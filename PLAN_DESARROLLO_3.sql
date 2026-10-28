/* ============================================================================
   PLAN_DESARROLLO_3  (27/10/2026)  marca PL_DES_V3  -- requiere PLAN_DESARROLLO_2 aplicado
   ----------------------------------------------------------------------------
   Estados de las acciones del plan (parche sobre la definicion VIVA de dbo.VCT_MAIN_PROYECTO_V360):
   - Cumplida: solo si la accion tiene desarrollo realizado.
   - Cancelada (o cerrada sin cumplir) y Eliminar: solo si NO tiene desarrollo realizado.
   - Desarrollo: se carga / edita / elimina solo en acciones abiertas (cerrada: reabrir con Editar > Estado).
   - Se ven todas las acciones del item, tambien las canceladas (atenuadas, no cuentan en el avance).
   - Assets: vct-proyecto-v360.css ?v=45 y vct-proyecto-v360.js ?v=38 (subir los dos archivos).
   Si alguno de los puntos no se encuentra en la definicion vigente, NO se cambia nada.
   Re-ejecutable: si la marca PL_DES_V3 ya esta, avisa y no hace nada.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),
        @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @N INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'PL_DES_V3', @D) > 0
    PRINT 'OK   el parche PL_DES_V3 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'PL_DES_V2', @D) = 0
    PRINT 'FALLO: falta aplicar antes PLAN_DESARROLLO_2.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'vct-proyecto-v360.css?v=44"><script src="../js/vct-proyecto-v360.js?v=37"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'vct-proyecto-v360.css?v=45"><script src="../js/vct-proyecto-v360.js?v=38"';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' assets(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* acc_reglas */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @ERR = '''' AND @PA_ACC IS NULL SELECT @PA_EST = @PL_PEND, @PA_EST_FIN = 0, @PA_RES = NULL;   /* PL_DES_V1: la accion nace Pendiente */';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @ERR = '''' AND @PA_ACC IS NULL SELECT @PA_EST = @PL_PEND, @PA_EST_FIN = 0, @PA_RES = NULL;   /* PL_DES_V1: la accion nace Pendiente */' + NCHAR(10) + N'                /* PL_DES_V3: cumplida solo con desarrollo realizado; cancelada (o cerrada sin cumplir) solo sin desarrollo realizado */' + NCHAR(10) + N'                DECLARE @PA_DH NUMERIC(18,2) = 0;' + NCHAR(10) + N'                IF @PA_ACC IS NOT NULL SELECT @PA_DH = ISNULL(SUM(D.HORAS), 0) FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = @PA_ACC AND D.TIPO = ''REALIZADO'';' + NCHAR(10) + N'                IF @ERR = '''' AND @PA_ACC IS NOT NULL AND @PA_EST = @PL_CUMP AND ISNULL(@PA_OLD_EST, -1) <> @PL_CUMP AND NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = @PA_ACC AND D.TIPO = ''REALIZADO'')' + NCHAR(10) + N'                    SET @ERR = ''Para cumplir la acci'' + CHAR(243) + ''n carg'' + CHAR(225) + '' primero su desarrollo realizado.'';' + NCHAR(10) + N'                IF @ERR = '''' AND @PA_ACC IS NOT NULL AND @PA_EST_FIN = 1 AND @PA_EST <> @PL_CUMP AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = @PA_ACC AND D.TIPO = ''REALIZADO'')' + NCHAR(10) + N'                    SET @ERR = ''La acci'' + CHAR(243) + ''n tiene '' + REPLACE(CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,1), @PA_DH)), ''.0'', '''') + '' h de desarrollo realizado: no se puede cancelar. Elimin'' + CHAR(225) + '' primero su desarrollo.'';';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' acc_reglas(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* acc_tilde */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'ELSE IF UPPER(@B_T11) NOT IN (''CUMPLIDA'',''PENDIENTE'') SET @ERR = ''Estado no v'' + CHAR(225) + ''lido.'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'ELSE IF UPPER(@B_T11) NOT IN (''CUMPLIDA'',''PENDIENTE'') SET @ERR = ''Estado no v'' + CHAR(225) + ''lido.''' + NCHAR(10) + N'            ELSE IF UPPER(@B_T11) = ''CUMPLIDA'' AND NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = @PL_ACC AND D.TIPO = ''REALIZADO'')' + NCHAR(10) + N'                SET @ERR = ''Para cumplir la acci'' + CHAR(243) + ''n carg'' + CHAR(225) + '' primero su desarrollo realizado.'';   /* PL_DES_V3 */';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' acc_tilde(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* acc_borrar */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'ELSE IF @PL_CANC IS NULL SET @ERR = ''Falta el estado CANCELADA en la parametr'' + CHAR(237) + ''a de acciones.'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'ELSE IF @PL_CANC IS NULL SET @ERR = ''Falta el estado CANCELADA en la parametr'' + CHAR(237) + ''a de acciones.''' + NCHAR(10) + N'            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = @PL_ACC AND D.TIPO = ''REALIZADO'')' + NCHAR(10) + N'                SET @ERR = ''La acci'' + CHAR(243) + ''n tiene desarrollo realizado: no se puede eliminar. Elimin'' + CHAR(225) + '' primero su desarrollo.'';   /* PL_DES_V3 */';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' acc_borrar(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* des_cerrada */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @DS_ACC IS NULL SET @ERR = ''La acci'' + CHAR(243) + ''n no es del plan de este proyecto.''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @DS_ACC IS NULL SET @ERR = ''La acci'' + CHAR(243) + ''n no es del plan de este proyecto.''' + NCHAR(10) + N'            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ID = @DS_EST AND ES_FINAL = 1) SET @ERR = ''La acci'' + CHAR(243) + ''n est'' + CHAR(225) + '' cerrada: reabrila (Editar > Estado) para cargar o cambiar su desarrollo.''   /* PL_DES_V3 */';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' des_cerrada(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* des_borrar_cerrada */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @ERR = '''' AND @B_CMD = ''PV_PL_DES_BORRAR'' AND @DS_ID IS NULL SET @ERR = ''Falta el desarrollo a eliminar.'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'IF @ERR = '''' AND @B_CMD = ''PV_PL_DES_BORRAR'' AND @DS_ID IS NULL SET @ERR = ''Falta el desarrollo a eliminar.'';' + NCHAR(10) + N'        IF @ERR = '''' AND @B_CMD = ''PV_PL_DES_BORRAR'' AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO' + NCHAR(10) + N'                                                                 WHERE A.ID = @DS_OLD_ACC AND E.ES_FINAL = 1)' + NCHAR(10) + N'            SET @ERR = ''La acci'' + CHAR(243) + ''n est'' + CHAR(225) + '' cerrada: reabrila (Editar > Estado) para cargar o cambiar su desarrollo.'';   /* PL_DES_V3 */';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' des_borrar_cerrada(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_col */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'RHTML VARCHAR(MAX), F1R DATETIME);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'RHTML VARCHAR(MAX), F1R DATETIME, CANC BIT);';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_col(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_todas */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'A.ID_ESTADO <> ISNULL(@PL_CANC_ST, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@PL_AV_ST, -1);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@PL_AV_ST, -1);   /* PL_DES_V3: tambien las canceladas (se ven, no cuentan) */';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_todas(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_canc */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'UPDATE A SET TOP_ITEM = P.TOPI,';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'UPDATE A SET CANC = CASE WHEN A.FINAL = 1 AND A.CUMPLIDA = 0 THEN 1 ELSE 0 END, TOP_ITEM = P.TOPI,';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_canc(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* cnt_item */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'        UPDATE P SET TOT = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID), 0),' + NCHAR(10) + N'                     CUMP = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.CUMPLIDA = 1), 0),' + NCHAR(10) + N'                     VEN = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.SIT = ''V''), 0)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'        UPDATE P SET TOT = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.CANC = 0), 0),' + NCHAR(10) + N'                     CUMP = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.CANC = 0 AND A.CUMPLIDA = 1), 0),' + NCHAR(10) + N'                     VEN = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.CANC = 0 AND A.SIT = ''V''), 0)';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' cnt_item(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* cnt_plan */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'@PL_TOT INT = (SELECT COUNT(*) FROM #PA), @PL_OK INT = (SELECT COUNT(*) FROM #PA WHERE CUMPLIDA = 1),';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'@PL_TOT INT = (SELECT COUNT(*) FROM #PA WHERE CANC = 0), @PL_OK INT = (SELECT COUNT(*) FROM #PA WHERE CANC = 0 AND CUMPLIDA = 1),';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' cnt_plan(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* cnt_gantt */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'FROM #PA A WHERE A.TOP_ITEM = T.ID AND A.VENCE IS NOT NULL FOR XML';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'FROM #PA A WHERE A.TOP_ITEM = T.ID AND A.VENCE IS NOT NULL AND A.CANC = 0 FOR XML';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' cnt_gantt(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* cnt_trab */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'AND (A.CUMPLIDA = 1 OR A.EST_COD = ''EN_PROCESO'' OR ISNULL(A.ND, 0) > 0)) THEN ''EN_CURSO''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'AND A.CANC = 0 AND (A.CUMPLIDA = 1 OR A.EST_COD = ''EN_PROCESO'' OR ISNULL(A.ND, 0) > 0)) THEN ''EN_CURSO''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' cnt_trab(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* orden */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'FROM #PA A WHERE A.ITEM = T.ID ORDER BY A.CUMPLIDA, ISNULL(A.VENCE, ''29991231''), A.ID FOR XML';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'FROM #PA A WHERE A.ITEM = T.ID ORDER BY A.CANC, A.CUMPLIDA, ISNULL(A.VENCE, ''29991231''), A.ID FOR XML';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' orden(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* fila_cls */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'''<div class="vct-plt-acc'' + CASE WHEN A.CUMPLIDA = 1 THEN '' is-done''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'''<div class="vct-plt-acc'' + CASE WHEN A.CANC = 1 THEN '' is-canc'' WHEN A.CUMPLIDA = 1 THEN '' is-done''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' fila_cls(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* fila_badge */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'''<span class="vct-plt-b"><span class="vct-360-badge '' + CASE WHEN A.CUMPLIDA = 1 THEN ''is-active''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'''<span class="vct-plt-b"><span class="vct-360-badge '' + CASE WHEN A.CANC = 1 THEN ''is-cancel'' WHEN A.CUMPLIDA = 1 THEN ''is-active''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' fila_badge(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* menu_des */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'+ ''<button type="button" class="vct-pv-menu-btn" data-pl-des-new="'' + CONVERT(VARCHAR(20), A.ID) + ''"><span data-vct-icon="plus"></span><span>Cargar desarrollo</span></button>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN A.FINAL = 0 THEN ''<button type="button" class="vct-pv-menu-btn" data-pl-des-new="'' + CONVERT(VARCHAR(20), A.ID) + ''"><span data-vct-icon="plus"></span><span>Cargar desarrollo</span></button>'' ELSE '''' END';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' menu_des(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* menu_del_a */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'+ ''<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ACC_BORRAR"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN A.CANC = 0 AND ISNULL(A.ND, 0) = 0 THEN ''<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ACC_BORRAR"';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' menu_del_a(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* menu_del_b */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'<span data-vct-icon="trash"></span><span>Eliminar</span></button>''' + NCHAR(10) + N'                + ''</div></span>'' ELSE '''' END';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'<span data-vct-icon="trash"></span><span>Eliminar</span></button>'' ELSE '''' END' + NCHAR(10) + N'                + ''</div></span>'' ELSE '''' END';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' menu_del_b(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* edit_nd */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'+ '' data-f-ini="'' + ISNULL(CONVERT(VARCHAR(10), A.INI, 120),'''') + ''" data-f-vence="'' + ISNULL(CONVERT(VARCHAR(10), A.VENCE, 120),'''') + ''"''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'+ '' data-f-ini="'' + ISNULL(CONVERT(VARCHAR(10), A.INI, 120),'''') + ''" data-f-vence="'' + ISNULL(CONVERT(VARCHAR(10), A.VENCE, 120),'''') + ''"''' + NCHAR(10) + N'                + '' data-f-nd="'' + CONVERT(VARCHAR(10), ISNULL(A.ND, 0)) + ''" data-f-hs="'' + REPLACE(CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,1), ISNULL(A.HS, 0))), ''.0'', '''') + ''"''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' edit_nd(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* est_cod */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'''" data-final="'' + CASE WHEN ES_FINAL = 1 THEN ''1'' ELSE ''0'' END + ''">''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'''" data-final="'' + CASE WHEN ES_FINAL = 1 THEN ''1'' ELSE ''0'' END + ''" data-cod="'' + ISNULL(CODIGO, '''') + ''">''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' est_cod(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* regs_menu */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN @PUEDE_PLAN = 1 THEN ''<span class="vct-pl-menu">'' + @PL_TRIG + ''<div class="vctdg-rowmenu-items" hidden>''' + NCHAR(10) + N'                          + ''<button type="button" class="vct-pv-menu-btn" data-pl-des-edit=';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN @PUEDE_PLAN = 1 AND A.FINAL = 0 THEN ''<span class="vct-pl-menu">'' + @PL_TRIG + ''<div class="vctdg-rowmenu-items" hidden>''' + NCHAR(10) + N'                          + ''<button type="button" class="vct-pv-menu-btn" data-pl-des-edit=';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' regs_menu(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* regs_ft */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN @PUEDE_PLAN = 1 THEN ''<div class="vct-pl-regs-ft">';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'+ CASE WHEN @PUEDE_PLAN = 1 AND A.FINAL = 0 THEN ''<div class="vct-pl-regs-ft">';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' regs_ft(' + CONVERT(NVARCHAR(10), @N) + N')';
    IF @F <> N''
        PRINT 'FALLO: no se encontraron en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (PL_DES_V3). Subir vct-proyecto-v360.css (v45) y vct-proyecto-v360.js (v38).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
