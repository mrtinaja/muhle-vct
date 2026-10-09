 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_GROUPS_MODULOS]
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
 
    -- 1. Saneo preventivo del buffer de sesión M_CONFIG
    UPDATE dbo.M_CONFIG
    SET ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(ID_GROUP_SEL, ''), ',', ''), '''', ''), '"', ''))),
        ID_USER_SEL  = NULL
    WHERE PAR_KEY = @IPKEYJOB;
 
    DECLARE
        @V_PERFIL_SEL   VARCHAR(100) = '',
        @V_MODULO_SEL   VARCHAR(100) = '',
        @V_PERFIL_DESC  VARCHAR(400) = '',
        @VHTML_HEADER   VARCHAR(MAX) = '',
        @VFORM_ID_CLEAN VARCHAR(100) = '',
        @V_HTML_SELECT  VARCHAR(MAX) = '',
        @V_QUERY_TASKS  NVARCHAR(MAX) = '';
 
    -- 2. Leer perfil activo
    SELECT
        @V_PERFIL_SEL = ISNULL(ID_GROUP_SEL, ''),
        @V_MODULO_SEL = ISNULL(ID_TASK_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SELECT TOP 1 @V_PERFIL_DESC = ISNULL(Name, '')
    FROM dbo.Groups WITH (NOLOCK) WHERE Id = @V_PERFIL_SEL;
 
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
 
    -- 3. Combo Nativo de Menúes no asociados (Mismo estándar estándar de Mühle)
    SET @V_QUERY_TASKS = N'
        SELECT
            CONVERT(VARCHAR(50), sb.Id) AS CAT_DATA_CODE,
            ISNULL(sb.Name, CONVERT(VARCHAR(50), sb.Id)) AS CAT_DATA_DESC,
            ''TRUE'' AS IS_ACTIVE
        FROM dbo.SideBar sb WITH (NOLOCK)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.SideBarGroups sbg WITH (NOLOCK)
            WHERE LTRIM(RTRIM(sbg.GroupId)) = ''' + REPLACE(@V_PERFIL_SEL, '''', '''''') + '''
              AND CONVERT(VARCHAR(50), sbg.SideBarId) = CONVERT(VARCHAR(50), sb.Id)
        )
        ORDER BY sb.Name;';
 
    EXEC dbo.VCT_RENDER_SELECT
        @I_SELECT_ID     = 'ID_TASK_SEL',
        @I_QUERY         = @V_QUERY_TASKS,
        @I_SELECTED_VAL  = '',
        @I_PLACEHOLDER   = 'Seleccione un menú',
        @I_EXTRA_CLASSES = 'vct-ts-select',
        @O_HTML_SELECT   = @V_HTML_SELECT OUTPUT;
 
    -- 4. Botón circular para volver
    DECLARE @VONCLICK_VOLVER VARCHAR(MAX) = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_TASK_SEL'','''');almacenarSeleccion(''NEW_ID'','''');almacenarSeleccion(''ID_DELETE'','''');} goto(''' + @VFORM_ID_CLEAN + ''', ''21B6894B-27A5-4A5F-9CA9-BFD807276E9C''); return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Menúes Asociados',
         @SUBTITLE            = 'Administre los menúes asignados al Perfil seleccionado',
         @MODULE_ICON         = 'boxes',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Menúes del Perfil',
         @DEFAULT_TAB_ICON    = 'boxes',
         @DYNAMIC_TAB_ID      = 'form',
         @DYNAMIC_TAB_TITLE   = 'Asociar menú',
         @DYNAMIC_TAB_ICON    = 'plus-circle',
         @SHOW_ACTION_BUTTON  = 0,
         @ACTION_BUTTON_TEXT  = '',
         @ACTION_BUTTON_ICON  = '',
         @ACTION_TARGET_TAB   = '',
         @ACTION_MODE         = '',
         @ACTION_ONCLICK      = '',
         @HTML                = @VHTML_HEADER OUTPUT;
 
    DECLARE @VBOTON_CIRCULAR VARCHAR(MAX) =
        '<button type="button" class="vct-circular-back-btn" onclick="' + @VONCLICK_VOLVER + '" title="Volver a Perfiles">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>' +
        '</button>';
 
    SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-module-header"', 'class="vct-module-header" style="position:relative;"');
    IF CHARINDEX('</div>', @VHTML_HEADER) > 0
    BEGIN
        SET @VHTML_HEADER = STUFF(@VHTML_HEADER, CHARINDEX('</div>', @VHTML_HEADER), 0, @VBOTON_CIRCULAR);
    END
 
    -- 5. Tarjeta del Header
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
                    'Seleccione un menú para asociarlo a este perfil.' +
                '</p>' +
            '</div>' +
            '<div style="display:flex; align-items:center; gap:10px;">' +
                '<div style="min-width:300px;">' +
                    @V_HTML_SELECT +
                '</div>' +
                '<a href="javascript:void(0);" onclick="ejecutarAltaMenu(); return false;" ' +
                   'style="height:40px; padding:0 18px; display:inline-flex; align-items:center; gap:6px; font-weight:600; background-color:#66062D; color:#ffffff; border-radius:8px; text-decoration:none; cursor:pointer; font-size:13px; border:none; box-sizing:border-box;">' +
 
                    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">' +
                        '<line x1="12" y1="5" x2="12" y2="19"/>' +
                        '<line x1="5" y1="12" x2="19" y2="12"/>' +
                    '</svg>' +
                    '<span>Agregar</span>' +
                '</a>' +
            '</div>' +
        '</div>' +
    '</div>';
 
    -- 6. Configuración JSON
    DECLARE @ActionsJsonModule VARCHAR(MAX) =
    '[
        {
            "type": "custom",
            "title": "Eliminar",
            "icon": "trash-2",
            "isSecondary": true,
            "variant": "danger",
            "keyField": "PKey",
            "targetGuid": "E47723C4-7340-4168-AE4D-FDE4A65E7271",
            "storageKey": "ID_DELETE",
            "actionParam": "DELETE_TASK"
        }
    ]';
 
    DECLARE @AttrActionsModule VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ActionsJsonModule, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    -- 7. Inyección CSS simplificada sin librerías externas de select
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.bootstrap5.min.css" />' +
        '<link rel="stylesheet" type="text/css" href="../css/vct-Table.css?v=17.0.0" />' +
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
 
        '<style>' +
            '.ts-wrapper.vct-ts-select .ts-control::after { content: none !important; display: none !important; }' +
            '.ts-wrapper.vct-ts-select .ts-control {' +
                'height: 40px !important;' +
                'min-height: 40px !important;' +
                'padding: 0 36px 0 14px !important;' +
                'font-size: 13px !important;' +
                'font-weight: 600 !important;' +
                'color: #0f172a !important;' +
                'background-color: #ffffff !important;' +
                'background-image: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2366062D%22 stroke-width=%222.5%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22m6 9 6 6 6-6%22/%3E%3C/svg%3E") !important;' +
                'background-repeat: no-repeat !important;' +
                'background-position: right 12px center !important;' +
                'border: 1px solid #cbd5e1 !important;' +
                'border-radius: 8px !important;' +
                'box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04) !important;' +
                'display: flex !important;' +
                'align-items: center !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select.focus .ts-control {' +
                'border-color: #66062D !important;' +
                'box-shadow: 0 0 0 3px rgba(102,6,45,.12) !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-control > input {' +
                'font-size: 13px !important;' +
                'font-weight: 600 !important;' +
                'color: #0f172a !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown {' +
                'margin-top: 4px !important;' +
                'background: #ffffff !important;' +
                'border: 1px solid #cbd5e1 !important;' +
                'border-radius: 8px !important;' +
                'box-shadow: 0 12px 24px rgba(15,23,42,.14) !important;' +
                'overflow: hidden !important;' +
                'z-index: 9999 !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .ts-dropdown-content {' +
                'padding: 4px !important;' +
                'max-height: 220px !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option {' +
                'padding: 10px 12px !important;' +
                'font-size: 13px !important;' +
                'font-weight: 500 !important;' +
                'line-height: 1.2 !important;' +
                'color: #0f172a !important;' +
                'background: #ffffff !important;' +
                'border-radius: 6px !important;' +
                'transition: background .15s ease, color .15s ease !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.active,' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option:hover {' +
                'background: #66062D !important;' +
                'color: #ffffff !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.selected {' +
                'background: transparent !important;' +
                'color: #66062D !important;' +
                'font-weight: 700 !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.selected.active,' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.selected:hover {' +
                'background: #66062D !important;' +
                'color: #ffffff !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""] {' +
                'font-weight: 600 !important;' +
                'color: #66062D !important;' +
            '}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""].active,' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""]:hover {' +
                'background: #f8fafc !important;' +
                'color: #66062D !important;' +
            '}' +
            '.vct-circular-back-btn {' +
                'position: absolute !important;' +
                'top: 50% !important;' +
                'transform: translateY(-50%) !important;' +
                'right: 20px !important;' +
                'width: 34px !important;' +
                'height: 34px !important;' +
                'border-radius: 50% !important;' +
                'background: #66062D !important;' +
                'border: 1px solid rgba(255, 255, 255, 0.25) !important;' +
                'color: #ffffff !important;' +
                'display: inline-flex !important;' +
                'align-items: center !important;' +
                'justify-content: center !important;' +
                'cursor: pointer !important;' +
                'box-shadow: 0 2px 5px rgba(0,0,0,0.25) !important;' +
                'z-index: 100 !important;' +
            '}' +
 
            '/* OCULTAMIENTO VISUAL DE PKEY */' +
            'table.vct-table-main th:nth-child(1), table.vct-table-main td:nth-child(1) {' +
                'width: 0px !important;' +
                'max-width: 0px !important;' +
                'padding: 0 !important;' +
                'margin: 0 !important;' +
                'overflow: hidden !important;' +
                'font-size: 0 !important;' +
                'line-height: 0 !important;' +
                'border: none !important;' +
                'opacity: 0 !important;' +
            '}' +
 
            '/* ALINEACIÓN Y ANCHOS */' +
            'table.vct-table-main th:nth-child(2), table.vct-table-main td:nth-child(2) { width: 25% !important; text-align: left !important; }' +
            'table.vct-table-main th:nth-child(3), table.vct-table-main td:nth-child(3) { width: 65% !important; text-align: left !important; }' +
            'table.vct-table-main th:nth-child(4), table.vct-table-main td:nth-child(4) { width: 10% !important; text-align: right !important; }' +
 
            '/* PADDING EN EL FOOTER DE PAGINACIÓN DE LA GRILLA */' +
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
        '</style>' +
 
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="grid"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"' +
        ' data-vct-primary-field="PKey"' +
        ' data-vct-actions="' + @AttrActionsModule + '">' +
        @VHTML_HEADER +
        @VTARJETA_PERFIL_HEADER
    AS VARCHAR(MAX));
 
    -- 8. Formulario y JS
    SET @PS_FORMULARIO = CAST(
        '<input type="hidden" name="SP.ID_GROUP_SEL" value="' + ISNULL(@V_PERFIL_SEL, '') + '" />' +
        '<input type="hidden" name="SP.ID_TASK_SEL" id="ID_TASK_SEL_HIDDEN" value="" />' +
 
        '<div class="vct-grid-host" data-vct-grid-host style="margin:0 !important; padding:0 !important;"></div>' +
 
        '<script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>' +
        '<script src="../js/vct-Core.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Tabs.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Table.js?v=20260916-3"></script>' +
        '<script src="../js/vct-modal.js?v=20260916-3"></script>' +
 
        '<script>' +
            'function initVctTomSelectMenu() {' +
                'var selectEl = document.getElementById("ID_TASK_SEL");' +
                'if (selectEl && !selectEl.tomselect && window.TomSelect) {' +
                    'new TomSelect(selectEl, {' +
                        'create: false,' +
                        'wrapperClass: "ts-wrapper vct-ts-select",' +
                        'placeholder: "Seleccione un menú",' +
                        'allowEmptyOption: true,' +
                        'controlInput: null' +
                    '});' +
                '}' +
            '};' +
            'initVctTomSelectMenu();' +
            'setTimeout(initVctTomSelectMenu, 150);' +
 
            'function ejecutarAltaMenu() {' +
                'var selectEl = document.getElementById("ID_TASK_SEL");' +
                'var valSelected = "";' +
                'if (selectEl) {' +
                    'if (selectEl.tomselect) { valSelected = selectEl.tomselect.getValue(); }' +
                    'else { valSelected = selectEl.value; }' +
                '}' +
 
                'if (!valSelected || valSelected.trim() === "") {' +
                    'if (window.VCTModal) { VCTModal.alert({ title: "Atención", text: "Debe seleccionar un menú para asociar." }); }' +
                    'else { alert("Debe seleccionar un Menú"); }' +
                    'return false;' +
                '}' +
 
                'var cleanVal = valSelected.trim();' +
                'var hInput = document.getElementById("ID_TASK_SEL_HIDDEN");' +
                'if (hInput) { hInput.value = cleanVal; }' +
 
                'if (typeof window.almacenarSeleccion === "function") {' +
                    'try { window.almacenarSeleccion("ID_TASK_SEL", cleanVal); } catch(e){}' +
                '}' +
 
                'setTimeout(function() {' +
                    'goto(''' + @VFORM_ID_CLEAN + ''', ''1C56964B-3AB1-417C-8E2D-DAB12E382D12'');' +
                '}, 200);' +
                'return false;' +
            '};' +
        '</script>'
    AS VARCHAR(MAX));
 
END
