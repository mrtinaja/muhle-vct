/* vct-export.js - v1
   ============================================================================
   Export unificado para MAIN (Excel .xlsx real + PDF real con logo/imagenes).
   Modulo independiente: NO conoce la grilla ni el DOM de la pantalla. Recibe
   una "spec" y genera el archivo.

     VCTExport.excel(spec)   -> Promise  (descarga .xlsx)
     VCTExport.pdf(spec)     -> Promise  (descarga .pdf)
     VCTExport.rasterize(el) -> Promise<string|null>  (elemento -> PNG dataURL)

     spec = {
       title, subtitle, filename,          // filename sin extension (opcional)
       orientation: "portrait|landscape",  // opcional (auto: >6 cols = landscape)
       columns: [{ title, align, width, type }],   // type: "text" fuerza texto
       rows:    [[valor, valor, ...], ...],        // string | number | Date
       logo:    "url" | false,             // default: ../img/LogoBordo.png
       images:  [{ dataUrl, caption }]     // graficos para el PDF (opcional)
     }

   Libs (carga diferida, solo al exportar; ya estan en /lib):
     lib/DataTables/JSZip-2.5.0/jszip.min.js
     lib/DataTables/pdfmake-0.1.36/pdfmake.min.js + vfs_fonts.js
     lib/tableToPdf/ExportPDF.js   (html2pdf bundle, solo para rasterizar HTML)

   Red de seguridad: si una lib no carga, cae al metodo viejo (HTML .xls /
   ventana de impresion) para que el boton nunca quede muerto.
   ============================================================================ */
(function (root, factory) {
    var api = factory(root);
    if (typeof module === "object" && module.exports) module.exports = api;
    else root.VCTExport = api;
})(typeof window !== "undefined" ? window : this, function (window) {
    "use strict";

    var hasDom = typeof document !== "undefined";
    var PRIMARY = "66062D";

    /* ------------------------------------------------------------------
       Rutas (relativas a donde esta publicado este mismo script: ../js/)
       ------------------------------------------------------------------ */
    function baseUrl() {
        if (!hasDom) return "";
        var s = document.currentScript;
        var src = s && s.src ? s.src : "";
        if (!src) {
            var all = document.getElementsByTagName("script");
            for (var i = all.length - 1; i >= 0; i--) {
                if (/vct-export\.js/i.test(all[i].src || "")) { src = all[i].src; break; }
            }
        }
        return src || (window.location ? window.location.href : "");
    }
    var BASE = baseUrl();
    function rel(path) {
        try { return new URL(path, BASE).href; } catch (e) { return path; }
    }
    var URLS = {
        jszip: "../lib/DataTables/JSZip-2.5.0/jszip.min.js",
        pdfmake: "../lib/DataTables/pdfmake-0.1.36/pdfmake.min.js",
        vfs: "../lib/DataTables/pdfmake-0.1.36/vfs_fonts.js",
        html2pdf: "../lib/tableToPdf/ExportPDF.js",
        logo: "../img/LogoBordo.png"
    };

    /* ------------------------------------------------------------------
       Utilidades
       ------------------------------------------------------------------ */
    function toast(msg, type) {
        try {
            if (window.VCT && window.VCT.Toast && window.VCT.Toast.show) { window.VCT.Toast.show(msg, type || "warning"); return; }
        } catch (e) { /* noop */ }
        if (typeof console !== "undefined") console.warn("[VCTExport] " + msg);
    }

    function clean(text) {
        return String(text === null || text === undefined ? "" : text)
            .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, "")
            .replace(/ /g, " ")
            .replace(/[ \t]+/g, " ")
            .trim();
    }

    function xmlEscape(text) {
        return clean(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    function stamp(d) { d = d || new Date(); return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
    function stampLong(d) {
        d = d || new Date();
        return pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + "/" + d.getFullYear() + " " + pad(d.getHours()) + ":" + pad(d.getMinutes());
    }

    function fileBase(spec) {
        var name = clean(spec.filename || spec.title || "Exportacion")
            .replace(/[\\\/:*?"<>|]+/g, " ").replace(/\s+/g, "_").replace(/^_+|_+$/g, "");
        return (name || "Exportacion") + "_" + stamp();
    }

    function colLetter(index) {
        var s = "", n = index + 1;
        while (n > 0) { var m = (n - 1) % 26; s = String.fromCharCode(65 + m) + s; n = Math.floor((n - 1) / 26); }
        return s;
    }

    /* Numero es-AR: "1.234,56" | "1234,5" | "-12" | "12.5" (punto decimal solo
       si NO tiene forma de miles). Devuelve null si no es un numero "limpio".
       Los codigos con ceros a la izquierda ("00123") o muy largos quedan texto. */
    function parseNumber(text) {
        var t = clean(text);
        if (!t) return null;
        if (/^-?0\d/.test(t)) return null;
        if (/^-?\d{1,3}(\.\d{3})+(,\d+)?$/.test(t)) return parseFloat(t.replace(/\./g, "").replace(",", "."));
        if (/^-?\d+,\d+$/.test(t)) return parseFloat(t.replace(",", "."));
        if (/^-?\d+(\.\d+)?$/.test(t)) {
            if (t.replace(/[-.]/g, "").length > 15) return null;
            return parseFloat(t);
        }
        return null;
    }

    function excelSerial(y, m, d) {
        return Math.round((Date.UTC(y, m - 1, d) - Date.UTC(1899, 11, 30)) / 86400000);
    }

    function parseDate(text) {
        var m = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(clean(text));
        if (!m) return null;
        var d = +m[1], mo = +m[2], y = +m[3];
        if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
        return excelSerial(y, mo, d);
    }

    /* -> { t: "n"|"d"|"s", v } */
    function typed(value, colType) {
        if (value instanceof Date && !isNaN(value.getTime()))
            return { t: "d", v: excelSerial(value.getFullYear(), value.getMonth() + 1, value.getDate()) };
        if (typeof value === "number" && isFinite(value)) return { t: "n", v: value };
        var text = clean(value);
        if (colType === "text" || text === "") return { t: "s", v: text };
        var dt = parseDate(text);
        if (dt !== null) return { t: "d", v: dt };
        var n = parseNumber(text);
        if (n !== null && isFinite(n)) return { t: "n", v: n };
        return { t: "s", v: text };
    }

    function textOf(value) {
        if (value instanceof Date) return pad(value.getDate()) + "/" + pad(value.getMonth() + 1) + "/" + value.getFullYear();
        return clean(value);
    }

    function columnWidths(spec, min, max) {
        var cols = spec.columns || [];
        var widths = cols.map(function (c) { return Math.min(max, Math.max(min, clean(c.title).length + 2)); });
        (spec.rows || []).forEach(function (row) {
            for (var i = 0; i < cols.length; i++) {
                var len = textOf(row[i]).length + 2;
                if (len > widths[i]) widths[i] = Math.min(max, len);
            }
        });
        cols.forEach(function (c, i) { if (c.width) widths[i] = c.width; });
        return widths;
    }

    function triggerDownload(blob, filename) {
        var url = URL.createObjectURL(blob);
        var a = document.createElement("a");
        a.href = url;
        a.download = filename;
        a.style.display = "none";
        document.body.appendChild(a);
        a.click();
        setTimeout(function () { document.body.removeChild(a); URL.revokeObjectURL(url); }, 1000);
    }

    /* ------------------------------------------------------------------
       Carga diferida de scripts
       ------------------------------------------------------------------ */
    var loading = {};
    function loadScript(url) {
        if (loading[url]) return loading[url];
        loading[url] = new Promise(function (resolve, reject) {
            var s = document.createElement("script");
            s.src = url;
            s.async = true;
            s.onload = function () { resolve(); };
            s.onerror = function () { delete loading[url]; reject(new Error("No se pudo cargar " + url)); };
            document.head.appendChild(s);
        });
        return loading[url];
    }

    function ensureJSZip() {
        if (window.JSZip) return Promise.resolve();
        return loadScript(rel(URLS.jszip)).then(function () {
            if (!window.JSZip) throw new Error("JSZip no disponible");
        });
    }

    function ensurePdfMake() {
        if (window.pdfMake && window.pdfMake.vfs && window.pdfMake.createPdf) return Promise.resolve();
        var chain = window.pdfMake && window.pdfMake.createPdf ? Promise.resolve() : loadScript(rel(URLS.pdfmake));
        return chain.then(function () {
            if (window.pdfMake && window.pdfMake.vfs) return null;
            return loadScript(rel(URLS.vfs));
        }).then(function () {
            if (!(window.pdfMake && window.pdfMake.vfs && window.pdfMake.createPdf)) throw new Error("pdfMake no disponible");
        });
    }

    /* ------------------------------------------------------------------
       EXCEL .xlsx (OOXML minimo, sin dependencias salvo JSZip para el zip)
       ------------------------------------------------------------------ */
    var XLSX_HEADER_ROW = 5; /* 1 titulo, 2 subtitulo, 3 generado, 4 vacio, 5 encabezado */

    function sheetName(spec) {
        var n = clean(spec.title || "Datos").replace(/[\[\]:*?\/\\]/g, " ").trim().slice(0, 31);
        return n || "Datos";
    }

    function buildStyles() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
            '<fonts count="4">' +
                '<font><sz val="11"/><name val="Calibri"/></font>' +
                '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>' +
                '<font><b/><sz val="14"/><color rgb="FF' + PRIMARY + '"/><name val="Calibri"/></font>' +
                '<font><i/><sz val="10"/><color rgb="FF64748B"/><name val="Calibri"/></font>' +
            '</fonts>' +
            '<fills count="3">' +
                '<fill><patternFill patternType="none"/></fill>' +
                '<fill><patternFill patternType="gray125"/></fill>' +
                '<fill><patternFill patternType="solid"><fgColor rgb="FF' + PRIMARY + '"/><bgColor indexed="64"/></patternFill></fill>' +
            '</fills>' +
            '<borders count="2">' +
                '<border><left/><right/><top/><bottom/><diagonal/></border>' +
                '<border><left style="thin"><color rgb="FFE2E8F0"/></left><right style="thin"><color rgb="FFE2E8F0"/></right>' +
                '<top style="thin"><color rgb="FFE2E8F0"/></top><bottom style="thin"><color rgb="FFE2E8F0"/></bottom><diagonal/></border>' +
            '</borders>' +
            '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
            '<cellXfs count="9">' +
                '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +                                                   /* 0 base */
                '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>' + /* 1 encabezado */
                '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +                                      /* 2 titulo */
                '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +                                      /* 3 subtitulo */
                '<xf numFmtId="49" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>' + /* 4 texto */
                '<xf numFmtId="3" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf>' + /* 5 entero */
                '<xf numFmtId="4" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf>' + /* 6 decimal */
                '<xf numFmtId="14" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf>' + /* 7 fecha */
                '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +                                      /* 8 generado */
            '</cellXfs>' +
            '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' +
            '</styleSheet>';
    }

    function inlineCell(ref, style, text) {
        return '<c r="' + ref + '" s="' + style + '" t="inlineStr"><is><t xml:space="preserve">' + xmlEscape(text) + '</t></is></c>';
    }

    function buildSheet(spec) {
        var cols = spec.columns || [];
        var rows = spec.rows || [];
        var last = colLetter(Math.max(cols.length, 1) - 1);
        var widths = columnWidths(spec, 8, 60);
        var out = [];

        out.push('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        out.push('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
        out.push('<sheetViews><sheetView workbookViewId="0" showGridLines="0">' +
            '<pane ySplit="' + XLSX_HEADER_ROW + '" topLeftCell="A' + (XLSX_HEADER_ROW + 1) + '" activePane="bottomLeft" state="frozen"/>' +
            '<selection pane="bottomLeft" activeCell="A' + (XLSX_HEADER_ROW + 1) + '" sqref="A' + (XLSX_HEADER_ROW + 1) + '"/>' +
            '</sheetView></sheetViews>');
        out.push('<sheetFormatPr defaultRowHeight="15"/>');
        out.push('<cols>' + widths.map(function (w, i) {
            return '<col min="' + (i + 1) + '" max="' + (i + 1) + '" width="' + w + '" customWidth="1"/>';
        }).join("") + '</cols>');

        out.push('<sheetData>');
        out.push('<row r="1" ht="22" customHeight="1">' + inlineCell("A1", 2, spec.title || "") + '</row>');
        if (clean(spec.subtitle)) out.push('<row r="2">' + inlineCell("A2", 3, spec.subtitle) + '</row>');
        out.push('<row r="3">' + inlineCell("A3", 8, "Generado: " + stampLong()) + '</row>');

        var h = XLSX_HEADER_ROW;
        out.push('<row r="' + h + '" ht="24" customHeight="1">' + cols.map(function (c, i) {
            return inlineCell(colLetter(i) + h, 1, c.title);
        }).join("") + '</row>');

        rows.forEach(function (row, r) {
            var rowNum = h + 1 + r;
            var cells = [];
            for (var i = 0; i < cols.length; i++) {
                var ref = colLetter(i) + rowNum;
                var cell = typed(row[i], cols[i].type);
                if (cell.t === "n") {
                    cells.push('<c r="' + ref + '" s="' + (Math.floor(cell.v) === cell.v ? 5 : 6) + '"><v>' + cell.v + '</v></c>');
                } else if (cell.t === "d") {
                    cells.push('<c r="' + ref + '" s="7"><v>' + cell.v + '</v></c>');
                } else {
                    cells.push(inlineCell(ref, 4, cell.v));
                }
            }
            out.push('<row r="' + rowNum + '">' + cells.join("") + '</row>');
        });
        out.push('</sheetData>');

        var lastRow = h + Math.max(rows.length, 1);
        out.push('<autoFilter ref="A' + h + ':' + last + lastRow + '"/>');
        out.push('<pageMargins left="0.5" right="0.5" top="0.6" bottom="0.6" header="0.3" footer="0.3"/>');
        out.push('<pageSetup orientation="' + (cols.length > 6 ? "landscape" : "portrait") + '" fitToHeight="0"/>');
        out.push('</worksheet>');
        return out.join("");
    }

    /* -> { "ruta/en/el/zip": "contenido" } */
    function buildXlsxFiles(spec) {
        var name = xmlEscape(sheetName(spec));
        var files = {};
        files["[Content_Types].xml"] =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>' +
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
            '</Types>';
        files["_rels/.rels"] =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
            '</Relationships>';
        files["xl/workbook.xml"] =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
            '<sheets><sheet name="' + name + '" sheetId="1" r:id="rId1"/></sheets>' +
            '<definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">\'' + name + '\'!$A$' + XLSX_HEADER_ROW + ':$' +
                colLetter(Math.max((spec.columns || []).length, 1) - 1) + '$' + (XLSX_HEADER_ROW + Math.max((spec.rows || []).length, 1)) + '</definedName></definedNames>' +
            '</workbook>';
        files["xl/_rels/workbook.xml.rels"] =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
            '</Relationships>';
        files["xl/styles.xml"] = buildStyles();
        files["xl/worksheets/sheet1.xml"] = buildSheet(spec);
        return files;
    }

    function excelFallback(spec) {
        var cols = spec.columns || [];
        var html = '<html><head><meta charset="utf-8"></head><body><table border="1"><thead><tr>' +
            cols.map(function (c) { return "<th>" + xmlEscape(c.title) + "</th>"; }).join("") + "</tr></thead><tbody>" +
            (spec.rows || []).map(function (row) {
                return "<tr>" + cols.map(function (c, i) { return "<td>" + xmlEscape(textOf(row[i])) + "</td>"; }).join("") + "</tr>";
            }).join("") + "</tbody></table></body></html>";
        triggerDownload(new Blob(["﻿", html], { type: "application/vnd.ms-excel;charset=utf-8;" }), fileBase(spec) + ".xls");
    }

    function excel(spec) {
        spec = spec || {};
        return ensureJSZip().then(function () {
            var zip = new window.JSZip();
            var files = buildXlsxFiles(spec);
            Object.keys(files).forEach(function (path) { zip.file(path, files[path]); });
            var blob = zip.generate({
                type: "blob",
                compression: "DEFLATE",
                mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            });
            triggerDownload(blob, fileBase(spec) + ".xlsx");
        }).catch(function (err) {
            toast("No se pudo generar el .xlsx (" + err.message + "). Se descarga en formato alternativo.", "warning");
            excelFallback(spec);
        });
    }

    /* ------------------------------------------------------------------
       IMAGENES: logo y rasterizado de graficos
       ------------------------------------------------------------------ */
    function imageToDataUrl(url) {
        return new Promise(function (resolve) {
            if (!url) { resolve(null); return; }
            if (/^data:image\//i.test(url)) { resolve({ dataUrl: url }); return; }
            var img = new Image();
            img.onload = function () {
                try {
                    var c = document.createElement("canvas");
                    c.width = img.naturalWidth || img.width;
                    c.height = img.naturalHeight || img.height;
                    c.getContext("2d").drawImage(img, 0, 0);
                    resolve({ dataUrl: c.toDataURL("image/png"), width: c.width, height: c.height });
                } catch (e) { resolve(null); }
            };
            img.onerror = function () { resolve(null); };
            img.src = url;
        });
    }

    function svgToPng(svg) {
        return new Promise(function (resolve) {
            try {
                var rect = svg.getBoundingClientRect();
                var w = Math.max(1, Math.round(rect.width || +svg.getAttribute("width") || 200));
                var h = Math.max(1, Math.round(rect.height || +svg.getAttribute("height") || 200));
                var clone = svg.cloneNode(true);
                clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
                clone.setAttribute("width", w);
                clone.setAttribute("height", h);
                /* los SVG de VCT colorean por clase CSS (donut): se inlinean los estilos computados */
                var src = svg.querySelectorAll("*"), dst = clone.querySelectorAll("*");
                for (var i = 0; i < src.length && i < dst.length; i++) {
                    var cs = window.getComputedStyle(src[i]);
                    ["fill", "stroke", "stroke-width", "stroke-dasharray", "stroke-dashoffset", "stroke-linecap", "font-size", "font-weight", "font-family", "opacity"].forEach(function (p) {
                        dst[i].style.setProperty(p, cs.getPropertyValue(p));
                    });
                }
                var xml = new XMLSerializer().serializeToString(clone);
                var img = new Image();
                img.onload = function () {
                    try {
                        var scale = 2, c = document.createElement("canvas");
                        c.width = w * scale; c.height = h * scale;
                        var ctx = c.getContext("2d");
                        ctx.fillStyle = "#ffffff"; ctx.fillRect(0, 0, c.width, c.height);
                        ctx.drawImage(img, 0, 0, c.width, c.height);
                        resolve(c.toDataURL("image/png"));
                    } catch (e) { resolve(null); }
                };
                img.onerror = function () { resolve(null); };
                img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(xml);
            } catch (e) { resolve(null); }
        });
    }

    function htmlToPng(el) {
        var run = function () {
            try {
                if (window.html2canvas) return window.html2canvas(el, { backgroundColor: "#ffffff", scale: 2 }).then(function (c) { return c.toDataURL("image/png"); });
                if (window.html2pdf) return window.html2pdf().from(el).toCanvas().get("canvas").then(function (c) { return c.toDataURL("image/png"); });
            } catch (e) { /* noop */ }
            return Promise.resolve(null);
        };
        if (window.html2canvas || window.html2pdf) return run().catch(function () { return null; });
        return loadScript(rel(URLS.html2pdf)).then(run).catch(function () { return null; });
    }

    /* Elemento -> dataURL PNG (SVG directo; el resto via html2canvas). Nunca rechaza: null si falla. */
    function rasterize(el) {
        if (!el || !hasDom) return Promise.resolve(null);
        var svg = el.tagName && el.tagName.toLowerCase() === "svg" ? el : el.querySelector("svg.vct-donut, svg");
        var onlySvg = svg && !el.querySelector(".vct-barchart, .vct-gantt");
        if (onlySvg) return svgToPng(svg);
        return htmlToPng(el);
    }

    /* ------------------------------------------------------------------
       PDF real (pdfmake)
       ------------------------------------------------------------------ */
    function pdfTable(spec, avail) {
        var cols = spec.columns || [];
        var weights = columnWidths(spec, 6, 40);
        var sum = weights.reduce(function (a, b) { return a + b; }, 0) || 1;
        var widths = weights.map(function (w) { return Math.max(24, (avail * w) / sum); });

        var head = cols.map(function (c) {
            return { text: clean(c.title), bold: true, color: "#FFFFFF", fillColor: "#" + PRIMARY, alignment: "center", fontSize: 8 };
        });
        var body = [head];
        (spec.rows || []).forEach(function (row) {
            body.push(cols.map(function (c, i) {
                var cell = typed(row[i], c.type);
                var isNum = cell.t === "n";
                return { text: textOf(row[i]), fontSize: 8, alignment: c.align || (isNum ? "right" : (cell.t === "d" ? "center" : "left")) };
            }));
        });
        if (!(spec.rows || []).length) {
            body.push([{ text: "Sin registros para exportar.", colSpan: Math.max(cols.length, 1), alignment: "center", fontSize: 8, color: "#64748B" }]);
        }

        return {
            table: { headerRows: 1, widths: widths, body: body },
            layout: {
                hLineWidth: function () { return 0.5; },
                vLineWidth: function () { return 0.5; },
                hLineColor: function () { return "#E2E8F0"; },
                vLineColor: function () { return "#E2E8F0"; },
                fillColor: function (i) { return i === 0 ? "#" + PRIMARY : (i % 2 === 0 ? "#F8FAFC" : null); },
                paddingLeft: function () { return 4; },
                paddingRight: function () { return 4; },
                paddingTop: function () { return 3; },
                paddingBottom: function () { return 3; }
            }
        };
    }

    function buildPdfDefinition(spec, logo) {
        var cols = spec.columns || [];
        var landscape = spec.orientation ? spec.orientation === "landscape" : cols.length > 6;
        var pageW = landscape ? 841.89 : 595.28;
        var margin = 28;
        var avail = pageW - margin * 2;
        var generated = stampLong();
        var content = [];

        var imgs = (spec.images || []).filter(function (i) { return i && i.dataUrl; });
        if (imgs.length) {
            var per = Math.min(imgs.length, 3);
            for (var s = 0; s < imgs.length; s += per) {
                var slice = imgs.slice(s, s + per);
                var colW = avail / per - 10;
                content.push({
                    columns: slice.map(function (im) {
                        var stack = [];
                        if (im.caption) stack.push({ text: clean(im.caption), bold: true, fontSize: 9, color: "#" + PRIMARY, margin: [0, 0, 0, 3] });
                        stack.push({ image: im.dataUrl, fit: [colW, 150] });
                        return { width: "*", stack: stack };
                    }),
                    columnGap: 10,
                    margin: [0, 0, 0, 10]
                });
            }
        }
        content.push(pdfTable(spec, avail));

        return {
            pageSize: "A4",
            pageOrientation: landscape ? "landscape" : "portrait",
            pageMargins: [margin, 70, margin, 40],
            info: { title: clean(spec.title || "Exportacion"), creator: "Vocaturo" },
            defaultStyle: { font: "Roboto", fontSize: 8 },
            header: function () {
                var left = logo ? { image: logo.dataUrl, width: 84, margin: [0, 2, 0, 0] } : { text: "Vocaturo", bold: true, fontSize: 14, color: "#" + PRIMARY };
                var right = { stack: [
                    { text: clean(spec.title), bold: true, fontSize: 13, color: "#" + PRIMARY, alignment: "right" },
                    clean(spec.subtitle) ? { text: clean(spec.subtitle), fontSize: 8.5, color: "#64748B", alignment: "right", margin: [0, 2, 0, 0] } : { text: "" }
                ] };
                return { margin: [margin, 18, margin, 0], columns: [{ width: 100, stack: [left] }, { width: "*", stack: right.stack }] };
            },
            footer: function (page, pages) {
                return { margin: [margin, 12, margin, 0], columns: [
                    { text: "Generado: " + generated, fontSize: 8, color: "#64748B" },
                    { text: "Página " + page + " de " + pages, fontSize: 8, color: "#64748B", alignment: "right" }
                ] };
            },
            content: content
        };
    }

    function printFallback(spec, logo) {
        var cols = spec.columns || [];
        var w = window.open("", "_blank");
        if (!w) { toast("El navegador bloqueó la ventana de impresión.", "warning"); return; }
        var html = '<!doctype html><html><head><meta charset="utf-8"><title>' + xmlEscape(spec.title) + '</title><style>' +
            '@page{size:' + (cols.length > 6 ? "landscape" : "portrait") + ';margin:12mm}' +
            'body{font-family:Arial,sans-serif;color:#1e293b}' +
            '.h{display:flex;align-items:center;justify-content:space-between;border-bottom:3px solid #' + PRIMARY + ';padding-bottom:8px;margin-bottom:12px}' +
            '.h img{height:42px}.h h1{margin:0;font-size:18px;color:#' + PRIMARY + '}.h p{margin:2px 0 0;font-size:11px;color:#64748b}' +
            'table{width:100%;border-collapse:collapse;font-size:10px}th{background:#' + PRIMARY + ';color:#fff;padding:5px}' +
            'td{border:1px solid #e2e8f0;padding:4px 5px}tr:nth-child(even) td{background:#f8fafc}thead{display:table-header-group}' +
            '</style></head><body><div class="h"><div>' + (logo ? '<img src="' + logo.dataUrl + '">' : "") + '</div><div style="text-align:right"><h1>' +
            xmlEscape(spec.title) + '</h1><p>' + xmlEscape(spec.subtitle) + '</p></div></div><table><thead><tr>' +
            cols.map(function (c) { return "<th>" + xmlEscape(c.title) + "</th>"; }).join("") + "</tr></thead><tbody>" +
            (spec.rows || []).map(function (row) {
                return "<tr>" + cols.map(function (c, i) { return "<td>" + xmlEscape(textOf(row[i])) + "</td>"; }).join("") + "</tr>";
            }).join("") + '</tbody></table><script>window.onload=function(){window.print();}<\/script></body></html>';
        w.document.open(); w.document.write(html); w.document.close();
    }

    function pdf(spec) {
        spec = spec || {};
        var logoUrl = spec.logo === false ? null : rel(spec.logo || URLS.logo);
        var logoP = imageToDataUrl(logoUrl);
        return Promise.all([ensurePdfMake().then(function () { return true; }, function (e) { return e; }), logoP]).then(function (res) {
            var libOk = res[0] === true, logo = res[1];
            if (!libOk) throw res[0];
            return new Promise(function (resolve, reject) {
                try {
                    window.pdfMake.createPdf(buildPdfDefinition(spec, logo)).download(fileBase(spec) + ".pdf", function () { resolve(); });
                    setTimeout(resolve, 1500);
                } catch (e) { reject(e); }
            });
        }).catch(function (err) {
            toast("No se pudo generar el PDF (" + (err && err.message ? err.message : err) + "). Se abre la vista de impresión.", "warning");
            return logoP.then(function (logo) { printFallback(spec, logo); });
        });
    }

    return {
        version: "1.0",
        excel: excel,
        pdf: pdf,
        rasterize: rasterize,
        _internal: {
            clean: clean, parseNumber: parseNumber, parseDate: parseDate, typed: typed,
            colLetter: colLetter, buildXlsxFiles: buildXlsxFiles, buildPdfDefinition: buildPdfDefinition, fileBase: fileBase
        }
    };
});
