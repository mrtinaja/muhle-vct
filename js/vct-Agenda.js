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

        var today=new Date();
        var state={ view:"month", cursor:new Date(today.getFullYear(),today.getMonth(),today.getDate()) };

        var titleEl=root.querySelector("[data-vct-agenda-title]");
        var paneEl=root.querySelector("[data-vct-agenda-view-pane]");
        var selMonth=root.querySelector("[data-vct-agenda-select-month]");
        var selYear=root.querySelector("[data-vct-agenda-select-year]");
        var btnPrev=root.querySelector("[data-vct-agenda-prev]");
        var btnNext=root.querySelector("[data-vct-agenda-next]");
        var viewButtons=root.querySelectorAll("[data-vct-agenda-view]");
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

                if(fer && fer.texto){
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
            if(fer && fer.texto){
                var tipoClass=(String(fer.tipo)==="2") ? "vct-agenda-movible" : "vct-agenda-fijo";
                var tipoLabel=(String(fer.tipo)==="2") ? "Feriado movible" : "Feriado fijo";
                html+='<div class="vct-agenda-day-holiday '+tipoClass+'">'+tipoLabel+' · '+escapeHtml(fer.texto)+'</div>';
                if(canEdit && !isPastDay) html+='<div class="vct-agenda-day-hint">Click para eliminar este feriado.</div>';
            }else if(canEdit && !isPastDay){
                html+='<div class="vct-agenda-day-hint">Click para cargar un feriado en esta fecha.</div>';
            }
            html+='<div class="vct-agenda-day-placeholder">Próximamente: agenda de consultores para este día.</div>';
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
