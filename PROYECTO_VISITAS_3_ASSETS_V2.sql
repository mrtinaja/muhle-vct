/* ========================================================================
   PROYECTO_VISITAS_3_ASSETS_V2
   La Vista 360 de Proyecto pasa a cargar vct-proyecto-visitas.js/.css v2
   (detalle legible en celular; "Ver todas" solo cuando hay mas de 15).
   Subir antes los dos archivos. Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT;

IF CHARINDEX(N'vct-proyecto-visitas.js?v=1', @D) = 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360: ya estaba en v2 (o no tiene las visitas). Sin cambios.';
    RETURN;
END;

SET @D = REPLACE(REPLACE(@D, N'vct-proyecto-visitas.js?v=1', N'vct-proyecto-visitas.js?v=2'),
                             N'vct-proyecto-visitas.css?v=1', N'vct-proyecto-visitas.css?v=2');

DECLARE @p INT = CHARINDEX(N'PROCEDURE', @D), @pre NVARCHAR(60);
IF @p > 0
BEGIN
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTO_V360 carga vct-proyecto-visitas v2.';
GO
