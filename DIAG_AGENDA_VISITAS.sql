:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_AGENDA_VISITAS.txt
/* DIAG_AGENDA_VISITAS (solo lectura) — estructura vigente para la agenda de la V360 de proyecto.
   SSMS: Query > SQLCMD Mode, F5. No modifica nada. */
USE [MuhlePROD];
SET NOCOUNT ON;
PRINT '=== 1. columnas de las tablas ===';
SELECT t.name AS tabla, c.column_id, c.name AS columna, ty.name AS tipo, c.max_length, c.is_nullable, ISNULL(OBJECT_DEFINITION(c.default_object_id),'') AS def
FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.name IN ('VCT_PROYECTOS_VISITAS','VCT_PROYECTOS_VISITAS_CONSULTORES','VCT_PROYECTOS_VISITAS_NORMAS','VCT_PROYECTOS_VISITAS_REGISTRO',
                 'VCT_CONSULTORES_NORMAS','VCT_CONSULTORES_SERVICIOS','VCT_PRM_AGENDA_CONSULTOR','VCT_PRM_AGENDA_ESTADOS','VCT_AGENDA_CONSULTOR_ACTIVIDAD','VCT_CONSULTORES_DIAS')
ORDER BY t.name, c.column_id;
PRINT '=== 2. claves foraneas y checks ===';
SELECT OBJECT_NAME(f.parent_object_id) AS tabla, f.name AS fk, OBJECT_NAME(f.referenced_object_id) AS ref
FROM sys.foreign_keys f WHERE OBJECT_NAME(f.parent_object_id) LIKE 'VCT_PROYECTOS_VISITAS%' OR OBJECT_NAME(f.parent_object_id) IN ('VCT_PRM_AGENDA_CONSULTOR','VCT_CONSULTORES_NORMAS');
SELECT OBJECT_NAME(parent_object_id) AS tabla, name, definition FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) LIKE 'VCT_PROYECTOS_VISITAS%' OR OBJECT_NAME(parent_object_id) IN ('VCT_PRM_AGENDA_CONSULTOR','VCT_CONSULTORES_NORMAS');
PRINT '=== 3. valores de estado / calificacion en uso ===';
IF COL_LENGTH('dbo.VCT_PROYECTOS_VISITAS','ESTADO') IS NOT NULL EXEC('SELECT ESTADO, COUNT(*) N FROM dbo.VCT_PROYECTOS_VISITAS GROUP BY ESTADO');
IF COL_LENGTH('dbo.VCT_PROYECTOS_VISITAS','CONFIRMADO') IS NOT NULL EXEC('SELECT CONFIRMADO, COUNT(*) N FROM dbo.VCT_PROYECTOS_VISITAS GROUP BY CONFIRMADO');
IF OBJECT_ID('dbo.VCT_PRM_AGENDA_ESTADOS') IS NOT NULL EXEC('SELECT * FROM dbo.VCT_PRM_AGENDA_ESTADOS');
IF COL_LENGTH('dbo.VCT_CONSULTORES_NORMAS','CALIFICACION') IS NOT NULL EXEC('SELECT CALIFICACION, COUNT(*) N FROM dbo.VCT_CONSULTORES_NORMAS GROUP BY CALIFICACION');
PRINT '=== 4. muestras (5 filas) ===';
SELECT TOP 5 * FROM dbo.VCT_PROYECTOS_VISITAS ORDER BY 1 DESC;
SELECT TOP 5 * FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES ORDER BY 1 DESC;
IF OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_NORMAS') IS NOT NULL EXEC('SELECT TOP 5 * FROM dbo.VCT_PROYECTOS_VISITAS_NORMAS ORDER BY 1 DESC');
SELECT TOP 5 * FROM dbo.VCT_CONSULTORES_NORMAS ORDER BY 1 DESC;
SELECT TOP 5 * FROM dbo.VCT_PRM_AGENDA_CONSULTOR ORDER BY 1 DESC;
PRINT '=== 5. objetos que ya usan visitas / agenda (nombre y largo) ===';
SELECT o.type, o.name, LEN(m.definition) AS largo, CONVERT(VARCHAR(16), o.modify_date, 120) AS modificado
FROM sys.objects o JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE m.definition LIKE '%VCT_PROYECTOS_VISITAS%' OR m.definition LIKE '%VCT_PRM_AGENDA_CONSULTOR%'
ORDER BY o.type, o.name;
