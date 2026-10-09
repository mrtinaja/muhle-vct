/* ========================================================================
   PROYECTO_ALTA_6_JS_V2
   ------------------------------------------------------------------------
   La Vista 360 de Cliente pasa a cargar vct-proyecto-alta.js v2
   (selector de normas: el menu abre en cada clic, Enter toma la opcion
   bajo el mouse, al reabrir el alta se limpian chips y servicios).
   SUBIR ANTES assets/js/vct-proyecto-alta.js al servidor (/js/).
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CLIENTES_V360'));
IF @D IS NULL
    PRINT 'No existe dbo.VCT_MAIN_CLIENTES_V360.';
ELSE IF CHARINDEX(N'vct-proyecto-alta.js?v=1', @D) = 0
    PRINT 'VCT_MAIN_CLIENTES_V360 no carga vct-proyecto-alta.js?v=1 (ya actualizado?). Sin cambios.';
ELSE
BEGIN
    SET @D = REPLACE(@D, N'vct-proyecto-alta.js?v=1', N'vct-proyecto-alta.js?v=2');
    /* CREATE -> ALTER solo en el encabezado (las 40 letras antes de PROCEDURE) */
    DECLARE @kp INT = CHARINDEX(N'PROCEDURE', @D), @kpre NVARCHAR(60);
    SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
    IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
        SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK: VCT_MAIN_CLIENTES_V360 carga vct-proyecto-alta.js v2.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE() + ' (sin cambios)';
    END CATCH;
END;
GO
