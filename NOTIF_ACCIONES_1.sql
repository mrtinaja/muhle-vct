/* ============================================================================
   NOTIF_ACCIONES_1  (28/10/2026)  marca NOTIF_ACC_V1
   ----------------------------------------------------------------------------
   Notificaciones del header (campanita):
   1. dbo.VCT_NOTIF_GENERAR
      - "Nueva accion: ..." y "Accion vencida: ..." (antes decia gestion).
      - "Visita sin registrar": deja de generarse si la visita ya tiene un desarrollo realizado
        o si esta cancelada / anulada. Texto: "carga el desarrollo realizado".
   2. dbo.VCT_NOTIF_RENDER
      - Las ya guardadas que dicen "Nueva gestion" / "Gestion vencida" se muestran como accion
        (no se modifica ningun dato).
      - Visita sin registrar: no se muestra si la visita ya tiene desarrollo realizado.
      - Clic en Visita sin registrar: va a la V360 del proyecto, pestania Visitas.
        Clic en Horas excedidas: va a la V360 del proyecto. Las de acciones siguen yendo a Acciones.
   3. dbo.VCT_GET_HEADER: js/vct-notif.js ?v=3 (subir el archivo).
   Cada parte: si un punto no se encuentra, NO se cambia ese SP. Re-ejecutable.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_NOTIF_GENERAR')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_NOTIF_GENERAR.';
ELSE IF CHARINDEX(N'NOTIF_ACC_V1', @D) > 0
    PRINT 'OK   el parche NOTIF_ACC_V1 ya estaba aplicado: no se hizo nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* gen_nueva */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'''Nueva gesti'' + CHAR(243) + ''n: '' + G.TITULO';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'''Nueva acci'' + CHAR(243) + ''n: '' /* NOTIF_ACC_V1 */ + G.TITULO';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' gen_nueva'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* gen_vencida */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'LEFT(''Gesti'' + CHAR(243) + ''n vencida: '' + G.TITULO, 300)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'LEFT(''Acci'' + CHAR(243) + ''n vencida: '' + G.TITULO, 300)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' gen_vencida'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* gen_vis_txt */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N''' - cargale los temas trabajados'', 1000)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N''' - carg'' + CHAR(225) + '' el desarrollo realizado'', 1000)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' gen_vis_txt'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* gen_vis_cond */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'          AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R WHERE R.ID_VISITA = V.ID);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'          AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R WHERE R.ID_VISITA = V.ID)' + NCHAR(10) + N'          /* NOTIF_ACC_V1: registrada = con desarrollo realizado; las canceladas no avisan */' + NCHAR(10) + N'          AND NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO DR WHERE DR.ID_VISITA = V.ID AND DR.TIPO = ''REALIZADO'')' + NCHAR(10) + N'          AND UPPER(LTRIM(RTRIM(ISNULL(V.ESTADO, '''')))) NOT IN (''CANCELADO'', ''ANULADO'');';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' gen_vis_cond'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
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
            PRINT 'OK   VCT_NOTIF_GENERAR actualizado (NOTIF_ACC_V1).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_NOTIF_GENERAR (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO

/* ---------- 2. dbo.VCT_NOTIF_RENDER ---------- */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_NOTIF_RENDER')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_NOTIF_RENDER.';
ELSE IF CHARINDEX(N'NOTIF_ACC_V1', @D) > 0
    PRINT 'OK   el parche NOTIF_ACC_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'NOTIF_HEADER_V2', @D) = 0
    PRINT 'FALLO: falta NOTIF_RENDER_FIX2. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* ren_link */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'''<button type="button" class="vct-notif-link" data-vct-notif-tab="'' + ISNULL(NT.TAB, ''todas'') + ''">'' + REPLACE(REPLACE(REPLACE(ISNULL(N.TITULO, ''''), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') /* NOTIF_HEADER_V2 */';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'''<button type="button" class="vct-notif-link" data-vct-notif-tab="'' + ISNULL(NT.TAB, ''todas'') + ''"''' + NCHAR(10) + N'          /* NOTIF_ACC_V1: visita / horas van a la V360 del proyecto; titulos de acciones */' + NCHAR(10) + N'          + CASE WHEN N.TIPO IN (''VISITA'', ''HORAS'') AND N.ID_PROYECTO IS NOT NULL' + NCHAR(10) + N'                 THEN '' data-vct-notif-proy="'' + CONVERT(VARCHAR(20), N.ID_PROYECTO) + ''" data-vct-notif-cli="'' + CONVERT(VARCHAR(20), ISNULL(N.ID_CLIENTE, 0)) + ''"''' + NCHAR(10) + N'                    + '' data-vct-notif-guid="330B876D-4E57-4E2E-BFC3-D7B998D09725" data-vct-notif-v360="'' + CASE WHEN N.TIPO = ''VISITA'' THEN ''agenda'' ELSE ''resumen'' END + ''"'' ELSE '''' END + ''>''' + NCHAR(10) + N'          + ISNULL(CASE WHEN N.TITULO LIKE ''Nueva gesti_n: %'' THEN ''Nueva acci&oacute;n: '' + REPLACE(REPLACE(REPLACE(SUBSTRING(N.TITULO, 16, 300), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') WHEN N.TITULO LIKE ''Gesti_n vencida: %'' THEN ''Acci&oacute;n vencida: '' + REPLACE(REPLACE(REPLACE(SUBSTRING(N.TITULO, 18, 300), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') ELSE NULL END, REPLACE(REPLACE(REPLACE(ISNULL(N.TITULO, ''''), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'')) /* NOTIF_HEADER_V2 */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ren_link'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ren_filtro */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'        WHERE N.USUARIO = @U' + NCHAR(10) + N'        ORDER BY N.LEIDA, N.FECHA DESC, N.ID DESC';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'        WHERE N.USUARIO = @U' + NCHAR(10) + N'          AND NOT (N.TIPO = ''VISITA'' AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO DR WITH(NOLOCK) WHERE CONVERT(VARCHAR(20), DR.ID_VISITA) = N.CLAVE AND DR.TIPO = ''REALIZADO''))   /* NOTIF_ACC_V1: visita ya con desarrollo realizado */' + NCHAR(10) + N'        ORDER BY N.LEIDA, N.FECHA DESC, N.ID DESC';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ren_filtro'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ren_cuenta */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'SELECT @NL = COUNT(*) FROM dbo.VCT_NOTIFICACIONES WHERE USUARIO = @U AND LEIDA = 0;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'SELECT @NL = COUNT(*) FROM dbo.VCT_NOTIFICACIONES N WHERE N.USUARIO = @U AND N.LEIDA = 0 AND NOT (N.TIPO = ''VISITA'' AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_DESARROLLO DR WITH(NOLOCK) WHERE CONVERT(VARCHAR(20), DR.ID_VISITA) = N.CLAVE AND DR.TIPO = ''REALIZADO''));';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ren_cuenta'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
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
            PRINT 'OK   VCT_NOTIF_RENDER actualizado (NOTIF_ACC_V1).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_NOTIF_RENDER (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO

/* ---------- 3. dbo.VCT_GET_HEADER ---------- */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_GET_HEADER')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_GET_HEADER.';
ELSE IF CHARINDEX(N'vct-notif.js?v=3', @D) > 0
    PRINT 'OK   el parche vct-notif.js?v=3 ya estaba aplicado: no se hizo nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* header_js */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-notif.js?v=2"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-notif.js?v=3"';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' header_js'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
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
            PRINT 'OK   VCT_GET_HEADER carga vct-notif.js v=3. Subir js/vct-notif.js.';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_GET_HEADER (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
