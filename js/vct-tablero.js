/* vct-tablero.js - v1 DASH_TAB_V1 (Inicio del consultor: Tablero de control)
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
        { k: "hacer", t: "Para hacer · Próximas visitas · Horas sin detallar" },
        { k: "proy", t: "Mis proyectos" },
        { k: "cal", t: "Calendario" }
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
        "eye": '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>'
    };
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
                      asig: num(r[14]), dev: num(r[15]), h12: num(r[16]) };
            D.P[p.id] = p;
            D.plist.push(p);
        });
        D.plist.sort(function (a, b) { return (a.cliente || a.nom).localeCompare(b.cliente || b.nom); });
        D.plist.forEach(function (p, i) { p.col = PAL[i % PAL.length]; p.short = (p.cliente || p.nom).split(" ")[0]; });
        /* acciones: id, proy, item, titulo, vence, estado, est cod, final, cierre, prioridad, nivel, plan, n dev, h dev R, h dev P */
        D.A = rows(page, "acc").map(function (r) {
            return { id: r[0], proy: r[1], item: deco(r[2]), tit: deco(r[3]), vence: pd(r[4]), est: deco(r[5]), estc: r[6], fin: r[7] === "1", cierre: pd(r[8]),
                     prio: deco(r[9]), pniv: num(r[10]), plan: r[11] === "1", dn: num(r[12]), dr: num(r[13]), dp: num(r[14]) };
        });
        /* visitas: id, proy, desde, hasta, estado, h plan, h ejec, dev R, dev P, sin registrar, dias */
        D.V = rows(page, "vis").map(function (r) {
            var v = { id: r[0], proy: r[1], desde: pd(r[2]), hasta: pd(r[3]) || pd(r[2]), est: r[4], hp: num(r[5]), he: num(r[6]), dr: num(r[7]), dp: num(r[8]), sinreg: r[9] === "1", dd: {} };
            if (r[10]) r[10].split("|").forEach(function (x) { var q = x.split("="); if (q.length === 2) v.dd[q[0]] = num(q[1]); });
            else {
                var n = diff(v.desde, v.hasta) + 1, h = n > 0 ? v.hp / n : v.hp;
                for (var i = 0; i < Math.max(n, 1); i++) v.dd[iso(add(v.desde, i))] = h;
            }
            return v;
        });
        /* agenda por dia: fecha, estado, horas, tipo, feriado, habil */
        D.G = {};
        rows(page, "dia").forEach(function (r) { D.G[r[0]] = { est: r[1], h: num(r[2]), tipo: r[3], fer: r[4] === "1", hab: r[5] === "1" }; });
        /* desarrollo: fecha visita, tipo, horas, proy, item, titulo, accion */
        D.X = rows(page, "dev").map(function (r) { return { f: r[0], tipo: r[1], h: num(r[2]), proy: r[3], item: deco(r[4]), tit: deco(r[5]), acc: r[6] }; });
        /* meses: etiqueta, ejecutadas, programadas, capacidad */
        D.M = rows(page, "mes").map(function (r) { return { l: deco(r[0]), e: num(r[1]), p: num(r[2]), c: num(r[3]) }; });
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
        p.folded = p.folded || {};
        p.cal = p.cal || "semana";
        return p;
    }
    function savePrefs(page, p) { try { window.localStorage.setItem(pkey(page), JSON.stringify(p)); } catch (e) { } }

    /* ---------------- estado ---------------- */
    function S(page) {
        if (!page.__vtb) {
            var D = load(page), pr = prefs(page);
            page.__vtb = { D: D, pr: pr, view: "tab", edit: false, f: "", q: "", tab: "venc", pg: 0, cal: pr.cal, cd: D.hoy, prk: "mes", exp: {}, draft: null };
        }
        return page.__vtb;
    }
    function okP(st, id) { return !st.f || st.f === String(id); }
    function okQ(st, s) { return !st.q || deco(s).toLowerCase().indexOf(st.q) >= 0; }

    /* ---------------- encabezado e indicadores ---------------- */
    function stat(tone, lbl, val, sub, icon) {
        return '<div class="vct-360-stat" data-vct-tone="' + tone + '"><span><span class="vct-360-stat-label">' + lbl + "</span><b>" + val + "</b><small>" + sub + "</small></span>"
             + '<span class="vct-360-stat-icon">' + ic(icon) + "</span></div>";
    }
    function header(st) {
        var D = st.D;
        var opts = '<option value="">Todos (' + D.plist.filter(function (p) { return p.activo; }).length + ")</option>" + D.plist.map(function (p) {
            return '<option value="' + esc(p.id) + '"' + (st.f === p.id ? " selected" : "") + ">" + esc((p.cliente || p.nom) + (p.cod ? " (" + p.cod + ")" : "")) + "</option>";
        }).join("");
        var seg = '<div class="vtb-seg"><button type="button" data-vtb-view="tab" class="' + (st.view === "tab" ? "is-on" : "") + '">' + ic("list-checks") + "Tablero</button>"
                + '<button type="button" data-vtb-view="graf" class="' + (st.view === "graf" ? "is-on" : "") + '">' + ic("chart-bar") + "Gráficos</button></div>";
        var pers = st.view === "tab" ? '<button type="button" class="vtb-btn' + (st.edit ? " is-p" : "") + '" data-vtb-pers>' + ic("settings") + "Personalizar</button>" : "";
        return '<div class="vtb-filters"><div class="vtb-period"><b>' + esc(D.mes) + '</b></div>'
             + '<label class="vtb-sel">Proyecto <select data-vtb-f>' + opts + "</select></label>"
             + '<div class="vtb-search">' + ic("search") + '<input type="text" data-vtb-q placeholder="Buscar acción, ítem, cliente…" value="' + esc(st.q) + '"></div>'
             + '<span class="vtb-sp"></span>' + seg + pers + "</div>";
    }
    function kpiHoras(st) {
        var k = st.D.k, cap = num(k.cap), ej = num(k.eje), pr = num(k.pro), lic = num(k.lic), nc = num(k.nc), asi = ej + pr, lib = Math.max(cap - asi, 0);
        var dr = num(k.devr), dp = num(k.devp), sd = num(k.sind);
        var pc = cap > 0 ? Math.round(asi * 100 / cap) : 0;
        var tiles = stat("violet", "Capacidad del mes", H(cap) + " h", num(k.dd) + " días disponibles × 8 h", "calendar-days")
            + stat("blue", "Asignadas en visitas", H(asi) + " h", (cap > 0 ? pc + "% de la capacidad · " : "") + H(lib) + " h libres", "briefcase")
            + stat("mint", "Ejecutadas", H(ej) + " h", "visitas hasta hoy · " + num(k.vhec) + " visita(s)", "clock-3")
            + stat("blue", "Programadas", H(pr) + " h", "visitas desde mañana · " + (num(k.vmes) - num(k.vhec)) + " visita(s)", "calendar")
            + stat("mint", "Desarrollo registrado", H(dr) + " h", (ej > 0 ? Math.round(dr * 100 / ej) + "% de lo ejecutado · " : "") + (sd > 0 ? '<span class="vtb-warn">' + H(sd) + " h sin detallar</span>" : "todo detallado"), "list-checks")
            + stat("violet", "Desarrollo programado", H(dp) + " h", "para las próximas visitas" + (pr > 0 ? " (de " + H(pr) + " h)" : ""), "edit");
        var seg = [["Ejecutadas", ej, "#9B1B4A", "c"], ["Programadas", pr, "#2563EB", "c"], ["Libres", lib, "#E2E8F0", "c"], ["Licencia", lic, "", "h"], ["Sin cargar", nc, "", "n"]];
        var tot = seg.reduce(function (a, s) { return a + s[1]; }, 0) || 1;
        var bar = seg.filter(function (s) { return s[1] > 0; }).map(function (s) {
            return '<span class="vtb-seg-' + s[3] + '" style="flex:' + s[1] + ";" + (s[2] ? "background:" + s[2] : "") + '" title="' + s[0] + ": " + H(s[1]) + ' h"></span>';
        }).join("") || '<span class="vtb-seg-n" style="flex:1"></span>';
        var leg = seg.map(function (s) { return '<span class="vtb-lgi"><i class="vtb-sw-' + s[3] + '" style="' + (s[2] ? "background:" + s[2] : "") + '"></i>' + s[0] + " <b>" + H(s[1]) + " h</b></span>"; }).join("");
        var det = ej > 0 ? '<div class="vtb-cap-t" style="margin-top:12px"><b>Lo ejecutado, ¿está detallado?</b><span>desarrollo cargado sobre las horas de visitas ya hechas</span></div>'
            + '<div class="vtb-cap-bar"><span class="vtb-seg-c" style="flex:' + Math.min(dr, ej) + ';background:#0F9F8F" title="Detallado: ' + H(Math.min(dr, ej)) + ' h"></span><span class="vtb-seg-c" style="flex:' + sd + ';background:#FDE68A" title="Sin detallar: ' + H(sd) + ' h"></span></div>'
            + '<div class="vtb-cap-leg"><span class="vtb-lgi"><i class="vtb-sw-c" style="background:#0F9F8F"></i>Detallado <b>' + H(Math.min(dr, ej)) + ' h</b></span><span class="vtb-lgi"><i class="vtb-sw-c" style="background:#FDE68A"></i>Sin detallar <b>' + H(sd) + " h</b> · " + num(k.sindn) + " visita(s)</span></div>" : "";
        return '<div class="vct-360-stats-row vtb-stats6">' + tiles + "</div>"
             + '<div class="vtb-cap"><div class="vtb-cap-t"><b>Uso del mes</b><span>' + H(num(k.hab) * 8) + " h hábiles (" + num(k.hab) + " días × 8) · " + H(cap) + " h disponibles en la agenda</span></div>"
             + '<div class="vtb-cap-bar">' + bar + '</div><div class="vtb-cap-leg">' + leg + "</div>" + det + "</div>";
    }
    function kpiMini(st) {
        var k = st.D.k, cm = num(k.cmes), ca = num(k.cant), dif = cm - ca;
        var t = [["violet", "Mis proyectos", num(k.np), num(k.npc) + " en curso · " + num(k.npl) + " en lanzamiento", "folder", ""],
                 ["blue", "Visitas del mes", num(k.vmes), num(k.vhec) + " hechas · próxima " + (k.vprox || "sin agendar"), "calendar", ""],
                 ["red", "Vencidas", num(k.aven), "en " + num(k.avenp) + " proyecto(s)", "bell", "venc"],
                 ["amber", "Vencen hoy", num(k.ahoy), dlab(st.D.hoy), "clock-3", "hoy"],
                 ["amber", "Próximos 7 días", num(k.asem), "hasta " + dlab(add(st.D.hoy, 7)), "calendar-days", "sem"],
                 ["blue", "Abiertas", num(k.aabi), num(k.acur) + " en proceso · " + num(k.asfe) + " sin fecha", "list-checks", "abi"],
                 ["violet", "Sin desarrollo", num(k.asdv), "del plan, sin registro", "edit", "sdev"],
                 ["mint", "Cumplidas en el mes", cm, (dif >= 0 ? "+" : "") + dif + " vs. mes anterior", "check", ""]];
        return '<div class="vtb-mini vtb-mini8">' + t.map(function (x) {
            return '<div class="vtb-mini-t" data-tone="' + x[0] + '"' + (x[5] ? ' data-vtb-ptab="' + x[5] + '" role="button" title="Ver en Para hacer"' : "") + ">" + ic(x[4]) + "<span><small>" + x[1] + "</small><b>" + x[2] + "</b><em>" + esc(x[3]) + "</em></span></div>";
        }).join("") + "</div>";
    }

    /* ---------------- card 1: para hacer ---------------- */
    var TABS = [["venc", "Vencidas"], ["hoy", "Hoy"], ["sem", "Esta semana"], ["abi", "Todas abiertas"], ["sdev", "Sin desarrollo"], ["sreg", "Visitas sin registrar"]];
    function accIn(st, a, tab) {
        var h = st.D.hoy, v = a.vence;
        if (a.fin) return false;
        if (tab === "venc") return v && v < h;
        if (tab === "hoy") return v && diff(h, v) === 0;
        if (tab === "sem") return v && v > h && diff(h, v) <= 7;
        if (tab === "sdev") return a.plan && a.dn === 0;
        return true;
    }
    function boxH(title, icon, body, sub, tools) {
        return '<div class="vct-360-box vtb-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon">' + ic(icon) + "</span>" + title + "</h3>"
             + (sub ? '<div class="vct-360-box-subtitle">' + sub + "</div>" : "") + "</div>" + (tools ? '<div class="vtb-tools">' + tools + "</div>" : "") + "</div>" + body + "</div>";
    }
    function bandeja(st) {
        var D = st.D;
        var A = D.A.filter(function (a) { return okP(st, a.proy) && (okQ(st, a.tit) || okQ(st, a.item) || okQ(st, P(D, a.proy).cliente)); });
        var VS = D.V.filter(function (v) { return v.sinreg && okP(st, v.proy) && okQ(st, P(D, v.proy).cliente + " " + P(D, v.proy).nom); });
        var cnt = {};
        TABS.forEach(function (t) { cnt[t[0]] = t[0] === "sreg" ? VS.length : A.filter(function (a) { return accIn(st, a, t[0]); }).length; });
        var tabs = TABS.map(function (t) {
            return '<button type="button" data-vtb-tab="' + t[0] + '" class="' + (st.tab === t[0] ? "is-on" : "") + '">' + t[1] + ' <span class="vct-tab-count' + ((t[0] === "venc" || t[0] === "sreg") && cnt[t[0]] ? " is-alert" : "") + '">' + cnt[t[0]] + "</span></button>";
        }).join("");
        var body, total;
        if (st.tab === "sreg") {
            VS.sort(function (a, b) { return b.desde - a.desde; });
            total = VS.length;
            body = '<table class="vtb-tbl"><thead><tr><th>Visita</th><th>Proyecto</th><th>Horas</th><th>Desarrollo</th><th></th></tr></thead><tbody>'
                 + VS.slice(st.pg * 10, st.pg * 10 + 10).map(function (v) {
                     return "<tr><td><b>" + dlab(v.desde) + "</b></td><td>" + ptag(D, v.proy, true) + "</td><td>" + H(v.he) + " h</td><td>" + (v.dr ? H(v.dr) + " h registradas" : '<span class="vtb-muted">&mdash;</span>') + "</td>"
                          + '<td class="vtb-qa"><button type="button" title="Registrar en la V360 (Visitas)" data-vtb-go="' + v.proy + '" data-vtb-gotab="agenda">' + ic("arrow-right") + "</button></td></tr>";
                 }).join("") + "</tbody></table>";
        } else {
            var L = A.filter(function (a) { return accIn(st, a, st.tab); });
            L.sort(function (a, b) {
                var av = a.vence ? a.vence.getTime() : 9e15, bv = b.vence ? b.vence.getTime() : 9e15;
                return av - bv || b.pniv - a.pniv;
            });
            total = L.length;
            body = '<table class="vtb-tbl"><thead><tr><th>Proyecto</th><th>&Iacute;tem</th><th>Acci&oacute;n</th><th>Vence</th><th>Estado</th><th>Prioridad</th><th>Desarrollo</th><th></th></tr></thead><tbody>'
                 + (L.length ? L.slice(st.pg * 10, st.pg * 10 + 10).map(function (a) {
                     var v = a.vence, h = D.hoy, cls = !v ? "s" : v < h ? "v" : diff(h, v) === 0 ? "h" : "s";
                     var vt = !v ? "sin fecha" : v < h ? "vencida " + dm(v) : diff(h, v) === 0 ? "hoy" : dlab(v);
                     var dev = a.dn ? a.dn + " reg." + (a.dr ? " · " + H(a.dr) + " h" : "") + (a.dp ? " · planif. " + H(a.dp) + " h" : "") : '<span class="vtb-muted">&mdash;</span>';
                     var pk = a.pniv >= 3 ? "p" : a.pniv === 2 ? "o" : "n";
                     return "<tr><td>" + ptag(D, a.proy) + '</td><td><span class="vtb-item">' + esc(a.item || (a.plan ? "" : "Proyecto")) + '</span></td><td class="vtb-acc">' + esc(a.tit) + "</td>"
                          + '<td><span class="vtb-due is-' + cls + '">' + vt + "</span></td><td>" + pill(a.est, a.estc === "EN_PROCESO" ? "d" : a.estc === "EN_ESPERA" ? "o" : "n") + "</td><td>" + (a.prio ? pill(a.prio, pk) : "") + '</td><td class="vtb-dev">' + dev + "</td>"
                          + '<td class="vtb-qa">' + (a.plan ? '<button type="button" title="Cargar desarrollo (en la V360, plan)" data-vtb-go="' + a.proy + '" data-vtb-gotab="plan">' + ic("edit") + "</button>" : "")
                          + '<button type="button" title="Abrir en la V360" data-vtb-go="' + a.proy + '" data-vtb-gotab="' + (a.plan ? "plan" : "acciones") + '">' + ic("arrow-right") + "</button></td></tr>";
                 }).join("") : '<tr><td colspan="8" class="vtb-empty">Nada en esta pestaña.</td></tr>') + "</tbody></table>";
        }
        var pages = Math.max(1, Math.ceil(total / 10));
        if (st.pg >= pages) st.pg = pages - 1;
        var foot = '<div class="vtb-foot"><span>' + (total ? "Mostrando " + (st.pg * 10 + 1) + " a " + Math.min(total, st.pg * 10 + 10) + " de " + total : "Sin registros") + "</span>"
                 + '<span class="vtb-pg"><button type="button" data-vtb-pg="-1"' + (st.pg <= 0 ? " disabled" : "") + ">" + ic("chevron-left") + "</button>" + (st.pg + 1) + " / " + pages
                 + '<button type="button" data-vtb-pg="1"' + (st.pg >= pages - 1 ? " disabled" : "") + ">" + ic("chevron-right") + "</button></span></div>";
        return boxH("Para hacer", "clipboard-check", '<div class="vtb-tabs">' + tabs + "</div>" + body + foot, "acciones a mi cargo, de todos mis proyectos");
    }
    function proximas(st) {
        var D = st.D, h = D.hoy;
        var L = D.V.filter(function (v) { return okP(st, v.proy) && v.desde > h && diff(h, v.desde) <= 7; }).sort(function (a, b) { return a.desde - b.desde; });
        var tot = L.reduce(function (a, v) { return a + v.hp; }, 0);
        var li = L.length ? L.map(function (v) {
            return '<div class="vtb-vrow"><div class="vtb-vd">' + dlab(v.desde) + '</div><div class="vtb-vm">' + ptag(D, v.proy, true) + "<small>" + H(v.hp) + " h · desarrollo: " + (v.dp ? H(v.dp) + " h planificado" : "&mdash;") + "</small></div>"
                 + pill(v.est === "CONFIRMADO" ? "Confirmada" : "Pendiente", v.est === "CONFIRMADO" ? "a" : "n") + "</div>";
        }).join("") : '<div class="vtb-empty">Sin visitas en los próximos 7 días.</div>';
        var S2 = D.V.filter(function (v) { return okP(st, v.proy) && v.desde <= h && v.he - v.dr > 0.05; }).sort(function (a, b) { return b.desde - a.desde; });
        var sd = S2.reduce(function (a, v) { return a + (v.he - v.dr); }, 0);
        var li2 = S2.length ? S2.slice(0, 6).map(function (v) {
            return '<div class="vtb-vrow"><div class="vtb-vd">' + dlab(v.desde) + '</div><div class="vtb-vm">' + ptag(D, v.proy, true) + "<small>visita " + H(v.he) + ' h · sin detallar <b class="vtb-warn">' + H(v.he - v.dr) + " h</b></small></div>"
                 + '<button type="button" class="vtb-btn is-p" data-vtb-go="' + v.proy + '" data-vtb-gotab="plan">Detallar</button></div>';
        }).join("") + (S2.length > 6 ? '<div class="vtb-more">y ' + (S2.length - 6) + " visita(s) más</div>" : "") : '<div class="vtb-empty">Todo lo ejecutado tiene desarrollo cargado.</div>';
        return boxH("Próximas visitas", "calendar", li, "próximos 7 días · " + H(tot) + " h")
             + boxH("Horas sin detallar", "clock-3", li2, H(sd) + " h de visitas ya hechas sin desarrollo cargado (últimas 6 semanas)");
    }

    /* ---------------- card 2: mis proyectos ---------------- */
    function proyectos(st) {
        var D = st.D, h = D.hoy;
        var L = D.plist.filter(function (p) { return p.activo && okP(st, p.id) && (okQ(st, p.nom) || okQ(st, p.cliente) || okQ(st, p.cod)); });
        L.forEach(function (p) {
            var mine = D.A.filter(function (a) { return a.proy === p.id && !a.fin; });
            p._ven = mine.filter(function (a) { return a.vence && a.vence < h; }).length;
            p._abi = mine.length;
            p._sd = D.V.filter(function (v) { return v.proy === p.id && v.desde <= h; }).reduce(function (a, v) { return a + Math.max(v.he - v.dr, 0); }, 0);
            var nx = D.V.filter(function (v) { return v.proy === p.id && v.desde > h; }).sort(function (a, b) { return a.desde - b.desde; })[0];
            p._prox = nx ? dlab(nx.desde) : "";
            var d = p.tiempo == null ? 0 : p.plan - p.tiempo;
            p._st = d <= -15 || p._ven >= 3 ? "bad" : (d < 0 || p._ven) ? "warn" : "ok";
        });
        var ord = { bad: 0, warn: 1, ok: 2 };
        L.sort(function (a, b) { return ord[a._st] - ord[b._st] || ((a.plan - (a.tiempo || 0)) - (b.plan - (b.tiempo || 0))); });
        var r = L.map(function (p) {
            var t = p.tiempo == null ? null : Math.max(0, Math.min(100, p.tiempo));
            var row = '<tr data-vtb-exp="' + p.id + '" class="vtb-rowx"><td><b class="vtb-st is-' + p._st + '" title="' + { bad: "Atrasado", warn: "Atención", ok: "En tiempo" }[p._st] + '">&#9679;</b></td>'
                + "<td>" + ptag(D, p.id, true) + '<small class="vtb-sm">' + esc((p.cod ? "(" + p.cod + ") " : "") + (p.srv || p.nom)) + "</small></td>"
                + '<td><div class="vtb-bul-b is-sm"><span class="vtb-bul-p" style="width:' + Math.min(100, p.plan) + '%"></span>' + (t != null ? '<i style="left:' + t + '%"></i>' : "") + "</div>"
                + '<small class="vtb-sm">' + p.plan + "% plan" + (t != null ? " · " + Math.round(t) + "% tiempo" : "") + "</small></td>"
                + "<td><b>" + H(p.hej) + "</b>" + (p.hpr ? " / " + H(p.hpr) + " h" : " h") + '<small class="vtb-sm">' + (p.hpr ? Math.round(p.hej * 100 / p.hpr) + "% horas" : "") + "</small></td>"
                + "<td>" + (p._ven ? pill(p._ven + " vencida" + (p._ven > 1 ? "s" : ""), "l") : '<span class="vtb-muted">0</span>') + "</td><td>" + p._abi + "</td>"
                + "<td>" + (p._sd > 0.05 ? '<b class="vtb-warn">' + H(p._sd) + " h</b>" : '<span class="vtb-muted">&mdash;</span>') + "</td><td>" + (p._prox || '<span class="vtb-muted">&mdash;</span>') + "</td>"
                + '<td class="vtb-qa"><button type="button" title="Plan (V360)" data-vtb-go="' + p.id + '" data-vtb-gotab="plan">' + ic("list-checks") + '</button><button type="button" title="Visitas (V360)" data-vtb-go="' + p.id + '" data-vtb-gotab="agenda">' + ic("calendar") + '</button><button type="button" title="Abrir V360" data-vtb-go="' + p.id + '">' + ic("arrow-right") + "</button></td></tr>";
            if (st.exp[p.id]) {
                var acc = D.A.filter(function (a) { return a.proy === p.id && !a.fin; }).sort(function (a, b) { return (a.vence ? a.vence.getTime() : 9e15) - (b.vence ? b.vence.getTime() : 9e15); }).slice(0, 4);
                var vis = D.V.filter(function (v) { return v.proy === p.id && v.desde > h; }).sort(function (a, b) { return a.desde - b.desde; }).slice(0, 3);
                row += '<tr class="vtb-exp"><td></td><td colspan="8"><div class="vtb-exp-in"><div><div class="vtb-day-s">Próximas acciones</div>'
                    + (acc.length ? acc.map(function (a) {
                        var v = a.vence;
                        return '<div class="vtb-li"><span class="vtb-due is-' + (!v ? "s" : v < h ? "v" : diff(h, v) === 0 ? "h" : "s") + '">' + (!v ? "sin fecha" : v < h ? "vencida " + dm(v) : diff(h, v) === 0 ? "hoy" : dlab(v)) + "</span> " + esc((a.item ? a.item + " " : "") + a.tit) + "</div>";
                    }).join("") : '<div class="vtb-li vtb-muted">Sin acciones abiertas a mi cargo.</div>')
                    + '</div><div><div class="vtb-day-s">Visitas</div>' + (vis.length ? vis.map(function (v) { return '<div class="vtb-li">' + dlab(v.desde) + " · " + H(v.hp) + " h" + (v.dp ? " · " + H(v.dp) + " h de desarrollo planificado" : "") + "</div>"; }).join("") : '<div class="vtb-li vtb-muted">Sin visitas agendadas.</div>')
                    + '<div class="vtb-day-s">Tiempo</div><div class="vtb-li">' + (p.fin != null ? (p.fin >= 0 ? p.fin + " días para el fin" : "venció hace " + (-p.fin) + " días") : "sin fecha de fin") + " · etapa: " + esc(p.etapa) + "</div></div></div></td></tr>";
            }
            return row;
        }).join("");
        var body = '<table class="vtb-tbl"><thead><tr><th></th><th>Proyecto</th><th>Plan vs. tiempo</th><th>Horas</th><th>Vencidas</th><th>Abiertas</th><th>Sin detallar</th><th>Próx. visita</th><th></th></tr></thead><tbody>'
                 + (r || '<tr><td colspan="9" class="vtb-empty">Sin proyectos activos.</td></tr>') + "</tbody></table>";
        return boxH("Mis proyectos", "folder", body, "activos · primero los atrasados · tocá una fila para desplegar");
    }

    /* ---------------- card 3: calendario ---------------- */
    function dayInfo(st, d) {
        var D = st.D, k = iso(d), g = D.G[k];
        var vis = [], acc = [], dev = [];
        D.V.forEach(function (v) { if (okP(st, v.proy) && v.dd[k] > 0) vis.push({ v: v, h: v.dd[k] }); });
        D.A.forEach(function (a) { if (!a.fin && a.vence && iso(a.vence) === k && okP(st, a.proy)) acc.push(a); });
        D.X.forEach(function (x) { if (x.f === k && okP(st, x.proy)) dev.push(x); });
        var r = dev.filter(function (x) { return x.tipo === "REALIZADO"; }).reduce(function (a, x) { return a + x.h; }, 0);
        var p = dev.filter(function (x) { return x.tipo !== "REALIZADO"; }).reduce(function (a, x) { return a + x.h; }, 0);
        return { k: k, g: g, vis: vis, acc: acc, dev: dev, r: r, p: p };
    }
    function agTag(g) {
        if (!g) return '<span class="vtb-muted">&mdash;</span>';
        if (g.fer) return pill("Feriado", "f");
        var t = g.tipo || "";
        if (t === "DISPONIBLE") return pill("D " + H(g.est === "ASIGNADO" ? 8 : g.h) + " h", "d");
        if (t === "LICENCIA") return pill("Lic", "l");
        if (t === "POTENCIAL") return pill("Pot", "p");
        if (t === "NO_DISPONIBLE" || t === "OCUPADO") return pill(t === "OCUPADO" ? "Oc" : "ND", "o");
        if (t === "ORGANISMO") return pill("Org", "g");
        if (t) return pill(t.charAt(0) + t.slice(1).toLowerCase(), "n");
        return '<span class="vtb-muted">&mdash;</span>';
    }
    function vb(st, x, small) {
        var p = P(st.D, x.v.proy), h = st.D.hoy, d = x.v.desde;
        return '<div class="vtb-vb' + (small ? " is-s" : "") + '" style="--c:' + p.col + '" title="' + esc((p.cliente || p.nom) + " · " + H(x.h) + " h") + '"><b>' + esc(p.short) + "</b><small>" + H(x.h) + " h" + (small ? "" : " · " + (x.v.hasta < h ? "ejecutada" : (d <= h && x.v.hasta >= h) ? "en curso" : x.v.est === "CONFIRMADO" ? "confirmada" : "pendiente")) + "</small></div>";
    }
    function accChips(st, list, small) {
        var by = {};
        list.forEach(function (a) { by[a.proy] = (by[a.proy] || 0) + 1; });
        var h = st.D.hoy;
        return Object.keys(by).map(function (k) {
            var p = P(st.D, k), past = list[0].vence < h;
            return '<span class="vtb-ab' + (small ? " is-s" : "") + '" style="--c:' + (past ? "#B42318" : p.col) + '" title="' + esc(p.cliente || p.nom) + '">' + by[k] + " " + (past ? "vencida" + (by[k] > 1 ? "s" : "") : "vence" + (by[k] > 1 ? "n" : "")) + "</span>";
        }).join("");
    }
    function devChips(i) { return (i.r ? '<span class="vtb-db is-r">R ' + H(i.r) + " h</span>" : "") + (i.p ? '<span class="vtb-db is-p">P ' + H(i.p) + " h</span>" : ""); }
    function inWin(st, d) { return (!st.D.fecha0 || d >= st.D.fecha0) && (!st.D.fecha1 || d <= st.D.fecha1); }
    function calendario(st) {
        var D = st.D, cd = st.cd, h = D.hoy, body = "", title = "";
        var views = [["dia", "Día"], ["semana", "Semana"], ["mes", "Mes"], ["lista", "Lista"]];
        var tools = '<div class="vtb-chips">' + views.map(function (v) { return '<button type="button" data-vtb-cal="' + v[0] + '" class="' + (st.cal === v[0] ? "is-on" : "") + '">' + v[1] + "</button>"; }).join("") + "</div>";
        var nav = function (lbl) {
            return '<div class="vtb-calnav"><button type="button" data-vtb-cnav="-1">' + ic("chevron-left") + '</button><b>' + lbl + '</b><button type="button" data-vtb-cnav="1">' + ic("chevron-right") + '</button><button type="button" class="vtb-btn" data-vtb-cnav="0">Hoy</button></div>';
        };
        if (st.cal === "semana") {
            var m = monday(cd), days = [];
            for (var i = 0; i < 7; i++) days.push(add(m, i));
            title = "Semana del " + dm(days[0]) + " al " + dm(days[6]);
            var I = days.map(function (d) { return dayInfo(st, d); });
            var hd = '<div class="vtb-cw-h"></div>' + days.map(function (d) { return '<div class="vtb-cw-h' + (iso(d) === iso(h) ? " is-today" : "") + '" data-vtb-day="' + iso(d) + '">' + DN[d.getDay()] + " " + d.getDate() + "</div>"; }).join("");
            var lane = function (lab, f) {
                return '<div class="vtb-cw-l">' + lab + "</div>" + days.map(function (d, j) {
                    var we = d.getDay() === 0 || d.getDay() === 6;
                    return '<div class="vtb-cw-c' + (iso(d) === iso(h) ? " is-today" : we ? " is-we" : "") + '" data-vtb-day="' + iso(d) + '">' + f(I[j], d) + "</div>";
                }).join("");
            };
            body = '<div class="vtb-cw">' + hd
                + lane("Agenda", function (x) { return agTag(x.g); })
                + lane("Visitas", function (x) { return x.vis.map(function (y) { return vb(st, y, false); }).join(""); })
                + lane("Vencimientos", function (x) { return x.acc.length ? accChips(st, x.acc, false) : ""; })
                + lane("Desarrollo", function (x) { return devChips(x); }) + "</div>";
        } else if (st.cal === "mes") {
            var f0 = new Date(cd.getFullYear(), cd.getMonth(), 1), f1 = new Date(cd.getFullYear(), cd.getMonth() + 1, 0);
            title = MN[cd.getMonth()] + " " + cd.getFullYear();
            var cells = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"].map(function (x) { return '<div class="vtb-cm-h">' + x + "</div>"; }).join("");
            var lead = (f0.getDay() + 6) % 7;
            for (var j = 0; j < lead; j++) cells += '<div class="vtb-cm-c is-out"></div>';
            for (var d = 1; d <= f1.getDate(); d++) {
                var dd = new Date(cd.getFullYear(), cd.getMonth(), d), x = dayInfo(st, dd), we = dd.getDay() === 0 || dd.getDay() === 6;
                var c = '<div class="vtb-cm-d">' + d + "</div>";
                if (x.g && x.g.tipo === "LICENCIA") c += pill("Lic", "l");
                if (x.g && x.g.fer) c += pill("Fer", "f");
                c += x.vis.slice(0, 2).map(function (y) { return vb(st, y, true); }).join("") + (x.vis.length > 2 ? '<span class="vtb-muted">+' + (x.vis.length - 2) + "</span>" : "");
                if (x.acc.length) c += '<span class="vtb-ab is-s" style="--c:' + (dd < h ? "#B42318" : "#D97706") + '">' + x.acc.length + (dd < h ? " venc." : " vence" + (x.acc.length > 1 ? "n" : "")) + "</span>";
                c += devChips(x);
                cells += '<div class="vtb-cm-c' + (we ? " is-we" : "") + (iso(dd) === iso(h) ? " is-today" : "") + (iso(dd) === iso(cd) ? " is-sel" : "") + (inWin(st, dd) ? "" : " is-nodata") + '" data-vtb-day="' + iso(dd) + '">' + c + "</div>";
            }
            body = '<div class="vtb-cm-wrap"><div class="vtb-cm">' + cells + "</div>" + dayPanel(st, cd) + "</div>";
        } else if (st.cal === "dia") {
            title = DN[cd.getDay()] + " " + dm(cd) + "/" + cd.getFullYear();
            body = dayPanel(st, cd, true);
        } else {
            title = "Del " + dm(cd) + " al " + dm(add(cd, 13));
            var tr = "";
            for (var n = 0; n < 14; n++) {
                var di = add(cd, n), y = dayInfo(st, di);
                y.vis.forEach(function (z) { tr += "<tr><td><b>" + dlab(di) + "</b></td><td>" + pill("Visita", "d") + "</td><td>" + ptag(D, z.v.proy, true) + "</td><td>" + H(z.h) + " h · " + (z.v.est === "CONFIRMADO" ? "confirmada" : "pendiente") + '</td><td class="vtb-qa"><button type="button" data-vtb-go="' + z.v.proy + '" data-vtb-gotab="agenda">' + ic("arrow-right") + "</button></td></tr>"; });
                y.dev.forEach(function (z) { tr += "<tr><td><b>" + dlab(di) + "</b></td><td>" + pill(z.tipo === "REALIZADO" ? "Desarrollo realizado" : "Desarrollo planificado", z.tipo === "REALIZADO" ? "a" : "p") + "</td><td>" + ptag(D, z.proy, true) + "</td><td>" + esc((z.item ? z.item + " " : "") + z.tit) + " · " + H(z.h) + ' h</td><td class="vtb-qa"><button type="button" data-vtb-go="' + z.proy + '" data-vtb-gotab="plan">' + ic("arrow-right") + "</button></td></tr>"; });
                y.acc.forEach(function (z) { tr += "<tr><td><b>" + dlab(di) + "</b></td><td>" + pill("Vence", "o") + "</td><td>" + ptag(D, z.proy, true) + "</td><td>" + esc((z.item ? z.item + " " : "") + z.tit) + '</td><td class="vtb-qa"><button type="button" data-vtb-go="' + z.proy + '" data-vtb-gotab="' + (z.plan ? "plan" : "acciones") + '">' + ic("arrow-right") + "</button></td></tr>"; });
            }
            body = '<table class="vtb-tbl"><thead><tr><th>Día</th><th>Tipo</th><th>Proyecto</th><th>Detalle</th><th></th></tr></thead><tbody>' + (tr || '<tr><td colspan="5" class="vtb-empty">Nada en estos 14 días.</td></tr>') + "</tbody></table>";
        }
        var leg = '<div class="vtb-cap-leg">' + pill("D 8 h", "d") + ' disponibilidad &nbsp; <span class="vtb-lgi"><i class="vtb-sw-c" style="background:#9B1B4A"></i>visita (color del proyecto)</span>'
                + '<span class="vtb-lgi"><span class="vtb-ab" style="--c:#D97706">1 vence</span> acción a mi cargo</span><span class="vtb-lgi"><span class="vtb-db is-r">R</span> desarrollo registrado</span><span class="vtb-lgi"><span class="vtb-db is-p">P</span> programado</span></div>';
        return boxH("Calendario", "calendar-days", nav(title) + body + (st.cal === "lista" ? "" : leg), "agenda + visitas + vencimientos + desarrollo · tocá un día para ver el detalle", tools);
    }
    function dayPanel(st, d, wide) {
        var x = dayInfo(st, d), g = x.g, tot = x.vis.reduce(function (a, y) { return a + y.h; }, 0);
        var s = '<div class="vtb-day' + (wide ? " is-wide" : "") + '"><div class="vtb-day-h"><b>' + DN[d.getDay()] + " " + dm(d) + "</b><span>" + agTag(g) + " " + (tot ? H(tot) + " h asignadas" : "sin visitas") + "</span></div>";
        s += '<div class="vtb-day-cols"><div><div class="vtb-day-s">Visitas</div>' + (x.vis.length ? x.vis.map(function (y) { return vb(st, y, false); }).join("") : '<div class="vtb-li vtb-muted">Sin visitas</div>') + "</div>";
        s += '<div><div class="vtb-day-s">Desarrollo' + (x.r || x.p ? " (" + H(x.r + x.p) + " h)" : "") + "</div>" + (x.dev.length ? x.dev.map(function (z) { return '<div class="vtb-li">' + (z.tipo === "REALIZADO" ? '<span class="vtb-db is-r">R</span>' : '<span class="vtb-db is-p">P</span>') + " " + esc((z.item ? z.item + " " : "") + z.tit) + " · " + H(z.h) + " h</div>"; }).join("") : '<div class="vtb-li vtb-muted">Sin desarrollo</div>') + "</div>";
        s += '<div><div class="vtb-day-s">Vencen</div>' + (x.acc.length ? x.acc.map(function (a) { return '<div class="vtb-li">' + ptag(st.D, a.proy) + " " + esc((a.item ? a.item + " " : "") + a.tit) + "</div>"; }).join("") : '<div class="vtb-li vtb-muted">Nada vence este día</div>') + "</div></div>";
        var pj = x.vis.length ? x.vis[0].v.proy : (x.acc.length ? x.acc[0].proy : "");
        if (pj) s += '<div class="vtb-day-a"><button type="button" class="vtb-btn is-p" data-vtb-go="' + pj + '" data-vtb-gotab="plan">' + ic("edit") + 'Cargar desarrollo</button><button type="button" class="vtb-btn" data-vtb-go="' + pj + '">' + ic("arrow-right") + "Abrir V360</button></div>";
        return s + "</div>";
    }

    /* ---------------- graficos (SVG, una sola escala por grafico) ---------------- */
    function svg(W, Hh, inner, lbl) { return '<svg viewBox="0 0 ' + W + " " + Hh + '" class="vtb-svg" role="img" aria-label="' + esc(lbl) + '">' + inner + "</svg>"; }
    function grid(L, W, y, vals, unit) {
        return vals.map(function (g) { return '<line x1="' + L + '" x2="' + (W - 6) + '" y1="' + y(g).toFixed(1) + '" y2="' + y(g).toFixed(1) + '" class="vtb-grid"/><text x="' + (L - 4) + '" y="' + (y(g) + 3).toFixed(1) + '" class="vtb-ax" text-anchor="end">' + g + unit + "</text>"; }).join("");
    }
    function legend(items) { return '<div class="vtb-cap-leg">' + items.map(function (i) { return '<span class="vtb-lgi"><i class="' + (i[2] || "vtb-sw-c") + '" style="background:' + i[1] + '"></i>' + i[0] + "</span>"; }).join("") + "</div>"; }
    function chHorasDia(st) {
        var D = st.D, h = D.hoy, f0 = new Date(h.getFullYear(), h.getMonth(), 1), n = new Date(h.getFullYear(), h.getMonth() + 1, 0).getDate();
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
            else if (g && g.tipo === "LICENCIA") o += '<rect x="' + x.toFixed(1) + '" y="' + y(8).toFixed(1) + '" width="' + (bw - 4).toFixed(1) + '" height="' + (y(0) - y(8)).toFixed(1) + '" class="vtb-lic"><title>' + dm(d) + ": licencia</title></rect>";
            var hv = byDay[k] || 0, dv = devD[k] || 0, fut = d > h;
            if (hv > 0) o += '<rect x="' + x.toFixed(1) + '" y="' + y(hv).toFixed(1) + '" width="' + (bw - 4).toFixed(1) + '" height="' + (y(0) - y(hv)).toFixed(1) + '" rx="3" fill="' + (fut ? "#2563EB" : "#9B1B4A") + '"><title>' + dm(d) + ": " + H(hv) + " h de visita" + (fut ? " (programada)" : "") + ", " + H(dv) + " h de desarrollo</title></rect>";
            if (dv > 0) o += '<circle cx="' + (x + (bw - 4) / 2).toFixed(1) + '" cy="' + y(Math.min(dv, mx)).toFixed(1) + '" r="3.2" fill="' + (fut ? "#7C3AED" : "#0F9F8F") + '" stroke="#fff" stroke-width="1.5"><title>' + dm(d) + ": " + H(dv) + " h de desarrollo</title></circle>";
            if ((i + 1) % 5 === 0 || i === 0) o += '<text x="' + (x + (bw - 4) / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + (i + 1) + "</text>";
        }
        var xh = L + (h.getDate() - 1) * bw + bw / 2;
        o += '<line x1="' + xh.toFixed(1) + '" x2="' + xh.toFixed(1) + '" y1="10" y2="' + (Hh - B) + '" class="vtb-today"/><text x="' + xh.toFixed(1) + '" y="9" class="vtb-ax vtb-today-t" text-anchor="middle">hoy</text>';
        return boxH("Horas por día", "chart-bar", svg(W, Hh, o, "Horas por dia") + legend([["Visita ejecutada", "#9B1B4A"], ["Visita programada", "#2563EB"], ["Desarrollo registrado", "#0F9F8F", "vtb-dot"], ["Desarrollo programado", "#7C3AED", "vtb-dot"], ["Licencia", "", "vtb-sw-h"], ["Fin de semana / feriado", "#F1F5F9"]]),
                    D.mes + " · barra = horas de visita del día · punto = horas de desarrollo");
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
            if (m.e) o += '<rect x="' + x.toFixed(1) + '" y="' + y(m.e).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(0) - y(m.e)).toFixed(1) + '" rx="4" fill="#9B1B4A"><title>' + esc(m.l) + ": " + H(m.e) + " h ejecutadas</title></rect>";
            if (m.p) o += '<rect x="' + x.toFixed(1) + '" y="' + y(m.e + m.p).toFixed(1) + '" width="' + w.toFixed(1) + '" height="' + (y(m.e) - y(m.e + m.p) - (m.e ? 2 : 0)).toFixed(1) + '" rx="4" fill="#2563EB"><title>' + esc(m.l) + ": " + H(m.p) + " h programadas</title></rect>";
            if (m.c) o += '<line x1="' + (x - 4).toFixed(1) + '" x2="' + (x + w + 4).toFixed(1) + '" y1="' + y(m.c).toFixed(1) + '" y2="' + y(m.c).toFixed(1) + '" stroke="#1e293b" stroke-width="2" stroke-linecap="round"><title>' + esc(m.l) + ": capacidad " + H(m.c) + " h</title></line>";
            o += '<text x="' + (x + w / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + esc(m.l) + "</text>";
            if (m.c) o += '<text x="' + (x + w / 2).toFixed(1) + '" y="' + (y(Math.max(m.c, m.e + m.p)) - 5).toFixed(1) + '" class="vtb-ax" text-anchor="middle" style="font-weight:700;fill:#1e293b">' + Math.round((m.e + m.p) * 100 / m.c) + "%</text>";
        });
        return boxH("Horas por mes", "chart-bar", svg(W, Hh, o, "Horas por mes") + legend([["Ejecutadas", "#9B1B4A"], ["Programadas (mes en curso)", "#2563EB"], ["Capacidad (días disponibles × 8)", "#1e293b", "vtb-tick"]]), "últimos 6 meses · % = uso de la capacidad");
    }
    function chVenc(st) {
        var D = st.D, h = D.hoy, b = [0, 0, 0, 0, 0];
        D.A.forEach(function (a) {
            if (a.fin || !okP(st, a.proy)) return;
            var v = a.vence;
            b[!v ? 4 : v < h ? 0 : diff(h, v) === 0 ? 1 : diff(h, v) <= 7 ? 2 : 3]++;
        });
        var L = [["Vencidas", "#B42318", "venc"], ["Hoy", "#D97706", "hoy"], ["7 días", "#D97706", "sem"], ["Más adelante", "#64748B", "abi"], ["Sin fecha", "#94A3B8", "abi"]], mx = Math.max.apply(null, b) || 1;
        var r = L.map(function (l, i) { return '<div class="vtb-hb" data-vtb-ptab="' + l[2] + '" role="button" title="Ver en Para hacer"><span class="vtb-hb-n">' + l[0] + '</span><div class="vtb-hb-b"><span style="width:' + Math.max(b[i] * 100 / mx, b[i] ? 2 : 0) + "%;background:" + l[1] + '"></span></div><b>' + b[i] + "</b></div>"; }).join("");
        return boxH("Acciones abiertas por vencimiento", "list-checks", r + '<div class="vtb-help">Tocá una barra para verlas en Para hacer.</div>', (b[0] + b[1] + b[2] + b[3] + b[4]) + " abiertas a mi cargo");
    }
    function chProy(st) {
        var D = st.D, L = D.plist.filter(function (p) { return okP(st, p.id) && (st.prk === "mes" ? p.asig + p.dev > 0 : p.h12 > 0); });
        L.sort(function (a, b) { return st.prk === "mes" ? b.asig - a.asig : b.h12 - a.h12; });
        L = L.slice(0, 8);
        var mx = Math.max.apply(null, L.map(function (p) { return st.prk === "mes" ? Math.max(p.asig, p.dev) : p.h12; }).concat([1]));
        var r = L.map(function (p) {
            var a = st.prk === "mes" ? p.asig : p.h12;
            return '<div class="vtb-hp"><div class="vtb-hp-n">' + ptag(D, p.id, true) + '<small>' + esc(p.srv || p.nom) + '</small></div><div class="vtb-hp-b"><span style="width:' + (a * 100 / mx) + "%;background:" + p.col + '" title="' + (st.prk === "mes" ? "Asignadas" : "Ejecutadas") + ": " + H(a) + ' h"></span>'
                 + (st.prk === "mes" ? '<span style="width:' + (p.dev * 100 / mx) + '%;background:#0F9F8F" title="Desarrollo registrado: ' + H(p.dev) + ' h"></span>' : "") + '</div><div class="vtb-hp-v"><b>' + H(a) + " h</b>" + (st.prk === "mes" ? " / " + H(p.dev) + " h dev." : "") + "</div></div>";
        }).join("") || '<div class="vtb-empty">Sin horas en el período.</div>';
        var tools = '<div class="vtb-chips"><button type="button" data-vtb-prk="mes" class="' + (st.prk === "mes" ? "is-on" : "") + '">Mes</button><button type="button" data-vtb-prk="12" class="' + (st.prk !== "mes" ? "is-on" : "") + '">12 meses</button></div>';
        return boxH("Horas por proyecto", "briefcase", r + (st.prk === "mes" ? legend([["Asignadas en visitas (color del proyecto)", "#64748B"], ["Desarrollo registrado", "#0F9F8F"]]) : legend([["Ejecutadas, últimos 12 meses", "#64748B"]])),
                    st.prk === "mes" ? D.mes + " · asignadas y desarrollo" : "ejecutadas, últimos 12 meses", tools);
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
            if (w.r) o += '<rect x="' + x.toFixed(1) + '" y="' + y(w.r).toFixed(1) + '" width="' + ww.toFixed(1) + '" height="' + (y(0) - y(w.r)).toFixed(1) + '" rx="4" fill="#0F9F8F"><title>sem ' + dm(w.d) + ": " + H(w.r) + " h registradas</title></rect>";
            if (w.p) o += '<rect x="' + x.toFixed(1) + '" y="' + y(w.r + w.p).toFixed(1) + '" width="' + ww.toFixed(1) + '" height="' + (y(w.r) - y(w.r + w.p) - (w.r ? 2 : 0)).toFixed(1) + '" rx="4" fill="#7C3AED"><title>sem ' + dm(w.d) + ": " + H(w.p) + " h programadas</title></rect>";
            o += '<text x="' + (x + ww / 2).toFixed(1) + '" y="' + (Hh - 8) + '" class="vtb-ax" text-anchor="middle">' + dm(w.d) + "</text>";
        });
        return boxH("Desarrollo por semana", "edit", svg(W, Hh, o, "Desarrollo por semana") + legend([["Desarrollo registrado", "#0F9F8F"], ["Desarrollo programado", "#7C3AED"]]), "últimas 4 semanas y próximas 3 · por fecha de la visita");
    }

    /* ---------------- personalizar ---------------- */
    function panelOrden(st) {
        var d = st.draft;
        var li = d.order.map(function (k, i) {
            var c = CARDS.filter(function (x) { return x.k === k; })[0];
            return '<div class="vtb-po-r"><b>' + (i + 1) + "</b><span>" + c.t + '</span><button type="button" data-vtb-mv="' + k + '|-1"' + (i === 0 ? " disabled" : "") + '>&#9650;</button><button type="button" data-vtb-mv="' + k + '|1"' + (i === d.order.length - 1 ? " disabled" : "") + '>&#9660;</button>'
                 + '<label class="vtb-sw' + (d.hidden[k] ? "" : " is-on") + '" data-vtb-hide="' + k + '" title="Mostrar / ocultar"><i></i></label></div>';
        }).join("");
        var top = [["kh", "Indicadores de horas"], ["ka", "Indicadores de proyectos, visitas y acciones"]].map(function (x, i) {
            return '<div class="vtb-po-r"><b>' + (i + 1) + "</b><span>" + x[1] + '</span><label class="vtb-sw' + (d.hidden[x[0]] ? "" : " is-on") + '" data-vtb-hide="' + x[0] + '"><i></i></label></div>';
        }).join("");
        var cal = [["dia", "Día"], ["semana", "Semana"], ["mes", "Mes"], ["lista", "Lista"]].map(function (v) { return '<button type="button" data-vtb-dcal="' + v[0] + '" class="' + (d.cal === v[0] ? "is-on" : "") + '">' + v[1] + "</button>"; }).join("");
        return '<div class="vtb-po"><div class="vtb-po-h"><b>Personalizar el tablero</b><small>flechas para ordenar; el interruptor muestra u oculta</small></div>'
             + '<div class="vtb-day-s">Arriba (fijos)</div>' + top + '<div class="vtb-day-s">Cards</div>' + li
             + '<div class="vtb-day-s">Al abrir</div><div class="vtb-po-r is-w"><span>Calendario abre en</span><div class="vtb-chips">' + cal + "</div></div>"
             + '<div class="vtb-day-a"><button type="button" class="vtb-btn" data-vtb-reset>Volver al orden original</button><span class="vtb-sp"></span><button type="button" class="vtb-btn" data-vtb-pers>Cancelar</button><button type="button" class="vtb-btn is-p" data-vtb-save>Guardar</button></div>'
             + '<div class="vtb-help">Se guarda en este navegador.</div></div>';
    }
    function card(st, k, n, body, edit, folded, hidden) {
        var c = CARDS.filter(function (x) { return x.k === k; })[0];
        var ctrl = edit ? "" : '<span class="vtb-cc"><button type="button" data-vtb-fold="' + k + '" title="' + (folded ? "Desplegar" : "Plegar") + '">' + (folded ? "&#9656;" : "&#9662;") + "</button></span>";
        return '<div class="vtb-card' + (edit ? " is-edit" : "") + (folded ? " is-folded" : "") + (hidden ? " is-hidden" : "") + '"><div class="vtb-card-h"><span class="vtb-card-n">' + n + "</span>" + c.t + ctrl + "</div>" + (folded ? "" : body) + "</div>";
    }

    /* ---------------- render ---------------- */
    function render(page) {
        var st = S(page), root = page.querySelector("[data-vtb-root]");
        if (!root) return;
        var pr = st.edit ? st.draft : st.pr;
        var html = header(st);
        if (!pr.hidden.kh) html += kpiHoras(st);
        if (!pr.hidden.ka) html += kpiMini(st);
        if (st.view === "graf") {
            html += '<div class="vtb-grid2e">' + chHorasDia(st) + chAccDia(st) + "</div><div class=\"vtb-grid2e\">" + chMes(st) + chVenc(st) + "</div>"
                  + '<div class="vtb-grid2e">' + chProy(st) + chPlan(st) + "</div><div class=\"vtb-grid2e\">" + chEtapa(st) + chDevSem(st) + "</div>";
        } else {
            var parts = { hacer: function () { return '<div class="vtb-grid2">' + bandeja(st) + '<div class="vtb-col">' + proximas(st) + "</div></div>"; }, proy: function () { return proyectos(st); }, cal: function () { return calendario(st); } };
            var cards = "", n = 0;
            pr.order.forEach(function (k) {
                if (pr.hidden[k] && !st.edit) return;
                n++;
                cards += card(st, k, n, parts[k](), st.edit, !st.edit && !!st.pr.folded[k], !!pr.hidden[k]);
            });
            html += st.edit ? '<div class="vtb-edit-wrap"><div>' + cards + "</div>" + panelOrden(st) + "</div>" : cards;
        }
        root.innerHTML = html;
    }

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
        if ((el = t.closest("[data-vtb-go]"))) { e.preventDefault(); e.stopPropagation(); goV360(page, el.getAttribute("data-vtb-go"), el.getAttribute("data-vtb-gotab") || ""); return; }
        if ((el = t.closest("[data-vtb-view]"))) { st.view = el.getAttribute("data-vtb-view"); st.edit = false; render(page); return; }
        if ((el = t.closest("[data-vtb-pers]"))) {
            st.edit = !st.edit;
            st.draft = st.edit ? JSON.parse(JSON.stringify(st.pr)) : null;
            render(page);
            return;
        }
        if ((el = t.closest("[data-vtb-save]"))) { st.pr = st.draft; st.cal = st.pr.cal; savePrefs(page, st.pr); st.edit = false; st.draft = null; render(page); return; }
        if ((el = t.closest("[data-vtb-reset]"))) { st.draft = { order: CARDS.map(function (c) { return c.k; }), hidden: {}, folded: {}, cal: "semana" }; render(page); return; }
        if ((el = t.closest("[data-vtb-mv]"))) {
            var q = el.getAttribute("data-vtb-mv").split("|"), o = st.draft.order, i = o.indexOf(q[0]), j = i + (+q[1]);
            if (i >= 0 && j >= 0 && j < o.length) { o.splice(i, 1); o.splice(j, 0, q[0]); }
            render(page);
            return;
        }
        if ((el = t.closest("[data-vtb-hide]"))) { var hk = el.getAttribute("data-vtb-hide"); st.draft.hidden[hk] = !st.draft.hidden[hk]; render(page); return; }
        if ((el = t.closest("[data-vtb-dcal]"))) { st.draft.cal = el.getAttribute("data-vtb-dcal"); render(page); return; }
        if ((el = t.closest("[data-vtb-fold]"))) { var fk = el.getAttribute("data-vtb-fold"); st.pr.folded[fk] = !st.pr.folded[fk]; savePrefs(page, st.pr); render(page); return; }
        if ((el = t.closest("[data-vtb-tab]"))) { st.tab = el.getAttribute("data-vtb-tab"); st.pg = 0; render(page); return; }
        if ((el = t.closest("[data-vtb-ptab]"))) {
            st.tab = el.getAttribute("data-vtb-ptab"); st.pg = 0; st.view = "tab";
            if (st.pr.hidden.hacer) { st.pr.hidden.hacer = false; }
            st.pr.folded.hacer = false;
            render(page);
            var b = page.querySelector(".vtb-tabs");
            if (b && b.scrollIntoView) b.scrollIntoView({ behavior: "smooth", block: "center" });
            return;
        }
        if ((el = t.closest("[data-vtb-pg]"))) { st.pg = Math.max(0, st.pg + (+el.getAttribute("data-vtb-pg"))); render(page); return; }
        if ((el = t.closest("[data-vtb-cal]"))) { st.cal = el.getAttribute("data-vtb-cal"); render(page); return; }
        if ((el = t.closest("[data-vtb-cnav]"))) {
            var s = +el.getAttribute("data-vtb-cnav");
            if (s === 0) st.cd = st.D.hoy;
            else if (st.cal === "mes") st.cd = new Date(st.cd.getFullYear(), st.cd.getMonth() + s, 1);
            else st.cd = add(st.cd, s * (st.cal === "semana" ? 7 : st.cal === "lista" ? 14 : 1));
            render(page);
            return;
        }
        if ((el = t.closest("[data-vtb-day]"))) { st.cd = pd(el.getAttribute("data-vtb-day")); if (st.cal === "semana") st.cal = "dia"; render(page); return; }
        if ((el = t.closest("[data-vtb-prk]"))) { st.prk = el.getAttribute("data-vtb-prk"); render(page); return; }
        if ((el = t.closest("tr[data-vtb-exp]"))) { var ek = el.getAttribute("data-vtb-exp"); st.exp[ek] = !st.exp[ek]; render(page); return; }
    });
    document.addEventListener("change", function (e) {
        var t = e.target, page = t && t.closest ? t.closest("[data-vtb]") : null;
        if (!page) return;
        if (t.matches("[data-vtb-f]")) { var st = S(page); st.f = t.value; st.pg = 0; render(page); }
    });
    var qT = null;
    document.addEventListener("input", function (e) {
        var t = e.target, page = t && t.closest ? t.closest("[data-vtb]") : null;
        if (!page || !t.matches("[data-vtb-q]")) return;
        clearTimeout(qT);
        qT = setTimeout(function () {
            var st = S(page), pos = t.selectionStart;
            st.q = String(t.value || "").trim().toLowerCase();
            st.pg = 0;
            render(page);
            var n = page.querySelector("[data-vtb-q]");
            if (n) { n.focus(); try { n.setSelectionRange(pos, pos); } catch (x) { } }
        }, 250);
    });

    function init() { document.querySelectorAll("[data-vtb]").forEach(function (p) { if (!p.__vtbInit) { p.__vtbInit = true; render(p); } }); }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
    new MutationObserver(function () { init(); }).observe(document.documentElement, { childList: true, subtree: true });
})(window, document);
