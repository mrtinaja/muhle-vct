CREATE PROCEDURE [dbo].[SV_05_INDICE_TOTALES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OPANEL	AS VARCHAR(4000) OUTPUT
 )
AS
 
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME
 
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
 
	SELECT	@VFECHA_DESDE = FECHA_DESDE,
			@VFECHA_HASTA = FECHA_HASTA
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
SET @OHEADER = '
<html>
 
<body>
 
<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''3156A499-EF81-4F52-818A-AE94DAF5583B'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
<div class="w3-row">
	<div class="w3-col w3-container" style="width:20%;background-color:#641E16;text-align:left">
		<p>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Indices Totales</b></font>
		</p>
	</div>
		
	<div class="w3-col w3-container" style="width:80%;background-color:#D6DBDF;text-align:right">
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
 
</body>
</html>'
 
SET @OPANEL = '
<html>
<body>
 
<div class="w3-panel w3-topbar"></div>
	<div class="w3-bar w3-grey">'+
		'<div class="w3-bar-item w3-grey"><b>Desde:</b></div><input type="date" class="w3-bar-item w3-grey" name="SP.FECHA_DESDE" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_DESDE, 105), 23),'')+'">'+
		'<div class="w3-bar-item w3-grey"><b>Hasta:</b></div><input type="date" class="w3-bar-item w3-grey" name="SP.FECHA_HASTA" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_HASTA, 105), 23),'')+'">'+
		'<a class="w3-bar-item w3-button w3-grey w3-right" href="javascript:goto('''+@FORM_ID+''',''EF90D031-85DA-4743-9DAB-F3C522F9C34B'');"><i class="fa fa-search"></i>&nbsp;Buscar</a>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
</body>
</html>
'
 
END
