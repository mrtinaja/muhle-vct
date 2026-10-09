 
CREATE PROCEDURE [dbo].[M_CONFIG_INICIA_AREAS]
(
    @IPKEYJOB      VARCHAR(100),
    @IUSERID        VARCHAR(100),
    @FORM_ID        VARCHAR(100),
    @PS_TITULO      VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @ID_AREA_SEL        VARCHAR(100)  = '',
        @VID_AREA_TMP       INT           = 0,
        @VNOMBRE_TMP        NVARCHAR(200) = '',
        @VDESC_ERROR        NVARCHAR(MAX) = '',
        @VHTML_HEADER       VARCHAR(MAX)  = '',
        @VREADONLY_ATTR     VARCHAR(300)  = '',
        @VIN_EDIT           BIT           = 0,
        @VACTIVE_TAB        VARCHAR(20)   = 'grid',
        @VDYNAMIC_TAB_TITLE VARCHAR(100)  = '',
        @VDYNAMIC_TAB_ICON    VARCHAR(100)  = '',
        @VFORM_TITLE        VARCHAR(150)  = '',
        @VFORM_SUBTITLE     VARCHAR(300)  = '',
        @VSUBMIT_LABEL      VARCHAR(100)  = '',
        @VFORM_ICON         VARCHAR(100)  = '',
        @VFORM_ID_CLEAN     VARCHAR(100)  = '';
 
    -- 1. Recuperar valores desde M_CONFIG (Soporta ID_USER_SEL o ID_SECTOR_SEL)
    SELECT TOP 1
        @ID_AREA_SEL = ISNULL(NULLIF(LTRIM(RTRIM(ID_USER_SEL)), ''), ISNULL(NULLIF(LTRIM(RTRIM(ID_SECTOR_SEL)), ''), '')),
        @VNOMBRE_TMP = ISNULL(NEW_NAME, ''),
        @VDESC_ERROR = ISNULL(DESC_ERROR, '')
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_AREA_SEL    = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@ID_AREA_SEL, ''), ',', ''), '''', ''), '"', '')));
    SET @VDESC_ERROR    = LTRIM(RTRIM(ISNULL(@VDESC_ERROR, '')));
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
 
    SET @VIN_EDIT = CASE WHEN @ID_AREA_SEL <> '' AND @ID_AREA_SEL <> '0' THEN 1 ELSE 0 END;
 
    IF @VDESC_ERROR <> ''
    BEGIN
        SET @VACTIVE_TAB = 'form';
    END
 
    -- 2. Lectura para Modo Edición vs Modo Alta
    IF @VIN_EDIT = 1
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" aria-readonly="true" style="background-color:#f8fafc; cursor:not-allowed;"';
 
        IF @VDESC_ERROR = ''
        BEGIN
            SELECT TOP 1
                @VNOMBRE_TMP = ISNULL(Desc_Area, '')
            FROM Areas WITH (NOLOCK)
            WHERE CONVERT(VARCHAR, Id_area) = @ID_AREA_SEL;
        END
    END
    ELSE
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" style="background-color:#f8fafc; cursor:not-allowed;"';
 
        IF @VDESC_ERROR = ''
        BEGIN
            SELECT @VID_AREA_TMP = ISNULL(MAX(Id_area), 0) + 1 FROM Areas WITH (NOLOCK);
            SET @VNOMBRE_TMP = '';
        END
    END;
 
    -- 3. Textos e Iconos dinámicos
    IF @VIN_EDIT = 1
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Editar Área';
        SET @VDYNAMIC_TAB_ICON  = 'pen-line';
        SET @VFORM_TITLE        = 'Editar Área';
        SET @VFORM_SUBTITLE     = 'Modifique los datos del área seleccionada.';
        SET @VSUBMIT_LABEL      = 'Guardar cambios';
        SET @VFORM_ICON         = 'pen-line';
    END
    ELSE
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Nueva Área';
        SET @VDYNAMIC_TAB_ICON  = 'plus';
        SET @VFORM_TITLE        = 'Nueva Área';
        SET @VFORM_SUBTITLE     = 'Complete los datos para registrar una nueva área.';
        SET @VSUBMIT_LABEL      = 'Crear Área';
        SET @VFORM_ICON         = 'plus';
    END;
 
    -- 4. Escapar HTML / JS
    SET @ID_AREA_SEL = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ID_AREA_SEL, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VNOMBRE_TMP = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VNOMBRE_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    DECLARE @VDESC_ERROR_JS NVARCHAR(MAX) = ISNULL(@VDESC_ERROR, '');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '\', '\\');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '''', '\''');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '"', '\"');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, CHAR(13), ' ');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, CHAR(10), ' ');
 
    -- 5. Handler del Botón "Nueva Área"
    DECLARE @VONCLICK_NUEVO VARCHAR(MAX) = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_USER_SEL'','''');almacenarSeleccion(''ID_SECTOR_SEL'','''');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Gestión de Áreas',
         @SUBTITLE            = 'Administre las áreas funcionales de la organización',
         @MODULE_ICON         = 'chart-area',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Áreas',
         @DEFAULT_TAB_ICON    = 'chart-area',
         @DYNAMIC_TAB_ID      = 'form',
         @DYNAMIC_TAB_TITLE   = @VDYNAMIC_TAB_TITLE,
         @DYNAMIC_TAB_ICON    = @VDYNAMIC_TAB_ICON,
         @SHOW_ACTION_BUTTON = 1,
         @ACTION_BUTTON_TEXT = 'Nueva Área',
         @ACTION_BUTTON_ICON = 'plus',
         @ACTION_TARGET_TAB  = 'form',
         @ACTION_MODE        = '',
         @ACTION_ONCLICK     = @VONCLICK_NUEVO,
         @HTML               = @VHTML_HEADER OUTPUT;
 
    SET @VHTML_HEADER = ISNULL(@VHTML_HEADER, '');
 
    IF @VACTIVE_TAB = 'form'
    BEGIN
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-tab is-active" data-vct-tab="grid"', 'class="vct-tab" data-vct-tab="grid"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab hidden', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
    END
 
    -- 6. Configuración de Acciones JSON para la Grilla (Activa el lápiz y el borrado)
    DECLARE @ActionsJsonModule VARCHAR(MAX) =
    '[
        {
            "type": "edit",
            "title": "Editar Área",
            "icon": "pen-line",
            "keyField": "Id_area",
            "targetGuid": "62DE8169-4D9E-4A7F-98DD-412AE6DFC080",
            "storageKey": "ID_USER_SEL",
            "actionParam": "EDIT_AREA"
        },
        {
            "type": "delete",
            "title": "Eliminar Área",
            "icon": "trash-2",
            "keyField": "Id_area",
            "targetGuid": "E47723C4-7340-4168-AE4D-FDE4A65E7271",
            "storageKey": "ID_DELETE",
            "actionParam": "DELETE_AREA"
        }
    ]';
 
    DECLARE @AttrActionsModule VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ActionsJsonModule, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    -- 7. Título VCT con Atributos de Edición
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
 
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="' + ISNULL(@VACTIVE_TAB, 'grid') + '"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"' +
        ' data-vct-primary-field="Id_area"' +
        ' data-vct-actions="' + @AttrActionsModule + '"' +
        ' data-vct-edit-mode="server"' +
        ' data-vct-edit-storage-key="ID_USER_SEL"' +
        ' data-vct-edit-guid="62DE8169-4D9E-4A7F-98DD-412AE6DFC080"' +
        ' data-vct-edit-tab="form"' +
        ' data-vct-initial-mode="' + CASE WHEN @VIN_EDIT = 1 THEN 'edit' ELSE 'new' END + '"' +
        ' data-vct-mode-new="{&quot;tabTitle&quot;:&quot;Nueva Área&quot;,&quot;tabIcon&quot;:&quot;plus&quot;,&quot;title&quot;:&quot;Nueva Área&quot;,&quot;subtitle&quot;:&quot;Complete los datos para registrar una nueva área.&quot;,&quot;icon&quot;:&quot;plus&quot;,&quot;submit&quot;:&quot;Crear Área&quot;}"' +
        ' data-vct-mode-edit="{&quot;tabTitle&quot;:&quot;Editar Área&quot;,&quot;tabIcon&quot;:&quot;pen-line&quot;,&quot;title&quot;:&quot;Editar Área&quot;,&quot;subtitle&quot;:&quot;Modifique los datos del área seleccionada.&quot;,&quot;icon&quot;:&quot;pen-line&quot;,&quot;submit&quot;:&quot;Guardar cambios&quot;}">' +
        @VHTML_HEADER
    AS VARCHAR(MAX));
 
    -- 8. Formulario y Paneles VCT
    SET @PS_FORMULARIO = CAST(
        '<div class="vct-panels">' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'is-active' ELSE '' END + '" data-vct-panel="grid" ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
                '<div class="vct-grid-host" data-vct-grid-host></div>' +
            '</div>' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'is-active' ELSE '' END + '" data-vct-panel="form" ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
 
                '<div class="vct-form-card">' +
                    '<div class="vct-form-header">' +
                        '<div class="vct-form-icon" data-vct-form-icon>' +
                            '<i data-lucide="' + ISNULL(@VFORM_ICON, 'plus') + '"></i>' +
                        '</div>' +
                        '<div>' +
                            '<h3 class="vct-form-title" data-vct-form-title>' + ISNULL(@VFORM_TITLE, 'Nueva Área') + '</h3>' +
                            '<p class="vct-form-subtitle" data-vct-form-subtitle>' + ISNULL(@VFORM_SUBTITLE, '') + '</p>' +
                        '</div>' +
                    '</div>' +
 
                    '<div class="vct-form-body">' +
 
                        '<input type="hidden"' +
                        ' id="ID_USER_SEL"' +
                        ' name="SP.ID_USER_SEL"' +
                        ' value="' + ISNULL(@ID_AREA_SEL, '') + '"' +
                        ' data-vct-selected-key />' +
 
                        '<input type="hidden"' +
                        ' id="VCT_FORM_MODE"' +
                        ' data-vct-form-mode' +
                        ' value="' + CASE WHEN @VIN_EDIT = 1 THEN 'EDIT' ELSE 'NEW' END + '" />' +
 
                        '<div class="vct-form-grid">' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctAreaCode">' +
                                    '<i data-lucide="key"></i>' +
                                    '<span>ID Área</span>' +
                                    '<span class="vct-required"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctAreaCode"' +
                                ' name="SP.NEW_ID"' +
                                ' value="' + CASE WHEN @VIN_EDIT = 1 THEN ISNULL(@ID_AREA_SEL, '') ELSE CONVERT(VARCHAR, @VID_AREA_TMP) END + '"' +
                                ' data-vct-field="Id_area"' +
                                ' data-vct-primary-input' +
                                ISNULL(@VREADONLY_ATTR, '') + ' />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctAreaDesc">' +
                                    '<i data-lucide="type"></i>' +
                                    '<span>Descripción</span>' +
                                    '<span class="vct-required"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctAreaDesc"' +
                                ' name="SP.NEW_NAME"' +
                                ' value="' + ISNULL(@VNOMBRE_TMP, '') + '"' +
                                ' placeholder="Ingrese la descripción del área"' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Descripcion" />' +
                            '</div>' +
 
                        '</div>' +
 
                        '<div class="vct-form-actions">' +
                            '<button type="button"' +
                            ' class="vct-button vct-button-secondary"' +
                            ' data-vct-close-tab="form"' +
                            ' data-vct-fallback-tab="grid"' +
                            ' data-vct-reset-on-close>' +
                                '<i data-lucide="x"></i>' +
                                '<span>Cancelar</span>' +
                            '</button>' +
 
                            '<button type="button"' +
                            ' class="vct-button vct-button-primary"' +
                            ' onclick="valFormArea(); return false;"' +
                            ' style="display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 0 20px; height: 42px;">' +
                                '<i data-lucide="save"></i>' +
                                '<span class="vct-button-text" style="display: inline-block; font-weight: 600;">' + ISNULL(@VSUBMIT_LABEL, 'Crear Área') + '</span>' +
                            '</button>' +
                        '</div>' +
 
                    '</div>' +
                '</div>' +
 
            '</div>' +
 
        '</div>' +
 
        '<script src="../js/vct-Core.js?v=5.4.1"></script>' +
        '<script src="../js/vct-Tabs.js?v=5.4.1"></script>' +
        '<script src="../js/vct-Table.js?v=5.4.1"></script>' +
        '<script src="../js/vct-modal.js?v=5.4.1"></script>' +
 
        '<script type="text/javascript">
        (function(){
            function initVctAreaModule(){
                var module = document.querySelector("[data-vct-tabs]");
                if(!module){ return; }
 
                var targetTab = "' + ISNULL(@VACTIVE_TAB, 'grid') + '";
                if(window.VctTabs && typeof window.VctTabs.activate === "function"){
                    var tabBtn = module.querySelector(''[data-vct-tab="'' + targetTab + ''"]'');
                    if(tabBtn){
                        tabBtn.hidden = false;
                        tabBtn.removeAttribute("hidden");
                    }
                    window.VctTabs.activate(module, targetTab);
                }
 
                if(window.lucide && typeof window.lucide.createIcons === "function"){
                    window.lucide.createIcons();
                }
 
                var errMessage = "' + ISNULL(@VDESC_ERROR_JS, '') + '";
                if(errMessage !== ""){
                    setTimeout(function(){
                        if(window.VCTModal && typeof window.VCTModal.alert === "function"){
                            window.VCTModal.alert({
                                title: "Error de Validación",
                                text: errMessage
                            });
                        } else {
                            alert(errMessage);
                        }
                    }, 100);
                }
            }
 
            function valFormArea() {
                var desc = document.getElementsByName("SP.NEW_NAME")[0];
                if (!desc || !desc.value || !desc.value.trim()) {
                    if (window.VCTModal && typeof window.VCTModal.alert === "function") {
                        window.VCTModal.alert({ title: "Atención", text: "Debe ingresar la descripción del área." });
                    } else {
                        alert("Debe ingresar la descripción del área");
                    }
                    return;
                }
                var userSel = document.getElementsByName("SP.ID_USER_SEL")[0];
                if(userSel && typeof almacenarSeleccion === "function") {
                    almacenarSeleccion("ID_USER_SEL", userSel.value);
                }
                goto("' + @VFORM_ID_CLEAN + '", "62DE8169-4D9E-4A7F-98DD-412AE6DFC080");
            }
            window.valFormArea = valFormArea;
 
            if(document.readyState === "loading"){
                document.addEventListener("DOMContentLoaded", initVctAreaModule);
            } else {
                initVctAreaModule();
            }
        })();
        </script>'
    AS VARCHAR(MAX));
 
END
