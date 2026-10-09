(function (window, document) {
    "use strict";
    if (window.VCT) return;

    var VCT = {};

    /* ============================================================
       UTILIDADES
       ============================================================ */
    VCT.Util = {
        trim: function (value) {
            return value === null || value === undefined ? "" : String(value).trim();
        },
        toBool: function (value) {
            return value === true || value === 1 || value === "1" ||
                   String(value).toLowerCase() === "true" ||
                   String(value).toUpperCase() === "SI";
        },
        findPage: function (element) {
            if (!element) return document.querySelector("[data-vct-page]");
            return element.closest("[data-vct-page]") || document.querySelector("[data-vct-page]");
        },
        getFormId: function (element) {
            var page = VCT.Util.findPage(element);
            if (page && page.dataset && page.dataset.vctFormId)
                return VCT.Util.trim(page.dataset.vctFormId);

            var holder = document.querySelector("[data-vct-form-id]");
            if (holder && holder.dataset && holder.dataset.vctFormId)
                return VCT.Util.trim(holder.dataset.vctFormId);

            return "";
        }
    };

    /* ============================================================
       BUFFER
       ============================================================ */
    VCT.Buffer = {
        getInput: function (field) {
            field = VCT.Util.trim(field);
            if (!field) return null;
            return document.querySelector('[name="SP.' + field + '"]') ||
                   document.getElementById(field) ||
                   document.querySelector('[data-vct-field="' + field + '"]');
        },
        setLocal: function (field, value) {
            var input = VCT.Buffer.getInput(field);
            if (!input) return false;
            if (input.type === "checkbox") input.checked = VCT.Util.toBool(value);
            else input.value = value === null || value === undefined ? "" : value;
            return true;
        },
        getValue: function (field) {
            var input = VCT.Buffer.getInput(field);
            if (!input) return "";
            if (input.type === "checkbox") return input.checked ? "1" : "0";
            return input.value;
        },
        store: function (field, value, sourceInput) {
            field = VCT.Util.trim(field);
            if (!field) {
                console.error("[VCT] Buffer.store: campo vacío.");
                return false;
            }

            /* Cuando hay varios formularios dinamicos pueden existir varios
               SP.TEXTO11, SP.FLAG02, etc. Si el caller conoce el input de
               origen, actualizamos ESE control y no el primero del documento. */
            if (sourceInput) {
                if (sourceInput.type === "checkbox")
                    sourceInput.checked = VCT.Util.toBool(value);
                else
                    sourceInput.value = value === null || value === undefined ? "" : value;
            } else {
                VCT.Buffer.setLocal(field, value);
            }

            if (typeof window.almacenarSeleccion !== "function") {
                console.warn("[VCT] almacenarSeleccion no está disponible.", field, value);
                return false;
            }

            try {
                var result = window.almacenarSeleccion(field, value);
                return result !== false;
            } catch (e) {
                console.error("[VCT] Error almacenando selección:", field, value, e);
                return false;
            }
        },

        /* --------------------------------------------------------
           ESCRITURA SECUENCIAL AL BUFFER
           --------------------------------------------------------
           almacenarSeleccion pertenece al framework. Dependiendo de la
           versión puede ser síncrona, devolver Promise/jqXHR o disparar
           un AJAX sin devolver handle. Los formularios escriben varios
           campos consecutivos; si esas escrituras viajan en paralelo se
           pueden pisar entre sí antes de ejecutar next().

           storeQueued normaliza los tres casos y llama done() recién
           cuando la escritura actual terminó (o venció el timeout).
           -------------------------------------------------------- */
        waitForStoreIdle: function (baseline, done) {
            var started = Date.now();
            var maxWait = 2500;

            var finish = function (ok) {
                window.setTimeout(function () { done(ok !== false); }, 20);
            };

            var tick = function () {
                var jq = window.jQuery;
                var active = jq && typeof jq.active === "number" ? jq.active : null;

                if (active === null) {
                    /* Framework sin jQuery observable: pequeña espera para
                       evitar que varias escrituras fire-and-forget se pisen. */
                    window.setTimeout(function () { done(true); }, 120);
                    return;
                }

                if (active <= baseline) {
                    finish(true);
                    return;
                }

                if (Date.now() - started >= maxWait) {
                    console.warn("[VCT] Timeout esperando escritura de buffer.");
                    finish(true);
                    return;
                }

                window.setTimeout(tick, 25);
            };

            tick();
        },

        storeQueued: function (field, value, sourceInput, done) {
            field = VCT.Util.trim(field);
            done = typeof done === "function" ? done : function () {};

            if (!field) {
                done(false);
                return;
            }

            if (sourceInput) {
                if (sourceInput.type === "checkbox")
                    sourceInput.checked = VCT.Util.toBool(value);
                else
                    sourceInput.value = value === null || value === undefined ? "" : value;
            } else {
                VCT.Buffer.setLocal(field, value);
            }

            if (typeof window.almacenarSeleccion !== "function") {
                console.error("[VCT] almacenarSeleccion no está disponible.", field);
                done(false);
                return;
            }

            var jq = window.jQuery;
            var baseline = jq && typeof jq.active === "number" ? jq.active : 0;
            var result;

            var namedCopies = document.querySelectorAll('[name="SP.' + field + '"]');
            if (namedCopies.length > 1) {
                console.error("[VCT] Campo duplicado antes de almacenar:", field, namedCopies.length);
                done(false);
                return;
            }

            try {
                result = window.almacenarSeleccion(field, value);
            } catch (e) {
                console.error("[VCT] Error almacenando selección:", field, value, e);
                done(false);
                return;
            }

            if (result === false) {
                done(false);
                return;
            }

            /* Promise nativa / thenable. */
            if (result && typeof result.then === "function") {
                result.then(
                    function () { done(true); },
                    function (e) {
                        console.error("[VCT] Error async almacenando selección:", field, e);
                        done(false);
                    }
                );
                return;
            }

            /* jqXHR / Deferred sin then estándar confiable. */
            if (result && typeof result.done === "function") {
                result.done(function () { done(true); });
                if (typeof result.fail === "function") {
                    result.fail(function (e) {
                        console.error("[VCT] Error AJAX almacenando selección:", field, e);
                        done(false);
                    });
                }
                return;
            }

            VCT.Buffer.waitForStoreIdle(baseline, done);
        }
    };

    /* ============================================================
       VALIDACIONES
       ============================================================ */
    VCT.Validation = {
        clear: function (scope) {
            scope = scope || document;
            scope.querySelectorAll(".vct-field-error").forEach(function (el) {
                el.classList.remove("vct-field-error");
            });
            scope.querySelectorAll("[data-vct-error-for]").forEach(function (el) {
                el.remove();
            });

            var box = scope.querySelector("[data-vct-validation-box]");
            if (box) {
                box.innerHTML = "";
                box.style.display = "none";
            }
        },
        validateField: function (input) {
            var errors = [];
            var label = VCT.Util.trim(input.dataset.vctLabel) ||
                        VCT.Util.trim(input.getAttribute("placeholder")) || "Campo";
            var type = VCT.Util.trim(input.dataset.vctType).toLowerCase();
            var required = VCT.Util.toBool(input.dataset.vctRequired);
            var value = input.type === "checkbox" ? (input.checked ? "1" : "") : VCT.Util.trim(input.value);

            if (required && value === "") {
                errors.push(label + " es obligatorio.");
                return errors;
            }
            if (value === "") return errors;

            if (type === "email") {
                var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(value)) errors.push(label + " no tiene un formato válido.");
            }

            if (type === "number" || type === "integer" || type === "decimal") {
                var normalized = value.replace(",", ".");
                if (isNaN(normalized)) {
                    errors.push(label + " debe ser numérico.");
                    return errors;
                }
                if (type === "integer" && !/^-?\d+$/.test(value))
                    errors.push(label + " debe ser un número entero.");

                if (input.dataset.vctMin !== undefined && input.dataset.vctMin !== "" &&
                    Number(normalized) < Number(input.dataset.vctMin))
                    errors.push(label + " debe ser mayor o igual a " + input.dataset.vctMin + ".");

                if (input.dataset.vctMax !== undefined && input.dataset.vctMax !== "" &&
                    Number(normalized) > Number(input.dataset.vctMax))
                    errors.push(label + " debe ser menor o igual a " + input.dataset.vctMax + ".");
            }

            if (input.dataset.vctMaxlength && value.length > Number(input.dataset.vctMaxlength))
                errors.push(label + " no puede superar " + input.dataset.vctMaxlength + " caracteres.");

            if (input.dataset.vctPattern) {
                try {
                    var regex = new RegExp(input.dataset.vctPattern);
                    if (!regex.test(value)) errors.push(label + " no tiene un formato válido.");
                } catch (e) {
                    console.warn("[VCT] Patrón inválido:", input.dataset.vctPattern);
                }
            }

            return errors;
        },
        validate: function (scope) {
            scope = scope || document;
            VCT.Validation.clear(scope);

            var allErrors = [];
            var fields = scope.querySelectorAll("[data-vct-field]");
            fields.forEach(function (input) {
                var errors = VCT.Validation.validateField(input);
                if (errors.length) {
                    input.classList.add("vct-field-error");
                    errors.forEach(function (message) {
                        allErrors.push({ field: input, message: message });
                    });
                }
            });

            if (!allErrors.length) return true;

            var box = scope.querySelector("[data-vct-validation-box]");
            if (box) {
                var html = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul>';
                allErrors.forEach(function (item) { html += "<li>" + item.message + "</li>"; });
                html += "</ul>";
                box.innerHTML = html;
                box.style.display = "block";
            }

            if (allErrors[0].field) allErrors[0].field.focus();
            return false;
        }
    };

    /* ============================================================
       NAVEGACION
       ============================================================ */
    VCT.Navigation = {
        next: function (element) {
            var formId = VCT.Util.getFormId(element);
            if (!formId) {
                console.error("[VCT] No se encontró FORM_ID para next().");
                return false;
            }
            if (typeof window.next !== "function") {
                console.error("[VCT] La función next() no está disponible.");
                return false;
            }
            try { window.next(formId); }
            catch (e) { console.error("[VCT] Error ejecutando next():", e); }
            return false;
        },
        goto: function (element, guid) {
            var formId = VCT.Util.getFormId(element);
            guid = VCT.Util.trim(guid);
            if (!formId) {
                console.error("[VCT] No se encontró FORM_ID para goto().");
                return false;
            }
            if (!guid) {
                console.error("[VCT] No se indicó GUID destino.");
                return false;
            }
            if (typeof window.goto !== "function") {
                console.error("[VCT] La función goto() no está disponible.");
                return false;
            }
            try { window.goto(formId, guid); }
            catch (e) { console.error("[VCT] Error ejecutando goto():", e); }
            return false;
        }
    };

    /* ============================================================
       MODAL
       ============================================================ */
    VCT.Modal = {
        get: function (id) {
            if (!id) return document.querySelector('[data-vct-component="modal"].is-open');
            return document.getElementById(id) ||
                   document.querySelector('[data-vct-component="modal"][data-vct-id="' + id + '"]');
        },
        open: function (id) {
            var modal = VCT.Modal.get(id);
            if (!modal) return false;
            modal.classList.add("is-open");
            document.body.classList.add("vct-modal-open");
            return true;
        },
        close: function (id) {
            var modal = VCT.Modal.get(id);
            if (!modal) return false;
            modal.classList.remove("is-open");
            if (!document.querySelector('[data-vct-component="modal"].is-open'))
                document.body.classList.remove("vct-modal-open");
            return true;
        }
    };

    /* ============================================================
       DRAWER
       ============================================================ */
    VCT.Drawer = {
        get: function (id) {
            if (!id) return document.querySelector('[data-vct-component="drawer"].is-open');
            return document.getElementById(id) ||
                   document.querySelector('[data-vct-component="drawer"][data-vct-id="' + id + '"]');
        },
        open: function (id) {
            var drawer = VCT.Drawer.get(id);
            if (!drawer) return false;
            drawer.classList.add("is-open");
            document.body.classList.add("vct-drawer-open");
            return true;
        },
        close: function (id) {
            var drawer = VCT.Drawer.get(id);
            if (!drawer) return false;
            drawer.classList.remove("is-open");
            if (!document.querySelector('[data-vct-component="drawer"].is-open'))
                document.body.classList.remove("vct-drawer-open");
            return true;
        }
    };

    /* ============================================================
       TOAST
       ============================================================ */
    VCT.Toast = {
        show: function (message, type) {
            type = type || "info";
            var container = document.querySelector("[data-vct-toast-container]");
            if (!container) {
                container = document.createElement("div");
                container.setAttribute("data-vct-toast-container", "");
                container.className = "vct-toast-container";
                document.body.appendChild(container);
            }

            var toast = document.createElement("div");
            toast.className = "vct-toast vct-toast-" + type;
            toast.textContent = message;
            container.appendChild(toast);

            setTimeout(function () { toast.classList.add("is-visible"); }, 10);
            setTimeout(function () {
                toast.classList.remove("is-visible");
                setTimeout(function () {
                    if (toast.parentNode) toast.parentNode.removeChild(toast);
                }, 200);
            }, 3500);
        }
    };


    /* ============================================================
       SELECT PERSONALIZADO
       Conserva el <select> real para el framework y crea una capa
       visual institucional sincronizada con su valor.
       ============================================================ */
    VCT.Select = {
        closeAll: function (except) {
            document.querySelectorAll(".vct-custom-select.is-open").forEach(function (wrap) {
                if (except && wrap === except) return;
                wrap.classList.remove("is-open");
                var trigger = wrap.querySelector(".vct-custom-select-trigger");
                if (trigger) trigger.setAttribute("aria-expanded", "false");
            });
        },

        sync: function (select, wrap) {
            if (!select || !wrap) return;

            var trigger = wrap.querySelector(".vct-custom-select-trigger");
            var valueBox = wrap.querySelector(".vct-custom-select-value");
            var selected = select.options[select.selectedIndex];

            if (valueBox) {
                valueBox.textContent = selected ? selected.text : "";
                valueBox.classList.toggle("is-placeholder", !select.value);
            }

            wrap.querySelectorAll(".vct-custom-select-option").forEach(function (option) {
                var isSelected = String(option.getAttribute("data-value") || "") === String(select.value || "");
                option.classList.toggle("is-selected", isSelected);
                option.setAttribute("aria-selected", isSelected ? "true" : "false");
            });

            wrap.classList.toggle("is-disabled", !!select.disabled);
            if (trigger) trigger.disabled = !!select.disabled;
        },

        build: function (select) {
            if (!select || select.dataset.vctSelectReady === "1") return;
            if (select.getAttribute("data-vct-native") === "true") return;
            if (select.multiple || select.size > 1) return;

            select.dataset.vctSelectReady = "1";
            select.classList.add("vct-custom-select-native");

            var wrap = document.createElement("div");
            wrap.className = "vct-custom-select";
            wrap.setAttribute("data-vct-custom-select", "");

            var trigger = document.createElement("button");
            trigger.type = "button";
            trigger.className = "vct-custom-select-trigger";
            trigger.setAttribute("aria-haspopup", "listbox");
            trigger.setAttribute("aria-expanded", "false");

            var valueBox = document.createElement("span");
            valueBox.className = "vct-custom-select-value";

            var chevron = document.createElementNS("http://www.w3.org/2000/svg", "svg");
            chevron.setAttribute("viewBox", "0 0 24 24");
            chevron.setAttribute("fill", "none");
            chevron.setAttribute("stroke", "currentColor");
            chevron.setAttribute("stroke-width", "2");
            chevron.setAttribute("stroke-linecap", "round");
            chevron.setAttribute("stroke-linejoin", "round");
            chevron.setAttribute("class", "vct-custom-select-chevron");

            var p = document.createElementNS("http://www.w3.org/2000/svg", "polyline");
            p.setAttribute("points", "6 9 12 15 18 9");
            chevron.appendChild(p);

            trigger.appendChild(valueBox);
            trigger.appendChild(chevron);

            var menu = document.createElement("div");
            menu.className = "vct-custom-select-menu";
            menu.setAttribute("role", "listbox");

            Array.prototype.forEach.call(select.options, function (nativeOption) {
                var option = document.createElement("div");
                option.className = "vct-custom-select-option";
                option.setAttribute("role", "option");
                option.setAttribute("data-value", nativeOption.value);
                option.textContent = nativeOption.text;

                if (nativeOption.disabled) {
                    option.classList.add("is-disabled");
                    option.setAttribute("aria-disabled", "true");
                }

                option.addEventListener("click", function (event) {
                    event.preventDefault();
                    event.stopPropagation();

                    if (nativeOption.disabled) return;

                    select.value = nativeOption.value;
                    select.dispatchEvent(new Event("change", { bubbles: true }));
                    VCT.Select.sync(select, wrap);

                    wrap.classList.remove("is-open");
                    trigger.setAttribute("aria-expanded", "false");
                    trigger.focus();
                });

                menu.appendChild(option);
            });

            select.parentNode.insertBefore(wrap, select.nextSibling);
            wrap.appendChild(trigger);
            wrap.appendChild(menu);

            trigger.addEventListener("click", function (event) {
                event.preventDefault();
                event.stopPropagation();

                if (select.disabled) return;

                var willOpen = !wrap.classList.contains("is-open");
                VCT.Select.closeAll(wrap);
                wrap.classList.toggle("is-open", willOpen);
                trigger.setAttribute("aria-expanded", willOpen ? "true" : "false");
            });

            trigger.addEventListener("keydown", function (event) {
                if (event.key === "Escape") {
                    wrap.classList.remove("is-open");
                    trigger.setAttribute("aria-expanded", "false");
                    return;
                }

                if (event.key === "ArrowDown" || event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    if (!wrap.classList.contains("is-open")) {
                        VCT.Select.closeAll(wrap);
                        wrap.classList.add("is-open");
                        trigger.setAttribute("aria-expanded", "true");
                    }
                }
            });

            select.addEventListener("change", function () {
                VCT.Select.sync(select, wrap);
            });

            VCT.Select.sync(select, wrap);
        },

        init: function (scope) {
            scope = scope || document;
            scope.querySelectorAll("select.vct-select").forEach(function (select) {
                VCT.Select.build(select);
            });
        }
    };

    /* ============================================================
       SIDEBAR
       Desktop: colapsado/expandido. Tablet/Mobile: overlay.
       ============================================================ */
    VCT.Sidebar = {
        storageKey: "VCT_SIDEBAR_EXPANDED",
        activeKey: "VCT_ACTIVE_MODULE",

        isMobile: function () {
            return window.matchMedia && window.matchMedia("(max-width: 1024px)").matches;
        },
        setExpanded: function (expanded) {
            if (VCT.Sidebar.isMobile()) return;
            document.body.classList.toggle("vct-sidebar-expanded", !!expanded);
            try { window.localStorage.setItem(VCT.Sidebar.storageKey, expanded ? "1" : "0"); }
            catch (e) {}
        },
        toggle: function () {
            if (VCT.Sidebar.isMobile()) {
                VCT.Sidebar.toggleMobile();
                return;
            }
            VCT.Sidebar.setExpanded(!document.body.classList.contains("vct-sidebar-expanded"));
        },
        openMobile: function () {
            document.body.classList.add("vct-sidebar-mobile-open");
        },
        closeMobile: function () {
            document.body.classList.remove("vct-sidebar-mobile-open");
        },
        toggleMobile: function () {
            document.body.classList.toggle("vct-sidebar-mobile-open");
        },
        applyActive: function (moduleId) {
            if (!moduleId) return;
            moduleId = String(moduleId);
            document.documentElement.setAttribute("data-vct-active", moduleId);

            var sidebar = document.getElementById("muhleSideBar");
            if (!sidebar) return;

            sidebar.querySelectorAll(".vct-sidebar-link").forEach(function (link) {
                var current = String(link.getAttribute("data-vct-mod") || "");
                link.classList.toggle("active", current === moduleId);
            });

            document.querySelectorAll(".vct-mobile-nav-link[data-vct-mod]").forEach(function (link) {
                var current = String(link.getAttribute("data-vct-mod") || "");
                link.classList.toggle("active", current === moduleId);
            });
        },
        setActive: function (moduleId) {
            if (moduleId === null || moduleId === undefined || String(moduleId) === "") return;

            moduleId = String(moduleId);
            window.VCT_ACTIVE_MODULE = moduleId;

            VCT.Sidebar.applyActive(moduleId);

            if (VCT.Sidebar.isMobile())
                VCT.Sidebar.closeMobile();
        },
        filter: function (value) {
            var sidebar = document.getElementById("muhleSideBar");
            if (!sidebar) return;

            value = VCT.Util.trim(value).toLowerCase();
            sidebar.querySelectorAll(".vct-sidebar-link").forEach(function (link) {
                var text = VCT.Util.trim(link.textContent).toLowerCase();
                link.style.display = (!value || text.indexOf(value) >= 0) ? "" : "none";
            });
        },
        init: function () {
            var sidebar = document.getElementById("muhleSideBar");
            if (!sidebar) return;

            if (!VCT.Sidebar.isMobile()) {
                var expanded = false;
                try { expanded = window.localStorage.getItem(VCT.Sidebar.storageKey) === "1"; }
                catch (e) {}
                VCT.Sidebar.setExpanded(expanded);
            } else {
                document.body.classList.remove("vct-sidebar-expanded");
                VCT.Sidebar.closeMobile();
            }

            /* ACTIVE DEL SIDEBAR
               1) Si acabamos de hacer click, window.VCT_ACTIVE_MODULE manda.
               2) Si la pantalla declara su SideBarId, usamos ese.
               3) Si Inicio no genera contenido VCT, usamos el primer item.
               No se restaura un módulo viejo por sessionStorage. */
            var activeModule = "";

            if (window.VCT_ACTIVE_MODULE !== null &&
                window.VCT_ACTIVE_MODULE !== undefined &&
                String(window.VCT_ACTIVE_MODULE) !== "") {
                activeModule = String(window.VCT_ACTIVE_MODULE);
            }

            if (!activeModule) {
                var currentPage = document.querySelector("[data-vct-page][data-vct-sidebar-id]");
                if (currentPage)
                    activeModule = String(currentPage.getAttribute("data-vct-sidebar-id") || "");
            }

            if (!activeModule) {
                var first = sidebar.querySelector(".vct-sidebar-link[data-vct-mod]");
                if (first)
                    activeModule = String(first.getAttribute("data-vct-mod") || "");
            }

            if (activeModule &&
                !sidebar.querySelector('.vct-sidebar-link[data-vct-mod="' +
                    String(activeModule).replace(/"/g, '\\"') + '"]')) {
                activeModule = "";

                var home = sidebar.querySelector(".vct-sidebar-link[data-vct-mod]");
                if (home)
                    activeModule = String(home.getAttribute("data-vct-mod") || "");
            }

            if (activeModule)
                VCT.Sidebar.applyActive(activeModule);

            var search = sidebar.querySelector("[data-vct-sidebar-search]");
            if (search) {
                search.addEventListener("input", function () {
                    VCT.Sidebar.filter(search.value);
                });
            }
        }
    };

    /* Compatibilidad con el onclick actual del SP */
    window.vctApplyActiveModule = function (moduleId) {
        VCT.Sidebar.applyActive(moduleId);
    };
    window.vctSetActiveModule = function (moduleId) {
        VCT.Sidebar.setActive(moduleId);
    };


    /* ============================================================
       OBSERVADOR DE CONTENIDO DINAMICO
       El framework puede insertar OUTPARAMs después de cargar JS.
       Inicializamos automáticamente componentes nuevos.
       ============================================================ */
    VCT.Dynamic = {
        observer: null,

        scan: function (node) {
            if (!node || node.nodeType !== 1) return;

            VCT.Select.init(node);
            VCT.Icon.init(node);
            VCT.Badge.init(node);
            VCT.Tooltip.init(node);

            if ((node.id && node.id === "muhleSideBar") ||
                (node.querySelector && node.querySelector("#muhleSideBar"))) {
                window.setTimeout(function () {
                    VCT.Sidebar.init();
                }, 0);
            }
        },

        init: function () {
            if (!window.MutationObserver || VCT.Dynamic.observer) return;

            VCT.Dynamic.observer = new MutationObserver(function (mutations) {
                mutations.forEach(function (mutation) {
                    Array.prototype.forEach.call(mutation.addedNodes || [], function (node) {
                        VCT.Dynamic.scan(node);
                    });
                });
            });

            VCT.Dynamic.observer.observe(document.documentElement, {
                childList: true,
                subtree: true
            });
        }
    };


    /* ============================================================
       ICONOS SVG
       Catálogo genérico. Todos comparten:
       - viewBox 24x24
       - fill none
       - stroke currentColor
       - stroke-linecap / join round
       ============================================================ */
    VCT.Icon = {
        icons: {
            "plus": '<path d="M12 5v14M5 12h14"/>',
            "save": '<path d="M5 4h12l2 2v14H5z"/><path d="M8 4v6h8V4M8 20v-6h8v6"/>',
            "check": '<path d="m5 12 4 4L19 6"/>',
            "x": '<path d="M6 6l12 12M18 6 6 18"/>',
            "arrow-left": '<path d="m15 18-6-6 6-6"/>',
            "arrow-right": '<path d="m9 18 6-6-6-6"/>',
            "chevron-left": '<path d="m15 18-6-6 6-6"/>',
            "chevron-right": '<path d="m9 18 6-6-6-6"/>',
            "chevrons-left": '<path d="m13 17-5-5 5-5M19 17l-5-5 5-5"/>',
            "chevrons-right": '<path d="m11 17 5-5-5-5M5 17l5-5-5-5"/>',
            "chevrons-up-down": '<path d="m7 15 5 5 5-5M17 9l-5-5-5 5"/>',
            "trash": '<path d="M4 7h16M9 7V4h6v3M7 7l1 13h8l1-13M10 11v5M14 11v5"/>',
            "rotate-ccw": '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>',
            "search": '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
            "edit": '<path d="M4 20h4l11-11a2.8 2.8 0 0 0-4-4L4 16v4z"/><path d="m13.5 6.5 4 4"/>',
            "eye": '<path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z"/><circle cx="12" cy="12" r="2.5"/>',
            "scan-eye": '<path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3"/><path d="M6.5 12s2-3.5 5.5-3.5 5.5 3.5 5.5 3.5-2 3.5-5.5 3.5S6.5 12 6.5 12z"/><circle cx="12" cy="12" r="1.5"/>',
            "copy": '<rect x="8" y="8" width="11" height="11" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
            "ellipsis": '<circle cx="5" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.4" fill="currentColor" stroke="none"/>',
            "file-text": '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v5h5M9 13h6M9 17h6M9 9h2"/>',
            "file-spreadsheet": '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v5h5M9 13h6M9 17h6M9 9h2"/>',
            "download": '<path d="M12 3v12M7 10l5 5 5-5M5 20h14"/>',
            "users": '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
            "user-plus": '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="M19 8v6M16 11h6"/>',
            "user-check": '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="m16 11 2 2 4-4"/>',
            "user-minus": '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="M16 11h6"/>',
            "user-x": '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="m17 9 5 5M22 9l-5 5"/>',
            "lock": '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
            "home": '<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10M9 20v-6h6v6"/>',
            "folder": '<path d="M3 6h7l2 2h9v11H3z"/>',

            "map-pin": '<path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0z"/><circle cx="12" cy="10" r="2.5"/>',
            "calendar-days": '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/>',
            "clock-3": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
            "list-checks": '<path d="m3 6 2 2 4-4M3 12l2 2 4-4M3 18l2 2 4-4M12 6h9M12 12h9M12 18h9"/>',
            "circle-dollar-sign": '<circle cx="12" cy="12" r="9"/><path d="M16 8h-6a2 2 0 0 0 0 4h4a2 2 0 0 1 0 4H8M12 6v12"/>',
            "chart-no-axes-column-increasing": '<path d="M3 20h18M6 16v-4M12 16V8M18 16V4"/>',
            "phone": '<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.4 19.4 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.9a2 2 0 0 1-.5 2.1L8 10a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.9.6 2.9.7A2 2 0 0 1 22 16.9z"/>',
            "mail": '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
            "contact": '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M6 16c.7-1.6 1.8-2.4 3-2.4s2.3.8 3 2.4M14 9h4M14 13h4"/>',
            "briefcase": '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V4h8v3M3 12h18"/>',
            "id-card": '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8" cy="11" r="2"/><path d="M5 16c.8-1.7 2-2.5 3-2.5s2.2.8 3 2.5M14 10h4M14 14h4"/>',
            "truck": '<path d="M3 6h11v10H3zM14 10h4l3 3v3h-7z"/><circle cx="7" cy="18" r="2"/><circle cx="18" cy="18" r="2"/>',
            "calendar": '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
            "bell": '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/>',
            "clipboard-check": '<path d="M9 5h6v3H9z"/><path d="M7 6H5v15h14V6h-2"/><path d="m9 15 2 2 4-4"/>',
            "chart-bar": '<path d="M4 20V10h4v10M10 20V4h4v16M16 20v-7h4v7M2 20h20"/>',
            "star": '<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2L3 9.6l6.2-.9L12 3z"/>',
            "settings": '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.83 2.83-.06-.06A1.7 1.7 0 0 0 15 19.4a1.7 1.7 0 0 0-1 .6 1.7 1.7 0 0 0-.4 1.1V21h-4v-.1a1.7 1.7 0 0 0-1.1-1.6 1.7 1.7 0 0 0-1.88.34l-.06.06-2.83-2.83.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-.6-1 1.7 1.7 0 0 0-1.1-.4H3v-4h.1A1.7 1.7 0 0 0 4.7 8.5a1.7 1.7 0 0 0-.34-1.88l-.06-.06 2.83-2.83.06.06A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-.6 1.7 1.7 0 0 0 .4-1.1V3h4v.1a1.7 1.7 0 0 0 1.1 1.6 1.7 1.7 0 0 0 1.88-.34l.06-.06 2.83 2.83-.06.06A1.7 1.7 0 0 0 19.4 9a1.7 1.7 0 0 0 .6 1 1.7 1.7 0 0 0 1.1.4h.1v4h-.1a1.7 1.7 0 0 0-1.7.6z"/>',
            "help-circle": '<circle cx="12" cy="12" r="9"/><path d="M9.8 9a2.5 2.5 0 1 1 3.8 2.1c-1 .7-1.6 1.1-1.6 2.4M12 17h.01"/>'
        },

        render: function (el) {
            if (!el || el.dataset.vctIconReady === "1") return;

            var name = VCT.Util.trim(el.getAttribute("data-vct-icon")).toLowerCase();
            var body = VCT.Icon.icons[name];
            if (!body) return;

            el.innerHTML =
                '<svg class="vct-icon-svg" width="16" height="16" viewBox="0 0 24 24" ' +
                'fill="none" stroke="currentColor" stroke-width="1.8" ' +
                'stroke-linecap="round" stroke-linejoin="round" ' +
                'aria-hidden="true" focusable="false">' + body + '</svg>';

            el.dataset.vctIconReady = "1";
        },

        init: function (scope) {
            scope = scope || document;

            if (scope.matches && scope.matches("[data-vct-icon]"))
                VCT.Icon.render(scope);

            if (!scope.querySelectorAll) return;

            scope.querySelectorAll("[data-vct-icon]").forEach(function (el) {
                VCT.Icon.render(el);
            });
        }
    };

    /* ============================================================
       BADGES
       Convierte data-vct-badge en clases estándar.
       ============================================================ */
    VCT.Badge = {
        typeFor: function (value) {
            value = VCT.Util.trim(value).toUpperCase();

            /* Semántica global única para todas las grillas. */
            if (value === "ACTIVO" || value === "ACTIVA" || value === "OK" ||
                value === "CUMPLIDO" || value === "CUMPLIDA" ||
                value === "COMPLETADO" || value === "COMPLETADA" ||
                value === "FINALIZADO" || value === "FINALIZADA")
                return "success";

            if (value === "EN CURSO" || value === "ENCURSO" ||
                value === "EN PROCESO" || value === "EN_PROCESO" ||
                value === "PROGRAMADO" || value === "PROGRAMADA" ||
                value === "HOY" || value === "PRÓXIMA" || value === "PROXIMA")
                return "info";

            if (value === "PENDIENTE" || value === "EN ESPERA" || value === "EN_ESPERA" ||
                value === "CONFIRMADO" || value === "CONFIRMADA" ||
                value === "PAUSADO" || value === "PAUSADA" ||
                value === "PLANIFICADO" || value === "PLANIFICADA" ||
                value === "SI" || value === "SÍ")
                return "warning";

            if (value === "ERROR" || value === "VENCIDO" || value === "VENCIDA" ||
                value === "CANCELADO" || value === "CANCELADA" ||
                value === "ANULADO" || value === "ANULADA")
                return "danger";

            /* Estados comerciales de clientes: criterio global y reutilizable. */
            if (value === "PASIVO" || value === "PASIVA")
                return "info";

            if (value === "DESAFECTADO" || value === "DESAFECTADA")
                return "danger";

            /* TERMINADO queda neutral: es histórico, no un estado positivo/activo. */
            if (value === "TERMINADO" || value === "TERMINADA" || value === "NO")
                return "neutral";

            if (value === "INFORMACION" || value === "INFORMACIÓN")
                return "info";

            return "neutral";
        },

        render: function (el) {
            if (!el) return;

            ["success","warning","danger","info","neutral"].forEach(function (type) {
                el.classList.remove("vct-badge-" + type);
            });

            el.classList.add("vct-badge-" + VCT.Badge.typeFor(el.getAttribute("data-vct-badge")));
        },

        init: function (scope) {
            scope = scope || document;

            if (scope.matches && scope.matches("[data-vct-badge]"))
                VCT.Badge.render(scope);

            if (!scope.querySelectorAll) return;

            scope.querySelectorAll("[data-vct-badge]").forEach(function (el) {
                VCT.Badge.render(el);
            });
        }
    };

    /* ============================================================
       TOOLTIPS
       Usa title nativo como fallback seguro.
       El CSS puede reemplazarlo visualmente más adelante.
       ============================================================ */
    VCT.Tooltip = {
        render: function (el) {
            if (!el) return;
            var text = VCT.Util.trim(el.getAttribute("data-vct-tooltip"));
            if (text && !el.getAttribute("title"))
                el.setAttribute("title", text);
        },

        init: function (scope) {
            scope = scope || document;

            if (scope.matches && scope.matches("[data-vct-tooltip]"))
                VCT.Tooltip.render(scope);

            if (!scope.querySelectorAll) return;

            scope.querySelectorAll("[data-vct-tooltip]").forEach(function (el) {
                VCT.Tooltip.render(el);
            });
        }
    };

    /* ============================================================
       ACCIONES DE GRILLA
       Usa PrmActions declarada por el SP:
       ACTION + StorageKey + TargetGuid + TargetTab.
       ============================================================ */
    VCT.Action = {
        execute: function (element) {
            var actionId = VCT.Util.trim(element.getAttribute("data-vct-action-id"));
            var storeField = VCT.Util.trim(element.getAttribute("data-vct-store"));
            var value = element.getAttribute("data-vct-value");
            var guid = VCT.Util.trim(element.getAttribute("data-vct-guid"));

            /* Compatibilidad con parametrías viejas de negocio.
               Si el campo ya no existe en VCT_BUFFER, usamos el slot genérico. */
            if (storeField && !VCT.Buffer.getInput(storeField) && VCT.Buffer.getInput("IDSELEC01"))
                storeField = "IDSELEC01";

            if (storeField)
                VCT.Buffer.store(storeField, value === null ? "" : value);

            if (actionId)
                VCT.Buffer.store("ACTION", actionId);

            if (guid)
                return VCT.Navigation.goto(element, guid);

            return VCT.Navigation.next(element);
        }
    };

    /* ============================================================
       COMANDOS GENERICOS
       ============================================================ */
    VCT.Command = {
        execute: function (element, event) {
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }

            var command = VCT.Util.trim(element.dataset.vctCommand).toLowerCase();
            if (!command) return false;

            switch (command) {
                case "open-modal":
                    VCT.Modal.open(element.dataset.vctTarget);
                    return false;
                case "close-modal":
                    VCT.Modal.close(element.dataset.vctTarget);
                    return false;
                case "open-drawer":
                    VCT.Drawer.open(element.dataset.vctTarget);
                    return false;
                case "close-drawer":
                    VCT.Drawer.close(element.dataset.vctTarget);
                    return false;
                case "save":
                    return VCT.Command.save(element);
                case "next":
                    return VCT.Command.next(element);
                case "goto":
                    return VCT.Command.goto(element);
                case "sidebar-toggle":
                    VCT.Sidebar.toggle();
                    return false;
                case "sidebar-close":
                    VCT.Sidebar.closeMobile();
                    return false;
                case "grid-action":
                    return VCT.Action.execute(element);
                default:
                    console.warn("[VCT] Comando no implementado:", command);
                    return false;
            }
        },
        save: function (element) {
            var scope = element.closest("[data-vct-form-scope]") ||
                        VCT.Util.findPage(element) || document;
            if (!VCT.Validation.validate(scope)) return false;
            VCT.Buffer.store("ACTION", element.dataset.vctAction || "SAVE");
            return VCT.Navigation.next(element);
        },
        next: function (element) {
            if (element.dataset.vctAction)
                VCT.Buffer.store("ACTION", element.dataset.vctAction);
            return VCT.Navigation.next(element);
        },
        goto: function (element) {
            var storeField = VCT.Util.trim(element.dataset.vctStore);
            if (storeField)
                VCT.Buffer.store(storeField, element.dataset.vctValue);

            if (element.dataset.vctAction)
                VCT.Buffer.store("ACTION", element.dataset.vctAction);

            return VCT.Navigation.goto(element, element.dataset.vctGuid);
        }
    };

    /* ============================================================
       INICIALIZACION
       ============================================================ */
    VCT.init = function () {
        /* IMPORTANTE:
           capturamos el click ANTES del onclick inline del SP.
           newTaskForContactWithParams puede iniciar navegación inmediatamente,
           por eso el active debe persistirse en fase capture. */
        document.addEventListener("click", function (event) {
            var sidebarLink = event.target.closest(".vct-sidebar-link[data-vct-mod]");
            if (!sidebarLink) return;

            VCT.Sidebar.setActive(sidebarLink.getAttribute("data-vct-mod"));
        }, true);

        document.addEventListener("click", function (event) {
            var commandButton = event.target.closest("[data-vct-command]");
            if (commandButton) {
                VCT.Command.execute(commandButton, event);
                return;
            }

            if (event.target.closest("[data-vct-sidebar-backdrop]"))
                VCT.Sidebar.closeMobile();
        });

        document.addEventListener("keydown", function (event) {
            if (event.key !== "Escape") return;
            VCT.Modal.close();
            VCT.Drawer.close();
            VCT.Sidebar.closeMobile();
        });

        window.addEventListener("resize", function () {
            if (!VCT.Sidebar.isMobile())
                VCT.Sidebar.closeMobile();
            else
                document.body.classList.remove("vct-sidebar-expanded");
        });

        VCT.Select.init(document);
        VCT.Icon.init(document);
        VCT.Badge.init(document);
        VCT.Tooltip.init(document);
        VCT.Sidebar.init();
        VCT.Dynamic.init();

        /* El framework puede insertar contenido después del DOMContentLoaded. */
        window.setTimeout(function () {
            VCT.Select.init(document);
            VCT.Icon.init(document);
            VCT.Badge.init(document);
            VCT.Tooltip.init(document);
            VCT.Sidebar.init();
        }, 150);

        console.log("[VCT-MAIN] vct-main.js v15 inicializado.");
    };

    window.VCT = VCT;

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", VCT.init);
    else
        VCT.init();

})(window, document);


/* =========================================================================
   VCT MAIN V16 - HOME ACTIVE FIX
   SOLO corrige el estado active del sidebar.
   No modifica navegación ni newTaskForContactWithParams.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT || !window.VCT.Sidebar) return;

    var Sidebar = window.VCT.Sidebar;
    var FORCE_KEY = "VCT_SIDEBAR_SELECTED_MODULE";

    function apply(moduleId) {
        if (moduleId === null || moduleId === undefined || String(moduleId) === "")
            return;

        moduleId = String(moduleId);

        window.VCT_ACTIVE_MODULE = moduleId;
        document.documentElement.setAttribute("data-vct-active", moduleId);

        try {
            window.sessionStorage.setItem(FORCE_KEY, moduleId);
        } catch (e) {}

        if (typeof Sidebar.applyActive === "function")
            Sidebar.applyActive(moduleId);
    }

    /* Mantiene compatibilidad con el onclick generado por VCT_GET_SIDEBAR */
    window.vctSetActiveModule = function (moduleId) {
        apply(moduleId);

        if (typeof Sidebar.isMobile === "function" &&
            Sidebar.isMobile() &&
            typeof Sidebar.closeMobile === "function") {
            Sidebar.closeMobile();
        }
    };

    window.vctApplyActiveModule = function (moduleId) {
        apply(moduleId);
    };

    /* Capture phase: corre ANTES de newTaskForContactWithParams */
    document.addEventListener("click", function (event) {
        var link = event.target.closest(".vct-sidebar-link[data-vct-mod]");
        if (!link) return;

        apply(link.getAttribute("data-vct-mod"));
    }, true);

    function restore() {
        var sidebar = document.getElementById("muhleSideBar");
        if (!sidebar) return;

        var moduleId = "";

        try {
            moduleId = window.sessionStorage.getItem(FORCE_KEY) || "";
        } catch (e) {}

        if (!moduleId) {
            moduleId = document.documentElement.getAttribute("data-vct-active") || "";
        }

        if (!moduleId) {
            var first = sidebar.querySelector(".vct-sidebar-link[data-vct-mod]");
            if (first)
                moduleId = String(first.getAttribute("data-vct-mod") || "");
        }

        if (moduleId)
            Sidebar.applyActive(moduleId);
    }

    /* Reaplica después de reemplazos parciales del framework */
    var queued = false;
    new MutationObserver(function () {
        if (queued) return;
        queued = true;

        window.setTimeout(function () {
            queued = false;
            restore();
        }, 25);
    }).observe(document.documentElement, {
        childList:true,
        subtree:true
    });

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", restore);
    else
        restore();

})(window, document);


/* =========================================================================
   VCT MAIN V17 - PARCHE FINAL
   SOLO:
   - V del sidebar funciona como toggle.
   - Home/primer item mantiene active de forma robusta.
   - Select puede abrir hacia arriba cuando no hay espacio inferior.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT) return;

    /* -------------------------------------------------------------
       1. V DEL SIDEBAR = TOGGLE
       ------------------------------------------------------------- */
    document.addEventListener("click", function (event) {
        var mark = event.target.closest("#muhleSideBar .vct-sidebar-brand-mark");
        if (!mark) return;

        event.preventDefault();
        event.stopPropagation();

        if (window.VCT.Sidebar && typeof window.VCT.Sidebar.toggle === "function")
            window.VCT.Sidebar.toggle();
    }, true);

    /* -------------------------------------------------------------
       2. HOME ACTIVE ROBUSTO
       Guardamos explícitamente si se eligió el primer item.
       Observamos también cambios de class porque scripts internos del
       sidebar pueden volver a tocar la clase active después del click.
       ------------------------------------------------------------- */
    var ACTIVE_SELECTION_KEY = "VCT_SIDEBAR_ACTIVE_SELECTION";
    var applyingActive = false;

    function getSidebar() {
        return document.getElementById("muhleSideBar");
    }

    function setPersistedActive(link) {
        if (!link) return;

        var sidebar = getSidebar();
        if (!sidebar) return;

        var links = Array.prototype.slice.call(
            sidebar.querySelectorAll(".vct-sidebar-link[data-vct-mod]")
        );

        var index = links.indexOf(link);
        var moduleId = String(link.getAttribute("data-vct-mod") || "");

        var value = index === 0 ? "__HOME__" : moduleId;

        try {
            window.sessionStorage.setItem(ACTIVE_SELECTION_KEY, value);
        } catch (e) {}

        applyPersistedActive();
    }

    function applyPersistedActive() {
        if (applyingActive) return;

        var sidebar = getSidebar();
        if (!sidebar) return;

        var links = Array.prototype.slice.call(
            sidebar.querySelectorAll(".vct-sidebar-link[data-vct-mod]")
        );
        if (!links.length) return;

        var persisted = "";
        try {
            persisted = window.sessionStorage.getItem(ACTIVE_SELECTION_KEY) || "";
        } catch (e) {}

        var target = null;

        if (persisted === "__HOME__") {
            target = links[0];
        } else if (persisted) {
            for (var i = 0; i < links.length; i++) {
                if (String(links[i].getAttribute("data-vct-mod") || "") === persisted) {
                    target = links[i];
                    break;
                }
            }
        }

        /* Primera entrada al sistema: Inicio por defecto */
        if (!target && !persisted)
            target = links[0];

        if (!target) return;

        applyingActive = true;

        links.forEach(function (link) {
            link.classList.toggle("active", link === target);
        });

        var targetModule = String(target.getAttribute("data-vct-mod") || "");
        document.documentElement.setAttribute("data-vct-active", targetModule);
        window.VCT_ACTIVE_MODULE = targetModule;

        window.setTimeout(function () {
            applyingActive = false;
        }, 0);
    }

    /* Corre antes del onclick inline/newTaskForContactWithParams */
    document.addEventListener("click", function (event) {
        var link = event.target.closest("#muhleSideBar .vct-sidebar-link[data-vct-mod]");
        if (!link) return;

        setPersistedActive(link);
    }, true);

    /* Reaplica si otro script cambia las clases del sidebar */
    var activeObserver = new MutationObserver(function (mutations) {
        if (applyingActive) return;

        var relevant = mutations.some(function (m) {
            return m.type === "attributes" &&
                   m.attributeName === "class" &&
                   m.target &&
                   m.target.classList &&
                   m.target.classList.contains("vct-sidebar-link");
        });

        if (relevant)
            window.setTimeout(applyPersistedActive, 0);
    });

    function observeSidebar() {
        var sidebar = getSidebar();
        if (!sidebar) return;

        activeObserver.disconnect();
        activeObserver.observe(sidebar, {
            subtree:true,
            attributes:true,
            attributeFilter:["class"]
        });

        applyPersistedActive();
    }

    /* -------------------------------------------------------------
       3. SELECT DROP-UP AUTOMÁTICO
       ------------------------------------------------------------- */
    function updateSelectDirection(wrap) {
        if (!wrap) return;

        var trigger = wrap.querySelector(".vct-custom-select-trigger");
        var menu = wrap.querySelector(".vct-custom-select-menu");
        if (!trigger || !menu) return;

        wrap.classList.remove("is-dropup");

        var rect = trigger.getBoundingClientRect();
        var availableBelow = window.innerHeight - rect.bottom;
        var availableAbove = rect.top;

        /* Altura estimada real del menú, limitada por max-height */
        var menuHeight = Math.min(
            menu.scrollHeight || 220,
            220
        ) + 10;

        if (availableBelow < menuHeight && availableAbove > availableBelow)
            wrap.classList.add("is-dropup");
    }

    document.addEventListener("click", function (event) {
        var trigger = event.target.closest(".vct-custom-select-trigger");
        if (!trigger) return;

        var wrap = trigger.closest(".vct-custom-select");
        if (!wrap) return;

        window.setTimeout(function () {
            if (wrap.classList.contains("is-open"))
                updateSelectDirection(wrap);
            else
                wrap.classList.remove("is-dropup");
        }, 0);
    }, true);

    window.addEventListener("resize", function () {
        document.querySelectorAll(".vct-custom-select.is-open").forEach(function (wrap) {
            updateSelectDirection(wrap);
        });
    });

    /* Inicialización */
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", function () {
            observeSidebar();
        });
    } else {
        observeSidebar();
    }

    /* Cuando Muhle reconstruye el sidebar, volver a observar */
    new MutationObserver(function (mutations) {
        var needsInit = mutations.some(function (m) {
            if (!m.addedNodes) return false;

            for (var i = 0; i < m.addedNodes.length; i++) {
                var node = m.addedNodes[i];
                if (!node || node.nodeType !== 1) continue;

                if (node.id === "muhleSideBar" ||
                    (node.querySelector && node.querySelector("#muhleSideBar")))
                    return true;
            }
            return false;
        });

        if (needsInit)
            window.setTimeout(observeSidebar, 20);

    }).observe(document.documentElement, {
        childList:true,
        subtree:true
    });

    console.log("[VCT-MAIN] ajustes finales v17 inicializados.");
})(window, document);


/* VCT SIDEBAR V4 - rail fijo: limpiar estados visuales heredados */
(function(document){
    function vctLockSidebarRail(){
        document.body.classList.remove("vct-sidebar-expanded");
        document.body.classList.remove("vct-sidebar-mobile-open");
        try{ window.localStorage.setItem("VCT_SIDEBAR_EXPANDED","0"); }catch(e){}
    }

    vctLockSidebarRail();

    if(document.readyState==="loading")
        document.addEventListener("DOMContentLoaded",vctLockSidebarRail);
    else
        vctLockSidebarRail();
})(document);


/* VCT SIDEBAR V5 - mobile inicia cerrado; desktop permanece rail fijo */
(function(window, document){
    function vctSidebarV5Init(){
        document.body.classList.remove("vct-sidebar-expanded");
        if(window.matchMedia && window.matchMedia("(max-width:1024px)").matches){
            document.body.classList.remove("vct-sidebar-mobile-open");
        }
    }

    vctSidebarV5Init();

    window.addEventListener("resize", function(){
        if(window.matchMedia && !window.matchMedia("(max-width:1024px)").matches){
            document.body.classList.remove("vct-sidebar-mobile-open");
        }
    });
})(window, document);


/* =========================================================================
   VCT MAIN - FORM DOM / STATE / SERVER FEEDBACK GENERICO
   ========================================================================= */
(function () {
    "use strict";
    if (!window.VCT) return;

    VCT.FormState = VCT.FormState || {};

    VCT.FormState.resetValidation = function (scope) {
        if (!scope) return;

        if (VCT.Validation && typeof VCT.Validation.clear === "function")
            VCT.Validation.clear(scope);

        scope.querySelectorAll("[aria-invalid]").forEach(function (el) {
            el.removeAttribute("aria-invalid");
        });

        if (VCT.Select && typeof VCT.Select.closeAll === "function")
            VCT.Select.closeAll();
    };

    VCT.FormState.suppressAutoOpenUntil = 0;

    VCT.FormState.suppressAutoOpen = function (milliseconds) {
        milliseconds = Number(milliseconds) || 0;
        VCT.FormState.suppressAutoOpenUntil = Math.max(
            Number(VCT.FormState.suppressAutoOpenUntil) || 0,
            Date.now() + milliseconds
        );
    };

    VCT.FormState.isAutoOpenSuppressed = function () {
        return Date.now() < (Number(VCT.FormState.suppressAutoOpenUntil) || 0);
    };

    VCT.FormState.openServerFeedback = function (scope) {
        scope = scope || document;

        /* Una entrada NUEVA a Vista 360 debe iniciar siempre limpia en
           Resumen. Durante la inserción dinámica de OUTPARAMs bloqueamos
           cualquier data-vct-auto-open heredado de la Vista 360 anterior.
           Los errores de validación internos siguen funcionando porque el
           SP devuelve data-vct-tabs-reset=0 en esos casos. */
        if (VCT.FormState.isAutoOpenSuppressed()) return;

        scope.querySelectorAll(
            '[data-vct-auto-open="true"][data-vct-component="modal"],' +
            '[data-vct-auto-open="true"][data-vct-component="drawer"]'
        ).forEach(function (component) {
            if (component.dataset.vctAutoOpened === "1") return;
            component.dataset.vctAutoOpened = "1";

            var id = component.id || component.getAttribute("data-vct-id");
            if (!id) return;

            if (component.getAttribute("data-vct-component") === "drawer")
                VCT.Drawer.open(id);
            else
                VCT.Modal.open(id);
        });
    };

    VCT.DomForm = VCT.DomForm || {};

    VCT.DomForm.getSource = function (element) {
        var selector =
            element.getAttribute("data-vct-source-selector") || "[data-vct-row]";
        return element.closest(selector);
    };

    VCT.DomForm.syncVisualField = function (field) {
        if (!field || field.getAttribute("data-vct-native") === "true") return;

        if (field.tagName === "SELECT" &&
            VCT.Select &&
            typeof VCT.Select.sync === "function") {

            var wrap = field.nextElementSibling;
            if (wrap && wrap.classList &&
                wrap.classList.contains("vct-custom-select")) {
                VCT.Select.sync(field, wrap);
            }
        }
    };

    VCT.DomForm.fill = function (element, targetId) {
        var source = VCT.DomForm.getSource(element);
        var target = document.getElementById(targetId);

        if (!source || !target) return false;

        VCT.FormState.resetValidation(target);

        target.querySelectorAll("[data-vct-source]").forEach(function (field) {
            var key = VCT.Util.trim(field.getAttribute("data-vct-source"));
            if (!key) return;

            var value = source.getAttribute("data-vct-" + key);
            if (value === null || value === undefined) value = "";

            if (field.type === "checkbox") {
                field.checked =
                    value === "1" ||
                    String(value).toLowerCase() === "true" ||
                    String(value).toUpperCase() === "SI";
            } else {
                field.value = value;
            }

            field.dispatchEvent(new Event("change", { bubbles: true }));
            VCT.DomForm.syncVisualField(field);
        });

        return true;
    };

    /* ------------------------------------------------------------
       PUENTE FORMULARIO -> VCT_BUFFER
       ------------------------------------------------------------
       Los formularios dinamicos viven en el DOM, pero el SP consume
       VCT_BUFFER. Antes de next() sincronizamos TODOS los campos del
       formulario activo de forma generica, sin conocer la entidad.
       ------------------------------------------------------------ */
    VCT.DomForm.getFieldName = function (field) {
        if (!field) return "";

        var name = VCT.Util.trim(field.getAttribute("data-vct-field"));
        if (name) return name;

        name = VCT.Util.trim(field.getAttribute("name"));
        if (name.toUpperCase().indexOf("SP.") === 0)
            return name.substring(3);

        /* Cuando un formulario está inactivo quitamos temporalmente name
           para que el framework no concatene SP.xxx repetidos. Conservamos
           el nombre original en este atributo para poder identificarlo al
           limpiar la Vista 360 completa desde el breadcrumb. */
        name = VCT.Util.trim(field.getAttribute("data-vct-buffer-original-name"));
        if (name.toUpperCase().indexOf("SP.") === 0)
            return name.substring(3);

        return "";
    };

    VCT.DomForm.getFieldValue = function (field) {
        if (!field) return "";

        if (field.type === "checkbox")
            return field.checked ? "1" : "0";

        if (field.type === "radio")
            return field.checked ? field.value : null;

        return field.value === null || field.value === undefined ? "" : field.value;
    };

    /* --------------------------------------------------------
       SCOPE ACTIVO DE FORMULARIO
       --------------------------------------------------------
       Los drawers de una Vista 360 conviven simultáneamente en el DOM
       y reutilizan slots de buffer (SP.TEXTO11, SP.TEXTO12, etc.).
       El framework resuelve esos nombres desde el DOM; si hay varias
       copias con el mismo name termina enviando valores separados por
       comas. Dejamos con name únicamente al formulario activo y
       "estacionamos" los names de los demás drawers/modales.
       -------------------------------------------------------- */
    VCT.DomForm.getManagedScope = function (scope) {
        if (!scope) return null;

        if (scope.matches &&
            scope.matches('[data-vct-component="drawer"],[data-vct-component="modal"],[data-vct-form-scope]'))
            return scope;

        if (scope.closest)
            return scope.closest('[data-vct-component="drawer"],[data-vct-component="modal"],[data-vct-form-scope]');

        return null;
    };

    VCT.DomForm.activateScope = function (scope) {
        var active = VCT.DomForm.getManagedScope(scope) || scope;
        if (!active || !active.querySelectorAll) return false;

        /* Los drawers pueden llegar por OUTPARAM3 y quedar fuera de
           [data-vct-page]. Por eso la exclusividad de names se resuelve
           contra document y no contra el contenedor visual de la página.

           IMPORTANTE: [data-vct-form-scope] participa SIEMPRE, no sólo
           como fallback cuando no hay ningún modal/drawer en la página.
           Un formulario PAGE (por ejemplo el editor de Email Templates)
           puede convivir en la misma pantalla con modales que reusan los
           mismos slots del buffer (TEXTO01..TEXTO11). Si se lo excluye
           acá cuando YA hay modales, su name original nunca se estaciona
           y storeQueued() lo detecta como copia duplicada apenas se
           guarda cualquier otro formulario de esa misma página. */
        var host = document;
        var roots = Array.prototype.slice.call(
            host.querySelectorAll(
                '[data-vct-component="drawer"],' +
                '[data-vct-component="modal"],' +
                '[data-vct-form-scope]'
            )
        );

        roots.forEach(function (root) {
            root.querySelectorAll('[name^="SP."],[data-vct-buffer-original-name]').forEach(function (field) {
                var originalName =
                    VCT.Util.trim(field.getAttribute('data-vct-buffer-original-name')) ||
                    VCT.Util.trim(field.getAttribute('name'));

                if (!originalName || originalName.toUpperCase().indexOf('SP.') !== 0)
                    return;

                if (!field.getAttribute('data-vct-buffer-original-name'))
                    field.setAttribute('data-vct-buffer-original-name', originalName);

                if (root === active)
                    field.setAttribute('name', originalName);
                else
                    field.removeAttribute('name');
            });
        });

        host.querySelectorAll('[data-vct-framework-mirror]').forEach(function (field) {
            if (field.parentNode) field.parentNode.removeChild(field);
        });

        return true;
    };

    VCT.DomForm.findField = function (scope, fieldName) {
        if (!scope) return null;
        fieldName = VCT.Util.trim(fieldName);
        if (!fieldName) return null;

        return scope.querySelector('[data-vct-field="' + fieldName + '"]') ||
               scope.querySelector('[name="SP.' + fieldName + '"]');
    };

    VCT.DomForm.setFieldValue = function (scope, fieldName, value) {
        var field = VCT.DomForm.findField(scope, fieldName);
        if (!field) return false;

        if (field.type === "checkbox")
            field.checked = VCT.Util.toBool(value);
        else
            field.value = value === null || value === undefined ? "" : value;

        field.dispatchEvent(new Event("change", { bubbles:true }));
        VCT.DomForm.syncVisualField(field);
        return true;
    };

    VCT.DomForm.syncLocalCopies = function (fieldName, value, sourceField) {
        fieldName = VCT.Util.trim(fieldName);
        if (!fieldName) return false;

        var controls = [];
        var add = function (field) {
            if (!field || controls.indexOf(field) >= 0) return;
            controls.push(field);
        };

        if (sourceField) add(sourceField);

        document.querySelectorAll('[name="SP.' + fieldName + '"]').forEach(add);
        document.querySelectorAll('[data-vct-field="' + fieldName + '"]').forEach(add);
        add(document.getElementById(fieldName));

        controls.forEach(function (field) {
            if (!field) return;

            if (field.type === "checkbox") {
                field.checked = VCT.Util.toBool(value);
            } else if (field.type === "radio") {
                field.checked = String(field.value) === String(value);
            } else {
                field.value = value === null || value === undefined ? "" : value;
            }

            /* La copia activa mantiene sincronizada también su capa visual.
               Las copias ocultas sólo necesitan el valor para el framework. */
            if (field === sourceField) {
                field.dispatchEvent(new Event("change", { bubbles:true }));
                VCT.DomForm.syncVisualField(field);
            }
        });

        return controls.length > 0;
    };

    VCT.DomForm.syncFrameworkForm = function (scope, values) {
        if (!scope || !values) return false;

        var formId = VCT.Util.getFormId(scope);
        if (!formId) return false;

        var form =
            document.getElementById(formId) ||
            (document.forms ? document.forms[formId] : null) ||
            document.querySelector('form[name="' + formId + '"]');

        if (!form || String(form.tagName || "").toUpperCase() !== "FORM")
            return false;

        Object.keys(values).forEach(function (fieldName) {
            var value =
                values[fieldName] === null || values[fieldName] === undefined
                    ? ""
                    : String(values[fieldName]);

            var selector = '[name="SP.' + fieldName + '"]';
            var controls = Array.prototype.slice.call(
                form.querySelectorAll(selector)
            );

            if (!controls.length) {
                var hidden = document.createElement("input");
                hidden.type = "hidden";
                hidden.name = "SP." + fieldName;
                hidden.setAttribute("data-vct-framework-mirror", fieldName);
                form.appendChild(hidden);
                controls.push(hidden);
            }

            controls.forEach(function (field) {
                if (field.type === "checkbox")
                    field.checked = VCT.Util.toBool(value);
                else if (field.type === "radio")
                    field.checked = String(field.value) === value;
                else
                    field.value = value;
            });
        });

        return true;
    };

    VCT.DomForm.buildBufferPayload = function (scope) {
        if (!scope) return null;

        var primaryFields = Array.prototype.slice.call(
            scope.querySelectorAll('[data-vct-field]')
        );
        var fallbackFields = Array.prototype.slice.call(
            scope.querySelectorAll('[name^="SP."]')
        );

        var values = {};
        var sources = {};
        var order = [];

        var collect = function (field, allowOverwrite) {
            var fieldName = VCT.DomForm.getFieldName(field);
            if (!fieldName) return;

            if (!allowOverwrite &&
                Object.prototype.hasOwnProperty.call(values, fieldName))
                return;

            var value = VCT.DomForm.getFieldValue(field);
            if (value === null) return;

            if (!Object.prototype.hasOwnProperty.call(values, fieldName))
                order.push(fieldName);

            values[fieldName] = value;
            sources[fieldName] = field;
        };

        primaryFields.forEach(function (field) { collect(field, true); });
        fallbackFields.forEach(function (field) { collect(field, false); });

        if (!order.length) return null;

        /* Los flags de comando son el COMMIT de la operación. Se escriben
           después de los datos y del ACTIVE_TAB; el único flag que vale 1
           se manda último. Esto evita que el SP vea una orden con payload
           todavía incompleto cuando el framework persiste por AJAX. */
        var commandNames = ["FLAG01", "FLAG03", "FLAG04"];
        var normal = [];
        var zeroCommands = [];
        var activeTab = [];
        var commitCommands = [];

        order.forEach(function (fieldName) {
            if (fieldName === "ACTIVE_TAB") {
                activeTab.push(fieldName);
                return;
            }

            if (commandNames.indexOf(fieldName) >= 0) {
                if (VCT.Util.toBool(values[fieldName]))
                    commitCommands.push(fieldName);
                else
                    zeroCommands.push(fieldName);
                return;
            }

            normal.push(fieldName);
        });

        return {
            values: values,
            sources: sources,
            order: normal.concat(zeroCommands, activeTab, commitCommands)
        };
    };

    VCT.DomForm.syncToBuffer = function (scope, done) {
        done = typeof done === "function" ? done : function () {};

        /* Debe existir una sola copia nombrada de cada SP.xxx antes de
           almacenarSeleccion(); los demás drawers quedan sin atributo name. */
        VCT.DomForm.activateScope(scope);

        var payload = VCT.DomForm.buildBufferPayload(scope);
        if (!payload) {
            console.error("[VCT] El formulario no posee campos sincronizables.");
            VCT.Toast.show("No se pudieron preparar los datos del formulario.", "error");
            done(false);
            return false;
        }

        var index = 0;
        var runNext = function () {
            if (index >= payload.order.length) {
                done(true);
                return;
            }

            var fieldName = payload.order[index++];
            VCT.Buffer.storeQueued(
                fieldName,
                payload.values[fieldName],
                payload.sources[fieldName],
                function (ok) {
                    if (!ok) {
                        console.error("[VCT] No se pudo almacenar el campo:", fieldName);
                        VCT.Toast.show("No se pudieron enviar los datos. Intente nuevamente.", "error");
                        done(false);
                        return;
                    }
                    runNext();
                }
            );
        };

        runNext();
        return true;
    };

    VCT.DomForm.getActiveTab = function (scope) {
        var field = VCT.DomForm.findField(scope, "ACTIVE_TAB");
        var value = field ? VCT.DomForm.getFieldValue(field) : "";
        return VCT.Util.trim(value);
    };

    /* ------------------------------------------------------------
       LIMPIEZA TOTAL DE FORMULARIOS AL SALIR DE VISTA 360
       ------------------------------------------------------------
       El framework puede conservar los drawers/modales de una navegación
       anterior en el DOM. Además, VCT_BUFFER conserva los últimos TEXTOxx,
       FLAGxx e IDSELECxx si no se vacían explícitamente.

       Al volver por el breadcrumb:
       - limpiamos TODOS los campos de todos los forms, abiertos o no;
       - quitamos data-vct-auto-open para que ningún drawer viejo reaparezca;
       - dejamos todos los SP.xxx sin name durante la navegación para evitar
         que el framework concatene copias repetidas con comas;
       - vaciamos secuencialmente en VCT_BUFFER los slots que realmente usa
         la Vista 360 y dejamos ACTIVE_TAB=resumen;
       - recién después navegamos al listado.
       ------------------------------------------------------------ */
    VCT.DomForm.resetAllForNavigation = function (done) {
        done = typeof done === "function" ? done : function () {};

        var roots = Array.prototype.slice.call(
            document.querySelectorAll(
                '[data-vct-component="drawer"],' +
                '[data-vct-component="modal"],' +
                '[data-vct-form-scope]'
            )
        );

        /* Evita procesar dos veces un mismo nodo cuando, por ejemplo, un
           drawer también declara data-vct-form-scope. */
        roots = roots.filter(function (root, index, arr) {
            if (arr.indexOf(root) !== index) return false;

            /* Sólo forms pertenecientes al flujo interno de Vista 360.
               Así el breadcrumb no altera modales globales del framework. */
            var hasEntity = !!root.querySelector(
                '[data-vct-field="TEXTO30"],' +
                '[name="SP.TEXTO30"],' +
                '[data-vct-buffer-original-name="SP.TEXTO30"]'
            );
            var hasTab = !!root.querySelector(
                '[data-vct-field="ACTIVE_TAB"],' +
                '[name="SP.ACTIVE_TAB"],' +
                '[data-vct-buffer-original-name="SP.ACTIVE_TAB"]'
            );

            return hasEntity && hasTab;
        });

        var fieldNames = [];
        var seen = {};
        var addFieldName = function (name) {
            name = VCT.Util.trim(name);
            if (!name || seen[name]) return;
            seen[name] = true;
            fieldNames.push(name);
        };

        var clearField = function (field) {
            if (!field) return;

            if (field.type === "checkbox" || field.type === "radio") {
                field.checked = false;
            } else if (String(field.tagName || "").toUpperCase() === "SELECT") {
                var emptyOption = Array.prototype.some.call(
                    field.options || [],
                    function (option) { return String(option.value || "") === ""; }
                );

                if (emptyOption)
                    field.value = "";
                else
                    field.selectedIndex = -1;
            } else {
                field.value = "";
            }

            try {
                field.dispatchEvent(new Event("change", { bubbles:true }));
            } catch (e) {}

            VCT.DomForm.syncVisualField(field);
        };

        roots.forEach(function (root) {
            if (!root || !root.querySelectorAll) return;

            if (VCT.FormState && typeof VCT.FormState.resetValidation === "function")
                VCT.FormState.resetValidation(root);

            /* Un feedback de servidor de la operación anterior no debe poder
               reabrirse cuando el framework vuelva a insertar contenido. */
            root.removeAttribute("data-vct-auto-open");
            root.removeAttribute("data-vct-auto-opened");
            if (root.dataset) delete root.dataset.vctAutoOpened;
            root.classList.remove("is-open");

            root.querySelectorAll(
                '[data-vct-field],' +
                '[name^="SP."],' +
                '[data-vct-buffer-original-name]'
            ).forEach(function (field) {
                var fieldName = VCT.DomForm.getFieldName(field);
                if (fieldName) addFieldName(fieldName);

                var currentName = VCT.Util.trim(field.getAttribute("name"));
                var originalName = VCT.Util.trim(
                    field.getAttribute("data-vct-buffer-original-name")
                );

                if (!originalName && currentName.toUpperCase().indexOf("SP.") === 0) {
                    field.setAttribute("data-vct-buffer-original-name", currentName);
                }

                /* Ninguna copia nombrada participa de la navegación de salida. */
                if (currentName.toUpperCase().indexOf("SP.") === 0)
                    field.removeAttribute("name");

                clearField(field);
            });
        });

        document.querySelectorAll('[data-vct-framework-mirror]').forEach(function (field) {
            if (field.parentNode) field.parentNode.removeChild(field);
        });

        document.body.classList.remove("vct-drawer-open", "vct-modal-open");

        if (VCT.RowMenu && typeof VCT.RowMenu.close === "function")
            VCT.RowMenu.close();

        /* Campos de control que deben limpiarse aunque por una inserción
           parcial del framework algún drawer no esté actualmente en el DOM. */
        [
            "IDSELEC02",
            "TEXTO11",
            "TEXTO12",
            "TEXTO13",
            "TEXTO14",
            "TEXTO15",
            "TEXTO16",
            "TEXTO17",
            "TEXTO30",
            "FLAG01",
            "FLAG02",
            "FLAG03",
            "FLAG04",
            "ACTIVE_TAB"
        ].forEach(addFieldName);

        var values = {};
        fieldNames.forEach(function (name) {
            values[name] = /^FLAG\d+$/i.test(name) ? "0" : "";
        });

        values.IDSELEC01 = "";
        values.ACTIVE_TAB = "resumen";

        /* IDSELEC01 y ACTIVE_TAB se escriben al final. Antes se vacían todos
           los slots de los forms para que una próxima Vista 360 nazca limpia. */
        var order = fieldNames.filter(function (name) {
            return name !== "ACTIVE_TAB" && name !== "IDSELEC01";
        });

        if (order.indexOf("IDSELEC02") < 0) order.push("IDSELEC02");
        order.push("ACTIVE_TAB");
        order.push("IDSELEC01");

        var index = 0;
        var allOk = true;

        var next = function () {
            if (index >= order.length) {
                /* Si la limpieza terminó bien, retiramos del DOM los forms
                   internos de esta V360. Algunos flujos del framework
                   conservan OUTPARAM3 entre navegaciones y, si dejamos los
                   drawers anteriores, al entrar a otro cliente pueden quedar
                   IDs/campos duplicados o reaparecer un error viejo. */
                if (allOk) {
                    if (VCT.FormSelect && typeof VCT.FormSelect.closeAll === "function")
                        VCT.FormSelect.closeAll();

                    roots.forEach(function (root) {
                        if (root && root.parentNode)
                            root.parentNode.removeChild(root);
                    });
                }

                done(allOk);
                return;
            }

            var fieldName = order[index++];
            var value = Object.prototype.hasOwnProperty.call(values, fieldName)
                ? values[fieldName]
                : "";

            VCT.Buffer.storeQueued(fieldName, value, null, function (ok) {
                if (!ok) allOk = false;
                next();
            });
        };

        next();
        return true;
    };

    VCT.DomForm.validateAndNext = function (element) {
        /* Para formularios dinámicos el drawer/modal es la unidad completa:
           incluye campos visibles + hidden de control. */
        var scope =
            element.closest('[data-vct-component="drawer"]') ||
            element.closest('[data-vct-component="modal"]') ||
            element.closest("[data-vct-form-scope]") ||
            VCT.Util.findPage(element) ||
            document;

        if (!VCT.Validation.validate(scope)) return false;

        var activeTab = VCT.DomForm.getActiveTab(scope);
        if (activeTab && VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function")
            VCT.Tabs.rememberInternalTab(activeTab);

        if (element.disabled) return false;
        element.disabled = true;

        /* Las escrituras al buffer se hacen en serie. Navegamos solamente
           cuando terminaron para que el SP reciba payload + flag + tab. */
        VCT.DomForm.syncToBuffer(scope, function (ok) {
            if (!ok) {
                element.disabled = false;
                return;
            }

            window.setTimeout(function () {
                VCT.Navigation.next(element);
            }, 40);
        });

        return false;
    };

    /* Al cerrar/cancelar se limpia sólo la validación visual. */
    if (VCT.Modal && !VCT.Modal.__vctStateWrapped) {
        var modalCloseOriginal = VCT.Modal.close;
        VCT.Modal.close = function (id) {
            var modal = VCT.Modal.get(id);
            if (modal) VCT.FormState.resetValidation(modal);
            return modalCloseOriginal.call(VCT.Modal, id);
        };
        VCT.Modal.__vctStateWrapped = true;
    }

    if (VCT.Drawer && !VCT.Drawer.__vctStateWrapped) {
        var drawerCloseOriginal = VCT.Drawer.close;
        VCT.Drawer.close = function (id) {
            var drawer = VCT.Drawer.get(id);
            if (drawer) VCT.FormState.resetValidation(drawer);
            return drawerCloseOriginal.call(VCT.Drawer, id);
        };
        VCT.Drawer.__vctStateWrapped = true;
    }

    document.addEventListener("click", function (event) {
        var element = event.target.closest(
            "[data-vct-command='open-modal-data']," +
            "[data-vct-command='open-drawer-data']," +
            "[data-vct-command='validate-next']"
        );
        if (!element) return;

        event.preventDefault();
        event.stopImmediatePropagation();

        var command = VCT.Util.trim(
            element.getAttribute("data-vct-command")
        ).toLowerCase();

        var targetId = element.getAttribute("data-vct-target");

        if (command === "open-modal-data") {
            if (!VCT.DomForm.fill(element, targetId)) return false;
            VCT.Modal.open(targetId);
            return false;
        }

        if (command === "open-drawer-data") {
            if (!VCT.DomForm.fill(element, targetId)) return false;
            VCT.Drawer.open(targetId);
            return false;
        }

        if (command === "validate-next")
            return VCT.DomForm.validateAndNext(element);

        return false;
    }, true);

    /* Server validation:
       después del next() el SP puede devolver el formulario con
       data-vct-auto-open="true". Lo abrimos automáticamente sin recargar
       valores desde la fila, preservando exactamente lo enviado. */
    function initServerFeedback() {
        VCT.FormState.openServerFeedback(document);
    }

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", initServerFeedback);
    else
        setTimeout(initServerFeedback, 0);

    new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (node) {
                if (node.nodeType !== 1) return;
                VCT.FormState.openServerFeedback(node);
                if (node.matches &&
                    node.matches('[data-vct-auto-open="true"]'))
                    VCT.FormState.openServerFeedback(node.parentNode || document);
            });
        });
    }).observe(document.documentElement, { childList:true, subtree:true });

})();

/* =========================================================================
   VCT MAIN - FORM SELECT CUSTOM PORTAL
   -------------------------------------------------------------------------
   Select custom para formularios generados por VCT_MAIN_RENDER_FORM.
   - conserva el <select> real para SP.xxx
   - menú visual fuera del modal (append a body)
   - no genera scroll del modal
   - abre abajo o arriba según espacio disponible
   - una sola estética para MODAL / DRAWER / PAGE
   ========================================================================= */
(function () {
    "use strict";
    if (!window.VCT) return;

    VCT.FormSelect = VCT.FormSelect || {
        openWrap: null,

        close: function (wrap) {
            wrap = wrap || VCT.FormSelect.openWrap;
            if (!wrap) return;

            var menu = wrap.__vctPortalMenu;
            var trigger = wrap.querySelector(".vct-form-select-trigger");

            wrap.classList.remove("is-open");
            if (trigger) trigger.setAttribute("aria-expanded", "false");

            if (menu) {
                menu.classList.remove("is-open", "opens-up");
                menu.style.display = "none";
            }

            if (VCT.FormSelect.openWrap === wrap)
                VCT.FormSelect.openWrap = null;
        },

        closeAll: function (except) {
            if (VCT.FormSelect.openWrap &&
                VCT.FormSelect.openWrap !== except)
                VCT.FormSelect.close(VCT.FormSelect.openWrap);
        },

        sync: function (select, wrap) {
            if (!select || !wrap) return;

            var trigger = wrap.querySelector(".vct-form-select-trigger");
            var valueBox = wrap.querySelector(".vct-form-select-value");
            var selected = select.options[select.selectedIndex];
            var menu = wrap.__vctPortalMenu;

            if (valueBox) {
                valueBox.textContent = selected ? selected.text : "Seleccione...";
                valueBox.classList.toggle("is-placeholder", !select.value);
            }

            if (menu) {
                menu.querySelectorAll(".vct-form-select-option").forEach(function (option) {
                    var selectedNow =
                        String(option.getAttribute("data-value") || "") ===
                        String(select.value || "");

                    option.classList.toggle("is-selected", selectedNow);
                    option.setAttribute(
                        "aria-selected",
                        selectedNow ? "true" : "false"
                    );
                });
            }

            wrap.classList.toggle("is-disabled", !!select.disabled);
            if (trigger) trigger.disabled = !!select.disabled;
        },

        position: function (wrap) {
            if (!wrap) return;

            var trigger = wrap.querySelector(".vct-form-select-trigger");
            var menu = wrap.__vctPortalMenu;
            if (!trigger || !menu) return;

            var rect = trigger.getBoundingClientRect();
            var gap = 5;
            var viewportH =
                window.innerHeight || document.documentElement.clientHeight;

            var desired = Math.min(
                menu.scrollHeight || 180,
                190
            );

            var spaceBelow = viewportH - rect.bottom - 10;
            var spaceAbove = rect.top - 10;
            var opensUp = spaceBelow < Math.min(desired, 150) &&
                          spaceAbove > spaceBelow;

            var maxHeight = Math.max(
                90,
                Math.min(
                    190,
                    opensUp ? spaceAbove - gap : spaceBelow - gap
                )
            );

            menu.style.position = "fixed";
            menu.style.left = Math.round(rect.left) + "px";
            menu.style.width = Math.round(rect.width) + "px";
            menu.style.maxHeight = Math.round(maxHeight) + "px";
            menu.style.zIndex = "12000";

            if (opensUp) {
                menu.classList.add("opens-up");
                menu.style.top = "auto";
                menu.style.bottom =
                    Math.round(viewportH - rect.top + gap) + "px";
            } else {
                menu.classList.remove("opens-up");
                menu.style.bottom = "auto";
                menu.style.top = Math.round(rect.bottom + gap) + "px";
            }
        },

        open: function (wrap) {
            if (!wrap || wrap.classList.contains("is-disabled")) return;

            VCT.FormSelect.closeAll(wrap);

            var menu = wrap.__vctPortalMenu;
            var trigger = wrap.querySelector(".vct-form-select-trigger");
            if (!menu || !trigger) return;

            menu.style.display = "block";
            wrap.classList.add("is-open");
            menu.classList.add("is-open");
            trigger.setAttribute("aria-expanded", "true");

            VCT.FormSelect.openWrap = wrap;
            VCT.FormSelect.position(wrap);
        },

        build: function (select) {
            if (!select ||
                select.dataset.vctFormSelectReady === "1" ||
                !select.closest(".vct-form-shell") ||
                select.multiple ||
                select.size > 1) return;

            select.dataset.vctFormSelectReady = "1";
            select.classList.add("vct-custom-select-native");

            var wrap = document.createElement("div");
            wrap.className = "vct-form-select";
            wrap.setAttribute("data-vct-form-select", "");

            var trigger = document.createElement("button");
            trigger.type = "button";
            trigger.className = "vct-form-select-trigger";
            trigger.setAttribute("aria-haspopup", "listbox");
            trigger.setAttribute("aria-expanded", "false");

            var valueBox = document.createElement("span");
            valueBox.className = "vct-form-select-value";

            var chevron = document.createElementNS(
                "http://www.w3.org/2000/svg", "svg"
            );
            chevron.setAttribute("viewBox", "0 0 24 24");
            chevron.setAttribute("fill", "none");
            chevron.setAttribute("stroke", "currentColor");
            chevron.setAttribute("stroke-width", "2");
            chevron.setAttribute("class", "vct-form-select-chevron");

            var poly = document.createElementNS(
                "http://www.w3.org/2000/svg", "polyline"
            );
            poly.setAttribute("points", "6 9 12 15 18 9");
            chevron.appendChild(poly);

            trigger.appendChild(valueBox);
            trigger.appendChild(chevron);
            wrap.appendChild(trigger);

            select.parentNode.insertBefore(wrap, select.nextSibling);

            var menu = document.createElement("div");
            menu.className = "vct-form-select-menu";
            menu.setAttribute("role", "listbox");
            menu.style.display = "none";
            document.body.appendChild(menu);
            wrap.__vctPortalMenu = menu;

            Array.prototype.forEach.call(select.options, function (nativeOption) {
                var option = document.createElement("div");
                option.className = "vct-form-select-option";
                option.setAttribute("role", "option");
                option.setAttribute("data-value", nativeOption.value);
                option.textContent = nativeOption.text;

                if (nativeOption.disabled) {
                    option.classList.add("is-disabled");
                    option.setAttribute("aria-disabled", "true");
                }

                option.addEventListener("click", function (event) {
                    event.preventDefault();
                    event.stopPropagation();

                    if (nativeOption.disabled) return;

                    select.value = nativeOption.value;
                    select.dispatchEvent(
                        new Event("change", { bubbles: true })
                    );

                    VCT.FormSelect.sync(select, wrap);
                    VCT.FormSelect.close(wrap);
                    trigger.focus();
                });

                menu.appendChild(option);
            });

            trigger.addEventListener("click", function (event) {
                event.preventDefault();
                event.stopPropagation();

                if (select.disabled) return;

                if (wrap.classList.contains("is-open"))
                    VCT.FormSelect.close(wrap);
                else
                    VCT.FormSelect.open(wrap);
            });

            select.addEventListener("change", function () {
                VCT.FormSelect.sync(select, wrap);
            });

            VCT.FormSelect.sync(select, wrap);
        },

        init: function (scope) {
            scope = scope || document;

            if (scope.matches &&
                scope.matches(".vct-form-shell select.vct-select"))
                VCT.FormSelect.build(scope);

            scope.querySelectorAll &&
            scope.querySelectorAll(".vct-form-shell select.vct-select")
                 .forEach(function (select) {
                     VCT.FormSelect.build(select);
                 });
        }
    };

    /* El formulario usa este custom select aunque el renderer marque
       data-vct-native=true para que el Select general NO lo duplique. */
    function initFormSelects(scope) {
        VCT.FormSelect.init(scope || document);
    }

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", function () {
            initFormSelects(document);
        });
    else
        setTimeout(function () { initFormSelects(document); }, 0);

    new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (node) {
                if (node.nodeType !== 1) return;
                initFormSelects(node);
            });
        });
    }).observe(document.documentElement, {
        childList: true,
        subtree: true
    });

    /* Reposicionar mientras cambia viewport/scroll.
       No afecta el layout del modal. */
    window.addEventListener("resize", function () {
        if (VCT.FormSelect.openWrap)
            VCT.FormSelect.position(VCT.FormSelect.openWrap);
    });

    window.addEventListener("scroll", function () {
        if (VCT.FormSelect.openWrap)
            VCT.FormSelect.position(VCT.FormSelect.openWrap);
    }, true);

    document.addEventListener("click", function (event) {
        if (!VCT.FormSelect.openWrap) return;
        if (event.target.closest(".vct-form-select") ||
            event.target.closest(".vct-form-select-menu")) return;

        VCT.FormSelect.close(VCT.FormSelect.openWrap);
    });

    /* Integración con carga de registro en edición. */
    var oldSyncVisual =
        VCT.DomForm && VCT.DomForm.syncVisualField;

    if (VCT.DomForm) {
        VCT.DomForm.syncVisualField = function (field) {
            if (field &&
                field.tagName === "SELECT" &&
                field.closest(".vct-form-shell")) {

                var wrap = field.nextElementSibling;
                if (wrap &&
                    wrap.classList.contains("vct-form-select")) {
                    VCT.FormSelect.sync(field, wrap);
                    return;
                }
            }

            if (oldSyncVisual)
                return oldSyncVisual.call(VCT.DomForm, field);
        };
    }

    /* Al cerrar modal/drawer, cerrar también el popover. */
    if (VCT.Modal) {
        var closeModalBase = VCT.Modal.close;
        VCT.Modal.close = function (id) {
            VCT.FormSelect.closeAll();
            return closeModalBase.call(VCT.Modal, id);
        };
    }

    if (VCT.Drawer) {
        var closeDrawerBase = VCT.Drawer.close;
        VCT.Drawer.close = function (id) {
            VCT.FormSelect.closeAll();
            return closeDrawerBase.call(VCT.Drawer, id);
        };
    }
})();

/* =========================================================================
   VCT MAIN - OPCIONES DECLARATIVAS PARA CAMPOS DE FORMULARIO
   -------------------------------------------------------------------------
   Permite que un SP declare opciones sin agregar lógica de negocio al JS:

   <template data-vct-field-options
             data-vct-target="idFormulario"
             data-vct-field="TEXTOxx"
             data-vct-placeholder="Seleccione...">
       <option value="...">...</option>
   </template>

   El motor reemplaza el input original por un <select>, conserva name,
   data-vct-field, validaciones y valor actual, y reutiliza FormSelect.
   ========================================================================= */
(function (window, document) {
    "use strict";
    if (!window.VCT) return;

    VCT.FieldOptions = VCT.FieldOptions || {};

    VCT.FieldOptions.apply = function (config) {
        if (!config || config.dataset.vctFieldOptionsReady === "1")
            return false;

        var targetId = VCT.Util.trim(config.getAttribute("data-vct-target"));
        var fieldName = VCT.Util.trim(config.getAttribute("data-vct-field"));
        if (!targetId || !fieldName) return false;

        var target = document.getElementById(targetId);
        if (!target) return false;

        var field =
            target.querySelector('[data-vct-field="' + fieldName + '"]') ||
            target.querySelector('[name="SP.' + fieldName + '"]');

        if (!field) return false;

        var currentValue =
            field.type === "checkbox"
                ? (field.checked ? "1" : "0")
                : (field.value || "");

        var select = field;

        if (field.tagName !== "SELECT") {
            select = document.createElement("select");

            Array.prototype.forEach.call(field.attributes || [], function (attr) {
                var name = String(attr.name || "").toLowerCase();
                if (name === "type" || name === "value") return;
                select.setAttribute(attr.name, attr.value);
            });

            var className = String(select.className || "");
            className = className.replace(/\bvct-input\b/g, "vct-select");
            if (className.indexOf("vct-select") < 0)
                className += (className ? " " : "") + "vct-select";
            select.className = className;

            /* El select de formulario usa el portal específico y evita
               que el Select general cree una segunda capa visual. */
            select.setAttribute("data-vct-native", "true");

            field.parentNode.replaceChild(select, field);
        } else {
            while (select.firstChild)
                select.removeChild(select.firstChild);
        }

        var placeholder =
            VCT.Util.trim(config.getAttribute("data-vct-placeholder"));

        if (placeholder) {
            var placeholderOption = document.createElement("option");
            placeholderOption.value = "";
            placeholderOption.textContent = placeholder;
            select.appendChild(placeholderOption);
        }

        var sourceOptions =
            config.content
                ? config.content.querySelectorAll("option")
                : config.querySelectorAll("option");

        Array.prototype.forEach.call(sourceOptions, function (sourceOption) {
            select.appendChild(sourceOption.cloneNode(true));
        });

        select.value = currentValue;

        /* Compatibilidad con un valor histórico que ya exista en la tabla
           pero todavía no esté parametrizado en el catálogo. */
        if (currentValue && select.value !== currentValue) {
            var legacy = document.createElement("option");
            legacy.value = currentValue;
            legacy.textContent = currentValue;
            legacy.setAttribute("data-vct-legacy-option", "1");
            select.appendChild(legacy);
            select.value = currentValue;
        }

        config.dataset.vctFieldOptionsReady = "1";

        if (VCT.FormSelect && typeof VCT.FormSelect.build === "function")
            VCT.FormSelect.build(select);
        else if (VCT.Select && typeof VCT.Select.build === "function")
            VCT.Select.build(select);

        return true;
    };

    VCT.FieldOptions.init = function (scope) {
        scope = scope || document;

        if (scope.matches && scope.matches("[data-vct-field-options]"))
            VCT.FieldOptions.apply(scope);

        if (!scope.querySelectorAll) return;

        scope.querySelectorAll("[data-vct-field-options]").forEach(function (config) {
            VCT.FieldOptions.apply(config);
        });
    };

    function init(scope) {
        VCT.FieldOptions.init(scope || document);
    }

    if (document.readyState === "loading")
        document.addEventListener("DOMContentLoaded", function () {
            init(document);
        });
    else
        setTimeout(function () { init(document); }, 0);

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                Array.prototype.forEach.call(mutation.addedNodes || [], function (node) {
                    if (!node || node.nodeType !== 1) return;
                    init(node);

                    /* Si primero llegó el template y luego el formulario,
                       reintentamos todas las configuraciones pendientes. */
                    document.querySelectorAll(
                        "[data-vct-field-options]:not([data-vct-field-options-ready='1'])"
                    ).forEach(function (config) {
                        VCT.FieldOptions.apply(config);
                    });
                });
            });
        }).observe(document.documentElement, {
            childList:true,
            subtree:true
        });
    }

})(window, document);


/* =========================================================================
   VCT MAIN - FORM NEW/EDIT GENERICO
   -------------------------------------------------------------------------
   open-modal-empty:
   - limpia validaciones
   - limpia valores de una edición anterior
   - restaura data-vct-default
   - actualiza título/subtítulo/icono
   - abre el MISMO formulario
   ========================================================================= */
(function () {
    "use strict";
    if (!window.VCT || !VCT.DomForm) return;

    VCT.DomForm.setHeader = function (target, element) {
        if (!target || !element) return;

        var title = element.getAttribute("data-vct-form-title");
        var subtitle = element.getAttribute("data-vct-form-subtitle");
        var icon = element.getAttribute("data-vct-form-icon");

        var titleEl = target.querySelector("[data-vct-form-title]");
        var subtitleEl = target.querySelector("[data-vct-form-subtitle]");
        var iconEl = target.querySelector("[data-vct-form-icon]");

        if (title !== null && titleEl) titleEl.textContent = title;
        if (subtitle !== null && subtitleEl) subtitleEl.textContent = subtitle;

        if (icon !== null && iconEl) {
            /* El icono ya pudo haber sido renderizado previamente.
               Para cambiar EDIT -> NEW hay que resetear su estado antes
               de volver a pedirle al motor genérico que lo dibuje. */
            iconEl.setAttribute("data-vct-icon", icon);
            iconEl.removeAttribute("data-vct-icon-ready");
            delete iconEl.dataset.vctIconReady;
            iconEl.innerHTML = "";

            if (VCT.Icon && typeof VCT.Icon.render === "function")
                VCT.Icon.render(iconEl);
        }
    };

    VCT.DomForm.clear = function (target) {
        if (!target) return false;

        VCT.FormState.resetValidation(target);

        target.querySelectorAll("[data-vct-field]").forEach(function (field) {
            var def = field.getAttribute("data-vct-default");
            if (def === null) def = "";

            if (field.type === "checkbox") {
                field.checked =
                    def === "1" ||
                    String(def).toLowerCase() === "true" ||
                    String(def).toUpperCase() === "SI";
            } else {
                field.value = def;
            }

            field.dispatchEvent(new Event("change", { bubbles:true }));
            VCT.DomForm.syncVisualField(field);
        });

        return true;
    };

    document.addEventListener("click", function (event) {
        var element = event.target.closest(
            "[data-vct-command='open-modal-empty']," +
            "[data-vct-command='open-drawer-empty']"
        );
        if (!element) return;

        event.preventDefault();
        event.stopImmediatePropagation();

        var targetId = element.getAttribute("data-vct-target");
        var target = document.getElementById(targetId);
        if (!target) return false;

        VCT.DomForm.clear(target);
        VCT.DomForm.setHeader(target, element);

        var command = element.getAttribute("data-vct-command");
        if (command === "open-drawer-empty")
            VCT.Drawer.open(targetId);
        else
            VCT.Modal.open(targetId);

        return false;
    }, true);

    /* Edit también actualiza header de forma declarativa. */
    document.addEventListener("click", function (event) {
        var element = event.target.closest(
            "[data-vct-command='open-modal-data']," +
            "[data-vct-command='open-drawer-data']"
        );
        if (!element) return;

        var targetId = element.getAttribute("data-vct-target");
        var target = document.getElementById(targetId);
        if (target) VCT.DomForm.setHeader(target, element);
    }, true);
})();

/* =========================================================================
   VCT MAIN - FORM ACTION GENERICO
   -------------------------------------------------------------------------
   Comandos declarativos generados por VCT_MAIN_RENDER_FORM_ACTION:

       form-open-empty  -> alta / formulario limpio
       form-open-data   -> edición / carga desde data-vct-* de la fila

   El JS NO sabe qué entidad está editando.
   También detecta automáticamente MODAL / DRAWER / PAGE.
   ========================================================================= */
(function () {
    "use strict";
    if (!window.VCT || !VCT.DomForm) return;

    VCT.DomForm.openTarget = function (element, clearMode) {
        var targetId = element.getAttribute("data-vct-target");
        var target = document.getElementById(targetId);
        if (!target) return false;

        if (clearMode) {
            if (!VCT.DomForm.clear(target)) return false;
        } else {
            if (!VCT.DomForm.fill(element, targetId)) return false;
        }

        VCT.DomForm.activateScope(target);
        VCT.DomForm.setHeader(target, element);

        var component =
            VCT.Util.trim(target.getAttribute("data-vct-component")).toLowerCase();

        if (component === "modal") {
            VCT.Modal.open(targetId);
            return false;
        }

        if (component === "drawer") {
            VCT.Drawer.open(targetId);
            return false;
        }

        /* PAGE:
           ya forma parte del documento. Cargamos/limpiamos y lo llevamos a vista. */
        if (typeof target.scrollIntoView === "function") {
            target.scrollIntoView({
                behavior: "smooth",
                block: "start"
            });
        }

        return false;
    };

    document.addEventListener("click", function (event) {
        var element = event.target.closest(
            "[data-vct-command='form-open-empty']," +
            "[data-vct-command='form-open-data']"
        );
        if (!element) return;

        event.preventDefault();
        event.stopImmediatePropagation();

        var command =
            VCT.Util.trim(element.getAttribute("data-vct-command")).toLowerCase();

        return VCT.DomForm.openTarget(
            element,
            command === "form-open-empty"
        );
    }, true);
})();

/* =========================================================================
   VCT MAIN - VISTA 360 GENERICA / ESTABLE
   -------------------------------------------------------------------------
   - Tabs
   - Menú contextual por fila
   - Editar
   - Eliminar
   - Marcar principal
   - Ver ubicación en Google Maps
   ========================================================================= */
(function(){
    "use strict";
    if(!window.VCT) return;

    /* ------------------------------------------------------------
       TABS
       Siempre aplica data-vct-tabs-active del HTML recién renderizado.
       ------------------------------------------------------------ */
    VCT.Tabs = VCT.Tabs || {};

    VCT.Tabs.activate = function(root,name){
        if(!root || !name) return;

        root.querySelectorAll("[data-vct-tab]").forEach(function(btn){
            btn.classList.toggle(
                "is-active",
                btn.getAttribute("data-vct-tab")===name
            );
        });

        root.querySelectorAll("[data-vct-panel]").forEach(function(panel){
            panel.classList.toggle(
                "is-active",
                panel.getAttribute("data-vct-panel")===name
            );
        });

        root.setAttribute("data-vct-tabs-active",name);
    };

    VCT.Tabs.forceSummaryKey="VCT_V360_FORCE_RESUMEN";
    VCT.Tabs.internalTabKey="VCT_V360_INTERNAL_TAB";

    VCT.Tabs.rememberInternalTab=function(name){
        name=VCT.Util.trim(name);
        if(!name) return;

        try{
            window.sessionStorage.setItem(
                VCT.Tabs.internalTabKey,
                JSON.stringify({ tab:name, ts:Date.now() })
            );
        }catch(e){}
    };

    VCT.Tabs.takeInternalTab=function(){
        try{
            var raw=window.sessionStorage.getItem(VCT.Tabs.internalTabKey);
            if(!raw) return "";

            window.sessionStorage.removeItem(VCT.Tabs.internalTabKey);

            var data=JSON.parse(raw);
            if(!data || !data.tab) return "";

            /* Evita reutilizar accidentalmente una solapa pendiente vieja
               si una navegación fue cancelada. */
            if(data.ts && (Date.now()-Number(data.ts))>15000) return "";

            return VCT.Util.trim(data.tab);
        }catch(e){
            try{ window.sessionStorage.removeItem(VCT.Tabs.internalTabKey); }catch(ignore){}
            return "";
        }
    };

    VCT.Tabs.clearInternalTab=function(){
        try{ window.sessionStorage.removeItem(VCT.Tabs.internalTabKey); }catch(e){}
    };

    VCT.Tabs.shouldForceSummary=function(){
        try{
            return window.sessionStorage.getItem(VCT.Tabs.forceSummaryKey)==="1";
        }catch(e){
            return false;
        }
    };

    VCT.Tabs.consumeForceSummary=function(){
        try{
            window.sessionStorage.removeItem(VCT.Tabs.forceSummaryKey);
        }catch(e){}
    };

    VCT.Tabs.markNextEntrySummary=function(){
        try{
            window.sessionStorage.setItem(VCT.Tabs.forceSummaryKey,"1");
        }catch(e){}
    };

    VCT.Tabs.closeInternalFormsForFreshEntry=function(){
        document.querySelectorAll(
            '[data-vct-component="drawer"],' +
            '[data-vct-component="modal"]'
        ).forEach(function(component){
            if(!component || !component.querySelector) return;

            var hasEntity=!!component.querySelector(
                '[data-vct-field="TEXTO30"],' +
                '[name="SP.TEXTO30"],' +
                '[data-vct-buffer-original-name="SP.TEXTO30"]'
            );
            var hasTab=!!component.querySelector(
                '[data-vct-field="ACTIVE_TAB"],' +
                '[name="SP.ACTIVE_TAB"],' +
                '[data-vct-buffer-original-name="SP.ACTIVE_TAB"]'
            );

            if(!hasEntity || !hasTab) return;

            component.classList.remove("is-open");
            component.removeAttribute("data-vct-auto-open");
            component.removeAttribute("data-vct-auto-opened");
            if(component.dataset) delete component.dataset.vctAutoOpened;
        });

        document.body.classList.remove("vct-drawer-open","vct-modal-open");

        if(VCT.FormSelect && typeof VCT.FormSelect.closeAll==="function")
            VCT.FormSelect.closeAll();

        if(VCT.RowMenu && typeof VCT.RowMenu.close==="function")
            VCT.RowMenu.close();
    };

    VCT.Tabs.init = function(root){
        if(!root) return;

        var first=root.querySelector("[data-vct-tab]");
        var reset=root.getAttribute("data-vct-tabs-reset")==="1";
        var forceSummary=VCT.Tabs.shouldForceSummary();

        /* REGLA DE ENTRADA V360:
           data-vct-tabs-reset=1 significa navegación nueva desde Clientes.
           Esa condición tiene prioridad absoluta sobre cualquier tab interno
           guardado por una operación anterior. De esta forma TODA V360 nueva
           comienza en Resumen y ningún drawer previo puede reaparecer. */
        if(reset || forceSummary){
            VCT.Tabs.clearInternalTab();

            if(VCT.FormState &&
               typeof VCT.FormState.suppressAutoOpen==="function")
                VCT.FormState.suppressAutoOpen(2500);

            VCT.Tabs.closeInternalFormsForFreshEntry();
        }

        var internalTab=(reset || forceSummary) ? "" : VCT.Tabs.takeInternalTab();
        var active=(reset || forceSummary)
            ? "resumen"
            : (internalTab ||
               root.getAttribute("data-vct-tabs-active") ||
               (first ? first.getAttribute("data-vct-tab") : ""));

        if(active) VCT.Tabs.activate(root,active);

        if(reset) root.setAttribute("data-vct-tabs-reset","0");
        if(forceSummary) VCT.Tabs.consumeForceSummary();

        if(root.dataset.vctTabsReady==="1") return;
        root.dataset.vctTabsReady="1";

        root.addEventListener("click",function(event){
            var tab=event.target.closest("[data-vct-tab]");
            if(tab){
                event.preventDefault();
                VCT.Tabs.activate(root,tab.getAttribute("data-vct-tab"));
                return;
            }

            var link=event.target.closest("[data-vct-tab-link]");
            if(link){
                event.preventDefault();
                VCT.Tabs.activate(root,link.getAttribute("data-vct-tab-link"));
            }
        });
    };

    VCT.Tabs.initAll = function(scope){
        scope=scope||document;

        /* OUTPARAM1 y OUTPARAM2 pueden insertarse en momentos distintos.
           Si aparece un panel dentro de una Vista 360 ya creada, se vuelve
           a sincronizar el contenedor padre con la solapa activa. */
        if(scope.closest){
            var owner=scope.closest("[data-vct-tabs]");
            if(owner) VCT.Tabs.init(owner);
        }

        if(scope.matches && scope.matches("[data-vct-tabs]"))
            VCT.Tabs.init(scope);

        if(scope.querySelectorAll)
            scope.querySelectorAll("[data-vct-tabs]").forEach(function(root){
                VCT.Tabs.init(root);
            });
    };

    /* Regreso V360 -> listado de la entidad.
       Se limpia el payload transitorio del buffer y se deja Resumen como
       próxima solapa inicial antes de navegar al listado. */
    document.addEventListener("click",function(event){
        var back=event.target.closest("[data-vct-v360-back]");
        if(!back) return;

        event.preventDefault();
        event.stopImmediatePropagation();

        if(back.disabled) return false;
        back.disabled=true;

        VCT.Tabs.clearInternalTab();
        VCT.Tabs.markNextEntrySummary();

        var goBack=function(){
            var backGuid=VCT.Util.trim(back.getAttribute("data-vct-guid"));
            if(backGuid){
                return VCT.Navigation.goto(back,backGuid);
            }

            /* Fallback genérico para módulos que ya existen en el sidebar.
               Permite reutilizar el breadcrumb en Empleados, Consultores,
               Proveedores, etc. sin hardcodear GUIDs en cada V360. */
            var sidebarMod=VCT.Util.trim(back.getAttribute("data-vct-sidebar-mod"));
            if(sidebarMod){
                var sidebar=document.getElementById("muhleSideBar");
                if(sidebar){
                    var links=sidebar.querySelectorAll(".vct-sidebar-link[data-vct-mod], .vct-sidebar-action[data-vct-mod]");
                    for(var i=0;i<links.length;i++){
                        if(String(links[i].getAttribute("data-vct-mod")||"")===sidebarMod){
                            back.disabled=false;
                            links[i].click();
                            return false;
                        }
                    }
                }

                back.disabled=false;
                console.error("[VCT] No se encontró el módulo de sidebar destino:",sidebarMod);
                return false;
            }

            back.disabled=false;
            console.error("[VCT] Breadcrumb V360 sin GUID ni módulo de sidebar destino.");
            return false;
        };

        /* La limpieza debe finalizar ANTES del goto. De lo contrario el
           framework puede reutilizar valores TEXTOxx/FLAGxx del cliente
           anterior y reabrir un drawer con valores concatenados. */
        if(VCT.DomForm &&
           typeof VCT.DomForm.resetAllForNavigation==="function"){
            VCT.DomForm.resetAllForNavigation(function(ok){
                if(!ok){
                    back.disabled=false;
                    VCT.Toast.show(
                        "No se pudo limpiar completamente el formulario antes de volver al listado.",
                        "error"
                    );
                    return;
                }

                goBack();
            });
            return false;
        }

        /* Fallback para una carga parcial del JS. */
        VCT.Buffer.storeQueued("ACTIVE_TAB","resumen",null,function(okTab){
            if(!okTab){
                back.disabled=false;
                return;
            }

            VCT.Buffer.storeQueued("IDSELEC01","",null,function(okClient){
                if(!okClient){
                    back.disabled=false;
                    return;
                }

                goBack();
            });
        });

        return false;
    },true);

    /* ------------------------------------------------------------
       MENÚ CONTEXTUAL
       ------------------------------------------------------------ */
    VCT.RowMenu = VCT.RowMenu || {};
    VCT.RowMenu.portal=null;
    VCT.RowMenu.trigger=null;

    VCT.RowMenu.close=function(){
        if(VCT.RowMenu.portal){
            VCT.RowMenu.portal.remove();
            VCT.RowMenu.portal=null;
        }

        if(VCT.RowMenu.trigger){
            VCT.RowMenu.trigger.classList.remove("is-open");
            VCT.RowMenu.trigger=null;
        }
    };

    VCT.RowMenu.info=function(btn){
        var row=btn ? btn.closest("[data-vct-row]") : null;

        return {
            row:row,
            id:row ? (row.getAttribute("data-vct-id") || "") : "",
            entity:btn ? (btn.getAttribute("data-vct-entity") || "") : "",
            tab:btn ? (btn.getAttribute("data-vct-tab") || "resumen") : "resumen",
            principal:row ? (row.getAttribute("data-vct-principal") || "0") : "0",
            actions:btn ? VCT.Util.trim(btn.getAttribute("data-vct-actions") || "") : ""
        };
    };

    VCT.RowMenu.place=function(menu,btn){
        if(!menu || !btn) return;

        var r=btn.getBoundingClientRect();
        var gap=8;
        var margin=10;

        /* Medimos el menú real. La cantidad de opciones cambia según
           la entidad, por lo que no usamos una altura estimada fija. */
        var menuRect=menu.getBoundingClientRect();
        var width=menuRect.width || 210;
        var height=menuRect.height || 0;

        var viewportW=window.innerWidth || document.documentElement.clientWidth;
        var viewportH=window.innerHeight || document.documentElement.clientHeight;

        var rightLeft=r.right+gap;
        var leftLeft=r.left-width-gap;
        var fitsRight=(rightLeft+width)<=viewportW-margin;
        var fitsLeft=leftLeft>=margin;
        var left;

        /* Posición horizontal determinística:
           - derecha del botón si entra completa;
           - izquierda si el botón está contra el borde derecho;
           - si ninguna entra completa, se ajusta al viewport. */
        if(fitsRight){
            left=rightLeft;
        }else if(fitsLeft){
            left=leftLeft;
        }else{
            left=Math.max(
                margin,
                Math.min(rightLeft,viewportW-width-margin)
            );
        }

        /* Posición vertical estable: el menú queda alineado con el botón.
           Sólo se desplaza lo mínimo indispensable para no salir de pantalla.
           De esta forma no salta arbitrariamente arriba/abajo entre filas. */
        var maxTop=Math.max(margin,viewportH-height-margin);
        var top=Math.max(margin,Math.min(r.top,maxTop));

        menu.classList.toggle("opens-left",left<r.left);
        menu.style.left=Math.round(left)+"px";
        menu.style.top=Math.round(top)+"px";
    };

    VCT.RowMenu.storeCommand=function(btn,flag){
        var info=VCT.RowMenu.info(btn);
        if(!info.id || !info.entity) return false;

        var targetId=btn.getAttribute("data-vct-target");
        var target=targetId ? document.getElementById(targetId) : null;

        if(VCT.Tabs && typeof VCT.Tabs.rememberInternalTab==="function")
            VCT.Tabs.rememberInternalTab(info.tab);

        /* Mismo contrato que un formulario normal. El comando se escribe
           secuencialmente y next() se ejecuta sólo al finalizar el commit. */
        if(target && VCT.DomForm &&
           typeof VCT.DomForm.setFieldValue==="function" &&
           typeof VCT.DomForm.syncToBuffer==="function"){

            if(typeof VCT.DomForm.activateScope==="function")
                VCT.DomForm.activateScope(target);

            VCT.DomForm.setFieldValue(target,"IDSELEC02",info.id);
            VCT.DomForm.setFieldValue(target,"TEXTO30",info.entity);
            VCT.DomForm.setFieldValue(target,"ACTIVE_TAB",info.tab);
            VCT.DomForm.setFieldValue(target,"FLAG01","0");
            VCT.DomForm.setFieldValue(target,"FLAG03",flag==="delete" ? "1" : "0");
            VCT.DomForm.setFieldValue(target,"FLAG04",flag==="principal" ? "1" : "0");

            VCT.DomForm.syncToBuffer(target,function(ok){
                if(!ok) return;
                window.setTimeout(function(){
                    VCT.Navigation.next(btn);
                },40);
            });

            return false;
        }

        /* Fallback para pantallas antiguas: también secuencial para no
           disparar varias escrituras simultáneas al buffer. */
        var items=[
            ["IDSELEC02",info.id],
            ["TEXTO30",info.entity],
            ["FLAG01","0"],
            ["FLAG03",flag==="delete" ? "1" : "0"],
            ["FLAG04",flag==="principal" ? "1" : "0"],
            ["ACTIVE_TAB",info.tab]
        ];

        /* El flag que dispara la operación va último. */
        var commitName=flag==="delete" ? "FLAG03" : "FLAG04";
        items.sort(function(a,b){
            if(a[0]===commitName) return 1;
            if(b[0]===commitName) return -1;
            return 0;
        });

        var i=0;
        var nextStore=function(){
            if(i>=items.length){
                window.setTimeout(function(){ VCT.Navigation.next(btn); },40);
                return;
            }

            var item=items[i++];
            VCT.Buffer.storeQueued(item[0],item[1],null,function(ok){
                if(!ok){
                    VCT.Toast.show("No se pudo ejecutar la acción. Intente nuevamente.","error");
                    return;
                }
                nextStore();
            });
        };

        nextStore();
        return false;
    };

    VCT.RowMenu.openMaps=function(btn){
        var info=VCT.RowMenu.info(btn);

        if(!info.row || info.entity!=="DOMICILIO") return false;

        var parts=[
            info.row.getAttribute("data-vct-calle"),
            info.row.getAttribute("data-vct-nro"),
            info.row.getAttribute("data-vct-localidad"),
            info.row.getAttribute("data-vct-provincia"),
            "Argentina"
        ].filter(function(value){
            return value && String(value).trim()!=="";
        });

        if(!parts.length) return false;

        window.open(
            "https://www.google.com/maps/search/?api=1&query="+
            encodeURIComponent(parts.join(", ")),
            "_blank",
            "noopener"
        );

        return false;
    };

    VCT.RowMenu.open=function(btn){
        VCT.RowMenu.close();

        var info=VCT.RowMenu.info(btn);
        if(!info.row) return false;

        VCT.RowMenu.trigger=btn;
        btn.classList.add("is-open");

        var declaredActions=info.actions
            ? info.actions.split(",").map(function(value){
                return VCT.Util.trim(value).toLowerCase();
              }).filter(Boolean)
            : null;

        var allows=function(action){
            return !declaredActions || declaredActions.indexOf(action)>=0;
        };

        var editHtml=allows("edit")
            ? '<button type="button" data-vct-menu-action="edit">' +
                '<span class="vct-row-context-icon" data-vct-icon="edit"></span>' +
                '<span>Editar</span>' +
              '</button>'
            : "";

        var principalHtml="";
        if(allows("principal")){
            if(info.principal==="1"){
                principalHtml=
                    '<button type="button" class="is-disabled" disabled>' +
                        '<span class="vct-row-context-icon" data-vct-icon="check"></span>' +
                        '<span>Principal actual</span>' +
                    '</button>';
            }else{
                principalHtml=
                    '<button type="button" data-vct-menu-action="principal">' +
                        '<span class="vct-row-context-icon" data-vct-icon="star"></span>' +
                        '<span>Marcar como principal</span>' +
                    '</button>';
            }
        }

        var mapsHtml="";
        if(info.entity==="DOMICILIO" && (!declaredActions || allows("maps"))){
            mapsHtml=
                '<button type="button" data-vct-menu-action="maps">' +
                    '<span class="vct-row-context-icon" data-vct-icon="map-pin"></span>' +
                    '<span>Ver ubicación</span>' +
                '</button>';
        }

        /* project-create es EXCLUSIVO del menú que lo declara explícitamente.
           Nunca debe filtrarse a Domicilios, Teléfonos, Emails o Contactos. */
        var projectCreateHtml=(declaredActions && allows("project-create"))
            ? '<button type="button" data-vct-menu-action="project-create">' +
                '<span class="vct-row-context-icon" data-vct-icon="plus"></span>' +
                '<span>Nuevo Proyecto</span>' +
              '</button>'
            : "";

        var deleteHtml=allows("delete")
            ? '<button type="button" class="is-danger" data-vct-menu-action="delete">' +
                '<span class="vct-row-context-icon" data-vct-icon="trash"></span>' +
                '<span>Eliminar</span>' +
              '</button>'
            : "";

        var separatorHtml=(deleteHtml && (editHtml || principalHtml || mapsHtml || projectCreateHtml))
            ? '<div class="vct-row-context-separator"></div>'
            : "";

        var portal=document.createElement("div");
        portal.className="vct-row-context-menu";
        portal.innerHTML=
            editHtml +
            principalHtml +
            mapsHtml +
            projectCreateHtml +
            separatorHtml +
            deleteHtml;

        document.body.appendChild(portal);

        VCT.RowMenu.portal=portal;

        if(VCT.Icon && typeof VCT.Icon.init==="function")
            VCT.Icon.init(portal);

        VCT.RowMenu.place(portal,btn);

        portal.addEventListener("click",function(event){
            var action=event.target.closest("[data-vct-menu-action]");
            if(!action) return;

            event.preventDefault();
            event.stopPropagation();

            var type=action.getAttribute("data-vct-menu-action");
            var source=VCT.RowMenu.trigger;

            if(type==="edit"){
                VCT.RowMenu.close();

                if(VCT.DomForm &&
                   typeof VCT.DomForm.openTarget==="function")
                    return VCT.DomForm.openTarget(source,false);

                return false;
            }

            if(type==="principal"){
                VCT.RowMenu.close();
                return VCT.RowMenu.storeCommand(source,"principal");
            }

            if(type==="maps"){
                VCT.RowMenu.close();
                return VCT.RowMenu.openMaps(source);
            }

            if(type==="project-create"){
                VCT.RowMenu.close();
                if(VCT.Toast && typeof VCT.Toast.show==="function")
                    VCT.Toast.show("El alta de proyectos se habilitara al implementar el ABM de Proyectos.","info");
                return false;
            }

            if(type==="delete"){
                if(!window.confirm("¿Eliminar este registro?"))
                    return false;

                VCT.RowMenu.close();
                return VCT.RowMenu.storeCommand(source,"delete");
            }
        });

        return false;
    };

    document.addEventListener("click",function(event){
        var btn=event.target.closest("[data-vct-command='row-context-menu']");

        if(btn){
            event.preventDefault();
            event.stopImmediatePropagation();

            if(VCT.RowMenu.trigger===btn){
                VCT.RowMenu.close();
                return false;
            }

            return VCT.RowMenu.open(btn);
        }

        if(!event.target.closest(".vct-row-context-menu"))
            VCT.RowMenu.close();
    },true);

    window.addEventListener("resize",VCT.RowMenu.close);
    window.addEventListener("scroll",VCT.RowMenu.close,true);

    /* ------------------------------------------------------------
       INIT
       ------------------------------------------------------------ */
    function init(scope){
        VCT.Tabs.initAll(scope||document);

        if(VCT.Icon && typeof VCT.Icon.init==="function")
            VCT.Icon.init(scope||document);
    }

    if(document.readyState==="loading"){
        document.addEventListener("DOMContentLoaded",function(){
            init(document);
        });
    }else{
        setTimeout(function(){init(document);},0);
    }

    new MutationObserver(function(mutations){
        mutations.forEach(function(mutation){
            mutation.addedNodes.forEach(function(node){
                if(node.nodeType===1)
                    init(node);
            });
        });
    }).observe(document.documentElement,{
        childList:true,
        subtree:true
    });

})();


/* =========================================================================
   VCT MAIN V18 - LIMPIEZA V360 / DRAWERS
   - El breadcrumb limpia explícitamente todos los slots usados por los forms.
   - Tras una limpieza exitosa elimina drawers V360 antiguos del DOM.
   ========================================================================= */

/* =========================================================================
   VCT MAIN - SYNC GENERICO DE FORMS RENDERIZADOS AL GUARDAR
   -------------------------------------------------------------------------
   Los formularios generados por VCT_MAIN_RENDER_FORM pueden contener
   checkboxes/toggles. Cuando un checkbox queda desmarcado, el navegador no
   siempre lo incluye en la serializacion tradicional del form y VCT_BUFFER
   puede conservar el valor anterior (por ejemplo FLAG02=1).

   Para forms VCT declarativos ([data-vct-field]) reutilizamos el mismo puente
   DomForm -> VCT_BUFFER que ya utilizan los drawers de Vista 360. De esta
   manera un checkbox desmarcado viaja explicitamente como "0" antes de next().

   Formularios antiguos que no usan data-vct-field conservan Command.save
   original sin cambios.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT || !window.VCT.Command || !window.VCT.DomForm) return;
    if (window.VCT.Command.__vctRenderedFormSaveSync) return;

    var VCT = window.VCT;
    var originalSave = VCT.Command.save;

    VCT.Command.save = function (element) {
        var scope =
            element.closest('[data-vct-component="modal"]') ||
            element.closest('[data-vct-component="drawer"]') ||
            element.closest('[data-vct-form-scope]') ||
            VCT.Util.findPage(element) ||
            document;

        /* Sólo intervenimos formularios declarativos del renderer genérico.
           El resto mantiene exactamente el comportamiento histórico. */
        if (!scope || !scope.querySelector || !scope.querySelector('[data-vct-field]') ||
            !VCT.DomForm || typeof VCT.DomForm.syncToBuffer !== "function") {
            return originalSave.call(VCT.Command, element);
        }

        if (!VCT.Validation.validate(scope)) return false;

        if (element.disabled) return false;
        element.disabled = true;

        VCT.DomForm.syncToBuffer(scope, function (ok) {
            if (!ok) {
                element.disabled = false;
                return;
            }

            /* ACTION no se modifica: el SP del módulo reconoce el guardado
               mediante su FLAGxx, igual que VCT_MAIN_CLIENTES. */
            window.setTimeout(function () {
                VCT.Navigation.next(element);
            }, 40);
        });

        return false;
    };

    VCT.Command.__vctRenderedFormSaveSync = true;

})(window, document);

/* =========================================================================
   VCT MAIN - CONFIGURACION V1
   -------------------------------------------------------------------------
   Scope exclusivo: [data-vct-config-root]
   - Selector principal Parametria / Emails.
   - Subtabs Servicios / Normas.
   - Eliminacion directa con el mismo puente DomForm -> VCT_BUFFER.
   No modifica VCT.Tabs ni la logica de V360.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT) return;

    var VCT = window.VCT;
    VCT.Config = VCT.Config || {};

    VCT.Config.allowedTabs = ["servicios", "normas", "email-templates"];

    VCT.Config.normalizeTab = function (value) {
        value = VCT.Util.trim(value).toLowerCase();
        return VCT.Config.allowedTabs.indexOf(value) >= 0 ? value : "servicios";
    };

    VCT.Config.activate = function (root, tab) {
        if (!root) return false;

        tab = VCT.Config.normalizeTab(tab);
        root.setAttribute("data-vct-config-active", tab);

        if (tab === "servicios" || tab === "normas")
            root.setAttribute("data-vct-config-last-param", tab);

        root.querySelectorAll("[data-vct-config-section]").forEach(function (button) {
            var section = VCT.Util.trim(button.getAttribute("data-vct-config-section")).toLowerCase();
            var active = section === "emails"
                ? tab === "email-templates"
                : (tab === "servicios" || tab === "normas");

            button.classList.toggle("is-active", active);
            button.setAttribute("aria-selected", active ? "true" : "false");
        });

        root.querySelectorAll("[data-vct-config-tab]").forEach(function (button) {
            var active = button.getAttribute("data-vct-config-tab") === tab;
            button.classList.toggle("is-active", active);
            button.setAttribute("aria-selected", active ? "true" : "false");
        });

        root.querySelectorAll("[data-vct-config-panel]").forEach(function (panel) {
            panel.classList.toggle(
                "is-active",
                panel.getAttribute("data-vct-config-panel") === tab
            );
        });

        return false;
    };

    VCT.Config.initOne = function (root) {
        if (!root || root.dataset.vctConfigReady === "1") return;
        root.dataset.vctConfigReady = "1";

        var initial = VCT.Config.normalizeTab(
            root.getAttribute("data-vct-config-active") || "servicios"
        );

        if (initial === "servicios" || initial === "normas")
            root.setAttribute("data-vct-config-last-param", initial);

        VCT.Config.activate(root, initial);

        root.addEventListener("click", function (event) {
            var section = event.target.closest("[data-vct-config-section]");
            if (section && root.contains(section)) {
                event.preventDefault();

                var name = VCT.Util.trim(
                    section.getAttribute("data-vct-config-section")
                ).toLowerCase();

                if (name === "emails") {
                    VCT.Config.activate(root, "email-templates");
                } else {
                    VCT.Config.activate(
                        root,
                        VCT.Config.normalizeTab(
                            root.getAttribute("data-vct-config-last-param") || "servicios"
                        )
                    );
                }
                return;
            }

            var tab = event.target.closest("[data-vct-config-tab]");
            if (tab && root.contains(tab)) {
                event.preventDefault();
                VCT.Config.activate(root, tab.getAttribute("data-vct-config-tab"));
            }
        });
    };

    VCT.Config.init = function (scope) {
        scope = scope || document;

        if (scope.matches && scope.matches("[data-vct-config-root]"))
            VCT.Config.initOne(scope);

        if (!scope.querySelectorAll) return;

        scope.querySelectorAll("[data-vct-config-root]").forEach(function (root) {
            VCT.Config.initOne(root);
        });
    };

    VCT.Config.deleteRow = function (button) {
        if (!button || button.disabled) return false;

        var row = button.closest("[data-vct-row]");
        var id = row ? VCT.Util.trim(row.getAttribute("data-vct-id")) : "";
        var entity = VCT.Util.trim(button.getAttribute("data-vct-entity"));
        var tab = VCT.Config.normalizeTab(button.getAttribute("data-vct-tab"));
        var targetId = VCT.Util.trim(button.getAttribute("data-vct-target"));
        var target = targetId ? document.getElementById(targetId) : null;

        if (!id || !entity || !target) {
            console.error("[VCT] Config.deleteRow: faltan datos de la operación.");
            return false;
        }

        if (!window.confirm("¿Eliminar este registro?")) return false;

        if (!VCT.DomForm ||
            typeof VCT.DomForm.activateScope !== "function" ||
            typeof VCT.DomForm.setFieldValue !== "function" ||
            typeof VCT.DomForm.syncToBuffer !== "function") {
            console.error("[VCT] Config.deleteRow: DomForm no está disponible.");
            return false;
        }

        button.disabled = true;
        VCT.DomForm.activateScope(target);

        VCT.DomForm.setFieldValue(target, "IDSELEC01", id);
        VCT.DomForm.setFieldValue(target, "TEXTO30", entity);
        VCT.DomForm.setFieldValue(target, "ACTIVE_TAB", tab);
        VCT.DomForm.setFieldValue(target, "FLAG01", "0");
        VCT.DomForm.setFieldValue(target, "FLAG03", "1");

        if (VCT.DomForm.findField(target, "FLAG02"))
            VCT.DomForm.setFieldValue(target, "FLAG02", "0");

        VCT.DomForm.syncToBuffer(target, function (ok) {
            if (!ok) {
                button.disabled = false;
                return;
            }

            window.setTimeout(function () {
                VCT.Navigation.next(button);
            }, 40);
        });

        return false;
    };

    document.addEventListener("click", function (event) {
        var button = event.target.closest("[data-vct-config-delete]");
        if (!button) return;

        event.preventDefault();
        event.stopImmediatePropagation();
        VCT.Config.deleteRow(button);
    }, true);

    function init(scope) {
        VCT.Config.init(scope || document);
        if (VCT.Icon && typeof VCT.Icon.init === "function")
            VCT.Icon.init(scope || document);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", function () {
            init(document);
        });
    } else {
        window.setTimeout(function () { init(document); }, 0);
    }

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                Array.prototype.forEach.call(mutation.addedNodes || [], function (node) {
                    if (node && node.nodeType === 1)
                        init(node);
                });
            });
        }).observe(document.documentElement, {
            childList:true,
            subtree:true
        });
    }

})(window, document);

/* =========================================================================
   VCT MAIN - CONFIGURACION V2 / SERVICIOS ID EN EDICION
   -------------------------------------------------------------------------
   Sólo para vctConfigServicioModal:
   - Alta: TEXTO01 continúa siendo CODIGO editable (la tabla lo requiere).
   - Edición: TEXTO01 muestra el ID del registro y queda disabled.
   - El SP ignora TEXTO01 durante UPDATE y conserva CODIGO sin cambios.
   No modifica DomForm para ninguna otra entidad.
   ========================================================================= */
(function (window, document) {
    "use strict";

    if (!window.VCT || !window.VCT.DomForm) return;

    var VCT = window.VCT;
    if (VCT.DomForm.__vctConfigServicioIdMode) return;

    var SERVICE_FORM_ID = "vctConfigServicioModal";
    var originalOpenTarget = VCT.DomForm.openTarget;

    function applyServiceIdMode(target, editMode) {
        if (!target || target.id !== SERVICE_FORM_ID) return;

        var codeField = VCT.DomForm.findField(target, "TEXTO01");
        var idField = VCT.DomForm.findField(target, "IDSELEC01");
        if (!codeField) return;

        if (editMode) {
            var idValue = idField ? VCT.Util.trim(VCT.DomForm.getFieldValue(idField)) : "";
            if (idValue) {
                codeField.value = idValue;
                codeField.dispatchEvent(new Event("change", { bubbles:true }));
            }

            codeField.disabled = true;
            codeField.setAttribute("aria-disabled", "true");
            codeField.setAttribute("title", "El código mostrado corresponde al ID y no es editable.");
        } else {
            codeField.disabled = false;
            codeField.removeAttribute("aria-disabled");
            codeField.removeAttribute("title");
        }

        VCT.DomForm.syncVisualField(codeField);
    }

    VCT.DomForm.openTarget = function (element, clearMode) {
        var result = originalOpenTarget.call(VCT.DomForm, element, clearMode);
        var targetId = element ? element.getAttribute("data-vct-target") : "";

        if (targetId === SERVICE_FORM_ID) {
            var target = document.getElementById(SERVICE_FORM_ID);
            applyServiceIdMode(target, !clearMode);
        }

        return result;
    };

    function syncRenderedServiceForm(scope) {
        scope = scope || document;
        var target = null;

        if (scope.id === SERVICE_FORM_ID)
            target = scope;
        else if (scope.querySelector)
            target = scope.querySelector("#" + SERVICE_FORM_ID);

        if (!target) return;

        var idField = VCT.DomForm.findField(target, "IDSELEC01");
        var idValue = idField ? VCT.Util.trim(VCT.DomForm.getFieldValue(idField)) : "";

        /* Reapertura del servidor después de una validación de edición. */
        applyServiceIdMode(target, !!idValue);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", function () {
            syncRenderedServiceForm(document);
        });
    } else {
        window.setTimeout(function () { syncRenderedServiceForm(document); }, 0);
    }

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                Array.prototype.forEach.call(mutation.addedNodes || [], function (node) {
                    if (node && node.nodeType === 1)
                        syncRenderedServiceForm(node);
                });
            });
        }).observe(document.documentElement, {
            childList:true,
            subtree:true
        });
    }

    VCT.DomForm.__vctConfigServicioIdMode = true;

})(window, document);

/* =========================================================================
   VCT MAIN V19 - SIMPLE MENU / ACCION PROYECTO PENDIENTE
   -------------------------------------------------------------------------
   El menu de tres puntos de Vista 360 usa <details> nativo.
   - Cierra al hacer click fuera o con Escape.
   - La opcion de nuevo proyecto queda explicitamente preparada pero NO
     navega a un alta inexistente: hoy muestra feedback hasta que exista el
     ABM real de Proyectos.
   ========================================================================= */
(function(window, document){
    "use strict";

    function closeMenus(except){
        document.querySelectorAll('details[data-vct-simple-menu][open]').forEach(function(menu){
            if(except && menu === except) return;
            menu.removeAttribute('open');
        });
    }

    document.addEventListener('click', function(event){
        var pending = event.target.closest('[data-vct-pending-action="project-create"]');
        if(pending){
            event.preventDefault();
            event.stopPropagation();
            closeMenus();
            if(window.VCT && VCT.Toast && typeof VCT.Toast.show === 'function'){
                VCT.Toast.show('El alta de proyectos se habilitara al implementar el ABM de Proyectos.', 'info');
            }
            return;
        }

        var menu = event.target.closest('details[data-vct-simple-menu]');
        if(!menu) closeMenus();
    });

    document.addEventListener('keydown', function(event){
        if(event.key === 'Escape') closeMenus();
    });

})(window, document);



/* =========================================================================
   VCT MAIN V20 - CLIENTE 360 / NORMALIZACION VISUAL
   -------------------------------------------------------------------------
   - Badge mapping ampliado y reutilizable en cualquier modulo.
   - RowMenu soporta la accion generica project-create, usando el mismo
     portal/menu contextual que Domicilios, Telefonos, Emails y Contactos.
   ========================================================================= */
/* =========================================================================
   VCT SIDEBAR RIEL - ACTIVE DEL SIDEBAR NUEVO
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