 
CREATE FUNCTION [dbo].[FN_GET_CONSULTORES] (@IAGENDA INT)
RETURNS @TempTable TABLE (
   CAT_DATA_CODE	VARCHAR(50),
   CAT_DATA_DESC	varchar(400),
   TRUE				VARCHAR(50)
) 
AS
BEGIN
	DECLARE @VCONSULTOR		VARCHAR(100),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VID			VARCHAR(50),
		@VALOR			VARCHAR(400)
 
	SELECT	@VCONSULTOR = ISNULL(ID_CONSULTOR,'')
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @IAGENDA
 
	IF (@VCONSULTOR <> '') BEGIN
		WHILE LEN(@VCONSULTOR) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VCONSULTOR) -- Busca el caracter a separador
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VCONSULTOR
					SET @VCONSULTOR = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VCONSULTOR, 1, @lnuPosComa - 1)
				
					SELECT	@VID = CONVERT(VARCHAR,ID_EMPLEADO), @VALOR = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
					FROM	LK_EMPLEADOS
					WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
 
					insert into @TempTable
					select @VID, @VALOR, 'true'
 
					SET @VCONSULTOR = SUBSTRING(@VCONSULTOR, @lnuPosComa + 1, LEN(@VCONSULTOR))
				END
			END
	END ELSE BEGIN
		insert into @TempTable
		select 'SC', 'Sin Consultor', 'true'
	END
   RETURN;
END
