 
CREATE PROCEDURE [dbo].[SV_02_UPD_CLIENTE]
(
    @IPKEYJOB  VARCHAR(100),
    @IUSERID   VARCHAR(100),
    @ORETCODE  INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @ORETCODE = 0;
 
    DECLARE @VCLAVE         VARCHAR(100),
            @VCUIT          VARCHAR(50),
            @VRAZON_SOCIAL  VARCHAR(300),
            @VCALLE         VARCHAR(100),
            @VNRO           VARCHAR(30),
            @VPISO          VARCHAR(30),
            @VLOCALIDAD     VARCHAR(100),
            @VPROVINCIA     VARCHAR(50),
            @VTELEFONO1     VARCHAR(100),
            @VTELEFONO2     VARCHAR(100),
            @VEMAIL         VARCHAR(100),
            @VIVA           VARCHAR(50),
            @VCONTACTO      VARCHAR(MAX), -- Ampliado temporalmente para evitar corte en lectura
            @VTIPO_CLIENTE  VARCHAR(50),
            @DESC_ERROR     VARCHAR(1000) = '';
 
    -- 1. Leer los datos desde la tabla de trabajo del Job (TMT_SV_02)
    SELECT 
        @VCLAVE        = LTRIM(RTRIM(ISNULL(CLAVE, ''))),
        @VCUIT         = LTRIM(RTRIM(ISNULL(CUIT, ''))),
        @VRAZON_SOCIAL = LTRIM(RTRIM(ISNULL(RAZON_SOCIAL, ''))),
        @VCALLE        = LTRIM(RTRIM(ISNULL(CALLE, ''))),
        @VNRO          = LTRIM(RTRIM(ISNULL(NRO, ''))),
        @VPISO         = LTRIM(RTRIM(ISNULL(PISO, ''))),
        @VLOCALIDAD    = LTRIM(RTRIM(ISNULL(LOCALIDAD, ''))),
        @VPROVINCIA    = LTRIM(RTRIM(ISNULL(PROVINCIA, ''))),
        @VTELEFONO1    = LTRIM(RTRIM(ISNULL(TELEFONO1, ''))),
        @VTELEFONO2    = LTRIM(RTRIM(ISNULL(TELEFONO2, ''))),
        @VEMAIL        = LTRIM(RTRIM(ISNULL(EMAIL, ''))),
        @VIVA          = LTRIM(RTRIM(ISNULL(IVA, ''))),
        @VCONTACTO     = LTRIM(RTRIM(ISNULL(CONTACTO, ''))),
        @VTIPO_CLIENTE = LTRIM(RTRIM(ISNULL(TIPO_CLIENTE, '')))
    FROM dbo.TMT_SV_02 WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- 2. VALIDACIONES DE UNICIDAD (CUIT y Razón Social)
    IF EXISTS (
        SELECT 1 
        FROM dbo.LK_CLIENTES WITH (NOLOCK) 
        WHERE CUIT_CLIENTE = @VCUIT 
          AND @VCUIT <> '' 
          AND CONVERT(VARCHAR(100), ID_CLIENTE) <> @VCLAVE
    )
    BEGIN
        SET @DESC_ERROR = 'El CUIT ' + @VCUIT + ' ya se encuentra registrado para otro cliente.';
    END
 
    IF @DESC_ERROR = '' AND EXISTS (
        SELECT 1 
        FROM dbo.LK_CLIENTES WITH (NOLOCK) 
        WHERE RAZON_SOCIAL_CLIENTE = @VRAZON_SOCIAL 
          AND @VRAZON_SOCIAL <> '' 
          AND CONVERT(VARCHAR(100), ID_CLIENTE) <> @VCLAVE
    )
    BEGIN
        SET @DESC_ERROR = 'La Razón Social "' + @VRAZON_SOCIAL + '" ya se encuentra registrada para otro cliente.';
    END
 
    -- 3. SI HAY ERROR: Notificar en TMT_SV_02 y abortar
    IF @DESC_ERROR <> ''
    BEGIN
        UPDATE dbo.TMT_SV_02
           SET ERROR = @DESC_ERROR
         WHERE PAR_KEY = @IPKEYJOB;
 
        SET @ORETCODE = 1;
        RETURN;
    END
 
    -- 4. SI PASA VALIDACIONES: Transacción recortando cadenas que superen límites
    BEGIN TRANSACTION;
 
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.LK_CLIENTES WITH (NOLOCK) WHERE CONVERT(VARCHAR(100), ID_CLIENTE) = @VCLAVE AND @VCLAVE <> '')
        BEGIN
            -- MODO EDICIÓN CON TRUNCAMIENTO DE BLINDAJE
            UPDATE dbo.LK_CLIENTES
               SET CUIT_CLIENTE         = LEFT(@VCUIT, 50),
                   CALLE_CLIENTE        = LEFT(@VCALLE, 100),
                   NRO_CALLE_CLIENTE    = LEFT(@VNRO, 30),
                   PISO_DEPTO_CLIENTE   = LEFT(@VPISO, 30),
                   LOCALIDAD_CLIENTE    = LEFT(@VLOCALIDAD, 100),
                   PROVINCIA_CLIENTE    = LEFT(@VPROVINCIA, 50),
                   TEL1_CLIENTE         = LEFT(@VTELEFONO1, 100),
                   TEL2_CLIENTE         = LEFT(@VTELEFONO2, 100),
                   EMAIL_CLIENTE        = LEFT(@VEMAIL, 100),
                   IVA_CLIENTE          = LEFT(@VIVA, 50),
                   CONTACTO_CLIENTE     = @VCONTACTO, -- Si la columna es VARCHAR(4000) o TEXT
                   TIPO_CLIENTE         = LEFT(@VTIPO_CLIENTE, 50),
                   FECHA_UPD            = GETDATE(),
                   USUARIO_UPD          = LEFT(@IUSERID, 100)
             WHERE ID_CLIENTE = CONVERT(INT, @VCLAVE);
        END
        ELSE
        BEGIN
            -- MODO ALTA CON TRUNCAMIENTO DE BLINDAJE
            INSERT INTO dbo.LK_CLIENTES
            (
                RAZON_SOCIAL_CLIENTE, CUIT_CLIENTE, CALLE_CLIENTE, NRO_CALLE_CLIENTE,
                PISO_DEPTO_CLIENTE, LOCALIDAD_CLIENTE, PROVINCIA_CLIENTE, TEL1_CLIENTE,
                TEL2_CLIENTE, EMAIL_CLIENTE, IVA_CLIENTE, CONTACTO_CLIENTE, TIPO_CLIENTE,
                STATUS_CLIENTE, FECHA_ALTA, USUARIO_ALTA
            )
            VALUES
            (
                LEFT(@VRAZON_SOCIAL, 300), LEFT(@VCUIT, 50), LEFT(@VCALLE, 100), LEFT(@VNRO, 30),
                LEFT(@VPISO, 30), LEFT(@VLOCALIDAD, 100), LEFT(@VPROVINCIA, 50), LEFT(@VTELEFONO1, 100),
                LEFT(@VTELEFONO2, 100), LEFT(@VEMAIL, 100), LEFT(@VIVA, 50), @VCONTACTO, LEFT(@VTIPO_CLIENTE, 50),
                '1', GETDATE(), LEFT(@IUSERID, 100)
            );
        END
 
        -- Limpiar estado de error
        UPDATE dbo.TMT_SV_02
           SET ERROR = NULL
         WHERE PAR_KEY = @IPKEYJOB;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
 
        SET @DESC_ERROR = ERROR_MESSAGE();
 
        UPDATE dbo.TMT_SV_02
           SET ERROR = @DESC_ERROR
         WHERE PAR_KEY = @IPKEYJOB;
 
        SET @ORETCODE = 1;
        RAISERROR(@DESC_ERROR, 16, 1);
    END CATCH
END
