function vocEscapeHtml(value) {
    if (value === null || value === undefined) {
        return "";
    }

    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function vocGetColor(index) {
    var colors = [
        "#24367D",
        "#4CAF50",
        "#F44336",
        "#FF9800",
        "#9C27B0",
        "#13B8C8",
        "#E91E63",
        "#795548",
        "#8BC34A",
        "#3F51B5",
        "#FFEB3B",
        "#FF5722",
        "#607D8B",
        "#00BCD4",
        "#CDDC39",
        "#673AB7"
    ];

    return colors[index % colors.length];
}

function vocNormalizeData(data) {
    if (!data || !data.length) {
        return [];
    }

    var total = data.reduce(function(acc, item) {
        return acc + Number(item.value || 0);
    }, 0);

    var current = 0;

    return data.map(function(item, index) {
        var value = Number(item.value || 0);
        var percent = total > 0 ? (value / total) * 100 : 0;
        var start = current;
        var end = current + percent;

        current = end;

        return {
            label: item.label || "Sin dato",
            value: value,
            percent: percent,
            start: start,
            end: end,
            color: vocGetColor(index),
            index: index
        };
    });
}

function vocFindSliceByAngle(slices, anglePercent) {
    for (var i = 0; i < slices.length; i++) {
        if (anglePercent >= slices[i].start && anglePercent <= slices[i].end) {
            return slices[i];
        }
    }

    return null;
}

function vocGetPieAnglePercent(event, chart) {
    var rect = chart.getBoundingClientRect();

    var x = event.clientX - rect.left - rect.width / 2;
    var y = event.clientY - rect.top - rect.height / 2;

    var angle = Math.atan2(y, x) * 180 / Math.PI;

    angle = angle + 90;

    if (angle < 0) {
        angle += 360;
    }

    return (angle / 360) * 100;
}

function vocForcePieLayout(chart, legend, whiteOverlay, sliceOverlay, tooltip) {
    if (chart) {
        chart.style.width = "150px";
        chart.style.height = "150px";
        chart.style.minWidth = "150px";
        chart.style.maxWidth = "150px";
        chart.style.minHeight = "150px";
        chart.style.maxHeight = "150px";
        chart.style.borderRadius = "50%";
    }

    if (chart && chart.parentElement) {
        chart.parentElement.style.position = "relative";
        chart.parentElement.style.width = "150px";
        chart.parentElement.style.height = "150px";
        chart.parentElement.style.minWidth = "150px";
        chart.parentElement.style.maxWidth = "150px";
        chart.parentElement.style.minHeight = "150px";
        chart.parentElement.style.maxHeight = "150px";
        chart.parentElement.style.flex = "0 0 150px";
        chart.parentElement.style.overflow = "visible";
    }

    if (whiteOverlay) {
        whiteOverlay.style.display = "none";
        whiteOverlay.style.opacity = "0";
        whiteOverlay.style.pointerEvents = "none";
    }

    if (sliceOverlay) {
        sliceOverlay.style.position = "absolute";
        sliceOverlay.style.inset = "0";
        sliceOverlay.style.width = "150px";
        sliceOverlay.style.height = "150px";
        sliceOverlay.style.borderRadius = "50%";
        sliceOverlay.style.pointerEvents = "none";
    }

    if (tooltip) {
        tooltip.style.position = "absolute";
        tooltip.style.display = "block";
        tooltip.style.minWidth = "105px";
        tooltip.style.maxWidth = "170px";
        tooltip.style.background = "#0f172a";
        tooltip.style.color = "#ffffff";
        tooltip.style.padding = "6px 8px";
        tooltip.style.borderRadius = "8px";
        tooltip.style.fontSize = "11px";
        tooltip.style.lineHeight = "1.25";
        tooltip.style.zIndex = "20";
        tooltip.style.pointerEvents = "none";
        tooltip.style.opacity = "0";
    }

    if (legend) {
        legend.style.display = "flex";
        legend.style.flexDirection = "column";
        legend.style.gap = "6px";
        legend.style.minWidth = "160px";
        legend.style.maxWidth = "220px";
        legend.style.overflow = "hidden";
        legend.style.fontSize = "12px";
    }
}

vocRenderDoughnut(
    "estadoChart",
    "estadoLegend",
    vocDataEstados,
    {
        centerLabel: "Proyectos"
    }
);

vocRenderHorizontalBar(
    "servicioChart",
    "servicioLegend",
    vocDataServicios,
    {
        datasetLabel: "Servicios"
    }
);    function clearActive() {
        if (whiteOverlay) {
            whiteOverlay.style.display = "none";
            whiteOverlay.style.opacity = "0";
        }

        if (sliceOverlay) {
            sliceOverlay.style.background = "transparent";
            sliceOverlay.style.transform = "translate(0, 0)";
        }

        if (tooltip) {
            tooltip.style.opacity = "0";
        }

        var activeItems = legend.querySelectorAll(".legend-item.active");

        for (var i = 0; i < activeItems.length; i++) {
            activeItems[i].classList.remove("active");
            activeItems[i].style.background = "transparent";
            activeItems[i].style.color = "#334155";
            activeItems[i].style.transform = "translateX(0)";
        }
    }

    function activateSlice(slice, event) {
        if (!slice) {
            clearActive();
            return;
        }

        if (whiteOverlay) {
            whiteOverlay.style.display = "none";
            whiteOverlay.style.opacity = "0";
        }

        if (sliceOverlay) {
            var sliceBg =
                "conic-gradient(" +
                    "transparent 0% " + slice.start + "%, " +
                    slice.color + " " + slice.start + "% " + slice.end + "%, " +
                    "transparent " + slice.end + "% 100%" +
                ")";

            var middle = ((slice.start + slice.end) / 2) * 3.6 - 90;
            var radians = middle * Math.PI / 180;
            var moveX = Math.cos(radians) * 8;
            var moveY = Math.sin(radians) * 8;

            sliceOverlay.style.background = sliceBg;
            sliceOverlay.style.transform = "translate(" + moveX + "px, " + moveY + "px)";
        }

        if (tooltip) {
            var containerRect = chart.parentElement.getBoundingClientRect();

            var left = event.clientX - containerRect.left;
            var top = event.clientY - containerRect.top;

            tooltip.innerHTML =
                vocEscapeHtml(slice.label) +
                "<br>" +
                slice.value +
                " (" + slice.percent.toFixed(1) + "%)";

            tooltip.style.left = left + "px";
            tooltip.style.top = top + "px";
            tooltip.style.opacity = "1";
        }

        var items = legend.querySelectorAll(".legend-item");

        for (var i = 0; i < items.length; i++) {
            items[i].classList.remove("active");
            items[i].style.background = "transparent";
            items[i].style.color = "#334155";
            items[i].style.transform = "translateX(0)";
        }

        var currentItem = legend.querySelector('.legend-item[data-index="' + slice.index + '"]');

        if (currentItem) {
            currentItem.classList.add("active");
            currentItem.style.background = "#f8fafc";
            currentItem.style.color = "#111827";
            currentItem.style.transform = "translateX(3px)";
        }
    }

    chart.addEventListener("mousemove", function(event) {
        var anglePercent = vocGetPieAnglePercent(event, chart);
        var slice = vocFindSliceByAngle(slices, anglePercent);

        activateSlice(slice, event);
    });

    chart.addEventListener("mouseleave", function() {
        clearActive();
    });

    var legendItems = legend.querySelectorAll(".legend-item");

    for (var i = 0; i < legendItems.length; i++) {
        legendItems[i].addEventListener("mouseenter", function() {
            var index = Number(this.getAttribute("data-index"));
            var slice = slices[index];

            if (!slice) {
                return;
            }

            var fakeEvent = {
                clientX: chart.getBoundingClientRect().left + chart.offsetWidth / 2,
                clientY: chart.getBoundingClientRect().top + chart.offsetHeight / 2
            };

            activateSlice(slice, fakeEvent);
        });

        legendItems[i].addEventListener("mouseleave", function() {
            clearActive();
        });
    }
}

function vctToggleAccordion(button) {
    var item = button.closest(".vct-accordion-item");

    if (!item) {
        return false;
    }

    item.classList.toggle("active");

    return false;
}

function vctToggleRowDetail(rowId, trigger) {
    var detailRow = document.getElementById("vctDetail_" + rowId);

    if (!detailRow) {
        return false;
    }

    var isOpen = detailRow.style.display === "table-row";

    detailRow.style.display = isOpen ? "none" : "table-row";

    if (trigger) {
        var icon = trigger.querySelector("i");

        if (icon) {
            icon.className = isOpen ? "fas fa-plus-circle" : "fas fa-minus-circle";
        }

        if (trigger.classList) {
            if (isOpen) {
                trigger.classList.remove("active");
            } else {
                trigger.classList.add("active");
            }
        }
    }

    return false;
}

function vocDashboardBuscar(formId, homeGuid, pageSize) {
    var input = document.getElementById("buscaCaso");
    var value = input ? String(input.value || "") : "";

    if (typeof almacenarSeleccion === "function") {
        almacenarSeleccion("FILTRO", value);
        almacenarSeleccion("NRO_PAGINA", "0");
        almacenarSeleccion("BUFFER", String(pageSize || "25"));
    }

    window.setTimeout(function() {
        if (typeof goto === "function") {
            goto(formId, homeGuid);
        }
    }, 350);

    return false;
}

function vocDashboardBuscarPlanificacion(formId, homeGuid, pageSize) {
    var desde = document.getElementById("fechaDesdePlanif");
    var hasta = document.getElementById("fechaHastaPlanif");

    var desdeValue = desde ? String(desde.value || "") : "";
    var hastaValue = hasta ? String(hasta.value || "") : "";

    if (typeof almacenarSeleccion === "function") {
        almacenarSeleccion("FECHA_DESDE", desdeValue);
        almacenarSeleccion("FECHA_HASTA", hastaValue);
        almacenarSeleccion("NRO_PAGINA", "0");
        almacenarSeleccion("BUFFER", String(pageSize || "25"));
    }

    window.setTimeout(function() {
        if (typeof goto === "function") {
            goto(formId, homeGuid);
        }
    }, 350);

    return false;
}

function vocDashboardLimpiarPlanificacion(formId, homeGuid, pageSize) {
    var desde = document.getElementById("fechaDesdePlanif");
    var hasta = document.getElementById("fechaHastaPlanif");

    if (desde) {
        desde.value = "";
    }

    if (hasta) {
        hasta.value = "";
    }

    if (typeof almacenarSeleccion === "function") {
        almacenarSeleccion("FECHA_DESDE", "");
        almacenarSeleccion("FECHA_HASTA", "");
        almacenarSeleccion("NRO_PAGINA", "0");
        almacenarSeleccion("BUFFER", String(pageSize || "25"));
    }

    window.setTimeout(function() {
        if (typeof goto === "function") {
            goto(formId, homeGuid);
        }
    }, 350);

    return false;
}