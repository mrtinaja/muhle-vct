 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_ACTIONS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID VARCHAR(100),
    @FORM_ID VARCHAR(100),
    @PS_TITULO VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ID_ACTION_SEL VARCHAR(100) = '',
        @VNEW_ID_TMP VARCHAR(200) = '',
        @VNOMBRE_TMP VARCHAR(300) = '',
        @VMODULO_TMP VARCHAR(200) = '',
        @VSCOPE_TMP VARCHAR(200) = '',
        @VTIPO_TMP VARCHAR(100) = '',
        @VSELECTOR_TMP VARCHAR(300) = '',
        @VVISIBILIDAD_TMP VARCHAR(50) = '',
        @VDESC_ERROR NVARCHAR(MAX) = '',
        @VHTML_HEADER VARCHAR(MAX) = '',
        @VOPTIONS_TIPO VARCHAR(MAX) = '',
        @VOPTIONS_VISIB VARCHAR(MAX) = '',
        @VREADONLY_ATTR VARCHAR(300) = '',
        @VIN_EDIT BIT = 0,
        @VACTIVE_TAB VARCHAR(20) = 'grid',
        @VDYNAMIC_TAB_TITLE VARCHAR(100) = '',
        @VDYNAMIC_TAB_ICON VARCHAR(100) = '',
        @VFORM_TITLE VARCHAR(150) = '',
        @VFORM_SUBTITLE VARCHAR(300) = '',
        @VSUBMIT_LABEL VARCHAR(100) = '',
        @VFORM_ICON VARCHAR(100) = '',
        @VFORM_ID_CLEAN VARCHAR(100) = '';
    -- Lectura de la sesión temporal en M_CONFIG
    SELECT TOP 1 @ID_ACTION_SEL = ISNULL(NULLIF(LTRIM(RTRIM(REPLACE(ID_ACTION_SEL, ',', ''))), ''), ''),
        @VNEW_ID_TMP = ISNULL(NEW_ID, ''),
        @VNOMBRE_TMP = ISNULL(NEW_NAME, ''),
        @VMODULO_TMP = ISNULL(NEW_AREA, ''),
        @VTIPO_TMP = ISNULL(NULLIF(LTRIM(RTRIM(REPLACE(NEW_PERFIL, ',', ''))), ''), ''),
        @VDESC_ERROR = ISNULL(DESC_ERROR, '')
        FROM M_CONFIG WITH (NOLOCK)
        WHERE PAR_KEY = @IPKEYJOB;
    SET @ID_ACTION_SEL = LTRIM(RTRIM(ISNULL(@ID_ACTION_SEL, '')));
    SET @VDESC_ERROR = LTRIM(RTRIM(ISNULL(@VDESC_ERROR, '')));
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
    SET @VIN_EDIT = CASE WHEN @ID_ACTION_SEL <> '' THEN 1 ELSE 0 END;
    IF @VDESC_ERROR <> ''
    SET @VACTIVE_TAB = 'form';
    IF @VIN_EDIT = 1
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" aria-readonly="true" style="background-color:#f8fafc;cursor:not-allowed;"';
        IF @VDESC_ERROR = ''
        BEGIN
            SELECT TOP 1 @VNEW_ID_TMP = ISNULL(NULLIF(@VNEW_ID_TMP, ''), ISNULL(a.Id, '')),
                @VNOMBRE_TMP = ISNULL(NULLIF(@VNOMBRE_TMP, ''), ISNULL(a.Name, '')),
                @VTIPO_TMP = ISNULL(NULLIF(@VTIPO_TMP, ''), ISNULL(a.Tipo, ''))
                FROM Actions a WITH (NOLOCK)
                WHERE UPPER(LTRIM(RTRIM(a.Id))) = UPPER(@ID_ACTION_SEL);
        END;
        SET @VDYNAMIC_TAB_TITLE = 'Editar acción';
        SET @VDYNAMIC_TAB_ICON = 'pencil';
        SET @VFORM_TITLE = 'Editar acción';
        SET @VFORM_SUBTITLE = 'Modifique los parámetros del permiso seleccionado.';
        SET @VSUBMIT_LABEL = 'Guardar cambios';
        SET @VFORM_ICON = 'pencil';
    END
    ELSE
    BEGIN
        SET @VREADONLY_ATTR = '';
        IF @VDESC_ERROR = ''
        BEGIN
            SET @VNEW_ID_TMP = '';
            SET @VNOMBRE_TMP = '';
            SET @VMODULO_TMP = '';
            SET @VSCOPE_TMP = '';
            SET @VTIPO_TMP = '';
            SET @VSELECTOR_TMP = '';
            SET @VVISIBILIDAD_TMP = 'HIDE';
        END;
        SET @VDYNAMIC_TAB_TITLE = 'Nueva acción';
        SET @VDYNAMIC_TAB_ICON = 'plus-circle';
        SET @VFORM_TITLE = 'Nueva acción';
        SET @VFORM_SUBTITLE = 'Defina un nuevo permiso reutilizable en el sistema.';
        SET @VSUBMIT_LABEL = 'Crear acción';
        SET @VFORM_ICON = 'plus-circle';
    END;
    -- Opciones para el combo de Tipo
    SET @VTIPO_TMP = UPPER(LTRIM(RTRIM(ISNULL(@VTIPO_TMP, ''))));
    SET @VOPTIONS_TIPO = '<option value=""'
        + CASE WHEN @VTIPO_TMP = '' THEN ' selected="selected"' ELSE '' END
        + '>Seleccione tipo...</option>'
        + '<option value="MODULE"'
        + CASE WHEN @VTIPO_TMP = 'MODULE' THEN ' selected="selected"' ELSE '' END
        + '>Módulo</option>'
        + '<option value="SIDEBAR"'
        + CASE WHEN @VTIPO_TMP = 'SIDEBAR' THEN ' selected="selected"' ELSE '' END
        + '>Menú / Sidebar</option>'
        + '<option value="TAB"'
        + CASE WHEN @VTIPO_TMP = 'TAB' THEN ' selected="selected"' ELSE '' END
        + '>Pestaña</option>'
        + '<option value="ACTION"'
        + CASE WHEN @VTIPO_TMP = 'ACTION' THEN ' selected="selected"' ELSE '' END
        + '>Comando / Botón</option>'
        + '<option value="GRID"'
        + CASE WHEN @VTIPO_TMP = 'GRID' THEN ' selected="selected"' ELSE '' END
        + '>Grilla</option>';
    -- Opciones para el combo de Visibilidad
    SET @VVISIBILIDAD_TMP = UPPER(LTRIM(RTRIM(ISNULL(@VVISIBILIDAD_TMP, 'HIDE'))));
    SET @VOPTIONS_VISIB = '<option value="HIDE"'
        + CASE WHEN @VVISIBILIDAD_TMP = 'HIDE' THEN ' selected="selected"' ELSE '' END
        + '>Ocultar</option>'
        + '<option value="DISABLE"'
        + CASE WHEN @VVISIBILIDAD_TMP = 'DISABLE' THEN ' selected="selected"' ELSE '' END
        + '>Deshabilitar</option>';
    -- Evento ONCLICK de la pestaña/botón Nuevo
    DECLARE @VONCLICK VARCHAR(MAX) = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_ACTION_SEL'','''');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
    EXEC dbo.VCT_RENDER_MODULE_HEADER
        @TITLE = 'ABM de Acciones',
        @SUBTITLE = 'Administre permisos jerárquicos y componentes detectables',
        @MODULE_ICON = 'route',
        @DEFAULT_TAB_ID = 'grid',
        @DEFAULT_TAB_TITLE = 'Acciones',
        @DEFAULT_TAB_ICON = 'list-checks',
        @DYNAMIC_TAB_ID = 'form',
        @DYNAMIC_TAB_TITLE = @VDYNAMIC_TAB_TITLE,
        @DYNAMIC_TAB_ICON = @VDYNAMIC_TAB_ICON,
        @SHOW_ACTION_BUTTON = 1,
        @ACTION_BUTTON_TEXT = 'Nueva',
        @ACTION_BUTTON_ICON = 'plus',
        @ACTION_TARGET_TAB = 'form',
        @ACTION_MODE = '',
        @ACTION_ONCLICK = @VONCLICK,
        @HTML = @VHTML_HEADER OUTPUT;
    SET @VHTML_HEADER = ISNULL(@VHTML_HEADER, '');
    IF @VACTIVE_TAB = 'form'
    BEGIN
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-tab is-active" data-vct-tab="grid"', 'class="vct-tab" data-vct-tab="grid"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab hidden', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
    END;
    -- TÍTULO Y RECURSOS
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />'
        + '<link rel="stylesheet" href="../css/vct-modal.css" />'
        + '<style>'
        + '.vct-select-input{'
        + 'width:100%!important;height:40px!important;min-height:40px!important;padding:0 36px 0 14px!important;font-size:13px!important;font-weight:500!important;color:#0f172a!important;background-color:#fff!important;'
        + 'background-image:url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2366062D%22 stroke-width=%222.5%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22m6 9 6 6 6-6%22/%3E%3C/svg%3E")!important;'
        + 'background-repeat:no-repeat!important;background-position:right 12px center!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 1px 2px rgba(0,0,0,.04)!important;appearance:none!important;-webkit-appearance:none!important;-moz-appearance:none!important;outline:none!important;cursor:pointer!important;display:block!important;'
        + '}'
        + '.vct-select-input:focus{border-color:#66062D!important;box-shadow:0 0 0 3px rgba(102,6,45,.12)!important;}'
        + '.vct-form-group select.vct-select-input[data-vct-custom-init="true"]{display:none!important;}'
        + '.vct-custom-select-wrapper{position:relative!important;width:100%!important;display:block!important;}'
        + '.vct-custom-select-trigger{width:100%!important;height:40px!important;min-height:40px!important;padding:0 36px 0 14px!important;font-size:13px!important;font-weight:500!important;color:#0f172a!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 1px 2px rgba(0,0,0,.04)!important;display:flex!important;align-items:center!important;justify-content:space-between!important;cursor:pointer!important;text-align:left!important;}'
        + '.vct-custom-select-trigger:hover{border-color:#b7c4d7!important;}'
        + '.vct-custom-select-wrapper.is-open .vct-custom-select-trigger{border-color:#66062D!important;box-shadow:0 0 0 3px rgba(102,6,45,.12)!important;}'
        + '.vct-custom-select-trigger span{display:block!important;overflow:hidden!important;text-overflow:ellipsis!important;white-space:nowrap!important;}'
        + '.vct-custom-select-trigger i,.vct-custom-select-trigger svg{width:16px!important;height:16px!important;color:#66062D!important;stroke:#66062D!important;flex:0 0 auto!important;}'
        + '.vct-custom-select-options{display:none!important;position:absolute!important;top:calc(100% + 4px)!important;left:0!important;right:0!important;z-index:9999!important;margin:0!important;padding:4px!important;list-style:none!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 12px 24px rgba(15,23,42,.14)!important;max-height:220px!important;overflow:auto!important;}'
        + '.vct-custom-select-wrapper.is-open .vct-custom-select-options{display:block!important;}'
        + '.vct-custom-select-option{margin:0!important;padding:10px 12px!important;list-style:none!important;font-size:13px!important;font-weight:500!important;line-height:1.2!important;color:#0f172a!important;background:#fff!important;border-radius:6px!important;cursor:pointer!important;}'
        + '.vct-custom-select-option::marker{content:""!important;}'
        + '.vct-custom-select-option:hover,.vct-custom-select-option.is-selected{background:#66062D!important;color:#fff!important;}'
        + '.vct-tree-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:12px;font-family:monospace;font-size:12px;line-height:1.8;}'
        + '.vct-panel[data-vct-panel="grid"]{padding-top:0!important;margin-top:0!important;}'
        + '.vct-grid-host{padding-top:0!important;margin-top:0!important;}'
        + '.vct-grid-host .vct-table-wrapper{margin-top:0!important;}'
        + '/* AJUSTE VISUAL LOCAL: compactar tab y toolbar de ABM Acciones */'
        + '.vct-module .vct-tabs-bar{min-height:42px!important;}'
        + '.vct-module .vct-tab{min-height:42px!important;height:42px!important;padding:0 18px!important;font-size:13px!important;gap:8px!important;}'
        + '.vct-module .vct-tab svg,.vct-module .vct-tab i{width:16px!important;height:16px!important;}'
        + '.vct-module .vct-table-toolbar{padding:10px 16px!important;margin:0!important;min-height:0!important;gap:8px!important;}'
        + '.vct-module .vct-table-toolbar select{height:40px!important;min-height:40px!important;font-size:13px!important;padding-top:0!important;padding-bottom:0!important;}'
        + '.vct-module .vct-table-toolbar button,.vct-module .vct-table-toolbar .vct-btn{min-height:40px!important;height:40px!important;padding:0 14px!important;font-size:13px!important;}'
        + '.vct-module .vct-table-toolbar button svg,.vct-module .vct-table-toolbar .vct-btn svg{width:16px!important;height:16px!important;}'
        + '.vct-module .vct-table-search input,.vct-module input[type="search"]{height:40px!important;min-height:40px!important;font-size:13px!important;}'
        + '/* FIX LOCAL: ocultar únicamente el carrier legacy generado por Mühle para M_CONFIG_ACTIONS */'
        + '#mainContainer .w3-responsive:has(> table[id^="grid_SP_M_CONFIG_ACTIONS_"]){display:none!important;margin:0!important;padding:0!important;height:0!important;min-height:0!important;border:0!important;overflow:hidden!important;}'
        + '</style>'
        + '<section class="vct-module"'
        + ' data-vct-module'
        + ' data-vct-tabs'
        + ' data-vct-default-tab="grid"'
        + ' data-vct-active-tab="'
        + ISNULL(@VACTIVE_TAB, 'grid')
        + '"'
        + ' data-vct-grid-selector="[data-vct-grid-source]"'
        + ' data-vct-form-id="'
        + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;')
        + '"'
        + ' data-vct-primary-field="Codigo"'
        + ' data-vct-edit-mode="server"'
        + ' data-vct-edit-storage-key="ID_ACTION_SEL"'
        + ' data-vct-edit-tab="form"'
        + ' data-vct-initial-mode="'
        + CASE WHEN @VIN_EDIT = 1 THEN 'edit' ELSE 'new' END
        + '"'
        + ' data-vct-mode-new="{&quot;tabTitle&quot;:&quot;Nueva acción&quot;,&quot;tabIcon&quot;:&quot;plus-circle&quot;,&quot;title&quot;:&quot;Nueva acción&quot;,&quot;subtitle&quot;:&quot;Defina un nuevo permiso reutilizable en el sistema.&quot;,&quot;icon&quot;:&quot;plus-circle&quot;,&quot;submit&quot;:&quot;Crear acción&quot;}"'
        + ' data-vct-mode-edit="{&quot;tabTitle&quot;:&quot;Editar acción&quot;,&quot;tabIcon&quot;:&quot;pencil&quot;,&quot;title&quot;:&quot;Editar acción&quot;,&quot;subtitle&quot;:&quot;Modifique los parámetros del permiso seleccionado.&quot;,&quot;icon&quot;:&quot;pencil&quot;,&quot;submit&quot;:&quot;Guardar cambios&quot;}">'
        + @VHTML_HEADER AS VARCHAR(MAX));
    -- ESTRUCTURA DEL FORMULARIO
    SET @PS_FORMULARIO = CAST(
        '<div class="vct-panels">'
        + '<div class="vct-panel '
        + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'is-active' ELSE '' END
        + '" data-vct-panel="grid" '
        + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END
        + '>'
        + '<div class="vct-grid-host" data-vct-grid-host></div>'
        + '</div>'
        + '<div class="vct-panel '
        + CASE WHEN @VACTIVE_TAB = 'form' THEN 'is-active' ELSE '' END
        + '" data-vct-panel="form" '
        + CASE WHEN @VACTIVE_TAB = 'form' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END
        + '>'
        + '<div class="vct-form-card">'
        + '<div class="vct-form-header">'
        + '<div class="vct-form-icon" data-vct-form-icon><i data-lucide="'
        + ISNULL(@VFORM_ICON, 'plus-circle')
        + '"></i></div>'
        + '<div>'
        + '<h3 class="vct-form-title" data-vct-form-title>'
        + ISNULL(@VFORM_TITLE, 'Nueva acción')
        + '</h3>'
        + '<p class="vct-form-subtitle" data-vct-form-subtitle>'
        + ISNULL(@VFORM_SUBTITLE, '')
        + '</p>'
        + '</div>'
        + '</div>'
        + '<div class="vct-form-body">'
        + '<input type="hidden" id="ID_ACTION_SEL" name="SP.ID_ACTION_SEL" value="'
        + ISNULL(@ID_ACTION_SEL, '')
        + '" data-vct-selected-key />'
        + '<input type="hidden" id="VCT_FORM_MODE" data-vct-form-mode value="'
        + CASE WHEN @VIN_EDIT = 1 THEN 'EDIT' ELSE 'NEW' END
        + '" />'
        + '<div class="vct-form-grid">'
        + '<!-- Campo 1: Código -->'
        + '<div class="vct-form-group vct-form-group-full">'
        + '<label for="vctActionCode"><i data-lucide="fingerprint"></i><span>Código de Permiso</span><span class="vct-required" id="idCampo1"><i data-lucide="asterisk"></i></span></label>'
        + '<input class="vct-input" type="text" id="vctActionCode" name="SP.NEW_ID" value="'
        + ISNULL(@VNEW_ID_TMP, '')
        + '" placeholder="ej. CLIENTES.EDIT" autocomplete="off" data-vct-field="Codigo" data-vct-primary-input'
        + ISNULL(@VREADONLY_ATTR, '')
        + ' />'
        + '</div>'
        + '<!-- Campo 2: Nombre -->'
        + '<div class="vct-form-group vct-form-group-full">'
        + '<label for="vctActionName"><i data-lucide="type"></i><span>Nombre visible</span><span class="vct-required" id="idCampo2"><i data-lucide="asterisk"></i></span></label>'
        + '<input class="vct-input" type="text" id="vctActionName" name="SP.NEW_NAME" value="'
        + ISNULL(@VNOMBRE_TMP, '')
        + '" placeholder="ej. Editar clientes" autocomplete="off" data-vct-field="Nombre" />'
        + '</div>'
        + '<!-- Campo 3: Módulo -->'
        + '<div class="vct-form-group">'
        + '<label for="vctActionModule"><i data-lucide="box"></i><span>Módulo / Contexto</span></label>'
        + '<input class="vct-input" type="text" id="vctActionModule" name="SP.NEW_AREA" value="'
        + ISNULL(@VMODULO_TMP, '')
        + '" placeholder="ej. CLIENTES" autocomplete="off" data-vct-field="Modulo" />'
        + '</div>'
        + '<!-- Campo 4: Tipo -->'
        + '<div class="vct-form-group">'
        + '<label for="vctActionType"><i data-lucide="tag"></i><span>Tipo de Acción</span></label>'
        + '<select class="vct-select-input vct-select-custom" id="vctActionType" name="SP.NEW_PERFIL" data-vct-field="Tipo">'
        + ISNULL(@VOPTIONS_TIPO, '')
        + '</select>'
        + '</div>'
        + '<!-- Campo Opcional: Comportamiento (solo UI, NO se persiste: M_CONFIG no tiene columna VISIBILITY) -->'
        + '<div class="vct-form-group vct-form-group-full">'
        + '<label for="vctActionVisibility"><i data-lucide="eye-off"></i><span>Comportamiento si no está permitido</span></label>'
        + '<select class="vct-select-input vct-select-custom" id="vctActionVisibility">'
        + ISNULL(@VOPTIONS_VISIB, '')
        + '</select>'
        + '</div>'
        + '</div>'
        + '<!-- Acciones del Formulario con la llamada estándar vctConfirmarGuardar -->'
        + '<div class="vct-form-actions">'
        + '<button type="button" class="vct-button vct-button-secondary" data-vct-close-tab="form" data-vct-fallback-tab="grid" data-vct-reset-on-close><i data-lucide="x"></i><span>Cancelar</span></button>'
        + '<button type="button" class="vct-button vct-button-primary" onclick="vctConfirmarGuardar('''
        + ISNULL(@VFORM_ID_CLEAN, '')
        + ''',4);return false;" style="display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:0 20px;height:42px;"><i data-lucide="save"></i><span class="vct-button-text" style="display:inline-block;font-weight:600;">'
        + ISNULL(@VSUBMIT_LABEL, 'Crear acción')
        + '</span></button>'
        + '</div>'
        + '</div>'
        + '</div>'
        + '</div>'
        + '</div>'
        + '<script src="../js/vct-Core.js?v=20260916-3"></script>'
        + '<script src="../js/vct-Tabs.js?v=20260916-3"></script>'
        + '<script src="../js/vct-Table.js?v=20260916-3"></script>'
        + '<script src="../js/vct-modal.js?v=20260916-3"></script>'
        + '<script src="../js/vct-Select.js?v=20260916-3"></script>'
        + '<script>'
        + '(function(){'
        + 'function run(){'
        + 'console.log("[VCT-ACTIONS] init custom selects");'
        + 'if(window.initVctCustomSelects){window.initVctCustomSelects(document.querySelector("[data-vct-panel=form]")||document);}'
        + 'if(window.lucide&&typeof window.lucide.createIcons==="function"){window.lucide.createIcons();}'
        + '}'
        + 'if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",run);}else{run();}'
        + 'setTimeout(run,100);'
        + 'setTimeout(run,400);'
        + 'setTimeout(run,800);'
        + '})();'
        + '</script>' AS VARCHAR(MAX));
    IF @VDESC_ERROR <> ''
    BEGIN
        UPDATE M_CONFIG
        SET DESC_ERROR = NULL
        WHERE PAR_KEY = @IPKEYJOB;
    END
END
