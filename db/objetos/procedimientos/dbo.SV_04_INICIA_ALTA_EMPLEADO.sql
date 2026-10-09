CREATE PROCEDURE [dbo].[SV_04_INICIA_ALTA_EMPLEADO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @PS_TITULO		AS VARCHAR(MAX) OUTPUT,
 @PS_FORMULARIO  AS VARCHAR(MAX) OUTPUT,
 @PS_FORMU_FOOT  AS VARCHAR(MAX) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@CV_PKEY as varchar(36)
 
DECLARE	@VAPELLIDO	AS VARCHAR(100),
		@VNOMBRE	AS VARCHAR(100),
		@VTIPO_DOC	AS VARCHAR(12),
		@VNRO_DOC	AS VARCHAR(50),
		@VCUIT		AS VARCHAR(50),
		@VINGRESO	AS VARCHAR(50),
		@VUSUARIO	AS VARCHAR(50),	
		@VCLAVE AS VARCHAR(100),
		@VCALLE AS VARCHAR(100),
		@VPISO as VARCHAR(100),
	    @VNRO AS VARCHAR(100),
		@VLOCALIDAD AS VARCHAR(100),
		@VPROVINCIA AS VARCHAR(100),
		@VTELEFONO1 AS VARCHAR(100),
		@VTELEFONO2 AS VARCHAR(100),
		@VEMAIL AS VARCHAR(100),
		@VPERFIL AS VARCHAR(100),
		@VAUDITORIA	 AS	VARCHAR(50),
		@VCAPACITACION	AS VARCHAR(50), 
		@VCONSULTORIA	AS VARCHAR(50),
		@VESTADO		AS VARCHAR(50),
		@VEVENTUAL AS VARCHAR(50),
		@VFORMACION AS VARCHAR(50),
		@VMOVILIDAD  AS VARCHAR(50),
		@VDIAS as varchar(50),
 
		@VID_SELEC as varchar(50),
		@VERROR AS VARCHAR(100),
		@VCOD_ACCION_MENU  AS VARCHAR(50),
		@VDESC_ERROR	VARCHAR(4000)
 
 
DECLARE @HTML_ADJCV VARCHAR(MAX) SET @HTML_ADJCV = '';
DECLARE @HTML_BUTTONS VARCHAR(MAX) SET @HTML_BUTTONS = '';
DECLARE @HTML_SCRIPTS VARCHAR(MAX) SET @HTML_SCRIPTS = '';
DECLARE @HTML_DISABLE VARCHAR(100) SET @HTML_DISABLE ='';	
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
	
	SELECT @VCOD_ACCION_MENU = COD_ACCION_MENU FROM TMT_SV_04 WHERE	PAR_KEY = @IPKEYJOB
 
	/*RECUPERO INFO BUFFER TMT*/
	SELECT	@VNOMBRE = ISNULL(NOMBRE,''),
			@VAPELLIDO = ISNULL(APELLIDO,''),
			@VTIPO_DOC = ISNULL(TIPO_DOC,''),
			@VNRO_DOC = ISNULL(NRO_DOC,''),
			@VCUIT = ISNULL(CUIT,''),
			@VINGRESO = ISNULL(INGRESO,''),
			@VUSUARIO = ISNULL(USUARIO,''),
			@VCLAVE = ISNULL(CLAVE,''),			
			@VCALLE = ISNULL(CALLE,''),
			@VNRO = ISNULL(NRO,''),
			@VPISO = ISNULL(PISO,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD,''),
			@VPROVINCIA = ISNULL(PROVINCIA,''),
			@VTELEFONO1 = ISNULL(TELEFONO1,''),
			@VTELEFONO2 = ISNULL(TELEFONO2,''),
			@VEMAIL = ISNULL(EMAIL,''),
			@VFORMACION = ISNULL(FORMACION,''),
			@VMOVILIDAD = ISNULL(MOVILIDAD,''),
			@VPERFIL = ISNULL(PERFIL,''),
			@VAUDITORIA = ISNULL(CONS_TIPO_AUDI,'0'),
			@VCAPACITACION = ISNULL(CONS_TIPO_CAPA,'0'),
			@VCONSULTORIA = ISNULL(CONS_TIPO_CONS,'0'),
			@VESTADO = ISNULL(ESTADO,''),
			@VERROR = ISNULL(ERROR,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,''),
			@VDIAS = ISNULL(DIAS_MENSUALES,'0'),
			@VID_SELEC = ISNULL(ID_SELEC,''),
			@VEVENTUAL = ISNULL(EVENTUAL,'')
	FROM	TMT_SV_04
	WHERE	PAR_KEY = @IPKEYJOB
 
 
	/*Recupero informacion de contacto en caso de ser una actualizacion*/
	IF (@VCOD_ACCION_MENU = 'UPDATE' AND @VERROR = '' ) BEGIN
		SELECT	@VNOMBRE = ISNULL(NOMBRE_EMPLEADO,''),
			@VAPELLIDO = ISNULL(APELLIDO_EMPLEADO,''),
			@VTIPO_DOC = ISNULL(TIPO_DOC_EMP,''),
			@VNRO_DOC = ISNULL(NRO_DOC_EMP,''),
			@VCUIT = ISNULL(CUIT_EMP,''),
			@VINGRESO = ISNULL(INGRESA_SISTEMA,''),
			@VUSUARIO = ISNULL(USUARIO_EMP,''),
			@VCLAVE = ISNULL(PASS_EMP,''),			
			@VCALLE = ISNULL(CALLE_EMP,''),
			@VNRO = ISNULL(NRO_CALLE_EMP,''),
			@VPISO = ISNULL(PISO_DEPTO_EMP,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD_EMP,''),
			@VPROVINCIA = ISNULL(PROVINCIA_EMP,''),
			@VTELEFONO1 = ISNULL(TEL1_EMP,''),
			@VTELEFONO2 = ISNULL(TEL2_EMP,''),
			@VEMAIL = ISNULL(EMAIL_EMP,''),
			@VFORMACION = ISNULL(FORMACION_EMP,''),
			@VMOVILIDAD = ISNULL(MOVILIDAD_EMP,''),
			@VPERFIL = ISNULL(PERFIL_EMP,''),
			@VESTADO = ISNULL(STATUS_EMP,''),
			@VDIAS = ISNULL(DIAS_MENSUALES,'0')
		FROM	LK_EMPLEADOS
		WHERE	ID_EMPLEADO = @VID_SELEC
 
		SELECT	@VCONSULTORIA = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_EMPLEADOS_TIPO
		WHERE	ID_EMPLEADO = @VID_SELEC
		AND		ID_TIPO = '1'
 
		SELECT	@VAUDITORIA = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_EMPLEADOS_TIPO
		WHERE	ID_EMPLEADO = @VID_SELEC
		AND		ID_TIPO = '2'
 
		SELECT	@VCAPACITACION = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
		FROM	LK_EMPLEADOS_TIPO
		WHERE	ID_EMPLEADO = @VID_SELEC
		AND		ID_TIPO = '3'
		
 
		SET  @HTML_DISABLE=''
 
	END
 
	SET @HTML_ADJCV = '	
				<div class="w3-col w3-container w3-muhle-text-14 w3-muhle-color"><p><b>Adjuntar CV</b></div>
				<input class="w3-input w3-border" id="'+@FORM_ID+'_fileupload" type="file" name="files[]">
				<div id="progressdiv" class="w3-light-grey" style="display: none;">
					<div id="progressbar" class="w3-container w3-green w3-center" style="width: 0%">0%</div>
				</div>
				<div id="'+@FORM_ID+'_attached_files"></div>
				<script>initAttachFiles(''' + @FORM_ID + ''',''' + isnull(@IPKEYJOB,'') + ''')</script>
				<div>&nbsp;</div>' +
		CASE WHEN isnull(@VDESC_ERROR,'') <> '' THEN
			'<div class="w3-panel w3-pale-red w3-muhle-text-14" style="height: 20px;">
				<font style="color:#641E16"><b>'+isnull(@VDESC_ERROR,'')+'</b></font>
			</div>'
			ELSE 
				''
			END + '
		<div class="w3-row w3-bottombar"></div>'
 
	----TOP CONTAINER----
	SET @PS_TITULO = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users w3-large"></i>&nbsp;&nbsp;Empleado/Consultores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''9290878C-C546-43A1-8B89-B53C7039DCB8'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
 
		<div class="w3-row-padding">'+
			CASE WHEN @VCOD_ACCION_MENU <> 'UPDATE' THEN
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Empleado/Consultor</b></span>'
			ELSE
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Empleado/Consultor</b></span>'
			END + '
			<div class="w3-row w3-bottombar"></div><div>&nbsp;</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Apellido&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.APELLIDO" value="' + @VAPELLIDO + '">
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Nombres&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NOMBRE" value="' + @VNOMBRE + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-id-badge"></i>&nbsp;&nbsp;Tipo Documento&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.TIPO_DOC"></select>		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-address-card"></i>&nbsp;&nbsp;Nº Documento&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NRO_DOC" value="' + @VNRO_DOC + '">		
			</div>
			<div>&nbsp;</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-edit"></i>&nbsp;&nbsp;CUIT</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CUIT" value="' + @VCUIT + '">		
			</div>		
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-building"></i>&nbsp;&nbsp;¿Ingresa al sistema? &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.INGRESO" '+CASE WHEN @VCOD_ACCION_MENU = 'UPDATE' THEN 'disabled' ELSE '' END+'></select>	
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-user-circle"></i>&nbsp;&nbsp;Usuario &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.USUARIO" value="' + @VUSUARIO + '" '+CASE WHEN @VCOD_ACCION_MENU = 'UPDATE' THEN 'disabled' ELSE '' END+'>		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-user-secret"></i>&nbsp;&nbsp;Clave &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CLAVE" value="' + @VCLAVE + '" '+CASE WHEN @VCOD_ACCION_MENU = 'UPDATE' THEN 'disabled' ELSE '' END+'>		
			</div>
			<div>&nbsp;</div>'
 
	----FOOT CONTAINER----
	SET @PS_FORMULARIO = '
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-map-signs"></i>&nbsp;&nbsp;Calle &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CALLE" value="' + @VCALLE + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-hashtag"></i>&nbsp;&nbsp;Numero &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NRO" value="' + @VNRO + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-home"></i>&nbsp;&nbsp;Localidad &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.LOCALIDAD" value="' + @VLOCALIDAD + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-bullseye"></i>&nbsp;&nbsp;Provincia &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.PROVINCIA"></select>	
			</div>
			<div>&nbsp;</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-tty"></i>&nbsp;&nbsp;Celular &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.TELEFONO1" value="' + @VTELEFONO1 + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-id-card"></i>&nbsp;&nbsp;CBU &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.TELEFONO2" value="' + @VTELEFONO2 + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-at"></i>&nbsp;&nbsp;Email &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.EMAIL" value="' + @VEMAIL + '">		
			</div>
			<div class="w3-quarter">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Perfil &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>	
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.PERFIL" onchange="EnableCheckBox()" '+CASE WHEN @VCOD_ACCION_MENU = 'UPDATE' THEN '' ELSE '' END+'></select>	
			</div>
			<div>&nbsp;</div>
			<div id="menuCheck">  
				<div class="w3-third">
					<label class="w3-muhle-text-14">&nbsp;&nbsp;&nbsp;Servicio Auditoria &nbsp;&nbsp;	
						<input type="hidden" name="CALL.CONS_TIPO_AUDI:ctl_6" value="'+@VAUDITORIA+'">
						<input type="checkbox" class="w3-check w3-border w3-padding w3-round w3-muhle-text-14" id="check_auditoria" onchange="saveCheckBoxValue(this, ''CALL.CONS_TIPO_AUDI:ctl_6'')";>
						<img src onerror="initCheckBox(''check_auditoria'','+@VAUDITORIA+')" style="display: none">			
					</label>
				</div>
				<div class="w3-third">
					<label class="w3-muhle-text-14">&nbsp;&nbsp;&nbsp;Servicio Capacitacion &nbsp;&nbsp;	
						<input type="hidden" name="CALL.CONS_TIPO_CAPA:ctl_7" value="'+@VCAPACITACION+'">
						<input type="checkbox" class="w3-check w3-border w3-padding w3-round w3-muhle-text-14" id="check_capacitacion" onchange="saveCheckBoxValue(this, ''CALL.CONS_TIPO_CAPA:ctl_7'');">
						<img src onerror="initCheckBox(''check_capacitacion'','+@VCAPACITACION+')" style="display: none">		
					</label>
				</div>
				<div class="w3-third">
					<label class="w3-muhle-text-14">&nbsp;&nbsp;&nbsp;Servicio Consultoria &nbsp;&nbsp;	
						<input type="hidden" name="CALL.CONS_TIPO_CONS:ctl_8" value="'+@VCONSULTORIA+'">
						<input type="checkbox" class="w3-check w3-border w3-padding w3-round w3-muhle-text-14" id="check_consultor" onchange="saveCheckBoxValue(this, ''CALL.CONS_TIPO_CONS:ctl_8'');">
						<img src onerror="initCheckBox(''check_consultor'','+@VCONSULTORIA+')" style="display: none">					
					</label>
				</div>
			</div>
			<div>&nbsp;</div>
			<div class="w3-third">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb5" name="SP.ESTADO"></select>	
			</div>
			<div class="w3-third">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-question-circle"></i>&nbsp;&nbsp;Eventual &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb6" name="SP.EVENTUAL"></select>	
			</div>
			<div class="w3-third">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user-graduate"></i>&nbsp;&nbsp;Formacion &nbsp;&nbsp;</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.FORMACION" value="' + @VFORMACION + '">		
			</div>
			<div>&nbsp;</div>
			<div class="w3-half">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-cab"></i>&nbsp;&nbsp;Movilidad &nbsp;&nbsp;</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb7" name="SP.MOVILIDAD"></select>	
			</div>
			<div class="w3-half">
				<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-calendar"></i>&nbsp;&nbsp;Dias Del Mes &nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DIAS_MENSUALES" value="' + ISNULL(@VDIAS,'0') + '">		
			</div>
			<div>&nbsp;</div>'
 
	SET @HTML_BUTTONS = '				
				<div class="w3-padding">
					<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VCOD_ACCION_MENU = 'UPDATE' THEN 'Grabar' ELSE 'Agregar' END +'</btn>
					<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''9290878C-C546-43A1-8B89-B53C7039DCB8'');return false;">Cancelar</btn>		
				</div>
			</div>'+  --cierre formulario
			'</div>
		</div>
	</div>'
 
	SET @HTML_SCRIPTS = '
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '951E0873-8D8E-49F3-8936-E116E6D5B97C' + ''', ''' + ISNULL(@VTIPO_DOC,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VINGRESO,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '0000000124_98' + ''', ''' + ISNULL(@VPROVINCIA,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '3256ECBE-25F0-4090-8276-B8F5C2401091' + ''', ''' + ISNULL(@VPERFIL,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb5'', ''' + '78FF2D5A-0B70-4854-A931-6D7F026748EA' + ''', ''' + ISNULL(@VESTADO,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb6'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VEVENTUAL,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb7'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VMOVILIDAD,'') +''', '''');</script>
 
	<script>
		function EnableCheckBox(){
			var select  = document.getElementById("cmb4");
		    var value =  select.options[select.selectedIndex].value;
			var checkList = document.getElementById("menuCheck").querySelectorAll("input");
 
				   if(value == "CONSULTOR" ){
					checkList.forEach(item => item.disabled = false)
				   }
				   else{					
				   	resetCheckBox();
				   }        
        }
 
		function resetCheckBox(){
			var checkList = document.getElementById("menuCheck").querySelectorAll("input");
 
			initCheckBox(''check_auditoria'',''0'')
			initCheckBox(''check_capacitacion'',''0'')
			initCheckBox(''check_consultor'',''0'')
			
			let checks =[]
					
			checkList.forEach((item) =>{ 
						if(item.getAttributeNode("type").value != "hidden"){
							checks.push(item);
						}
			})
			saveCheckBoxValue(checks[0], ''CALL.CONS_TIPO_AUDI:ctl_6'')
			checks[0].disabled = true;
			saveCheckBoxValue(checks[1], ''CALL.CONS_TIPO_CAPA:ctl_7'')
			checks[1].disabled = true;
			saveCheckBoxValue(checks[2], ''CALL.CONS_TIPO_CONS:ctl_8'')
			checks[2].disabled = true;
			 
		}
 
		function initCheckBox(id_item , value){	
			let checkBoxItem =  document.getElementById(id_item);
			if(value == 1) checkBoxItem.checked = true;
			else  checkBoxItem.checked = false;
		}
	
	</script>
	<script>		
       $(document).ready(function() {
			if('''+@VPERFIL+''' != ''CONSULTOR'')
				resetCheckBox();
        });	
	</script>'
	--@PS_FORMU_FOOT+
	SET @PS_FORMU_FOOT = @HTML_ADJCV+@HTML_BUTTONS+@HTML_SCRIPTS
		
END
