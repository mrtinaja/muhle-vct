 
 
/* ============================================================================
   VCT_GET_SHELL - V7
   Mantiene el contenido usando todo el espacio desde x = 64 px.
   ============================================================================ */
CREATE PROCEDURE [dbo].[VCT_GET_SHELL]
(
    @IUNIDAD             VARCHAR(100),
    @IAGENTE             VARCHAR(100),
    @FORM_ID             VARCHAR(100),
    @TITLE               VARCHAR(200),
    @SUBTITLE            VARCHAR(500) = '',
    @SEARCH_PLACEHOLDER  VARCHAR(250) = '',
    @SHOW_SEARCH         BIT = 0,
    @OSHELL              VARCHAR(MAX) OUTPUT,
    @ORESULTADO          VARCHAR(20) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @HTML_SIDEBAR VARCHAR(MAX)='',
        @HTML_HEADER VARCHAR(MAX)='',
        @RES_SIDEBAR VARCHAR(20)='',
        @RES_HEADER VARCHAR(20)='',
        @LAYOUT_FIX VARCHAR(MAX)='';
 
    SET @OSHELL='';
    SET @ORESULTADO='OK';
 
    BEGIN TRY
        EXEC dbo.VCT_GET_SIDEBAR
             @IUNIDAD=@IUNIDAD,
             @IAGENTE=@IAGENTE,
             @FORM_ID=@FORM_ID,
             @OSIDEBAR=@HTML_SIDEBAR OUTPUT,
             @ORESULTADO=@RES_SIDEBAR OUTPUT;
 
        EXEC dbo.VCT_GET_HEADER
             @IUNIDAD=@IUNIDAD,
             @IAGENTE=@IAGENTE,
             @FORM_ID=@FORM_ID,
             @TITLE=@TITLE,
             @SUBTITLE=@SUBTITLE,
             @SEARCH_PLACEHOLDER=@SEARCH_PLACEHOLDER,
             @SHOW_SEARCH=@SHOW_SEARCH,
             @LOGO_SRC='../img/vct-logo-burgundy.png',
             @OHEADER=@HTML_HEADER OUTPUT,
             @ORESULTADO=@RES_HEADER OUTPUT;
 
        SET @LAYOUT_FIX=
        '<style>'+
        '@media (min-width:769px){'+
            'html,body{margin:0!important;padding:0!important;width:100%!important;max-width:none!important;}'+
            'html body .vct-main,'+
            'html body .vct-main-content,'+
            'html body .vct-content,'+
            'html body .main-content,'+
            'html body .content-wrapper,'+
            'html body .page-wrapper,'+
            'html body .page-content,'+
            'html body #mainContent,'+
            'html body #content,'+
            'html body main{'+
                'margin-left:64px!important;margin-right:0!important;padding-left:0!important;'+
                'width:calc(100% - 64px)!important;max-width:none!important;box-sizing:border-box!important;'+
            '}'+
            'html body .container,'+
            'html body .container-fluid{max-width:none!important;}'+
        '}'+
        '</style>'+
 
        '<script>'+
        '(function(){'+
            'function applyVctLayout(){'+
                'if(window.innerWidth<=768)return;'+
                'var sidebar=document.getElementById(''muhleSideBar'');'+
                'var header=document.getElementById(''vctAppHeader'');'+
                'if(sidebar){'+
                    'sidebar.style.setProperty(''width'',''64px'',''important'');'+
                    'sidebar.style.setProperty(''min-width'',''64px'',''important'');'+
                    'sidebar.style.setProperty(''max-width'',''64px'',''important'');'+
                '}'+
                'if(header){'+
                    'header.style.setProperty(''position'',''fixed'',''important'');'+
                    'header.style.setProperty(''top'',''0'',''important'');'+
                    'header.style.setProperty(''left'',''64px'',''important'');'+
                    'header.style.setProperty(''right'',''0'',''important'');'+
                    'header.style.setProperty(''width'',''auto'',''important'');'+
                    'header.style.setProperty(''margin'',''0'',''important'');'+
                '}'+
                'var known=document.querySelectorAll(''.vct-main,.vct-main-content,.vct-content,.main-content,.content-wrapper,.page-wrapper,.page-content,#mainContent,#content,main'');'+
                'for(var j=0;j<known.length;j++){'+
                    'known[j].style.setProperty(''margin-left'',''64px'',''important'');'+
                    'known[j].style.setProperty(''width'',''calc(100% - 64px)'',''important'');'+
                    'known[j].style.setProperty(''max-width'',''none'',''important'');'+
                    'known[j].style.setProperty(''box-sizing'',''border-box'',''important'');'+
                '}'+
            '}'+
            'if(document.readyState===''loading''){document.addEventListener(''DOMContentLoaded'',applyVctLayout);}else{applyVctLayout();}'+
            'setTimeout(applyVctLayout,50);'+
            'setTimeout(applyVctLayout,250);'+
            'window.addEventListener(''resize'',applyVctLayout);'+
        '})();'+
        '</script>';
 
        SET @OSHELL=ISNULL(@HTML_SIDEBAR,'')+ISNULL(@HTML_HEADER,'')+ISNULL(@LAYOUT_FIX,'');
 
        IF ISNULL(@RES_SIDEBAR,'')='ERROR' OR ISNULL(@RES_HEADER,'')='ERROR'
            SET @ORESULTADO='ERROR';
    END TRY
    BEGIN CATCH
        SET @OSHELL=ISNULL(@HTML_SIDEBAR,'')+ISNULL(@HTML_HEADER,'');
        SET @ORESULTADO='ERROR';
    END CATCH;
END
