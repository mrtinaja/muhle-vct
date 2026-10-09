/* vct-proyecto-plan.js - v2 (cronograma, pendientes del cliente, exportar)
   ============================================================================
   Seccion "Plan Estrategico" de la Vista 360 de Proyecto.
   El SP (dbo.VCT_PROYECTO_PLAN_RENDER) arma la seccion y los formularios;
   alta/edicion usan los comandos estandar (open-modal-empty /
   open-modal-data + validate-next). Aca solo:
     - Abrir / cerrar el detalle de cada item (gestiones) y recordarlo
       despues de guardar.
     - Filtro por estado (chips) y buscador.
     - Titulo del modal en open-modal-data (el motor no lo actualiza).
     - Etiqueta del date picker cuando el valor llega desde la fila.
     - Confirmar "Quitar item".
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoPlanLoaded) return;
    window.__vctProyectoPlanLoaded = true;

    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    function storeKey() {
        var bc = document.querySelector(".vct-breadcrumb-current");
        return "vctPlanOpen:" + (bc ? bc.textContent.trim() : "");
    }

    function openIds() {
        try { return JSON.parse(sessionStorage.getItem(storeKey()) || "[]"); } catch (e) { return []; }
    }

    function saveIds(ids) {
        try { sessionStorage.setItem(storeKey(), JSON.stringify(ids)); } catch (e) {}
    }

    function setOpen(box, id, open) {
        var row = box.querySelector('[data-plan-item="' + id + '"]');
        var det = box.querySelector('[data-plan-detail="' + id + '"]');
        if (!row || !det) return;
        det.hidden = !open;
        row.classList.toggle("is-open", open);
        var t = row.querySelector("[data-vct-plan-toggle]");
        if (t) t.setAttribute("aria-expanded", open ? "true" : "false");
    }

    /* ---------- filtro: chip de estado + texto (tabla y cronograma) ---------- */
    function applyFilter(box) {
        var chip = box.querySelector(".vct-plan-chip.is-active");
        var estado = chip ? chip.getAttribute("data-plan-filter") : "";
        var input = box.querySelector("[data-vct-plan-filter]");
        var q = norm(input ? input.value : "");
        function match(el) {
            return (!estado || el.getAttribute("data-plan-estado") === estado) &&
                   (!q || norm(el.getAttribute("data-plan-text")).indexOf(q) >= 0);
        }
        box.querySelectorAll(".vct-plan-row").forEach(function (row) {
            var ok = match(row);
            row.style.display = ok ? "" : "none";
            var det = box.querySelector('[data-plan-detail="' + row.getAttribute("data-plan-item") + '"]');
            if (det) det.style.display = ok ? "" : "none";
        });
        box.querySelectorAll(".vct-gantt-row").forEach(function (row) {
            row.style.display = match(row) ? "" : "none";
        });
    }

    /* ---------- vista: tabla / cronograma ---------- */
    function viewKey() { return storeKey().replace("vctPlanOpen:", "vctPlanView:"); }

    function setView(box, view, remember) {
        box.querySelectorAll("[data-plan-pane]").forEach(function (p) {
            p.hidden = p.getAttribute("data-plan-pane") !== view;
        });
        box.querySelectorAll("[data-plan-view]").forEach(function (b) {
            b.classList.toggle("is-active", b.getAttribute("data-plan-view") === view);
        });
        if (remember) { try { sessionStorage.setItem(viewKey(), view); } catch (e) {} }
    }

    /* ---------- exportar (VCTExport de vct-export.js: .xlsx / .pdf reales) ---------- */
    function dmy(iso) {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso || "");
        return m ? m[3] + "/" + m[2] + "/" + m[1] : "";
    }

    function ensureExport(cb) {
        if (window.VCTExport) return cb();
        var s = document.createElement("script");
        s.src = "../js/vct-export.js?v=1";
        s.onload = function () { cb(); };
        s.onerror = function () {
            if (window.VCT && VCT.Toast) VCT.Toast.show("No se pudo cargar el exportador.", "error");
        };
        document.head.appendChild(s);
    }

    function exportPlan(box, kind) {
        var rows = [];
        box.querySelectorAll(".vct-plan-row").forEach(function (r) {
            var a = function (k) { return r.getAttribute(k) || ""; };
            var cod = a("data-vct-pi-cod");
            rows.push([
                Number(a("data-vct-pi-n")) || "",
                /[^0-9]/.test(cod) ? cod : "",
                a("data-vct-pi-tit"),
                a("data-vct-pi-resp"),
                dmy(a("data-vct-pi-ini")),
                dmy(a("data-vct-pi-fin")),
                dmy(a("data-vct-pi-real")),
                a("data-x-est"),
                Number(a("data-x-av")) || 0,
                a("data-x-g"),
                Number(a("data-x-tm")) || 0,
                a("data-vct-pi-obs")
            ]);
        });
        var spec = {
            title: box.getAttribute("data-plan-titulo") || "Plan Estrategico",
            subtitle: box.getAttribute("data-plan-resumen") || "",
            filename: (box.getAttribute("data-plan-titulo") || "Plan_Estrategico").replace(/[^A-Za-z0-9]+/g, "_").slice(0, 80),
            orientation: "landscape",
            columns: [
                { title: "N°", align: "right", width: 5 },
                { title: "Código", type: "text", width: 8 },
                { title: "Ítem", width: 40 },
                { title: "Responsables", width: 20 },
                { title: "Inicio", align: "center", width: 11 },
                { title: "Fin", align: "center", width: 11 },
                { title: "Fin real", align: "center", width: 11 },
                { title: "Estado", width: 11 },
                { title: "Avance %", align: "right", width: 9 },
                { title: "Gestiones", type: "text", align: "center", width: 9 },
                { title: "Tiempo %", align: "right", width: 9 },
                { title: "Observaciones", width: 40 }
            ],
            rows: rows
        };
        ensureExport(function () {
            var p = kind === "pdf" ? VCTExport.pdf(spec) : VCTExport.excel(spec);
            if (p && p.catch) p.catch(function () {
                if (window.VCT && VCT.Toast) VCT.Toast.show("No se pudo generar el archivo.", "error");
            });
        });
    }

    document.addEventListener("click", function (e) {
        var toggle = e.target.closest("[data-vct-plan-toggle]");
        if (toggle) {
            var box = toggle.closest("[data-vct-plan]") || document;
            var row = toggle.closest("[data-plan-item]");
            if (!row) return;
            var id = row.getAttribute("data-plan-item");
            var det = box.querySelector('[data-plan-detail="' + id + '"]');
            var open = det ? det.hidden : false;
            setOpen(box, id, open);
            var ids = openIds().filter(function (x) { return x !== id; });
            if (open) ids.push(id);
            saveIds(ids);
            return;
        }

        var vb = e.target.closest("[data-plan-view]");
        if (vb && vb.closest("[data-vct-plan-views]")) {
            setView(vb.closest("[data-vct-plan]") || document, vb.getAttribute("data-plan-view"), true);
            return;
        }

        var ex = e.target.closest("[data-vct-plan-export]");
        if (ex) {
            var eb = ex.closest("[data-vct-plan]");
            if (eb) exportPlan(eb, ex.getAttribute("data-vct-plan-export"));
            return;
        }

        var chip = e.target.closest("[data-plan-filter]");
        if (chip && chip.closest("[data-vct-plan-chips]")) {
            var b = chip.closest("[data-vct-plan]") || document;
            b.querySelectorAll(".vct-plan-chip").forEach(function (c) { c.classList.toggle("is-active", c === chip); });
            applyFilter(b);
        }
    });

    document.addEventListener("input", function (e) {
        if (e.target.hasAttribute && e.target.hasAttribute("data-vct-plan-filter")) {
            var box = e.target.closest("[data-vct-plan]");
            if (box) applyFilter(box);
        }
    });

    document.addEventListener("keydown", function (e) {
        if (e.key === "Enter" && e.target.hasAttribute && e.target.hasAttribute("data-vct-plan-filter")) e.preventDefault();
    });

    /* ---------- captura en window: corre antes que el motor ---------- */
    window.addEventListener("click", function (e) {
        var el = e.target.closest && e.target.closest("[data-vct-command]");
        if (!el) return;
        var cmd = (el.getAttribute("data-vct-command") || "").toLowerCase();
        var target = el.getAttribute("data-vct-target") || "";

        /* open-modal-data no actualiza el titulo del formulario */
        if (cmd === "open-modal-data" && target.indexOf("vctPlan") === 0) {
            var modal = document.getElementById(target);
            if (modal && window.VCT && VCT.DomForm && typeof VCT.DomForm.setHeader === "function")
                VCT.DomForm.setHeader(modal, el);
            return;
        }

        if (cmd === "validate-next" && el.closest("[data-vct-plan-quitar]")) {
            if (!window.confirm("¿Quitar este ítem del plan?")) {
                e.preventDefault();
                e.stopImmediatePropagation();
            }
        }
    }, true);

    /* ---------- date picker: etiqueta cuando el valor viene de la fila ---------- */
    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    document.addEventListener("change", function (e) {
        var input = e.target;
        if (!input || !input.classList || !input.classList.contains("vct-datepicker-native")) return;
        if (!input.closest("#vctPlanItem, #vctPlanGestion")) return;
        var wrap = input.closest(".vct-datepicker");
        var label = wrap && wrap.querySelector(".vct-datepicker-value");
        if (!label) return;
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(input.value || "");
        if (m) {
            label.textContent = m[3] + "/" + m[2] + "/" + m[1];
            label.classList.remove("is-placeholder");
        } else {
            label.textContent = input.getAttribute("placeholder") || "Seleccionar fecha";
            label.classList.add("is-placeholder");
        }
    }, true);

    /* ---------- al cargar: detalles abiertos y foco en el plan ---------- */
    function boot() {
        document.querySelectorAll("[data-vct-plan]").forEach(function (box) {
            if (box.dataset.planReady === "1") return;
            box.dataset.planReady = "1";
            var ids = openIds();
            ids.forEach(function (id) { setOpen(box, id, true); });
            var view = null;
            try { view = sessionStorage.getItem(viewKey()); } catch (e) {}
            if (view === "gantt" && box.querySelector('[data-plan-pane="gantt"]')) setView(box, "gantt", false);
            if (box.querySelector(".vct-lanz-alert")) {
                setTimeout(function () {
                    try { box.scrollIntoView({ behavior: "smooth", block: "start" }); } catch (e) {}
                }, 120);
            }
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
