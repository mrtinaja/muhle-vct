 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_GROUPS]
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
        @ID_GROUP_SEL        VARCHAR(100)  = '',
        @VACTION             VARCHAR(100)  = '',
        @VNOMBRE_TMP          NVARCHAR(200) = '',
        @VDESC_ERROR          NVARCHAR(MAX) = '',
        @VHTML_HEADER         VARCHAR(MAX)  = '',
        @VREADONLY_ATTR       VARCHAR(300)  = '',
        @VIN_EDIT             BIT           = 0,
        @VACTIVE_TAB          VARCHAR(20)   = 'grid',
        @VDYNAMIC_TAB_TITLE   VARCHAR(100)  = '',
        @VDYNAMIC_TAB_ICON    VARCHAR(100)  = '',
        @VFORM_TITLE          VARCHAR(150)  = '',
        @VFORM_SUBTITLE       VARCHAR(300)  = '',
        @VSUBMIT_LABEL        VARCHAR(100)  = '',
        @VFORM_ICON           VARCHAR(100)  = '';
 
    -- 1. LEER ID_GROUP_SEL Y ACTION DE M_CONFIG
    SELECT TOP 1
        @ID_GROUP_SEL = ISNULL(NULLIF(LTRIM(RTRIM(REPLACE(ID_GROUP_SEL, ',', ''))), ''), ''),
        @VACTION      = ISNULL(LTRIM(RTRIM([ACTION])), ''),
        @VNOMBRE_TMP  = ISNULL(NEW_NAME, ''),
        @VDESC_ERROR  = ISNULL(DESC_ERROR, '')
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_GROUP_SEL = ISNULL(@ID_GROUP_SEL, '');
    SET @VACTION      = ISNULL(@VACTION, '');
 
    -- 💡 2. RUTEADOR DE SUB-MÓDULOS
    IF @VACTION = 'VER_USUARIOS'
    BEGIN
        EXEC dbo.M_CONFIG_GROUP_USERS 
             @IPKEYJOB = @IPKEYJOB, 
             @IUSERID  = @IUSERID, 
             @FORM_ID  = @FORM_ID;
        RETURN;
    END
 
    -- 3. RUTA POR DEFECTO: GESTIÓN DE PERFILES
    SET @VDESC_ERROR = LTRIM(RTRIM(ISNULL(@VDESC_ERROR, '')));
    SET @VIN_EDIT = CASE WHEN @ID_GROUP_SEL <> '' THEN 1 ELSE 0 END;
 
    IF @VDESC_ERROR <> '' SET @VACTIVE_TAB = 'form';
 
    IF @VIN_EDIT = 1
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" aria-readonly="true" style="background-color:#f8fafc;cursor:not-allowed;"';
        IF @VDESC_ERROR = ''
        BEGIN
            SELECT TOP 1 @VNOMBRE_TMP = ISNULL(g.Name, '')
            FROM Groups g WITH (NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(g.Id))) = UPPER(@ID_GROUP_SEL);
        END
    END
    ELSE
    BEGIN
        SET @VREADONLY_ATTR = '';
        IF @VDESC_ERROR = '' SET @VNOMBRE_TMP = '';
    END;
 
    IF @VIN_EDIT = 1
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Editar perfil';
        SET @VDYNAMIC_TAB_ICON  = 'shield-check';
        SET @VFORM_TITLE        = 'Editar perfil';
        SET @VFORM_SUBTITLE     = 'Modifique los datos del perfil seleccionado.';
        SET @VSUBMIT_LABEL      = 'Guardar cambios';
        SET @VFORM_ICON         = 'shield-check';
    END
    ELSE
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Nuevo perfil';
        SET @VDYNAMIC_TAB_ICON  = 'plus-circle';
        SET @VFORM_TITLE        = 'Nuevo perfil';
        SET @VFORM_SUBTITLE     = 'Complete los datos del nuevo perfil.';
        SET @VSUBMIT_LABEL      = 'Crear perfil';
        SET @VFORM_ICON         = 'shield-plus';
    END;
 
    SET @ID_GROUP_SEL = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ID_GROUP_SEL, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VNOMBRE_TMP  = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VNOMBRE_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    DECLARE @VONCLICK VARCHAR(MAX) = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_GROUP_SEL'','''');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Gestión de Perfiles',
         @SUBTITLE            = 'Administre los perfiles y permisos del sistema',
         @MODULE_ICON         = 'shield-check',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Perfiles',
         @DEFAULT_TAB_ICON    = 'shield',
         @DYNAMIC_TAB_ID      = 'form',
         @DYNAMIC_TAB_TITLE   = @VDYNAMIC_TAB_TITLE,
         @DYNAMIC_TAB_ICON    = @VDYNAMIC_TAB_ICON,
         @SHOW_ACTION_BUTTON = 1,
         @ACTION_BUTTON_TEXT = 'Nuevo',
         @ACTION_BUTTON_ICON = 'plus-circle',
         @ACTION_TARGET_TAB  = 'form',
         @ACTION_MODE        = '',
         @ACTION_ONCLICK     = @VONCLICK,
         @HTML               = @VHTML_HEADER OUTPUT;
 
    SET @VHTML_HEADER = ISNULL(@VHTML_HEADER, '');
 
    IF @VACTIVE_TAB = 'form'
    BEGIN
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-tab is-active" data-vct-tab="grid"', 'class="vct-tab" data-vct-tab="grid"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab hidden', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
    END;
 
    DECLARE @ActionsJsonModule VARCHAR(MAX) = ''
    /*'[
        {
            "type": "edit",
            "title": "Editar perfil",
            "icon": "pen-line",
            "keyField": "Perfil",
            "targetTab": "form"
        },
        {
            "type": "custom",
            "title": "Usuarios asociados",
            "icon": "users",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "3936E80A-5D88-4201-A10F-B7E7D9BAFCD6",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_USUARIOS"
        },
        {
            "type": "custom",
            "title": "Módulos asociados",
            "icon": "boxes",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "4489F5AB-1DFC-40FD-A3BC-B74DA1254733",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_TAREAS"
        },
        {
            "type": "custom",
            "title": "Permisos asociados",
            "icon": "navigation",
            "isSecondary": true,
            "keyField": "Perfil",
            "targetGuid": "6C5AC979-DFE2-4F60-8553-D027D20E3D81",
            "storageKey": "ID_GROUP_SEL",
            "actionParam": "VER_ACCIONES"
        }
    ]';
    */
    DECLARE @AttrActionsModule VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ActionsJsonModule, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    
 
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
        ' data-vct-primary-field="Perfil"' +
        ' data-vct-edit-mode="client"' +
        ' data-vct-edit-storage-key="ID_GROUP_SEL"' +
        ' data-vct-edit-tab="form"' +
        ' data-vct-actions="' + @AttrActionsModule + '"' +
        ' data-vct-initial-mode="' + CASE WHEN @VIN_EDIT = 1 THEN 'edit' ELSE 'new' END + '"' +
        ' data-vct-mode-new="{&quot;tabTitle&quot;:&quot;Nuevo perfil&quot;,&quot;tabIcon&quot;:&quot;plus-circle&quot;,&quot;title&quot;:&quot;Nuevo perfil&quot;,&quot;subtitle&quot;:&quot;Complete los datos del nuevo perfil.&quot;,&quot;icon&quot;:&quot;shield-plus&quot;,&quot;submit&quot;:&quot;Crear perfil&quot;}"' +
        ' data-vct-mode-edit="{&quot;tabTitle&quot;:&quot;Editar perfil&quot;,&quot;tabIcon&quot;:&quot;shield-check&quot;,&quot;title&quot;:&quot;Editar perfil&quot;,&quot;subtitle&quot;:&quot;Modifique los datos del perfil seleccionado.&quot;,&quot;icon&quot;:&quot;shield-check&quot;,&quot;submit&quot;:&quot;Guardar cambios&quot;}">' +
        @VHTML_HEADER
    AS VARCHAR(MAX));
 
    SET @PS_FORMULARIO = CAST(
        '<div class="vct-panels">' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'is-active' ELSE '' END + '" data-vct-panel="grid" ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
                '<div class="vct-grid-host" data-vct-grid-host></div>' +
            '</div>' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'is-active' ELSE '' END + '" data-vct-panel="form" ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
 
                '<div class="vct-form-card">' +
                    '<div class="vct-form-header">' +
                        '<div class="vct-form-icon" data-vct-form-icon>' +
                            '<i data-lucide="' + ISNULL(@VFORM_ICON, 'shield-plus') + '"></i>' +
                        '</div>' +
                        '<div>' +
                            '<h3 class="vct-form-title" data-vct-form-title>' + ISNULL(@VFORM_TITLE, 'Nuevo perfil') + '</h3>' +
                            '<p class="vct-form-subtitle" data-vct-form-subtitle>' + ISNULL(@VFORM_SUBTITLE, '') + '</p>' +
                        '</div>' +
                    '</div>' +
 
                    '<div class="vct-form-body">' +
 
                        '<input type="hidden"' +
                        ' id="ID_GROUP_SEL"' +
                        ' name="SP.ID_GROUP_SEL"' +
                        ' value="' + ISNULL(@ID_GROUP_SEL, '') + '"' +
                        ' data-vct-selected-key />' +
 
                        '<input type="hidden"' +
                        ' id="VCT_FORM_MODE"' +
                        ' data-vct-form-mode' +
                        ' value="' + CASE WHEN @VIN_EDIT = 1 THEN 'EDIT' ELSE 'NEW' END + '" />' +
 
                        '<div class="vct-form-grid">' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctGroupCode">' +
                                    '<i data-lucide="key"></i>' +
                                    '<span>Código / ID Perfil</span>' +
                                    '<span class="vct-required" id="idCampo1"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctGroupCode"' +
                                ' name="SP.NEW_ID"' +
                                ' value="' + ISNULL(@ID_GROUP_SEL, '') + '"' +
                                ' placeholder="ej. ADMIN, OPERACIONES..."' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Perfil"' +
                                ' data-vct-primary-input' +
                                ISNULL(@VREADONLY_ATTR, '') + ' />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctGroupName">' +
                                    '<i data-lucide="type"></i>' +
                                    '<span>Nombre del perfil</span>' +
                                    '<span class="vct-required" id="idCampo2"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctGroupName"' +
                                ' name="SP.NEW_NAME"' +
                                ' value="' + ISNULL(@VNOMBRE_TMP, '') + '"' +
                                ' placeholder="ej. Administradores del Sistema"' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Descripción" />' +
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
                            ' onclick="vctConfirmarGuardar(''' + ISNULL(@FORM_ID, '') + ''',2);return false;"' +
                            ' style="display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 0 20px; height: 42px;">' +
                                '<i data-lucide="save"></i>' +
                                '<span class="vct-button-text" style="display: inline-block; font-weight: 600;">' + ISNULL(@VSUBMIT_LABEL, 'Crear perfil') + '</span>' +
                            '</button>' +
                        '</div>' +
 
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +
 
        '<script src="../js/vct-Core.js"></script>' +
        '<script src="../js/vct-Tabs.js"></script>' +
        '<script src="../js/vct-Table.js"></script>' +
        '<script src="../js/vct-modal.js"></script>'
    AS VARCHAR(MAX));
 
    IF @VDESC_ERROR <> ''
    BEGIN
        UPDATE M_CONFIG 
        SET DESC_ERROR = NULL 
        WHERE PAR_KEY = @IPKEYJOB;
    END
 
END
