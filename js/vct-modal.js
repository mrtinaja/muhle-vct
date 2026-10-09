/* ==========================================================================
   VCT MODAL & FORM ENGINE - FRAMEWORK VCT 8.0.0
   100% Agnóstico, Dinámico y Reutilizable (Zero Hardcode Edition)
   Archivo: vct-modal.js
   ========================================================================== */

(function (window, document) {
    "use strict";

    var VCTModal = {
        version: "8.0.0-AGNOSTIC",

        show: function (title, text, isConfirm, onOk) {
            var old = document.getElementById("vctGlobalModal");
            if (old) old.remove();

            var backdrop = document.createElement("div");
            backdrop.id = "vctGlobalModal";
            backdrop.className = "vct-modal-backdrop";

            var actionsHtml = isConfirm
                ? '<button type="button" class="vct-modal-btn vct-modal-btn-cancel" id="vctBtnCancel">Cancelar</button>' +
                  '<button type="button" class="vct-modal-btn vct-modal-btn-confirm" id="vctBtnOk">Confirmar</button>'
                : '<button type="button" class="vct-modal-btn vct-modal-btn-warning" id="vctBtnOk">Entendido</button>';

            backdrop.innerHTML =
                '<div class="vct-modal-card" role="dialog" aria-modal="true">' +
                    '<h4 class="vct-modal-title">' + (title || "Atención") + '</h4>' +
                    '<p class="vct-modal-text">' + (text || "") + '</p>' +
                    '<div class="vct-modal-actions">' + actionsHtml + '</div>' +
                '</div>';

            document.body.appendChild(backdrop);

            var close = function () {
                backdrop.classList.remove("is-open");
                window.setTimeout(function () { backdrop.remove(); }, 200);
            };

            var btnCancel = document.getElementById("vctBtnCancel");
            if (btnCancel) btnCancel.onclick = close;

            var btnOk = document.getElementById("vctBtnOk");
            if (btnOk) {
                btnOk.onclick = function () {
                    close();
                    if (typeof onOk === "function") onOk();
                };
            }

            window.setTimeout(function () {
                backdrop.classList.add("is-open");
                if (btnOk) btnOk.focus();
            }, 10);
        },

        alert: function (opts) {
            opts = opts || {};
            this.show(opts.title || "Atención", opts.text || "", false, opts.onOk);
        },

        confirm: function (opts) {
            opts = opts || {};
            this.show(opts.title || "¿Confirmar?", opts.text || "", true, opts.onConfirm);
        }
    };

    window.VCTModal = VCTModal;

    /**
     * Sincroniza dinámicamente los marcadores de campos opcionales en edición
     * de manera agnóstica a través del atributo [data-vct-optional-on-edit].
     */
    function enforceFormState() {
        var activePanel = document.querySelector("[data-vct-panel='form']:not([hidden]), [data-vct-panel].is-active") || document;
        var modeElem = activePanel.querySelector("[data-vct-form-mode]");
        var isEdit = modeElem && modeElem.value === "EDIT";

        // Cualquier campo marcado como opcional en edición (ej. Contraseña) conmuta su marca de requeratorio
        var optionalMarkers = activePanel.querySelectorAll("[data-vct-optional-on-edit]");
        optionalMarkers.forEach(function (marker) {
            var reqMarker = marker.querySelector(".vct-required") || (marker.classList.contains("vct-required") ? marker : null);
            if (reqMarker) {
                reqMarker.style.display = isEdit ? "none" : "inline-block";
            }
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", enforceFormState);
    } else {
        enforceFormState();
    }

    window.vctRefreshFormEngine = enforceFormState;

})(window, document);

/**
 * Extracción quirúrgica, pura y agnóstica de valores de controles HTML
 */
function vctExtraerValorControl(input, container) {
    if (!input) return "";

    var tagName = input.tagName.toLowerCase();

    // 1. Manejo de SELECT / TomSelect
    if (tagName === "select") {
        var val = "";

        if (input.tomselect && typeof input.tomselect.getValue === "function") {
            var tsVal = input.tomselect.getValue();
            if (Array.isArray(tsVal)) tsVal = tsVal.join(",");
            val = String(tsVal || "").trim();
        }

        if (val === "" && input.value !== null && input.value !== undefined) {
            val = String(input.value).trim();
        }

        if (val === "" && input.selectedIndex >= 0 && input.options[input.selectedIndex]) {
            var opt = input.options[input.selectedIndex];
            val = String(opt.value || "").trim();
        }

        var lowerVal = val.toLowerCase();
        if (val === "" || 
            lowerVal.indexOf("selecc") !== -1 || 
            lowerVal.indexOf("elegir") !== -1 || 
            lowerVal.indexOf("buscar") !== -1) {
            return "";
        }

        var tieneOpcionValida = false;
        for (var i = 0; i < input.options.length; i++) {
            var o = input.options[i];
            var oVal = String(o.value || "").trim();
            var oText = String(o.text || "").trim().toLowerCase();

            if (oVal !== "" && (oVal === val || oText === lowerVal)) {
                val = oVal;
                tieneOpcionValida = true;
                break;
            }
        }

        return tieneOpcionValida ? val : "";
    } 
    
    // 2. Checkbox y Radio Buttons
    if (input.type === "checkbox" || input.type === "radio") {
        return input.checked ? "OK" : "";
    }

    // 3. Inputs de Texto, Password, Textarea, etc.
    return input.value ? input.value.trim() : "";
}

/**
 * Validador Global de Formulario
 * Agnóstico, evaluado por marcadores de obligatoriedad en el DOM.
 */
function vctConfirmarGuardar(formId, totalCampos, options) {
    try {
        options = options || {};
        var maxCampos = totalCampos || 30;
        var prefix = options.prefix || "idCampo";
        var faltantes = [];

        var activePanel = document.querySelector("[data-vct-panel='form']:not([hidden]), [data-vct-panel].is-active") || document;
        var modeElem = activePanel.querySelector("[data-vct-form-mode]");
        var isEditMode = modeElem && modeElem.value === "EDIT";

        // A) Sincronizar Clave Primaria Seleccionada con el Buffer de Mühle
        var module = activePanel.closest("[data-vct-tabs]") || document.querySelector("[data-vct-tabs]");
        var storageKey = module ? module.dataset.vctEditStorageKey : null;

        if (storageKey && typeof window.almacenarSeleccion === "function") {
            var hiddenPk = activePanel.querySelector('[data-vct-selected-key], [name$=".' + storageKey + '"], [name="' + storageKey + '"], #' + storageKey);
            var valPk = (isEditMode && hiddenPk) ? String(hiddenPk.value || "").trim() : "";
            window.almacenarSeleccion(storageKey, valPk);
        }

        // B) Recorrido de los marcadores requeridos
        for (var i = 1; i <= maxCampos; i++) {
            var fieldId = prefix + i;
            var marker = document.getElementById(fieldId);

            if (!marker || marker.hidden || marker.style.display === "none") {
                continue;
            }

            var container = marker.closest(".vct-form-group") || marker.closest(".vct-form-group-full") || marker.parentElement.parentElement;
            var label = marker.closest("label");
            var input = null;

            if (label && label.getAttribute("for")) {
                var targetId = label.getAttribute("for");
                input = activePanel.querySelector("#" + targetId) || document.getElementById(targetId);
            }

            if (!input || (input.id && input.id.indexOf("-ts-control") !== -1)) {
                if (container) {
                    input = container.querySelector("select, input, textarea");
                }
            }

            if (!input) continue;

            // Regla Semántica: Un input es opcional en edición si es tipo 'password' o tiene el atributo [data-vct-optional-on-edit]
            var isOptionalOnEdit = input.type === "password" || container.hasAttribute("data-vct-optional-on-edit") || input.hasAttribute("data-vct-optional-on-edit");

            if (isOptionalOnEdit && isEditMode) {
                continue;
            }

            // Ignorar campos deshabilitados o de solo lectura
            if (input.tagName.toLowerCase() !== "select" && (input.disabled || input.readOnly || input.getAttribute("readonly") !== null)) {
                continue;
            }

            var val = vctExtraerValorControl(input, container);

            if (input.tagName.toLowerCase() === "select") {
                input.value = val;
            }

            // Evaluación de Campo Incompleto
            if (val === "") {
                var labelElem = container ? container.querySelector("label span:not(.vct-required)") : null;
                var nombreCampo = labelElem ? labelElem.textContent.trim() : ("Campo N° " + i);
                faltantes.push(nombreCampo);
            }
        }

        // C) Si hay campos requeridos vacíos, detener submit y mostrar alerta
        if (faltantes.length > 0) {
            var listaCampos = faltantes.map(function(c) { return "• " + c; }).join("<br>");
            VCTModal.alert({
                title: "Campos obligatorios incompletos",
                text: "Por favor complete los siguientes campos requeridos antes de continuar:<br><br>" + listaCampos
            });
            return false;
        }

        // D) Diálogo de Confirmación
        var msgTitle = isEditMode ? "¿Guardar cambios?" : "¿Confirmar registro?";
        var msgText = isEditMode 
            ? "Se actualizarán los datos ingresados en la base de datos." 
            : "Se dará de alta la nueva información en el sistema.";

        VCTModal.confirm({
            title: msgTitle,
            text: options.customMessage || msgText,
            onConfirm: function() {
                // Sincronizar todos los selects nativos antes del POST
                activePanel.querySelectorAll("select").forEach(function(s) {
                    var sContainer = s.closest(".vct-form-group") || s.closest(".vct-form-group-full");
                    var sVal = vctExtraerValorControl(s, sContainer);
                    s.value = sVal;
                });

                if (typeof window.next === "function") {
                    window.next(formId);
                } else if (typeof next === "function") {
                    next(formId);
                } else {
                    var form = document.forms[0];
                    if (form) form.submit();
                }
            }
        });

    } catch (err) {
        console.error("Critical Error en vctConfirmarGuardar:", err);
    }

    return false;
}