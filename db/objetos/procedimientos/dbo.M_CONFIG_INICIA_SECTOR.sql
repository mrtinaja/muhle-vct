 
CREATE PROCEDURE [dbo].[M_CONFIG_INICIA_SECTOR]
(
    @IPKEYJOB      AS VARCHAR(100),
    @IUSERID       AS VARCHAR(100),
    @FORM_ID       AS VARCHAR(100),
    @PS_TITULO     AS VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @VACTION          VARCHAR(50)    = '',
        @ID_SECTOR_SEL    VARCHAR(100)   = '',
        @VNOMBRE_TMP      NVARCHAR(200)  = '',
        @VEMAIL_TMP       NVARCHAR(300)  = '',
        @VDESC_ERROR      NVARCHAR(4000) = '',
        @VHTML_HEADER     VARCHAR(MAX)   = '',
        @VFORM_ID_CLEAN   VARCHAR(100)   = '',
        @VIN_EDIT         BIT            = 0,
        @VFORM_TITLE      VARCHAR(150)   = '',
        @VFORM_SUBTITLE   VARCHAR(300)   = '',
        @VSUBMIT_LABEL    VARCHAR(100)   = '',
        @VFORM_ICON       VARCHAR(100)   = '',
        @VACTIVE_TAB      VARCHAR(20)    = 'form';
 
    SELECT TOP 1
        @VACTION       = ISNULL(ACTION, ''),
        @ID_SECTOR_SEL = ISNULL(NULLIF(LTRIM(RTRIM(CONVERT(VARCHAR(100), ID_SECTOR_SEL))), ''), '0'),
        @VNOMBRE_TMP   = ISNULL(NEW_NAME, ''),
        @VEMAIL_TMP    = ISNULL(NEW_EMAIL, ''),
        @VDESC_ERROR   = ISNULL(DESC_ERROR, '')
    FROM M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @VACTION = UPPER(LTRIM(RTRIM(ISNULL(@VACTION, ''))));
    SET @ID_SECTOR_SEL = LTRIM(RTRIM(ISNULL(@ID_SECTOR_SEL, '0')));
    SET @VDESC_ERROR = LTRIM(RTRIM(ISNULL(@VDESC_ERROR, '')));
    SET @VFORM_ID_CLEAN = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
 
    IF @VACTION = 'EDITAR' AND @ID_SECTOR_SEL <> '' AND @ID_SECTOR_SEL <> '0'
        SET @VIN_EDIT = 1;
 
    IF @VIN_EDIT = 1 AND @VDESC_ERROR = ''
    BEGIN
        SELECT TOP 1
            @VNOMBRE_TMP = ISNULL(Desc_Sector, ''),
            @VEMAIL_TMP  = ISNULL(Mail_Sector, '')
        FROM dbo.Sectores WITH (NOLOCK)
        WHERE CONVERT(VARCHAR(100), Id_Sector) = @ID_SECTOR_SEL;
    END;
 
    IF @VIN_EDIT = 1
    BEGIN
        SET @VFORM_TITLE    = 'Editar sector';
        SET @VFORM_SUBTITLE = 'Modifique los datos del sector seleccionado.';
        SET @VSUBMIT_LABEL  = 'Guardar cambios';
        SET @VFORM_ICON     = 'network';
    END
    ELSE
    BEGIN
        SET @VFORM_TITLE    = 'Nuevo sector';
        SET @VFORM_SUBTITLE = 'Complete los datos del nuevo sector.';
        SET @VSUBMIT_LABEL  = 'Crear sector';
        SET @VFORM_ICON     = 'plus-circle';
        SET @VACTION        = 'AGREGAR';
        SET @ID_SECTOR_SEL  = ISNULL(NULLIF(@ID_SECTOR_SEL, ''), '0');
    END;
 
    SET @ID_SECTOR_SEL = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@ID_SECTOR_SEL, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VNOMBRE_TMP   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VNOMBRE_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
    SET @VEMAIL_TMP    = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VEMAIL_TMP, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;');
 
    DECLARE @VONCLICK_NUEVO VARCHAR(MAX) =
        'if(typeof almacenarSeleccion===''function''){almacenarSeleccion(''ID_SECTOR_SEL'',''0'');almacenarSeleccion(''ACTION'',''AGREGAR'');} if(window.VctTabs){var m=document.querySelector(''[data-vct-tabs]'');if(m){VctTabs.open(m,''form'',{mode:''new''});}} return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
         @TITLE              = 'Estructura Organizacional',
         @SUBTITLE           = 'Gestione la jerarquía de sectores y asignación de integrantes',
         @MODULE_ICON        = 'network',
         @DEFAULT_TAB_ID     = 'form',
         @DEFAULT_TAB_TITLE  = 'Sector',
         @DEFAULT_TAB_ICON   = 'network',
         @DYNAMIC_TAB_ID     = '',
         @DYNAMIC_TAB_TITLE  = '',
         @DYNAMIC_TAB_ICON   = '',
         @SHOW_ACTION_BUTTON = 0,
         @ACTION_BUTTON_TEXT = '',
         @ACTION_BUTTON_ICON = '',
         @ACTION_TARGET_TAB  = '',
         @ACTION_MODE        = '',
         @ACTION_ONCLICK     = @VONCLICK_NUEVO,
         @HTML               = @VHTML_HEADER OUTPUT;
 
    SET @VHTML_HEADER = ISNULL(@VHTML_HEADER, '');
 
    SET @PS_TITULO = CAST(
        '<link rel="stylesheet" href="../css/vct-Tabs.css" />' +
        '<link rel="stylesheet" href="../css/vct-modal.css" />' +
 
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="form"' +
        ' data-vct-active-tab="form"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '"' +
        ' data-vct-primary-field="Id_Sector"' +
        ' data-vct-edit-mode="server"' +
        ' data-vct-edit-storage-key="ID_SECTOR_SEL"' +
        ' data-vct-initial-mode="' + CASE WHEN @VIN_EDIT = 1 THEN 'edit' ELSE 'new' END + '">' +
        @VHTML_HEADER
    AS VARCHAR(MAX));
 
    SET @PS_FORMULARIO = CAST(
        '<div class="vct-panels">' +
            '<div class="vct-panel is-active" data-vct-panel="form" aria-hidden="false">' +
 
                '<div class="vct-form-card">' +
                    '<div class="vct-form-header">' +
                        '<div class="vct-form-icon" data-vct-form-icon>' +
                            '<i data-lucide="' + ISNULL(@VFORM_ICON, 'network') + '"></i>' +
                        '</div>' +
                        '<div>' +
                            '<h3 class="vct-form-title" data-vct-form-title>' + ISNULL(@VFORM_TITLE, 'Sector') + '</h3>' +
                            '<p class="vct-form-subtitle" data-vct-form-subtitle>' + ISNULL(@VFORM_SUBTITLE, '') + '</p>' +
                        '</div>' +
                    '</div>' +
 
                    '<div class="vct-form-body">' +
 
                        CASE WHEN @VDESC_ERROR <> '' THEN
                            '<div class="vct-alert vct-alert-error" style="margin-bottom:16px;">' +
                                '<i data-lucide="alert-circle"></i>' +
                                '<span>' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@VDESC_ERROR, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;') + '</span>' +
                            '</div>'
                        ELSE '' END +
 
                        '<input type="hidden" id="ID_SECTOR_SEL" name="SP.ID_SECTOR_SEL" value="' + ISNULL(@ID_SECTOR_SEL, '') + '" />' +
                        '<input type="hidden" id="VCT_FORM_MODE" data-vct-form-mode value="' + CASE WHEN @VIN_EDIT = 1 THEN 'EDIT' ELSE 'NEW' END + '" />' +
                        '<input type="hidden" name="SP.ACTION" value="' + ISNULL(@VACTION, '') + '" />' +
 
                        '<div class="vct-form-grid">' +
 
                            CASE WHEN @VIN_EDIT = 1 THEN
                                '<div class="vct-form-group vct-form-group-full">' +
                                    '<label for="vctSectorId">' +
                                        '<i data-lucide="key-round"></i>' +
                                        '<span>ID Sector</span>' +
                                    '</label>' +
                                    '<input class="vct-input" type="text" id="vctSectorId" value="' + ISNULL(@ID_SECTOR_SEL, '') + '" readonly="readonly" aria-readonly="true" style="background-color:#f8fafc;cursor:not-allowed;" />' +
                                '</div>'
                            ELSE '' END +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctSectorName">' +
                                    '<i data-lucide="type"></i>' +
                                    '<span>Nombre</span>' +
                                    '<span class="vct-required" id="idCampo1"><i data-lucide="asterisk"></i></span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="text"' +
                                ' id="vctSectorName"' +
                                ' name="SP.NEW_NAME"' +
                                ' value="' + ISNULL(@VNOMBRE_TMP, '') + '"' +
                                ' placeholder="ej. Sector Producción"' +
                                ' autocomplete="off" />' +
                            '</div>' +
 
                            '<div class="vct-form-group vct-form-group-full">' +
                                '<label for="vctSectorEmail">' +
                                    '<i data-lucide="mail"></i>' +
                                    '<span>Email contacto</span>' +
                                '</label>' +
                                '<input class="vct-input"' +
                                ' type="email"' +
                                ' id="vctSectorEmail"' +
                                ' name="SP.NEW_EMAIL"' +
                                ' value="' + ISNULL(@VEMAIL_TMP, '') + '"' +
                                ' placeholder="contacto@vocaturo.com.ar"' +
                                ' autocomplete="off" />' +
                            '</div>' +
 
                        '</div>' +
 
                        '<div class="vct-form-actions">' +
                            '<button type="button"' +
                            ' class="vct-button vct-button-secondary"' +
                            ' onclick="goto(''' + ISNULL(@VFORM_ID_CLEAN, '') + ''',''F01670C1-8A7A-469D-A8A6-B375A9198930'');return false;">' +
                                '<i data-lucide="x"></i>' +
                                '<span>Cancelar</span>' +
                            '</button>' +
 
                            '<button type="button"' +
                            ' class="vct-button vct-button-primary"' +
                            ' onclick="vctConfirmarGuardar(''' + ISNULL(@VFORM_ID_CLEAN, '') + ''',1);return false;"' +
                            ' style="display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:0 20px;height:42px;">' +
                                '<i data-lucide="save"></i>' +
                                '<span class="vct-button-text" style="display:inline-block;font-weight:600;">' + ISNULL(@VSUBMIT_LABEL, 'Guardar') + '</span>' +
                            '</button>' +
                        '</div>' +
 
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +
 
        '<script src="../js/vct-Core.js"></script>' +
        '<script src="../js/vct-Tabs.js"></script>' +
        '<script src="../js/vct-modal.js"></script>' +
 
        '<script>' +
        '(function(){' +
        'function run(){' +
        'if(window.lucide&&typeof window.lucide.createIcons==="function"){window.lucide.createIcons();}' +
        '}' +
        'if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",run);}else{run();}' +
        'setTimeout(run,100);' +
        'setTimeout(run,400);' +
        '})();' +
        '</script>' +
 
        '</section>'
    AS VARCHAR(MAX));
 
    IF @VDESC_ERROR <> ''
    BEGIN
        UPDATE M_CONFIG
        SET DESC_ERROR = NULL
        WHERE PAR_KEY = @IPKEYJOB;
    END
END
