 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_USERS_bk]
(
    @IPKEYJOB          VARCHAR(100),
    @IUSERID            VARCHAR(100),
    @FORM_ID           VARCHAR(100),
    @PS_TITULO         VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO     VARCHAR(MAX) OUTPUT
)
AS
BEGIN
 
    SET NOCOUNT ON;
 
    DECLARE
        @VACTION        VARCHAR(50),
        @ID_USER_SEL    VARCHAR(100),
        @VNOMBRE_TMP    NVARCHAR(200),
        @VEMAIL_TMP     NVARCHAR(300),
        @VPERFIL_TMP    VARCHAR(100),
        @VESTADO_TMP    VARCHAR(100),
        @VHTML_HEADER   VARCHAR(MAX),
        @VREADONLY_ATTR VARCHAR(200) = ''
 
    DECLARE @VOPTIONS_PERFIL VARCHAR(MAX) = ''
 
    -------------------------------------------------------
    -- 1. RECUPERAR DATOS DE M_CONFIG Y FORZAR LIMPIEZA EN ALTA
    -------------------------------------------------------
 
    SELECT
        @VACTION      = ISNULL(ACTION, ''),
        @ID_USER_SEL  = ISNULL(NULLIF(ID_USER_SEL, ''), NEW_ID),
        @VNOMBRE_TMP  = ISNULL(NEW_NAME, ''),
        @VEMAIL_TMP   = ISNULL(NEW_EMAIL, ''),
        @VPERFIL_TMP  = ISNULL(NEW_PERFIL, ''),
        @VESTADO_TMP  = ISNULL(NEW_ESTADO_CUENTA, '')
    FROM M_CONFIG WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @ID_USER_SEL = ISNULL(@ID_USER_SEL, '');
 
    -- Si es un registro nuevo (alta), forzamos variables vacías para no precargar datos viejos
    IF @ID_USER_SEL = ''
    BEGIN
        SET @VNOMBRE_TMP = '';
        SET @VEMAIL_TMP  = '';
        SET @VPERFIL_TMP = '';
        SET @VESTADO_TMP = '';
    END
    ELSE
    BEGIN
        SET @VREADONLY_ATTR = ' readonly="readonly" style="background-color: #f8fafc; cursor: not-allowed;" ';
    END
 
    -------------------------------------------------------
    -- 2. ESCAPAR CARACTERES PARA ATRIBUTOS VALUE DE INPUTS
    -------------------------------------------------------
 
    SET @ID_USER_SEL = REPLACE(@ID_USER_SEL, '"', '&quot;');
    SET @VNOMBRE_TMP = REPLACE(@VNOMBRE_TMP, '"', '&quot;');
    SET @VEMAIL_TMP  = REPLACE(@VEMAIL_TMP, '"', '&quot;');
    SET @VPERFIL_TMP = REPLACE(@VPERFIL_TMP, '"', '&quot;');
    SET @VESTADO_TMP = REPLACE(@VESTADO_TMP, '"', '&quot;');
 
    -------------------------------------------------------
    -- 3. CARGA DE OPCIONES DE PERFIL / GRUPOS (CURSOR SEGURO COMPATIBLE)
    -------------------------------------------------------
 
    -- Opción neutra limpia inicial
    SET @VOPTIONS_PERFIL = '<option value=""' + CASE WHEN ISNULL(@VPERFIL_TMP, '') = '' THEN ' selected="selected"' ELSE '' END + '>Seleccione un perfil...</option>';
 
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
        SET @VOPTIONS_PERFIL = @VOPTIONS_PERFIL + 
            '<option value="' + REPLACE(@g_id, '"', '&quot;') + '"' + 
            CASE WHEN @g_id = @VPERFIL_TMP AND @VPERFIL_TMP <> '' THEN ' selected="selected"' ELSE '' END + '>' + 
            REPLACE(@g_name, '<', '&lt;') + '</option>';
        FETCH NEXT FROM curG INTO @g_id, @g_name;
    END;
 
    CLOSE curG;
    DEALLOCATE curG;
 
    -------------------------------------------------------
    -- 4. HEADER Y PESTAÑAS GENÉRICAS
    -------------------------------------------------------
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
     @TITLE                   = 'Gestión de Usuarios',
     @SUBTITLE                = 'Administre los usuarios del sistema',
     @MODULE_ICON             = 'users',
 
     @DEFAULT_TAB_ID          = 'grid',
     @DEFAULT_TAB_TITLE       = 'Usuarios',
     @DEFAULT_TAB_ICON        = 'users',
 
     @DYNAMIC_TAB_ID          = 'form',
     @DYNAMIC_TAB_TITLE       = 'Nuevo usuario',
     @DYNAMIC_TAB_ICON        = 'user-plus',
 
     @SHOW_ACTION_BUTTON      = 1,
     @ACTION_BUTTON_TEXT      = 'Nuevo',
     @ACTION_BUTTON_ICON      = 'user-plus',
     @ACTION_TARGET_TAB       = 'form',
     @ACTION_MODE             = 'new',
 
     @HTML                    = @VHTML_HEADER OUTPUT;
 
    SET @PS_TITULO = CAST('
    <link rel="stylesheet" href="../css/vct-Tabs.css"/>
    <link rel="stylesheet" href="../css/vct-modal.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.css"/>
    <section class="vct-module" data-vct-tabs data-vct-grid-selector="[data-vct-grid-source]">' AS VARCHAR(MAX)) + ISNULL(@VHTML_HEADER, '');
 
    -------------------------------------------------------
    -- 5. CONSTRUCCIÓN DEL FORMULARIO
    -------------------------------------------------------
 
    SET @PS_FORMULARIO = '
    <div class="vct-panels">
        <div class="vct-panel is-active" data-vct-panel="grid">
            <div class="vct-grid-host" data-vct-grid-host></div>
        </div>
 
        <div class="vct-panel" data-vct-panel="form" hidden>
            <div class="vct-form-card">
                <div class="vct-form-header">
                    <div class="vct-form-icon" data-vct-form-icon>
                        <i data-lucide="user-plus"></i>
                    </div>
                    <div>
                        <h3 class="vct-form-title" data-vct-form-title>Nuevo usuario</h3>
                        <p class="vct-form-subtitle" data-vct-form-subtitle>Complete los datos del nuevo usuario.</p>
                    </div>
                </div>
 
                <div class="vct-form-body">
                    <input type="hidden" name="SP.ID_USER_SEL" id="SP_ID_USER_SEL" value="' + @ID_USER_SEL + '" data-vct-field="Usuario">
                    <input type="hidden" value="NEW" data-vct-form-mode>
 
                    <div class="vct-form-grid">
 
                        <!-- CAMPO 1: ID USUARIO -->
                        <div class="vct-form-group vct-form-group-full">
                            <label> 
                                <i data-lucide="id-card"></i> <span data-vct-id-label>Usuario</span>
                                <span class="vct-required" id="idCampo1" data-vct-id-required><i data-lucide="asterisk"></i></span>
                            </label>
                            <input class="vct-input" type="text" name="SP.NEW_ID" id="SP_NEW_ID" value="' + @ID_USER_SEL + '" placeholder="ej. jperez" autocomplete="off" data-vct-field="Usuario"' + @VREADONLY_ATTR + ' oninput="document.getElementById(''SP_ID_USER_SEL'').value = this.value;">
                        </div>
 
                        <!-- CAMPO 2: NOMBRE -->
                        <div class="vct-form-group vct-form-group-full">
                            <label> 
                                <i data-lucide="type"></i> <span>Nombre y Apellido</span> 
                                <span class="vct-required" id="idCampo2"><i data-lucide="asterisk"></i></span>
                            </label>
                            <input class="vct-input" type="text" name="SP.NEW_NAME" value="' + @VNOMBRE_TMP + '" placeholder="ej. Juan Pérez" autocomplete="off" data-vct-field="Descripcion">
                        </div>
 
                        <!-- CAMPO 3: EMAIL -->
                        <div class="vct-form-group vct-form-group-full">
                            <label>
                                <i data-lucide="mail"></i> <span>Email</span>
                            </label>
                            <input class="vct-input" type="email" name="SP.NEW_EMAIL" value="' + @VEMAIL_TMP + '" placeholder="jperez@empresa.com" autocomplete="off" data-vct-field="Email">
                        </div>
 
                        <!-- CAMPO 4: CONTRASEÑA -->
                        <div class="vct-form-group vct-form-group-full">
                            <label>
                                <i data-lucide="key-round"></i> <span>Contraseña</span>
                                <span class="vct-required" id="idCampo4"><i data-lucide="asterisk"></i></span>
                            </label>
                            <input class="vct-input" type="password" name="SP.NEW_PASSWORD" placeholder="Dejar en blanco para conservar contraseña actual" autocomplete="new-password" data-vct-field="Password">
                        </div>
 
                        <!-- CAMPO 5: PERFIL / GRUPO -->
                        <div class="vct-form-group">
                            <label>
                                <i data-lucide="shield"></i> <span>Perfil / Grupo</span>
                                <span class="vct-required" id="idCampo5"><i data-lucide="asterisk"></i></span>
                            </label>
                            <select class="vct-input vct-tom-select" name="SP.NEW_PERFIL" id="SP_NEW_PERFIL" data-vct-field="CodigoPerfil">
                                ' + ISNULL(@VOPTIONS_PERFIL, '') + '
                            </select>
                        </div>
 
                        <!-- CAMPO 6: ESTADO CUENTA -->
                        <div class="vct-form-group">
                            <label>
                                <i data-lucide="toggle-left"></i> <span>Estado</span>
                                <span class="vct-required" id="idCampo6"><i data-lucide="asterisk"></i></span>
                            </label>
                            <select class="vct-input vct-tom-select" name="SP.NEW_ESTADO_CUENTA" id="SP_NEW_ESTADO_CUENTA" data-vct-field="CodigoEstado">
                                <option value=""' + CASE WHEN ISNULL(@VESTADO_TMP, '') = '' THEN ' selected="selected"' ELSE '' END + '>Seleccione estado...</option>
                                <option value="1"' + CASE WHEN @VESTADO_TMP = '1' THEN ' selected="selected"' ELSE '' END + '>Activa</option>
                                <option value="0"' + CASE WHEN @VESTADO_TMP = '0' THEN ' selected="selected"' ELSE '' END + '>No Activa</option>
                            </select>
                        </div>
 
                    </div>
 
                    <!-- BOTONES DE ACCIÓN -->
                    <div class="vct-form-actions">
                        <button type="button" class="vct-button vct-button-secondary" data-vct-close-tab="form">
                            <i data-lucide="x"></i> Cancelar
                        </button>
                        
                        <button type="button" 
                                class="vct-button vct-button-primary" 
                                data-vct-submit 
                                onclick="vctConfirmarGuardar(''' + @FORM_ID + ''', 6); return false;">
                            <i data-lucide="save"></i>
                            <span data-vct-submit-label>Crear usuario</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- CARGA DE SCRIPTS Y MOTOR CENTRALIZADO -->
    <script src="../js/vct-Tabs.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script src="../js/vct-modal.js"></script>
';
 
END
