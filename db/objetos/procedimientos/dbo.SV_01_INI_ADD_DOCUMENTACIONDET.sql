CREATE PROCEDURE [dbo].[SV_01_INI_ADD_DOCUMENTACIONDET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VCLAVE_DOC VARCHAR(100),
		@VCODIGO_DOC	VARCHAR(50),
		@VDESC_DOC		VARCHAR(300),
		@VFECHA_DOC		VARCHAR(50),
		@VDETALLE_DOC	VARCHAR(50)
	
DECLARE	@VCLAVE_DET VARCHAR(50),
		@VDESC_DET VARCHAR(200),
		@VESTADO_DET VARCHAR(50),
		@VGRUPO_DET VARCHAR(50),
		@VORDEN_DET VARCHAR(50),
		@VCOMENTARIO_DET VARCHAR(200),
		@VOBLIGATORIO_DET VARCHAR(50),
		@VDATO_DET VARCHAR(50),
		@VCAMPO_DET VARCHAR(50),
		@VEXPORTA_DET VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VDESC_ERROR VARCHAR(4000)
 
DECLARE @VHTML_TITTLE VARCHAR(200)
DECLARE @VHTML_BUTTON VARCHAR(200)
 
BEGIN	
 
	SELECT	@VCLAVE_DOC = CLAVE_DOC,
			@VCLAVE_DET = ISNULL(CLAVE_DETALLE,''),
			@VERROR = ISNULL(ERROR,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	/*Inicializamos campos*/
	SET @VDESC_DET = ''
	SET	@VORDEN_DET = ''
	SET @VESTADO_DET = ''
	SET @VGRUPO_DET = ''
	SET @VOBLIGATORIO_DET = ''
	SET @VDATO_DET = ''
	SET @VCAMPO_DET = ''
	SET	@VEXPORTA_DET = ''
	
	SELECT	@VCODIGO_DOC = CODE_DOCUMENTACION,
			@VDESC_DOC = DESC_DOCUMENTACION,
			@VFECHA_DOC= CONVERT(VARCHAR,FECHA_ALTA,103) ,
			@VDETALLE_DOC = DETALLE_DOCUMENTACION
	FROM	LK_DOCUMENTACION
	WHERE	ID_DOCUMENTACION = @VCLAVE_DOC	
 
	IF( @VCLAVE_DET = '') BEGIN 	
		SET @VHTML_TITTLE = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Detalle</b></span>'
		SET @VHTML_BUTTON = 'Agregar'
	END	ELSE BEGIN
		SET @VHTML_TITTLE = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Detalle</b></span>'
		SET @VHTML_BUTTON = 'Guardar'	
	END
 
	/*Alta primera entrada*/
	--IF (@VCLAVE_DET = '' AND @VERROR <> 'SI') BEGIN
	--	/*Limpio el buffer*/
	--	UPDATE	TMT_SV_01
	--	SET		DESCRIPCION_DET = NULL,
	--			ESTADO_DET = NULL,
	--			COMENTARIO_DET = NULL,
	--			GRUPO_DET = NULL,
	--			ORDEN = NULL,
	--			CLAVE_DETALLE = NULL,
	--			OBLIGATORIO = NULL,
	--			DATO = NULL,
	--			CAMPO = NULL
	--	WHERE	PAR_KEY = @IPKEYJOB
	--END
	--ELSE
	
	--MODIFICA DETALLE--
	IF(@VCLAVE_DET <> '' ) BEGIN
		/*Update primera entrada*/
		IF (@VERROR = 'NO') BEGIN
			SELECT @VDESC_DET = ISNULL(DESC_DOC_DET,''),
				   @VESTADO_DET = ISNULL(STATUS_DOC_DET,''),
				   @VORDEN_DET = ISNULL(CONVERT(VARCHAR,ORDEN),''),
				   @VGRUPO_DET = ISNULL(GRUPO_DOC_DET,''),
				   @VCOMENTARIO_DET = ISNULL(COMENT_DOC_DET,''),
				   @VOBLIGATORIO_DET = ISNULL(OBLIGATORIO_DET,''),
				   @VDATO_DET = ISNULL(DATO_DET,''),
				   @VCAMPO_DET = ISNULL(CAMPO_DET,''),
				   @VEXPORTA_DET = ISNULL(EXPORTA_DET,'')
			FROM LK_DOCUMENTACION_DET WHERE ID_DOCUMENTACION_DET = @VCLAVE_DET
			
			UPDATE	TMT_SV_01 SET DATO = @VDATO_DET WHERE PAR_KEY = @IPKEYJOB
 
		--REFRESH O GRABA CON ERROR--
		END ELSE BEGIN
			
			SELECT @VDESC_DET = ISNULL(DESCRIPCION_DET,''),
				   @VESTADO_DET = ISNULL(ESTADO_DET,''),
				   @VORDEN_DET = ISNULL(CONVERT(VARCHAR,ORDEN),''),
				   @VGRUPO_DET = ISNULL(GRUPO_DET,''),
				   @VCOMENTARIO_DET = ISNULL(COMENTARIO_DET,''),
				   @VOBLIGATORIO_DET = ISNULL(OBLIGATORIO,''),
				   @VDATO_DET = ISNULL(DATO,''),
				   @VCAMPO_DET = ISNULL(CAMPO,''),
				   @VEXPORTA_DET = ISNULL(EXPORTA,'')
			FROM TMT_SV_01 WHERE PAR_KEY = @IPKEYJOB
		END
	END
 
	--AGREGA DETALLE
	IF(@VCLAVE_DET = '') BEGIN
		SELECT @VDESC_DET = ISNULL(DESCRIPCION_DET,''),
			   @VESTADO_DET = ISNULL(ESTADO_DET,''),
			   @VORDEN_DET = ISNULL(CONVERT(VARCHAR,ORDEN),''),
			   @VGRUPO_DET = ISNULL(GRUPO_DET,''),
			   @VCOMENTARIO_DET = ISNULL(COMENTARIO_DET,''),
			   @VOBLIGATORIO_DET = ISNULL(OBLIGATORIO,''),
			   @VDATO_DET = ISNULL(DATO,''),
			   @VCAMPO_DET = ISNULL(CAMPO,''),
			   @VEXPORTA_DET = ISNULL(EXPORTA,'')
		FROM TMT_SV_01 WHERE PAR_KEY = @IPKEYJOB
	END
 
	--SELECT * FROM LK_DOCUMENTACION_DET
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-address-book fa-fw w3-large"></i>&nbsp;&nbsp;Detalle Documentación</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''4B0F1063-4306-45F1-8C86-E41A88987F90'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-container" style="padding:2px;"></div>
	<div class="w3-container">
		<table class="w3-table-all">
			<thead>
				<tr class="w3-light-grey w3-muhle-text-12">
					<th><b>Codigo</b></th>
					<th><b>Documentacion</b></th>
					<th><b>Fecha Alta</b></th>
					<th><b>Detalle</b></th>
				</tr>
			</thead>
			<tr class="w3-grey w3-muhle-text-12">' +
				'<td>'+@VCODIGO_DOC+'</td>'+
				'<td>'+@VDESC_DOC+'</td>'+
				'<td>'+@VFECHA_DOC+'</td>'+
				'<td>'+@VDETALLE_DOC+'</td>
			</tr>
		</table>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	--SET @OHEADER = '
	--<div class="w3-row w3-back w3-light-grey">
	--	<div class="w3-col w3-padding-large">
	--		<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--			<div class="w3-bar w3-round-up">
	--				<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-address-book w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Detalle Documentación</span>
	--				<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''4B0F1063-4306-45F1-8C86-E41A88987F90'');return false;"></i></span>
	--			</div>
	--		</div>
	--	</div>
	--</div>
	--<div class="w3-container" style="padding:4px;"></div>
	--<div class="w3-container">
	--	<table class="w3-table-all">
	--		<thead>
	--			<tr class="w3-light-grey">
	--			<th><b>Codigo</b></th>
	--			<th><b>Documentacion</b></th>
	--			<th><b>Fecha Alta</b></th>
	--			<th><b>Detalle</b></th>
	--			</tr>
	--		</thead>
	--		<tr class="w3-grey">' +
	--		  '<td>'+@VCODIGO_DOC+'</td>'+
	--		  '<td>'+@VDESC_DOC+'</td>'+
	--		  '<td>'+@VFECHA_DOC+'</td>'+
	--		  '<td>'+@VDETALLE_DOC+'</td>
	--		</tr>
	--	</table>	
	--</div>
	--<div class="w3-container" style="padding:4px;"></div>'
 
	
	--<div class="w3-col w3-padding-large">
	--<div class="w3-card-4 w3-round">
	--<div class="w3-container w3-padding-16 w3-round" style="background-color:light-gray;">
	
				--<div class="w3-padding">
				--	<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-edit"></i>&nbsp;&nbsp;Comentario</label>
				--	<textarea class="w3-input w3-border w3-round w3-muhle-text-14" maxlength="4000" rows="5" cols="50" name="SP.COMENTARIO_DET">'+ISNULL(@VCOMENTARIO_DET,'')+'</textarea>	
				--</div>
 
	--SET @OFORMULARIO = '
	--		<div class="w3-row-padding">
	--			'+@VHTML_TITTLE+'
	--			<div class="w3-row w3-bottombar"></div>
	--			<div class="w3-half w3-padding">
	--				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Descripcion&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
	--				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIPCION_DET" value="' + @VDESC_DET + '">		
	--			</div>
	--			<div class="w3-half w3-padding">
	--				<label class="w3-muhle-text-14"><i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
	--				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.ESTADO_DET"></select>	
	--			</div>
	--			<div class="w3-half w3-padding">
	--				<label class="w3-muhle-text-14"><i class="fas fa-layer-group"></i>&nbsp;&nbsp;Grupo&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
	--				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.GRUPO_DET"></select>	
	--			</div>
	--			<div class="w3-half w3-padding">
	--				<label class="w3-muhle-text-14"><i class="fas fa-arrows-alt-v"></i>&nbsp;&nbsp;Orden</label>
	--				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number"  min="1" max="100" name="SP.ORDEN" value="'+ISNULL(@VORDEN_DET,'')+'">		
	--			</div>							
	--			<div class="w3-padding">
	--				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Contacto</label>
	--				<textarea class="w3-input w3-border w3-round w3-muhle-text-14" maxlength="4000" rows="5" cols="50" name="SP.CONTACTO">' + ISNULL(@VCOMENTARIO_DET,'') + '</textarea>
	--			</div>
	--			<div>&nbsp;</div>
	--		</div>
	--		<div class="w3-row w3-topbar">
	--			&nbsp;
	--		</div>'
 
	SET @OFORMULARIO = '
		<div class="w3-row-padding">'+
			CASE WHEN @VCLAVE_DET = '' THEN 
				--'<h4><b>Nuevo Cliente</b></h4>'
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Detalle</b></span>'
			ELSE
				--'<h4><b>Modificar Cliente</b></h4>'
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Detalle</b></span>'
			END + '
			<div class="w3-row w3-bottombar"></div>
			<div class="w3-col '+CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN 'm4' ELSE 'm6' END +' w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Descripcion&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIPCION_DET" value="' + @VDESC_DET + '">
			</div>
			<div class="w3-col '+CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN 'm4' ELSE 'm6' END +' w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.ESTADO_DET"></select>
			</div>'+
			CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN
			'<div class="w3-col m2 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Obligatorio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.OBLIGATORIO"></select>
			</div>
			<div class="w3-col m2 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-file-pdf"></i>&nbsp;&nbsp;Exporta&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" name="SP.EXPORTA">
					<option value=""></option>
					<option value="1" '+CASE WHEN isnull(@VEXPORTA_DET,'') = '1' THEN 'selected="selected"' ELSE '' END+'>Consultor</option>
					<option value="0|1" '+CASE WHEN isnull(@VEXPORTA_DET,'') = '0|1' THEN 'selected="selected"' ELSE '' END+'>Interno</option>					
				</select>
			</div>'
			ELSE '' END + '
			<div class="w3-col '+CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN 'm3' ELSE 'm6' END +' w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-layer-group"></i>&nbsp;&nbsp;Grupo&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.GRUPO_DET"></select>	
			</div>
			<div class="w3-col '+CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN 'm3' ELSE 'm6' END +' w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-arrows-alt-v"></i>&nbsp;&nbsp;Orden</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number" name="SP.ORDEN" value="' + ISNULL(@VORDEN_DET,'') + '">
			</div>'+
			CASE WHEN @VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex') THEN
			'<div class="w3-col m3 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Asociar Dato</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.DATO" onchange="almacenarSeleccion(''ERROR'','''');goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');return false;"></select>
			</div>
			<div class="w3-col m3 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Campo'+CASE WHEN ISNULL(@VDATO_DET,'') <> '' THEN '&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i>' ELSE '' END +'</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb5" name="SP.CAMPO"></select>
			</div>'
			ELSE '' END + '
			<div class="w3-col m12 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-edit"></i>&nbsp;&nbsp;Comentario</label>
				<textarea class="w3-input w3-border w3-round w3-muhle-text-14" maxlength="4000" rows="5" cols="50" name="SP.COMENTARIO_DET">' + ISNULL(@VCOMENTARIO_DET,'') + '</textarea>
			</div>
			<div>&nbsp;</div>
		</div>
	<div class="w3-row w3-topbar">'+
		CASE WHEN @VERROR = 'SI' AND @VDESC_ERROR <> '' THEN @VDESC_ERROR ELSE '&nbsp;' END + '
	</div>'
 
	SET @OFOOTER = '
	<div class="w3-row">
		<div class="w3-container w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+@VHTML_BUTTON+'</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''4B0F1063-4306-45F1-8C86-E41A88987F90'');return false;">Cancelar</btn>
		</div>
	</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '78FF2D5A-0B70-4854-A931-6D7F026748EA' + ''', ''' + ISNULL(@VESTADO_DET,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + 'B67C9BEF-0B34-4044-B438-F009ADA63F54' + ''', ''' + ISNULL(@VGRUPO_DET,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VOBLIGATORIO_DET,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + 'D1D4E88A-C0CE-47A7-B486-4D6C58B8ACB8' + ''', ''' + ISNULL(@VDATO_DET,'') +''', '''');</script>'+
	--CASE WHEN ISNULL(@VDATO_DET,'') <> '' THEN
	--	'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb5'', ''E37FEA72-2592-4EA2-B7A5-4922310118C5'', '''+isnull(@VCAMPO_DET,'')+''', '''+isnull(@VDATO_DET,'')+''');</script>' 
	--ELSE
		'<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb5'', ''' + 'E37FEA72-2592-4EA2-B7A5-4922310118C5' + ''', ''' + ISNULL(@VCAMPO_DET,'') +''', '''');</script>'
	--END + '
	+'<script>function MyFunction() {
		goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');
		}
	</script>'
 
END
 
