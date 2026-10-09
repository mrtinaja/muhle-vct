CREATE PROCEDURE [dbo].[HOME_MOD_DET_VIATICO]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OCODE		AS VARCHAR(2) OUTPUT,
 @OMENSAJE	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE	@VPROYECTO				VARCHAR(50),
		@VSERVICIO				VARCHAR(50),
		@VPROYECTO_SERV			VARCHAR(50),
		@VTIPO_SERV				VARCHAR(50),
		@VPROVEEDOR_ID			VARCHAR(50),
		@VTIPO_PROV				VARCHAR(50),
		@VCANT					INT,
		@VAGENDA_ID				VARCHAR(50),
		@VERROR					VARCHAR(50),
		@VID_VIATICO			VARCHAR(50),
		@VRESERVA				VARCHAR(100),
		@VFECHA					DATETIME,
		@VVUELO					VARCHAR(50),
		@VORIGEN				VARCHAR(100),
		@VDESTINO				VARCHAR(100),
		@VSALIDA				VARCHAR(100),
		@VLLEGADA				VARCHAR(100),
		@VLOCAL					VARCHAR(100),
		@VFINGRESO				DATETIME,
		@VFEGRESO				DATETIME,
		@VFPARTIDA				DATETIME,
		@VFLLEGADA				DATETIME,
		@VPAGA_CONSULTOR		VARCHAR(50),
		@VPAGA_CONSULTORA		VARCHAR(50),
		@VRENDICION_CLIENTE		VARCHAR(50),
		@VID_DETALLE			VARCHAR(50),
		@VKMS					VARCHAR(50),
		@VPEAJES				VARCHAR(50)
		
BEGIN	
 
	SET @OCODE = '0'
	SET @OMENSAJE = ''
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_VIATICO = ISNULL(HOJA_RUTA_ID,''),
			@VTIPO_PROV = ISNULL(TIPO_PROV,''),
			@VID_DETALLE = ISNULL(ID_DETALLE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VRESERVA = ISNULL(DET_PROV_RESERVA,''),
			@VFECHA = ISNULL(DET_PROV_FECHA,''),
			@VVUELO = ISNULL(DET_PROV_VUELO,''),
			@VORIGEN = ISNULL(DET_PROV_ORIGEN,''),
			@VDESTINO = ISNULL(DET_PROV_DESTINO,''),
			@VSALIDA = ISNULL(DET_PROV_SALIDA,''),
			@VLLEGADA = ISNULL(DET_PROV_LLEGADA,''),
			@VLOCAL = ISNULL(DET_PROV_LOCAL,''),
			@VFINGRESO = ISNULL(DET_PROV_FINGRESO,''),
			@VFEGRESO = ISNULL(DET_PROV_FEGRESO,''),
			@VFPARTIDA = ISNULL(DET_PROV_FPARTIDA,''),
			@VFLLEGADA = ISNULL(DET_PROV_FLLEGADA,''),
			@VPAGA_CONSULTOR = ISNULL(PAGA_CONSULTOR,''),
			@VPAGA_CONSULTORA = ISNULL(PAGA_CONSULTORA,''),
			@VRENDICION_CLIENTE = ISNULL(RENDICION_CLIENTE,''),
			@VKMS = ISNULL(DET_PROV_KMS,''),
			@VPEAJES = ISNULL(DET_PROV_PEAJES,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	
	IF @VERROR = '' BEGIN
		SET @OCODE = '0'
		SET @OMENSAJE = ''
 
	END ELSE BEGIN
 
		IF (@VTIPO_PROV = 'AVION' OR @VTIPO_PROV = 'MICRO') BEGIN
 
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
			
			UPDATE	LK_PROYECTO_VIATICOS_DET
			SET		DET_PROV_RESERVA = @VRESERVA,
					DET_PROV_FECHA = @VFECHA,
					DET_PROV_VUELO = @VVUELO,
					DET_PROV_ORIGEN = @VORIGEN,
					DET_PROV_DESTINO = @VDESTINO,
					DET_PROV_SALIDA = @VSALIDA,
					DET_PROV_LLEGADA = @VLLEGADA,
					PAGA_CONSULTOR = @VPAGA_CONSULTOR,
					PAGA_CONSULTORA = @VPAGA_CONSULTORA,
					RENDICION_CLIENTE = @VRENDICION_CLIENTE
			WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
			
		END
 
		IF (@VTIPO_PROV = 'HOTEL') BEGIN
 
			IF (@VFINGRESO = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Ingreso</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			IF (@VFEGRESO = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Egreso</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			UPDATE	LK_PROYECTO_VIATICOS_DET
			SET		DET_PROV_LOCAL = @VLOCAL,
					DET_PROV_FINGRESO = @VFINGRESO,
					DET_PROV_FEGRESO = @VFEGRESO,
					PAGA_CONSULTOR = @VPAGA_CONSULTOR,
					PAGA_CONSULTORA = @VPAGA_CONSULTORA,
					RENDICION_CLIENTE = @VRENDICION_CLIENTE
			WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
			
			
		END
 
		IF (@VTIPO_PROV = 'TAXI' OR @VTIPO_PROV = 'REMIS') BEGIN
 
			IF (@VFPARTIDA = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Partida</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			IF (@VFLLEGADA = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Llegada</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			UPDATE	LK_PROYECTO_VIATICOS_DET
			SET		DET_PROV_ORIGEN = @VORIGEN,
					DET_PROV_FPARTIDA = @VFPARTIDA,
					DET_PROV_DESTINO = @VDESTINO,
					DET_PROV_FLLEGADA = @VFLLEGADA,
					DET_PROV_SALIDA = @VSALIDA,
					DET_PROV_LLEGADA = @VLLEGADA,
					PAGA_CONSULTOR = @VPAGA_CONSULTOR,
					PAGA_CONSULTORA = @VPAGA_CONSULTORA,
					RENDICION_CLIENTE = @VRENDICION_CLIENTE
			WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
			
		END
 
		IF (@VTIPO_PROV = 'AUTO') BEGIN
 
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
 
			UPDATE	LK_PROYECTO_VIATICOS_DET
			SET		DET_PROV_KMS = @VKMS,
					DET_PROV_PEAJES = @VPEAJES,
					PAGA_CONSULTOR = @VPAGA_CONSULTOR,
					PAGA_CONSULTORA = @VPAGA_CONSULTORA,
					RENDICION_CLIENTE = @VRENDICION_CLIENTE
			WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
			
		END
 
		IF (@VTIPO_PROV = 'ALQUILER') BEGIN
 
			IF (@VFPARTIDA = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Desde</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			IF (@VFLLEGADA = '') BEGIN
				SET @OCODE = '1'
				SET @OMENSAJE = '<html>
								<body>
								  <div class="w3-panel w3-pale-red" style="height: 20px;">
										<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>Debe completar el Campo Fecha Hasta</b></font>
								  </div>
								</div>
								</body>
								</html>'
			
				UPDATE	XAGENDA
				SET		ERROR = 'SI'
				WHERE	PAR_KEY = @IPKEYJOB
				RETURN
			END
 
			UPDATE	LK_PROYECTO_VIATICOS_DET
			SET		DET_PROV_ORIGEN = @VORIGEN,
					DET_PROV_FPARTIDA = @VFPARTIDA,
					DET_PROV_DESTINO = @VDESTINO,
					DET_PROV_FLLEGADA = @VFLLEGADA,
					PAGA_CONSULTOR = @VPAGA_CONSULTOR,
					PAGA_CONSULTORA = @VPAGA_CONSULTORA,
					RENDICION_CLIENTE = @VRENDICION_CLIENTE
			WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
			
		END
 
	END	
 
	IF (@OCODE = '0') BEGIN
		UPDATE	XAGENDA
		SET		ERROR = 'NO'
		WHERE	PAR_KEY = @IPKEYJOB
	END
END
 
