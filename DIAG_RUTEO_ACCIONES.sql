/* DIAG_RUTEO_ACCIONES (solo lectura) - correr con Query > SQLCMD Mode
   Como se elige el SP de cada menu (ACTION=...): el menu "Acciones"
   (PLANIFICACION) y "Proyectos" (PROYECTOS) caen en el Inicio. */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_RUTEO_ACCIONES.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== 1. menus (SideBar) ===';
SELECT * FROM dbo.SideBar ORDER BY CONVERT(INT, Id);
GO

PRINT '=== 2. SP VCT_MAIN_* existentes ===';
SELECT name, modify_date FROM sys.objects WHERE type = 'P' AND name LIKE 'VCT_MAIN[_]%' ORDER BY name;
GO

PRINT '=== 3. objetos que mencionan AGENDA_CONSULTOR o VCT_MAIN_DASHBOARD (despachador) ===';
SELECT O.type_desc, O.name FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%AGENDA_CONSULTOR%' OR M.definition LIKE '%''VCT_MAIN_''%' OR M.definition LIKE '%VCT_MAIN_DASHBOARD%';
GO

PRINT '=== 4. tablas con columnas de ruteo (SP / PROCEDURE / ACTION) ===';
SELECT T.name AS TABLA, C.name AS COLUMNA
FROM sys.tables T JOIN sys.columns C ON C.object_id = T.object_id
WHERE (C.name LIKE '%PROC%' OR C.name LIKE '%SP%' OR C.name LIKE '%STORED%' OR C.name LIKE '%ROUT%')
  AND T.name NOT LIKE 'VCT_PROYECTOS%' AND T.name NOT LIKE 'sys%'
ORDER BY T.name;
GO

PRINT '=== 5. filas que mencionan VCT_MAIN_CLIENTES o AGENDA en tablas chicas de configuracion ===';
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(S.name) + N'.' + QUOTENAME(T.name) + N' WHERE CONVERT(NVARCHAR(4000),' + QUOTENAME(C.name) + N') LIKE N''%VCT_MAIN_CLIENTES%'' OR CONVERT(NVARCHAR(4000),' + QUOTENAME(C.name) + N') LIKE N''%AGENDA_CONSULTOR%'') PRINT ''' + T.name + N'.' + C.name + N''';' + CHAR(10)
FROM sys.tables T
JOIN sys.schemas S ON S.schema_id = T.schema_id
JOIN sys.columns C ON C.object_id = T.object_id
JOIN sys.types TY ON TY.user_type_id = C.user_type_id
JOIN sys.partitions P ON P.object_id = T.object_id AND P.index_id IN (0,1)
WHERE TY.name IN ('varchar','nvarchar','char','nchar') AND (C.max_length = -1 OR C.max_length >= 20) AND P.rows < 5000;
EXEC sp_executesql @sql;
GO
