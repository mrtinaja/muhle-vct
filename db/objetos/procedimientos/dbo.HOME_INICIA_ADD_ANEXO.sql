CREATE PROCEDURE [dbo].[HOME_INICIA_ADD_ANEXO]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VCLAVE AS VARCHAR(100),
		@VDESCRIPCION VARCHAR(2000),
		@VTIPO_SERVICIO VARCHAR(50),
		@VSERVICIO VARCHAR(50),
		@VERROR VARCHAR(50),
		@VDESC_ERROR VARCHAR(400),
		@VCLIENTE	VARCHAR(100),
		@VPROYECTO VARCHAR(100),
		@VRAZON_SOCIAL VARCHAR(400),
		@VNOMBRE_PROY VARCHAR(400)
 
 
/*Strings segun el menu (ALTA-UPDATE)*/
DECLARE @VTITULO_PANTALLA VARCHAR(200)
DECLARE @VBOTON_ACCION VARCHAR(200)
 
BEGIN	
 
	SET @VDESCRIPCION = ''
	SET @VTIPO_SERVICIO = ''
	SET @VSERVICIO = ''
	SET @VCLAVE = ''
	
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VPROYECTO =	ISNULL(PROYECTO_ID,''),
			@VDESCRIPCION=ISNULL(AGENDA_OBSERVADOR,''),
			@VTIPO_SERVICIO = ISNULL(AGENDA_ESTADO,''),
			@VSERVICIO = ISNULL(AGENDA_DESC,''),
			@VCLAVE = ISNULL(TIPO_FERIADO,''),
			@VERROR = ERROR,
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	XAGENDA 
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
	FROM	LK_PROYECTO P
	WHERE	P.ID_CLIENTE = @VCLIENTE
	AND		P.ID_PROYECTO = @VPROYECTO
 
   IF( @VCLAVE = '') BEGIN 	
		SET @VTITULO_PANTALLA = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Anexo</b></span>'
		SET @VBOTON_ACCION = 'Agregar'
	END	ELSE BEGIN
		SET @VTITULO_PANTALLA = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Anexo</b></span>'
		SET @VBOTON_ACCION = 'Guardar'
		
		IF(ISNULL(@VDESC_ERROR,'') = '')BEGIN
			SELECT 
				@VDESCRIPCION = ISNULL(NRO_DOCUM_INTERNO,''),
				@VTIPO_SERVICIO = ISNULL(ID_TIPO_SERVICIO,''),
				@VSERVICIO = ISNULL(PROYECTO_SERV_ID,'')
			FROM	LK_PROYECTO_DOCUM 
			WHERE	ID_PROYECTO_DOCUM = @VCLAVE
 
			UPDATE	XAGENDA
			SET		AGENDA_ESTADO = @VTIPO_SERVICIO, AGENDA_DESC = @VSERVICIO, AGENDA_OBSERVADOR = @VDESCRIPCION
			WHERE	PAR_KEY = @IPKEYJOB
		END
	END
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white">
						<i class="fas fa-user"></i>&nbsp;&nbsp;'+ISNULL(@VRAZON_SOCIAL,'')+' - ' + '
						<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;' +ISNULL(@VNOMBRE_PROY,'') + '					
					</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
 
		<div class="w3-row-padding">'+
			CASE WHEN @VCLAVE = '' THEN 
				@VTITULO_PANTALLA
			ELSE
				@VTITULO_PANTALLA
			END + '
			<div class="w3-row w3-bottombar"></div>
			<div>&nbsp;</div>
			<div class="w3-col m6 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Tipo Servicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-round w3-muhle-text-14" id="cmb1" name="SP.AGENDA_ESTADO" onchange="goto('''+@FORM_ID+''',''3049C791-DD77-42F0-B8E6-7E9A8AAEA86D'');return false;" '+CASE WHEN @VCLAVE = '' THEN '' ELSE 'disabled' END+'></select>
			</div>
			<div class="w3-col m6 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-cogs"></i>&nbsp;&nbsp;Servicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-round w3-muhle-text-14" id="cmb2" name="SP.AGENDA_DESC" '+CASE WHEN @VCLAVE = '' THEN '' ELSE 'disabled' END+'></select>	
			</div>
			<div>&nbsp;</div>
			<div class="w3-col m12 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripción&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_OBSERVADOR" value="' + ISNULL(@VDESCRIPCION,'') + '">
			</div>
		</div>
	<div class="w3-row w3-topbar">'+
	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
		''
	ELSE 
		'<div class="w3-panel w3-pale-red" style="height: 20px;">
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>'+isnull(@VDESC_ERROR,'')+'</b></font>
			</div>' 
	END + '
	</div>'
	
	SET @OFOOTER = '
	<div class="w3-row">
		<div class="w3-container w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+@VBOTON_ACCION+'</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;">Cancelar</btn>
		</div>
	</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '388310AC-6010-4BEE-8B89-3D90D7C621E7' + ''', ''' + ISNULL(@VTIPO_SERVICIO,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + 'ECB9CBB2-0B32-4F04-965B-566A5431F2D7' + ''', ''' + ISNULL(@VSERVICIO,'') +''', '''');</script>'
 
END
 
