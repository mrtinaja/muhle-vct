USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_GROUP_USERS]    Script Date: 16/9/2026 17:13:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[M_CONFIG_GROUP_USERS]
(
    @IPKEYJOB      VARCHAR(100),
    @IUSERID        VARCHAR(100),
    @FORM_ID        VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @V_PERFIL_SEL VARCHAR(100) = '';

    -- 1. Obtener perfil de M_CONFIG
    SELECT TOP 1
        @V_PERFIL_SEL = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    SET @V_PERFIL_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@V_PERFIL_SEL, ''), ',', ''), '''', ''), '"', '')));

    -- 2. Cargar tabla temporal
    IF OBJECT_ID('tempdb..#TmpGroupUsers') IS NOT NULL
        DROP TABLE #TmpGroupUsers;

    SELECT
        Usuario       = u.Id,
        Nombre        = ISNULL(u.Name, u.Id),
        Email         = ISNULL(u.Email, ''),
        Estado        = CASE WHEN u.State = 1 THEN '<span class="vct-status-badge vct-status-active"><span class="vct-status-dot"></span>Activa</span>' ELSE '<span class="vct-status-badge vct-status-inactive"><span class="vct-status-dot"></span>No Activa</span>' END,
        [Fallos Login] = ISNULL(u.LoginFailure, 0)
    INTO #TmpGroupUsers
    FROM dbo.GroupsUserMembers gum WITH (NOLOCK)
    INNER JOIN dbo.Users u WITH (NOLOCK) ON UPPER(LTRIM(RTRIM(gum.UserMemberId))) = UPPER(LTRIM(RTRIM(u.Id)))
    LEFT JOIN dbo.Groups g WITH (NOLOCK) ON UPPER(LTRIM(RTRIM(gum.GroupId))) = UPPER(LTRIM(RTRIM(g.Id)))
    WHERE
        UPPER(LTRIM(RTRIM(gum.GroupId))) = UPPER(@V_PERFIL_SEL)
        OR UPPER(LTRIM(RTRIM(ISNULL(g.Name, '')))) = UPPER(@V_PERFIL_SEL)
        OR UPPER(LTRIM(RTRIM(ISNULL(g.Id, '')))) = UPPER(@V_PERFIL_SEL)
    ORDER BY u.Name, u.Id;

    -- 3. Configuración JSON de la columna de desvinculación (Tacho Rojo)
    DECLARE @ActionsJson VARCHAR(MAX) =
    '[
        {
            "type": "custom",
            "title": "Eliminar",
            "icon": "trash-2",
            "isSecondary": true,
            "variant": "danger",
            "keyField": "Usuario",
            "targetGuid": "97D60A26-8606-4D28-8BBE-6E290E407C9E",
            "storageKey": "ID_DELETE",
            "actionParam": "DELETE_USER"
        }
    ]';

    -- 4. Invocación a vct_RenderGrid (Garantiza Buscador, Paginado y Columna de Acciones)
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpGroupUsers',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HtmlColumns   = 'Estado',
         @ScriptVersion = '6.1.0';

    IF OBJECT_ID('tempdb..#TmpGroupUsers') IS NOT NULL
        DROP TABLE #TmpGroupUsers;

END
