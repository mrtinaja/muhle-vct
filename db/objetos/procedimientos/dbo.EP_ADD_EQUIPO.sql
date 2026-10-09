CREATE PROCEDURE [dbo].[EP_ADD_EQUIPO]
(@IPKEYJOB	AS VARCHAR(100),
 @RTA AS VARCHAR(1000) OUTPUT)
AS
 
BEGIN
 
	DECLARE 
	@TIPO_EQ VARCHAR(50),
	@NRO_EQUIPO INT,
	@MARCA_MODELO VARCHAR(300),
	@NRO_SERIE VARCHAR(300),
	@ESTADO VARCHAR(50),
	@ACTION VARCHAR(50),
	@CANT AS INT;
 
	SELECT @TIPO_EQ= EQ_TIPO, @NRO_EQUIPO=EQ_NRO, @MARCA_MODELO=EQ_MARCA_MOD, @NRO_SERIE=EQ_NRO_SERIE,
		@ESTADO = EQ_ESTADO, @ACTION=[ACTION] FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
	
	IF @ACTION IN ('EQUIPOS', 'EDIT_EQUIPO', 'DEL_EQUIPO','SEARCH_EQUIPO')
		BEGIN 
			SET @RTA='';
			RETURN
		END
	IF @ACTION IN ('ADD_EQUIPO')
		BEGIN 
		IF @NRO_EQUIPO =0
			BEGIN 
				SET @RTA='<br><p><b><font color="red">El número de equipo es obligatorio.</font></b></p>'
				RETURN
			END
 
		select @CANT=count(*) from EP_EQUIPOS where TipoEquipo = @TIPO_EQ AND NroEquipo =@NRO_EQUIPO;
		IF @CANT > 0 
			BEGIN
 
				SET @RTA='<br><p><b><font color="red">Ya existe ese TIPO de equipo con ese Nro de Equipo.</font></b></p>'
				RETURN
			END
		ELSE
			BEGIN
				UPDATE TMT_CRON 
				SET [ACTION]='ADD_EQUIPO'
				WHERE PAR_KEY= @IPKEYJOB;
 
				INSERT INTO EP_EQUIPOS VALUES (newid(), @TIPO_EQ, @NRO_EQUIPO, @MARCA_MODELO, @NRO_SERIE,@ESTADO)
				
				SET @RTA='<br><p><b><font color="red">Equipo creado con exito.</font></b></p>'
 
			END
	END
 
END
