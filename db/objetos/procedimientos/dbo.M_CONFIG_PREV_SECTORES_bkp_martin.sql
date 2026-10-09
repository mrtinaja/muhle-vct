create PROCEDURE [dbo].[M_CONFIG_PREV_SECTORES_bkp_martin]
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
 
    /* =========================================================
       1. ESTILOS PORTAL VOCATURO (vct-) PARA ÁRBOL Y USUARIOS
       ========================================================== */
    SET @PS_TITULO = '
    <style>
        body, ul, li { margin: 0; padding: 0; }
        
        #myUL {
            font-size: 13px !important;
            color: #1e293b !important;
            list-style-type: none;
            padding: 0;
        }
 
        #myUL li {
            position: relative;
            margin: 0px !important;
            padding-left: 28px;
            list-style: none;
        }
 
        #myUL li::before {
            content: "";
            position: absolute;
            top: 0 !important;
            left: 12px;
            bottom: 0;
            border-left: 1px dashed #cbd5e1;
        }
 
        #myUL li::after {
            content: "";
            position: absolute;
            top: 22px;
            left: 12px;
            width: 16px;
            border-top: 1px dashed #cbd5e1;
            opacity: 0.8;
        }
 
        #myUL li:last-child::before {
            height: 22px;
            bottom: auto;
        }
 
        #myUL > li::before, #myUL > li::after {
            content: none;
        }
 
        .background-container {
            background: transparent !important;
            width: 100%;
            padding: 4px 0;
            box-sizing: border-box;
        }
 
        /* Card del Sector / Grupo */
        .sector-tree-card {
            background: #ffffff !important;
            border-radius: 12px !important;
            border: 1px solid #e2e8f0 !important;
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.04) !important;
            padding: 12px 18px !important;
            min-width: 300px;
            max-width: 420px;
            margin: 8px 0 !important;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: flex-start;
            transition: all 0.2s ease;
        }
 
        .sector-tree-card:hover {
            border-color: #cbd5e1 !important;
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.08) !important;
        }
 
        /* Card del Usuario (Sub-nodo) */
        .user-tree-card {
            background: #f8fafc !important;
            border-radius: 10px !important;
            border: 1px solid #cbd5e1 !important;
            padding: 8px 14px !important;
            min-width: 260px;
            max-width: 380px;
            margin: 6px 0 !important;
            display: flex;
            flex-direction: column;
            align-items: flex-start;
        }
 
        .sector-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            width: 100%;
        }
 
        .sector-title {
            color: #1e293b !important;
            font-weight: 700;
            font-size: 13px;
            display: flex;
            align-items: center;
        }
 
        .vct-tree-logo {
            max-height: 28px;
            width: auto;
            object-fit: contain;
            vertical-align: middle;
			margin-bottom:2px;
        }
 
        .user-title {
            color: #334155 !important;
            font-weight: 600;
            font-size: 12px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
 
        .sector-meta {
            font-size: 11px;
            color: #64748b;
            margin-top: 2px;
            font-weight: 500;
        }
 
        .caret {
            cursor: pointer;
            user-select: none;
        }
 
        .caret::before {
            content: "\25B6";
            color: #66062C !important;
            display: inline-block;
            margin-right: 8px;
            font-size: 11px;
            transition: transform .2s ease;
        }
 
        .caret.caret-down::before {
            transform: rotate(90deg);
        }
 
        .nested {
            display: none !important;
            margin-left: 12px !important;
        }
 
        .nested.active {
            display: block !important;
        }
 
        .bullet::before {
            content: "•";
            color: #66062C !important;
            font-size: 16px;
            margin-right: 8px;
            line-height: 1;
        }
 
        .dropdown {
            position: relative;
            display: inline-block;
            cursor: pointer;
        }
 
        .dropdown-toggle {
            color: #94a3b8 !important;
            padding: 4px 8px;
            border-radius: 6px;
            transition: background 0.2s;
        }
 
        .dropdown-toggle:hover {
            color: #66062C !important;
            background: #f1f5f9;
        }
 
        .dropdown-content {
            display: none;
            position: absolute;
            top: 24px;
            right: 0;
            background-color: #ffffff;
            min-width: 160px;
            box-shadow: 0 10px 25px rgba(15, 23, 42, 0.12);
            z-index: 9999;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            padding: 4px;
        }
 
        .dropdown-content a {
            color: #334155 !important;
            padding: 8px 12px;
            text-decoration: none;
            display: block;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            cursor: pointer;
        }
 
        .dropdown-content a:hover {
            background-color: #f8fafc;
            color: #66062C !important;
        }
    </style>
 
    <div class="vct-header-card">
        <div class="vct-header-bar">
            <div class="vct-header-title">
                <i class="fa fa-bezier-curve"></i>
                <span>Estructura Organización</span>
            </div>
        </div>
    </div>';
 
    /* =========================================================
       2. ARMADO DEL ÁRBOL: GRUPOS Y SUS USUARIOS INTEGRADOS
       ========================================================== */
    DECLARE @HTML NVARCHAR(MAX) = N'';
    DECLARE @group_id VARCHAR(100), @group_name NVARCHAR(200), @group_email NVARCHAR(300);
    DECLARE @HTML_USERS NVARCHAR(MAX), @has_users INT;
 
    CREATE TABLE #TMP_GROUPS(HTML NVARCHAR(MAX));
 
    -- Recorrido filtrado de los sectores/grupos
    DECLARE curGroups CURSOR LOCAL FOR
        SELECT ISNULL(Id, ''), ISNULL(Name, ''), ISNULL(email, '')
        FROM Groups WITH (NOLOCK)
        WHERE ISNULL(Name, '') <> ''
          AND Id NOT IN ('ESTRUCPLAN', 'EP_EJECUTIVOS', 'SQUAD')
        ORDER BY Name;
 
    OPEN curGroups;
    FETCH NEXT FROM curGroups INTO @group_id, @group_name, @group_email;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @HTML_USERS = N'';
        SET @has_users = 0;
 
        SELECT @HTML_USERS = STRING_AGG(
            CAST(
                N'<li>' +
                    N'<div class="user-tree-card">' +
                        N'<div class="user-title"><i class="fas fa-user-circle" style="color: #66062C;"></i> ' + ISNULL(U.Name, '') + N'</div>' +
                        N'<span class="sector-meta"><i class="far fa-envelope"></i> ' + ISNULL(U.Email, '-') + N'</span>' +
                    N'</div>' +
                N'</li>' AS NVARCHAR(MAX)
            ), 
            N''
        )
        FROM GroupsUserMembers GUM WITH (NOLOCK)
        INNER JOIN Users U WITH (NOLOCK) ON U.Id = GUM.UserMemberId
        WHERE GUM.GroupId = @group_id;
 
        IF ISNULL(@HTML_USERS, N'') <> N'' 
            SET @has_users = 1;
 
        INSERT INTO #TMP_GROUPS(HTML)
        VALUES(N'<li>' +
            N'<div class="sector-tree-card">' +
            N'<div class="sector-header">' +
            N'<span class="sector-title ' + CASE WHEN @has_users = 1 THEN N'caret' ELSE N'bullet' END + N'">' + ISNULL(@group_name, N'') + N'</span>' +
            N'<div class="dropdown">' +
            N'<i class="fas fa-ellipsis-v dropdown-toggle"></i>' +
            N'<div class="dropdown-content">' +
            N'<a onclick="almacenarSeleccion(''ID_GROUP_SEL'', '''+@group_id+''');goto('''+@FORM_ID+''',''4091398D-5D55-4C84-BF0A-4A67E4D0EE0A'');">Ver Usuarios</a>' +
            N'<a onclick="almacenarSeleccion(''ID_GROUP_SEL'', '''+@group_id+''');almacenarSeleccion(''ACTION'', ''EDITAR'');goto('''+@FORM_ID+''',''BB9BCDF4-39AD-4118-8AE1-C25BCA95FBD1'');">Editar Grupo</a>' +
            N'</div></div></div>' +
            N'<span class="sector-meta"><i class="far fa-envelope"></i> ' + ISNULL(@group_email, N'-') + N'</span>' +
            N'<span class="sector-meta"><i class="fas fa-key"></i> ID: ' + ISNULL(@group_id, N'') + N'</span></div>' +
            
            CASE WHEN @has_users = 1 THEN N'<ul class="nested">' + @HTML_USERS + N'</ul>' ELSE N'' END +
            
            N'</li>');
 
        FETCH NEXT FROM curGroups INTO @group_id, @group_name, @group_email;
    END;
 
    CLOSE curGroups; DEALLOCATE curGroups;
 
    SELECT @HTML = STRING_AGG(
        CAST(HTML AS NVARCHAR(MAX)), 
        N''
    ) 
    FROM #TMP_GROUPS;
    
    DROP TABLE #TMP_GROUPS;
 
    /* =========================================================
       3. ARMADO DEL HTML FINAL Y DELEGACIÓN DE EVENTOS JS
       ========================================================== */
    SET @PS_FORMULARIO = '
    <div class="background-container">
      <ul id="myUL">
        <li>
          <div class="sector-tree-card" style="border-left: 4px solid #66062C !important;">
            <div class="sector-header">
              <span class="sector-title caret caret-down">
                <img src="../img/logo.jpg" alt="Logo" class="vct-tree-logo" />
              </span>
              <div class="dropdown">
                <i class="fas fa-ellipsis-v dropdown-toggle"></i>
                <div class="dropdown-content">
                  <a onclick="almacenarSeleccion(''ID_GROUP_SEL'', ''0'');almacenarSeleccion(''ACTION'', ''AGREGAR'');goto('''+@FORM_ID+''',''BB9BCDF4-39AD-4118-8AE1-C25BCA95FBD1'');">Agregar Grupo</a>
                </div>
              </div>
            </div>
          </div>
          <ul class="nested active">' + ISNULL(@HTML, N'') + '</ul>
        </li>
      </ul>
    </div>
 
    <script>
    (function() {
      window.vctCloseAllDropdowns = function() {
        var dropdowns = document.querySelectorAll(".dropdown-content");
        dropdowns.forEach(function(dd) { dd.style.display = "none"; });
      };
 
      document.body.removeEventListener("click", window.vctTreeHandler);
      window.vctTreeHandler = function(e) {
        var toggleBtn = e.target.closest(".dropdown-toggle");
        if (toggleBtn) {
          e.preventDefault();
          e.stopPropagation();
          var menu = toggleBtn.parentElement.querySelector(".dropdown-content");
          var isOpen = menu && menu.style.display === "block";
          window.vctCloseAllDropdowns();
          if (menu) menu.style.display = isOpen ? "none" : "block";
          return;
        }
 
        if (e.target.closest(".dropdown-content")) {
          window.vctCloseAllDropdowns();
          return;
        }
 
        window.vctCloseAllDropdowns();
 
        var caretElem = e.target.closest(".caret");
        if (caretElem) {
          var li = caretElem.closest("li");
          if (!li) return;
          var nested = li.querySelector(".nested");
          if (!nested) return;
          
          nested.classList.toggle("active");
          caretElem.classList.toggle("caret-down");
        }
      };
 
      document.body.addEventListener("click", window.vctTreeHandler);
    })();
    </script>';
 
    /* =========================================================
       4. RESET CONFIG
       ========================================================== */
    UPDATE M_CONFIG 
    SET ID_GROUP_SEL=NULL, ID_USER_SEL=NULL, ID_TASK_SEL=NULL,
        ID_SECTOR_SEL=NULL, ID_ACTION_SEL=NULL,
        NEW_AREA=NULL, NEW_ID=NULL, NEW_EMAIL=NULL,
        NEW_NAME=NULL, NEW_PASSWORD=NULL,
        NEW_ESTADO_CUENTA=NULL, NEW_PERFIL=NULL, DESC_ERROR=NULL
    WHERE PAR_KEY = @IPKEYJOB;
END
