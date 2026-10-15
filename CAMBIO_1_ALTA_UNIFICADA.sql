/* ========================================================================
   CAMBIO 1 (V2) - ALTA DE PROYECTO UNIFICADA (pantalla completa, todavia NO graba)
   ------------------------------------------------------------------------
   Reemplaza lo instalado por CAMBIO_1_FORMULARIO_ALTA.sql.
     1. VCT_PROYECTOS: agrega TIPO_PROYECTO VARCHAR(20) NULL (si no existe).
     2. dbo.VCT_PROYECTO_ALTA_RENDER (ya existe, se modifica): un solo
        formulario de pantalla completa para Proyectos y para la Vista 360
        de Cliente (cliente fijo). Boton volver arriba, como en templates.
     3. dbo.VCT_MAIN_PROYECTOS: boton Nuevo muestra el formulario (PROYECTO_ALTA_FORM_V2).
     4. dbo.VCT_MAIN_CLIENTES_V360: el alta vieja usa el mismo SP (ALTA_PROYECTO_V2)
        y deja de llamar a dbo.VCT_PERFIL_PUEDE.
   No crea SPs, vistas, funciones ni permisos. Re-ejecutable: si los pasos
   3 y 4 ya estan aplicados, avisa "ya tenia" y no los toca.
   "Crear proyecto" valida y vuelve a mostrar el formulario con el aviso
   "Todavia no graba": el guardado es el cambio 2.
   Antes de correrlo: subir css/vct-proyecto-alta.css y js/vct-proyecto-alta.js (v3).
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
   1. VCT_PROYECTOS.TIPO_PROYECTO (IMPLEMENTACION / MANTENIMIENTO, sin CHECK)
   ======================================================================== */
BEGIN TRY
    IF COL_LENGTH('dbo.VCT_PROYECTOS','TIPO_PROYECTO') IS NULL
    BEGIN
        ALTER TABLE dbo.VCT_PROYECTOS ADD TIPO_PROYECTO VARCHAR(20) NULL;
        PRINT 'OK   VCT_PROYECTOS.TIPO_PROYECTO agregado.';
    END
    ELSE PRINT 'OK   VCT_PROYECTOS.TIPO_PROYECTO ya existia.';
END TRY
BEGIN CATCH
    PRINT 'FALLO VCT_PROYECTOS.TIPO_PROYECTO: ' + ERROR_MESSAGE();
END CATCH;
GO

/* ========================================================================
   2. dbo.VCT_PROYECTO_ALTA_RENDER  (V2: formulario unico, pantalla completa)
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
        (110,'TEXTO24','Normas','TEXT',12,0,4000,NULL,NULL,NULLIF(@B24,''),0,0,'Obligatorias si hay consultor&iacute;a.',NULL),
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
   3. Parche de dbo.VCT_MAIN_PROYECTOS (sobre la definicion vigente)
      - si tiene el V1, lo reemplaza por el V2
      - si no tiene ninguno, lo inserta despues de SET @BTN_NUEVO = ...
   ======================================================================== */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_PROYECTOS')),
        @P INT, @Q INT, @E INT, @ANC NVARCHAR(400), @BLK NVARCHAR(MAX), @OK BIT = 1;

IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER')),N'') NOT LIKE N'%VCT_PROYECTO_ALTA_RENDER_V2%'
BEGIN PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_RENDER V2 no se creo: revisar el error del bloque 2.'; SET @OK = 0; END;
IF @OK = 1 AND @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_PROYECTOS.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%PROYECTO_ALTA_FORM_V2%' BEGIN PRINT 'OK   VCT_MAIN_PROYECTOS ya tenia el alta V2.'; SET @OK = 0; END;

SET @BLK = N'/* PROYECTO_ALTA_FORM_V2: alta en el formulario unico de pantalla completa (dbo.VCT_PROYECTO_ALTA_RENDER, el mismo
           que usa la Vista 360 de Cliente). Permiso = accion CREATE ya resuelta en @BTN_NUEVO
           (dbo.VCT_MAIN_GET_ACTIONS). El boton Nuevo muestra el formulario sin ir al servidor. */
        DECLARE @ALTA_ERR VARCHAR(1000) = '''', @ALTA_MSG VARCHAR(1000) = '''', @ALTA_ID INT = NULL,
                @ALTA_HTML VARCHAR(MAX) = '''', @ALTA_OK VARCHAR(MAX) = '''', @ALTA_VER VARCHAR(MAX) = '''';
        IF @BTN_NUEVO <> ''''
        BEGIN
            SET @BTN_NUEVO = ''<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-proy-alta-open data-vct-tooltip="Nuevo proyecto">''
                           + ''<span data-vct-icon="plus"></span><span>Nuevo</span></button>'';

            IF @B_CMD = ''PRY_ALTA_GUARDAR''
            BEGIN
                UPDATE dbo.VCT_BUFFER SET TEXTO30 = NULL WHERE PAR_KEY = @IPKEYJOB;
                /* CAMBIO 2 reemplaza esta linea por EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR */
                SET @ALTA_ERR = ''Formulario OK. Todavia no graba: el guardado se instala en el cambio 2.'';
            END;

            EXEC dbo.VCT_PROYECTO_ALTA_RENDER @IPKEYJOB = @IPKEYJOB, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,
                 @ID_CLIENTE = NULL, @ORIGEN = ''PROYECTOS'', @ERROR = @ALTA_ERR, @HTML = @ALTA_HTML OUTPUT;

            IF ISNULL(@ALTA_HTML,'''') <> ''''
                SET @ALTA_HTML = ''<link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script>''
                               + ''<link rel="stylesheet" href="../css/vct-proyecto-alta.css?v=3"><script src="../js/vct-proyecto-alta.js?v=3"></script>''
                               + @ALTA_HTML;

            /* alta OK (cambio 2): aviso arriba de la grilla + Ver proyecto (accion VIEW) */
            IF ISNULL(@ALTA_MSG,'''') <> ''''
            BEGIN
                SELECT TOP 1 @ALTA_VER = dbo.VCT_MAIN_RENDER_ACTION(A.ACTION_ID, A.TITLE, A.ICON, A.STORAGE_KEY, A.TARGET_TAB, A.TARGET_GUID,
                                                                    CONVERT(VARCHAR(20), @ALTA_ID), ''vct-btn vct-btn-secondary vct-btn-sm'', ''Ver proyecto'')
                FROM #ACT A WHERE A.ACTION_TYPE = ''VIEW'' ORDER BY A.SORT_ORDER, A.ID_PRM;
                SET @ALTA_OK = ''<div class="vct-card" style="display:flex;align-items:center;gap:12px;padding:12px 16px;margin:0 0 14px;border-left:3px solid #059669;">''
                             + ''<span data-vct-icon="check" style="color:#059669"></span><span style="flex:1;font-size:12px">''
                             + REPLACE(REPLACE(ISNULL(@ALTA_MSG,''''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' + ISNULL(@ALTA_VER,'''') + ''</div>'';
            END;
        END;';

IF @OK = 1
BEGIN
    /* CREATE PROCEDURE -> ALTER PROCEDURE (primer CREATE seguido de PROC) */
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P = 0 BEGIN PRINT 'FALLO no se encontro CREATE PROCEDURE en la definicion.'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, 6, N'ALTER');

    IF @OK = 0 SET @D = @D;
    ELSE IF @D LIKE N'%PROYECTO_ALTA_FORM_V1%'
    BEGIN
        SET @P = CHARINDEX(N'/* PROYECTO_ALTA_FORM_V1', @D);
        SET @Q = CHARINDEX(N'+ ISNULL(@ALTA_VER,'''') + ''</div>'';', @D, @P);
        SET @E = CASE WHEN @Q > 0 THEN CHARINDEX(N'END;', @D, @Q) ELSE 0 END;
        IF @P = 0 OR @Q = 0 OR @E = 0 OR @E - @Q > 80
        BEGIN PRINT 'FALLO no se encontro el fin del bloque V1 en VCT_MAIN_PROYECTOS.'; SET @OK = 0; END
        ELSE SET @D = STUFF(@D, @P, @E + LEN(N'END;') - @P, @BLK);

        SET @ANC = N'+ ISNULL(@ALTA_OK,'''') + @KPIS';
        SET @P = CHARINDEX(@ANC, @D);
        IF @OK = 1 AND @P = 0 BEGIN PRINT 'FALLO ancla no encontrada: ' + @ANC; SET @OK = 0; END
        ELSE IF @OK = 1 SET @D = STUFF(@D, @P, LEN(@ANC), N'+ ISNULL(@ALTA_OK,'''') + ISNULL(@ALTA_HTML,'''') + @KPIS');
    END
    ELSE
    BEGIN
        SET @ANC = N'SET @BTN_NUEVO = ISNULL(@BTN_NUEVO,'''');';
        SET @P = CHARINDEX(@ANC, @D);
        IF @P = 0 BEGIN PRINT 'FALLO ancla no encontrada: ' + @ANC; SET @OK = 0; END
        ELSE SET @D = STUFF(@D, @P + LEN(@ANC), 0, NCHAR(13) + NCHAR(10) + N'        ' + @BLK);

        SET @ANC = N'+ @KPIS';
        SET @P = CHARINDEX(@ANC, @D);
        IF @OK = 1 AND @P = 0 BEGIN PRINT 'FALLO ancla no encontrada: ' + @ANC; SET @OK = 0; END
        ELSE IF @OK = 1 SET @D = STUFF(@D, @P, LEN(@ANC), N'+ ISNULL(@ALTA_OK,'''') + ISNULL(@ALTA_HTML,'''') + @KPIS');
    END;
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_PROYECTOS: boton Nuevo muestra el formulario (PROYECTO_ALTA_FORM_V2).';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_PROYECTOS: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

/* ========================================================================
   4. Parche de dbo.VCT_MAIN_CLIENTES_V360 (sobre la definicion vigente)
      - alta vieja (ALTA_PROYECTO_V1) -> EXEC dbo.VCT_PROYECTO_ALTA_RENDER
      - guardado: por ahora solo avisa "Todavia no graba" (cambio 2)
      - assets: vct-proyecto-alta v3
   ======================================================================== */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_CLIENTES_V360')),
        @P INT, @Q INT, @ANC NVARCHAR(400), @OK BIT = 1,
        @SAVE NVARCHAR(MAX) = N'/* CAMBIO 2 reemplaza esta linea por EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR (ALTA_PROYECTO_V2) */
                SET @PROY_ALTA_ERR=''Formulario OK. Todavia no graba: el guardado se instala en el cambio 2.'';',
        @MODAL NVARCHAR(MAX) = N'DECLARE @HTML_MODAL_PROY VARCHAR(MAX)='''', @PROY_ERR_V2 VARCHAR(1000)='''';
    /* ALTA_PROYECTO_V2: el formulario lo arma dbo.VCT_PROYECTO_ALTA_RENDER (el mismo que Proyectos),
       con el cliente fijo. Permiso: accion CREATE de PROYECTOS (VCT_MAIN_GET_ACTIONS, dentro del SP). */
    IF @VFORM_ENTITY=''PROYECTO'' SET @PROY_ERR_V2=LEFT(ISNULL(@VFORM_ERROR,''''),1000);
    EXEC dbo.VCT_PROYECTO_ALTA_RENDER
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE,
         @ID_CLIENTE=@ID_CLIENTE, @ORIGEN=''CLIENTE_V360'', @ERROR=@PROY_ERR_V2,
         @HTML=@HTML_MODAL_PROY OUTPUT;

    
';

IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER')),N'') NOT LIKE N'%VCT_PROYECTO_ALTA_RENDER_V2%'
BEGIN PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_RENDER V2 no se creo: revisar el error del bloque 2.'; SET @OK = 0; END;
IF @OK = 1 AND @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_CLIENTES_V360.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%ALTA_PROYECTO_V2%' BEGIN PRINT 'OK   VCT_MAIN_CLIENTES_V360 ya tenia el alta V2.'; SET @OK = 0; END;
IF @OK = 1 AND @D NOT LIKE N'%ALTA_PROYECTO_V1%' BEGIN PRINT 'FALLO VCT_MAIN_CLIENTES_V360 no tiene el alta V1 (modal viejo). No se aplico nada.'; SET @OK = 0; END;

IF @OK = 1
BEGIN
    /* a. guardado */
    SET @ANC = N'EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR';
    SET @P = CHARINDEX(@ANC, @D);
    SET @Q = CASE WHEN @P > 0 THEN CHARINDEX(N'@MENSAJE=@PROY_ALTA_MSG OUTPUT;', @D, @P) ELSE 0 END;
    IF @P = 0 OR @Q = 0 OR @Q - @P > 600 BEGIN PRINT 'FALLO ancla no encontrada: ' + @ANC; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, @Q + LEN(N'@MENSAJE=@PROY_ALTA_MSG OUTPUT;') - @P, @SAVE);
END;

IF @OK = 1
BEGIN
    /* b. modal */
    SET @ANC = N'DECLARE @HTML_MODAL_PROY VARCHAR(MAX)='''';';
    SET @P = CHARINDEX(@ANC, @D);
    SET @Q = CASE WHEN @P > 0 THEN CHARINDEX(N'/* Aviso de alta OK', @D, @P) ELSE 0 END;
    IF @P = 0 OR @Q = 0 BEGIN PRINT 'FALLO ancla no encontrada: ' + @ANC + ' ... /* Aviso de alta OK'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, @Q - @P, @MODAL);
END;

IF @OK = 1
BEGIN
    /* c. assets v3 */
    SET @D = REPLACE(@D, N'vct-proyecto-alta.css?v=1"', N'vct-proyecto-alta.css?v=3"');
    SET @D = REPLACE(@D, N'vct-proyecto-alta.css?v=2"', N'vct-proyecto-alta.css?v=3"');
    SET @D = REPLACE(@D, N'vct-proyecto-alta.js?v=1"', N'vct-proyecto-alta.js?v=3"');
    SET @D = REPLACE(@D, N'vct-proyecto-alta.js?v=2"', N'vct-proyecto-alta.js?v=3"');
    IF CHARINDEX(N'vct-proyecto-alta.js?v=3"', @D) = 0
    BEGIN PRINT 'FALLO no se encontro el script vct-proyecto-alta.js en VCT_MAIN_CLIENTES_V360.'; SET @OK = 0; END;

    /* CREATE PROCEDURE -> ALTER PROCEDURE (primer CREATE seguido de PROC) */
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P = 0 BEGIN PRINT 'FALLO no se encontro CREATE PROCEDURE en la definicion.'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, 6, N'ALTER');
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_CLIENTES_V360: Nuevo proyecto usa el formulario unico (ALTA_PROYECTO_V2).';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_CLIENTES_V360: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

/* ========================================================================
   5. Resumen + trigger
   ======================================================================== */
IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER')),N'') LIKE N'%VCT_PROYECTO_ALTA_RENDER_V2%'
    PRINT 'OK   dbo.VCT_PROYECTO_ALTA_RENDER V2 instalado.';
ELSE
    PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_RENDER V2 no esta instalado.';

IF EXISTS (SELECT 1 FROM #C1_RUN WHERE TRG_ON = 1)
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
