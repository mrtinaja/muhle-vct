 
CREATE PROCEDURE [dbo].[HOME_REC_DATOS_SEGUIMIENTO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OSERVICIO	AS VARCHAR(50) OUTPUT)
AS
 
DECLARE	@VSERVICIO	VARCHAR(50),
		@VID		VARCHAR(50),
		@VFECHA_INI	DATETIME,
		@VFECHA_FIN	DATETIME,
		@VDIAS		VARCHAR(50),
		@VMONTO		VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(50),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDIASP		VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VTABLA		VARCHAR(MAX),
		@VARCLIENTE	VARCHAR(300), 
		@VARPROYECTO VARCHAR(300), 
		@VARSERVICIO VARCHAR(100), 
		@VARNORMA	VARCHAR(300), 
		@VARFECHA	VARCHAR(50), 
		@VARPROFESIONAL VARCHAR(300), 
		@VAROBSERVADOR VARCHAR(300), 
		@VID_AGENDA	VARCHAR(50),
		@VID_SERVICIO	VARCHAR(50),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS		VARCHAR(4000),
		@VSTATUS			VARCHAR(50),
		@VID_DELETE			VARCHAR(50),
		@VTIPO				VARCHAR(50),
		@VFRECUENCIA		VARCHAR(50),
		@VDOC_EMPRESA		VARCHAR(50),
		@VMANUAL_DOC		VARCHAR(50),
		@VREQ_INGRESO		VARCHAR(50),
		@VCV_CERTIF			VARCHAR(50),
		@VLOGISTICA			VARCHAR(50),
		@VCURSO				VARCHAR(300),
		@VMATERIAL			VARCHAR(50),
		@VESTADO_ENVIO		VARCHAR(50),
		@VRECIBIDO			VARCHAR(50)
 
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
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO = ID_PROYECTO,
			@VSERVICIO  = ID_TIPO_SERVICIO,
			@VFRECUENCIA = ISNULL(FRECUENCIA_ENVIO,''), @VDOC_EMPRESA = ISNULL(DOC_EMPRESA,''), 
			@VMANUAL_DOC = ISNULL(MANUALES,''), @VREQ_INGRESO = ISNULL(REQUISITO_INGRESO,''), @VCV_CERTIF = ISNULL(CV_CERTIFICADOS,''), @VLOGISTICA = ISNULL(LOGISTICA,''),
			@VCURSO = ISNULL(NOMBRE_CURSO,''), @VMATERIAL = ISNULL(MATERIALES,''), @VESTADO_ENVIO = ISNULL(ESTADO_ENVIO,''), @VRECIBIDO = ISNULL(RECIBIDO,'')
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
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		AUDI_MANUAL = @VMANUAL_DOC,
				AUDI_REQ_INGRESO = @VREQ_INGRESO,
				AUDI_CV_CERTIF = @VCV_CERTIF,
				AUDI_LOGISTICA = @VLOGISTICA,
				CAPA_CURSO = @VCURSO,
				CAPA_MATERIAL = @VMATERIAL,
				CAPA_ESTADO_ENVIO = @VESTADO_ENVIO,
				CAPA_RECIBIDO = @VRECIBIDO,
				CONS_DOC_EMPRESA = @VDOC_EMPRESA,
				CONS_FRECUENCIA_PE = @VFRECUENCIA
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
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Editar Seguimiento '+case when @VSERVICIO = '1' then 'Consultoria'
																																					  when @VSERVICIO = '2' then 'Auditoria'
																																					  when @VSERVICIO = '3' then 'Capacitacion' end +'</b></font>
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
	</div>'	
 
	SET @OFOOTER = '
	<html>
	<body>
	
	<div class="w3-panel w3-topbar"></div>
 
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	SET @OSERVICIO = @VSERVICIO
	
END
 
