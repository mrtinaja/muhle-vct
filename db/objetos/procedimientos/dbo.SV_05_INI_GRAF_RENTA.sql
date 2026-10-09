 
CREATE PROCEDURE [dbo].[SV_05_INI_GRAF_RENTA]
(
    @IPKEYJOB AS VARCHAR(100),
    @FORM_ID  AS VARCHAR(100),
    @IUNIDAD  AS VARCHAR(100),
    @IAGENTE  AS VARCHAR(100),
    @OHEADER  AS VARCHAR(MAX) OUTPUT,
    @OGRAFICO AS VARCHAR(MAX) OUTPUT,
    @OGRAFICO1 AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @VFECHA_DESDE DATETIME,
        @VFECHA_HASTA DATETIME,
        @VCLIENTE     VARCHAR(50),
        @VPERIODO     VARCHAR(50),
        @VESTADO      VARCHAR(50),
        @VTOTAL_PROYECTOS INT = 0,
        @VHTML_CARDS  VARCHAR(MAX) = '';
 
    -----------------------------------------------------------------------------------------
    -- 1. RECUPERAR FILTROS DESDE TMT_SV_05
    -----------------------------------------------------------------------------------------
    SELECT
        @VFECHA_DESDE = FECHA_DESDE,
        @VFECHA_HASTA = FECHA_HASTA,
        @VCLIENTE     = ISNULL(CLIENTE, ''),
        @VPERIODO     = ISNULL(PERIODO, ''),
        @VESTADO      = ISNULL(ESTADO, '')
    FROM TMT_SV_05 WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    -----------------------------------------------------------------------------------------
    -- 2. HEADER BARRA PRINCIPAL
    -----------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------
    -- 2. HEADER BARRA PRINCIPAL (TITULO A LA IZQUIERDA, BOTONES A LA DERECHA)
    -----------------------------------------------------------------------------------------
    SET @OHEADER = '
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
 
    <div class="w3-row vct-export-ignore" id="vctHeaderModule" style="padding:16px 0px 8px 0px;box-sizing:border-box;width:100%;">
        <div class="w3-col" style="width:100%;">
            <div class="w3-card-4 w3-round">
                <div class="w3-bar w3-muhle-vocaturo w3-round w3-padding" style="display:flex !important;align-items:center !important;width:100% !important;box-sizing:border-box;">
                    
                    <!-- TITULO EXPLICITAMENTE A LA IZQUIERDA -->
                    <div style="display:flex;align-items:center;margin-right:auto;">
                        <span class="w3-muhle-text-14" style="color:white;font-weight:600;display:inline-flex;align-items:center;gap:8px;">
                            <i class="fas fa-chart-pie fa-fw w3-large"></i> Grafico Rentabilidad Proyectos
                        </span>
                    </div>
 
                    <!-- ACCIONES EXPLICITAMENTE A LA DERECHA -->
                    <div style="display:flex;gap:10px;align-items:center;margin-left:auto;">
                        
                        <!-- BOTÓN IMPRIMIR / PDF COMPLETO -->
                        <button type="button" class="w3-button w3-round w3-white w3-text-dark-gray vct-export-ignore" onclick="vctExportarPDFGlobal();return false;" title="Exportar Todo a PDF" style="font-weight:600;font-size:12px;padding:5px 12px;border:none;cursor:pointer;display:inline-flex;align-items:center;gap:6px;">
                            <i class="fas fa-file-pdf" style="color:#dc2626;font-size:14px;"></i>
                        </button>
 
                        <!-- BOTÓN VOLVER -->
                        <span style="color:white;padding:0;display:inline-flex;align-items:center;">
                            <i class="fas fa-arrow-alt-circle-left w3-large" style="cursor:pointer;color:white;" title="Volver a la Grilla" onclick="goto('''+@FORM_ID+''',''361AE370-6363-45EF-A972-989A27FF2A87'');return false;"></i>
                        </span>
 
                    </div>
                </div>
            </div>
        </div>
    </div>';
 
 -----------------------------------------------------------------------------------------
    -- 3. CURSOR Y CONSTRUCCIÓN DE CARDS INDIVIDUALES DENTRO DE PANEL CONTENEDOR
    -----------------------------------------------------------------------------------------
    DECLARE
        @PROY_ID                INT,
        @PROY_CODIGO            VARCHAR(100),
        @PROY_NORMA             NVARCHAR(500),
        @CLIENTE_NOMBRE         NVARCHAR(300),
        @MONTO_TOTAL            DECIMAL(18,2),
        @COSTO_TOTAL            DECIMAL(18,2),
        @UTILIDAD_ESTIMADA      DECIMAL(18,2),
        @MARGEN_ESTIMADO        DECIMAL(18,2),
        @VENTAS_REALES          DECIMAL(18,2),
        @COMPRAS_REALES         DECIMAL(18,2),
        @UTILIDAD_REAL          DECIMAL(18,2),
        @MARGEN_REAL            DECIMAL(18,2),
        @DESVIACION_MARGEN      DECIMAL(18,2),
        @ULTIMO_PERIODO         VARCHAR(50),
        @TIENE_RENTABILIDAD_REAL BIT,
        @CARD_INDEX             INT = 0;
 
    DECLARE CUR_RENTA CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        P.ID_PROYECTO,
        CONVERT(VARCHAR, P.CODIGO) AS CODIGO,
        ISNULL(P.NORMA_REF, 'Sin descripción') AS NORMA_REF,
        ISNULL(C.RAZON_SOCIAL_CLIENTE, 'Cliente sin especificar') AS CLIENTE,
        ISNULL(P.MONTO_TOTAL, 0) AS MONTO_TOTAL,
        ISNULL(P.COSTO_TOTAL, 0) AS COSTO_TOTAL,
        (ISNULL(P.MONTO_TOTAL, 0) - ISNULL(P.COSTO_TOTAL, 0)) AS UTILIDAD_ESTIMADA,
        CASE
            WHEN ISNULL(P.MONTO_TOTAL, 0) > 0
            THEN CAST(((ISNULL(P.MONTO_TOTAL, 0) - ISNULL(P.COSTO_TOTAL, 0)) * 100.0) / P.MONTO_TOTAL AS DECIMAL(18,2))
            ELSE 0.00
        END AS MARGEN_ESTIMADO,
        ISNULL(R.TotalVentasReales, 0) AS VENTAS_REALES,
        ISNULL(R.TotalComprasReales, 0) AS COMPRAS_REALES,
        (ISNULL(R.TotalVentasReales, 0) - ISNULL(R.TotalComprasReales, 0)) AS UTILIDAD_REAL,
        CASE
            WHEN ISNULL(R.TotalVentasReales, 0) > 0
            THEN CAST(((ISNULL(R.TotalVentasReales, 0) - ISNULL(R.TotalComprasReales, 0)) * 100.0) / R.TotalVentasReales AS DECIMAL(18,2))
            ELSE 0.00
        END AS MARGEN_REAL,
        CASE
            WHEN ISNULL(R.TotalVentasReales, 0) > 0 AND ISNULL(P.MONTO_TOTAL, 0) > 0
            THEN CAST((((ISNULL(R.TotalVentasReales, 0) - ISNULL(R.TotalComprasReales, 0)) * 100.0) / R.TotalVentasReales) - (((ISNULL(P.MONTO_TOTAL, 0) - ISNULL(P.COSTO_TOTAL, 0)) * 100.0) / P.MONTO_TOTAL) AS DECIMAL(18,2))
            ELSE 0.00
        END AS DESVIACION_MARGEN,
        ISNULL(R.UltimoPeriodo, '-') AS ULTIMO_PERIODO,
        CASE WHEN R.ID_PROYECTO IS NOT NULL AND ISNULL(R.TotalVentasReales, 0) > 0 THEN 1 ELSE 0 END AS TIENE_RENTABILIDAD_REAL
    FROM LK_PROYECTO P WITH (NOLOCK)
    INNER JOIN LK_CLIENTES C WITH (NOLOCK) ON P.ID_CLIENTE = C.ID_CLIENTE
    LEFT JOIN
    (
        SELECT
            PR.ID_PROYECTO,
            SUM(ISNULL(PR.VENTAS, 0)) AS TotalVentasReales,
            SUM(ISNULL(PR.COMPRAS, 0)) AS TotalComprasReales,
            MAX(PR.PERIODO) AS UltimoPeriodo
        FROM LK_PROYECTO_RENTABILIDAD PR WITH (NOLOCK)
        WHERE (@VPERIODO = '' OR PR.PERIODO <= @VPERIODO)
        GROUP BY PR.ID_PROYECTO
    ) R ON P.ID_PROYECTO = R.ID_PROYECTO
    WHERE 1 = 1
      AND (@VCLIENTE = '' OR P.ID_CLIENTE = @VCLIENTE)
      AND (@VESTADO = '' OR P.ESTADO_PROYECTO_TOTAL = @VESTADO)
      AND (@VPERIODO = '' OR R.ID_PROYECTO IS NOT NULL)
    ORDER BY C.RAZON_SOCIAL_CLIENTE, P.CODIGO;
 
    OPEN CUR_RENTA;
    FETCH NEXT FROM CUR_RENTA INTO
        @PROY_ID, @PROY_CODIGO, @PROY_NORMA, @CLIENTE_NOMBRE,
        @MONTO_TOTAL, @COSTO_TOTAL, @UTILIDAD_ESTIMADA, @MARGEN_ESTIMADO,
        @VENTAS_REALES, @COMPRAS_REALES, @UTILIDAD_REAL, @MARGEN_REAL,
        @DESVIACION_MARGEN, @ULTIMO_PERIODO, @TIENE_RENTABILIDAD_REAL;
 
    -- CONTENEDOR BLANCO UNIFICADO QUE ENCAPSULA A TODAS LAS TARJETAS
    SET @VHTML_CARDS = '
    <div style="padding:0px 0px 16px 0px;box-sizing:border-box;width:100%;">
        <div class="w3-card-4 w3-round w3-white" style="padding:20px;border:1px solid #e2e8f0;box-sizing:border-box;">
            <div id="vctRentaDashboardContainer" style="display:grid;grid-template-columns:repeat(auto-fill, minmax(320px, 1fr));gap:16px;width:100%;box-sizing:border-box;">';
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CARD_INDEX = @CARD_INDEX + 1;
        SET @VTOTAL_PROYECTOS = @VTOTAL_PROYECTOS + 1;
 
        DECLARE @CANVAS_ID VARCHAR(50) = 'chartRenta_' + CAST(@CARD_INDEX AS VARCHAR);
        DECLARE @CARD_ID VARCHAR(50)   = 'cardRenta_' + CAST(@CARD_INDEX AS VARCHAR);
        DECLARE @DESVIACION_COLOR VARCHAR(20) = CASE WHEN @DESVIACION_MARGEN >= 0 THEN '#059669' ELSE '#dc2626' END;
        DECLARE @DESVIACION_TXT VARCHAR(30) = CASE WHEN @DESVIACION_MARGEN >= 0 THEN '+' + FORMAT(@DESVIACION_MARGEN, 'N2') ELSE FORMAT(@DESVIACION_MARGEN, 'N2') END;
 
        SET @VHTML_CARDS = @VHTML_CARDS + '
        <div id="' + @CARD_ID + '" class="vct-renta-card" style="background:#ffffff;border-radius:10px;border:1px solid #e2e8f0;box-shadow:0 1px 4px rgba(0,0,0,0.04);padding:14px;display:flex;flex-direction:column;justify-content:space-between;box-sizing:border-box;position:relative;page-break-inside:avoid;break-inside:avoid;">
            
            <!-- HEADER DE TARJETA -->
            <div style="border-bottom:1px solid #f1f5f9;padding-bottom:8px;margin-bottom:8px;display:flex;justify-content:space-between;align-items:flex-start;">
                <div>
                    <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:#64748b;letter-spacing:0.5px;margin-bottom:2px;" class="vct-txt-cliente">
                        ' + REPLACE(REPLACE(@CLIENTE_NOMBRE, '<', '&lt;'), '>', '&gt;') + '
                    </div>
                    <div style="font-size:12px;font-weight:700;color:#1e293b;line-height:1.2;" class="vct-txt-titulo">
                        (' + ISNULL(@PROY_CODIGO, '') + ') - ' + REPLACE(REPLACE(@PROY_NORMA, '<', '&lt;'), '>', '&gt;') + '
                    </div>
                </div>
 
                <!-- ACCIONES INDIVIDUALES -->
                <div style="display:flex;gap:4px;" class="vct-export-ignore">
                    <button type="button" onclick="vctExportarPDFTarjeta(''' + @CARD_ID + ''');return false;" title="Exportar esta tarjeta a PDF" style="background:#f1f5f9;border:1px solid #cbd5e1;color:#dc2626;border-radius:4px;width:24px;height:24px;display:flex;align-items:center;justify-content:center;cursor:pointer;flex-shrink:0;">
                        <i class="fas fa-file-pdf" style="font-size:11px;"></i>
                    </button>
                </div>
            </div>
 
            <!-- CUERPO PRINCIPAL -->
            <div style="display:flex;gap:10px;align-items:center;">
                <div style="flex:1;">
                    <div style="margin-bottom:6px;">
                        <span style="font-size:10px;color:#64748b;display:block;" class="vct-lbl">Margen Estimado:</span>
                        <span style="font-size:15px;font-weight:700;color:#d97706;" class="vct-val-est">' + FORMAT(@MARGEN_ESTIMADO, 'N2') + '%</span>
                    </div>
 
                    <div style="margin-bottom:6px;">
                        <span style="font-size:10px;color:#64748b;display:block;" class="vct-lbl">Margen Real Acum.:</span>';
 
        IF @TIENE_RENTABILIDAD_REAL = 1
        BEGIN
            SET @VHTML_CARDS = @VHTML_CARDS + '
                        <span style="font-size:15px;font-weight:700;color:#059669;" class="vct-val-real">' + FORMAT(@MARGEN_REAL, 'N2') + '%</span>';
        END
        ELSE
        BEGIN
            SET @VHTML_CARDS = @VHTML_CARDS + '
                        <span style="font-size:11px;font-weight:600;color:#94a3b8;background:#f1f5f9;padding:1px 6px;border-radius:3px;display:inline-block;margin-top:1px;">Sin datos asociados</span>';
        END
 
        SET @VHTML_CARDS = @VHTML_CARDS + '
                    </div>
 
                    <div>
                        <span style="font-size:10px;color:#64748b;display:block;" class="vct-lbl">Desviación:</span>
                        <span style="font-size:12px;font-weight:700;color:' + @DESVIACION_COLOR + ';" class="vct-val-desv">' + @DESVIACION_TXT + '%</span>
                    </div>
                </div>
 
                <div style="width:130px;height:95px;position:relative;display:flex;align-items:center;justify-content:center;" class="vct-canvas-container">
                    <canvas id="' + @CANVAS_ID + '" width="130" height="95"
                        data-vct-chart="bar"
                        data-estimado="' + CAST(@MARGEN_ESTIMADO AS VARCHAR) + '"
                        data-real="' + CAST(@MARGEN_REAL AS VARCHAR) + '"></canvas>
                </div>
            </div>
 
            <!-- FOOTER DE TARJETA -->
            <div style="margin-top:10px;padding-top:8px;border-top:1px solid #f8fafc;display:flex;flex-direction:column;gap:4px;font-size:10px;color:#475569;" class="vct-card-footer">
                <div style="display:flex;justify-content:space-between;align-items:center;">
                    <span><strong>Presupuesto:</strong></span>
                    <span>' + FORMAT(@MONTO_TOTAL, 'C', 'es-AR') + '</span>
                </div>
                <div style="display:flex;justify-content:space-between;align-items:center;">
                    <span><strong>Costo Estimado:</strong></span>
                    <span>' + FORMAT(@COSTO_TOTAL, 'C', 'es-AR') + '</span>
                </div>
                <div style="display:flex;justify-content:space-between;align-items:center;">
                    <span><strong>Ventas Acumuladas:</strong></span>
                    <span>' + FORMAT(@VENTAS_REALES, 'C', 'es-AR') + '</span>
                </div>
                <div style="display:flex;justify-content:space-between;align-items:center;">
                    <span><strong>Compras Acumuladas:</strong></span>
                    <span>' + FORMAT(@COMPRAS_REALES, 'C', 'es-AR') + '</span>
                </div>
            </div>
 
            <div style="margin-top:6px;font-size:9.5px;color:#94a3b8;text-align:right;">
                Ultimo Período: <strong>' + @ULTIMO_PERIODO + '</strong>
            </div>
 
        </div>';
 
        FETCH NEXT FROM CUR_RENTA INTO
            @PROY_ID, @PROY_CODIGO, @PROY_NORMA, @CLIENTE_NOMBRE,
            @MONTO_TOTAL, @COSTO_TOTAL, @UTILIDAD_ESTIMADA, @MARGEN_ESTIMADO,
            @VENTAS_REALES, @COMPRAS_REALES, @UTILIDAD_REAL, @MARGEN_REAL,
            @DESVIACION_MARGEN, @ULTIMO_PERIODO, @TIENE_RENTABILIDAD_REAL;
    END;
 
    CLOSE CUR_RENTA;
    DEALLOCATE CUR_RENTA;
 
    SET @VHTML_CARDS = @VHTML_CARDS + '
            </div>
        </div>
    </div>';
 
    -----------------------------------------------------------------------------------------
    -- 4. MENSAJE EN CASO DE NO HABER REGISTROS
    -----------------------------------------------------------------------------------------
    IF @VTOTAL_PROYECTOS = 0
    BEGIN
        SET @VHTML_CARDS = '
        <div style="background:#ffffff;border-radius:12px;border:1px solid #e2e8f0;padding:40px;text-align:center;color:#64748b;margin:20px;">
            <i class="fas fa-folder-open" style="font-size:36px;color:#cbd5e1;margin-bottom:10px;display:block;"></i>
            <h3 style="margin:0;font-size:16px;color:#1e293b;">No se encontraron proyectos</h3>
            <p style="margin:5px 0 0 0;font-size:13px;">No existen proyectos registrados que coincidan con los filtros seleccionados.</p>
        </div>';
    END
 
    -----------------------------------------------------------------------------------------
    -- 5. SCRIPT DE RENDERIZADO Y EXPORTACIÓN
    -----------------------------------------------------------------------------------------
    SET @OGRAFICO = @VHTML_CARDS;
 
    SET @OGRAFICO1 = '
    <script type="text/javascript">
    (function(){
 
        function renderVctRentaCharts(){
            if(typeof window.Chart !== "function"){
                setTimeout(renderVctRentaCharts, 100);
                return;
            }
 
            var canvases = document.querySelectorAll("canvas[data-vct-chart=''bar'']");
            canvases.forEach(function(canvas){
                if(canvas.chartInstance){ return; }
 
                var est = parseFloat(canvas.dataset.estimado || "0");
                var real = parseFloat(canvas.dataset.real || "0");
 
                var colorEst = "#d97706";
                var colorReal = real >= 0 ? "#059669" : "#dc2626";
 
                canvas.chartInstance = new window.Chart(canvas, {
                    type: "bar",
                    data: {
                        labels: ["Estimado", "Real"],
                        datasets: [{
                            data: [est, real],
                            backgroundColor: [colorEst, colorReal],
                            borderRadius: 3,
                            barThickness: 18
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        animation: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            x: { grid: { display: false }, ticks: { font: { size: 9, weight: "bold" }, color: "#64748b" } },
                            y: { grid: { color: "#f1f5f9" }, ticks: { font: { size: 8 }, color: "#94a3b8", callback: function(v){ return v + "%"; } } }
                        }
                    }
                });
            });
        }
 
        function getCleanExportClone(elem){
            var clone = elem.cloneNode(true);
            var origCanvases = elem.querySelectorAll("canvas");
            var cloneCanvases = clone.querySelectorAll("canvas");
 
            origCanvases.forEach(function(canv, i){
                try {
                    var img = document.createElement("img");
                    img.src = canv.toDataURL("image/png");
                    img.style.width = "100%";
                    img.style.height = "auto";
                    img.style.display = "block";
                    if(cloneCanvases[i] && cloneCanvases[i].parentNode){
                        cloneCanvases[i].parentNode.replaceChild(img, cloneCanvases[i]);
                    }
                } catch(e){}
            });
            return clone;
        }
 
        function openCleanPrintWindow(cloneNode, isGlobal){
            var iframe = document.createElement("iframe");
            iframe.style.position = "fixed";
            iframe.style.right = "0";
            iframe.style.bottom = "0";
            iframe.style.width = "0";
            iframe.style.height = "0";
            iframe.style.border = "0";
            document.body.appendChild(iframe);
 
            var totalCards = cloneNode.querySelectorAll(".vct-renta-card").length;
 
            var doc = iframe.contentWindow.document;
            doc.open();
            doc.write("<!DOCTYPE html><html><head><title>Reporte_Rentabilidad</title>");
            doc.write("<style>");
            doc.write("@page { size: A4 " + (isGlobal ? "landscape" : "portrait") + "; margin: " + (isGlobal ? "6mm 8mm" : "15mm 20mm") + "; }");
            doc.write("body { font-family: system-ui, -apple-system, sans-serif; background: #fff; margin: 0; padding: 0; }");
            doc.write(".vct-export-ignore { display: none !important; }");
            
            if(isGlobal){
                if(totalCards <= 2){
                    doc.write("#vctRentaDashboardContainer { display: grid !important; grid-template-columns: repeat(" + totalCards + ", 1fr) !important; gap: 20px !important; width: 100% !important; padding: 10px 0 !important; }");
                    doc.write(".vct-renta-card { border: 1.5px solid #cbd5e1 !important; padding: 20px !important; border-radius: 12px !important; background: #fff !important; box-sizing: border-box !important; page-break-inside: avoid !important; break-inside: avoid !important; }");
                    doc.write(".vct-txt-cliente { font-size: 12px !important; }");
                    doc.write(".vct-txt-titulo { font-size: 16px !important; }");
                    doc.write(".vct-lbl { font-size: 11px !important; }");
                    doc.write(".vct-val-est, .vct-val-real { font-size: 22px !important; }");
                    doc.write(".vct-canvas-container { width: 190px !important; height: 140px !important; }");
                    doc.write(".vct-card-footer { font-size: 12px !important; gap: 6px !important; margin-top: 15px !important; }");
                } 
                else if(totalCards === 3){
                    doc.write("#vctRentaDashboardContainer { display: grid !important; grid-template-columns: repeat(3, 1fr) !important; gap: 14px !important; width: 100% !important; padding: 10px 0 !important; }");
                    doc.write(".vct-renta-card { border: 1.5px solid #cbd5e1 !important; padding: 16px !important; border-radius: 10px !important; background: #fff !important; box-sizing: border-box !important; page-break-inside: avoid !important; break-inside: avoid !important; }");
                    doc.write(".vct-txt-cliente { font-size: 11px !important; }");
                    doc.write(".vct-txt-titulo { font-size: 14px !important; }");
                    doc.write(".vct-val-est, .vct-val-real { font-size: 18px !important; }");
                    doc.write(".vct-canvas-container { width: 160px !important; height: 120px !important; }");
                    doc.write(".vct-card-footer { font-size: 11px !important; gap: 5px !important; margin-top: 12px !important; }");
                } 
                else if(totalCards === 4){
                    doc.write("#vctRentaDashboardContainer { display: grid !important; grid-template-columns: repeat(2, 1fr) !important; gap: 14px 18px !important; width: 100% !important; padding: 0 !important; }");
                    doc.write(".vct-renta-card { border: 1.5px solid #cbd5e1 !important; padding: 16px 18px !important; border-radius: 10px !important; background: #fff !important; box-sizing: border-box !important; page-break-inside: avoid !important; break-inside: avoid !important; }");
                    doc.write(".vct-txt-cliente { font-size: 11px !important; }");
                    doc.write(".vct-txt-titulo { font-size: 14px !important; }");
                    doc.write(".vct-lbl { font-size: 11px !important; }");
                    doc.write(".vct-val-est, .vct-val-real { font-size: 19px !important; }");
                    doc.write(".vct-canvas-container { width: 170px !important; height: 125px !important; }");
                    doc.write(".vct-card-footer { font-size: 11px !important; gap: 6px !important; margin-top: 12px !important; }");
                } 
                else {
                    doc.write("#vctRentaDashboardContainer { display: grid !important; grid-template-columns: repeat(3, 1fr) !important; grid-auto-rows: minmax(250px, auto) !important; gap: 8px 10px !important; width: 100% !important; padding: 0 !important; }");
                    doc.write(".vct-renta-card { border: 1px solid #cbd5e1 !important; padding: 8px 10px !important; border-radius: 8px !important; background: #fff !important; box-sizing: border-box !important; page-break-inside: avoid !important; break-inside: avoid !important; height: 100% !important; }");
                }
            } else {
                doc.write(".vct-renta-card { border: 2px solid #cbd5e1 !important; padding: 28px !important; border-radius: 16px !important; background: #fff !important; width: 100% !important; max-width: 680px !important; margin: 20px auto !important; box-sizing: border-box !important; box-shadow: none !important; }");
                doc.write(".vct-txt-cliente { font-size: 13px !important; margin-bottom: 4px !important; }");
                doc.write(".vct-txt-titulo { font-size: 18px !important; }");
                doc.write(".vct-lbl { font-size: 12px !important; }");
                doc.write(".vct-val-est { font-size: 24px !important; }");
                doc.write(".vct-val-real { font-size: 24px !important; }");
                doc.write(".vct-val-desv { font-size: 16px !important; }");
                doc.write(".vct-canvas-container { width: 240px !important; height: 180px !important; }");
                doc.write(".vct-card-footer { font-size: 13px !important; gap: 8px !important; margin-top: 20px !important; padding-top: 15px !important; }");
            }
 
            doc.write("</style></head><body>");
            doc.write(cloneNode.outerHTML);
            doc.write("</body></html>");
            doc.close();
 
            setTimeout(function(){
                iframe.contentWindow.focus();
                iframe.contentWindow.print();
                setTimeout(function(){ document.body.removeChild(iframe); }, 1500);
            }, 300);
        }
 
        window.vctExportarPDFGlobal = function(){
            var elem = document.getElementById("vctRentaDashboardContainer");
            if(!elem){ return; }
            var clone = getCleanExportClone(elem);
            openCleanPrintWindow(clone, true);
        };
 
        window.vctExportarPDFTarjeta = function(cardId){
            var elem = document.getElementById(cardId);
            if(!elem){ return; }
            var clone = getCleanExportClone(elem);
            openCleanPrintWindow(clone, false);
        };
 
        if(document.readyState === "loading"){
            document.addEventListener("DOMContentLoaded", renderVctRentaCharts);
        } else {
            renderVctRentaCharts();
        }
    })();
    </script>';
 
END
