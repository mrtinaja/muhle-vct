CREATE PROCEDURE [dbo].[HOME_INI_AGENDA_PASO5]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX)	OUTPUT,
 @OPASOS	AS VARCHAR(MAX)	OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO1 AS VARCHAR(MAX) OUTPUT)
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
		@VTABLA2			VARCHAR(MAX),
		@VDIF				INT,
		@VREG				INT,
		@VFECHA				DATETIME,
		@VDESCCONS			VARCHAR(400),
		@VHORAS_DISP		INT,
		@VHORAS_DIA			INT,
		@ALMACENA_HORAS		VARCHAR(4000),
		@VID_VISITA			VARCHAR(100),
		@VHORAS_VISITA		NUMERIC(5),
		@VNORMAS_PROY		VARCHAR(400),
		@VNORMAS			VARCHAR(400),
		@VDATO				VARCHAR(MAX),
		@VESTADO_PROY		VARCHAR(100),
		@VOBSERVACIONES		VARCHAR(400),
		@VOBS_CALIF			VARCHAR(400),
		--@VOBS_LOGIS			VARCHAR(400),
		@VPREVIAS			VARCHAR(400),
		@VNORMAS_PREVIAS	VARCHAR(400),
		@RESULTADO			VARCHAR(400),
		@VSELECCION			VARCHAR(MAX),
		@VESTADO			VARCHAR(100)
		
BEGIN
 
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	=	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA		= ISNULL(AGENDA_ID,''),
			@VFECHA_DESDE	= ISNULL(AGENDA_DESDE,''),
			@VFECHA_HASTA	= ISNULL(AGENDA_HASTA,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VCONSULTORES	= ISNULL(AGENDA_CONSULTORES,''),
			@VBUFFER		= ISNULL(LIDER,''),
			@VNORMAS		= ISNULL(AGENDA_NORMA,''),
			@VESTADO_PROY	= ISNULL(AGENDA_ESTADO,''),
			@VOBSERVACIONES = ISNULL(AGENDA_OBSERVADOR,''),
			@VOBS_CALIF		= ISNULL(AGENDA_OBSERV_CALIF,'')
			--@VOBS_LOGIS = ISNULL(AGENDA_OBSERV_LOGIS,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	 --linea 
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
 
	IF (@VID_SERVICIO <> '') BEGIN
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
	END
 
	IF (@VID_AGENDA <> '' AND @VDESC_ERROR = '') BEGIN
 
		SELECT	@VPREVIAS = LIDER, 
				@VNORMAS_PREVIAS = NORMA,
				@VESTADO = ISNULL(ESTADO,''),
				@VOBSERVACIONES = ISNULL(OBSERVADOR,''),
				--@VOBS_LOGIS = ISNULL(OBSERV_LOGISTICA,''),
				@VOBS_CALIF = ISNULL(OBSERV_CALIF,'')
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VID_AGENDA
 
		UPDATE	XAGENDA
		SET		LIDER = @VPREVIAS, AGENDA_NORMA = @VNORMAS_PREVIAS, AGENDA_ESTADO = @VESTADO, AGENDA_OBSERVADOR = @VOBSERVACIONES, /*AGENDA_OBSERV_LOGIS = @VOBS_LOGIS,*/ AGENDA_OBSERV_CALIF = @VOBS_CALIF
		WHERE	PAR_KEY = @IPKEYJOB
 
		WHILE PATINDEX('%|%',@VPREVIAS)>0
		BEGIN
			SET	 @RESULTADO = PATINDEX('%|%',@VPREVIAS) --+ @N
			SET  @VALOR = SUBSTRING(@VPREVIAS,1, @RESULTADO-1)
			
			SET @VSELECCION = ISNULL(@VSELECCION,'') + @VALOR + '=true|'
		
			SELECT @VPREVIAS = RIGHT(@VPREVIAS,LEN(@VPREVIAS)-PATINDEX('%|%',@VPREVIAS))
		END
 
		--GRABO SELECCION DE LIDERES--
		UPDATE	XAGENDA
		SET		ACUMULA = @VSELECCION
		WHERE	PAR_KEY = @IPKEYJOB
 
		WHILE PATINDEX('%|%',@VNORMAS_PREVIAS)>0
		BEGIN
			SET	 @RESULTADO = PATINDEX('%|%',@VNORMAS_PREVIAS) --+ @N
			SET  @VALOR = SUBSTRING(@VNORMAS_PREVIAS,1, @RESULTADO-1)
			
			SET @VSELECCION = ISNULL(@VSELECCION,'') + @VALOR + '=true|'
		
			SELECT @VNORMAS_PREVIAS = RIGHT(@VNORMAS_PREVIAS,LEN(@VNORMAS_PREVIAS)-PATINDEX('%|%',@VNORMAS_PREVIAS))
		END
 
		--GRABO SELECCION DE LIDERES--
		UPDATE	XAGENDA
		SET		AGENDA_NORMAS = @VSELECCION
		WHERE	PAR_KEY = @IPKEYJOB
 
		SELECT	@VBUFFER = ISNULL(LIDER,''),
				@VNORMAS = ISNULL(AGENDA_NORMA,''),
				@VESTADO_PROY = ISNULL(AGENDA_ESTADO,''),
				@VOBSERVACIONES = ISNULL(AGENDA_OBSERVADOR,''),
				@VOBS_CALIF = ISNULL(AGENDA_OBSERV_CALIF,'')
				--@VOBS_LOGIS = ISNULL(AGENDA_OBSERV_LOGIS,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
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
		--'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_EMPLEADO)+'"'+CASE WHEN ([dbo].[FN_GET_NORMA](@vbuffer,ID_EMPLEADO) = 'SI') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">'
		SET @VTABLA = '
		<table class="w3-table w3-border w3-bordered w3-muhle-text-12">
			<tr class="w3-gray">
				<th class="w3-left"><b>Consultor</b></th>
				<th class="w3-center"><b>Lider</b></th>'
	  
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
					<td class="w3-left">'+@VDESCCONS+'</td>
					<td class="w3-center" ><input type="checkbox" id="'+@lstDato+'"'+CASE WHEN ([dbo].[FN_GET_NORMA](@VBUFFER,@lstDato) = 'SI') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);"></td>'
				
				SET @VREG = 0
				SET @VDIF = DATEDIFF(DD,@VFECHA_DESDE,@VFECHA_HASTA)
				SET @VFECHA = @VFECHA_DESDE
 
				WHILE @VREG <= @VDIF  
				BEGIN 
 
					SELECT	@VHORAS_VISITA = ISNULL(HORAS,0)
					FROM	XAGENDA_VISITAS
					WHERE	PAR_KEY = @IPKEYJOB
					AND		ID_CONSULTOR = @lstDato
					AND		FECHA = CONVERT(VARCHAR,@VFECHA,23)
 
					SET @VTABLA = @VTABLA + 
						'<td class="w3-center">
							'+CONVERT(VARCHAR,@VHORAS_VISITA)+'
						</td>'
					
					SET @VFECHA = DATEADD(DD,1,@VFECHA)
					SET @VREG = @VREG + 1
				END
				
				SET @VTABLA = @VTABLA + '</tr>'
				SET @VCONSULTORES = SUBSTRING(@VCONSULTORES, @lnuPosComa + 1, LEN(@VCONSULTORES))
			END	
		END
		
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	SET @VTABLA2 = '
		<table class="w3-table w3-border w3-bordered w3-muhle-text-12">
			<tr class="w3-gray"><th></th></tr>'
 
	DECLARE Normas CURSOR FOR
	SELECT	'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_APTITUD)+'"'+CASE WHEN ([dbo].[FN_GET_NORMA](ISNULL(@VNORMAS,''),ID_APTITUD) = 'SI') THEN ' checked="true"' ELSE '' END +'	 onchange="toggleCheckbox2(this);">' + ' '+
			ISNULL(DESC_APTITUD,'')
	FROM	LK_APTITUDES
	WHERE	[dbo].[FN_GET_NORMA](@VNORMAS_PROY,ID_APTITUD) = 'SI'
 
	OPEN Normas
	FETCH NEXT FROM Normas INTO @VDATO
	
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VTABLA2 = @VTABLA2 + 
				'<tr>
					<td class="w3-left">'+@VDATO+'</td>
				</tr>'
 
			FETCH NEXT FROM Normas INTO @VDATO
		END 
 
	CLOSE Normas  
	DEALLOCATE Normas
	
	SET @VTABLA2 = @VTABLA2 + '</table>'
 
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
        <li class="completed">
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
		<div class="w3-row w3-topbar"></div><div class="w3-container" style="padding:4px;"></div>
		<div class="w3-row-padding">
			<div class="w3-row w3-half">
				<div class="w3-container">
					<span class="w3-muhle-text-14"><b>Consultores</b></span>'+
						ISNULL(@VTABLA,'') +'
				</div>	
			</div>
			<div class="w3-row w3-half">
				<div class="w3-container">
					<span class="w3-muhle-text-14"><b>Normas</b></span>'+
						ISNULL(@VTABLA2,'') +'
				</div>	
			</div>
		</div>'+'
		<div class="w3-container" style="padding:4px;"></div><div class="w3-row w3-topbar"></div><div class="w3-container" style="padding:4px;"></div>
		<div class="w3-row-padding">
			<div class="w3-col m4 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado</label>
				<select class="w3-input w3-border w3-round" id="cmb1" name="SP.AGENDA_ESTADO"></select>
			</div>
			<div class="w3-col m8 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones&nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-round" type="text" name="SP.AGENDA_OBSERVADOR" value="'+ISNULL(@VOBSERVACIONES,'')+'">
			</div>
			<div>&nbsp;</div>'+
			--<div class="w3-row">
			--	<label>&nbsp;<i class="fas fa-list-alt"></i>&nbsp;&nbsp;Observacion Logistica&nbsp;&nbsp;</label>
			--	<input class="w3-input w3-border w3-round" type="text" name="SP.AGENDA_OBSERV_LOGIS" value="'+ISNULL(@VOBS_LOGIS,'')+'">
			--</div>
			--<div>&nbsp;</div>
			'<div class="w3-col m12 w3-padding-small">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Observacion Calificacion&nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-round" type="text" name="SP.AGENDA_OBSERV_CALIF" value="'+ISNULL(@VOBS_CALIF,'')+'">
			</div>
		</div>'
		+CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
			'<div>&nbsp;</div>'
		ELSE 
			'<div class="w3-panel w3-pale-red" style="height: 20px;">
				<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
				</div>' 
		END + '
		<div class="w3-row w3-topbar">&nbsp;</div>
				<div class="w3-row">
					<div class="w3-container">
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="saveValues2(''AGENDA_NORMAS'');saveValues(''ACUMULA'');next('''+@FORM_ID+''');return false;">Grabar</btn>
						<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''FE506C41-FD75-4B6C-A242-C7C5708716E0'');return false;">Anterior</btn>
					</div>
				</div>
			</div>
		</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '260022DF-4FC1-4944-809E-BC3834834FD1' + ''', ''' + ISNULL(@VESTADO_PROY,'') +''', '''');</script>'
 
	UPDATE	XAGENDA
	SET		DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
