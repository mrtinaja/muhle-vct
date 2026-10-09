CREATE   PROCEDURE [dbo].[SV_01_GRD_APTITUDES_EMP]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE @VEMPLEADO	VARCHAR(50),
		@VSERVICIO	VARCHAR(50)
 
BEGIN
 
	SELECT	@VEMPLEADO = ISNULL(EMPLEADO,''),
			@VSERVICIO = ISNULL(TIPO_SERVICIO,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF (@VEMPLEADO = '') BEGIN
		
		SELECT	'<div class="w3-center w3-muhle-text-12">Debe Seleccionar un Empleado/Consultor</div>' AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
	
	END ELSE BEGIN	
 
		IF (@VSERVICIO = '') BEGIN
			
			SELECT	'<div class="w3-center w3-muhle-text-12">Debe Seleccionar un Servicio</div>' AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
		
		END ELSE BEGIN
			SELECT	'<div class="w3-center w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					onclick="almacenarSeleccion(''CLAVE'','''+CONVERT(VARCHAR,ID_EMPLE_APTITUD)+''');
					goto('''+@FORM_ID+''',''F4604538-20F1-4237-8139-AF3F712C6C92'');"/></i></div>'	AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
					--ID_APTITUD	AS "<B>ID</B>",
					'<div class="w3-left w3-muhle-text-11">'+APT.DESC_APTITUD+'</div>'							AS '<div class="w3-left w3-muhle-text-11">APTITUD</div>',
					'<div class="w3-center w3-muhle-text-11">'+TS.DESC_TIPO_SERVICIO+'</div>'						AS '<div class="w3-center w3-muhle-text-11">SERVICIO</div>',
					'<div class="w3-center w3-muhle-text-11">'+EMP.CALIFICACION+'</div>'							AS '<div class="w3-center w3-muhle-text-11">CALIFICACION</div>',
					'<div class="w3-left w3-muhle-text-11">'+EMP.OBSERVACION+'</div>'								AS '<div class="w3-left w3-muhle-text-11">OBSERVACION</div>',
					'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,EMP.FECHA_ALTA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">FECHA ALTA</div>',
					'<div class="w3-center w3-muhle-text-11">'+EMP.USUARIO_ALTA+'</div>'							AS '<div class="w3-center w3-muhle-text-11">USUARIO ALTA</div>',
					'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,EMP.FECHA_UPD,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">FECHA MODIF.</div>',
					'<div class="w3-center w3-muhle-text-11">'+EMP.USUARIO_UPD+'</div>'								AS '<div class="w3-center w3-muhle-text-11">USUARIO MODIF.</div>',
					'<div class="w3-center w3-muhle-text-12"><i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="Eliminar" ' + '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Aptitud del Empleado/Consultor?'');
					if (confirmar){almacenarSeleccion(''ID_EMPLE_APTITUD'','''+CONVERT(VARCHAR,ID_EMPLE_APTITUD)+ ''');goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[-]</div>'
			FROM	LK_EMPLEADOS_APTITUD EMP
					INNER JOIN LK_APTITUDES APT ON (EMP.ID_APTITUD = APT.ID_APTITUD)
					INNER JOIN LK_TIPO_SERVICIOS TS ON TS.ID_TIPO_SERVICIO = EMP.ID_TIPO
			WHERE	EMP.ID_EMPLEADO = @VEMPLEADO
			AND		EMP.ID_TIPO = @VSERVICIO
			ORDER BY ID_EMPLE_APTITUD
		END
	END
END
 
--9CCB2B05-74FB-4CB6-8F69-0B5772BC5974
