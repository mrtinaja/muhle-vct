/* ============================================================================
   FIX_INICIO_1_SUBTITULO_Y_CHART
   ----------------------------------------------------------------------------
   Corrige dos cosas de la pantalla INICIO (dbo.VCT_MAIN_DASHBOARD), sobre la
   definicion VIGENTE del servidor:

   1) SUBTITULO: hoy pasa 'Indicadores seg&uacute;n tu perfil.' a VCT_GET_SHELL.
      VCT_GET_HEADER escapa el '&' (-> '&amp;'), por eso se ve el literal
      "&uacute;". Se reemplaza la entidad por el caracter real (u-acute).

   2) GRAFICO (celular): las etiquetas de meses (.vct-dash-vlbl) de las barras
      verticales se superponen en pantallas chicas. Se agregan reglas al
      @media (max-width:640px) para rotarlas -55 grados y achicarlas.

   Trabaja por REPLACE sobre la definicion y re-crea el SP con ALTER (misma
   tecnica que el instalador de Resumen). Re-ejecutable: si ya esta aplicado,
   avisa y no toca nada. No cambia consultas, permisos ni calculos.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
DECLARE @Name SYSNAME = N'dbo.VCT_MAIN_DASHBOARD';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@Name));
DECLARE @P INT, @CreatePos INT, @AlterPos INT, @Start INT, @Prefix NVARCHAR(MAX), @Changed BIT = 0;

IF @D IS NULL
BEGIN
    RAISERROR('No se pudo leer la definicion de %s (revisar nombre / permiso VIEW DEFINITION).',16,1,@Name);
    RETURN;
END;

/* 1) subtitulo: entidad &uacute; -> caracter real (NCHAR 250 = u con tilde) */
IF CHARINDEX(N'Indicadores seg&uacute;n tu perfil.', @D) > 0
BEGIN
    SET @D = REPLACE(@D, N'Indicadores seg&uacute;n tu perfil.',
                         N'Indicadores seg' + NCHAR(250) + N'n tu perfil.');
    SET @Changed = 1;
END;

/* 2) grafico en celular: rotar y achicar las etiquetas de meses */
IF CHARINDEX(N'transform:rotate(-55deg)', @D) = 0
   AND CHARINDEX(N'@media (max-width:640px){.vct-dash-vval{display:none}.vct-dash-hrow{grid-template-columns:minmax(0,45%) minmax(0,1fr) auto}}', @D) > 0
BEGIN
    SET @D = REPLACE(@D,
        N'@media (max-width:640px){.vct-dash-vval{display:none}.vct-dash-hrow{grid-template-columns:minmax(0,45%) minmax(0,1fr) auto}}',
        N'@media (max-width:640px){.vct-dash-vval{display:none}.vct-dash-hrow{grid-template-columns:minmax(0,45%) minmax(0,1fr) auto}.vct-dash-vbars{padding-bottom:28px}.vct-dash-vcol{overflow:visible}.vct-dash-vlbl{font-size:8.5px;margin-top:10px;transform:rotate(-55deg);transform-origin:center top}}');
    SET @Changed = 1;
END;

IF @Changed = 0
BEGIN
    PRINT 'Nada que corregir en VCT_MAIN_DASHBOARD (ya aplicado).';
    RETURN;
END;

/* CREATE -> ALTER solo en la cabecera (mirando las 40 letras antes de PROCEDURE) */
SET @P = CHARINDEX(N'PROCEDURE', UPPER(@D));
IF @P = 0
BEGIN
    RAISERROR('No se identifico PROCEDURE en la definicion. Se cancela.',16,1);
    RETURN;
END;
SET @Prefix = LEFT(@D, @P - 1);
SET @CreatePos = CHARINDEX(REVERSE(N'CREATE'), REVERSE(UPPER(@Prefix)));
SET @AlterPos  = CHARINDEX(REVERSE(N'ALTER'),  REVERSE(UPPER(@Prefix)));
SET @CreatePos = CASE WHEN @CreatePos > 0 THEN DATALENGTH(@Prefix)/2 - @CreatePos - 4 ELSE 0 END;
SET @AlterPos  = CASE WHEN @AlterPos  > 0 THEN DATALENGTH(@Prefix)/2 - @AlterPos  - 3 ELSE 0 END;
SET @Start = CASE WHEN @CreatePos > 0 AND @P - @CreatePos <= 40 THEN @CreatePos
                  WHEN @AlterPos  > 0 AND @P - @AlterPos  <= 40 THEN @AlterPos ELSE 0 END;
IF @Start = 0
BEGIN
    RAISERROR('No se identifico la cabecera CREATE/ALTER. Se cancela.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @Start, @P - @Start, N'ALTER ');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: VCT_MAIN_DASHBOARD corregido (subtitulo sin &uacute; + labels del grafico rotados en celular).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al aplicar el ALTER: %s',16,1,@e);
END CATCH;
GO
