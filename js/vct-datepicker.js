/* vct-datepicker.js - v2
   ============================================================================
   Picker de fecha con la estetica visual propia de VCT, en vez del
   <input type="date"> nativo del browser. Aislado de vct-main.js, mismo
   criterio que vct-config-parametria.js/vct-email-template-designer.js.

   No cambia el contrato con el servidor: el <input type="date"> original
   sigue existiendo en el DOM (oculto visualmente, igual que
   .vct-custom-select-native en vct-main.css) con su mismo name="SP.TEXTOxx"
   -- el picker solo le escribe el valor ISO (yyyy-mm-dd) y dispara un
   evento "change" nativo sobre el, asi que todo lo que ya escuchaba ese
   input (el filtro liviano de vct-reportes.js, VCT.DomForm, etc.) se entera
   exactamente igual que con el date picker del browser.

   Reusa, sin reimplementar:
     - La matematica de grilla de mes de vct-agenda.js (renderMonth):
       firstOfMonth/startWeekday/daysInMonth/totalCells, pad(), dateKey().
     - El recorte visual + logica de colision con el viewport de los
       dropdowns ya estandarizados de vct-main.js/vct-main.css
       (.vct-custom-select-menu, updateSelectDirection) -- ver
       vct-reportes.css para las reglas .vct-datepicker-* que calcan ese
       mismo recorte (radius, sombra doble, fade+slide, is-dropup).

   Alcance: los <input type="date"> DENTRO de un DataGrid ([data-vct-dg]) o de Reportes
   ([data-vct-report-root]), mas cualquiera que lo pida con data-vct-datepicker. Regla de
   plataforma: toda pantalla que use DataGrid usa ESTE picker para sus fechas. No toca otros
   <input type="date"> (ej. el modal de feriados de Agenda, que vct-agenda.js manipula asumiendo
   el input nativo de siempre). vct-datagrid.js carga este script (y vct-datepicker.css) solo
   cuando encuentra una fecha en una grilla.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctDatePickerLoaded) return; /* puede venir del tag de la pantalla Y del motor */
    window.__vctDatePickerLoaded = true;

    var MESES = ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"];
    var DIAS_ABREV = ["Lu","Ma","Mi","Ju","Vi","Sá","Do"];

    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    function isoOf(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
    function dmyOf(d) { return pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + "/" + d.getFullYear(); }

    function parseIso(value) {
        if (!value) return null;
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
        if (!m) return null;
        var d = new Date(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10));
        return isNaN(d.getTime()) ? null : d;
    }

    function closeAll(except) {
        document.querySelectorAll(".vct-datepicker.is-open").forEach(function (wrap) {
            if (wrap !== except) wrap.classList.remove("is-open", "is-dropup");
        });
    }

    function updateDirection(wrap) {
        var trigger = wrap.querySelector(".vct-datepicker-trigger");
        var menu = wrap.querySelector(".vct-datepicker-menu");
        if (!trigger || !menu) return;
        wrap.classList.remove("is-dropup");
        var rect = trigger.getBoundingClientRect();
        var availableBelow = window.innerHeight - rect.bottom;
        var availableAbove = rect.top;
        var menuHeight = Math.min(menu.scrollHeight || 300, 320) + 10;
        if (availableBelow < menuHeight && availableAbove > availableBelow)
            wrap.classList.add("is-dropup");
    }

    function renderGrid(wrap, cursor) {
        var year = cursor.getFullYear(), month = cursor.getMonth() + 1;
        var native = wrap.querySelector(".vct-datepicker-native");
        var selected = parseIso(native.value);
        var today = new Date();

        wrap.querySelector(".vct-datepicker-title").textContent = MESES[month - 1] + " " + year;

        var firstOfMonth = new Date(year, month - 1, 1);
        var startWeekday = (firstOfMonth.getDay() + 6) % 7; /* lunes=0 */
        var daysInMonth = new Date(year, month, 0).getDate();
        var totalCells = Math.ceil((startWeekday + daysInMonth) / 7) * 7;
        var dayNum = 1 - startWeekday;

        var html = '<table class="vct-datepicker-table"><thead><tr>' +
            DIAS_ABREV.map(function (d) { return "<th>" + d + "</th>"; }).join("") +
            "</tr></thead><tbody>";

        for (var w = 0; w < totalCells / 7; w++) {
            html += "<tr>";
            for (var d = 0; d < 7; d++) {
                if (dayNum < 1 || dayNum > daysInMonth) {
                    html += '<td class="vct-datepicker-cell vct-datepicker-cell-empty"></td>';
                } else {
                    var cellDate = new Date(year, month - 1, dayNum);
                    var cls = "vct-datepicker-cell";
                    if (d === 5 || d === 6) cls += " vct-datepicker-cell-weekend";
                    if (selected && isoOf(cellDate) === isoOf(selected)) cls += " vct-datepicker-cell-selected";
                    else if (isoOf(cellDate) === isoOf(today)) cls += " vct-datepicker-cell-today";
                    html += '<td class="' + cls + '" data-vct-datepicker-day="' + isoOf(cellDate) + '">' + dayNum + "</td>";
                }
                dayNum++;
            }
            html += "</tr>";
        }
        html += "</tbody></table>";
        wrap.querySelector(".vct-datepicker-grid").innerHTML = html;
    }

    function openPicker(wrap) {
        var native = wrap.querySelector(".vct-datepicker-native");
        var start = parseIso(native.value) || new Date();
        wrap.__vctCursor = new Date(start.getFullYear(), start.getMonth(), 1);
        renderGrid(wrap, wrap.__vctCursor);
        closeAll(wrap);
        wrap.classList.add("is-open");
        wrap.querySelector(".vct-datepicker-trigger").setAttribute("aria-expanded", "true");
        updateDirection(wrap);
    }

    function closePicker(wrap) {
        wrap.classList.remove("is-open", "is-dropup");
        wrap.querySelector(".vct-datepicker-trigger").setAttribute("aria-expanded", "false");
    }

    function selectDay(wrap, iso) {
        var native = wrap.querySelector(".vct-datepicker-native");
        native.value = iso;
        native.dispatchEvent(new Event("input", { bubbles: true }));
        native.dispatchEvent(new Event("change", { bubbles: true }));
        updateTriggerLabel(wrap);
        closePicker(wrap);
    }

    function updateTriggerLabel(wrap) {
        var native = wrap.querySelector(".vct-datepicker-native");
        var valueEl = wrap.querySelector(".vct-datepicker-value");
        var d = parseIso(native.value);
        if (d) {
            valueEl.textContent = dmyOf(d);
            valueEl.classList.remove("is-placeholder");
        } else {
            valueEl.textContent = native.getAttribute("placeholder") || native.getAttribute("aria-label") || "Seleccionar fecha";
            valueEl.classList.add("is-placeholder");
        }
    }

    function upgrade(input) {
        if (input.dataset.vctDatepickerReady === "1") return;
        input.dataset.vctDatepickerReady = "1";

        var wrap = document.createElement("span");
        wrap.className = "vct-datepicker";

        input.parentNode.insertBefore(wrap, input);
        wrap.appendChild(input);
        input.className = (input.className ? input.className + " " : "") + "vct-datepicker-native";

        var trigger = document.createElement("button");
        trigger.type = "button";
        trigger.className = "vct-datepicker-trigger";
        trigger.setAttribute("aria-haspopup", "dialog");
        trigger.setAttribute("aria-expanded", "false");
        trigger.innerHTML =
            '<span class="vct-datepicker-value"></span>' +
            '<span class="vct-datepicker-icon" aria-hidden="true">' +
                '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
                    '<rect x="3" y="4" width="18" height="18" rx="2"></rect>' +
                    '<path d="M3 9h18M8 2v4M16 2v4"></path>' +
                '</svg>' +
            '</span>';
        wrap.appendChild(trigger);

        var menu = document.createElement("div");
        menu.className = "vct-datepicker-menu";
        menu.setAttribute("role", "dialog");
        menu.innerHTML =
            '<div class="vct-datepicker-head">' +
                '<button type="button" class="vct-datepicker-nav" data-vct-datepicker-nav="-1" aria-label="Mes anterior">&#8249;</button>' +
                '<span class="vct-datepicker-title"></span>' +
                '<button type="button" class="vct-datepicker-nav" data-vct-datepicker-nav="1" aria-label="Mes siguiente">&#8250;</button>' +
            '</div>' +
            '<div class="vct-datepicker-grid"></div>';
        wrap.appendChild(menu);

        updateTriggerLabel(wrap);

        trigger.addEventListener("click", function (event) {
            event.preventDefault();
            if (wrap.classList.contains("is-open")) closePicker(wrap);
            else openPicker(wrap);
        });

        menu.addEventListener("click", function (event) {
            var nav = event.target.closest("[data-vct-datepicker-nav]");
            if (nav) {
                var dir = parseInt(nav.getAttribute("data-vct-datepicker-nav"), 10);
                wrap.__vctCursor = new Date(wrap.__vctCursor.getFullYear(), wrap.__vctCursor.getMonth() + dir, 1);
                renderGrid(wrap, wrap.__vctCursor);
                return;
            }
            var cell = event.target.closest("[data-vct-datepicker-day]");
            if (cell) selectDay(wrap, cell.getAttribute("data-vct-datepicker-day"));
        });
    }

    var SEL = '[data-vct-dg] input[type="date"], [data-vct-report-root] input[type="date"], input[type="date"][data-vct-datepicker]';
    function scan(scope) {
        scope = scope || document;
        var inputs = [];
        if (scope.matches && scope.matches(SEL)) inputs.push(scope);
        if (scope.querySelectorAll)
            scope.querySelectorAll(SEL).forEach(function (i) { inputs.push(i); });
        inputs.forEach(upgrade);
    }

    document.addEventListener("click", function (event) {
        if (!event.target.closest(".vct-datepicker")) closeAll(null);
    });

    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") closeAll(null);
    });

    scan(document);

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                Array.prototype.forEach.call(m.addedNodes || [], function (n) {
                    if (n && n.nodeType === 1) scan(n);
                });
            });
        }).observe(document.documentElement, { childList: true, subtree: true });
    }
})(window, document);
