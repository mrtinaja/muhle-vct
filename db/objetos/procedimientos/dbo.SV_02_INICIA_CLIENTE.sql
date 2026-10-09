 
CREATE PROCEDURE [dbo].[SV_02_INICIA_CLIENTE]
(
    @IPKEYJOB VARCHAR(100),
    @IUNIDAD  VARCHAR(100),
    @IAGENTE  VARCHAR(100),
    @IJOBSEQ  INT,
    @FORM_ID  VARCHAR(100),
    @OHEADER  VARCHAR(MAX) OUTPUT,
    @OFOOTER  VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @HTML_SIDEBAR    VARCHAR(MAX) = '';
    DECLARE @HTML_HEADER     VARCHAR(MAX) = '';
    DECLARE @ACTION_ONCLICK  VARCHAR(MAX) = '';
    DECLARE @RESOURCE_NAME   VARCHAR(100) = 'Clientes';
    DECLARE @VFORM_ID_CLEAN  VARCHAR(100) = REPLACE(ISNULL(@FORM_ID, ''), '''', '''''');
 
    DECLARE @CAN_VIEW   BIT = 0;
    DECLARE @CAN_CREATE BIT = 0;
 
    SET @CAN_VIEW   = dbo.VCT_USER_CAN_SEE_SIDEBAR(@IAGENTE, @RESOURCE_NAME);
    SET @CAN_CREATE = dbo.VCT_USER_HAS_ACTION(@IAGENTE, @RESOURCE_NAME, 'CREATE');
 
    EXEC dbo.HOME_GET_SIDEBAR
         @IUNIDAD  = @IUNIDAD,
         @IAGENTE  = @IAGENTE,
         @FORM_ID  = @FORM_ID,
         @OSIDEBAR = @HTML_SIDEBAR OUTPUT;
 
    IF ISNULL(@CAN_VIEW, 0) = 0
    BEGIN
        SET @OHEADER = ISNULL(@HTML_SIDEBAR, '') + '
<section class="vct-module">
    <header class="vct-module-header">
        <div class="vct-module-heading">
            <div class="vct-module-icon"><i data-lucide="lock"></i></div>
            <div class="vct-module-heading-text">
                <h2 class="vct-module-title">Acceso restringido</h2>
                <p class="vct-module-subtitle">No posee permisos para acceder a Clientes.</p>
            </div>
        </div>
    </header>
</section>
<script type="text/javascript">
    if (window.lucide && typeof window.lucide.createIcons === "function") window.lucide.createIcons();
</script>';
 
        SET @OFOOTER = '';
        RETURN;
    END;
 
    DECLARE @OPT_PROVINCIA VARCHAR(MAX) = '<option value="">Seleccione...</option>';
    DECLARE @OPT_IVA       VARCHAR(MAX) = '<option value="">Seleccione...</option>';
    DECLARE @OPT_TIPO      VARCHAR(MAX) = '<option value="">Seleccione...</option>';
 
    SELECT @OPT_PROVINCIA = @OPT_PROVINCIA +
        '<option value="' + ISNULL(CD.CAT_DATA_CODE, '') + '">' + ISNULL(CD.CAT_DATA_DESC, '') + '</option>'
    FROM dbo.CAT_DATA CD WITH (NOLOCK)
        INNER JOIN dbo.CAT_TYPE CT WITH (NOLOCK)
            ON CT.PKEY = CD.PAR_KEY
    WHERE CT.CAT_TYPE_CODE = 'PROVINCIA'
    ORDER BY CD.CAT_DATA_DESC;
 
    SELECT @OPT_IVA = @OPT_IVA +
        '<option value="' + ISNULL(CD.CAT_DATA_CODE, '') + '">' + ISNULL(CD.CAT_DATA_DESC, '') + '</option>'
    FROM dbo.CAT_DATA CD WITH (NOLOCK)
        INNER JOIN dbo.CAT_TYPE CT WITH (NOLOCK)
            ON CT.PKEY = CD.PAR_KEY
    WHERE CT.CAT_TYPE_CODE = 'IVA'
    ORDER BY CD.CAT_DATA_DESC;
 
    SET @OPT_TIPO = '
        <option value="">Seleccione...</option>
        <option value="ACTIVO">Activo</option>
        <option value="PASIVO">Pasivo</option>
        <option value="DESAFECTADO">Desafectado</option>';
 
    SET @ACTION_ONCLICK =
        'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''CLAVE'','''');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE              = 'Clientes',
         @SUBTITLE           = 'Administre la cartera de clientes',
         @MODULE_ICON        = 'users',
         @DEFAULT_TAB_ID     = 'grid',
         @DEFAULT_TAB_TITLE  = 'Clientes',
         @DEFAULT_TAB_ICON   = 'users',
         @DYNAMIC_TAB_ID     = 'form',
         @DYNAMIC_TAB_TITLE  = 'Cliente',
         @DYNAMIC_TAB_ICON   = 'user-plus',
         @SHOW_DYNAMIC_TAB   = 1,
         @SHOW_ACTION_BUTTON = @CAN_CREATE,
         @ACTION_BUTTON_TEXT = 'Nuevo',
         @ACTION_BUTTON_ICON = 'plus',
         @ACTION_TARGET_TAB  = 'form',
         @ACTION_MODE        = 'new',
         @ACTION_ONCLICK     = @ACTION_ONCLICK,
         @HTML               = @HTML_HEADER OUTPUT;
 
    SET @OHEADER = ISNULL(@HTML_SIDEBAR, '') + '
<link rel="stylesheet" href="../css/vct-Tabs.css" />
<link rel="stylesheet" href="../css/vct-modal.css" />
 
<style>
    .vct-client-form {
        width: 100%;
        max-width: 760px;
        margin: 28px auto;
    }
 
    .vct-client-form .vct-form-header {
        padding: 22px 26px 18px 26px;
    }
 
    .vct-client-form .vct-form-title {
        font-weight: 500 !important;
        letter-spacing: 0 !important;
    }
 
    .vct-client-form .vct-form-body {
        padding: 24px 26px 26px 26px;
    }
 
    .vct-client-layout {
        display: grid;
        grid-template-columns: 1fr;
        gap: 0 !important;
    }
 
    .vct-client-form .vct-form-group {
        margin-bottom: 16px !important;
    }
 
    .vct-client-form .vct-form-group label {
        display: flex !important;
        align-items: center !important;
        gap: 8px !important;
        margin-bottom: 8px !important;
        color: #0f172a !important;
        font-size: 13px !important;
        font-weight: 600 !important;
        line-height: 1.2 !important;
    }
 
    .vct-client-form .vct-form-group label svg,
    .vct-client-form .vct-form-group label i {
        width: 16px !important;
        height: 16px !important;
        color: #97003f !important;
        stroke: #97003f !important;
        flex: 0 0 auto !important;
    }
 
    .vct-client-form .vct-required {
        display: inline-flex !important;
        align-items: center !important;
        color: #97003f !important;
        margin-left: 4px !important;
    }
 
    .vct-client-form .vct-required svg {
        width: 12px !important;
        height: 12px !important;
    }
 
    .vct-client-form .vct-input,
    .vct-client-form select.vct-input,
    .vct-client-form textarea.vct-input {
        width: 100% !important;
        min-height: 42px !important;
        border: 1px solid #cbd5e1 !important;
        border-radius: 8px !important;
        padding: 0 14px !important;
        font-size: 14px !important;
        line-height: 1.4 !important;
        box-sizing: border-box !important;
    }
 
    .vct-client-form textarea.vct-input {
        min-height: 110px !important;
        padding-top: 12px !important;
        resize: vertical !important;
    }
 
    .vct-client-form .vct-input-error {
        border-color: #97003f !important;
        box-shadow: 0 0 0 3px rgba(151, 0, 63, 0.12) !important;
    }
 
    .vct-client-form .vct-form-actions {
        border-top: 1px solid #e2e8f0;
        margin-top: 22px;
        padding-top: 20px;
    }
 
    .vct-client-validation-backdrop {
        position: fixed;
        inset: 0;
        z-index: 99999;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(15, 23, 42, 0.42);
        padding: 24px;
    }
 
    .vct-client-validation-modal {
        width: min(460px, 100%);
        background: #ffffff;
        border: 1px solid #dbe3ef;
        border-radius: 12px;
        box-shadow: 0 24px 70px rgba(15, 23, 42, 0.25);
        overflow: hidden;
    }
 
    .vct-client-validation-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 18px 20px;
        background: #f8fafc;
        border-bottom: 1px solid #e2e8f0;
    }
 
    .vct-client-validation-icon {
        width: 34px;
        height: 34px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border-radius: 10px;
        background: #97003f;
        color: #ffffff;
        font-weight: 700;
    }
 
    .vct-client-validation-title {
        margin: 0;
        color: #0f172a;
        font-size: 18px;
        font-weight: 600;
    }
 
    .vct-client-validation-body {
        padding: 18px 20px;
        color: #334155;
        font-size: 14px;
    }
 
    .vct-client-validation-body ul {
        margin: 12px 0 0 18px;
        padding: 0;
    }
 
    .vct-client-validation-body li {
        margin-bottom: 6px;
    }
 
    .vct-client-validation-actions {
        display: flex;
        justify-content: flex-end;
        padding: 14px 20px 18px 20px;
        border-top: 1px solid #e2e8f0;
    }
 
    .vct-client-validation-close {
        border: 0;
        border-radius: 8px;
        background: #97003f;
        color: #ffffff;
        padding: 10px 18px;
        font-weight: 600;
        cursor: pointer;
    }
</style>
 
<section class="vct-module"
    data-vct-module
    data-vct-tabs
    data-vct-default-tab="grid"
    data-vct-active-tab="grid"
    data-vct-grid-selector="[data-vct-grid-source]"
    data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"
    data-vct-primary-field="Clave"
    data-vct-edit-mode="client"
    data-vct-edit-storage-key="CLAVE"
    data-vct-edit-tab="form"
    data-vct-initial-mode="new"
    data-vct-mode-new="{&quot;tabTitle&quot;:&quot;Nuevo cliente&quot;,&quot;tabIcon&quot;:&quot;user-plus&quot;,&quot;title&quot;:&quot;Agregar cliente&quot;,&quot;subtitle&quot;:&quot;Complete los datos del cliente.&quot;,&quot;icon&quot;:&quot;user-plus&quot;,&quot;submit&quot;:&quot;Crear cliente&quot;}"
    data-vct-mode-edit="{&quot;tabTitle&quot;:&quot;Editar cliente&quot;,&quot;tabIcon&quot;:&quot;pencil&quot;,&quot;title&quot;:&quot;Editar cliente&quot;,&quot;subtitle&quot;:&quot;Modifique los datos del cliente seleccionado.&quot;,&quot;icon&quot;:&quot;pencil&quot;,&quot;submit&quot;:&quot;Guardar cambios&quot;}">
' + ISNULL(@HTML_HEADER, '') + '
 
<div class="vct-panels">
    <div class="vct-panel is-active" data-vct-panel="grid" aria-hidden="false">
';
 
    SET @OFOOTER = '
    </div>
 
    <div class="vct-panel" data-vct-panel="form" hidden aria-hidden="true">
        <div class="vct-form-card vct-client-form">
            <div class="vct-form-header">
                <div class="vct-form-icon" data-vct-form-icon>
                    <i data-lucide="user-plus"></i>
                </div>
                <div>
                    <h3 class="vct-form-title" data-vct-form-title>Agregar cliente</h3>
                    <p class="vct-form-subtitle" data-vct-form-subtitle>Complete los datos del cliente.</p>
                </div>
            </div>
 
            <div class="vct-form-body">
                <input type="hidden" id="CLAVE" name="SP.CLAVE" value="" data-vct-field="Clave" data-vct-selected-key />
 
                <div class="vct-client-layout">
                    <div class="vct-form-group">
                        <label><i data-lucide="type"></i><span>Razon Social</span><span class="vct-required"><i data-lucide="asterisk"></i></span></label>
                        <input class="vct-input" type="text" name="SP.RAZON_SOCIAL" data-vct-field="Cliente" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="id-card"></i><span>Cuit</span><span class="vct-required"><i data-lucide="asterisk"></i></span></label>
                        <input class="vct-input" type="text" name="SP.CUIT" data-vct-field="CUIT" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="home"></i><span>Calle</span></label>
                        <input class="vct-input" type="text" name="SP.CALLE" data-vct-field="Calle" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="map-pin"></i><span>Nro</span></label>
                        <input class="vct-input" type="text" name="SP.NRO" data-vct-field="Nro" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="building"></i><span>Piso</span></label>
                        <input class="vct-input" type="text" name="SP.PISO" data-vct-field="Piso" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="map"></i><span>Localidad</span><span class="vct-required"><i data-lucide="asterisk"></i></span></label>
                        <input class="vct-input" type="text" name="SP.LOCALIDAD" data-vct-field="Localidad" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="map-pinned"></i><span>Provincia</span></label>
                        <select class="vct-input" name="SP.PROVINCIA" data-vct-field="ProvinciaCodigo">
                            ' + @OPT_PROVINCIA + '
                        </select>
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="phone"></i><span>Telefono 1</span></label>
                        <input class="vct-input" type="text" name="SP.TELEFONO1" data-vct-field="Telefono" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="smartphone"></i><span>Telefono 2</span></label>
                        <input class="vct-input" type="text" name="SP.TELEFONO2" data-vct-field="Celular" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="mail"></i><span>Email</span></label>
                        <input class="vct-input" type="text" name="SP.EMAIL" data-vct-field="Email" autocomplete="off" />
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="receipt"></i><span>Situacion Iva</span></label>
                        <select class="vct-input" name="SP.IVA" data-vct-field="IvaCodigo">
                            ' + @OPT_IVA + '
                        </select>
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="grid-2x2"></i><span>Tipo Cliente</span><span class="vct-required"><i data-lucide="asterisk"></i></span></label>
                        <select class="vct-input" name="SP.TIPO_CLIENTE" data-vct-field="TipoCodigo">
                            ' + @OPT_TIPO + '
                        </select>
                    </div>
 
                    <div class="vct-form-group">
                        <label><i data-lucide="user"></i><span>Contacto</span></label>
                        <textarea class="vct-input" name="SP.CONTACTO" data-vct-field="Contacto" rows="5"></textarea>
                    </div>
                </div>
 
                <div class="vct-form-actions">
                    <button type="button" class="vct-button vct-button-secondary" data-vct-close-tab="form" data-vct-fallback-tab="grid" data-vct-reset-on-close>
                        <i data-lucide="x"></i>
                        <span>Cancelar</span>
                    </button>
 
                    <button type="button" id="vctClienteSaveBtn" class="vct-button vct-button-primary" onclick="return vctClientesValidarYGuardar(''' + @VFORM_ID_CLEAN + ''');">
                        <i data-lucide="save"></i>
                        <span class="vct-button-text">Guardar</span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
 
</section>
 
<script src="../js/vct-Core.js"></script>
<script src="../js/vct-Tabs.js"></script>
<script src="../js/vct-Table.js"></script>
<script src="../js/vct-modal.js"></script>
 
<script type="text/javascript">
(function () {
    function vctClienteField(name) {
        return document.querySelector("[name=''SP." + name + "'']");
    }
 
    function vctClienteValue(name) {
        var el = vctClienteField(name);
        return el ? String(el.value || "").replace(/^\s+|\s+$/g, "") : "";
    }
 
    function vctClienteShowModal(messages) {
        var old = document.getElementById("vctClienteValidationModal");
        if (old && old.parentNode) old.parentNode.removeChild(old);
 
        var backdrop = document.createElement("div");
        backdrop.id = "vctClienteValidationModal";
        backdrop.className = "vct-client-validation-backdrop";
 
        var items = "";
        for (var i = 0; i < messages.length; i++) {
            items += "<li>" + messages[i] + "</li>";
        }
 
        backdrop.innerHTML =
            "<div class=\"vct-client-validation-modal\" role=\"dialog\" aria-modal=\"true\">" +
                "<div class=\"vct-client-validation-header\">" +
                    "<div class=\"vct-client-validation-icon\">!</div>" +
                    "<div><h3 class=\"vct-client-validation-title\">Revisar datos</h3></div>" +
                "</div>" +
                "<div class=\"vct-client-validation-body\">" +
                    "<div>Antes de guardar, corregi los siguientes campos:</div>" +
                    "<ul>" + items + "</ul>" +
                "</div>" +
                "<div class=\"vct-client-validation-actions\">" +
                    "<button type=\"button\" class=\"vct-client-validation-close\">Entendido</button>" +
                "</div>" +
            "</div>";
 
        document.body.appendChild(backdrop);
 
        var closeBtn = backdrop.querySelector(".vct-client-validation-close");
        if (closeBtn) {
            closeBtn.onclick = function () {
                if (backdrop && backdrop.parentNode) backdrop.parentNode.removeChild(backdrop);
            };
        }
 
        backdrop.onclick = function (ev) {
            if (ev.target === backdrop && backdrop.parentNode) {
                backdrop.parentNode.removeChild(backdrop);
            }
        };
    }
 
    function markError(name, hasError) {
        var el = vctClienteField(name);
        if (!el) return;
        if (hasError) el.classList.add("vct-input-error");
        else el.classList.remove("vct-input-error");
    }
 
    window.vctClientesValidarYGuardar = function (formId) {
        var errors = [];
 
        var razon = vctClienteValue("RAZON_SOCIAL");
        var cuit = vctClienteValue("CUIT");
        var localidad = vctClienteValue("LOCALIDAD");
        var tipo = vctClienteValue("TIPO_CLIENTE");
        var email = vctClienteValue("EMAIL");
 
        markError("RAZON_SOCIAL", !razon);
        markError("CUIT", !cuit);
        markError("LOCALIDAD", !localidad);
        markError("TIPO_CLIENTE", !tipo);
 
        if (!razon) errors.push("Razon Social es obligatoria.");
        if (!cuit) errors.push("Cuit es obligatorio.");
        if (!localidad) errors.push("Localidad es obligatoria.");
        if (!tipo) errors.push("Tipo Cliente es obligatorio.");
 
        if (cuit && !/^[0-9]{2}-?[0-9]{8}-?[0-9]$/.test(cuit)) {
            errors.push("El Cuit debe tener un formato valido. Ejemplo: 30-12345678-9.");
            markError("CUIT", true);
        }
 
        if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            errors.push("El Email no tiene un formato valido.");
            markError("EMAIL", true);
        } else {
            markError("EMAIL", false);
        }
 
        if (errors.length > 0) {
            vctClienteShowModal(errors);
            return false;
        }
 
        if (typeof window.next === "function") {
            window.next(formId);
            return false;
        }
 
        if (typeof window.vctConfirmarGuardar === "function") {
            window.vctConfirmarGuardar(formId, 2);
            return false;
        }
 
        if (typeof window.confirmarGuardar === "function") {
            window.confirmarGuardar(formId, 2);
            return false;
        }
 
        vctClienteShowModal(["No se encontro la funcion de guardado del formulario."]);
        return false;
    };
 
    function initClientes() {
        if (window.VctTabs && typeof window.VctTabs.init === "function") window.VctTabs.init();
        if (window.VctTable && typeof window.VctTable.init === "function") window.VctTable.init();
        if (window.lucide && typeof window.lucide.createIcons === "function") window.lucide.createIcons();
    }
 
    initClientes();
})();
</script>';
 
    UPDATE dbo.TMT_SV_02
       SET CUIT          = NULL,
           RAZON_SOCIAL  = NULL,
           CALLE         = NULL,
           NRO           = NULL,
           PISO          = NULL,
           LOCALIDAD     = NULL,
           PROVINCIA     = NULL,
           TELEFONO1     = NULL,
           TELEFONO2     = NULL,
           EMAIL         = NULL,
           IVA           = NULL,
           CONTACTO      = NULL,
           TIPO_CLIENTE  = NULL,
           ESTADO        = NULL,
           OBSERVACIONES = NULL,
           ERROR         = NULL,
           CLAVE         = NULL
     WHERE PAR_KEY = @IPKEYJOB;
END
