/* ========================================================================
   DIAG_PERMISOS - SOLO LECTURA. No modifica nada.
   Junta en UNA sola grilla (columna "linea") el estado actual del modelo de
   permisos para poder disenar el tercer nivel:
     1. Perfiles (Groups), cantidad de usuarios y de acciones
     2. Matriz: acciones por perfil (GroupsActions)
     3. Desfasajes entre Actions / PrmActions / GroupsActions
     4. Menues por perfil (SideBar / SideBarGroups)
     5. Definicion de VCT_MAIN_GET_ACTIONS, VCT_USER_HAS_ACTION, VCT_USER_GET_ACTIONS
     6. Columnas que vinculan usuario <-> consultor/empleado/cliente/proveedor
     7. SPs con listas de usuarios escritas a mano (@IAGENTE IN (...))
   Uso: ejecutar y copiar TODA la columna "linea" (Ctrl+A en la grilla,
   Ctrl+C) y pegarla en el chat.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

/* ---------------- 1. PERFILES ---------------- */
INSERT #O(linea) VALUES (N'=== 1. PERFILES (Groups): Id | Name | usuarios | acciones ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),G.Id)+N' | '+ISNULL(CONVERT(NVARCHAR(200),G.Name),N'')
     +N' | usuarios='+CONVERT(NVARCHAR(20),(SELECT COUNT(*) FROM dbo.GroupsUserMembers M WHERE M.GroupId=G.Id))
     +N' | acciones='+CONVERT(NVARCHAR(20),(SELECT COUNT(*) FROM dbo.GroupsActions A WHERE A.GroupId=G.Id))
FROM dbo.Groups G
ORDER BY G.Id;

/* ---------------- 2. MATRIZ ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 2. MATRIZ: acciones por perfil (GroupsActions) ===');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),G.GroupId)+N': '+
       STUFF((SELECT N', '+CONVERT(NVARCHAR(200),A.ActionId)
              FROM dbo.GroupsActions A
              WHERE A.GroupId=G.GroupId
              ORDER BY A.ActionId
              FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N'')
FROM (SELECT DISTINCT GroupId FROM dbo.GroupsActions) G
ORDER BY G.GroupId;

/* ---------------- 3. DESFASAJES ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 3. DESFASAJES entre Actions / PrmActions / GroupsActions ===');
INSERT #O(linea) VALUES (N'-- Total Actions / PrmActions / GroupsActions(distintas):');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(20),(SELECT COUNT(*) FROM dbo.Actions))+N' / '
      +CONVERT(NVARCHAR(20),(SELECT COUNT(*) FROM dbo.PrmActions))+N' / '
      +CONVERT(NVARCHAR(20),(SELECT COUNT(DISTINCT ActionId) FROM dbo.GroupsActions));
INSERT #O(linea) VALUES (N'-- En Actions y NO en PrmActions (la matriz admin la ve, MAIN no):');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),A.Id) FROM dbo.Actions A
WHERE NOT EXISTS (SELECT 1 FROM dbo.PrmActions P WHERE P.ActionID COLLATE DATABASE_DEFAULT = A.Id COLLATE DATABASE_DEFAULT)
ORDER BY A.Id;
INSERT #O(linea) VALUES (N'-- En PrmActions y NO en Actions (MAIN la usa, la matriz admin no):');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),P.ActionID)+N' | '+ISNULL(CONVERT(NVARCHAR(50),P.ActionType),N'')+N' | sidebar='+ISNULL(CONVERT(NVARCHAR(20),P.SideBarId),N'')
FROM dbo.PrmActions P
WHERE NOT EXISTS (SELECT 1 FROM dbo.Actions A WHERE A.Id COLLATE DATABASE_DEFAULT = P.ActionID COLLATE DATABASE_DEFAULT)
ORDER BY P.ActionID;
INSERT #O(linea) VALUES (N'-- PrmActions (todas): ActionID | ActionType | SideBarId | SortOrder');
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),P.ActionID)+N' | '+ISNULL(CONVERT(NVARCHAR(50),P.ActionType),N'')+N' | '+ISNULL(CONVERT(NVARCHAR(20),P.SideBarId),N'')+N' | '+ISNULL(CONVERT(NVARCHAR(20),P.SortOrder),N'')
FROM dbo.PrmActions P
ORDER BY P.SideBarId,P.SortOrder,P.ActionID;

/* ---------------- 4. MENUES ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 4. MENUES (SideBar) y asignacion por perfil (SideBarGroups) ===');
INSERT #O(linea)
SELECT N'SideBar '+CONVERT(NVARCHAR(20),S.Id)+N' | '+ISNULL(CONVERT(NVARCHAR(200),S.Name),N'')
       +ISNULL(N' | code='+CONVERT(NVARCHAR(100),(SELECT TOP 1 CONVERT(NVARCHAR(100),X.Code) FROM dbo.SideBar X WHERE X.Id=S.Id)),N'')
FROM dbo.SideBar S ORDER BY S.Id;
INSERT #O(linea)
SELECT CONVERT(NVARCHAR(200),B.GroupId)+N' ve menues: '+
       STUFF((SELECT N', '+CONVERT(NVARCHAR(20),B2.SideBarId)
              FROM dbo.SideBarGroups B2
              WHERE B2.GroupId=B.GroupId
              ORDER BY B2.SideBarId
              FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N'')
FROM (SELECT DISTINCT GroupId FROM dbo.SideBarGroups) B
ORDER BY B.GroupId;

/* ---------------- 5. DEFINICIONES ---------------- */
DECLARE @obj TABLE (n INT IDENTITY(1,1), nombre SYSNAME);
INSERT @obj(nombre) VALUES ('VCT_MAIN_GET_ACTIONS'),('VCT_USER_HAS_ACTION'),('VCT_USER_GET_ACTIONS');
DECLARE @i INT=1, @nom SYSNAME, @def NVARCHAR(MAX), @p INT, @q INT;
WHILE @i<=(SELECT COUNT(*) FROM @obj)
BEGIN
    SELECT @nom=nombre FROM @obj WHERE n=@i;
    INSERT #O(linea) VALUES (N'');
    INSERT #O(linea) VALUES (N'=== 5.'+CONVERT(NVARCHAR(5),@i)+N' DEFINICION de dbo.'+@nom+N' ===');
    SET @def=OBJECT_DEFINITION(OBJECT_ID('dbo.'+@nom));
    IF @def IS NULL
        INSERT #O(linea) VALUES (N'(no existe o sin permiso para verla)');
    ELSE
    BEGIN
        SET @def=REPLACE(@def,NCHAR(13),N'');
        SET @p=1;
        WHILE @p<=LEN(@def)+1
        BEGIN
            SET @q=CHARINDEX(NCHAR(10),@def,@p);
            IF @q=0 SET @q=LEN(@def)+1;
            INSERT #O(linea) VALUES (CASE WHEN @q>@p THEN SUBSTRING(@def,@p,@q-@p) ELSE N' ' END);
            SET @p=@q+1;
        END;
    END;
    SET @i+=1;
END;

/* ---------------- 6. VINCULO USUARIO <-> ENTIDAD ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 6. COLUMNAS que podrian vincular usuario <-> entidad (tabla.columna) ===');
INSERT #O(linea)
SELECT t.name+N'.'+c.name
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id=c.object_id
WHERE (c.name LIKE N'%USUARIO%' OR c.name LIKE N'%USER%' OR c.name LIKE N'%AGENTE%' OR c.name LIKE N'%LOGIN%')
  AND (t.name LIKE N'VCT[_]%' OR t.name IN (N'Users',N'UsersSector',N'GroupsUserMembers'))
ORDER BY t.name,c.column_id;
INSERT #O(linea) VALUES (N'-- Tablas VCT_ relacionadas a clientes/consultores/empleados/proveedores:');
INSERT #O(linea)
SELECT t.name FROM sys.tables t
WHERE t.name LIKE N'VCT[_]CLIENTE%' OR t.name LIKE N'VCT[_]CONSULTOR%' OR t.name LIKE N'VCT[_]EMPLEADO%' OR t.name LIKE N'VCT[_]PROVEEDOR%' OR t.name LIKE N'VCT[_]CONTACTO%'
ORDER BY t.name;
INSERT #O(linea) VALUES (N'-- Cantidad de consultores / empleados con usuario de seguridad cargado:');
IF COL_LENGTH('dbo.VCT_CONSULTORES','ID_USUARIO_SEGURIDAD') IS NOT NULL
    EXEC(N'INSERT #O(linea) SELECT N''consultores total=''+CONVERT(NVARCHAR(20),COUNT(*))+N'' con usuario=''+CONVERT(NVARCHAR(20),SUM(CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(NVARCHAR(100),ID_USUARIO_SEGURIDAD),N''''))),N'''') IS NOT NULL THEN 1 ELSE 0 END)) FROM dbo.VCT_CONSULTORES');
IF COL_LENGTH('dbo.VCT_EMPLEADOS','ID_USUARIO_SEGURIDAD') IS NOT NULL
    EXEC(N'INSERT #O(linea) SELECT N''empleados total=''+CONVERT(NVARCHAR(20),COUNT(*))+N'' con usuario=''+CONVERT(NVARCHAR(20),SUM(CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(NVARCHAR(100),ID_USUARIO_SEGURIDAD),N''''))),N'''') IS NOT NULL THEN 1 ELSE 0 END)) FROM dbo.VCT_EMPLEADOS');

/* ---------------- 7. LISTAS DE USUARIOS A MANO ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 7. SPs con usuarios escritos a mano (@IAGENTE IN / = ''usuario'') ===');
INSERT #O(linea)
SELECT OBJECT_SCHEMA_NAME(m.object_id)+N'.'+o.name
FROM sys.sql_modules m
INNER JOIN sys.objects o ON o.object_id=m.object_id
WHERE m.definition LIKE N'%@IAGENTE IN (%' OR m.definition LIKE N'%@IAGENTE=''%' OR m.definition LIKE N'%@IAGENTE = ''%'
ORDER BY o.name;

SELECT linea FROM #O ORDER BY id;
GO
