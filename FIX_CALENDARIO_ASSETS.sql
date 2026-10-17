/* ============================================================================
   FIX_CALENDARIO_ASSETS  (v2 - deteccion de cabecera robusta)
   ----------------------------------------------------------------------------
   Repunta la pantalla "Calendario"/feriados (dbo.VCT_MAIN_CALENDARIO) al par
   UNIFICADO de assets:
       vct-agenda.css?v=11  ->  vct-calendario.css?v=1
       vct-agenda.js?v=10   ->  vct-calendario.js?v=1

   v2: la deteccion CREATE->ALTER ya NO se ancla en 'PROCEDURE' (el comentario de
   este SP contiene "DROP PROCEDURE dbo.VCT_MAIN_AGENDA", que confundia al patch).
   Ahora busca el primer 'CREATE' seguido de 'PROC' y soporta CREATE OR ALTER.

   Surgical REPLACE + ALTER. Re-ejecutable.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Name SYSNAME = N'dbo.VCT_MAIN_CALENDARIO';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@Name));
DECLARE @Changed BIT = 0;

IF @D IS NULL
BEGIN
    RAISERROR('No se pudo leer %s (revisar nombre / VIEW DEFINITION).',16,1,@Name);
    RETURN;
END;

IF CHARINDEX(N'vct-agenda.css?v=11', @D) > 0
BEGIN SET @D = REPLACE(@D, N'vct-agenda.css?v=11', N'vct-calendario.css?v=1'); SET @Changed = 1; END;
IF CHARINDEX(N'vct-agenda.js?v=10', @D) > 0
BEGIN SET @D = REPLACE(@D, N'vct-agenda.js?v=10',  N'vct-calendario.js?v=1');  SET @Changed = 1; END;

IF @Changed = 0
BEGIN
    PRINT 'VCT_MAIN_CALENDARIO: no se encontro vct-agenda.css?v=11 / vct-agenda.js?v=10.';
    PRINT 'Puede que ya este repuntado, o que el ?v vigente sea otro (avisar para ajustar).';
    RETURN;
END;

/* ---- CREATE [OR ALTER] PROCEDURE -> ALTER PROCEDURE (robusto) ---- */
DECLARE @up NVARCHAR(MAX) = UPPER(@D);
DECLARE @cp INT = 0, @scan INT = 1, @probe INT;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 30 BREAK;  /* este CREATE es el de la cabecera */
    SET @scan = @cp + 6;
END;

IF @cp = 0
BEGIN
    RAISERROR('No se identifico la cabecera CREATE ... PROCEDURE.',16,1);
    RETURN;
END;

IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER'
    SET @D = STUFF(@D, @cp, 15, N'ALTER');   /* CREATE OR ALTER PROCEDURE -> ALTER PROCEDURE */
ELSE
    SET @D = STUFF(@D, @cp, 6, N'ALTER');     /* CREATE PROCEDURE -> ALTER PROCEDURE */

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: VCT_MAIN_CALENDARIO repuntado a vct-calendario.css/js?v=1.';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al aplicar: %s',16,1,@e);
END CATCH;
GO
