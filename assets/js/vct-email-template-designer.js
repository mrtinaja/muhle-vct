/*
========================================================================
VCT EMAIL TEMPLATE DESIGNER - V2 ———————————————————————— Aislado de
vct-main.js. Usa VCT.DomForm para persistir al VCT_BUFFER. Reemplaza el
editor por bloques (V1) por un cuerpo único de texto enriquecido + panel
de variables persistente. Conserva el mismo contrato de campos que V1
(TEXTO01..TEXTO11, IDSELEC01, TEXTO30, ACTIVE_TAB, FLAG01/FLAG03) y el
mismo flujo open/close/save con VCT.DomForm.validateAndNext.

Compatibilidad hacia atrás: TEXTO10 (HTML compilado) sigue siendo la
fuente de verdad del cuerpo visible. Un template guardado con el editor
por bloques (V1) no tiene el marcador data-vct-email-content dentro de
TEXTO10: al abrirlo, este editor carga igual el documento completo
dentro del cuerpo editable (no se pierde contenido) y al guardar de
nuevo queda recompilado en el formato nuevo. TEXTO11 (DISENO_JSON) deja
de describir bloques; ahora solo lleva un marcador de versión para
satisfizar el “no vacío” que valida la SP, sin que nada dependa de su
contenido para volver a abrir el template.

Insercion de imagenes: SOLO por el de banners fijos del servidor
(insertServerBanner). No hay paste ni carga de archivo local:
VCT_BUFFER.TEXTO10 pasa por un POST hacia task/Default.aspx manejado por
codigo .NET compilado (sin fuente) que trunca a 4000 caracteres antes de
llegar a SQL Server, sin importar que la columna en si sea VARCHAR(MAX).
Una imagen en base64 solo entraria si el archivo original pesa ~2-2.5
KB, impractico – por eso se descarto esa via por completo (ver historial
en VCT_MAIN_CONFIGURACION.sql, actualizaciones V17-V19). safeImageUrl()
sigue aceptando el patron data:image por si algun dia cambia esa
restriccion, pero hoy no hay ningun camino en la UI que la ejercite.
========================================================================
*/ (function (window, document) { "use strict";

    if (window.VCTEmailTemplateDesigner) {
        if (typeof window.VCTEmailTemplateDesigner.init === "function")
            window.VCTEmailTemplateDesigner.init(document);
        return;
    }

    var Designer = {};

    Designer.variables = [
        { name:"NOMBRE", desc:"Nombre del destinatario.", group:"Persona" },
        { name:"APELLIDO", desc:"Apellido del destinatario.", group:"Persona" },
        { name:"EMAIL", desc:"Casilla de correo del destinatario.", group:"Persona" },
        { name:"PROYECTO", desc:"Nombre o código del proyecto.", group:"Proyecto" },
        { name:"SERVICIO", desc:"Servicio asociado.", group:"Proyecto" },
        { name:"ANALISTA", desc:"Apellido y nombre del analista responsable.", group:"Proyecto" },
        { name:"CONSULTOR", desc:"Apellido y nombre del consultor.", group:"Proyecto" },
        { name:"AGENDA", desc:"Calendario mensual del consultor (mes en curso) con los días de visita resaltados y el cliente de cada uno. Solo funciona en el cuerpo del mail, no en el asunto.", group:"Proyecto" },
        { name:"CLIENTE", desc:"Razón social o nombre del cliente.", group:"Proyecto" },
        { name:"FECHA", desc:"Fecha del envío.", group:"Fecha" },
        { name:"HORA", desc:"Hora del envío.", group:"Fecha" },
        { name:"MES", desc:"Mes actual (en letras, ej. Septiembre).", group:"Fecha" },
        { name:"ANIO", desc:"Año actual (ej. 2026).", group:"Fecha" }
    ];

    function trim(v) { return v === null || v === undefined ? "" : String(v).trim(); }
    function escHtml(v) {
        return String(v === null || v === undefined ? "" : v)
            .replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
            .replace(/"/g,"&quot;").replace(/'/g,"&#39;");
    }
    function escAttr(v) { return escHtml(v); }
    function field(root, name) { return root.querySelector('[data-vct-field="' + name + '"]'); }
    function setField(root, name, value) {
        var el = field(root, name);
        if (!el) return;
        el.value = value === null || value === undefined ? "" : String(value);
        try { el.dispatchEvent(new Event("change", { bubbles:true })); } catch (e) {}
        if (window.VCT && VCT.DomForm && typeof VCT.DomForm.syncVisualField === "function")
            VCT.DomForm.syncVisualField(el);
    }
    function getField(root, name) {
        var el = field(root, name);
        return el ? el.value : "";
    }

    function wordCount(text) {
        text = trim(text).replace(/\s+/g," ");
        if (!text) return 0;
        return text.split(" ").length;
    }

    function cleanBodyHtml(html) {
        var host = document.createElement("div");
        host.innerHTML = html || "";
        host.querySelectorAll("script,style,iframe,object,embed,form,input,button").forEach(function (el) { el.remove(); });
        host.querySelectorAll(".vct-email-img-selected").forEach(function (el) { el.classList.remove("vct-email-img-selected"); });
        host.querySelectorAll("*").forEach(function (el) {
            Array.prototype.slice.call(el.attributes || []).forEach(function (attr) {
                var n = String(attr.name || "").toLowerCase();
                var v = String(attr.value || "");
                if (n.indexOf("on") === 0) el.removeAttribute(attr.name);
                if ((n === "href" || n === "src") && /^\s*javascript:/i.test(v)) el.removeAttribute(attr.name);
                if (n === "style") {
                    var safe = v.replace(/expression\s*\([^)]*\)/gi, "").replace(/url\s*\(\s*['\"]?javascript:[^)]+\)/gi, "");
                    el.setAttribute("style", safe);
                }
            });
        });
        return host.innerHTML;
    }

    function safeImageUrl(value) {
        value = trim(value);
        if (!value) return "";
        if (/^https?:\/\//i.test(value)) return value;
        if (/^data:image\/(png|jpeg|jpg|gif|webp);base64,/i.test(value)) return value;
        return "";
    }

    function defaultBodyHtml() {
        return "<p>Hola {{NOMBRE}},</p><p>Escriba aquí el contenido del mensaje.</p>";
    }

    function wrapEmailHtml(bodyHtml) {
        return '<!doctype html><html><head><meta charset="utf-8">' +
            '<style>html,body{overflow-x:hidden;}</style></head>' +
            '<body style="margin:0;padding:0;background:#f3f5f7;">' +
            '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#f3f5f7;padding:24px 0;">' +
            '<tr><td align="center">' +
            '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:600px;max-width:94%;background:#ffffff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;">' +
            '<tr><td data-vct-email-content style="padding:20px 24px;color:#263247;font-family:Arial,sans-serif;font-size:14px;line-height:1.6;">' + bodyHtml + '</td></tr>' +
            '</table></td></tr></table></body></html>';
    }

    function extractBodyInnerHtml(fullHtml) {
        var marker = "data-vct-email-content";
        if (fullHtml.indexOf(marker) === -1) return fullHtml; // formato viejo (V1) o desconocido: se carga tal cual, sin perder contenido
        var host = document.createElement("div");
        host.innerHTML = fullHtml;
        var cell = host.querySelector("[" + marker + "]");
        return cell ? cell.innerHTML : fullHtml;
    }

    function makeState(root) {
        return {
            root:root,
            list:(root.closest('[data-vct-config-panel="email-templates"], [data-vct-param-group-panel="email-templates"]') || root).querySelector("[data-vct-email-list-view]"),
            editorBody:root.querySelector("[data-vct-email-rich-editor]"),
            previewFrame:root.querySelector("[data-vct-email-preview]"),
            wordCountEl:root.querySelector("[data-vct-email-word-count]"),
            title:root.querySelector("[data-vct-email-editor-title]"),
            variablesList:root.querySelector("[data-vct-email-variables-list]"),
            selectedImage:null,
            lastFocusTarget:null,
            savedRange:null,
            mode:"create",
            deviceMode:"desktop",
            dirty:false
        };
    }

    function updateConditionalFields(state) {
        var destino = getField(state.root, "TEXTO04");
        var cc = getField(state.root, "TEXTO06");
        var destinoWrap = state.root.querySelector("[data-vct-email-destino-libre-wrap]");
        var ccWrap = state.root.querySelector("[data-vct-email-cc-libre-wrap]");
        if (destinoWrap) destinoWrap.classList.toggle("is-visible", destino === "LIBRE");
        if (ccWrap) ccWrap.classList.toggle("is-visible", cc === "LIBRE");

        var destinoLibre = field(state.root, "TEXTO05");
        var ccLibre = field(state.root, "TEXTO07");
        if (destinoLibre) destinoLibre.setAttribute("data-vct-required", destino === "LIBRE" ? "1" : "0");
        if (ccLibre) ccLibre.setAttribute("data-vct-required", cc === "LIBRE" ? "1" : "0");
        if (destino !== "LIBRE") setField(state.root, "TEXTO05", "");
        if (cc !== "LIBRE") setField(state.root, "TEXTO07", "");
    }

    function buildVariablesPanel(state) {
        if (!state.variablesList || state.variablesList.children.length) return;
        var groups = [];
        var byGroup = {};
        Designer.variables.forEach(function (v) {
            var g = v.group || "Otras";
            if (!byGroup[g]) { byGroup[g] = []; groups.push(g); }
            byGroup[g].push(v);
        });
        groups.forEach(function (g) {
            var groupEl = document.createElement("div");
            groupEl.className = "vct-email-variables-group";
            groupEl.setAttribute("data-vct-email-variables-group", g);

            var label = document.createElement("div");
            label.className = "vct-email-variables-group-label";
            label.textContent = g;
            groupEl.appendChild(label);

            var chipsWrap = document.createElement("div");
            chipsWrap.className = "vct-email-variables-chips";

            byGroup[g].forEach(function (v) {
                var chip = document.createElement("button");
                chip.type = "button";
                chip.className = "vct-email-variable-chip";
                chip.setAttribute("data-vct-email-variable", v.name);
                chip.setAttribute("data-vct-email-variable-search", (v.name + " " + v.desc).toLowerCase());
                chip.title = v.desc;
                chip.innerHTML = '{{' + escHtml(v.name) + '}}';
                chipsWrap.appendChild(chip);
            });

            groupEl.appendChild(chipsWrap);
            state.variablesList.appendChild(groupEl);
        });
    }

    function filterVariables(state, query) {
        query = trim(query).toLowerCase();
        var anyVisible = false;
        var groups = state.variablesList ? state.variablesList.querySelectorAll("[data-vct-email-variables-group]") : [];
        groups.forEach(function (groupEl) {
            var groupHasMatch = false;
            groupEl.querySelectorAll("[data-vct-email-variable]").forEach(function (chip) {
                var match = !query || chip.getAttribute("data-vct-email-variable-search").indexOf(query) !== -1;
                chip.style.display = match ? "" : "none";
                if (match) groupHasMatch = true;
            });
            groupEl.style.display = groupHasMatch ? "" : "none";
            if (groupHasMatch) anyVisible = true;
        });
        var emptyEl = state.root.querySelector("[data-vct-email-variables-empty]");
        if (emptyEl) emptyEl.style.display = anyVisible ? "none" : "block";
    }

    function saveSelectionRange(state) {
        var sel = window.getSelection();
        if (sel && sel.rangeCount && state.editorBody.contains(sel.anchorNode))
            state.savedRange = sel.getRangeAt(0).cloneRange();
    }

    function restoreSelectionRange(state) {
        if (!state.savedRange) { state.editorBody.focus(); return; }
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(state.savedRange);
    }

    function insertAtInput(input, text) {
        var start = typeof input.selectionStart === "number" ? input.selectionStart : input.value.length;
        var end = typeof input.selectionEnd === "number" ? input.selectionEnd : start;
        input.value = input.value.slice(0,start) + text + input.value.slice(end);
        var pos = start + text.length;
        try { input.setSelectionRange(pos,pos); } catch (e) {}
        input.focus();
        input.dispatchEvent(new Event("input", { bubbles:true }));
    }

    function insertHtmlAtCursor(state, html) {
        state.editorBody.focus();
        restoreSelectionRange(state);
        try { document.execCommand("insertHTML", false, html); }
        catch (e) { state.editorBody.insertAdjacentHTML("beforeend", html); }
        state.editorBody.dispatchEvent(new Event("input", { bubbles:true }));
    }

    function showPasteBlockedMessage(state) {
        var box = state.root.querySelector("[data-vct-validation-box]");
        if (!box) return;
        box.innerHTML = '<div class="vct-validation-title">No se puede pegar la captura directo</div>' +
            '<ul><li>Subí la imagen primero con "Insertar banner" (arriba del editor) y despues insertala desde ahí. Pegar una captura como base64 la corta al guardar (VCT_BUFFER.TEXTO10 pasa por un POST hacia task/Default.aspx en .NET compilado que trunca a 4000 caracteres) y no se ve en el mail.</li></ul>';
        box.style.display = "block";
        try { box.scrollIntoView({ block:"center", behavior:"smooth" }); } catch (e) {}
    }

    /* Pegar una captura (Ctrl+V) copiada desde una herramienta de recorte
       nunca debe convertirse en un <img src="data:..."> embebido: ya se
       probo (ver historial en VCT_MAIN_CONFIGURACION.sql, V17-V19) y el
       techo real es ~2-2.5 KB de archivo original -- impractico. En vez de
       insertarlo roto, se avisa y se lo manda al flujo de banner (URL
       absoluta), que si funciona de punta a punta. */
    function handlePaste(state, event) {
        var items = event.clipboardData && event.clipboardData.items;
        if (items) {
            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                if (item.kind === "file" && /^image\//i.test(item.type)) {
                    event.preventDefault();
                    showPasteBlockedMessage(state);
                    return;
                }
            }
        }
        var pastedText = event.clipboardData ? trim(event.clipboardData.getData("text/plain")) : "";
        if (/^data:image\//i.test(pastedText)) {
            event.preventDefault();
            showPasteBlockedMessage(state);
        }
    }

    function insertVariable(state, name) {
        var token = "{{" + name + "}}";
        var target = state.lastFocusTarget;
        if (target && target.getAttribute && target.getAttribute("data-vct-field") === "TEXTO09") {
            insertAtInput(target, token);
            return;
        }
        insertHtmlAtCursor(state, escHtml(token));
    }

    function selectImage(state, img) {
        clearImageSelection(state);
        state.selectedImage = img;
        img.classList.add("vct-email-img-selected");
    }
    function clearImageSelection(state) {
        if (state.selectedImage) state.selectedImage.classList.remove("vct-email-img-selected");
        state.selectedImage = null;
    }
    function removeSelectedImage(state) {
        if (!state.selectedImage) return;
        var img = state.selectedImage;
        state.selectedImage = null;
        img.remove();
        state.dirty = true;
        syncOutput(state);
        updateWordCount(state);
    }
    function alignImage(img, align) {
        img.style.display = "block";
        img.style.float = "none";
        img.style.marginTop = "8px";
        img.style.marginBottom = "8px";
        if (align === "left") { img.style.marginLeft = "0"; img.style.marginRight = "auto"; }
        else if (align === "right") { img.style.marginLeft = "auto"; img.style.marginRight = "0"; }
        else { img.style.marginLeft = "auto"; img.style.marginRight = "auto"; }
    }

    function buildTableHtml(rows, cols) {
        rows = Math.max(1, Math.min(10, rows || 2));
        cols = Math.max(1, Math.min(6, cols || 2));
        var html = '<table style="width:100%;border-collapse:collapse;margin:8px 0;">';
        for (var r = 0; r < rows; r++) {
            html += "<tr>";
            for (var c = 0; c < cols; c++)
                html += '<td style="border:1px solid #e2e8f0;padding:6px 8px;font-size:13px;">&nbsp;</td>';
            html += "</tr>";
        }
        html += "</table>";
        return html;
    }

    function applyRich(state, cmd, value) {
        var isAlign = cmd === "justifyLeft" || cmd === "justifyCenter" || cmd === "justifyRight";
        if (isAlign && state.selectedImage && state.editorBody.contains(state.selectedImage)) {
            alignImage(state.selectedImage, cmd === "justifyLeft" ? "left" : cmd === "justifyRight" ? "right" : "center");
            state.editorBody.dispatchEvent(new Event("input", { bubbles:true }));
            return;
        }
        state.editorBody.focus();
        restoreSelectionRange(state);
        if (cmd === "createLink") {
            var url = window.prompt("URL del vínculo", "https://");
            if (!url) return;
            document.execCommand("createLink", false, url);
        } else if (cmd === "insertTable") {
            var rows = parseInt(window.prompt("Cantidad de filas", "2"), 10) || 2;
            var cols = parseInt(window.prompt("Cantidad de columnas", "2"), 10) || 2;
            insertHtmlAtCursor(state, buildTableHtml(rows, cols));
            return;
        } else {
            document.execCommand(cmd, false, value || null);
        }
        state.editorBody.dispatchEvent(new Event("input", { bubbles:true }));
    }

    function updateWordCount(state) {
        if (state.wordCountEl) state.wordCountEl.textContent = wordCount(state.editorBody.textContent) + " palabras";
    }

    function syncOutput(state) {
        var html = cleanBodyHtml(state.editorBody.innerHTML);
        setField(state.root, "TEXTO10", wrapEmailHtml(html));
        setField(state.root, "TEXTO11", JSON.stringify({ version:2, editor:"richtext" }));
        if (state.previewFrame) state.previewFrame.srcdoc = wrapEmailHtml(html);
        updateWordCount(state);
    }

    /* La vista previa ahora vive siempre visible, al lado del editor (split
       view) — ya no hay que togglearla. Esta función solo cambia el ancho
       simulado del iframe (Escritorio/Móvil); togglePreview(state,false) se
       conserva como no-op de compatibilidad para las llamadas existentes en
       openEditor/clearForm. */
    function setDeviceMode(state, mode) {
        mode = mode === "mobile" ? "mobile" : "desktop";
        state.deviceMode = mode;
        var wrap = state.root.querySelector("[data-vct-email-live-preview]");
        if (wrap) wrap.classList.toggle("is-mobile", mode === "mobile");
        state.root.querySelectorAll("[data-vct-email-device]").forEach(function (btn) {
            btn.classList.toggle("is-active", btn.getAttribute("data-vct-email-device") === mode);
        });
        resizePreviewFrame(state);
    }

    /* El email interno siempre se renderiza a su ancho real de diseño
       (600px, igual que en un cliente de correo) para que la tabla nunca
       tenga que reflowar ni generar scroll propio. Para "mostrar" un ancho
       menor (columna angosta o toggle Movil) escalamos el iframe entero con
       transform, como hace un celular al abrir una pagina no responsive, y
       recalculamos el alto reservado del contenedor para que no quede un
       hueco ni aparezca ningun scrollbar. */
    var EMAIL_CONTENT_WIDTH = 600;
    var MOBILE_PREVIEW_WIDTH = 340;

    function resizePreviewFrame(state) {
        var frame = state.previewFrame;
        if (!frame) return;
        var wrap = frame.parentElement;
        try {
            var doc = frame.contentDocument || frame.contentWindow.document;
            var naturalH = doc.documentElement ? doc.documentElement.scrollHeight : doc.body.scrollHeight;
            naturalH = Math.max(naturalH, 280);
            frame.style.height = naturalH + "px";

            var targetWidth = state.deviceMode === "mobile" ? MOBILE_PREVIEW_WIDTH : (wrap ? wrap.clientWidth : EMAIL_CONTENT_WIDTH);
            var scale = Math.min(1, targetWidth / EMAIL_CONTENT_WIDTH);
            frame.style.transform = scale < 1 ? "scale(" + scale + ")" : "";
            if (wrap) wrap.style.height = Math.round(naturalH * scale) + "px";
        } catch (e) { /* cross-origin u otro edge case: se mantiene el min-height del CSS */ }
    }
    function togglePreview(state, force) {
        if (force === false) setDeviceMode(state, "desktop");
    }

    function insertServerBanner(state, url) {
        url = trim(url);
        if (!url) return;
        /* Los clientes de correo no tienen "pagina actual": una ruta relativa
           como ../img/banner.png no resuelve al enviar el mail (aunque en el
           iframe de preview si funciona, porque ahi si hay un documento base).
           Por eso guardamos siempre la URL absoluta, resuelta contra el
           dominio donde corre la app en este momento (desa/test/prod). */
        var absoluteUrl = url;
        try { absoluteUrl = new URL(url, window.location.href).href; } catch (e) { /* deja la url original si no se puede resolver */ }
        var img = new Image();
        img.onload = function () {
            var width = 600;
            var ratio = img.naturalWidth ? (img.naturalHeight / img.naturalWidth) : .15;
            var height = Math.round(width * ratio) || 90;
            var html = '<img src="' + escAttr(absoluteUrl) + '" alt="" width="' + width + '" height="' + height + '" style="max-width:100%;width:100%;height:auto;display:block;margin:0;">';
            insertHtmlAtCursor(state, html);
        };
        img.onerror = function () {
            var box = state.root.querySelector("[data-vct-validation-box]");
            if (box) box.textContent = "No se pudo cargar el banner desde " + url;
        };
        img.src = url;
    }

    function loadContent(state, texto10, texto11) {
        var html = trim(texto10);
        html = html ? extractBodyInnerHtml(html) : defaultBodyHtml();
        state.editorBody.innerHTML = cleanBodyHtml(html);
        state.selectedImage = null;
        updateWordCount(state);
    }

    function clearForm(state) {
        ["TEXTO01","TEXTO02","TEXTO05","TEXTO07","TEXTO09","TEXTO10","TEXTO11","IDSELEC01"].forEach(function (n) { setField(state.root,n,""); });
        setField(state.root,"TEXTO03","MANUAL");
        setField(state.root,"TEXTO04","ANALISTA");
        setField(state.root,"TEXTO06","NINGUNO");
        setField(state.root,"TEXTO08","ACTIVO");
        setField(state.root,"TEXTO30","EMAIL_TEMPLATE");
        setField(state.root,"ACTIVE_TAB","email-templates");
        setField(state.root,"FLAG03","0");
        setField(state.root,"FLAG01","1");
        state.dirty = false;
        state.editorBody.innerHTML = cleanBodyHtml(defaultBodyHtml());
        state.selectedImage = null;
        updateWordCount(state);
        togglePreview(state, false);
        updateConditionalFields(state);
    }

    function openEditor(state, mode, row) {
        state.mode = mode || "create";
        if (state.title) state.title.textContent = state.mode === "edit" ? "Editar template de email" : "Nuevo template de email";

        if (state.mode === "edit" && row) {
            setField(state.root,"IDSELEC01", row.getAttribute("data-vct-id") || "");
            setField(state.root,"TEXTO01", row.getAttribute("data-vct-codigo") || "");
            setField(state.root,"TEXTO02", row.getAttribute("data-vct-descripcion") || "");
            setField(state.root,"TEXTO03", row.getAttribute("data-vct-tipo-envio") || "MANUAL");
            setField(state.root,"TEXTO04", row.getAttribute("data-vct-destino-tipo") || "ANALISTA");
            setField(state.root,"TEXTO05", row.getAttribute("data-vct-destino-libre") || "");
            setField(state.root,"TEXTO06", row.getAttribute("data-vct-cc-tipo") || "NINGUNO");
            setField(state.root,"TEXTO07", row.getAttribute("data-vct-cc-libre") || "");
            setField(state.root,"TEXTO08", row.getAttribute("data-vct-estado") || "ACTIVO");
            setField(state.root,"TEXTO09", row.getAttribute("data-vct-asunto") || "");
            setField(state.root,"TEXTO30","EMAIL_TEMPLATE");
            setField(state.root,"ACTIVE_TAB","email-templates");
            setField(state.root,"FLAG03","0");
            setField(state.root,"FLAG01","1");
            loadContent(state, row.getAttribute("data-vct-html-contenido") || "", row.getAttribute("data-vct-diseno-json") || "");
            togglePreview(state, false);
        } else {
            clearForm(state);
        }

        updateConditionalFields(state);
        if (state.list) state.list.classList.remove("is-active");
        state.root.classList.add("is-active");
        state.root.scrollIntoView({ block:"start", behavior:"smooth" });
        state.dirty = false;
        syncOutput(state);
    }

    function closeEditor(state) {
        state.root.classList.remove("is-active");
        if (state.list) state.list.classList.add("is-active");
        if (state.list) state.list.scrollIntoView({ block:"start", behavior:"smooth" });
    }

    function showSaveError(state, message) {
        var box = state.root.querySelector("[data-vct-validation-box]");
        message = trim(message) || "No se pudo guardar el template.";
        if (box) {
            box.innerHTML = '<div class="vct-validation-title">No se pudo guardar el template</div><ul><li>' + escHtml(message) + '</li></ul>';
            box.style.display = "block";
            try { box.scrollIntoView({ block:"center", behavior:"smooth" }); } catch (e) {}
        }
    }

    function save(state, button) {
        /*
           #vctConfigEmailTemplateEditor tiene data-vct-form-scope y todos sus
           campos data-vct-field, igual que cualquier form generado por
           VCT_MAIN_RENDER_FORM. Eso alcanza para que VCT.DomForm.validateAndNext
           lo trate como el formulario activo: su activateScope() ya se encarga
           de sacarle name="SP.*" a los modales de Servicios/Normas antes de
           persistir (evita el "Campo duplicado antes de almacenar" sin que este
           editor tenga que hacer nada especial), valida con VCT.Validation.validate
           (usa el mismo [data-vct-validation-box] que ya tenemos), escribe el
           buffer campo por campo con VCT.Buffer.storeQueued y recién ahí llama
           VCT.Navigation.next(). Es el mismo camino que ya usan Servicios y
           Normas en esta misma pantalla — no hace falta reimplementarlo.
        */
        syncOutput(state);
        updateConditionalFields(state);
        setField(state.root,"TEXTO30","EMAIL_TEMPLATE");
        setField(state.root,"ACTIVE_TAB","email-templates");
        setField(state.root,"FLAG03","0");
        setField(state.root,"FLAG01","1");

        /* IDSELEC01 es numérico en VCT_BUFFER: "" hace fallar la escritura al
           crear un template nuevo ("No se pudo escribir IDSELEC01..."). Se
           manda "0" como sentinel técnico; la SP lo normaliza de nuevo a
           vacío antes de decidir INSERT vs UPDATE. */
        if (state.mode === "create") setField(state.root, "IDSELEC01", "0");

        if (!window.VCT || !VCT.DomForm || typeof VCT.DomForm.validateAndNext !== "function") {
            showSaveError(state, "VCT.DomForm no está disponible. No se realizó ningún postback.");
            return false;
        }
        return VCT.DomForm.validateAndNext(button);
    }

    function toggleCellExpand(button) {
        var cell = button.closest(".vct-table-cell-truncatable");
        if (!cell) return;
        cell.classList.toggle("is-expanded");
    }

    function bind(state) {
        if (state.root.dataset.vctEmailDesignerReady === "1") return;
        state.root.dataset.vctEmailDesignerReady = "1";
        buildVariablesPanel(state);

        var panel = state.root.closest('[data-vct-config-panel="email-templates"], [data-vct-param-group-panel="email-templates"]');
        if (!panel) return;

        panel.addEventListener("click", function (event) {
            var newBtn = event.target.closest("[data-vct-email-new]");
            if (newBtn) { event.preventDefault(); openEditor(state,"create",null); return; }

            var editBtn = event.target.closest("[data-vct-email-edit]");
            if (editBtn) { event.preventDefault(); openEditor(state,"edit",editBtn.closest("[data-vct-row]")); return; }

            var cancel = event.target.closest("[data-vct-email-cancel]");
            if (cancel && state.root.contains(cancel)) { event.preventDefault(); closeEditor(state); return; }

            var saveBtn = event.target.closest("[data-vct-email-save]");
            if (saveBtn && state.root.contains(saveBtn)) { event.preventDefault(); save(state,saveBtn); return; }

            var deviceBtn = event.target.closest("[data-vct-email-device]");
            if (deviceBtn && state.root.contains(deviceBtn)) { event.preventDefault(); setDeviceMode(state, deviceBtn.getAttribute("data-vct-email-device")); return; }

            var richBtn = event.target.closest("[data-vct-email-rich]");
            if (richBtn && state.root.contains(richBtn)) {
                event.preventDefault();
                applyRich(state, richBtn.getAttribute("data-vct-email-rich"), richBtn.getAttribute("data-vct-email-rich-value"));
                return;
            }

            var varCard = event.target.closest("[data-vct-email-variable]");
            if (varCard && state.root.contains(varCard)) { event.preventDefault(); insertVariable(state, varCard.getAttribute("data-vct-email-variable")); return; }

            var removeImageBtn = event.target.closest("[data-vct-email-remove-image]");
            if (removeImageBtn && state.root.contains(removeImageBtn)) { event.preventDefault(); removeSelectedImage(state); return; }

            var cellExpandBtn = event.target.closest("[data-vct-cell-expand]");
            if (cellExpandBtn) { event.preventDefault(); toggleCellExpand(cellExpandBtn); return; }
        });

        var bannerSelect = state.root.querySelector("[data-vct-email-banner-select]");
        if (bannerSelect) {
            bannerSelect.addEventListener("mousedown", function () { saveSelectionRange(state); });
            bannerSelect.addEventListener("change", function () {
                if (bannerSelect.value) insertServerBanner(state, bannerSelect.value);
                bannerSelect.value = "";
            });
        }

        var variablesSearch = state.root.querySelector("[data-vct-email-variables-search]");
        if (variablesSearch) {
            variablesSearch.addEventListener("input", function () { filterVariables(state, variablesSearch.value); });
        }

        if (state.previewFrame) {
            state.previewFrame.addEventListener("load", function () { resizePreviewFrame(state); });
            window.addEventListener("resize", function () {
                if (state.root.classList.contains("is-active")) resizePreviewFrame(state);
            });
        }

        state.editorBody.addEventListener("paste", function (event) { handlePaste(state, event); });
        state.editorBody.addEventListener("input", function () { state.dirty = true; syncOutput(state); });
        state.editorBody.addEventListener("click", function (event) {
            var img = event.target.closest("img");
            if (img && state.editorBody.contains(img)) selectImage(state, img);
            else clearImageSelection(state);
        });
        state.editorBody.addEventListener("mouseup", function () { saveSelectionRange(state); });
        state.editorBody.addEventListener("keyup", function () { saveSelectionRange(state); });
        state.editorBody.addEventListener("keydown", function (event) {
            if ((event.key === "Delete" || event.key === "Backspace") && state.selectedImage) {
                event.preventDefault();
                removeSelectedImage(state);
            }
        });

        state.root.addEventListener("focusin", function (event) {
            var t = event.target;
            if (t === state.editorBody || (t.getAttribute && t.getAttribute("data-vct-field") === "TEXTO09"))
                state.lastFocusTarget = t;
        });

        state.root.addEventListener("change", function (event) {
            var f = event.target.getAttribute && event.target.getAttribute("data-vct-field");
            if (f === "TEXTO04" || f === "TEXTO06") updateConditionalFields(state);
        });

        var paragraphSelect = state.root.querySelector("[data-vct-email-rich-block]");
        if (paragraphSelect) {
            paragraphSelect.addEventListener("mousedown", function () { saveSelectionRange(state); });
            paragraphSelect.addEventListener("change", function () { applyRich(state,"formatBlock", paragraphSelect.value); });
        }

        var colorInput = state.root.querySelector("[data-vct-email-rich-color]");
        if (colorInput) {
            colorInput.addEventListener("mousedown", function () { saveSelectionRange(state); });
            colorInput.addEventListener("change", function () { applyRich(state,"foreColor", colorInput.value); });
        }

        updateConditionalFields(state);

        if (state.root.getAttribute("data-vct-server-open") === "1") {
            state.mode = trim(getField(state.root,"IDSELEC01")) ? "edit" : "create";
            loadContent(state, getField(state.root,"TEXTO10"), getField(state.root,"TEXTO11"));
            if (state.list) state.list.classList.remove("is-active");
            state.root.classList.add("is-active");
        } else {
            state.editorBody.innerHTML = cleanBodyHtml(defaultBodyHtml());
            updateWordCount(state);
        }
    }

    Designer.init = function (scope) {
        scope = scope || document;
        var roots = [];
        if (scope.matches && scope.matches("[data-vct-email-editor]")) roots.push(scope);
        if (scope.querySelectorAll) scope.querySelectorAll("[data-vct-email-editor]").forEach(function (r) { roots.push(r); });
        roots.forEach(function (root) { bind(makeState(root)); });
        if (window.VCT && VCT.Icon && typeof VCT.Icon.init === "function") VCT.Icon.init(scope);
        if (window.VCT && VCT.Select && typeof VCT.Select.init === "function") VCT.Select.init(scope);
    };

    window.VCTEmailTemplateDesigner = Designer;
    Designer.init(document);

    if (window.MutationObserver) {
        new MutationObserver(function (mutations) {
            mutations.forEach(function (m) {
                Array.prototype.forEach.call(m.addedNodes || [], function (n) {
                    if (n && n.nodeType === 1) Designer.init(n);
                });
            });
        }).observe(document.documentElement, { childList:true, subtree:true });
    }

})(window, document);
