USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_PREV_GROUPS_ACTIONS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[M_CONFIG_PREV_GROUPS_ACTIONS]
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

    DECLARE
        @V_PERFIL_SEL     VARCHAR(100) = '',
        @V_PERFIL_DESC    VARCHAR(400) = '',
        @VHTML_HEADER     VARCHAR(MAX) = '',
        @VFORM_ID_CLEAN   VARCHAR(100) = '',
        @VONCLICK_VOLVER  VARCHAR(MAX) = '',
        @VBOTON_CIRCULAR  VARCHAR(MAX) = '';

    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');

    -- =========================================================================
    -- SALVAGUARDA DE SEGURIDAD CONTRA EL APILAMIENTO EN DASHBOARD / MAIN
    -- =========================================================================
    IF @VFORM_ID_CLEAN LIKE '%a6a24eed_e652_4afe_b2ff_dc7ce9d59725%'
       OR @VFORM_ID_CLEAN LIKE '%9cc84973_b378_4761_9ace_5cd438ab9578%'
       OR @VFORM_ID_CLEAN IN ('MAIN', 'DASHBOARD', 'E0CD9397-2EC0-44EE-ACBB-D08A72ABC171')
    BEGIN
        SET @PS_TITULO = '';
        SET @PS_FORMULARIO = '';
        RETURN;
    END

    -- 1. Leer selección de perfil desde M_CONFIG
    SELECT TOP 1
        @V_PERFIL_SEL = ISNULL(ID_GROUP_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    SET @V_PERFIL_SEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@V_PERFIL_SEL, ''), ',', ''), '''', ''), '"', '')));

    IF @V_PERFIL_SEL = ''
    BEGIN
        SET @PS_TITULO = '';
        SET @PS_FORMULARIO = '';
        RETURN;
    END

    -- 2. Nombre descriptivo del perfil activo
    SELECT TOP 1
        @V_PERFIL_DESC = ISNULL(Name, '')
    FROM dbo.Groups WITH (NOLOCK)
    WHERE Id = @V_PERFIL_SEL;

    -- 3. Renderizar Header Estándar de Módulo (mismo set de parámetros que MODULOS)
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Matriz de Permisos Funcionales',
         @SUBTITLE            = 'Administre las acciones habilitadas para el perfil seleccionado',
         @MODULE_ICON         = 'shield-check',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Acciones / Permisos',
         @DEFAULT_TAB_ICON    = 'shield-check',
         @DYNAMIC_TAB_ID      = '',
         @DYNAMIC_TAB_TITLE   = '',
         @DYNAMIC_TAB_ICON    = '',
         @SHOW_ACTION_BUTTON  = 0,
         @ACTION_BUTTON_TEXT  = '',
         @ACTION_BUTTON_ICON  = '',
         @ACTION_TARGET_TAB   = '',
         @ACTION_MODE         = '',
         @ACTION_ONCLICK      = '',
         @HTML                = @VHTML_HEADER OUTPUT;

    -- 4. Botón circular "Volver" armado en línea (mismo patrón que MODULOS / Usuarios)
    SET @VONCLICK_VOLVER = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_ACTION_SEL'','''');almacenarSeleccion(''NEW_ID'','''');almacenarSeleccion(''ID_DELETE'','''');} goto(''' + @VFORM_ID_CLEAN + ''', ''21B6894B-27A5-4A5F-9CA9-BFD807276E9C''); return false;';

    SET @VBOTON_CIRCULAR =
        '<button type="button" class="vct-circular-back-btn" onclick="' + @VONCLICK_VOLVER + '" title="Volver a Perfiles">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>' +
        '</button>';

    SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-module-header"', 'class="vct-module-header" style="position:relative;"');
    IF CHARINDEX('</div>', @VHTML_HEADER) > 0
    BEGIN
        SET @VHTML_HEADER = STUFF(@VHTML_HEADER, CHARINDEX('</div>', @VHTML_HEADER), 0, @VBOTON_CIRCULAR);
    END

    -- 5. Tarjeta resumen del perfil seleccionado (plana, pegada al header, igual que MODULOS/Usuarios)
    DECLARE @VTARJETA_PERFIL_HEADER VARCHAR(MAX) =
        '<div class="vct-card-perfil-header" style="background:#fff; border:none; border-radius:0; padding:16px 20px; margin:12px 0 0 0; box-shadow:none;">' +
            '<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; border-left:4px solid #66062D; padding-left:16px;">' +
                '<div>' +
                    '<div style="display:flex; align-items:center; gap:8px;">' +
                        '<h3 style="margin:0; font-size:15px; font-weight:700; color:#0f172a;">Perfil:</h3>' +
                        '<span style="display:inline-flex; align-items:center; gap:6px; padding:5px 12px; background:rgba(102,6,45,0.10); color:#66062D; border-radius:20px; font-size:14px; font-weight:700;">' +
                            '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="7" r="3"/><path d="M6 21v-2a6 6 0 0 1 12 0v2"/><path d="M6 8a3 3 0 1 0 0 6"/><path d="M18 8a3 3 0 1 1 0 6"/></svg>' +
                            ISNULL(@V_PERFIL_DESC, @V_PERFIL_SEL) +
                        '</span>' +
                    '</div>' +
                    '<p style="margin:5px 0 0 0; font-size:12px; color:#64748b;">Active o desactive los interruptores para otorgar o denegar permisos a este perfil.</p>' +
                '</div>' +
            '</div>' +
        '</div>';

    -- 6. Encabezado HTML (sin overrides de layout: el header usa el mismo estándar que MODULOS/Usuarios)
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" type="text/css" href="../css/vct-Table.css?v=18.0.0" />' +
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
        '<style>' +
            '.vct-module-header { position: relative !important; }' +
            '.vct-module-heading { display: flex !important; align-items: center !important; gap: 16px !important; }' +
            '.vct-module-icon { flex-shrink: 0 !important; }' +
            '.vct-module-heading-text { display: flex !important; flex-direction: column !important; }' +

            'tbody tr td:has(link), tbody tr:has(link), td:has(link), tr:has(link) { display: none !important; }' +

            '/* 1. Botón circular volver integrado */' +
            '.vct-circular-back-btn {' +
                'position: absolute !important;' +
                'top: 50% !important;' +
                'transform: translateY(-50%) !important;' +
                'right: 20px !important;' +
                'width: 32px !important;' +
                'height: 32px !important;' +
                'border-radius: 50% !important;' +
                'background: #66062D !important;' +
                'border: 1px solid rgba(255, 255, 255, 0.2) !important;' +
                'color: #ffffff !important;' +
                'display: inline-flex !important;' +
                'align-items: center !important;' +
                'justify-content: center !important;' +
                'cursor: pointer !important;' +
                'box-shadow: 0 2px 5px rgba(0,0,0,0.15) !important;' +
                'transition: all 0.2s ease !important;' +
                'z-index: 100 !important;' +
            '}' +
            '.vct-circular-back-btn:hover {' +
                'background: #4a0420 !important;' +
                'transform: translateY(-50%) scale(1.05) !important;' +
            '}' +

            '/* 2. Tarjeta del perfil plana, sin borde ni sombra, pegada al header */' +
            '.vct-card-perfil-header {' +
                'background: #ffffff !important;' +
                'border: none !important;' +
                'border-radius: 0 !important;' +
                'margin: 12px 0 0 0 !important;' +
                'padding: 16px 20px !important;' +
                'box-shadow: none !important;' +
            '}' +

            '/* 3. Envoltorio general de la grilla */' +
            '.vct-grid-host, .vct-table-wrapper {' +
                'padding-left: 20px !important;' +
                'padding-right: 20px !important;' +
                'padding-bottom: 24px !important;' +
                'box-sizing: border-box !important;' +
            '}' +

            '/* 4. Aire en el Footer / Paginado */' +
            '.vct-table-footer, ' +
            'div.vct-grid-host div[style*="display:flex"][style*="justify-content:space-between"] {' +
                'padding: 16px 20px 20px 20px !important;' +
                'margin-top: 12px !important;' +
                'border-top: 1px solid #f1f5f9 !important;' +
                'box-sizing: border-box !important;' +
            '}' +

            '/* 5. Padding interno de Celdas */' +
            'table.vct-table-main thead th {' +
                'padding: 14px 18px !important;' +
            '}' +
            'table.vct-table-main tbody td {' +
                'padding: 12px 18px !important;' +
                'vertical-align: middle !important;' +
            '}' +

            '/* 6. Switch Toggle Fino (Lucide Style) */' +
            '.vct-switch {' +
                'position: relative !important;' +
                'display: inline-block !important;' +
                'width: 34px !important;' +
                'height: 18px !important;' +
                'vertical-align: middle !important;' +
                'margin: 0 auto !important;' +
            '}' +
            '.vct-switch input {' +
                'opacity: 0 !important;' +
                'width: 0 !important;' +
                'height: 0 !important;' +
            '}' +
            '.vct-slider {' +
                'position: absolute !important;' +
                'cursor: pointer !important;' +
                'top: 0; left: 0; right: 0; bottom: 0;' +
                'background-color: #cbd5e1 !important;' +
                'transition: .2s ease-in-out !important;' +
                'border-radius: 18px !important;' +
            '}' +
            '.vct-slider:before {' +
                'position: absolute !important;' +
                'content: "" !important;' +
                'height: 12px !important;' +
                'width: 12px !important;' +
                'left: 3px !important;' +
                'bottom: 3px !important;' +
                'background-color: #ffffff !important;' +
                'transition: .2s ease-in-out !important;' +
                'border-radius: 50% !important;' +
                'box-shadow: 0 1px 2px rgba(0,0,0,0.15) !important;' +
            '}' +
            'input:checked + .vct-slider {' +
                'background-color: #66062D !important;' +
            '}' +
            'input:checked + .vct-slider:before {' +
                'transform: translateX(16px) !important;' +
            '}' +

            '/* Ocultar pestañas huérfanas */' +
            '.vct-tabs-bar, .vct-tabs-bar:empty, .vct-panels:empty, .vct-panel:not(.is-active) { display: none !important; }' +
            '.vct-module-content, div[id*="step_"] { margin-top: 0 !important; padding-top: 0 !important; }' +
        '</style>' +

        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="grid"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '">' +
        @VHTML_HEADER +
        @VTARJETA_PERFIL_HEADER
    AS VARCHAR(MAX));

    -- 7. Formulario, campos ocultos de persistencia e inyección de JS
    SET @PS_FORMULARIO = CAST(
        '<!-- CAMPOS OCULTOS REQUERIDOS PARA PERSISTIR EN M_CONFIG --> ' +
        '<input type="hidden" name="SP.ID_GROUP_SEL" value="' + ISNULL(@V_PERFIL_SEL, '') + '" />' +
        '<input type="hidden" name="SP.ID_ACTION_SEL" id="ID_ACTION_SEL_HIDDEN" value="" />' +
        '<input type="hidden" name="SP.NEW_ID" id="NEW_ID_HIDDEN" value="" />' +
        '<input type="hidden" name="SP.ID_DELETE" id="ID_DELETE_HIDDEN" value="" />' +

        '<div class="vct-grid-host" data-vct-grid-host style="margin:0 !important; padding:0 !important;"></div>' +

        '<script src="../js/vct-Core.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Tabs.js?v=20260916-3"></script>' +
        '<script src="../js/vct-Table.js?v=20260916-3"></script>' +
        '<script src="../js/vct-modal.js?v=20260916-3"></script>' +

        '<script type="text/javascript">' +
            '(function () {' +
                '"use strict";' +

                'function getColumnIndices() {' +
                    'var ths = document.querySelectorAll("table.vct-table-main thead th");' +
                    'var indices = { codeIdx: -1, stateIdx: -1 };' +

                    'for (var i = 0; i < ths.length; i++) {' +
                        'var txt = ths[i].textContent.trim().toUpperCase();' +
                        'if (txt === "CODIGO" || txt === "CÓDIGO") { indices.codeIdx = i; }' +
                        'if (txt === "ESTADO") { indices.stateIdx = i; }' +
                    '}' +
                    'return indices;' +
                '}' +

                'function renderGridSwitches() {' +
                    'var map = getColumnIndices();' +
                    'if (map.codeIdx === -1 || map.stateIdx === -1) return;' +

                    'var rows = document.querySelectorAll("table.vct-table-main tbody tr");' +

                    'for (var i = 0; i < rows.length; i++) {' +
                        'var cells = rows[i].children;' +
                        'if (!cells[map.codeIdx] || !cells[map.stateIdx]) continue;' +

                        'var actionCode = cells[map.codeIdx].textContent.trim();' +
                        'var valState = cells[map.stateIdx].textContent.trim();' +

                        'if (!rows[i].getAttribute("data-vct-chk-bound") || cells[map.stateIdx].querySelector("input.vct-action-switch") === null) {' +
                            'rows[i].setAttribute("data-vct-chk-bound", "1");' +
                            'var isChecked = valState === "1" || valState === "HABILITADO";' +

                            'cells[map.stateIdx].style.textAlign = "center";' +
                            'cells[map.stateIdx].innerHTML = ' +
                                '"<label class=\"vct-switch\">" +' +
                                    '"<input type=\"checkbox\" class=\"vct-action-switch\" data-code=\"" + actionCode + "\" " + (isChecked ? "checked" : "") + " />" +' +
                                    '"<span class=\"vct-slider\"></span>" +' +
                                '"</label>";' +
                        '}' +
                    '}' +
                '}' +

                'function bindSwitchEvents() {' +
                    'if (window._vctSwitchBound) return;' +
                    'window._vctSwitchBound = true;' +

                    'document.addEventListener("change", function (event) {' +
                        'if (!event.target || !event.target.classList.contains("vct-action-switch")) return;' +

                        'var actionCode = event.target.getAttribute("data-code");' +
                        'var newState = event.target.checked ? "1" : "0";' +

                        'var inputAction = document.getElementById("ID_ACTION_SEL_HIDDEN");' +
                        'var inputState = document.getElementById("NEW_ID_HIDDEN");' +

                        'if (inputAction) inputAction.value = actionCode;' +
                        'if (inputState) inputState.value = newState;' +

                        'if (typeof window.almacenarSeleccion === "function") {' +
                            'try { window.almacenarSeleccion("ID_ACTION_SEL", actionCode); } catch(e){}' +
                            'try { window.almacenarSeleccion("NEW_ID", newState); } catch(e){}' +
                        '}' +

                        'setTimeout(function() {' +
                            'var moduleElem = document.querySelector("section.vct-module");' +
                            'var formId = moduleElem ? moduleElem.getAttribute("data-vct-form-id") : "";' +

                            'if (typeof window.next === "function") {' +
                                'if (formId) {' +
                                    'window.next(formId);' +
                                '} else {' +
                                    'window.next();' +
                                '}' +
                            '} else if (typeof next === "function") {' +
                                'next();' +
                            '}' +
                        '}, 50);' +

                        'return false;' +
                    '});' +
                '}' +

                'function startGridObserver() {' +
                    'renderGridSwitches();' +
                    'bindSwitchEvents();' +

                    'var hostElem = document.querySelector(".vct-grid-host") || document.body;' +
                    'var observer = new MutationObserver(function () {' +
                        'renderGridSwitches();' +
                    '});' +

                    'observer.observe(hostElem, { childList: true, subtree: true });' +

                    '[100, 300, 600, 1000].forEach(function (delay) {' +
                        'setTimeout(renderGridSwitches, delay);' +
                    '});' +
                '}' +

                'if (document.readyState === "loading") {' +
                    'document.addEventListener("DOMContentLoaded", startGridObserver);' +
                '} else {' +
                    'startGridObserver();' +
                '}' +
            '})();' +
        '</script>'
    AS VARCHAR(MAX));

END
