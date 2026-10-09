CREATE PROCEDURE [dbo].[HOME_GRD_AGENDA_CONSULTOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OAGENDA	AS VARCHAR(MAX) OUTPUT,
 @OHEADER	AS VARCHAR(MAX) OUTPUT)
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
		@VNARANJA		VARCHAR(100),
		@VAZUL			VARCHAR(100),
		@VVERDE			VARCHAR(100),
		@VAMAR			VARCHAR(100),
		@VDISP			VARCHAR(100),
		@VNDISP			VARCHAR(100),
		@VLIC			VARCHAR(100),
		@VQUERY			varchar(max),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_SELEC	VARCHAR(100),
		@VCONSULTOR		VARCHAR(50),
		@VPREVIUS		VARCHAR(50),
		@VCODE_MES		VARCHAR(50),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max),
		@VOPTIONS_MESES VARCHAR(max),
		@VOPTIONS_CONSULTOR VARCHAR(max),
		@VCODE_CONSULTOR VARCHAR(50),
		@VEVENT_CONSULTOR VARCHAR(50),
		@VNOMBRE_CONSULTOR	VARCHAR(400),
		@VCMB_CONSULTOR_HTML VARCHAR(max),
		@VCONSULTOR_DESC VARCHAR(300),
		@VID_DELETE		VARCHAR(50),
		@VAGENDA		VARCHAR(4000),
		@VREG			INT,
		@VCANT			INT,
		@VDIAS_MENS		VARCHAR(50),
		@VSELECCIONADO	VARCHAR(400),
		@VEMAIL			VARCHAR(400),
		@VOBSERV_CONSUL VARCHAR(400),
		@VOBSERV_FECHA	DATETIME,
		@VOBSERV_USER	VARCHAR(100),
		@VDESC_ERROR	VARCHAR(4000)
 
BEGIN
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE		
 
	SELECT	@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,''),
			@VFECHA_SELEC = ISNULL(FECHA_SELEC,''),
			@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			@VPREVIUS = ISNULL(PREVIUS,''),
			@VID_DELETE = ISNULL(ID_DELETE,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())	
 
	IF (@VFECHA_SELEC <> '' AND @VID_DELETE = 'SI') BEGIN
		
		DELETE FROM LK_AGENDA_EMPLEADO
		WHERE	CONVERT(VARCHAR,Fecha) = @VFECHA_SELEC
		AND		ID_EMPLEADO = @VCONSULTOR
 
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
 
	SET @VOPTIONS_CONSULTOR = '<option></option>'
 
	DECLARE Consultores CURSOR FOR 
		SELECT	CONVERT(VARCHAR,ID_EMPLEADO), EVENTUAL, APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
		FROM	LK_EMPLEADOS
		WHERE	PERFIL_EMP = 'CONSULTOR'
		AND		STATUS_EMP = '1'
		ORDER BY APELLIDO_EMPLEADO
 
		OPEN Consultores  
		FETCH NEXT FROM Consultores INTO @VCODE_CONSULTOR, @VEVENT_CONSULTOR, @VNOMBRE_CONSULTOR
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
 
			SET @VOPTIONS_CONSULTOR =  isnull(@VOPTIONS_CONSULTOR,'') + 
	
				'<option style="color:'  + case when @VEVENT_CONSULTOR = 'SI' then 'blue' else 'black' end + ';" onclick="saveSelection(''AGENDA_CONSULTOR'','''+@VCODE_CONSULTOR+''');" class="lt" value="'+@VCODE_CONSULTOR+'"'+ CASE WHEN @VCONSULTOR = @VCODE_CONSULTOR THEN 'selected="selected"' ELSE '' END+'>'+@VNOMBRE_CONSULTOR+'</option>'	
			
			FETCH NEXT FROM Consultores INTO @VCODE_CONSULTOR, @VEVENT_CONSULTOR, @VNOMBRE_CONSULTOR
		END 
 
	CLOSE Consultores  
	DEALLOCATE Consultores
	
	set @vsemana = @vprimer_semana
	
	IF (ISNULL(@VCONSULTOR,'') = '') BEGIN
		SET	@VTABLA = '<div>&nbsp;</div>
		<div>
			<table class="w3-table w3-border w3-bordered"><tr><th class="w3-center w3-muhle-text-12"><b>Mensaje</b></th></tr><tr><td class="w3-center w3-muhle-text-12">Debe Seleccionar un Consultor</td></tr></table>
		</div>'
	END ELSE BEGIN
 
		SELECT	@VSELECCIONADO = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO,
				@VEMAIL = EMAIL_EMP
		FROM	LK_EMPLEADOS
		WHERE	ID_EMPLEADO = @VCONSULTOR
 
		SET @VCANT = 0
 
		SELECT	@VCANT = COUNT(1)
		FROM	LK_EMPLEADOS_DIAS
		WHERE	ID_EMPLEADO = @VCONSULTOR
		AND		CONVERT(VARCHAR,Mes) = @VMES
		AND		CONVERT(VARCHAR,Ano) = @VANO
 
		IF (@VCANT = 0) BEGIN
			SELECT	@VDIAS_MENS = DIAS_MENSUALES
			FROM	LK_EMPLEADOS
			WHERE	ID_EMPLEADO = @VCONSULTOR
		END ELSE BEGIN
			SELECT	@VDIAS_MENS = ISNULL(DIAS,'')
			FROM	LK_EMPLEADOS_DIAS
			WHERE	ID_EMPLEADO = @VCONSULTOR
			AND		CONVERT(VARCHAR,Mes) = @VMES
			AND		CONVERT(VARCHAR,Ano) = @VANO
		END
 
		SET @VCANT = 0
 
		SELECT	@VCANT = COUNT(1)
		FROM	LK_EMPLEADOS_OBSERV
		WHERE	ID_EMPLEADO = @VCONSULTOR
		AND		CONVERT(VARCHAR,Mes) = @VMES
		AND		CONVERT(VARCHAR,Ano) = @VANO
 
		IF (@VCANT > 0) BEGIN
			SELECT	@VOBSERV_CONSUL = ISNULL(OBSERVACION,''),
					@VOBSERV_FECHA = FECHA_UPD,
					@VOBSERV_USER = USUARIO_UPD
			FROM	LK_EMPLEADOS_OBSERV
			WHERE	ID_EMPLEADO = @VCONSULTOR
			AND		CONVERT(VARCHAR,Mes) = @VMES
			AND		CONVERT(VARCHAR,Ano) = @VANO
		END
	
		SET	@VTABLA = '<table id="agenda-content">
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
				
				SELECT	@VACTUAL = 
							CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
								'<td class="'+CASE	WHEN (A.TIPO = 'OC') THEN 'NoDisponible'
													WHEN (A.TIPO = 'OP') THEN 'NoDisponible'
													WHEN (A.TIPO = 'ND') THEN 'NoDisponible'
													WHEN (A.TIPO = 'D') THEN 'Disponible'
													WHEN (A.TIPO = 'LIC') THEN 'Licencia'
													WHEN (A.TIPO = 'POT') THEN 'Potencial'
													WHEN (A.TIPO = 'OA') THEN 'NoDisponible'
													WHEN (A.TIPO = 'A') THEN
														CASE	WHEN (([dbo].[FN_GET_CONSULTOR_HORAS_DISP] (@VCONSULTOR, A.FECHA) >  [dbo].[FN_GET_CONSULTOR_HORAS] (@VCONSULTOR, A.FECHA)) AND (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) IN ('S','P')) ) THEN 'DisponibleA' 
																WHEN (([dbo].[FN_GET_CONSULTOR_HORAS_DISP] (@VCONSULTOR, A.FECHA) >  [dbo].[FN_GET_CONSULTOR_HORAS] (@VCONSULTOR, A.FECHA)) AND (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) = 'C')) THEN 'DisponibleC' 
																WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) IN ('S','P')) THEN 'agendadoA'
																WHEN (dbo.FN_GET_AGENDA_ESTADO(A.HOLIDAYTEXT) = 'C') THEN 'agendadoC' ELSE '' END
												ELSE '' END+'">
										<span class="date">'+CONVERT(VARCHAR,A.DIA)+'<ul>'+
															CASE WHEN (A.TIPO = 'OC') THEN '<li><span class="event">Organismo Certificacion '+ CASE WHEN ISNULL(A.DESCRIPCION,'') = '' THEN '' ELSE '<i class="fas fa-info-circle" style="cursor:pointer;color:orange;" title="'+ISNULL(A.DESCRIPCION,'')+'"></i>' END +'</span>
																									<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span></li>'
																WHEN (A.TIPO = 'OP') THEN '<li><span class="event">Ocupado Personal '+ CASE WHEN ISNULL(A.DESCRIPCION,'') = '' THEN '' ELSE '<i class="fas fa-info-circle" style="cursor:pointer;color:orange;" title="'+ISNULL(A.DESCRIPCION,'')+'"></i>' END +'</span>
																								<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span></li>'
																WHEN (A.TIPO = 'ND') THEN '<li><span class="event">No Disponible ' + CASE WHEN ISNULL(A.DESCRIPCION,'') = '' THEN '' ELSE '<i class="fas fa-info-circle" style="cursor:pointer;color:orange;" title="'+ISNULL(A.DESCRIPCION,'')+'"></i>' END +'</span>
																								<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span></li>'
																WHEN (A.TIPO = 'D') THEN '<li><span class="event">Disponible ('+ISNULL(CONVERT(VARCHAR,A.HORAS_DISP),'')+')</span>
																								<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span></li>'
																WHEN (A.TIPO = 'LIC') THEN '<li><span class="event">Licencia - '+CASE WHEN A.HOLIDAYTEXT = 'V' THEN 'Vacaciones' ELSE 'Médica' END+'</span>
																									<span class="time">
																										<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																									</span></li>'
																WHEN (A.TIPO = 'POT') THEN '<li><span class="event">Potencial '+ CASE WHEN isnull([dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (A.FECHA,@VCONSULTOR),'') = '' THEN '' ELSE '<i class="fas fa-info-circle" style="cursor:pointer;color:orange;" title="'+isnull([dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (A.FECHA,@VCONSULTOR),'')+'"></i>' END +'</span>
																								<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span>
																							</li>' +
																							CASE WHEN isnull([dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (A.FECHA,@VCONSULTOR),'') = '' THEN '' ELSE
																								'<li><span class="event cursive-text">'+isnull([dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (A.FECHA,@VCONSULTOR),'') +'</span></li>'
																							END
																WHEN (A.TIPO = 'OA') THEN '<li><span class="event">Observacion Actividad ' + CASE WHEN ISNULL(A.DESCRIPCION,'') = '' THEN '' ELSE '<i class="fas fa-info-circle" style="cursor:pointer;color:orange;" title="'+ISNULL(A.DESCRIPCION,'')+'"></i>' END +'</span>
																								<span class="time">
																									<i class="far fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="Eliminar Fecha Consultor" onclick="almacenarSeleccion(''ID_DELETE'',''SI'');almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,A.Fecha)+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i>
																								</span></li>'
																--WHEN (A.TIPO = 'NA') THEN '<li><span class="event">No Cargado</span></li>'
																WHEN (A.TIPO = 'A') THEN ISNULL([dbo].[FN_GET_AGENDAS_CONSULTOR] (@IPKEYJOB, @VCONSULTOR, A.FECHA, @FORM_ID),'')
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
									'<td class="free" style="cursor:pointer;" title="Cargar Fecha Consultor" onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,c.Fecha)+''');goto('''+@FORM_ID+''',''5195D53C-FAD8-4256-A450-E3EF8895FAC6'');return false;">
										<span class="date">'+CONVERT(VARCHAR,C.DIA)+'<ul><li>
										<span class="event">No Cargado</span>
										</li></ul></span>
									</td>'
								END  
							END
						--END
				FROM	Calendar C
						LEFT JOIN LK_AGENDA_EMPLEADO A ON A.FECHA = C.Fecha and a.ID_EMPLEADO = @VCONSULTOR
				WHERE	CONVERT(VARCHAR,C.Mes) = @VMES
				AND		CONVERT(VARCHAR,C.Ano) = @VANO
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
	END
		
SET @VMES_ANT = @VMES - 1
SET @VANO_ANT = @VANO - 1
SET @VMES_SIG = @VMES + 1
SET @VANO_SIG = @VANO + 1
 
SET @OHEADER = '
<div class="w3-row w3-back  w3-light-grey" id="agenda-wrapper">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-user-clock w3-large"></i>&nbsp;&nbsp;Agenda Consultor '+
					CASE WHEN @VCONSULTOR <> '' THEN
						'<b>'+ISNULL(@VSELECCIONADO,'')+ ' - Dias Mensuales ('+ISNULL(@VDIAS_MENS,'')+')</b>'
					ELSE '' END + '</span>'+
					CASE WHEN ISNULL(@VPREVIUS,'') = 'SI' THEN
						'<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''0DB4EC39-94DD-48DE-AAEB-6DEF2834ACBC'');return false;"></i></span>'
					ELSE 
						'<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-envelope w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Enviar Mail a Consultor" id="btn-capturar" onclick="capturarAgenda();return false;"></i></span>' 
					END + '
				</div>
				<div class="w3-row w3-back w3-light-grey">
					<div class="w3-col w3-padding">
						<div class="w3-card-4 w3-round w3-padding">
							<div class="w3-container w3-round w3-padding">
								<div class="w3-row">
									<div class="w3-col m2 w3-padding-small">
										<span class="w3-muhle-text-24 w3-left">'+@VMes_Nombre+ ' ' +@VANO+'</span>'+
										CASE WHEN @VCONSULTOR <> '' THEN
											'<span class="w3-muhle-text-20 w3-right"><i class="fa fa-user-clock" style="'+CASE WHEN ISNULL(@VOBSERV_CONSUL,'') = '' THEN '' ELSE 'color:red;' END +'cursor:pointer;" title="Datos Consultor" onclick="document.getElementById(''CardConsultor'').style.display=''block'';return false;"></i></span>'
										ELSE '' END +'
									</div>
									<div class="w3-col m2 w3-padding-small">
										<select class="w3-input w3-round w3-border w3-muhle-text-11 w3-left" id="comboC" onchange="getComboC(this)">
											'+ISNULL(@VOPTIONS_CONSULTOR,'')+'
										</select>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '1' THEN '12' ELSE @VMES_ANT END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '1' THEN @VANO_ANT ELSE @VANO END+');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
									</div>
									<div class="w3-col m2 w3-padding-small">
										<select class="w3-input w3-round w3-border w3-muhle-text-11" id="comboA" onchange="getComboA(this)">
											'+ISNULL(@VOPTIONS_MESES,'')+'
										</select>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '12' THEN '1' ELSE @VMES_SIG END+');almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '12' THEN @VANO_SIG ELSE @VANO END+');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11 w3-right" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></button>
									</div>
									<div class="w3-col m2 w3-padding-small">
										<select class="w3-input w3-round w3-border w3-muhle-text-11" disabled>
											<option class="lt" selected="selected">'+ISNULL(CONVERT(VARCHAR,@VANO),'')+'</option>
										</select>
									</div>
									<div class="w3-col m1 w3-padding-small">
										<button class="w3-button w3-round w3-border w3-muhle-text-11" onclick="almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></button>
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
	</style>'
 
	SET @OAGENDA = @OAGENDA + ISNULL(@VTABLA,'')
 
	SET @OAGENDA = @OAGENDA + '
	<!DOCTYPE html>
	<html lang="es">
	<head>
	  <meta charset="UTF-8">
	  <title>Agenda - Descargar y Subir</title>
	  <!-- html2canvas -->
	  <script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
	  <script>
		function showToast(msg) {
		  const toast = document.getElementById("toast-success");
		  toast.textContent = msg;
		  toast.style.display = "block";
		  setTimeout(() => (toast.style.display = "none"), 3000);
		}
 
		async function capturarAgenda() {
		  const wrapper = document.getElementById("agenda-wrapper");
		  if (!wrapper) {
			showToast("❌ No se encontró el contenedor de la agenda");
			return;
		  }
 
		  try {
			// 👉 Render HTML a canvas
			const canvas = await html2canvas(wrapper, { backgroundColor: "#fff", scale: 2 });
			const dataUrl = canvas.toDataURL("image/png");
 
			// 👉 Convertir a Blob
			const res = await fetch(dataUrl);
			const blob = await res.blob();
 
			// 👉 Nombre de archivo con Consultor + Mes + Año
			const fileName = "AgCons_" + "' + @VCONSULTOR + '_' + @VMES + @VANO + '_' + CONVERT(VARCHAR,GETDATE(),112) + '_' + @IAGENTE + '" + ".png";
 
			 // ✅ POST al servidor .NET (UploadAgenda.ashx)
		  const formData = new FormData();
		  formData.append("file", blob, fileName);
		  formData.append("folder", "img/Agendas");
		  formData.append("pkey", "' + ISNULL(@IPKEYJOB,'''') + '");
 
		  const response = await fetch("/task/UploadAgenda.ashx", {
			method: "POST",
			body: formData
		  });
 
		  if (!response.ok) {
			console.error("❌ Error en POST:", response.statusText);
		  } else {
			const serverMsg = await response.text();
			console.log("📤 Respuesta servidor:", serverMsg);
			next('''+@FORM_ID+''');return false;
		  }
 
		} catch (err) {
		  console.error("💥 Captura error:", err);
		}
	  }
	</script>
	</head>
	<body>
	  <div id="toast-success" class="w3-panel w3-green w3-round w3-animate-opacity" 
		   style="display:none;position:fixed;top:20px;right:20px;z-index:9999;padding:10px 20px;">
	  </div>
	</body>
	</html>';
 
	SET @OAGENDA = @OAGENDA + 
					--inicio pop up--
					'<div id="CardConsultor" class="w3-modal w3-round">
						<div class="w3-modal-content w3-round">
							<header class="w3-container w3-muhle-color w3-round-up w3-padding">
								<img src="./../img/avatar7.png" style="height:50px;width:50px;" alt="Avatar" class="w3-left w3-circle w3-margin-right">
								<p class="w3-muhle-text-20" style="color:white">'+ISNULL(@VSELECCIONADO,'')+' - '+ ISNULL(@VMes_Nombre,'')+ ' ' +ISNULL(@VANO,'')+'</p>
							</header>
							<div class="w3-container w3-padding">
								<table class="w3-table w3-border w3-muhle-text-12 w3-white">
									<tr>
										<td class="w3-left"><i class="fas fa-calendar"></i></td>
										<td class="w3-left">Dias Mensuales</td>
										<td><div style="text-align:right">' +  ISNULL(@VDIAS_MENS,'') + '
											</div>
										</td>
									</tr>
									<tr>
										<td class="w3-left"><i class="fas fa-envelope"></i></td>
										<td class="w3-left">Email</td>
										<td><div style="text-align:right">' +  ISNULL(@VEMAIL,'') + '
											</div>
										</td>
									</tr>
									<tr>
										<td class="w3-left"><i class="fas fa-clipboard-list"></i></td>
										<td class="w3-left">Fecha / Usuario</td>
										<td><div style="text-align:right">' + ISNULL(CONVERT(VARCHAR,@VOBSERV_FECHA,103),'') + ' / ' + ISNULL(@VOBSERV_USER,'') + '
											</div>
										</td>
									</tr>
								</table>
								<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Observaciones</label>
								<textarea class="w3-input w3-border w3-round w3-muhle-text-14" maxlength="4000" rows="3" cols="50" name="SP.AGENDA_OBSERVADOR">' + ISNULL(@VOBSERV_CONSUL,'') + '</textarea>
							</div>
							<div class="w3-container w3-border-top w3-padding-16 w3-light-grey w3-round-down">
								<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''82DD6978-59C0-4C6D-8CDC-74E862D7F5FF'');">Guardar</btn>
								<btn type="btn" class="w3-button w3-muhle-color w3-medium w3-round" onclick="document.getElementById(''CardConsultor'').style.display=''none''">Cancelar</btn>
							</div>
						</div>
					</div>'+
					--fin pop up--
			'</div>
		</div>
	</div>
	<script>
	function getComboA(selectObject) {
    var value = selectObject.value;
	saveSelection(''AGENDA_MES'',value);goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');
	}
	function getComboC(selectObject) {
    var value = selectObject.value;
	saveSelection(''AGENDA_CONSULTOR'',value);goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');
	}
	</script>'+
	CASE WHEN @VDESC_ERROR <> '' THEN
	'<script>alert("'+ISNULL(@VDESC_ERROR,'')+'");</script>' 
	ELSE '' END
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			DESC_ERROR = NULL,
			--FECHA_SELEC = NULL,
			--AGENDA_DESDE = NULL,
			--AGENDA_HASTA = NULL,
			AGENDA_TIPO = NULL,
			AGENDA_MOTIVO = NULL,
			AGENDA_HORAS = NULL,
			AGENDA_MES = @VMES,
			AGENDA_ANO = @VANO,
			AGENDA_DESC = NULL,
			action = 'INICIO',
			ID_DELETE = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
