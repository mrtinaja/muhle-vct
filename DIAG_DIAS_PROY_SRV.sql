/* ============================================================================
   DIAG_DIAS_PROY_SRV  v2 (solo lectura, PRINT-based)
   Muestra COMO la Agenda del consultor mete proy/srv en los dias del calendario,
   para calcarlo en VCT_MAIN_CONSULTORES_V360. SSMS F5. Pegame Messages.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @A NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR'));
DECLARE @p INT, @ini INT, @k INT;

PRINT '################ VCT_MAIN_AGENDA_CONSULTOR - mapa de anclas ################';
IF @A IS NULL BEGIN PRINT '  !!! NO EXISTE'; RETURN; END;
PRINT '  LARGO: ' + CONVERT(VARCHAR(20), LEN(@A));
PRINT '  pos CONSULTOR_RANGO  : ' + CONVERT(VARCHAR(20), CHARINDEX('CONSULTOR_RANGO', @A));
PRINT '  pos ''"proy"''          : ' + CONVERT(VARCHAR(20), CHARINDEX('"proy"', @A));
PRINT '  pos ''proy":''          : ' + CONVERT(VARCHAR(20), CHARINDEX('proy":', @A));
PRINT '  pos ''"srv"''           : ' + CONVERT(VARCHAR(20), CHARINDEX('"srv"', @A));
PRINT '  pos ACTS_JSON        : ' + CONVERT(VARCHAR(20), CHARINDEX('ACTS_JSON', @A));
PRINT '  pos VISITAS          : ' + CONVERT(VARCHAR(20), CHARINDEX('VISITAS', @A));
PRINT '  pos OUTER APPLY      : ' + CONVERT(VARCHAR(20), CHARINDEX('OUTER APPLY', @A));

/* elegir el mejor ancla: donde arma el JSON de dias (CONSULTOR_RANGO) */
SET @p = CHARINDEX('CONSULTOR_RANGO', @A);
IF @p = 0 SET @p = CHARINDEX('"proy"', @A);
IF @p = 0 SET @p = CHARINDEX('proy":', @A);
IF @p = 0 SET @p = 1;

PRINT '';
PRINT '################ SECCION desde el ancla (9000 chars) ################';
SET @ini = CASE WHEN @p > 2500 THEN @p - 2500 ELSE 1 END;
DECLARE @T NVARCHAR(MAX) = SUBSTRING(@A, @ini, 9000);
SET @k = 1;
WHILE @k <= LEN(@T) BEGIN PRINT SUBSTRING(@T, @k, 3500); SET @k = @k + 3500; END;
PRINT '################ FIN ################';
