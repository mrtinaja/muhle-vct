/**
 * Suite Vocaturo - vct-Table.js
 * Versi?n Estable Definitiva: Captura PK Estricta + Inyecci?n Anti-Desfase en Search/Paginado
 */
(function (window, document) {
    "use strict";

    console.log("?? [VCT-ENGINE] vct-Table.js activo (Con protecci?n de estructura en Search/Paginado).");

    var SVG_ICONS = {
    "pen-line": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>',
    "edit": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>',
    "users": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>',
    "boxes": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>',
    "navigation": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 19 21 12 17 5 21 12 2"></polygon></svg>',
    "scan-eye": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7V5a2 2 0 0 1 2-2h2"></path><path d="M17 3h2a2 2 0 0 1 2 2v2"></path><path d="M21 17v2a2 2 0 0 1-2 2h-2"></path><path d="M7 21H5a2 2 0 0 1-2-2v-2"></path><circle cx="12" cy="12" r="3"></circle><path d="M18 12s-2.25-4-6-4-6 4-6 4 2.25 4 6 4 6-4 6-4"></path></svg>',
    "folder-kanban": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5z"></path><path d="M8 10v6"></path><path d="M12 8v8"></path><path d="M16 11v5"></path></svg>',
    "trash-2": '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>',
    "switch": '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#66062D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="8" ry="8"></rect><circle cx="16" cy="12" r="5"></circle></svg>'
};

    function cleanParam(val) {
        if (val === null || val === undefined) return "";
        return String(val).replace(/,/g, "").trim();
    }

    function extractFormId(triggerElem) {
        if (!triggerElem) return "";
        var module = triggerElem.closest("[data-vct-tabs]") ||
                     triggerElem.closest("[data-vct-module]") ||
                     triggerElem.closest("[data-vct-form-id]");

        if (module && module.dataset && module.dataset.vctFormId) {
            return cleanParam(module.dataset.vctFormId.replace(/'/g, ""));
        }

        var parentForm = triggerElem.closest("form");
        if (parentForm && parentForm.id) {
            return cleanParam(parentForm.id);
        }
        return "";
    }

    function extractRowDataObject(tr, theadTr) {
        var rowData = {};
        if (!tr || !theadTr) return rowData;

        var headers = Array.from(theadTr.children);
        var cells = Array.from(tr.children);

        headers.forEach(function (th, idx) {
            var colName = cleanParam(th.textContent);
            if (colName && colName.toUpperCase() !== "ACCIONES" && cells[idx]) {
                var val = cleanParam(cells[idx].textContent);
                rowData[colName] = val;
            }
        });

        var primaryKey = rowData["C?digo"] || rowData["C?DIGO"] || rowData["Codigo"] || rowData.Usuario || rowData.USUARIO || rowData.PKey || "";
        if (primaryKey) {
            rowData.id = primaryKey;
            rowData["C?digo"] = primaryKey;
            rowData.selectedId = primaryKey;
        }

        return rowData;
    }

    window.vctExecuteGoto = function (formId, targetGuid, storageKey, pkVal, event) {
        if (event && event.preventDefault) event.preventDefault();
        if (event && event.stopPropagation) event.stopPropagation();

        console.group("?? [VCT-GOTO] Navegaci?n M¨¹hle");
        console.log("?? FormID:", formId, "| TargetGUID:", targetGuid, "| StorageKey:", storageKey, "| PK/C?digo:", pkVal);

        if (document.activeElement && typeof document.activeElement.blur === "function") {
            document.activeElement.blur();
        }

        if (storageKey !== "") {
            var targets = [storageKey, "SP." + storageKey, "CALL." + storageKey];
            targets.forEach(function (id) {
                var el = document.getElementById(id) || document.getElementsByName(id)[0];
                if (el) el.value = pkVal;
            });
        }

        if (storageKey !== "" && pkVal !== "" && typeof window.almacenarSeleccion === "function") {
            try {
                window.almacenarSeleccion(storageKey, pkVal);
                console.log("? almacenarSeleccion ejecutado exitosamente -> Key:", storageKey, "Value:", pkVal);
            } catch (e) {
                console.error("? Error ejecutando almacenarSeleccion:", e);
            }
        }

        if (targetGuid !== "" && formId !== "") {
            var inputResult = document.getElementById(formId + "_ResultCode");
            if (inputResult) inputResult.value = targetGuid;

            if (typeof window.goto === "function") {
                console.groupEnd();
                setTimeout(function () {
                    try { window.goto(formId, targetGuid); } catch (e) {}
                }, 50);
                return false;
            }
        }

        console.groupEnd();
        return false;
    };

    function processAndInjectOnclick(context) {
        var root = context || document;
        var tables = root.querySelectorAll("table[data-vct-table], table.vct-table, table.vct-table-main");

        tables.forEach(function (table) {
            if (table.classList.contains("datatable")) return;

            var theadTr = table.querySelector("thead tr");
            var tbodyRows = table.querySelectorAll("tbody > tr");
            if (!theadTr || !tbodyRows.length) return;

            var formId = extractFormId(table);

            var rawActions = table.dataset.vctActions || "";
            if (!rawActions) {
                var container = table.closest("[data-vct-grid-source], [data-vct-module]");
                if (container && container.dataset) rawActions = container.dataset.vctActions || "";
            }

            var actionsConfig = [];
            try { actionsConfig = JSON.parse(rawActions); } catch (e) {}

            var hasEditAction = actionsConfig.some(function(a) {
                var ik = String(a.icon || a.type || "").toLowerCase();
                return ik === "edit" || ik === "pen-line" || a.type === "edit";
            });

            // --- PROTECCI?N HEAD: Verificar celda real en el DOM por clase ---
            var existingLeftTh = theadTr.querySelector("th.vct-injected-th");
            if (hasEditAction) {
                if (!existingLeftTh) {
                    var thLeft = document.createElement("th");
                    thLeft.className = "vct-injected-th";
                    thLeft.style.width = "40px";
                    thLeft.style.padding = "12px 8px";
                    thLeft.style.textAlign = "center";
                    theadTr.insertBefore(thLeft, theadTr.firstChild);
                }
            } else if (existingLeftTh) {
                existingLeftTh.remove();
            }

            var thAcciones = null;
            Array.from(theadTr.children).forEach(function (th) {
                if (th.textContent.trim().toUpperCase() === "ACCIONES") thAcciones = th;
            });

            var hasRightActions = actionsConfig.some(function(a) {
                var ik = String(a.icon || a.type || "").toLowerCase();
                return a.isSecondary || ik === "trash-2" || (ik !== "edit" && ik !== "pen-line" && a.type !== "edit");
            });

            if (!hasRightActions && thAcciones) {
                thAcciones.remove();
            } else if (hasRightActions && thAcciones && theadTr.lastElementChild !== thAcciones) {
                thAcciones.style.textAlign = "right";
                thAcciones.style.paddingRight = "15px";
                theadTr.appendChild(thAcciones);
            }

            // --- PROTECCI?N BODY ---
            tbodyRows.forEach(function (tr) {
                if (tr.querySelector("table")) return;

                var cells = Array.from(tr.children);
                if (!cells.length || cells[0].getAttribute("colspan")) return;

                // Inyecci?n de la columna Editar manteniendo alineaci?n flex aislada
                var existingLeftTd = tr.querySelector("td.vct-injected-td");
                if (hasEditAction) {
                    if (!existingLeftTd) {
                        var tdEdit = document.createElement("td");
                        tdEdit.className = "vct-injected-td";
                        tdEdit.style.cssText = "padding:8px !important;text-align:center !important;width:40px !important;min-width:40px !important;";

                        var editBtn = document.createElement("span");
                        editBtn.className = "vct-action-btn";
                        editBtn.setAttribute("role", "button");
                        editBtn.setAttribute("title", "Editar");
                        editBtn.style.cssText = "display:inline-flex !important;align-items:center !important;justify-content:center !important;width:28px !important;height:28px !important;border-radius:6px !important;background:#eff6ff !important;border:1px solid #bfdbfe !important;color:#2563eb !important;cursor:pointer !important;";
                        editBtn.innerHTML = SVG_ICONS["edit"];

                        editBtn.addEventListener("click", function (e) {
                            e.preventDefault();
                            e.stopPropagation();

                            var rowData = extractRowDataObject(tr, theadTr);
                            if (window.VctTabs && typeof window.VctTabs.edit === "function") {
                                window.VctTabs.edit(this, "form", rowData);
                            }
                        });

                        tdEdit.appendChild(editBtn);
                        tr.insertBefore(tdEdit, tr.firstChild);
                    }
                } else if (existingLeftTd) {
                    existingLeftTd.remove();
                }

                // Celdas de acciones derechas
                var actionsTd = null;
                Array.from(tr.children).forEach(function (td) {
                    if (td.querySelector(".vct-action-btn[data-aindex]")) actionsTd = td;
                });

                if (actionsTd) {
                    if (hasEditAction) {
                        var dupEdit = actionsTd.querySelector(".vct-action-btn[data-aindex='0']");
                        if (dupEdit) dupEdit.remove();
                    }

                    if (!actionsTd.querySelector(".vct-action-btn")) {
                        actionsTd.remove();
                    } else if (tr.lastElementChild !== actionsTd) {
                        actionsTd.style.textAlign = "right";
                        actionsTd.style.paddingRight = "15px";
                        tr.appendChild(actionsTd);
                    }
                }

                // Botones con control de re-inyecci?n anti-apilamiento
                var buttons = tr.querySelectorAll(".vct-action-btn[data-aindex]");
                buttons.forEach(function (btn) {
                    var aIdx = parseInt(btn.dataset.aindex, 10);
                    var conf = actionsConfig[aIdx] || {};
                    var iconKey = String(conf.icon || conf.type || btn.dataset.icon || "edit").toLowerCase();

                    if (hasEditAction && aIdx === 0 && (iconKey === "edit" || iconKey === "pen-line" || conf.type === "edit")) {
                        btn.remove();
                        return;
                    }

                    if (btn.dataset.vctInjected === "true") return;
                    btn.dataset.vctInjected = "true";

                    if (SVG_ICONS[iconKey]) btn.innerHTML = SVG_ICONS[iconKey];
                    if (conf.title) btn.setAttribute("title", conf.title);

                    if (iconKey === "trash-2" || conf.variant === "danger") {
                        btn.style.cssText = "display:inline-flex !important;align-items:center !important;justify-content:center !important;width:28px !important;height:28px !important;border-radius:6px !important;background:#fef2f2 !important;border:1px solid #fecaca !important;color:#dc2626 !important;cursor:pointer !important;margin:0 2px !important;";
                        var svgTrash = btn.querySelector("svg");
                        if (svgTrash) svgTrash.setAttribute("stroke", "#dc2626");
                    } else if (iconKey === "pen-line" || iconKey === "edit") {
                        btn.style.cssText = "display:inline-flex !important;align-items:center !important;justify-content:center !important;width:28px !important;height:28px !important;border-radius:6px !important;background:#eff6ff !important;border:1px solid #bfdbfe !important;color:#2563eb !important;cursor:pointer !important;margin:0 2px !important;";
                        var svgEdit = btn.querySelector("svg");
                        if (svgEdit) svgEdit.setAttribute("stroke", "#2563eb");
                    } else {
                        btn.style.cssText = "display:inline-flex !important;align-items:center !important;justify-content:center !important;width:28px !important;height:28px !important;border-radius:6px !important;background:#f8fafc !important;border:1px solid #e2e8f0 !important;cursor:pointer !important;margin:0 2px !important;";
                    }

                    btn.addEventListener("click", function (e) {
                        var pkVal = "";
                        var rowData = extractRowDataObject(tr, theadTr);
                        var keyField = conf.keyField || "C?digo";

                        if (rowData[keyField]) {
                            pkVal = rowData[keyField];
                        } else if (rowData["C?digo"]) {
                            pkVal = rowData["C?digo"];
                        } else if (rowData["Usuario"]) {
                            pkVal = rowData["Usuario"];
                        }

                        if (!pkVal) {
                            var targetColIdx = -1;
                            Array.from(theadTr.children).forEach(function (th, idx) {
                                var thText = cleanParam(th.textContent).toLowerCase();
                                if (thText === "c?digo" || thText === "codigo" || thText === "usuario" || thText === "pkey") {
                                    targetColIdx = idx;
                                }
                            });

                            if (targetColIdx !== -1 && tr.children[targetColIdx]) {
                                pkVal = cleanParam(tr.children[targetColIdx].textContent);
                            }
                        }

                        if (!pkVal) {
                            Array.from(tr.children).forEach(function (td) {
                                var txt = cleanParam(td.textContent);
                                if (txt !== "" && !td.querySelector(".vct-action-btn") && !pkVal) {
                                    pkVal = txt;
                                }
                            });
                        }

                        var storageKey = cleanParam(conf.storageKey || "ID_DELETE");
                        var targetGuid = cleanParam(conf.targetGuid || conf.actionParam);

                        return window.vctExecuteGoto(formId, targetGuid, storageKey, pkVal, e);
                    });
                });
            });
        });
    }

    function startGridObserver() {
        processAndInjectOnclick(document);

        if (typeof window.MutationObserver === "function") {
            var observer = new MutationObserver(function () {
                processAndInjectOnclick(document);
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }

        if (window.jQuery) {
            window.jQuery(document).ajaxComplete(function () {
                processAndInjectOnclick(document);
            });
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", startGridObserver);
    } else {
        startGridObserver();
    }

})(window, document);
