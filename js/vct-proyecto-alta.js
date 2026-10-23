/* vct-proyecto-alta.js - v3
   ============================================================================
   Alta de proyecto UNICA, en pantalla completa (como el editor de templates).
   El formulario #vctProyectoAlta lo arma dbo.VCT_PROYECTO_ALTA_RENDER y se usa desde:
     - Proyectos (boton "Nuevo")          -> cliente seleccionable (TEXTO19)
     - Vista 360 de Cliente (menu)        -> cliente fijo, no editable
   El SP arma los campos con VCT_MAIN_RENDER_FORM. Este script solo agrega:
     - Servicios como tarjetas; cada servicio elegido abre su linea de
       inicio / fin / horas                -> SP.TEXTO22 (id|aaaa-mm-dd|aaaa-mm-dd|horas;...)
     - Normas: frecuentes como chips + panel "Ver todas" -> SP.TEXTO24 (ids por coma)
     - Rentabilidad estimada en un panel aparte -> SP.TEXTO25 (6 valores con |)
                                                   SP.TEXTO26 (comentario)
     - Contactos filtrados por el cliente elegido.
     - Debajo del analista se ve el mail al que se le va a avisar.
     - Fecha limite de lanzamiento obligatoria solo si hay analista.
     - Nuevo -> oculta la grilla / la V360 y muestra el formulario;
       Volver o Cancelar -> vuelve a la pantalla de origen.
   El valor siempre viaja en el input original del formulario, asi que
   VCT.DomForm / VCT.Validation / el buffer no cambian.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoAltaV3) return;
    window.__vctProyectoAltaV3 = true;

    var FORM_ID = "vctProyectoAlta";
    var RENT_KEYS = ["montoPres", "montoViat", "fechaPres", "costoMo", "costoViat", "costoVarios"];
    var FRECUENTES = 8;

    function modal() { return document.getElementById(FORM_ID); }
    function view() { var m = modal(); return m ? m.closest(".vct-proy-alta-view") : null; }
    function fieldEl(name) {
        var m = modal();
        return m ? m.querySelector('[data-vct-field="' + name + '"]') : null;
    }
    function esc(s) {
        return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }
    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    }
    function csv(value) {
        return String(value || "").split(",").map(function (v) { return v.trim(); }).filter(Boolean);
    }
    function catalog(name) {
        var tpl = document.querySelector('template[data-vct-proy-catalog="' + name + '"]');
        if (!tpl) return [];
        var opts = tpl.content ? tpl.content.querySelectorAll("option") : tpl.querySelectorAll("option");
        return Array.prototype.map.call(opts, function (o) {
            return {
                id: o.value,
                text: o.textContent,
                codigo: (o.getAttribute("data-codigo") || "").toUpperCase(),
                grupo: o.getAttribute("data-grupo") || "",
                uso: Number(o.getAttribute("data-uso") || 0)
            };
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
    function datepickers(scope) {
        if (window.VCTDatePicker && typeof VCTDatePicker.init === "function") VCTDatePicker.init(scope);
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
    function fmtHoras(n) { return (n || 0).toLocaleString("es-AR", { maximumFractionDigits: 1 }); }
    /* ALTA_DOCS_V1: jornada de 8 h */
    function diasTxt(h) { var n = Number(h) || 0; return n > 0 ? "= " + fmtHoras(n / 8) + (n / 8 === 1 ? " d&iacute;a" : " d&iacute;as") : ""; }

    /* ======================================================================
       SERVICIOS: tarjeta + linea de fechas y horas por servicio elegido
       TEXTO22 = id|inicio|fin|horas;id|inicio|fin|horas
       ====================================================================== */
    var servApi = { syncDates: function () {} };
    var SERV_ICON = { CONSULTORIA: "briefcase", AUDITORIA: "clipboard-check", CAPACITACION: "users" };

    function readServ() {
        var input = fieldEl("TEXTO22"), out = [];
        String(input ? input.value : "").split(";").forEach(function (row) {
            var p = row.split("|");
            if (!p[0]) return;
            out.push({ id: p[0], ini: p[1] || "", fin: p[2] || "", hrs: p[3] || "" });
        });
        return out;
    }
    function writeServ(list) {
        setValue(fieldEl("TEXTO22"), list.map(function (s) {
            return [s.id, s.ini, s.fin, s.hrs].join("|");
        }).join(";"));
    }

    function buildServicios() {
        var input = fieldEl("TEXTO22");
        if (!input || input.dataset.vctProyReady === "1") return;
        input.dataset.vctProyReady = "1";
        input.classList.add("vct-proy-source");

        var cat = catalog("servicios"), byId = {};
        cat.forEach(function (s) { byId[s.id] = s; });

        var box = document.createElement("div");
        box.className = "vct-proy-srv-wrap";
        box.innerHTML =
            '<div class="vct-proy-services" role="group" aria-label="Servicios">' +
            (cat.map(function (s) {
                return '<button type="button" class="vct-proy-service" data-id="' + esc(s.id) + '" aria-pressed="false">' +
                    '<span class="vct-proy-service-icon" data-vct-icon="' + (SERV_ICON[s.codigo] || "list-checks") + '"></span>' +
                    '<span class="vct-proy-service-name">' + esc(s.text) + '</span>' +
                    '<span class="vct-proy-service-check" aria-hidden="true">&#10003;</span>' +
                    '</button>';
            }).join("") || '<div class="vct-proy-empty">No hay servicios activos en la parametr&iacute;a.</div>') +
            '</div>' +
            '<div class="vct-proy-srv-detail" hidden>' +
                '<div class="vct-proy-srv-head"><span>Servicio</span><span>Inicio</span><span>Fin</span><span>Horas (d&iacute;as)</span></div>' +
                '<div class="vct-proy-srv-rows"></div>' +
                '<div class="vct-proy-srv-foot"><div class="vct-proy-srv-track"><span></span></div><span class="vct-proy-srv-total"></span></div>' +
            '</div>';
        input.parentNode.insertBefore(box, input.nextSibling);
        icons(box);

        var rows = box.querySelector(".vct-proy-srv-rows");
        var detail = box.querySelector(".vct-proy-srv-detail");

        box.querySelector(".vct-proy-services").addEventListener("click", function (e) {
            var btn = e.target.closest(".vct-proy-service");
            if (!btn) return;
            var id = btn.getAttribute("data-id"), list = readServ();
            var i = list.map(function (s) { return s.id; }).indexOf(id);
            if (i >= 0) list.splice(i, 1);
            else list.push({ id: id, ini: valueOf("TEXTO13"), fin: valueOf("TEXTO14"), hrs: "" });
            list.sort(function (a, b) { return Number(a.id) - Number(b.id); });
            writeServ(list);
        });

        /* cambios dentro de una linea -> TEXTO22 */
        rows.addEventListener("change", onRow);
        rows.addEventListener("input", function (e) {
            if (!e.target.hasAttribute("data-srv-hrs")) return;
            var dd = e.target.parentNode.querySelector("[data-srv-dias]");
            if (dd) dd.innerHTML = diasTxt(e.target.value);
            onRow(e);
        });
        function onRow(e) {
            var row = e.target.closest("[data-srv]");
            if (!row) return;
            var list = readServ(), id = row.getAttribute("data-srv");
            list.forEach(function (s) {
                if (s.id !== id) return;
                s.ini = row.querySelector("[data-srv-ini]").value;
                s.fin = row.querySelector("[data-srv-fin]").value;
                s.hrs = row.querySelector("[data-srv-hrs]").value;
            });
            input.value = list.map(function (s) { return [s.id, s.ini, s.fin, s.hrs].join("|"); }).join(";");
            if (e.target.type === "date") checkRow(row);
            paintBar();
        }

        /* rango de fechas del servicio: se avisa en la misma linea al cambiarlas */
        function checkRow(row) {
            var ini = row.querySelector("[data-srv-ini]").value, fin = row.querySelector("[data-srv-fin]").value;
            var pIni = valueOf("TEXTO13"), pFin = valueOf("TEXTO14"), msg = "";
            if (ini && fin && fin < ini) msg = "La fecha de fin es anterior a la de inicio.";
            else if ((ini && pIni && ini < pIni) || (fin && pFin && fin > pFin) || (ini && pFin && ini > pFin) || (fin && pIni && fin < pIni))
                msg = "Las fechas tienen que estar entre " + fmtDate(pIni) + " y " + fmtDate(pFin) + " (plazo del proyecto).";
            var box = row.querySelector(".vct-proy-srv-msg");
            box.textContent = msg;
            box.hidden = !msg;
            row.classList.toggle("is-error", !!msg);
        }

        /* fechas del proyecto -> servicios: se copian a las lineas vacias o
           que todavia tenian la fecha anterior del proyecto */
        var lastIni = valueOf("TEXTO13"), lastFin = valueOf("TEXTO14");
        servApi.syncDates = function () {
            var nIni = valueOf("TEXTO13"), nFin = valueOf("TEXTO14"), list = readServ();
            list.forEach(function (s) {
                if (!s.ini || s.ini === lastIni) s.ini = nIni;
                if (!s.fin || s.fin === lastFin) s.fin = nFin;
            });
            lastIni = nIni; lastFin = nFin;
            writeServ(list);
        };

        input.addEventListener("change", paintServicios);
        paintServicios();

        function paintServicios() {
            var list = readServ(), ids = list.map(function (s) { return s.id; });
            box.querySelectorAll(".vct-proy-service").forEach(function (btn) {
                var on = ids.indexOf(btn.getAttribute("data-id")) >= 0;
                btn.classList.toggle("is-selected", on);
                btn.setAttribute("aria-pressed", on ? "true" : "false");
            });
            detail.hidden = !list.length;
            rows.innerHTML = list.map(function (s) {
                var c = byId[s.id] || { text: "#" + s.id, codigo: "" };
                return '<div class="vct-proy-srv-row" data-srv="' + esc(s.id) + '">' +
                    '<span class="vct-proy-srv-name"><span data-vct-icon="' + (SERV_ICON[c.codigo] || "list-checks") + '"></span>' + esc(c.text) + '</span>' +
                    '<input type="date" class="vct-input" data-vct-datepicker data-srv-ini value="' + esc(s.ini) + '" placeholder="Inicio" aria-label="Inicio ' + esc(c.text) + '">' +
                    '<input type="date" class="vct-input" data-vct-datepicker data-srv-fin value="' + esc(s.fin) + '" placeholder="Fin" aria-label="Fin ' + esc(c.text) + '">' +
                    /* ALTA_DOCS_V1: dias = horas / 8, al lado de las horas del servicio */
                    '<div class="vct-proy-srv-hcell"><input type="number" class="vct-input vct-proy-srv-hrs" min="0" step="1" data-srv-hrs value="' + esc(s.hrs) + '" placeholder="0" aria-label="Horas ' + esc(c.text) + '">' +
                    '<small class="vct-proy-srv-dias" data-srv-dias>' + diasTxt(s.hrs) + '</small></div>' +
                    '<div class="vct-proy-srv-msg" hidden></div>' +
                    '</div>';
            }).join("");
            icons(rows);
            datepickers(rows);
            rows.querySelectorAll("[data-srv]").forEach(checkRow);
            paintBar();
        }

        function paintBar() {
            var total = Number(valueOf("TEXTO15")) || 0, sum = 0;
            readServ().forEach(function (s) { sum += Number(s.hrs) || 0; });
            var pct = total > 0 ? Math.min(100, (sum * 100) / total) : 0;
            var bar = box.querySelector(".vct-proy-srv-track span");
            var lbl = box.querySelector(".vct-proy-srv-total");
            var st = !total ? "is-empty" : sum === total ? "is-ok" : sum > total ? "is-over" : "is-under";
            bar.style.width = pct + "%";
            box.querySelector(".vct-proy-srv-foot").className = "vct-proy-srv-foot " + st;
            lbl.textContent = !total
                ? fmtHoras(sum) + " h asignadas - cargue las horas proyectadas"
                : st === "is-ok" ? fmtHoras(sum) + " de " + fmtHoras(total) + " h asignadas"
                : st === "is-over" ? "Sobran " + fmtHoras(sum - total) + " h (" + fmtHoras(sum) + " de " + fmtHoras(total) + ")"
                : "Faltan " + fmtHoras(total - sum) + " h (" + fmtHoras(sum) + " de " + fmtHoras(total) + ")";
        }
        var hrs = fieldEl("TEXTO15");
        if (hrs) hrs.addEventListener("input", paintBar);
    }

    function valueOf(name) { var el = fieldEl(name); return el ? el.value : ""; }

    /* ======================================================================
       NORMAS: chips de las mas usadas + panel "Ver todas" con buscador
       TEXTO24 = ids por coma
       ====================================================================== */
    function buildNormas() {
        var input = fieldEl("TEXTO24");
        if (!input || input.dataset.vctProyReady === "1") return;
        input.dataset.vctProyReady = "1";
        input.classList.add("vct-proy-source");

        var all = catalog("normas"), byId = {};
        all.forEach(function (n) { byId[n.id] = n; });
        var top = all.slice().sort(function (a, b) { return b.uso - a.uso || a.text.localeCompare(b.text); })
            .slice(0, FRECUENTES).map(function (n) { return n.id; });

        var box = document.createElement("div");
        box.className = "vct-proy-normas";
        box.innerHTML =
            '<div class="vct-proy-norm-chips"></div>' +
            '<div class="vct-proy-norm-foot"><span class="vct-proy-norm-count"></span>' +
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-norm-open><span data-vct-icon="search"></span><span>Ver todas</span></button></div>';
        input.parentNode.insertBefore(box, input.nextSibling);

        /* panel "Ver todas": modal estandar (misma cabecera que el resto) */
        var panel = document.createElement("div");
        panel.id = "vctProyNormasModal";
        panel.className = "vct-modal vct-form-shell vct-form-medium vct-proy-norm-modal";
        panel.setAttribute("data-vct-component", "modal");
        panel.setAttribute("data-vct-id", panel.id);
        panel.innerHTML =
            '<div class="vct-modal-backdrop" data-norm-cancel></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-label="Normas del proyecto">' +
                '<div class="vct-modal-header vct-form-header">' +
                    '<div class="vct-form-header-accent"></div>' +
                    '<div class="vct-form-header-icon"><span data-vct-icon="list-checks"></span></div>' +
                    '<div class="vct-form-header-copy"><h3 class="vct-modal-title">Normas del proyecto</h3>' +
                        '<p class="vct-modal-subtitle">Marque todas las que aplican. Son del proyecto, no de cada servicio.</p></div>' +
                    '<button type="button" class="vct-form-close" data-norm-cancel aria-label="Cerrar">&times;</button>' +
                '</div>' +
                '<div class="vct-modal-body vct-form-body">' +
                    '<div class="vct-proy-norm-search"><span class="vct-proy-norm-search-icon" data-vct-icon="search"></span>' +
                        '<input type="text" class="vct-input vct-proy-norm-q" placeholder="Buscar por c&oacute;digo o nombre..." autocomplete="off" data-norm-q aria-label="Buscar normas"></div>' +
                    '<div class="vct-proy-norm-list" data-norm-list role="listbox" aria-multiselectable="true"></div>' +
                '</div>' +
                '<div class="vct-modal-footer vct-form-footer">' +
                    '<span class="vct-proy-norm-sel" data-norm-sel></span>' +
                    '<span class="vct-proy-rent-spacer"></span>' +
                    '<button type="button" class="vct-btn vct-btn-secondary" data-norm-cancel>Cancelar</button>' +
                    '<button type="button" class="vct-btn vct-btn-primary" data-norm-apply>Aplicar</button>' +
                '</div>' +
            '</div>';
        (view() || modal()).appendChild(panel);
        icons(box); icons(panel);

        var chips = box.querySelector(".vct-proy-norm-chips");
        var count = box.querySelector(".vct-proy-norm-count");
        var list = panel.querySelector("[data-norm-list]");
        var q = panel.querySelector("[data-norm-q]");
        var draft = [], pinned = [];

        function selected() { return csv(input.value); }

        function paint() {
            var ids = selected();
            /* frecuentes + las elegidas que no estan entre las frecuentes */
            var show = top.slice();
            ids.forEach(function (id) { if (show.indexOf(id) < 0) show.push(id); });
            chips.innerHTML = show.map(function (id) {
                var n = byId[id], on = ids.indexOf(id) >= 0;
                return '<button type="button" class="vct-proy-norm-chip' + (on ? " is-selected" : "") + '" data-id="' + esc(id) + '" aria-pressed="' + on + '">' +
                    '<span class="vct-proy-norm-tick" aria-hidden="true">' + (on ? "&#10003;" : "+") + '</span>' + esc(n ? n.text : "#" + id) + '</button>';
            }).join("");
            count.textContent = ids.length ? ids.length + (ids.length === 1 ? " norma elegida" : " normas elegidas") : "Ninguna norma elegida";
            count.classList.toggle("is-empty", !ids.length);
        }

        function renderList() {
            var t = norm(q.value), groups = {}, order = [];
            /* las ya elegidas al abrir van primero, asi se ven sin buscarlas */
            var lista = all.filter(function (n) { return pinned.indexOf(n.id) >= 0; })
                .concat(all.filter(function (n) { return pinned.indexOf(n.id) < 0; }));
            lista.filter(function (n) { return !t || norm(n.text).indexOf(t) >= 0; }).forEach(function (n) {
                var g = n.grupo || "Normas";
                if (!groups[g]) { groups[g] = []; order.push(g); }
                groups[g].push(n);
            });
            list.innerHTML = order.length ? order.map(function (g) {
                return (order.length > 1 ? '<div class="vct-proy-norm-group">' + esc(g) + '</div>' : '') + groups[g].map(function (n) {
                    var on = draft.indexOf(n.id) >= 0;
                    return '<button type="button" role="option" class="vct-proy-norm-item' + (on ? " is-selected" : "") + '" data-id="' + esc(n.id) + '" aria-selected="' + on + '">' +
                        '<span class="vct-proy-norm-box" aria-hidden="true">' + (on ? "&#10003;" : "") + '</span><span>' + esc(n.text) + '</span></button>';
                }).join("");
            }).join("") : '<div class="vct-proy-empty">No hay normas que coincidan.</div>';
            panel.querySelector("[data-norm-sel]").textContent = draft.length + (draft.length === 1 ? " elegida" : " elegidas");
        }

        function openPanel() {
            draft = selected();
            pinned = draft.slice();
            q.value = "";
            renderList();
            panel.classList.add("is-open");
            document.body.classList.add("vct-modal-open");
            setTimeout(function () { q.focus(); }, 30);
        }
        function closePanel() {
            panel.classList.remove("is-open");
            if (!document.querySelector(".vct-modal.is-open")) document.body.classList.remove("vct-modal-open");
        }

        chips.addEventListener("click", function (e) {
            var c = e.target.closest(".vct-proy-norm-chip");
            if (!c) return;
            var ids = selected(), id = c.getAttribute("data-id"), i = ids.indexOf(id);
            if (i >= 0) ids.splice(i, 1); else ids.push(id);
            setValue(input, ids.join(","));
        });
        box.addEventListener("click", function (e) { if (e.target.closest("[data-norm-open]")) openPanel(); });
        q.addEventListener("input", renderList);
        list.addEventListener("click", function (e) {
            var it = e.target.closest(".vct-proy-norm-item");
            if (!it) return;
            var id = it.getAttribute("data-id"), i = draft.indexOf(id), on = i < 0;
            if (on) draft.push(id); else draft.splice(i, 1);
            it.classList.toggle("is-selected", on);
            it.setAttribute("aria-selected", on ? "true" : "false");
            it.querySelector(".vct-proy-norm-box").innerHTML = on ? "&#10003;" : "";
            panel.querySelector("[data-norm-sel]").textContent = draft.length + (draft.length === 1 ? " elegida" : " elegidas");
        });
        panel.addEventListener("click", function (e) {
            if (e.target.closest("[data-norm-cancel]")) closePanel();
            else if (e.target.closest("[data-norm-apply]")) { setValue(input, draft.join(",")); closePanel(); }
        });
        panel.addEventListener("keydown", function (e) { if (e.key === "Escape") { e.stopPropagation(); closePanel(); } });
        input.addEventListener("change", paint);
        paint();
    }

    /* ======================================================================
       CLIENTE -> contactos del cliente elegido
       ====================================================================== */
    /* Contacto: solo los de VCT_CONTACTOS del cliente elegido (data-cliente).
       Se filtra el select y el menu del combo estandar (VCT.FormSelect). */
    function VCT_trim(t) { return String(t || "").replace(/^\s+|\s+$/g, ""); }
    function syncContactos() {
        var cli = fieldEl("TEXTO19"), con = fieldEl("TEXTO17");
        if (!cli || !con || con.tagName !== "SELECT") return;
        var id = cli.value, visibles = 0, ph = null;
        Array.prototype.forEach.call(con.options, function (o) {
            if (!o.value) { ph = o; return; }
            var ok = !!id && o.getAttribute("data-cliente") === id;
            o.hidden = !ok; o.disabled = !ok;
            if (ok) visibles++;
            if (!ok && o.selected) con.value = "";
        });
        if (ph) ph.text = !id ? "Seleccione primero el cliente" : visibles ? "Seleccione un contacto" : "El cliente no tiene contactos cargados";
        /* el menu visible del combo (VCT.FormSelect) es otro elemento en el
           body: se dejan en el solo las opciones del cliente (se guardan todas
           la primera vez y se vuelven a poner las que corresponden) */
        var wrap = con.parentNode ? con.parentNode.querySelector(".vct-form-select") : null;
        var menu = wrap && wrap.__vctPortalMenu;
        if (menu) {
            if (!menu.__vctProyAll) menu.__vctProyAll = Array.prototype.slice.call(menu.querySelectorAll(".vct-form-select-option"));
            menu.__vctProyAll.forEach(function (opt) {
                var v = opt.getAttribute("data-value");
                var src = v ? con.querySelector('option[value="' + v.replace(/"/g, "") + '"]') : null;
                if (!v && ph) opt.textContent = ph.text;
                var ok = !v || (src && !src.hidden && VCT_trim(opt.textContent) !== "");
                if (ok && opt.parentNode !== menu) menu.appendChild(opt);
                if (!ok && opt.parentNode) opt.parentNode.removeChild(opt);
            });
        }
        if (wrap && window.VCT && VCT.FormSelect && typeof VCT.FormSelect.sync === "function") VCT.FormSelect.sync(con, wrap);
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

        var dialog = view() || modal();
        var panel = document.createElement("div");
        /* modal estandar: misma cabecera (icono + titulo) que el resto */
        panel.id = "vctProyRentModal";
        panel.className = "vct-modal vct-form-shell vct-form-large vct-proy-rent-modal";
        panel.setAttribute("data-vct-component", "modal");
        panel.setAttribute("data-vct-id", panel.id);
        panel.innerHTML =
            '<div class="vct-modal-backdrop" data-rent-cancel></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-label="Rentabilidad estimada">' +
                '<div class="vct-modal-header vct-form-header">' +
                    '<div class="vct-form-header-accent"></div>' +
                    '<div class="vct-form-header-icon"><span data-vct-icon="chart-bar"></span></div>' +
                    '<div class="vct-form-header-copy"><h3 class="vct-modal-title">Rentabilidad estimada</h3>' +
                        '<p class="vct-modal-subtitle">Opcional. Se puede completar o corregir despu&eacute;s desde la Vista 360.</p></div>' +
                    '<button type="button" class="vct-form-close" data-rent-cancel aria-label="Cerrar">&times;</button>' +
                '</div>' +
                '<div class="vct-modal-body vct-form-body"><div class="vct-proy-rent-body">' +
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
                '</div></div>' +
                '<div class="vct-modal-footer vct-form-footer">' +
                    '<button type="button" class="vct-btn vct-btn-secondary" data-rent-clear>Limpiar</button>' +
                    '<span class="vct-proy-rent-spacer"></span>' +
                    '<button type="button" class="vct-btn vct-btn-secondary" data-rent-cancel>Cancelar</button>' +
                    '<button type="button" class="vct-btn vct-btn-primary" data-rent-apply>Aplicar</button>' +
                '</div>' +
            '</div>';
        dialog.appendChild(panel);
        icons(panel);

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

        function openPanel() {
            load();
            panel.classList.add("is-open");
            document.body.classList.add("vct-modal-open");
            var f = q("montoPres");
            if (f) f.focus();
        }
        function closePanel() {
            panel.classList.remove("is-open");
            if (!document.querySelector(".vct-modal.is-open")) document.body.classList.remove("vct-modal-open");
        }

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
       ANALISTA -> mail de aviso visible + fecha limite obligatoria
       El mail sale del data-email de la opcion (VCT_EMAILS principal).
       ====================================================================== */
    /* Analista y fecha limite son obligatorios (los marca el SP). Debajo del
       analista se ve el mail al que se le va a avisar (data-email de la opcion,
       mail principal de VCT_EMAILS). */
    function syncAnalista() {
        syncMail();
        var analista = fieldEl("TEXTO20");
        if (!analista) return;
        var wrap = analista.closest(".vct-field"), help = wrap && wrap.querySelector(".vct-help");
        var opt = analista.tagName === "SELECT" ? analista.options[analista.selectedIndex] : null;
        var mail = opt && opt.value ? (opt.getAttribute("data-email") || "") : "";
        if (!help) return;
        help.innerHTML = !analista.value
            ? "Recibe la gesti&oacute;n y el mail para organizar el lanzamiento."
            : mail ? 'Se le avisa a <b>' + esc(mail) + '</b> y recibe la gesti&oacute;n para organizar el lanzamiento.'
            : '<span class="vct-proy-warn">El analista no tiene mail principal cargado: se crea la gesti&oacute;n pero no se env&iacute;a el mail.</span>';
    }

    /* El date picker no se entera de cambios por codigo (DomForm.clear). */
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
       VALIDACION PREVIA (mismas reglas que va a aplicar el SP al grabar)
       window + captura: corre antes que el validate-next de vct-main.js
       ====================================================================== */
    function errores() {
        var e = [], cat = {}, total = Number(valueOf("TEXTO15")) || 0, suma = 0;
        var pIni = valueOf("TEXTO13"), pFin = valueOf("TEXTO14");
        catalog("servicios").forEach(function (s) { cat[s.id] = s; });
        var list = readServ();
        if (pIni && pFin && pFin < pIni) e.push("La fecha de fin del proyecto es anterior al inicio.");
        if (!list.length) e.push("Seleccione al menos un servicio.");
        list.forEach(function (s) {
            var c = cat[s.id] || { text: "#" + s.id, codigo: "" }, h = Number(s.hrs) || 0;
            suma += h;
            if (!s.ini || !s.fin) e.push(c.text + ": falta la fecha de inicio o de fin.");
            else if (s.fin < s.ini) e.push(c.text + ": la fecha de fin es anterior al inicio.");
            else if ((pIni && s.ini < pIni) || (pFin && s.fin > pFin)) e.push(c.text + ": las fechas deben estar dentro del plazo del proyecto.");
            if (h <= 0) e.push(c.text + ": cargue las horas.");
        });
        if (list.length && total > 0 && suma !== total)
            e.push("La suma de horas de los servicios (" + fmtHoras(suma) + " h) debe ser igual a las horas proyectadas (" + fmtHoras(total) + " h).");
        if (!csv(valueOf("TEXTO24")).length) e.push("Normas es obligatorio: elija al menos una norma.");
        return e;
    }
    /* Se encadena a la validacion estandar (VCT.Validation.validate):
       primero valida los campos obligatorios en orden, como todos los
       formularios; recien si estan completos revisa servicios y normas. */
    function hookValidation() {
        if (!window.VCT || !VCT.Validation || VCT.Validation.__vctProyAlta) return;
        var base = VCT.Validation.validate;
        VCT.Validation.validate = function (scope) {
            /* ALTA_CONTACTO_V1: grabar solo el contacto nuevo (el proyecto se valida despues) */
            if (scope && scope.id === FORM_ID && ctPendiente()) return true;
            var ok = base.apply(this, arguments);
            if (!ok || !scope || scope.id !== FORM_ID) return ok;
            var list = errores();
            var me = mailError();
            if (me) list.push(me);
            if (!list.length) return true;
            var box = scope.querySelector("[data-vct-validation-box]");
            if (box) {
                box.innerHTML = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul>' +
                    list.map(function (x) { return "<li>" + esc(x) + "</li>"; }).join("") + "</ul>";
                box.style.display = "block";
                box.scrollIntoView({ block: "center" });
            }
            return false;
        };
        VCT.Validation.__vctProyAlta = true;
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
                if (f === "TEXTO19") syncContactos();
                if (f === "TEXTO15") { var s = fieldEl("TEXTO22"); if (s) s.dispatchEvent(new Event("change", { bubbles: true })); }
                if (f === "TEXTO13" || f === "TEXTO14") servApi.syncDates();
                if (e.target.type === "date") syncDateLabel(e.target);
            });
        }
        syncAnalista();
        syncContactos();
        return true;
    }

    /* La vista se muestra dentro de la pantalla actual ([data-vct-page]):
       se ocultan los demas bloques (grilla / V360) y vuelven al cerrar. */
    /* El buffer exige una sola copia de cada SP.xxx en la pagina. La pantalla
       de origen tiene las suyas (ej. SP.TEXTO30 de Proyectos, que usan
       "Otros estados" y los filtros). Mientras el alta esta cerrada el
       formulario no tiene name en las que se repiten; al abrirlo es al reves.
       Se guarda el name en data-vct-proy-name y se devuelve al cambiar. */
    function ownNames(abierto) {
        var v = view();
        if (!v) return;
        function park(el) {
            if (!el.getAttribute("name")) return;
            el.setAttribute("data-vct-proy-name", el.getAttribute("name"));
            el.removeAttribute("name");
        }
        function unpark(el) {
            var n = el.getAttribute("data-vct-proy-name");
            if (!n) return;
            el.setAttribute("name", n);
            el.removeAttribute("data-vct-proy-name");
        }
        var propios = Array.prototype.slice.call(v.querySelectorAll("[name], [data-vct-proy-name]"));
        propios.forEach(function (i) {
            var n = i.getAttribute("name") || i.getAttribute("data-vct-proy-name");
            var otros = Array.prototype.filter.call(
                document.querySelectorAll('[name="' + n + '"], [data-vct-proy-name="' + n + '"]'),
                function (o) { return !v.contains(o); });
            if (!otros.length) { unpark(i); return; }
            if (abierto) { unpark(i); otros.forEach(park); }
            else { park(i); otros.forEach(unpark); }
        });
    }

    function showView() {
        var v = view();
        if (!v) return;
        var page = document.querySelector("[data-vct-page]");
        if (page && v.parentNode !== page) page.insertBefore(v, page.firstChild);
        if (page) page.classList.add("vct-proy-alta-on");
        /* el buffer exige una sola copia de cada SP.xxx: la pantalla de
           origen puede tener la suya (ej. SP.TEXTO30 de Proyectos). Se le
           saca el name mientras el alta esta abierta y se devuelve al cerrar. */
        ownNames(true);
        v.classList.add("is-open");
        window.scrollTo(0, 0);
        var sc = v.closest(".vct-main-content, .vct-content, main");
        if (sc) sc.scrollTop = 0;
    }
    function closeAlta() {
        var v = view();
        if (v) v.classList.remove("is-open");
        ownNames(false);
        document.querySelectorAll(".vct-proy-alta-on").forEach(function (p) { p.classList.remove("vct-proy-alta-on"); });
        document.querySelectorAll(".vct-proy-rent-modal.is-open, .vct-proy-norm-modal.is-open").forEach(function (p) { p.classList.remove("is-open"); });
        document.body.classList.remove("vct-modal-open");
        window.scrollTo(0, 0);
    }

    /* ALTA_DOCS_V1: propuesta comercial con el upload del framework (task/UploadFile.ashx).
       El archivo queda en PHYSICAL_ATTACHED_DOCUMENT con PAR_KEY = trámite; al grabar el alta
       VCT_PROYECTO_ALTA_GUARDAR lo vincula al proyecto (VCT_PROYECTOS_DOCUMENTOS). */
    function adjInit() {
        var w = document.querySelector("[data-vct-proy-adj]");
        if (!w || w.dataset.vctAdj === "1") return;
        w.dataset.vctAdj = "1";
        var key = w.getAttribute("data-key") || "";
        var $ = window.jQuery;
        if (typeof window.initAttachFiles === "function" && $ && $.fn && $.fn.fileupload && key) {
            window.initAttachFiles(FORM_ID, key);
            adjWatch(w);
        } else {
            var b = w.querySelector(".vct-proy-adj-btn");
            if (b) b.hidden = true;
            var l = w.querySelector(".vct-proy-adj-list");
            if (l) l.textContent = "El adjunto no est\u00e1 disponible en esta pantalla.";
        }
    }

    /* ALTA_ADJ_V2: la lista del framework (AttachedFiles.ashx, w3) se reemplaza por tarjetas propias.
       Su "x" solo ocultaba la fila (el archivo igual se vinculaba): "Quitar" anota la clave en TEXTO28
       y VCT_PROYECTO_ALTA_GUARDAR no la vincula al proyecto. */
    function adjQuitados() {
        var f = fieldEl("TEXTO28");
        return f && f.value ? f.value.split(",").filter(Boolean) : [];
    }
    function adjIcon(name) {
        var ext = String(name || "").split(".").pop().toLowerCase();
        return ext === "pdf" ? "PDF" : ext === "doc" || ext === "docx" ? "DOC" : ext === "xls" || ext === "xlsx" ? "XLS" : (ext || "ARCH").slice(0, 4).toUpperCase();
    }
    function adjPaint(w) {
        var box = document.getElementById(FORM_ID + "_attached_files");
        var out = w.querySelector("[data-vct-proy-adj-files]");
        if (!box || !out) return;
        var fuera = adjQuitados(), items = [];
        box.querySelectorAll("li").forEach(function (li) {
            var op = li.querySelector("[onclick*='OpenAttach']");
            var m = op ? /OpenAttach\('([^']*)','([^']*)'\)/.exec(op.getAttribute("onclick") || "") : null;
            if (!m || fuera.indexOf(m[1]) >= 0) return;
            var sp = op.querySelectorAll(".w3-left");
            items.push({ k: m[1], n: m[2], meta: sp.length > 1 ? sp[1].textContent.trim() : "" });
        });
        out.innerHTML = items.map(function (it) {
            return '<div class="vct-proy-adj-file" data-k="' + esc(it.k) + '">' +
                '<span class="vct-proy-adj-ext">' + esc(adjIcon(it.n)) + '</span>' +
                '<button type="button" class="vct-proy-adj-name" data-vct-proy-adj-open="' + esc(it.k) + '" data-n="' + esc(it.n) + '" title="Ver archivo">' +
                    '<b>' + esc(it.n) + '</b><small>' + esc(it.meta) + '</small></button>' +
                '<button type="button" class="vct-proy-adj-del" data-vct-proy-adj-del="' + esc(it.k) + '" title="Quitar" aria-label="Quitar ' + esc(it.n) + '">' +
                    '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
                    '<path d="M3 6h18"></path><path d="M8 6V4h8v2"></path><path d="M19 6l-1 14H6L5 6"></path><path d="M10 11v6M14 11v6"></path></svg></button>' +
                '</div>';
        }).join("");
        out.hidden = !items.length;
        w.classList.toggle("has-files", items.length > 0);
    }
    function adjWatch(w) {
        var box = document.getElementById(FORM_ID + "_attached_files");
        if (!box) return;
        box.classList.add("vct-proy-adj-raw");
        if (!w.querySelector("[data-vct-proy-adj-files]")) {
            var out = document.createElement("div");
            out.className = "vct-proy-adj-files";
            out.setAttribute("data-vct-proy-adj-files", "");
            out.hidden = true;
            box.parentNode.insertBefore(out, box);
        }
        if (window.MutationObserver) new MutationObserver(function () { adjPaint(w); }).observe(box, { childList: true, subtree: true });
        adjPaint(w);
    }
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        var op = t.closest("[data-vct-proy-adj-open]");
        if (op) { e.preventDefault(); if (typeof window.OpenAttach === "function") window.OpenAttach(op.getAttribute("data-vct-proy-adj-open"), op.getAttribute("data-n")); return; }
        var del = t.closest("[data-vct-proy-adj-del]");
        if (!del) return;
        e.preventDefault();
        var f = fieldEl("TEXTO28"), k = del.getAttribute("data-vct-proy-adj-del");
        if (f) { var l = adjQuitados(); if (l.indexOf(k) < 0) l.push(k); f.value = l.join(","); }
        var card = del.closest(".vct-proy-adj-file");
        if (card) card.classList.add("is-out");
        setTimeout(function () { var w = document.querySelector("[data-vct-proy-adj]"); if (w) adjPaint(w); }, 180);
    });

    /* ALTA_CONTACTO_V1: "+" al lado de Contacto del cliente -> modal de alta de contacto.
       Graba por el mismo boton del formulario con TEXTO27 = CONTACTO|nombres|apellido|cargo|obs;
       VCT_PROYECTO_ALTA_GUARDAR inserta el contacto (VCT_CONTACTOS), lo deja elegido en TEXTO17
       y vuelve a abrir el alta con todo lo cargado (no graba el proyecto). */
    function ctPendiente() { var f = fieldEl("TEXTO27"); return !!(f && /^(CONTACTO|EMAIL)\|/.test(f.value || "")); }
    function ctCliente() { var c = fieldEl("TEXTO19"); return c ? (c.value || "") : ""; }
    function ctButton() {
        emButton();
        var sel = fieldEl("TEXTO17");
        if (!sel || !fieldEl("TEXTO27")) return;
        var fld = sel.closest(".vct-field");
        if (!fld || fld.querySelector(".vct-proy-ct-add")) return;
        fld.classList.add("vct-proy-ct-field");
        var b = document.createElement("button");
        b.type = "button";
        b.className = "vct-proy-ct-add";
        b.setAttribute("data-vct-proy-ct-add", "");
        b.title = "Nuevo contacto";
        b.setAttribute("aria-label", "Nuevo contacto del cliente");
        b.textContent = "+";
        fld.appendChild(b);
    }
    /* ALTA_CONTACTO_V2: mismo markup que los modales del framework (VCT_MAIN_RENDER_FORM, LAYOUT MODAL),
       con titulo/subtitulo/icono del drawer Contacto de la V360 de cliente; sin telefono ni email. */
    var CT_ID = "vctProyContacto";
    /* ALTA_ANALISTA_MAIL_V1: "+" al lado del analista -> modal Email (mismo diseno que Contacto).
       Graba por el boton del formulario con TEXTO27 = EMAIL|id_analista|email; el SP lo
       inserta en VCT_EMAILS (EMPLEADO, PRINCIPAL = NO) y vuelve a abrir el alta. */
    var EM_ID = "vctProyEmail";
    function emButton() {
        var sel = fieldEl("TEXTO20");
        if (!sel || !fieldEl("TEXTO27")) return;
        var fld = sel.closest(".vct-field");
        if (!fld || fld.querySelector("[data-vct-proy-em-add]")) return;
        fld.classList.add("vct-proy-ct-field");
        var b = document.createElement("button");
        b.type = "button";
        b.className = "vct-proy-ct-add";
        b.setAttribute("data-vct-proy-em-add", "");
        b.title = "Nuevo email del analista";
        b.setAttribute("aria-label", "Nuevo email del analista");
        b.textContent = "+";
        fld.appendChild(b);
    }
    function emClose() {
        var o = document.getElementById(EM_ID);
        if (!o) return;
        o.classList.remove("is-open");
        setTimeout(function () { if (o.parentNode) o.parentNode.removeChild(o); }, 200);
    }
    function emOpen() {
        if (!ctCliente()) { toast("Primero elija el cliente.", "info"); var c = fieldEl("TEXTO19"); if (c) c.focus(); return; }
        var a = anaInfo();
        if (!a) { toast("Primero elija el analista.", "info"); var s0 = fieldEl("TEXTO20"); if (s0) s0.focus(); return; }
        var prev = document.getElementById(EM_ID);
        if (prev) prev.parentNode.removeChild(prev);
        var o = document.createElement("div");
        o.id = EM_ID;
        o.className = "vct-modal vct-form-shell vct-form-md vct-proy-ct-modal";
        o.innerHTML =
            '<div class="vct-modal-backdrop" data-vct-proy-em-cancel></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="' + EM_ID + '_t">' +
              '<div class="vct-modal-header vct-form-header">' +
                '<div class="vct-form-header-accent"></div>' +
                '<div class="vct-form-header-icon"><span data-vct-icon="mail"></span></div>' +
                '<div class="vct-form-header-copy">' +
                  '<h3 class="vct-modal-title" id="' + EM_ID + '_t">Email</h3>' +
                  '<p class="vct-modal-subtitle">Dirección de correo de ' + esc(a.nombre) + '.</p>' +
                '</div>' +
                '<button type="button" class="vct-form-close" data-vct-proy-em-cancel aria-label="Cerrar">×</button>' +
              '</div>' +
              '<div class="vct-modal-body vct-form-body">' +
                '<div class="vct-validation-box" data-em-box style="display:none;"></div>' +
                '<div class="vct-form-grid">' +
                  '<div class="vct-field vct-col-12"><label class="vct-label">Email <span class="vct-required">*</span></label>' +
                  '<input type="text" class="vct-input" data-em="m" maxlength="100" placeholder="Email" autocomplete="off"></div>' +
                '</div>' +
              '</div>' +
              '<div class="vct-modal-footer vct-form-footer">' +
                '<button type="button" class="vct-btn vct-btn-secondary" data-vct-proy-em-cancel>Cancelar</button>' +
                '<button type="button" class="vct-btn vct-btn-primary" data-vct-proy-em-save><span data-vct-icon="save"></span><span>Guardar</span></button>' +
              '</div>' +
            '</div>';
        document.body.appendChild(o);
        icons(o);
        requestAnimationFrame(function () { o.classList.add("is-open"); });
        setTimeout(function () { var i = o.querySelector('[data-em="m"]'); if (i) i.focus(); }, 60);
    }
    function emSave() {
        var o = document.getElementById(EM_ID), a = anaInfo();
        if (!o || !a) return;
        var i = o.querySelector('[data-em="m"]'), v = i ? String(i.value || "").trim() : "";
        var box = o.querySelector("[data-em-box]");
        i.classList.remove("vct-field-error");
        box.style.display = "none"; box.innerHTML = "";
        var msg = !v ? "Email es obligatorio." : !MAIL_RE.test(v) ? "Email no tiene un formato válido." : "";
        if (msg) {
            box.innerHTML = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul><li>' + msg + '</li></ul>';
            box.style.display = "block";
            i.classList.add("vct-field-error"); i.focus();
            return;
        }
        var f = fieldEl("TEXTO27");
        var m = modal(), go = m ? m.querySelector('[data-vct-command="validate-next"]') : null;
        if (!f || !go) return;
        f.value = ["EMAIL", a.id, v].join("|");
        o.querySelector("[data-vct-proy-em-save]").disabled = true;
        emClose();
        go.click();
    }
    function ctClose() {
        var o = document.getElementById(CT_ID);
        if (!o) return;
        o.classList.remove("is-open");
        setTimeout(function () { if (o.parentNode) o.parentNode.removeChild(o); }, 200);
    }
    function ctCampo(k, label, col, req, max, area) {
        var ctl = area
            ? '<textarea class="vct-textarea" data-ct="' + k + '" maxlength="' + max + '" placeholder="' + label + '"></textarea>'
            : '<input type="text" class="vct-input" data-ct="' + k + '" maxlength="' + max + '" placeholder="' + label + '" autocomplete="off">';
        return '<div class="vct-field vct-col-' + col + '"><label class="vct-label">' + label +
            (req ? ' <span class="vct-required">*</span>' : '') + '</label>' + ctl + '</div>';
    }
    function ctOpen() {
        if (!ctCliente()) { toast("Primero elija el cliente.", "info"); var c = fieldEl("TEXTO19"); if (c) c.focus(); return; }
        var prev = document.getElementById(CT_ID);
        if (prev) prev.parentNode.removeChild(prev);
        var o = document.createElement("div");
        o.id = CT_ID;
        o.className = "vct-modal vct-form-shell vct-form-md vct-proy-ct-modal";
        o.innerHTML =
            '<div class="vct-modal-backdrop" data-vct-proy-ct-cancel></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="' + CT_ID + '_t">' +
              '<div class="vct-modal-header vct-form-header">' +
                '<div class="vct-form-header-accent"></div>' +
                '<div class="vct-form-header-icon"><span data-vct-icon="contact"></span></div>' +
                '<div class="vct-form-header-copy">' +
                  '<h3 class="vct-modal-title" id="' + CT_ID + '_t">Contacto</h3>' +
                  '<p class="vct-modal-subtitle">Persona de contacto del cliente.</p>' +
                '</div>' +
                '<button type="button" class="vct-form-close" data-vct-proy-ct-cancel aria-label="Cerrar">×</button>' +
              '</div>' +
              '<div class="vct-modal-body vct-form-body">' +
                '<div class="vct-validation-box" data-ct-box style="display:none;"></div>' +
                '<div class="vct-form-grid">' +
                  ctCampo("n", "Nombres", 6, true, 100) +
                  ctCampo("a", "Apellido", 6, true, 100) +
                  ctCampo("c", "Cargo", 12, false, 100) +
                  ctCampo("o", "Observaciones", 12, false, 1000, true) +
                '</div>' +
              '</div>' +
              '<div class="vct-modal-footer vct-form-footer">' +
                '<button type="button" class="vct-btn vct-btn-secondary" data-vct-proy-ct-cancel>Cancelar</button>' +
                '<button type="button" class="vct-btn vct-btn-primary" data-vct-proy-ct-save><span data-vct-icon="save"></span><span>Guardar</span></button>' +
              '</div>' +
            '</div>';
        document.body.appendChild(o);
        icons(o);
        requestAnimationFrame(function () { o.classList.add("is-open"); });
        setTimeout(function () { var i = o.querySelector('[data-ct="n"]'); if (i) i.focus(); }, 60);
    }
    function ctSave() {
        var o = document.getElementById(CT_ID);
        if (!o) return;
        var inp = function (k) { return o.querySelector('[data-ct="' + k + '"]'); };
        var v = function (k) { var i = inp(k); return i ? String(i.value || "").replace(/\|/g, "/").replace(/[\r\n]+/g, " ").trim() : ""; };
        var box = o.querySelector("[data-ct-box]"), msg = "", foco = "";
        o.querySelectorAll(".vct-field-error").forEach(function (x) { x.classList.remove("vct-field-error"); });
        box.style.display = "none"; box.innerHTML = "";
        /* validacion campo por campo, en orden */
        if (!v("n")) { msg = "Nombres es obligatorio."; foco = "n"; }
        else if (!v("a")) { msg = "Apellido es obligatorio."; foco = "a"; }
        if (msg) {
            box.innerHTML = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul><li>' + msg + '</li></ul>';
            box.style.display = "block";
            var fi = inp(foco); if (fi) { fi.classList.add("vct-field-error"); fi.focus(); }
            return;
        }
        var f = fieldEl("TEXTO27");
        var m = modal(), go = m ? m.querySelector('[data-vct-command="validate-next"]') : null;
        if (!f || !go) return;
        f.value = ["CONTACTO", v("n"), v("a"), v("c"), v("o")].join("|");
        o.querySelector("[data-vct-proy-ct-save]").disabled = true;
        ctClose();
        go.click();
    }
    /* volvio del servidor: "Contacto agregado ..." no es un error */
    function ctAviso() {
        /* ALTA_CONTACTO_V3: solo se grabo el contacto; se quita el cuadro "No se pudo guardar" y se avisa con un toast */
        var m = modal(), box = m ? m.querySelector("[data-vct-validation-box]") : null;
        var li = box ? box.querySelector("li") : null;
        var txt = String((li || box || {}).textContent || "").trim();
        if (!box || !/^(Contacto|Email) agregado/.test(txt)) return;
        box.style.display = "none";
        box.innerHTML = "";
        box.classList.remove("vct-validation-box-server");
        m.querySelectorAll(".vct-field-error").forEach(function (x) { x.classList.remove("vct-field-error"); });
        toast(/^Email/.test(txt) ? txt : txt.replace(/\s*Ya qued[oó] elegido.*$/, "") + " Ya quedó elegido en el proyecto.", "success");
    }
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        if (t.closest("[data-vct-proy-ct-add]")) { e.preventDefault(); ctOpen(); return; }
        if (t.closest("[data-vct-proy-em-add]")) { e.preventDefault(); emOpen(); return; }
        if (t.closest("[data-vct-proy-em-save]")) { e.preventDefault(); emSave(); return; }
        if (t.closest("[data-vct-proy-em-cancel]")) { e.preventDefault(); emClose(); return; }
        if (t.closest("[data-vct-proy-ct-save]")) { e.preventDefault(); ctSave(); return; }
        if (t.closest("[data-vct-proy-ct-cancel]")) { e.preventDefault(); ctClose(); }
    });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape" && document.getElementById(CT_ID)) { e.stopImmediatePropagation(); ctClose(); }
        if (e.key === "Escape" && document.getElementById(EM_ID)) { e.stopImmediatePropagation(); emClose(); } }, true);

    /* ALTA_CONFIRMA_V1: al crear, confirmacion con codigo + nombre, analista y su mail.
       Si el analista no tiene mail en VCT_EMAILS (data-email vacio) se pide debajo del
       formulario a quien enviar el mail de asignacion (viaja en TEXTO29). */
    var MAIL_RE = /^[^\s@;,]+@[^\s@;,]+\.[^\s@;,]+$/;
    function anaInfo() {
        var a = fieldEl("TEXTO20");
        var o = a && a.tagName === "SELECT" ? a.options[a.selectedIndex] : null;
        if (!o || !o.value) return null;
        return { id: o.value, nombre: String(o.textContent || "").trim(), mail: String(o.getAttribute("data-email") || "").trim() };
    }
    function mailBox() {
        var m = modal();
        if (!m) return null;
        var b = m.querySelector("[data-vct-proy-mail]");
        if (b) return b;
        var foot = m.querySelector(".vct-form-footer");
        if (!foot) return null;
        b = document.createElement("div");
        b.className = "vct-proy-mail";
        b.setAttribute("data-vct-proy-mail", "");
        b.hidden = true;
        b.innerHTML =
            '<div class="vct-proy-mail-msg"><span data-vct-icon="mail"></span><span data-vct-proy-mail-txt></span></div>' +
            '<div class="vct-field vct-proy-mail-field"><label class="vct-label">Enviar el mail de asignación a <span class="vct-required">*</span></label>' +
            '<input type="text" class="vct-input" data-vct-proy-mail-in maxlength="200" placeholder="Email del analista o de quien deba recibir la asignación" autocomplete="off"></div>';
        foot.parentNode.insertBefore(b, foot);
        icons(b);
        b.querySelector("[data-vct-proy-mail-in]").addEventListener("input", function () {
            var h = fieldEl("TEXTO29");
            if (h) h.value = this.value.trim();
            this.classList.remove("vct-field-error");
        });
        return b;
    }
    function mailPedido() { var a = anaInfo(); return !!(a && !a.mail && fieldEl("TEXTO29")); }
    function syncMail() {
        var b = mailBox(), h = fieldEl("TEXTO29"), a = anaInfo();
        if (!b) return;
        var pedir = mailPedido();
        b.hidden = !pedir;
        if (!pedir) { if (h) h.value = ""; b.querySelector("[data-vct-proy-mail-in]").value = ""; return; }
        b.querySelector("[data-vct-proy-mail-txt]").innerHTML =
            "El analista <b>" + esc(a.nombre) + "</b> no tiene email cargado. Indique a quién enviar el mail de asignación.";
        var i = b.querySelector("[data-vct-proy-mail-in]");
        if (h && h.value && !i.value) i.value = h.value;
    }
    function mailError() {
        if (!mailPedido()) return "";
        var i = mailBox() && mailBox().querySelector("[data-vct-proy-mail-in]"), v = i ? i.value.trim() : "";
        var msg = !v ? "Indique a quién enviar el mail de asignación (el analista no tiene email cargado)."
            : !MAIL_RE.test(v) ? "El email para el mail de asignación no tiene un formato válido." : "";
        if (msg && i) i.classList.add("vct-field-error");
        return msg;
    }

    var CF_ID = "vctProyConfirma", cfOk = false;
    function cfClose() {
        var o = document.getElementById(CF_ID);
        if (!o) return;
        o.classList.remove("is-open");
        setTimeout(function () { if (o.parentNode) o.parentNode.removeChild(o); }, 200);
    }
    function cfRow(lbl, val) { return '<div class="vct-proy-cf-row"><span>' + lbl + '</span><div>' + val + '</div></div>'; }
    function cfOpen() {
        var a = anaInfo(), cod = String(valueOf("TEXTO12") || "").trim(), nom = String(valueOf("TEXTO11") || "").trim();
        var mail = a ? (a.mail || String(valueOf("TEXTO29") || "").trim()) : "";
        var cs = fieldEl("TEXTO19"), co = cs && cs.tagName === "SELECT" ? cs.options[cs.selectedIndex] : null;
        var cli = co && co.value ? String(co.textContent || "").trim() : "";
        var prev = document.getElementById(CF_ID);
        if (prev) prev.parentNode.removeChild(prev);
        var o = document.createElement("div");
        o.id = CF_ID;
        o.className = "vct-modal vct-form-shell vct-form-md vct-proy-ct-modal vct-proy-cf";
        o.innerHTML =
            '<div class="vct-modal-backdrop" data-vct-proy-cf-cancel></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="' + CF_ID + '_t">' +
              '<div class="vct-modal-header vct-form-header">' +
                '<div class="vct-form-header-accent"></div>' +
                '<div class="vct-form-header-icon"><span data-vct-icon="folder"></span></div>' +
                '<div class="vct-form-header-copy">' +
                  '<h3 class="vct-modal-title" id="' + CF_ID + '_t">Crear proyecto</h3>' +
                  '<p class="vct-modal-subtitle">Revise los datos antes de confirmar.</p>' +
                '</div>' +
                '<button type="button" class="vct-form-close" data-vct-proy-cf-cancel aria-label="Cerrar">×</button>' +
              '</div>' +
              '<div class="vct-modal-body vct-form-body">' +
                cfRow("Cliente", cli ? '<b>' + esc(cli) + '</b>' : '<span class="vct-proy-cf-muted">-</span>') +
                cfRow("Proyecto", (cod ? '<span class="vct-proy-cf-code">' + esc(cod) + '</span> ' : '') + '<b>' + esc(nom) + '</b>') +
                cfRow("Analista asignado", a ? esc(a.nombre) : '<span class="vct-proy-cf-muted">Sin asignar</span>') +
                cfRow("Email del analista", !a ? '<span class="vct-proy-cf-muted">No se envía mail de asignación</span>'
                    : esc(mail) + (a.mail ? '' : ' <small class="vct-proy-cf-muted">(ingresado en el alta)</small>')) +
                (a ? '<p class="vct-proy-cf-note"><span data-vct-icon="mail"></span>Al crear se le env\u00eda el mail de asignaci\u00f3n y se genera su acci\u00f3n para organizar el lanzamiento.</p>' : '') +
              '</div>' +
              '<div class="vct-modal-footer vct-form-footer">' +
                '<button type="button" class="vct-btn vct-btn-secondary" data-vct-proy-cf-cancel>Cancelar</button>' +
                '<button type="button" class="vct-btn vct-btn-primary" data-vct-proy-cf-ok><span data-vct-icon="save"></span><span>Crear proyecto</span></button>' +
              '</div>' +
            '</div>';
        document.body.appendChild(o);
        icons(o);
        requestAnimationFrame(function () { o.classList.add("is-open"); });
        setTimeout(function () { var b = o.querySelector("[data-vct-proy-cf-ok]"); if (b) b.focus(); }, 60);
    }
    /* captura: corre antes que el validate-next de vct-main.js */
    window.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        if (t.closest("[data-vct-proy-cf-cancel]")) { e.preventDefault(); cfClose(); return; }
        if (t.closest("[data-vct-proy-cf-ok]")) {
            e.preventDefault();
            var m0 = modal(), go0 = m0 ? m0.querySelector('[data-vct-command="validate-next"]') : null;
            cfClose();
            if (go0) { cfOk = true; go0.click(); }
            return;
        }
        var go = t.closest('[data-vct-command="validate-next"]'), m = modal();
        if (!go || !m || !m.contains(go)) return;
        if (cfOk) { cfOk = false; return; }
        if (ctPendiente()) return;
        e.preventDefault();
        e.stopImmediatePropagation();
        if (window.VCT && VCT.Validation && !VCT.Validation.validate(m)) return;
        cfOpen();
    }, true);
    document.addEventListener("keydown", function (e) { if (e.key === "Escape" && document.getElementById(CF_ID)) { e.stopImmediatePropagation(); cfClose(); } }, true);

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
        ["TEXTO22", "TEXTO24", "TEXTO25"].forEach(function (f) {
            var i = fieldEl(f);
            if (i) i.dispatchEvent(new Event("change", { bubbles: true }));
        });
        var box = m.querySelector("[data-vct-validation-box]");
        if (box) { box.style.display = "none"; box.innerHTML = ""; }
        m.querySelectorAll('input[type="date"]').forEach(syncDateLabel);
        syncAnalista();
        syncContactos();
        adjInit();
        ctButton();
        var ct = fieldEl("TEXTO27");
        if (ct) ct.value = "";
        showView();
        var first = fieldEl("TEXTO19");
        if (!first || first.type === "hidden" || first.readOnly) first = fieldEl("TEXTO11");
        if (first) setTimeout(function () { first.focus(); }, 60);
    }

    /* Volver (encabezado) y Cancelar (pie) */
    document.addEventListener("click", function (e) {
        if (!e.target.closest || !e.target.closest("[data-vct-proy-alta-back]")) return;
        e.preventDefault();
        closeAlta();
    });

    /* Captura: desde el menu de la V360 de Cliente o el boton Nuevo de Proyectos. */
    document.addEventListener("click", function (e) {
        var opt = e.target.closest('[data-vct-menu-action="project-create"], [data-vct-pending-action="project-create"], [data-vct-proy-alta-open]');
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

    /* volvio del servidor con error: se muestra abierto con lo cargado */
    function reopenIfNeeded() {
        var v = view();
        if (!v || v.getAttribute("data-vct-proy-reabrir") !== "1" || v.dataset.vctReopened === "1") return;
        v.dataset.vctReopened = "1";
        if (window.VCT && VCT.DomForm && typeof VCT.DomForm.activateScope === "function") VCT.DomForm.activateScope(modal());
        adjInit();
        ctButton();
        var ct2 = fieldEl("TEXTO27");
        if (ct2) ct2.value = "";
        ctAviso();
        showView();
    }

    function boot() {
        hookValidation();
        enhance();
        if (view() && !view().classList.contains("is-open")) ownNames(false);
        reopenIfNeeded();
        showOk();
    }

    window.VCTProyectoAlta = { version: 3, open: openAlta, close: closeAlta };

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
    else boot();

    /* El formulario puede llegar despues de este script (OUTPARAM3 en la V360). */
    if (window.MutationObserver) {
        var pending = false;
        new MutationObserver(function () {
            if (pending) return;
            pending = true;
            setTimeout(function () {
                pending = false;
                var m = modal();
                if (m && (m.dataset.vctProyReady !== "1" || !m.querySelector(".vct-proy-services"))) enhance();
                var vv = view();
                if (vv && !vv.classList.contains("is-open") && vv.getAttribute("data-vct-proy-reabrir") !== "1") ownNames(false);
                reopenIfNeeded();
                showOk();
            }, 30);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }
})(window, document);
