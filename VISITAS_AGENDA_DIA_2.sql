/* ============================================================================
   VISITAS_AGENDA_DIA_2  (28/10/2026)  marca VIS_AGD_V2   (despues de VISITAS_AGENDA_DIA_1.sql)
   ----------------------------------------------------------------------------
   Fix: el buffer solo guarda los campos que tiene el formulario de la V360 y no tiene TEXTO23 ni
   TEXTO24, asi que las horas por dia y los dias de 'Cargar disponible' no llegaban al SP (se tomaba
   el total repartido y los dias sin agenda frenaban). Ahora viajan en TEXTO15:
   'totales#horas por dia#dias a cargar'. Assets: vct-proyecto-v360.js ?v=48 (el css no cambia).
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, el SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_AGD_V2', @D) > 0
    PRINT 'OK   el parche VIS_AGD_V2 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'VIS_AGD_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes VISITAS_AGENDA_DIA_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* t15_max */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T15 VARCHAR(4000) = ''''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T15 VARCHAR(MAX) = ''''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t15_max'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t15_split */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'        DECLARE @AGP TABLE (CONS INT, FECHA DATE);   /* VIS_AGD_V1: dias sin agenda a cargar disponibles */';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'        DECLARE @AGP TABLE (CONS INT, FECHA DATE);   /* VIS_AGD_V1: dias sin agenda a cargar disponibles */' + NCHAR(10) + N'        /* VIS_AGD_V2: el formulario no tiene TEXTO23 / TEXTO24 (el buffer solo guarda sus campos): TEXTO15 = ''totales#horas por dia#dias a cargar'' */' + NCHAR(10) + N'        DECLARE @AG_PK15 VARCHAR(MAX) = '''';' + NCHAR(10) + N'        IF CHARINDEX(''#'', @AG_T15) > 0' + NCHAR(10) + N'        BEGIN' + NCHAR(10) + N'            SET @AG_PK15 = SUBSTRING(@AG_T15, CHARINDEX(''#'', @AG_T15) + 1, 2000000);' + NCHAR(10) + N'            SET @AG_T15 = LEFT(@AG_T15, CHARINDEX(''#'', @AG_T15) - 1);' + NCHAR(10) + N'            IF CHARINDEX(''#'', @AG_PK15) > 0' + NCHAR(10) + N'            BEGIN' + NCHAR(10) + N'                SET @AG_T24 = LTRIM(RTRIM(SUBSTRING(@AG_PK15, CHARINDEX(''#'', @AG_PK15) + 1, 2000000)));' + NCHAR(10) + N'                SET @AG_PK15 = LEFT(@AG_PK15, CHARINDEX(''#'', @AG_PK15) - 1);' + NCHAR(10) + N'            END;' + NCHAR(10) + N'            SET @AG_T23 = LTRIM(RTRIM(@AG_PK15));' + NCHAR(10) + N'        END;';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t15_split'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=56"><script src="../js/vct-proyecto-v360.js?v=47"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=56"><script src="../js/vct-proyecto-v360.js?v=48"';
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
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_AGD_V2). Subir vct-proyecto-v360.js (v48).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
