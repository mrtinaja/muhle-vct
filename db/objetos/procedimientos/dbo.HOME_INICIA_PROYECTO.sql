CREATE PROCEDURE [dbo].[HOME_INICIA_PROYECTO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO2 AS VARCHAR(MAX) OUTPUT)
AS
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VERROR			VARCHAR(50),
		@VDESC_ERROR	VARCHAR(4000),
		@lnuPosComa		INT,
		@lstDato		VARCHAR(400)
 
/*DATOS CONTROL DE FLUJO*/
DECLARE @HTML_RETURN_PAGE_CODE VARCHAR(100)
 
/*DATOS FORMULARIO*/
DECLARE @VID_PROYECTO		VARCHAR(100),
		@VCLIENTE_ID_TMT	VARCHAR(100),
		@VNOMBRE_PROY_TMT	VARCHAR(400),
		@VCODIGO_PROY_TMT	VARCHAR(100),
		@VFECHA_INIT_TMT	DATETIME,
		@VFECHA_FIN_TMT		DATETIME,
		@VNRO_COTIZA_TMT	VARCHAR(100),
		@VHORAS_PROY_TMT	VARCHAR(100),
		@VMONTO_PROY_TMT	VARCHAR(100),
		@VESTADO_PROY_TMT	VARCHAR(100),
		@VNORMAS_TMT		VARCHAR(400),
		@VAUDITORIA_TMT		VARCHAR(50),
		@VCAPACITACION_TMT	VARCHAR(50),
		@VCONSULTORIA_TMT	VARCHAR(50),
		@VCONTACTO_TMT		VARCHAR(400),
		@VOBSERVACIONES_TMT VARCHAR(4000),
		@VNIVEL_RIESGO_TMT	VARCHAR(50)
 
DECLARE	@VCLIENTE_ID	VARCHAR(100),
		@VNOMBRE_PROY	VARCHAR(400),
		@VCODIGO_PROY	VARCHAR(100),
		@VFECHA_INIT	DATETIME,
		@VFECHA_FIN		DATETIME,
		@VNRO_COTIZA	VARCHAR(100),
		@VHORAS_PROY	VARCHAR(100),
		@VMONTO_PROY	VARCHAR(100),
		@VESTADO_PROY	VARCHAR(100),
		@VNORMAS		VARCHAR(400),
		@VAUDITORIA		VARCHAR(50),
		@VCAPACITACION	VARCHAR(50),
		@VCONSULTORIA	VARCHAR(50),
		@VCONTACTO		VARCHAR(400),
		@VOBSERVACIONES VARCHAR(4000),
		@VNIVEL_RIESGO	VARCHAR(50)
 
DECLARE @HTML_PAGE		VARCHAR(MAX)
DECLARE @HTML_SCRIPT	VARCHAR(2000)
DECLARE @HTML_TITULO	VARCHAR(100)
/*ARMADO CURSOR DE NORMAS*/
DECLARE @HTML_NORMAS	VARCHAR(MAX)
DECLARE @c_id			VARCHAR(100)
DECLARE @c_desc			VARCHAR(100)
 
BEGIN	
 
	SET @HTML_RETURN_PAGE_CODE = '522967A7-DDC9-465B-969B-85997AE1B085'
 
	/*RECUPERAR INFOMACION BUFFER*/
	SELECT	@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VCLIENTE_ID_TMT	= ISNULL(CLIENTE,''),
			@VNOMBRE_PROY_TMT	= ISNULL(NOMBRE_PROY,''),
			@VCODIGO_PROY_TMT	= ISNULL(CODIGO_PROY,''),
			@VFECHA_INIT_TMT	= ISNULL(FECHA_INICIO_PROY,''),
			@VFECHA_FIN_TMT		= ISNULL (FECHA_FIN_PROY,'') ,
			@VNRO_COTIZA_TMT	= ISNULL(NRO_COTIZA,'') ,
			@VHORAS_PROY_TMT	= ISNULL(HORAS_PROY,'') ,
			@VMONTO_PROY_TMT	= ISNULL(MONTO_PROY,''),
			@VESTADO_PROY_TMT	= ISNULL(ESTADO_PROY,''),
			@VCONSULTORIA_TMT	= ISNULL(SERV_CONS_PROY,'0'),
			@VAUDITORIA_TMT		= ISNULL(SERV_AUDI_PROY,'0'),
			@VCAPACITACION_TMT	= ISNULL(SERV_CAPA_PROY,'0'),
			--@VNORMAS_TMT		= ISNULL(BUFFER,''), 
			@VCONTACTO_TMT		= ISNULL(CONTACTO_PROY,''),
			@VOBSERVACIONES_TMT =  ISNULL(OBSERV_PROY,''),
			@VNIVEL_RIESGO_TMT	= ISNULL(NIVEL_RIESGO,''),
			@VERROR				= ISNULL(ERROR,''),
			@VDESC_ERROR		= ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	--LIMPIO EL BUFFER POR SI VIENE DE OTRA PANTALLA QUE LO USA--
	UPDATE	XAGENDA SET BUFFER = NULL WHERE PAR_KEY = @IPKEYJOB
 
	--agrego para cargar el codigo de proyecto nuevo por default--
	IF (@VID_PROYECTO = '') BEGIN
		
		SELECT	@VCODIGO_PROY_TMT = ATTR1 + 1
		FROM	CAT_DATA
		WHERE	PAR_KEY = '0000000280_98'
		AND		CAT_DATA_CODE = 'PROYECTO_KEY'
 
	END
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_PROYECTO <> '') BEGIN
 
		/*Setea el return del boton de volver*/
		SET @HTML_RETURN_PAGE_CODE = '40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'
 
		SELECT	@VCLIENTE_ID	= ISNULL(CONVERT(VARCHAR,ID_CLIENTE),''),
				@VNOMBRE_PROY	= ISNULL(NORMA_REF,''),
				@VCODIGO_PROY	= ISNULL(CODIGO,''),
				@VNRO_COTIZA	= ISNULL(CONVERT(VARCHAR,ID_COTIZACION),''),
				@VFECHA_INIT	= ISNULL(FECHA_INICIO_REAL,''),
				@VFECHA_FIN		= ISNULL(FECHA_FIN_REAL,''),
				@VHORAS_PROY	= ISNULL(CONVERT(VARCHAR,TOTAL_HORAS_PROYECTADAS),'0'),
				@VMONTO_PROY	= ISNULL(CONVERT(VARCHAR,MONTO_PRESUP),'0'),
				@VNORMAS		= ISNULL(NORMAS,''),
				@VESTADO_PROY	= ISNULL(ESTADO_PROYECTO_TOTAL,''),
				@VCONTACTO		= ISNULL(CONTACTO,''),
				@VOBSERVACIONES = ISNULL(OBSERVACIONES,''),
				@VNIVEL_RIESGO	= ISNULL(NIVEL_RIESGO,'')
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
		SELECT	@VCONSULTORIA = CASE WHEN ISNULL(ID_TIPO_SERVICIO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
		AND		ID_TIPO_SERVICIO = '1'
 
		SELECT	@VAUDITORIA = CASE WHEN ISNULL(ID_TIPO_SERVICIO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
		AND		ID_TIPO_SERVICIO = '2'
 
		SELECT	@VCAPACITACION = CASE WHEN ISNULL(ID_TIPO_SERVICIO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
		AND		ID_TIPO_SERVICIO = '3'
		
	END
 
	IF (@VID_PROYECTO <> '' AND @VDESC_ERROR = '') BEGIN
		SET @VCLIENTE_ID_TMT	= @VCLIENTE_ID
		SET @VNOMBRE_PROY_TMT	= @VNOMBRE_PROY
		SET @VCODIGO_PROY_TMT	= @VCODIGO_PROY
		SET @VFECHA_INIT_TMT	= @VFECHA_INIT
		SET @VFECHA_FIN_TMT		= @VFECHA_FIN
		SET @VNRO_COTIZA_TMT	= @VNRO_COTIZA
		SET @VHORAS_PROY_TMT	= @VHORAS_PROY
		SET @VMONTO_PROY_TMT	= @VMONTO_PROY
		SET @VESTADO_PROY_TMT	= @VESTADO_PROY
		SET @VCONSULTORIA_TMT	= @VCONSULTORIA
		SET @VAUDITORIA_TMT		= @VAUDITORIA
		SET @VCAPACITACION_TMT	= @VCAPACITACION
		--SET @VNORMAS_TMT		= @VNORMAS 
		SET @VCONTACTO_TMT		= @VCONTACTO
		SET @VOBSERVACIONES_TMT = @VOBSERVACIONES
		SET @VNIVEL_RIESGO_TMT	= @VNIVEL_RIESGO
 
		WHILE LEN(@VNORMAS) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VNORMAS
				SET @VNORMAS = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
				SET @VNORMAS_TMT = ISNULL(@VNORMAS_TMT,'') + @lstDato + '=true|'
 
				SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
			END
		END
 
		UPDATE	XAGENDA
		SET		BUFFER = @VNORMAS_TMT
		WHERE	PAR_KEY = @IPKEYJOB
	END
		
	DECLARE LIST_NORMAS cursor for 
		SELECT	ID_APTITUD,DESC_APTITUD 
		FROM	LK_APTITUDES 
		WHERE	STATUS_APTITUD = 1 
		ORDER BY ID_APTITUD
 
	OPEN LIST_NORMAS	
	FETCH NEXT FROM LIST_NORMAS INTO @c_id,@c_desc
 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @HTML_NORMAS = CONCAT(@HTML_NORMAS,'<li><input name="BUFFER" type="checkbox" id="'+@c_id+'" '+ CASE WHEN ([dbo].[FN_GET_NORMA2](@VNORMAS_TMT,CONVERT(INT,@c_id)) = 'true') THEN 'checked="true"' ELSE '' END + ' onchange="toggleCheckbox(this);">&nbsp;&nbsp;'+@c_desc+'</li>'+ CHAR(13)+CHAR(10))
		FETCH NEXT FROM LIST_NORMAS INTO @c_id,@c_desc
	END
 
	CLOSE LIST_NORMAS  
	DEALLOCATE LIST_NORMAS
	/******************************/
 
	UPDATE	XAGENDA
	SET		CODIGO_PROY = @VCODIGO_PROY_TMT
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-project-diagram w3-large"></i>&nbsp;&nbsp;Proyectos</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''','''+@HTML_RETURN_PAGE_CODE+''');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	--SET @OHEADER = 
	--'<div class="w3-row w3-back w3-light-grey">
	--	<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--		<div class="w3-bar w3-round-up">
	--			<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fas fa-project-diagram w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Proyecto</span>
	--			<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''','''+@HTML_RETURN_PAGE_CODE+''');return false;"></i></span>
	--		</div>
	--	</div>
	--</div>
	--<div class="w3-container" style="padding:4px;"></div>'
 
	SET @OFORMULARIO = '		
					<div class="w3-row-padding">
						<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_PROYECTO = '' THEN 'Nuevo Proyecto' ELSE 'Modificar Proyecto' END+'</b></span>
						<div class="w3-row w3-bottombar"></div>
						<div class="w3-col m6 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-id-badge"></i>&nbsp;&nbsp;Cliente&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1_'+@FORM_ID+'" name="SP.CLIENTE" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_COTIZACIONES'', '''',this.id);"></select>		
						</div>
						<div class="w3-col m6 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Nombre Proyecto&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NOMBRE_PROY" value="'+@VNOMBRE_PROY_TMT+'">		
						</div>
					</div>
					<div class="w3-row-padding">
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-barcode"></i>&nbsp;&nbsp;Código Proyecto</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CODIGO_PROY" value="'+@VCODIGO_PROY_TMT+'" disabled>
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Inicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_INICIO_PROY" value="'+CASE WHEN ISNULL(@VFECHA_INIT_TMT,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_INIT_TMT,23) END+'">		
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-calendar"></i>&nbsp;&nbsp;Fecha Fin&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_FIN_PROY" value="'+CASE WHEN ISNULL(@VFECHA_FIN_TMT,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_FIN_TMT,23) END+'">		
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-hashtag"></i>&nbsp;&nbsp;Nro Cotización</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2_'+@FORM_ID+'" name="SP.NRO_COTIZA"></select>		
						</div>
					</div>
					<div class="w3-row-padding">
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Horas Proyecto&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number" name="SP.HORAS_PROY" value="'+@VHORAS_PROY_TMT+'">		
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Monto Proyecto</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number" name="SP.MONTO_PROY" value="'+@VMONTO_PROY_TMT+'">		
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-id-badge"></i>&nbsp;&nbsp;Estado</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.ESTADO_PROY"></select>		
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-barcode"></i>&nbsp;&nbsp;Nivel Riesgo</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" name="SP.NIVEL_RIESGO">
								<option value=""></option>
								<option value="Alto" '+CASE WHEN isnull(@VNIVEL_RIESGO_TMT,'') = 'Alto' THEN 'selected="selected"' ELSE '' END+'>Alto</option>
								<option value="Medio" '+CASE WHEN isnull(@VNIVEL_RIESGO_TMT,'') = 'Medio' THEN 'selected="selected"' ELSE '' END+'>Medio</option>
								<option value="Bajo" '+CASE WHEN isnull(@VNIVEL_RIESGO_TMT,'') = 'Bajo' THEN 'selected="selected"' ELSE '' END+'>Bajo</option>
							</select>
						</div>
					</div>
					<div class="w3-row-padding">
						<div class="w3-col m6 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Contacto&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CONTACTO_PROY" value="'+@VCONTACTO_TMT+'">		
						</div>
						<div class="w3-col m6 w3-padding-small">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user-tie"></i>&nbsp;&nbsp;Analista a Cargo</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.OBSERV_PROY" value="'+@VOBSERVACIONES_TMT+'">		
						</div>
					</div>'
 
	SET @OFORMULARIO2 = CAST('' AS VARCHAR(MAX)) + '
		<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>
		<div class="w3-row-padding">
			<span class="w3-muhle-text-20 w3-left"><b>Servicios</b></span>
		</div>
		<div id="menuCheck">  
			<div class="w3-third w3-muhle-text-14 w3-padding">
				<label>
					<input type="hidden" name="SP.SERV_CONS_PROY" value="'+ISNULL(@VCONSULTORIA_TMT,'')+'">
					<input type="checkbox" class="w3-check w3-muhle-text-14 '+CASE WHEN @VID_PROYECTO <> '' THEN 'w3-disabled' ELSE '' END + '"  '+CASE WHEN @VCONSULTORIA_TMT = '1' THEN 'checked="true"' ELSE '' END+' onchange="saveCheckBoxValue(this, ''SP.SERV_CONS_PROY'');">&nbsp;&nbsp;Servicio Consultoria
				</label>
			</div>
			<div class="w3-third w3-muhle-text-14 w3-padding">
				<label>
					<input type="hidden" name="SP.SERV_AUDI_PROY" value="'+ISNULL(@VAUDITORIA_TMT,'')+'">
					<input type="checkbox" class="w3-check w3-muhle-text-14 '+CASE WHEN @VID_PROYECTO <> '' THEN 'w3-disabled' ELSE '' END + '"  '+CASE WHEN @VAUDITORIA_TMT = '1' THEN 'checked="true"' ELSE '' END+' onchange="saveCheckBoxValue(this, ''SP.SERV_AUDI_PROY'')";>&nbsp;&nbsp;Servicio Auditoria
				</label>
			</div>
			<div class="w3-third w3-muhle-text-14 w3-padding">
				<label>
					<input type="hidden" name="SP.SERV_CAPA_PROY" value="'+ISNULL(@VCAPACITACION_TMT,'')+'">
					<input type="checkbox" class="w3-check w3-muhle-text-14 '+CASE WHEN @VID_PROYECTO <> '' THEN 'w3-disabled' ELSE '' END + '"  '+CASE WHEN @VCAPACITACION_TMT = '1' THEN 'checked="true"' ELSE '' END+' onchange="saveCheckBoxValue(this, ''SP.SERV_CAPA_PROY'');">&nbsp;&nbsp;Servicio Capacitación
				</label>
			</div>
		</div>
		<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>
		<div class="w3-card">
			<header class="w3-container w3-btn w3-block w3-left-align w3-muhle-color w3-muhle-text-20 w3-padding" style="color:white" onclick="toggleHeader(''tableHeader_GRILLA_NORMAS'')">
			   <span class="w3-left">Normas&nbsp;<i class="fa fa-caret-down"></i></span>
			</header>
			<div class="w3-hide" id="tableHeader_GRILLA_NORMAS">
			   <input class="w3-input w3-muhle-text-14 w3-border" type="text" placeholder="Buscar.." id="input_GRILLA_NORMAS" onkeyup="filterList(''input_GRILLA_NORMAS'', ''table_GRILLA_NORMAS'')">
			   <ul id="table_GRILLA_NORMAS" class="w3-ul w3-card-4 w3-bar w3-muhle-text-14">
				 '+ISNULL(@HTML_NORMAS,'')+'
			   </ul>
			</div>
		 </div>'
 
	SET @OFOOTER =	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height:20px;">
							<span class="w3-left w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="saveValues(''BUFFER'');next('''+@FORM_ID+''');return false;">'+CASE WHEN (@VID_PROYECTO <> '') THEN 'Modificar' ELSE 'Agregar' END+'</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''','''+@HTML_RETURN_PAGE_CODE+''');return false;">Cancelar</btn>
						</div>
					</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_CLIENTES'', '''+isnull(@VCLIENTE_ID_TMT,'')+''', '''');</script>'+
	CASE WHEN ISNULL(@VCLIENTE_ID,'') = '' THEN '' ELSE
		'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_COTIZACIONES'', '''+isnull(@VNRO_COTIZA_TMT,'')+''', '''+isnull(@VCLIENTE_ID_TMT,'')+''');</script>' 
	END+
	'<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '3C2B554E-4339-4492-90D3-AE93773FB5D1' + ''', ''' + ISNULL(@VESTADO_PROY_TMT,'') +''', '''');</script>
	 <script>var dic=[];function toggleCheckbox(i){ dic[i.id]=i.checked;saveValues(i.name)}function saveValues(name){var a="";for(var c in dic){a=a+c+"="+dic[c]+"|"}saveSelection(name,a)}</script>
	 <script>function iniDic(){var str = document.getElementsByName("CALL.BUFFER:ctl_7")[0].value;var res = str.split("|");res.forEach(func);}</script>
	 <script>function func(item, index){var val = item.split("=");if (val[0]!==""){dic[val[0]]=val[1];}}iniDic();</script>'
 
END
 
