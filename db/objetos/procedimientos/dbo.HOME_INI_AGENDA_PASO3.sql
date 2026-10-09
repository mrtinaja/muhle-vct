CREATE PROCEDURE [dbo].[HOME_INI_AGENDA_PASO3]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX)	OUTPUT,
 @OPASOS	AS VARCHAR(MAX)	OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE	@VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VID_AGENDA			VARCHAR(100),
		@VNOMBRE_CLIENTE	VARCHAR(MAX),
		@VNOMBRE_PROY		VARCHAR(MAX),
		@VNOMBRE_SERV_SELEC	VARCHAR(MAX),
		@VLUGAR_SERV_SELEC	VARCHAR(MAX),
		@VTIPO_SERV_SELEC	VARCHAR(MAX),
		@VFECHA_DESDE		DATETIME,
		@VFECHA_HASTA		DATETIME,
		@VDESC_ERROR		VARCHAR(4000),
		@VBUFFER			VARCHAR(MAX),
		@vsemana			int,
		@vmes				int,
		@vano				int,
		@var_mes			VARCHAR(50),
		@var_ano			VARCHAR(50),
		@VNORMAS_PROY		VARCHAR(400),
		@VNORMASIN			VARCHAR(400),
		@VNORMAS			VARCHAR(400),
		@VCONSULTORES		VARCHAR(MAX),
		@lstDato			VARCHAR(100), 
		@lnuPosComa			int ,
		@VALOR				VARCHAR(400),
		@VQUERY				NVARCHAR(MAX),
		@SQLString			NVARCHAR(MAX),
		@objcursorConsultores as cursor,
		@VCHECK				VARCHAR(400),
		@VID_CONSULTOR		VARCHAR(50),
		@VAPENOM			VARCHAR(400),
		@VCALIF				VARCHAR(100),
		@VEVENTUAL			VARCHAR(50),
		@VDIA				tinyint,
		@VEXISTE			INT,
		@VACTUAL			VARCHAR(MAX),
		@VCONSULORES_AGENDA VARCHAR(MAX),
		@VSELECCION			VARCHAR(MAX),
		@VSELECCION2		VARCHAR(MAX),
		@VPREVIOS			VARCHAR(MAX),
		@VNUEVOS			VARCHAR(MAX),
		@RESULTADO			INT,
		@VESTA				VARCHAR(50),
		@VAGREGO			VARCHAR(50),
		@VTORF				VARCHAR(100),
		@VPREVIUS			VARCHAR(50)
		
BEGIN
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA	= ISNULL(AGENDA_ID,''),
			@VFECHA_DESDE = ISNULL(AGENDA_DESDE,''),
			@VFECHA_HASTA = ISNULL(AGENDA_HASTA,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,''),
			@VBUFFER = isnull(AGENDA_CONSULTORES,''),
			@VSELECCION = ISNULL(BUFFER,''),
			@VPREVIOS = ISNULL(AGENDA_CONSULTORES,''),
			@VPREVIUS = ISNULL(PREVIUS,'NO')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	--SI MODIFICA AGENDA, RECUPERO LOS CONSULTORES DE LA AGENDA--
	IF (@VID_AGENDA <> '') BEGIN
 
		SELECT	@VCONSULORES_AGENDA = ID_CONSULTOR
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VID_AGENDA
 
		IF (ISNULL(@VDESC_ERROR,'') = '') BEGIN
			
			UPDATE	XAGENDA
			SET		AGENDA_CONSULTORES = @VCONSULORES_AGENDA
			WHERE	PAR_KEY = @IPKEYJOB
 
			SET @VBUFFER = @VCONSULORES_AGENDA
		END
	END
 
	IF (@VPREVIUS = 'SI') BEGIN
 
		SET @VNUEVOS = @VPREVIOS
		SET @VSELECCION2 = [dbo].[FN_GET_SELECCION] (@VSELECCION)
 
		WHILE PATINDEX('%|%',@VNUEVOS)>0
		BEGIN
			SET @RESULTADO = PATINDEX('%|%',@VNUEVOS) --+ @N
			SET  @VALOR = SUBSTRING(@VNUEVOS,1, @RESULTADO-1)
		
			SET @VESTA = DBO.FN_GET_NORMA(@VSELECCION2,@VALOR)
 
			--aca agrego o elimino el dato en el string--
			IF (@VESTA = 'SI') BEGIN
				SET @VAGREGO = 'NO'
			END ELSE BEGIN
				SET @VAGREGO = 'SI'
			END
 
			IF (@VAGREGO = 'SI') BEGIN
				SET @VSELECCION = ISNULL(@VSELECCION,'') + @VALOR + '=true|'
			END
		
			SELECT @VNUEVOS = RIGHT(@VNUEVOS,LEN(@VNUEVOS)-PATINDEX('%|%',@VNUEVOS))
		END
			
		SET @VALOR = NULL
 
		--RECUPERO LAS POSIBLES SELECCIONES PREVIAS A LA AGENDA CONSULTOR DE LA ACTUAL CARGA--
		WHILE LEN(@VSELECCION) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VSELECCION) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VSELECCION
				SET @VSELECCION = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VSELECCION, 1, @lnuPosComa - 1)
				SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
				IF (@VTORF = 'FALSE') BEGIN
					SET @VALOR = REPLACE('|'+ @VALOR,'|'+@VALOR+'|','|')
						IF (SUBSTRING(@VALOR,1,1) = '|') BEGIN
							SET @VALOR = SUBSTRING(@VALOR,2,LEN(@VALOR))
 
						END
				END ELSE BEGIN
 
					SET @VALOR = ISNULL(@VALOR,'') + SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1) + '|'
 
					SET @lstDato = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
 
				END
				
				SET @VSELECCION = SUBSTRING(@VSELECCION, @lnuPosComa + 1, LEN(@VSELECCION))
			END
		END
 
		UPDATE	XAGENDA
		SET		AGENDA_CONSULTORES = @VALOR, PREVIUS = NULL
		WHERE	PAR_KEY = @IPKEYJOB
 
		SELECT	@VBUFFER = isnull(AGENDA_CONSULTORES,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SELECT	@VNOMBRE_CLIENTE = ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF,
				@VNORMAS_PROY = ISNULL(NORMAS,'')
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
	
	SELECT	@VNORMASIN = substring(''''+REPLACE(@VNORMAS_PROY,'|',''','''),1,len(''''+REPLACE(@VNORMAS_PROY,'|',''','''))-2)
 
	SET @VNORMAS = @VNORMAS_PROY
 
	IF (@VID_SERVICIO <> '') BEGIN
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
	END
 
	SELECT	@vsemana = SemanaMes, @vmes = Mes, @vano = Ano
	FROM	Calendar
	WHERE	Fecha = @VFECHA_DESDE
 
	SET @var_mes = CONVERT(VARCHAR(50),@vmes)
	SET @var_ano = CONVERT(VARCHAR(50),@vano)
 
	--ARMO EL HEADER DE LA TABLA DE CONSULTORES--
	SET @VCONSULTORES = '
	<table class="w3-table w3-border w3-bordered">
		<thead>
			<tr class="w3-gray w3-muhle-text-12">
				<th class="w3-center"><b>Opc.</b></th>
				<th class="w3-left"><b>Consultor</b></th>'
	  
	  WHILE LEN(@VNORMAS) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VNORMAS
				SET @VNORMAS = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
 
				SELECT	@VALOR = DESC_APTITUD
				FROM	LK_APTITUDES
				WHERE	ID_APTITUD = @lstDato
 
				SET @VCONSULTORES = @VCONSULTORES + 
				'<th class="w3-center"><b>'+@VALOR+'</b></th>'
 
				SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
			END
		END
	  
	SET @VCONSULTORES = @VCONSULTORES +
	  '<th class="w3-left"><b>Disponibilidad</b></th>
	   <th class="w3-center"><b>Detalles</b></th>
    </tr>
	</thead>'
	--TERMINA EL HEADER DE LA TABLA DE CONSULTORES--
	   --<th class="w3-center"><b>Detalles</b></th>
 
	--ARMO CURSOR CON TODOS LOS CONSULTORES QUE CUMPLAN CON LAS NORMAS DEL PROYECTO--
	SELECT @VQUERY = 
		'SELECT	DISTINCT ''<input type="checkbox" id="''+CONVERT(VARCHAR,EMP.ID_EMPLEADO)+''"''+CASE WHEN ([dbo].[FN_GET_NORMA]('''+@VBUFFER+''',EMP.ID_EMPLEADO) = ''SI'') THEN '' checked="true"'' ELSE '''' END +'' onchange="toggleCheckbox(this);">'',  EMP.ID_EMPLEADO, EMP.APELLIDO_EMPLEADO + '', '' + EMP.NOMBRE_EMPLEADO, isnull(EVENTUAL,''NO'')
		   FROM	LK_EMPLEADOS EMP    
				INNER JOIN LK_EMPLEADOS_APTITUD APT ON EMP.ID_EMPLEADO = APT.ID_EMPLEADO AND APT.ID_TIPO = '+@VTIPO_SERV_SELEC+' AND APT.ID_APTITUD IN ('+@VNORMASIN+')  
		  WHERE	PERFIL_EMP = ''CONSULTOR''
		  AND  STATUS_EMP=''1''
		  ORDER BY 3'
 
	SELECT @SQLString = 'set @cursor = cursor forward_only static for ' + @VQUERY + ' open @cursor;'
 
	exec sys.sp_executesql
    @SQLString
    ,N'@cursor cursor output'
    ,@objcursorConsultores output
 
	--RECORRO EL CURSOR--
	FETCH NEXT FROM @objcursorConsultores INTO @VCHECK, @VID_CONSULTOR, @VAPENOM, @VEVENTUAL
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		--BUSCO LA CALIFICACION POR CADA NORMA DEL PROYECTO
		SET @VCONSULTORES = @VCONSULTORES +
				'<td class="w3-center w3-muhle-text-11">'+isnull(@VCHECK,'')+'</td>'+ 
				'<td class="w3-left w3-muhle-text-11" style="width:250px;color:'  + case when @VEVENTUAL = 'SI' then 'blue' else 'black' end + ';">'+ @VAPENOM +'</td>'
		
		SET @VNORMAS = @VNORMAS_PROY
					
		WHILE LEN(@VNORMAS) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VNORMAS
				SET @VNORMAS = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
 
				SELECT	@VCALIF = [dbo].[FN_GET_CALIFICACION] (@VID_CONSULTOR,@lstDato,@VTIPO_SERV_SELEC)
						
				SET @VCONSULTORES = @VCONSULTORES + 
				'<td class="w3-center w3-muhle-text-11">'+@VCALIF+'</td>'
 
				SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
			END
		END	
 
		SET @VDIA = 1
		
		WHILE @VDIA <= 7 
		BEGIN
		
			IF (@VDIA = 1) BEGIN
				SET @VCONSULTORES = @VCONSULTORES + '<td><table><tr>'
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
										'<td class="'+CASE	WHEN (A.TIPO = 'OC') THEN 'NoDisponible'
																WHEN (A.TIPO = 'OP') THEN 'NoDisponible'
																WHEN (A.TIPO = 'ND') THEN 'NoDisponible'
																WHEN (A.TIPO = 'D') THEN 'Disponible'
																WHEN (A.TIPO = 'LIC') THEN 'Licencia'
																WHEN (A.TIPO = 'POT') THEN 'Potencial'
																WHEN (A.TIPO = 'OA') THEN 'NoDisponible'
																WHEN (A.TIPO = 'A') THEN
																	CASE WHEN (([dbo].[FN_GET_CONSULTOR_HORAS_DISP] (@VID_CONSULTOR, A.FECHA) >  [dbo].[FN_GET_CONSULTOR_HORAS] (@VID_CONSULTOR, A.FECHA)) AND (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) IN ('S','P')) ) THEN 'DisponibleA' 
																		WHEN (([dbo].[FN_GET_CONSULTOR_HORAS_DISP] (@VID_CONSULTOR, A.FECHA) >  [dbo].[FN_GET_CONSULTOR_HORAS] (@VID_CONSULTOR, A.FECHA)) AND (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) = 'C')) THEN 'DisponibleC' 
																		WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) IN ('S','P')) THEN 'agendadoA'
																		WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) = 'C') THEN 'agendadoC' ELSE '' END
															ELSE '' END+'">
													<span class="date">'+CONVERT(VARCHAR,A.DIA)+'<ul>'+
																		CASE WHEN (A.TIPO = 'OC') THEN '<li><span class="event">Organismo Certificacion</span></li>'
																			WHEN (A.TIPO = 'OP') THEN '<li><span class="event">Ocupado Personal</span></li>'
																			WHEN (A.TIPO = 'ND') THEN '<li><span class="event">No Disponible</span></li>'
																			WHEN (A.TIPO = 'D') THEN '<li><span class="event">Disponible ('+ISNULL(CONVERT(VARCHAR,A.HORAS_DISP),'')+')</span></li>'
																			WHEN (A.TIPO = 'LIC') THEN '<li><span class="event">Licencia - '+CASE WHEN A.HOLIDAYTEXT = 'V' THEN 'Vacaciones' ELSE 'Médica' END+'</span></li>'
																			WHEN (A.TIPO = 'POT') THEN '<li><span class="event">Potencial</span></li>'
																			WHEN (A.TIPO = 'OA') THEN '<li><span class="event">Observacion Actividad</span></li>'
																			WHEN (A.TIPO = 'A') THEN '<li><span class="event">'+ 
																											'<i class="'+ CASE WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Consultoria' THEN 
																																	'fas fa-user-tie"'
																																WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Auditoria' THEN 
																																	'fas fa-chalkboard-teacher"'
																																WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Capacitacion' THEN 
																																	'fas fa-user-graduate"' END+
																												'style="cursor:pointer;" title="'+CASE WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Consultoria' THEN 
																																	'Consultoria'
																																WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Auditoria' THEN 
																																	'Auditoria'
																																WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (A.HOLIDAYTEXT),'') = 'Capacitacion' THEN 
																																	'Capacitacion' END
																												+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(A.HOLIDAYTEXT)
																												+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(A.HOLIDAYTEXT)
																												+ ' / (' + [dbo].[FN_GET_CONSULTOR_HORAS] (@VID_CONSULTOR, A.FECHA) +')"></i>' + '&nbsp;' +
																												ISNULL(SUBSTRING([dbo].[FN_GET_AGENDA_CLIENTE] (A.HOLIDAYTEXT),1,20),'')+'</span>
																											<span class="time"><b>('+ISNULL([dbo].[FN_GET_CONSULTOR_HORAS] (@VID_CONSULTOR, A.FECHA),'')+')</b></span>
																										</li>'
																		ELSE '' END+'</ul>
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
												<span class="date">'+CONVERT(VARCHAR,C.DIA)+'<ul><li>
												<span class="event">No Cargado</span>
												</li></ul></span>
											</td>'
										END  
									END
				from	Calendar C
						LEFT JOIN LK_AGENDA_EMPLEADO A ON A.FECHA = C.Fecha and a.ID_EMPLEADO = @VID_CONSULTOR
				where	CONVERT(VARCHAR,C.Mes) = @VMES
				and		CONVERT(VARCHAR,C.Ano) = @VANO
				and		SemanaMes = @vsemana
				AND		DiaSemana = @VDIA
 
			END ELSE BEGIN
 
				SET @VACTUAL = '<td class="w3-disabled"><span class="date"></span></td>'
			END
 
			SET @VCONSULTORES = @VCONSULTORES + @VACTUAL
 
			SET @VDIA = @VDIA + 1
 
			IF (@VDIA = 8) BEGIN
				--SET @VSEMANA = @VSEMANA + 1
				--SET @VDIA = 1
				SET @VCONSULTORES = @VCONSULTORES + '</tr></table></td>'
			END
		END
		
		SET @VCONSULTORES = @VCONSULTORES + '
		<td class="w3-center">
			<i class="far fa-calendar-plus w3-large" style="cursor:pointer;" title="Ir Agenda" onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''+@VID_CONSULTOR+''');almacenarSeleccion(''PREVIUS'','''+'SI'+''');saveValues(''BUFFER'');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');"></i>
		</td>
		</tr>'--<td></td>
 
		FETCH NEXT FROM @objcursorConsultores INTO @VCHECK, @VID_CONSULTOR, @VAPENOM, @VEVENTUAL
	END 
 
	CLOSE @objcursorConsultores  
	DEALLOCATE @objcursorConsultores
 
	SET @VCONSULTORES = isnull(@VCONSULTORES,'') + '</table>'
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="'+CASE WHEN @VID_AGENDA <> '' THEN 'fas fa-edit' ELSE 'fas fa-calendar-plus' END+ ' w3-large"></i>&nbsp;&nbsp;'+CASE WHEN @VID_AGENDA <> '' THEN 'Modificar' ELSE 'Agregar' END + ' Visita</span>
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
		<li class="completed">
            <span class="bubble"></span>
            <i class="fas fa-calendar-day w3-large"></i><br>
            2. SELECCIONAR FECHA HASTA
        </li>
        <li class="completed">
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
	<div class="w3-container" style="padding:4px;"></div>'
 
	SET @OFORMULARIO = '
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
	.date {text-align: right;display: block;height: 0;font-weight: bold;font-size: 1.00em;padding: 0.25em;padding-bottom: 53%;position: relative;border: 1px solid gray;}
	.date ul,
	.date li {margin: 0;padding: 0;list-style: none;color: #333;}
	.date ul {text-align: left;font-size: 0.6em;width: 100%;overflow: hidden;position: absolute;font-weight: normal;}
	.date li {color: black;width: 100%;height: 1.6em;overflow: hidden;white-space: nowrap;text-overflow: ellipsis;position: relative;}
	.date li:before {content: ''\2022'';color: inherit;display: inline-block;padding-right: 0.25em;}
	.time {float: right;padding-right: 0.50em;text-align: right;color: black;}
	.event {color: #333;}
	.feriadoF {border-top: 4px solid red;background-clop: padding-box;background: rgba(255, 0, 0, 0.2);}
	.feriadoM {border-top: 4px solid rgb(138, 43, 226);background-clop: padding-box;background: rgb(138, 43, 226, 0.2);}
	.agendadoA {border-top: 4px solid rgb(241, 196, 15);background-clop: padding-box;background: rgb(241, 196, 15, 0.2);}
	.agendadoC {border-top: 4px solid rgb(39, 174, 96);background-clop: padding-box;background: rgb(39, 174, 96, 0.2);}
	.free {background-clop: padding-box;background: white;}
	.Disponible {border-top: 4px solid rgb(133,193,233);background-clop: padding-box;background: rgb(133,193,233, 0.2);}
	.DisponibleA {border-top: 4px solid rgb(241, 196, 15);background-clop: padding-box;background: rgb(133,193,233, 0.2);}
	.DisponibleC {border-top: 4px solid rgb(39, 174, 96);background-clop: padding-box;background: rgb(133,193,233, 0.2);}
	.NoDisponible {border-top: 4px solid rgb(171,178,185);background-clop: padding-box;background: rgb(171,178,185, 0.2);}
	.Licencia {border-top: 4px solid rgb(250,219,216);background-clop: padding-box;background: rgb(250,219,216, 0.2);}
	.NoCargado {border-top: 4px solid #FDFEFE;background-clop: padding-box;background: #FDFEFE;}
	.Potencial {border-top: 4px solid rgb(255,165,0);background-clop: padding-box;background: rgb(255,165,0, 0.2);}
	</style>
		<div class="w3-row-padding" style="display: flex;justify-content: center;flex-wrap: wrap;">
			<div class="w3-col m2 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-day"></i>&nbsp;&nbsp;Fecha Desde</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14 w3-center" type="date" name="SP.AGENDA_DESDE" value="' + CASE WHEN ISNULL(@VFECHA_DESDE,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_DESDE,23) END + '" disabled>
			</div>
			<div class="w3-col m2 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-day"></i>&nbsp;&nbsp;Fecha Hasta</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14 w3-center" type="date" name="SP.AGENDA_HASTA" value="' + CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_HASTA,23) END + '" disabled>
			</div>
		</div>
		<div class="w3-row w3-topbar">&nbsp;</div>
		<div class="w3-container">
		' + @VCONSULTORES + '
		</div>'+
		CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
			'<div>&nbsp;</div>'
		ELSE 
			'<div class="w3-panel w3-pale-red" style="height: 20px;">
				<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
				</div>' 
		END + '
		<div class="w3-row w3-topbar">&nbsp;</div>
				<div class="w3-row">
					<div class="w3-container">
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="saveValues(''BUFFER'');next('''+@FORM_ID+''');return false;">Siguiente</btn>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');return false;">Anterior</btn>
					</div>
				</div>
			</div>
		</div>
	</div>'
	
	UPDATE	XAGENDA
	SET		ALERTA_CALIF = NULL,
			DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
 
END
