CREATE PROCEDURE [dbo].[HOME_INI_ADD_CHECHKLIST]
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
		@VID_SELEC			VARCHAR(100)
 
DECLARE	@VID				VARCHAR(50),
		@VSERVICIO			VARCHAR(50),
		@UNITDESC			VARCHAR(300),
		@USERDESC			VARCHAR(300),
		@VPROYECTO			VARCHAR(50),
		@VIDCLIENTE			VARCHAR(100),
		@VNORMA				VARCHAR(300),
		@VDIASP				VARCHAR(50),
		@VAGENDA_ID			VARCHAR(50),
		@VFECHAD			VARCHAR(50),
		@VFECHAH			VARCHAR(50),
		@VDIAS				VARCHAR(50),
		@VESTADO			VARCHAR(100),
		@VARNORMA			VARCHAR(400),
		@lstDato			VARCHAR(100), 
		@lnuPosComa			INT,
		@VALOR				VARCHAR(400),
		@VDESCNORMAS		VARCHAR(4000),
		@VCONSULTORES		VARCHAR(4000),
		@VTIPO				VARCHAR(50),
		@VCANT_HR			INT,
		@VSTATUS			VARCHAR(50),
		@VPROYECTO_SERV		VARCHAR(50)
 
DECLARE @VTMT_FECHA			DATETIME,
		@VTMT_CURSO			VARCHAR(400),
		@VTMT_NOMBRE_CL		VARCHAR(400),
		@VTMT_ASISTENTE		VARCHAR(100),
		@VTMT_OBSERVACION	VARCHAR(400)
 
DECLARE @VFECHA				DATETIME,
		@VCURSO				VARCHAR(400),
		@VNOMBRE_CL			VARCHAR(400),
		@VASISTENTE			VARCHAR(100),
		@VOBSERVACION		VARCHAR(400)
 
BEGIN	
 
	SELECT	@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VID_SELEC		= ISNULL(HOJA_RUTA_ID,''),
			@VTMT_FECHA		= ISNULL(FECHA_CLC,''),
			@VTMT_NOMBRE_CL = ISNULL(NOMBRE_CLC,''),
			@VTMT_ASISTENTE = ISNULL(ASISTENTES_CLC,''),
			@VTMT_CURSO = ISNULL(CURSO_CLC,''),
			@VTMT_OBSERVACION = ISNULL(OBSERVACION_HR,'')
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
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_SELEC <> '') BEGIN
		
		SELECT	@VFECHA = FECHA_DOCUM,
				@VNOMBRE_CL = NRO_DOCUM_INTERNO,
				@VCURSO = TEMAS_DOCUM,
				@VASISTENTE = PARTICIPANTES_DOCUM,
				@VOBSERVACION = OBSERVACIONES
		FROM	LK_PROYECTO_DOCUM 
		WHERE	ID_PROYECTO_DOCUM = @VID_SELEC
 
	END
 
	IF (@VID_SELEC <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_FECHA		= @VFECHA
		SET @VTMT_NOMBRE_CL	= @VNOMBRE_CL
		SET @VTMT_ASISTENTE	= @VASISTENTE
		SET @VTMT_CURSO		= @VCURSO
		SET @VTMT_OBSERVACION = @VOBSERVACION
	END
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		FECHA_CLC = NULL,
				OBSERVACION_HR = NULL,
				NOMBRE_CLC = NULL,
				CURSO_CLC = NULL,
				ASISTENTES_CLC = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-tasks w3-large"></i>&nbsp;&nbsp;CheckList</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Modificar' END+' CheckList</b></span>
					<div class="w3-row w3-bottombar"></div>
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-user"></i>&nbsp;&nbsp;'+ISNULL(@VRAZON_SOCIAL,'')+' <b>-</b> '+'
							<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+' <b>-</b> '+'
							<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN 
										'fas fa-user-tie"'
									WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN 
										'fas fa-chalkboard-teacher"'
									WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN 
										'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;' +ISNULL(@VNOMBRE,'')+' - '+ISNULL(@VLUGAR,'')+'
						</span>
					</div>
					<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_CLC" value="'+CASE WHEN ISNULL(@VTMT_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA,23),'') END +'">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-certificate"></i>&nbsp;&nbsp;Curso</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CURSO_CLC" value="' + ISNULL(@VTMT_CURSO,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-signature"></i>&nbsp;&nbsp;Nombre</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NOMBRE_CLC" value="' + ISNULL(@VTMT_NOMBRE_CL,'') + '">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Asistentes</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.ASISTENTES_CLC" value="' + ISNULL(@VTMT_ASISTENTE,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div>
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.OBSERVACION_HR" value="'+ISNULL(@VTMT_OBSERVACION,'')+'">
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
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>'
 
END
 
