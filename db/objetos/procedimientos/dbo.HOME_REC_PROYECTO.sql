CREATE PROCEDURE [dbo].[HOME_REC_PROYECTO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @VCLIENTE		VARCHAR(100),
		@VNOMBRE		VARCHAR(300),
		@VNRO_COTIZA	VARCHAR(50),
		@VFECHA			DATETIME,
		@VFECHA_FIN		DATETIME,
		@VHORAS			VARCHAR(50),
		@VMONTO			VARCHAR(50),
		@VAUDITORIA		VARCHAR(50),
		@VCAPACITACION	VARCHAR(50),
		@VCONSULTORIA	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VNIVEL_RIESGO	VARCHAR(50),
		@VID_PROYECTO	INT,
		@VERROR			VARCHAR(50),
		@VCODIGO		VARCHAR(100),
		@VOBSERVACIONES	VARCHAR(4000),
		@VNORMAS		VARCHAR(400),
		@UNITDESC		VARCHAR(400),
		@USERDESC		VARCHAR(300),
		@VCONTACTO		VARCHAR(400)
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
 
	SELECT	@VID_PROYECTO = ISNULL(PROYECTO_ID,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VCLIENTE	= ISNULL(ID_CLIENTE,''),
			@VNOMBRE	= ISNULL(NORMA_REF,''),
			@VNRO_COTIZA = ISNULL(ID_COTIZACION,''),
			@VFECHA = ISNULL(FECHA_INICIO_REAL,''),
			@VFECHA_FIN = ISNULL(FECHA_FIN_REAL,''),
			@VHORAS = ISNULL(TOTAL_HORAS_PROYECTADAS,'0'),
			@VMONTO = ISNULL(MONTO_PRESUP,'0'),
			@VCODIGO = ISNULL(CODIGO,''),
			@VOBSERVACIONES =  ISNULL(OBSERVACIONES,''),
			@VNORMAS = ISNULL(NORMAS,''),
			@VESTADO = ISNULL(ESTADO_PROYECTO_TOTAL,''),
			@VCONTACTO = ISNULL(CONTACTO,''),
			@VNIVEL_RIESGO = ISNULL(NIVEL_RIESGO,'')
	FROM	LK_PROYECTO
	WHERE	ID_PROYECTO = @VID_PROYECTO
 
	SELECT	@VCONSULTORIA = COUNT(1) FROM LK_PROYECTO_SERVICIO WHERE ID_PROYECTO = @VID_PROYECTO AND ID_TIPO_SERVICIO = '1' --ISNULL(SERV_CONS_PROY,'0'),
	SELECT	@VAUDITORIA = COUNT(1) FROM LK_PROYECTO_SERVICIO WHERE ID_PROYECTO = @VID_PROYECTO AND ID_TIPO_SERVICIO = '2' --ISNULL(SERV_AUDI_PROY,'0')
	SELECT	@VCAPACITACION = COUNT(1) FROM LK_PROYECTO_SERVICIO WHERE ID_PROYECTO = @VID_PROYECTO AND ID_TIPO_SERVICIO = '3' --ISNULL(SERV_CAPA_PROY,'0'),
	
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		CLIENTE = @VCLIENTE,
				NOMBRE_PROY = @VNOMBRE,
				NRO_COTIZA = @VNRO_COTIZA,
				FECHA_INICIO_PROY = @VFECHA,
				FECHA_FIN_PROY = @VFECHA_FIN,
				HORAS_PROY = @VHORAS,
				MONTO_PROY = @VMONTO,
				CODIGO_PROY = @VCODIGO,
				OBSERV_PROY = @VOBSERVACIONES,
				BUFFER = NULL,
				SERV_CONS_PROY = CASE WHEN @VCONSULTORIA > 0 THEN '1' ELSE '0' END,
				SERV_AUDI_PROY = CASE WHEN @VAUDITORIA > 0 THEN '1' ELSE '0' END,
				SERV_CAPA_PROY = CASE WHEN @VCAPACITACION > 0 THEN '1' ELSE '0' END,
				--ESTADO_PROY = @VESTADO
				CONTACTO_PROY = @VCONTACTO,
				NIVEL_RIESGO = @VNIVEL_RIESGO
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
 
	<body>
	
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#5DADE2;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Proyecto</b></font>
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
		<button onclick="saveValues(''BUFFER'');next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#5DADE2"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#5DADE2"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
END
