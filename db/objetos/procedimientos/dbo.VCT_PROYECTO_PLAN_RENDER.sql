 
/* ---------------- 5. render de la seccion ---------------- */
CREATE   PROCEDURE dbo.VCT_PROYECTO_PLAN_RENDER
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
    /* Seccion "Plan Estrategico" de la Vista 360 de Proyecto.
       No aparece mientras el proyecto esta en lanzamiento y no tiene plan.
       Formularios en @FORMS (van a OUTPARAM3). No devuelve result sets. */
    SET NOCOUNT ON;
    SET @HTML = '';
    SET @FORMS = '';
 
    DECLARE @CAN_EDIT BIT = ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PLAN.EDIT'),0);
    IF @CAN_EDIT = 0 AND ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PLAN.VIEW'),0) = 0 RETURN;
    DECLARE @EST_COD VARCHAR(30), @CODIGO VARCHAR(100), @F_INI_P DATETIME, @F_FIN_P DATETIME, @P_NOMBRE VARCHAR(300), @P_CLIENTE VARCHAR(300);
 
    SELECT @EST_COD = E.CODIGO, @CODIGO = P.CODIGO, @F_INI_P = ISNULL(P.FECHA_INICIO_REAL, P.FECHA_INICIO), @F_FIN_P = P.FECHA_FIN,
           @P_NOMBRE = P.NOMBRE, @P_CLIENTE = C.RAZON_SOCIAL
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE
    WHERE P.ID = @ID_PROYECTO;
 
    DECLARE @ID_PLAN INT, @PLAN_DOC VARCHAR(100), @PLAN_FECHA DATETIME;
    SELECT TOP 1 @ID_PLAN = PL.ID, @PLAN_DOC = D.CODIGO, @PLAN_FECHA = PL.FECHA_ALTA
    FROM dbo.VCT_PROYECTOS_PLANES PL
    LEFT JOIN dbo.VCT_PRM_DOCUMENTOS D ON D.ID = PL.ID_DOCUMENTO
    WHERE PL.ID_PROYECTO = @ID_PROYECTO
    ORDER BY PL.ID DESC;
 
    IF @ID_PLAN IS NULL AND ISNULL(@EST_COD,'') IN ('BORRADOR','CONFIRMADO','') RETURN;
 
    DECLARE @LIDER VARCHAR(300) = '';
    SELECT TOP 1 @LIDER = LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,'')))
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER'
    ORDER BY EQ.ID DESC;
 
    DECLARE @ALERTA VARCHAR(MAX) =
        CASE WHEN ISNULL(@ERROR,'') <> '' THEN '<div class="vct-lanz-alert is-error">' + dbo.VCT_HTML_ESC(@ERROR) + '</div>'
             WHEN ISNULL(@MENSAJE,'') <> '' THEN '<div class="vct-lanz-alert is-ok">' + dbo.VCT_HTML_ESC(@MENSAJE) + '</div>'
             ELSE '' END;
 
    DECLARE @HEAD VARCHAR(MAX) =
        '<div class="vct-360-box-head vct-plan-head">'
      + '<div><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Plan Estrat&eacute;gico</h3>'
      + '<p class="vct-360-box-subtitle">'
      + CASE WHEN @LIDER <> '' THEN 'Consultor l&iacute;der: <b>' + dbo.VCT_HTML_ESC(@LIDER) + '</b>' ELSE 'Sin consultor l&iacute;der asignado' END
      + CASE WHEN @ID_PLAN IS NOT NULL THEN ' &middot; ' + dbo.VCT_HTML_ESC(ISNULL(@PLAN_DOC,'Plan')) + ' desde el ' + CONVERT(VARCHAR(10), @PLAN_FECHA, 103) ELSE '' END
      + '</p></div>';
 
    /* ---------- sin plan: generar ---------- */
    IF @ID_PLAN IS NULL
    BEGIN
        DECLARE @N_BASE INT = (SELECT COUNT(*) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
                               INNER JOIN dbo.VCT_PRM_DOCUMENTOS D ON D.ID = I.ID_DOCUMENTO
                               WHERE D.CODIGO = 'RE-PP-007' AND D.ACTIVO = 1 AND I.ACTIVO = 1);
        SET @HTML =
            '<div class="vct-360-box vct-plan" data-vct-plan>' + @HEAD + '</div>' + @ALERTA
          + '<div class="vct-plan-empty">'
          +   '<p><b>El proyecto todav&iacute;a no tiene Plan Estrat&eacute;gico.</b> Se arma sobre los requisitos de la norma: en cada &iacute;tem se definen fechas, responsables y las gestiones que se van a hacer. El avance sale de las gestiones cumplidas.</p>'
          +   CASE WHEN @CAN_EDIT = 1 THEN
                  '<div class="vct-plan-empty-actions">'
                + CASE WHEN @N_BASE > 0 THEN
                      '<span data-vct-form-scope>'
                    + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="PLAN_GENERAR" value="PLAN_GENERAR">'
                    + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" data-vct-default="BASE" value="BASE">'
                    + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
                    + '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next"><span data-vct-icon="list-checks"></span><span>Generar plan base (RE-PP-007, ' + CONVERT(VARCHAR(10), @N_BASE) + ' &iacute;tems)</span></button>'
                    + '</span>'
                  ELSE '' END
                + '<span data-vct-form-scope>'
                + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="PLAN_GENERAR" value="PLAN_GENERAR">'
                + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" data-vct-default="BLANCO" value="BLANCO">'
                + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
                + '<button type="button" class="vct-btn vct-btn-secondary" data-vct-command="validate-next"><span data-vct-icon="plus"></span><span>Empezar en blanco</span></button>'
                + '</span>'
                + '</div>'
              ELSE '<p class="vct-lanz-muted">Lo arma el consultor l&iacute;der.</p>' END
          + '</div></div>';
        RETURN;
    END;
 
    /* ---------- resumen ---------- */
    DECLARE @N INT = 0, @N_PEND INT = 0, @N_CURSO INT = 0, @N_CUMP INT = 0, @N_VENC INT = 0, @N_SINF INT = 0,
            @AV DECIMAL(5,1) = 0, @TM DECIMAL(5,1) = 0, @GT INT = 0, @GC INT = 0, @AV_TXT VARCHAR(10) = '0', @TM_TXT VARCHAR(10) = '0';
    SELECT @N = COUNT(*),
           @N_PEND = SUM(CASE WHEN ESTADO_CALC = 'PENDIENTE' THEN 1 ELSE 0 END),
           @N_CURSO = SUM(CASE WHEN ESTADO_CALC = 'EN_CURSO' THEN 1 ELSE 0 END),
           @N_CUMP = SUM(CASE WHEN ESTADO_CALC = 'CUMPLIDO' THEN 1 ELSE 0 END),
           @N_VENC = SUM(CASE WHEN ESTADO_CALC = 'VENCIDO' THEN 1 ELSE 0 END),
           @N_SINF = SUM(CASE WHEN ESTADO_CALC = 'SIN_FECHAS' THEN 1 ELSE 0 END),
           @AV = ISNULL(ROUND(AVG(CAST(AVANCE AS DECIMAL(9,2))), 1), 0), @TM = ISNULL(ROUND(AVG(CAST(TIEMPO AS DECIMAL(9,2))), 1), 0),
           @GT = ISNULL(SUM(G_TOTAL), 0), @GC = ISNULL(SUM(G_CUMPLIDAS), 0)
    FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO);
 
    SET @AV_TXT = CASE WHEN @AV = FLOOR(@AV) THEN CONVERT(VARCHAR(10), CONVERT(INT, @AV)) ELSE REPLACE(CONVERT(VARCHAR(10), @AV), '.', ',') END;
    SET @TM_TXT = CASE WHEN @TM = FLOOR(@TM) THEN CONVERT(VARCHAR(10), CONVERT(INT, @TM)) ELSE REPLACE(CONVERT(VARCHAR(10), @TM), '.', ',') END;
 
    DECLARE @CHIP VARCHAR(MAX) =
        '<div class="vct-plan-chips" data-vct-plan-chips>'
      + '<button type="button" class="vct-plan-chip is-active" data-plan-filter="">Todos <b>' + CONVERT(VARCHAR(10), ISNULL(@N,0)) + '</b></button>'
      + '<button type="button" class="vct-plan-chip is-pendiente" data-plan-filter="PENDIENTE">Pendientes <b>' + CONVERT(VARCHAR(10), ISNULL(@N_PEND,0)) + '</b></button>'
      + '<button type="button" class="vct-plan-chip is-encurso" data-plan-filter="EN_CURSO">En curso <b>' + CONVERT(VARCHAR(10), ISNULL(@N_CURSO,0)) + '</b></button>'
      + '<button type="button" class="vct-plan-chip is-cumplido" data-plan-filter="CUMPLIDO">Cumplidos <b>' + CONVERT(VARCHAR(10), ISNULL(@N_CUMP,0)) + '</b></button>'
      + '<button type="button" class="vct-plan-chip is-vencido" data-plan-filter="VENCIDO">Vencidos <b>' + CONVERT(VARCHAR(10), ISNULL(@N_VENC,0)) + '</b></button>'
      + CASE WHEN ISNULL(@N_SINF,0) > 0 THEN '<button type="button" class="vct-plan-chip is-sinfechas" data-plan-filter="SIN_FECHAS">Sin fechas <b>' + CONVERT(VARCHAR(10), @N_SINF) + '</b></button>' ELSE '' END
      + '</div>';
 
    DECLARE @RESUMEN VARCHAR(MAX) =
        '<div class="vct-plan-summary">'
      + '<div class="vct-plan-kpi"><span class="vct-plan-kpi-label">Avance del plan</span><b>' + @AV_TXT + '%</b>'
      +   '<div class="vct-plan-bar"><span style="width:' + CONVERT(VARCHAR(10), @AV) + '%"></span></div>'
      +   '<small>' + CONVERT(VARCHAR(10), @GC) + ' de ' + CONVERT(VARCHAR(10), @GT) + ' gestiones cumplidas</small></div>'
      + '<div class="vct-plan-kpi"><span class="vct-plan-kpi-label">Tiempo consumido</span><b>' + @TM_TXT + '%</b>'
      +   '<div class="vct-plan-bar is-time' + CASE WHEN @TM - @AV >= 20 THEN ' is-late' ELSE '' END + '"><span style="width:' + CONVERT(VARCHAR(10), @TM) + '%"></span></div>'
      +   '<small>' + CASE WHEN @TM - @AV >= 20 THEN 'El tiempo va adelante del avance' ELSE 'Promedio del plazo de los &iacute;tems' END + '</small></div>'
      + '</div>';
 
    /* ---------- items ---------- */
    DECLARE @ROWS VARCHAR(MAX) = '';
    SELECT @ROWS = ISNULL((
        SELECT
            '<tr class="vct-plan-row' + CASE WHEN C.ID_PADRE IS NOT NULL THEN ' is-sub' ELSE '' END + '" data-plan-item="' + CONVERT(VARCHAR(20), C.ID) + '" data-plan-estado="' + C.ESTADO_CALC + '"'
          + ' data-plan-text="' + dbo.VCT_HTML_ESC(LOWER(ISNULL(C.CODIGO_ITEM,'') + ' ' + C.TITULO + ' ' + ISNULL(C.RESPONSABLES,''))) + '"'
          + ' data-vct-row data-vct-pi-id="' + CONVERT(VARCHAR(20), C.ID) + '" data-vct-pi-n="' + CONVERT(VARCHAR(10), C.ORDEN) + '"'
          + ' data-vct-pi-cod="' + dbo.VCT_HTML_ESC(C.CODIGO_ITEM) + '" data-vct-pi-tit="' + dbo.VCT_HTML_ESC(C.TITULO) + '"'
          + ' data-vct-pi-desc="' + dbo.VCT_HTML_ESC(C.DESCRIPCION) + '" data-vct-pi-resp="' + dbo.VCT_HTML_ESC(C.RESPONSABLES) + '"'
          + ' data-vct-pi-ini="' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_INICIO, 23), '') + '" data-vct-pi-fin="' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_VENCIMIENTO, 23), '') + '"'
          + ' data-vct-pi-real="' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_CIERRE, 23), '') + '" data-vct-pi-obs="' + dbo.VCT_HTML_ESC(C.OBSERVACIONES) + '"'
          + ' data-x-est="' + CASE C.ESTADO_CALC WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso'
                                                 WHEN 'PENDIENTE' THEN 'Pendiente' ELSE 'Sin fechas' END + '"'
          + ' data-x-av="' + CONVERT(VARCHAR(10), C.AVANCE) + '" data-x-tm="' + CONVERT(VARCHAR(10), C.TIEMPO) + '"'
          + ' data-x-g="' + CONVERT(VARCHAR(10), C.G_CUMPLIDAS) + '/' + CONVERT(VARCHAR(10), C.G_TOTAL) + '">'
          + '<td class="vct-plan-n">' + CONVERT(VARCHAR(10), C.ORDEN) + '</td>'
          + '<td class="vct-plan-item"><button type="button" class="vct-plan-toggle" data-vct-plan-toggle aria-expanded="false">'
          +   CASE WHEN PATINDEX('%[^0-9]%', ISNULL(C.CODIGO_ITEM,'')) > 0 THEN '<b>' + dbo.VCT_HTML_ESC(C.CODIGO_ITEM) + '</b> ' ELSE '' END
          +   dbo.VCT_HTML_ESC(C.TITULO) + '</button>'
          +   CASE WHEN ISNULL(C.RESPONSABLES,'') <> '' THEN '<small>' + dbo.VCT_HTML_ESC(C.RESPONSABLES) + '</small>' ELSE '' END + '</td>'
          + '<td class="vct-plan-date">' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_INICIO, 103), '-') + '</td>'
          + '<td class="vct-plan-date">' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_VENCIMIENTO, 103), '-') + '</td>'
          + '<td class="vct-plan-date">' + ISNULL(CONVERT(VARCHAR(10), C.FECHA_CIERRE, 103), '-') + '</td>'
          + '<td><span class="vct-plan-est is-' + LOWER(REPLACE(C.ESTADO_CALC,'_','')) + '">'
          +   CASE C.ESTADO_CALC WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso'
                                 WHEN 'PENDIENTE' THEN 'Pendiente' ELSE 'Sin fechas' END + '</span>'
          +   CASE WHEN C.DIAS_ATRASO > 0 THEN '<small class="vct-plan-late">' + CONVERT(VARCHAR(10), C.DIAS_ATRASO) + ' d de atraso</small>' ELSE '' END + '</td>'
          + '<td class="vct-plan-meter"><div class="vct-plan-bar"><span style="width:' + CONVERT(VARCHAR(10), C.AVANCE) + '%"></span></div>'
          +   '<small>' + CONVERT(VARCHAR(10), C.AVANCE) + '% &middot; ' + CONVERT(VARCHAR(10), C.G_CUMPLIDAS) + '/' + CONVERT(VARCHAR(10), C.G_TOTAL) + '</small></td>'
          + '<td class="vct-plan-meter"><div class="vct-plan-bar is-time'
          +   CASE WHEN C.ESTADO_CALC IN ('EN_CURSO','VENCIDO') AND C.TIEMPO - C.AVANCE >= 20 THEN ' is-late' ELSE '' END
          +   '"><span style="width:' + CONVERT(VARCHAR(10), C.TIEMPO) + '%"></span></div><small>' + CONVERT(VARCHAR(10), C.TIEMPO) + '%</small></td>'
          + '<td class="vct-plan-actions">'
          +   CASE WHEN @CAN_EDIT = 1 THEN
                  '<button type="button" class="vct-plan-icon" title="Editar &iacute;tem" aria-label="Editar &iacute;tem" data-vct-command="open-modal-data" data-vct-target="vctPlanItem"'
                + ' data-vct-form-title="Editar &iacute;tem" data-vct-form-subtitle="El cambio de fechas de un &iacute;tem ya fechado le avisa al analista."><span data-vct-icon="edit"></span></button>'
                + '<button type="button" class="vct-plan-icon" title="Agregar gesti&oacute;n" aria-label="Agregar gesti&oacute;n" data-vct-command="open-modal-data" data-vct-target="vctPlanGestion" data-vct-form-title="Nueva gesti&oacute;n"'
                + ' data-vct-form-subtitle="&Iacute;tem: ' + dbo.VCT_HTML_ESC(CASE WHEN PATINDEX('%[^0-9]%', ISNULL(C.CODIGO_ITEM,'')) > 0 THEN C.CODIGO_ITEM + ' ' ELSE '' END + C.TITULO) + '"><span data-vct-icon="plus"></span></button>'
              ELSE '' END
          + '</td></tr>'
          /* detalle: descripcion, observaciones y gestiones del item */
          + '<tr class="vct-plan-detail" data-plan-detail="' + CONVERT(VARCHAR(20), C.ID) + '" data-vct-row data-vct-pi-id="' + CONVERT(VARCHAR(20), C.ID) + '" hidden><td colspan="9"><div class="vct-plan-detail-body">'
          + CASE WHEN ISNULL(C.DESCRIPCION,'') <> '' THEN '<p class="vct-plan-text">' + REPLACE(dbo.VCT_HTML_ESC(C.DESCRIPCION), CHAR(10), '<br>') + '</p>' ELSE '' END
          + CASE WHEN ISNULL(C.OBSERVACIONES,'') <> '' THEN '<p class="vct-plan-text"><b>Observaciones:</b> ' + REPLACE(dbo.VCT_HTML_ESC(C.OBSERVACIONES), CHAR(10), '<br>') + '</p>' ELSE '' END
          + '<ul class="vct-plan-gs">' + ISNULL((
                SELECT
                    '<li class="vct-plan-g' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN ' is-done' WHEN GE.CODIGO = 'CANCELADA' THEN ' is-cancel' ELSE '' END + '">'
                  + '<span class="vct-plan-g-check">' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN '&#10003;' ELSE '' END + '</span>'
                  + '<span class="vct-plan-g-main"><span class="vct-plan-g-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</span>'
                  + '<small>' + ISNULL(GE.DESCRIPCION,'')
                  +   CASE WHEN G.FECHA_VENCIMIENTO IS NOT NULL THEN ' &middot; vence ' + CONVERT(VARCHAR(10), G.FECHA_VENCIMIENTO, 103) ELSE '' END
                  +   CASE WHEN GE.CODIGO NOT IN ('CUMPLIDA','CANCELADA') AND G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < CONVERT(DATE, GETDATE())
                           THEN ' &middot; <span class="vct-plan-late">vencida hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, CONVERT(DATE, G.FECHA_VENCIMIENTO), CONVERT(DATE, GETDATE()))) + ' d</span>' ELSE '' END
                  +   ISNULL(' &middot; ' + dbo.VCT_HTML_ESC(RS.NOMBRE), '')
                  + '</small></span>'
                  + CASE WHEN @CAN_EDIT = 1 AND GE.CODIGO <> 'CANCELADA' THEN
                        '<span class="vct-plan-g-act" data-vct-form-scope>'
                      + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="PLAN_GESTION_ESTADO" value="PLAN_GESTION_ESTADO">'
                      + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), G.ID) + '" value="' + CONVERT(VARCHAR(20), G.ID) + '">'
                      + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" data-vct-default="' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'PENDIENTE' ELSE 'CUMPLIDA' END + '" value="' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'PENDIENTE' ELSE 'CUMPLIDA' END + '">'
                      + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
                      + '<button type="button" data-vct-command="validate-next" class="vct-btn vct-btn-sm ' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'vct-btn-secondary">Reabrir' ELSE 'vct-btn-primary"><span data-vct-icon="check"></span><span>Cumplida</span>' END + '</button>'
                      + '</span>'
                    ELSE '' END
                  + '</li>'
                FROM dbo.VCT_GESTIONES G
                LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
                OUTER APPLY
                (
                    SELECT TOP 1 CASE GP.TIPO_ENTIDAD
                                    WHEN 'CONSULTOR' THEN (SELECT LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'') + ', ' + ISNULL(CO.NOMBRES,''))) FROM dbo.VCT_CONSULTORES CO WHERE CO.ID = GP.ID_ENTIDAD)
                                    WHEN 'EMPLEADO' THEN (SELECT LTRIM(RTRIM(ISNULL(EM.APELLIDOS,'') + ', ' + ISNULL(EM.NOMBRES,''))) FROM dbo.VCT_EMPLEADOS EM WHERE EM.ID = GP.ID_ENTIDAD)
                                 END AS NOMBRE
                    FROM dbo.VCT_GESTIONES_PARTICIPANTES GP
                    WHERE GP.ID_GESTION = G.ID AND GP.ROL_PARTICIPANTE = 'RESPONSABLE' AND GP.ESTADO = 'ACTIVO'
                    ORDER BY GP.PRINCIPAL DESC, GP.ID
                ) RS
                WHERE G.ID_PLAN_ITEM = C.ID
                ORDER BY CASE WHEN GE.CODIGO IN ('CUMPLIDA','CANCELADA') THEN 1 ELSE 0 END, ISNULL(G.FECHA_VENCIMIENTO, '29991231'), G.ID
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)') , '') + '</ul>'
          + CASE WHEN C.G_TOTAL = 0 AND NOT EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES GZ WHERE GZ.ID_PLAN_ITEM = C.ID)
                 THEN '<p class="vct-lanz-empty">Sin gestiones. Agreg&aacute; las acciones que vas a hacer en este &iacute;tem: el avance sale de las gestiones cumplidas.</p>' ELSE '' END
          + CASE WHEN @CAN_EDIT = 1 THEN
                '<div class="vct-plan-detail-actions">'
              + '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-command="open-modal-data" data-vct-target="vctPlanGestion" data-vct-form-title="Nueva gesti&oacute;n"'
              + ' data-vct-form-subtitle="&Iacute;tem: ' + dbo.VCT_HTML_ESC(CASE WHEN PATINDEX('%[^0-9]%', ISNULL(C.CODIGO_ITEM,'')) > 0 THEN C.CODIGO_ITEM + ' ' ELSE '' END + C.TITULO) + '"><span data-vct-icon="plus"></span><span>Agregar gesti&oacute;n</span></button>'
              + CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES GZ WHERE GZ.ID_PLAN_ITEM = C.ID) THEN
                    '<span data-vct-form-scope data-vct-plan-quitar>'
                  + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="PLAN_ITEM_DEL" value="PLAN_ITEM_DEL">'
                  + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), C.ID) + '" value="' + CONVERT(VARCHAR(20), C.ID) + '">'
                  + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
                  + '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-plan-del" data-vct-command="validate-next"><span data-vct-icon="trash"></span><span>Quitar &iacute;tem</span></button>'
                  + '</span>'
                ELSE '' END
              + '</div>'
            ELSE '' END
          + '</div></td></tr>'
        FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C
        ORDER BY C.ORDEN, C.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    /* ---------- cronograma por mes (como el Gantt del Excel) ---------- */
    DECLARE @G_INI DATE, @G_FIN DATE, @G_TOT INT, @G_HOY DATE = CONVERT(DATE, GETDATE()), @G_M DATE,
            @GANTT VARCHAR(MAX) = '', @G_HEAD VARCHAR(MAX) = '', @G_TODAY VARCHAR(200) = '';
    SELECT @G_INI = MIN(CONVERT(DATE, FECHA_INICIO)),
           @G_FIN = MAX(CONVERT(DATE, CASE WHEN FECHA_CIERRE > FECHA_VENCIMIENTO THEN FECHA_CIERRE ELSE FECHA_VENCIMIENTO END))
    FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO)
    WHERE FECHA_INICIO IS NOT NULL AND FECHA_VENCIMIENTO IS NOT NULL;
 
    IF @G_INI IS NOT NULL
    BEGIN
        SET @G_INI = DATEADD(MONTH, DATEDIFF(MONTH, 0, @G_INI), 0);
        SET @G_FIN = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @G_FIN) + 1, 0));
        IF DATEDIFF(MONTH, @G_INI, @G_FIN) > 35 SET @G_FIN = DATEADD(DAY, -1, DATEADD(MONTH, 36, @G_INI));
        SET @G_TOT = DATEDIFF(DAY, @G_INI, @G_FIN) + 1;
 
        SET @G_M = @G_INI;
        WHILE @G_M <= @G_FIN
        BEGIN
            SET @G_HEAD = @G_HEAD + '<span class="vct-gantt-m" style="left:' + CONVERT(VARCHAR(20), CAST(100.0 * (DATEDIFF(DAY, @G_INI, @G_M)) / @G_TOT AS DECIMAL(9,3))) + '%;width:'
                        + CONVERT(VARCHAR(20), CAST(100.0 * (DATEDIFF(DAY, @G_M, DATEADD(MONTH, 1, @G_M))) / @G_TOT AS DECIMAL(9,3))) + '%">'
                        + SUBSTRING('EneFebMarAbrMayJunJulAgoSepOctNovDic', (MONTH(@G_M) - 1) * 3 + 1, 3)
                        + CASE WHEN MONTH(@G_M) = 1 OR @G_M = @G_INI THEN '<small>' + CONVERT(VARCHAR(4), YEAR(@G_M)) + '</small>' ELSE '' END + '</span>';
            SET @G_M = DATEADD(MONTH, 1, @G_M);
        END;
 
        IF @G_HOY BETWEEN @G_INI AND @G_FIN
            SET @G_TODAY = '<span class="vct-gantt-today" style="left:' + CONVERT(VARCHAR(20), CAST(100.0 * (DATEDIFF(DAY, @G_INI, @G_HOY)) / @G_TOT AS DECIMAL(9,3))) + '%"></span>';
 
        SELECT @GANTT = ISNULL((
            SELECT
                '<div class="vct-gantt-row" data-plan-gitem="' + CONVERT(VARCHAR(20), C.ID) + '" data-plan-estado="' + C.ESTADO_CALC + '"'
              + ' data-plan-text="' + dbo.VCT_HTML_ESC(LOWER(ISNULL(C.CODIGO_ITEM,'') + ' ' + C.TITULO + ' ' + ISNULL(C.RESPONSABLES,''))) + '">'
              + '<div class="vct-gantt-label" title="' + dbo.VCT_HTML_ESC(C.TITULO) + '"><span>' + CONVERT(VARCHAR(10), C.ORDEN) + '</span>'
              + dbo.VCT_HTML_ESC(CASE WHEN PATINDEX('%[^0-9]%', ISNULL(C.CODIGO_ITEM,'')) > 0 THEN C.CODIGO_ITEM + ' ' ELSE '' END + C.TITULO) + '</div>'
              + '<div class="vct-gantt-track">' + @G_TODAY
              + CASE WHEN C.FECHA_INICIO IS NOT NULL AND C.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, C.FECHA_INICIO) <= @G_FIN THEN
                    '<span class="vct-gantt-bar is-' + LOWER(REPLACE(C.ESTADO_CALC,'_','')) + '" style="left:'
                  + CONVERT(VARCHAR(20), CAST(100.0 * (DATEDIFF(DAY, @G_INI, CONVERT(DATE, C.FECHA_INICIO))) / @G_TOT AS DECIMAL(9,3))) + '%;width:'
                  + CONVERT(VARCHAR(20), CAST(100.0 * (CASE WHEN DATEDIFF(DAY, @G_INI, CONVERT(DATE, C.FECHA_VENCIMIENTO)) + 1 > @G_TOT THEN @G_TOT - DATEDIFF(DAY, @G_INI, CONVERT(DATE, C.FECHA_INICIO)) ELSE DATEDIFF(DAY, CONVERT(DATE, C.FECHA_INICIO), CONVERT(DATE, C.FECHA_VENCIMIENTO)) + 1 END) / @G_TOT AS DECIMAL(9,3))) + '%"'
                  + ' title="' + CONVERT(VARCHAR(10), C.FECHA_INICIO, 103) + ' al ' + CONVERT(VARCHAR(10), C.FECHA_VENCIMIENTO, 103)
                  + ' &middot; avance ' + CONVERT(VARCHAR(10), C.AVANCE) + '%"><i style="width:' + CONVERT(VARCHAR(10), C.AVANCE) + '%"></i></span>'
                ELSE '<span class="vct-gantt-none">sin fechas</span>' END
              + '</div></div>'
            FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C
            ORDER BY C.ORDEN, C.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
        SET @GANTT = '<div class="vct-gantt">'
                   + '<div class="vct-gantt-head"><div class="vct-gantt-label">&Iacute;tem</div><div class="vct-gantt-months">' + @G_HEAD + '</div></div>'
                   + @GANTT
                   + '<div class="vct-gantt-legend"><span class="is-encurso">En curso</span><span class="is-pendiente">Pendiente</span><span class="is-cumplido">Cumplido</span><span class="is-vencido">Vencido</span><span class="is-hoy">Hoy</span><span>La parte oscura de cada barra es el avance.</span></div>'
                   + '</div>';
    END
    ELSE
        SET @GANTT = '<div class="vct-plan-empty"><p>Carg&aacute; inicio y fin en los &iacute;tems para ver el cronograma.</p></div>';
 
    /* ---------- pendientes del cliente (gestiones fuera del plan) ---------- */
    DECLARE @PEND VARCHAR(MAX) = '', @N_PEND_AB INT = 0;
    SELECT @N_PEND_AB = COUNT(*)
    FROM dbo.VCT_GESTIONES G
    INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
    INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'PENDIENTE_CLIENTE' AND GE.CODIGO NOT IN ('CUMPLIDA','CANCELADA');
 
    SELECT @PEND = ISNULL((
        SELECT
            '<li class="vct-plan-g' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN ' is-done' WHEN GE.CODIGO = 'CANCELADA' THEN ' is-cancel' ELSE '' END + '">'
          + '<span class="vct-plan-g-check">' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN '&#10003;' ELSE '' END + '</span>'
          + '<span class="vct-plan-g-main"><span class="vct-plan-g-title">' + dbo.VCT_HTML_ESC(G.TITULO) + '</span>'
          + '<small>' + ISNULL(GE.DESCRIPCION,'')
          +   CASE WHEN G.FECHA_VENCIMIENTO IS NOT NULL THEN ' &middot; para el ' + CONVERT(VARCHAR(10), G.FECHA_VENCIMIENTO, 103) ELSE '' END
          +   CASE WHEN GE.CODIGO NOT IN ('CUMPLIDA','CANCELADA') AND G.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, G.FECHA_VENCIMIENTO) < CONVERT(DATE, GETDATE())
                   THEN ' &middot; <span class="vct-plan-late">vencido hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, CONVERT(DATE, G.FECHA_VENCIMIENTO), CONVERT(DATE, GETDATE()))) + ' d</span>' ELSE '' END
          +   CASE WHEN ISNULL(G.OBSERVACIONES,'') <> '' THEN ' &middot; ' + dbo.VCT_HTML_ESC(G.OBSERVACIONES) ELSE '' END
          + '</small>'
          + CASE WHEN ISNULL(G.DESCRIPCION,'') <> '' THEN '<small class="vct-plan-g-det">' + dbo.VCT_HTML_ESC(G.DESCRIPCION) + '</small>' ELSE '' END
          + '</span>'
          + CASE WHEN @CAN_EDIT = 1 AND GE.CODIGO <> 'CANCELADA' THEN
                '<span class="vct-plan-g-act" data-vct-form-scope>'
              + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="PLAN_GESTION_ESTADO" value="PLAN_GESTION_ESTADO">'
              + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), G.ID) + '" value="' + CONVERT(VARCHAR(20), G.ID) + '">'
              + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" data-vct-default="' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'PENDIENTE' ELSE 'CUMPLIDA' END + '" value="' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'PENDIENTE' ELSE 'CUMPLIDA' END + '">'
              + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
              + '<button type="button" data-vct-command="validate-next" class="vct-btn vct-btn-sm ' + CASE WHEN GE.CODIGO = 'CUMPLIDA' THEN 'vct-btn-secondary">Reabrir' ELSE 'vct-btn-primary"><span data-vct-icon="check"></span><span>Cumplido</span>' END + '</button>'
              + '</span>'
            ELSE '' END
          + '</li>'
        FROM dbo.VCT_GESTIONES G
        INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
        LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
        WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'PENDIENTE_CLIENTE'
        ORDER BY CASE WHEN GE.CODIGO IN ('CUMPLIDA','CANCELADA') THEN 1 ELSE 0 END, ISNULL(G.FECHA_VENCIMIENTO, '29991231'), G.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    SET @PEND =
        '<div class="vct-plan-pend">'
      + '<div class="vct-plan-pend-head"><h4><span data-vct-icon="user-check"></span> Pendientes del cliente</h4>'
      + '<span class="vct-plan-pend-count' + CASE WHEN @N_PEND_AB > 0 THEN ' is-open' ELSE '' END + '">' + CONVERT(VARCHAR(10), @N_PEND_AB) + ' abierto' + CASE WHEN @N_PEND_AB = 1 THEN '' ELSE 's' END + '</span>'
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-command="open-modal-empty" data-vct-target="vctPlanPend"'
          + ' data-vct-form-title="Nuevo pendiente del cliente" data-vct-form-subtitle="Lo que tiene que hacer el cliente. No cuenta para el avance del plan.">'
          + '<span data-vct-icon="plus"></span><span>Agregar pendiente</span></button>'
        ELSE '' END
      + '</div>'
      + '<p class="vct-plan-pend-help">Tareas que dependen del cliente (por ejemplo, aprobar la pol&iacute;tica). Se separan de las acciones del plan y no cuentan para su avance.</p>'
      + CASE WHEN @PEND = '' THEN '<p class="vct-lanz-empty">Sin pendientes del cliente.</p>' ELSE '<ul class="vct-plan-gs">' + @PEND + '</ul>' END
      + '</div>';
 
    SET @HTML =
        '<div class="vct-360-box vct-plan" data-vct-plan'
      + ' data-plan-titulo="' + dbo.VCT_HTML_ESC('Plan Estrategico - (' + ISNULL(@CODIGO,'') + ') ' + ISNULL(@P_NOMBRE,'') + ' - ' + ISNULL(@P_CLIENTE,'')) + '"'
      + ' data-plan-resumen="' + dbo.VCT_HTML_ESC('Avance ' + @AV_TXT + '% | Tiempo consumido ' + @TM_TXT + '% | '
                                + CONVERT(VARCHAR(10), @GC) + ' de ' + CONVERT(VARCHAR(10), @GT) + ' gestiones cumplidas'
                                + CASE WHEN @LIDER <> '' THEN ' | Consultor lider: ' + @LIDER ELSE '' END) + '">'
      + @HEAD
      + '<span class="vct-plan-big"><b>' + @AV_TXT + '%</b> avance</span>'
      + '</div>'
      + @ALERTA
      + @RESUMEN
      + '<div class="vct-plan-toolbar">' + @CHIP
      +   '<div class="vct-plan-tools">'
      +     '<div class="vct-plan-view" data-vct-plan-views>'
      +       '<button type="button" class="vct-plan-view-btn is-active" data-plan-view="tabla"><span data-vct-icon="list-checks"></span><span>Tabla</span></button>'
      +       '<button type="button" class="vct-plan-view-btn" data-plan-view="gantt"><span data-vct-icon="calendar"></span><span>Cronograma</span></button>'
      +     '</div>'
      +     '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-plan-export="excel" title="Exportar el plan a Excel"><span data-vct-icon="file-spreadsheet"></span><span>Excel</span></button>'
      +     '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-plan-export="pdf" title="Exportar el plan a PDF"><span data-vct-icon="download"></span><span>PDF</span></button>'
      +     '<div class="vct-plan-search"><span data-vct-icon="search"></span><input type="text" class="vct-input" placeholder="Buscar &iacute;tem o responsable..." data-vct-plan-filter autocomplete="off"></div>'
      +     CASE WHEN @CAN_EDIT = 1 THEN '<button type="button" class="vct-btn vct-btn-primary vct-btn-sm" data-vct-command="open-modal-empty" data-vct-target="vctPlanItem" data-vct-form-title="Nuevo &iacute;tem" data-vct-form-subtitle="Por ejemplo un requisito de la norma o una actividad propia: diagn&oacute;stico, auditor&iacute;a interna, certificaci&oacute;n."><span data-vct-icon="plus"></span><span>Agregar &iacute;tem</span></button>' ELSE '' END
      +   '</div>'
      + '</div>'
      + CASE WHEN @ROWS = '' THEN '<div class="vct-plan-empty"><p>El plan no tiene &iacute;tems todav&iacute;a.</p></div>'
             ELSE '<div class="vct-plan-table-wrap" data-plan-pane="tabla"><table class="vct-plan-table"><thead><tr>'
                + '<th class="vct-plan-n">N&deg;</th><th>&Iacute;tem</th><th>Inicio</th><th>Fin</th><th>Fin real</th><th>Estado</th>'
                + '<th title="Gestiones cumplidas sobre el total del &iacute;tem">Avance</th><th title="Tiempo transcurrido del plazo del &iacute;tem">Tiempo</th><th></th>'
                + '</tr></thead><tbody>' + @ROWS + '</tbody></table></div>' END
      + '<div data-plan-pane="gantt" hidden>' + @GANTT + '</div>'
      + @PEND
      + '<p class="vct-plan-foot">Avance = gestiones cumplidas sobre el total del &iacute;tem. Tiempo = parte del plazo (inicio a fin) ya transcurrida; en naranja cuando va 20 puntos o m&aacute;s adelante del avance.</p>'
      + '</div>';
 
    /* ============================================================
       FORMULARIOS
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
    DECLARE @F VARCHAR(MAX), @OPT VARCHAR(MAX);
 
    /* ---- item (alta y edicion: el JS completa los valores) ---- */
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO19','N&deg;','TEXT',2,0,5,NULL,NULL,CONVERT(VARCHAR(10), ISNULL(@N,0) + 1),0,0,NULL,'pi-n'),
    (2,'TEXTO11','C&oacute;digo','TEXT',3,0,50,'Ej.: 4.1',NULL,NULL,0,0,NULL,'pi-cod'),
    (3,'TEXTO12','&Iacute;tem','TEXT',7,1,400,'Ej.: Comprensi&oacute;n de la organizaci&oacute;n y de su contexto',NULL,NULL,0,0,NULL,'pi-tit'),
    (4,'TEXTO13','Descripci&oacute;n / alcance','TEXTAREA',12,0,2000,'Qu&eacute; se va a hacer en este &iacute;tem.',NULL,NULL,0,0,NULL,'pi-desc'),
    (5,'TEXTO14','Responsables','TEXT',12,0,500,'Ej.: C. Cuello / RRHH del cliente',NULL,NULL,0,0,NULL,'pi-resp'),
    (6,'TEXTO15','Inicio','DATE',4,0,NULL,'Seleccionar fecha',NULL,NULL,0,0,NULL,'pi-ini'),
    (7,'TEXTO16','Fin','DATE',4,0,NULL,'Seleccionar fecha',NULL,NULL,0,0,NULL,'pi-fin'),
    (8,'TEXTO17','Fin real','DATE',4,0,NULL,'Al cerrar el &iacute;tem',NULL,NULL,0,0,NULL,'pi-real'),
    (9,'TEXTO18','Observaciones / comentarios','TEXTAREA',12,0,2000,NULL,NULL,NULL,0,0,NULL,'pi-obs'),
    (10,'IDSELEC03','Item','HIDDEN',12,0,NULL,NULL,NULL,'',0,1,NULL,'pi-id'),
    (11,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'PLAN_ITEM_GUARDAR',0,1,NULL,NULL),
    (12,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
    SET @F = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctPlanItem', @TITLE='&Iacute;tem del plan',
         @SUBTITLE='El cambio de fechas de un &iacute;tem ya fechado le avisa al analista.', @ICON='list-checks',
         @LAYOUT='MODAL', @SAVE_LABEL='Guardar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
    SET @FORMS = @FORMS + REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ');
 
    /* ---- gestion de un item ---- */
    SELECT @OPT = ISNULL((
        SELECT '<option value="' + X.V + '">' + dbo.VCT_HTML_ESC(X.NOMBRE) + '</option>'
        FROM
        (
            SELECT 'C:' + CONVERT(VARCHAR(20), C.ID) AS V,
                   LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')' AS NOMBRE,
                   CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN 0 ELSE 1 END AS O
            FROM dbo.VCT_PROYECTOS_EQUIPO EQ
            INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
            INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
            WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
            UNION ALL
            SELECT 'E:' + CONVERT(VARCHAR(20), E.ID),
                   LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')', 2
            FROM dbo.VCT_PROYECTOS_EQUIPO EQ
            INNER JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
            INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
            WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO'
        ) X
        ORDER BY X.O, X.NOMBRE
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Gesti&oacute;n','TEXT',12,1,300,'Ej.: Redactar la pol&iacute;tica de calidad',NULL,NULL,0,0,NULL,'g-tit'),
    (2,'TEXTO12','Vence','DATE',6,0,NULL,'Seleccionar fecha',NULL,NULL,0,0,NULL,'g-ven'),
    (3,'TEXTO13','Responsable','TEXT',6,0,20,NULL,NULL,NULL,0,0,NULL,'g-resp'),
    (4,'TEXTO14','Detalle','TEXTAREA',12,0,2000,NULL,NULL,NULL,0,0,NULL,'g-det'),
    (5,'IDSELEC03','Item','HIDDEN',12,0,NULL,NULL,NULL,'',0,1,NULL,'pi-id'),
    (6,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'PLAN_GESTION_ADD',0,1,NULL,NULL),
    (7,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
    SET @F = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctPlanGestion', @TITLE='Nueva gesti&oacute;n',
         @SUBTITLE='Acci&oacute;n del &iacute;tem. Cuenta para el avance cuando se marca cumplida.', @ICON='clipboard-check',
         @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
    SET @FORMS = @FORMS + REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ')
        + '<template data-vct-field-options data-vct-target="vctPlanGestion" data-vct-field="TEXTO13" data-vct-placeholder="Sin responsable">' + @OPT + '</template>';
 
    /* ---- pendiente del cliente ---- */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Pendiente','TEXT',12,1,300,'Ej.: Aprobar la pol&iacute;tica de calidad',NULL,NULL,0,0,NULL,NULL),
    (2,'TEXTO12','Para cu&aacute;ndo','DATE',6,0,NULL,'Seleccionar fecha',NULL,NULL,0,0,NULL,NULL),
    (3,'TEXTO13','Qui&eacute;n en el cliente','TEXT',6,0,200,'Ej.: Gerente de planta',NULL,NULL,0,0,NULL,NULL),
    (4,'TEXTO14','Detalle','TEXTAREA',12,0,2000,NULL,NULL,NULL,0,0,NULL,NULL),
    (5,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'PLAN_PEND_ADD',0,1,NULL,NULL),
    (6,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
    SET @F = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctPlanPend', @TITLE='Pendiente del cliente',
         @SUBTITLE='Lo que tiene que hacer el cliente. No cuenta para el avance del plan.', @ICON='user-check',
         @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
    SET @FORMS = @FORMS + REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ');
END
