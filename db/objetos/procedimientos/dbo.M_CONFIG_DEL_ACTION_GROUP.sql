 
CREATE PROCEDURE [dbo].[M_CONFIG_DEL_ACTION_GROUP]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @ID_ACTION_SEL VARCHAR(100) = '',
        @ID_GROUP_SEL  VARCHAR(100) = '',
        @V_ROWS        INT = 0,
        @VPERFIL_DESC  VARCHAR(250) = '',
        @VDESC_PERMISO VARCHAR(250) = '',
        @VDETALLE_LOG  VARCHAR(500) = '';
 
    -- Leer ID_DELETE guardado por la grilla
    SELECT
        @ID_ACTION_SEL = ISNULL(ID_DELETE, ''),
        @ID_GROUP_SEL  = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_ACTION_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@ID_ACTION_SEL, ',', ''), '''', ''), '"', '')));
    SET @ID_GROUP_SEL  = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@ID_GROUP_SEL, ',', ''), '''', ''), '"', '')));
 
    -- Si vino vacío, cancelamos
    IF @ID_ACTION_SEL = '' OR @ID_GROUP_SEL = ''
        RETURN;
 
    -- Descripciones para el log (se resuelven antes del DELETE)
    SELECT TOP 1 @VPERFIL_DESC  = ISNULL(Name, '') FROM dbo.Groups WITH (NOLOCK) WHERE Id = @ID_GROUP_SEL;
    SELECT TOP 1 @VDESC_PERMISO = ISNULL(Name, '') FROM dbo.Actions WITH (NOLOCK) WHERE Id = @ID_ACTION_SEL;
 
    BEGIN TRANSACTION;
    BEGIN TRY
 
        DELETE FROM dbo.GroupsActions
        WHERE UPPER(LTRIM(RTRIM(GroupId)))  = UPPER(@ID_GROUP_SEL)
          AND UPPER(LTRIM(RTRIM(ActionId))) = UPPER(@ID_ACTION_SEL);
 
        SET @V_ROWS = @@ROWCOUNT;
 
        COMMIT TRANSACTION;
 
        IF @V_ROWS > 0
        BEGIN
            SET @VDETALLE_LOG = 'Permiso "' + ISNULL(NULLIF(@VDESC_PERMISO, ''), @ID_ACTION_SEL) + '" quitado del perfil ' + ISNULL(NULLIF(@VPERFIL_DESC, ''), @ID_GROUP_SEL);
 
            EXEC dbo.VCT_LOG_AUDITORIA
                 @MODULO            = 'PERFIL_ADMIN',
                 @ACCION            = 'DESASOCIAR',
                 @USER_ID           = @IUSERID,
                 @REGISTRO_AFECTADO = @ID_GROUP_SEL,
                 @DETALLE           = @VDETALLE_LOG;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
 
        DECLARE @ErrMsg VARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
 
    RETURN;
END
