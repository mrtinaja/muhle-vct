CREATE   PROCEDURE [dbo].[SV_01_MOD_DOCUMENTACION_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VCLAVE		VARCHAR(100),
		@VCLAVE_DOC	VARCHAR(100),
		@VDET_DESC	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VCOMENT	VARCHAR(400),
		@VGRUPO		VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VORDEN		NUMERIC(5,0),
		@VCANT		INT
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VCLAVE = ISNULL(CLAVE_DETALLE,''),
			@VCLAVE_DOC = ISNULL(CLAVE_DOC,''),
			@VDET_DESC	= ISNULL(DESCRIPCION_DET,''),
			@VESTADO = ISNULL(ESTADO_DET,''),
			@VCOMENT = ISNULL(COMENTARIO_DET,''),
			@VGRUPO = GRUPO_DET,
			@VORDEN = ISNULL(ORDEN,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
		IF (@VDET_DESC = '') BEGIN
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
 
		IF (@VGRUPO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Grupo</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA LA MISMA DESCRIPCION EN LK_DOCUMENTACION_DET POR ID_DOCUMENTACION Y GRUPO--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_DOCUMENTACION_DET
		WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
		AND		GRUPO_DOC_DET = @VGRUPO
		AND		DESC_DOC_DET = LTRIM(RTRIM(@VDET_DESC))
		AND		ID_DOCUMENTACION_DET <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Detalle con la misma Descripcion para el mismo Grupo</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			UPDATE LK_DOCUMENTACION_DET
			SET DESC_DOC_DET = @VDET_DESC,
				GRUPO_DOC_DET = @VGRUPO, 
				STATUS_DOC_DET = @VESTADO,
				COMENT_DOC_DET = @VCOMENT,
				FECHA_UPD = GETDATE(), 
				USUARIO_UPD = @IAGENTE,
				ORDEN = ISNULL(@VORDEN,NULL)
			WHERE ID_DOCUMENTACION_DET = @VCLAVE
 
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_01
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
END
