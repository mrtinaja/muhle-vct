 
CREATE PROCEDURE [dbo].[M_CONFIG_CMB_GROUPS]
(
    @IPKEYJOB AS VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Mantiene compatibilidad nativa mapeando las columnas de Groups
    SELECT 
        G.Id    AS CAT_DATA_CODE,
        G.Name  AS CAT_DATA_DESC,
        'TRUE'  AS IS_ACTIVE
    FROM dbo.Groups G WITH (NOLOCK)
    ORDER BY G.Name;
 
END
