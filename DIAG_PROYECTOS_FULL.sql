/* ============================================================================
   DIAG_PROYECTOS_FULL  (solo lectura)
   Vuelca la definicion COMPLETA de dbo.VCT_MAIN_PROYECTOS (ya con los iconos),
   para disenar el patch del menu 3 puntos (sacar el ojo, ⋮ a la derecha con
   Ver 360 + Editar) sobre la fila y la cabecera reales.
   SSMS F5. Pegame TODO el bloque de Messages.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS'));
DECLARE @KK INT = 1;
IF @D IS NULL BEGIN PRINT 'NO EXISTE VCT_MAIN_PROYECTOS'; RETURN; END;
PRINT '################ VCT_MAIN_PROYECTOS (LARGO '+CONVERT(VARCHAR(20),LEN(@D))+') ################';
WHILE @KK <= LEN(@D)
BEGIN
    PRINT SUBSTRING(@D, @KK, 3500);
    SET @KK = @KK + 3500;
END;
PRINT '################ FIN ################';
