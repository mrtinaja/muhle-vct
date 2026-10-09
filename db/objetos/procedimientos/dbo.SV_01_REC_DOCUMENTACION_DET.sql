CREATE   PROCEDURE [dbo].[SV_01_REC_DOCUMENTACION_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @VCLAVE		VARCHAR(100),
		@VDET_DESC	VARCHAR(400),
		@VESTADO	VARCHAR(50),
		@VCOMENT	VARCHAR(400),
		@VGRUPO		VARCHAR(50),
		@VERROR		VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VCLAVE_DOC VARCHAR(100),
		@VCODIGO	VARCHAR(50),
		@VDESC		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDETALLE	VARCHAR(50),
		@VORDEN		NUMERIC(5,0)
 
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
 
	SELECT	@VCLAVE = ISNULL(CLAVE_DETALLE,''),
			@VCLAVE_DOC = CLAVE_DOC,
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCODIGO = CODE_DOCUMENTACION,
			@VDESC = DESC_DOCUMENTACION,
			@VFECHA = CONVERT(VARCHAR,FECHA_ALTA,103) ,
			@VDETALLE = DETALLE_DOCUMENTACION
	FROM	LK_DOCUMENTACION
	WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
 
	IF (@VERROR <> 'SI') BEGIN
		--RECUPERO CAMPOS DE LK_TIPO_SERVICIOS--
		SELECT	@VDET_DESC	= ISNULL(DESC_DOC_DET,''),
				@VCOMENT = ISNULL(COMENT_DOC_DET,''),
				@VESTADO = ISNULL(STATUS_DOC_DET,''),
				@VGRUPO = GRUPO_DOC_DET,
				@VORDEN = ISNULL(ORDEN,0)
		FROM	LK_DOCUMENTACION_DET
		WHERE	ID_DOCUMENTACION_DET = @VCLAVE
	
		UPDATE	TMT_SV_01
		SET		DESCRIPCION_DET = @VDET_DESC,
				COMENTARIO_DET = @VCOMENT,
				GRUPO_DET = @VGRUPO,
				ESTADO_DET = @VESTADO,
				ORDEN = @VORDEN
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
 
	<body>
	
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:25%;background-color:#641E16;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Detalle</b></font>
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
 
	<div class="w3-panel w3-topbar"></div>
 
	<div class="w3-container">
		<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
			<th><b>Codigo</b></th>
			<th><b>Documentacion</b></th>
			<th><b>Fecha Alta</b></th>
			<th><b>Detalle</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCODIGO+'</td>'+
			  '<td>'+@VDESC+'</td>'+
			  '<td>'+@VFECHA+'</td>'+
			  '<td>'+@VDETALLE+'</td>
			</tr>
	</table>
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
		<button onclick="goto('''+@FORM_ID+''',''4B0F1063-4306-45F1-8C86-E41A88987F90'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#641E16"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
END
