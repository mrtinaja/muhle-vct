 
/* ---------------- 1. valor permitido por CHECK ---------------- */
/* Devuelve el primer candidato (lista separada por comas) que acepta la
   restriccion CHECK de la columna; si no hay restriccion, el primero. */
CREATE   FUNCTION dbo.VCT_CK_VALOR (@TABLA SYSNAME, @COLUMNA SYSNAME, @CANDIDATOS VARCHAR(400))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @DEF NVARCHAR(MAX) = NULL, @L VARCHAR(500) = ISNULL(@CANDIDATOS,'') + ',', @C VARCHAR(50),
            @P INT, @PRIMERO VARCHAR(50) = NULL, @R VARCHAR(50) = NULL;
 
    SELECT @DEF = ISNULL(@DEF, N'') + CC.definition
    FROM sys.check_constraints CC
    WHERE CC.parent_object_id = OBJECT_ID(@TABLA)
      AND CC.definition LIKE N'%' + @COLUMNA + N'%';
 
    SET @P = CHARINDEX(',', @L);
    WHILE @P > 0 AND @R IS NULL
    BEGIN
        SET @C = LTRIM(RTRIM(LEFT(@L, @P - 1)));
        SET @L = SUBSTRING(@L, @P + 1, 500);
        IF @C <> ''
        BEGIN
            IF @PRIMERO IS NULL SET @PRIMERO = @C;
            IF @DEF IS NULL OR @DEF LIKE N'%''' + @C + N'''%' SET @R = @C;
        END;
        SET @P = CHARINDEX(',', @L);
    END;
    RETURN ISNULL(@R, @PRIMERO);
END
