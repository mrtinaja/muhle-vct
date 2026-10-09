CREATE FUNCTION [dbo].[FN_GET_SELECCION] (@ISTRING VARCHAR(4000))
RETURNS VARCHAR(400)
AS BEGIN
    DECLARE @VSELECCION	VARCHAR(4000),
			@VALOR		VARCHAR(400),
			@RESULTADO	INT,
			@N			INT,
			@VEXISTE	VARCHAR(50),
			@lstDato		varchar(100), 
			@lnuPosComa		int ,
			@VTORF			VARCHAR(50)
 
	IF (@ISTRING <> '') BEGIN
		WHILE LEN(@ISTRING) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @ISTRING) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @ISTRING
				SET @ISTRING = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@ISTRING, 1, @lnuPosComa - 1)
				--SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
				SET @VALOR = ISNULL(@VALOR,'') + SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1) + '|'
 
 
				SET @ISTRING = SUBSTRING(@ISTRING, @lnuPosComa + 1, LEN(@ISTRING))
			END
		END
	END
 
	RETURN ISNULL(@VALOR,'')
 
END
