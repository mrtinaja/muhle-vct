CREATE PROCEDURE [dbo].[HOME_REC_HOJA_RUTA]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OLABEL1	AS VARCHAR(100) OUTPUT,
 @OLABEL2	AS VARCHAR(100) OUTPUT,
 @OLABEL3	AS VARCHAR(100) OUTPUT,
 @OLABEL4	AS VARCHAR(100) OUTPUT,
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(8000) OUTPUT)
AS
 
DECLARE	@VID				VARCHAR(50),
		@VSERVICIO			VARCHAR(50),
		@VID_HOJA			VARCHAR(50),
		@VCLIENTE			VARCHAR(300),
		@VFECHA				DATETIME,
		@VNOMBRE			VARCHAR(100),
		@VCONSULTOR			VARCHAR(50),
		@VCONSULTOR_ACOMP	VARCHAR(50),
		@VVISITA			DATETIME,
		@VOBSERVACIONES		VARCHAR(400),
		@VFECHA_CIERRE		DATETIME,
		@UNITDESC			VARCHAR(300),
		@USERDESC			VARCHAR(300),
		@VERROR				VARCHAR(50),
		@VID_AGENDA			VARCHAR(50),
		@VPROYECTO			VARCHAR(50),
		@VNORMA				VARCHAR(300),
		@VFECHAP			VARCHAR(50),
		@VDIASP				VARCHAR(50)
 
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
 
	SELECT	--@VPROYECTO = ISNULL(PROYECTO_ID,''),
			--@VID = ISNULL(PROYECTO_SERV_ID,''),
			--@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHAP  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS/24)
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
	
	SELECT	@VFECHA = FECHA_DOCUM,
			@VNOMBRE = NRO_DOCUM_INTERNO,
			@VCONSULTOR = CONSULTOR,
			@VCONSULTOR_ACOMP = CONSULTOR_ACOMP,
			@VVISITA = NULLIF(ISNULL(VISITA_MES,''),''),
			@VOBSERVACIONES = OBSERVACIONES,
			@VFECHA_CIERRE = NULLIF(ISNULL(FECHA_CIERRE,''),'')
	FROM	LK_PROYECTO_DOCUM 
	WHERE	ID_AGENDA = @VID_AGENDA
 
	IF (@VERROR <> 'SI') BEGIN
 
		UPDATE	XAGENDA
		SET		--HOJA_RUTA_ID = NULL,
				FECHA_HR = @VFECHA,
				CONSULTOR_HR = @VCONSULTOR,
				VISITA_MES_HR = @VVISITA,
				CONSULTOR_ACOMP_HR = @VCONSULTOR_ACOMP,
				OBSERVACION_HR = @VOBSERVACIONES,
				FECHA_CIERRE_HR = @VFECHA_CIERRE,
				NOMBRE_HR = @VNOMBRE
		WHERE	PAR_KEY = @IPKEYJOB
	END
	
	--SELECT * FROM LK_TIPO_SERVICIOS
	/*	1	Consultoria
		2	Auditoria
		3	Capacitacion*/
	IF (@VSERVICIO = '1') BEGIN
		SET @OLABEL1 = 'Visita Mes:'
		SET @OLABEL2 = 'Nro/Nombre Int.:'
		SET @OLABEL3 = 'Consultor:'
		SET @OLABEL4 = 'Consultor Acomp.:'
	END
 
	IF (@VSERVICIO = '2') BEGIN
		SET @OLABEL1 = 'F. Entrega Inf.:'
		SET @OLABEL2 = 'Fechas:'
		SET @OLABEL3 = 'Auditor:'
		SET @OLABEL4 = 'Auditor Acomp.:'
	END
 
	IF (@VSERVICIO = '3') BEGIN
		SET @OLABEL1 = 'Fechas:'
		SET @OLABEL2 = 'Capacitacion (Tipo,Lugar):'
		SET @OLABEL3 = 'Instructor:'
		SET @OLABEL4 = 'Instructor Acomp.:'
	END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#F4D03F"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#F4D03F;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Hoja de Ruta</b></font>
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
			  '<td>'+@VFECHAP+'</td>' +
			  '<td>'+@VDIASP+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	<div class="w3-left-align"><p>
	<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
	+'<b>Servicio </b>'+'<font style="font-size:24;color:red">'+'<b>'+ CASE WHEN @VSERVICIO = '1' THEN	'Consultoria'
																				 WHEN @VSERVICIO = '2' THEN	'Auditoria'
																				 WHEN @VSERVICIO = '3' THEN	'Capacitacion' END	 +'</b></font> '
	+'</font>'
	+'</p></div>'
 
	
 
	SET @OFOOTER = '
	<html>
	<body>
	
	<div>
	<p>
		<button onclick="saveValues(''BUFFER'');next('''+@FORM_ID+''');" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#F4D03F"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#F4D03F"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	</body>
	</html>'
 
END
 
