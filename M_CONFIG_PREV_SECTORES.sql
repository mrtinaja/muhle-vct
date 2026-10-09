USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_PREV_SECTORES]    Script Date: 16/9/2026 11:06:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[M_CONFIG_PREV_SECTORES]
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
    SET @PS_TITULO = '
    <link rel="stylesheet" href="../css/admin.css?v=6.0"/>
    <link rel="stylesheet" href="../css/vct-Tabs.css"/>

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
    SELECT @HTML_USUARIOS = ISNULL((
        SELECT
            N'<tr class="vct-group-user-row" data-group-id="' +
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(100), GUM.GroupId), N''), N'&', N'&amp;'), N'"', N'&quot;'), N'<', N'&lt;'), N'>', N'&gt;') +
                N'" style="display:none;">' +
                N'<td class="vct-cell-user">' +
                    REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(200), U.ID), N''), N'&', N'&amp;'), N'<', N'&lt;'), N'>', N'&gt;') +
                N'</td>' +
                N'<td>' +
                    REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(300), U.NAME), N''), N'&', N'&amp;'), N'<', N'&lt;'), N'>', N'&gt;') +
                N'</td>' +
                N'<td>' +
                    CASE
                        WHEN ISNULL(CONVERT(NVARCHAR(300), U.EMAIL), N'') <> N'' THEN
                            REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(300), U.EMAIL), N''), N'&', N'&amp;'), N'<', N'&lt;'), N'>', N'&gt;')
                        ELSE N'<span class="vct-muted">Sin email</span>'
                    END +
                N'</td>' +
                N'<td class="vct-cell-state">' +
                    CASE
                        WHEN ISNULL(CONVERT(INT, U.STATE), 0) = 1 THEN
                            N'<span class="vct-status-badge is-active"><span class="vct-status-dot"></span>Activo</span>'
                        ELSE
                            N'<span class="vct-status-badge is-inactive"><span class="vct-status-dot"></span>Inactivo</span>'
                    END +
                N'</td>' +
            N'</tr>'
        FROM dbo.GroupsUserMembers GUM WITH (NOLOCK)
        INNER JOIN dbo.Users U WITH (NOLOCK)
            ON U.ID = GUM.UserMemberId
        WHERE EXISTS (
            SELECT 1
            FROM dbo.[Groups] G WITH (NOLOCK)
            WHERE G.ID = GUM.GroupId
              AND G.ID <> 'SQUAD'
              AND G.ID <> 'GERENCIA'
        )
        ORDER BY GUM.GroupId, U.NAME, U.ID
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), N'');

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
    SET @PS_FORMULARIO = '
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

                    <div class="vct-table-toolbar">
                        <div class="vct-table-page-size">
                            <select id="vctGroupUsersPageSize"
                                    class="vct-page-size-select"
                                    onchange="vctCambiarTamPaginaUsuariosGrupo();">
                                <option value="10" selected>10 por pág.</option>
                                <option value="25">25 por pág.</option>
                                <option value="50">50 por pág.</option>
                            </select>
                        </div>

                        <div class="vct-table-search-wrap">
                            <i data-lucide="search"></i>
                            <input type="text"
                                   id="vctGroupUsersSearch"
                                   class="vct-table-search"
                                   placeholder="Buscar usuario, nombre o email..."
                                   autocomplete="off"
                                   oninput="vctFiltrarUsuariosGrupo(true);" />
                        </div>
                    </div>

                    <div class="vct-table-wrapper">
                        <div class="vct-table-scroll">
                            <table class="vct-users-table">
                                <thead>
                                    <tr>
                                        <th>Usuario</th>
                                        <th>Nombre</th>
                                        <th>Email</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody id="vctGroupUsersBody">' + ISNULL(@HTML_USUARIOS, N'') + '</tbody>
                            </table>

                            <div class="vct-empty-state" id="vctGroupUsersEmpty" hidden>
                                <div class="vct-empty-icon"><i data-lucide="users"></i></div>
                                <div class="vct-empty-title">Sin usuarios asociados</div>
                                <div class="vct-empty-text">Este perfil no tiene integrantes para mostrar.</div>
                            </div>
                        </div>

                        <div class="vct-users-pagination" id="vctGroupUsersPagination" hidden>
                            <div class="vct-users-pagination-info" id="vctGroupUsersPaginationInfo"></div>
                            <div class="vct-users-pagination-pages" id="vctGroupUsersPaginationPages"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script>
        (function(){
            window.vctSectorSelectedGroupId = "";
            window.vctGroupUsersPage = 1;

            window.vctAbrirUsuariosGrupo = function(event, button, groupId){
                if(event){
                    event.preventDefault();
                    event.stopPropagation();
                }

                groupId = String(groupId || "");
                window.vctSectorSelectedGroupId = groupId;

                var card = button && button.closest ? button.closest("[data-sector-group-id]") : null;
                var groupName = card ? (card.getAttribute("data-sector-group-name") || groupId) : groupId;

                var tab = document.querySelector("[data-vct-tab=\"group-users\"]");
                if(tab){
                    tab.hidden = false;
                    var tabTitle = tab.querySelector("[data-vct-tab-title]");
                    if(tabTitle){
                        tabTitle.textContent = "Usuarios: " + groupName;
                    }
                }

                var title = document.getElementById("vctGroupUsersTitle");
                var subtitle = document.getElementById("vctGroupUsersSubtitle");
                var search = document.getElementById("vctGroupUsersSearch");

                if(title){ title.textContent = "Usuarios asociados"; }
                if(subtitle){ subtitle.textContent = groupName; }
                if(search){ search.value = ""; }
                window.vctGroupUsersPage = 1;

                vctFiltrarUsuariosGrupo(true);

                var module = document.querySelector("[data-vct-tabs]");
                if(window.VctTabs && module){
                    VctTabs.open(module, "group-users");
                }else{
                    vctAbrirPanelUsuariosFallback();
                }

                if(window.lucide && typeof window.lucide.createIcons === "function"){
                    window.lucide.createIcons();
                }

                return false;
            };

            window.vctFiltrarUsuariosGrupo = function(resetPage){
                var groupId = String(window.vctSectorSelectedGroupId || "");
                var search = document.getElementById("vctGroupUsersSearch");
                var pageSizeEl = document.getElementById("vctGroupUsersPageSize");
                var q = search ? String(search.value || "").toLowerCase().trim() : "";
                var pageSize = pageSizeEl ? parseInt(pageSizeEl.value || "10", 10) : 10;
                var rows = Array.prototype.slice.call(document.querySelectorAll("#vctGroupUsersBody .vct-group-user-row"));
                var filtered = [];
                var totalGroup = 0;

                if(resetPage !== false){
                    window.vctGroupUsersPage = 1;
                }

                rows.forEach(function(row){
                    var sameGroup = String(row.getAttribute("data-group-id") || "") === groupId;
                    if(sameGroup){ totalGroup++; }

                    var matchesSearch = !q || String(row.textContent || "").toLowerCase().indexOf(q) >= 0;
                    var matches = sameGroup && matchesSearch;
                    row.style.display = "none";
                    if(matches){ filtered.push(row); }
                });

                var totalFiltered = filtered.length;
                var totalPages = Math.max(1, Math.ceil(totalFiltered / pageSize));
                if(window.vctGroupUsersPage > totalPages){ window.vctGroupUsersPage = totalPages; }
                if(window.vctGroupUsersPage < 1){ window.vctGroupUsersPage = 1; }

                var startIndex = (window.vctGroupUsersPage - 1) * pageSize;
                var endIndex = Math.min(startIndex + pageSize, totalFiltered);

                filtered.slice(startIndex, endIndex).forEach(function(row){
                    row.style.display = "";
                });

                var count = document.getElementById("vctGroupUsersCount");
                if(count){
                    if(q){
                        count.textContent = totalFiltered + " de " + totalGroup + " integrantes";
                    }else{
                        count.textContent = totalGroup + (totalGroup === 1 ? " integrante" : " integrantes");
                    }
                }

                var empty = document.getElementById("vctGroupUsersEmpty");
                var table = document.querySelector(".vct-users-table");
                var pagination = document.getElementById("vctGroupUsersPagination");
                if(empty){ empty.hidden = totalFiltered !== 0; }
                if(table){ table.style.display = totalFiltered === 0 ? "none" : "table"; }
                if(pagination){ pagination.hidden = totalFiltered === 0; }

                var info = document.getElementById("vctGroupUsersPaginationInfo");
                if(info){
                    if(totalFiltered === 0){
                        info.textContent = "";
                    }else{
                        info.textContent = "Mostrando " + (startIndex + 1) + " a " + endIndex + " de " + totalFiltered + " registros";
                    }
                }

                vctRenderPaginasUsuariosGrupo(totalPages);
            };

            window.vctCambiarTamPaginaUsuariosGrupo = function(){
                window.vctGroupUsersPage = 1;
                vctFiltrarUsuariosGrupo(false);
            };

            window.vctIrPaginaUsuariosGrupo = function(page){
                var p = parseInt(page, 10);
                if(!isFinite(p)){ return false; }
                window.vctGroupUsersPage = p;
                vctFiltrarUsuariosGrupo(false);
                return false;
            };

            window.vctRenderPaginasUsuariosGrupo = function(totalPages){
                var host = document.getElementById("vctGroupUsersPaginationPages");
                if(!host){ return; }

                host.innerHTML = "";
                if(totalPages <= 0){ return; }

                var current = window.vctGroupUsersPage || 1;

                function addButton(label, page, disabled, active){
                    var btn = document.createElement("button");
                    btn.type = "button";
                    btn.className = "vct-page-btn" + (active ? " is-active" : "");
                    btn.textContent = label;
                    btn.disabled = !!disabled;
                    btn.setAttribute("aria-label", label === "‹" ? "Página anterior" : (label === "›" ? "Página siguiente" : "Página " + label));
                    btn.onclick = function(){ return vctIrPaginaUsuariosGrupo(page); };
                    host.appendChild(btn);
                }

                addButton("‹", current - 1, current <= 1, false);

                var pages = [];
                if(totalPages <= 7){
                    for(var i=1;i<=totalPages;i++){ pages.push(i); }
                }else{
                    pages.push(1);
                    if(current > 4){ pages.push("..."); }
                    var from = Math.max(2, current - 1);
                    var to = Math.min(totalPages - 1, current + 1);
                    for(var p=from;p<=to;p++){ pages.push(p); }
                    if(current < totalPages - 3){ pages.push("..."); }
                    pages.push(totalPages);
                }

                pages.forEach(function(p){
                    if(p === "..."){
                        var dots = document.createElement("span");
                        dots.className = "vct-page-dots";
                        dots.textContent = "…";
                        host.appendChild(dots);
                    }else{
                        addButton(String(p), p, false, p === current);
                    }
                });

                addButton("›", current + 1, current >= totalPages, false);
            };

            window.vctAbrirPanelUsuariosFallback = function(){
                var tabs = document.querySelectorAll("[data-vct-tab]");
                var panels = document.querySelectorAll("[data-vct-panel]");

                tabs.forEach(function(t){
                    t.classList.toggle("is-active", t.getAttribute("data-vct-tab") === "group-users");
                });

                panels.forEach(function(p){
                    var active = p.getAttribute("data-vct-panel") === "group-users";
                    p.classList.toggle("is-active", active);
                    p.hidden = !active;
                    p.setAttribute("aria-hidden", active ? "false" : "true");
                });
            };

            window.vctCerrarUsuariosGrupo = function(event){
                if(event){
                    event.preventDefault();
                    event.stopPropagation();
                }

                var module = document.querySelector("[data-vct-tabs]");
                if(window.VctTabs && module){
                    VctTabs.open(module, "tree");
                }else{
                    document.querySelectorAll("[data-vct-tab]").forEach(function(t){
                        t.classList.toggle("is-active", t.getAttribute("data-vct-tab") === "tree");
                    });

                    document.querySelectorAll("[data-vct-panel]").forEach(function(p){
                        var active = p.getAttribute("data-vct-panel") === "tree";
                        p.classList.toggle("is-active", active);
                        p.hidden = !active;
                        p.setAttribute("aria-hidden", active ? "false" : "true");
                    });
                }

                var tab = document.querySelector("[data-vct-tab=\"group-users\"]");
                if(tab){ tab.hidden = true; }

                window.vctSectorSelectedGroupId = "";
                return false;
            };
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

            .vct-table-toolbar{
                display:flex;
                align-items:center;
                justify-content:space-between;
                margin-bottom:14px;
            }

            .vct-table-page-size{
                flex:0 0 auto;
            }

            .vct-page-size-select{
                height:38px;
                min-width:118px;
                padding:0 32px 0 12px;
                border:1px solid #cbd5e1;
                border-radius:8px;
                background:#fff;
                color:#334155;
                font-family:"Gotham","Montserrat",sans-serif;
                font-size:11.5px;
                font-weight:600;
                outline:none;
                cursor:pointer;
            }

            .vct-page-size-select:focus{
                border-color:#66062D;
                box-shadow:0 0 0 3px rgba(102,6,45,.10);
            }

            .vct-table-search-wrap{
                width:min(420px,100%);
                position:relative;
            }

            .vct-table-search-wrap > svg,.vct-table-search-wrap > i{
                position:absolute;
                left:12px;
                top:50%;
                transform:translateY(-50%);
                width:15px;
                height:15px;
                stroke:#64748b;
                pointer-events:none;
            }

            .vct-table-search{
                width:100%;
                height:38px;
                padding:0 12px 0 36px;
                box-sizing:border-box;
                border:1px solid #cbd5e1;
                border-radius:8px;
                outline:none;
                background:#fff;
                color:#0f172a;
                font-family:"Gotham","Montserrat",sans-serif;
                font-size:12px;
                transition:border-color .18s ease,box-shadow .18s ease;
            }

            .vct-table-search:focus{
                border-color:#66062D;
                box-shadow:0 0 0 3px rgba(102,6,45,.10);
            }

            .vct-table-wrapper{
                border:1px solid #e2e8f0;
                border-radius:12px;
                background:#fff;
                overflow:hidden;
                box-shadow:0 1px 3px rgba(15,23,42,.04);
            }

            .vct-table-scroll{
                overflow:auto;
            }

            .vct-users-pagination{
                display:flex;
                align-items:center;
                justify-content:space-between;
                gap:16px;
                padding:14px 16px;
                border-top:1px solid #eef2f6;
                background:#fff;
            }

            .vct-users-pagination-info{
                color:#64748b;
                font-size:11.5px;
                font-weight:500;
            }

            .vct-users-pagination-pages{
                display:flex;
                align-items:center;
                gap:5px;
            }

            .vct-page-btn{
                min-width:32px;
                height:32px;
                padding:0 9px;
                border:1px solid #dbe3ec;
                border-radius:7px;
                background:#fff;
                color:#475569;
                font-family:"Gotham","Montserrat",sans-serif;
                font-size:11.5px;
                font-weight:700;
                cursor:pointer;
                transition:all .15s ease;
            }

            .vct-page-btn:hover:not(:disabled){
                border-color:#8C1D40;
                color:#66062D;
                background:#fff7fa;
            }

            .vct-page-btn.is-active{
                border-color:#66062D;
                background:#66062D;
                color:#fff;
            }

            .vct-page-btn:disabled{
                opacity:.42;
                cursor:not-allowed;
            }

            .vct-page-dots{
                min-width:24px;
                text-align:center;
                color:#94a3b8;
                font-size:12px;
                font-weight:700;
            }

            .vct-users-table{
                width:100%;
                border-collapse:collapse;
                table-layout:fixed;
                font-family:"Gotham","Montserrat",sans-serif;
            }

            .vct-users-table thead th{
                padding:11px 14px;
                background:#F8FAFC;
                color:#475569;
                border-bottom:1px solid #e2e8f0;
                text-align:left;
                font-size:11px;
                font-weight:700;
                text-transform:uppercase;
                letter-spacing:.03em;
            }

            .vct-users-table tbody td{
                padding:12px 14px;
                border-bottom:1px solid #eef2f6;
                color:#334155;
                font-size:12px;
                line-height:1.35;
                vertical-align:middle;
                overflow-wrap:anywhere;
            }

            .vct-users-table tbody tr:last-child td{
                border-bottom:none;
            }

            .vct-users-table tbody tr:hover td{
                background:#FCFCFD;
            }

            .vct-users-table th:nth-child(1),.vct-users-table td:nth-child(1){width:18%;}
            .vct-users-table th:nth-child(2),.vct-users-table td:nth-child(2){width:32%;}
            .vct-users-table th:nth-child(3),.vct-users-table td:nth-child(3){width:34%;}
            .vct-users-table th:nth-child(4),.vct-users-table td:nth-child(4){width:16%;}

            .vct-cell-user{
                font-weight:700;
                color:#66062D!important;
            }

            .vct-cell-state{
                white-space:nowrap;
            }

            .vct-status-badge{
                display:inline-flex;
                align-items:center;
                gap:6px;
                padding:4px 8px;
                border-radius:999px;
                font-size:10.5px;
                font-weight:700;
                line-height:1;
            }

            .vct-status-badge.is-active{
                background:#ECFDF3;
                color:#166534;
                border:1px solid #BBF7D0;
            }

            .vct-status-badge.is-inactive{
                background:#F8FAFC;
                color:#64748b;
                border:1px solid #E2E8F0;
            }

            .vct-status-dot{
                width:6px;
                height:6px;
                border-radius:50%;
                background:currentColor;
            }

            .vct-muted{
                color:#94a3b8;
                font-style:italic;
            }

            .vct-empty-state{
                padding:54px 20px;
                text-align:center;
                color:#64748b;
            }

            .vct-empty-icon{
                width:42px;
                height:42px;
                margin:0 auto 10px;
                border-radius:12px;
                display:flex;
                align-items:center;
                justify-content:center;
                background:#F8FAFC;
                border:1px solid #E2E8F0;
                color:#8C1D40;
            }

            .vct-empty-icon svg,.vct-empty-icon i{
                width:19px;
                height:19px;
                stroke:#8C1D40;
            }

            .vct-empty-title{
                font-size:13px;
                font-weight:700;
                color:#334155;
            }

            .vct-empty-text{
                margin-top:4px;
                font-size:11.5px;
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
                .vct-users-table{min-width:720px;}
                .vct-table-toolbar{align-items:stretch;gap:10px;}
                .vct-table-page-size{width:100%;}
                .vct-page-size-select{width:100%;}
                .vct-users-pagination{align-items:flex-start;flex-direction:column;}
                .vct-users-pagination-pages{width:100%;justify-content:flex-end;flex-wrap:wrap;}
            }

            @media (max-width:430px){
                .vct-sector-title-wrapper img{width:84px!important;height:auto!important;}
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
