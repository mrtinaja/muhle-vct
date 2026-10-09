 
CREATE PROCEDURE [dbo].[VCT_RENDER_MODULE_HEADER]
(
    @TITLE                  VARCHAR(200),
    @SUBTITLE               VARCHAR(500) = '',
    @MODULE_ICON            VARCHAR(100) = '',
 
    @DEFAULT_TAB_ID         VARCHAR(100) = '',
    @DEFAULT_TAB_TITLE      VARCHAR(150) = '',
    @DEFAULT_TAB_ICON       VARCHAR(100) = '',
 
    @DYNAMIC_TAB_ID         VARCHAR(100) = '',
    @DYNAMIC_TAB_TITLE      VARCHAR(150) = '',
    @DYNAMIC_TAB_ICON       VARCHAR(100) = '',
    @SHOW_DYNAMIC_TAB       BIT = 1,
 
    @SHOW_ACTION_BUTTON     BIT = 1,
    @ACTION_BUTTON_TEXT     VARCHAR(150) = '',
    @ACTION_BUTTON_ICON     VARCHAR(100) = '',
    @ACTION_TARGET_TAB      VARCHAR(100) = '',
    @ACTION_MODE            VARCHAR(50) = '',
	@ACTION_ONCLICK			VARCHAR(4000) = '',
 
    @HTML                   VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @TITLE               = ISNULL(@TITLE, '');
    SET @SUBTITLE            = ISNULL(@SUBTITLE, '');
    SET @MODULE_ICON         = ISNULL(@MODULE_ICON, '');
 
    SET @DEFAULT_TAB_ID      = ISNULL(@DEFAULT_TAB_ID, 'grid');
    SET @DEFAULT_TAB_TITLE   = ISNULL(@DEFAULT_TAB_TITLE, '');
    SET @DEFAULT_TAB_ICON    = ISNULL(@DEFAULT_TAB_ICON, '');
 
    SET @DYNAMIC_TAB_ID      = ISNULL(@DYNAMIC_TAB_ID, 'form');
    SET @DYNAMIC_TAB_TITLE   = ISNULL(@DYNAMIC_TAB_TITLE, '');
    SET @DYNAMIC_TAB_ICON    = ISNULL(@DYNAMIC_TAB_ICON, '');
 
    SET @ACTION_BUTTON_TEXT  = ISNULL(@ACTION_BUTTON_TEXT, '');
    SET @ACTION_BUTTON_ICON  = ISNULL(@ACTION_BUTTON_ICON, '');
    SET @ACTION_TARGET_TAB   = ISNULL(@ACTION_TARGET_TAB, 'form');
    SET @ACTION_MODE         = ISNULL(@ACTION_MODE, 'new');
 
    SET @TITLE = REPLACE(REPLACE(REPLACE(@TITLE, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    SET @SUBTITLE = REPLACE(REPLACE(REPLACE(@SUBTITLE, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    SET @DEFAULT_TAB_TITLE = REPLACE(REPLACE(REPLACE(@DEFAULT_TAB_TITLE, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    SET @DYNAMIC_TAB_TITLE = REPLACE(REPLACE(REPLACE(@DYNAMIC_TAB_TITLE, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    SET @ACTION_BUTTON_TEXT = REPLACE(REPLACE(REPLACE(@ACTION_BUTTON_TEXT, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
 
    SET @HTML = CAST('
    <header class="vct-module-header">
        <div class="vct-module-heading">
            <div class="vct-module-icon">' +
                CASE WHEN @MODULE_ICON <> '' THEN '<i data-lucide="' + @MODULE_ICON + '"></i>' ELSE '' END +
            '</div>
            <div class="vct-module-heading-text">
                <h2 class="vct-module-title">' + @TITLE + '</h2>
                <p class="vct-module-subtitle">' + @SUBTITLE + '</p>
            </div>
        </div>
    </header>
 
    <nav class="vct-tabs-bar">
        <div class="vct-tabs-list">
 
            <!-- PESTAÑA PRINCIPAL -->
            <button type="button" class="vct-tab is-active" data-vct-tab="' + @DEFAULT_TAB_ID + '">
                ' + CASE WHEN @DEFAULT_TAB_ICON <> '' THEN '<i data-lucide="' + @DEFAULT_TAB_ICON + '"></i>' ELSE '' END + '
                <span data-vct-tab-text>' + @DEFAULT_TAB_TITLE + '</span>
            </button>' +
 
            CASE WHEN @SHOW_DYNAMIC_TAB = 1 THEN '
            <!-- PESTAÑA DINÁMICA -->
            <button type="button" class="vct-tab" data-vct-tab="' + @DYNAMIC_TAB_ID + '" data-vct-dynamic-tab hidden>
                <span data-vct-tab-icon>
                    ' + CASE WHEN @DYNAMIC_TAB_ICON <> '' THEN '<i data-lucide="' + @DYNAMIC_TAB_ICON + '"></i>' ELSE '' END + '
                </span>
                <span data-vct-tab-text data-vct-tab-title>' + @DYNAMIC_TAB_TITLE + '</span>
                <span class="vct-tab-close" data-vct-close-tab="' + @DYNAMIC_TAB_ID + '" title="Cerrar">&times;</span>
            </button>' ELSE '' END +
 
        '</div>' +
 
        CASE WHEN @SHOW_ACTION_BUTTON = 1 THEN '
        <!-- BOTÓN ACCIÓN A LA DERECHA -->
        <div class="vct-tabs-actions">
            <button type="button" onclick="'+@ACTION_ONCLICK+'" class="vct-button vct-button-primary vct-tabs-action-button" data-vct-open-tab="' + @ACTION_TARGET_TAB + '"' +
                CASE WHEN LOWER(@ACTION_MODE) = 'new' THEN ' data-vct-new-record' ELSE '' END +
                ' data-vct-mode="' + @ACTION_MODE + '">
                ' + CASE WHEN @ACTION_BUTTON_ICON <> '' THEN '<i data-lucide="' + @ACTION_BUTTON_ICON + '"></i>' ELSE '' END + '
                ' + CASE WHEN @ACTION_BUTTON_TEXT <> '' THEN '<span class="vct-button-text">' + @ACTION_BUTTON_TEXT + '</span>' ELSE '' END + '
            </button>
        </div>' ELSE '' END +
 
    '</nav>' AS VARCHAR(MAX));
END
