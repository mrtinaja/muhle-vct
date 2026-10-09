

/* =========================================================================
   VCT SIDEBAR RIEL - ACTIVE DEL SIDEBAR NUEVO
   El shell pinta los items como a.vct-sidebar-action[data-vct-mod] (antes
   eran .vct-sidebar-link): applyActive/restore no los encontraban y ningun
   modulo quedaba resaltado. Se extiende SIN tocar el resto de la logica.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT || !window.VCT.Sidebar) return;

    var Sidebar = window.VCT.Sidebar;
    var FORCE_KEY = "VCT_SIDEBAR_SELECTED_MODULE";

    function items() {
        var sidebar = document.getElementById("muhleSideBar");
        return sidebar ? sidebar.querySelectorAll(".vct-sidebar-action[data-vct-mod]") : [];
    }

    function paint(moduleId) {
        moduleId = String(moduleId === null || moduleId === undefined ? "" : moduleId);
        if (!moduleId) return;

        items().forEach(function (item) {
            var on = String(item.getAttribute("data-vct-mod") || "") === moduleId;
            item.classList.toggle("active", on);
            if (on) item.setAttribute("aria-current", "page");
            else item.removeAttribute("aria-current");
        });
    }

    var previous = Sidebar.applyActive;
    Sidebar.applyActive = function (moduleId) {
        if (typeof previous === "function")
            previous.apply(Sidebar, arguments);
        paint(moduleId);
    };

    function restore() {
        var list = items();
        if (!list.length) return;
        if (document.querySelector("#muhleSideBar .vct-sidebar-action.active")) return;

        var moduleId = "";
        try { moduleId = window.sessionStorage.getItem(FORCE_KEY) || ""; } catch (e) {}
        if (!moduleId) moduleId = document.documentElement.getAttribute("data-vct-active") || "";
        if (!moduleId) moduleId = String(window.VCT_ACTIVE_MODULE || "");
        if (!moduleId) moduleId = String(list[0].getAttribute("data-vct-mod") || "");

        paint(moduleId);
    }

    var queued = false;
    new MutationObserver(function () {
        if (queued) return;
        queued = true;
        window.setTimeout(function () { queued = false; restore(); }, 40);
    }).observe(document.documentElement, { childList: true, subtree: true });

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", restore);
    else
        restore();

})(window, document);
