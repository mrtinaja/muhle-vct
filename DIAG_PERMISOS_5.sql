/* ========================================================================
   DIAG_PERMISOS_5 - SOLO LECTURA. No modifica nada.
   El diagnostico 4 (parte B) no mostro las tablas de permisos porque sus
   columnas de perfil son de un tipo definido por el sistema (alias, ej.
   "Code") y las ignore. Esta version:
     1. lista las tablas cuyo NOMBRE sugiere permisos / menues / actividades
     2. cuenta filas por perfil en TODA tabla con columna de perfil, incluso
        de tipo alias, y marca las que tienen filas de GERENCIA pero ninguna
        de SQUAD (lo que le falta a SQUAD para entrar).
   Uso: ejecutar y copiar TODA la columna "linea" de la pestana Results.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

/* ---------------- 1. TABLAS POR NOMBRE ---------------- */
INSERT #O(linea) VALUES (N'=== 1. TABLAS cuyo nombre sugiere permisos/menues/actividades ===');
INSERT #O(linea)
SELECT t.name+N' ('+CONVERT(NVARCHAR(20),(SELECT SUM(p.rows) FROM sys.partitions p WHERE p.object_id=t.object_id AND p.index_id IN (0,1)))+N' filas)'
FROM sys.tables t
WHERE t.name LIKE N'%GROUP%' OR t.name LIKE N'%TASK%' OR t.name LIKE N'%ACTIV%' OR t.name LIKE N'%SIDEBAR%'
   OR t.name LIKE N'%PERFIL%' OR t.name LIKE N'%PERMIS%' OR t.name LIKE N'%ACTION%' OR t.name LIKE N'%FORM%'
ORDER BY t.name;

/* ---------------- 2. FILAS POR PERFIL (incluye tipos alias) ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 2. Filas por perfil: tabla.columna | perfil=filas ... | (marca si GERENCIA tiene y SQUAD no) ===');

DECLARE @tab SYSNAME, @col SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name, c.name
    FROM sys.tables t
    INNER JOIN sys.columns c ON c.object_id=t.object_id
    INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
    INNER JOIN sys.types bt ON bt.user_type_id=ty.system_type_id
    WHERE (c.name LIKE N'%GROUP%' OR c.name LIKE N'%UNIDAD%' OR c.name LIKE N'%PERFIL%')
      AND bt.name IN (N'varchar',N'nvarchar',N'char',N'nchar')
      AND t.name NOT LIKE N'DSS[_]%' AND t.name NOT LIKE N'ATTENDED%' AND t.name NOT LIKE N'PHYSICAL%'
      AND t.name NOT LIKE N'M[_]CONFIG%' AND t.name NOT LIKE N'M[_]AUDITORIA%'
    ORDER BY t.name,c.name;
OPEN cur;
FETCH NEXT FROM cur INTO @tab,@col;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @sql = N'INSERT #O(linea) SELECT N''' + @tab + N'.' + @col + N' | '' + ISNULL(STUFF((SELECT N'', '' + g + N''='' + CONVERT(NVARCHAR(20),n) FROM (SELECT UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) AS g, COUNT(*) AS n FROM dbo.' + QUOTENAME(@tab) +
               N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) IN (N''GERENCIA'',N''SQUAD'',N''PROYECTOS'',N''ADMINISTRACION'',N''CLIENTES'',N''CONSULTORES'',N''TEST'') GROUP BY UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) ) X ORDER BY g FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)''),1,2,N''''),N''(sin filas de estos perfiles)'')' +
               N' + CASE WHEN EXISTS (SELECT 1 FROM dbo.' + QUOTENAME(@tab) + N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N'))))=N''GERENCIA'')' +
               N' AND NOT EXISTS (SELECT 1 FROM dbo.' + QUOTENAME(@tab) + N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N'))))=N''SQUAD'') THEN N''   <<< FALTA SQUAD'' ELSE N'''' END';
    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        INSERT #O(linea) VALUES (@tab + N'.' + @col + N' | (no se pudo leer: ' + ERROR_MESSAGE() + N')');
    END CATCH;
    FETCH NEXT FROM cur INTO @tab,@col;
END;
CLOSE cur;
DEALLOCATE cur;

DECLARE @nFilas INT=(SELECT COUNT(*) FROM #O);
PRINT N'Filas generadas: '+CONVERT(NVARCHAR(10),@nFilas)+N'. Copiar la columna "linea" de la pestana Results.';

SELECT linea FROM #O ORDER BY id;
GO
