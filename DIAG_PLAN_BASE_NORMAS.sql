/* DIAG_PLAN_BASE_NORMAS - solo lectura (no modifica nada).
   Para redisenar la parametria del plan base por norma y el arbol capitulo > item > subitem > acciones,
   sin suponer el modelo. Pasar el resultado de todas las grillas. */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. columnas de las tablas de parametria, del plan del proyecto y de los participantes de acciones */
SELECT C.TABLE_NAME, C.ORDINAL_POSITION, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH AS LARGO, C.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_SCHEMA = 'dbo'
  AND C.TABLE_NAME IN ('VCT_PRM_DOCUMENTOS','VCT_PRM_DOCUMENTOS_ITEMS','VCT_PRM_NORMAS','VCT_PROYECTOS_PLANES',
                       'VCT_PROYECTOS_PLAN_ITEMS','VCT_ACCIONES_PARTICIPANTES','VCT_PROYECTOS_NORMAS')
ORDER BY C.TABLE_NAME, C.ORDINAL_POSITION;

/* 2. tablas que ya relacionen documentos (planes base) con normas */
SELECT T.TABLE_NAME FROM INFORMATION_SCHEMA.TABLES T
WHERE T.TABLE_SCHEMA = 'dbo' AND T.TABLE_TYPE = 'BASE TABLE'
  AND (T.TABLE_NAME LIKE 'VCT[_]PRM[_]DOCUMENTOS%' OR T.TABLE_NAME LIKE '%NORMA%');
SELECT OBJECT_NAME(F.parent_object_id) AS TABLA, F.name AS FK, COL_NAME(FC.parent_object_id, FC.parent_column_id) AS COLUMNA,
       OBJECT_NAME(F.referenced_object_id) AS REFERENCIA
FROM sys.foreign_keys F INNER JOIN sys.foreign_key_columns FC ON FC.constraint_object_id = F.object_id
WHERE F.parent_object_id IN (OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS'), OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_ITEMS'),
                             OBJECT_ID('dbo.VCT_PROYECTOS_PLAN_ITEMS'), OBJECT_ID('dbo.VCT_ACCIONES_PARTICIPANTES'))
ORDER BY 1, 2;

/* 3. normas de parametria */
SELECT * FROM dbo.VCT_PRM_NORMAS WITH(NOLOCK) ORDER BY ID;

/* 4. plan base RE-PP-007: estructura (niveles por ID_PADRE y codigos) */
SELECT I.ID, I.ID_PADRE, I.CODIGO_ITEM, LEFT(I.DESCRIPCION, 120) AS DESCRIPCION, I.GRUPO, I.ORDEN, I.OBLIGATORIO, I.ACTIVO
FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
INNER JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) ON D.ID = I.ID_DOCUMENTO AND D.CODIGO = 'RE-PP-007'
ORDER BY I.ORDEN, I.ID;

/* 5. como se cargan hoy los responsables de las acciones (tipos de entidad y roles) */
SELECT AP.TIPO_ENTIDAD, AP.ROL_PARTICIPANTE, COUNT(*) AS FILAS
FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
GROUP BY AP.TIPO_ENTIDAD, AP.ROL_PARTICIPANTE ORDER BY 1, 2;

/* 6. CHECK de participantes, items del plan y documentos (valores permitidos) */
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name, definition FROM sys.check_constraints
WHERE parent_object_id IN (OBJECT_ID('dbo.VCT_ACCIONES_PARTICIPANTES'), OBJECT_ID('dbo.VCT_PROYECTOS_PLAN_ITEMS'),
                           OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS'), OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_ITEMS'));
