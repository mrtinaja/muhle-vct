 
CREATE PROCEDURE [dbo].[M_CONFIG_UPD_SECTOR]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100),
    @ORETCODE AS INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @VACTION          VARCHAR(50)    = '',
        @ID_SECTOR_SEL    VARCHAR(50)    = '',
        @ID_SECTOR_SEL_INT INT           = NULL,
        @VNOMBRE_TMT      NVARCHAR(200)  = '',
        @VEMAIL_TMT       NVARCHAR(300)  = '',
        @VEXISTE          INT            = 0,
        @VNEW_SECTOR_ID   INT            = NULL,
        @VID_SECTOR_LOG   VARCHAR(50)    = NULL,
        @VDETALLE_LOG     VARCHAR(500)   = NULL;
 
    SET @ORETCODE = 0;
 
    SELECT TOP 1
        @VACTION       = UPPER(LTRIM(RTRIM(ISNULL(ACTION, '')))),
        @ID_SECTOR_SEL = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50), ID_SECTOR_SEL), ''))),
        @VEMAIL_TMT    = LTRIM(RTRIM(ISNULL(NEW_EMAIL, ''))),
        @VNOMBRE_TMT   = LTRIM(RTRIM(ISNULL(NEW_NAME, '')))
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF ISNULL(@VACTION, '') = ''
    BEGIN
        IF ISNULL(@ID_SECTOR_SEL, '') <> '' AND @ID_SECTOR_SEL <> '0'
            SET @VACTION = 'EDITAR';
        ELSE
            SET @VACTION = 'AGREGAR';
    END;
 
    IF ISNUMERIC(@ID_SECTOR_SEL) = 1
        SET @ID_SECTOR_SEL_INT = CONVERT(INT, @ID_SECTOR_SEL);
 
    IF ISNULL(@VNOMBRE_TMT, '') = ''
    BEGIN
        SET @ORETCODE = 1;
 
        UPDATE M_CONFIG
        SET DESC_ERROR = 'Debe completar el campo Nombre'
        WHERE PAR_KEY = @IPKEYJOB;
 
        RETURN;
    END;
 
    IF @VACTION = 'EDITAR'
    BEGIN
        IF ISNULL(@ID_SECTOR_SEL, '') = '' OR @ID_SECTOR_SEL = '0' OR @ID_SECTOR_SEL_INT IS NULL
        BEGIN
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = 'No se pudo identificar el sector a editar'
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END;
 
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Sectores WITH (NOLOCK)
            WHERE Id_Sector = @ID_SECTOR_SEL_INT
        )
        BEGIN
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = 'El sector seleccionado no existe'
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END;
 
        SELECT @VEXISTE = COUNT(1)
        FROM dbo.Sectores WITH (NOLOCK)
        WHERE LTRIM(RTRIM(Desc_Sector)) = @VNOMBRE_TMT
          AND Id_Sector <> @ID_SECTOR_SEL_INT;
 
        IF @VEXISTE <> 0
        BEGIN
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = 'Ya existe otro sector con el nombre ingresado'
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END;
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            UPDATE dbo.Sectores
            SET Desc_Sector  = @VNOMBRE_TMT,
                Mail_Sector  = NULLIF(@VEMAIL_TMT, ''),
                ModifiedDate = GETDATE(),
                Userid       = @IUSERID
            WHERE Id_Sector = @ID_SECTOR_SEL_INT;
 
            COMMIT TRANSACTION;
 
            SET @VID_SECTOR_LOG = CONVERT(VARCHAR(50), @ID_SECTOR_SEL_INT);
            SET @VDETALLE_LOG = 'Edición de sector: ' + @VNOMBRE_TMT;
 
            EXEC dbo.VCT_LOG_AUDITORIA
                 @MODULO            = 'ESTRUCTURA',
                 @ACCION            = 'MODIFICACION',
                 @USER_ID           = @IUSERID,
                 @REGISTRO_AFECTADO = @VID_SECTOR_LOG,
                 @DETALLE           = @VDETALLE_LOG;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = ERROR_MESSAGE()
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END CATCH;
 
        RETURN;
    END;
 
    IF @VACTION = 'AGREGAR'
    BEGIN
        SELECT @VEXISTE = COUNT(1)
        FROM dbo.Sectores WITH (NOLOCK)
        WHERE LTRIM(RTRIM(Desc_Sector)) = @VNOMBRE_TMT;
 
        IF @VEXISTE <> 0
        BEGIN
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = 'Ya existe otro sector con el nombre ingresado'
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END;
 
        BEGIN TRY
            BEGIN TRANSACTION;
 
            INSERT INTO dbo.Sectores
            (
                Desc_Sector,
                Mail_Sector,
                Id_Area,
                Id_Sector_Padre,
                Id_nivel,
                ModifiedDate,
                Userid
            )
            VALUES
            (
                @VNOMBRE_TMT,
                NULLIF(@VEMAIL_TMT, ''),
                NULL,
                0,
                1,
                GETDATE(),
                @IUSERID
            );
 
            SET @VNEW_SECTOR_ID = CAST(SCOPE_IDENTITY() AS INT);
 
            COMMIT TRANSACTION;
 
            SET @VID_SECTOR_LOG = CONVERT(VARCHAR(50), @VNEW_SECTOR_ID);
            SET @VDETALLE_LOG = 'Alta de sector: ' + @VNOMBRE_TMT;
 
            EXEC dbo.VCT_LOG_AUDITORIA
                 @MODULO            = 'ESTRUCTURA',
                 @ACCION            = 'ALTA',
                 @USER_ID           = @IUSERID,
                 @REGISTRO_AFECTADO = @VID_SECTOR_LOG,
                 @DETALLE           = @VDETALLE_LOG;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 
            SET @ORETCODE = 1;
 
            UPDATE M_CONFIG
            SET DESC_ERROR = ERROR_MESSAGE()
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END CATCH;
 
        RETURN;
    END;
 
    SET @ORETCODE = 1;
 
    UPDATE M_CONFIG
    SET DESC_ERROR = 'Acción no reconocida para sector'
    WHERE PAR_KEY = @IPKEYJOB;
END
