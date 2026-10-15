/* ========================================================================
   PROYECTO_ALTA_2_SP                                       (paso 2 de 3)
   ------------------------------------------------------------------------
   Requiere PROYECTO_ALTA_1_MODELO.sql. Crea 3 SP nuevos, escritos desde
   cero. No toca permisos, vistas ni funciones. Re-ejecutable.

   dbo.VCT_ACCIONES_EVENTO        motor del workflow (reutilizable por
                                  todos los pasos): genera las acciones de
                                  un evento segun VCT_PRM_ACCIONES_REGLAS y
                                  despues manda sus mails.
   dbo.VCT_PROYECTO_ALTA_RENDER   formulario "Nuevo proyecto" (pagina
                                  completa, VCT_MAIN_RENDER_FORM PAGE).
   dbo.VCT_PROYECTO_ALTA_GUARDAR  valida y graba el alta en una transaccion
                                  y dispara los eventos del workflow.

   Reglas de diseno (acordadas):
   - Permisos: solo dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,'PROYECTOS'), accion
     de tipo CREATE. Ningun perfil, rol de usuario ni usuario en el codigo.
   - Tipificacion, estado inicial, prioridad, responsable, vencimiento y
     mail de cada accion salen de VCT_PRM_ACCIONES_REGLAS (por evento).
   - Mail: template = VCT_PRM_EMAIL_TEMPLATES.ID de la regla. Asunto y
     cuerpo los resuelve dbo.VCT_MAIN_SEND_EMAIL. Destinatario: el mail
     cargado en el formulario; si viene vacio, el que resuelve el template
     segun su DESTINO_TIPO (ANALISTA/CONSULTOR/CLIENTE -> VCT_EMAILS,
     LIBRE -> DESTINO_LIBRE). CC siempre segun CC_TIPO del template.
   - Perfil de Database Mail: el perfil por defecto de msdb (no se escribe
     el nombre en el codigo).
   Codigos fijos que SI estan en el codigo (son nombres de pasos o valores
   de dominio, no roles ni usuarios):
     eventos PROYECTO_ALTA / ANALISTA_ASIGNADO,
     estado inicial del proyecto CONFIRMADO (VCT_PRM_PROYECTOS_ESTADOS),
     tipo proyecto IMPLEMENTACION / MANTENIMIENTO, riesgo Bajo/Medio/Alto,
     servicio CONSULTORIA (exige normas).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#ALTA2_RUN') IS NOT NULL DROP TABLE #ALTA2_RUN;
CREATE TABLE #ALTA2_RUN (INICIO DATETIME, TRG_ON BIT);
INSERT INTO #ALTA2_RUN VALUES (DATEADD(SECOND,-2,GETDATE()), 0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #ALTA2_RUN SET TRG_ON = 1;
END;
GO

/* ========================================================================
   1. dbo.VCT_ACCIONES_EVENTO
   ------------------------------------------------------------------------
   Contrato: el SP que llama crea antes
       CREATE TABLE #EV_ACC (ID_ACCION INT, ID_REGLA INT);
   @FASE = 'ACCIONES'  (dentro de la transaccion del llamador)
       Por cada regla ACTIVA de @CODIGO_EVENTO (orden ID):
         - VCT_ACCIONES: tipo/subtipo/estado/prioridad de la regla,
           ID_REGLA_ORIGEN = regla, titulo/detalle = plantillas de la regla.
           Vencimiento: si el estado inicial no es final -> @FECHA_VENCE
           (formulario) o, si no vino, hoy + DIAS_VENCIMIENTO.
           Si el estado es final (ES_FINAL=1) -> FECHA_CIERRE = ahora.
         - Responsable (VCT_ACCIONES_PARTICIPANTES, RESPONSABLE): integrante
           de VCT_PROYECTOS_EQUIPO cuyo rol (VCT_PRM_PROYECTOS_ROLES.CODIGO)
           = DESTINATARIO_ROL de la regla.
         - VCT_ACCIONES_HISTORIAL: alta de la accion.
         - Agrega la accion a #EV_ACC.
   @FASE = 'MAILS'  (despues del COMMIT del llamador)
       Para cada accion de #EV_ACC cuya regla tenga GENERA_EMAIL = 1:
         template  = VCT_PRM_EMAIL_TEMPLATES.ID = regla.ID_EMAIL_TEMPLATE
         contenido = EXEC dbo.VCT_MAIN_SEND_EMAIL (modo preview, sin perfil)
                     + variables propias del workflow:
                     {{CODIGO_PROYECTO}} {{SERVICIOS}} {{NORMAS}}
                     {{FECHA_VENCIMIENTO}} {{FECHA_LANZAMIENTO}}
         destino   = @EMAIL_DESTINO (formulario) si viene cargado;
                     si no, DESTINATARIO resuelto por el template.
         cc        = CC resuelto por el template (CC_TIPO / CC_LIBRE).
       El resultado (enviado / motivo de no envio) queda en
       VCT_ACCIONES_HISTORIAL de esa accion.
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_ACCIONES_EVENTO
(
    @CODIGO_EVENTO VARCHAR(100),
    @FASE          VARCHAR(10),
    @ID_PROYECTO   INT,
    @ID_CLIENTE    INT,
    @IAGENTE       VARCHAR(100),
    @FECHA_VENCE   DATETIME      = NULL,
    @EMAIL_DESTINO VARCHAR(1000) = NULL
)
AS
BEGIN
    /* VCT_ACCIONES_EVENTO_V1 */
    SET NOCOUNT ON;

    DECLARE @PRY_COD VARCHAR(100) = '', @PRY_NOM VARCHAR(300) = '', @CLI_NOM VARCHAR(300) = '',
            @SERV VARCHAR(2000) = '', @NORM VARCHAR(2000) = '', @AHORA DATETIME = GETDATE();

    SELECT @PRY_COD = ISNULL(P.CODIGO,''), @PRY_NOM = ISNULL(P.NOMBRE,''), @CLI_NOM = ISNULL(C.RAZON_SOCIAL,'')
    FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
    LEFT JOIN dbo.VCT_CLIENTES C WITH(NOLOCK) ON C.ID = P.IDCLIENTE
    WHERE P.ID = @ID_PROYECTO;

    SELECT @SERV = ISNULL(STUFF((
        SELECT ', ' + S.DESCRIPCION
        FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO
        WHERE PS.ID_PROYECTO = @ID_PROYECTO ORDER BY PS.ORDEN
        FOR XML PATH(''), TYPE).value('.','VARCHAR(2000)'), 1, 2, ''), '');

    SELECT @NORM = ISNULL(STUFF((
        SELECT ', ' + N.DESCRIPCION
        FROM dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_NORMAS N WITH(NOLOCK) ON N.ID = PN.ID_NORMA
        WHERE PN.ID_PROYECTO = @ID_PROYECTO ORDER BY PN.PRINCIPAL DESC, N.DESCRIPCION
        FOR XML PATH(''), TYPE).value('.','VARCHAR(2000)'), 1, 2, ''), '');

    /* ------------------------------------------------------------------
       FASE ACCIONES
       ------------------------------------------------------------------ */
    IF UPPER(@FASE) = 'ACCIONES'
    BEGIN
        DECLARE @R_ID INT, @R_COD VARCHAR(100), @R_TIPO INT, @R_SUB INT, @R_EST INT, @R_PRI INT,
                @R_ROL VARCHAR(100), @R_TIT VARCHAR(300), @R_DET VARCHAR(MAX), @R_DIAS INT,
                @ES_FINAL BIT, @VENCE DATETIME, @TIT VARCHAR(300), @DET VARCHAR(MAX),
                @ID_ACC INT, @ID_PADRE INT = NULL, @RESP_TM VARCHAR(20), @RESP_ID INT;

        DECLARE C_REG CURSOR LOCAL FAST_FORWARD FOR
            SELECT R.ID, R.CODIGO, R.ID_TIPO, R.ID_SUBTIPO, R.ID_ESTADO_INICIAL, R.ID_PRIORIDAD,
                   NULLIF(LTRIM(RTRIM(ISNULL(R.DESTINATARIO_ROL,''))),''), R.TITULO_PLANTILLA, R.DETALLE_PLANTILLA, R.DIAS_VENCIMIENTO
            FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
            WHERE R.CODIGO_EVENTO = @CODIGO_EVENTO AND R.ACTIVO = 1
            ORDER BY R.ID;
        OPEN C_REG;
        FETCH NEXT FROM C_REG INTO @R_ID, @R_COD, @R_TIPO, @R_SUB, @R_EST, @R_PRI, @R_ROL, @R_TIT, @R_DET, @R_DIAS;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @ES_FINAL = ISNULL(ES_FINAL,0) FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ID = @R_EST;

            SET @VENCE = CASE WHEN ISNULL(@ES_FINAL,0) = 1 THEN NULL
                              WHEN @FECHA_VENCE IS NOT NULL THEN @FECHA_VENCE
                              WHEN @R_DIAS IS NOT NULL THEN DATEADD(DAY, @R_DIAS, CONVERT(DATE,@AHORA))
                              ELSE NULL END;

            SET @TIT = ISNULL(@R_TIT,'');
            SET @TIT = REPLACE(REPLACE(REPLACE(@TIT,'{{CODIGO_PROYECTO}}',@PRY_COD),'{{PROYECTO}}',@PRY_NOM),'{{CLIENTE}}',@CLI_NOM);
            SET @DET = ISNULL(@R_DET,'');
            SET @DET = REPLACE(REPLACE(REPLACE(@DET,'{{CODIGO_PROYECTO}}',@PRY_COD),'{{PROYECTO}}',@PRY_NOM),'{{CLIENTE}}',@CLI_NOM);
            SET @DET = REPLACE(REPLACE(@DET,'{{SERVICIOS}}',@SERV),'{{NORMAS}}',@NORM);

            INSERT INTO dbo.VCT_ACCIONES
                (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO, ID_ACCION_PADRE, ID_REGLA_ORIGEN,
                 TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, REQUIERE_RESPUESTA, REQUIERE_APROBACION,
                 FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
            VALUES
                ('AUTOMATICA', @R_TIPO, @R_SUB, @R_EST, @R_PRI, NULL, @ID_PADRE, @R_ID,
                 LEFT(@TIT,300), NULLIF(@DET,''), @ID_CLIENTE, @ID_PROYECTO, 0, 0,
                 @AHORA, @AHORA, @VENCE, CASE WHEN ISNULL(@ES_FINAL,0) = 1 THEN @AHORA END, @AHORA, @IAGENTE);
            SET @ID_ACC = SCOPE_IDENTITY();
            UPDATE dbo.VCT_ACCIONES SET CODIGO = 'ACC-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_ACC), 9) WHERE ID = @ID_ACC;
            IF @ID_PADRE IS NULL SET @ID_PADRE = @ID_ACC;

            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
            VALUES (@ID_ACC, NULL, @R_EST, NULL, 'CREADA', LEFT('Generada por la regla ' + @R_COD + ' (evento ' + @CODIGO_EVENTO + ').', 2000), 'USUARIO', NULL, @AHORA, @IAGENTE);

            /* Responsable: rol de la regla -> integrante del equipo del proyecto */
            IF @R_ROL IS NOT NULL
            BEGIN
                SET @RESP_TM = NULL; SET @RESP_ID = NULL;
                SELECT TOP 1 @RESP_TM = EQ.TIPO_MIEMBRO,
                             @RESP_ID = CASE EQ.TIPO_MIEMBRO WHEN 'EMPLEADO' THEN EQ.ID_EMPLEADO WHEN 'CONSULTOR' THEN EQ.ID_CONSULTOR END
                FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES RL WITH(NOLOCK) ON RL.ID = EQ.ID_ROL
                WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND RL.CODIGO = @R_ROL AND EQ.ESTADO = 'ACTIVO'
                ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

                IF @RESP_ID IS NOT NULL
                    INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_ACC, 'RESPONSABLE', @RESP_TM, @RESP_ID, 1, 'ACTIVO', @AHORA, @AHORA, @IAGENTE);
                ELSE
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
                    VALUES (@ID_ACC, NULL, NULL, NULL, 'SIN_RESPONSABLE', LEFT('No hay integrante activo con rol ' + @R_ROL + ' en el equipo del proyecto.', 2000), 'SISTEMA', NULL, @AHORA, @IAGENTE);
            END;

            INSERT INTO #EV_ACC (ID_ACCION, ID_REGLA) VALUES (@ID_ACC, @R_ID);
            FETCH NEXT FROM C_REG INTO @R_ID, @R_COD, @R_TIPO, @R_SUB, @R_EST, @R_PRI, @R_ROL, @R_TIT, @R_DET, @R_DIAS;
        END;
        CLOSE C_REG; DEALLOCATE C_REG;
        RETURN;
    END;

    /* ------------------------------------------------------------------
       FASE MAILS
       ------------------------------------------------------------------ */
    IF UPPER(@FASE) = 'MAILS'
    BEGIN
        DECLARE @PROFILE SYSNAME = NULL;
        BEGIN TRY
            /* perfil por defecto de Database Mail (no se escribe en el codigo) */
            SELECT TOP 1 @PROFILE = P.name
            FROM msdb.dbo.sysmail_profile P
            INNER JOIN msdb.dbo.sysmail_principalprofile PP ON PP.profile_id = P.profile_id
            WHERE PP.is_default = 1
            ORDER BY CASE WHEN PP.principal_sid = 0x00 THEN 1 ELSE 0 END, P.profile_id;
            IF @PROFILE IS NULL AND (SELECT COUNT(*) FROM msdb.dbo.sysmail_profile) = 1
                SELECT @PROFILE = name FROM msdb.dbo.sysmail_profile;
        END TRY
        BEGIN CATCH
            SET @PROFILE = NULL;
        END CATCH;

        CREATE TABLE #MAIL (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));

        DECLARE @M_ACC INT, @M_TPL INT, @T_COD VARCHAR(50), @T_EST VARCHAR(20), @T_DEST VARCHAR(20),
                @M_TM VARCHAR(20), @M_EID INT, @M_ID_AN INT, @M_ID_CO INT, @M_VENCE VARCHAR(10),
                @M_ASUNTO VARCHAR(500), @M_BODY VARCHAR(MAX), @M_TO VARCHAR(1000), @M_CC VARCHAR(1000),
                @M_ORIGEN VARCHAR(200), @M_NOTA VARCHAR(2000);

        DECLARE C_MAIL CURSOR LOCAL FAST_FORWARD FOR
            SELECT E.ID_ACCION, R.ID_EMAIL_TEMPLATE
            FROM #EV_ACC E
            INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = E.ID_REGLA
            WHERE R.GENERA_EMAIL = 1
            ORDER BY E.ID_ACCION;
        OPEN C_MAIL;
        FETCH NEXT FROM C_MAIL INTO @M_ACC, @M_TPL;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @M_NOTA = NULL; SET @T_COD = NULL; SET @T_EST = NULL; SET @T_DEST = NULL;

            /* 1. template de la regla */
            SELECT @T_COD = CODIGO, @T_EST = UPPER(ISNULL(ESTADO,'')), @T_DEST = UPPER(ISNULL(DESTINO_TIPO,''))
            FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK) WHERE ID = @M_TPL;

            IF @T_COD IS NULL
                SET @M_NOTA = 'Mail no enviado: la regla no tiene un template valido (ID_EMAIL_TEMPLATE).';
            ELSE IF @T_EST <> 'ACTIVO'
                SET @M_NOTA = 'Mail no enviado: el template ' + @T_COD + ' esta ' + @T_EST + '.';

            IF @M_NOTA IS NULL
            BEGIN
                /* 2. entidades para las variables del template: responsable de la accion */
                SET @M_TM = NULL; SET @M_EID = NULL;
                SELECT TOP 1 @M_TM = TIPO_ENTIDAD, @M_EID = ID_ENTIDAD
                FROM dbo.VCT_ACCIONES_PARTICIPANTES WITH(NOLOCK)
                WHERE ID_ACCION = @M_ACC AND ROL_PARTICIPANTE = 'RESPONSABLE'
                ORDER BY PRINCIPAL DESC, ID;
                SET @M_ID_AN = CASE WHEN @M_TM = 'EMPLEADO'  THEN @M_EID END;
                SET @M_ID_CO = CASE WHEN @M_TM = 'CONSULTOR' THEN @M_EID END;
                SELECT @M_VENCE = ISNULL(CONVERT(VARCHAR(10), FECHA_VENCIMIENTO, 103), '') FROM dbo.VCT_ACCIONES WITH(NOLOCK) WHERE ID = @M_ACC;

                /* 3. asunto, cuerpo, destinatario y cc: los resuelve el template */
                DELETE FROM #MAIL;
                BEGIN TRY
                    INSERT INTO #MAIL (ASUNTO, HTML_CONTENIDO, DESTINATARIO, CC, ENVIADO, ADVERTENCIA)
                    EXEC dbo.VCT_MAIN_SEND_EMAIL @CODIGO = @T_COD, @ID_CONSULTOR = @M_ID_CO, @ID_PROYECTO = @ID_PROYECTO,
                                                 @ID_ANALISTA = @M_ID_AN, @ID_CLIENTE = @ID_CLIENTE;   -- sin @PROFILE_NAME: solo resuelve
                END TRY
                BEGIN CATCH
                    SET @M_NOTA = LEFT('Mail no enviado: error al resolver el template ' + @T_COD + ': ' + ERROR_MESSAGE(), 2000);
                END CATCH;
            END;

            IF @M_NOTA IS NULL
            BEGIN
                SELECT TOP 1 @M_ASUNTO = ASUNTO, @M_BODY = HTML_CONTENIDO, @M_TO = DESTINATARIO, @M_CC = CC FROM #MAIL;

                /* variables propias del workflow */
                SET @M_ASUNTO = REPLACE(REPLACE(REPLACE(ISNULL(@M_ASUNTO,''),'{{CODIGO_PROYECTO}}',@PRY_COD),'{{SERVICIOS}}',@SERV),'{{NORMAS}}',@NORM);
                SET @M_ASUNTO = REPLACE(REPLACE(@M_ASUNTO,'{{FECHA_VENCIMIENTO}}',@M_VENCE),'{{FECHA_LANZAMIENTO}}',@M_VENCE);
                SET @M_BODY   = REPLACE(REPLACE(REPLACE(ISNULL(@M_BODY,''),'{{CODIGO_PROYECTO}}',@PRY_COD),'{{SERVICIOS}}',@SERV),'{{NORMAS}}',@NORM);
                SET @M_BODY   = REPLACE(REPLACE(@M_BODY,'{{FECHA_VENCIMIENTO}}',@M_VENCE),'{{FECHA_LANZAMIENTO}}',@M_VENCE);

                /* 4. destino: formulario si vino cargado; si no, el del template */
                IF NULLIF(LTRIM(RTRIM(ISNULL(@EMAIL_DESTINO,''))),'') IS NOT NULL
                BEGIN
                    SET @M_TO = LTRIM(RTRIM(@EMAIL_DESTINO));
                    SET @M_ORIGEN = 'mail cargado en el formulario';
                END
                ELSE
                    SET @M_ORIGEN = 'template ' + @T_COD + ' (DESTINO_TIPO=' + @T_DEST + ')';

                IF NULLIF(@M_TO,'') IS NULL
                    SET @M_NOTA = 'Mail no enviado: sin destinatario (' + @M_ORIGEN + ').';
                ELSE IF @PROFILE IS NULL
                    SET @M_NOTA = 'Mail no enviado: no hay perfil por defecto de Database Mail.';
                ELSE
                BEGIN
                    BEGIN TRY
                        EXEC msdb.dbo.sp_send_dbmail @profile_name = @PROFILE, @recipients = @M_TO, @copy_recipients = @M_CC,
                                                     @subject = @M_ASUNTO, @body = @M_BODY, @body_format = 'HTML';
                        SET @M_NOTA = LEFT('Mail enviado a ' + @M_TO + CASE WHEN NULLIF(@M_CC,'') IS NOT NULL THEN ' (cc ' + @M_CC + ')' ELSE '' END
                                      + ' con el template ' + @T_COD + '. Destino tomado de: ' + @M_ORIGEN + '.', 2000);
                    END TRY
                    BEGIN CATCH
                        SET @M_NOTA = LEFT('Mail no enviado: ' + ERROR_MESSAGE(), 2000);
                    END CATCH;
                END;
            END;

            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
            VALUES (@M_ACC, NULL, NULL, NULL, 'EMAIL', @M_NOTA, 'SISTEMA', NULL, GETDATE(), @IAGENTE);

            FETCH NEXT FROM C_MAIL INTO @M_ACC, @M_TPL;
        END;
        CLOSE C_MAIL; DEALLOCATE C_MAIL;
    END;
END
GO

/* ========================================================================
   2. dbo.VCT_PROYECTO_ALTA_RENDER
   ------------------------------------------------------------------------
   Formulario "Nuevo proyecto" en pagina completa. Lo llaman las pantallas
   de origen (Proyectos y, en el paso siguiente, Cliente 360).
     @ID_CLIENTE NULL  -> combo de cliente (desde Proyectos)
     @ID_CLIENTE <> 0  -> cliente fijo, no editable (desde Cliente 360)
     @ERROR <> ''      -> reabre con los valores enviados (buffer) y el error
   Campos del buffer (los lee VCT_PROYECTO_ALTA_GUARDAR):
     TEXTO11 nombre             TEXTO19 cliente (id)
     TEXTO12 referencia         TEXTO20 analista (VCT_EMPLEADOS.ID)
     TEXTO13 fecha inicio       TEXTO21 vence proxima accion
     TEXTO14 fecha fin          TEXTO22 servicios  id|inicio|fin|horas;...
     TEXTO15 total horas        TEXTO23 mail a notificar (editable)
     TEXTO16 tipo proyecto      TEXTO24 normas     id,id,...
     TEXTO18 nivel de riesgo    TEXTO25 honorarios  TEXTO26 viaticos pres.
     TEXTO27 costo estimado MO  TEXTO28 moneda      TEXTO30 comando
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_RENDER
(
    @IPKEYJOB   VARCHAR(100),
    @IUNIDAD    VARCHAR(100),
    @IAGENTE    VARCHAR(100),
    @ID_CLIENTE INT           = NULL,
    @ERROR      VARCHAR(1000) = '',
    @CMD_GUARDAR VARCHAR(50)  = 'PRY_ALTA_GUARDAR',
    @CMD_CANCELAR VARCHAR(50) = 'PRY_MODO_VIGENTES',
    @HTML       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ALTA_RENDER_V1 */
    SET NOCOUNT ON;
    SET @HTML = '';

    /* ---------- permiso: CREATE del modulo PROYECTOS ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
                   WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) IN ('CREATE','NEW','ADD','INSERT'))
    BEGIN
        SET @HTML = '<div class="vct-card"><div class="vct-card-body">No posee permisos para dar de alta proyectos.</div></div>';
        RETURN;
    END;

    DECLARE @FORM VARCHAR(50) = 'vctProyectoAlta', @REOPEN BIT = CASE WHEN ISNULL(@ERROR,'') <> '' THEN 1 ELSE 0 END,
            @B11 VARCHAR(4000)='', @B12 VARCHAR(4000)='', @B13 VARCHAR(4000)='', @B14 VARCHAR(4000)='', @B15 VARCHAR(4000)='',
            @B16 VARCHAR(4000)='', @B18 VARCHAR(4000)='', @B19 VARCHAR(4000)='', @B20 VARCHAR(4000)='', @B21 VARCHAR(4000)='',
            @B22 VARCHAR(4000)='', @B23 VARCHAR(4000)='', @B24 VARCHAR(4000)='', @B25 VARCHAR(4000)='', @B26 VARCHAR(4000)='',
            @B27 VARCHAR(4000)='', @B28 VARCHAR(4000)='', @CLI_NOM VARCHAR(300) = '';

    IF @REOPEN = 1
        SELECT TOP 1 @B11=ISNULL(TEXTO11,''), @B12=ISNULL(TEXTO12,''), @B13=ISNULL(TEXTO13,''), @B14=ISNULL(TEXTO14,''),
                     @B15=ISNULL(TEXTO15,''), @B16=ISNULL(TEXTO16,''), @B18=ISNULL(TEXTO18,''), @B19=ISNULL(TEXTO19,''),
                     @B20=ISNULL(TEXTO20,''), @B21=ISNULL(TEXTO21,''), @B22=ISNULL(TEXTO22,''), @B23=ISNULL(TEXTO23,''),
                     @B24=ISNULL(TEXTO24,''), @B25=ISNULL(TEXTO25,''), @B26=ISNULL(TEXTO26,''), @B27=ISNULL(TEXTO27,''),
                     @B28=ISNULL(TEXTO28,'')
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

    IF @ID_CLIENTE IS NOT NULL
    BEGIN
        SELECT @CLI_NOM = ISNULL(RAZON_SOCIAL,'') FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @ID_CLIENTE;
        SET @B19 = CONVERT(VARCHAR(20), @ID_CLIENTE);
    END;
    IF @B28 = '' SET @B28 = 'ARS';

    /* ---------- campos (renderer generico) ---------- */
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
        COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
        HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
    );

    IF @ID_CLIENTE IS NULL
        INSERT INTO #VCT_FORM_FIELDS VALUES (10,'TEXTO19','Cliente','TEXT',6,1,NULL,'Seleccione un cliente',NULL,NULLIF(@B19,''),0,0,NULL,NULL);
    ELSE
        INSERT INTO #VCT_FORM_FIELDS VALUES
            (10,'TEXTO19','Cliente','HIDDEN',12,0,NULL,NULL,NULL,@B19,0,1,NULL,NULL),
            (11,'TEXTO29','Cliente','TEXT',6,0,NULL,NULL,NULL,@CLI_NOM,1,0,'Viene fijo desde la Vista 360 del cliente.',NULL);

    INSERT INTO #VCT_FORM_FIELDS VALUES
        (20,'TEXTO16','Tipo proyecto','TEXT',3,1,NULL,'Seleccione',NULL,NULLIF(@B16,''),0,0,NULL,NULL),
        (30,'TEXTO18','Nivel de riesgo','TEXT',3,1,NULL,'Seleccione',NULL,NULLIF(@B18,''),0,0,NULL,NULL),
        (40,'TEXTO11','Nombre','TEXT',8,1,300,'Nombre del proyecto',NULL,NULLIF(@B11,''),0,0,NULL,NULL),
        (50,'TEXTO12','Referencia','TEXT',4,0,300,'Ej. numero de propuesta',NULL,NULLIF(@B12,''),0,0,NULL,NULL),
        (60,'TEXTO13','Fecha inicio','DATE',3,1,NULL,NULL,NULL,NULLIF(@B13,''),0,0,NULL,NULL),
        (70,'TEXTO14','Fecha fin','DATE',3,1,NULL,NULL,NULL,NULLIF(@B14,''),0,0,NULL,NULL),
        (80,'TEXTO15','Total horas proyecto','NUMBER',3,1,NULL,'0',NULL,NULLIF(@B15,''),0,0,'Tope para la suma de los servicios.',NULL),
        (85,'TEXTO28','Moneda','TEXT',3,1,NULL,NULL,NULL,@B28,0,0,NULL,NULL),
        (90,'TEXTO22','Servicios','HIDDEN',12,0,NULL,NULL,NULL,@B22,0,1,NULL,NULL),         -- ancla: bloque Servicios + Normas
        (100,'TEXTO24','Normas','HIDDEN',12,0,NULL,NULL,NULL,@B24,0,1,NULL,NULL),           -- ancla: titulo Rentabilidad
        (120,'TEXTO25','Honorarios presupuestados','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B25,''),0,0,NULL,NULL),
        (130,'TEXTO26','Vi&aacute;ticos presupuestados','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B26,''),0,0,NULL,NULL),
        (140,'TEXTO27','Costo estimado de horas','NUMBER',4,0,NULL,'0',NULL,NULLIF(@B27,''),0,0,NULL,NULL),
        (150,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,@CMD_GUARDAR,0,1,NULL,NULL),  -- ancla: titulo Proxima accion
        (160,'TEXTO20','Analista','TEXT',6,1,NULL,'Seleccione el analista',NULL,NULLIF(@B20,''),0,0,'Recibe la acci&oacute;n &ldquo;Asignar consultor&rdquo;.',NULL),
        (170,'TEXTO21','Vence','DATE',3,1,NULL,NULL,NULL,NULLIF(@B21,''),0,0,NULL,NULL),
        (180,'TEXTO23','Enviar mail a','EMAIL',9,0,1000,'mail@dominio.com',NULL,NULLIF(@B23,''),0,0,'Se completa con el mail del analista elegido; se puede modificar. Vac&iacute;o = destino del template.',NULL);

    DECLARE @HF VARCHAR(MAX) = '';
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID = @FORM, @TITLE = 'Nuevo proyecto',
         @SUBTITLE = 'El c&oacute;digo se asigna al guardar. Los campos con * son obligatorios.',
         @ICON = 'folder', @LAYOUT = 'PAGE', @SAVE_LABEL = 'Crear proyecto', @CANCEL_LABEL = 'Cancelar',
         @ERROR_MESSAGE = @ERROR, @OPEN_ON_RENDER = @REOPEN, @OUTHTML = @HF OUTPUT;

    SET @HF = REPLACE(ISNULL(@HF,''), 'type="date" ', 'type="date" data-vct-datepicker ');
    SET @HF = REPLACE(@HF, 'class="vct-card vct-form-shell ', 'class="vct-card vct-form-shell vct-pry-nuevo ');

    /* ---------- secciones e insertos en las anclas ---------- */
    DECLARE @P INT, @E INT,
            @SEC_DATOS VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Datos generales</div>',
            @SEC_SRV   VARCHAR(MAX),
            @SEC_RENT  VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Rentabilidad estimada <small>opcional</small></div>',
            @SEC_PROX  VARCHAR(500) = '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Pr&oacute;xima acci&oacute;n <small>Asignar consultor &middot; la recibe el analista</small></div>';

    SET @SEC_SRV =
          '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Servicios <small>una fila por servicio: fechas y horas. Nombre, lugar y responsable se completan al editar el servicio.</small></div>'
        + '<div class="vct-field vct-col-12"><div class="vct-pry-nuevo-srv" data-vct-pry-srv></div>'
        + '<div class="vct-pry-nuevo-bar" data-vct-pry-srv-bar></div></div>'
        + '<div class="vct-field vct-col-12 vct-pry-nuevo-sec">Normas <small>son del proyecto; obligatorias si hay consultor&iacute;a</small></div>'
        + '<div class="vct-field vct-col-12"><div class="vct-pry-nuevo-normas" data-vct-pry-normas></div></div>';

    SET @P = CHARINDEX('<div class="vct-form-grid">', @HF);
    IF @P > 0 SET @HF = STUFF(@HF, @P + LEN('<div class="vct-form-grid">'), 0, @SEC_DATOS);

    SET @P = CHARINDEX('name="SP.TEXTO22"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_SRV); END;
    SET @P = CHARINDEX('name="SP.TEXTO24"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_RENT); END;
    SET @P = CHARINDEX('name="SP.TEXTO30"', @HF);
    IF @P > 0 BEGIN SET @E = CHARINDEX('>', @HF, @P); SET @HF = STUFF(@HF, @E + 1, 0, @SEC_PROX); END;

    /* Cancelar: vuelve a la pantalla de origen con el mismo mecanismo de modo */
    SET @P = CHARINDEX('<div class="vct-card-footer vct-form-footer">', @HF);
    IF @P > 0
        SET @HF = STUFF(@HF, @P + LEN('<div class="vct-card-footer vct-form-footer">'), 0,
            '<button type="button" class="vct-btn vct-btn-secondary" data-vct-pry-modo="' + @CMD_CANCELAR + '">Cancelar</button>');

    /* ---------- opciones de los combos ---------- */
    DECLARE @O_CLI VARCHAR(MAX) = '', @O_ANA VARCHAR(MAX) = '', @C_SRV VARCHAR(MAX) = '', @C_NOR VARCHAR(MAX) = '';

    IF @ID_CLIENTE IS NULL
        SELECT @O_CLI = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), C.ID) + '">'
                 + REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_CLIENTES C WITH(NOLOCK)
            ORDER BY C.RAZON_SOCIAL
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* analistas = empleados activos; data-email = mail principal (VCT_EMAILS, EMPLEADO) */
    SELECT @O_ANA = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), E.ID) + '" data-email="'
             + REPLACE(ISNULL((SELECT TOP 1 M.EMAIL FROM dbo.VCT_EMAILS M WITH(NOLOCK)
                               WHERE M.TIPO_ENTIDAD = 'EMPLEADO' AND M.ID_ENTIDAD = E.ID
                               ORDER BY CASE WHEN M.PRINCIPAL = 'SI' THEN 0 ELSE 1 END, M.ID),''),'"','')
             + '">' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
        WHERE ISNULL(E.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY E.APELLIDOS, E.NOMBRES
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @C_SRV = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), S.ID) + '" data-codigo="' + UPPER(ISNULL(S.CODIGO,'')) + '">'
             + REPLACE(REPLACE(REPLACE(ISNULL(S.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
        WHERE ISNULL(S.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY S.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @C_NOR = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), N.ID) + '">'
             + REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
        WHERE ISNULL(N.ESTADO,'ACTIVO') = 'ACTIVO'
        ORDER BY N.DESCRIPCION
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @HTML = '<div class="vct-pry-nuevo-page">' + @HF
        + CASE WHEN @ID_CLIENTE IS NULL THEN
          '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO19" data-vct-placeholder="Seleccione un cliente">' + @O_CLI + '</template>' ELSE '' END
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO16" data-vct-placeholder="Seleccione">'
        +   '<option value="IMPLEMENTACION">Implementaci&oacute;n</option><option value="MANTENIMIENTO">Mantenimiento</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO18" data-vct-placeholder="Seleccione">'
        +   '<option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO28" data-vct-placeholder="Moneda">'
        +   '<option value="ARS">ARS</option><option value="USD">USD</option></template>'
        + '<template data-vct-field-options data-vct-target="' + @FORM + '" data-vct-field="TEXTO20" data-vct-placeholder="Seleccione el analista">' + @O_ANA + '</template>'
        + '<template data-vct-pry-catalog="servicios">' + @C_SRV + '</template>'
        + '<template data-vct-pry-catalog="normas">' + @C_NOR + '</template>'
        + '</div>';
END
GO

/* ========================================================================
   3. dbo.VCT_PROYECTO_ALTA_GUARDAR
   ------------------------------------------------------------------------
   Lee el formulario del buffer (ver mapa en VCT_PROYECTO_ALTA_RENDER),
   valida y graba en UNA transaccion:
     VCT_PROYECTOS                (estado CONFIRMADO, TIPO_PROYECTO)
     VCT_PROYECTOS_SERVICIOS      1 fila por servicio: inicio, fin, horas
     VCT_PROYECTOS_NORMAS         nivel proyecto (ID_PROYECTO_SERVICIO NULL)
     VCT_PROYECTOS_EQUIPO         el analista elegido, con el rol de
                                  VCT_PRM_PROYECTOS_ROLES cuyo TIPO_MIEMBRO
                                  es EMPLEADO (menor ORDEN)
     evento PROYECTO_ALTA         -> acciones de sus reglas
     evento ANALISTA_ASIGNADO     -> acciones de sus reglas (vence = form)
   Despues del COMMIT manda los mails de esas acciones (fase MAILS).
   Si el mail falla el alta NO se revierte: queda anotado en el historial.
   ======================================================================== */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_ALTA_GUARDAR
(
    @IPKEYJOB       VARCHAR(100),
    @IUNIDAD        VARCHAR(100),
    @IAGENTE        VARCHAR(100),
    @ID_CLIENTE_FIJO INT = NULL,
    @ID_PROYECTO    INT           OUTPUT,
    @ERROR          VARCHAR(1000) OUTPUT,
    @MENSAJE        VARCHAR(1000) OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ALTA_GUARDAR_V1 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ERROR = ''; SET @MENSAJE = ''; SET @ID_PROYECTO = NULL;

    /* codigos de dominio (ver encabezado del script) */
    DECLARE @EST_INICIAL VARCHAR(30) = 'CONFIRMADO',
            @SRV_EXIGE_NORMAS VARCHAR(30) = 'CONSULTORIA';

    /* ---------- permiso ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
                   WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) IN ('CREATE','NEW','ADD','INSERT'))
    BEGIN
        SET @ERROR = 'No posee permisos para dar de alta proyectos.';
        RETURN;
    END;

    /* ---------- buffer ---------- */
    DECLARE @T11 VARCHAR(4000), @T12 VARCHAR(4000), @T13 VARCHAR(4000), @T14 VARCHAR(4000), @T15 VARCHAR(4000),
            @T16 VARCHAR(4000), @T18 VARCHAR(4000), @T19 VARCHAR(4000), @T20 VARCHAR(4000), @T21 VARCHAR(4000),
            @T22 VARCHAR(4000), @T23 VARCHAR(4000), @T24 VARCHAR(4000), @T25 VARCHAR(4000), @T26 VARCHAR(4000),
            @T27 VARCHAR(4000), @T28 VARCHAR(4000);
    SELECT TOP 1
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))), @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))),
        @T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @T16 = UPPER(LTRIM(RTRIM(ISNULL(TEXTO16,'')))),
        @T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))), @T19 = LTRIM(RTRIM(ISNULL(TEXTO19,''))), @T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))),
        @T21 = LTRIM(RTRIM(ISNULL(TEXTO21,''))), @T22 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO22,''))),' ',''),
        @T23 = LTRIM(RTRIM(ISNULL(TEXTO23,''))), @T24 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO24,''))),' ',''),
        @T25 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO25,''))),',','.'), @T26 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO26,''))),',','.'),
        @T27 = REPLACE(LTRIM(RTRIM(ISNULL(TEXTO27,''))),',','.'), @T28 = UPPER(LTRIM(RTRIM(ISNULL(TEXTO28,''))))
    FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

    /* ---------- cliente ---------- */
    DECLARE @ID_CLIENTE INT = @ID_CLIENTE_FIJO;
    IF @ID_CLIENTE IS NULL AND @T19 <> '' AND @T19 NOT LIKE '%[^0-9]%' AND LEN(@T19) <= 9 SET @ID_CLIENTE = CONVERT(INT, @T19);
    IF @ID_CLIENTE IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CLIENTES WITH(NOLOCK) WHERE ID = @ID_CLIENTE)
    BEGIN SET @ERROR = 'Seleccione un cliente.'; RETURN; END;

    /* ---------- datos generales ---------- */
    IF @T11 = '' BEGIN SET @ERROR = 'Ingrese el nombre del proyecto.'; RETURN; END;
    IF @T16 NOT IN ('IMPLEMENTACION','MANTENIMIENTO') BEGIN SET @ERROR = 'Seleccione el tipo de proyecto.'; RETURN; END;
    IF @T18 NOT IN ('Bajo','Medio','Alto') BEGIN SET @ERROR = 'Seleccione el nivel de riesgo.'; RETURN; END;
    IF @T28 NOT IN ('ARS','USD') SET @T28 = 'ARS';

    /* fechas: yyyy-mm-dd (input date) o dd/mm/yyyy */
    DECLARE @F_INI DATE, @F_FIN DATE, @F_VEN DATE;
    SET @F_INI = CASE WHEN @T13 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(@T13) = 1 THEN CONVERT(DATE, @T13, 23)
                      WHEN @T13 LIKE '[0-3][0-9]/[01][0-9]/[12][0-9][0-9][0-9]' THEN CONVERT(DATE, @T13, 103) END;
    SET @F_FIN = CASE WHEN @T14 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(@T14) = 1 THEN CONVERT(DATE, @T14, 23)
                      WHEN @T14 LIKE '[0-3][0-9]/[01][0-9]/[12][0-9][0-9][0-9]' THEN CONVERT(DATE, @T14, 103) END;
    SET @F_VEN = CASE WHEN @T21 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(@T21) = 1 THEN CONVERT(DATE, @T21, 23)
                      WHEN @T21 LIKE '[0-3][0-9]/[01][0-9]/[12][0-9][0-9][0-9]' THEN CONVERT(DATE, @T21, 103) END;
    IF @F_INI IS NULL OR @F_FIN IS NULL BEGIN SET @ERROR = 'Ingrese fecha de inicio y fecha de fin validas.'; RETURN; END;
    IF @F_FIN < @F_INI BEGIN SET @ERROR = 'La fecha de fin no puede ser anterior a la fecha de inicio.'; RETURN; END;

    IF @T15 = '' OR @T15 LIKE '%[^0-9]%' OR LEN(@T15) > 6
    BEGIN SET @ERROR = 'Ingrese el total de horas del proyecto (entero mayor a 0).'; RETURN; END;
    DECLARE @HORAS INT = CONVERT(INT, @T15);
    IF @HORAS <= 0 BEGIN SET @ERROR = 'Ingrese el total de horas del proyecto (entero mayor a 0).'; RETURN; END;

    /* montos opcionales */
    DECLARE @M_HON DECIMAL(18,2), @M_VIA DECIMAL(18,2), @M_CMO DECIMAL(18,2);
    IF @T25 <> '' AND (@T25 LIKE '%[^0-9.]%' OR @T25 LIKE '%.%.%') BEGIN SET @ERROR = 'Honorarios: ingrese un numero.'; RETURN; END;
    IF @T26 <> '' AND (@T26 LIKE '%[^0-9.]%' OR @T26 LIKE '%.%.%') BEGIN SET @ERROR = 'Viaticos: ingrese un numero.'; RETURN; END;
    IF @T27 <> '' AND (@T27 LIKE '%[^0-9.]%' OR @T27 LIKE '%.%.%') BEGIN SET @ERROR = 'Costo de horas: ingrese un numero.'; RETURN; END;
    IF @T25 NOT IN ('','.') SET @M_HON = CONVERT(DECIMAL(18,2), @T25);
    IF @T26 NOT IN ('','.') SET @M_VIA = CONVERT(DECIMAL(18,2), @T26);
    IF @T27 NOT IN ('','.') SET @M_CMO = CONVERT(DECIMAL(18,2), @T27);

    /* ---------- servicios: id|inicio|fin|horas;... ---------- */
    DECLARE @SRV TABLE (ORDEN INT IDENTITY(1,1), ID_SERVICIO INT, CODIGO VARCHAR(30), F_INI DATE, F_FIN DATE, HORAS INT);
    DECLARE @LISTA VARCHAR(4000) = @T22 + ';', @ITEM VARCHAR(400), @POS INT, @A VARCHAR(100), @B VARCHAR(100), @C VARCHAR(100), @D VARCHAR(100);
    WHILE CHARINDEX(';', @LISTA) > 0
    BEGIN
        SET @POS = CHARINDEX(';', @LISTA);
        SET @ITEM = LEFT(@LISTA, @POS - 1) + '|||';
        SET @LISTA = SUBSTRING(@LISTA, @POS + 1, 4000);
        IF REPLACE(@ITEM,'|','') = '' CONTINUE;
        SET @A = LEFT(@ITEM, CHARINDEX('|', @ITEM) - 1);                      SET @ITEM = SUBSTRING(@ITEM, CHARINDEX('|', @ITEM) + 1, 400);
        SET @B = LEFT(@ITEM, CHARINDEX('|', @ITEM) - 1);                      SET @ITEM = SUBSTRING(@ITEM, CHARINDEX('|', @ITEM) + 1, 400);
        SET @C = LEFT(@ITEM, CHARINDEX('|', @ITEM) - 1);                      SET @ITEM = SUBSTRING(@ITEM, CHARINDEX('|', @ITEM) + 1, 400);
        SET @D = LEFT(@ITEM, CHARINDEX('|', @ITEM) - 1);
        IF @A = '' OR @A LIKE '%[^0-9]%' OR LEN(@A) > 9 BEGIN SET @ERROR = 'Servicio invalido.'; RETURN; END;
        IF @D = '' OR @D LIKE '%[^0-9]%' OR LEN(@D) > 6
        BEGIN SET @ERROR = 'Cada servicio debe tener horas proyectadas (entero mayor a 0).'; RETURN; END;
        IF CONVERT(INT, @D) <= 0
        BEGIN SET @ERROR = 'Cada servicio debe tener horas proyectadas (entero mayor a 0).'; RETURN; END;
        INSERT INTO @SRV (ID_SERVICIO, CODIGO, F_INI, F_FIN, HORAS)
        SELECT S.ID, UPPER(ISNULL(S.CODIGO,'')),
               CASE WHEN @B LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(@B) = 1 THEN CONVERT(DATE, @B, 23) END,
               CASE WHEN @C LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(@C) = 1 THEN CONVERT(DATE, @C, 23) END,
               CONVERT(INT, @D)
        FROM dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
        WHERE S.ID = CONVERT(INT, @A) AND ISNULL(S.ESTADO,'ACTIVO') = 'ACTIVO';
        IF @@ROWCOUNT = 0 BEGIN SET @ERROR = 'Uno de los servicios no existe o esta inactivo.'; RETURN; END;
    END;

    IF NOT EXISTS (SELECT 1 FROM @SRV) BEGIN SET @ERROR = 'Seleccione al menos un servicio.'; RETURN; END;
    IF EXISTS (SELECT ID_SERVICIO FROM @SRV GROUP BY ID_SERVICIO HAVING COUNT(*) > 1) BEGIN SET @ERROR = 'Hay servicios repetidos.'; RETURN; END;
    IF EXISTS (SELECT 1 FROM @SRV WHERE F_INI IS NULL OR F_FIN IS NULL) BEGIN SET @ERROR = 'Cada servicio debe tener fecha de inicio y fin.'; RETURN; END;
    IF EXISTS (SELECT 1 FROM @SRV WHERE F_FIN < F_INI) BEGIN SET @ERROR = 'En un servicio la fecha de fin es anterior al inicio.'; RETURN; END;
    IF EXISTS (SELECT 1 FROM @SRV WHERE F_INI < @F_INI OR F_FIN > @F_FIN)
    BEGIN SET @ERROR = 'Las fechas de cada servicio deben estar dentro del plazo del proyecto.'; RETURN; END;

    DECLARE @SUMA INT = (SELECT SUM(HORAS) FROM @SRV);
    IF @SUMA <> @HORAS
    BEGIN
        SET @ERROR = 'La suma de horas de los servicios (' + CONVERT(VARCHAR(10), @SUMA) + ' h) debe ser igual al total del proyecto ('
                   + CONVERT(VARCHAR(10), @HORAS) + ' h): ' + CASE WHEN @SUMA < @HORAS THEN 'faltan ' + CONVERT(VARCHAR(10), @HORAS - @SUMA)
                                                                  ELSE 'sobran ' + CONVERT(VARCHAR(10), @SUMA - @HORAS) END + ' h.';
        RETURN;
    END;

    /* ---------- normas: id,id,... ---------- */
    DECLARE @NOR TABLE (ORDEN INT IDENTITY(1,1), ID_NORMA INT);
    SET @LISTA = @T24 + ',';
    WHILE CHARINDEX(',', @LISTA) > 0
    BEGIN
        SET @POS = CHARINDEX(',', @LISTA);
        SET @A = LEFT(@LISTA, @POS - 1);
        SET @LISTA = SUBSTRING(@LISTA, @POS + 1, 4000);
        IF @A = '' CONTINUE;
        IF @A LIKE '%[^0-9]%' OR LEN(@A) > 9 BEGIN SET @ERROR = 'Norma invalida.'; RETURN; END;
        IF NOT EXISTS (SELECT 1 FROM @NOR WHERE ID_NORMA = CONVERT(INT, @A))
            INSERT INTO @NOR (ID_NORMA) SELECT N.ID FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK) WHERE N.ID = CONVERT(INT, @A);
    END;
    IF EXISTS (SELECT 1 FROM @SRV WHERE CODIGO = @SRV_EXIGE_NORMAS) AND NOT EXISTS (SELECT 1 FROM @NOR)
    BEGIN SET @ERROR = 'Con consultoria hay que seleccionar al menos una norma.'; RETURN; END;

    /* ---------- analista y proxima accion ---------- */
    DECLARE @ID_ANALISTA INT, @ID_ROL_EMP INT;
    IF @T20 <> '' AND @T20 NOT LIKE '%[^0-9]%' AND LEN(@T20) <= 9 SET @ID_ANALISTA = CONVERT(INT, @T20);
    IF @ID_ANALISTA IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID = @ID_ANALISTA)
    BEGIN SET @ERROR = 'Seleccione el analista.'; RETURN; END;
    IF @F_VEN IS NULL BEGIN SET @ERROR = 'Ingrese el vencimiento de la proxima accion.'; RETURN; END;
    IF @F_VEN < CONVERT(DATE, GETDATE()) BEGIN SET @ERROR = 'El vencimiento de la proxima accion no puede ser anterior a hoy.'; RETURN; END;
    IF @T23 <> '' AND @T23 NOT LIKE '%_@_%._%' BEGIN SET @ERROR = 'El mail a notificar no es valido.'; RETURN; END;

    /* rol del analista en el equipo: el rol de tipo EMPLEADO de VCT_PRM_PROYECTOS_ROLES */
    SELECT TOP 1 @ID_ROL_EMP = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK)
    WHERE TIPO_MIEMBRO = 'EMPLEADO' AND ACTIVO = 1 ORDER BY ORDEN, ID;
    IF @ID_ROL_EMP IS NULL BEGIN SET @ERROR = 'No hay un rol de tipo EMPLEADO en VCT_PRM_PROYECTOS_ROLES.'; RETURN; END;

    DECLARE @ID_EST INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE CODIGO = @EST_INICIAL);
    IF @ID_EST IS NULL BEGIN SET @ERROR = 'No existe el estado de proyecto ' + @EST_INICIAL + '.'; RETURN; END;

    /* ---------- grabacion ---------- */
    DECLARE @CODIGO VARCHAR(100), @NEXT INT;
    CREATE TABLE #EV_ACC (ID_ACCION INT, ID_REGLA INT);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC sp_getapplock @Resource = 'VCT_PROYECTO_CODIGO', @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        SELECT @NEXT = MAX(N) FROM (
            SELECT CASE WHEN CODIGO NOT LIKE '%[^0-9]%' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT, CODIGO) END AS N
            FROM dbo.VCT_PROYECTOS WITH(UPDLOCK, HOLDLOCK)) X;
        SET @CODIGO = CONVERT(VARCHAR(100), ISNULL(@NEXT, 0) + 1);

        INSERT INTO dbo.VCT_PROYECTOS
            (IDCLIENTE, CODIGO, NOMBRE, REFERENCIA, ID_ESTADO, FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE, MONEDA,
             MONTO_PRES, MONTO_PRES_VIAT, COSTO_MO, MONTO_TOTAL, COSTO_TOTAL,
             TOTAL_HORAS_PROYECTADAS, TOTAL_HORAS_EJECUTADAS, NIVEL_RIESGO, TIPO_PROYECTO, FECHA_ALTA, USUARIO_ALTA)
        VALUES
            (@ID_CLIENTE, @CODIGO, LEFT(@T11,300), NULLIF(LEFT(@T12,300),''), @ID_EST, @F_INI, @F_FIN, 0, @T28,
             @M_HON, @M_VIA, @M_CMO,
             CASE WHEN @M_HON IS NULL AND @M_VIA IS NULL THEN NULL ELSE ISNULL(@M_HON,0) + ISNULL(@M_VIA,0) END, @M_CMO,
             @HORAS, 0, @T18, @T16, GETDATE(), @IAGENTE);
        SET @ID_PROYECTO = SCOPE_IDENTITY();

        INSERT INTO dbo.VCT_PROYECTOS_SERVICIOS
            (ID_PROYECTO, ID_SERVICIO, ID_ESTADO, PRINCIPAL, ORDEN, SECUENCIA, FECHA_INICIO, FECHA_FIN,
             PORCENTAJE_AVANCE, TOTAL_HORAS_PROYECTADAS, TOTAL_HORAS_EJECUTADAS, FECHA_ALTA, USUARIO_ALTA)
        SELECT @ID_PROYECTO, S.ID_SERVICIO, @ID_EST, CASE WHEN S.ORDEN = 1 THEN 1 ELSE 0 END, S.ORDEN, S.ORDEN, S.F_INI, S.F_FIN,
               0, S.HORAS, 0, GETDATE(), @IAGENTE
        FROM @SRV S;

        INSERT INTO dbo.VCT_PROYECTOS_NORMAS
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, ID_NORMA, PRINCIPAL, OBLIGATORIA, ESTADO, FECHA_ALTA, USUARIO_ALTA)
        SELECT @ID_PROYECTO, NULL, N.ID_NORMA, CASE WHEN N.ORDEN = 1 THEN 1 ELSE 0 END, 1, 'ACTIVA', GETDATE(), @IAGENTE
        FROM @NOR N;

        INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL, FECHA_DESDE, ESTADO, FECHA_ALTA, USUARIO_ALTA)
        VALUES
            (@ID_PROYECTO, NULL, 'EMPLEADO', @ID_ANALISTA, NULL, @ID_ROL_EMP, 1, GETDATE(), 'ACTIVO', GETDATE(), @IAGENTE);

        /* workflow: acciones de las reglas de cada evento */
        EXEC dbo.VCT_ACCIONES_EVENTO @CODIGO_EVENTO = 'PROYECTO_ALTA', @FASE = 'ACCIONES',
             @ID_PROYECTO = @ID_PROYECTO, @ID_CLIENTE = @ID_CLIENTE, @IAGENTE = @IAGENTE;
        EXEC dbo.VCT_ACCIONES_EVENTO @CODIGO_EVENTO = 'ANALISTA_ASIGNADO', @FASE = 'ACCIONES',
             @ID_PROYECTO = @ID_PROYECTO, @ID_CLIENTE = @ID_CLIENTE, @IAGENTE = @IAGENTE, @FECHA_VENCE = @F_VEN;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ID_PROYECTO = NULL;
        SET @ERROR = LEFT('No se pudo crear el proyecto: ' + ERROR_MESSAGE(), 1000);
        RETURN;
    END CATCH;

    /* mails (fuera de la transaccion: si fallan, el alta queda grabada) */
    BEGIN TRY
        EXEC dbo.VCT_ACCIONES_EVENTO @CODIGO_EVENTO = NULL, @FASE = 'MAILS',
             @ID_PROYECTO = @ID_PROYECTO, @ID_CLIENTE = @ID_CLIENTE, @IAGENTE = @IAGENTE,
             @EMAIL_DESTINO = @T23;
    END TRY
    BEGIN CATCH
        SET @MENSAJE = ' Aviso: no se pudieron procesar los mails (' + LEFT(ERROR_MESSAGE(), 300) + ').';
    END CATCH;

    SET @MENSAJE = LEFT('Proyecto (' + @CODIGO + ') ' + @T11 + ' creado.' + ISNULL(@MENSAJE,''), 1000);
END
GO

/* ---------------- resultado ---------------- */
DECLARE @N VARCHAR(100);
DECLARE C CURSOR LOCAL FAST_FORWARD FOR
    SELECT V FROM (VALUES ('VCT_ACCIONES_EVENTO'),('VCT_PROYECTO_ALTA_RENDER'),('VCT_PROYECTO_ALTA_GUARDAR')) X(V);
OPEN C; FETCH NEXT FROM C INTO @N;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.procedures P CROSS JOIN #ALTA2_RUN R
               WHERE P.object_id = OBJECT_ID('dbo.' + @N) AND P.modify_date >= R.INICIO)
        PRINT 'OK   dbo.' + @N + ' creado/reemplazado.';
    ELSE
        PRINT 'FALLO dbo.' + @N + ' no se actualizo: revisar el error del bloque.';
    FETCH NEXT FROM C INTO @N;
END;
CLOSE C; DEALLOCATE C;

IF EXISTS (SELECT 1 FROM #ALTA2_RUN WHERE TRG_ON = 1)
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
