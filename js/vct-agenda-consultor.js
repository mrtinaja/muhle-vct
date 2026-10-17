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

        function renderWeek(){
            var start=addDays(state.cursor, -state.cursor.getDay()), end=addDays(start,6);
            titleEl.textContent=start.getDate()+" "+MESES[start.getMonth()].substr(0,3)+" - "+end.getDate()+" "+MESES[end.getMonth()].substr(0,3)+" "+end.getFullYear();
            var html='<div class="vct-agenda-weeklist">';
            for(var i=0;i<7;i++){
                var d=addDays(start,i), k=dateKey(d), r=dayInfo(d), isToday=sameDay(d,today);
                html+='<div class="vct-agenda-weekrow '+clsOf(r.e)+'" data-vct-agc-day="'+k+'">';
                html+='<div class="vct-agenda-weekrow-date'+(isToday?" is-today":"")+'">';
                html+='<span class="vct-agenda-weekrow-dayname">'+DIAS_ABREV[i]+'</span>';
                html+='<span class="vct-agenda-weekrow-daynum">'+d.getDate()+'</span>';
                html+='<span class="vct-agenda-weekrow-month">'+MESES[d.getMonth()].substr(0,3)+'</span>';
                html+='</div>';
                html+='<div class="vct-agenda-weekrow-card vct-agc-weekcard">';
                html+='<span class="vct-agc-badge '+clsOf(r.e)+'">'+estadoLabel(r.e)+'</span>';
                if (r.n) html+='<span class="vct-agenda-weekrow-text">'+esc(r.n)+'</span>';
                if ((String(r.e).toUpperCase()==="ASIGNADO"||String(r.e).toUpperCase()==="DISPONIBLE") && +r.h>0)
                    html+='<span class="vct-agenda-weekrow-text">'+fmtH(r.h)+'h</span>';
                html+='</div></div>';
            }
            html+='</div>';
            paneEl.innerHTML=html;
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
