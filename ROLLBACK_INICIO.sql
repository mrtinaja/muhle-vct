/* ============================================================================
   ROLLBACK_INICIO  — deja VCT_MAIN_DASHBOARD como estaba antes del FIX de hoy.
   Revierte exactamente los 2 cambios de FIX_INICIO_1_SUBTITULO_Y_CHART.sql:
     - subtitulo: vuelve a 'Indicadores seg&uacute;n tu perfil.'
     - grafico:   saca la rotacion de labels del @media (max-width:640px)
   Re-ejecutable: si ya esta revertido, avisa y no toca nada.
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
    RAISERROR('No se pudo leer la definicion de %s.',16,1,@Name);
    RETURN;
END;

/* 1) subtitulo: caracter real -> entidad &uacute; (como estaba) */
IF CHARINDEX(N'Indicadores seg' + NCHAR(250) + N'n tu perfil.', @D) > 0
BEGIN
    SET @D = REPLACE(@D, N'Indicadores seg' + NCHAR(250) + N'n tu perfil.',
                         N'Indicadores seg&uacute;n tu perfil.');
    SET @Changed = 1;
END;

/* 2) grafico: sacar la rotacion (volver al @media original) */
IF CHARINDEX(N'transform:rotate(-55deg)', @D) > 0
BEGIN
    SET @D = REPLACE(@D,
        N'@media (max-width:640px){.vct-dash-vval{display:none}.vct-dash-hrow{grid-template-columns:minmax(0,45%) minmax(0,1fr) auto}.vct-dash-vbars{padding-bottom:28px}.vct-dash-vcol{overflow:visible}.vct-dash-vlbl{font-size:8.5px;margin-top:10px;transform:rotate(-55deg);transform-origin:center top}}',
        N'@media (max-width:640px){.vct-dash-vval{display:none}.vct-dash-hrow{grid-template-columns:minmax(0,45%) minmax(0,1fr) auto}}');
    SET @Changed = 1;
END;

IF @Changed = 0
BEGIN
    PRINT 'VCT_MAIN_DASHBOARD ya estaba en la version anterior (nada que revertir).';
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
    PRINT 'OK: VCT_MAIN_DASHBOARD revertido a la version anterior.';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error al revertir: %s',16,1,@e);
END CATCH;
GO
