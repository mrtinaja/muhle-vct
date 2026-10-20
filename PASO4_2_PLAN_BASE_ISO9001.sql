/* ========================================================================
   PASO4_2_PLAN_BASE_ISO9001  (CARGA DE DATOS DE PARAMETRIA - lo corre Esteban)
   ------------------------------------------------------------------------
   Reemplaza el plan base RE-PP-007 por el plan por norma ISO 9001:2015
   (RE-PP-007 Rev 06, pestania "Plan ISO 9001.2015"), en arbol:
      capitulo (titulo estandar ISO)  >  item (4.1)  >  subitem (5.1.1)
      + capitulo "Hitos" con las 3 auditorias.
   Que hace:
     1. Muestra que se va a borrar y quien lo usa.
     2. Si hay planes de proyecto generados con el RE-PP-007 viejo:
          @BORRAR_PLANES_PROYECTO = 0  -> se detiene y los lista (no toca nada).
          @BORRAR_PLANES_PROYECTO = 1  -> borra esos planes y sus items;
             las acciones de los items quedan CANCELADAS (con historial) y
             sin vinculo al plan; la "Carga del plan" vuelve a PENDIENTE.
     3. Borra SOLO el plan base RE-PP-007 (documento + items). Las minutas
        RE-PP-022 (datos de entrada), hojas de ruta y demas documentos NO se
        tocan: los usan los datos ya cargados de los proyectos.
     4. Reinicia el identity de VCT_PRM_DOCUMENTOS / _ITEMS al maximo actual.
     5. Carga el plan ISO 9001:2015 (ID_NORMA = ISO 9001:2015).
   Si otra tabla no prevista referencia lo que se borra, se detiene.
   Requiere PASO4_1. Todo en una transaccion. Archivo UTF-8 (acentos).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @BORRAR_PLANES_PROYECTO BIT = 0;   /* <<< 1 = tambien borra los planes de proyecto hechos con el plan base viejo */

DECLARE @OK BIT = 1, @NORMA INT, @DOC_NEW INT, @N INT, @SQL NVARCHAR(MAX), @MAXID INT,
        @E_CANC INT, @E_PEND INT, @E_PROC INT, @ST_CARGA INT, @USR VARCHAR(100) = 'PASO4_2';

IF COL_LENGTH('dbo.VCT_PRM_DOCUMENTOS', 'ID_NORMA') IS NULL BEGIN PRINT 'FALLO falta correr PASO4_1 (columna ID_NORMA).'; SET @OK = 0; END;
SELECT @NORMA = ID FROM dbo.VCT_PRM_NORMAS WITH(NOLOCK) WHERE DESCRIPCION = 'ISO 9001:2015';
IF @OK = 1 AND @NORMA IS NULL BEGIN PRINT 'FALLO no existe la norma ISO 9001:2015 en VCT_PRM_NORMAS.'; SET @OK = 0; END;
SELECT @E_CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';
SELECT @E_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE';
SELECT @E_PROC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'EN_PROCESO';
SELECT @ST_CARGA = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'CARGA_PLAN';

/* ---------- que se borra ---------- */
IF OBJECT_ID('tempdb..#DOC') IS NOT NULL DROP TABLE #DOC;
IF OBJECT_ID('tempdb..#DIT') IS NOT NULL DROP TABLE #DIT;
IF OBJECT_ID('tempdb..#PLN') IS NOT NULL DROP TABLE #PLN;
IF OBJECT_ID('tempdb..#PIT') IS NOT NULL DROP TABLE #PIT;
IF OBJECT_ID('tempdb..#ACC') IS NOT NULL DROP TABLE #ACC;
CREATE TABLE #DOC (ID INT PRIMARY KEY);
CREATE TABLE #DIT (ID INT PRIMARY KEY);
CREATE TABLE #PLN (ID INT PRIMARY KEY);
CREATE TABLE #PIT (ID INT PRIMARY KEY);
CREATE TABLE #ACC (ID INT PRIMARY KEY, ITEM INT, EST INT, SUB INT, FIN BIT);
INSERT INTO #DOC SELECT ID FROM dbo.VCT_PRM_DOCUMENTOS WHERE CODIGO = 'RE-PP-007';
INSERT INTO #DIT SELECT ID FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS WHERE ID_DOCUMENTO IN (SELECT ID FROM #DOC);
INSERT INTO #PLN SELECT ID FROM dbo.VCT_PROYECTOS_PLANES WHERE ID_DOCUMENTO IN (SELECT ID FROM #DOC)
UNION SELECT DISTINCT ID_PLAN FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_DOCUMENTO_ITEM IN (SELECT ID FROM #DIT);
INSERT INTO #PIT SELECT ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN IN (SELECT ID FROM #PLN);
INSERT INTO #ACC SELECT A.ID, A.ID_PLAN_ITEM, A.ID_ESTADO, A.ID_SUBTIPO, ISNULL(E.ES_FINAL, 0)
FROM dbo.VCT_ACCIONES A LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID_PLAN IN (SELECT ID FROM #PLN) OR A.ID_PLAN_ITEM IN (SELECT ID FROM #PIT);

SELECT 'Plan base a borrar' AS QUE, D.ID, D.CODIGO, D.DESCRIPCION, (SELECT COUNT(*) FROM #DIT X INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I ON I.ID = X.ID AND I.ID_DOCUMENTO = D.ID) AS ITEMS
FROM dbo.VCT_PRM_DOCUMENTOS D WHERE D.ID IN (SELECT ID FROM #DOC);
SELECT 'Planes de proyecto con el plan base viejo' AS QUE, P.CODIGO AS PROYECTO, PL.ID AS ID_PLAN,
       (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WHERE I.ID_PLAN = PL.ID) AS ITEMS,
       (SELECT COUNT(*) FROM #ACC A WHERE A.ITEM IN (SELECT I.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WHERE I.ID_PLAN = PL.ID)) AS ACCIONES_DE_ITEMS
FROM dbo.VCT_PROYECTOS_PLANES PL INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = PL.ID_PROYECTO
WHERE PL.ID IN (SELECT ID FROM #PLN) ORDER BY P.CODIGO;

/* ---------- otras tablas que referencian lo que se borra (no previstas: frena) ---------- */
IF OBJECT_ID('tempdb..#REF') IS NOT NULL DROP TABLE #REF;
CREATE TABLE #REF (TABLA SYSNAME, COLUMNA SYSNAME, REFERENCIA SYSNAME, FILAS INT);
DECLARE @T SYSNAME, @C SYSNAME, @R SYSNAME, @X SYSNAME;
DECLARE CF CURSOR LOCAL STATIC READ_ONLY FOR
    SELECT OBJECT_NAME(FC.parent_object_id), COL_NAME(FC.parent_object_id, FC.parent_column_id), OBJECT_NAME(FC.referenced_object_id)
    FROM sys.foreign_key_columns FC
    WHERE FC.referenced_object_id IN (OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS'), OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_ITEMS'),
                                      OBJECT_ID('dbo.VCT_PROYECTOS_PLANES'), OBJECT_ID('dbo.VCT_PROYECTOS_PLAN_ITEMS'))
      AND COL_NAME(FC.referenced_object_id, FC.referenced_column_id) = 'ID';
OPEN CF;
FETCH NEXT FROM CF INTO @T, @C, @R;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @X = CASE @R WHEN 'VCT_PRM_DOCUMENTOS' THEN '#DOC' WHEN 'VCT_PRM_DOCUMENTOS_ITEMS' THEN '#DIT' WHEN 'VCT_PROYECTOS_PLANES' THEN '#PLN' ELSE '#PIT' END;
    SET @SQL = N'SELECT @N = COUNT(*) FROM dbo.' + QUOTENAME(@T) + N' WHERE ' + QUOTENAME(@C) + N' IN (SELECT ID FROM ' + @X + N')';
    EXEC sp_executesql @SQL, N'@N INT OUTPUT', @N = @N OUTPUT;
    INSERT INTO #REF VALUES (@T, @C, @R, @N);
    FETCH NEXT FROM CF INTO @T, @C, @R;
END;
CLOSE CF; DEALLOCATE CF;
SELECT TABLA, COLUMNA, REFERENCIA, FILAS FROM #REF WHERE FILAS > 0 ORDER BY TABLA;
IF @OK = 1 AND EXISTS (SELECT 1 FROM #REF WHERE FILAS > 0 AND TABLA NOT IN ('VCT_PRM_DOCUMENTOS_ITEMS','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_PLANES','VCT_ACCIONES','VCT_PRM_DOCUMENTOS_SERVICIOS'))
BEGIN
    PRINT 'FALLO hay tablas no previstas que usan el plan base o los planes (ver grilla de referencias). No se hizo nada.';
    SET @OK = 0;
END;
IF @OK = 1 AND EXISTS (SELECT 1 FROM #PLN) AND @BORRAR_PLANES_PROYECTO = 0
BEGIN
    PRINT 'FALLO hay planes de proyecto hechos con el plan base viejo (ver grilla). No se hizo nada.';
    PRINT '      Para borrarlos y cargar el plan nuevo: @BORRAR_PLANES_PROYECTO = 1 (sus acciones de items quedan CANCELADAS).';
    SET @OK = 0;
END;

/* ---------- plan ISO 9001:2015: capitulo (titulo estandar) > item > subitem; hitos ---------- */
DECLARE @P TABLE (ORD INT, COD NVARCHAR(50), PAD NVARCHAR(50), DES NVARCHAR(400), GRP VARCHAR(100));
INSERT INTO @P (ORD, COD, PAD, DES, GRP) VALUES
    (1, N'4', N'', N'Contexto de la organización', 'CAPITULO'),
    (2, N'4.1', N'4', N'Comprensión de la organización y de su contexto', 'PLAN ESTRATEGICO'),
    (3, N'4.2', N'4', N'Comprensión de las necesidades y expectativas de las partes interesadas', 'PLAN ESTRATEGICO'),
    (4, N'4.3', N'4', N'Determinación del alcance del Sistema de Gestión de Calidad', 'PLAN ESTRATEGICO'),
    (5, N'4.4', N'4', N'Sistema de Gestión de la calidad y sus procesos', 'PLAN ESTRATEGICO'),
    (6, N'5', N'', N'Liderazgo', 'CAPITULO'),
    (7, N'5.1', N'5', N'Liderazgo y compromiso', 'PLAN ESTRATEGICO'),
    (8, N'5.1.1', N'5.1', N'Generalidades', 'PLAN ESTRATEGICO'),
    (9, N'5.1.2', N'5.1', N'Enfoque al cliente', 'PLAN ESTRATEGICO'),
    (10, N'5.2', N'5', N'Política', 'PLAN ESTRATEGICO'),
    (11, N'5.2.1', N'5.2', N'Establecimiento de la política de la calidad', 'PLAN ESTRATEGICO'),
    (12, N'5.2.2', N'5.2', N'Comunicación de la política de la calidad', 'PLAN ESTRATEGICO'),
    (13, N'5.3', N'5', N'Roles, responsabilidades y autoridades en la organización', 'PLAN ESTRATEGICO'),
    (14, N'6', N'', N'Planificación', 'CAPITULO'),
    (15, N'6.1', N'6', N'Acciones para abordar riesgos y oportunidades', 'PLAN ESTRATEGICO'),
    (16, N'6.2', N'6', N'Objetivos de la calidad y planificación para lograrlos', 'PLAN ESTRATEGICO'),
    (17, N'6.3', N'6', N'Planificación de los cambios', 'PLAN ESTRATEGICO'),
    (18, N'7', N'', N'Apoyo', 'CAPITULO'),
    (19, N'7.1', N'7', N'Recursos', 'PLAN ESTRATEGICO'),
    (20, N'7.1.1', N'7.1', N'Generalidades', 'PLAN ESTRATEGICO'),
    (21, N'7.1.2', N'7.1', N'Personas', 'PLAN ESTRATEGICO'),
    (22, N'7.1.3', N'7.1', N'Infraestructura', 'PLAN ESTRATEGICO'),
    (23, N'7.1.4', N'7.1', N'Ambiente para la operación de los procesos', 'PLAN ESTRATEGICO'),
    (24, N'7.1.5', N'7.1', N'Recursos de seguimiento y medición', 'PLAN ESTRATEGICO'),
    (25, N'7.1.6', N'7.1', N'Conocimientos de la organización', 'PLAN ESTRATEGICO'),
    (26, N'7.2', N'7', N'Competencia', 'PLAN ESTRATEGICO'),
    (27, N'7.3', N'7', N'Toma de conciencia', 'PLAN ESTRATEGICO'),
    (28, N'7.4', N'7', N'Comunicación', 'PLAN ESTRATEGICO'),
    (29, N'7.5', N'7', N'Información documentada', 'PLAN ESTRATEGICO'),
    (30, N'7.5.1', N'7.5', N'Generalidades', 'PLAN ESTRATEGICO'),
    (31, N'7.5.2', N'7.5', N'Creación y actualización', 'PLAN ESTRATEGICO'),
    (32, N'7.5.3', N'7.5', N'Control de la información documentada', 'PLAN ESTRATEGICO'),
    (33, N'8', N'', N'Operación', 'CAPITULO'),
    (34, N'8.1', N'8', N'Planificación y control operacional', 'PLAN ESTRATEGICO'),
    (35, N'8.2', N'8', N'Requisitos para los productos y servicios', 'PLAN ESTRATEGICO'),
    (36, N'8.2.1', N'8.2', N'Comunicación con el cliente', 'PLAN ESTRATEGICO'),
    (37, N'8.2.2', N'8.2', N'Determinación de los requisitos para los productos y servicios', 'PLAN ESTRATEGICO'),
    (38, N'8.2.3', N'8.2', N'Revisión de los requisitos para los productos y servicios', 'PLAN ESTRATEGICO'),
    (39, N'8.2.4', N'8.2', N'Cambios en los requisitos para los productos y servicios', 'PLAN ESTRATEGICO'),
    (40, N'8.3', N'8', N'Diseño y desarrollo de los productos y servicios', 'PLAN ESTRATEGICO'),
    (41, N'8.3.1', N'8.3', N'Generalidades', 'PLAN ESTRATEGICO'),
    (42, N'8.3.2', N'8.3', N'Planificación del diseño y desarrollo', 'PLAN ESTRATEGICO'),
    (43, N'8.3.3', N'8.3', N'Entradas para el diseño y desarrollo', 'PLAN ESTRATEGICO'),
    (44, N'8.3.4', N'8.3', N'Controles del diseño y desarrollo', 'PLAN ESTRATEGICO'),
    (45, N'8.3.5', N'8.3', N'Salidas del diseño y desarrollo', 'PLAN ESTRATEGICO'),
    (46, N'8.3.6', N'8.3', N'Cambios en el diseño y desarrollo', 'PLAN ESTRATEGICO'),
    (47, N'8.4', N'8', N'Control de los procesos, productos y servicios suministrados externamente', 'PLAN ESTRATEGICO'),
    (48, N'8.4.1', N'8.4', N'Generalidades', 'PLAN ESTRATEGICO'),
    (49, N'8.4.2', N'8.4', N'Tipo y alcance del control', 'PLAN ESTRATEGICO'),
    (50, N'8.4.3', N'8.4', N'Información para los proveedores externos', 'PLAN ESTRATEGICO'),
    (51, N'8.5', N'8', N'Producción y provisión del servicio', 'PLAN ESTRATEGICO'),
    (52, N'8.5.1', N'8.5', N'Control de la producción y de la provisión del servicio', 'PLAN ESTRATEGICO'),
    (53, N'8.5.2', N'8.5', N'Identificación y trazabilidad', 'PLAN ESTRATEGICO'),
    (54, N'8.5.3', N'8.5', N'Propiedad perteneciente a los clientes o proveedores externos', 'PLAN ESTRATEGICO'),
    (55, N'8.5.4', N'8.5', N'Preservación', 'PLAN ESTRATEGICO'),
    (56, N'8.5.5', N'8.5', N'Actividades posteriores a la entrega', 'PLAN ESTRATEGICO'),
    (57, N'8.5.6', N'8.5', N'Control de los cambios', 'PLAN ESTRATEGICO'),
    (58, N'8.6', N'8', N'Liberación de los productos y servicios', 'PLAN ESTRATEGICO'),
    (59, N'8.7', N'8', N'Control de las salidas no conformes', 'PLAN ESTRATEGICO'),
    (60, N'9', N'', N'Evaluación del desempeño', 'CAPITULO'),
    (61, N'9.1', N'9', N'Seguimiento, medición, análisis y evaluación', 'PLAN ESTRATEGICO'),
    (62, N'9.1.1', N'9.1', N'Generalidades', 'PLAN ESTRATEGICO'),
    (63, N'9.1.2', N'9.1', N'Satisfacción del cliente', 'PLAN ESTRATEGICO'),
    (64, N'9.1.3', N'9.1', N'Análisis y evaluación', 'PLAN ESTRATEGICO'),
    (65, N'9.2', N'9', N'Auditoria interna', 'PLAN ESTRATEGICO'),
    (66, N'9.3', N'9', N'Revisión por la dirección', 'PLAN ESTRATEGICO'),
    (67, N'9.3.1', N'9.3', N'Generalidades', 'PLAN ESTRATEGICO'),
    (68, N'9.3.2', N'9.3', N'Entradas de la revisión por la dirección', 'PLAN ESTRATEGICO'),
    (69, N'9.3.3', N'9.3', N'Salidas de la revisión por la dirección', 'PLAN ESTRATEGICO'),
    (70, N'10', N'', N'Mejora', 'CAPITULO'),
    (71, N'10.1', N'10', N'Generalidades', 'PLAN ESTRATEGICO'),
    (72, N'10.2', N'10', N'No conformidades y acción correctiva', 'PLAN ESTRATEGICO'),
    (73, N'10.3', N'10', N'Mejora continua', 'PLAN ESTRATEGICO'),
    (74, N'H', N'', N'Hitos', 'CAPITULO'),
    (75, N'', N'H', N'Realización de Auditoria Interna', 'HITO'),
    (76, N'', N'H', N'Realización de Auditoria Inicial por el Organismo de Certificación', 'HITO'),
    (77, N'', N'H', N'Realización de la Auditoria principal por el Organismo de Certificación', 'HITO');

IF @OK = 1
BEGIN
    DECLARE @TRG BIT = 0;
    BEGIN TRY
        BEGIN TRAN;

        /* acciones de los items de los planes viejos: canceladas, sin vinculo al plan */
        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
        SELECT A.ID, A.EST, CASE WHEN A.FIN = 1 THEN A.EST ELSE @E_CANC END, 'PLAN_REINICIADO',
               'Se reemplazo el plan base del proyecto (plan por norma). La accion queda sin item del plan.', 'SISTEMA', GETDATE(), @USR
        FROM #ACC A WHERE A.ITEM IS NOT NULL;
        UPDATE X SET ID_ESTADO = CASE WHEN A.FIN = 1 THEN X.ID_ESTADO ELSE @E_CANC END,
                     FECHA_CIERRE = CASE WHEN A.FIN = 1 THEN X.FECHA_CIERRE ELSE GETDATE() END,
                     ID_PLAN = NULL, ID_PLAN_ITEM = NULL, FECHA_UPD = GETDATE(), USUARIO_UPD = @USR
        FROM dbo.VCT_ACCIONES X INNER JOIN #ACC A ON A.ID = X.ID WHERE A.ITEM IS NOT NULL;
        /* "Carga del plan": sin plan, vuelve a pendiente para generar el nuevo */
        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
        SELECT A.ID, A.EST, @E_PEND, 'PLAN_REINICIADO', 'Se reemplazo el plan base: hay que generar el plan nuevo.', 'SISTEMA', GETDATE(), @USR
        FROM #ACC A WHERE A.ITEM IS NULL AND A.SUB = @ST_CARGA AND A.FIN = 0;
        UPDATE X SET ID_ESTADO = CASE WHEN A.SUB = @ST_CARGA AND A.FIN = 0 THEN @E_PEND ELSE X.ID_ESTADO END,
                     ID_PLAN = NULL, FECHA_UPD = GETDATE(), USUARIO_UPD = @USR
        FROM dbo.VCT_ACCIONES X INNER JOIN #ACC A ON A.ID = X.ID WHERE A.ITEM IS NULL;

        /* planes de proyecto viejos */
        UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS SET ID_PADRE = NULL WHERE ID IN (SELECT ID FROM #PIT);
        DELETE FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID IN (SELECT ID FROM #PIT);
        DELETE FROM dbo.VCT_PROYECTOS_PLANES WHERE ID IN (SELECT ID FROM #PLN);

        /* vinculo documento / servicio: se guarda para pasarlo al documento nuevo */
        DECLARE @DS_COL SYSNAME = (SELECT TOP 1 COLUMNA FROM #REF WHERE TABLA = 'VCT_PRM_DOCUMENTOS_SERVICIOS' AND REFERENCIA = 'VCT_PRM_DOCUMENTOS');
        IF OBJECT_ID('tempdb..##DS42') IS NOT NULL DROP TABLE ##DS42;
        IF @DS_COL IS NOT NULL
        BEGIN
            SET @SQL = N'SELECT * INTO ##DS42 FROM dbo.VCT_PRM_DOCUMENTOS_SERVICIOS WHERE ' + QUOTENAME(@DS_COL) + N' IN (SELECT ID FROM #DOC);'
                     + N'DELETE FROM dbo.VCT_PRM_DOCUMENTOS_SERVICIOS WHERE ' + QUOTENAME(@DS_COL) + N' IN (SELECT ID FROM #DOC);';
            EXEC sp_executesql @SQL;
        END;

        /* plan base viejo */
        UPDATE dbo.VCT_PRM_DOCUMENTOS_ITEMS SET ID_PADRE = NULL WHERE ID IN (SELECT ID FROM #DIT);
        DELETE FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS WHERE ID IN (SELECT ID FROM #DIT);
        DELETE FROM dbo.VCT_PRM_DOCUMENTOS WHERE ID IN (SELECT ID FROM #DOC);

        /* identity al maximo actual (el proximo ID sigue al ultimo que queda) */
        SELECT @MAXID = ISNULL(MAX(ID), 0) FROM dbo.VCT_PRM_DOCUMENTOS;
        DBCC CHECKIDENT ('dbo.VCT_PRM_DOCUMENTOS', RESEED, @MAXID) WITH NO_INFOMSGS;
        SELECT @MAXID = ISNULL(MAX(ID), 0) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS;
        DBCC CHECKIDENT ('dbo.VCT_PRM_DOCUMENTOS_ITEMS', RESEED, @MAXID) WITH NO_INFOMSGS;

        /* documento nuevo */
        INSERT INTO dbo.VCT_PRM_DOCUMENTOS (CODIGO, DESCRIPCION, COMENTARIO, TIPO_DETALLE, ACTIVO, ID_NORMA, FECHA_ALTA, USUARIO_ALTA)
        VALUES ('RE-PP-007', N'Plan Estratégico ISO 9001:2015', 'Rev 06', 'PLAN', 1, @NORMA, GETDATE(), @USR);
        SET @DOC_NEW = SCOPE_IDENTITY();

        /* items: primero todos sin padre, despues se enlaza cada uno con su padre (por codigo) */
        INSERT INTO dbo.VCT_PRM_DOCUMENTOS_ITEMS (ID_DOCUMENTO, ID_PADRE, CODIGO_ITEM, DESCRIPCION, GRUPO, ORDEN, OBLIGATORIO, EXPORTA, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
        SELECT @DOC_NEW, NULL, NULLIF(COD, N''), DES, GRP, ORD, 0, 1, 1, GETDATE(), @USR FROM @P ORDER BY ORD;
        UPDATE I SET ID_PADRE = PADRE.ID
        FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
        INNER JOIN @P P ON P.ORD = I.ORDEN AND I.ID_DOCUMENTO = @DOC_NEW
        INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS PADRE ON PADRE.ID_DOCUMENTO = @DOC_NEW AND PADRE.CODIGO_ITEM = P.PAD
        WHERE P.PAD <> N'';

        /* vinculo documento / servicio al documento nuevo */
        IF OBJECT_ID('tempdb..##DS42') IS NOT NULL
        BEGIN
            DECLARE @COLS NVARCHAR(MAX) = N'', @VALS NVARCHAR(MAX) = N'';
            SELECT @COLS = @COLS + N', ' + QUOTENAME(name),
                   @VALS = @VALS + N', ' + CASE WHEN name = @DS_COL THEN CONVERT(NVARCHAR(20), @DOC_NEW) ELSE QUOTENAME(name) END
            FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_SERVICIOS') AND is_identity = 0 AND is_computed = 0 ORDER BY column_id;
            SET @SQL = N'INSERT INTO dbo.VCT_PRM_DOCUMENTOS_SERVICIOS (' + STUFF(@COLS, 1, 2, N'') + N') SELECT DISTINCT ' + STUFF(@VALS, 1, 2, N'') + N' FROM ##DS42;';
            EXEC sp_executesql @SQL;
            DROP TABLE ##DS42;
        END;

        COMMIT;
        PRINT 'OK   plan base ISO 9001:2015 cargado (documento ' + CONVERT(VARCHAR(20), @DOC_NEW) + ').';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        IF OBJECT_ID('tempdb..##DS42') IS NOT NULL DROP TABLE ##DS42;
        PRINT 'FALLO ' + ERROR_MESSAGE();
        PRINT 'No se aplico ningun cambio.';
    END CATCH;
END;

/* control: arbol cargado */
SELECT D.ID AS ID_DOC, D.DESCRIPCION AS PLAN_BASE, N.DESCRIPCION AS NORMA,
       SUM(CASE WHEN I.GRUPO = 'CAPITULO' THEN 1 ELSE 0 END) AS CAPITULOS,
       SUM(CASE WHEN I.GRUPO <> 'CAPITULO' AND P.GRUPO = 'CAPITULO' THEN 1 ELSE 0 END) AS ITEMS,
       SUM(CASE WHEN P.GRUPO IS NOT NULL AND P.GRUPO <> 'CAPITULO' THEN 1 ELSE 0 END) AS SUBITEMS
FROM dbo.VCT_PRM_DOCUMENTOS D
LEFT JOIN dbo.VCT_PRM_NORMAS N ON N.ID = D.ID_NORMA
LEFT JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I ON I.ID_DOCUMENTO = D.ID
LEFT JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS P ON P.ID = I.ID_PADRE
WHERE D.CODIGO = 'RE-PP-007'
GROUP BY D.ID, D.DESCRIPCION, N.DESCRIPCION;
