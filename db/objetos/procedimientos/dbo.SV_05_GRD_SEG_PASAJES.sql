CREATE PROCEDURE [dbo].[SV_05_GRD_SEG_PASAJES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME
 
BEGIN	
	
	SELECT	@VFECHA_DESDE = ISNULL(FECHA_DESDE,''),
			@VFECHA_HASTA = ISNULL(FECHA_HASTA,'')
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VFECHA_DESDE = '') BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Desde</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
	END
 
	IF (@VFECHA_HASTA = '') BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
	END
 
	IF (@VFECHA_DESDE > @VFECHA_HASTA) BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">La Fecha Desde debe ser Igual o Mayor a la Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
 
	END ELSE BEGIN
	
		SELECT	'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,V.FECHA_DESDE_SERV,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha Pasaje</div>',
				--'<font size="2">'+DET.DET_PROV_ORIGEN+'/'+DET.DET_PROV_DESTINO+'</font>'		AS '<font size="1">Destino</font>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,NRO_FC)+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Nro Factura</div>',
				CASE WHEN ISNULL(FECHA_FC,'') = '' THEN '' ELSE
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_FC,103)+'</div>' END						AS '<div class="w3-center w3-muhle-text-11">Fecha Factura</div>',
				'<div class="w3-center w3-muhle-text-11">'+UPPER(SUBSTRING(V.TIPO_PROVEEDOR,1,1))+LOWER(SUBSTRING(V.TIPO_PROVEEDOR,2,LEN(V.TIPO_PROVEEDOR)))+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Tipo</div>',
				CASE WHEN (V.ID_PROVEEDOR = 9999) THEN 
					'<div class="w3-left w3-muhle-text-11">'+V.DESCRIP_SERVICIO+'</div>' 
				ELSE
					'<div class="w3-left w3-muhle-text-11">'+P.RAZON_SOCIAL_PROV+'</div>'	
				END																											AS '<div class="w3-left w3-muhle-text-11">Proveedor</div>',
				'<div class="w3-center w3-muhle-text-11">'+UPPER(SUBSTRING(TIPO_CONSULTOR,1,1))+LOWER(SUBSTRING(TIPO_CONSULTOR,2,LEN(TIPO_CONSULTOR)))+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Tipo Pasajero</div>',
				CASE WHEN TIPO_CONSULTOR = 'CONSULTOR' THEN
					'<div class="w3-left w3-muhle-text-11">'+E.APELLIDO_EMPLEADO + ', '+E.NOMBRE_EMPLEADO +'</div>'			
				ELSE 
					'<div class="w3-left w3-muhle-text-11">'+V.ID_CONSULTOR+'</div>' 
				END																											AS '<div class="w3-left w3-muhle-text-11">Pasajero</div>',
				'<div class="w3-left w3-muhle-text-11">'+C.RAZON_SOCIAL_CLIENTE+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
				'<div class="w3-left w3-muhle-text-11">'+PROY.NORMA_REF+ ' - ' + '<b>'+ISNULL(ps.NOMBRE,'')+'</b></div>'	AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
				'<div class="w3-center w3-muhle-text-11">'+S.DESC_TIPO_SERVICIO+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Servicio</div>',
				'<div class="w3-center w3-muhle-text-11">'+UPPER(SUBSTRING(FORMA_PAGO,1,1))+LOWER(SUBSTRING(FORMA_PAGO,2,LEN(FORMA_PAGO)))+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Forma Pago</div>',
				'<div class="w3-left w3-muhle-text-11">'+ISNULL(DESC_FORMA_PAGO,'')+'</div>'								AS '<div class="w3-left w3-muhle-text-11">Desc. Forma Pago</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,PRECIO_FINAL)+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Precio Final</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,CANT_CUOTAS)+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Cuotas</div>'
				--'<font size="2">'+CONVERT(VARCHAR,PRECIO_CUOTA)+'</font>'		AS '<font size="2">Precio Cuota</font>',
				--'<font size="2">'+CONVERT(VARCHAR,SALDO_PEND)+'</font>'			AS '<font size="2">Saldo</font>',
				--'<font size="2">'+UPPER(SUBSTRING(ESTADO_PAGO,1,1))+LOWER(SUBSTRING(ESTADO_PAGO,2,LEN(ESTADO_PAGO)))+'</font>'	AS '<font size="2">Estado</font>'
				--CASE WHEN ISNULL(FECHA_ULT_PAGO,'') = '' THEN '' ELSE
				--'<font size="2">'+CONVERT(VARCHAR,FECHA_ULT_PAGO,103)+'</font>' END		AS '<font size="2">Ult. Pago</font>',
				--CASE WHEN ISNULL(PROX_VENCIMIENTO,'') = '' THEN '' ELSE
				--'<font size="2">'+CONVERT(VARCHAR,PROX_VENCIMIENTO,103)+'</font>' END	AS '<font size="2">Prox. Vto.</font>'
		FROM	LK_PROYECTO_VIATICOS V
				--LEFT JOIN LK_PROYECTO_VIATICOS_DET DET ON V.ID_PROYECTO_VIATICOS = DET.ID_PROYECTO_VIATICOS
				INNER JOIN LK_AGENDA A ON V.ID_AGENDA = A.ID_AGENDA
				INNER JOIN LK_PROYECTO PROY ON  PROY.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
				INNER JOIN LK_TIPO_SERVICIOS S ON V.ID_TIPO_SERVICIO = S.ID_TIPO_SERVICIO
				LEFT JOIN LK_PROVEEDORES P ON V.ID_PROVEEDOR = P.ID_PROVEEDOR
				LEFT JOIN LK_EMPLEADOS E ON V.ID_CONSULTOR = CONVERT(VARCHAR,E.ID_EMPLEADO)
		WHERE	TIPO_PROVEEDOR in ('AVION','MICRO')
		AND		V.FECHA_DESDE_SERV  >= @VFECHA_DESDE
		AND		V.FECHA_HASTA_SERV  <= @VFECHA_HASTA 
		order by SUBSTRING(CONVERT(VARCHAR,V.FECHA_DESDE_SERV,120),1,10)
 
	END
END
