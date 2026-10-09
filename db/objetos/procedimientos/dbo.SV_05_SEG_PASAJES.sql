CREATE PROCEDURE [dbo].[SV_05_SEG_PASAJES]
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
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME,
		@VMES			VARCHAR(50),
		@VANO			VARCHAR(50),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max),
		@VANO_DESC      VARCHAR(100),
		@VANO_HTML      VARCHAR(max)
 
BEGIN	
	
	SELECT	@VFECHA_DESDE = FECHA_DESDE,
			@VFECHA_HASTA = FECHA_HASTA
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-pie fa-fw w3-large"></i>&nbsp;&nbsp;Seguimiento de Pasajes</span>
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
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde</label>
							<input class="w3-input w3-round w3-border w3-muhle-text-12" type="date" name="SP.FECHA_DESDE" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_DESDE, 105), 23),'')+'">
						</div>
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta</label>
							<input class="w3-input w3-round w3-border w3-muhle-text-12" type="date" name="SP.FECHA_HASTA" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_HASTA, 105), 23),'')+'">
						</div>
						<div class="w3-col m1 w3-padding-small">
							<br>
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''08B425FF-02CF-4686-BBA2-062C2FF53C7E'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
END
