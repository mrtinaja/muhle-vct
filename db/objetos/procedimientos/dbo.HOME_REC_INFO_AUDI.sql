 
CREATE PROCEDURE [dbo].[HOME_REC_INFO_AUDI]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(100),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VID_SERVICIO INT,
		@VESTADO	VARCHAR(100),
		@VERROR		VARCHAR(50),
		@VARNORMA	VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VTIPO			VARCHAR(50),
		@VCANT_HR		INT,
		@VSTATUS		VARCHAR(50),
		@VID_DELETE			VARCHAR(50),
		@VINFORME			VARCHAR(50),
		@VFECHA_INFO		DATETIME,
		@VOBSERV_INFO		VARCHAR(400),
		@VFECHA		VARCHAR(50),
		@VDIASP		VARCHAR(50),
		@VFECHA_INI	DATETIME,
		@VFECHA_FIN	DATETIME,
		@VMONTO		VARCHAR(50)
 
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
 
	SELECT	@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VINFORME = ISNULL(ID_MINUTA,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VFECHA_INFO = ISNULL(FECHA_DOCUM,''),
			@VOBSERV_INFO = ISNULL(OBSERVACIONES,'')
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_PROYECTO_DOCUM = @VINFORME
 
	SELECT	@VFECHA_INI = FECHA_INICIO_REAL,
			@VFECHA_FIN = NULLIF(ISNULL(FECHA_FIN_REAL,''),''),
			@VDIAS		= TOTAL_HORAS_PROYECTADAS,
			@VMONTO		= MONTO_PRESUP,
			@VSERVICIO  = ID_TIPO_SERVICIO,
			@VPROYECTO  = ID_PROYECTO
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VID
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS),
			@VIDCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	/*	
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VINFORME = ISNULL(HOJA_RUTA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VFECHA_INFO = ISNULL(FECHA_DOCUM,''),
			@VOBSERV_INFO = ISNULL(OBSERVACIONES,'')
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_PROYECTO_DOCUM = @VINFORME
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO  = '('+P.CODIGO+') - '+P.NORMA_REF,
			@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VFECHAD = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(P.NORMAS,''),
			@VCONSULTORES = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
			@VID_SERVICIO = ID_SERVICIO
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	WHILE LEN(@VARNORMA) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VARNORMA) -- Busca el caracter a separador
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VARNORMA
					SET @VARNORMA = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VARNORMA, 1, @lnuPosComa - 1)
 
					SELECT	@VALOR = '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+DESC_APTITUD+'</font>'
					FROM	LK_APTITUDES
					WHERE	ID_APTITUD = @lstDato
 
					SET @VDESCNORMAS = ISNULL(@VDESCNORMAS,'') + @VALOR + '</br>'
 
					SET @VARNORMA = SUBSTRING(@VARNORMA, @lnuPosComa + 1, LEN(@VARNORMA))
				END
			END
	*/
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		AUDI_FECHA_IA = @VFECHA_INFO,
				AUDI_OBSERV_IA = @VOBSERV_INFO
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:red;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modifica Informe Auditoria</b></font>
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
			<th><b>Servicio</b></th>
			<th><b>Fecha Inicio</b></th>
			<th><b>Horas</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VNORMA+'</td>' +
			  '<td>'+CASE WHEN @VSERVICIO = '1' THEN	'Consultoria'
						  WHEN @VSERVICIO = '2' THEN	'Auditoria'
						  WHEN @VSERVICIO = '3' THEN	'Capacitacion' END+'</td>' +
			  '<td>'+@VFECHA+'</td>' +
			  '<td>'+@VDIASP+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>'
	
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-card">
		   <div class="w3-col w3-container" style="background-color:red;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Adjuntar Informe</b></font>
			</p>
			</div>
		   <input class=""w3-input w3-border"" id="'+@FORM_ID+'_fileupload" type="file" name="files[]">
	
		<div id="progressdiv" class="w3-light-grey" style="display: none;">
			<div id="progressbar" class="w3-container w3-green w3-center" style="width: 0%">0%</div>
	    </div>
		<div id="'+@FORM_ID+'_attached_files"></div><script>initAttachFiles(''' + @FORM_ID + ''',''' + isnull(@IPKEYJOB,'') + ''')</script>
		</div>
	
	<div class="w3-panel w3-topbar"></div>
 
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	UPDATE	XAGENDA
	SET		ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
