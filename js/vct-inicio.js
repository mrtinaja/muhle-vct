/* vct-inicio.js - v4 (campanita: abre bien el panel)
   ============================================================================
   Inicio por perfil (dbo.VCT_MAIN_DASHBOARD). El SP arma las pestanias que
   corresponden a quien entra; aca solo:
     - Cambiar de pestania (y recordar la ultima por usuario).
     - Abrir la Vista 360 de un proyecto: guarda cliente (IDSELEC01) y
       proyecto (IDSELEC02) en el buffer y navega con grid-action.
     - Abrir / cerrar el panel de la campanita (clic afuera o Escape cierra).
       Las notificaciones se marcan vistas al abrir el Inicio (lo hace el SP).
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctInicioLoaded) return;
    window.__vctInicioLoaded = true;

    function key(page) { return "vctInicioTab:" + (page.getAttribute("data-vct-ini-user") || ""); }

    function show(page, name, remember) {
        var panels = page.querySelectorAll("[data-vct-ini-panel]");
        var found = false;
        panels.forEach(function (p) { if (p.getAttribute("data-vct-ini-panel") === name) found = true; });
        if (!found && panels.length) name = panels[0].getAttribute("data-vct-ini-panel");
        panels.forEach(function (p) { p.hidden = p.getAttribute("data-vct-ini-panel") !== name; });
        page.querySelectorAll("[data-vct-ini-tab]").forEach(function (t) {
            var on = t.getAttribute("data-vct-ini-tab") === name;
            t.classList.toggle("is-active", on);
            t.setAttribute("aria-selected", on ? "true" : "false");
        });
        if (remember) { try { sessionStorage.setItem(key(page), name); } catch (e) {} }
    }

    function wait(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

    function openProject(page, el) {
        var proy = el.getAttribute("data-vct-ini-proy");
        var cli = el.getAttribute("data-vct-ini-cli");
        var guid = page.getAttribute("data-vct-ini-guid");
        if (!proy || !guid || !window.VCT || !VCT.Buffer || !VCT.Action) return;
        var r = VCT.Buffer.store("IDSELEC01", cli || "");
        Promise.resolve(r).then(function () { return wait(250); }).then(function () {
            var b = document.createElement("button");
            b.type = "button";
            b.hidden = true;
            b.setAttribute("data-vct-command", "grid-action");
            b.setAttribute("data-vct-store", "IDSELEC02");
            b.setAttribute("data-vct-value", proy);
            b.setAttribute("data-vct-guid", guid);
            page.appendChild(b);
            VCT.Action.execute(b);
        });
    }

    function bell(open, root) {
        var list = root ? [root] : Array.prototype.slice.call(document.querySelectorAll("[data-vct-ini-bell]"));
        list.forEach(function (b) {
            var panel = b.querySelector("[data-vct-ini-bell-panel]");
            var btn = b.querySelector("[data-vct-ini-bell-toggle]");
            var o = typeof open === "boolean" ? open : panel.hidden;
            panel.hidden = !o;
            if (btn) btn.setAttribute("aria-expanded", o ? "true" : "false");
        });
    }

    document.addEventListener("keydown", function (e) { if (e.key === "Escape") bell(false); });

    document.addEventListener("click", function (e) {
        var bt = e.target.closest && e.target.closest("[data-vct-ini-bell-toggle]");
        if (bt) { bell(undefined, bt.closest("[data-vct-ini-bell]")); return; }
        if (!(e.target.closest && e.target.closest("[data-vct-ini-bell-panel]"))) bell(false);

        var tab = e.target.closest && e.target.closest("[data-vct-ini-tab]");
        if (tab) {
            var page = tab.closest("[data-vct-inicio]");
            if (page) show(page, tab.getAttribute("data-vct-ini-tab"), true);
            return;
        }
        var link = e.target.closest && e.target.closest("[data-vct-ini-proy]");
        if (link) {
            var pg = link.closest("[data-vct-inicio]");
            if (pg) {
                e.preventDefault();
                openProject(pg, link);
            }
        }
    });

    function boot() {
        document.querySelectorAll("[data-vct-inicio]").forEach(function (page) {
            if (page.dataset.iniReady === "1") return;
            page.dataset.iniReady = "1";
            var last = null;
            try { last = sessionStorage.getItem(key(page)); } catch (e) {}
            show(page, last || "", false);
        });
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
    else boot();
    if (window.MutationObserver) {
        var pend = false;
        new MutationObserver(function () {
            if (pend) return;
            pend = true;
            setTimeout(function () { pend = false; boot(); }, 40);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }
})(window, document);
