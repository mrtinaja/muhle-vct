CREATE PROCEDURE [dbo].[SV_02_MODIFY_CLIENTE]
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
		@VCONTACTO		VARCHAR(4000),
		@VTIPO_CLIENTE	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VOBSERVACIONES	VARCHAR(400),
		@VERROR			VARCHAR(50),
		@VCANT			INT,
		@VCLAVE			VARCHAR(100)
 
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
			@VCONTACTO = ISNULL(CONTACTO,''),
			@VTIPO_CLIENTE = ISNULL(TIPO_CLIENTE,''),
			@VESTADO = ISNULL(ESTADO,''),
			@VOBSERVACIONES = ISNULL(OBSERVACIONES,''),
			@VERROR = ISNULL(ERROR,''),
			@VCLAVE = ISNULL(CLAVE,'')
	FROM	TMT_SV_02
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VCUIT = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo CUIT</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VRAZON_SOCIAL = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Razon Social</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VLOCALIDAD = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Localidad</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
		/*
		IF (@VPROVINCIA = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Provincia</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
		*/
		IF (@VTIPO_CLIENTE = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Tipo Cliente</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
		/*
		IF (@VESTADO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Estado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END*/
 
		--VALIDO QUE NO EXISTA EL MISMO CLIENTE EN LK_CLIENTES--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_CLIENTES
		WHERE	CUIT_CLIENTE = LTRIM(RTRIM(@VCUIT))
		AND		ID_CLIENTE <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Cliente para el CUIT ingresado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_02
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			--VALIDO QUE NO EXISTA LA MISMA RAZON SOCIAL EN LK_CLIENTES--
			SELECT	@VCANT = COUNT(1)
			FROM	LK_CLIENTES
			WHERE	RAZON_SOCIAL_CLIENTE = LTRIM(RTRIM(@VRAZON_SOCIAL))
			AND		ID_CLIENTE <> @VCLAVE
 
			IF (@VCANT > 0) BEGIN
		
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Cliente con la misma Razon Social ingresada</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
				UPDATE	TMT_SV_02
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
		
			END ELSE BEGIN
 
				UPDATE	LK_CLIENTES
				SET		RAZON_SOCIAL_CLIENTE = @VRAZON_SOCIAL, 
						CUIT_CLIENTE = @VCUIT, 
						CALLE_CLIENTE = @VCALLE, 
						NRO_CALLE_CLIENTE = @VNRO, 
						PISO_DEPTO_CLIENTE = @VPISO,
						LOCALIDAD_CLIENTE = @VLOCALIDAD, 
						PROVINCIA_CLIENTE = @VPROVINCIA, 
						TEL1_CLIENTE = @VTELEFONO1, 
						TEL2_CLIENTE = @VTELEFONO2, 
						EMAIL_CLIENTE = @VEMAIL, 
						IVA_CLIENTE = @VIVA,
						CONTACTO_CLIENTE = @VCONTACTO, 
						TIPO_CLIENTE = @VTIPO_CLIENTE, 
						STATUS_CLIENTE = @VESTADO, 
						OBSERV_CLIENTE = @VOBSERVACIONES,
						FECHA_UPD = GETDATE(), 
						USUARIO_UPD = @IAGENTE
				WHERE	ID_CLIENTE = @VCLAVE
			END
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_02
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
END
 
