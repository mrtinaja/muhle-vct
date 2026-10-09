 
CREATE PROCEDURE [dbo].[M_CONFIG_PREV_SECTORES]
(
    @IPKEYJOB       AS VARCHAR(100),
    @IUSERID        AS VARCHAR(100),
    @FORM_ID        AS VARCHAR(100),
    @PS_TITULO      AS VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO  AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @VONCLICK_NUEVO VARCHAR(MAX);
    DECLARE @HTML NVARCHAR(MAX);
    DECLARE @HTML_NIVEL1 NVARCHAR(MAX);
    DECLARE @HTML_NIVEL2 NVARCHAR(MAX);
    DECLARE @HTML_USUARIOS NVARCHAR(MAX);
    DECLARE @IMG_HEADER_LOGO NVARCHAR(MAX);
 
    SET @VONCLICK_NUEVO =
        'almacenarSeleccion(''ID_SECTOR_SEL'',''0'');almacenarSeleccion(''ACTION'',''AGREGAR'');goto(''' +
        @FORM_ID +
        ''',''BB9BCDF4-39AD-4118-8AE1-C25BCA95FBD1'');';
 
    SET @HTML = N'';
    SET @HTML_NIVEL1 = N'';
    SET @HTML_NIVEL2 = N'';
    SET @HTML_USUARIOS = N'';
 
    SET @IMG_HEADER_LOGO =
        N'<img src="../img/logo.jpg" alt="Logo Vocaturo" style="width:108px;height:96px;object-fit:contain;display:block;" />';
 
    /* =========================================================
       HEADER + TABS
       Mantiene el lenguaje visual de Admin.
       La segunda tab se abre dinámicamente al pulsar Ver usuarios.
       ========================================================= */
    SET @PS_TITULO = CAST('' AS VARCHAR(MAX)) + '
    <link rel="stylesheet" href="../css/admin.css?v=6.0"/>
    <link rel="stylesheet" href="../css/vct-Tabs.css"/><link rel="stylesheet" href="../css/vct-Table.css?v=18.0.0"/>
 
    <section class="vct-module"
             data-vct-module
             data-vct-tabs
             data-vct-default-tab="tree"
             data-vct-active-tab="tree">
 
        <header class="vct-module-header">
            <div class="vct-module-heading">
                <div class="vct-module-icon"><i data-lucide="network"></i></div>
                <div class="vct-module-heading-text">
                    <h2 class="vct-module-title">Organización</h2>
                    <p class="vct-module-subtitle">Estructura de jerarquías</p>
                </div>
            </div>
        </header>
 
        <nav class="vct-tabs-bar">
            <div class="vct-tabs-list">
                <button type="button"
                        class="vct-tab is-active"
                        data-vct-tab="tree">
                    <i data-lucide="network"></i>
                    <span data-vct-tab-text>Estructura</span>
                </button>
 
                <button type="button"
                        class="vct-tab"
                        data-vct-tab="group-users"
                        data-vct-dynamic-tab
                        hidden>
                    <span data-vct-tab-icon>
                        <i data-lucide="users"></i>
                    </span>
                    <span data-vct-tab-text data-vct-tab-title>Usuarios asociados</span>
                    <span class="vct-tab-close"
                          data-vct-close-tab="group-users"
                          title="Cerrar"
                          onclick="return vctCerrarUsuariosGrupo(event);">&times;</span>
                </button>
            </div>
        </nav>';
 
    /* =========================================================
       USUARIOS ASOCIADOS
       Se renderizan una sola vez. Luego JS filtra por GroupId.
       No hay goto ni persistencia de ID_GROUP_SEL.
       ========================================================= */
    SELECT DISTINCT
        CONVERT(VARCHAR(100), GUM.GroupId) AS GroupId,
        ISNULL(CONVERT(NVARCHAR(200), U.Id), N'') AS Usuario,
        ISNULL(CONVERT(NVARCHAR(300), U.Name), N'') AS Nombre,
        ISNULL(CONVERT(NVARCHAR(300), U.Email), N'') AS Email,
        CASE WHEN ISNULL(CONVERT(INT, U.State), 0) = 1
             THEN N'Activo' ELSE N'Inactivo' END AS Estado
    INTO #VctSectorUsers
    FROM dbo.GroupsUserMembers GUM
    INNER JOIN dbo.Users U ON U.Id = GUM.UserMemberId
    WHERE EXISTS (
        SELECT 1 FROM dbo.Groups G
        WHERE G.Id = GUM.GroupId AND G.Id NOT IN ('SQUAD','GERENCIA')
    );
    DECLARE @VGRID_USERS VARCHAR(MAX);
    EXEC dbo.vct_RenderGrid
        @TempTableName = '#VctSectorUsers',
        @FormId = @FORM_ID,
        @ActionsJson = '[]',
        @PageSize = 10,
        @HiddenColumns = 'GroupId',
        @ScriptVersion = '18.0.0',
        @RenderMode = 'OUTPUT',
        @HTML = @VGRID_USERS OUTPUT;
    SET @HTML_USUARIOS = ISNULL(@VGRID_USERS, '');
    DROP TABLE #VctSectorUsers;
    /* =========================================================
       NIVEL 2 - PERFILES / SECTORES
       ========================================================= */
    SELECT @HTML_NIVEL2 = ISNULL((
        SELECT
            N'<li>' +
                N'<div class="vct-sector-card" ' +
                     N'data-sector-group-id="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(100), G.ID), N''), N'&', N'&amp;'), N'"', N'&quot;'), N'<', N'&lt;'), N'>', N'&gt;') +
                     N'" data-sector-group-name="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(200), G.NAME), N''), N'&', N'&amp;'), N'"', N'&quot;'), N'<', N'&lt;'), N'>', N'&gt;') +
                     N'" style="border-left-color:#8C1D40!important;background-color:#FAFAFA!important;">' +
 
                    N'<div class="vct-sector-header">' +
                        N'<div class="vct-sector-title-wrapper">' +
                            N'<span class="vct-sector-icon" style="background-color:#F8FAFC!important;color:#8C1D40!important;border:1px solid #E2E8F0!important;">' +
                                N'<i data-lucide="building-2" style="width:15px!important;height:15px!important;stroke:#8C1D40!important;"></i>' +
                            N'</span>' +
                            N'<span class="vct-sector-title" style="color:#1e293b!important;font-size:14.5px!important;font-weight:700!important;">' +
                                ISNULL(CONVERT(NVARCHAR(200), G.NAME), N'') +
                            N'</span>' +
                        N'</div>' +
 
                        N'<div class="vct-sector-actions">' +
                            N'<span class="vct-members-badge" title="Integrantes del perfil">' +
                                N'<i data-lucide="users"></i>' +
                                CONVERT(NVARCHAR(20), (
                                    SELECT COUNT(DISTINCT U.ID)
                                    FROM dbo.GroupsUserMembers GUM WITH (NOLOCK)
                                    INNER JOIN dbo.Users U WITH (NOLOCK)
                                        ON U.ID = GUM.UserMemberId
                                    WHERE GUM.GroupId = G.ID
                                )) +
                            N'</span>' +
 
                            N'<button type="button" ' +
                                    N'class="vct-dropdown-btn vct-group-users-btn" ' +
                                    N'title="Ver usuarios asociados" ' +
                                    N'aria-label="Ver usuarios asociados" ' +
                                    N'onclick="return vctAbrirUsuariosGrupo(event,this,''' +
                                        REPLACE(ISNULL(CONVERT(NVARCHAR(100), G.ID), N''), N'''', N'') +
                                    N''');">' +
                                N'<i data-lucide="user-round-search"></i>' +
                                N'<span>Ver usuarios</span>' +
                            N'</button>' +
                        N'</div>' +
                    N'</div>' +
 
                    CASE
                        WHEN ISNULL(CONVERT(NVARCHAR(300), G.EMAIL), N'') <> N'' THEN
                            N'<div class="vct-sector-meta">' +
                                N'<span style="background-color:#F8FAFC!important;color:#8C1D40!important;border:1px solid #E2E8F0!important;padding:3px 10px!important;border-radius:6px!important;font-size:11.5px!important;font-weight:500!important;display:inline-flex!important;align-items:center!important;gap:5px!important;line-height:1.2!important;">' +
                                    N'<i data-lucide="mail" style="width:12px!important;height:12px!important;stroke:#8C1D40!important;"></i> ' +
                                    ISNULL(CONVERT(NVARCHAR(300), G.EMAIL), N'') +
                                N'</span>' +
                            N'</div>'
                        ELSE N''
                    END +
                N'</div>' +
            N'</li>'
        FROM dbo.[Groups] G WITH (NOLOCK)
        WHERE G.ID <> 'SQUAD'
          AND G.ID <> 'GERENCIA'
        ORDER BY G.NAME
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), N'');
 
    /* =========================================================
       NIVEL 1 - GERENCIA
       ========================================================= */
    SELECT @HTML_NIVEL1 = ISNULL((
        SELECT
            N'<li>' +
                N'<div class="vct-sector-card" style="border-left-color:#66062D!important;background-color:#FFFFFF!important;">' +
                    N'<div class="vct-sector-header">' +
                        N'<div class="vct-sector-title-wrapper" onclick="var li=this.closest(''li'');if(li){var n=li.querySelector(''.vct-nested'');var c=this.querySelector(''.vct-caret'');if(n)n.classList.toggle(''active'');if(c)c.classList.toggle(''active'');}">' +
                            N'<span class="vct-caret" style="background-color:#66062D!important;display:inline-flex;align-items:center;justify-content:center;">' +
                                N'<i data-lucide="chevron-right" style="width:14px!important;height:14px!important;stroke:#ffffff!important;color:#ffffff!important;"></i>' +
                            N'</span>' +
                            N'<span class="vct-sector-icon" style="background-color:#FDFBF7!important;color:#66062D!important;border:1px solid #E8C2CA!important;">' +
                                N'<i data-lucide="folder" style="width:15px!important;height:15px!important;stroke:#66062D!important;"></i>' +
                            N'</span>' +
                            N'<span class="vct-sector-title" style="color:#1e293b!important;font-size:14.5px!important;font-weight:700!important;">' +
                                ISNULL(CONVERT(NVARCHAR(200), G.NAME), N'') +
                            N'</span>' +
                        N'</div>' +
                    N'</div>' +
                    CASE
                        WHEN @HTML_NIVEL2 <> N'' THEN N'<ul class="vct-nested">' + @HTML_NIVEL2 + N'</ul>'
                        ELSE N''
                    END +
                N'</div>' +
            N'</li>'
        FROM dbo.[Groups] G WITH (NOLOCK)
        WHERE G.ID = 'GERENCIA'
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), N'');
 
    /* =========================================================
       ROOT
       ========================================================= */
    SET @HTML =
        N'<li>' +
            N'<div class="vct-sector-card special-root">' +
                N'<div class="vct-sector-header">' +
                    N'<div class="vct-sector-title-wrapper" onclick="var li=this.closest(''li'');if(li){var n=li.querySelector(''.vct-nested'');var c=this.querySelector(''.vct-caret'');if(n)n.classList.toggle(''active'');if(c)c.classList.toggle(''active'');}">' +
                        N'<span class="vct-caret vct-root-caret" style="background-color:#66062D!important;display:inline-flex;align-items:center;justify-content:center;">' +
                            N'<i data-lucide="chevron-right" style="width:14px!important;height:14px!important;stroke:#fff!important;color:#fff!important;"></i>' +
                        N'</span>' +
                        @IMG_HEADER_LOGO +
                    N'</div>' +
                N'</div>' +
            N'</div>' +
            CASE
                WHEN @HTML_NIVEL1 <> N'' THEN N'<ul class="vct-nested">' + @HTML_NIVEL1 + N'</ul>'
                ELSE N''
            END +
        N'</li>';
 
    /* =========================================================
       PANELES
       ========================================================= */
    SET @PS_FORMULARIO = CAST(N'' AS NVARCHAR(MAX)) + '
        <div class="vct-panels vct-sector-panels">
 
            <div class="vct-panel is-active"
                 data-vct-panel="tree"
                 aria-hidden="false">
 
                <div class="vct-tree-container">
                    <ul class="vct-tree">' + ISNULL(@HTML, N'') + '</ul>
                </div>
            </div>
 
            <div class="vct-panel"
                 data-vct-panel="group-users"
                 hidden
                 aria-hidden="true">
 
                <div class="vct-group-users-content">
                    <div class="vct-card-perfil-header">
                        <div class="vct-card-perfil-heading">
                            <div class="vct-card-perfil-icon">
                                <i data-lucide="users"></i>
                            </div>
                            <div>
                                <div class="vct-card-perfil-title" id="vctGroupUsersTitle">Usuarios asociados</div>
                                <div class="vct-card-perfil-subtitle" id="vctGroupUsersSubtitle">Seleccione un perfil desde la estructura.</div>
                            </div>
                        </div>
 
                        <span class="vct-group-users-count" id="vctGroupUsersCount">0 integrantes</span>
                    </div>
 
                    <div id="vctSectorUsersGrid">' + ISNULL(@HTML_USUARIOS, N'') + '</div>
                    <p id="vctSectorGridError" role="alert" hidden></p>
                </div>
            </div>
        </div>
        <script src="../js/vct-Core.js"></script>
        <script src="../js/vct-Tabs.js"></script>
        <script src="../js/vct-Table.js"></script>        <script>
(function(){
    function grid(){
        var host=document.getElementById("vctSectorUsersGrid");
        if(!host) return null;
        if(window.VctTable) window.VctTable.init(host);
        var source=host.querySelector("[data-vct-grid-source]");
        var instance=source && source._vctTable;
        if(instance && !instance._sectorAllUsers){
            instance._sectorAllUsers=instance.data.slice();
            instance.data=[];
            instance.sortColumn="Usuario";
            instance.sortDirection=1;
            instance.applySearch();
        }
        return instance;
    }
    function activate(name){
        var host=document.getElementById("vctSectorUsersGrid");
        var module=host && host.closest("[data-vct-tabs]");
        if(!module) return;
        if(window.VctTabs && typeof window.VctTabs.open==="function"){
            window.VctTabs.open(module,name);
        }else{
            module.querySelectorAll("[data-vct-tab]").forEach(function(tab){
                tab.classList.toggle("is-active",tab.getAttribute("data-vct-tab")===name);
            });
            module.querySelectorAll("[data-vct-panel]").forEach(function(panel){
                var active=panel.getAttribute("data-vct-panel")===name;
                panel.classList.toggle("is-active",active);
                panel.hidden=!active;
                panel.setAttribute("aria-hidden",active?"false":"true");
            });
        }
    }
    window.vctAbrirUsuariosGrupo=function(event,button,groupId){
        if(event){event.preventDefault();event.stopPropagation();}
        var card=button.closest("[data-sector-group-id]");
        var module=button.closest("[data-vct-tabs]");
        var name=card ? card.getAttribute("data-sector-group-name") : String(groupId);
        var tab=module.querySelector(''[data-vct-tab="group-users"]'');
        if(tab){
            tab.hidden=false;
            var title=tab.querySelector("[data-vct-tab-title]");
            if(title)title.textContent="Usuarios de "+name;
        }
        document.getElementById("vctGroupUsersTitle").textContent=name;
        document.getElementById("vctGroupUsersSubtitle").textContent="Usuarios asociados al perfil. Orden inicial: Usuario, A-Z.";
        activate("group-users");
        var instance=grid();
        var error=document.getElementById("vctSectorGridError");
        if(!instance){
            error.textContent="No se pudo inicializar la tabla VCT. Verifique la carga de vct-Core.js y vct-Table.js.";
            error.hidden=false;
            return false;
        }
        error.hidden=true;
        instance.data=instance._sectorAllUsers.filter(function(row){
            return String(row.GroupId)===String(groupId);
        });
        instance.searchTerm="";
        if(instance.searchInput)instance.searchInput.value="";
        instance.sortColumn="Usuario";
        instance.sortDirection=1;
        instance.currentPage=1;
        instance.applySearch();
        var total=instance.data.length;
        document.getElementById("vctGroupUsersCount").textContent=total+(total===1?" integrante":" integrantes");
        return false;
    };
    window.vctCerrarUsuariosGrupo=function(event){
        if(event){event.preventDefault();event.stopPropagation();}
        activate("tree");
        var host=document.getElementById("vctSectorUsersGrid");
        var tab=host.closest("[data-vct-tabs]").querySelector(''[data-vct-tab="group-users"]'');
        if(tab)tab.hidden=true;
        return false;
    };
    if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",grid);
    else grid();
})();
        </script>
 
        <style>
            .vct-sector-panels{
                background:#fff;
            }
 
            .vct-tree-container{
                padding:20px 28px;
                font-family:"Gotham","Montserrat",-apple-system,sans-serif;
            }
 
            .vct-tree,.vct-tree ul{
                list-style:none!important;
                padding-left:0!important;
                margin:0!important;
                position:relative!important;
            }
 
            .vct-tree li{
                position:relative!important;
                margin:12px 0!important;
                padding:0!important;
                list-style:none!important;
                overflow:visible!important;
            }
 
            .vct-tree li::before,.vct-tree li::after{
                display:none!important;
                content:none!important;
            }
 
            .vct-tree ul.vct-nested{
                padding-left:48px!important;
                max-height:0;
                opacity:0;
                overflow:visible!important;
                transform:translateY(-4px);
                transition:max-height .3s cubic-bezier(.4,0,.2,1),opacity .2s ease,transform .2s ease;
            }
 
            .vct-tree ul.vct-nested.active{
                max-height:3500px!important;
                opacity:1!important;
                transform:translateY(0)!important;
                margin-top:10px;
                margin-bottom:10px;
            }
 
            .vct-tree ul.vct-nested::before{
                content:""!important;
                position:absolute!important;
                left:28px!important;
                top:-12px!important;
                bottom:30px!important;
                width:2px!important;
                background:linear-gradient(180deg,#e2c7cd,#e2e8f0)!important;
                border-radius:2px!important;
                z-index:1!important;
                display:block!important;
            }
 
            .vct-tree ul.vct-nested > li::before{
                content:""!important;
                display:block!important;
                position:absolute!important;
                left:-20px!important;
                top:-12px!important;
                width:20px!important;
                height:36px!important;
                border-left:2px solid #e2e8f0!important;
                border-bottom:2px solid #e2e8f0!important;
                border-bottom-left-radius:12px!important;
                background:transparent!important;
                z-index:2!important;
            }
 
            .vct-sector-card{
                background:#fff;
                border:1px solid #eef2f6;
                border-left:4px solid #cbd5e1;
                border-radius:14px;
                padding:16px 20px;
                box-shadow:0 1px 3px rgba(15,23,42,.04);
                transition:box-shadow .2s ease,transform .2s ease;
                position:relative;
                z-index:3;
                display:flex;
                flex-direction:column;
                gap:10px;
                overflow:visible!important;
            }
 
            .vct-sector-card:hover{
                box-shadow:0 10px 24px rgba(15,23,42,.08);
                transform:translateY(-2px);
                z-index:10!important;
            }
 
            .vct-sector-card.special-root{
                min-height:92px!important;
                max-width:720px!important;
                padding:18px 28px!important;
                justify-content:center!important;
                background-color:#fff!important;
                border:1px solid #e2e8f0!important;
                border-left:6px solid #66062D!important;
                border-radius:14px!important;
                box-shadow:0 6px 18px rgba(102,6,45,.08)!important;
                overflow:hidden!important;
            }
 
            .vct-sector-card.special-root .vct-sector-header{
                min-height:48px!important;
            }
 
            .vct-sector-header{
                display:flex;
                align-items:center;
                justify-content:space-between;
                gap:12px;
                position:relative;
                z-index:5;
            }
 
            .vct-sector-title-wrapper{
                display:flex;
                align-items:center;
                gap:10px;
                cursor:pointer;
                user-select:none;
                flex-grow:1;
            }
 
            .vct-sector-icon{
                display:inline-flex!important;
                align-items:center!important;
                justify-content:center!important;
                width:28px!important;
                height:28px!important;
                border-radius:8px!important;
                flex-shrink:0!important;
            }
 
            .vct-caret{
                display:inline-flex;
                align-items:center;
                justify-content:center;
                width:24px;
                height:24px;
                border-radius:6px;
                background:#66062D;
                color:#fff;
                transition:transform .25s ease,background-color .2s ease,color .2s ease;
            }
 
            .vct-caret i,.vct-caret svg{
                color:#fff!important;
                stroke:#fff!important;
                width:14px!important;
                height:14px!important;
            }
 
            .vct-caret.active{
                transform:rotate(90deg)!important;
            }
 
            .vct-root-caret{
                width:34px!important;
                height:34px!important;
                border-radius:9px!important;
            }
 
            .vct-sector-meta{
                display:flex!important;
                align-items:center!important;
                gap:6px 10px!important;
                flex-wrap:wrap!important;
                width:100%!important;
            }
 
            .vct-sector-actions{
                display:flex!important;
                align-items:center!important;
                gap:8px!important;
                flex-shrink:0!important;
            }
 
            .vct-members-badge{
                display:inline-flex!important;
                align-items:center!important;
                justify-content:center!important;
                gap:5px!important;
                min-width:34px!important;
                height:28px!important;
                padding:0 9px!important;
                border-radius:999px!important;
                background:#F8FAFC!important;
                color:#66062D!important;
                border:1px solid #E2E8F0!important;
                font-size:11.5px!important;
                font-weight:700!important;
                line-height:1!important;
                box-sizing:border-box!important;
            }
 
            .vct-members-badge svg,.vct-members-badge i{
                width:13px!important;
                height:13px!important;
                stroke:#66062D!important;
            }
 
            .vct-dropdown-btn{
                background:#fff!important;
                border:1px solid #cbd5e1!important;
                color:#333233!important;
                width:28px!important;
                height:28px!important;
                border-radius:6px!important;
                display:flex!important;
                align-items:center!important;
                justify-content:center!important;
                cursor:pointer!important;
                transition:all .2s ease!important;
                box-shadow:0 1px 4px rgba(0,0,0,.15)!important;
            }
 
            .vct-dropdown-btn:hover{
                background:#fff!important;
                color:#66062D!important;
                border-color:#66062D!important;
            }
 
            .vct-group-users-btn{
                width:auto!important;
                min-width:112px!important;
                height:30px!important;
                padding:0 11px!important;
                gap:6px!important;
                border-radius:7px!important;
                font-family:"Gotham","Montserrat",sans-serif!important;
                font-size:11.5px!important;
                font-weight:700!important;
                line-height:1!important;
                white-space:nowrap!important;
                color:#66062D!important;
                border-color:#d8c0ca!important;
                background:#fff!important;
                box-shadow:0 1px 3px rgba(102,6,45,.08)!important;
            }
 
            .vct-group-users-btn:hover{
                background:#fff5f8!important;
                border-color:#8C1D40!important;
                color:#8C1D40!important;
            }
 
            .vct-group-users-btn svg,.vct-group-users-btn i{
                width:15px!important;
                height:15px!important;
                stroke:currentColor!important;
                flex-shrink:0!important;
            }
 
            .vct-group-users-btn span{
                display:inline-block!important;
            }
 
            /* ----- Panel de usuarios ----- */
            .vct-group-users-content{
                padding:18px 20px 26px;
                font-family:"Gotham","Montserrat",-apple-system,sans-serif;
            }
 
            .vct-card-perfil-header{
                display:flex;
                align-items:center;
                justify-content:space-between;
                gap:16px;
                padding:16px 18px;
                margin-bottom:14px;
                background:#fff;
                border:1px solid #e2e8f0;
                border-radius:12px;
                box-shadow:0 1px 3px rgba(15,23,42,.04);
            }
 
            .vct-card-perfil-heading{
                display:flex;
                align-items:center;
                gap:12px;
                min-width:0;
            }
 
            .vct-card-perfil-icon{
                width:38px;
                height:38px;
                border-radius:10px;
                display:inline-flex;
                align-items:center;
                justify-content:center;
                background:#FDF2F6;
                border:1px solid #F3D6DF;
                color:#8C1D40;
                flex:0 0 38px;
            }
 
            .vct-card-perfil-icon svg,.vct-card-perfil-icon i{
                width:18px;
                height:18px;
                stroke:#8C1D40;
            }
 
            .vct-card-perfil-title{
                font-size:14.5px;
                line-height:1.25;
                font-weight:700;
                color:#1e293b;
            }
 
            .vct-card-perfil-subtitle{
                margin-top:3px;
                font-size:11.5px;
                line-height:1.35;
                color:#64748b;
            }
 
            .vct-group-users-count{
                display:inline-flex;
                align-items:center;
                justify-content:center;
                min-height:28px;
                padding:0 10px;
                border-radius:999px;
                border:1px solid #E2E8F0;
                background:#F8FAFC;
                color:#66062D;
                font-size:11.5px;
                font-weight:700;
                white-space:nowrap;
            }
 
            @media (max-width:760px){
                .vct-tree-container{padding:14px 12px;}
                .vct-tree ul.vct-nested{padding-left:28px!important;}
                .vct-tree ul.vct-nested::before{left:16px!important;}
                .vct-tree ul.vct-nested > li::before{left:-12px!important;width:12px!important;}
                .vct-sector-card{padding:14px;}
                .vct-sector-card.special-root{max-width:100%!important;padding:16px!important;}
                .vct-card-perfil-header{align-items:flex-start;flex-direction:column;}
                .vct-group-users-content{padding:14px 12px 22px;}
                .vct-group-users-btn{min-width:32px!important;width:32px!important;padding:0!important;}
                .vct-group-users-btn span{display:none!important;}
            }
 
            @media (max-width:430px){
                .vct-sector-title-wrapper img{width:84px!important;height:auto!important;}
            }
 
            /* Árbol amplio: nombre, contacto y acciones con zonas estables. */
            .vct-sector-panels,
            .vct-sector-panels > [data-vct-panel="tree"],
            .vct-sector-panels .vct-tree-container{
                width:100%!important;
                max-width:none!important;
                min-width:0!important;
                box-sizing:border-box!important;
            }
            .vct-sector-panels .vct-tree-container{
                padding:24px 28px;
                container-type:inline-size;
                container-name:sector-tree;
            }
            .vct-sector-panels .vct-tree,
            .vct-sector-panels .vct-tree ul,
            .vct-sector-panels .vct-tree li{
                width:100%!important;
                max-width:none!important;
                min-width:0!important;
                box-sizing:border-box!important;
            }
            .vct-sector-panels .vct-sector-card,
            .vct-sector-panels .vct-sector-card.special-root{
                width:100%!important;
                max-width:none!important;
                min-width:0!important;
                box-sizing:border-box!important;
                padding:20px 24px!important;
            }
            .vct-sector-panels .vct-sector-card:hover{transform:none!important;}
            .vct-sector-panels .vct-sector-header{min-width:0!important;gap:20px;}
            .vct-sector-panels .vct-sector-title-wrapper{min-width:0!important;gap:12px;}
            .vct-sector-panels .vct-sector-title{
                display:block!important;
                min-width:0!important;
                white-space:normal!important;
                overflow-wrap:anywhere!important;
                line-height:1.45!important;
                text-align:left!important;
            }
            .vct-sector-panels .vct-caret{flex-shrink:0!important;}
            .vct-sector-panels [data-sector-group-id]{
                display:grid!important;
                grid-template-columns:minmax(0,1fr) auto;
                align-items:center;
                gap:10px 24px!important;
            }
            .vct-sector-panels [data-sector-group-id] > .vct-sector-header{display:contents!important;}
            .vct-sector-panels [data-sector-group-id] .vct-sector-title-wrapper{
                grid-column:1;
                grid-row:1;
                cursor:default;
                user-select:text;
            }
            .vct-sector-panels [data-sector-group-id] .vct-sector-actions{
                grid-column:2;
                grid-row:1;
                justify-self:end;
                gap:10px!important;
                flex-wrap:wrap;
            }
            .vct-sector-panels [data-sector-group-id] .vct-sector-meta{
                grid-column:1 / -1;
                grid-row:2;
                min-width:0!important;
                padding-left:40px;
                box-sizing:border-box;
            }
            .vct-sector-panels [data-sector-group-id] .vct-sector-meta > span{
                max-width:100%!important;
                min-width:0!important;
                box-sizing:border-box!important;
                white-space:normal!important;
                overflow-wrap:anywhere!important;
                line-height:1.5!important;
                text-align:left!important;
            }
            .vct-sector-panels .vct-sector-meta svg,
            .vct-sector-panels .vct-sector-meta i{flex-shrink:0!important;}
            .vct-sector-panels .vct-members-badge{height:32px!important;min-width:44px!important;}
            .vct-sector-panels .vct-group-users-btn{height:34px!important;min-width:118px!important;width:auto!important;padding:0 12px!important;}
            .vct-sector-panels .vct-group-users-btn span{display:inline-block!important;}
 
            /* Tres columnas solo cuando el árbol tiene espacio real. */
            @container sector-tree (min-width:1000px){
                .vct-sector-panels [data-sector-group-id]{grid-template-columns:minmax(0,1.2fr) minmax(0,1fr) auto;gap:12px 28px!important;}
                .vct-sector-panels [data-sector-group-id] .vct-sector-meta{grid-column:2;grid-row:1;padding-left:0;}
                .vct-sector-panels [data-sector-group-id] .vct-sector-actions{grid-column:3;grid-row:1;}
            }
            @container sector-tree (max-width:580px){
                .vct-sector-panels .vct-sector-card,
                .vct-sector-panels .vct-sector-card.special-root{padding:16px!important;}
                .vct-sector-panels [data-sector-group-id]{grid-template-columns:minmax(0,1fr);gap:12px!important;}
                .vct-sector-panels [data-sector-group-id] .vct-sector-title-wrapper{grid-column:1;grid-row:1;}
                .vct-sector-panels [data-sector-group-id] .vct-sector-meta{grid-column:1;grid-row:2;padding-left:0;}
                .vct-sector-panels [data-sector-group-id] .vct-sector-actions{grid-column:1;grid-row:3;justify-self:start;}
                .vct-sector-panels .vct-tree ul.vct-nested{padding-left:20px!important;}
                .vct-sector-panels .vct-tree ul.vct-nested::before{left:8px!important;}
                .vct-sector-panels .vct-tree ul.vct-nested > li::before{left:-12px!important;width:12px!important;}
            }
            @media(max-width:760px){
                .vct-sector-panels .vct-tree-container{padding:16px 12px;}
            }
            /* Ancho del árbol en escritorio, centrado dentro del módulo. */
            .vct-sector-panels .vct-tree-container{
                width:75%!important;
                margin-left:auto!important;
                margin-right:auto!important;
            }
            @media(max-width:900px){
                .vct-sector-panels .vct-tree-container{width:100%!important;}
            }
        </style>
 
    </section>';
 
    /* Limpieza de contexto ajeno a esta pantalla. */
    UPDATE M_CONFIG
       SET ID_USER_SEL = NULL,
           ID_TASK_SEL = NULL,
           ID_SECTOR_SEL = NULL,
           ID_ACTION_SEL = NULL,
           NEW_AREA = NULL,
           NEW_ID = NULL,
           NEW_EMAIL = NULL,
           NEW_NAME = NULL,
           NEW_PASSWORD = NULL,
           NEW_ESTADO_CUENTA = NULL,
           NEW_PERFIL = NULL,
           DESC_ERROR = NULL
     WHERE PAR_KEY = @IPKEYJOB;
END
 
