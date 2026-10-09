CREATE PROCEDURE [dbo].[EP_CRON_DASHBOARD]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHTML	AS VARCHAR(MAX) OUTPUT)
AS
 
 DECLARE @ENOREALIZADO INT,
 @EREALIZADO INT,
 @EENPROCESO INT,
 @EFINALIZADO INT,
 @IPLANTA VARCHAR(50),
 @IEMPRESA VARCHAR(50),
 @EMPRESA_DESC AS VARCHAR(1000),
 @PLANTA_DESC AS VARCHAR(1000),
 @IESTADO_SEL AS VARCHAR(50),
 @IMES_SEL AS VARCHAR(50),
 @IANIO_SEL AS VARCHAR(50),
 @ITIPO_SERV_SEL AS VARCHAR(50),
 @UserName as varchar(100)
 
BEGIN	
	--No Realizado	1
	--Realizado	3
	--En Proceso	2
	--Finalizado	4
 
 
	SELECT 
		@IEMPRESA = ID_EMPRESA_SEL, 
		@IPLANTA = ID_PLANTA_SEL,
		@IESTADO_SEL = ID_ESTADO_SEL,
		@IMES_SEL = ID_MES_SEL,
		@IANIO_SEL = ID_ANIO_SEL,
		@ITIPO_SERV_SEL=ID_TIPO_SERV_SEL
	FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
	SELECT @UserName=U.[NAME] FROM EP_PLANTAS_USUARIOS PU
	INNER JOIN GROUPSUSERMEMBERS G ON G.USERMEMBERID=PU.IDUSUARIO AND GROUPID='EP_EJECUTIVOS'
	INNER JOIN USERS U ON U.ID=G.USERMEMBERID
	WHERE IDPLANTA=@IPLANTA
 
	IF (ISNULL(@IANIO_SEL,'')='') 
		BEGIN
			SET @IANIO_SEL = '2025'
		END
 
	
	IF (ISNULL(@IEMPRESA,'')='') 
		BEGIN
			SET @EMPRESA_DESC = '(Todas)'
		END
	ELSE
		BEGIN
			SELECT @EMPRESA_DESC=Empresa FROM EP_EMPRESAS WHERE IDEMPRESA=@IEMPRESA;
		END
 
	IF (ISNULL(@IPLANTA,'')='') 
		BEGIN
			SET @PLANTA_DESC = '(Todas)'
		END
	ELSE
		BEGIN
			SELECT @PLANTA_DESC=Planta FROM EP_PLANTAS WHERE IDPlanta=@IPLANTA;
		END
 
 
	SELECT @ENOREALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDPlanta= CAST(@IPLANTA AS INT) and IDESTADO=1 AND Año=CAST(@IANIO_SEL AS float);
	SELECT @EENPROCESO=COUNT(1) FROM EP_CRONOGRAMA where IDPlanta= CAST(@IPLANTA AS INT) and  IDESTADO=2 AND Año=CAST(@IANIO_SEL AS float);
	SELECT @EREALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDPlanta= CAST(@IPLANTA AS INT) and IDESTADO=3 AND Año=CAST(@IANIO_SEL AS float);
	SELECT @EFINALIZADO=COUNT(1) FROM EP_CRONOGRAMA where IDPlanta= CAST(@IPLANTA AS INT) and IDESTADO=4 AND Año=CAST(@IANIO_SEL AS float);
 
	SET @OHTML=' 
	<ul class="breadcrumb">
	  <li><a href="javascript:goto('''+@FORM_ID+''',''C902C963-5172-45A4-984B-DC9730767097'');">'+@EMPRESA_DESC+'</a></li>
	  <li>Cronograma de Actividades</li>
	</ul>
 
	<div class="w3-row" style="background-color:#d42215;">
		<div class="w3-col s8 w3-container w3-left w3-text-white" >
			<h2>Cronograma de Actividades</h2>
		</div>
		
		<div class="w3-col s4 w3-container w3-right w3-small w3-light-grey">'
			+'<b>Empresa: </b>' + @EMPRESA_DESC + '<br/>'
			+'<b>Planta: </b>' + @PLANTA_DESC + '<br/>'
			+'<b>Responsable: </b>'+isnull(@UserName,'')+'<br/>'
			+'<b>Transaction Id: </b>'+CONVERT(VARCHAR,@IJOBSEQ)+
		'</div>
	</div>
	<br/>
	<br/>
 
 <div class="w3-row-padding w3-margin-bottom">
    <div class="w3-quarter">
      <div class="w3-container w3-red w3-text-white w3-padding">
        <div class="w3-left w3-xlarge"><i class="fa fa-calendar-times"></i>&nbsp;No Realizado</div>
        <div class="w3-right w3-xlarge">'+cast(@ENOREALIZADO as varchar)+'</div>
      </div>
    </div>
    <div class="w3-quarter">
      <div class="w3-container w3-yellow w3-text-white w3-padding">
	    <div class="w3-left w3-xlarge"><i class="fa fa-calendar-day"></i>&nbsp;En Proceso</div>
        <div class="w3-right w3-xlarge">'+cast(@EENPROCESO as varchar)+'</div>
      </div>
    </div>
    <div class="w3-quarter">
      <div class="w3-container w3-orange w3-text-white w3-padding">
	  	<div class="w3-left w3-xlarge"><i class="fa fa-calendar-alt"></i>&nbsp;Realizado</div>
        <div class="w3-right w3-xlarge">'+cast(@EREALIZADO as varchar)+'</div>
      </div>
    </div>
    <div class="w3-quarter">
      <div class="w3-container w3-green w3-text-white w3-padding">
	  	<div class="w3-left w3-xlarge"><i class="fa fa-calendar-check"></i>&nbsp;Finalizado</div>
        <div class="w3-right w3-xlarge">'+cast(@EFINALIZADO as varchar)+'</div>
      </div>
    </div>
  </div>
  
<div class="w3-bar w3-grey">
	<div class="w3-bar-item"><b>Año:</b></div><select class="w3-bar-item w3-grey" id="cmb_anio" name="SP.ID_ANIO_SEL"></select>
	<div class="w3-bar-item"><b>Mes:</b></div><select class="w3-bar-item w3-grey" id="cmb_mes" name="SP.ID_MES_SEL"></select>
	<div class="w3-bar-item"><b>Tipo Servicio:</b></div><select class="w3-bar-item w3-grey" id="cmb_tipo_serv" name="SP.ID_TIPO_SERV_SEL"></select>
	<div class="w3-bar-item"><b>Estado:</b></div><select class="w3-bar-item w3-grey" id="cmb_estados" name="SP.ID_ESTADO_SEL"></select>
	<a class="w3-bar-item w3-button w3-right" href="javascript:goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'');"><i class="fa fa-search"></i></a>
  </div>
  <br/>
  <br/>
  <script>
	BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_anio'', ''FA317B1B-B901-423C-8C8B-CBD6CD4C4675'', '''+ISNULL(@IANIO_SEL,'')+''', '''');
	BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_mes'', ''50E339E6-FBAD-42D6-8B64-109214B19EE0'', '''+ISNULL(@IMES_SEL,'')+''', '''');
	BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_tipo_serv'', ''F53BADBE-B758-4005-8004-121E42D3BFB8'', '''+ISNULL(@ITIPO_SERV_SEL,'')+''', '''');
	BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_estados'', ''07C14105-5B0A-4D3E-8477-F70BF1974111'', '''+ISNULL(@IESTADO_SEL,'')+''', '''');
  </script>'
 
  --SACO TIPO DE TAREA POR PEDIDO DE ROBER
  --<div class="w3-bar-item">Tipo Tarea:</div><select class="w3-bar-item w3-grey" id="cmb_tipo_tarea" name="SP.ID_TAREA_SEL"></select>
  --BuildAjaxSPCombo('''+@FORM_ID+''',''cmb_tipo_tarea'', ''D3F38729-8CBD-4CD7-82CF-33664E913B4C'', '''', '''');
  
 
END
