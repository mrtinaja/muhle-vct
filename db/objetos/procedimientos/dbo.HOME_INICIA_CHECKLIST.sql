CREATE PROCEDURE [dbo].[HOME_INICIA_CHECKLIST]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT
 )
AS
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(50),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDIASP		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VERROR		VARCHAR(50)
 
BEGIN
 
	SELECT	TOP 1 @UNITDESC = UNIT_DESCRIPTION
	FROM	ORGANIZATION
	WHERE	UNIT_CODE = @IUNIDAD;
 
	SELECT	TOP 1 @USERDESC = A.NOMBRE
	FROM	(
			SELECT	TOP 1 USER_NAME AS NOMBRE
			FROM	AGENTE
			WHERE	USER_ID = @IAGENTE
			UNION
			SELECT	TOP 1 SUPERVISOR_NAME AS NOMBRE
			FROM	SUPERVISOR
			WHERE	SUPERVISOR_CODE = @IAGENTE) A
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS/24),
			@VIDCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#AF7AC5"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#AF7AC5;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>CheckList</b></font>
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
 
	<div class="w3-container">
		<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
			<th><b>Cliente</b></th>
			<th><b>Proyecto</b></th>
			<th><b>Fecha</b></th>
			<th><b>Dias</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VNORMA+'</td>' +
			  '<td>'+@VFECHA+'</td>' +
			  '<td>'+@VDIASP+'</td>
			</tr>
	</table>
	</div>
	
	'
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-panel w3-topbar">
		<p w3-left>
	<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
	+'<b>CheckList </b>'+'<font style="font-size:24;color:#AF7AC5">'+'<b>'+ CASE WHEN @VSERVICIO = '1' THEN	'Consultoria'
																				 WHEN @VSERVICIO = '2' THEN	'Auditoria'
																				 WHEN @VSERVICIO = '3' THEN	'Capacitacion' END	 +'</b></font> '
	+'</font>'
	+'
		<i class="fas fa-tasks w3-right" style="font-size:24px;color:#AF7AC5;cursor:pointer;" title="Agregar CheckList" onclick="goto('''+@FORM_ID+''',''3F11610E-DB37-427B-997D-1507E8982A92'');"></i>
	</p>
	</div>
 
	</body>
	</html>'
	
END
 
