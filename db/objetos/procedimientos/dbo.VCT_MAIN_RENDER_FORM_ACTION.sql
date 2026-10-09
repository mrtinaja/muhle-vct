 
/* =============================================================================
   dbo.VCT_MAIN_RENDER_FORM_ACTION
   -----------------------------------------------------------------------------
   Renderer genérico de acciones que abren formularios VCT.
 
   OBJETIVO:
   El JS NO conoce Clientes / Consultores / Empleados / Proveedores.
   Todo el texto, icono, destino y modo sale del SP llamador.
 
   @MODE
       CREATE = limpia el formulario y lo abre con sus DEFAULT_VALUE.
       EDIT   = carga data-vct-* de la fila seleccionada y abre el formulario.
 
   @TARGET_FORM
       Id DOM generado por VCT_MAIN_RENDER_FORM.
 
   @FORM_TITLE / @FORM_SUBTITLE / @FORM_ICON
       Cambian dinámicamente el header del mismo formulario.
 
   @BUTTON_TEXT
       Texto visible del botón.
       Si se informa vacío, queda botón sólo icono.
 
   @BUTTON_ICON
       Icono del botón que dispara la acción.
 
   @BUTTON_CLASS
       Clase visual del botón.
       Ejemplos:
         vct-btn vct-btn-new vct-btn-sm
         vct-grid-icon-btn vct-grid-icon-btn-edit
 
   @SOURCE_SELECTOR
       Sólo EDIT.
       Define dónde buscar los data-vct-* del registro.
       Default: [data-vct-row]
 
   IMPORTANTE:
   - No modifica ACTION.
   - No ejecuta next() al abrir.
   - Sirve igual para MODAL / DRAWER / PAGE.
   ============================================================================= */
CREATE   PROCEDURE dbo.VCT_MAIN_RENDER_FORM_ACTION
(
    @MODE             VARCHAR(20),             -- CREATE / EDIT
    @TARGET_FORM      VARCHAR(100),            -- Id DOM del formulario
    @FORM_TITLE       VARCHAR(200),            -- Título dinámico
    @FORM_SUBTITLE    VARCHAR(500) = '',       -- Subtítulo dinámico
    @FORM_ICON        VARCHAR(50) = '',        -- Icono header
    @BUTTON_TEXT      VARCHAR(100) = '',       -- Texto botón
    @BUTTON_ICON      VARCHAR(50) = '',        -- Icono botón
    @BUTTON_CLASS     VARCHAR(300) = '',       -- Clases CSS botón
    @TOOLTIP          VARCHAR(200) = '',       -- Tooltip/aria
    @SOURCE_SELECTOR  VARCHAR(200) = '[data-vct-row]',
    @OUTHTML          VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @OUTHTML='';
 
    SET @MODE=UPPER(LTRIM(RTRIM(ISNULL(@MODE,''))));
 
    IF @MODE NOT IN ('CREATE','EDIT')
    BEGIN
        RAISERROR('VCT_MAIN_RENDER_FORM_ACTION: MODE debe ser CREATE o EDIT.',16,1);
        RETURN;
    END;
 
    IF NULLIF(LTRIM(RTRIM(ISNULL(@TARGET_FORM,''))),'') IS NULL
    BEGIN
        RAISERROR('VCT_MAIN_RENDER_FORM_ACTION: TARGET_FORM es obligatorio.',16,1);
        RETURN;
    END;
 
    IF NULLIF(@BUTTON_CLASS,'') IS NULL
        SET @BUTTON_CLASS='vct-btn vct-btn-outline vct-btn-sm';
 
    DECLARE @COMMAND VARCHAR(50);
 
    /* El comando es genérico.
       El JS inspecciona si TARGET_FORM es modal, drawer o page. */
    SET @COMMAND=
        CASE
            WHEN @MODE='CREATE' THEN 'form-open-empty'
            ELSE 'form-open-data'
        END;
 
    SET @OUTHTML=
        '<button type="button" '+
        'class="'+REPLACE(ISNULL(@BUTTON_CLASS,''),'"','&quot;')+'" '+
        'data-vct-command="'+@COMMAND+'" '+
        'data-vct-target="'+REPLACE(ISNULL(@TARGET_FORM,''),'"','&quot;')+'" '+
        'data-vct-form-title="'+REPLACE(ISNULL(@FORM_TITLE,''),'"','&quot;')+'" '+
        'data-vct-form-subtitle="'+REPLACE(ISNULL(@FORM_SUBTITLE,''),'"','&quot;')+'" '+
        'data-vct-form-icon="'+REPLACE(ISNULL(@FORM_ICON,''),'"','&quot;')+'" '+
        CASE
            WHEN @MODE='EDIT'
            THEN 'data-vct-source-selector="'+REPLACE(ISNULL(@SOURCE_SELECTOR,'[data-vct-row]'),'"','&quot;')+'" '
            ELSE ''
        END+
        CASE
            WHEN NULLIF(@TOOLTIP,'') IS NOT NULL
            THEN 'data-vct-tooltip="'+REPLACE(@TOOLTIP,'"','&quot;')+'" aria-label="'+REPLACE(@TOOLTIP,'"','&quot;')+'" '
            ELSE ''
        END+
        '>'+
        CASE
            WHEN NULLIF(@BUTTON_ICON,'') IS NOT NULL
            THEN '<span data-vct-icon="'+REPLACE(@BUTTON_ICON,'"','&quot;')+'"></span>'
            ELSE ''
        END+
        CASE
            WHEN NULLIF(@BUTTON_TEXT,'') IS NOT NULL
            THEN '<span>'+REPLACE(REPLACE(REPLACE(ISNULL(@BUTTON_TEXT,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>'
            ELSE ''
        END+
        '</button>';
END
