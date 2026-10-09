 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_USERS_BK_24/8]
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
        @ID_USER_SEL        VARCHAR(100)  = '',
        @VNEW_ID_TMP        VARCHAR(100)  = '',
        @VNOMBRE_TMP          NVARCHAR(200) = '',
        @VEMAIL_TMP           NVARCHAR(300) = '',
        @VPERFIL_TMP          VARCHAR(100)  = '',
        @VESTADO_TMP          VARCHAR(100)  = '',
        @VPASS_VALUE          VARCHAR(100)  = '',
        @VDESC_ERROR          NVARCHAR(MAX) = '',
        @VHTML_HEADER         VARCHAR(MAX)  = '',
        @VOPTIONS_PERFIL      VARCHAR(MAX)  = '',
        @VOPTIONS_ESTADO      VARCHAR(MAX)  = '',
        @VREADONLY_ATTR       VARCHAR(300)  = '',
        @VIN_EDIT             BIT           = 0,
        @VACTIVE_TAB          VARCHAR(20)   = 'grid',
        @VDYNAMIC_TAB_TITLE   VARCHAR(100)  = '',
        @VDYNAMIC_TAB_ICON    VARCHAR(100)  = '',
        @VFORM_TITLE          VARCHAR(150)  = '',
        @VFORM_SUBTITLE       VARCHAR(300)  = '',
        @VSUBMIT_LABEL        VARCHAR(100)  = '',
        @VFORM_ICON           VARCHAR(100)  = '',
        @VFORM_ID_CLEAN       VARCHAR(100)  = '';
 
    -----------------------------------------------------------------------------------------
    -- 1. RECUPERAR ESTADO DESDE M_CONFIG
    -----------------------------------------------------------------------------------------
    SELECT TOP 1
        @ID_USER_SEL = ISNULL(NULLIF(LTRIM(RTRIM(REPLACE(ID_USER_SEL, ',', ''))), ''), ''),
        @VNEW_ID_TMP = ISNULL(NEW_ID, ''),
        @VNOMBRE_TMP = ISNULL(NEW_NAME, ''),
        @VEMAIL_TMP  = ISNULL(NEW_EMAIL, ''),
        @VPERFIL_TMP = ISNULL(NULLIF(LTRIM(RTRIM(REPLACE(NEW_PERFIL, ',', ''))), ''), ''),
        @VESTADO_TMP = ISNULL(NEW_ESTADO_CUENTA, ''),
        @VDESC_ERROR = ISNULL(DESC_ERROR, '')
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_USER_SEL = LTRIM(RTRIM(ISNULL(@ID_USER_SEL, '')));
    SET @VDESC_ERROR = LTRIM(RTRIM(ISNULL(@VDESC_ERROR, '')));
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
 
    SET @VIN_EDIT = CASE WHEN @ID_USER_SEL <> '' THEN 1 ELSE 0 END;
 
    IF @VDESC_ERROR <> ''
    BEGIN
        SET @VACTIVE_TAB = 'form';
    END;
 
    -----------------------------------------------------------------------------------------
    -- 2. RECUPERACIÓN ROBUSTA DE DATOS (MODO EDICIÓN SERVIDOR)
    -----------------------------------------------------------------------------------------
    IF @VIN_EDIT = 1
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" aria-readonly="true" style="background-color:#f8fafc;cursor:not-allowed;"';
 
        IF @VDESC_ERROR = ''
        BEGIN
            SELECT TOP 1
                @VNOMBRE_TMP = ISNULL(NULLIF(@VNOMBRE_TMP, ''), ISNULL(u.Name, '')),
                @VEMAIL_TMP  = ISNULL(NULLIF(@VEMAIL_TMP, ''), ISNULL(u.Email, '')),
                @VESTADO_TMP = ISNULL(NULLIF(@VESTADO_TMP, ''), ISNULL(CONVERT(VARCHAR(20), u.State), '1')),
                @VPASS_VALUE = CASE WHEN ISNULL(u.[Password], '') <> '' THEN '••••••' ELSE '' END
            FROM Users u WITH (NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(u.Id))) = UPPER(@ID_USER_SEL);
 
            IF ISNULL(@VPERFIL_TMP, '') = ''
            BEGIN
                SELECT TOP 1 
                    @VPERFIL_TMP = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(100), GroupId), '')))
                FROM GroupsUserMembers WITH (NOLOCK)
                WHERE UPPER(LTRIM(RTRIM(UserMemberId))) = UPPER(@ID_USER_SEL);
            END;
        END;
 
        IF ISNULL(@VPERFIL_TMP, '') <> ''
        BEGIN
            SELECT TOP 1 
                @VPERFIL_TMP = LTRIM(RTRIM(CAST(Id AS VARCHAR(100))))
            FROM Groups WITH (NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(CAST(Id AS VARCHAR(100))))) = UPPER(LTRIM(RTRIM(@VPERFIL_TMP)))
               OR UPPER(LTRIM(RTRIM(Name))) = UPPER(LTRIM(RTRIM(@VPERFIL_TMP)));
        END;
    END
    ELSE
    BEGIN
        SET @VREADONLY_ATTR = '';
 
        IF @VDESC_ERROR = ''
        BEGIN
            SET @VNEW_ID_TMP = '';
            SET @VNOMBRE_TMP = '';
            SET @VEMAIL_TMP  = '';
            SET @VPERFIL_TMP = '';
            SET @VESTADO_TMP = '1';
            SET @VPASS_VALUE = '';
        END
    END;
 
    -----------------------------------------------------------------------------------------
    -- 3. TEXTOS E ICONOS
    -----------------------------------------------------------------------------------------
    IF @VIN_EDIT = 1
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Editar usuario';
        SET @VDYNAMIC_TAB_ICON  = 'user-pen';
        SET @VFORM_TITLE        = 'Editar usuario';
        SET @VFORM_SUBTITLE     = 'Modifique los datos del usuario seleccionado.';
        SET @VSUBMIT_LABEL      = 'Guardar cambios';
        SET @VFORM_ICON         = 'user-pen';
    END
    ELSE
    BEGIN
        SET @VDYNAMIC_TAB_TITLE = 'Nuevo usuario';
        SET @VDYNAMIC_TAB_ICON  = 'user-plus';
        SET @VFORM_TITLE        = 'Nuevo usuario';
        SET @VFORM_SUBTITLE     = 'Complete los datos del nuevo usuario.';
        SET @VSUBMIT_LABEL      = 'Crear usuario';
        SET @VFORM_ICON         = 'user-plus';
    END;
 
    SET @VESTADO_TMP = LTRIM(RTRIM(ISNULL(@VESTADO_TMP, '1')));
    IF @VESTADO_TMP IN ('Activa', '1', 'TRUE', 'True') SET @VESTADO_TMP = '1';
    ELSE IF @VESTADO_TMP IN ('No Activa', '0', 'FALSE', 'False') SET @VESTADO_TMP = '0';
    ELSE SET @VESTADO_TMP = '1';
 
    -----------------------------------------------------------------------------------------
    -- 4. ESCAPAR HTML Y JS
    -----------------------------------------------------------------------------------------
    SET @ID_USER_SEL = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ID_USER_SEL, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VNEW_ID_TMP = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VNEW_ID_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VNOMBRE_TMP = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VNOMBRE_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VEMAIL_TMP  = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VEMAIL_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VPERFIL_TMP = LTRIM(RTRIM(ISNULL(@VPERFIL_TMP, '')));
 
    DECLARE @VDESC_ERROR_JS NVARCHAR(MAX) = ISNULL(@VDESC_ERROR, '');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '\', '\\');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '''', '\''');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, '"', '\"');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, CHAR(13), ' ');
    SET @VDESC_ERROR_JS = REPLACE(@VDESC_ERROR_JS, CHAR(10), ' ');
 
    -----------------------------------------------------------------------------------------
    -- 5. CURSOR SQL: OPCIONES DE PERFIL
    -----------------------------------------------------------------------------------------
    SET @VOPTIONS_PERFIL = '<option value=""' + CASE WHEN ISNULL(@VPERFIL_TMP, '') = '' THEN ' selected="selected"' ELSE '' END + '>Seleccione perfil...</option>';
 
    DECLARE @g_id VARCHAR(100), @g_name VARCHAR(200);
    DECLARE curG CURSOR LOCAL FAST_FORWARD FOR 
        SELECT CAST(Id AS VARCHAR(100)), ISNULL(Name, '') 
        FROM Groups WITH (NOLOCK) 
        WHERE Id <> 'SQUAD' 
        ORDER BY Name;
 
    OPEN curG;
    FETCH NEXT FROM curG INTO @g_id, @g_name;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @is_selected_perfil BIT = 0;
 
        DECLARE @v_perfil_norm VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@VPERFIL_TMP, ''))));
        SET @v_perfil_norm = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@v_perfil_norm, 'Á', 'A'), 'É', 'E'), 'Í', 'I'), 'Ó', 'O'), 'Ú', 'U');
 
        DECLARE @g_name_norm VARCHAR(200) = UPPER(LTRIM(RTRIM(@g_name)));
        SET @g_name_norm = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@g_name_norm, 'Á', 'A'), 'É', 'E'), 'Í', 'I'), 'Ó', 'O'), 'Ú', 'U');
 
        IF @v_perfil_norm <> '' AND (UPPER(LTRIM(RTRIM(@g_id))) = @v_perfil_norm OR @g_name_norm = @v_perfil_norm)
        BEGIN
            SET @is_selected_perfil = 1;
        END
 
        SET @VOPTIONS_PERFIL = @VOPTIONS_PERFIL + 
            '<option value="' + REPLACE(@g_id, '"', '&quot;') + '"' + 
            CASE WHEN @is_selected_perfil = 1 THEN ' selected="selected"' ELSE '' END + '>' + 
            REPLACE(@g_name, '<', '&lt;') + '</option>';
 
        FETCH NEXT FROM curG INTO @g_id, @g_name;
    END;
 
    CLOSE curG;
    DEALLOCATE curG;
 
    -----------------------------------------------------------------------------------------
    -- 5.B. OPCIONES DE ESTADO EN SQL
    -----------------------------------------------------------------------------------------
    SET @VOPTIONS_ESTADO = '<option value=""' + CASE WHEN @VESTADO_TMP NOT IN ('1','0') THEN ' selected="selected"' ELSE '' END + '>Seleccione estado...</option>' +
        '<option value="1"' + CASE WHEN @VESTADO_TMP = '1' THEN ' selected="selected"' ELSE '' END + '>Activa</option>' +
        '<option value="0"' + CASE WHEN @VESTADO_TMP = '0' THEN ' selected="selected"' ELSE '' END + '>No Activa</option>';
 
    -----------------------------------------------------------------------------------------
    -- 6. HEADER
    -----------------------------------------------------------------------------------------
    DECLARE @VONCLICK VARCHAR(MAX) = 'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_USER_SEL'','''');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE               = 'Gestión de Usuarios',
         @SUBTITLE            = 'Administre los usuarios del sistema',
         @MODULE_ICON         = 'users',
         @DEFAULT_TAB_ID      = 'grid',
         @DEFAULT_TAB_TITLE   = 'Usuarios',
         @DEFAULT_TAB_ICON    = 'users',
         @DYNAMIC_TAB_ID      = 'form',
         @DYNAMIC_TAB_TITLE   = @VDYNAMIC_TAB_TITLE,
         @DYNAMIC_TAB_ICON    = @VDYNAMIC_TAB_ICON,
         @SHOW_ACTION_BUTTON = 1,
         @ACTION_BUTTON_TEXT = 'Nuevo',
         @ACTION_BUTTON_ICON = 'user-plus',
         @ACTION_TARGET_TAB  = 'form',
         @ACTION_MODE        = '',
         @ACTION_ONCLICK     = @VONCLICK,
         @HTML               = @VHTML_HEADER OUTPUT;
 
    SET @VHTML_HEADER = ISNULL(@VHTML_HEADER, '');
 
    IF @VACTIVE_TAB = 'form'
    BEGIN
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'class="vct-tab is-active" data-vct-tab="grid"', 'class="vct-tab" data-vct-tab="grid"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab hidden', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
        SET @VHTML_HEADER = REPLACE(@VHTML_HEADER, 'data-vct-tab="form" data-vct-dynamic-tab', 'data-vct-tab="form" data-vct-dynamic-tab class="vct-tab is-active"');
    END;
 
    -- CSS Nativo con Flecha Bordó
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
 
        '<style>' +
            '.vct-select-input {' +
                'width: 100% !important;' +
                'height: 40px !important;' +
                'min-height: 40px !important;' +
                'padding: 0 36px 0 14px !important;' +
                'font-size: 13px !important;' +
                'font-weight: 500 !important;' +
                'color: #0f172a !important;' +
                'background-color: #ffffff !important;' +
                'background-image: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2366062D%22 stroke-width=%222.5%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22m6 9 6 6 6-6%22/%3E%3C/svg%3E") !important;' +
                'background-repeat: no-repeat !important;' +
                'background-position: right 12px center !important;' +
                'border: 1px solid #cbd5e1 !important;' +
                'border-radius: 8px !important;' +
                'box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04) !important;' +
                'appearance: none !important;' +
                '-webkit-appearance: none !important;' +
                '-moz-appearance: none !important;' +
                'outline: none !important;' +
                'cursor: pointer !important;' +
                'display: block !important;' +
            '}' +
            '.vct-select-input:focus {' +
                'border-color: #66062D !important;' +
                'box-shadow: 0 0 0 3px rgba(102, 6, 45, 0.12) !important;' +
            '}' +
        '</style>' +
 
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="' + ISNULL(@VACTIVE_TAB, 'grid') + '"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"' +
        ' data-vct-primary-field="Usuario"' +
        ' data-vct-edit-mode="server"' +
        ' data-vct-edit-storage-key="ID_USER_SEL"' +
        ' data-vct-edit-guid="9911B4B4-A00E-40D8-B148-A92469C268CC"' +
        ' data-vct-edit-tab="form"' +
        ' data-vct-initial-mode="' + CASE WHEN @VIN_EDIT = 1 THEN 'edit' ELSE 'new' END + '"' +
        ' data-vct-mode-new="{&quot;tabTitle&quot;:&quot;Nuevo usuario&quot;,&quot;tabIcon&quot;:&quot;user-plus&quot;,&quot;title&quot;:&quot;Nuevo usuario&quot;,&quot;subtitle&quot;:&quot;Complete los datos del nuevo usuario.&quot;,&quot;icon&quot;:&quot;user-plus&quot;,&quot;submit&quot;:&quot;Crear usuario&quot;}"' +
        ' data-vct-mode-edit="{&quot;tabTitle&quot;:&quot;Editar usuario&quot;,&quot;tabIcon&quot;:&quot;user-pen&quot;,&quot;title&quot;:&quot;Editar usuario&quot;,&quot;subtitle&quot;:&quot;Modifique los datos del usuario seleccionado.&quot;,&quot;icon&quot;:&quot;user-pen&quot;,&quot;submit&quot;:&quot;Guardar cambios&quot;}">' +
        @VHTML_HEADER
    AS VARCHAR(MAX));
 
    -----------------------------------------------------------------------------------------
    -- 7. FORMULARIO HTML Y PANELES (MAPEO CLIENTE + CURSOR SERVIDOR)
    -----------------------------------------------------------------------------------------
    SET @PS_FORMULARIO = CAST(
        '<div class="vct-panels">' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'is-active' ELSE '' END + '" data-vct-panel="grid" ' + CASE WHEN @VACTIVE_TAB = 'grid' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
                '<div class="vct-grid-host" data-vct-grid-host></div>' +
            '</div>' +
 
            '<div class="vct-panel ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'is-active' ELSE '' END + '" data-vct-panel="form" ' + CASE WHEN @VACTIVE_TAB = 'form' THEN 'aria-hidden="false"' ELSE 'hidden aria-hidden="true"' END + '>' +
 
                '<div class="vct-form-card">' +
                    '<div class="vct-form-header">' +
                        '<div class="vct-form-icon" data-vct-form-icon>' +
                            '<i data-lucide="' + ISNULL(@VFORM_ICON, 'user-plus') + '"></i>' +
                        '</div>' +
                        '<div>' +
                            '<h3 class="vct-form-title" data-vct-form-title>' + ISNULL(@VFORM_TITLE, 'Nuevo usuario') + '</h3>' +
                            '<p class="vct-form-subtitle" data-vct-form-subtitle>' + ISNULL(@VFORM_SUBTITLE, '') + '</p>' +
                        '</div>' +
                    '</div>' +
 
                    '<div class="vct-form-body">' +
 
                        '<input type="hidden"' +
                        ' id="ID_USER_SEL"' +
                        ' name="SP.ID_USER_SEL"' +
                        ' value="' + ISNULL(@ID_USER_SEL, '') + '"' +
                        ' data-vct-selected-key />' +
 
                        '<input type="hidden"' +
                        ' id="VCT_FORM_MODE"' +
                        ' data-vct-form-mode' +
                        ' value="' + CASE WHEN @VIN_EDIT = 1 THEN 'EDIT' ELSE 'NEW' END + '" />' +
 
                        '<div class="vct-form-grid">' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctUserCode">' +
                                    '<i data-lucide="id-card"></i>' +
                                    '<span>Usuario</span>' +
                                    '<span class="vct-required" id="idCampo1"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctUserCode"' +
                                ' name="SP.NEW_ID"' +
                                ' value="' + CASE WHEN @VIN_EDIT = 1 THEN ISNULL(@ID_USER_SEL, '') ELSE ISNULL(@VNEW_ID_TMP, '') END + '"' +
                                ' placeholder="ej. jperez"' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Usuario"' +
                                ' data-vct-primary-input' +
                                ISNULL(@VREADONLY_ATTR, '') + ' />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctUserName">' +
                                    '<i data-lucide="type"></i>' +
                                    '<span>Nombre y Apellido</span>' +
                                    '<span class="vct-required" id="idCampo2"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctUserName"' +
                                ' name="SP.NEW_NAME"' +
                                ' value="' + ISNULL(@VNOMBRE_TMP, '') + '"' +
                                ' placeholder="ej. Juan Pérez"' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Descripcion"' +
                                ' data-vct-field-alt="Nombre y Apellido" />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctUserEmail">' +
                                    '<i data-lucide="mail"></i>' +
                                    '<span>Email</span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="email"' +
                                ' id="vctUserEmail"' +
                                ' name="SP.NEW_EMAIL"' +
                                ' value="' + ISNULL(@VEMAIL_TMP, '') + '"' +
                                ' placeholder="jperez@empresa.com"' +
                                ' autocomplete="off"' +
                                ' data-vct-field="Email" />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full" data-vct-optional-on-edit>' +
                                '<label for="vctUserPassword">' +
                                    '<i data-lucide="key-round"></i>' +
                                    '<span>Contraseña</span>' +
                                    '<span class="vct-required" id="idCampo4"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="password"' +
                                ' id="vctUserPassword"' +
                                ' name="SP.NEW_PASSWORD"' +
                                ' value="' + ISNULL(@VPASS_VALUE, '') + '"' +
                                ' placeholder="' + CASE WHEN @VIN_EDIT = 1
                                    THEN 'Dejar en blanco para conservar la contraseña actual'
                                    ELSE 'Ingrese una contraseña' END + '"' +
                                ' autocomplete="new-password"' +
                                ' data-vct-field="PASSWORD"' +
                                ' data-vct-optional-on-edit />' +
                            '</div>' +
 
                            '<div class="vct-form-group">' +
                                '<label for="vctUserProfile">' +
                                    '<i data-lucide="shield"></i>' +
                                    '<span>Perfil / Grupo</span>' +
                                    '<span class="vct-required" id="idCampo5"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<select class="vct-select-input"' +
                                ' id="vctUserProfile"' +
                                ' name="SP.NEW_PERFIL"' +
                                ' data-vct-field="CodigoPerfil"' +
                                ' data-vct-field-alt="Perfil">' +
                                    ISNULL(@VOPTIONS_PERFIL, '') +
                                '</select>' +
                            '</div>' +
 
                            '<div class="vct-form-group">' +
                                '<label for="vctUserState">' +
                                    '<i data-lucide="toggle-left"></i>' +
                                    '<span>Estado</span>' +
                                    '<span class="vct-required" id="idCampo6"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<select class="vct-select-input"' +
                                ' id="vctUserState"' +
                                ' name="SP.NEW_ESTADO_CUENTA"' +
                                ' data-vct-field="CodigoEstado"' +
                                ' data-vct-field-alt="Estado">' +
                                    ISNULL(@VOPTIONS_ESTADO, '') +
                                '</select>' +
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
                            ' onclick="vctConfirmarGuardar(''' + ISNULL(@VFORM_ID_CLEAN, '') + ''',6);return false;"' +
                            ' style="display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 0 20px; height: 42px;">' +
                                '<i data-lucide="save"></i>' +
                                '<span class="vct-button-text" style="display: inline-block; font-weight: 600;">' + ISNULL(@VSUBMIT_LABEL, 'Crear usuario') + '</span>' +
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
 
    -----------------------------------------------------------------------------------------
    -- 8. LIMPIEZA DE ERRORES EN M_CONFIG
    -----------------------------------------------------------------------------------------
    IF @VDESC_ERROR <> ''
    BEGIN
        UPDATE M_CONFIG 
        SET DESC_ERROR = NULL 
        WHERE PAR_KEY = @IPKEYJOB;
    END
 
END
