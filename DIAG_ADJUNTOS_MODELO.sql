:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_ADJUNTOS_MODELO.txt
/* ============================================================================
   DIAG_ADJUNTOS_MODELO  (solo lectura)
   Para adjuntar la propuesta comercial en el alta del proyecto:
     1) tabla estandar del framework donde UploadFile.ashx guarda los adjuntos
        (PHYSICAL_ATTACHED_DOCUMENT / PHYSICAL_JOB_ATTACHED_DATA): columnas, PK, indices
        y 5 filas de ejemplo SIN el contenido binario;
     2) como lo usa el legacy (LK_PROYECTO_DOCUM / LK_PROYECTOS.ID_ADJUNTO);
     3) nuestro modelo: VCT_PROYECTOS_DATOS (+ _ITEMS) (ex VCT_PROYECTOS_DOCUMENTOS, renombrada en PASO3_7).
   V2: todo lo que no existe se saltea (no da error).
   SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '==== 1. columnas ====';
SELECT t.name AS tabla, c.column_id, c.name AS columna, ty.name AS tipo, c.max_length, c.is_nullable, c.is_identity,
       dc.definition AS default_def
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE t.name IN ('PHYSICAL_ATTACHED_DOCUMENT','PHYSICAL_JOB_ATTACHED_DATA','LK_PROYECTO_DOCUM','VCT_PROYECTOS_DATOS','VCT_PROYECTOS_DATOS_ITEMS','VCT_PROYECTOS_DOCUMENTOS','VCT_PROYECTOS_DOCUMENTOS_ITEMS','VCT_DOCUMENTOS')
   OR (t.name = 'LK_PROYECTOS' AND c.name LIKE '%ADJUNTO%')
ORDER BY t.name, c.column_id;

PRINT '==== 2. PK / FK / indices ====';
SELECT t.name AS tabla, i.name AS indice, i.is_primary_key, i.is_unique,
       STUFF((SELECT ',' + c.name FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 1, '') AS columnas
FROM sys.indexes i JOIN sys.tables t ON t.object_id = i.object_id
WHERE t.name IN ('PHYSICAL_ATTACHED_DOCUMENT','PHYSICAL_JOB_ATTACHED_DATA','VCT_PROYECTOS_DATOS','VCT_PROYECTOS_DATOS_ITEMS','VCT_PROYECTOS_DOCUMENTOS','VCT_PROYECTOS_DOCUMENTOS_ITEMS','VCT_DOCUMENTOS') AND i.name IS NOT NULL;
SELECT fk.name, OBJECT_NAME(fk.parent_object_id) AS tabla, OBJECT_NAME(fk.referenced_object_id) AS referencia
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('VCT_PROYECTOS_DATOS','VCT_PROYECTOS_DATOS_ITEMS','VCT_PROYECTOS_DOCUMENTOS','VCT_PROYECTOS_DOCUMENTOS_ITEMS','VCT_DOCUMENTOS','PHYSICAL_ATTACHED_DOCUMENT');

PRINT '==== 3. ejemplos (sin binario) ====';
DECLARE @cols NVARCHAR(MAX), @sql NVARCHAR(MAX);
SELECT @cols = STUFF((SELECT ',' + QUOTENAME(c.name) FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
                      WHERE c.object_id = OBJECT_ID('dbo.PHYSICAL_ATTACHED_DOCUMENT') AND ty.name NOT IN ('image','varbinary','binary','text','ntext')
                      ORDER BY c.column_id FOR XML PATH('')), 1, 1, '');
IF @cols IS NOT NULL BEGIN SET @sql = N'SELECT TOP 5 ' + @cols + N' FROM dbo.PHYSICAL_ATTACHED_DOCUMENT ORDER BY 1 DESC;'; EXEC sp_executesql @sql; END;
SELECT @cols = STUFF((SELECT ',' + QUOTENAME(c.name) FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
                      WHERE c.object_id = OBJECT_ID('dbo.PHYSICAL_JOB_ATTACHED_DATA') AND ty.name NOT IN ('image','varbinary','binary','text','ntext')
                      ORDER BY c.column_id FOR XML PATH('')), 1, 1, '');
IF @cols IS NOT NULL BEGIN SET @sql = N'SELECT TOP 5 ' + @cols + N' FROM dbo.PHYSICAL_JOB_ATTACHED_DATA ORDER BY 1 DESC;'; EXEC sp_executesql @sql; END;
IF OBJECT_ID('dbo.PHYSICAL_ATTACHED_DOCUMENT') IS NOT NULL EXEC (N'SELECT COUNT(*) AS adjuntos_total FROM dbo.PHYSICAL_ATTACHED_DOCUMENT;');
IF OBJECT_ID('dbo.LK_PROYECTO_DOCUM') IS NOT NULL
    EXEC (N'SELECT TOP 5 ID_PROYECTO_DOCUM, ID_PROYECTO, TIPO, NRO_DOCUM_INTERNO, ID_ADJUNTO FROM dbo.LK_PROYECTO_DOCUM WHERE ISNULL(ID_ADJUNTO,'''') <> '''' ORDER BY ID_PROYECTO_DOCUM DESC;');
IF OBJECT_ID('dbo.VCT_PROYECTOS_DATOS') IS NOT NULL EXEC (N'SELECT TIPO, COUNT(*) AS cant FROM dbo.VCT_PROYECTOS_DATOS GROUP BY TIPO;');
SELECT name AS tabla_existe FROM sys.tables WHERE name IN ('PHYSICAL_ATTACHED_DOCUMENT','PHYSICAL_JOB_ATTACHED_DATA','LK_PROYECTO_DOCUM','VCT_PROYECTOS_DATOS','VCT_PROYECTOS_DATOS_ITEMS','VCT_PROYECTOS_DOCUMENTOS','VCT_DOCUMENTOS');

PRINT '==== 4. SPs que leen / escriben el adjunto ====';
SELECT o.name, o.type_desc FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%PHYSICAL_ATTACHED_DOCUMENT%' ORDER BY o.name;
