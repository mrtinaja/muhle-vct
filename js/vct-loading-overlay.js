/* ========================================================================
   VCT LOADING OVERLAY
   ------------------------------------------------------------------------
   Aislado de vct-main.js, mismo criterio que vct-email-template-designer.js.

   Todo el framework (VCT.Buffer.waitForStoreIdle ya usa jQuery.active)
   corre sobre AJAX de jQuery, sin importar si el request lo dispara
   next(), goto(), almacenarSeleccion() u otra funcion legacy. En vez de
   parchear una funcion puntual (newTaskForContactWithParams u otra) que
   no forma parte de este archivo, se usan los eventos globales de jQuery
   ajaxStart/ajaxStop: jQuery los dispara solo/exactamente cuando la
   cantidad de requests en vuelo (jQuery.active) sube de 0 a 1 o baja de
   1 a 0, asi que varios requests superpuestos ya quedan cubiertos sin
   contador manual.

   Requiere en el HTML (una sola vez, en el shell/master):
     <div id="vct-loading-overlay" class="vct-loading-overlay">
         <div class="vct-spinner"></div>
     </div>
   ======================================================================== */
(function (window, document) {
    "use strict";

    function getOverlay() {
        return document.getElementById("vct-loading-overlay");
    }

    function showVctLoading() {
        var overlay = getOverlay();
        if (overlay) overlay.classList.add("is-active");
    }

    function hideVctLoading() {
        var overlay = getOverlay();
        if (overlay) overlay.classList.remove("is-active");
    }

    window.showVctLoading = showVctLoading;
    window.hideVctLoading = hideVctLoading;

    function bind() {
        if (!window.jQuery) {
            window.setTimeout(bind, 200);
            return;
        }

        window.jQuery(document).ajaxStart(showVctLoading);
        window.jQuery(document).ajaxStop(hideVctLoading);
    }

    bind();

})(window, document);
