CREATE PROCEDURE [dbo].[SV_04_MODIFY_EMPLEADO]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE @VAPELLIDO		VARCHAR(100),
		@VNOMBRE		VARCHAR(100),
		@VTIPO_DOC		VARCHAR(50),
		@VNRO_DOC		VARCHAR(50),
		@VCUIT			VARCHAR(50),
		@VINGRESO		VARCHAR(50),
		@VUSUARIO		VARCHAR(100),
		@VCLAVE			VARCHAR(100),
		@VCALLE			VARCHAR(100),
		@VNRO			VARCHAR(30),
		@VPISO			VARCHAR(30),
		@VLOCALIDAD		VARCHAR(100),
		@VPROVINCIA		VARCHAR(50),
		@VTELEFONO1		VARCHAR(100),
		@VTELEFONO2		VARCHAR(100),
		@VEMAIL			VARCHAR(100),
		@VFORMACION		VARCHAR(100),
		@VMOVILIDAD		VARCHAR(50),
		@VPERFIL		VARCHAR(50),
		@VAUDITORIA		VARCHAR(50),
		@VCAPACITACION	VARCHAR(50), 
		@VCONSULTORIA	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VID_CONSULTOR	VARCHAR(50),
		@VERROR			VARCHAR(50),
		@VCANT			INT,
		@VDIAS			VARCHAR(50),
		@VDIAS_ANT		VARCHAR(50),
		@VPKEY_CV		VARCHAR(100),
		@VID_EMPLEADO	INT,
		@VID_SELEC		VARCHAR(50),
		@VCANT_CONS		INT,
		@VCANT_AUDI		INT,
		@VCANT_CAPA		INT,
		@cant int,
		@NEW_PASS_ENC VARCHAR(100),
		@VEVENTUAL		VARCHAR(50)
 
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,''),
			@VAPELLIDO = ISNULL(APELLIDO,''),
			@VTIPO_DOC = ISNULL(TIPO_DOC,''),
			@VNRO_DOC = ISNULL(NRO_DOC,''),
			@VCUIT = ISNULL(CUIT,''),
			@VINGRESO = ISNULL(INGRESO,''),
			@VUSUARIO = ISNULL(USUARIO,''),
			@VCLAVE = ISNULL(CLAVE,''),			
			@VCALLE = ISNULL(CALLE,''),
			@VNRO = ISNULL(NRO,''),
			@VPISO = ISNULL(PISO,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD,''),
			@VPROVINCIA = ISNULL(PROVINCIA,''),
			@VTELEFONO1 = ISNULL(TELEFONO1,''),
			@VTELEFONO2 = ISNULL(TELEFONO2,''),
			@VEMAIL = ISNULL(EMAIL,''),
			@VFORMACION = ISNULL(FORMACION,''),
			@VMOVILIDAD = ISNULL(MOVILIDAD,''),
			@VPERFIL = ISNULL(PERFIL,''),
			@VAUDITORIA = ISNULL(CONS_TIPO_AUDI,'0'),
			@VCAPACITACION = ISNULL(CONS_TIPO_CAPA,'0'),
			@VCONSULTORIA = ISNULL(CONS_TIPO_CONS,'0'),
			@VESTADO = ISNULL(ESTADO,''),
			@VERROR = ISNULL(ERROR,''),
			@VDIAS = ISNULL(DIAS_MENSUALES,'0'),
			@VID_SELEC = ISNULL(ID_SELEC,''),
			@VEVENTUAL = ISNULL(EVENTUAL,'')
	FROM	TMT_SV_04
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	TOP 1 @VPKEY_CV = ISNULL(PKEY,'')
	FROM	PHYSICAL_ATTACHED_DOCUMENT
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VAPELLIDO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Apellido</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VNOMBRE = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Nombres</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VTIPO_DOC = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Tipo Documento</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VNRO_DOC = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Nro Documento</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
	
		END ELSE BEGIN
		
			IF (ISNUMERIC(@VNRO_DOC) <> '1') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Nro Documento solamente con Numeros</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
				UPDATE	TMT_SV_04
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
		END
 
		IF (@VINGRESO = '') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Ingreso Sistema?</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
	
		END ELSE BEGIN
 
			IF (@VINGRESO = 'SI') BEGIN
				IF (@VUSUARIO = '' OR @VCLAVE = '') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar los Campos Usuario y Clave para la opcion ingresada en Ingreso Sistema</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
					UPDATE	TMT_SV_04
					SET		ERROR = 'SI'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
			END
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
									
				UPDATE	TMT_SV_04
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
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VPERFIL = '') BEGIN
	
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Perfil</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
	
		END ELSE BEGIN
		
			IF (@VPERFIL = 'CONSULTOR') BEGIN
				IF (@VAUDITORIA = '0' AND @VCAPACITACION = '0' AND @VCONSULTORIA = '0') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe Seleccionar al menos un Servicio para el Perfil Seleccionado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
					UPDATE	TMT_SV_04
					SET		ERROR = 'SI',
							CONS_TIPO_CONS = NULL,
							CONS_TIPO_AUDI = NULL,
							CONS_TIPO_CAPA = NULL
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
		
			END ELSE BEGIN
				IF (@VAUDITORIA = '1' OR @VCAPACITACION = '1' OR @VCONSULTORIA = '1') BEGIN
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>NO Debe Seleccionar ningun Servicio para el Perfil Seleccionado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
					UPDATE	TMT_SV_04
					SET		ERROR = 'SI',
							CONS_TIPO_CONS = NULL,
							CONS_TIPO_AUDI = NULL,
							CONS_TIPO_CAPA = NULL
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
			END
 
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
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
		END
 
		IF (@VEVENTUAL = '' and @VPERFIL = 'CONSULTOR') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Eventual</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
	
		END
 
		IF (@VDIAS = '' and @VPERFIL = 'CONSULTOR') BEGIN
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Dias Mensuales</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
	
		END ELSE BEGIN
		
			IF (ISNUMERIC(@VDIAS) <> '1' and @VPERFIL = 'CONSULTOR') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Dias Mensuales solamente con Numeros</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
				UPDATE	TMT_SV_04
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
		END
 
		--VALIDO QUE NO EXISTA EL MISMO EMPLEADO EN LK_EMPLEADOS POR TIPO Y NRO DOCUMENTO--
		SELECT	@VCANT = COUNT(1)
		FROM	LK_EMPLEADOS
		WHERE	TIPO_DOC_EMP = LTRIM(RTRIM(@VTIPO_DOC))
		AND		NRO_DOC_EMP = LTRIM(RTRIM(@VNRO_DOC))
		AND		ID_EMPLEADO <> @VID_SELEC
 
		IF (@VCANT > 0) BEGIN
		
			SET @OCODE = '1'
			SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Empleado/Consultor para el Tipo y Nro Documento ingresado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
			UPDATE	TMT_SV_04
			SET		ERROR = 'SI'
			WHERE	PAR_KEY = @IPKEYJOB
			RETURN
 
		END --ELSE BEGIN
		/*
			--Verifico que no existe un usuario igual al ingresado--
			IF (@VINGRESO = 'SI') BEGIN
	
				SELECT	@VCANT = COUNT(1)
				FROM	Users
				WHERE	Id = @VUSUARIO
 
				IF (@VCANT > 0) BEGIN 
					SET @OCODE = '1'
					SET @OMENSAJE = '<html>
							<body>
							  <div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Ya Existe un Usuario de Sistema igual al ingresado</b></font>
							  </div>
							</div>
							</body>
							</html>'
									
					UPDATE	TMT_SV_04
					SET		ERROR = 'SI'
					WHERE	PAR_KEY = @IPKEYJOB
					RETURN
				END
 
			END*/
		
			BEGIN	
 
				--VERIFICO SI LOS DIAS MENSUALES INGRESADO SON DISTINTOS DEL ANTERIOR--
				SELECT	@VDIAS_ANT = ISNULL(DIAS_MENSUALES,'0')
				FROM	LK_EMPLEADOS
				WHERE	ID_EMPLEADO = @VID_SELEC
				
				UPDATE	LK_EMPLEADOS
				SET		NOMBRE_EMPLEADO = @VNOMBRE, 
						APELLIDO_EMPLEADO = @VAPELLIDO, 
						TIPO_DOC_EMP = @VTIPO_DOC, 
						NRO_DOC_EMP = @VNRO_DOC, 
						INGRESA_SISTEMA = @VINGRESO, 
						USUARIO_EMP = @VUSUARIO, 
						PASS_EMP = @VCLAVE,
						CUIT_EMP = @VCUIT, 
						CALLE_EMP = @VCALLE,
						NRO_CALLE_EMP = @VNRO, 
						PISO_DEPTO_EMP = @VPISO, 
						LOCALIDAD_EMP = @VLOCALIDAD, 
						PROVINCIA_EMP = @VPROVINCIA, 
						TEL1_EMP = @VTELEFONO1, 
						TEL2_EMP = @VTELEFONO2,
						EMAIL_EMP = @VEMAIL, 
						FORMACION_EMP = @VFORMACION, 
						MOVILIDAD_EMP = @VMOVILIDAD, 
						PERFIL_EMP = @VPERFIL, 
						STATUS_EMP = @VESTADO, 
						FECHA_UPD = GETDATE(), 
						USUARIO_UPD= @IAGENTE,
						DIAS_MENSUALES = @VDIAS,
						EVENTUAL = @VEVENTUAL
				WHERE	ID_EMPLEADO = @VID_SELEC
 
				IF (@VDIAS <> @VDIAS_ANT) BEGIN
					
					SELECT	@VCANT = COUNT(1)
					FROM	LK_EMPLEADOS_DIAS
					WHERE	ID_EMPLEADO = @VID_SELEC
					AND		MES = DATEPART(MM,GETDATE())
					AND		ANO = DATEPART(YYYY,GETDATE())
 
					IF (@VCANT = 0) BEGIN
						
						INSERT INTO LK_EMPLEADOS_DIAS
						(ID_EMPLEADO, MES, ANO, DIAS, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
						VALUES
						(@VID_SELEC, DATEPART(MM,GETDATE()), DATEPART(YYYY,GETDATE()), CAST(@VDIAS_ANT AS INT), GETDATE(), @IAGENTE, GETDATE(), @IAGENTE)
 
					/*END ELSE BEGIN
 
						UPDATE	LK_EMPLEADOS_DIAS
						SET		DIAS = CAST(@VDIAS AS INT),
								FECHA_UPD = GETDATE(),
								USUARIO_UPD = @IAGENTE
						WHERE	ID_EMPLEADO = @VID_SELEC
						AND		MES = DATEPART(MM,GETDATE())
						AND		ANO = DATEPART(YYYY,GETDATE())
					*/
					END
 
				END
 
				IF (@VPKEY_CV <> '') BEGIN
					
					UPDATE	LK_EMPLEADOS
					SET		CV_EMP_PKEY = @VPKEY_CV,
							FECHA_CV_EMP = GETDATE()
					WHERE	ID_EMPLEADO = @VID_SELEC
 
					UPDATE	PHYSICAL_ATTACHED_DOCUMENT
					SET		PAR_KEY = @VID_SELEC
					WHERE	PKEY = @VPKEY_CV
				END
 
				--Ingreso registro en la tabla AGENTE--
				/*
				IF (@VINGRESO = 'SI') BEGIN
						 
					SET @NEW_PASS_ENC = CONVERT(VARCHAR(40), HashBytes('SHA1', upper(CAST(@VUSUARIO AS VARCHAR))+@VCLAVE), 2)
 
					INSERT INTO Users VALUES (@VUSUARIO, @VAPELLIDO + ',' + @VNOMBRE, 1, 0, @VEMAIL, @VTELEFONO1, NULL, @NEW_PASS_ENC, NEWID(), GETDATE(), GETDATE())
 
					INSERT INTO GroupsUserMembers VALUES ('PROYECTOS', @VUSUARIO, NEWID(), GETDATE())
				END*/
 
				BEGIN
 
					IF (@VCONSULTORIA = '1') BEGIN
					
						SELECT	@VCANT_CONS = COUNT(1)
						FROM	LK_EMPLEADOS_TIPO
						WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @VID_SELEC
						AND		ID_TIPO = 1
 
						IF (@VCANT_CONS = 0) BEGIN
 
							INSERT INTO LK_EMPLEADOS_TIPO
							(ID_EMPLEADO, ID_TIPO, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
							VALUES
							(CONVERT(INT,@VID_SELEC), 1, GETDATE(), @IAGENTE, GETDATE(), @IAGENTE)
						END
					END
 
					IF (@VAUDITORIA = '1') BEGIN
 
						SELECT	@VCANT_AUDI = COUNT(1)
						FROM	LK_EMPLEADOS_TIPO
						WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @VID_SELEC
						AND		ID_TIPO = 2
 
						IF (@VCANT_AUDI = 0) BEGIN
 
							INSERT INTO LK_EMPLEADOS_TIPO
							(ID_EMPLEADO, ID_TIPO, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
							VALUES
							(CONVERT(INT,@VID_SELEC), 2, GETDATE(), @IAGENTE, GETDATE(), @IAGENTE)
						END
					END
		 
					IF (@VCAPACITACION = '1') BEGIN
 
						SELECT	@VCANT_CAPA = COUNT(1)
						FROM	LK_EMPLEADOS_TIPO
						WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @VID_SELEC
						AND		ID_TIPO = 3
					
						IF (@VCANT_CAPA = 0) BEGIN
 
							INSERT INTO LK_EMPLEADOS_TIPO
							(ID_EMPLEADO, ID_TIPO, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
							VALUES
							(CONVERT(INT,@VID_SELEC), 3, GETDATE(), @IAGENTE, GETDATE(), @IAGENTE)
						END
					END
 
				END
 
			END
		--END
	END
 
	IF (@OCODE = '0') BEGIN
		UPDATE	TMT_SV_04
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
END
