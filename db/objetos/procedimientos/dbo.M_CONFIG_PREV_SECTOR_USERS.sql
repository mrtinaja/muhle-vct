 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_SECTOR_USERS]
(
    @IPKEYJOB      VARCHAR(100),
    @IUSERID       VARCHAR(100),
    @FORM_ID       VARCHAR(100),
    @PS_TITULO     VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @V_SECTOR_SEL    VARCHAR(100) = '',
        @V_SECTOR_ID_INT INT = NULL,
        @V_SECTOR_DESC   NVARCHAR(300) = '',
        @VHTML_HEADER    VARCHAR(MAX) = '',
        @V_BACK_ONCLICK  VARCHAR(MAX),
        @V_BACK_BUTTON   VARCHAR(MAX),
        @V_HEADER_STYLE  VARCHAR(MAX);
 
    SELECT
        @V_SECTOR_SEL = ISNULL(NULLIF(LTRIM(RTRIM(CONVERT(VARCHAR(100), ID_SECTOR_SEL))), ''), ISNULL(ID_GROUP_SEL, ''))
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF ISNUMERIC(@V_SECTOR_SEL) = 1
        SET @V_SECTOR_ID_INT = CONVERT(INT, @V_SECTOR_SEL);
 
    IF @V_SECTOR_ID_INT IS NOT NULL
    BEGIN
        SELECT @V_SECTOR_DESC = ISNULL(Desc_Sector, '')
        FROM dbo.Sectores WITH (NOLOCK)
        WHERE Id_Sector = @V_SECTOR_ID_INT;
    END;
 
    IF ISNULL(@V_SECTOR_DESC, '') = ''
        SET @V_SECTOR_DESC = 'Sector seleccionado';
 
    SET @V_BACK_ONCLICK =
        'goto(''' + @FORM_ID + ''',''F01670C1-8A7A-469D-A8A6-B375A9198930'');return false;';
 
    EXEC dbo.VCT_RENDER_MODULE_HEADER
        @TITLE              = 'Usuarios del Sector',
        @SUBTITLE           = @V_SECTOR_DESC,
        @MODULE_ICON        = 'users',
        @DEFAULT_TAB_ID     = 'grid',
        @DEFAULT_TAB_TITLE  = 'Integrantes',
        @DEFAULT_TAB_ICON   = 'users',
        @SHOW_DYNAMIC_TAB   = 0,
        @SHOW_ACTION_BUTTON = 0,
        @ACTION_BUTTON_TEXT = '',
        @ACTION_BUTTON_ICON = '',
        @ACTION_TARGET_TAB  = '',
        @ACTION_MODE        = '',
        @ACTION_ONCLICK     = '',
        @HTML               = @VHTML_HEADER OUTPUT;
 
    SET @V_BACK_BUTTON =
        '<button type="button" class="vct-header-circle-back" title="Volver" onclick="' + @V_BACK_ONCLICK + '">' +
            '<i data-lucide="arrow-left"></i>' +
        '</button>';
 
    SET @VHTML_HEADER = REPLACE(
        ISNULL(@VHTML_HEADER, ''),
        '</header>',
        @V_BACK_BUTTON + '</header>'
    );
 
    SET @V_HEADER_STYLE = '
	<style>
		.vct-header-circle-back {
			width: 34px !important;
			height: 34px !important;
			min-width: 34px !important;
			border-radius: 999px !important;
			border: 1px solid rgba(255,255,255,.22) !important;
			background: #97003f !important;
			color: #ffffff !important;
			display: inline-flex !important;
			align-items: center !important;
			justify-content: center !important;
			cursor: pointer !important;
			box-shadow: 0 5px 12px rgba(0,0,0,.16) !important;
			transition: all .18s ease !important;
		}
 
		.vct-header-circle-back:hover {
			background: #7d0035 !important;
			border-color: rgba(255,255,255,.32) !important;
			transform: translateY(-1px) !important;
		}
 
		.vct-header-circle-back svg,
		.vct-header-circle-back i {
			width: 19px !important;
			height: 19px !important;
			stroke: #ffffff !important;
			color: #ffffff !important;
			stroke-width: 2.5 !important;
		}
	</style>';
 
    SET @PS_TITULO =
        '<link rel="stylesheet" href="../css/vct-Tabs.css?v=9.9.9" />' +
        '<script type="text/javascript" src="../js/vct-Core.js?v=9.9.9"></script>' +
        '<script type="text/javascript" src="../js/vct-Tabs.js?v=9.9.9"></script>' +
        @V_HEADER_STYLE +
        '<section class="vct-module"' +
        ' data-vct-module' +
        ' data-vct-tabs' +
        ' data-vct-default-tab="grid"' +
        ' data-vct-active-tab="grid"' +
        ' data-vct-grid-selector="[data-vct-grid-source]"' +
        ' data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID, ''), '"', '&quot;') + '">' +
        ISNULL(@VHTML_HEADER, '');
 
    SET @PS_FORMULARIO =
        '<script type="text/javascript">
            if (window.lucide && typeof window.lucide.createIcons === "function") {
                window.lucide.createIcons();
            }
        </script>' +
        '</section>';
END
