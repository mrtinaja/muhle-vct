CREATE PROCEDURE [dbo].[HOME_REC_COTIZACION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OADJUNTO	AS VARCHAR(400) OUTPUT)
AS
 
DECLARE	@VID		VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VFECHA		VARCHAR(50),
		@VFECHA_COTIZA DATETIME,
		@VERROR		VARCHAR(50),
		@VNRO		VARCHAR(50),
		@VESTADO	VARCHAR(50),
		@VCLAVE_ADJ	VARCHAR(100)
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
 
	SELECT	@VID = ISNULL(CLAVE_COTIZA,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VFECHA_COTIZA = FECHA_COTIZACION,
			@VNRO	= NRO_COTIZACION,
			@VESTADO = ESTADO_COTIZACION
	FROM	LK_COTIZACIONES
	WHERE	ID_COTIZACION = @VID
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO= ISNULL(P.NORMA_REF,'Sin Asignar'),
			@VFECHA	  = ISNULL(CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103), 'No Aplica')
	FROM	LK_COTIZACIONES C
			LEFT JOIN LK_CLIENTES CLI ON C.ID_CLIENTE = CLI.ID_CLIENTE
			LEFT JOIN LK_PROYECTO P ON C.ID_COTIZACION = P.ID_COTIZACION	
	WHERE	C.ID_COTIZACION = @VID
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		FECHA_COTIZA = @VFECHA_COTIZA,
				NRO_COTIZA = @VNRO,
				ESTADO_COTIZA = @VESTADO
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div class="w3-container" style="background-color:light-gray">
		<span class="w3-right" style="font-size:14px;">'+
			'Usuario: <b>'+@USERDESC+'</b> - Fecha: <b>' +CONVERT(VARCHAR, GETDATE(), 103)+' '+CONVERT(VARCHAR,GETDATE(),108)+'</b>
		</span>
	</div>
	<div class="w3-card-4 w3-round" style="background-color:#641E16;">
		<div class="w3-bar w3-round-up">
			<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fas fa-chart-bar fa-fw w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Propuestas</span>
		</div>
	</div>
	<div>&nbsp</div>
	
	<div class="w3-panel w3-topbar"></div>
 
	<div class="w3-container">
		<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
			<th><b>Cliente</b></th>
			<th><b>Proyecto</b></th>
			<th><b>Fecha</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VPROYECTO+'</td>' +
			  '<td>'+@VFECHA+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>'
	
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-card">
		   <div class="w3-col w3-container" style="background-color:#48C9B0;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Adjuntar Cotizacion</b></font>
			</p>
			</div>
		   <input class=""w3-input w3-border"" id="'+@FORM_ID+'_fileupload" type="file" name="files[]">
	
		<div id="progressdiv" class="w3-light-grey" style="display: none;">
			<div id="progressbar" class="w3-container w3-green w3-center" style="width: 0%">0%</div>
	    </div>
		<div id="'+@FORM_ID+'_attached_files"></div><script>initAttachFiles(''' + @FORM_ID + ''',''' + isnull(@IPKEYJOB,'') + ''')</script>
		</div>
	
	<div class="w3-panel w3-topbar">
	</div>
 
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#48C9B0"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''1F3B9CBF-6330-4598-B517-9F8CCB08069E'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#48C9B0"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	/*SET @VCLAVE_ADJ = NEWID()
	
	SET @OADJUNTO = 
	'<button onclick="openGlobalAttachDialog('''+@IPKEYJOB+''', ''TASK'', '''+@VCLAVE_ADJ+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#48C9B0"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Adjuntar</b></font></button>' 
	--'<a href="javascript:openGlobalAttachDialog('''+@IPKEYJOB+''', ''TASK'', '''+@VCLAVE_ADJ+''');">Adjuntar<a/>'
	--'<a href="javascript:OpenAttach('''+ISNULL(AD.PKEY,'')+''','''+ISNULL(AD.[FILE_NAME],'')+''');">'+ISNULL([FILE_NAME],'')+'</a><div id="'+PRES.PKEY+'_list_files"></div>'
 
	UPDATE	XAGENDA
	SET		CLAVE_ADJUNTO = @VCLAVE_ADJ
	WHERE	PAR_KEY = @IPKEYJOB*/
 
END
 
