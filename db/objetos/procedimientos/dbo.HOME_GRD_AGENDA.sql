 
CREATE PROCEDURE [dbo].[HOME_GRD_AGENDA]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OAGENDA	AS VARCHAR(MAX) OUTPUT,
 @OHEADER	AS VARCHAR(8000) OUTPUT)
AS
 
declare	@VMES			VARCHAR(50),
		@VMES_ANT		VARCHAR(50),
		@VMES_SIG		VARCHAR(50),
		@VANO			VARCHAR(50),
		@VANO_ANT		VARCHAR(50),
		@VANO_SIG		VARCHAR(50),
		@vprimer_semana	tinyint,
		@vultima_semana	tinyint,
		@VMes_Nombre	VARCHAR(100),
		@VDIA			tinyint,
		@VEXISTE		INT,
		@VACTUAL		VARCHAR(MAX),
		@vsemana		tinyint,
		@vdomingo		varchar(4000),
		@vlunes			varchar(4000),
		@vmartes		varchar(4000),
		@vmiercoles		varchar(4000),
		@vjueves		varchar(4000),
		@vviernes		varchar(4000),
		@vsabado		varchar(4000),
		@VTABLA			VARCHAR(max),
		@VCLASE			VARCHAR(1000),
		@VCLASED		VARCHAR(1000),
		@VSTYLE			VARCHAR(1000),
		@VROJO			VARCHAR(100),
		@VAZUL			VARCHAR(100),
		@VVERDE			VARCHAR(100),
		@VQUERY			varchar(max),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_SELEC	VARCHAR(100),
		@VFECHA			DATE,
		@VMES_DESC      VARCHAR(100),
		@VCODE_MES		VARCHAR(50),
		@VMES_HTML      VARCHAR(max),
		@VOPTIONS_MESES VARCHAR(max)
 
 
BEGIN
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
	
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,''),
			@VFECHA_SELEC = ISNULL(FECHA_SELEC,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())	
 
	IF (@VFECHA_SELEC <> '') BEGIN
		
		SET @VFECHA = CONVERT(DATE,@VFECHA_SELEC)
 
		UPDATE	Calendar
		SET		IsHoliday = 0,
				HolidayText = NULL,
				Feriado = '0'
		WHERE	Fecha = @VFECHA
	END
 
	SELECT	@vprimer_semana = min(semanames),
			@vultima_semana = max(semanames),
			@VMes_Nombre = MesNombre
	FROM	Calendar
	WHERE	CONVERT(VARCHAR,Mes) = @VMES
	AND		CONVERT(VARCHAR,Ano) = @VANO
	group by MesNombre
 
	SET @VDIA = 1
 
	--SET @VOPTIONS_MESES = '<option value=""></option>'
 
	DECLARE Meses CURSOR FOR 
		SELECT	DISTINCT Mes, MesNombre
		FROM	Calendar 
		WHERE	Ano = @VANO
		order by Mes
 
		OPEN Meses  
		FETCH NEXT FROM Meses INTO @VCODE_MES, @VMES_DESC
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
 
			SET @VOPTIONS_MESES =  isnull(@VOPTIONS_MESES,'') + 
	
				'<option onclick="saveSelection(''AGENDA_MES'','''+@VCODE_MES+''');" class="lt" value="'+@VCODE_MES+'"'+ CASE WHEN ISNULL(CONVERT(VARCHAR,@VMES),'') = @VCODE_MES THEN 'selected="selected"' ELSE '' END+'>'+@VMES_DESC+'</option>'	
			
			FETCH NEXT FROM Meses INTO @VCODE_MES, @VMES_DESC
		END 
 
	CLOSE Meses  
	DEALLOCATE Meses
	
	--EXEC HOME_CMB_MESES_HTML @VMES_DESC, 'AGENDA_MES', @FORM_ID, '8C0685B0-27AD-4DD2-A881-EDDD553BA13C', @VMES_HTML OUTPUT;
 
	set @vsemana = @vprimer_semana
	
	SET	@VTABLA = '<table>
	  <thead>
		<tr class="w3-muhle-text-14">
		  <th><b>Domingo</b></th>
		  <th><b>Lunes</b></th>
		  <th><b>Martes</b></th>
		  <th><b>Miércoles</b></th>
		  <th><b>Jueves</b></th>
		  <th><b>Viernes</b></th>
		  <th><b>Sábado</b></th>
		</tr>
	  </thead>'
 
	WHILE @vsemana <= @vultima_semana 
	BEGIN
		
		IF (@VDIA = 1) BEGIN
			SET @VTABLA = @VTABLA + '<tr>'
		END
 
		SET @VEXISTE = 0
 
		SELECT	@VEXISTE = COUNT(1)
		FROM	Calendar
		WHERE	CONVERT(VARCHAR,Mes) = @VMES
		AND		CONVERT(VARCHAR,Ano) = @VANO
		AND		SemanaMes = @VSEMANA
		AND		DiaSemana = @VDIA
	
		IF (@VEXISTE = 1) BEGIN
			
			SELECT	@VACTUAL =	CASE WHEN Fecha < CONVERT(VARCHAR,GETDATE(),23) THEN
									CASE WHEN (Feriado = 2) THEN
											'<td class="feriadoM">
												<span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(HolidayText,1,25),'')+'</span>
												</li></ul></span>
											</td>'
										 WHEN (Feriado = 1) THEN
											'<td class="feriadoF">
												<span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(HolidayText,1,25),'')+'</span>
												</li></ul></span>
											</td>'
									ELSE
										'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
									END
								ELSE
									CASE WHEN (Feriado = 2) THEN
											'<td class="feriadoM">
												<span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(HolidayText,1,25),'')+'</span>
												<span class="time"><i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Feriado" onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,FECHA)+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"></i></span>
												</li></ul></span>
											</td>'
										 WHEN (Feriado = 1) THEN
											'<td class="feriadoF">
												<span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(HolidayText,1,25),'')+'</span>
												<span class="time"><i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Feriado" onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,FECHA)+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"></i></span>
												</li></ul></span>
											</td>'
									ELSE
										'<td class="free" style="cursor:pointer;" title="Agregar Feriado" onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,FECHA)+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');return false;"><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
									END
								END 
			FROM	Calendar
			WHERE	CONVERT(VARCHAR,Mes) = @VMES
			AND		CONVERT(VARCHAR,Ano) = @VANO
			AND		SemanaMes = @VSEMANA
			AND		DiaSemana = @VDIA
 
		END ELSE BEGIN
 
			SET @VACTUAL = '<td class="w3-disabled"><span class="date"></span></td>'
		END
 
		SET @VTABLA = @VTABLA + @VACTUAL
 
		SET @VDIA = @VDIA + 1
 
		IF (@VDIA > 7) BEGIN
			SET @VSEMANA = @VSEMANA + 1
			SET @VDIA = 1
			SET @VTABLA = @VTABLA + '</tr>'
		END
	END
 
	SET @VTABLA = @VTABLA + '</table>'
	
SET @VMES_ANT = @VMES - 1
SET @VANO_ANT = @VANO - 1
SET @VMES_SIG = @VMES + 1
SET @VANO_SIG = @VANO + 1
 
SET @OHEADER = '
<div class="w3-row w3-back  w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-calendar-alt w3-large"></i>&nbsp;&nbsp;Agenda General</span>
				</div>
				<div class="w3-row w3-back w3-light-grey">
					<div class="w3-col w3-padding">
						<div class="w3-card-4 w3-round w3-padding">
							<div class="w3-container w3-round w3-padding">
								<div class="w3-row">
									<div class="w3-col m2 w3-padding-small">
										<span class="w3-muhle-text-24 w3-left">'+@VMes_Nombre+ ' ' +@VANO+'</span>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '1' THEN '12' ELSE @VMES_ANT END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '1' THEN @VANO_ANT ELSE @VANO END+');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
									</div>
									<div class="w3-col m2 w3-padding-small">
										<select class="w3-input w3-round w3-border w3-muhle-text-11" id="comboA" onchange="getComboA(this)">
											'+ISNULL(@VOPTIONS_MESES,'')+'
										</select>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '12' THEN '1' ELSE @VMES_SIG END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '12' THEN @VANO_SIG ELSE @VANO END+');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
									</div>
									<div class="w3-col m2 w3-padding-small">
										<select class="w3-input w3-round w3-border w3-muhle-text-11" disabled>
											<option class="lt" selected="selected">'+ISNULL(CONVERT(VARCHAR,@VANO),'')+'</option>
										</select>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
									</div>
								</div>
							</div>
							<hr style="height:1px;border-width:0;color:gray;background-color:gray;">'
 
	SET @OAGENDA = '
	<style>
	.cursive-text {font-family: "Roboto", "sans-serif"}
	select {text-align: center;text-align-last: center;}
	select .lt {text-align: center;}
	a {text-decoration: none;display: inline-block;}
	a:hover {background-color: #ddd;color: black;}
	.pyn {border: 1px solid gray;border-radius: 2px;background-color: white;color: black;padding: 8px 16px;cursor: pointer;}
	{font-size: 100%;}
	*:before,
	*:after {
	  box-sizing: border-box;
	}
	body {margin: 0.5em;}
	table {
	  border-collapse: collapse;
	  border-spacing: 0;
	  width: 100%;
	  height: 100%;
	  min-width: 800px;
	}
	@media (max-width: 800px) {
	  table .time {
		display: none;
	  }
	}
	tr {position: relative;}
	th {font-family: "Roboto", "sans-serif"; text-align: center;color: black;font-weight: bold;font-weight: normal;font-size: 1.00em;}
	td {font-family: "Roboto", "sans-serif"; width: 14.285714286%;}
	.date {text-align: right;display: block;height: 0;font-weight: bold;font-size: 1.20em;padding: 0.25em;padding-bottom: 53%;position: relative;border: 1px solid gray;}
	.date ul,
	.date li {margin: 0;padding: 0;list-style: none;color: #333;}
	.date ul {text-align: left;font-size: 0.7em;width: 100%;overflow: hidden;position: absolute;font-weight: normal;}
	.date li {color: black;width: 100%;height: 1.6em;overflow: hidden;white-space: nowrap;text-overflow: ellipsis;position: relative;}
	.date li:before {content: ''\2022'';color: inherit;display: inline-block;padding-right: 0.25em;}
	.time {float: right;padding-right: 0.50em;text-align: right;color: black;}
	.event {color: #333;}
	.feriadoF {border-top: 4px solid red;background-clop: padding-box;background: rgba(255, 0, 0, 0.2);}
	.feriadoM {border-top: 4px solid rgb(138, 43, 226);background-clop: padding-box;background: rgb(138, 43, 226, 0.2);}
	.free {background-clop: padding-box;background: white;}
	</style>'
 
	SET @OAGENDA = @OAGENDA + ISNULL(@VTABLA,'')
 
	SET @OAGENDA = @OAGENDA + '
	<script>
	function getComboA(selectObject) {
    var value = selectObject.value;
	saveSelection(''AGENDA_MES'',value);goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');
	}
	</script>'
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			DESC_ERROR = NULL,
			FECHA_FERIADO = NULL,
			DESCRIP_FERIADO = NULL,
			TIPO_FERIADO = NULL,
			FECHA_SELEC = NULL,
			AGENDA_MES = @VMES,
			AGENDA_ANO = @VANO
	WHERE	PAR_KEY = @IPKEYJOB
	
END
 
