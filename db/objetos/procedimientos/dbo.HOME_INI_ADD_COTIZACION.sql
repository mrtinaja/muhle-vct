CREATE PROCEDURE [dbo].[HOME_INI_ADD_COTIZACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OADJUNTAR AS VARCHAR(400) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
DECLARE @UNITDESC			VARCHAR(300),
		@USERDESC			VARCHAR(300),
		@VERROR				VARCHAR(50),
		@VDESC_ERROR		VARCHAR(400),
		@VCLAVE_ADJ			VARCHAR(100),
		@VID_SELEC			VARCHAR(100)
 
DECLARE @VTMT_CLIENTE		VARCHAR(100),
		@VTMT_NRO_COTI		VARCHAR(50),
		@VTMT_ESTADO		VARCHAR(50),
		@VTMT_FECHA			DATETIME
 
DECLARE @VCLIENTE			VARCHAR(100),
		@VNRO_COTI			VARCHAR(50),
		@VESTADO			VARCHAR(50),
		@VFECHA				DATETIME
 
BEGIN	
	
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VID_SELEC		= ISNULL(CLAVE_COTIZA,''),
			@VTMT_CLIENTE	= ISNULL(CLIENTE,''),
			@VTMT_NRO_COTI	= ISNULL(NRO_COTIZA,''),
			@VTMT_ESTADO	= ISNULL(ESTADO_COTIZA,''),
			@VTMT_FECHA		= NULLIF(ISNULL(FECHA_COTIZA,''),'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_SELEC <> '') BEGIN
		
		SELECT	@VCLIENTE	= ISNULL(ID_CLIENTE,''),
				@VNRO_COTI	= ISNULL(NRO_COTIZACION,''),
				@VESTADO	= ISNULL(ESTADO_COTIZACION,''),
				@VFECHA		= ISNULL(FECHA_COTIZACION,'')
		FROM	LK_COTIZACIONES
		WHERE	ID_COTIZACION = @VID_SELEC
 
	END
 
	IF (@VID_SELEC <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_CLIENTE	= @VCLIENTE
		SET @VTMT_NRO_COTI	= @VNRO_COTI
		SET @VTMT_ESTADO	= @VESTADO
		SET @VTMT_FECHA		= @VFECHA
 
	END
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		NRO_COTIZA = NULL,
				CLIENTE = NULL,
				FECHA_COTIZA = NULL,
				ESTADO_COTIZA = NULL,
				ERROR = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
	
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-bar w3-large"></i>&nbsp;&nbsp;Propuestas</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '			
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Modificar' END+' Propuesta</b></span>
					<div class="w3-panel w3-bottombar"></div>
					<div class="w3-twothird">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Cliente&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1_'+@FORM_ID+'" name="SP.CLIENTE"></select>
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-list-ol"></i>&nbsp;&nbsp;Nro Cotización&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" name="SP.NRO_COTIZA" type="text" value="'+@VTMT_NRO_COTI+ '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_COTIZA" value="'+CASE WHEN ISNULL(@VTMT_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA,23),'') END +'">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.ESTADO_COTIZA"></select>	
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-card">
						   <div class="w3-col w3-container w3-muhle-text-14 w3-muhle-color">
							<p>
							<span><b>Adjuntar Propuesta</b></span>
							</p>
							</div>
						   <input class=""w3-input w3-border"" id="'+@FORM_ID+'_fileupload" type="file" name="files[]">
	
						<div id="progressdiv" class="w3-light-grey" style="display: none;">
							<div id="progressbar" class="w3-container w3-green w3-center" style="width: 0%">0%</div>
						</div>
		
						<div id="'+@FORM_ID+'_attached_files"></div>
						<script>initAttachFiles(''' + @FORM_ID + ''',''' + isnull(@IPKEYJOB,'') + ''')</script>
					</div>
					<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>'
	
	SET @OFOOTER =	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Grabar' END +'</btn>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');return false;">Cancelar</btn>
					</div>
				</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_CLIENTES'', '''+isnull(@VTMT_CLIENTE,'')+''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + 'B1E36376-EF9E-48D4-88C0-0F3F8FBB4CCE' + ''', ''' + ISNULL(@VTMT_ESTADO,'') +''', '''');</script>'
 
END
