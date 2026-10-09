/* ========================================================================
   PROYECTO_PLAN_1_INSTALACION  (CREA FUNCIONES Y SP: leer antes)
   ------------------------------------------------------------------------
   Plan Estrategico en la Vista 360 de Proyecto (pantalla del consultor
   lider). Sin tablas ni columnas nuevas: usa VCT_PROYECTOS_PLANES,
   VCT_PROYECTOS_PLAN_ITEMS y VCT_GESTIONES (ID_PLAN / ID_PLAN_ITEM).
   Criterio (Resumen_reunion_sistema_gestion.pdf + Excel RE-PP-007 rev 6):
     - Plan base = documento RE-PP-007 de parametria (VCT_PRM_DOCUMENTOS),
       o plan en blanco. Se pueden agregar items libres (diagnostico,
       auditoria interna, certificacion...).
     - Item: N, codigo, item, descripcion, responsables (texto libre),
       inicio, fin, fin real, observaciones.
     - Estado del item por fechas, como el Excel: Cumplido (tiene fin real),
       Vencido (fin < hoy), En curso, Pendiente (todavia no empieza).
     - Avance del item = gestiones cumplidas / gestiones del item (sin las
       canceladas). Dinamico: si se agrega una gestion, baja.
       Sin gestiones: 100% si tiene fin real, si no 0%.
     - Tiempo consumido del item, como el Excel: dias transcurridos entre
       inicio y fin (100% con fin real o fin vencido).
     - Avance global = promedio del avance de los items (alimenta el KPI
       "Avance proyecto": lanzamiento 10% + plan 90%).
     - Cambio de fecha de un item ya fechado -> gestion de AVISO al
       analista del proyecto (alerta inmediata, pedida en la reunion).
   Objetos:
     1. dbo.VCT_CK_VALOR             valor permitido por CHECK de una columna
     2. dbo.VCT_PROYECTO_PLAN_CALC   items del plan con avance/tiempo/estado
     3. dbo.VCT_PROYECTO_AVANCE      (se recrea: el plan usa el avance nuevo)
     4. dbo.VCT_PROYECTO_PLAN_ACCION graba (comandos PLAN_* en TEXTO30)
     5. dbo.VCT_PROYECTO_PLAN_RENDER arma la seccion y sus formularios
   Permisos: PLAN.EDIT (editar) y PLAN.VIEW (ver). Sin ninguno de los dos
   la seccion no se muestra. Se asignan con PERMISOS_PLAN.sql.
   Todo se puede volver a correr. Despues: PROYECTO_PLAN_2_PARCHE_V360.sql
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Restricciones CHECK de las columnas ESTADO (informativo) */
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name AS RESTRICCION, definition AS DEFINICION
FROM sys.check_constraints
WHERE parent_object_id IN (OBJECT_ID('dbo.VCT_PROYECTOS_PLANES'), OBJECT_ID('dbo.VCT_PROYECTOS_PLAN_ITEMS'))
   OR name = 'CK_VCT_GES_FECHAS';
GO

/* ---------------- 0. parametria ---------------- */
/* Template del aviso de cambio de fecha. MODO PRUEBA: destino LIBRE
   (martin.aja + esteban.de.marco). Al salir a produccion: DESTINO_TIPO = ANALISTA. */
IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE UPPER(LTRIM(RTRIM(CODIGO)))='PLAN_CAMBIO_FECHA')
INSERT INTO dbo.VCT_PRM_EMAIL_TEMPLATES
    (CODIGO, DESCRIPCION, TIPO_ENVIO, DESTINO_TIPO, DESTINO_LIBRE, CC_TIPO, CC_LIBRE, ESTADO, ASUNTO, HTML_CONTENIDO, DISENO_JSON, FECHA_ALTA, USUARIO_ALTA)
VALUES
    ('PLAN_CAMBIO_FECHA',
     'Aviso automatico al analista cuando se cambian las fechas de un item del Plan Estrategico.',
     'AUTOMATICO', 'LIBRE', 'martin.aja@squad.com.ar; esteban.de.marco@squad.com.ar', 'NINGUNO', NULL, 'ACTIVO',
     'Cambio de fecha en el plan: ({{CODIGO_PROYECTO}}) {{PROYECTO}}',
       '<!doctype html><html><head><meta charset="utf-8"><style>html,body{overflow-x:hidden;}</style></head>'
     + '<body style="margin:0;padding:0;background:#f3f5f7;">'
     + '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#f3f5f7;padding:24px 0;"><tr><td align="center">'
     + '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:600px;max-width:94%;background:#ffffff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;"><tr>'
     + '<td data-vct-email-content style="padding:20px 24px;color:#263247;font-family:Arial,sans-serif;font-size:14px;line-height:1.6;">'
     + '<img src="https://vocaturo.desa.interdev.online/img/vct-mail-banner-Bordeaux.png" alt="" width="600" height="90" style="max-width:100%;width:100%;height:auto;display:block;margin:0;">'
     + '<div><br></div>'
     + '<div style="font-size:17px;font-weight:bold;color:#66062D;">Cambio de fecha en el Plan Estrat&eacute;gico</div>'
     + '<div><br></div>'
     + '<div>Hola {{ANALISTA}},</div>'
     + '<div>Se modificaron las fechas de un &iacute;tem del plan del proyecto <b>({{CODIGO_PROYECTO}}) {{PROYECTO}}</b> del cliente <b>{{CLIENTE}}</b>.</div>'
     + '<div><br></div>'
     + '<div><b>&Iacute;tem:</b> {{ITEM}}</div>'
     + '<div><b>Cambio:</b> {{CAMBIOS}}</div>'
     + '<div><b>Realizado por:</b> {{USUARIO}}</div>'
     + '<div><br></div>'
     + '<div>El aviso es para que est&eacute;s al tanto. Si fue un error, consultalo con el consultor.</div>'
     + '<div><br></div>'
     + '<div>Pod&eacute;s verlo en <a href="https://vocaturo.desa.interdev.online/main/">https://vocaturo.desa.interdev.online/main/</a></div>'
     + '<div><br></div>'
     + '<div style="color:#6b7280;font-size:12px;">Mail generado autom&aacute;ticamente el {{FECHA}} a las {{HORA}}.</div>'
     + '</td></tr></table>'
     + '</td></tr></table></body></html>',
     NULL, GETDATE(), 'PROYECTO_PLAN');
GO

/* Subtipo de gestion para los pendientes del cliente (fuera del plan). */
IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'PENDIENTE_CLIENTE')
INSERT INTO dbo.VCT_PRM_GESTIONES_SUBTIPOS (ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
SELECT TOP 1 T.ID, 'PENDIENTE_CLIENTE', 'Pendiente del cliente', 11, 1, GETDATE(), 'PROYECTO_PLAN'
FROM dbo.VCT_PRM_GESTIONES_TIPOS T WHERE T.CODIGO = 'TAREA';
GO

/* ---------------- 1. valor permitido por CHECK ---------------- */
/* Devuelve el primer candidato (lista separada por comas) que acepta la
   restriccion CHECK de la columna; si no hay restriccion, el primero. */
CREATE OR ALTER FUNCTION dbo.VCT_CK_VALOR (@TABLA SYSNAME, @COLUMNA SYSNAME, @CANDIDATOS VARCHAR(400))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @DEF NVARCHAR(MAX) = NULL, @L VARCHAR(500) = ISNULL(@CANDIDATOS,'') + ',', @C VARCHAR(50),
            @P INT, @PRIMERO VARCHAR(50) = NULL, @R VARCHAR(50) = NULL;

    SELECT @DEF = ISNULL(@DEF, N'') + CC.definition
    FROM sys.check_constraints CC
    WHERE CC.parent_object_id = OBJECT_ID(@TABLA)
      AND CC.definition LIKE N'%' + @COLUMNA + N'%';

    SET @P = CHARINDEX(',', @L);
    WHILE @P > 0 AND @R IS NULL
    BEGIN
        SET @C = LTRIM(RTRIM(LEFT(@L, @P - 1)));
        SET @L = SUBSTRING(@L, @P + 1, 500);
        IF @C <> ''
        BEGIN
            IF @PRIMERO IS NULL SET @PRIMERO = @C;
            IF @DEF IS NULL OR @DEF LIKE N'%''' + @C + N'''%' SET @R = @C;
        END;
        SET @P = CHARINDEX(',', @L);
    END;
    RETURN ISNULL(@R, @PRIMERO);
END
GO

/* ---------------- 2. calculo de items ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_PLAN_CALC (@ID_PROYECTO INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        I.ID, I.ID_PLAN, I.ID_PADRE, I.ID_DOCUMENTO_ITEM, I.CODIGO_ITEM, I.TITULO, I.DESCRIPCION,
        I.VALOR AS RESPONSABLES, ISNULL(I.ORDEN, 0) AS ORDEN, I.OBSERVACIONES,
        I.FECHA_INICIO, I.FECHA_VENCIMIENTO, I.FECHA_CIERRE,
        ISNULL(G.TOTAL, 0) AS G_TOTAL,
        ISNULL(G.CUMPLIDAS, 0) AS G_CUMPLIDAS,
        CASE WHEN ISNULL(G.TOTAL, 0) > 0 THEN (ISNULL(G.CUMPLIDAS, 0) * 100) / G.TOTAL
             WHEN I.FECHA_CIERRE IS NOT NULL THEN 100
             ELSE 0 END AS AVANCE,
        CASE WHEN I.FECHA_CIERRE IS NOT NULL THEN 100
             WHEN I.FECHA_INICIO IS NULL OR I.FECHA_VENCIMIENTO IS NULL THEN 0
             WHEN CONVERT(DATE, I.FECHA_INICIO) > T.HOY THEN 0
             WHEN CONVERT(DATE, I.FECHA_VENCIMIENTO) <= CONVERT(DATE, I.FECHA_INICIO) THEN 100
             WHEN T.HOY >= CONVERT(DATE, I.FECHA_VENCIMIENTO) THEN 100
             ELSE (DATEDIFF(DAY, CONVERT(DATE, I.FECHA_INICIO), T.HOY) * 100)
                  / DATEDIFF(DAY, CONVERT(DATE, I.FECHA_INICIO), CONVERT(DATE, I.FECHA_VENCIMIENTO)) END AS TIEMPO,
        CASE WHEN I.FECHA_CIERRE IS NOT NULL THEN 'CUMPLIDO'
             WHEN I.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, I.FECHA_VENCIMIENTO) < T.HOY THEN 'VENCIDO'
             WHEN I.FECHA_INICIO IS NULL THEN 'SIN_FECHAS'
             WHEN CONVERT(DATE, I.FECHA_INICIO) > T.HOY THEN 'PENDIENTE'
             ELSE 'EN_CURSO' END AS ESTADO_CALC,
        CASE WHEN I.FECHA_CIERRE IS NULL AND I.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, I.FECHA_VENCIMIENTO) < T.HOY
             THEN DATEDIFF(DAY, CONVERT(DATE, I.FECHA_VENCIMIENTO), T.HOY) ELSE 0 END AS DIAS_ATRASO
    FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
    INNER JOIN (SELECT TOP 1 PL.ID FROM dbo.VCT_PROYECTOS_PLANES PL
                WHERE PL.ID_PROYECTO = @ID_PROYECTO ORDER BY PL.ID DESC) P ON P.ID = I.ID_PLAN
    CROSS APPLY (SELECT CONVERT(DATE, GETDATE()) AS HOY) T
    OUTER APPLY
    (
        SELECT COUNT(*) AS TOTAL,
               SUM(CASE WHEN E.CODIGO = 'CUMPLIDA' THEN 1 ELSE 0 END) AS CUMPLIDAS
        FROM dbo.VCT_GESTIONES GX
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS E ON E.ID = GX.ID_ESTADO
        WHERE GX.ID_PLAN_ITEM = I.ID AND E.CODIGO <> 'CANCELADA'
    ) G
)
GO

/* ---------------- 3. avance del proyecto (se recrea) ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_AVANCE (@ID_PROYECTO INT)
RETURNS @R TABLE (AVANCE INT, DETALLE VARCHAR(200))
AS
BEGIN
    DECLARE @COD VARCHAR(50), @PASOS INT = 0, @NITEMS INT = 0, @PLAN DECIMAL(9,2) = 0, @V DECIMAL(9,2),
            @GT INT = 0, @GC INT = 0;

    SELECT @COD = ISNULL(ESTADO_CODIGO, ''),
           @PASOS = CASE WHEN ISNULL(CONSULTORES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(DATOS_CARGADOS,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(CONSIDERACIONES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(REUNION_OK,0) = 1 THEN 1 ELSE 0 END
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);

    IF @COD LIKE 'FINALIZ%' OR @COD LIKE 'CERRAD%' OR @COD LIKE 'TERMIN%' OR @COD LIKE 'COMPLET%'
    BEGIN
        INSERT INTO @R VALUES (100, 'Proyecto finalizado');
        RETURN;
    END;

    SELECT @NITEMS = COUNT(*),
           @PLAN = ISNULL(AVG(CAST(C.AVANCE AS DECIMAL(9,2))), 0),
           @GT = ISNULL(SUM(C.G_TOTAL), 0),
           @GC = ISNULL(SUM(C.G_CUMPLIDAS), 0)
    FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C;

    IF @COD = 'ENCURSO' OR @NITEMS > 0 SET @PASOS = 4;

    SET @V = @PASOS * 2.5 + @PLAN * 0.9;
    IF @V > 100 SET @V = 100;

    INSERT INTO @R VALUES (
        CAST(ROUND(@V, 0) AS INT),
        CASE WHEN @NITEMS > 0 THEN 'Plan estrategico: ' + CASE WHEN ROUND(@PLAN,1) = FLOOR(ROUND(@PLAN,1)) THEN CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS INT))
                                                     ELSE REPLACE(CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS DECIMAL(5,1))), '.', ',') END + '% ('
                                   + CONVERT(VARCHAR(10), @GC) + ' de ' + CONVERT(VARCHAR(10), @GT) + ' gestiones)'
             WHEN @COD = 'ENCURSO' THEN 'Lanzado - plan estrategico pendiente'
             ELSE 'Lanzamiento: ' + CONVERT(VARCHAR(2), @PASOS) + ' de 4 pasos' END);
    RETURN;
END
GO

/* ---------------- 4. acciones ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_PLAN_ACCION
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
GO

/* ---------------- 5. render de la seccion ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_PLAN_RENDER
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
GO

PRINT 'OK: Plan Estrategico instalado (funciones y SP de accion/render). Siguiente: PROYECTO_PLAN_2_PARCHE_V360.sql';
GO
