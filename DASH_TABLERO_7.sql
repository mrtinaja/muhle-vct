/* ============================================================================
   DASH_TABLERO_7  (29/10/2026)  marca DASH_TAB_V7  (requiere DASH_TAB_V6)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD - Tablero del consultor, Mis proyectos con el diseno de la grilla Proyectos:
   a cada proyecto se le agregan servicios (CO / AU / CA), normas y analista. Solo lectura.
   Subir css/vct-tablero.css y js/vct-tablero.js (?v=7). SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V7', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V7 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V6', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_6 (marca DASH_TAB_V6). No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* pro_rows */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(MV.H12, 0))), ''.0'', '''') + @TB_N';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(MV.H12, 0))), ''.0'', '''') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(200), ISNULL(STUFF((SELECT DISTINCT '','' + CASE WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%AUDIT%'' THEN ''AU'' WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%CAPACIT%'' THEN ''CA'' WHEN UPPER(ISNULL(S.CODIGO, '''') + '' '' + ISNULL(S.DESCRIPCION, '''')) LIKE ''%CONSULT%'' THEN ''CO'' ELSE ''XX'' END FROM dbo.VCT_PROYECTOS_SERVICIOS XS WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = XS.ID_SERVICIO WHERE XS.ID_PROYECTO = T.ID FOR XML PATH(''''), TYPE).value(''.'', ''VARCHAR(200)''), 1, 1, ''''), '''')), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(2000), ISNULL(STUFF((SELECT ''|'' + ISNULL(N.DESCRIPCION, '''') FROM dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_NORMAS N WITH(NOLOCK) ON N.ID = PN.ID_NORMA WHERE PN.ID_PROYECTO = T.ID AND UPPER(ISNULL(PN.ESTADO, ''ACTIVO'')) = ''ACTIVO'' GROUP BY N.DESCRIPCION ORDER BY N.DESCRIPCION FOR XML PATH(''''), TYPE).value(''.'', ''VARCHAR(2000)''), 1, 1, ''''), '''')), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(4), (SELECT TOP 1 UPPER(LEFT(LTRIM(ISNULL(E.NOMBRES, '''')), 1) + LEFT(LTRIM(ISNULL(E.APELLIDOS, '''')), 1)) FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK) INNER JOIN dbo.VCT_EMPLEADOS E WITH(NOLOCK) ON E.ID = EQ.ID_EMPLEADO INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL WHERE EQ.ID_PROYECTO = T.ID AND R.CODIGO = ''ANALISTA'' AND ISNULL(EQ.ESTADO, ''ACTIVO'') = ''ACTIVO'' ORDER BY EQ.ID_EMPLEADO)), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(300), (SELECT TOP 1 LTRIM(RTRIM(ISNULL(E.APELLIDOS, '''') + CASE WHEN ISNULL(E.NOMBRES, '''') <> '''' THEN '', '' + E.NOMBRES ELSE '''' END)) FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK) INNER JOIN dbo.VCT_EMPLEADOS E WITH(NOLOCK) ON E.ID = EQ.ID_EMPLEADO INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL WHERE EQ.ID_PROYECTO = T.ID AND R.CODIGO = ''ANALISTA'' AND ISNULL(EQ.ESTADO, ''ACTIVO'') = ''ACTIVO'' ORDER BY EQ.ID_EMPLEADO)), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_N   /* DASH_TAB_V7 */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' pro_rows'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* css */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=6';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.css?v=7';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' css'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=6';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-tablero.js?v=7';
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V7). Subir css/vct-tablero.css y js/vct-tablero.js (?v=7).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
