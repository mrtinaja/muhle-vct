 
/* ---------------- 5. grabar ---------------- */
CREATE   PROCEDURE dbo.VCT_PROYECTO_VISITA_ACCION
(
    @IPKEYJOB    VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @ID_PROYECTO INT,
    @MENSAJE     VARCHAR(1000) OUTPUT,
    @ERROR       VARCHAR(1000) OUTPUT
)
AS
BEGIN
    /* ============================================================
       Comando (VCT_BUFFER.TEXTO30, con FLAG01 = 1):
         VISITA_GUARDAR  IDSELEC03 = visita ('' = visita nueva, no agendada)
                         TEXTO11 fecha (yyyy-mm-dd), TEXTO12 desde (hh:mm),
                         TEXTO13 hasta (hh:mm), TEXTO21 horas (opcional: si
                         esta vacio salen del horario), TEXTO14 consultor (id),
                         TEXTO15 modalidad (Presencial / Remoto), TEXTO16 lugar,
                         TEXTO17 temas trabajados, TEXTO18 proximos temas,
                         TEXTO19 proximas acciones del cliente,
                         TEXTO20 SI = crear un pendiente del cliente con las
                         acciones (solo la primera vez que se registra).
       No devuelve result sets.
       ============================================================ */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @MENSAJE = '';
    SET @ERROR = '';
 
    DECLARE @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100),
            @T11 VARCHAR(4000), @T12 VARCHAR(4000), @T13 VARCHAR(4000), @T14 VARCHAR(4000), @T15 VARCHAR(4000),
            @T16 VARCHAR(4000), @T17 VARCHAR(4000), @T18 VARCHAR(4000), @T19 VARCHAR(4000), @T20 VARCHAR(4000),
            @T21 VARCHAR(4000);
 
    SELECT TOP 1
        @FLAG = ISNULL(FLAG01,''),
        @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @SEL3 = LTRIM(RTRIM(ISNULL(IDSELEC03,''))),
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))),
        @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))), @T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))),
        @T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))),
        @T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))), @T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))),
        @T19 = LTRIM(RTRIM(ISNULL(TEXTO19,''))), @T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))),
        @T21 = LTRIM(RTRIM(ISNULL(TEXTO21,'')))
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF CHARINDEX(',', @CMD) > 0 SET @CMD = LEFT(@CMD, CHARINDEX(',', @CMD) - 1);
    IF CHARINDEX(',', @SEL3) > 0 SET @SEL3 = LEFT(@SEL3, CHARINDEX(',', @SEL3) - 1);
    IF ISNULL(@FLAG,'') <> '1' OR @CMD NOT LIKE 'VISITA[_]%' RETURN;
 
    /* siempre se consume el comando, haya error o no */
    UPDATE dbo.VCT_BUFFER
       SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL,
           TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL,
           TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL, TEXTO21 = NULL
     WHERE PAR_KEY = @IPKEYJOB;
 
    IF dbo.VCT_PERFIL_PUEDE(@IUNIDAD, 'VISITA.EDIT') = 0
    BEGIN
        SET @ERROR = 'No posee permisos para registrar visitas.';
        RETURN;
    END;
 
    IF @CMD <> 'VISITA_GUARDAR'
    BEGIN
        SET @ERROR = 'Comando no reconocido.';
        RETURN;
    END;
 
    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT;
    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE
    FROM dbo.VCT_PROYECTOS P WHERE P.ID = @ID_PROYECTO;
    IF @NOMBRE IS NULL
    BEGIN
        SET @ERROR = 'No se encontro el proyecto.';
        RETURN;
    END;
 
    /* ---------- validaciones ---------- */
    DECLARE @F DATE, @HD TIME(0) = NULL, @HH TIME(0) = NULL, @HORAS DECIMAL(6,2) = NULL, @H_TXT DECIMAL(6,2) = NULL,
            @ID_CONS INT = NULL, @MOD VARCHAR(20) = NULL, @ID_VIS INT = NULL, @REG_ID INT = NULL, @V_OK BIT = 0;
 
    IF @T11 = '' OR @T11 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T11,'-','')) = 0
    BEGIN
        SET @ERROR = 'Indique la fecha de la visita.';
        RETURN;
    END;
    SET @F = CONVERT(DATE, REPLACE(@T11,'-',''), 112);
    IF @F > CONVERT(DATE, GETDATE())
    BEGIN
        SET @ERROR = 'La fecha no puede ser futura: la visita se registra cuando ya se hizo.';
        RETURN;
    END;
 
    IF (@T12 <> '' AND (@T12 NOT LIKE '[0-2][0-9]:[0-5][0-9]' OR LEFT(@T12,2) > '23'))
    OR (@T13 <> '' AND (@T13 NOT LIKE '[0-2][0-9]:[0-5][0-9]' OR LEFT(@T13,2) > '23'))
    BEGIN
        SET @ERROR = 'El horario no es valido (hh:mm).';
        RETURN;
    END;
    IF (@T12 = '' AND @T13 <> '') OR (@T12 <> '' AND @T13 = '')
    BEGIN
        SET @ERROR = 'Complete el horario: desde y hasta.';
        RETURN;
    END;
    IF @T12 <> '' SET @HD = CONVERT(TIME(0), @T12);
    IF @T13 <> '' SET @HH = CONVERT(TIME(0), @T13);
    IF @HD IS NOT NULL AND @HH IS NOT NULL AND @HH <= @HD
    BEGIN
        SET @ERROR = 'La hora "hasta" tiene que ser posterior a "desde".';
        RETURN;
    END;
 
    IF @T21 <> ''
    BEGIN
        /* sin TRY_CONVERT: la base corre en un nivel de compatibilidad viejo */
        SET @T21 = REPLACE(@T21, ',', '.');
        IF @T21 LIKE '%[^0-9.]%' OR @T21 LIKE '%.%.%' OR @T21 NOT LIKE '%[0-9]%' OR LEN(@T21) > 6
        BEGIN
            SET @ERROR = 'Las horas no son un numero valido.';
            RETURN;
        END;
        SET @H_TXT = CONVERT(DECIMAL(6,2), @T21);
        IF @H_TXT IS NULL
        BEGIN
            SET @ERROR = 'Las horas no son un numero valido.';
            RETURN;
        END;
    END;
    SET @HORAS = ISNULL(@H_TXT, CASE WHEN @HD IS NOT NULL AND @HH IS NOT NULL
                                     THEN CONVERT(DECIMAL(6,2), ROUND(DATEDIFF(MINUTE, @HD, @HH) / 60.0, 2)) END);
    IF @HORAS IS NULL OR @HORAS <= 0
    BEGIN
        SET @ERROR = 'Indique el horario (desde / hasta) o las horas de la visita.';
        RETURN;
    END;
    IF @HORAS > 200
    BEGIN
        SET @ERROR = 'Las horas de una visita no pueden superar 200.';
        RETURN;
    END;
 
    IF @T14 <> '' AND PATINDEX('%[^0-9]%', @T14) = 0 AND LEN(@T14) <= 9
        SELECT @ID_CONS = ID FROM dbo.VCT_CONSULTORES WHERE ID = CONVERT(INT, @T14);
    IF @ID_CONS IS NULL
    BEGIN
        SET @ERROR = 'Seleccione el consultor que hizo la visita.';
        RETURN;
    END;
 
    SET @MOD = CASE WHEN UPPER(@T15) LIKE 'PRESENCIAL%' THEN 'Presencial' WHEN UPPER(@T15) LIKE 'REMOTO%' THEN 'Remoto' ELSE NULL END;
 
    IF @T17 = ''
    BEGIN
        SET @ERROR = 'Escriba los temas trabajados en la visita.';
        RETURN;
    END;
 
    IF @SEL3 <> ''
    BEGIN
        IF PATINDEX('%[^0-9]%', @SEL3) = 0 AND LEN(@SEL3) <= 9
            SELECT @ID_VIS = V.ID, @REG_ID = R.ID, @V_OK = 1
            FROM dbo.VCT_PROYECTOS_VISITAS V
            LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_REGISTRO R ON R.ID_VISITA = V.ID
            WHERE V.ID = CONVERT(INT, @SEL3) AND V.ID_PROYECTO = @ID_PROYECTO;
        IF @V_OK = 0
        BEGIN
            SET @ERROR = 'La visita no pertenece a este proyecto.';
            RETURN;
        END;
    END;
 
    DECLARE @ID_PS INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_SERVICIOS WHERE ID_PROYECTO = @ID_PROYECTO ORDER BY PRINCIPAL DESC, ID);
    IF @ID_VIS IS NULL AND @ID_PS IS NULL
    BEGIN
        SET @ERROR = 'El proyecto no tiene servicios cargados: no se puede crear la visita.';
        RETURN;
    END;
 
    DECLARE @V_IDENT BIT = ISNULL(COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS'), 'ID', 'IsIdentity'), 0),
            @VC_IDENT BIT = ISNULL(COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES'), 'ID', 'IsIdentity'), 0),
            @ST_PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'PENDIENTE_CLIENTE'),
            @G_PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
            @G_NORM INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
            @ID_PLAN INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_PLANES WHERE ID_PROYECTO = @ID_PROYECTO ORDER BY ID DESC),
            @NUEVA BIT = CASE WHEN @SEL3 = '' THEN 1 ELSE 0 END,
            @PRIMERA BIT = 0, @ID_NP INT = NULL, @NEW_ID INT, @PEND_TXT VARCHAR(200) = '';
    IF @G_NORM IS NULL SET @G_NORM = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES ORDER BY ID);
    SET @PRIMERA = CASE WHEN @REG_ID IS NULL THEN 1 ELSE 0 END;
 
    BEGIN TRY
        BEGIN TRANSACTION;
            /* ---------- la visita ---------- */
            IF @ID_VIS IS NULL
            BEGIN
                IF @V_IDENT = 1
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS
                        (ID_PROYECTO, ID_PROYECTO_SERVICIO, FECHA_DESDE, FECHA_HASTA, DIAS, LUGAR, DESCRIPCION, OBSERVADOR,
                         ESTADO, FECHA_ALTA, USUARIO_ALTA, TOTAL_HORAS_EJECUTADAS, HORAS_SIN_CONSULTOR)
                    VALUES
                        (@ID_PROYECTO, @ID_PS, CONVERT(DATETIME, @F), CONVERT(DATETIME, @F), 1, NULLIF(LEFT(@T16,300),''),
                         'Visita registrada por el consultor', @MOD, 'CONFIRMADO', GETDATE(), @IAGENTE, @HORAS, 0);
                    SET @ID_VIS = SCOPE_IDENTITY();
                END
                ELSE
                BEGIN
                    SELECT @NEW_ID = ISNULL(MAX(ID), 0) + 1 FROM dbo.VCT_PROYECTOS_VISITAS WITH (UPDLOCK, HOLDLOCK);
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS
                        (ID, ID_PROYECTO, ID_PROYECTO_SERVICIO, FECHA_DESDE, FECHA_HASTA, DIAS, LUGAR, DESCRIPCION, OBSERVADOR,
                         ESTADO, FECHA_ALTA, USUARIO_ALTA, TOTAL_HORAS_EJECUTADAS, HORAS_SIN_CONSULTOR)
                    VALUES
                        (@NEW_ID, @ID_PROYECTO, @ID_PS, CONVERT(DATETIME, @F), CONVERT(DATETIME, @F), 1, NULLIF(LEFT(@T16,300),''),
                         'Visita registrada por el consultor', @MOD, 'CONFIRMADO', GETDATE(), @IAGENTE, @HORAS, 0);
                    SET @ID_VIS = @NEW_ID;
                END;
            END
            ELSE
                /* se corre la fecha conservando la duracion (visitas de varios dias) */
                UPDATE dbo.VCT_PROYECTOS_VISITAS
                   SET FECHA_HASTA = DATEADD(DAY, DATEDIFF(DAY, FECHA_DESDE, ISNULL(FECHA_HASTA, FECHA_DESDE)), CONVERT(DATETIME, @F)),
                       FECHA_DESDE = CONVERT(DATETIME, @F),
                       ESTADO = 'CONFIRMADO',
                       TOTAL_HORAS_EJECUTADAS = @HORAS,
                       OBSERVADOR = ISNULL(@MOD, OBSERVADOR),
                       LUGAR = ISNULL(NULLIF(LEFT(@T16,300),''), LUGAR),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_VIS;
 
            /* ---------- horas del consultor en la visita ---------- */
            IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE ID_VISITA = @ID_VIS AND ID_CONSULTOR = @ID_CONS)
                UPDATE dbo.VCT_PROYECTOS_VISITAS_CONSULTORES
                   SET HORAS_EJECUTADAS = @HORAS, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID_VISITA = @ID_VIS AND ID_CONSULTOR = @ID_CONS;
            ELSE IF @VC_IDENT = 1
                INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES
                    (ID_VISITA, ID_CONSULTOR, LIDER, HORAS_PLANIFICADAS, HORAS_EJECUTADAS, FECHA_ALTA, USUARIO_ALTA, OBSERVACIONES)
                VALUES
                    (@ID_VIS, @ID_CONS,
                     CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE ID_VISITA = @ID_VIS) THEN 0 ELSE 1 END,
                     NULL, @HORAS, GETDATE(), @IAGENTE, 'Registro de visita');
            ELSE
            BEGIN
                SELECT @NEW_ID = ISNULL(MAX(ID), 0) + 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WITH (UPDLOCK, HOLDLOCK);
                INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES
                    (ID, ID_VISITA, ID_CONSULTOR, LIDER, HORAS_PLANIFICADAS, HORAS_EJECUTADAS, FECHA_ALTA, USUARIO_ALTA, OBSERVACIONES)
                VALUES
                    (@NEW_ID, @ID_VIS, @ID_CONS,
                     CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE ID_VISITA = @ID_VIS) THEN 0 ELSE 1 END,
                     NULL, @HORAS, GETDATE(), @IAGENTE, 'Registro de visita');
            END;
 
            /* ---------- el registro ---------- */
            IF @REG_ID IS NULL
                INSERT INTO dbo.VCT_PROYECTOS_VISITAS_REGISTRO
                    (ID_VISITA, ID_CONSULTOR, FECHA, HORA_DESDE, HORA_HASTA, HORAS, MODALIDAD, LUGAR,
                     TEMAS_TRABAJADOS, PROXIMOS_TEMAS, ACCIONES_CLIENTE, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_VIS, @ID_CONS, @F, @HD, @HH, @HORAS, @MOD, NULLIF(LEFT(@T16,300),''),
                     @T17, NULLIF(@T18,''), NULLIF(@T19,''), GETDATE(), @IAGENTE);
            ELSE
                UPDATE dbo.VCT_PROYECTOS_VISITAS_REGISTRO
                   SET ID_CONSULTOR = @ID_CONS, FECHA = @F, HORA_DESDE = @HD, HORA_HASTA = @HH, HORAS = @HORAS,
                       MODALIDAD = @MOD, LUGAR = NULLIF(LEFT(@T16,300),''), TEMAS_TRABAJADOS = @T17,
                       PROXIMOS_TEMAS = NULLIF(@T18,''), ACCIONES_CLIENTE = NULLIF(@T19,''),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @REG_ID;
 
            /* ---------- pendiente del cliente con las acciones (solo la primera vez) ---------- */
            IF @PRIMERA = 1 AND UPPER(@T20) = 'SI' AND @T19 <> ''
            BEGIN
                IF @ST_PEND IS NULL OR @G_PEND IS NULL
                    SET @PEND_TXT = ' No se creo el pendiente: falta el subtipo PENDIENTE_CLIENTE (Plan Estrategico).';
                ELSE
                BEGIN
                    INSERT INTO dbo.VCT_GESTIONES
                        (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN,
                         REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                    VALUES
                        ('MANUAL',
                         ISNULL((SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'TAREA'), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS ORDER BY ID)),
                         @ST_PEND, @G_PEND, @G_NORM,
                         'Acciones acordadas en la visita del ' + CONVERT(VARCHAR(10), @F, 103),
                         LEFT(@T19, 2000), @ID_CLIENTE, @ID_PROYECTO, @ID_PLAN,
                         0, 0, GETDATE(), GETDATE(), GETDATE(), @IAGENTE);
                    SET @ID_NP = SCOPE_IDENTITY();
                    UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_NP), 9) WHERE ID = @ID_NP;
 
                    INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                        (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@ID_NP, NULL, @G_PEND, 'CREACION', 'Pendiente del cliente (registro de visita).', 'USUARIO', GETDATE(), @IAGENTE);
 
                    INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                        (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_NP, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE),
                           (@ID_NP, 'RESPONSABLE', 'CLIENTE', @ID_CLIENTE, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
 
                    UPDATE dbo.VCT_PROYECTOS_VISITAS_REGISTRO SET ID_GESTION_PENDIENTE = @ID_NP WHERE ID_VISITA = @ID_VIS;
                    SET @PEND_TXT = ' Se agrego un pendiente del cliente con las acciones.';
                END;
            END;
        COMMIT TRANSACTION;
 
        SET @MENSAJE = CASE WHEN @NUEVA = 1 THEN 'Visita registrada: '
                            WHEN @PRIMERA = 1 THEN 'Visita registrada: '
                            ELSE 'Registro actualizado: ' END
                     + CONVERT(VARCHAR(10), @F, 103) + ', ' + dbo.VCT_FMT_HORAS(@HORAS) + ' h.' + @PEND_TXT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ERROR = LEFT('No se pudo grabar la visita: ' + ERROR_MESSAGE(), 1000);
    END CATCH;
END
