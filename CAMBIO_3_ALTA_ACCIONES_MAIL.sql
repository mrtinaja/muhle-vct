/* ========================================================================
   CAMBIO 3 - ALTA DE PROYECTO: ACCIONES Y MAIL AL ANALISTA
   ------------------------------------------------------------------------
   Requiere CAMBIO_2_ALTA_GRABAR.sql ya aplicado.
     1. Datos de VCT_PRM_ACCIONES_REGLAS (las 2 reglas del evento ANALISTA_ASIGNADO):
        - DESTINATARIO_ROL 'ANALISTA_PROYECTO' -> 'ANALISTA' (es el CODIGO de
          VCT_PRM_PROYECTOS_ROLES; el valor anterior no existe ahi).
        - PROY_ANALISTA_ASIGNAR_CONSULTORES: GENERA_EMAIL = 1 con la plantilla
          PROYECTO_ANALISTA_ASIGNADO.
     2. dbo.VCT_PROYECTO_ALTA_GUARDAR (se modifica): al grabar el alta crea las
        acciones de esas reglas (VCT_ACCIONES + PARTICIPANTES + HISTORIAL) con el
        analista como RESPONSABLE, y manda el mail de la regla.
   No crea tablas, vistas, funciones ni SPs. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#C3_RUN') IS NOT NULL DROP TABLE #C3_RUN;
CREATE TABLE #C3_RUN (TRG_ON BIT);
INSERT INTO #C3_RUN VALUES (0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #C3_RUN SET TRG_ON = 1;
END;
GO

/* ========================================================================
   1. Reglas del evento ANALISTA_ASIGNADO
   ======================================================================== */
BEGIN TRY
    UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
       SET DESTINATARIO_ROL = 'ANALISTA', FECHA_UPD = GETDATE(), USUARIO_UPD = 'CAMBIO_3'
     WHERE CODIGO IN ('PROY_ANALISTA_ASIGNADO_REGISTRO', 'PROY_ANALISTA_ASIGNAR_CONSULTORES')
       AND DESTINATARIO_ROL = 'ANALISTA_PROYECTO';
    PRINT 'OK   reglas: DESTINATARIO_ROL = ANALISTA (' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' filas).';

    DECLARE @TPL INT = (SELECT ID FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE CODIGO = 'PROYECTO_ANALISTA_ASIGNADO');
    IF @TPL IS NULL
        PRINT 'FALLO no existe la plantilla PROYECTO_ANALISTA_ASIGNADO en VCT_PRM_EMAIL_TEMPLATES.';
    ELSE
    BEGIN
        UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
           SET GENERA_EMAIL = 1, ID_EMAIL_TEMPLATE = @TPL, FECHA_UPD = GETDATE(), USUARIO_UPD = 'CAMBIO_3'
         WHERE CODIGO = 'PROY_ANALISTA_ASIGNAR_CONSULTORES'
           AND (GENERA_EMAIL = 0 OR ID_EMAIL_TEMPLATE IS NULL);
        PRINT 'OK   regla PROY_ANALISTA_ASIGNAR_CONSULTORES: mail con PROYECTO_ANALISTA_ASIGNADO (' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' filas).';
    END;
END TRY
BEGIN CATCH
    PRINT 'FALLO reglas: ' + ERROR_MESSAGE();
END CATCH;
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
    /* VCT_PROYECTO_ALTA_GUARDAR_V1 - V2: acciones y mail */
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

    /* ---------- 5. normas: id,id,... (obligatorias si hay consultoria) ---------- */
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
       AND EXISTS (SELECT 1 FROM @SRV S JOIN dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) ON P.ID = S.ID_SERVICIO
                   WHERE UPPER(ISNULL(P.CODIGO,'')) = 'CONSULTORIA')
    BEGIN SET @ERROR = 'Con consultoria hay que elegir al menos una norma.'; RETURN; END;

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

            UPDATE @PV SET ASUNTO = REPLACE(ASUNTO, '{{CODIGO_PROYECTO}}', @COD),
                           HTML_CONTENIDO = REPLACE(HTML_CONTENIDO, '{{CODIGO_PROYECTO}}', @COD);

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


/* ========================================================================
   3. Resumen + trigger
   ======================================================================== */
IF ISNULL(OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_GUARDAR')),N'') LIKE N'%V2: acciones y mail%'
    PRINT 'OK   dbo.VCT_PROYECTO_ALTA_GUARDAR con acciones y mail.';
ELSE
    PRINT 'FALLO dbo.VCT_PROYECTO_ALTA_GUARDAR no se actualizo.';

SELECT R.CODIGO, R.ID_TIPO, R.ID_SUBTIPO, R.ID_ESTADO_INICIAL, R.DESTINATARIO_ROL, R.DIAS_VENCIMIENTO, R.GENERA_EMAIL, T.CODIGO AS PLANTILLA
FROM dbo.VCT_PRM_ACCIONES_REGLAS R LEFT JOIN dbo.VCT_PRM_EMAIL_TEMPLATES T ON T.ID = R.ID_EMAIL_TEMPLATE
WHERE R.CODIGO_EVENTO = 'ANALISTA_ASIGNADO';

IF EXISTS (SELECT 1 FROM #C3_RUN WHERE TRG_ON = 1)
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
