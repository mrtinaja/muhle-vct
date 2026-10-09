CREATE PROCEDURE [dbo].[EP_ADD_EQUIPO_CERTIF]
(@IPKEYJOB	AS VARCHAR(100),
 @RTA AS VARCHAR(1000) OUTPUT)
AS
 
BEGIN
 
	DECLARE 
	@NEW_ID VARCHAR(36),
	@FECHA_DESDE DATE,
	@FECHA_HASTA DATE,
	@EQ_SEL VARCHAR(36),
	@ACTION VARCHAR(50),
	@CANT INT
 
	SELECT @EQ_SEL=EQ_SEL, @FECHA_DESDE= EQ_FECHA_DESDE, @FECHA_HASTA=EQ_FECHA_HASTA, @ACTION=[ACTION] FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
	IF @ACTION IN ('EDIT_EQUIPO')
		BEGIN 
			SET @RTA='';
			RETURN
		END
 
	IF @FECHA_DESDE IS NULL OR @FECHA_HASTA IS NULL
		BEGIN 
			SET @RTA='<br><p><b><font color="red">La fecha desde y hasta son obligatorios.</font></b></p>'
		END
	else
		BEGIN
 
			SELECT @CANT=COUNT(*) FROM EP_EQUIPOS_CERTIF WHERE IdEquipo=@EQ_SEL AND ESTADO='VIGENTE'
			
			IF @CANT>0
				BEGIN
					SET @RTA='<br><p><b><font color="red">Solo puede haber un certificado vigente por equipo. Debe primero sacar de vigencia los otros certificados.</font></b></p>'
				END
			ELSE
				BEGIN
					SET @NEW_ID=NEWID();
 
					INSERT INTO EP_EQUIPOS_CERTIF VALUES (@NEW_ID, @EQ_SEL, @FECHA_DESDE, @FECHA_HASTA, 'VIGENTE')
 
					UPDATE PHYSICAL_ATTACHED_DOCUMENT SET PAR_KEY=@NEW_ID WHERE PAR_KEY=@IPKEYJOB
				
					SET @RTA='<br><p><b><font color="red">Certificado agregado con éxito.</font></b></p>'
				END
		END
 
END
