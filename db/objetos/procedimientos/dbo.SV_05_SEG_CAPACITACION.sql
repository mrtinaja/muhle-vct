 
CREATE PROCEDURE [dbo].[SV_05_SEG_CAPACITACION]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OPANEL	AS VARCHAR(4000) OUTPUT
 )
AS
 
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME,
		@VTOTAL_CAPA		INT,
		@VTOTAL_HS_CAPA		INT,
		@VTOTAL_HS_EJEC		INT,
		@VTOTAL_HS_PROY		INT,
		@VHORAS_CAPA		INT,
		@VID_AGENDA			INT
 
BEGIN	
 
	SELECT	@VFECHA_DESDE = FECHA_DESDE,
			@VFECHA_HASTA = FECHA_HASTA
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
 
	SELECT	@VTOTAL_CAPA = COUNT(*), @VTOTAL_HS_PROY = SUM(PS.TOTAL_HORAS_PROYECTADAS), @VTOTAL_HS_EJEC = SUM(CONVERT(INT,[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO)))
	FROM	LK_PROYECTO P
			INNER JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
	WHERE	PS.FECHA_INICIO_REAL >= @VFECHA_DESDE
	AND		PS.FECHA_INICIO_REAL <= @VFECHA_HASTA
	--WHERE	PS.FECHA_INICIO_REAL <= @VFECHA_HASTA  
	--AND		PS.FECHA_FIN_REAL	 >= @VFECHA_DESDE
	AND		PS.ID_TIPO_SERVICIO = '3'
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-pie fa-fw w3-large"></i>&nbsp;&nbsp;Seguimiento de Capacitación</span>
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
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''0287E26B-2E89-4816-9D25-0A6C1C5FEDDC'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-container">
		<div class="w3-row-padding">
			<div class="w3-col s6 m4 l4" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-red"  style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+isnull(CAST(@VTOTAL_CAPA AS VARCHAR),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-user-tie w3-large"></i> Total Capacitaciones</span>
					</div>
				</div>
			</div>
			<div class="w3-col s6 m4 l4" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-green" style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+ISNULL(CAST(@VTOTAL_HS_PROY AS varchar),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-business-time w3-large"></i> Total Hs Proyectadas</span>
					</div>
				</div>
			</div>
			<div class="w3-col s6 m4 l4" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-orange w3-text-white" style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+ISNULL(CAST(@VTOTAL_HS_EJEC AS varchar),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-user-clock w3-large"></i> Total Hs Ejecutadas</span>
					</div>
				</div>
			</div>			
		</div>
	</div>
	<div class="w3-panel w3-topbar"></div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
END
 
