/* ============================================================================
   DASH_TABLERO_5_A_8  (29/10/2026)  correr UNA vez, todo junto (F5)
   ----------------------------------------------------------------------------
   El 4 solo subio la version de los assets y no dejaba marca: el 5 pedia la marca DASH_TAB_V4 y no se aplicaba (ni el 6, 7 y 8).
   Ahora el 5 controla que el SP cargue vct-tablero ?v=4.
   Este archivo es la suma de DASH_TABLERO_5, 6, 7 y 8, en orden. Cada parte es re-ejecutable:
   si ya esta aplicada avisa y sigue; si falla, dice que punto no encontro y NO cambia nada.
   Primero lista las marcas que tiene hoy el SP. Pasar todos los mensajes si alguno dice FALLO.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @M VARCHAR(400) = '', @I INT = 1;
WHILE @I <= 8
BEGIN
    SET @M = @M + ' V' + CONVERT(VARCHAR(2), @I) + '=' + CASE WHEN CHARINDEX('DASH_TAB_V' + CONVERT(VARCHAR(2), @I), @D) > 0 THEN 'SI' ELSE 'no' END;
    SET @I = @I + 1;
END;
PRINT 'Marcas antes:' + @M;
PRINT 'Assets tablero: ' + CASE WHEN CHARINDEX('vct-tablero.js?v=', @D) > 0 THEN SUBSTRING(@D, CHARINDEX('vct-tablero.js?v=', @D), 19) ELSE '(no encontrado)' END;
GO

/* ======================= DASH_TABLERO_5 ======================= */
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
ELSE IF CHARINDEX(N'vct-tablero.js?v=4', @D) = 0
    PRINT 'FALLO: falta DASH_TABLERO_4 (assets del tablero ?v=4). No se cambio nada.';
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

/* ======================= DASH_TABLERO_6 ======================= */
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

/* ======================= DASH_TABLERO_7 ======================= */
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

/* ======================= DASH_TABLERO_8 ======================= */
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
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'UPPER(ISNULL(PN.ESTADO, '''')) NOT LIKE ''INACTIV%'' AND UPPER(ISNULL(PN.ESTADO, '''')) NOT IN (''BAJA'', ''ANULADA'', ''ANULADO'', ''ELIMINADA'', ''ELIMINADO'') /* DASH_TAB_V8 */';
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
