/* vct-proyecto-lanz.js - v2
   ============================================================================
   Seccion "Lanzamiento" de la Vista 360 de Proyecto (pantalla del analista).
   El SP (dbo.VCT_PROYECTO_LANZ_RENDER) arma la seccion y los formularios;
   el guardado es el estandar (validate-next -> buffer -> mismo SP). Aca solo:
     - Abrir el modal de "Datos de entrada" sin limpiar lo ya cargado.
     - Empaquetar las respuestas libres en SP.TEXTO11..TEXTO29
       ("[[idItem]]valor..." en tramos de 3500) antes de guardar.
     - Buscador, contador y alto automatico de los campos.
     - Confirmar "Quitar del equipo" e "Iniciar proyecto".
     - Stepper: barra 1-2-3-4 y un paso visible a la vez (v2).
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoLanzLoaded) return;
    window.__vctProyectoLanzLoaded = true;

    var CHUNK = 3500;

    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    function grow(t) {
        t.style.height = "auto";
        t.style.height = Math.min(t.scrollHeight + 2, 320) + "px";
    }

    function count(modal) {
        var qs = modal.querySelectorAll(".vct-lanz-q");
        var ok = 0;
        qs.forEach(function (q) { if (q.value.trim()) ok++; });
        var el = modal.querySelector("[data-vct-lanz-count]");
        if (el) el.textContent = ok + " de " + qs.length + " datos cargados";
    }

    function pack(modal) {
        var parts = [];
        modal.querySelectorAll(".vct-lanz-q").forEach(function (q) {
            var id = q.getAttribute("data-lanz-item");
            if (!id) return;
            parts.push("[[" + id + "]]" + q.value.trim().replace(/\[\[/g, "[ ["));
        });
        var all = parts.join("");
        var slots = modal.querySelectorAll("[data-vct-lanz-slot]");
        if (Math.ceil(all.length / CHUNK) > slots.length) {
            if (window.VCT && VCT.Toast) VCT.Toast.show("Los datos de entrada son demasiado largos para guardarse de una vez. Acorte algunos textos.", "error");
            return false;
        }
        slots.forEach(function (slot, i) {
            slot.value = all.substr(i * CHUNK, CHUNK);
        });
        return true;
    }

    function openDatos(id) {
        var modal = document.getElementById(id);
        if (!modal) return;
        if (window.VCT && VCT.DomForm && typeof VCT.DomForm.activateScope === "function")
            VCT.DomForm.activateScope(modal);
        if (window.VCT && VCT.Modal) VCT.Modal.open(id);
        else modal.classList.add("is-open");
        var filter = modal.querySelector("[data-vct-lanz-filter]");
        if (filter) { filter.value = ""; applyFilter(modal, ""); }
        setTimeout(function () {
            modal.querySelectorAll(".vct-lanz-q").forEach(grow);
            count(modal);
        }, 30);
    }

    function applyFilter(modal, text) {
        var q = norm(text);
        modal.querySelectorAll(".vct-lanz-q").forEach(function (t) {
            var field = t.closest(".vct-field");
            if (!field) return;
            var label = field.querySelector(".vct-label");
            var hit = !q || norm(label ? label.textContent : "").indexOf(q) >= 0 || norm(t.value).indexOf(q) >= 0;
            field.style.display = hit ? "" : "none";
        });
    }

    /* abrir datos de entrada */
    document.addEventListener("click", function (e) {
        var btn = e.target.closest("[data-vct-lanz-open]");
        if (!btn) return;
        e.preventDefault();
        openDatos(btn.getAttribute("data-vct-lanz-open"));
    });

    /* captura en window: corre antes que el validate-next de vct-main.js */
    window.addEventListener("click", function (e) {
        var btn = e.target.closest && e.target.closest('[data-vct-command="validate-next"]');
        if (!btn) return;

        var datos = btn.closest("[data-vct-lanz-datos]");
        if (datos) {
            if (!pack(datos)) { e.preventDefault(); e.stopImmediatePropagation(); }
            return;
        }

        if (btn.closest("[data-vct-lanz-quitar]")) {
            if (!window.confirm("¿Quitar a este consultor del equipo del proyecto?")) {
                e.preventDefault(); e.stopImmediatePropagation();
            }
            return;
        }

        var ini = btn.closest("[data-vct-lanz-iniciar]");
        if (ini) {
            var pasos = parseInt(ini.getAttribute("data-pasos") || "0", 10);
            var msg = pasos >= 4
                ? "¿Iniciar el proyecto? Pasa a En curso y el consultor líder recibe la tarea de armar el Plan Estratégico."
                : "Hay " + (4 - pasos) + " paso(s) del lanzamiento sin completar. ¿Iniciar el proyecto igual?";
            if (!window.confirm(msg)) { e.preventDefault(); e.stopImmediatePropagation(); }
        }
    }, true);

    document.addEventListener("input", function (e) {
        var t = e.target;
        if (t.classList && t.classList.contains("vct-lanz-q")) {
            grow(t);
            var m = t.closest("[data-vct-lanz-datos]");
            if (m) count(m);
            return;
        }
        if (t.hasAttribute && t.hasAttribute("data-vct-lanz-filter")) {
            var modal = t.closest("[data-vct-lanz-datos]");
            if (modal) applyFilter(modal, t.value);
        }
    });

    /* ======================================================================
       STEPPER: barra 1-2-3-4 y un solo paso visible a la vez.
       Al entrar se abre el primer paso sin completar; despues de guardar
       se queda en el paso donde estaba (para cargar otro consultor, etc.).
       ====================================================================== */
    function stepKey(box) {
        var bc = document.querySelector(".vct-breadcrumb-current");
        return "vctLanzStep:" + (bc ? bc.textContent.trim() : "");
    }

    function showStep(box, idx, remember) {
        var steps = box.querySelectorAll(".vct-lanz-step");
        if (!steps.length) return;
        idx = Math.max(0, Math.min(idx, steps.length - 1));
        steps.forEach(function (s, i) { s.classList.toggle("is-active", i === idx); });
        box.querySelectorAll(".vct-lanz-stepper-item").forEach(function (b, i) {
            b.classList.toggle("is-active", i === idx);
            b.setAttribute("aria-selected", i === idx ? "true" : "false");
        });
        var prev = box.querySelector("[data-lanz-prev]"), next = box.querySelector("[data-lanz-next]");
        if (prev) prev.disabled = idx === 0;
        if (next) next.disabled = idx === steps.length - 1;
        box.setAttribute("data-lanz-step", String(idx));
        if (remember) { try { sessionStorage.setItem(stepKey(box), String(idx)); } catch (e) {} }
    }

    function buildStepper(box) {
        if (!box || box.dataset.lanzStepper === "1") return;
        var wrap = box.querySelector(".vct-lanz-steps");
        var steps = box.querySelectorAll(".vct-lanz-step");
        if (!wrap || !steps.length) return;
        box.dataset.lanzStepper = "1";
        wrap.classList.add("is-stepper");

        var nav = document.createElement("div");
        nav.className = "vct-lanz-stepper";
        nav.setAttribute("role", "tablist");
        var firstPending = -1;
        steps.forEach(function (s, i) {
            var done = s.classList.contains("is-done");
            if (!done && firstPending < 0) firstPending = i;
            var title = s.querySelector("h4");
            var b = document.createElement("button");
            b.type = "button";
            b.className = "vct-lanz-stepper-item" + (done ? " is-done" : "");
            b.setAttribute("role", "tab");
            b.innerHTML = '<span class="vct-lanz-stepper-dot">' + (i + 1) + '</span>' +
                '<span class="vct-lanz-stepper-label">' + (title ? title.textContent : "Paso " + (i + 1)) +
                '<small>' + (done ? "Completo" : "Pendiente") + '</small></span>';
            b.addEventListener("click", function () { showStep(box, i, true); });
            nav.appendChild(b);
        });
        wrap.parentNode.insertBefore(nav, wrap);

        var pager = document.createElement("div");
        pager.className = "vct-lanz-pager";
        pager.innerHTML =
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-lanz-prev>&lsaquo; Anterior</button>' +
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-lanz-next>Siguiente &rsaquo;</button>';
        wrap.parentNode.insertBefore(pager, wrap.nextSibling);
        pager.addEventListener("click", function (e) {
            var cur = parseInt(box.getAttribute("data-lanz-step") || "0", 10);
            if (e.target.closest("[data-lanz-prev]")) showStep(box, cur - 1, true);
            if (e.target.closest("[data-lanz-next]")) showStep(box, cur + 1, true);
        });

        var idx = firstPending < 0 ? steps.length - 1 : firstPending;
        try {
            var saved = sessionStorage.getItem(stepKey(box));
            if (saved !== null && box.querySelector(".vct-lanz-alert")) idx = parseInt(saved, 10);
        } catch (e) {}
        showStep(box, idx, false);
    }

    function bootStepper() {
        document.querySelectorAll("[data-vct-lanz]").forEach(buildStepper);
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", bootStepper);
    else bootStepper();
    if (window.MutationObserver) {
        var pend = false;
        new MutationObserver(function () {
            if (pend) return;
            pend = true;
            setTimeout(function () { pend = false; bootStepper(); }, 30);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }

    /* Enter en el buscador no debe enviar nada */
    document.addEventListener("keydown", function (e) {
        if (e.key === "Enter" && e.target.hasAttribute && e.target.hasAttribute("data-vct-lanz-filter")) e.preventDefault();
    });
})(window, document);
