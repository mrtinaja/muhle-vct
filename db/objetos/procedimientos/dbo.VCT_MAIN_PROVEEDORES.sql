 
CREATE PROCEDURE [dbo].[VCT_MAIN_PROVEEDORES]
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
 
    DECLARE @MODULE_CODE VARCHAR(50) = 'PROVEEDORES';
 
    DECLARE
        @HTML_SHELL           VARCHAR(MAX) = '',
        @HTML                 VARCHAR(MAX) = '',
        @HTML_ROWS            VARCHAR(MAX) = '',
        @HTML_TIPOS           VARCHAR(MAX) = '',
        @HTML_CONDICIONES_IVA VARCHAR(MAX) = '',
        @HTML_TOOL_ACTIONS    VARCHAR(MAX) = '',
        @HTML_EDIT_ACTION     VARCHAR(MAX) = '',
        @HTML_MODAL           VARCHAR(MAX) = '',
        @RESULTADO_SHELL      VARCHAR(20)  = '',
        @SIDEBAR_ID           INT = 0,
        @TOTAL                INT = 0,
        @TOTAL_ACTIVOS        INT = 0,
        @TOTAL_INACTIVOS      INT = 0,
        @TOTAL_CON_CUIT       INT = 0,
        @VID_PROVEEDOR        VARCHAR(100) = '',
        @VTEXTO01             VARCHAR(500) = '',
        @VTEXTO02             VARCHAR(500) = '',
        @VTEXTO03             VARCHAR(100) = '',
        @VTEXTO04             VARCHAR(100) = '',
        @VTEXTO05             VARCHAR(100) = '',
        @VTEXTO06             VARCHAR(50)  = '',
        @VTEXTO07             VARCHAR(1200)= '',
        @VFLAG01              VARCHAR(10)  = '',
        @VFORM_ERROR          VARCHAR(1000) = '',
        @VFORM_REOPEN         BIT = 0;
 
    /* 1. SHELL GENERAL: Sidebar + Header */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Proveedores',
             @SUBTITLE           = 'Gestión y consulta de proveedores.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
        SET @RESULTADO_SHELL = 'ERROR';
    END CATCH;
 
    /* 2. ACCIONES: módulo PROVEEDORES, sin ActionID ni SidebarID hardcodeados */
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
            <p class="vct-card-subtitle">No posee permisos para visualizar Proveedores.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;
 
    /* 3. CATÁLOGO TIPO DE PROVEEDOR */
    IF OBJECT_ID('tempdb..#TIPOS_PROVEEDOR') IS NOT NULL DROP TABLE #TIPOS_PROVEEDOR;
 
    SELECT DISTINCT
        CODIGO      = ISNULL(CONVERT(VARCHAR(50),D.CAT_DATA_CODE),''),
        DESCRIPCION = ISNULL(CONVERT(VARCHAR(300),D.CAT_DATA_DESC),'')
    INTO #TIPOS_PROVEEDOR
    FROM dbo.CAT_DATA D WITH(NOLOCK)
    INNER JOIN dbo.CAT_TYPE T WITH(NOLOCK)
        ON T.PKEY = D.PAR_KEY
    WHERE T.CAT_TYPE_CODE = 'TIPO_PROVEEDOR'
      AND NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),D.CAT_DATA_CODE),''))),'') IS NOT NULL;
 
    SELECT @HTML_TIPOS = ISNULL((
        SELECT
            '<option value="' +
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') +
            '">' +
            REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
            '</option>'
        FROM #TIPOS_PROVEEDOR T
        ORDER BY T.DESCRIPCION,T.CODIGO
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* 4. CATÁLOGO CONDICIÓN IVA */
    IF OBJECT_ID('tempdb..#CONDICIONES_IVA') IS NOT NULL DROP TABLE #CONDICIONES_IVA;
 
    SELECT DISTINCT
        CODIGO      = ISNULL(CONVERT(VARCHAR(50),CD.CAT_DATA_CODE),''),
        DESCRIPCION = ISNULL(CONVERT(VARCHAR(300),CD.CAT_DATA_DESC),'')
    INTO #CONDICIONES_IVA
    FROM dbo.CAT_DATA CD WITH(NOLOCK)
    WHERE CD.PAR_KEY =
    (
        SELECT TOP 1 PKEY
        FROM dbo.CAT_TYPE WITH(NOLOCK)
        WHERE CAT_TYPE_CODE = 'CondicionIva'
    )
      AND NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),CD.CAT_DATA_CODE),''))),'') IS NOT NULL;
 
    SELECT @HTML_CONDICIONES_IVA = ISNULL((
        SELECT
            '<option value="' +
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CI.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') +
            '">' +
            REPLACE(REPLACE(REPLACE(ISNULL(CI.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
            '</option>'
        FROM #CONDICIONES_IVA CI
        ORDER BY CI.DESCRIPCION,CI.CODIGO
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* 5. POSTBACK ALTA / EDICIÓN */
    SELECT TOP 1
        @VID_PROVEEDOR = ISNULL(CONVERT(VARCHAR(100),IDSELEC01),''),
        @VTEXTO01      = ISNULL(CONVERT(VARCHAR(500),TEXTO01),''),
        @VTEXTO02      = ISNULL(CONVERT(VARCHAR(500),TEXTO02),''),
        @VTEXTO03      = ISNULL(CONVERT(VARCHAR(100),TEXTO03),''),
        @VTEXTO04      = ISNULL(CONVERT(VARCHAR(100),TEXTO04),''),
        @VTEXTO05      = ISNULL(CONVERT(VARCHAR(100),TEXTO05),''),
        @VTEXTO06      = ISNULL(CONVERT(VARCHAR(50),TEXTO06),''),
        @VTEXTO07      = ISNULL(CONVERT(VARCHAR(1200),TEXTO07),''),
        @VFLAG01       = ISNULL(CONVERT(VARCHAR(10),FLAG01),'')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    IF @VFLAG01='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF NULLIF(LTRIM(RTRIM(@VTEXTO01)),'') IS NULL
            SET @VFORM_ERROR='La razón social es obligatoria.';
 
        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VID_PROVEEDOR)),'') IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.VCT_PROVEEDORES P WITH(NOLOCK)
               WHERE CONVERT(VARCHAR(100),P.ID_PROVEEDOR)=@VID_PROVEEDOR
           )
            SET @VFORM_ERROR='El proveedor seleccionado no existe.';
 
        /* CUIT opcional; si se informa debe ser numérico y tener como máximo 11 dígitos. */
        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO03)),'') IS NOT NULL
           AND
           (
               LEN(LTRIM(RTRIM(@VTEXTO03))) > 11
               OR LTRIM(RTRIM(@VTEXTO03)) LIKE '%[^0-9]%'
           )
            SET @VFORM_ERROR='El CUIT debe ser numérico y no puede superar los 11 dígitos.';
 
        IF @VFORM_ERROR='' AND NULLIF(LTRIM(RTRIM(@VTEXTO04)),'') IS NULL
            SET @VFORM_ERROR='El tipo de proveedor es obligatorio.';
 
        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO04)),'') IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM #TIPOS_PROVEEDOR T
               WHERE UPPER(LTRIM(RTRIM(T.CODIGO))) COLLATE DATABASE_DEFAULT =
                     UPPER(LTRIM(RTRIM(@VTEXTO04))) COLLATE DATABASE_DEFAULT
           )
            SET @VFORM_ERROR='El tipo de proveedor seleccionado no es válido.';
 
        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO05)),'') IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM #CONDICIONES_IVA CI
               WHERE UPPER(LTRIM(RTRIM(CI.CODIGO))) COLLATE DATABASE_DEFAULT =
                     UPPER(LTRIM(RTRIM(@VTEXTO05))) COLLATE DATABASE_DEFAULT
           )
            SET @VFORM_ERROR='La condición IVA seleccionada no es válida.';
 
        IF @VFORM_ERROR=''
           AND UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO06,'')))) NOT IN ('ACTIVO','INACTIVO')
            SET @VFORM_ERROR='El estado seleccionado no es válido.';
 
        IF @VFORM_ERROR=''
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@VID_PROVEEDOR)),'') IS NULL
            BEGIN
                IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROVEEDORES'),'ID_PROVEEDOR','IsIdentity')=1
                BEGIN
                    INSERT INTO dbo.VCT_PROVEEDORES
                    (
                        RAZON_SOCIAL,
                        DESCRIPCION,
                        CUIT,
                        TIPO_PROVEEDOR,
                        CONDICION_IVA,
                        ESTADO,
                        OBSERVACIONES,
                        FECHA_ALTA,
                        USUARIO_ALTA
                    )
                    VALUES
                    (
                        LTRIM(RTRIM(@VTEXTO01)),
                        NULLIF(LTRIM(RTRIM(@VTEXTO02)),''),
                        CASE
                            WHEN NULLIF(LTRIM(RTRIM(@VTEXTO03)),'') IS NULL THEN NULL
                            ELSE CONVERT(NUMERIC(11,0),LTRIM(RTRIM(@VTEXTO03)))
                        END,
                        LTRIM(RTRIM(@VTEXTO04)),
                        NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                        UPPER(LTRIM(RTRIM(@VTEXTO06))),
                        NULLIF(LTRIM(RTRIM(@VTEXTO07)),''),
                        GETDATE(),
                        @IAGENTE
                    );
                END
                ELSE
                    SET @VFORM_ERROR='No se pudo crear el proveedor: la columna ID_PROVEEDOR no es autonumérica.';
            END
            ELSE
            BEGIN
                UPDATE dbo.VCT_PROVEEDORES
                   SET RAZON_SOCIAL   = LTRIM(RTRIM(@VTEXTO01)),
                       DESCRIPCION    = NULLIF(LTRIM(RTRIM(@VTEXTO02)),''),
                       CUIT           = CASE
                                            WHEN NULLIF(LTRIM(RTRIM(@VTEXTO03)),'') IS NULL THEN NULL
                                            ELSE CONVERT(NUMERIC(11,0),LTRIM(RTRIM(@VTEXTO03)))
                                        END,
                       TIPO_PROVEEDOR = LTRIM(RTRIM(@VTEXTO04)),
                       CONDICION_IVA  = NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                       ESTADO         = UPPER(LTRIM(RTRIM(@VTEXTO06))),
                       OBSERVACIONES  = NULLIF(LTRIM(RTRIM(@VTEXTO07)),''),
                       FECHA_UPD      = GETDATE(),
                       USUARIO_UPD    = @IAGENTE
                 WHERE CONVERT(VARCHAR(100),ID_PROVEEDOR)=@VID_PROVEEDOR;
            END;
 
            SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR='' THEN 0 ELSE 1 END;
        END
        ELSE
            SET @VFORM_REOPEN=1;
 
        UPDATE dbo.VCT_BUFFER
           SET FLAG01=0
         WHERE PAR_KEY=@IPKEYJOB;
    END;
 
    /* 6. ACCIONES DE FORMULARIO */
    SET @HTML_TOOL_ACTIONS='';
    SET @HTML_EDIT_ACTION='';
 
    IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='CREATE')
    BEGIN
        DECLARE @CREATE_ICON VARCHAR(50)='plus';
 
        SELECT TOP 1 @CREATE_ICON=ISNULL(NULLIF(ICON,''),'plus')
        FROM #ACCIONES
        WHERE ACTION_TYPE='CREATE'
        ORDER BY SORT_ORDER,ID_PRM;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctProveedorEditModal',
             @FORM_TITLE='Nuevo proveedor',
             @FORM_SUBTITLE='Complete los datos generales del proveedor.',
             @FORM_ICON=@CREATE_ICON,
             @BUTTON_TEXT='Nuevo',
             @BUTTON_ICON=@CREATE_ICON,
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Nuevo proveedor',
             @OUTHTML=@HTML_TOOL_ACTIONS OUTPUT;
    END;
 
    IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT')
    BEGIN
        DECLARE @EDIT_ICON VARCHAR(50)='edit';
 
        SELECT TOP 1 @EDIT_ICON=ISNULL(NULLIF(ICON,''),'edit')
        FROM #ACCIONES
        WHERE ACTION_TYPE='EDIT'
        ORDER BY SORT_ORDER,ID_PRM;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',
             @TARGET_FORM='vctProveedorEditModal',
             @FORM_TITLE='Editar proveedor',
             @FORM_SUBTITLE='Modificación de datos generales del proveedor.',
             @FORM_ICON=@EDIT_ICON,
             @BUTTON_TEXT='',
             @BUTTON_ICON=@EDIT_ICON,
             @BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',
             @TOOLTIP='Editar proveedor',
             @SOURCE_SELECTOR='[data-vct-row]',
             @OUTHTML=@HTML_EDIT_ACTION OUTPUT;
    END;
 
    /* 7. DATASET */
    IF OBJECT_ID('tempdb..#PROVEEDORES') IS NOT NULL DROP TABLE #PROVEEDORES;
 
    SELECT
        ID_PROVEEDOR       = CONVERT(VARCHAR(100),P.ID_PROVEEDOR),
        RAZON_SOCIAL       = ISNULL(CONVERT(VARCHAR(300),P.RAZON_SOCIAL),''),
        DESCRIPCION        = ISNULL(CONVERT(VARCHAR(300),P.DESCRIPCION),''),
        CUIT               = ISNULL(CONVERT(VARCHAR(20),P.CUIT),''),
        TIPO_CODE          = ISNULL(CONVERT(VARCHAR(50),P.TIPO_PROVEEDOR),''),
        TIPO_DESC          = ISNULL(NULLIF(CONVERT(VARCHAR(300),T.DESCRIPCION),''),ISNULL(CONVERT(VARCHAR(50),P.TIPO_PROVEEDOR),'')),
        CONDICION_IVA      = ISNULL(CONVERT(VARCHAR(50),P.CONDICION_IVA),''),
        CONDICION_IVA_DESC = ISNULL(NULLIF(CONVERT(VARCHAR(300),CI.DESCRIPCION),''),ISNULL(CONVERT(VARCHAR(50),P.CONDICION_IVA),'')),
        ESTADO_CODE        = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),P.ESTADO),'INACTIVO')))),
        ESTADO_DESC        = CASE
                                 WHEN UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),P.ESTADO),''))))='ACTIVO'
                                     THEN 'Activo'
                                 ELSE 'Inactivo'
                              END,
        OBSERVACIONES      = ISNULL(CONVERT(VARCHAR(1000),P.OBSERVACIONES),'')
    INTO #PROVEEDORES
    FROM dbo.VCT_PROVEEDORES P WITH(NOLOCK)
    LEFT JOIN #TIPOS_PROVEEDOR T
        ON T.CODIGO COLLATE DATABASE_DEFAULT =
           ISNULL(CONVERT(VARCHAR(50),P.TIPO_PROVEEDOR),'') COLLATE DATABASE_DEFAULT
    LEFT JOIN #CONDICIONES_IVA CI
        ON CI.CODIGO COLLATE DATABASE_DEFAULT =
           ISNULL(CONVERT(VARCHAR(50),P.CONDICION_IVA),'') COLLATE DATABASE_DEFAULT;
 
    SELECT @TOTAL=COUNT(*) FROM #PROVEEDORES;
    SELECT @TOTAL_ACTIVOS=COUNT(*) FROM #PROVEEDORES WHERE ESTADO_CODE='ACTIVO';
    SELECT @TOTAL_INACTIVOS=COUNT(*) FROM #PROVEEDORES WHERE ESTADO_CODE='INACTIVO';
    SELECT @TOTAL_CON_CUIT=COUNT(*) FROM #PROVEEDORES WHERE NULLIF(LTRIM(RTRIM(CUIT)),'') IS NOT NULL;
 
    /* 8. FILAS */
    SELECT @HTML_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row ' +
            'data-vct-key="' + ISNULL(P.ID_PROVEEDOR,'') + '" ' +
            'data-vct-search="' +
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(P.RAZON_SOCIAL,'') + ' ' +
                    ISNULL(P.DESCRIPCION,'') + ' ' +
                    ISNULL(P.CUIT,'') + ' ' +
                    ISNULL(P.TIPO_CODE,'') + ' ' +
                    ISNULL(P.TIPO_DESC,'') + ' ' +
                    ISNULL(P.CONDICION_IVA,'') + ' ' +
                    ISNULL(P.CONDICION_IVA_DESC,'') + ' ' +
                    ISNULL(P.OBSERVACIONES,''),
                    '&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-filter-estado="' + ISNULL(P.ESTADO_CODE,'') + '" ' +
            'data-vct-filter-tipo="' + REPLACE(REPLACE(ISNULL(P.TIPO_CODE,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-id="' + ISNULL(P.ID_PROVEEDOR,'') + '" ' +
            'data-vct-razon-social="' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.RAZON_SOCIAL,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-descripcion="' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-cuit="' + REPLACE(REPLACE(ISNULL(P.CUIT,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-tipo-proveedor="' + REPLACE(REPLACE(ISNULL(P.TIPO_CODE,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-condicion-iva="' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CONDICION_IVA,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-estado="' + ISNULL(P.ESTADO_CODE,'') + '" ' +
            'data-vct-observaciones="' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.OBSERVACIONES,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '">' +
 
            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL((
                    SELECT TOP 1 dbo.VCT_MAIN_RENDER_ACTION
                    (
                        A.ACTION_ID,A.TITLE,A.ICON,A.STORAGE_KEY,
                        A.TARGET_TAB,A.TARGET_GUID,P.ID_PROVEEDOR,
                        'vct-grid-icon-btn vct-grid-icon-btn-view',''
                    )
                    FROM #ACCIONES A
                    WHERE A.ACTION_TYPE='VIEW'
                    ORDER BY A.SORT_ORDER,A.ID_PRM
                ),'') +
            '</td>' +
 
            '<td data-label="Razón social" data-vct-sort-value="' +
                REPLACE(REPLACE(REPLACE(ISNULL(P.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '">' +
                '<strong>' +
                CASE WHEN P.RAZON_SOCIAL='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(P.RAZON_SOCIAL,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
                '</strong>' +
            '</td>' +
 
            '<td class="vct-text-center" data-label="CUIT">' +
                CASE WHEN P.CUIT='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(P.CUIT,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +
 
            '<td data-label="Tipo">' +
                CASE WHEN P.TIPO_DESC='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(P.TIPO_DESC,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +
 
            '<td data-label="Condición IVA">' +
                CASE WHEN P.CONDICION_IVA_DESC='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(P.CONDICION_IVA_DESC,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +
 
            '<td class="vct-text-center" data-label="Estado">' +
                '<span class="vct-badge" data-vct-badge="' + ISNULL(P.ESTADO_CODE,'') + '">' + ISNULL(P.ESTADO_DESC,'') + '</span>' +
            '</td>' +
 
            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL(@HTML_EDIT_ACTION,'') +
            '</td>' +
            '</tr>'
        FROM #PROVEEDORES P
        ORDER BY P.RAZON_SOCIAL,P.ID_PROVEEDOR
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* 9. FORMULARIO */
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
 
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT,
        FIELD_NAME VARCHAR(50),
        LABEL VARCHAR(150),
        FIELD_TYPE VARCHAR(20),
        COL_SPAN INT,
        REQUIRED BIT,
        MAX_LENGTH INT,
        PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100),
        DEFAULT_VALUE VARCHAR(MAX),
        READONLY BIT,
        HIDDEN BIT,
        HELP_TEXT VARCHAR(500),
        SOURCE_FIELD VARCHAR(100)
    );
 
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Razón social','TEXT',8,1,300,'Ingrese razón social',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'razon-social'),
    (2,'TEXTO03','CUIT','TEXT',4,0,11,'Solo números, hasta 11 dígitos',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO03 ELSE NULL END,0,0,'Opcional. Si se informa, debe ser numérico y tener hasta 11 dígitos.','cuit'),
    (3,'TEXTO02','Descripción','TEXT',12,0,300,'Descripción o nombre comercial',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (4,'TEXTO04','Tipo de proveedor','TEXT',4,1,50,'Seleccione tipo',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO04 ELSE NULL END,0,0,NULL,'tipo-proveedor'),
    (5,'TEXTO05','Condición IVA','TEXT',4,0,50,'Seleccione condición IVA',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO05 ELSE NULL END,0,0,NULL,'condicion-iva'),
    (6,'TEXTO06','Estado','TEXT',4,1,30,'Seleccione estado',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO06 ELSE 'ACTIVO' END,0,0,NULL,'estado'),
    (7,'TEXTO07','Observaciones','TEXTAREA',12,0,1000,'Ingrese observaciones',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO07 ELSE NULL END,0,0,NULL,'observaciones'),
    (8,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VID_PROVEEDOR ELSE NULL END,0,1,NULL,'id'),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctProveedorEditModal',
         @TITLE='Editar proveedor',
         @SUBTITLE='Modificación de datos generales del proveedor.',
         @ICON='truck',
         @LAYOUT='MODAL',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@VFORM_ERROR,
         @OPEN_ON_RENDER=@VFORM_REOPEN,
         @OUTHTML=@HTML_MODAL OUTPUT;
 
    SET @HTML_MODAL = ISNULL(@HTML_MODAL,'') +
        '<template data-vct-field-options data-vct-target="vctProveedorEditModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione tipo">' +
            ISNULL(@HTML_TIPOS,'') +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctProveedorEditModal" data-vct-field="TEXTO05" data-vct-placeholder="Seleccione condición IVA">' +
            ISNULL(@HTML_CONDICIONES_IVA,'') +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctProveedorEditModal" data-vct-field="TEXTO06" data-vct-placeholder="Seleccione estado">' +
            '<option value="ACTIVO">Activo</option>' +
            '<option value="INACTIVO">Inactivo</option>' +
        '</template>';
 
    /* 10. HTML PRINCIPAL: grilla con el motor nuevo (data-vct-dg) */
    SET @HTML = '
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4">
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
 
    <section class="vct-soft-kpi-grid" aria-label="Indicadores de proveedores">
        <article class="vct-soft-kpi is-blue">
            <span class="vct-soft-kpi-icon" data-vct-icon="truck"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Total Proveedores</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL) + '</strong>
                <span class="vct-soft-kpi-help">proveedores registrados</span>
            </div>
        </article>
 
        <article class="vct-soft-kpi is-green">
            <span class="vct-soft-kpi-icon" data-vct-icon="user-check"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Activos</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_ACTIVOS) + '</strong>
                <span class="vct-soft-kpi-help">estado activo</span>
            </div>
        </article>
 
        <article class="vct-soft-kpi is-orange">
            <span class="vct-soft-kpi-icon" data-vct-icon="user-minus"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Inactivos</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_INACTIVOS) + '</strong>
                <span class="vct-soft-kpi-help">estado inactivo</span>
            </div>
        </article>
 
        <article class="vct-soft-kpi is-purple">
            <span class="vct-soft-kpi-icon" data-vct-icon="id-card"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Con CUIT</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_CON_CUIT) + '</strong>
                <span class="vct-soft-kpi-help">proveedores identificados</span>
            </div>
        </article>
    </section>
 
    <section class="vct-card vct-grid-card">
        <div class="vct-card-body">
            <div data-vct-dg
                 data-vct-dg-id="proveedores"
                 data-vct-dg-title="Proveedores"
                 data-vct-dg-subtitle="Gestión y consulta de proveedores."
                 data-vct-dg-unit="proveedor(es)"
                 data-vct-dg-page-size="10"
                 data-vct-dg-search-placeholder="Buscar proveedor, CUIT, tipo, descripción..."
                 data-vct-dg-density="compact"
                 data-vct-dg-layout="fixed">
 
                <div data-vct-dg-slot="filters">
                    <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Estado">
                        <option value="">Todos los estados</option>
                        <option value="ACTIVO">Activo</option>
                        <option value="INACTIVO">Inactivo</option>
                    </select>
 
                    <select class="vct-select vct-select-sm" data-vct-dg-filter="tipo" aria-label="Tipo de proveedor">
                        <option value="">Todos los tipos</option>
                        ' + ISNULL(@HTML_TIPOS,'') + '
                    </select>
                </div>
 
                <div data-vct-dg-slot="actions">' + ISNULL(@HTML_TOOL_ACTIONS,'') + '</div>
 
                <table>
                    <thead>
                        <tr>
                            <th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>
 
                            <th data-vct-sort="razon-social" data-vct-sortable="true">
                                <span>Razón social</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>
 
                            <th class="vct-text-center" data-vct-width="14%" data-vct-sort="cuit" data-vct-sortable="true">
                                <span>CUIT</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>
 
                            <th data-vct-width="20%" data-vct-sort="tipo" data-vct-sortable="true">
                                <span>Tipo</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>
 
                            <th data-vct-width="20%" data-vct-sort="condicion-iva" data-vct-sortable="true">
                                <span>Condición IVA</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>
 
                            <th class="vct-text-center" data-vct-width="11%" data-vct-sort="estado" data-vct-sortable="true">
                                <span>Estado</span>
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
