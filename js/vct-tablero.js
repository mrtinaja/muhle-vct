/* vct-tablero.js - v8 DASH_TAB_V8 (Mis proyectos: sin detalle por fila, sin detallar como badge circular, fecha de proxima visita mas chica)
   v7 DASH_TAB_V7 (Mis proyectos con el diseno de la grilla Proyectos: cliente, proyecto, servicios apilados, normas,
   analista + plan vs. tiempo, horas, acciones, sin detallar, proxima visita con fecha tipo calendario y estado; detalle por fila)
   v6 DASH_TAB_V6 (indicadores fijos sin titulo; Para hacer y Mis proyectos como cards con titulo y plegado propio;
   Personalizar con vista previa esquematica; inicializa las grillas con VCTDataGrid.init)
   v5 DASH_TAB_V5 (card Para hacer al 100%: Acciones | Visitas | Sin detallar en la misma grilla estandar (vct-datagrid),
   Acciones con pestanias, Lista | Calendario (calendario unificado vct-calendario) y Graficos como la pantalla Acciones;
   sin card Calendario; Personalizar con 3 bloques: Indicadores, Para hacer, Mis proyectos)
   v4 DASH_TAB_V4 (Para hacer de a 20, Proximas visitas de a 5 y Horas sin detallar de a 15 con alto fijo; ayuda de cada pestania)
   v3 DASH_TAB_V3 (barra solo Tablero / Graficos / Personalizar; filtros debajo con el estilo de las grillas: mes, cliente,
   proyecto y buscar; grillas con el diseno de las grillas institucionales: badges del kit, paginado, menu de fila; botones suaves)
   v2 DASH_TAB_V2 (barra de pestanias como la V360 / Gerencia, cambio de mes, indicadores en 4 grupos con colores de la V360 y la agenda)
   v1 DASH_TAB_V1 (Inicio del consultor: Tablero de control)
   ============================================================================
   dbo.VCT_MAIN_DASHBOARD (vista CONSULTOR) manda los datos en <textarea data-vt="..."> (una fila por
   renglon, campos separados por TAB) y este archivo arma el tablero:
     - Indicadores del mes (horas y acciones) y fila de indicadores chicos.
     - Cards: 1 Para hacer + Proximas visitas + Horas sin detallar, 2 Mis proyectos, 3 Calendario
       (Dia / Semana / Mes / Lista). Cada card se pliega; Personalizar cambia el orden y oculta.
     - Graficos (boton Tablero | Graficos).
   Las preferencias (orden, ocultas, plegadas, vista del calendario) quedan en el navegador del usuario.
   Solo lectura: las acciones abren la V360 del proyecto en la pestania que corresponde.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctTableroLoaded) return;
    window.__vctTableroLoaded = true;

    var PAL = ["#9B1B4A", "#2563EB", "#0F9F8F", "#D97706", "#7C3AED", "#DB2777"];
    var DN = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
    var MN = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
    var CARDS = [
        { k: "hacer", t: "Para hacer", i: "clipboard-check", d: "Acciones (lista, calendario y gráficos), próximas visitas y horas sin detallar." },
        { k: "proy", t: "Mis proyectos", i: "folder", d: "Proyectos activos: plan vs. tiempo, horas, vencidas y próxima visita." }
    ];
    var ICON = {
        "folder": '<path d="M3 6h7l2 2h9v11H3z"/>',
        "calendar": '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
        "calendar-days": '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/>',
        "clock-3": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
        "list-checks": '<path d="m3 6 2 2 4-4M3 12l2 2 4-4M3 18l2 2 4-4M12 6h9M12 12h9M12 18h9"/>',
        "briefcase": '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V4h8v3M3 12h18"/>',
        "bell": '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/>',
        "edit": '<path d="M4 20h4L19 9l-4-4L4 16v4z"/><path d="m13.5 6.5 4 4"/>',
        "check": '<path d="m5 12 5 5 9-10"/>',
        "chart-bar": '<path d="M4 20V10h4v10M10 20V4h4v16M16 20v-7h4v7M2 20h20"/>',
        "settings": '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1 7 17M17 7l2.1-2.1"/>',
        "arrow-right": '<path d="M5 12h14M13 6l6 6-6 6"/>',
        "chevron-left": '<path d="m15 6-6 6 6 6"/>',
        "chevron-right": '<path d="m9 6 6 6-6 6"/>',
        "search": '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
        "clipboard-check": '<path d="M9 5h6v3H9z"/><path d="M7 6H5v15h14V6h-2"/><path d="m9 15 2 2 4-4"/>',
        "eye": '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
        "users": '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5M16 4.8a3.3 3.3 0 0 1 0 6.4M18 14.8c2 .6 3.2 2.3 3.5 5.2"/>',
        "dots": '<circle cx="12" cy="5" r="1.4" fill="currentColor"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/><circle cx="12" cy="19" r="1.4" fill="currentColor"/>',
        "first": '<path d="m11 17-5-5 5-5M18 17l-5-5 5-5"/>',
        "last": '<path d="m6 17 5-5-5-5M13 17l5-5-5-5"/>'
    };
    function svgI(n) { return '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + (ICON[n] || "") + "</svg>"; }
    function ic(n, cls) {
        return '<span class="vtb-ic ' + (cls || "") + '"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + (ICON[n] || "") + "</svg></span>";
    }

    /* ---------------- utilidades ---------------- */
    var _dec = document.createElement("textarea");
    function deco(s) { if (!s || s.indexOf("&") < 0) return s || ""; _dec.innerHTML = s; return _dec.value; }
    function esc(s) { return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }
    function txt(s) { return esc(deco(s)); }
    function num(v) { var n = parseFloat(String(v == null ? "" : v).replace(",", ".")); return isNaN(n) ? 0 : n; }
    function H(n) { n = Math.round(n * 10) / 10; return String(n).replace(".", ","); }
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
    function pd(s) { if (!s) return null; var p = s.split("-"); return p.length === 3 ? new Date(+p[0], +p[1] - 1, +p[2]) : null; }
    function add(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n); }
    function diff(a, b) { return Math.round((b - a) / 86400000); }
    function dm(d) { return pad(d.getDate()) + "/" + pad(d.getMonth() + 1); }
    function dlab(d) { return DN[d.getDay()].toLowerCase() + " " + dm(d); }
    function monday(d) { var w = (d.getDay() + 6) % 7; return add(d, -w); }

    function rows(page, name) {
        var t = page.querySelector('textarea[data-vt="' + name + '"]');
        if (!t) return [];
        return String(t.value || "").split("\n").filter(function (l) { return l.length > 0; }).map(function (l) { return l.split("\t"); });
    }

    /* ---------------- datos ---------------- */
    function load(page) {
        var D = { hoy: pd(page.getAttribute("data-hoy")), mes: page.getAttribute("data-mes") || "", k: {}, P: {}, plist: [] };
        rows(page, "kpi").forEach(function (r) { D.k[r[0]] = r[1]; });
        /* proyectos: id, cli, cod, nombre, cliente, est, avance, servicio, tiempo%, hejec, hproy, dias fin, etapa, activo */
        rows(page, "pro").forEach(function (r) {
            var p = { id: r[0], cli: r[1], cod: deco(r[2]), nom: deco(r[3]), cliente: deco(r[4]), est: r[5], plan: num(r[6]), srv: deco(r[7]),
                      tiempo: r[8] === "" ? null : num(r[8]), hej: num(r[9]), hpr: num(r[10]), fin: r[11] === "" ? null : num(r[11]), etapa: deco(r[12]), activo: r[13] === "1",
                      asig: num(r[14]), dev: num(r[15]), h12: num(r[16]),
                      svcs: (r[17] || "").split(",").filter(function (x) { return x === "CO" || x === "AU" || x === "CA"; }),
                      normas: (r[18] ? deco(r[18]).split("|").filter(function (x) { return x; }) : []), anIni: deco(r[19] || ""), anNom: deco(r[20] || "") };
            D.P[p.id] = p;
            D.plist.push(p);
        });
        D.plist.sort(function (a, b) { return (a.cliente || a.nom).localeCompare(b.cliente || b.nom); });
        D.plist.forEach(function (p, i) { p.col = PAL[i % PAL.length]; p.short = (p.cliente || p.nom).split(" ")[0]; });
        /* acciones: id, proy, item, titulo, vence, estado, est cod, final, cierre, prioridad, nivel, plan, n dev, h dev R, h dev P */
        D.A = rows(page, "acc").map(function (r) {
            return { id: r[0], proy: r[1], item: deco(r[2]), tit: deco(r[3]), vence: pd(r[4]), est: deco(r[5]), estc: r[6], fin: r[7] === "1", cierre: pd(r[8]),
                     prio: deco(r[9]), pniv: num(r[10]), plan: r[11] === "1", dn: num(r[12]), dr: num(r[13]), dp: num(r[14]),
                     tipo: deco(r[15] || ""), subt: deco(r[16] || ""), idt: r[17] || "0", prioc: (r[18] || "").toUpperCase() };
        });
        /* visitas: id, proy, desde, hasta, estado, h plan, h ejec, dev R, dev P, sin registrar, dias */
        D.V = rows(page, "vis").map(function (r) {
            var v = { id: r[0], proy: r[1], desde: pd(r[2]), hasta: pd(r[3]) || pd(r[2]), est: r[4], hp: num(r[5]), he: num(r[6]), dr: num(r[7]), dp: num(r[8]), sinreg: r[9] === "1", dd: {}, svc: (r[11] || "").toUpperCase() };
            if (r[10]) r[10].split("|").forEach(function (x) { var q = x.split("="); if (q.length === 2) v.dd[q[0]] = num(q[1]); });
            else {
                var n = diff(v.desde, v.hasta) + 1, h = n > 0 ? v.hp / n : v.hp;
                for (var i = 0; i < Math.max(n, 1); i++) v.dd[iso(add(v.desde, i))] = h;
            }
            return v;
        });
        /* agenda por dia: fecha, estado, horas, tipo, feriado, habil */
        D.G = {};
        rows(page, "dia").forEach(function (r) { D.G[r[0]] = { est: r[1], h: num(r[2]), tipo: r[3], fer: r[4] === "1", hab: r[5] === "1", cap: r[6] === undefined ? 8 : num(r[6]) }; });
        /* desarrollo: fecha visita, tipo, horas, proy, item, titulo, accion */
        D.X = rows(page, "dev").map(function (r) { return { f: r[0], tipo: r[1], h: num(r[2]), proy: r[3], item: deco(r[4]), tit: deco(r[5]), acc: r[6] }; });
        /* meses: etiqueta, ejecutadas, programadas, capacidad */
        D.M = rows(page, "mes").map(function (r) { return { l: deco(r[0]), e: num(r[1]), p: num(r[2]), c: num(r[3]) }; });
        /* feriados (calendario unificado): fecha, tipo, texto */
        D.F = rows(page, "fer").map(function (r) { return { f: r[0], t: r[1], x: deco(r[2] || "Feriado") }; });
        /* boton Nueva accion (permisos del perfil, lo arma el SP) */
        var tn = page.querySelector('textarea[data-vt="nueva"]');
        D.nueva = tn ? String(tn.value || "") : "";
        D.fecha0 = pd(page.getAttribute("data-des"));
        D.fecha1 = pd(page.getAttribute("data-has"));
        return D;
    }
    function P(D, id) { return D.P[id] || { id: id, cod: "", nom: "Proyecto " + id, cliente: "", short: "Proyecto", col: "#64748B", cli: "" }; }
    function ptag(D, id, full) {
        var p = P(D, id);
        return '<span class="vtb-ptag" style="--c:' + p.col + '" title="' + esc((p.cod ? "(" + p.cod + ") " : "") + p.nom + (p.cliente ? " · " + p.cliente : "")) + '"><i></i>' + esc(full ? (p.cliente || p.nom) : p.short) + "</span>";
    }
    function pill(t, k) { return '<span class="vtb-lg is-' + k + '">' + esc(t) + "</span>"; }

    /* ---------------- preferencias (navegador) ---------------- */
    function pkey(page) { return "vctTablero:" + (page.getAttribute("data-user") || ""); }
    function prefs(page) {
        var p = null;
        try { p = JSON.parse(window.localStorage.getItem(pkey(page)) || "null"); } catch (e) { p = null; }
        p = p || {};
        p.order = (p.order || []).filter(function (k) { return CARDS.some(function (c) { return c.k === k; }); });
        CARDS.forEach(function (c) { if (p.order.indexOf(c.k) < 0) p.order.push(c.k); });
        p.hidden = p.hidden || {};
        delete p.hidden.kh; delete p.hidden.kpi; if (p.folded) delete p.folded.kpi;
        p.folded = p.folded || {};
        p.modo = p.modo === "vis" || p.modo === "sd" ? p.modo : "acc";
        delete p.cal;
        return p;
    }
    function savePrefs(page, p) { try { window.localStorage.setItem(pkey(page), JSON.stringify(p)); } catch (e) { } }

    /* ---------------- estado ---------------- */
    function S(page) {
        if (!page.__vtb) {
            var D = load(page), pr = prefs(page);
            page.__vtb = { D: D, pr: pr, view: "tab", edit: false, c: "", f: "", q: "", modo: pr.modo, atab: "", aview: "lista", capas: { ven: true, vis: true, dev: true },
                           pgs: {}, prk: "mes", exp: {}, draft: null, mes: new Date(D.hoy.getFullYear(), D.hoy.getMonth(), 1) };
        }
        return page.__vtb;
    }
    function okP(st, id) { return (!st.f || st.f === String(id)) && (!st.c || P(st.D, id).cli === st.c); }
    function okQ(st, s) { return !st.q || deco(s).toLowerCase().indexOf(st.q) >= 0; }

    /* ---------------- encabezado e indicadores (v2: barra de pestanias y 4 grupos) ---------------- */
    /* colores: horas como la V360 (ejecutadas / programadas), dias como la agenda del consultor, desarrollo en bordo */
    var CL = { ej: "#16A34A", pr: "#3B82F6", lib: "#DBEAFE", pot: "#F59E0B", lic: "#EC4899", oc: "#64748B", org: "#0D9488", obs: "#FF7A59", det: "#66062D", sin: "#E8A9C0" };
    var SVC = { CO: ["briefcase", "Consultoría", "#8C1D47"], AU: ["clipboard-check", "Auditoría", "#4A4849"], CA: ["users", "Capacitación", "#CF6F92"] };
    function m0(d) { return new Date(d.getFullYear(), d.getMonth(), 1); }
    function mlabel(d) { var n = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"][d.getMonth()]; return n.charAt(0).toUpperCase() + n.slice(1) + " " + d.getFullYear(); }
    /* indicadores del mes elegido, calculados con la agenda por dia y las visitas */
    function mesData(st) {
        var D = st.D, f0 = st.mes, f1 = new Date(f0.getFullYear(), f0.getMonth() + 1, 0), h = D.hoy;
        var r = { cap: 0, dd: 0, hab: 0, ej: 0, pr: 0, lib: 0, pot: 0, lic: 0, oc: 0, org: 0, obs: 0, nc: 0, dr: 0, dp: 0, sd: 0, sdn: 0, vm: 0, vh: 0, svc: { CO: 0, AU: 0, CA: 0 }, cum: 0 };
        for (var d = new Date(f0); d <= f1; d = add(d, 1)) {
            var g = D.G[iso(d)];
            if (!g) continue;
            var asg = g.est === "ASIGNADO" ? g.h : 0, cap = g.cap || 8, t = g.tipo || "";
            if (asg) { if (d <= h) r.ej += asg; else r.pr += asg; }
            if (g.hab) r.hab++;
            if (t === "DISPONIBLE") { r.cap += cap; r.dd++; r.lib += Math.max(cap - asg, 0); continue; }
            if (!g.hab || g.fer) continue;
            var rest = Math.max(8 - asg, 0);
            if (t === "POTENCIAL") r.pot += Math.max(cap - asg, 0);
            else if (t === "LICENCIA") r.lic += rest;
            else if (t === "OCUPADO" || t === "NO_DISPONIBLE") r.oc += rest;
            else if (t === "ORGANISMO") r.org += rest;
            else if (t) r.obs += rest;
            else r.nc += rest;
        }
        D.V.forEach(function (v) {
            if (v.desde < f0 || v.desde > f1) return;
            r.vm++;
            if (v.desde <= h) { r.vh++; r.dr += v.dr; if (v.he - v.dr > 0.05) { r.sd += v.he - v.dr; r.sdn++; } }
            r.dp += v.dp;
            if (r.svc[v.svc] != null) r.svc[v.svc]++;
        });
        D.A.forEach(function (a) { if (a.fin && a.estc === "CUMPLIDA" && a.cierre && a.cierre >= f0 && a.cierre <= f1) r.cum++; });
        return r;
    }
    function svcIco(code) {
        var x = SVC[code];
        return x ? '<span class="vctdg-svc is-' + code.toLowerCase() + ' is-on vtb-svi" title="' + x[1] + '">' + ic(x[0]) + "</span>" : "";
    }
    /* barra: solo las pestanias y Personalizar (a la derecha) */
    function header(st) {
        var tab = function (k, t, i) { return '<button type="button" class="vct-ini-tab' + (st.view === k ? " is-active" : "") + '" data-vtb-view="' + k + '" aria-selected="' + (st.view === k) + '">' + ic(i) + "<span>" + t + "</span></button>"; };
        return '<div class="vct-360-tabsbar vct-ini-tabs vtb-bar">' + tab("tab", "Tablero", "list-checks") + tab("graf", "Gráficos", "chart-bar")
             + '<span class="vtb-sp"></span>'
             + (st.view === "tab" ? '<div class="vtb-ctl"><button type="button" class="vctdg-btn' + (st.edit ? " is-on" : "") + '" data-vtb-pers>' + ic("settings") + "Personalizar</button></div>" : "")
             + "</div>";
    }
    /* filtros (sin barra): mes a la izquierda, cliente y proyecto; buscar sobre el margen derecho. Mismo estilo que los filtros de las grillas */
    function filtros(st) {
        var D = st.D, a = m0(D.fecha0 || D.hoy), b = m0(D.fecha1 || D.hoy), cl = {}, cls = [];
        D.plist.forEach(function (p) { if (p.cli && !cl[p.cli]) { cl[p.cli] = p.cliente || ("Cliente " + p.cli); cls.push(p.cli); } });
        cls.sort(function (x, y) { return cl[x].localeCompare(cl[y]); });
        var oc = '<option value="">Cliente</option>' + cls.map(function (c) { return '<option value="' + esc(c) + '"' + (st.c === c ? " selected" : "") + ">" + esc(cl[c]) + "</option>"; }).join("");
        var pl = D.plist.filter(function (p) { return !st.c || p.cli === st.c; }).slice().sort(function (x, y) { return (x.cliente || "").localeCompare(y.cliente || "") || String(x.cod).localeCompare(String(y.cod)); });
        var op = '<option value="">Proyecto</option>' + pl.map(function (p) {
            return '<option value="' + esc(p.id) + '"' + (st.f === p.id ? " selected" : "") + ">" + esc((p.cod ? "(" + p.cod + ") " : "") + p.nom) + "</option>";
        }).join("");
        return '<div class="vctdg vtb-flt"><div class="vtb-mesnav">'
             + '<button type="button" class="vctdg-btn vtb-ico" data-vtb-mes="-1" title="Mes anterior"' + (st.mes <= a ? " disabled" : "") + ">" + svgI("chevron-left") + "</button>"
             + '<input type="text" class="vtb-mesin" readonly tabindex="-1" aria-label="Mes" value="' + mlabel(st.mes) + '">'
             + '<button type="button" class="vctdg-btn vtb-ico" data-vtb-mes="1" title="Mes siguiente"' + (st.mes >= b ? " disabled" : "") + ">" + svgI("chevron-right") + "</button></div>"
             + '<div class="vctdg-filters"><select class="vctdg-select vct-select" data-vtb-c aria-label="Cliente">' + oc + "</select>"
             + '<select class="vctdg-select vct-select" data-vtb-f aria-label="Proyecto">' + op + "</select></div>"
             + '<div class="vctdg-search vtb-q"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg><input type="search" data-vtb-q placeholder="Buscar acción, ítem, cliente…" value="' + esc(st.q) + '"></div></div>';
    }
    /* ---------------- grillas: mismo diseno que las grillas institucionales (vct-datagrid.css) ---------------- */
    function grid2(head, rows, cols, empty, cls) {
        return '<div class="vctdg vtb-dg' + (cls ? " " + cls : "") + '"><div class="vctdg-wrap"><table class="vctdg-table"><thead><tr>' + head.map(function (h) {
            var c = typeof h === "string" ? [h, ""] : h;
            return "<th" + (c[1] ? ' class="' + c[1] + '"' : "") + ">" + c[0] + "</th>";
        }).join("") + "</tr></thead><tbody>" + (rows || '<tr class="vctdg-empty"><td colspan="' + cols + '">' + (empty || "Sin registros") + "</td></tr>") + "</tbody></table></div>";
    }
    function pgSlice(st, key, list, per) {
        per = per || 10;
        var pages = Math.max(1, Math.ceil(list.length / per)), pg = Math.min(st.pgs[key] || 0, pages - 1);
        st.pgs[key] = pg;
        return { rows: list.slice(pg * per, pg * per + per), pg: pg, pages: pages, total: list.length, per: per, key: key };
    }
    function pager(x) {
        var info = x.total ? "Mostrando " + (x.pg * x.per + 1) + " a " + Math.min(x.total, x.pg * x.per + x.per) + " de " + x.total : "Sin registros";
        var p = x.pg + 1, n = x.pages;
        var btn = function (t, h, lbl, dis, act) { return '<button type="button" class="vctdg-page' + (act ? " is-active" : "") + '" data-vtb-pgto="' + x.key + "|" + (t - 1) + '" aria-label="' + lbl + '"' + (dis ? " disabled" : "") + ">" + h + "</button>"; };
        var s = Math.max(1, p - 2), e = Math.min(n, s + 4);
        s = Math.max(1, e - 4);
        var h = btn(1, svgI("first"), "Primera página", p === 1) + btn(p - 1, svgI("chevron-left"), "Página anterior", p === 1);
        for (var i = s; i <= e; i++) h += btn(i, String(i), "Página " + i, false, i === p);
        h += btn(p + 1, svgI("chevron-right"), "Página siguiente", p === n) + btn(n, svgI("last"), "Última página", p === n);
        return '<div class="vctdg-footer"><div class="vctdg-info">' + info + '</div><nav class="vctdg-pager" aria-label="Paginación">' + h + "</nav></div></div>";
    }
    /* celda de proyecto: (codigo) nombre + cliente como referencia */
    function pcell(D, id) {
        var p = P(D, id), n = (p.cod ? "(" + p.cod + ") " : "") + p.nom;
        return '<span class="vct-360-project-name" title="' + esc(n) + '">' + esc(n) + '</span><span class="vct-360-project-ref" title="' + esc(p.cliente) + '">' + esc(p.cliente) + "</span>";
    }
    function bdg(t, cls) { return '<span class="vct-360-badge ' + cls + '">' + esc(t) + "</span>"; }
    function estBdg(a) { return bdg(a.est, { PENDIENTE: "is-planned", EN_PROCESO: "is-active", EN_ESPERA: "is-paused", CUMPLIDA: "is-done", CANCELADA: "is-cancel" }[a.estc] || "is-neutral"); }
    function prioBdg(a) { return a.prio ? bdg(a.prio, a.pniv >= 3 ? "is-cancel" : a.pniv === 2 ? "is-neutral" : "is-draft") : '<span class="vctdg-none">&mdash;</span>'; }
    function visBdg(v) { return v.est === "CONFIRMADO" ? bdg("Confirmada", "is-active") : bdg("Pendiente", "is-planned"); }
    /* menu de fila (3 puntos), como las grillas: [texto, icono, proyecto, pestania de la V360] */
    function rmenu(items) {
        return '<button type="button" class="vct-row-menu-trigger vtb-rm" data-vtb-rm title="Acciones" aria-haspopup="menu">' + svgI("dots") + '</button><span class="vtb-rm-items" hidden>'
             + items.map(function (i) { return '<i data-l="' + esc(i[0]) + '" data-i="' + i[1] + '" data-p="' + esc(i[2]) + '" data-t="' + (i[3] || "") + '"></i>'; }).join("") + "</span>";
    }
    function due(D, v) {
        var h = D.hoy;
        if (!v) return '<span class="vctdg-none">sin fecha</span>';
        if (v < h) return '<span class="vtb-due-v">vencida ' + dm(v) + "</span>";
        if (diff(h, v) === 0) return '<span class="vtb-due-h">hoy</span>';
        return dlab(v);
    }
    function n2(v, lbl, tone, tip) { return '<span class="vtb-n' + (tone ? " is-" + tone : "") + '"' + (tip ? ' title="' + esc(tip) + '"' : "") + "><b>" + v + "</b><small>" + lbl + "</small></span>"; }
    function bar(parts, h) {
        var tot = parts.reduce(function (a, s) { return a + s[1]; }, 0);
        if (!tot) return '<div class="vtb-ubar" style="height:' + h + 'px"><span class="vtb-u-n" style="flex:1"></span></div>';
        return '<div class="vtb-ubar" style="height:' + h + 'px">' + parts.filter(function (s) { return s[1] > 0.05; }).map(function (s) {
            return '<span class="' + (s[2] ? "" : "vtb-u-n") + '" style="flex:' + s[1] + ";" + (s[2] ? "background:" + s[2] : "") + '" title="' + esc(s[0] + ": " + H(s[1]) + " h") + '"></span>';
        }).join("") + "</div>";
    }
    function kpiHoras(st) {
        var m = mesData(st), asi = m.ej + m.pr, pc = m.cap > 0 ? Math.round(asi * 100 / m.cap) : 0;
        var parts = [["Ejecutadas", m.ej, CL.ej], ["Programadas", m.pr, CL.pr], ["Libres (disponible sin visita)", m.lib, CL.lib], ["Potencial", m.pot, CL.pot], ["Licencia", m.lic, CL.lic],
                     ["Ocupado / no disponible", m.oc, CL.oc], ["Organismo", m.org, CL.org], ["Otros de la agenda", m.obs, CL.obs], ["Sin cargar", m.nc, ""]];
        var g1 = '<div class="vtb-g"><div class="vtb-g-h">' + ic("clock-3") + '<b>Horas del mes</b><span title="' + m.dd + ' días disponibles × horas de capacidad">capacidad ' + H(m.cap) + " h</span></div>"
               + '<div class="vtb-g-n">' + n2(H(asi) + " h", "asignadas" + (m.cap ? " · " + pc + "%" : "")) + n2(H(m.ej) + " h", "ejecutadas", "ej") + n2(H(m.pr) + " h", "programadas", "pr") + n2(H(m.lib) + " h", "libres") + "</div>"
               + bar(parts, 8) + "</div>";
        var det = Math.min(m.dr, m.ej);
        var g2 = '<div class="vtb-g"><div class="vtb-g-h">' + ic("edit") + "<b>Desarrollo</b><span>de " + H(m.ej) + " h ejecutadas</span></div>"
               + '<div class="vtb-g-n">' + n2(H(m.dr) + " h", "registrado" + (m.ej > 0 ? " · " + Math.round(m.dr * 100 / m.ej) + "%" : "")) + n2(H(m.sd) + " h", "sin detallar", m.sd > 0 ? "warn" : "", m.sdn + " visita(s)") + n2(H(m.dp) + " h", "programado") + "</div>"
               + bar([["Detallado", det, CL.det], ["Sin detallar", m.sd, CL.sin]], 8) + "</div>";
        /* acciones: anillo abiertas / cumplidas del mes + badges (datos de hoy) */
        var k = st.D.k, abi = num(k.aabi), cum = m.cum, tot = abi + cum, pcum = tot ? Math.round(cum * 100 / tot) : 0;
        var bd = function (cls, n, t, tab) { return '<span class="vct-360-badge ' + cls + '"' + (tab ? ' data-vtb-ptab="' + tab + '" role="button" title="Ver en Para hacer"' : "") + ">" + n + " " + t + "</span>"; };
        var g3 = '<div class="vtb-g"><div class="vtb-g-h">' + ic("list-checks") + "<b>Acciones</b><span title=\"Acciones a mi cargo: el anillo muestra las abiertas hoy y las cumplidas en el mes elegido\">" + cum + " cumplida" + (cum === 1 ? "" : "s") + " en " + mlabel(st.mes).split(" ")[0].toLowerCase() + "</span></div>"
               + '<div class="vtb-acc"><div class="vtb-mr" style="background:conic-gradient(' + CL.det + " 0 " + pcum + "%, #F3E3EA " + pcum + '% 100%)" title="' + abi + " abiertas · " + cum + ' cumplidas en el mes"><span><b>' + abi + "</b><small>abiertas</small></span></div>"
               + '<div class="vctdg vtb-accb">' + bd("is-cancel", num(k.aven), "vencidas", "V") + bd("is-planned", num(k.ahoy), "hoy", "H") + bd("is-paused", num(k.asem), "en 7 días", "P") + bd("is-draft", num(k.asdv), "sin desarrollo", "") + "</div></div></div>";
        /* proyectos y visitas: proyectos, anillo de visitas por servicio y la proxima visita */
        var sv = ["CO", "AU", "CA"], vt = sv.reduce(function (a, c) { return a + m.svc[c]; }, 0), acc = 0, grad = [];
        sv.forEach(function (c) { if (!m.svc[c]) return; grad.push(SVC[c][2] + " " + (acc * 100 / vt).toFixed(1) + "% " + ((acc + m.svc[c]) * 100 / vt).toFixed(1) + "%"); acc += m.svc[c]; });
        var tip = sv.filter(function (c) { return m.svc[c]; }).map(function (c) { return SVC[c][1] + ": " + m.svc[c]; }).join(" · ");
        var nx = st.D.V.filter(function (v) { return v.desde > st.D.hoy; }).sort(function (x, y) { return x.desde - y.desde; })[0];
        var px = nx ? (function () {
            var p = P(st.D, nx.proy);
            return '<div class="vtb-dt" title="' + dlab(nx.desde) + '"><div class="vtb-dt-m">' + MN[nx.desde.getMonth()].toUpperCase() + '</div><div class="vtb-dt-d">' + nx.desde.getDate() + '</div><div class="vtb-dt-w">' + DN[nx.desde.getDay()].toLowerCase() + "</div></div>"
                 + '<div class="vtb-ci-t"><span>Próxima visita</span><div class="vctdg vtb-pxs">' + svcIco(nx.svc) + "<small>" + esc(p.cliente || p.nom) + "</small></div><small>" + H(nx.hp) + " h · " + (nx.est === "CONFIRMADO" ? "confirmada" : "pendiente") + "</small></div>";
        })() : '<div class="vtb-ci-t"><span>Próxima visita</span><small>sin visitas agendadas</small></div>';
        var g4 = '<div class="vtb-g"><div class="vtb-g-h">' + ic("folder") + "<b>Proyectos y visitas</b></div><div class=\"vtb-pv\">"
               + '<div class="vtb-cc2" title="Proyectos: ' + num(k.npc) + " en curso · " + num(k.npl) + ' en lanzamiento"><div class="vtb-ci-c"><b>' + num(k.np) + "</b></div><small>proyectos</small></div>"
               + '<div class="vtb-cc2" title="Visitas del mes: ' + m.vm + " (" + m.vh + " hechas)" + (tip ? " · " + tip : "") + '"><div class="vtb-ci-c vtb-ci-ring" style="background:' + (grad.length ? "conic-gradient(" + grad.join(",") + ")" : "#F1F5F9") + '"><b>' + m.vm + "</b></div><small>visitas</small></div>"
               + px + "</div></div>";
        return '<div class="vtb-ga">' + g1 + g2 + g3 + g4 + "</div>";
    }
    function kpiMini() { return ""; }

    /* ---------------- card: Para hacer = Acciones | Visitas | Sin detallar ----------------
       Una sola grilla estandar (vct-datagrid: buscador, filtros, orden, Excel / PDF, paginado de a 10) al 100%.
       Acciones replica la pantalla Acciones (VCT_MAIN_ACCIONES): pestanias por situacion, Lista | Calendario y Graficos. */
    var MODOS = [["acc", "Acciones", "clipboard-check"], ["vis", "Visitas", "calendar"], ["sd", "Sin detallar", "clock-3"]];
    var ATABS = [["V", "Vencidas", "bell", "is-red"], ["H", "Hoy", "clock-3", "is-amb"], ["P", "Próximas", "chevron-right", "is-bor"],
                 ["S", "Sin fecha", "calendar", "is-gry"], ["T", "Todas", "list-checks", "is-gry"]];
    function boxH(title, icon, body, sub, tools) {
        return '<div class="vct-360-box vtb-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon">' + ic(icon) + "</span>" + title + "</h3>"
             + (sub ? '<div class="vct-360-box-subtitle">' + sub + "</div>" : "") + "</div>" + (tools ? '<div class="vtb-tools">' + tools + "</div>" : "") + "</div>" + body + "</div>";
    }
    /* situacion como Acciones: V vencida, H hoy, P 1-7 dias, L posterior, S sin fecha, C cerrada */
    function sitOf(D, a) {
        if (a.fin) return "C";
        if (!a.vence) return "S";
        var d = diff(D.hoy, a.vence);
        return d < 0 ? "V" : d === 0 ? "H" : d <= 7 ? "P" : "L";
    }
    function abiertas(st) {
        var D = st.D;
        return D.A.filter(function (a) {
            if (a.fin || !okP(st, a.proy)) return false;
            var p = P(D, a.proy);
            return okQ(st, a.tit + " " + a.item + " " + a.tipo + " " + a.subt + " " + p.cliente + " " + p.nom + " " + p.cod);
        }).map(function (a) { a._s = sitOf(D, a); return a; });
    }
    function cntTab(L, k) { return k === "T" ? L.length : L.filter(function (a) { return a._s === k; }).length; }
    function tabIni(L) { return cntTab(L, "V") ? "V" : cntTab(L, "H") ? "H" : cntTab(L, "P") ? "P" : "T"; }
    function d5(d) { return dm(d); }
    function d10(d) { return dm(d) + "/" + d.getFullYear(); }
    function tabInfo(st, k, n) {
        var h = st.D.hoy;
        return {
            V: ["Vencidas", "bell", "Acciones abiertas a tu cargo con vencimiento anterior a hoy (" + d5(h) + ")."],
            H: ["Vencen hoy", "clock-3", "Lo que vence hoy a tu cargo, " + d10(h) + "."],
            P: ["Próximas", "chevron-right", "Lo que vence en los próximos 7 días (" + d5(add(h, 1)) + " al " + d5(add(h, 7)) + ")."],
            S: ["Sin fecha", "calendar", "Acciones abiertas a tu cargo sin fecha de vencimiento: conviene ponerles una."],
            T: ["Todas las acciones abiertas", "list-checks", "Todo lo abierto a tu cargo, ordenado por vencimiento."],
            G: ["Gráficos", "chart-bar", "Seguimiento de tus acciones."]
        }[k];
    }
    function relBdg(D, a) {
        var d = a.vence ? diff(D.hoy, a.vence) : null;
        if (a._s === "V") return '<span class="vct-acc-rel is-red">hace ' + (-d) + (d === -1 ? " día" : " días") + "</span>";
        if (a._s === "H") return '<span class="vct-acc-rel is-amb">Hoy</span>';
        if (a._s === "P") return '<span class="vct-acc-rel is-bor">' + (d === 1 ? "Mañana" : "en " + d + " días") + "</span>";
        if (a._s === "L") return '<span class="vct-acc-rel is-gry">en ' + d + " días</span>";
        return '<span class="vct-acc-rel is-gry">Sin fecha</span>';
    }
    function prioBdgA(a) {
        if (!a.prio) return '<span class="vct-acc-muted">-</span>';
        var c = a.prioc;
        return bdg(a.prio, c === "URGENTE" || c === "CRITICA" || c === "ALTA" ? "is-cancel" : c === "MEDIA" ? "is-planned" : "is-neutral");
    }
    function estBdgA(a) { return bdg(a.est || "Pendiente", a.estc === "EN_CURSO" ? "is-active" : (a.estc === "PENDIENTE" || !a.estc) ? "is-neutral" : "is-planned"); }
    function sortIco() { return '<span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>'; }
    function th(t, w, cls, sort) {
        return "<th" + (cls ? ' class="' + cls + '"' : "") + (w ? ' data-vct-width="' + w + '"' : "") + (sort === false ? ' data-vct-export-ignore="true"' : sort === null ? ' title="Sin detallar"' : ' data-vct-sortable="true"') + ">"
             + (t ? "<span>" + t + "</span>" + (sort === false ? "" : sortIco()) : "") + "</th>";
    }
    function dgHost(id, title, unit, ph, filters, actions, head, rows) {
        return '<div class="vtb-dgh" data-vct-dg data-vct-dg-id="' + id + '" data-vct-dg-title="' + esc(title) + '" data-vct-dg-unit="' + unit + '" data-vct-dg-page-size="10"'
             + ' data-vct-dg-search-placeholder="' + esc(ph) + '" data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
             + (filters ? '<div data-vct-dg-slot="filters">' + filters + "</div>" : "") + (actions ? '<div data-vct-dg-slot="actions">' + actions + "</div>" : "")
             + "<table><thead><tr>" + head + "</tr></thead><tbody>" + rows + "</tbody></table></div>";
    }
    function cliProy(D, id) {
        var p = P(D, id), pr = (p.cod ? "(" + p.cod + ") " : "") + p.nom;
        return '<span class="vct-acc-title is-light">' + esc(p.cliente || "Sin cliente") + '</span><span class="vct-acc-sub">' + esc(pr) + "</span>";
    }
    function opt(list) { return list.map(function (o) { return '<option value="' + esc(o[0]) + '">' + esc(o[1]) + "</option>"; }).join(""); }
    function accGrid(st, L, k) {
        var D = st.D, R = L.filter(function (a) { return k === "T" || a._s === k; });
        R.sort(function (a, b) { return (a.vence ? a.vence.getTime() : 9e15) - (b.vence ? b.vence.getTime() : 9e15) || a.id - b.id; });
        var tipos = {}, prios = {};
        R.forEach(function (a) { tipos[a.idt] = a.tipo || "Sin tipo"; prios[a.prioc || "NA"] = a.prio || "Sin prioridad"; });
        var po = { URGENTE: 0, CRITICA: 0, ALTA: 1, MEDIA: 2, BAJA: 3 };
        var fT = Object.keys(tipos).map(function (x) { return [x, tipos[x]]; }).sort(function (a, b) { return a[1].localeCompare(b[1]); });
        var fP = Object.keys(prios).map(function (x) { return [x, prios[x]]; }).sort(function (a, b) { return (po[a[0]] == null ? 9 : po[a[0]]) - (po[b[0]] == null ? 9 : po[b[0]]) || a[1].localeCompare(b[1]); });
        var filters = '<select class="vct-select vct-select-sm" data-vct-dg-filter="tipo" aria-label="Tipo"><option value="">Tipo</option>' + opt(fT) + "</select>"
                    + '<select class="vct-select vct-select-sm" data-vct-dg-filter="prio" aria-label="Prioridad"><option value="">Prioridad</option>' + opt(fP) + "</select>";
        var rows = R.map(function (a) {
            var p = P(D, a.proy), tit = (a.item && a.plan ? a.item + " " : "") + a.tit, sub = a.tipo + (a.subt && a.subt !== a.tipo ? (a.tipo ? " - " : "") + a.subt : "");
            var fv = a.vence ? dm(a.vence) + "/" + a.vence.getFullYear() : "";
            return '<tr data-vct-row data-vct-key="' + a.id + '" data-vct-search="' + esc(tit + " " + sub + " " + p.cliente + " " + p.cod + " " + p.nom + " " + (fv || "sin fecha")) + '"'
                 + ' data-vct-filter-tipo="' + esc(a.idt) + '" data-vct-filter-prio="' + esc(a.prioc || "NA") + '">'
                 + '<td data-label="Vence" data-vct-sort-value="' + (a.vence ? iso(a.vence).replace(/-/g, "") : "99991231") + '" data-vct-export-value="' + (fv || "Sin fecha") + '">'
                 + '<span class="vct-acc-date">' + (fv || "-") + "</span>" + relBdg(D, a) + "</td>"
                 + '<td data-label="Acción" data-vct-sort-value="' + esc(tit) + '" data-vct-export-value="' + esc(tit) + '"><span class="vct-acc-title">' + esc(tit) + "</span>" + (sub ? '<span class="vct-acc-sub">' + esc(sub) + "</span>" : "") + "</td>"
                 + '<td data-label="Cliente / Proyecto" data-vct-sort-value="' + esc(p.cliente) + '" data-vct-export-value="' + esc(p.cliente + " - (" + p.cod + ") " + p.nom) + '">' + cliProy(D, a.proy) + "</td>"
                 + '<td class="vct-text-center" data-label="Prioridad" data-vct-sort-value="' + (po[a.prioc] == null ? 9 : po[a.prioc]) + '" data-vct-export-value="' + esc(a.prio) + '">' + prioBdgA(a) + "</td>"
                 + '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' + esc(a.est) + '" data-vct-export-value="' + esc(a.est) + '">' + estBdgA(a) + "</td>"
                 + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vtb-go="' + a.proy + '" data-vtb-gotab="' + (a.plan ? "plan" : "acciones") + '">Gestionar</button></td></tr>';
        }).join("");
        var info = tabInfo(st, k);
        return dgHost("vtb-acc-" + k, "Acciones - " + info[0], "acci&oacute;n(es)", "Buscar acción, cliente, fecha...", filters, D.nueva,
                      th("Vence", "13%") + th("Acci&oacute;n") + th("Cliente / Proyecto", "28%") + th("Prioridad", "10%", "vct-text-center") + th("Estado", "11%", "vct-text-center") + th("", "110", "vct-col-action", false), rows);
    }
    function visGrid(st) {
        var D = st.D, h = D.hoy;
        var L = D.V.filter(function (v) { return okP(st, v.proy) && v.desde > h && diff(h, v.desde) <= 7 && okQ(st, P(D, v.proy).cliente + " " + P(D, v.proy).nom); }).sort(function (a, b) { return a.desde - b.desde; });
        var rows = L.map(function (v) {
            var p = P(D, v.proy), conf = v.est === "CONFIRMADO";
            return '<tr data-vct-row data-vct-search="' + esc(p.cliente + " " + p.cod + " " + p.nom + " " + dm(v.desde)) + '">'
                 + '<td data-label="Fecha" data-vct-sort-value="' + iso(v.desde).replace(/-/g, "") + '" data-vct-export-value="' + dm(v.desde) + "/" + v.desde.getFullYear() + '">' + dlab(v.desde) + "</td>"
                 + '<td data-label="Cliente / Proyecto" data-vct-sort-value="' + esc(p.cliente) + '" data-vct-export-value="' + esc(p.cliente + " - (" + p.cod + ") " + p.nom) + '">' + cliProy(D, v.proy) + "</td>"
                 + '<td class="vct-text-center" data-label="Servicio" data-vct-sort-value="' + v.svc + '" data-vct-export-value="' + (SVC[v.svc] ? SVC[v.svc][1] : "") + '">' + (svcIco(v.svc) || '<span class="vct-acc-muted">-</span>') + "</td>"
                 + '<td class="vct-text-center" data-label="Horas" data-vct-sort-value="' + v.hp + '" data-vct-export-value="' + H(v.hp) + '">' + H(v.hp) + " h</td>"
                 + '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' + (conf ? 1 : 2) + '" data-vct-export-value="' + (conf ? "Confirmada" : "Pendiente") + '">' + visBdg(v) + "</td>"
                 + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vtb-go="' + v.proy + '" data-vtb-gotab="agenda">Gestionar</button></td></tr>';
        }).join("");
        return dgHost("vtb-vis", "Próximas visitas", "visita(s)", "Buscar cliente, proyecto, fecha...", "", "",
                      th("Fecha", "13%") + th("Cliente / Proyecto") + th("Servicio", "10%", "vct-text-center") + th("Horas", "10%", "vct-text-center") + th("Estado", "12%", "vct-text-center") + th("", "110", "vct-col-action", false), rows);
    }
    function sdList(st) {
        var D = st.D, h = D.hoy;
        return D.V.filter(function (v) { return okP(st, v.proy) && v.desde <= h && v.he - v.dr > 0.05 && okQ(st, P(D, v.proy).cliente + " " + P(D, v.proy).nom); }).sort(function (a, b) { return b.desde - a.desde; });
    }
    function sdGrid(st) {
        var D = st.D, L = sdList(st);
        var rows = L.map(function (v) {
            var p = P(D, v.proy), sd = v.he - v.dr;
            return '<tr data-vct-row data-vct-search="' + esc(p.cliente + " " + p.cod + " " + p.nom + " " + dm(v.desde)) + '">'
                 + '<td data-label="Fecha" data-vct-sort-value="' + iso(v.desde).replace(/-/g, "") + '" data-vct-export-value="' + dm(v.desde) + "/" + v.desde.getFullYear() + '">' + dlab(v.desde) + "</td>"
                 + '<td data-label="Cliente / Proyecto" data-vct-sort-value="' + esc(p.cliente) + '" data-vct-export-value="' + esc(p.cliente + " - (" + p.cod + ") " + p.nom) + '">' + cliProy(D, v.proy) + "</td>"
                 + '<td class="vct-text-center" data-label="Servicio" data-vct-sort-value="' + v.svc + '" data-vct-export-value="' + (SVC[v.svc] ? SVC[v.svc][1] : "") + '">' + (svcIco(v.svc) || '<span class="vct-acc-muted">-</span>') + "</td>"
                 + '<td class="vct-text-center" data-label="Visita" data-vct-sort-value="' + v.he + '" data-vct-export-value="' + H(v.he) + '">' + H(v.he) + " h</td>"
                 + '<td class="vct-text-center" data-label="Sin detallar" data-vct-sort-value="' + sd + '" data-vct-export-value="' + H(sd) + '"><span class="vtb-due-h">' + H(sd) + " h</span></td>"
                 + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vtb-go="' + v.proy + '" data-vtb-gotab="plan">Detallar</button></td></tr>';
        }).join("");
        return dgHost("vtb-sd", "Horas sin detallar", "visita(s)", "Buscar cliente, proyecto, fecha...", "", "",
                      th("Fecha", "13%") + th("Cliente / Proyecto") + th("Servicio", "10%", "vct-text-center") + th("Visita", "10%", "vct-text-center") + th("Sin detallar", "12%", "vct-text-center") + th("", "110", "vct-col-action", false), rows);
    }
    /* calendario unificado (vct-calendario, solo lectura): vencimientos de la pestania + mis visitas + desarrollo */
    function calEvents(st, L, k) {
        var D = st.D, ev = [];
        if (st.capas.ven) L.forEach(function (a) {
            if (!a.vence || (k !== "T" && a._s !== k)) return;
            var p = P(D, a.proy);
            ev.push({ f: iso(a.vence), x: (a.item && a.plan ? a.item + " " : "") + a.tit, c: a._s, cli: p.cliente, proy: "(" + p.cod + ") " + p.nom });
        });
        if (st.capas.vis) D.V.forEach(function (v) {
            if (!okP(st, v.proy)) return;
            var p = P(D, v.proy), sv = SVC[v.svc] ? v.svc + "|" + SVC[v.svc][1] : "";
            Object.keys(v.dd).forEach(function (f) {
                if (!(v.dd[f] > 0)) return;
                ev.push({ f: f, x: "Visita " + (p.cliente || p.nom) + " · " + H(v.dd[f]) + " h", c: pd(f) <= D.hoy ? "VE" : "VP", cli: p.cliente, proy: "(" + p.cod + ") " + p.nom, srv: sv });
            });
        });
        if (st.capas.dev) {
            var g = {};
            D.X.forEach(function (x) { if (!okP(st, x.proy)) return; var key = x.f + "|" + x.proy; (g[key] = g[key] || { f: x.f, proy: x.proy, h: 0, it: [] }).h += x.h; if (x.item) g[key].it.push(x.item); });
            Object.keys(g).forEach(function (key) {
                var o = g[key], p = P(D, o.proy);
                ev.push({ f: o.f, x: "Desarrollo " + (o.it.length ? o.it.slice(0, 3).join(", ") + " · " : "") + H(o.h) + " h", c: "DE", cli: p.cliente, proy: "(" + p.cod + ") " + p.nom });
            });
        }
        return ev;
    }
    function calHtml(st, L, k) {
        var meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
        var nV = L.filter(function (a) { return a.vence && (k === "T" || a._s === k); }).length;
        var capa = function (key, t, n) { return '<button type="button" data-vtb-capa="' + key + '" class="' + (st.capas[key] ? "is-on" : "") + '">' + t + (n == null ? "" : ' <span class="vct-tab-count">' + n + "</span>") + "</button>"; };
        var ev = calEvents(st, L, k);
        return '<div class="vtb-tabs vtb-capas"><span class="vtb-capas-l">Mostrar:</span>' + capa("ven", "Vencimientos", nV) + capa("vis", "Mis visitas") + capa("dev", "Desarrollo") + "</div>"
             + '<div class="vct-agenda vct-acc-cal-unified" data-vct-agenda-root data-vct-feriados="' + esc(JSON.stringify(st.D.F)) + '" data-vct-calendar-events="' + esc(JSON.stringify(ev)) + '">'
             + '<div class="vct-agenda-toolbar"><div class="vct-agenda-nav">'
             + '<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>'
             + '<h2 class="vct-agenda-title" data-vct-agenda-title></h2>'
             + '<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button></div>'
             + '<div class="vct-agenda-view-toggle"><button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>'
             + '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button><button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">Día</button></div>'
             + '<div class="vct-agenda-jump"><select class="vct-select" data-vct-agenda-select-month>' + meses.map(function (m, i) { return '<option value="' + (i + 1) + '">' + m + "</option>"; }).join("")
             + '</select><select class="vct-select" data-vct-agenda-select-year></select></div></div><div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div></div>'
             + '<div class="vtb-calleg"><span class="vct-agenda-event ev-V">vencida</span><span class="vct-agenda-event ev-H">vence hoy</span><span class="vct-agenda-event ev-P">vence en 7 días</span>'
             + '<span class="vct-agenda-event ev-L">vence más adelante</span><span class="vct-agenda-event ev-VE">visita hecha</span><span class="vct-agenda-event ev-VP">visita programada</span>'
             + '<span class="vct-agenda-event ev-DE">desarrollo cargado</span></div>';
    }
    /* graficos de Acciones (mismo calculo que VCT_MAIN_ACCIONES, vista del consultor) */
    function accCharts(st, L) {
        var D = st.D, h = D.hoy, by = {}, i;
        L.forEach(function (a) {
            var k = a.proy || "0", p = P(D, a.proy);
            var g = by[k] = by[k] || { e: "(" + p.cod + ") " + p.nom, V: 0, H: 0, P: 0, L: 0, T: 0 };
            g[a._s === "S" ? "L" : a._s]++; g.T++;
        });
        var G1 = Object.keys(by).map(function (k) { return by[k]; }).sort(function (a, b) { return b.T - a.T || a.e.localeCompare(b.e); }).slice(0, 8), mx = G1.length ? G1[0].T : 1;
        var w = function (v) { return (100 * v / mx).toFixed(2); };
        var g1 = G1.map(function (g) {
            return '<div class="vct-acc-hb"><span class="vct-acc-hb-name" title="' + esc(g.e) + '">' + esc(g.e) + '</span><span class="vct-acc-hb-bar">'
                 + (g.V ? '<i class="is-red" style="width:' + w(g.V) + '%" title="Vencidas: ' + g.V + '"></i>' : "") + (g.H ? '<i class="is-amb" style="width:' + w(g.H) + '%" title="Hoy: ' + g.H + '"></i>' : "")
                 + (g.P ? '<i class="is-bor" style="width:' + w(g.P) + '%" title="Próximas: ' + g.P + '"></i>' : "") + (g.L ? '<i class="is-gry" style="width:' + w(g.L) + '%" title="Más adelante / sin fecha: ' + g.L + '"></i>' : "")
                 + "</span><b>" + g.T + "</b></div>";
        }).join("") || '<div class="vct-acc-empty">No hay acciones abiertas.</div>';
        g1 += '<div class="vct-acc-lg"><span><i class="is-red"></i>Vencidas</span><span><i class="is-amb"></i>Hoy</span><span><i class="is-bor"></i>Próximas</span><span><i class="is-gry"></i>Más adelante / sin fecha</span></div>';
        var d14 = [];
        for (i = 0; i < 14; i++) { var dd = add(h, i), c = L.filter(function (a) { return a.vence && iso(a.vence) === iso(dd); }).length; d14.push([dd, c]); }
        var m2 = Math.max.apply(null, d14.map(function (x) { return x[1]; }));
        var g2 = '<div class="vct-acc-cols">' + d14.map(function (x, j) {
            var we = x[0].getDay() === 0 || x[0].getDay() === 6;
            return '<span class="' + (j === 0 ? "is-today" : we ? "is-we" : "") + '" style="height:' + (!m2 || !x[1] ? 2 : Math.round(100 * x[1] / m2)) + '%" title="' + dm(x[0]) + ": " + x[1] + '">' + (x[1] ? "<em>" + x[1] + "</em>" : "") + "</span>";
        }).join("") + '</div><div class="vct-acc-clb">' + d14.map(function (x) { return "<span>" + ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"][x[0].getDay()] + "<br>" + x[0].getDate() + "</span>"; }).join("") + "</div>";
        var ms = [], tt = 0, ok = 0;
        for (i = -5; i <= 0; i++) {
            var m0d = new Date(h.getFullYear(), h.getMonth() + i, 1), m1d = new Date(h.getFullYear(), h.getMonth() + i + 1, 1);
            var cl = D.A.filter(function (a) { return a.fin && a.estc !== "CANCELADA" && a.cierre && a.cierre >= m0d && a.cierre < m1d && okP(st, a.proy); });
            var o = cl.filter(function (a) { return !a.vence || a.cierre <= a.vence; }).length;
            ms.push([MN[m0d.getMonth()].charAt(0).toUpperCase() + MN[m0d.getMonth()].slice(1), cl.length, o, i === 0]); tt += cl.length; ok += o;
        }
        var g3 = '<div class="vct-acc-cols is-pct">' + ms.map(function (x) {
            var pc = x[1] ? Math.round(100 * x[2] / x[1]) : 0;
            return '<span class="' + (x[3] ? "is-today" : "") + '" style="height:' + (x[1] ? pc : 2) + '%" title="' + x[2] + " de " + x[1] + ' a término"><em>' + (x[1] ? pc + "%" : "-") + "</em></span>";
        }).join("") + '</div><div class="vct-acc-clb">' + ms.map(function (x) { return "<span>" + x[0] + "</span>"; }).join("") + "</div>";
        var tp = {};
        L.forEach(function (a) { var k = a.idt || "0"; (tp[k] = tp[k] || { e: a.tipo || "Sin tipo", c: 0 }).c++; });
        var G4 = Object.keys(tp).map(function (k) { return tp[k]; }).sort(function (a, b) { return b.c - a.c || a.e.localeCompare(b.e); });
        if (G4.length > 5) { var ot = G4.slice(4).reduce(function (s2, x) { return s2 + x.c; }, 0); G4 = G4.slice(0, 4).concat([{ e: "Otros", c: ot }]); }
        var cols = ["#8C1D47", "#4A4849", "#CF6F92", "#8E8C8D", "#D9C3CD"], ac = 0, tot = L.length || 1;
        var grad = G4.map(function (x, j) { var s1 = (100 * ac / tot).toFixed(2); ac += x.c; return cols[j] + " " + s1 + "% " + (100 * ac / tot).toFixed(2) + "%"; }).join(",");
        var g4 = '<div class="vct-acc-dn"><div class="vct-acc-donut" style="background:' + (L.length ? "conic-gradient(" + grad + ")" : "#EEF2F7") + '"><b>' + L.length + '</b></div><div class="vct-acc-dl">'
               + (G4.map(function (x, j) { return '<span><i style="background:' + cols[j] + '"></i><em>' + esc(x.e) + "</em><b>" + x.c + "</b></span>"; }).join("") || '<span class="vct-acc-muted">Sin datos</span>') + "</div></div>";
        var ch = function (t, s, b) { return '<div class="vct-acc-chart"><div class="vct-acc-chart-t">' + t + "<small>" + s + "</small></div>" + b + "</div>"; };
        return '<div class="vct-acc-charts">' + ch("Abiertas por proyecto", "las 8 con más carga", g1) + ch("Vencimientos de los próximos 14 días", "acciones abiertas por día", g2)
             + ch("Cumplidas a término", tt ? Math.round(100 * ok / tt) + "% en los últimos 6 meses (" + ok + " de " + tt + ")" : "sin acciones cerradas en los últimos 6 meses", g3)
             + ch("Abiertas por tipo", L.length + " acciones abiertas", g4) + "</div>";
    }
    function foldBtn(st, k) {
        var f = !!st.pr.folded[k];
        return '<button type="button" class="vtb-fold" data-vtb-fold="' + k + '" title="' + (f ? "Desplegar" : "Plegar") + '" aria-expanded="' + !f + '">' + svgI(f ? "chevron-right" : "chevron-left").replace("<svg ", '<svg style="transform:rotate(' + (f ? 0 : -90) + 'deg)" ') + "</button>";
    }
    function paraHacer(st) {
        var D = st.D, L = abiertas(st), nSd = sdList(st).length, fold = !st.edit && !!st.pr.folded.hacer;
        var nVis = D.V.filter(function (v) { return okP(st, v.proy) && v.desde > D.hoy && diff(D.hoy, v.desde) <= 7; }).length;
        if (!st.atab) st.atab = tabIni(L);
        var cnt = { acc: L.length, vis: nVis, sd: nSd };
        var sub = { acc: "Acciones a tu cargo, de todos tus proyectos.", vis: "Tus próximas visitas (de mañana a 7 días), con las horas planificadas para vos.",
                    sd: "Visitas ya hechas con horas sin desarrollo registrado por vos." }[st.modo];
        var sel = '<div class="vct-acc-view vtb-modo" role="group" aria-label="Grilla">' + MODOS.map(function (m) {
            return '<button type="button" data-vct-acc-view="' + m[0] + '" data-vtb-modo="' + m[0] + '" class="' + (st.modo === m[0] ? "is-on" : "") + '" aria-pressed="' + (st.modo === m[0]) + '">'
                 + svgI(m[2]) + "<span>" + m[1] + '</span><small class="vtb-mcnt">' + cnt[m[0]] + "</small></button>";
        }).join("") + "</div>";
        var top = '<div class="vct-360-box-head vtb-ph-top"><div class="vtb-ph-tt"><h3><span class="vct-360-title-icon">' + ic("clipboard-check") + "</span>Para hacer</h3>"
                + '<div class="vct-360-box-subtitle">' + sub + "</div></div>" + (fold ? "" : sel) + foldBtn(st, "hacer") + "</div>";
        if (fold) return '<div class="vct-360-box vtb-phbox vtb-cardx is-folded" data-vtb-card="hacer">' + top + "</div>";
        var body;
        if (st.modo === "acc") {
            var k = st.atab, info = tabInfo(st, k);
            var tabs = '<div class="vct-360-tabsbar vct-acc-tabs vtb-ph-tabs">' + ATABS.map(function (t) {
                var n = cntTab(L, t[0]);
                return '<button type="button" class="vct-ini-tab' + (k === t[0] ? " is-active" : "") + '" data-vtb-atab="' + t[0] + '">' + ic(t[2]) + "<span>" + t[1] + '</span><small class="vct-acc-cnt ' + (n ? t[3] : "is-zero") + '">' + n + "</small></button>";
            }).join("") + '<button type="button" class="vct-ini-tab vct-acc-tab-graf' + (k === "G" ? " is-active" : "") + '" data-vtb-atab="G">' + ic("chart-bar") + "<span>Gráficos</span></button></div>";
            var conCal = k !== "S" && k !== "G", vista = conCal ? st.aview : "lista";
            var head = '<div class="vct-360-box-head vct-acc-head"><div class="vct-acc-head-txt"><h3><span class="vct-360-title-icon">' + ic(info[1]) + "</span>" + info[0] + (k === "G" ? "" : " (" + cntTab(L, k) + ")") + "</h3>"
                     + '<p class="vct-360-box-subtitle">' + info[2] + "</p></div>"
                     + (conCal ? '<div class="vct-acc-view" role="group" aria-label="Vista"><button type="button" data-vct-acc-view="lista" data-vtb-aview="lista" class="' + (vista === "lista" ? "is-on" : "") + '">' + svgI("list-checks") + "<span>Lista</span></button>"
                                + '<button type="button" data-vct-acc-view="calendario" data-vtb-aview="cal" class="' + (vista === "cal" ? "is-on" : "") + '">' + svgI("calendar-days") + "<span>Calendario</span></button></div>" : "") + "</div>";
            body = tabs + '<div class="vtb-ph-in">' + head + (k === "G" ? accCharts(st, L) : vista === "cal" ? calHtml(st, L, k) : '<div class="vtb-ph-grid">' + accGrid(st, L, k) + "</div>") + "</div>";
        } else {
            body = '<div class="vtb-ph-in"><div class="vtb-ph-grid">' + (st.modo === "vis" ? visGrid(st) : sdGrid(st)) + "</div></div>";
        }
        return '<div class="vct-360-box vtb-phbox vtb-cardx vct-acc-module" data-vct-acc data-vtb-card="hacer">' + top + body + "</div>";
    }

    /* ---------------- card: mis proyectos (diseno de la grilla Proyectos + columnas del tablero) ---------------- */
    var SVCN = { CO: "Consultoría", AU: "Auditoría", CA: "Capacitación" };
    /* servicios apilados: los tres iconos superpuestos, en color los del proyecto; el detalle va en el tooltip */
    function svcStack(list) {
        var on = {}, names = [];
        list.forEach(function (c) { on[c] = true; });
        ["CO", "AU", "CA"].forEach(function (c) { if (on[c]) names.push(SVCN[c]); });
        var tip = names.length ? "Servicios: " + names.join(", ") : "Sin servicios";
        return '<span class="vtb-svcs" title="' + esc(tip) + '" tabindex="0">' + ["CO", "AU", "CA"].map(function (c) {
            return '<span class="vctdg-svc is-' + c.toLowerCase() + (on[c] ? " is-on" : "") + '">' + ic(SVC[c][0]) + "</span>";
        }).join("") + "</span>";
    }
    function normList(list) {
        if (!list.length) return '<span class="vctdg-none">-</span>';
        var sh = list.slice(0, 3);
        return '<span class="vctdg-list" title="' + esc(list.join(" · ")) + '">' + sh.map(function (n) { return '<span class="vctdg-li">' + esc(n) + "</span>"; }).join("")
             + (list.length > 3 ? '<span class="vctdg-li is-more">+' + (list.length - 3) + " más</span>" : "") + "</span>";
    }
    function dateTile(d) {
        if (!d) return '<span class="vctdg-none">—</span>';
        return '<span class="vtb-dtile" title="' + DN[d.getDay()] + " " + dm(d) + "/" + d.getFullYear() + '"><span class="vtb-dtile-m">' + MN[d.getMonth()].toUpperCase()
             + '</span><span class="vtb-dtile-d">' + d.getDate() + '</span><span class="vtb-dtile-w">' + DN[d.getDay()].toLowerCase() + "</span></span>";
    }
    function proyectos(st) {
        var D = st.D, h = D.hoy, fold = !st.edit && !!st.pr.folded.proy;
        var L = D.plist.filter(function (p) { return p.activo && okP(st, p.id) && (okQ(st, p.nom) || okQ(st, p.cliente) || okQ(st, p.cod) || okQ(st, p.normas.join(" "))); });
        L.forEach(function (p) {
            var mine = D.A.filter(function (a) { return a.proy === p.id && !a.fin; });
            p._ven = mine.filter(function (a) { return a.vence && a.vence < h; }).length;
            p._abi = mine.length;
            p._sd = D.V.filter(function (v) { return v.proy === p.id && v.desde <= h; }).reduce(function (a, v) { return a + Math.max(v.he - v.dr, 0); }, 0);
            p._nx = D.V.filter(function (v) { return v.proy === p.id && v.desde > h; }).sort(function (a, b) { return a.desde - b.desde; })[0] || null;
            var d = p.tiempo == null ? 0 : p.plan - p.tiempo;
            p._st = d <= -15 || p._ven >= 3 ? "bad" : (d < 0 || p._ven) ? "warn" : "ok";
        });
        var ord = { bad: 0, warn: 1, ok: 2 }, EST = { bad: ["Atrasado", "is-cancel"], warn: ["Atención", "is-paused"], ok: ["En tiempo", "is-active"] };
        L.sort(function (a, b) { return ord[a._st] - ord[b._st] || ((a.plan - (a.tiempo || 0)) - (b.plan - (b.tiempo || 0))); });
        var combos = {};
        L.forEach(function (p) { var k = p.svcs.join(",") || "-"; combos[k] = p.svcs.length ? p.svcs.map(function (c) { return SVCN[c]; }).join(" + ") : "Sin servicio"; });
        var filters = '<select class="vct-select vct-select-sm" data-vct-dg-filter="est" aria-label="Estado del plan"><option value="">Estado del plan</option><option value="bad">Atrasado</option><option value="warn">Atención</option><option value="ok">En tiempo</option></select>'
                    + '<select class="vct-select vct-select-sm" data-vct-dg-filter="svc" aria-label="Servicio"><option value="">Servicio</option>' + opt(Object.keys(combos).map(function (k) { return [k, combos[k]]; })) + "</select>";
        var rows = L.map(function (p) {
            var t = p.tiempo == null ? null : Math.max(0, Math.min(100, p.tiempo)), est = EST[p._st], nx = p._nx;
            return '<tr data-vct-row data-vct-key="' + p.id + '" data-vct-search="' + esc(p.cliente + " " + p.cod + " " + p.nom + " " + p.srv + " " + p.normas.join(" ") + " " + p.anNom) + '"'
                 + ' data-vct-filter-est="' + p._st + '" data-vct-filter-svc="' + esc(p.svcs.join(",") || "-") + '">'
                 + '<td data-label="Cliente" data-vct-sort-value="' + esc(p.cliente) + '" data-vct-export-value="' + esc(p.cliente) + '"><span class="vtb-cli">' + esc(p.cliente || "Sin cliente") + "</span></td>"
                 + '<td data-label="Proyecto" data-vct-sort-value="' + esc(p.nom) + '" data-vct-export-value="' + esc("(" + p.cod + ") " + p.nom) + '"><span class="vct-360-project-name">' + esc("(" + p.cod + ") " + p.nom) + "</span>"
                 + (p.srv ? '<span class="vct-360-project-ref">' + esc(p.srv) + "</span>" : "") + "</td>"
                 + '<td class="vct-text-center" data-label="Servicios" data-vct-sort-value="' + esc(p.svcs.join(",")) + '" data-vct-export-value="' + esc(p.svcs.map(function (c) { return SVCN[c]; }).join(", ")) + '">' + svcStack(p.svcs) + "</td>"
                 + '<td data-label="Normas" data-vct-sort-value="' + esc(p.normas.join(", ")) + '" data-vct-export-value="' + esc(p.normas.join(", ")) + '">' + normList(p.normas) + "</td>"
                 + '<td class="vct-text-center" data-label="Analista" data-vct-sort-value="' + esc(p.anNom) + '" data-vct-export-value="' + esc(p.anNom) + '">' + (p.anIni ? '<span class="vctdg-avatar is-a" title="' + esc(p.anNom) + '">' + esc(p.anIni) + "</span>" : '<span class="vctdg-none">-</span>') + "</td>"
                 + '<td data-label="Plan vs. tiempo" data-vct-sort-value="' + (p.plan - (t || 0)) + '" data-vct-export-value="' + p.plan + "% plan" + (t != null ? " / " + Math.round(t) + "% tiempo" : "") + '">'
                 + '<div class="vtb-bul-b is-sm"><span class="vtb-bul-p" style="width:' + Math.min(100, p.plan) + '%"></span>' + (t != null ? '<i style="left:' + t + '%"></i>' : "") + "</div>"
                 + '<small class="vtb-sub">' + p.plan + "% plan" + (t != null ? " · " + Math.round(t) + "% tiempo" : "") + "</small></td>"
                 + '<td class="vct-text-center" data-label="Horas" data-vct-sort-value="' + p.hej + '" data-vct-export-value="' + H(p.hej) + (p.hpr ? " / " + H(p.hpr) : "") + '"><span class="vtb-nw">' + H(p.hej) + (p.hpr ? " / " + H(p.hpr) + " h" : " h") + "</span>"
                 + (p.hpr ? '<small class="vtb-sub">' + Math.round(p.hej * 100 / p.hpr) + "% horas</small>" : "") + "</td>"
                 + '<td class="vct-text-center" data-label="Acciones" data-vct-sort-value="' + (p._ven * 1000 + p._abi) + '" data-vct-export-value="' + p._ven + " vencidas / " + p._abi + ' abiertas"><span class="vtb-accs">'
                 + (p._ven ? bdg(p._ven + " vencida" + (p._ven > 1 ? "s" : ""), "is-cancel") : "") + '<small class="vtb-sub">' + p._abi + " abierta" + (p._abi === 1 ? "" : "s") + "</small></span></td>"
                 + '<td class="vct-text-center" data-label="Sin detallar" data-vct-sort-value="' + p._sd + '" data-vct-export-value="' + H(p._sd) + '">' + (p._sd > 0.05 ? '<span class="vtb-sdb" title="Sin detallar: ' + H(p._sd) + ' h de visitas ya hechas sin desarrollo cargado">' + H(p._sd) + "<small>h</small></span>" : '<span class="vctdg-none">—</span>') + "</td>"
                 + '<td class="vct-text-center" data-label="Próx. visita" data-vct-sort-value="' + (nx ? iso(nx.desde).replace(/-/g, "") : "99991231") + '" data-vct-export-value="' + (nx ? dm(nx.desde) + "/" + nx.desde.getFullYear() : "") + '">' + dateTile(nx ? nx.desde : null) + "</td>"
                 + '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' + ord[p._st] + '" data-vct-export-value="' + est[0] + '">' + bdg(est[0], est[1]) + "</td>"
                 + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true">' + rmenu([["Plan estratégico (V360)", "list-checks", p.id, "plan"], ["Visitas (V360)", "calendar", p.id, "agenda"], ["Abrir V360", "eye", p.id, ""]]) + "</td></tr>";
        }).join("");
        var head = th("Cliente", "11%") + th("Proyecto", "16%") + th("Servicios", "64px", "vct-text-center") + th("Normas", "11%") + th("Analista", "72px", "vct-text-center")
                 + th("Plan vs. tiempo", "13%") + th("Horas", "8%", "vct-text-center") + th("Acciones", "9%", "vct-text-center") + th("", "52px", "vct-text-center", null)
                 + th("Próx. visita", "60px", "vct-text-center") + th("Estado", "96px", "vct-text-center") + th("", "48", "vct-col-action", false);
        var body = '<div class="vtb-pj-grid">' + dgHost("vtb-proy", "Mis proyectos", "proyecto(s)", "Buscar cliente, proyecto, norma...", filters, "", head, rows) + "</div>";
        return '<div class="vct-360-box vtb-box vtb-cardx vtb-pjbox' + (fold ? " is-folded" : "") + '" data-vtb-card="proy"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon">' + ic("folder") + "</span>Mis proyectos</h3>"
             + '<div class="vct-360-box-subtitle">activos · primero los atrasados</div></div>' + foldBtn(st, "proy") + "</div>" + (fold ? "" : body) + "</div>";
    }

    /* ---------------- graficos (SVG, una sola escala por grafico) ---------------- */
    function svg(W, Hh, inner, lbl) { return '<svg viewBox="0 0 ' + W + " " + Hh + '" class="vtb-svg" role="img" aria-label="' + esc(lbl) + '">' + inner + "</svg>"; }
    function grid(L, W, y, vals, unit) {
        return vals.map(function (g) { return '<line x1="' + L + '" x2="' + (W - 6) + '" y1="' + y(g).toFixed(1) + '" y2="' + y(g).toFixed(1) + '" class="vtb-grid"/><text x="' + (L - 4) + '" y="' + (y(g) + 3).toFixed(1) + '" class="vtb-ax" text-anchor="end">' + g + unit + "</text>"; }).join("");
    }
    function legend(items) { return '<div class="vtb-cap-leg">' + items.map(function (i) { return '<span class="vtb-lgi"><i class="' + (i[2] || "vtb-sw-c") + '" style="background:' + i[1] + '"></i>' + i[0] + "</span>"; }).join("") + "</div>"; }
    function chHorasDia(st) {
        var D = st.D, h = D.hoy, f0 = st.mes, n = new Date(f0.getFullYear(), f0.getMonth() + 1, 0).getDate();
        var W = 560, Hh = 190, L = 30, B = 24, bw = (W - L - 10) / n, mx = 8;
        var byDay = {}, devD = {};
        D.X.forEach(function (x) { if (okP(st, x.proy)) devD[x.f] = (devD[x.f] || 0) + x.h; });
        D.V.forEach(function (v) { if (!okP(st, v.proy)) return; Object.keys(v.dd).forEach(function (k) { byDay[k] = (byDay[k] || 0) + v.dd[k]; }); });
        Object.keys(byDay).forEach(function (k) { if (byDay[k] > mx) mx = byDay[k]; });
        mx = Math.ceil(mx / 4) * 4;
        var y = function (v) { return Hh - B - v * (Hh - B - 12) / mx; };
        var o = grid(L, W, y, [0, mx / 2, mx], " h");
        for (var i = 0; i < n; i++) {
            var d = add(f0, i), k = iso(d), x = L + i * bw + 2, g = D.G[k], we = d.getDay() === 0 || d.getDay() === 6;
            if (we || (g && g.fer)) o += '<rect x="' + (x - 1).toFixed(1) + '" y="12" width="' + (bw - 2).toFixed(1) + '" height="' + (Hh - B - 12) + '" class="vtb-we"><title>' + dm(d) + (g && g.fer ? ": feriado" : ": fin de semana") + "</title></rect>";
            else if (g && (g.tipo === "LICENCIA" || g.tipo === "POTENCIAL" || g.tipo === "OCUPADO" || g.tipo === "NO_DISPONIBLE" || g.tipo === "ORGANISMO")) o += '<rect x="' + x.toFixed(1) + '" y="' + y(8).toFixed(1) + '" width="' + (bw - 4).toFixed(1) + '" height="' + (y(0) - y(8)).toFixed(1) + '" rx="3" fill="' + ({ LICENCIA: CL.lic, POTENCIAL: CL.pot, ORGANISMO: CL.org }[g.tipo] || CL.oc) + '" fill-opacity=".18"><title>' + dm(d) + ": " + g.tipo.toLowerCase().replace("_", " ") + "</title></rect>";
            var hv = byDay[k] || 0, dv = devD[k] || 0, fut = d > h;
            if (hv > 0) o += '<rect x="' + x.toFixed(1) + '" y="' + y(hv).toFixed(1) + '" width="' + (bw - 4).toFixed(1) + '" height="' + (y(0) - y(hv)).toFixed(1) + '" rx="3" fill="' + (fut ? CL.pr : CL.ej) + '"><title>' + dm(d) + ": " + H(hv) + " h de visita" + (fut ? " (programada)" : "") + ", " + H(dv) + " h de desarrollo</title></rect>";
            if (dv > 0) o += '<circle cx="' + (x + (bw - 4) / 2).toFixed(1) + '" cy="' + y(Math.min(dv, mx)).toFixed(1) + '" r="3.2" fill="' + (fut ? CL.sin : CL.det) + '" stroke="#fff" stroke-width="1.5"><title>' + dm(d) + ": " + H(dv) + " h de desarrollo</title></circle>";
            if ((i + 1) % 5 === 0 || i === 0) o += '<text x="' + (x + (bw - 4) / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + (i + 1) + "</text>";
        }
        var xh = L + (h.getDate() - 1) * bw + bw / 2;
        o += '<line x1="' + xh.toFixed(1) + '" x2="' + xh.toFixed(1) + '" y1="10" y2="' + (Hh - B) + '" class="vtb-today"/><text x="' + xh.toFixed(1) + '" y="9" class="vtb-ax vtb-today-t" text-anchor="middle">hoy</text>';
        return boxH("Horas por día", "chart-bar", svg(W, Hh, o, "Horas por dia") + legend([["Ejecutadas", CL.ej], ["Programadas", CL.pr], ["Desarrollo registrado", CL.det, "vtb-dot"], ["Desarrollo programado", CL.sin, "vtb-dot"], ["Licencia", CL.lic], ["Potencial", CL.pot], ["Ocupado / ND", CL.oc], ["Fin de semana / feriado", "#F1F5F9"]]),
                    mlabel(st.mes) + " · barra = horas de visita del día · punto = horas de desarrollo");
    }
    function chAccDia(st) {
        var D = st.D, h = D.hoy, W = 560, Hh = 190, L = 30, B = 24, days = [];
        for (var i = -2; i <= 11; i++) days.push(add(h, i));
        var data = days.map(function (d) {
            var k = iso(d), v = 0, n = 0, c = 0;
            D.A.forEach(function (a) {
                if (!okP(st, a.proy)) return;
                if (!a.fin && a.vence && iso(a.vence) === k) { if (d < h) v++; else n++; }
                if (a.fin && a.estc === "CUMPLIDA" && a.cierre && iso(a.cierre) === k) c++;
            });
            return [d, v, n, c];
        });
        var mx = Math.max(4, Math.max.apply(null, data.map(function (x) { return Math.max(x[1] + x[2], x[3]); })));
        var y = function (v) { return Hh - B - v * (Hh - B - 12) / mx; }, bw = (W - L - 10) / data.length;
        var o = grid(L, W, y, [0, Math.round(mx / 2), mx], "");
        data.forEach(function (r, i) {
            var x = L + i * bw + 6, w = (bw - 14) / 2, base = 0;
            [[r[1], "#B42318", "quedaron vencidas"], [r[2], "#D97706", "vencen"]].forEach(function (s) {
                if (!s[0]) return;
                o += '<rect x="' + x.toFixed(1) + '" y="' + y(base + s[0]).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(base) - y(base + s[0]) - (base ? 2 : 0)).toFixed(1) + '" rx="3" fill="' + s[1] + '"><title>' + dm(r[0]) + ": " + s[0] + " " + s[2] + "</title></rect>";
                base += s[0];
            });
            if (r[3]) o += '<rect x="' + (x + w + 2).toFixed(1) + '" y="' + y(r[3]).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(0) - y(r[3])).toFixed(1) + '" rx="3" fill="#0F9F8F"><title>' + dm(r[0]) + ": " + r[3] + " cumplidas</title></rect>";
            o += '<text x="' + (x + w).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + r[0].getDate() + "</text>";
        });
        var xh = L + 2 * bw + bw / 2;
        o += '<line x1="' + xh.toFixed(1) + '" x2="' + xh.toFixed(1) + '" y1="10" y2="' + (Hh - B) + '" class="vtb-today"/><text x="' + xh.toFixed(1) + '" y="9" class="vtb-ax vtb-today-t" text-anchor="middle">hoy</text>';
        return boxH("Acciones por día", "list-checks", svg(W, Hh, o, "Acciones por dia") + legend([["Vencen ese día", "#D97706"], ["Quedaron vencidas", "#B42318"], ["Cumplidas ese día", "#0F9F8F"]]), "últimos 2 días y próximos 11 · a mi cargo");
    }
    function chMes(st) {
        var M = st.D.M, W = 560, Hh = 190, L = 36, B = 24;
        var mx = Math.max(8, Math.max.apply(null, M.map(function (m) { return Math.max(m.c, m.e + m.p); }).concat([0])));
        mx = Math.ceil(mx / 40) * 40;
        var y = function (v) { return Hh - B - v * (Hh - B - 14) / mx; }, bw = (W - L - 10) / Math.max(M.length, 1);
        var o = grid(L, W, y, [0, mx / 2, mx], " h");
        M.forEach(function (m, i) {
            var x = L + i * bw + bw * 0.22, w = bw * 0.56;
            if (m.e) o += '<rect x="' + x.toFixed(1) + '" y="' + y(m.e).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(0) - y(m.e)).toFixed(1) + '" rx="4" fill="' + CL.ej + '"><title>' + esc(m.l) + ": " + H(m.e) + " h ejecutadas</title></rect>";
            if (m.p) o += '<rect x="' + x.toFixed(1) + '" y="' + y(m.e + m.p).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(m.e) - y(m.e + m.p) - (m.e ? 2 : 0)).toFixed(1) + '" rx="4" fill="' + CL.pr + '"><title>' + esc(m.l) + ": " + H(m.p) + " h programadas</title></rect>";
            if (m.c) o += '<line x1="' + (x - 4).toFixed(1) + '" x2="' + (x + w + 4).toFixed(1) + '" y1="' + y(m.c).toFixed(1) + '" y2="' + y(m.c).toFixed(1) + '" stroke="#1e293b" stroke-width="2" stroke-linecap="round"><title>' + esc(m.l) + ": capacidad " + H(m.c) + " h</title></line>";
            o += '<text x="' + (x + w / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + esc(m.l) + "</text>";
            if (m.c) o += '<text x="' + (x + w / 2).toFixed(1) + '" y="' + (y(Math.max(m.c, m.e + m.p)) - 5).toFixed(1) + '" class="vtb-ax" text-anchor="middle" style="font-weight:700;fill:#1e293b">' + Math.round((m.e + m.p) * 100 / m.c) + "%</text>";
        });
        return boxH("Horas por mes", "chart-bar", svg(W, Hh, o, "Horas por mes") + legend([["Ejecutadas", CL.ej], ["Programadas (mes en curso)", CL.pr], ["Capacidad (días disponibles × 8)", "#1e293b", "vtb-tick"]]), "últimos 6 meses · % = uso de la capacidad");
    }
    function chVenc(st) {
        var D = st.D, h = D.hoy, b = [0, 0, 0, 0, 0];
        D.A.forEach(function (a) {
            if (a.fin || !okP(st, a.proy)) return;
            var v = a.vence;
            b[!v ? 4 : v < h ? 0 : diff(h, v) === 0 ? 1 : diff(h, v) <= 7 ? 2 : 3]++;
        });
        var L = [["Vencidas", "#B42318", "V"], ["Hoy", "#D97706", "H"], ["7 días", "#D97706", "P"], ["Más adelante", "#64748B", "T"], ["Sin fecha", "#94A3B8", "S"]], mx = Math.max.apply(null, b) || 1;
        var r = L.map(function (l, i) { return '<div class="vtb-hb" data-vtb-ptab="' + l[2] + '" role="button" title="Ver en Para hacer"><span class="vtb-hb-n">' + l[0] + '</span><div class="vtb-hb-b"><span style="width:' + Math.max(b[i] * 100 / mx, b[i] ? 2 : 0) + "%;background:" + l[1] + '"></span></div><b>' + b[i] + "</b></div>"; }).join("");
        return boxH("Acciones abiertas por vencimiento", "list-checks", r + '<div class="vtb-help">Tocá una barra para verlas en Para hacer.</div>', (b[0] + b[1] + b[2] + b[3] + b[4]) + " abiertas a mi cargo");
    }
    function chProy(st) {
        var D = st.D, f0 = st.mes, f1 = new Date(f0.getFullYear(), f0.getMonth() + 1, 0);
        D.plist.forEach(function (p) { p.asig = 0; p.dev = 0; });
        D.V.forEach(function (v) { var p = D.P[v.proy]; if (p && v.desde >= f0 && v.desde <= f1) { p.asig += v.hp; p.dev += v.dr; } });
        var L = D.plist.filter(function (p) { return okP(st, p.id) && (st.prk === "mes" ? p.asig + p.dev > 0 : p.h12 > 0); });
        L.sort(function (a, b) { return st.prk === "mes" ? b.asig - a.asig : b.h12 - a.h12; });
        L = L.slice(0, 8);
        var mx = Math.max.apply(null, L.map(function (p) { return st.prk === "mes" ? Math.max(p.asig, p.dev) : p.h12; }).concat([1]));
        var r = L.map(function (p) {
            var a = st.prk === "mes" ? p.asig : p.h12;
            return '<div class="vtb-hp"><div class="vtb-hp-n">' + ptag(D, p.id, true) + '<small>' + esc(p.srv || p.nom) + '</small></div><div class="vtb-hp-b"><span style="width:' + (a * 100 / mx) + "%;background:" + p.col + '" title="' + (st.prk === "mes" ? "Asignadas" : "Ejecutadas") + ": " + H(a) + ' h"></span>'
                 + (st.prk === "mes" ? '<span style="width:' + (p.dev * 100 / mx) + '%;background:' + CL.det + '" title="Desarrollo registrado: ' + H(p.dev) + ' h"></span>' : "") + '</div><div class="vtb-hp-v"><b>' + H(a) + " h</b>" + (st.prk === "mes" ? " / " + H(p.dev) + " h dev." : "") + "</div></div>";
        }).join("") || '<div class="vtb-empty">Sin horas en el período.</div>';
        var tools = '<div class="vtb-chips"><button type="button" data-vtb-prk="mes" class="' + (st.prk === "mes" ? "is-on" : "") + '">Mes</button><button type="button" data-vtb-prk="12" class="' + (st.prk !== "mes" ? "is-on" : "") + '">12 meses</button></div>';
        return boxH("Horas por proyecto", "briefcase", r + (st.prk === "mes" ? legend([["Asignadas en visitas (color del proyecto)", "#64748B"], ["Desarrollo registrado", CL.det]]) : legend([["Ejecutadas, últimos 12 meses", "#64748B"]])),
                    st.prk === "mes" ? mlabel(st.mes) + " · asignadas y desarrollo" : "ejecutadas, últimos 12 meses", tools);
    }
    function chPlan(st) {
        var D = st.D, L = D.plist.filter(function (p) { return p.activo && okP(st, p.id); });
        var r = L.map(function (p) {
            var t = p.tiempo == null ? null : Math.max(0, Math.min(100, p.tiempo)), d = t == null ? 0 : p.plan - t;
            return '<div class="vtb-bul"><div class="vtb-hp-n">' + ptag(D, p.id, true) + '</div><div class="vtb-bul-b"><span class="vtb-bul-p" style="width:' + Math.min(100, p.plan) + '%"></span>' + (t != null ? '<i style="left:' + t + '%" title="Tiempo transcurrido ' + Math.round(t) + '%"></i>' : "") + "</div>"
                 + '<div class="vtb-bul-v is-' + (d <= -15 ? "bad" : d < 0 ? "warn" : "ok") + '"><b>' + p.plan + "%</b> plan" + (t != null ? " · " + Math.round(t) + "% tiempo" : "") + "</div></div>";
        }).join("") || '<div class="vtb-empty">Sin proyectos activos.</div>';
        return boxH("¿Voy atrasado?", "clock-3", r + legend([["Plan cumplido", "#9B1B4A"], ["Tiempo transcurrido", "#1e293b", "vtb-tick"]]), "avance del plan vs. tiempo transcurrido (desde la 1ª visita)");
    }
    function chEtapa(st) {
        var D = st.D, by = {}, order = [];
        D.plist.forEach(function (p) { if (!p.activo || !okP(st, p.id)) return; if (!(p.etapa in by)) { by[p.etapa] = 0; order.push(p.etapa); } by[p.etapa]++; });
        var cols = { "Lanzamiento": "#D97706", "Plan por cargar": "#7C3AED", "En ejecución": "#9B1B4A" }, tot = 0, acc = 0, parts = [];
        order.forEach(function (k) { tot += by[k]; });
        order.forEach(function (k) { parts.push((cols[k] || "#64748B") + " " + (acc * 100 / tot).toFixed(2) + "% " + ((acc + by[k]) * 100 / tot).toFixed(2) + "%"); acc += by[k]; });
        var body = tot ? '<div class="vtb-donut-wrap"><div class="vtb-donut" style="background:conic-gradient(' + parts.join(",") + ')"><b>' + tot + "</b><small>proyectos</small></div><ul class=\"vtb-dleg\">"
            + order.map(function (k) { return '<li><i style="background:' + (cols[k] || "#64748B") + '"></i>' + esc(k) + " <b>" + by[k] + "</b> <small>(" + Math.round(by[k] * 100 / tot) + "%)</small></li>"; }).join("") + "</ul></div>"
            : '<div class="vtb-empty">Sin proyectos activos.</div>';
        return boxH("Mis proyectos por etapa", "folder", body, "activos");
    }
    function chDevSem(st) {
        var D = st.D, m0 = add(monday(D.hoy), -28), W = 560, Hh = 190, L = 36, B = 24, wk = [];
        for (var i = 0; i < 7; i++) wk.push({ d: add(m0, i * 7), r: 0, p: 0 });
        D.X.forEach(function (x) {
            if (!okP(st, x.proy)) return;
            var d = pd(x.f);
            if (!d) return;
            var i = Math.floor(diff(m0, d) / 7);
            if (i >= 0 && i < 7) { if (x.tipo === "REALIZADO") wk[i].r += x.h; else wk[i].p += x.h; }
        });
        var mx = Math.max(10, Math.max.apply(null, wk.map(function (w) { return w.r + w.p; })));
        mx = Math.ceil(mx / 10) * 10;
        var y = function (v) { return Hh - B - v * (Hh - B - 14) / mx; }, bw = (W - L - 10) / 7;
        var o = grid(L, W, y, [0, mx / 2, mx], " h");
        wk.forEach(function (w, i) {
            var x = L + i * bw + bw * 0.25, ww = bw * 0.5;
            if (w.r) o += '<rect x="' + x.toFixed(1) + '" y="' + y(w.r).toFixed(1) + '" width="' + ww.toFixed(1) + '" height="' + (y(0) - y(w.r)).toFixed(1) + '" rx="4" fill="' + CL.det + '"><title>sem ' + dm(w.d) + ": " + H(w.r) + " h registradas</title></rect>";
            if (w.p) o += '<rect x="' + x.toFixed(1) + '" y="' + y(w.r + w.p).toFixed(1) + '" width="' + ww.toFixed(1) + '" height="' + (y(w.r) - y(w.r + w.p) - (w.r ? 2 : 0)).toFixed(1) + '" rx="4" fill="' + CL.sin + '"><title>sem ' + dm(w.d) + ": " + H(w.p) + " h programadas</title></rect>";
            o += '<text x="' + (x + ww / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + dm(w.d) + "</text>";
        });
        return boxH("Desarrollo por semana", "edit", svg(W, Hh, o, "Desarrollo por semana") + legend([["Desarrollo registrado", CL.det], ["Desarrollo programado", CL.sin]]), "últimas 4 semanas y próximas 3 · por fecha de la visita");
    }

    /* ---------------- personalizar: 3 bloques (cards) en el orden que se quiera ---------------- */
    function panelOrden(st) {
        var d = st.draft;
        var li = d.order.map(function (k, i) {
            var c = CARDS.filter(function (x) { return x.k === k; })[0];
            return '<div class="vtb-pcard' + (d.hidden[k] ? " is-off" : "") + '"><span class="vtb-pcard-n">' + (i + 1) + '</span><span class="vct-360-title-icon">' + ic(c.i) + "</span>"
                 + '<span class="vtb-pcard-t"><b>' + c.t + "</b><small>" + c.d + "</small></span>"
                 + '<button type="button" class="vctdg-btn vtb-ico" data-vtb-mv="' + k + '|-1" title="Subir"' + (i === 0 ? " disabled" : "") + ">" + svgI("chevron-left").replace("<svg ", '<svg style="transform:rotate(90deg)" ') + "</button>"
                 + '<button type="button" class="vctdg-btn vtb-ico" data-vtb-mv="' + k + '|1" title="Bajar"' + (i === d.order.length - 1 ? " disabled" : "") + ">" + svgI("chevron-right").replace("<svg ", '<svg style="transform:rotate(90deg)" ') + "</button>"
                 + '<label class="vtb-sw' + (d.hidden[k] ? "" : " is-on") + '" data-vtb-hide="' + k + '" title="Mostrar / ocultar"><i></i></label></div>';
        }).join("");
        var modo = MODOS.map(function (m) { return '<button type="button" data-vtb-dmodo="' + m[0] + '" class="' + (d.modo === m[0] ? "is-on" : "") + '">' + m[1] + "</button>"; }).join("");
        return '<div class="vtb-po"><div class="vtb-po-h"><b>Personalizar el tablero</b><small>Los indicadores quedan fijos arriba. Ordená las cards con las flechas y mostrá u ocultá cada una.</small></div>'
             + li + '<div class="vtb-day-s">Al abrir</div><div class="vtb-po-r is-w"><span>Para hacer abre en</span><div class="vtb-chips">' + modo + "</div></div>"
             + '<div class="vtb-day-a"><button type="button" class="vctdg-btn" data-vtb-reset>Volver al orden original</button><span class="vtb-sp"></span><button type="button" class="vctdg-btn" data-vtb-pers>Cancelar</button><button type="button" class="vctdg-btn" data-vtb-save>Guardar</button></div>'
             + '<div class="vtb-help">Se guarda en este navegador.</div></div>';
    }
    /* vista previa esquematica (sin datos) de como queda el tablero con el orden elegido */
    function preview(st) {
        var d = st.draft, ln = function (w) { return '<i class="vtb-wf-l" style="width:' + w + '%"></i>'; };
        var kpi = '<div class="vtb-wf-kpi">' + ["Horas del mes", "Desarrollo", "Acciones", "Proyectos y visitas"].map(function (t) { return "<div><b>" + t + "</b>" + ln(70) + ln(45) + "</div>"; }).join("") + "</div>";
        var cards = d.order.map(function (k) {
            var c = CARDS.filter(function (x) { return x.k === k; })[0], off = !!d.hidden[k];
            var head = '<div class="vtb-wf-h"><span class="vct-360-title-icon">' + ic(c.i) + "</span><b>" + c.t + "</b>" + (off ? '<em>oculta</em>' : "")
                     + (k === "hacer" && !off ? '<span class="vtb-wf-sel"><span class="is-on">' + MODOS.filter(function (m) { return m[0] === d.modo; })[0][1] + "</span>"
                        + MODOS.filter(function (m) { return m[0] !== d.modo; }).map(function (m) { return "<span>" + m[1] + "</span>"; }).join("") + "</span>" : "") + "</div>";
            if (off) return '<div class="vtb-wf-card is-off">' + head + "</div>";
            var rows = "";
            for (var i = 0; i < (k === "hacer" ? 5 : 3); i++) rows += '<div class="vtb-wf-r">' + ln(14) + ln(38) + ln(22) + ln(10) + "</div>";
            return '<div class="vtb-wf-card">' + head + (k === "hacer" ? '<div class="vtb-wf-tabs">' + ln(9) + ln(7) + ln(9) + ln(9) + ln(7) + "</div>" : "") + rows + "</div>";
        }).join("");
        return '<div class="vtb-wf"><div class="vtb-wf-cap">Vista previa del tablero (esquema, sin datos)</div><div class="vtb-wf-fix">Indicadores · fijos</div>' + kpi + cards + "</div>";
    }

    /* ---------------- render ---------------- */
    /* carga diferida de un asset de la plataforma si la pagina no lo trajo (mismo criterio que vct-acciones.js) */
    function ensureJs(src, ok, cb) {
        if (ok()) { cb(); return; }
        var base = src.split("?")[0], tag = null;
        Array.prototype.forEach.call(document.querySelectorAll("script[src]"), function (x) { if (x.getAttribute("src").split("?")[0] === base) tag = x; });
        if (!tag) { tag = document.createElement("script"); tag.src = src; document.head.appendChild(tag); }
        var n = 0;
        (function tick() { if (ok()) { cb(); return; } if (n++ < 60) setTimeout(tick, 100); })();
    }
    function ensureCss(href) {
        var base = href.split("?")[0], has = false;
        Array.prototype.forEach.call(document.querySelectorAll('link[rel="stylesheet"]'), function (x) { if ((x.getAttribute("href") || "").split("?")[0] === base) has = true; });
        if (!has) { var l = document.createElement("link"); l.rel = "stylesheet"; l.href = href; document.head.appendChild(l); }
    }
    function initGrids(root) {
        ensureJs("../js/vct-export.js?v=1", function () { return !!window.VCTExport; }, function () { });
        ensureJs("../js/vct-datagrid.js?v=51", function () { return !!(window.VCTDataGrid && window.VCTDataGrid.init); }, function () {
            try { window.VCTDataGrid.init(root); } catch (x) { if (window.console) console.warn("[vct-tablero] grilla", x); }
        });
    }
    function initCal() {
        ensureCss("../css/vct-calendario.css?v=47");
        ensureJs("../js/vct-calendario.js?v=47", function () { return !!window.__vctAgcLoaded; }, function () {
            try { document.dispatchEvent(new Event("vct:content-loaded")); } catch (x) { }
        });
    }
    function render(page) {
        var st = S(page), root = page.querySelector("[data-vtb-root]");
        if (!root) return;
        var html = header(st) + filtros(st) + kpiHoras(st);
        if (st.view === "graf") {
            html += '<div class="vtb-grid2e">' + chHorasDia(st) + chAccDia(st) + "</div><div class=\"vtb-grid2e\">" + chMes(st) + chVenc(st) + "</div>"
                  + '<div class="vtb-grid2e">' + chProy(st) + chPlan(st) + "</div><div class=\"vtb-grid2e\">" + chEtapa(st) + chDevSem(st) + "</div>";
        } else if (st.edit) {
            html += '<div class="vtb-edit-wrap">' + preview(st) + panelOrden(st) + "</div>";
        } else {
            var parts = { hacer: function () { return paraHacer(st); }, proy: function () { return proyectos(st); } };
            st.pr.order.forEach(function (k) { if (!st.pr.hidden[k]) html += parts[k](); });
        }
        closeRm();
        root.innerHTML = html;
        /* combos propios de la plataforma sobre los filtros del tablero (los de las grillas los arma vct-datagrid) */
        if (window.VCT && VCT.Select && typeof VCT.Select.build === "function") root.querySelectorAll(".vtb-flt select.vct-select").forEach(function (x) { VCT.Select.build(x); });
        if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(root);
        /* grillas: se inicializan explicitamente (no depender del observer de vct-datagrid) */
        if (root.querySelector("[data-vct-dg]")) initGrids(root);
        /* calendario unificado: vct-calendario escanea los roots nuevos con este evento */
        if (root.querySelector("[data-vct-agenda-root]")) initCal();
    }

    /* ---------------- menu de fila (mismo look que vct-datagrid: .vctdg-rowmenu) ---------------- */
    var RM = { el: null, btn: null };
    function closeRm() {
        if (RM.el && RM.el.parentNode) RM.el.parentNode.removeChild(RM.el);
        if (RM.btn) RM.btn.classList.remove("is-open");
        RM.el = null; RM.btn = null;
    }
    function openRm(page, btn) {
        closeRm();
        var src = btn.nextElementSibling;
        if (!src) return;
        var its = Array.prototype.slice.call(src.children), m = document.createElement("div");
        m.className = "vctdg-rowmenu";
        m.setAttribute("role", "menu");
        m.innerHTML = its.map(function (i, k) {
            return '<button type="button" class="vctdg-rowmenu-item" role="menuitem" data-k="' + k + '"><span class="vctdg-rowmenu-icon">' + svgI(i.getAttribute("data-i")) + "</span><span>" + esc(i.getAttribute("data-l")) + "</span></button>";
        }).join("");
        m.addEventListener("click", function (e) {
            var it = e.target.closest(".vctdg-rowmenu-item");
            if (!it) return;
            e.preventDefault();
            e.stopPropagation();
            var o = its[+it.getAttribute("data-k")];
            closeRm();
            if (o) goV360(page, o.getAttribute("data-p"), o.getAttribute("data-t") || "");
        });
        document.body.appendChild(m);
        var r = btn.getBoundingClientRect(), mw = m.offsetWidth, mh = m.offsetHeight;
        var top = r.bottom + 4;
        if (top + mh > window.innerHeight - 8 && r.top - mh - 4 > 8) top = r.top - mh - 4;
        m.style.left = Math.max(8, Math.min(r.right - mw, window.innerWidth - mw - 8)) + "px";
        m.style.top = top + "px";
        btn.classList.add("is-open");
        RM.el = m; RM.btn = btn;
    }
    document.addEventListener("click", function (e) { if (RM.el && !RM.el.contains(e.target) && !(e.target.closest && e.target.closest("[data-vtb-rm]"))) closeRm(); });
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") closeRm(); });
    window.addEventListener("resize", closeRm);
    window.addEventListener("scroll", closeRm, true);

    /* ---------------- V360 ---------------- */
    function goV360(page, proy, tab) {
        var VCT = window.VCT, st = S(page), p = P(st.D, proy), guid = page.getAttribute("data-guid");
        if (!proy || !guid || !VCT || !VCT.Buffer || !VCT.Action) return;
        if (tab && VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab(tab);
        Promise.resolve(VCT.Buffer.store("IDSELEC01", p.cli || "")).then(function () { return new Promise(function (r) { setTimeout(r, 250); }); }).then(function () {
            var b = document.createElement("button");
            b.type = "button";
            b.hidden = true;
            b.setAttribute("data-vct-command", "grid-action");
            b.setAttribute("data-vct-store", "IDSELEC02");
            b.setAttribute("data-vct-value", proy);
            b.setAttribute("data-vct-guid", guid);
            page.appendChild(b);
            VCT.Action.execute(b);
        });
    }

    /* ---------------- eventos ---------------- */
    document.addEventListener("click", function (e) {
        var t = e.target, page = t && t.closest ? t.closest("[data-vtb]") : null;
        if (!page) return;
        var st = S(page), el;
        if ((el = t.closest("[data-vtb-rm]"))) { e.preventDefault(); e.stopPropagation(); if (RM.btn === el) closeRm(); else openRm(page, el); return; }
        if ((el = t.closest("[data-vtb-go]"))) { e.preventDefault(); e.stopPropagation(); goV360(page, el.getAttribute("data-vtb-go"), el.getAttribute("data-vtb-gotab") || ""); return; }
        if ((el = t.closest("[data-vtb-view]"))) { st.view = el.getAttribute("data-vtb-view"); st.edit = false; render(page); return; }
        if ((el = t.closest("[data-vtb-pers]"))) {
            st.edit = !st.edit;
            st.draft = st.edit ? JSON.parse(JSON.stringify(st.pr)) : null;
            render(page);
            return;
        }
        if ((el = t.closest("[data-vtb-save]"))) { st.pr = st.draft; savePrefs(page, st.pr); st.edit = false; st.draft = null; render(page); return; }
        if ((el = t.closest("[data-vtb-reset]"))) { st.draft = { order: CARDS.map(function (c) { return c.k; }), hidden: {}, folded: {}, modo: "acc" }; render(page); return; }
        if ((el = t.closest("[data-vtb-mv]"))) {
            if (el.disabled) return;
            var q = el.getAttribute("data-vtb-mv").split("|"), o = st.draft.order, i = o.indexOf(q[0]), j = i + (+q[1]);
            if (i >= 0 && j >= 0 && j < o.length) { o.splice(i, 1); o.splice(j, 0, q[0]); }
            render(page);
            return;
        }
        if ((el = t.closest("[data-vtb-hide]"))) { var hk = el.getAttribute("data-vtb-hide"); st.draft.hidden[hk] = !st.draft.hidden[hk]; render(page); return; }
        if ((el = t.closest("[data-vtb-dmodo]"))) { st.draft.modo = el.getAttribute("data-vtb-dmodo"); render(page); return; }
        if ((el = t.closest("[data-vtb-fold]"))) { e.preventDefault(); var fk = el.getAttribute("data-vtb-fold"); st.pr.folded[fk] = !st.pr.folded[fk]; savePrefs(page, st.pr); render(page); return; }
        if ((el = t.closest("[data-vtb-modo]"))) { st.modo = el.getAttribute("data-vtb-modo"); render(page); return; }
        if ((el = t.closest("[data-vtb-atab]"))) { st.atab = el.getAttribute("data-vtb-atab"); render(page); return; }
        if ((el = t.closest("[data-vtb-aview]"))) { st.aview = el.getAttribute("data-vtb-aview"); render(page); return; }
        if ((el = t.closest("[data-vtb-capa]"))) { var ck = el.getAttribute("data-vtb-capa"); st.capas[ck] = !st.capas[ck]; render(page); return; }
        if ((el = t.closest("[data-vtb-ptab]"))) {
            st.view = "tab"; st.modo = "acc"; st.atab = el.getAttribute("data-vtb-ptab"); st.aview = "lista";
            st.pr.hidden.hacer = false;
            st.pr.folded.hacer = false;
            render(page);
            var b = page.querySelector('[data-vtb-card="hacer"]');
            if (b && b.scrollIntoView) b.scrollIntoView({ behavior: "smooth", block: "start" });
            return;
        }
        if ((el = t.closest("[data-vtb-mes]"))) { var mv = +el.getAttribute("data-vtb-mes"); st.mes = new Date(st.mes.getFullYear(), st.mes.getMonth() + mv, 1); render(page); return; }
        if ((el = t.closest("[data-vtb-pgto]"))) { if (el.disabled) return; var pq = el.getAttribute("data-vtb-pgto").split("|"); st.pgs[pq[0]] = Math.max(0, +pq[1]); render(page); return; }
        if ((el = t.closest("[data-vtb-prk]"))) { st.prk = el.getAttribute("data-vtb-prk"); render(page); return; }
        if ((el = t.closest("tr[data-vtb-exp]"))) { var ek = el.getAttribute("data-vtb-exp"); st.exp[ek] = !st.exp[ek]; render(page); return; }
    });
    document.addEventListener("change", function (e) {
        var t = e.target, page = t && t.closest ? t.closest("[data-vtb]") : null;
        if (!page) return;
        var st = S(page);
        if (t.matches("[data-vtb-c]")) { st.c = t.value; if (st.f && st.c && P(st.D, st.f).cli !== st.c) st.f = ""; st.pgs = {}; setTimeout(function () { render(page); }, 0); }
        if (t.matches("[data-vtb-f]")) { st.f = t.value; st.pgs = {}; setTimeout(function () { render(page); }, 0); }
    });
    var qT = null;
    document.addEventListener("input", function (e) {
        var t = e.target, page = t && t.closest ? t.closest("[data-vtb]") : null;
        if (!page || !t.matches("[data-vtb-q]")) return;
        clearTimeout(qT);
        qT = setTimeout(function () {
            var st = S(page), pos = t.selectionStart;
            st.q = String(t.value || "").trim().toLowerCase();
            st.pgs = {};
            render(page);
            var n = page.querySelector("[data-vtb-q]");
            if (n) { n.focus(); try { n.setSelectionRange(pos, pos); } catch (x) { } }
        }, 250);
    });

    function init() { document.querySelectorAll("[data-vtb]").forEach(function (p) { if (!p.__vtbInit) { p.__vtbInit = true; render(p); } }); }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
    new MutationObserver(function () { init(); }).observe(document.documentElement, { childList: true, subtree: true });
})(window, document);
