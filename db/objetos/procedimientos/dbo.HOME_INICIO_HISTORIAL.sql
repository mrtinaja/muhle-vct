CREATE PROCEDURE [dbo].[HOME_INICIO_HISTORIAL]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OMENU		AS VARCHAR(4000) OUTPUT,
 @OTABS		AS VARCHAR(MAX) OUTPUT )
AS
 
DECLARE
			@VSOLAPA			VARCHAR(50),
			@VID_DELETE			VARCHAR(50),
			@VID_MC_DELETE		VARCHAR(100),
			@VPROY_MC			VARCHAR(50),
			@VFECHA_DESDE		DATETIME,
			@VFECHA_HASTA		DATETIME,
			@VF_CLIENTE			VARCHAR(50),
			@VF_PROYECTO		VARCHAR(50),
			@VF_SERVICIO		VARCHAR(50),
			@VFILTRO			VARCHAR(50),
			@UNITDESC			VARCHAR(300),
			@USERDESC			VARCHAR(300)
 
BEGIN	
	
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
			@VF_PROYECTO = ISNULL(PROYECTO,''),
			@VF_SERVICIO = ISNULL(SERVICIO,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
SET @OTABS = 
'
<div class="w3-container">
  
  	<div id="table9"></div>
 
</div>
 
<script>
 
BuildAjaxSPTable(''table9'', ''HOME_INI_PROYEC_HIST'', '''+@FORM_ID+''');
 
</script>
'
 
SET @OMENU = '
	
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#5DADE2;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Histórico de Proyectos</b></font>
			</p>
		</div>
		
		<div class="w3-col w3-container" style="width:70%;background-color:#D6DBDF;text-align:right">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: center">'
			+'<b>Nro Proceso: </b>'+'<font style="font-size:8;color:#003D7A">'+'<b>'+ CONVERT(VARCHAR,@IJOBSEQ)		 +'</b></font> - '
			+'<b>Usuario: </b>'+@USERDESC								 +' - '
			+'<b>Perfil: </b>'+@UNITDESC								 +' - '
			+'<b>Fecha: </b>' +CONVERT(VARCHAR, GETDATE(), 103)			 +' '
								+CONVERT(VARCHAR,GETDATE(),108)			 +
			--+'/>'
			+'</font>
			</p>
		</div>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-bar w3-grey">'+
		--'<a class="w3-bar-item w3-button" href="javascript:void(0);" onclick="w3_open_nav(''nav_fecha'')" title="Fecha"><b>Fecha</b>&nbsp;&nbsp<i class="fa fa-caret-down" style="display: inline;"></i><i class="fa fa-caret-up" style="display: none;"></i></a>'+
		--'<div class="w3-bar-item w3-grey"><b>Desde:</b></div><input type="date" class="w3-bar-item w3-grey" name="SP.FECHA_DESDE" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_DESDE, 105), 23),'')+'">'+
		--'<div class="w3-bar-item w3-grey"><b>Hasta:</b></div><input type="date" class="w3-bar-item w3-grey" name="SP.FECHA_HASTA" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_HASTA, 105), 23),'')+'">'+
		'<div class="w3-bar-item w3-grey"><b>Cliente:</b></div><select class="w3-bar-item w3-grey" id="cmb1_'+@FORM_ID+'" name="SP.INICIO_CLIENTE" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROYECTOS'', '''',this.id);"></select>
		<div class="w3-bar-item w3-grey"><b>Proyecto:</b></div><select class="w3-bar-item w3-grey" id="cmb2_'+@FORM_ID+'" name="SP.PROYECTO"></select>
		<a class="w3-bar-item w3-button w3-grey w3-right" href="javascript:goto('''+@FORM_ID+''',''A12B5155-A622-40A8-BC05-3DC964BE2F59'');"><i class="fa fa-search"></i></a>
	</div>'
	/*<div id="nav_fecha" class="w3-bar-block w3-card-2 w3-dark-grey" style="display: none;">
		<span onclick="w3_close_nav(''nav_fecha'')" class="w3-button w3-xlarge w3-right" style="font-weight:bold;">×</span>
		<div class="w3-row-padding" style="padding:24px 48px">
			<div class="w3-col l3 m4">
			  <h4>Seleccione Fecha</h4>
				<div class="w3-bar-item w3-dark-grey"><b>Desde:</b></div><input type="date" class="w3-bar-item w3-dark-grey" name="SP.FECHA_DESDE" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_DESDE, 105), 23),'')+'">
				<div class="w3-bar-item w3-dark-grey"><b>Hasta:</b></div><input type="date" class="w3-bar-item w3-dark-grey" name="SP.FECHA_HASTA" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_HASTA, 105), 23),'')+'">
			</div>
		</div>
		<br>
    </div><br>'+
	CASE WHEN ISNULL(@VFECHA_DESDE,'') = '' THEN '' ELSE
	'<span class="w3-tag w3-teal">Desde: '+ISNULL(CONVERT(VARCHAR,CONVERT(date, @VFECHA_DESDE, 105),103),'')+' </span>&nbsp;' END+
	CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE
	'<span class="w3-tag w3-teal">Hasta: '+ISNULL(CONVERT(VARCHAR,CONVERT(date, @VFECHA_HASTA, 105),103),'')+'</span>&nbsp;' END+
	CASE WHEN ISNULL(@VF_CLIENTE,'') = '' THEN '' ELSE
	'<span class="w3-tag w3-teal">Cliente: '+ISNULL(@VF_CLIENTE,'')+' </span>&nbsp;' END+
	CASE WHEN ISNULL(@VF_PROYECTO,'') = '' THEN '' ELSE
	'<span class="w3-tag w3-teal">Proyecto: '+ISNULL(@VF_PROYECTO,'')+' </span>&nbsp;' END+
	CASE WHEN ISNULL(@VF_SERVICIO,'') = '' THEN '' ELSE
	'<span class="w3-tag w3-teal">Servicio: '+ISNULL(@VF_SERVICIO,'')+' </span>&nbsp;' END+*/
 
	+ '<div class="w3-panel w3-topbar"></div>
 
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3_'+@FORM_ID+''', ''VW_SERVICIOS'', '''+isnull(@VF_SERVICIO,'')+''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_CLIENTES'', '''+isnull(@VF_CLIENTE,'')+''', '''');</script>'+
	
	CASE WHEN ISNULL(@VF_CLIENTE,'') = '' THEN '' ELSE
	'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROYECTOS'', '''+isnull(@VF_PROYECTO,'')+''', '''+isnull(@VF_CLIENTE,'')+''');</script>' END
	
END
