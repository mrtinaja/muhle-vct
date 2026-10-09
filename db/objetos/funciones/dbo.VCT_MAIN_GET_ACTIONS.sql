 
CREATE   FUNCTION [dbo].[VCT_MAIN_GET_ACTIONS]
(
    @IUNIDAD     VARCHAR(100),
    @MODULE_CODE VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        ID_PRM       = PA.Id,
        ACTION_ID    = PA.ActionID,
        ACTION_TYPE  = UPPER(LTRIM(RTRIM(ISNULL(PA.ActionType,'')))),
        TITLE        = ISNULL(PA.Title,''),
        ICON         = ISNULL(PA.Icon,''),
        KEY_FIELD    = ISNULL(PA.KeyField,''),
        STORAGE_KEY  = ISNULL(PA.StorageKey,''),
        TARGET_TAB   = ISNULL(PA.TargetTab,''),
        SORT_ORDER   = ISNULL(PA.SortOrder,999),
        TARGET_GUID  = ISNULL(CONVERT(VARCHAR(100),PA.TargetGuid),''),
        SIDEBAR_ID   = ISNULL(PA.SideBarId,0)
    FROM dbo.PrmActions PA
    INNER JOIN dbo.Actions A
        ON A.Id COLLATE DATABASE_DEFAULT = PA.ActionID COLLATE DATABASE_DEFAULT
    INNER JOIN dbo.GroupsActions GA
        ON GA.ActionId COLLATE DATABASE_DEFAULT = A.Id COLLATE DATABASE_DEFAULT
    WHERE UPPER(LTRIM(RTRIM(GA.GroupId))) = UPPER(LTRIM(RTRIM(@IUNIDAD)))
      AND UPPER(PA.ActionID) LIKE UPPER(@MODULE_CODE) + '.%'
);
