/* ============================================================================
   DIAG_V360_ROWMENU  (solo lectura)
   Vuelca el markup del menu de 3 puntos (row-menu-trigger) de VCT_MAIN_PROYECTO_V360,
   para ver QUE acciones tiene y copiarlo a la tabla de Proyectos.
   SSMS F5. Pegame Messages.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @DEFV NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @POS INT, @INI INT, @KK INT, @TMP NVARCHAR(MAX);

IF @DEFV IS NULL BEGIN PRINT 'NO EXISTE VCT_MAIN_PROYECTO_V360'; RETURN; END;
PRINT 'LARGO: '+CONVERT(VARCHAR(20),LEN(@DEFV));
PRINT 'pos row-menu-trigger: '+CONVERT(VARCHAR(20),CHARINDEX('row-menu-trigger',@DEFV));

SET @POS = CHARINDEX('row-menu-trigger',@DEFV);
IF @POS=0 SET @POS=1;
/* arrancar un poco antes para ver el <td> y el boton completo + los items del menu */
SET @INI = CASE WHEN @POS>1200 THEN @POS-1200 ELSE 1 END;
SET @TMP = SUBSTRING(@DEFV,@INI,6000);
SET @KK=1;
WHILE @KK<=LEN(@TMP) BEGIN PRINT SUBSTRING(@TMP,@KK,3500); SET @KK=@KK+3500; END;
PRINT '################ FIN ################';
