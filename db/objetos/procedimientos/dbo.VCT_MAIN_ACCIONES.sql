 
CREATE   PROCEDURE dbo.VCT_MAIN_ACCIONES
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
 
    DECLARE @HTML_SHELL VARCHAR(MAX) = '', @RES VARCHAR(20) = '', @HOY DATE = CONVERT(DATE, GETDATE()),
            @PERFIL VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@IUNIDAD,'')))),
            @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @CONS_ID INT, @EMP_ID INT, @VE_TODO BIT = 0, @LINK BIT = 0,
            @GUID_P VARCHAR(50) = '330B876D-4E57-4E2E-BFC3-D7B998D09725',
            @SUBT VARCHAR(200);
 
    SET @VE_TODO = CASE WHEN @PERFIL IN ('GERENCIA','SQUAD','ADMINISTRACION','PROYECTOS') THEN 1 ELSE 0 END;
    SET @SUBT = CASE WHEN @VE_TODO = 1 THEN 'Gestiones de todos los proyectos: qu' + CHAR(233) + ' est' + CHAR(225) + ' abierto, vencido y cumplido.'
                     ELSE 'Tus gestiones: lo que ten' + CHAR(233) + 's abierto y lo que se vence.' END;
 
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @FORM_ID = @FORM_ID,
             @TITLE = 'Acciones', @SUBTITLE = @SUBT, @SEARCH_PLACEHOLDER = '', @SHOW_SEARCH = 0,
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
 
    /* ---------- comando: marcar cumplida / reabrir (lo manda el boton via goto) ---------- */
    DECLARE @PUEDE_CERRAR BIT = CASE WHEN @PERFIL IN ('GERENCIA','SQUAD','PROYECTOS') THEN 1 ELSE 0 END,
            @MSG VARCHAR(500) = '', @ERR VARCHAR(500) = '', @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100), @NUEVO VARCHAR(20);
    SELECT TOP 1 @FLAG = ISNULL(FLAG01,''), @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
           @SEL3 = LTRIM(RTRIM(ISNULL(IDSELEC03,''))), @NUEVO = UPPER(LTRIM(RTRIM(ISNULL(TEXTO11,''))))
    FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
    IF @FLAG = '1' AND @CMD = 'ACC_ESTADO'
    BEGIN
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL WHERE PAR_KEY = @IPKEYJOB;
        DECLARE @ID_GE INT = NULL, @EST_ANT INT, @ID_PROY_GE INT, @TIT_GE VARCHAR(300), @ES_MIA BIT = 0,
                @G_CUMP INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'CUMPLIDA'),
                @G_PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
                @G_RES  INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE CODIGO = 'COMPLETADA'),
                @EST_NUEVO INT;
        IF @SEL3 <> '' AND PATINDEX('%[^0-9]%', @SEL3) = 0 AND LEN(@SEL3) <= 9
            SELECT @ID_GE = G.ID, @EST_ANT = G.ID_ESTADO, @ID_PROY_GE = G.ID_PROYECTO, @TIT_GE = G.TITULO,
                   @ES_MIA = CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE' AND GP.ESTADO = 'ACTIVO'
                                               AND ((GP.TIPO_ENTIDAD = 'CONSULTOR' AND GP.ID_ENTIDAD = @CONS_ID) OR (GP.TIPO_ENTIDAD = 'EMPLEADO' AND GP.ID_ENTIDAD = @EMP_ID)))
                                  THEN 1 ELSE 0 END
            FROM dbo.VCT_GESTIONES G WHERE G.ID = CONVERT(INT, @SEL3);
        SET @EST_NUEVO = CASE @NUEVO WHEN 'CUMPLIDA' THEN @G_CUMP WHEN 'PENDIENTE' THEN @G_PEND END;
        IF @ID_GE IS NULL SET @ERR = 'No se encontr' + CHAR(243) + ' la gesti' + CHAR(243) + 'n.'
        ELSE IF @PUEDE_CERRAR = 0 AND @ES_MIA = 0 SET @ERR = 'Solo pod' + CHAR(233) + 's cerrar gestiones a tu cargo.'
        ELSE IF @EST_NUEVO IS NULL SET @ERR = 'Estado no reconocido.'
        ELSE
        BEGIN TRY
            BEGIN TRANSACTION;
                UPDATE dbo.VCT_GESTIONES
                   SET ID_ESTADO = @EST_NUEVO,
                       ID_RESULTADO = CASE WHEN @NUEVO = 'CUMPLIDA' THEN ISNULL(@G_RES, ID_RESULTADO) ELSE NULL END,
                       FECHA_CIERRE = CASE WHEN @NUEVO = 'CUMPLIDA' THEN GETDATE() ELSE NULL END,
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_GE;
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@ID_GE, @EST_ANT, @EST_NUEVO, 'CAMBIO_ESTADO',
                        CASE WHEN @NUEVO = 'CUMPLIDA' THEN 'Gestion cumplida (Acciones).' ELSE 'Gestion reabierta (Acciones).' END, 'USUARIO', GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
            IF @ID_PROY_GE IS NOT NULL AND OBJECT_ID('dbo.VCT_PROYECTO_AVANCE_SYNC') IS NOT NULL
                EXEC dbo.VCT_PROYECTO_AVANCE_SYNC @ID_PROYECTO = @ID_PROY_GE;
            SET @MSG = CASE WHEN @NUEVO = 'CUMPLIDA' THEN 'Gesti' + CHAR(243) + 'n cumplida: ' ELSE 'Gesti' + CHAR(243) + 'n reabierta: ' END + LEFT(@TIT_GE, 200);
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @ERR = LEFT('No se pudo grabar: ' + ERROR_MESSAGE(), 500);
        END CATCH;
    END;
 
    /* ---------- gestiones del alcance ---------- */
    CREATE TABLE #G (ID INT PRIMARY KEY, TITULO VARCHAR(300), TIPO VARCHAR(100), TIPO_COD VARCHAR(50), SUBTIPO_COD VARCHAR(50),
                     EST_COD VARCHAR(50), EST_DESC VARCHAR(100), ES_FINAL BIT, CREADA DATETIME, VENCE DATETIME, CIERRE DATETIME,
                     ID_PROYECTO INT, ID_CLIENTE INT, PROY_TXT VARCHAR(400), CLIENTE VARCHAR(300), RESPONSABLE VARCHAR(300),
                     MIA BIT, SITUACION VARCHAR(20));
 
    INSERT INTO #G (ID, TITULO, TIPO, TIPO_COD, SUBTIPO_COD, EST_COD, EST_DESC, ES_FINAL, CREADA, VENCE, CIERRE, ID_PROYECTO, ID_CLIENTE,
                    PROY_TXT, CLIENTE, RESPONSABLE, MIA)
    SELECT G.ID, ISNULL(NULLIF(LTRIM(RTRIM(G.TITULO)),''), 'Gesti' + CHAR(243) + 'n'),
           ISNULL(ST.DESCRIPCION, T.DESCRIPCION), T.CODIGO, ST.CODIGO, GE.CODIGO, GE.DESCRIPCION, ISNULL(GE.ES_FINAL, 0),
           G.FECHA_CREACION, G.FECHA_VENCIMIENTO, G.FECHA_CIERRE, G.ID_PROYECTO, ISNULL(P.IDCLIENTE, G.ID_CLIENTE),
           CASE WHEN P.ID IS NOT NULL THEN ISNULL('(' + P.CODIGO + ') ', '') + P.NOMBRE END, CL.RAZON_SOCIAL,
           RS.NOMBRE,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE' AND GP.ESTADO = 'ACTIVO'
                                AND ((GP.TIPO_ENTIDAD = 'CONSULTOR' AND GP.ID_ENTIDAD = @CONS_ID) OR (GP.TIPO_ENTIDAD = 'EMPLEADO' AND GP.ID_ENTIDAD = @EMP_ID)))
                THEN 1 ELSE 0 END
    FROM dbo.VCT_GESTIONES G
    LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T ON T.ID = G.ID_TIPO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PROYECTOS P ON P.ID = G.ID_PROYECTO
    LEFT JOIN dbo.VCT_CLIENTES CL ON CL.ID = ISNULL(P.IDCLIENTE, G.ID_CLIENTE)
    OUTER APPLY
    (
        SELECT TOP 1 CASE GP.TIPO_ENTIDAD
                        WHEN 'CONSULTOR' THEN (SELECT LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,''))) FROM dbo.VCT_CONSULTORES CO WHERE CO.ID = GP.ID_ENTIDAD)
                        WHEN 'EMPLEADO'  THEN (SELECT LTRIM(RTRIM(ISNULL(EM.APELLIDOS,'') + ', ' + ISNULL(EM.NOMBRES,''))) FROM dbo.VCT_EMPLEADOS EM WHERE EM.ID = GP.ID_ENTIDAD)
                        WHEN 'CLIENTE'   THEN 'Cliente'
                     END AS NOMBRE
        FROM dbo.VCT_GESTIONES_PARTICIPANTES GP
        WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE' AND GP.ESTADO = 'ACTIVO'
        ORDER BY GP.PRINCIPAL DESC, GP.ID
    ) RS
    WHERE (ISNULL(GE.ES_FINAL, 0) = 0 OR ISNULL(G.FECHA_CIERRE, G.FECHA_CREACION) >= DATEADD(DAY, -180, @HOY));
 
    IF @VE_TODO = 0 DELETE FROM #G WHERE MIA = 0;
 
    UPDATE #G SET SITUACION =
        CASE WHEN ES_FINAL = 1 AND EST_COD = 'CANCELADA' THEN 'CANCELADA'
             WHEN ES_FINAL = 1 THEN 'CUMPLIDA'
             WHEN VENCE IS NOT NULL AND CONVERT(DATE, VENCE) < @HOY THEN 'VENCIDA'
             WHEN VENCE IS NOT NULL AND CONVERT(DATE, VENCE) <= DATEADD(DAY, 7, @HOY) THEN 'PROXIMA'
             ELSE 'ABIERTA' END;
 
    /* ---------- KPIs ---------- */
    DECLARE @K_AB INT = 0, @K_VE INT = 0, @K_PR INT = 0, @K_CU INT = 0, @K_MIAS INT = 0, @K_SINF INT = 0;
    SELECT @K_AB = SUM(CASE WHEN SITUACION IN ('ABIERTA','PROXIMA','VENCIDA') THEN 1 ELSE 0 END),
           @K_VE = SUM(CASE WHEN SITUACION = 'VENCIDA' THEN 1 ELSE 0 END),
           @K_PR = SUM(CASE WHEN SITUACION = 'PROXIMA' THEN 1 ELSE 0 END),
           @K_CU = SUM(CASE WHEN SITUACION = 'CUMPLIDA' AND CIERRE >= DATEADD(MONTH, DATEDIFF(MONTH, 0, @HOY), 0) THEN 1 ELSE 0 END),
           @K_MIAS = SUM(CASE WHEN MIA = 1 AND SITUACION IN ('ABIERTA','PROXIMA','VENCIDA') THEN 1 ELSE 0 END),
           @K_SINF = SUM(CASE WHEN SITUACION = 'ABIERTA' AND VENCE IS NULL THEN 1 ELSE 0 END)
    FROM #G;
    SELECT @K_AB = ISNULL(@K_AB,0), @K_VE = ISNULL(@K_VE,0), @K_PR = ISNULL(@K_PR,0), @K_CU = ISNULL(@K_CU,0), @K_MIAS = ISNULL(@K_MIAS,0), @K_SINF = ISNULL(@K_SINF,0);
 
    /* ---------- torta: abiertas por situacion ---------- */
    DECLARE @D_AL INT = @K_AB - @K_VE - @K_PR, @S1 INT = 0, @S2 INT = 0, @DONUT VARCHAR(MAX);
    IF @K_AB > 0
    BEGIN
        SET @S1 = CONVERT(INT, ROUND(100.0 * @K_VE / @K_AB, 0));
        SET @S2 = @S1 + CONVERT(INT, ROUND(100.0 * @K_PR / @K_AB, 0)); IF @S2 > 100 SET @S2 = 100;
    END;
    SET @DONUT =
        '<div class="vct-dashboard-donut-layout">'
      + '<div class="vct-dashboard-donut" style="background:' + CASE WHEN @K_AB = 0 THEN '#EEF2F7' ELSE 'conic-gradient(#F87171 0% ' + CONVERT(VARCHAR(10), @S1) + '%,#F4BC78 ' + CONVERT(VARCHAR(10), @S1) + '% ' + CONVERT(VARCHAR(10), @S2) + '%,#82D8A2 ' + CONVERT(VARCHAR(10), @S2) + '% 100%)' END + ';">'
      + '<div class="vct-dashboard-donut-hole"><strong>' + CONVERT(VARCHAR(10), @K_AB) + '</strong><span>Abiertas</span></div></div>'
      + '<div class="vct-dashboard-legend">'
      + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot" style="background:#F87171"></span><span>Vencidas</span><strong>' + CONVERT(VARCHAR(10), @K_VE) + '</strong></div>'
      + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-orange"></span><span>Vencen en 7 d&iacute;as</span><strong>' + CONVERT(VARCHAR(10), @K_PR) + '</strong></div>'
      + '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-green"></span><span>Al d&iacute;a</span><strong>' + CONVERT(VARCHAR(10), @D_AL) + '</strong></div>'
      + '</div></div>';
 
    /* ---------- barras: cumplidas por mes (6 meses) ---------- */
    CREATE TABLE #M (ORDEN INT, INI DATE, LBL VARCHAR(5), N INT);
    INSERT INTO #M (ORDEN, INI, LBL, N)
    SELECT X.N + 6, DATEADD(MONTH, X.N, DATEADD(MONTH, DATEDIFF(MONTH, 0, @HOY), 0)),
           SUBSTRING('EneFebMarAbrMayJunJulAgoSepOctNovDic', (MONTH(DATEADD(MONTH, X.N, @HOY)) - 1) * 3 + 1, 3), 0
    FROM (VALUES (-5),(-4),(-3),(-2),(-1),(0)) X(N);
    UPDATE M SET N = (SELECT COUNT(*) FROM #G G WHERE G.SITUACION = 'CUMPLIDA' AND G.CIERRE >= M.INI AND G.CIERRE < DATEADD(MONTH, 1, M.INI))
    FROM #M M;
    DECLARE @MAXN INT = (SELECT MAX(N) FROM #M), @BARS VARCHAR(MAX);
    SELECT @BARS = ISNULL((
        SELECT '<div class="vct-dashboard-bar-item"><span class="vct-dashboard-bar-value">' + CONVERT(VARCHAR(10), N) + '</span>'
             + '<div class="vct-dashboard-bar-track"><span class="vct-dashboard-bar" style="--vct-dashboard-bar-height:'
             + CONVERT(VARCHAR(10), CASE WHEN ISNULL(@MAXN,0) <= 0 OR N <= 0 THEN 6 ELSE CONVERT(INT, ROUND(100.0 * N / @MAXN, 0)) END) + '%;"></span></div>'
             + '<span class="vct-dashboard-bar-label">' + LBL + '</span></div>'
        FROM #M ORDER BY ORDEN
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    /* ---------- grilla ---------- */
    DECLARE @ROWS VARCHAR(MAX);
    SELECT @ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-key="' + CONVERT(VARCHAR(20), G.ID) + '"'
          + ' data-vct-search="' + dbo.VCT_HTML_ESC(G.TITULO + ' ' + ISNULL(G.PROY_TXT,'') + ' ' + ISNULL(G.CLIENTE,'') + ' ' + ISNULL(G.RESPONSABLE,'') + ' ' + ISNULL(G.TIPO,'')) + '"'
          + ' data-vct-filter-situacion="' + G.SITUACION + '"'
          + ' data-vct-filter-tipo="' + CASE WHEN G.SUBTIPO_COD = 'PENDIENTE_CLIENTE' THEN 'PENDIENTE' WHEN G.TIPO_COD = 'AVISO' THEN 'AVISO' WHEN G.ID_PLAN_ITEM_FLAG = 1 THEN 'PLAN' ELSE 'OTRA' END + '"'
          + ' data-vct-filter-mias="' + CASE WHEN G.MIA = 1 THEN '1' ELSE '0' END + '">'
          + '<td data-label="Gesti&oacute;n" data-vct-sort-value="' + dbo.VCT_HTML_ESC(G.TITULO) + '"><b class="vct-acc-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</b>'
          +   CASE WHEN ISNULL(G.TIPO,'') <> '' THEN '<small class="vct-acc-sub">' + dbo.VCT_HTML_ESC(G.TIPO) + '</small>' ELSE '' END + '</td>'
          + '<td data-label="Proyecto" data-vct-sort-value="' + dbo.VCT_HTML_ESC(ISNULL(G.PROY_TXT,'')) + '">'
          +   CASE WHEN G.ID_PROYECTO IS NULL THEN '<span class="vct-acc-muted">-</span>'
                   WHEN @LINK = 1 THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), G.ID_PROYECTO) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(G.ID_CLIENTE,0)) + '">' + dbo.VCT_HTML_ESC(G.PROY_TXT) + '</button>'
                   ELSE dbo.VCT_HTML_ESC(G.PROY_TXT) END
          +   CASE WHEN ISNULL(G.CLIENTE,'') <> '' THEN '<small class="vct-acc-sub">' + dbo.VCT_HTML_ESC(G.CLIENTE) + '</small>' ELSE '' END + '</td>'
          + '<td data-label="Responsable" data-vct-sort-value="' + dbo.VCT_HTML_ESC(ISNULL(G.RESPONSABLE,'')) + '">' + CASE WHEN ISNULL(G.RESPONSABLE,'') = '' THEN '<span class="vct-acc-muted">-</span>' ELSE dbo.VCT_HTML_ESC(G.RESPONSABLE) END + '</td>'
          + '<td class="vct-text-center" data-label="Vence" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), G.VENCE, 112), '99991231') + '">'
          +   CASE WHEN G.VENCE IS NULL THEN '<span class="vct-acc-muted">-</span>' ELSE CONVERT(VARCHAR(10), G.VENCE, 103) END
          +   CASE WHEN G.SITUACION = 'VENCIDA' THEN '<small class="vct-acc-late">hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, CONVERT(DATE, G.VENCE), @HOY)) + ' d</small>' ELSE '' END + '</td>'
          + '<td class="vct-text-center" data-label="Estado" data-vct-sort-value="' + G.SITUACION + '">'
          +   '<span class="vct-ini-pill ' + CASE G.SITUACION WHEN 'VENCIDA' THEN 'is-bad">Vencida' WHEN 'PROXIMA' THEN 'is-warn">Vence pronto'
                                                            WHEN 'CUMPLIDA' THEN 'is-ok">Cumplida' WHEN 'CANCELADA' THEN 'is-info">Cancelada'
                                                            ELSE 'is-info">' + dbo.VCT_HTML_ESC(ISNULL(G.EST_DESC,'Abierta')) END + '</span></td>'
          + '<td class="vct-text-center" data-label="" data-vct-export-ignore="true">'
          +   CASE WHEN (@PUEDE_CERRAR = 1 OR G.MIA = 1) AND G.SITUACION IN ('VENCIDA','PROXIMA','ABIERTA')
                   THEN '<button type="button" class="vct-acc-btn" data-vct-acc-estado="CUMPLIDA" data-vct-acc-id="' + CONVERT(VARCHAR(20), G.ID) + '" title="Marcar como cumplida"><span data-vct-icon="check"></span><span>Cumplida</span></button>'
                   WHEN (@PUEDE_CERRAR = 1 OR G.MIA = 1) AND G.SITUACION = 'CUMPLIDA'
                   THEN '<button type="button" class="vct-acc-btn is-ghost" data-vct-acc-estado="PENDIENTE" data-vct-acc-id="' + CONVERT(VARCHAR(20), G.ID) + '" title="Volver a abrir">Reabrir</button>'
                   ELSE '' END
          + '</td>'
          + '</tr>'
        FROM (SELECT X.*, CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES Z WHERE Z.ID = X.ID AND Z.ID_PLAN_ITEM IS NOT NULL) THEN 1 ELSE 0 END AS ID_PLAN_ITEM_FLAG FROM #G X) G
        ORDER BY CASE G.SITUACION WHEN 'VENCIDA' THEN 0 WHEN 'PROXIMA' THEN 1 WHEN 'ABIERTA' THEN 2 ELSE 3 END,
                 ISNULL(G.VENCE, '29991231'), G.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    DECLARE @HTML VARCHAR(MAX) =
        CONVERT(VARCHAR(MAX), '<link rel="stylesheet" href="../css/vct-inicio.css?v=5"><script src="../js/vct-inicio.js?v=4"></script>')
      + '<style>.vct-acc .vct-acc-title{display:block;font-weight:600;color:#1e293b}.vct-acc .vct-acc-sub{display:block;margin-top:2px;color:#64748b;font-size:11px}'
      + '.vct-acc .vct-acc-muted{color:#94a3b8}.vct-acc .vct-acc-late{display:block;margin-top:2px;color:#b91c1c;font-size:11px}'
      + '.vct-acc .vct-acc-btn{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border:1px solid #66062D;border-radius:999px;background:#66062D;color:#fff;font:inherit;font-size:11px;font-weight:600;cursor:pointer;white-space:nowrap}'
      + '.vct-acc .vct-acc-btn svg{width:12px;height:12px}.vct-acc .vct-acc-btn:hover{background:#4d0422}'
      + '.vct-acc .vct-acc-btn.is-ghost{background:#fff;color:#64748b;border-color:#e2e8f0}.vct-acc .vct-acc-btn.is-ghost:hover{color:#66062D;border-color:#66062D}'
      + '.vct-acc .vct-acc-btn[disabled]{opacity:.6;cursor:wait}'
      + '.vct-acc .vct-acc-alert{margin:0 0 14px;padding:10px 14px;border-radius:9px;font-size:13px}'
      + '.vct-acc .vct-acc-alert.is-ok{background:#ecfdf5;color:#047857;border:1px solid #a7f3d0}.vct-acc .vct-acc-alert.is-error{background:#fef2f2;color:#b91c1c;border:1px solid #fecaca}</style>'
      + '<script>(function(){if(window.__vctAccLoaded)return;window.__vctAccLoaded=true;'
      + 'document.addEventListener(''click'',function(e){var b=e.target.closest&&e.target.closest(''[data-vct-acc-estado]'');if(!b||b.disabled)return;'
      + 'e.preventDefault();var est=b.getAttribute(''data-vct-acc-estado'');'
      + 'if(est===''PENDIENTE''&&!window.confirm(''Volver a abrir esta gestion?''))return;'
      + 'b.disabled=true;var S=function(k,v){return Promise.resolve(VCT.Buffer.store(k,v));};'
      + 'S(''TEXTO30'',''ACC_ESTADO'').then(function(){return S(''IDSELEC03'',b.getAttribute(''data-vct-acc-id''));})'
      + '.then(function(){return S(''TEXTO11'',est);}).then(function(){return S(''FLAG01'',''1'');})'
      + '.then(function(){VCT.Navigation.goto(b,''447E1496-AC9B-4821-B658-25AB8D1F45AE'');});});})();</script>'
      + '<div class="vct-page vct-360-module vct-360-visual-final vct-inicio vct-acc" data-vct-page data-vct-inicio data-vct-sidebar-id="2"'
      + ' data-vct-form-id="' + ISNULL(@FORM_ID,'') + '" data-vct-ini-guid="' + @GUID_P + '" data-vct-ini-user="' + dbo.VCT_HTML_ESC(@U) + '">'
      + '<input type="hidden" name="SP.IDSELEC01" data-vct-field="IDSELEC01" value="">'
      + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="">'
      + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">'
      + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">'
      + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value="">'
      + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">'
      + '<div class="vct-360-content-shell">'
      + CASE WHEN @ERR <> '' THEN '<div class="vct-acc-alert is-error">' + dbo.VCT_HTML_ESC(@ERR) + '</div>'
             WHEN @MSG <> '' THEN '<div class="vct-acc-alert is-ok">' + dbo.VCT_HTML_ESC(@MSG) + '</div>' ELSE '' END
      + '<div class="vct-360-stats-row">'
      +   '<div class="vct-360-stat" data-vct-tone="violet"><span><span class="vct-360-stat-label">Abiertas</span><b>' + CONVERT(VARCHAR(10), @K_AB) + '</b><small>'
      +     CASE WHEN @VE_TODO = 1 THEN CONVERT(VARCHAR(10), @K_MIAS) + ' a tu cargo' ELSE CONVERT(VARCHAR(10), @K_SINF) + ' sin fecha' END + '</small></span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="' + CASE WHEN @K_VE > 0 THEN 'amber' ELSE 'mint' END + '"><span><span class="vct-360-stat-label">Vencidas</span><b>' + CONVERT(VARCHAR(10), @K_VE) + '</b><small>sin cerrar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="blue"><span><span class="vct-360-stat-label">Vencen en 7 d&iacute;as</span><b>' + CONVERT(VARCHAR(10), @K_PR) + '</b><small>para priorizar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="calendar"></span></span></div>'
      +   '<div class="vct-360-stat" data-vct-tone="mint"><span><span class="vct-360-stat-label">Cumplidas este mes</span><b>' + CONVERT(VARCHAR(10), @K_CU) + '</b><small>cerradas</small></span><span class="vct-360-stat-icon"><span data-vct-icon="check"></span></span></div>'
      + '</div>'
      + '<div class="vct-ini-grid vct-dashboard-option-b">'
      +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="chart-bar"></span></span>Abiertas por situaci&oacute;n</h3></div></div><div class="vct-ini-box-body">' + @DONUT + '</div></div>'
      +   '<div class="vct-360-box vct-ini-box"><div class="vct-360-box-head"><div><h3><span class="vct-360-title-icon"><span data-vct-icon="check"></span></span>Cumplidas por mes</h3><p class="vct-360-box-subtitle">&uacute;ltimos 6 meses</p></div></div><div class="vct-ini-box-body"><div class="vct-dashboard-bars">' + @BARS + '</div></div></div>'
      + '</div>'
      + '<div class="vct-360-box vct-ini-box"><div class="vct-ini-box-body">'
      +   '<div data-vct-dg data-vct-dg-id="acciones" data-vct-dg-title="' + CASE WHEN @VE_TODO = 1 THEN 'Gestiones' ELSE 'Mis gestiones' END + '"'
      +   ' data-vct-dg-subtitle="Vencidas y pr&oacute;ximas primero" data-vct-dg-unit="gesti&oacute;n(es)" data-vct-dg-page-size="15"'
      +   ' data-vct-dg-search-placeholder="Buscar gesti&oacute;n, proyecto, cliente o responsable..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
      +   '<div data-vct-dg-slot="filters">'
      +     '<select class="vct-select vct-select-sm" data-vct-dg-filter="situacion" aria-label="Situaci&oacute;n">'
      +       '<option value="">Todas las situaciones</option><option value="VENCIDA">Vencidas</option><option value="PROXIMA">Vencen pronto</option>'
      +       '<option value="ABIERTA">Al d&iacute;a</option><option value="CUMPLIDA">Cumplidas</option><option value="CANCELADA">Canceladas</option></select>'
      +     '<select class="vct-select vct-select-sm" data-vct-dg-filter="tipo" aria-label="Tipo">'
      +       '<option value="">Todos los tipos</option><option value="PLAN">Del plan</option><option value="PENDIENTE">Pendientes del cliente</option>'
      +       '<option value="AVISO">Avisos</option><option value="OTRA">Otras</option></select>'
      +     CASE WHEN @VE_TODO = 1 THEN '<select class="vct-select vct-select-sm" data-vct-dg-filter="mias" aria-label="Responsable"><option value="">Todos los responsables</option><option value="1">A mi cargo</option></select>' ELSE '' END
      +   '</div>'
      +   '<table><thead><tr>'
      +     '<th data-vct-sort="gestion" data-vct-sortable="true"><span>Gesti&oacute;n</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-width="24%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th data-vct-width="15%" data-vct-sort="responsable" data-vct-sortable="true"><span>Responsable</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="11%" data-vct-sort="vence" data-vct-sortable="true"><span>Vence</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="12%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'
      +     '<th class="vct-text-center" data-vct-width="12%" data-vct-export-ignore="true"></th>'
      +   '</tr></thead><tbody>' + @ROWS + '</tbody></table>'
      +   '</div>'
      + '</div></div>'
      + '</div></div>';
 
    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @HTML;
END
