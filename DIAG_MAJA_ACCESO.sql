/* ========================================================================
   DIAG_MAJA_ACCESO  (solo lectura, no modifica nada)
   maja entra al sitio pero la actividad VCT_GESTION responde "No posee
   permisos sobre la actividad"; avocaturo entra bien. Ya se descarto el
   perfil (GroupsActions / SideBarGroups / tablas por perfil), asi que se
   compara POR USUARIO. Pegar TODAS las grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. Perfil actual y fila completa del usuario */
SELECT M.* FROM dbo.GroupsUserMembers M
WHERE UPPER(LTRIM(RTRIM(M.UserMemberId))) IN ('MAJA','EDEMARCO','AVOCATURO');
SELECT * FROM dbo.Users WHERE UPPER(Id) IN ('MAJA','EDEMARCO','AVOCATURO');
GO

/* 2. Tablas (hasta 50.000 filas) con una columna de usuario donde
      avocaturo tiene filas y maja no */
IF OBJECT_ID('tempdb..#U') IS NOT NULL DROP TABLE #U;
CREATE TABLE #U (TABLA SYSNAME, COLUMNA SYSNAME, AVOCATURO INT, MAJA INT, EDEMARCO INT, FILAS BIGINT);

DECLARE @tab SYSNAME, @col SYSNAME, @rows BIGINT, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name, c.name, SUM(p.rows)
    FROM sys.tables t
    JOIN sys.columns c ON c.object_id = t.object_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    JOIN sys.types bt ON bt.user_type_id = ty.system_type_id
    JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
    WHERE (c.name LIKE '%USER%' OR c.name LIKE '%AGENT%' OR c.name LIKE '%MEMBER%' OR c.name LIKE '%LOGIN%'
           OR c.name LIKE '%USUARIO%' OR c.name LIKE '%OPERADOR%' OR c.name = 'Id')
      AND bt.name IN ('varchar','nvarchar','char','nchar')
    GROUP BY t.name, c.name
    HAVING SUM(p.rows) BETWEEN 1 AND 50000;
OPEN cur;
FETCH NEXT FROM cur INTO @tab, @col, @rows;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #U SELECT ''' + @tab + N''', ''' + @col + N''','
             + N' SUM(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''AVOCATURO'' THEN 1 ELSE 0 END),'
             + N' SUM(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''MAJA'' THEN 1 ELSE 0 END),'
             + N' SUM(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''EDEMARCO'' THEN 1 ELSE 0 END), '
             + CONVERT(NVARCHAR(30), @rows)
             + N' FROM dbo.' + QUOTENAME(@tab) + N';';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;
    FETCH NEXT FROM cur INTO @tab, @col, @rows;
END;
CLOSE cur; DEALLOCATE cur;

SELECT * FROM #U WHERE AVOCATURO > 0 AND MAJA = 0 ORDER BY TABLA, COLUMNA;
GO

/* 3. Las filas de avocaturo en esas tablas (lo que le falta a maja) */
DECLARE @tab SYSNAME, @col SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
    SELECT TABLA, COLUMNA FROM #U WHERE AVOCATURO > 0 AND MAJA = 0 AND AVOCATURO <= 100;
OPEN cur2;
FETCH NEXT FROM cur2 INTO @tab, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP 30 ''' + @tab + N''' AS _TABLA, * FROM dbo.' + QUOTENAME(@tab)
             + N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''AVOCATURO'';';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;
    FETCH NEXT FROM cur2 INTO @tab, @col;
END;
CLOSE cur2; DEALLOCATE cur2;
GO

/* 4. Sectores de los tres usuarios */
IF OBJECT_ID('dbo.UsersSector') IS NOT NULL
    EXEC (N'SELECT * FROM dbo.UsersSector');
GO
