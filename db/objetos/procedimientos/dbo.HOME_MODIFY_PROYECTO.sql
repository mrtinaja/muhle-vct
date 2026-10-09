CREATE PROCEDURE [dbo].[HOME_MODIFY_PROYECTO]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VCLIENTE		VARCHAR(100),
		@VNOMBRE		VARCHAR(300),
		@VNRO_COTIZA	VARCHAR(50),
		@VFECHA			DATETIME,
		@VFECHA_FIN		DATETIME,
		@VHORAS			VARCHAR(50),
		@VMONTO			VARCHAR(50),
		@VAUDITORIA		VARCHAR(50),
		@VCAPACITACION	VARCHAR(50),
		@VCONSULTORIA	VARCHAR(50),
		@VID_PROYECTO	INT,
		@VERROR			VARCHAR(50),
		@VCODIGO		VARCHAR(100),
		@VOBSERVACIONES	VARCHAR(4000),
		@VNORMAS		VARCHAR(400),
		@VCANT			INT,
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VTORF			VARCHAR(50),
		@VEXISTE		VARCHAR(50),
		@VPREVIAS		VARCHAR(400),
		@VNUEVAS		VARCHAR(400),
		@VESTADO		VARCHAR(50),
		@VNIVEL_RIESGO	VARCHAR(50),
		@VCONTACTO		VARCHAR(400),
		@vestado_act	varchar(50)
 
BEGIN	
	
	SELECT	@VID_PROYECTO = PROYECTO_ID,
			@VCLIENTE = CLIENTE,
			@VNOMBRE = NOMBRE_PROY,
			@VNRO_COTIZA = NRO_COTIZA,
			@VFECHA = FECHA_INICIO_PROY,
			@VFECHA_FIN = FECHA_FIN_PROY,
			@VHORAS = HORAS_PROY,
			@VMONTO = REPLACE(ISNULL(MONTO_PROY,'0'),'.',''),
			@VCODIGO = CODIGO_PROY,
			@VOBSERVACIONES = OBSERV_PROY,
			@VNORMAS = BUFFER,
			@VESTADO = ESTADO_PROY,
			@VCONTACTO = ISNULL(CONTACTO_PROY,''),
			@VNIVEL_RIESGO = ISNULL(NIVEL_RIESGO,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPREVIAS = NORMAS
	FROM	LK_PROYECTO
	WHERE	ID_PROYECTO = @VID_PROYECTO
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VNOMBRE = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Nombre</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VFECHA = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Inicio</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VFECHA_FIN = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Fin</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF @VFECHA > @VFECHA_FIN BEGIN
			
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>La Fecha Fin debe ser Mayor a la Fecha Inicio</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (ISNUMERIC(@VHORAS) = '0') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>El Campo Horas Proyectadas debe ser numerico</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (ISNUMERIC(@VMONTO) = '0') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>El Campo Monto Presepuestado debe ser numerico</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF CHARINDEX(@VMONTO,',') > 0  BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>El Campo Monto Presupuestado no puede tener decimales</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
		/*IF (@VESTADO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe Completar el Campo Estado</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END*/		
 
		IF (@VPREVIAS = '' AND @VNORMAS = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe Selecionar al menos una Norma para Modificar el Proyecto</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		
		END ELSE BEGIN
 
			SET @VNUEVAS = @VPREVIAS
 
			WHILE LEN(@VNORMAS) > 0
				BEGIN 
					SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
					IF (@lnuPosComa = 0) BEGIN 
						SET @lstDato = @VNORMAS
						SET @VNORMAS = '' 
					END ELSE BEGIN
						SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
						SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
						SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
						IF (@VTORF = 'FALSE') BEGIN
							SET @VEXISTE = [dbo].[FN_GET_NORMA](@VPREVIAS,@VALOR) 
							
							IF @VEXISTE = 'SI' BEGIN
								SET @VNUEVAS = REPLACE('|'+ @VNUEVAS,'|'+@VALOR+'|','|')
								IF (SUBSTRING(@VNUEVAS,1,1) = '|') BEGIN
									SET @VNUEVAS = SUBSTRING(@VNUEVAS,2,LEN(@VNUEVAS))
								END
							END
 
						END ELSE BEGIN
 
							SET @VEXISTE = [dbo].[FN_GET_NORMA](@VPREVIAS,@VALOR) 
							
							IF @VEXISTE <> 'SI' BEGIN
								SET @VNUEVAS = ISNULL(@VNUEVAS,'') + @VALOR + '|'
							END
						END
 
						SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
					END
				END
 
				IF (@VNUEVAS = '') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
										<body>
										  <div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe Selecionar al menos una Norma para Modificar el Proyecto</b></font>
										  </div>
										</div>
										</body>
										</html>'
									
					UPDATE	XAGENDA
					SET		ERROR = 'SI'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
		END
 
		/*
		--VALIDO QUE NO EXISTA EL MISMO CODIGO EN LK_DOCUMENTACION--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_PROYECTO
		WHERE	CONVERT(VARCHAR,ID_CLIENTE) = @VCLIENTE
		AND		NORMA_REF = LTRIM(RTRIM(@VNOMBRE))
		AND		ID_PROYECTO <> @VID_PROYECTO
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Proyecto con el mismo Nombre para ese Cliente</b></font>
								  </div>
								</div>
								</body>
								</html>'
									
			UPDATE	XAGENDA
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END ELSE BEGIN*/
 
			UPDATE	LK_PROYECTO
			SET		ID_COTIZACION	= @VNRO_COTIZA, 
					NORMA_REF		= @VNOMBRE, 
					FECHA_INICIO_TOTAL = @VFECHA,
					FECHA_INICIO_REAL = @VFECHA,
					FECHA_FIN_TOTAL = @VFECHA_FIN,
					FECHA_FIN_REAL = @VFECHA_FIN,
					TOTAL_HORAS_PROYECTADAS = @VHORAS, 
					MONTO_PRESUP = CAST(@VMONTO AS int),
					CODIGO = @VCODIGO, 
					OBSERVACIONES = @VOBSERVACIONES, 
					NORMAS = @VNUEVAS,
					ESTADO_PROYECTO_TOTAL = CASE WHEN ESTADO_PROYECTO_TOTAL NOT IN ('TERMINADO','ENCURSO') THEN @VESTADO ELSE ESTADO_PROYECTO_TOTAL END,
					CONTACTO = @VCONTACTO,
					NIVEL_RIESGO = @VNIVEL_RIESGO
			WHERE	ID_PROYECTO = @VID_PROYECTO
	
		--END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	XAGENDA
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
