/* ========================================================================
   CAMBIO 4 - ALTA: NORMAS OBLIGATORIAS Y VARIABLES DEL MAIL
   ------------------------------------------------------------------------
   Requiere CAMBIO_3_ALTA_ACCIONES_MAIL.sql ya aplicado.
     1. dbo.VCT_PROYECTO_ALTA_RENDER: Normas obligatorio en el formulario.
     2. dbo.VCT_PROYECTO_ALTA_GUARDAR: valida al menos una norma (siempre) y
        completa en el mail {{SERVICIOS}}, {{NORMAS}} y {{FECHA_LANZAMIENTO}}.
   Solo modifica esos dos SPs. Re-ejecutable.
   Antes de correrlo: subir js/vct-proyecto-alta.js.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#C4_RUN') IS NOT NULL DROP TABLE #C4_RUN;
CREATE TABLE #C4_RUN (TRG_ON BIT);
INSERT INTO #C4_RUN VALUES (0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #C4_RUN SET TRG_ON = 1;
END;
GO

/* ========================================================================
   1. dbo.VCT_PROYECTO_ALTA_RENDER  (V2: formulario unico, pantalla completa)
   ------------------------------------------------------------------------
   Arma el formulario "Nuevo proyecto" (#vctProyectoAlta) en pantalla
   completa, como el editor de templates. Es el MISMO para:
     @ORIGEN = 'PROYECTOS'     -> cliente seleccionable (sidebar Proyectos)
     @ORIGEN = 'CLIENTE_V360'  -> cliente fijo, no editable (@ID_CLIENTE)
   Permiso: accion CREATE del modulo PROYECTOS (dbo.VCT_MAIN_GET_ACTIONS).
            Sin permiso devuelve '' (no hay formulario).
   @ERROR <> '' -> lo vuelve a mostrar con lo enviado (VCT_BUFFER) y el error.
   Nuevo -> vct-proyecto-alta.js oculta la grilla / V360 y muestra el form.
   Volver (arriba) y Cancelar (abajo) vuelven a la pantalla de origen.
   Campos que viajan al buffer (los va a leer VCT_PROYECTO_ALTA_GUARDAR):
     TEXTO11 nombre               TEXTO19 cliente (VCT_CLIENTES.ID)
     TEXTO12 codigo (solo muestra) TEXTO20 analista (VCT_EMPLEADOS.ID)
     TEXTO13 fecha inicio         TEXTO21 fecha limite de lanzamiento
     TEXTO14 fecha fin            TEXTO22 servicios id|inicio|fin|horas;...
     TEXTO15 horas proyectadas    TEXTO23 referencia
     TEXTO16 tipo de proyecto     TEXTO24 normas id,id,...
     TEXTO17 contacto del cliente TEXTO25 rentabilidad (6 valores con |)
     TEXTO18 nivel de riesgo      TEXTO26 comentario de rentabilidad
     TEXTO30 comando (PROYECTOS) / entidad PROYECTO (CLIENTE_V360)
   El mail al analista va a su mail principal (VCT_EMAILS, EMPLEADO):
   se muestra como data-email en la opcion y lo resuelve el SP al grabar.
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_RENDER
(
    @IPKEYJOB   VARCHAR(100),
    @IUNIDAD    VARCHAR(100),
    @IAGENTE    VARCHAR(100),
    @ID_CLIENTE INT           = NULL,
    @ORIGEN     VARCHAR(20)   = 'PROYECTOS',
    @ERROR      VARCHAR(1000) = '',
    @HTML       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ALTA_RENDER_V2 */
    SET NOCOUNT ON;
    SET @HTML = '';
    SET @ORIGEN = UPPER(ISNULL(@ORIGEN,'PROYECTOS'));
    SET @ERROR = ISNULL(@ERROR,'');

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
                   WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'CREATE')
        RETURN;

    DECLARE @FORM VARCHAR(50) = 'vctProyectoAlta',
            @REOPEN BIT = CASE WHEN @ERROR <> '' THEN 1 ELSE 0 END,
            @B11 VARCHAR(4000)='', @B13 VARCHAR(4000)='', @B14 VARCHAR(4000)='', @B15 VARCHAR(4000)='',
            @B16 VARCHAR(4000)='', @B17 VARCHAR(4000)='', @B18 VARCHAR(4000)='', @B19 VARCHAR(4000)='',
            @B20 VARCHAR(4000)='', @B21 VARCHAR(4000)='', @B22 VARCHAR(4000)='', @B23 VARCHAR(4000)='',
            @B24 VARCHAR(4000)='', @B25 VARCHAR(4000)='', @B26 VARCHAR(4000)='',
            @CLI_NOM VARCHAR(300) = '', @COD VARCHAR(20) = '', @SUBT VARCHAR(500) = '', @VOLVER VARCHAR(100) = '';

    IF @REOPEN = 1
        SELECT TOP 1 @B11=ISNULL(TEXTO11,''), @B13=ISNULL(TEXTO13,''), @B14=ISNULL(TEXTO14,''), @B15=ISNULL(TEXTO15,''),
                     @B16=ISNULL(TEXTO16,''), @B17=ISNULL(TEXTO17,''), @B18=ISNULL(TEXTO18,''), @B19=ISNULL(TEXTO19,''),
                     @B20=ISNULL(TEXTO20,''), @B21=ISNULL(TEXTO21,''), @B22=ISNULL(TEXTO22,''), @B23=ISNULL(TEXTO23,''),
                     @B24=ISNULL(TEXTO24,''), @B25=ISNULL(TEXTO25,''), @B26=ISNULL(TEXTO26,'')
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

    IF @ORIGEN = 'CLIENTE_V360'
    BEGIN
        SELECT @CLI_NOM = ISNULL(RAZON_SOCIAL,'') FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @ID_CLIENTE;
        SET @B19 = ISNULL(CONVERT(VARCHAR(20), @ID_CLIENTE),'');
        SET @SUBT = 'Cliente: ' + REPLACE(REPLACE(REPLACE(@CLI_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;');
        SET @VOLVER = 'Volver al cliente';
    END
    ELSE
    BEGIN
        SET @ID_CLIENTE = NULL;
        SET @SUBT = 'Los campos con * son obligatorios.';
        SET @VOLVER = 'Volver a proyectos';
    END;

    /* codigo estimado: el definitivo lo asigna el guardado */
    SELECT @COD = CONVERT(VARCHAR(20), ISNULL(MAX(N),0) + 1)
    FROM (SELECT CASE WHEN CODIGO NOT LIKE '%[^0-9]%' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT, CODIGO) END AS N
          FROM dbo.VCT_PROYECTOS WITH(NOLOCK)) X;

    /* ---------- campos (renderer generico) ----------
       Si la pantalla que llama ya tiene #VCT_FORM_FIELDS se reutiliza. */
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NULL
        CREATE TABLE #VCT_FORM_FIELDS
        (
            ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
            COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
            OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
            HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
        );
    ELSE
        DELETE FROM #VCT_FORM_FIELDS;

    IF @ORIGEN = 'CLIENTE_V360'
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (10,'TEXTO19','Cliente','HIDDEN',12,0,NULL,NULL,NULL,@B19,0,1,NULL,NULL),
            (11,'TEXTO29','Cliente','TEXT',8,1,NULL,NULL,NULL,@CLI_NOM,1,0,'Viene de la Vista 360 del cliente.',NULL);
    ELSE
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (10,'TEXTO19','Cliente','TEXT',8,1,NULL,NULL,NULL,NULLIF(@B19,''),0,0,NULL,NULL);

    INSERT INTO #VCT_FORM_FIELDS VALUES
        (20,'TEXTO12','C&oacute;digo','TEXT',4,0,20,NULL,NULL,@COD,1,0,'Se confirma al guardar.',NULL),
        (30,'TEXTO11','Nombre del proyecto','TEXT',8,1,300,'Ej.: Implementaci&oacute;n ISO 9001:2015',NULL,NULLIF(@B11,''),0,0,NULL,NULL),
        (40,'TEXTO23','Referencia','TEXT',4,0,300,'Ej.: propuesta 2026-118',NULL,NULLIF(@B23,''),0,0,NULL,NULL),
        (50,'TEXTO16','Tipo de proyecto','TEXT',6,1,20,NULL,NULL,NULLIF(@B16,''),0,0,NULL,NULL),
        (60,'TEXTO18','Nivel de riesgo','TEXT',6,1,20,NULL,NULL,NULLIF(@B18,''),0,0,NULL,NULL),
        (70,'TEXTO13','Fecha inicio proyecto','DATE',4,1,NULL,'Fecha inicio',NULL,NULLIF(@B13,''),0,0,NULL,NULL),
        (80,'TEXTO14','Fecha fin proyecto','DATE',4,1,NULL,'Fecha fin',NULL,NULLIF(@B14,''),0,0,NULL,NULL),
        (90,'TEXTO15','Horas proyectadas','NUMBER',4,1,6,'0',NULL,NULLIF(@B15,''),0,0,'Tope para la suma de los servicios.',NULL),
        (100,'TEXTO22','Servicios','TEXT',12,1,4000,NULL,NULL,NULLIF(@B22,''),0,0,NULL,NULL),
        (110,'TEXTO24','Normas','TEXT',12,1,4000,NULL,NULL,NULLIF(@B24,''),0,0,NULL,NULL),
        (120,'TEXTO17','Contacto del cliente','TEXT',12,0,20,NULL,NULL,NULLIF(@B17,''),0,0,NULL,NULL),
        (130,'TEXTO20','Analista a cargo','TEXT',6,1,20,NULL,NULL,NULLIF(@B20,''),0,0,'Recibe la gesti&oacute;n y el mail para organizar el lanzamiento.',NULL),
        (140,'TEXTO21','Fecha l&iacute;mite de lanzamiento','DATE',6,1,NULL,'Fecha l&iacute;mite',NULL,NULLIF(@B21,''),0,0,'Vencimiento de la gesti&oacute;n del analista.',NULL),
        (150,'TEXTO25','Rentabilidad estimada','TEXT',12,0,4000,NULL,NULL,NULLIF(@B25,''),0,0,NULL,NULL),
        (160,'TEXTO26','Comentario rentabilidad','HIDDEN',12,0,NULL,NULL,NULL,NULLIF(@B26,''),0,1,NULL,NULL);

    /* ocultos segun la pantalla que recibe el guardado */
    IF @ORIGEN = 'CLIENTE_V360'
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (200,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL),
            (210,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'PROYECTO',0,1,NULL,NULL),
            (220,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
            (230,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
            (240,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
            (250,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'proyectos',0,1,NULL,NULL);
    ELSE
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (200,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'PRY_ALTA_GUARDAR',0,1,NULL,NULL);

    DECLARE @HF VARCHAR(MAX) = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID = @FORM, @TITLE = 'Nuevo proyecto', @SUBTITLE = @SUBT, @ICON = 'folder',
         @LAYOUT = 'PAGE', @SAVE_LABEL = 'Crear proyecto', @CANCEL_LABEL = 'Cancelar',
         @ERROR_MESSAGE = @ERROR, @OPEN_ON_RENDER = @REOPEN, @OUTHTML = @HF OUTPUT;

    /* fechas con el date picker propio y marca para el CSS/JS del alta */
    SET @HF = REPLACE(ISNULL(@HF,''), 'type="date" ', 'type="date" data-vct-datepicker ');
    SET @HF = REPLACE(@HF, 'class="vct-card vct-form-shell ', 'class="vct-card vct-form-shell vct-proy-alta ');
    /* encabezado: boton volver + icono (como el editor de templates) */
    SET @HF = REPLACE(@HF, '<div class="vct-form-header-accent"></div><div class="vct-form-header-copy">',
          '<div class="vct-form-header-accent"></div>'
        + '<button type="button" class="vct-proy-back-btn" data-vct-proy-alta-back data-vct-tooltip="' + @VOLVER + '" aria-label="' + @VOLVER + '"><span data-vct-icon="arrow-left"></span></button>'
        + '<span class="vct-proy-head-icon"><span data-vct-icon="folder"></span></span>'
        + '<div class="vct-form-header-copy">');
    /* pie: Cancelar antes de Crear proyecto */
    SET @HF = REPLACE(@HF, '<div class="vct-card-footer vct-form-footer">',
          '<div class="vct-card-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-proy-alta-back>Cancelar</button>');

    /* ---------- opciones ---------- */
    DECLARE @O_CLI VARCHAR(MAX) = '', @O_CON VARCHAR(MAX) = '', @O_ANA VARCHAR(MAX) = '',
            @C_SRV VARCHAR(MAX) = '', @C_NOR VARCHAR(MAX) = '';

    IF @ORIGEN <> 'CLIENTE_V360'
        SELECT @O_CLI = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), C.ID) + '">'
                 + REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_CLIENTES C WITH(NOLOCK)
            ORDER BY C.RAZON_SOCIAL
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* contactos: data-cliente para filtrarlos por el cliente elegido */
    SELECT @O_CON = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), C.ID) + '" data-cliente="' + CONVERT(VARCHAR(20), C.IDCLIENTE) + '">'
             + REPLACE(REPLACE(REPLACE(
                   LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ' ' + ISNULL(C.APELLIDO,'')))
                 + CASE WHEN ISNULL(C.CARGO,'') <> '' THEN ' - ' + C.CARGO ELSE '' END,
               '&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_CONTACTOS C WITH(NOLOCK)
        WHERE (@ID_CLIENTE IS NULL OR C.IDCLIENTE = @ID_CLIENTE)
          AND LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ISNULL(C.APELLIDO,''))) <> ''
        ORDER BY C.APELLIDO, C.NOMBRES, C.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* analistas = empleados activos; data-email = mail principal (VCT_EMAILS, EMPLEADO) */
    SELECT @O_ANA = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), E.ID) + '" data-email="'
             + REPLACE(ISNULL((SELECT TOP 1 M.EMAIL FROM dbo.VCT_EMAILS M WITH(NOLOCK)
                               WHERE M.TIPO_ENTIDAD = 'EMPLEADO' AND M.ID_ENTIDAD = E.ID AND M.PRINCIPAL = 'SI'
                               ORDER BY M.ID),''),'"','')
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

    /* normas: data-uso = cantidad de proyectos que la usan (las 8 mas usadas salen como chips) */
    SELECT @C_NOR = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), N.ID) + '" data-uso="'
             + CONVERT(VARCHAR(20), (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK) WHERE PN.ID_NORMA = N.ID)) + '">'
             + REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
        WHERE ISNULL(N.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY N.DESCRIPCION
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @HTML = '<div class="vct-proy-alta-view"' + CASE WHEN @REOPEN = 1 THEN ' data-vct-proy-reabrir="1"' ELSE '' END + '>' + @HF
        + CASE WHEN @ORIGEN <> 'CLIENTE_V360' THEN
          '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO19" data-vct-placeholder="Seleccione un cliente">' + @O_CLI + '</template>' ELSE '' END
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO16" data-vct-placeholder="Seleccione">'
        +   '<option value="IMPLEMENTACION">Implementaci&oacute;n</option><option value="MANTENIMIENTO">Mantenimiento</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO18" data-vct-placeholder="Seleccione">'
        +   '<option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO17" data-vct-placeholder="'
        +   CASE WHEN @ORIGEN <> 'CLIENTE_V360' THEN 'Seleccione primero el cliente' WHEN @O_CON = '' THEN 'El cliente no tiene contactos cargados' ELSE 'Seleccione un contacto' END + '">' + @O_CON + '</template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO20" data-vct-placeholder="Sin asignar">' + @O_ANA + '</template>'
        + '<template data-vct-proy-catalog="servicios">' + @C_SRV + '</template>'
        + '<template data-vct-proy-catalog="normas">' + @C_NOR + '</template>'
        + '</div>';
END
GO

/* ========================================================================
   2. dbo.VCT_PROYECTO_ALTA_GUARDAR
   ------------------------------------------------------------------------
   Graba el alta (paso 1) con lo que el formulario dejo en VCT_BUFFER.
   Lo llaman VCT_MAIN_PROYECTOS y VCT_MAIN_CLIENTES_V360.
     @ID_CLIENTE NULL  -> el cliente sale de TEXTO19 (Proyectos)
     @ID_CLIENTE <> 0  -> cliente fijo de la Vista 360 (se ignora TEXTO19)
   Valida en el orden del formulario y devuelve el PRIMER error en @ERROR
   (no graba nada). Si todo esta bien graba en una transaccion:
     VCT_ACCIONES (+ PARTICIPANTES + HISTORIAL) segun VCT_PRM_ACCIONES_REGLAS
                             del evento ANALISTA_ASIGNADO; despues manda los mails
                             de las reglas con GENERA_EMAIL = 1
     VCT_PROYECTOS           estado CONFIRMADO, codigo numerico siguiente
     VCT_PROYECTOS_SERVICIOS uno por servicio (inicio, fin, horas)
     VCT_PROYECTOS_NORMAS    normas del proyecto (ID_PROYECTO_SERVICIO NULL)
     VCT_PROYECTOS_EQUIPO    analista (rol de VCT_PRM_PROYECTOS_ROLES con
                             TIPO_MIEMBRO = 'EMPLEADO', el de menor ORDEN)
   Buffer:
     TEXTO11 nombre  TEXTO13 inicio  TEXTO14 fin  TEXTO15 horas proyectadas
     TEXTO16 tipo    TEXTO17 contacto TEXTO18 riesgo TEXTO19 cliente
     TEXTO20 analista TEXTO21 fecha limite de lanzamiento (vencimiento de la accion)
     TEXTO22 servicios id|aaaa-mm-dd|aaaa-mm-dd|horas;...
     TEXTO23 referencia TEXTO24 normas id,id,...
     TEXTO25 rentabilidad montoPres|montoViat|fechaPres|costoMo|costoViat|costoVarios
     TEXTO26 comentario de rentabilidad
   Compatibilidad 100: sin TRY_CONVERT / STRING_SPLIT / IIF / CONCAT.
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_GUARDAR
(
    @IPKEYJOB    VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @ID_CLIENTE  INT = NULL,
    @ERROR       VARCHAR(1000) = '' OUTPUT,
    @MENSAJE     VARCHAR(1000) = '' OUTPUT,
    @ID_PROYECTO INT = NULL OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ALTA_GUARDAR_V1 - V2: acciones y mail - V3: normas obligatorias y variables del mail */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ERROR = '';
    SET @MENSAJE = '';
    SET @ID_PROYECTO = NULL;

    /* ---------- permiso: accion CREATE del modulo PROYECTOS ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
                   WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'CREATE')
    BEGIN
        SET @ERROR = 'No tiene permiso para dar de alta proyectos.';
        RETURN;
    END;

    DECLARE @T11 VARCHAR(4000), @T13 VARCHAR(4000), @T14 VARCHAR(4000), @T15 VARCHAR(4000),
            @T16 VARCHAR(4000), @T17 VARCHAR(4000), @T18 VARCHAR(4000), @T19 VARCHAR(4000),
            @T20 VARCHAR(4000), @T21 VARCHAR(4000), @T22 VARCHAR(4000), @T23 VARCHAR(4000),
            @T24 VARCHAR(4000), @T25 VARCHAR(4000), @T26 VARCHAR(4000);

    SELECT TOP 1
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))),
        @T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))),
        @T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))), @T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))),
        @T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))), @T19 = LTRIM(RTRIM(ISNULL(TEXTO19,''))),
        @T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))), @T21 = LTRIM(RTRIM(ISNULL(TEXTO21,''))),
        @T22 = LTRIM(RTRIM(ISNULL(TEXTO22,''))), @T23 = LTRIM(RTRIM(ISNULL(TEXTO23,''))),
        @T24 = LTRIM(RTRIM(ISNULL(TEXTO24,''))), @T25 = LTRIM(RTRIM(ISNULL(TEXTO25,''))),
        @T26 = LTRIM(RTRIM(ISNULL(TEXTO26,'')))
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    IF @T11 IS NULL
    BEGIN
        SET @ERROR = 'No se encontraron los datos del formulario. Vuelva a cargarlo.';
        RETURN;
    END;

    DECLARE @CLI INT, @INI DATETIME, @FIN DATETIME, @HORAS INT, @CONTACTO INT, @ANALISTA INT,
            @LIMITE DATETIME, @ID_ESTADO INT, @ID_ROL_ANALISTA INT,
            @M1 NUMERIC(15,2), @M2 NUMERIC(15,2), @FPRES DATETIME, @C1 NUMERIC(15,2), @C2 NUMERIC(15,2), @C3 NUMERIC(15,2),
            @P INT, @Q INT, @ROW VARCHAR(400), @RESTO VARCHAR(4000), @X VARCHAR(400), @I INT;

    /* ---------- 1. cliente ---------- */
    IF @ID_CLIENTE IS NOT NULL SET @CLI = @ID_CLIENTE;
    ELSE IF @T19 <> '' AND @T19 NOT LIKE '%[^0-9]%' AND LEN(@T19) <= 9 SET @CLI = CONVERT(INT, @T19);
    IF @CLI IS NULL BEGIN SET @ERROR = 'Cliente es obligatorio.'; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @CLI)
    BEGIN SET @ERROR = 'El cliente elegido no existe.'; RETURN; END;

    /* ---------- 2. nombre, tipo, riesgo ---------- */
    IF @T11 = '' BEGIN SET @ERROR = 'Nombre del proyecto es obligatorio.'; RETURN; END;
    IF LEN(@T11) > 300 BEGIN SET @ERROR = 'Nombre del proyecto no puede superar 300 caracteres.'; RETURN; END;
    IF LEN(@T23) > 300 BEGIN SET @ERROR = 'Referencia no puede superar 300 caracteres.'; RETURN; END;
    IF @T16 NOT IN ('IMPLEMENTACION','MANTENIMIENTO') BEGIN SET @ERROR = 'Tipo de proyecto es obligatorio.'; RETURN; END;
    IF @T18 NOT IN ('Bajo','Medio','Alto') BEGIN SET @ERROR = 'Nivel de riesgo es obligatorio.'; RETURN; END;

    /* ---------- 3. fechas y horas del proyecto (aaaa-mm-dd -> aaaammdd, formato fijo) ---------- */
    IF @T13 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@T13,'-','')) = 1
        SET @INI = CONVERT(DATETIME, REPLACE(@T13,'-',''), 112);
    IF @INI IS NULL BEGIN SET @ERROR = 'Fecha inicio proyecto es obligatoria.'; RETURN; END;
    IF @T14 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@T14,'-','')) = 1
        SET @FIN = CONVERT(DATETIME, REPLACE(@T14,'-',''), 112);
    IF @FIN IS NULL BEGIN SET @ERROR = 'Fecha fin proyecto es obligatoria.'; RETURN; END;
    IF @FIN < @INI BEGIN SET @ERROR = 'La fecha fin del proyecto es anterior a la fecha inicio.'; RETURN; END;
    IF @T15 <> '' AND @T15 NOT LIKE '%[^0-9]%' AND LEN(@T15) <= 6 SET @HORAS = CONVERT(INT, @T15);
    IF ISNULL(@HORAS,0) <= 0 BEGIN SET @ERROR = 'Horas proyectadas es obligatorio y debe ser mayor a cero.'; RETURN; END;

    /* ---------- 4. servicios: id|inicio|fin|horas;... ---------- */
    DECLARE @SRV TABLE (ORDEN INT IDENTITY(1,1), ID_SERVICIO INT, T_INI VARCHAR(20), T_FIN VARCHAR(20), T_HRS VARCHAR(20),
                        INI DATETIME NULL, FIN DATETIME NULL, HRS INT NULL);
    SET @RESTO = @T22;
    WHILE @RESTO <> ''
    BEGIN
        SET @P = CHARINDEX(';', @RESTO);
        IF @P = 0 BEGIN SET @ROW = @RESTO; SET @RESTO = ''; END
        ELSE BEGIN SET @ROW = LEFT(@RESTO, @P - 1); SET @RESTO = SUBSTRING(@RESTO, @P + 1, 4000); END;
        IF @ROW = '' CONTINUE;
        SET @ROW = @ROW + '||||';
        SET @P = CHARINDEX('|', @ROW);
        SET @X = LEFT(@ROW, @P - 1);
        IF @X = '' OR @X LIKE '%[^0-9]%' OR LEN(@X) > 9 BEGIN SET @ERROR = 'Hay un servicio con un dato invalido. Vuelva a elegirlo.'; RETURN; END;
        SET @Q = CHARINDEX('|', @ROW, @P + 1);
        SET @I = CHARINDEX('|', @ROW, @Q + 1);
        INSERT INTO @SRV (ID_SERVICIO, T_INI, T_FIN, T_HRS)
        VALUES (CONVERT(INT, @X), SUBSTRING(@ROW, @P + 1, @Q - @P - 1), SUBSTRING(@ROW, @Q + 1, @I - @Q - 1),
                SUBSTRING(@ROW, @I + 1, CHARINDEX('|', @ROW, @I + 1) - @I - 1));
    END;

    IF NOT EXISTS (SELECT 1 FROM @SRV) BEGIN SET @ERROR = 'Seleccione al menos un servicio.'; RETURN; END;
    IF EXISTS (SELECT ID_SERVICIO FROM @SRV GROUP BY ID_SERVICIO HAVING COUNT(*) > 1)
    BEGIN SET @ERROR = 'Hay un servicio repetido.'; RETURN; END;

    SET @X = NULL;
    SELECT TOP 1 @X = CONVERT(VARCHAR(20), S.ID_SERVICIO)
    FROM @SRV S LEFT JOIN dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) ON P.ID = S.ID_SERVICIO AND ISNULL(P.ESTADO,'ACTIVO') = 'ACTIVO'
    WHERE P.ID IS NULL ORDER BY S.ORDEN;
    IF @X IS NOT NULL BEGIN SET @ERROR = 'El servicio ' + @X + ' no existe o no esta activo.'; RETURN; END;

    UPDATE @SRV SET
        INI = CASE WHEN T_INI LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(T_INI,'-','')) = 1
                   THEN CONVERT(DATETIME, REPLACE(T_INI,'-',''), 112) END,
        FIN = CASE WHEN T_FIN LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(T_FIN,'-','')) = 1
                   THEN CONVERT(DATETIME, REPLACE(T_FIN,'-',''), 112) END,
        HRS = CASE WHEN T_HRS <> '' AND T_HRS NOT LIKE '%[^0-9]%' AND LEN(T_HRS) <= 6 THEN CONVERT(INT, T_HRS) END;

    SET @X = NULL;
    SELECT TOP 1 @X = ISNULL(P.DESCRIPCION,'Servicio') + CASE
                 WHEN S.INI IS NULL OR S.FIN IS NULL THEN ': falta la fecha de inicio o de fin.'
                 WHEN S.FIN < S.INI THEN ': la fecha de fin es anterior al inicio.'
                 WHEN S.INI < @INI OR S.FIN > @FIN THEN ': las fechas deben estar dentro del plazo del proyecto.'
                 ELSE ': cargue las horas.' END
    FROM @SRV S JOIN dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) ON P.ID = S.ID_SERVICIO
    WHERE S.INI IS NULL OR S.FIN IS NULL OR S.FIN < S.INI OR S.INI < @INI OR S.FIN > @FIN OR ISNULL(S.HRS,0) <= 0
    ORDER BY S.ORDEN;
    IF @X IS NOT NULL BEGIN SET @ERROR = @X; RETURN; END;

    IF (SELECT SUM(HRS) FROM @SRV) <> @HORAS
    BEGIN
        SELECT @ERROR = 'La suma de horas de los servicios (' + CONVERT(VARCHAR(20), SUM(HRS)) + ' h) debe ser igual a las horas proyectadas ('
                      + CONVERT(VARCHAR(20), @HORAS) + ' h).'
        FROM @SRV;
        RETURN;
    END;

    /* ---------- 5. normas: id,id,... (al menos una) ---------- */
    DECLARE @NOR TABLE (ORDEN INT IDENTITY(1,1), ID_NORMA INT);
    SET @RESTO = @T24;
    WHILE @RESTO <> ''
    BEGIN
        SET @P = CHARINDEX(',', @RESTO);
        IF @P = 0 BEGIN SET @X = LTRIM(RTRIM(@RESTO)); SET @RESTO = ''; END
        ELSE BEGIN SET @X = LTRIM(RTRIM(LEFT(@RESTO, @P - 1))); SET @RESTO = SUBSTRING(@RESTO, @P + 1, 4000); END;
        IF @X = '' CONTINUE;
        IF @X LIKE '%[^0-9]%' OR LEN(@X) > 9 BEGIN SET @ERROR = 'Hay una norma con un dato invalido. Vuelva a elegirla.'; RETURN; END;
        IF NOT EXISTS (SELECT 1 FROM @NOR WHERE ID_NORMA = CONVERT(INT, @X))
            INSERT INTO @NOR (ID_NORMA) VALUES (CONVERT(INT, @X));
    END;

    IF EXISTS (SELECT 1 FROM @NOR N LEFT JOIN dbo.VCT_PRM_NORMAS P WITH(NOLOCK) ON P.ID = N.ID_NORMA AND ISNULL(P.ESTADO,'ACTIVO') = 'ACTIVO'
               WHERE P.ID IS NULL)
    BEGIN SET @ERROR = 'Hay una norma que no existe o no esta activa.'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM @NOR)
    BEGIN SET @ERROR = 'Normas es obligatorio: elija al menos una norma.'; RETURN; END;

    /* ---------- 6. contacto (opcional, tiene que ser del cliente) ---------- */
    IF @T17 <> ''
    BEGIN
        IF @T17 NOT LIKE '%[^0-9]%' AND LEN(@T17) <= 9 SET @CONTACTO = CONVERT(INT, @T17);
        IF @CONTACTO IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CONTACTOS WITH(NOLOCK) WHERE ID = @CONTACTO AND IDCLIENTE = @CLI)
        BEGIN SET @ERROR = 'El contacto elegido no pertenece al cliente.'; RETURN; END;
    END;

    /* ---------- 7. analista y fecha limite (obligatorios) ---------- */
    IF @T20 <> '' AND @T20 NOT LIKE '%[^0-9]%' AND LEN(@T20) <= 9 SET @ANALISTA = CONVERT(INT, @T20);
    IF @ANALISTA IS NULL BEGIN SET @ERROR = 'Analista a cargo es obligatorio.'; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID = @ANALISTA AND ISNULL(ESTADO,'ACTIVO') = 'ACTIVO')
    BEGIN SET @ERROR = 'El analista elegido no existe o no esta activo.'; RETURN; END;
    IF @T21 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@T21,'-','')) = 1
        SET @LIMITE = CONVERT(DATETIME, REPLACE(@T21,'-',''), 112);
    IF @LIMITE IS NULL BEGIN SET @ERROR = 'Fecha limite de lanzamiento es obligatoria.'; RETURN; END;

    SELECT TOP 1 @ID_ROL_ANALISTA = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK)
    WHERE TIPO_MIEMBRO = 'EMPLEADO' AND ACTIVO = 1 ORDER BY ORDEN, ID;
    IF @ID_ROL_ANALISTA IS NULL BEGIN SET @ERROR = 'Falta en VCT_PRM_PROYECTOS_ROLES un rol activo con TIPO_MIEMBRO EMPLEADO.'; RETURN; END;

    /* ---------- 8. rentabilidad (opcional): 6 valores con | ---------- */
    IF REPLACE(@T25,'|','') <> ''
    BEGIN
        DECLARE @RV TABLE (POS INT, VALOR VARCHAR(40));
        SET @RESTO = @T25 + '|';
        SET @I = 1;
        WHILE @RESTO <> '' AND @I <= 6
        BEGIN
            SET @P = CHARINDEX('|', @RESTO);
            IF @P = 0 BREAK;
            INSERT INTO @RV VALUES (@I, LTRIM(RTRIM(LEFT(@RESTO, @P - 1))));
            SET @RESTO = SUBSTRING(@RESTO, @P + 1, 4000);
            SET @I = @I + 1;
        END;
        IF EXISTS (SELECT 1 FROM @RV WHERE POS <> 3 AND VALOR <> ''
                   AND (VALOR LIKE '%[^0-9.]%' OR VALOR LIKE '%.%.%' OR LEN(VALOR) > 16))
        BEGIN SET @ERROR = 'Hay un importe de rentabilidad invalido.'; RETURN; END;
        SELECT @M1 = CONVERT(NUMERIC(15,2), NULLIF(VALOR,'')) FROM @RV WHERE POS = 1;
        SELECT @M2 = CONVERT(NUMERIC(15,2), NULLIF(VALOR,'')) FROM @RV WHERE POS = 2;
        SELECT @C1 = CONVERT(NUMERIC(15,2), NULLIF(VALOR,'')) FROM @RV WHERE POS = 4;
        SELECT @C2 = CONVERT(NUMERIC(15,2), NULLIF(VALOR,'')) FROM @RV WHERE POS = 5;
        SELECT @C3 = CONVERT(NUMERIC(15,2), NULLIF(VALOR,'')) FROM @RV WHERE POS = 6;
        SELECT @FPRES = CASE WHEN VALOR LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(VALOR,'-','')) = 1
                             THEN CONVERT(DATETIME, REPLACE(VALOR,'-',''), 112) END
        FROM @RV WHERE POS = 3;
    END;
    IF LEN(@T26) > 4000 BEGIN SET @ERROR = 'El comentario de rentabilidad es demasiado largo.'; RETURN; END;

    /* ---------- 9. reglas del workflow: evento ANALISTA_ASIGNADO ----------
       Todo sale de dbo.VCT_PRM_ACCIONES_REGLAS (tabla de referencia):
         ID_TIPO / ID_SUBTIPO / ID_ESTADO_INICIAL / ID_PRIORIDAD -> la accion
         DESTINATARIO_ROL = VCT_PRM_PROYECTOS_ROLES.CODIGO -> responsable
         DIAS_VENCIMIENTO no nulo -> vence en la Fecha limite del formulario
         GENERA_EMAIL + ID_EMAIL_TEMPLATE -> mail (plantilla de VCT_PRM_EMAIL_TEMPLATES)
       El destinatario del mail lo define la plantilla (DESTINO_TIPO). */
    DECLARE @RG TABLE (ID INT, CODIGO VARCHAR(100), ID_TIPO INT, ID_SUBTIPO INT, ID_ESTADO INT, ID_PRIORIDAD INT,
                       ROL VARCHAR(100), TITULO VARCHAR(300), DETALLE VARCHAR(MAX), DIAS INT, MAIL BIT, ID_TPL INT,
                       ES_FINAL BIT, ID_ACCION INT NULL);
    INSERT INTO @RG (ID, CODIGO, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ROL, TITULO, DETALLE, DIAS, MAIL, ID_TPL, ES_FINAL)
    SELECT R.ID, R.CODIGO, R.ID_TIPO, R.ID_SUBTIPO, R.ID_ESTADO_INICIAL, R.ID_PRIORIDAD, LTRIM(RTRIM(ISNULL(R.DESTINATARIO_ROL,''))),
           R.TITULO_PLANTILLA, R.DETALLE_PLANTILLA, R.DIAS_VENCIMIENTO, R.GENERA_EMAIL, R.ID_EMAIL_TEMPLATE, ISNULL(E.ES_FINAL, 0)
    FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = R.ID_ESTADO_INICIAL
    WHERE R.CODIGO_EVENTO = 'ANALISTA_ASIGNADO' AND R.ACTIVO = 1;

    /* el unico integrante al dar de alta es el analista: cada regla tiene que apuntar a su rol */
    SET @X = NULL;
    SELECT TOP 1 @X = G.CODIGO + ' (DESTINATARIO_ROL = ' + CASE WHEN G.ROL = '' THEN 'vacio' ELSE G.ROL END + ')'
    FROM @RG G
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES PR WITH(NOLOCK) ON PR.CODIGO = G.ROL
    WHERE ISNULL(PR.ID, -1) <> @ID_ROL_ANALISTA
    ORDER BY G.ID;
    IF @X IS NOT NULL BEGIN SET @ERROR = 'La regla ' + @X + ' no corresponde al rol del analista en VCT_PRM_PROYECTOS_ROLES.'; RETURN; END;

    SELECT @ID_ESTADO = ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CONFIRMADO';
    IF @ID_ESTADO IS NULL BEGIN SET @ERROR = 'Falta el estado CONFIRMADO en VCT_PRM_PROYECTOS_ESTADOS.'; RETURN; END;

    /* ---------- 10. grabar ---------- */
    DECLARE @COD VARCHAR(20), @LOCK INT;
    BEGIN TRY
        BEGIN TRAN;

        /* codigo numerico siguiente, sin repetir aunque graben dos a la vez */
        EXEC @LOCK = sp_getapplock @Resource = 'VCT_PROYECTO_ALTA_CODIGO', @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LOCK < 0 RAISERROR('No se pudo reservar el codigo del proyecto. Intente nuevamente.', 16, 1);

        SELECT @COD = CONVERT(VARCHAR(20), ISNULL(MAX(N), 0) + 1)
        FROM (SELECT CASE WHEN CODIGO NOT LIKE '%[^0-9]%' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT, CODIGO) END AS N
              FROM dbo.VCT_PROYECTOS WITH(UPDLOCK, HOLDLOCK)) X;

        INSERT INTO dbo.VCT_PROYECTOS
            (IDCLIENTE, CODIGO, NOMBRE, REFERENCIA, ID_ESTADO, FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE, MONEDA,
             MONTO_PRES, MONTO_PRES_VIAT, COSTO_MO, COSTO_VIAT, COSTO_VARIOS, MONTO_TOTAL, COSTO_TOTAL,
             OBSERV_RENTA, FECHA_PRESUPUESTO, FECHA_ALTA, USUARIO_ALTA,
             TOTAL_HORAS_PROYECTADAS, TOTAL_HORAS_EJECUTADAS, NIVEL_RIESGO, IDCONTACTO, TIPO_PROYECTO)
        VALUES
            (@CLI, @COD, @T11, NULLIF(@T23,''), @ID_ESTADO, @INI, @FIN, 0, NULL,
             @M1, @M2, @C1, @C2, @C3,
             CASE WHEN @M1 IS NULL AND @M2 IS NULL THEN NULL ELSE ISNULL(@M1,0) + ISNULL(@M2,0) END,
             CASE WHEN @C1 IS NULL AND @C2 IS NULL AND @C3 IS NULL THEN NULL ELSE ISNULL(@C1,0) + ISNULL(@C2,0) + ISNULL(@C3,0) END,
             NULLIF(@T26,''), @FPRES, GETDATE(), @IAGENTE,
             @HORAS, 0, @T18, @CONTACTO, @T16);

        SET @ID_PROYECTO = SCOPE_IDENTITY();

        /* servicios: principal = consultoria si esta, si no el primero */
        INSERT INTO dbo.VCT_PROYECTOS_SERVICIOS
            (ID_PROYECTO, ID_SERVICIO, ID_ESTADO, PRINCIPAL, ORDEN, FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE,
             FECHA_ALTA, USUARIO_ALTA, SECUENCIA, TOTAL_HORAS_PROYECTADAS, TOTAL_HORAS_EJECUTADAS)
        SELECT @ID_PROYECTO, S.ID_SERVICIO, @ID_ESTADO,
               CASE WHEN S.ORDEN = (SELECT TOP 1 S2.ORDEN FROM @SRV S2 JOIN dbo.VCT_PRM_SERVICIOS P2 WITH(NOLOCK) ON P2.ID = S2.ID_SERVICIO
                                    ORDER BY CASE WHEN UPPER(ISNULL(P2.CODIGO,'')) = 'CONSULTORIA' THEN 0 ELSE 1 END, S2.ORDEN)
                    THEN 1 ELSE 0 END,
               S.ORDEN, S.INI, S.FIN, 0, GETDATE(), @IAGENTE, 1, S.HRS, 0
        FROM @SRV S;

        INSERT INTO dbo.VCT_PROYECTOS_NORMAS
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, ID_NORMA, PRINCIPAL, OBLIGATORIA, ESTADO, FECHA_ALTA, USUARIO_ALTA)
        SELECT @ID_PROYECTO, NULL, N.ID_NORMA, CASE WHEN N.ORDEN = 1 THEN 1 ELSE 0 END, 1, 'ACTIVA', GETDATE(), @IAGENTE
        FROM @NOR N;

        INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL,
             FECHA_DESDE, ESTADO, FECHA_ALTA, USUARIO_ALTA)
        VALUES
            (@ID_PROYECTO, NULL, 'EMPLEADO', @ANALISTA, NULL, @ID_ROL_ANALISTA, 1,
             GETDATE(), 'ACTIVO', GETDATE(), @IAGENTE);

        /* acciones de las reglas: accion + responsable + historial */
        DECLARE @RID INT = 0, @NEWA INT;
        WHILE 1 = 1
        BEGIN
            SET @NEWA = NULL;
            SELECT TOP 1 @RID = ID FROM @RG WHERE ID > @RID ORDER BY ID;
            IF @@ROWCOUNT = 0 BREAK;

            INSERT INTO dbo.VCT_ACCIONES
                (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_REGLA_ORIGEN, TITULO, DESCRIPCION,
                 ID_CLIENTE, ID_PROYECTO, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
            SELECT 'AUTOMATICA', G.ID_TIPO, G.ID_SUBTIPO, G.ID_ESTADO, G.ID_PRIORIDAD, G.ID,
                   LEFT(REPLACE(REPLACE(G.TITULO, '{{CODIGO_PROYECTO}}', @COD), '{{PROYECTO}}', @T11), 300),
                   REPLACE(REPLACE(ISNULL(G.DETALLE, ''), '{{CODIGO_PROYECTO}}', @COD), '{{PROYECTO}}', @T11),
                   @CLI, @ID_PROYECTO, GETDATE(), GETDATE(),
                   CASE WHEN G.ES_FINAL = 1 OR G.DIAS IS NULL THEN NULL ELSE @LIMITE END,
                   CASE WHEN G.ES_FINAL = 1 THEN GETDATE() END,
                   GETDATE(), @IAGENTE
            FROM @RG G WHERE G.ID = @RID;
            SET @NEWA = SCOPE_IDENTITY();

            INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES
                (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
            VALUES (@NEWA, 'RESPONSABLE', 'EMPLEADO', @ANALISTA, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);

            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL
                (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
            SELECT @NEWA, NULL, G.ID_ESTADO, 'ALTA',
                   LEFT('Generada por la regla ' + G.CODIGO + ' al dar de alta el proyecto ' + @COD + '.', 2000),
                   'SISTEMA', GETDATE(), @IAGENTE
            FROM @RG G WHERE G.ID = @RID;

            UPDATE @RG SET ID_ACCION = @NEWA WHERE ID = @RID;
        END;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        SET @ID_PROYECTO = NULL;
        SET @ERROR = LEFT('No se pudo grabar el proyecto: ' + ERROR_MESSAGE(), 1000);
        RETURN;
    END CATCH;

    /* alta OK: se limpia lo cargado para que el formulario no vuelva a abrirse con esos datos */
    UPDATE dbo.VCT_BUFFER
       SET TEXTO11 = NULL, TEXTO13 = NULL, TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL, TEXTO17 = NULL,
           TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL, TEXTO21 = NULL, TEXTO22 = NULL, TEXTO23 = NULL,
           TEXTO24 = NULL, TEXTO25 = NULL, TEXTO26 = NULL
     WHERE PAR_KEY = @IPKEYJOB;

    SET @MENSAJE = 'Proyecto ' + @COD + ' creado.';

    /* ---------- 11. mails de las reglas (despues de grabar: si falla el mail, el proyecto queda) ----------
       Plantilla: VCT_PRM_EMAIL_TEMPLATES.ID = regla.ID_EMAIL_TEMPLATE.
       Destino y CC: los resuelve dbo.VCT_MAIN_SEND_EMAIL segun DESTINO_TIPO / CC_TIPO de la plantilla
       (LIBRE = DESTINO_LIBRE, ANALISTA = mail principal del analista en VCT_EMAILS).
       Aca solo se completa {{CODIGO_PROYECTO}} y se envia con el perfil de Database Mail
       marcado como predeterminado en msdb. El resultado queda en VCT_ACCIONES_HISTORIAL. */
    DECLARE @TPL VARCHAR(50), @PERFIL SYSNAME, @MAIL_OK VARCHAR(1000) = '', @MAIL_ERR VARCHAR(1000) = '';
    DECLARE @PV TABLE (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));

    SELECT TOP 1 @PERFIL = P.name
    FROM msdb.dbo.sysmail_profile P
    JOIN msdb.dbo.sysmail_principalprofile PP ON PP.profile_id = P.profile_id
    WHERE PP.is_default = 1
    ORDER BY P.profile_id;

    /* textos para {{SERVICIOS}}, {{NORMAS}} y {{FECHA_LANZAMIENTO}} */
    DECLARE @V_SRV_TXT VARCHAR(MAX) = '', @V_SRV_HTML VARCHAR(MAX) = '', @V_NOR_TXT VARCHAR(MAX) = '',
            @V_NOR_HTML VARCHAR(MAX) = '', @V_LIM VARCHAR(10) = CONVERT(VARCHAR(10), @LIMITE, 103);
    SELECT @V_SRV_TXT = @V_SRV_TXT + CASE WHEN @V_SRV_TXT = '' THEN '' ELSE ', ' END
                      + ISNULL(P.DESCRIPCION,'') + ' (' + CONVERT(VARCHAR(10), S.INI, 103) + ' al '
                      + CONVERT(VARCHAR(10), S.FIN, 103) + ', ' + CONVERT(VARCHAR(10), S.HRS) + ' h)'
    FROM @SRV S JOIN dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) ON P.ID = S.ID_SERVICIO
    ORDER BY S.ORDEN;
    SELECT @V_NOR_TXT = @V_NOR_TXT + CASE WHEN @V_NOR_TXT = '' THEN '' ELSE ', ' END + ISNULL(P.DESCRIPCION,'')
    FROM @NOR N JOIN dbo.VCT_PRM_NORMAS P WITH(NOLOCK) ON P.ID = N.ID_NORMA
    ORDER BY N.ORDEN;
    SET @V_SRV_HTML = REPLACE(REPLACE(REPLACE(@V_SRV_TXT, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
    SET @V_NOR_HTML = REPLACE(REPLACE(REPLACE(@V_NOR_TXT, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');

    SET @RID = 0;
    WHILE 1 = 1
    BEGIN
        SET @TPL = NULL;
        SELECT TOP 1 @RID = G.ID, @NEWA = G.ID_ACCION, @TPL = T.CODIGO
        FROM @RG G LEFT JOIN dbo.VCT_PRM_EMAIL_TEMPLATES T WITH(NOLOCK) ON T.ID = G.ID_TPL AND T.ESTADO = 'ACTIVO'
        WHERE G.ID > @RID AND G.MAIL = 1
        ORDER BY G.ID;
        IF @@ROWCOUNT = 0 BREAK;

        DELETE FROM @PV;
        SET @MAIL_ERR = '';
        BEGIN TRY
            IF @TPL IS NULL RAISERROR('la regla no tiene una plantilla activa (ID_EMAIL_TEMPLATE).', 16, 1);
            IF @PERFIL IS NULL RAISERROR('no hay un perfil de Database Mail predeterminado en msdb.', 16, 1);

            INSERT INTO @PV EXEC dbo.VCT_MAIN_SEND_EMAIL @CODIGO = @TPL, @ID_PROYECTO = @ID_PROYECTO,
                                 @ID_ANALISTA = @ANALISTA, @ID_CLIENTE = @CLI, @PROFILE_NAME = NULL;

            /* variables propias del alta (VCT_MAIN_SEND_EMAIL no las conoce) */
            UPDATE @PV SET
                ASUNTO = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ASUNTO,
                            '{{CODIGO_PROYECTO}}', @COD), '{{SERVICIOS}}', @V_SRV_TXT), '{{NORMAS}}', @V_NOR_TXT),
                            '{{FECHA_LANZAMIENTO}}', @V_LIM), '{{FECHA_VENCIMIENTO}}', @V_LIM),
                HTML_CONTENIDO = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(HTML_CONTENIDO,
                            '{{CODIGO_PROYECTO}}', @COD), '{{SERVICIOS}}', @V_SRV_HTML), '{{NORMAS}}', @V_NOR_HTML),
                            '{{FECHA_LANZAMIENTO}}', @V_LIM), '{{FECHA_VENCIMIENTO}}', @V_LIM);

            IF NOT EXISTS (SELECT 1 FROM @PV WHERE ISNULL(DESTINATARIO,'') <> '')
                RAISERROR('la plantilla no resolvio el destinatario.', 16, 1);

            DECLARE @M_TO VARCHAR(1000), @M_CC VARCHAR(1000), @M_ASU VARCHAR(500), @M_BODY VARCHAR(MAX);
            SELECT TOP 1 @M_TO = DESTINATARIO, @M_CC = NULLIF(CC,''), @M_ASU = ASUNTO, @M_BODY = HTML_CONTENIDO FROM @PV;

            EXEC msdb.dbo.sp_send_dbmail @profile_name = @PERFIL, @recipients = @M_TO, @copy_recipients = @M_CC,
                                         @subject = @M_ASU, @body = @M_BODY, @body_format = 'HTML';

            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
            VALUES (@NEWA, 'EMAIL_ENVIADO', LEFT('Plantilla ' + @TPL + ' a ' + @M_TO + ' (perfil ' + @PERFIL + ').', 2000), 'SISTEMA', GETDATE(), @IAGENTE);
            SET @MAIL_OK = @M_TO;
        END TRY
        BEGIN CATCH
            SET @MAIL_ERR = LEFT(ERROR_MESSAGE(), 500);
            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
            VALUES (@NEWA, 'EMAIL_NO_ENVIADO', LEFT('Plantilla ' + ISNULL(@TPL,'-') + ': ' + @MAIL_ERR, 2000), 'SISTEMA', GETDATE(), @IAGENTE);
        END CATCH;
    END;

    IF @MAIL_OK <> '' SET @MENSAJE = @MENSAJE + ' Se envio el mail a ' + @MAIL_OK + '.';
    IF @MAIL_ERR <> '' SET @MENSAJE = LEFT(@MENSAJE + ' El mail no se pudo enviar: ' + @MAIL_ERR, 1000);
END
GO


IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_GUARDAR')),N'') LIKE N'%V3: normas obligatorias%'
    PRINT 'OK   dbo.VCT_PROYECTO_ALTA_GUARDAR actualizado.';
ELSE
    PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_GUARDAR no se actualizo.';
IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER')),N'') LIKE N'%VCT_PROYECTO_ALTA_RENDER_V2%'
    PRINT 'OK   dbo.VCT_PROYECTO_ALTA_RENDER actualizado.';
IF EXISTS (SELECT 1 FROM #C4_RUN WHERE TRG_ON = 1)
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
