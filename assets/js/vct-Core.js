(function (window, document) {
    "use strict";

    /**
     * vct-Table.js
     * Framework VCT 5.4.2 - Motor NATIVO VOCATURO (Visual Clean & Alignment Edition)
     * + Ordenamiento por columna (click en header)
     */

    var ICONS = {
        edit: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>',
        search: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>',
        excel: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>',
        pdf: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>',
        doc: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>',
        sort: '<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#cbd5e0" stroke-width="2" style="margin-left:4px;vertical-align:middle;"><path d="M7 15l5 5 5-5M7 9l5-5 5 5"/></svg>',
        sortActive: '<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#66062D" stroke-width="2.5" style="margin-left:4px;vertical-align:middle;{{ROTATE}}"><path d="M7 10l5 5 5-5"/></svg>'
    };

    /* ==========================================================
       Tema VCT compartido para los combos TomSelect que cada SP
       instancia por su cuenta ("Seleccione un usuario/menú", etc.).
       El selector de "por página" es un <select> nativo: no depende
       de TomSelect ni de ninguna carga de CDN.
       ========================================================== */
    function injectTomSelectSharedStyle() {
        if (document.getElementById("vct-tomselect-shared-style")) return;

        var style = document.createElement("style");
        style.id = "vct-tomselect-shared-style";
        style.textContent =
            '.ts-wrapper.vct-ts-select .ts-control::after{content:none!important;display:none!important;}' +
            '.ts-wrapper.vct-ts-select .ts-control{height:38px!important;min-height:38px!important;padding:0 32px 0 12px!important;font-size:13px!important;font-weight:600!important;color:#0f172a!important;background-color:#fff!important;background-image:url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2366062D%22 stroke-width=%222.5%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22m6 9 6 6 6-6%22/%3E%3C/svg%3E")!important;background-repeat:no-repeat!important;background-position:right 10px center!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 1px 2px rgba(0,0,0,.04)!important;display:flex!important;align-items:center!important;cursor:pointer!important;}' +
            '.ts-wrapper.vct-ts-select.focus .ts-control{border-color:#66062D!important;box-shadow:0 0 0 3px rgba(102,6,45,.12)!important;}' +
            '.ts-wrapper.vct-ts-select .ts-control>input{font-size:13px!important;font-weight:600!important;color:#0f172a!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown{margin-top:4px!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;box-shadow:0 12px 24px rgba(15,23,42,.14)!important;overflow:hidden!important;z-index:9999!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .ts-dropdown-content{padding:4px!important;max-height:220px!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option{padding:10px 12px!important;font-size:13px!important;font-weight:500!important;line-height:1.2!important;color:#0f172a!important;background:#fff!important;border-radius:6px!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option{transition:background .15s ease,color .15s ease!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.active,.ts-wrapper.vct-ts-select .ts-dropdown .option:hover{background:#66062D!important;color:#fff!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.selected{background:transparent!important;color:#66062D!important;font-weight:700!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option.selected.active,.ts-wrapper.vct-ts-select .ts-dropdown .option.selected:hover{background:#66062D!important;color:#fff!important;}' +
            /* La opción vacía ("Seleccione un usuario/menú...") nunca debe
               pintarse bordó sólido como una fila real: en hover/activo va
               en gris clarito, manteniendo el texto bordó. */
            '.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""]{font-weight:600!important;color:#66062D!important;}' +
            '.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""].active,.ts-wrapper.vct-ts-select .ts-dropdown .option[data-value=""]:hover{background:#f8fafc!important;color:#66062D!important;}' +
            /* Hover para los botones de paginación (antes no tenían ninguno). */
            '.vct-prev:hover,.vct-next:hover,.vct-page-num:not(.is-active):hover{border-color:#66062D!important;color:#66062D!important;background:#fdf2f6!important;}' +
            '.vct-page-num.is-active:hover{background:#4a0420!important;border-color:#4a0420!important;}';
        document.head.appendChild(style);
    }

    function parseJson(raw, fallback) {
        if (!raw) return fallback;
        try {
            return JSON.parse(raw);
        } catch (e) {
            console.error("VctTable: JSON inválido.", e);
            return fallback;
        }
    }

    function escapeHtml(value) {
        return String(value === null || value === undefined ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function isFalseFlag(v) {
        return v === false || v === 0 || v === "0" || String(v).toLowerCase() === "false";
    }

    /* Convierte una celda con HTML (ej. la píldora de Permisos) a texto plano
       legible para exportar a Excel/PDF/Word, en vez de mostrar las etiquetas
       crudas. Saca botones/íconos (son solo UI de pantalla) y, si encuentra
       filas de datos reales (.vct-perm-row u otro "li"/ítem), las une con
       coma; si no, cae al texto visible restante. */
    function htmlCellToText(value) {
        var raw = String(value === null || value === undefined ? "" : value);
        if (raw.indexOf("<") === -1) return raw;

        var container = document.createElement("div");
        container.innerHTML = raw;

        container.querySelectorAll('[role="button"], svg, button').forEach(function (el) {
            if (el.parentNode) el.parentNode.removeChild(el);
        });

        var parts = [];
        container.querySelectorAll('.vct-perm-row, li, [data-export-item]').forEach(function (el) {
            var t = el.textContent.replace(/\s+/g, " ").trim();
            if (t) parts.push(t);
        });

        if (parts.length) return parts.join(", ");

        return container.textContent.replace(/\s+/g, " ").trim();
    }

    /* Comparador genérico: numérico > fecha DD/MM/AAAA[ HH:mm[:ss]] > texto (es-AR, natural) */
    function compareValues(va, vb) {
        var sa = String(va === null || va === undefined ? "" : va).trim();
        var sb = String(vb === null || vb === undefined ? "" : vb).trim();

        if (sa === "" && sb === "") return 0;
        if (sa === "") return -1;
        if (sb === "") return 1;

        var numRe = /^-?\d+([.,]\d+)?$/;
        if (numRe.test(sa) && numRe.test(sb)) {
            return parseFloat(sa.replace(",", ".")) - parseFloat(sb.replace(",", "."));
        }

        var dateRe = /^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$/;
        var ma = sa.match(dateRe), mb = sb.match(dateRe);
        if (ma && mb) {
            var da = new Date(+ma[3], +ma[2] - 1, +ma[1], +(ma[4] || 0), +(ma[5] || 0), +(ma[6] || 0));
            var db = new Date(+mb[3], +mb[2] - 1, +mb[1], +(mb[4] || 0), +(mb[5] || 0), +(mb[6] || 0));
            return da - db;
        }

        var isoRe = /^\d{4}-\d{2}-\d{2}([ T]\d{2}:\d{2}(:\d{2})?)?$/;
        if (isoRe.test(sa) && isoRe.test(sb)) {
            return new Date(sa.replace(" ", "T")) - new Date(sb.replace(" ", "T"));
        }

        return sa.localeCompare(sb, "es", { sensitivity: "base", numeric: true });
    }

    function VctNativeTable(source, table) {
        this.source = source;
        this.tableElement = table;
        this.data = parseJson(table.dataset.vctData, []);
        this.columns = parseJson(table.dataset.vctColumns, []);
        this.actions = parseJson(table.dataset.vctActions, []);
        this.pageSize = parseInt(table.dataset.vctPageSize || "10", 10) || 10;
        this.currentPage = 1;
        this.searchTerm = "";
        this.sortColumn = null;
        this.sortDirection = 1;
        this.filteredData = this.data.slice();
        this.visibleColumns = this.columns.filter(function (c) { return !isFalseFlag(c.visible) && !c.vctHidden; });
        this.exportColumns = this.columns.filter(function (c) {
            return !isFalseFlag(c.visible) && !isFalseFlag(c.exportable);
        });

        this.build();
        this.render();
        this.bind();
    }

    VctNativeTable.prototype.build = function () {
        this.source.innerHTML = [
            '<div class="vct-table-wrapper" style="width:100%;margin:0;padding:10px 10px 0 10px;box-sizing:border-box;">',
            '  <div class="vct-table-toolbar" style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;gap:10px;flex-wrap:wrap;width:100%;box-sizing:border-box;">',
            '    <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;flex:1 1 auto;min-width:0;">',
            '      <select class="vct-page-size-select" style="padding:0 30px 0 12px;border:1px solid #cbd5e1;border-radius:8px;background-color:#fff;background-image:url(&quot;data:image/svg+xml,%3Csvg xmlns=&#39;http://www.w3.org/2000/svg&#39; width=&#39;16&#39; height=&#39;16&#39; viewBox=&#39;0 0 24 24&#39; fill=&#39;none&#39; stroke=&#39;%2366062D&#39; stroke-width=&#39;2.5&#39; stroke-linecap=&#39;round&#39; stroke-linejoin=&#39;round&#39;%3E%3Cpath d=&#39;m6 9 6 6 6-6&#39;/%3E%3C/svg%3E&quot;);background-repeat:no-repeat;background-position:right 10px center;font-size:12px;font-weight:600;color:#333233;outline:none;cursor:pointer;height:36px;box-shadow:0 1px 2px rgba(0,0,0,0.02);appearance:none;-webkit-appearance:none;-moz-appearance:none;width:auto;min-width:130px;flex:0 0 auto;">',
            '        <option value="10">10 por pág.</option>',
            '        <option value="25">25 por pág.</option>',
            '        <option value="50">50 por pág.</option>',
            '        <option value="100">100 por pág.</option>',
            '      </select>',
            '      <span role="button" class="vct-export-btn" data-type="excel" style="display:inline-flex;align-items:center;gap:6px;padding:0 14px;height:36px;background:#fff;border:1px solid #cbd5e1;border-radius:8px;font-size:12px;font-weight:600;color:#333233;cursor:pointer;transition:all 0.15s ease;box-shadow:0 1px 2px rgba(0,0,0,0.02);">' + ICONS.excel + ' Excel</span>',
            '      <span role="button" class="vct-export-btn" data-type="pdf" style="display:inline-flex;align-items:center;gap:6px;padding:0 14px;height:36px;background:#fff;border:1px solid #cbd5e1;border-radius:8px;font-size:12px;font-weight:600;color:#333233;cursor:pointer;transition:all 0.15s ease;box-shadow:0 1px 2px rgba(0,0,0,0.02);">' + ICONS.pdf + ' PDF</span>',
            '      <span role="button" class="vct-export-btn" data-type="doc" style="display:inline-flex;align-items:center;gap:6px;padding:0 14px;height:36px;background:#fff;border:1px solid #cbd5e1;border-radius:8px;font-size:12px;font-weight:600;color:#333233;cursor:pointer;transition:all 0.15s ease;box-shadow:0 1px 2px rgba(0,0,0,0.02);">' + ICONS.doc + ' Word</span>',
            '    </div>',
            '    <div class="vct-search-box" style="position:relative;width:240px;max-width:100%;box-sizing:border-box;">',
            '      <input type="text" class="vct-input-search" placeholder="' + escapeHtml(this.tableElement.dataset.vctSearchPlaceholder || "Buscar...") + '" style="width:100%;height:36px;box-sizing:border-box;padding:0 12px 0 38px !important;border:1px solid #cbd5e1;border-radius:8px;background:#fff;font-size:12.5px;color:#333233;outline:none;transition:border-color 0.15s;box-shadow:0 1px 2px rgba(0,0,0,0.02);" />',
            '      <div style="position:absolute;left:12px;top:50%;transform:translateY(-50%);pointer-events:none;line-height:0;display:flex;align-items:center;justify-content:center;">' + ICONS.search + '</div>',
            '    </div>',
            '  </div>',
            '  <div style="overflow-x:auto;border-radius:8px;border:1px solid #edf2f7;background:#fff;width:100%;box-sizing:border-box;">',
            '    <table class="vct-table-main" style="width:100%;border-collapse:collapse;font-size:12px;margin:0!important;">',
            '      <thead></thead>',
            '      <tbody></tbody>',
            '    </table>',
            '  </div>',
            '  <div style="display:flex;justify-content:space-between;align-items:center;margin-top:15px;margin-bottom:8px;font-size:12px;color:#64748b;gap:10px;flex-wrap:wrap;">',
            '    <div class="vct-info-text" style="font-weight:500;"></div>',
            '    <div class="vct-pagination-controls" style="display:flex;gap:4px;align-items:center;flex-wrap:wrap;"></div>',
            '  </div>',
            '</div>'
        ].join("");

        this.thead = this.source.querySelector("thead");
        this.tbody = this.source.querySelector("tbody");
        this.searchInput = this.source.querySelector(".vct-input-search");
        this.pageSizeSelect = this.source.querySelector(".vct-page-size-select");
        this.infoText = this.source.querySelector(".vct-info-text");
        this.pagination = this.source.querySelector(".vct-pagination-controls");

        if (this.pageSizeSelect) {
            this.pageSizeSelect.value = String(this.pageSize);
        }
    };

    VctNativeTable.prototype.render = function () {
        this.renderTable();
        this.renderPagination();
    };

    VctNativeTable.prototype.applySort = function () {
        if (!this.sortColumn) return;
        var col = this.sortColumn, dir = this.sortDirection;
        this.filteredData.sort(function (a, b) {
            return compareValues(a[col], b[col]) * dir;
        });
    };

    VctNativeTable.prototype.bindSortHeaders = function () {
        var self = this;
        if (!this.thead) return;

        this.thead.querySelectorAll("th[data-col]").forEach(function (th) {
            th.addEventListener("click", function () {
                var col = th.dataset.col;

                if (self.sortColumn === col) {
                    self.sortDirection = self.sortDirection === 1 ? -1 : 1;
                } else {
                    self.sortColumn = col;
                    self.sortDirection = 1;
                }

                self.applySort();
                self.currentPage = 1;
                self.render();
            });
        });
    };

    VctNativeTable.prototype.renderTable = function () {
        var self = this;
        var hasActions = this.actions.length > 0;

        var head = '<tr style="border-bottom:1px solid #edf2f7;background:#f8fafc;color:#64748b;font-size:11px;letter-spacing:.5px;">';

        if (hasActions) {
            head += '<th style="padding:12px 10px;text-align:center;width:65px;font-weight:700;">Acciones</th>';
        }

        this.visibleColumns.forEach(function (col) {
            var orderable = !isFalseFlag(col.orderable);
            var isActive = orderable && self.sortColumn === col.data;
            var icon = isActive
                ? ICONS.sortActive.replace("{{ROTATE}}", self.sortDirection === 1 ? "" : "transform:rotate(180deg);")
                : (orderable ? ICONS.sort : "");

            head += '<th'
                + (orderable ? ' data-col="' + escapeHtml(col.data) + '" style="padding:12px 10px;text-align:left;font-weight:700;white-space:nowrap;cursor:pointer;user-select:none;"' : ' style="padding:12px 10px;text-align:left;font-weight:700;white-space:nowrap;"')
                + '>' + escapeHtml(col.title || col.data) + icon + '</th>';
        });

        head += '</tr>';
        this.thead.innerHTML = head;
        this.bindSortHeaders();

        var start = (this.currentPage - 1) * this.pageSize;
        var end = start + this.pageSize;
        var pageData = this.filteredData.slice(start, end);

        if (!pageData.length) {
            var colspan = this.visibleColumns.length + (hasActions ? 1 : 0);
            this.tbody.innerHTML = '<tr><td colspan="' + colspan + '" style="text-align:center;padding:25px;color:#94a3b8;font-weight:500;">No se encontraron registros</td></tr>';
            return;
        }

        var body = "";

        pageData.forEach(function (row, rowIndex) {
            body += '<tr style="border-bottom:1px solid #f1f5f9;transition:background 0.1s ease;">';

            if (hasActions) {
                body += '<td style="padding:10px;text-align:center;white-space:nowrap;">';

                self.actions.forEach(function (action, actionIndex) {
                    var type = String(action.type || "edit").toLowerCase();
                    var icon = type === "edit" ? ICONS.edit : ICONS.edit;

                    body += '<span role="button" class="vct-action-btn"'
                        + ' data-rindex="' + rowIndex + '"'
                        + ' data-aindex="' + actionIndex + '"'
                        + ' title="' + escapeHtml(action.title || "") + '"'
                        + ' style="display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:50%;background:#f1f5f9;color:#333233;cursor:pointer;margin:0 2px;transition:all 0.15s ease;">'
                        + icon
                        + '</span>';
                });

                body += '</td>';
            }

            self.visibleColumns.forEach(function (col) {
                var value = row[col.data];
                if (value === null || value === undefined) value = "";
                body += '<td style="padding:10px;color:#333233;">' + escapeHtml(value) + '</td>';
            });

            body += '</tr>';
        });

        this.tbody.innerHTML = body;
        this.bindRowActions(pageData);
    };

    VctNativeTable.prototype.bindRowActions = function (pageData) {
        var self = this;

        this.tbody.querySelectorAll(".vct-action-btn").forEach(function (button) {
            button.addEventListener("click", function (event) {
                event.preventDefault();
                event.stopPropagation();

                var rowIndex = parseInt(button.dataset.rindex || "-1", 10);
                var actionIndex = parseInt(button.dataset.aindex || "-1", 10);
                var row = pageData[rowIndex] || null;
                var action = self.actions[actionIndex] || {};

                if (!row) return;

                var type = String(action.type || "edit").toLowerCase();

                if (type === "edit") {
                    if (window.VctTabs && typeof window.VctTabs.edit === "function") {
                        var module = button.closest("[data-vct-tabs]");
                        var tabName = action.targetTab || action.tabName || action.tab || (module && module.dataset.vctEditTab) || "form";

                        window.VctTabs.edit(button, tabName, row);
                    }
                    return;
                }

                self.source.dispatchEvent(new CustomEvent("vct:tableaction", {
                    bubbles: true,
                    detail: { type: type, row: row, action: action, source: button }
                }));
            });
        });
    };

    VctNativeTable.prototype.applySearch = function () {
        var term = String(this.searchTerm || "").toLowerCase().trim();
        var searchable = this.columns.filter(function (c) { return !isFalseFlag(c.searchable); });

        if (!term) {
            this.filteredData = this.data.slice();
        } else {
            this.filteredData = this.data.filter(function (row) {
                return searchable.some(function (col) {
                    var value = row[col.data];
                    return String(value === null || value === undefined ? "" : value).toLowerCase().indexOf(term) !== -1;
                });
            });
        }

        this.applySort();
        this.currentPage = 1;
        this.render();
    };

    /* PAGINACIÓN LIMPIA Y COMPLETA CON PUNTOS SUSPENSIVOS */
    VctNativeTable.prototype.renderPagination = function () {
        var total = this.filteredData.length;
        var pages = Math.max(1, Math.ceil(total / this.pageSize));

        if (this.currentPage > pages) this.currentPage = pages;

        var start = total === 0 ? 0 : ((this.currentPage - 1) * this.pageSize) + 1;
        var end = Math.min(this.currentPage * this.pageSize, total);

        this.infoText.textContent = "Mostrando " + start + " a " + end + " de " + total + " registros";

        var html = "";
        var prevDisabled = this.currentPage <= 1;
        var nextDisabled = this.currentPage >= pages;

        // Botón Anterior
        html += '<span role="button" class="vct-prev" style="display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:6px;border:1px solid #cbd5e1;background:#fff;color:#475569;font-weight:600;cursor:' + (prevDisabled ? 'default' : 'pointer') + ';opacity:' + (prevDisabled ? '.35' : '1') + ';">&laquo;</span>';

        // Lógica de Páginas Consecutivas (...)
        var range = [];
        var delta = 1;

        for (var i = 1; i <= pages; i++) {
            if (i === 1 || i === pages || (i >= this.currentPage - delta && i <= this.currentPage + delta)) {
                range.push(i);
            }
        }

        // Rellena huecos de un solo número (ej. [1,3] -> [1,2,3]) ANTES de renderizar,
        // para no mutar el array mientras se itera sobre él (eso duplicaba páginas).
        var filledRange = [];
        for (var r = 0; r < range.length; r++) {
            if (r > 0 && range[r] - range[r - 1] === 2) {
                filledRange.push(range[r - 1] + 1);
            }
            filledRange.push(range[r]);
        }
        range = filledRange;

        var last = 0;
        for (var idx = 0; idx < range.length; idx++) {
            var pageNum = range[idx];
            if (last && pageNum - last > 1) {
                html += '<span style="display:inline-flex;align-items:center;justify-content:center;width:24px;height:30px;color:#94a3b8;font-size:12px;">...</span>';
            }

            var isActive = pageNum === this.currentPage;
            html += '<span role="button" class="vct-page-num' + (isActive ? ' is-active' : '') + '" data-page="' + pageNum + '" style="display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:6px;border:1px solid ' + (isActive ? '#66062D' : '#cbd5e1') + ';background:' + (isActive ? '#66062D' : '#fff') + ';color:' + (isActive ? '#fff' : '#475569') + ';font-weight:' + (isActive ? '700' : '500') + ';cursor:pointer;transition:all 0.15s ease;">' + pageNum + '</span>';

            last = pageNum;
        }

        // Botón Siguiente
        html += '<span role="button" class="vct-next" style="display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:6px;border:1px solid #cbd5e1;background:#fff;color:#475569;font-weight:600;cursor:' + (nextDisabled ? 'default' : 'pointer') + ';opacity:' + (nextDisabled ? '.35' : '1') + ';">&raquo;</span>';

        this.pagination.innerHTML = html;

        var self = this;

        this.pagination.querySelectorAll(".vct-page-num").forEach(function (button) {
            button.addEventListener("click", function () {
                self.currentPage = parseInt(button.dataset.page, 10);
                self.render();
            });
        });

        var prev = this.pagination.querySelector(".vct-prev");
        if (prev && !prevDisabled) {
            prev.addEventListener("click", function () {
                self.currentPage -= 1;
                self.render();
            });
        }

        var next = this.pagination.querySelector(".vct-next");
        if (next && !nextDisabled) {
            next.addEventListener("click", function () {
                self.currentPage += 1;
                self.render();
            });
        }
    };

    VctNativeTable.prototype.bind = function () {
        var self = this;

        if (this.searchInput) {
            this.searchInput.addEventListener("input", function () {
                self.searchTerm = this.value;
                self.applySearch();
            });
        }

        if (this.pageSizeSelect) {
            this.pageSizeSelect.addEventListener("change", function () {
                self.pageSize = parseInt(this.value, 10) || 10;
                self.currentPage = 1;
                self.render();
            });
        }

        // Estilo compartido de TomSelect: lo siguen usando los combos
        // "Seleccione un usuario/menú" que cada SP instancia por su cuenta
        // (no el selector de paginado, que es un <select> nativo otra vez).
        injectTomSelectSharedStyle();

        var excel = this.source.querySelector('[data-type="excel"]');
        if (excel) {
            excel.addEventListener("click", function () { self.exportExcel(); });
        }

        var pdf = this.source.querySelector('[data-type="pdf"]');
        if (pdf) {
            pdf.addEventListener("click", function () { self.exportPDF(); });
        }

        var doc = this.source.querySelector('[data-type="doc"]');
        if (doc) {
            doc.addEventListener("click", function () { self.exportDOC(); });
        }
    };

    /* EXPORTACIÓN A EXCEL */
    VctNativeTable.prototype.exportExcel = function () {
        if (!this.filteredData.length) return;

        var headers = this.exportColumns.map(function (c) { return c.title || c.data; });
        var keys = this.exportColumns.map(function (c) { return c.data; });

        var html = '<html><head><meta charset="utf-8"></head><body><table><thead><tr>';
        headers.forEach(function (h) { html += '<th>' + escapeHtml(h) + '</th>'; });
        html += '</tr></thead><tbody>';

        this.filteredData.forEach(function (row) {
            html += '<tr>';
            keys.forEach(function (key) { html += '<td>' + escapeHtml(htmlCellToText(row[key])) + '</td>'; });
            html += '</tr>';
        });

        html += '</tbody></table></body></html>';

        var blob = new Blob(["﻿" + html], { type: "application/vnd.ms-excel;charset=utf-8;" });
        var url = URL.createObjectURL(blob);
        var link = document.createElement("a");
        link.href = url;
        link.download = "Reporte_" + new Date().toISOString().slice(0, 10) + ".xls";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    /* EXPORTACIÓN A WORD (.DOC) */
    VctNativeTable.prototype.exportDOC = function () {
        if (!this.filteredData.length) return;

        var headers = this.exportColumns.map(function (c) { return c.title || c.data; });
        var keys = this.exportColumns.map(function (c) { return c.data; });

        var html = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40"><head><meta charset="utf-8"><style>table{border-collapse:collapse;width:100%;}th,td{border:1px solid #cbd5e1;padding:8px;font-family:Arial;font-size:11px;}th{background-color:#66062D;color:#ffffff;}</style></head><body><h2>Reporte de Datos</h2><table><thead><tr>';
        headers.forEach(function (h) { html += '<th>' + escapeHtml(h) + '</th>'; });
        html += '</tr></thead><tbody>';

        this.filteredData.forEach(function (row) {
            html += '<tr>';
            keys.forEach(function (key) { html += '<td>' + escapeHtml(htmlCellToText(row[key])) + '</td>'; });
            html += '</tr>';
        });

        html += '</tbody></table></body></html>';

        var blob = new Blob(["﻿" + html], { type: "application/msword;charset=utf-8;" });
        var url = URL.createObjectURL(blob);
        var link = document.createElement("a");
        link.href = url;
        link.download = "Reporte_" + new Date().toISOString().slice(0, 10) + ".doc";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    /* EXPORTACIÓN A PDF */
    VctNativeTable.prototype.exportPDF = function () {
        if (!this.filteredData.length) return;

        var headers = this.exportColumns.map(function (c) { return c.title || c.data; });
        var keys = this.exportColumns.map(function (c) { return c.data; });

        var printWin = window.open("", "_blank");
        var html = '<html><head><title>Reporte PDF</title><style>body{font-family:sans-serif;padding:20px;}table{width:100%;border-collapse:collapse;}th,td{border:1px solid #e2e8f0;padding:8px;font-size:11px;text-align:left;}th{background:#66062D;color:#fff;}</style></head><body><h2>Reporte de Sistema</h2><table><thead><tr>';

        headers.forEach(function (h) { html += '<th>' + escapeHtml(h) + '</th>'; });
        html += '</tr></thead><tbody>';

        this.filteredData.forEach(function (row) {
            html += '<tr>';
            keys.forEach(function (key) { html += '<td>' + escapeHtml(htmlCellToText(row[key])) + '</td>'; });
            html += '</tr>';
        });

        html += '</tbody></table><script>window.onload=function(){window.print();window.close();};</script></body></html>';

        printWin.document.write(html);
        printWin.document.close();
    };

    var VctTable = {
        version: "5.4.2-native",

        init: function (root) {
            var scope = root || document;

            scope.querySelectorAll("[data-vct-table]").forEach(function (table) {
                if (table.dataset.vctTableInitialized === "true") return;

                var source = table.closest("[data-vct-grid-source]") || table.parentElement;
                if (!source) return;

                table.dataset.vctTableInitialized = "true";
                source._vctTable = new VctNativeTable(source, table);
            });
        }
    };

    window.VctTable = VctTable;

    function start() {
        VctTable.init(document);

        if (typeof window.MutationObserver === "function") {
            var pending = false;
            var observer = new MutationObserver(function () {
                if (pending) return;
                pending = true;

                window.setTimeout(function () {
                    pending = false;
                    VctTable.init(document);
                }, 0);
            });

            observer.observe(document.body, { childList: true, subtree: true });
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", start);
    } else {
        start();
    }

})(window, document);
