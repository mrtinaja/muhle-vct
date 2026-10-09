/* ========================================================================
   PROYECTO_ALTA_4_MAIL_SEND_EMAIL
   ------------------------------------------------------------------------
   VCT_PROYECTO_ALTA_GUARDAR pasa a resolver el mail con dbo.VCT_MAIN_SEND_EMAIL
   (modo preview: template, destinatario, CC y variables estandar). El SP del
   alta completa {{CODIGO_PROYECTO}}, {{SERVICIOS}}, {{NORMAS}} y
   {{FECHA_LANZAMIENTO}} y envia con sp_send_dbmail (VocaturoProfile).
   Modo prueba: el template queda con destino fijo martin.aja@squad.com.ar y
   e.de.marco@squad.com.ar.
   Resto del SP: sin cambios.
   ======================================================================== */
USE [MuhlePROD];
GO

/* ---- MODO PRUEBA: el mail del alta va SOLO a esta casilla, no al analista ----
   Para pasar a produccion: Configuracion > Templates de email >
   PROYECTO_ANALISTA_ASIGNADO > Destino = Analista. */
UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
   SET DESTINO_TIPO = 'LIBRE',
       DESTINO_LIBRE = 'martin.aja@squad.com.ar;e.de.marco@squad.com.ar',
       CC_TIPO = 'NINGUNO',
       CC_LIBRE = NULL,
       /* VCT_MAIN_SEND_EMAIL deja {{NOMBRE}} vacio cuando el destino es LIBRE */
       HTML_CONTENIDO = REPLACE(HTML_CONTENIDO, 'Hola {{NOMBRE}},', 'Hola {{ANALISTA}},'),
       FECHA_UPD = GETDATE(),
       USUARIO_UPD = 'PROYECTO_ALTA'
 WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_ANALISTA_ASIGNADO';
PRINT 'Template PROYECTO_ANALISTA_ASIGNADO en modo prueba: destino martin.aja@squad.com.ar y e.de.marco@squad.com.ar.';
GO
/* ---------------- 3. SP de guardado ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_GUARDAR
(
    @IPKEYJOB    VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @ID_CLIENTE  INT,
    @ERROR       VARCHAR(1000) OUTPUT,
    @MENSAJE     VARCHAR(1000) OUTPUT
)
AS
BEGIN
    /* ============================================================
       Lee el formulario "Nuevo proyecto" de VCT_BUFFER:
         TEXTO11 nombre            TEXTO20 analista (VCT_EMPLEADOS.ID)
         TEXTO13 fecha inicio      TEXTO21 fecha limite lanzamiento
         TEXTO14 fecha fin         TEXTO22 servicios (ids separados por coma)
         TEXTO15 horas contratadas TEXTO24 normas (ids separados por coma)
         TEXTO17 contacto          TEXTO25 rentabilidad (6 valores con |)
         TEXTO18 nivel de riesgo   TEXTO26 comentario de rentabilidad
       Fechas yyyy-mm-dd y montos con punto decimal (los normaliza el JS).
       No devuelve result sets: solo @ERROR (vacio = OK) y @MENSAJE.
       ============================================================ */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ERROR = '';
    SET @MENSAJE = '';

    DECLARE
        @T11 VARCHAR(4000), @T13 VARCHAR(4000), @T14 VARCHAR(4000), @T15 VARCHAR(4000),
        @T17 VARCHAR(4000), @T18 VARCHAR(4000), @T20 VARCHAR(4000), @T21 VARCHAR(4000),
        @T22 VARCHAR(4000), @T24 VARCHAR(4000), @T25 VARCHAR(4000), @T26 VARCHAR(4000);

    SELECT TOP 1
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))),
        @T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))),
        @T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))), @T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))),
        @T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))), @T21 = LTRIM(RTRIM(ISNULL(TEXTO21,''))),
        @T22 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO22,''))),' ',''),
        @T24 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO24,''))),' ',''), @T25 = LTRIM(RTRIM(ISNULL(TEXTO25,''))),
        @T26 = LTRIM(RTRIM(ISNULL(TEXTO26,'')))
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    /* ---------- permiso y cliente ---------- */
    IF dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PROYECTOS.CREATE') = 0
    BEGIN
        SET @ERROR = 'No posee permisos para dar de alta proyectos.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @ID_CLIENTE)
    BEGIN
        SET @ERROR = 'No se encontro el cliente seleccionado.';
        RETURN;
    END;

    /* ---------- obligatorios ---------- */
    IF @T11 = ''
        SET @ERROR = 'El nombre del proyecto es obligatorio.';
    ELSE IF LEN(@T11) > 300
        SET @ERROR = 'El nombre del proyecto no puede superar los 300 caracteres.';
    ELSE IF @T22 = '' OR PATINDEX('%[^0-9,]%', @T22) > 0
        SET @ERROR = 'Seleccione al menos un servicio.';
    ELSE IF @T24 = '' OR PATINDEX('%[^0-9,]%', @T24) > 0
        SET @ERROR = 'Seleccione al menos una norma.';
    IF @ERROR <> '' RETURN;

    /* ---------- listas de ids ---------- */
    DECLARE @SERV TABLE (ORDEN INT IDENTITY(1,1), ID INT);
    DECLARE @NORM TABLE (ORDEN INT IDENTITY(1,1), ID INT);
    DECLARE @X XML;

    SET @X = CAST('<i>' + REPLACE(@T22, ',', '</i><i>') + '</i>' AS XML);
    INSERT INTO @SERV (ID)
    SELECT DISTINCT CONVERT(INT, V)
    FROM (SELECT N.value('.','VARCHAR(20)') AS V FROM @X.nodes('/i') T(N)) Z
    WHERE V <> '' AND LEN(V) <= 9;

    SET @X = CAST('<i>' + REPLACE(@T24, ',', '</i><i>') + '</i>' AS XML);
    INSERT INTO @NORM (ID)
    SELECT DISTINCT CONVERT(INT, V)
    FROM (SELECT N.value('.','VARCHAR(20)') AS V FROM @X.nodes('/i') T(N)) Z
    WHERE V <> '' AND LEN(V) <= 9;

    IF NOT EXISTS (SELECT 1 FROM @SERV)
        SET @ERROR = 'Seleccione al menos un servicio.';
    ELSE IF EXISTS (SELECT 1 FROM @SERV S WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) WHERE P.ID = S.ID AND ISNULL(P.ESTADO,'ACTIVO') = 'ACTIVO'))
        SET @ERROR = 'Alguno de los servicios seleccionados no existe o esta inactivo.';
    ELSE IF NOT EXISTS (SELECT 1 FROM @NORM)
        SET @ERROR = 'Seleccione al menos una norma.';
    ELSE IF EXISTS (SELECT 1 FROM @NORM S WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_NORMAS P WITH(NOLOCK) WHERE P.ID = S.ID AND ISNULL(P.ESTADO,'ACTIVO') = 'ACTIVO'))
        SET @ERROR = 'Alguna de las normas seleccionadas no existe o esta inactiva.';
    IF @ERROR <> '' RETURN;

    /* ---------- fechas ---------- */
    DECLARE @F_INI DATETIME = NULL, @F_FIN DATETIME = NULL, @F_LANZ DATETIME = NULL;

    IF @T13 <> ''
    BEGIN
        IF @T13 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T13,'-','')) = 0
            SET @ERROR = 'La fecha de inicio no es valida.';
        ELSE SET @F_INI = CONVERT(DATETIME, REPLACE(@T13,'-',''), 112);
    END;
    IF @ERROR = '' AND @T14 <> ''
    BEGIN
        IF @T14 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T14,'-','')) = 0
            SET @ERROR = 'La fecha de fin no es valida.';
        ELSE SET @F_FIN = CONVERT(DATETIME, REPLACE(@T14,'-',''), 112);
    END;
    IF @ERROR = '' AND @T21 <> ''
    BEGIN
        IF @T21 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T21,'-','')) = 0
            SET @ERROR = 'La fecha limite de lanzamiento no es valida.';
        ELSE SET @F_LANZ = CONVERT(DATETIME, REPLACE(@T21,'-',''), 112);
    END;
    IF @ERROR = '' AND @F_INI IS NOT NULL AND @F_FIN IS NOT NULL AND @F_FIN < @F_INI
        SET @ERROR = 'La fecha de fin no puede ser anterior a la de inicio.';
    IF @ERROR <> '' RETURN;

    /* ---------- horas ---------- */
    DECLARE @HORAS INT = NULL;
    IF @T15 <> ''
    BEGIN
        IF PATINDEX('%[^0-9]%', @T15) > 0 OR LEN(@T15) > 6 SET @ERROR = 'Las horas contratadas deben ser un numero entero.';
        ELSE SET @HORAS = CONVERT(INT, @T15);
    END;
    IF @ERROR <> '' RETURN;

    /* ---------- contacto / riesgo ---------- */
    DECLARE @ID_CONTACTO INT = NULL, @RIESGO VARCHAR(50) = NULL;

    IF @T17 <> ''
    BEGIN
        IF PATINDEX('%[^0-9]%', @T17) > 0 OR LEN(@T17) > 9
           OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CONTACTOS WITH(NOLOCK) WHERE CONVERT(VARCHAR(20),ID) = @T17 AND IDCLIENTE = @ID_CLIENTE)
            SET @ERROR = 'Seleccione un contacto del cliente.';
        ELSE SET @ID_CONTACTO = CONVERT(INT, @T17);
    END;
    IF @ERROR = '' AND @T18 <> ''
    BEGIN
        IF @T18 NOT IN ('Bajo','Medio','Alto') SET @ERROR = 'Seleccione un nivel de riesgo valido.';
        ELSE SET @RIESGO = @T18;
    END;
    IF @ERROR <> '' RETURN;

    /* ---------- analista ---------- */
    DECLARE @ID_ANALISTA INT = NULL, @ID_ROL_ANALISTA INT = NULL;
    SELECT TOP 1 @ID_ROL_ANALISTA = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE CODIGO = 'ANALISTA';

    IF @T20 <> ''
    BEGIN
        IF PATINDEX('%[^0-9]%', @T20) > 0 OR LEN(@T20) > 9
           OR NOT EXISTS (SELECT 1 FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE CONVERT(VARCHAR(20),ID) = @T20 AND ISNULL(ESTADO,'ACTIVO') = 'ACTIVO')
            SET @ERROR = 'Seleccione un analista activo.';
        ELSE IF @ID_ROL_ANALISTA IS NULL
            SET @ERROR = 'No existe el rol ANALISTA en la parametria de proyectos.';
        ELSE IF @F_LANZ IS NULL
            SET @ERROR = 'Indique la fecha limite de lanzamiento (vencimiento de la gestion del analista).';
        ELSE IF @F_LANZ < CONVERT(DATE, GETDATE())
            SET @ERROR = 'La fecha limite de lanzamiento no puede ser anterior a hoy.';
        ELSE SET @ID_ANALISTA = CONVERT(INT, @T20);
    END;
    IF @ERROR <> '' RETURN;

    /* ---------- rentabilidad estimada (opcional) ----------
       TEXTO25 = montoPres|montoViat|fechaPresupuesto|costoMO|costoViat|costoVarios */
    DECLARE @R TABLE (POS INT, V VARCHAR(100));
    DECLARE @RS VARCHAR(4000) = @T25 + '|', @RP INT, @RI INT = 1;
    WHILE @RI <= 6 AND LEN(@RS) > 0
    BEGIN
        SET @RP = CHARINDEX('|', @RS);
        IF @RP = 0 BREAK;
        INSERT INTO @R VALUES (@RI, LTRIM(RTRIM(LEFT(@RS, @RP - 1))));
        SET @RS = SUBSTRING(@RS, @RP + 1, 4000);
        SET @RI = @RI + 1;
    END;

    IF EXISTS (SELECT 1 FROM @R WHERE POS <> 3 AND V <> ''
               AND (PATINDEX('%[^0-9.]%', V) > 0 OR V = '.' OR LEN(V) - LEN(REPLACE(V,'.','')) > 1 OR LEN(V) > 13))
    BEGIN
        SET @ERROR = 'Los importes de rentabilidad deben ser numericos.';
        RETURN;
    END;

    DECLARE
        @M_PRES NUMERIC(15,2) = (SELECT CONVERT(NUMERIC(15,2), NULLIF(V,'')) FROM @R WHERE POS = 1),
        @M_VIAT NUMERIC(15,2) = (SELECT CONVERT(NUMERIC(15,2), NULLIF(V,'')) FROM @R WHERE POS = 2),
        @C_MO   NUMERIC(15,2) = (SELECT CONVERT(NUMERIC(15,2), NULLIF(V,'')) FROM @R WHERE POS = 4),
        @C_VIAT NUMERIC(15,2) = (SELECT CONVERT(NUMERIC(15,2), NULLIF(V,'')) FROM @R WHERE POS = 5),
        @C_VAR  NUMERIC(15,2) = (SELECT CONVERT(NUMERIC(15,2), NULLIF(V,'')) FROM @R WHERE POS = 6),
        @F_PRES DATETIME = NULL,
        @FPS VARCHAR(100) = ISNULL((SELECT V FROM @R WHERE POS = 3),'');

    IF @FPS <> ''
    BEGIN
        IF @FPS NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@FPS,'-','')) = 0
        BEGIN
            SET @ERROR = 'La fecha del presupuesto no es valida.';
            RETURN;
        END;
        SET @F_PRES = CONVERT(DATETIME, REPLACE(@FPS,'-',''), 112);
    END;

    DECLARE @M_TOTAL NUMERIC(15,2) = CASE WHEN @M_PRES IS NULL AND @M_VIAT IS NULL THEN NULL ELSE ISNULL(@M_PRES,0) + ISNULL(@M_VIAT,0) END;
    DECLARE @C_TOTAL NUMERIC(15,2) = CASE WHEN @C_MO IS NULL AND @C_VIAT IS NULL AND @C_VAR IS NULL THEN NULL ELSE ISNULL(@C_MO,0) + ISNULL(@C_VIAT,0) + ISNULL(@C_VAR,0) END;

    /* ---------- doble clic: mismo nombre y cliente en el ultimo minuto ---------- */
    IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS WITH(NOLOCK)
               WHERE IDCLIENTE = @ID_CLIENTE AND NOMBRE = @T11 AND FECHA_ALTA >= DATEADD(SECOND,-60,GETDATE()))
    BEGIN
        SET @ERROR = 'Ese proyecto ya se acaba de dar de alta para este cliente.';
        RETURN;
    END;

    /* ---------- estados / tipos por codigo ---------- */
    DECLARE
        @ID_EST_PROY INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CONFIRMADO'),
        @G_TIPO      INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WITH(NOLOCK) WHERE CODIGO = 'ASIGNACION'),
        @G_SUBTIPO   INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'ASIGNACION_ANALISTA'),
        @G_ESTADO    INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE'),
        @G_PRIOR     INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK) WHERE CODIGO = 'NORMAL');

    IF @ID_EST_PROY IS NULL
    BEGIN
        SET @ERROR = 'No existe el estado de proyecto CONFIRMADO en la parametria.';
        RETURN;
    END;
    IF @ID_ANALISTA IS NOT NULL AND (@G_TIPO IS NULL OR @G_ESTADO IS NULL OR @G_PRIOR IS NULL)
    BEGIN
        SET @ERROR = 'Falta parametria de gestiones (tipo ASIGNACION, estado PENDIENTE o prioridad NORMAL).';
        RETURN;
    END;

    /* ---------- grabacion ---------- */
    DECLARE @ID_PROYECTO INT, @CODIGO VARCHAR(100), @NEXT INT, @ID_GESTION INT = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* codigo correlativo (numerico) de VCT_PROYECTOS */
        EXEC sp_getapplock @Resource = 'VCT_PROYECTO_CODIGO', @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;

        SELECT @NEXT = MAX(N)
        FROM
        (
            SELECT CASE WHEN CODIGO NOT LIKE '%[^0-9]%' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT, CODIGO) END AS N
            FROM dbo.VCT_PROYECTOS WITH(NOLOCK)
        ) X;
        SET @CODIGO = CONVERT(VARCHAR(100), ISNULL(@NEXT, 0) + 1);

        INSERT INTO dbo.VCT_PROYECTOS
        (
            IDCLIENTE, CODIGO, NOMBRE, REFERENCIA, ID_ESTADO,
            FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE, MONEDA,
            MONTO_PRES, MONTO_PRES_VIAT, COSTO_MO, COSTO_VIAT, COSTO_VARIOS,
            MONTO_TOTAL, COSTO_TOTAL, OBSERV_RENTA, FECHA_PRESUPUESTO,
            FECHA_ALTA, USUARIO_ALTA, TOTAL_HORAS_PROYECTADAS,
            NIVEL_RIESGO, IDCONTACTO
        )
        VALUES
        (
            @ID_CLIENTE, @CODIGO, @T11, NULL, @ID_EST_PROY,
            @F_INI, @F_FIN, 0, 'ARS',
            @M_PRES, @M_VIAT, @C_MO, @C_VIAT, @C_VAR,
            @M_TOTAL, @C_TOTAL, NULLIF(@T26,''), @F_PRES,
            GETDATE(), @IAGENTE, @HORAS,
            @RIESGO, @ID_CONTACTO
        );
        SET @ID_PROYECTO = SCOPE_IDENTITY();

        INSERT INTO dbo.VCT_PROYECTOS_SERVICIOS
            (ID_PROYECTO, ID_SERVICIO, ID_ESTADO, PRINCIPAL, ORDEN, FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE, FECHA_ALTA, USUARIO_ALTA, SECUENCIA)
        SELECT @ID_PROYECTO, S.ID, @ID_EST_PROY, CASE WHEN S.ORDEN = 1 THEN 1 ELSE 0 END, S.ORDEN, @F_INI, @F_FIN, 0, GETDATE(), @IAGENTE, S.ORDEN
        FROM @SERV S;

        INSERT INTO dbo.VCT_PROYECTOS_NORMAS
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, ID_NORMA, PRINCIPAL, OBLIGATORIA, ESTADO, FECHA_ALTA, USUARIO_ALTA)
        SELECT @ID_PROYECTO, NULL, N.ID, CASE WHEN N.ORDEN = 1 THEN 1 ELSE 0 END, 1, 'ACTIVA', GETDATE(), @IAGENTE
        FROM @NORM N;

        IF @ID_ANALISTA IS NOT NULL
        BEGIN
            INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
                (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL, FECHA_DESDE, ESTADO, FECHA_ALTA, USUARIO_ALTA)
            VALUES
                (@ID_PROYECTO, NULL, 'EMPLEADO', @ID_ANALISTA, NULL, @ID_ROL_ANALISTA, 1, GETDATE(), 'ACTIVO', GETDATE(), @IAGENTE);

            /* Gestion "Organizar lanzamiento" (misma estructura que VCT_GESTION_CREAR,
               escrita directo para no devolver result sets a la pagina). */
            INSERT INTO dbo.VCT_GESTIONES
            (
                CODIGO, ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO,
                TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                REQUIERE_RESPUESTA, REQUIERE_APROBACION,
                FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO,
                FECHA_ALTA, USUARIO_ALTA
            )
            VALUES
            (
                NULL, 'AUTOMATICA', @G_TIPO, @G_SUBTIPO, @G_ESTADO, @G_PRIOR, NULL,
                LEFT('Organizar lanzamiento - (' + @CODIGO + ') ' + @T11, 300),
                'Proyecto nuevo asignado. Antes de la fecha limite: asignar el/los consultores, '
                + 'completar los datos de entrada (riesgos iniciales, acciones y consideraciones) '
                + 'y hacer la reunion de lanzamiento con el consultor.',
                @ID_CLIENTE, @ID_PROYECTO,
                0, 0,
                GETDATE(), GETDATE(), @F_LANZ,
                GETDATE(), @IAGENTE
            );
            SET @ID_GESTION = SCOPE_IDENTITY();

            UPDATE dbo.VCT_GESTIONES
               SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_GESTION), 9)
             WHERE ID = @ID_GESTION;

            INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
            VALUES
                (@ID_GESTION, NULL, @G_ESTADO, NULL, 'CREACION', 'Creacion de gestion (alta de proyecto).', 'SISTEMA', NULL, GETDATE(), @IAGENTE);

            INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
            VALUES
                (@ID_GESTION, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE),
                (@ID_GESTION, 'RESPONSABLE', 'EMPLEADO', @ID_ANALISTA, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ERROR = 'No se pudo grabar el proyecto: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    SET @MENSAJE = LEFT('Proyecto (' + @CODIGO + ') ' + @T11 + ' creado.', 400);

    /* ---------- mail al analista (fuera de la transaccion: si falla, el alta queda) ---------- */
    IF @ID_ANALISTA IS NOT NULL
    BEGIN
        BEGIN TRY
            /* El template lo resuelve dbo.VCT_MAIN_SEND_EMAIL en modo preview (sin
               @PROFILE_NAME): destinatario, CC y variables estandar. Aca se completan
               las variables propias del alta y se envia. */
            DECLARE @M_ASUNTO VARCHAR(500), @M_BODY VARCHAR(MAX), @M_DEST VARCHAR(1000), @M_CC VARCHAR(1000),
                    @M_ESTADO VARCHAR(20) = NULL;

            SELECT TOP 1 @M_ESTADO = ESTADO
            FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_ANALISTA_ASIGNADO';

            IF @M_ESTADO IS NOT NULL
            BEGIN
                IF OBJECT_ID('tempdb..#MAIL') IS NOT NULL DROP TABLE #MAIL;
                CREATE TABLE #MAIL (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));

                INSERT INTO #MAIL
                EXEC dbo.VCT_MAIN_SEND_EMAIL
                     @CODIGO = 'PROYECTO_ANALISTA_ASIGNADO',
                     @ID_PROYECTO = @ID_PROYECTO,
                     @ID_ANALISTA = @ID_ANALISTA,
                     @ID_CLIENTE = @ID_CLIENTE;

                SELECT TOP 1 @M_ASUNTO = ASUNTO, @M_BODY = HTML_CONTENIDO, @M_DEST = DESTINATARIO, @M_CC = NULLIF(LTRIM(RTRIM(CC)),'') FROM #MAIL;
            END;

            /* si el empleado no tiene mail cargado, se usa el de su usuario */
            IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL
                SELECT TOP 1 @M_DEST = U.Email
                FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
                INNER JOIN dbo.Users U WITH(NOLOCK) ON UPPER(LTRIM(RTRIM(U.Id))) = UPPER(LTRIM(RTRIM(E.ID_USUARIO_SEGURIDAD)))
                WHERE E.ID = @ID_ANALISTA AND NULLIF(LTRIM(RTRIM(U.Email)),'') IS NOT NULL;

            DECLARE @L_SERV VARCHAR(1000) = '', @L_NORM VARCHAR(2000) = '';
            SELECT @L_SERV = @L_SERV + CASE WHEN @L_SERV = '' THEN '' ELSE ', ' END + P.DESCRIPCION
            FROM @SERV S INNER JOIN dbo.VCT_PRM_SERVICIOS P WITH(NOLOCK) ON P.ID = S.ID ORDER BY S.ORDEN;
            SELECT @L_NORM = @L_NORM + CASE WHEN @L_NORM = '' THEN '' ELSE ', ' END + P.DESCRIPCION
            FROM @NORM S INNER JOIN dbo.VCT_PRM_NORMAS P WITH(NOLOCK) ON P.ID = S.ID ORDER BY S.ORDEN;

            SET @M_ASUNTO = REPLACE(@M_ASUNTO, '{{CODIGO_PROYECTO}}', @CODIGO);
            SET @M_BODY = REPLACE(@M_BODY, '{{CODIGO_PROYECTO}}', @CODIGO);
            SET @M_BODY = REPLACE(@M_BODY, '{{SERVICIOS}}', REPLACE(REPLACE(@L_SERV,'<','&lt;'),'>','&gt;'));
            SET @M_BODY = REPLACE(@M_BODY, '{{NORMAS}}', REPLACE(REPLACE(@L_NORM,'<','&lt;'),'>','&gt;'));
            SET @M_BODY = REPLACE(@M_BODY, '{{FECHA_LANZAMIENTO}}', ISNULL(CONVERT(VARCHAR(10), @F_LANZ, 103),'-'));

            /* Si el template va a una casilla fija (LIBRE, ej. pruebas), {{NOMBRE}} y
               {{APELLIDO}} no los resuelve VCT_MAIN_SEND_EMAIL: se usan los del analista. */
            DECLARE @A_NOM VARCHAR(150) = '', @A_APE VARCHAR(150) = '';
            SELECT @A_NOM = ISNULL(NOMBRES,''), @A_APE = ISNULL(APELLIDOS,'') FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID = @ID_ANALISTA;
            SET @M_ASUNTO = REPLACE(REPLACE(@M_ASUNTO, '{{NOMBRE}}', @A_NOM), '{{APELLIDO}}', @A_APE);
            SET @M_BODY = REPLACE(REPLACE(@M_BODY, '{{NOMBRE}}', @A_NOM), '{{APELLIDO}}', @A_APE);

            IF @M_ASUNTO IS NULL OR ISNULL(@M_ESTADO,'ACTIVO') <> 'ACTIVO'
                SET @MENSAJE = @MENSAJE + ' Gestion creada para el analista; mail no enviado: el template PROYECTO_ANALISTA_ASIGNADO no existe o esta inactivo.';
            ELSE IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL AND @M_CC IS NULL
                SET @MENSAJE = @MENSAJE + ' Gestion creada para el analista, pero no se envio el mail: el analista no tiene email cargado.';
            ELSE
            BEGIN
                /* sin mail del analista pero con copia fija: se manda solo a la copia */
                IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL
                BEGIN
                    SET @M_DEST = @M_CC;
                    SET @M_CC = NULL;
                END;

                EXEC msdb.dbo.sp_send_dbmail
                     @profile_name    = 'VocaturoProfile',
                     @recipients      = @M_DEST,
                     @copy_recipients = @M_CC,
                     @subject         = @M_ASUNTO,
                     @body            = @M_BODY,
                     @body_format     = 'HTML';
                SET @MENSAJE = LEFT(@MENSAJE + ' Mail enviado a ' + @M_DEST + ISNULL(' (copia: ' + @M_CC + ')','') + '.', 1000);
            END;
        END TRY
        BEGIN CATCH
            SET @MENSAJE = LEFT(@MENSAJE + ' Gestion creada para el analista, pero el mail fallo: ' + ERROR_MESSAGE(), 1000);
        END CATCH;
    END;

    /* limpiar el formulario del buffer */
    UPDATE dbo.VCT_BUFFER
       SET TEXTO18 = NULL, TEXTO20 = NULL, TEXTO21 = NULL, TEXTO22 = NULL,
           TEXTO24 = NULL, TEXTO25 = NULL, TEXTO26 = NULL
     WHERE PAR_KEY = @IPKEYJOB;
END
GO

PRINT 'OK: VCT_PROYECTO_ALTA_GUARDAR usa VCT_MAIN_SEND_EMAIL.';
GO
