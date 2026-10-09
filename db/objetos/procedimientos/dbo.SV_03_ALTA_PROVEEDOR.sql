CREATE PROCEDURE [dbo].[SV_03_ALTA_PROVEEDOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VCUIT			VARCHAR(50),
		@VRAZON_SOCIAL	VARCHAR(300),
		@VCALLE			VARCHAR(100),
		@VNRO			VARCHAR(30),
		@VPISO			VARCHAR(30),
		@VLOCALIDAD		VARCHAR(100),
		@VPROVINCIA		VARCHAR(50),
		@VTELEFONO1		VARCHAR(100),
		@VTELEFONO2		VARCHAR(100),
		@VEMAIL			VARCHAR(100),
		@VIVA			VARCHAR(50),
		@VTIPO_PROV		VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VOBSERVACIONES	VARCHAR(400),
		@VERROR			VARCHAR(50),
		@VCANT			INT
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VCUIT = ISNULL(CUIT,''),
			@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL,''),
			@VCALLE = ISNULL(CALLE,''),
			@VNRO = ISNULL(NRO,''),
			@VPISO = ISNULL(PISO,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD,''),
			@VPROVINCIA = ISNULL(PROVINCIA,''),
			@VTELEFONO1 = ISNULL(TELEFONO1,''),
			@VTELEFONO2 = ISNULL(TELEFONO2,''),
			@VEMAIL = ISNULL(EMAIL,''),
			@VIVA = ISNULL(IVA,''),
			@VTIPO_PROV = ISNULL(TIPO_PROVEEDOR,''),
			@VESTADO = ISNULL(ESTADO,''),
			@VOBSERVACIONES = ISNULL(OBSERVACIONES,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_03
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VCUIT = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo CUIT</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VRAZON_SOCIAL = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Razon Social</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VLOCALIDAD = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = ' <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Localidad</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VPROVINCIA = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Provincia</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VTIPO_PROV = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Tipo Proveedor</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VESTADO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Estado</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA EL MISMO CLIENTE EN LK_PROVEEDORES--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_PROVEEDORES
		WHERE	CUIT_PROV = LTRIM(RTRIM(@VCUIT))
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Proveedor para el CUIT ingresado</b></font>
							  </div>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			--VALIDO QUE NO EXISTA LA MISMA RAZON SOCIAL EN LK_PROVEEDORES--
			SELECT	@VCANT = COUNT(1)
			FROM	LK_PROVEEDORES
			WHERE	RAZON_SOCIAL_PROV = LTRIM(RTRIM(@VRAZON_SOCIAL))
 
			IF (@VCANT > 0) BEGIN
		
				SET @OCODE = '1'
				SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Proveedor con la misma Razon Social ingresada</b></font>
							  </div>'
									
				UPDATE	TMT_SV_03
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
		
			END ELSE BEGIN
 
				INSERT INTO LK_PROVEEDORES
				(RAZON_SOCIAL_PROV, CUIT_PROV, CALLE_PROV, NRO_CALLE_PROV, PISO_DEPTO_PROV,
				 LOCALIDAD_PROV, PROVINCIA_PROV, TEL1_PROV, TEL2_PROV, EMAIL_PROV, IVA_PROV,
				 TIPO_PROV, STATUS_PROV, OBSERV_PROV,
				 FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
				VALUES
				(@VRAZON_SOCIAL, @VCUIT, @VCALLE, @VNRO, @VPISO, 
				 @VLOCALIDAD, @VPROVINCIA, @VTELEFONO1, @VTELEFONO2, @VEMAIL, @VIVA,
				 @VTIPO_PROV, @VESTADO, @VOBSERVACIONES,
				 GETDATE(), @IAGENTE, GETDATE(), @IAGENTE)
 
			END
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_03
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
 
