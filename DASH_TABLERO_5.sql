/* ============================================================================
   DASH_TABLERO_5  (29/10/2026)  marca DASH_TAB_V5  (requiere DASH_TAB_V4)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_DASHBOARD - Tablero del consultor, card Para hacer al 100% con el diseno de la pantalla Acciones:
   - Acciones | Visitas | Sin detallar en la misma grilla estandar (vct-datagrid), alto fijo de 10 registros.
   - Acciones: pestanias Vencidas / Hoy / Proximas / Sin fecha / Todas + Graficos, Lista | Calendario
     (calendario unificado vct-calendario: vencimientos + mis visitas + desarrollo), filtros Tipo y Prioridad,
     Excel / PDF y el boton Nueva segun los permisos del perfil (VCT_MAIN_GET_ACTIONS, modulo ACCIONES).
   - Se saca el card Calendario; Personalizar ordena 3 bloques: Indicadores, Para hacer, Mis proyectos.
   Solo lectura: no cambia datos. Assets: subir css/vct-tablero.css y js/vct-tablero.js (?v=5).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_DASHBOARD.';
ELSE IF CHARINDEX(N'DASH_TAB_V5', @D) > 0
    PRINT 'OK   el parche DASH_TAB_V5 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DASH_TAB_V4', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_4 (marca DASH_TAB_V4). No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* tba_cols */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'CIERRE DATE, PRIO VARCHAR(100), PNIV INT, ESPLAN BIT, DN INT, DR DECIMAL(9,2), DP DECIMAL(9,2));';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'CIERRE DATE, PRIO VARCHAR(100), PNIV INT, ESPLAN BIT, DN INT, DR DECIMAL(9,2), DP DECIMAL(9,2),' + NCHAR(10) + N'                           TIPO VARCHAR(150), SUBT VARCHAR(150), IDT INT, PRIOC VARCHAR(50));   /* DASH_TAB_V5 */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' tba_cols'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* tba_ins */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'INSERT INTO #TBA (ID, ID_PROYECTO, ITEM, TIT, VENCE, EST, ESTC, FINAL, CIERRE, PRIO, PNIV, ESPLAN, DN, DR, DP)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'INSERT INTO #TBA (ID, ID_PROYECTO, ITEM, TIT, VENCE, EST, ESTC, FINAL, CIERRE, PRIO, PNIV, ESPLAN, DN, DR, DP, TIPO, SUBT, IDT, PRIOC)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' tba_ins'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* tba_sel */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'               ISNULL(DX.N, 0), ISNULL(DX.R, 0), ISNULL(DX.P, 0)' + NCHAR(10) + N'        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'               ISNULL(DX.N, 0), ISNULL(DX.R, 0), ISNULL(DX.P, 0),' + NCHAR(10) + N'               ISNULL(TT.DESCRIPCION, ''''), ISNULL(TS.DESCRIPCION, ''''), ISNULL(A.ID_TIPO, 0), UPPER(LTRIM(RTRIM(ISNULL(PR.CODIGO, ''''))))' + NCHAR(10) + N'        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' tba_sel'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* tba_join */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'        LEFT JOIN dbo.VCT_PRM_ACCIONES_PRIORIDADES PR WITH(NOLOCK) ON PR.ID = A.ID_PRIORIDAD' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'        LEFT JOIN dbo.VCT_PRM_ACCIONES_PRIORIDADES PR WITH(NOLOCK) ON PR.ID = A.ID_PRIORIDAD' + NCHAR(10) + N'        LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS TT WITH(NOLOCK) ON TT.ID = A.ID_TIPO' + NCHAR(10) + N'        LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS TS WITH(NOLOCK) ON TS.ID = A.ID_SUBTIPO' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' tba_join'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* acc_rows */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(A.DP, 0))), ''.0'', '''') + @TB_N';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(A.DP, 0))), ''.0'', '''') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(150), A.TIPO), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(150), A.SUBT), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_T + ISNULL(CONVERT(VARCHAR(20), A.IDT), '''') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(50), A.PRIOC), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_N';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' acc_rows'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* pre_html */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'        SET @TB_HTML = CONVERT(VARCHAR(MAX), '''')';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'        /* DASH_TAB_V5: feriados (calendario unificado) y boton Nueva accion (permisos del perfil, como la pantalla Acciones) */' + NCHAR(10) + N'        DECLARE @TB_FER VARCHAR(MAX) = '''', @TB_NUEVA VARCHAR(MAX) = '''';' + NCHAR(10) + N'        SET @TB_FER = ISNULL((SELECT CONVERT(VARCHAR(10), CL.Fecha, 120) + @TB_T + ISNULL(CONVERT(VARCHAR(10), CL.Feriado), ''1'') + @TB_T + REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(300), ISNULL(NULLIF(CL.HolidayText, ''''), ''Feriado'')), ''''), CHAR(9), '' ''), CHAR(10), '' ''), CHAR(13), '' '') + @TB_N' + NCHAR(10) + N'            FROM dbo.Calendar CL WITH(NOLOCK) WHERE CL.IsHoliday = 1 AND CL.Fecha >= @DESDE12 AND CL.Fecha <= DATEADD(MONTH, 14, @MES_INI)' + NCHAR(10) + N'            ORDER BY CL.Fecha' + NCHAR(10) + N'            FOR XML PATH(''''), TYPE).value(''.'', ''VARCHAR(MAX)''), '''');' + NCHAR(10) + N'        BEGIN TRY' + NCHAR(10) + N'            SELECT TOP 1 @TB_NUEVA = dbo.VCT_MAIN_RENDER_ACTION(A.ACTION_ID, ISNULL(NULLIF(A.TITLE, ''''), ''Nueva acci&oacute;n''), ISNULL(NULLIF(A.ICON, ''''), ''plus''),' + NCHAR(10) + N'                                                             A.STORAGE_KEY, A.TARGET_TAB, A.TARGET_GUID, '''', ''vct-btn vct-btn-new vct-btn-sm'', ''Nueva'')' + NCHAR(10) + N'            FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, ''ACCIONES'') A' + NCHAR(10) + N'            WHERE A.ACTION_TYPE IN (''CREATE'', ''NEW'', ''ADD'', ''INSERT'')' + NCHAR(10) + N'            ORDER BY A.SORT_ORDER, A.ID_PRM;' + NCHAR(10) + N'        END TRY' + NCHAR(10) + N'        BEGIN CATCH' + NCHAR(10) + N'            SET @TB_NUEVA = '''';' + NCHAR(10) + N'        END CATCH;' + NCHAR(10) + N'        SET @TB_NUEVA = ISNULL(@TB_NUEVA, '''');' + NCHAR(10) + NCHAR(10) + N'        SET @TB_HTML = CONVERT(VARCHAR(MAX), '''')';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' pre_html'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ta */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<textarea hidden data-vt="mes">''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<textarea hidden data-vt="fer">'' + REPLACE(REPLACE(REPLACE(@TB_FER, ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') + ''</textarea>''' + NCHAR(10) + N'            + ''<textarea hidden data-vt="nueva">'' + REPLACE(REPLACE(REPLACE(@TB_NUEVA, ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') + ''</textarea>''' + NCHAR(10) + N'            + ''<textarea hidden data-vt="mes">''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ta'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'''<link rel="stylesheet" href="../css/vct-tablero.css?v=4"><script src="../js/vct-tablero.js?v=4"></script>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'''<link rel="stylesheet" href="../css/vct-acciones.css?v=21"><link rel="stylesheet" href="../css/vct-calendario.css?v=47"><link rel="stylesheet" href="../css/vct-tablero.css?v=5"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=51"></script><script src="../js/vct-calendario.js?v=47"></script><script src="../js/vct-tablero.js?v=5"></script>''';
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
            PRINT 'OK   VCT_MAIN_DASHBOARD actualizado (DASH_TAB_V5). Subir css/vct-tablero.css y js/vct-tablero.js (?v=5).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_DASHBOARD (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
