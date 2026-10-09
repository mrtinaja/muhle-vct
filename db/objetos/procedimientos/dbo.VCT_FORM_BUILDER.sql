 
CREATE PROCEDURE [dbo].[VCT_FORM_BUILDER]
(
    @FORM_ID             VARCHAR(100),
    @PANEL_ID            VARCHAR(100) = 'form',
    @TITLE_NEW           VARCHAR(200) = 'Nuevo registro',
    @SUBTITLE_NEW        VARCHAR(500) = 'Complete los datos solicitados.',
    @TITLE_EDIT          VARCHAR(200) = 'Editar registro',
    @SUBTITLE_EDIT       VARCHAR(500) = 'Modifique los datos seleccionados.',
    @ICON_NEW            VARCHAR(100) = 'plus',
    @ICON_EDIT           VARCHAR(100) = 'pencil',
    @SUBMIT_NEW_TEXT     VARCHAR(100) = 'Guardar',
    @SUBMIT_EDIT_TEXT    VARCHAR(100) = 'Guardar cambios',
    @STORAGE_KEY         VARCHAR(100) = NULL,
    @PRIMARY_FIELD       VARCHAR(100) = NULL,
    @REQUIRED_PREFIX     VARCHAR(50) = 'idCampo',
    @HTML                VARCHAR(MAX) OUTPUT,
    @REQUIRED_COUNT      INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @HTML = '';
    SET @REQUIRED_COUNT = 0;
 
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NULL
    BEGIN
        SET @HTML = '<div class="vct-form-error">No se encontró #VCT_FORM_FIELDS.</div>';
        RETURN;
    END;
 
    DECLARE @SOURCE_OBJECT_ID INT;
    SET @SOURCE_OBJECT_ID = OBJECT_ID('tempdb..#VCT_FORM_FIELDS');
 
    IF NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'ORDEN'
    )
    OR NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'METADATA'
    )
    OR NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'FIELD_NAME'
    )
    OR NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'LABEL'
    )
    OR NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'TYPE'
    )
    OR NOT EXISTS (
        SELECT 1 FROM tempdb.sys.columns
        WHERE object_id = @SOURCE_OBJECT_ID AND name = 'REQUIRED'
    )
    BEGIN
        SET @HTML = '<div class="vct-form-error">#VCT_FORM_FIELDS no tiene las columnas mínimas requeridas.</div>';
        RETURN;
    END;
 
    CREATE TABLE #VCT_FORM_FIELDS_NORMALIZED
    (
        ORDEN              INT,
        METADATA           VARCHAR(100),
        FIELD_NAME         VARCHAR(100),
        LABEL              VARCHAR(150),
        TYPE               VARCHAR(30),
        REQUIRED           BIT,
        OPTIONS_HTML       VARCHAR(MAX),
        ICON               VARCHAR(50),
        ROWS               INT,
        FULL_WIDTH         BIT,
        PLACEHOLDER        VARCHAR(200),
        MAX_LENGTH         INT,
        READONLY           BIT,
        OPTIONAL_ON_EDIT   BIT,
        CSS_CLASS          VARCHAR(200)
    );
 
    DECLARE
        @HAS_OPTIONS_HTML      BIT = 0,
        @HAS_ICON              BIT = 0,
        @HAS_ROWS              BIT = 0,
        @HAS_FULL_WIDTH        BIT = 0,
        @HAS_PLACEHOLDER       BIT = 0,
        @HAS_MAX_LENGTH        BIT = 0,
        @HAS_READONLY          BIT = 0,
        @HAS_OPTIONAL_ON_EDIT  BIT = 0,
        @HAS_CSS_CLASS         BIT = 0;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'OPTIONS_HTML')
        SET @HAS_OPTIONS_HTML = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'ICON')
        SET @HAS_ICON = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'ROWS')
        SET @HAS_ROWS = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'FULL_WIDTH')
        SET @HAS_FULL_WIDTH = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'PLACEHOLDER')
        SET @HAS_PLACEHOLDER = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'MAX_LENGTH')
        SET @HAS_MAX_LENGTH = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'READONLY')
        SET @HAS_READONLY = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'OPTIONAL_ON_EDIT')
        SET @HAS_OPTIONAL_ON_EDIT = 1;
 
    IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE object_id = @SOURCE_OBJECT_ID AND name = 'CSS_CLASS')
        SET @HAS_CSS_CLASS = 1;
 
    DECLARE @SQL VARCHAR(MAX);
 
    SET @SQL = '
    INSERT INTO #VCT_FORM_FIELDS_NORMALIZED
    (
        ORDEN,
        METADATA,
        FIELD_NAME,
        LABEL,
        TYPE,
        REQUIRED,
        OPTIONS_HTML,
        ICON,
        ROWS,
        FULL_WIDTH,
        PLACEHOLDER,
        MAX_LENGTH,
        READONLY,
        OPTIONAL_ON_EDIT,
        CSS_CLASS
    )
    SELECT
        ORDEN,
        METADATA,
        FIELD_NAME,
        LABEL,
        TYPE,
        REQUIRED,
        ' + CASE WHEN @HAS_OPTIONS_HTML = 1 THEN 'OPTIONS_HTML' ELSE 'NULL' END + ',
        ' + CASE WHEN @HAS_ICON = 1 THEN 'ICON' ELSE 'NULL' END + ',
        ' + CASE WHEN @HAS_ROWS = 1 THEN 'ROWS' ELSE 'NULL' END + ',
        ' + CASE WHEN @HAS_FULL_WIDTH = 1 THEN 'FULL_WIDTH' ELSE '0' END + ',
        ' + CASE WHEN @HAS_PLACEHOLDER = 1 THEN 'PLACEHOLDER' ELSE 'NULL' END + ',
        ' + CASE WHEN @HAS_MAX_LENGTH = 1 THEN 'MAX_LENGTH' ELSE 'NULL' END + ',
        ' + CASE WHEN @HAS_READONLY = 1 THEN 'READONLY' ELSE '0' END + ',
        ' + CASE WHEN @HAS_OPTIONAL_ON_EDIT = 1 THEN 'OPTIONAL_ON_EDIT' ELSE '0' END + ',
        ' + CASE WHEN @HAS_CSS_CLASS = 1 THEN 'CSS_CLASS' ELSE 'NULL' END + '
    FROM #VCT_FORM_FIELDS;';
 
    EXEC (@SQL);
 
    DECLARE
        @VFORM_ID         VARCHAR(100),
        @VPANEL_ID        VARCHAR(100),
        @VSTORAGE_KEY     VARCHAR(100),
        @VPRIMARY_FIELD   VARCHAR(100),
        @VREQUIRED_PREFIX VARCHAR(50),
        @FIELD_COUNT      INT,
        @COLUMN_COUNT     INT;
 
    SET @VFORM_ID = REPLACE(ISNULL(@FORM_ID, ''), '''', '''''');
    SET @VPANEL_ID = ISNULL(NULLIF(LTRIM(RTRIM(@PANEL_ID)), ''), 'form');
    SET @VSTORAGE_KEY = ISNULL(LTRIM(RTRIM(@STORAGE_KEY)), '');
    SET @VPRIMARY_FIELD = ISNULL(LTRIM(RTRIM(@PRIMARY_FIELD)), '');
    SET @VREQUIRED_PREFIX = ISNULL(NULLIF(LTRIM(RTRIM(@REQUIRED_PREFIX)), ''), 'idCampo');
 
    SELECT @FIELD_COUNT = COUNT(*)
    FROM #VCT_FORM_FIELDS_NORMALIZED
    WHERE ISNULL(TYPE, 'text') <> 'hidden';
 
    IF ISNULL(@FIELD_COUNT, 0) <= 4
        SET @COLUMN_COUNT = 1;
    ELSE IF @FIELD_COUNT <= 8
        SET @COLUMN_COUNT = 2;
    ELSE
        SET @COLUMN_COUNT = 3;
 
    SET @HTML = '
<div class="vct-panel"
     data-vct-panel="' + REPLACE(@VPANEL_ID, '"', '&quot;') + '"
     data-vct-new-form-title="' + REPLACE(ISNULL(@TITLE_NEW, ''), '"', '&quot;') + '"
     data-vct-edit-form-title="' + REPLACE(ISNULL(@TITLE_EDIT, ''), '"', '&quot;') + '"
     data-vct-new-form-subtitle="' + REPLACE(ISNULL(@SUBTITLE_NEW, ''), '"', '&quot;') + '"
     data-vct-edit-form-subtitle="' + REPLACE(ISNULL(@SUBTITLE_EDIT, ''), '"', '&quot;') + '"
     data-vct-new-submit-label="' + REPLACE(ISNULL(@SUBMIT_NEW_TEXT, ''), '"', '&quot;') + '"
     data-vct-edit-submit-label="' + REPLACE(ISNULL(@SUBMIT_EDIT_TEXT, ''), '"', '&quot;') + '"
     hidden
     aria-hidden="true">
 
    <div class="vct-form-card">
        <div class="vct-form-header">
            <div class="vct-form-icon" data-vct-form-icon>
                <i data-lucide="' + REPLACE(ISNULL(@ICON_NEW, 'plus'), '"', '') + '"></i>
            </div>
 
            <div>
                <h3 class="vct-form-title" data-vct-form-title>' + ISNULL(@TITLE_NEW, '') + '</h3>
                <p class="vct-form-subtitle" data-vct-form-subtitle>' + ISNULL(@SUBTITLE_NEW, '') + '</p>
            </div>
        </div>
 
        <div class="vct-form-body">
            <input type="hidden" value="NEW" data-vct-form-mode />';
 
    IF @VSTORAGE_KEY <> ''
    BEGIN
        SET @HTML = @HTML + '
            <input type="hidden"
                   id="' + @VSTORAGE_KEY + '"
                   name="SP.' + @VSTORAGE_KEY + '"
                   value=""'
                   + CASE
                        WHEN @VPRIMARY_FIELD <> ''
                        THEN ' data-vct-field="' + REPLACE(@VPRIMARY_FIELD, '"', '&quot;') + '"'
                        ELSE ''
                     END + '
                   data-vct-selected-key />';
    END;
 
    SET @HTML = @HTML + '
            <div class="vct-form-grid vct-form-grid-' + CONVERT(VARCHAR(10), @COLUMN_COUNT) + '"
                 data-vct-form-columns="' + CONVERT(VARCHAR(10), @COLUMN_COUNT) + '">';
 
    DECLARE
        @ORDEN            INT,
        @METADATA         VARCHAR(100),
        @FIELD_NAME       VARCHAR(100),
        @LABEL            VARCHAR(150),
        @TYPE             VARCHAR(30),
        @REQUIRED         BIT,
        @OPTIONS_HTML     VARCHAR(MAX),
        @ICON             VARCHAR(50),
        @ROWS             INT,
        @FULL_WIDTH       BIT,
        @PLACEHOLDER      VARCHAR(200),
        @MAX_LENGTH       INT,
        @READONLY         BIT,
        @OPTIONAL_ON_EDIT BIT,
        @CSS_CLASS        VARCHAR(200),
        @FIELD_HTML       VARCHAR(MAX),
        @FIELD_EFFECTIVE  VARCHAR(100),
        @REQUIRED_ID      VARCHAR(100);
 
    DECLARE CUR_FORM_FIELDS CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        ORDEN,
        METADATA,
        FIELD_NAME,
        LABEL,
        TYPE,
        REQUIRED,
        OPTIONS_HTML,
        ICON,
        ROWS,
        FULL_WIDTH,
        PLACEHOLDER,
        MAX_LENGTH,
        READONLY,
        OPTIONAL_ON_EDIT,
        CSS_CLASS
    FROM #VCT_FORM_FIELDS_NORMALIZED
    ORDER BY ORDEN;
 
    OPEN CUR_FORM_FIELDS;
 
    FETCH NEXT FROM CUR_FORM_FIELDS INTO
        @ORDEN,
        @METADATA,
        @FIELD_NAME,
        @LABEL,
        @TYPE,
        @REQUIRED,
        @OPTIONS_HTML,
        @ICON,
        @ROWS,
        @FULL_WIDTH,
        @PLACEHOLDER,
        @MAX_LENGTH,
        @READONLY,
        @OPTIONAL_ON_EDIT,
        @CSS_CLASS;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @FIELD_HTML = '';
        SET @METADATA = LTRIM(RTRIM(ISNULL(@METADATA, '')));
        SET @TYPE = LOWER(LTRIM(RTRIM(ISNULL(@TYPE, 'text'))));
        SET @FIELD_EFFECTIVE = ISNULL(NULLIF(LTRIM(RTRIM(@FIELD_NAME)), ''), @METADATA);
        SET @REQUIRED_ID = '';
 
        IF @TYPE = 'hidden'
        BEGIN
            SET @FIELD_HTML = '
                <input type="hidden"
                       name="SP.' + @METADATA + '"
                       data-vct-field="' + REPLACE(@FIELD_EFFECTIVE, '"', '&quot;') + '" />';
        END
        ELSE
        BEGIN
            IF ISNULL(@REQUIRED, 0) = 1
            BEGIN
                SET @REQUIRED_COUNT = @REQUIRED_COUNT + 1;
                SET @REQUIRED_ID = @VREQUIRED_PREFIX + CONVERT(VARCHAR(10), @REQUIRED_COUNT);
            END;
 
            SET @FIELD_HTML = '
                <div class="vct-form-group'
                + CASE WHEN ISNULL(@FULL_WIDTH, 0) = 1 THEN ' vct-form-full' ELSE '' END
                + CASE WHEN ISNULL(@CSS_CLASS, '') <> '' THEN ' ' + @CSS_CLASS ELSE '' END
                + '"'
                + CASE WHEN ISNULL(@OPTIONAL_ON_EDIT, 0) = 1 THEN ' data-vct-optional-on-edit' ELSE '' END
                + '>
                    <label>';
 
            IF ISNULL(@ICON, '') <> ''
                SET @FIELD_HTML = @FIELD_HTML
                    + '<i data-lucide="' + REPLACE(@ICON, '"', '') + '"></i>';
 
            SET @FIELD_HTML = @FIELD_HTML
                + '<span>' + ISNULL(@LABEL, @METADATA) + '</span>';
 
            IF ISNULL(@REQUIRED, 0) = 1
            BEGIN
                SET @FIELD_HTML = @FIELD_HTML
                    + '<span id="' + @REQUIRED_ID + '" class="vct-required">'
                    + '<i data-lucide="asterisk"></i>'
                    + '</span>';
            END;
 
            SET @FIELD_HTML = @FIELD_HTML + '</label>';
 
            IF @TYPE = 'select'
            BEGIN
                SET @FIELD_HTML = @FIELD_HTML + '
                    <select class="vct-input"
                            name="SP.' + @METADATA + '"
                            data-vct-field="' + REPLACE(@FIELD_EFFECTIVE, '"', '&quot;') + '"'
                            + CASE WHEN ISNULL(@READONLY, 0) = 1 THEN ' disabled' ELSE '' END
                            + CASE WHEN ISNULL(@OPTIONAL_ON_EDIT, 0) = 1 THEN ' data-vct-optional-on-edit' ELSE '' END
                            + '>'
                            + ISNULL(@OPTIONS_HTML, '<option value="">Seleccione...</option>')
                            + '</select>';
            END
            ELSE IF @TYPE = 'textarea'
            BEGIN
                SET @FIELD_HTML = @FIELD_HTML + '
                    <textarea class="vct-input"
                              name="SP.' + @METADATA + '"
                              data-vct-field="' + REPLACE(@FIELD_EFFECTIVE, '"', '&quot;') + '"
                              rows="' + CONVERT(VARCHAR(10), CASE WHEN ISNULL(@ROWS, 0) <= 0 THEN 4 ELSE @ROWS END) + '"'
                              + CASE WHEN ISNULL(@PLACEHOLDER, '') <> '' THEN ' placeholder="' + REPLACE(@PLACEHOLDER, '"', '&quot;') + '"' ELSE '' END
                              + CASE WHEN ISNULL(@MAX_LENGTH, 0) > 0 THEN ' maxlength="' + CONVERT(VARCHAR(20), @MAX_LENGTH) + '"' ELSE '' END
                              + CASE WHEN ISNULL(@READONLY, 0) = 1 THEN ' readonly' ELSE '' END
                              + CASE WHEN ISNULL(@OPTIONAL_ON_EDIT, 0) = 1 THEN ' data-vct-optional-on-edit' ELSE '' END
                              + '></textarea>';
            END
            ELSE IF @TYPE = 'checkbox'
            BEGIN
                SET @FIELD_HTML = @FIELD_HTML + '
                    <input class="vct-input-check"
                           type="checkbox"
                           name="SP.' + @METADATA + '"
                           value="OK"
                           data-vct-field="' + REPLACE(@FIELD_EFFECTIVE, '"', '&quot;') + '"'
                           + CASE WHEN ISNULL(@READONLY, 0) = 1 THEN ' disabled' ELSE '' END
                           + CASE WHEN ISNULL(@OPTIONAL_ON_EDIT, 0) = 1 THEN ' data-vct-optional-on-edit' ELSE '' END
                           + ' />';
            END
            ELSE
            BEGIN
                IF @TYPE NOT IN ('text', 'email', 'password', 'number', 'date', 'tel', 'url')
                    SET @TYPE = 'text';
 
                SET @FIELD_HTML = @FIELD_HTML + '
                    <input class="vct-input"
                           type="' + @TYPE + '"
                           name="SP.' + @METADATA + '"
                           data-vct-field="' + REPLACE(@FIELD_EFFECTIVE, '"', '&quot;') + '"'
                           + CASE WHEN ISNULL(@PLACEHOLDER, '') <> '' THEN ' placeholder="' + REPLACE(@PLACEHOLDER, '"', '&quot;') + '"' ELSE '' END
                           + CASE WHEN ISNULL(@MAX_LENGTH, 0) > 0 AND @TYPE NOT IN ('number', 'date') THEN ' maxlength="' + CONVERT(VARCHAR(20), @MAX_LENGTH) + '"' ELSE '' END
                           + CASE WHEN ISNULL(@READONLY, 0) = 1 THEN ' readonly' ELSE '' END
                           + CASE WHEN ISNULL(@OPTIONAL_ON_EDIT, 0) = 1 THEN ' data-vct-optional-on-edit' ELSE '' END
                           + ' />';
            END;
 
            SET @FIELD_HTML = @FIELD_HTML + '
                </div>';
        END;
 
        SET @HTML = @HTML + @FIELD_HTML;
 
        FETCH NEXT FROM CUR_FORM_FIELDS INTO
            @ORDEN,
            @METADATA,
            @FIELD_NAME,
            @LABEL,
            @TYPE,
            @REQUIRED,
            @OPTIONS_HTML,
            @ICON,
            @ROWS,
            @FULL_WIDTH,
            @PLACEHOLDER,
            @MAX_LENGTH,
            @READONLY,
            @OPTIONAL_ON_EDIT,
            @CSS_CLASS;
    END;
 
    CLOSE CUR_FORM_FIELDS;
    DEALLOCATE CUR_FORM_FIELDS;
 
    SET @HTML = @HTML + '
            </div>
 
            <div class="vct-form-actions">
                <button type="button"
                        class="vct-button vct-button-secondary"
                        data-vct-close-tab="' + REPLACE(@VPANEL_ID, '"', '&quot;') + '"
                        data-vct-fallback-tab="grid"
                        data-vct-reset-on-close>
                    <i data-lucide="x"></i>
                    <span>Cancelar</span>
                </button>
 
                <button type="button"
                        class="vct-button vct-button-primary"
                        onclick="return vctConfirmarGuardar(''' + @VFORM_ID + ''','
                        + CONVERT(VARCHAR(10), @REQUIRED_COUNT)
                        + ',{prefix:''' + REPLACE(@VREQUIRED_PREFIX, '''', '''''') + '''});">
                    <i data-lucide="save"></i>
                    <span class="vct-button-text" data-vct-submit-label>'
                        + ISNULL(@SUBMIT_NEW_TEXT, 'Guardar')
                    + '</span>
                </button>
            </div>
        </div>
    </div>
</div>';
END
