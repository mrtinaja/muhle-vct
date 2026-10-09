/* ========================================================================
   PROYECTO_VISITAS_1_INSTALACION  (CREA TABLA, FUNCIONES, SP Y PERMISOS)
   ------------------------------------------------------------------------
   Registro de visitas del consultor y control de horas, en la Vista 360
   de Proyecto (Resumen_reunion_sistema_gestion: fecha, horario, horas,
   temas trabajados, proximos temas del consultor, proximas acciones del
   cliente; horas usadas vs contratadas y por consultor).
   Criterio de horas usadas (opcion A, 08/10):
     - visita con registro            -> horas del registro
     - visita pasada CONFIRMADA (hist) -> TOTAL_HORAS_EJECUTADAS de la visita
     - visita futura                   -> cuenta como "agendada", no usada
     - visita pasada PENDIENTE         -> "sin confirmar", no cuenta
   Contratadas = VCT_PROYECTOS.TOTAL_HORAS_PROYECTADAS.
   El registro va en una tabla NUEVA (VCT_PROYECTOS_VISITAS_REGISTRO), ligada
   a la visita: la migracion desde LK reescribe VCT_PROYECTOS_VISITAS y no
   tiene que pisar lo que carga el consultor. Al registrar tambien se
   actualiza la visita (fecha, CONFIRMADO, horas, modalidad, lugar) y las
   horas del consultor en VCT_PROYECTOS_VISITAS_CONSULTORES.
   Objetos:
     0. tabla dbo.VCT_PROYECTOS_VISITAS_REGISTRO
     1. permisos VISITA.EDIT / VISITA.VIEW (mismos perfiles que el plan)
     2. dbo.VCT_FMT_HORAS                 horas para mostrar (8 / 7,5)
     3. dbo.VCT_PROYECTO_VISITAS_CALC      visitas del proyecto con estado y horas
     4. dbo.VCT_PROYECTO_VISITAS_HORAS_CONS horas usadas por consultor
     5. dbo.VCT_PROYECTO_VISITA_ACCION     graba (comando VISITA_GUARDAR)
     6. dbo.VCT_PROYECTO_VISITA_RENDER     arma la seccion y el formulario
   No borra nada. Se puede volver a correr.
   Despues: PROYECTO_VISITAS_2_PARCHE_V360.sql
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------- 0. tabla del registro ---------------- */
IF OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_REGISTRO') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_PROYECTOS_VISITAS_REGISTRO
    (
        ID                   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_VIS_REG PRIMARY KEY,
        ID_VISITA            INT NOT NULL CONSTRAINT FK_VCT_VIS_REG_VISITA REFERENCES dbo.VCT_PROYECTOS_VISITAS (ID),
        ID_CONSULTOR         INT NULL CONSTRAINT FK_VCT_VIS_REG_CONSULTOR REFERENCES dbo.VCT_CONSULTORES (ID),
        FECHA                DATE NOT NULL,
        HORA_DESDE           TIME(0) NULL,
        HORA_HASTA           TIME(0) NULL,
        HORAS                DECIMAL(6,2) NOT NULL,
        MODALIDAD            VARCHAR(20) NULL,
        LUGAR                VARCHAR(300) NULL,
        TEMAS_TRABAJADOS     VARCHAR(MAX) NOT NULL,
        PROXIMOS_TEMAS       VARCHAR(MAX) NULL,
        ACCIONES_CLIENTE     VARCHAR(MAX) NULL,
        ID_GESTION_PENDIENTE INT NULL,
        FECHA_ALTA           DATETIME NOT NULL CONSTRAINT DF_VCT_VIS_REG_ALTA DEFAULT (GETDATE()),
        USUARIO_ALTA         VARCHAR(100) NULL,
        FECHA_UPD            DATETIME NULL,
        USUARIO_UPD          VARCHAR(100) NULL,
        CONSTRAINT UQ_VCT_VIS_REG_VISITA UNIQUE (ID_VISITA),
        CONSTRAINT CK_VCT_VIS_REG_HORAS CHECK (HORAS > 0 AND HORAS <= 200),
        CONSTRAINT CK_VCT_VIS_REG_HORARIO CHECK (HORA_DESDE IS NULL OR HORA_HASTA IS NULL OR HORA_HASTA > HORA_DESDE)
    );
    PRINT 'Tabla dbo.VCT_PROYECTOS_VISITAS_REGISTRO creada.';
END
ELSE
    PRINT 'La tabla dbo.VCT_PROYECTOS_VISITAS_REGISTRO ya existia.';
GO

/* ---------------- 1. permisos ---------------- */
INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, Tipo)
SELECT a.id, a.nombre, NEWID(), GETDATE(), NULL
FROM (VALUES ('VISITA.EDIT', 'Visitas del proyecto - registrar'),
             ('VISITA.VIEW', 'Visitas del proyecto - ver')) a(id, nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Actions AC WHERE UPPER(LTRIM(RTRIM(AC.Id))) = a.id);
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' acciones VISITA.* creadas en Actions.';

INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
SELECT v.grupo, v.accion, NEWID(), GETDATE()
FROM (VALUES ('GERENCIA','VISITA.EDIT'),('SQUAD','VISITA.EDIT'),('PROYECTOS','VISITA.EDIT'),('CONSULTORES','VISITA.EDIT'),
             ('GERENCIA','VISITA.VIEW'),('SQUAD','VISITA.VIEW'),('PROYECTOS','VISITA.VIEW'),('CONSULTORES','VISITA.VIEW'),
             ('ADMINISTRACION','VISITA.VIEW')) v(grupo, accion)
WHERE EXISTS (SELECT 1 FROM dbo.Groups GR WHERE UPPER(LTRIM(RTRIM(GR.Id))) = v.grupo)
  AND NOT EXISTS (SELECT 1 FROM dbo.GroupsActions X
                  WHERE UPPER(LTRIM(RTRIM(X.GroupId))) = v.grupo
                    AND UPPER(LTRIM(RTRIM(X.ActionId))) = v.accion);
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' permisos VISITA.* asignados.';
GO

/* ---------------- 2. formato de horas ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_FMT_HORAS (@H DECIMAL(12,2))
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN CASE WHEN @H IS NULL THEN '0'
                WHEN @H = FLOOR(@H) THEN CONVERT(VARCHAR(20), CONVERT(BIGINT, @H))
                ELSE REPLACE(CONVERT(VARCHAR(20), CONVERT(DECIMAL(12,1), @H)), '.', ',') END;
END
GO

/* ---------------- 3. visitas del proyecto ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_VISITAS_CALC (@ID_PROYECTO INT)
RETURNS TABLE
AS
RETURN
    SELECT V.ID, V.FECHA_DESDE, V.FECHA_HASTA, V.DIAS, V.LUGAR, V.OBSERVADOR, V.ESTADO,
           CONVERT(DECIMAL(9,2), ISNULL(V.TOTAL_HORAS_EJECUTADAS, 0)) AS HORAS_VISITA,
           R.ID AS ID_REG, R.FECHA AS R_FECHA, R.HORA_DESDE, R.HORA_HASTA, R.HORAS AS R_HORAS,
           R.ID_CONSULTOR AS R_CONSULTOR, R.MODALIDAD AS R_MODALIDAD, R.LUGAR AS R_LUGAR,
           R.TEMAS_TRABAJADOS, R.PROXIMOS_TEMAS, R.ACCIONES_CLIENTE, R.ID_GESTION_PENDIENTE,
           ISNULL(R.USUARIO_UPD, R.USUARIO_ALTA) AS R_USUARIO, ISNULL(R.FECHA_UPD, R.FECHA_ALTA) AS R_FECHA_ALTA,
           X.ESTADO_CALC,
           CONVERT(DATE, ISNULL(CONVERT(DATETIME, R.FECHA), V.FECHA_DESDE)) AS FECHA,
           CONVERT(DECIMAL(9,2), CASE X.ESTADO_CALC WHEN 'REGISTRADA' THEN R.HORAS
                                                    WHEN 'REALIZADA' THEN ISNULL(V.TOTAL_HORAS_EJECUTADAS, 0)
                                                    ELSE 0 END) AS HORAS_USADAS,
           CONVERT(DECIMAL(9,2), CASE WHEN X.ESTADO_CALC = 'AGENDADA' THEN ISNULL(V.TOTAL_HORAS_EJECUTADAS, 0) ELSE 0 END) AS HORAS_AGENDADAS
    FROM dbo.VCT_PROYECTOS_VISITAS V
    LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_REGISTRO R ON R.ID_VISITA = V.ID
    CROSS APPLY
    (
        SELECT CASE WHEN R.ID IS NOT NULL THEN 'REGISTRADA'
                    WHEN CONVERT(DATE, V.FECHA_DESDE) > CONVERT(DATE, GETDATE()) THEN 'AGENDADA'
                    WHEN UPPER(LTRIM(RTRIM(ISNULL(V.ESTADO, '')))) = 'CONFIRMADO' THEN 'REALIZADA'
                    ELSE 'SIN_CONFIRMAR' END AS ESTADO_CALC
    ) X
    WHERE V.ID_PROYECTO = @ID_PROYECTO;
GO

/* ---------------- 4. horas usadas por consultor ---------------- */
/* Registrada: el consultor del registro. Historica: cada consultor de la
   visita con sus horas (o la parte proporcional si no tiene). */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_VISITAS_HORAS_CONS (@ID_PROYECTO INT)
RETURNS TABLE
AS
RETURN
    SELECT Z.ID_CONSULTOR, CONVERT(DECIMAL(12,2), SUM(Z.H)) AS HORAS, COUNT(DISTINCT Z.ID_VISITA) AS VISITAS
    FROM
    (
        SELECT C.ID AS ID_VISITA, C.R_CONSULTOR AS ID_CONSULTOR, C.R_HORAS AS H
        FROM dbo.VCT_PROYECTO_VISITAS_CALC(@ID_PROYECTO) C
        WHERE C.ESTADO_CALC = 'REGISTRADA'
        UNION ALL
        SELECT C.ID, VC.ID_CONSULTOR, ISNULL(VC.HORAS_EJECUTADAS, C.HORAS_VISITA / ISNULL(NULLIF(N.N, 0), 1))
        FROM dbo.VCT_PROYECTO_VISITAS_CALC(@ID_PROYECTO) C
        OUTER APPLY (SELECT COUNT(*) AS N FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES Q WHERE Q.ID_VISITA = C.ID) N
        LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = C.ID
        WHERE C.ESTADO_CALC = 'REALIZADA'
    ) Z
    GROUP BY Z.ID_CONSULTOR;
GO

/* horas usadas para el KPI de la cabecera ("264 h") */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_HORAS_USADAS_TXT (@ID_PROYECTO INT)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @H DECIMAL(12,2) = (SELECT SUM(HORAS_USADAS) FROM dbo.VCT_PROYECTO_VISITAS_CALC(@ID_PROYECTO));
    RETURN LEFT(dbo.VCT_FMT_HORAS(ISNULL(@H, 0)) + ' h', 10);
END
GO

/* ---------------- 5. grabar ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_VISITA_ACCION
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
GO

/* ---------------- 6. render de la seccion ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_VISITA_RENDER
(
    @ID_PROYECTO INT,
    @IUNIDAD     VARCHAR(100),
    @MENSAJE     VARCHAR(1000) = '',
    @ERROR       VARCHAR(1000) = '',
    @HTML        VARCHAR(MAX) OUTPUT,
    @FORMS       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    /* Seccion "Visitas y horas" de la Vista 360 de Proyecto.
       Formulario en @FORMS (va a OUTPARAM3). No devuelve result sets. */
    SET NOCOUNT ON;
    SET @HTML = '';
    SET @FORMS = '';

    DECLARE @CAN_EDIT BIT = ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'VISITA.EDIT'),0);
    IF @CAN_EDIT = 0 AND ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'VISITA.VIEW'),0) = 0 RETURN;

    DECLARE @EST_COD VARCHAR(30), @CODIGO VARCHAR(100), @P_NOMBRE VARCHAR(300), @P_CLIENTE VARCHAR(300), @CONTR DECIMAL(12,2),
            @HOY DATE = CONVERT(DATE, GETDATE());
    SELECT @EST_COD = E.CODIGO, @CODIGO = P.CODIGO, @P_NOMBRE = P.NOMBRE, @P_CLIENTE = C.RAZON_SOCIAL,
           @CONTR = CONVERT(DECIMAL(12,2), NULLIF(P.TOTAL_HORAS_PROYECTADAS, 0))
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE
    WHERE P.ID = @ID_PROYECTO;

    DECLARE @N INT = 0, @N_REG INT = 0, @N_AGE INT = 0, @N_SINREG INT = 0, @N_REAL INT = 0,
            @H_USADAS DECIMAL(12,2) = 0, @H_AGE DECIMAL(12,2) = 0;
    SELECT @N = COUNT(*),
           @N_REG = ISNULL(SUM(CASE WHEN ESTADO_CALC = 'REGISTRADA' THEN 1 ELSE 0 END), 0),
           @N_AGE = ISNULL(SUM(CASE WHEN ESTADO_CALC = 'AGENDADA' THEN 1 ELSE 0 END), 0),
           @N_SINREG = ISNULL(SUM(CASE WHEN ESTADO_CALC IN ('REALIZADA','SIN_CONFIRMAR') THEN 1 ELSE 0 END), 0),
           @H_USADAS = ISNULL(SUM(HORAS_USADAS), 0),
           @H_AGE = ISNULL(SUM(HORAS_AGENDADAS), 0)
    FROM dbo.VCT_PROYECTO_VISITAS_CALC(@ID_PROYECTO);
    SET @N_REAL = @N - @N_AGE;

    /* proyecto sin lanzar y sin visitas: no se muestra */
    IF @N = 0 AND ISNULL(@EST_COD,'') IN ('BORRADOR','CONFIRMADO','') RETURN;

    DECLARE @PCT DECIMAL(9,1) = CASE WHEN @CONTR > 0 THEN ROUND(100.0 * @H_USADAS / @CONTR, 1) END,
            @DISP DECIMAL(12,2) = CASE WHEN @CONTR > 0 THEN @CONTR - @H_USADAS - @H_AGE END;
    DECLARE @PCT_TXT VARCHAR(20) = CASE WHEN @PCT IS NULL THEN '' WHEN @PCT = FLOOR(@PCT) THEN CONVERT(VARCHAR(20), CONVERT(INT, @PCT)) ELSE REPLACE(CONVERT(VARCHAR(20), @PCT), '.', ',') END;
    DECLARE @BAR_W VARCHAR(20) = CONVERT(VARCHAR(20), CASE WHEN @PCT IS NULL THEN 0 WHEN @PCT > 100 THEN 100 ELSE @PCT END);

    DECLARE @ALERTA VARCHAR(MAX) =
        CASE WHEN ISNULL(@ERROR,'') <> '' THEN '<div class="vct-lanz-alert is-error">' + dbo.VCT_HTML_ESC(@ERROR) + '</div>'
             WHEN ISNULL(@MENSAJE,'') <> '' THEN '<div class="vct-lanz-alert is-ok">' + dbo.VCT_HTML_ESC(@MENSAJE) + '</div>'
             ELSE '' END;

    /* ---------- resumen de horas ---------- */
    DECLARE @RESUMEN VARCHAR(MAX) =
        '<div class="vct-plan-summary vct-vis-summary">'
      /* usadas */
      + '<div class="vct-plan-kpi"><span class="vct-plan-kpi-label">Horas usadas</span>'
      +   '<b>' + dbo.VCT_FMT_HORAS(@H_USADAS) + ' h' + CASE WHEN @CONTR > 0 THEN ' <span class="vct-vis-de">de ' + dbo.VCT_FMT_HORAS(@CONTR) + ' h</span>' ELSE '' END + '</b>'
      +   '<div class="vct-plan-bar vct-vis-bar' + CASE WHEN @PCT > 100 THEN ' is-over' WHEN @PCT >= 90 THEN ' is-warn' ELSE '' END + '"><span style="width:' + @BAR_W + '%"></span></div>'
      +   '<small>' + CASE WHEN @CONTR IS NULL THEN 'El proyecto no tiene horas contratadas cargadas'
                         WHEN @PCT > 100 THEN '<span class="vct-plan-late">Se pasaron ' + dbo.VCT_FMT_HORAS(@H_USADAS - @CONTR) + ' h de lo contratado</span>'
                         ELSE @PCT_TXT + '% de las horas contratadas' END + '</small></div>'
      /* agendadas */
      + '<div class="vct-plan-kpi"><span class="vct-plan-kpi-label">Horas agendadas</span>'
      +   '<b>' + dbo.VCT_FMT_HORAS(@H_AGE) + ' h</b>'
      +   '<small>' + CONVERT(VARCHAR(10), @N_AGE) + ' visita' + CASE WHEN @N_AGE = 1 THEN '' ELSE 's' END + ' pr&oacute;xima' + CASE WHEN @N_AGE = 1 THEN '' ELSE 's' END + '</small>'
      +   CASE WHEN @DISP IS NULL THEN ''
               WHEN @DISP < 0 THEN '<small class="vct-plan-late">Usadas + agendadas superan lo contratado en ' + dbo.VCT_FMT_HORAS(-@DISP) + ' h</small>'
               ELSE '<small>Quedan ' + dbo.VCT_FMT_HORAS(@DISP) + ' h sin agendar</small>' END
      + '</div>'
      /* registro */
      + '<div class="vct-plan-kpi"><span class="vct-plan-kpi-label">Visitas registradas</span>'
      +   '<b>' + CONVERT(VARCHAR(10), @N_REG) + ' <span class="vct-vis-de">de ' + CONVERT(VARCHAR(10), @N_REAL) + ' realizadas</span></b>'
      +   CASE WHEN @N_SINREG > 0 THEN '<small>' + CONVERT(VARCHAR(10), @N_SINREG) + ' visita' + CASE WHEN @N_SINREG = 1 THEN '' ELSE 's' END + ' pasada' + CASE WHEN @N_SINREG = 1 THEN '' ELSE 's' END + ' sin registro (historial)</small>'
               ELSE '<small>Todas las visitas pasadas tienen registro</small>' END
      + '</div>'
      + '</div>';

    /* ---------- horas por consultor ---------- */
    DECLARE @H_MAX DECIMAL(12,2) = (SELECT MAX(HORAS) FROM dbo.VCT_PROYECTO_VISITAS_HORAS_CONS(@ID_PROYECTO));
    DECLARE @CONS VARCHAR(MAX) = ISNULL((
        SELECT '<li><span class="vct-vis-cons-name">' + dbo.VCT_HTML_ESC(ISNULL(LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,''))), 'Sin consultor')) + '</span>'
             + '<span class="vct-vis-cons-bar"><span style="width:' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,1), CASE WHEN ISNULL(@H_MAX,0) = 0 THEN 0 ELSE 100.0 * H.HORAS / @H_MAX END)) + '%"></span></span>'
             + '<span class="vct-vis-cons-num"><b>' + dbo.VCT_FMT_HORAS(H.HORAS) + ' h</b> &middot; ' + CONVERT(VARCHAR(10), H.VISITAS) + ' visita' + CASE WHEN H.VISITAS = 1 THEN '' ELSE 's' END + '</span></li>'
        FROM dbo.VCT_PROYECTO_VISITAS_HORAS_CONS(@ID_PROYECTO) H
        LEFT JOIN dbo.VCT_CONSULTORES CO ON CO.ID = H.ID_CONSULTOR
        ORDER BY H.HORAS DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    IF @CONS <> ''
        SET @CONS = '<div class="vct-vis-cons"><h4><span data-vct-icon="user-check"></span> Horas usadas por consultor</h4><ul>' + @CONS + '</ul></div>';

    /* ---------- visitas ---------- */
    DECLARE @ROWS VARCHAR(MAX) = '';
    SELECT @ROWS = ISNULL((
        SELECT
            '<tr class="vct-vis-row" data-vis-id="' + CONVERT(VARCHAR(20), C.ID) + '"'
          + ' data-vis-g="' + CASE WHEN C.ESTADO_CALC = 'AGENDADA' THEN 'PROX' ELSE 'REAL' END + '"'
          + ' data-vis-sinreg="' + CASE WHEN C.ESTADO_CALC IN ('REALIZADA','SIN_CONFIRMAR') THEN '1' ELSE '0' END + '"'
          + ' data-vis-text="' + dbo.VCT_HTML_ESC(LOWER(ISNULL(CN.NOMBRES,'') + ' ' + ISNULL(C.R_LUGAR, ISNULL(C.LUGAR,'')) + ' ' + ISNULL(LEFT(C.TEMAS_TRABAJADOS, 400),''))) + '"'
          + ' data-vct-row data-vct-vs-id="' + CONVERT(VARCHAR(20), C.ID) + '"'
          + ' data-vct-vs-fecha="' + CONVERT(VARCHAR(10), CASE WHEN C.FECHA > @HOY THEN @HOY ELSE C.FECHA END, 23) + '"'
          + ' data-vct-vs-desde="' + ISNULL(CONVERT(VARCHAR(5), C.HORA_DESDE, 108), '') + '"'
          + ' data-vct-vs-hasta="' + ISNULL(CONVERT(VARCHAR(5), C.HORA_HASTA, 108), '') + '"'
          + ' data-vct-vs-horas="' + dbo.VCT_FMT_HORAS(ISNULL(C.R_HORAS, NULLIF(C.HORAS_VISITA, 0))) + '"'
          + ' data-vct-vs-cons="' + ISNULL(CONVERT(VARCHAR(20), ISNULL(C.R_CONSULTOR, CN.ID_PRIMERO)), '') + '"'
          + ' data-vct-vs-mod="' + ISNULL(C.R_MODALIDAD, CASE WHEN C.OBSERVADOR LIKE '%remot%' THEN 'Remoto' WHEN C.OBSERVADOR LIKE '%presen%' THEN 'Presencial' ELSE '' END) + '"'
          + ' data-vct-vs-lugar="' + dbo.VCT_HTML_ESC(ISNULL(C.R_LUGAR, C.LUGAR)) + '"'
          + ' data-vct-vs-temas="' + dbo.VCT_HTML_ESC(C.TEMAS_TRABAJADOS) + '"'
          + ' data-vct-vs-prox="' + dbo.VCT_HTML_ESC(C.PROXIMOS_TEMAS) + '"'
          + ' data-vct-vs-acc="' + dbo.VCT_HTML_ESC(C.ACCIONES_CLIENTE) + '"'
          + ' data-vct-vs-pend="NO">'
          + '<td class="vct-plan-date">'
          +   CASE WHEN C.ID_REG IS NOT NULL THEN '<button type="button" class="vct-plan-toggle" data-vct-vis-toggle aria-expanded="false">' + CONVERT(VARCHAR(10), C.FECHA, 103) + '</button>'
                   ELSE CONVERT(VARCHAR(10), C.FECHA, 103) END
          +   CASE WHEN ISNULL(C.DIAS,1) > 1 AND C.FECHA_HASTA IS NOT NULL AND C.ID_REG IS NULL THEN '<small>al ' + CONVERT(VARCHAR(10), C.FECHA_HASTA, 103) + '</small>' ELSE '' END
          + '</td>'
          + '<td class="vct-plan-date">' + CASE WHEN C.HORA_DESDE IS NOT NULL THEN CONVERT(VARCHAR(5), C.HORA_DESDE, 108) + ' a ' + CONVERT(VARCHAR(5), C.HORA_HASTA, 108) ELSE '-' END + '</td>'
          + '<td class="vct-vis-h">' + CASE WHEN C.ESTADO_CALC = 'REGISTRADA' THEN dbo.VCT_FMT_HORAS(C.R_HORAS) ELSE dbo.VCT_FMT_HORAS(C.HORAS_VISITA) END + ' h</td>'
          + '<td>' + CASE WHEN CN.NOMBRES IS NULL THEN '<span class="vct-lanz-muted">-</span>' ELSE dbo.VCT_HTML_ESC(CN.NOMBRES) END + '</td>'
          + '<td>' + dbo.VCT_HTML_ESC(ISNULL(C.R_MODALIDAD, CASE WHEN C.OBSERVADOR LIKE '%remot%' THEN 'Remoto' WHEN C.OBSERVADOR LIKE '%presen%' THEN 'Presencial' ELSE '' END)) + '</td>'
          + '<td><span class="vct-plan-est ' + CASE C.ESTADO_CALC WHEN 'REGISTRADA' THEN 'is-cumplido">Registrada' WHEN 'AGENDADA' THEN 'is-encurso">Agendada'
                                                                  WHEN 'REALIZADA' THEN 'is-sinfechas">Sin registro' ELSE 'is-pendiente">Sin confirmar' END + '</span></td>'
          + '<td class="vct-plan-actions">'
          +   CASE WHEN @CAN_EDIT = 1 AND C.ESTADO_CALC = 'REGISTRADA' THEN
                    '<button type="button" class="vct-plan-icon" title="Editar registro" aria-label="Editar registro" data-vct-command="open-modal-data" data-vct-target="vctVisita"'
                  + ' data-vct-form-title="Editar registro de visita" data-vct-form-subtitle="Visita del ' + CONVERT(VARCHAR(10), C.FECHA, 103) + '"><span data-vct-icon="edit"></span></button>'
                   WHEN @CAN_EDIT = 1 AND C.FECHA <= @HOY THEN
                    '<button type="button" class="vct-btn vct-btn-primary vct-btn-sm" data-vct-command="open-modal-data" data-vct-target="vctVisita"'
                  + ' data-vct-form-title="Registrar visita" data-vct-form-subtitle="Visita agendada del ' + CONVERT(VARCHAR(10), C.FECHA, 103) + '"><span data-vct-icon="check"></span><span>Registrar</span></button>'
                   ELSE '' END
          + '</td></tr>'
          + CASE WHEN C.ID_REG IS NOT NULL THEN
                '<tr class="vct-vis-detail" data-vis-detail="' + CONVERT(VARCHAR(20), C.ID) + '" hidden><td colspan="7"><div class="vct-vis-detail-body">'
              + '<div><h5>Temas trabajados</h5><p>' + REPLACE(dbo.VCT_HTML_ESC(C.TEMAS_TRABAJADOS), CHAR(10), '<br>') + '</p></div>'
              + '<div><h5>Pr&oacute;ximos temas del consultor</h5><p>' + CASE WHEN ISNULL(C.PROXIMOS_TEMAS,'') = '' THEN '<span class="vct-lanz-muted">-</span>' ELSE REPLACE(dbo.VCT_HTML_ESC(C.PROXIMOS_TEMAS), CHAR(10), '<br>') END + '</p></div>'
              + '<div><h5>Pr&oacute;ximas acciones del cliente</h5><p>' + CASE WHEN ISNULL(C.ACCIONES_CLIENTE,'') = '' THEN '<span class="vct-lanz-muted">-</span>' ELSE REPLACE(dbo.VCT_HTML_ESC(C.ACCIONES_CLIENTE), CHAR(10), '<br>') END + '</p>'
              +   CASE WHEN C.ID_GESTION_PENDIENTE IS NOT NULL THEN '<small class="vct-vis-pend">Se cargaron como pendiente del cliente.</small>' ELSE '' END + '</div>'
              + '<p class="vct-vis-meta">' + CASE WHEN ISNULL(C.R_LUGAR,'') <> '' THEN 'Lugar: ' + dbo.VCT_HTML_ESC(C.R_LUGAR) + ' &middot; ' ELSE '' END
              +   'Registrada por ' + dbo.VCT_HTML_ESC(ISNULL(C.R_USUARIO,'')) + ' el ' + CONVERT(VARCHAR(10), C.R_FECHA_ALTA, 103) + '</p>'
              + '</div></td></tr>'
            ELSE '' END
        FROM dbo.VCT_PROYECTO_VISITAS_CALC(@ID_PROYECTO) C
        OUTER APPLY
        (
            SELECT NOMBRES = CASE WHEN C.ID_REG IS NOT NULL
                                  THEN (SELECT LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,''))) FROM dbo.VCT_CONSULTORES CO WHERE CO.ID = C.R_CONSULTOR)
                                  ELSE NULLIF(STUFF((SELECT '; ' + LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,'')))
                                                     FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
                                                     INNER JOIN dbo.VCT_CONSULTORES CO ON CO.ID = VC.ID_CONSULTOR
                                                     WHERE VC.ID_VISITA = C.ID
                                                     ORDER BY VC.LIDER DESC, VC.ID
                                                     FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 2, ''), '') END,
                   ID_PRIMERO = (SELECT TOP 1 VC.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
                                 WHERE VC.ID_VISITA = C.ID ORDER BY VC.LIDER DESC, VC.ID)
        ) CN
        ORDER BY CASE WHEN C.ESTADO_CALC = 'AGENDADA' THEN 0 ELSE 1 END,
                 CASE WHEN C.ESTADO_CALC = 'AGENDADA' THEN C.FECHA END ASC,
                 C.FECHA DESC, C.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    DECLARE @CHIP VARCHAR(MAX) =
        '<div class="vct-plan-chips" data-vct-vis-chips>'
      + '<button type="button" class="vct-plan-chip is-active" data-vis-filter="">Todas <b>' + CONVERT(VARCHAR(10), @N) + '</b></button>'
      + '<button type="button" class="vct-plan-chip" data-vis-filter="PROX">Pr&oacute;ximas <b>' + CONVERT(VARCHAR(10), @N_AGE) + '</b></button>'
      + '<button type="button" class="vct-plan-chip" data-vis-filter="REAL">Realizadas <b>' + CONVERT(VARCHAR(10), @N_REAL) + '</b></button>'
      + CASE WHEN @N_SINREG > 0 THEN '<button type="button" class="vct-plan-chip is-sinfechas" data-vis-filter="SINREG">Sin registro <b>' + CONVERT(VARCHAR(10), @N_SINREG) + '</b></button>' ELSE '' END
      + '</div>';

    SET @HTML =
        '<div class="vct-360-box vct-plan vct-vis" data-vct-vis>'
      + '<div class="vct-360-box-head vct-plan-head">'
      +   '<div><h3><span class="vct-360-title-icon"><span data-vct-icon="calendar"></span></span>Visitas y horas</h3>'
      +   '<p class="vct-360-box-subtitle">Lo que se trabaj&oacute; en cada visita y las horas usadas contra las contratadas.</p></div>'
      +   CASE WHEN @PCT IS NOT NULL THEN '<span class="vct-plan-big' + CASE WHEN @PCT > 100 THEN ' is-over' ELSE '' END + '"><b>' + @PCT_TXT + '%</b> horas usadas</span>' ELSE '' END
      + '</div>'
      + @ALERTA
      + @RESUMEN
      + @CONS
      + '<div class="vct-plan-toolbar">' + @CHIP
      +   '<div class="vct-plan-tools">'
      +     '<div class="vct-plan-search"><span data-vct-icon="search"></span><input type="text" class="vct-input" placeholder="Buscar consultor, lugar o tema..." data-vct-vis-search autocomplete="off"></div>'
      +     CASE WHEN @CAN_EDIT = 1 THEN '<button type="button" class="vct-btn vct-btn-primary vct-btn-sm" data-vct-command="open-modal-empty" data-vct-target="vctVisita" data-vct-form-title="Registrar visita" data-vct-form-subtitle="Visita que no estaba agendada. Si estaba agendada, us&aacute; Registrar en su fila."><span data-vct-icon="plus"></span><span>Registrar visita</span></button>' ELSE '' END
      +   '</div>'
      + '</div>'
      + CASE WHEN @ROWS = '' THEN '<div class="vct-plan-empty"><p>El proyecto todav&iacute;a no tiene visitas.</p></div>'
             ELSE '<div class="vct-plan-table-wrap"><table class="vct-plan-table vct-vis-table"><thead><tr>'
                + '<th>Fecha</th><th>Horario</th><th>Horas</th><th>Consultor</th><th>Modalidad</th><th>Estado</th><th></th>'
                + '</tr></thead><tbody>' + @ROWS + '</tbody></table></div>'
                + '<div class="vct-vis-more" data-vct-vis-more hidden><button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-vis-all>Ver todas</button></div>' END
      + '<p class="vct-plan-foot">Horas usadas = visitas registradas + visitas pasadas confirmadas del historial. Las agendadas a futuro no cuentan hasta que pasan. Contratadas = horas proyectadas del proyecto.</p>'
      + '</div>';

    /* ============================================================
       FORMULARIO
       ============================================================ */
    IF @CAN_EDIT = 0 RETURN;

    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
        COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
        HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
    );
    DECLARE @F VARCHAR(MAX) = '', @OPT_CONS VARCHAR(MAX), @OPT_HORA VARCHAR(MAX) = '', @M INT = 6 * 60, @ID_LIDER INT;

    /* consultores: equipo activo + los que ya visitaron el proyecto */
    SELECT @OPT_CONS = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), X.ID) + '">' + dbo.VCT_HTML_ESC(X.NOMBRE) + '</option>'
        FROM
        (
            SELECT CO.ID, LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,''))) AS NOMBRE,
                   MIN(CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN 0 WHEN EQ.ID IS NOT NULL THEN 1 ELSE 2 END) AS O
            FROM dbo.VCT_CONSULTORES CO
            LEFT JOIN dbo.VCT_PROYECTOS_EQUIPO EQ ON EQ.ID_CONSULTOR = CO.ID AND EQ.ID_PROYECTO = @ID_PROYECTO
                                                 AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
            LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
            WHERE EQ.ID IS NOT NULL
               OR CO.ID IN (SELECT VC.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
                            INNER JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VC.ID_VISITA
                            WHERE V.ID_PROYECTO = @ID_PROYECTO)
            GROUP BY CO.ID, CO.APELLIDOS, CO.NOMBRES
        ) X
        ORDER BY X.O, X.NOMBRE
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT TOP 1 @ID_LIDER = EQ.ID_CONSULTOR
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER'
    ORDER BY EQ.ID DESC;

    /* horario: 06:00 a 22:00 cada 30 minutos */
    WHILE @M <= 22 * 60
    BEGIN
        SET @OPT_HORA = @OPT_HORA + '<option value="' + RIGHT('0' + CONVERT(VARCHAR(2), @M / 60), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @M % 60), 2) + '">'
                      + RIGHT('0' + CONVERT(VARCHAR(2), @M / 60), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @M % 60), 2) + '</option>';
        SET @M = @M + 30;
    END;

    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Fecha','DATE',4,1,NULL,'Seleccionar fecha',NULL,CONVERT(VARCHAR(10), @HOY, 23),0,0,NULL,'vs-fecha'),
    (2,'TEXTO12','Desde','TEXT',3,0,5,NULL,NULL,NULL,0,0,NULL,'vs-desde'),
    (3,'TEXTO13','Hasta','TEXT',3,0,5,NULL,NULL,NULL,0,0,NULL,'vs-hasta'),
    (4,'TEXTO21','Horas','TEXT',2,0,6,'Ej.: 4',NULL,NULL,0,0,'Salen del horario. Escrib&iacute; las horas si fue en varios d&iacute;as.','vs-horas'),
    (5,'TEXTO14','Consultor','TEXT',6,1,20,NULL,NULL,CONVERT(VARCHAR(20), @ID_LIDER),0,0,NULL,'vs-cons'),
    (6,'TEXTO15','Modalidad','TEXT',3,0,20,NULL,NULL,'Presencial',0,0,NULL,'vs-mod'),
    (7,'TEXTO16','Lugar','TEXT',3,0,300,'Ej.: Planta',NULL,NULL,0,0,NULL,'vs-lugar'),
    (8,'TEXTO17','Temas trabajados','TEXTAREA',12,1,4000,'Qu&eacute; se hizo en la visita.',NULL,NULL,0,0,NULL,'vs-temas'),
    (9,'TEXTO18','Pr&oacute;ximos temas del consultor','TEXTAREA',12,0,4000,'Qu&eacute; se va a trabajar en la pr&oacute;xima visita.',NULL,NULL,0,0,NULL,'vs-prox'),
    (10,'TEXTO19','Pr&oacute;ximas acciones del cliente','TEXTAREA',12,0,4000,'Lo que tiene que hacer el cliente antes de la pr&oacute;xima visita.',NULL,NULL,0,0,NULL,'vs-acc'),
    (11,'TEXTO20','Crear pendiente del cliente con estas acciones','TEXT',12,0,2,NULL,NULL,'NO',0,0,'Aparece en "Pendientes del cliente" del Plan Estrat&eacute;gico. Solo al registrar la visita por primera vez.','vs-pend'),
    (12,'IDSELEC03','Visita','HIDDEN',12,0,NULL,NULL,NULL,'',0,1,NULL,'vs-id'),
    (13,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'VISITA_GUARDAR',0,1,NULL,NULL),
    (14,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctVisita', @TITLE='Registrar visita',
         @SUBTITLE='Fecha, horario y lo trabajado. Las horas se descuentan de las contratadas.', @ICON='calendar',
         @LAYOUT='MODAL', @SAVE_LABEL='Guardar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
    SET @FORMS = REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ')
        + '<template data-vct-field-options data-vct-target="vctVisita" data-vct-field="TEXTO12" data-vct-placeholder="--:--">' + @OPT_HORA + '</template>'
        + '<template data-vct-field-options data-vct-target="vctVisita" data-vct-field="TEXTO13" data-vct-placeholder="--:--">' + @OPT_HORA + '</template>'
        + '<template data-vct-field-options data-vct-target="vctVisita" data-vct-field="TEXTO14" data-vct-placeholder="Seleccione el consultor">' + @OPT_CONS + '</template>'
        + '<template data-vct-field-options data-vct-target="vctVisita" data-vct-field="TEXTO15" data-vct-placeholder="Seleccione"><option value="Presencial">Presencial</option><option value="Remoto">Remoto</option></template>'
        + '<template data-vct-field-options data-vct-target="vctVisita" data-vct-field="TEXTO20" data-vct-placeholder="Seleccione"><option value="NO">No</option><option value="SI">S&iacute;, crear el pendiente</option></template>';
END
GO

/* ---------------- verificacion ---------------- */
SELECT dbo.VCT_PERFIL_PUEDE('GERENCIA','VISITA.EDIT') AS GERENCIA_EDIT,
       dbo.VCT_PERFIL_PUEDE('ADMINISTRACION','VISITA.EDIT') AS ADMIN_EDIT,
       dbo.VCT_PERFIL_PUEDE('ADMINISTRACION','VISITA.VIEW') AS ADMIN_VIEW;
SELECT ESTADO_CALC, COUNT(*) AS VISITAS, SUM(HORAS_USADAS) AS HORAS_USADAS, SUM(HORAS_AGENDADAS) AS HORAS_AGENDADAS
FROM dbo.VCT_PROYECTO_VISITAS_CALC(978) GROUP BY ESTADO_CALC;
GO

PRINT 'OK: Visitas instaladas (tabla, permisos, funciones y SP de accion/render). Siguiente: PROYECTO_VISITAS_2_PARCHE_V360.sql';
GO
