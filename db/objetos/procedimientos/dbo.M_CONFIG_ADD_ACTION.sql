CREATE PROCEDURE [dbo].[M_CONFIG_ADD_ACTION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @ORETCODE	AS INT = NULL OUTPUT)
AS
BEGIN
    SET NOCOUNT ON;
    SET @ORETCODE = 0;
 
    DECLARE
        @ID_ACTION_SEL VARCHAR(100),
        @NEW_ID        VARCHAR(50),
        @NEW_NAME      VARCHAR(100),
        @VEXISTE       INT = 0,
        @VACCION_LOG   VARCHAR(50),
        @VDETALLE_LOG  VARCHAR(500),
        @VREGISTRO_LOG VARCHAR(100),
        @VNAME_OLD     VARCHAR(100),
        @VTIPO         VARCHAR(20);
 
    SELECT
        @ID_ACTION_SEL = LTRIM(RTRIM(ISNULL(ID_ACTION_SEL, ''))),
        @NEW_ID        = LTRIM(RTRIM(ISNULL(NEW_ID, ''))),
        @NEW_NAME      = LTRIM(RTRIM(ISNULL(NEW_NAME, ''))),
        @VTIPO         = NULLIF(LTRIM(RTRIM(ISNULL(NEW_PERFIL, ''))), '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- Validaciones básicas
    IF ISNULL(@NEW_ID, '') = ''
    BEGIN
        SET @ORETCODE = 1;
        UPDATE dbo.M_CONFIG SET DESC_ERROR = 'Debe completar el campo Código de Acción' WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END
 
    IF ISNULL(@NEW_NAME, '') = ''
    BEGIN
        SET @ORETCODE = 1;
        UPDATE dbo.M_CONFIG SET DESC_ERROR = 'Debe completar el campo Nombre' WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END
 
    SET @NEW_ID = UPPER(@NEW_ID);
 
    IF (@ID_ACTION_SEL = '')
    BEGIN
        -- ===== ALTA =====
        SELECT @VEXISTE = COUNT(1)
        FROM dbo.Actions WITH (NOLOCK)
        WHERE Id = @NEW_ID;
 
        IF @VEXISTE <> 0
        BEGIN
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG SET DESC_ERROR = 'Ya existe una acción con el código ingresado' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, Tipo)
            VALUES (@NEW_ID, @NEW_NAME, NEWID(), GETDATE(), @VTIPO);
 
            COMMIT TRANSACTION;
 
            SET @VACCION_LOG  = 'ALTA';
            SET @VDETALLE_LOG = 'Alta de acción: ' + @NEW_ID + ' (' + @NEW_NAME + ')';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG SET DESC_ERROR = ERROR_MESSAGE() WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END CATCH
    END
    ELSE
    BEGIN
        -- ===== MODIFICACIÓN =====
        SELECT @VEXISTE = COUNT(1)
        FROM dbo.Actions WITH (NOLOCK)
        WHERE Id = @ID_ACTION_SEL;
 
        IF @VEXISTE = 0
        BEGIN
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG SET DESC_ERROR = 'La acción seleccionada ya no existe' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            SELECT @VNAME_OLD = Name
            FROM dbo.Actions WITH (NOLOCK)
            WHERE Id = @ID_ACTION_SEL;
 
            UPDATE dbo.Actions
            SET Name = @NEW_NAME,
                ModifiedDate = GETDATE(),
                Tipo = @VTIPO
            WHERE Id = @ID_ACTION_SEL;
 
            COMMIT TRANSACTION;
 
            SET @VACCION_LOG  = 'MODIFICACION';
            SET @VDETALLE_LOG = 'Edición de acción: ' + @ID_ACTION_SEL + ' (' + ISNULL(@VNAME_OLD, '') + ' -> ' + @NEW_NAME + ')';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG SET DESC_ERROR = ERROR_MESSAGE() WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END CATCH
    END
 
    SET @VREGISTRO_LOG = ISNULL(NULLIF(@ID_ACTION_SEL, ''), @NEW_ID);
 
    EXEC dbo.VCT_LOG_AUDITORIA
         @MODULO            = 'PERFIL_ADMIN',
         @ACCION            = @VACCION_LOG,
         @USER_ID           = @IUSERID,
         @REGISTRO_AFECTADO = @VREGISTRO_LOG,
         @DETALLE           = @VDETALLE_LOG;
 
    UPDATE dbo.M_CONFIG
    SET DESC_ERROR    = NULL,
        ID_ACTION_SEL = NULL,
        NEW_PERFIL    = NULL,
        NEW_NIVEL     = NULL,
        ID_TASK_SEL   = NULL
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ORETCODE = 0;
    RETURN;
END
