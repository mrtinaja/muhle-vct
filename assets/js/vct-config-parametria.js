/* ========================================================================
   VCT CONFIG PARAMETRIA - V2
   ------------------------------------------------------------------------
   Header con dropdown por categoria (Gestiones / Normas / Proyectos /
   Viáticos), mas breadcrumb debajo -- mismo mecanismo que vct-reportes.js
   (catOf/openDropdown/closeAllDropdowns/activate), re-escrito acá con
   atributos propios de Parametría para no chocar con nada existente.
   Reemplaza al V1 (grupo + subpestaña en 2 barras separadas): el dropdown
   del header hace las veces de la vieja barra de subpestañas, así que ya
   no existe un nivel intermedio de "panel de grupo" -- cada hoja
   (ej. "gestiones-tipos") es directamente un panel de contenido.

   Contrato HTML esperado (lo arma VCT_MAIN_CONFIGURACION):
     <div data-vct-param-root data-vct-config-active="<leaf>">
         <nav class="vct-param-topnav">
             <!-- item directo (categoria de 1 solo item, ej. Normas):
                  data-vct-param-cat Y data-vct-param-group juntos en el
                  MISMO boton -->
             <button data-vct-param-cat="normas" data-vct-param-group="normas">Normas</button>
             <!-- categoria con dropdown: SIN data-vct-param-group propio -->
             <div class="vct-param-topnav-item">
                 <button data-vct-param-cat="gestiones" aria-expanded="false">Gestiones</button>
                 <div class="vct-param-dropdown" data-vct-param-cat-panel="gestiones">
                     <button data-vct-param-group="gestiones-tipos">...</button>
                     ...
                 </div>
             </div>
             ...
         </nav>
         <div class="vct-param-breadcrumb" data-vct-param-breadcrumb></div>
         <div data-vct-param-group-panel="gestiones-tipos">...</div>
         ...
     </div>
   ======================================================================== */
(function (window, document) {
    "use strict";

    /* Un boton de categoria con data-vct-param-group propio (Normas,
       Viáticos) ES a la vez su propio item -- no tiene dropdown. */
    function catOf(root, group) {
        var direct = root.querySelector('[data-vct-param-cat][data-vct-param-group="' + group + '"]');
        if (direct) return direct.getAttribute("data-vct-param-cat");
        var btn = root.querySelector('[data-vct-param-group="' + group + '"]');
        var panel = btn ? btn.closest("[data-vct-param-cat-panel]") : null;
        return panel ? panel.getAttribute("data-vct-param-cat-panel") : null;
    }

    function closeAllDropdowns(root) {
        root.querySelectorAll("[data-vct-param-cat-panel]").forEach(function (panel) {
            panel.classList.remove("is-open");
        });
        root.querySelectorAll("[data-vct-param-cat]").forEach(function (btn) {
            if (!btn.hasAttribute("data-vct-param-group")) btn.setAttribute("aria-expanded", "false");
        });
    }

    function openDropdown(root, cat) {
        var panel = root.querySelector('[data-vct-param-cat-panel="' + cat + '"]');
        if (!panel) return;
        panel.classList.add("is-open");
        var btn = root.querySelector('[data-vct-param-cat="' + cat + '"]');
        if (btn) btn.setAttribute("aria-expanded", "true");
    }

    function updateBreadcrumb(root, cat, group) {
        var bc = root.querySelector("[data-vct-param-breadcrumb]");
        if (!bc) return;
        var catBtn = root.querySelector('[data-vct-param-cat="' + cat + '"]');
        var groupBtn = root.querySelector('[data-vct-param-group="' + group + '"]');
        var catLabel = catBtn ? catBtn.textContent.trim() : "";
        var groupLabel = groupBtn ? groupBtn.textContent.trim() : "";
        var parts = ["Parametría"];
        if (catLabel) parts.push(catLabel);
        if (groupLabel && groupLabel !== catLabel) parts.push(groupLabel);
        bc.textContent = parts.join(" / ");
    }

    function activateTopnav(root, cat) {
        root.querySelectorAll("[data-vct-param-cat]").forEach(function (btn) {
            btn.classList.toggle("is-active", btn.getAttribute("data-vct-param-cat") === cat);
        });
    }

    function activateGroup(root, group) {
        root.querySelectorAll("[data-vct-param-group]").forEach(function (btn) {
            btn.classList.toggle("is-active", btn.getAttribute("data-vct-param-group") === group);
        });
        root.querySelectorAll("[data-vct-param-group-panel]").forEach(function (panel) {
            panel.classList.toggle("is-active", panel.getAttribute("data-vct-param-group-panel") === group);
        });
        root.setAttribute("data-vct-param-active", group);
    }

    function activate(root, group) {
        var cat = catOf(root, group);
        if (cat) {
            activateTopnav(root, cat);
            updateBreadcrumb(root, cat, group);
        }
        activateGroup(root, group);
        closeAllDropdowns(root);
    }

    function init(root) {
        if (root.dataset.vctParamReady === "1") return;
        root.dataset.vctParamReady = "1";

        var initial = root.getAttribute("data-vct-config-active") || root.getAttribute("data-vct-param-active") || "";
        if (!initial || !root.querySelector('[data-vct-param-group="' + initial + '"]')) {
            var firstBtn = root.querySelector("[data-vct-param-group]");
            initial = firstBtn ? firstBtn.getAttribute("data-vct-param-group") : "";
        }
        if (initial) activate(root, initial);

        root.addEventListener("click", function (event) {
            var catBtn = event.target.closest("[data-vct-param-cat]");
            if (catBtn) {
                event.preventDefault();
                var cat = catBtn.getAttribute("data-vct-param-cat");
                var ownGroup = catBtn.getAttribute("data-vct-param-group");
                if (ownGroup) {
                    activate(root, ownGroup);
                } else {
                    var panel = root.querySelector('[data-vct-param-cat-panel="' + cat + '"]');
                    var wasOpen = panel && panel.classList.contains("is-open");
                    closeAllDropdowns(root);
                    if (!wasOpen) openDropdown(root, cat);
                }
                return;
            }

            var groupBtn = event.target.closest("[data-vct-param-group]");
            if (groupBtn && !groupBtn.hasAttribute("data-vct-param-cat")) {
                event.preventDefault();
                activate(root, groupBtn.getAttribute("data-vct-param-group"));
                return;
            }

            if (!event.target.closest("[data-vct-param-cat-panel]")) {
                closeAllDropdowns(root);
            }
        });

        document.addEventListener("click", function (event) {
            if (!root.contains(event.target)) closeAllDropdowns(root);
        });
    }

    function scan(scope) {
        scope = scope || document;
        var roots = [];
        if (scope.matches && scope.matches("[data-vct-param-root]")) roots.push(scope);
        if (scope.querySelectorAll) scope.querySelectorAll("[data-vct-param-root]").forEach(function (r) { roots.push(r); });
        roots.forEach(init);
    }

    scan(document);

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                Array.prototype.forEach.call(m.addedNodes || [], function (n) {
                    if (n && n.nodeType === 1) scan(n);
                });
            });
        }).observe(document.documentElement, { childList: true, subtree: true });
    }
})(window, document);
