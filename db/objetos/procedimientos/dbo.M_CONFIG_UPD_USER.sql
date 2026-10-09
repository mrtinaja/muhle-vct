 
CREATE PROCEDURE [dbo].[M_CONFIG_UPD_USER]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @ORETCODE INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ID_USER_SEL    VARCHAR(100),
            @NEW_ID_INPUT   VARCHAR(100),
            @VNOMBRE_TMT    NVARCHAR(200),
            @VEMAIL_TMT     NVARCHAR(300),
            @VPASS_TMT      VARCHAR(200),
            @VESTADO_TMT    VARCHAR(50),
            @VESTADO_CODE   INT,
            @VPERFIL_TMT    VARCHAR(100),
            @CURRENT_PASS   VARCHAR(150),
            @VPERFIL_OLD    VARCHAR(100),
            @ES_NUEVO       BIT = 0,
            @VACCION_LOG    VARCHAR(50),
            @VDETALLE_LOG   VARCHAR(500);
 
    -------------------------------------------------------------------
    -- 1. LECTURA Y LIMPIEZA DEL BUFFER (M_CONFIG)
    -------------------------------------------------------------------
    SELECT  @ID_USER_SEL    = ISNULL(LTRIM(RTRIM(ID_USER_SEL)), ''),
            @NEW_ID_INPUT   = ISNULL(LTRIM(RTRIM(NEW_ID)), ''),
            @VNOMBRE_TMT    = ISNULL(NEW_NAME, ''),
            @VEMAIL_TMT     = ISNULL(NEW_EMAIL, ''),
            @VPASS_TMT      = ISNULL(NEW_PASSWORD, ''),
            @VESTADO_TMT    = ISNULL(NEW_ESTADO_CUENTA, ''),
            @VPERFIL_TMT    = ISNULL(NEW_PERFIL, '')
    FROM    dbo.M_CONFIG WITH (NOLOCK)
    WHERE   PAR_KEY = @IPKEYJOB;
 
    -- Normalización
    SET @ID_USER_SEL  = ISNULL(@ID_USER_SEL, '');
    SET @NEW_ID_INPUT = ISNULL(@NEW_ID_INPUT, '');
    SET @VNOMBRE_TMT  = ISNULL(LTRIM(RTRIM(@VNOMBRE_TMT)), '');
    SET @VEMAIL_TMT   = ISNULL(LTRIM(RTRIM(@VEMAIL_TMT)), '');
    SET @VPASS_TMT    = ISNULL(LTRIM(RTRIM(@VPASS_TMT)), '');
    SET @VPERFIL_TMT  = ISNULL(LTRIM(RTRIM(@VPERFIL_TMT)), '');
 
    -- DETERMINAR SI ES ALTA O EDICIÓN:
    -- Si ID_USER_SEL viene vacío, es un Alta pura.
    -- Si ID_USER_SEL coincide con NEW_ID_INPUT pero no existe en Users, es Alta.
    IF @ID_USER_SEL = '' OR NOT EXISTS (SELECT 1 FROM dbo.Users WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(Id))) = UPPER(@ID_USER_SEL))
    BEGIN
        SET @ES_NUEVO = 1;
        IF @NEW_ID_INPUT <> '' SET @ID_USER_SEL = @NEW_ID_INPUT;
    END
    ELSE
    BEGIN
        SET @ES_NUEVO = 0;
    END
 
    -------------------------------------------------------------------
    -- 2. REGLAS DE NEGOCIO Y CONTROL DE DUPLICADOS
    -------------------------------------------------------------------
    -- A) Validaciones para ALTA
    IF @ES_NUEVO = 1
    BEGIN
        -- Control de ID de Usuario duplicado en Users
        IF EXISTS (SELECT 1 FROM dbo.Users WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(Id))) = UPPER(@ID_USER_SEL))
        BEGIN
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG
            SET DESC_ERROR = 'El ID de usuario "' + @ID_USER_SEL + '" ya existe en el sistema. Elija otro identificador.'
            WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        -- Control de Nombre y Apellido duplicado en Alta
        IF @VNOMBRE_TMT <> '' AND EXISTS (SELECT 1 FROM dbo.Users WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(Name))) = UPPER(@VNOMBRE_TMT))
        BEGIN
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG
            SET DESC_ERROR = 'El Nombre y Apellido "' + @VNOMBRE_TMT + '" ya está registrado para otro usuario.'
            WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
    END
    -- B) Validaciones para EDICIÓN
    ELSE
    BEGIN
        -- Control de Nombre y Apellido duplicado pertenecientes a OTRO usuario
        IF @VNOMBRE_TMT <> '' AND EXISTS (
            SELECT 1
            FROM dbo.Users WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(Name))) = UPPER(@VNOMBRE_TMT)
              AND UPPER(LTRIM(RTRIM(Id))) <> UPPER(@ID_USER_SEL)
        )
        BEGIN
            SET @ORETCODE = 1;
            UPDATE dbo.M_CONFIG
            SET DESC_ERROR = 'El Nombre y Apellido "' + @VNOMBRE_TMT + '" ya pertenece a otro usuario registrado.'
            WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
    END
 
    -------------------------------------------------------------------
    -- 3. PROCESAMIENTO DE CONTRASEÑA Y ESTADO
    -------------------------------------------------------------------
    IF @VPASS_TMT <> ''
    BEGIN
        SET @VPASS_TMT = CONVERT(VARCHAR(40), HashBytes('SHA1', UPPER(@ID_USER_SEL) + @VPASS_TMT), 2);
    END
 
    IF ISNUMERIC(@VESTADO_TMT) = 1
        SET @VESTADO_CODE = CAST(@VESTADO_TMT AS INT);
    ELSE
        SELECT TOP 1 @VESTADO_CODE = CAST(attr1 AS INT)
        FROM dbo.CAT_DATA WITH (NOLOCK)
        WHERE CAT_DATA_CODE = @VESTADO_TMT;
 
    SET @VESTADO_CODE = ISNULL(@VESTADO_CODE, 1);
 
    -------------------------------------------------------------------
    -- 4. TRANSACCIÓN
    -------------------------------------------------------------------
    BEGIN TRANSACTION;
    BEGIN TRY
 
        IF @ES_NUEVO = 1
        BEGIN
            INSERT INTO dbo.Users (Id, [Name], Email, [Password], [State], LoginFailure, ModifiedDate)
            VALUES (@ID_USER_SEL, @VNOMBRE_TMT, @VEMAIL_TMT, @VPASS_TMT, @VESTADO_CODE, 0, GETDATE());
        END
        ELSE
        BEGIN
            UPDATE  dbo.Users
            SET     [Name]       = CASE WHEN @VNOMBRE_TMT <> '' THEN @VNOMBRE_TMT ELSE [Name] END,
                    Email        = CASE WHEN @VEMAIL_TMT <> ''  THEN @VEMAIL_TMT  ELSE Email END,
                    [Password]   = CASE WHEN @VPASS_TMT <> ''   THEN @VPASS_TMT   ELSE [Password] END,
                    [State]      = @VESTADO_CODE,
                    LoginFailure = 0,
                    ModifiedDate = GETDATE()
            WHERE   UPPER(LTRIM(RTRIM([Id]))) = UPPER(@ID_USER_SEL);
        END
 
        IF (@VPERFIL_TMT <> '')
        BEGIN
            DELETE FROM dbo.GroupsUserMembers
            WHERE UPPER(LTRIM(RTRIM(UserMemberId))) = UPPER(@ID_USER_SEL);
 
            INSERT INTO dbo.GroupsUserMembers (GroupId, UserMemberId, rowguid, ModifiedDate)
            VALUES (@VPERFIL_TMT, UPPER(@ID_USER_SEL), NEWID(), GETDATE());
        END
 
        COMMIT TRANSACTION;
 
        SET @VACCION_LOG  = CASE WHEN @ES_NUEVO = 1 THEN 'ALTA' ELSE 'MODIFICACION' END;
        SET @VDETALLE_LOG = (CASE WHEN @ES_NUEVO = 1 THEN 'Alta de usuario ' ELSE 'Edición de usuario ' END) + @ID_USER_SEL;
 
        EXEC dbo.VCT_LOG_AUDITORIA
             @MODULO            = 'USUARIOS',
             @ACCION            = @VACCION_LOG,
             @USER_ID           = @IUSERID,
             @REGISTRO_AFECTADO = @ID_USER_SEL,
             @DETALLE           = @VDETALLE_LOG;
 
        IF (@VPERFIL_TMT <> '')
        BEGIN
            SET @VDETALLE_LOG = 'Usuario ' + @ID_USER_SEL + ' asociado al perfil ' + @VPERFIL_TMT;
 
            EXEC dbo.VCT_LOG_AUDITORIA
                 @MODULO            = 'PERFILES',
                 @ACCION            = 'ASOCIAR',
                 @USER_ID           = @IUSERID,
                 @REGISTRO_AFECTADO = @ID_USER_SEL,
                 @DETALLE           = @VDETALLE_LOG;
        END
 
        UPDATE dbo.M_CONFIG SET DESC_ERROR = NULL WHERE PAR_KEY = @IPKEYJOB;
 
        SET @ORETCODE = 0;
        RETURN;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 
        SET @ORETCODE = 1;
 
        UPDATE dbo.M_CONFIG
        SET    DESC_ERROR = ERROR_MESSAGE()
        WHERE  PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END CATCH
END
