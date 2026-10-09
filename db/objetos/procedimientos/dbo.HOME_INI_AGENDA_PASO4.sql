CREATE PROCEDURE [dbo].[HOME_INI_AGENDA_PASO4]
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
		@VALERTA			VARCHAR(50),
		@VTABLA				VARCHAR(MAX),
		@VDIF				INT,
		@VREG				INT,
		@VFECHA				DATETIME,
		@VDESCCONS			VARCHAR(400),
		@VHORAS_DISP		INT,
		@VHORAS_DIA			INT,
		@ALMACENA_HORAS		VARCHAR(4000),
		@VID_VISITA			VARCHAR(100),
		@VHORAS_VISITA		NUMERIC(5),
		@VHORAS_AGENDA		INT,
		@VCONSULORES_AGENDA	VARCHAR(MAX),
		@VTIENE_HORAS		INT
		
BEGIN
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA	= ISNULL(AGENDA_ID,''),
			@VFECHA_DESDE = ISNULL(AGENDA_DESDE,''),
			@VFECHA_HASTA = ISNULL(AGENDA_HASTA,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,''),
			@VALERTA = ISNULL(ALERTA_CALIF,''),
			@VCONSULTORES = ISNULL(AGENDA_CONSULTORES,''),
			@ALMACENA_HORAS = ISNULL(ALMACENA_HORAS,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
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
 
	IF (@VID_AGENDA <> '') BEGIN
						
		SELECT	@VCONSULORES_AGENDA = ID_CONSULTOR
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VID_AGENDA
	END
 
	IF (@VCONSULTORES = '') BEGIN
		SET @VTABLA = '
		<table class="w3-table w3-border w3-bordered w3-muhle-text-12">
			<tr class="w3-gray">
				<th class="w3-left"><b>Consultor</b></th>
			</tr>
			<tr><td class="w3-left">Sin Consultores</td></tr>
		</table>'
 
	END ELSE BEGIN
 
		SET @VTABLA = '
		<table class="w3-table w3-border w3-bordered w3-muhle-text-12">
			<tr class="w3-gray">
				<th class="w3-left"><b>Consultor</b></th>'
	  
		SET @VREG = 0
		SET @VDIF = DATEDIFF(DD,@VFECHA_DESDE,@VFECHA_HASTA)
		SET @VFECHA = @VFECHA_DESDE
 
		WHILE @VREG <= @VDIF  
		BEGIN 
			SET @VTABLA = @VTABLA + 
				'<th class="w3-center"><b>'+CONVERT(VARCHAR,@VFECHA,103)+'</b></th>'
 
			SET @VFECHA = DATEADD(DD,1,@VFECHA)
			SET @VREG = @VREG + 1
		END
	  
		SET @VTABLA = @VTABLA + '</tr>'
 
		WHILE LEN(@VCONSULTORES) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VCONSULTORES) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VCONSULTORES
				SET @VCONSULTORES = '' 
			END ELSE BEGIN
 
				SET @lstDato = SUBSTRING(@VCONSULTORES, 1, @lnuPosComa - 1)
 
				SELECT	@VDESCCONS = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
				FROM	LK_EMPLEADOS
				WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
				
				SET @VTABLA = @VTABLA + 
				'<tr>
					<td class="w3-left">'+@VDESCCONS+'</td>'
				
				SET @VREG = 0
				SET @VDIF = DATEDIFF(DD,@VFECHA_DESDE,@VFECHA_HASTA)
				SET @VFECHA = @VFECHA_DESDE
 
				WHILE @VREG <= @VDIF  
				BEGIN 
					
					--busco la disponibilidad horaria del consultor por fecha--
					SELECT	TOP 1 @VHORAS_DISP = ISNULL(HORAS_DISP,0)
					FROM	LK_AGENDA_EMPLEADO
					WHERE	ID_EMPLEADO = @lstDato
					AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
 
					SELECT	@VHORAS_DIA = ISNULL(SUM(HORAS),0)
					FROM	LK_AGENDA_EMPLEADO
					WHERE	ID_EMPLEADO = @lstDato
					AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
 
					SELECT	@VID_VISITA = ISNULL(PKEY,''), 
							@VHORAS_VISITA = ISNULL(HORAS,0)
					FROM	XAGENDA_VISITAS
					WHERE	PAR_KEY = @IPKEYJOB
					AND		ID_CONSULTOR = @lstDato
					AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
 
					--RECUPERO LAS HORAS DEL CONSULTOR POR FECHA PARA ESA AGENDA--
					IF (@VID_AGENDA <> '') BEGIN
						
						IF (CHARINDEX('|'+@lstDato+'|','|'+@VCONSULORES_AGENDA) > 0) BEGIN
							
							SET @VTIENE_HORAS = 0
 
							SELECT	@VTIENE_HORAS = COUNT(1)
							FROM	LK_AGENDA_EMPLEADO
							WHERE	ID_EMPLEADO = @lstDato
							AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
							AND		HOLIDAYTEXT = @VID_AGENDA
 
							IF (@VTIENE_HORAS <> 0) BEGIN
								SELECT	@VHORAS_AGENDA = ISNULL(HORAS,0)
								FROM	LK_AGENDA_EMPLEADO
								WHERE	ID_EMPLEADO = @lstDato
								AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
								AND		HOLIDAYTEXT = @VID_AGENDA
							END ELSE BEGIN
								SET @VHORAS_AGENDA = 0
							END
						
						END ELSE BEGIN
							SET @VHORAS_AGENDA = 0
						END
					END
 
					IF (@VID_AGENDA = '') BEGIN
						
						SET @VHORAS_DISP = @VHORAS_DISP - @VHORAS_DIA
 
					END ELSE BEGIN
 
						SET @VHORAS_DISP = (@VHORAS_DISP - @VHORAS_DIA) + @VHORAS_AGENDA
 
						IF (ISNULL(@VHORAS_VISITA,0) <> 0) BEGIN
							SET @ALMACENA_HORAS = ISNULL(@ALMACENA_HORAS,'') + ISNULL(@VID_VISITA,'') +'='+ ISNULL(CONVERT(VARCHAR,@VHORAS_VISITA),'0') + '|'
						END
					END
 
					SET @VTABLA = @VTABLA + 
						'<td class="w3-center">
							<span class="w3-muhle-text-12">('+ISNULL(CONVERT(VARCHAR,@VHORAS_DISP),'0')+')&nbsp;</span><input style="text-align:center" type="number" id="'+ISNULL(@VID_VISITA,'')+'" min="0" max="24" value="'+ISNULL(CONVERT(VARCHAR,@VHORAS_VISITA),'0')+'" onChange="toggleCombo(this);">
						</td>'
					
					SET @VFECHA = DATEADD(DD,1,@VFECHA)
					SET @VREG = @VREG + 1
				END
				
				SET @VTABLA = @VTABLA + '</tr>'
				SET @VCONSULTORES = SUBSTRING(@VCONSULTORES, @lnuPosComa + 1, LEN(@VCONSULTORES))
			END
			
			UPDATE	XAGENDA
			SET		ALMACENA_HORAS = @ALMACENA_HORAS
			WHERE	PAR_KEY = @IPKEYJOB
 
		END
		
		SET @VTABLA = @VTABLA + '</table>'
	END
 
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
		<li class="completed">
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
 
	SET @OFORMULARIO = 
		'<div class="w3-row-padding" style="display: flex;justify-content: center;flex-wrap: wrap;">
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
			<span class="w3-muhle-text-14"><b>Consultores</b></span>'+
				ISNULL(@VTABLA,'') +'
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
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="saveValuesCombo(''ALMACENA_HORAS'');next('''+@FORM_ID+''');return false;">Siguiente</btn>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''0DB4EC39-94DD-48DE-AAEB-6DEF2834ACBC'');return false;">Anterior</btn>
					</div>
				</div>
			</div>
		</div>
	</div>'+
	CASE WHEN (@VALERTA = 'SI') THEN
		'<script type="text/javascript">alert("Ha Seleccionado Algun Consultor que NO tiene Calificacion para Alguna de las Normas del Proyecto");</script>'
	ELSE '' END +
	'<script>var dic2=[];function toggleCombo(i){dic2[i.id]=i.value;}function saveValuesCombo(i){var a="";for(var c in dic2){a=a+c+"="+dic2[c]+"|"}almacenarSeleccion(i,a);}</script>
		<script>function iniDic(){var str = document.getElementsByName("CALL.ALMACENA_HORAS:ctl_294")[0].value;var res = str.split("|");res.forEach(func);}</script>
		<script>function func(item, index){var val = item.split("=");if (val[0]!==""){dic2[val[0]]=val[1];}}iniDic();</script>'
 
	UPDATE	XAGENDA
	SET		DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
