/* ============================================================================
   VISITAS_FIX_ALTA  (28/10/2026)  -- solo sube la version del js de la V360 del proyecto (v44 -> v45)
   ----------------------------------------------------------------------------
   Arregla el alta / edicion de visitas (boton Agregar de la lista y "+" del calendario), que dejo de abrir
   el modal por un error del js de los filtros de Visitas. Subir js/vct-proyecto-v360.js (v45).
   No cambia la logica del SP. Re-ejecutable.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'vct-proyecto-v360.js?v=45', @D) > 0
    PRINT 'OK   el parche vct-proyecto-v360.js?v=45 ya estaba aplicado: no se hizo nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.js?v=44"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.js?v=45"';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' assets'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    IF @F <> N''
        PRINT 'FALLO: no se encontraron (o estan repetidos) en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 carga vct-proyecto-v360.js v45. Subir el js.';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
