CREATE PROCEDURE [dbo].[HOME_INICIA_SERVICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VERROR			VARCHAR(50),
		@VDESC_ERROR	VARCHAR(4000),
		@lnuPosComa		INT,
		@lstDato		VARCHAR(400)
 
/*DATOS FORMULARIO*/
DECLARE @VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VRAZON_SOCIAL		VARCHAR(400),
		@VNOMBRE_PROY		VARCHAR(400),
		@VEXISTE			INT
 
DECLARE	@VNOMBRE_SERV		VARCHAR(400),
		@VLUGAR_SERV		VARCHAR(400),
		@VFECHA_INICIO_SERV	DATETIME,
		@VFECHA_FIN_SERV	DATETIME,
		@VHORAS_SERV		VARCHAR(100),	
		@VMONTO_SERV		VARCHAR(100),
		@VCIERRE_SERVICIO	VARCHAR(100),
		@VTIPO_SERVICIO		VARCHAR(100),
		@VOPTIONS_TIPO		VARCHAR(MAX)
 
BEGIN	
 
	/*RECUPERAR INFOMACION BUFFER*/
	SELECT	@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VID_SERVICIO = 'N') BEGIN
		UPDATE	XAGENDA
		SET		PROYECTO_SERV_ID = NULL,
				NOMBRE_SERV = NULL,
				LUGAR_SERV = NULL,
				FECHA_INICIO_SERV = NULL,
				FECHA_FIN_SERV = NULL,
				HORAS_SERV = NULL,
				MONTO_SERV = NULL,
				CIERRE_SERVICIO = NULL,
				TIPO_SERVICIO = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VTIPO_SERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VNOMBRE_SERV = ISNULL(NOMBRE_SERV,''),
			@VLUGAR_SERV = ISNULL(LUGAR_SERV,''),
			@VFECHA_INICIO_SERV = ISNULL(FECHA_INICIO_SERV,''),
			@VFECHA_FIN_SERV = ISNULL(FECHA_FIN_SERV,''),
			@VHORAS_SERV = ISNULL(HORAS_SERV,'0'),
			@VMONTO_SERV = ISNULL(MONTO_SERV,'0'),
			@VCIERRE_SERVICIO = ISNULL(CIERRE_SERVICIO,''),
			@VERROR				= ISNULL(ERROR,''),
			@VDESC_ERROR		= ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @VCIERRE_SERVICIO = 'NO'
 
	SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
 
		--VERIFICO SI EL PROYECTO TIENE EL SERVICIO DE CONSULTORIA O NO--
		SET @VEXISTE = 0
 
		SELECT	@VEXISTE = COUNT(1)
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
		AND		ID_TIPO_SERVICIO = '1'
 
		SET @VOPTIONS_TIPO = '
			<option value=""></option>
			<option value="2" '+CASE WHEN isnull(@VTIPO_SERVICIO,'') = '2' THEN 'selected="selected"' ELSE '' END+'>Auditoria</option>
			<option value="3" '+CASE WHEN isnull(@VTIPO_SERVICIO,'') = '3' THEN 'selected="selected"' ELSE '' END+'>Capacitacion</option>'+
			CASE WHEN @VEXISTE = 0 THEN
				'<option value="1" '+CASE WHEN isnull(@VTIPO_SERVICIO,'') = '1' THEN 'selected="selected"' ELSE '' END+'>Consultoria</option>'
			ELSE '' END
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-cogs w3-large"></i>&nbsp;&nbsp;Servicio</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '		
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Servicio</b></span>
					<div class="w3-row w3-bottombar"></div>
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;'+ISNULL(@VRAZON_SOCIAL,'')+' <b>-</b> '+'<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+'</span>
					</div>
					<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-id-badge"></i>&nbsp;&nbsp;Tipo Servicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.TIPO_SERVICIO">
							'+ISNULL(@VOPTIONS_TIPO,'')+'
						</select>
					</div>
					<div class="w3-quarter">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Inicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_INICIO_SERV" value="'+CASE WHEN ISNULL(@VFECHA_INICIO_SERV,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_INICIO_SERV,23),'') END +'">
					</div>
					<div class="w3-quarter">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Fin</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_FIN_SERV" value="'+CASE WHEN ISNULL(@VFECHA_FIN_SERV,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_FIN_SERV,23),'') END +'">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Nombre&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NOMBRE_SERV" value="' + ISNULL(@VNOMBRE_SERV,'') + '">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Lugar</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.LUGAR_SERV" value="' + ISNULL(@VLUGAR_SERV,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Horas Proyectadas&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.HORAS_SERV" value="' + ISNULL(@VHORAS_SERV,'') + '">
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Monto</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.MONTO_SERV" value="' + ISNULL(@VMONTO_SERV,'') + '">
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-window-close"></i>&nbsp;&nbsp;Cierre</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CIERRE_SERVICIO" value="' + ISNULL(@VCIERRE_SERVICIO,'') + '" disabled>
					</div>
					<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>'
 
	SET @OFOOTER =	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Agregar</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>'
	
END
 
