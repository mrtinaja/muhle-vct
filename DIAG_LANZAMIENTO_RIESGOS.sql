/* DIAG_LANZAMIENTO_RIESGOS - solo lectura (no modifica nada).
   Para definir "Riesgos" y "Reuniones" del lanzamiento sin suponer el modelo.
   Pasar el resultado de todas las grillas. */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. tablas o columnas que ya hablen de riesgo (para usar la existente si la hay) */
SELECT T.TABLE_NAME, T.TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES T
WHERE T.TABLE_SCHEMA = 'dbo' AND T.TABLE_NAME LIKE '%RIESGO%' AND T.TABLE_TYPE = 'BASE TABLE';
SELECT C.TABLE_NAME, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH AS LARGO, C.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS C INNER JOIN INFORMATION_SCHEMA.TABLES T ON T.TABLE_NAME = C.TABLE_NAME AND T.TABLE_SCHEMA = C.TABLE_SCHEMA AND T.TABLE_TYPE = 'BASE TABLE'
WHERE C.TABLE_SCHEMA = 'dbo' AND C.COLUMN_NAME LIKE '%RIESGO%'
ORDER BY C.TABLE_NAME, C.ORDINAL_POSITION;

/* 2. columnas de VCT_PROYECTOS_DATOS (donde se graban datos de entrada, consideraciones, reuniones e inicio) */
SELECT C.ORDINAL_POSITION, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH AS LARGO, C.IS_NULLABLE, C.COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_SCHEMA = 'dbo' AND C.TABLE_NAME = 'VCT_PROYECTOS_DATOS'
ORDER BY C.ORDINAL_POSITION;

/* 3. CHECK, claves unicas y triggers de VCT_PROYECTOS_DATOS y VCT_PROYECTOS */
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name, definition FROM sys.check_constraints
WHERE parent_object_id IN (OBJECT_ID('dbo.VCT_PROYECTOS_DATOS'), OBJECT_ID('dbo.VCT_PROYECTOS'));
SELECT OBJECT_NAME(I.object_id) AS TABLA, I.name AS INDICE, I.is_unique, I.has_filter, I.filter_definition,
       STUFF((SELECT ', ' + COL_NAME(IC.object_id, IC.column_id) FROM sys.index_columns IC
              WHERE IC.object_id = I.object_id AND IC.index_id = I.index_id ORDER BY IC.key_ordinal FOR XML PATH('')), 1, 2, '') AS COLUMNAS
FROM sys.indexes I
WHERE I.object_id = OBJECT_ID('dbo.VCT_PROYECTOS_DATOS') AND I.is_unique = 1;
SELECT OBJECT_NAME(parent_id) AS TABLA, name, is_disabled FROM sys.triggers
WHERE parent_id IN (OBJECT_ID('dbo.VCT_PROYECTOS_DATOS'), OBJECT_ID('dbo.VCT_PROYECTOS'));

/* 4. que hay grabado hoy por tipo (sin datos de clientes) */
SELECT TIPO, COUNT(*) AS FILAS, COUNT(DISTINCT ID_PROYECTO) AS PROYECTOS, MAX(LEN(NRO_INTERNO)) AS MAX_LARGO_NRO
FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK) GROUP BY TIPO ORDER BY TIPO;

/* 5. valores de riesgo usados hoy en proyectos */
SELECT ISNULL(NIVEL_RIESGO, '(NULL)') AS NIVEL_RIESGO, COUNT(*) AS PROYECTOS
FROM dbo.VCT_PROYECTOS WITH(NOLOCK) GROUP BY NIVEL_RIESGO ORDER BY 2 DESC;

/* 6. proyectos con mas de una reunion marcada como realizada (hoy solo una deberia ser la de lanzamiento) */
SELECT P.CODIGO, COUNT(*) AS REUNIONES_REALIZADAS
FROM dbo.VCT_PROYECTOS_DATOS D WITH(NOLOCK) INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = D.ID_PROYECTO
WHERE D.TIPO = 'LANZ' AND D.FECHA_CIERRE IS NOT NULL
GROUP BY P.CODIGO HAVING COUNT(*) > 1;
