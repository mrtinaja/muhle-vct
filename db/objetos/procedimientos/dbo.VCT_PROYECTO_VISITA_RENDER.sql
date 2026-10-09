 
/* ---------------- 6. render de la seccion ---------------- */
CREATE   PROCEDURE dbo.VCT_PROYECTO_VISITA_RENDER
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
