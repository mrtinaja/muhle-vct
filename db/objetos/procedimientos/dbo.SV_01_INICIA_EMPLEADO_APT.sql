CREATE   PROCEDURE [dbo].[SV_01_INICIA_EMPLEADO_APT]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VID_EMP_APTITUD VARCHAR(50),
		@VEMPLEADO AS VARCHAR(50),
		@VEMPLEADO_DESC AS VARCHAR(400),
		@VTIPO_SERVICIO VARCHAR(50)
 
BEGIN	
 
	SELECT	@VID_EMP_APTITUD = ISNULL(ID_EMPLE_APTITUD,''),
			@VTIPO_SERVICIO = TIPO_SERVICIO,
			@VEMPLEADO=EMPLEADO
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VEMPLEADO_DESC = ISNULL(APELLIDO_EMPLEADO,'') + ', ' + ISNULL(NOMBRE_EMPLEADO,'')
	FROM	LK_EMPLEADOS
	WHERE	ID_EMPLEADO = @VEMPLEADO
 
	IF (@VID_EMP_APTITUD <> '') BEGIN
		DELETE FROM LK_EMPLEADOS_APTITUD
		WHERE ID_EMPLE_APTITUD = @VID_EMP_APTITUD
 
		UPDATE	TMT_SV_01
		SET		ID_EMPLE_APTITUD = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	UPDATE	TMT_SV_01
	SET		--EMPLEADO = NULL,
			APTITUD = NULL,
			CALIFICACION = NULL,
			OBSERVACION = NULL,
			CLAVE = NULL,
			ERROR = NULL,
			DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users fa-fw w3-large"></i>&nbsp;&nbsp;Empleado Aptitudes</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''1085F118-8FDD-4D38-8AE4-BD8D52BF0928'');return false;"></i></span>'+
					CASE WHEN ISNULL(@VEMPLEADO,'') = '' THEN '' ELSE
						'<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fa fa-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" onclick="goto('''+@FORM_ID+''',''F4604538-20F1-4237-8139-AF3F712C6C92'');return false;"></i></span>'
					END + '
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round">
					<div class="w3-container w3-white w3-padding w3-round-up">
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Empleado/Consultor</label>
							<select class="w3-input w3-round w3-border w3-muhle-text-12" id="cmb1_'+@FORM_ID+'" name="SP.EMPLEADO" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''9459491E-DDC8-4DDF-A765-1122AAA3955E'', '''',this.id);goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;">
							</select>
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-cogs"></i>&nbsp;&nbsp;Servicio</label>
							<select class="w3-input w3-round w3-border w3-muhle-text-12" id="cmb2_'+@FORM_ID+'" name="SP.TIPO_SERVICIO" onchange="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;"></select>
						</div>
						<div class="w3-col m1 w3-padding-small">
							<br>
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''CE208ACC-D843-473E-94F8-4F5DF9353A2D'', '''+isnull(@VEMPLEADO,'')+''', '''');</script>'+
	CASE WHEN ISNULL(@VEMPLEADO,'') = '' THEN '' ELSE
		'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''9459491E-DDC8-4DDF-A765-1122AAA3955E'', '''+isnull(@VTIPO_SERVICIO,'')+''', '''+isnull(@VEMPLEADO,'')+''');</script>' 
	END +
	'<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round w3-padding">'+
				CASE WHEN @VEMPLEADO <> '' THEN
					'<div class="w3-bar w3-muhle-color w3-round w3-padding">
						<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-user fa-fw w3-large"></i>&nbsp;&nbsp;'+ISNULL(@VEMPLEADO_DESC,'')+'</span>
					</div>
					<div class="w3-container" style="padding:4px;"></div>
					<div class="w3-container" style="padding:4px;border-top:1px solid;border-color:gray;"></div>'
				ELSE '' END
					
 
	--SET @OHEADER = '
	--<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--	<div class="w3-bar w3-round-up">
	--		<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-users fa-fw w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Empleado Aptitudes</span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''1085F118-8FDD-4D38-8AE4-BD8D52BF0928'');return false;"></i></span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fa fa-plus w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''F4604538-20F1-4237-8139-AF3F712C6C92'');return false;"></i></span>
	--	</div>
	--</div>
	--<div>&nbsp</div>
	--<div class="w3-bar w3-grey">
	--<div class="w3-bar-item w3-grey"><b>Empleado/Consultor:</b></div><select class="w3-bar-item w3-grey" id="cmb1_'+@FORM_ID+'" name="SP.EMPLEADO" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''9459491E-DDC8-4DDF-A765-1122AAA3955E'', '''',this.id);"></select>'+
	--'<div class="w3-bar-item w3-grey"><b>Servicio:</b></div><select class="w3-bar-item w3-grey" id="cmb2_'+@FORM_ID+'" name="SP.TIPO_SERVICIO"></select>'+
	--+'<a class="w3-bar-item w3-button w3-grey w3-right" href="javascript:goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');"><i class="fa fa-search"></i></a>
 -- </div><script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''CE208ACC-D843-473E-94F8-4F5DF9353A2D'', '''+isnull(@VEMPLEADO,'')+''', '''');</script>'+
	--CASE WHEN ISNULL(@VEMPLEADO,'') = '' THEN '' ELSE
	--	'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''9459491E-DDC8-4DDF-A765-1122AAA3955E'', '''+isnull(@VTIPO_SERVICIO,'')+''', '''+isnull(@VEMPLEADO,'')+''');</script>' 
	--END
 
END
 
