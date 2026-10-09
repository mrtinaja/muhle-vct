CREATE PROCEDURE [dbo].[HOME_ADD_FEC_AGENDA]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VPROYECTO		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VCLIENTE		VARCHAR(50),	
		@VFECHA			VARCHAR(50),
		@VFECHAD		VARCHAR(50),
		@VFECHAH		VARCHAR(50),
		@VCONSULTORES	VARCHAR(400),
		@VCONSULTORES2	VARCHAR(400),
		@VESTADO		VARCHAR(50),
		@VNORMA			VARCHAR(400),
		@VOBSERVADOR	VARCHAR(100),
		@VERROR			VARCHAR(50),
		@VREG			INT,
		@VDIF			INT,
		@VCANT			INT,
		@VLOG			INT,
		@VID_AGENDA		INT,
		@VID_DOC			VARCHAR(50),
		@VID_PROYECTO_DOCUM	VARCHAR(50),
		@VDESC_DOC_DET		VARCHAR(400), 
		@VGRUPO_DOC_DET		VARCHAR(50),
		@VALIDA_AGENDA		VARCHAR(50),
		@VTIPOSERVICIO	VARCHAR(50),
		@VDIAS			INT,
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VTORF			VARCHAR(50),
		@VDESCCONS		VARCHAR(400),
		@VEXISTE		int,
		@VTOTAL_EJEC	INT,
		@VTOTAL_SERV	INT,
		@VALERT_CALIF	VARCHAR(50),
		@VOBS_CALIF		VARCHAR(400),
		@VOBS_LOGIS		VARCHAR(400),
		@VHORAS			INT,
		@VHORAS_TOTALES	INT,
		@VSELECCION		VARCHAR(4000),
		@VPREVIAS			VARCHAR(400),
		@VNUEVAS			VARCHAR(400),
		@RESULTADO			VARCHAR(400),
		@RESULTADO2			VARCHAR(400),
		@VALOR2				VARCHAR(400),
		@VALORNORMA			VARCHAR(400),
		@VAGREGO			VARCHAR(50),
		@VSELECCION2		VARCHAR(4000),
		@VESTA				VARCHAR(50),
		@VLIDER				VARCHAR(400),
		@VLIDERES			VARCHAR(400),
		@VNORMAS_SELEC		VARCHAR(4000),
		@VNORMAS_SELEC2		VARCHAR(4000),
		@VNORMAS_PREVIAS	VARCHAR(4000),
		@VNORMAS_NUEVAS		VARCHAR(4000),
		@VAGREGO_NORMA		VARCHAR(50),
		@VESTA_NORMA		VARCHAR(50),			
		@VNORMAS_SERV		VARCHAR(400),
		@VID			VARCHAR(100),
		@VORDEN			NUMERIC(5,0),
		@VFECHA_FIN_SERV	VARCHAR(50)
 
BEGIN	
	SET @VID_AGENDA = 0
	SET @OCODE = '0'
	SET @OMENSAJE = ''
	
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VCONSULTORES = ISNULL(AGENDA_CONSULTORES,''),
			@VFECHAD = CONVERT(VARCHAR(10), CONVERT(date, FECHA_SELEC, 105), 23),
			@VFECHAH = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_HASTA, 105), 23),''),
			@VHORAS = ISNULL(AGENDA_HORAS,0),
			@VESTADO = ISNULL(AGENDA_ESTADO,''),
			--@VNORMA = ISNULL(AGENDA_NORMA,''),
			@VOBSERVADOR = ISNULL(AGENDA_OBSERVADOR,''),
			@VERROR = ISNULL(ERROR,''),
			@VALIDA_AGENDA = ISNULL(VALIDA_AGENDA,''),
			@VALERT_CALIF = ISNULL(ALERTA_CALIF,''),
			@VOBS_CALIF = ISNULL(AGENDA_OBSERV_CALIF,''),
			@VOBS_LOGIS = ISNULL(AGENDA_OBSERV_LOGIS,''),
			@VSELECCION = ISNULL(ACUMULA,''),
			@VPREVIAS = ISNULL(LIDER,''),
			@VNORMAS_SELEC = ISNULL(AGENDA_NORMAS,''),
			@VNORMAS_PREVIAS = ISNULL(AGENDA_NORMA,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VSERVICIO = '1' BEGIN
	
		SELECT	@VID = ID_PROYECTO_SERVICIO,
				@VTIPOSERVICIO = ID_TIPO_SERVICIO,
				@VFECHA_FIN_SERV = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA_FIN_REAL, 105), 23),'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VPROYECTO 
		AND		ID_TIPO_SERVICIO = @VSERVICIO
	
	END ELSE BEGIN
		
		SELECT	@VTIPOSERVICIO = ID_TIPO_SERVICIO,
				@VFECHA_FIN_SERV = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA_FIN_REAL, 105), 23),'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID
	END
 
	SELECT	@VCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	SET @VNUEVAS = @VPREVIAS
	SET @VSELECCION2 = [dbo].[FN_GET_SELECCION] (@VSELECCION)
	
	WHILE PATINDEX('%|%',@VNUEVAS)>0
	BEGIN
		SET @RESULTADO = PATINDEX('%|%',@VNUEVAS) --+ @N
		SET  @VALOR = SUBSTRING(@VNUEVAS,1, @RESULTADO-1)
		
		SET @VESTA = DBO.FN_GET_NORMA(@VSELECCION2,@VALOR)
 
		--aca agrego o elimino el dato en el string--
		IF (@VESTA = 'SI') BEGIN
			SET @VAGREGO = 'NO'
		END ELSE BEGIN
			SET @VAGREGO = 'SI'
		END
 
		IF (@VAGREGO = 'SI') BEGIN
			SET @VSELECCION = ISNULL(@VSELECCION,'') + @VALOR + '=true|'
		END
		
		SELECT @VNUEVAS = RIGHT(@VNUEVAS,LEN(@VNUEVAS)-PATINDEX('%|%',@VNUEVAS))
	END
 
	SET @VALOR = NULL
	SET @VLIDERES = @VSELECCION
 
	IF (@VLIDERES <> '') BEGIN
		WHILE LEN(@VLIDERES) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VLIDERES) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VLIDERES
				SET @VLIDERES = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VLIDERES, 1, @lnuPosComa - 1)
				SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
				IF (@VTORF = 'FALSE') BEGIN
					SET @VALOR = REPLACE('|'+ @VALOR,'|'+@VALOR+'|','|')
						IF (SUBSTRING(@VALOR,1,1) = '|') BEGIN
							SET @VALOR = SUBSTRING(@VALOR,2,LEN(@VALOR))
 
						END
				END ELSE BEGIN
 
					SET @VALOR = ISNULL(@VALOR,'') + SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1) + '|'
 
					SET @lstDato = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
 
				END
				
				SET @VLIDERES = SUBSTRING(@VLIDERES, @lnuPosComa + 1, LEN(@VLIDERES))
			END
		END
	END
 
	--SET @VALORNORMA = NULL
	SET @VNORMAS_NUEVAS = @VNORMAS_PREVIAS
	SET @VNORMAS_SELEC2 = [dbo].[FN_GET_SELECCION] (@VNORMAS_SELEC)
	
	WHILE PATINDEX('%|%',@VNORMAS_NUEVAS)>0
	BEGIN
		SET @RESULTADO = PATINDEX('%|%',@VNORMAS_NUEVAS) --+ @N
		SET  @VALORNORMA = SUBSTRING(@VNORMAS_NUEVAS,1, @RESULTADO-1)
		
		SET @VESTA_NORMA = DBO.FN_GET_NORMA(@VNORMAS_SELEC2,@VALORNORMA)
 
		--aca agrego o elimino el dato en el string--
		IF (@VESTA_NORMA = 'SI') BEGIN
			SET @VAGREGO_NORMA = 'NO'
		END ELSE BEGIN
			SET @VAGREGO_NORMA = 'SI'
		END
 
		IF (@VAGREGO_NORMA = 'SI') BEGIN
			SET @VNORMAS_SELEC = ISNULL(@VNORMAS_SELEC,'') + @VALORNORMA + '=true|'
		END
		
		SELECT @VNORMAS_NUEVAS = RIGHT(@VNORMAS_NUEVAS,LEN(@VNORMAS_NUEVAS)-PATINDEX('%|%',@VNORMAS_NUEVAS))
	END
 
	SET @VALORNORMA = NULL
	SET @VNORMAS_SERV = @VNORMAS_SELEC
 
	IF (@VNORMAS_SERV <> '') BEGIN
		WHILE LEN(@VNORMAS_SERV) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VNORMAS_SERV) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VNORMAS_SERV
				SET @VNORMAS_SERV = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VNORMAS_SERV, 1, @lnuPosComa - 1)
				SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
				IF (@VTORF = 'FALSE') BEGIN
					SET @VALORNORMA = REPLACE('|'+ @VALORNORMA,'|'+@VALORNORMA+'|','|')
						IF (SUBSTRING(@VALORNORMA,1,1) = '|') BEGIN
							SET @VALORNORMA = SUBSTRING(@VALORNORMA,2,LEN(@VALORNORMA))
 
						END
				END ELSE BEGIN
 
					SET @VALORNORMA = ISNULL(@VALORNORMA,'') + SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1) + '|'
 
					SET @lstDato = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
 
				END
				
				SET @VNORMAS_SERV = SUBSTRING(@VNORMAS_SERV, @lnuPosComa + 1, LEN(@VNORMAS_SERV))
			END
		END
	END
 
 
	/*WHILE PATINDEX('%|%',@VSELECCION)>0
	BEGIN
		SET @RESULTADO1 = PATINDEX('%|%',@VSELECCION) --+ @N
		SET @VSELECCION2 = SUBSTRING(@VSELECCION,1, @RESULTADO1-1)
		SET @RESULTADO2 = PATINDEX('%=%',@VSELECCION2)
		SET @VALOR1 = SUBSTRING(@VSELECCION2,1,@RESULTADO2-1)
		SET @VALOR2 = SUBSTRING(@VSELECCION2,@RESULTADO2+1, @RESULTADO1-1)
		
		--SET @Vesta = DBO.FN_GET_NORMA(@VSELECCION2,@VALOR2)
 
		--aca agrego o elimino el dato en el string--
		IF (@VALOR2 = 'false') BEGIN
			SET @VAGREGO = 'NO'
			SET @VESTA = DBO.FN_GET_NORMA(@VPREVIAS,CONVERT(NUMERIC,@VALOR1))
 
			IF (@VESTA = 'SI') BEGIN
				
			END
 
		END ELSE BEGIN
			SET @VAGREGO = 'SI'
		END
 
		IF (@VAGREGO = 'SI') BEGIN
			SET @VNUEVAS = ISNULL(@VNUEVAS,'') + CONVERT(VARCHAR,@VALOR1) + '|'
		END
 
		SELECT @VSELECCION = RIGHT(@VSELECCION,LEN(@VSELECCION)-PATINDEX('%|%',@VSELECCION))
	END*/
 
	UPDATE	XAGENDA
	SET		LIDER = @VALOR,--@VNUEVAS
			AGENDA_NORMA = @VALORNORMA
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF (@VALIDA_AGENDA <> '1') BEGIN
 
		IF (@VALIDA_AGENDA = 'SI') BEGIN
 
			IF @VERROR = '' BEGIN
				SET @OCODE = '0'
				SET @OMENSAJE = ''
 
			END ELSE BEGIN
 
				IF (@VFECHAD = '') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
										<body>
										  <div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Seleccionar una Fecha Desde</b></font>
										  </div>
										</div>
										</body>
										</html>'
									
					UPDATE	XAGENDA
					SET		ERROR = 'SI'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
		
				IF (@VFECHAH = '') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
									<body>
										<div class="w3-panel w3-pale-red" style="height: 20px;">
											<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Seleccionar una Fecha Hasta</b></font>
										</div>
									</div>
									</body>
									</html>'
									
					UPDATE	XAGENDA
					SET		ERROR = 'SI'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
 
				END ELSE BEGIN
 
					IF (@VFECHAH < @VFECHAD ) BEGIN
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
											  <div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha Hasta debe ser Mayor o Igual a la Fecha Desde</b></font>
											  </div>
											</div>
											</body>
											</html>'
									
							UPDATE	XAGENDA
							SET		ERROR = 'SI'
							WHERE	PAR_KEY = @IPKEYJOB
							RETURN
					END
					
					IF (@VFECHAH > @VFECHA_FIN_SERV) BEGIN
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
											  <div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha Hasta NO debe ser Mayor a la Fecha Fin del Servicio ('+CONVERT(varchar, DATEPART(DD, @VFECHA_FIN_SERV))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA_FIN_SERV))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA_FIN_SERV))+')</b></font>
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
 
				IF (@VALERT_CALIF = 'SI') BEGIN
					
					IF (@VOBS_CALIF = '') BEGIN
						SET @OCODE = '1'
						SET @OMENSAJE = '<html>
										<body>
											<div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Completar el Campo Obs. Calificacion</b></font>
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
 
				--si no elige consultor-- no se validan las fechas--
				IF (@VCONSULTORES = '') BEGIN
					
					SET @VREG = 0
					SET @VDIF = DATEDIFF(DD,@VFECHAD,@VFECHAH)
					SET @VFECHA = @VFECHAD
 
					--IF (@VDIF > 0) BEGIN
						
					--	SET @OCODE = '1'
					--	SET @OMENSAJE = '<html>
					--					<body>
					--						<div class="w3-panel w3-pale-red" style="height: 20px;">
					--							<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha Hasta debe ser Igual a la Fecha Desde si NO selecciona Consultor</b></font>
					--						</div>
					--					</div>
					--					</body>
					--					</html>'
									
					--	UPDATE	XAGENDA
					--	SET		ERROR = 'SI'
					--	WHERE	PAR_KEY = @IPKEYJOB
					--	RETURN
 
					--END ELSE BEGIN
 
						--valido que la fecha seleccionada sea mayor a la fecha actual
						--valido que la fecha seleccionada este disponible para el cliente/proyecto/servicio
						--NO valido que la fecha seleccionada este disponible por consultor porque NO se selecciona Consultor
						IF (CONVERT(VARCHAR(10), CONVERT(date, convert(varchar,DATEPART(DD,@VFECHA))+'-'+convert(varchar,DATEPART(MM,@VFECHA))+'-'+convert(varchar,DATEPART(YYYY,@VFECHA)), 105), 23)
							< CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23)) BEGIN
 
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
												<div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha Desde debe ser Mayor o Igual a la Fecha Actual</b></font>
												</div>
											</div>
											</body>
											</html>'
									
							UPDATE	XAGENDA
							SET		ERROR = 'SI'
							WHERE	PAR_KEY = @IPKEYJOB
							RETURN
 
						END
 
						SELECT	@VEXISTE = COUNT(1) 
						FROM	LK_AGENDA 
						WHERE	ID_CLIENTE = @VCLIENTE 
						AND		ID_PROYECTO = @VPROYECTO 
						AND		ID_SERVICIO = @VTIPOSERVICIO
						AND		PROYECTO_SERV_ID = @VID
						AND		FECHA = @VFECHA
 
						IF (@VEXISTE > 0) BEGIN
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
												<div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha '+CONVERT(varchar, DATEPART(DD, @VFECHA))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA))+' NO se encuentra Disponible para el Cliente Proyecto Servicio</b></font>
												</div>
											</div>
											</body>
											</html>'
									
							UPDATE	XAGENDA
							SET		ERROR = 'SI'
							WHERE	PAR_KEY = @IPKEYJOB
							RETURN
 
						END ELSE BEGIN
 
					--WHILE @VREG <= @VDIF 
				
					--BEGIN
						--IF (@VID_AGENDA = 0) BEGIN
							INSERT INTO LK_AGENDA
							(FECHA,ID_CLIENTE,ID_PROYECTO,ID_SERVICIO,ID_CONSULTOR,
								DIA,MES,ANO,
								ESTADO,NORMA,FECHA_ALTA,USUARIO_ALTA,OBSERVADOR,FECHA_HASTA,DIAS, PROYECTO_SERV_ID)
							VALUES
							(@VFECHA, @VCLIENTE, @VPROYECTO, @VTIPOSERVICIO, @VCONSULTORES,
								CONVERT(varchar, DATEPART(DD, @VFECHA)),CONVERT(varchar, DATEPART(MM, @VFECHA)),CONVERT(varchar, DATEPART(YYYY, @VFECHA)),
								@VESTADO, @VALORNORMA, GETDATE(), @IAGENTE, @VOBSERVADOR, @VFECHAH, DATEDIFF(DD,@VFECHAD,@VFECHAH) +1, @VID)
 
								SELECT	@VID_AGENDA = IDENT_CURRENT ('LK_AGENDA')
 
								/* no grabo LK_AGENDA_EMPLEADO porque NO tengo CONSULTOR
								--ACTUALIZO EL REGISTRO DEL CONSULTOR DE LA TABLA LK_AGENDA_EMPLEADO
								UPDATE LK_AGENDA_EMPLEADO
								SET	TIPO = 'A',
									--GRABO EN ORDER-- IDAGENDA|ESTADO|IDCLIENTE|IDPROYECTO|ISERVICIO, 
									HOLIDAYTEXT = convert(varchar,@VID_AGENDA)--+'|'+CASE WHEN (ISNULL(@VESTADO,'')='') THEN 'S' ELSE @VESTADO END+'|'+@VCLIENTE+'|'+@VPROYECTO+'|'+@VTIPOSERVICIO
								WHERE	FECHA = @VFECHA
								--AND	ID_EMPLEADO = @VCONSULTORES*/
 
							/* Grabo el ID de Documentacion que corresponda segun el Servicio
								5	RE-PP-038	Hoja de Ruta Auditoria
								6	RE-PP-039	Hoja de Ruta Capacitacion
								7	RE-PP-040	Hoja de Ruta Consultoria
 
								1	Consultoria --> GRABO ID 7
								2	Auditoria --> GRABO ID 5
								3	Capacitacion --> GRABO ID 6
							*/
							SELECT	@VID_DOC =	CASE WHEN @VTIPOSERVICIO = '1' THEN '7'
														WHEN @VTIPOSERVICIO = '2' THEN '5'
														WHEN @VTIPOSERVICIO = '3' THEN '6'
												END 
 
							INSERT INTO LK_PROYECTO_DOCUM
							(ID_PROYECTO, ID_TIPO_SERVICIO, ID_DOCUMENTACION, 
								FECHA_DOCUM, NRO_DOCUM_INTERNO,
								PARTICIPANTES_DOCUM, TEMAS_DOCUM, ADJUNTO_DOCUM,
								CONSULTOR, VISITA_MES, CONSULTOR_ACOMP, OBSERVACIONES,FECHA_CIERRE,
								ID_AGENDA)
							VALUES
							(@VPROYECTO, @VTIPOSERVICIO, @VID_DOC, 
								GETDATE(), 'Hoja de Ruta '+ CASE WHEN @VTIPOSERVICIO = '1' THEN 'Consultoria' WHEN @VTIPOSERVICIO = '2' THEN 'Auditoria' WHEN @VTIPOSERVICIO = '3' THEN 'Capacitacion' END + ' - ' + CONVERT(varchar, DATEPART(DD, @VFECHA))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA)), 
								NULL, NULL, NULL,
								@VCONSULTORES, NULL, NULL, NULL, NULL,
								@VID_AGENDA)
 
							SELECT	@VID_PROYECTO_DOCUM = IDENT_CURRENT ('LK_PROYECTO_DOCUM')
 
								--RECUPERO TODOS LOS ITEMS QUE CORRESPONDEN AL DETALLE DE LA HOJA DE RUTA QUE CORRESPONDA SEGUN SERVICIO--
							DECLARE Items CURSOR FOR 
								SELECT	DESC_DOC_DET, GRUPO_DOC_DET, ISNULL(ORDEN,99) ORDEN
								FROM	LK_DOCUMENTACION_DET
								WHERE	ID_DOCUMENTACION = @VID_DOC
								AND		STATUS_DOC_DET = '1'
								ORDER BY CASE WHEN GRUPO_DOC_DET = 'LOGISTICO' THEN 1 
											  WHEN GRUPO_DOC_DET = 'TECNICO' THEN 2
											  WHEN GRUPO_DOC_DET = 'ADMINISTRACION' THEN 3 END, ISNULL(ORDEN,99)
 
							OPEN Items  
							FETCH NEXT FROM Items INTO @VDESC_DOC_DET, @VGRUPO_DOC_DET, @VORDEN  
 
							WHILE @@FETCH_STATUS = 0  
							BEGIN  
 
								INSERT INTO LK_PROYECTO_DOCUM_DET
								(ID_PROYECTO_DOCUM, DESC_DOC_DET, VALOR_DOC_DET, GRUPO_DOC_DET, ADJUNTO_DOC_DET, ORDEN)
								VALUES
								(@VID_PROYECTO_DOCUM, @VDESC_DOC_DET, NULL, @VGRUPO_DOC_DET, NULL, @VORDEN)
 
								FETCH NEXT FROM Items INTO @VDESC_DOC_DET, @VGRUPO_DOC_DET, @VORDEN
							END 
 
							CLOSE Items  
							DEALLOCATE Items
 
							--SET @VFECHA = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,1,@VFECHA), 105), 23)
							--SET @VREG = @VREG + 1
						
						/*END ELSE BEGIN
								
							--ACTUALIZO EL REGISTRO DEL CONSULTOR DE LA TABLA LK_AGENDA_EMPLEADO
							UPDATE	LK_AGENDA_EMPLEADO
							SET		TIPO = 'A',
									--GRABO EN ORDER-- IDAGENDA|ESTADO|IDCLIENTE|IDPROYECTO|ISERVICIO, 
									HOLIDAYTEXT = convert(varchar,@VID_AGENDA)--+'|'+CASE WHEN (ISNULL(@VESTADO,'')='') THEN 'S' ELSE @VESTADO END+'|'+@VCLIENTE+'|'+@VPROYECTO+'|'+@VTIPOSERVICIO
							WHERE	FECHA = @VFECHA
							--AND	ID_EMPLEADO = @VCONSULTORES
							
							SET @VFECHA = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,1,@VFECHA), 105), 23)
							SET @VREG = @VREG + 1
						END*/
						END
					--END
 
				END ELSE BEGIN
 
					SET @VLOG = 0
					SET @VREG = 0
					SET @VDIF = DATEDIFF(DD,@VFECHAD,@VFECHAH)
					SET @VFECHA = @VFECHAD
 
					--RECUPERO CAMPO LIDER DE LA TMT
					SELECT	@VLIDER = ISNULL(LIDER,''),
							@VNORMA = ISNULL(AGENDA_NORMA,'')
					FROM	XAGENDA
					WHERE	PAR_KEY = @IPKEYJOB
 
					IF (ISNULL(@VNORMA,'') = '') BEGIN
						SET @OCODE = '1'
						SET @OMENSAJE = '<html>
										<body>
											<div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Seleccionar al menos una Norma</b></font>
											</div>
										</div>
										</body>
										</html>'
									
						UPDATE	XAGENDA
						SET		ERROR = 'SI'
						WHERE	PAR_KEY = @IPKEYJOB
						RETURN
 
					END
 
					IF (ISNULL(@VLIDER,'') = '') BEGIN
						SET @OCODE = '1'
						SET @OMENSAJE = '<html>
										<body>
											<div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Seleccionar al menos un Consultor como Lider</b></font>
											</div>
										</div>
										</body>
										</html>'
									
						UPDATE	XAGENDA
						SET		ERROR = 'SI'
						WHERE	PAR_KEY = @IPKEYJOB
						RETURN
 
					END ELSE BEGIN
 
						IF ISNULL(SUBSTRING(@VLIDER,CHARINDEX('|', @VLIDER)+1,LEN(@VLIDER)),'') <> '' BEGIN
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
												<div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>Debe Seleccionar SOLO un Consultor como Lider</b></font>
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
 
					IF (@VHORAS = 0) BEGIN
						SET @OCODE = '1'
						SET @OMENSAJE = '<html>
										<body>
											<div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>El Campo Horas debe ser Mayor a 0 (cero)</b></font>
											</div>
										</div>
										</body>
										</html>'
									
						UPDATE	XAGENDA
						SET		ERROR = 'SI'
						WHERE	PAR_KEY = @IPKEYJOB
						RETURN
					END
					
					--valido que la fecha seleccionada sea mayor a la fecha actual
					--valido que la fecha seleccionada este disponible para el cliente/proyecto/servicio
					--NO valido que la fecha seleccionada este disponible por consultor porque NO se selecciona Consultor
					IF (CONVERT(VARCHAR(10), CONVERT(date, convert(varchar,DATEPART(DD,@VFECHA))+'-'+convert(varchar,DATEPART(MM,@VFECHA))+'-'+convert(varchar,DATEPART(YYYY,@VFECHA)), 105), 23)
						< CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23)) BEGIN
 
						SET @OCODE = '1'
						SET @OMENSAJE = '<html>
										<body>
											<div class="w3-panel w3-pale-red" style="height: 20px;">
												<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha Desde debe ser Mayor o Igual a la Fecha Actual</b></font>
											</div>
										</div>
										</body>
										</html>'
									
						UPDATE	XAGENDA
						SET		ERROR = 'SI'
						WHERE	PAR_KEY = @IPKEYJOB
						RETURN
 
					END
 
					--primero recorro de fecha desde a fecha hasta, si todas las fechas estan diponibles --> OK sino paro y aviso que la fecha XXX no esta disponible para el consultor
					WHILE @VREG <= @VDIF  
					BEGIN  
						
						SELECT	@VEXISTE = COUNT(1) 
						FROM	LK_AGENDA 
						WHERE	ID_CLIENTE = @VCLIENTE 
						AND		ID_PROYECTO = @VPROYECTO 
						AND		ID_SERVICIO = @VTIPOSERVICIO
						AND		PROYECTO_SERV_ID = @VID
						AND		FECHA = @VFECHA
 
						IF (@VEXISTE > 0) BEGIN
							SET @OCODE = '1'
							SET @OMENSAJE = '<html>
											<body>
												<div class="w3-panel w3-pale-red" style="height: 20px;">
													<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha '+CONVERT(varchar, DATEPART(DD, @VFECHA))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA))+' NO se encuentra Disponible para el Cliente Proyecto Servicio</b></font>
												</div>
											</div>
											</body>
											</html>'
									
							UPDATE	XAGENDA
							SET		ERROR = 'SI'
							WHERE	PAR_KEY = @IPKEYJOB
							RETURN
 
						END
 
						SET @VCANT = 0	
						SET @VCONSULTORES2 = @VCONSULTORES
 
						--RECORRO EL/LOS CONSULTORES
						WHILE LEN(@VCONSULTORES2) > 0
						BEGIN 
							SET @lnuPosComa = CHARINDEX('|', @VCONSULTORES2) -- Busca el caracter a separador
							IF (@lnuPosComa = 0) BEGIN 
								SET @lstDato = @VCONSULTORES2
								SET @VCONSULTORES2 = '' 
							END ELSE BEGIN
								SET @lstDato = SUBSTRING(@VCONSULTORES2, 1, @lnuPosComa - 1)
								--SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
								--SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
								SELECT	@VDESCCONS = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
								FROM	LK_EMPLEADOS
								WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
 
								--VALIDO QUE EL RANGO DE FECHAS DESDE Y HASTA ESTES DISPONIBLES
								SELECT	@VCANT = COUNT(1)
								FROM	LK_AGENDA_EMPLEADO
								WHERE	Fecha = @VFECHA
								AND		CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
								AND		TIPO = 'D'
 
								IF (@VCANT > 0) BEGIN
				
									SET @VCONSULTORES2 = SUBSTRING(@VCONSULTORES2, @lnuPosComa + 1, LEN(@VCONSULTORES2))
 
								END ELSE BEGIN
 
									SET @OCODE = '1'
									SET @OMENSAJE = '<html>
													<body>
														<div class="w3-panel w3-pale-red" style="height: 20px;">
															<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:#641E16"><b>La Fecha '+CONVERT(varchar, DATEPART(DD, @VFECHA))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA))+' NO se encuentra Disponible para el Consultor '+  @VDESCCONS + '</b></font>
														</div>
													</div>
													</body>
													</html>'
 
									SET @VLOG = 1
									
									UPDATE	XAGENDA
									SET		ERROR = 'SI'
									WHERE	PAR_KEY = @IPKEYJOB
									RETURN
								END
							END
						END
 
						SET @VFECHA = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,1,@VFECHA), 105), 23)
						SET @VREG = @VREG + 1
						--SET @VLOG = 0
					END
 
					IF (@VLOG = 0) BEGIN
				
						SET @VREG = 0
						SET @VDIF = DATEDIFF(DD,@VFECHAD,@VFECHAH)
						--SET @VHORAS_TOTALES = 0
						SET @VFECHA = @VFECHAD
 
						WHILE @VREG <= @VDIF 
							
						BEGIN
							
							--SET @VHORAS_TOTALES = @VHORAS_TOTALES + @VHORAS 
 
							IF (@VID_AGENDA = 0) BEGIN
								INSERT INTO LK_AGENDA
								(FECHA,ID_CLIENTE,ID_PROYECTO,ID_SERVICIO,ID_CONSULTOR,
								 DIA,MES,ANO,
								 ESTADO,NORMA,FECHA_ALTA,USUARIO_ALTA,OBSERVADOR,FECHA_HASTA,DIAS, OBSERV_LOGISTICA, OBSERV_CALIF, LIDER, PROYECTO_SERV_ID)
								VALUES
								(@VFECHA, @VCLIENTE, @VPROYECTO, @VTIPOSERVICIO, @VCONSULTORES,
								 CONVERT(varchar, DATEPART(DD, @VFECHA)),CONVERT(varchar, DATEPART(MM, @VFECHA)),CONVERT(varchar, DATEPART(YYYY, @VFECHA)),
								 @VESTADO, @VNORMA, GETDATE(), @IAGENTE, @VOBSERVADOR, @VFECHAH, DATEDIFF(DD,@VFECHAD,@VFECHAH) +1,	@VOBS_LOGIS, @VOBS_CALIF, @VLIDER, @VID)
 
								 SELECT	@VID_AGENDA = IDENT_CURRENT ('LK_AGENDA')
 
								 SET @VCONSULTORES2 = @VCONSULTORES
 
								 WHILE LEN(@VCONSULTORES2) > 0
									BEGIN 
										SET @lnuPosComa = CHARINDEX('|', @VCONSULTORES2) -- Busca el caracter a separador
										IF (@lnuPosComa = 0) BEGIN 
											SET @lstDato = @VCONSULTORES2
											SET @VCONSULTORES2 = '' 
										END ELSE BEGIN
											SET @lstDato = SUBSTRING(@VCONSULTORES2, 1, @lnuPosComa - 1)
											--SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
											--SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
											 --ACTUALIZO EL REGISTRO DEL CONSULTOR DE LA TABLA LK_AGENDA_EMPLEADO
											 UPDATE LK_AGENDA_EMPLEADO
											 SET	TIPO = 'A',
													--GRABO EN ORDER-- IDAGENDA|ESTADO|IDCLIENTE|IDPROYECTO|ISERVICIO, 
													HOLIDAYTEXT = convert(varchar,@VID_AGENDA),--+'|'+CASE WHEN (ISNULL(@VESTADO,'')='') THEN 'S' ELSE @VESTADO END+'|'+@VCLIENTE+'|'+@VPROYECTO+'|'+@VTIPOSERVICIO
													HORAS = @VHORAS
											 WHERE	FECHA = @VFECHA
											 AND	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
 
										END
								
										SET @VCONSULTORES2 = SUBSTRING(@VCONSULTORES2, @lnuPosComa + 1, LEN(@VCONSULTORES2))
									END
 
								/* Grabo el ID de Documentacion que corresponda segun el Servicio
									5	RE-PP-038	Hoja de Ruta Auditoria
									6	RE-PP-039	Hoja de Ruta Capacitacion
									7	RE-PP-040	Hoja de Ruta Consultoria
 
									1	Consultoria --> GRABO ID 7
									2	Auditoria --> GRABO ID 5
									3	Capacitacion --> GRABO ID 6
								*/
								SELECT	@VID_DOC =	CASE WHEN @VTIPOSERVICIO = '1' THEN '7'
															WHEN @VTIPOSERVICIO = '2' THEN '5'
															WHEN @VTIPOSERVICIO = '3' THEN '6'
													END 
 
								INSERT INTO LK_PROYECTO_DOCUM
								(ID_PROYECTO, ID_TIPO_SERVICIO, ID_DOCUMENTACION, 
								 FECHA_DOCUM, NRO_DOCUM_INTERNO,
								 PARTICIPANTES_DOCUM, TEMAS_DOCUM, ADJUNTO_DOCUM,
								 CONSULTOR, VISITA_MES, CONSULTOR_ACOMP, OBSERVACIONES,FECHA_CIERRE,
								 ID_AGENDA)
								VALUES
								(@VPROYECTO, @VTIPOSERVICIO, @VID_DOC, 
								 GETDATE(), 'Hoja de Ruta '+ CASE WHEN @VTIPOSERVICIO = '1' THEN 'Consultoria' WHEN @VTIPOSERVICIO = '2' THEN 'Auditoria' WHEN @VTIPOSERVICIO = '3' THEN 'Capacitacion' END + ' - ' + CONVERT(varchar, DATEPART(DD, @VFECHA))+'-'+CONVERT(varchar, DATEPART(MM, @VFECHA))+'-'+CONVERT(varchar, DATEPART(YYYY, @VFECHA)), 
								 NULL, NULL, NULL,
								 @VCONSULTORES, NULL, NULL, NULL, NULL,
								 @VID_AGENDA)
 
								SELECT	@VID_PROYECTO_DOCUM = IDENT_CURRENT ('LK_PROYECTO_DOCUM')
 
									--RECUPERO TODOS LOS ITEMS QUE CORRESPONDEN AL DETALLE DE LA HOJA DE RUTA QUE CORRESPONDA SEGUN SERVICIO--
								DECLARE Items CURSOR FOR 
									SELECT	DESC_DOC_DET, GRUPO_DOC_DET, ISNULL(ORDEN,99) ORDEN
									FROM	LK_DOCUMENTACION_DET
									WHERE	ID_DOCUMENTACION = @VID_DOC
									AND		STATUS_DOC_DET = '1'
									ORDER BY CASE WHEN GRUPO_DOC_DET = 'LOGISTICO' THEN 1 
												  WHEN GRUPO_DOC_DET = 'TECNICO' THEN 2
												  WHEN GRUPO_DOC_DET = 'ADMINISTRACION' THEN 3 END, ISNULL(ORDEN,99)
 
								OPEN Items  
								FETCH NEXT FROM Items INTO @VDESC_DOC_DET, @VGRUPO_DOC_DET, @VORDEN
 
								WHILE @@FETCH_STATUS = 0  
								BEGIN  
 
									INSERT INTO LK_PROYECTO_DOCUM_DET
									(ID_PROYECTO_DOCUM, DESC_DOC_DET, VALOR_DOC_DET, GRUPO_DOC_DET, ADJUNTO_DOC_DET, ORDEN)
									VALUES
									(@VID_PROYECTO_DOCUM, @VDESC_DOC_DET, NULL, @VGRUPO_DOC_DET, NULL, @VORDEN)
 
									FETCH NEXT FROM Items INTO @VDESC_DOC_DET, @VGRUPO_DOC_DET, @VORDEN
								END 
 
								CLOSE Items  
								DEALLOCATE Items
 
								SET @VFECHA = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,1,@VFECHA), 105), 23)
								SET @VREG = @VREG + 1
						
							END ELSE BEGIN
								
								SET @VCONSULTORES2 = @VCONSULTORES
 
								 WHILE LEN(@VCONSULTORES2) > 0
									BEGIN 
										SET @lnuPosComa = CHARINDEX('|', @VCONSULTORES2) -- Busca el caracter a separador
										IF (@lnuPosComa = 0) BEGIN 
											SET @lstDato = @VCONSULTORES2
											SET @VCONSULTORES2 = '' 
										END ELSE BEGIN
											SET @lstDato = SUBSTRING(@VCONSULTORES2, 1, @lnuPosComa - 1)
											--SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
											--SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
 
											 --ACTUALIZO EL REGISTRO DEL CONSULTOR DE LA TABLA LK_AGENDA_EMPLEADO
											 UPDATE LK_AGENDA_EMPLEADO
											 SET	TIPO = 'A',
													--GRABO EN ORDER-- IDAGENDA|ESTADO|IDCLIENTE|IDPROYECTO|ISERVICIO, 
													HOLIDAYTEXT = convert(varchar,@VID_AGENDA),--+'|'+CASE WHEN (ISNULL(@VESTADO,'')='') THEN 'S' ELSE @VESTADO END+'|'+@VCLIENTE+'|'+@VPROYECTO+'|'+@VTIPOSERVICIO
													HORAS = @VHORAS
											 WHERE	FECHA = @VFECHA
											 AND	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
										END
								
										SET @VCONSULTORES2 = SUBSTRING(@VCONSULTORES2, @lnuPosComa + 1, LEN(@VCONSULTORES2))
									END
							
								SET @VFECHA = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,1,@VFECHA), 105), 23)
								SET @VREG = @VREG + 1
							END
						END				
					END
				END 
			END
 
			--si no elige consultor-- no se ACTUALIZAN LOS VALORES--
			IF (@VCONSULTORES <> '') BEGIN
 
				IF (@VTIPOSERVICIO <> '3') BEGIN
				--CONSULTORIA Y AUDITORIA
				--LA SUMA DE HORAS ES IGUAL A: EL TOTAL DE HORAS CARGADAS POR N DIAS POR N CONSULTORES
 
					SELECT	@VHORAS_TOTALES = SUM(HORAS)
					FROM	LK_AGENDA_EMPLEADO
					WHERE	HOLIDAYTEXT = convert(varchar,@VID_AGENDA)
 
					--actualizo el total de horas del servicio y del proyecto
					UPDATE	LK_PROYECTO_SERVICIO
					SET		ESTADO_PROYECTO = 'ENCURSO',
							TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) + @VHORAS_TOTALES
					WHERE	ID_PROYECTO_SERVICIO = @VID
 
					UPDATE	LK_PROYECTO
					SET		ESTADO_PROYECTO_TOTAL = 'ENCURSO',
							TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) + @VHORAS_TOTALES
					WHERE	ID_PROYECTO = @VPROYECTO
 
					--ACTUALIZO LOS PORCENTAJES
					UPDATE	LK_PROYECTO_SERVICIO
					SET		PORCENTAJE_AVANCE = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
					WHERE	ID_PROYECTO_SERVICIO = @VID
 
					UPDATE	LK_PROYECTO
					SET		PORCENTAJE_AVANCE_TOTAL = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
					WHERE	ID_PROYECTO = @VPROYECTO
 
				END ELSE BEGIN
				--SOLO CAPACITACION
				--LA SUMA DE HORAS ES IGUAL A: EL TOTAL DE HORAS CARGADAS POR N DIAS SOLAMENTE
					
					SELECT	@VDIAS = DIAS
					FROM	LK_AGENDA
					WHERE	ID_AGENDA = @VID_AGENDA
 
					SET @VHORAS_TOTALES = @VHORAS * @VDIAS
 
					--actualizo el total de horas del servicio y del proyecto
					UPDATE	LK_PROYECTO_SERVICIO
					SET		ESTADO_PROYECTO = 'ENCURSO',
							TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) + @VHORAS_TOTALES
					WHERE	ID_PROYECTO_SERVICIO = @VID
 
					UPDATE	LK_PROYECTO
					SET		ESTADO_PROYECTO_TOTAL = 'ENCURSO',
							TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) + @VHORAS_TOTALES
					WHERE	ID_PROYECTO = @VPROYECTO
 
					--ACTUALIZO LOS PORCENTAJES
					UPDATE	LK_PROYECTO_SERVICIO
					SET		PORCENTAJE_AVANCE = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
					WHERE	ID_PROYECTO_SERVICIO = @VID
 
					UPDATE	LK_PROYECTO
					SET		PORCENTAJE_AVANCE_TOTAL = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
					WHERE	ID_PROYECTO = @VPROYECTO
 
				END
			END
			
			IF (@OCODE = '0') BEGIN
				UPDATE	XAGENDA
				SET		ERROR = 'NO'
				WHERE	PAR_KEY = @IPKEYJOB
			END
		END
	END
END
