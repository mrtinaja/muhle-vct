/* ============================================================================
   PLAN_DESARROLLO_2  (27/10/2026)  marca PL_DES_V2  -- requiere PLAN_DESARROLLO_1 aplicado
   ----------------------------------------------------------------------------
   Opcion B (la realidad manda), parche sobre la definicion VIVA de dbo.VCT_MAIN_PROYECTO_V360:
   - Item / subitem En curso si llego su fecha de inicio o si ya tiene trabajo
     (accion en proceso o cumplida, o desarrollo realizado). Arbol y estado guardado del item.
   - Accion "Adelantada": desarrollo realizado en una visita anterior a su inicio planificado.
   - Desarrollo planificado: la visita tiene que estar dentro del rango de la accion.
   - Assets: vct-proyecto-v360.css ?v=44 y vct-proyecto-v360.js ?v=37 (subir los dos archivos).
   Si alguno de los puntos no se encuentra en la definicion vigente, NO se cambia nada.
   Re-ejecutable: si la marca PL_DES_V2 ya esta, avisa y no hace nada.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),
        @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @N INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'PL_DES_V2', @D) > 0
    PRINT 'OK   el parche PL_DES_V2 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'PL_DES_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes PLAN_DESARROLLO_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'vct-proyecto-v360.css?v=41"><script src="../js/vct-proyecto-v360.js?v=33"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'vct-proyecto-v360.css?v=44"><script src="../js/vct-proyecto-v360.js?v=37"';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' assets(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* est_arbol */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'WHEN T.FI IS NOT NULL AND CONVERT(DATE, T.FI) <= @HOY THEN ''EN_CURSO''' + NCHAR(10) + N'                                ELSE ''PENDIENTE'' END' + NCHAR(10) + N'        FROM #PI P INNER JOIN #PI T ON T.ID = ISNULL(P.TOPI, P.ID);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'WHEN T.FI IS NOT NULL AND CONVERT(DATE, T.FI) <= @HOY THEN ''EN_CURSO''' + NCHAR(10) + N'                                /* PL_DES_V2: con trabajo (accion en proceso / cumplida o desarrollo realizado) ya esta en curso */' + NCHAR(10) + N'                                WHEN P.NIV > 1 AND EXISTS (SELECT 1 FROM #PA A WHERE (A.ITEM = P.ID OR A.ITEM IN (SELECT S.ID FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3)) AND (A.CUMPLIDA = 1 OR A.EST_COD = ''EN_PROCESO'' OR ISNULL(A.ND, 0) > 0)) THEN ''EN_CURSO''' + NCHAR(10) + N'                                ELSE ''PENDIENTE'' END' + NCHAR(10) + N'        FROM #PI P INNER JOIN #PI T ON T.ID = ISNULL(P.TOPI, P.ID);';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' est_arbol(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* est_db */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'WHEN T.FECHA_INICIO IS NOT NULL AND CONVERT(DATE, T.FECHA_INICIO) <= @HOY THEN ''EN_CURSO''' + NCHAR(10) + N'                                  ELSE ''PENDIENTE'' END';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'WHEN T.FECHA_INICIO IS NOT NULL AND CONVERT(DATE, T.FECHA_INICIO) <= @HOY THEN ''EN_CURSO''' + NCHAR(10) + N'                                  WHEN ISNULL(Y.TRAB, 0) > 0 AND ISNULL(I.GRUPO, '''') <> ''CAPITULO'' THEN ''EN_CURSO''   /* PL_DES_V2 */' + NCHAR(10) + N'                                  ELSE ''PENDIENTE'' END';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' est_db(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* est_db_y */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'AND (A.ID_PLAN_ITEM = I.ID OR A.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))) X' + NCHAR(10) + N'                WHERE I.ID_PLAN = @PL_PLAN;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'AND (A.ID_PLAN_ITEM = I.ID OR A.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))) X' + NCHAR(10) + N'                OUTER APPLY (SELECT COUNT(*) AS TRAB FROM dbo.VCT_ACCIONES A2' + NCHAR(10) + N'                             WHERE A2.ID_ESTADO <> ISNULL(@PL_CANC, -1) AND ISNULL(A2.ID_SUBTIPO, 0) <> ISNULL(@PL_ST_AV, -1)' + NCHAR(10) + N'                               AND (A2.ID_PLAN_ITEM = I.ID OR A2.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))' + NCHAR(10) + N'                               AND (A2.ID_ESTADO IN (ISNULL(@PL_CUMP, -1), ISNULL(@PL_PROC, -1))' + NCHAR(10) + N'                                    OR EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO D WHERE D.ID_ACCION = A2.ID AND D.TIPO = ''REALIZADO''))) Y' + NCHAR(10) + N'                WHERE I.ID_PLAN = @PL_PLAN;';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' est_db_y(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_col */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'FI_IT DATETIME, FF_IT DATETIME, RHTML VARCHAR(MAX));';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'FI_IT DATETIME, FF_IT DATETIME, RHTML VARCHAR(MAX), F1R DATETIME);';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_col(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_upd */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'UPDATE A SET HS = ISNULL(X.HS, 0), ND = ISNULL(X.ND, 0), NP = ISNULL(X.NP, 0)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'UPDATE A SET HS = ISNULL(X.HS, 0), ND = ISNULL(X.ND, 0), NP = ISNULL(X.NP, 0), F1R = X.F1R';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_upd(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_x */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'SUM(CASE WHEN D.TIPO = ''PLANIFICADO'' THEN 1 ELSE 0 END) AS NP' + NCHAR(10) + N'                         FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) WHERE D.ID_ACCION = A.ID) X;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'SUM(CASE WHEN D.TIPO = ''PLANIFICADO'' THEN 1 ELSE 0 END) AS NP,' + NCHAR(10) + N'                                MIN(CASE WHEN D.TIPO = ''REALIZADO'' THEN V.FECHA_DESDE END) AS F1R   /* PL_DES_V2 */' + NCHAR(10) + N'                         FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK)' + NCHAR(10) + N'                         LEFT JOIN dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK) ON V.ID = D.ID_VISITA' + NCHAR(10) + N'                         WHERE D.ID_ACCION = A.ID) X;';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_x(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* pa_chip */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'CASE WHEN A.INI IS NOT NULL THEN @PL_SEP + ''desde '' + CONVERT(VARCHAR(5), A.INI, 103) ELSE '''' END + ''</small></span>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'CASE WHEN A.INI IS NOT NULL THEN @PL_SEP + ''desde '' + CONVERT(VARCHAR(5), A.INI, 103) ELSE '''' END + CASE WHEN A.F1R IS NOT NULL AND A.INI IS NOT NULL AND CONVERT(DATE, A.F1R) < CONVERT(DATE, A.INI) THEN ''<span class="vct-pl-adel" title="Trabajo realizado antes del inicio planificado">Adelantada &middot; real '' + CONVERT(VARCHAR(5), A.F1R, 103) + ''</span>'' ELSE '''' END + ''</small></span>''';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' pa_chip(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* ds_decl */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'@DS_OLD_ACC INT, @DS_Q INT, @DS_H VARCHAR(50);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'@DS_OLD_ACC INT, @DS_Q INT, @DS_H VARCHAR(50), @DS_AFI DATETIME, @DS_AFF DATETIME;';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' ds_decl(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* ds_acc */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'SELECT @DS_ACC = A.ID, @DS_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'SELECT @DS_ACC = A.ID, @DS_EST = A.ID_ESTADO, @DS_AFI = A.FECHA_INICIO, @DS_AFF = A.FECHA_VENCIMIENTO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' ds_acc(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* ds_rango */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'                SET @ERR = ''Un desarrollo planificado va en una visita futura.''' + NCHAR(10) + N'';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'                SET @ERR = ''Un desarrollo planificado va en una visita futura.''' + NCHAR(10) + N'            ELSE IF @DS_TIPO = ''PLANIFICADO'' AND ((@DS_AFI IS NOT NULL AND CONVERT(DATE, @DS_VDES) < CONVERT(DATE, @DS_AFI))' + NCHAR(10) + N'                                               OR (@DS_AFF IS NOT NULL AND CONVERT(DATE, @DS_VDES) > CONVERT(DATE, @DS_AFF)))' + NCHAR(10) + N'                SET @ERR = ''Un desarrollo planificado va en una visita dentro del rango de la acci'' + CHAR(243) + ''n (''' + NCHAR(10) + N'                         + ISNULL(CONVERT(VARCHAR(10), @DS_AFI, 103), ''-'') + '' al '' + ISNULL(CONVERT(VARCHAR(10), @DS_AFF, 103), ''-'') + '').''' + NCHAR(10) + N'';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' ds_rango(' + CONVERT(NVARCHAR(10), @N) + N')';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (PL_DES_V2). Subir vct-proyecto-v360.css (v44) y vct-proyecto-v360.js (v37).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
