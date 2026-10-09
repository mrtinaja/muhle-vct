USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_DEL_TASK_GROUP] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[M_CONFIG_DEL_TASK_GROUP]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @V_GROUP_ID    VARCHAR(100) = '',
        @V_DELETE_KEY  VARCHAR(100) = '',
        @V_ROWS        INT = 0,
        @V_PERFIL_DESC VARCHAR(250) = '',
        @V_MENU_DESC   VARCHAR(250) = '',
        @V_DETALLE_LOG VARCHAR(500) = '';

    -- Capturamos el ID del grupo y el ID a eliminar probando ID_DELETE e ID_TASK_SEL
    SELECT
        @V_GROUP_ID   = LTRIM(RTRIM(ISNULL(ID_GROUP_SEL, ''))),
        @V_DELETE_KEY = COALESCE(
                            NULLIF(LTRIM(RTRIM(ISNULL(ID_DELETE, ''))), ''),
                            NULLIF(LTRIM(RTRIM(ISNULL(ID_TASK_SEL, ''))), ''),
                            ''
                        )
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    SET @V_GROUP_ID   = REPLACE(REPLACE(REPLACE(@V_GROUP_ID, '''', ''), '"', ''), ',', '');
    SET @V_DELETE_KEY = REPLACE(REPLACE(REPLACE(@V_DELETE_KEY, '''', ''), '"', ''), ',', '');

    -- Descripciones para el log (se resuelven antes del DELETE)
    SELECT TOP 1 @V_PERFIL_DESC = ISNULL(Name, '') FROM dbo.Groups WITH (NOLOCK) WHERE Id = @V_GROUP_ID;
    SELECT TOP 1 @V_MENU_DESC   = ISNULL(Name, '') FROM dbo.SideBar WITH (NOLOCK) WHERE CONVERT(VARCHAR(50), Id) = @V_DELETE_KEY;

    -- Eliminación física por relación SideBarId + GroupId o por PK Id
    IF @V_GROUP_ID <> '' AND @V_DELETE_KEY <> ''
    BEGIN
        DELETE FROM dbo.SideBarGroups
        WHERE GroupId = @V_GROUP_ID
          AND (SideBarId = @V_DELETE_KEY OR Id = @V_DELETE_KEY);

        SET @V_ROWS = @@ROWCOUNT;
    END

    IF @V_ROWS > 0
    BEGIN
        SET @V_DETALLE_LOG = 'Menú "' + ISNULL(NULLIF(@V_MENU_DESC, ''), @V_DELETE_KEY) + '" desasociado del perfil ' + ISNULL(NULLIF(@V_PERFIL_DESC, ''), @V_GROUP_ID);

        EXEC dbo.VCT_LOG_AUDITORIA
             @MODULO            = 'PERFIL_ADMIN',
             @ACCION            = 'DESASOCIAR',
             @USER_ID           = @IUSERID,
             @REGISTRO_AFECTADO = @V_GROUP_ID,
             @DETALLE           = @V_DETALLE_LOG;
    END

    -- Limpieza de buffer
    UPDATE dbo.M_CONFIG
    SET ID_DELETE   = NULL,
        ID_TASK_SEL = NULL
    WHERE PAR_KEY = @IPKEYJOB;

END
