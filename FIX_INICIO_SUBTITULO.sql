/* ============================================================================
   FIX_INICIO_SUBTITULO
   ----------------------------------------------------------------------------
   Corrige SOLO el subtitulo de la pantalla INICIO (dbo.VCT_MAIN_DASHBOARD):
   hoy pasa 'Indicadores seg&uacute;n tu perfil.' a VCT_GET_SHELL, y
   VCT_GET_HEADER escapa el '&' (-> '&amp;'), por eso se ve el literal
   "&uacute;". Se reemplaza la entidad por el caracter real (NCHAR 250 = u con
   tilde). NO toca el grafico ni nada mas.

   Trabaja por REPLACE sobre la definicion vigente y re-crea con ALTER.
   Re-ejecutable: si ya esta corregido, avisa y no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Name SYSNAME = N'dbo.VCT_MAIN_DASHBOARD';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@Name));
DECLARE @P INT, @CreatePos INT, @AlterPos INT, @Start INT, @Prefix NVARCHAR(MAX);

IF @D IS NULL
BEGIN
    RAISERROR('No se pudo leer la definicion de %s.',16,1,@Name);
    RETURN;
END;

IF CHARINDEX(N'Indicadores seg&uacute;n tu perfil.', @D) = 0
BEGIN
    PRINT 'El subtitulo ya esta corregido (o cambio el texto). Sin cambios.';
    RETURN;
END;

SET @D = REPLACE(@D, N'Indicadores seg&uacute;n tu perfil.',
                     N'Indicadores seg' + NCHAR(250) + N'n tu perfil.');

/* CREATE -> ALTER solo en la cabecera */
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
    PRINT 'OK: subtitulo de Inicio corregido (segun, sin &uacute;).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al aplicar: %s',16,1,@e);
END CATCH;
GO
