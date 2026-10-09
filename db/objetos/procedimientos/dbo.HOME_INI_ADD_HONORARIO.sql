CREATE PROCEDURE [dbo].[HOME_INI_ADD_HONORARIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VRAZON_SOCIAL		VARCHAR(400),
		@VNOMBRE_PROY		VARCHAR(400),
		@VTIPO_SERV			VARCHAR(50),
		@VNOMBRE			VARCHAR(400),
		@VLUGAR				VARCHAR(400),
		@VERROR				VARCHAR(50),
		@VDESC_ERROR		VARCHAR(4000),
		@VID_SELEC			VARCHAR(100),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
DECLARE @VTMT_HONOR_FECHA	DATETIME,
		@VTMT_HONOR_LUGAR	VARCHAR(400),
		@VTMT_HONOR_CONSULTOR VARCHAR(100),
		@VTMT_HONOR_IMPORTE	VARCHAR(100)
 
DECLARE @VHONOR_FECHA		DATETIME,
		@VHONOR_LUGAR		VARCHAR(400),
		@VHONOR_CONSULTOR	VARCHAR(100),
		@VHONOR_IMPORTE		VARCHAR(100)
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(100),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VESTADO	VARCHAR(100),
		@VARNORMA	VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VTIPO			VARCHAR(50),
		@VCANT_HR		INT,
		@VSTATUS		VARCHAR(50),
		@VPROYECTO_SERV	VARCHAR(50),
		@VHORAS			VARCHAR(50)
 
BEGIN	
 
	SELECT	@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VID_SELEC		= ISNULL(HOJA_RUTA_ID,''),
			@VTMT_HONOR_FECHA = ISNULL(HONOR_FECHA,''),
			@VTMT_HONOR_LUGAR = ISNULL(HONOR_LUGAR,''),
			@VTMT_HONOR_CONSULTOR = ISNULL(HONOR_CONSULTOR,''),
			@VTMT_HONOR_IMPORTE = ISNULL(HONOR_IMPORTE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO,
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
	WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
	SELECT	@VDIAS_AGENDA = DIAS,
			@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END
	FROM	LK_AGENDA A
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_SELEC <> '') BEGIN
		
		SELECT	@VHONOR_FECHA		= ISNULL(FECHA,''),
				@VHONOR_LUGAR		= ISNULL(LUGAR,''),
				@VHONOR_CONSULTOR	= ISNULL(ID_CONSULTOR,''),
				@VHONOR_IMPORTE		= ISNULL(IMPORTE,'')
		FROM	LK_PROYECTO_HONORARIOS
		WHERE	ID_PROYECTO_HONORARIOS = @VID_SELEC
 
	END
 
	IF (@VID_SELEC <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_HONOR_FECHA		= @VHONOR_FECHA
		SET @VTMT_HONOR_LUGAR		= @VHONOR_LUGAR
		SET @VTMT_HONOR_CONSULTOR	= @VHONOR_CONSULTOR
		SET @VTMT_HONOR_IMPORTE		= @VHONOR_IMPORTE
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-hand-holding-usd w3-large"></i>&nbsp;&nbsp;Honorarios</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Modificar' END+' Honorario</b></span>
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
					<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.HONOR_FECHA" value="'+CASE WHEN ISNULL(@VTMT_HONOR_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_HONOR_FECHA,23),'') END +'">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14"><i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Lugar</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.HONOR_LUGAR" value="' + ISNULL(@VTMT_HONOR_LUGAR,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;Consultor&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.HONOR_CONSULTOR"></select>
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Importe</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.HONOR_IMPORTE" value="' + ISNULL(@VTMT_HONOR_IMPORTE,'') + '">
					</div>
					<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>'
 
	SET @OFOOTER = CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Grabar' END+'</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '8C9377AF-4074-42E0-B353-BCC33DB04051' + ''', ''' + ISNULL(@VTMT_HONOR_CONSULTOR,'') +''', '''');</script>'
 
END
