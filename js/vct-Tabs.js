(function (window, document) {
    "use strict";

    var VctTabs = {

        init: function () {
            var modules = document.querySelectorAll("[data-vct-tabs]");
            modules.forEach(function (module) {
                VctTabs.initModule(module);
            });
            VctTabs.mountGrids();
        },

        initModule: function (module) {
            if (module.dataset.vctInitialized === "true") return;
            module.dataset.vctInitialized = "true";

            VctTabs.decorateTabs(module);

            var activePanel = module.querySelector("[data-vct-panel].is-active");
            if (activePanel) {
                var tabName = activePanel.dataset.vctPanel;
                var tabBtn = module.querySelector('[data-vct-tab="' + tabName + '"]');
                if (tabBtn) {
                    tabBtn.hidden = false;
                    tabBtn.removeAttribute("hidden");
                }
                VctTabs.activate(module, tabName);
            } else {
                var activeTab = module.querySelector("[data-vct-tab].is-active");
                if (activeTab) {
                    VctTabs.activate(module, activeTab.dataset.vctTab);
                }
            }
        },

        decorateTabs: function (module) {
            if (!module) return;
            var tabs = module.querySelectorAll("[data-vct-tab]");

            tabs.forEach(function (tab) {
                if (tab.dataset.vctDecorated === "true") return;
                tab.dataset.vctDecorated = "true";

                var surface = document.createElement("span");
                surface.className = "vct-tab-surface";
                surface.setAttribute("aria-hidden", "true");

                var content = document.createElement("span");
                content.className = "vct-tab-content";

                while (tab.firstChild) {
                    content.appendChild(tab.firstChild);
                }

                tab.appendChild(surface);
                tab.appendChild(content);
            });
        },

        activate: function (module, tabName) {
            if (!module || !tabName) return;

            var tabs = module.querySelectorAll("[data-vct-tab]");
            var panels = module.querySelectorAll("[data-vct-panel]");

            tabs.forEach(function (tab) {
                var isActive = tab.dataset.vctTab === tabName;
                tab.classList.toggle("is-active", isActive);
                if (isActive) {
                    tab.hidden = false;
                    tab.removeAttribute("hidden");
                }
            });

            panels.forEach(function (panel) {
                var isActive = panel.dataset.vctPanel === tabName;
                panel.classList.toggle("is-active", isActive);
                panel.hidden = !isActive;
            });

            module.dataset.vctActiveTab = tabName;

            module.dispatchEvent(
                new CustomEvent("vct:tabchange", { detail: { tab: tabName } })
            );
        },

        open: function (module, tabName, options) {
            options = options || {};
            VctTabs.decorateTabs(module);

            var tab = module.querySelector('[data-vct-tab="' + tabName + '"]');
            var panel = module.querySelector('[data-vct-panel="' + tabName + '"]');

            if (!tab || !panel) return;

            tab.hidden = false;
            tab.removeAttribute("hidden");
            panel.hidden = false;

            if (options.mode === "new") {
                VctTabs.prepareNew(module, panel);
            }

            if (options.mode === "edit") {
                VctTabs.prepareEdit(module, panel, options.values || {});
            }

            VctTabs.activate(module, tabName);
        },

        close: function (module, tabName) {
            var tab = module.querySelector('[data-vct-tab="' + tabName + '"]');
            var panel = module.querySelector('[data-vct-panel="' + tabName + '"]');

            if (tab && tab.hasAttribute("data-vct-dynamic-tab")) {
                tab.hidden = true;
            }

            if (panel) {
                panel.hidden = true;
                panel.classList.remove("is-active");
            }

            var defaultTab = module.querySelector("[data-vct-tab]:not([data-vct-dynamic-tab])");
            if (defaultTab) {
                VctTabs.activate(module, defaultTab.dataset.vctTab);
            }
        },

        prepareNew: function (module, panel) {
            var storageKey = module ? module.dataset.vctEditStorageKey : null;

            if (storageKey && typeof window.almacenarSeleccion === "function") {
                try { window.almacenarSeleccion(storageKey, ""); } catch (e) {}
            }

            if (storageKey && panel) {
                var hiddenKeys = panel.querySelectorAll(
                    'input[name="SP.' + storageKey + '"], ' +
                    'input[name="CALL.' + storageKey + '"], ' +
                    '#' + storageKey + ', ' +
                    '[data-vct-selected-key]'
                );
                hiddenKeys.forEach(function (h) {
                    h.value = "";
                });
            }

            VctTabs.resetFields(panel);

            var modeField = panel ? panel.querySelector("[data-vct-form-mode]") : null;
            if (modeField) { modeField.value = "NEW"; }

            var primaryInput = panel ? panel.querySelector("[data-vct-primary-input]") : null;
            if (primaryInput) {
                primaryInput.disabled = false;
                primaryInput.readOnly = false;
                primaryInput.removeAttribute("readonly");
                primaryInput.removeAttribute("aria-readonly");
                primaryInput.value = "";
                primaryInput.style.backgroundColor = "";
                primaryInput.style.cursor = "";
            }

            var modeNewConfig = module && module.dataset.vctModeNew ? parseModeJson(module.dataset.vctModeNew) : {};

            VctTabs.setTabTitle(module, "form", modeNewConfig.tabTitle || module.dataset.vctNewTabTitle || "Nuevo");
            VctTabs.setText(panel, "[data-vct-form-title]", modeNewConfig.title || panel.dataset.vctNewFormTitle || "Nuevo");
            VctTabs.setText(panel, "[data-vct-form-subtitle]", modeNewConfig.subtitle || panel.dataset.vctNewFormSubtitle || "Complete los datos solicitados.");
            VctTabs.setText(panel, "[data-vct-submit-label], .vct-button-text", modeNewConfig.submit || panel.dataset.vctNewSubmitLabel || "Guardar");

            if (typeof window.vctRefreshFormEngine === "function") {
                window.vctRefreshFormEngine();
            }
        },

        prepareEdit: function (module, panel, values) {
            values = values || {};

            var primaryField = module ? module.dataset.vctPrimaryField : null;
            var storageKey   = module ? module.dataset.vctEditStorageKey : null;

            var pkVal = "";
            if (primaryField && values[primaryField] !== undefined) {
                pkVal = String(values[primaryField]).trim();
            } else if (storageKey && values[storageKey] !== undefined) {
                pkVal = String(values[storageKey]).trim();
            }

            if (storageKey && pkVal !== "") {
                if (typeof window.almacenarSeleccion === "function") {
                    try { window.almacenarSeleccion(storageKey, pkVal); } catch (e) {}
                }

                if (panel) {
                    var inputsToUpdate = panel.querySelectorAll(
                        'input[name="SP.' + storageKey + '"], ' +
                        'input[name="CALL.' + storageKey + '"], ' +
                        '#' + storageKey + ', ' +
                        '[data-vct-selected-key]'
                    );
                    inputsToUpdate.forEach(function (input) {
                        input.value = pkVal;
                    });
                }
            }

            VctTabs.resetFields(panel);
            VctTabs.fillFields(panel, values);

            var modeField = panel ? panel.querySelector("[data-vct-form-mode]") : null;
            if (modeField) { modeField.value = "EDIT"; }

            var primaryInput = panel ? panel.querySelector("[data-vct-primary-input]") : null;
            if (primaryInput) {
                if (pkVal !== "") primaryInput.value = pkVal;
                primaryInput.readOnly = true;
                primaryInput.setAttribute("aria-readonly", "true");
                primaryInput.disabled = false;
                primaryInput.style.backgroundColor = "#f8fafc";
                primaryInput.style.cursor = "not-allowed";
            }

            var modeEditConfig = module && module.dataset.vctModeEdit ? parseModeJson(module.dataset.vctModeEdit) : {};

            VctTabs.setTabTitle(module, "form", modeEditConfig.tabTitle || module.dataset.vctEditTabTitle || "Editar");
            VctTabs.setText(panel, "[data-vct-form-title]", modeEditConfig.title || panel.dataset.vctEditFormTitle || "Editar");
            VctTabs.setText(panel, "[data-vct-form-subtitle]", modeEditConfig.subtitle || panel.dataset.vctEditFormSubtitle || "Modifique los datos seleccionados.");
            VctTabs.setText(panel, "[data-vct-submit-label], .vct-button-text", modeEditConfig.submit || panel.dataset.vctEditSubmitLabel || "Guardar cambios");

            if (typeof window.vctRefreshFormEngine === "function") {
                window.vctRefreshFormEngine();
            }
        },

        resetFields: function (panel) {
            if (!panel) return;

            var fields = panel.querySelectorAll("input, select, textarea");
            fields.forEach(function (field) {
                if (field.type === "checkbox" || field.type === "radio") {
                    field.checked = false;
                    return;
                }

                if (field.tagName === "SELECT") {
                    field.selectedIndex = 0;
                    field.value = "";

                    for (var i = 0; i < field.options.length; i++) {
                        field.options[i].selected = (i === 0);
                        field.options[i].removeAttribute("selected");
                    }

                    field.dispatchEvent(new Event("change", { bubbles: true }));
                    return;
                }

                if (field.type !== "hidden") {
                    field.value = "";
                    field.defaultValue = "";
                }
            });
        },

        fillFields: function (panel, values) {
            if (!panel || !values) return;

            var norm = function (str) {
                if (str === null || str === undefined) return "";
                return String(str)
                    .toLowerCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "")
                    .replace(/[^a-z0-9]/g, "")
                    .trim();
            };

            Object.keys(values).forEach(function (key) {
                var fields = panel.querySelectorAll('[data-vct-field="' + key + '"], [data-vct-field-alt="' + key + '"]');

                fields.forEach(function (field) {
                    var rawVal = (values[key] === null || values[key] === undefined) ? "" : String(values[key]).trim();

                    if (field.type === "checkbox" || field.type === "radio") {
                        field.checked = Boolean(rawVal);
                    } else if (field.tagName === "SELECT") {
                        var cleanVal = norm(rawVal);

                        // Mapeo automático de etiquetas de Estado
                        if (cleanVal === "activa" || cleanVal === "1" || cleanVal === "true") {
                            cleanVal = "1";
                        } else if (cleanVal === "noactiva" || cleanVal === "0" || cleanVal === "false") {
                            cleanVal = "0";
                        }

                        var matchedIndex = -1;

                        // Búsqueda por valor o texto visible
                        for (var i = 0; i < field.options.length; i++) {
                            var opt = field.options[i];
                            var optText = norm(opt.text);
                            var optVal  = norm(opt.value);

                            if (cleanVal !== "" && (optVal === cleanVal || optText === cleanVal)) {
                                matchedIndex = i;
                                break;
                            }
                        }

                        // Búsqueda por coincidencia parcial si no hubo match directo
                        if (matchedIndex === -1 && cleanVal !== "") {
                            for (var j = 0; j < field.options.length; j++) {
                                var optAlt = field.options[j];
                                var optAltText = norm(optAlt.text);
                                var optAltVal  = norm(optAlt.value);

                                if (optAltVal !== "" && (optAltVal.indexOf(cleanVal) !== -1 || cleanVal.indexOf(optAltVal) !== -1 || optAltText.indexOf(cleanVal) !== -1 || cleanVal.indexOf(optAltText) !== -1)) {
                                    matchedIndex = j;
                                    break;
                                }
                            }
                        }

                        if (matchedIndex !== -1) {
                            field.selectedIndex = matchedIndex;
                            field.value = field.options[matchedIndex].value;
                            field.options[matchedIndex].selected = true;
                            field.options[matchedIndex].setAttribute("selected", "selected");
                        }

                        // Notificar al componente custom para refrescar la interfaz de usuario
                        field.dispatchEvent(new Event("change", { bubbles: true }));
                    } else {
                        field.value = rawVal;
                    }
                });
            });
        },

        mountGrids: function () {
            var modules = document.querySelectorAll("[data-vct-tabs]");

            modules.forEach(function (module) {
                var host = module.querySelector("[data-vct-grid-host]");
                if (!host) return;

                if (host.children.length > 0 && host.querySelector("[data-vct-grid-mounted]")) return;

                var rawSelector = module.dataset.vctGridSelector;
                var selectors = [
                    rawSelector,
                    "[data-vct-grid-source]",
                    ".vct-grid-source",
                    ".vct-table-wrapper",
                    "[data-vct-table]"
                ].filter(Boolean);

                var grid = null;

                for (var s = 0; s < selectors.length; s++) {
                    var candidates = document.querySelectorAll(selectors[s]);
                    for (var i = 0; i < candidates.length; i++) {
                        var cand = candidates[i];
                        if (!host.contains(cand)) {
                            grid = cand.closest("[data-vct-grid-source]") ||
                                   cand.closest(".vct-grid-source") ||
                                   cand.closest(".vct-table-wrapper") ||
                                   cand;
                            break;
                        }
                    }
                    if (grid) break;
                }

                if (!grid) return;

                grid.setAttribute("data-vct-grid-mounted", "true");
                host.innerHTML = "";
                host.appendChild(grid);

                grid.style.width = "100%";
                grid.style.margin = "0";
                grid.style.boxShadow = "none";

                module.dispatchEvent(
                    new CustomEvent("vct:gridmounted", { detail: { grid: grid, host: host } })
                );
            });
        },

        setTabTitle: function (module, tabName, text) {
            if (!module || !tabName || !text) return;
            var tab = module.querySelector('[data-vct-tab="' + tabName + '"]');
            if (!tab) return;
            var titleElem = tab.querySelector('[data-vct-tab-title]') || tab.querySelector('.vct-tab-content span') || tab.querySelector('.vct-tab-content');
            if (titleElem) {
                titleElem.textContent = text;
            } else {
                tab.textContent = text;
            }
        },

        setText: function (container, selector, text) {
            if (!container || !text) return;
            var element = container.querySelector(selector);
            if (element) { element.textContent = text; }
        },

        edit: function (element, tabName, values) {
            var module = element.closest("[data-vct-tabs]");
            if (!module) return;

            values = values || {};
            var primaryField = module ? module.dataset.vctPrimaryField : null;
            var storageKey   = module ? module.dataset.vctEditStorageKey : null;

            var pkValue = "";
            if (primaryField && values[primaryField] !== undefined) {
                pkValue = String(values[primaryField]).trim();
            } else if (storageKey && values[storageKey] !== undefined) {
                pkValue = String(values[storageKey]).trim();
            }

            if (storageKey && pkValue !== "") {
                if (typeof window.almacenarSeleccion === "function") {
                    try { window.almacenarSeleccion(storageKey, pkValue); } catch(e){}
                }
            }

            VctTabs.open(module, tabName, { mode: "edit", values: values });
        }
    };

    function parseModeJson(str) {
        if (!str) return {};
        try { return JSON.parse(str); } catch (e) { return {}; }
    }

    document.addEventListener("click", function (event) {
        var tabButton = event.target.closest("[data-vct-tab]");

        if (tabButton && !event.target.closest("[data-vct-close-tab]")) {
            var tabModule = tabButton.closest("[data-vct-tabs]");
            VctTabs.activate(tabModule, tabButton.dataset.vctTab);
            return;
        }

        var openButton = event.target.closest("[data-vct-open-tab]");

        if (openButton) {
            var openModule = openButton.closest("[data-vct-tabs]");
            var isNew = openButton.hasAttribute("data-vct-new-record") || openButton.dataset.vctMode === "new";

            VctTabs.open(openModule, openButton.dataset.vctOpenTab, {
                mode: isNew ? "new" : (openButton.dataset.vctMode || "")
            });
            return;
        }

        var closeButton = event.target.closest("[data-vct-close-tab]");

        if (closeButton) {
            event.preventDefault();
            event.stopPropagation();

            var closeModule = closeButton.closest("[data-vct-tabs]");
            VctTabs.close(closeModule, closeButton.dataset.vctCloseTab);
            return;
        }
    });

    function startVctTabs() {
        VctTabs.init();
        VctTabs.mountGrids();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", startVctTabs);
    } else {
        startVctTabs();
    }

    window.VctTabs = VctTabs;

})(window, document);