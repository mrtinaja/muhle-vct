    USE [MuhlePROD]
    GO
    /****** Object:  StoredProcedure [dbo].[VCT_MAIN_CLIENTES]
            Migrado al motor de tablas nuevo (vct-datagrid.js / vct-datagrid.css / vct-export.js).
            Sin cambios de logica: permisos, guardado, validaciones, formulario y renderers de
            acciones (VIEW / EDIT / CREATE) quedan IGUAL. Solo cambia el markup de la grilla. ******/
    SET ANSI_NULLS ON
    GO
    SET QUOTED_IDENTIFIER ON
    GO
    
    ALTER   PROCEDURE [dbo].[VCT_MAIN_CLIENTES]
    (
        @IPKEYJOB    VARCHAR(100),
        @FORM_ID     VARCHAR(100),
        @IUNIDAD     VARCHAR(100),
        @IAGENTE     VARCHAR(100),
        @OUTPARAM1   VARCHAR(MAX) OUTPUT,
        @OUTPARAM2   VARCHAR(MAX) OUTPUT,
        @OUTPARAM3   VARCHAR(MAX) OUTPUT
    )
    AS
    BEGIN
        SET NOCOUNT ON;
    
        SET @OUTPARAM1 = '';
        SET @OUTPARAM2 = '';
        SET @OUTPARAM3 = '';
    
        DECLARE @MODULE_CODE VARCHAR(50) = 'CLIENTES';
    
        DECLARE
            @HTML_SHELL          VARCHAR(MAX) = '',
            @HTML                VARCHAR(MAX) = '',
            @HTML_ROWS           VARCHAR(MAX) = '',
            @HTML_ESTADOS        VARCHAR(MAX) = '',
            @HTML_COND_IVA       VARCHAR(MAX) = '',
            @HTML_TOOL_ACTIONS   VARCHAR(MAX) = '',
            @HTML_EDIT_ACTION    VARCHAR(MAX) = '',
            @HTML_MODAL          VARCHAR(MAX) = '',
            @RESULTADO_SHELL     VARCHAR(20)  = '',
            @SIDEBAR_ID          INT = 0,
            @TOTAL               INT = 0,
            @TOTAL_ACTIVOS       INT = 0,
            @TOTAL_PASIVOS       INT = 0,
            @TOTAL_DESAF         INT = 0,
            @VID_CLIENTE          VARCHAR(100) = '',
            @VTEXTO01             VARCHAR(500) = '',
            @VTEXTO02             VARCHAR(100) = '',
            @VTEXTO03             VARCHAR(100) = '',
            @VTEXTO04             VARCHAR(100) = '',
            @VFLAG01              VARCHAR(10)  = '',
            @VFORM_ERROR          VARCHAR(500) = '',
            @VFORM_REOPEN         BIT = 0;
    
        /* ============================================================
           1. SHELL GENERAL DEL FRAMEWORK
           ------------------------------------------------------------
           Devuelve Sidebar + Header común.
           El título y subtítulo pertenecen a esta pantalla y se pasan
           dinámicamente al shell.
           ============================================================ */
        BEGIN TRY
            EXEC dbo.VCT_GET_SHELL
                 @IUNIDAD            = @IUNIDAD,
                 @IAGENTE            = @IAGENTE,
                 @FORM_ID            = @FORM_ID,
                 @TITLE              = 'Clientes',
                 @SUBTITLE           = 'Gestión y consulta de clientes del sistema.',
                 @SEARCH_PLACEHOLDER = '',
                 @SHOW_SEARCH        = 0,
                 @OSHELL             = @HTML_SHELL OUTPUT,
                 @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
        END TRY
        BEGIN CATCH
            SET @HTML_SHELL = '';
            SET @RESULTADO_SHELL = 'ERROR';
        END CATCH;
    
        /* ============================================================
           2. ACCIONES HABILITADAS
           Centralizado. El SP no conoce ActionID específicos.
           ============================================================ */
        IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;
    
        SELECT *
        INTO #ACCIONES
        FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);
    
        SELECT TOP 1 @SIDEBAR_ID = ISNULL(SIDEBAR_ID,0)
        FROM #ACCIONES
        WHERE ISNULL(SIDEBAR_ID,0) <> 0
        ORDER BY SORT_ORDER,ID_PRM;
    
        IF NOT EXISTS (SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE = 'VIEW')
        BEGIN
            SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + '
    <div class="vct-page vct-page-main"
         data-vct-page
         data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
         data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
        <section class="vct-card">
            <div class="vct-card-body">
                <h2 class="vct-card-title">Acceso restringido</h2>
                <p class="vct-card-subtitle">No posee permisos para visualizar Clientes.</p>
            </div>
        </section>
    </div>';
            RETURN;
        END;
    
        /* ============================================================
           3. EDICION INLINE / POSTBACK
           No usa ACTION. FLAG01 identifica el guardado del modal.
           ============================================================ */
        SELECT
            @VID_CLIENTE=ISNULL(CONVERT(VARCHAR(100),IDSELEC01),''),
            @VTEXTO01=ISNULL(CONVERT(VARCHAR(500),TEXTO01),''),
            @VTEXTO02=ISNULL(CONVERT(VARCHAR(100),TEXTO02),''),
            @VTEXTO03=ISNULL(CONVERT(VARCHAR(100),TEXTO03),''),
            @VTEXTO04=ISNULL(CONVERT(VARCHAR(100),TEXTO04),''),
            @VFLAG01=ISNULL(CONVERT(VARCHAR(10),FLAG01),'')
        FROM dbo.VCT_BUFFER WITH (NOLOCK)
        WHERE PAR_KEY=@IPKEYJOB;
    
        IF @VFLAG01='1'
        BEGIN
            /* ========================================================
               VALIDACIONES DE NEGOCIO / CORE
               --------------------------------------------------------
               Acá van las reglas que necesitan base de datos.
               Si falla una regla:
                 - NO se hace UPDATE
                 - el mismo VCT_MAIN_CLIENTES vuelve a renderizar
                 - el renderer reabre el modal
                 - conserva exactamente los values enviados
                 - muestra @VFORM_ERROR dentro del modal.
               ======================================================== */
    
            SET @VFORM_ERROR='';
    
            /* ID vacío = ALTA / ID informado = EDICIÓN */
            IF NULLIF(LTRIM(RTRIM(@VTEXTO01)),'') IS NULL
                SET @VFORM_ERROR='La Razón Social es obligatoria.';
    
            IF @VFORM_ERROR='' AND NULLIF(LTRIM(RTRIM(@VTEXTO02)),'') IS NULL
                SET @VFORM_ERROR='El CUIT es obligatorio.';
    
            IF @VFORM_ERROR=''
               AND NULLIF(LTRIM(RTRIM(@VID_CLIENTE)),'') IS NOT NULL
               AND NOT EXISTS
            (
                SELECT 1
                FROM dbo.VCT_CLIENTES WITH(NOLOCK)
                WHERE CONVERT(VARCHAR(100),ID)=@VID_CLIENTE
            )
                SET @VFORM_ERROR='El cliente seleccionado no existe.';
    
            IF @VFORM_ERROR='' AND NOT EXISTS
            (
                SELECT 1
                FROM dbo.CAT_DATA CD WITH(NOLOCK)
                WHERE CD.PAR_KEY=
                (
                    SELECT TOP 1 PKEY
                    FROM dbo.CAT_TYPE WITH(NOLOCK)
                    WHERE CAT_TYPE_CODE='TIPO_CLIENTE'
                )
                AND CD.CAT_DATA_CODE COLLATE DATABASE_DEFAULT=
                    @VTEXTO03 COLLATE DATABASE_DEFAULT
            )
                SET @VFORM_ERROR='El Estado seleccionado no es válido.';
    
            IF @VFORM_ERROR='' AND NOT EXISTS
            (
                SELECT 1
                FROM dbo.CAT_DATA CD WITH(NOLOCK)
                WHERE CD.PAR_KEY=
                (
                    SELECT TOP 1 PKEY
                    FROM dbo.CAT_TYPE WITH(NOLOCK)
                    WHERE CAT_TYPE_CODE='CondicionIva'
                )
                AND CD.CAT_DATA_CODE COLLATE DATABASE_DEFAULT=
                    @VTEXTO04 COLLATE DATABASE_DEFAULT
            )
                SET @VFORM_ERROR='La Condición IVA seleccionada no es válida.';
    
            /* CUIT único: excluye el cliente que se está editando. */
            IF @VFORM_ERROR='' AND EXISTS
            (
                SELECT 1
                FROM dbo.VCT_CLIENTES C WITH(NOLOCK)
                WHERE LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(100),C.CUIT),'')))
                        COLLATE DATABASE_DEFAULT =
                      LTRIM(RTRIM(@VTEXTO02)) COLLATE DATABASE_DEFAULT
                  AND CONVERT(VARCHAR(100),C.ID)<>@VID_CLIENTE
            )
                SET @VFORM_ERROR='Ya existe otro cliente con el CUIT ingresado.';
    
            /* Razón Social única: excluye el cliente que se está editando. */
            IF @VFORM_ERROR='' AND EXISTS
            (
                SELECT 1
                FROM dbo.VCT_CLIENTES C WITH(NOLOCK)
                WHERE UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(500),C.RAZON_SOCIAL),''))))
                        COLLATE DATABASE_DEFAULT =
                      UPPER(LTRIM(RTRIM(@VTEXTO01))) COLLATE DATABASE_DEFAULT
                  AND CONVERT(VARCHAR(100),C.ID)<>@VID_CLIENTE
            )
                SET @VFORM_ERROR='Ya existe otro cliente con la Razón Social ingresada.';
    
            IF @VFORM_ERROR=''
            BEGIN
                IF NULLIF(LTRIM(RTRIM(@VID_CLIENTE)),'') IS NULL
                BEGIN
                    /* ALTA:
                       Se asume ID identity/autonumérico.
                       Si la tabla no posee IDENTITY se devuelve un mensaje claro. */
                    IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_CLIENTES'),'ID','IsIdentity')=1
                    BEGIN
                        INSERT INTO dbo.VCT_CLIENTES
                        (
                            RAZON_SOCIAL,
                            CUIT,
                            TIPO,
                            CONDICION_IVA
                        )
                        VALUES
                        (
                            LTRIM(RTRIM(@VTEXTO01)),
                            LTRIM(RTRIM(@VTEXTO02)),
                            @VTEXTO03,
                            @VTEXTO04
                        );
                    END
                    ELSE
                    BEGIN
                        SET @VFORM_ERROR='No se pudo crear el cliente: la columna ID no es autonumérica y falta definir su generación.';
                    END;
                END
                ELSE
                BEGIN
                    /* EDICIÓN */
                    UPDATE dbo.VCT_CLIENTES
                    SET RAZON_SOCIAL=LTRIM(RTRIM(@VTEXTO01)),
                        CUIT=LTRIM(RTRIM(@VTEXTO02)),
                        TIPO=@VTEXTO03,
                        CONDICION_IVA=@VTEXTO04
                    WHERE CONVERT(VARCHAR(100),ID)=@VID_CLIENTE;
                END;
    
                SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR='' THEN 0 ELSE 1 END;
            END
            ELSE
            BEGIN
                /* Error de negocio:
                   el renderer recibirá los values actuales como DEFAULT_VALUE
                   y volverá a abrir el mismo modal. */
                SET @VFORM_REOPEN=1;
            END;
    
            /* La marca se consume siempre.
               Si el usuario vuelve a presionar Guardar, el hidden FLAG01=1
               vuelve a viajar al buffer. ACTION permanece intacto. */
            UPDATE dbo.VCT_BUFFER
            SET FLAG01=0
            WHERE PAR_KEY=@IPKEYJOB;
        END;
    
        /* ============================================================
           4. ACCIONES DE FORMULARIO - GENERICAS
           ------------------------------------------------------------
           El módulo define textos/iconos/permisos.
           VCT_MAIN_RENDER_FORM_ACTION solamente genera el botón declarativo.
           JS no conoce CLIENTES.
           ============================================================ */
        SET @HTML_TOOL_ACTIONS='';
        SET @HTML_EDIT_ACTION='';
    
        /* ------------------------------------------------------------
           CREATE / NUEVO
           La existencia de ACTION_TYPE='CREATE' sigue determinando permiso.
           El icono del botón/header puede salir de PrmActions.
           ------------------------------------------------------------ */
        IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='CREATE')
        BEGIN
            DECLARE
                @CREATE_ICON  VARCHAR(50)='user-plus',
                @CREATE_TITLE VARCHAR(200)='Nuevo cliente';
    
            SELECT TOP 1
                @CREATE_ICON=ISNULL(NULLIF(ICON,''),'user-plus')
            FROM #ACCIONES
            WHERE ACTION_TYPE='CREATE'
            ORDER BY SORT_ORDER,ID_PRM;
    
            EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
                 @MODE            = 'CREATE',
                 @TARGET_FORM     = 'vctClienteEditModal',
                 @FORM_TITLE      = @CREATE_TITLE,
                 @FORM_SUBTITLE   = 'Complete los datos generales del cliente.',
                 @FORM_ICON       = @CREATE_ICON,
                 @BUTTON_TEXT     = 'Nuevo',
                 @BUTTON_ICON     = @CREATE_ICON,
                 @BUTTON_CLASS    = 'vct-btn vct-btn-new vct-btn-sm',
                 @TOOLTIP         = 'Nuevo cliente',
                 @OUTHTML         = @HTML_TOOL_ACTIONS OUTPUT;
        END;
    
        /* ------------------------------------------------------------
           EDIT
           Se genera UNA sola vez y luego se reutiliza en todas las filas.
           Los values se obtienen de data-vct-* del <tr> seleccionado.
           ------------------------------------------------------------ */
        IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT')
        BEGIN
            DECLARE @EDIT_ICON VARCHAR(50)='edit';
    
            SELECT TOP 1
                @EDIT_ICON=ISNULL(NULLIF(ICON,''),'edit')
            FROM #ACCIONES
            WHERE ACTION_TYPE='EDIT'
            ORDER BY SORT_ORDER,ID_PRM;
    
            EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
                 @MODE            = 'EDIT',
                 @TARGET_FORM     = 'vctClienteEditModal',
                 @FORM_TITLE      = 'Editar cliente',
                 @FORM_SUBTITLE   = 'Modificación de datos generales del cliente.',
                 @FORM_ICON       = @EDIT_ICON,
                 @BUTTON_TEXT     = '',
                 @BUTTON_ICON     = @EDIT_ICON,
                 @BUTTON_CLASS    = 'vct-grid-icon-btn vct-grid-icon-btn-edit',
                 @TOOLTIP         = 'Editar cliente',
                 @SOURCE_SELECTOR = '[data-vct-row]',
                 @OUTHTML         = @HTML_EDIT_ACTION OUTPUT;
        END;
    
        /* ============================================================
           4. DATASET
           ESTRUCTURA REAL DE dbo.VCT_CLIENTES:
             ID
             RAZON_SOCIAL
             CUIT
             CONDICION_IVA
             TIPO        -> ACTIVO / PASIVO / DESAFECTADO
             ESTADO      -> estado técnico 1/0 (NO se usa para badge)
           ============================================================ */
        IF OBJECT_ID('tempdb..#CLIENTES') IS NOT NULL DROP TABLE #CLIENTES;
    
        SELECT
            ID_CLIENTE    = CONVERT(VARCHAR(100),C.ID),
            RAZON_SOCIAL  = ISNULL(CONVERT(VARCHAR(500),C.RAZON_SOCIAL),''),
            CUIT          = ISNULL(CONVERT(VARCHAR(100),C.CUIT),''),
            TIPO_CODE     = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(100),C.TIPO),'')))),
            TIPO_DESC     = ISNULL(NULLIF(TC.CAT_DATA_DESC,''),CONVERT(VARCHAR(200),C.TIPO)),
            COND_IVA_CODE = ISNULL(CONVERT(VARCHAR(100),C.CONDICION_IVA),''),
            COND_IVA_DESC = ISNULL(NULLIF(IVA.CAT_DATA_DESC,''),CONVERT(VARCHAR(200),C.CONDICION_IVA))
        INTO #CLIENTES
        FROM dbo.VCT_CLIENTES C WITH (NOLOCK)
        LEFT JOIN dbo.CAT_DATA TC WITH (NOLOCK)
            ON TC.PAR_KEY = (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH (NOLOCK)
                WHERE CAT_TYPE_CODE = 'TIPO_CLIENTE'
            )
           AND TC.CAT_DATA_CODE COLLATE DATABASE_DEFAULT =
               CONVERT(VARCHAR(100),C.TIPO) COLLATE DATABASE_DEFAULT
        LEFT JOIN dbo.CAT_DATA IVA WITH (NOLOCK)
            ON IVA.PAR_KEY = (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH (NOLOCK)
                WHERE CAT_TYPE_CODE = 'CondicionIva'
            )
           AND IVA.CAT_DATA_CODE COLLATE DATABASE_DEFAULT =
               CONVERT(VARCHAR(100),C.CONDICION_IVA) COLLATE DATABASE_DEFAULT;
    
        /* ============================================================
           5. INDICADORES - SOBRE C.TIPO
           ============================================================ */
        SELECT @TOTAL = COUNT(*) FROM #CLIENTES;
        SELECT @TOTAL_ACTIVOS = COUNT(*) FROM #CLIENTES WHERE TIPO_CODE = 'ACTIVO';
        SELECT @TOTAL_PASIVOS = COUNT(*) FROM #CLIENTES WHERE TIPO_CODE = 'PASIVO';
        SELECT @TOTAL_DESAF = COUNT(*) FROM #CLIENTES WHERE TIPO_CODE = 'DESAFECTADO';
    
        /* ============================================================
           6. FILTRO ESTADO/TIPO DESDE PARAMETRIA
           ============================================================ */
        SELECT @HTML_ESTADOS = ISNULL((
            SELECT
                '<option value="' +
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') +
                '">' +
                REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                '</option>'
            FROM dbo.CAT_DATA CD WITH (NOLOCK)
            WHERE CD.PAR_KEY = (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH (NOLOCK)
                WHERE CAT_TYPE_CODE = 'TIPO_CLIENTE'
            )
            ORDER BY CD.CAT_DATA_DESC
            FOR XML PATH(''),TYPE
        ).value('.','varchar(max)'),'');
    
        /* ============================================================
           7. FILTRO CONDICION IVA DESDE PARAMETRIA
           ============================================================ */
        SELECT @HTML_COND_IVA = ISNULL((
            SELECT
                '<option value="' +
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') +
                '">' +
                REPLACE(REPLACE(REPLACE(ISNULL(CD.CAT_DATA_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                '</option>'
            FROM dbo.CAT_DATA CD WITH (NOLOCK)
            WHERE CD.PAR_KEY = (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH (NOLOCK)
                WHERE CAT_TYPE_CODE = 'CondicionIva'
            )
            ORDER BY CD.CAT_DATA_DESC
            FOR XML PATH(''),TYPE
        ).value('.','varchar(max)'),'');
    
        /* ============================================================
           8. FILAS
           La ubicación de VIEW/EDIT se decide ACA.
           No se hardcodea ningún ActionID.
           El <tr data-vct-row> conserva TODOS sus data-vct-*: el boton Editar
           (SOURCE_SELECTOR='[data-vct-row]') los lee de la fila al abrir el formulario,
           y el motor de tabla usa data-vct-search / data-vct-filter-* para buscar y filtrar.
           ============================================================ */
        SELECT @HTML_ROWS = ISNULL((
            SELECT
                '<tr data-vct-row ' +
                    'data-vct-key="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.ID_CLIENTE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-search="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                            ISNULL(C.RAZON_SOCIAL,'') + ' ' +
                            ISNULL(C.CUIT,'') + ' ' +
                            ISNULL(C.TIPO_DESC,'') + ' ' +
                            ISNULL(C.COND_IVA_DESC,''),
                            '&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-filter-estado="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.TIPO_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-filter-condicion-iva="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.COND_IVA_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-id="' + ISNULL(C.ID_CLIENTE,'') + '" ' +
                    'data-vct-razon-social="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-cuit="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.CUIT,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
                    'data-vct-tipo="' + ISNULL(C.TIPO_CODE,'') + '" ' +
                    'data-vct-condicion-iva="' + ISNULL(C.COND_IVA_CODE,'') + '">' +
    
                    /* V360 - PRIMERA COLUMNA */
                    '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                        ISNULL((
                            SELECT TOP 1 dbo.VCT_MAIN_RENDER_ACTION
                            (
                                A.ACTION_ID,A.TITLE,A.ICON,A.STORAGE_KEY,
                                A.TARGET_TAB,A.TARGET_GUID,C.ID_CLIENTE,
                                'vct-grid-icon-btn vct-grid-icon-btn-view',''
                            )
                            FROM #ACCIONES A
                            WHERE A.ACTION_TYPE = 'VIEW'
                            ORDER BY A.SORT_ORDER,A.ID_PRM
                        ),'') +
                    '</td>' +
    
                    '<td data-label="Razón Social" data-vct-sort-value="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
                        REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                    '</td>' +
    
                    '<td class="vct-text-center" data-label="CUIT" data-vct-sort-value="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.CUIT,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
                        REPLACE(REPLACE(REPLACE(ISNULL(C.CUIT,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                    '</td>' +
    
                    '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.TIPO_DESC,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
                        '<span class="vct-badge" data-vct-badge="' +
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.TIPO_CODE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
                            REPLACE(REPLACE(REPLACE(ISNULL(C.TIPO_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                        '</span>' +
                    '</td>' +
    
                    '<td class="vct-text-center" data-label="Condición IVA" data-vct-sort-value="' +
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.COND_IVA_DESC,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
                        REPLACE(REPLACE(REPLACE(ISNULL(C.COND_IVA_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                    '</td>' +
    
                    /* EDITAR - ULTIMA COLUMNA */
                    '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                        ISNULL(@HTML_EDIT_ACTION,'') +
                    '</td>' +
    
                '</tr>'
            FROM #CLIENTES C
            ORDER BY C.RAZON_SOCIAL,C.ID_CLIENTE
            FOR XML PATH(''),TYPE
        ).value('.','varchar(max)'),'');
    
        /* ============================================================
           9. FORMULARIO DINAMICO DE EDICION
           ------------------------------------------------------------
           IMPORTANTE:
           Desde acá VCT_MAIN_CLIENTES NO arma HTML de campos.
           Solamente declara qué campos necesita y llama al renderer
           genérico dbo.VCT_MAIN_RENDER_FORM.
    
           PARA AGREGAR UN CAMPO:
           agregar UN INSERT a #VCT_FORM_FIELDS.
    
           COLUMNAS DE #VCT_FORM_FIELDS:
           -------------------------------------------------------------------------
           1) ORDEN
              Orden visual del campo.
    
           2) FIELD_NAME
              Campo del VCT_BUFFER.
              Ej: TEXTO01 genera automáticamente name="SP.TEXTO01".
    
           3) LABEL
              Etiqueta visible del campo.
    
           4) FIELD_TYPE
              TEXT / EMAIL / NUMBER / DECIMAL / DATE / TEXTAREA /
              SELECT / TOGGLE / HIDDEN.
    
           5) COL_SPAN
              Ancho lógico desktop sobre 12 columnas:
              12=100%, 6=50%, 4=33%, 3=25%.
              Mobile lo resuelve el CSS genérico.
    
           6) REQUIRED
              1=obligatorio, 0=opcional.
              El JS genérico lo valida antes de ejecutar next().
    
           7) MAX_LENGTH
              Máximo de caracteres. NULL si no aplica.
    
           8) PLACEHOLDER
              Texto dentro del control. NULL si no se necesita.
    
           9) OPTIONS_SOURCE
              SOLO para FIELD_TYPE='SELECT'.
              Se informa CAT_TYPE.CAT_TYPE_CODE.
              VCT_MAIN_RENDER_FORM obtiene automáticamente:
                  CAT_DATA_CODE -> value del <option>
                  CAT_DATA_DESC -> texto visible.
              Ejemplo:
                  'TIPO_CLIENTE'
                  'CondicionIva'
    
           10) DEFAULT_VALUE
               Valor inicial. Útil para altas o campos ocultos.
    
           11) READONLY
               1=solo lectura, 0=editable.
    
           12) HIDDEN
               1=oculto, 0=visible.
    
           13) HELP_TEXT
               Ayuda opcional debajo del campo.
    
           14) SOURCE_FIELD
               Nombre del data-vct-* que se toma de la fila al editar.
               Ej: 'razon-social' lee data-vct-razon-social.
           ============================================================ */
        IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    
        CREATE TABLE #VCT_FORM_FIELDS
        (
            ORDEN          INT,
            FIELD_NAME     VARCHAR(50),
            LABEL          VARCHAR(150),
            FIELD_TYPE     VARCHAR(20),
            COL_SPAN       INT,
            REQUIRED       BIT,
            MAX_LENGTH     INT,
            PLACEHOLDER    VARCHAR(250),
            OPTIONS_SOURCE VARCHAR(100),
            DEFAULT_VALUE  VARCHAR(MAX),
            READONLY       BIT,
            HIDDEN         BIT,
            HELP_TEXT      VARCHAR(500),
            SOURCE_FIELD   VARCHAR(100)
        );
    
        /* Razón Social:
           TEXTO01 -> name="SP.TEXTO01"
           TEXT    -> input de texto
           12      -> ancho completo
           1       -> obligatorio
           500     -> máximo 500 caracteres
           SOURCE_FIELD='razon-social' -> toma data-vct-razon-social de la fila */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO01','Razón Social','TEXT',12,1,500,'Ingrese razón social',NULL,
           CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO01 ELSE NULL END,
           0,0,NULL,'razon-social');
    
        /* CUIT:
           TEXTO02 -> name="SP.TEXTO02"
           TEXT    -> input de texto
           6       -> media fila desktop
           1       -> obligatorio */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (2,'TEXTO02','CUIT','TEXT',6,1,100,'Ingrese CUIT',NULL,
           CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO02 ELSE NULL END,
           0,0,NULL,'cuit');
    
        /* -------------------------------------------------------------------------
           EJEMPLO DE COMBO DINAMICO: ESTADO
    
           FIELD_TYPE    = 'SELECT'
           OPTIONS_SOURCE= 'TIPO_CLIENTE'
    
           No se arma HTML de opciones acá.
           VCT_MAIN_RENDER_FORM busca:
    
               CAT_TYPE.CAT_TYPE_CODE = 'TIPO_CLIENTE'
                             |
                             +--> CAT_DATA.CAT_DATA_CODE = value
                             +--> CAT_DATA.CAT_DATA_DESC = texto visible
    
           TEXTO03 genera name="SP.TEXTO03".
           SOURCE_FIELD='tipo' carga el valor actual desde data-vct-tipo.
           ------------------------------------------------------------------------- */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (3,'TEXTO03','Estado','SELECT',6,1,NULL,NULL,'TIPO_CLIENTE',
           CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO03 ELSE NULL END,
           0,0,NULL,'tipo');
    
        /* Otro combo dinámico.
           OPTIONS_SOURCE='CondicionIva' usa exactamente el mismo mecanismo. */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (4,'TEXTO04','Condición IVA','SELECT',12,1,NULL,NULL,'CondicionIva',
           CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO04 ELSE NULL END,
           0,0,NULL,'condicion-iva');
    
        /* ID del registro editado. Oculto.
           IDSELEC01 genera name="SP.IDSELEC01".
           SOURCE_FIELD='id' toma data-vct-id de la fila. */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,
           CASE WHEN @VFORM_REOPEN=1 THEN @VID_CLIENTE ELSE NULL END,
           0,1,NULL,'id');
    
        /* Marca de postback del guardado.
           FLAG01=1 permite que ESTE MISMO VCT_MAIN_CLIENTES detecte el guardado.
           NO se utiliza ni modifica ACTION. */
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (6,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    
        /* ============================================================
           LLAMADO AL RENDERER GENERICO
           ------------------------------------------------------------
           @FORM_ID
               Id DOM único del formulario generado.
               Debe coincidir con data-vct-target del botón que lo abre.
    
           @TITLE
               Título visible del formulario.
    
           @SUBTITLE
               Texto secundario opcional debajo del título.
    
           @LAYOUT
               Define SOLAMENTE cómo se presenta el mismo formulario:
    
               'MODAL'
                   Ventana centrada sobre la pantalla actual.
                   Recomendado para formularios cortos/medios.
    
               'DRAWER'
                   Panel lateral.
                   Útil cuando hay más campos o se quiere conservar
                   visible el contexto de la pantalla original.
    
               'PAGE'
                   Formulario integrado directamente dentro de la página.
                   Útil para formularios grandes o procesos principales.
    
               IMPORTANTE:
               Para pasar de MODAL a DRAWER o PAGE NO se cambian los INSERT.
               Sólo se cambia este parámetro.
    
           @SAVE_LABEL
               Texto del botón principal.
    
           @CANCEL_LABEL
               Texto del botón cancelar/cerrar.
    
           @OUTHTML
               Variable VARCHAR(MAX) donde el renderer devuelve todo el HTML.
           ============================================================ */
        EXEC dbo.VCT_MAIN_RENDER_FORM
             @FORM_ID      = 'vctClienteEditModal',
             @TITLE        = 'Editar cliente',
             @SUBTITLE     = 'Modificación de datos generales del cliente.',
             @ICON         = 'edit',   -- Icono del header. '' = sin icono
             @LAYOUT       = 'MODAL',  -- OPCIONES: 'MODAL' / 'DRAWER' / 'PAGE'
             @SAVE_LABEL    = 'Guardar',
             @CANCEL_LABEL  = 'Cancelar',
             @ERROR_MESSAGE = @VFORM_ERROR,  -- mensaje de validación de negocio
             @OPEN_ON_RENDER= @VFORM_REOPEN, -- 1=reabre modal conservando values
             @OUTHTML      = @HTML_MODAL OUTPUT;
    
        /* ============================================================
           10. HTML
           ------------------------------------------------------------
           Grilla con el motor nuevo (data-vct-dg): el motor arma buscador,
           Excel/PDF, paginado, orden y "registros por pagina". El SP solo
           declara: filtros (slot filters), boton Nuevo (slot actions) y la tabla.
           ============================================================ */
        SET @HTML = '
    <link rel="stylesheet" href="../css/vct-datagrid.css?v=4">
    <div class="vct-page vct-page-main"
         data-vct-page
         data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
         data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
    
        <section class="vct-soft-kpi-grid" aria-label="Indicadores de clientes">
            <article class="vct-soft-kpi is-purple">
                <span class="vct-soft-kpi-icon" data-vct-icon="users"></span>
                <div class="vct-soft-kpi-copy">
                    <span class="vct-soft-kpi-label">Total Clientes</span>
                    <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL) + '</strong>
                    <span class="vct-soft-kpi-help">clientes registrados</span>
                </div>
            </article>
    
            <article class="vct-soft-kpi is-green">
                <span class="vct-soft-kpi-icon" data-vct-icon="user-check"></span>
                <div class="vct-soft-kpi-copy">
                    <span class="vct-soft-kpi-label">Activos</span>
                    <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_ACTIVOS) + '</strong>
                    <span class="vct-soft-kpi-help">cartera vigente</span>
                </div>
            </article>
    
            <article class="vct-soft-kpi is-blue">
                <span class="vct-soft-kpi-icon" data-vct-icon="user-minus"></span>
                <div class="vct-soft-kpi-copy">
                    <span class="vct-soft-kpi-label">Pasivos</span>
                    <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_PASIVOS) + '</strong>
                    <span class="vct-soft-kpi-help">clientes pasivos</span>
                </div>
            </article>
    
            <article class="vct-soft-kpi is-red">
                <span class="vct-soft-kpi-icon" data-vct-icon="user-x"></span>
                <div class="vct-soft-kpi-copy">
                    <span class="vct-soft-kpi-label">Desafectados</span>
                    <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_DESAF) + '</strong>
                    <span class="vct-soft-kpi-help">fuera de cartera</span>
                </div>
            </article>
        </section>
    
        <section class="vct-card vct-grid-card">
            <div class="vct-card-body">
                <div data-vct-dg
                     data-vct-dg-id="clientes"
                     data-vct-dg-title="Clientes"
                     data-vct-dg-subtitle="Gestión y consulta de clientes del sistema."
                     data-vct-dg-unit="cliente(s)"
                     data-vct-dg-page-size="10"
                     data-vct-dg-search-placeholder="Buscar por razón social, CUIT..."
                     data-vct-dg-density="compact"
                     data-vct-dg-layout="fixed">
    
                    <div data-vct-dg-slot="filters">
                        <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Estado">
                            <option value="">Todos los estados</option>
                            ' + ISNULL(@HTML_ESTADOS,'') + '
                        </select>
    
                        <select class="vct-select vct-select-sm" data-vct-dg-filter="condicion-iva" aria-label="Condición IVA">
                            <option value="">Todas las condiciones</option>
                            ' + ISNULL(@HTML_COND_IVA,'') + '
                        </select>
                    </div>
    
                    <div data-vct-dg-slot="actions">' + ISNULL(@HTML_TOOL_ACTIONS,'') + '</div>
    
                    <table>
                        <thead>
                            <tr>
                                <th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>
    
                                <th data-vct-sort="razon-social" data-vct-sortable="true">
                                    <span>Razón Social</span>
                                    <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                                </th>
    
                                <th class="vct-text-center" data-vct-width="16%" data-vct-sort="cuit" data-vct-sortable="true">
                                    <span>CUIT</span>
                                    <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                                </th>
    
                                <th class="vct-text-center" data-vct-width="16%" data-vct-sort="estado" data-vct-sortable="true">
                                    <span>Estado</span>
                                    <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                                </th>
    
                                <th class="vct-text-center" data-vct-width="22%" data-vct-sort="condicion-iva" data-vct-sortable="true">
                                    <span>Condición IVA</span>
                                    <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                                </th>
    
                                <th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>
                            </tr>
                        </thead>
    
                        <tbody>' + ISNULL(@HTML_ROWS,'') + '</tbody>
                    </table>
                </div>
            </div>
        </section>
    
        <input type="hidden" name="SP.PAGE_NUMBER" id="PAGE_NUMBER"  value="1">
        <input type="hidden" name="SP.PAGE_SIZE"   id="PAGE_SIZE"    value="10">
        <input type="hidden" name="SP.SEARCH_TEXT" id="SEARCH_TEXT"  value="">
        <input type="hidden" name="SP.SORT_FIELD"  id="SORT_FIELD"   value="">
        <input type="hidden" name="SP.SORT_DIR"    id="SORT_DIR"     value="">
    </div>
    <script src="../js/vct-export.js?v=1"></script>
    <script src="../js/vct-datagrid.js?v=3"></script>';
    
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + ISNULL(@HTML,'');
        SET @OUTPARAM2 = ISNULL(@HTML_MODAL,'');
        SET @OUTPARAM3 = '';
    END
    GO
