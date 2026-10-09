 
CREATE PROCEDURE [dbo].[HOME_INI_ADD_MINUTACIE_PROY]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
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
		@VICONS				VARCHAR(MAX)
 
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
 
	SELECT	@VID = ISNULL(PROYECTO_ID,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS),
			@VIDCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VID
 
	DECLARE Servicios CURSOR FOR 
		SELECT	ID_TIPO_SERVICIO, ID_PROYECTO_SERVICIO
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID
			
	OPEN Servicios  
	FETCH NEXT FROM Servicios INTO @VTIPO, @VSERVICIO
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		
		SET @VICONS = isnull(@VICONS,'') +
			'<i class="'+ CASE WHEN @VTIPO = '1' THEN 
								'fas fa-user-tie w3-large"'
							WHEN @VTIPO = '2' THEN 
								'fas fa-chalkboard-teacher w3-large"'
							WHEN @VTIPO = '3' THEN 
								'fas fa-user-graduate w3-large"' END+
			'style="cursor:pointer;" title="'+	CASE WHEN @VTIPO = '1' THEN 
														'Consultoria"></i>'
													WHEN @VTIPO = '2' THEN 
														'Auditoria"></i>'
													WHEN @VTIPO = '3' THEN 
														'Capacitacion"></i>' END
			+ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
					
		FETCH NEXT FROM Servicios INTO @VTIPO, @VSERVICIO
	END 
 
	CLOSE Servicios  
	DEALLOCATE Servicios
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		FECHA_MC_PROY = NULL,
				OBSERV_MC_PROY = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:CornflowerBlue"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:CornflowerBlue;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Agrega Minuta de Cierre Proyecto</b></font>
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
			<th><b>Servicios</b></th>
			<th><b>Fecha Inicio</b></th>
			<th><b>Horas</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+ISNULL(@VCLIENTE,'')+'</td>'+
			  '<td>'+ISNULL(@VNORMA,'')+'</td>' +
			  '<td>'+ISNULL(@VICONS,'')+'</td>' +
			  '<td>'+ISNULL(@VFECHA,'')+'</td>' +
			  '<td>'+ISNULL(@VDIASP,'')+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>'
 
	
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-card">
		   <div class="w3-col w3-container" style="background-color:CornflowerBlue;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Adjuntar Minuta</b></font>
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
		<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:CornflowerBlue"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Agregar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:CornflowerBlue"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
	
END
