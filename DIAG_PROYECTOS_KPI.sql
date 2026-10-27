/* DIAG_PROYECTOS_KPI (solo lectura): muestra como arma VCT_MAIN_PROYECTOS el
   KPI "Proyectos activos" (soft-kpi) y su icono, para corregir el patch del icono.
   SSMS F5. Pegame Messages. */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS'));
DECLARE @POS INT, @INI INT, @KK INT, @TMP NVARCHAR(MAX);
IF @D IS NULL BEGIN PRINT 'NO EXISTE'; RETURN; END;
PRINT 'LARGO: '+CONVERT(VARCHAR(20),LEN(@D));
PRINT 'pos soft-kpi-icon : '+CONVERT(VARCHAR(20),CHARINDEX('soft-kpi-icon',@D));
PRINT 'pos soft-kpi      : '+CONVERT(VARCHAR(20),CHARINDEX('soft-kpi',@D));
PRINT 'pos Proyectos activos : '+CONVERT(VARCHAR(20),CHARINDEX('Proyectos activos',@D));
PRINT 'pos data-vct-icon : '+CONVERT(VARCHAR(20),CHARINDEX('data-vct-icon',@D));
SET @POS = CHARINDEX('soft-kpi',@D);
IF @POS=0 SET @POS=CHARINDEX('Proyectos activos',@D);
IF @POS=0 SET @POS=CHARINDEX('data-vct-icon',@D);
IF @POS=0 SET @POS=1;
SET @INI = CASE WHEN @POS>800 THEN @POS-800 ELSE 1 END;
SET @TMP = SUBSTRING(@D,@INI,5000);
SET @KK=1;
WHILE @KK<=LEN(@TMP) BEGIN PRINT SUBSTRING(@TMP,@KK,3500); SET @KK=@KK+3500; END;
PRINT '################ FIN ################';
