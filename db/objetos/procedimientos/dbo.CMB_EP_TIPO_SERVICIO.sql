CREATE PROCEDURE [dbo].[CMB_EP_TIPO_SERVICIO]
AS
BEGIN	
 
	SELECT	'1' AS CAT_DATA_CODE,
			'Seguridad e Higiene' AS CAT_DATA_DESC,
			'TRUE'
	UNION
	SELECT	'2' AS CAT_DATA_CODE,
			'Asesoramiento y Gestión Ambiental' AS CAT_DATA_DESC,
			'FALSE'
	UNION
	SELECT	'3' AS CAT_DATA_CODE,
			'Monitoreos Contratados' AS CAT_DATA_DESC,
			'FALSE'
	UNION
	SELECT	'4' AS CAT_DATA_CODE,
			'Avisos y Comunicaciones' AS CAT_DATA_DESC,
			'FALSE'
 
 
END
