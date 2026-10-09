/* ========================================================================
   DUMP_OBJETOS - SOLO LECTURA. No modifica nada.
   Baja la definicion VIGENTE de todos los SP, funciones, vistas y triggers
   de la base a un archivo, para versionarlos en git (db/objetos/).

   USO (SSMS):
     1) Query > SQLCMD Mode (activarlo).
     2) Conectarse al servidor que se quiere bajar (desarrollo o produccion).
     3) F5. Termina con "DUMP OK" en Messages.
     4) Avisar: se corre  python tools\split_dump.py  y queda un .sql por objeto
        en db\objetos\ (git muestra que cambio desde la ultima vez).
   ======================================================================== */
:OUT C:\Users\Usuario\Desktop\muhle-vct\db\_dump\DUMP_OBJETOS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @OBJS TABLE (orden INT IDENTITY(1,1), oid INT, nombre SYSNAME, tipo VARCHAR(10));
INSERT @OBJS(oid, nombre, tipo)
SELECT o.object_id, SCHEMA_NAME(o.schema_id) + N'.' + o.name, RTRIM(o.type)
FROM sys.objects o
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P','FN','IF','TF','V','TR')
ORDER BY o.name;

PRINT '--@@SERVIDOR ' + @@SERVERNAME + ' | ' + CONVERT(VARCHAR(20), GETDATE(), 120);

DECLARE @I INT = 1, @N INT = (SELECT COUNT(*) FROM @OBJS), @D NVARCHAR(MAX), @NAME SYSNAME, @T VARCHAR(10),
        @TOTAL INT, @P INT, @E INT, @LINE NVARCHAR(MAX);
WHILE @I <= @N
BEGIN
    SELECT @D = OBJECT_DEFINITION(oid), @NAME = nombre, @T = tipo FROM @OBJS WHERE orden = @I;
    PRINT '--@@OBJ ' + @T + ' ' + @NAME;
    IF @D IS NOT NULL
    BEGIN
        SET @TOTAL = DATALENGTH(@D) / 2; SET @P = 1;
        WHILE @P <= @TOTAL
        BEGIN
            SET @E = CHARINDEX(NCHAR(10), @D, @P);
            IF @E = 0 SET @E = @TOTAL + 1;
            SET @LINE = SUBSTRING(@D, @P, @E - @P);
            IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
                SET @LINE = SUBSTRING(@LINE, 1, DATALENGTH(@LINE) / 2 - 1);
            IF DATALENGTH(@LINE) / 2 <= 3500
                PRINT @LINE;
            ELSE
            BEGIN
                /* PRINT corta a 4000: las lineas largas van en trozos que el script de python vuelve a unir */
                PRINT '--@@LARGA';
                WHILE DATALENGTH(@LINE) / 2 > 0
                BEGIN
                    PRINT SUBSTRING(@LINE, 1, 3500);
                    SET @LINE = SUBSTRING(@LINE, 3501, 2147483647);
                END;
                PRINT '--@@FINLARGA';
            END;
            SET @P = @E + 1;
        END;
    END;
    PRINT '--@@FINOBJ';
    SET @I = @I + 1;
END;
PRINT '--@@DUMP OK ' + CONVERT(VARCHAR(10), @N) + ' objetos';
