CREATE PROCEDURE [dbo].[HOME_INI_ADD_VIATICOS_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT
 )
AS
 
DECLARE	@VID			VARCHAR(50),
		@VSERVICIO		VARCHAR(100),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VPROYECTO		VARCHAR(300),
		@VCLIENTE		VARCHAR(300),
		@VIDCLIENTE		VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VFECHA			VARCHAR(50),
		@VDIASP			VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VERROR			VARCHAR(50),
		@VID_VIATICO	VARCHAR(50),
		@VARNORMA		VARCHAR(400),
		@lstDato		VARCHAR(100), 
		@lnuPosComa		INT,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VID_SERVICIO	INT,
		@VID_PROYECTO	INT,
		@VESTADO		VARCHAR(100),
		@VFECHAD		VARCHAR(50),
		@VFECHAH		VARCHAR(50),
		@VDIAS			VARCHAR(50),
		@VTIPO_PROV		VARCHAR(50),
		@VHOTEL			VARCHAR(300),
		@VPROYECTO_SERV	VARCHAR(50),
		@VNOMBRE		VARCHAR(300),
		@VHORAS			VARCHAR(50),
		@VRAZON_SOCIAL	VARCHAR(400),
		@VNOMBRE_PROY	VARCHAR(400),
		@VTIPO_SERV		VARCHAR(50),
		@VLUGAR			VARCHAR(400)
 
DECLARE	@VID_SELEC		VARCHAR(100),
		@VDESC_ERROR	VARCHAR(4000),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
DECLARE @VTMT_DET_PROV_RESERVA		VARCHAR(50),
		@VTMT_DET_PROV_VUELO		VARCHAR(50),
		@VTMT_DET_PROV_ORIGEN		VARCHAR(100),
		@VTMT_DET_PROV_DESTINO		VARCHAR(100),
		@VTMT_DET_PROV_FECHA		DATETIME,
		@VTMT_DET_PROV_SALIDA		VARCHAR(50),
		@VTMT_DET_PROV_LLEGADA		VARCHAR(50),
		@VTMT_PAGA_CONSULTOR		VARCHAR(50),
		@VTMT_PAGA_CONSULTORA		VARCHAR(50),
		@VTMT_RENDICION_CLIENTE		VARCHAR(50),
		@VTMT_DESC_PROV				VARCHAR(400),
		@VTMT_DET_PROV_LOCAL		VARCHAR(100),
		@VTMT_DET_PROV_FINGRESO		DATETIME,
		@VTMT_DET_PROV_FEGRESO		DATETIME,
		@VTMT_DET_PROV_FPARTIDA		DATETIME,
		@VTMT_DET_PROV_FLLEGADA		DATETIME,
		@VTMT_DET_PROV_KMS			VARCHAR(100),
		@VTMT_DET_PROV_PEAJES		VARCHAR(100)
 
DECLARE @VDET_PROV_RESERVA			VARCHAR(50),
		@VDET_PROV_VUELO			VARCHAR(50),
		@VDET_PROV_ORIGEN			VARCHAR(100),
		@VDET_PROV_DESTINO			VARCHAR(100),
		@VDET_PROV_FECHA			DATETIME,
		@VDET_PROV_SALIDA			VARCHAR(50),
		@VDET_PROV_LLEGADA			VARCHAR(50),
		@VPAGA_CONSULTOR			VARCHAR(50),
		@VPAGA_CONSULTORA			VARCHAR(50),
		@VRENDICION_CLIENTE			VARCHAR(50),
		@VDESC_PROV					VARCHAR(400),
		@VDET_PROV_LOCAL			VARCHAR(100),
		@VDET_PROV_FINGRESO			DATETIME,
		@VDET_PROV_FEGRESO			DATETIME,
		@VDET_PROV_FPARTIDA			DATETIME,
		@VDET_PROV_FLLEGADA			DATETIME,
		@VDET_PROV_KMS				VARCHAR(100),
		@VDET_PROV_PEAJES			VARCHAR(100)
 
BEGIN
 
	SELECT	@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VID_VIATICO	= ISNULL(HOJA_RUTA_ID,''),
			@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_SELEC		= ISNULL(ID_DETALLE,''),
			@VTMT_DET_PROV_RESERVA = ISNULL(DET_PROV_RESERVA,''),
			@VTMT_DET_PROV_VUELO = ISNULL(DET_PROV_VUELO,''),
			@VTMT_DET_PROV_ORIGEN = ISNULL(DET_PROV_ORIGEN,''),
			@VTMT_DET_PROV_DESTINO = ISNULL(DET_PROV_DESTINO,''),
			@VTMT_DET_PROV_FECHA = ISNULL(DET_PROV_FECHA,''),
			@VTMT_DET_PROV_SALIDA = ISNULL(DET_PROV_SALIDA,''),
			@VTMT_DET_PROV_LLEGADA = ISNULL(DET_PROV_LLEGADA,''),
			@VTMT_PAGA_CONSULTOR = ISNULL(PAGA_CONSULTOR,''),
			@VTMT_PAGA_CONSULTORA = ISNULL(PAGA_CONSULTORA,''),
			@VTMT_RENDICION_CLIENTE = ISNULL(RENDICION_CLIENTE,''),
			@VTMT_DESC_PROV = ISNULL(DESCRIP_SERVICIO_PROV,''),
			@VTMT_DET_PROV_LOCAL = ISNULL(DET_PROV_LOCAL,''),
			@VTMT_DET_PROV_FINGRESO = ISNULL(DET_PROV_FINGRESO,''),
			@VTMT_DET_PROV_FEGRESO = ISNULL(DET_PROV_FEGRESO,''),
			@VTMT_DET_PROV_FPARTIDA = ISNULL(DET_PROV_FPARTIDA,''),
			@VTMT_DET_PROV_FLLEGADA = ISNULL(DET_PROV_FLLEGADA,''),
			@VTMT_DET_PROV_KMS = ISNULL(DET_PROV_KMS,''),
			@VTMT_DET_PROV_PEAJES = ISNULL(DET_PROV_PEAJES,'')			
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VTIPO_PROV = TIPO_PROVEEDOR,
			@VHOTEL = ISNULL(P.RAZON_SOCIAL_PROV,V.DESCRIP_SERVICIO)
	FROM	LK_PROYECTO_VIATICOS V
			LEFT JOIN LK_PROVEEDORES P ON P.ID_PROVEEDOR = V.ID_PROVEEDOR	
	WHERE	ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	SELECT	@VID_PROYECTO  = ID_PROYECTO,
			@VID_SERVICIO  = ID_SERVICIO,
			@VPROYECTO_SERV = PROYECTO_SERV_ID
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	SELECT	@VTIPO_SERV = ID_TIPO_SERVICIO,
			@VNOMBRE = ISNULL(NOMBRE,''),
			@VLUGAR = ISNULL(LUGAR,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	SELECT	@VDIAS_AGENDA = DIAS,
			@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END
	FROM	LK_AGENDA A
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_SELEC <> '') BEGIN
		
		SELECT	@VDET_PROV_RESERVA	= ISNULL(DET_PROV_RESERVA,''),
				@VDET_PROV_VUELO	= ISNULL(DET_PROV_VUELO,''),
				@VDET_PROV_ORIGEN	= ISNULL(DET_PROV_ORIGEN,''),
				@VDET_PROV_DESTINO	= ISNULL(DET_PROV_DESTINO,''),
				@VDET_PROV_FECHA	= NULLIF(ISNULL(DET_PROV_FECHA,''),''),
				@VDET_PROV_SALIDA	= ISNULL(DET_PROV_SALIDA,''),
				@VDET_PROV_LLEGADA	= ISNULL(DET_PROV_LLEGADA,''),
				@VPAGA_CONSULTOR	= ISNULL(PAGA_CONSULTOR,''),
				@VPAGA_CONSULTORA	= ISNULL(PAGA_CONSULTORA,''),
				@VRENDICION_CLIENTE	= ISNULL(RENDICION_CLIENTE,''),
				@VDET_PROV_LOCAL	= ISNULL(DET_PROV_LOCAL,''),
				@VDET_PROV_FINGRESO = ISNULL(DET_PROV_FINGRESO,''),
				@VDET_PROV_FEGRESO	= ISNULL(DET_PROV_FEGRESO,''),
				@VDET_PROV_FPARTIDA = ISNULL(DET_PROV_FPARTIDA,''),
				@VDET_PROV_FLLEGADA = ISNULL(DET_PROV_FLLEGADA,''),
				@VDET_PROV_KMS		= ISNULL(DET_PROV_KMS,''),
				@VDET_PROV_PEAJES	= ISNULL(DET_PROV_PEAJES,'')
		FROM	LK_PROYECTO_VIATICOS_DET
		WHERE	ID_PROYECTO_VIATICOS_DET = @VID_SELEC
 
	END
 
	IF (@VID_SELEC <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_DET_PROV_RESERVA	= @VDET_PROV_RESERVA
		SET @VTMT_DET_PROV_VUELO	= @VDET_PROV_VUELO
		SET @VTMT_DET_PROV_ORIGEN	= @VDET_PROV_ORIGEN
		SET @VTMT_DET_PROV_DESTINO	= @VDET_PROV_DESTINO
		SET @VTMT_DET_PROV_FECHA	= @VDET_PROV_FECHA
		SET @VTMT_DET_PROV_SALIDA	= @VDET_PROV_SALIDA
		SET @VTMT_DET_PROV_LLEGADA	= @VDET_PROV_LLEGADA
		SET @VTMT_PAGA_CONSULTOR	= @VPAGA_CONSULTOR
		SET @VTMT_PAGA_CONSULTORA	= @VPAGA_CONSULTORA
		SET @VTMT_RENDICION_CLIENTE	= @VRENDICION_CLIENTE
		SET @VTMT_DET_PROV_LOCAL	= @VDET_PROV_LOCAL
		SET @VTMT_DET_PROV_FINGRESO	= @VDET_PROV_FINGRESO
		SET @VTMT_DET_PROV_FEGRESO	= @VDET_PROV_FEGRESO
		SET @VTMT_DET_PROV_FPARTIDA	= @VDET_PROV_FPARTIDA
		SET @VTMT_DET_PROV_FLLEGADA	= @VDET_PROV_FLLEGADA
		SET @VTMT_DET_PROV_KMS		= @VDET_PROV_KMS
		SET	@VTMT_DET_PROV_PEAJES	= @VDET_PROV_PEAJES
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-money-check-alt w3-large"></i>&nbsp;&nbsp;'+CASE WHEN @VID_SELEC <> '' THEN 'Modificar' ELSE 'Agregar' END+' Detalle Viático</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_SELEC <> '' THEN 'Modificar' ELSE 'Agregar' END+' Detalle Viático - '+ISNULL(@VTIPO_PROV,'')+'</b></span>
					<div class="w3-row w3-bottombar"></div>
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VRAZON_SOCIAL,'')+'</b>&nbsp;'+'
							<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+'</b>&nbsp;'+'
							<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN 
										'fas fa-user-tie"'
									WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN 
										'fas fa-chalkboard-teacher"'
									WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN 
										'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE,'')+' - '+ISNULL(@VLUGAR,'')+'</b>
						</span>
					</div>
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
						</span>
					</div>
					<div class="w3-panel w3-topbar"></div>'+
					CASE WHEN @VTIPO_PROV IN ('AVION','MICRO') THEN
						'<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-copyright"></i>&nbsp;&nbsp;Código Reseva</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_RESERVA" value="' + ISNULL(@VTMT_DET_PROV_RESERVA,'') + '">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FECHA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FECHA,23),'') END +'">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-plane"></i>&nbsp;&nbsp;Vuelo</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_VUELO" value="' + ISNULL(@VTMT_DET_PROV_VUELO,'') + '">
						</div>'
						WHEN @VTIPO_PROV = 'HOTEL' THEN 
						'<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-hotel"></i>&nbsp;&nbsp;Hotel</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIP_SERVICIO_PROV" value="' + ISNULL(@VTMT_DESC_PROV,'') + '" disabled>
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-city"></i>&nbsp;&nbsp;Ciudad</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_LOCAL" value="' + ISNULL(@VTMT_DET_PROV_LOCAL,'') + '">
						</div>'
						WHEN @VTIPO_PROV IN ('TAXI','REMIS') THEN
						'<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Origen</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_ORIGEN" value="' + ISNULL(@VTMT_DET_PROV_ORIGEN,'') + '">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Partida&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FPARTIDA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FPARTIDA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FPARTIDA,23),'') END +'">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-clock"></i>&nbsp;&nbsp;Hora Partida</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_SALIDA" value="' + ISNULL(@VTMT_DET_PROV_SALIDA,'') + '">
						</div>'
						WHEN @VTIPO_PROV = 'AUTO' THEN
						'<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FECHA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FECHA,23),'') END +'">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-car"></i>&nbsp;&nbsp;Kilómetros</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_KMS" value="' + ISNULL(@VTMT_DET_PROV_KMS,'') + '">
						</div>
						<div class="w3-third">
							<label><i class="fas fa-hand-holding-usd"></i>&nbsp;&nbsp;Peajes</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_PEAJES" value="' + ISNULL(@VTMT_DET_PROV_PEAJES,'') + '">
						</div>'
						WHEN @VTIPO_PROV = 'ALQUILER' THEN
						'<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Origen</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_ORIGEN" value="' + ISNULL(@VTMT_DET_PROV_ORIGEN,'') + '">
						</div>
						<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Desde&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FPARTIDA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FPARTIDA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FPARTIDA,23),'') END +'">
						</div>
						<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fas fa-map-marked"></i>&nbsp;&nbsp;Destino</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_DESTINO" value="' + ISNULL(@VTMT_DET_PROV_DESTINO,'') + '">
						</div>
						<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FLLEGADA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FLLEGADA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FLLEGADA,23),'') END +'">
						</div>'
					ELSE '' END + '
					<div>
						&nbsp;
					</div>'+
					CASE WHEN @VTIPO_PROV IN ('AVION','MICRO') THEN
						'<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Origen</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_ORIGEN" value="' + ISNULL(@VTMT_DET_PROV_ORIGEN,'') + '">
						</div>
						<div class="w3-quarter">
							<label><i class="fas fa-map-marked"></i>&nbsp;&nbsp;Destino</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_DESTINO" value="' + ISNULL(@VTMT_DET_PROV_DESTINO,'') + '">
						</div>
						<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fas fa-clock"></i>&nbsp;&nbsp;Hora Salida</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_SALIDA" value="' + ISNULL(@VTMT_DET_PROV_SALIDA,'') + '">
						</div>
						<div class="w3-quarter">
							<label class="w3-muhle-text-14"><i class="fas fa-clock"></i>&nbsp;&nbsp;Hora LLegada</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_LLEGADA" value="' + ISNULL(@VTMT_DET_PROV_LLEGADA,'') + '">
						</div>'
						WHEN @VTIPO_PROV = 'HOTEL' THEN 
						'<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Ingreso&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FINGRESO" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FINGRESO,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FINGRESO,23),'') END +'">
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Egreso&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FEGRESO" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FEGRESO,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FEGRESO,23),'') END +'">
						</div>'
						WHEN @VTIPO_PROV IN ('TAXI','REMIS') THEN
						'<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-map-marked"></i>&nbsp;&nbsp;Destino</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_DESTINO" value="' + ISNULL(@VTMT_DET_PROV_DESTINO,'') + '">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Llegada&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.DET_PROV_FLLEGADA" value="'+CASE WHEN ISNULL(@VTMT_DET_PROV_FLLEGADA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_DET_PROV_FLLEGADA,23),'') END +'">
						</div>
						<div class="w3-third">
							<label class="w3-muhle-text-14"><i class="fas fa-clock"></i>&nbsp;&nbsp;Hora Llegada</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DET_PROV_LLEGADA" value="' + ISNULL(@VTMT_DET_PROV_LLEGADA,'') + '">
						</div>'
					ELSE '' END + CASE WHEN @VTIPO_PROV NOT IN ('AUTO','ALQUILER') THEN '
					<div>
						&nbsp;
					</div>' ELSE '' END + '
					<div class="w3-third">
						<label class="w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;Paga Consultor</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.PAGA_CONSULTOR"></select>
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14"><i class="fas fa-users"></i>&nbsp;&nbsp;Paga Consultora</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.PAGA_CONSULTORA"></select>
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14"><i class="fas fa-user-edit"></i>&nbsp;&nbsp;Rendición Cliente</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.RENDICION_CLIENTE"></select>
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-panel w3-bottombar"></div>'
 
	SET @OFOOTER =	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Grabar' END+'</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VTMT_PAGA_CONSULTOR,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VTMT_PAGA_CONSULTORA,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VTMT_RENDICION_CLIENTE,'') +''', '''');</script>'
END
