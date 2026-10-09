 
CREATE PROCEDURE [dbo].[M_CONFIG_USERS_bk]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
 
    SET NOCOUNT ON;
 
    -----------------------------------------------------------------------------------------
    -- 1. TABLA TEMPORAL DE USUARIOS
    -- 'Usuario' actúa como la columna clave principal visible y accesible por vctTable.js
    -----------------------------------------------------------------------------------------
 
    IF OBJECT_ID('tempdb..#TmpUsers') IS NOT NULL
        DROP TABLE #TmpUsers;
 
    SELECT
        Usuario      = ISNULL(u.Id, ''),                   -- Clave principal mapeada con data-vct-field="Usuario"
        Descripcion  = ISNULL(u.Name, ''),
        Email        = ISNULL(u.Email, ''),
        CodigoEstado = u.State,                            -- Oculta en UI
        Estado       = CASE
                            WHEN u.State = 1 THEN 'Activa'
                            ELSE 'No Activa'
                       END,
        Perfil       = ISNULL(g.Name, ''),
        CodigoPerfil = ISNULL(g.Id, ''),                  -- Oculta en UI
        Sector       = ISNULL(SECTUSU.sectores, ''),
        IdUserSector = ISNULL(SECTUSU.idUserSectores, ''), -- Oculta en UI
        Fallidos     = ISNULL(u.LoginFailure, 0)
    INTO #TmpUsers
    FROM Users u WITH (NOLOCK)
        LEFT OUTER JOIN GroupsUserMembers gu WITH (NOLOCK)
            ON u.Id = gu.UserMemberId
        LEFT OUTER JOIN Groups g WITH (NOLOCK)
            ON gu.GroupId = g.Id
        LEFT OUTER JOIN
        (
            SELECT
                ussec.Id_User,
                STRING_AGG(
                    sct.Desc_Sector,
                    ', '
                ) AS sectores,
                STRING_AGG(
                    CAST(ussec.Id_Sector AS VARCHAR(MAX)),
                    ','
                ) AS idUserSectores
            FROM UsersSector ussec WITH (NOLOCK)
                INNER JOIN Sectores sct WITH (NOLOCK)
                    ON ussec.Id_Sector = sct.Id_Sector
            GROUP BY
                ussec.Id_User
        ) SECTUSU
            ON u.Id = SECTUSU.Id_User;
 
    -----------------------------------------------------------------------------------------
    -- 2. CONFIGURACIÓN DE ACCIONES
    -- 'keyField' apunta exactamente a "Usuario" para vincular con la grilla y vct-Tabs.js
    -----------------------------------------------------------------------------------------
 
    DECLARE @Actions VARCHAR(MAX);
 
    SET @Actions = '
    [
        {
            "type": "edit",
            "title": "Editar usuario",
            "keyField": "Usuario",
            "tabName": "form"
        }
    ]';
 
    -----------------------------------------------------------------------------------------
    -- 3. GENERAR GRILLA
    -----------------------------------------------------------------------------------------
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpUsers',
         @FormId        = @FORM_ID,
         @ActionsJson   = @Actions,
         @PageSize      = 10,
         @HiddenColumns = 'CodigoEstado,CodigoPerfil,IdUserSector';
 
    -----------------------------------------------------------------------------------------
    -- 4. LIMPIAR TABLA TEMPORAL
    -----------------------------------------------------------------------------------------
 
    IF OBJECT_ID('tempdb..#TmpUsers') IS NOT NULL
        DROP TABLE #TmpUsers;
 
END
