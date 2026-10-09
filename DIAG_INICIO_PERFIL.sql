/* ========================================================================
   DIAG_INICIO_PERFIL (solo lectura) - correr con Query > SQLCMD Mode
   Para armar el Inicio por perfil sobre VCT_MAIN_DASHBOARD:
     1. definicion vigente de VCT_MAIN_DASHBOARD (linea por linea)
     2. tipo de ID_USUARIO_SEGURIDAD y vinculos usuario <-> consultor / empleado
     3. usuarios por perfil (activos) con su vinculo, para elegir con quien probar
     4. como se llama al Inicio (quien ejecuta VCT_MAIN_DASHBOARD)
   ======================================================================== */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_INICIO_PERFIL.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== 1. VCT_MAIN_DASHBOARD ===';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @p INT = 1, @e INT, @k INT = 0;
SET @D = REPLACE(@D, NCHAR(13), N'');
WHILE @D IS NOT NULL AND @p <= LEN(@D)
BEGIN
    SET @k = @k + 1;
    SET @e = CHARINDEX(NCHAR(10), @D, @p); IF @e = 0 SET @e = LEN(@D) + 1;
    PRINT RIGHT('0000' + CONVERT(VARCHAR(5), @k), 4) + ': ' + LEFT(SUBSTRING(@D, @p, @e - @p), 3900);
    SET @p = @e + 1;
END;
GO

PRINT '=== 2. columnas de vinculo ===';
SELECT OBJECT_NAME(c.object_id) AS TABLA, c.name AS COLUMNA, TYPE_NAME(c.user_type_id) AS TIPO, c.max_length AS LARGO
FROM sys.columns c
WHERE c.object_id IN (OBJECT_ID('dbo.VCT_CONSULTORES'), OBJECT_ID('dbo.VCT_EMPLEADOS'), OBJECT_ID('dbo.Users'))
  AND (c.name LIKE '%USUARIO%' OR c.name LIKE '%USER%' OR c.name IN ('Id','Name','State','Email','ESTADO','EMAIL'));
GO

PRINT '=== 2b. consultores y empleados con usuario cargado ===';
EXEC (N'SELECT ''CONSULTOR'' AS TIPO, ID, APELLIDOS, NOMBRES, ESTADO, CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD) AS USUARIO
        FROM dbo.VCT_CONSULTORES WHERE NULLIF(LTRIM(RTRIM(CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD))), N'''') IS NOT NULL
          AND CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD) <> N''0''
        UNION ALL
        SELECT ''EMPLEADO'', ID, APELLIDOS, NOMBRES, ESTADO, CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD)
        FROM dbo.VCT_EMPLEADOS WHERE NULLIF(LTRIM(RTRIM(CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD))), N'''') IS NOT NULL
          AND CONVERT(NVARCHAR(100), ID_USUARIO_SEGURIDAD) <> N''0''
        ORDER BY 1, 3');
GO

PRINT '=== 3. usuarios por perfil (State) ===';
SELECT GM.GroupId AS PERFIL, U.Id AS USUARIO, U.Name AS NOMBRE, U.State AS ESTADO,
       CASE WHEN EXISTS (SELECT 1 FROM dbo.UsersSector S WHERE S.Id_User = U.Id) THEN 'SI' ELSE 'NO' END AS TIENE_SECTOR
FROM dbo.GroupsUserMembers GM
JOIN dbo.Users U ON U.Id = GM.UserMemberId
ORDER BY GM.GroupId, U.Id;
GO

PRINT '=== 5. SP de la pestania Acciones (ACTION=PLANIFICACION) ===';
SELECT O.name, O.modify_date, LEN(M.definition) AS LARGO
FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE O.type = 'P' AND (O.name LIKE 'VCT_MAIN_PLANIF%' OR O.name LIKE 'VCT_MAIN_ACCION%' OR O.name LIKE 'VCT_MAIN_TAREA%' OR O.name = 'VCT_MAIN');
DECLARE @N2 SYSNAME = (SELECT TOP 1 name FROM sys.objects WHERE type = 'P' AND name LIKE 'VCT_MAIN_PLANIF%' ORDER BY LEN(name));
DECLARE @D2 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @N2)), @p2 INT = 1, @e2 INT, @k2 INT = 0;
PRINT '--- definicion de ' + ISNULL(@N2, '(no encontrado)');
SET @D2 = REPLACE(@D2, NCHAR(13), N'');
WHILE @D2 IS NOT NULL AND @p2 <= LEN(@D2)
BEGIN
    SET @k2 = @k2 + 1;
    SET @e2 = CHARINDEX(NCHAR(10), @D2, @p2); IF @e2 = 0 SET @e2 = LEN(@D2) + 1;
    PRINT RIGHT('0000' + CONVERT(VARCHAR(5), @k2), 4) + ': ' + LEFT(SUBSTRING(@D2, @p2, @e2 - @p2), 3900);
    SET @p2 = @e2 + 1;
END;
/* ruteo: lineas del despachador que mencionan PLANIFICACION / INICIO */
SELECT O.name, O.type_desc
FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%''PLANIFICACION''%' AND O.type = 'P';
GO

PRINT '=== 4. quien llama a VCT_MAIN_DASHBOARD ===';
SELECT O.type_desc, O.name, O.modify_date
FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%VCT_MAIN_DASHBOARD%' AND O.name <> 'VCT_MAIN_DASHBOARD';
GO
