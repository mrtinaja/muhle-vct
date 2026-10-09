 
CREATE PROCEDURE [dbo].[SV_02_INICIA_ALTA_CLIENTE]
(
    @IPKEYJOB        AS VARCHAR(100),
    @IUNIDAD        AS VARCHAR(100),
    @IAGENTE        AS VARCHAR(100),
    @IJOBSEQ        AS INT,
    @FORM_ID        AS VARCHAR(100),
    @OHEADER        AS VARCHAR(4000) OUTPUT,
    @OFOOTER        AS VARCHAR(4000) OUTPUT,
    @PS_TITULO      AS VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO  AS VARCHAR(MAX) OUTPUT,
    @PS_FORMU_FOOT  AS VARCHAR(MAX) OUTPUT
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
            @VCLAVE         VARCHAR(100),
            @VCUIT_TMT          VARCHAR(50),
            @VRAZON_SOCIAL_TMT  VARCHAR(300),
            @VCALLE_TMT         VARCHAR(100),
            @VNRO_TMT           VARCHAR(30),
            @VPISO_TMT          VARCHAR(30),
            @VLOCALIDAD_TMT     VARCHAR(100),
            @VPROVINCIA_TMT     VARCHAR(50),
            @VTELEFONO1_TMT     VARCHAR(100),
            @VTELEFONO2_TMT     VARCHAR(100),
            @VEMAIL_TMT         VARCHAR(100),
            @VIVA_TMT           VARCHAR(50),
            @VCONTACTO_TMT      VARCHAR(4000),
            @VTIPO_CLIENTE_TMT  VARCHAR(50),
            @VESTADO_TMT        VARCHAR(50),
            @VOBSERVACIONES_TMT VARCHAR(400);
 
    SELECT  @VCLAVE             = ISNULL(CLAVE,''),
            @VCUIT_TMT          = ISNULL(CUIT,''),
            @VRAZON_SOCIAL_TMT  = ISNULL(RAZON_SOCIAL,''),
            @VCALLE_TMT         = ISNULL(CALLE,''),
            @VNRO_TMT           = ISNULL(NRO,''),
            @VPISO_TMT          = ISNULL(PISO,''),
            @VLOCALIDAD_TMT     = ISNULL(LOCALIDAD,''),
            @VPROVINCIA_TMT     = ISNULL(PROVINCIA,''),
            @VTELEFONO1_TMT     = ISNULL(TELEFONO1,''),
            @VTELEFONO2_TMT     = ISNULL(TELEFONO2,''),
            @VEMAIL_TMT         = ISNULL(EMAIL,''),
            @VIVA_TMT           = ISNULL(IVA,''),
            @VCONTACTO_TMT      = ISNULL(CONTACTO,''),
            @VTIPO_CLIENTE_TMT  = ISNULL(TIPO_CLIENTE,''),
            @VESTADO_TMT        = ISNULL(ESTADO,''),
            @VOBSERVACIONES_TMT = ISNULL(OBSERVACIONES,''),
            @VERROR             = ISNULL(ERROR,'')
    FROM    TMT_SV_02
    WHERE   PAR_KEY = @IPKEYJOB;
 
    IF @VERROR = '' 
    BEGIN 
        UPDATE TMT_SV_02 SET ERROR = NULL WHERE PAR_KEY = @IPKEYJOB;
    END
 
    IF @VCLAVE <> '' AND @VERROR = ''
    BEGIN
        SELECT  @VCUIT          = ISNULL(CUIT_CLIENTE,''),
                @VRAZON_SOCIAL  = ISNULL(RAZON_SOCIAL_CLIENTE,''),
                @VCALLE         = ISNULL(CALLE_CLIENTE,''),
                @VNRO           = ISNULL(NRO_CALLE_CLIENTE,''),
                @VPISO          = ISNULL(PISO_DEPTO_CLIENTE,''),
                @VLOCALIDAD     = ISNULL(LOCALIDAD_CLIENTE,''),
                @VPROVINCIA     = ISNULL(PROVINCIA_CLIENTE,''),
                @VTELEFONO1     = ISNULL(TEL1_CLIENTE,''),
                @VTELEFONO2     = ISNULL(TEL2_CLIENTE,''),
                @VEMAIL         = ISNULL(EMAIL_CLIENTE,''),
                @VIVA           = ISNULL(IVA_CLIENTE,''),
                @VCONTACTO      = ISNULL(CONTACTO_CLIENTE,''),
                @VTIPO_CLIENTE  = ISNULL(TIPO_CLIENTE,''),
                @VESTADO        = ISNULL(STATUS_CLIENTE,''),
                @VOBSERVACIONES = ISNULL(OBSERV_CLIENTE,'')
        FROM    LK_CLIENTES
        WHERE   ID_CLIENTE = @VCLAVE;
 
        SET @VCUIT_TMT          = @VCUIT;
        SET @VRAZON_SOCIAL_TMT  = @VRAZON_SOCIAL;
        SET @VCALLE_TMT         = @VCALLE;
        SET @VNRO_TMT           = @VNRO;
        SET @VPISO_TMT          = @VPISO;
        SET @VLOCALIDAD_TMT     = @VLOCALIDAD;
        SET @VPROVINCIA_TMT     = @VPROVINCIA;
        SET @VTELEFONO1_TMT     = @VTELEFONO1;
        SET @VTELEFONO2_TMT     = @VTELEFONO2;
        SET @VEMAIL_TMT         = @VEMAIL;
        SET @VIVA_TMT           = @VIVA;
        SET @VCONTACTO_TMT      = @VCONTACTO;
        SET @VTIPO_CLIENTE_TMT  = @VTIPO_CLIENTE;
        SET @VESTADO_TMT        = @VESTADO;
        SET @VOBSERVACIONES_TMT = @VOBSERVACIONES;
    END
 
    DECLARE @TITLE VARCHAR(200) = CASE WHEN @VCLAVE = '' THEN 'Agregar Cliente' ELSE 'Modificar Cliente' END;
    DECLARE @FIELDS_HTML VARCHAR(MAX) = '';
    DECLARE @SCRIPTS_HTML VARCHAR(MAX) = '';
    DECLARE @MODAL_HTML VARCHAR(MAX) = '';
 
    SET @FIELDS_HTML = '
    <div class="vct-form-row">
        <div class="vct-form-group" style="grid-column: span 2;">
            <label class="vct-label">Razón Social <span style="color:#ef4444;">*</span></label>
            <input type="text" name="SP.RAZON_SOCIAL" value="' + @VRAZON_SOCIAL_TMT + '" required data-required="true" placeholder="Razón Social">
        </div>
    </div>
 
    <div class="vct-form-row">
        <div class="vct-form-group">
            <label class="vct-label">CUIT <span style="color:#ef4444;">*</span></label>
            <input type="text" name="SP.CUIT" value="' + @VCUIT_TMT + '" required data-required="true" placeholder="30-12345678-9">
        </div>
        <div class="vct-form-group">
            <label class="vct-label">Situación IVA</label>
            <select id="cmb2" name="SP.IVA"></select>
        </div>
    </div>
 
    <div class="vct-form-row">
        <div class="vct-form-group">
            <label class="vct-label">Calle</label>
            <input type="text" name="SP.CALLE" value="' + @VCALLE_TMT + '" placeholder="Nombre de la calle">
        </div>
        <div class="vct-form-group" style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
            <div>
                <label class="vct-label">Nro</label>
                <input type="text" name="SP.NRO" value="' + @VNRO_TMT + '">
            </div>
            <div>
                <label class="vct-label">Piso/Dpto</label>
                <input type="text" name="SP.PISO" value="' + @VPISO_TMT + '">
            </div>
        </div>
    </div>
 
    <div class="vct-form-row">
        <div class="vct-form-group">
            <label class="vct-label">Localidad <span style="color:#ef4444;">*</span></label>
            <input type="text" name="SP.LOCALIDAD" value="' + @VLOCALIDAD_TMT + '" required data-required="true">
        </div>
        <div class="vct-form-group">
            <label class="vct-label">Provincia</label>
            <select id="cmb1" name="SP.PROVINCIA"></select>
        </div>
    </div>
 
    <div class="vct-form-row">
        <div class="vct-form-group">
            <label class="vct-label">Teléfono 1</label>
            <input type="text" name="SP.TELEFONO1" value="' + @VTELEFONO1_TMT + '">
        </div>
        <div class="vct-form-group">
            <label class="vct-label">Teléfono 2</label>
            <input type="text" name="SP.TELEFONO2" value="' + @VTELEFONO2_TMT + '">
        </div>
    </div>
 
    <div class="vct-form-row">
        <div class="vct-form-group">
            <label class="vct-label">Email</label>
            <input type="email" name="SP.EMAIL" value="' + @VEMAIL_TMT + '" placeholder="ejemplo@cliente.com">
        </div>
        <div class="vct-form-group">
            <label class="vct-label">Tipo Cliente <span style="color:#ef4444;">*</span></label>
            <select id="cmb3" name="SP.TIPO_CLIENTE" required data-required="true"></select>
        </div>
    </div>
 
    <div class="vct-form-group">
        <label class="vct-label">Contacto / Observaciones</label>
        <textarea name="SP.CONTACTO" rows="3" style="width:100%; border:1px solid #cbd5e1; border-radius:8px; padding:8px; font-size:13px; outline:none; font-family:inherit;">' + @VCONTACTO_TMT + '</textarea>
    </div>';
 
    SET @SCRIPTS_HTML = '
    <script>
        BuildAjaxSPCombo(''' + @FORM_ID + ''', ''cmb1'', ''0000000124_98'', ''' + ISNULL(@VPROVINCIA_TMT,'') + ''', '''');
        BuildAjaxSPCombo(''' + @FORM_ID + ''', ''cmb2'', ''0000000003_98'', ''' + ISNULL(@VIVA_TMT,'') + ''', '''');
        BuildAjaxSPCombo(''' + @FORM_ID + ''', ''cmb3'', ''763C17B4-31D5-4D09-853B-28F6EC12ED6A'', ''' + ISNULL(@VTIPO_CLIENTE_TMT,'') + ''', '''');
        
        /* EXTRACCIÓN Y BLINDAJE ANTI-LIMPADO MÜHLE */
        (function lockModalInBody() {
            function protect() {
                var modal = document.getElementById("vctModalContainer");
                if (modal && modal.parentNode !== document.body) {
                    document.body.appendChild(modal);
                }
            }
            protect();
            setTimeout(protect, 50);
            setTimeout(protect, 150);
            setTimeout(protect, 300);
            setTimeout(protect, 600);
        })();
    </script>';
 
    EXEC [dbo].[HOME_BUILD_FORM_BODY]
        @I_TITLE        = @TITLE,
        @I_FIELDS_HTML  = @FIELDS_HTML,
        @I_FORM_ID      = @FORM_ID,
        @I_SAVE_LABEL   = 'Grabar',
        @I_LAYOUT_MODE  = 'LARGE',
        @I_SCRIPTS_HTML = @SCRIPTS_HTML,
        @O_HTML_FORM    = @MODAL_HTML OUTPUT;
 
    SET @OHEADER = '';
    SET @OFOOTER = '';
    SET @PS_TITULO = '';
    SET @PS_FORMULARIO = ISNULL(@MODAL_HTML, '');
    SET @PS_FORMU_FOOT = '';
 
END
