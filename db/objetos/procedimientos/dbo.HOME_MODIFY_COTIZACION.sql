CREATE PROCEDURE [dbo].[HOME_MODIFY_COTIZACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VNRO		VARCHAR(50),
		@VCLIENTE	VARCHAR(100),
		@VFECHA		DATETIME,
		@VESTADO	VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VCANT		INT,
		@VADJUNTO	VARCHAR(100),
		@VADJUNTO_ANT	VARCHAR(100),
		@VCLAVE		VARCHAR(50)
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VCLAVE = CLAVE_COTIZA,
			@VNRO = ISNULL(NRO_COTIZA,''),
			--@VCLIENTE	= ISNULL(CLIENTE,''),
			@VFECHA = ISNULL(FECHA_COTIZA,''),
			@VESTADO = ISNULL(ESTADO_COTIZA,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCLIENTE	= ISNULL(ID_CLIENTE,''),
			@VADJUNTO_ANT = ISNULL(ID_ADJUNTO,'')
	FROM	LK_COTIZACIONES
	WHERE	ID_COTIZACION = @VCLAVE
 
	SELECT	@VADJUNTO = ISNULL(PKEY,'')
	FROM	PHYSICAL_ATTACHED_DOCUMENT
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VNRO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Nro Cotizacion</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		/*END ELSE BEGIN
 
			IF (ISNUMERIC(@VNRO) = '0') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>El Campo Nro Cotizacion debe ser numerico</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END*/
		END
 
		IF (@VFECHA = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	XAGENDA
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
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA EL MISMO CODIGO EN LK_DOCUMENTACION--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_COTIZACIONES
		WHERE	CONVERT(VARCHAR,NRO_COTIZACION) = LTRIM(RTRIM(@VNRO))
		AND		CONVERT(VARCHAR,ID_CLIENTE) = @VCLIENTE
		AND		CONVERT(VARCHAR,ID_COTIZACION) <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe una Cotizacion con el mismo Nro para ese Cliente</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			UPDATE LK_COTIZACIONES
			SET NRO_COTIZACION = @VNRO, 
				FECHA_COTIZACION = @VFECHA, 
				ESTADO_COTIZACION = @VESTADO, 
				ID_ADJUNTO = ISNULL(@VADJUNTO,@VADJUNTO_ANT)
			WHERE	ID_COTIZACION = @VCLAVE
 
			IF (@VADJUNTO <> '') BEGIN
				UPDATE	PHYSICAL_ATTACHED_DOCUMENT
				SET		PAR_KEY = @VCLIENTE
				WHERE	PKEY = @VADJUNTO
 
				DELETE	PHYSICAL_ATTACHED_DOCUMENT
				WHERE	PKEY = @VADJUNTO_ANT
			END
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	XAGENDA
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
 
