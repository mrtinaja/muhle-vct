/* vct-calendario.js - v1 (UNIFICADO)
   ============================================================================
   UN SOLO JS para TODO el calendario:
     - feriados (boota sobre [data-vct-agenda-root], ex vct-Agenda.js)
     - agenda del consultor (boota sobre [data-vct-agc-root], ex vct-agenda-consultor.js)
   Cada motor arranca solo en su propio root y tiene su guard, asi que conviven
   en un unico archivo sin colisionar. Reemplaza a vct-Agenda.js + vct-agenda-consultor.js.
   (Paso siguiente del bloque: unificar los dos render en un solo motor + look GCal.)
   ============================================================================ */

/* ===================== [FERIADOS] ex vct-Agenda.js ===================== */
/* vct-agenda.js - v9
   Calendario full-width con vistas Mes / Semana / Dia, 100% cliente
   (Date() nativo, no depende de columnas calculadas de dbo.Calendar).
   Clic en un dia dispara el alta (dia sin feriado) o el borrado (dia con
   feriado) reutilizando los modales que arma la SP via VCT_MAIN_RENDER_
   FORM/FORM_ACTION -- este archivo nunca escribe en el servidor por su
   cuenta, solo dibuja las vistas y dispara los botones ya wireados. */
(function(){
    "use strict";

    var MESES=["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"];
    var DIAS_CORTOS=["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"];
    var DIAS_ABREV=["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"];

    function pad(n){ return n<10 ? "0"+n : ""+n; }
    function dateKey(d){ return d.getFullYear()+"-"+pad(d.getMonth()+1)+"-"+pad(d.getDate()); }
    function sameDay(a,b){ return dateKey(a)===dateKey(b); }
    function addDays(d,n){ var r=new Date(d); r.setDate(r.getDate()+n); return r; }

    function escapeHtml(s){
        return String(s||"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
    }
    function escapeAttr(s){
        return escapeHtml(s).replace(/"/g,"&quot;");
    }

    function initAgenda(root){
        if(!root || root.getAttribute("data-vct-agenda-inited")==="1") return;
        root.setAttribute("data-vct-agenda-inited","1");

        var canEdit=root.getAttribute("data-vct-agenda-can-edit")==="1";

        var feriados={};
        try{
            var raw=root.getAttribute("data-vct-feriados")||"[]";
            var list=JSON.parse(raw);
            for(var i=0;i<list.length;i++){
                var row=list[i];
                feriados[row.f]={ tipo:row.t, texto:row.x };
            }
        }catch(e){ feriados={}; }

        /* Actividades de Proyecto 360: datos de lectura; Feriados conserva su fuente. */
        var hasActivities=root.hasAttribute("data-vct-calendar-events");
        var activities={};
        if(hasActivities){
            try{JSON.parse(root.getAttribute("data-vct-calendar-events")||"[]").forEach(function(e){
                if(!activities[e.f]) activities[e.f]=[];
                activities[e.f].push(e);
            });}catch(e){activities={};}
        }
        function activityBadges(key,compact){
            var items=activities[key]||[];
            var shown=compact&&items.length>2?items.slice(0,1):items;
            return '<div class="vct-agenda-events">'+shown.map(function(e){
                var tone=e.k==="AGENDADA"?" is-planned":e.k==="REGISTRADA"?"":" is-pending";
                return '<span class="vct-agenda-event'+tone+'" title="'+escapeAttr(e.x)+'">'+escapeHtml(e.x)+'</span>';
            }).join("")+(compact&&items.length>2?'<span class="vct-agenda-event">+ '+(items.length-1)+' actividades</span>':'')+'</div>';
        }

        var today=new Date();
        var state={ view:"month", cursor:new Date(today.getFullYear(),today.getMonth(),today.getDate()) };

        var titleEl=root.querySelector("[data-vct-agenda-title]");
        var paneEl=root.querySelector("[data-vct-agenda-view-pane]");
        var selMonth=root.querySelector("[data-vct-agenda-select-month]");
        var selYear=root.querySelector("[data-vct-agenda-select-year]");
        var btnPrev=root.querySelector("[data-vct-agenda-prev]");
        var btnNext=root.querySelector("[data-vct-agenda-next]");
        var viewButtons=root.querySelectorAll("[data-vct-agenda-view]");
        /* Mes y anio nativos: el enhancer antiguo confunde wrappers adyacentes. */
        [selMonth,selYear].forEach(function(select){
            if(!select)return;
            var wrapper=select.nextElementSibling;
            if(wrapper&&wrapper.classList.contains("vct-custom-select-wrapper"))wrapper.remove();
            select.dataset.vctCustomInit="true";
            select.setAttribute("data-vct-native","true");
            select.style.removeProperty("display");
        });
        var proxyDelete=root.querySelector("[data-vct-agenda-proxy-delete]");
        var btnCreate=root.querySelector(".vct-agenda-btn-new");

        /* ------------------------------------------------------------
           CLIC EN UN DIA -> dispara el modal correspondiente
           ------------------------------------------------------------ */
        var todayOnly=new Date(today.getFullYear(),today.getMonth(),today.getDate());
        function isPast(dateObj){
            return new Date(dateObj.getFullYear(),dateObj.getMonth(),dateObj.getDate()) < todayOnly;
        }

        function openDayModal(dateObj){
            if(hasActivities){state.cursor=new Date(dateObj);setView("day");return;}
            if(!canEdit) return;
            if(isPast(dateObj)) return; // no se editan/agregan feriados en fechas pasadas
            var key=dateKey(dateObj);
            var fer=feriados[key];
            var isWeekendDay=(dateObj.getDay()===0 || dateObj.getDay()===6);

            if(fer){
                // Un feriado fijo puede caer en fin de semana (ej. Belgrano
                // 20/6/2026 = sabado) -- si ya existe, se puede seguir
                // gestionando (ver/eliminar) aunque sea fin de semana.
                if(!proxyDelete) return;
                proxyDelete.setAttribute("data-vct-fecha", key);
                proxyDelete.setAttribute("data-vct-tipo", String(fer.tipo));
                proxyDelete.setAttribute("data-vct-holidaytext", fer.texto || "");
                var delBtn=proxyDelete.querySelector("button");
                if(delBtn) delBtn.click();
            }else{
                // No tiene sentido cargar un feriado nuevo en un dia que ya
                // es no laborable por ser fin de semana.
                if(isWeekendDay) return;
                if(!btnCreate) return;
                btnCreate.click();
                // El input de fecha ya existe en el DOM del modal (solo
                // oculto), completar apenas se abre.
                setTimeout(function(){ trySetCreateDate(key); }, 30);
            }
        }

        function trySetCreateDate(val){
            var selectors=[
                '#vctAgendaFeriadoModal [name="SP.TEXTO01"]',
                '#vctAgendaFeriadoModal [data-vct-field="TEXTO01"]',
                '[data-vct-form-id="vctAgendaFeriadoModal"] [name="SP.TEXTO01"]',
                '[data-vct-form-id="vctAgendaFeriadoModal"] [data-vct-field="TEXTO01"]',
                '[data-vct-target="vctAgendaFeriadoModal"] [name="SP.TEXTO01"]',
                '[name="SP.TEXTO01"]'
            ];
            for(var i=0;i<selectors.length;i++){
                var el;
                try{ el=document.querySelector(selectors[i]); }catch(e){ el=null; }
                if(el){
                    el.value=val;
                    el.dispatchEvent(new Event("input",{bubbles:true}));
                    el.dispatchEvent(new Event("change",{bubbles:true}));
                    return true;
                }
            }
            return false;
        }

        /* ------------------------------------------------------------
           NAVEGACION / SELECTS
           ------------------------------------------------------------ */
        function fillYearSelect(){
            var prevValue=selYear.value;
            selYear.innerHTML="";
            var minY=today.getFullYear()-3, maxY=today.getFullYear()+3;
            for(var y=minY;y<=maxY;y++){
                var opt=document.createElement("option");
                opt.value=String(y);
                opt.textContent=String(y);
                selYear.appendChild(opt);
            }
            if(prevValue) selYear.value=prevValue;
        }

        function holidayClass(fer){
            if(!fer) return "";
            return (String(fer.tipo)==="2") ? " vct-agenda-cell-holiday-puente" : " vct-agenda-cell-holiday";
        }

        /* ------------------------------------------------------------
           VISTAS
           ------------------------------------------------------------ */
        function renderMonth(){
            var year=state.cursor.getFullYear(), month=state.cursor.getMonth()+1;
            titleEl.textContent=MESES[month-1]+" "+year;

            var firstOfMonth=new Date(year, month-1, 1);
            var startWeekday=firstOfMonth.getDay();
            var daysInMonth=new Date(year, month, 0).getDate();
            var totalCells=Math.ceil((startWeekday+daysInMonth)/7)*7;
            var dayNum=1-startWeekday;

            var html='<table class="vct-agenda-table"><thead><tr>'+
                DIAS_ABREV.map(function(d){ return "<th>"+d+"</th>"; }).join("")+
                '</tr></thead><tbody>';

            for(var w=0; w<totalCells/7; w++){
                html+="<tr>";
                for(var d=0; d<7; d++){
                    if(dayNum<1 || dayNum>daysInMonth){
                        html+='<td class="vct-agenda-cell vct-agenda-cell-empty"></td>';
                    }else{
                        var cellDate=new Date(year, month-1, dayNum);
                        var key=dateKey(cellDate);
                        var isWeekend=(d===0||d===6);
                        var isToday=sameDay(cellDate,today);
                        var fer=feriados[key];
                        var isPastDay=isPast(cellDate);

                        var cls="vct-agenda-cell"+(isWeekend?" vct-agenda-cell-weekend":"")+(isToday?" vct-agenda-cell-today":"")+holidayClass(fer)+((canEdit && !isPastDay)?"":" vct-agenda-cell-nocreate")+(isPastDay?" vct-agenda-cell-past":"");

                        html+='<td class="'+cls+'" data-vct-agenda-day="'+key+'"'+(fer && fer.texto ? ' title="'+escapeAttr(fer.texto)+'"' : '')+'>';
                        html+='<span class="vct-agenda-daynum">'+dayNum+'</span>';
                        if(fer && fer.texto){
                            html+='<span class="vct-agenda-holiday-label">'+escapeHtml(fer.texto)+'</span>';
                        }
                        if(hasActivities) html+=activityBadges(key,true);
                        html+='</td>';
                    }
                    dayNum++;
                }
                html+="</tr>";
            }
            html+="</tbody></table>";
            paneEl.innerHTML=html;

            paneEl.querySelectorAll("[data-vct-agenda-day]").forEach(function(cell){
                cell.addEventListener("click", function(){
                    var parts=cell.getAttribute("data-vct-agenda-day").split("-");
                    openDayModal(new Date(parseInt(parts[0],10),parseInt(parts[1],10)-1,parseInt(parts[2],10)));
                });
            });
        }

        function renderWeek(){
            var start=addDays(state.cursor, -state.cursor.getDay());
            var end=addDays(start,6);
            var label=start.getDate()+" "+MESES[start.getMonth()].substr(0,3)+" - "+end.getDate()+" "+MESES[end.getMonth()].substr(0,3)+" "+end.getFullYear();
            titleEl.textContent=label;

            var html='<div class="vct-agenda-weeklist">';
            for(var i=0;i<7;i++){
                var d=addDays(start,i);
                var key=dateKey(d);
                var fer=feriados[key];
                var isToday=sameDay(d,today);
                var isPastDay=isPast(d);
                var isWeekendDay=(i===0||i===6);

                html+='<div class="vct-agenda-weekrow'+(isPastDay?" vct-agenda-cell-past":"")+(isWeekendDay?" vct-agenda-cell-weekend":"")+'" data-vct-agenda-day="'+key+'">';
                html+='<div class="vct-agenda-weekrow-date'+(isToday?" is-today":"")+'">';
                html+='<span class="vct-agenda-weekrow-dayname">'+DIAS_CORTOS[i].substr(0,3)+'</span>';
                html+='<span class="vct-agenda-weekrow-daynum">'+d.getDate()+'</span>';
                html+='<span class="vct-agenda-weekrow-month">'+MESES[d.getMonth()].substr(0,3)+'</span>';
                html+='</div>';

                if(hasActivities){
                    html+='<div class="vct-agenda-weekrow-card">'+((activities[key]||[]).length?activityBadges(key):'<span class="vct-agenda-event-detail">Sin visitas</span>')+'</div>';
                }else if(fer && fer.texto){
                    var esPuente=(String(fer.tipo)==="2");
                    html+='<div class="vct-agenda-weekrow-card'+(esPuente?" is-movible":" is-fijo")+'">';
                    html+='<span class="vct-agenda-weekrow-badge">'+(esPuente?"Movible":"Fijo")+'</span>';
                    html+='<span class="vct-agenda-weekrow-text">'+escapeHtml(fer.texto)+'</span>';
                    html+='</div>';
                }else{
                    html+='<div class="vct-agenda-weekrow-card is-empty">Sin feriados</div>';
                }
                html+='</div>';
            }
            html+='</div>';
            paneEl.innerHTML=html;

            paneEl.querySelectorAll("[data-vct-agenda-day]").forEach(function(cell){
                cell.addEventListener("click", function(){
                    var parts=cell.getAttribute("data-vct-agenda-day").split("-");
                    openDayModal(new Date(parseInt(parts[0],10),parseInt(parts[1],10)-1,parseInt(parts[2],10)));
                });
            });
        }

        function renderDay(){
            var d=state.cursor;
            var key=dateKey(d);
            var fer=feriados[key];
            titleEl.textContent=DIAS_CORTOS[d.getDay()]+" "+d.getDate()+" de "+MESES[d.getMonth()]+" "+d.getFullYear();

            var isPastDay=isPast(d);
            var html='<div class="vct-agenda-day'+(isPastDay?" vct-agenda-cell-past":"")+'" data-vct-agenda-day="'+key+'">';
            html+='<div class="vct-agenda-day-num">'+d.getDate()+'</div>';
            html+='<div class="vct-agenda-day-name">'+DIAS_CORTOS[d.getDay()]+" de "+MESES[d.getMonth()]+" de "+d.getFullYear()+'</div>';
            if(hasActivities){
                html+=((activities[key]||[]).length?activityBadges(key):'<p class="vct-agenda-event-detail">Sin visitas en esta fecha.</p>');
            }else if(fer && fer.texto){
                var tipoClass=(String(fer.tipo)==="2") ? "vct-agenda-movible" : "vct-agenda-fijo";
                var tipoLabel=(String(fer.tipo)==="2") ? "Feriado movible" : "Feriado fijo";
                html+='<div class="vct-agenda-day-holiday '+tipoClass+'">'+tipoLabel+' · '+escapeHtml(fer.texto)+'</div>';
                if(canEdit && !isPastDay) html+='<div class="vct-agenda-day-hint">Click para eliminar este feriado.</div>';
            }else if(canEdit && !isPastDay){
                html+='<div class="vct-agenda-day-hint">Click para cargar un feriado en esta fecha.</div>';
            }
            if(!hasActivities) html+='<div class="vct-agenda-day-placeholder">Próximamente: agenda de consultores para este día.</div>';
            html+='</div>';
            paneEl.innerHTML=html;

            var dayCard=paneEl.querySelector("[data-vct-agenda-day]");
            if(dayCard){
                dayCard.addEventListener("click", function(){ openDayModal(d); });
            }
        }

        function syncJumpSelects(){
            selMonth.value=String(state.cursor.getMonth()+1);
            selYear.value=String(state.cursor.getFullYear());
            if(typeof window.initVctCustomSelects==="function") window.initVctCustomSelects(root);
        }

        function render(){
            syncJumpSelects();
            if(state.view==="month") renderMonth();
            else if(state.view==="week") renderWeek();
            else renderDay();
        }

        function setView(view){
            state.view=view;
            for(var i=0;i<viewButtons.length;i++){
                var isActive=viewButtons[i].getAttribute("data-vct-agenda-view")===view;
                viewButtons[i].classList.toggle("is-active",isActive);
            }
            render();
        }

        function goPrev(){
            if(state.view==="month") state.cursor=new Date(state.cursor.getFullYear(),state.cursor.getMonth()-1,1);
            else if(state.view==="week") state.cursor=addDays(state.cursor,-7);
            else state.cursor=addDays(state.cursor,-1);
            fillYearSelect();
            render();
        }
        function goNext(){
            if(state.view==="month") state.cursor=new Date(state.cursor.getFullYear(),state.cursor.getMonth()+1,1);
            else if(state.view==="week") state.cursor=addDays(state.cursor,7);
            else state.cursor=addDays(state.cursor,1);
            fillYearSelect();
            render();
        }

        btnPrev.addEventListener("click", goPrev);
        btnNext.addEventListener("click", goNext);
        for(var v=0; v<viewButtons.length; v++){
            viewButtons[v].addEventListener("click", function(ev){
                setView(ev.currentTarget.getAttribute("data-vct-agenda-view"));
            });
        }
        selMonth.addEventListener("change", function(){
            var m=parseInt(selMonth.value,10), y=state.cursor.getFullYear();
            state.cursor=new Date(y,m-1,Math.min(state.cursor.getDate(),new Date(y,m,0).getDate()));
            render();
        });
        selYear.addEventListener("change", function(){
            var y=parseInt(selYear.value,10), m=state.cursor.getMonth();
            state.cursor=new Date(y,m,Math.min(state.cursor.getDate(),new Date(y,m+1,0).getDate()));
            render();
        });

        fillYearSelect();
        render();
    }

    /* Previsualizacion en vivo dentro del drawer "Nuevo feriado": el
       formulario solo tiene 3 campos y el drawer queda con mucho espacio
       vacio (@LAYOUT='DRAWER' es panel completo, no se achica solo por
       tener pocos campos). Se corre una sola vez -- los inputs ya estan
       en el DOM aunque el drawer este cerrado, VCT_MAIN_RENDER_FORM los
       renderiza siempre, solo los oculta visualmente hasta que se abre. */
    function enhanceFeriadoDrawer(){
        var modal=document.getElementById("vctAgendaFeriadoModal");
        if(!modal || modal.getAttribute("data-vct-agenda-enhanced")==="1") return;

        var dateInput=modal.querySelector('[name="SP.TEXTO01"]');
        var grid=modal.querySelector(".vct-form-grid");
        if(!dateInput || !grid) return;

        modal.setAttribute("data-vct-agenda-enhanced","1");

        var preview=document.createElement("div");
        preview.className="vct-agenda-drawer-preview";
        grid.parentNode.insertBefore(preview, grid.nextSibling);

        /* El campo Tipo se ve como un <select> pero es un widget propio
           (vct-form-select-trigger) que vct-main.js arma recien la
           primera vez que se abre el drawer -- al cargar la pagina
           .vct-form-select-value todavia puede no existir. Por eso se
           busca de nuevo en cada update() en vez de guardarlo una sola
           vez, y si no existe se asume "Fijo" (el default del form). El
           <input name="SP.TEXTO02"> real queda oculto y nunca cambia su
           .value hasta el submit -- lo unico que cambia en vivo es el
           texto de ese span. Confirmado inspeccionando el HTML real. */
        var observer=null;
        var OBSERVE_OPTS={ characterData:true, childList:true, subtree:true };

        function setPreview(html){
            /* preview vive adentro del propio modal observado -- si no
               se pausa la observacion mientras se escribe, cada update()
               dispara otra mutacion sobre si mismo (bucle). */
            if(observer) observer.disconnect();
            preview.innerHTML=html;
            if(observer) observer.observe(modal, OBSERVE_OPTS);
        }

        function update(){
            var val=dateInput.value;
            if(!val){
                setPreview('<span>Elegí una fecha para ver el resumen</span>');
                return;
            }
            var parts=val.split("-");
            var d=new Date(parseInt(parts[0],10),parseInt(parts[1],10)-1,parseInt(parts[2],10));
            if(isNaN(d.getTime())){
                setPreview('<span>Elegí una fecha para ver el resumen</span>');
                return;
            }
            var label=DIAS_CORTOS[d.getDay()]+" "+d.getDate()+" de "+MESES[d.getMonth()]+" de "+d.getFullYear();
            var tipoValueEl=modal.querySelector(".vct-form-select-value");
            var esPuente=tipoValueEl && (tipoValueEl.textContent||"").indexOf("Movible")!==-1;
            var tipoClass=esPuente?"is-movible":"is-fijo";
            var tipoLabel=esPuente?"Movible":"Fijo";
            setPreview('<span>'+label+'</span><span class="vct-agenda-drawer-preview-badge '+tipoClass+'">'+tipoLabel+'</span>');
        }

        dateInput.addEventListener("change", update);
        dateInput.addEventListener("input", update);
        update();

        /* Se observa el modal entero (no solo el span de Tipo, que puede
           no existir todavia) para agarrar tanto la creacion tardia del
           widget como los cambios de texto posteriores. */
        try{
            observer=new MutationObserver(update);
            observer.observe(modal, OBSERVE_OPTS);
        }catch(e){
            setInterval(update, 300);
        }
    }

    function scan(){
        var roots=document.querySelectorAll("[data-vct-agenda-root]");
        for(var i=0;i<roots.length;i++) initAgenda(roots[i]);
        enhanceFeriadoDrawer();
    }

    if(document.readyState==="loading"){
        document.addEventListener("DOMContentLoaded", scan);
    }else{
        scan();
    }

    /* Reintento por si el contenido llega via navegacion interna del
       portal (sin refresh completo de la pagina). */
    document.addEventListener("vct:content-loaded", scan);
})();

/* ============== [AGENDA CONSULTOR] ex vct-agenda-consultor.js ============== */
/* vct-agenda-consultor.js - v15
   ============================================================================
   Agenda del consultor (dbo.VCT_MAIN_AGENDA_CONSULTOR). Reusa la estetica del
   calendario de feriados (clases de vct-agenda.css) pero pinta, por dia, el
   ESTADO del consultor que arma VCT_FN_AGENDA_CONSULTOR_RANGO:

     NO_CARGADO (blanco)  DISPONIBLE (azul)  ASIGNADO (verde, de las visitas)
     LICENCIA (rosa)  OCUPADO/personal (gris)  POTENCIAL (naranja)
     ORGANISMO (teal)  OBSERVACION (coral)  FERIADO_FIJO (rojo)  FERIADO_MOV (violeta)

   El SP manda todos los dias de una ventana amplia en data-vct-agc-dias (JSON);
   aca navegamos los meses sin ir al server. Round-trips: cambiar de consultor
   (VE_TODO) y guardar/eliminar una fecha (modal), via newTaskForContactWithParams.

   v2 = alta/edicion por MODAL con TIPO (campos dinamicos + validaciones).
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctAgcLoaded) return;
    window.__vctAgcLoaded = true;

    var MESES = ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"];
    var DIAS_ABREV = ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"];
    var DIAS_LARGO = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"];

    /* tipos cargables desde el modal (DISPONIBLE, POTENCIAL y ORGANISMO llevan horas) */
    var TIPOS = [
        { v:"DISPONIBLE",  label:"Disponible",                need:"horas" },
        { v:"LICENCIA",    label:"Licencia",                  need:"motivo" },
        { v:"OCUPADO",     label:"Ocupado / personal",        need:"" },
        { v:"POTENCIAL",   label:"Potencial",                 need:"desc" },
        { v:"ORGANISMO",   label:"Organismo de certificación", need:"desc" },
        { v:"OBSERVACION", label:"Observación",               need:"desc" }
    ];
    var MOTIVOS = ["Vacaciones","Médica"];

    function pad(n){ return (n<10?"0":"")+n; }
    function dateKey(d){ return d.getFullYear()+"-"+pad(d.getMonth()+1)+"-"+pad(d.getDate()); }
    function sameDay(a,b){ return a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate(); }
    function addDays(d,n){ var x=new Date(d); x.setDate(x.getDate()+n); return x; }
    function esc(s){ return String(s==null?"":s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;"); }
    function escAttr(s){ return esc(s).replace(/"/g,"&quot;"); }
    function fmtH(n){ n = +n||0; return (Math.round(n*10)/10).toString(); }

    function clsOf(e){
        e = String(e||"NO_CARGADO").toUpperCase();
        if (e==="FERIADO_FIJO") return "vct-agc-feriado-fijo";
        if (e==="FERIADO_MOV")  return "vct-agc-feriado-mov";
        return "vct-agc-" + e.toLowerCase();
    }
    function isFeriado(e){ return /^FERIADO/.test(String(e||"").toUpperCase()); }
    function tipoLabel(v){ for(var i=0;i<TIPOS.length;i++){ if(TIPOS[i].v===v) return TIPOS[i].label; } return v||""; }
    function estadoLabel(e){
        switch(String(e||"").toUpperCase()){
            case "DISPONIBLE":   return "Disponible";
            case "ASIGNADO":     return "Asignado";
            case "LICENCIA":     return "Licencia";
            case "OCUPADO":      return "Ocupado / personal";
            case "POTENCIAL":    return "Potencial";
            case "ORGANISMO":    return "Organismo de certificación";
            case "OBSERVACION":  return "Observación";
            case "FERIADO_FIJO": return "Feriado nacional";
            case "FERIADO_MOV":  return "Feriado movible";
            default:             return "No cargado";
        }
    }

    function boot(){
        document.querySelectorAll("[data-vct-agc-root]").forEach(function(root){
            if (root.getAttribute("data-vct-agc-inited")==="1") return;
            root.setAttribute("data-vct-agc-inited","1");
            init(root);
        });
    }

    function init(root){
        var today = new Date(); today.setHours(0,0,0,0);

        /* datos: {f,e,h,n,t,mo,de} por fecha */
        var dias = {};
        try {
            var raw = root.getAttribute("data-vct-agc-dias") || "[]";
            JSON.parse(raw).forEach(function(r){ dias[r.f] = r; });
        } catch(e){ dias = {}; }

        var paneEl   = root.querySelector("[data-vct-agc-pane]");
        var statsEl  = root.querySelector("[data-vct-agc-stats]");
        var titleEl  = root.querySelector("[data-vct-agc-title]");
        var selMonth = root.querySelector("[data-vct-agc-month]");
        var selYear  = root.querySelector("[data-vct-agc-year]");
        var selCons  = root.querySelector("[data-vct-agc-select-cons]");
        var btnPrev  = root.querySelector("[data-vct-agc-prev]");
        var btnNext  = root.querySelector("[data-vct-agc-next]");
        var viewBtns = root.querySelectorAll("[data-vct-agc-view]");

        /* Mes y anio nativos: el enhancer antiguo confunde wrappers adyacentes. */
        [selMonth,selYear].forEach(function(select){
            if(!select)return;
            var wrapper=select.nextElementSibling;
            if(wrapper&&wrapper.classList.contains("vct-custom-select-wrapper"))wrapper.remove();
            select.dataset.vctCustomInit="true";
            select.setAttribute("data-vct-native","true");
            select.style.removeProperty("display");
        });
        var canEdit = root.getAttribute("data-vct-agc-can-edit")==="1";
        var consId  = root.getAttribute("data-vct-agc-cons") || "";

        /* reload al cambiar de consultor (solo VE_TODO). Separador de start_params = ';' */
        if (selCons){
            selCons.addEventListener("change", function(){
                var id = selCons.value || "";
                if (typeof window.newTaskForContactWithParams !== "function") return;
                if (typeof window.vctSetActiveModule === "function") { try { vctSetActiveModule("9"); } catch(e){} }
                newTaskForContactWithParams("VOCATURO", "ACTION=AGENDA_CONSULTOR;IDSELEC01=" + id, "VCT_GESTION", "Agenda");
            });
        }

        if (!paneEl) return; /* sin consultor elegido: solo queda el prompt */

        var state = { cursor: new Date(today), view: "month" };

        /* dia sin registro = NO_CARGADO (blanco), tambien los fines de semana */
        function dayInfo(d){
            var k = dateKey(d);
            var r = dias[k];
            if (r) return r;
            return { f:k, e:"NO_CARGADO", h:0, n:"", t:"", mo:"", de:"" };
        }

        /* ---- selects de navegacion ----
           Las opciones de AÑO las genera el SP (server-side) para que el widget
           custom (VCT Select) las tenga al inicializarse. Aca NO se tocan las
           opciones (si el JS las reescribe, el widget queda desincronizado). */
        var syncing = false;
        function syncSelects(){
            syncing = true;
            if (selMonth){
                selMonth.value = String(state.cursor.getMonth()+1);
                try { selMonth.dispatchEvent(new Event("change", { bubbles:true })); } catch(e){}
            }
            if (selYear){
                selYear.value = String(state.cursor.getFullYear());
                try { selYear.dispatchEvent(new Event("change", { bubbles:true })); } catch(e){}
            }
            syncing = false;
        }

        /* ---- stats del mes visible ---- */
        function renderStats(){
            if (!statsEl) return;
            var y=state.cursor.getFullYear(), m=state.cursor.getMonth();
            var dispD=0, dispH=0, asigD=0, noDispD=0, ferD=0;
            var dim=new Date(y, m+1, 0).getDate();
            for(var i=1;i<=dim;i++){
                var r=dayInfo(new Date(y,m,i)), e=String(r.e).toUpperCase();
                if (e==="DISPONIBLE"){ dispD++; dispH += +r.h||0; }
                else if (e==="ASIGNADO"){ asigD++; }
                else if (e==="LICENCIA" || e==="OCUPADO") { noDispD++; }
                else if (isFeriado(e)) { ferD++; }
            }
            /* mismo componente que la pantalla Proyectos: .vct-soft-kpi
               (icono en caja de color a la izq, titulo + numero grande + ayuda).
               Colores Vocaturo: is-blue / is-green / is-orange / is-purple. */
            function tile(variant,label,val,help,icon){
                return '<article class="vct-soft-kpi '+variant+'">'
                     + '<span class="vct-soft-kpi-icon" data-vct-icon="'+icon+'"></span>'
                     + '<div class="vct-soft-kpi-copy">'
                     +   '<span class="vct-soft-kpi-label">'+label+'</span>'
                     +   '<strong class="vct-soft-kpi-value">'+val+'</strong>'
                     +   '<span class="vct-soft-kpi-help">'+help+'</span>'
                     + '</div></article>';
            }
            statsEl.innerHTML =
                  tile("is-blue","Disponible", dispD, fmtH(dispH)+"h en el mes", "check")
                + tile("is-green","Asignado", asigD, "día(s) con visita", "briefcase")
                + tile("is-orange","No disponible", noDispD, "licencia / ocupado", "clock-3")
                + tile("is-purple","Feriados", ferD, "en el mes", "calendar");
            if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(statsEl);
        }

        /* ---- celda contenido ---- */
        function cellBadge(r){
            var e=String(r.e||"").toUpperCase();
            if (e==="NO_CARGADO") return "";
            var note = r.n ? esc(r.n) : estadoLabel(e);
            var h = (e==="ASIGNADO"||e==="DISPONIBLE"||e==="POTENCIAL"||e==="ORGANISMO") && (+r.h>0) ? ' · '+fmtH(r.h)+'h' : '';
            return '<span class="vct-agc-cell-note">'+note+h+'</span>';
        }

        /* ---- vistas ---- */
        function renderMonth(){
            var year=state.cursor.getFullYear(), month=state.cursor.getMonth()+1;
            titleEl.textContent=MESES[month-1]+" "+year;
            var first=new Date(year,month-1,1), startW=first.getDay();
            var dim=new Date(year,month,0).getDate();
            var totalCells=Math.ceil((startW+dim)/7)*7, dayNum=1-startW;

            var html='<table class="vct-agenda-table vct-agc-table"><thead><tr>'
                + DIAS_ABREV.map(function(d){ return "<th>"+d+"</th>"; }).join("") + '</tr></thead><tbody>';
            for(var w=0; w<totalCells/7; w++){
                html+="<tr>";
                for(var dd=0; dd<7; dd++){
                    if(dayNum<1 || dayNum>dim){ html+='<td class="vct-agenda-cell vct-agenda-cell-empty"></td>'; }
                    else{
                        var cd=new Date(year,month-1,dayNum), k=dateKey(cd), r=dayInfo(cd);
                        var isToday=sameDay(cd,today);
                        var cls="vct-agenda-cell "+clsOf(r.e)+(isToday?" vct-agenda-cell-today":"");
                        html+='<td class="'+cls+'" data-vct-agc-day="'+k+'"'+(r.n?' title="'+escAttr(r.n)+'"':'')+'>';
                        html+='<span class="vct-agenda-daynum">'+dayNum+'</span>';
                        html+=cellBadge(r);
                        html+='</td>';
                    }
                    dayNum++;
                }
                html+="</tr>";
            }
            html+="</tbody></table>";
            paneEl.innerHTML=html;
            bindDayClicks();
        }

        /* vista SEMANA estilo Google Calendar: 7 columnas (encabezado dia/numero
           con "hoy" marcado) y, por dia, el ESTADO como entrada con sus horas.
           Clic en la columna abre el modal (crear/editar), via bindDayClicks. */
        function renderWeek(){
            var start=addDays(state.cursor, -state.cursor.getDay()), end=addDays(start,6);
            titleEl.textContent=start.getDate()+" "+MESES[start.getMonth()].substr(0,3)+" - "+end.getDate()+" "+MESES[end.getMonth()].substr(0,3)+" "+end.getFullYear();
            var head='<div class="vct-agc-week-head">';
            var body='<div class="vct-agc-week-body">';
            for(var i=0;i<7;i++){
                var d=addDays(start,i), k=dateKey(d), r=dayInfo(d), isToday=sameDay(d,today);
                var e=String(r.e||"").toUpperCase(), isWknd=(d.getDay()===0||d.getDay()===6);
                head+='<div class="vct-agc-wday'+(isToday?" is-today":"")+'">'
                    + '<span class="vct-agc-wday-name">'+DIAS_ABREV[i]+'</span>'
                    + '<span class="vct-agc-wday-num">'+d.getDate()+'</span></div>';
                var entry='';
                if (e!=="NO_CARGADO"){
                    var hrs=(e==="ASIGNADO"||e==="DISPONIBLE"||e==="POTENCIAL"||e==="ORGANISMO") && (+r.h>0)
                            ? '<span class="vct-agc-wentry-h">'+fmtH(r.h)+' h</span>' : '';
                    entry='<div class="vct-agc-wentry '+clsOf(r.e)+'">'
                        + '<span class="vct-agc-wentry-label">'+estadoLabel(r.e)+'</span>'
                        + (r.n ? '<span class="vct-agc-wentry-note">'+esc(r.n)+'</span>' : '')
                        + hrs + '</div>';
                }
                body+='<div class="vct-agc-wcol'+(isWknd?" is-wknd":"")+(isToday?" is-today":"")+'"'
                    + ' data-vct-agc-day="'+k+'"'+(r.n?' title="'+escAttr(r.n)+'"':'')+'>'+entry+'</div>';
            }
            head+='</div>'; body+='</div>';
            paneEl.innerHTML='<div class="vct-agc-week">'+head+body+'</div>';
            bindDayClicks();
        }

        function renderDay(){
            var d=state.cursor, r=dayInfo(d), key=dateKey(d), e=String(r.e).toUpperCase();
            titleEl.textContent=DIAS_LARGO[d.getDay()]+" "+d.getDate()+" de "+MESES[d.getMonth()]+" "+d.getFullYear();
            var html='<div class="vct-agenda-day vct-agc-dayview '+clsOf(r.e)+'">';
            html+='<div class="vct-agenda-day-num">'+d.getDate()+'</div>';
            html+='<div class="vct-agenda-day-name">'+DIAS_LARGO[d.getDay()]+'</div>';
            html+='<div class="vct-agc-dayview-badge"><span class="vct-agc-badge '+clsOf(r.e)+'">'+estadoLabel(r.e)+'</span></div>';
            if (r.n) html+='<div class="vct-agc-dayview-note">'+esc(r.n)+'</div>';
            if ((e==="ASIGNADO"||e==="DISPONIBLE") && +r.h>0)
                html+='<div class="vct-agc-dayview-hours">'+fmtH(r.h)+'h</div>';

            if (canEdit && consId && !isFeriado(e)){
                html+='<div class="vct-agc-edit">'
                    + '<button type="button" class="vct-btn vct-btn-primary vct-agc-btn-edit" data-vct-agc-edit-open>'
                    + (r.t ? 'Editar fecha' : 'Agregar fecha') + '</button></div>';
            }
            html+='</div>';
            paneEl.innerHTML=html;

            var eBtn=paneEl.querySelector("[data-vct-agc-edit-open]");
            if (eBtn) eBtn.addEventListener("click", function(){ openModal(key, r); });
        }

        function bindDayClicks(){
            paneEl.querySelectorAll("[data-vct-agc-day]").forEach(function(cell){
                cell.addEventListener("click", function(){
                    var key=cell.getAttribute("data-vct-agc-day"), p=key.split("-");
                    var dObj=new Date(+p[0], +p[1]-1, +p[2]);
                    var r=dayInfo(dObj);
                    if (canEdit && consId && !isFeriado(r.e)) { openModal(key, r); }
                    else { state.cursor=dObj; setView("day"); render(); }
                });
            });
        }

        /* ---- guardar / eliminar via tarea nueva ---- */
        function saveFecha(fecha, opt){
            opt = opt || {};
            if (typeof window.newTaskForContactWithParams !== "function") return;
            if (typeof window.vctSetActiveModule === "function") { try { vctSetActiveModule("9"); } catch(e){} }
            var clean=function(s){ return String(s==null?"":s).replace(/[;=+]/g," ").trim().slice(0,400); };
            /* IMPORTANTE: NO enviar pares con valor vacio (ej. "TEXTO04=") porque
               rompen el parseo de start_params en el server y el guardado se pierde.
               Solo se agregan los campos con contenido. */
            var parts = ["ACTION=AGENDA_CONSULTOR", "IDSELEC01=" + consId, "TEXTO01=" + fecha];
            if (opt.del) {
                parts.push("FLAG02=1");
            } else {
                parts.push("FLAG01=1");
                var add=function(k,v){ v=clean(v); if (v!=="") parts.push(k + "=" + v); };
                add("TEXTO03", opt.tipo);     /* tipo */
                add("TEXTO02", opt.motivo);   /* motivo (licencia) */
                add("TEXTO04", opt.desc);     /* descripcion */
                add("TEXTO05", opt.horas);    /* horas: disponible, potencial u organismo */
            }
            newTaskForContactWithParams("VOCATURO", parts.join(";"), "VCT_GESTION", "Agenda");
        }

        /* ---- MODAL de alta/edicion ---- */
        function openModal(key, r){
            r = r || {};
            var p=key.split("-"), dObj=new Date(+p[0],+p[1]-1,+p[2]);
            var fechaTxt = DIAS_LARGO[dObj.getDay()]+", "+dObj.getDate()+" de "+MESES[dObj.getMonth()]+" "+dObj.getFullYear();
            var exists = !!(r.t && String(r.t).length);

            var opts = '<option value="">Elegí un tipo...</option>';
            TIPOS.forEach(function(t){ opts += '<option value="'+t.v+'">'+esc(t.label)+'</option>'; });
            var motOpts = '<option value="">Elegí un motivo...</option>';
            MOTIVOS.forEach(function(m){ motOpts += '<option value="'+esc(m)+'">'+esc(m)+'</option>'; });

            var ov=document.createElement("div");
            ov.className="vct-modal vct-form-shell vct-form-compact is-open vct-agc-modal-ov";
            ov.innerHTML =
                '<div class="vct-modal-dialog vct-agc-modal" role="dialog" aria-modal="true" aria-label="Fecha del consultor">'
              + '<div class="vct-modal-header vct-form-header vct-agc-modal-head">'
              +   '<span class="vct-form-header-icon"><span data-vct-icon="calendar"></span></span>'
              +   '<div class="vct-form-header-copy"><h3 class="vct-modal-title vct-agc-modal-title">'+(exists?'Editar':'Agregar')+' fecha</h3></div>'
              +   '<button type="button" class="vct-form-close vct-agc-modal-x" data-x aria-label="Cerrar"><span data-vct-icon="x"></span></button>'
              + '</div>'
              + '<div class="vct-modal-body vct-form-body vct-agc-modal-body">'
              +   '<div class="vct-agc-field">'
              +     '<label class="vct-label vct-agc-flabel">Fecha</label>'
              +     '<input type="text" class="vct-input vct-agc-fecha-ro" value="'+escAttr(fechaTxt)+'" readonly>'
              +   '</div>'
              +   '<div class="vct-agc-field">'
              +     '<label class="vct-label vct-agc-flabel">Tipo <i class="vct-agc-req">*</i></label>'
              +     '<select class="vct-select" data-vct-native="true" data-vct-custom-init="true" data-f-tipo>'+opts+'</select>'
              +   '</div>'
              +   '<div class="vct-agc-field" data-wrap-motivo hidden>'
              +     '<label class="vct-label vct-agc-flabel">Motivo <i class="vct-agc-req">*</i></label>'
              +     '<select class="vct-select" data-vct-native="true" data-vct-custom-init="true" data-f-motivo>'+motOpts+'</select>'
              +   '</div>'
              +   '<div class="vct-agc-field" data-wrap-desc hidden>'
              +     '<label class="vct-label vct-agc-flabel">Descripción <i class="vct-agc-req">*</i></label>'
              +     '<input type="text" class="vct-input" data-f-desc maxlength="400" placeholder="Detalle de la fecha">'
              +   '</div>'
              +   '<div class="vct-agc-field" data-wrap-horas hidden>'
              +     '<label class="vct-label vct-agc-flabel">Horas <i class="vct-agc-req" data-horas-req>*</i></label>'
              +     '<input type="number" class="vct-input" data-f-horas min="0" max="24" step="0.5" value="8">'
              +   '</div>'
              +   '<p class="vct-agc-modal-err" data-err hidden></p>'
              + '</div>'
              + '<div class="vct-modal-footer vct-form-footer vct-agc-modal-foot">'
              +   '<div class="vct-agc-modal-foot-l">'
              +     (exists ? '<button type="button" class="vct-btn vct-agc-btn-del" data-del>Eliminar</button>' : '')
              +   '</div>'
              +   '<div class="vct-agc-modal-foot-r">'
              +     '<button type="button" class="vct-btn vct-btn-secondary" data-cancel>Cancelar</button>'
              +     '<button type="button" class="vct-btn vct-btn-primary" data-save>Guardar</button>'
              +   '</div>'
              + '</div>'
              + '</div>';
            var wasModalOpen = document.body.classList.contains("vct-modal-open");
            document.body.classList.add("vct-modal-open");
            document.body.appendChild(ov);

            var selTipo = ov.querySelector("[data-f-tipo]");
            var selMot  = ov.querySelector("[data-f-motivo]");
            var inpDesc = ov.querySelector("[data-f-desc]");
            var inpHor  = ov.querySelector("[data-f-horas]");
            var wrapMot = ov.querySelector("[data-wrap-motivo]");
            var wrapDesc= ov.querySelector("[data-wrap-desc]");
            var wrapHor = ov.querySelector("[data-wrap-horas]");
            var errEl   = ov.querySelector("[data-err]");

            function permitsHours(t){ return t === "DISPONIBLE" || t === "POTENCIAL" || t === "ORGANISMO"; }
            var savedHours = r.hc != null ? r.hc : r.h;
            var lastAvailableHours = (permitsHours(r.t) && +savedHours > 0) ? fmtH(savedHours) : "8";
            var previousTipo = "";
            var hoursRequired = ov.querySelector("[data-horas-req]");
            function syncFields(){
                var t = selTipo.value, available = permitsHours(t);
                if (permitsHours(previousTipo) && isFinite(+inpHor.value) && +inpHor.value > 0)
                    lastAvailableHours = inpHor.value;
                wrapMot.hidden = t !== "LICENCIA";
                wrapDesc.hidden = !t || t === "DISPONIBLE" || t === "LICENCIA";
                inpDesc.required = !!t && t !== "DISPONIBLE" && t !== "LICENCIA";
                wrapHor.hidden = !t;
                inpHor.disabled = !available;
                inpHor.required = available;
                hoursRequired.hidden = !available;
                inpHor.value = available ? lastAvailableHours : "0";
                previousTipo = t;
            }
            selTipo.addEventListener("change", function(){ errEl.hidden=true; syncFields(); });

            /* prefill */
            if (r.t) selTipo.value = r.t;
            if (r.mo) selMot.value = r.mo;
            if (r.de) inpDesc.value = r.de;
            if (+r.h>0) inpHor.value = fmtH(r.h);
            syncFields();
            if (window.VCT && VCT.FormSelect && typeof VCT.FormSelect.init === "function") VCT.FormSelect.init(ov);
            ov.querySelectorAll(".vct-form-select").forEach(function(wrap){
                if (wrap.__vctPortalMenu) wrap.__vctPortalMenu.classList.add("vct-agc-select-menu");
            });
            if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(ov);

            function close(){
                ov.querySelectorAll(".vct-form-select").forEach(function(wrap){
                    if (window.VCT && VCT.FormSelect && typeof VCT.FormSelect.close === "function") VCT.FormSelect.close(wrap);
                    var menu = wrap.__vctPortalMenu;
                    if (menu && menu.parentNode) menu.parentNode.removeChild(menu);
                });
                if (ov.parentNode) ov.parentNode.removeChild(ov);
                if (!wasModalOpen) document.body.classList.remove("vct-modal-open");
                document.removeEventListener("keydown", onKey);
            }
            function onKey(ev){ if (ev.key==="Escape") close(); }
            document.addEventListener("keydown", onKey);
            ov.addEventListener("mousedown", function(ev){ if (ev.target===ov) close(); });
            ov.querySelector("[data-x]").addEventListener("click", close);
            ov.querySelector("[data-cancel]").addEventListener("click", close);

            var delBtn = ov.querySelector("[data-del]");
            if (delBtn) delBtn.addEventListener("click", function(){
                saveFecha(key, { del:true }); close();
            });

            ov.querySelector("[data-save]").addEventListener("click", function(){
                var t = selTipo.value;
                function fail(msg){ errEl.textContent=msg; errEl.hidden=false; }
                if (!t) return fail("Elegí un tipo.");
                if (permitsHours(t) && (!isFinite(+inpHor.value) || !(+inpHor.value>0) || +inpHor.value>24 || (+inpHor.value*2)%1!==0)) return fail("Ingresá horas entre 0,5 y 24, en intervalos de media hora.");
                if (t==="LICENCIA" && !selMot.value) return fail("Elegí el motivo de la licencia.");
                if (t!=="DISPONIBLE" && t!=="LICENCIA" && !inpDesc.value.trim()) return fail("Completá la descripción.");
                saveFecha(key, {
                    tipo:   t,
                    motivo: (t==="LICENCIA") ? selMot.value : "",
                    desc:   (t!=="DISPONIBLE" && t!=="LICENCIA") ? inpDesc.value.trim() : "",
                    horas:  permitsHours(t) ? inpHor.value : "0"
                });
                close();
            });

            setTimeout(function(){ var trigger = ov.querySelector("[data-f-tipo] + .vct-form-select .vct-form-select-trigger"); (trigger || selTipo).focus(); }, 30);
        }

        function setView(v){
            state.view=v;
            viewBtns.forEach(function(b){ b.classList.toggle("is-active", b.getAttribute("data-vct-agc-view")===v); });
        }

        function render(){
            if (state.view==="week") renderWeek();
            else if (state.view==="day") renderDay();
            else renderMonth();
            renderStats();
            syncSelects();
        }

        /* ---- eventos ---- */
        if (btnPrev) btnPrev.addEventListener("click", function(){
            if (state.view==="month") state.cursor.setMonth(state.cursor.getMonth()-1);
            else if (state.view==="week") state.cursor=addDays(state.cursor,-7);
            else state.cursor=addDays(state.cursor,-1);
            render();
        });
        if (btnNext) btnNext.addEventListener("click", function(){
            if (state.view==="month") state.cursor.setMonth(state.cursor.getMonth()+1);
            else if (state.view==="week") state.cursor=addDays(state.cursor,7);
            else state.cursor=addDays(state.cursor,1);
            render();
        });
        if (selMonth) selMonth.addEventListener("change", function(){ if (syncing) return; state.cursor.setMonth(+selMonth.value-1); render(); });
        if (selYear)  selYear.addEventListener("change", function(){ if (syncing) return; state.cursor.setFullYear(+selYear.value); render(); });
        viewBtns.forEach(function(b){ b.addEventListener("click", function(){ setView(b.getAttribute("data-vct-agc-view")); render(); }); });

        render();
    }

    if (document.readyState==="loading") document.addEventListener("DOMContentLoaded", boot);
    else boot();
    if (window.MutationObserver){
        var pend=false;
        new MutationObserver(function(){
            if (pend) return; pend=true;
            setTimeout(function(){ pend=false; boot(); }, 40);
        }).observe(document.documentElement, { childList:true, subtree:true });
    }
})(window, document);
