USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_ADD_ACTION_GROUP] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[M_CONFIG_ADD_ACTION_GROUP]
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
        @VPERFIL_DESC  VARCHAR(250) = '',
        @VDESC_PERMISO VARCHAR(250) = '',
        @VINSERTED     BIT = 0,
        @VDETALLE_LOG  VARCHAR(500) = '';

    -- 1. Leer y sanear datos desde M_CONFIG
    SELECT
        @ID_ACTION_SEL = ISNULL(ID_ACTION_SEL, ''),
        @ID_GROUP_SEL  = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    SET @ID_ACTION_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@ID_ACTION_SEL, ',', ''), '''', ''), '"', '')));
    SET @ID_GROUP_SEL  = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@ID_GROUP_SEL, ',', ''), '''', ''), '"', '')));

    -- Validar que no vengan vacíos
    IF @ID_ACTION_SEL = '' OR @ID_GROUP_SEL = ''
        RETURN;

    -- 2. Obtener nombres descriptivos para trazabilidad o logs
    SELECT TOP 1
        @VPERFIL_DESC = ISNULL(Name, '')
    FROM dbo.Groups WITH (NOLOCK)
    WHERE Id = @ID_GROUP_SEL;

    SELECT TOP 1
        @VDESC_PERMISO = ISNULL(Name, '')
    FROM dbo.Actions WITH (NOLOCK)
    WHERE Id = @ID_ACTION_SEL;

    -- 3. Transacción Segura de Inserción
    BEGIN TRANSACTION;
    BEGIN TRY

        -- Solo inserta si la relación aún no existe para evitar violaciones de clave única
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.GroupsActions WITH (NOLOCK)
            WHERE LTRIM(RTRIM(GroupId)) = @ID_GROUP_SEL
              AND LTRIM(RTRIM(ActionId)) = @ID_ACTION_SEL
        )
        BEGIN
            INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
            VALUES (@ID_GROUP_SEL, @ID_ACTION_SEL, NEWID(), GETDATE());

            SET @VINSERTED = 1;
        END

        COMMIT TRANSACTION;

        IF @VINSERTED = 1
        BEGIN
            SET @VDETALLE_LOG = 'Permiso "' + ISNULL(@VDESC_PERMISO, @ID_ACTION_SEL) + '" habilitado para el perfil ' + ISNULL(@VPERFIL_DESC, @ID_GROUP_SEL);

            EXEC dbo.VCT_LOG_AUDITORIA
                 @MODULO            = 'PERFIL_ADMIN',
                 @ACCION            = 'ASOCIAR',
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
