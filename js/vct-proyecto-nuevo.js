/* ========================================================================
   VCT PROYECTO NUEVO                                                   v1
   ------------------------------------------------------------------------
   Formulario "Nuevo proyecto" (dbo.VCT_PROYECTO_ALTA_RENDER). Solo actua
   dentro de .vct-pry-nuevo-page. No tiene logica de negocio propia: arma
   los controles de servicios y normas, mantiene los campos ocultos que lee
   dbo.VCT_PROYECTO_ALTA_GUARDAR y adelanta las mismas validaciones que el
   SP (el SP valida igual; esto es solo para avisar antes de enviar).
     SP.TEXTO22  servicios  id|aaaa-mm-dd|aaaa-mm-dd|horas;...
     SP.TEXTO24  normas     id,id,...
     SP.TEXTO23  mail a notificar: se completa con el mail del analista
                 elegido (option data-email); el usuario lo puede cambiar.
   ======================================================================== */
(function () {
    "use strict";
    if (window.VCTProyectoNuevo && window.VCTProyectoNuevo.version >= 1) return;

    var EXIGE_NORMAS = "CONSULTORIA"; /* mismo codigo que el SP */

    function q(root, sel) { return root ? root.querySelector(sel) : null; }
    function qa(root, sel) { return root ? Array.prototype.slice.call(root.querySelectorAll(sel)) : []; }
    function field(page, name) { return q(page, '[name="SP.' + name + '"]'); }
    function val(page, name) { var f = field(page, name); return f ? String(f.value || "").trim() : ""; }
    function setVal(page, name, v) { var f = field(page, name); if (f) f.value = v; }
    function esc(s) { return String(s || "").replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }
    function toIso(s) {
        s = String(s || "").trim();
        if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
        var m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(s);
        return m ? m[3] + "-" + m[2] + "-" + m[1] : "";
    }
    function catalog(page, name) {
        var t = q(page, 'template[data-vct-pry-catalog="' + name + '"]');
        if (!t) return [];
        var box = document.createElement("div");
        box.innerHTML = t.innerHTML;
        return qa(box, "option").map(function (o) {
            return { id: o.value, text: o.textContent, codigo: (o.getAttribute("data-codigo") || "").toUpperCase() };
        });
    }

    /* ---------------- servicios ---------------- */
    function buildServicios(page) {
        var host = q(page, "[data-vct-pry-srv]");
        if (!host || host.getAttribute("data-ready") === "1") return;
        host.setAttribute("data-ready", "1");

        var prev = {};
        val(page, "TEXTO22").split(";").forEach(function (it) {
            var p = it.split("|");
            if (p[0]) prev[p[0]] = { ini: p[1] || "", fin: p[2] || "", hrs: p[3] || "" };
        });

        var rows = catalog(page, "servicios").map(function (s) {
            var on = !!prev[s.id], v = prev[s.id] || { ini: "", fin: "", hrs: "" };
            return '<tr data-srv="' + esc(s.id) + '" data-codigo="' + esc(s.codigo) + '" class="' + (on ? "is-on" : "") + '">'
                + '<td class="vct-pry-nuevo-tg"><label class="vct-toggle"><input type="checkbox" data-srv-on' + (on ? " checked" : "") + '>'
                + '<span class="vct-toggle-track"><span class="vct-toggle-thumb"></span></span></label></td>'
                + '<td><b>' + esc(s.text) + '</b>' + (s.codigo === EXIGE_NORMAS ? '<small>solo se puede agregar en el alta</small>' : '<small>1..N &middot; se pueden sumar despu&eacute;s</small>') + '</td>'
                + '<td><input type="date" class="vct-input" data-srv-ini value="' + esc(v.ini) + '"></td>'
                + '<td><input type="date" class="vct-input" data-srv-fin value="' + esc(v.fin) + '"></td>'
                + '<td><input type="number" min="1" step="1" class="vct-input vct-pry-nuevo-hrs" data-srv-hrs value="' + esc(v.hrs) + '"></td>'
                + '</tr>';
        }).join("");

        host.innerHTML = '<table class="vct-pry-nuevo-tabla"><colgroup><col style="width:64px"><col><col style="width:150px"><col style="width:150px"><col style="width:130px"></colgroup>'
            + '<thead><tr><th></th><th>Servicio</th><th>Inicio</th><th>Fin</th><th class="r">Horas proyectadas</th></tr></thead><tbody>' + rows + '</tbody></table>';

        host.addEventListener("change", function (e) { onSrvChange(page, e); });
        host.addEventListener("input", function () { serialize(page); });
        serialize(page);
    }

    function onSrvChange(page, e) {
        var tr = e.target.closest("tr[data-srv]");
        if (tr && e.target.hasAttribute("data-srv-on")) {
            tr.classList.toggle("is-on", e.target.checked);
            if (e.target.checked) {
                var ini = q(tr, "[data-srv-ini]"), fin = q(tr, "[data-srv-fin]");
                if (!ini.value) ini.value = toIso(val(page, "TEXTO13"));
                if (!fin.value) fin.value = toIso(val(page, "TEXTO14"));
            }
        }
        serialize(page);
    }

    function selected(page) {
        return qa(page, "tr[data-srv]").filter(function (tr) { return q(tr, "[data-srv-on]").checked; }).map(function (tr) {
            return { id: tr.getAttribute("data-srv"), codigo: tr.getAttribute("data-codigo"),
                     ini: q(tr, "[data-srv-ini]").value, fin: q(tr, "[data-srv-fin]").value,
                     hrs: q(tr, "[data-srv-hrs]").value, name: q(tr, "b").textContent };
        });
    }

    /* ---------------- normas ---------------- */
    function buildNormas(page) {
        var host = q(page, "[data-vct-pry-normas]");
        if (!host || host.getAttribute("data-ready") === "1") return;
        host.setAttribute("data-ready", "1");
        var cat = catalog(page, "normas"), ids = val(page, "TEXTO24").split(",").filter(Boolean);

        function draw() {
            var chips = ids.map(function (id) {
                var n = cat.filter(function (c) { return c.id === id; })[0];
                return n ? '<span class="vct-pry-nuevo-chip">' + esc(n.text) + '<button type="button" data-norma-del="' + esc(id) + '" aria-label="Quitar">&times;</button></span>' : "";
            }).join("");
            var opts = cat.filter(function (c) { return ids.indexOf(c.id) < 0; })
                          .map(function (c) { return '<option value="' + esc(c.id) + '">' + esc(c.text) + '</option>'; }).join("");
            host.innerHTML = '<div class="vct-pry-nuevo-chips">' + chips
                + '<select class="vct-pry-nuevo-add" data-norma-add><option value="">Agregar norma...</option>' + opts + '</select></div>';
            setVal(page, "TEXTO24", ids.join(","));
        }
        host.addEventListener("change", function (e) {
            if (e.target.hasAttribute("data-norma-add") && e.target.value) { ids.push(e.target.value); draw(); }
        });
        host.addEventListener("click", function (e) {
            var b = e.target.closest("[data-norma-del]");
            if (b) { ids = ids.filter(function (x) { return x !== b.getAttribute("data-norma-del"); }); draw(); }
        });
        draw();
    }

    /* ---------------- serializacion + barra de horas ---------------- */
    function serialize(page) {
        var s = selected(page);
        setVal(page, "TEXTO22", s.map(function (x) { return [x.id, x.ini, x.fin, x.hrs].join("|"); }).join(";"));

        var bar = q(page, "[data-vct-pry-srv-bar]");
        if (!bar) return;
        var total = parseInt(val(page, "TEXTO15"), 10) || 0, suma = 0;
        s.forEach(function (x) { suma += parseInt(x.hrs, 10) || 0; });
        var seg = s.map(function (x, i) {
            var w = total > 0 ? Math.min(100, 100 * (parseInt(x.hrs, 10) || 0) / total) : 0;
            return '<span class="c' + (i % 3) + '" style="width:' + w + '%" title="' + esc(x.name) + ' ' + (x.hrs || 0) + ' h"></span>';
        }).join("");
        var estado = total <= 0 ? "Cargue el total de horas del proyecto"
                   : suma === total ? suma + " de " + total + " h asignadas"
                   : suma < total ? "faltan " + (total - suma) + " h (" + suma + " de " + total + ")"
                   : "sobran " + (suma - total) + " h (" + suma + " de " + total + ")";
        bar.innerHTML = '<div class="vct-pry-nuevo-track">' + seg + '</div>'
            + '<span class="vct-360-badge ' + (total > 0 && suma === total ? "is-active" : "is-cancel") + '">' + estado + '</span>';
    }

    /* ---------------- validacion previa (mismas reglas que el SP) ---------------- */
    function errores(page) {
        var e = [], s = selected(page), total = parseInt(val(page, "TEXTO15"), 10) || 0, suma = 0;
        var pIni = toIso(val(page, "TEXTO13")), pFin = toIso(val(page, "TEXTO14"));
        if (!s.length) e.push("Seleccione al menos un servicio.");
        s.forEach(function (x) {
            var h = parseInt(x.hrs, 10) || 0; suma += h;
            if (!x.ini || !x.fin) e.push(x.name + ": falta la fecha de inicio o de fin.");
            else if (x.fin < x.ini) e.push(x.name + ": la fecha de fin es anterior al inicio.");
            else if ((pIni && x.ini < pIni) || (pFin && x.fin > pFin)) e.push(x.name + ": las fechas deben estar dentro del plazo del proyecto.");
            if (h <= 0) e.push(x.name + ": cargue las horas proyectadas.");
        });
        if (s.length && total > 0 && suma !== total)
            e.push("La suma de horas de los servicios (" + suma + " h) debe ser igual al total del proyecto (" + total + " h).");
        if (s.some(function (x) { return x.codigo === EXIGE_NORMAS; }) && !val(page, "TEXTO24"))
            e.push("Con consultoría hay que seleccionar al menos una norma.");
        var mail = val(page, "TEXTO23");
        if (mail && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(mail)) e.push("El mail a notificar no es válido.");
        return e;
    }

    function showErrores(page, list) {
        var box = q(page, "[data-vct-validation-box]");
        if (!box) { window.alert(list.join("\n")); return; }
        box.innerHTML = '<div class="vct-validation-title">Revise el formulario</div><ul>' + list.map(function (x) { return "<li>" + esc(x) + "</li>"; }).join("") + "</ul>";
        box.style.display = "block";
        box.scrollIntoView({ behavior: "smooth", block: "center" });
    }

    /* window + captura: corre antes que el validate-next de vct-main.js (document) */
    window.addEventListener("click", function (e) {
        var btn = e.target && e.target.closest ? e.target.closest('[data-vct-command="validate-next"]') : null;
        var page = btn ? btn.closest(".vct-pry-nuevo-page") : null;
        if (!page) return;
        serialize(page);
        var list = errores(page);
        if (list.length) { e.preventDefault(); e.stopPropagation(); showErrores(page, list); }
    }, true);

    /* ---------------- mail del analista ---------------- */
    var autoMail = "";
    function analistaMail(page) {
        var sel = field(page, "TEXTO20");
        if (!sel) return "";
        var opt = sel.options && sel.selectedIndex >= 0 ? sel.options[sel.selectedIndex] : null;
        var m = opt ? opt.getAttribute("data-email") : "";
        if (!m) {
            var t = q(page, 'template[data-vct-field="TEXTO20"]');
            if (t) { var box = document.createElement("div"); box.innerHTML = t.innerHTML;
                     var o = q(box, 'option[value="' + String(sel.value).replace(/"/g, "") + '"]'); m = o ? o.getAttribute("data-email") : ""; }
        }
        return m || "";
    }
    document.addEventListener("change", function (e) {
        var t = e.target;
        if (!t || !t.name) return;
        var page = t.closest ? t.closest(".vct-pry-nuevo-page") : null;
        if (!page) return;
        if (t.name === "SP.TEXTO20") {
            var cur = val(page, "TEXTO23"), m = analistaMail(page);
            if (!cur || cur === autoMail) { setVal(page, "TEXTO23", m); autoMail = m; }
        }
        if (t.name === "SP.TEXTO15") serialize(page);
    });

    function init() {
        qa(document, ".vct-pry-nuevo-page").forEach(function (page) {
            buildServicios(page);
            buildNormas(page);
            if (!val(page, "TEXTO23")) { autoMail = analistaMail(page); if (autoMail) setVal(page, "TEXTO23", autoMail); }
        });
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else setTimeout(init, 0);
    new MutationObserver(function () { if (q(document, ".vct-pry-nuevo-page [data-vct-pry-srv]:not([data-ready])")) init(); })
        .observe(document.documentElement, { childList: true, subtree: true });

    window.VCTProyectoNuevo = { version: 1, init: init };
})();
