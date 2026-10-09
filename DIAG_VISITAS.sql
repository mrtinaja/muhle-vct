/* ========================================================================
   DIAG_VISITAS  (solo lectura, no modifica nada)
   Estructura actual de las visitas (cambio el 06/10) para armar el
   registro de visita del consultor.
   Correr con Query > SQLCMD Mode activado: todo el resultado queda en
   _diag\DIAG_VISITAS.txt (no hace falta copiar grillas).
   ======================================================================== */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_VISITAS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. Tablas de visitas / agenda con filas */
SELECT T.name AS TABLA, SUM(P.rows) AS FILAS
FROM sys.tables T JOIN sys.partitions P ON P.object_id = T.object_id AND P.index_id IN (0,1)
WHERE T.name LIKE '%VISITA%' OR T.name LIKE '%AGENDA%'
GROUP BY T.name ORDER BY T.name;
GO
/* 2. Columnas */
SELECT T.name AS TABLA, C.column_id AS N, C.name AS COLUMNA, TY.name AS TIPO, C.max_length AS LARGO, C.is_nullable AS NULO
FROM sys.tables T JOIN sys.columns C ON C.object_id = T.object_id JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE T.name LIKE 'VCT_PROYECTOS_VISITAS%' OR T.name LIKE 'VCT_PRM_AGENDA%' OR T.name = 'VCT_PROYECTOS'
ORDER BY T.name, C.column_id;
GO
/* 3. Restricciones CHECK y claves foraneas */
SELECT OBJECT_NAME(parent_object_id) AS TABLA, name, definition FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) LIKE 'VCT_PROYECTOS_VISITAS%';
SELECT OBJECT_NAME(FK.parent_object_id) AS TABLA, COL_NAME(FC.parent_object_id, FC.parent_column_id) AS COLUMNA,
       OBJECT_NAME(FK.referenced_object_id) AS REFERENCIA
FROM sys.foreign_keys FK JOIN sys.foreign_key_columns FC ON FC.constraint_object_id = FK.object_id
WHERE OBJECT_NAME(FK.parent_object_id) LIKE 'VCT_PROYECTOS_VISITAS%';
GO
/* 4. Estados de agenda / visita */
IF OBJECT_ID('dbo.VCT_PRM_AGENDA_ESTADOS') IS NOT NULL EXEC (N'SELECT * FROM dbo.VCT_PRM_AGENDA_ESTADOS');
GO
/* 5. Ultimas 8 visitas con su consultor (muestra) */
EXEC (N'SELECT TOP 8 V.*, VC.* FROM dbo.VCT_PROYECTOS_VISITAS V
        LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID
        ORDER BY V.ID DESC');
GO
/* 6. SP / funciones que leen o escriben visitas */
SELECT O.type_desc, O.name, O.modify_date
FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%VCT_PROYECTOS_VISITAS%'
ORDER BY O.modify_date DESC;
GO
