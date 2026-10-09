CREATE FUNCTION dbo.FN_VCT_LIMPIA_TELEFONO
(
    @TELEFONO VARCHAR(100)
)
RETURNS VARCHAR(30)
AS
BEGIN
 
    DECLARE @RESULTADO VARCHAR(30) = '';
    DECLARE @I INT = 1;
    DECLARE @CARACTER CHAR(1);
    DECLARE @POS INT;
 
 
    IF @TELEFONO IS NULL
        RETURN NULL;
 
 
    SET @TELEFONO = LTRIM(RTRIM(@TELEFONO));
 
 
    /* --------------------------------------------------------
       ELIMINAR TODO LO QUE ESTÉ DESPUÉS DE UN PARÉNTESIS
       Ej:
       011-5022-3276 (Luis Silvestrini)
       queda:
       011-5022-3276
       -------------------------------------------------------- */
 
    SET @POS = CHARINDEX('(', @TELEFONO);
 
    IF @POS > 0
        SET @TELEFONO = LEFT(@TELEFONO, @POS - 1);
 
 
    /* --------------------------------------------------------
       DEJAR SOLAMENTE DÍGITOS
       -------------------------------------------------------- */
 
    WHILE @I <= LEN(@TELEFONO)
    BEGIN
 
        SET @CARACTER = SUBSTRING(@TELEFONO, @I, 1);
 
        IF @CARACTER LIKE '[0-9]'
            SET @RESULTADO = @RESULTADO + @CARACTER;
 
        SET @I = @I + 1;
 
    END;
 
 
    IF ISNULL(@RESULTADO, '') = ''
        RETURN NULL;
 
 
    /* --------------------------------------------------------
       QUITAR CÓDIGO DE PAÍS 54
       Ej: +541160601804 -> 1160601804
       -------------------------------------------------------- */
 
    IF LEFT(@RESULTADO, 2) = '54'
        SET @RESULTADO = SUBSTRING(@RESULTADO, 3, LEN(@RESULTADO));
 
 
    /* --------------------------------------------------------
       QUITAR 0 INICIAL
       Ej: 01143410340 -> 1143410340
           02324434406 -> 2324434406
       -------------------------------------------------------- */
 
    IF LEFT(@RESULTADO, 1) = '0'
        SET @RESULTADO = SUBSTRING(@RESULTADO, 2, LEN(@RESULTADO));
 
 
    RETURN NULLIF(@RESULTADO, '');
 
END;
