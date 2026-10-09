 
 
 
 
 
 
 
 
CREATE VIEW [dbo].[VW_CLIENTES]
AS
 
                      
SELECT	DISTINCT TOP 1000 ID_CLIENTE AS CAT_DATA_CODE, 
		--'<font style="font-size:13px;color:'+case when TIPO_CLIENTE = 'ACTIVO' then 'black' when TIPO_CLIENTE = 'PASIVO' then 'blue' else 'red' end +';text-align: left">'+ISNULL(RAZON_SOCIAL_CLIENTE + ' - ('+CUIT_CLIENTE+')','')+'</font>' AS CAT_DATA_DESC, 
		ISNULL(RAZON_SOCIAL_CLIENTE + ' - ('+CUIT_CLIENTE+')','') AS CAT_DATA_DESC,
        ID_CLIENTE AS PKEY, 
		'' AS PARENT_CAT_DATA_CODE, 
		'' AS PARENT_CAT_DATA_PKEY
FROM    LK_CLIENTES 
WHERE	TIPO_CLIENTE = 'ACTIVO'
 
