 
CREATE PROCEDURE [dbo].[HOME_INICIA_AGENDA]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OALERTA	AS VARCHAR(400) OUTPUT
 )
AS
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(100),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VCLIENTE	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VHORAS		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VID_SERVICIO INT,
		@VESTADO	VARCHAR(100),
		@VERROR		VARCHAR(50),
		@VARNORMA	VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VTIPO			VARCHAR(50),
		@VCANT_HR		INT,
		@VCANT_HONOR	INT,
		@VCANT_VIATICO	INT,
		@VCANT_CL		INT,
		@VCANT_MV		INT,
		@VCANT_IA		INT,
		@VCANT_IC		INT,
		@VSTATUS		VARCHAR(50),
		@VID_DELETE		VARCHAR(50),
		@VPROYECTO_SERV	VARCHAR(50),
		@VNOMBRE		VARCHAR(300),
		@VSTRUCTURE		VARCHAR(100),
		@VSTRUCTURE_HR	VARCHAR(100),
		@VTOTAL_EJEC	INT,
		@VTOTAL_SERV	INT,
		@VSOLAPA	VARCHAR(50),
		@VACTION	VARCHAR(100)
 
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
			@VTIPO = ISNULL(TIPO_SELEC,''),
			@VID_DELETE = ISNULL(ID_DELETE,''),
			@VSOLAPA = ISNULL(SOLAPA,''),
			@VACTION = ISNULL(ACTION,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VTIPO = 'V') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_VIATICOS
			WHERE	ID_PROYECTO_VIATICOS = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
 
	IF (@VTIPO = 'H') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_HONORARIOS
			WHERE	ID_PROYECTO_HONORARIOS = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
 
	IF (@VTIPO = 'CL') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
 
	IF (@VTIPO = 'MV') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
	/*
	IF (@VTIPO = 'IA') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
 
	IF (@VTIPO = 'IC') BEGIN
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE	XAGENDA
			SET		ID_DELETE = NULL
			WHERE	PAR_KEY = @IPKEYJOB
		END	
	END
	*/
 
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO  = '('+P.CODIGO+') - '+P.NORMA_REF,
			@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VHORAS = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(A.NORMA,''),
			@VCONSULTORES = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
			@VID_SERVICIO = ID_SERVICIO,
			@VPROYECTO_SERV = PROYECTO_SERV_ID,
			@VID = A.ID_PROYECTO
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	SET @VSTATUS = [dbo].[FN_GET_STATUS_AGENDA] (@VAGENDA_ID)
	
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
 
	SELECT	@VCANT_HR = COUNT(*)
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		ID_DOCUMENTACION = CASE WHEN @VID_SERVICIO = '1' THEN '7'
									WHEN @VID_SERVICIO = '2' THEN '5'
									WHEN @VID_SERVICIO = '3' THEN '6'
								END
 
	SELECT	@VCANT_VIATICO = COUNT(*)
	FROM	LK_PROYECTO_VIATICOS
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VCANT_HONOR = COUNT(*)
	FROM	LK_PROYECTO_HONORARIOS
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VCANT_CL = COUNT(*)
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		ID_DOCUMENTACION = '4'
 
	SELECT	@VCANT_MV = COUNT(*)
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		TIPO = 'MV'
 
	/*
	SELECT	@VCANT_IA = COUNT(*)
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		TIPO = 'IA'
 
	SELECT	@VCANT_IC = COUNT(*)
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		TIPO = 'IC'
	*/
 
	
	SET @VSTRUCTURE = CASE WHEN @VSOLAPA = 'PLAN' THEN '522967A7-DDC9-465B-969B-85997AE1B085' ELSE '74BBD80D-05CB-41DB-A981-5B6E3EE63A74' END
	
	SET @VSTRUCTURE_HR = CASE WHEN @VID_SERVICIO = '1' THEN '522967A7-DDC9-465B-969B-85997AE1B085' ELSE 'A77CE927-9D2D-4C15-91CE-34388075B9F7' END
 
--	74BBD80D-05CB-41DB-A981-5B6E3EE63A74
 
	SET @OHEADER = 
	'<div>
	<p>
		<button onclick="almacenarSeleccion(''TIPO_SELEC'','''+''+''');goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#BDC3C7"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#BDC3C7;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Ver Visita</b></font>
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
			<th><b></b></th>
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
			'<td>'+CASE WHEN @VSTATUS = 'R' THEN	
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:red;" title="Indicador"></i>'
						WHEN @VSTATUS = 'N' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
						WHEN @VSTATUS = 'A' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
						WHEN @VSTATUS = 'V' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:green;" title="Indicador"></i>'
						WHEN @VSTATUS = 'C' THEN	
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
					END	+
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VPROYECTO+'</td>' +
			  '<td>'+@VSERVICIO+'</td>' +
			  '<td>'+ISNULL(@VNOMBRE,'')+'</td>' +
			  '<td>'+ISNULL(@VDESCNORMAS,'')+'</td>' +
			  '<td>'+@VDIAS+'</td>' +
			  '<td>'+@VHORAS+'</td>' +
			  '<td>'+@VFECHAD+'</td>' +
			  '<td>'+@VFECHAH+'</td>' +
			  '<td>'+@VESTADO+'</td>' +
			  '<td>'+@VCONSULTORES+'</td> 
			</tr>
	</table>
	</div>
	
	<div class="w3-panel w3-topbar"></div>'+
 
	CASE WHEN @VSERVICIO = 'Consultoria' THEN
 
		'<div class="w3-row-padding w3-margin-bottom">' +
		case when @vaction = 'HISTORICO' then
			'<div class="w3-col" style="width:20%;cursor:pointer;">'
		else
			'<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'M'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5'');">'
		end +
		  '<div class="w3-container w3-blue w3-padding-16">
			<div class="w3-left"><i class="fas fa-edit w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+'&nbsp;'+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Modificar</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'HR'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-padding-16" style="background-color:#F4D03F">
			<div class="w3-left"><i class="fas fa-address-book w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_HR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Hoja de Ruta</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'V'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-padding-16" style="background-color:#52BE80">
			<div class="w3-left"><i class="fas fa-money-check-alt w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_VIATICO)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Viaticos</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'H'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-teal w3-padding-16">
			<div class="w3-left"><i class="fas fa-hand-holding-usd w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_HONOR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Honorarios</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'MV'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-orange w3-text-white w3-padding-16">
			<div class="w3-left"><i class="fas fa-paperclip w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_MV)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Minuta de Visita</h4>
		  </div>
		</div>
		
	  </div>'
	
	WHEN @VSERVICIO = 'Auditoria' THEN
	
	'<div class="w3-row-padding w3-margin-bottom">' +
		case when @vaction = 'HISTORICO' then
			'<div class="w3-col" style="width:20%;cursor:pointer;">'
		else
			'<div class="w3-col" style="width:25%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'M'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5'');">'
		end +
		 '<div class="w3-container w3-blue w3-padding-16">
			<div class="w3-left"><i class="fas fa-edit w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+'&nbsp;'+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Modificar</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:25%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'HR'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-padding-16" style="background-color:#F4D03F">
			<div class="w3-left"><i class="fas fa-address-book w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_HR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Hoja de Ruta</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:25%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'V'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-padding-16" style="background-color:#52BE80">
			<div class="w3-left"><i class="fas fa-money-check-alt w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_VIATICO)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Viaticos</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:25%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'H'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-teal w3-padding-16">
			<div class="w3-left"><i class="fas fa-hand-holding-usd w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_HONOR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Honorarios</h4>
		  </div>
		</div>'
		/*<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'IA'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-orange w3-text-white w3-padding-16">
			<div class="w3-left"><i class="fas fa-list-alt w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_IA)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Informe Auditoria</h4>
		  </div>
		</div>*/
 
	  +'</div>' 
	
	WHEN @VSERVICIO = 'Capacitacion' THEN
	
	'<div class="w3-row-padding w3-margin-bottom">' +
		case when @vaction = 'HISTORICO' then
			'<div class="w3-col" style="width:20%;cursor:pointer;">'
		else 
			'<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'M'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5'');">'
		end +
		  '<div class="w3-container w3-blue w3-padding-16">
			<div class="w3-left"><i class="fas fa-edit w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+'&nbsp;'+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Modificar</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'HR'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-padding-16" style="background-color:#F4D03F">
			<div class="w3-left"><i class="fas fa-address-book w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_HR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Hoja de Ruta</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'V'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-padding-16" style="background-color:#52BE80">
			<div class="w3-left"><i class="fas fa-money-check-alt w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_VIATICO)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Viaticos</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'H'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-teal w3-padding-16">
			<div class="w3-left"><i class="fas fa-hand-holding-usd w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_HONOR)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Honorarios</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:20%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'CL'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-text-white w3-padding-16" style="background-color:#AF7AC5">
			<div class="w3-left"><i class="fas fa-tasks w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+CONVERT(VARCHAR,@VCANT_CL)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">CheckList</h4>
		  </div>
		</div>'+
		/*<div class="w3-col" style="width:12.5%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'IC'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C'');">
		  <div class="w3-container w3-orange w3-text-white w3-padding-16">
			<div class="w3-left"><i class="fas fa-paperclip w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+CONVERT(VARCHAR,@VCANT_IC)+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Informe</h4>
		  </div>
		</div>*/
		/*'<div class="w3-col" style="width:14.28%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'CA'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-red w3-padding-16">
			<div class="w3-left"><i class="fas fa-user-alt w3-xxxlarge"></i></div>
			<div class="w3-right">
			  <h3>'+'&nbsp;'+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4>Asistentes</h4>
		  </div>
		</div>
		<div class="w3-col" style="width:14.28%;cursor:pointer;" onclick="almacenarSeleccion(''TIPO_SELEC'','''+'CC'+''');almacenarSeleccion(''AGENDA_ID'','''+@VAGENDA_ID+''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20'');">
		  <div class="w3-container w3-lime w3-padding-16">
			<div class="w3-left"><i class="fas fa-certificate w3-xxxlarge" style="color:white"></i></div>
			<div class="w3-right">
			  <h3 style="color:white">'+'&nbsp;'+'</h3>
			</div>
			<div class="w3-clear"></div>
			<h4 style="color:white">Certificados</h4>
		  </div>*/
		'</div>
	  </div>' 
 
	END +
 
	'<div class="w3-panel w3-topbar"></div>
 
	'
 
	IF (ISNULL(@VTIPO,'') = '') BEGIN 
		SET @VTIPO = 'HR'
	END
 
	SET @OFOOTER = 
	CASE WHEN @VTIPO = 'HR' THEN
		'<div>
		<p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#F4D03F">'+'<b>Hoja de Ruta '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'</p>
		<p>
			<button onclick="saveValues(''BUFFER'');goto('''+@FORM_ID+''',''A98FD1D3-4226-45C2-961D-A47DFA5E9E8F''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#F4D03F"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
			<button onclick="almacenarSeleccion(''TIPO_SELEC'','''+''+''');goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#F4D03F"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
		</p>
		</div>
 
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'V' THEN
 
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#52BE80">'+'<b>Viaticos '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-money-check-alt w3-right w3-xxlarge" style="color:#52BE80;cursor:pointer;" title="Agregar Viatico" onclick="almacenarSeleccion(''TIPO_CONSULTOR_PROV'','''+''+''');
																																	   almacenarSeleccion(''CONSULTOR_PROV'','''+''+''');
																																	   almacenarSeleccion(''TIPO_PROV'','''+''+''');
																																	   almacenarSeleccion(''PROVEEDOR_ID'','''+''+''');
																																	   almacenarSeleccion(''FORMA_PAGO_PROV'','''+''+''');
																																	   almacenarSeleccion(''ESTADO_PAGO_PROV'','''+''+''');	
																																	   goto('''+@FORM_ID+''',''9699BAC1-EB3A-41AF-AB6C-8B97A339EFA2'');"></i>'
		+'&nbsp;&nbsp;&nbsp;&nbsp;'
		+'<i class="fas fa-clipboard-list w3-center w3-xxlarge" style="color:#52BE80;cursor:pointer;" title="Parte Logistico" onclick="almacenarSeleccion(''CONSULTOR_PROV'','''+''+''');
																																		almacenarSeleccion(''CORRESPONDE_MAT_PL'','''+''+''');
																																		almacenarSeleccion(''POWER_POINT_PL'','''+''+''');
																																		goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');"></i>'
		+'&nbsp;&nbsp;&nbsp;&nbsp;'
		+'<i class="fas fa-file-invoice-dollar w3-center w3-xxlarge" style="color:#52BE80;cursor:pointer;" title="Rendicion Viaticos" onclick="goto('''+@FORM_ID+''',''816D74E9-0C1C-478A-A699-CF1903A61B23'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'CL' THEN
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#AF7AC5">'+'<b>CheckList '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-tasks w3-right w3-xxlarge" style="color:#AF7AC5;cursor:pointer;" title="Agregar CheckList" onclick="goto('''+@FORM_ID+''',''3F11610E-DB37-427B-997D-1507E8982A92'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'H' THEN
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#117A65">'+'<b>Honorarios '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-hand-holding-usd w3-right w3-teal w3-xxlarge" style="cursor:pointer;" title="Agregar Honorario" onclick="goto('''+@FORM_ID+''',''0B438E7D-728C-4D27-B9C5-534984C18EF9'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'MV' THEN
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#E67E22">'+'<b>Minuta de Visita '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-paperclip w3-right w3-orange w3-text-white w3-xxlarge" style="cursor:pointer;" title="Agregar Minuta" onclick="goto('''+@FORM_ID+''',''95871190-0255-4CFC-9598-8FD01332BAC1'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'IA' THEN
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#E67E22">'+'<b>Informe de '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-list-alt w3-right w3-orange w3-text-white w3-xxlarge" style="cursor:pointer;" title="Agregar Informe" onclick="goto('''+@FORM_ID+''',''3F6EFE7E-110B-4A5E-953B-B0E5D49C0F16'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
		WHEN @VTIPO = 'IC' THEN
		'<div class="w3-left-align"><p></br>
		<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: left">'
		+'<font style="font-size:28;color:#E67E22">'+'<b>Informe de '+ @VSERVICIO	 +'</b></font> '
		+'</font>'
		+'<i class="fas fa-list-alt w3-right w3-orange w3-text-white w3-xxlarge" style="cursor:pointer;" title="Agregar Informe" onclick="goto('''+@FORM_ID+''',''931875EA-23ED-4EEA-BF4F-8A53C7B1FB90'');"></i>'
		+'</p></div>
		
		<div class="w3-panel w3-topbar">
		</div>'
 
	END
 
	SELECT	@VTOTAL_EJEC = CONVERT(INT,[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, ID_PROYECTO_SERVICIO)),--TOTAL_HORAS_EJECUTADAS,
			@VTOTAL_SERV = TOTAL_HORAS_PROYECTADAS
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	IF @VTOTAL_EJEC > @VTOTAL_SERV BEGIN
		SET @OALERTA = '<script type="text/javascript">alert("Ha Superado el Total de Horas Proyectadas del Servicio");</script>'
	END
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			FECHA_SELEC = NULL,
			BUFFER = NULL,
			AGENDA_CONSULTOR = NULL,
			AGENDA_CONSULTORES = NULL,
			ACUMULA = NULL,
			LIDER = NULL,
			PROYECTO_ID = CASE WHEN ISNULL(PROYECTO_ID,'') = '' THEN @VID ELSE PROYECTO_ID END,
			PROYECTO_SERV_ID = CASE WHEN ISNULL(PROYECTO_SERV_ID,'') = '' THEN @VPROYECTO_SERV ELSE PROYECTO_SERV_ID END,
			TIPO_SELEC = CASE WHEN ISNULL(TIPO_SELEC,'') = '' THEN 'HR' ELSE @VTIPO END
	WHERE	PAR_KEY = @IPKEYJOB
		
END
 
