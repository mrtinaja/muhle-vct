/* vct-notif.js - v3 NOTIF_ACC_V1 (Visita sin registrar / Horas excedidas: van a la V360 del proyecto)
   v2 (decodifica acentos escritos como entidades en titulo / subtitulo del header)
   ============================================================================
   Campanita de notificaciones en el header de todas las pantallas.
   - dbo.VCT_GET_HEADER trae la campanita (dbo.VCT_NOTIF_RENDER) dentro de
     [data-vct-notif-holder]; aca se mueve al topbar (#muhleTopBar), a la
     izquierda de las iniciales del usuario. Si la pantalla nueva no trae
     campanita (sin notificaciones), se saca la anterior.
   - Abre / cierra el panel (clic afuera o Escape cierra).
   - Clic en una notificacion: va a Acciones, a la pestania que indica
     data-vct-notif-tab (vencidas / hoy / proximas / todas). Usa el mismo
     mecanismo de pestania recordada de vct-main.js (VCT.Tabs) y la opcion
     Acciones del sidebar.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctNotifLoaded) return;
    window.__vctNotifLoaded = true;

    function topBox() { return document.querySelector("#muhleTopBar .vct-header-right-container"); }

    /* titulo / subtitulo del header: si llegan como texto "seg&uacute;n" se muestran con el acento */
    var decoder = document.createElement("textarea");
    function fixEntities() {
        var roots = document.querySelectorAll("#vctAppHeader, #muhleTopBar");
        Array.prototype.forEach.call(roots, function (root) {
            var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false), n;
            while ((n = walker.nextNode())) {
                if (/&(#\d+|[a-zA-Z]+);/.test(n.nodeValue)) {
                    decoder.innerHTML = n.nodeValue;
                    n.nodeValue = decoder.value;
                }
            }
        });
    }

    function place() {
        fixEntities();
        var holders = document.querySelectorAll("[data-vct-notif-holder]");
        if (!holders.length) return;
        var box = topBox();
        var user = box && box.querySelector(".vct-user-widget");
        if (!box || !user) return;
        var src = holders[holders.length - 1];
        var bell = src.querySelector("[data-vct-notif-bell]");
        box.querySelectorAll("[data-vct-notif-bell]").forEach(function (b) {
            if (b !== bell && b.parentNode) b.parentNode.removeChild(b);
        });
        if (bell) box.insertBefore(bell, user);
        var bar = document.getElementById("muhleTopBar");
        if (bar) bar.classList.toggle("vct-has-notif", !!bell);
        Array.prototype.forEach.call(holders, function (h) { if (h.parentNode) h.parentNode.removeChild(h); });
    }

    function panel(open) {
        var bell = document.querySelector("#muhleTopBar [data-vct-notif-bell]");
        if (!bell) return;
        var p = bell.querySelector("[data-vct-notif-panel]");
        var btn = bell.querySelector("[data-vct-notif-toggle]");
        if (!p) return;
        var o = typeof open === "boolean" ? open : p.hidden;
        p.hidden = !o;
        if (btn) btn.setAttribute("aria-expanded", o ? "true" : "false");
    }

    function goAcciones(tab) {
        tab = tab || "todas";
        var VCT = window.VCT;
        /* ya esta en Acciones: solo cambia de pestania */
        var root = document.querySelector("[data-vct-acc]");
        if (root && root.offsetParent !== null && VCT && VCT.Tabs && typeof VCT.Tabs.activate === "function") {
            VCT.Tabs.activate(root, tab);
            window.scrollTo(0, 0);
            return;
        }
        var menu = Array.prototype.filter.call(document.querySelectorAll("#muhleSideBar [onclick]"), function (el) {
            return (el.getAttribute("onclick") || "").indexOf("'ACTION=ACCIONES'") >= 0;
        })[0];
        if (!menu) return;
        if (VCT && VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab(tab);
        menu.click();
    }

    /* v3: abre la V360 del proyecto (mismo camino que el Inicio: cliente en IDSELEC01, proyecto en IDSELEC02)
       en la pestania que indica data-vct-notif-v360 (agenda = Visitas) */
    function goProyecto(link) {
        var VCT = window.VCT;
        var proy = link.getAttribute("data-vct-notif-proy"), cli = link.getAttribute("data-vct-notif-cli") || "";
        var guid = link.getAttribute("data-vct-notif-guid"), tab = link.getAttribute("data-vct-notif-v360") || "";
        if (!proy || !guid || !VCT || !VCT.Buffer || !VCT.Action) { goAcciones(link.getAttribute("data-vct-notif-tab")); return; }
        if (tab && VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab(tab);
        Promise.resolve(VCT.Buffer.store("IDSELEC01", cli === "0" ? "" : cli)).then(function () {
            return new Promise(function (r) { setTimeout(r, 250); });
        }).then(function () {
            var b = document.createElement("button");
            b.type = "button";
            b.hidden = true;
            b.setAttribute("data-vct-command", "grid-action");
            b.setAttribute("data-vct-store", "IDSELEC02");
            b.setAttribute("data-vct-value", proy);
            b.setAttribute("data-vct-guid", guid);
            (document.querySelector("[data-vct-form-id]") || document.body).appendChild(b);
            VCT.Action.execute(b);
        });
    }

    document.addEventListener("keydown", function (e) { if (e.key === "Escape") panel(false); });

    document.addEventListener("click", function (e) {
        var t = e.target;
        if (!t || !t.closest) return;
        if (t.closest("[data-vct-notif-toggle]")) { e.preventDefault(); panel(); return; }
        var link = t.closest("[data-vct-notif-tab]");
        if (link) {
            e.preventDefault();
            panel(false);
            if (link.getAttribute("data-vct-notif-proy")) goProyecto(link);
            else goAcciones(link.getAttribute("data-vct-notif-tab"));
            return;
        }
        if (!t.closest("[data-vct-notif-panel]")) panel(false);
    });

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", place);
    else place();

    /* SPA: cada pantalla trae su header */
    if (window.MutationObserver) {
        var pend = false;
        new MutationObserver(function () {
            if (pend) return;
            pend = true;
            setTimeout(function () { pend = false; place(); }, 30);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }

    window.VCTNotif = { version: 3, place: place, go: goAcciones, proyecto: goProyecto };
})(window, document);
