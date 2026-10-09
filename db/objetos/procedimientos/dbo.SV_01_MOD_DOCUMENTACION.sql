CREATE   PROCEDURE [dbo].[SV_01_MOD_DOCUMENTACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VCLAVE		VARCHAR(100),
		@VDOC_CODE	VARCHAR(50),
		@VDOC_DESC	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VCOMENT	VARCHAR(400),
		@VDETALLE	VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VCANT		INT
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VCLAVE = ISNULL(CLAVE_DOC,''),
			@VDOC_CODE = ISNULL(CODIGO_DOC,''),
			@VDOC_DESC	= ISNULL(DESCRIPCION_DOC,''),
			@VESTADO = ISNULL(ESTADO_DOC,''),
			@VCOMENT = ISNULL(COMENTARIO_DOC,''),
			@VDETALLE = DETALLE_DOC,
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VDOC_CODE = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Procedimiento</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
	
		IF (@VDOC_DESC = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Descripción</b></font>
							  </div>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VESTADO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Estado</b></font>
							  </div>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VDETALLE = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Detalle</b></font>
							  </div>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDO QUE NO EXISTA LA MISMA codigo EN LK_DOCUMENTACION--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_DOCUMENTACION
		WHERE	CODE_DOCUMENTACION = LTRIM(RTRIM(@VDOC_CODE))
		AND		ID_DOCUMENTACION <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe una Documentacion con el mismo Procedimiento</b></font>
							  </div>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END
 
		--VALIDO QUE NO EXISTA LA MISMA DESCRIPCION EN LK_DOCUMENTACION--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_DOCUMENTACION
		WHERE	DESC_DOCUMENTACION = LTRIM(RTRIM(@VDOC_DESC))
		AND		ID_DOCUMENTACION <> @VCLAVE
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe una Documentacion con la misma Descripción</b></font>
								</div>'
									
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN
 
			UPDATE LK_DOCUMENTACION
			SET CODE_DOCUMENTACION = @VDOC_CODE,
				DESC_DOCUMENTACION = @VDOC_DESC, 
				STATUS_DOCUMENTACION = @VESTADO,
				COMENT_DOCUMENTACION = @VCOMENT,
				DETALLE_DOCUMENTACION = @VDETALLE, 
				FECHA_UPD = GETDATE(), 
				USUARIO_UPD = @IAGENTE
			WHERE ID_DOCUMENTACION = @VCLAVE
 
		END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_01
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
