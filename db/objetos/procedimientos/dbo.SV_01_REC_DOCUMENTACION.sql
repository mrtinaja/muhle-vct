CREATE   PROCEDURE [dbo].[SV_01_REC_DOCUMENTACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @VCLAVE		VARCHAR(100),
		@VDOC_CODE	VARCHAR(50),
		@VDOC_DESC	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VCOMENT	VARCHAR(400),
		@VERROR		VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VDETALLE	VARCHAR(50),
		@VDESC_ERROR VARCHAR(4000)
 
BEGIN	
	
	SELECT	@VCLAVE = ISNULL(CLAVE_DOC,''),
			@VERROR = ISNULL(ERROR,'')--,
			--@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	--RECUPERO CAMPOS DE LK_TIPO_SERVICIOS--
	IF (@VERROR <> 'SI') BEGIN
		SELECT	@VDOC_CODE = ISNULL(CODE_DOCUMENTACION,''),
				@VDOC_DESC	= ISNULL(DESC_DOCUMENTACION,''),
				@VCOMENT = ISNULL(COMENT_DOCUMENTACION,''),
				@VESTADO = ISNULL(STATUS_DOCUMENTACION,''),
				@VDETALLE = DETALLE_DOCUMENTACION
		FROM	LK_DOCUMENTACION
		WHERE	ID_DOCUMENTACION = @VCLAVE
 
		UPDATE	TMT_SV_01
		SET		CODIGO_DOC = @VDOC_CODE,
				DESCRIPCION_DOC = @VDOC_DESC,
				COMENTARIO_DOC = @VCOMENT,
				DETALLE_DOC = @VDETALLE,
				ESTADO_DOC = @VESTADO
		WHERE	PAR_KEY = @IPKEYJOB
	END
	ELSE BEGIN
		SELECT	@VDOC_CODE = ISNULL(CODIGO_DOC,''),
				@VDOC_DESC	= ISNULL(DESCRIPCION_DOC,''),
				@VCOMENT = ISNULL(COMENTARIO_DOC,''),
				@VESTADO = ISNULL(ESTADO_DOC,''),
				@VDETALLE = DETALLE_DOC
		FROM	TMT_SV_01
		WHERE	CLAVE_DOC = @VCLAVE
	END
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-address-book fa-fw w3-large"></i>&nbsp;&nbsp;Editar Documentación</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
	
	SET @OFORMULARIO = '		
		<div class="w3-row-padding">
			<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Documentación</b></span>
			<div class="w3-panel w3-bottombar"></div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-copyright"></i>&nbsp;&nbsp;Código&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CODIGO_DOC" value="'+@VDOC_CODE+'" disabled>
			</div>
			<div class="w3-col m8 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Descripción&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIPCION_DOC" value="'+@VDOC_DESC+'">
			</div>
			<div>
				&nbsp;
			</div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.ESTADO_DOC"></select>		
			</div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fa fa-search"></i>&nbsp;&nbsp;Detalle&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.DETALLE_DOC"></select>
			</div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-edit"></i>&nbsp;&nbsp;Comentario</label>
				<input type="text" class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" name="SP.COMENTARIO_DOC" value='+@VCOMENT+' maxlength="400" rows="5" cols="50">
			</div>
		</div>
		<div>&nbsp;</div>
		<div class="w3-row w3-topbar"></div>'
 
	SET @OFOOTER =	'
	<div class="w3-row">
		<div class="w3-container w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Grabar</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');return false;">Cancelar</btn>
		</div>
	</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '78FF2D5A-0B70-4854-A931-6D7F026748EA' + ''', ''' + ISNULL(''+@VESTADO+'','') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '0000000004_98' + ''', ''' + ISNULL(''+@VDETALLE+'','') +''', '''');</script>'
 
END
 
