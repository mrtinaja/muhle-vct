/* ============================================================================
   PLAN_CSS_V46  (27/10/2026)
   Solo cambia la version del css en dbo.VCT_MAIN_PROYECTO_V360: vct-proyecto-v360.css ?v=45 -> ?v=46
   (anillo del capitulo). Re-ejecutable: si ya esta en v46, avisa y no hace nada.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'vct-proyecto-v360.css?v=46"', @D) > 0
    PRINT 'OK   ya estaba en v46: no se hizo nada.';
ELSE IF CHARINDEX(N'vct-proyecto-v360.css?v=45"', @D) = 0
    PRINT 'FALLO: no se encontro vct-proyecto-v360.css?v=45 en el SP. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, N'vct-proyecto-v360.css?v=45"', N'vct-proyecto-v360.css?v=46"');
    SET @s = CHARINDEX(N'PROCEDURE', @D);
    SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
    IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
        SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
    BEGIN TRY
        EXEC sys.sp_executesql @D;
        PRINT 'OK   VCT_MAIN_PROYECTO_V360 ahora carga vct-proyecto-v360.css?v=46.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO al actualizar VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE();
    END CATCH;
END;
GO
