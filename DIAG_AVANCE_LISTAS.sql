/* DIAG_AVANCE_LISTAS (solo lectura) - correr con Query > SQLCMD Mode
   Lineas de las Vista 360 de Cliente / Consultor / Empleado que leen el avance. */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_AVANCE_LISTAS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @n SYSNAME, @D NVARCHAR(MAX), @p INT, @e INT, @l NVARCHAR(MAX), @k INT;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM (VALUES ('VCT_MAIN_CLIENTES_V360'),('VCT_MAIN_CONSULTORES_V360'),('VCT_MAIN_EMPLEADOS_V360')) x(name);
OPEN c; FETCH NEXT FROM c INTO @n;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @n));
    SET @l = CONVERT(VARCHAR(20), (SELECT modify_date FROM sys.objects WHERE object_id = OBJECT_ID('dbo.' + @n)), 120);
    PRINT '=== ' + @n + CASE WHEN @D IS NULL THEN ' (NO EXISTE)' ELSE ' modificado ' + ISNULL(@l, '') END;
    SET @p = 1; SET @k = 0;
    WHILE @D IS NOT NULL AND @p <= LEN(@D)
    BEGIN
        SET @k = @k + 1;
        SET @e = CHARINDEX(NCHAR(10), @D, @p); IF @e = 0 SET @e = LEN(@D) + 1;
        SET @l = SUBSTRING(@D, @p, @e - @p);
        IF @l LIKE '%AVANCE%' OR @l LIKE '%FROM dbo.VCT_PROYECTOS %' OR @l LIKE '%JOIN dbo.VCT_PROYECTOS %' OR @l LIKE '%VCT_PROYECTOS P%'
            PRINT CONVERT(VARCHAR(6), @k) + ': ' + LEFT(REPLACE(@l, NCHAR(13), ''), 400);
        SET @p = @e + 1;
    END;
    FETCH NEXT FROM c INTO @n;
END;
CLOSE c; DEALLOCATE c;
GO
