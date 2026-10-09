/* ========================================================================
   INICIO_PERFIL_3_NOTIFICACIONES  (CREA TABLA Y SP)
   ------------------------------------------------------------------------
   Campanita de notificaciones en el Inicio: las ultimas novedades del
   usuario, las no leidas en rojo con su contador.
     0. tabla dbo.VCT_NOTIFICACIONES (una fila por usuario y novedad;
        TIPO + CLAVE evitan duplicados).
     1. dbo.VCT_NOTIF_GENERAR  se corre al abrir el Inicio y agrega lo nuevo:
          GESTION   gestion abierta asignada al usuario (consultor/empleado)
          AVISO     aviso del plan (cambio de fecha) a cargo del usuario
          VENCIDA   gestion a cargo del usuario que se vencio
          VISITA    visita pasada (30 dias) del consultor sin registrar
          PENDIENTE pendiente del cliente vencido en un proyecto del usuario
          HORAS     proyecto en curso que paso sus horas contratadas
                    (GERENCIA, SQUAD, ADMINISTRACION)
        La primera vez, lo que tiene mas de 7 dias entra como leido (para no
        llenar la campanita con historia).
     2. dbo.VCT_NOTIF_ACCION   comandos NOTIF_LEER (sin uso en el Inicio: el
                               "siguiente" del Inicio es Clientes, no recarga).
     3. dbo.VCT_NOTIF_RENDER   la campanita y su panel (ultimas 20). Lo nuevo
                               desde la ultima visita va en rojo y queda visto.
   Despues: INICIO_PERFIL_1_DASHBOARD.sql (el Inicio llama a estos SP).
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------- 0. tabla ---------------- */
IF OBJECT_ID('dbo.VCT_NOTIFICACIONES') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_NOTIFICACIONES
    (
        ID          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_NOTIFICACIONES PRIMARY KEY,
        USUARIO     VARCHAR(100) NOT NULL,
        TIPO        VARCHAR(20)  NOT NULL,
        CLAVE       VARCHAR(100) NOT NULL,
        TITULO      VARCHAR(300) NOT NULL,
        DETALLE     VARCHAR(1000) NULL,
        ID_PROYECTO INT NULL,
        ID_CLIENTE  INT NULL,
        FECHA       DATETIME NOT NULL CONSTRAINT DF_VCT_NOTIF_FECHA DEFAULT (GETDATE()),
        LEIDA       BIT NOT NULL CONSTRAINT DF_VCT_NOTIF_LEIDA DEFAULT (0),
        FECHA_LEIDA DATETIME NULL,
        FECHA_ALTA  DATETIME NOT NULL CONSTRAINT DF_VCT_NOTIF_ALTA DEFAULT (GETDATE()),
        CONSTRAINT UQ_VCT_NOTIF UNIQUE (USUARIO, TIPO, CLAVE)
    );
    CREATE INDEX IX_VCT_NOTIF_USUARIO ON dbo.VCT_NOTIFICACIONES (USUARIO, LEIDA, FECHA DESC);
    PRINT 'Tabla dbo.VCT_NOTIFICACIONES creada.';
END
ELSE
    PRINT 'La tabla dbo.VCT_NOTIFICACIONES ya existia.';
GO

/* ---------------- 1. generar ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_NOTIF_GENERAR
(
    @IUNIDAD VARCHAR(100),
    @IAGENTE VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @PERFIL VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@IUNIDAD,'')))),
            @HOY DATE = CONVERT(DATE, GETDATE()), @CONS_ID INT, @EMP_ID INT, @PRIMERA BIT = 0;
    IF @U = '' RETURN;

    SELECT TOP 1 @CONS_ID = ID FROM dbo.VCT_CONSULTORES
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO' ORDER BY ID DESC;
    SELECT TOP 1 @EMP_ID = ID FROM dbo.VCT_EMPLEADOS
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO' ORDER BY ID DESC;
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_NOTIFICACIONES WHERE USUARIO = @U) SET @PRIMERA = 1;

    CREATE TABLE #N (TIPO VARCHAR(20), CLAVE VARCHAR(100), TITULO VARCHAR(300), DETALLE VARCHAR(1000),
                     ID_PROYECTO INT, ID_CLIENTE INT, FECHA DATETIME);

    /* gestiones a cargo del usuario (como consultor o como empleado) */
    CREATE TABLE #G (ID INT PRIMARY KEY);
    INSERT INTO #G (ID)
    SELECT DISTINCT GP.ID_GESTION
    FROM dbo.VCT_GESTIONES_PARTICIPANTES GP
    WHERE GP.ROL_PARTICIPANTE = 'RESPONSABLE' AND GP.ESTADO = 'ACTIVO'
      AND ((GP.TIPO_ENTIDAD = 'CONSULTOR' AND GP.ID_ENTIDAD = @CONS_ID) OR (GP.TIPO_ENTIDAD = 'EMPLEADO' AND GP.ID_ENTIDAD = @EMP_ID));

    INSERT INTO #N
    SELECT CASE WHEN T.CODIGO = 'AVISO' THEN 'AVISO' ELSE 'GESTION' END, CONVERT(VARCHAR(20), G.ID),
           LEFT(CASE WHEN T.CODIGO = 'AVISO' THEN G.TITULO ELSE 'Nueva gesti' + CHAR(243) + 'n: ' + G.TITULO END, 300),
           LEFT(ISNULL('(' + P.CODIGO + ') ', '') + ISNULL(P.NOMBRE, '')
                + CASE WHEN G.FECHA_VENCIMIENTO IS NOT NULL THEN ' - vence ' + CONVERT(VARCHAR(10), G.FECHA_VENCIMIENTO, 103) ELSE '' END, 1000),
           G.ID_PROYECTO, P.IDCLIENTE, G.FECHA_CREACION
    FROM #G X
    INNER JOIN dbo.VCT_GESTIONES G ON G.ID = X.ID
    INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T ON T.ID = G.ID_TIPO
    LEFT JOIN dbo.VCT_PROYECTOS P ON P.ID = G.ID_PROYECTO
    WHERE GE.ES_FINAL = 0 AND G.FECHA_CREACION >= DATEADD(DAY, -30, @HOY);

    INSERT INTO #N
    SELECT 'VENCIDA', CONVERT(VARCHAR(20), G.ID) + '-' + CONVERT(VARCHAR(8), G.FECHA_VENCIMIENTO, 112),
           LEFT('Gesti' + CHAR(243) + 'n vencida: ' + G.TITULO, 300),
           LEFT(ISNULL('(' + P.CODIGO + ') ', '') + ISNULL(P.NOMBRE, '') + ' - venci' + CHAR(243) + ' el ' + CONVERT(VARCHAR(10), G.FECHA_VENCIMIENTO, 103), 1000),
           G.ID_PROYECTO, P.IDCLIENTE, DATEADD(DAY, 1, CONVERT(DATETIME, CONVERT(DATE, G.FECHA_VENCIMIENTO)))
    FROM #G X
    INNER JOIN dbo.VCT_GESTIONES G ON G.ID = X.ID
    INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    LEFT JOIN dbo.VCT_PROYECTOS P ON P.ID = G.ID_PROYECTO
    WHERE GE.ES_FINAL = 0 AND G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY;

    /* visitas del consultor sin registrar (ultimos 30 dias) */
    IF @CONS_ID IS NOT NULL
        INSERT INTO #N
        SELECT 'VISITA', CONVERT(VARCHAR(20), V.ID),
               'Visita sin registrar: ' + CONVERT(VARCHAR(10), V.FECHA_DESDE, 103),
               LEFT(ISNULL('(' + P.CODIGO + ') ', '') + ISNULL(P.NOMBRE, '') + ' - cargale los temas trabajados', 1000),
               V.ID_PROYECTO, P.IDCLIENTE, DATEADD(DAY, 1, CONVERT(DATETIME, CONVERT(DATE, V.FECHA_DESDE)))
        FROM dbo.VCT_PROYECTOS_VISITAS V
        INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID AND VC.ID_CONSULTOR = @CONS_ID
        INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = V.ID_PROYECTO
        WHERE CONVERT(DATE, V.FECHA_DESDE) BETWEEN DATEADD(DAY, -30, @HOY) AND DATEADD(DAY, -1, @HOY)
          AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R WHERE R.ID_VISITA = V.ID);

    /* pendientes del cliente vencidos en proyectos donde el usuario esta en el equipo */
    INSERT INTO #N
    SELECT 'PENDIENTE', CONVERT(VARCHAR(20), G.ID) + '-' + CONVERT(VARCHAR(8), G.FECHA_VENCIMIENTO, 112),
           LEFT('Pendiente del cliente vencido: ' + G.TITULO, 300),
           LEFT(ISNULL('(' + P.CODIGO + ') ', '') + ISNULL(P.NOMBRE, ''), 1000),
           G.ID_PROYECTO, P.IDCLIENTE, DATEADD(DAY, 1, CONVERT(DATETIME, CONVERT(DATE, G.FECHA_VENCIMIENTO)))
    FROM dbo.VCT_GESTIONES G
    INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO AND ST.CODIGO = 'PENDIENTE_CLIENTE'
    INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = G.ID_PROYECTO
    WHERE GE.ES_FINAL = 0 AND G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY
      AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WHERE EQ.ID_PROYECTO = P.ID AND EQ.ESTADO = 'ACTIVO'
                  AND ((EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = @CONS_ID) OR (EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ID_EMPLEADO = @EMP_ID)));

    /* horas excedidas: direccion y administracion */
    IF @PERFIL IN ('GERENCIA','SQUAD','ADMINISTRACION')
        INSERT INTO #N
        SELECT 'HORAS', CONVERT(VARCHAR(20), P.ID),
               LEFT('Horas excedidas: (' + ISNULL(P.CODIGO,'') + ') ' + P.NOMBRE, 300),
               dbo.VCT_FMT_HORAS(H.U) + ' h usadas de ' + CONVERT(VARCHAR(10), P.TOTAL_HORAS_PROYECTADAS) + ' contratadas',
               P.ID, P.IDCLIENTE, GETDATE()
        FROM dbo.VCT_PROYECTOS P
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO AND E.CODIGO = 'ENCURSO'
        CROSS APPLY (SELECT SUM(C.HORAS_USADAS) AS U FROM dbo.VCT_PROYECTO_VISITAS_CALC(P.ID) C) H
        WHERE P.TOTAL_HORAS_PROYECTADAS > 0 AND H.U > P.TOTAL_HORAS_PROYECTADAS;

    INSERT INTO dbo.VCT_NOTIFICACIONES (USUARIO, TIPO, CLAVE, TITULO, DETALLE, ID_PROYECTO, ID_CLIENTE, FECHA, LEIDA, FECHA_LEIDA)
    SELECT @U, N.TIPO, N.CLAVE, N.TITULO, N.DETALLE, N.ID_PROYECTO, N.ID_CLIENTE, ISNULL(N.FECHA, GETDATE()),
           CASE WHEN @PRIMERA = 1 AND ISNULL(N.FECHA, GETDATE()) < DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END,
           CASE WHEN @PRIMERA = 1 AND ISNULL(N.FECHA, GETDATE()) < DATEADD(DAY, -7, GETDATE()) THEN GETDATE() END
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY TIPO, CLAVE ORDER BY FECHA DESC) AS RN FROM #N) N
    WHERE N.RN = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.VCT_NOTIFICACIONES X WHERE X.USUARIO = @U AND X.TIPO = N.TIPO AND X.CLAVE = N.CLAVE);
END
GO

/* ---------------- 2. marcar como leidas ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_NOTIF_ACCION
(
    @IPKEYJOB VARCHAR(100),
    @IAGENTE  VARCHAR(100)
)
AS
BEGIN
    /* VCT_BUFFER: TEXTO30 = NOTIF_LEER, FLAG01 = 1, IDSELEC03 = id o TODAS */
    SET NOCOUNT ON;
    DECLARE @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100), @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,''))));
    SELECT TOP 1 @FLAG = ISNULL(FLAG01,''), @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))), @SEL3 = UPPER(LTRIM(RTRIM(ISNULL(IDSELEC03,''))))
    FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
    IF CHARINDEX(',', @CMD) > 0 SET @CMD = LEFT(@CMD, CHARINDEX(',', @CMD) - 1);
    IF CHARINDEX(',', @SEL3) > 0 SET @SEL3 = LEFT(@SEL3, CHARINDEX(',', @SEL3) - 1);
    IF ISNULL(@FLAG,'') <> '1' OR @CMD <> 'NOTIF_LEER' RETURN;

    UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL WHERE PAR_KEY = @IPKEYJOB;

    IF @SEL3 = 'TODAS'
        UPDATE dbo.VCT_NOTIFICACIONES SET LEIDA = 1, FECHA_LEIDA = GETDATE() WHERE USUARIO = @U AND LEIDA = 0;
    ELSE IF @SEL3 <> '' AND PATINDEX('%[^0-9]%', @SEL3) = 0 AND LEN(@SEL3) <= 9
        UPDATE dbo.VCT_NOTIFICACIONES SET LEIDA = 1, FECHA_LEIDA = GETDATE() WHERE USUARIO = @U AND ID = CONVERT(INT, @SEL3) AND LEIDA = 0;
END
GO

/* ---------------- 3. campanita ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_NOTIF_RENDER
(
    @IUNIDAD VARCHAR(100),
    @IAGENTE VARCHAR(100),
    @LINK    BIT,
    @HTML    VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))), @NL INT = 0, @ITEMS VARCHAR(MAX) = '';
    SET @HTML = '';
    SELECT @NL = COUNT(*) FROM dbo.VCT_NOTIFICACIONES WHERE USUARIO = @U AND LEIDA = 0;

    SELECT @ITEMS = ISNULL((
        SELECT TOP 20
            '<li class="vct-ini-notif' + CASE WHEN N.LEIDA = 0 THEN ' is-unread' ELSE '' END + '">'
          + '<span class="vct-ini-notif-icon is-' + LOWER(N.TIPO) + '" data-vct-icon="'
          +   CASE N.TIPO WHEN 'AVISO' THEN 'clock-3' WHEN 'VENCIDA' THEN 'list-checks' WHEN 'VISITA' THEN 'calendar'
                          WHEN 'PENDIENTE' THEN 'user-check' WHEN 'HORAS' THEN 'chart-bar' ELSE 'clipboard-check' END + '"></span>'
          + '<span class="vct-ini-notif-main">'
          +   '<span class="vct-ini-notif-title">'
          +     CASE WHEN @LINK = 1 AND N.ID_PROYECTO IS NOT NULL
                     THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), N.ID_PROYECTO) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(N.ID_CLIENTE,0)) + '">' + dbo.VCT_HTML_ESC(N.TITULO) + '</button>'
                     ELSE dbo.VCT_HTML_ESC(N.TITULO) END
          +   '</span>'
          +   CASE WHEN ISNULL(N.DETALLE,'') <> '' THEN '<span class="vct-ini-notif-meta">' + dbo.VCT_HTML_ESC(N.DETALLE) + '</span>' ELSE '' END
          +   '<span class="vct-ini-notif-date">'
          +     CASE WHEN DATEDIFF(MINUTE, N.FECHA, GETDATE()) < 60 THEN 'hace ' + CONVERT(VARCHAR(10), CASE WHEN DATEDIFF(MINUTE, N.FECHA, GETDATE()) < 1 THEN 1 ELSE DATEDIFF(MINUTE, N.FECHA, GETDATE()) END) + ' min'
                     WHEN DATEDIFF(HOUR, N.FECHA, GETDATE()) < 24 THEN 'hace ' + CONVERT(VARCHAR(10), DATEDIFF(HOUR, N.FECHA, GETDATE())) + ' h'
                     WHEN DATEDIFF(DAY, N.FECHA, GETDATE()) < 7 THEN 'hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, N.FECHA, GETDATE())) + ' d'
                     ELSE CONVERT(VARCHAR(10), N.FECHA, 103) END
          +   '</span>'
          + '</span>'
          + '</li>'
        FROM dbo.VCT_NOTIFICACIONES N
        WHERE N.USUARIO = @U
        ORDER BY N.LEIDA, N.FECHA DESC, N.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @HTML =
        '<div class="vct-ini-bell" data-vct-ini-bell>'
      + '<button type="button" class="vct-ini-bell-btn' + CASE WHEN @NL > 0 THEN ' has-unread' ELSE '' END + '" data-vct-ini-bell-toggle aria-expanded="false"'
      +   ' title="Notificaciones" aria-label="Notificaciones' + CASE WHEN @NL > 0 THEN ': ' + CONVERT(VARCHAR(10), @NL) + ' sin leer' ELSE '' END + '">'
      +   '<span data-vct-icon="bell"></span>'
      +   CASE WHEN @NL > 0 THEN '<span class="vct-ini-bell-badge">' + CASE WHEN @NL > 99 THEN '99+' ELSE CONVERT(VARCHAR(10), @NL) END + '</span>' ELSE '' END
      + '</button>'
      + '<div class="vct-ini-bell-panel" data-vct-ini-bell-panel hidden>'
      +   '<div class="vct-ini-bell-head"><b>Notificaciones</b>'
      +     CASE WHEN @NL > 0 THEN '<span class="vct-ini-bell-new" style="color:#b91c1c;font-size:12px;">' + CONVERT(VARCHAR(10), @NL) + ' nueva' + CASE WHEN @NL = 1 THEN '' ELSE 's' END + ' desde tu &uacute;ltima visita</span>'
            ELSE '<span class="vct-ini-bell-ok">Est&aacute;s al d&iacute;a</span>' END
      +   '</div>'
      +   CASE WHEN @ITEMS = '' THEN '<p class="vct-ini-bell-empty">Todav&iacute;a no ten&eacute;s notificaciones.</p>'
               ELSE '<ul class="vct-ini-bell-list">' + @ITEMS + '</ul>' END
      + '</div>'
      + '</div>';
    /* lo mostrado queda visto: en la proxima visita ya no aparece en rojo */
    UPDATE dbo.VCT_NOTIFICACIONES SET LEIDA = 1, FECHA_LEIDA = GETDATE() WHERE USUARIO = @U AND LEIDA = 0;
END
GO

PRINT 'OK: notificaciones instaladas. Siguiente: INICIO_PERFIL_1_DASHBOARD.sql';
GO
