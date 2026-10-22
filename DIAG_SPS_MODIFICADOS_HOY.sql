:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_SPS_MODIFICADOS_HOY.txt
/* ============================================================================
   DIAG_SPS_MODIFICADOS_HOY  (solo lectura)
   1) Lista los SP / funciones modificados en los ultimos 2 dias + los 3 que tocamos (quien toco que y cuando).
   2) Vuelca la definicion VIVA de cada uno, para traerla al repo y no pisar
      los cambios de Martin con un script que reemplace el SP entero.
   SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

SELECT o.name, o.type_desc, o.create_date, o.modify_date
FROM sys.objects o
WHERE o.type IN ('P','FN','IF','TF') AND (o.modify_date >= DATEADD(DAY, -2, CONVERT(DATE, GETDATE())) OR o.name IN ('VCT_MAIN_PROYECTO_V360','VCT_MAIN_AGENDA_CONSULTOR','VCT_MAIN_CONSULTORES_V360'))
ORDER BY o.modify_date DESC;

DECLARE @n SYSNAME, @D NVARCHAR(MAX), @k INT;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT o.name FROM sys.objects o
    WHERE o.type IN ('P','FN','IF','TF') AND (o.modify_date >= DATEADD(DAY, -2, CONVERT(DATE, GETDATE())) OR o.name IN ('VCT_MAIN_PROYECTO_V360','VCT_MAIN_AGENDA_CONSULTOR','VCT_MAIN_CONSULTORES_V360'))
    ORDER BY o.modify_date DESC;
OPEN c; FETCH NEXT FROM c INTO @n;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @n));
    PRINT '-- ===================================================================';
    PRINT '-- ' + @n + '  (largo ' + CONVERT(VARCHAR(20), LEN(@D)) + ')';
    PRINT '-- ===================================================================';
    SET @k = 1;
    WHILE @k <= LEN(@D) BEGIN PRINT SUBSTRING(@D, @k, 3500); SET @k = @k + 3500; END;
    PRINT 'GO';
    FETCH NEXT FROM c INTO @n;
END;
CLOSE c; DEALLOCATE c;
