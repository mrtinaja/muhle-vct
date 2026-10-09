 
CREATE PROCEDURE [dbo].[EP_EQUIPOS_HEADER]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHTML	AS VARCHAR(MAX) OUTPUT)
AS
 
BEGIN	
 
	DECLARE @TIPO VARCHAR(50),
	@ESTADO VARCHAR(50)
  
	SELECT @TIPO=EQ_TIPO, @ESTADO=EQ_ESTADO FROM TMT_CRON where PAR_KEY=@IPKEYJOB
 
	SET @OHTML=' 
 
	<div class="w3-row" style="background-color:#d42215;">
		<div class="w3-col w3-container w3-left w3-text-white" >
			<h2>Certificados de Calibracion</h2>
		</div>
		
	</div>
	<br/>
	<div class="w3-bar w3-grey">
		<div class="w3-bar-item"><b>Tipo Equipo:</b></div><select class="w3-bar-item w3-grey" id="cmb_tipo_equipo" name="SP.EQ_TIPO"></select>'
		+	case when ((@IAGENTE='admin') or (@IAGENTE='estrucplan')) then
		'<div class="w3-bar-item"><b>Estado:</b></div><select class="w3-bar-item w3-grey" id="cmb_estados" name="SP.EQ_ESTADO"></select>' else '' end+
		'<a class="w3-bar-item w3-button w3-right" href="javascript:goto('''+@FORM_ID+''',''6A67507F-3FC7-4DCB-AC6A-C087497A72B4'');"><i class="fa fa-search"></i></a>
	  </div><br/>
  <script>
	BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_tipo_equipo'', ''D21113EC-7A64-4C2F-9CDF-4C91094AA32B'', '''+ISNULL(@TIPO,'')+''', '''');'+	case when ((@IAGENTE='admin') or (@IAGENTE='estrucplan')) then
		'BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_estados'', ''53934364-A251-4B3D-82D4-51C390AAC1BA'', '''+ISNULL(@ESTADO,'')+''', '''');' else '' end+
	'</script>
	'+	case when ((@IAGENTE='admin') or (@IAGENTE='estrucplan')) then
		'<div class="w3-container">
		  <p><button onclick="goto('''+@FORM_ID+''',''F8508489-8B5D-46A1-BEA8-F92806ED237D'');return false;" class="w3-button w3-right" style="background-color:#5DADE2;"><font style="color:#FFFFFF;">Agregar Equipo</font></button></p>
		</div>	
			<br/>' else '' end 
 
  
  update TMT_CRON
  set eq_sel=null,
	  EQ_NRO=null,
	  EQ_MARCA_MOD=null,
	EQ_NRO_SERIE=null,
	EQ_FECHA_DESDE=null,
	EQ_FECHA_HASTA=null,
	[ACTION]='SEARCH_EQUIPO'
  where PAR_KEY=@IPKEYJOB
 
END
