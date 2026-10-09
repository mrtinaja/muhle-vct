/* vct-proyecto-visitas.js - v2
   ============================================================================
   Seccion "Visitas y horas" de la Vista 360 de Proyecto.
   El SP (dbo.VCT_PROYECTO_VISITA_RENDER) arma la seccion y el formulario;
   registrar / editar usan los comandos estandar (open-modal-empty /
   open-modal-data + validate-next). Aca solo:
     - Abrir / cerrar el detalle de una visita registrada.
     - Filtro (chips) y buscador; muestra 15 y "Ver todas".
     - Horas = hasta - desde, al elegir el horario.
     - Titulo del modal en open-modal-data y etiqueta del date picker.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoVisitasLoaded) return;
    window.__vctProyectoVisitasLoaded = true;

    var LIMITE = 15;

    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    /* ---------- filtro: chip + texto, con limite de filas ---------- */
    function applyFilter(box) {
        var chip = box.querySelector("[data-vct-vis-chips] .vct-plan-chip.is-active");
        var f = chip ? chip.getAttribute("data-vis-filter") : "";
        var input = box.querySelector("[data-vct-vis-search]");
        var q = norm(input ? input.value : "");
        var all = box.dataset.visAll === "1" || !!q;
        var n = 0, hidden = 0;
        box.querySelectorAll(".vct-vis-row").forEach(function (row) {
            var ok = (!f || (f === "SINREG" ? row.getAttribute("data-vis-sinreg") === "1" : row.getAttribute("data-vis-g") === f)) &&
                     (!q || norm(row.getAttribute("data-vis-text")).indexOf(q) >= 0);
            if (ok) {
                n++;
                if (!all && n > LIMITE) { ok = false; hidden++; }
            }
            row.style.display = ok ? "" : "none";
            var det = box.querySelector('[data-vis-detail="' + row.getAttribute("data-vis-id") + '"]');
            if (det) det.style.display = ok ? "" : "none";
        });
        var more = box.querySelector("[data-vct-vis-more]");
        if (more) {
            more.hidden = hidden === 0;
            var b = more.querySelector("[data-vct-vis-all]");
            if (b) b.textContent = "Ver todas (" + n + ")";
        }
    }

    document.addEventListener("click", function (e) {
        var toggle = e.target.closest("[data-vct-vis-toggle]");
        if (toggle) {
            var row = toggle.closest("[data-vis-id]");
            var box = toggle.closest("[data-vct-vis]");
            if (!row || !box) return;
            var det = box.querySelector('[data-vis-detail="' + row.getAttribute("data-vis-id") + '"]');
            if (!det) return;
            det.hidden = !det.hidden;
            row.classList.toggle("is-open", !det.hidden);
            toggle.setAttribute("aria-expanded", det.hidden ? "false" : "true");
            return;
        }

        var allBtn = e.target.closest("[data-vct-vis-all]");
        if (allBtn) {
            var ab = allBtn.closest("[data-vct-vis]");
            if (ab) { ab.dataset.visAll = "1"; applyFilter(ab); }
            return;
        }

        var chip = e.target.closest("[data-vis-filter]");
        if (chip && chip.closest("[data-vct-vis-chips]")) {
            var cb = chip.closest("[data-vct-vis]");
            cb.querySelectorAll("[data-vct-vis-chips] .vct-plan-chip").forEach(function (c) { c.classList.toggle("is-active", c === chip); });
            applyFilter(cb);
        }
    });

    document.addEventListener("input", function (e) {
        if (e.target.hasAttribute && e.target.hasAttribute("data-vct-vis-search")) {
            var box = e.target.closest("[data-vct-vis]");
            if (box) applyFilter(box);
        }
    });

    document.addEventListener("keydown", function (e) {
        if (e.key === "Enter" && e.target.hasAttribute && e.target.hasAttribute("data-vct-vis-search")) e.preventDefault();
    });

    /* ---------- horas = hasta - desde ---------- */
    function field(form, name) {
        return form.querySelector('[name="SP.' + name + '"]') || form.querySelector('[data-vct-field="' + name + '"]');
    }
    function mins(v) {
        var m = /^(\d{2}):(\d{2})$/.exec(v || "");
        return m ? Number(m[1]) * 60 + Number(m[2]) : null;
    }
    document.addEventListener("change", function (e) {
        var el = e.target;
        var form = el && el.closest && el.closest("#vctVisita");
        if (!form) return;
        var name = el.getAttribute("data-vct-field") || String(el.getAttribute("name") || "").replace("SP.", "");
        if (name !== "TEXTO12" && name !== "TEXTO13") return;
        var d = mins((field(form, "TEXTO12") || {}).value), h = mins((field(form, "TEXTO13") || {}).value);
        var out = field(form, "TEXTO21");
        if (d === null || h === null || !out) return;
        if (h <= d) {
            if (window.VCT && VCT.Toast) VCT.Toast.show("La hora \"hasta\" tiene que ser posterior a \"desde\".", "error");
            return;
        }
        var horas = Math.round((h - d) / 60 * 100) / 100;
        out.value = String(horas).replace(".", ",");
        out.dispatchEvent(new Event("input", { bubbles: true }));
    }, true);

    /* ---------- captura en window: corre antes que el motor ---------- */
    window.addEventListener("click", function (e) {
        var el = e.target.closest && e.target.closest("[data-vct-command]");
        if (!el) return;
        var cmd = (el.getAttribute("data-vct-command") || "").toLowerCase();
        if (cmd === "open-modal-data" && el.getAttribute("data-vct-target") === "vctVisita") {
            var modal = document.getElementById("vctVisita");
            if (modal && window.VCT && VCT.DomForm && typeof VCT.DomForm.setHeader === "function")
                VCT.DomForm.setHeader(modal, el);
        }
    }, true);

    /* ---------- date picker: etiqueta cuando el valor viene de la fila ---------- */
    document.addEventListener("change", function (e) {
        var input = e.target;
        if (!input || !input.classList || !input.classList.contains("vct-datepicker-native")) return;
        if (!input.closest("#vctVisita")) return;
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

    /* ---------- ancho visible de la tabla (detalle legible en celular) ---------- */
    function fitWidth() {
        document.querySelectorAll("[data-vct-vis] .vct-plan-table-wrap").forEach(function (w) {
            if (w.clientWidth) w.style.setProperty("--vct-vis-w", (w.clientWidth - 24) + "px");
        });
    }
    window.addEventListener("resize", fitWidth);

    /* ---------- al cargar ---------- */
    function boot() {
        fitWidth();
        document.querySelectorAll("[data-vct-vis]").forEach(function (box) {
            if (box.dataset.visReady === "1") return;
            box.dataset.visReady = "1";
            applyFilter(box);
            if (box.querySelector(".vct-lanz-alert")) {
                setTimeout(function () {
                    try { box.scrollIntoView({ behavior: "smooth", block: "start" }); } catch (e) {}
                }, 160);
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
