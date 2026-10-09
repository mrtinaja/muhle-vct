USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_UPD_GROUPS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[M_CONFIG_UPD_GROUPS]
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
        @VNEW_ID       VARCHAR(100),
        @VNEW_NAME     NVARCHAR(200),
        @VERROR_MSG    NVARCHAR(500) = '',
        @VES_NUEVO     BIT = 0,
        @VACCION_LOG   VARCHAR(50),
        @VDETALLE_LOG  VARCHAR(500)

    SELECT
        @VNEW_ID   = LTRIM(RTRIM(ISNULL(NEW_ID, ''))),
        @VNEW_NAME = LTRIM(RTRIM(ISNULL(NEW_NAME, '')))
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    -- Validaciones básicas
    IF @VNEW_ID = ''
    BEGIN
        SET @ORETCODE = 1;
        UPDATE M_CONFIG SET DESC_ERROR = 'Debe especificar el Código / ID del Perfil.' WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END

    IF @VNEW_NAME = ''
    BEGIN
        SET @ORETCODE = 1;
        UPDATE M_CONFIG SET DESC_ERROR = 'Debe ingresar el Nombre del Perfil.' WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END

    -- Validación de duplicados
    IF EXISTS (
        SELECT 1
        FROM Groups WITH (NOLOCK)
        WHERE LOWER(LTRIM(RTRIM(Name))) = LOWER(@VNEW_NAME)
          AND LOWER(LTRIM(RTRIM(Id))) <> LOWER(@VNEW_ID)
    )
    BEGIN
        SET @ORETCODE = 1;
        SET @VERROR_MSG = 'Ya existe otro perfil registrado con el nombre "' + @VNEW_NAME + '".';
        UPDATE M_CONFIG SET DESC_ERROR = @VERROR_MSG WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END

    -- Determinar si es alta o edición ANTES de escribir, para loguear correctamente
    SET @VES_NUEVO = CASE WHEN EXISTS (SELECT 1 FROM Groups WITH (NOLOCK) WHERE Id = @VNEW_ID) THEN 0 ELSE 1 END;

    -- Guardado
    BEGIN TRANSACTION;

    BEGIN TRY
        IF @VES_NUEVO = 0
        BEGIN
            UPDATE Groups SET Name = @VNEW_NAME WHERE Id = @VNEW_ID;
        END
        ELSE
        BEGIN
            INSERT INTO Groups (Id, Name) VALUES (@VNEW_ID, @VNEW_NAME);
        END

        -- Limpieza M_CONFIG
        UPDATE M_CONFIG
        SET ID_GROUP_SEL = NULL,
            NEW_ID       = NULL,
            NEW_NAME     = NULL,
            DESC_ERROR   = NULL
        WHERE PAR_KEY = @IPKEYJOB;

        COMMIT TRANSACTION;

        SET @VACCION_LOG  = CASE WHEN @VES_NUEVO = 1 THEN 'ALTA' ELSE 'MODIFICACION' END;
        SET @VDETALLE_LOG = (CASE WHEN @VES_NUEVO = 1 THEN 'Alta de perfil: ' ELSE 'Edición de perfil: ' END) + @VNEW_NAME;

        EXEC dbo.VCT_LOG_AUDITORIA
             @MODULO            = 'PERFILES',
             @ACCION            = @VACCION_LOG,
             @USER_ID           = @IUSERID,
             @REGISTRO_AFECTADO = @VNEW_ID,
             @DETALLE           = @VDETALLE_LOG;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ORETCODE = 1;
        SET @VERROR_MSG = ERROR_MESSAGE();
        UPDATE M_CONFIG SET DESC_ERROR = @VERROR_MSG WHERE PAR_KEY = @IPKEYJOB;
        RETURN;
    END CATCH
END
