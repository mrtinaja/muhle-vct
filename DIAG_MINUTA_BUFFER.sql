/* ========================================================================
   DIAG_MINUTA_BUFFER - SOLO LECTURA. No modifica nada.
   Bug: Minuta de Gestion (Vista 360 Cliente > Proyectos > librito) da error
   al guardar. La pagina junta los campos cambiados en CALL.BUFFER
   ("id=valor|id=valor|") con maxlength=4000; la minuta del proyecto 1340
   suma 4188 caracteres. Este script busca:
     1. Columnas llamadas BUFFER (tabla y tamano)
     2. SPs / funciones que leen el BUFFER o la minuta (y si usan VARCHAR(4000/8000))
     3. Columnas de la tabla de respuestas de la minuta (tamano del valor)
   Uso: ejecutar y copiar TODA la columna "linea" de Results.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

INSERT #O(linea) VALUES (N'=== 1. COLUMNAS BUFFER ===');
INSERT #O(linea)
SELECT SCHEMA_NAME(t.schema_id)+N'.'+t.name+N'.'+c.name+N' | '+ty.name
     +N'('+CASE WHEN c.max_length=-1 THEN N'MAX' WHEN ty.name LIKE N'n%' THEN CONVERT(NVARCHAR(10),c.max_length/2) ELSE CONVERT(NVARCHAR(10),c.max_length) END+N')'
FROM sys.columns c
JOIN sys.tables t ON t.object_id=c.object_id
JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE c.name LIKE N'%BUFFER%'
ORDER BY t.name;

INSERT #O(linea) VALUES (N''),(N'=== 2. OBJETOS que mencionan BUFFER junto con MINUTA / XAGENDA / TAB_SERV ===');
INSERT #O(linea)
SELECT SCHEMA_NAME(o.schema_id)+N'.'+o.name+N' | '+o.type_desc
     +N' | mod '+CONVERT(NVARCHAR(16),o.modify_date,120)
     +N' | usa VARCHAR(4000)/(8000): '
     +CASE WHEN m.definition LIKE N'%(4000)%' OR m.definition LIKE N'%(8000)%' THEN N'SI' ELSE N'no' END
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id=m.object_id
WHERE m.definition LIKE N'%BUFFER%'
  AND (m.definition LIKE N'%MINUTA%' OR m.definition LIKE N'%XAGENDA%' OR m.definition LIKE N'%TAB_SERV%')
ORDER BY o.name;

INSERT #O(linea) VALUES (N''),(N'=== 3. TABLAS con columnas de minuta (nombre contiene MINUTA) ===');
INSERT #O(linea)
SELECT SCHEMA_NAME(t.schema_id)+N'.'+t.name+N'.'+c.name+N' | '+ty.name
     +N'('+CASE WHEN c.max_length=-1 THEN N'MAX' WHEN ty.name LIKE N'n%' THEN CONVERT(NVARCHAR(10),c.max_length/2) ELSE CONVERT(NVARCHAR(10),c.max_length) END+N')'
FROM sys.columns c
JOIN sys.tables t ON t.object_id=c.object_id
JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE t.name LIKE N'%MINUTA%'
ORDER BY t.name, c.column_id;

INSERT #O(linea) VALUES (N''),(N'=== 4. Lineas de esos objetos que tocan BUFFER (para ver como lo parsean) ===');
DECLARE @OBJS TABLE (orden INT IDENTITY(1,1), oid INT, nombre SYSNAME);
INSERT @OBJS(oid,nombre)
SELECT o.object_id, SCHEMA_NAME(o.schema_id)+N'.'+o.name
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id
WHERE m.definition LIKE N'%BUFFER%'
  AND (m.definition LIKE N'%MINUTA%' OR m.definition LIKE N'%XAGENDA%' OR m.definition LIKE N'%TAB_SERV%');

DECLARE @I INT = 1, @N INT = (SELECT COUNT(*) FROM @OBJS), @D NVARCHAR(MAX), @NAME SYSNAME,
        @TOTAL INT, @P INT, @E INT, @LINE NVARCHAR(MAX), @NRO INT;
WHILE @I <= @N
BEGIN
    SELECT @D = OBJECT_DEFINITION(oid), @NAME = nombre FROM @OBJS WHERE orden=@I;
    INSERT #O(linea) VALUES (N'--- '+@NAME);
    SET @TOTAL = DATALENGTH(@D)/2; SET @P = 1; SET @NRO = 0;
    WHILE @P <= @TOTAL
    BEGIN
        SET @E = CHARINDEX(NCHAR(10), @D, @P);
        IF @E = 0 SET @E = @TOTAL + 1;
        SET @LINE = SUBSTRING(@D, @P, @E-@P);
        SET @NRO = @NRO + 1;
        IF @LINE LIKE N'%BUFFER%' OR @LINE LIKE N'%(4000)%' OR @LINE LIKE N'%(8000)%'
            INSERT #O(linea) VALUES (N'  '+CONVERT(NVARCHAR(10),@NRO)+N': '+LTRIM(REPLACE(@LINE,NCHAR(13),N'')));
        SET @P = @E + 1;
    END;
    SET @I = @I + 1;
END;

SELECT linea FROM #O ORDER BY id;
