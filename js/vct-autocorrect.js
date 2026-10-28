/* ============================================================================
   VCT AUTOCORRECCION ORTOGRAFICA (POC) - 100% interno, solo ortografia
   ----------------------------------------------------------------------------
   Corrige automaticamente al terminar cada palabra (espacio/puntuacion) en los
   textarea marcados (POC: Observaciones). Usa Typo.js + diccionario espaniol
   Hunspell servido desde el propio server (../lib/spell/). Nada sale afuera.

   SALVAGUARDAS (para no pisar nombres propios / siglas / codigos):
     - solo palabras en minuscula (Mayuscula inicial = nombre propio -> no toca)
     - no toca SIGLAS (todo mayusculas) ni palabras con numeros
     - solo corrige si la sugerencia esta a <=2 ediciones (alta confianza)
     - Ctrl+Z deshace (se usa execCommand insertText)

   Alcance POC: textarea con placeholder "Observ..." o [data-vct-autocorrect].
   Para sumar un campo: agregarle data-vct-autocorrect. Para excluir: quitarlo.
   ============================================================================ */
(function (window, document) {
    "use strict";
    if (window.__vctAutocorrect) return;
    window.__vctAutocorrect = true;

    var BASE = "../lib/spell/";
    var dict = null, loading = false, failed = false;

    function loadScript(src, cb) {
        var s = document.createElement("script");
        s.src = src; s.onload = cb; s.onerror = function () { cb(); };
        document.head.appendChild(s);
    }

    function ensureDict(cb) {
        if (dict) { cb && cb(); return; }
        if (failed) return;
        function build() {
            if (!window.Typo) { failed = true; loading = false; return; }
            Promise.all([
                fetch(BASE + "es.aff.txt").then(function (r) { return r.text(); }),
                fetch(BASE + "es.dic.txt").then(function (r) { return r.text(); })
            ]).then(function (res) {
                try { dict = new window.Typo("es", res[0], res[1]); } catch (e) { dict = null; failed = true; }
                loading = false;
                if (dict && cb) cb();
            }).catch(function () { loading = false; failed = true; });
        }
        if (loading) return;
        loading = true;
        if (window.Typo) build();
        else loadScript(BASE + "typo.js", build);
    }

    var WORDCH = /[A-Za-zÀ-ſ]/;  /* letras latinas con acentos/ñ */

    function stripAccents(s) { try { return s.normalize("NFD").replace(/[̀-ͯ]/g, ""); } catch (e) { return s; } }

    function baseOk(w) {
        if (!w || w.length < 3) return false;
        if (/[0-9]/.test(w)) return false;
        if (w === w.toUpperCase() && w !== w.toLowerCase()) return false; /* SIGLA (todo mayuscula) */
        return true;
    }
    /* true si la palabra que empieza en 'start' es la primera de la frase
       (inicio del texto o despues de . ! ? ¡ ¿ salto de linea) -> ahi una
       mayuscula inicial es correcta, no un nombre propio. */
    function sentenceStart(val, start) {
        var i = start - 1;
        while (i >= 0 && /\s/.test(val.charAt(i))) i--;
        if (i < 0) return true;
        return /[.!?\n¡¿]/.test(val.charAt(i));
    }

    function editDistLE(a, b, max) {
        var la = a.length, lb = b.length, i, j;
        if (Math.abs(la - lb) > max) return false;
        var prev = [], cur = [];
        for (j = 0; j <= lb; j++) prev[j] = j;
        for (i = 1; i <= la; i++) {
            cur[0] = i; var best = i;
            for (j = 1; j <= lb; j++) {
                var cost = a.charAt(i - 1) === b.charAt(j - 1) ? 0 : 1;
                cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
                if (cur[j] < best) best = cur[j];
            }
            if (best > max) return false;
            for (j = 0; j <= lb; j++) prev[j] = cur[j];
        }
        return prev[lb] <= max;
    }

    function correctLastWord(ta) {
        if (!dict) return;
        var val = ta.value, pos = ta.selectionStart;
        if (pos < 2) return;
        var boundary = val.charAt(pos - 1);
        if (!/[\s.,;:!?)\]]/.test(boundary)) return;
        var end = pos - 1, start = end;
        while (start > 0 && WORDCH.test(val.charAt(start - 1))) start--;
        var word = val.slice(start, end);
        if (!baseOk(word)) return;
        var first = word.charAt(0);
        var isCap = (first === first.toUpperCase() && first !== first.toLowerCase());
        if (isCap && !sentenceStart(val, start)) return;    /* nombre propio a mitad de frase: no tocar */
        var lookup = isCap ? (first.toLowerCase() + word.slice(1)) : word;
        if (dict.check(word) || dict.check(lookup)) return;
        var sugg = dict.suggest(lookup);
        if (!sugg || !sugg.length) return;
        var lw = lookup.toLowerCase();
        /* preferir la sugerencia que solo agrega acentos (misma palabra sin tildes):
           es la correccion mas comun y segura. Evita casos como telefono->telefoneo. */
        var best = null, i2;
        for (i2 = 0; i2 < sugg.length; i2++) {
            if (stripAccents(sugg[i2]).toLowerCase() === lw) { best = sugg[i2]; break; }
        }
        if (!best) best = sugg[0];
        if (best.toLowerCase() === lw) return;
        if (!editDistLE(lw, best.toLowerCase(), 2)) return;
        if (isCap) best = best.charAt(0).toUpperCase() + best.slice(1);   /* preservar mayuscula inicial */
        /* reemplazar [start,end] -> best, conservando Ctrl+Z */
        ta.setSelectionRange(start, end);
        var ok = false;
        try { ok = document.execCommand("insertText", false, best); } catch (e) {}
        if (!ok) {
            ta.value = val.slice(0, start) + best + val.slice(end);
        }
        var np = start + best.length + 1;
        try { ta.setSelectionRange(np, np); } catch (e) {}
        try { ta.dispatchEvent(new Event("input", { bubbles: true })); } catch (e) {}
    }

    function wire(ta) {
        if (ta.__vctAc) return;
        ta.__vctAc = true;
        ta.setAttribute("spellcheck", "false"); /* ya autocorregimos; evita doble subrayado */
        ta.setAttribute("lang", "es");
        ensureDict();  /* precarga el diccionario al enfocar el area */
        ta.addEventListener("keyup", function (e) {
            if (e.key === " " || e.key === "Enter" || (e.key && e.key.length === 1 && /[.,;:!?)\]]/.test(e.key))) {
                ensureDict(function () { correctLastWord(ta); });
            }
        });
    }

    function scan() {
        /* TODA la app: todos los textarea (campos de texto libre: observaciones,
           notas, descripcion, minuta...). Para excluir uno: data-vct-noautocorrect.
           Los inputs cortos (calle, localidad, numero) quedan afuera a proposito. */
        var tas = document.querySelectorAll('textarea:not([data-vct-noautocorrect])');
        Array.prototype.forEach.call(tas, wire);
    }

    if (document.readyState !== "loading") scan();
    else document.addEventListener("DOMContentLoaded", scan);
    try { if (window.jQuery) jQuery(document).ajaxComplete(scan); } catch (e) {}
    if (window.MutationObserver) {
        var t, host = document.getElementById("mainContainer") || document.documentElement;
        new MutationObserver(function () { clearTimeout(t); t = setTimeout(scan, 150); })
            .observe(host, { childList: true, subtree: true });
    }
})(window, document);
