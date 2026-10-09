 
CREATE PROCEDURE [dbo].[M_CONFIG_USERS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TmpUsers') IS NOT NULL
        DROP TABLE #TmpUsers;
 
    SELECT
        Usuario      = ISNULL(u.Id, ''),
        Descripcion  = ISNULL(u.Name, ''),
        Email        = ISNULL(u.Email, ''),
        CodigoEstado = ISNULL(u.State, 0),
        Estado       = CASE
                           WHEN ISNULL(u.State, 0) = 1 THEN '<span class="vct-status-badge vct-status-active"><span class="vct-status-dot"></span>Activa</span>'
                           ELSE '<span class="vct-status-badge vct-status-inactive"><span class="vct-status-dot"></span>No Activa</span>'
                       END,
        Perfil       = ISNULL(g.Name, ''),
        CodigoPerfil = ISNULL(g.Id, ''),
        Fallidos     = ISNULL(u.LoginFailure, 0)
    INTO #TmpUsers
    FROM Users u WITH (NOLOCK)
        LEFT JOIN GroupsUserMembers gu WITH (NOLOCK)
            ON gu.UserMemberId = u.Id
        LEFT JOIN Groups g WITH (NOLOCK)
            ON g.Id = gu.GroupId
        LEFT JOIN
        (
            SELECT
                ussec.Id_User,
                Sectores = STRING_AGG(
                    CONVERT(VARCHAR(MAX), ISNULL(sct.Desc_Sector, '')),
                    ', '
                ),
                IdUserSectores = STRING_AGG(
                    CONVERT(VARCHAR(MAX), ussec.Id_Sector),
                    ','
                )
            FROM UsersSector ussec WITH (NOLOCK)
                INNER JOIN Sectores sct WITH (NOLOCK)
                    ON sct.Id_Sector = ussec.Id_Sector
            GROUP BY
                ussec.Id_User
        ) SECTUSU
            ON UPPER(LTRIM(RTRIM(SECTUSU.Id_User))) = UPPER(LTRIM(RTRIM(u.Id)))
    WHERE   1 = 1
    AND     u.Id <> 'admin';
 
    DECLARE @ActionsJson VARCHAR(MAX);
 
    SET @ActionsJson =
    '[
        {
            "type": "edit",
            "title": "Editar usuario",
            "keyField": "Usuario",
            "storageKey": "ID_USER_SEL",
            "targetTab": "form",
            "mode": "server"
        }
    ]';
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpUsers',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HiddenColumns = 'CodigoEstado,CodigoPerfil',
         @HtmlColumns   = 'Estado',
         @ScriptVersion = '5.1.0';
 
    IF OBJECT_ID('tempdb..#TmpUsers') IS NOT NULL
        DROP TABLE #TmpUsers;
END
