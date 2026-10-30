/* ============================================================================
   DASH_TABLERO_8  (29/10/2026)  marca DASH_TAB_V8  (requiere DASH_TAB_V7)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD - Tablero del consultor, Mis proyectos:
   - Normas: el alta graba ESTADO = 'ACTIVA' y V7 filtraba 'ACTIVO' -> no salia ninguna. Ahora solo se excluyen las de baja.
   - Assets ?v=8: sin detalle por fila, sin detallar como badge circular, fecha de proxima visita mas chica.
   Correr DESPUES de DASH_TABLERO_7. Subir css/vct-tablero.css y js/vct-tablero.js. SSMS: F5. Re-ejecutable.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V8', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V8 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V7', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_7 (marca DASH_TAB_V7): correrlo primero. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* normas */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'UPPER(ISNULL(PN.ESTADO, ''ACTIVO'')) = ''ACTIVO''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'UPPER(ISNULL(PN.ESTADO, '''')) NOT LIKE ''INACTIV%'' AND UPPER(ISNULL(PN.ESTADO, '''')) NOT IN (''BAJA'', ''ANULADA'', ''ANULADO'', ''ELIMINADA'', ''ELIMINADO'')';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' normas'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* css */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=7';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=8';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' css'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=7';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=8';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' js'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V8). Subir css/vct-tablero.css y js/vct-tablero.js (?v=8).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
