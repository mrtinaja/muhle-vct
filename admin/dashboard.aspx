<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsMain" %>

<!DOCTYPE html>
<html lang="es">
    <head>
        <title>Mühle | Vocaturo & Asociados | Panel de Administración</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
        <!-- Hojas de estilo base necesarias para W3 y DataTables -->
        <link rel="stylesheet" href="../css/w3.css"/>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
        <link rel="stylesheet" href="../lib/DataTables/datatables.min.css" />
        
        <style>
            * { box-sizing: border-box; }
            html, body, h1, h2, h3, h4, h5 { font-family: "Inter", sans-serif; }
            body { background-color: #f8fafc; margin: 0; padding: 0; overflow-x: hidden; }

            /* 🎯 BARRA NAVEGACIÓN SUPERIOR (BORDÓ) */
            .vct-top-navbar {
                background-color: #66062C;
                height: 60px;
                width: 100%;
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 0 16px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                position: fixed;
                top: 0;
                left: 0;
                z-index: 1001;
            }

            .vct-navbar-left {
                display: flex;
                align-items: center;
                gap: 12px;
            }

            .vct-btn-hamburger {
                display: none; /* Se activa en móvil */
                background: transparent;
                border: none;
                color: #ffffff;
                font-size: 20px;
                cursor: pointer;
                padding: 6px;
                border-radius: 6px;
                transition: background 0.2s;
            }
            .vct-btn-hamburger:hover {
                background: rgba(255, 255, 255, 0.15);
            }

            .vct-brand-container {
                display: flex;
                align-items: center;
                height: 36px;
            }
            .vct-brand-container img {
                height: 100%;
                width: auto;
                object-fit: contain;
            }

            /* DERECHA: USUARIO & SALIR */
            .vct-user-widget {
                display: flex;
                align-items: center;
                gap: 12px;
            }
            .vct-avatar {
                width: 36px;
                height: 40px;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.2);
                border: 2px solid rgba(255, 255, 255, 0.6);
                display: flex;
                align-items: center;
                justify-content: center;
                overflow: hidden
            }
            .vct-avatar img { width: 100%; height: 100%; object-fit: cover; }
            .vct-user-details { display: flex; flex-direction: column; }
            .vct-user-title { color: #ffffff; font-size: 13px; font-weight: 700; line-height: 1.1; }
            .vct-user-subtitle { color: rgba(255, 255, 255, 0.75); font-size: 10px; }
            
            .vct-btn-logout { 
                color: rgba(255, 255, 255, 0.85); 
                font-size: 18px; 
                margin-left: 6px; 
                text-decoration: none;
                padding: 6px 8px;
                border-radius: 8px;
                transition: background 0.2s, color 0.2s;
            }
            .vct-btn-logout:hover {
                color: #ffffff;
                background: rgba(239, 68, 68, 0.3);
            }

            /* 🎯 SIDEBAR DE ÍCONOS (GRIS VOCATURO) */
            .vct-sidebar {
                position: fixed;
                top: 60px; /* Debajo de la barra superior */
                left: 0;
                width: 70px;
                height: calc(100vh - 60px);
                background-color: #1e293b; /* Gris oscuro característico */
                z-index: 1000;
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: 20px 0;
                box-shadow: 4px 0 15px rgba(0,0,0,0.1);
                transition: transform 0.3s ease;
            }

            /* NAVEGACIÓN EN SIDEBAR */
            .vct-sidebar-nav {
                list-style: none;
                margin: 0;
                padding: 0;
                width: 100%;
                display: flex;
                flex-direction: column;
                align-items: center;
                gap: 14px;
            }

            .vct-nav-item {
                width: 100%;
                display: flex;
                justify-content: center;
            }

            .vct-nav-item a {
                color: #94a3b8;
                text-decoration: none;
                width: 46px;
                height: 46px;
                border-radius: 12px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 18px;
                transition: all 0.2s ease;
                cursor: pointer;
            }

            .vct-nav-item a:hover {
                color: #ffffff;
                background: #334155;
            }

            .vct-nav-item.active a {
                color: #ffffff;
                background: #66062C; /* Destacado en bordó */
                box-shadow: 0 4px 10px rgba(102, 6, 44, 0.4);
            }

            /* OVERLAY EN MÓVIL */
            .vct-sidebar-overlay {
                position: fixed;
                top: 60px; left: 0; width: 100%; height: calc(100vh - 60px);
                background: rgba(15, 23, 42, 0.6);
                backdrop-filter: blur(4px);
                z-index: 999;
                display: none;
            }

            /* CONTENIDO PRINCIPAL */
            #main { 
                margin-left: 70px !important; 
                padding: 80px 24px 24px 24px !important; /* Top padding compensation */
                width: calc(100% - 70px) !important; 
                transition: all 0.3s ease;
            }

            /* RESPONSIVE (MÓVIL <= 900px) */
            @media (max-width: 900px) {
                .vct-btn-hamburger {
                    display: flex;
                }

                .vct-user-details {
                    display: none; /* Oculta textos para ahorrar espacio */
                }

                .vct-sidebar {
                    transform: translateX(-100%);
                }

                .vct-sidebar.open {
                    transform: translateX(0);
                }

                #main {
                    margin-left: 0 !important;
                    padding: 75px 14px 20px 14px !important;
                    width: 100% !important;
                }
            }

            /* Loader */
            .loading { position: fixed; top: 0; right: 0; bottom: 0; left: 0; background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(4px); z-index: 9999; }
            .loader { left: 50%; margin-left: -4em; font-size: 10px; border: .8em solid #e2e8f0; border-left: .8em solid #66062C; animation: spin 1.1s infinite linear; }
            .loader, .loader:after { border-radius: 50%; width: 8em; height: 8em; display: block; position: absolute; top: 50%; margin-top: -4.05em; }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

            /* ==========================================================================
               🛡️ COMPATIBILIDAD CON W3.CSS Y ENCABEZADOS DE MÜHLE (#mainContainer)
               ========================================================================== */
            
            #main .w3-container { padding: 0 !important; }

            #mainContainer,
            #mainContainer .w3-content,
            #mainContainer .w3-row,
            #mainContainer .w3-card,
            #mainContainer .w3-card-4,
            #mainContainer [class*="w3-col"] {
                width: 100% !important;
                max-width: 100% !important;
                margin-left: 0 !important;
                margin-right: 0 !important;
                box-sizing: border-box !important;
            }

            #mainContainer .w3-bar {
                display: block !important;
                width: 100% !important;
                clear: both !important;
            }

            #mainContainer .w3-bar::after,
            #mainContainer .w3-row::after {
                content: "" !important;
                display: table !important;
                clear: both !important;
            }

            #mainContainer .w3-bar .w3-bar-item {
                padding: 10px 16px !important;
                float: left !important;
                width: auto !important;
                border: none !important;
                display: block !important;
            }

            #mainContainer .w3-bar .w3-left { float: left !important; }
            #mainContainer .w3-bar .w3-right { float: right !important; }

            #mainContainer .w3-bar-item {
                font-size: 14px !important;
                line-height: 1.5 !important;
            }

            #mainContainer .w3-bar-item i {
                display: inline-block !important;
                vertical-align: middle !important;
            }

            #mainContainer .w3-muhle-color {
                background-color: #66062C !important;
                color: #ffffff !important;
            }

            #mainContainer .dataTables_wrapper {
                width: 100% !important;
                padding: 12px 8px !important;
                overflow-x: auto;
            }

            #mainContainer .dataTables_wrapper table {
                width: 100% !important;
            }

            #mainContainer .dataTables_wrapper .dataTables_length {
                float: left !important;
                margin-top: 5px !important;
                margin-bottom: 10px !important;
            }

            #mainContainer .dataTables_wrapper .dataTables_filter {
                float: right !important;
                margin-top: 5px !important;
                margin-bottom: 10px !important;
            }

            #mainContainer .dataTables_wrapper::after {
                content: "" !important;
                clear: both !important;
                display: table !important;
            }
        </style>    
    </head>
<body>

<form id="form1" runat="server">

    <!-- 🎯 BARRA SUPERIOR (HEADER BORDÓ) -->
    <header class="vct-top-navbar">
        <div class="vct-navbar-left">
            <button type="button" class="vct-btn-hamburger" onclick="toggleSidebar(); return false;" title="Abrir Menú">
                <i class="fa fa-bars"></i>
            </button>
            <div class="vct-brand-container">
                <img src="../img/logoBordo.png" alt="Vocaturo">
            </div>
        </div>

        <div class="vct-user-widget">
            <div class="vct-avatar">
                <img src="../img/avatar2.png" alt="Avatar">
            </div>
            <div class="vct-user-details">
                <span class="vct-user-subtitle">BIENVENIDO,</span>
                <span class="vct-user-title">
                    <asp:Label id="lblAgentValue" runat="server" Text=""></asp:Label>
                </span>
            </div>
            <a href="#" onclick="logout(event);" class="vct-btn-logout" title="Salir del Sistema">
                <i class="fa fa-sign-out-alt"></i>
            </a>
        </div>
    </header>

    <!-- OVERLAY EN MÓVIL -->
    <div class="vct-sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar();"></div>

    <!-- 🎯 SIDEBAR UNIFICADO (GRIS VOCATURO, SOLO ÍCONOS) -->
    <aside class="vct-sidebar" id="mainSidebar">
        <ul class="vct-sidebar-nav">
            <li class="vct-nav-item nav-link-usuarios">
                <a href="#" onclick="navAction(event, 'usuarios', 'ACTION=USUARIOS', 'Usuarios');" title="Usuarios">
                    <i class="fa fa-user"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-grupos">
                <a href="#" onclick="navAction(event, 'grupos', 'ACTION=GRUPOS', 'Usuarios');" title="Grupos">
                    <i class="fa fa-users"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-sectores">
                <a href="#" onclick="navAction(event, 'sectores', 'ACTION=SECTORES', 'Estructura');" title="Estructura">
                    <i class="fa fa-bezier-curve"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-permisos">
                <a href="#" onclick="navAction(event, 'permisos', 'ACTION=ACCIONES', 'Permisos');" title="Permisos">
                    <i class="fas fa-location-arrow"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-areas">
                <a href="#" onclick="navAction(event, 'areas', 'ACTION=AREAS', 'Areas');" title="Áreas">
                    <i class="fas fa-chart-area"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-reportes">
                <a href="#" onclick="navAction(event, 'reportes', 'ACTION=REPORTES', 'Reportes');" title="Reportes">
                    <i class="fas fa-chart-pie"></i>
                </a>
            </li>
        </ul>
    </aside>

    <!-- CONTENEDOR PRINCIPAL -->
    <div id="main">
        <div class="w3-container">
            <div id="loader" class="loading" style="display: none;">
                <div class="loader"></div>
            </div>
            <div id="mainContainer"></div>
        </div>
    </div>

</form>

<script src="../lib/jquery/jquery.min.js"></script>
<script src="../lib/jquery-file-upload/vendor/jquery.ui.widget.js"></script>
<script src="../lib/jquery-file-upload/jquery.iframe-transport.js"></script>
<script src="../lib/jquery-file-upload/jquery.fileupload.js"></script>
<script src="../lib/DataTables/datatables.min.js"></script>
<script src="../js/main.js"></script>

<script>
function toggleSidebar() {
    var sidebar = $('#mainSidebar');
    var overlay = $('#sidebarOverlay');
    
    if (sidebar.hasClass('open')) {
        sidebar.removeClass('open');
        overlay.fadeOut(200);
    } else {
        sidebar.addClass('open');
        overlay.fadeIn(200);
    }
}

function closeSidebarOnMobile() {
    if ($(window).width() <= 900) {
        $('#mainSidebar').removeClass('open');
        $('#sidebarOverlay').fadeOut(200);
    }
}

function setActiveNav(navKey) {
    $('.vct-nav-item').removeClass('active');
    $('.nav-link-' + navKey).addClass('active');
}

function navAction(e, navKey, actionParam, titleParam) {
    if (e && e.preventDefault) e.preventDefault();
    setActiveNav(navKey);
    newTaskForContactWithParams('MUHLE', actionParam, 'M_CONFIG', titleParam);
    closeSidebarOnMobile();
    return false;
}

function loadHome() {
    setActiveNav('usuarios');
    newTaskForContactWithParams('MUHLE', 'ACTION=USUARIOS','M_CONFIG', 'Usuarios');
}

function logout(e) {
    if (e && e.preventDefault) e.preventDefault();
    
    $('#mainContainer').hide();
    $('#loader').show();

    $.ajax({
        type: 'GET',
        url: '../logout/',
        dataType: "text",
        success: function (data) {
            window.location.href = '.';
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
            $('#loader').hide();
        }
    });
    return false;
}

$(document).ready(function () {
    loadHome();
});
</script>

</body>
</html>