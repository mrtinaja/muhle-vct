CREATE   PROCEDURE [dbo].[SV_01_MOD_TIPO_SERVICIOS]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VCLAVE		VARCHAR(100),
		@VTIPO_DESC	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VCANT		INT
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VCLAVE = ISNULL(CLAVE,''),
			@VTIPO_DESC	= ISNULL(DESCRIPCION_TS,''),
			@VESTADO = ISNULL(ESTADO_TS,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VTIPO_DESC = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Descripción</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_01
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
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA LA MISMA DESCRIPCION EN LK_TIPO_SERVICIOS--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_TIPO_SERVICIOS
		WHERE	DESC_TIPO_SERVICIO = LTRIM(RTRIM(@VTIPO_DESC))
		AND		ID_TIPO_SERVICIO <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Tipo de Servicio con la misma Descripción</b></font>
							  </div>
							</div>
							</body>
							</html>'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			UPDATE LK_TIPO_SERVICIOS
			SET DESC_TIPO_SERVICIO = @VTIPO_DESC, 
				STATUS_TIPO_SERVICIO = @VESTADO, 
				FECHA_UPD = GETDATE(), 
				USUARIO_UPD = @IAGENTE
			WHERE ID_TIPO_SERVICIO = @VCLAVE
			
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_01
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
 
