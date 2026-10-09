CREATE   PROCEDURE [dbo].[SV_01_ADD_DOCUMENTACION_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VDET_DESC	VARCHAR(400),
		@VCOMENT	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VDET_GRUPO	VARCHAR(50),
		@VCLAVE_DOC	VARCHAR(100),
		@VERROR		VARCHAR(50),
		@VORDEN		VARCHAR(50),
		@VOBLIGATORIO VARCHAR(50),
		@VDATO		VARCHAR(50),
		@VCAMPO		VARCHAR(50),
		@VEXPORTA	VARCHAR(50),
		@CLAVE_DET	VARCHAR(50),
		@VCANT		INT,
		@VCODIGO_DOC VARCHAR(100)
 
BEGIN	
	
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VDET_DESC	= ISNULL(DESCRIPCION_DET,''),
			@VCOMENT = ISNULL(COMENTARIO_DET,''),
			@VESTADO = ISNULL(ESTADO_DET,''),
			@VDET_GRUPO = ISNULL(GRUPO_DET,''),
			@VCLAVE_DOC = ISNULL(CLAVE_DOC,''),
			@CLAVE_DET = ISNULL(CLAVE_DETALLE,''),
			@VORDEN = ISNULL(CONVERT(VARCHAR,ORDEN),'0'),
			@VOBLIGATORIO = ISNULL(OBLIGATORIO,''),
			@VDATO = ISNULL(DATO,''),
			@VCAMPO = ISNULL(CAMPO,''),
			@VEXPORTA = ISNULL(EXPORTA,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCODIGO_DOC = CODE_DOCUMENTACION
	FROM	LK_DOCUMENTACION
	WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
 
	--IF @VERROR IN ('','NO') BEGIN
	--	SET @OCODE = '0'
	--	SET @OMENSAJE = ''
 
	--END ELSE BEGIN
 
		IF (@VDET_DESC = '') BEGIN
			SET @OCODE = '1'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI',
					DESC_ERROR = '<div class="w3-panel w3-pale-red" style="height:20px;">
										<span class="w3-muhle-text-12"><b>Debe completar el Campo Descripción</b></span>
								  </div>'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VESTADO = '') BEGIN
			SET @OCODE = '1'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI',
					DESC_ERROR ='<div class="w3-panel w3-pale-red" style="height: 20px;">
									<span class="w3-muhle-text-12"><b>Debe completar el Campo Estado</b></span>
							  </div>'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDACIONES PARA MINUTA DE GESTION--
		IF (@VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex')) BEGIN
 
			IF (@VOBLIGATORIO = '') BEGIN
				SET @OCODE = '1'
			
				UPDATE	TMT_SV_01
				SET		ERROR = 'SI',
						DESC_ERROR = '<div class="w3-panel w3-pale-red" style="height: 20px;">
										<span class="w3-muhle-text-12"><b>Debe completar el Campo Obligatorio</b></span>
								  </div>'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			IF (@VEXPORTA = '') BEGIN
				SET @OCODE = '1'
			
				UPDATE	TMT_SV_01
				SET		ERROR = 'SI',
						DESC_ERROR = '<div class="w3-panel w3-pale-red" style="height: 20px;">
										<span class="w3-muhle-text-12"><b>Debe completar el Campo Exporta</b></span>
								  </div>'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
		END
 
		IF (@VDET_GRUPO = '') BEGIN
			SET @OCODE = '1'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI',
					DESC_ERROR = '<div class="w3-panel w3-pale-red" style="height: 20px;">
									<span class="w3-muhle-text-12"><b>Debe completar el Campo Grupo/Tipo</b></span>
							  </div>'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VORDEN = '' OR @VORDEN = '0') BEGIN
			SET @OCODE = '1'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI',
					DESC_ERROR ='<div class="w3-panel w3-pale-red" style="height: 20px;">
									<span class="w3-muhle-text-12"><b>Debe completar el Campo Orden</b></span>
							  </div>'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		--VALIDACIONES PARA MINUTA DE GESTION--
		IF (@VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex')) BEGIN
 
			IF (@VDATO <> '') BEGIN
				IF (@VCAMPO = '') BEGIN
					SET @OCODE = '1'
			
					UPDATE	TMT_SV_01
					SET		ERROR = 'SI',
							DESC_ERROR = '<div class="w3-panel w3-pale-red" style="height: 20px;">
											<span class="w3-muhle-text-12"><b>Debe completar el Campo si Selecciona Asociar Dato</b></span>
									  </div>'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
			END
		END
 
		--VALIDO QUE NO EXISTA LA MISMA DESCRIPCION EN LK_DOCUMENTACION_DET POR ID_DOCUMENTACION Y GRUPO--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_DOCUMENTACION_DET
		WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
		AND		GRUPO_DOC_DET = @VDET_GRUPO
		AND		DESC_DOC_DET = LTRIM(RTRIM(@VDET_DESC))
		AND		ID_DOCUMENTACION_DET <> @CLAVE_DET
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			
			UPDATE	TMT_SV_01
			SET		ERROR = 'SI',
					DESC_ERROR ='<div class="w3-panel w3-pale-red" style="height: 20px;">
									<span class="w3-muhle-text-12"><b>Ya Existe un Detalle con la misma Descripcion para el mismo Grupo/Tipo</b></span>
							  </div>'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END 
 
		IF @CLAVE_DET = '' BEGIN
 
			INSERT INTO LK_DOCUMENTACION_DET
			(ID_DOCUMENTACION, DESC_DOC_DET, GRUPO_DOC_DET, COMENT_DOC_DET, STATUS_DOC_DET,
			 FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD, ORDEN, OBLIGATORIO_DET, DATO_DET, CAMPO_DET, EXPORTA_DET)
			VALUES
			(@VCLAVE_DOC, @VDET_DESC, @VDET_GRUPO, @VCOMENT, @VESTADO, 
			 GETDATE(), @IAGENTE, GETDATE(), @IAGENTE, CONVERT(NUMERIC,@VORDEN), @VOBLIGATORIO, @VDATO, @VCAMPO, @VEXPORTA)
 
 
			 --SET @OCODE = '0'
		END
		ELSE BEGIN
			UPDATE LK_DOCUMENTACION_DET
			SET DESC_DOC_DET = @VDET_DESC,
				GRUPO_DOC_DET = @VDET_GRUPO, 
				STATUS_DOC_DET = @VESTADO,
				COMENT_DOC_DET = @VCOMENT,
				FECHA_UPD = GETDATE(), 
				USUARIO_UPD = @IAGENTE,
				ORDEN = CONVERT(NUMERIC,@VORDEN),
				OBLIGATORIO_DET = @VOBLIGATORIO,
				DATO_DET = @VDATO,
				CAMPO_DET = @VCAMPO,
				EXPORTA_DET = @VEXPORTA
			WHERE ID_DOCUMENTACION_DET = @CLAVE_DET
		END
 
		 --SET @OCODE = '0'
 
	--END
 
	--IF (@OCODE = '0') BEGIN
	--	UPDATE	TMT_SV_01
	--	SET		ERROR = 'NO',
	--			DESCRIPCION_DET = NULL,
	--			ESTADO_DET = NULL,
	--			COMENTARIO_DET = NULL,
	--			GRUPO_DET = NULL,
	--			ORDEN = NULL
	--	WHERE	PAR_KEY = @IPKEYJOB
	--END
END
 
