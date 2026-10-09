 
/* ---------------- 4. acciones ---------------- */
CREATE   PROCEDURE dbo.VCT_PROYECTO_PLAN_ACCION
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
         PLAN_GENERAR        TEXTO11 = BASE (copia RE-PP-007) / BLANCO
         PLAN_ITEM_GUARDAR   IDSELEC03 = item ('' = nuevo); TEXTO11 codigo,
                             TEXTO12 item, TEXTO13 descripcion, TEXTO14
                             responsables, TEXTO15 inicio, TEXTO16 fin,
                             TEXTO17 fin real, TEXTO18 observaciones, TEXTO19 N
         PLAN_ITEM_DEL       IDSELEC03 = item (solo sin gestiones)
         PLAN_GESTION_ADD    IDSELEC03 = item; TEXTO11 gestion, TEXTO12 vence,
                             TEXTO13 responsable (C:id consultor / E:id empleado),
                             TEXTO14 detalle
         PLAN_GESTION_ESTADO IDSELEC03 = gestion; TEXTO11 CUMPLIDA / PENDIENTE / CANCELADA
       Fechas yyyy-mm-dd. No devuelve result sets.
       ============================================================ */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @MENSAJE = '';
    SET @ERROR = '';
 
    DECLARE @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100),
            @T11 VARCHAR(4000), @T12 VARCHAR(4000), @T13 VARCHAR(4000), @T14 VARCHAR(4000), @T15 VARCHAR(4000),
            @T16 VARCHAR(4000), @T17 VARCHAR(4000), @T18 VARCHAR(4000), @T19 VARCHAR(4000);
 
    SELECT TOP 1
        @FLAG = ISNULL(FLAG01,''),
        @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @SEL3 = LTRIM(RTRIM(ISNULL(IDSELEC03,''))),
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))),
        @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))), @T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))),
        @T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))),
        @T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))), @T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))),
        @T19 = LTRIM(RTRIM(ISNULL(TEXTO19,'')))
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF CHARINDEX(',', @CMD) > 0 SET @CMD = LEFT(@CMD, CHARINDEX(',', @CMD) - 1);
    IF CHARINDEX(',', @SEL3) > 0 SET @SEL3 = LEFT(@SEL3, CHARINDEX(',', @SEL3) - 1);
    IF ISNULL(@FLAG,'') <> '1' OR @CMD NOT LIKE 'PLAN[_]%' RETURN;
 
    /* siempre se consume el comando, haya error o no */
    UPDATE dbo.VCT_BUFFER
       SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL,
           TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL, TEXTO15 = NULL,
           TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL
     WHERE PAR_KEY = @IPKEYJOB;
 
    IF dbo.VCT_PERFIL_PUEDE(@IUNIDAD, 'PLAN.EDIT') = 0
    BEGIN
        SET @ERROR = 'No posee permisos para modificar el plan del proyecto.';
        RETURN;
    END;
 
    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT, @EST_COD VARCHAR(30), @F_INI_REAL DATETIME;
    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE, @EST_COD = E.CODIGO, @F_INI_REAL = P.FECHA_INICIO_REAL
    FROM dbo.VCT_PROYECTOS P LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    WHERE P.ID = @ID_PROYECTO;
 
    IF @CODIGO IS NULL AND @NOMBRE IS NULL
    BEGIN
        SET @ERROR = 'No se encontro el proyecto.';
        RETURN;
    END;
 
    DECLARE @ID_PLAN INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_PLANES WHERE ID_PROYECTO = @ID_PROYECTO ORDER BY ID DESC);
 
    DECLARE @ID_LIDER INT = (SELECT TOP 1 EQ.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                             INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                             WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                               AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER'
                             ORDER BY EQ.ID DESC);
 
    DECLARE @G_PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
            @G_PROC INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'EN_PROCESO'),
            @G_CUMP INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'CUMPLIDA'),
            @G_CANC INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'CANCELADA'),
            @G_NORM INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
            @G_RES  INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE CODIGO = 'COMPLETADA');
    IF @G_NORM IS NULL SET @G_NORM = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES ORDER BY ID);
    DECLARE @ST_PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'PENDIENTE_CLIENTE');
    DECLARE @AV_MAIL BIT = 0, @AV_ITEM VARCHAR(400) = '', @AV_CAMBIOS VARCHAR(1000) = '', @AV_ANA INT = NULL;
 
    BEGIN TRY
        /* ---------------- generar el plan ---------------- */
        IF @CMD = 'PLAN_GENERAR'
        BEGIN
            IF @ID_PLAN IS NOT NULL
            BEGIN
                SET @ERROR = 'El proyecto ya tiene un Plan Estrategico.';
                RETURN;
            END;
 
            DECLARE @ID_DOC INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_DOCUMENTOS WHERE CODIGO = 'RE-PP-007' AND ACTIVO = 1 ORDER BY ID DESC);
            IF @ID_DOC IS NULL
            BEGIN
                SET @ERROR = 'No existe el documento RE-PP-007 (Plan Estrategico) activo en parametria.';
                RETURN;
            END;
 
            DECLARE @ID_PS INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_SERVICIOS WHERE ID_PROYECTO = @ID_PROYECTO ORDER BY PRINCIPAL DESC, ID);
            DECLARE @BASE BIT = CASE WHEN UPPER(@T11) = 'BLANCO' THEN 0 ELSE 1 END;
            DECLARE @MAP TABLE (ID_PRM INT PRIMARY KEY, ID_NEW INT);
 
            BEGIN TRANSACTION;
                INSERT INTO dbo.VCT_PROYECTOS_PLANES
                    (ID_PROYECTO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, VERSION, ESTADO, ID_CONSULTOR_RESPONSABLE, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_PROYECTO, @ID_PS, @ID_DOC, 1,
                     dbo.VCT_CK_VALOR('dbo.VCT_PROYECTOS_PLANES', 'ESTADO', 'VIGENTE,ACTIVO,EN_CURSO,ENCURSO,BORRADOR'),
                     @ID_LIDER, ISNULL(@F_INI_REAL, CONVERT(DATE, GETDATE())), GETDATE(), @IAGENTE);
                SET @ID_PLAN = SCOPE_IDENTITY();
 
                IF @BASE = 1
                BEGIN
                    MERGE dbo.VCT_PROYECTOS_PLAN_ITEMS AS T
                    USING
                    (
                        SELECT I.ID, I.CODIGO_ITEM, I.DESCRIPCION, I.COMENTARIO, I.GRUPO, ISNULL(I.OBLIGATORIO,0) AS OBLIGATORIO,
                               ROW_NUMBER() OVER (ORDER BY ISNULL(I.ORDEN, 9999), I.ID) AS N
                        FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
                        WHERE I.ID_DOCUMENTO = @ID_DOC AND I.ACTIVO = 1
                    ) AS S
                    ON 1 = 0
                    WHEN NOT MATCHED THEN
                        INSERT (ID_PLAN, ID_DOCUMENTO_ITEM, CODIGO_ITEM, TITULO, DESCRIPCION, GRUPO, ORDEN, OBLIGATORIO, ESTADO, PORCENTAJE_AVANCE, FECHA_ALTA, USUARIO_ALTA)
                        VALUES (@ID_PLAN, S.ID, CASE WHEN PATINDEX('%[^0-9]%', ISNULL(S.CODIGO_ITEM,'')) = 0 THEN NULL ELSE S.CODIGO_ITEM END, LEFT(ISNULL(NULLIF(LTRIM(RTRIM(S.DESCRIPCION)),''), 'Item ' + CONVERT(VARCHAR(10), S.N)), 400),
                                LEFT(NULLIF(LTRIM(RTRIM(S.COMENTARIO)),''), 2000), S.GRUPO, S.N, S.OBLIGATORIO,
                                dbo.VCT_CK_VALOR('dbo.VCT_PROYECTOS_PLAN_ITEMS', 'ESTADO', 'PENDIENTE'), 0, GETDATE(), @IAGENTE)
                    OUTPUT S.ID, INSERTED.ID INTO @MAP (ID_PRM, ID_NEW);
 
                    /* jerarquia (sub-items) */
                    UPDATE T
                       SET ID_PADRE = MP.ID_NEW
                      FROM dbo.VCT_PROYECTOS_PLAN_ITEMS T
                      INNER JOIN @MAP M ON M.ID_NEW = T.ID
                      INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I ON I.ID = M.ID_PRM
                      INNER JOIN @MAP MP ON MP.ID_PRM = I.ID_PADRE;
                END;
 
                /* la gestion "Iniciar Plan Estrategico" pasa a En proceso */
                DECLARE @ID_GCP INT, @EST_GCP INT;
                SELECT TOP 1 @ID_GCP = G.ID, @EST_GCP = G.ID_ESTADO
                FROM dbo.VCT_GESTIONES G
                INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
                WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'CARGA_PLAN' AND G.ID_ESTADO = @G_PEND
                ORDER BY G.ID DESC;
 
                IF @ID_GCP IS NOT NULL AND @G_PROC IS NOT NULL
                BEGIN
                    UPDATE dbo.VCT_GESTIONES SET ID_ESTADO = @G_PROC, ID_PLAN = @ID_PLAN, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @ID_GCP;
                    INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                        (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@ID_GCP, @EST_GCP, @G_PROC, 'PLAN_GENERADO', 'Se genero el Plan Estrategico del proyecto.', 'SISTEMA', GETDATE(), @IAGENTE);
                END;
            COMMIT TRANSACTION;
 
            SET @MENSAJE = CASE WHEN @BASE = 1
                                THEN 'Plan Estrategico generado con ' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM @MAP)) + ' items de RE-PP-007. Ahora defina fechas, responsables y gestiones de cada item.'
                                ELSE 'Plan Estrategico creado en blanco. Agregue los items del plan.' END;
            RETURN;
        END;
 
        IF @ID_PLAN IS NULL
        BEGIN
            SET @ERROR = 'El proyecto todavia no tiene Plan Estrategico.';
            RETURN;
        END;
 
        DECLARE @ID_ITEM INT = NULL;
        IF @SEL3 <> '' AND PATINDEX('%[^0-9]%', @SEL3) = 0 AND LEN(@SEL3) <= 9
            SET @ID_ITEM = CONVERT(INT, @SEL3);
 
        /* ---------------- alta / edicion de item ---------------- */
        IF @CMD = 'PLAN_ITEM_GUARDAR'
        BEGIN
            DECLARE @FI DATETIME = NULL, @FF DATETIME = NULL, @FR DATETIME = NULL, @ORD INT = NULL;
 
            IF @T12 = ''
            BEGIN
                SET @ERROR = 'Escriba el item del plan.';
                RETURN;
            END;
            IF (@T15 <> '' AND (@T15 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T15,'-','')) = 0))
            OR (@T16 <> '' AND (@T16 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T16,'-','')) = 0))
            OR (@T17 <> '' AND (@T17 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T17,'-','')) = 0))
            BEGIN
                SET @ERROR = 'Alguna de las fechas no es valida.';
                RETURN;
            END;
            IF @T15 <> '' SET @FI = CONVERT(DATETIME, REPLACE(@T15,'-',''), 112);
            IF @T16 <> '' SET @FF = CONVERT(DATETIME, REPLACE(@T16,'-',''), 112);
            IF @T17 <> '' SET @FR = CONVERT(DATETIME, REPLACE(@T17,'-',''), 112);
            IF @T19 <> '' AND PATINDEX('%[^0-9]%', @T19) = 0 AND LEN(@T19) <= 5 SET @ORD = CONVERT(INT, @T19);
            IF @FI IS NOT NULL AND @FF IS NOT NULL AND @FF < @FI
            BEGIN
                SET @ERROR = 'La fecha de fin no puede ser anterior a la de inicio.';
                RETURN;
            END;
 
            DECLARE @OLD_FI DATETIME, @OLD_FF DATETIME, @OLD_TIT VARCHAR(400), @OLD_ORD INT;
 
            IF @ID_ITEM IS NOT NULL
            BEGIN
                SELECT @OLD_FI = FECHA_INICIO, @OLD_FF = FECHA_VENCIMIENTO, @OLD_TIT = TITULO, @OLD_ORD = ORDEN
                FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID = @ID_ITEM AND ID_PLAN = @ID_PLAN;
                IF @OLD_TIT IS NULL
                BEGIN
                    SET @ERROR = 'El item no pertenece al plan de este proyecto.';
                    RETURN;
                END;
            END;
 
            BEGIN TRANSACTION;
                IF @ID_ITEM IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_PLAN_ITEMS
                        (ID_PLAN, CODIGO_ITEM, TITULO, DESCRIPCION, VALOR, ORDEN, OBLIGATORIO, ESTADO, FECHA_INICIO, FECHA_VENCIMIENTO,
                         FECHA_CIERRE, PORCENTAJE_AVANCE, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES
                        (@ID_PLAN, NULLIF(LEFT(@T11,50),''), LEFT(@T12,400), NULLIF(LEFT(@T13,2000),''), NULLIF(@T14,''),
                         ISNULL(@ORD, (SELECT ISNULL(MAX(ORDEN),0) + 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN = @ID_PLAN)) - 0,
                         0, dbo.VCT_CK_VALOR('dbo.VCT_PROYECTOS_PLAN_ITEMS', 'ESTADO', 'PENDIENTE'),
                         @FI, @FF, @FR, 0, NULLIF(LEFT(@T18,2000),''), GETDATE(), @IAGENTE);
                    SET @ID_ITEM = SCOPE_IDENTITY();
                END
                ELSE
                    UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS
                       SET CODIGO_ITEM = NULLIF(LEFT(@T11,50),''), TITULO = LEFT(@T12,400), DESCRIPCION = NULLIF(LEFT(@T13,2000),''),
                           VALOR = NULLIF(@T14,''), FECHA_INICIO = @FI, FECHA_VENCIMIENTO = @FF, FECHA_CIERRE = @FR,
                           OBSERVACIONES = NULLIF(LEFT(@T18,2000),''), ORDEN = ISNULL(@ORD, ORDEN),
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @ID_ITEM;
 
                /* numeracion 1..n: el item queda en la posicion pedida */
                IF @ORD IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS SET ORDEN = ORDEN + 1
                     WHERE ID_PLAN = @ID_PLAN AND ID <> @ID_ITEM AND ORDEN >= @ORD
                       AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS X WHERE X.ID_PLAN = @ID_PLAN AND X.ID <> @ID_ITEM AND X.ORDEN = @ORD);
 
                ;WITH N AS (SELECT ID, ORDEN, ROW_NUMBER() OVER (ORDER BY ISNULL(ORDEN, 99999), CASE WHEN ID = @ID_ITEM THEN 0 ELSE 1 END, ID) AS RN
                            FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN = @ID_PLAN)
                UPDATE N SET ORDEN = RN WHERE ISNULL(ORDEN, -1) <> RN;
 
                /* alerta al analista: cambio de fechas de un item ya fechado */
                IF @OLD_TIT IS NOT NULL
                   AND ((@OLD_FI IS NOT NULL AND ISNULL(CONVERT(DATE,@OLD_FI),'19000101') <> ISNULL(CONVERT(DATE,@FI),'19000101'))
                     OR (@OLD_FF IS NOT NULL AND ISNULL(CONVERT(DATE,@OLD_FF),'19000101') <> ISNULL(CONVERT(DATE,@FF),'19000101')))
                BEGIN
                    DECLARE @ID_ANA INT = (SELECT TOP 1 EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                                           INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                                           WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'ANALISTA'
                                           ORDER BY EQ.PRINCIPAL DESC, EQ.ID),
                            @ID_AV INT,
                            @AV_TXT VARCHAR(2000) =
                                'Item: ' + LEFT(@T12, 300)
                              + CASE WHEN ISNULL(CONVERT(DATE,@OLD_FI),'19000101') <> ISNULL(CONVERT(DATE,@FI),'19000101')
                                     THEN ' | Inicio: ' + ISNULL(CONVERT(VARCHAR(10),@OLD_FI,103),'-') + ' -> ' + ISNULL(CONVERT(VARCHAR(10),@FI,103),'-') ELSE '' END
                              + CASE WHEN ISNULL(CONVERT(DATE,@OLD_FF),'19000101') <> ISNULL(CONVERT(DATE,@FF),'19000101')
                                     THEN ' | Fin: ' + ISNULL(CONVERT(VARCHAR(10),@OLD_FF,103),'-') + ' -> ' + ISNULL(CONVERT(VARCHAR(10),@FF,103),'-') ELSE '' END
                              + ' | Cambio realizado por ' + ISNULL(@IAGENTE,'') + '.';
 
                    INSERT INTO dbo.VCT_GESTIONES
                        (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN,
                         REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                    VALUES
                        ('AUTOMATICA', (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'AVISO'), NULL, @G_PEND, @G_NORM,
                         LEFT('Cambio de fecha en el plan - (' + ISNULL(@CODIGO,'') + ') ' + @T12, 300), @AV_TXT,
                         @ID_CLIENTE, @ID_PROYECTO, @ID_PLAN, 0, 0, GETDATE(), GETDATE(), GETDATE(), @IAGENTE);
                    SET @ID_AV = SCOPE_IDENTITY();
                    UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_AV), 9) WHERE ID = @ID_AV;
 
                    INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                        (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@ID_AV, NULL, @G_PEND, 'CREACION', LEFT(@AV_TXT, 2000), 'SISTEMA', GETDATE(), @IAGENTE);
 
                    INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                        (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_AV, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                    IF @ID_ANA IS NOT NULL
                        INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                            (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                        VALUES (@ID_AV, 'RESPONSABLE', 'EMPLEADO', @ID_ANA, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
 
                    SET @MENSAJE = 'Item guardado. Se aviso al analista del cambio de fechas.';
                    SELECT @AV_MAIL = 1, @AV_ITEM = LEFT(@T12, 400), @AV_ANA = @ID_ANA,
                           @AV_CAMBIOS = STUFF(
                               CASE WHEN ISNULL(CONVERT(DATE,@OLD_FI),'19000101') <> ISNULL(CONVERT(DATE,@FI),'19000101')
                                    THEN '; inicio ' + ISNULL(CONVERT(VARCHAR(10),@OLD_FI,103),'-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10),@FI,103),'-') ELSE '' END
                             + CASE WHEN ISNULL(CONVERT(DATE,@OLD_FF),'19000101') <> ISNULL(CONVERT(DATE,@FF),'19000101')
                                    THEN '; fin ' + ISNULL(CONVERT(VARCHAR(10),@OLD_FF,103),'-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10),@FF,103),'-') ELSE '' END, 1, 2, '');
                END
                ELSE
                    SET @MENSAJE = CASE WHEN @OLD_TIT IS NULL THEN 'Item agregado al plan.' ELSE 'Item guardado.' END;
            COMMIT TRANSACTION;
 
            /* mail al analista (fuera de la transaccion; si falla, el item queda guardado) */
            IF @AV_MAIL = 1
            BEGIN TRY
                IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PLAN_CAMBIO_FECHA' AND ESTADO = 'ACTIVO')
                BEGIN
                    DECLARE @M_ASUNTO VARCHAR(500), @M_BODY VARCHAR(MAX), @M_DEST VARCHAR(1000), @M_CC VARCHAR(1000);
                    IF OBJECT_ID('tempdb..#MAIL') IS NOT NULL DROP TABLE #MAIL;
                    CREATE TABLE #MAIL (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));
 
                    INSERT INTO #MAIL
                    EXEC dbo.VCT_MAIN_SEND_EMAIL
                         @CODIGO = 'PLAN_CAMBIO_FECHA',
                         @ID_CONSULTOR = @ID_LIDER,
                         @ID_PROYECTO = @ID_PROYECTO,
                         @ID_ANALISTA = @AV_ANA,
                         @ID_CLIENTE = @ID_CLIENTE;
 
                    SELECT TOP 1 @M_ASUNTO = ASUNTO, @M_BODY = HTML_CONTENIDO, @M_DEST = DESTINATARIO, @M_CC = NULLIF(LTRIM(RTRIM(CC)),'') FROM #MAIL;
 
                    SET @M_ASUNTO = REPLACE(@M_ASUNTO, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{ITEM}}', dbo.VCT_HTML_ESC(@AV_ITEM));
                    SET @M_BODY = REPLACE(@M_BODY, '{{CAMBIOS}}', @AV_CAMBIOS);
                    SET @M_BODY = REPLACE(@M_BODY, '{{USUARIO}}', dbo.VCT_HTML_ESC(ISNULL(@IAGENTE,'')));
 
                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL AND @M_CC IS NOT NULL
                    BEGIN
                        SET @M_DEST = @M_CC;
                        SET @M_CC = NULL;
                    END;
 
                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NOT NULL
                    BEGIN
                        EXEC msdb.dbo.sp_send_dbmail
                             @profile_name = 'VocaturoProfile', @recipients = @M_DEST, @copy_recipients = @M_CC,
                             @subject = @M_ASUNTO, @body = @M_BODY, @body_format = 'HTML';
                        SET @MENSAJE = LEFT(@MENSAJE + ' Mail enviado a ' + @M_DEST + '.', 1000);
                    END
                    ELSE
                        SET @MENSAJE = LEFT(@MENSAJE + ' No se envio el mail: el analista no tiene email cargado.', 1000);
                END;
            END TRY
            BEGIN CATCH
                SET @MENSAJE = LEFT(@MENSAJE + ' El mail fallo: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
        END
 
        /* ---------------- baja de item ---------------- */
        ELSE IF @CMD = 'PLAN_ITEM_DEL'
        BEGIN
            IF @ID_ITEM IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID = @ID_ITEM AND ID_PLAN = @ID_PLAN)
            BEGIN
                SET @ERROR = 'El item no pertenece al plan de este proyecto.';
                RETURN;
            END;
            IF EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES WHERE ID_PLAN_ITEM = @ID_ITEM)
            BEGIN
                SET @ERROR = 'El item tiene gestiones: no se puede quitar. Cancele sus gestiones o cierre el item con fin real.';
                RETURN;
            END;
 
            BEGIN TRANSACTION;
                UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS SET ID_PADRE = NULL WHERE ID_PADRE = @ID_ITEM;
                DELETE FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID = @ID_ITEM;
 
                ;WITH N AS (SELECT ID, ORDEN, ROW_NUMBER() OVER (ORDER BY ISNULL(ORDEN, 99999), ID) AS RN
                            FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN = @ID_PLAN)
                UPDATE N SET ORDEN = RN WHERE ISNULL(ORDEN, -1) <> RN;
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Item quitado del plan.';
        END
 
        /* ---------------- alta de gestion en un item ---------------- */
        ELSE IF @CMD = 'PLAN_GESTION_ADD'
        BEGIN
            DECLARE @IT_TIT VARCHAR(400), @F_VEN DATETIME = NULL, @R_TIPO VARCHAR(20) = NULL, @R_ID INT = NULL, @ID_NG INT;
 
            SELECT @IT_TIT = TITULO FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID = @ID_ITEM AND ID_PLAN = @ID_PLAN;
            IF @IT_TIT IS NULL
            BEGIN
                SET @ERROR = 'El item no pertenece al plan de este proyecto.';
                RETURN;
            END;
            IF @T11 = ''
            BEGIN
                SET @ERROR = 'Escriba la gestion.';
                RETURN;
            END;
            IF @T12 <> ''
            BEGIN
                IF @T12 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T12,'-','')) = 0
                BEGIN
                    SET @ERROR = 'La fecha de vencimiento no es valida.';
                    RETURN;
                END;
                SET @F_VEN = CONVERT(DATETIME, REPLACE(@T12,'-',''), 112);
            END;
            IF @T13 LIKE 'C:%' AND PATINDEX('%[^0-9]%', SUBSTRING(@T13, 3, 20)) = 0 AND LEN(@T13) BETWEEN 3 AND 11
                SELECT @R_TIPO = 'CONSULTOR', @R_ID = CONVERT(INT, SUBSTRING(@T13, 3, 20));
            IF @T13 LIKE 'E:%' AND PATINDEX('%[^0-9]%', SUBSTRING(@T13, 3, 20)) = 0 AND LEN(@T13) BETWEEN 3 AND 11
                SELECT @R_TIPO = 'EMPLEADO', @R_ID = CONVERT(INT, SUBSTRING(@T13, 3, 20));
 
            BEGIN TRANSACTION;
                INSERT INTO dbo.VCT_GESTIONES
                    (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN, ID_PLAN_ITEM,
                     REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    ('MANUAL',
                     ISNULL((SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'TAREA'), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS ORDER BY ID)),
                     (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'TRABAJO_PLAN_ITEM'),
                     @G_PEND, @G_NORM, LEFT(@T11, 300), NULLIF(@T14,''), @ID_CLIENTE, @ID_PROYECTO, @ID_PLAN, @ID_ITEM,
                     0, 0, GETDATE(),
                     CASE WHEN @F_VEN IS NOT NULL AND @F_VEN < GETDATE() THEN @F_VEN ELSE GETDATE() END,
                     @F_VEN, GETDATE(), @IAGENTE);
                SET @ID_NG = SCOPE_IDENTITY();
                UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_NG), 9) WHERE ID = @ID_NG;
 
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@ID_NG, NULL, @G_PEND, 'CREACION', LEFT('Gestion del plan (item: ' + @IT_TIT + ').', 2000), 'USUARIO', GETDATE(), @IAGENTE);
 
                INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                    (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                VALUES (@ID_NG, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                IF @R_ID IS NOT NULL
                    INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                        (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_NG, 'RESPONSABLE', @R_TIPO, @R_ID, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Gestion agregada al item.';
        END
 
        /* ---------------- pendiente del cliente (fuera del plan) ---------------- */
        ELSE IF @CMD = 'PLAN_PEND_ADD'
        BEGIN
            DECLARE @P_VEN DATETIME = NULL, @ID_NP INT;
            IF @T11 = ''
            BEGIN
                SET @ERROR = 'Escriba el pendiente del cliente.';
                RETURN;
            END;
            IF @T12 <> ''
            BEGIN
                IF @T12 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T12,'-','')) = 0
                BEGIN
                    SET @ERROR = 'La fecha no es valida.';
                    RETURN;
                END;
                SET @P_VEN = CONVERT(DATETIME, REPLACE(@T12,'-',''), 112);
            END;
 
            BEGIN TRANSACTION;
                INSERT INTO dbo.VCT_GESTIONES
                    (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN,
                     REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    ('MANUAL',
                     ISNULL((SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'TAREA'), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS ORDER BY ID)),
                     @ST_PEND, @G_PEND, @G_NORM, LEFT(@T11, 300), NULLIF(@T14,''), @ID_CLIENTE, @ID_PROYECTO, @ID_PLAN,
                     0, 0, GETDATE(),
                     CASE WHEN @P_VEN IS NOT NULL AND @P_VEN < GETDATE() THEN @P_VEN ELSE GETDATE() END,
                     @P_VEN, NULLIF(LEFT(@T13, 2000),''), GETDATE(), @IAGENTE);
                SET @ID_NP = SCOPE_IDENTITY();
                UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_NP), 9) WHERE ID = @ID_NP;
 
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@ID_NP, NULL, @G_PEND, 'CREACION', 'Pendiente del cliente.', 'USUARIO', GETDATE(), @IAGENTE);
 
                INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                    (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                VALUES (@ID_NP, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE),
                       (@ID_NP, 'RESPONSABLE', 'CLIENTE', @ID_CLIENTE, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = 'Pendiente del cliente agregado.';
        END
 
        /* ---------------- estado de una gestion del plan ---------------- */
        ELSE IF @CMD = 'PLAN_GESTION_ESTADO'
        BEGIN
            DECLARE @ID_GE INT = NULL, @EST_ANT INT, @EST_NUEVO INT, @NUEVO VARCHAR(20) = UPPER(@T11);
            IF @SEL3 <> '' AND PATINDEX('%[^0-9]%', @SEL3) = 0 AND LEN(@SEL3) <= 9
                SELECT @ID_GE = ID, @EST_ANT = ID_ESTADO FROM dbo.VCT_GESTIONES
                WHERE ID = CONVERT(INT, @SEL3) AND ID_PROYECTO = @ID_PROYECTO AND (ID_PLAN_ITEM IS NOT NULL OR ID_SUBTIPO = @ST_PEND);
 
            IF @ID_GE IS NULL
            BEGIN
                SET @ERROR = 'La gestion no pertenece al plan de este proyecto.';
                RETURN;
            END;
 
            SET @EST_NUEVO = CASE @NUEVO WHEN 'CUMPLIDA' THEN @G_CUMP WHEN 'CANCELADA' THEN @G_CANC WHEN 'PENDIENTE' THEN @G_PEND END;
            IF @EST_NUEVO IS NULL
            BEGIN
                SET @ERROR = 'Estado no reconocido.';
                RETURN;
            END;
 
            BEGIN TRANSACTION;
                UPDATE dbo.VCT_GESTIONES
                   SET ID_ESTADO = @EST_NUEVO,
                       ID_RESULTADO = CASE WHEN @NUEVO = 'CUMPLIDA' THEN ISNULL(@G_RES, ID_RESULTADO) WHEN @NUEVO = 'PENDIENTE' THEN NULL ELSE ID_RESULTADO END,
                       FECHA_CIERRE = CASE WHEN @NUEVO = 'PENDIENTE' THEN NULL ELSE GETDATE() END,
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_GE;
 
                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@ID_GE, @EST_ANT, @EST_NUEVO, 'CAMBIO_ESTADO',
                        CASE @NUEVO WHEN 'CUMPLIDA' THEN 'Gestion cumplida.' WHEN 'CANCELADA' THEN 'Gestion cancelada.' ELSE 'Gestion reabierta.' END,
                        'USUARIO', GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;
 
            SET @MENSAJE = CASE @NUEVO WHEN 'CUMPLIDA' THEN 'Gestion cumplida.' WHEN 'CANCELADA' THEN 'Gestion cancelada.' ELSE 'Gestion reabierta.' END;
        END
        ELSE
        BEGIN
            SET @ERROR = 'Comando no reconocido.';
            RETURN;
        END;
 
        /* avance y estado guardados en el item (para otras pantallas) */
        UPDATE I
           SET PORCENTAJE_AVANCE = C.AVANCE,
               ESTADO = dbo.VCT_CK_VALOR('dbo.VCT_PROYECTOS_PLAN_ITEMS', 'ESTADO',
                            CASE C.ESTADO_CALC WHEN 'CUMPLIDO' THEN 'CUMPLIDO,CUMPLIDA,COMPLETADO,CERRADO,PENDIENTE'
                                               WHEN 'VENCIDO' THEN 'VENCIDO,VENCIDA,EN_CURSO,EN_PROCESO,PENDIENTE'
                                               WHEN 'EN_CURSO' THEN 'EN_CURSO,EN_PROCESO,PENDIENTE'
                                               ELSE 'PENDIENTE' END)
          FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
          INNER JOIN dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C ON C.ID = I.ID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ERROR = LEFT('No se pudo grabar: ' + ERROR_MESSAGE(), 1000);
    END CATCH;
END
