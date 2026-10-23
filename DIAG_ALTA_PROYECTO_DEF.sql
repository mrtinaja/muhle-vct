:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_ALTA_PROYECTO_DEF.txt
/* ============================================================================
   DIAG_ALTA_PROYECTO_DEF  (solo lectura)
   Vuelca la definicion VIVA (linea por linea) de los SP del alta de proyecto,
   para hacer los cambios sobre lo que esta en el servidor:
     - dbo.VCT_PROYECTO_ALTA_RENDER   (formulario)
     - dbo.VCT_PROYECTO_ALTA_GUARDAR  (grabacion)
   Cambios a hacer: adjuntar la propuesta comercial, sacar el nivel de riesgo,
   dias (horas / 8) en la seleccion de servicios.
   SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

SELECT o.name, o.modify_date, LEN(OBJECT_DEFINITION(o.object_id)) AS largo
FROM sys.objects o WHERE o.name IN ('VCT_PROYECTO_ALTA_RENDER','VCT_PROYECTO_ALTA_GUARDAR');

DECLARE @n SYSNAME, @D NVARCHAR(MAX), @p INT, @q INT, @L NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT N'dbo.VCT_PROYECTO_ALTA_RENDER' UNION ALL SELECT N'dbo.VCT_PROYECTO_ALTA_GUARDAR';
OPEN c; FETCH NEXT FROM c INTO @n;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @D = REPLACE(OBJECT_DEFINITION(OBJECT_ID(@n)), NCHAR(13), N'');
    PRINT N'-- ===================== ' + @n + N' =====================';
    IF @D IS NULL PRINT N'-- (no existe)';
    ELSE
    BEGIN
        SET @p = 1;
        WHILE @p <= LEN(@D) + 1
        BEGIN
            SET @q = CHARINDEX(NCHAR(10), @D, @p); IF @q = 0 SET @q = LEN(@D) + 1;
            SET @L = SUBSTRING(@D, @p, @q - @p);
            WHILE LEN(@L) > 3900 BEGIN PRINT LEFT(@L, 3900); SET @L = SUBSTRING(@L, 3901, LEN(@L)); END;
            PRINT @L;
            SET @p = @q + 1;
        END;
    END;
    PRINT N'GO';
    FETCH NEXT FROM c INTO @n;
END;
CLOSE c; DEALLOCATE c;
