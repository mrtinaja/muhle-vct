/* DIAG_CONSULTOR_SERVICIOS (solo lectura) - correr con Query > SQLCMD Mode
   Servicios y normas por consultor (charla con Esteban 09/10):
     - estructura de VCT_CONSULTORES_SERVICIOS / VCT_CONSULTORES_NORMAS y sus parametricas
     - datos de Cavana (5), del consultor 147 y de Romero Carlos (analista de prueba)
     - que SP usan esas tablas y la definicion vigente de VCT_MAIN_CONSULTORES_V360 */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_CONSULTOR_SERVICIOS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== 1. columnas ===';
SELECT T.name AS TABLA, C.column_id, C.name AS COLUMNA, TY.name AS TIPO, C.max_length, C.is_nullable, C.is_identity
FROM sys.tables T
JOIN sys.columns C ON C.object_id = T.object_id
JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE T.name IN ('VCT_CONSULTORES_SERVICIOS','VCT_CONSULTORES_NORMAS','PRM_SERVICIOS','VCT_PROYECTOS_SERVICIOS','VCT_PROYECTOS_NORMAS')
ORDER BY T.name, C.column_id;
GO

PRINT '=== 2. claves foraneas (a que tabla apunta cada columna) ===';
SELECT OBJECT_NAME(FK.parent_object_id) AS TABLA, PC.name AS COLUMNA, OBJECT_NAME(FK.referenced_object_id) AS REFERENCIA, RC.name AS COL_REF
FROM sys.foreign_keys FK
JOIN sys.foreign_key_columns FKC ON FKC.constraint_object_id = FK.object_id
JOIN sys.columns PC ON PC.object_id = FKC.parent_object_id AND PC.column_id = FKC.parent_column_id
JOIN sys.columns RC ON RC.object_id = FKC.referenced_object_id AND RC.column_id = FKC.referenced_column_id
WHERE OBJECT_NAME(FK.parent_object_id) IN ('VCT_CONSULTORES_SERVICIOS','VCT_CONSULTORES_NORMAS');
GO

PRINT '=== 3. checks, unicos y defaults ===';
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name, definition FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) IN ('VCT_CONSULTORES_SERVICIOS','VCT_CONSULTORES_NORMAS');
SELECT OBJECT_NAME(I.object_id) AS TABLA, I.name, I.is_unique, I.is_primary_key,
       STUFF((SELECT ',' + C.name FROM sys.index_columns IC JOIN sys.columns C ON C.object_id = IC.object_id AND C.column_id = IC.column_id
              WHERE IC.object_id = I.object_id AND IC.index_id = I.index_id ORDER BY IC.key_ordinal FOR XML PATH('')),1,1,'') AS COLUMNAS
FROM sys.indexes I
WHERE OBJECT_NAME(I.object_id) IN ('VCT_CONSULTORES_SERVICIOS','VCT_CONSULTORES_NORMAS') AND I.index_id > 0;
SELECT OBJECT_NAME(parent_object_id) AS TABLA, COL_NAME(parent_object_id, parent_column_id) AS COLUMNA, definition FROM sys.default_constraints
WHERE OBJECT_NAME(parent_object_id) IN ('VCT_CONSULTORES_SERVICIOS','VCT_CONSULTORES_NORMAS');
GO

PRINT '=== 4. parametricas: servicios y tablas a las que apuntan las FK de normas ===';
PRINT '--- tablas de servicios que existen:';
SELECT name FROM sys.tables WHERE name LIKE '%SERVICIO%' ORDER BY name;
IF OBJECT_ID('dbo.VCT_PRM_SERVICIOS') IS NOT NULL EXEC ('SELECT * FROM dbo.VCT_PRM_SERVICIOS');
IF OBJECT_ID('dbo.PRM_SERVICIOS') IS NOT NULL EXEC ('SELECT * FROM dbo.PRM_SERVICIOS');
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'PRINT ''--- ' + OBJECT_NAME(FK.referenced_object_id) + N' (primeras 60 filas)''; SELECT TOP 60 * FROM dbo.' + QUOTENAME(OBJECT_NAME(FK.referenced_object_id)) + N';' + CHAR(10)
FROM sys.foreign_keys FK
WHERE OBJECT_NAME(FK.parent_object_id) IN ('VCT_CONSULTORES_NORMAS','VCT_CONSULTORES_SERVICIOS')
  AND OBJECT_NAME(FK.referenced_object_id) NOT IN ('VCT_CONSULTORES','PRM_SERVICIOS');
EXEC sp_executesql @sql;
GO

PRINT '=== 5. volumen ===';
SELECT 'SERVICIOS' AS TABLA, COUNT(*) AS FILAS, COUNT(DISTINCT ID_CONSULTOR) AS CONSULTORES FROM dbo.VCT_CONSULTORES_SERVICIOS
UNION ALL
SELECT 'NORMAS', COUNT(*), COUNT(DISTINCT ID_CONSULTOR) FROM dbo.VCT_CONSULTORES_NORMAS;
SELECT X.ESTADO, COUNT(*) AS CONSULTORES, SUM(X.CON_SERV) AS CON_SERVICIOS, SUM(X.CON_NORM) AS CON_NORMAS
FROM (
    SELECT C.ESTADO,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_SERVICIOS S WHERE S.ID_CONSULTOR = C.ID) THEN 1 ELSE 0 END AS CON_SERV,
           CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS N WHERE N.ID_CONSULTOR = C.ID) THEN 1 ELSE 0 END AS CON_NORM
    FROM dbo.VCT_CONSULTORES C
) X GROUP BY X.ESTADO;
GO

PRINT '=== 6. Cavana (5) y consultor 147: ficha, servicios y normas ===';
SELECT * FROM dbo.VCT_CONSULTORES WHERE ID IN (5, 147) OR APELLIDOS LIKE '%CAVANA%' OR APELLIDOS LIKE '%CABANA%';
SELECT * FROM dbo.VCT_CONSULTORES_SERVICIOS WHERE ID_CONSULTOR IN (5, 147) ORDER BY ID_CONSULTOR;
SELECT * FROM dbo.VCT_CONSULTORES_NORMAS WHERE ID_CONSULTOR IN (5, 147) ORDER BY ID_CONSULTOR;
GO

PRINT '=== 7. Romero Carlos (empleado) y su usuario ===';
SELECT * FROM dbo.VCT_EMPLEADOS WHERE APELLIDOS LIKE '%ROMERO%';
SELECT U.Id, U.Name, U.State, U.Email, G.GroupId AS PERFIL
FROM dbo.Users U LEFT JOIN dbo.GroupsUserMembers G ON G.UserMemberId = U.Id
WHERE U.Id LIKE '%ROMERO%' OR U.Name LIKE '%ROMERO%';
SELECT * FROM dbo.VCT_CONSULTORES WHERE APELLIDOS LIKE '%ROMERO%' OR APELLIDOS LIKE '%BERRA%';
GO

PRINT '=== 8. objetos que usan las tablas ===';
SELECT O.type_desc, O.name, O.modify_date FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%VCT_CONSULTORES_SERVICIOS%' OR M.definition LIKE '%VCT_CONSULTORES_NORMAS%'
ORDER BY O.name;
GO

PRINT '=== 10. roles de proyecto y equipo de los proyectos de prueba ===';
SELECT * FROM dbo.VCT_PRM_PROYECTOS_ROLES;
SELECT EQ.* FROM dbo.VCT_PROYECTOS_EQUIPO EQ JOIN dbo.VCT_PROYECTOS P ON P.ID = EQ.ID_PROYECTO
WHERE P.CODIGO IN ('1339','1340','1341','1342','1343') ORDER BY EQ.ID_PROYECTO;
SELECT C.name AS COLUMNA, TY.name AS TIPO, C.max_length FROM sys.columns C JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE C.object_id = OBJECT_ID('dbo.VCT_PROYECTOS') AND C.name IN ('REFERENCIA','NOMBRE','CODIGO');
SELECT TOP 10 ID, CODIGO, NOMBRE, REFERENCIA FROM dbo.VCT_PROYECTOS WHERE NULLIF(LTRIM(REFERENCIA),'') IS NOT NULL ORDER BY ID DESC;
GO

PRINT '=== 11. sidebar y acciones por perfil (ADMINISTRACION, CONSULTORES, PROYECTOS, GERENCIA) ===';
SELECT * FROM dbo.SideBar ORDER BY Id;
SELECT * FROM dbo.SideBarGroups WHERE GroupId IN ('ADMINISTRACION','CONSULTORES','PROYECTOS','GERENCIA') ORDER BY GroupId, SideBarId;
SELECT GA.* FROM dbo.GroupsActions GA
WHERE GA.GroupId IN ('ADMINISTRACION','CONSULTORES','PROYECTOS')
ORDER BY GA.GroupId;
SELECT G.GroupId, COUNT(*) AS USUARIOS FROM dbo.GroupsUserMembers G GROUP BY G.GroupId;
GO

PRINT '=== 11b. catalogo de normas del alta: nombres repetidos y version del js que carga la 360 de cliente ===';
SELECT DESCRIPCION, COUNT(*) AS VECES, MIN(ID) AS ID_MIN, MAX(ID) AS ID_MAX
FROM dbo.VCT_PRM_NORMAS WHERE ISNULL(ESTADO,'ACTIVO') = 'ACTIVO'
GROUP BY DESCRIPCION HAVING COUNT(*) > 1;
SELECT ID, DESCRIPCION, ESTADO FROM dbo.VCT_PRM_NORMAS WHERE DESCRIPCION LIKE '%9001%' OR DESCRIPCION LIKE '%14001%' ORDER BY DESCRIPCION;
DECLARE @CV NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CLIENTES_V360')), @CVJ VARCHAR(60);
SET @CVJ = SUBSTRING(@CV, CHARINDEX(N'vct-proyecto-alta.js', @CV), 30);
PRINT 'VCT_MAIN_CLIENTES_V360 carga: ' + ISNULL(@CVJ, '(no encontrado)');
GO

PRINT '=== 12. ruteo: pasos con ACTION PROYECTOS / PLANIFICACION ===';
SELECT name, modify_date FROM sys.objects WHERE type = 'P' AND (name LIKE 'VCT_MAIN_PROYECTO%' OR name LIKE 'VCT_MAIN_ACCIONES%');
GO

PRINT '=== FIN ===';
GO
