/* ========================================================================
   VCT ACCIONES                                                          v1
   ------------------------------------------------------------------------
   Pantalla Acciones (dbo.VCT_MAIN_ACCIONES, ACCIONES_PANTALLA_V2).
   - Cambio Lista / Calendario dentro de la card de cada pestana.
   - Calendario mensual armado con los datos ocultos .vct-acc-caldata
     (<i data-d="yyyymmdd" data-s="V|H|P|L" data-t="titulo">), filtrado por
     la situacion de la pestana (data-vct-acc-sit; T = todas).
   - Click en un dia: vuelve a Lista y busca esa fecha en la grilla.
   - "Marcar cumplida" / "Reabrir": buffer (ACC_ESTADO) + goto, y al volver
     queda abierta la misma pestana.
   Guarda propia: no depende de la guarda de vct-datagrid.js.
   ======================================================================== */
(function () {
    "use strict";
    if (window.VCTAcciones && window.VCTAcciones.version >= 1) return;

    var GUID_INICIO = "447E1496-AC9B-4821-B658-25AB8D1F45AE";
    var MESES = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    var DIAS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    var SIT_CLS = { V: "is-red", H: "is-amb", P: "is-bor", L: "is-gry" };

    function pad(n) { return (n < 10 ? "0" : "") + n; }
    function ymd(d) { return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()); }
    function parseYmd(s) { return new Date(+s.substr(0, 4), +s.substr(4, 2) - 1, +s.substr(6, 2)); }
    function dmy(s) { return s.substr(6, 2) + "/" + s.substr(4, 2) + "/" + s.substr(0, 4); }
    function esc(s) {
        return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    /* ---------------- datos ---------------- */
    function readData(root) {
        if (root._accData) return root._accData;
        var list = [];
        var box = root.querySelector(".vct-acc-caldata");
        if (box) {
            box.querySelectorAll("i[data-d]").forEach(function (i) {
                list.push({
                    d: i.getAttribute("data-d"), s: i.getAttribute("data-s") || "L", t: i.getAttribute("data-t") || "",
                    cli: i.getAttribute("data-cli") || "", proy: i.getAttribute("data-proy") || "", srv: i.getAttribute("data-srv") || "",
                    r: i.getAttribute("data-r") || "", ri: i.getAttribute("data-ri") || ""
                });
            });
        }
        root._accData = list;
        return list;
    }
    function itemsFor(root, sit) {
        return readData(root).filter(function (x) { return sit === "T" || x.s === sit; });
    }
    function todayOf(root) {
        var h = root.getAttribute("data-vct-acc-hoy");
        return h && h.length === 8 ? parseYmd(h) : new Date();
    }

    /* ---------------- calendario (UNIFICADO: monta vct-calendario, solo lectura) ----------------
       En vez de dibujar su propio mes, Acciones monta el engine view-only de
       vct-calendario (el mismo de Feriados y de las fichas 360). Las acciones
       viajan como eventos {f,x,c} y el color sale del estado (V/H/P/L). */
    var CAL_VER = "33";   /* version de vct-calendario.css/js a inyectar */

    function ensureCalendario(cb) {
        /* CSS */
        if (!document.querySelector('link[data-vct-cal-css]')) {
            var l = document.createElement("link");
            l.rel = "stylesheet"; l.href = "../css/vct-calendario.css?v=" + CAL_VER;
            l.setAttribute("data-vct-cal-css", "1");
            document.head.appendChild(l);
        }
        /* JS: si el archivo ya se ejecuto (lo marca el engine del consultor) listo */
        if (window.__vctAgcLoaded) { cb(); return; }
        if (document.querySelector('script[data-vct-cal-js]')) {
            var t = setInterval(function () { if (window.__vctAgcLoaded) { clearInterval(t); cb(); } }, 50);
            setTimeout(function () { clearInterval(t); cb(); }, 3000);
            return;
        }
        var s = document.createElement("script");
        s.src = "../js/vct-calendario.js?v=" + CAL_VER;
        s.setAttribute("data-vct-cal-js", "1");
        s.onload = function () { cb(); };
        s.onerror = function () { cb(); };
        document.head.appendChild(s);
    }

    function buildEvents(root, sit) {
        return itemsFor(root, sit).map(function (x) {
            var f = x.d.substr(0, 4) + "-" + x.d.substr(4, 2) + "-" + x.d.substr(6, 2);
            /* cli/proy/srv + consultor (r/ri) -> tooltip Cliente > Proyecto > Servicio(chips) > Consultor(avatar) > Descripcion */
            return { f: f, x: x.t, c: x.s, cli: x.cli, proy: x.proy, srv: x.srv, r: x.r, ri: x.ri };
        });
    }

    function mountCal(root, panel, cal, sit) {
        var events = buildEvents(root, sit);
        /* ACC_FERIADOS_V21: misma fuente que Feriados, independiente del filtro de acciones. */
        var scope=root.closest('[id^="step_"]') || document;
        var carriers=scope.querySelectorAll("[data-vct-acc-holidays]");
        var carrier=carriers.length ? carriers[carriers.length-1] : null;
        var holidaysJson=carrier ? carrier.getAttribute("data-vct-acc-holidays") : "[]";
        try { holidaysJson=JSON.stringify(JSON.parse(holidaysJson||"[]")); } catch(e){ holidaysJson="[]"; }

        var monthOpts = "";
        for (var m = 1; m <= 12; m++) monthOpts += '<option value="' + m + '">' + MESES[m - 1] + "</option>";
        var h =
            '<div class="vct-agenda vct-acc-cal-unified" data-vct-agenda-root data-vct-feriados="' + esc(holidaysJson) + '" data-vct-calendar-events="' + esc(JSON.stringify(events)) + '">' +
              '<div class="vct-agenda-toolbar">' +
                '<div class="vct-agenda-nav">' +
                  '<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>' +
                  '<h2 class="vct-agenda-title" data-vct-agenda-title></h2>' +
                  '<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button>' +
                '</div>' +
                '<div class="vct-agenda-view-toggle">' +
                  '<button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>' +
                  '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button>' +
                  '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">Día</button>' +
                '</div>' +
                '<div class="vct-agenda-jump">' +
                  '<select class="vct-select" data-vct-agenda-select-month>' + monthOpts + '</select>' +
                  '<select class="vct-select" data-vct-agenda-select-year></select>' +
                '</div>' +
              '</div>' +
              '<div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div>' +
            '</div>';
        cal.innerHTML = h;
        /* el engine de vct-calendario escucha este evento y escanea nuevos roots */
        document.dispatchEvent(new Event("vct:content-loaded"));
        if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(cal);
    }

    function renderCal(root, panel) {
        var cal = panel.querySelector("[data-vct-acc-cal]");
        if (!cal) return;
        var sit = panel.getAttribute("data-vct-acc-sit") || "T";
        ensureCalendario(function () { mountCal(root, panel, cal, sit); });
    }

    function setView(root, panel, view) {
        var list = panel.querySelector(".vct-acc-list");
        var cal = panel.querySelector("[data-vct-acc-cal]");
        if (!cal || !list) return;
        panel.querySelectorAll("[data-vct-acc-view]").forEach(function (b) {
            b.classList.toggle("is-on", b.getAttribute("data-vct-acc-view") === view);
            b.setAttribute("aria-pressed", b.getAttribute("data-vct-acc-view") === view ? "true" : "false");
        });
        if (view === "calendario") {
            renderCal(root, panel);
            list.hidden = true;
            cal.hidden = false;
        } else {
            cal.hidden = true;
            list.hidden = false;
        }
    }

    function searchInList(root, panel, key) {
        setView(root, panel, "lista");
        var input = panel.querySelector(".vctdg-search input");
        if (!input) return;
        input.value = dmy(key);
        input.dispatchEvent(new Event("input", { bubbles: true }));
        try { input.focus(); } catch (e) { }
    }

    /* ---------------- init ---------------- */
    function ensureActive(root) {
        var active = root.querySelector(".vct-360-panel.is-active");
        if (active) return;
        var name = root.getAttribute("data-vct-acc-default") || "todas";
        if (window.VCT && VCT.Tabs && typeof VCT.Tabs.activate === "function") VCT.Tabs.activate(root, name);
    }

    function init(root) {
        if (!root || root.getAttribute("data-vct-acc-ready") === "1") return;
        root.setAttribute("data-vct-acc-ready", "1");
        root._accData = null;
        /* VCT.Tabs puede venir de una V360 con "resumen" forzado: si no quedo
           ningun panel activo se abre la pestana sugerida por el SP. */
        setTimeout(function () { ensureActive(root); }, 0);
        setTimeout(function () { ensureActive(root); }, 400);
        /* el alerta del comando se va sola */
        var al = root.querySelector(".vct-acc-alert");
        if (al) setTimeout(function () { al.classList.add("is-hiding"); setTimeout(function () { if (al.parentNode) al.parentNode.removeChild(al); }, 400); }, 6000);
    }

    function scan(scope) {
        scope = scope || document;
        if (scope.matches && scope.matches("[data-vct-acc]")) init(scope);
        if (scope.querySelectorAll) scope.querySelectorAll("[data-vct-acc]").forEach(init);
    }

    /* ---------------- eventos (una sola vez, delegados) ---------------- */
    document.addEventListener("click", function (e) {
        var t = e.target;
        if (!t || !t.closest) return;

        var vb = t.closest("[data-vct-acc-view]");
        if (vb) {
            var p1 = vb.closest(".vct-acc-panel"), r1 = vb.closest("[data-vct-acc]");
            if (p1 && r1) { e.preventDefault(); setView(r1, p1, vb.getAttribute("data-vct-acc-view")); }
            return;
        }

        /* La navegacion de mes y el click en dia los maneja ahora el engine de
           vct-calendario (montado en la vista Calendario). Aca solo queda el
           toggle Lista/Calendario y los botones de estado. */

        var b = t.closest("[data-vct-acc-estado]");
        if (b && !b.disabled) {
            e.preventDefault();
            var est = b.getAttribute("data-vct-acc-estado");
            if (est === "PENDIENTE" && !window.confirm("¿Volver a abrir esta acción?")) return;
            if (!window.VCT || !VCT.Buffer || !VCT.Navigation) return;
            b.disabled = true;
            var root = b.closest("[data-vct-acc]");
            var tab = root ? root.getAttribute("data-vct-tabs-active") : "";
            if (tab && VCT.Tabs && typeof VCT.Tabs.rememberInternalTab === "function") VCT.Tabs.rememberInternalTab(tab);
            var S = function (k, v) { return Promise.resolve(VCT.Buffer.store(k, v)); };
            S("TEXTO30", "ACC_ESTADO")
                .then(function () { return S("IDSELEC03", b.getAttribute("data-vct-acc-id")); })
                .then(function () { return S("TEXTO11", est); })
                .then(function () { return S("FLAG01", "1"); })
                .then(function () { VCT.Navigation.goto(b, GUID_INICIO); })
                .catch(function () { b.disabled = false; });
        }
    });

    document.addEventListener("keydown", function (e) {
        if (e.key !== "Enter" && e.key !== " ") return;
        var day = e.target && e.target.closest ? e.target.closest("[data-vct-acc-day]") : null;
        if (!day) return;
        e.preventDefault();
        day.click();
    });

    /* SPA: la pantalla se inyecta sin recargar */
    function boot() {
        scan(document);
        if (window.MutationObserver && document.body) {
            new MutationObserver(function (muts) {
                for (var i = 0; i < muts.length; i++) {
                    var add = muts[i].addedNodes;
                    for (var j = 0; j < add.length; j++) if (add[j].nodeType === 1) scan(add[j]);
                }
            }).observe(document.body, { childList: true, subtree: true });
        }
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot); else boot();

    window.VCTAcciones = { version: 1, scan: scan, render: renderCal };
})();
