/* ============================================================================
   FIX_CALENDARIO_360_ASSETS
   ----------------------------------------------------------------------------
   Repunta el calendario EMBEBIDO de las fichas 360 (helper dbo.VCT_CALENDAR_V360_RENDER)
   al JS/CSS unificado. Reemplaza el NOMBRE DE ARCHIVO conservando el ?v (asi
   funciona sea cual sea la version viva: v3, v31, 20261016-2, etc.):
       vct-agenda-consultor.css  -> vct-calendario.css
       vct-agenda.css            -> vct-calendario.css
       vct-agenda-consultor.js   -> vct-calendario.js
       vct-agenda.js             -> vct-calendario.js
   (Los nombres "vct-agenda.css" y "vct-agenda-consultor.css" son substrings
   distintos, no se pisan entre si.)

   Surgical REPLACE + ALTER robusto. Re-ejecutable.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Name SYSNAME = N'dbo.VCT_CALENDAR_V360_RENDER';
IF OBJECT_ID(@Name) IS NULL
BEGIN
    PRINT 'No existe dbo.VCT_CALENDAR_V360_RENDER (correr CALENDARIOS_1_INSTALAR primero). Sin cambios.';
    RETURN;
END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@Name));
DECLARE @orig NVARCHAR(MAX) = @D;

SET @D = REPLACE(@D, N'vct-agenda-consultor.css', N'vct-calendario.css');
SET @D = REPLACE(@D, N'vct-agenda-consultor.js',  N'vct-calendario.js');
SET @D = REPLACE(@D, N'vct-agenda.css',           N'vct-calendario.css');
SET @D = REPLACE(@D, N'vct-agenda.js',            N'vct-calendario.js');

IF @D = @orig
BEGIN
    PRINT 'VCT_CALENDAR_V360_RENDER: no referencia vct-agenda*.css/js (ya repuntado?). Sin cambios.';
    RETURN;
END;

/* ---- CREATE [OR ALTER] ... -> ALTER (ancla en el CREATE real, no en PROCEDURE/FUNCTION) ---- */
DECLARE @up NVARCHAR(MAX) = UPPER(@D);
DECLARE @cp INT = 0, @scan INT = 1, @probe INT;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE ... PROCEDURE.',16,1); RETURN; END;

IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER'
    SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE
    SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: VCT_CALENDAR_V360_RENDER repuntado a vct-calendario (css/js).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al aplicar: %s',16,1,@e);
END CATCH;
GO
