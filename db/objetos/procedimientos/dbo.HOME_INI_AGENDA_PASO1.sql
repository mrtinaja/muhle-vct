CREATE PROCEDURE [dbo].[HOME_INI_AGENDA_PASO1]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX)	OUTPUT,
 @OPASOS	AS VARCHAR(MAX)	OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE	@VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VNOMBRE_CLIENTE	VARCHAR(MAX),
		@VNOMBRE_PROY		VARCHAR(MAX),
		@VNOMBRE_SERV_SELEC	VARCHAR(MAX),
		@VLUGAR_SERV_SELEC	VARCHAR(MAX),
		@VTIPO_SERV_SELEC	VARCHAR(MAX)
 
DECLARE	@VMES				VARCHAR(50),
		@VMES_ANT			VARCHAR(50),
		@VMES_SIG			VARCHAR(50),
		@VANO				VARCHAR(50),
		@VANO_ANT			VARCHAR(50),
		@VANO_SIG			VARCHAR(50),
		@VMes_Nombre		VARCHAR(100),
		@VMES_DESC			VARCHAR(100),
		@VCODE_MES			VARCHAR(50),
		@VOPTIONS_MESES		VARCHAR(max),
		@vprimer_semana		tinyint,
		@vultima_semana		tinyint,
		@VDIA				tinyint,
		@VEXISTE			INT,
		@VACTUAL			VARCHAR(MAX),
		@vsemana			tinyint,
		@VTABLA				VARCHAR(max)
 
BEGIN
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())
 
	SELECT	@VNOMBRE_CLIENTE = ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	IF (@VID_SERVICIO <> '') BEGIN
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-calendar-plus w3-large"></i>&nbsp;&nbsp;Agregar Visita</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
			<div class="w3-row-padding">
				<span class="w3-bar-item w3-left w3-padding w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VNOMBRE_CLIENTE,'')+'</b></span>
				<span class="w3-bar-item w3-right w3-padding w3-muhle-text-14"> 
						<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
											'fas fa-user-tie"'
										WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
											'fas fa-chalkboard-teacher"'
										WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
											'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' + ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,'')+'</b></span>
				<span class="w3-bar-item w3-right w3-padding w3-muhle-text-14"><i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(@VNOMBRE_PROY,'')+'&nbsp;&nbsp;</b></span>
				<div class="w3-row w3-bottombar"></div>'
 
	SET @OPASOS = '
	<ul class="progress-indicator">
        <li class="completed">
            <span class="bubble"></span>
            <i class="fas fa-calendar-day w3-large"></i><br>
            1. SELECCIONAR FECHA DESDE
        </li>
		<li class="">
            <span class="bubble"></span>
            <i class="fas fa-calendar-day w3-large"></i><br>
            2. SELECCIONAR FECHA HASTA
        </li>
        <li class="">
            <span class="bubble"></span>
            <i class="fas fa-users w3-large"></i><br>
            3. SELECCIONAR CONSULTORES
        </li>
		<li class="">
            <span class="bubble"></span>
            <i class="fas fa-clock w3-large"></i><br>
            4. CARGA HORARIO
        </li>
        <li>
            <span class="bubble"></span>
            <i class="fas fa-check-circle w3-large"></i><br>
            5. CONFIRMAR
        </li>
    </ul>
	<div class="w3-row w3-bottombar"></div>
	<div class="w3-container" style="padding:4px;"></div>
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
	.agendadoA {border-top: 4px solid rgb(241, 196, 15);background-clop: padding-box;background: rgb(241, 196, 15, 0.2);}
	.agendadoC {border-top: 4px solid rgb(39, 174, 96);background-clop: padding-box;background: rgb(39, 174, 96, 0.2);}
	.free {background-clop: padding-box;background: white;}
	</style>
	<script>
	function getComboA(selectObject) {
    var value = selectObject.value;
	saveSelection(''AGENDA_MES'',value);goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');
	}
	</script>'
 
	SELECT	@vprimer_semana = min(semanames),
			@vultima_semana = max(semanames),
			@VMes_Nombre = MesNombre
	FROM	Calendar
	WHERE	CONVERT(VARCHAR,Mes) = @VMES
	AND		CONVERT(VARCHAR,Ano) = @VANO
	group by MesNombre
 
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
 
	SET @VMES_ANT = @VMES - 1
	SET @VANO_ANT = @VANO - 1
	SET @VMES_SIG = @VMES + 1
	SET @VANO_SIG = @VANO + 1
 
	SET @VDIA = 1
 
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
			
			SELECT	@VACTUAL =	CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										'<td class="'+CASE WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) IN ('S','P')) THEN 'agendadoA'
																		WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) = 'C') THEN 'agendadoC' ELSE '' END+'">
												<span class="date">'+CONVERT(VARCHAR,A.DIA)+'<ul>'+
																	ISNULL([dbo].[FN_GET_AGENDA_DIA_CONSULTOR] (A.HOLIDAYTEXT, A.FECHA),'')+'</ul>
												</span>
											</td>'
								ELSE
									CASE WHEN (C.Feriado = 2) THEN
											'<td class="feriadoM">
												<span class="date">'+CONVERT(VARCHAR,C.DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(C.HolidayText,1,25),'')+'</span>
												</li></ul></span>
											</td>'
										 WHEN (Feriado = 1) THEN
											'<td class="feriadoF">
												<span class="date">'+CONVERT(VARCHAR,C.DIA)+'<ul><li>
												<span class="event">'+ISNULL(SUBSTRING(C.HolidayText,1,25),'')+'</span>
												</li></ul></span>
											</td>'
									ELSE
											'<td class="free">
												<span class="date" style="cursor:pointer;" title="Seleccionar Fecha Desde" onclick="almacenarSeleccion(''AGENDA_DESDE'','''+CONVERT(VARCHAR,C.Fecha)+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');return false;">'+CONVERT(VARCHAR,C.DIA)+'</span>
											</td>'
									END  
								END
			from	Calendar C
					LEFT JOIN LK_AGENDA_EMPLEADO A ON C.FECHA = A.FECHA AND	A.HOLIDAYTEXT in (SELECT CONVERT(VARCHAR,ID_AGENDA) FROM LK_AGENDA WHERE ID_CLIENTE = @VCLIENTE and ID_PROYECTO = @VID_PROYECTO AND PROYECTO_SERV_ID = @VID_SERVICIO)
			where	CONVERT(VARCHAR,C.Mes) = @VMES
			and		CONVERT(VARCHAR,C.Ano) = @VANO
			and		SemanaMes = @vsemana
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
 
	SET @VTABLA = @VTABLA + '</table></div>'
 
	SET @OFORMULARIO = '
	<div class="w3-row w3-padding">
		<div class="w3-col m2 w3-padding-small">
			<span class="w3-muhle-text-24 w3-left">'+@VMes_Nombre+ ' ' +@VANO+'</span>
		</div>
		<div class="w3-col m1 w3-padding-small">
			<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '1' THEN '12' ELSE @VMES_ANT END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '1' THEN @VANO_ANT ELSE @VANO END+');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
		</div>
		<div class="w3-col m2 w3-padding-small">
			<select class="w3-input w3-round w3-border w3-muhle-text-11" id="comboA" onchange="getComboA(this)">
				'+ISNULL(@VOPTIONS_MESES,'')+'
			</select>
		</div>
		<div class="w3-col m1 w3-padding-small">
			<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '12' THEN '1' ELSE @VMES_SIG END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '12' THEN @VANO_SIG ELSE @VANO END+');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
		</div>
		<div class="w3-col m1 w3-padding-small">
			<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT+''');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
		</div>
		<div class="w3-col m2 w3-padding-small">
			<select class="w3-input w3-round w3-border w3-muhle-text-11" disabled>
				<option class="lt" selected="selected">'+ISNULL(CONVERT(VARCHAR,@VANO),'')+'</option>
			</select>
		</div>
		<div class="w3-col m1 w3-padding-small">
			<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG+''');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
		</div>
	</div>
	<div class="w3-row w3-bottombar"></div><div class="w3-container" style="padding:4px;"></div>'
 
	SET @OFORMULARIO = @OFORMULARIO + ISNULL(@VTABLA,'')
 
	UPDATE	XAGENDA
	SET		AGENDA_ESTADO = NULL,
			AGENDA_HASTA = NULL,
			AGENDA_HORAS = NULL,
			AGENDA_OBSERVADOR = NULL,
			AGENDA_OBSERV_CALIF = NULL,
			AGENDA_OBSERV_LOGIS = NULL,
			AGENDA_CONSULTOR = NULL,
			AGENDA_CONSULTORES = NULL,
			AGENDA_NORMAS = NULL,
			AGENDA_NORMA = NULL,
			ALERTA_CALIF = NULL,
			BUFFER = NULL,
			ACUMULA = NULL,
			LIDER = NULL,
			DESC_ERROR = NULL,
			PREVIUS = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
 
END
