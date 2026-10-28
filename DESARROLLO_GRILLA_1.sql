/* ============================================================================
   DESARROLLO_GRILLA_1  (28/10/2026)  marca DES_GRID_V1  -- requiere DESARROLLO_PLANIFICADO_3 aplicado
   ----------------------------------------------------------------------------
   Pestania Visitas > Desarrollo (grilla):
   - Item: codigo y nombre en el mismo renglon. Accion pasa a su propia columna.
   - Textos largos (item, accion, titulo y desarrollo) con el recorte de 2 lineas del sistema y el texto
     completo en el tooltip.
   - Tipo con el badge del sistema (Realizado / Planificado). Consultor: solo el avatar de iniciales.
   - Filtros mas angostos para que entren en un renglon.
   - Assets: vct-proyecto-v360.css ?v=54 (subir el css; el js queda en v44).
   Si alguno de los puntos no se encuentra, NO se cambia nada. Re-ejecutable.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'DES_GRID_V1', @D) > 0
    PRINT 'OK   el parche DES_GRID_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DES_PLAN_V3', @D) = 0
    PRINT 'FALLO: falta aplicar antes DESARROLLO_PLANIFICADO_3.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* buscar */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ '' '' + ISNULL(I.TITULO, '''') + '' '' + ISNULL(Y.NOM, ''''),''&'',''&amp;'')';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ '' '' + ISNULL(I.TITULO, '''') + '' '' + ISNULL(AC.TITULO, '''') + '' '' + ISNULL(Y.NOM, ''''),''&'',''&amp;'')';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' buscar'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* td_item */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                 + ''<td>'' + CASE WHEN ISNULL(I.CODIGO_ITEM, '''') <> '''' THEN ''<span class="vct-pl-code">'' + REPLACE(REPLACE(REPLACE(I.CODIGO_ITEM,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span> '' ELSE '''' END' + NCHAR(10) + N'                 + ''<span class="vct-360-project-ref">'' + REPLACE(REPLACE(REPLACE(ISNULL(I.TITULO, ''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>''' + NCHAR(10) + N'                 + ''<span class="vct-360-project-ref">Acci&oacute;n: '' + REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(CONVERT(VARCHAR(300), AC.DESCRIPCION), '''') <> '''' THEN CONVERT(VARCHAR(300), AC.DESCRIPCION) ELSE ISNULL(AC.TITULO, '''') END,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span></td>''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                 /* DES_GRID_V1: codigo e item en el mismo renglon; la accion en su columna; texto completo en el tooltip */' + NCHAR(10) + N'                 + ''<td><span class="vct-pv-agd-it">'' + CASE WHEN ISNULL(I.CODIGO_ITEM, '''') <> '''' THEN ''<span class="vct-pl-code">'' + REPLACE(REPLACE(REPLACE(I.CODIGO_ITEM,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END' + NCHAR(10) + N'                 + ''<span class="vct-360-project-ref" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(I.TITULO, ''''),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + REPLACE(REPLACE(REPLACE(ISNULL(I.TITULO, ''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span></span></td>''' + NCHAR(10) + N'                 + ''<td data-vct-export-value="'' + REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(CONVERT(VARCHAR(2000), AC.DESCRIPCION), '''') <> '''' THEN CONVERT(VARCHAR(2000), AC.DESCRIPCION) ELSE ISNULL(AC.TITULO, '''') END,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''"><span class="vct-360-project-ref vct-pv-agd-acc" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(CONVERT(VARCHAR(2000), AC.DESCRIPCION), '''') <> '''' THEN CONVERT(VARCHAR(2000), AC.DESCRIPCION) ELSE ISNULL(AC.TITULO, '''') END,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + REPLACE(REPLACE(REPLACE(CASE WHEN ISNULL(CONVERT(VARCHAR(2000), AC.DESCRIPCION), '''') <> '''' THEN CONVERT(VARCHAR(2000), AC.DESCRIPCION) ELSE ISNULL(AC.TITULO, '''') END,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span></td>''' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' td_item'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* td_des */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                 + ''<td><span class="vct-360-project-name">'' + REPLACE(REPLACE(REPLACE(D.TITULO,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>''' + NCHAR(10) + N'                 + CASE WHEN ISNULL(D.DESARROLLO, '''') <> '''' THEN ''<span class="vct-360-project-ref">'' + REPLACE(REPLACE(REPLACE(LEFT(D.DESARROLLO, 400),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END' + NCHAR(10) + N'                 + CASE WHEN ISNULL(D.PROXIMO_PASO, '''') <> '''' THEN ''<span class="vct-360-project-ref vct-pv-agd-nx">Pr&oacute;ximo: '' + REPLACE(REPLACE(REPLACE(D.PROXIMO_PASO,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END + ''</td>''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                 + ''<td><span class="vct-360-project-name" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(D.TITULO,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + REPLACE(REPLACE(REPLACE(D.TITULO,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>''' + NCHAR(10) + N'                 + CASE WHEN ISNULL(D.DESARROLLO, '''') <> '''' THEN ''<span class="vct-360-project-ref" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(LEFT(D.DESARROLLO, 1500),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + REPLACE(REPLACE(REPLACE(LEFT(D.DESARROLLO, 1500),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END' + NCHAR(10) + N'                 + CASE WHEN ISNULL(D.PROXIMO_PASO, '''') <> '''' THEN ''<span class="vct-360-project-ref vct-pv-agd-nx" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(D.PROXIMO_PASO,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">Pr&oacute;ximo: '' + REPLACE(REPLACE(REPLACE(D.PROXIMO_PASO,''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span>'' ELSE '''' END + ''</td>''' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' td_des'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* td_tipo */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE ''Planificado'' END + ''"><span class="vct-pl-tp '' + CASE WHEN D.TIPO = ''REALIZADO'' THEN ''is-re">Realizado'' ELSE ''is-pl">Planificado'' END + ''</span>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE ''Planificado'' END + ''"><span class="vct-360-badge '' + CASE WHEN D.TIPO = ''REALIZADO'' THEN ''is-active">Realizado'' ELSE ''is-planned">Planificado'' END + ''</span>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' td_tipo'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* td_cons */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'<td data-vct-export-value="'' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(Y.NOM, ''''),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''"><span class="vct-pv-agd-who"><span class="vctdg-avatar is-c" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(Y.NOM, ''''),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + ISNULL(Y.INI, '''') + ''</span>'' + REPLACE(REPLACE(REPLACE(ISNULL(Y.NOM, ''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'') + ''</span></td>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'<td class="vct-text-center" data-vct-export-value="'' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(Y.NOM, ''''),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''"><span class="vctdg-avatar is-c" title="'' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(Y.NOM, ''''),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'') + ''">'' + ISNULL(Y.INI, '''') + ''</span></td>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' td_cons'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* th */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<th data-vct-width="22%"><span>&Iacute;tem / acci&oacute;n</span></th><th><span>Desarrollo</span></th>''' + NCHAR(10) + N'            + ''<th class="vct-text-center" data-vct-width="110"><span>Tipo</span></th><th data-vct-width="170"><span>Consultor</span></th>''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            + ''<th data-vct-width="20%"><span>&Iacute;tem</span></th><th data-vct-width="20%"><span>Acci&oacute;n</span></th><th><span>Desarrollo</span></th>''' + NCHAR(10) + N'            + ''<th class="vct-text-center" data-vct-width="120"><span>Tipo</span></th><th class="vct-text-center" data-vct-width="90"><span>Consultor</span></th>''' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' th'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* th_vis */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''<table><thead><tr><th data-vct-width="130" data-vct-sortable="true" data-vct-sort-type="number"><span>Visita</span></th>''' + NCHAR(10) + N'            + ''<th data-vct-width="20%"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''<table><thead><tr><th data-vct-width="110" data-vct-sortable="true" data-vct-sort-type="number"><span>Visita</span></th>''' + NCHAR(10) + N'            + ''<th data-vct-width="20%"';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' th_vis'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=53"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=54"';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (DES_GRID_V1). Subir vct-proyecto-v360.css (v54).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
