CREATE   PROCEDURE [dbo].[SV_01_INICIA_ADD_EMPLEADO_APT]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OFORMULARIO AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
DECLARE @VCLAVE AS VARCHAR(100),
		@VERROR AS VARCHAR(100),
		@VID_EMPLEADO AS VARCHAR(100),
		@VAPTITUD AS VARCHAR(100),
		@VSERVICIO AS VARCHAR(100),
		@VCALIFICACION AS VARCHAR(100),
		@VOBSERVACION AS VARCHAR(400),
		@VEMPLEADO AS VARCHAR(100),
		@VDESC_ERROR AS VARCHAR(4000)
 
DECLARE @UPDATE_MENU AS BIT,
		@HTML_TITTLE AS VARCHAR(400),
		@HTML_NAME_EMP AS VARCHAR(100),
		@HTML_INPUT_APTITUD AS VARCHAR(100),
		@HTML_INPUT_SERVICIO AS VARCHAR(100)
 
BEGIN	
 
	--RECUPERO INFOMACION DEL BUFFER
	SELECT	@VCLAVE = ISNULL(CLAVE,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_EMPLEADO = ISNULL(EMPLEADO,''),
			@VSERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VAPTITUD = ISNULL(APTITUD,''),
			@VCALIFICACION = ISNULL(CALIFICACION,''),
			@VOBSERVACION = ISNULL(OBSERVACION,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	--ARMO NOMBRE DEL EMPLEADO.
	SELECT @HTML_NAME_EMP = isnull(APELLIDO_EMPLEADO,'') + ', ' + isnull(NOMBRE_EMPLEADO,'')
	FROM LK_EMPLEADOS WHERE ID_EMPLEADO = @VID_EMPLEADO
 
 
	IF(@VCLAVE = '') BEGIN
		SET @HTML_TITTLE = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Aptitud - '+isnull(@HTML_NAME_EMP,'')+'</b></span>'
		SET @UPDATE_MENU = 0 --Menu ALTA.		
	END ELSE BEGIN
		SET @HTML_TITTLE = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Aptitud - '+isnull(@HTML_NAME_EMP,'')+'</b></span>'
		SET @UPDATE_MENU = 1 --Menu UPDATE.
 
		IF (@VERROR <> 'SI') BEGIN
			--RECUPERO CAMPOS DE LK_TIPO_SERVICIOS--
			SELECT	@VEMPLEADO	= ISNULL(ID_EMPLEADO,''),
					@VAPTITUD = ISNULL(APT.ID_APTITUD,''),
					@VCALIFICACION = ISNULL(CALIFICACION,''),
					@VOBSERVACION = ISNULL(OBSERVACION,'')
			FROM	LK_EMPLEADOS_APTITUD EMP
					LEFT JOIN LK_APTITUDES APT ON (EMP.ID_APTITUD = APT.ID_APTITUD)
			WHERE	ID_EMPLE_APTITUD = @VCLAVE
						
			UPDATE TMT_SV_01
			SET		EMPLEADO = @VEMPLEADO,
					APTITUD = @VAPTITUD,
					CALIFICACION = @VCALIFICACION,
					OBSERVACION = @VOBSERVACION
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
 
	--IF @UPDATE_MENU = 0 BEGIN
		--SET @HTML_INPUT_APTITUD = '<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.APTITUD"></select>'
		--SET @HTML_INPUT_SERVICIO = '<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.TIPO_SERVICIO" disabled></select>'
	/*END ELSE BEGIN
		SET @HTML_INPUT_APTITUD = '<input class="w3-input w3-border w3-round" type="text" name="SP.APTITUD" value="'+isnull(@VAPTITUD,'')+'">'
		SET @HTML_INPUT_SERVICIO = '<input class="w3-input w3-border w3-round" type="text" name="SP.TIPO_SERVICIO" value="'+isnull(@VSERVICIO,'')+'">'
	END*/
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users fa-fw w3-large"></i>&nbsp;&nbsp;Empleado Aptitud</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '
		<div class="w3-row-padding">'+
			isnull(@HTML_TITTLE,'') + '
			<div class="w3-row w3-bottombar"></div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Aptitud&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.APTITUD"></select>
			</div>
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-cogs"></i>&nbsp;&nbsp;Servicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.TIPO_SERVICIO" disabled></select>
			</div>
			<div class="w3-col m4 w3-padding-small">
				<label><i class="fas fa-sort-numeric-down"></i>&nbsp;&nbsp;Calificación&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CALIFICACION" value="'+@VCALIFICACION+'">	
			</div>
			<div class="w3-col m12 w3-padding-small">
				<label><i class="fas fa-font"></i>&nbsp;&nbsp;Observación</i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.OBSERVACION" value="'+@VOBSERVACION+'">
			</div>
			<div>&nbsp;</div>
		</div>
	<div class="w3-row w3-topbar">'+
		CASE WHEN @VERROR = 'SI' AND @VDESC_ERROR <> '' THEN @VDESC_ERROR ELSE '&nbsp;' END + '
	</div>'
 
	SET @OFOOTER = '
	<div class="w3-row">
		<div class="w3-container w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+case when @UPDATE_MENU = 0 then 'Agregar' else 'Grabar' end+'</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;">Cancelar</btn>
		</div>
	</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '450788A2-7610-4657-90C1-5DE02426BA5B' + ''', ''' + ISNULL(@VAPTITUD,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '9459491E-DDC8-4DDF-A765-1122AAA3955E' + ''', ''' + ISNULL(@VSERVICIO,'') +''', '''');</script>'
 
END
 
 
 
