CREATE PROCEDURE [dbo].[SV_05_CALIF_CONSULTORES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OPANEL	AS VARCHAR(MAX) OUTPUT
 )
AS
 
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@CALIF_SEL		VARCHAR(50),
		@APTITUD_SEL	INT,
		@TIPO_SERVICIO_SEL INT
 
BEGIN	
	
	SELECT	@CALIF_SEL=CALIF_SEL,
			@APTITUD_SEL=APTITUD_SEL,
			@TIPO_SERVICIO_SEL=TIPO_SERVICIO_SEL
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-pie fa-fw w3-large"></i>&nbsp;&nbsp;Calificación Consultores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''3156A499-EF81-4F52-818A-AE94DAF5583B'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>'
 
	SET @OPANEL = 
	'<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round">
					<div class="w3-container w3-white w3-padding w3-round-up">
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Aptitud</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb_aptitud" name="SP.APTITUD_SEL" onchange="goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');return false;"></select>
						</div>
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-cogs"></i>&nbsp;&nbsp;Servicio</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb_tipo_serv" name="SP.TIPO_SERVICIO_SEL" onchange="goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');return false;"></select>
						</div>
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-sort-numeric-down"></i>&nbsp;&nbsp;Calificación</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb_calif" name="SP.CALIF_SEL" onchange="goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');return false;"></select>
						</div>
						<div class="w3-col m1 w3-padding-small">
							<br>
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''83A4857B-A604-4008-B608-0ADBE1B9B5BE'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<script>
		BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_aptitud'', ''450788A2-7610-4657-90C1-5DE02426BA5B'', '''+ISNULL(cast(@APTITUD_SEL as varchar),'')+''', '''');
		BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_tipo_serv'', ''D7FF0D36-D39D-4386-8BDC-F6560BD11EB7'', '''+ISNULL(cast(@TIPO_SERVICIO_SEL as varchar),'')+''', '''');'+
		CASE WHEN ISNULL(@APTITUD_SEL,'') = '' THEN '' ELSE
			'BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_calif'', ''CD0C3361-D400-4E51-82C9-6F906906C461'', '''+ISNULL(@CALIF_SEL,'')+''', '''');'
		END + '
	</script>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
END
