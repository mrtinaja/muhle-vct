 
CREATE PROCEDURE [dbo].[VCT_RENDER_BREADCRUMB]
(
    @FORM_ID      VARCHAR(100),   -- FORM_ID actual, se usa en el goto de cada paso clickeable
 
    -- Hasta 3 pasos, en orden (Paso1 > Paso2 > Paso3). Cada paso:
    --   LABEL  = texto a mostrar
    --   GUID   = PKEY de destino en CALL_CONV_STRUCTURES para saltar ahi con window.goto.
    --            NULL = este es el paso ACTUAL (no clickeable, se resalta distinto).
    --   KEY1/VAL1, KEY2/VAL2, KEY3/VAL3 = hasta 3 pares para almacenarSeleccion(KEY,VAL)
    --            ANTES del goto. Dejar todos NULL para un salto "limpio" (ej: Volver,
    --            que no necesita guardar nada). Completar cuando el salto SI necesita
    --            llevar datos (ej: ir a Vista 360 necesitando el CUIT en IDCLIENTE).
    @STEP1_LABEL  VARCHAR(100) = NULL,
    @STEP1_GUID   VARCHAR(100) = NULL,
    @STEP1_KEY1   VARCHAR(100) = NULL, @STEP1_VAL1 VARCHAR(200) = NULL,
    @STEP1_KEY2   VARCHAR(100) = NULL, @STEP1_VAL2 VARCHAR(200) = NULL,
    @STEP1_KEY3   VARCHAR(100) = NULL, @STEP1_VAL3 VARCHAR(200) = NULL,
 
    @STEP2_LABEL  VARCHAR(100) = NULL,
    @STEP2_GUID   VARCHAR(100) = NULL,
    @STEP2_KEY1   VARCHAR(100) = NULL, @STEP2_VAL1 VARCHAR(200) = NULL,
    @STEP2_KEY2   VARCHAR(100) = NULL, @STEP2_VAL2 VARCHAR(200) = NULL,
    @STEP2_KEY3   VARCHAR(100) = NULL, @STEP2_VAL3 VARCHAR(200) = NULL,
 
    @STEP3_LABEL  VARCHAR(100) = NULL,
    @STEP3_GUID   VARCHAR(100) = NULL,
    @STEP3_KEY1   VARCHAR(100) = NULL, @STEP3_VAL1 VARCHAR(200) = NULL,
    @STEP3_KEY2   VARCHAR(100) = NULL, @STEP3_VAL2 VARCHAR(200) = NULL,
    @STEP3_KEY3   VARCHAR(100) = NULL, @STEP3_VAL3 VARCHAR(200) = NULL,
 
    @HTML         VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @FORM_ID_JS VARCHAR(200) = REPLACE(REPLACE(ISNULL(@FORM_ID, ''), '\', '\\'), '''', '\''');
    DECLARE @Q CHAR(1) = CHAR(34); -- comilla doble, para armar el onclick en JS
 
    DECLARE @HTML_STEPS VARCHAR(MAX) = '';
    DECLARE @I INT = 1;
 
    DECLARE
        @Label VARCHAR(100), @Guid VARCHAR(100),
        @K1 VARCHAR(100), @V1 VARCHAR(200),
        @K2 VARCHAR(100), @V2 VARCHAR(200),
        @K3 VARCHAR(100), @V3 VARCHAR(200);
 
    WHILE @I <= 3
    BEGIN
        SELECT
            @Label = CASE @I WHEN 1 THEN @STEP1_LABEL WHEN 2 THEN @STEP2_LABEL ELSE @STEP3_LABEL END,
            @Guid  = CASE @I WHEN 1 THEN @STEP1_GUID  WHEN 2 THEN @STEP2_GUID  ELSE @STEP3_GUID  END,
            @K1    = CASE @I WHEN 1 THEN @STEP1_KEY1  WHEN 2 THEN @STEP2_KEY1  ELSE @STEP3_KEY1  END,
            @V1    = CASE @I WHEN 1 THEN @STEP1_VAL1  WHEN 2 THEN @STEP2_VAL1  ELSE @STEP3_VAL1  END,
            @K2    = CASE @I WHEN 1 THEN @STEP1_KEY2  WHEN 2 THEN @STEP2_KEY2  ELSE @STEP3_KEY2  END,
            @V2    = CASE @I WHEN 1 THEN @STEP1_VAL2  WHEN 2 THEN @STEP2_VAL2  ELSE @STEP3_VAL2  END,
            @K3    = CASE @I WHEN 1 THEN @STEP1_KEY3  WHEN 2 THEN @STEP2_KEY3  ELSE @STEP3_KEY3  END,
            @V3    = CASE @I WHEN 1 THEN @STEP1_VAL3  WHEN 2 THEN @STEP2_VAL3  ELSE @STEP3_VAL3  END;
 
        IF ISNULL(@Label, '') <> ''
        BEGIN
            DECLARE @LabelEsc VARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Label,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
            IF @HTML_STEPS <> ''
                SET @HTML_STEPS = @HTML_STEPS + '<span class="vct-breadcrumb-sep">/</span>';
 
            IF ISNULL(@Guid, '') = ''
            BEGIN
                -- Paso actual: texto plano, no clickeable
                SET @HTML_STEPS = @HTML_STEPS + '<span class="vct-breadcrumb-step is-current">' + @LabelEsc + '</span>';
            END
            ELSE
            BEGIN
                -- Paso clickeable: arma hasta 3 almacenarSeleccion(K,V) (solo los que
                -- tengan KEY no vacio) y despues window.goto(FORM_ID, Guid). Si ningun
                -- KEY viene cargado, el onclick queda como un goto "limpio" sin guardar nada.
                DECLARE @OnClick VARCHAR(MAX) = 'if(typeof window.almacenarSeleccion===' + @Q + 'function' + @Q + '){';
 
                IF ISNULL(@K1, '') <> ''
                    SET @OnClick = @OnClick + 'window.almacenarSeleccion(' + @Q + @K1 + @Q + ',' + @Q + ISNULL(@V1,'') + @Q + ');';
                IF ISNULL(@K2, '') <> ''
                    SET @OnClick = @OnClick + 'window.almacenarSeleccion(' + @Q + @K2 + @Q + ',' + @Q + ISNULL(@V2,'') + @Q + ');';
                IF ISNULL(@K3, '') <> ''
                    SET @OnClick = @OnClick + 'window.almacenarSeleccion(' + @Q + @K3 + @Q + ',' + @Q + ISNULL(@V3,'') + @Q + ');';
 
                SET @OnClick = @OnClick + '}' +
                    'if(typeof window.goto===' + @Q + 'function' + @Q + '){' +
                        'window.goto(' + @Q + @FORM_ID_JS + @Q + ',' + @Q + @Guid + @Q + ');' +
                    '}return false;';
 
                -- El onclick va adentro de un atributo HTML delimitado por comillas dobles,
                -- pero el JS de arriba TAMBIEN usa comillas dobles para sus strings (@Q) --
                -- si se pega tal cual, el navegador corta el atributo en la primera comilla
                -- interna y el resto queda roto (el click no hace nada). Hay que escapar
                -- esas comillas a &quot; (el navegador las decodifica antes de ejecutar el
                -- JS, asi que el codigo corre igual, solo que ahora el atributo HTML es valido).
                DECLARE @OnClickAttr VARCHAR(MAX) =
                    REPLACE(REPLACE(REPLACE(REPLACE(@OnClick, '&','&amp;'), '<','&lt;'), '>','&gt;'), @Q, '&quot;');
 
                SET @HTML_STEPS = @HTML_STEPS +
                    '<span class="vct-breadcrumb-step is-link" role="button" onclick="' + @OnClickAttr + '">' + @LabelEsc + '</span>';
            END;
        END;
 
        SET @I = @I + 1;
    END;
 
    SET @HTML = '<nav class="vct-breadcrumb">' + @HTML_STEPS + '</nav>';
END
