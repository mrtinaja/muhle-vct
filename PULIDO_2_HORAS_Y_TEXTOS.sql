/* ========================================================================
   PULIDO_2_HORAS_Y_TEXTOS
   ------------------------------------------------------------------------
   Detalles encontrados probando con svocaturo:
     1. dbo.VCT_FMT_HORAS: separador de miles y coma decimal
        (27999 -> 27.999 ; 7.5 -> 7,5). Lo usan Visitas y el Inicio.
     2. dbo.VCT_PROYECTO_AVANCE: el detalle del KPI "Avance proyecto" decia
        "plan estrategico" sin tilde.
     3. Vista 360 de Proyecto carga vct-proyecto-visitas.css v3 (breadcrumb
        en celular). Subir antes vct-proyecto-visitas.css.
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------- 1. horas con separador de miles ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_FMT_HORAS (@H DECIMAL(12,2))
RETURNS VARCHAR(20)
AS
BEGIN
    IF @H IS NULL RETURN '0';
    /* MONEY estilo 1 = 27,999.50 -> se invierten los separadores */
    DECLARE @S VARCHAR(30) = CONVERT(VARCHAR(30), CAST(ROUND(@H, 1) AS MONEY), 1);
    SET @S = REPLACE(REPLACE(REPLACE(@S, ',', '#'), '.', ','), '#', '.');
    IF RIGHT(@S, 3) = ',00' SET @S = LEFT(@S, LEN(@S) - 3)
    ELSE IF RIGHT(@S, 1) = '0' AND CHARINDEX(',', @S) > 0 SET @S = LEFT(@S, LEN(@S) - 1);
    RETURN @S;
END
GO
SELECT dbo.VCT_FMT_HORAS(27999) AS A_27999, dbo.VCT_FMT_HORAS(7.5) AS A_7_5, dbo.VCT_FMT_HORAS(8) AS A_8, dbo.VCT_FMT_HORAS(1234.25) AS A_1234_25;
GO

/* ---------------- 2. tilde en el detalle del avance ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_PROYECTO_AVANCE'));
IF @D IS NULL
    PRINT 'No existe dbo.VCT_PROYECTO_AVANCE.';
ELSE IF CHARINDEX(N'CHAR(233)', @D) > 0
    PRINT 'VCT_PROYECTO_AVANCE ya tenia las tildes.';
ELSE
BEGIN
    SET @D = REPLACE(@D, N'''Plan estrategico: ''', N'''Plan estrat'' + CHAR(233) + ''gico: ''');
    SET @D = REPLACE(@D, N'''Lanzado - plan estrategico pendiente''', N'''Lanzado - plan estrat'' + CHAR(233) + ''gico pendiente''');
    /* CREATE -> ALTER solo en el encabezado (las 40 letras antes de FUNCTION) */
    DECLARE @kp INT = CHARINDEX(N'FUNCTION', @D), @kpre NVARCHAR(60);
    SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
    IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
        SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK: VCT_PROYECTO_AVANCE con tildes.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE() + ' (sin cambios)';
    END CATCH;
END;
GO

/* ---------------- 3. css v3 en la 360 de proyecto ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
IF CHARINDEX(N'vct-proyecto-visitas.css?v=2', @D) = 0
    PRINT 'VCT_MAIN_PROYECTO_V360: no carga vct-proyecto-visitas.css?v=2 (ya actualizado?). Sin cambios.';
ELSE
BEGIN
    SET @D = REPLACE(@D, N'vct-proyecto-visitas.css?v=2', N'vct-proyecto-visitas.css?v=3');
    /* CREATE -> ALTER solo en el encabezado (las 40 letras antes de PROCEDURE) */
    DECLARE @kp INT = CHARINDEX(N'PROCEDURE', @D), @kpre NVARCHAR(60);
    SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
    IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
        SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK: VCT_MAIN_PROYECTO_V360 carga vct-proyecto-visitas.css v3.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE() + ' (sin cambios)';
    END CATCH;
END;
GO
