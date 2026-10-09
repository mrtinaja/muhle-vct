 
 
/* ============================================================================
   VCT_GET_HEADER - V7
   Mantiene el layout corregido de V6.
   ============================================================================ */
CREATE PROCEDURE [dbo].[VCT_GET_HEADER]
(
    @IUNIDAD             VARCHAR(100),
    @IAGENTE             VARCHAR(100),
    @FORM_ID             VARCHAR(100),
    @TITLE               VARCHAR(200),
    @SUBTITLE            VARCHAR(500) = '',
    @SEARCH_PLACEHOLDER  VARCHAR(250) = '',
    @SHOW_SEARCH         BIT = 0,
    @LOGO_SRC            VARCHAR(250) = '../img/vct-logo-burgundy.png',
    @OHEADER             VARCHAR(MAX) OUTPUT,
    @ORESULTADO          VARCHAR(20) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @OHEADER='';
    SET @ORESULTADO='OK';
 
    BEGIN TRY
        DECLARE
            @E_TITLE      VARCHAR(1000),
            @E_SUBTITLE   VARCHAR(2000),
            @E_LOGO       VARCHAR(1000),
            @E_FORM_ID    VARCHAR(1000);
 
        SET @E_TITLE=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@TITLE,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
        SET @E_SUBTITLE=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@SUBTITLE,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
        SET @E_LOGO=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(@LOGO_SRC,''),'../img/vct-logo-burgundy.png'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
        SET @E_FORM_ID=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@FORM_ID,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
        SET @OHEADER=
            '<style>'+
            '@media (min-width:769px){'+
                'html body #vctAppHeader{'+
                    'position:fixed!important;top:0!important;left:64px!important;right:0!important;'+
                    'width:auto!important;max-width:none!important;height:70px!important;min-height:70px!important;'+
                    'margin:0!important;padding:0 20px!important;box-sizing:border-box!important;z-index:1400!important;'+
                    'display:flex!important;align-items:center!important;justify-content:space-between!important;'+
                    'background:rgba(255,255,255,.96)!important;border-bottom:1px solid rgba(87,18,49,.08)!important;'+
                    'box-shadow:0 3px 16px rgba(32,18,24,.05)!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-left{'+
                    'height:100%!important;display:flex!important;align-items:center!important;gap:14px!important;'+
                    'padding:0!important;margin:0!important;min-width:0!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-brand{'+
                    'height:100%!important;display:flex!important;align-items:center!important;justify-content:flex-start!important;'+
                    'padding:0!important;margin:0!important;flex:0 0 auto!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-logo{'+
                    'height:38px!important;width:auto!important;max-width:none!important;display:block!important;object-fit:contain!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-divider{'+
                    'display:block!important;width:1px!important;height:36px!important;margin:0 2px!important;background:rgba(122,7,52,.18)!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-copy{'+
                    'display:flex!important;flex-direction:column!important;justify-content:center!important;padding:0!important;margin:0!important;min-width:0!important;'+
                '}'+
                'html body #vctAppHeader .vct-app-header-title{margin:0!important;padding:0!important;line-height:1.05!important;}'+
                'html body #vctAppHeader .vct-app-header-subtitle{margin:4px 0 0!important;padding:0!important;line-height:1.15!important;}'+
                'html body #vctAppHeader .vct-app-header-user-reserve{margin-left:auto!important;}'+
            '}'+
            '@media (max-width:768px){'+
                'html body #vctAppHeader{position:relative!important;left:0!important;right:auto!important;width:100%!important;height:64px!important;min-height:64px!important;padding:0 12px!important;}'+
                'html body #vctAppHeader .vct-app-header-logo{height:36px!important;}'+
            '}'+
            '</style>'+
 
            '<header id="vctAppHeader" class="vct-app-header" data-vct-app-header data-vct-form-id="'+@E_FORM_ID+'">'+
                '<div class="vct-app-header-left">'+
                    '<div class="vct-app-header-brand">'+
                        '<img class="vct-app-header-logo" src="'+@E_LOGO+'" alt="Vocaturo">'+
                    '</div>'+
                    '<span class="vct-app-header-divider" aria-hidden="true"></span>'+
                    '<div class="vct-app-header-copy">'+
                        '<h1 class="vct-app-header-title">'+@E_TITLE+'</h1>'+
                        CASE WHEN NULLIF(@E_SUBTITLE,'') IS NULL THEN '' ELSE '<p class="vct-app-header-subtitle">'+@E_SUBTITLE+'</p>' END+
                    '</div>'+
                '</div>'+
                '<div class="vct-app-header-user-reserve" aria-hidden="true"></div>'+
                '<button type="button" class="vct-header-mobile-menu" data-vct-command="sidebar-toggle" aria-label="Abrir menu" title="Menu">'+
                    '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"></path></svg>'+
                '</button>'+
            '</header>';
 
    END TRY
    BEGIN CATCH
        SET @OHEADER='';
        SET @ORESULTADO='ERROR';
    END CATCH;
END
