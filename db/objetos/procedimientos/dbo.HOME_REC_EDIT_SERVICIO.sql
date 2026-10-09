 
CREATE PROCEDURE [dbo].[HOME_REC_EDIT_SERVICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OPLAN		AS VARCHAR(MAX) OUTPUT,
 @OALERTA	AS VARCHAR(400) OUTPUT)
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
		@VARFECHAD	VARCHAR(50), 
		@VARFECHAH	VARCHAR(50), 
		@VARHORAS	VARCHAR(50),
		@VARPROFESIONAL VARCHAR(MAX), 
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
		@VPLAN_SEL		VARCHAR(50),
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
		@VNOMBRE_SERV		VARCHAR(300),
		@VLUGAR_SERV		VARCHAR(300),
		@VSTRUCTURE			VARCHAR(100),
		@VTIPO_SERVICIO		VARCHAR(50),
		@VTOTAL_EJEC		INT,
		@VTOTAL_SERV		INT,
		@VACTION			VARCHAR(100),
		@VOBS				VARCHAR(MAX)
 
BEGIN	
	
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VPROYECTO  = ISNULL(PROYECTO_ID,''),
			@VTIPO_SERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_DELETE = ISNULL(ID_DELETE,''),
			@VTIPO = ISNULL(TIPO_SELEC,''),
			@VCLAVE_MINUTA = ISNULL(CLAVE_DELETE,''),
			@VACTION = ISNULL(ACTION,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VTIPO_SERVICIO='1'
		BEGIN
			SELECT	@VID = ID_PROYECTO_SERVICIO,
					@VFECHA_INI = FECHA_INICIO_REAL,
					@VFECHA_FIN = NULLIF(ISNULL(FECHA_FIN_REAL,''),''),
					@VDIAS		= TOTAL_HORAS_PROYECTADAS,
					@VMONTO		= MONTO_PRESUP,
					@VSERVICIO  = ID_TIPO_SERVICIO,
					@VPROYECTO  = ID_PROYECTO,
					@VCIERRE = ISNULL(CIERRE,'NO'),
					@VNOMBRE_SERV = ISNULL(NOMBRE,''),
					@VLUGAR_SERV = ISNULL(LUGAR,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE ID_PROYECTO = @VPROYECTO AND ID_TIPO_SERVICIO = @VTIPO_SERVICIO
		END
	ELSE
		BEGIN
			SELECT	@VFECHA_INI = FECHA_INICIO_REAL,
					@VFECHA_FIN = NULLIF(ISNULL(FECHA_FIN_REAL,''),''),
					@VDIAS		= TOTAL_HORAS_PROYECTADAS,
					@VMONTO		= MONTO_PRESUP,
					@VSERVICIO  = ID_TIPO_SERVICIO,
					@VPROYECTO  = ID_PROYECTO,
					@VCIERRE = ISNULL(CIERRE,'NO'),
					@VNOMBRE_SERV = ISNULL(NOMBRE,''),
					@VLUGAR_SERV = ISNULL(LUGAR,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE ID_PROYECTO_SERVICIO = @VID
		END
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIASP	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS),
			@VIDCLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	IF ISNULL(@VTIPO,'') = '' BEGIN
		SET @VTIPO = 'A'
	END
 
	SELECT	@VTOTAL_EJEC = CONVERT(INT,[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, ID_PROYECTO_SERVICIO)),--TOTAL_HORAS_EJECUTADAS,
			@VTOTAL_SERV = TOTAL_HORAS_PROYECTADAS
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VID
 
	IF ((@VTOTAL_EJEC > @VTOTAL_SERV) AND @VTIPO = 'A') BEGIN
		SET @OALERTA = '<script type="text/javascript">alert("Ha Superado el Total de Horas Proyectadas del Servicio");</script>'
	END
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		FECHA_INICIO_SERV = @VFECHA_INI,
				FECHA_FIN_SERV = @VFECHA_FIN,
				HORAS_SERV = @VDIAS,
				MONTO_SERV = @VMONTO,
				CIERRE_SERVICIO = @VCIERRE,
				NOMBRE_SERV = @VNOMBRE_SERV,
				LUGAR_SERV = @VLUGAR_SERV
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	IF (@VID_DELETE <> '') BEGIN
		
		--SET	@VHORAS_TOTALES_ANT = ISNULL(@VHORAS_ANT,0) * @VDIAS_ANT
		IF (@VSERVICIO <> '3') BEGIN
				--CONSULTORIA Y AUDITORIA
				--LA SUMA DE HORAS ES IGUAL A: EL TOTAL DE HORAS CARGADAS POR N DIAS POR N CONSULTORES
 
			SELECT	@VHORAS_TOTALES_ANT = SUM(HORAS)
			FROM	LK_AGENDA_EMPLEADO
			WHERE	HOLIDAYTEXT = convert(varchar,@VID_DELETE)
 
			UPDATE LK_AGENDA_EMPLEADO
			SET	   TIPO = 'D', HOLIDAYTEXT = ''
			WHERE  HOLIDAYTEXT = @VID_DELETE
		
			--actualizo el total de horas del servicio y del proyecto
			UPDATE	LK_PROYECTO_SERVICIO
			SET		--ESTADO_PROYECTO = 'ENCURSO',
					TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) - ISNULL(@VHORAS_TOTALES_ANT,0)
			WHERE	ID_PROYECTO_SERVICIO = @VID
 
			UPDATE	LK_PROYECTO
			SET		--ESTADO_PROYECTO_TOTAL = 'ENCURSO',
					TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) - ISNULL(@VHORAS_TOTALES_ANT,0)
			WHERE	ID_PROYECTO = @VPROYECTO
 
			--ACTUALIZO LOS PORCENTAJES
			UPDATE	LK_PROYECTO_SERVICIO
			SET		PORCENTAJE_AVANCE = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
			WHERE	ID_PROYECTO_SERVICIO = @VID
 
			UPDATE	LK_PROYECTO
			SET		PORCENTAJE_AVANCE_TOTAL = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
			WHERE	ID_PROYECTO = @VPROYECTO	
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
 
		END ELSE BEGIN
 
			SELECT	@VDIAS_ANT = DIAS
			FROM	LK_AGENDA
			WHERE	ID_AGENDA = @VID_DELETE
 
			SELECT	TOP 1 @VHORAS_ANT = HORAS
			FROM	LK_AGENDA_EMPLEADO
			WHERE	HOLIDAYTEXT = @VID_DELETE
 
			SET	@VHORAS_TOTALES_ANT = ISNULL(@VHORAS_ANT,0) * @VDIAS_ANT
 
			UPDATE LK_AGENDA_EMPLEADO
			SET	   TIPO = 'D', HOLIDAYTEXT = ''
			WHERE  HOLIDAYTEXT = @VID_DELETE
		
			--actualizo el total de horas del servicio y del proyecto
			UPDATE	LK_PROYECTO_SERVICIO
			SET		--ESTADO_PROYECTO = 'ENCURSO',
					TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) - ISNULL(@VHORAS_TOTALES_ANT,0)
			WHERE	ID_PROYECTO_SERVICIO = @VID
 
			UPDATE	LK_PROYECTO
			SET		--ESTADO_PROYECTO_TOTAL = 'ENCURSO',
					TOTAL_HORAS_EJECUTADAS = ISNULL(TOTAL_HORAS_EJECUTADAS,0) - ISNULL(@VHORAS_TOTALES_ANT,0)
			WHERE	ID_PROYECTO = @VPROYECTO
 
			--ACTUALIZO LOS PORCENTAJES
			UPDATE	LK_PROYECTO_SERVICIO
			SET		PORCENTAJE_AVANCE = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
			WHERE	ID_PROYECTO_SERVICIO = @VID
 
			UPDATE	LK_PROYECTO
			SET		PORCENTAJE_AVANCE_TOTAL = CASE WHEN TOTAL_HORAS_PROYECTADAS = 0 THEN 0 ELSE TOTAL_HORAS_EJECUTADAS * 100 / TOTAL_HORAS_PROYECTADAS END
			WHERE	ID_PROYECTO = @VPROYECTO	
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
 
		END
		
		DELETE LK_PROYECTO_DOCUM_DET WHERE ID_PROYECTO_DOCUM IN (SELECT ID_PROYECTO_DOCUM FROM LK_PROYECTO_DOCUM WHERE ID_AGENDA = @VID_DELETE)
		DELETE LK_PROYECTO_DOCUM WHERE ID_AGENDA = @VID_DELETE
		DELETE LK_PROYECTO_VIATICOS WHERE ID_AGENDA = @VID_DELETE
		DELETE LK_PROYECTO_VIATICOS_DET WHERE ID_AGENDA = @VID_DELETE
		DELETE LK_AGENDA WHERE ID_AGENDA = @VID_DELETE
		
	END
 
	IF (@VCLAVE_MINUTA <> '') BEGIN
		SELECT	@VADJUNTO = ISNULL(ID_ADJUNTO,'')
		FROM	LK_PROYECTO_DOCUM
		WHERE ID_PROYECTO_DOCUM = @VCLAVE_MINUTA
 
		DELETE LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_MINUTA
		DELETE PHYSICAL_ATTACHED_DOCUMENT WHERE PKEY = @VADJUNTO
 
		UPDATE	XAGENDA
		SET		CLAVE_DELETE = NULL
		WHERE PAR_KEY = @IPKEYJOB
	END
 
	SET @VSTRUCTURE = CASE WHEN @VSERVICIO = '1' THEN '522967A7-DDC9-465B-969B-85997AE1B085' ELSE 'A77CE927-9D2D-4C15-91CE-34388075B9F7' END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="almacenarSeleccion(''PROYECTO_SERV_ID'','''+@VSERVICIO+ ''');goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:red;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Detalle Servicio</b></font>
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
 
	<div class="w3-panel w3-topbar"></div>'
 
	
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div>
	<p>
		<button onclick="almacenarSeleccion(''GRABA_SERV'',''SI'');next('''+@FORM_ID+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="almacenarSeleccion(''PROYECTO_SERV_ID'','''+@VSERVICIO+ ''');goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:red"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
 
	</body>
	</html>'
 
	IF ISNULL(@VTIPO,'') = '' BEGIN
		SET @VTIPO = 'A'
	END
 
	IF (@VTIPO = 'A') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b></b></th>
			  <th id = "th01"><b>Cliente</b></th>
			  <th id = "th01"><b>Proyecto</b></th>
			  <th id = "th01"><b>Normas</b></th>
			  <th id = "th02"><b>Fecha Desde</b></th>
			  <th id = "th02"><b>Fecha Hasta</b></th>
			  <th id = "th02"><b>Dias</b></th>
			  <th id = "th02"><b>Horas</b></th>
			  <th id = "th02"><b>Obs</b></th>
			  <th id = "th01"><b>Profesional</b></th>
			  <th id = "th01"><b>Observador</b></th>
			  <th id = "th01" style="width:100px;"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Planificacion CURSOR FOR 
			SELECT	C.RAZON_SOCIAL_CLIENTE, --CLIENTE
					P.NORMA_REF, --PROYECTO
					CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria'
						 WHEN A.ID_SERVICIO = '2' THEN 'Auditoria'
						 WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion'
					END, --SERVICIO
					A.NORMA, --NORMA
					CONVERT(VARCHAR,A.FECHA,103), --FECHA desde
					CONVERT(VARCHAR,A.FECHA_HASTA,103), --FECHA hasta
					CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor' 
					ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END, --PROFESIONAL
					A.OBSERVADOR, --OBSERVADOR
					CONVERT(VARCHAR,A.ID_AGENDA), --ID AGENDA
					A.ID_SERVICIO, --ID SERVICIO
					A.DIAS,
					'<div class="tooltip">' +
					CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN
						''--'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:gray;" title="Obs. Calificacion">'
					ELSE
						'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:red;" title="Obs. Calificacion">'
					END + '
						<span class="tooltiptext">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align:left">'+CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_CALIF END+
						'</font></span>
					</i>
					</div>'	
					+ '<br>' + 
					'<div class="tooltip">' +
					CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN 
						''--'<i class="fas fa-clipboard-check w3-large" style="cursor:pointer;color:gray;" title="Obs. Logistica">' 
					ELSE 
						'<i class="fas fa-clipboard-check w3-large" style="cursor:pointer;color:blue;" title="Obs. Logistica">' 
					END + '
						<span class="tooltiptext">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_LOGISTICA END +
						'</font></span>
					</i>
					</div>'
					+ '<br>' + 
					'<div class="tooltip">' +
					CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN
						''--'<i class="fas fa-address-book w3-large" style="cursor:pointer;color:gray;" title="Obs. Hoja Ruta">'
					ELSE
						'<i class="fas fa-address-book w3-large" style="cursor:pointer;color:green;" title="Obs. Hoja Ruta">'
					END + '
						<span class="tooltiptext">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE DOC.OBSERVACIONES END +
						'</font></span>
					</i>
					</div>',
					DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) AS HORAS
			FROM	LK_AGENDA A
					INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
					INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
					--LEFT JOIN LK_EMPLEADOS EMP ON EMP.ID_EMPLEADO = A.ID_CONSULTOR
					INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
					LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
			WHERE	A.ID_CLIENTE = @VIDCLIENTE
			AND		A.ID_PROYECTO = @VPROYECTO
			AND		A.ID_SERVICIO = @VSERVICIO
			AND		A.PROYECTO_SERV_ID = @VID
			ORDER BY A.FECHA
 
		OPEN Planificacion  
		FETCH NEXT FROM Planificacion INTO @VARCLIENTE, @VARPROYECTO, @VARSERVICIO,@VARNORMA, @VARFECHAD, @VARFECHAH, @VARPROFESIONAL, @VAROBSERVADOR, @VID_AGENDA, @VID_SERVICIO, @VDIAS, @VOBS, @VARHORAS
 
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
 
			SET @VSTATUS = [dbo].[FN_GET_STATUS_AGENDA] (@VID_AGENDA)
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+CASE  WHEN @VSTATUS = 'R' THEN	
											'<i class="fas fa-circle w3-large" style="cursor:pointer;color:red;" title="Indicador"></i>'
										   WHEN @VSTATUS = 'N' THEN
											'<i class="fas fa-circle w3-large" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
										   WHEN @VSTATUS = 'A' THEN
											'<i class="fas fa-circle w3-large" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
										   WHEN @VSTATUS = 'V' THEN
											'<i class="fas fa-circle w3-large" style="cursor:pointer;color:green;" title="Indicador"></i>'
										   WHEN @VSTATUS = 'C' THEN	
											'<i class="fas fa-circle w3-large" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
										END +'</td>'+	
				  '<td id = "td01">'+@VARCLIENTE+'</td>'+
				  '<td id = "td01">'+@VARPROYECTO+'</td>'+
				  '<td id = "td01">'+@VDESCNORMAS+'</td>'+
				  '<td id = "td02">'+@VARFECHAD+'</td>'+
				  '<td id = "td02">'+@VARFECHAH+'</td>'+
				  '<td id = "td02">'+@VDIAS+'</td>'+
				  '<td id = "td02">'+@VARHORAS+'</td>'+
				  '<td id = "td02">'+ISNULL(@VOBS,'')+'</td>'+
				  '<td id = "td01">'+@VARPROFESIONAL+'</td>'+
				  '<td id = "td01">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+ISNULL(@VAROBSERVADOR,'')+'</font>'+'</td>' +
				  '<td>' +
				  '<i class="fas fa-calendar-alt w3-large" style="cursor:pointer;" title="Ver Visita" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20''); return false;"></i>'+ '&nbsp;' + 
				  CASE WHEN (@VACTION <> 'HISTORICO') THEN
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Visita?'');
					if (confirmar){almacenarSeleccion(''PROYECTO_SERV_ID'','''+@VID+ ''');almacenarSeleccion(''ID_DELETE'','''+@VID_AGENDA+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>'+ '&nbsp;' 
				  ELSE '' END+ 
				  /*
				  '<div class="tooltip">
					<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;" title="Obs. Calificacion">
						<span class="tooltiptext">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+ISNULL(@VOBS_CALIF,'Sin Observaciones')+
						'</font></span>
					</i>
					</div>'	+ '&nbsp;' + 
				  '<div class="tooltip">
					<i class="fas fa-shipping-fast w3-large" style="cursor:pointer;" title="Obs. Logistica">
						<span class="tooltiptext">'+'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+ISNULL(@VOBS_LOGIS,'Sin Observaciones')+
						'</font></span>
					</i>
					</div>'
				 
				   <i class="fas fa-address-book w3-large" style="cursor:pointer;" title="Hoja de Ruta" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''A98FD1D3-4226-45C2-961D-A47DFA5E9E8F'');"></i>
				   <i class="fas fa-money-check-alt w3-large" style="cursor:pointer;" title="Viaticos" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''D5C00A34-A249-424B-9152-033D6F2652FB'');"></i>
				   <i class="fas fa-hand-holding-usd w3-large" style="cursor:pointer;" title="Honorarios" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>' + '&nbsp;' + 
				CASE WHEN @VID_SERVICIO = '1' THEN
				  '<i class="fas fa-paperclip w3-large" style="cursor:pointer;" title="Minutas" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>
				   <i class="fas fa-paperclip w3-large" style="cursor:pointer;" title="Plan Estrategico" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>'	
					WHEN @VID_SERVICIO = '2' THEN 
				  '<i class="fas fa-paperclip w3-large" style="cursor:pointer;" title="Plan de Auditoria" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>
				   <i class="fas fa-list-alt w3-large" style="cursor:pointer;" title="Informe de Auditoria" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>
				  '	
					WHEN @VID_SERVICIO = '3' THEN
				  '<i class="fas fa-tasks w3-large" style="cursor:pointer;" title="CheckList" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''3D54E704-280F-4A6C-9876-D28E83C3F187'');"></i>
				   <i class="fas fa-user-alt w3-large" style="cursor:pointer;" title="Carga Asistentes" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>
				   <i class="fas fa-certificate w3-large" style="cursor:pointer;" title="Certificados" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');"></i>
				  '	
				END*/ + '
			   </td>'+
				'</tr>'
 
			FETCH NEXT FROM Planificacion INTO @VARCLIENTE, @VARPROYECTO, @VARSERVICIO,@VARNORMA, @VARFECHAD, @VARFECHAH, @VARPROFESIONAL, @VAROBSERVADOR, @VID_AGENDA, @VID_SERVICIO, @VDIAS, @VOBS, @VARHORAS
		END 
 
		CLOSE Planificacion  
		DEALLOCATE Planificacion
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'DS') BEGIN
		
		IF (@VSERVICIO = '1') BEGIN
			SET @VTABLA = '
			<table class="w3-table-all">
				<thead>
				<tr class="w3-grey w3-hover-light-grey">
				  <th id = "th02"><b>Frecuencia Envio Plan Estrategico</b></th>
				  <th id = "th02"><b>Documentacion Empresa</b></th>
				</tr>
				</thead>'
		END
 
		IF (@VSERVICIO = '2') BEGIN
			SET @VTABLA = '
			<table class="w3-table-all">
				<thead>
				<tr class="w3-grey w3-hover-light-grey">
				  <th id = "th02"><b>Manual/Documentacion</b></th>
				  <th id = "th02"><b>Requisitos Ingreso</b></th>
				  <th id = "th02"><b>CV y Certificados</b></th>
				  <th id = "th02"><b>Logistica</b></th>
				</tr>
				</thead>'
		END
 
		IF (@VSERVICIO = '3') BEGIN
			SET @VTABLA = '
			<table class="w3-table-all">
				<thead>
				<tr class="w3-grey w3-hover-light-grey">
				  <th id = "th02"><b>Nombre Curso</b></th>
				  <th id = "th02"><b>Materiales</b></th>
				  <th id = "th02"><b>Estado de Envio</b></th>
				  <th id = "th02"><b>Recibido</b></th>
				</tr>
				</thead>'
		END
 
		--DECLARE Datos CURSOR FOR 
			SELECT	@VFRECUENCIA = ISNULL(FRECUENCIA_ENVIO,''), @VDOC_EMPRESA = ISNULL(DOC_EMPRESA,''), 
					@VMANUAL_DOC = ISNULL(MANUALES,''), @VREQ_INGRESO = ISNULL(REQUISITO_INGRESO,''), @VCV_CERTIF = ISNULL(CV_CERTIFICADOS,''), @VLOGISTICA = ISNULL(LOGISTICA,''),
					@VCURSO = ISNULL(NOMBRE_CURSO,''), @VMATERIAL = ISNULL(MATERIALES,''), @VESTADO_ENVIO = ISNULL(ESTADO_ENVIO,''), @VRECIBIDO = ISNULL(RECIBIDO,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID
 
		/*OPEN Datos  
		FETCH NEXT FROM Datos INTO @VFRECUENCIA, @VDOC_EMPRESA,	@VMANUAL_DOC, @VREQ_INGRESO, @VCV_CERTIF, @VLOGISTICA, @VCURSO,	@VMATERIAL,	@VESTADO_ENVIO,	@VRECIBIDO
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  */
			
			IF (@VSERVICIO = '1') BEGIN
 
				SET @VTABLA =  isnull(@VTABLA,'') + 
	
					'<tr class="w3-hover-light-grey">' +
					  '<td id = "td02">'+@VFRECUENCIA+'</td>'+
					  '<td id = "td02">'+@VDOC_EMPRESA+'</td>'+
					'</tr>'
			END
 
			IF (@VSERVICIO = '2') BEGIN
 
				SET @VTABLA =  isnull(@VTABLA,'') + 
	
					'<tr class="w3-hover-light-grey">' +
					  '<td id = "td02">'+@VMANUAL_DOC+'</td>'+
					  '<td id = "td02">'+@VREQ_INGRESO+'</td>'+
					  '<td id = "td02">'+@VCV_CERTIF+'</td>'+
					  '<td id = "td02">'+@VLOGISTICA+'</td>'+
					'</tr>'
			END
 
			IF (@VSERVICIO = '3') BEGIN
 
				SET @VTABLA =  isnull(@VTABLA,'') + 
	
					'<tr class="w3-hover-light-grey">' +
					  '<td id = "td02">'+@VCURSO+'</td>'+
					  '<td id = "td02">'+@VMATERIAL+'</td>'+
					  '<td id = "td02">'+@VESTADO_ENVIO+'</td>'+
					  '<td id = "td02">'+@VRECIBIDO+'</td>'+
					'</tr>'
			END
 
 
			--FETCH NEXT FROM Datos INTO @VFRECUENCIA, @VDOC_EMPRESA,	@VMANUAL_DOC, @VREQ_INGRESO, @VCV_CERTIF, @VLOGISTICA, @VCURSO,	@VMATERIAL,	@VESTADO_ENVIO,	@VRECIBIDO
		--END 
 
		--CLOSE Datos  
		--DEALLOCATE Datos
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
 
	IF (@VTIPO = 'MC') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b>Fecha</b></th>
			  <th id = "th02"><b>Nombre</b></th>
			  <th id = "th01"><b>Observacion</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Minutas CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit w3-large" style="cursor:pointer;color:blue;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''5E7191C8-7172-4B3C-9AEF-A3A0F2CD109B'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Minuta?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Minuta" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END 
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VPROYECTO
			AND		D.ID_TIPO_SERVICIO = @VSERVICIO
			AND		D.PROYECTO_SERV_ID = @VID
			AND		D.TIPO = 'MC'
 
 
		OPEN Minutas  
		FETCH NEXT FROM Minutas INTO @VFECHA_MINUTA, @VNOMBRE, @VOBSERV_MINUTA,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+@VFECHA_MINUTA+'</td>'+
				  '<td id = "td02">'+@VNOMBRE+'</td>'+
				  '<td id = "td01">'+@VOBSERV_MINUTA+'</td>'+
				  '<td id = "td01">'+@VACCION+'</td>' +
				'</tr>'
 
			FETCH NEXT FROM Minutas INTO @VFECHA_MINUTA, @VNOMBRE, @VOBSERV_MINUTA,@VACCION
		END 
 
		CLOSE Minutas  
		DEALLOCATE Minutas
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'PE') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b>Fecha</b></th>
			  <th id = "th02"><b>Nombre</b></th>
			  <th id = "th01"><b>Observacion</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Planes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit w3-large" style="cursor:pointer;color:blue;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''6E5AE7D4-E406-454C-B72A-12B2FE47F023'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Plan?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Plan" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VPROYECTO
			AND		D.ID_TIPO_SERVICIO = @VSERVICIO
			AND		D.PROYECTO_SERV_ID = @VID
			AND		D.TIPO = 'PE'
 
 
		OPEN Planes  
		FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION--, @VFRECUENCIA
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+@VFECHA_PLAN+'</td>'+
				  '<td id = "td02">'+@VNOMBRE+'</td>'+
				  '<td id = "td01">'+@VOBSERV_PLAN+'</td>'+
				  '<td id = "td01">'+@VACCION+'</td>' +
				'</tr>'
 
			FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION--, @VFRECUENCIA
		END 
 
		CLOSE Planes  
		DEALLOCATE Planes
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'PA') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b>Fecha</b></th>
			  <th id = "th02"><b>Nombre</b></th>
			  <th id = "th01"><b>Observacion</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Planes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit w3-large" style="cursor:pointer;color:blue;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''41DC0631-D362-40DC-9BD1-6A76C6801503'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Plan?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Plan" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VPROYECTO
			AND		D.ID_TIPO_SERVICIO = @VSERVICIO
			AND		D.PROYECTO_SERV_ID = @VID
			AND		D.TIPO = 'PA'
 
 
		OPEN Planes  
		FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+@VFECHA_PLAN+'</td>'+
				  '<td id = "td02">'+@VNOMBRE+'</td>'+
				  '<td id = "td01">'+@VOBSERV_PLAN+'</td>'+
				  '<td id = "td01">'+@VACCION+'</td>' +
				'</tr>'
 
			FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Planes  
		DEALLOCATE Planes
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'IA') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b>Fecha</b></th>
			  <th id = "th02"><b>Nombre</b></th>
			  <th id = "th01"><b>Observacion</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Informes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit w3-large" style="cursor:pointer;color:blue;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''E54664C3-342F-45DC-8CCA-F8DC8DF96E67'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VPROYECTO
			AND		D.ID_TIPO_SERVICIO = @VSERVICIO
			AND		D.PROYECTO_SERV_ID = @VID
			AND		D.TIPO = 'IA'
 
 
		OPEN Informes  
		FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+@VFECHA_PLAN+'</td>'+
				  '<td id = "td02">'+@VNOMBRE+'</td>'+
				  '<td id = "td01">'+@VOBSERV_PLAN+'</td>'+
				  '<td id = "td01">'+@VACCION+'</td>' +
				'</tr>'
 
			FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Informes  
		DEALLOCATE Informes
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'IC') BEGIN
 
		SET @VTABLA = '
		<table class="w3-table-all">
			<thead>
			<tr class="w3-grey w3-hover-light-grey">
			  <th id = "th02"><b>Fecha</b></th>
			  <th id = "th02"><b>Nombre</b></th>
			  <th id = "th01"><b>Observacion</b></th>
			  <th id = "th01"><b>[+]</b></th>
			</tr>
			</thead>'
 
		DECLARE Informes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit w3-large" style="cursor:pointer;color:blue;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''C8DDD3B5-F138-487B-A452-2CA1A10DEBF7'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VPROYECTO
			AND		D.ID_TIPO_SERVICIO = @VSERVICIO
			AND		D.PROYECTO_SERV_ID = @VID
			AND		D.TIPO = 'IC'
 
 
		OPEN Informes  
		FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			SET @VTABLA =  isnull(@VTABLA,'') + 
	
				'<tr class="w3-hover-light-grey">' +
				  '<td id = "td02">'+@VFECHA_PLAN+'</td>'+
				  '<td id = "td02">'+@VNOMBRE+'</td>'+
				  '<td id = "td01">'+@VOBSERV_PLAN+'</td>'+
				  '<td id = "td01">'+@VACCION+'</td>' +
				'</tr>'
 
			FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Informes  
		DEALLOCATE Informes
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTIPO = 'A') 
		BEGIN
			SET @VVISTAS_SEL='w3-red'
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL =''
		END
	ELSE IF (@VTIPO = 'MC')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL='w3-red'
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL =''
		END 
	ELSE IF (@VTIPO = 'PE')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL='w3-red'
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL =''
		END 
	ELSE IF (@VTIPO = 'PA')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL='w3-red'
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL =''
		END 
	ELSE IF (@VTIPO = 'IA')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL='w3-red'
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL =''
		END 
	ELSE IF (@VTIPO = 'IC')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL='w3-red'
			SET @VDATOS_SEL =''
		END 
	ELSE IF (@VTIPO = 'DS')
		BEGIN
			SET @VVISTAS_SEL = ''
			SET @VMINUTA_SEL=''
			SET @VPLAN_SEL=''
			SET @VPLAN_AUD_SEL=''
			SET @VINF_AUD_SEL=''
			SET @VINF_CAP_SEL=''
			SET @VDATOS_SEL ='w3-red'
		END 
 
SET @OPLAN = '
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
<div class="w3-bar w3-grey">
	<button class="w3-bar-item w3-button tablink '+@VVISTAS_SEL+'" onclick="saveSelection(''TIPO_SELEC'','''+'A'+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Visitas</button>
	<button class="w3-bar-item w3-button tablink '+@VDATOS_SEL+'" onclick="saveSelection(''TIPO_SELEC'','''+'DS'+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Datos Seguimiento</button>'
	+CASE WHEN @VSERVICIO = '1' THEN +
		'<button class="w3-bar-item w3-button tablink '+@VMINUTA_SEL+'" onclick="saveSelection(''TIPO_SELEC'',''MC'');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Minuta de Cierre</button>
		<button class="w3-bar-item w3-button tablink '+@VPLAN_SEL+'" onclick="saveSelection(''TIPO_SELEC'',''PE'');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Plan Estrategico</button>'
	WHEN @VSERVICIO = '2' THEN +
		'<button class="w3-bar-item w3-button tablink '+@VPLAN_AUD_SEL+'" onclick="saveSelection(''TIPO_SELEC'','''+'PA'+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Plan Auditoría</button>
		<button class="w3-bar-item w3-button tablink '+@VINF_AUD_SEL+'" onclick="saveSelection(''TIPO_SELEC'','''+'IA'+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Informe Auditoría</button>'
	WHEN @VSERVICIO = '3' THEN +
		'<button class="w3-bar-item w3-button tablink '+@VINF_CAP_SEL+'" onclick="saveSelection(''TIPO_SELEC'','''+'IC'+''');goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;">Informe Capacitación</button>'
	END +
	CASE WHEN (@VTIPO = 'A') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-calendar-plus"></i>&nbsp;Agregar Visita</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'DS') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''02CCDB99-A437-4DFB-8A0A-E455962301E3'');return false;"><i class="fas fa-edit"></i>&nbsp;Editar Datos</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'MC') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');return false;"><i class="fas fa-paperclip"></i>&nbsp;Agregar Minuta</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'PE') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''B0569958-40AB-49AD-8036-555088709D77'');return false;"><i class="fas fa-list-alt"></i>&nbsp;Agregar Plan</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'PA') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''DFE8677A-7CCF-4D8E-A91D-4EB3F526393C'');return false;"><i class="fas fa-list-alt"></i>&nbsp;Agregar Plan</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'IA') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''3F6EFE7E-110B-4A5E-953B-B0E5D49C0F16'');return false;"><i class="fas fa-paperclip"></i>&nbsp;Agregar Informe</button>' 
		ELSE '' END +
		CASE WHEN (@VTIPO = 'IC') THEN
		'<button class="w3-bar-item w3-button w3-right w3-red" onclick="goto('''+@FORM_ID+''',''931875EA-23ED-4EEA-BF4F-8A53C7B1FB90'');return false;"><i class="fas fa-list-alt"></i>&nbsp;Agregar Informe</button>' 
		ELSE '' END +
	'</div>'+
		  '<div class="w3-container w3-border" style="padding:0px">' + ISNULL(@VTABLA,'') + '</div>'
 
	UPDATE	XAGENDA
	SET		AGREGA_SERV = NULL,
			GRABA_SERV = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
