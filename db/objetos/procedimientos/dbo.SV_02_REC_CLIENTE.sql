CREATE PROCEDURE [dbo].[SV_02_REC_CLIENTE]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VCUIT			VARCHAR(50),
		@VRAZON_SOCIAL	VARCHAR(300),
		@VCALLE			VARCHAR(100),
		@VNRO			VARCHAR(30),
		@VPISO			VARCHAR(30),
		@VLOCALIDAD		VARCHAR(100),
		@VPROVINCIA		VARCHAR(50),
		@VTELEFONO1		VARCHAR(100),
		@VTELEFONO2		VARCHAR(100),
		@VEMAIL			VARCHAR(100),
		@VIVA			VARCHAR(50),
		@VCONTACTO		VARCHAR(100),
		@VTIPO_CLIENTE	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VOBSERVACIONES	VARCHAR(400),
		@VERROR			VARCHAR(50),
		@VCANT			INT,
		@VCLAVE			VARCHAR(100)	
 
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
 
	SELECT	@VCLAVE = ISNULL(CLAVE,'')
	FROM	TMT_SV_02
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCUIT = ISNULL(CUIT_CLIENTE,''),
			@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,''),
			@VCALLE = ISNULL(CALLE_CLIENTE,''),
			@VNRO = ISNULL(NRO_CALLE_CLIENTE,''),
			@VPISO = ISNULL(PISO_DEPTO_CLIENTE,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD_CLIENTE,''),
			@VPROVINCIA = ISNULL(PROVINCIA_CLIENTE,''),
			@VTELEFONO1 = ISNULL(TEL1_CLIENTE,''),
			@VTELEFONO2 = ISNULL(TEL2_CLIENTE,''),
			@VEMAIL = ISNULL(EMAIL_CLIENTE,''),
			@VIVA = ISNULL(IVA_CLIENTE,''),
			@VCONTACTO = ISNULL(CONTACTO_CLIENTE,''),
			@VTIPO_CLIENTE = ISNULL(TIPO_CLIENTE,''),
			@VESTADO = ISNULL(STATUS_CLIENTE,''),
			@VOBSERVACIONES = ISNULL(OBSERV_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLAVE
 
	UPDATE	TMT_SV_02
	SET		CUIT = @VCUIT,
			RAZON_SOCIAL = @VRAZON_SOCIAL,
			CALLE = @VCALLE,
			NRO = @VNRO,
			PISO = @VPISO,
			LOCALIDAD = @VLOCALIDAD,
			PROVINCIA = @VPROVINCIA,
			TELEFONO1 = @VTELEFONO1,
			TELEFONO2 = @VTELEFONO2,
			EMAIL = @VEMAIL,
			IVA = @VIVA,
			CONTACTO = @VCONTACTO,
			TIPO_CLIENTE = @VTIPO_CLIENTE,
			ESTADO = @VESTADO,
			OBSERVACIONES = @VOBSERVACIONES
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<html>
 
	<body>
	
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:25%;background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Cliente</b></font>
			</p>
		</div>
		
		<div class="w3-col w3-container" style="width:75%;background-color:#D6DBDF;text-align:right">
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
 
	<div class="w3-panel w3-topbar">
	</div>
	
	</body>
	</html>'
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''F7CB8283-07A6-479F-8FD1-334AE1670B1D'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
END
 
 
