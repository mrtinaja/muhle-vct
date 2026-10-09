/* ========================================================================
   DIAG_PLAN_ESTRATEGICO  (solo lectura, no modifica nada)
   Que existe hoy en la base para armar el Plan Estrategico:
   tablas de planes / items / requisitos de normas, como se enganchan
   las gestiones y que datos de prueba hay. Pegar TODAS las grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* Cada bloque va separado por GO: si uno falla, los demas corren igual. */

/* 1. Tablas candidatas con su cantidad de filas */
SELECT T.name AS TABLA, SUM(P.rows) AS FILAS
FROM sys.tables T
JOIN sys.partitions P ON P.object_id = T.object_id AND P.index_id IN (0,1)
WHERE T.name LIKE '%PLAN%' OR T.name LIKE '%REQUISIT%' OR T.name LIKE '%NORMA%'
   OR T.name LIKE '%ITEM%' OR T.name LIKE '%GESTION%'
GROUP BY T.name
ORDER BY T.name;

GO
/* 2. Columnas de esas tablas */
SELECT T.name AS TABLA, C.column_id AS N, C.name AS COLUMNA, TY.name AS TIPO,
       C.max_length AS LARGO, C.is_nullable AS NULO
FROM sys.tables T
JOIN sys.columns C ON C.object_id = T.object_id
JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE T.name LIKE '%PLAN%' OR T.name LIKE '%REQUISIT%' OR T.name LIKE '%NORMA%'
   OR T.name LIKE '%ITEM%' OR T.name = 'VCT_GESTIONES'
ORDER BY T.name, C.column_id;

GO
/* 3. Claves foraneas entre ellas */
SELECT OBJECT_NAME(FK.parent_object_id) AS TABLA, COL_NAME(FC.parent_object_id, FC.parent_column_id) AS COLUMNA,
       OBJECT_NAME(FK.referenced_object_id) AS REFERENCIA, COL_NAME(FC.referenced_object_id, FC.referenced_column_id) AS COL_REF
FROM sys.foreign_keys FK
JOIN sys.foreign_key_columns FC ON FC.constraint_object_id = FK.object_id
WHERE OBJECT_NAME(FK.parent_object_id) LIKE '%PLAN%' OR OBJECT_NAME(FK.parent_object_id) LIKE '%REQUISIT%'
   OR OBJECT_NAME(FK.parent_object_id) LIKE '%NORMA%' OR OBJECT_NAME(FK.parent_object_id) = 'VCT_GESTIONES'
ORDER BY 1, 2;

GO
/* 4. SPs / funciones / vistas que mencionan planes o requisitos */
SELECT O.type_desc AS TIPO, O.name AS OBJETO, O.modify_date AS MODIFICADO
FROM sys.objects O
JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%PLAN_ITEMS%' OR M.definition LIKE '%PROYECTOS_PLANES%'
   OR M.definition LIKE '%REQUISITO%'
ORDER BY O.type_desc, O.name;

GO
/* 5. Muestras (primeras filas) de las tablas de plan / requisitos que existan */
DECLARE @t SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.tables
    WHERE name LIKE '%PLAN%' OR name LIKE '%REQUISIT%' OR name LIKE 'VCT_PRM_NORMA%'
    ORDER BY name;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP 8 ''' + @t + N''' AS _TABLA, * FROM dbo.' + QUOTENAME(@t) + N';';
    EXEC sp_executesql @sql;
    FETCH NEXT FROM cur INTO @t;
END;
CLOSE cur; DEALLOCATE cur;

GO
/* 6. Parametria de gestiones: tipos, subtipos, estados, reglas */
SELECT 'TIPO' AS QUE, ID, CODIGO, DESCRIPCION FROM dbo.VCT_PRM_GESTIONES_TIPOS
UNION ALL SELECT 'SUBTIPO', ID, CODIGO, DESCRIPCION FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS
UNION ALL SELECT 'ESTADO', ID, CODIGO, DESCRIPCION FROM dbo.VCT_PRM_GESTIONES_ESTADOS
ORDER BY 1, 2;

IF OBJECT_ID('dbo.VCT_PRM_GESTIONES_REGLAS') IS NOT NULL
    EXEC (N'SELECT * FROM dbo.VCT_PRM_GESTIONES_REGLAS');

GO
/* 7. El proyecto de prueba 1341: normas, servicio, gestiones */
SELECT 'NORMA' AS QUE, PN.*, N.*
FROM dbo.VCT_PROYECTOS_NORMAS PN
LEFT JOIN dbo.VCT_PRM_NORMAS N ON N.ID = PN.ID_NORMA
WHERE PN.ID_PROYECTO = 1341;

SELECT G.*
FROM dbo.VCT_GESTIONES G
WHERE G.ID_PROYECTO = 1341;
GO
