 
CREATE PROCEDURE [dbo].[M_CONFIG_GROUPS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TmpGroups') IS NOT NULL
        DROP TABLE #TmpGroups;
 
    SELECT
        Perfil      = ISNULL(G.Id, ''),
        Descripción = ISNULL(G.Name, ''),
		Email       = ISNULL (G.email,'')
    INTO #TmpGroups
    FROM Groups G WITH (NOLOCK)
    WHERE G.Id <> 'SQUAD'
    ORDER BY G.Id;
 
    DECLARE @ActionsJson VARCHAR(MAX);
 
    -- Configuración JSON limpia sin comas adicionales
    SET @ActionsJson =
    '[
        {
            "type": "edit",
            "title": "Editar perfil",
            "icon": "pen-line",
            "keyField": "Perfil",
            "targetTab": "form"
        },
        {
            "type": "custom",
            "title": "Usuarios asociados",
            "icon": "users",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "3936E80A-5D88-4201-A10F-B7E7D9BAFCD6",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_USUARIOS"
        },
        {
            "type": "custom",
            "title": "Opciones Sidebar",
            "icon": "boxes",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "4489F5AB-1DFC-40FD-A3BC-B74DA1254733",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_TAREAS"
        },
        {
            "type": "custom",
            "title": "Permisos asociados",
            "icon": "navigation",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "6C5AC979-DFE2-4F60-8553-D027D20E3D81",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_ACCIONES"
        }
    ]';
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpGroups',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HiddenColumns = '',
         @ScriptVersion = '16.0.0';
 
    IF OBJECT_ID('tempdb..#TmpGroups') IS NOT NULL
        DROP TABLE #TmpGroups;
END
