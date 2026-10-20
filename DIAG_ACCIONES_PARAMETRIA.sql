/* ========================================================================
   DIAG_ACCIONES_PARAMETRIA  (solo lectura: no modifica nada)
   ------------------------------------------------------------------------
   Para definir el set de tipos / subtipos / resultados de acciones y
   separar la pestana Acciones por origen. Pasar TODAS las grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. columnas de VCT_ACCIONES y de toda la parametria de acciones */
SELECT C.TABLE_NAME, C.ORDINAL_POSITION, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH AS LARGO, C.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS C
WHERE C.TABLE_SCHEMA = 'dbo' AND (C.TABLE_NAME = 'VCT_ACCIONES' OR C.TABLE_NAME LIKE 'VCT_PRM_ACCIONES%')
ORDER BY C.TABLE_NAME, C.ORDINAL_POSITION;

/* 2. FKs y CHECKs de esas tablas */
SELECT OBJECT_NAME(F.parent_object_id) AS TABLA, F.name AS FK, COL_NAME(FC.parent_object_id, FC.parent_column_id) AS COLUMNA,
       OBJECT_NAME(F.referenced_object_id) AS REFERENCIA, COL_NAME(FC.referenced_object_id, FC.referenced_column_id) AS COL_REF
FROM sys.foreign_keys F INNER JOIN sys.foreign_key_columns FC ON FC.constraint_object_id = F.object_id
WHERE OBJECT_NAME(F.parent_object_id) = 'VCT_ACCIONES' OR OBJECT_NAME(F.parent_object_id) LIKE 'VCT_PRM_ACCIONES%'
   OR OBJECT_NAME(F.referenced_object_id) LIKE 'VCT_PRM_ACCIONES%'
ORDER BY 1, 2;
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name AS RESTRICCION, [definition] AS DEFINICION
FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) = 'VCT_ACCIONES' OR OBJECT_NAME(parent_object_id) LIKE 'VCT_PRM_ACCIONES%';

/* 3. contenido completo de cada tabla de parametria de acciones */
DECLARE @T SYSNAME, @SQL NVARCHAR(MAX);
DECLARE C CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.tables WHERE name LIKE 'VCT_PRM_ACCIONES%' ORDER BY name;
OPEN C; FETCH NEXT FROM C INTO @T;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'SELECT ''' + @T + N''' AS TABLA, * FROM dbo.' + QUOTENAME(@T) + N' ORDER BY 2;';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM C INTO @T;
END
CLOSE C; DEALLOCATE C;

/* 4. uso real: acciones por tipo / subtipo / resultado / estado */
SELECT T.CODIGO AS TIPO, ST.CODIGO AS SUBTIPO, R.CODIGO AS RESULTADO, E.CODIGO AS ESTADO,
       COUNT(*) AS CANT,
       SUM(CASE WHEN A.ID_PLAN_ITEM IS NOT NULL THEN 1 ELSE 0 END) AS EN_PLAN,
       SUM(CASE WHEN A.ID_PROYECTO IS NOT NULL THEN 1 ELSE 0 END) AS CON_PROYECTO
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) ON T.ID = A.ID_TIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_RESULTADOS R WITH(NOLOCK) ON R.ID = A.ID_RESULTADO
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
GROUP BY T.CODIGO, ST.CODIGO, R.CODIGO, E.CODIGO
ORDER BY T.CODIGO, ST.CODIGO, R.CODIGO, E.CODIGO;

/* 5. acciones del proyecto 1348 (el de la captura), con todas sus columnas */
SELECT A.*
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
WHERE P.CODIGO = '1348'
ORDER BY A.ID;

/* 6. responsables de esas acciones */
SELECT AP.ID_ACCION, AP.ROL_PARTICIPANTE, AP.TIPO_ENTIDAD, AP.ID_ENTIDAD, AP.PRINCIPAL, AP.ESTADO, AP.NOMBRE_LIBRE
FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
INNER JOIN dbo.VCT_ACCIONES A WITH(NOLOCK) ON A.ID = AP.ID_ACCION
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
WHERE P.CODIGO = '1348'
ORDER BY AP.ID_ACCION, AP.ID;

/* 7. SPs que referencian codigos de subtipo / resultado (para no romper el workflow al limpiar) */
SELECT DISTINCT O.name AS SP, S.CODIGO AS SUBTIPO_REFERENCIADO
FROM sys.sql_modules M
INNER JOIN sys.objects O ON O.object_id = M.object_id AND O.type = 'P'
CROSS JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S
WHERE M.[definition] LIKE '%''' + S.CODIGO + '''%'
ORDER BY 1, 2;
SELECT DISTINCT O.name AS SP, R.CODIGO AS RESULTADO_REFERENCIADO
FROM sys.sql_modules M
INNER JOIN sys.objects O ON O.object_id = M.object_id AND O.type = 'P'
CROSS JOIN dbo.VCT_PRM_ACCIONES_RESULTADOS R
WHERE M.[definition] LIKE '%''' + R.CODIGO + '''%'
ORDER BY 1, 2;
