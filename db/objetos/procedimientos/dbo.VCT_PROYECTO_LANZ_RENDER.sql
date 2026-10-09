 
/* ---------------- 5. render de la seccion ---------------- */
CREATE    PROCEDURE dbo.VCT_PROYECTO_LANZ_RENDER
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
    /* Seccion "Lanzamiento" de la Vista 360 de Proyecto (pantalla del analista):
       1. Equipo  2. Datos de entrada  3. Consideraciones  4. Reunion de lanzamiento
       + boton "Iniciar proyecto". Los pasos son guia: no bloquean el inicio.
       Formularios en @FORMS (van a OUTPARAM3). No devuelve result sets. */
    SET NOCOUNT ON;
    SET @HTML = '';
    SET @FORMS = '';
 
    DECLARE @CAN_EDIT BIT = ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PROYECTOS.EDIT'),0);
 
    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT, @CLIENTE VARCHAR(300),
            @F_INI DATETIME, @F_FIN DATETIME, @F_INI_REAL DATETIME, @RIESGO VARCHAR(50), @ID_CONTACTO INT;
 
    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE, @CLIENTE = C.RAZON_SOCIAL,
           @F_INI = P.FECHA_INICIO, @F_FIN = P.FECHA_FIN, @F_INI_REAL = P.FECHA_INICIO_REAL,
           @RIESGO = P.NIVEL_RIESGO, @ID_CONTACTO = P.IDCONTACTO
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE
    WHERE P.ID = @ID_PROYECTO;
 
    IF @CODIGO IS NULL AND @NOMBRE IS NULL RETURN;
 
    DECLARE @EST_COD VARCHAR(30), @EST VARCHAR(100), @NLID INT, @NCONS_EQ INT, @NDATOS INT, @NCONSID INT, @REU BIT;
    SELECT @EST_COD = ESTADO_CODIGO, @EST = ESTADO, @NLID = LIDERES, @NCONS_EQ = CONSULTORES,
           @NDATOS = DATOS_CARGADOS, @NCONSID = CONSIDERACIONES, @REU = REUNION_OK
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);
 
    DECLARE @EN_LANZ BIT = CASE WHEN ISNULL(@EST_COD,'') IN ('BORRADOR','CONFIRMADO') THEN 1 ELSE 0 END;
 
    /* ---------- datos de apoyo ---------- */
    DECLARE @ANALISTA VARCHAR(400) = '', @CONSULTORES_TXT VARCHAR(2000) = '', @NORMAS VARCHAR(2000) = '',
            @DOMICILIO VARCHAR(600) = '', @CONTACTO VARCHAR(600) = '';
 
    SELECT TOP 1 @ANALISTA = LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,'')))
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    INNER JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'ANALISTA'
    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
 
    SELECT @CONSULTORES_TXT = @CONSULTORES_TXT + CASE WHEN @CONSULTORES_TXT = '' THEN '' ELSE '; ' END
                            + LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')'
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
 
    SELECT @NORMAS = @NORMAS + CASE WHEN @NORMAS = '' THEN '' ELSE ', ' END + N.DESCRIPCION
    FROM (SELECT DISTINCT PN.ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS PN
          WHERE PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA') X
    INNER JOIN dbo.VCT_PRM_NORMAS N ON N.ID = X.ID_NORMA;
 
    SELECT TOP 1 @DOMICILIO = LTRIM(RTRIM(ISNULL(D.CALLE,'') + ' ' + ISNULL(CONVERT(VARCHAR(20),D.NRO),'')
                 + CASE WHEN ISNULL(D.LOCALIDAD,'') <> '' THEN ', ' + D.LOCALIDAD ELSE '' END
                 + CASE WHEN ISNULL(D.PROVINCIA,'') <> '' THEN ', ' + D.PROVINCIA ELSE '' END))
    FROM dbo.VCT_DOMICILIOS D
    WHERE D.TIPO_ENTIDAD = 'CLIENTE' AND D.ID_ENTIDAD = @ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, D.ID;
 
    SELECT TOP 1 @CONTACTO = LTRIM(RTRIM(ISNULL(CT.NOMBRES,'') + ' ' + ISNULL(CT.APELLIDO,'')))
                 + CASE WHEN ISNULL(CT.CARGO,'') <> '' THEN ' - ' + CT.CARGO ELSE '' END
                 + CASE WHEN ISNULL(EM.EMAIL,'') <> '' THEN ' - ' + EM.EMAIL ELSE '' END
    FROM dbo.VCT_CONTACTOS CT
    LEFT JOIN dbo.VCT_EMAILS EM ON EM.ID = CT.ID_EMAIL
    WHERE CT.IDCLIENTE = @ID_CLIENTE
    ORDER BY CASE WHEN CT.ID = @ID_CONTACTO THEN 0 ELSE 1 END, CT.ID;
 
    /* ---------- gestion de lanzamiento ---------- */
    DECLARE @G_VENC DATETIME, @G_CIERRE DATETIME, @G_OBS VARCHAR(2000), @G_EST VARCHAR(100);
    SELECT TOP 1 @G_VENC = G.FECHA_VENCIMIENTO, @G_CIERRE = G.FECHA_CIERRE, @G_OBS = G.OBSERVACIONES, @G_EST = GE.DESCRIPCION
    FROM dbo.VCT_GESTIONES G
    INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'ASIGNACION_ANALISTA'
    ORDER BY G.ID DESC;
 
    /* ---------- 1. equipo ---------- */
    DECLARE @H_EQUIPO VARCHAR(MAX) = '';
    SELECT @H_EQUIPO = ISNULL((
        SELECT
            '<li class="vct-lanz-person">'
          + '<span class="vct-lanz-person-name">' + dbo.VCT_HTML_ESC(LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,'')))) + '</span>'
          + '<span class="vct-lanz-role' + CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN ' is-lead' ELSE '' END + '">' + dbo.VCT_HTML_ESC(R.DESCRIPCION) + '</span>'
          + CASE WHEN @CAN_EDIT = 1 THEN
                '<span class="vct-lanz-inline" data-vct-form-scope data-vct-lanz-quitar>'
              + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_EQUIPO_DEL" value="LANZ_EQUIPO_DEL">'
              + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), EQ.ID) + '" value="' + CONVERT(VARCHAR(20), EQ.ID) + '">'
              + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
              + '<button type="button" class="vct-lanz-icon-btn" data-vct-command="validate-next" title="Quitar del equipo" aria-label="Quitar del equipo">&times;</button>'
              + '</span>'
            ELSE '' END
          + '</li>'
        FROM dbo.VCT_PROYECTOS_EQUIPO EQ
        INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
        ORDER BY EQ.PRINCIPAL DESC, EQ.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    SET @H_EQUIPO =
        '<div class="vct-lanz-row"><span class="vct-lanz-k">Analista</span><span class="vct-lanz-v">' + CASE WHEN @ANALISTA = '' THEN 'Sin asignar' ELSE dbo.VCT_HTML_ESC(@ANALISTA) END + '</span></div>'
      + CASE WHEN @H_EQUIPO = '' THEN '<div class="vct-lanz-empty">Todav&iacute;a no hay consultores asignados.</div>'
             ELSE '<ul class="vct-lanz-people">' + @H_EQUIPO + '</ul>' END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzConsultor" data-vct-form-title="Agregar consultor" data-vct-form-subtitle="Consultores activos; primero los calificados en las normas del proyecto."><span data-vct-icon="user-plus"></span><span>Agregar consultor</span></button>'
        ELSE '' END;
 
    /* ---------- 2. datos de entrada ---------- */
    DECLARE @H_DATOS VARCHAR(MAX) = '';
    SELECT @H_DATOS = ISNULL((
        SELECT
            '<div class="vct-lanz-doc">'
          + '<div class="vct-lanz-doc-head"><b>' + dbo.VCT_HTML_ESC(M.SERVICIO) + '</b><span>'
          + CONVERT(VARCHAR(10), M.ITEMS_OK) + ' de ' + CONVERT(VARCHAR(10), M.ITEMS_TOTAL) + ' datos cargados</span></div>'
          + '<div class="vct-lanz-bar"><span style="width:' + CONVERT(VARCHAR(10), CASE WHEN M.ITEMS_TOTAL = 0 THEN 0 ELSE (M.ITEMS_OK * 100) / M.ITEMS_TOTAL END) + '%"></span></div>'
          + '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-lanz-open="vctLanzDatos' + CONVERT(VARCHAR(20), M.ID_DOCUMENTO) + '">'
          + '<span data-vct-icon="' + CASE WHEN @CAN_EDIT = 1 THEN 'edit' ELSE 'eye' END + '"></span><span>'
          + CASE WHEN @CAN_EDIT = 0 THEN 'Ver' WHEN M.ITEMS_OK = 0 THEN 'Completar' ELSE 'Ver / editar' END + '</span></button>'
          + '</div>'
        FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) M
        ORDER BY M.ID_SERVICIO
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    IF @H_DATOS = ''
        SET @H_DATOS = '<div class="vct-lanz-empty">El servicio del proyecto no tiene datos de entrada parametrizados.</div>';
 
    /* ---------- 3. consideraciones ---------- */
    DECLARE @H_CONS VARCHAR(MAX) = '';
    SELECT @H_CONS = ISNULL((
        SELECT TOP 5
            '<li class="vct-lanz-note">'
          + '<div class="vct-lanz-note-meta"><span class="vct-lanz-vis vct-lanz-vis-' + LOWER(ISNULL(I.GRUPO,'INTERNA')) + '">'
          + CASE ISNULL(I.GRUPO,'INTERNA') WHEN 'CONSULTOR' THEN 'Consultor' WHEN 'CLIENTE' THEN 'Cliente' ELSE 'Interna' END + '</span>'
          + '<span>' + CONVERT(VARCHAR(10), I.FECHA_ALTA, 103) + ' &middot; ' + dbo.VCT_HTML_ESC(ISNULL(I.USUARIO_ALTA,'')) + '</span></div>'
          + '<div class="vct-lanz-note-text">' + REPLACE(dbo.VCT_HTML_ESC(I.VALOR), CHAR(10), '<br>') + '</div>'
          + '</li>'
        FROM dbo.VCT_PROYECTOS_DOCUMENTOS D
        INNER JOIN dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS I ON I.ID_PROYECTO_DOCUMENTO = D.ID
        WHERE D.ID_PROYECTO = @ID_PROYECTO AND D.TIPO = 'CONS' AND I.CAMPO = 'CONSIDERACION'
        ORDER BY I.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    SET @H_CONS =
        CASE WHEN @H_CONS = '' THEN '<div class="vct-lanz-empty">Sin consideraciones. Ej.: &laquo;ojo con la log&iacute;stica&raquo;, d&iacute;as de acompa&ntilde;amiento en la auditor&iacute;a interna.</div>'
             ELSE '<ul class="vct-lanz-notes">' + @H_CONS + '</ul>'
                + CASE WHEN ISNULL(@NCONSID,0) > 5 THEN '<div class="vct-lanz-more">y ' + CONVERT(VARCHAR(10), @NCONSID - 5) + ' m&aacute;s</div>' ELSE '' END END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzCons"><span data-vct-icon="plus"></span><span>Agregar consideraci&oacute;n</span></button>'
        ELSE '' END;
 
    /* ---------- 4. reunion de lanzamiento ---------- */
    DECLARE @H_REU VARCHAR(MAX) =
        CASE WHEN @REU = 1 THEN
            '<div class="vct-lanz-row"><span class="vct-lanz-k">Realizada</span><span class="vct-lanz-v">' + ISNULL(CONVERT(VARCHAR(10), @G_CIERRE, 103), '-') + '</span></div>'
          + CASE WHEN ISNULL(@G_OBS,'') <> '' THEN '<div class="vct-lanz-note-text vct-lanz-muted">' + dbo.VCT_HTML_ESC(@G_OBS) + '</div>' ELSE '' END
        ELSE
            '<div class="vct-lanz-row"><span class="vct-lanz-k">Fecha l&iacute;mite</span><span class="vct-lanz-v">' + ISNULL(CONVERT(VARCHAR(10), @G_VENC, 103), 'Sin definir') + '</span></div>'
          + '<div class="vct-lanz-empty">Se explica el proyecto al consultor: d&iacute;as por mes, auditor&iacute;a interna, acompa&ntilde;amientos y puntos de atenci&oacute;n.</div>'
        END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzReunion"><span data-vct-icon="calendar"></span><span>'
          + CASE WHEN @REU = 1 THEN 'Actualizar reuni&oacute;n' ELSE 'Registrar reuni&oacute;n' END + '</span></button>'
        ELSE '' END;
 
    /* ---------- armado de la seccion ---------- */
    DECLARE @PASOS INT = CASE WHEN ISNULL(@NCONS_EQ,0) > 0 THEN 1 ELSE 0 END + CASE WHEN ISNULL(@NDATOS,0) > 0 THEN 1 ELSE 0 END
                       + CASE WHEN ISNULL(@NCONSID,0) > 0 THEN 1 ELSE 0 END + CASE WHEN @REU = 1 THEN 1 ELSE 0 END;
 
    SET @HTML =
        '<div class="vct-360-box vct-lanz" data-vct-lanz>'
      + '<div class="vct-360-box-head vct-lanz-head">'
      +   '<div><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>'
      +   CASE WHEN @EN_LANZ = 1 THEN 'Lanzamiento del proyecto' ELSE 'Equipo y datos de entrada' END + '</h3>'
      +   '<p class="vct-360-box-subtitle">'
      +   CASE WHEN @EN_LANZ = 1 THEN 'Asignar el equipo, cargar los datos de entrada y las consideraciones, hacer la reuni&oacute;n de lanzamiento e iniciar el proyecto.'
               ELSE 'Proyecto ' + dbo.VCT_HTML_ESC(LOWER(ISNULL(@EST,''))) + CASE WHEN @F_INI_REAL IS NOT NULL THEN ' desde el ' + CONVERT(VARCHAR(10), @F_INI_REAL, 103) ELSE '' END + '.' END
      +   '</p></div>'
      +   CASE WHEN @EN_LANZ = 1 THEN '<span class="vct-lanz-progress"><b>' + CONVERT(VARCHAR(2), @PASOS) + '</b> de 4 pasos</span>' ELSE '' END
      + '</div>'
      + CASE WHEN ISNULL(@ERROR,'') <> '' THEN '<div class="vct-lanz-alert is-error">' + dbo.VCT_HTML_ESC(@ERROR) + '</div>'
             WHEN ISNULL(@MENSAJE,'') <> '' THEN '<div class="vct-lanz-alert is-ok">' + dbo.VCT_HTML_ESC(@MENSAJE) + '</div>'
             ELSE '' END
      + '<div class="vct-lanz-steps">'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NCONS_EQ,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">1</span><h4>Equipo</h4></header>' + @H_EQUIPO + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NDATOS,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">2</span><h4>Datos de entrada</h4></header>' + @H_DATOS + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NCONSID,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">3</span><h4>Consideraciones</h4></header>' + @H_CONS + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN @REU = 1 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">4</span><h4>Reuni&oacute;n de lanzamiento</h4></header>' + @H_REU + '</section>'
      + '</div>'
      + CASE WHEN @EN_LANZ = 1 AND @CAN_EDIT = 1 THEN
            '<div class="vct-lanz-foot" data-vct-form-scope data-vct-lanz-iniciar data-pasos="' + CONVERT(VARCHAR(2), @PASOS) + '">'
          + '<span class="vct-lanz-foot-text">Al iniciar, el proyecto pasa a <b>En curso</b> y el consultor l&iacute;der recibe la tarea de armar el Plan Estrat&eacute;gico.</span>'
          + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_INICIAR" value="LANZ_INICIAR">'
          + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
          + '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next"><span data-vct-icon="check"></span><span>Iniciar proyecto</span></button>'
          + '</div>'
        ELSE '' END
      + '</div>';
 
    /* ============================================================
       FORMULARIOS
       ============================================================ */
    IF @CAN_EDIT = 0 AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO)) RETURN;
 
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
        COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
        HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
    );
    DECLARE @F VARCHAR(MAX), @OPT VARCHAR(MAX);
 
    IF @CAN_EDIT = 1
    BEGIN
        /* ---- agregar consultor ---- */
        SELECT @OPT = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), X.ID) + '">' + dbo.VCT_HTML_ESC(X.NOMBRE)
                 + CASE WHEN X.CAL = 1 THEN ' &#9733; calificado' ELSE '' END + '</option>'
            FROM
            (
                SELECT C.ID, LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,''))) AS NOMBRE,
                       CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS CN
                                         INNER JOIN dbo.VCT_PROYECTOS_NORMAS PN ON PN.ID_NORMA = CN.ID_NORMA AND PN.ID_PROYECTO = @ID_PROYECTO
                                         WHERE CN.ID_CONSULTOR = C.ID) THEN 1 ELSE 0 END AS CAL
                FROM dbo.VCT_CONSULTORES C
                WHERE UPPER(ISNULL(C.ESTADO,'')) = 'ACTIVO'
                  AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                                  WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                                    AND EQ.ID_CONSULTOR = C.ID AND EQ.ESTADO = 'ACTIVO')
            ) X
            ORDER BY X.CAL DESC, X.NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Consultor','TEXT',8,1,20,NULL,NULL,NULL,0,0,'&#9733; = calificado en alguna norma del proyecto.',NULL),
        (2,'TEXTO12','Rol','TEXT',4,1,30,NULL,NULL,CASE WHEN ISNULL(@NLID,0) = 0 THEN 'CONSULTOR_LIDER' ELSE 'CONSULTOR' END,0,0,NULL,NULL),
        (3,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_EQUIPO_ADD',0,1,NULL,NULL),
        (4,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzConsultor', @TITLE='Agregar consultor',
             @SUBTITLE='Consultores activos; primero los calificados en las normas del proyecto.', @ICON='user-plus',
             @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + ISNULL(@F,'')
            + '<template data-vct-field-options data-vct-target="vctLanzConsultor" data-vct-field="TEXTO11" data-vct-placeholder="Seleccione un consultor">' + @OPT + '</template>'
            + '<template data-vct-field-options data-vct-target="vctLanzConsultor" data-vct-field="TEXTO12" data-vct-placeholder="Seleccione"><option value="CONSULTOR_LIDER">Consultor l&iacute;der</option><option value="CONSULTOR">Consultor</option></template>';
 
        /* ---- consideracion ---- */
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Consideraci&oacute;n','TEXTAREA',12,1,4000,'Ej.: ojo con la log&iacute;stica de la planta; a los 10 meses hay auditor&iacute;a interna con 2 d&iacute;as de acompa&ntilde;amiento.',NULL,NULL,0,0,NULL,NULL),
        (2,'TEXTO12','Visible para','TEXT',6,1,20,NULL,NULL,'INTERNA',0,0,'Interna: solo la consultora.',NULL),
        (3,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_CONS',0,1,NULL,NULL),
        (4,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzCons', @TITLE='Nueva consideraci&oacute;n',
             @SUBTITLE='Queda registrada con autor y fecha.', @ICON='clipboard-check',
             @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + ISNULL(@F,'')
            + '<template data-vct-field-options data-vct-target="vctLanzCons" data-vct-field="TEXTO12" data-vct-placeholder="Seleccione"><option value="INTERNA">Interna</option><option value="CONSULTOR">Consultor</option><option value="CLIENTE">Cliente</option></template>';
 
        /* ---- reunion de lanzamiento ---- */
        DECLARE @PARTIC VARCHAR(2000) = LTRIM(RTRIM(CASE WHEN @ANALISTA <> '' THEN @ANALISTA + ' (Analista)' ELSE '' END
                                       + CASE WHEN @ANALISTA <> '' AND @CONSULTORES_TXT <> '' THEN '; ' ELSE '' END + @CONSULTORES_TXT));
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Fecha de la reuni&oacute;n','DATE',6,1,NULL,'Seleccionar fecha',NULL,CONVERT(VARCHAR(10), ISNULL(@G_CIERRE, GETDATE()), 23),0,0,NULL,NULL),
        (2,'TEXTO12','Participantes','TEXT',12,0,1000,NULL,NULL,LEFT(@PARTIC,1000),0,0,NULL,NULL),
        (3,'TEXTO13','Notas','TEXTAREA',12,0,1500,'Qu&eacute; se le explic&oacute; al consultor: d&iacute;as por mes, auditor&iacute;a interna, acompa&ntilde;amientos, puntos de atenci&oacute;n.',NULL,NULL,0,0,NULL,NULL),
        (4,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_REUNION',0,1,NULL,NULL),
        (5,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
 
        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzReunion', @TITLE='Reuni&oacute;n de lanzamiento',
             @SUBTITLE='Cierra la gesti&oacute;n de lanzamiento del analista.', @ICON='calendar',
             @LAYOUT='MODAL', @SAVE_LABEL='Guardar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ');
    END;
 
    /* ---- datos de entrada: un modal por minuta (campos libres) ---- */
    DECLARE @ID_DOC INT, @DOC_TIT VARCHAR(400), @ID_PD INT, @Q VARCHAR(MAX), @SLOTS VARCHAR(MAX) = '', @I INT = 11;
    WHILE @I <= 29
    BEGIN
        SET @SLOTS = @SLOTS + '<input type="hidden" name="SP.TEXTO' + CONVERT(VARCHAR(2), @I) + '" data-vct-field="TEXTO' + CONVERT(VARCHAR(2), @I) + '" data-vct-default="" value="" data-vct-lanz-slot>';
        SET @I = @I + 1;
    END;
 
    DECLARE C_DOC CURSOR LOCAL FAST_FORWARD FOR
        SELECT ID_DOCUMENTO, SERVICIO, ID_PROYECTO_DOCUMENTO FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) ORDER BY ID_SERVICIO;
    OPEN C_DOC;
    FETCH NEXT FROM C_DOC INTO @ID_DOC, @DOC_TIT, @ID_PD;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Q = ISNULL((
            SELECT
                '<div class="vct-field ' + CASE WHEN LEN(I.DESCRIPCION) > 55 THEN 'vct-col-12' ELSE 'vct-col-6' END + '">'
              + '<label class="vct-label">' + dbo.VCT_HTML_ESC(LTRIM(RTRIM(I.DESCRIPCION))) + '</label>'
              + '<textarea class="vct-textarea vct-lanz-q" rows="1" data-lanz-item="' + CONVERT(VARCHAR(20), I.ID) + '"'
              + CASE WHEN @CAN_EDIT = 0 THEN ' readonly' ELSE '' END + '>'
              + dbo.VCT_HTML_ESC(COALESCE(PI.VALOR,
                    CASE
                        WHEN I.CAMPO = 'CODIGO' AND I.DESCRIPCION NOT LIKE '%propuesta%' THEN @CODIGO
                        WHEN I.DESCRIPCION LIKE 'Normas%' THEN NULLIF(@NORMAS,'')
                        WHEN I.CAMPO = 'RAZON_SOCIAL_CLIENTE' THEN @CLIENTE
                        WHEN I.CAMPO = 'DOMICILIO' THEN NULLIF(@DOMICILIO,'')
                        WHEN I.CAMPO = 'CONTACTO_CLIENTE' THEN NULLIF(@CONTACTO,'')
                        WHEN I.CAMPO = 'OBSERVACIONES' THEN NULLIF(@ANALISTA,'')
                        WHEN I.CAMPO = 'NORMAS' THEN NULLIF(@NORMAS,'')
                        WHEN I.CAMPO = 'FECHA_INICIO_REAL' THEN CONVERT(VARCHAR(10), @F_INI, 103)
                        WHEN I.CAMPO = 'FECHA_FIN_REAL' THEN CONVERT(VARCHAR(10), @F_FIN, 103)
                        WHEN I.DESCRIPCION LIKE 'Profesional%' THEN NULLIF(@CONSULTORES_TXT,'')
                        WHEN I.DESCRIPCION LIKE 'Nivel de Riesgo%' THEN @RIESGO
                    END, ''))
              + '</textarea></div>'
            FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
            LEFT JOIN dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                   ON PI.ID_PROYECTO_DOCUMENTO = @ID_PD AND PI.ID_DOCUMENTO_ITEM = I.ID
            WHERE I.ID_DOCUMENTO = @ID_DOC AND I.ACTIVO = 1 AND UPPER(ISNULL(I.GRUPO,'')) <> 'CIERRE'
            ORDER BY ISNULL(I.ORDEN, 999), I.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
        SET @FORMS = @FORMS
          + '<div id="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" class="vct-modal vct-form-shell vct-form-large vct-lanz-datos" data-vct-component="modal" data-vct-id="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" data-vct-form-scope data-vct-form-size="large" data-vct-lanz-datos>'
          + '<div class="vct-modal-backdrop" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '"></div>'
          + '<div class="vct-modal-dialog">'
          +   '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div>'
          +     '<div class="vct-form-header-icon" data-vct-form-icon-wrap><span data-vct-icon="file-text" data-vct-form-icon></span></div>'
          +     '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-form-title>Datos de entrada &middot; ' + dbo.VCT_HTML_ESC(@DOC_TIT) + '</h3>'
          +     '<p class="vct-modal-subtitle" data-vct-form-subtitle>Todo lo que antes iba en la minuta de gesti&oacute;n. Campos libres: complet&aacute; lo que aplique.</p></div>'
          +     '<button type="button" class="vct-form-close" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" aria-label="Cerrar">&times;</button>'
          +   '</div>'
          +   '<div class="vct-modal-body vct-form-body">'
          +     '<div class="vct-validation-box" data-vct-validation-box style="display:none;"></div>'
          +     '<div class="vct-lanz-search"><span data-vct-icon="search"></span><input type="text" class="vct-input" placeholder="Buscar un dato..." data-vct-lanz-filter autocomplete="off"></div>'
          +     '<div class="vct-form-grid">' + @Q + '</div>'
          +     '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), @ID_DOC) + '" value="' + CONVERT(VARCHAR(20), @ID_DOC) + '">'
          +     '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_DATOS" value="LANZ_DATOS">'
          +     @SLOTS
          +     '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
          +   '</div>'
          +   '<div class="vct-modal-footer vct-form-footer">'
          +     '<span class="vct-lanz-count" data-vct-lanz-count></span>'
          +     '<button type="button" class="vct-btn vct-btn-secondary" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '">' + CASE WHEN @CAN_EDIT = 1 THEN 'Cancelar' ELSE 'Cerrar' END + '</button>'
          +     CASE WHEN @CAN_EDIT = 1 THEN '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next"><span data-vct-icon="save"></span><span>Guardar</span></button>' ELSE '' END
          +   '</div>'
          + '</div></div>';
 
        FETCH NEXT FROM C_DOC INTO @ID_DOC, @DOC_TIT, @ID_PD;
    END;
    CLOSE C_DOC;
    DEALLOCATE C_DOC;
END
