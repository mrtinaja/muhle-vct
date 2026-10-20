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

    /* ---- Tooltip propio tipo tarjeta para las acciones del calendario ----
       Reemplaza el title nativo: muestra titulo + responsable + area + fecha
       en una tarjetita con estilo. Se setea una sola vez, delegado en document. */
    (function setupCalTip(){
        if (typeof window==="undefined" || window.__vctCalTipReady) return;
        window.__vctCalTipReady = true;
        var tip=null;
        function el(){
            if(tip) return tip;
            tip=document.createElement("div");
            tip.className="vct-cal-tip";
            tip.setAttribute("role","tooltip");
            tip.hidden=true;
            (document.body||document.documentElement).appendChild(tip);
            return tip;
        }
        function build(t){
            var x  =t.getAttribute("data-tt-x")||"";
            var cli=t.getAttribute("data-tt-cli")||"";   /* ACCIONES: cliente */
            var proy=t.getAttribute("data-tt-proy")||""; /* ACCIONES: proyecto */
            var srv=t.getAttribute("data-tt-srv")||"";   /* ACCIONES: servicio(s) del proyecto */
            var r =t.getAttribute("data-tt-r")||"";
            var ri=t.getAttribute("data-tt-ri")||"";
            var ar=t.getAttribute("data-tt-ar")||"";
            var tm=t.getAttribute("data-tt-time")||"";   /* horario (agenda consultor) */
            var su=t.getAttribute("data-tt-sub")||"";    /* subtitulo / tipo */
            var f =t.getAttribute("data-tt-f")||"";
            var fTxt=""; if(f){ var p=f.split("-"); if(p.length===3) fTxt=p[2]+"/"+p[1]+"/"+p[0]; }
            var h, m='';
            function row(k,v){ return '<div class="vct-cal-tip-row">'+(k?'<span class="vct-cal-tip-k">'+k+'</span>':'')+'<span>'+escapeHtml(v)+'</span></div>'; }
            if(srv){
                var SVG={
                    briefcase:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="7" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>',
                    "clipboard-check":'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="8" height="4" x="8" y="2" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/></svg>',
                    users:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>'
                };
                var chips='', parts=srv.split(', ');
                for(var si=0; si<parts.length; si++){
                    var pr=parts[si].split('|'), code=(pr[0]||'').trim().toUpperCase(), nm=(pr[1]||code).trim();
                    if(!code) continue;
                    var ico=code==='AU'?'clipboard-check':code==='CA'?'users':'briefcase';
                    chips+='<span class="vct-cal-tip-svc is-'+escapeAttr(code.toLowerCase())+'" title="'+escapeAttr(nm)+'">'+SVG[ico]+'</span>';
                }
            }
            /* solo iconos, sin labels: servicio(s) + consultor en una fila */
            var icons=(chips||'')+(ri?'<span class="vct-cal-tip-ic" title="'+escapeAttr(r)+'">'+escapeHtml(ri)+'</span>':'');
            var iconRow=icons ? '<div class="vct-cal-tip-row vct-cal-tip-icons"><span class="vct-cal-tip-chips">'+icons+'</span></div>' : '';
            if(cli){
                /* ACCIONES: Cliente -> Proyecto -> Servicio(chips) -> Consultor(avatar) -> Descripcion.
                   Servicio y consultor como circulos con iniciales (nombre en el hover). */
                h='<div class="vct-cal-tip-t">'+escapeHtml(cli)+'</div>';
                if(proy) m+='<div class="vct-cal-tip-row vct-cal-tip-proy"><span>'+escapeHtml(proy)+'</span></div>';
                m+=iconRow;
                if(tm)   m+='<div class="vct-cal-tip-row vct-cal-tip-time"><span>'+escapeHtml(tm)+'</span></div>';   /* horario (visita del consultor) */
                if(x)    m+='<div class="vct-cal-tip-row vct-cal-tip-desc"><span>'+escapeHtml(x)+'</span></div>';
                if(fTxt) m+='<div class="vct-cal-tip-row vct-cal-tip-date">Vence '+escapeHtml(fTxt)+'</div>';
            } else {
                h='<div class="vct-cal-tip-t">'+escapeHtml(x)+'</div>';
                if(tm)     m+='<div class="vct-cal-tip-row vct-cal-tip-time"><span>'+escapeHtml(tm)+'</span></div>';
                if(su)     m+='<div class="vct-cal-tip-row"><span>'+escapeHtml(su)+'</span></div>';
                if(srv) m+=iconRow;
                if(r && !srv) m+='<div class="vct-cal-tip-row"><span class="vct-cal-tip-ic">'+escapeHtml(ri)+'</span><span>'+escapeHtml(r)+(ar?' <em>&middot; '+escapeHtml(ar)+'</em>':'')+'</span></div>';
                else if(ar)m+='<div class="vct-cal-tip-row"><span>'+escapeHtml(ar)+'</span></div>';
                if(fTxt)   m+='<div class="vct-cal-tip-row vct-cal-tip-date">Vence '+escapeHtml(fTxt)+'</div>';
            }
            if(m) h+='<div class="vct-cal-tip-m">'+m+'</div>';
            return h;
        }
        function place(t){
            if(!tip||tip.hidden) return;
            var r=t.getBoundingClientRect(), tw=tip.offsetWidth, th=tip.offsetHeight;
            var left=r.left+r.width/2-tw/2, top=r.top-th-8;
            if(top<6) top=r.bottom+8;
            left=Math.max(6, Math.min(left, window.innerWidth-tw-6));
            tip.style.left=Math.round(left)+"px";
            tip.style.top=Math.round(top)+"px";
        }
        function show(t){ var e=el(); e.innerHTML=build(t); e.hidden=false; place(t); }
        function hide(){ if(tip) tip.hidden=true; }
        document.addEventListener("mouseover", function(ev){
            var t=ev.target&&ev.target.closest?ev.target.closest("[data-tt]"):null;
            if(t) show(t);
        });
        document.addEventListener("mouseout", function(ev){
            var t=ev.target&&ev.target.closest?ev.target.closest("[data-tt]"):null;
            if(t){ var to=ev.relatedTarget; if(!to||!t.contains(to)) hide(); }
        });
        window.addEventListener("scroll", hide, true);
    })();

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
        /* PV_FERIADOS_V17: feriado y actividad se muestran juntos. */
        function projectHolidayBadge(fer){
            if(!root.closest("[data-vct-pv],[data-vct-acc]") || !fer || !fer.texto) return "";
            var movable=String(fer.tipo)==="2";
            return '<span class="vct-agenda-event vct-pv-calendar-holiday '+(movable?'is-movible':'is-fijo')+'">'
                +(movable?'Feriado movible':'Feriado fijo')+' · '+escapeHtml(fer.texto)+'</span>';
        }
        function activityBadges(key,compact){
            var items=activities[key]||[];
            var shown=compact&&items.length>2?items.slice(0,1):items;
            return '<div class="vct-agenda-events">'+shown.map(function(e){
                /* e.c = color por estado (Acciones: V/H/P/L); si no, tono por e.k (visitas 360) */
                var tone=e.c?(" ev-"+e.c):(e.k==="AGENDADA"?" is-planned":e.k==="REGISTRADA"?"":" is-pending");
                /* F: tooltip-tarjeta propio (data-tt-*) + badge de iniciales del responsable.
                   Sin title nativo: lo muestra el engine de tooltip de este archivo. */
                var ttAttrs=' data-tt="1" data-tt-x="'+escapeAttr(e.x)+'"'
                    +(e.cli ?' data-tt-cli="' +escapeAttr(e.cli) +'"':'')
                    +(e.proy?' data-tt-proy="'+escapeAttr(e.proy)+'"':'')
                    +(e.srv ?' data-tt-srv="' +escapeAttr(e.srv) +'"':'')
                    +(e.r ?' data-tt-r="' +escapeAttr(e.r) +'"':'')
                    +(e.ri?' data-tt-ri="'+escapeAttr(e.ri)+'"':'')
                    +(e.ar?' data-tt-ar="'+escapeAttr(e.ar)+'"':'')
                    +(e.f ?' data-tt-f="' +escapeAttr(e.f) +'"':'');
                /* la celda muestra solo el titulo; consultor y servicio van en el tooltip */
                return '<span class="vct-agenda-event'+tone+'"'+ttAttrs+'>'+escapeHtml(e.x)+'</span>';
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
            /* CAL_C_V1: sabado y domingo no se editan (ni alta ni baja), como los dias pasados */
            if(isWeekendDay && !root.closest("[data-vct-pv]")) return;

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
            if(!selYear) return;
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

                        /* en vistas de solo-lectura con eventos (Acciones / 360) no se marca el dia actual */
                        var cls="vct-agenda-cell"+(isWeekend?" vct-agenda-cell-weekend":"")+((isToday && !hasActivities)?" vct-agenda-cell-today":"")+holidayClass(fer)+((canEdit && !isPastDay)?"":" vct-agenda-cell-nocreate")+(isPastDay?" vct-agenda-cell-past":"");

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
                    html+='<div class="vct-agenda-weekrow-card">'+projectHolidayBadge(fer)+((activities[key]||[]).length?activityBadges(key):'<span class="vct-agenda-event-detail">Sin actividades del proyecto</span>')+'</div>';
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
                html+=projectHolidayBadge(fer)+((activities[key]||[]).length?activityBadges(key):'<p class="vct-agenda-event-detail">Sin actividades del proyecto en esta fecha.</p>');
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

        /* PV_CAL_SELECT_V15: widgets VCT solo en Proyecto 360.
           Cada select tiene contenedor propio para aislar el enhancer legado.
           El select sigue siendo fuente del valor y del evento change. */
        function syncProjectJump(){
            if(!root.closest("[data-vct-pv],[data-vct-acc]")) return false;
            var api=window.VCT && window.VCT.FormSelect;
            if(!api || typeof api.build!=="function") return false;
            [selMonth,selYear].forEach(function(select){
                if(!select) return;
                var holder=select.parentElement;
                if(!holder.classList.contains("vct-pv-cal-select")){
                    holder=document.createElement("span");
                    holder.className="vct-form-shell vct-pv-cal-select";
                    select.parentNode.insertBefore(holder,select);
                    holder.appendChild(select);
                }
                select.classList.add("vct-select");
                select.setAttribute("data-vct-native","true");
                select.setAttribute("data-vct-custom-init","true");
                api.build(select);
                var widget=holder.querySelector(".vct-form-select");
                if(!widget) return;
                var trigger=widget.querySelector(".vct-form-select-trigger");
                if(trigger) trigger.setAttribute("aria-label",select===selMonth ? "Mes del calendario" : "Año del calendario");
                if(widget.__vctPortalMenu) widget.__vctPortalMenu.classList.add("vct-pv-cal-select-menu");
                if(typeof api.sync==="function") api.sync(select,widget);
            });
            return true;
        }
        function syncJumpSelects(){
            if(selMonth) selMonth.value=String(state.cursor.getMonth()+1);
            if(selYear) selYear.value=String(state.cursor.getFullYear());
            if(!syncProjectJump() && typeof window.initVctCustomSelects==="function") window.initVctCustomSelects(root);
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

        if(btnPrev) btnPrev.addEventListener("click", goPrev);
        if(btnNext) btnNext.addEventListener("click", goNext);
        for(var v=0; v<viewButtons.length; v++){
            viewButtons[v].addEventListener("click", function(ev){
                setView(ev.currentTarget.getAttribute("data-vct-agenda-view"));
            });
        }
        if(selMonth) selMonth.addEventListener("change", function(){
            var m=parseInt(selMonth.value,10), y=state.cursor.getFullYear();
            state.cursor=new Date(y,m-1,Math.min(state.cursor.getDate(),new Date(y,m,0).getDate()));
            render();
        });
        if(selYear) selYear.addEventListener("change", function(){
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
        /* CIERRE_CAL_V12: conserva el input ISO y el contrato del formulario. */
        dateInput.setAttribute("data-vct-datepicker", "");
        /* PICKER_V20: CSS independiente de si el JS ya estaba inicializado. */
        if(!document.querySelector('link[data-vct-feriado-picker="20"]')){
            var pickerCss=document.createElement("link");pickerCss.rel="stylesheet";
            pickerCss.href="../css/vct-datepicker.css?v=20";
            pickerCss.setAttribute("data-vct-feriado-picker","20");document.head.appendChild(pickerCss);
        }
        function initFeriadoPicker(){
            if(window.VCT && window.VCT.Datepicker) window.VCT.Datepicker.init(modal);
            /* El formulario legacy asigna .value sin disparar change al abrir. */
            var wrap=dateInput.closest(".vct-datepicker");
            var label=wrap && wrap.querySelector(".vct-datepicker-value");
            if(label){
                var m=/^(\d{4})-(\d{2})-(\d{2})$/.exec(dateInput.value||"");
                var text=m ? m[3]+"/"+m[2]+"/"+m[1] : "Seleccionar fecha";
                if(label.textContent!==text) label.textContent=text;
                label.classList.toggle("is-placeholder",!m);
            }
        }
        var pickerApi=window.VCT && window.VCT.Datepicker;
        if(pickerApi) initFeriadoPicker();
        if(!pickerApi || !(pickerApi.version>=20)){
            var script=document.querySelector('script[data-vct-feriado-picker="20"]');
            if(!script){
                script=document.createElement("script");script.src="../js/vct-datepicker.js?v=20";
                script.setAttribute("data-vct-feriado-picker","20");
                script.addEventListener("load",initFeriadoPicker);document.head.appendChild(script);
            } else script.addEventListener("load",initFeriadoPicker);
        }

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
        var OBSERVE_OPTS={ characterData:true, childList:true, subtree:true, attributes:true, attributeFilter:["class","hidden","aria-hidden","value"] };

        function setPreview(html){
            /* preview vive adentro del propio modal observado -- si no
               se pausa la observacion mientras se escribe, cada update()
               dispara otra mutacion sobre si mismo (bucle). */
            if(observer) observer.disconnect();
            preview.innerHTML=html;
            if(observer) observer.observe(modal, OBSERVE_OPTS);
        }

        function update(){
            initFeriadoPicker();
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
        { v:"DISPONIBLE",   label:"Disponible",                need:"horas" },
        { v:"LICENCIA",     label:"Licencia",                  need:"motivo" },
        { v:"OCUPADO",      label:"Ocupado / personal",        need:"" },
        { v:"NO_DISPONIBLE",label:"No disponible",             need:"" },
        { v:"POTENCIAL",    label:"Potencial",                 need:"desc" },
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
    /* data-tt para el tooltip-tarjeta (mismo engine que 360/Feriados): cliente, proyecto, servicios y consultor asignado,
       ademas del horario y subtipo de la actividad. */
    function actTip(e){
        var tm=e.hd ? e.hd + ((e.hh && e.hh!==e.hd) ? ' – '+e.hh : '') : '';
        return ' data-tt="1" data-tt-x="'+escAttr(e.ti||'')+'"'
             + (e.cli ?' data-tt-cli="' +escAttr(e.cli) +'"':'')   /* mismo tooltip que Acciones */
             + (e.proy?' data-tt-proy="'+escAttr(e.proy)+'"':'')
             + (e.srv ?' data-tt-srv="' +escAttr(e.srv) +'"':'')
             + (e.r   ?' data-tt-r="'   +escAttr(e.r)   +'"':'')
             + (e.ri  ?' data-tt-ri="'  +escAttr(e.ri)  +'"':'')
             + (tm   ? ' data-tt-time="'+escAttr(tm)+'"'   : '')
             + (e.su ? ' data-tt-sub="' +escAttr(e.su)+'"' : '');
    }

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
            case "NO_DISPONIBLE":return "No disponible";
            case "POTENCIAL":    return "Potencial";
            case "ORGANISMO":    return "Organismo de certificación";
            case "OBSERVACION":  return "Observación";
            case "FERIADO_FIJO": return "Feriado nacional";
            case "FERIADO_MOV":  return "Feriado movible";
            default:             return "No cargado";
        }
    }

    /* ---- ACTIVIDADES con horario (vista semana estilo Google Calendar) ---- */
    var ACT_TIPOS = [
        { v:"REUNION_CLIENTE", label:"Reuniones con clientes", color:"#2563EB" },
        { v:"PROYECTO",        label:"Proyectos",              color:"#0E9F6E" },
        { v:"TAREA",           label:"Tareas",                 color:"#F59E0B" },
        { v:"CAPACITACION",    label:"Capacitaciones",         color:"#8B5CF6" },
        { v:"AUDITORIA",       label:"Auditorías",             color:"#EC4899" },
        { v:"OTRO",            label:"Otros",                  color:"#64748B" }
    ];
    function tipoColor(t){
        t = String(t||"").toUpperCase();
        for(var i=0;i<ACT_TIPOS.length;i++){ if(ACT_TIPOS[i].v===t) return ACT_TIPOS[i].color; }
        return "#64748B";
    }
    function hexToRgba(hex, a){
        hex = String(hex||"").replace("#","");
        if(hex.length===3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
        var n = parseInt(hex,16);
        if(isNaN(n)) return "rgba(100,116,139,"+a+")";
        return "rgba("+((n>>16)&255)+","+((n>>8)&255)+","+(n&255)+","+a+")";
    }
    function hmToMin(s){ var p=String(s||"0:0").split(":"); return (+p[0])*60 + (+(p[1]||0)); }
    /* mini iconos (agregar / editar) para la Agenda del consultor */
    var SVG_PLUS='<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>';
    var SVG_PEN ='<svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>';
    /* empaqueta actividades solapadas en "carriles" (left/width %) estilo GCal */
    function layoutDay(evs){
        evs = evs.slice().sort(function(a,b){ return hmToMin(a.hd)-hmToMin(b.hd) || hmToMin(a.hh)-hmToMin(b.hh); });
        var clusters=[], cur=[], curEnd=-1;
        evs.forEach(function(e){
            var s=hmToMin(e.hd), en=hmToMin(e.hh);
            if(cur.length && s>=curEnd){ clusters.push(cur); cur=[]; curEnd=-1; }
            cur.push(e); curEnd=Math.max(curEnd,en);
        });
        if(cur.length) clusters.push(cur);
        clusters.forEach(function(cl){
            var lanes=[];
            cl.forEach(function(e){
                var s=hmToMin(e.hd), en=hmToMin(e.hh), placed=false;
                for(var L=0;L<lanes.length;L++){ if(lanes[L]<=s){ e._lane=L; lanes[L]=en; placed=true; break; } }
                if(!placed){ e._lane=lanes.length; lanes.push(en); }
            });
            var N=lanes.length;
            cl.forEach(function(e){ e._lanes=N; });
        });
        return evs;
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

        /* actividades con horario: {id,f,hd,hh,t,ti,su,c} -> agrupadas por fecha */
        var actsByDay = {};
        try {
            var rawA = root.getAttribute("data-vct-agc-acts") || "[]";
            JSON.parse(rawA).forEach(function(a){ (actsByDay[a.f] = actsByDay[a.f] || []).push(a); });
        } catch(e){ actsByDay = {}; }
        function actsOf(k){ return actsByDay[k] || []; }

        /* ventana horaria de la grilla semanal (estilo Google Calendar) */
        var GRID_START = 7, GRID_END = 20, HOUR_PX = 40;

        var paneEl   = root.querySelector("[data-vct-agc-pane]");
        var statsEl  = root.querySelector("[data-vct-agc-stats]");
        var titleEl  = root.querySelector("[data-vct-agc-title]");
        var selMonth = root.querySelector("[data-vct-agc-month]");
        var selYear  = root.querySelector("[data-vct-agc-year]");
        var selCons  = root.querySelector("[data-vct-agc-select-cons]");
        var btnPrev  = root.querySelector("[data-vct-agc-prev]");
        var btnNext  = root.querySelector("[data-vct-agc-next]");
        var viewBtns = root.querySelectorAll("[data-vct-agc-view]");
        /* CONS360_V16: VCT_MAIN_CONSULTORES_V360 omite el selector de vista.
           Se agrega solo en el calendario embebido y solo si falta. */
        if(root.classList.contains("vct-agc-v360") && !viewBtns.length){
            var toolbar=root.querySelector(".vct-agenda-toolbar");
            if(toolbar){
                var toggle=document.createElement("div");
                toggle.className="vct-agenda-view-toggle";
                toggle.setAttribute("data-vct-agc-view-toggle","");
                toggle.setAttribute("role","group");
                toggle.setAttribute("aria-label","Vista del calendario del consultor");
                [["month","Mes"],["week","Semana"],["day","Día"]].forEach(function(item){
                    var button=document.createElement("button");
                    button.type="button";button.className="vct-agenda-view-btn";
                    button.setAttribute("data-vct-agc-view",item[0]);button.textContent=item[1];
                    toggle.appendChild(button);
                });
                toolbar.appendChild(toggle);
                viewBtns=root.querySelectorAll("[data-vct-agc-view]");
            }
        }

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

        var state = { cursor: new Date(today), view: "month", selDay: null };   /* todos los calendarios inician en Mes */

        /* dia sin registro = NO_CARGADO (blanco), tambien los fines de semana */
        function dayInfo(d){
            var k = dateKey(d);
            var r = dias[k];
            if (r) { if(!r.f) r.f=k; return r; }
            return { f:k, e:"NO_CARGADO", h:0, n:"", t:"", mo:"", de:"" };
        }
        /* CAL_C_V1: sabado / domingo (por la fecha aaaa-mm-dd del registro) */
        function isWkndKey(f){
            var p = String(f||"").split("-"); if(p.length<3) return false;
            var wd = new Date(+p[0], +p[1]-1, +p[2]).getDay();
            return wd===0 || wd===6;
        }
        /* CAL_C_V1: reparto de horas del dia asignado
           conf = asignado confirmado (visita CONFIRMADO o con horas registradas), pend = asignado pendiente,
           disp = lo que sigue disponible de la capacidad cargada (TIPO DISPONIBLE). Sin hcf/hpe (version vieja
           del SP) todo lo asignado cuenta como confirmado. */
        function splitOf(r){
            var e = String((r&&r.e)||"").toUpperCase(), h = +r.h||0;
            if (e!=="ASIGNADO") return null;
            var hasS = (r.hcf!=null || r.hpe!=null);
            var conf = hasS ? (+r.hcf||0) : h, pend = hasS ? (+r.hpe||0) : 0;
            if (hasS && conf+pend<=0 && h>0) conf = h;
            var disp = (String(r.t||"").toUpperCase()==="DISPONIBLE" && +r.hc>0) ? Math.max((+r.hc) - (conf+pend), 0) : 0;
            return { conf:conf, pend:pend, disp:disp };
        }
        /* franja superior de la celda (opcion C): un segmento por estado, proporcional a las horas */
        function stripHtml(r){
            var e = String((r&&r.e)||"NO_CARGADO").toUpperCase();
            if (e==="NO_CARGADO") return "";
            var sp = splitOf(r), seg = "";
            if (sp){
                if (sp.conf>0) seg += '<i class="is-asc" style="flex:'+sp.conf+'"></i>';
                if (sp.pend>0) seg += '<i class="is-asp" style="flex:'+sp.pend+'"></i>';
                if (sp.disp>0) seg += '<i class="is-disp" style="flex:'+sp.disp+'"></i>';
                if (!seg) seg = '<i class="is-asc" style="flex:1"></i>';
            } else seg = '<i class="'+clsOf(e)+'" style="flex:1"></i>';
            return '<span class="vct-cal-strip" aria-hidden="true">'+seg+'</span>';
        }
        /* dia ya transcurrido: no se puede crear ni editar (solo ver) */
        function isPastDay(r){
            var f = r && r.f; if(!f) return false;
            var p = String(f).split("-"); if(p.length<3) return false;
            var cd = new Date(+p[0], +p[1]-1, +p[2]);
            return cd < today && !sameDay(cd, today);
        }

        /* Estados que el consultor PUEDE declarar/editar (sus propios tipos).
           ASIGNADO (trabajo asignado por administracion/comercial) y los FERIADOS
           NO se editan. NO_CARGADO = dia vacio -> se puede crear. */
        function isEditableType(e){
            e = String(e||"").toUpperCase();
            return e==="DISPONIBLE" || e==="LICENCIA" || e==="OCUPADO" || e==="NO_DISPONIBLE" ||
                   e==="POTENCIAL"  || e==="ORGANISMO" || e==="OBSERVACION";
        }
        function canEditDay(r){
            if (!(canEdit && consId)) return false;
            if (isPastDay(r)) return false;                /* dias transcurridos: solo lectura */
            if (isWkndKey(r && r.f)) return false;         /* CAL_C_V1: sabado y domingo: solo lectura */
            var e = String((r&&r.e)||"NO_CARGADO").toUpperCase();
            if (isFeriado(e)) return false;
            if (e==="ASIGNADO") return false;              /* asignado por admin/comercial */
            return e==="NO_CARGADO" || isEditableType(e);  /* vacio -> crear; propios -> editar */
        }
        /* tipo vigente del dia (para editar): el TIPO guardado o, si viene vacio,
           el propio estado cuando es uno de los tipos del consultor. */
        function tipoDe(r){
            if (r && r.t && String(r.t).length) return r.t;
            var e = String((r&&r.e)||"").toUpperCase();
            return isEditableType(e) ? e : "";
        }
        /* mini boton +/lapiz (solo donde el consultor puede crear/editar) */
        function editIcon(r, key){
            if (!canEditDay(r)) return "";
            var has = !!tipoDe(r);
            return '<button type="button" class="vct-agc-dayedit-btn '+(has?'is-edit':'is-add')+'"'
                 + ' data-vct-agc-editday="'+key+'" title="'+(has?'Editar':'Agregar')+'" aria-label="'+(has?'Editar':'Agregar')+'">'
                 + (has?SVG_PEN:SVG_PLUS) + '</button>';
        }
        function bindEditIcons(){
            paneEl.querySelectorAll("[data-vct-agc-editday]").forEach(function(b){
                b.addEventListener("click", function(ev){
                    ev.stopPropagation();
                    var key=b.getAttribute("data-vct-agc-editday"), p=key.split("-");
                    openModal(key, dayInfo(new Date(+p[0],+p[1]-1,+p[2])));
                });
            });
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
            var dispD=0, dispH=0, asigD=0, noDispD=0, ferD=0, confD=0, pendD=0;
            var dim=new Date(y, m+1, 0).getDate();
            for(var i=1;i<=dim;i++){
                var r=dayInfo(new Date(y,m,i)), e=String(r.e).toUpperCase();
                if (e==="DISPONIBLE"){ dispD++; dispH += +r.h||0; }
                else if (e==="ASIGNADO"){ asigD++; var sq=splitOf(r); if(sq){ if(sq.conf>0) confD++; if(sq.pend>0) pendD++; if(sq.disp>0) dispH+=sq.disp; } }
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
                + tile("is-green","Asignado", asigD, (pendD ? confD+" confirmado(s) · "+pendD+" pendiente(s)" : "día(s) con visita"), "briefcase")
                + tile("is-orange","No disponible", noDispD, "licencia / ocupado", "clock-3")
                + tile("is-purple","Feriados", ferD, "en el mes", "calendar");
            if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(statsEl);
        }

        /* ---- celda contenido ---- */
        function cellBadge(r){
            var e=String(r.e||"").toUpperCase();
            if (e==="NO_CARGADO") return "";
            /* CAL_C_V1: asignado con reparto -> una linea por parte (confirmado / pendiente / disponible) */
            var sp=splitOf(r);
            if (sp && (sp.pend>0 || sp.disp>0)){
                var r1={}; for(var kk in r){ if(Object.prototype.hasOwnProperty.call(r,kk)) r1[kk]=r[kk]; }
                var out='';
                if (sp.conf>0){ r1.h=sp.conf; out+=cellBadgeBase(r1).replace('vct-agc-cell-note"','vct-agc-cell-note is-asc"'); }
                if (sp.pend>0){ r1.h=sp.pend; out+=cellBadgeBase(r1).replace('vct-agc-cell-note"','vct-agc-cell-note is-asp"').replace('</span>',' · pend.</span>'); }
                if (sp.disp>0) out+='<span class="vct-agc-cell-note is-disp" data-tt="1" data-tt-x="Disponible" data-tt-sub="'+fmtH(sp.disp)+'h libres de '+fmtH(r.hc)+'h cargadas">Disponible · '+fmtH(sp.disp)+'h</span>';
                return out;
            }
            return cellBadgeBase(r);
        }
        function cellBadgeBase(r){
            var e=String(r.e||"").toUpperCase();
            if (e==="NO_CARGADO") return "";
            /* preferimos la descripcion (observacion/potencial/organismo), luego la nota, luego el label */
            var note = r.de ? esc(r.de) : (r.n ? esc(r.n) : estadoLabel(e));
            var h = (e==="ASIGNADO"||e==="DISPONIBLE"||e==="POTENCIAL"||e==="ORGANISMO") && (+r.h>0) ? ' · '+fmtH(r.h)+'h' : '';
            var hrs = (+r.h>0) ? fmtH(r.h)+'h' : '';
            var ttA;
            if (r.cli || r.proy || r.srv){
                /* asignado por visita: mismo tooltip que Acciones (cliente -> proyecto -> servicio -> estado) */
                ttA = ' data-tt="1"'
                    + (r.cli ? ' data-tt-cli="' +escAttr(r.cli) +'"' : '')
                    + (r.proy? ' data-tt-proy="'+escAttr(r.proy)+'"' : '')
                    + (r.srv ? ' data-tt-srv="' +escAttr(r.srv) +'"' : '')
                    + ' data-tt-time="'+escAttr(estadoLabel(e)+(hrs?' · '+hrs:''))+'"'
                    + (r.cli?'':' data-tt-x="'+escAttr(estadoLabel(e))+'"');  /* fallback header si no hay cliente */
            } else {
                /* tooltip-tarjeta: estado + detalle + horas (en lugar del title nativo) */
                var det = r.de || r.n || '';
                var sub = det + (h ? (det?' · ':'')+fmtH(r.h)+'h' : '');
                ttA = ' data-tt="1" data-tt-x="'+escAttr(estadoLabel(e))+'"'
                    + (sub ? ' data-tt-sub="'+escAttr(sub)+'"' : '');
            }
            return '<span class="vct-agc-cell-note"'+ttA+'>'+note+h+'</span>';
        }
        /* chips de ACTIVIDADES para la celda del mes (se ven tambien en Mes) */
        function monthActs(key){
            var items=actsOf(key); if(!items.length) return "";
            items=items.slice().sort(function(a,b){ return hmToMin(a.hd)-hmToMin(b.hd); });
            var shown=items.slice(0,2), h='<div class="vct-agc-cell-acts">';
            shown.forEach(function(e){
                var c=e.c||tipoColor(e.t);
                h+='<span class="vct-agc-cell-act" style="border-left-color:'+c+';background:'+hexToRgba(c,0.12)+'"'+actTip(e)+'>'+(e.hd?'<b>'+esc(e.hd)+'</b> ':'')+esc(e.ti)+'</span>';
            });
            if(items.length>2) h+='<span class="vct-agc-cell-actmore">+'+(items.length-2)+' más</span>';
            h+='</div>';
            return h;
        }
        /* lista de ACTIVIDADES del dia (se ven tambien en Dia) */
        function dayActs(key){
            var items=actsOf(key).slice().sort(function(a,b){ return hmToMin(a.hd)-hmToMin(b.hd); });
            if(!items.length) return "";
            var h='<div class="vct-agc-dayview-acts">';
            items.forEach(function(e){
                var c=e.c||tipoColor(e.t);
                h+='<div class="vct-agc-dayview-act" style="--evc:'+c+'"'+actTip(e)+'>'
                    + (e.hd?'<span class="vct-agc-dayview-act-time">'+esc(e.hd)+' – '+esc(e.hh)+'</span>':'')
                    + '<span class="vct-agc-dayview-act-ti">'+esc(e.ti)+'</span>'
                    + (e.su?'<span class="vct-agc-dayview-act-su">'+esc(e.su)+'</span>':'')
                    + '</div>';
            });
            h+='</div>';
            return h;
        }
        function isTimed(e){ return e && e.hd && e.hd!==e.hh; }

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
                        var isToday=sameDay(cd,today), isPastCell=(cd<today && !isToday);
                        var isWknd=(cd.getDay()===0||cd.getDay()===6);
                        var cls="vct-agenda-cell "+clsOf(r.e)+(isToday?" vct-agenda-cell-today":"")+(isWknd?" is-wknd":"")+(isPastCell?" is-past":"");
                        html+='<td class="'+cls+'" data-vct-agc-day="'+k+'"'+(r.n?' title="'+escAttr(r.n)+'"':'')+'>';
                        html+='<span class="vct-agenda-daynum">'+dayNum+'</span>';
                        html+=stripHtml(r);
                        html+=cellBadge(r);
                        html+=monthActs(k);
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

        /* ===== vista SEMANA estilo Google Calendar =====
           Layout de 3 columnas: mini-mes + leyenda (izq), grilla por horas con
           bloques de actividad (centro) y panel de detalle del dia (der).
           Semana de LUNES a DOMINGO (como el mock). */
        function weekStart(d){ var x=new Date(d); x.setHours(0,0,0,0); x.setDate(x.getDate()-((x.getDay()+6)%7)); return x; }

        function miniMonthHtml(base, wkStart, wkEnd){
            var y=base.getFullYear(), m=base.getMonth();
            var first=new Date(y,m,1), startW=first.getDay(), dim=new Date(y,m+1,0).getDate();
            var h='<div class="vct-agc-mini">'
                + '<div class="vct-agc-mini-head"><button type="button" class="vct-agc-mini-nav" data-vct-agc-mini-prev>‹</button>'
                + '<span class="vct-agc-mini-title">'+MESES[m]+' '+y+'</span>'
                + '<button type="button" class="vct-agc-mini-nav" data-vct-agc-mini-next>›</button></div>'
                + '<table class="vct-agc-mini-tab"><thead><tr>'
                + ['D','L','M','M','J','V','S'].map(function(x){return '<th>'+x+'</th>';}).join("")
                + '</tr></thead><tbody><tr>';
            var cell=1-startW, total=Math.ceil((startW+dim)/7)*7;
            for(var i=0;i<total;i++){
                if(i>0 && i%7===0) h+='</tr><tr>';
                if(cell<1 || cell>dim){ h+='<td class="is-out"></td>'; }
                else{
                    var cd=new Date(y,m,cell), k=dateKey(cd);
                    var inWk = cd>=wkStart && cd<=wkEnd;
                    var cls=(sameDay(cd,today)?"is-today ":"")+(inWk?"is-wk ":"");
                    h+='<td class="'+cls.trim()+'" data-vct-agc-mini-day="'+k+'">'+cell+'</td>';
                }
                cell++;
            }
            h+='</tr></tbody></table></div>';
            return h;
        }

        function legendSideHtml(){
            var h='<div class="vct-agc-side-legend"><div class="vct-agc-side-legend-ttl">Mis agendas</div>';
            ACT_TIPOS.forEach(function(t){
                h+='<div class="vct-agc-side-legend-row"><span class="vct-agc-side-dot" style="background:'+t.color+'"></span>'+esc(t.label)+'</div>';
            });
            h+='</div>';
            return h;
        }

        function detailHtml(selD){
            var k=dateKey(selD), evs=layoutDay(actsOf(k));
            evs.sort(function(a,b){ return hmToMin(a.hd)-hmToMin(b.hd); });
            var h='<div class="vct-agc-detail-head"><span class="vct-agc-detail-ttl">'
                + DIAS_ABREV[selD.getDay()]+' '+selD.getDate()+' de '+MESES[selD.getMonth()]+'</span></div>'
                + '<div class="vct-agc-detail-list">';
            if(!evs.length){ h+='<div class="vct-agc-detail-empty">Sin actividades este día.</div>'; }
            evs.forEach(function(e){
                var c=e.c||tipoColor(e.t);
                h+='<div class="vct-agc-detail-item" style="--evc:'+c+'">'
                    + '<div class="vct-agc-detail-time">'+esc(e.hd)+' – '+esc(e.hh)+'</div>'
                    + '<div class="vct-agc-detail-name">'+esc(e.ti)+'</div>'
                    + (e.su?'<div class="vct-agc-detail-sub">'+esc(e.su)+'</div>':'')
                    + '</div>';
            });
            h+='</div>';
            return h;
        }

        function renderWeek(){
            var start=weekStart(state.cursor), end=addDays(start,6);
            titleEl.textContent=start.getDate()+" "+MESES[start.getMonth()].substr(0,3)+" – "+end.getDate()+" "+MESES[end.getMonth()].substr(0,3)+" "+end.getFullYear();
            /* Semana HORIZONTAL (como Agenda General): una fila por dia (Lun-Dom),
               con el estado del dia + las actividades como barras de color. */
            var html='<div class="vct-agc-wl">';
            for(var i=0;i<7;i++){
                var d=addDays(start,i), k=dateKey(d), r=dayInfo(d), e=String(r.e||"").toUpperCase();
                var isToday=sameDay(d,today), isPastRow=(d<today && !isToday), isWknd=(d.getDay()===0||d.getDay()===6);
                var editable=canEditDay(r);
                var bars='';
                if(e!=="NO_CARGADO"){
                    var hrs=(e==="DISPONIBLE"||e==="ASIGNADO"||e==="POTENCIAL"||e==="ORGANISMO") && (+r.h>0) ? ' &middot; '+fmtH(r.h)+' h' : '';
                    var lbl=estadoLabel(r.e);
                    var extra = r.de || ((r.n && r.n.toUpperCase()!==lbl.toUpperCase()) ? r.n : '');
                    var sTxt=lbl+(extra?': '+esc(extra):'')+hrs;
                    var spw=splitOf(r);
                    if (spw && (spw.pend>0 || spw.disp>0)){
                        var who=esc(r.n||'Asignado');
                        if (spw.conf>0) bars+='<span class="vct-agc-wl-bar vct-agc-asignado">'+who+' &middot; '+fmtH(spw.conf)+' h</span>';
                        if (spw.pend>0) bars+='<span class="vct-agc-wl-bar vct-agc-asignado is-pend">'+who+' &middot; '+fmtH(spw.pend)+' h &middot; pendiente</span>';
                        if (spw.disp>0) bars+='<span class="vct-agc-wl-bar vct-agc-disponible">Disponible &middot; '+fmtH(spw.disp)+' h</span>';
                    } else bars+='<span class="vct-agc-wl-bar '+clsOf(r.e)+'">'+sTxt+'</span>';
                }
                actsOf(k).slice().sort(function(a,b){ return hmToMin(a.hd)-hmToMin(b.hd); }).forEach(function(a){
                    var c=a.c||tipoColor(a.t);
                    bars+='<span class="vct-agc-wl-bar vct-agc-wl-act" style="border-left-color:'+c+';background:'+hexToRgba(c,0.13)+'"'+actTip(a)+'>'+(a.hd?'<b>'+esc(a.hd)+'</b> ':'')+esc(a.ti)+'</span>';
                });
                if(!bars) bars='<span class="vct-agc-wl-empty">Sin carga</span>';
                html+='<div class="vct-agc-wl-row'+(isToday?' is-today':'')+(isPastRow?' is-past':'')+(isWknd?' is-wknd':'')+(editable?' is-editable':'')+'" data-vct-agc-day="'+k+'">'
                    + '<div class="vct-agc-wl-date">'
                    +   '<span class="vct-agc-wl-dname">'+DIAS_ABREV[d.getDay()]+'</span>'
                    +   '<span class="vct-agc-wl-dnum">'+d.getDate()+'</span>'
                    +   '<span class="vct-agc-wl-dmonth">'+MESES[d.getMonth()].substr(0,3)+'</span>'
                    + '</div>'
                    + '<div class="vct-agc-wl-bars">'+bars+'</div>'
                    + '</div>';
            }
            html+='</div>';
            /* boceto A: mini-calendario + referencias a la izquierda, weeklist a la derecha */
            paneEl.innerHTML='<div class="vct-agc-wk">'
                + '<aside class="vct-agc-wk-side">'+miniMonthHtml(state.cursor,start,end)+referenciasHtml()+'</aside>'
                + '<div class="vct-agc-wk-main">'+html+'</div>'
                + '</div>';
            bindMiniMes();
            paneEl.querySelectorAll("[data-vct-agc-day]").forEach(function(row){
                row.addEventListener("click", function(){
                    var key=row.getAttribute("data-vct-agc-day"), p=key.split("-"), dObj=new Date(+p[0],+p[1]-1,+p[2]), rr=dayInfo(dObj);
                    if (canEditDay(rr)) openModal(key, rr);
                    else { state.cursor=dObj; setView("day"); render(); }
                });
            });
        }
        /* leyenda de REFERENCIAS (colores de estado) para la barra lateral */
        function referenciasHtml(){
            var items=[["DISPONIBLE","Disponible"],["ASIGNADO","Asignado confirmado"],["ASIGNADO is-pend","Asignado pendiente"],["LICENCIA","Licencia / Vac."],["OCUPADO","Ocupado / No disp."],["POTENCIAL","Potencial"],["ORGANISMO","Organismo"],["OBSERVACION","Observación"],["FERIADO_FIJO","Feriado"]];
            var h='<div class="vct-agc-ref"><div class="vct-agc-ref-h">Referencias</div>';
            items.forEach(function(it){ h+='<div class="vct-agc-ref-row"><span class="vct-agc-ref-dot '+clsOf(it[0])+'"></span>'+it[1]+'</div>'; });
            h+='</div>';
            return h;
        }
        function bindMiniMes(){
            var mp=paneEl.querySelector("[data-vct-agc-mini-prev]"), mn=paneEl.querySelector("[data-vct-agc-mini-next]");
            if(mp) mp.addEventListener("click", function(){ state.cursor=new Date(state.cursor.getFullYear(),state.cursor.getMonth()-1,1); render(); });
            if(mn) mn.addEventListener("click", function(){ state.cursor=new Date(state.cursor.getFullYear(),state.cursor.getMonth()+1,1); render(); });
            paneEl.querySelectorAll("[data-vct-agc-mini-day]").forEach(function(td){
                td.addEventListener("click", function(){
                    var p=td.getAttribute("data-vct-agc-mini-day").split("-");
                    state.cursor=new Date(+p[0],+p[1]-1,+p[2]); render();
                });
            });
        }

        function renderDay(){
            var d=state.cursor, r=dayInfo(d), key=dateKey(d), e=String(r.e).toUpperCase();
            titleEl.textContent=DIAS_LARGO[d.getDay()]+" "+d.getDate()+" de "+MESES[d.getMonth()]+" "+d.getFullYear();
            var editable = canEditDay(r);
            var html='<div class="vct-agenda-day vct-agc-dayview '+clsOf(r.e)+(editable?' is-editable':'')+'"'+(editable?' data-vct-agc-dayedit':'')+'>';
            html+='<div class="vct-agenda-day-num">'+d.getDate()+'</div>';
            html+='<div class="vct-agenda-day-name">'+DIAS_LARGO[d.getDay()]+'</div>';
            html+='<div class="vct-agc-dayview-badge"><span class="vct-agc-badge '+clsOf(r.e)+'">'+estadoLabel(r.e)+'</span></div>';
            if (r.n) html+='<div class="vct-agc-dayview-note">'+esc(r.n)+'</div>';
            if ((e==="ASIGNADO"||e==="DISPONIBLE") && +r.h>0)
                html+='<div class="vct-agc-dayview-hours">'+fmtH(r.h)+'h'+(function(){ var q=splitOf(r); if(!q||(!q.pend&&!q.disp)) return ''; return ' &middot; '+[q.conf?fmtH(q.conf)+'h confirmadas':'',q.pend?fmtH(q.pend)+'h pendientes':'',q.disp?fmtH(q.disp)+'h disponibles':''].filter(Boolean).join(' &middot; '); })()+'</div>';

            html+=dayActs(key);
            html+='</div>';
            paneEl.innerHTML=html;

            /* clic en la tarjeta del dia -> abre el modal directo (sin boton intermedio) */
            var card=paneEl.querySelector("[data-vct-agc-dayedit]");
            if (card) card.addEventListener("click", function(){ openModal(key, r); });
        }

        function bindDayClicks(){
            /* Mes: clic en un dia -> abre el modal de edicion (si es editable y
               no es feriado). Feriado -> vista Dia (solo lectura). */
            paneEl.querySelectorAll("[data-vct-agc-day]").forEach(function(cell){
                cell.addEventListener("click", function(){
                    var key=cell.getAttribute("data-vct-agc-day"), p=key.split("-");
                    var dObj=new Date(+p[0], +p[1]-1, +p[2]), r=dayInfo(dObj);
                    if (canEditDay(r)) { openModal(key, r); }
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
            if(!r.f) r.f=key;
            if(!canEditDay(r)) return;   /* guard: feriados, asignados y dias transcurridos = solo lectura */
            var p=key.split("-"), dObj=new Date(+p[0],+p[1]-1,+p[2]);
            var fechaTxt = DIAS_LARGO[dObj.getDay()]+", "+dObj.getDate()+" de "+MESES[dObj.getMonth()]+" "+dObj.getFullYear();
            var curTipo = tipoDe(r);          /* tipo vigente (TIPO guardado o el propio estado) */
            var exists = !!curTipo;           /* hay algo cargado -> Editar */
            var lockedLicense = String(curTipo).toUpperCase()==="LICENCIA";
            /* Una licencia se elimina antes de poder cambiar el tipo del dia. */

            var opts = '<option value="">Elegí un tipo...</option>';
            TIPOS.forEach(function(t){ if(!lockedLicense || t.v==="LICENCIA") opts += '<option value="'+t.v+'">'+esc(t.label)+'</option>'; });
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
            var lastAvailableHours = (permitsHours(curTipo) && +savedHours > 0) ? fmtH(savedHours) : "8";
            var previousTipo = "";
            var hoursRequired = ov.querySelector("[data-horas-req]");
            function syncFields(){
                var t = selTipo.value, available = permitsHours(t);
                if (permitsHours(previousTipo) && isFinite(+inpHor.value) && +inpHor.value > 0)
                    lastAvailableHours = inpHor.value;
                wrapMot.hidden = t !== "LICENCIA";
                /* la descripcion solo la piden POTENCIAL / ORGANISMO / OBSERVACION.
                   Disponible, Licencia, Ocupado y No disponible NO piden descripcion. */
                var sinDesc = (!t || t==="DISPONIBLE" || t==="LICENCIA" || t==="OCUPADO" || t==="NO_DISPONIBLE");
                wrapDesc.hidden = sinDesc;
                inpDesc.required = !sinDesc;
                wrapHor.hidden = !t;
                inpHor.disabled = !available;
                inpHor.required = available;
                hoursRequired.hidden = !available;
                inpHor.value = available ? lastAvailableHours : "0";
                previousTipo = t;
            }
            selTipo.addEventListener("change", function(){ errEl.hidden=true; syncFields(); });

            /* prefill */
            if (curTipo) selTipo.value = curTipo;
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
                if (lockedLicense && t!=="LICENCIA") return fail("Eliminá primero la licencia o vacaciones para cargar otra actividad.");
                if (!t) return fail("Elegí un tipo.");
                if (permitsHours(t) && (!isFinite(+inpHor.value) || !(+inpHor.value>0) || +inpHor.value>24 || (+inpHor.value*2)%1!==0)) return fail("Ingresá horas entre 0,5 y 24, en intervalos de media hora.");
                if (t==="LICENCIA" && !selMot.value) return fail("Elegí el motivo de la licencia.");
                var pideDesc = (t==="POTENCIAL" || t==="ORGANISMO" || t==="OBSERVACION");
                if (pideDesc && !inpDesc.value.trim()) return fail("Completá la descripción.");
                saveFecha(key, {
                    tipo:   t,
                    motivo: (t==="LICENCIA") ? selMot.value : "",
                    desc:   pideDesc ? inpDesc.value.trim() : "",
                    horas:  permitsHours(t) ? inpHor.value : "0"
                });
                close();
            });

            setTimeout(function(){ var trigger = ov.querySelector("[data-f-tipo] + .vct-form-select .vct-form-select-trigger"); (trigger || selTipo).focus(); }, 30);
        }

        function setView(v){
            state.view=v;
            viewBtns.forEach(function(b){ var active=b.getAttribute("data-vct-agc-view")===v; b.classList.toggle("is-active",active); b.setAttribute("aria-pressed",active ? "true" : "false"); });
        }

        function render(){
            /* la vista semana (Google Calendar) trae su propio layout: sin fila de KPIs */
            if (statsEl) statsEl.style.display = (state.view==="week") ? "none" : "";
            root.classList.toggle("vct-agc-weekmode", state.view==="week");
            setView(state.view);
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
        if (selMonth) selMonth.addEventListener("change", function(){ if (syncing) return; var day=state.cursor.getDate(), m=+selMonth.value-1, y=state.cursor.getFullYear(); state.cursor=new Date(y,m,Math.min(day,new Date(y,m+1,0).getDate())); render(); });
        if (selYear)  selYear.addEventListener("change", function(){ if (syncing) return; var y=+selYear.value,m=state.cursor.getMonth(),day=state.cursor.getDate(); state.cursor=new Date(y,m,Math.min(day,new Date(y,m+1,0).getDate())); render(); });
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

/* ===================== [CAL_C_V1] diseno comun de calendarios (opcion C) =====================
   Aplica a Acciones, Agenda general (feriados), Agenda del consultor y su calendario en la V360
   del consultor (NO al de la V360 de proyecto, que queda como estaba).
     - Navegacion:  [ ‹ Mes › ]  [ Mes | Semana | Dia ]  [ ‹ Anio › ]  (sin desplegables de mes / anio;
       los <select> quedan ocultos y siguen siendo la fuente del cambio de anio).
     - Dias pasados, sabados y domingos: no editables ni clickeables (solo se ven, atenuados).
     - Leyenda: asignado confirmado / pendiente y "No editable".
   No cambia los datos que muestra cada calendario. */
(function (window, document) {
    "use strict";
    if (window.__vctCalCLoaded) return;
    window.__vctCalCLoaded = true;

    var RO_SEL = ".vct-agenda-cell-past,.vct-agenda-cell-weekend,.vct-agenda-cell.is-past,.vct-agenda-cell.is-wknd,"
               + ".vct-agc-wl-row.is-past,.vct-agc-wl-row.is-wknd";

    function q(root, a, b){ return root.querySelector(root.hasAttribute("data-vct-agc-root") ? b : a); }

    function setup(root){
        if (!root || root.getAttribute("data-vct-cal-c") === "1") return;
        if (root.closest("[data-vct-pv]")) return;                       /* V360 de proyecto: sin cambios por ahora */
        var title = q(root, "[data-vct-agenda-title]", "[data-vct-agc-title]");
        var selY  = q(root, "[data-vct-agenda-select-year]", "[data-vct-agc-year]");
        var selM  = q(root, "[data-vct-agenda-select-month]", "[data-vct-agc-month]");
        var nav   = title ? title.parentNode : null;
        if (!nav || !selY) return;                                         /* el motor todavia no dibujo la barra */
        root.setAttribute("data-vct-cal-c", "1");
        root.classList.add("vct-cal-c");

        var viewBtn = q(root, "[data-vct-agenda-view]", "[data-vct-agc-view]");
        var toggle  = viewBtn ? viewBtn.parentNode : null;
        var tb      = nav.parentNode;

        /* desplegables de mes y anio: ocultos */
        [selM, selY].forEach(function(s){
            if (!s) return;
            var holder = s.closest(".vct-agenda-jump") || s.parentNode;
            holder.classList.add("vct-cal-hide");
        });
        var right = tb.querySelector(".vct-agenda-toolbar-right");
        if (right && !right.querySelector(":scope > :not(.vct-cal-hide)")) right.classList.add("vct-cal-hide");

        /* grupo:  ‹ Mes ›  |  Mes Semana Dia  |  ‹ Anio › */
        var grp = document.createElement("div");
        grp.className = "vct-cal-navgroup";
        nav.classList.add("vct-cal-stp");
        grp.appendChild(nav);
        if (toggle && toggle !== nav) { toggle.classList.add("vct-cal-seg"); grp.appendChild(toggle); }
        var ys = document.createElement("div");
        ys.className = "vct-cal-stp is-year";
        ys.innerHTML = '<button type="button" class="vct-cal-stp-btn" data-vct-cal-y="-1" aria-label="Año anterior">‹</button>'
                     + '<span class="vct-cal-stp-lbl" data-vct-cal-ylbl></span>'
                     + '<button type="button" class="vct-cal-stp-btn" data-vct-cal-y="1" aria-label="Año siguiente">›</button>';
        grp.appendChild(ys);
        tb.appendChild(grp);
        var ylbl = ys.querySelector("[data-vct-cal-ylbl]");

        /* el titulo del motor trae el anio al final: pasa al selector de anio */
        function syncTitle(){
            var t = title.textContent || "", m = /\s(\d{4})$/.exec(t);
            if (m){ ylbl.textContent = m[1]; title.textContent = t.replace(/\s\d{4}$/, ""); }
            else if (!ylbl.textContent) ylbl.textContent = selY.value || String(new Date().getFullYear());
        }
        syncTitle();
        try { new MutationObserver(syncTitle).observe(title, { childList:true, characterData:true, subtree:true }); } catch(e){}

        ys.addEventListener("click", function(ev){
            var b = ev.target.closest("[data-vct-cal-y]"); if (!b) return;
            var y = (parseInt(ylbl.textContent, 10) || new Date().getFullYear()) + parseInt(b.getAttribute("data-vct-cal-y"), 10);
            var has = false;
            for (var i = 0; i < selY.options.length; i++) if (selY.options[i].value === String(y)) has = true;
            if (!has){ var o = document.createElement("option"); o.value = String(y); o.textContent = String(y); selY.appendChild(o); }
            selY.value = String(y);
            try { selY.dispatchEvent(new Event("change", { bubbles:true })); } catch(e){}
        });

        /* leyenda */
        var leg = root.querySelector(".vct-agc-legend") || root.querySelector(".vct-agenda-legend");
        if (leg && !leg.querySelector("[data-vct-cal-ro]")){
            var asg = leg.querySelector(".vct-agc-dot-asignado");
            if (asg){
                var it = asg.parentNode;
                it.lastChild.nodeValue = "Asignado confirmado";
                var pend = document.createElement("span");
                pend.className = "vct-agenda-legend-item";
                pend.innerHTML = '<i class="vct-agc-dot vct-agc-dot-pendiente"></i>Asignado pendiente';
                it.parentNode.insertBefore(pend, it.nextSibling);
            }
            var ro = document.createElement("span");
            ro.className = "vct-agenda-legend-item";
            ro.setAttribute("data-vct-cal-ro", "");
            ro.innerHTML = '<i class="vct-cal-dot-ro"></i>No editable (pasado, sábado y domingo)';
            leg.appendChild(ro);
        }
    }

    /* dias no editables: no se puede hacer clic (el tooltip sigue andando con el mouse) */
    document.addEventListener("click", function(ev){
        var t = ev.target && ev.target.closest ? ev.target : null;
        if (!t || !t.closest(".vct-cal-c")) return;
        if (t.closest(".vct-cal-navgroup,.vct-agenda-toolbar,.vct-agc-mini,.vct-agc-modal-ov")) return;
        if (t.closest(RO_SEL)){ ev.preventDefault(); ev.stopPropagation(); }
    }, true);

    function scan(){
        document.querySelectorAll("[data-vct-agenda-root],[data-vct-agc-root]").forEach(setup);
    }
    function later(){ scan(); setTimeout(scan, 120); setTimeout(scan, 600); }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", later); else later();
    document.addEventListener("vct:content-loaded", later);
})(window, document);
