 
CREATE FUNCTION [dbo].[FN_GET_NORMA2] (@ISTRING VARCHAR(400), @INORMA INT)
RETURNS VARCHAR(50)
AS BEGIN
    DECLARE @VNORMAS	VARCHAR(4000),
			@RESULTADO	INT,
			@N			INT,
			@VCHECKED	VARCHAR(50),
			@lstDato		varchar(100), 
			@lnuPosComa		int ,
			@VALOR			VARCHAR(400),
			@VTORF			VARCHAR(50)
 
	SET	@VNORMAS = ISNULL(@ISTRING,'')
				
	WHILE LEN(@VNORMAS) > 0
	BEGIN 
		SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
		IF (@lnuPosComa = 0) BEGIN 
			SET @lstDato = @VNORMAS
			SET @VNORMAS = '' 
		END ELSE BEGIN
			SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
			SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
			SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
			IF (@INORMA = @VALOR) BEGIN
				SET @VCHECKED = ISNULL(@VTORF,'false')
			END
 
			SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
		END
	END
 
	RETURN ISNULL(@VCHECKED,'false')
 
END
