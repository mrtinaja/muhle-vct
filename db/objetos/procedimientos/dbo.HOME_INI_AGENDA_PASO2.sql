CREATE PROCEDURE [dbo].[HOME_INI_AGENDA_PASO2]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX)	OUTPUT,
 @OPASOS	AS VARCHAR(MAX)	OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE	@VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VID_AGENDA			VARCHAR(100),
		@VNOMBRE_CLIENTE	VARCHAR(MAX),
		@VNOMBRE_PROY		VARCHAR(MAX),
		@VNOMBRE_SERV_SELEC	VARCHAR(MAX),
		@VLUGAR_SERV_SELEC	VARCHAR(MAX),
		@VTIPO_SERV_SELEC	VARCHAR(MAX),
		@VFECHA_DESDE		DATETIME,
		@VFECHA_HASTA		DATETIME,
		@VFDESDE_AGENDA		DATETIME,
		@VFHASTA_AGENDA		DATETIME,
		@VDESC_ERROR		VARCHAR(4000),
		@VSTRUCTURE			VARCHAR(100)
		
BEGIN
	
	--VUELVE AL PASO 1 DEL ALTA--
	SET @VSTRUCTURE = '02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'
 
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA		= ISNULL(AGENDA_ID,''),
			@VFECHA_DESDE	= ISNULL(AGENDA_DESDE,''),
			@VFECHA_HASTA	= ISNULL(AGENDA_HASTA,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	--SI MODIFICA AGENDA, RECUPERO FECHA_DESDE Y FECHA_HASTA DE LA AGENDA--
	IF (@VID_AGENDA <> '') BEGIN
		
		--VUELVE A LA V360--
		SET @VSTRUCTURE = '40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'
 
		SELECT	@VFDESDE_AGENDA = FECHA,
				@VFHASTA_AGENDA = FECHA_HASTA
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VID_AGENDA
 
		IF (ISNULL(@VDESC_ERROR,'') = '') BEGIN
			SET @VFECHA_DESDE = @VFDESDE_AGENDA
			SET	@VFECHA_HASTA = @VFHASTA_AGENDA
		END
	END
 
	SELECT	@VNOMBRE_CLIENTE = ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	IF (@VID_SERVICIO <> '') BEGIN
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="'+CASE WHEN @VID_AGENDA <> '' THEN 'fas fa-edit' ELSE 'fas fa-calendar-plus' END+ ' w3-large"></i>&nbsp;&nbsp;'+CASE WHEN @VID_AGENDA <> '' THEN 'Modificar' ELSE 'Agregar' END + ' Visita</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
			<div class="w3-row-padding">
				<span class="w3-bar-item w3-left w3-padding w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VNOMBRE_CLIENTE,'')+'</b></span>
				<span class="w3-bar-item w3-right w3-padding w3-muhle-text-14"> 
						<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
											'fas fa-user-tie"'
										WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
											'fas fa-chalkboard-teacher"'
										WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
											'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' + ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,'')+'</b></span>
				<span class="w3-bar-item w3-right w3-padding w3-muhle-text-14"><i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(@VNOMBRE_PROY,'')+'&nbsp;&nbsp;</b></span>
				<div class="w3-row w3-bottombar"></div>'
 
	SET @OPASOS = '
	<ul class="progress-indicator">
        <li class="completed">
            <span class="bubble"></span>
            <i class="fas fa-calendar-day w3-large"></i><br>
            1. SELECCIONAR FECHA DESDE
        </li>
		<li class="completed">
            <span class="bubble"></span>
            <i class="fas fa-calendar-day w3-large"></i><br>
            2. SELECCIONAR FECHA HASTA
        </li>
        <li class="">
            <span class="bubble"></span>
            <i class="fas fa-users w3-large"></i><br>
            3. SELECCIONAR CONSULTORES
        </li>
		<li class="">
            <span class="bubble"></span>
            <i class="fas fa-clock w3-large"></i><br>
            4. CARGA HORARIO
        </li>
        <li>
            <span class="bubble"></span>
            <i class="fas fa-check-circle w3-large"></i><br>
            5. CONFIRMAR
        </li>
    </ul>
	<div class="w3-row w3-bottombar"></div>
	<div class="w3-container" style="padding:4px;"></div>'
 
	SET @OFORMULARIO = '
					<div class="w3-row-padding" style="display: flex;justify-content: center;flex-wrap: wrap;">
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-day"></i>&nbsp;&nbsp;Fecha Desde&nbsp;&nbsp;'+CASE WHEN @VID_AGENDA <> '' THEN '<i class="fas fa-exclamation-circle w3-text-red"></i>' ELSE '' END+'</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14 w3-center" type="date" name="SP.AGENDA_DESDE" value="' + CASE WHEN ISNULL(@VFECHA_DESDE,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_DESDE,23) END + '" '+CASE WHEN @VID_AGENDA <> '' THEN '' ELSE 'disabled' END +'>
						</div>
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-day"></i>&nbsp;&nbsp;Fecha Hasta&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14 w3-center" type="date" name="SP.AGENDA_HASTA" value="' + CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_HASTA,23) END + '">
						</div>
					</div>'+
				CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
					'<div>&nbsp;</div>'
				ELSE 
					'<div class="w3-panel w3-pale-red" style="height: 20px;">
						<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
					 </div>' 
				END + '
				<div class="w3-row w3-topbar">&nbsp;</div>
				<div class="w3-row">
					<div class="w3-container">
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Siguiente</btn>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;">'+CASE WHEN @VID_AGENDA <> '' THEN 'Volver' ELSE 'Anterior' END+ '</btn>
					</div>
				</div>
			</div>
		</div>
	</div>'
	
	UPDATE	XAGENDA
	SET		ALERTA_CALIF = NULL,
			AGENDA_CONSULTORES = NULL,
			DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
 
END
