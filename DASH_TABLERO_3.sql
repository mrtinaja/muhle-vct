/* ============================================================================
   DASH_TABLERO_3  (29/10/2026)  marca DASH_TAB_V3  (requiere DASH_TAB_V2)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD:
   - Subtitulo del encabezado: "Dashboard Perfil <perfil que ingresa>" (todos los perfiles).
   - Tablero del consultor: barra solo con Tablero / Graficos / Personalizar; filtros debajo con el
     estilo de las grillas (mes, cliente, proyecto, buscar); grillas institucionales.
   Assets: css/vct-tablero.css ?v=3 y js/vct-tablero.js ?v=3 (subir los dos).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V3', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V3 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V2', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_2 (marca DASH_TAB_V2). No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* subt_decl */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'    /* ---------- shell y sidebar ---------- */';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'    /* DASH_TAB_V3: subtitulo ''Dashboard Perfil <perfil>'' (nombre del perfil en Groups; si viene en mayusculas, con mayuscula inicial) */' + NCHAR(10) + N'    DECLARE @DB_PERF NVARCHAR(200) = (SELECT TOP 1 LTRIM(RTRIM(G.Name)) FROM dbo.Groups G WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(G.Id))) = UPPER(LTRIM(RTRIM(@IUNIDAD))));' + NCHAR(10) + N'    SET @DB_PERF = ISNULL(NULLIF(@DB_PERF, N''''), LTRIM(RTRIM(ISNULL(@IUNIDAD, ''''))));' + NCHAR(10) + N'    IF @DB_PERF COLLATE Latin1_General_CS_AS = UPPER(@DB_PERF) SET @DB_PERF = UPPER(LEFT(@DB_PERF, 1)) + LOWER(SUBSTRING(@DB_PERF, 2, 200));' + NCHAR(10) + N'    DECLARE @DB_SUBT VARCHAR(300) = ''Dashboard Perfil '' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(200), @DB_PERF), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'');' + NCHAR(10) + N'    /* ---------- shell y sidebar ---------- */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' subt_decl'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* subt_use */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@SUBTITLE = ''Indicadores seg&uacute;n tu perfil.'',';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@SUBTITLE = @DB_SUBT,';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' subt_use'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* css */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=2';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=3';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' css'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=2';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=3';
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V3). Subir css/vct-tablero.css y js/vct-tablero.js (?v=3).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
