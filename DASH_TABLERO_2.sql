/* ============================================================================
   DASH_TABLERO_2  (29/10/2026)  marca DASH_TAB_V2  (requiere DASH_TAB_V1)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD - Tablero del consultor:
   - Se puede cambiar el mes (6 meses atras hasta 2 adelante): el SP manda agenda, visitas, desarrollo y
     acciones cerradas de todo ese rango; los indicadores los calcula js/vct-tablero.js por mes.
   - Agenda por dia con su capacidad; visitas con su servicio (CO / AU / CA).
   Assets: css/vct-tablero.css ?v=2 y js/vct-tablero.js ?v=2 (subir los dos).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V2', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V2 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V1', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_1 (marca DASH_TAB_V1). No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* has */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'SET @TB_HAS = CASE WHEN DATEADD(DAY, 56, @HOY) > @TB_MF THEN DATEADD(DAY, 56, @HOY) ELSE @TB_MF END;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'SET @TB_HAS = DATEADD(DAY, -1, DATEADD(MONTH, 3, @MES_INI));   /* DASH_TAB_V2: hasta fin del mes +2 */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' has'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* dia_w */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'D.FECHA BETWEEN @TB_DES AND @TB_HAS';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'D.FECHA >= @DESDE6';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' dia_w'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* dia_cap */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'CONVERT(VARCHAR(1), D.HAB) + @TB_N';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'CONVERT(VARCHAR(1), D.HAB) + @TB_T + REPLACE(CONVERT(VARCHAR(30), CONVERT(DECIMAL(18,1), ISNULL(D.CAP, 0))), ''.0'', '''') + @TB_N';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' dia_cap'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* vis_w */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'V.HASTA >= @TB_DES AND V.DESDE <= @TB_HAS';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'V.HASTA >= @DESDE6';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' vis_w'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* vis_svc */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(2000), V.DIAS), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_N';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(2000), V.DIAS), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + ISNULL((SELECT TOP 1 CASE WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%AUDIT%'' THEN ''AU'' WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%CAPACIT%'' THEN ''CA'' WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%CONSULT%'' THEN ''CO'' ELSE '''' END FROM dbo.VCT_PROYECTOS_VISITAS VV WITH(NOLOCK) INNER JOIN dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK) ON PS.ID = VV.ID_PROYECTO_SERVICIO INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO WHERE VV.ID = V.ID), '''') + @TB_N';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' vis_svc'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* dev_w */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'V.DESDE BETWEEN @TB_DES AND @TB_HAS';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'V.DESDE >= @DESDE6';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' dev_w'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* acc_cie */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'OR A.FECHA_CIERRE >= @MES_ANT';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'OR A.FECHA_CIERRE >= @DESDE6';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' acc_cie'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* acc_fin */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'WHERE FINAL = 1 AND CIERRE >= DATEADD(DAY, -14, @HOY)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'WHERE FINAL = 1';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' acc_fin'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* des */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'data-des="'' + CONVERT(VARCHAR(10), @TB_DES, 120)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'data-des="'' + CONVERT(VARCHAR(10), @DESDE6, 120)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' des'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* css */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=1';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=2';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' css'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=1';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=2';
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V2). Subir css/vct-tablero.css y js/vct-tablero.js (?v=2).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
