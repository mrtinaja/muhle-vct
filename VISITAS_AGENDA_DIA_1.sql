/* ============================================================================
   VISITAS_AGENDA_DIA_1  (28/10/2026)  marca VIS_AGD_V1   (correr despues de VISITAS_EQUIPO_1.sql)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_PROYECTO_V360, Nueva / Editar visita:
   - Dia no disponible: se muestra el estado de la agenda del consultor + su descripcion
     (ocupado, no disponible, licencia...). Sin agenda cargada: 'agenda sin cargar'.
   - Potencial con horas cargadas: no frena la visita. Al grabar, ese dia pasa a disponible en
     VCT_PRM_AGENDA_CONSULTOR (queda asignado por la visita) y se borra la descripcion del potencial.
   - Dias sin agenda: boton 'Cargar disponible' en el dia (solo con permiso EDIT de AGENDA_CONSULTOR).
     Al grabar la visita se cargan en la agenda del consultor como disponibles, 8 h.
   - Assets: vct-proyecto-v360.css ?v=56 y vct-proyecto-v360.js ?v=47 (subir los dos).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_AGD_V1', @D) > 0
    PRINT 'OK   el parche VIS_AGD_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'VIS_EQ_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes VISITAS_EQUIPO_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* t24_decl */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T23 VARCHAR(MAX) = '''';   /* VIS_HD_V1: TEXTO23 horas por dia */';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T23 VARCHAR(MAX) = '''', @AG_T24 VARCHAR(MAX) = '''';   /* VIS_HD_V1: TEXTO23 horas por dia; VIS_AGD_V1: TEXTO24 dias a cargar disponibles */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t24_decl'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t24_read */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T23 = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(MAX), TEXTO23),'''')))';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T23 = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(MAX), TEXTO23),''''))), @AG_T24 = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(MAX), TEXTO24),'''')))';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t24_read'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t24_clean */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'TEXTO22 = NULL, TEXTO23 = NULL' + NCHAR(10) + N'        WHERE PAR_KEY = @IPKEYJOB;' + NCHAR(10) + N'        SET @VOLVER = ''agenda'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'TEXTO22 = NULL, TEXTO23 = NULL, TEXTO24 = NULL' + NCHAR(10) + N'        WHERE PAR_KEY = @IPKEYJOB;' + NCHAR(10) + N'        SET @VOLVER = ''agenda'';' + NCHAR(10) + N'        DECLARE @AGP TABLE (CONS INT, FECHA DATE);   /* VIS_AGD_V1: dias sin agenda a cargar disponibles */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t24_clean'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t24_parse */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            UPDATE C SET HORAS = X.S FROM @AGC C CROSS APPLY (SELECT SUM(D.HORAS) AS S FROM @AGD D WHERE D.CONS = C.CONS) X WHERE X.S IS NOT NULL;' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            UPDATE C SET HORAS = X.S FROM @AGC C CROSS APPLY (SELECT SUM(D.HORAS) AS S FROM @AGD D WHERE D.CONS = C.CONS) X WHERE X.S IS NOT NULL;' + NCHAR(10) + NCHAR(10) + N'            /* VIS_AGD_V1: dias sin agenda que se cargan disponibles (8 h): "id:aaaa-mm-dd|aaaa-mm-dd;id:...". Permiso: EDIT de AGENDA_CONSULTOR */' + NCHAR(10) + N'            IF @AG_T24 <> '''' AND NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, ''AGENDA_CONSULTOR'') AA WHERE UPPER(ISNULL(AA.ACTION_TYPE,'''')) = ''EDIT'')' + NCHAR(10) + N'                SET @ERR = ''No tiene permiso para cargar la agenda del consultor.'';' + NCHAR(10) + N'            ELSE IF @AG_T24 <> ''''' + NCHAR(10) + N'            BEGIN' + NCHAR(10) + N'                SET @AG_L = @AG_T24 + '';'';' + NCHAR(10) + N'                SET @AG_P = CHARINDEX('';'', @AG_L);' + NCHAR(10) + N'                WHILE @AG_P > 0' + NCHAR(10) + N'                BEGIN' + NCHAR(10) + N'                    SET @AG_PAR = LTRIM(RTRIM(LEFT(@AG_L, @AG_P - 1)));' + NCHAR(10) + N'                    SET @AG_L = SUBSTRING(@AG_L, @AG_P + 1, 2000000);' + NCHAR(10) + N'                    SET @AG_Q = CHARINDEX('':'', @AG_PAR);' + NCHAR(10) + N'                    SET @AG_A = CASE WHEN @AG_Q > 1 THEN LTRIM(RTRIM(LEFT(@AG_PAR, @AG_Q - 1))) ELSE '''' END;' + NCHAR(10) + N'                    IF @AG_A <> '''' AND PATINDEX(''%[^0-9]%'', @AG_A) = 0 AND LEN(@AG_A) <= 9 AND EXISTS (SELECT 1 FROM @AGC WHERE CONS = CONVERT(INT, @AG_A))' + NCHAR(10) + N'                    BEGIN' + NCHAR(10) + N'                        SET @AG_L2 = SUBSTRING(@AG_PAR, @AG_Q + 1, 4000) + ''|'';' + NCHAR(10) + N'                        SET @AG_P2 = CHARINDEX(''|'', @AG_L2);' + NCHAR(10) + N'                        WHILE @AG_P2 > 0' + NCHAR(10) + N'                        BEGIN' + NCHAR(10) + N'                            SET @AG_FD = LTRIM(RTRIM(LEFT(@AG_L2, @AG_P2 - 1)));' + NCHAR(10) + N'                            SET @AG_L2 = SUBSTRING(@AG_L2, @AG_P2 + 1, 4000);' + NCHAR(10) + N'                            IF @AG_FD LIKE ''[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]'' AND ISDATE(REPLACE(@AG_FD,''-'','''')) = 1' + NCHAR(10) + N'                               AND CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112) BETWEEN CONVERT(DATE, @AG_DES) AND CONVERT(DATE, @AG_HAS)' + NCHAR(10) + N'                               AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR A WITH(NOLOCK) WHERE A.ID_CONSULTOR = CONVERT(INT, @AG_A) AND A.FECHA = CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112))' + NCHAR(10) + N'                               AND NOT EXISTS (SELECT 1 FROM dbo.Calendar CL WITH(NOLOCK) WHERE CL.Fecha = CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112) AND ISNULL(CL.IsHoliday, 0) = 1)' + NCHAR(10) + N'                               AND NOT EXISTS (SELECT 1 FROM @AGP WHERE CONS = CONVERT(INT, @AG_A) AND FECHA = CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112))' + NCHAR(10) + N'                                INSERT INTO @AGP (CONS, FECHA) VALUES (CONVERT(INT, @AG_A), CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112));' + NCHAR(10) + N'                            SET @AG_P2 = CHARINDEX(''|'', @AG_L2);' + NCHAR(10) + N'                        END;' + NCHAR(10) + N'                    END;' + NCHAR(10) + N'                    SET @AG_P = CHARINDEX('';'', @AG_L);' + NCHAR(10) + N'                END;' + NCHAR(10) + N'            END;' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t24_parse'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_msg */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                            WHEN AG.TIPO <> ''DISPONIBLE'' THEN LOWER(REPLACE(AG.TIPO, ''_'', '' ''))' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                            WHEN AG.TIPO = ''POTENCIAL'' AND ISNULL(AG.HORAS_CAPACIDAD, 0) <= 0 THEN ''potencial sin horas cargadas''   /* VIS_AGD_V1 */' + NCHAR(10) + N'                            WHEN AG.TIPO NOT IN (''DISPONIBLE'',''POTENCIAL'') THEN LOWER(REPLACE(AG.TIPO, ''_'', '' ''))' + NCHAR(10) + N'                                 + ISNULL('': '' + NULLIF(LTRIM(RTRIM(ISNULL(NULLIF(CONVERT(VARCHAR(400), AG.DESCRIPCION),''''), ISNULL(CONVERT(VARCHAR(400), AG.MOTIVO),'''')))), ''''), '''')' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_msg'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_libre */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(AG.TIPO, '''') <> ''DISPONIBLE'' THEN 0';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(AG.TIPO, CASE WHEN EXISTS (SELECT 1 FROM @AGP P WHERE P.CONS = C.CONS AND P.FECHA = R.FECHA) THEN ''DISPONIBLE'' ELSE '''' END) NOT IN (''DISPONIBLE'',''POTENCIAL'') THEN 0';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_libre'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* save_prm */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                /* VIS_EQ_V1: consultor de la visita';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                /* VIS_AGD_V1: dias sin agenda marcados en el modal -> disponibles (8 h) en la agenda del consultor */' + NCHAR(10) + N'                INSERT INTO dbo.VCT_PRM_AGENDA_CONSULTOR (ID_CONSULTOR, FECHA, TIPO, HORAS_CAPACIDAD, DISPONIBLE, MOTIVO, DESCRIPCION, FECHA_ALTA, USUARIO_ALTA)' + NCHAR(10) + N'                SELECT P.CONS, P.FECHA, ''DISPONIBLE'', 8, 1, NULL, NULL, GETDATE(), @IAGENTE FROM @AGP P' + NCHAR(10) + N'                WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR A WHERE A.ID_CONSULTOR = P.CONS AND A.FECHA = P.FECHA);' + NCHAR(10) + N'                /* VIS_AGD_V1: potencial con horas en un dia de la visita -> disponible (queda asignado por la visita), sin descripcion */' + NCHAR(10) + N'                UPDATE A SET TIPO = ''DISPONIBLE'', DISPONIBLE = 1, DESCRIPCION = NULL, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE' + NCHAR(10) + N'                FROM dbo.VCT_PRM_AGENDA_CONSULTOR A INNER JOIN @AGC C ON C.CONS = A.ID_CONSULTOR' + NCHAR(10) + N'                WHERE A.TIPO = ''POTENCIAL'' AND ISNULL(A.HORAS_CAPACIDAD, 0) > 0 AND A.FECHA BETWEEN CONVERT(DATE, @AG_DES) AND CONVERT(DATE, @AG_HAS)' + NCHAR(10) + N'                  AND (EXISTS (SELECT 1 FROM @AGD D WHERE D.CONS = C.CONS AND D.FECHA = A.FECHA AND D.HORAS > 0)' + NCHAR(10) + N'                       OR NOT EXISTS (SELECT 1 FROM @AGD D WHERE D.CONS = C.CONS));' + NCHAR(10) + N'                /* VIS_EQ_V1: consultor de la visita';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' save_prm'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ag_a */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'WHEN R.ESTADO = ''ASIGNADO'' AND ISNULL(AG.TIPO,'''') = ''DISPONIBLE'' THEN ''A''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'WHEN R.ESTADO = ''ASIGNADO'' AND ISNULL(AG.TIPO,'''') IN (''DISPONIBLE'',''POTENCIAL'') THEN ''A''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_a'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ag_h */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(AG.TIPO,'''') <> ''DISPONIBLE'' THEN 0';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(AG.TIPO,'''') NOT IN (''DISPONIBLE'',''POTENCIAL'') THEN 0';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_h'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ag_desc */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N''' data-ag="'' + K.AG + ''" data-q="''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N''' data-ag="'' + K.AG + ''" data-agd="'' + ISNULL(REPLACE(REPLACE(REPLACE(STUFF((' + NCHAR(10) + N'                       SELECT ''|'' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @HOY, A2.FECHA)) + '':'' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(NULLIF(CONVERT(VARCHAR(400), A2.DESCRIPCION),''''), ISNULL(CONVERT(VARCHAR(400), A2.MOTIVO),'''')))), ''|'', ''/''), CHAR(13), '' ''), CHAR(10), '' '')' + NCHAR(10) + N'                       FROM dbo.VCT_PRM_AGENDA_CONSULTOR A2 WITH(NOLOCK)' + NCHAR(10) + N'                       WHERE A2.ID_CONSULTOR = K.ID AND A2.FECHA BETWEEN CONVERT(DATE, @HOY) AND CONVERT(DATE, DATEADD(DAY, @AG_ND - 1, @HOY))' + NCHAR(10) + N'                         AND ISNULL(A2.TIPO,'''') <> ''DISPONIBLE'' AND LTRIM(RTRIM(ISNULL(NULLIF(CONVERT(VARCHAR(400), A2.DESCRIPCION),''''), ISNULL(CONVERT(VARCHAR(400), A2.MOTIVO),'''')))) <> ''''' + NCHAR(10) + N'                       ORDER BY A2.FECHA FOR XML PATH(''''), TYPE).value(''.'',''VARCHAR(MAX)''), 1, 1, ''''), ''&'',''&amp;''), ''"'',''&quot;''), ''<'',''&lt;''), '''') + ''" data-q="''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_desc'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* modal_can */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'''" data-pv-ag-tpl="''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'''" data-pv-ag-canag="'' + CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, ''AGENDA_CONSULTOR'') AA WHERE UPPER(ISNULL(AA.ACTION_TYPE,'''')) = ''EDIT'') THEN ''1'' ELSE ''0'' END + ''" data-pv-ag-tpl="''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' modal_can'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=55"><script src="../js/vct-proyecto-v360.js?v=46"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=56"><script src="../js/vct-proyecto-v360.js?v=47"';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_AGD_V1). Subir vct-proyecto-v360.css (v56) y vct-proyecto-v360.js (v47).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
