
/* VCT Proyecto V360 - Agenda mensual de visitas, solo lectura. */
(function () {
  'use strict';
  if (window.__vctProyectoAgendaV1) return;
  window.__vctProyectoAgendaV1 = true;

  var MONTHS = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  function el(tag, cls, txt) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (txt !== undefined) n.textContent = txt;
    return n;
  }
  function pad(n) { return String(n).padStart(2, '0'); }
  function key(y,m,d) { return y + '-' + pad(m+1) + '-' + pad(d); }
  function hours(n) { return String(n || '0').replace('.', ',') + ' h'; }
  function init(root) {
    if (root.dataset.vctPvaReady === '1') return;
    root.dataset.vctPvaReady = '1';
    var grid = root.querySelector('[data-vct-pva-grid]');
    var title = root.querySelector('[data-vct-pva-title]');
    if (!grid || !title) return;
    var records = Array.from(root.querySelectorAll('[data-vct-pva-event]')).map(function (node) {
      return {
        date: node.dataset.date, visit: node.dataset.visit,
        service: node.dataset.service || 'Servicio',
        person: node.dataset.person || 'Profesional sin nombre',
        planned: node.dataset.hours || '0', executed: node.dataset.executed || ''
      };
    }).filter(function (r) { return /^\d{4}-\d{2}-\d{2}$/.test(r.date); });
    var now = new Date();
    var year = now.getFullYear(), month = now.getMonth();
    var overlay = null;

    function closeDetails() {
      if (overlay) { overlay.remove(); overlay = null; }
    }
    function showDetails(date, events) {
      closeDetails();
      overlay = el('div','vct-pva-overlay');
      var dialog = el('section','vct-pva-dialog');
      dialog.setAttribute('role','dialog');
      dialog.setAttribute('aria-modal','true');
      dialog.setAttribute('aria-label','Visitas del ' + date);
      var head = el('div','vct-pva-dialog-head');
      head.appendChild(el('h3','', 'Visitas del ' + date.split('-').reverse().join('/')));
      var close = el('button','vct-pva-close','×');
      close.type = 'button'; close.setAttribute('aria-label','Cerrar');
      close.addEventListener('click',closeDetails);
      head.appendChild(close); dialog.appendChild(head);
      events.forEach(function (e) {
        var item = el('div','vct-pva-detail');
        item.appendChild(el('strong','',e.service));
        item.appendChild(el('span','',e.person));
        item.appendChild(el('small','', 'Planificadas: ' + hours(e.planned) +
          (e.executed !== '' ? ' · Ejecutadas: ' + hours(e.executed) : '')));
        dialog.appendChild(item);
      });
      overlay.appendChild(dialog);
      overlay.addEventListener('click',function (event) { if (event.target === overlay) closeDetails(); });
      document.body.appendChild(overlay);
      close.focus();
    }
    function render() {
      title.textContent = MONTHS[month] + ' ' + year;
      grid.replaceChildren();
      var grouped = Object.create(null);
      records.forEach(function (r) { (grouped[r.date] || (grouped[r.date] = [])).push(r); });
      var first = new Date(year,month,1);
      var offset = (first.getDay()+6)%7;
      var count = new Date(year,month+1,0).getDate();
      var cells = Math.ceil((offset+count)/7)*7;
      for (var i=0; i<cells; i++) {
        var day = i-offset+1;
        var cell = el('div','vct-pva-day');
        if (day<1 || day>count) { cell.classList.add('is-outside'); grid.appendChild(cell); continue; }
        var date = key(year,month,day);
        if (date === key(now.getFullYear(),now.getMonth(),now.getDate())) cell.classList.add('is-today');
        cell.appendChild(el('span','vct-pva-daynum',String(day)));
        var events = grouped[date] || [];
        var visits = Object.create(null);
        events.forEach(function (e) { (visits[e.visit] || (visits[e.visit] = [])).push(e); });
        Object.keys(visits).forEach(function (id) {
          var group = visits[id];
          var button = el('button','vct-pva-visit');
          button.type = 'button';
          button.appendChild(el('strong','',group[0].service));
          button.appendChild(el('span','',group.map(function (r) { return r.person; }).join(', ')));
          button.appendChild(el('small','',group.map(function (r) { return hours(r.planned); }).join(' · ')));
          button.title = 'Ver detalle de visita';
          button.addEventListener('click',function () { showDetails(date,group); });
          cell.appendChild(button);
        });
        grid.appendChild(cell);
      }
    }
    function move(n) {
      var d = new Date(year,month+n,1);
      year=d.getFullYear(); month=d.getMonth(); render();
    }
    var prev=root.querySelector('[data-vct-pva-prev]');
    var next=root.querySelector('[data-vct-pva-next]');
    if(prev) prev.addEventListener('click',function(){move(-1);});
    if(next) next.addEventListener('click',function(){move(1);});
    render();
  }
  function boot() { document.querySelectorAll('[data-vct-pva-root]').forEach(init); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',boot);
  else boot();
  var queued=false;
  new MutationObserver(function () {
    if(queued) return;
    queued=true;
    Promise.resolve().then(function () {queued=false;boot();});
  }).observe(document.body || document.documentElement,{childList:true,subtree:true});
})();
