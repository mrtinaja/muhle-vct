/* ========================================================================
   FIX_VCT_GET_SIDEBAR_V82
   ------------------------------------------------------------------------
   V8.2 = V8.1 + nombres en el menu movil.
   En celular, "Mas" abria el riel de solo iconos (64px) y no habia forma
   de saber que era cada uno (no hay "pasar el mouse").
     - El texto de cada item ya no viene oculto en linea (style="display:
       none"); en escritorio lo sigue ocultando el CSS (@media >= 769px).
     - Nuevo bloque @media (max-width:768px): el drawer pasa a 248px con
       icono + nombre, y "Salir" tambien con nombre.
   Escritorio queda igual.
   ======================================================================== */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[VCT_GET_SIDEBAR]
(
    @IUNIDAD    VARCHAR(100),
    @IAGENTE    VARCHAR(100),
    @FORM_ID    VARCHAR(100) = NULL,
    @OSIDEBAR   VARCHAR(MAX) OUTPUT,
    @ORESULTADO VARCHAR(20) OUTPUT
)
AS
BEGIN
    /* VCT_GET_SIDEBAR - V8.2: V8.1 + nombres en el drawer movil. */
    SET NOCOUNT ON;

    DECLARE @HTML_ITEMS VARCHAR(MAX)='';
    DECLARE @HTML_MOBILE_ITEMS VARCHAR(MAX)='';
    DECLARE @VCANT_MENU INT=0;

    DECLARE @ACCIONES_ICON VARCHAR(MAX)=
        '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'+
            '<rect x="3" y="3" width="18" height="18" rx="3"></rect>'+
            '<path d="M7 12l3 3 7-7"></path>'+
        '</svg>';

    DECLARE @LOGOUT_ICON VARCHAR(MAX)=
        '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'+
            '<path d="M10 17l5-5-5-5"></path>'+
            '<path d="M15 12H3"></path>'+
            '<path d="M21 19V5a2 2 0 0 0-2-2h-6"></path>'+
        '</svg>';

    SET @OSIDEBAR='';
    SET @ORESULTADO='SIN_MENU';

    SELECT @VCANT_MENU=COUNT(*)
    FROM dbo.SideBar SB WITH(NOLOCK)
    INNER JOIN dbo.SideBarGroups SBG WITH(NOLOCK)
        ON CONVERT(VARCHAR(50),SBG.SideBarId)=CONVERT(VARCHAR(50),SB.Id)
    WHERE UPPER(LTRIM(RTRIM(SBG.GroupId)))=UPPER(LTRIM(RTRIM(@IUNIDAD)));

    IF ISNULL(@VCANT_MENU,0)=0 RETURN;

    SET @ORESULTADO='MENU_OK';

    SELECT @HTML_ITEMS=ISNULL((
        SELECT
        '<a id="vct_mod_'+CONVERT(VARCHAR(50),SB.Id)+'" href="#" '+
        'title="'+CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(SB.Name,'')))) LIKE 'PLANIFIC%' THEN 'Acciones' ELSE ISNULL(SB.Name,'') END+'" '+
        'aria-label="'+CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(SB.Name,'')))) LIKE 'PLANIFIC%' THEN 'Acciones' ELSE ISNULL(SB.Name,'') END+'" '+
        'class="vct-sidebar-action'+
            CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(SB.Name,'')))) LIKE 'PLANIFIC%' THEN ' vct-ob-planificacion' ELSE '' END+'" '+
        'data-vct-mod="'+CONVERT(VARCHAR(50),SB.Id)+'" '+
        'onclick="vctSetActiveModule('''+CONVERT(VARCHAR(50),SB.Id)+''');'+
        'newTaskForContactWithParams(''VOCATURO'',''ACTION='+ISNULL(SB.Code,'')+
        ''',''VCT_GESTION'','''+ISNULL(SB.Name,'')+''');return false;">'+
            '<span class="vct-sidebar-action-icon">'+
                CASE
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(SB.Name,'')))) LIKE 'PLANIFIC%' THEN @ACCIONES_ICON
                    ELSE ISNULL(SB.SvgIcon,'')
                END+
            '</span>'+
            '<span class="vct-sidebar-text">'+
                CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(SB.Name,'')))) LIKE 'PLANIFIC%' THEN 'Acciones' ELSE ISNULL(SB.Name,'') END+
            '</span>'+
        '</a>'
        FROM dbo.SideBar SB WITH(NOLOCK)
        INNER JOIN dbo.SideBarGroups SBG WITH(NOLOCK)
            ON CONVERT(VARCHAR(50),SBG.SideBarId)=CONVERT(VARCHAR(50),SB.Id)
        WHERE UPPER(LTRIM(RTRIM(SBG.GroupId)))=UPPER(LTRIM(RTRIM(@IUNIDAD)))
        ORDER BY CONVERT(INT,SB.Id)
        FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),'');

    SELECT @HTML_MOBILE_ITEMS=ISNULL((
        SELECT
        '<a href="#" class="vct-mobile-nav-link" data-vct-mod="'+CONVERT(VARCHAR(50),X.Id)+'" '+
        'onclick="vctSetActiveModule('''+CONVERT(VARCHAR(50),X.Id)+''');'+
        'newTaskForContactWithParams(''VOCATURO'',''ACTION='+ISNULL(X.Code,'')+
        ''',''VCT_GESTION'','''+ISNULL(X.Name,'')+''');return false;">'+
            '<span class="vct-mobile-nav-icon">'+
                CASE
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(X.Name,'')))) LIKE 'PLANIFIC%' THEN @ACCIONES_ICON
                    ELSE ISNULL(X.SvgIcon,'')
                END+
            '</span>'+
            '<span class="vct-mobile-nav-text">'+
                CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(X.Name,'')))) LIKE 'PLANIFIC%' THEN 'Acciones' ELSE ISNULL(X.Name,'') END+
            '</span>'+
        '</a>'
        FROM
        (
            SELECT TOP 4 SB.Id,SB.Code,SB.Name,SB.SvgIcon
            FROM dbo.SideBar SB WITH(NOLOCK)
            INNER JOIN dbo.SideBarGroups SBG WITH(NOLOCK)
                ON CONVERT(VARCHAR(50),SBG.SideBarId)=CONVERT(VARCHAR(50),SB.Id)
            WHERE UPPER(LTRIM(RTRIM(SBG.GroupId)))=UPPER(LTRIM(RTRIM(@IUNIDAD)))
            ORDER BY CONVERT(INT,SB.Id)
        ) X
        ORDER BY CONVERT(INT,X.Id)
        FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),'');

    SET @OSIDEBAR=
        CONVERT(VARCHAR(MAX),'<style>')+
        '@media (min-width:769px){'+

            ':root{--vct-sidebar-w:64px;}'+

            /* SIDEBAR */
            'html body #muhleSideBar{'+
                'position:fixed!important;top:0!important;left:0!important;bottom:0!important;'+
                'width:64px!important;min-width:64px!important;max-width:64px!important;height:100vh!important;'+
                'display:flex!important;flex-direction:column!important;overflow:hidden!important;z-index:1500!important;'+
                'background:linear-gradient(180deg,#7c0734 0%,#670528 52%,#51031f 100%)!important;'+
                'box-shadow:6px 0 18px rgba(45,6,22,.10)!important;transform:none!important;'+
            '}'+

            /* LOGO SUPERIOR: MISMO EJE X QUE ICONOS */
            'html body #muhleSideBar .vct-sidebar-head{'+
                'width:64px!important;height:66px!important;min-height:66px!important;flex:0 0 66px!important;'+
                'display:flex!important;align-items:center!important;justify-content:center!important;'+
                'padding:0!important;margin:0!important;'+
            '}'+

            'html body #muhleSideBar .vct-sidebar-brand,'+
            'html body #muhleSideBar .vct-sidebar-brand-mark{'+
                'width:64px!important;height:66px!important;'+
                'display:flex!important;align-items:center!important;justify-content:center!important;'+
                'padding:0!important;margin:0!important;'+
            '}'+

            'html body #muhleSideBar .vct-sidebar-brand-mark img{'+
                'display:block!important;'+
                'height:28px!important;width:auto!important;max-width:36px!important;'+
                'object-fit:contain!important;margin:0 auto!important;'+
                'transform:none!important;'+
            '}'+

            /* MENU */
            'html body #muhleSideBar .vct-sidebar-nav{'+
                'width:64px!important;flex:1 1 auto!important;min-height:0!important;'+
                'display:flex!important;flex-direction:column!important;align-items:center!important;justify-content:flex-start!important;'+
                'gap:3px!important;padding:7px 0!important;margin:0!important;'+
                'overflow-y:auto!important;overflow-x:hidden!important;scrollbar-width:none!important;'+
            '}'+

            'html body #muhleSideBar .vct-sidebar-nav::-webkit-scrollbar{display:none!important;}'+

            /* MISMO DISENO PARA MENU Y LOG OFF */
            'html body #muhleSideBar .vct-sidebar-action,'+
            'html body #muhleSideBar .vct-sidebar-logout{'+
                'position:relative!important;'+
                'width:42px!important;height:40px!important;'+
                'min-width:42px!important;max-width:42px!important;'+
                'min-height:40px!important;max-height:40px!important;'+
                'flex:0 0 40px!important;'+
                'display:flex!important;align-items:center!important;justify-content:center!important;'+
                'padding:0!important;margin:0 auto!important;'+
                'border-radius:10px!important;'+
                'border:1px solid rgba(255,255,255,.05)!important;'+
                'background:rgba(255,255,255,.09)!important;'+
                'color:rgba(255,255,255,.94)!important;'+
                'box-shadow:none!important;outline:none!important;'+
                'text-decoration:none!important;cursor:pointer!important;overflow:hidden!important;'+
                'transform:none!important;'+
                'transition:background-color .14s ease,border-color .14s ease,color .14s ease!important;'+
            '}'+

            /* HOVER = MISMO CRITERIO DEL LOG OFF */
            'html body #muhleSideBar .vct-sidebar-action:hover,'+
            'html body #muhleSideBar .vct-sidebar-logout:hover{'+
                'background:rgba(255,255,255,.15)!important;'+
                'border-color:rgba(255,255,255,.10)!important;'+
                'color:#fff!important;'+
                'box-shadow:none!important;transform:none!important;'+
            '}'+

            /* ACTIVE = MISMO BOTON, SOLO UN PASO MAS MARCADO */
            'html body #muhleSideBar .vct-sidebar-action.active,'+
            'html body #muhleSideBar .vct-sidebar-action.vct-active,'+
            'html body #muhleSideBar .vct-sidebar-action[aria-current="page"]{'+
                'background:rgba(255,255,255,.21)!important;'+
                'border-color:rgba(255,255,255,.14)!important;'+
                'color:#fff!important;'+
                'box-shadow:none!important;transform:none!important;'+
            '}'+

            /* ANULA CUALQUIER DECORACION ACTIVE/HOVER VIEJA */
            'html body #muhleSideBar .vct-sidebar-action::before,'+
            'html body #muhleSideBar .vct-sidebar-action::after,'+
            'html body #muhleSideBar .vct-sidebar-action.active::before,'+
            'html body #muhleSideBar .vct-sidebar-action.active::after,'+
            'html body #muhleSideBar .vct-sidebar-action.vct-active::before,'+
            'html body #muhleSideBar .vct-sidebar-action.vct-active::after,'+
            'html body #muhleSideBar .vct-sidebar-logout::before,'+
            'html body #muhleSideBar .vct-sidebar-logout::after{'+
                'content:none!important;display:none!important;'+
                'width:0!important;height:0!important;border:0!important;box-shadow:none!important;'+
            '}'+

            /* ICONOS: MISMO EJE Y MISMO TAMANO */
            'html body #muhleSideBar .vct-sidebar-action-icon,'+
            'html body #muhleSideBar .vct-sidebar-logout{'+
                'align-items:center!important;justify-content:center!important;'+
            '}'+

            'html body #muhleSideBar .vct-sidebar-action-icon{'+
                'width:20px!important;height:20px!important;min-width:20px!important;max-width:20px!important;'+
                'display:flex!important;align-items:center!important;justify-content:center!important;'+
                'margin:0!important;padding:0!important;line-height:0!important;flex:0 0 20px!important;'+
                'position:static!important;transform:none!important;'+
            '}'+

            'html body #muhleSideBar .vct-sidebar-action-icon svg,'+
            'html body #muhleSideBar .vct-sidebar-logout svg{'+
                'display:block!important;width:20px!important;height:20px!important;'+
                'max-width:20px!important;max-height:20px!important;'+
                'margin:0!important;padding:0!important;transform:none!important;'+
                'stroke:currentColor!important;color:inherit!important;'+
            '}'+

            /* SIN TEXTOS */
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-text,html body #muhleSideBar .vct-sidebar-text,'+
            'html body #muhleSideBar .vct-ob-text,'+
            'html body #muhleSideBar a span[class*="text"]{'+
                'display:none!important;width:0!important;max-width:0!important;height:0!important;max-height:0!important;'+
                'font-size:0!important;line-height:0!important;margin:0!important;padding:0!important;'+
                'visibility:hidden!important;opacity:0!important;position:absolute!important;pointer-events:none!important;'+
            '}'+

            /* FOOTER */
            'html body #muhleSideBar .vct-sidebar-footer{'+
                'width:64px!important;height:56px!important;min-height:56px!important;flex:0 0 56px!important;'+
                'display:flex!important;align-items:center!important;justify-content:center!important;'+
                'padding:6px 0!important;margin:0!important;border-top:1px solid rgba(255,255,255,.10)!important;'+
            '}'+

            'html body .vct-sidebar-backdrop{display:none!important;}'+
        '}'+

        /* MOVIL (V8.2): drawer con icono + nombre. body:not(.vct-x) sube la especificidad
           por encima de las reglas viejas de vct-main.css */
        '@media (max-width:768px){'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8{'+
                'width:min(248px,80vw)!important;min-width:min(248px,80vw)!important;max-width:min(248px,80vw)!important;'+
            '}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-head{'+
                'width:100%!important;justify-content:flex-start!important;padding:0 0 0 12px!important;box-sizing:border-box!important;'+
            '}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-nav{'+
                'width:100%!important;align-items:stretch!important;gap:4px!important;'+
                'padding:8px 10px!important;box-sizing:border-box!important;'+
            '}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-action,'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-logout{'+
                'width:100%!important;min-width:0!important;max-width:none!important;'+
                'height:44px!important;min-height:44px!important;max-height:44px!important;flex:0 0 44px!important;'+
                'justify-content:flex-start!important;gap:12px!important;padding:0 12px!important;margin:0!important;'+
                'box-sizing:border-box!important;font:inherit!important;'+
            '}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-action-icon{flex:0 0 20px!important;}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-text,'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 a span.vct-sidebar-text,'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 button span.vct-sidebar-text{'+
                'display:block!important;position:static!important;visibility:visible!important;opacity:1!important;'+
                'width:auto!important;max-width:none!important;height:auto!important;max-height:none!important;'+
                'margin:0!important;padding:0!important;pointer-events:none!important;'+
                'font-size:14px!important;line-height:1.2!important;font-weight:500!important;color:inherit!important;'+
                'white-space:nowrap!important;overflow:hidden!important;text-overflow:ellipsis!important;text-align:left!important;'+
            '}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-footer .vct-sidebar-logout{flex:1 1 auto!important;}'+
            'html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-footer{'+
                'width:100%!important;max-width:none!important;padding:6px 10px!important;box-sizing:border-box!important;'+
            '}'+
            'html body.vct-sidebar-mobile-open:not(.vct-x) .vct-sidebar-backdrop{'+
                'inset:0 0 0 min(248px,80vw)!important;'+
            '}'+
        '}'+
        '</style>'+

        '<script>'+
        'window.vctSidebarLogout=function(){'+
            'var nodes=document.querySelectorAll(''a,button'');'+
            'for(var i=0;i<nodes.length;i++){'+
                'var n=nodes[i];'+
                'if(n.classList&&n.classList.contains(''vct-sidebar-logout''))continue;'+
                'var t=(n.innerText||n.textContent||'''').replace(/\s+/g,'' '').trim().toLowerCase();'+
                'var a=(n.getAttribute(''aria-label'')||'''').trim().toLowerCase();'+
                'var q=(n.getAttribute(''title'')||'''').trim().toLowerCase();'+
                'if(t===''salir''||a===''salir''||q===''salir''){n.click();return false;}'+
            '}'+
            'return false;'+
        '};'+

        /* Limpia residuos inline de versiones anteriores sin tocar navegacion */
        'window.vctSidebarVisualReset=function(){'+
            'var links=document.querySelectorAll(''#muhleSideBar .vct-sidebar-action'');'+
            'for(var i=0;i<links.length;i++){'+
                'var l=links[i];'+
                'l.style.removeProperty(''border-left'');'+
                'l.style.removeProperty(''border-right'');'+
                'l.style.removeProperty(''padding-left'');'+
                'l.style.removeProperty(''padding-right'');'+
                'l.style.removeProperty(''left'');'+
                'l.style.removeProperty(''right'');'+
                'l.style.removeProperty(''transform'');'+
                'l.style.removeProperty(''box-shadow'');'+
            '}'+
        '};'+
        'if(document.readyState===''loading''){document.addEventListener(''DOMContentLoaded'',window.vctSidebarVisualReset);}else{window.vctSidebarVisualReset();}'+
        'setTimeout(window.vctSidebarVisualReset,100);'+
        '</script>'+

        '<div class="vct-sidebar-backdrop" data-vct-sidebar-backdrop></div>'+
        '<aside id="muhleSideBar" class="vct-sidebar vct-sidebar-option-b vct-sidebar-v8" aria-label="Menu principal">'+
            '<div class="vct-sidebar-head">'+
                '<div class="vct-sidebar-brand" aria-label="Vocaturo">'+
                    '<div class="vct-sidebar-brand-mark">'+
                        '<img src="../img/vct-mark-white.png" alt="V">'+
                    '</div>'+
                '</div>'+
            '</div>'+
            '<nav class="vct-sidebar-nav">'+ISNULL(@HTML_ITEMS,'')+'</nav>'+
            '<div class="vct-sidebar-footer">'+
                '<button type="button" class="vct-sidebar-logout" title="Salir" aria-label="Salir" onclick="return vctSidebarLogout();">'+
                    @LOGOUT_ICON+
                    '<span class="vct-sidebar-text">Salir</span>'+
                '</button>'+
            '</div>'+
        '</aside>'+

        '<nav class="vct-mobile-bottom-nav" aria-label="Navegacion mobile">'+
            ISNULL(@HTML_MOBILE_ITEMS,'')+
            '<button type="button" class="vct-mobile-nav-link vct-mobile-nav-more" data-vct-command="sidebar-toggle" aria-label="Mas opciones">'+
                '<span class="vct-mobile-nav-icon">'+
                    '<svg viewBox="0 0 24 24" aria-hidden="true">'+
                        '<circle cx="5" cy="12" r="1.5"></circle>'+
                        '<circle cx="12" cy="12" r="1.5"></circle>'+
                        '<circle cx="19" cy="12" r="1.5"></circle>'+
                    '</svg>'+
                '</span>'+
                '<span class="vct-mobile-nav-text">Mas</span>'+
            '</button>'+
        '</nav>';
END
GO

PRINT 'OK: VCT_GET_SIDEBAR V8.2 (nombres en el menu movil).';
GO
