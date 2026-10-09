 
CREATE PROCEDURE [dbo].[HOME_INI_VER_SERVICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OSERVICIOS AS VARCHAR(MAX) OUTPUT)
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
		@VTIPOSERVICIO VARCHAR(50),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDIASP		VARCHAR(50),
		@VERROR		VARCHAR(50),
		@VTABLA		VARCHAR(MAX),
		@VARNOMBRE	VARCHAR(300), 
		@VARLUGAR	VARCHAR(300), 
		@VARESTADO	VARCHAR(100), 
		@VARCIERRE	VARCHAR(100),
		@VARCLIENTE	VARCHAR(300), 
		@VARPROYECTO VARCHAR(300), 
		@VARSERVICIO VARCHAR(100), 
		@VARNORMA	VARCHAR(300), 
		@VARFECHAD	VARCHAR(50), 
		@VARFECHAH	VARCHAR(50), 
		@VARHORAS	VARCHAR(100),
		@VARPROFESIONAL VARCHAR(MAX), 
		@VAROBSERVADOR VARCHAR(300), 
		@VID_AGENDA	VARCHAR(50),
		@VID_SERVICIO	VARCHAR(50),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS		VARCHAR(MAX),
		@VSTATUS			VARCHAR(50),
		@VID_DELETE			VARCHAR(50),
		@VTIPO				VARCHAR(50),
		@VFECHA_MINUTA		VARCHAR(50),
		@VNOMBRE			VARCHAR(300),
		@VOBSERV_MINUTA		VARCHAR(400),
		@VACCION			VARCHAR(MAX),
		@VCLAVE_MINUTA		VARCHAR(50),
		@VADJUNTO			VARCHAR(100),
		@VFECHA_PLAN		VARCHAR(50),
		@VOBSERV_PLAN		VARCHAR(400),
		@VFRECUENCIA		VARCHAR(50),
		@VVISTAS_SEL		VARCHAR(50),
		@VPLAN_SEL			VARCHAR(50),
		@VMINUTA_SEL		VARCHAR(50),
		@VPLAN_AUD_SEL		VARCHAR(50),
		@VINF_AUD_SEL		VARCHAR(50),
		@VINF_CAP_SEL		VARCHAR(50),
		@VDATOS_SEL			VARCHAR(50),
		@VDOC_EMPRESA		VARCHAR(50),
		@VMANUAL_DOC		VARCHAR(50),
		@VREQ_INGRESO		VARCHAR(50),
		@VCV_CERTIF			VARCHAR(50),
		@VLOGISTICA			VARCHAR(50),
		@VCURSO				VARCHAR(300),
		@VMATERIAL			VARCHAR(50),
		@VESTADO_ENVIO		VARCHAR(50),
		@VRECIBIDO			VARCHAR(50),
		@VHORAS_ANT		INT,
		@VDIAS_ANT		INT,
		@VHORAS_TOTALES_ANT	INT,
		@VCIERRE			VARCHAR(50),
		@VOBS_CALIF			VARCHAR(4000), 
		@VOBS_LOGIS			VARCHAR(4000),
		@VID_SERVICIO_PROY	VARCHAR(100),
		@VAGREGA			VARCHAR(50),
		@VCANT_SERV			INT,
		@VCANT				INT,
		@VMENSAJE			VARCHAR(400),
		@VACTION			VARCHAR(100)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_DELETE = ISNULL(ID_SERV_DELETE,''),
			@VAGREGA = ISNULL(AGREGA_SERV,''),
			@VACTION = ISNULL(ACTION,'')
			--@VTIPO = ISNULL(TIPO_SELEC,''),
			--@VCLAVE_MINUTA = ISNULL(CLAVE_DELETE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS),
			@VIDCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	SELECT	@VCANT_SERV = COUNT(1)
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO = @VPROYECTO
	AND		ID_TIPO_SERVICIO = @VSERVICIO -- PARA AUDITORIA Y CAPACITACION TIENEN 2 Y 3 EN ESTE CAMPO Y NO EL ID REAL DE LK_PROYECTO_SERVICIO
 
	IF (@VID_DELETE <> '') BEGIN
		
		SELECT	@VCANT = COUNT(1)
		FROM	LK_AGENDA
		WHERE	PROYECTO_SERV_ID = @VID_DELETE
		
		IF (@VCANT = 0) BEGIN
			
			DELETE	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID_DELETE
 
		END ELSE BEGIN
			
			SET @VMENSAJE = 
			'<div class="w3-panel w3-pale-red" style="height: 20px;">
				<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>NO Puede Eliminar el Servicio si el mismo tiene Visitas Cargadas</b></font>
			</div>'
 
		END
 
	END
 
 
	IF (@VAGREGA <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		FECHA_INICIO_SERV = NULL,
				FECHA_FIN_SERV = NULL,
				HORAS_SERV = NULL,
				MONTO_SERV = NULL,
				NOMBRE_SERV = NULL,
				LUGAR_SERV = NULL,
				AGREGA_SERV = NULL,
				ID_SERV_DELETE = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:red;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Servicio de '+CASE WHEN @VSERVICIO = '1' THEN	'Consultoria'
																				 WHEN @VSERVICIO = '2' THEN	'Auditoria'
																				 WHEN @VSERVICIO = '3' THEN	'Capacitacion' END+'</b></font>
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
																				 WHEN @VSERVICIO = '3' THEN	'Capacitacion' END	 +'</td>' +
			  '<td>'+@VFECHA+'</td>' +
			  '<td>'+@VDIASP+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
 
	<div class="w3-left-align"><p>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:red;text-align: left">'
		+'<font style="font-size:28;color:red">'+'<b>'+CASE WHEN @VSERVICIO = '1' THEN	'Consultorias'
																				 WHEN @VSERVICIO = '2' THEN	'Auditorias'
																				 WHEN @VSERVICIO = '3' THEN	'Capacitaciones' END+'</b></font> '
		+'</font>'
		+CASE WHEN @VACTION <> 'HISTORICO' THEN
			'<button onclick="goto('''+@FORM_ID+''',''F8B6A5CD-5252-4CDF-ABEA-67260485E937'');return false;" class="w3-button w3-circle w3-red w3-right w3-border w3-border-white" title="Nuevo">+</button>'
		 ELSE '' END
		+'</p></br>		
	</div>
	'
 
	
	/*
	SET @OFOOTER = '
	<html>
	<body>
 
	<div>
	<p>
		<button onclick="almacenarSeleccion(''AGREGA_SERV'',''SI'');next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Agregar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	<div class="w3-panel w3-topbar"></div>' +
 
	isnull(@VMENSAJE,'')
 
	+'
	</body>
	</html>'
	*/
	SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th01"><b>Nombre</b></th>
			  <th id = "th01"><b>Lugar</b></th>
			  <th id = "th01"><b>Normas</b></th>
			  <th id = "th02"><b>Fecha Inicio</b></th>
			  <th id = "th02"><b>Fecha Fin</b></th>
			  <th id = "th02"><b>Horas</b></th>
			  <th id = "th01"><b>Estado</b></th>
			  <th id = "th01"><b>Cierre</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Servicios CURSOR FOR 
			SELECT	ISNULL(PS.NOMBRE,''),
					ISNULL(PS.LUGAR,''),
					P.NORMAS, --NORMA
					CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103), --FECHA desde
					CONVERT(VARCHAR,PS.FECHA_FIN_REAL,103), --FECHA hasta
					CONVERT(VARCHAR,ISNULL(PS.TOTAL_HORAS_PROYECTADAS,'0')) + '/' + [dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO),--CONVERT(VARCHAR,ISNULL(PS.TOTAL_HORAS_EJECUTADAS,'0')),
					ISNULL(CD.CAT_DATA_DESC,PS.ESTADO_PROYECTO),
					PS.CIERRE,
					PS.ID_PROYECTO_SERVICIO
			FROM	LK_PROYECTO_SERVICIO PS
					INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = PS.ID_PROYECTO
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = PS.ESTADO_PROYECTO AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO') 
			WHERE	PS.ID_PROYECTO = @VPROYECTO
			AND		PS.ID_TIPO_SERVICIO = @VSERVICIO
			ORDER BY CONVERT(VARCHAR,PS.FECHA_FIN_REAL,112)
 
		OPEN Servicios  
		FETCH NEXT FROM Servicios INTO @VARNOMBRE, @VARLUGAR, @VARNORMA, @VARFECHAD, @VARFECHAH, @VARHORAS, @VARESTADO, @VARCIERRE, @VID_SERVICIO_PROY
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VALOR = ''
			SET @VDESCNORMAS = ''
 
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
 
			--SET @VSTATUS = [dbo].[FN_GET_STATUS_AGENDA] (@VID_AGENDA)
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td01">'+@VARNOMBRE+'</td>'+	
				  '<td id = "td01">'+@VARLUGAR+'</td>'+
				  '<td id = "td01">'+@VDESCNORMAS+'</td>'+
				  '<td id = "td02">'+@VARFECHAD+'</td>'+
				  '<td id = "td02">'+@VARFECHAH+'</td>'+
				  '<td id = "td02">'+@VARHORAS+'</td>'+
				  '<td id = "td01">'+@VARESTADO+'</td>'+
				  '<td id = "td01">'+@VARCIERRE+'</td>'+
				  '<td>' +
				  '<i class="'+ CASE WHEN @VSERVICIO = '1' THEN 
											'fas fa-user-tie w3-large"'
										WHEN @VSERVICIO = '2' THEN 
											'fas fa-chalkboard-teacher w3-large"'
										WHEN @VSERVICIO = '3' THEN 
											'fas fa-user-graduate w3-large"' END+
						'style="cursor:pointer;" title="'+	CASE WHEN @VSERVICIO = '1' THEN 
																	'Ver Consultoria"'
																WHEN @VSERVICIO = '2' THEN 
																	'Ver Auditoria"'
																WHEN @VSERVICIO = '3' THEN 
																	'Ver Capacitacion"' END+ 
						'onclick="almacenarSeleccion(''ERROR'','''+''+ ''');almacenarSeleccion(''PROYECTO_SERV_ID'','''+ISNULL(@VID_SERVICIO_PROY,'')+''');almacenarSeleccion(''CIERRE_SERVICIO'','''+@VARCIERRE+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');"></i>' + '&nbsp;' +
						CASE WHEN (@VCANT_SERV = 1 OR @VACTION = 'HISTORICO') THEN '' ELSE 
						'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
							onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Servicio?'');
							if (confirmar){almacenarSeleccion(''ID_SERV_DELETE'','''+@VID_SERVICIO_PROY+ ''');goto('''+@FORM_ID+''',''A77CE927-9D2D-4C15-91CE-34388075B9F7'');}"/>' 
						END 
				   + '
			   </td>'+
				'</tr>'
 
			FETCH NEXT FROM Servicios INTO @VARNOMBRE, @VARLUGAR, @VARNORMA, @VARFECHAD, @VARFECHAH, @VARHORAS, @VARESTADO, @VARCIERRE, @VID_SERVICIO_PROY
		END 
 
		CLOSE Servicios  
		DEALLOCATE Servicios
 
		SET @VTABLA = @VTABLA + '</table>'
 
 
SET @OSERVICIOS = '
<style>
 
th#th01 {
  text-align: left;
}
 
th#th02 {
  text-align: center;
}
 
td#td01 {
  text-align: left;
}
 
td#td02 {
  text-align: center;
}
 
.tooltip {
  position: relative;
  display: inline-block;
  border-bottom: 1px dotted grey;
}
 
.tooltip .tooltiptext {
  visibility: hidden;
  width: 210px;
  background-color: grey;
  color: black;
  text-align: left;
  border-radius: 3px;
  padding: 5px 0;
  position: absolute;
  z-index: 1;
  top: -5px;
  left: 110%;
}
 
.tooltip .tooltiptext::after {
  content: "";
  position: absolute;
  top: 30%;
  right: 100%;
  margin-top: -5px;
  border-width: 5px;
  border-style: solid;
  border-color: transparent grey transparent transparent;
}
.tooltip:hover .tooltiptext {
  visibility: visible;
}
 
</style>
<body>
 
<div class="w3-container">
 
' + ISNULL(@VTABLA,'') + '
  
</div>
 
</body>'
 
END
