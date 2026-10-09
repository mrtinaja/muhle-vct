/* ========================================================================
   DIAG_SQUAD_ACCESO  (solo lectura, no modifica nada)
   maja / EDEMARCO (perfil SQUAD) ven "No posee permisos sobre la actividad"
   y GERENCIA entra bien. SQUAD ya tiene los mismos menus (SideBarGroups) y
   acciones (GroupsActions), asi que falta otra asociacion por perfil.
   Este script recorre las tablas CHICAS (de configuracion) que tienen una
   columna de perfil y muestra las que tienen filas de GERENCIA y ninguna de
   SQUAD, con esas filas. Pegar TODAS las grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. Usuarios: perfil y estado */
SELECT U.Id, U.Name, U.State, M.GroupId
FROM dbo.Users U
LEFT JOIN dbo.GroupsUserMembers M ON UPPER(LTRIM(RTRIM(M.UserMemberId))) = UPPER(LTRIM(RTRIM(U.Id)))
WHERE UPPER(U.Id) IN ('MAJA','EDEMARCO','AVOCATURO','JJVOCATURO');
GO

/* 2. Tablas de configuracion con filas de GERENCIA y ninguna de SQUAD */
IF OBJECT_ID('tempdb..#R') IS NOT NULL DROP TABLE #R;
CREATE TABLE #R (TABLA SYSNAME, COLUMNA SYSNAME, GERENCIA INT, SQUAD INT, FILAS BIGINT);

DECLARE @tab SYSNAME, @col SYSNAME, @rows BIGINT, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name, c.name, SUM(p.rows)
    FROM sys.tables t
    JOIN sys.columns c ON c.object_id = t.object_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    JOIN sys.types bt ON bt.user_type_id = ty.system_type_id
    JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
    WHERE (c.name LIKE '%GROUP%' OR c.name LIKE '%UNIDAD%' OR c.name LIKE '%PERFIL%' OR c.name LIKE '%ROLE%')
      AND bt.name IN ('varchar','nvarchar','char','nchar')
    GROUP BY t.name, c.name
    HAVING SUM(p.rows) BETWEEN 1 AND 20000;
OPEN cur;
FETCH NEXT FROM cur INTO @tab, @col, @rows;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #R SELECT ''' + @tab + N''', ''' + @col + N''','
             + N' SUM(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''GERENCIA'' THEN 1 ELSE 0 END),'
             + N' SUM(CASE WHEN UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''SQUAD'' THEN 1 ELSE 0 END), '
             + CONVERT(NVARCHAR(30), @rows)
             + N' FROM dbo.' + QUOTENAME(@tab) + N';';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;
    FETCH NEXT FROM cur INTO @tab, @col, @rows;
END;
CLOSE cur; DEALLOCATE cur;

SELECT * FROM #R WHERE GERENCIA > 0 AND SQUAD < GERENCIA ORDER BY SQUAD, TABLA;
GO

/* 3. Las filas de GERENCIA de esas tablas (lo que le falta a SQUAD) */
DECLARE @tab SYSNAME, @col SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
    SELECT TABLA, COLUMNA FROM #R WHERE GERENCIA > 0 AND SQUAD = 0 AND GERENCIA <= 200;
OPEN cur2;
FETCH NEXT FROM cur2 INTO @tab, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT TOP 50 ''' + @tab + N''' AS _TABLA, * FROM dbo.' + QUOTENAME(@tab)
             + N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200),' + QUOTENAME(@col) + N'))))=N''GERENCIA'';';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;
    FETCH NEXT FROM cur2 INTO @tab, @col;
END;
CLOSE cur2; DEALLOCATE cur2;
GO
