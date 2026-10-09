CREATE PROCEDURE [dbo].[HOME_GRD_COTIZACIONES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VCLAVE_DEL		VARCHAR(50),
		@VID_ADJUNTO	VARCHAR(100),
		@VESTADO		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VCLAVE_DEL = ISNULL(ID_DELETE,''),
			@VESTADO = ISNULL(ESTADO_PROY,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VCLAVE_DEL <> '') BEGIN
		
		--elimino la ref en la cotizaciones de los proyectos
		UPDATE	LK_PROYECTO
		SET		ID_COTIZACION = 0
		WHERE	ID_COTIZACION = @VCLAVE_DEL
 
		SELECT	@VID_ADJUNTO = ISNULL(ID_ADJUNTO,'')
		FROM	LK_COTIZACIONES
		WHERE	ID_COTIZACION = @VCLAVE_DEL
 
		DELETE FROM	LK_COTIZACIONES
		WHERE ID_COTIZACION = @VCLAVE_DEL
 
		IF (@VID_ADJUNTO <> '') BEGIN
			DELETE FROM PHYSICAL_ATTACHED_DOCUMENT
			WHERE PKEY = @VID_ADJUNTO
		END
 
	END
	
	SELECT	'<div class="w3-center w3-muhle-text-12">'+
			'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
			onclick="almacenarSeleccion(''CLAVE_COTIZA'','''+CONVERT(VARCHAR,C.ID_COTIZACION)+''');
					 almacenarSeleccion(''ESTADO_COTIZA'','''+C.ESTADO_COTIZACION+''');
					 goto('''+@FORM_ID+''',''116FA485-BFEA-4883-AB54-CD2937DFD996'');"></i></div>'						AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
			'<div class="w3-left w3-muhle-text-11">'+CLI.RAZON_SOCIAL_CLIENTE+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
			string_agg('<div class="w3-left w3-muhle-text-11">'+ISNULL('('+P.CODIGO+') - '+P.NORMA_REF, 'Sin Asignar')+'</div>','<br>') AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
			'<div class="w3-center w3-muhle-text-11">'+NRO_COTIZACION+'</div>'											AS '<div class="w3-center w3-muhle-text-11">Nro Cotizacion</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,C.FECHA_COTIZACION,103)+'</div>'					AS '<div class="w3-center w3-muhle-text-11">Fecha</div>',
			'<div class="w3-center w3-muhle-text-11">'+C.ESTADO_COTIZACION+'</div>'										AS '<div class="w3-center w3-muhle-text-11">Estado</div>',
			CASE WHEN ISNULL(C.ID_ADJUNTO,'') <> '' THEN
			'<div class="w3-center w3-muhle-text-12">
				<i class="fas fa-file-word" style="cursor:pointer;" title="Cotizacion" '+ CASE WHEN ISNULL(C.ID_ADJUNTO,'') <> '' THEN
												'onclick="OpenAttach('''+ISNULL(AD.PKEY,'')+''','''+ISNULL(AD.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i></div>'
			ELSE '' END																									AS '<div class="w3-center w3-muhle-text-11">Ver</div>',
			'<div class="w3-center w3-muhle-text-11">
				<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
			onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Cotizacion?'');
			if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,C.ID_COTIZACION)+ ''');goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[-]</div>'
	FROM	LK_COTIZACIONES C
			LEFT JOIN	LK_CLIENTES CLI ON CLI.ID_CLIENTE = C.ID_CLIENTE
			LEFT JOIN	LK_PROYECTO P ON P.ID_COTIZACION = C.ID_COTIZACION
			LEFT JOIN	PHYSICAL_ATTACHED_DOCUMENT AD ON AD.PKEY = C.ID_ADJUNTO
	WHERE	1=1
	AND		CASE WHEN ISNULL(P.ESTADO_PROYECTO_TOTAL,'') = '' THEN 'SIN_ASIGNAR' ELSE P.ESTADO_PROYECTO_TOTAL END = @VESTADO 
	GROUP BY C.ID_COTIZACION, C.ESTADO_COTIZACION, C.NRO_COTIZACION, C.FECHA_COTIZACION, CLI.RAZON_SOCIAL_CLIENTE, C.ID_ADJUNTO, AD.PKEY, AD.[FILE_NAME]
	ORDER BY CLI.RAZON_SOCIAL_CLIENTE, C.FECHA_COTIZACION
 
END
