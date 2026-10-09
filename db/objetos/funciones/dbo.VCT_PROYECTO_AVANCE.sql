 
/* ---------------- 3. avance del proyecto (se recrea) ---------------- */
CREATE   FUNCTION dbo.VCT_PROYECTO_AVANCE (@ID_PROYECTO INT)
RETURNS @R TABLE (AVANCE INT, DETALLE VARCHAR(200))
AS
BEGIN
    DECLARE @COD VARCHAR(50), @PASOS INT = 0, @NITEMS INT = 0, @PLAN DECIMAL(9,2) = 0, @V DECIMAL(9,2),
            @GT INT = 0, @GC INT = 0;
 
    SELECT @COD = ISNULL(ESTADO_CODIGO, ''),
           @PASOS = CASE WHEN ISNULL(CONSULTORES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(DATOS_CARGADOS,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(CONSIDERACIONES,0) > 0 THEN 1 ELSE 0 END
                  + CASE WHEN ISNULL(REUNION_OK,0) = 1 THEN 1 ELSE 0 END
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);
 
    IF @COD LIKE 'FINALIZ%' OR @COD LIKE 'CERRAD%' OR @COD LIKE 'TERMIN%' OR @COD LIKE 'COMPLET%'
    BEGIN
        INSERT INTO @R VALUES (100, 'Proyecto finalizado');
        RETURN;
    END;
 
    SELECT @NITEMS = COUNT(*),
           @PLAN = ISNULL(AVG(CAST(C.AVANCE AS DECIMAL(9,2))), 0),
           @GT = ISNULL(SUM(C.G_TOTAL), 0),
           @GC = ISNULL(SUM(C.G_CUMPLIDAS), 0)
    FROM dbo.VCT_PROYECTO_PLAN_CALC(@ID_PROYECTO) C;
 
    IF @COD = 'ENCURSO' OR @NITEMS > 0 SET @PASOS = 4;
 
    SET @V = @PASOS * 2.5 + @PLAN * 0.9;
    IF @V > 100 SET @V = 100;
 
    INSERT INTO @R VALUES (
        CAST(ROUND(@V, 0) AS INT),
        CASE WHEN @NITEMS > 0 THEN 'Plan estrat' + CHAR(233) + 'gico: ' + CASE WHEN ROUND(@PLAN,1) = FLOOR(ROUND(@PLAN,1)) THEN CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS INT))
                                                     ELSE REPLACE(CONVERT(VARCHAR(10), CAST(ROUND(@PLAN,1) AS DECIMAL(5,1))), '.', ',') END + '% ('
                                   + CONVERT(VARCHAR(10), @GC) + ' de ' + CONVERT(VARCHAR(10), @GT) + ' gestiones)'
             WHEN @COD = 'ENCURSO' THEN 'Lanzado - plan estrat' + CHAR(233) + 'gico pendiente'
             ELSE 'Lanzamiento: ' + CONVERT(VARCHAR(2), @PASOS) + ' de 4 pasos' END);
    RETURN;
END
