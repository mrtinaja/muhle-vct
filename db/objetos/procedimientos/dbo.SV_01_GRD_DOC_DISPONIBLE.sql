CREATE   PROCEDURE [dbo].[SV_01_GRD_DOC_DISPONIBLE]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE @VTIPO	VARCHAR(50)
 
BEGIN	
 
	SELECT	@VTIPO = ISNULL(TIPO_SERVICIO,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VTIPO = '') BEGIN
		
		SELECT	'Debe Seleccionar un Tipo de Servicio' AS "<B>MENSAJE</B>"
 
	END ELSE BEGIN
 
		SELECT	CASE WHEN STATUS_DOCUMENTACION = '1' THEN
						'<font color="green">'+CODE_DOCUMENTACION+'</font>'
					 WHEN STATUS_DOCUMENTACION = '0' THEN
						'<font color="red">'+CODE_DOCUMENTACION+'</font>'
				END AS "<B>CODIGO</B>",
				CASE WHEN STATUS_DOCUMENTACION = '1' THEN
						'<font color="green">'+DESC_DOCUMENTACION+'</font>'
					 WHEN STATUS_DOCUMENTACION = '0' THEN
						'<font color="red">'+DESC_DOCUMENTACION+'</font>'
				END AS "<B>DOCUMENTACION</B>",
				'<img src="./../img/fderecha.png" width="25" height="25" style="cursor:pointer" title="' +'Agregar'+ '" 
				onclick="almacenarSeleccion(''CLAVE_DOC'','''+CONVERT(VARCHAR,ID_DOCUMENTACION)+''');
				goto('''+@FORM_ID+''',''10F46389-EA1D-47AD-A5AB-C8FA8361A7BA'');"/>' AS "<B>[+]</B>"
		FROM	LK_DOCUMENTACION
		WHERE	ID_DOCUMENTACION NOT IN (SELECT ID_DOCUMENTACION 
										 FROM	LK_DOCUMENTACION_REL
										 WHERE	ID_TIPO_SERVICIO = @VTIPO)
		ORDER BY ID_DOCUMENTACION
 
	END
END
 
