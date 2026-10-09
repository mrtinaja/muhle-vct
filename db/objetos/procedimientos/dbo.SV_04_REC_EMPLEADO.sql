CREATE PROCEDURE [dbo].[SV_04_REC_EMPLEADO]
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
		@VAPELLIDO		VARCHAR(100),
		@VNOMBRE		VARCHAR(100),
		@VTIPO_DOC		VARCHAR(50),
		@VNRO_DOC		VARCHAR(50),
		@VCUIT			VARCHAR(50),
		@VINGRESO		VARCHAR(50),
		@VUSUARIO		VARCHAR(100),
		@VCLAVE			VARCHAR(100),
		@VCALLE			VARCHAR(100),
		@VNRO			VARCHAR(30),
		@VPISO			VARCHAR(30),
		@VLOCALIDAD		VARCHAR(100),
		@VPROVINCIA		VARCHAR(50),
		@VTELEFONO1		VARCHAR(100),
		@VTELEFONO2		VARCHAR(100),
		@VEMAIL			VARCHAR(100),
		@VFORMACION		VARCHAR(100),
		@VMOVILIDAD		VARCHAR(50),
		@VPERFIL		VARCHAR(50),
		@VAUDITORIA		VARCHAR(50),
		@VCAPACITACION	VARCHAR(50), 
		@VCONSULTORIA	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VID_CONSULTOR	VARCHAR(50),
		@VERROR			VARCHAR(50),
		@VCANT			INT,
		@VDIAS			VARCHAR(50),
		@VPKEY_CV		VARCHAR(100),
		@VID_EMPLEADO	INT,
		@VID_SELEC		VARCHAR(50)
 
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
 
	SELECT	@VID_SELEC = ISNULL(ID_SELEC,'')
	FROM	TMT_SV_04
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE_EMPLEADO,''),
			@VAPELLIDO = ISNULL(APELLIDO_EMPLEADO,''),
			@VTIPO_DOC = ISNULL(TIPO_DOC_EMP,''),
			@VNRO_DOC = ISNULL(NRO_DOC_EMP,''),
			@VCUIT = ISNULL(CUIT_EMP,''),
			@VINGRESO = ISNULL(INGRESA_SISTEMA,''),
			@VUSUARIO = ISNULL(USUARIO_EMP,''),
			@VCLAVE = ISNULL(PASS_EMP,''),			
			@VCALLE = ISNULL(CALLE_EMP,''),
			@VNRO = ISNULL(NRO_CALLE_EMP,''),
			@VPISO = ISNULL(PISO_DEPTO_EMP,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD_EMP,''),
			@VPROVINCIA = ISNULL(PROVINCIA_EMP,''),
			@VTELEFONO1 = ISNULL(TEL1_EMP,''),
			@VTELEFONO2 = ISNULL(TEL2_EMP,''),
			@VEMAIL = ISNULL(EMAIL_EMP,''),
			@VFORMACION = ISNULL(FORMACION_EMP,''),
			@VMOVILIDAD = ISNULL(MOVILIDAD_EMP,''),
			@VPERFIL = ISNULL(PERFIL_EMP,''),
			@VESTADO = ISNULL(STATUS_EMP,''),
			@VDIAS = ISNULL(DIAS_MENSUALES,'0')
	FROM	LK_EMPLEADOS
	WHERE	ID_EMPLEADO = @VID_SELEC
 
	SELECT	@VCONSULTORIA = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
	FROM	LK_EMPLEADOS_TIPO
	WHERE	ID_EMPLEADO = @VID_SELEC
	AND		ID_TIPO = '1'
 
	SELECT	@VAUDITORIA = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
	FROM	LK_EMPLEADOS_TIPO
	WHERE	ID_EMPLEADO = @VID_SELEC
	AND		ID_TIPO = '2'
 
	SELECT	@VCAPACITACION = CASE WHEN ISNULL(ID_TIPO,'0') = '0' THEN '0' ELSE '1' END
	FROM	LK_EMPLEADOS_TIPO
	WHERE	ID_EMPLEADO = @VID_SELEC
	AND		ID_TIPO = '3'
	
	UPDATE	TMT_SV_04
	SET		CUIT = @VCUIT,
			CALLE = @VCALLE,
			NRO = @VNRO,
			PISO = @VPISO,
			LOCALIDAD = @VLOCALIDAD,
			PROVINCIA = @VPROVINCIA,
			TELEFONO1 = @VTELEFONO1,
			TELEFONO2 = @VTELEFONO2,
			EMAIL = @VEMAIL,
			ESTADO = @VESTADO,
			NOMBRE = @VNOMBRE,
			APELLIDO = @VAPELLIDO,
			TIPO_DOC = @VTIPO_DOC,
			NRO_DOC = @VNRO_DOC,
			INGRESO = @VINGRESO,
			USUARIO = @VUSUARIO,
			CLAVE = @VCLAVE,
			FORMACION = @VFORMACION,
			MOVILIDAD = @VMOVILIDAD,
			PERFIL = @VPERFIL,
			CONS_TIPO_CONS = @VCONSULTORIA,
			CONS_TIPO_AUDI = @VAUDITORIA,
			CONS_TIPO_CAPA = @VCAPACITACION,
			DIAS_MENSUALES = @VDIAS
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<html>
 
	<body>
	
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:25%;background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Empleado/Consultor</b></font>
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
 
	 <div class="w3-card">
		   <div class="w3-col w3-container" style="background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Adjuntar CV</b></font>
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
		<button onclick="next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''9290878C-C546-43A1-8B89-B53C7039DCB8'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
	
END
 
 
