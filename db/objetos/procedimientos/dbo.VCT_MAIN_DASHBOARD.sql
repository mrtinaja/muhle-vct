 
CREATE PROCEDURE [dbo].[VCT_MAIN_DASHBOARD]
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
    /* INICIO_PERFIL_V1 */
    /* ACCIONES_RUTEO_V1: el menu Acciones (ACTION=PLANIFICACION) no tiene paso propio en la plataforma */
    IF OBJECT_ID('dbo.VCT_MAIN_ACCIONES') IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB AND UPPER(LTRIM(RTRIM(ISNULL(ACTION,'')))) = 'PLANIFICACION')
    BEGIN
        EXEC dbo.VCT_MAIN_ACCIONES @IPKEYJOB = @IPKEYJOB, @FORM_ID = @FORM_ID, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,
             @OUTPARAM1 = @OUTPARAM1 OUTPUT, @OUTPARAM2 = @OUTPARAM2 OUTPUT, @OUTPARAM3 = @OUTPARAM3 OUTPUT;
        RETURN;
    END;
    SET NOCOUNT ON;
    SET @OUTPARAM1 = '';
    SET @OUTPARAM2 = NULL;
    SET @OUTPARAM3 = NULL;
 
    DECLARE @HTML_SHELL VARCHAR(MAX) = '', @RESULTADO_SHELL VARCHAR(20) = '', @SIDEBAR_ID INT = 0,
            @HOY DATE = CONVERT(DATE, GETDATE()),
            @PERFIL VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@IUNIDAD,'')))),
            @CONS_ID INT = NULL, @EMP_ID INT = NULL, @NOMBRE VARCHAR(300) = '',
            @VE_TODO BIT = 0, @ES_ADMIN BIT = 0, @LINK BIT = 0,
            @GUID_P VARCHAR(50) = '330B876D-4E57-4E2E-BFC3-D7B998D09725',
            @TABS VARCHAR(MAX) = '', @PANELS VARCHAR(MAX) = '', @NTABS INT = 0;
 
    DECLARE @SUBT VARCHAR(200) = 'Lo importante de hoy, seg' + CHAR(250) + 'n tu perfil.';
    SET @VE_TODO = CASE WHEN @PERFIL IN ('GERENCIA','SQUAD','ADMINISTRACION','PROYECTOS') THEN 1 ELSE 0 END;
    SET @ES_ADMIN = CASE WHEN @PERFIL = 'ADMINISTRACION' THEN 1 ELSE 0 END;
 
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @FORM_ID = @FORM_ID,
             @TITLE = 'Inicio', @SUBTITLE = @SUBT,
             @SEARCH_PLACEHOLDER = '', @SHOW_SEARCH = 0,
             @OSHELL = @HTML_SHELL OUTPUT, @ORESULTADO = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
    END CATCH;
 
    BEGIN TRY
        SELECT TOP 1 @SIDEBAR_ID = CONVERT(INT, SB.Id)
        FROM dbo.SideBar SB WITH(NOLOCK)
        INNER JOIN dbo.SideBarGroups SBG WITH(NOLOCK) ON CONVERT(VARCHAR(50), SBG.SideBarId) = CONVERT(VARCHAR(50), SB.Id)
        WHERE UPPER(LTRIM(RTRIM(SBG.GroupId))) = @PERFIL AND UPPER(LTRIM(RTRIM(ISNULL(SB.Code,'')))) = 'INICIO'
        ORDER BY CONVERT(INT, SB.Id);
    END TRY
    BEGIN CATCH
        SET @SIDEBAR_ID = 0;
    END CATCH;
 
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'CLIENTES') A WHERE A.ACTION_TYPE = 'VIEW') SET @LINK = 1;
    END TRY
    BEGIN CATCH
        SET @LINK = 0;
    END CATCH;
 
    /* ---------- notificaciones (campanita) ---------- */
    DECLARE @BELL VARCHAR(MAX) = '';
    BEGIN TRY
        IF OBJECT_ID('dbo.VCT_NOTIF_RENDER') IS NOT NULL
        BEGIN
            EXEC dbo.VCT_NOTIF_ACCION @IPKEYJOB = @IPKEYJOB, @IAGENTE = @IAGENTE;
            EXEC dbo.VCT_NOTIF_GENERAR @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE;
            EXEC dbo.VCT_NOTIF_RENDER @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @LINK = @LINK, @HTML = @BELL OUTPUT;
        END;
    END TRY
    BEGIN CATCH
        SET @BELL = '';
    END CATCH;
 
    /* ---------- quien es ---------- */
    SELECT TOP 1 @CONS_ID = C.ID, @NOMBRE = LTRIM(RTRIM(ISNULL(C.NOMBRES,'')))
    FROM dbo.VCT_CONSULTORES C
    WHERE LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,''))) = LTRIM(RTRIM(@IAGENTE)) AND UPPER(ISNULL(C.ESTADO,'')) = 'ACTIVO'
    ORDER BY C.ID DESC;
 
    SELECT TOP 1 @EMP_ID = E.ID, @NOMBRE = CASE WHEN @NOMBRE = '' THEN LTRIM(RTRIM(ISNULL(E.NOMBRES,''))) ELSE @NOMBRE END
    FROM dbo.VCT_EMPLEADOS E
    WHERE LTRIM(RTRIM(ISNULL(E.ID_USUARIO_SEGURIDAD,''))) = LTRIM(RTRIM(@IAGENTE)) AND UPPER(ISNULL(E.ESTADO,'')) = 'ACTIVO'
    ORDER BY E.ID DESC;
 
    /* ---------- proyectos vigentes con horas ---------- */
    CREATE TABLE #P (ID INT PRIMARY KEY, IDCLIENTE INT, CODIGO VARCHAR(100), NOMBRE VARCHAR(300), CLIENTE VARCHAR(300),
                     EST VARCHAR(30), AVANCE INT, INICIO DATETIME, CONTR DECIMAL(12,2), USADAS DECIMAL(12,2), AGEND DECIMAL(12,2),
                     TXT VARCHAR(MAX));
    INSERT INTO #P (ID, IDCLIENTE, CODIGO, NOMBRE, CLIENTE, EST, AVANCE, INICIO, CONTR, USADAS, AGEND)
    SELECT P.ID, P.IDCLIENTE, P.CODIGO, P.NOMBRE, CL.RAZON_SOCIAL, E.CODIGO, ISNULL(P.PORCENTAJE_AVANCE,0),
           ISNULL(P.FECHA_INICIO_REAL, P.FECHA_INICIO), CONVERT(DECIMAL(12,2), NULLIF(P.TOTAL_HORAS_PROYECTADAS,0)),
           ISNULL(H.U,0), ISNULL(H.A,0)
    FROM dbo.VCT_PROYECTOS P
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    LEFT JOIN dbo.VCT_CLIENTES CL ON CL.ID = P.IDCLIENTE
    OUTER APPLY (SELECT SUM(V.HORAS_USADAS) AS U, SUM(V.HORAS_AGENDADAS) AS A FROM dbo.VCT_PROYECTO_VISITAS_CALC(P.ID) V) H
    WHERE E.CODIGO IN ('ENCURSO','CONFIRMADO');
 
    /* nombre del proyecto (clicable si el perfil puede abrir la 360) */
    UPDATE #P SET TXT =
        CASE WHEN @LINK = 1
             THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), ID) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(IDCLIENTE,0)) + '">'
                  + dbo.VCT_HTML_ESC(ISNULL('(' + CODIGO + ') ','') + NOMBRE) + '</button>'
             ELSE dbo.VCT_HTML_ESC(ISNULL('(' + CODIGO + ') ','') + NOMBRE) END;
 
    DECLARE @EMPTY_FMT VARCHAR(200) = '<div class="vct-ini-empty">{T}</div>';
 
    /* =====================================================================
       PESTANIA: MIS VISITAS Y PLAN (consultor)
       ===================================================================== */
    IF @CONS_ID IS NOT NULL
    BEGIN
        DECLARE @C_NPROY INT = 0, @C_SINREG INT = 0, @C_PROX INT = 0, @C_GES INT = 0, @C_GESV INT = 0,
                @C_VIS VARCHAR(MAX) = '', @C_GL VARCHAR(MAX) = '', @C_PROYS VARCHAR(MAX) = '', @C_BARS VARCHAR(MAX) = '';
 
        CREATE TABLE #MC (ID INT PRIMARY KEY);
        INSERT INTO #MC (ID)
        SELECT P.ID FROM #P P
        WHERE EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                      AND EQ.ESTADO = 'ACTIVO' AND EQ.ID_CONSULTOR = @CONS_ID)
           OR EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS V
                      INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID
                      WHERE V.ID_PROYECTO = P.ID AND VC.ID_CONSULTOR = @CONS_ID AND V.FECHA_DESDE >= DATEADD(DAY, -120, @HOY));
        SET @C_NPROY = (SELECT COUNT(*) FROM #MC);
 
        /* visitas: ultimos 30 dias sin registro + proximos 14 dias */
        CREATE TABLE #CV (ID INT, ID_PROYECTO INT, FECHA DATE, ESTADO_CALC VARCHAR(20), MODALIDAD VARCHAR(50), LUGAR VARCHAR(300), HORAS DECIMAL(9,2));
        INSERT INTO #CV
        SELECT C.ID, M.ID, C.FECHA, C.ESTADO_CALC,
               ISNULL(C.R_MODALIDAD, CASE WHEN C.OBSERVADOR LIKE '%remot%' THEN 'Remoto' WHEN C.OBSERVADOR LIKE '%presen%' THEN 'Presencial' ELSE 'Visita' END),
               ISNULL(C.R_LUGAR, C.LUGAR), ISNULL(C.R_HORAS, C.HORAS_VISITA)
        FROM #MC M
        CROSS APPLY dbo.VCT_PROYECTO_VISITAS_CALC(M.ID) C
        WHERE C.FECHA BETWEEN DATEADD(DAY, -30, @HOY) AND DATEADD(DAY, 14, @HOY)
          AND (C.R_CONSULTOR = @CONS_ID
               OR (C.ID_REG IS NULL AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WHERE VC.ID_VISITA = C.ID AND VC.ID_CONSULTOR = @CONS_ID)));
 
        SELECT @C_SINREG = SUM(CASE WHEN ESTADO_CALC IN ('REALIZADA','SIN_CONFIRMAR') THEN 1 ELSE 0 END),
               @C_PROX = SUM(CASE WHEN ESTADO_CALC = 'AGENDADA' THEN 1 ELSE 0 END)
        FROM #CV;
 
        SELECT @C_VIS = ISNULL((
            SELECT TOP 8
                '<div class="vct-ini-row">'
              + '<span class="vct-ini-row-icon ' + CASE WHEN V.ESTADO_CALC = 'AGENDADA' THEN 'is-blue' ELSE 'is-orange' END + '" data-vct-icon="calendar"></span>'
              + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">'
              +   SUBSTRING('DomLunMarMieJueVieSab', (DATEPART(WEEKDAY, V.FECHA) + @@DATEFIRST - 1) % 7 * 3 + 1, 3) + ' ' + CONVERT(VARCHAR(5), V.FECHA, 103)
              +   ' &middot; ' + dbo.VCT_HTML_ESC(V.MODALIDAD) + '</span>'
              + '<span class="vct-ini-row-meta">' + P.TXT + CASE WHEN ISNULL(V.LUGAR,'') <> '' THEN ' &middot; ' + dbo.VCT_HTML_ESC(V.LUGAR) ELSE '' END
              +   ' &middot; ' + dbo.VCT_FMT_HORAS(V.HORAS) + ' h</span></div>'
              + CASE WHEN V.ESTADO_CALC IN ('REALIZADA','SIN_CONFIRMAR') THEN '<span class="vct-ini-pill is-bad">registrar</span>'
                     WHEN V.ESTADO_CALC = 'REGISTRADA' THEN '<span class="vct-ini-pill is-ok">registrada</span>'
                     WHEN V.FECHA = @HOY THEN '<span class="vct-ini-pill is-warn">hoy</span>'
                     WHEN V.FECHA = DATEADD(DAY, 1, @HOY) THEN '<span class="vct-ini-pill is-info">ma&ntilde;ana</span>'
                     ELSE '<span class="vct-ini-pill is-info">agendada</span>' END
              + '</div>'
            FROM #CV V INNER JOIN #P P ON P.ID = V.ID_PROYECTO
            WHERE V.ESTADO_CALC <> 'REGISTRADA'
            ORDER BY CASE WHEN V.ESTADO_CALC = 'AGENDADA' THEN 1 ELSE 0 END, CASE WHEN V.ESTADO_CALC = 'AGENDADA' THEN V.FECHA END, V.FECHA DESC
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @C_VIS = '' SET @C_VIS = REPLACE(@EMPTY_FMT, '{T}', 'Sin visitas pendientes de registro ni agendadas para los pr&oacute;ximos 14 d&iacute;as.');
 
        /* gestiones donde el consultor es responsable */
        SELECT @C_GES = COUNT(*), @C_GESV = SUM(CASE WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY THEN 1 ELSE 0 END)
        FROM dbo.VCT_GESTIONES G
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
        WHERE GE.ES_FINAL = 0
          AND EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE'
                      AND GP.TIPO_ENTIDAD = 'CONSULTOR' AND GP.ID_ENTIDAD = @CONS_ID AND GP.ESTADO = 'ACTIVO');
 
        SELECT @C_GL = ISNULL((
            SELECT TOP 8
                '<div class="vct-ini-row">'
              + '<span class="vct-ini-row-icon is-purple" data-vct-icon="list-checks"></span>'
              + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</span>'
              + '<span class="vct-ini-row-meta">' + ISNULL(P.TXT, dbo.VCT_HTML_ESC(ISNULL(PX.NOMBRE,'')))
              +   CASE WHEN I.TITULO IS NOT NULL THEN ' &middot; ' + dbo.VCT_HTML_ESC(ISNULL(I.CODIGO_ITEM + ' ','') + I.TITULO) ELSE '' END + '</span></div>'
              + CASE WHEN G.FECHA_VENCIMIENTO IS NULL THEN '<span class="vct-ini-pill is-info">sin fecha</span>'
                     WHEN CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY THEN '<span class="vct-ini-pill is-bad">vencida ' + CONVERT(VARCHAR(5), G.FECHA_VENCIMIENTO, 103) + '</span>'
                     WHEN CONVERT(DATE, G.FECHA_VENCIMIENTO) <= DATEADD(DAY, 3, @HOY) THEN '<span class="vct-ini-pill is-warn">vence ' + CONVERT(VARCHAR(5), G.FECHA_VENCIMIENTO, 103) + '</span>'
                     ELSE '<span class="vct-ini-pill is-info">vence ' + CONVERT(VARCHAR(5), G.FECHA_VENCIMIENTO, 103) + '</span>' END
              + '</div>'
            FROM dbo.VCT_GESTIONES G
            INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
            LEFT JOIN #P P ON P.ID = G.ID_PROYECTO
            LEFT JOIN dbo.VCT_PROYECTOS PX ON PX.ID = G.ID_PROYECTO
            LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS I ON I.ID = G.ID_PLAN_ITEM
            WHERE GE.ES_FINAL = 0
              AND EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE'
                          AND GP.TIPO_ENTIDAD = 'CONSULTOR' AND GP.ID_ENTIDAD = @CONS_ID AND GP.ESTADO = 'ACTIVO')
            ORDER BY ISNULL(G.FECHA_VENCIMIENTO, '29991231'), G.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @C_GL = '' SET @C_GL = REPLACE(@EMPTY_FMT, '{T}', 'No ten&eacute;s gestiones abiertas a tu cargo.');
 
        /* avance y horas de mis proyectos */
        SELECT @C_PROYS = ISNULL((
            SELECT
                '<div class="vct-ini-proj">'
              + '<div class="vct-ini-proj-name">' + P.TXT + '<small>' + dbo.VCT_HTML_ESC(ISNULL(P.CLIENTE,'')) + '</small></div>'
              + '<div class="vct-ini-proj-bars">'
              +   '<div class="vct-ini-meter"><span>Avance</span><div class="vct-ini-track"><i style="width:' + CONVERT(VARCHAR(10), CASE WHEN P.AVANCE > 100 THEN 100 ELSE P.AVANCE END) + '%"></i></div><b>' + CONVERT(VARCHAR(10), P.AVANCE) + '%</b></div>'
              +   CASE WHEN P.CONTR > 0 THEN
                      '<div class="vct-ini-meter is-hours' + CASE WHEN P.USADAS > P.CONTR THEN ' is-over' WHEN P.USADAS >= 0.9 * P.CONTR THEN ' is-warn' ELSE '' END + '"><span>Horas</span><div class="vct-ini-track"><i style="width:'
                    + CONVERT(VARCHAR(10), CONVERT(INT, CASE WHEN P.USADAS >= P.CONTR THEN 100 ELSE 100.0 * P.USADAS / P.CONTR END)) + '%"></i></div><b>'
                    + dbo.VCT_FMT_HORAS(P.USADAS) + '/' + dbo.VCT_FMT_HORAS(P.CONTR) + '</b></div>'
                   ELSE '' END
              + '</div></div>'
            FROM #MC M INNER JOIN #P P ON P.ID = M.ID
            ORDER BY CASE WHEN P.EST = 'ENCURSO' THEN 0 ELSE 1 END, P.NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @C_PROYS = '' SET @C_PROYS = REPLACE(@EMPTY_FMT, '{T}', 'No ten&eacute;s proyectos vigentes asignados.');
 
        IF @C_NPROY > 0 OR ISNULL(@C_GES,0) > 0 OR ISNULL(@C_SINREG,0) + ISNULL(@C_PROX,0) > 0
        BEGIN
        SET @NTABS = @NTABS + 1;
            SET @TABS = @TABS + '<button type="button" class="vct-ini-tab" data-vct-ini-tab="consultor"><span data-vct-icon="calendar"></span><span>Mis visitas y plan</span></button>';
            SET @PANELS = @PANELS
              + '<div class="vct-ini-panel" data-vct-ini-panel="consultor">'
              + '<div class="vct-360-stats-row">'
              +   '<div class="vct-360-stat" data-vct-tone="violet"><span><span class="vct-360-stat-label">Mis proyectos</span><b>' + CONVERT(VARCHAR(10), @C_NPROY) + '</b><small>vigentes donde particip&aacute;s</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN ISNULL(@C_SINREG,0) > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Visitas sin registrar</span><b>' + CONVERT(VARCHAR(10), ISNULL(@C_SINREG,0)) + '</b><small>&uacute;ltimos 30 d&iacute;as</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clipboard-check"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Pr&oacute;ximas visitas</span><b>' + CONVERT(VARCHAR(10), ISNULL(@C_PROX,0)) + '</b><small>pr&oacute;ximos 14 d&iacute;as</small></span><span class="vct-360-stat-icon"><span data-vct-icon="calendar"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN ISNULL(@C_GESV,0) > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Mis gestiones abiertas</span><b>' + CONVERT(VARCHAR(10), ISNULL(@C_GES,0)) + '</b><small>' + CONVERT(VARCHAR(10), ISNULL(@C_GESV,0)) + ' vencida' + CASE WHEN ISNULL(@C_GESV,0) = 1 THEN '' ELSE 's' END + '</small></span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
              + '</div>'
              + '<div class="vct-ini-grid">'
              +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="calendar"></span></span>Visitas</h3><p class="vct-360-box-subtitle">sin registrar y pr&oacute;ximas</p></div></div><div class="vct-ini-list">' + @C_VIS + '</div></div>'
              +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Mis gestiones</h3><p class="vct-360-box-subtitle">por vencimiento</p></div></div><div class="vct-ini-list">' + @C_GL + '</div></div>'
              + '</div>'
              + '<div class="vct-360-box vct-ini-box vct-ini-wide"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="chart-bar"></span></span>Avance y horas de mis proyectos</h3></div></div><div class="vct-ini-box-body">' + @C_PROYS + '</div></div>'
              + '</div>';
        END;
    END;
 
    /* =====================================================================
       PESTANIA: MIS PROYECTOS (analista / empleado)
       ===================================================================== */
    IF @EMP_ID IS NOT NULL
    BEGIN
        DECLARE @A_NPROY INT = 0, @A_AVISOS INT = 0, @A_LANZ INT = 0, @A_VENC INT = 0,
                @A_AV VARCHAR(MAX) = '', @A_LZ VARCHAR(MAX) = '', @A_PROYS VARCHAR(MAX) = '';
 
        CREATE TABLE #MA (ID INT PRIMARY KEY);
        INSERT INTO #MA (ID)
        SELECT P.ID FROM #P P
        WHERE EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'EMPLEADO'
                      AND EQ.ESTADO = 'ACTIVO' AND EQ.ID_EMPLEADO = @EMP_ID);
        SET @A_NPROY = (SELECT COUNT(*) FROM #MA);
        SET @A_LANZ = (SELECT COUNT(*) FROM #MA M INNER JOIN #P P ON P.ID = M.ID WHERE P.EST = 'CONFIRMADO');
 
        /* avisos (gestiones tipo AVISO a cargo del empleado) */
        CREATE TABLE #AG (ID INT PRIMARY KEY);
        INSERT INTO #AG (ID)
        SELECT G.ID FROM dbo.VCT_GESTIONES G
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
        INNER JOIN dbo.VCT_PRM_GESTIONES_TIPOS T ON T.ID = G.ID_TIPO
        WHERE GE.ES_FINAL = 0 AND T.CODIGO = 'AVISO'
          AND EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE'
                      AND GP.TIPO_ENTIDAD = 'EMPLEADO' AND GP.ID_ENTIDAD = @EMP_ID AND GP.ESTADO = 'ACTIVO');
        SET @A_AVISOS = (SELECT COUNT(*) FROM #AG);
 
        SELECT @A_VENC = COUNT(*)
        FROM dbo.VCT_GESTIONES G
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
        WHERE GE.ES_FINAL = 0 AND G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY
          AND EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE'
                      AND GP.TIPO_ENTIDAD = 'EMPLEADO' AND GP.ID_ENTIDAD = @EMP_ID AND GP.ESTADO = 'ACTIVO');
 
        SELECT @A_AV = ISNULL((
            SELECT TOP 8
                '<div class="vct-ini-row">'
              + '<span class="vct-ini-row-icon is-orange" data-vct-icon="clock-3"></span>'
              + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</span>'
              + '<span class="vct-ini-row-meta">' + ISNULL(P.TXT, dbo.VCT_HTML_ESC(ISNULL(PX.NOMBRE,''))) + ' &middot; ' + CONVERT(VARCHAR(10), G.FECHA_CREACION, 103) + '</span></div>'
              + '<span class="vct-ini-pill is-warn">aviso</span></div>'
            FROM #AG A INNER JOIN dbo.VCT_GESTIONES G ON G.ID = A.ID
            LEFT JOIN #P P ON P.ID = G.ID_PROYECTO
            LEFT JOIN dbo.VCT_PROYECTOS PX ON PX.ID = G.ID_PROYECTO
            ORDER BY G.FECHA_CREACION DESC, G.ID DESC
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @A_AV = '' SET @A_AV = REPLACE(@EMPTY_FMT, '{T}', 'Sin avisos abiertos.');
 
        /* lanzamientos pendientes */
        SELECT @A_LZ = ISNULL((
            SELECT
                '<div class="vct-ini-row">'
              + '<span class="vct-ini-row-icon is-purple" data-vct-icon="folder"></span>'
              + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + P.TXT + '</span>'
              + '<span class="vct-ini-row-meta">' + dbo.VCT_HTML_ESC(ISNULL(P.CLIENTE,'')) + ' &middot; ' + CONVERT(VARCHAR(2), L.PASOS) + ' de 4 pasos</span></div>'
              + '<span class="vct-ini-pill ' + CASE WHEN L.PASOS = 4 THEN 'is-ok">listo para iniciar' WHEN L.PASOS = 0 THEN 'is-bad">sin empezar' ELSE 'is-warn">en preparaci&oacute;n' END + '</span></div>'
            FROM #MA M INNER JOIN #P P ON P.ID = M.ID
            CROSS APPLY (SELECT CASE WHEN ISNULL(LE.CONSULTORES,0) > 0 THEN 1 ELSE 0 END + CASE WHEN ISNULL(LE.DATOS_CARGADOS,0) > 0 THEN 1 ELSE 0 END
                              + CASE WHEN ISNULL(LE.CONSIDERACIONES,0) > 0 THEN 1 ELSE 0 END + CASE WHEN ISNULL(LE.REUNION_OK,0) = 1 THEN 1 ELSE 0 END AS PASOS
                         FROM dbo.VCT_PROYECTO_LANZ_ESTADO(P.ID) LE) L
            WHERE P.EST = 'CONFIRMADO'
            ORDER BY L.PASOS DESC, P.NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @A_LZ = '' SET @A_LZ = REPLACE(@EMPTY_FMT, '{T}', 'No hay proyectos esperando lanzamiento.');
 
        SELECT @A_PROYS = ISNULL((
            SELECT
                '<div class="vct-ini-proj">'
              + '<div class="vct-ini-proj-name">' + P.TXT + '<small>' + dbo.VCT_HTML_ESC(ISNULL(P.CLIENTE,'')) + CASE WHEN P.EST = 'CONFIRMADO' THEN ' &middot; sin lanzar' ELSE '' END + '</small></div>'
              + '<div class="vct-ini-proj-bars">'
              +   '<div class="vct-ini-meter"><span>Avance</span><div class="vct-ini-track"><i style="width:' + CONVERT(VARCHAR(10), CASE WHEN P.AVANCE > 100 THEN 100 ELSE P.AVANCE END) + '%"></i></div><b>' + CONVERT(VARCHAR(10), P.AVANCE) + '%</b></div>'
              +   CASE WHEN P.CONTR > 0 THEN
                      '<div class="vct-ini-meter is-hours' + CASE WHEN P.USADAS > P.CONTR THEN ' is-over' WHEN P.USADAS >= 0.9 * P.CONTR THEN ' is-warn' ELSE '' END + '"><span>Horas</span><div class="vct-ini-track"><i style="width:'
                    + CONVERT(VARCHAR(10), CONVERT(INT, CASE WHEN P.USADAS >= P.CONTR THEN 100 ELSE 100.0 * P.USADAS / P.CONTR END)) + '%"></i></div><b>'
                    + dbo.VCT_FMT_HORAS(P.USADAS) + '/' + dbo.VCT_FMT_HORAS(P.CONTR) + '</b></div>'
                   ELSE '' END
              + '</div></div>'
            FROM #MA M INNER JOIN #P P ON P.ID = M.ID
            ORDER BY CASE WHEN P.EST = 'ENCURSO' THEN 0 ELSE 1 END, P.NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        IF @A_PROYS = '' SET @A_PROYS = REPLACE(@EMPTY_FMT, '{T}', 'No ten&eacute;s proyectos vigentes asignados.');
 
        IF @A_NPROY > 0 OR @A_AVISOS > 0 OR @A_VENC > 0
        BEGIN
        SET @NTABS = @NTABS + 1;
            SET @TABS = @TABS + '<button type="button" class="vct-ini-tab" data-vct-ini-tab="analista"><span data-vct-icon="folder"></span><span>Mis proyectos</span></button>';
            SET @PANELS = @PANELS
              + '<div class="vct-ini-panel" data-vct-ini-panel="analista">'
              + '<div class="vct-360-stats-row">'
              +   '<div class="vct-360-stat" data-vct-tone="violet"><span><span class="vct-360-stat-label">Mis proyectos</span><b>' + CONVERT(VARCHAR(10), @A_NPROY) + '</b><small>vigentes en tu equipo</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN @A_AVISOS > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Avisos abiertos</span><b>' + CONVERT(VARCHAR(10), @A_AVISOS) + '</b><small>cambios de fecha del plan</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Por lanzar</span><b>' + CONVERT(VARCHAR(10), @A_LANZ) + '</b><small>confirmados sin iniciar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="calendar"></span></span></div>'
              +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN @A_VENC > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Mis gestiones vencidas</span><b>' + CONVERT(VARCHAR(10), @A_VENC) + '</b><small>a tu cargo</small></span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
              + '</div>'
              + '<div class="vct-ini-grid">'
              +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>Avisos del plan</h3><p class="vct-360-box-subtitle">m&aacute;s nuevos primero</p></div></div><div class="vct-ini-list">' + @A_AV + '</div></div>'
              +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="folder"></span></span>Lanzamientos pendientes</h3></div></div><div class="vct-ini-list">' + @A_LZ + '</div></div>'
              + '</div>'
              + '<div class="vct-360-box vct-ini-box vct-ini-wide"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="chart-bar"></span></span>Avance y horas de mis proyectos</h3></div></div><div class="vct-ini-box-body">' + @A_PROYS + '</div></div>'
              + '</div>';
        END;
    END;
 
    /* =====================================================================
       PESTANIA: GENERAL / ADMINISTRACION (alcance total)
       ===================================================================== */
    IF @VE_TODO = 1
    BEGIN
        DECLARE @G_ENC INT = 0, @G_CONF INT = 0, @G_AV INT = 0, @G_HU DECIMAL(14,2) = 0, @G_HC DECIMAL(14,2) = 0,
                @G_PASADOS INT = 0, @G_PORAGOTAR INT = 0, @G_GABIERTAS INT = 0, @G_GVENC INT = 0, @G_CLI INT = 0,
                @G_L1 VARCHAR(MAX) = '', @G_L2 VARCHAR(MAX) = '', @G_BARS VARCHAR(MAX) = '', @G_DONUT VARCHAR(MAX) = '',
                @PT INT = 0, @PA INT = 0, @PC INT = 0, @PTE INT = 0, @PO INT = 0, @S1 INT = 0, @S2 INT = 0, @S3 INT = 0, @MAXH DECIMAL(14,2) = 0;
 
        SELECT @G_ENC = SUM(CASE WHEN EST = 'ENCURSO' THEN 1 ELSE 0 END),
               @G_CONF = SUM(CASE WHEN EST = 'CONFIRMADO' THEN 1 ELSE 0 END),
               @G_AV = ISNULL(AVG(CASE WHEN EST = 'ENCURSO' THEN AVANCE END), 0),
               @G_HU = ISNULL(SUM(CASE WHEN EST = 'ENCURSO' AND CONTR > 0 THEN USADAS END), 0),
               @G_HC = ISNULL(SUM(CASE WHEN EST = 'ENCURSO' AND CONTR > 0 THEN CONTR END), 0),
               @G_PASADOS = SUM(CASE WHEN EST = 'ENCURSO' AND CONTR > 0 AND USADAS > CONTR THEN 1 ELSE 0 END),
               @G_PORAGOTAR = SUM(CASE WHEN EST = 'ENCURSO' AND CONTR > 0 AND USADAS <= CONTR AND USADAS >= 0.8 * CONTR THEN 1 ELSE 0 END)
        FROM #P;
 
        SELECT @G_GABIERTAS = COUNT(*), @G_GVENC = SUM(CASE WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY THEN 1 ELSE 0 END)
        FROM dbo.VCT_GESTIONES G INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
        WHERE GE.ES_FINAL = 0;
 
        SELECT @G_CLI = COUNT(*) FROM dbo.VCT_CLIENTES WHERE UPPER(LTRIM(RTRIM(ISNULL(TIPO,'')))) = 'ACTIVO';
 
        IF @ES_ADMIN = 0
        BEGIN
            /* proyectos para mirar: horas, plan atrasado, sin plan con la gestion pendiente */
            SELECT @G_L1 = ISNULL((
                SELECT TOP 8
                    '<div class="vct-ini-row">'
                  + '<span class="vct-ini-row-icon ' + CASE WHEN X.SEV >= 3 THEN 'is-red' ELSE 'is-orange' END + '" data-vct-icon="chart-bar"></span>'
                  + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + X.TXT + '</span>'
                  + '<span class="vct-ini-row-meta">' + dbo.VCT_HTML_ESC(ISNULL(X.CLIENTE,'')) + ' &middot; ' + X.DET + '</span></div>'
                  + '<span class="vct-ini-pill ' + CASE WHEN X.SEV >= 3 THEN 'is-bad' WHEN X.SEV = 2 THEN 'is-warn' ELSE 'is-info' END + '">' + X.MOTIVO + '</span></div>'
                FROM
                (
                    SELECT P.ID, P.TXT, P.CLIENTE, P.NOMBRE,
                           CASE WHEN P.CONTR > 0 AND P.USADAS > P.CONTR THEN 3
                                WHEN PL.N > 0 AND PL.TM - PL.AV >= 20 THEN 3
                                WHEN P.CONTR > 0 AND P.USADAS >= 0.9 * P.CONTR THEN 2
                                ELSE 1 END AS SEV,
                           CASE WHEN P.CONTR > 0 AND P.USADAS > P.CONTR THEN 'horas ' + CONVERT(VARCHAR(10), CONVERT(INT, 100.0 * P.USADAS / P.CONTR)) + '%'
                                WHEN PL.N > 0 AND PL.TM - PL.AV >= 20 THEN 'atrasado'
                                WHEN P.CONTR > 0 AND P.USADAS >= 0.9 * P.CONTR THEN 'horas ' + CONVERT(VARCHAR(10), CONVERT(INT, 100.0 * P.USADAS / P.CONTR)) + '%'
                                ELSE 'sin plan' END AS MOTIVO,
                           CASE WHEN PL.N > 0 THEN 'tiempo ' + CONVERT(VARCHAR(10), CONVERT(INT, PL.TM)) + '% &middot; avance ' + CONVERT(VARCHAR(10), CONVERT(INT, PL.AV)) + '%'
                                WHEN P.CONTR > 0 THEN dbo.VCT_FMT_HORAS(P.USADAS) + ' de ' + dbo.VCT_FMT_HORAS(P.CONTR) + ' h'
                                ELSE 'iniciado el ' + ISNULL(CONVERT(VARCHAR(10), P.INICIO, 103), '-') END AS DET
                    FROM #P P
                    OUTER APPLY (SELECT COUNT(*) AS N, AVG(CAST(C.TIEMPO AS DECIMAL(9,2))) AS TM, AVG(CAST(C.AVANCE AS DECIMAL(9,2))) AS AV
                                 FROM dbo.VCT_PROYECTO_PLAN_CALC(P.ID) C) PL
                    WHERE P.EST = 'ENCURSO'
                      AND (   (P.CONTR > 0 AND P.USADAS >= 0.9 * P.CONTR)
                           OR (PL.N > 0 AND PL.TM - PL.AV >= 20)
                           OR (PL.N = 0 AND P.INICIO < DATEADD(DAY, -15, @HOY)
                               AND EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES G
                                           INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
                                           INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
                                           WHERE G.ID_PROYECTO = P.ID AND ST.CODIGO = 'CARGA_PLAN' AND GE.ES_FINAL = 0)))
                ) X
                ORDER BY X.SEV DESC, X.NOMBRE
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
            IF @G_L1 = '' SET @G_L1 = REPLACE(@EMPTY_FMT, '{T}', 'Ning&uacute;n proyecto en curso con horas al l&iacute;mite o plan atrasado.');
 
            /* pendientes del cliente abiertos */
            SELECT @G_L2 = ISNULL((
                SELECT TOP 8
                    '<div class="vct-ini-row">'
                  + '<span class="vct-ini-row-icon is-purple" data-vct-icon="user-check"></span>'
                  + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</span>'
                  + '<span class="vct-ini-row-meta">' + ISNULL(P.TXT, dbo.VCT_HTML_ESC(ISNULL(PX.NOMBRE,''))) + '</span></div>'
                  + CASE WHEN G.FECHA_VENCIMIENTO IS NULL THEN '<span class="vct-ini-pill is-info">sin fecha</span>'
                         WHEN CONVERT(DATE, G.FECHA_VENCIMIENTO) < @HOY THEN '<span class="vct-ini-pill is-bad">hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, CONVERT(DATE, G.FECHA_VENCIMIENTO), @HOY)) + ' d</span>'
                         WHEN CONVERT(DATE, G.FECHA_VENCIMIENTO) = @HOY THEN '<span class="vct-ini-pill is-warn">vence hoy</span>'
                         ELSE '<span class="vct-ini-pill is-info">' + CONVERT(VARCHAR(5), G.FECHA_VENCIMIENTO, 103) + '</span>' END
                  + '</div>'
                FROM dbo.VCT_GESTIONES G
                INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
                INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
                LEFT JOIN #P P ON P.ID = G.ID_PROYECTO
                LEFT JOIN dbo.VCT_PROYECTOS PX ON PX.ID = G.ID_PROYECTO
                WHERE ST.CODIGO = 'PENDIENTE_CLIENTE' AND GE.ES_FINAL = 0
                ORDER BY ISNULL(G.FECHA_VENCIMIENTO, '29991231'), G.ID
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
            IF @G_L2 = '' SET @G_L2 = REPLACE(@EMPTY_FMT, '{T}', 'Sin pendientes del cliente abiertos.');
        END
        ELSE
        BEGIN
            /* administracion: control de horas */
            SELECT @G_L1 = ISNULL((
                SELECT TOP 8
                    '<div class="vct-ini-row">'
                  + '<span class="vct-ini-row-icon ' + CASE WHEN P.USADAS > P.CONTR THEN 'is-red' ELSE 'is-orange' END + '" data-vct-icon="clock-3"></span>'
                  + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">' + P.TXT + '</span>'
                  + '<span class="vct-ini-row-meta">' + dbo.VCT_HTML_ESC(ISNULL(P.CLIENTE,'')) + ' &middot; ' + dbo.VCT_FMT_HORAS(P.USADAS) + ' de ' + dbo.VCT_FMT_HORAS(P.CONTR) + ' h'
                  +   CASE WHEN P.AGEND > 0 THEN ' &middot; ' + dbo.VCT_FMT_HORAS(P.AGEND) + ' h agendadas' ELSE '' END + '</span></div>'
                  + '<span class="vct-ini-pill ' + CASE WHEN P.USADAS > P.CONTR THEN 'is-bad' ELSE 'is-warn' END + '">' + CONVERT(VARCHAR(10), CONVERT(INT, 100.0 * P.USADAS / P.CONTR)) + '%</span></div>'
                FROM #P P
                WHERE P.EST = 'ENCURSO' AND P.CONTR > 0 AND P.USADAS >= 0.8 * P.CONTR
                ORDER BY P.USADAS / P.CONTR DESC
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
            IF @G_L1 = '' SET @G_L1 = REPLACE(@EMPTY_FMT, '{T}', 'Ning&uacute;n proyecto en curso usa m&aacute;s del 80% de sus horas.');
 
            /* terminados en los ultimos 60 dias */
            SELECT @G_L2 = ISNULL((
                SELECT TOP 8
                    '<div class="vct-ini-row">'
                  + '<span class="vct-ini-row-icon is-green" data-vct-icon="check"></span>'
                  + '<div class="vct-ini-row-main"><span class="vct-ini-row-title">'
                  +   CASE WHEN @LINK = 1 THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), P.ID) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(P.IDCLIENTE,0)) + '">' + dbo.VCT_HTML_ESC(ISNULL('(' + P.CODIGO + ') ','') + P.NOMBRE) + '</button>'
                           ELSE dbo.VCT_HTML_ESC(ISNULL('(' + P.CODIGO + ') ','') + P.NOMBRE) END + '</span>'
                  + '<span class="vct-ini-row-meta">' + dbo.VCT_HTML_ESC(ISNULL(CL.RAZON_SOCIAL,''))
                  +   CASE WHEN P.TOTAL_HORAS_PROYECTADAS > 0 THEN ' &middot; ' + CONVERT(VARCHAR(10), ISNULL(P.TOTAL_HORAS_EJECUTADAS,0)) + ' de ' + CONVERT(VARCHAR(10), P.TOTAL_HORAS_PROYECTADAS) + ' h' ELSE '' END + '</span></div>'
                  + '<span class="vct-ini-pill is-ok">' + CONVERT(VARCHAR(10), (CASE WHEN P.FECHA_FIN_REAL <= GETDATE() THEN P.FECHA_FIN_REAL ELSE P.FECHA_UPD END), 103) + '</span></div>'
                FROM dbo.VCT_PROYECTOS P
                INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
                LEFT JOIN dbo.VCT_CLIENTES CL ON CL.ID = P.IDCLIENTE
                WHERE E.CODIGO = 'TERMINADO' AND (CASE WHEN P.FECHA_FIN_REAL <= GETDATE() THEN P.FECHA_FIN_REAL ELSE P.FECHA_UPD END) >= DATEADD(DAY, -60, @HOY) AND (CASE WHEN P.FECHA_FIN_REAL <= GETDATE() THEN P.FECHA_FIN_REAL ELSE P.FECHA_UPD END) <= GETDATE()
                ORDER BY (CASE WHEN P.FECHA_FIN_REAL <= GETDATE() THEN P.FECHA_FIN_REAL ELSE P.FECHA_UPD END) DESC
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
            IF @G_L2 = '' SET @G_L2 = REPLACE(@EMPTY_FMT, '{T}', 'No se termin&oacute; ning&uacute;n proyecto en los &uacute;ltimos 60 d&iacute;as.');
        END;
 
        /* torta: proyectos por estado (todos) */
        SELECT @PT = COUNT(*),
               @PA = SUM(CASE WHEN E.CODIGO = 'ENCURSO' THEN 1 ELSE 0 END),
               @PC = SUM(CASE WHEN E.CODIGO = 'CONFIRMADO' THEN 1 ELSE 0 END),
               @PTE = SUM(CASE WHEN E.CODIGO = 'TERMINADO' THEN 1 ELSE 0 END)
        FROM dbo.VCT_PROYECTOS P LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO;
        SELECT @PA = ISNULL(@PA,0), @PC = ISNULL(@PC,0), @PTE = ISNULL(@PTE,0);
        SET @PO = @PT - @PA - @PC - @PTE;
        IF @PT > 0
        BEGIN
            SET @S1 = CONVERT(INT, ROUND(100.0 * @PA / @PT, 0));
            SET @S2 = @S1 + CONVERT(INT, ROUND(100.0 * @PC / @PT, 0));
            SET @S3 = @S2 + CONVERT(INT, ROUND(100.0 * @PTE / @PT, 0)); IF @S3 > 100 SET @S3 = 100;
        END;
        SET @G_DONUT =
            '<div class="vct-dashboard-donut-layout">'
          + '<div class="vct-dashboard-donut" style="background:conic-gradient(#69A8FF 0% ' + CONVERT(VARCHAR(10), @S1) + '%,#C59AF4 ' + CONVERT(VARCHAR(10), @S1) + '% ' + CONVERT(VARCHAR(10), @S2)
          +   '%,#82D8A2 ' + CONVERT(VARCHAR(10), @S2) + '% ' + CONVERT(VARCHAR(10), @S3) + '%,#F4BC78 ' + CONVERT(VARCHAR(10), @S3) + '% 100%);">'
          + '<div class="vct-dashboard-donut-hole"><strong>' + CONVERT(VARCHAR(10), @PT) + '</strong><span>Proyectos</span></div></div>'
          + '<div class="vct-dashboard-legend">'
          + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-blue"></span><span>En curso</span><strong>' + CONVERT(VARCHAR(10), @PA) + '</strong></div>'
          + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-purple"></span><span>Confirmados</span><strong>' + CONVERT(VARCHAR(10), @PC) + '</strong></div>'
          + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-green"></span><span>Terminados</span><strong>' + CONVERT(VARCHAR(10), @PTE) + '</strong></div>'
          + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-orange"></span><span>Otros</span><strong>' + CONVERT(VARCHAR(10), @PO) + '</strong></div>'
          + '</div></div>';
 
        /* barras: horas de visita usadas por mes (6 meses) */
        CREATE TABLE #HM (ORDEN INT, INI DATE, LBL VARCHAR(5), H DECIMAL(14,2));
        INSERT INTO #HM (ORDEN, INI, LBL, H)
        SELECT N.N + 6, DATEADD(MONTH, N.N, DATEADD(MONTH, DATEDIFF(MONTH, 0, @HOY), 0)),
               SUBSTRING('EneFebMarAbrMayJunJulAgoSepOctNovDic', (MONTH(DATEADD(MONTH, N.N, @HOY)) - 1) * 3 + 1, 3), 0
        FROM (VALUES (-5),(-4),(-3),(-2),(-1),(0)) N(N);
 
        UPDATE M SET H = ISNULL((
            SELECT SUM(CASE WHEN R.ID IS NOT NULL THEN R.HORAS
                            WHEN UPPER(LTRIM(RTRIM(ISNULL(V.ESTADO,'')))) = 'CONFIRMADO' THEN ISNULL(V.TOTAL_HORAS_EJECUTADAS,0) ELSE 0 END)
            FROM dbo.VCT_PROYECTOS_VISITAS V
            LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_REGISTRO R ON R.ID_VISITA = V.ID
            WHERE CONVERT(DATE, ISNULL(CONVERT(DATETIME, R.FECHA), V.FECHA_DESDE)) >= M.INI
              AND CONVERT(DATE, ISNULL(CONVERT(DATETIME, R.FECHA), V.FECHA_DESDE)) < DATEADD(MONTH, 1, M.INI)
              AND CONVERT(DATE, ISNULL(CONVERT(DATETIME, R.FECHA), V.FECHA_DESDE)) <= @HOY), 0)
        FROM #HM M;
        SELECT @MAXH = MAX(H) FROM #HM;
 
        SELECT @G_BARS = ISNULL((
            SELECT '<div class="vct-dashboard-bar-item"><span class="vct-dashboard-bar-value">' + dbo.VCT_FMT_HORAS(H) + '</span>'
                 + '<div class="vct-dashboard-bar-track"><span class="vct-dashboard-bar" style="--vct-dashboard-bar-height:'
                 + CONVERT(VARCHAR(10), CASE WHEN ISNULL(@MAXH,0) <= 0 OR H <= 0 THEN 6 ELSE CONVERT(INT, ROUND(100.0 * H / @MAXH, 0)) END) + '%;"></span></div>'
                 + '<span class="vct-dashboard-bar-label">' + LBL + '</span></div>'
            FROM #HM ORDER BY ORDEN
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
        SET @NTABS = @NTABS + 1;
        SET @TABS = @TABS + '<button type="button" class="vct-ini-tab" data-vct-ini-tab="general"><span data-vct-icon="chart-bar"></span><span>'
                  + CASE WHEN @ES_ADMIN = 1 THEN 'Administraci&oacute;n' ELSE 'General' END + '</span></button>';
        SET @PANELS = @PANELS
          + '<div class="vct-ini-panel" data-vct-ini-panel="general">'
          + '<div class="vct-360-stats-row">'
          + CASE WHEN @ES_ADMIN = 1 THEN
                '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Clientes activos</span><b>' + CONVERT(VARCHAR(10), @G_CLI) + '</b><small>cartera vigente</small></span><span class="vct-360-stat-icon"><span data-vct-icon="users"></span></span></div>'
            ELSE
                '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Avance promedio</span><b>' + CONVERT(VARCHAR(10), @G_AV) + '%</b><small>proyectos en curso</small></span><span class="vct-360-stat-icon"><span data-vct-icon="chart-bar"></span></span></div>'
            END
          +   '<div class="vct-360-stat" data-vct-tone="violet"><span><span class="vct-360-stat-label">Proyectos en curso</span><b>' + CONVERT(VARCHAR(10), ISNULL(@G_ENC,0)) + '</b><small>' + CONVERT(VARCHAR(10), ISNULL(@G_CONF,0)) + ' confirmados sin lanzar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span></div>'
          +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN ISNULL(@G_PASADOS,0) > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Horas usadas</span><b>'
          +     CASE WHEN @G_HC > 0 THEN CONVERT(VARCHAR(10), CONVERT(INT, ROUND(100.0 * @G_HU / @G_HC, 0))) + '%' ELSE '-' END
          +     '</b><small>' + CONVERT(VARCHAR(10), ISNULL(@G_PASADOS,0)) + ' pasado' + CASE WHEN ISNULL(@G_PASADOS,0) = 1 THEN '' ELSE 's' END + ' de horas &middot; ' + CONVERT(VARCHAR(10), ISNULL(@G_PORAGOTAR,0)) + ' por agotar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span></div>'
          + CASE WHEN @ES_ADMIN = 1 THEN
                '<div class="vct-360-stat" data-vct-tone="mint"><span><span class="vct-360-stat-label">Horas contratadas</span><b>' + dbo.VCT_FMT_HORAS(@G_HC) + '</b><small>' + dbo.VCT_FMT_HORAS(@G_HU) + ' usadas en proyectos en curso</small></span><span class="vct-360-stat-icon"><span data-vct-icon="check"></span></span></div>'
            ELSE
                '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN ISNULL(@G_GVENC,0) > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Gestiones vencidas</span><b>' + CONVERT(VARCHAR(10), ISNULL(@G_GVENC,0)) + '</b><small>de ' + CONVERT(VARCHAR(10), ISNULL(@G_GABIERTAS,0)) + ' abiertas</small></span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
            END
          + '</div>'
          + '<div class="vct-ini-grid">'
          +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="' + CASE WHEN @ES_ADMIN = 1 THEN 'clock-3' ELSE 'chart-bar' END + '"></span></span>'
          +     CASE WHEN @ES_ADMIN = 1 THEN 'Control de horas' ELSE 'Proyectos para mirar' END + '</h3><p class="vct-360-box-subtitle">'
          +     CASE WHEN @ES_ADMIN = 1 THEN 'en curso, 80% o m&aacute;s' ELSE 'horas, plan atrasado, sin plan' END + '</p></div></div><div class="vct-ini-list">' + @G_L1 + '</div></div>'
          +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="' + CASE WHEN @ES_ADMIN = 1 THEN 'check' ELSE 'user-check' END + '"></span></span>'
          +     CASE WHEN @ES_ADMIN = 1 THEN 'Terminados recientes' ELSE 'Pendientes del cliente' END + '</h3><p class="vct-360-box-subtitle">'
          +     CASE WHEN @ES_ADMIN = 1 THEN '&uacute;ltimos 60 d&iacute;as' ELSE 'abiertos, por fecha' END + '</p></div></div><div class="vct-ini-list">' + @G_L2 + '</div></div>'
          + '</div>'
          + '<div class="vct-ini-grid vct-dashboard-option-b">'
          +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="folder"></span></span>Proyectos por estado</h3></div></div><div class="vct-ini-box-body">' + @G_DONUT + '</div></div>'
          +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>Horas de visita por mes</h3><p class="vct-360-box-subtitle">usadas, &uacute;ltimos 6 meses</p></div></div><div class="vct-ini-box-body"><div class="vct-dashboard-bars">' + @G_BARS + '</div></div></div>'
          + '</div>'
          + '</div>';
    END;
 
    /* ---------- sin nada que mostrar ---------- */
    IF @NTABS = 0
        SET @PANELS =
            '<div class="vct-ini-panel" data-vct-ini-panel="vacio"><div class="vct-360-box vct-ini-box"><div class="vct-ini-box-body">'
          + '<div class="vct-ini-empty">'
          + CASE WHEN @CONS_ID IS NOT NULL OR @EMP_ID IS NOT NULL
                 THEN 'No ten&eacute;s proyectos vigentes, visitas ni gestiones pendientes.'
                 ELSE 'Tu usuario todav&iacute;a no tiene un inicio configurado. Si sos consultor o empleado, pedile a Gerencia que vincule tu usuario en tu ficha.' END
          + '</div>'
          + '</div></div></div>';
 
    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'')
      + '<link rel="stylesheet" href="../css/vct-inicio.css?v=5"><script src="../js/vct-inicio.js?v=4"></script>'
      + '<div class="vct-page vct-360-module vct-360-visual-final vct-inicio" data-vct-page data-vct-inicio data-vct-dashboard="option-b"'
      + ' data-vct-sidebar-id="' + CONVERT(VARCHAR(20), ISNULL(@SIDEBAR_ID,0)) + '" data-vct-form-id="' + ISNULL(@FORM_ID,'') + '"'
      + ' data-vct-ini-guid="' + @GUID_P + '" data-vct-ini-user="' + dbo.VCT_HTML_ESC(LOWER(ISNULL(@IAGENTE,''))) + '">'
      + '<input type="hidden" name="SP.IDSELEC01" data-vct-field="IDSELEC01" value="">'
      + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="">'
      + '<div class="vct-360-content-shell">'
      + '<div class="vct-ini-top">'
      + CASE WHEN @NOMBRE <> '' THEN '<p class="vct-ini-hello">Hola, ' + dbo.VCT_HTML_ESC(@NOMBRE) + '.</p>' ELSE '<p class="vct-ini-hello"></p>' END
      + ISNULL(@BELL, '')
      + '</div>'
      + CASE WHEN @NTABS > 1 THEN '<div class="vct-360-tabsbar vct-ini-tabs" data-vct-ini-tabs>' + @TABS + '</div>' ELSE '' END
      + @PANELS
      + '</div></div>';
END
