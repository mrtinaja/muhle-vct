/* ============================================================================
   FIX_CALENDARIO_ASSETS
   ----------------------------------------------------------------------------
   Repunta la pantalla "Calendario"/feriados (dbo.VCT_MAIN_CALENDARIO) al par
   UNIFICADO de assets de calendario:
       vct-agenda.css?v=11  ->  vct-calendario.css?v=1
       vct-agenda.js?v=10   ->  vct-calendario.js?v=1
   (El consultor y el embebido 360 se repuntan por sus propios scripts:
    AGENDA_CONSULTOR_3_PANTALLA.sql y CALENDARIOS_1_INSTALAR.sql.)

   Surgical REPLACE sobre la definicion vigente + CREATE->ALTER. Re-ejecutable:
   si ya apunta a vct-calendario, avisa y no toca nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Name SYSNAME = N'dbo.VCT_MAIN_CALENDARIO';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@Name));
DECLARE @P INT, @CreatePos INT, @AlterPos INT, @Start INT, @Prefix NVARCHAR(MAX), @Changed BIT = 0;

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

/* CREATE -> ALTER en la cabecera */
SET @P = CHARINDEX(N'PROCEDURE', UPPER(@D));
IF @P = 0 BEGIN RAISERROR('No se identifico PROCEDURE.',16,1); RETURN; END;
SET @Prefix = LEFT(@D, @P - 1);
SET @CreatePos = CHARINDEX(REVERSE(N'CREATE'), REVERSE(UPPER(@Prefix)));
SET @AlterPos  = CHARINDEX(REVERSE(N'ALTER'),  REVERSE(UPPER(@Prefix)));
SET @CreatePos = CASE WHEN @CreatePos > 0 THEN DATALENGTH(@Prefix)/2 - @CreatePos - 4 ELSE 0 END;
SET @AlterPos  = CASE WHEN @AlterPos  > 0 THEN DATALENGTH(@Prefix)/2 - @AlterPos  - 3 ELSE 0 END;
SET @Start = CASE WHEN @CreatePos > 0 AND @P - @CreatePos <= 40 THEN @CreatePos
                  WHEN @AlterPos  > 0 AND @P - @AlterPos  <= 40 THEN @AlterPos ELSE 0 END;
IF @Start = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE/ALTER.',16,1); RETURN; END;
SET @D = STUFF(@D, @Start, @P - @Start, N'ALTER ');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: VCT_MAIN_CALENDARIO repuntado a vct-calendario.css/js?v=1.';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al aplicar: %s',16,1,@e);
END CATCH;
GO
