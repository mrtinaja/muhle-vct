CREATE PROCEDURE [dbo].[SV_04_GRD_EMPLEADOS]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VCLAVE_DEL		VARCHAR(50),
		@VID_ADJUNTO	VARCHAR(100)
 
BEGIN	
 
	SELECT	'<div class="w3-center w3-muhle-text-12">'+
			'<i class="fas fa-edit" style="cursor:pointer;color:#002364" title="Modificar"
			onclick="almacenarSeleccion(''ID_SELEC'','''+CONVERT(VARCHAR,ID_EMPLEADO)+''');
					 almacenarSeleccion(''TIPO_DOC'','''+ISNULL(CONVERT(VARCHAR,TIPO_DOC_EMP),'')+''');
					 almacenarSeleccion(''INGRESO'','''+ISNULL(CONVERT(VARCHAR,INGRESA_SISTEMA),'')+''');
					 almacenarSeleccion(''PROVINCIA'','''+ISNULL(CONVERT(VARCHAR,PROVINCIA_EMP),'')+''');
					 almacenarSeleccion(''PERFIL'','''+ISNULL(CONVERT(VARCHAR,PERFIL_EMP),'')+''');
					 almacenarSeleccion(''ESTADO'','''+ISNULL(CONVERT(VARCHAR,STATUS_EMP),'')+''');
					 almacenarSeleccion(''MOVILIDAD'','''+ISNULL(CONVERT(VARCHAR,MOVILIDAD_EMP),'')+''');
					 almacenarSeleccion(''EVENTUAL'','''+ISNULL(CONVERT(VARCHAR,EVENTUAL),'')+''');
					 almacenarSeleccion(''COD_ACCION_MENU'',''UPDATE'');
					 goto('''+@FORM_ID+''',''EB1BF60D-7182-4AF8-A6F4-4904EA719F98'');"></i></div>'AS '<div class="w3-center w3-muhle-text-11"></div>', 
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ CONVERT(VARCHAR,FECHA_ALTA,103) + '</div>'				AS '<div class="w3-left w3-muhle-text-11">Alta</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO + '</div>'	AS '<div class="w3-left w3-muhle-text-11">Empleado/Consultor</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ TIPO_DOC_EMP + ' - '+ NRO_DOC_EMP	+ '</div>'			AS '<div class="w3-left w3-muhle-text-11">Documento</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ PERFIL_EMP	+ '</div>'									AS '<div class="w3-left w3-muhle-text-11">Perfil</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ CASE WHEN STATUS_EMP = '1' THEN 'Activo' ELSE 'Inactivo' END + '</div>'	AS '<div class="w3-left w3-muhle-text-11">Estado</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ ISNULL(EVENTUAL,'NO')	+ '</div>'						AS '<div class="w3-left w3-muhle-text-11">Eventual</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ ISNULL(DIAS_MENSUALES,'0') + '</div>'					AS '<div class="w3-left w3-muhle-text-11">Días Mensuales</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ CALLE_EMP+ ' ' +ISNULL(NRO_CALLE_EMP,'') + case when ISNULL(PISO_DEPTO_EMP,'') = '' THEN '' ELSE ' - ' + PISO_DEPTO_EMP END + '</div>'	AS '<div class="w3-left w3-muhle-text-11">Domicilio</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ LOCALIDAD_EMP	+ '</div>'								AS '<div class="w3-left w3-muhle-text-11">Localidad</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ ISNULL(CD.CAT_DATA_DESC,PROVINCIA_EMP)	+ '</div>'		AS '<div class="w3-left w3-muhle-text-11">Provincia</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ TEL1_EMP	+ '</div>'										AS '<div class="w3-left w3-muhle-text-11">Celular</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ TEL2_EMP	+ '</div>'										AS '<div class="w3-left w3-muhle-text-11">CBU</div>',
			'<div class="w3-left w3-muhle-text-11" style="color:'+case when E.STATUS_EMP = '0' then 'red' when E.EVENTUAL = 'SI' then 'blue' else 'black' end+'">'+ EMAIL_EMP	+ '</div>'									AS '<div class="w3-left w3-muhle-text-11">Email</div>',
			+ '<div class="w3-center w3-muhle-text-12">'+
			case when ISNULL(P.pkey,'') = '' then '' else 
			'<i class="fas fa-file" style="cursor:pointer;" title="CV"
			onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''', '''+ISNULL(P.FILE_NAME,'')+''');"></i></div>' end AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
			CASE WHEN PERFIL_EMP = 'EMPLEADO' THEN 
			'<div class="w3-center w3-muhle-text-12">'+
			'&nbsp;<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="Eliminar" onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Empleado?'');
			if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_EMPLEADO)+''');goto('''+@FORM_ID+''',''9290878C-C546-43A1-8B89-B53C7039DCB8'');}"></i></div>' 
			ELSE '' END AS '<div class="w3-center w3-muhle-text-11">[-]</div>'
	FROM	LK_EMPLEADOS E
			LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = E.PROVINCIA_EMP AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'PROVINCIA')
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = E.CV_EMP_PKEY
	ORDER BY APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
 
END
