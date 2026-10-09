 
CREATE PROCEDURE [dbo].[SV_02_ALTA_CLIENTE]
(
    @IPKEYJOB   AS VARCHAR(100),
    @IAGENTE    AS VARCHAR(100),
    @OCODE      AS VARCHAR(2) OUTPUT,
    @OMENSAJE   AS VARCHAR(400) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @VCUIT          VARCHAR(50),
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
            @VCONTACTO      VARCHAR(4000),
            @VTIPO_CLIENTE  VARCHAR(50),
            @VESTADO        VARCHAR(50),
            @VOBSERVACIONES VARCHAR(400),
            @VERROR         VARCHAR(50),
            @VCANT          INT,
            @VCLAVE         VARCHAR(100);
 
    SET @OCODE = '0';
    SET @OMENSAJE = '';
 
    SELECT  @VCUIT          = ISNULL(CUIT,''),
            @VRAZON_SOCIAL  = ISNULL(RAZON_SOCIAL,''),
            @VCALLE         = ISNULL(CALLE,''),
            @VNRO           = ISNULL(NRO,''),
            @VPISO          = ISNULL(PISO,''),
            @VLOCALIDAD     = ISNULL(LOCALIDAD,''),
            @VPROVINCIA     = ISNULL(PROVINCIA,''),
            @VTELEFONO1     = ISNULL(TELEFONO1,''),
            @VTELEFONO2     = ISNULL(TELEFONO2,''),
            @VEMAIL         = ISNULL(EMAIL,''),
            @VIVA           = ISNULL(IVA,''),
            @VCONTACTO      = ISNULL(CONTACTO,''),
            @VTIPO_CLIENTE  = ISNULL(TIPO_CLIENTE,''),
            @VESTADO        = ISNULL(ESTADO,''),
            @VOBSERVACIONES = ISNULL(OBSERVACIONES,''),
            @VERROR         = ISNULL(ERROR,''),
            @VCLAVE         = ISNULL(CLAVE,'')
    FROM    TMT_SV_02
    WHERE   PAR_KEY = @IPKEYJOB;
 
    IF @VERROR <> '' 
    BEGIN
        IF (@VRAZON_SOCIAL = '') 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Atención", text:"Debe completar la Razón Social.", icon:"warning"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        IF (@VCUIT = '') 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Atención", text:"Debe ingresar un CUIT válido.", icon:"warning"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        IF (@VLOCALIDAD = '') 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Atención", text:"Debe ingresar la Localidad.", icon:"warning"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        IF (@VTIPO_CLIENTE = '') 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Atención", text:"Debe seleccionar un Tipo de Cliente.", icon:"warning"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        -- VERIFICACIÓN DE DUPLICIDAD DE CUIT
        IF (@VCLAVE = '')
            SELECT @VCANT = COUNT(1) FROM LK_CLIENTES WHERE CUIT_CLIENTE = LTRIM(RTRIM(@VCUIT));
        ELSE
            SELECT @VCANT = COUNT(1) FROM LK_CLIENTES WHERE CUIT_CLIENTE = LTRIM(RTRIM(@VCUIT)) AND ID_CLIENTE <> @VCLAVE;
 
        IF (@VCANT > 0) 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Duplicado", text:"Ya existe un cliente con ese CUIT registrado.", icon:"danger"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        -- VERIFICACIÓN DE DUPLICIDAD DE RAZÓN SOCIAL
        IF (@VCLAVE = '')
            SELECT @VCANT = COUNT(1) FROM LK_CLIENTES WHERE RAZON_SOCIAL_CLIENTE = LTRIM(RTRIM(@VRAZON_SOCIAL));
        ELSE
            SELECT @VCANT = COUNT(1) FROM LK_CLIENTES WHERE RAZON_SOCIAL_CLIENTE = LTRIM(RTRIM(@VRAZON_SOCIAL)) AND ID_CLIENTE <> @VCLAVE;
 
        IF (@VCANT > 0) 
        BEGIN
            SET @OCODE = '1';
            SET @OMENSAJE = '<script>vctConfirmDialog({title:"Duplicado", text:"Ya existe un cliente con la misma Razón Social.", icon:"danger"});</script>';
            UPDATE TMT_SV_02 SET ERROR = 'SI' WHERE PAR_KEY = @IPKEYJOB;
            RETURN;
        END
 
        -- OPERACIÓN EN BASE DE DATOS
        IF (@VCLAVE = '') 
        BEGIN
            INSERT INTO LK_CLIENTES
            (RAZON_SOCIAL_CLIENTE, CUIT_CLIENTE, CALLE_CLIENTE, NRO_CALLE_CLIENTE, PISO_DEPTO_CLIENTE,
             LOCALIDAD_CLIENTE, PROVINCIA_CLIENTE, TEL1_CLIENTE, TEL2_CLIENTE, EMAIL_CLIENTE, IVA_CLIENTE,
             CONTACTO_CLIENTE, TIPO_CLIENTE, STATUS_CLIENTE, OBSERV_CLIENTE,
             FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
            VALUES
            (@VRAZON_SOCIAL, @VCUIT, @VCALLE, @VNRO, @VPISO, 
             @VLOCALIDAD, @VPROVINCIA, @VTELEFONO1, @VTELEFONO2, @VEMAIL, @VIVA,
             @VCONTACTO, @VTIPO_CLIENTE, @VESTADO, @VOBSERVACIONES,
             GETDATE(), @IAGENTE, GETDATE(), @IAGENTE);
        END 
        ELSE 
        BEGIN
            UPDATE LK_CLIENTES
            SET    RAZON_SOCIAL_CLIENTE = @VRAZON_SOCIAL, 
                   CUIT_CLIENTE = @VCUIT, 
                   CALLE_CLIENTE = @VCALLE, 
                   NRO_CALLE_CLIENTE = @VNRO, 
                   PISO_DEPTO_CLIENTE = @VPISO,
                   LOCALIDAD_CLIENTE = @VLOCALIDAD, 
                   PROVINCIA_CLIENTE = @VPROVINCIA, 
                   TEL1_CLIENTE = @VTELEFONO1, 
                   TEL2_CLIENTE = @VTELEFONO2, 
                   EMAIL_CLIENTE = @VEMAIL, 
                   IVA_CLIENTE = @VIVA,
                   CONTACTO_CLIENTE = @VCONTACTO, 
                   TIPO_CLIENTE = @VTIPO_CLIENTE, 
                   STATUS_CLIENTE = @VESTADO, 
                   OBSERV_CLIENTE = @VOBSERVACIONES,
                   FECHA_UPD = GETDATE(), 
                   USUARIO_UPD = @IAGENTE
            WHERE  ID_CLIENTE = @VCLAVE;
        END
    END
 
    IF (@OCODE = '0') 
    BEGIN
        UPDATE TMT_SV_02 SET ERROR = 'NO' WHERE PAR_KEY = @IPKEYJOB;
    END
END
