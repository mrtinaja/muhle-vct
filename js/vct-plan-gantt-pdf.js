/* Vocaturo - exportador vectorial del cronograma, independiente de la pantalla.
   Usa pdfMake ya distribuido con Muhle; no requiere cambios SQL. */
(function (w) {
    'use strict';
    function load(src) {
        return new Promise(function (resolve, reject) {
            var s = document.createElement('script'); s.src = src;
            s.onload = resolve; s.onerror = function () { reject(new Error('No se pudo cargar ' + src)); };
            document.head.appendChild(s);
        });
    }
    function ready() {
        var base = '../lib/DataTables/pdfmake-0.1.36/';
        return (w.pdfMake && w.pdfMake.createPdf ? Promise.resolve() : load(base + 'pdfmake.min.js'))
            .then(function () { return w.pdfMake && w.pdfMake.vfs ? null : load(base + 'vfs_fonts.js'); })
            .then(function () { if (!w.pdfMake || !w.pdfMake.vfs) throw new Error('pdfMake no disponible'); });
    }
    function date(s) { return /^\d{4}-\d{2}-\d{2}$/.test(s || '') ? new Date(s + 'T12:00:00') : null; }
    function monday(d) { var a = new Date(d); a.setDate(a.getDate() - (a.getDay() + 6) % 7); return a; }
    function plus(d, n) { var a = new Date(d); a.setDate(a.getDate() + n); return a; }
    function txt(r, k) { return r.getAttribute(k) || ''; }
    function visible(r) { return r.style.display !== 'none' && !r.hidden; }
    function read(box) {
        return Array.prototype.filter.call(box.querySelectorAll('.vct-plan-row'), visible).map(function (r) {
            return { id: txt(r, 'data-vct-pi-id'), code: txt(r, 'data-vct-pi-cod'), title: txt(r, 'data-vct-pi-tit'),
                resp: txt(r, 'data-vct-pi-resp'), start: date(txt(r, 'data-vct-pi-ini')),
                end: date(txt(r, 'data-vct-pi-fin')), real: date(txt(r, 'data-vct-pi-real')),
                progress: Math.max(0, Math.min(100, Number(txt(r, 'data-x-av')) || 0)),
                state: txt(r, 'data-plan-estado'), sub: r.classList.contains('is-sub') };
        });
    }
    function color(state) { return ({ CUMPLIDO: '#0B8066', VENCIDO: '#C2410C', EN_CURSO: '#2870B7', PENDIENTE: '#94A3B8' })[state] || '#94A3B8'; }
    function pdf(box) {
        var rows = read(box);
        if (!rows.length) return Promise.reject(new Error('No hay filas visibles para exportar'));
        var starts = rows.filter(function (r) { return r.start; }).map(function (r) { return r.start.getTime(); });
        var ends = rows.filter(function (r) { return r.end || r.start; }).map(function (r) { return (r.end || r.start).getTime(); });
        if (!starts.length || !ends.length) return Promise.reject(new Error('No hay fechas válidas para construir el Gantt'));
        var first = monday(new Date(Math.min.apply(null, starts)));
        var last = new Date(Math.max.apply(null, ends));
        var weeks = Math.max(1, Math.ceil((last - first) / 604800000) + 1);
        if (weeks > 520) return Promise.reject(new Error('El período supera las 520 semanas permitidas'));
        var content = [], perPage = 13;
        for (var offset = 0; offset < weeks; offset += perPage) {
            var n = Math.min(perPage, weeks - offset), begin = plus(first, offset * 7);
            var end = plus(begin, n * 7 - 1);
            var header = [{ text: 'Ítem / responsable', bold: true, fillColor: '#E9EDF2' }];
            for (var i = 0; i < n; i++) {
                var dt = plus(begin, i * 7);
                header.push({ text: ('0' + dt.getDate()).slice(-2) + '/' + ('0' + (dt.getMonth() + 1)).slice(-2),
                    alignment: 'center', bold: true, fillColor: '#E9EDF2' });
            }
            var body = [header];
            rows.forEach(function (r) {
                var label = (r.sub ? '   ' : '') + (r.code ? r.code + ' · ' : '') + r.title + (r.resp ? '\n' + r.resp : '');
                var line = [{ text: label, fontSize: 7, margin: [3, 4, 2, 4] }];
                for (var j = 0; j < n; j++) {
                    var ws = plus(begin, j * 7), we = plus(ws, 6);
                    var active = r.start && r.end && r.start <= we && r.end >= ws;
                    line.push({ text: active ? (r.progress ? r.progress + '%' : '●') : '',
                        fontSize: 6, alignment: 'center', color: active ? '#FFFFFF' : '#475569',
                        fillColor: active ? color(r.state) : (j % 2 ? '#F7F9FC' : '#FFFFFF'),
                        margin: [0, 5, 0, 5] });
                }
                body.push(line);
            });
            if (content.length) content.push({ text: '', pageBreak: 'before' });
            content.push({ text: 'Cronograma · ' + begin.toLocaleDateString('es-AR') + ' — ' + end.toLocaleDateString('es-AR'),
                bold: true, fontSize: 10, margin: [0, 0, 0, 8] });
            content.push({ table: { headerRows: 1, widths: [260].concat(Array(n).fill('*')), body: body },
                layout: { hLineWidth: function () { return 0.35; }, vLineWidth: function () { return 0.35; },
                    hLineColor: function () { return '#CBD5E1'; }, vLineColor: function () { return '#CBD5E1'; },
                    paddingLeft: function () { return 2; }, paddingRight: function () { return 2; } } });
        }
        var title = box.getAttribute('data-plan-titulo') || 'Plan estratégico';
        var doc = { pageSize: 'A3', pageOrientation: 'landscape', pageMargins: [26, 60, 26, 38],
            defaultStyle: { font: 'Roboto', fontSize: 7 }, content: content,
            header: function () { return { text: 'Vocaturo  |  ' + title, margin: [26, 22, 26, 0], fontSize: 12, bold: true, color: '#66062D' }; },
            footer: function (page, pages) { return { text: 'Página ' + page + ' de ' + pages, alignment: 'right', margin: [0, 10, 26, 0], fontSize: 8 }; } };
        return ready().then(function () { return new Promise(function (resolve) {
            w.pdfMake.createPdf(doc).download('Vocaturo_Cronograma_Gantt.pdf', resolve);
        }); });
    }
    w.VCTPlanGanttPDF = { pdf: pdf };
})(window);