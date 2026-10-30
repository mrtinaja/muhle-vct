/* ============================================================================
   DASH_TABLERO_6  (29/10/2026)  marca DASH_TAB_V6  (requiere DASH_TAB_V5)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD:
   - Subtitulo "Dashboard Perfil Consultor" cuando el Inicio arma la vista del consultor.
   - Assets del tablero ?v=6: indicadores fijos sin titulo, Para hacer y Mis proyectos como cards con titulo y
     plegado propio, Personalizar con vista previa esquematica, grillas inicializadas por el tablero.
   Subir css/vct-tablero.css y js/vct-tablero.js. SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V6', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V6 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V5', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_5 (marca DASH_TAB_V5). No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* subt */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'    SET @OUTPARAM1 = ISNULL(@HTML_SHELL, '''')';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'    /* DASH_TAB_V6: el subtitulo nombra la vista que arma el Inicio (el consultor puede estar en un grupo con otro nombre) */' + NCHAR(10) + N'    IF @VISTA = ''CONSULTOR'' AND ISNULL(@DB_SUBT, '''') <> '''' SET @HTML_SHELL = REPLACE(@HTML_SHELL, @DB_SUBT, ''Dashboard Perfil Consultor'');' + NCHAR(10) + N'    SET @OUTPARAM1 = ISNULL(@HTML_SHELL, '''')';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' subt'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* css */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=5';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=6';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' css'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=5';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=6';
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V6). Subir css/vct-tablero.css y js/vct-tablero.js (?v=6).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
