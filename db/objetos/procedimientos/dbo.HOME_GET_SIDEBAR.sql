 
CREATE PROCEDURE [dbo].[HOME_GET_SIDEBAR]
(
    @IUNIDAD      AS VARCHAR(100),
    @IAGENTE      AS VARCHAR(100),
    @FORM_ID      AS VARCHAR(100) = NULL,
    @OSIDEBAR     AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @HTML_ITEMS VARCHAR(MAX) = '';
 
    DECLARE @S_HOME VARCHAR(300) = '<i class="vct-sb-icon vct-sb-home"></i>';
    DECLARE @S_PROJ VARCHAR(300) = '<i class="vct-sb-icon vct-sb-proj"></i>';
    DECLARE @S_CONF VARCHAR(300) = '<i class="vct-sb-icon vct-sb-conf"></i>';
    DECLARE @S_CLIE VARCHAR(300) = '<i class="vct-sb-icon vct-sb-clie"></i>';
    DECLARE @S_PROV VARCHAR(300) = '<i class="vct-sb-icon vct-sb-prov"></i>';
    DECLARE @S_USER VARCHAR(300) = '<i class="vct-sb-icon vct-sb-user"></i>';
    DECLARE @S_OFFE VARCHAR(300) = '<i class="vct-sb-icon vct-sb-offe"></i>';
    DECLARE @S_CALE VARCHAR(300) = '<i class="vct-sb-icon vct-sb-cale"></i>';
    DECLARE @S_CLOC VARCHAR(300) = '<i class="vct-sb-icon vct-sb-cloc"></i>';
    DECLARE @S_REPO VARCHAR(300) = '<i class="vct-sb-icon vct-sb-repo"></i>';
 
    DECLARE @CATALOGO TABLE
    (
        ORDEN       INT,
        SideBarId   VARCHAR(50),
        ModuleId    VARCHAR(50),
        TITULO      VARCHAR(100),
        SVG_ICON    VARCHAR(MAX),
        MODO_CALL   VARCHAR(20),
        PARAMS      VARCHAR(250),
        MODULE_CODE VARCHAR(50)
    );
 
    INSERT INTO @CATALOGO
        (ORDEN, SideBarId, ModuleId, TITULO, SVG_ICON, MODO_CALL, PARAMS, MODULE_CODE)
    VALUES
        (1, '1', 'portal', 'Inicio', @S_HOME, 'PORTAL',
 'ACTION=INICIO',
 'VCT_GESTION_1'),
       (2, '2', 'proyectos', 'Proyectos', @S_PROJ, 'PARAMS',
 'ACTION=INICIO;SOLAPA=PROYECTO',
 'VCT_GESTION_1'),
        (3,  '3',  'parametria', 'Parametria',  @S_CONF, 'DIRECT', 'SV_01',                                      'Parametria'),
        (4,  '4',  'clientes',   'Clientes',    @S_CLIE, 'DIRECT', 'SV_02',                                      'Alta de Clientes'),
        (5,  '5',  'ventas',     'Proveedores', @S_PROV, 'DIRECT', 'SV_03',                                      'Alta de Proveedores'),
        (6,  '6',  'procesos',   'Usuarios',    @S_USER, 'DIRECT', 'SV_04',                                      'Alta Empleados/Consultores'),
        (7,  '7',  'inventario', 'Propuestas',  @S_OFFE, 'PARAMS', 'ACTION=COTIZACIONES',                        'Propuestas'),
        (8,  '8',  'informes',   'Calendario',  @S_CALE, 'PARAMS', 'ACTION=AGENDA_GENERAL',                      'Agenda General'),
        (9,  '9',  'dashboard',  'Agenda',      @S_CLOC, 'PARAMS', 'ACTION=AGENDA_CONSULTOR',                    'Agenda Consultor'),
        (10, '10', 'encuestas',  'Reportes',    @S_REPO, 'DIRECT', 'SV_05',                                      'Reportes');
 
    SELECT @HTML_ITEMS = ISNULL((
        SELECT
            '<a id="vct_mod_' + C.ModuleId + '" href="#" onclick="' +
            CASE
                WHEN C.MODO_CALL = 'PORTAL' THEN
                    'vctSetActiveModule(''' + C.ModuleId + ''');loadHome();return false;'
                WHEN C.MODO_CALL = 'PARAMS' THEN
                    'vctSetActiveModule(''' + C.ModuleId + ''');newTaskForContactWithParams(''VOCATURO'',''' + C.PARAMS + ''',''XAGENDA'',''' + C.MODULE_CODE + ''');return false;'
                ELSE
                    'vctSetActiveModule(''' + C.ModuleId + ''');newTaskForContact(''VOCATURO'',''' + C.PARAMS + ''',''' + C.MODULE_CODE + ''');return false;'
            END + '" class="vct-sidebar-link" data-vct-mod="' + C.ModuleId + '">' +
                '<span class="vct-sidebar-icon">' + C.SVG_ICON + '</span>' +
                '<span class="vct-sidebar-text">' + C.TITULO + '</span>' +
            '</a>'
        FROM @CATALOGO C
        WHERE EXISTS (
            SELECT 1
            FROM dbo.GroupsUserMembers GUM WITH (NOLOCK)
                INNER JOIN dbo.SideBarGroups SBG WITH (NOLOCK)
                    ON SBG.GroupId = GUM.GroupId
            WHERE UPPER(LTRIM(RTRIM(GUM.UserMemberId))) = UPPER(LTRIM(RTRIM(@IAGENTE)))
              AND SBG.SideBarId = C.SideBarId
        )
        ORDER BY C.ORDEN
        FOR XML PATH(''), TYPE
    ).value('.', 'VARCHAR(MAX)'), '');
 
    SET @OSIDEBAR = '
    <style>
        #muhleSideBar.vct-sidebar{background-color:#66062D!important;width:60px!important;height:calc(100vh - 60px)!important;position:fixed!important;top:60px!important;left:0!important;z-index:1050!important;display:flex!important;flex-direction:column!important;align-items:flex-start!important;padding:0!important;margin:0!important;box-shadow:4px 0 16px rgba(0,0,0,0.18)!important;transition:width 0.22s ease!important;overflow:hidden!important;box-sizing:border-box!important;}
        #muhleSideBar.vct-sidebar:hover{width:190px!important;}
        #muhleSideBar .vct-sidebar-link{display:flex!important;align-items:center!important;justify-content:flex-start!important;width:100%!important;height:46px!important;padding:0!important;margin:0!important;color:rgba(255,255,255,0.75)!important;text-decoration:none!important;transition:background-color 0.15s ease,color 0.15s ease!important;white-space:nowrap!important;position:relative!important;box-sizing:border-box!important;border-left:4px solid transparent!important;}
        #muhleSideBar .vct-sidebar-link:hover{color:#fff!important;background-color:rgba(255,255,255,0.15)!important;}
        #muhleSideBar .vct-sidebar-link.active{color:#fff!important;background-color:rgba(0,0,0,0.3)!important;border-left-color:#fff!important;font-weight:700!important;}
        #muhleSideBar .vct-sidebar-icon{display:flex!important;align-items:center!important;justify-content:center!important;width:56px!important;min-width:56px!important;height:46px!important;flex-shrink:0!important;color:inherit!important;margin:0!important;padding:0!important;}
        #muhleSideBar .vct-sidebar-text{display:inline-block!important;font-size:13px!important;font-weight:600!important;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif!important;color:#fff!important;opacity:0!important;transition:opacity 0.18s ease!important;white-space:nowrap!important;}
        #muhleSideBar.vct-sidebar:hover .vct-sidebar-text{opacity:1!important;}
    </style>
 
    <div id="muhleSideBar" class="vct-sidebar">
        ' + ISNULL(@HTML_ITEMS, '') + '
    </div>
 
    <script>
        function vctInjectSidebarSVGs() {
            var map = {
                "vct-sb-home": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>'',
                "vct-sb-proj": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>'',
                "vct-sb-conf": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>'',
                "vct-sb-clie": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>'',
                "vct-sb-prov": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>'',
                "vct-sb-user": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 21a8 8 0 0 0-12 0"/><circle cx="12" cy="10" r="5"/><path d="M19 11l1 1"/><path d="M19 8v.01"/></svg>'',
                "vct-sb-offe": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>'',
                "vct-sb-cale": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>'',
                "vct-sb-cloc": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>'',
                "vct-sb-repo": ''<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>''
            };
 
            for (var c in map) {
                document.querySelectorAll("i." + c).forEach(function(el) {
                    el.outerHTML = map[c];
                });
            }
        }
 
        function vctSetActiveModule(m) {
            if (!m) return;
            localStorage.setItem("VCT_ACTIVE_MODULE", m);
            document.querySelectorAll("#muhleSideBar .vct-sidebar-link").forEach(function(e) {
                if (e.getAttribute("data-vct-mod") === m) e.classList.add("active");
                else e.classList.remove("active");
            });
        }
 
        setTimeout(function() {
            vctInjectSidebarSVGs();
            var a = localStorage.getItem("VCT_ACTIVE_MODULE") || "portal";
            vctSetActiveModule(a);
        }, 50);
    </script>';
END
