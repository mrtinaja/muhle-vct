CREATE PROCEDURE [dbo].[EP_EQUIPO_CERTIF_VIGENTE]
(@IPKEYJOB	AS VARCHAR(100),
 @RTA AS VARCHAR(1000) OUTPUT)
AS
 
BEGIN
 
	DECLARE 
	@EQ_SEL VARCHAR(36),
	@EQ_CERTIF_SEL VARCHAR(36),
	@ESTADO VARCHAR(50),
	@CANT INT
 
	SELECT @EQ_SEL=EQ_SEL, @EQ_CERTIF_SEL=EQ_CERTIF_SEL FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
	if isnull(@EQ_CERTIF_SEL,'') =''
		begin
			SET @RTA=''
			return
		end
 
	SELECT @ESTADO=ESTADO FROM EP_EQUIPOS_CERTIF WHERE ID = @EQ_CERTIF_SEL;
 
	IF @ESTADO='VIGENTE'
		BEGIN
			UPDATE EP_EQUIPOS_CERTIF 
			SET ESTADO='NO-VIGENTE'
			WHERE ID = @EQ_CERTIF_SEL;
		END
	ELSE
		BEGIN
 
			SELECT @CANT=COUNT(*) FROM EP_EQUIPOS_CERTIF WHERE IdEquipo=@EQ_SEL AND ESTADO='VIGENTE' AND ID<>@EQ_CERTIF_SEL;
			
			IF @CANT>0
				BEGIN
					SET @RTA='<br><p><b><font color="red">Solo puede haber un certificado vigente por equipo. Debe primero sacar de vigencia los otros certificados.</font></b></p>'
				END
			ELSE
				BEGIN
					UPDATE EP_EQUIPOS_CERTIF 
					SET ESTADO='VIGENTE'
					WHERE ID = @EQ_CERTIF_SEL;
				
					SET @RTA='<br><p><b><font color="red">Certificado se cambio a vigente.</font></b></p>'
				END
		END
 
END
