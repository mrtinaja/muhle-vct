:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_HORAS_DIA.txt
/* DIAG_HORAS_DIA: donde se usan las horas planificadas de las visitas (solo lectura, no cambia nada).
   SSMS: Query > SQLCMD Mode, F5. */
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== 1. COLUMNAS DE VCT_PROYECTOS_VISITAS_CONSULTORES ===';
SELECT LEFT(c.name, 30) AS COLUMNA, LEFT(t.name, 15) AS TIPO, c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES') ORDER BY c.column_id;
SELECT LEFT(name, 60) AS INDICE_O_CLAVE, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES') AND name IS NOT NULL;
SELECT LEFT(fk.name, 60) AS FK, LEFT(OBJECT_NAME(fk.referenced_object_id), 40) AS REFERENCIA FROM sys.foreign_keys fk WHERE fk.parent_object_id = OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES');
SELECT LEFT(name, 60) AS TRIGGER_TABLA, is_disabled FROM sys.triggers WHERE parent_id IN (OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES'), OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS'));
PRINT 'Existe VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS: ' + CASE WHEN OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS') IS NULL THEN 'NO' ELSE 'SI' END;

PRINT '';
PRINT '=== 2. OBJETOS QUE USAN LAS HORAS DE LA VISITA ===';
SELECT LEFT(o.name, 50) AS OBJETO, o.type_desc, CONVERT(VARCHAR(16), o.modify_date, 120) AS MODIFICADO, LEN(m.definition) AS LARGO,
       CASE WHEN m.definition LIKE '%HORAS_PLANIFICADAS%' THEN 'SI' ELSE '' END AS USA_HORAS_PLANIF,
       CASE WHEN m.definition LIKE '%HORAS_EJECUTADAS%' THEN 'SI' ELSE '' END AS USA_HORAS_EJEC
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%VCT_PROYECTOS_VISITAS_CONSULTORES%' OR m.definition LIKE '%HORAS_PLANIFICADAS%'
ORDER BY o.name;

/* 3. definicion completa de cada uno (menos VCT_MAIN_PROYECTO_V360, que ya tengo) */
DECLARE @NAME SYSNAME, @D NVARCHAR(MAX), @TOTAL INT, @P INT, @E INT, @LINE NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT 'dbo.' + o.name FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
    WHERE (m.definition LIKE '%VCT_PROYECTOS_VISITAS_CONSULTORES%' OR m.definition LIKE '%HORAS_PLANIFICADAS%')
      AND o.name NOT IN ('VCT_MAIN_PROYECTO_V360') AND o.name NOT LIKE 'VCT_MIGRAR%'
    ORDER BY o.name;
OPEN c; FETCH NEXT FROM c INTO @NAME;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '';
    PRINT '=== DEFINICION ' + @NAME + ' ===';
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));
    SET @TOTAL = DATALENGTH(@D) / 2; SET @P = 1;
    WHILE @P <= @TOTAL
    BEGIN
        SET @E = CHARINDEX(NCHAR(10), @D, @P);
        IF @E = 0 SET @E = @TOTAL + 1;
        SET @LINE = SUBSTRING(@D, @P, @E - @P);
        IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13) SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
        WHILE (DATALENGTH(@LINE) / 2) > 4000 BEGIN PRINT SUBSTRING(@LINE, 1, 4000); SET @LINE = SUBSTRING(@LINE, 4001, 1000000); END;
        PRINT @LINE;
        SET @P = @E + 1;
    END;
    FETCH NEXT FROM c INTO @NAME;
END;
CLOSE c; DEALLOCATE c;
