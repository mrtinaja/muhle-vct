CREATE   PROCEDURE [dbo].[SV_01_GRD_TIPO_SERVICIOS]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
 
	SELECT	'<i class="far fa-edit" style="cursor:pointer;color:#003D7A;font-size:16px" title="Modificar" 
			onclick="almacenarSeleccion(''CLAVE'','''+CONVERT(VARCHAR,ID_TIPO_SERVICIO)+''');
					 almacenarSeleccion(''ESTADO_TS'','''+STATUS_TIPO_SERVICIO+''');
					 goto('''+@FORM_ID+''',''5F150061-40F2-441C-8094-A6DE36491E4A'');"></i>'	AS '<font size="2">[+]</font>',
			'<font size="2">'+CONVERT(VARCHAR,ID_TIPO_SERVICIO)+'</font>'			AS '<font size="2">ID</font>',
			'<font size="2">'+DESC_TIPO_SERVICIO+'</font>'							AS '<font size="2">TIPO SERVICIO</font>',
			'<font size="2">'+CONVERT(VARCHAR,FECHA_ALTA,103)+'</font>'				AS '<font size="2">FECHA ALTA</font>',
			'<font size="2">'+USUARIO_ALTA+'</font>'								AS '<font size="2">USUARIO ALTA</font>',
			'<font size="2">'+CONVERT(VARCHAR,FECHA_UPD,103)+'</font>'				AS '<font size="2">FECHA MODIF.</font>',
			'<font size="2">'+USUARIO_UPD+'</font>'									AS '<font size="2">USUARIO MODIF.</font>',
			CASE WHEN (STATUS_TIPO_SERVICIO = '0') THEN
					'<i class="fas fa-eye-slash" style="cursor:pointer;color:red;font-size:18px" title="Inactivo"></i>'
				 WHEN (STATUS_TIPO_SERVICIO = '1') THEN
					'<i class="fas fa-eye" style="cursor:pointer;color:green;font-size:18px" title="Activo"></i>'
			END																		AS '<font size="2">ESTADO</font>'
	FROM	LK_TIPO_SERVICIOS
	ORDER BY ID_TIPO_SERVICIO
 
END
 
