/* ========================================================================
   DIAG_PERMISOS_4 - SOLO LECTURA. No modifica nada.
   A) Permisos efectivos por usuario (perfil, menues, acciones, Rentabilidad).
   B) Que tablas guardan asociaciones por perfil (columna tipo GroupId/Unidad)
      y cuantas filas tiene cada perfil: sirve para encontrar que le falta a
      SQUAD (EDEMARCO entra y ve "Advertencia - Pagina Activity - No posee
      permisos sobre la actividad").
   Uso: ejecutar y copiar TODA la columna "linea" de la pestana Results.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

/* ---------------- A. PERMISOS EFECTIVOS POR USUARIO ---------------- */
INSERT #O(linea) VALUES (N'=== A. EFECTIVO POR USUARIO: usuario | estado | perfil | menues | acciones | Rentabilidad ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),U.Id)+N' | state='+CONVERT(NVARCHAR(10),U.State)
      +N' | '+ISNULL(CONVERT(NVARCHAR(100),M.GroupId),N'(sin perfil)')
      +N' | menues='+ISNULL(STUFF((SELECT N',' + CONVERT(NVARCHAR(20),B.SideBarId)
                                   FROM dbo.SideBarGroups B
                                   WHERE UPPER(LTRIM(RTRIM(B.GroupId)))=UPPER(LTRIM(RTRIM(M.GroupId)))
                                   ORDER BY B.SideBarId
                                   FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,N''),N'-')
      +N' | acciones='+CONVERT(NVARCHAR(10),(SELECT COUNT(*) FROM dbo.GroupsActions A WHERE UPPER(LTRIM(RTRIM(A.GroupId)))=UPPER(LTRIM(RTRIM(M.GroupId)))))
      +N' | rentabilidad='+CASE WHEN M.GroupId IS NOT NULL AND dbo.VCT_PERFIL_PUEDE(CONVERT(VARCHAR(100),M.GroupId),'RENTABILIDAD.VIEW')=1 THEN N'SI' ELSE N'no' END
FROM dbo.Users U
LEFT JOIN dbo.GroupsUserMembers M ON UPPER(LTRIM(RTRIM(M.UserMemberId)))=UPPER(LTRIM(RTRIM(U.Id)))
ORDER BY M.GroupId,U.Id;

/* ---------------- B. TABLAS CON ASOCIACIONES POR PERFIL ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== B. Tablas con columna de perfil y filas por perfil (GERENCIA / SQUAD / PROYECTOS / ADMINISTRACION / CLIENTES / CONSULTORES / TEST) ===');

DECLARE @tab SYSNAME, @col SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name, c.name
    FROM sys.tables t
    INNER JOIN sys.columns c ON c.object_id=t.object_id
    INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
    WHERE (c.name LIKE N'%GROUP%' OR c.name LIKE N'%UNIDAD%' OR c.name LIKE N'%PERFIL%')
      AND ty.name IN (N'varchar',N'nvarchar',N'char',N'nchar')
      AND t.name NOT IN (N'M_AUDITORIA_ADMIN')
    ORDER BY t.name,c.name;
OPEN cur;
FETCH NEXT FROM cur INTO @tab,@col;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @sql = N'INSERT #O(linea) SELECT N''' + @tab + N'.' + @col + N' | ''' +
               N' + STUFF((SELECT N'', '' + g + N''='' + CONVERT(NVARCHAR(20),n) FROM (SELECT UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) AS g, COUNT(*) AS n FROM dbo.' + QUOTENAME(@tab) +
               N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) IN (N''GERENCIA'',N''SQUAD'',N''PROYECTOS'',N''ADMINISTRACION'',N''CLIENTES'',N''CONSULTORES'',N''TEST'') GROUP BY UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) ) X ORDER BY g FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)''),1,2,N'''')' +
               N' WHERE EXISTS (SELECT 1 FROM dbo.' + QUOTENAME(@tab) + N' WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100),' + QUOTENAME(@col) + N')))) IN (N''GERENCIA'',N''SQUAD'',N''PROYECTOS'',N''ADMINISTRACION'',N''CLIENTES'',N''CONSULTORES'',N''TEST''))';
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
