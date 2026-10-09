CREATE   PROCEDURE [dbo].[SV_01_REC_EMPLEADO_APT]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @VCLAVE			VARCHAR(100),
		@VOBSERVACION	VARCHAR(400),
		@VEMPLEADO		VARCHAR(50),
		@VAPTITUD		VARCHAR(100),
		@VCALIFICACION	VARCHAR(50),
		@VERROR		VARCHAR(50),
		@UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
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
 
	SELECT	@VCLAVE = ISNULL(CLAVE,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	
		--RECUPERO CAMPOS DE LK_TIPO_SERVICIOS--
		SELECT	@VEMPLEADO	= ISNULL(ID_EMPLEADO,''),
				@VAPTITUD = ISNULL(APT.DESC_APTITUD,''),
				@VCALIFICACION = ISNULL(CALIFICACION,''),
				@VOBSERVACION = ISNULL(OBSERVACION,'')
		FROM	LK_EMPLEADOS_APTITUD EMP
				LEFT JOIN LK_APTITUDES APT ON (EMP.ID_APTITUD = APT.ID_APTITUD)
		WHERE	ID_EMPLE_APTITUD = @VCLAVE
 
		UPDATE	TMT_SV_01
		SET		EMPLEADO = @VEMPLEADO,
				APTITUD = @VAPTITUD,
				CALIFICACION = @VCALIFICACION,
				OBSERVACION = @VOBSERVACION
		WHERE	PAR_KEY = @IPKEYJOB
	
 
	SET @OHEADER = '
	<html>
 
	<body>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Empleado Aptitud</b></font>
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
		<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
END
 
