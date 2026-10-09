 
CREATE PROCEDURE [dbo].[M_CONFIG_ACTIONS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Limpieza de variables de sesión temporales en M_CONFIG
    UPDATE dbo.M_CONFIG
    SET ID_GROUP_SEL  = NULL,
        ID_ACTION_SEL = NULL,
        NEW_ID        = NULL,
        NEW_NAME      = NULL,
        NEW_PASSWORD  = NULL,
        NEW_EMAIL     = NULL
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- Eliminación preventiva de la tabla temporal
    IF OBJECT_ID('tempdb..#TmpActions') IS NOT NULL
        DROP TABLE #TmpActions;
 
    -- Preparación del dataset utilizando la estructura real (Id, Name, ModifiedDate)
    SELECT
        Codigo     = ISNULL(A.Id, ''),
        Nombre     = ISNULL(A.Name, ''),
        Modulo     = CASE
                       WHEN CHARINDEX('.', A.Id) > 0 THEN LEFT(A.Id, CHARINDEX('.', A.Id) - 1)
                       ELSE A.Id
                     END,
        Modificado = ISNULL(CONVERT(VARCHAR(10), A.ModifiedDate, 103) + ' ' + CONVERT(VARCHAR(5), A.ModifiedDate, 108), '-'),
        Tipo       = ISNULL(A.Tipo, '')
    INTO #TmpActions
    FROM dbo.Actions A WITH (NOLOCK)
    ORDER BY A.Id ASC;
 
    -- Renderizado dinámico según estándar VCT
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpActions',
         @FormId        = @FORM_ID,
         @ActionsJson   = '[{"type":"edit","storageKey":"ID_ACTION_SEL","targetTab":"form","icon":"pencil","title":"Editar acción"}]',
         @PageSize      = 10,
         @HiddenColumns = 'Codigo,Tipo',
         @ScriptVersion = '9.9.9';
 
    -- Limpieza final de la tabla temporal
    IF OBJECT_ID('tempdb..#TmpActions') IS NOT NULL
        DROP TABLE #TmpActions;
END
