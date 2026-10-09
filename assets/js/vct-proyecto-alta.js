/* vct-proyecto-alta.js - v1
   ============================================================================
   Alta de proyecto desde la Vista 360 de Cliente (VCT_MAIN_CLIENTES_V360).

   El SP arma el modal #vctModalProyecto con VCT_MAIN_RENDER_FORM (mismos
   campos, validacion y guardado que el resto de los formularios). Este
   script solo agrega:
     - Abrir el modal desde la opcion "Nuevo Proyecto" del menu del
       encabezado (antes mostraba un aviso).
     - Servicios como tarjetas seleccionables  -> SP.TEXTO22 (ids por coma)
     - Normas con buscador y chips              -> SP.TEXTO24 (ids por coma)
     - Rentabilidad estimada en un panel aparte -> SP.TEXTO25 (6 valores con |)
                                                   SP.TEXTO26 (comentario)
     - Fecha limite de lanzamiento obligatoria solo si hay analista.
     - Toast de "proyecto creado" despues de grabar.
   El valor siempre viaja en el input original del formulario, asi que
   VCT.DomForm / VCT.Validation / el buffer no cambian.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoAltaLoaded) return;
    window.__vctProyectoAltaLoaded = true;

    var MODAL_ID = "vctModalProyecto";
    var RENT_KEYS = ["montoPres", "montoViat", "fechaPres", "costoMo", "costoViat", "costoVarios"];

    function modal() { return document.getElementById(MODAL_ID); }
    function fieldEl(name) {
        var m = modal();
        return m ? m.querySelector('[data-vct-field="' + name + '"]') : null;
    }
    function esc(s) {
        return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }
    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }
    function csv(value) {
        return String(value || "").split(",").map(function (v) { return v.trim(); }).filter(Boolean);
    }
    function catalog(name) {
        var tpl = document.querySelector('template[data-vct-proy-catalog="' + name + '"]');
        if (!tpl) return [];
        var opts = tpl.content ? tpl.content.querySelectorAll("option") : tpl.querySelectorAll("option");
        return Array.prototype.map.call(opts, function (o) {
            return { id: o.value, text: o.textContent, codigo: (o.getAttribute("data-codigo") || "").toUpperCase() };
        });
    }
    function setValue(input, value) {
        if (!input || input.value === value) return;
        input.value = value;
        input.dispatchEvent(new Event("change", { bubbles: true }));
    }
    function icons(scope) {
        if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(scope);
    }
    function toast(msg, type) {
        if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") VCT.Toast.show(msg, type || "info");
        else window.alert(msg);
    }

    /* ---------- importes es-AR ---------- */
    function parseMoney(text) {
        var t = String(text || "").replace(/[$\s]/g, "");
        if (!t) return null;
        if (t.indexOf(",") >= 0) t = t.replace(/\./g, "").replace(",", ".");
        else if ((t.match(/\./g) || []).length > 1) t = t.replace(/\./g, "");
        var n = Number(t);
        return isNaN(n) ? NaN : Math.round(n * 100) / 100;
    }
    function fmtMoney(n) {
        if (n == null || isNaN(n)) return "";
        return "$ " + n.toLocaleString("es-AR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
    function fmtDate(iso) {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso || "");
        return m ? m[3] + "/" + m[2] + "/" + m[1] : "";
    }

    /* ======================================================================
       SERVICIOS
       ====================================================================== */
    /* solo iconos que existen en VCT.Icon (vct-main.js) */
    var SERV_ICON = { CONSULTORIA: "briefcase", AUDITORIA: "clipboard-check", CAPACITACION: "users" };

    function buildServicios() {
        var input = fieldEl("TEXTO22");
        if (!input || input.dataset.vctProyReady === "1") return;
        input.dataset.vctProyReady = "1";
        input.classList.add("vct-proy-source");

        var box = document.createElement("div");
        box.className = "vct-proy-services";
        box.setAttribute("role", "group");
        box.setAttribute("aria-label", "Servicios");
        box.innerHTML = catalog("servicios").map(function (s) {
            return '<button type="button" class="vct-proy-service" data-id="' + esc(s.id) + '" aria-pressed="false">' +
                '<span class="vct-proy-service-icon" data-vct-icon="' + (SERV_ICON[s.codigo] || "list-checks") + '"></span>' +
                '<span class="vct-proy-service-name">' + esc(s.text) + '</span>' +
                '<span class="vct-proy-service-check" aria-hidden="true">&#10003;</span>' +
                '</button>';
        }).join("") || '<div class="vct-proy-empty">No hay servicios activos en la parametr&iacute;a.</div>';
        input.parentNode.insertBefore(box, input.nextSibling);
        icons(box);

        box.addEventListener("click", function (e) {
            var btn = e.target.closest(".vct-proy-service");
            if (!btn) return;
            var ids = csv(input.value), id = btn.getAttribute("data-id"), i = ids.indexOf(id);
            if (i >= 0) ids.splice(i, 1); else ids.push(id);
            setValue(input, ids.join(","));
        });
        input.addEventListener("change", function () { paintServicios(); });
        paintServicios();
    }

    function paintServicios() {
        var input = fieldEl("TEXTO22");
        if (!input) return;
        var ids = csv(input.value);
        input.parentNode.querySelectorAll(".vct-proy-service").forEach(function (btn) {
            var on = ids.indexOf(btn.getAttribute("data-id")) >= 0;
            btn.classList.toggle("is-selected", on);
            btn.setAttribute("aria-pressed", on ? "true" : "false");
        });
    }

    /* ======================================================================
       NORMAS (buscador + chips)
       ====================================================================== */
    function buildNormas() {
        var input = fieldEl("TEXTO24");
        if (!input || input.dataset.vctProyReady === "1") return;
        input.dataset.vctProyReady = "1";
        input.classList.add("vct-proy-source");

        var all = catalog("normas");
        var byId = {};
        all.forEach(function (n) { byId[n.id] = n; });

        var box = document.createElement("div");
        box.className = "vct-proy-normas";
        box.innerHTML =
            '<div class="vct-proy-chips" aria-live="polite"></div>' +
            '<div class="vct-proy-combo">' +
                '<span class="vct-proy-combo-icon" data-vct-icon="search"></span>' +
                '<input type="text" class="vct-input vct-proy-combo-input" placeholder="Buscar y agregar normas..." autocomplete="off" aria-label="Buscar normas">' +
                '<div class="vct-proy-combo-menu" role="listbox"></div>' +
            '</div>';
        input.parentNode.insertBefore(box, input.nextSibling);
        icons(box);

        var chips = box.querySelector(".vct-proy-chips");
        var search = box.querySelector(".vct-proy-combo-input");
        var menu = box.querySelector(".vct-proy-combo-menu");
        var active = -1;

        function selected() { return csv(input.value); }

        function renderChips() {
            var ids = selected();
            chips.innerHTML = ids.length
                ? ids.map(function (id) {
                    var n = byId[id];
                    return '<span class="vct-proy-chip">' + esc(n ? n.text : "#" + id) +
                        '<button type="button" class="vct-proy-chip-x" data-id="' + esc(id) + '" aria-label="Quitar">&times;</button></span>';
                }).join("")
                : '<span class="vct-proy-chips-empty">Ninguna norma seleccionada</span>';
        }

        function renderMenu() {
            var q = norm(search.value), ids = selected();
            var list = all.filter(function (n) { return !q || norm(n.text).indexOf(q) >= 0; }).slice(0, 80);
            if (active >= list.length) active = list.length - 1;
            menu.innerHTML = list.length
                ? list.map(function (n, i) {
                    var on = ids.indexOf(n.id) >= 0;
                    return '<div class="vct-proy-combo-option' + (on ? " is-selected" : "") + (i === active ? " is-active" : "") +
                        '" role="option" aria-selected="' + on + '" data-id="' + esc(n.id) + '">' +
                        '<span class="vct-proy-combo-check" aria-hidden="true">' + (on ? "&#10003;" : "") + '</span>' + esc(n.text) + '</div>';
                }).join("")
                : '<div class="vct-proy-combo-empty">Sin resultados</div>';
        }

        function open() { box.classList.add("is-open"); renderMenu(); }
        function close() { box.classList.remove("is-open"); active = -1; }
        function toggle(id) {
            var ids = selected(), i = ids.indexOf(id);
            if (i >= 0) ids.splice(i, 1); else ids.push(id);
            setValue(input, ids.join(","));
            if (search.value) { search.value = ""; active = 0; renderMenu(); }
        }

        search.addEventListener("focus", open);
        search.addEventListener("input", function () { active = 0; open(); });
        search.addEventListener("keydown", function (e) {
            var opts = menu.querySelectorAll(".vct-proy-combo-option");
            if (e.key === "ArrowDown") { e.preventDefault(); active = Math.min(active + 1, opts.length - 1); open(); }
            else if (e.key === "ArrowUp") { e.preventDefault(); active = Math.max(active - 1, 0); open(); }
            else if (e.key === "Enter") {
                e.preventDefault();
                if (opts[active]) toggle(opts[active].getAttribute("data-id"));
            }
            else if (e.key === "Escape") { e.stopPropagation(); close(); search.blur(); }
            else if (e.key === "Backspace" && !search.value) {
                var ids = selected();
                if (ids.length) { ids.pop(); setValue(input, ids.join(",")); }
            }
        });
        menu.addEventListener("mousedown", function (e) {
            var opt = e.target.closest(".vct-proy-combo-option");
            if (!opt) return;
            e.preventDefault(); /* no perder el foco del buscador */
            toggle(opt.getAttribute("data-id"));
        });
        chips.addEventListener("click", function (e) {
            var x = e.target.closest(".vct-proy-chip-x");
            if (x) toggle(x.getAttribute("data-id"));
        });
        document.addEventListener("mousedown", function (e) {
            if (!box.contains(e.target)) close();
        });
        input.addEventListener("change", function () {
            renderChips();
            if (box.classList.contains("is-open")) renderMenu();
            if (!input.value) search.value = "";
        });
        renderChips();
    }

    /* ======================================================================
       RENTABILIDAD (panel aparte dentro del modal)
       ====================================================================== */
    function readRent() {
        var input = fieldEl("TEXTO25"), parts = String(input ? input.value : "").split("|"), r = {};
        RENT_KEYS.forEach(function (k, i) {
            var v = (parts[i] || "").trim();
            r[k] = k === "fechaPres" ? v : (v === "" ? null : Number(v));
        });
        var com = fieldEl("TEXTO26");
        r.comentario = com ? com.value : "";
        return r;
    }
    function totals(r) {
        var pres = (r.montoPres || 0) + (r.montoViat || 0);
        var costo = (r.costoMo || 0) + (r.costoViat || 0) + (r.costoVarios || 0);
        var rent = pres - costo;
        return { pres: pres, costo: costo, rent: rent, margen: pres > 0 ? (rent * 100) / pres : null };
    }
    function hasRent(r) {
        return RENT_KEYS.some(function (k) { return r[k] !== null && r[k] !== "" && r[k] !== undefined; }) || !!r.comentario;
    }

    function buildRentabilidad() {
        var input = fieldEl("TEXTO25");
        if (!input || input.dataset.vctProyReady === "1") return;
        input.dataset.vctProyReady = "1";
        input.classList.add("vct-proy-source");

        var card = document.createElement("div");
        card.className = "vct-proy-rent-card";
        input.parentNode.insertBefore(card, input.nextSibling);

        var dialog = modal().querySelector(".vct-modal-dialog");
        var panel = document.createElement("div");
        panel.className = "vct-proy-rent-panel";
        panel.setAttribute("role", "dialog");
        panel.setAttribute("aria-label", "Rentabilidad estimada");
        panel.innerHTML =
            '<div class="vct-proy-rent-sheet">' +
                '<div class="vct-proy-rent-head">' +
                    '<div><h4>Rentabilidad estimada</h4><p>Opcional. Se puede completar o corregir despu&eacute;s desde la Vista 360.</p></div>' +
                    '<button type="button" class="vct-form-close" data-rent-cancel aria-label="Cerrar">&times;</button>' +
                '</div>' +
                '<div class="vct-proy-rent-body">' +
                    '<div class="vct-proy-rent-col">' +
                        '<div class="vct-proy-rent-title">Presupuestado (S/IVA)</div>' +
                        money("montoPres", "Monto del proyecto") +
                        money("montoViat", "Monto de vi&aacute;ticos") +
                        '<div class="vct-field"><label class="vct-label">Fecha del presupuesto</label>' +
                            '<input type="date" class="vct-input" data-rent="fechaPres" data-vct-datepicker placeholder="Seleccionar fecha"></div>' +
                        '<div class="vct-proy-rent-total"><span>Presupuesto total</span><b data-rent-out="pres">$ 0,00</b></div>' +
                    '</div>' +
                    '<div class="vct-proy-rent-col">' +
                        '<div class="vct-proy-rent-title">Costos estimados</div>' +
                        money("costoMo", "Mano de obra") +
                        money("costoViat", "Vi&aacute;ticos") +
                        money("costoVarios", "Varios") +
                        '<div class="vct-proy-rent-total"><span>Costo total</span><b data-rent-out="costo">$ 0,00</b></div>' +
                    '</div>' +
                    '<div class="vct-proy-rent-result">' +
                        '<div><span>Rentabilidad estimada (S/IVA)</span><b data-rent-out="rent">$ 0,00</b></div>' +
                        '<div><span>Margen estimado</span><b data-rent-out="margen">-</b></div>' +
                    '</div>' +
                    '<div class="vct-field vct-proy-rent-comment"><label class="vct-label">Comentario</label>' +
                        '<textarea class="vct-textarea" rows="2" data-rent="comentario" maxlength="4000"></textarea></div>' +
                '</div>' +
                '<div class="vct-proy-rent-foot">' +
                    '<button type="button" class="vct-btn vct-btn-secondary" data-rent-clear>Limpiar</button>' +
                    '<span class="vct-proy-rent-spacer"></span>' +
                    '<button type="button" class="vct-btn vct-btn-secondary" data-rent-cancel>Cancelar</button>' +
                    '<button type="button" class="vct-btn vct-btn-primary" data-rent-apply>Aplicar</button>' +
                '</div>' +
            '</div>';
        dialog.appendChild(panel);

        function money(key, label) {
            return '<div class="vct-field"><label class="vct-label">' + label + '</label>' +
                '<input type="text" class="vct-input vct-proy-money" inputmode="decimal" placeholder="$ 0,00" data-rent="' + key + '"></div>';
        }
        function q(key) { return panel.querySelector('[data-rent="' + key + '"]'); }

        function recalc() {
            var r = {};
            RENT_KEYS.forEach(function (k) {
                if (k === "fechaPres") return;
                var v = parseMoney(q(k).value);
                r[k] = isNaN(v) ? null : v;
                q(k).classList.toggle("vct-field-error", isNaN(v));
            });
            var t = totals(r);
            panel.querySelector('[data-rent-out="pres"]').textContent = fmtMoney(t.pres);
            panel.querySelector('[data-rent-out="costo"]').textContent = fmtMoney(t.costo);
            var rentEl = panel.querySelector('[data-rent-out="rent"]');
            rentEl.textContent = fmtMoney(t.rent);
            rentEl.classList.toggle("is-negative", t.rent < 0);
            var mEl = panel.querySelector('[data-rent-out="margen"]');
            mEl.textContent = t.margen === null ? "-" : t.margen.toLocaleString("es-AR", { maximumFractionDigits: 2 }) + " %";
            mEl.classList.toggle("is-negative", t.margen !== null && t.margen < 0);
        }

        function load() {
            var r = readRent();
            RENT_KEYS.forEach(function (k) {
                var el = q(k);
                if (k === "fechaPres") {
                    el.value = r.fechaPres || "";
                    syncDateLabel(el);
                } else {
                    el.value = r[k] === null ? "" : fmtMoney(r[k]);
                }
            });
            q("comentario").value = r.comentario || "";
            recalc();
        }

        function apply() {
            var vals = [], bad = false;
            RENT_KEYS.forEach(function (k) {
                if (k === "fechaPres") { vals.push(q(k).value || ""); return; }
                var v = parseMoney(q(k).value);
                if (isNaN(v)) bad = true;
                vals.push(v === null || isNaN(v) ? "" : v.toFixed(2));
            });
            if (bad) { toast("Revise los importes marcados.", "error"); return; }
            var packed = vals.join("|");
            setValue(input, packed.replace(/\|/g, "") === "" ? "" : packed);
            var com = fieldEl("TEXTO26");
            if (com) com.value = q("comentario").value.trim();
            closePanel();
            paintCard();
        }

        function openPanel() { load(); panel.classList.add("is-open"); var f = q("montoPres"); if (f) f.focus(); }
        function closePanel() { panel.classList.remove("is-open"); }

        panel.addEventListener("input", function (e) { if (e.target.classList.contains("vct-proy-money")) recalc(); });
        panel.addEventListener("focusout", function (e) {
            if (!e.target.classList.contains("vct-proy-money")) return;
            var v = parseMoney(e.target.value);
            if (v !== null && !isNaN(v)) e.target.value = fmtMoney(v);
        });
        panel.addEventListener("click", function (e) {
            if (e.target.closest("[data-rent-cancel]")) closePanel();
            else if (e.target.closest("[data-rent-apply]")) apply();
            else if (e.target.closest("[data-rent-clear]")) {
                RENT_KEYS.forEach(function (k) { q(k).value = ""; syncDateLabel(q(k)); });
                q("comentario").value = "";
                recalc();
            }
        });
        panel.addEventListener("keydown", function (e) {
            if (e.key === "Escape") { e.stopPropagation(); closePanel(); }
        });

        card.addEventListener("click", function (e) {
            if (e.target.closest("[data-rent-open]")) openPanel();
        });
        input.addEventListener("change", paintCard);
        paintCard();

        function paintCard() {
            var r = readRent();
            if (!hasRent(r)) {
                card.innerHTML =
                    '<span class="vct-proy-rent-card-icon" data-vct-icon="chart-bar"></span>' +
                    '<span class="vct-proy-rent-card-copy"><b>Sin datos de rentabilidad</b><small>Presupuesto, costos estimados y margen. No es obligatorio para crear el proyecto.</small></span>' +
                    '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-rent-open>Cargar</button>';
            } else {
                var t = totals(r);
                card.innerHTML =
                    '<span class="vct-proy-rent-card-icon" data-vct-icon="chart-bar"></span>' +
                    '<span class="vct-proy-rent-kpis">' +
                        '<span><small>Presupuesto</small><b>' + fmtMoney(t.pres) + '</b></span>' +
                        '<span><small>Costo</small><b>' + fmtMoney(t.costo) + '</b></span>' +
                        '<span><small>Rentabilidad</small><b class="' + (t.rent < 0 ? "is-negative" : "is-positive") + '">' + fmtMoney(t.rent) + '</b></span>' +
                        '<span><small>Margen</small><b class="' + (t.margen !== null && t.margen < 0 ? "is-negative" : "is-positive") + '">' +
                            (t.margen === null ? "-" : t.margen.toLocaleString("es-AR", { maximumFractionDigits: 2 }) + " %") + '</b></span>' +
                    '</span>' +
                    '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-rent-open>Editar</button>';
            }
            icons(card);
        }
    }

    /* ======================================================================
       ANALISTA -> fecha limite obligatoria
       ====================================================================== */
    function syncAnalista() {
        var analista = fieldEl("TEXTO20"), fecha = fieldEl("TEXTO21");
        if (!fecha) return;
        var required = !!(analista && analista.value);
        if (required) fecha.setAttribute("data-vct-required", "true");
        else fecha.removeAttribute("data-vct-required");
        var wrap = fecha.closest(".vct-field");
        if (!wrap) return;
        var label = wrap.querySelector(".vct-label");
        var mark = label && label.querySelector(".vct-required");
        if (required && label && !mark) label.insertAdjacentHTML("beforeend", ' <span class="vct-required">*</span>');
        if (!required && mark) mark.remove();
        wrap.classList.toggle("vct-proy-muted", !required);
    }

    /* El date picker no se entera de cambios por codigo (DomForm.clear): se
       actualiza el texto visible con el mismo formato que usa el picker. */
    function syncDateLabel(input) {
        var wrap = input && input.closest(".vct-datepicker");
        if (!wrap) return;
        var valueEl = wrap.querySelector(".vct-datepicker-value");
        if (!valueEl) return;
        var txt = fmtDate(input.value);
        valueEl.textContent = txt || input.getAttribute("placeholder") || "Seleccionar fecha";
        valueEl.classList.toggle("is-placeholder", !txt);
    }

    /* ======================================================================
       INIT / APERTURA
       ====================================================================== */
    function enhance() {
        var m = modal();
        if (!m) return false;
        buildServicios();
        buildNormas();
        buildRentabilidad();
        if (m.dataset.vctProyReady !== "1") {
            m.dataset.vctProyReady = "1";
            m.addEventListener("change", function (e) {
                var f = e.target.getAttribute && e.target.getAttribute("data-vct-field");
                if (f === "TEXTO20") syncAnalista();
                if (e.target.type === "date") syncDateLabel(e.target);
            });
        }
        syncAnalista();
        return true;
    }

    function openAlta() {
        var m = modal();
        if (!m) {
            toast("No tiene permiso para dar de alta proyectos.", "info");
            return;
        }
        enhance();
        if (window.VCT && VCT.DomForm) {
            if (typeof VCT.DomForm.clear === "function") VCT.DomForm.clear(m);
            if (typeof VCT.DomForm.activateScope === "function") VCT.DomForm.activateScope(m);
        }
        var com = fieldEl("TEXTO26");
        if (com) com.value = "";
        m.querySelectorAll('input[type="date"]').forEach(syncDateLabel);
        syncAnalista();
        var panel = m.querySelector(".vct-proy-rent-panel");
        if (panel) panel.classList.remove("is-open");
        if (window.VCT && VCT.Modal) VCT.Modal.open(MODAL_ID);
        else m.classList.add("is-open");
        var nombre = fieldEl("TEXTO11");
        if (nombre) setTimeout(function () { nombre.focus(); }, 60);
    }

    /* Captura: corre antes que el handler del menu que mostraba el aviso. */
    document.addEventListener("click", function (e) {
        var opt = e.target.closest('[data-vct-menu-action="project-create"], [data-vct-pending-action="project-create"]');
        if (!opt) return;
        e.preventDefault();
        e.stopPropagation();
        if (window.VCT && VCT.RowMenu && typeof VCT.RowMenu.close === "function") VCT.RowMenu.close();
        document.querySelectorAll("details[data-vct-simple-menu][open]").forEach(function (d) { d.removeAttribute("open"); });
        openAlta();
    }, true);

    function showOk() {
        var ok = document.querySelector("[data-vct-proy-alta-ok]");
        if (!ok || ok.dataset.vctShown === "1") return;
        ok.dataset.vctShown = "1";
        toast(ok.getAttribute("data-vct-proy-alta-ok"), "success");
    }

    function boot() {
        enhance();
        showOk();
    }

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
    else boot();

    /* El modal llega en OUTPARAM3 (puede insertarse despues de este script). */
    if (window.MutationObserver) {
        var pending = false;
        new MutationObserver(function () {
            if (pending) return;
            pending = true;
            setTimeout(function () {
                pending = false;
                var m = modal();
                if (m && (m.dataset.vctProyReady !== "1" || !m.querySelector(".vct-proy-services"))) enhance();
                showOk();
            }, 30);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }
})(window, document);
