CREATE PROCEDURE [dbo].[HOME_INI_MOD_VIATICOS_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT
 )
AS
 
DECLARE	@VID			VARCHAR(50),
		@VSERVICIO		VARCHAR(100),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VPROYECTO		VARCHAR(300),
		@VCLIENTE		VARCHAR(300),
		@VIDCLIENTE		VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VFECHA			VARCHAR(50),
		@VDIASP			VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VERROR			VARCHAR(50),
		@VID_VIATICO	VARCHAR(50),
		@VARNORMA		VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VID_SERVICIO	INT,
		@VID_PROYECTO	INT,
		@VESTADO		VARCHAR(100),
		@VFECHAD		VARCHAR(50),
		@VFECHAH		VARCHAR(50),
		@VDIAS			VARCHAR(50),
		@VTIPO_PROV		VARCHAR(50),
		@VID_DETALLE	VARCHAR(50),
		@VRESERVA		VARCHAR(100),
		@VVUELO			VARCHAR(50),
		@VORIGEN		VARCHAR(100),
		@VDESTINO		VARCHAR(100),
		@VSALIDA		VARCHAR(100),
		@VLLEGADA		VARCHAR(100),
		@VLOCAL			VARCHAR(100),
		@VFINGRESO		DATETIME,
		@VFEGRESO		DATETIME,
		@VFPARTIDA		DATETIME,
		@VFLLEGADA		DATETIME,
		@VPAGA_CONSULTOR VARCHAR(50),
		@VPAGA_CONSULTORA VARCHAR(50),
		@VRENDICION_CLIENTE	VARCHAR(50),
		@VKMS				VARCHAR(50),
		@VPEAJES			VARCHAR(50),
		@VPROYECTO_SERV	VARCHAR(50),
		@VNOMBRE		VARCHAR(300),
		@VHORAS		VARCHAR(50)
 
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
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_VIATICO = ISNULL(HOJA_RUTA_ID,''),
			@VTIPO_PROV = ISNULL(TIPO_PROV,''),
			@VID_DETALLE = ISNULL(ID_DETALLE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VID_PROYECTO  = ID_PROYECTO,
			@VID_SERVICIO  = ID_SERVICIO,
			@VPROYECTO_SERV = PROYECTO_SERV_ID
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO  = '('+P.CODIGO+') - '+P.NORMA_REF,
			@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VFECHAD = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(A.NORMA,''),
			@VCONSULTORES = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
			@VHORAS = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA)
			--@VID_SERVICIO = ID_SERVICIO
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
	
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
 
	SELECT	@VRESERVA = ISNULL(DET_PROV_RESERVA,''),
			@VFECHA = ISNULL(DET_PROV_FECHA,''),
			@VVUELO = ISNULL(DET_PROV_VUELO,''),
			@VORIGEN = ISNULL(DET_PROV_ORIGEN,''),
			@VDESTINO = ISNULL(DET_PROV_DESTINO,''),
			@VSALIDA = ISNULL(DET_PROV_SALIDA,''),
			@VLLEGADA = ISNULL(DET_PROV_LLEGADA,''),
			@VLOCAL = ISNULL(DET_PROV_LOCAL,''),
			@VFINGRESO = ISNULL(DET_PROV_FINGRESO,''),
			@VFEGRESO = ISNULL(DET_PROV_FEGRESO,''),
			@VFPARTIDA = ISNULL(DET_PROV_FPARTIDA,''),
			@VFLLEGADA = ISNULL(DET_PROV_FLLEGADA,''),
			@VPAGA_CONSULTOR = ISNULL(PAGA_CONSULTOR,''),
			@VPAGA_CONSULTORA = ISNULL(PAGA_CONSULTORA,''),
			@VRENDICION_CLIENTE = ISNULL(RENDICION_CLIENTE,''),
			@VKMS = ISNULL(DET_PROV_KMS,''),
			@VPEAJES = ISNULL(DET_PROV_PEAJES,'')
	FROM	LK_PROYECTO_VIATICOS_DET
	WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DETALLE
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		--HOJA_RUTA_ID = NULL,
				DET_PROV_RESERVA = @VRESERVA,
				DET_PROV_FECHA = @VFECHA,
				DET_PROV_VUELO = @VVUELO,
				DET_PROV_ORIGEN = @VORIGEN,
				DET_PROV_DESTINO = @VDESTINO,
				DET_PROV_SALIDA = @VSALIDA,
				DET_PROV_LLEGADA = @VLLEGADA,
				DET_PROV_LOCAL = @VLOCAL,
				DET_PROV_FINGRESO = @VFINGRESO,
				DET_PROV_FEGRESO = @VFEGRESO,
				DET_PROV_FPARTIDA = @VFPARTIDA,
				DET_PROV_FLLEGADA = @VFLLEGADA,
				PAGA_CONSULTOR = @VPAGA_CONSULTOR,
				PAGA_CONSULTORA = @VPAGA_CONSULTORA,
				RENDICION_CLIENTE = @VRENDICION_CLIENTE,
				DET_PROV_KMS = @VKMS,
				DET_PROV_PEAJES = @VPEAJES
		WHERE	PAR_KEY = @IPKEYJOB
	END		
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560''); return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#52BE80;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modifica Detalle Viatico '+UPPER(substring(@VTIPO_PROV,1,1))+LOWER(SUBSTRING(@VTIPO_PROV,2,LEN(@VTIPO_PROV)))+'</b></font>
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
			<th><b>Nombre</b></th>
			<th><b>Normas</b></th>
			<th><b>Dias</b></th>
			<th><b>Horas</b></th>
			<th><b>Fecha Desde</b></th>
			<th><b>Fecha Hasta</b></th>
			<th><b>Estado</b></th>
			<th><b>Profesional</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VPROYECTO+'</td>' +
			  '<td>'+@VSERVICIO+'</td>' +
			  '<td>'+ISNULL(@VNOMBRE,'')+'</td>' +
			  '<td>'+@VDESCNORMAS+'</td>' +
			  '<td>'+@VDIAS+'</td>' +
			  '<td>'+@VHORAS+'</td>' +
			  '<td>'+@VFECHAD+'</td>' +
			  '<td>'+@VFECHAH+'</td>' +
			  '<td>'+@VESTADO+'</td>' +
			  '<td>'+@VCONSULTORES+'</td> 
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
 
	'
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-panel w3-topbar"></div>
 
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	
END
