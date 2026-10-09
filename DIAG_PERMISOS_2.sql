/* ========================================================================
   DIAG_PERMISOS_2 - SOLO LECTURA. No modifica nada.
   Completa DIAG_PERMISOS: quienes son los usuarios por perfil, a que perfil
   pertenecen los 5 usuarios con Rentabilidad escrita a mano, que SP arma el
   Inicio de MAIN y que columnas tiene Users (para vincular usuario <->
   consultor por email, sin leer datos sensibles).
   Uso: ejecutar y copiar TODA la columna "linea" (Ctrl+A, Ctrl+C).
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

INSERT #O(linea) VALUES (N'=== A. Los 5 usuarios con Rentabilidad escrita a mano: usuario | perfil ===');
INSERT #O(linea)
SELECT V.u+N' | '+ISNULL((SELECT TOP 1 CONVERT(NVARCHAR(100),M.GroupId) FROM dbo.GroupsUserMembers M WHERE LOWER(LTRIM(RTRIM(M.UserMemberId)))=V.u),N'(sin perfil / no existe)')
FROM (VALUES (N'avocaturo'),(N'svocaturo'),(N'jjvocaturo'),(N'cbielsa'),(N'mbolivieri')) V(u);

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== B. Usuarios de los perfiles que NO son PROYECTOS: perfil | usuario | nombre ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),M.GroupId)+N' | '+CONVERT(NVARCHAR(100),M.UserMemberId)+N' | '+ISNULL((SELECT TOP 1 CONVERT(NVARCHAR(200),U.Name) FROM dbo.Users U WHERE U.Id=M.UserMemberId),N'')
FROM dbo.GroupsUserMembers M
WHERE UPPER(LTRIM(RTRIM(M.GroupId)))<>N'PROYECTOS'
ORDER BY M.GroupId,M.UserMemberId;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== C. Los 36 usuarios del perfil PROYECTOS: usuario | nombre ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),M.UserMemberId)+N' | '+ISNULL((SELECT TOP 1 CONVERT(NVARCHAR(200),U.Name) FROM dbo.Users U WHERE U.Id=M.UserMemberId),N'')
FROM dbo.GroupsUserMembers M
WHERE UPPER(LTRIM(RTRIM(M.GroupId)))=N'PROYECTOS'
ORDER BY M.UserMemberId;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== D. Columnas de la tabla Users (solo nombres) ===');
INSERT #O(linea)
SELECT c.name+N' ('+ty.name+N')'
FROM sys.columns c
INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE c.object_id=OBJECT_ID('dbo.Users')
ORDER BY c.column_id;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== E. SPs/vistas que arman el Inicio de MAIN (texto "Proyectos vigentes" o "Clientes activos") ===');
INSERT #O(linea)
SELECT OBJECT_SCHEMA_NAME(m.object_id)+N'.'+o.name+N' ('+o.type_desc+N')'
FROM sys.sql_modules m
INNER JOIN sys.objects o ON o.object_id=m.object_id
WHERE m.definition LIKE N'%Proyectos vigentes%' OR m.definition LIKE N'%Clientes activos%'
ORDER BY o.name;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== F. Menues asignados a perfiles que no existen en SideBar (ids huerfanos): perfil | SideBarId ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),B.GroupId)+N' | '+CONVERT(NVARCHAR(20),B.SideBarId)
FROM dbo.SideBarGroups B
WHERE NOT EXISTS (SELECT 1 FROM dbo.SideBar S WHERE S.Id=B.SideBarId)
ORDER BY B.GroupId,B.SideBarId;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== G. Consultores con email cargado vs total (para cruzar usuario <-> consultor por email) ===');
IF COL_LENGTH('dbo.VCT_EMAILS','TIPO_ENTIDAD') IS NOT NULL AND COL_LENGTH('dbo.VCT_EMAILS','ID_ENTIDAD') IS NOT NULL
    EXEC(N'INSERT #O(linea) SELECT N''consultores total=''+CONVERT(NVARCHAR(20),(SELECT COUNT(*) FROM dbo.VCT_CONSULTORES))+N'' con al menos un email=''+CONVERT(NVARCHAR(20),(SELECT COUNT(DISTINCT E.ID_ENTIDAD) FROM dbo.VCT_EMAILS E WHERE E.TIPO_ENTIDAD=N''CONSULTOR'' AND EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES C WHERE C.ID=E.ID_ENTIDAD)))');
ELSE
    INSERT #O(linea) VALUES (N'(VCT_EMAILS no usa TIPO_ENTIDAD/ID_ENTIDAD: revisar a mano)');

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== H. Empleados (VCT_EMPLEADOS): estado | apellido, nombres | usuario de seguridad ===');
DECLARE @eN NVARCHAR(300)=N'N''''', @eA NVARCHAR(300)=N'N''''', @eS NVARCHAR(300)=N'N''''', @eU NVARCHAR(300)=N'N''''', @sqlE NVARCHAR(MAX);
IF COL_LENGTH('dbo.VCT_EMPLEADOS','NOMBRES') IS NOT NULL SET @eN=N'ISNULL(CONVERT(NVARCHAR(150),E.NOMBRES),N'''')';
ELSE IF COL_LENGTH('dbo.VCT_EMPLEADOS','NOMBRE') IS NOT NULL SET @eN=N'ISNULL(CONVERT(NVARCHAR(150),E.NOMBRE),N'''')';
IF COL_LENGTH('dbo.VCT_EMPLEADOS','APELLIDOS') IS NOT NULL SET @eA=N'ISNULL(CONVERT(NVARCHAR(150),E.APELLIDOS),N'''')';
ELSE IF COL_LENGTH('dbo.VCT_EMPLEADOS','APELLIDO') IS NOT NULL SET @eA=N'ISNULL(CONVERT(NVARCHAR(150),E.APELLIDO),N'''')';
IF COL_LENGTH('dbo.VCT_EMPLEADOS','ESTADO') IS NOT NULL SET @eS=N'ISNULL(CONVERT(NVARCHAR(50),E.ESTADO),N'''')';
IF COL_LENGTH('dbo.VCT_EMPLEADOS','ID_USUARIO_SEGURIDAD') IS NOT NULL SET @eU=N'ISNULL(CONVERT(NVARCHAR(100),E.ID_USUARIO_SEGURIDAD),N'''')';
SET @sqlE=N'INSERT #O(linea) SELECT '+@eS+N'+N'' | ''+'+@eA+N'+N'', ''+'+@eN+N'+N'' | ''+'+@eU+N' FROM dbo.VCT_EMPLEADOS E ORDER BY '+@eS+N','+@eA;
EXEC(@sqlE);

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== I. Consultores por estado (cantidad) ===');
IF COL_LENGTH('dbo.VCT_CONSULTORES','ESTADO') IS NOT NULL
    EXEC(N'INSERT #O(linea) SELECT ISNULL(CONVERT(NVARCHAR(50),ESTADO),N''(sin estado)'')+N'': ''+CONVERT(NVARCHAR(20),COUNT(*)) FROM dbo.VCT_CONSULTORES GROUP BY ESTADO');

DECLARE @nFilas INT=(SELECT COUNT(*) FROM #O);
PRINT N'Filas generadas: '+CONVERT(NVARCHAR(10),@nFilas)+N'. Copiar la columna "linea" de la pestana Results.';

SELECT linea FROM #O ORDER BY id;
GO
