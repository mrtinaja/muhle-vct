<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsMain" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <title>Mühle | Vocaturo & Asociados | Panel de Administración</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- 🎨 HOJA DE ESTILOS CENTRAL DEL PANEL -->
    <link rel="stylesheet" href="../css/admin.css?v=20260916-3">

    <!-- 🎨 ÍCONOS LUCIDE -->
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body>

<form id="form1" runat="server">
    <!-- BARRA SUPERIOR -->
    <header class="vct-top-navbar">
        <div class="vct-navbar-left">
            <button type="button" class="vct-btn-hamburger" onclick="toggleSidebar(); return false;" title="Abrir Menú">
                <i data-lucide="menu"></i>
            </button>
            <div class="vct-brand-container">
                <img src="../img/logoBordo.png" alt="Vocaturo">
            </div>
        </div>
        <div class="vct-user-widget">
            <div class="vct-avatar"><img src="../img/avatar2.png" alt="Avatar"></div>
            <div class="vct-user-details">
                <span class="vct-user-subtitle">BIENVENIDO,</span>
                <span class="vct-user-title"><asp:Label id="lblAgentValue" runat="server" Text=""></asp:Label></span>
            </div>
            <a href="#" onclick="logout(event);" class="vct-btn-logout" title="Salir del Sistema">
                <i data-lucide="log-out"></i>
            </a>
        </div>
    </header>

    <div class="vct-sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar();"></div>

    <!-- SIDEBAR DE ÍCONOS LUCIDE NORMALIZADOS -->
    <aside class="vct-sidebar" id="mainSidebar">
        <ul class="vct-sidebar-nav">
            <li class="vct-nav-item nav-link-usuarios">
                <a href="#" onclick="navAction(event, 'usuarios', 'ACTION=USUARIOS', 'Usuarios');" title="Usuarios">
                    <i data-lucide="user"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-grupos">
                <a href="#" onclick="navAction(event, 'grupos', 'ACTION=GRUPOS', 'Perfiles');" title="Perfiles">
                    <i data-lucide="shield-check"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-sectores">
                <a href="#" onclick="navAction(event, 'sectores', 'ACTION=SECTORES', 'Estructura');" title="Estructura">
                    <i data-lucide="network"></i>
                </a>
            </li>
            <!-- Ocultos a pedido: Permisos y Áreas se administran aparte, no van en el sidebar.
            <li class="vct-nav-item nav-link-permisos">
                <a href="#" onclick="navAction(event, 'permisos', 'ACTION=ACCIONES', 'Permisos');" title="Permisos">
                    <i data-lucide="key-round"></i>
                </a>
            </li>
            <li class="vct-nav-item nav-link-areas">
                <a href="#" onclick="navAction(event, 'areas', 'ACTION=AREAS', 'Areas');" title="Áreas">
                    <i data-lucide="layout-grid"></i>
                </a>
            </li>
            -->

            <li class="vct-nav-item nav-link-reportes">
                <a href="#" onclick="navAction(event, 'reportes', 'ACTION=REPORTES', 'Reportes');" title="Reportes">
                    <i data-lucide="pie-chart"></i>
                </a>
            </li>
        </ul>
    </aside>

    <div id="main">
        <div id="loader" class="loading" style="display: none;"><div class="loader"></div></div>
        <div id="mainContainer"></div>
    </div>
</form>

<script src="../lib/jquery/jquery.min.js"></script>

<!-- MOCK DEFENSIVO DATATABLES -->
<script>
    (function($) {
        if (!$) return;
        var mockDT = function() {
            return {
                destroy: function() { return this; },
                draw: function() { return this; },
                clear: function() { return this; },
                rows: function() { return { remove: function() { return this; } }; },
                on: function() { return this; }
            };
        };
        $.fn.DataTable = mockDT;
        $.fn.dataTable = mockDT;
    })(window.jQuery);
</script>

<script src="../lib/jquery-file-upload/vendor/jquery.ui.widget.js"></script>
<script src="../lib/jquery-file-upload/jquery.iframe-transport.js"></script>
<script src="../lib/jquery-file-upload/jquery.fileupload.js"></script>
<script src="../js/main.js?v=20260916-1"></script>

<!-- COMPONENTES CORE VOCATURO SPA -->
<script>
function toggleSidebar() {
    var sidebar = $('#mainSidebar'), overlay = $('#sidebarOverlay');
    if (sidebar.hasClass('open')) { sidebar.removeClass('open'); overlay.fadeOut(200); }
    else { sidebar.addClass('open'); overlay.fadeIn(200); }
}

function closeSidebarOnMobile() {
    if ($(window).width() <= 900) { $('#mainSidebar').removeClass('open'); $('#sidebarOverlay').fadeOut(200); }
}

function setActiveNav(navKey) {
    $('.vct-nav-item').removeClass('active'); $('.nav-link-' + navKey).addClass('active');
}

function navAction(e, navKey, actionParam, titleParam) {
    if (e && e.preventDefault) e.preventDefault();
    setActiveNav(navKey);

    if (window.VctTabEngine && typeof window.VctTabEngine.resetEngine === 'function') {
        window.VctTabEngine.resetEngine();
    }

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
    $('#mainContainer').hide(); $('#loader').show();
    $.ajax({
        type: 'GET', url: '../logout/', dataType: "text",
        success: function () { window.location.href = '.'; },
        error: function (xhr, status, error) { $('#loader').hide(); }
    });
    return false;
}

// Re-inicialización dinámica de Lucide tras cada llamada AJAX
$(document).ajaxComplete(function () {
    if (window.lucide) {
        lucide.createIcons();
    }
});

$(document).ready(function () {
    if (window.lucide) lucide.createIcons();
    loadHome();
});
</script>
</body>
</html>
