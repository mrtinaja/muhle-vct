/* ========================================================================
   DIAG_DASHBOARD - SOLO LECTURA. No modifica nada.
   Junta lo necesario para armar el Inicio (dashboard) segun perfil:
     1. Objetos creados/modificados desde el 06/10 (lo que se armo del
        tercer nivel: funciones, vistas, SP)
     2. Acciones de dashboard / alcance / inicio y que perfiles las tienen
     3. Acciones por perfil (matriz completa)
     4. Vinculos usuario <-> consultor / empleado cargados
     5. Definicion completa de las funciones y vistas nuevas (paso 1)
     6. Definicion completa de dbo.VCT_MAIN_DASHBOARD
   Uso: ejecutar (F5), ir a Results, clic en la columna "linea",
        Ctrl+A, Ctrl+C y pegarlo en el chat (o guardarlo en un .txt).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

DECLARE @DESDE DATETIME = '2026-10-06';

/* ---------------- 1. OBJETOS NUEVOS / MODIFICADOS ---------------- */
INSERT #O(linea) VALUES (N'=== 1. OBJETOS creados/modificados desde el 06/10 ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(16),o.modify_date,120)+N' | '+o.type_desc+N' | '+SCHEMA_NAME(o.schema_id)+N'.'+o.name
     +CASE WHEN o.create_date>=@DESDE THEN N' (NUEVO)' ELSE N'' END
FROM sys.objects o
WHERE o.modify_date>=@DESDE AND o.is_ms_shipped=0 AND o.type IN ('P','FN','IF','TF','V','U','TR')
ORDER BY o.modify_date;

/* ---------------- 2. ACCIONES DE DASHBOARD / ALCANCE ---------------- */
INSERT #O(linea) VALUES (N''),(N'=== 2. ACCIONES dashboard / alcance / inicio y perfiles que las tienen ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),A.Id)+N' -> '
     +ISNULL(STUFF((SELECT N', '+CONVERT(NVARCHAR(100),GA.GroupId)
              FROM dbo.GroupsActions GA
              WHERE UPPER(LTRIM(RTRIM(GA.ActionId)))=UPPER(LTRIM(RTRIM(A.Id)))
              FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'(ningun perfil)')
FROM dbo.Actions A
WHERE A.Id LIKE 'DASHBOARD%' OR A.Id LIKE 'ALCANCE%' OR A.Id LIKE 'INICIO%' OR A.Id LIKE 'SCOPE%' OR A.Id LIKE '%.OWN' OR A.Id LIKE '%.ALL'
ORDER BY A.Id;

/* ---------------- 3. ACCIONES POR PERFIL ---------------- */
INSERT #O(linea) VALUES (N''),(N'=== 3. ACCIONES por perfil ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(100),G.Id)
     +N' | usuarios='+CONVERT(NVARCHAR(10),(SELECT COUNT(*) FROM dbo.GroupsUserMembers GU WHERE GU.GroupId=G.Id))
     +N' | '+ISNULL(STUFF((SELECT N', '+CONVERT(NVARCHAR(150),GA.ActionId)
                     FROM dbo.GroupsActions GA WHERE GA.GroupId=G.Id ORDER BY GA.ActionId
                     FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'(sin acciones)')
FROM dbo.Groups G
ORDER BY G.Id;

/* ---------------- 4. VINCULOS USUARIO <-> ENTIDAD ---------------- */
INSERT #O(linea) VALUES (N''),(N'=== 4. VINCULOS usuario <-> entidad cargados ===');
INSERT #O(linea)
SELECT N'consultores con usuario: '+CONVERT(NVARCHAR(10),COUNT(*))
FROM dbo.VCT_CONSULTORES WHERE ISNULL(CONVERT(NVARCHAR(100),ID_USUARIO_SEGURIDAD),N'') NOT IN (N'',N'0');
INSERT #O(linea)
SELECT N'empleados con usuario: '+CONVERT(NVARCHAR(10),COUNT(*))
FROM dbo.VCT_EMPLEADOS WHERE ISNULL(CONVERT(NVARCHAR(100),ID_USUARIO_SEGURIDAD),N'') NOT IN (N'',N'0');
INSERT #O(linea)
SELECT N'columnas de VCT_CLIENTES que parecen vinculo a usuario: '
     +ISNULL(STUFF((SELECT N', '+c.name
                    FROM sys.columns c
                    WHERE c.object_id=OBJECT_ID('dbo.VCT_CLIENTES') AND (c.name LIKE '%USUARIO%' OR c.name LIKE '%USER%')
                    FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'(ninguna)');

/* ---------------- 5 y 6. DEFINICIONES ---------------- */
DECLARE @OBJS TABLE (orden INT IDENTITY(1,1), nombre SYSNAME);
INSERT @OBJS(nombre)
SELECT SCHEMA_NAME(o.schema_id)+N'.'+o.name
FROM sys.objects o
WHERE o.modify_date>=@DESDE AND o.is_ms_shipped=0 AND o.type IN ('FN','IF','TF','V')
ORDER BY o.name;
IF OBJECT_ID('dbo.VCT_MAIN_DASHBOARD') IS NOT NULL INSERT @OBJS(nombre) VALUES (N'dbo.VCT_MAIN_DASHBOARD');

DECLARE @I INT = 1, @N INT = (SELECT COUNT(*) FROM @OBJS), @NAME SYSNAME, @D NVARCHAR(MAX),
        @TOTAL INT, @P INT, @E INT, @LINE NVARCHAR(MAX);
WHILE @I <= @N
BEGIN
    SELECT @NAME = nombre FROM @OBJS WHERE orden=@I;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));
    INSERT #O(linea) VALUES (N''),(N'=== DEFINICION: '+@NAME+N' ===');
    IF @D IS NULL
        INSERT #O(linea) VALUES (N'(sin definicion visible)');
    ELSE
    BEGIN
        SET @TOTAL = DATALENGTH(@D)/2; SET @P = 1;
        WHILE @P <= @TOTAL
        BEGIN
            SET @E = CHARINDEX(NCHAR(10), @D, @P);
            IF @E = 0 SET @E = @TOTAL + 1;
            SET @LINE = SUBSTRING(@D, @P, @E-@P);
            IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE,1) = NCHAR(13)
                SET @LINE = SUBSTRING(@LINE, 1, DATALENGTH(@LINE)/2 - 1);
            INSERT #O(linea) VALUES (@LINE);
            SET @P = @E + 1;
        END;
    END;
    SET @I += 1;
END;

SELECT linea FROM #O ORDER BY id;
