/**
 * Portal Vocaturo - Dashboard Core Engine (Optimizado para Espaciado)
 * Integración Profesional con Chart.js 4.x
 * Fecha de Actualización: 10/07/2026
 */

(function (window, document) {
    "use strict";

    var vocCharts = {};

    var VOC_PALETTE = {
        primary: "#66062D",
        mediumBordo: "#8D3157",
        lightBordo: "#B05A7C",
        dark: "#333233",
        mediumGray: "#6E6D6E",
        lightGray: "#A5A3A5",
        warning: "#D99A19",
        success: "#2E7D5B",
        error: "#C84B4B",
        auxBlue: "#4977A8"
    };

    var COLOR_SEQUENCE = [
        VOC_PALETTE.primary,
        VOC_PALETTE.auxBlue,
        VOC_PALETTE.success,
        VOC_PALETTE.warning,
        VOC_PALETTE.mediumBordo,
        VOC_PALETTE.lightBordo,
        VOC_PALETTE.mediumGray,
        VOC_PALETTE.dark
    ];

    function vocEscapeHtml(value) {
        if (value === null || value === undefined) return "";
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function vocFormatNumber(num) {
        return Number(num || 0).toLocaleString("es-AR");
    }

    function vocNormalizeChartData(data) {
        if (!data || !Array.isArray(data)) return [];
        var total = data.reduce(function (acc, item) { return acc + Number(item.value || 0); }, 0);
        
        return data.map(function (item, index) {
            var val = Number(item.value || 0);
            return {
                label: item.label || "Sin especificar",
                value: val,
                percent: total > 0 ? (val / total) * 100 : 0,
                color: COLOR_SEQUENCE[index % COLOR_SEQUENCE.length]
            };
        });
    }

    function vocDestroyChart(chartId) {
        if (vocCharts[chartId]) {
            vocCharts[chartId].destroy();
            delete vocCharts[chartId];
        }
        if (window.Chart) {
            var existingChart = window.Chart.getChart(chartId);
            if (existingChart) existingChart.destroy();
        }
    }

    function vocRenderEmptyState(containerId, legendId) {
        var container = document.getElementById(containerId);
        var legend = document.getElementById(legendId);
        if (legend) legend.innerHTML = "";
        if (container) {
            var wrap = container.closest(".vct-chart-layout");
            if (wrap) {
                wrap.innerHTML = '<div class="vct-chart-empty"><i class="fas fa-chart-pie"></i><span>Sin datos para mostrar</span></div>';
            }
        }
    }

    // Plugin con cálculo matemático exacto del centro del arco del Doughnut
    var vocCenterTextPlugin = {
        id: "vocCenterText",
        afterDraw: function (chart) {
            if (chart.config.type !== "doughnut") return;
            
            var centerConfig = chart.config.options.plugins.vocCenterText;
            if (!centerConfig) return;

            var meta = chart.getDatasetMeta(0);
            if (!meta || !meta.data || !meta.data[0]) return;

            // Centro geométrico real calculado por Chart.js
            var centerX = meta.data[0].x;
            var centerY = meta.data[0].y;
            var ctx = chart.ctx;

            var total = chart.data.datasets[0].data.reduce(function (acc, val, i) {
                return acc + (meta.data[i] && !meta.data[i].hidden ? val : 0);
            }, 0);

            ctx.save();
            
            // Número Principal
            ctx.font = "bold 24px \"Gotham\", \"Montserrat\", \"Inter\", Arial, sans-serif";
            ctx.textBaseline = "middle";
            ctx.textAlign = "center";
            ctx.fillStyle = VOC_PALETTE.dark;
            ctx.fillText(vocFormatNumber(total), centerX, centerY - 8);

            // Subetiqueta Inferior
            ctx.font = "600 10px \"Gotham\", \"Montserrat\", \"Inter\", Arial, sans-serif";
            ctx.fillStyle = VOC_PALETTE.mediumGray;
            ctx.fillText(String(centerConfig.centerLabel || "").toUpperCase(), centerX, centerY + 14);

            ctx.restore();
        }
    };

    if (window.Chart && typeof window.Chart.register === "function") {
        window.Chart.register(vocCenterTextPlugin);
    }

    function vocBuildChartLegend(chartInstance, legendId, normalizedData) {
        var legendContainer = document.getElementById(legendId);
        if (!legendContainer) return;

        var html = '<ul class="vct-chart-legend-list">';
        normalizedData.forEach(function (item, index) {
            html += '<li class="vct-chart-legend-item" data-index="' + index + '">' +
                        '<span class="vct-chart-legend-color" style="background-color:' + item.color + '"></span>' +
                        '<div class="vct-chart-legend-copy">' +
                            '<span class="vct-chart-legend-label">' + vocEscapeHtml(item.label) + '</span>' +
                            '<span class="vct-chart-legend-meta"><strong>' + vocFormatNumber(item.value) + '</strong> &nbsp;&middot;&nbsp; ' + item.percent.toFixed(1) + '%</span>' +
                        '</div>' +
                    '</li>';
        });
        html += '</ul>';
        legendContainer.innerHTML = html;

        var items = legendContainer.querySelectorAll(".vct-chart-legend-item");
        items.forEach(function (el) {
            var idx = parseInt(el.getAttribute("data-index"), 10);

            el.addEventListener("click", function () {
                var meta = chartInstance.getDatasetMeta(0);
                var itemData = meta.data[idx];
                if (itemData) {
                    itemData.hidden = !itemData.hidden;
                    this.classList.toggle("is-muted", itemData.hidden);
                    chartInstance.update();
                }
            });

            el.addEventListener("mouseenter", function () {
                chartInstance.setActiveElements([{ datasetIndex: 0, index: idx }]);
                chartInstance.update();
            });

            el.addEventListener("mouseleave", function () {
                chartInstance.setActiveElements([]);
                chartInstance.update();
            });
        });
    }

    window.vocRenderDoughnut = function (canvasId, legendId, rawData, options) {
        vocDestroyChart(canvasId);
        var cleanData = vocNormalizeChartData(rawData);
        
        var total = cleanData.reduce(function (a, b) { return a + b.value; }, 0);
        if (total === 0) {
            vocRenderEmptyState(canvasId, legendId);
            return;
        }

        var ctx = document.getElementById(canvasId);
        if (!ctx) return;

        var config = {
            type: "doughnut",
            data: {
                labels: cleanData.map(function (d) { return d.label; }),
                datasets: [{
                    data: cleanData.map(function (d) { return d.value; }),
                    backgroundColor: cleanData.map(function (d) { return d.color; }),
                    borderColor: "#FFFFFF",
                    borderWidth: 2,
                    hoverOffset: 6,
                    spacing: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: "75%",
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: VOC_PALETTE.dark,
                        titleColor: "#FFFFFF",
                        bodyColor: "#FFFFFF",
                        cornerRadius: 8,
                        padding: 10,
                        callbacks: {
                            label: function (context) {
                                var val = context.raw;
                                var pct = cleanData[context.dataIndex].percent.toFixed(1);
                                return " " + vocFormatNumber(val) + " · " + pct + "%";
                            }
                        }
                    },
                    vocCenterText: {
                        centerLabel: (options && options.centerLabel) || "Items"
                    }
                },
                animation: {
                    duration: 500,
                    easing: "easeOutQuart"
                }
            }
        };

        var chart = new Chart(ctx, config);
        vocCharts[canvasId] = chart;
        vocBuildChartLegend(chart, legendId, cleanData);
    };

    window.vocRenderHorizontalBar = function (canvasId, legendId, rawData, options) {
        vocDestroyChart(canvasId);
        var cleanData = vocNormalizeChartData(rawData);
        cleanData.sort(function (a, b) { return b.value - a.value; });

        var total = cleanData.reduce(function (a, b) { return a + b.value; }, 0);
        if (total === 0) {
            vocRenderEmptyState(canvasId, legendId);
            return;
        }

        var ctx = document.getElementById(canvasId);
        if (!ctx) return;

        var config = {
            type: "bar",
            data: {
                labels: cleanData.map(function (d) { return d.label; }),
                datasets: [{
                    label: (options && options.datasetLabel) || "Cantidad",
                    data: cleanData.map(function (d) { return d.value; }),
                    backgroundColor: cleanData.map(function (d) { return d.color; }),
                    borderRadius: 6,
                    borderSkipped: false,
                    barThickness: 16,
                    maxBarThickness: 20
                }]
            },
            options: {
                indexAxis: "y",
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: VOC_PALETTE.dark,
                        cornerRadius: 8,
                        padding: 10
                    }
                },
                scales: {
                    x: {
                        beginAtZero: true,
                        ticks: {
                            color: VOC_PALETTE.dark,
                            font: { family: '"Gotham", "Montserrat", sans-serif', size: 10 }
                        },
                        grid: { color: "rgba(51, 50, 51, 0.05)" },
                        border: { display: false }
                    },
                    y: {
                        ticks: {
                            color: VOC_PALETTE.dark,
                            font: { family: '"Gotham", "Montserrat", sans-serif', size: 12, weight: '600' }
                        },
                        grid: { display: false },
                        border: { display: false }
                    }
                }
            }
        };

        var chart = new Chart(ctx, config);
        vocCharts[canvasId] = chart;

        var legendContainer = document.getElementById(legendId);
        if (legendContainer) {
            var legendHtml = '<div class="vct-bar-inline-legend">';
            cleanData.forEach(function(item) {
                legendHtml += '<div class="vct-bar-legend-pill"><span class="vct-chart-legend-color" style="background-color:'+ item.color +'"></span>' + vocEscapeHtml(item.label) + ': <strong>'+ item.value +'</strong></div>';
            });
            legendHtml += '</div>';
            legendContainer.innerHTML = legendHtml;
        }
    };

    window.vocRenderPie = function (canvasId, legendId, rawData) {
        window.vocRenderDoughnut(canvasId, legendId, rawData, { centerLabel: "Total" });
    };

    // Funciones del Accordion y Tabla se mantienen idénticas de forma segura...
    window.vctToggleAccordion = function (button) {
        var item = button.closest(".vct-accordion-item");
        if (!item) return false;
        item.classList.toggle("active");
        return false;
    };

    window.vctToggleRowDetail = function (rowId, trigger) {
        var detailRow = document.getElementById("vctDetail_" + rowId);
        if (!detailRow) return false;
        var isOpen = detailRow.style.display === "table-row";
        detailRow.style.display = isOpen ? "none" : "table-row";
        if (trigger) {
            var icon = trigger.querySelector("i");
            if (icon) icon.className = isOpen ? "fas fa-plus-circle" : "fas fa-minus-circle";
            if (trigger.classList) {
                if (isOpen) trigger.classList.remove("active");
                else trigger.classList.add("active");
            }
        }
        return false;
    };

    window.vocDashboardBuscar = function (formId, homeGuid, pageSize) {
        var input = document.getElementById("buscaCaso");
        var value = input ? String(input.value || "") : "";
        if (typeof almacenarSeleccion === "function") {
            almacenarSeleccion("FILTRO", value);
            almacenarSeleccion("NRO_PAGINA", "0");
            almacenarSeleccion("BUFFER", String(pageSize || "25"));
        }
        window.setTimeout(function () { if (typeof goto === "function") goto(formId, homeGuid); }, 350);
        return false;
    };

    window.vocDashboardBuscarPlanificacion = function (formId, homeGuid, pageSize) {
        var desde = document.getElementById("fechaDesdePlanif");
        var hasta = document.getElementById("fechaHastaPlanif");
        if (typeof almacenarSeleccion === "function") {
            almacenarSeleccion("FECHA_DESDE", desde ? String(desde.value || "") : "");
            almacenarSeleccion("FECHA_HASTA", hasta ? String(hasta.value || "") : "");
            almacenarSeleccion("NRO_PAGINA", "0");
            almacenarSeleccion("BUFFER", String(pageSize || "25"));
        }
        window.setTimeout(function () { if (typeof goto === "function") goto(formId, homeGuid); }, 350);
        return false;
    };

    window.vocDashboardLimpiarPlanificacion = function (formId, homeGuid, pageSize) {
        var desde = document.getElementById("fechaDesdePlanif");
        var hasta = document.getElementById("fechaHastaPlanif");
        if (desde) desde.value = "";
        if (hasta) hasta.value = "";
        if (typeof almacenarSeleccion === "function") {
            almacenarSeleccion("FECHA_DESDE", "");
            almacenarSeleccion("FECHA_HASTA", "");
            almacenarSeleccion("NRO_PAGINA", "0");
            almacenarSeleccion("BUFFER", String(pageSize || "25"));
        }
        window.setTimeout(function () { if (typeof goto === "function") goto(formId, homeGuid); }, 350);
        return false;
    };

})(window, document);