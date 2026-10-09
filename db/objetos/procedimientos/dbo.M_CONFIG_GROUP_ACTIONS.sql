 
CREATE PROCEDURE [dbo].[M_CONFIG_GROUP_ACTIONS]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID AS VARCHAR(100),
    @FORM_ID AS VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ID_GROUP_SEL VARCHAR(100);
 
    SELECT TOP 1 @ID_GROUP_SEL = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@ID_GROUP_SEL, ''), ',', ''), '''', ''), '"', '')));
 
    IF OBJECT_ID('tempdb..#TmpGroupActions') IS NOT NULL
        DROP TABLE #TmpGroupActions;
 
    SELECT
        Descripcion = ISNULL(A.Name, A.Id),
        Codigo = CONVERT(VARCHAR(100), A.Id),
        Estado = CASE WHEN GA.GroupId IS NOT NULL THEN '1' ELSE '0' END
    INTO #TmpGroupActions
    FROM dbo.Actions A WITH (NOLOCK)
    LEFT JOIN dbo.GroupsActions GA WITH (NOLOCK)
        ON LTRIM(RTRIM(GA.ActionId)) = LTRIM(RTRIM(A.Id))
       AND LTRIM(RTRIM(GA.GroupId)) = @ID_GROUP_SEL
    ORDER BY Descripcion;
 
    -- Codigo debe permanecer en el DOM para identificar el permiso.
    -- El PREV oculta sus celdas visualmente, sin eliminar la columna.
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpGroupActions',
         @FormId = @FORM_ID,
         @ActionsJson = '[]',
         @PageSize = 25,
         @HiddenColumns = '',
         @ScriptVersion = '18.0.0';
 
    IF OBJECT_ID('tempdb..#TmpGroupActions') IS NOT NULL
        DROP TABLE #TmpGroupActions;
END
