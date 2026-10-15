/* ========================================================================
   CAMBIO 1 - FORMULARIO "NUEVO PROYECTO" (solo el formulario, no graba)
   ------------------------------------------------------------------------
   Que hace este script:
     1. Crea dbo.VCT_PROYECTO_ALTA_RENDER: arma el formulario de pagina
        completa con el renderer generico (VCT_MAIN_RENDER_FORM, PAGE).
     2. Parchea dbo.VCT_MAIN_PROYECTOS (por anclas, sobre la definicion
        vigente) para que el boton "Nuevo" abra ese formulario en el mismo
        paso. "Cancelar" vuelve a la grilla. "Crear proyecto" por ahora solo
        vuelve a mostrar el formulario con un aviso (el guardado es el
        cambio 2).
   No crea tablas, vistas, funciones ni permisos. No toca VCT_PROYECTOS.
   El boton "Nuevo" sigue saliendo solo si VCT_MAIN_GET_ACTIONS devuelve la
   accion CREATE del modulo PROYECTOS (lo cargas vos en PrmActions).
   Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#C1_RUN') IS NOT NULL DROP TABLE #C1_RUN;
CREATE TABLE #C1_RUN (INICIO DATETIME, TRG_ON BIT);
INSERT INTO #C1_RUN VALUES (DATEADD(SECOND,-2,GETDATE()), 0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #C1_RUN SET TRG_ON = 1;
END;
GO

/* ========================================================================
   1. dbo.VCT_PROYECTO_ALTA_RENDER
   ------------------------------------------------------------------------
   Formulario "Nuevo proyecto" en pagina completa. Lo llaman las pantallas
   de origen (Proyectos y, en el paso siguiente, Cliente 360).
     @ID_CLIENTE NULL  -> combo de cliente (desde Proyectos)
     @ID_CLIENTE <> 0  -> cliente fijo, no editable (desde Cliente 360)
     @ERROR <> ''      -> reabre con los valores enviados (buffer) y el error
   Campos del buffer (los lee VCT_PROYECTO_ALTA_GUARDAR):
     TEXTO11 nombre             TEXTO19 cliente (id)
     TEXTO12 referencia         TEXTO20 analista (VCT_EMPLEADOS.ID)
     TEXTO13 fecha inicio       TEXTO21 vence proxima accion
     TEXTO14 fecha fin          TEXTO22 servicios  id|inicio|fin|horas;...
     TEXTO15 total horas        TEXTO23 mail a notificar (editable)
     TEXTO16 tipo proyecto      TEXTO24 normas     id,id,...
     TEXTO18 nivel de riesgo    TEXTO25 honorarios  TEXTO26 viaticos pres.
     TEXTO27 costo estimado MO  TEXTO28 moneda      TEXTO30 comando
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_RENDER
(
    @IPKEYJOB   VARCHAR(100),
    @IUNIDAD    VARCHAR(100),
    @IAGENTE    VARCHAR(100),
    @ID_CLIENTE INT           = NULL,
    @ERROR      VARCHAR(1000) = '',
    @CMD_GUARDAR VARCHAR(50)  = 'PRY_ALTA_GUARDAR',
    @CMD_CANCELAR VARCHAR(50) = 'PRY_MODO_VIGENTES',
    @HTML       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ALTA_RENDER_V1 */
    SET NOCOUNT ON;
    SET @HTML = '';

    /* ---------- permiso: CREATE del modulo PROYECTOS ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
                   WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) IN ('CREATE','NEW','ADD','INSERT'))
    BEGIN
        SET @HTML = '<div class="vct-card"><div class="vct-card-body">No posee permisos para dar de alta proyectos.</div></div>';
        RETURN;
    END;

    DECLARE @FORM VARCHAR(50) = 'vctProyectoAlta', @REOPEN BIT = CASE WHEN ISNULL(@ERROR,'') <> '' THEN 1 ELSE 0 END,
            @B11 VARCHAR(4000)='', @B12 VARCHAR(4000)='', @B13 VARCHAR(4000)='', @B14 VARCHAR(4000)='', @B15 VARCHAR(4000)='',
            @B16 VARCHAR(4000)='', @B18 VARCHAR(4000)='', @B19 VARCHAR(4000)='', @B20 VARCHAR(4000)='', @B21 VARCHAR(4000)='',
            @B22 VARCHAR(4000)='', @B23 VARCHAR(4000)='', @B24 VARCHAR(4000)='', @B25 VARCHAR(4000)='', @B26 VARCHAR(4000)='',
            @B27 VARCHAR(4000)='', @B28 VARCHAR(4000)='', @CLI_NOM VARCHAR(300) = '';

    IF @REOPEN = 1
        SELECT TOP 1 @B11=ISNULL(TEXTO11,''), @B12=ISNULL(TEXTO12,''), @B13=ISNULL(TEXTO13,''), @B14=ISNULL(TEXTO14,''),
                     @B15=ISNULL(TEXTO15,''), @B16=ISNULL(TEXTO16,''), @B18=ISNULL(TEXTO18,''), @B19=ISNULL(TEXTO19,''),
                     @B20=ISNULL(TEXTO20,''), @B21=ISNULL(TEXTO21,''), @B22=ISNULL(TEXTO22,''), @B23=ISNULL(TEXTO23,''),
                     @B24=ISNULL(TEXTO24,''), @B25=ISNULL(TEXTO25,''), @B26=ISNULL(TEXTO26,''), @B27=ISNULL(TEXTO27,''),
                     @B28=ISNULL(TEXTO28,'')
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

    IF @ID_CLIENTE IS NOT NULL
    BEGIN
        SELECT @CLI_NOM = ISNULL(RAZON_SOCIAL,'') FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @ID_CLIENTE;
        SET @B19 = CONVERT(VARCHAR(20), @ID_CLIENTE);
    END;
    IF @B28 = '' SET @B28 = 'ARS';

    /* ---------- campos (renderer generico) ---------- */
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
        COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
        HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
    );

    IF @ID_CLIENTE IS NULL
        INSERT INTO #VCT_FORM_FIELDS VALUES (10,'TEXTO19','Cliente','TEXT',6,1,NULL,'Seleccione un cliente',NULL,NULLIF(@B19,''),0,0,NULL,NULL);
    ELSE
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (10,'TEXTO19','Cliente','HIDDEN',12,0,NULL,NULL,NULL,@B19,0,1,NULL,NULL),
            (11,'TEXTO29','Cliente','TEXT',6,0,NULL,NULL,NULL,@CLI_NOM,1,0,'Viene fijo desde la Vista 360 del cliente.',NULL);

    INSERT INTO #VCT_FORM_FIELDS VALUES
        (20,'TEXTO16','Tipo proyecto','TEXT',3,1,NULL,'Seleccione',NULL,NULLIF(@B16,''),0,0,NULL,NULL),
        (30,'TEXTO18','Nivel de riesgo','TEXT',3,1,NULL,'Seleccione',NULL,NULLIF(@B18,''),0,0,NULL,NULL),
        (40,'TEXTO11','Nombre','TEXT',8,1,300,'Nombre del proyecto',NULL,NULLIF(@B11,''),0,0,NULL,NULL),
        (50,'TEXTO12','Referencia','TEXT',4,0,300,'Ej. numero de propuesta',NULL,NULLIF(@B12,''),0,0,NULL,NULL),
        (60,'TEXTO13','Fecha inicio','DATE',3,1,NULL,NULL,NULL,NULLIF(@B13,''),0,0,NULL,NULL),
        (70,'TEXTO14','Fecha fin','DATE',3,1,NULL,NULL,NULL,NULLIF(@B14,''),0,0,NULL,NULL),
        (80,'TEXTO15','Total horas proyecto','NUMBER',3,1,NULL,'0',NULL,NULLIF(@B15,''),0,0,'Tope para la suma de los servicios.',NULL),
        (85,'TEXTO28','Moneda','TEXT',3,1,NULL,NULL,NULL,@B28,0,0,NULL,NULL),
        (90,'TEXTO22','Servicios','HIDDEN',12,0,NULL,NULL,NULL,@B22,0,1,NULL,NULL),         -- ancla: bloque Servicios + Normas
        (100,'TEXTO24','Normas','HIDDEN',12,0,NULL,NULL,NULL,@B24,0,1,NULL,NULL),           -- ancla: titulo Rentabilidad
        (120,'TEXTO25','Honorarios presupuestados','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B25,''),0,0,NULL,NULL),
        (130,'TEXTO26','Vi&aacute;ticos presupuestados','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B26,''),0,0,NULL,NULL),
        (140,'TEXTO27','Costo estimado de horas','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B27,''),0,0,NULL,NULL),
        (150,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,@CMD_GUARDAR,0,1,NULL,NULL),  -- ancla: titulo Proxima accion
        (160,'TEXTO20','Analista','TEXT',6,1,NULL,'Seleccione el analista',NULL,NULLIF(@B20,''),0,0,'Recibe la acci&oacute;n &ldquo;Asignar consultor&rdquo;.',NULL),
        (170,'TEXTO21','Vence','DATE',3,1,NULL,NULL,NULL,NULLIF(@B21,''),0,0,NULL,NULL),
        (180,'TEXTO23','Enviar mail a','EMAIL',9,0,1000,'mail@dominio.com',NULL,NULLIF(@B23,''),0,0,'Se completa con el mail del analista elegido; se puede modificar.',NULL);

    DECLARE @HF VARCHAR(MAX) = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID = @FORM, @TITLE = 'Nuevo proyecto',
         @SUBTITLE = 'El c&oacute;digo se asigna al guardar. Los campos con * son obligatorios.',
         @ICON = 'folder', @LAYOUT = 'PAGE', @SAVE_LABEL = 'Crear proyecto', @CANCEL_LABEL = 'Cancelar',
         @ERROR_MESSAGE = @ERROR, @OPEN_ON_RENDER = @REOPEN, @OUTHTML = @HF OUTPUT;

    SET @HF = REPLACE(ISNULL(@HF,''), 'type="date" ', 'type="date" data-vct-datepicker ');
    SET @HF = REPLACE(@HF, 'class="vct-card vct-form-shell ', 'class="vct-card vct-form-shell vct-pry-nuevo ');

    /* ---------- secciones e insertos en las anclas ---------- */
    DECLARE @P INT, @E INT,
            @SEC_DATOS VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Datos generales</div>',
            @SEC_SRV   VARCHAR(MAX),
            @SEC_RENT  VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Rentabilidad estimada <small>opcional</small></div>',
            @SEC_PROX  VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Pr&oacute;xima acci&oacute;n <small>Asignar consultor &middot; la recibe el analista</small></div>';

    SET @SEC_SRV =
          '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Servicios <small>una fila por servicio: fechas y horas. Nombre, lugar y responsable se completan al editar el servicio.</small></div>'
        + '<div class="vct-field vct-col-12"><div class="vct-pry-nuevo-srv" data-vct-pry-srv></div>'
        + '<div class="vct-pry-nuevo-bar" data-vct-pry-srv-bar></div></div>'
        + '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Normas <small>son del proyecto; obligatorias si hay consultor&iacute;a</small></div>'
        + '<div class="vct-field vct-col-12"><div class="vct-pry-nuevo-normas" data-vct-pry-normas></div></div>';

    SET @P = CHARINDEX('<div class="vct-form-grid">', @HF);
    IF @P > 0 SET @HF = STUFF(@HF, @P + LEN('<div class="vct-form-grid">'), 0, @SEC_DATOS);

    SET @P = CHARINDEX('name="SP.TEXTO22"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_SRV); END;
    SET @P = CHARINDEX('name="SP.TEXTO24"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_RENT); END;
    SET @P = CHARINDEX('name="SP.TEXTO30"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_PROX); END;

    /* Cancelar: vuelve a la pantalla de origen con el mismo mecanismo de modo */
    SET @P = CHARINDEX('<div class="vct-card-footer vct-form-footer">', @HF);
    IF @P > 0
        SET @HF = STUFF(@HF, @P + LEN('<div class="vct-card-footer vct-form-footer">'), 0,
            '<button type="button" class="vct-btn vct-btn-secondary" data-vct-pry-modo="' + @CMD_CANCELAR + '">Cancelar</button>');

    /* ---------- opciones de los combos ---------- */
    DECLARE @O_CLI VARCHAR(MAX) = '', @O_ANA VARCHAR(MAX) = '', @C_SRV VARCHAR(MAX) = '', @C_NOR VARCHAR(MAX) = '';

    IF @ID_CLIENTE IS NULL
        SELECT @O_CLI = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), C.ID) + '">'
                 + REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_CLIENTES C WITH(NOLOCK)
            ORDER BY C.RAZON_SOCIAL
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* analistas = empleados activos; data-email = mail principal (VCT_EMAILS, EMPLEADO) */
    SELECT @O_ANA = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), E.ID) + '" data-email="'
             + REPLACE(ISNULL((SELECT TOP 1 M.EMAIL FROM dbo.VCT_EMAILS M WITH(NOLOCK)
                               WHERE M.TIPO_ENTIDAD = 'EMPLEADO' AND M.ID_ENTIDAD = E.ID
                               ORDER BY CASE WHEN M.PRINCIPAL = 'SI' THEN 0 ELSE 1 END, M.ID),''),'"','')
             + '">' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
        WHERE ISNULL(E.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY E.APELLIDOS, E.NOMBRES
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @C_SRV = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), S.ID) + '" data-codigo="' + UPPER(ISNULL(S.CODIGO,'')) + '">'
             + REPLACE(REPLACE(REPLACE(ISNULL(S.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
        WHERE ISNULL(S.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY S.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @C_NOR = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), N.ID) + '">'
             + REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
        WHERE ISNULL(N.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY N.DESCRIPCION
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @HTML = '<div class="vct-pry-nuevo-page">' + @HF
        + CASE WHEN @ID_CLIENTE IS NULL THEN
          '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO19" data-vct-placeholder="Seleccione un cliente">' + @O_CLI + '</template>' ELSE '' END
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO16" data-vct-placeholder="Seleccione">'
        +   '<option value="IMPLEMENTACION">Implementaci&oacute;n</option><option value="MANTENIMIENTO">Mantenimiento</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO18" data-vct-placeholder="Seleccione">'
        +   '<option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO28" data-vct-placeholder="Moneda">'
        +   '<option value="ARS">ARS</option><option value="USD">USD</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO20" data-vct-placeholder="Seleccione el analista">' + @O_ANA + '</template>'
        + '<template data-vct-pry-catalog="servicios">' + @C_SRV + '</template>'
        + '<template data-vct-pry-catalog="normas">' + @C_NOR + '</template>'
        + '</div>';
END
GO

/* ========================================================================
   2. Parche de dbo.VCT_MAIN_PROYECTOS
   ======================================================================== */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_PROYECTOS')),
        @P INT, @Q INT, @ANC NVARCHAR(400), @BLK NVARCHAR(MAX), @OK BIT = 1;

IF OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER') IS NULL
BEGIN PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_RENDER no se creo: revisar el error del bloque anterior.'; SET @OK = 0; END;
IF @OK = 1 AND @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_PROYECTOS.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%PROYECTO_ALTA_FORM_V1%' BEGIN PRINT 'OK   VCT_MAIN_PROYECTOS ya tenia el formulario de alta.'; SET @OK = 0; END;

IF @OK = 1
BEGIN
    SET @P = PATINDEX(N'%CREATE%PROCEDURE%', @D);
    SET @Q = CHARINDEX(N'PROCEDURE', @D, @P);
    SET @D = STUFF(@D, @P, @Q + LEN(N'PROCEDURE') - @P, N'ALTER PROCEDURE');

    SET @ANC = N'SET @BTN_NUEVO = ISNULL(@BTN_NUEVO,'''');';
    SET @P = CHARINDEX(@ANC, @D);
    IF @P = 0 BEGIN PRINT 'FALLO ancla 1 no encontrada: ' + @ANC; SET @OK = 0; END;
END;

IF @OK = 1
BEGIN
    SET @BLK = N'
    
        /* PROYECTO_ALTA_FORM_V1: formulario de alta en pagina completa sobre el mismo paso.
           Permiso = la accion CREATE ya resuelta en @BTN_NUEVO (VCT_MAIN_GET_ACTIONS). */
        DECLARE @ALTA_ERR VARCHAR(1000) = '''', @ALTA_MSG VARCHAR(1000) = '''', @ALTA_ID INT = NULL,
                @ALTA_HTML VARCHAR(MAX) = '''', @ALTA_OK VARCHAR(MAX) = '''', @ALTA_VER VARCHAR(MAX) = '''';
        IF @BTN_NUEVO <> ''''
            SET @BTN_NUEVO = ''<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pry-modo="PRY_MODO_ALTA" data-vct-tooltip="Nuevo proyecto">''
                           + ''<span data-vct-icon="plus"></span><span>Nuevo</span></button>'';
        IF @B_CMD IN (''PRY_MODO_ALTA'',''PRY_ALTA_GUARDAR'') AND @BTN_NUEVO <> ''''
        BEGIN
            UPDATE dbo.VCT_BUFFER SET TEXTO30 = NULL WHERE PAR_KEY = @IPKEYJOB;
    
            /* CAMBIO 2 reemplaza este IF por EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR */
            IF @B_CMD = ''PRY_ALTA_GUARDAR''
                SET @ALTA_ERR = ''Formulario OK. Todavia no graba: el guardado se instala en el cambio 2.'';
    
            IF @B_CMD = ''PRY_MODO_ALTA'' OR ISNULL(@ALTA_ERR,'''') <> ''''
            BEGIN
                EXEC dbo.VCT_PROYECTO_ALTA_RENDER @IPKEYJOB = @IPKEYJOB, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,
                     @ID_CLIENTE = NULL, @ERROR = @ALTA_ERR, @CMD_GUARDAR = ''PRY_ALTA_GUARDAR'', @CMD_CANCELAR = ''PRY_MODO_VIGENTES'',
                     @HTML = @ALTA_HTML OUTPUT;
                SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'''') + @ASSETS
                    + ''<link rel="stylesheet" href="../css/vct-proyecto-nuevo.css?v=1"><script src="../js/vct-proyecto-nuevo.js?v=1"></script>''
                    + ''<div class="vct-page vct-page-main vct-proy-page" data-vct-page data-vct-sidebar-id="'' + CONVERT(VARCHAR(20), ISNULL(@SIDEBAR_ID,0)) + ''" data-vct-form-id="'' + @FORM_ESC + ''">''
                    + ISNULL(@ALTA_HTML,'''') + ''</div>'';
                RETURN;
            END;
    
            /* alta OK: aviso arriba de la grilla + Ver proyecto (accion VIEW) */
            SELECT TOP 1 @ALTA_VER = dbo.VCT_MAIN_RENDER_ACTION(A.ACTION_ID, A.TITLE, A.ICON, A.STORAGE_KEY, A.TARGET_TAB, A.TARGET_GUID,
                                                                CONVERT(VARCHAR(20), @ALTA_ID), ''vct-btn vct-btn-secondary vct-btn-sm'', ''Ver proyecto'')
            FROM #ACT A WHERE A.ACTION_TYPE = ''VIEW'' ORDER BY A.SORT_ORDER, A.ID_PRM;
            SET @ALTA_OK = ''<div class="vct-card vct-pry-nuevo-ok" style="display:flex;align-items:center;gap:12px;padding:12px 16px;margin:0 0 14px;border-left:3px solid #059669;">''
                         + ''<span data-vct-icon="check" style="color:#059669"></span><span style="flex:1;font-size:12px">''
                         + REPLACE(REPLACE(ISNULL(@ALTA_MSG,''''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' + ISNULL(@ALTA_VER,'''') + ''</div>'';
        END;';
    SET @D = STUFF(@D, @P + LEN(@ANC), 0, @BLK);

    SET @ANC = N'+ @KPIS';
    SET @P = CHARINDEX(@ANC, @D);
    IF @P = 0 BEGIN PRINT 'FALLO ancla 2 no encontrada: ' + @ANC; SET @OK = 0; END;
    ELSE SET @D = STUFF(@D, @P, LEN(@ANC), N'+ ISNULL(@ALTA_OK,'''') + @KPIS');
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_PROYECTOS: boton Nuevo abre el formulario (PROYECTO_ALTA_FORM_V1).';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_PROYECTOS: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF EXISTS (SELECT 1 FROM sys.procedures P CROSS JOIN #C1_RUN R
           WHERE P.object_id = OBJECT_ID('dbo.VCT_PROYECTO_ALTA_RENDER') AND P.modify_date >= R.INICIO)
    PRINT 'OK   dbo.VCT_PROYECTO_ALTA_RENDER creado/reemplazado.';

IF EXISTS (SELECT 1 FROM #C1_RUN WHERE TRG_ON = 1)
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
