/* ========================================================================
   PROYECTO_LANZ_4_AVANCE
   ------------------------------------------------------------------------
   KPI "Avance proyecto" de la Vista 360 de Proyecto calculado en vivo
   (antes leia VCT_PROYECTOS.PORCENTAJE_AVANCE, que nadie actualiza).
     - Lanzamiento = 10% del proyecto: 2,5% por cada paso completo
       (equipo, datos de entrada, consideraciones, reunion). Si el
       proyecto ya esta En curso, el lanzamiento cuenta completo.
     - Plan Estrategico = 90%: promedio del avance de sus items.
     - Proyecto finalizado/cerrado = 100%.
   Debajo del porcentaje muestra en que etapa esta.
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_PROYECTO_V360.
   Si ya fue aplicado (marca AVANCE_V1), solo recrea la funcion.
   ======================================================================== */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_AVANCE (@ID_PROYECTO INT)
RETURNS @R TABLE (AVANCE INT, DETALLE VARCHAR(200))
AS
BEGIN
    DECLARE @COD VARCHAR(50), @PASOS INT = 0, @NITEMS INT = 0, @PLAN DECIMAL(9,2) = 0, @V DECIMAL(9,2);

    SELECT @COD = ISNULL(ESTADO_CODIGO, ''),
           @PASOS = CASE WHEN ISNULL(CONSULTORES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(DATOS_CARGADOS,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(CONSIDERACIONES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(REUNION_OK,0) = 1 THEN 1 ELSE 0 END
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);

    IF @COD LIKE 'FINALIZ%' OR @COD LIKE 'CERRAD%'
    BEGIN
        INSERT INTO @R VALUES (100, 'Proyecto finalizado');
        RETURN;
    END;

    SELECT @NITEMS = COUNT(*),
           @PLAN = ISNULL(AVG(CAST(ISNULL(I.PORCENTAJE_AVANCE,0) AS DECIMAL(9,2))), 0)
    FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
    INNER JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID = I.ID_PLAN
    WHERE PL.ID_PROYECTO = @ID_PROYECTO;

    IF @COD = 'ENCURSO' SET @PASOS = 4;

    SET @V = @PASOS * 2.5 + @PLAN * 0.9;
    IF @V > 100 SET @V = 100;

    INSERT INTO @R VALUES (
        CAST(ROUND(@V, 0) AS INT),
        CASE WHEN @NITEMS > 0 THEN 'Plan estrategico: ' + CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,0) AS INT)) + '% de ' + CONVERT(VARCHAR(10), @NITEMS) + ' items'
             WHEN @COD = 'ENCURSO' THEN 'Lanzado - plan estrategico pendiente'
             ELSE 'Lanzamiento: ' + CONVERT(VARCHAR(2), @PASOS) + ' de 4 pasos' END);
    RETURN;
END;
GO

SET NOCOUNT ON;
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'AVANCE_V1',@D) > 0
BEGIN
    PRINT 'OK: funcion VCT_PROYECTO_AVANCE actualizada (el SP ya tenia el parche).';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'/* el inicio del proyecto cambia el estado del encabezado */'),
 (N'<b>''+CONVERT(VARCHAR(10),@AVANCE)+''%</b>');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

/* ---- 1. calculo, despues de las acciones del lanzamiento ---- */
SET @s = CHARINDEX(N'/* el inicio del proyecto cambia el estado del encabezado */', @D);
SET @D = STUFF(@D, @s, 0, N'/* AVANCE_V1: avance calculado (lanzamiento 10% + plan 90%) */
DECLARE @AVANCE_DET VARCHAR(200) = '''';
BEGIN TRY
    SELECT @AVANCE = AVANCE, @AVANCE_DET = DETALLE FROM dbo.VCT_PROYECTO_AVANCE(@ID_PROYECTO);
END TRY
BEGIN CATCH
    SET @AVANCE_DET = '''';
END CATCH;

');

/* ---- 2. detalle debajo del porcentaje ---- */
SET @D = REPLACE(@D, N'<b>''+CONVERT(VARCHAR(10),@AVANCE)+''%</b>', N'<b>''+CONVERT(VARCHAR(10),@AVANCE)+''%</b>''+CASE WHEN @AVANCE_DET<>'''' THEN ''<small style="display:block;font-size:11px;font-weight:400;opacity:.75;margin-top:2px">''+@AVANCE_DET+''</small>'' ELSE '''' END+''');

/* ---- CREATE -> ALTER en el encabezado ---- */
DECLARE @p INT = CHARINDEX(N'PROCEDURE', @D), @pre NVARCHAR(60);
IF @p > 0
BEGIN
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
END;

IF PATINDEX(N'%ALTER%PROC%', @D) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTO_V360 con avance calculado.';
GO
