/* ========================================================================
   PROYECTOS_FIX_TIMEOUT_1  —  arregla el timeout de VCT_MAIN_PROYECTOS
   ------------------------------------------------------------------------
   CAUSA (diagnosticada): el SP llamaba dbo.VCT_HTML_ESC (UDF ESCALAR) ~13.000
   veces (862 proyectos x ~15 columnas). En compat 140 el UDF escalar NO se
   inlinea -> ejecucion serial, overhead por invocacion -> timeout (>30s).
   Medido: el MISMO gather con REPLACE inline (sin UDF) = 94 ms.

   FIX: no se llama mas a VCT_HTML_ESC en el camino caliente.
     1) #P junta los valores CRUDOS (columnas de texto como VARCHAR(MAX) para
        que el escape no trunque).
     2) un UNICO UPDATE set-based escapa esas columnas con REPLACE inline
        (una pasada sobre 862 filas = instantaneo).
     3) el armado de @ROWS usa las columnas YA escapadas (cero UDF).
   Semantica de salida identica a la version previa (REPLACE inline produce el
   mismo HTML que VCT_HTML_ESC). Compat 100 y 140. Re-ejecutable (CREATE OR ALTER).

   NOTA: partir de la version vigente del server. Si el SP en el server difiere
   de PROYECTOS_GRILLA_1.sql, avisar antes de aplicar.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.VCT_MAIN_PROYECTOS
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
    SET @OUTPARAM2 = NULL;
    SET @OUTPARAM3 = NULL;

    DECLARE @HTML_SHELL VARCHAR(MAX) = '', @RES VARCHAR(20) = '',
            @PERFIL VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@IUNIDAD,'')))),
            @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @CONS_ID INT, @EMP_ID INT, @VE_TODO BIT = 0, @LINK BIT = 0,
            @GUID_P VARCHAR(50) = '330B876D-4E57-4E2E-BFC3-D7B998D09725';

    SET @VE_TODO = CASE WHEN @PERFIL IN ('GERENCIA','SQUAD','ADMINISTRACION','PROYECTOS') THEN 1 ELSE 0 END;

    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @FORM_ID = @FORM_ID,
             @TITLE = 'Proyectos', @SUBTITLE = 'Listado de proyectos: estado, servicios, analista y avance.',
             @SEARCH_PLACEHOLDER = '', @SHOW_SEARCH = 0,
             @OSHELL = @HTML_SHELL OUTPUT, @ORESULTADO = @RES OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
    END CATCH;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'CLIENTES') A WHERE A.ACTION_TYPE = 'VIEW') SET @LINK = 1;
    END TRY
    BEGIN CATCH
        SET @LINK = 0;
    END CATCH;

    SELECT TOP 1 @CONS_ID = ID FROM dbo.VCT_CONSULTORES
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO' ORDER BY ID DESC;
    SELECT TOP 1 @EMP_ID = ID FROM dbo.VCT_EMPLEADOS
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO' ORDER BY ID DESC;

    /* ---------- datos (CRUDOS; texto en VARCHAR(MAX) para que el escape no trunque) ---------- */
    IF OBJECT_ID('tempdb..#P') IS NOT NULL DROP TABLE #P;
    CREATE TABLE #P (
        ID INT, ID_CLIENTE INT, CODIGO VARCHAR(MAX), NOMBRE VARCHAR(MAX), REFERENCIA VARCHAR(MAX),
        CLIENTE VARCHAR(MAX), EST_COD VARCHAR(50), ESTADO VARCHAR(MAX), ANALISTA VARCHAR(MAX),
        SERV_HTML VARCHAR(MAX), SERV_TXT VARCHAR(MAX), FINI DATETIME, FFIN DATETIME, AVANCE INT
    );

    INSERT INTO #P
    SELECT
        P.ID, P.IDCLIENTE, CONVERT(VARCHAR(100), P.CODIGO), CONVERT(VARCHAR(300), P.NOMBRE),
        CONVERT(VARCHAR(300), ISNULL(P.REFERENCIA,'')),
        CONVERT(VARCHAR(300), ISNULL(NULLIF(C.RAZON_SOCIAL,''),'Sin cliente')),
        PE.CODIGO, PE.DESCRIPCION,
        (SELECT TOP 1 LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + CASE WHEN ISNULL(E.NOMBRES,'')<>'' THEN ', '+E.NOMBRES ELSE '' END))
         FROM dbo.VCT_PROYECTOS_EQUIPO EQ
         JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
         JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
         WHERE EQ.ID_PROYECTO = P.ID AND R.CODIGO = 'ANALISTA' AND ISNULL(EQ.ESTADO,'ACTIVO')='ACTIVO'),
        /* SERV_HTML: chips, escapando la descripcion con REPLACE inline (sin UDF) */
        ISNULL((SELECT
             '<span class="vct-serv-chip ' +
             CASE WHEN UPPER(PS.DESCRIPCION) LIKE '%AUDITOR%' THEN 'is-auditoria'
                  WHEN UPPER(PS.DESCRIPCION) LIKE '%CAPACIT%' THEN 'is-capacitacion'
                  WHEN UPPER(PS.DESCRIPCION) LIKE '%CONSULT%' THEN 'is-consultoria'
                  ELSE 'is-neutral' END + '" style="margin:1px 3px 1px 0;">'
           + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')
           + '</span>'
         FROM dbo.VCT_PROYECTOS_SERVICIOS XS
         JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = XS.ID_SERVICIO
         WHERE XS.ID_PROYECTO = P.ID
         ORDER BY PS.DESCRIPCION
         FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),
        /* SERV_TXT: crudo (se escapa despues en el UPDATE set-based) */
        ISNULL((SELECT ' ' + PS.DESCRIPCION
         FROM dbo.VCT_PROYECTOS_SERVICIOS XS
         JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = XS.ID_SERVICIO
         WHERE XS.ID_PROYECTO = P.ID
         FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),
        P.FECHA_INICIO, P.FECHA_FIN, ISNULL(P.PORCENTAJE_AVANCE,0)
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS PE ON PE.ID = P.ID_ESTADO
    WHERE
        @VE_TODO = 1
        OR (@CONS_ID IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ
             WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = @CONS_ID AND ISNULL(EQ.ESTADO,'ACTIVO')='ACTIVO'))
        OR (@EMP_ID IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ
             WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ID_EMPLEADO = @EMP_ID AND ISNULL(EQ.ESTADO,'ACTIVO')='ACTIVO'));

    /* ---------- escape set-based (una pasada, sin UDF) ---------- */
    UPDATE #P SET
        CODIGO     = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        NOMBRE     = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NOMBRE,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        REFERENCIA = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        CLIENTE    = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        ANALISTA   = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ANALISTA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        ESTADO     = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ESTADO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
        SERV_TXT   = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(SERV_TXT,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');

    /* ---------- KPIs ---------- */
    DECLARE @K_TOT INT, @K_CURSO INT, @K_CONF INT, @K_TERM INT;
    SELECT @K_TOT = COUNT(*),
           @K_CURSO = SUM(CASE WHEN EST_COD='ENCURSO' THEN 1 ELSE 0 END),
           @K_CONF  = SUM(CASE WHEN EST_COD='CONFIRMADO' THEN 1 ELSE 0 END),
           @K_TERM  = SUM(CASE WHEN EST_COD='TERMINADO' THEN 1 ELSE 0 END)
    FROM #P;
    SET @K_TOT=ISNULL(@K_TOT,0); SET @K_CURSO=ISNULL(@K_CURSO,0); SET @K_CONF=ISNULL(@K_CONF,0); SET @K_TERM=ISNULL(@K_TERM,0);

    /* ---------- grilla (columnas YA escapadas: sin VCT_HTML_ESC) ---------- */
    DECLARE @ROWS VARCHAR(MAX);
    SELECT @ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-key="' + CONVERT(VARCHAR(20), P.ID) + '"'
          + ' data-vct-search="' + (ISNULL(P.CODIGO,'') + ' ' + ISNULL(P.NOMBRE,'') + ' ' + ISNULL(P.REFERENCIA,'') + ' ' + ISNULL(P.CLIENTE,'') + ' ' + ISNULL(P.ANALISTA,'') + ' ' + ISNULL(P.SERV_TXT,'')) + '"'
          + ' data-vct-filter-estado="' + ISNULL(P.EST_COD,'') + '"'
          + ' data-vct-filter-servicio="' + LTRIM(RTRIM(ISNULL(P.SERV_TXT,''))) + '">'
          + '<td data-label="C&oacute;digo" data-vct-sort-value="' + ISNULL(P.CODIGO,'') + '">' + ISNULL(NULLIF(P.CODIGO,''),'-') + '</td>'
          + '<td data-label="Proyecto" data-vct-sort-value="' + ISNULL(P.NOMBRE,'') + '">'
          +   CASE WHEN @LINK = 1 THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), P.ID) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(P.ID_CLIENTE,0)) + '">' + ISNULL(NULLIF(P.NOMBRE,''),'(sin nombre)') + '</button>'
                   ELSE '<b>' + ISNULL(NULLIF(P.NOMBRE,''),'(sin nombre)') + '</b>' END
          +   CASE WHEN ISNULL(P.REFERENCIA,'') <> '' THEN '<small class="vct-acc-sub">' + P.REFERENCIA + '</small>' ELSE '' END + '</td>'
          + '<td data-label="Cliente" data-vct-sort-value="' + ISNULL(P.CLIENTE,'') + '">' + ISNULL(NULLIF(P.CLIENTE,''),'-') + '</td>'
          + '<td data-label="Servicios">' + CASE WHEN ISNULL(P.SERV_HTML,'') = '' THEN '<span class="vct-acc-muted">-</span>' ELSE P.SERV_HTML END + '</td>'
          + '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' + ISNULL(P.EST_COD,'') + '"><span class="vct-ini-pill '
          +   CASE P.EST_COD WHEN 'ENCURSO' THEN 'is-ok">En curso' WHEN 'TERMINADO' THEN 'is-info">Terminado'
                             WHEN 'CANCELADO' THEN 'is-bad">Cancelado' WHEN 'CONFIRMADO' THEN 'is-warn">Confirmado'
                             WHEN 'PAUSADO' THEN 'is-warn">Pausado' WHEN 'BORRADOR' THEN 'is-info">Borrador'
                             ELSE 'is-info">' + ISNULL(NULLIF(P.ESTADO,''),'-') END + '</span></td>'
          + '<td data-label="Analista" data-vct-sort-value="' + ISNULL(P.ANALISTA,'') + '">' + CASE WHEN ISNULL(P.ANALISTA,'') = '' THEN '<span class="vct-acc-muted">-</span>' ELSE P.ANALISTA END + '</td>'
          + '<td class="vct-text-center" data-label="Inicio" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), P.FINI, 112),'99991231') + '">' + CASE WHEN P.FINI IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), P.FINI, 103) END + '</td>'
          + '<td class="vct-text-center" data-label="Fin" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), P.FFIN, 112),'99991231') + '">' + CASE WHEN P.FFIN IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), P.FFIN, 103) END + '</td>'
          + '<td class="vct-text-center" data-label="Avance" data-vct-sort-value="' + CONVERT(VARCHAR(5), P.AVANCE) + '" data-vct-sort-type="number">'
          +   '<div class="vct-360-progress"><div class="vct-360-progress-bar" style="background:#66062D !important;width:' + CONVERT(VARCHAR(5), CASE WHEN P.AVANCE<0 THEN 0 WHEN P.AVANCE>100 THEN 100 ELSE P.AVANCE END) + '%;"></div></div>'
          +   '<span class="vct-360-progress-label">' + CONVERT(VARCHAR(5), P.AVANCE) + '%</span></td>'
          + '</tr>'
        FROM #P P
        ORDER BY CASE P.EST_COD WHEN 'ENCURSO' THEN 0 WHEN 'CONFIRMADO' THEN 1 WHEN 'PAUSADO' THEN 2 WHEN 'BORRADOR' THEN 3 WHEN 'TERMINADO' THEN 4 ELSE 5 END,
                 P.FINI DESC, P.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    IF @ROWS IS NULL OR @ROWS = ''
        SET @ROWS = '';

    /* ---------- filtro de servicios (opciones; REPLACE inline, solo pocas filas) ---------- */
    DECLARE @FILTRO_SERV VARCHAR(MAX) = ISNULL((
        SELECT '<option value="' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '">'
             + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</option>'
        FROM dbo.VCT_PRM_SERVICIOS PS WHERE UPPER(ISNULL(PS.ESTADO,'ACTIVO'))='ACTIVO'
        ORDER BY PS.DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    DECLARE @HTML VARCHAR(MAX) =
        CONVERT(VARCHAR(MAX), '<link rel="stylesheet" href="../css/vct-inicio.css?v=5"><script src="../js/vct-inicio.js?v=4"></script>')
      + '<style>.vct-proy .vct-acc-sub{display:block;margin-top:2px;color:#64748b;font-size:11px}.vct-proy .vct-acc-muted{color:#94a3b8}'
      + '.vct-proy .vct-serv-chip{margin:1px 3px 1px 0}</style>'
      + '<div class="vct-page vct-360-module vct-360-visual-final vct-inicio vct-proy" data-vct-page data-vct-inicio data-vct-sidebar-id="3"'
      + ' data-vct-form-id="' + ISNULL(@FORM_ID,'') + '" data-vct-ini-guid="' + @GUID_P + '" data-vct-ini-user="' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@U,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '">'
      + '<input type="hidden" name="SP.IDSELEC01" data-vct-field="IDSELEC01" value="">'
      + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="">'
      + '<div class="vct-360-content-shell">'
      + '<div class="vct-360-stats-row">'
      +   '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Proyectos</span><b>' + CONVERT(VARCHAR(10), @K_TOT) + '</b><small>en total</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="violet"><span><span class="vct-360-stat-label">En curso</span><b>' + CONVERT(VARCHAR(10), @K_CURSO) + '</b><small>activos</small></span><span class="vct-360-stat-icon"><span data-vct-icon="play"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="amber"><span><span class="vct-360-stat-label">Por lanzar</span><b>' + CONVERT(VARCHAR(10), @K_CONF) + '</b><small>confirmados</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="mint"><span><span class="vct-360-stat-label">Terminados</span><b>' + CONVERT(VARCHAR(10), @K_TERM) + '</b><small>cerrados</small></span><span class="vct-360-stat-icon"><span data-vct-icon="check"></span></span></div>'
      + '</div>'
      + '<div class="vct-360-box vct-ini-box"><div class="vct-ini-box-body">'
      +   '<div data-vct-dg data-vct-dg-id="proyectos" data-vct-dg-title="Proyectos" data-vct-dg-subtitle="En curso primero" data-vct-dg-unit="proyecto(s)" data-vct-dg-page-size="15"'
      +   ' data-vct-dg-search-placeholder="Buscar proyecto, c&oacute;digo, cliente, analista..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
      +   '<div data-vct-dg-slot="filters">'
      +     '<select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Estado">'
      +       '<option value="">Todos los estados</option><option value="ENCURSO">En curso</option><option value="CONFIRMADO">Confirmados</option>'
      +       '<option value="BORRADOR">Borrador</option><option value="PAUSADO">Pausados</option><option value="TERMINADO">Terminados</option><option value="CANCELADO">Cancelados</option></select>'
      +     CASE WHEN @FILTRO_SERV <> '' THEN '<select class="vct-select vct-select-sm" data-vct-dg-filter="servicio" aria-label="Servicio"><option value="">Todos los servicios</option>' + @FILTRO_SERV + '</select>' ELSE '' END
      +   '</div>'
      +   '<table><thead><tr>'
      +     '<th data-vct-width="9%" data-vct-sort="codigo" data-vct-sortable="true"><span>C&oacute;digo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-width="15%" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-width="15%"><span>Servicios</span></th>'
      +     '<th class="vct-text-center" data-vct-width="10%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-width="13%" data-vct-sort="analista" data-vct-sortable="true"><span>Analista</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="9%" data-vct-sort="inicio" data-vct-sortable="true" data-vct-sort-type="date"><span>Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="9%" data-vct-sort="fin" data-vct-sortable="true" data-vct-sort-type="date"><span>Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="10%" data-vct-sort="avance" data-vct-sortable="true" data-vct-sort-type="number"><span>Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +   '</tr></thead><tbody>' + @ROWS + '</tbody></table>'
      +   '</div>'
      + '</div></div>'
      + '</div>';

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @HTML;
END
GO

PRINT 'OK: VCT_MAIN_PROYECTOS reescrito sin UDF escalar (escape REPLACE inline + UPDATE set-based).';
GO
