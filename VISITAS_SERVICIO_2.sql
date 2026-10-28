/* ============================================================================
   VISITAS_SERVICIO_2  (28/10/2026)  marca VIS_SRV_V2  -- requiere VISITAS_SERVICIO_1 aplicado
   ----------------------------------------------------------------------------
   Pestania Visitas de la V360 del proyecto:
   - Los chips Todos / Consultoria / Auditorias / Capacitaciones quedan arriba y valen para Lista y Desarrollo.
   - Desarrollo: filtro Servicio (igual que Lista) y los indicadores se calculan para el tipo / servicio elegido.
   - Lista: la columna Servicio toma mas ancho; Logistica deja de ser columna y se muestra debajo del servicio.
   - Assets: vct-proyecto-v360.css ?v=49 y vct-proyecto-v360.js ?v=41 (subir los dos archivos).
   Si alguno de los puntos no se encuentra (o esta repetido), NO se cambia nada. Re-ejecutable.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_SRV_V2', @D) > 0
    PRINT 'OK   el parche VIS_SRV_V2 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'VIS_SRV_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes VISITAS_SERVICIO_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* chips_arriba */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''<div data-pv-agpane="lista">'' + @AG_CHIPS + ''<div class="vct-360-stats-row vct-pv-agsum" data-pv-agsum hidden></div>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ @AG_CHIPS + ''<div data-pv-agpane="lista"><div class="vct-360-stats-row vct-pv-agsum" data-pv-agsum hidden></div>''   /* VIS_SRV_V2: chips para Lista y Desarrollo */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' chips_arriba'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* des_filtros */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            + CASE WHEN @AG_DINST_N > 1 THEN ''<select data-vct-dg-filter="inst" aria-label="Servicio"><option value="">Servicio</option>'' + @AG_DINST + ''</select>'' ELSE '''' END + ''</div>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<select data-vct-dg-filter="servicio" aria-label="Tipo de servicio" data-pv-agtsel><option value="">Tipo de servicio</option>'' + @AG_FSRV + ''</select>''' + NCHAR(10) + N'            + ''<select data-vct-dg-filter="inst" aria-label="Servicio" data-pv-aginst><option value="">Servicio (todos)</option>'' + @AG_FINST + ''</select></div>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' des_filtros'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* des_row_srv */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N''' data-vct-filter-cons="'' + CONVERT(VARCHAR(20), D.ID_CONSULTOR) + ''" data-vct-filter-inst="''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N''' data-vct-filter-cons="'' + CONVERT(VARCHAR(20), D.ID_CONSULTOR) + ''" data-vct-filter-servicio="'' + LOWER(A.T) + ''" data-vct-filter-inst="''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' des_row_srv'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* des_stats */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<div class="vct-360-stats-row vct-pv-agd-stats">''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<div class="vct-360-stats-row vct-pv-agd-stats" data-pv-agdstats>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' des_stats'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* inst_dv */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                            SUM(CASE WHEN D.TIPO = ''PLANIFICADO'' THEN 1 ELSE 0 END) AS NP' + NCHAR(10) + N'                     FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) INNER JOIN #AGV A2 ON A2.ID = D.ID_VISITA WHERE @AG_DES_ON = 1 AND A2.ID_PS = S.ID) DV';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                            SUM(CASE WHEN D.TIPO = ''PLANIFICADO'' THEN 1 ELSE 0 END) AS NP,' + NCHAR(10) + N'                            COUNT(DISTINCT CASE WHEN D.TIPO = ''REALIZADO'' THEN D.ID_VISITA END) AS NVD,' + NCHAR(10) + N'                            MIN(CASE WHEN D.TIPO = ''PLANIFICADO'' AND A2.DESDE > @HOY THEN A2.DESDE END) AS PX' + NCHAR(10) + N'                     FROM dbo.VCT_ACCIONES_DESARROLLO D WITH(NOLOCK) INNER JOIN #AGV A2 ON A2.ID = D.ID_VISITA WHERE @AG_DES_ON = 1 AND A2.ID_PS = S.ID) DV';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' inst_dv'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* inst_attrs */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''" data-dp="'' + CONVERT(VARCHAR(10), ISNULL(DV.NP, 0)) + ''">''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''" data-dp="'' + CONVERT(VARCHAR(10), ISNULL(DV.NP, 0)) + ''" data-nvd="'' + CONVERT(VARCHAR(10), ISNULL(DV.NVD, 0)) + ''" data-px="'' + ISNULL(CONVERT(VARCHAR(10), DV.PX, 120), '''') + ''">''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' inst_attrs'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* th_logi */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'<th class="vct-text-center" data-vct-width="110"><span>Estado</span></th><th data-vct-width="14%"><span>Log&iacute;stica</span></th>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'<th class="vct-text-center" data-vct-width="110"><span>Estado</span></th>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' th_logi'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* td_logi */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'             + ''<td>'' + CASE WHEN A.LOGI = '''' THEN ''<span class="vctdg-none">-</span>'' ELSE REPLACE(REPLACE(REPLACE(A.LOGI,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') END + ''</td>''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'');
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' td_logi'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* srv_logi */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'             + CASE WHEN A.LUGAR <> '''' THEN ''<span class="vct-360-project-ref">'' + REPLACE(REPLACE(REPLACE(A.LUGAR,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END + ''</td>''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'             + CASE WHEN A.LUGAR <> '''' THEN ''<span class="vct-360-project-ref">'' + REPLACE(REPLACE(REPLACE(A.LUGAR,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END' + NCHAR(10) + N'             + CASE WHEN A.LOGI <> '''' THEN ''<span class="vct-360-project-ref vct-pv-ag-logi">Log&iacute;stica: '' + REPLACE(REPLACE(REPLACE(A.LOGI,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END + ''</td>''   /* VIS_SRV_V2 */' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' srv_logi'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* th_srv */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''<table><thead><tr><th data-vct-sortable="true"><span>Servicio</span></th>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''<table><thead><tr><th data-vct-sortable="true" data-vct-width="30%"><span>Servicio</span></th>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' th_srv'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=48"><script src="../js/vct-proyecto-v360.js?v=40"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=49"><script src="../js/vct-proyecto-v360.js?v=41"';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_SRV_V2). Subir vct-proyecto-v360.css (v49) y vct-proyecto-v360.js (v41).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
