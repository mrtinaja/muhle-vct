 
CREATE FUNCTION [dbo].[FN_GET_VALOR] (@ISTRING VARCHAR(400), @ID VARCHAR(100))
RETURNS VARCHAR(50)
AS BEGIN
    DECLARE @VVALORES	VARCHAR(4000),
			@RESULTADO	VARCHAR(100),
			@N			INT,
			@lstDato		varchar(100), 
			@lnuPosComa		int ,
			@VALOR			VARCHAR(400),
			@VID			VARCHAR(100)
 
	SET	@VVALORES = ISNULL(@ISTRING,'')
				
	WHILE LEN(@VVALORES) > 0
	BEGIN 
		SET @lnuPosComa = CHARINDEX('|', @VVALORES) -- Busca el caracter a separador
		IF (@lnuPosComa = 0) BEGIN 
			SET @lstDato = @VVALORES
			SET @VVALORES = '' 
		END ELSE BEGIN
			SET @lstDato = SUBSTRING(@VVALORES, 1, @lnuPosComa - 1)
			SET @VID = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
			SET @VALOR = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
			IF (@VID = @ID) BEGIN
				SET @RESULTADO = @VALOR 
			END
 
			SET @VVALORES = SUBSTRING(@VVALORES, @lnuPosComa + 1, LEN(@VVALORES))
		END
	END
 
	RETURN ISNULL(@RESULTADO,'')
 
END
