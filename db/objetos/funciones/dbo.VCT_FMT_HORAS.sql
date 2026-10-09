 
/* ---------------- 1. horas con separador de miles ---------------- */
CREATE   FUNCTION dbo.VCT_FMT_HORAS (@H DECIMAL(12,2))
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
