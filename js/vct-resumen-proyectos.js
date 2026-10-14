/* Resumen 360 - v2: reconoce tablas recientes generadas por otros componentes. */
(function(window,document){
    "use strict";
    if(window.__vctRecentProjectsV2) return;
    window.__vctRecentProjectsV2=true;
    function norm(s){return String(s||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase().trim();}
    var weights={cliente:14,proyecto:34,servicios:6,normas:16,analista:6,consultor:7,estado:8,inicio:8,fin:8,avance:14,viaticos:14,acciones:3};
    function key(label,index){
        var n=norm(label);
        if(!n) return "acciones";
        for(var k in weights) if(n===k||n.indexOf(k)===0) return k;
        return "col"+index;
    }
    function referenceWidths(table,labels){
        var page=table.closest(".vct-360-module")||document.getElementById("mainContainer")||document;
        var grids=page.querySelectorAll('[data-vct-dg-id*="proyecto"] table');
        for(var i=0;i<grids.length;i++){
            var heads=grids[i].querySelectorAll("thead th");
            if(heads.length!==labels.length) continue;
            var same=true,widths=[];
            for(var j=0;j<heads.length;j++){
                if(key(heads[j].textContent,j)!==labels[j]) same=false;
                widths.push(parseFloat(heads[j].getAttribute("data-vct-width")));
            }
            if(same&&widths.every(function(w){return isFinite(w)&&w>0;})) return widths;
        }
        return labels.map(function(k){return weights[k]||8;});
    }
    function fix(table){
        if(table.hasAttribute("data-vct-recent-layout")) return;
        var head=table.querySelector("thead tr");
        if(!head) return;
        var heads=Array.prototype.slice.call(head.children),labels=heads.map(function(h,i){return key(h.textContent,i);});
        if(labels.indexOf("proyecto")<0) return;
        var widths=referenceWidths(table,labels),total=widths.reduce(function(a,b){return a+b;},0);
        table.setAttribute("data-vct-recent-layout","v2");
        table.classList.add("vct-360-table","vct-360-project-table","vct-360-project-table-recent");
        var container=table.closest(".vct-360-projects-recent")||table.parentElement;
        if(container)container.classList.add("vct-360-projects-recent");
        if(container){container.setAttribute("data-vct-recent-wrap","");container.style.removeProperty("overflow");}
        table.style.removeProperty("width");table.style.removeProperty("min-width");table.style.removeProperty("table-layout");
        table.style.setProperty("--vct-recent-min-width",(labels.length>=9?1150:labels.length>=7?920:labels.length>=6?760:640)+"px");
        table.querySelectorAll("colgroup").forEach(function(g){g.remove();});
        var group=document.createElement("colgroup");
        widths.forEach(function(w){var col=document.createElement("col");col.style.width=(w/total*100)+"%";group.appendChild(col);});
        table.insertBefore(group,table.firstChild);
        Array.prototype.forEach.call(table.rows,function(row){
            Array.prototype.forEach.call(row.cells,function(cell,i){
                if(cell.colSpan>1) return;
                cell.style.removeProperty("width");cell.style.removeProperty("min-width");cell.style.removeProperty("max-width");cell.style.removeProperty("text-align");
                if(!labels[i]) return;
                cell.setAttribute("data-vct-recent-col",labels[i]);
                if(cell.tagName==="TD"){
                    cell.setAttribute("data-label",heads[i].textContent.trim()||"Acciones");
                    var content=document.createElement("div");content.className="vct-recent-cell-content";
                    while(cell.firstChild) content.appendChild(cell.firstChild);
                    cell.appendChild(content);
                    var bar=content.querySelector(".vct-360-progress"),pct=content.querySelector(".vct-360-progress-label");
                    if(bar&&pct){var progress=document.createElement("div");progress.className="vct-recent-progress";bar.parentNode.insertBefore(progress,bar);progress.appendChild(bar);progress.appendChild(pct);}
                }
            });
        });
    }
    function boot(){
        var root=document.getElementById("mainContainer")||document;
        root.querySelectorAll("table").forEach(function(table){
            var recent=table.closest(".vct-360-projects-recent");
            var summary=table.closest('[data-vct-panel="resumen"], [data-vct-tab-panel="resumen"], [data-vct-tab-content="resumen"]');
            var box=table.closest(".vct-360-box"),title=box&&box.querySelector("h3");
            var label=norm(title&&title.textContent);
            if(recent||summary||label.indexOf("ultimos proyectos")>=0||label.indexOf("proyectos recientes")>=0)fix(table);
        });
    }
    if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",boot);else boot();
    if(window.MutationObserver){var pending=false;new MutationObserver(function(){if(pending)return;pending=true;setTimeout(function(){pending=false;boot();},20);}).observe(document.documentElement,{childList:true,subtree:true});}
})(window,document);
