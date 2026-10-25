<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsMain" %>
<!DOCTYPE html>
<html lang="es">
    <head>
        <title>Mühle | Main</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="../css/w3.css"/>
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.3/css/all.css">
        <link rel="stylesheet" href="../lib/DataTables/datatables.min.css" />
        <link rel="stylesheet" href="../css/font-awesome-5-all.css"/>
        <link rel="stylesheet" href="../css/sw2/sweetalert2.min.css"/>
        <link rel="stylesheet" href="../css/progress-wizard.min.css"/>
        <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon"/>
        <link rel="icon" href="../favicon.ico" type="image/x-icon"/>
        <link rel="stylesheet" href="/css/vct-main.css">
        <link rel="stylesheet" href="/css/vct-shell.css">
        <%-- FOUC fix: CSS de grilla + de cada pantalla precargado en el head (evita flash al inyectar la pantalla). --%>
        <link rel="stylesheet" href="/css/vct-datagrid.css?v=50">
        <link rel="stylesheet" href="/css/vct-datepicker.css?v=50">
        <link rel="stylesheet" href="/css/vct-inicio.css?v=5">
        <link rel="stylesheet" href="/css/vct-acciones.css?v=21">
        <link rel="stylesheet" href="/css/vct-calendario.css?v=47">
        <link rel="stylesheet" href="/css/vct-reportes.css?v=32">
        <link rel="stylesheet" href="/css/vct-config-parametria.css?v=10">
        <link rel="stylesheet" href="/css/vct-email-template-designer.css?v=31">
        <link rel="stylesheet" href="/css/vct-proyecto-v360.css?v=40">
    </head>
    <body class="w3-light-grey">

        <!------ BARRA SUPERIOR ------>
        <div id="muhleTopBar" class="w3-bar w3-top w3-muhle-topbar">
            <div class="vct-header-right-container">

                <!-- USUARIO INFORMATIVO: NO ABRE PERFIL / NO ES CLICKABLE -->
                <div class="vct-user-widget" aria-label="Usuario actual">
                    <span id="vctUserInitials" class="vct-user-initials" aria-hidden="true">--</span>

                    <div class="vct-user-details">
                        <span id="vctUserFullName" class="vct-user-fullname"></span>

                        <!-- Control obligatorio del framework. Se conserva intacto. -->
                        <span id="fullname" class="vct-framework-fullname"><asp:Label id="lblAgentValue" runat="server" Text=""></asp:Label></span>
                    </div>
                </div>

                <span class="vct-header-user-divider" aria-hidden="true"></span>

                <!-- BOTÓN DE SALIR: reutiliza logout() nativa del framework. -->
                <button type="button"
                        class="vct-logout-button"
                        onclick="logout();"
                        title="Salir del Sistema"
                        aria-label="Salir del Sistema">
                    <svg class="vct-logout-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                        <path d="M14 8L18 12L14 16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M18 12H8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                        <path d="M10 5H6.8C5.81 5 5 5.81 5 6.8V17.2C5 18.19 5.81 19 6.8 19H10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                    </svg>
                    <span>Salir</span>
                </button>
            </div>
        </div>

        <div id="muhlePopup" class="w3-hide">
            <span class="closebtn" onclick="this.parentElement.style.display='none';">&times;</span>
            <span id="muhlePopupMessage">This is an alert box.</span>
        </div>

        <!------ CONTENIDO DINÁMICO ------>
        <div id="main" class="w3-main">
            <div class="w3-container" style="padding:0 !important;">
                <div id="loader" class="loading" style="display: none;"><div class="loader"></div></div>
                <div id="mainContainer" class="w3-light-grey"></div>
            </div>
        </div>

        <!-- OVERLAY DE CARGA GLOBAL (AJAX). Ver vct-loading-overlay.js -->
        <div id="vct-loading-overlay" class="vct-loading-overlay">
            <div class="vct-spinner"></div>
        </div>

        <script src="../lib/jquery/jquery.min.js"></script>
        <script src="../lib/jquery-file-upload/vendor/jquery.ui.widget.js"></script>
        <script src="../lib/jquery-file-upload/jquery.iframe-transport.js"></script>
        <script src="../lib/jquery-file-upload/jquery.fileupload.js"></script>
        <script src="../lib/DataTables/datatables.min.js"></script>
        <script src="../lib/easy-timer/easytimer.min.js"></script>
        <script src="../lib/tableToExcel/tableToExcel.js"></script>
        <%-- AUDITORIA: Google Maps API quitada (no se usaba en MAIN: sin google.maps.*, sin mapa, sin initMap) --%>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.3/Chart.min.js"></script>
        <script src="../css/sw2/sweetalert2.all.min.js"></script>
        <script src="../css/sw2/sweetalert2.min.js"></script>
        <script src="../js/main.js"></script>
        <script src="../js/vct-main.js"></script>
        <script src="../js/vct-loading-overlay.js"></script>
        <script>
        try {
            var full_name = document.getElementById("fullname").innerText.trim();

            /* Iniciales para el nuevo header. Se calculan antes de conservar
               el comportamiento existente que muestra solamente el primer nombre. */
            var initialsNode = document.getElementById("vctUserInitials");
            if(initialsNode && full_name && full_name !== "") {
                var initials = "";

                if(full_name.indexOf(',') !== -1) {
                    var nameParts = full_name.split(',');
                    var surnamePart = (nameParts[0] || "").trim();
                    var givenPart = (nameParts[1] || "").trim();
                    initials = (givenPart.charAt(0) + surnamePart.charAt(0)).toUpperCase();
                } else {
                    var cleanParts = full_name.split(/\s+/).filter(function(item){ return item !== ""; });
                    if(cleanParts.length >= 2) {
                        initials = (cleanParts[0].charAt(0) + cleanParts[cleanParts.length - 1].charAt(0)).toUpperCase();
                    } else if(cleanParts.length === 1) {
                        initials = cleanParts[0].substring(0,2).toUpperCase();
                    }
                }

                initialsNode.innerText = initials || "--";
            }

            /* Copia visual del nombre completo para el nuevo shell.
               #fullname se conserva intacto para compatibilidad del framework. */
            var fullNameDisplay = document.getElementById("vctUserFullName");
            if(fullNameDisplay) {
                fullNameDisplay.innerText = full_name || "";
            }

            if(full_name && full_name !== "") {
                if(full_name.indexOf(',') !== -1) {
                    var name = full_name.split(',')[1].trim();
                    document.getElementById("fullname").innerHTML = name.split(' ')[0];
                } else {
                    document.getElementById("fullname").innerHTML = full_name.split(' ')[0];
                }
            }
        } catch(e) { console.log(e); }

        function loadHome() {
            try {
                /* Inicio es la pantalla inicial del framework.
                   Limpiamos únicamente el estado visual persistido del sidebar
                   para que una sesión anterior (por ejemplo Clientes) no pueda
                   quedar activa cuando el dashboard se vuelve a cargar. */
                try {
                    window.sessionStorage.removeItem('VCT_SIDEBAR_SELECTED_MODULE');
                    window.sessionStorage.removeItem('VCT_SIDEBAR_ACTIVE_SELECTION');
                } catch(ignore) {}

                try {
                    window.VCT_ACTIVE_MODULE = '';
                    document.documentElement.removeAttribute('data-vct-active');
                } catch(ignore) {}

                newTaskForContactWithParams('VOCATURO', 'ACTION=INICIO', 'VCT_GESTION', 'Inicio');
            } catch(err) {
                console.warn("Mühle loadHome fallback:", err);
                $('#mainContainer').empty();
            }
        }

        function profile() {
            $('#mainContainer').hide();
            $('#loader').show();
            $.ajax({
                type: 'GET',
                url: '../profile/',
                dataType: "text",
                success: function (data) {
                    $("#mainContainer").html(data);
                    $('#loader').hide();
                    $("#mainContainer").show();
                    refreshLucideIcons();
                },
                error: function (httpReq, status, exception) {
                    console.log(status + " " + exception);
                    $('#loader').hide();
                    $('#mainContainer').show();
                }
            });
        }

        function logout() {
            $('#mainContainer').hide();
            $('#loader').show();
            $.ajax({
                type: 'GET',
                url: '../logout/',
                dataType: "text",
                success: function (data) {
                    window.location.href = '../';
                },
                error: function (httpReq, status, exception) {
                    console.log(status + " " + exception);
                    $('#loader').hide();
                }
            });
        }

        function refreshLucideIcons() {
            if (typeof lucide !== 'undefined') {
                lucide.createIcons();
            }
        }

        $(document).ready(function () {
            loadHome();
            refreshLucideIcons();
            setTimeout(refreshLucideIcons, 300);
            setTimeout(refreshLucideIcons, 800);
        });

        $(document).ajaxComplete(function() {
            setTimeout(refreshLucideIcons, 150);
        });
        </script>
    </body>
</html>
