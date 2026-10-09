CREATE PROCEDURE [dbo].[SV_03_MODIFY_PROVEEDOR]
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
			@VTIPO_PROV = ISNULL(TIPO_PROVEEDOR,''),
			@VESTADO = ISNULL(ESTADO,''),
			@VOBSERVACIONES = ISNULL(OBSERVACIONES,''),
			@VERROR = ISNULL(ERROR,''),
			@VCLAVE = ISNULL(CLAVE,'')
	FROM	TMT_SV_03
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
									
			UPDATE	TMT_SV_03
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
									
			UPDATE	TMT_SV_03
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
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
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
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VTIPO_PROV = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Tipo Proveedor</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
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
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA EL MISMO CLIENTE EN LK_PROVEEDORES--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_PROVEEDORES
		WHERE	CUIT_PROV = LTRIM(RTRIM(@VCUIT))
		AND		ID_PROVEEDOR <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Proveedor para el CUIT ingresado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_03
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			--VALIDO QUE NO EXISTA LA MISMA RAZON SOCIAL EN LK_PROVEEDORES--
			SELECT	@VCANT = COUNT(1)
			FROM	LK_PROVEEDORES
			WHERE	RAZON_SOCIAL_PROV = LTRIM(RTRIM(@VRAZON_SOCIAL))
			AND		ID_PROVEEDOR <> @VCLAVE
 
			IF (@VCANT > 0) BEGIN
		
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Proveedor con la misma Razon Social ingresada</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
				UPDATE	TMT_SV_03
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
		
			END ELSE BEGIN
 
				UPDATE	LK_PROVEEDORES
				SET		RAZON_SOCIAL_PROV = @VRAZON_SOCIAL, 
						CUIT_PROV = @VCUIT, 
						CALLE_PROV = @VCALLE, 
						NRO_CALLE_PROV = @VNRO, 
						PISO_DEPTO_PROV = @VPISO,
						LOCALIDAD_PROV = @VLOCALIDAD, 
						PROVINCIA_PROV = @VPROVINCIA, 
						TEL1_PROV = @VTELEFONO1, 
						TEL2_PROV = @VTELEFONO2, 
						EMAIL_PROV = @VEMAIL, 
						IVA_PROV = @VIVA,
						TIPO_PROV = @VTIPO_PROV, 
						STATUS_PROV = @VESTADO, 
						OBSERV_PROV = @VOBSERVACIONES,
						FECHA_UPD = GETDATE(), 
						USUARIO_UPD = @IAGENTE
				WHERE	ID_PROVEEDOR = @VCLAVE
 
			END
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_03
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
 
