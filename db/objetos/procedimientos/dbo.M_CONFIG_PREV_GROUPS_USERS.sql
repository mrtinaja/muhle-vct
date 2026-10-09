 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_GROUPS_USERS]
(
    @IPKEYJOB      VARCHAR(100),
    @IUSERID        VARCHAR(100),
    @FORM_ID        VARCHAR(100),
    @PS_TITULO      VARCHAR(MAX) = NULL OUTPUT,
    @PS_FORMULARIO VARCHAR(MAX) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- 1. Saneo del buffer en M_CONFIG y resguardo de variables cruzadas
    UPDATE dbo.M_CONFIG
    SET ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(ID_GROUP_SEL, ''), ',', ''), '''', ''), '"', ''))),
        ID_TASK_SEL  = NULL
    WHERE PAR_KEY = @IPKEYJOB;
 
    DECLARE
        @V_PERFIL_SEL    VARCHAR(100) = '',
        @V_USER_SEL      VARCHAR(100) = '',
        @V_PERFIL_DESC   VARCHAR(400) = '',
        @VHTML_HEADER    VARCHAR(MAX) = '',
        @VBOTON_VOLVER   VARCHAR(MAX) = '',
        @VFORM_ID_CLEAN  VARCHAR(100) = '',
        @V_HTML_SELECT   VARCHAR(MAX) = '';
 
    SELECT TOP 1
        @V_PERFIL_SEL = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @V_USER_SEL = '';
 
    SELECT TOP 1 @V_PERFIL_DESC = ISNULL(Name, '')
    FROM dbo.Groups WITH (NOLOCK) WHERE Id = @V_PERFIL_SEL;
 
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
 
    -- 2. Query para el combo de Usuarios no asignados
    DECLARE @V_QUERY_USERS NVARCHAR(MAX) = N'
        SELECT
                u.Id AS CAT_DATA_CODE,
                ISNULL(u.Name, u.Id) + '' ('' + u.Id + '')'' AS CAT_DATA_DESC,
                ''TRUE'' AS IS_ACTIVE
        FROM    dbo.Users u WITH (NOLOCK)
        WHERE   u.State = 1
        AND     UPPER(LTRIM(RTRIM(u.Id))) NOT IN (
                  SELECT    UPPER(LTRIM(RTRIM(gum.UserMemberId)))
                  FROM      dbo.GroupsUserMembers gum WITH (NOLOCK)
                  WHERE     UPPER(LTRIM(RTRIM(gum.GroupId))) = UPPER(''' + REPLACE(@V_PERFIL_SEL, '''', '''''') + ''')
                  AND       gum.UserMemberId IS NOT NULL AND gum.UserMemberId <> ''''
          )
        AND     u.id <> ''admin''
        ORDER BY u.Name, u.Id;';
 
    EXEC dbo.VCT_RENDER_SELECT
        @I_SELECT_ID     = 'ID_USER_SEL',
        @I_QUERY         = @V_QUERY_USERS,
        @I_SELECTED_VAL  = '',
        @I_PLACEHOLDER   = 'Seleccione un usuario',
        @I_EXTRA_CLASSES = 'vct-ts-select',
        @O_HTML_SELECT   = @V_HTML_SELECT OUTPUT;
 
    -- 3. Invocación al componente pro reutilizable del Botón Volver
    EXEC dbo.VCT_RENDER_BACK_BUTTON
         @FORM_ID     = @VFORM_ID_CLEAN,
         @TARGET_GUID = '21B6894B-27A5-4A5F-9CA9-BFD807276E9C',
         @TITLE       = 'Volver a Perfiles',
         @HTML        = @VBOTON_VOLVER OUTPUT;
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Usuarios Asociados',
         @SUBTITLE            = 'Administre la asignación de usuarios al perfil seleccionado',
         @MODULE_ICON         = 'users',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Usuarios del Perfil',
         @DEFAULT_TAB_ICON    = 'users',
         @DYNAMIC_TAB_ID      = 'form',
         @DYNAMIC_TAB_TITLE   = 'Asociar usuario',
         @DYNAMIC_TAB_ICON    = 'user-plus',
         @SHOW_ACTION_BUTTON  = 0,
         @ACTION_BUTTON_TEXT  = '',
         @ACTION_BUTTON_ICON  = '',
         @ACTION_TARGET_TAB   = '',
         @ACTION_MODE         = '',
         @ACTION_ONCLICK      = '',
         @HTML                = @VHTML_HEADER OUTPUT;
 
    -- Inyección del Botón Volver Reutilizable
    SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-module-header"', 'class="vct-module-header" style="position:relative;"');
    IF CHARINDEX('</div>', @VHTML_HEADER) > 0
    BEGIN
        SET @VHTML_HEADER = STUFF(@VHTML_HEADER, CHARINDEX('</div>', @VHTML_HEADER), 0, @VBOTON_VOLVER);
    END
 
    -- 4. Tarjeta del Header
    DECLARE @VTARJETA_PERFIL_HEADER VARCHAR(MAX) =
    '<div class="vct-card-perfil-header" style="background:#fff; border:none; border-radius:0; padding:16px 20px; margin:12px 0 0 0; box-shadow:none;">' +
        '<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; border-left:4px solid #66062D; padding-left:16px;">' +
            '<div>' +
                '<div style="display:flex; align-items:center; gap:8px;">' +
                    '<h3 style="margin:0; font-size:15px; font-weight:700; color:#0f172a;">' +
                        'Perfil:' +
                    '</h3>' +
                    '<span style="display:inline-flex; align-items:center; gap:6px; padding:5px 12px; background:rgba(102,6,45,0.10); color:#66062D; border-radius:20px; font-size:14px; font-weight:700;">' +
                        '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">' +
                            '<circle cx="12" cy="7" r="3"/>' +
                            '<path d="M6 21v-2a6 6 0 0 1 12 0v2"/>' +
                            '<path d="M6 8a3 3 0 1 0 0 6"/>' +
                            '<path d="M18 8a3 3 0 1 1 0 6"/>' +
                        '</svg>' +
                        ISNULL(@V_PERFIL_DESC, @V_PERFIL_SEL) +
                    '</span>' +
                '</div>' +
 
                '<p style="margin:5px 0 0 0; font-size:12px; color:#64748b;">' +
                    'Seleccione un Usuario para asociarlo al perfil.' +
                '</p>' +
            '</div>' +
            '<div style="display:flex; align-items:center; gap:10px;">' +
                '<div style="min-width:300px;">' +
                    @V_HTML_SELECT +
                '</div>' +
                '<a href="javascript:void(0);" onclick="ejecutarAltaUsuario(); return false;" ' +
                   'style="height:40px; padding:0 18px; display:inline-flex; align-items:center; gap:6px; font-weight:600; background-color:#66062D; color:#ffffff; border-radius:8px; text-decoration:none; cursor:pointer; font-size:13px; border:none; box-sizing:border-box;">' +
 
                    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">' +
                        '<line x1="12" y1="5" x2="12" y2="19"/>' +
                        '<line x1="5" y1="12" x2="19" y2="12"/>' +
                    '</svg>' +
                    '<span>Agregar</span>' +
                '</a>' +
            '</div>' +
        '</div>' +
        '<div style="margin-top:14px; padding:10px 14px; background:#fff8f1; border-left:4px solid #d97706; border-radius:4px; font-size:12px; color:#92400e; display:flex; align-items:center; gap:8px;">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>' +
            '<span><b>Nota de Asignación:</b> Un Usuario solo puede tener un Perfil activo. Al asignarse a este Perfil, se desvinculará automáticamente del Perfil anterior.</span>' +
        '</div>' +
    '</div>';
 
    -- 5. Configuración de Acciones
    DECLARE @ActionsJsonModule VARCHAR(MAX) =
    '[
        {
            "type": "custom",
            "title": "Eliminar",
            "icon": "trash-2",
            "isSecondary": true,
            "variant": "danger",
            "keyField": "Usuario",
            "targetGuid": "97D60A26-8606-4D28-8BBE-6E290E407C9E",
            "storageKey": "ID_DELETE",
            "actionParam": "DELETE_USER"
        }
    ]';
 
    DECLARE @AttrActionsModule VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ActionsJsonModule, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    -- 6. Inyección CSS limpia e inclusión de estilos del botón volver pro
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.bootstrap5.min.css" />' +
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
 
        '<style>' +
            /* SELECT - tamaño/color estándar definidos en vct-Core.js; acá solo el ancho del wrapper.
               :not(.vct-page-size-ts) evita pisar el selector de paginado, que también
               lleva la clase vct-ts-select y debe mantener su ancho angosto. */
            '.ts-wrapper.vct-ts-select:not(.vct-page-size-ts) { width: 100% !important; }' +
 
            '.vct-circular-back-btn {' +
                'position: absolute !important;' +
                'top: 50% !important;' +
                'transform: translateY(-50%) !important;' +
                'right: 20px !important;' +
                'width: 34px !important;' +
                'height: 34px !important;' +
                'border-radius: 50% !important;' +
                'background: #66062D !important;' +
                'border: 1px solid rgba(255, 255, 255, 0.2) !important;' +
                'color: #ffffff !important;' +
                'display: inline-flex !important;' +
                'align-items: center !important;' +
                'justify-content: center !important;' +
                'cursor: pointer !important;' +
                'box-shadow: 0 2px 6px rgba(102, 6, 45, 0.3) !important;' +
                'transition: all 0.2s ease-in-out !important;' +
                'z-index: 100 !important;' +
            '}' +
 
            '.vct-circular-back-btn:hover {' +
                'background: #4a0420 !important;' +
                'transform: translateY(-50%) scale(1.08) !important;' +
                'box-shadow: 0 4px 10px rgba(102, 6, 45, 0.4) !important;' +
            '}' +
 
            '/* PADDING EN EL FOOTER DE PAGINACIÓN DE LA GRILLA DE USUARIOS */' +
            'div.vct-grid-host div[style*="display:flex"][style*="justify-content:space-between"] {' +
                'padding: 15px 20px !important;' +
                'margin-top: 10px !important;' +
                'box-sizing: border-box !important;' +
            '}' +
 
            '.vct-tabs-bar, .vct-tabs-bar:empty, .vct-panels:empty, .vct-panel:not(.is-active) { display: none !important; }' +
            '.vct-module-content, .vct-grid-host, div[id*="step_"] { margin-top: 0 !important; padding-top: 0 !important; }' +
            '.vct-card-perfil-header, .vct-table-wrapper { padding-left: 20px !important; padding-right: 20px !important; box-sizing: border-box !important; }' +
            '.vct-card-perfil-header { margin-top: 12px !important; margin-bottom: 0 !important; }' +
            '.vct-table-toolbar { padding-top: 15px !important; margin-bottom: 14px !important; }' +
            'tbody tr td:has(link), tbody tr:has(link) { display: none !important; }' +
 
            '.vct-status-badge{display:inline-flex!important;align-items:center!important;gap:6px!important;padding:4px 8px!important;border-radius:999px!important;font-size:10.5px!important;font-weight:700!important;line-height:1!important;white-space:nowrap!important;}' +
            '.vct-status-badge .vct-status-dot{width:6px!important;height:6px!important;border-radius:50%!important;flex-shrink:0!important;background:currentColor!important;}' +
            '.vct-status-active{background:#ECFDF3!important;color:#166534!important;border:1px solid #BBF7D0!important;}' +
            '.vct-status-inactive{background:#F8FAFC!important;color:#64748b!important;border:1px solid #E2E8F0!important;}' +
        '</style>' +
 
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="grid"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"' +
        ' data-vct-primary-field="Usuario"' +
        ' data-vct-actions="' + @AttrActionsModule + '">' +
        @VHTML_HEADER +
        @VTARJETA_PERFIL_HEADER
    AS VARCHAR(MAX));
 
    -- 7. Formulario y JS
    SET @PS_FORMULARIO = CAST(
        '<input type="hidden" name="SP.ID_GROUP_SEL" value="' + ISNULL(@V_PERFIL_SEL, '') + '" />' +
        '<input type="hidden" name="SP.ID_USER_SEL" id="ID_USER_SEL_HIDDEN" value="" />' +
 
        '<div class="vct-grid-host" data-vct-grid-host style="margin:0 !important; padding:0 !important;"></div>' +
 
        '<script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>' +
        '<script src="../js/vct-Core.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Tabs.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Table.js?v=20260916-3"></script>' +
        '<script src="../js/vct-modal.js?v=20260916-3"></script>' +
 
        '<script>' +
            'function initVctTomSelect() {' +
                'var selectEl = document.getElementById("ID_USER_SEL");' +
                'if (selectEl && !selectEl.tomselect && window.TomSelect) {' +
                    'new TomSelect(selectEl, {' +
                        'create: false,' +
                        'wrapperClass: "ts-wrapper vct-ts-select",' +
                        'placeholder: "Seleccione un usuario",' +
                        'allowEmptyOption: true,' +
                        'controlInput: null' +
                    '});' +
                '}' +
            '};' +
            'initVctTomSelect();' +
            'setTimeout(initVctTomSelect, 150);' +
 
            'function ejecutarAltaUsuario() {' +
                'var selectEl = document.getElementById("ID_USER_SEL");' +
                'var valSelected = "";' +
                'if (selectEl) {' +
                    'if (selectEl.tomselect) { valSelected = selectEl.tomselect.getValue(); }' +
                    'else { valSelected = selectEl.value; }' +
                '}' +
                'if (!valSelected || valSelected.trim() === "") {' +
                    'if (window.VCTModal) { VCTModal.alert({ title: "Atención", text: "Debe seleccionar un usuario para asociar." }); }' +
                    'else { alert("Debe seleccionar un Usuario"); }' +
                    'return false;' +
                '}' +
                'var cleanVal = valSelected.trim();' +
                'var hInput = document.getElementById("ID_USER_SEL_HIDDEN");' +
                'if (hInput) { hInput.value = cleanVal; }' +
                'var formEl = document.forms[0] || document.getElementById("form1");' +
                'if (formEl) {' +
                    '["ID_USER_SEL", "SP.ID_USER_SEL"].forEach(function(n) {' +
                        'var el = document.getElementsByName(n)[0];' +
                        'if (!el) { el = document.createElement("input"); el.type = "hidden"; el.name = n; formEl.appendChild(el); }' +
                        'el.value = cleanVal;' +
                    '});' +
                '}' +
                'if (typeof window.almacenarSeleccion === "function") {' +
                    'try { window.almacenarSeleccion("ID_USER_SEL", cleanVal); } catch(e){}' +
                '}' +
                'setTimeout(function() {' +
                    'goto(''' + @VFORM_ID_CLEAN + ''', ''2C416013-11F9-4385-AB33-060532E0C152'');' +
                '}, 200);' +
                'return false;' +
                '};' +
        '</script>'
    AS VARCHAR(MAX));
 
END
