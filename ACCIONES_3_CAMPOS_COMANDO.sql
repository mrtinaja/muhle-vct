/* ACCIONES_3_CAMPOS_COMANDO: el boton Cumplida / Reabrir de Acciones no llegaba
   al SP: el salto (goto) envia los campos del formulario y la pagina no tenia
   SP.TEXTO30 / IDSELEC03 / TEXTO11 / FLAG01. Se agregan como ocultos.
   Se puede volver a correr. */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_ACCIONES'));
DECLARE @MK NVARCHAR(200) = N'''<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="">''';
IF @D IS NULL
    PRINT 'No existe dbo.VCT_MAIN_ACCIONES.';
ELSE IF CHARINDEX(N'name="SP.TEXTO30"', @D) > 0
    PRINT 'VCT_MAIN_ACCIONES ya tenia los campos del comando.';
ELSE IF CHARINDEX(@MK, @D) = 0
    PRINT 'No se encontro el campo IDSELEC02 en VCT_MAIN_ACCIONES. Sin cambios.';
ELSE
BEGIN
    SET @D = REPLACE(@D, @MK, @MK + N'
      + ''<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">''
      + ''<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">''
      + ''<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value="">''
      + ''<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">''');
    DECLARE @kp INT = CHARINDEX(N'PROCEDURE', @D), @kpre NVARCHAR(60);
    SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
    IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
        SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK: Acciones con los campos del comando.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE() + ' (sin cambios)';
    END CATCH;
END;
GO
