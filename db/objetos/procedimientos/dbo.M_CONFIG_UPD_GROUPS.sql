 
CREATE PROCEDURE [dbo].[M_CONFIG_UPD_GROUPS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @ORETCODE INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @ORETCODE = 0;
 
    DECLARE
        @VNEW_ID      VARCHAR(100) = '',
        @VNEW_NAME    NVARCHAR(200) = '',
        @VERROR_MSG   NVARCHAR(500) = '',
        @VES_NUEVO    BIT = 0,
        @VACCION_LOG  VARCHAR(50),
        @VDETALLE_LOG VARCHAR(500),
        @VFECHA       DATETIME;
 
    SELECT
        @VNEW_ID   = LTRIM(RTRIM(ISNULL(NEW_ID, ''))),
        @VNEW_NAME = LTRIM(RTRIM(ISNULL(NEW_NAME, '')))
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- Validaciones básicas
    IF @VNEW_ID = ''
    BEGIN
        SET @ORETCODE = 1;
 
        UPDATE dbo.M_CONFIG
        SET DESC_ERROR = 'Debe especificar el Código / ID del Perfil.'
        WHERE PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END;
 
    IF @VNEW_NAME = ''
    BEGIN
        SET @ORETCODE = 1;
 
        UPDATE dbo.M_CONFIG
        SET DESC_ERROR = 'Debe ingresar el Nombre del Perfil.'
        WHERE PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END;
 
    -- Validación de duplicados
    IF EXISTS
    (
        SELECT 1
        FROM dbo.Groups WITH (NOLOCK)
        WHERE LOWER(LTRIM(RTRIM(Name))) = LOWER(@VNEW_NAME)
          AND LOWER(LTRIM(RTRIM(Id))) <> LOWER(@VNEW_ID)
    )
    BEGIN
        SET @ORETCODE = 1;
 
        SET @VERROR_MSG =
            N'Ya existe otro perfil registrado con el nombre "'
            + @VNEW_NAME + N'".';
 
        UPDATE dbo.M_CONFIG
        SET DESC_ERROR = @VERROR_MSG
        WHERE PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END;
 
    -- Determinar si es alta o edición
    SET @VES_NUEVO =
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM dbo.Groups WITH (NOLOCK)
                WHERE Id = @VNEW_ID
            )
            THEN 0
            ELSE 1
        END;
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF @VES_NUEVO = 0
        BEGIN
            -- Edición: actualizar únicamente el perfil
            UPDATE dbo.Groups
            SET Name = @VNEW_NAME
            WHERE Id = @VNEW_ID;
        END
        ELSE
        BEGIN
            -- Alta del perfil
            INSERT INTO dbo.Groups
            (
                Id,
                Name
            )
            VALUES
            (
                @VNEW_ID,
                @VNEW_NAME
            );
 
            SET @VFECHA = GETDATE();
 
            -- Registrar en UNIT_CALL_TYPE solo al crear el perfil
            INSERT INTO dbo.UNIT_CALL_TYPE
            (
                PKEY,
                PAR_KEY,
                UNIT_CODE,
                UNIT_LEVEL,
                PKEY_CALL_TYPE,
                TS_BEGIN,
                TS_END,
                TS_USER_ID,
                PKEY_CUST_TYPE
            )
            VALUES
            (
                NEWID(),
                NULL,
                @VNEW_ID,
                2,
                'E0CD9397-2EC0-44EE-ACBB-D08A72ABC171',
                GETDATE(),
                GETDATE(),
                @IUSERID,
                NULL
            );
        END;
 
        -- Limpieza M_CONFIG
        UPDATE dbo.M_CONFIG
        SET ID_GROUP_SEL = NULL,
            NEW_ID       = NULL,
            NEW_NAME     = NULL,
            DESC_ERROR   = NULL
        WHERE PAR_KEY = @IPKEYJOB;
 
        COMMIT TRANSACTION;
 
        SET @VACCION_LOG =
            CASE
                WHEN @VES_NUEVO = 1 THEN 'ALTA'
                ELSE 'MODIFICACION'
            END;
 
        SET @VDETALLE_LOG =
            CASE
                WHEN @VES_NUEVO = 1 THEN 'Alta de perfil: '
                ELSE 'Edición de perfil: '
            END + @VNEW_NAME;
 
        EXEC dbo.VCT_LOG_AUDITORIA
            @MODULO            = 'PERFILES',
            @ACCION            = @VACCION_LOG,
            @USER_ID           = @IUSERID,
            @REGISTRO_AFECTADO = @VNEW_ID,
            @DETALLE           = @VDETALLE_LOG;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
 
        SET @ORETCODE = 1;
        SET @VERROR_MSG = LEFT(ERROR_MESSAGE(), 500);
 
        UPDATE dbo.M_CONFIG
        SET DESC_ERROR = @VERROR_MSG
        WHERE PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END CATCH;
END;
