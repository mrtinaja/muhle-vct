/* INICIO_PERFIL_4_CSS_V5: el Inicio carga vct-inicio.css v5 (margenes en celular).
   Subir antes vct-inicio.css. Se puede volver a correr. */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD'));
IF CHARINDEX(N'vct-inicio.css?v=4', @D) = 0
    PRINT 'VCT_MAIN_DASHBOARD no carga vct-inicio.css?v=4 (ya actualizado?). Sin cambios.';
ELSE
BEGIN
    SET @D = REPLACE(@D, N'vct-inicio.css?v=4', N'vct-inicio.css?v=5');
    DECLARE @kp INT = CHARINDEX(N'PROCEDURE', @D), @kpre NVARCHAR(60);
    SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
    IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
        SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK: VCT_MAIN_DASHBOARD carga vct-inicio.css v5.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE() + ' (sin cambios)';
    END CATCH;
END;
GO
