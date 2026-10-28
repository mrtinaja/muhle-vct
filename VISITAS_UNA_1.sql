/* ============================================================================
   VISITAS_UNA_1  (28/10/2026)  marca VIS_UNA_V1   (despues de VISITAS_AGENDA_DIA_2.sql)
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_PROYECTO_V360, Nueva / Editar visita:
   - El alta crea UNA visita con todos los consultores elegidos (antes, una por consultor).
     Las horas de la visita = suma de las horas de cada consultor.
   - Al editar se pueden sumar o quitar consultores.
   - El desarrollo sobre acciones ya se carga por visita y consultor, con el tope de horas de cada uno.
   - Las visitas ya cargadas no se tocan.
   - Assets: vct-proyecto-v360.js ?v=49 (el css no cambia).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_UNA_V1', @D) > 0
    PRINT 'OK   el parche VIS_UNA_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'VIS_AGD_V2', @D) = 0
    PRINT 'FALLO: falta aplicar antes VISITAS_AGENDA_DIA_2.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* una_vid */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                    /* la visita: en la edicion, la misma para todos sus consultores; en el alta, una por consultor */' + NCHAR(10) + N'                    IF @AG_ID IS NOT NULL SET @AG_VID = @AG_ID' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                    /* VIS_UNA_V1: una sola visita para todos sus consultores (alta: se crea con el primero; edicion: la misma) */' + NCHAR(10) + N'                    IF @AG_ID IS NOT NULL OR @AG_NG > 0 SET @AG_VID = ISNULL(@AG_ID, @AG_VID)' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' una_vid'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* una_normas */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'IF @AG_ID IS NULL OR @AG_I = (SELECT MIN(ORD) FROM @AGC)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'IF @AG_I = (SELECT MIN(ORD) FROM @AGC)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' una_normas'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* una_edit */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            ELSE IF @AG_ID IS NOT NULL AND (SELECT COUNT(*) FROM @AGC) > CASE WHEN @AG_ORIG_N > 1 THEN @AG_ORIG_N ELSE 1 END' + NCHAR(10) + N'                SET @ERR = ''Al editar, la visita conserva su cantidad de consultores. Para sumar otro consultor use Agregar.''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'');
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' una_edit'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* una_msg */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE CONVERT(VARCHAR(10), @AG_NG) + '' visita(s) agendada(s): una por consultor.'' END';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ELSE ''Visita agendada con '' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM @AGC)) + '' consultor(es).'' END';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' una_msg'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=56"><script src="../js/vct-proyecto-v360.js?v=48"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=56"><script src="../js/vct-proyecto-v360.js?v=49"';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_UNA_V1). Subir vct-proyecto-v360.js (v49).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
