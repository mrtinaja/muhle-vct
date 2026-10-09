CREATE   PROCEDURE [dbo].[SV_01_INICIA_DOC_RELACIONADA]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VF_SERVICIO AS VARCHAR(50)
 
BEGIN	
 
	--SELECT	TOP 1 @UNITDESC = UNIT_DESCRIPTION
	--FROM	ORGANIZATION
	--WHERE	UNIT_CODE = @IUNIDAD;
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	--SELECT	TOP 1 @USERDESC = A.NOMBRE
	--FROM	(
	--		SELECT	TOP 1 USER_NAME AS NOMBRE
	--		FROM	AGENTE
	--		WHERE	USER_ID = @IAGENTE
	--		UNION
	--		SELECT	TOP 1 SUPERVISOR_NAME AS NOMBRE
	--		FROM	SUPERVISOR
	--		WHERE	SUPERVISOR_CODE = @IAGENTE) A
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	select @VF_SERVICIO=TIPO_SERVICIO from TMT_SV_01 where PAR_KEY = @IPKEYJOB;
 
	SET @OHEADER = '
	<html>
 
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''1085F118-8FDD-4D38-8AE4-BD8D52BF0928'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Documentacion Relacionada</b></font>
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
 
	<div class="w3-bar w3-grey">
	<div class="w3-bar-item w3-grey"><b>Tipo Servicio:</b></div><select class="w3-bar-item w3-grey" id="cmb1_'+@FORM_ID+'" name="SP.TIPO_SERVICIO"></select>'
	+'<a class="w3-bar-item w3-button w3-grey w3-right" href="javascript:goto('''+@FORM_ID+''',''8374CCC7-378F-488E-950F-4AFFA6B56BD0'');"><i class="fa fa-search"></i></a>
  </div><script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_SERVICIOS'', '''+isnull(@VF_SERVICIO,'')+''', '''');</script>'
  +'<div class="w3-panel w3-topbar"></div>
 
 
  
  <div class="w3-cell-row">
 
  <div class="w3-container w3-cell">
    <div id="table1"/>
  </div>
 
  <div class="w3-container w3-cell">
    <div id="table2"/>
  </div>
  <script>BuildAjaxSPTable(''table1'', ''SV_01_GRD_DOC_DISPON'', '''+@FORM_ID+''');</script>
  <script>BuildAjaxSPTable(''table2'', ''SV_01_GRD_DOC_RELACI'', '''+@FORM_ID+''');</script>
</div>'
 
END
 
