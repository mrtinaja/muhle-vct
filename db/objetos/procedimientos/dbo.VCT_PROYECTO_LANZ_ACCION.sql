 
/* ---------------- 4. acciones ---------------- */
CREATE   PROCEDURE dbo.VCT_PROYECTO_LANZ_ACCION
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
       Comandos (VCT_BUFFER.TEXTO30, con FLAG01 = 1):
         LANZ_EQUIPO_ADD  TEXTO11 consultor, TEXTO12 rol (CONSULTOR_LIDER / CONSULTOR)
         LANZ_EQUIPO_DEL  IDSELEC03 = VCT_PROYECTOS_EQUIPO.ID (baja logica)
         LANZ_DATOS       IDSELEC03 = ID_DOCUMENTO de la minuta;
                          TEXTO11..TEXTO29 = respuestas "[[idItem]]valor..." en tramos
         LANZ_CONS        TEXTO11 consideracion, TEXTO12 visibilidad
         LANZ_REUNION     TEXTO11 fecha (yyyy-mm-dd), TEXTO12 participantes, TEXTO13 notas
         LANZ_INICIAR     pasa el proyecto a EN CURSO
       No devuelve result sets.
       ============================================================ */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @MENSAJE = '';
    SET @ERROR = '';
 
    DECLARE @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100), @PAYLOAD VARCHAR(MAX),
            @T11 VARCHAR(4000), @T12 VARCHAR(4000), @T13 VARCHAR(4000);
 
    SELECT TOP 1
        @FLAG = ISNULL(FLAG01,''),
        @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @SEL3 = LTRIM(RTRIM(ISNULL(IDSELEC03,''))),
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))),
        @T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))),
        @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))),
        @PAYLOAD = ISNULL(TEXTO11,'') + ISNULL(TEXTO12,'') + ISNULL(TEXTO13,'') + ISNULL(TEXTO14,'') + ISNULL(TEXTO15,'')
                 + ISNULL(TEXTO16,'') + ISNULL(TEXTO17,'') + ISNULL(TEXTO18,'') + ISNULL(TEXTO19,'') + ISNULL(TEXTO20,'')
                 + ISNULL(TEXTO21,'') + ISNULL(TEXTO22,'') + ISNULL(TEXTO23,'') + ISNULL(TEXTO24,'') + ISNULL(TEXTO25,'')
                 + ISNULL(TEXTO26,'') + ISNULL(TEXTO27,'') + ISNULL(TEXTO28,'') + ISNULL(TEXTO29,'')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF CHARINDEX(',', @CMD) > 0 SET @CMD = LEFT(@CMD, CHARINDEX(',', @CMD) - 1);
    IF ISNULL(@FLAG,'') <> '1' OR @CMD NOT LIKE 'LANZ[_]%' RETURN;
 
    /* siempre se consume el comando, haya error o no */
    UPDATE dbo.VCT_BUFFER
       SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL,
           TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL, TEXTO15 = NULL,
           TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL,
           TEXTO21 = NULL, TEXTO22 = NULL, TEXTO23 = NULL, TEXTO24 = NULL, TEXTO25 = NULL,
           TEXTO26 = NULL, TEXTO27 = NULL, TEXTO28 = NULL, TEXTO29 = NULL
     WHERE PAR_KEY = @IPKEYJOB;
 
    IF dbo.VCT_PERFIL_PUEDE(@IUNIDAD, 'PROYECTOS.EDIT') = 0
    BEGIN
        SET @ERROR = 'No posee permisos para modificar el proyecto.';
        RETURN;
    END;
 
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS WHERE ID = @ID_PROYECTO)
    BEGIN
        SET @ERROR = 'No se encontro el proyecto.';
        RETURN;
    END;
 
    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT, @EST_COD VARCHAR(30);
    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE, @EST_COD = E.CODIGO
    FROM dbo.VCT_PROYECTOS P LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    WHERE P.ID = @ID_PROYECTO;
 
    BEGIN TRY
        /* ---------------- equipo: agregar consultor ---------------- */
        IF @CMD = 'LANZ_EQUIPO_ADD'
        BEGIN
            DECLARE @ID_CONS INT, @ID_ROL INT, @ROL_COD VARCHAR(50) = UPPER(@T12);
 
            IF @T11 = '' OR PATINDEX('%[^0-9]%', @T11) > 0 OR LEN(@T11) > 9
               OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES WHERE CONVERT(VARCHAR(20),ID) = @T11 AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO')
            BEGIN
                SET @ERROR = 'Seleccione un consultor activo.';
                RETURN;
            END;
            SET @ID_CONS = CONVERT(INT, @T11);
 
            SELECT TOP 1 @ID_ROL = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WHERE CODIGO = @ROL_COD AND @ROL_COD IN ('CONSULTOR_LIDER','CONSULTOR');
            IF @ID_ROL IS NULL
            BEGIN
                SET @ERROR = 'Seleccione el rol del consultor.';
                RETURN;
            END;
 
            IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR'
                       AND ID_CONSULTOR = @ID_CONS AND ESTADO = 'ACTIVO')
            BEGIN
                SET @ERROR = 'Ese consultor ya forma parte del equipo.';
                RETURN;
            END;
 
            BEGIN TRANSACTION;
                /* un solo lider: el anterior pasa a consultor */
                IF @ROL_COD = 'CONSULTOR_LIDER'
                    UPDATE EQ
                       SET ID_ROL = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WHERE CODIGO = 'CONSULTOR'),
                           PRINCIPAL = 0, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                      FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                      INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                     WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                       AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER';
 
                INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
                    (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL, FECHA_DESDE, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_PROYECTO, NULL, 'CONSULTOR', NULL, @ID_CONS, @ID_ROL,
                     CASE WHEN @ROL_COD = 'CONSULTOR_LIDER' THEN 1 ELSE 0 END, GETDATE(), 'ACTIVO', GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Consultor agregado al equipo.';
            RETURN;
        END;
 
        /* ---------------- equipo: quitar ---------------- */
        IF @CMD = 'LANZ_EQUIPO_DEL'
        BEGIN
            UPDATE dbo.VCT_PROYECTOS_EQUIPO
               SET ESTADO = 'INACTIVO', FECHA_HASTA = GETDATE(), PRINCIPAL = 0, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
             WHERE CONVERT(VARCHAR(20), ID) = @SEL3 AND ID_PROYECTO = @ID_PROYECTO
               AND TIPO_MIEMBRO = 'CONSULTOR' AND ESTADO = 'ACTIVO';
 
            IF @@ROWCOUNT = 0 SET @ERROR = 'El consultor ya no forma parte del equipo.';
            ELSE SET @MENSAJE = 'Consultor quitado del equipo.';
            RETURN;
        END;
 
        /* ---------------- datos de entrada (minuta) ---------------- */
        IF @CMD = 'LANZ_DATOS'
        BEGIN
            DECLARE @ID_DOC INT, @ID_PS INT, @ID_SERV INT, @ID_PD INT;
 
            SELECT TOP 1 @ID_DOC = M.ID_DOCUMENTO, @ID_PS = M.ID_PROYECTO_SERVICIO, @ID_SERV = M.ID_SERVICIO, @ID_PD = M.ID_PROYECTO_DOCUMENTO
            FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) M
            WHERE CONVERT(VARCHAR(20), M.ID_DOCUMENTO) = @SEL3;
 
            IF @ID_DOC IS NULL
            BEGIN
                SET @ERROR = 'La minuta indicada no corresponde a este proyecto.';
                RETURN;
            END;
 
            /* respuestas: [[idItem]]valor[[idItem]]valor... */
            DECLARE @R TABLE (ID_ITEM INT PRIMARY KEY, VALOR VARCHAR(MAX));
            DECLARE @P INT = CHARINDEX('[[', @PAYLOAD), @Q INT, @N INT, @IDTXT VARCHAR(20);
            WHILE @P > 0
            BEGIN
                SET @Q = CHARINDEX(']]', @PAYLOAD, @P + 2);
                IF @Q = 0 BREAK;
                SET @IDTXT = SUBSTRING(@PAYLOAD, @P + 2, @Q - @P - 2);
                SET @N = CHARINDEX('[[', @PAYLOAD, @Q + 2);
                IF @IDTXT <> '' AND PATINDEX('%[^0-9]%', @IDTXT) = 0 AND LEN(@IDTXT) <= 9
                   AND NOT EXISTS (SELECT 1 FROM @R WHERE ID_ITEM = CONVERT(INT, @IDTXT))
                    INSERT INTO @R VALUES (CONVERT(INT, @IDTXT),
                        LTRIM(RTRIM(SUBSTRING(@PAYLOAD, @Q + 2, CASE WHEN @N = 0 THEN LEN(@PAYLOAD) + 1 ELSE @N END - @Q - 2))));
                SET @P = @N;
            END;
 
            BEGIN TRANSACTION;
                IF @ID_PD IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS
                        (ID_PROYECTO, ID_SERVICIO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                    SELECT @ID_PROYECTO, @ID_SERV, @ID_PS, @ID_DOC, GETDATE(), LEFT(D.DESCRIPCION, 300), 'MG', 'REGISTRADO', GETDATE(), @IAGENTE
                    FROM dbo.VCT_PRM_DOCUMENTOS D WHERE D.ID = @ID_DOC;
                    SET @ID_PD = SCOPE_IDENTITY();
                END
                ELSE
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS SET FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @ID_PD;
 
                UPDATE PI
                   SET VALOR = NULLIF(R.VALOR,''), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                  FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                  INNER JOIN @R R ON R.ID_ITEM = PI.ID_DOCUMENTO_ITEM
                 WHERE PI.ID_PROYECTO_DOCUMENTO = @ID_PD
                   AND ISNULL(PI.VALOR,'') <> ISNULL(NULLIF(R.VALOR,''),'');
 
                INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS
                    (ID_PROYECTO_DOCUMENTO, ID_DOCUMENTO_ITEM, DESCRIPCION, VALOR, GRUPO, ORDEN, OBLIGATORIO, DATO, CAMPO, EXPORTA, FECHA_ALTA, USUARIO_ALTA)
                SELECT @ID_PD, I.ID, I.DESCRIPCION, R.VALOR, I.GRUPO, I.ORDEN, ISNULL(I.OBLIGATORIO,0), I.DATO, I.CAMPO, ISNULL(I.EXPORTA,0), GETDATE(), @IAGENTE
                FROM @R R
                INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I ON I.ID = R.ID_ITEM AND I.ID_DOCUMENTO = @ID_DOC
                WHERE R.VALOR <> ''
                  AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                                  WHERE PI.ID_PROYECTO_DOCUMENTO = @ID_PD AND PI.ID_DOCUMENTO_ITEM = I.ID);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Datos de entrada guardados.';
            RETURN;
        END;
 
        /* ---------------- consideraciones ---------------- */
        IF @CMD = 'LANZ_CONS'
        BEGIN
            DECLARE @VIS VARCHAR(20) = UPPER(@T12);
            IF @T11 = ''
            BEGIN
                SET @ERROR = 'Escriba la consideracion.';
                RETURN;
            END;
            IF @VIS NOT IN ('INTERNA','CONSULTOR','CLIENTE') SET @VIS = 'INTERNA';
 
            DECLARE @ID_CONS_DOC INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'CONS' ORDER BY ID);
 
            BEGIN TRANSACTION;
                IF @ID_CONS_DOC IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, GETDATE(), 'Consideraciones', 'CONS', 'REGISTRADO', GETDATE(), @IAGENTE);
                    SET @ID_CONS_DOC = SCOPE_IDENTITY();
                END;
 
                INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS
                    (ID_PROYECTO_DOCUMENTO, DESCRIPCION, VALOR, GRUPO, ORDEN, OBLIGATORIO, CAMPO, EXPORTA, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_CONS_DOC, 'Consideracion', LEFT(@T11, 4000), @VIS,
                     (SELECT ISNULL(MAX(ORDEN),0) + 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS WHERE ID_PROYECTO_DOCUMENTO = @ID_CONS_DOC),
                     0, 'CONSIDERACION', CASE WHEN @VIS = 'CLIENTE' THEN 1 ELSE 0 END, GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Consideracion agregada.';
            RETURN;
        END;
 
        /* ---------------- reunion de lanzamiento ---------------- */
        IF @CMD = 'LANZ_REUNION'
        BEGIN
            DECLARE @F_REU DATETIME;
            IF @T11 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T11,'-','')) = 0
            BEGIN
                SET @ERROR = 'Indique la fecha de la reunion de lanzamiento.';
                RETURN;
            END;
            SET @F_REU = CONVERT(DATETIME, REPLACE(@T11,'-',''), 112);
 
            DECLARE @ID_G INT, @EST_ANT INT,
                    @G_CUMP INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'CUMPLIDA'),
                    @G_RES  INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE CODIGO = 'COMPLETADA');
 
            SELECT TOP 1 @ID_G = G.ID, @EST_ANT = G.ID_ESTADO
            FROM dbo.VCT_GESTIONES G
            INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
            WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'ASIGNACION_ANALISTA'
            ORDER BY G.ID DESC;
 
            BEGIN TRANSACTION;
                IF @ID_G IS NULL
                BEGIN
                    /* proyectos sin gestion de lanzamiento (dados de alta antes): se crea */
                    INSERT INTO dbo.VCT_GESTIONES
                        (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                         REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                    SELECT 'SISTEMA',
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'ASIGNACION'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'ASIGNACION_ANALISTA'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
                           LEFT('Organizar lanzamiento - (' + ISNULL(@CODIGO,'') + ') ' + ISNULL(@NOMBRE,''), 300),
                           'Reunion de lanzamiento del proyecto.', @ID_CLIENTE, @ID_PROYECTO, 0, 0, GETDATE(), GETDATE(), GETDATE(), @IAGENTE;
                    SET @ID_G = SCOPE_IDENTITY();
                    UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_G), 9) WHERE ID = @ID_G;
                    SELECT @EST_ANT = ID_ESTADO FROM dbo.VCT_GESTIONES WHERE ID = @ID_G;
                END;
 
                UPDATE dbo.VCT_GESTIONES
                   SET ID_ESTADO = @G_CUMP, ID_RESULTADO = @G_RES, FECHA_CIERRE = @F_REU,
                       OBSERVACIONES = LEFT('Reunion de lanzamiento ' + CONVERT(VARCHAR(10), @F_REU, 103)
                                     + CASE WHEN @T12 <> '' THEN '. Participantes: ' + @T12 ELSE '' END
                                     + '. Notas: ' + @T13, 2000),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_G;
 
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
                VALUES
                    (@ID_G, @EST_ANT, @G_CUMP, @G_RES, 'REUNION_LANZAMIENTO',
                     LEFT('Reunion ' + CONVERT(VARCHAR(10), @F_REU, 103)
                          + CASE WHEN @T12 <> '' THEN ' | Participantes: ' + @T12 ELSE '' END
                          + ' | Notas: ' + @T13, 2000),
                     'EMPLEADO', NULL, GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Reunion de lanzamiento registrada.';
            RETURN;
        END;
 
        /* ---------------- iniciar proyecto ---------------- */
        IF @CMD = 'LANZ_INICIAR'
        BEGIN
            IF ISNULL(@EST_COD,'') NOT IN ('BORRADOR','CONFIRMADO')
            BEGIN
                SET @ERROR = 'El proyecto ya fue iniciado o no esta en estado Confirmado.';
                RETURN;
            END;
 
            DECLARE @ID_ENC INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WHERE CODIGO = 'ENCURSO'),
                    @ID_LIDER INT, @ID_REGLA INT, @DIAS INT, @TIT VARCHAR(300), @DET VARCHAR(MAX), @ID_GP INT, @F_PLAN DATETIME;
 
            SELECT TOP 1 @ID_LIDER = EQ.ID_CONSULTOR
            FROM dbo.VCT_PROYECTOS_EQUIPO EQ INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
            WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER'
            ORDER BY EQ.ID DESC;
 
            SELECT TOP 1 @ID_REGLA = ID, @DIAS = DIAS_VENCIMIENTO, @TIT = TITULO_PLANTILLA, @DET = DETALLE_PLANTILLA
            FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE CODIGO = 'PROY_CONSULTORES_CARGAR_PLAN';
 
            SET @F_PLAN = DATEADD(DAY, ISNULL(@DIAS, 3), CONVERT(DATE, GETDATE()));
            SET @TIT = REPLACE(REPLACE(ISNULL(@TIT, 'Iniciar Plan Estrategico - {{CODIGO_PROYECTO}}'), '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,'')), '{{PROYECTO}}', ISNULL(@NOMBRE,''));
            SET @DET = REPLACE(REPLACE(ISNULL(@DET, 'Iniciar o completar el Plan Estrategico del proyecto.'), '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,'')), '{{PROYECTO}}', ISNULL(@NOMBRE,''));
 
            BEGIN TRANSACTION;
                UPDATE dbo.VCT_PROYECTOS
                   SET ID_ESTADO = @ID_ENC, FECHA_INICIO_REAL = ISNULL(FECHA_INICIO_REAL, CONVERT(DATE, GETDATE())),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_PROYECTO;
 
                UPDATE PS
                   SET ID_ESTADO = @ID_ENC, FECHA_INICIO_REAL = ISNULL(PS.FECHA_INICIO_REAL, CONVERT(DATE, GETDATE())),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                  FROM dbo.VCT_PROYECTOS_SERVICIOS PS
                  INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = PS.ID_ESTADO
                 WHERE PS.ID_PROYECTO = @ID_PROYECTO AND E.CODIGO IN ('BORRADOR','CONFIRMADO');
 
                IF @ID_LIDER IS NOT NULL
                BEGIN
                INSERT INTO dbo.VCT_GESTIONES
                    (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_REGLA_ORIGEN, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                     REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_ALTA, USUARIO_ALTA)
                SELECT 'AUTOMATICA',
                       ISNULL((SELECT TOP 1 ID_TIPO FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE ID = @ID_REGLA), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'TAREA')),
                       ISNULL((SELECT TOP 1 ID_SUBTIPO FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE ID = @ID_REGLA), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'CARGA_PLAN')),
                       (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
                       (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
                       @ID_REGLA, LEFT(@TIT, 300), @DET, @ID_CLIENTE, @ID_PROYECTO, 0, 0, GETDATE(), GETDATE(), @F_PLAN, GETDATE(), @IAGENTE;
                SET @ID_GP = SCOPE_IDENTITY();
                UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_GP), 9) WHERE ID = @ID_GP;
 
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                SELECT @ID_GP, NULL, ID_ESTADO, 'CREACION', 'Creacion de gestion (inicio de proyecto).', 'SISTEMA', GETDATE(), @IAGENTE
                FROM dbo.VCT_GESTIONES WHERE ID = @ID_GP;
 
                INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                    (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_GP, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE),
                    (@ID_GP, 'RESPONSABLE', 'CONSULTOR', @ID_LIDER, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                END;
            COMMIT TRANSACTION;
 
            IF @ID_LIDER IS NULL
            BEGIN
                SET @MENSAJE = 'Proyecto iniciado: quedo En curso. No hay consultor lider asignado, asi que no se creo la gestion del Plan Estrategico.';
                RETURN;
            END;
 
            SET @MENSAJE = 'Proyecto iniciado: quedo En curso y se creo la gestion del Plan Estrategico para el consultor lider.';
 
            /* mail al consultor lider (fuera de la transaccion) */
            BEGIN TRY
                DECLARE @M_ASUNTO VARCHAR(500), @M_BODY VARCHAR(MAX), @M_DEST VARCHAR(1000), @M_CC VARCHAR(1000);
                IF OBJECT_ID('tempdb..#MAIL') IS NOT NULL DROP TABLE #MAIL;
                CREATE TABLE #MAIL (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));
 
                IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_INICIO_CONSULTOR' AND ESTADO = 'ACTIVO')
                BEGIN
                    DECLARE @ID_ANA INT = (SELECT TOP 1 EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                                           INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                                           WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'ANALISTA'
                                           ORDER BY EQ.PRINCIPAL DESC, EQ.ID);
 
                    INSERT INTO #MAIL
                    EXEC dbo.VCT_MAIN_SEND_EMAIL
                         @CODIGO = 'PROYECTO_INICIO_CONSULTOR',
                         @ID_CONSULTOR = @ID_LIDER,
                         @ID_PROYECTO = @ID_PROYECTO,
                         @ID_ANALISTA = @ID_ANA,
                         @ID_CLIENTE = @ID_CLIENTE;
 
                    SELECT TOP 1 @M_ASUNTO = ASUNTO, @M_BODY = HTML_CONTENIDO, @M_DEST = DESTINATARIO, @M_CC = NULLIF(LTRIM(RTRIM(CC)),'') FROM #MAIL;
 
                    DECLARE @L_NORM VARCHAR(2000) = '', @L_EQ VARCHAR(2000) = '';
                    SELECT @L_NORM = @L_NORM + CASE WHEN @L_NORM = '' THEN '' ELSE ', ' END + N.DESCRIPCION
                    FROM (SELECT DISTINCT PN.ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS PN WHERE PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA') X
                    INNER JOIN dbo.VCT_PRM_NORMAS N ON N.ID = X.ID_NORMA;
                    SELECT @L_EQ = @L_EQ + CASE WHEN @L_EQ = '' THEN '' ELSE ', ' END
                                 + LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ' ' + ISNULL(C.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')'
                    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                    INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
                    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
                    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
 
                    SET @M_ASUNTO = REPLACE(@M_ASUNTO, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{NORMAS}}', dbo.VCT_HTML_ESC(@L_NORM));
                    SET @M_BODY = REPLACE(@M_BODY, '{{EQUIPO}}', dbo.VCT_HTML_ESC(@L_EQ));
                    SET @M_BODY = REPLACE(@M_BODY, '{{FECHA_PLAN}}', CONVERT(VARCHAR(10), @F_PLAN, 103));
 
                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL AND @M_CC IS NOT NULL
                    BEGIN
                        SET @M_DEST = @M_CC;
                        SET @M_CC = NULL;
                    END;
 
                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL
                        SET @MENSAJE = LEFT(@MENSAJE + ' No se envio el mail: el consultor lider no tiene email cargado.', 1000);
                    ELSE
                    BEGIN
                        EXEC msdb.dbo.sp_send_dbmail
                             @profile_name = 'VocaturoProfile', @recipients = @M_DEST, @copy_recipients = @M_CC,
                             @subject = @M_ASUNTO, @body = @M_BODY, @body_format = 'HTML';
                        SET @MENSAJE = LEFT(@MENSAJE + ' Mail enviado a ' + @M_DEST + '.', 1000);
                    END;
                END;
            END TRY
            BEGIN CATCH
                SET @MENSAJE = LEFT(@MENSAJE + ' El mail fallo: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
            RETURN;
        END;
 
        SET @ERROR = 'Comando no reconocido.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ERROR = LEFT('No se pudo grabar: ' + ERROR_MESSAGE(), 1000);
    END CATCH;
END
