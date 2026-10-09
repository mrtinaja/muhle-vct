CREATE   PROCEDURE [dbo].[SV_01_INICIA_ADD_APTITUD]
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
		@USERDESC AS VARCHAR(300),
		@VCLAVE AS VARCHAR(100),
		@VDESCRIPCION_APT VARCHAR(2000),
		@VESTADO_APT VARCHAR(50),
		@VERROR VARCHAR(50),
		@VDESC_ERROR VARCHAR(400)
 
 
/*Strings segun el menu (ALTA-UPDATE)*/
DECLARE @VTITULO_PANTALLA VARCHAR(200)
DECLARE @VBOTON_ACCION VARCHAR(200)
 
 
BEGIN	
 
	SET @VDESCRIPCION_APT = '';
	SET @VESTADO_APT = '';
	SET @VCLAVE = '';
	
	SELECT @VCLAVE = ISNULL(CLAVE,''),
		   @VDESCRIPCION_APT=ISNULL(DESCRIPCION_APT,''),
		   @VESTADO_APT = ISNULL(ESTADO_APT,''),
		   @VERROR = ERROR,
		   @VDESC_ERROR = ISNULL(DESC_ERROR,'')
   FROM TMT_SV_01 
   WHERE PAR_KEY = @IPKEYJOB
 
   IF( @VCLAVE = '') BEGIN 	
		SET @VTITULO_PANTALLA = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Aptitud</b></span>'
		SET @VBOTON_ACCION = 'Agregar'
	END	ELSE BEGIN
		SET @VTITULO_PANTALLA = '<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Aptitud</b></span>'
		SET @VBOTON_ACCION = 'Guardar'
		
		IF(ISNULL(@VDESC_ERROR,'') = '')BEGIN
			SELECT 
				@VDESCRIPCION_APT = ISNULL(DESC_APTITUD,''),
				@VESTADO_APT = ISNULL(STATUS_APTITUD,'')
			FROM LK_APTITUDES WHERE ID_APTITUD = @VCLAVE
		END
	END
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users fa-fw w3-large"></i>&nbsp;&nbsp;Aptitudes</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''F6941E7F-13B6-483D-8513-CE40C0C35C6C'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '
		<div class="w3-row-padding">'+
			CASE WHEN @VCLAVE = '' THEN 
				@VTITULO_PANTALLA
			ELSE
				@VTITULO_PANTALLA
			END + '
			<div class="w3-row w3-bottombar"></div>
			<div class="w3-col m6 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fas fa-font"></i>&nbsp;&nbsp;Descripcion&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIPCION_APT" value="' + @VDESCRIPCION_APT + '">
			</div>
			<div class="w3-col m6 w3-padding-small">
				<label class="w3-muhle-text-14"><i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.ESTADO_APT"></select>	
			</div>
			<div>&nbsp;</div>
		</div>
	<div class="w3-row w3-topbar">'+
		CASE WHEN @VERROR = 'SI' AND @VDESC_ERROR <> '' THEN @VDESC_ERROR ELSE '&nbsp;' END + '
	</div>'
	
	SET @OFOOTER = '
	<div class="w3-row">
		<div class="w3-container w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+@VBOTON_ACCION+'</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''F6941E7F-13B6-483D-8513-CE40C0C35C6C'');return false;">Cancelar</btn>
		</div>
	</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '78FF2D5A-0B70-4854-A931-6D7F026748EA' + ''', ''' + ISNULL(''+@VESTADO_APT+'','') +''', '''');</script>'
 
END
 
