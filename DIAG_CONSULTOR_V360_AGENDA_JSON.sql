:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_CONSULTOR_V360_AGENDA_JSON.txt
/* ============================================================================
   DIAG_CONSULTOR_V360_AGENDA_JSON  (solo lectura)
   Muestra como arma dbo.VCT_MAIN_CONSULTORES_V360 el JSON de dias del calendario
   (@V360_AGC_DIAS), para sumarle hcf / hpe igual que en la Agenda del consultor
   (AGENDA_CAL_C_V1). SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'));
DECLARE @i INT = CHARINDEX(N'SET @V360_AGC_DIAS', @D);
IF @i = 0 SET @i = CHARINDEX(N'@V360_AGC_DIAS', @D);
SELECT LEN(@D) AS LARGO, @i AS POSICION;
/* 6000 caracteres desde la primera asignacion del JSON de dias (PRINT en tramos: SELECT corta a 256) */
DECLARE @T NVARCHAR(MAX) = SUBSTRING(@D, CASE WHEN @i > 300 THEN @i - 300 ELSE 1 END, 6000), @k INT = 1;
WHILE @k <= LEN(@T) BEGIN PRINT SUBSTRING(@T, @k, 3500); SET @k = @k + 3500; END;
