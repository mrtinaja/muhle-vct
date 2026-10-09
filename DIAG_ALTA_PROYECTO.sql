/* ========================================================================
   DIAG_ALTA_PROYECTO - SOLO LECTURA. No modifica nada.
   Junta lo necesario para disenar el alta de Proyecto en MAIN:
     1. columnas (tipo, null, identity, default) de las tablas de proyectos,
        gestiones, catalogos, emails, contactos, cotizaciones y riesgo
     2. FKs y triggers de esas tablas
     3. contenido de los catalogos chicos (servicios, estados, roles,
        gestiones, templates de email) y cantidad de normas
     4. ultimas 3 filas (JSON) de cada tabla de proyectos/gestiones
     5. SP / vistas / funciones que escriben o leen esas tablas
   Uso: ejecutar y copiar TODA la columna "linea" de la pestana Results.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

IF OBJECT_ID('tempdb..#T') IS NOT NULL DROP TABLE #T;
SELECT t.object_id, t.name
INTO #T
FROM sys.tables t
WHERE t.name LIKE N'VCT[_]PROYECTO%'
   OR t.name LIKE N'VCT[_]GESTION%'
   OR t.name LIKE N'VCT[_]PRM[_]PROYECTO%'
   OR t.name LIKE N'VCT[_]PRM[_]GESTION%'
   OR t.name IN (N'VCT_PRM_SERVICIOS',N'VCT_PRM_NORMAS',N'VCT_PRM_EMAIL_TEMPLATES',N'VCT_EMAILS',N'VCT_EMPLEADOS')
   OR t.name LIKE N'%CONTACTO%'
   OR t.name LIKE N'%COTIZ%'
   OR t.name LIKE N'%RIESGO%'
   OR t.name LIKE N'LK[_]PROYECTO%'
   OR t.name LIKE N'%RENTAB%';

/* ---------------- 1. COLUMNAS ---------------- */
INSERT #O(linea) VALUES (N'=== 1. COLUMNAS: tabla (filas) | col tipo [NULL] [IDENTITY] [DEF=...] ===');
INSERT #O(linea)
SELECT t.name + N' (' + CONVERT(NVARCHAR(20),(SELECT SUM(p.rows) FROM sys.partitions p WHERE p.object_id=t.object_id AND p.index_id IN (0,1))) + N') | '
     + ISNULL(STUFF((
         SELECT N', ' + c.name + N' ' + ty.name
              + CASE WHEN ty.name IN (N'varchar',N'char',N'varbinary') THEN N'(' + CASE WHEN c.max_length=-1 THEN N'MAX' ELSE CONVERT(NVARCHAR(10),c.max_length) END + N')'
                     WHEN ty.name IN (N'nvarchar',N'nchar') THEN N'(' + CASE WHEN c.max_length=-1 THEN N'MAX' ELSE CONVERT(NVARCHAR(10),c.max_length/2) END + N')'
                     WHEN ty.name IN (N'decimal',N'numeric') THEN N'(' + CONVERT(NVARCHAR(10),c.precision) + N',' + CONVERT(NVARCHAR(10),c.scale) + N')'
                     ELSE N'' END
              + CASE WHEN c.is_nullable=1 THEN N' NULL' ELSE N'' END
              + CASE WHEN c.is_identity=1 THEN N' IDENTITY' ELSE N'' END
              + CASE WHEN dc.definition IS NOT NULL THEN N' DEF=' + dc.definition ELSE N'' END
         FROM sys.columns c
         INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
         LEFT JOIN sys.default_constraints dc ON dc.object_id=c.default_object_id
         WHERE c.object_id=t.object_id
         ORDER BY c.column_id
         FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'')
FROM #T t
ORDER BY t.name;

/* ---------------- 2. FKs y TRIGGERS ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 2. FKs (tabla.col -> tabla.col) y TRIGGERS ===');
INSERT #O(linea)
SELECT N'FK ' + OBJECT_NAME(fk.parent_object_id) + N'.' + pc.name + N' -> ' + OBJECT_NAME(fk.referenced_object_id) + N'.' + rc.name
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
INNER JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
INNER JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE fk.parent_object_id IN (SELECT object_id FROM #T) OR fk.referenced_object_id IN (SELECT object_id FROM #T)
ORDER BY 1;
INSERT #O(linea)
SELECT N'TRIGGER ' + tr.name + N' ON ' + OBJECT_NAME(tr.parent_id) + CASE WHEN tr.is_disabled=1 THEN N' (DESHABILITADO)' ELSE N'' END
FROM sys.triggers tr
WHERE tr.parent_id IN (SELECT object_id FROM #T);

/* ---------------- 3. CATALOGOS ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 3. CATALOGOS (todas las filas, JSON) ===');

DECLARE @tab SYSNAME, @sql NVARCHAR(MAX), @first SYSNAME;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM #T
    WHERE name IN (N'VCT_PRM_SERVICIOS',N'VCT_PRM_EMAIL_TEMPLATES')
       OR name LIKE N'VCT[_]PRM[_]PROYECTO%'
       OR name LIKE N'VCT[_]PRM[_]GESTION%'
       OR name LIKE N'%COTIZ%' OR name LIKE N'%RIESGO%'
    ORDER BY name;
OPEN cur;
FETCH NEXT FROM cur INTO @tab;
WHILE @@FETCH_STATUS=0
BEGIN
    /* en templates no traigo el HTML ni el diseno (son enormes) */
    IF @tab=N'VCT_PRM_EMAIL_TEMPLATES'
        SET @sql = N'INSERT #O(linea) SELECT N''' + @tab + N' | '' + ISNULL((SELECT CODIGO,DESCRIPCION,TIPO_ENVIO,DESTINO_TIPO,CC_TIPO,ESTADO,ASUNTO FROM dbo.VCT_PRM_EMAIL_TEMPLATES FOR JSON PATH),N''(vacia)'')';
    ELSE
        SET @sql = N'INSERT #O(linea) SELECT N''' + @tab + N' | '' + ISNULL((SELECT TOP 200 * FROM dbo.' + QUOTENAME(@tab) + N' FOR JSON PATH),N''(vacia)'')';
    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        INSERT #O(linea) VALUES (@tab + N' | (no se pudo leer: ' + ERROR_MESSAGE() + N')');
    END CATCH;
    FETCH NEXT FROM cur INTO @tab;
END;
CLOSE cur;
DEALLOCATE cur;

IF OBJECT_ID(N'dbo.VCT_PRM_NORMAS') IS NOT NULL
BEGIN
    EXEC (N'INSERT #O(linea) SELECT N''VCT_PRM_NORMAS | total='' + CONVERT(NVARCHAR(10),COUNT(*)) + N'' activas='' + CONVERT(NVARCHAR(10),SUM(CASE WHEN ESTADO=''ACTIVO'' THEN 1 ELSE 0 END)) FROM dbo.VCT_PRM_NORMAS');
    EXEC (N'INSERT #O(linea) SELECT N''VCT_PRM_NORMAS (primeras 5) | '' + ISNULL((SELECT TOP 5 * FROM dbo.VCT_PRM_NORMAS ORDER BY ID FOR JSON PATH),N''(vacia)'')');
END;

/* ---------------- 4. ULTIMAS FILAS DE DATOS ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 4. ULTIMAS 3 FILAS (JSON) de proyectos / gestiones / rentabilidad ===');
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM #T
    WHERE (name LIKE N'VCT[_]PROYECTO%' OR name LIKE N'VCT[_]GESTION%' OR name LIKE N'LK[_]PROYECTO%' OR name LIKE N'%RENTAB%')
      AND name NOT LIKE N'VCT[_]PRM%'
    ORDER BY name;
OPEN cur2;
FETCH NEXT FROM cur2 INTO @tab;
WHILE @@FETCH_STATUS=0
BEGIN
    /* ordena por la primera columna (normalmente el ID) descendente */
    SET @first = (SELECT TOP 1 c.name FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'dbo.'+@tab) ORDER BY c.column_id);
    SET @sql = N'INSERT #O(linea) SELECT N''' + @tab + N' | '' + ISNULL((SELECT TOP 3 * FROM dbo.' + QUOTENAME(@tab) + N' ORDER BY ' + QUOTENAME(@first) + N' DESC FOR JSON PATH, INCLUDE_NULL_VALUES),N''(vacia)'')';
    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        INSERT #O(linea) VALUES (@tab + N' | (no se pudo leer: ' + ERROR_MESSAGE() + N')');
    END CATCH;
    FETCH NEXT FROM cur2 INTO @tab;
END;
CLOSE cur2;
DEALLOCATE cur2;

/* ---------------- 5. OBJETOS QUE USAN ESAS TABLAS ---------------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 5. SP / vistas / funciones: que tablas ESCRIBEN (I=insert, U=update) y LEEN ===');
IF OBJECT_ID('tempdb..#TD') IS NOT NULL DROP TABLE #TD;
SELECT name INTO #TD FROM #T
WHERE (name LIKE N'VCT[_]PROYECTO%' OR name LIKE N'VCT[_]GESTION%' OR name LIKE N'%RENTAB%' OR name LIKE N'%COTIZ%' OR name LIKE N'%RIESGO%')
  AND name NOT LIKE N'VCT[_]PRM%';
INSERT #O(linea)
SELECT X.tipo + N' ' + X.nombre + N' | ' + X.tablas
FROM (
    SELECT o.type_desc AS tipo, o.name AS nombre,
           STUFF((
               SELECT N', ' + d.name
                    + CASE WHEN m.definition LIKE N'%INSERT%' + d.name + N'%' THEN N'[I]' ELSE N'' END
                    + CASE WHEN m.definition LIKE N'%UPDATE%' + d.name + N'%' THEN N'[U]' ELSE N'' END
               FROM #TD d
               WHERE m.definition LIKE N'%' + d.name + N'%'
               ORDER BY d.name
               FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N'') AS tablas
    FROM sys.sql_modules m
    INNER JOIN sys.objects o ON o.object_id=m.object_id
    WHERE o.name NOT LIKE N'EP[_]%'
) X
WHERE X.tablas IS NOT NULL
ORDER BY X.nombre;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 6. Procedimientos VCT_MAIN_* (nombre | creado | modificado) ===');
INSERT #O(linea)
SELECT name + N' | ' + CONVERT(NVARCHAR(10),create_date,120) + N' | ' + CONVERT(NVARCHAR(16),modify_date,120)
FROM sys.procedures
WHERE name LIKE N'VCT[_]MAIN[_]%' OR name LIKE N'VCT[_]%PROYECT%' OR name LIKE N'VCT[_]%GESTION%'
ORDER BY name;

DECLARE @nFilas INT=(SELECT COUNT(*) FROM #O);
PRINT N'Filas generadas: '+CONVERT(NVARCHAR(10),@nFilas)+N'. Copiar la columna "linea" de la pestana Results.';

SELECT linea FROM #O ORDER BY id;
GO
