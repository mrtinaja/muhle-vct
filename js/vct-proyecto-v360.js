/* vct-proyecto-v360.js - v32 PV_AGENDA_V1 (permiso del plan, calendario pendiente / confirmada, modal del boceto)
   v31 PV_AGENDA_V1 (pestania Agenda: lista por servicio / calendario, modal Nueva visita)
   v29 PV_ASIG_V2 (asignar: lider al primero, + email del consultor, CC, confirmacion)
   v22 (plan estrategico en arbol con detalle 50/50; responsable otro)
   v21 (paginado de servicios > 10; pestania Plan de auditoria / capacitacion)
   v20 (servicios en grilla agrupada; pestania del plan deshabilitada hasta Ver plan / Gestionar)
   v19 (encabezado 3 filas, resumen por etapas, editar proyecto, servicios)
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
        if (tab === "plan") { var ptb = planTab(r); if (ptb && ptb.classList.contains("is-off")) { var st = planStored(r); planOpen(r, st.t, st.id, st.nom, false, st.lugar); } }
        if (window.VCT && VCT.Tabs && typeof VCT.Tabs.activate === "function") VCT.Tabs.activate(r, tab);
        var bar = r.querySelector(".vct-360-tabsbar");
        if (bar && bar.scrollIntoView) bar.scrollIntoView({ block: "start", behavior: "smooth" });
    }
    /* ---------------- pestania del plan (PV_PLAN_TAB_V1) ----------------
       Arranca deshabilitada. Se habilita con Ver plan (Servicios) o Gestionar (campanita / Acciones)
       y toma el nombre del plan: Plan estrategico (consultoria), Plan de auditoria / capacitacion · instancia. */
    var PLAN_SEL = "vct.pv.plan.sel.";
    function planTab(r) { return r ? r.querySelector("[data-vct-pv-plantab]") : null; }
    function planStored(r) {
        var d = null;
        try { d = JSON.parse(sessionStorage.getItem(PLAN_SEL + (r.getAttribute("data-vct-pv-proyecto") || "")) || "null"); } catch (e) { d = null; }
        return d && d.t ? d : { t: "co", id: "", nom: "", lugar: "" };
    }
    function planOpen(r, t, id, nom, go, lugar) {
        r = r || root();
        var tab = planTab(r);
        if (!tab) return;
        t = t || "co";
        /* pestania: siempre el tipo de plan; titulo del panel: tipo · nombre · lugar */
        var tipo = t === "au" ? "Plan de auditor\u00eda" : t === "ca" ? "Plan de capacitaci\u00f3n" : "Plan estrat\u00e9gico";
        /* PL_TITULO_V1: tipo de plan · codigo del proyecto · nombre del servicio · lugar */
        var cod = r.getAttribute("data-vct-pv-cod") || "";
        var lbl = t === "co" ? tipo : tipo + (cod ? " \u00b7 " + cod : "") + (nom ? " \u00b7 " + nom : "") + (lugar ? " \u00b7 " + lugar : "");
        tab.classList.remove("is-off");
        tab.removeAttribute("aria-disabled");
        tab.title = lbl;
        var l = tab.querySelector("[data-vct-pv-plantab-lbl]");
        if (l) l.textContent = tipo;
        var c = tab.querySelector("[data-vct-pv-plantab-cnt]");
        if (c) c.style.display = t === "co" ? "" : "none";
        var p = r.querySelector('[data-vct-panel="plan"]');
        if (p) {
            var co = p.querySelector('[data-vct-pv-planpane="co"]'), ot = p.querySelector('[data-vct-pv-planpane="otro"]');
            if (co) co.hidden = t !== "co";
            if (ot) {
                ot.hidden = t === "co";
                var ti = ot.querySelector("[data-vct-pv-planpane-tit]"), ms = ot.querySelector("[data-vct-pv-planpane-msg]");
                if (ti) ti.textContent = lbl;
                if (ms) ms.textContent = "El " + tipo.toLowerCase() + (nom ? " de \u00ab" + nom + "\u00bb" : "") + " todav\u00eda no est\u00e1 definido. Se arma cuando se definan los planes base.";
            }
        }
        try { sessionStorage.setItem(PLAN_SEL + (r.getAttribute("data-vct-pv-proyecto") || ""), JSON.stringify({ t: t, id: id || "", nom: nom || "", lugar: lugar || "" })); } catch (e) { }
        if (go) activateTab(r, "plan");
    }
    /* al volver de un guardado del plan la pestania queda activa: se rehabilita con el plan elegido */
    function planRestore(r) {
        if (!r) return;
        var tab = planTab(r);
        if (!tab || !tab.classList.contains("is-off")) return;
        if (r.getAttribute("data-vct-tabs-active") !== "plan" && !tab.classList.contains("is-active")) return;
        var st = planStored(r);
        planOpen(r, st.t, st.id, st.nom, false, st.lugar);
    }
    /* pestania deshabilitada: no navega (se intercepta antes que VCT.Tabs) */
    document.addEventListener("click", function (e) {
        var off = e.target && e.target.closest ? e.target.closest("[data-vct-tab].is-off") : null;
        if (!off) return;
        e.preventDefault();
        e.stopPropagation();
        if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function")
            VCT.Toast.show("Eleg\u00ed el servicio en la pesta\u00f1a Servicios: \u22ee \u2192 Ver plan.", "info");
    }, true);

    /* ---------------- servicios: grupos y busqueda (PV_SV_GRILLA_V1) ---------------- */
    /* hasta 10 instancias por grupo se ven todas; con mas de 10 (auditorias / capacitaciones), paginado de 10 */
    var SV_PAG = 10;
    var SV_IC = {
        first: '<path d="m11 17-5-5 5-5M18 17l-5-5 5-5"></path>', prev: '<path d="m15 18-6-6 6-6"></path>',
        next: '<path d="m9 18 6-6-6-6"></path>', last: '<path d="m6 17 5-5-5-5M13 17l5-5-5-5"></path>'
    };
    function svIco(k) { return '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">' + SV_IC[k] + "</svg>"; }
    function svPager(page, pages) {
        function b(tg, ic, lb, dis, act) {
            return '<button type="button" class="vctdg-page' + (act ? " is-active" : "") + '" data-vct-pv-svpage="' + tg + '" aria-label="' + lb + '"' + (dis ? " disabled" : "") + (act ? ' aria-current="page"' : "") + ">" + ic + "</button>";
        }
        var st = Math.max(1, page - 2), en = Math.min(pages, st + 4);
        st = Math.max(1, en - 4);
        var h = b(1, svIco("first"), "Primera p\u00e1gina", page === 1) + b(page - 1, svIco("prev"), "P\u00e1gina anterior", page === 1);
        for (var x = st; x <= en; x++) h += b(x, String(x), "P\u00e1gina " + x, false, x === page);
        return h + b(page + 1, svIco("next"), "P\u00e1gina siguiente", page === pages) + b(pages, svIco("last"), "\u00daltima p\u00e1gina", page === pages);
    }
    function svApply(box) {
        if (!box) return;
        var inp = box.querySelector("[data-vct-pv-svbuscar]"), q = ((inp && inp.value) || "").trim().toLowerCase(), tot = 0;
        box.querySelectorAll("tr[data-vct-pv-svg]").forEach(function (g) {
            var k = g.getAttribute("data-vct-pv-svg"), abierto = g.classList.contains("is-open") || !!q, ok = [];
            box.querySelectorAll('tr[data-vct-pv-svrow="' + k + '"]').forEach(function (rw) {
                if (!q || (rw.getAttribute("data-q") || "").indexOf(q) >= 0) ok.push(rw);
                rw.hidden = true;
            });
            var pg = box.querySelector('tr[data-vct-pv-svpg="' + k + '"]'), pages = Math.max(1, Math.ceil(ok.length / SV_PAG));
            var page = Math.min(Math.max(parseInt(g.getAttribute("data-page") || "1", 10) || 1, 1), pages);
            g.setAttribute("data-page", String(page));
            var conPag = !!pg && ok.length > SV_PAG, desde = conPag ? (page - 1) * SV_PAG : 0, hasta = conPag ? Math.min(ok.length, desde + SV_PAG) : ok.length;
            if (abierto) for (var i = desde; i < hasta; i++) ok[i].hidden = false;
            if (pg) {
                pg.hidden = !abierto || !conPag;
                if (conPag) {
                    var inf = pg.querySelector("[data-vct-pv-svinfo]"), nav = pg.querySelector(".vctdg-pager");
                    if (inf) inf.textContent = "Mostrando " + (desde + 1) + " a " + hasta + " de " + ok.length + " " + (pg.getAttribute("data-unit") || "registro(s)");
                    if (nav) nav.innerHTML = svPager(page, pages);
                }
            }
            g.hidden = !!q && ok.length === 0;
            tot += ok.length;
        });
        var nr = box.querySelector("[data-vct-pv-svnores]");
        if (nr) nr.hidden = tot > 0;
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
    /* PV_ASIG_V2: el primero que se marca es lider (si el proyecto no tiene); el resto solo consultor */
    function rolAlMarcar(m, tr) {
        var l = tr.querySelector('.vct-pv-role[data-lider="1"]');
        if (l && !hayLider(m)) setRol(tr, l); else rolDefault(tr);
    }
    function lockLider(m) {
        var lider = hayLider(m);
        m.querySelectorAll("tr[data-vct-pv-cons]").forEach(function (tr) {
            var o = rowRol(tr), esLider = tr.classList.contains("is-selected") && o && o.getAttribute("data-lider") === "1";
            tr.querySelectorAll('.vct-pv-role[data-lider="1"]').forEach(function (b) {
                var off = lider && !esLider;
                b.classList.toggle("is-locked", off);
                b.setAttribute("aria-disabled", off ? "true" : "false");
                b.title = off ? "Ya hay un consultor l\u00edder" : "";
            });
        });
    }
    function consMail(tr) { return tr.getAttribute("data-email") || tr.getAttribute("data-email-new") || ""; }
    var MAIL_RE = /^[^\s@;,]+@[^\s@;,]+\.[^\s@;,]+$/;
    function escH(x) { return String(x == null ? "" : x).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }
    function icons(sc) { if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(sc); }
    function ovClose(id) {
        var o = document.getElementById(id);
        if (!o) return;
        o.classList.remove("is-open");
        setTimeout(function () { if (o.parentNode) o.parentNode.removeChild(o); }, 200);
    }
    function ovOpen(id, icon, tit, sub, body, okAttr, okTxt, cancelAttr) {
        var prev = document.getElementById(id);
        if (prev) prev.parentNode.removeChild(prev);
        var o = document.createElement("div");
        o.id = id;
        o.className = "vct-modal vct-form-shell vct-form-md vct-pv-ov2";
        o.innerHTML =
            '<div class="vct-modal-backdrop" ' + cancelAttr + '></div>' +
            '<div class="vct-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="' + id + '_t">' +
              '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div>' +
                '<div class="vct-form-header-icon"><span data-vct-icon="' + icon + '"></span></div>' +
                '<div class="vct-form-header-copy"><h3 class="vct-modal-title" id="' + id + '_t">' + tit + '</h3><p class="vct-modal-subtitle">' + sub + '</p></div>' +
                '<button type="button" class="vct-form-close" ' + cancelAttr + ' aria-label="Cerrar">\u00d7</button></div>' +
              '<div class="vct-modal-body vct-form-body">' + body + '</div>' +
              '<div class="vct-modal-footer vct-form-footer">' +
                '<button type="button" class="vct-btn vct-btn-secondary" ' + cancelAttr + '>Cancelar</button>' +
                '<button type="button" class="vct-btn vct-btn-primary" ' + okAttr + '><span data-vct-icon="save"></span><span>' + okTxt + '</span></button>' +
              '</div></div>';
        document.body.appendChild(o);
        icons(o);
        requestAnimationFrame(function () { o.classList.add("is-open"); });
        return o;
    }
    /* "+" email del consultor: se guarda en la fila y se graba al asignar (VCT_EMAILS, PRINCIPAL NO) */
    var EM_ID = "vctPvEmail", emCons = "";
    function emOpen(m, cons) {
        var tr = m.querySelector('tr[data-vct-pv-cons="' + cons + '"]');
        if (!tr) return;
        emCons = cons;
        var nm = tr.querySelector(".vct-360-project-name");
        var o = ovOpen(EM_ID, "mail", "Email", "Direcci\u00f3n de correo de " + escH(nm ? nm.textContent : "") + ".",
            '<div class="vct-validation-box" data-pv-em-box style="display:none;"></div>' +
            '<div class="vct-form-grid"><div class="vct-field vct-col-12"><label class="vct-label">Email <span class="vct-required">*</span></label>' +
            '<input type="text" class="vct-input" data-pv-em-in maxlength="100" placeholder="Email" autocomplete="off" value="' + escH(tr.getAttribute("data-email-new") || "") + '"></div></div>',
            "data-vct-pv-em-ok", "Guardar", "data-vct-pv-em-cancel");
        setTimeout(function () { var i = o.querySelector("[data-pv-em-in]"); if (i) i.focus(); }, 60);
    }
    function emSave() {
        var o = document.getElementById(EM_ID), m = modal();
        if (!o || !m) return;
        var i = o.querySelector("[data-pv-em-in]"), v = i ? i.value.trim() : "", box = o.querySelector("[data-pv-em-box]");
        i.classList.remove("vct-field-error"); box.style.display = "none"; box.innerHTML = "";
        var msg = !v ? "Email es obligatorio." : !MAIL_RE.test(v) ? "Email no tiene un formato v\u00e1lido." : "";
        if (msg) {
            box.innerHTML = '<div class="vct-validation-title">Complete o corrija los datos indicados</div><ul><li>' + msg + '</li></ul>';
            box.style.display = "block"; i.classList.add("vct-field-error"); i.focus();
            return;
        }
        var tr = m.querySelector('tr[data-vct-pv-cons="' + emCons + '"]');
        if (tr) { tr.setAttribute("data-email-new", v); if (!tr.getAttribute("data-email")) tr.setAttribute("data-email", ""); }
        ovClose(EM_ID);
        syncSel(m);
    }
    /* confirmacion previa (igual que el alta del proyecto) */
    var CF_ID = "vctPvAsigConf", cfData = null;
    function cfRow(lbl, val) { return '<div class="vct-pv-cf-row"><span>' + lbl + '</span><div>' + val + '</div></div>'; }
    function cfOpen(m, d) {
        cfData = d;
        var cons = picked(m).map(function (tr) {
            var nm = tr.querySelector(".vct-360-project-name"), o = rowRol(tr);
            return '<div class="vct-pv-cf-cons"><b>' + escH(nm ? nm.textContent : "") + '</b> <span class="vct-pv-cf-rol">' + escH(o ? o.textContent : "") + '</span>' +
                   '<div class="vct-pv-cf-mail">' + escH(consMail(tr)) + (tr.getAttribute("data-email-new") && !tr.getAttribute("data-email") ? ' <small>(nuevo)</small>' : '') + '</div></div>';
        }).join("");
        var gen = m.querySelector(".vct-pv-gen");
        var body = cfRow("Cliente", '<b>' + escH(m.getAttribute("data-vct-pv-cli") || "") + '</b>') +
            cfRow("Proyecto", '<b>' + (m.getAttribute("data-vct-pv-pcod") ? "(" + escH(m.getAttribute("data-vct-pv-pcod")) + ") " : "") + escH(m.getAttribute("data-vct-pv-pnom") || "") + '</b>') +
            cfRow(d.n > 1 ? "Consultores" : "Consultor", cons) +
            (d.cc ? cfRow("Con copia a", escH(d.cc)) : "") +
            '<p class="vct-pv-cf-note"><span data-vct-icon="mail"></span>Se env\u00eda el mail de asignaci\u00f3n a ' + (d.n > 1 ? "los consultores" : "el consultor") + '.</p>' +
            (d.lideres && gen ? '<div class="vct-pv-cf-gen"><div class="vct-pv-sec">Al asignar el l\u00edder se genera</div><div class="vct-pv-gen">' + gen.innerHTML + '</div></div>' : "");
        var o = ovOpen(CF_ID, "user-plus", "Asignar consultores", "Revise los datos antes de confirmar.", body, "data-vct-pv-cf-ok", "Asignar y notificar", "data-vct-pv-cf-cancel");
        setTimeout(function () { var b = o.querySelector("[data-vct-pv-cf-ok]"); if (b) b.focus(); }, 60);
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
                    var nm = tr.querySelector(".vct-360-project-name"), o = rowRol(tr), mail = consMail(tr), nuevo = !tr.getAttribute("data-email") && !!mail;
                    if (!mail) faltan++;
                    return '<div class="vct-pv-sel-row"><b>' + esc(nm ? nm.textContent : "") + '</b>' +
                           '<span class="vct-pv-sel-rol">' + esc(o ? o.textContent : "") + '</span>' +
                           (mail ? '<span class="vct-pv-sel-mail">' + esc(mail) + (nuevo ? ' <small class="vct-pv-sel-new">(nuevo)</small>' : '') + '</span>'
                                 : '<span class="vct-pv-sel-mail is-missing">sin email cargado</span>') +
                           (tr.getAttribute("data-email") ? '' : '<button type="button" class="vct-pv-em-add" data-vct-pv-em-add="' + esc(tr.getAttribute("data-vct-pv-cons")) + '" title="Agregar email" aria-label="Agregar email">+</button>') + '</div>';
                }).join("");
        }
        m.setAttribute("data-vct-pv-faltan", String(faltan));
        var lbl = m.querySelector("[data-vct-pv-email-lbl]"), help = m.querySelector("[data-vct-pv-email-help]");
        if (lbl) lbl.innerHTML = "Con copia a";
        if (help) help.innerHTML = "Opcional: va en copia del mail a los consultores.";
        lockLider(m);
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
        m.querySelectorAll("tr[data-vct-pv-cons]").forEach(function (tr) { tr.classList.remove("is-selected"); tr.removeAttribute("data-email-new"); rolDefault(tr); });
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
        var mv = mail ? mail.value.replace(/,/g, ";").trim() : "", nuevos = [];
        filas.forEach(function (tr) {
            var nm = tr.querySelector(".vct-360-project-name");
            if (!consMail(tr)) errs.push(escH(nm ? nm.textContent : "El consultor") + " no tiene email: agr&eacute;guelo con el bot&oacute;n +.");
            else if (!tr.getAttribute("data-email") && tr.getAttribute("data-email-new")) nuevos.push(tr.getAttribute("data-vct-pv-cons") + ":" + tr.getAttribute("data-email-new"));
        });
        if (mv) mv.split(";").forEach(function (x) {
            x = x.trim();
            if (x && !/^[^\s@;]+@[^\s@;]+\.[^\s@;]+$/.test(x)) errs.push("Con copia a: &quot;" + x.replace(/</g, "&lt;") + "&quot; no es una direcci&oacute;n v&aacute;lida.");
        });
        var guid = m.getAttribute("data-vct-pv-guid") || "";
        if (!guid) errs.push("No se encontr&oacute; la pantalla de la Vista 360 (permiso PROYECTOS VIEW).");
        if (errs.length) { showError(m, errs); return; }
        showError(m, null);
        if (!btn.hasAttribute("data-vct-pv-cf-go")) {
            cfOpen(m, { n: filas.length, lideres: lideres, cc: mv.replace(/;/g, "; ") });
            return;
        }
        btn.removeAttribute("data-vct-pv-cf-go");
        if (!window.VCT || !VCT.Buffer || !VCT.Navigation) return;
        btn.disabled = true;
        if (VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab("equipo");
        var S = function (k, v) { return Promise.resolve(VCT.Buffer.store(k, v)); };
        S("TEXTO30", "PV_ASIGNAR")
            .then(function () { return S("TEXTO11", lista.join(";")); })
            .then(function () { return S("TEXTO12", lideres && vence ? vence.value : ""); })
            .then(function () { return S("TEXTO13", obs ? obs.value : ""); })
            .then(function () { return S("TEXTO14", mv); })
            .then(function () { return S("TEXTO15", nuevos.join(";")); })
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
    /* servicio: al agregar se ocultan los que el proyecto ya tiene; al editar el servicio no se cambia */
    function svSel(m, edit) {
        var sel = m.querySelector("[data-vct-pv-svsel]");
        if (!sel) return;
        var fs = window.VCT && VCT.FormSelect;
        sel.disabled = !!edit;
        Array.prototype.forEach.call(sel.options, function (o) {
            if (!o.value) return;
            var off = !edit && o.getAttribute("data-used") === "1";
            o.disabled = off; o.hidden = off;
        });
        var w = sel.parentNode ? sel.parentNode.querySelector(".vct-form-select") : null;
        var menu = w ? w.__vctPortalMenu : null;
        if (menu) menu.querySelectorAll(".vct-form-select-option").forEach(function (d) {
            var v = d.getAttribute("data-value"), o = null;
            if (!v) return;
            Array.prototype.forEach.call(sel.options, function (x) { if (x.value === v) o = x; });
            var off = !!(o && o.disabled);
            if (off) d.style.setProperty("display", "none", "important"); else d.style.removeProperty("display");
        });
        if (!edit) {
            var libres = Array.prototype.filter.call(sel.options, function (o) { return o.value && !o.disabled; });
            if (libres.length === 1) setVal(sel, libres[0].value);
        }
        if (w && fs && fs.sync) fs.sync(sel, w);
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
        paResp(m);
        svSel(m, !!edit);
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
        enviar(btn, cmdM, lzId, campos, /^PV_PL_/.test(cmdM) ? "plan" : /^PV_AC_/.test(cmdM) ? "acciones" : /^PV_PROY_/.test(cmdM) ? "resumen" : /^PV_SV_/.test(cmdM) ? "servicios" : "lanzamiento");
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
        enviar(btn, cmd, btn.getAttribute("data-id") || "0", extra, /^PV_PL_/.test(cmd) ? "plan" : /^PV_AC_/.test(cmd) ? "acciones" : /^PV_DOC_/.test(cmd) ? "documentos" : "lanzamiento");
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

    /* ---------------- plan estrategico: arbol capitulo > item > subitem, detalle 50/50, cronograma (PL_ARBOL_V1) ----------------
       - la flecha (o la fila del capitulo) despliega / pliega, sin abrir el detalle;
       - clic en el nombre del item / subitem o en el menu "Ver detalle": abre el detalle a la derecha (50 / 50);
       - la X del detalle lo cierra. Lo abierto y lo elegido se recuerdan al volver despues de grabar (por proyecto). */
    function plKey(box) { var m = box ? box.closest("[data-vct-pv-proyecto]") : null; return "vct.pv.plan.arbol." + (m ? m.getAttribute("data-vct-pv-proyecto") : ""); }
    function plBox() { var r = root(); return r ? r.querySelector("[data-pl-box]") : null; }
    function plSave(box) {
        if (!box) return;
        var st = { ch: [], it: [], sel: box.getAttribute("data-pl-cur") || "" };
        box.querySelectorAll(".vct-plt-ch.is-open").forEach(function (c) { st.ch.push(c.getAttribute("data-pl-ch")); });
        box.querySelectorAll(".vct-plt-it.is-open > .vct-plt-r").forEach(function (r) { st.it.push(r.getAttribute("data-pl-row")); });
        try { window.sessionStorage.setItem(plKey(box), JSON.stringify(st)); } catch (e) { }
    }
    function plAllLabel(box) {
        if (!box) return;
        var b = box.querySelector("[data-pl-chap-all]");
        if (!b) return;
        var todos = true, hay = false;
        box.querySelectorAll(".vct-plt-ch:not([hidden])").forEach(function (c) { hay = true; if (!c.classList.contains("is-open")) todos = false; });
        todos = todos && hay;
        var sp = b.querySelectorAll("span");
        if (sp.length) sp[sp.length - 1].textContent = todos ? "Contraer todo" : "Expandir todo";
        b.setAttribute("data-pl-open", todos ? "1" : "0");
    }
    function plToggle(node, open) {
        if (!node) return;
        node.classList.toggle("is-open", typeof open === "boolean" ? open : !node.classList.contains("is-open"));
        var box = node.closest("[data-pl-box]");
        plAllLabel(box);
        plSave(box);
    }
    function plSel(box, id) {
        if (!box) return;
        var tree = box.querySelector("[data-pl-tree]");
        if (!tree) return;
        var det = id ? tree.querySelector('[data-pl-det="' + id + '"]') : null;
        tree.querySelectorAll("[data-pl-det]").forEach(function (d) { d.hidden = d !== det; });
        tree.querySelectorAll(".vct-plt-r.is-on").forEach(function (r) { r.classList.remove("is-on"); });
        tree.classList.toggle("is-sel", !!det);
        box.setAttribute("data-pl-cur", det ? id : "");
        if (det) {
            var row = tree.querySelector('[data-pl-row="' + id + '"]');
            if (row) {
                row.classList.add("is-on");
                /* que se vea: abre su capitulo y, si es subitem, su item */
                var n = row.parentNode;
                while (n && n !== tree) {
                    if (n.classList && (n.classList.contains("vct-plt-ch") || (n.classList.contains("vct-plt-it") && n !== row.parentNode))) n.classList.add("is-open");
                    n = n.parentNode;
                }
            }
            var side = tree.querySelector(".vct-plt-side");
            if (side && side.getBoundingClientRect().top < 0) side.scrollIntoView({ block: "start", behavior: "smooth" });
        }
        plAllLabel(box);
        plSave(box);
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
        var filtra = !!(q || e);
        var ok = function (el) { return (!q || (el.getAttribute("data-pl-search") || "").indexOf(q) >= 0) && (!e || el.getAttribute("data-pl-est") === e); };
        var hay = 0;
        box.querySelectorAll(".vct-plt-ch").forEach(function (ch) {
            var n = 0;
            ch.querySelectorAll(".vct-plt-kids > .vct-plt-it:not(.is-sub)").forEach(function (it) {
                var vIt = ok(it), vSub = 0;
                it.querySelectorAll(".vct-plt-it.is-sub").forEach(function (sb) { var v = !filtra || vIt || ok(sb); sb.hidden = !v; if (v && ok(sb)) vSub++; });
                var vis = !filtra || vIt || vSub > 0;
                it.hidden = !vis;
                it.classList.toggle("is-fopen", filtra && vSub > 0);
                if (vis) n++;
            });
            ch.hidden = filtra && n === 0;
            ch.classList.toggle("is-fopen", filtra && n > 0);
            hay += n;
        });
        var nr = box.querySelector("[data-pl-nores]");
        if (nr) nr.hidden = hay > 0 || !box.querySelector(".vct-plt-ch");
        /* cronograma */
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
            var st = null;
            try { st = JSON.parse(window.sessionStorage.getItem(plKey(box)) || "null"); } catch (e) { st = null; }
            if (st && st.ch) {
                box.querySelectorAll(".vct-plt-ch").forEach(function (c) { c.classList.toggle("is-open", st.ch.indexOf(c.getAttribute("data-pl-ch")) >= 0); });
                (st.it || []).forEach(function (id) { var r = box.querySelector('[data-pl-row="' + id + '"]'); if (r && r.parentNode.classList.contains("vct-plt-it")) r.parentNode.classList.add("is-open"); });
                if (st.sel) plSel(box, st.sel);
            } else {
                box.querySelectorAll('.vct-plt-ch[data-pl-def="1"]').forEach(function (c) { c.classList.add("is-open"); });
            }
            plAllLabel(box);
        });
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", plInit); else plInit();
    setTimeout(plInit, 400);

    /* ---------------- plan: exportar arbol / cronograma (PL_EXPORT_V1) ----------------
       Mismo export que las grillas (VCTExport: Excel .xlsx / PDF con logo). Respeta el buscador y el filtro de estado.
       Desde el cronograma, el PDF suma la imagen del cronograma arriba de la tabla. */
    function plTxt(el) { return el ? String(el.textContent || "").replace(/\s+/g, " ").trim() : ""; }
    function plExportSpec(box) {
        var gantt = box.classList.contains("is-gantt");
        var h3 = box.querySelector(".vct-pl-head h3");
        var title = plTxt(h3) || "Plan";
        var q = ((box.querySelector("[data-pl-buscar]") || {}).value || "").trim();
        var es = box.querySelector("[data-pl-estado]");
        var fil = [];
        if (q) fil.push("Buscar: " + q);
        if (es && es.value) fil.push("Estado: " + plTxt(es.options[es.selectedIndex]));
        var rows = [];
        box.querySelectorAll(".vct-plt-ch").forEach(function (ch) {
            if (ch.hidden) return;
            var cap = plTxt(ch.querySelector(".vct-plt-cht > b"));
            ch.querySelectorAll(".vct-plt-it").forEach(function (it) {
                if (it.hidden || (it.parentNode && it.parentNode.closest(".vct-plt-it[hidden]"))) return;
                var r = it.querySelector(":scope > .vct-plt-r");
                if (!r) return;
                var c = r.querySelector(".vct-pl-code"), t = r.querySelector(".vct-plt-t");
                var g = function (k) { return r.getAttribute("data-x-" + k) || ""; };
                rows.push([cap, plTxt(c), it.classList.contains("is-sub") ? "Sub\u00edtem" : "\u00cdtem", (t && t.getAttribute("title")) || plTxt(t),
                    g("r"), g("i"), g("v"), g("f"), (+g("a") || 0) + "%", g("n"), +g("ve") || 0, g("e")]);
            });
        });
        return {
            title: title,
            subtitle: (gantt ? "Cronograma" : "\u00c1rbol") + (fil.length ? " \u00b7 " + fil.join(" \u00b7 ") : ""),
            filename: title + (gantt ? " - Cronograma" : ""),
            orientation: "landscape",
            columns: [{ title: "Cap\u00edtulo" }, { title: "C\u00f3digo", type: "text" }, { title: "Tipo" }, { title: "\u00cdtem / sub\u00edtem" }, { title: "Responsable" },
                      { title: "Inicio", align: "center" }, { title: "Vence", align: "center" }, { title: "Fin real", align: "center" }, { title: "Avance", align: "right" },
                      { title: "Acciones cumplidas", align: "center", type: "text" }, { title: "Acciones vencidas", align: "right" }, { title: "Estado" }],
            rows: rows
        };
    }
    /* PL_PDF_GANTT_VECTOR_V1: solo PDF de cronograma. No altera DOM, Excel ni PDF del arbol. */
    function plGanttPDF(spec) {
        if (!window.pdfMake || typeof window.pdfMake.createPdf !== "function")
            return Promise.reject(new Error("pdfMake no esta disponible para el PDF vectorial del cronograma."));

        function fecha(valor) {
            var s = String(valor == null ? "" : valor).trim(), m, y, mo, d;
            if ((m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s))) { y = +m[1]; mo = +m[2]; d = +m[3]; }
            else if ((m = /^(\d{2})\/(\d{2})\/(\d{4})/.exec(s))) { d = +m[1]; mo = +m[2]; y = +m[3]; }
            else return null;
            var f = new Date(y, mo - 1, d);
            return f.getFullYear() === y && f.getMonth() === mo - 1 && f.getDate() === d ? f : null;
        }
        function dia(f) { return Math.floor(Date.UTC(f.getFullYear(), f.getMonth(), f.getDate()) / 86400000); }
        function sumar(f, n) { return new Date(f.getFullYear(), f.getMonth(), f.getDate() + n); }
        function etiqueta(f) { return (f.getDate() < 10 ? "0" : "") + f.getDate() + "/" + (f.getMonth() + 1 < 10 ? "0" : "") + (f.getMonth() + 1); }
        function celda(t, opt) { return Object.assign({ text: String(t == null ? "" : t), fontSize: 7, margin: [3, 5, 3, 5] }, opt || {}); }
        var entradas = spec.rows.map(function (r) {
            var ini = fecha(r[5]), fin = fecha(r[6]);
            return { r: r, ini: ini, fin: fin, a: Math.max(0, Math.min(100, parseFloat(String(r[8]).replace(",", ".")) || 0)) };
        });
        var fechas = [];
        entradas.forEach(function (e) { if (e.ini) fechas.push(dia(e.ini)); if (e.fin) fechas.push(dia(e.fin)); });
        if (!fechas.length) return Promise.reject(new Error("El cronograma no contiene fechas validas de inicio o vencimiento."));
        var min = Math.min.apply(null, fechas), max = Math.max.apply(null, fechas);
        var primer = new Date(min * 86400000);
        primer = new Date(primer.getUTCFullYear(), primer.getUTCMonth(), primer.getUTCDate());
        primer = sumar(primer, -((primer.getDay() + 6) % 7));
        var ultimo = new Date(max * 86400000);
        ultimo = new Date(ultimo.getUTCFullYear(), ultimo.getUTCMonth(), ultimo.getUTCDate());
        var semanas = Math.ceil((dia(ultimo) - dia(primer) + 1) / 7);
        if (semanas > 260) return Promise.reject(new Error("El rango supera 260 semanas. Ajusta las fechas antes de exportar."));
        var porPagina = 13, contenido = [];
        /* El ancho de cada semana es fijo para dibujar duraciones parciales con precision. */
        var anchoSemana = 55;
        function barraSemana(e, desde, hasta) {
            var ini = e.ini ? dia(e.ini) : null, fin = e.fin ? dia(e.fin) : null;
            if (ini === null && fin === null) return celda("");
            if (ini === null) ini = fin;
            if (fin === null) fin = ini;
            if (fin < ini) { var aux = ini; ini = fin; fin = aux; }
            var esHito = /hito/i.test(String(e.r[0] || "")) || /hito/i.test(String(e.r[2] || "")) || /^hito$/i.test(String(e.r[1] || ""));
            var ancho = anchoSemana - 4, alto = 12, dibujo = [];
            if (esHito) {
                /* Un hito se ubica en su fecha de vencimiento, sin simular duracion. */
                if (fin >= desde && fin <= hasta) {
                    var x = 2 + ((fin - desde + 0.5) / 7) * ancho;
                    dibujo.push({ type: "polyline", points: [{ x: x, y: 1 }, { x: x + 5, y: 6 }, { x: x, y: 11 }, { x: x - 5, y: 6 }], closePath: true, color: "#751A3D", lineColor: "#751A3D" });
                }
            } else {
                var a = Math.max(ini, desde), b = Math.min(fin, hasta);
                if (a <= b) {
                    var x0 = 2 + ((a - desde) / 7) * ancho;
                    var x1 = 2 + ((b - desde + 1) / 7) * ancho;
                    dibujo.push({ type: "rect", x: x0, y: 3, w: Math.max(1, x1 - x0), h: 7, r: 2, color: "#DDE9FF" });
                    /* El avance se calcula sobre toda la actividad, no sobre cada semana. */
                    var diasEjecutados = (fin - ini + 1) * e.a / 100;
                    var extremoAvance = ini + diasEjecutados;
                    var hastaAvance = Math.min(extremoAvance, b + 1);
                    if (hastaAvance > a) {
                        var xp = 2 + ((hastaAvance - desde) / 7) * ancho;
                        dibujo.push({ type: "rect", x: x0, y: 3, w: Math.max(0.5, xp - x0), h: 7, r: 2, color: "#12864A" });
                    }
                }
            }
            return { canvas: dibujo.length ? dibujo : [{ type: "line", x1: 0, y1: 0, x2: 0, y2: 0, lineColor: "#FFFFFF", lineWidth: 0.1 }], margin: [0, 4, 0, 4] };
        }
        for (var base = 0; base < semanas; base += porPagina) {
            var cantidad = Math.min(porPagina, semanas - base);
            var comienzo = sumar(primer, base * 7), cierre = sumar(comienzo, cantidad * 7 - 1);
            if (base) contenido.push({ text: "", pageBreak: "before", margin: 0 });
            contenido.push({ text: spec.title, style: "titulo" });
            contenido.push({ text: spec.subtitle + "  |  " + etiqueta(comienzo) + " - " + etiqueta(cierre) + "  |  Semanas " + (base + 1) + "-" + (base + cantidad) + " de " + semanas, style: "subtitulo" });
            var widths = [35, 155, 68, 38];
            for (var w = 0; w < cantidad; w++) widths.push(anchoSemana);
            var cab = [celda("Codigo"), celda("Item / subitem"), celda("Responsable"), celda("Avance")];
            for (var h = 0; h < cantidad; h++) cab.push(celda(etiqueta(sumar(comienzo, h * 7)), { alignment: "center" }));
            var cuerpo = [cab], capAnterior = null;
            entradas.forEach(function (e) {
                var r = e.r;
                if (r[0] !== capAnterior) {
                    capAnterior = r[0];
                    cuerpo.push([{ text: String(capAnterior || "Sin capitulo"), colSpan: cantidad + 4, bold: true, color: "#751A3D", fillColor: "#F3EAF0", fontSize: 8, margin: [4, 5, 4, 5] }].concat(Array(cantidad + 3).fill({ text: "" })));
                }
                var fila = [celda(r[1]), celda((r[2] === "Subítem" ? "  · " : "") + r[3]), celda(r[4]), celda(r[8], { alignment: "right" })];
                var ini = e.ini ? dia(e.ini) : null, fin = e.fin ? dia(e.fin) : null;
                if (ini !== null && fin !== null && fin < ini) { var tmp = ini; ini = fin; fin = tmp; }
                for (var j = 0; j < cantidad; j++) {
                    var desde = dia(sumar(comienzo, j * 7)), hasta = desde + 6;
                    fila.push(barraSemana(e, desde, hasta));
                }
                cuerpo.push(fila);
            });
            contenido.push({ table: { headerRows: 1, widths: widths, body: cuerpo, dontBreakRows: true }, layout: { fillColor: function (row) { return row === 0 ? "#EDEDED" : null; }, hLineColor: function () { return "#D8D8D8"; }, vLineColor: function () { return "#E8E8E8"; }, hLineWidth: function () { return 0.4; }, vLineWidth: function () { return 0.4; } } });
        }
        /* Recupera el mismo logo original que utiliza vct-export.js.
           Solo afecta el PDF Gantt; no altera los demas exportadores. */
        function cargarLogo() {
            return new Promise(function (resolve) {
                var img = new Image();
                img.onload = function () {
                    try {
                        var canvas = document.createElement("canvas");
                        canvas.width = img.naturalWidth || img.width;
                        canvas.height = img.naturalHeight || img.height;
                        if (!canvas.width || !canvas.height) { resolve(null); return; }
                        canvas.getContext("2d").drawImage(img, 0, 0);
                        resolve({ data: canvas.toDataURL("image/png"), ratio: canvas.width / canvas.height });
                    } catch (e) { resolve(null); }
                };
                img.onerror = function () { resolve(null); };
                img.src = "../img/LogoBordo.png";
            });
        }
        return cargarLogo().then(function (logo) {
            var cabecera = logo
                ? { image: logo.data, width: 84, margin: [25, 7, 0, 0] }
                : { text: "Vocaturo", bold: true, fontSize: 12, color: "#751A3D", margin: [25, 7, 0, 0] };
            var doc = { pageSize: "A3", pageOrientation: "landscape", pageMargins: [25, 43, 25, 30], content: contenido,
                header: function () { return cabecera; },
                defaultStyle: { font: "Roboto" }, styles: { titulo: { fontSize: 15, bold: true, color: "#751A3D", margin: [0, 0, 0, 5] }, subtitulo: { fontSize: 9, color: "#555555", margin: [0, 0, 0, 12] } },
                footer: function (p, total) { return { text: "Pagina " + p + " de " + total, alignment: "right", margin: [0, 0, 25, 0], fontSize: 8, color: "#777777" }; } };
            return new Promise(function (resolve, reject) {
                try { window.pdfMake.createPdf(doc).download((spec.filename || "Cronograma") + ".pdf", function () { resolve(); }); }
                catch (e) { reject(e); }
            });
        });
    }

    function plExport(btn, kind) {
        var box = btn.closest("[data-pl-box]");
        if (!box || btn.classList.contains("is-busy")) return;
        if (!window.VCTExport) { if (window.VCT && VCT.Toast) VCT.Toast.show("Falta cargar vct-export.js: no se puede exportar.", "warning"); return; }
        var spec = plExportSpec(box);
        btn.classList.add("is-busy");
        var job = kind === "pdf"
            ? (box.classList.contains("is-gantt") ? plGanttPDF(spec) : window.VCTExport.pdf(spec))
            : window.VCTExport.excel(spec);
        Promise.resolve(job).catch(function (e) { if (window.VCT && VCT.Toast) VCT.Toast.show("No se pudo exportar: " + (e && e.message ? e.message : e), "warning"); })
            .then(function () { btn.classList.remove("is-busy"); });
    }

    /* accion del plan: responsable "Otro" pide el nombre (el badge toma sus iniciales) */
    function plIni(t) {
        var p = String(t || "").trim().split(/\s+/).filter(Boolean);
        return p.length ? (p[0].charAt(0) + (p.length > 1 ? p[1].charAt(0) : "")).toUpperCase() : "?";
    }
    function paResp(m) {
        if (!m) return;
        var sel = m.querySelector("[data-vct-pv-resp]"), box = m.querySelector("[data-vct-pv-otro]");
        if (!sel || !box) return;
        var otro = sel.value === "OTRO", nom = box.querySelector('[data-vct-pv-f="nom"]'), ini = box.querySelector("[data-vct-pv-otro-ini]");
        box.hidden = !otro;
        if (nom) {
            if (otro) nom.setAttribute("data-req", "Nombre del responsable"); else { nom.removeAttribute("data-req"); nom.classList.remove("is-invalid"); }
            if (ini) ini.textContent = plIni(nom.value);
        }
    }

    /* ---------------- encabezado: fila 3 flexible (PV_HEADER_V2) ----------------
       Los datos no se cortan ni se pisan: si no entran, se compactan en este orden:
       cargo del contacto > domicilio > email > telefono > contacto (pasan a icono con el dato en el tooltip).
       Como ultimo recurso el nombre del cliente se corta con "...". */
    function hdFit() {
        document.querySelectorAll("[data-vct-pv-fit]").forEach(function (r) {
            r.classList.remove("no-cg", "cli-shrink");
            r.querySelectorAll(".is-ico").forEach(function (x) { x.classList.remove("is-ico"); });
            if (!r.clientWidth) return;
            var ico = function (sel) { var e = r.querySelector(sel); if (e) e.classList.add("is-ico"); };
            var pasos = [function () { r.classList.add("no-cg"); }, function () { ico(".vct-pv-hd-dom"); }, function () { ico(".vct-pv-hd-mail"); },
                         function () { ico(".vct-pv-hd-tel"); }, function () { ico(".vct-pv-hd-con"); }, function () { r.classList.add("cli-shrink"); }];
            for (var i = 0; i < pasos.length && r.scrollWidth > r.clientWidth + 1; i++) pasos[i]();
        });
    }
    var hdT = null;
    window.addEventListener("resize", function () { clearTimeout(hdT); hdT = setTimeout(hdFit, 120); });
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", hdFit); else hdFit();
    setTimeout(hdFit, 300); setTimeout(hdFit, 1200);

    /* ---------------- eventos ---------------- */
    document.addEventListener("click", function (e) {
        var t = e.target;
        if (!t || !t.closest) return;

        /* campanita del proyecto: abre / cierra; Gestionar cierra el panel y sigue */
        var bt = t.closest("[data-vct-pv-bell-toggle]");
        if (bt) { e.preventDefault(); bellPanel(bt.closest("[data-vct-pv-bell]")); return; }
        if (t.closest("[data-vct-pv-bell-go]")) bellPanel(null, false);
        else if (!t.closest("[data-vct-pv-bell-panel]")) bellPanel(null, false);

        /* servicios: plegar grupo; Ver plan */
        var svg = t.closest("tr[data-vct-pv-svg]");
        if (svg) { e.preventDefault(); svg.classList.toggle("is-open"); svApply(svg.closest(".vct-pv-svt-box")); return; }
        var svp = t.closest("[data-vct-pv-svpage]");
        if (svp) {
            e.preventDefault();
            if (svp.disabled) return;
            var pgr = svp.closest("tr[data-vct-pv-svpg]"), bx = svp.closest(".vct-pv-svt-box");
            var gh = pgr && bx ? bx.querySelector('tr[data-vct-pv-svg="' + pgr.getAttribute("data-vct-pv-svpg") + '"]') : null;
            if (gh) { gh.setAttribute("data-page", svp.getAttribute("data-vct-pv-svpage")); svApply(bx); }
            return;
        }
        var vp = t.closest("[data-vct-pv-verplan]");
        if (vp) {
            e.preventDefault();
            if (window.VCT && VCT.RowMenu && typeof VCT.RowMenu.close === "function") VCT.RowMenu.close();
            planOpen(root(), vp.getAttribute("data-vct-pv-verplan"), vp.getAttribute("data-id"), vp.getAttribute("data-nombre"), true, vp.getAttribute("data-lugar"));
            return;
        }

        /* documentos del proyecto (PV_DOCS_V1): ver / descargar con el handler del framework */
        var pdoc = t.closest("[data-vct-pv-doc]");
        if (pdoc) {
            e.preventDefault();
            if (window.VCT && VCT.RowMenu && typeof VCT.RowMenu.close === "function") VCT.RowMenu.close();
            var durl = "../task/DownloadFile.ashx?action=view&pKey=" + encodeURIComponent(pdoc.getAttribute("data-pkey") || "")
                     + "&fileName=" + encodeURIComponent(pdoc.getAttribute("data-file") || "");
            if (pdoc.getAttribute("data-vct-pv-doc") === "download") {
                var da = document.createElement("a");
                da.href = durl; da.setAttribute("download", pdoc.getAttribute("data-nombre") || pdoc.getAttribute("data-file") || "documento");
                da.style.display = "none"; document.body.appendChild(da); da.click(); document.body.removeChild(da);
            } else window.open(durl, "_blank", "noopener");
            return;
        }
        var plx = t.closest("[data-pl-export]");
        if (plx) { e.preventDefault(); plExport(plx, plx.getAttribute("data-pl-export")); return; }
        /* requiere atencion: ver todas -> Acciones con el chip Plan estrategico */
        var pat = t.closest("[data-pl-atn-all]");
        if (pat) {
            e.preventDefault();
            var rr = root();
            activateTab(rr, "acciones");
            var acb = rr ? rr.querySelector("[data-pv-acbox]") : null;
            if (acb && acb.querySelector('[data-pv-acchip="plan"]')) acChip(acb, "plan");
            return;
        }
        var plv = t.closest("[data-pl-view]");
        if (plv) { e.preventDefault(); plView(plv.closest("[data-pl-box]"), plv.getAttribute("data-pl-view")); return; }
        var pla = t.closest("[data-pl-chap-all]");
        if (pla) {
            e.preventDefault();
            var bx = pla.closest("[data-pl-box]"), abrir = pla.getAttribute("data-pl-open") !== "1";
            if (bx) bx.querySelectorAll(".vct-plt-ch:not([hidden]), .vct-plt-it").forEach(function (c) {
                if (c.classList.contains("vct-plt-ch") || c.querySelector(".vct-plt-kids")) c.classList.toggle("is-open", abrir);
            });
            plAllLabel(bx);
            plSave(bx);
            return;
        }
        /* arbol del plan: elegir (detalle 50/50), cerrar detalle, desplegar */
        var pls = t.closest("[data-pl-sel]");
        if (pls) {
            e.preventDefault();
            if (window.VCT && VCT.RowMenu && typeof VCT.RowMenu.close === "function") VCT.RowMenu.close();
            plSel(pls.closest("[data-pl-box]") || plBox(), pls.getAttribute("data-pl-sel"));
            return;
        }
        if (t.closest("[data-pl-x]")) { e.preventDefault(); plSel(t.closest("[data-pl-box]"), ""); return; }
        var plt = t.closest("[data-pl-tg]");
        if (plt && !t.closest("button:not([data-pl-tg]),a,[data-vctdg-rowmenu],.vct-pl-menu")) {
            e.preventDefault();
            plToggle(plt.closest(".vct-plt-it") && !plt.classList.contains("is-ch") ? plt.closest(".vct-plt-it") : plt.closest(".vct-plt-ch"));
            return;
        }

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
        if (go) {
            e.preventDefault();
            var gr = go.closest("[data-vct-pv]") || root();
            if (go.getAttribute("data-vct-pv-goto") === "plan") {
                planOpen(gr, go.getAttribute("data-vct-pv-plan") || "co", "", "", true);
                /* desde Acciones: abre el detalle del item de la accion (AC_PESTANIA_V1) */
                var pli = go.getAttribute("data-vct-pv-plitem");
                if (pli) setTimeout(function () { var bx = gr ? gr.querySelector("[data-pl-box]") : plBox(); if (bx) { plView(bx, "cards"); plSel(bx, pli); } }, 250);
            }
            else activateTab(gr, go.getAttribute("data-vct-pv-goto"));
            return;
        }

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

        var ea = t.closest("[data-vct-pv-em-add]");
        if (ea) { e.preventDefault(); e.stopPropagation(); emOpen(ea.closest("[data-vct-pv-modal]") || modal(), ea.getAttribute("data-vct-pv-em-add")); return; }
        var rb = t.closest(".vct-pv-role");
        if (rb && rb.closest("tr[data-vct-pv-cons]")) {
            e.preventDefault();
            var rtr = rb.closest("tr"), rm = rtr.closest("[data-vct-pv-modal]");
            if (rb.classList.contains("is-locked")) {
                if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") VCT.Toast.show("Ya hay un consultor l\u00edder: este solo puede asignarse como consultor.", "info");
                return;
            }
            rtr.classList.add("is-selected");          /* elegir un rol marca la fila */
            setRol(rtr, rb);
            unLider(rm, rtr);
            syncSel(rm);
            return;
        }
        var tr = t.closest("tr[data-vct-pv-cons]");
        if (tr) {
            var trm = tr.closest("[data-vct-pv-modal]");
            tr.classList.toggle("is-selected");
            if (!tr.classList.contains("is-selected")) rolDefault(tr); else rolAlMarcar(trm, tr);
            syncSel(trm);
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
        if (e.target.matches("[data-vct-pv-resp]")) paResp(m);
    });
    document.addEventListener("input", function (e) {
        if (e.target && e.target.matches && e.target.matches("[data-pl-buscar]")) { plFiltrar(e.target.closest(".vct-pl-box")); return; }
        if (e.target && e.target.matches && e.target.matches('[data-vct-pv-otro] [data-vct-pv-f="nom"]')) { paResp(e.target.closest("[data-vct-pv-modal]")); return; }
        if (e.target && e.target.matches && e.target.matches("[data-vct-pv-svbuscar]")) {
            var sbx = e.target.closest(".vct-pv-svt-box");
            if (sbx) sbx.querySelectorAll("tr[data-vct-pv-svg]").forEach(function (g) { g.setAttribute("data-page", "1"); });
            svApply(sbx);
            return;
        }
        if (!e.target || !e.target.matches || !e.target.matches("[data-vct-pv-buscar]")) return;
        filtrar(e.target.closest("[data-vct-pv-modal]"), e.target.value);
    });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") { closeModal(); bellPanel(null, false); } });
    /* PV_ASIG_V2: modales Email y confirmacion (por encima del de asignar) */
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        if (t.closest("[data-vct-pv-em-cancel]")) { e.preventDefault(); e.stopImmediatePropagation(); ovClose(EM_ID); return; }
        if (t.closest("[data-vct-pv-em-ok]")) { e.preventDefault(); e.stopImmediatePropagation(); emSave(); return; }
        if (t.closest("[data-vct-pv-cf-cancel]")) { e.preventDefault(); e.stopImmediatePropagation(); ovClose(CF_ID); return; }
        if (t.closest("[data-vct-pv-cf-ok]")) {
            e.preventDefault(); e.stopImmediatePropagation();
            ovClose(CF_ID);
            var m = modal(), b = m ? m.querySelector("[data-vct-pv-asignar]") : null;
            if (b && !b.disabled) { b.setAttribute("data-vct-pv-cf-go", "1"); guardar(b); }
        }
    }, true);
    document.addEventListener("keydown", function (e) {
        if (e.key !== "Escape") return;
        if (document.getElementById(EM_ID)) { e.stopImmediatePropagation(); ovClose(EM_ID); }
        else if (document.getElementById(CF_ID)) { e.stopImmediatePropagation(); ovClose(CF_ID); }
    }, true);

    /* ---------------- acciones: grilla agrupada por origen + chips (AC_PESTANIA_V1) ---------------- */
    var AC_KEY = "vct.pv.acciones.origen.";
    function acHost(box) { return box ? box.querySelector('[data-vct-dg-id="pv_acciones"]') : null; }
    function acGroups(host) {
        if (!host) return;
        var tb = host.querySelector("tbody");
        if (!tb) return;
        tb.querySelectorAll("tr.vct-pv-acg-row").forEach(function (x) { x.parentNode.removeChild(x); });
        /* con un orden de columna elegido no se agrupa (las filas se mezclan) */
        if (host.querySelector("th.is-asc, th.is-desc")) return;
        var box = host.closest("[data-pv-acbox]");
        var cols = host.querySelectorAll("thead th").length || 6, prev = null;
        Array.prototype.slice.call(tb.querySelectorAll("tr[data-pv-acg]")).forEach(function (row) {
            var k = row.getAttribute("data-pv-acg");
            if (k === prev) return;
            prev = k;
            var chip = box ? box.querySelector('[data-pv-acchip="' + k + '"]') : null;
            var n = chip ? (chip.querySelector("i") || {}).textContent || "" : "";
            var ab = chip ? +chip.getAttribute("data-pv-acchip-ab") || 0 : 0, ve = chip ? +chip.getAttribute("data-pv-acchip-ve") || 0 : 0;
            var tr = document.createElement("tr");
            tr.className = "vct-pv-acg-row";
            tr.setAttribute("data-pv-acg-k", k);
            tr.innerHTML = '<td colspan="' + cols + '"><span class="vct-pv-acg-t">' + (chip ? chip.getAttribute("data-pv-acchip-lbl") : k) + "</span>" +
                '<small>' + n + " acci" + (n === "1" ? "ón" : "ones") + (ab ? " · " + ab + " abierta" + (ab > 1 ? "s" : "") : "") +
                (ve ? ' · <b>' + ve + " vencida" + (ve > 1 ? "s" : "") + "</b>" : "") + (k === "plan" ? " · se gestionan en el plan" : "") + "</small></td>";
            row.parentNode.insertBefore(tr, row);
        });
    }
    function acChip(box, k, keep) {
        if (!box) return;
        var host = acHost(box);
        var sel = host ? host.querySelector("[data-pv-acorig]") : null;
        box.querySelectorAll("[data-pv-acchip]").forEach(function (c) { c.classList.toggle("is-on", c.getAttribute("data-pv-acchip") === k); });
        if (sel && sel.value !== k) {
            sel.value = k;
            try { sel.dispatchEvent(new Event("change", { bubbles: true })); } catch (e) { }
        }
        /* filtro Capitulo: solo con el chip Plan estrategico (al salir del chip se limpia) */
        var cap = host ? host.querySelector("[data-pv-accap]") : null;
        if (cap) {
            var fb = host.querySelector(".vctdg-filters"), w = cap;
            while (w && w.parentNode && w.parentNode !== fb && w.parentNode !== host) w = w.parentNode;
            if (w) w.style.display = k === "plan" ? "" : "none";
            /* si el selector visible es un hermano (desplegable del formulario), tambien */
            var sib = w ? w.nextElementSibling : null;
            if (w === cap && sib && /vct-form-select|vctdg-select-ui/.test(sib.className || "")) sib.style.display = k === "plan" ? "" : "none";
            if (k !== "plan" && cap.value) {
                cap.value = "";
                if (window.VCT && VCT.FormSelect && typeof VCT.FormSelect.sync === "function") { var fw = cap.parentNode ? cap.parentNode.querySelector(".vct-form-select") : null; if (fw) VCT.FormSelect.sync(cap, fw); }
                try { cap.dispatchEvent(new Event("change", { bubbles: true })); } catch (e) { }
            }
        }
        if (!keep) { var m = box.closest("[data-vct-pv-proyecto]"); try { sessionStorage.setItem(AC_KEY + (m ? m.getAttribute("data-vct-pv-proyecto") : ""), k); } catch (e) { } }
        setTimeout(function () { acGroups(host); }, 0);
    }
    function acInit(r) {
        var box = r ? r.querySelector("[data-pv-acbox]") : null;
        if (!box) return;
        var k = "";
        try { k = sessionStorage.getItem(AC_KEY + (r.getAttribute("data-vct-pv-proyecto") || "")) || ""; } catch (e) { }
        if (k && !box.querySelector('[data-pv-acchip="' + k + '"]')) k = "";
        acChip(box, k, true);
    }
    document.addEventListener("vctdg:render", function (e) {
        var h = e.target;
        if (h && h.getAttribute && h.getAttribute("data-vct-dg-id") === "pv_acciones") acGroups(h);
    });
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        var c = t.closest("[data-pv-acchip]");
        if (c) { e.preventDefault(); acChip(c.closest("[data-pv-acbox]"), c.getAttribute("data-pv-acchip")); return; }
        var g = t.closest("tr.vct-pv-acg-row");
        if (g) {
            var bx = g.closest("[data-pv-acbox]"), k = g.getAttribute("data-pv-acg-k");
            var on = bx ? bx.querySelector("[data-pv-acchip].is-on") : null;
            acChip(bx, on && on.getAttribute("data-pv-acchip") === k ? "" : k);
        }
    });

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
        r.querySelectorAll(".vct-pv-svt-box").forEach(svApply);
        setTimeout(function () { planRestore(r); }, 150);
        setTimeout(function () { planRestore(r); }, 600);
        /* arbol del plan: tras guardar / eliminar se re-inyecta; restaura capitulos abiertos y el detalle seleccionado */
        plInit();
        setTimeout(plInit, 200);
        /* acciones: chip de origen elegido y filas de grupo */
        setTimeout(function () { acInit(r); }, 300);
        /* agenda: filas de grupo por servicio (PV_AGENDA_V1) */
        setTimeout(function () { r.querySelectorAll('[data-vct-dg-id="pv_agenda"]').forEach(agGroups); }, 300);
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

    /* ---------------- agenda del proyecto (PV_AGENDA_V1) ----------------
       Lista agrupada por servicio (como Servicios) / Calendario (motor vct-calendario, dias editables con "+"),
       modal Nueva visita / Editar visita: servicio e instancia, normas, consultores con calificacion por norma,
       agenda de 7 dias desde la fecha desde, horas (8 h por dia), estado, observaciones y mail. Graba PV_AG_GUARDAR. */
    var AG_LBL = {
        D: ["d", "D"], A: ["d", "D"], AX: ["a", "Asig"], ND: ["o", "ND"], OC: ["o", "Oc"], PO: ["p", "Pot"], OR: ["g", "Org"],
        OB: ["b", "Obs"], LI: ["l", "Lic"], FE: ["f", "Fer"], NC: ["n", "—"], X: ["n", "?"]
    };
    var AG_TXT = {
        AX: "asignado a otro proyecto", ND: "no disponible", OC: "ocupado", PO: "potencial", OR: "organismo", OB: "observación",
        LI: "licencia", FE: "feriado", NC: "agenda sin cargar"
    };
    var AG_DN = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
    var ag = null;   /* estado del modal abierto */
    function agM(from) {
        var r = (from && from.closest ? from.closest("[data-vct-pv]") : null) || root();
        return r ? r.querySelector('[data-vct-pv-modal="ag"]') : null;
    }
    function agIso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
    function agFmt(d) { return pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + "/" + d.getFullYear(); }
    function agAdd(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n); }
    function agDiff(a, b) { return Math.round((b - a) / 86400000); }
    function agNum(v) { var n = parseFloat(String(v == null ? "" : v).replace(",", ".")); return isNaN(n) ? 0 : n; }
    function agH(n) { n = Math.round(n * 10) / 10; return String(n).replace(".", ","); }
    function agToast(msg) { if (window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") VCT.Toast.show(msg, "info"); }
    function agF(m, k) { return m.querySelector('[data-pv-ag-f="' + k + '"]'); }
    function agRows(m) { return Array.prototype.slice.call(m.querySelectorAll("tr[data-pv-agc]")); }
    function agSel(m) { return agRows(m).filter(function (tr) { return tr.classList.contains("is-selected"); }); }
    function agDias() { return ag && ag.desde && ag.hasta && ag.hasta >= ag.desde ? agDiff(ag.desde, ag.hasta) + 1 : 0; }
    /* agenda del consultor: "dia:codigo:horas libres" desde hoy */
    function agAgenda(tr) {
        if (tr.__ag) return tr.__ag;
        var o = {};
        (tr.getAttribute("data-ag") || "").split(",").forEach(function (x) {
            var p = x.split(":");
            if (p.length === 3) o[p[0]] = { c: p[1], h: agNum(p[2]) };
        });
        tr.__ag = o;
        return o;
    }
    function agDia(m, tr, d) {
        var hoy = parseISO(m.getAttribute("data-pv-ag-hoy")), i = agDiff(hoy, d);
        var nd = parseInt(m.getAttribute("data-pv-ag-nd"), 10) || 0;
        var x = i >= 0 && i < nd ? agAgenda(tr)[String(i)] : null;
        var r = x ? { c: x.c, h: x.h } : { c: "X", h: 0 };
        /* edicion: lo que ya ocupaba esta misma visita vuelve a estar libre */
        var own = ag && ag.own ? ag.own[tr.getAttribute("data-pv-agc")] : 0;
        if (own && r.c === "A" && ag.oDesde && d >= ag.oDesde && d <= ag.oHasta) r.h += own;
        return r;
    }
    function agFalta(m, tr) {
        var dias = agDias();
        if (!dias) return "";
        var inp = tr.querySelector("[data-pv-agc-h]"), need = agNum(inp && inp.value) / dias;
        for (var i = 0; i < dias; i++) {
            var d = agAdd(ag.desde, i), x = agDia(m, tr, d);
            if (x.c === "X") continue;   /* fuera de la ventana: lo valida el servidor al guardar */
            if ((x.c === "D" || x.c === "A") && x.h + 0.05 >= need) continue;
            return AG_DN[d.getDay()] + " " + pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + ": " +
                (x.c === "D" || x.c === "A" ? (x.h > 0 ? "le quedan " + agH(x.h) + " h" : "asignado a otro proyecto") : AG_TXT[x.c] || x.c);
        }
        return "";
    }
    function agCal(tr, nor) {
        if (!ag || !ag.srv) return null;
        var v = null;
        (tr.getAttribute("data-cal") || "").split("|").forEach(function (x) {
            var p = x.split(":");
            if (p.length >= 3 && p[0] === ag.srv && p[1] === nor) v = p.slice(2).join(":");
        });
        return v;
    }
    function agSinCal(tr) {
        if (!ag || !ag.srv) return false;
        return Object.keys(ag.nor).some(function (n) { return ag.nor[n] && !agCal(tr, n); });
    }
    function agSetDate(el, v) { if (el) setVal(el, v); }

    function agOpen(btn, fecha, ed) {
        var m = agM(btn);
        if (!m) return;
        var hoy = parseISO(m.getAttribute("data-pv-ag-hoy"));
        ag = { busy: true, id: "", t: "", ps: "", srv: "", ini: null, fin: null, est: "P", nor: {}, own: {}, otros: false, desde: null, hasta: null, max: 0, emails: {} };
        m.querySelectorAll("[data-pv-ag-nor]").forEach(function (c) { ag.nor[c.getAttribute("data-pv-ag-nor")] = true; });
        agRows(m).forEach(function (tr) {
            tr.classList.remove("is-selected");
            var h = tr.querySelector("[data-pv-agc-h]");
            if (h) { h.value = ""; h.disabled = true; h.removeAttribute("data-user"); }
        });
        ["cc", "det", "log", "calif"].forEach(function (k) { var x = agF(m, k); if (x) x.value = ""; });
        var bus = m.querySelector("[data-pv-ag-buscar]");
        if (bus) bus.value = "";
        var mail = agF(m, "mail");
        if (mail && !mail.disabled) mail.checked = true;
        if (window.VCT && VCT.FormSelect && typeof VCT.FormSelect.build === "function")
            m.querySelectorAll("select[data-pv-ag-ps]").forEach(function (sel) { try { VCT.FormSelect.build(sel); } catch (e) { } });
        m.querySelectorAll("[data-pv-ag-ps]").forEach(function (s) { setVal(s, ""); });
        if (ed) {
            ag.id = ed.getAttribute("data-pv-ag-edit") || "";
            ag.est = ed.getAttribute("data-est") === "C" ? "C" : "P";
            ag.desde = parseISO(ed.getAttribute("data-desde"));
            ag.hasta = parseISO(ed.getAttribute("data-hasta")) || ag.desde;
            ag.oDesde = ag.desde; ag.oHasta = ag.hasta;
            var t = ed.getAttribute("data-t") || "", ps = ed.getAttribute("data-ps") || "";
            agServ(m, t, ps);
            ag.nor = {};
            m.querySelectorAll("[data-pv-ag-nor]").forEach(function (c) { ag.nor[c.getAttribute("data-pv-ag-nor")] = false; });
            (ed.getAttribute("data-nor") || "").split(",").forEach(function (n) { if (n) ag.nor[n] = true; });
            var dias = agDiff(ag.desde, ag.hasta) + 1, cons = (ed.getAttribute("data-cons") || "").split(";").filter(Boolean);
            ag.max = Math.max(1, cons.length);
            cons.forEach(function (x) {
                var p = x.split(":"), tr = m.querySelector('tr[data-pv-agc="' + p[0] + '"]');
                ag.own[p[0]] = agNum(p[1]) / dias;
                if (!tr) return;
                tr.classList.add("is-selected");
                var h = tr.querySelector("[data-pv-agc-h]");
                if (h) { h.disabled = false; h.value = agH(agNum(p[1])).replace(",", "."); h.setAttribute("data-user", "1"); }
                if (tr.hasAttribute("data-otro")) ag.otros = true;
            });
            var map = { det: "data-det", log: "data-log", calif: "data-calif" };
            Object.keys(map).forEach(function (k) { var x = agF(m, k); if (x) x.value = ed.getAttribute(map[k]) || ""; });
            if (mail && !mail.disabled) mail.checked = false;
        } else {
            var f = parseISO(fecha);
            if (f && f >= hoy) { ag.desde = f; ag.hasta = f; }
            /* un solo servicio: queda elegido */
            var svs = m.querySelectorAll("[data-pv-ag-svt]");
            if (svs.length === 1) agServ(m, svs[0].getAttribute("data-pv-ag-svt"), "");
            /* el lider del proyecto arranca marcado */
            var lid = m.querySelector('tr[data-pv-agc][data-rol="l"]');
            if (lid) lid.classList.add("is-selected");
        }
        agSetDate(agF(m, "desde"), ag.desde ? agIso(ag.desde) : "");
        agSetDate(agF(m, "hasta"), ag.hasta ? agIso(ag.hasta) : "");
        var tt = m.querySelector("[data-pv-ag-mtitle]");
        if (tt) tt.textContent = ag.id ? "Editar visita" : "Nueva visita";
        showError(m, null);
        var sv = m.querySelector("[data-pv-ag-save]");
        if (sv) sv.disabled = false;
        agHoras(m, false);
        ag.busy = false;
        agRender(m);
        m.classList.add("is-open");
        document.body.classList.add("vct-modal-open");
        icons(m);
    }
    /* servicio: tipo (co / au / ca) y la instancia */
    function agServ(m, t, ps) {
        ag.t = t; ag.ps = ""; ag.srv = ""; ag.ini = null; ag.fin = null;
        var box = m.querySelector('[data-pv-ag-svt="' + t + '"]');
        if (box && box.hasAttribute("data-ps")) {
            ag.ps = box.getAttribute("data-ps"); ag.srv = box.getAttribute("data-srv") || "";
            ag.ini = parseISO(box.getAttribute("data-ini")); ag.fin = parseISO(box.getAttribute("data-fin"));
        }
        var sel = m.querySelector('[data-pv-ag-ps="' + t + '"]');
        if (sel) {
            if (ps) setVal(sel, ps);
            agInst(m, sel);
        }
    }
    function agInst(m, sel) {
        var o = sel.options[sel.selectedIndex];
        if (!o || !o.value) { ag.ps = ""; ag.srv = ""; ag.ini = null; ag.fin = null; return; }
        ag.ps = o.value; ag.srv = o.getAttribute("data-srv") || "";
        ag.ini = parseISO(o.getAttribute("data-ini")); ag.fin = parseISO(o.getAttribute("data-fin"));
    }
    /* horas por defecto: dias x 8 (salvo las que el usuario cambio a mano) */
    function agHoras(m, reset) {
        var max = agDias() * 8;
        agRows(m).forEach(function (tr) {
            var h = tr.querySelector("[data-pv-agc-h]");
            if (!h) return;
            var on = tr.classList.contains("is-selected");
            h.disabled = !on;
            h.max = max ? String(max) : "";
            if (!on) { h.value = ""; h.removeAttribute("data-user"); return; }
            if (reset || !h.hasAttribute("data-user") || !h.value) { h.value = max ? String(max) : ""; if (reset) h.removeAttribute("data-user"); }
            else if (max && agNum(h.value) > max) h.value = String(max);
        });
    }
    function agRender(m) {
        if (!ag) return;
        var dias = agDias(), hoy = parseISO(m.getAttribute("data-pv-ag-hoy"));
        var di = m.querySelector("[data-pv-ag-dias]");
        if (di) di.value = dias ? dias + " día(s) · hasta " + dias * 8 + " h c/u" : "-";
        var res = m.querySelector("[data-pv-ag-res]");
        if (res) res.value = ag.est === "C" ? "Visita confirmada" : "Visita programada";
        m.querySelectorAll("[data-pv-ag-est] [data-v]").forEach(function (b) { b.classList.toggle("is-on", b.getAttribute("data-v") === ag.est); });
        m.querySelectorAll("[data-pv-ag-svt]").forEach(function (b) { b.classList.toggle("is-on", b.getAttribute("data-pv-ag-svt") === ag.t); });
        m.querySelectorAll("[data-pv-ag-inst]").forEach(function (w) { w.hidden = w.getAttribute("data-pv-ag-inst") !== ag.t; });
        m.querySelectorAll("[data-pv-ag-nor]").forEach(function (c) {
            var on = !!ag.nor[c.getAttribute("data-pv-ag-nor")];
            if (!c.hasAttribute("data-t")) c.setAttribute("data-t", c.textContent);
            c.classList.toggle("is-on", on);
            c.textContent = (on ? "✓ " : "") + c.getAttribute("data-t");
        });
        m.querySelectorAll("th[data-pv-agn], td[data-pv-agn]").forEach(function (c) { c.hidden = !ag.nor[c.getAttribute("data-pv-agn")]; });
        /* cabecera de la agenda: 7 dias desde la fecha desde (o hoy) */
        var base = ag.desde || hoy, win = [];
        for (var i = 0; i < 7; i++) win.push(agAdd(base, i));
        var inV = function (d) { return ag.desde && ag.hasta && d >= ag.desde && d <= ag.hasta; };
        var hd = m.querySelector("[data-pv-agc-dhd]");
        if (hd) hd.innerHTML = win.map(function (d) { return '<span class="' + (inV(d) ? "is-in" : "") + '">' + AG_DN[d.getDay()] + "<br>" + d.getDate() + "</span>"; }).join("");
        var q = ((m.querySelector("[data-pv-ag-buscar]") || {}).value || "").trim().toLowerCase();
        var nOtros = 0;
        agRows(m).forEach(function (tr) {
            var sel = tr.classList.contains("is-selected"), otro = tr.hasAttribute("data-otro");
            var okSrv = !ag.srv || (tr.getAttribute("data-srv") || "").indexOf("," + ag.srv + ",") >= 0;
            var okQ = !q || (tr.getAttribute("data-q") || "").indexOf(q) >= 0;
            if (otro && okSrv) nOtros++;
            tr.hidden = !sel && (!okQ || (otro && (!okSrv || (!ag.otros && !q))));
            /* calificacion por norma (del servicio elegido) */
            tr.querySelectorAll("td[data-pv-agn]").forEach(function (td) {
                if (!ag.srv) { td.innerHTML = '<span class="vctdg-none">-</span>'; return; }
                var c = agCal(tr, td.getAttribute("data-pv-agn"));
                td.innerHTML = c ? '<span class="vct-pv-ag-cal is-ok">' + escH(c) + "</span>" : '<span class="vct-pv-ag-cal is-no">Sin calificación</span>';
            });
            /* agenda de 7 dias */
            var cell = tr.querySelector("[data-pv-agc-agd]");
            if (cell) cell.innerHTML = '<div class="vct-pv-ag-days">' + win.map(function (d) {
                var x = agDia(m, tr, d), lb = AG_LBL[x.c] || AG_LBL.NC, k = lb[0], t = lb[1];
                if (x.c === "D" || x.c === "A") { if (x.h > 0) t = "D<br>" + agH(x.h) + "h"; else { k = "a"; t = "Asig"; } }
                return '<span class="is-' + k + (inV(d) ? " is-in" : "") + '" title="' + escH(AG_DN[d.getDay()] + " " + agFmt(d) + ": " + (x.c === "D" || x.c === "A" ? (x.h > 0 ? "disponible, " + agH(x.h) + " h libres" : "asignado") : AG_TXT[x.c] || "sin dato")) + '">' + t + "</span>";
            }).join("") + "</div>";
            var w = tr.querySelector("[data-pv-agc-warn]"), f = sel ? agFalta(m, tr) : "";
            if (w) { w.hidden = !f; w.textContent = f ? "No disponible · " + f : ""; }
        });
        var og = m.querySelector("[data-pv-agc-otros]");
        if (og) {
            og.hidden = nOtros === 0;
            og.classList.toggle("is-open", ag.otros || !!q);
            var n = og.querySelector("[data-pv-agc-otros-n]");
            if (n) n.textContent = nOtros + " · tocá para " + (ag.otros ? "ocultar" : "ver");
        }
        var eqg = m.querySelector(".vct-pv-ag-grp.is-eq");
        if (eqg) eqg.hidden = !m.querySelector("tr[data-pv-agc]:not([data-otro])");
        /* observaciones de calificacion: obligatorias si hay consultores sin calificacion */
        var sel2 = agSel(m), falta = sel2.some(agSinCal);
        var rq = m.querySelector("[data-pv-ag-calreq]"), hp = m.querySelector("[data-pv-ag-calhelp]");
        if (rq) rq.hidden = !falta;
        if (hp) { hp.textContent = falta ? "Obligatorio: hay consultores sin calificación en alguna norma de la visita." : (sel2.length && ag.srv ? "Opcional: todos los seleccionados están calificados." : ""); hp.classList.toggle("is-req", falta); }
        agNotif(m, sel2);
        agGen(m, sel2);
    }
    /* "Se notifica a": consultores marcados con su email (o para cargarlo) */
    function agNotif(m, sel) {
        var box = m.querySelector("[data-pv-ag-notif]");
        if (!box) return;
        box.querySelectorAll("[data-pv-ag-em]").forEach(function (i) { ag.emails[i.getAttribute("data-pv-ag-em")] = i.value; });
        var nd = sel.filter(function (tr) { return !!agFalta(m, tr); }).length;
        box.innerHTML = '<div class="vct-pv-ag-notif-t">Se notifica a</div>' + (sel.length ? sel.map(function (tr) {
            var id = tr.getAttribute("data-pv-agc"), nm = tr.querySelector(".vct-360-project-name"), em = tr.getAttribute("data-email") || "";
            var rol = tr.getAttribute("data-rol") === "l" ? "Consultor líder" : "Consultor", h = tr.querySelector("[data-pv-agc-h]");
            var abierto = Object.prototype.hasOwnProperty.call(ag.emails, id);
            return '<div class="vct-pv-ag-notif-r"><b>' + escH(nm ? nm.textContent : "") + '</b><span class="vct-pv-ag-notif-rol">' + rol + '</span>' +
                '<span class="vct-pv-ag-notif-h">' + agH(agNum(h && h.value)) + ' h programadas</span>' +
                (em ? '<span class="vct-pv-ag-notif-m">' + escH(em) + "</span><span></span>"
                    : abierto ? '<input type="text" class="vct-input" maxlength="100" placeholder="Email del consultor (se guarda)" data-pv-ag-em="' + id + '" value="' + escH(ag.emails[id] || "") + '"><span></span>'
                    : '<span class="vct-pv-ag-notif-m is-no">sin email cargado</span><button type="button" class="vct-pv-ag-plus" data-pv-ag-emadd="' + id + '" title="Agregar email">+</button>') + "</div>";
        }).join("") : '<div class="vct-help">Ningún consultor seleccionado.</div>') +
        (nd ? '<div class="vct-help is-req">' + nd + " consultor(es) no está(n) disponible(s) en esas fechas: no se puede guardar.</div>" : "");
        var sv = m.querySelector("[data-pv-ag-save]");
        if (sv) { sv.classList.toggle("is-dim", nd > 0); sv.title = nd ? "Hay consultores no disponibles" : ""; }
    }
    function agGen(m, sel) {
        var g = m.querySelector("[data-pv-ag-gen]");
        if (!g) return;
        var tot = 0;
        sel.forEach(function (tr) { var h = tr.querySelector("[data-pv-agc-h]"); tot += agNum(h && h.value); });
        var fe = ag.desde ? agFmt(ag.desde) + (ag.hasta && ag.hasta > ag.desde ? " al " + agFmt(ag.hasta) : "") : "sin fecha";
        var bd = ag.est === "C" ? '<span class="vct-360-badge is-active">Confirmada</span>' : '<span class="vct-360-badge is-planned">Pendiente</span>';
        var mail = agF(m, "mail");
        g.innerHTML = '<div>' + bd + " " + (ag.id ? "Se actualiza la visita" : sel.length + " visita(s) en la agenda del proyecto (una por consultor)") + " · " + fe + " · " + agH(tot) + " h programadas</div>" +
            '<div>' + bd + " Horas asignadas en la agenda de cada consultor en esos días</div>" +
            (mail && mail.checked ? '<div><span class="vct-360-badge is-active">Mail</span> «Visita programada» a los consultores' + ((agF(m, "cc") || {}).value ? " (con copia)" : "") + "</div>" : "");
    }
    function agGuardar(btn) {
        var m = btn.closest('[data-vct-pv-modal="ag"]');
        if (!m || !ag) return;
        var errs = [], sel = agSel(m), dias = agDias(), hoy = parseISO(m.getAttribute("data-pv-ag-hoy"));
        if (!ag.desde) errs.push("Fecha desde es obligatoria.");
        else if (ag.desde < hoy) errs.push("Fecha desde no puede ser anterior a hoy.");
        if (ag.desde && !ag.hasta) errs.push("Fecha hasta es obligatoria.");
        else if (ag.desde && ag.hasta < ag.desde) errs.push("Fecha hasta no puede ser anterior a Fecha desde.");
        if (dias > 31) errs.push("La visita no puede durar más de 31 días.");
        if (!ag.t) errs.push("Servicio es obligatorio.");
        else if (!ag.ps) errs.push((ag.t === "au" ? "Auditoría" : ag.t === "ca" ? "Capacitación" : "Servicio") + " es obligatorio: elija a cuál se carga la visita.");
        if (ag.ps && ag.desde && ag.ini && ag.desde < ag.ini) errs.push("La visita no puede empezar antes del inicio del servicio (" + agFmt(ag.ini) + ").");
        if (ag.ps && ag.hasta && ag.fin && ag.hasta > ag.fin) errs.push("La visita no puede terminar después del fin del servicio (" + agFmt(ag.fin) + ").");
        var nor = Object.keys(ag.nor).filter(function (n) { return ag.nor[n]; });
        if (!nor.length) errs.push("Norma es obligatoria: deje al menos una.");
        if (!sel.length) errs.push("Consultor es obligatorio: marque al menos uno.");
        var lista = [], nuevos = [], mail = agF(m, "mail"), conMail = !!(mail && mail.checked);
        sel.forEach(function (tr) {
            var nm = tr.querySelector(".vct-360-project-name"), n = escH(nm ? nm.textContent : "El consultor");
            var h = tr.querySelector("[data-pv-agc-h]"), v = agNum(h && h.value);
            if (!(v > 0) || (dias && v > dias * 8)) errs.push("Horas de " + n + ": mayor a 0 y hasta " + (dias * 8 || 8) + " (8 h por día).");
            var f = agFalta(m, tr);
            if (f) errs.push(n + " no está disponible (" + escH(f) + ").");
            lista.push(tr.getAttribute("data-pv-agc") + ":" + v);
            if (conMail && !tr.getAttribute("data-email")) {
                var i = m.querySelector('[data-pv-ag-em="' + tr.getAttribute("data-pv-agc") + '"]'), em = i ? i.value.trim() : "";
                if (!em) errs.push(n + " no tiene email: agréguelo con el botón + o destilde Enviar mail.");
                else if (!MAIL_RE.test(em)) errs.push("Email de " + n + " no tiene un formato válido.");
                else nuevos.push(tr.getAttribute("data-pv-agc") + ":" + em);
            }
        });
        var cal = agF(m, "calif");
        if (sel.some(agSinCal) && cal && !cal.value.trim()) errs.push("Observaciones de calificación es obligatorio: hay consultores sin calificación en alguna norma de la visita.");
        var cc = conMail ? (agF(m, "cc") || {}).value || "" : "";
        cc = cc.replace(/,/g, ";").trim();
        if (cc) cc.split(";").forEach(function (x) { x = x.trim(); if (x && !MAIL_RE.test(x)) errs.push("Con copia a: &quot;" + escH(x) + "&quot; no es una dirección válida."); });
        if (errs.length) { showError(m, errs); return; }
        showError(m, null);
        var v = function (k) { var x = agF(m, k); return x ? String(x.value || "").trim() : ""; };
        enviar(btn, "PV_AG_GUARDAR", ag.id || "0", {
            TEXTO11: agIso(ag.desde), TEXTO12: agIso(ag.hasta), TEXTO13: ag.ps, TEXTO14: nor.join(","), TEXTO15: lista.join(";"),
            TEXTO16: ag.est, TEXTO17: v("det"), TEXTO18: v("log"), TEXTO19: v("calif"), TEXTO20: conMail ? "1" : "0", TEXTO21: cc, TEXTO22: nuevos.join(";")
        }, "agenda");
    }

    /* lista: filas de grupo por servicio (como Servicios), con totales de horas */
    function agGroups(host) {
        var tb = host ? host.querySelector("tbody") : null;
        if (!tb) return;
        tb.querySelectorAll("tr.vct-pv-agg-g").forEach(function (x) { x.parentNode.removeChild(x); });
        if (host.querySelector("th.is-asc, th.is-desc, th[aria-sort='ascending'], th[aria-sort='descending']")) return;
        var G = {};
        (host.getAttribute("data-pv-agmeta") || "").split(";").forEach(function (x) {
            var p = x.split("|");
            if (p.length >= 7) G[p[0]] = { t: p[1], ic: p[2], n: p[3], ej: agNum(p[4]), cap: agNum(p[5]), pr: agNum(p[6]) };
        });
        var cols = host.querySelectorAll("thead th").length || 9, prev = null, open = host.__agOpen || {};
        Array.prototype.slice.call(tb.querySelectorAll("tr[data-pv-agg]")).forEach(function (r) {
            var k = r.getAttribute("data-pv-agg");
            r.classList.toggle("is-hidden", open[k] === false);
            if (k === prev) return;
            prev = k;
            var g = G[k] || { t: k, ic: "briefcase", n: "", ej: 0, cap: 0, pr: 0 };
            var pe = g.cap ? Math.min(100, Math.round(g.ej * 100 / g.cap)) : 0, pp = g.cap ? Math.min(100 - pe, Math.round(g.pr * 100 / g.cap)) : 0;
            var tr = document.createElement("tr");
            tr.className = "vct-pv-agg-g" + (open[k] === false ? "" : " is-open");
            tr.setAttribute("data-k", k);
            tr.innerHTML = '<td colspan="' + cols + '"><div class="vct-pv-svt-gh"><span class="vct-pv-svt-chev"><span data-vct-icon="chevron-right"></span></span>' +
                '<span class="vctdg-svc is-' + escH(k) + ' is-on"><span data-vct-icon="' + escH(g.ic) + '"></span></span><b>' + g.t + " (" + escH(g.n) + ")</b>" +
                "<small>" + agH(g.ej) + " / " + agH(g.cap) + " h ejecutadas" + (g.pr ? " · " + agH(g.pr) + " h programadas" : "") + "</small>" +
                '<span class="vct-pv-bar"><span class="is-ejec" style="width:' + pe + '%"></span><span class="is-prog" style="width:' + pp + '%"></span></span></div></td>';
            r.parentNode.insertBefore(tr, r);
        });
        icons(tb);
    }
    document.addEventListener("vctdg:render", function (e) {
        var h = e.target;
        if (h && h.getAttribute && h.getAttribute("data-vct-dg-id") === "pv_agenda") agGroups(h);
    });

    /* calendario: mismo motor que Acciones (vct-calendario); dias editables con "+" */
    function agCalMount(box) {
        var host = box ? box.querySelector("[data-pv-agcal]") : null;
        if (!host || host.getAttribute("data-pv-agcal-on") === "1") return;
        host.setAttribute("data-pv-agcal-on", "1");
        var mo = "";
        ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"].forEach(function (x, i) { mo += '<option value="' + (i + 1) + '">' + x + "</option>"; });
        var leg = [["Visita pendiente", "#CA8A04"], ["Visita confirmada", "#16A34A"], ["Feriado fijo", "#E0304D"], ["Feriado movible", "#8B5CF6"]];
        host.innerHTML = '<div class="vct-agenda vct-acc-cal-unified vct-cal-c vct-pv-agc" data-vct-agenda-root data-pv-agroot data-vct-feriados="' + escH(host.getAttribute("data-pv-agfer") || "[]") +
            '" data-vct-calendar-events="' + escH(host.getAttribute("data-pv-agevt") || "[]") + '">' +
            '<div class="vct-agenda-toolbar"><div class="vct-agenda-nav"><button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>' +
            '<h2 class="vct-agenda-title" data-vct-agenda-title></h2><button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button></div>' +
            '<div class="vct-agenda-view-toggle"><button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>' +
            '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button><button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">Día</button></div>' +
            '<div class="vct-agenda-jump vct-cal-hide"><select class="vct-select" data-vct-agenda-select-month>' + mo + '</select><select class="vct-select" data-vct-agenda-select-year></select></div></div>' +
            '<div class="vct-agenda-legend">' + leg.map(function (l) { return '<span class="vct-agenda-legend-item" style="--c:' + l[1] + '"><i style="background:' + l[1] + '"></i>' + l[0] + "</span>"; }).join("") +
            '<span class="vct-agenda-legend-item" data-vct-cal-ro><i class="vct-cal-dot-ro"></i>No editable (pasado, sábado y domingo)</span></div>' +
            '<div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div></div>';
        document.dispatchEvent(new Event("vct:content-loaded"));
        var rt = host.querySelector("[data-pv-agroot]");
        setTimeout(function () { agCalNav(rt); agCalPlus(rt); }, 0);
        try { new MutationObserver(function () { agCalPlus(rt); }).observe(rt.querySelector("[data-vct-agenda-view-pane]"), { childList: true }); } catch (e) { }
        icons(host);
    }
    /* barra como el resto de los calendarios:  < Mes >  |  Mes Semana Dia  |  < Anio > */
    function agCalNav(rt) {
        if (!rt || rt.querySelector(".vct-cal-navgroup")) return;
        var title = rt.querySelector("[data-vct-agenda-title]"), selY = rt.querySelector("[data-vct-agenda-select-year]");
        var nav = title ? title.parentNode : null, tb = rt.querySelector(".vct-agenda-toolbar"), tg = rt.querySelector(".vct-agenda-view-toggle");
        if (!nav || !tb) return;
        var grp = document.createElement("div");
        grp.className = "vct-cal-navgroup";
        nav.classList.add("vct-cal-stp");
        grp.appendChild(nav);
        if (tg) { tg.classList.add("vct-cal-seg"); grp.appendChild(tg); }
        var ys = document.createElement("div");
        ys.className = "vct-cal-stp is-year";
        ys.innerHTML = '<button type="button" class="vct-cal-stp-btn" data-pv-agy="-1" aria-label="Año anterior">‹</button><span class="vct-cal-stp-lbl" data-pv-agylbl></span>' +
            '<button type="button" class="vct-cal-stp-btn" data-pv-agy="1" aria-label="Año siguiente">›</button>';
        grp.appendChild(ys);
        tb.appendChild(grp);
        var yl = ys.querySelector("[data-pv-agylbl]");
        function sync() {
            var t = title.textContent || "", mm = /\s(\d{4})$/.exec(t);
            if (mm) { yl.textContent = mm[1]; title.textContent = t.replace(/\s\d{4}$/, ""); }
            else if (!yl.textContent) yl.textContent = (selY && selY.value) || String(new Date().getFullYear());
        }
        sync();
        try { new MutationObserver(sync).observe(title, { childList: true, characterData: true, subtree: true }); } catch (e) { }
        ys.addEventListener("click", function (ev) {
            var b = ev.target.closest("[data-pv-agy]");
            if (!b || !selY) return;
            var y = (parseInt(yl.textContent, 10) || new Date().getFullYear()) + parseInt(b.getAttribute("data-pv-agy"), 10), has = false;
            for (var i = 0; i < selY.options.length; i++) if (selY.options[i].value === String(y)) has = true;
            if (!has) { var o = document.createElement("option"); o.value = String(y); o.textContent = String(y); selY.appendChild(o); }
            selY.value = String(y);
            try { selY.dispatchEvent(new Event("change", { bubbles: true })); } catch (e) { }
        });
        icons(rt);
    }
    /* "+" en los dias habiles desde hoy que no son feriado (con permiso) */
    function agCalPlus(rt) {
        var host = rt ? rt.closest("[data-pv-agcal]") : null;
        if (!host || host.getAttribute("data-pv-agcal-edit") !== "1") return;
        rt.querySelectorAll("td.vct-agenda-cell[data-vct-agenda-day]").forEach(function (td) {
            var ro = /vct-agenda-cell-(past|weekend|holiday|holiday-puente)\b/.test(td.className);
            td.classList.toggle("vct-pv-ag-ed", !ro);
            var b = td.querySelector(".vct-pv-ag-add");
            if (ro) { if (b) b.parentNode.removeChild(b); return; }
            if (!b) {
                b = document.createElement("button");
                b.type = "button";
                b.className = "vct-pv-ag-add";
                var dk = (td.getAttribute("data-vct-agenda-day") || "").split("-");
                b.title = "Agregar visita el " + (dk.length === 3 ? dk[2] + "/" + dk[1] : "");
                b.textContent = "+";
                td.appendChild(b);
            }
        });
    }
    /* clic en un dia editable (fuera de una visita): abre el alta con esa fecha; antes que el motor (vista dia) */
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        var td = t.closest("[data-pv-agroot] td.vct-pv-ag-ed");
        if (!td || (t.closest(".vct-agenda-event") && !t.closest(".vct-pv-ag-add"))) return;
        e.preventDefault();
        e.stopPropagation();
        agOpen(td, td.getAttribute("data-vct-agenda-day"), null);
    }, true);
    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        var v = t.closest("[data-pv-agv]");
        if (v) {
            e.preventDefault();
            var box = v.closest("[data-pv-agbox]");
            if (!box) return;
            box.querySelectorAll("[data-pv-agv]").forEach(function (b) { b.classList.toggle("is-on", b === v); });
            box.querySelectorAll("[data-pv-agpane]").forEach(function (p) { p.hidden = p.getAttribute("data-pv-agpane") !== v.getAttribute("data-pv-agv"); });
            if (v.getAttribute("data-pv-agv") === "cal") agCalMount(box);
            return;
        }
        var gr = t.closest("tr.vct-pv-agg-g");
        if (gr) {
            var host = gr.closest("[data-vct-dg]"), k = gr.getAttribute("data-k"), op = !gr.classList.contains("is-open");
            if (host) { host.__agOpen = host.__agOpen || {}; host.__agOpen[k] = op; }
            gr.classList.toggle("is-open", op);
            var n = gr.nextElementSibling;
            while (n && !n.classList.contains("vct-pv-agg-g")) { n.classList.toggle("is-hidden", !op); n = n.nextElementSibling; }
            return;
        }
        var nw = t.closest("[data-pv-ag-new]");
        if (nw) { e.preventDefault(); agOpen(nw, "", null); return; }
        var ed = t.closest("[data-pv-ag-edit]");
        if (ed) { e.preventDefault(); agOpen(ed, "", ed); return; }
        var del = t.closest("[data-pv-ag-del]");
        if (del) {
            e.preventDefault();
            if (!window.confirm("¿Eliminar esta visita?\n\n" + (del.getAttribute("data-nombre") || "") + "\n\nSe libera la agenda del consultor.")) return;
            enviar(del, "PV_AG_BORRAR", del.getAttribute("data-pv-ag-del") || "0", {}, "agenda");
            return;
        }
        var m = t.closest('[data-vct-pv-modal="ag"]');
        if (!m || !ag) return;
        var sv = t.closest("[data-pv-ag-save]");
        if (sv && !sv.disabled) { e.preventDefault(); agGuardar(sv); return; }
        var es = t.closest("[data-pv-ag-est] [data-v]");
        if (es) { e.preventDefault(); ag.est = es.getAttribute("data-v"); agRender(m); return; }
        var st = t.closest("[data-pv-ag-svt]");
        if (st) { e.preventDefault(); agServ(m, st.getAttribute("data-pv-ag-svt"), ""); agRender(m); return; }
        var nr = t.closest("[data-pv-ag-nor]");
        if (nr) { e.preventDefault(); var k2 = nr.getAttribute("data-pv-ag-nor"); ag.nor[k2] = !ag.nor[k2]; agRender(m); return; }
        var ea = t.closest("[data-pv-ag-emadd]");
        if (ea) {
            e.preventDefault();
            var cid = ea.getAttribute("data-pv-ag-emadd");
            ag.emails[cid] = ag.emails[cid] || "";
            agNotif(m, agSel(m));
            var inp = m.querySelector('[data-pv-ag-em="' + cid + '"]');
            if (inp) inp.focus();
            return;
        }
        if (t.closest("[data-pv-agc-otros]")) { e.preventDefault(); ag.otros = !ag.otros; agRender(m); return; }
        var tr = t.closest("tr[data-pv-agc]");
        if (tr && !t.closest("input")) {
            e.preventDefault();
            if (!tr.classList.contains("is-selected") && ag.id && agSel(m).length >= ag.max) {
                agToast("Al editar, la visita conserva su cantidad de consultores. Para sumar otro consultor use Agregar.");
                return;
            }
            tr.classList.toggle("is-selected");
            agHoras(m, false);
            agRender(m);
        }
    });
    document.addEventListener("change", function (e) {
        var t = e.target;
        var m = t && t.closest ? t.closest('[data-vct-pv-modal="ag"]') : null;
        if (!m || !ag || ag.busy) return;
        if (t.matches('[data-pv-ag-f="desde"]')) {
            ag.desde = parseISO(t.value);
            if (ag.desde && (!ag.hasta || ag.hasta < ag.desde)) { ag.hasta = ag.desde; agSetDate(agF(m, "hasta"), t.value); }
            agHoras(m, true); agRender(m); return;
        }
        if (t.matches('[data-pv-ag-f="hasta"]')) { ag.hasta = parseISO(t.value); agHoras(m, true); agRender(m); return; }
        if (t.matches("[data-pv-ag-ps]")) { agInst(m, t); agRender(m); return; }
        if (t.matches('[data-pv-ag-f="mail"]')) { agRender(m); return; }
        if (t.matches("[data-pv-agc-h]")) {
            var max = agDias() * 8, v = agNum(t.value);
            if (max && v > max) t.value = String(max);
            t.setAttribute("data-user", "1");
            agRender(m);
        }
    });
    document.addEventListener("input", function (e) {
        var t = e.target;
        if (!t || !t.matches) return;
        if (t.matches("[data-pv-ag-buscar]")) { agRender(t.closest('[data-vct-pv-modal="ag"]')); return; }
        if (t.matches("[data-pv-ag-em]") && ag) ag.emails[t.getAttribute("data-pv-ag-em")] = t.value;
        if (t.matches('[data-pv-ag-f="cc"]') && ag) agGen(t.closest('[data-vct-pv-modal="ag"]'), agSel(t.closest('[data-vct-pv-modal="ag"]')));
    });

    window.VCTProyectoV360 = { version: 1, open: openModal, close: closeModal };
})(window, document);

/* v7: quitar la marca roja del email al escribir */
document.addEventListener("input", function (e) {
    var t = e.target;
    if (t && t.matches && t.matches("[data-vct-pv-email].is-invalid") && t.value.trim()) t.classList.remove("is-invalid");
});
