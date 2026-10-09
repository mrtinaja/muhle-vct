CREATE PROCEDURE [dbo].[SV_02_GRD_CLIENTES_BK]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
	SET NOCOUNT ON;
 
	SELECT	
		'<div style="text-align:center;"><i class="fas fa-edit" style="cursor:pointer;color:#2563eb;" title="Modificar" onclick="almacenarSeleccion(''CLAVE'','''+CONVERT(VARCHAR,C.ID_CLIENTE)+'''); almacenarSeleccion(''PROVINCIA'','''+ISNULL(CONVERT(VARCHAR,C.PROVINCIA_CLIENTE),'')+'''); almacenarSeleccion(''IVA'','''+ISNULL(CONVERT(VARCHAR,C.IVA_CLIENTE),'')+'''); almacenarSeleccion(''TIPO_CLIENTE'','''+ISNULL(CONVERT(VARCHAR,C.TIPO_CLIENTE),'')+'''); almacenarSeleccion(''ESTADO'','''+ISNULL(CONVERT(VARCHAR,C.STATUS_CLIENTE),'')+'''); goto('''+@FORM_ID+''',''FDEDA3EB-D348-4CCB-883F-BB54E878F975'');"></i></div>' AS 'Editar',
		'<div style="font-weight:700; color:#0f172a;">' + ISNULL(C.RAZON_SOCIAL_CLIENTE,'') + '</div>' AS 'Cliente',
		'<div style="text-align:center;"><span style="padding:2px 6px; border-radius:4px; font-size:11px; font-weight:700; ' + CASE WHEN C.TIPO_CLIENTE = 'ACTIVO' THEN 'background:#dcfce7; color:#15803d;' WHEN C.TIPO_CLIENTE = 'PASIVO' THEN 'background:#dbeafe; color:#1e40af;' ELSE 'background:#fee2e2; color:#b91c1c;' END + '">' + ISNULL(C.TIPO_CLIENTE,'') + '</span></div>' AS 'Tipo',
		'<div style="text-align:center;">' + ISNULL(C.CUIT_CLIENTE,'') + '</div>' AS 'CUIT',
		'<div>' + ISNULL(C.CALLE_CLIENTE,'') + ' ' + ISNULL(C.NRO_CALLE_CLIENTE,'') + CASE WHEN ISNULL(C.PISO_DEPTO_CLIENTE,'') = '' THEN '' ELSE ' - ' + C.PISO_DEPTO_CLIENTE END + '</div>' AS 'Domicilio',
		'<div>' + ISNULL(C.LOCALIDAD_CLIENTE,'') + '</div>' AS 'Localidad',
		'<div>' + ISNULL(CD.CAT_DATA_DESC, C.PROVINCIA_CLIENTE) + '</div>' AS 'Provincia',
		'<div>' + ISNULL(C.CONTACTO_CLIENTE,'') + '</div>' AS 'Contacto',
		'<div style="text-align:center;">' + ISNULL(C.TEL1_CLIENTE,'') + '</div>' AS 'Teléfono',
		'<div style="text-align:center;">' + ISNULL(C.TEL2_CLIENTE,'') + '</div>' AS 'Celular',
		'<div>' + ISNULL(C.EMAIL_CLIENTE,'') + '</div>' AS 'Email'
	FROM LK_CLIENTES C WITH (NOLOCK)
	LEFT JOIN CAT_DATA CD WITH (NOLOCK) ON CD.CAT_DATA_CODE = C.PROVINCIA_CLIENTE AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'PROVINCIA')
	ORDER BY C.RAZON_SOCIAL_CLIENTE;
 
END
