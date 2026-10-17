/* DIAG_ACCIONES_TIPIFICACION - solo lectura.
   Para armar el modal "Nueva accion del plan" con la tipificacion completa
   (tipo, subtipo, resultado, estado, prioridad, vencimiento) sobre el modelo existente.
   Pasar el resultado de todas las grillas. */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. columnas de acciones y de la parametria */
SELECT C.TABLE_NAME, C.ORDINAL_POSITION, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH AS LARGO, C.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_SCHEMA = 'dbo'
  AND (C.TABLE_NAME = 'VCT_ACCIONES' OR C.TABLE_NAME LIKE 'VCT_PRM_ACCIONES[_]%')
ORDER BY C.TABLE_NAME, C.ORDINAL_POSITION;

/* 2. claves foraneas y CHECK */
SELECT OBJECT_NAME(F.parent_object_id) AS TABLA, F.name AS FK, COL_NAME(FC.parent_object_id, FC.parent_column_id) AS COLUMNA,
       OBJECT_NAME(F.referenced_object_id) AS REFERENCIA, COL_NAME(FC.referenced_object_id, FC.referenced_column_id) AS COL_REF
FROM sys.foreign_keys F INNER JOIN sys.foreign_key_columns FC ON FC.constraint_object_id = F.object_id
WHERE OBJECT_NAME(F.parent_object_id) = 'VCT_ACCIONES' OR OBJECT_NAME(F.parent_object_id) LIKE 'VCT_PRM_ACCIONES[_]%'
ORDER BY 1, 2;
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name AS RESTRICCION, definition AS DEFINICION
FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) = 'VCT_ACCIONES' OR OBJECT_NAME(parent_object_id) LIKE 'VCT_PRM_ACCIONES[_]%';

/* 3. contenido de la parametria */
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_TIPOS') IS NOT NULL       SELECT 'TIPOS' AS T, * FROM dbo.VCT_PRM_ACCIONES_TIPOS ORDER BY 2;
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_SUBTIPOS') IS NOT NULL    SELECT 'SUBTIPOS' AS T, * FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS ORDER BY 2;
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_RESULTADOS') IS NOT NULL  SELECT 'RESULTADOS' AS T, * FROM dbo.VCT_PRM_ACCIONES_RESULTADOS ORDER BY 2;
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_ESTADOS') IS NOT NULL     SELECT 'ESTADOS' AS T, * FROM dbo.VCT_PRM_ACCIONES_ESTADOS ORDER BY 2;
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_PRIORIDADES') IS NOT NULL SELECT 'PRIORIDADES' AS T, * FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES ORDER BY 2;

/* 4. otras tablas de parametria de acciones (por si hay relaciones tipo-subtipo-resultado) */
SELECT name FROM sys.tables WHERE name LIKE 'VCT_PRM_ACCIONES%' OR name LIKE 'VCT_ACCIONES%' ORDER BY name;

/* 5. acciones ya cargadas en el plan del 1347 */
SELECT A.ID, A.TITULO, A.ID_TIPO, A.ID_SUBTIPO, A.ID_ESTADO, A.ID_PRIORIDAD, A.ID_PLAN_ITEM, A.FECHA_VENCIMIENTO
FROM dbo.VCT_ACCIONES A INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = A.ID_PROYECTO AND P.CODIGO = '1347'
WHERE A.ID_PLAN_ITEM IS NOT NULL;
