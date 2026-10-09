 
/* =============================================================================
   dbo.VCT_MAIN_RENDER_FORM
   -----------------------------------------------------------------------------
   Renderer genérico de formularios VCT Main.
 
   IDEA:
   - El SP de negocio NO arma HTML de inputs.
   - El SP de negocio crea y carga #VCT_FORM_FIELDS.
   - Este renderer toma esa tabla y genera MODAL / DRAWER / PAGE.
   - name="SP.xxx" sale automáticamente de FIELD_NAME.
   - Los SELECT pueden alimentarse automáticamente desde CAT_TYPE / CAT_DATA.
   - CSS y JS resuelven visual, responsive, validación y comportamiento.
 
   IMPORTANTE:
   La tabla temporal #VCT_FORM_FIELDS debe existir en el SP llamador antes
   de ejecutar este procedimiento.
   ============================================================================= */
CREATE   PROCEDURE dbo.VCT_MAIN_RENDER_FORM
(
    @FORM_ID       VARCHAR(100),          -- Id DOM único. Ej: vctClienteEditModal
    @TITLE         VARCHAR(200),          -- Título visible. Ej: Editar cliente
    @SUBTITLE      VARCHAR(500) = '',     -- Texto secundario opcional
    @ICON          VARCHAR(50) = 'edit',    -- Icono genérico del header. '' = sin icono
    @LAYOUT        VARCHAR(20) = 'MODAL', -- MODAL / DRAWER / PAGE
    @SAVE_LABEL    VARCHAR(100) = 'Guardar',
    @CANCEL_LABEL  VARCHAR(100) = 'Cancelar',
    @ERROR_MESSAGE VARCHAR(MAX) = '',      -- Error de negocio devuelto por el SP llamador
    @OPEN_ON_RENDER BIT = 0,               -- 1=reabrir MODAL/DRAWER preservando valores enviados
    @OUTHTML       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @OUTHTML='';
 
    SET @LAYOUT=UPPER(LTRIM(RTRIM(ISNULL(@LAYOUT,'MODAL'))));
 
    IF @LAYOUT NOT IN ('MODAL','DRAWER','PAGE')
    BEGIN
        RAISERROR('VCT_MAIN_RENDER_FORM: LAYOUT debe ser MODAL, DRAWER o PAGE.',16,1);
        RETURN;
    END;
 
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NULL
    BEGIN
        RAISERROR('VCT_MAIN_RENDER_FORM: no existe #VCT_FORM_FIELDS.',16,1);
        RETURN;
    END;
 
    DECLARE
        @FIELDS_HTML VARCHAR(MAX)='',
        @FIELD_HTML VARCHAR(MAX)='',
        @OPTIONS_HTML VARCHAR(MAX)='',
        @ORDEN INT,
        @FIELD_NAME VARCHAR(50),
        @LABEL VARCHAR(150),
        @FIELD_TYPE VARCHAR(20),
        @COL_SPAN INT,
        @REQUIRED BIT,
        @MAX_LENGTH INT,
        @PLACEHOLDER VARCHAR(250),
        @OPTIONS_SOURCE VARCHAR(100),
        @DEFAULT_VALUE VARCHAR(MAX),
        @READONLY BIT,
        @HIDDEN BIT,
        @HELP_TEXT VARCHAR(500),
        @SOURCE_FIELD VARCHAR(100),
        @VISIBLE_FIELDS INT=0,
        @FORM_SIZE VARCHAR(20)='COMPACT';
 
    /* Tamaño visual automático según cantidad de campos visibles.
       No se configura formulario por formulario:
         1 a 5  -> COMPACT
         6 a 10 -> MEDIUM
         11+    -> LARGE
       El CSS genérico decide ancho, espacios y comportamiento responsive. */
    SELECT @VISIBLE_FIELDS=COUNT(*)
    FROM #VCT_FORM_FIELDS
    WHERE ISNULL(HIDDEN,0)=0
      AND UPPER(ISNULL(FIELD_TYPE,'TEXT'))<>'HIDDEN';
 
    SET @FORM_SIZE=
        CASE
            WHEN @VISIBLE_FIELDS<=5 THEN 'COMPACT'
            WHEN @VISIBLE_FIELDS<=10 THEN 'MEDIUM'
            ELSE 'LARGE'
        END;
 
    DECLARE C_FIELDS CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        ORDEN,FIELD_NAME,LABEL,UPPER(ISNULL(FIELD_TYPE,'TEXT')),
        ISNULL(COL_SPAN,12),ISNULL(REQUIRED,0),MAX_LENGTH,
        ISNULL(PLACEHOLDER,''),ISNULL(OPTIONS_SOURCE,''),
        ISNULL(DEFAULT_VALUE,''),ISNULL(READONLY,0),
        ISNULL(HIDDEN,0),ISNULL(HELP_TEXT,''),
        ISNULL(SOURCE_FIELD,'')
    FROM #VCT_FORM_FIELDS
    ORDER BY ORDEN;
 
    OPEN C_FIELDS;
    FETCH NEXT FROM C_FIELDS INTO
        @ORDEN,@FIELD_NAME,@LABEL,@FIELD_TYPE,@COL_SPAN,@REQUIRED,
        @MAX_LENGTH,@PLACEHOLDER,@OPTIONS_SOURCE,@DEFAULT_VALUE,
        @READONLY,@HIDDEN,@HELP_TEXT,@SOURCE_FIELD;
 
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @FIELD_HTML='';
        SET @OPTIONS_HTML='';
 
        IF @COL_SPAN NOT BETWEEN 1 AND 12 SET @COL_SPAN=12;
 
        /* SELECT de catálogo:
           OPTIONS_SOURCE = CAT_TYPE_CODE.
           value = CAT_DATA_CODE / texto = CAT_DATA_DESC. */
        IF @FIELD_TYPE='SELECT' AND NULLIF(@OPTIONS_SOURCE,'') IS NOT NULL
        BEGIN
            SELECT @OPTIONS_HTML=ISNULL((
                SELECT
                    '<option value="'+
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'"' +
                    CASE WHEN CD.CAT_DATA_CODE COLLATE DATABASE_DEFAULT =
                                   ISNULL(@DEFAULT_VALUE,'') COLLATE DATABASE_DEFAULT
                         THEN ' selected="selected"' ELSE '' END + '>'+
                    REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+
                    '</option>'
                FROM dbo.CAT_DATA CD WITH(NOLOCK)
                WHERE CD.PAR_KEY=
                (
                    SELECT TOP 1 CT.PKEY
                    FROM dbo.CAT_TYPE CT WITH(NOLOCK)
                    WHERE CT.CAT_TYPE_CODE=@OPTIONS_SOURCE
                )
                ORDER BY CD.CAT_DATA_DESC
                FOR XML PATH(''),TYPE
            ).value('.','varchar(max)'),'');
        END;
 
        IF @HIDDEN=1 OR @FIELD_TYPE='HIDDEN'
        BEGIN
            SET @FIELD_HTML=
                '<input type="hidden" name="SP.'+@FIELD_NAME+'" '+
                'data-vct-field="'+@FIELD_NAME+'" '+
                'data-vct-default="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'" '+
                CASE WHEN @SOURCE_FIELD<>'' THEN 'data-vct-source="'+@SOURCE_FIELD+'" ' ELSE '' END+
                'value="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'">';
        END
        ELSE
        BEGIN
            SET @FIELD_HTML=
                '<div class="vct-field vct-col-'+CONVERT(VARCHAR(2),@COL_SPAN)+'">'+
                '<label class="vct-label">'+ISNULL(@LABEL,'')+
                CASE WHEN @REQUIRED=1 THEN ' <span class="vct-required">*</span>' ELSE '' END+
                '</label>';
 
            IF @FIELD_TYPE IN ('TEXT','EMAIL','NUMBER','DECIMAL','DATE')
            BEGIN
                SET @FIELD_HTML=@FIELD_HTML+
                    '<input type="'+CASE
                        WHEN @FIELD_TYPE='EMAIL' THEN 'email'
                        WHEN @FIELD_TYPE='NUMBER' THEN 'number'
                        WHEN @FIELD_TYPE='DATE' THEN 'date'
                        ELSE 'text' END+'" '+
                    'class="vct-input" name="SP.'+@FIELD_NAME+'" '+
                    'data-vct-field="'+@FIELD_NAME+'" '+
                    'data-vct-default="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'" '+
                    'data-vct-label="'+ISNULL(@LABEL,'')+'" '+
                    'data-vct-type="'+LOWER(@FIELD_TYPE)+'" '+
                    CASE WHEN @SOURCE_FIELD<>'' THEN 'data-vct-source="'+@SOURCE_FIELD+'" ' ELSE '' END+
                    CASE WHEN @REQUIRED=1 THEN 'data-vct-required="true" ' ELSE '' END+
                    CASE WHEN @MAX_LENGTH IS NOT NULL THEN 'data-vct-maxlength="'+CONVERT(VARCHAR(10),@MAX_LENGTH)+'" ' ELSE '' END+
                    CASE WHEN @PLACEHOLDER<>'' THEN 'placeholder="'+REPLACE(@PLACEHOLDER,'"','&quot;')+'" ' ELSE '' END+
                    CASE WHEN @READONLY=1 THEN 'readonly ' ELSE '' END+
                    'value="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'">';
            END
            ELSE IF @FIELD_TYPE='TEXTAREA'
            BEGIN
                SET @FIELD_HTML=@FIELD_HTML+
                    '<textarea class="vct-textarea" name="SP.'+@FIELD_NAME+'" '+
                    'data-vct-field="'+@FIELD_NAME+'" '+
                    'data-vct-default="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'" '+
                    'data-vct-label="'+ISNULL(@LABEL,'')+'" '+
                    CASE WHEN @SOURCE_FIELD<>'' THEN 'data-vct-source="'+@SOURCE_FIELD+'" ' ELSE '' END+
                    CASE WHEN @REQUIRED=1 THEN 'data-vct-required="true" ' ELSE '' END+
                    CASE WHEN @MAX_LENGTH IS NOT NULL THEN 'data-vct-maxlength="'+CONVERT(VARCHAR(10),@MAX_LENGTH)+'" ' ELSE '' END+
                    CASE WHEN @PLACEHOLDER<>'' THEN 'placeholder="'+REPLACE(@PLACEHOLDER,'"','&quot;')+'" ' ELSE '' END+
                    CASE WHEN @READONLY=1 THEN 'readonly ' ELSE '' END+
                    'rows="3">'+ISNULL(@DEFAULT_VALUE,'')+'</textarea>';
            END
            ELSE IF @FIELD_TYPE='SELECT'
            BEGIN
                SET @FIELD_HTML=@FIELD_HTML+
                    '<select class="vct-select" data-vct-native="true" name="SP.'+@FIELD_NAME+'" '+
                    'data-vct-field="'+@FIELD_NAME+'" '+
                    'data-vct-default="'+REPLACE(REPLACE(ISNULL(@DEFAULT_VALUE,''),'"','&quot;'),'''','&#39;')+'" '+
                    'data-vct-label="'+ISNULL(@LABEL,'')+'" '+
                    CASE WHEN @SOURCE_FIELD<>'' THEN 'data-vct-source="'+@SOURCE_FIELD+'" ' ELSE '' END+
                    CASE WHEN @REQUIRED=1 THEN 'data-vct-required="true" ' ELSE '' END+
                    CASE WHEN @READONLY=1 THEN 'disabled ' ELSE '' END+'>'+
                    '<option value="">Seleccione...</option>'+ISNULL(@OPTIONS_HTML,'')+
                    '</select>';
            END
            ELSE IF @FIELD_TYPE IN ('CHECKBOX','TOGGLE')
            BEGIN
                SET @FIELD_HTML=@FIELD_HTML+
                    '<label class="vct-toggle">'+
                    '<input type="checkbox" name="SP.'+@FIELD_NAME+'" value="1" '+
                    'data-vct-field="'+@FIELD_NAME+'" data-vct-label="'+ISNULL(@LABEL,'')+'" '+
                    CASE WHEN @SOURCE_FIELD<>'' THEN 'data-vct-source="'+@SOURCE_FIELD+'" ' ELSE '' END+
                    CASE WHEN @REQUIRED=1 THEN 'data-vct-required="true" ' ELSE '' END+'>'+
                    '<span class="vct-toggle-track"><span class="vct-toggle-thumb"></span></span>'+
                    '<span class="vct-toggle-label">'+ISNULL(@LABEL,'')+'</span></label>';
            END
            ELSE
            BEGIN
                SET @FIELD_HTML=@FIELD_HTML+
                    '<div class="vct-alert vct-alert-danger">Tipo de campo no soportado: '+ISNULL(@FIELD_TYPE,'')+'</div>';
            END;
 
            IF @HELP_TEXT<>''
                SET @FIELD_HTML=@FIELD_HTML+'<div class="vct-help">'+@HELP_TEXT+'</div>';
 
            SET @FIELD_HTML=@FIELD_HTML+'</div>';
        END;
 
        SET @FIELDS_HTML=@FIELDS_HTML+ISNULL(@FIELD_HTML,'');
 
        FETCH NEXT FROM C_FIELDS INTO
            @ORDEN,@FIELD_NAME,@LABEL,@FIELD_TYPE,@COL_SPAN,@REQUIRED,
            @MAX_LENGTH,@PLACEHOLDER,@OPTIONS_SOURCE,@DEFAULT_VALUE,
            @READONLY,@HIDDEN,@HELP_TEXT,@SOURCE_FIELD;
    END;
 
    CLOSE C_FIELDS;
    DEALLOCATE C_FIELDS;
 
    /* -------------------------------------------------------------------------
       El mismo formulario se puede presentar como MODAL, DRAWER o PAGE.
       La definición de campos NO cambia.
       ------------------------------------------------------------------------- */
    IF @LAYOUT='MODAL'
    BEGIN
        SET @OUTHTML=
        '<div id="'+@FORM_ID+'" class="vct-modal vct-form-shell vct-form-'+LOWER(@FORM_SIZE)+'" '+
             'data-vct-component="modal" data-vct-id="'+@FORM_ID+'" data-vct-form-scope '+
             CASE WHEN @OPEN_ON_RENDER=1 THEN 'data-vct-auto-open="true" ' ELSE '' END+
             'data-vct-form-size="'+LOWER(@FORM_SIZE)+'">'+
          '<div class="vct-modal-backdrop" data-vct-command="close-modal" data-vct-target="'+@FORM_ID+'"></div>'+
          '<div class="vct-modal-dialog">'+
 
            /* Header estándar: acento institucional + bloque compacto */
            '<div class="vct-modal-header vct-form-header">'+
              '<div class="vct-form-header-accent"></div>'+
              CASE WHEN ISNULL(@ICON,'')<>'' THEN
                   '<div class="vct-form-header-icon" data-vct-form-icon-wrap><span data-vct-icon="'+@ICON+'" data-vct-form-icon></span></div>'
                   ELSE '' END+
              '<div class="vct-form-header-copy">'+
                '<h3 class="vct-modal-title" data-vct-form-title>'+@TITLE+'</h3>'+
                CASE WHEN @SUBTITLE<>'' THEN '<p class="vct-modal-subtitle" data-vct-form-subtitle>'+@SUBTITLE+'</p>' ELSE '' END+
              '</div>'+
              '<button type="button" class="vct-form-close" data-vct-command="close-modal" '+
                      'data-vct-target="'+@FORM_ID+'" aria-label="Cerrar">×</button>'+
            '</div>'+
 
            /* Sólo BODY puede scrollear, y únicamente cuando realmente no entra. */
            '<div class="vct-modal-body vct-form-body">'+
              CASE WHEN ISNULL(@ERROR_MESSAGE,'')<>'' THEN
                '<div class="vct-validation-box vct-validation-box-server" data-vct-validation-box style="display:block;">'+
                  '<div class="vct-validation-title">No se pudo guardar</div>'+
                  '<ul><li>'+REPLACE(REPLACE(REPLACE(ISNULL(@ERROR_MESSAGE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</li></ul>'+
                '</div>'
              ELSE
                '<div class="vct-validation-box" data-vct-validation-box style="display:none;"></div>'
              END+
              '<div class="vct-form-grid">'+@FIELDS_HTML+'</div>'+
            '</div>'+
 
            '<div class="vct-modal-footer vct-form-footer">'+
              '<button type="button" class="vct-btn vct-btn-secondary" data-vct-command="close-modal" '+
                      'data-vct-target="'+@FORM_ID+'">'+@CANCEL_LABEL+'</button>'+
              '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next">'+
                '<span data-vct-icon="save"></span><span>'+@SAVE_LABEL+'</span>'+
              '</button>'+
            '</div>'+
          '</div>'+
        '</div>';
    END
    ELSE IF @LAYOUT='DRAWER'
    BEGIN
        SET @OUTHTML=
        '<div id="'+@FORM_ID+'" class="vct-drawer vct-form-shell vct-form-'+LOWER(@FORM_SIZE)+'" '+
             'data-vct-component="drawer" data-vct-id="'+@FORM_ID+'" data-vct-form-scope '+
             CASE WHEN @OPEN_ON_RENDER=1 THEN 'data-vct-auto-open="true" ' ELSE '' END+
             'data-vct-form-size="'+LOWER(@FORM_SIZE)+'">'+
          '<div class="vct-drawer-backdrop" data-vct-command="close-drawer" data-vct-target="'+@FORM_ID+'"></div>'+
          '<div class="vct-drawer-panel">'+
            '<div class="vct-drawer-header vct-form-header">'+
              '<div class="vct-form-header-accent"></div>'+
              CASE WHEN ISNULL(@ICON,'')<>'' THEN
                   '<div class="vct-form-header-icon" data-vct-form-icon-wrap><span data-vct-icon="'+@ICON+'" data-vct-form-icon></span></div>'
                   ELSE '' END+
              '<div class="vct-form-header-copy">'+
                '<h3 class="vct-drawer-title">'+@TITLE+'</h3>'+
                CASE WHEN @SUBTITLE<>'' THEN '<p class="vct-drawer-subtitle">'+@SUBTITLE+'</p>' ELSE '' END+
              '</div>'+
              '<button type="button" class="vct-form-close" data-vct-command="close-drawer" '+
                      'data-vct-target="'+@FORM_ID+'" aria-label="Cerrar">×</button>'+
            '</div>'+
            '<div class="vct-drawer-body vct-form-body">'+
              CASE WHEN ISNULL(@ERROR_MESSAGE,'')<>'' THEN
                '<div class="vct-validation-box vct-validation-box-server" data-vct-validation-box style="display:block;">'+
                  '<div class="vct-validation-title">No se pudo guardar</div>'+
                  '<ul><li>'+REPLACE(REPLACE(REPLACE(ISNULL(@ERROR_MESSAGE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</li></ul>'+
                '</div>'
              ELSE
                '<div class="vct-validation-box" data-vct-validation-box style="display:none;"></div>'
              END+
              '<div class="vct-form-grid">'+@FIELDS_HTML+'</div>'+
            '</div>'+
            '<div class="vct-drawer-footer vct-form-footer">'+
              '<button type="button" class="vct-btn vct-btn-secondary" data-vct-command="close-drawer" '+
                      'data-vct-target="'+@FORM_ID+'">'+@CANCEL_LABEL+'</button>'+
              '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next">'+
                '<span data-vct-icon="save"></span><span>'+@SAVE_LABEL+'</span>'+
              '</button>'+
            '</div>'+
          '</div>'+
        '</div>';
    END
    ELSE
    BEGIN
        SET @OUTHTML=
        '<div id="'+@FORM_ID+'" class="vct-card vct-form-shell vct-form-'+LOWER(@FORM_SIZE)+'" '+
             'data-vct-form-scope data-vct-form-size="'+LOWER(@FORM_SIZE)+'">'+
          '<div class="vct-card-header vct-form-header">'+
            '<div class="vct-form-header-accent"></div>'+
            '<div class="vct-form-header-copy">'+
              '<h2 class="vct-card-title">'+@TITLE+'</h2>'+
              CASE WHEN @SUBTITLE<>'' THEN '<p class="vct-card-subtitle">'+@SUBTITLE+'</p>' ELSE '' END+
            '</div>'+
          '</div>'+
          '<div class="vct-card-body vct-form-body">'+
            CASE WHEN ISNULL(@ERROR_MESSAGE,'')<>'' THEN
                '<div class="vct-validation-box vct-validation-box-server" data-vct-validation-box style="display:block;">'+
                  '<div class="vct-validation-title">No se pudo guardar</div>'+
                  '<ul><li>'+REPLACE(REPLACE(REPLACE(ISNULL(@ERROR_MESSAGE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</li></ul>'+
                '</div>'
              ELSE
                '<div class="vct-validation-box" data-vct-validation-box style="display:none;"></div>'
              END+
            '<div class="vct-form-grid">'+@FIELDS_HTML+'</div>'+
          '</div>'+
          '<div class="vct-card-footer vct-form-footer">'+
            '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next">'+
              '<span data-vct-icon="save"></span><span>'+@SAVE_LABEL+'</span>'+
            '</button>'+
          '</div>'+
        '</div>';
    END;
END
