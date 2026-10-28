/* vct-proyecto-v360.js - v44 DES_PLAN_V2 (planificar: primero pasar a realizado o eliminar lo planificado para visitas de hoy o anteriores)
   v43 (desarrollo: aviso de adelantada con la fecha de la visita y la del inicio de la accion)
   v42 VIS_SRV_V3 (Desarrollo: sin aviso para auditorias / capacitaciones; filtro Consultor solo si hay opciones)
   v41 VIS_SRV_V2 (Visitas: los chips y el filtro Servicio valen para Lista y Desarrollo; indicadores de Desarrollo por servicio)
   v40 VIS_SRV_V1 (Visitas: chips por tipo de servicio, filtro Servicio con su resumen, columna Desarrollos, vista Desarrollo)
   v39 PL_DES_V7 (accion: estado en chips (automatico Pendiente / En proceso + En espera, Cumplida, Cancelada), resultado al lado, responsable a todo el ancho y sin analista; subitem desde el arbol)
   v38 PL_DES_V6 (estado de la accion: cumplida exige desarrollo realizado; cancelada solo sin desarrollo; aviso dentro del modal)
   v37 PL_DES_V5 (opcion B: desarrollo realizado antes del inicio = accion adelantada; planificado dentro del rango de la accion)
   v36 PL_DES_V4 (accion del plan: fechas fuera del rango del item se avisan dentro del modal)
   v35 PL_DES_V3 (accion: Detalle -> Descripcion; desarrollo: item / subitem de la accion, no editables)
   v34 PL_DES_V2 (accion del plan: responsable alineado, aviso que se limpia al completar, errores del servidor en toast)
   v33 PL_DES_V1 (desarrollo de acciones del plan, plan desde Excel, eliminar plan, trabajo de la visita)
   v32 PV_AGENDA_V1 (permiso del plan, calendario pendiente / confirmada, modal del boceto)
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
        if (key === "pa") paPrep(m, btn, !!edit);   /* PL_DES_V1 */
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
        /* v36: accion del plan: inicio / vence dentro del rango del item (mismo control que el servidor, pero dentro del modal) */
        if (m.getAttribute("data-vct-pv-modal") === "pa") {
            var fI = m.querySelector('[data-vct-pv-f="ini"]'), fV = m.querySelector('[data-vct-pv-f="vence"]');
            var vi = fI ? String(fI.value || "") : "", vv = fV ? String(fV.value || "") : "";
            var mn = fI ? fI.getAttribute("min") || "" : "", mx = fI ? fI.getAttribute("max") || "" : "";
            var bad = function (f, msg) { errs.push(msg); if (f) f.classList.add("is-invalid"); };
            if (vi && mn && vi < mn) bad(fI, "La acci&oacute;n no puede empezar antes del inicio del &iacute;tem (" + fmtD(mn) + ").");
            if (vv && mx && vv > mx) bad(fV, "La acci&oacute;n no puede vencer despu&eacute;s del fin del &iacute;tem (" + fmtD(mx) + ").");
            if (vi && vv && vv < vi) bad(fV, "Vence no puede ser anterior a la fecha de inicio.");
            /* v38: cumplida solo con desarrollo realizado; cerrada sin cumplir (cancelada) solo sin desarrollo realizado */
            var fE = m.querySelector('[data-vct-pv-f="est"]'), oE = fE && fE.selectedIndex >= 0 ? fE.options[fE.selectedIndex] : null;
            if (oE && m.getAttribute("data-vct-pv-mode") === "edit") {
                var cod = oE.getAttribute("data-cod") || "", fin = oE.getAttribute("data-final") === "1";
                var nd = parseInt(m.getAttribute("data-pv-nd") || "0", 10) || 0, est0 = m.getAttribute("data-pv-est0") || "";
                if (cod === "CUMPLIDA" && nd === 0 && est0 !== fE.value)
                    bad(fE, "Para cumplir la acci&oacute;n carg&aacute; primero su desarrollo realizado.");
                if (fin && cod !== "CUMPLIDA" && nd > 0)
                    bad(fE, "La acci&oacute;n tiene " + (m.getAttribute("data-pv-hs") || "") + " h de desarrollo realizado: no se puede cancelar. Elimin&aacute; primero su desarrollo.");
            }
        }
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
        /* visitas: chips por tipo de servicio y filtro Servicio (VIS_SRV_V1) */
        setTimeout(function () { agChipsInit(r); }, 350);
        /* plan: reabre el desarrollo de la accion que se estaba cargando (PL_DES_V1) */
        setTimeout(function () { desRestore(r); }, 700);
        /* v34: error del servidor al grabar: ademas del aviso de arriba, toast (no pasa desapercibido) */
        var ale = r.querySelector("[data-vct-pv-alert].is-error");
        if (ale && window.VCT && VCT.Toast && typeof VCT.Toast.show === "function") setTimeout(function () { VCT.Toast.show(ale.textContent.trim(), "error"); }, 400);
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
        /* v40: con un servicio elegido no hacen falta las filas de grupo (el resumen esta arriba) */
        var fInst = host.querySelector('select[data-vct-dg-filter="inst"]');
        if (fInst && fInst.value) return;
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

    /* ================= PL_DES_V1 (v33): desarrollo de las acciones del plan, plan desde Excel, trabajo de la visita ================= */
    function fmtH(n) { n = Math.round((+n || 0) * 10) / 10; return String(n); }
    function fmtD(iso) { var x = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso || ""); return x ? x[3] + "/" + x[2] + "/" + x[1] : ""; }
    function pvRoot(el) { return (el && el.closest && el.closest("[data-vct-pv]")) || root(); }
    function pvModal(el, key) { var r = pvRoot(el); return r ? r.querySelector('[data-vct-pv-modal="' + key + '"]') : null; }
    function mOpen(m) { m.classList.add("is-open"); document.body.classList.add("vct-modal-open"); icons(m); }

    /* -- accion del plan: inicio obligatorio, nace Pendiente (estado y resultado solo al editar), rango del item -- */
    function paPrep(m, btn, edit) {
        /* v38: desarrollo realizado de la accion y su estado al abrir (para validar el cambio de estado) */
        m.setAttribute("data-pv-nd", edit ? (btn.getAttribute("data-f-nd") || "0") : "0");
        m.setAttribute("data-pv-hs", edit ? (btn.getAttribute("data-f-hs") || "0") : "0");
        m.setAttribute("data-pv-est0", edit ? (btn.getAttribute("data-f-est") || "") : "");
        /* v35: el campo de texto libre de la accion es su descripcion */
        var ob = m.querySelector('[data-vct-pv-f="obs"]'), obf = ob ? ob.closest(".vct-field") : null, obl = obf ? obf.querySelector(".vct-label") : null;
        if (obl) obl.innerHTML = "Descripci&oacute;n";
        var ini = m.querySelector('[data-vct-pv-f="ini"]'), vence = m.querySelector('[data-vct-pv-f="vence"]');
        if (ini) {
            ini.setAttribute("data-req", "Fecha inicio");
            var fi = ini.closest(".vct-field"), lb = fi ? fi.querySelector(".vct-label") : null;
            if (lb && !lb.querySelector(".vct-req")) lb.insertAdjacentHTML("beforeend", ' <span class="vct-req">*</span>');
        }
        ["[data-vct-pv-estado]", "[data-vct-pv-resultado]"].forEach(function (q) {
            var x = m.querySelector(q), f = x ? x.closest(".vct-field") : null;
            if (f) f.hidden = !edit;
        });
        var rg = String(btn.getAttribute("data-rng") || "").split("|");
        var h = m.querySelector("[data-pv-pa-rng]");
        var fv = vence ? vence.closest(".vct-field") : null;
        if (!h && fv) {
            fv.insertAdjacentHTML("afterend", '<div class="vct-field vct-col-12"><div class="vct-help vct-pv-pa-rng" data-pv-pa-rng></div></div>');
            h = m.querySelector("[data-pv-pa-rng]");
        }
        if (h) {
            var t = (rg[0] || rg[1]) ? "Inicio y vence dentro del &iacute;tem: " + (fmtD(rg[0]) || "-") + " al " + (fmtD(rg[1]) || "-") + ". " : "";
            if (!edit) t += "La acci&oacute;n nace Pendiente; el estado se cambia despu&eacute;s con Editar, en cualquier momento.";
            h.innerHTML = t;
            h.parentNode.hidden = !t;
        }
        /* v34: la celda vacia de relleno desacomodaba Responsable (quedaba al medio) */
        Array.prototype.forEach.call(m.querySelectorAll(".vct-form-grid > .vct-field"), function (c) {
            if (!c.children.length && !c.textContent.trim()) c.hidden = true;
        });
        [ini, vence].forEach(function (x) {
            if (!x) return;
            if (rg[0]) x.setAttribute("min", rg[0]); else x.removeAttribute("min");
            if (rg[1]) x.setAttribute("max", rg[1]); else x.removeAttribute("max");
        });
        /* v39: estado (chips) y resultado debajo de las fechas; responsable a todo el ancho */
        var fEst = m.querySelector('[data-vct-pv-f="est"]'), fRes = m.querySelector('[data-vct-pv-f="res"]'), fResp = m.querySelector('[data-vct-pv-f="resp"]');
        var cEst = fEst ? fEst.closest(".vct-field") : null, cRes = fRes ? fRes.closest(".vct-field") : null;
        var cResp = fResp ? fResp.closest(".vct-field") : null, cOtro = m.querySelector("[data-vct-pv-otro]");
        var hRow = h ? h.closest(".vct-field") : null;
        if (cEst && cRes && hRow && !m.hasAttribute("data-pv-pa-lay")) {
            m.setAttribute("data-pv-pa-lay", "1");
            hRow.parentNode.insertBefore(cEst, hRow.nextSibling);
            cEst.parentNode.insertBefore(cRes, cEst.nextSibling);
            cEst.classList.remove("vct-col-4"); cEst.classList.add("vct-col-8", "has-chips");
            cEst.insertAdjacentHTML("beforeend", '<div class="vct-pv-pa-est" data-pv-pa-est></div><div class="vct-help">Pendiente / En proceso los define el desarrollo realizado. Eleg&iacute; En espera, Cumplida o Cancelada solo cuando corresponda.</div>');
        }
        [cResp, cOtro].forEach(function (c) { if (c) { c.classList.remove("vct-col-6"); c.classList.add("vct-col-12"); } });
        /* v39: el analista no es responsable de las acciones del plan (si ya lo era, se mantiene visible) */
        if (fResp) {
            var cur = fResp.value;
            Array.prototype.forEach.call(fResp.options, function (o) {
                var off = o.getAttribute("data-rol") === "ANALISTA" && o.value !== cur;
                o.hidden = off; o.disabled = off;
            });
            var w = fResp.parentNode ? fResp.parentNode.querySelector(".vct-form-select") : null, menu = w ? w.__vctPortalMenu : null;
            if (menu) menu.querySelectorAll(".vct-form-select-option").forEach(function (d) {
                var v = d.getAttribute("data-value"), o = null;
                Array.prototype.forEach.call(fResp.options, function (x) { if (x.value === v) o = x; });
                if (o && o.disabled) d.style.setProperty("display", "none", "important"); else d.style.removeProperty("display");
            });
        }
        paEst(m);
    }
    /* v39: estado de la accion en chips: el automatico (Pendiente / En proceso, segun el desarrollo realizado) y los que se eligen */
    function paEst(m) {
        var sel = m.querySelector('[data-vct-pv-f="est"]'), box = m.querySelector("[data-pv-pa-est]");
        if (!sel || !box) return;
        var nd = parseInt(m.getAttribute("data-pv-nd") || "0", 10) || 0, autoCod = nd > 0 ? "EN_PROCESO" : "PENDIENTE";
        var opts = Array.prototype.filter.call(sel.options, function (o) { return !!o.value; });
        var auto = opts.filter(function (o) { return o.getAttribute("data-cod") === autoCod; })[0] || null;
        var man = opts.filter(function (o) { var c = o.getAttribute("data-cod") || ""; return c !== "PENDIENTE" && c !== "EN_PROCESO"; });
        var cur = sel.selectedIndex >= 0 ? sel.options[sel.selectedIndex] : null, curCod = cur ? cur.getAttribute("data-cod") || "" : "";
        var isAuto = !curCod || curCod === "PENDIENTE" || curCod === "EN_PROCESO";
        if (isAuto && auto && sel.value !== auto.value) { sel.value = auto.value; cur = auto; }
        var esc = function (x) { return String(x || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/"/g, "&quot;"); };
        box.innerHTML = (auto ? '<button type="button" class="vct-pv-pa-chip is-auto' + (isAuto ? " is-on" : "") + '" data-pv-pa-est-v="' + esc(auto.value) + '" title="Autom&aacute;tico: lo define el desarrollo realizado">' + esc(auto.text) + '<small>auto</small>' + "</button>" : "")
            + man.map(function (o) {
                var c = o.getAttribute("data-cod") || "", k = c === "CUMPLIDA" ? "is-ok" : c === "EN_ESPERA" ? "is-wait" : "is-canc";
                return '<button type="button" class="vct-pv-pa-chip ' + k + (cur && o.value === cur.value && !isAuto ? " is-on" : "") + '" data-pv-pa-est-v="' + esc(o.value) + '">' + esc(o.text) + "</button>";
            }).join("");
        var cRes = m.querySelector('[data-vct-pv-f="res"]');
        cRes = cRes ? cRes.closest(".vct-field") : null;
        var fin = !!(cur && cur.getAttribute("data-final") === "1");
        if (cRes) cRes.hidden = !(m.getAttribute("data-vct-pv-mode") === "edit" && fin);
    }
    document.addEventListener("click", function (e) {
        var b = e.target && e.target.closest ? e.target.closest("[data-pv-pa-est-v]") : null;
        if (!b) return;
        e.preventDefault();
        var m = b.closest("[data-vct-pv-modal]"), sel = m ? m.querySelector('[data-vct-pv-f="est"]') : null;
        if (!sel) return;
        var v = b.getAttribute("data-pv-pa-est-v");
        if (b.classList.contains("is-on") && !b.classList.contains("is-auto")) {
            var a = m.querySelector(".vct-pv-pa-chip.is-auto");
            v = a ? a.getAttribute("data-pv-pa-est-v") : v;
        }
        setVal(sel, v);
        paEst(m);
    });

    /* -- desarrollo de la accion: registros desplegables en el detalle del item -- */
    var REGS_KEY = "vct.pv.pl.regs";
    function awToggle(aw, open) {
        var regs = aw ? aw.querySelector("[data-pl-regs]") : null;
        if (!regs) return;
        var o = typeof open === "boolean" ? open : !aw.classList.contains("is-open");
        aw.classList.toggle("is-open", o);
        regs.hidden = !o;
        if (o) icons(regs);
    }
    function desRestore(r) {
        var k = "";
        try { k = sessionStorage.getItem(REGS_KEY) || ""; sessionStorage.removeItem(REGS_KEY); } catch (e) { }
        if (!k || !r) return;
        var aw = r.querySelector('[data-pl-aw="' + k + '"]');
        if (aw) awToggle(aw, true);
    }

    /* -- modal de desarrollo (realizado / planificado) -- */
    var des = null;
    function desVis(m) {
        return String(m.getAttribute("data-pv-des-vis") || "").split(";").filter(Boolean).map(function (s) {
            var p = s.split("|");
            return { vc: p[0], d1: p[1] || "", d2: p[2] || "", est: p[3] || "P", srv: p[4] || "", ini: p[5] || "", nom: p[6] || "",
                     h: parseFloat(p[7]) || 0, u: parseFloat(p[8]) || 0, mio: p[9] === "1" };
        });
    }
    function desF(k) { return des && des.m ? des.m.querySelector('[data-pv-des-f="' + k + '"]') : null; }
    function desOpen(btn, edit) {
        var m = pvModal(btn, "des");
        if (!m) return;
        var acc = edit ? btn.getAttribute("data-acc") : btn.getAttribute("data-pl-des-new");
        var aw = pvRoot(btn).querySelector('[data-pl-aw="' + acc + '"]');
        var tt = aw ? aw.querySelector(".vct-plt-acc-t b") : null;
        var tipo = edit ? (btn.getAttribute("data-f-tipo") || "R") : "R";
        des = { m: m, id: edit ? (btn.getAttribute("data-pl-des-edit") || "") : "", acc: acc || "", tipo: tipo,
                vc: edit ? (btn.getAttribute("data-f-vc") || "") : "", vcOrig: edit ? (btn.getAttribute("data-f-vc") || "") : "",
                hOrig: edit && tipo === "R" ? (parseFloat(btn.getAttribute("data-f-hrs")) || 0) : 0,
                tOrig: edit ? tipo : "" };
        /* v37: rango de la accion (inicio / vence) para el planificado y el aviso de adelantada */
        var eb = aw ? aw.querySelector('[data-vct-pv-edit="pa"]') : null;
        des.ai = eb ? eb.getAttribute("data-f-ini") || "" : "";
        des.av = eb ? eb.getAttribute("data-f-vence") || "" : "";
        var a = m.querySelector("[data-pv-des-acc]");
        if (a) a.value = tt ? tt.textContent : "";
        desItem(m, aw, a);
        var ti = m.querySelector("[data-pv-des-mtitle]");
        if (ti) ti.innerHTML = edit ? "Editar desarrollo" : "Nuevo desarrollo";
        [["hrs", "data-f-hrs"], ["tit", "data-f-tit"], ["des", "data-f-des"], ["prox", "data-f-prox"]].forEach(function (x) {
            var f = desF(x[0]);
            if (f) { f.value = edit ? (btn.getAttribute(x[1]) || "") : ""; f.classList.remove("is-invalid"); }
        });
        showError(m, null);
        var sv = m.querySelector("[data-pv-des-save]");
        if (sv) sv.disabled = false;
        desRender();
        mOpen(m);
        try { sessionStorage.setItem(REGS_KEY, des.acc); } catch (e) { }
    }
    /* v35: item (y subitem) de la accion, no editables, antes de la descripcion */
    function desItem(m, aw, a) {
        var af = a ? a.closest(".vct-field") : null;
        if (!af) return;
        var lb = af.querySelector(".vct-label");
        if (lb) lb.innerHTML = "Descripci&oacute;n de la acci&oacute;n";
        var box = m.querySelector("[data-pv-des-it]");
        if (!box) {
            af.insertAdjacentHTML("beforebegin", '<div class="vct-field vct-col-12 vct-pv-des-it" data-pv-des-it></div>');
            box = m.querySelector("[data-pv-des-it]");
        }
        var det = aw ? aw.closest("[data-pl-det]") : null, r = pvRoot(aw || m);
        var tx = function (d) { var h = d ? d.querySelector(".vct-plt-det-tt h4") : null; return h ? h.textContent.replace(/\s+/g, " ").trim() : ""; };
        var id = det ? det.getAttribute("data-pl-det") : "", item = tx(det), sub = "";
        /* v39: el subitem trae el id de su item (data-pl-padre); si no, se busca en la lista vieja */
        var pid = det ? det.getAttribute("data-pl-padre") || "" : "";
        var pd = pid && r ? r.querySelector('[data-pl-det="' + pid + '"]') : null;
        if (!pd) { var sl = id && r ? r.querySelector('.vct-plt-subl[data-pl-sel="' + id + '"]') : null; pd = sl ? sl.closest("[data-pl-det]") : null; }
        if (pd && pd !== det) { sub = item; item = tx(pd); }
        var esc = function (x) { return String(x || "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;"); };
        var fld = function (l, v, cls) { return '<div class="' + cls + '"><label class="vct-label">' + l + '</label><input type="text" class="vct-input" readonly value="' + esc(v) + '"></div>'; };
        box.innerHTML = sub ? '<div class="vct-pv-des-it2">' + fld("&Iacute;tem", item, "") + fld("Sub&iacute;tem", sub, "") + '</div>'
                            : fld("&Iacute;tem", item, "");
        box.hidden = !item;
    }
    /* v44 DES_PLAN_V2: planificado de visitas de hoy o anteriores que sigue sin pasar a realizado (el que se edita no cuenta si ya era planificado) */
    function desPend() {
        if (!des) return [];
        var own = des.tOrig === "P" ? des.id : "";
        return String(des.m.getAttribute("data-pv-des-pend") || "").split(",").filter(Boolean).map(function (x) {
            var p = x.split(":"); return { id: p[0], d: p[1] || "" };
        }).filter(function (x) { return x.id !== own; });
    }
    function desRender() {
        if (!des) return;
        var m = des.m, hoy = m.getAttribute("data-pv-des-hoy") || "", R = des.tipo === "R";
        m.querySelectorAll("[data-pv-des-tipo] [data-v]").forEach(function (b) { b.classList.toggle("is-on", b.getAttribute("data-v") === des.tipo); });
        var th = m.querySelector("[data-pv-des-thelp]");
        if (th) th.innerHTML = R ? "Lo que se trabaj&oacute; en una visita confirmada de hoy o anterior, con sus horas."
                                 : "Lo que se va a trabajar en una pr&oacute;xima visita (sin horas).";
        var pend = R ? [] : desPend();
        if (th && pend.length)
            th.innerHTML += '<br><span class="vct-pv-des-adel">Hay ' + pend.length + " desarrollo" + (pend.length === 1 ? "" : "s") + " planificado" + (pend.length === 1 ? "" : "s")
                + " para visitas de hoy o anteriores (" + pend.map(function (x) { return fmtD(x.d).slice(0, 5); }).filter(function (d, i, a) { return a.indexOf(d) === i; }).join(", ")
                + "): pasalo" + (pend.length === 1 ? "" : "s") + " a realizado o eliminalo" + (pend.length === 1 ? "" : "s") + " antes de planificar otro.</span>";
        var list = desVis(m).filter(function (v) {
            if (R) return v.est === "C" && v.d1 <= hoy;
            return v.d1 > hoy && (!des.ai || v.d1 >= des.ai) && (!des.av || v.d1 <= des.av);   /* v37: planificado dentro del rango de la accion */
        });
        list.sort(function (a, b) {
            if (a.mio !== b.mio) return a.mio ? -1 : 1;
            return R ? (a.d1 < b.d1 ? 1 : a.d1 > b.d1 ? -1 : 0) : (a.d1 < b.d1 ? -1 : a.d1 > b.d1 ? 1 : 0);
        });
        if (des.vc && !list.some(function (v) { return v.vc === des.vc; })) des.vc = "";
        var sel = null;
        var box = m.querySelector("[data-pv-des-cards]");
        if (box) {
            if (!list.length) {
                box.innerHTML = '<div class="vct-360-empty">' + (R ? "No hay visitas confirmadas de hoy o anteriores en la agenda del proyecto."
                                                                    : "No hay visitas futuras" + ((des.ai || des.av) ? " dentro del rango de la acci&oacute;n (" + (fmtD(des.ai) || "-") + " al " + (fmtD(des.av) || "-") + ")" : "") + " en la agenda del proyecto.")
                              + " Las visitas se cargan en la pesta&ntilde;a Agenda.</div>";
            } else {
                box.innerHTML = list.map(function (v) {
                    var usadas = Math.max(0, v.u - (v.vc === des.vcOrig ? des.hOrig : 0));
                    var disp = Math.max(0, Math.round((v.h - usadas) * 10) / 10);
                    var on = v.vc === des.vc, lleno = R && disp <= 0 && !on;
                    if (on) sel = { v: v, disp: disp };
                    var pct = v.h > 0 ? Math.min(100, Math.round(usadas * 100 / v.h)) : 0;
                    return '<button type="button" class="vct-pv-des-v' + (on ? " is-on" : "") + (lleno ? " is-full" : "") + '" data-pv-des-vc="' + escH(v.vc) + '" data-disp="' + disp + '"' + (lleno ? " disabled" : "") + ">"
                         + '<span class="vct-pv-des-vt"><b>' + fmtD(v.d1) + (v.d2 > v.d1 ? " al " + fmtD(v.d2).slice(0, 5) : "") + "</b>"
                         + '<span class="vct-360-badge ' + (v.est === "C" ? 'is-active">Confirmada' : 'is-planned">Pendiente') + "</span></span>"
                         + "<small>" + escH(v.srv) + "</small>"
                         + '<span class="vct-pv-des-vn"><span class="vctdg-avatar is-c" title="' + escH(v.nom) + '">' + escH(v.ini) + "</span><span>" + escH(v.nom) + "</span></span>"
                         + (R ? '<span class="vct-pv-bar"><span class="is-plan" style="width:' + pct + '%"></span></span>'
                              + '<span class="vct-pv-des-vh"><span>Cargadas <b>' + fmtH(usadas) + " h</b> de " + fmtH(v.h) + ' h</span><span>Disponible <b>' + fmtH(disp) + " h</b></span></span>"
                            : '<span class="vct-pv-des-vh"><span>' + fmtH(v.h) + " h de visita</span></span>")
                         + "</button>";
                }).join("");
                icons(box);
            }
        }
        var hw = m.querySelector("[data-pv-des-hw]"), tw = m.querySelector("[data-pv-des-tw]");
        if (hw) hw.hidden = !R;
        if (tw) { tw.classList.toggle("vct-col-9", R); tw.classList.toggle("vct-col-12", !R); }
        var hh = m.querySelector("[data-pv-des-hhelp]");
        if (hh) hh.innerHTML = sel ? "M&aacute;ximo " + fmtH(sel.disp) + " h en esta visita" : "Eleg&iacute; la visita";
        /* v37: trabajo antes del inicio planificado: se permite y la accion queda marcada como adelantada */
        if (hh && sel && R && des.ai && sel.v.d1 < des.ai)
            hh.innerHTML += '<br><span class="vct-pv-des-adel">La visita (' + fmtD(sel.v.d1) + ") es anterior al inicio planificado de la acci&oacute;n (" + fmtD(des.ai) + "): la acci&oacute;n quedar&aacute; marcada como &laquo;Adelantada&raquo;.</span>";
        var dl = m.querySelector("[data-pv-des-dlbl]"), dr = m.querySelector("[data-pv-des-dreq]");
        if (dl) dl.innerHTML = R ? "Desarrollo &middot; qu&eacute; se hizo" : "Detalle &middot; qu&eacute; se va a trabajar";
        if (dr) dr.hidden = !R;
    }
    function desSave(btn) {
        if (!des) return;
        var m = des.m, errs = [], R = des.tipo === "R";
        var v = function (k) { var f = desF(k); return f ? String(f.value || "").trim() : ""; };
        var hrs = v("hrs").replace(",", "."), tit = v("tit"), tx = v("des"), prox = v("prox");
        ["hrs", "tit", "des"].forEach(function (k) { var f = desF(k); if (f) f.classList.remove("is-invalid"); });
        if (!R && desPend().length) errs.push("Hay desarrollos planificados para visitas de hoy o anteriores: pasalos a realizado o eliminalos antes de planificar otros.");
        if (!des.vc) errs.push("Visita es obligatoria: eleg&iacute; una visita.");
        if (R) {
            var n = parseFloat(hrs);
            if (!(n > 0)) { errs.push("Horas es obligatorio y debe ser mayor a cero."); desF("hrs").classList.add("is-invalid"); }
            else {
                var card = des.vc ? m.querySelector('[data-pv-des-vc="' + des.vc + '"]') : null;
                var disp = card ? parseFloat(card.getAttribute("data-disp")) || 0 : null;
                if (disp !== null && n > disp + 0.001) { errs.push("Horas: en esa visita quedan " + fmtH(disp) + " h disponibles."); desF("hrs").classList.add("is-invalid"); }
            }
            if (!tx) { errs.push("Desarrollo es obligatorio."); desF("des").classList.add("is-invalid"); }
        }
        if (!tit) { errs.push("T&iacute;tulo breve es obligatorio."); desF("tit").classList.add("is-invalid"); }
        if (errs.length) { showError(m, errs); return; }
        showError(m, null);
        enviar(btn, "PV_PL_DES_GUARDAR", des.id || "0", {
            TEXTO11: des.acc, TEXTO12: des.tipo, TEXTO13: des.vc, TEXTO14: R ? hrs : "",
            TEXTO15: tit.slice(0, 300), TEXTO16: tx.slice(0, 4000), TEXTO17: prox.slice(0, 1000)
        }, "plan");
    }

    /* -- plan desde Excel (.xlsx sin librerias; .csv) -- */
    var xls = null;
    function xlsOpen(btn) {
        var m = pvModal(btn, "xls");
        if (!m) return;
        xls = { m: m, rows: null, ok: false };
        var pv = m.querySelector("[data-pv-xls-prev]");
        if (pv) pv.innerHTML = "";
        var fi = m.querySelector("[data-pv-xls-file]");
        if (fi) fi.value = "";
        xlsBtn();
        showError(m, null);
        mOpen(m);
    }
    function xlsBtn() {
        if (!xls) return;
        var b = xls.m.querySelector("[data-pv-xls-save]"), l = xls.m.querySelector("[data-pv-xls-savelbl]");
        var n = xls.rows ? xls.rows.length : 0;
        if (b) b.disabled = !(xls.ok && n);
        if (l) l.textContent = n ? "Grabar plan (" + n + " filas)" : "Grabar plan";
    }
    function u16(b, o) { return b[o] | (b[o + 1] << 8); }
    function u32(b, o) { return (b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)) >>> 0; }
    function inflate(data) {
        if (typeof DecompressionStream === "undefined") return Promise.reject(new Error("sin DecompressionStream"));
        var ds = new DecompressionStream("deflate-raw");
        var out = new Blob([data]).stream().pipeThrough(ds);
        return new Response(out).arrayBuffer().then(function (ab) { return new Uint8Array(ab); });
    }
    function utf8(u) { try { return new TextDecoder("utf-8").decode(u); } catch (e) { var s = ""; for (var i = 0; i < u.length; i++) s += String.fromCharCode(u[i]); return s; } }
    /* lector de ZIP minimo: directorio central + deflate nativo del navegador */
    function zipFiles(buf) {
        var b = new Uint8Array(buf), eocd = -1;
        for (var i = b.length - 22; i >= Math.max(0, b.length - 66000); i--) if (u32(b, i) === 0x06054b50) { eocd = i; break; }
        if (eocd < 0) return Promise.reject(new Error("no es un .xlsx válido"));
        var n = u16(b, eocd + 10), off = u32(b, eocd + 16), files = {};
        for (var k = 0; k < n; k++) {
            if (u32(b, off) !== 0x02014b50) break;
            var meth = u16(b, off + 10), csize = u32(b, off + 20), nl = u16(b, off + 28), el = u16(b, off + 30), cl = u16(b, off + 32), lo = u32(b, off + 42);
            var name = utf8(b.subarray(off + 46, off + 46 + nl));
            var ds = lo + 30 + u16(b, lo + 26) + u16(b, lo + 28);
            files[name] = { m: meth, d: b.subarray(ds, ds + csize) };
            off += 46 + nl + el + cl;
        }
        return Promise.resolve({
            get: function (nm) {
                var f = files[nm];
                if (!f) return Promise.resolve(null);
                if (f.m === 0) return Promise.resolve(utf8(f.d));
                if (f.m === 8) return inflate(f.d).then(utf8);
                return Promise.reject(new Error("compresión no soportada"));
            }
        });
    }
    function xmlTxt(s) {
        return String(s || "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&apos;/g, "'")
            .replace(/&#(\d+);/g, function (a, d) { return String.fromCharCode(+d); })
            .replace(/&#x([0-9a-f]+);/gi, function (a, h) { return String.fromCharCode(parseInt(h, 16)); }).replace(/&amp;/g, "&");
    }
    function tTexts(x) { var r = [], re = /<(?:\w+:)?t(?:\s[^>]*)?>([\s\S]*?)<\/(?:\w+:)?t>/g, mm; while ((mm = re.exec(x))) r.push(xmlTxt(mm[1])); return r.join(""); }
    function colIdx(ref) { var l = String(ref || "").replace(/[0-9]/g, "").toUpperCase(), n = 0; for (var i = 0; i < l.length; i++) n = n * 26 + (l.charCodeAt(i) - 64); return n - 1; }
    function readXlsx(buf) {
        return zipFiles(buf).then(function (z) {
            return Promise.all([z.get("xl/workbook.xml"), z.get("xl/_rels/workbook.xml.rels"), z.get("xl/sharedStrings.xml")]).then(function (r) {
                var path = "xl/worksheets/sheet1.xml";
                var sh = /<(?:\w+:)?sheet\b[^>]*\br:id="([^"]+)"/.exec(r[0] || "");
                if (sh && r[1]) {
                    var rel = new RegExp('<Relationship\\b[^>]*Id="' + sh[1] + '"[^>]*>').exec(r[1]);
                    var tg = rel ? /Target="([^"]+)"/.exec(rel[0]) : null;
                    if (tg) path = tg[1].charAt(0) === "/" ? tg[1].slice(1) : "xl/" + tg[1].replace(/^\.\//, "");
                }
                var ss = [], re = /<(?:\w+:)?si>([\s\S]*?)<\/(?:\w+:)?si>/g, mm;
                while ((mm = re.exec(r[2] || ""))) ss.push(tTexts(mm[1]));
                return z.get(path).then(function (xml) {
                    if (!xml) throw new Error("no se encontró la primera hoja");
                    var rows = [], rr = /<(?:\w+:)?row\b([^>]*)>([\s\S]*?)<\/(?:\w+:)?row>/g, rm;
                    xml = xml.replace(/<(?:\w+:)?row\b[^>]*\/>/g, "");
                    while ((rm = rr.exec(xml))) {
                        var row = [], cr = /<(?:\w+:)?c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/(?:\w+:)?c>)/g, cm, pos = 0;
                        while ((cm = cr.exec(rm[2]))) {
                            var at = cm[1] || "", body = cm[2] || "";
                            var ref = /\br="([A-Z]+)\d*"/.exec(at), t = /\bt="([^"]+)"/.exec(at);
                            var ci = ref ? colIdx(ref[1]) : pos;
                            pos = ci + 1;
                            var vv = /<(?:\w+:)?v>([\s\S]*?)<\/(?:\w+:)?v>/.exec(body), val = "";
                            if (t && t[1] === "s") val = vv ? (ss[parseInt(vv[1], 10)] || "") : "";
                            else if (t && t[1] === "inlineStr") val = tTexts(body);
                            else val = vv ? xmlTxt(vv[1]) : "";
                            row[ci] = { v: val, n: !t || t[1] === "n" };
                        }
                        var rn = /\br="(\d+)"/.exec(rm[1]), ix = rn ? parseInt(rn[1], 10) - 1 : rows.length;
                        while (rows.length < ix) rows.push([]);
                        rows[ix] = row;
                    }
                    return rows;
                });
            });
        });
    }
    function readCsv(text) {
        text = String(text || "").replace(/^﻿/, "");
        var first = text.split(/\r?\n/)[0] || "";
        var sep = (first.match(/;/g) || []).length >= (first.match(/,/g) || []).length ? ";" : ",";
        if ((first.match(/\t/g) || []).length > (first.match(new RegExp(sep === ";" ? ";" : ",", "g")) || []).length) sep = "\t";
        var rows = [], row = [], cur = "", q = false;
        for (var i = 0; i < text.length; i++) {
            var ch = text.charAt(i);
            if (q) {
                if (ch === '"' && text.charAt(i + 1) === '"') { cur += '"'; i++; }
                else if (ch === '"') q = false;
                else cur += ch;
            } else if (ch === '"') q = true;
            else if (ch === sep) { row.push({ v: cur, n: false }); cur = ""; }
            else if (ch === "\n") { row.push({ v: cur.replace(/\r$/, ""), n: false }); rows.push(row); row = []; cur = ""; }
            else cur += ch;
        }
        if (cur !== "" || row.length) { row.push({ v: cur.replace(/\r$/, ""), n: false }); rows.push(row); }
        return rows;
    }
    function norm(s) { return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]/g, ""); }
    function cellDate(c) {
        if (!c) return "";
        var s = String(c.v == null ? "" : c.v).trim();
        if (!s) return "";
        if (/^\d+(\.\d+)?$/.test(s) && +s > 20000 && +s < 80000) {
            var d = new Date(Date.UTC(1899, 11, 30) + Math.floor(+s) * 86400000);
            return d.getUTCFullYear() + "-" + pad(d.getUTCMonth() + 1) + "-" + pad(d.getUTCDate());
        }
        var x = /^(\d{4})-(\d{1,2})-(\d{1,2})/.exec(s);
        if (x) return x[1] + "-" + pad(+x[2]) + "-" + pad(+x[3]);
        x = /^(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{2,4})$/.exec(s);
        if (x) { var y = +x[3]; if (y < 100) y += 2000; return y + "-" + pad(+x[2]) + "-" + pad(+x[1]); }
        return "?" + s;
    }
    function okISO(s) {
        var x = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || "");
        if (!x) return false;
        var d = new Date(+x[1], +x[2] - 1, +x[3]);
        return d.getFullYear() === +x[1] && d.getMonth() === +x[2] - 1 && d.getDate() === +x[3];
    }
    /* filas de la hoja -> filas del plan (codigo, titulo, desde, hasta) con su validacion */
    function xlsRows(raw, ini, fin) {
        var hi = -1, map = null;
        for (var i = 0; i < Math.min(raw.length, 25) && hi < 0; i++) {
            var mp = {};
            (raw[i] || []).forEach(function (c, j) {
                var k = norm(c && c.v);
                if (!k) return;
                if (mp.cod == null && /^(codigo|cod|numero|nro|item)$/.test(k)) mp.cod = j;
                else if (mp.tit == null && /^(titulo|descripcion|nombre|requisito)/.test(k)) mp.tit = j;
                else if (mp.d1 == null && /(desde|inicio)/.test(k)) mp.d1 = j;
                else if (mp.d2 == null && /(hasta|fin|vence|vencimiento)/.test(k)) mp.d2 = j;
            });
            if (mp.cod != null && mp.tit != null) { hi = i; map = mp; }
        }
        if (hi < 0) return { err: "No se encontr&oacute; la fila de t&iacute;tulos: el archivo tiene que tener las columnas C&oacute;digo y T&iacute;tulo (y Fecha desde / Fecha hasta)." };
        var out = [], seen = {};
        for (var r = hi + 1; r < raw.length; r++) {
            var row = raw[r] || [];
            var g = function (j) { var c = j == null ? null : row[j]; return c ? String(c.v == null ? "" : c.v).trim() : ""; };
            var cod = g(map.cod).replace(/\s+/g, "").replace(/\.$/, ""), tit = g(map.tit).replace(/[\t\r\n]+/g, " ");
            if (!cod && !tit) continue;
            var d1 = map.d1 == null ? "" : cellDate(row[map.d1]), d2 = map.d2 == null ? "" : cellDate(row[map.d2]);
            var niv = cod ? cod.split(".").length : 0, pad_ = cod.indexOf(".") >= 0 ? cod.slice(0, cod.lastIndexOf(".")) : "";
            out.push({ fila: r + 1, cod: cod, tit: tit, d1: d1, d2: d2, niv: niv, pad: pad_, err: "" });
        }
        out.forEach(function (x) { seen[x.cod] = (seen[x.cod] || 0) + 1; });
        var byCod = {};
        out.forEach(function (x) { if (!byCod[x.cod]) byCod[x.cod] = x; });
        out.forEach(function (x) {
            var e = "";
            if (!/^\d+(\.\d+){0,2}$/.test(x.cod)) e = "C&oacute;digo no v&aacute;lido (4, 4.1 o 4.1.1)";
            else if (!x.tit) e = "Falta el t&iacute;tulo";
            else if (seen[x.cod] > 1) e = "C&oacute;digo repetido";
            else if (x.niv === 3 && !(byCod[x.pad] && byCod[x.pad].niv === 2)) e = "Falta su &iacute;tem " + escH(x.pad);
            else if (x.niv > 1) {
                if (x.d1 && !okISO(x.d1)) e = "Fecha desde no v&aacute;lida";
                else if (x.d2 && !okISO(x.d2)) e = "Fecha hasta no v&aacute;lida";
                else if (x.d1 && x.d2 && x.d2 < x.d1) e = "Hasta anterior a desde";
                else if ((ini && x.d1 && x.d1 < ini) || (fin && x.d2 && x.d2 > fin)) e = "Fuera del proyecto (" + fmtD(ini) + " al " + fmtD(fin) + ")";
                else if (x.niv === 3) {
                    var p = byCod[x.pad];
                    if (p && ((x.d1 && p.d1 && x.d1 < p.d1) || (x.d2 && p.d2 && x.d2 > p.d2))) e = "Fuera del &iacute;tem " + escH(p.cod) + " (" + fmtD(p.d1) + " al " + fmtD(p.d2) + ")";
                }
            }
            x.err = e;
        });
        /* capitulo: fechas calculadas con sus items */
        out.forEach(function (x) {
            if (x.niv !== 1) return;
            var its = out.filter(function (y) { return y.niv === 2 && y.pad === x.cod; });
            var a = its.map(function (y) { return y.d1; }).filter(okISO).sort(), b = its.map(function (y) { return y.d2; }).filter(okISO).sort();
            x.c1 = a[0] || ""; x.c2 = b[b.length - 1] || "";
        });
        return { rows: out };
    }
    function xlsShow(res, fname) {
        var m = xls.m, pv = m.querySelector("[data-pv-xls-prev]");
        xls.rows = null; xls.ok = false;
        if (res.err) { pv.innerHTML = ""; showError(m, [res.err]); xlsBtn(); return; }
        var rows = res.rows, nerr = rows.filter(function (x) { return x.err; }).length;
        var cnt = function (n) { return rows.filter(function (x) { return x.niv === n; }).length; };
        if (!rows.length) { pv.innerHTML = ""; showError(m, ["El archivo no tiene filas para cargar."]); xlsBtn(); return; }
        showError(m, null);
        var nivL = ["", "Cap&iacute;tulo", "&Iacute;tem", "Sub&iacute;tem"];
        pv.innerHTML = '<div class="vct-pv-xls-file"><span data-vct-icon="file-text"></span><b>' + escH(fname) + "</b><span>" + rows.length + " filas le&iacute;das</span></div>"
            + '<div class="vct-pv-xls-cnt"><span class="vct-360-badge is-neutral">' + cnt(1) + " cap&iacute;tulos</span>"
            + '<span class="vct-360-badge is-neutral">' + cnt(2) + " &iacute;tems</span>"
            + '<span class="vct-360-badge is-neutral">' + cnt(3) + " sub&iacute;tems</span>"
            + '<span class="vct-360-badge is-active">' + (rows.length - nerr) + " correctas</span>"
            + (nerr ? '<span class="vct-360-badge is-cancel">' + nerr + " con error</span>" : "") + "</div>"
            + '<div class="vct-pv-xls-prev"><table><thead><tr><th>Fila</th><th>Nivel</th><th>C&oacute;digo</th><th>T&iacute;tulo</th><th>Desde</th><th>Hasta</th><th>Validaci&oacute;n</th></tr></thead><tbody>'
            + rows.map(function (x) {
                var d1 = x.niv === 1 ? x.c1 : x.d1, d2 = x.niv === 1 ? x.c2 : x.d2;
                var sd = function (d) { return d ? (d.charAt(0) === "?" ? escH(d.slice(1)) : fmtD(d)) : "&ndash;"; };
                return '<tr class="is-n' + (x.niv || 0) + (x.err ? " is-bad" : "") + '"><td>' + x.fila + "</td><td>" + (nivL[x.niv] || "-") + "</td><td>" + escH(x.cod) + '</td><td class="tt">' + escH(x.tit) + "</td>"
                     + "<td>" + sd(d1) + "</td><td>" + sd(d2) + "</td>"
                     + "<td>" + (x.err ? '<span class="vct-360-badge is-cancel">' + x.err + "</span>" : '<span class="vct-360-badge is-active">OK' + (x.niv === 1 ? " &middot; calculadas" : "") + "</span>") + "</td></tr>";
            }).join("") + "</tbody></table></div>"
            + (nerr ? '<div class="vct-pv-xls-msg is-err">Hay ' + nerr + " fila(s) con error: correg&iacute; el archivo y volv&eacute; a subirlo. No se graba nada hasta que todas est&eacute;n OK.</div>"
                    : '<div class="vct-pv-xls-msg is-ok">Todo correcto: al grabar se crea el plan con estas filas y la acci&oacute;n Carga del plan pasa a En proceso.</div>');
        icons(pv);
        xls.rows = rows; xls.ok = !nerr;
        xlsBtn();
    }
    function xlsRead(m, file) {
        if (!xls || xls.m !== m) xls = { m: m, rows: null, ok: false };
        var ini = m.getAttribute("data-pv-xls-ini") || "", fin = m.getAttribute("data-pv-xls-fin") || "";
        var name = file.name || "archivo", csv = /\.(csv|txt)$/i.test(name);
        var rd = new FileReader();
        rd.onload = function () {
            var p = csv ? Promise.resolve(readCsv(rd.result)) : readXlsx(rd.result);
            p.then(function (raw) { xlsShow(xlsRows(raw, ini, fin), name); })
             .catch(function (e) { xls.rows = null; xls.ok = false; xlsBtn(); showError(m, ["No se pudo leer el archivo: " + escH(e && e.message ? e.message : e) + ". Guardalo como .xlsx o .csv y prob&aacute; de nuevo."]); });
        };
        rd.onerror = function () { showError(m, ["No se pudo leer el archivo."]); };
        if (csv) rd.readAsText(file); else rd.readAsArrayBuffer(file);
    }
    function xlsTpl(btn) {
        var m = btn.closest("[data-vct-pv-modal]"), ini = m.getAttribute("data-pv-xls-ini") || "", cod = m.getAttribute("data-pv-xls-cod") || "";
        var d0 = parseISO(ini) || new Date(), f = function (n) { var d = new Date(d0.getFullYear(), d0.getMonth(), d0.getDate() + n); return pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + "/" + d.getFullYear(); };
        var rows = [["4", "Contexto de la organización", "", ""],
                    ["4.1", "Comprensión de la organización y de su contexto", f(0), f(28)],
                    ["4.1.1", "Cuestiones internas y externas", f(0), f(14)],
                    ["4.2", "Necesidades y expectativas de las partes interesadas", f(7), f(35)],
                    ["5", "Liderazgo", "", ""],
                    ["5.1", "Liderazgo y compromiso", f(21), f(49)]];
        var cols = [{ title: "Código", type: "text", width: 10 }, { title: "Título", type: "text", width: 60 }, { title: "Fecha desde", width: 14 }, { title: "Fecha hasta", width: 14 }];
        var fn = "plantilla_plan_" + cod.replace(/[^\w\-]/g, "");
        if (window.VCTExport && typeof window.VCTExport.excel === "function") {
            window.VCTExport.excel({ title: "Plan estratégico - plantilla", subtitle: "Proyecto (" + cod + "): complete Código, Título, Fecha desde y Fecha hasta", filename: fn, columns: cols, rows: rows, logo: false });
            return;
        }
        var csv = "﻿Código;Título;Fecha desde;Fecha hasta\r\n" + rows.map(function (r) { return r.map(function (c) { return '"' + String(c).replace(/"/g, '""') + '"'; }).join(";"); }).join("\r\n") + "\r\n";
        var a = document.createElement("a");
        a.href = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
        a.download = fn + ".csv";
        document.body.appendChild(a); a.click();
        setTimeout(function () { URL.revokeObjectURL(a.href); a.parentNode.removeChild(a); }, 1000);
    }
    function xlsSave(btn) {
        if (!xls || !xls.ok || !xls.rows || !xls.rows.length) return;
        var lines = xls.rows.map(function (x) {
            var cl = function (s) { return String(s || "").replace(/[\t\r\n]+/g, " ").trim(); };
            return cl(x.cod) + "\t" + cl(x.tit).slice(0, 400) + "\t" + (x.niv > 1 ? x.d1 : "") + "\t" + (x.niv > 1 ? x.d2 : "") + "\n";
        });
        var chunks = [], cur = "";
        lines.forEach(function (l) { if (cur.length + l.length > 3900) { chunks.push(cur); cur = ""; } cur += l; });
        if (cur) chunks.push(cur);
        if (chunks.length > 12) { showError(xls.m, ["El plan es demasiado grande para cargarlo de una vez (m&aacute;s de ~400 filas)."]); return; }
        var campos = {};
        for (var i = 0; i < 12; i++) campos["TEXTO" + (11 + i)] = chunks[i] || "";
        enviar(btn, "PV_PL_IMPORTAR", "0", campos, "plan");
    }

    /* -- agenda: trabajo de la visita (lista: menu; calendario: clic en la visita) -- */
    function agwOpen(el, id) {
        var m = pvModal(el, "agw");
        if (!m) return;
        var sec = null;
        m.querySelectorAll("[data-pv-agw]").forEach(function (s) { var on = s.getAttribute("data-pv-agw") === String(id); s.hidden = !on; if (on) sec = s; });
        if (!sec) return;
        var t = m.querySelector("[data-pv-agw-title]"), sb = m.querySelector("[data-pv-agw-sub]");
        if (t) t.textContent = sec.getAttribute("data-tit") || "Trabajo de la visita";
        if (sb) sb.textContent = sec.getAttribute("data-sub") || "";
        mOpen(m);
    }
    document.addEventListener("click", function (e) {
        var ev = e.target && e.target.closest ? e.target.closest(".vct-agenda-event[data-tt-x]") : null;
        if (!ev || !ev.closest("[data-pv-agcal]")) return;
        var m = pvModal(ev, "agw");
        if (!m) return;
        var x = ev.getAttribute("data-tt-x"), f = ev.getAttribute("data-tt-f") || "", hit = null;
        m.querySelectorAll("[data-pv-agw]").forEach(function (s) {
            if (!hit && s.getAttribute("data-x") === x && (!f || (s.getAttribute("data-d1") <= f && f <= s.getAttribute("data-d2")))) hit = s;
        });
        if (!hit) return;
        e.preventDefault();
        e.stopPropagation();
        agwOpen(ev, hit.getAttribute("data-pv-agw"));
    }, true);

    document.addEventListener("click", function (e) {
        var t = e.target && e.target.closest ? e.target : null;
        if (!t) return;
        var x = t.closest("[data-pl-dtg],.vct-pl-dchip");
        if (x && x.closest("[data-pl-aw]")) { e.preventDefault(); awToggle(x.closest("[data-pl-aw]")); return; }
        if ((x = t.closest("[data-pl-des-new]"))) { e.preventDefault(); desOpen(x, false); return; }
        if ((x = t.closest("[data-pl-des-edit]"))) { e.preventDefault(); desOpen(x, true); return; }
        if ((x = t.closest("[data-pv-des-tipo] [data-v]"))) { e.preventDefault(); if (des) { des.tipo = x.getAttribute("data-v"); desRender(); } return; }
        if ((x = t.closest("[data-pv-des-vc]"))) { e.preventDefault(); if (des && !x.disabled) { des.vc = x.getAttribute("data-pv-des-vc"); desRender(); } return; }
        if ((x = t.closest("[data-pv-des-save]"))) { e.preventDefault(); desSave(x); return; }
        if ((x = t.closest("[data-pl-xls-open]"))) { e.preventDefault(); xlsOpen(x); return; }
        if ((x = t.closest("[data-pv-xls-pick]"))) { e.preventDefault(); var fi = x.closest("[data-vct-pv-modal]").querySelector("[data-pv-xls-file]"); if (fi) { fi.value = ""; fi.click(); } return; }
        if ((x = t.closest("[data-pv-xls-tpl]"))) { e.preventDefault(); xlsTpl(x); return; }
        if ((x = t.closest("[data-pv-xls-save]"))) { e.preventDefault(); if (!x.disabled) xlsSave(x); return; }
        if ((x = t.closest("[data-pv-agw-open]"))) { e.preventDefault(); agwOpen(x, x.getAttribute("data-pv-agw-open")); return; }
    });
    document.addEventListener("change", function (e) {
        var t = e.target;
        if (t && t.matches && t.matches("[data-pv-xls-file]") && t.files && t.files[0]) xlsRead(t.closest("[data-vct-pv-modal]"), t.files[0]);
    });
    document.addEventListener("dragover", function (e) {
        var d = e.target && e.target.closest ? e.target.closest("[data-pv-xls-drop]") : null;
        if (!d) return;
        e.preventDefault();
        d.classList.add("is-over");
    });
    document.addEventListener("dragleave", function (e) {
        var d = e.target && e.target.closest ? e.target.closest("[data-pv-xls-drop]") : null;
        if (d) d.classList.remove("is-over");
    });
    document.addEventListener("drop", function (e) {
        var d = e.target && e.target.closest ? e.target.closest("[data-pv-xls-drop]") : null;
        if (!d) return;
        e.preventDefault();
        d.classList.remove("is-over");
        var f = e.dataTransfer && e.dataTransfer.files ? e.dataTransfer.files[0] : null;
        if (f) xlsRead(d.closest("[data-vct-pv-modal]"), f);
    });
    /* v34: al completar un campo marcado se le quita la marca; sin marcas, se oculta el aviso */
    function pvFix(e) {
        var f = e.target && e.target.closest ? e.target.closest("[data-vct-pv-modal] [data-vct-pv-f].is-invalid") : null;
        if (!f) return;
        var v = f.type === "checkbox" ? f.checked : String(f.value || "").trim();
        if (!v) return;
        f.classList.remove("is-invalid");
        var m = f.closest("[data-vct-pv-modal]");
        if (m && !m.querySelector("[data-vct-pv-f].is-invalid")) showError(m, null);
    }
    document.addEventListener("change", pvFix);
    document.addEventListener("input", pvFix);
    /* ================= VIS_SRV_V1 (v40): visitas por servicio ================= */
    var AGC_KEY = "vct.pv.ag.chip.";
    function agLista(box) { return box ? box.querySelector('[data-pv-agpane="lista"]') : null; }
    function agSel(scope, name) { return scope ? scope.querySelector('select[data-vct-dg-filter="' + name + '"]') : null; }
    function agProj(box) { var r = box ? box.closest("[data-vct-pv]") : null; return r ? r.getAttribute("data-vct-pv-proyecto") || "" : ""; }
    function agSetSel(s, v) {
        if (!s) return;
        s.value = v;
        try { s.dispatchEvent(new Event("change", { bubbles: true })); } catch (e) { }
        var w = s.nextElementSibling;
        if (w && w.classList && w.classList.contains("vct-custom-select") && window.VCT && VCT.Select && typeof VCT.Select.sync === "function") VCT.Select.sync(s, w);
    }
    function agInstOpts(s, t) {
        if (!s) return;
        var w = s.nextElementSibling;
        Array.prototype.forEach.call(s.options, function (o) {
            var off = !!o.value && !!t && o.getAttribute("data-t") !== t;
            o.hidden = off; o.disabled = off;
            if (w && w.querySelectorAll) w.querySelectorAll(".vct-custom-select-option").forEach(function (d) {
                if (d.getAttribute("data-value") === o.value) d.style.display = off ? "none" : "";
            });
        });
    }
    function agSave(box) {
        var l = agLista(box), on = box.querySelector("[data-pv-agchip].is-on"), ins = agSel(l, "inst");
        try { sessionStorage.setItem(AGC_KEY + agProj(box), JSON.stringify({ t: on ? on.getAttribute("data-pv-agchip") : "", i: ins ? ins.value : "" })); } catch (e) { }
    }
    function agPanes(box) {
        return ["lista", "des"].map(function (k) { return box.querySelector('[data-pv-agpane="' + k + '"]'); }).filter(function (x) { return !!x; });
    }
    function agChip(box, t, inst, keep) {
        var l = agLista(box);
        if (!l) return;
        box.querySelectorAll("[data-pv-agchip]").forEach(function (b) { b.classList.toggle("is-on", b.getAttribute("data-pv-agchip") === t); });
        var ins = agSel(l, "inst");
        if (inst === undefined) {
            var opts = ins ? Array.prototype.filter.call(ins.options, function (o) { return o.value && (!t || o.getAttribute("data-t") === t); }) : [];
            inst = t && opts.length === 1 ? opts[0].value : "";   /* un solo servicio del tipo: queda elegido */
        }
        /* v41: el tipo y el servicio valen para la Lista y para Desarrollo */
        agPanes(box).forEach(function (p) {
            var i2 = agSel(p, "inst");
            agInstOpts(i2, t);
            agSetSel(agSel(p, "servicio"), t);
            agSetSel(i2, inst || "");
        });
        agSum(box);
        agDesStats(box);
        if (!keep) agSave(box);
    }
    /* v41: indicadores de Desarrollo para el tipo / servicio elegido (datos de cada servicio en las opciones del filtro) */
    function agDesStats(box) {
        var st = box.querySelector("[data-pv-agdstats]"), ins = agSel(agLista(box), "inst");
        if (!st || !ins) return;
        var on = box.querySelector("[data-pv-agchip].is-on"), t = on ? on.getAttribute("data-pv-agchip") || "" : "", iv = ins.value;
        /* v42: auditorias y capacitaciones no tienen desarrollo: sin indicadores (la grilla queda vacia) */
        st.hidden = !!(t && t !== "co");
        if (st.hidden) { st.innerHTML = ""; return; }
        var hv = 0, dh = 0, nv = 0, nvd = 0, dp = 0, px = "";
        Array.prototype.forEach.call(ins.options, function (o) {
            if (!o.value || o.getAttribute("data-t") !== "co" || (iv && o.value !== iv)) return;
            var n = function (k) { return parseFloat(o.getAttribute("data-" + k) || "0") || 0; };
            hv += n("ejec"); dh += n("dh"); nv += n("nv"); nvd += n("nvd"); dp += n("dp");
            var p = o.getAttribute("data-px") || "";
            if (p && (!px || p < px)) px = p;
        });
        var card = function (tone, lab, val, sm, ic) {
            return '<div class="vct-360-stat" data-vct-tone="' + tone + '"><span class="vct-360-stat-main"><span class="vct-360-stat-label">' + lab + "</span><b>" + val + "</b><small>" + sm + "</small></span>"
                + '<span class="vct-360-stat-icon"><span data-vct-icon="' + ic + '"></span></span></div>';
        };
        var sin = Math.max(0, Math.round((hv - dh) * 10) / 10);
        st.innerHTML = card("blue", "Horas de visita", fmtH(hv) + " h", nv + " visita(s) &middot; " + nvd + " con desarrollo", "clock-3")
            + card("mint", "Volcadas en desarrollos", fmtH(dh) + " h", (hv > 0 ? Math.round(dh * 100 / hv) : 0) + " % de las horas de visita", "check")
            + card("amber", "Sin detallar", fmtH(sin) + " h", "dato de informe", "clipboard-check")
            + card("violet", "Planificados", String(dp), px ? "pr&oacute;xima visita " + fmtD(px).slice(0, 5) : "sin pr&oacute;xima visita con planificados", "list-checks");
        icons(st);
    }
    function agSum(box) {
        var l = agLista(box), sum = box.querySelector("[data-pv-agsum]"), ins = agSel(l, "inst");
        if (!sum) return;
        var o = ins && ins.value && ins.selectedIndex >= 0 ? ins.options[ins.selectedIndex] : null;
        if (!o) { sum.hidden = true; sum.innerHTML = ""; return; }
        var d = function (k) { return o.getAttribute("data-" + k) || ""; }, co = d("t") === "co";
        var st = function (tone, lab, val, sm, ic) {
            return '<div class="vct-360-stat" data-vct-tone="' + tone + '"><span class="vct-360-stat-main"><span class="vct-360-stat-label">' + lab + "</span><b>" + val + "</b><small>" + sm + "</small></span>"
                + '<span class="vct-360-stat-icon"><span data-vct-icon="' + ic + '"></span></span></div>';
        };
        var ej = parseFloat(d("ejec")) || 0, dh = parseFloat(d("dh")) || 0, sin = Math.max(0, Math.round((ej - dh) * 10) / 10);
        var pl = function (n, a, b) { return n + " " + (n === "1" ? a : b); };
        sum.innerHTML = st("blue", escH(o.text), escH(d("ejec") || "0") + " / " + escH(d("proy") || "0") + " h",
                           (d("ini") ? escH(d("ini")) + " al " + escH(d("fin")) + " &middot; " : "") + escH(d("prog") || "0") + " h programadas", "briefcase")
            + st("mint", "Visitas", escH(d("nv") || "0"), pl(d("ne") || "0", "ejecutada", "ejecutadas") + " &middot; " + pl(d("nc") || "0", "confirmada", "confirmadas")
                 + (d("np") && d("np") !== "0" ? " &middot; " + pl(d("np"), "pendiente", "pendientes") : ""), "calendar")
            + (co ? st("violet", "Desarrollo", fmtH(dh) + " h", pl(d("dr") || "0", "realizado", "realizados") + " &middot; " + pl(d("dp") || "0", "planificado", "planificados"), "list-checks")
                  + st("amber", "Sin detallar", fmtH(sin) + " h", "horas ejecutadas sin desarrollo", "clock-3") : "");
        sum.hidden = false;
        icons(sum);
    }
    function agChipsInit(r) {
        r.querySelectorAll("[data-pv-agbox]").forEach(function (box) {
            var l = agLista(box);
            if (!l || !box.querySelector("[data-pv-agchips]")) return;
            agPanes(box).forEach(function (p) {
                var ts = agSel(p, "servicio");
                if (ts) { ts.style.display = "none"; var w = ts.nextElementSibling; if (w && w.classList && w.classList.contains("vct-custom-select")) w.style.display = "none"; }
            });
            /* v42: el filtro Consultor de Desarrollo solo se muestra si hay consultores con desarrollo cargado */
            var fc = agSel(box.querySelector('[data-pv-agpane="des"]'), "cons");
            if (fc && fc.options.length <= 1) { fc.style.display = "none"; var wc = fc.nextElementSibling; if (wc && wc.classList && wc.classList.contains("vct-custom-select")) wc.style.display = "none"; }
            var st = null;
            try { st = JSON.parse(sessionStorage.getItem(AGC_KEY + agProj(box)) || "null"); } catch (e) { st = null; }
            if (st && (st.t || st.i)) agChip(box, st.t || "", st.i || "", true);
            else agDesStats(box);
        });
    }
    document.addEventListener("click", function (e) {
        var c = e.target && e.target.closest ? e.target.closest("[data-pv-agchip]") : null;
        if (!c) return;
        e.preventDefault();
        var box = c.closest("[data-pv-agbox]");
        if (box) agChip(box, c.getAttribute("data-pv-agchip") || "");
    });
    document.addEventListener("change", function (e) {
        var s = e.target;
        if (!s || !s.matches || !s.matches("select[data-pv-aginst]")) return;
        var box = s.closest("[data-pv-agbox]");
        if (!box) return;
        /* v41: el servicio elegido en una vista se copia a la otra */
        agPanes(box).forEach(function (p) { var o = agSel(p, "inst"); if (o && o !== s && o.value !== s.value) agSetSel(o, s.value); });
        agSum(box);
        agDesStats(box);
        agSave(box);
    });
    window.__vctPvDes = { rows: xlsRows, csv: readCsv, xlsx: readXlsx };

    window.VCTProyectoV360 = { version: 1, open: openModal, close: closeModal };
})(window, document);

/* v7: quitar la marca roja del email al escribir */
document.addEventListener("input", function (e) {
    var t = e.target;
    if (t && t.matches && t.matches("[data-vct-pv-email].is-invalid") && t.value.trim()) t.classList.remove("is-invalid");
});
