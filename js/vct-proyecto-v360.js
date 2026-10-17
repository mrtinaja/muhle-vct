/* vct-proyecto-v360.js - v17 (parte logistico: capitulos con tarjetas + cronograma)
   v12 (mail al consultor al iniciar el proyecto)
   v11 (desplegables con VCT.FormSelect)
   v10 (selects y fechas de los modales del lanzamiento)
   v9 (lanzamiento: alta / edicion / eliminar; menu de 3 puntos con confirm)
   ============================================================================
   Vista 360 de Proyecto (dbo.VCT_MAIN_PROYECTO_V360).
   - Subpestanias de los grupos (Proyecto: Datos y servicios / Normas / Equipo).
   - Botones Gestionar / Ver todas: [data-vct-pv-goto] cambia de pestania.
   - Modal "Asignar consultor" ([data-vct-pv-open="asignar"]): elige consultor,
     rol, vencimiento y observaciones; guarda por VCT_BUFFER con el comando
     PV_ASIGNAR y vuelve a la misma V360 (dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR).
   Las pestanias principales las maneja VCT.Tabs (vct-main.js).
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctProyectoV360) return;
    window.__vctProyectoV360 = true;

    var SUB_KEY = "vctPvSub";

    function root() {
        var list = document.querySelectorAll("[data-vct-pv]");
        for (var i = list.length - 1; i >= 0; i--) if (list[i].offsetParent !== null) return list[i];
        return list.length ? list[list.length - 1] : null;
    }
    function modal() { var r = root(); return r ? r.querySelector('[data-vct-pv-modal="asignar"]') : null; }
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    function parseISO(v) {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(v || "");
        return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null;
    }

    /* ---------------- pestanias y subpestanias ---------------- */
    function activateTab(r, tab) {
        if (!r || !tab) return;
        if (window.VCT && VCT.Tabs && typeof VCT.Tabs.activate === "function") VCT.Tabs.activate(r, tab);
        var bar = r.querySelector(".vct-360-tabsbar");
        if (bar && bar.scrollIntoView) bar.scrollIntoView({ block: "start", behavior: "smooth" });
    }
    function showSub(panel, name) {
        if (!panel) return;
        var subs = panel.querySelectorAll("[data-vct-pv-subpanel]");
        if (!subs.length) return;
        var found = false;
        subs.forEach(function (s) { if (s.getAttribute("data-vct-pv-subpanel") === name) found = true; });
        if (!found) name = subs[0].getAttribute("data-vct-pv-subpanel");
        subs.forEach(function (s) { s.hidden = s.getAttribute("data-vct-pv-subpanel") !== name; });
        panel.querySelectorAll("[data-vct-pv-sub]").forEach(function (b) {
            b.classList.toggle("is-active", b.getAttribute("data-vct-pv-sub") === name);
        });
    }

    /* ---------------- modal asignar consultor ---------------- */
    function showError(m, list) {
        var box = m.querySelector("[data-vct-pv-error]");
        if (!box) return;
        if (!list || !list.length) { box.style.display = "none"; box.innerHTML = ""; return; }
        box.innerHTML = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul>' +
            list.map(function (x) { return "<li>" + x + "</li>"; }).join("") + "</ul>";
        box.style.display = "block";
        /* el aviso queda arriba del modal: llevarlo a la vista y avisar con toast */
        try { box.scrollIntoView({ block: "start", behavior: "smooth" }); } catch (e) { box.scrollIntoView(true); }
        if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") {
            var tmp = document.createElement("div"); tmp.innerHTML = list[0];
            VCT.Toast.show(tmp.textContent, "error");
        }
    }
    /* filas elegidas: tr.is-selected; el rol de cada una es su boton .vct-pv-role.is-on */
    function picked(m) {
        return Array.prototype.filter.call(m.querySelectorAll("tr[data-vct-pv-cons]"), function (tr) { return tr.classList.contains("is-selected"); });
    }
    function rowRol(tr) { return tr.querySelector(".vct-pv-role.is-on"); }
    function hayLider(m) {
        return picked(m).some(function (tr) { var o = rowRol(tr); return !!(o && o.getAttribute("data-lider") === "1"); });
    }
    function setRol(tr, btn) {
        tr.querySelectorAll(".vct-pv-role").forEach(function (b) { b.classList.toggle("is-on", b === btn); });
    }
    function rolDefault(tr) {
        var d = tr.querySelector(".vct-pv-role.is-default") || tr.querySelector('.vct-pv-role[data-lider="0"]');
        if (d) setRol(tr, d);
    }
    function syncSel(m) {
        var lider = hayLider(m);
        m.querySelectorAll("[data-vct-pv-vence-wrap], [data-vct-pv-gen-lider]").forEach(function (g) { g.style.display = lider ? "" : "none"; });
        /* seleccionados con su rol y su mail; si alguno no tiene mail, el email es obligatorio */
        var sel = m.querySelector("[data-vct-pv-sel]"), n = picked(m), faltan = 0;
        var esc = function (x) { return String(x || "").replace(/&/g, "&amp;").replace(/</g, "&lt;"); };
        if (sel) {
            sel.innerHTML = !n.length ? '<span class="vct-pv-sel-empty">Ning&uacute;n consultor seleccionado.</span>'
                : '<div class="vct-pv-sel-title">Se notifica a</div>' + n.map(function (tr) {
                    var nm = tr.querySelector(".vct-360-project-name"), o = rowRol(tr), mail = tr.getAttribute("data-email") || "";
                    if (!mail) faltan++;
                    return '<div class="vct-pv-sel-row"><b>' + esc(nm ? nm.textContent : "") + '</b>' +
                           '<span class="vct-pv-sel-rol">' + esc(o ? o.textContent : "") + '</span>' +
                           (mail ? '<span class="vct-pv-sel-mail">' + esc(mail) + '</span>'
                                 : '<span class="vct-pv-sel-mail is-missing">sin email cargado</span>') + '</div>';
                }).join("");
        }
        m.setAttribute("data-vct-pv-faltan", String(faltan));
        var lbl = m.querySelector("[data-vct-pv-email-lbl]"), help = m.querySelector("[data-vct-pv-email-help]");
        if (lbl) lbl.innerHTML = faltan ? 'Email para los consultores sin email <span class="vct-required">*</span>' : "Email adicional (CC)";
        if (help) help.innerHTML = faltan
            ? "Obligatorio: " + (faltan === 1 ? "un consultor seleccionado no tiene" : faltan + " consultores seleccionados no tienen") + " email cargado; el aviso se env&iacute;a a esta direcci&oacute;n."
            : "Opcional: va en copia del mail a los consultores.";
        syncFechas(m);
    }
    /* un solo lider: al elegir Lider en una fila, las otras con Lider vuelven a Consultor */
    function unLider(m, tr) {
        var o = rowRol(tr);
        if (!o || o.getAttribute("data-lider") !== "1") return;
        picked(m).forEach(function (x) {
            if (x === tr) return;
            var xo = rowRol(x);
            if (xo && xo.getAttribute("data-lider") === "1") rolDefault(x);
        });
    }
    function filtrar(m, q) {
        q = (q || "").toLowerCase().trim();
        m.querySelectorAll("tr[data-vct-pv-cons]").forEach(function (tr) {
            var t = tr.getAttribute("data-vct-search") || "";
            tr.style.display = !q || t.indexOf(q) >= 0 ? "" : "none";
        });
    }
    function syncFechas(m) {
        var inp = m.querySelector("[data-vct-pv-vence]");
        var base = parseISO(inp && inp.value);
        if (!base) return;
        m.querySelectorAll("[data-vct-pv-dias]").forEach(function (g) {
            var d = parseInt(g.getAttribute("data-vct-pv-dias"), 10);
            var b = g.querySelector("[data-vct-pv-gen-fecha]");
            if (!b || isNaN(d)) return;
            var f = new Date(base.getFullYear(), base.getMonth(), base.getDate() + d);
            b.textContent = pad(f.getDate()) + "/" + pad(f.getMonth() + 1);
        });
    }
    function openModal() {
        var m = modal();
        if (!m) return;
        m.querySelectorAll("tr[data-vct-pv-cons]").forEach(function (tr) { tr.classList.remove("is-selected"); rolDefault(tr); });
        ["[data-vct-pv-obs]", "[data-vct-pv-email]", "[data-vct-pv-buscar]"].forEach(function (q) { var x = m.querySelector(q); if (x) x.value = ""; });
        filtrar(m, "");
        showError(m, null);
        syncSel(m);
        m.classList.add("is-open");
        document.body.classList.add("vct-modal-open");
        var b = m.querySelector("[data-vct-pv-buscar]");
        if (b) setTimeout(function () { b.focus(); }, 60);
    }
    function closeModal() {
        document.querySelectorAll('[data-vct-pv-modal].is-open').forEach(function (m) { m.classList.remove("is-open"); });
        document.body.classList.remove("vct-modal-open");
    }
    function guardar(btn) {
        var m = btn.closest("[data-vct-pv-modal]");
        if (!m) return;
        var errs = [], filas = picked(m), lista = [], lideres = 0;
        filas.forEach(function (tr) {
            var o = rowRol(tr);
            if (!o) return;
            if (o.getAttribute("data-lider") === "1") lideres++;
            lista.push(tr.getAttribute("data-vct-pv-cons") + ":" + o.getAttribute("data-vct-pv-role"));
        });
        var vence = m.querySelector("[data-vct-pv-vence]");
        var obs = m.querySelector("[data-vct-pv-obs]");
        var mail = m.querySelector("[data-vct-pv-email]");
        var hoy = m.getAttribute("data-vct-pv-hoy") || "";
        if (!filas.length) errs.push("Consultor es obligatorio: marque al menos uno de la lista.");
        else if (lista.length !== filas.length) errs.push("Rol es obligatorio para cada consultor marcado.");
        if (lideres > 1) errs.push("Solo puede haber un consultor l&iacute;der.");
        if (lideres && vence && vence.value && hoy && vence.value < hoy) errs.push("Vence pr&oacute;xima acci&oacute;n no puede ser anterior a hoy.");
        var mv = mail ? mail.value.replace(/,/g, ";").trim() : "";
        if (filas.length && m.getAttribute("data-vct-pv-faltan") !== "0" && !mv)
            errs.push("Email es obligatorio: hay consultores seleccionados sin email cargado.");
        if (mv) mv.split(";").forEach(function (x) {
            x = x.trim();
            if (x && !/^[^\s@;]+@[^\s@;]+\.[^\s@;]+$/.test(x)) errs.push("Email adicional: &quot;" + x.replace(/</g, "&lt;") + "&quot; no es una direcci&oacute;n v&aacute;lida.");
        });
        var guid = m.getAttribute("data-vct-pv-guid") || "";
        if (!guid) errs.push("No se encontr&oacute; la pantalla de la Vista 360 (permiso PROYECTOS VIEW).");
        if (mail) mail.classList.toggle("is-invalid", !!(filas.length && m.getAttribute("data-vct-pv-faltan") !== "0" && !mv));
        if (errs.length) { showError(m, errs); return; }
        showError(m, null);
        if (!window.VCT || !VCT.Buffer || !VCT.Navigation) return;
        btn.disabled = true;
        if (VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab("equipo");
        var S = function (k, v) { return Promise.resolve(VCT.Buffer.store(k, v)); };
        S("TEXTO30", "PV_ASIGNAR")
            .then(function () { return S("TEXTO11", lista.join(";")); })
            .then(function () { return S("TEXTO12", lideres && vence ? vence.value : ""); })
            .then(function () { return S("TEXTO13", obs ? obs.value : ""); })
            .then(function () { return S("TEXTO14", mv); })
            .then(function () { return S("FLAG01", "1"); })
            .then(function () { closeModal(); VCT.Navigation.goto(btn, guid); })
            .catch(function () { btn.disabled = false; showError(m, ["No se pudo guardar. Intente nuevamente."]); });
    }

    /* ---------------- campanita de pendientes del proyecto ---------------- */
    function bellPanel(bell, open) {
        var list = bell ? [bell] : Array.prototype.slice.call(document.querySelectorAll("[data-vct-pv-bell]"));
        list.forEach(function (b) {
            var p = b.querySelector("[data-vct-pv-bell-panel]"), btn = b.querySelector("[data-vct-pv-bell-toggle]");
            if (!p) return;
            var o = typeof open === "boolean" ? open : p.hidden;
            p.hidden = !o;
            if (btn) btn.setAttribute("aria-expanded", o ? "true" : "false");
        });
    }

    /* ---------------- grabar por buffer y volver a la V360 ---------------- */
    function enviar(btn, cmd, id, campos, tab) {
        var r = btn.closest("[data-vct-pv]") || root();
        var guid = r ? r.getAttribute("data-vct-pv-guid") || "" : "";
        if (!guid || !window.VCT || !VCT.Buffer || !VCT.Navigation) return;
        if (btn.disabled) return;
        btn.disabled = true;
        if (VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab(tab || "lanzamiento");
        var S = function (k, v) { return Promise.resolve(VCT.Buffer.store(k, v)); };
        var p = S("TEXTO30", cmd).then(function () { return S("IDSELEC03", id || "0"); });
        Object.keys(campos || {}).forEach(function (k) { p = p.then(function () { return S(k, campos[k]); }); });
        p.then(function () { return S("FLAG01", "1"); })
         .then(function () { closeModal(); VCT.Navigation.goto(btn, guid); })
         .catch(function () { btn.disabled = false; });
    }

    /* ---------------- modales de alta / edicion del lanzamiento ---------------- */
    var lzId = "";
    function lzModal(btn, key) {
        var r = btn.closest("[data-vct-pv]") || root();
        return r ? r.querySelector('[data-vct-pv-modal="' + key + '"]') : null;
    }
    function setVal(el, v) {
        if (el.type === "checkbox") el.checked = v === "1";
        else el.value = v == null ? "" : v;
        try { el.dispatchEvent(new Event("change", { bubbles: true })); } catch (e) { }
        /* fecha: el datepicker no escucha cambios externos, se actualiza su texto */
        var dp = el.closest ? el.closest(".vct-datepicker") : null;
        var lbl = dp ? dp.querySelector(".vct-datepicker-value") : null;
        if (lbl) {
            var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(el.value || "");
            lbl.textContent = m ? m[3] + "/" + m[2] + "/" + m[1] : "Seleccionar fecha";
            lbl.classList.toggle("is-placeholder", !m);
        }
        /* desplegable: sincroniza el selector del formulario */
        if (el.tagName === "SELECT" && window.VCT && VCT.FormSelect && typeof VCT.FormSelect.sync === "function") {
            var w = el.parentNode ? el.parentNode.querySelector(".vct-form-select") : null;
            if (w) VCT.FormSelect.sync(el, w);
        }
    }
    /* accion del plan: subtipos del tipo elegido; resultado solo con estado final */
    function plTipif(m) {
        var fs = window.VCT && VCT.FormSelect;
        var t = m.querySelector("[data-vct-pv-tipo]"), s = m.querySelector("[data-vct-pv-sub-tipo]");
        if (t && s) {
            var tv = t.value;
            Array.prototype.forEach.call(s.options, function (o) {
                if (!o.value) return;
                var ok = !!tv && o.getAttribute("data-tipo") === tv;
                o.disabled = !ok; o.hidden = !ok;
            });
            var w = s.parentNode ? s.parentNode.querySelector(".vct-form-select") : null;
            var menu = w ? w.__vctPortalMenu : null;
            if (menu) menu.querySelectorAll(".vct-form-select-option").forEach(function (d) {
                var v = d.getAttribute("data-value");
                if (!v) return;
                var o = null;
                Array.prototype.forEach.call(s.options, function (x) { if (x.value === v) o = x; });
                var off = !!(o && o.disabled);
                if (off) d.style.setProperty("display", "none", "important"); else d.style.removeProperty("display");
                d.classList.toggle("is-disabled", off);
                d.setAttribute("aria-disabled", off ? "true" : "false");
            });
            var cur = s.options[s.selectedIndex];
            if (cur && cur.disabled) setVal(s, "");
            else if (w && fs && fs.sync) fs.sync(s, w);
        }
        var e = m.querySelector("[data-vct-pv-estado]"), r = m.querySelector("[data-vct-pv-resultado]");
        if (e && r) {
            var oe = e.options[e.selectedIndex];
            var fin = !!(oe && oe.getAttribute("data-final") === "1");
            r.disabled = !fin;
            if (fin) r.setAttribute("data-req", "Resultado");
            else { r.removeAttribute("data-req"); r.classList.remove("is-invalid"); if (r.value) setVal(r, ""); }
            var star = m.querySelector("[data-vct-pv-res-req]");
            if (star) star.hidden = !fin;
            var w2 = r.parentNode ? r.parentNode.querySelector(".vct-form-select") : null;
            if (w2 && fs && fs.sync) fs.sync(r, w2);
        }
    }
    function syncPreg(m) {
        var wrap = m.querySelector("[data-vct-pv-preg-wrap]");
        if (!wrap) return;
        var sel = m.querySelector('[data-vct-pv-f="item"]'), preg = m.querySelector('[data-vct-pv-f="preg"]');
        var nuevo = m.getAttribute("data-vct-pv-mode") === "new";
        if (nuevo) wrap.hidden = !!(sel && sel.value);
        else wrap.hidden = false;
        if (preg) preg.readOnly = !nuevo && m.getAttribute("data-vct-pv-item") !== "";
    }
    function syncMail(m) {
        var chk = m.querySelector('[data-vct-pv-f="enviar"]');
        if (!chk) return;
        var on = chk.checked && m.getAttribute("data-vct-pv-mode") === "new";
        m.querySelectorAll("[data-vct-pv-mail]").forEach(function (x) { x.hidden = !on; });
    }
    function openLz(btn, key, edit) {
        var m = lzModal(btn, key);
        if (!m) return;
        lzId = btn.getAttribute("data-id") || "";
        m.setAttribute("data-vct-pv-mode", edit ? "edit" : "new");
        m.setAttribute("data-vct-pv-item", edit ? (btn.getAttribute("data-f-item") || "") : "");
        var t = m.querySelector("[data-vct-pv-mtitle]");
        if (t) t.innerHTML = m.getAttribute(edit ? "data-vct-pv-tedit" : "data-vct-pv-tnew") || t.innerHTML;
        m.querySelectorAll("[data-vct-pv-only-new]").forEach(function (x) { x.hidden = !!edit; });
        /* desplegables: un solo selector, el estandar de los formularios (VCT.FormSelect) */
        if (window.VCT && VCT.FormSelect && typeof VCT.FormSelect.build === "function")
            m.querySelectorAll("select[data-vct-pv-f]").forEach(function (sel) { try { VCT.FormSelect.build(sel); } catch (e) { } });
        m.querySelectorAll("[data-vct-pv-f]").forEach(function (f) {
            var k = f.getAttribute("data-vct-pv-f");
            if (edit) setVal(f, btn.getAttribute("data-f-" + k) || "");
            else if (btn.hasAttribute("data-f-" + k)) setVal(f, btn.getAttribute("data-f-" + k) || "");
            else if (f.tagName === "SELECT" && !f.hasAttribute("data-vct-pv-def")) setVal(f, f.options.length ? f.options[0].value : "");
            else setVal(f, f.getAttribute("data-vct-pv-def") || "");
            f.classList.remove("is-invalid");
        });
        syncPreg(m);
        syncMail(m);
        plTipif(m);
        /* item del plan: un sub-item no tiene fechas propias */
        var padre = m.querySelector('[data-vct-pv-f="padre"]');
        if (padre) {
            var esSub = !!padre.value;
            m.querySelectorAll("[data-vct-pv-only-top]").forEach(function (x) { x.hidden = esSub; });
            m.querySelectorAll("[data-vct-pv-only-sub]").forEach(function (x) { x.hidden = !esSub; });
            var tt = m.querySelector("[data-vct-pv-mtitle]");
            if (tt && esSub) tt.innerHTML = edit ? "Editar sub&iacute;tem" : "Agregar sub&iacute;tem";
        }
        showError(m, null);
        var sv = m.querySelector("[data-vct-pv-save]");
        if (sv) sv.disabled = false;
        m.classList.add("is-open");
        document.body.classList.add("vct-modal-open");
    }
    function guardarLz(btn) {
        var m = btn.closest("[data-vct-pv-modal]");
        if (!m) return;
        var errs = [], campos = {};
        m.querySelectorAll("[data-vct-pv-f]").forEach(function (f) {
            var v = f.type === "checkbox" ? (f.checked ? "1" : "0") : String(f.value || "").trim();
            var req = f.getAttribute("data-req");
            var bad = !!(req && !v);
            f.classList.toggle("is-invalid", bad);
            if (bad) errs.push(req + " es obligatorio.");
            var b = f.getAttribute("data-vct-pv-buf");
            if (b) campos[b] = v;
        });
        if (m.getAttribute("data-vct-pv-modal") === "in" && m.getAttribute("data-vct-pv-mode") === "new" && campos.TEXTO13 === "1") {
            var para = m.querySelector('[data-vct-pv-f="para"]');
            if (!campos.TEXTO14) { errs.push("Para es obligatorio para enviar el mail al consultor."); if (para) para.classList.add("is-invalid"); }
            (campos.TEXTO14 + ";" + (campos.TEXTO15 || "")).replace(/,/g, ";").split(";").forEach(function (x) {
                x = x.trim();
                if (x && !/^[^\s@;]+@[^\s@;]+\.[^\s@;]+$/.test(x)) errs.push("Email no v\u00e1lido: " + x.replace(/</g, "&lt;"));
            });
        }
        if (m.getAttribute("data-vct-pv-modal") === "in" && campos.TEXTO13 !== "1") { campos.TEXTO14 = ""; campos.TEXTO15 = ""; }
        if (m.getAttribute("data-vct-pv-modal") === "de" && m.getAttribute("data-vct-pv-mode") === "new" && !campos.TEXTO11 && !campos.TEXTO12)
            errs.push("Dato es obligatorio: elija uno de la minuta o escr\u00edbalo.");
        if (errs.length) { showError(m, errs); return; }
        showError(m, null);
        var cmdM = m.getAttribute("data-vct-pv-cmd") || "";
        enviar(btn, cmdM, lzId, campos, /^PV_PL_/.test(cmdM) ? "plan" : "lanzamiento");
    }

    /* ---------------- eliminar / confirmar (alerta nativa, como en las otras grillas) ---------------- */
    function confirmar(btn) {
        var cmd = btn.getAttribute("data-vct-pv-confirm") || "";
        var msg = /_BORRAR$/.test(cmd) ? "\u00bfEliminar este registro?" : (btn.getAttribute("data-msg") || "\u00bfConfirma?");
        if (/_BORRAR$/.test(cmd) && btn.getAttribute("data-nombre")) msg += "\n\n" + btn.getAttribute("data-nombre");
        if (cmd === "PV_IN_BORRAR") msg = "\u00bfDeshacer el inicio del proyecto?\n" + (btn.getAttribute("data-msg") || "");
        if (!window.confirm(msg)) return;
        var extra = {};
        if (btn.hasAttribute("data-t11")) extra.TEXTO11 = btn.getAttribute("data-t11");
        enviar(btn, cmd, btn.getAttribute("data-id") || "0", extra, /^PV_PL_/.test(cmd) ? "plan" : "lanzamiento");
    }
    /* calendario dentro de un modal: se muestra completo (no lo recorta el scroll del cuerpo del modal) */
    function dpPlace(wrap) {
        var menu = wrap ? wrap.querySelector(".vct-datepicker-menu") : null;
        var trg = wrap ? wrap.querySelector(".vct-datepicker-trigger") : null;
        var dlg = wrap ? wrap.closest(".vct-modal-dialog") : null;
        if (!menu || !trg || !dlg) return;
        if (!wrap.classList.contains("is-open")) { menu.removeAttribute("style"); return; }
        menu.style.position = "fixed";
        menu.style.transform = "none";
        menu.style.transition = "opacity .14s ease";
        menu.style.bottom = "auto";
        menu.style.right = "auto";
        menu.style.zIndex = "13000";
        menu.style.top = "0px"; menu.style.left = "0px";
        var r = trg.getBoundingClientRect(), d = dlg.getBoundingClientRect();
        var w = menu.offsetWidth, h = menu.offsetHeight, gap = 5;
        var left = Math.max(d.left + 8, Math.min(r.left, d.right - w - 8));
        var top = r.bottom + gap;
        if (top + h > d.bottom - 8 && r.top - gap - h >= d.top + 8) top = r.top - gap - h;
        else if (top + h > window.innerHeight - 8) top = Math.max(8, window.innerHeight - 8 - h);
        /* corrige si el modal tiene transform (el fixed se mide desde el modal) */
        var m0 = menu.getBoundingClientRect();
        menu.style.left = Math.round(left - m0.left) + "px";
        menu.style.top = Math.round(top - m0.top) + "px";
    }
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target.closest(".vct-datepicker-trigger") : null;
        if (!t || !t.closest("[data-vct-pv-modal]")) return;
        var wrap = t.closest(".vct-datepicker");
        setTimeout(function () { dpPlace(wrap); }, 0);
    });
    document.addEventListener("scroll", function (e) {
        var b = e.target && e.target.closest ? e.target.closest("[data-vct-pv-modal]") : null;
        if (!b) return;
        b.querySelectorAll(".vct-datepicker.is-open").forEach(dpPlace);
    }, true);
    function quitarConsultor(btn) {
        if (!window.confirm("\u00bfEliminar este registro?")) return;
        enviar(btn, "PV_EQ_BAJA", btn.getAttribute("data-vct-pv-baja") || "", {}, "equipo");
    }

    /* ---------------- parte logistico: capitulos, tarjetas, cronograma ---------------- */
    function plChap(ch, open) {
        if (!ch) return;
        ch.classList.toggle("is-open", typeof open === "boolean" ? open : !ch.classList.contains("is-open"));
        plAllLabel(ch.closest("[data-pl-box]"));
    }
    /* capitulos abiertos: se recuerdan al volver despues de grabar (por proyecto) */
    function plKey(box) { var m = box ? box.closest("[data-vct-pv-proyecto]") : null; return "vct.pv.plan.open." + (m ? m.getAttribute("data-vct-pv-proyecto") : ""); }
    function plSave(box) {
        if (!box) return;
        var a = [];
        box.querySelectorAll("[data-pl-chap].is-open").forEach(function (c) { a.push(c.getAttribute("data-pl-chap")); });
        try { window.sessionStorage.setItem(plKey(box), a.join(",")); } catch (e) { }
    }
    function plAllLabel(box) {
        if (!box) return;
        plSave(box);
        var b = box.querySelector("[data-pl-chap-all]");
        if (!b) return;
        var cs = box.querySelectorAll("[data-pl-chap]:not([hidden])"), todos = cs.length > 0;
        cs.forEach(function (c) { if (!c.classList.contains("is-open")) todos = false; });
        var sp = b.querySelectorAll("span");
        if (sp.length) sp[sp.length - 1].textContent = todos ? "Contraer todo" : "Expandir todo";
        b.setAttribute("data-pl-open", todos ? "1" : "0");
    }
    function plView(box, v) {
        if (!box) return;
        box.querySelectorAll("[data-pl-view]").forEach(function (b) { b.classList.toggle("is-on", b.getAttribute("data-pl-view") === v); });
        box.querySelectorAll("[data-pl-pane]").forEach(function (p) { p.hidden = p.getAttribute("data-pl-pane") !== v; });
        box.classList.toggle("is-gantt", v === "gantt");
        try { window.localStorage.setItem("vct.pv.plan.view", v); } catch (e) { }
    }
    function plFiltrar(box) {
        if (!box) return;
        var q = ((box.querySelector("[data-pl-buscar]") || {}).value || "").toLowerCase().trim();
        var e = (box.querySelector("[data-pl-estado]") || {}).value || "";
        var ok = function (el) { return (!q || (el.getAttribute("data-pl-search") || "").indexOf(q) >= 0) && (!e || el.getAttribute("data-pl-est") === e); };
        var hay = 0;
        box.querySelectorAll("[data-pl-chap]").forEach(function (ch) {
            var n = 0;
            ch.querySelectorAll("[data-pl-card]").forEach(function (c) { var v = ok(c); c.hidden = !v; if (v) n++; });
            ch.hidden = n === 0;
            if (n > 0 && (q || e)) ch.classList.add("is-open");
            hay += n;
        });
        var nr = box.querySelector("[data-pl-nores]");
        if (nr) nr.hidden = hay > 0 || !box.querySelector("[data-pl-chap]");
        var caps = {};
        box.querySelectorAll("[data-pl-grow]").forEach(function (r) {
            var v = ok(r); r.hidden = !v;
            if (v) caps[r.getAttribute("data-pl-cap")] = 1;
            box.querySelectorAll('[data-pl-gparent="' + r.getAttribute("data-pl-grow") + '"]').forEach(function (x) { x.hidden = !v; });
        });
        box.querySelectorAll("[data-pl-gchap]").forEach(function (r) { r.hidden = !caps[r.getAttribute("data-pl-gchap")]; });
        plAllLabel(box);
    }
    function plInit() {
        document.querySelectorAll("[data-pl-box]").forEach(function (box) {
            if (box.__plInit) return;
            box.__plInit = true;
            var v = "cards";
            try { v = window.localStorage.getItem("vct.pv.plan.view") || "cards"; } catch (e) { }
            plView(box, v === "gantt" ? "gantt" : "cards");
            var g = null;
            try { g = window.sessionStorage.getItem(plKey(box)); } catch (e) { }
            if (g !== null && g !== "") {
                var abiertos = "," + g + ",";
                box.querySelectorAll("[data-pl-chap]").forEach(function (c) { c.classList.toggle("is-open", abiertos.indexOf("," + c.getAttribute("data-pl-chap") + ",") >= 0); });
            }
            plAllLabel(box);
        });
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", plInit); else plInit();
    setTimeout(plInit, 400);

    /* ---------------- eventos ---------------- */
    document.addEventListener("click", function (e) {
        var t = e.target;
        if (!t || !t.closest) return;

        /* campanita del proyecto: abre / cierra; Gestionar cierra el panel y sigue */
        var bt = t.closest("[data-vct-pv-bell-toggle]");
        if (bt) { e.preventDefault(); bellPanel(bt.closest("[data-vct-pv-bell]")); return; }
        if (t.closest("[data-vct-pv-bell-go]")) bellPanel(null, false);
        else if (!t.closest("[data-vct-pv-bell-panel]")) bellPanel(null, false);

        var plv = t.closest("[data-pl-view]");
        if (plv) { e.preventDefault(); plView(plv.closest("[data-pl-box]"), plv.getAttribute("data-pl-view")); return; }
        var pla = t.closest("[data-pl-chap-all]");
        if (pla) {
            e.preventDefault();
            var bx = pla.closest("[data-pl-box]"), abrir = pla.getAttribute("data-pl-open") !== "1";
            if (bx) bx.querySelectorAll("[data-pl-chap]:not([hidden])").forEach(function (c) { c.classList.toggle("is-open", abrir); });
            plAllLabel(bx);
            return;
        }
        var plc = t.closest("[data-pl-chap-toggle]");
        if (plc && !t.closest("button,a,[data-vctdg-rowmenu]")) { e.preventDefault(); plChap(plc.closest("[data-pl-chap]")); return; }

        /* quitar consultor del equipo; lanzamiento: alta, edicion, eliminar */
        var bj = t.closest("[data-vct-pv-baja]");
        if (bj) { e.preventDefault(); quitarConsultor(bj); return; }
        var cf = t.closest("[data-vct-pv-confirm]");
        if (cf && !cf.disabled) { e.preventDefault(); confirmar(cf); return; }
        var nw = t.closest("[data-vct-pv-new]");
        if (nw && !nw.disabled) { e.preventDefault(); openLz(nw, nw.getAttribute("data-vct-pv-new"), false); return; }
        var ed = t.closest("[data-vct-pv-edit]");
        if (ed) { e.preventDefault(); openLz(ed, ed.getAttribute("data-vct-pv-edit"), true); return; }
        var sv = t.closest("[data-vct-pv-save]");
        if (sv && !sv.disabled) { e.preventDefault(); guardarLz(sv); return; }

        var pronto = t.closest("[data-vct-pv-pronto]");
        if (pronto) {
            e.preventDefault();
            var msg = pronto.getAttribute("data-vct-pv-pronto") + ": se habilita en el pr\u00f3ximo paso del workflow.";
            if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") VCT.Toast.show(msg, "info");
            return;
        }

        var open = t.closest('[data-vct-pv-open="asignar"]');
        if (open) { e.preventDefault(); openModal(); return; }

        var go = t.closest("[data-vct-pv-goto]");
        if (go) { e.preventDefault(); activateTab(go.closest("[data-vct-pv]") || root(), go.getAttribute("data-vct-pv-goto")); return; }

        var sub = t.closest("[data-vct-pv-sub]");
        if (sub) {
            e.preventDefault();
            showSub(sub.closest("[data-vct-panel]"), sub.getAttribute("data-vct-pv-sub"));
            try { sessionStorage.setItem(SUB_KEY, sub.getAttribute("data-vct-pv-sub")); } catch (e2) { }
            return;
        }

        if (t.closest("[data-vct-pv-close]") && t.closest("[data-vct-pv-modal]")) { e.preventDefault(); closeModal(); return; }

        var g = t.closest("[data-vct-pv-asignar]");
        if (g && !g.disabled) { e.preventDefault(); guardar(g); return; }

        var rb = t.closest(".vct-pv-role");
        if (rb && rb.closest("tr[data-vct-pv-cons]")) {
            e.preventDefault();
            var rtr = rb.closest("tr"), rm = rtr.closest("[data-vct-pv-modal]");
            rtr.classList.add("is-selected");          /* elegir un rol marca la fila */
            setRol(rtr, rb);
            unLider(rm, rtr);
            syncSel(rm);
            return;
        }
        var tr = t.closest("tr[data-vct-pv-cons]");
        if (tr) {
            tr.classList.toggle("is-selected");
            if (!tr.classList.contains("is-selected")) rolDefault(tr);
            syncSel(tr.closest("[data-vct-pv-modal]"));
        }
    });
    document.addEventListener("change", function (e) {
        if (e.target && e.target.matches && e.target.matches("[data-pl-estado]")) { plFiltrar(e.target.closest(".vct-pl-box")); return; }
        var m = e.target && e.target.closest ? e.target.closest("[data-vct-pv-modal]") : null;
        if (!m) return;
        if (e.target.matches("[data-vct-pv-vence]")) syncFechas(m);
        if (e.target.matches('[data-vct-pv-f="item"]')) syncPreg(m);
        if (e.target.matches('[data-vct-pv-f="enviar"]')) syncMail(m);
        if (e.target.matches("[data-vct-pv-tipo],[data-vct-pv-estado]")) plTipif(m);
    });
    document.addEventListener("input", function (e) {
        if (e.target && e.target.matches && e.target.matches("[data-pl-buscar]")) { plFiltrar(e.target.closest(".vct-pl-box")); return; }
        if (!e.target || !e.target.matches || !e.target.matches("[data-vct-pv-buscar]")) return;
        filtrar(e.target.closest("[data-vct-pv-modal]"), e.target.value);
    });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") { closeModal(); bellPanel(null, false); } });

    /* ---------------- init (SPA: la pantalla se inyecta sin recargar) ---------------- */
    function init(r) {
        if (!r || r.getAttribute("data-vct-pv-ready") === "1") return;
        r.setAttribute("data-vct-pv-ready", "1");
        var sub = "";
        try { sub = sessionStorage.getItem(SUB_KEY) || ""; sessionStorage.removeItem(SUB_KEY); } catch (e) { }
        r.querySelectorAll("[data-vct-panel]").forEach(function (p) { showSub(p, sub); });
        var volver = r.getAttribute("data-vct-pv-volver");
        if (volver) {
            var parts = volver.split(":");
            setTimeout(function () {
                activateTab(r, parts[0]);
                if (parts[1]) showSub(r.querySelector('[data-vct-panel="' + parts[0] + '"]'), parts[1]);
            }, 60);
        }
        var al = r.querySelector("[data-vct-pv-alert].is-ok");
        if (al) setTimeout(function () { al.classList.add("is-hiding"); setTimeout(function () { if (al.parentNode) al.parentNode.removeChild(al); }, 400); }, 9000);
    }
    function scan() { document.querySelectorAll("[data-vct-pv]").forEach(init); }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", scan); else scan();
    if (window.MutationObserver) {
        var pend = false;
        new MutationObserver(function () {
            if (pend) return;
            pend = true;
            setTimeout(function () { pend = false; scan(); }, 40);
        }).observe(document.documentElement, { childList: true, subtree: true });
    }

    window.VCTProyectoV360 = { version: 1, open: openModal, close: closeModal };
})(window, document);

/* v7: quitar la marca roja del email al escribir */
document.addEventListener("input", function (e) {
    var t = e.target;
    if (t && t.matches && t.matches("[data-vct-pv-email].is-invalid") && t.value.trim()) t.classList.remove("is-invalid");
});
