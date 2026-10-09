 
CREATE PROCEDURE [dbo].[M_CONFIG_GROUP_TASKS]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100),
    @FORM_ID  AS VARCHAR(100)
)
AS
BEGIN   
    SET NOCOUNT ON;
 
    DECLARE @ID_GROUP_SEL VARCHAR(100);
 
    SELECT TOP 1 @ID_GROUP_SEL = ISNULL(ID_GROUP_SEL, '') 
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@ID_GROUP_SEL, ''), ',', ''), '''', ''), '"', '')));
 
    IF OBJECT_ID('tempdb..#TmpGroupTasks') IS NOT NULL DROP TABLE #TmpGroupTasks;
 
    -- Lectura directa de SideBar y SideBarGroups
    SELECT 
        PKey        = LTRIM(RTRIM(ISNULL(S.Id, ''))),
        Código      = ISNULL(S.Id, ''),
        Descripción = ISNULL(S.Name, '')
    INTO #TmpGroupTasks
    FROM dbo.SideBar S WITH (NOLOCK)
    WHERE S.Id IN (
            SELECT SG.SideBarId
            FROM dbo.SideBarGroups SG WITH (NOLOCK)
            WHERE LTRIM(RTRIM(REPLACE(SG.GroupId, ',', ''))) = @ID_GROUP_SEL
          ) 
    ORDER BY S.Id;
 
    DECLARE @ActionsJson VARCHAR(MAX) = 
    '[
        {
            "type": "custom",
            "title": "Eliminar",
            "icon": "trash-2",
            "isSecondary": true,
            "variant": "danger",
            "keyField": "Pkey",
            "targetGuid": "E47723C4-7340-4168-AE4D-FDE4A65E7271",
            "storageKey": "ID_DELETE",
            "actionParam": "DELETE_TASK"
        }
    ]';
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpGroupTasks',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HiddenColumns = '',
         @ScriptVersion = '6.0.0';
 
    IF OBJECT_ID('tempdb..#TmpGroupTasks') IS NOT NULL DROP TABLE #TmpGroupTasks;
 
END
