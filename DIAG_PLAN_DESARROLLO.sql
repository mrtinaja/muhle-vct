:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_PLAN_DESARROLLO.txt
/* ============================================================================
   DIAG_PLAN_DESARROLLO  (solo lectura: no modifica nada)
   Relevamiento para: desarrollo de acciones del plan (detalles con visita y horas),
   carga del plan por Excel, dias habiles y tiempo transcurrido desde la primera visita.
   SSMS: Query > SQLCMD Mode, F5. Si no aparece el .txt, pegar la salida.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== 1. columnas de las tablas involucradas ===';
SELECT t.name AS tabla, c.column_id, c.name AS columna, TYPE_NAME(c.user_type_id) AS tipo, c.max_length, c.is_nullable,
       c.is_identity, ISNULL(OBJECT_DEFINITION(c.default_object_id), '') AS def
FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name IN ('VCT_ACCIONES','VCT_ACCIONES_HISTORIAL','VCT_ACCIONES_PARTICIPANTES','VCT_PROYECTOS_PLANES','VCT_PROYECTOS_PLAN_ITEMS',
                 'VCT_PROYECTOS_VISITAS_REGISTRO','VCT_BUFFER','Calendar','VCT_PRM_ACCIONES_ESTADOS','VCT_PRM_ACCIONES_SUBTIPOS')
ORDER BY t.name, c.column_id;

PRINT '=== 2. claves foraneas, checks y triggers de acciones y plan ===';
SELECT OBJECT_NAME(fk.parent_object_id) AS tabla, fk.name AS fk, OBJECT_NAME(fk.referenced_object_id) AS ref
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('VCT_ACCIONES','VCT_ACCIONES_HISTORIAL','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_PLANES','VCT_PROYECTOS_VISITAS_REGISTRO')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('VCT_ACCIONES','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_PLANES')
ORDER BY 1, 2;
SELECT OBJECT_NAME(cc.parent_object_id) AS tabla, cc.name, cc.definition
FROM sys.check_constraints cc
WHERE OBJECT_NAME(cc.parent_object_id) IN ('VCT_ACCIONES','VCT_ACCIONES_HISTORIAL','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_PLANES','VCT_PROYECTOS_VISITAS_REGISTRO');
SELECT OBJECT_NAME(tr.parent_id) AS tabla, tr.name AS trigger_name, tr.is_disabled, LEN(OBJECT_DEFINITION(tr.object_id)) AS largo
FROM sys.triggers tr
WHERE tr.parent_class = 1 AND OBJECT_NAME(tr.parent_id) IN ('VCT_ACCIONES','VCT_ACCIONES_HISTORIAL','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_PLANES','VCT_PROYECTOS_VISITAS_REGISTRO','VCT_PROYECTOS_VISITAS');

PRINT '=== 3. parametria de acciones (estados, resultados, tipos y subtipos del plan) ===';
SELECT ID, CODIGO, DESCRIPCION, ES_FINAL, ACTIVO FROM dbo.VCT_PRM_ACCIONES_ESTADOS ORDER BY ID;
SELECT * FROM dbo.VCT_PRM_ACCIONES_RESULTADOS ORDER BY 1;
SELECT T.ID AS ID_TIPO, T.DESCRIPCION AS TIPO, S.ID AS ID_SUBTIPO, S.CODIGO, S.DESCRIPCION AS SUBTIPO, S.CARGA_MANUAL, S.ACTIVO
FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS S LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T ON T.ID = S.ID_TIPO
ORDER BY T.ID, S.ID;

PRINT '=== 4. nombres libres para la tabla nueva (debe dar vacio) ===';
SELECT name, type_desc FROM sys.objects WHERE name LIKE 'VCT_ACCIONES_DESARROLLO%' OR name LIKE 'VCT_PLAN%DESARROLLO%';

PRINT '=== 5. plan del proyecto 1348 (estructura y fechas) ===';
DECLARE @P INT = (SELECT ID FROM dbo.VCT_PROYECTOS WHERE CODIGO = '1348');
SELECT PL.ID, PL.ID_PROYECTO_SERVICIO, PL.ID_DOCUMENTO, PL.VERSION, PL.ESTADO, PL.FECHA_INICIO, PL.FECHA_ALTA, PL.USUARIO_ALTA
FROM dbo.VCT_PROYECTOS_PLANES PL WHERE PL.ID_PROYECTO = @P;
SELECT I.GRUPO,
       CASE WHEN I.ID_PADRE IS NULL THEN 'raiz' WHEN P.GRUPO = 'CAPITULO' THEN 'item' ELSE 'subitem' END AS NIVEL,
       COUNT(*) AS N, SUM(CASE WHEN I.FECHA_INICIO IS NOT NULL THEN 1 ELSE 0 END) AS CON_INICIO,
       SUM(CASE WHEN I.FECHA_VENCIMIENTO IS NOT NULL THEN 1 ELSE 0 END) AS CON_FIN
FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID = I.ID_PLAN
LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P ON P.ID = I.ID_PADRE
WHERE PL.ID_PROYECTO = @P
GROUP BY I.GRUPO, CASE WHEN I.ID_PADRE IS NULL THEN 'raiz' WHEN P.GRUPO = 'CAPITULO' THEN 'item' ELSE 'subitem' END;
SELECT TOP 15 I.ID, I.ID_PADRE, I.CODIGO_ITEM, LEFT(I.TITULO, 60) AS TITULO, I.GRUPO, I.ORDEN, I.FECHA_INICIO, I.FECHA_VENCIMIENTO, I.ESTADO
FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID = I.ID_PLAN
WHERE PL.ID_PROYECTO = @P ORDER BY I.ORDEN, I.ID;
SELECT E.CODIGO AS ESTADO, COUNT(*) AS ACCIONES_DEL_PLAN,
       SUM(CASE WHEN A.FECHA_INICIO IS NULL THEN 1 ELSE 0 END) AS SIN_INICIO
FROM dbo.VCT_ACCIONES A LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID_PROYECTO = @P AND A.ID_PLAN_ITEM IS NOT NULL GROUP BY E.CODIGO;
SELECT A.ID, S.CODIGO AS SUBTIPO, E.CODIGO AS ESTADO, A.ID_PLAN, A.FECHA_VENCIMIENTO, A.FECHA_CIERRE
FROM dbo.VCT_ACCIONES A JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID_PROYECTO = @P AND S.CODIGO IN ('CARGA_PLAN');

PRINT '=== 6. registro de visitas actual (VISITA_GUARDAR) y modalidad de las visitas ===';
SELECT COUNT(*) AS FILAS, MIN(FECHA) AS DESDE, MAX(FECHA) AS HASTA, COUNT(DISTINCT ID_VISITA) AS VISITAS FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO;
SELECT ISNULL(OBSERVADOR, '(null)') AS MODALIDAD, COUNT(*) AS N FROM dbo.VCT_PROYECTOS_VISITAS GROUP BY OBSERVADOR ORDER BY N DESC;

PRINT '=== 7. calendario (dias habiles: fines de semana y feriados) ===';
SELECT TOP 3 * FROM dbo.Calendar WHERE Fecha >= CONVERT(DATE, GETDATE()) ORDER BY Fecha;
SELECT YEAR(Fecha) AS ANIO, COUNT(*) AS DIAS, SUM(CASE WHEN IsHoliday = 1 THEN 1 ELSE 0 END) AS FERIADOS FROM dbo.Calendar
WHERE Fecha BETWEEN '2026-01-01' AND '2028-12-31' GROUP BY YEAR(Fecha) ORDER BY 1;

PRINT '=== 8. objetos que usan el registro de visitas / historial de acciones ===';
SELECT o.type, o.name, LEN(m.definition) AS largo, CONVERT(VARCHAR(16), o.modify_date, 120) AS modificado
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%VCT_PROYECTOS_VISITAS_REGISTRO%' OR m.definition LIKE '%VCT_PROYECTO_AVANCE%' OR o.name LIKE 'VCT_PROYECTO_AVANCE%'
ORDER BY o.type, o.name;
PRINT '=== fin ===';
