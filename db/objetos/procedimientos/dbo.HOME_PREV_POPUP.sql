 
CREATE PROCEDURE [dbo].[HOME_PREV_POPUP] (
@PROCESSID		AS VARCHAR(100), 
@FORM_ID		AS VARCHAR(100),
@USUARIO_ID		AS VARCHAR(30),  
@PS_TITULO		AS VARCHAR(MAX) OUTPUT,
@PS_TABS		AS VARCHAR(MAX) OUTPUT,
@PS_TABLE_1		AS VARCHAR(MAX)  OUTPUT)
AS
 
-- ==================================================
-- SETEO PROCEDIMIENTO
-- ==================================================
 
	SET NOCOUNT ON;
 
-- ==================================================
-- VARIABLES PROCEDIMIENTO
-- ==================================================
DECLARE @VCUIT			VARCHAR(50),
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
		@VDIRECCION		VARCHAR(MAX),
		@VOBSERV_HR		VARCHAR(MAX)
 
DECLARE	@VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VID_AGENDA_SELEC	VARCHAR(100),
		@VCANT_PROY_ABI		INT,
		@VCANT_PROY_CER		INT,
		@VCANT_SERVICIOS	INT,
		@VNOMBRE_PROY		VARCHAR(MAX),
		@VNOMBRE_SERV_SELEC	VARCHAR(MAX),
		@VLUGAR_SERV_SELEC	VARCHAR(MAX),
		@VTIPO_SERV_SELEC	VARCHAR(MAX),
		@VFECHA_INI_SELEC	DATETIME,
		@VFECHA_FIN_SELEC	DATETIME,
		@VHORAS_SELEC		VARCHAR(MAX),
		@VMONTO_SELEC		VARCHAR(MAX),
		@VCIERRE_SELEC		VARCHAR(MAX),
		@VNOMBRE_SERV_TMT	VARCHAR(MAX),
		@VLUGAR_SERV_TMT	VARCHAR(MAX),
		@VTIPO_SERV_TMT		VARCHAR(MAX),
		@VFECHA_INI_TMT		DATETIME,
		@VFECHA_FIN_TMT		DATETIME,
		@VHORAS_TMT			VARCHAR(MAX),
		@VMONTO_TMT			VARCHAR(MAX),
		@VCIERRE_TMT		VARCHAR(MAX),
		@VTAB				VARCHAR(100),
		@VTAB_SERV			VARCHAR(100),
		@VTAB_AGENDA		VARCHAR(100),
		@VTABLA				VARCHAR(MAX),
		@VTABLA_DET			VARCHAR(MAX),
		@VDESC_ERROR		VARCHAR(MAX),
		@VCLAVE_DELETE		VARCHAR(100),
		@PageNumber			INT,
		@VSUBTOTAL			NUMERIC(36,2),
		@VTOTAL_PAGINA		INT,
		@VTOTAL				INT,
		@VIZQUIERDA			VARCHAR(MAX),
		@VPAGINADO			VARCHAR(MAX),
		@VDERECHA			VARCHAR(MAX),
		@VPAGINAS			VARCHAR(MAX),
		@VACTUAL			INT,
		@VPREVIUS			VARCHAR(50),
		@VAGENDA_CONSULTOR	VARCHAR(50),
		@VSTRUCTURE			VARCHAR(100)
 
DECLARE @vproyecto			varchar(max),
		@vobs				varchar(max),
		@vestado_proy		varchar(max),
		@vnormas			varchar(max),
		@vfechaini			varchar(max),
		@vfechafin			varchar(max),
		@vhoras				varchar(max),
		@vopciones			varchar(max),
		@vinfo				varchar(max)
 
DECLARE @VID_PROYECTO_SERV	VARCHAR(MAX),
		@VTIPO_SERVICIO		varchar(max), 
		@VHORAS_SERV_EJEC	varchar(max), 
		@VFECHA_INI_SERV	varchar(max), 
		@VFECHA_FIN_SERV	varchar(max), 
		@VCIERRE			varchar(max), 
		@VNOMBRE_SERV		varchar(max), 
		@VLUGAR_SERV		varchar(max),
		@VHORAS_SERV		varchar(max),
		@VID_SERV_DELETE	VARCHAR(100),
		@VCANT_AGENDAS		INT,
		@VMENSAJE			varchar(4000)
 
DECLARE @VARCLIENTE			varchar(max), 
		@VARPROYECTO		varchar(max), 
		@VARNORMA			varchar(max), 
		@VARFECHAD			varchar(max), 
		@VARFECHAH			varchar(max), 
		@VARPROFESIONAL		varchar(max), 
		@VAROBSERVACIONES	varchar(max), 
		@VID_AGENDA			varchar(max), 
		@VARSERVICIO		varchar(max), 
		@VARDIAS			varchar(max), 
		@VAROBS_HR			varchar(max), 
		@VAROBS_CALIF		varchar(max), 
		@VAROBS_LOGIS		varchar(max), 
		@VARHORAS			varchar(max),
		@VSTATUS			varchar(max),
		@VARESTADO			varchar(max),
		@VCANT_AGENDA		INT
 
DECLARE @VFRECUENCIA		VARCHAR(50),
		@VDOC_EMPRESA		VARCHAR(50),
		@VMANUAL_DOC		VARCHAR(50),
		@VREQ_INGRESO		VARCHAR(50),
		@VCV_CERTIF			VARCHAR(50),
		@VLOGISTICA			VARCHAR(50),
		@VCURSO				VARCHAR(300),
		@VMATERIAL			VARCHAR(50),
		@VESTADO_ENVIO		VARCHAR(50),
		@VRECIBIDO			VARCHAR(50),
		@VCANT_SEG			INT
 
DECLARE @VFECHA_MINUTA		VARCHAR(50),
		@VNOMBRE			VARCHAR(300),
		@VOBSERV_MINUTA		VARCHAR(400),
		@VACCION			VARCHAR(MAX),
		@VFECHA_PLAN		VARCHAR(50),
		@VOBSERV_PLAN		VARCHAR(400),
		@VCANT_MC			INT,
		@VCANT_PE			INT,
		@VCANT_PA			INT,
		@VCANT_IA			INT,
		@VCANT_IC			INT
 
--AGENDA--
DECLARE @VNORMA_AGENDA		VARCHAR(4000),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VESTADO_AGENDA		VARCHAR(100),
		@VESTADO_AGENDA_CODE VARCHAR(50),
		--@VOBSERV_LOGIS_AGENDA VARCHAR(400),
		@VOBSERV_CALIF_AGENDA VARCHAR(400),
		@VOBSERV_AGENDA		VARCHAR(400),
		@VCONSULTORES_AGENDA VARCHAR(400),
		@VCONSULTORES_AGENDA_DESC VARCHAR(400),
		@lstDato			VARCHAR(100), 
		@lnuPosComa			INT,
		@VALOR				VARCHAR(400),
		@VDESCNORMAS		VARCHAR(4000)
 
DECLARE @ODETALLE			VARCHAR(MAX)
 
BEGIN
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA_SELEC = ISNULL(AGENDA_ID,''),
			@VTAB = ISNULL(TAB,''), --proyecto o servicio
			@VTAB_SERV = ISNULL(TAB_SERV,''), --detalle de servicio
			@VTAB_AGENDA = ISNULL(TAB_AGENDA,''), --detalle visita
			@VDESC_ERROR = ISNULL(DESC_ERROR,''),
			@VFECHA_INI_TMT = ISNULL(FECHA_INICIO_SERV,''),
			@VFECHA_FIN_TMT = ISNULL(FECHA_FIN_SERV,''),
			@VHORAS_TMT = ISNULL(HORAS_SERV,''),
			@VMONTO_TMT = REPLACE(ISNULL(MONTO_SERV,'0'),'.',''),
			@VNOMBRE_SERV_TMT = ISNULL(NOMBRE_SERV,''),
			@VLUGAR_SERV_TMT = ISNULL(LUGAR_SERV,''),
			@VCIERRE_TMT = ISNULL(CIERRE_SERVICIO,''),
			@VCLAVE_DELETE = ISNULL(CLAVE_DELETE,''),
			@PageNumber	= (CONVERT(INT,ISNULL(NRO_PAGINA,0))),
			@VPREVIUS = ISNULL(PREVIUS,''),
			@VAGENDA_CONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			@VID_SERV_DELETE = ISNULL(ID_SERV_DELETE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @PROCESSID
 
	--DEFINO A QUE ESTRUCTURA VOLVER--
	IF (@VAGENDA_CONSULTOR = '') BEGIN
		--HOME INICIO--
		SET @VSTRUCTURE = '522967A7-DDC9-465B-969B-85997AE1B085'
	END ELSE BEGIN
		--AGENDA CONSULTOR--
		SET @VSTRUCTURE = '59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'
		UPDATE XAGENDA SET PREVIUS = NULL WHERE PAR_KEY = @PROCESSID
	END
 
	IF (@VTAB = '') BEGIN
		SET @VTAB = '0'
	END
 
	SET @VCANT_PROY_ABI = 0
	SET @VCANT_PROY_CER = 0
	SET @VCANT_SERVICIOS = 0
	SET @VTOTAL = 0 
 
	SELECT	@VCANT_PROY_ABI = COUNT(*)
	FROM	LK_PROYECTO P
	WHERE	P.ID_CLIENTE = @VCLIENTE
	AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'	
 
	SELECT	@VCANT_PROY_CER = COUNT(*)
	FROM	LK_PROYECTO P
	WHERE	P.ID_CLIENTE = @VCLIENTE
	AND		P.ESTADO_PROYECTO_TOTAL = 'TERMINADO'
 
	IF (@VID_PROYECTO <> '') BEGIN
 
		SELECT	@VCANT_SERVICIOS = COUNT(1)
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	IF (@VID_SERVICIO <> '') BEGIN
		
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,''),
				@VFECHA_INI_SELEC = FECHA_INICIO_REAL,
				@VFECHA_FIN_SELEC = NULLIF(ISNULL(FECHA_FIN_REAL,''),''),
				@VHORAS_SELEC = TOTAL_HORAS_PROYECTADAS,
				@VMONTO_SELEC = MONTO_PRESUP,
				@VCIERRE_SELEC = ISNULL(CIERRE,'NO')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
		IF (@VDESC_ERROR = '') BEGIN
			SET @VFECHA_INI_TMT = @VFECHA_INI_SELEC
			SET @VFECHA_FIN_TMT = @VFECHA_FIN_SELEC
			SET @VHORAS_TMT = @VHORAS_SELEC
			SET @VMONTO_TMT = @VMONTO_SELEC
			SET @VNOMBRE_SERV_TMT = @VNOMBRE_SERV_SELEC
			SET @VLUGAR_SERV_TMT = @VLUGAR_SERV_SELEC
			SET @VCIERRE_TMT = @VCIERRE_SELEC
		END
	END
 
	SET @VMENSAJE = ''
 
	--AGREGO CONTROL BOTON ELIMINAR SERVICIO--
	IF (@VID_SERV_DELETE <> '') BEGIN
		
		SET @VCANT_AGENDAS = 0
 
		SELECT	@VCANT_AGENDAS = COUNT(1)
		FROM	LK_AGENDA
		WHERE	PROYECTO_SERV_ID = @VID_SERV_DELETE
		
		IF (@VCANT_AGENDAS = 0) BEGIN
			
			DELETE	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID_SERV_DELETE
 
		END ELSE BEGIN
			
			SET @VMENSAJE = 
			'<script>
				alert("NO Puede Eliminar el Servicio si el mismo tiene Visitas Cargadas");
			</script>'
 
		END
	END
 
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
			@VOBSERVACIONES = ISNULL(OBSERV_CLIENTE,''),
			@VCONTACTO = ISNULL(CONTACTO_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
	
	SET @VDIRECCION = ISNULL(@VCALLE,'') + ' ' + ISNULL(@VNRO,'') + ' / ' + --' - Depto: '+ ISNULL(@VPISO,'') + char(10) +
					  ISNULL(@VLOCALIDAD,'') + ' - ' + ISNULL(@VPROVINCIA,'')
 
	--logica para armar parte inferior en variable @detalle
	IF (@VID_AGENDA_SELEC = '') BEGIN
 
		SET @ODETALLE = 
		'<div class="w3-bar" style="background-color:#light-gray;font-size:14px">
			<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '0' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''0'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>
			<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '1' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''1'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-calendar-alt w3-margin-right"></i>Visitas</button>
			<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '2' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''2'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-shoe-prints w3-margin-right"></i>Datos Seguimiento</button>'
			+CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN +
					'<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '3' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''3'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-archive w3-margin-right"></i>Minuta de Cierre</button>
						<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '4' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''4'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-list-alt w3-margin-right"></i>Plan Estrategico</button>'
				WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN +
					'<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '5' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''5'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard w3-margin-right"></i>Plan Auditoría</button>
						<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '6' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''6'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard-list w3-margin-right"></i>Informe Auditoría</button>'
				WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN +
					'<button class="w3-bar-item w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' style="background-color:'+CASE WHEN @VTAB_SERV = '7' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_SERV'',''7'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard-list w3-margin-right"></i>Informe Capacitación</button>'
				ELSE ''
				END + 
			CASE WHEN @VTAB_SERV = '1' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;"><i class="fas fa-calendar-plus"></i>&nbsp;&nbsp;Agregar Visita</button>'
				WHEN @VTAB_SERV = '2' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''6DDF0683-6FD9-4D57-8FF0-C2FA07AE1397'');return false;"><i class="fas fa-edit"></i>&nbsp;&nbsp;Editar Datos</button>'
				WHEN @VTAB_SERV = '3' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');return false;"><i class="fas fa-archive"></i>&nbsp;&nbsp;Agregar Minuta</button>'
				WHEN @VTAB_SERV = '4' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''B0569958-40AB-49AD-8036-555088709D77'');return false;"><i class="fas fa-list-alt"></i>&nbsp;&nbsp;Agregar Plan</button>'
				WHEN @VTAB_SERV = '5' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''DFE8677A-7CCF-4D8E-A91D-4EB3F526393C'');return false;"><i class="fas fa-clipboard"></i>&nbsp;&nbsp;Agregar Plan</button>'
				WHEN @VTAB_SERV = '6' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''3F6EFE7E-110B-4A5E-953B-B0E5D49C0F16'');return false;"><i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Agregar Informe</button>' 
				WHEN @VTAB_SERV = '7' THEN
				'<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="goto('''+@FORM_ID+''',''931875EA-23ED-4EEA-BF4F-8A53C7B1FB90'');return false;"><i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Agregar Informe</button>'
			ELSE ''	END +
			CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN '' ELSE
			'<span class="w3-bar-item w3-right" style="color:#641E16;font-size:14px;"> 
				<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
									'fas fa-user-tie"'
								WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
									'fas fa-chalkboard-teacher"'
								WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
									'fas fa-user-graduate"' ELSE '' END+' style="color:black;"></i>&nbsp;&nbsp;<b>' + SUBSTRING(ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,''),1,80)+'</b></span>' END + '
		</div>
		<div class="w3-container" style="padding:1px;"></div>'+
		CASE WHEN ISNULL(@VTAB_SERV,'') = '' THEN
			'<table id="TableDet" class="w3-table-all">
			<tr style="height:470px;">
				<td style="text-align:center;vertical-align: middle;font-size:12px"><b>Debe Seleccionar un Servicio</b></td>
			</tr>
			</table>'
		ELSE
			CASE WHEN ISNULL(@VTAB_SERV,'') = '0' THEN 
					'<div class="w3-container w3-padding" style="border: 2px solid gray;">
							<form class="w3-container" style="background-color:light-gray;border-style: solid 1px;border-color:gray;">
							<div class="w3-row-padding">
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Nombre&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
									<input class="w3-input w3-border w3-round" type="text" name="SP.NOMBRE_SERV" value="' + ISNULL(@VNOMBRE_SERV_TMT,'') + '">
								</div>
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Lugar&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
									<input class="w3-input w3-border w3-round" type="text" name="SP.LUGAR_SERV" value="' + ISNULL(@VLUGAR_SERV_TMT,'') + '">
								</div>
								<div>
									&nbsp;
								</div>
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Inicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
									<input class="w3-input w3-border w3-round" type="date" name="SP.FECHA_INICIO_SERV" value="'+ISNULL(CONVERT(VARCHAR,@VFECHA_INI_TMT,23),'') +'">
								</div>
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Fin&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
									<input class="w3-input w3-border w3-round" type="date" name="SP.FECHA_FIN_SERV" value="'+ISNULL(CONVERT(VARCHAR,@VFECHA_FIN_TMT,23),'') +'">
								</div>
								<div>
									&nbsp;
								</div>
								<div class="w3-third">
									<label>&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Horas Proyectadas&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
									<input class="w3-input w3-border w3-round" type="text" name="SP.HORAS_SERV" value="' + ISNULL(@VHORAS_TMT,'') + '">
								</div>
								<div class="w3-third">
									<label>&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Monto</label>
									<input class="w3-input w3-border w3-round" type="text" name="SP.MONTO_SERV" value="' + ISNULL(@VMONTO_TMT,'') + '">
								</div>
								<div class="w3-third">
									<label>&nbsp;<i class="fas fa-window-close"></i>&nbsp;&nbsp;Cierre</label>
									<select class="w3-input w3-border w3-round" name="SP.CIERRE_SERVICIO">
										<option value="SI" '+CASE WHEN isnull(@VCIERRE_TMT,'') = 'SI' THEN 'selected="selected"' ELSE '' END+'>Si</option>
										<option value="NO" '+CASE WHEN isnull(@VCIERRE_TMT,'') = 'NO' THEN 'selected="selected"' ELSE '' END+'>No</option>
									</select>									
								</div>
							</div>
						</form>
						<div>
							&nbsp;
						</div>
						<div class="w3-row w3-topbar">'+
							CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
								'<div class="w3-container" style="padding:8px;"></div>'
							ELSE 
								'<div class="w3-panel w3-pale-red" style="height: 20px;">
									<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>'+isnull(@VDESC_ERROR,'')+'</b></font>
								</div>' 
							END + '
						</div>
						<div class="w3-row">
							<div class="w3-half w3-container ">
								<button onclick="goto('''+@FORM_ID+''',''A77CE927-9D2D-4C15-91CE-34388075B9F7'');return false;" class="w3-button w3-round" style="background-color:#641E16;color:white;">Guardar</button>
							</div>
						</div>
					</div>'
			WHEN ISNULL(@VTAB_SERV,'') = '1' THEN 
				CASE WHEN (@VCANT_AGENDA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Agendas Cargadas</b></td>
						</tr>
					</table>' END
			WHEN ISNULL(@VTAB_SERV,'') = '2' THEN 
				ISNULL(@VTABLA_DET,'')
			WHEN ISNULL(@VTAB_SERV,'') = '3' THEN 
				CASE WHEN (@VCANT_MC > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Minutas de Cierre Cargadas</b></td>
						</tr>
					</table>' END
			WHEN ISNULL(@VTAB_SERV,'') = '4' THEN 
				CASE WHEN (@VCANT_PE > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Plan Estrategico Cargados</b></td>
						</tr>
					</table>' END
			WHEN ISNULL(@VTAB_SERV,'') = '5' THEN 
				CASE WHEN (@VCANT_PA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Plan Auditoria Cargados</b></td>
						</tr>
					</table>' END
			WHEN ISNULL(@VTAB_SERV,'') = '6' THEN 
				CASE WHEN (@VCANT_IA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Informe Auditoria Cargados</b></td>
						</tr>
					</table>' END
			WHEN ISNULL(@VTAB_SERV,'') = '7' THEN 
				CASE WHEN (@VCANT_IC > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
					'<table id="TableDet" class="w3-table-all">
						<tr style="height:470px;">
							<td style="text-align:center;vertical-align: middle;font-size:12px"><b>No Existen Informe Capacitacion Cargados</b></td>
						</tr>
					</table>' END
			ELSE '' END
		END
 
	END ELSE BEGIN
		
		SELECT	@VDIAS_AGENDA = DIAS,
				@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
				@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
				@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
				@VESTADO_AGENDA = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
				@VESTADO_AGENDA_CODE = A.ESTADO,
				@VNORMA_AGENDA = ISNULL(A.NORMA,''),
				@VCONSULTORES_AGENDA = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
				@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END,
				--@VOBSERV_LOGIS_AGENDA = ISNULL(A.OBSERV_LOGISTICA,''),
				@VOBSERV_CALIF_AGENDA = ISNULL(A.OBSERV_CALIF,''),
				@VOBSERV_AGENDA = ISNULL(A.OBSERVADOR,'')
		FROM	LK_AGENDA A
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
		WHERE	ID_AGENDA = @VID_AGENDA_SELEC
 
		WHILE LEN(@VNORMA_AGENDA) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VNORMA_AGENDA) -- Busca el caracter a separador
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VARNORMA
					SET @VARNORMA = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VNORMA_AGENDA, 1, @lnuPosComa - 1)
 
					SELECT	@VALOR = '<font style="font-size:13px;color:black;text-align:left">'+DESC_APTITUD+'</font>'
					FROM	LK_APTITUDES
					WHERE	ID_APTITUD = @lstDato
 
					SET @VDESCNORMAS = ISNULL(@VDESCNORMAS,'') + @VALOR + '</br>'
 
					SET @VNORMA_AGENDA = SUBSTRING(@VARNORMA, @lnuPosComa + 1, LEN(@VNORMA_AGENDA))
				END
			END
 
		SET @ODETALLE = 
		'<div class="w3-bar" style="background-color:#light-gray;font-size:14px;">
				<span class="w3-bar-item w3-text-white" style="background-color:#641E16;"><i class="fas fa-calendar-alt w3-margin-right"></i>Detalle Visita</span>' +
				CASE WHEN ISNULL(@VTAB_AGENDA,'') <> '0' THEN
				'<span class="w3-bar-item w3-left" style="color:#641E16;font-size:14px;">
					<i class="fas fa-calendar" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
					<i class="fas fa-clock" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
					<i class="fas fa-users" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b></span>'
				ELSE '' END +
				CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN '' ELSE '
				<button class="w3-bar-item w3-button w3-text-white w3-right" style="background-color:#641E16;" onclick="almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-arrow-alt-circle-left w3-margin-center"></i>&nbsp;&nbsp;Volver</button>
				<span class="w3-bar-item w3-right" style="color:#641E16;font-size:14px;">
					<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
										'fas fa-user-tie"'
									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
										'fas fa-chalkboard-teacher"'
									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
										'fas fa-user-graduate"' ELSE '' END+' style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,'')+'</b></span>' END + '			
			</div>
			<div class="w3-container" style="padding:1px;"></div>
			<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>
			<div class="w3-bar" style="background-color:#light-gray;font-size:14px">
				<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '0' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''0'');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>
				<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '1' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''1'');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-road w3-margin-right"></i>Hoja de Ruta</button>
				<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '2' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''2'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-money-check-alt w3-margin-right"></i>Viáticos</button>
				<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '3' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''3'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-hand-holding-usd w3-margin-right"></i>Honorarios</button>' +
				CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
					'<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '4' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''4'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-paperclip w3-margin-right"></i>Minuta de Visita</button>'
					WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN
					''
					WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN
					'<button class="w3-bar-item w3-button w3-text-white" style="background-color:'+CASE WHEN @VTAB_AGENDA = '5' THEN '#641E16' ELSE 'gray' END+';" onclick="almacenarSeleccion(''TAB_AGENDA'',''5'');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-tasks w3-margin-right"></i>CheckList</button>'
				END + 
				CASE WHEN @VTAB_AGENDA = '0' THEN
					'<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;border:2px solid gray;" title="Modificar" onclick="goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');return false;"><i class="fas fa-edit"></i></button>
					<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;border:2px solid gray;" title="Editar" onclick="document.getElementById(''nuevoProceso'').style.display=''block'';return false;"><i class="fas fa-pen"></i></button>'
					 --<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;border:2px solid gray;" title="Editar" onclick="document.getElementById(''nuevoProceso'').style.display=''block'';return false;"><i class="fas fa-pen"></i></button>'
					WHEN @VTAB_AGENDA = '2' THEN
					'<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;" title="Nuevo Viático" onclick="goto('''+@FORM_ID+''',''9699BAC1-EB3A-41AF-AB6C-8B97A339EFA2'');return false;"><i class="fa fa-plus"></i></button>
					 <i class="fas fa-clipboard-list w3-right w3-xxlarge" style="color:#641E16;cursor:pointer;" title="Parte Logistico" onclick="goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');">&nbsp;&nbsp;&nbsp;</i>
					 <i class="fas fa-file-invoice-dollar w3-right w3-xxlarge" style="color:#641E16;cursor:pointer;" title="Rendicion Viaticos" onclick="goto('''+@FORM_ID+''',''816D74E9-0C1C-478A-A699-CF1903A61B23'');">&nbsp;&nbsp;&nbsp;</i>'
					WHEN @VTAB_AGENDA = '3' THEN 
					'<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;" title="Nuevo Honorario" onclick="goto('''+@FORM_ID+''',''0B438E7D-728C-4D27-B9C5-534984C18EF9'');return false;"><i class="fa fa-plus"></i></button>'
					WHEN @VTAB_AGENDA = '4' THEN 
					'<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;" title="Nueva Minuta" onclick="goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');return false;"><i class="fa fa-plus"></i></button>'
					WHEN @VTAB_AGENDA = '5' THEN 
					'<button class="w3-bar-item w3-right w3-button w3-text-white" style="background-color:#641E16;width:4%;" title="Nuevo CheckList" onclick="goto('''+@FORM_ID+''',''3F11610E-DB37-427B-997D-1507E8982A92'');return false;"><i class="fa fa-plus"></i></button>'
				ELSE '' END +'
			</div>
			<div class="w3-container" style="padding:1px;"></div>' +
			CASE WHEN ISNULL(@VTAB_AGENDA,'') = '0' THEN
				'<div class="w3-container w3-padding" style="border: 2px solid gray;">
							<form class="w3-container" style="background-color:light-gray;border-style: solid 1px;border-color:gray;">
							<div class="w3-row-padding">
								<div class="w3-quarter">
									<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VFECHAD_AGENDA,'') + '" disabled>
								</div>
								<div class="w3-quarter">
									<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VFECHAH_AGENDA,'') + '" disabled>
								</div>
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VOBSERV_AGENDA,'') + '" disabled>
								</div>
								<div>
									&nbsp;
								</div>
								<div class="w3-quarter">
									<label>&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VESTADO_AGENDA,'') + '" disabled>
								</div>
								<div class="w3-quarter">
									<label>&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Días / Horas</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'') + '" disabled>
								</div>
								<div class="w3-half">
									<label>&nbsp;<i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Observaciones Calificación</label>
									<input class="w3-input w3-border w3-round" value="' + ISNULL(@VOBSERV_CALIF_AGENDA,'') + '" disabled>
								</div>
								<div>
									&nbsp;
								</div>
								<div class="w3-quarter">
									<label>&nbsp;<i class="fas fa-ruler"></i>&nbsp;&nbsp;Normas</label></br>'+
									ISNULL(@VDESCNORMAS,'')+'
								</div>
								<div class="w3-quarter">
									<label>&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Profesionales</label></br>' + 
									ISNULL(@VCONSULTORES_AGENDA,'') + '
								</div>'+
								--<div class="w3-half">
								--	<label>&nbsp;<i class="fas fa-list-alt"></i>&nbsp;&nbsp;Observaciones Logística</label>
								--	<input class="w3-input w3-border w3-round" value="' + ISNULL(@VOBSERV_LOGIS_AGENDA,'') + '" disabled>
								--</div>
							'</div>
						</form>
					</div>'
			ELSE 
				'<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>' 
			END
	END
 
 
 
----TOP CONTAINER----
/*
<div class="w3-bar w3-muhle-color w3-round-down">
	<div class="w3-button w3-bar-item w3-muhle-hover-color" onclick="document.getElementById(''nuevoProceso'').style.display=''block'';"><i class="fas fa-plus"></i>&nbsp;&nbsp;Crear</div>
	<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-home w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Actualizar" onclick="goto('''+@FORM_ID+''',''8AE66594-9787-454F-8800-4ADA67798631'');return false;"></i></span>
</div>
*/
 
	SET @PS_TITULO = '	<div class="w3-row w3-back w3-light-grey">
							<div class="w3-col w3-padding">
								<div class="w3-card-4 w3-round">
									<div class="w3-bar w3-muhle-vocaturo w3-round">
										<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-street-view w3-large"></i>&nbsp;&nbsp;Vista 360 Cliente</span>
										<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver a Proyectos" onclick="almacenarSeleccion(''TAB'','''');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''','''+ISNULL(@VSTRUCTURE,'')+''');return false;"></i></span>
									</div>
								</div>
							</div>
						</div>
						<div class="w3-row w3-back w3-light-grey">
							<div class="w3-col w3-padding">
								<div class="w3-card-4 w3-round w3-padding">'+
									--divido en dos la parte superior--
									'<div class="w3-row-padding">'+
										--parte izquierda--	
										'<div class="w3-col s3">'+
											--card cliente-- quarter
											--<span class="w3-bar-item w3-left" style="color:white"><img src="./../img/avatar7.png" style="height:50px;width:50px;" alt="Avatar" class="w3-left w3-circle w3-margin-center"></span>
											'<div class="w3-card-4 w3-round">
												<header class="w3-container w3-muhle-color w3-center w3-padding w3-round">
													<span class="w3-muhle-text-14" style="font-size:20px;color:white">&nbsp;&nbsp;'+ISNULL(@VRAZON_SOCIAL,'')+'</span>
												</header>
												<div class="w3-container w3-padding">
													<div class="w3-container">
														<span class="w3-muhle-text-14 w3-left"><i class="fas fa-address-card w3-text-blue-gray"></i>&nbsp;' + ISNULL(@VCUIT,'') + '</span>
														<span class="w3-muhle-text-14 w3-right"><i class="fas fa-envelope w3-text-blue-gray"></i>&nbsp;' + ISNULL(@VEMAIL,'') + '</span>
													</div>
													<div class="w3-container">
														<span class="w3-muhle-text-14 w3-left"><i class="fas fa-phone w3-text-blue-gray"></i>&nbsp;' + ISNULL(@VTELEFONO1,'') +'</span>
														<span class="w3-muhle-text-14 w3-right"><i class="fas fa-mobile-alt w3-text-blue-gray"></i>&nbsp;' + ISNULL(@VTELEFONO2,'') +'</span>
													</div>
													<hr style="height:2px;border-width:0;color:gray;background-color:gray;">
													<div class="w3-container">
														<span class="w3-muhle-text-14 w3-left"><i class="fas fa-home w3-text-blue-gray"></i>&nbsp;' + ISNULL(@VDIRECCION,'')  + '</span>
													</div>
												</div>
												<div class="w3-container w3-padding">
													<table class="w3-table w3-borderer" style="background-color:#E6E6E6">
														<tr>
															<td class="w3-muhle-text-12"><i class="fas fa-user w3-text-blue"></i></td>
															<td class="w3-muhle-text-12">Contacto Cliente</td>
															<td class="w3-muhle-text-12">' + ISNULL(@VCONTACTO,'') + '</td>
														</tr>
														<tr>
															<td class="w3-muhle-text-12"><i class="fas fa-project-diagram w3-text-green"></i></td>
															<td class="w3-muhle-text-12">Proyectos En Curso</td>
															<td class="w3-muhle-text-12">' + CONVERT(VARCHAR,@VCANT_PROY_ABI) +'</td>
														</tr>
														<tr>
															<td class="w3-muhle-text-12"><i class="fas fa-project-diagram w3-text-red"></i></td>
															<td class="w3-muhle-text-12">Proyectos Finalizados</td>
															<td class="w3-muhle-text-12">' + CONVERT(VARCHAR,@VCANT_PROY_CER) +'</td>
														</tr>
													</table>
												</div>
											</div>'+
											--fin card cliente--
										'</div>'+
										--parte derecha--
										'<div class="w3-col s9">
											<div class="w3-bar w3-muhle-vocaturo w3-round w3-muhle-text-14">
												<button class="w3-bar-item w3-muhle-hover-color w3-button w3-text-white" onclick="almacenarSeleccion(''TAB'',''0'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-project-diagram w3-margin-right"></i>Proyectos</button>
												<button class="w3-bar-item w3-muhle-hover-color w3-button w3-text-white" onclick="almacenarSeleccion(''TAB'',''2'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-project-diagram w3-margin-right"></i>Finalizados</button>
												<button class="w3-bar-item w3-muhle-hover-color w3-button w3-text-white" '+CASE WHEN @VID_PROYECTO = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB'',''1'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-cogs w3-margin-right"></i>Servicios</button>
												<button class="w3-bar-item w3-muhle-hover-color w3-button w3-text-white" '+CASE WHEN @VID_PROYECTO = '' THEN 'disabled' ELSE '' END+' title="Nuevo" onclick="almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''PROYECTO_SERV_ID'',''N'');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''F8B6A5CD-5252-4CDF-ABEA-67260485E937'');return false;"><i class="fa fa-plus"></i></button>
												<span class="w3-bar-item w3-muhle-hover-color w3-right" style="color:#641E16;font-size:14px;">'+CASE WHEN @VID_PROYECTO = '' THEN '' ELSE '<i class="fas fa-project-diagram" style="color:black;"></i>&nbsp;&nbsp;<b>' END+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,80),'')+'</b></span>
											</div>
											<div class="w3-container" style="padding:1px;"></div>
											<div id="table1">'+ISNULL(@VTABLA,'')+'</div>
											<div class="w3-container w3-center" style="padding:8px;"></div>
											'+ISNULL(@VPAGINADO,'')+'
											<div class="w3-container w3-center" style="padding:8px;">
												<span>'+CASE WHEN @VTOTAL <> '0' THEN
												'Página '+ CONVERT(VARCHAR,@PageNumber+1)+' de '+CONVERT(VARCHAR,@VTOTAL_PAGINA)+', 
												  mostrando filas ' + CASE WHEN (@PageNumber = 0) THEN '1' ELSE CONVERT(VARCHAR,(@PageNumber*5) + 1) END + ' a la '+
													CASE WHEN (@PageNumber + 1 < @VTOTAL_PAGINA) THEN
														CONVERT(VARCHAR,(@PageNumber*5) + 5) 
													ELSE 
														CONVERT(VARCHAR,@VTOTAL)
													END +' de '+CONVERT(VARCHAR,@VTOTAL)
												  ELSE
												  'No se han encontrado resultados para esta búsqueda.'
												  END + '</span>
											</div>
										</div>'+
										--fin parte derecha--
									'</div>'
									--fin division superior class="w3-row"--
									
 
----FOOT CONTAINER----
 
	SET @PS_TABLE_1 =				--division superior con inferior--
									'<div class="w3-container" style="padding:8px;"></div>
									 <div class="w3-row w3-topbar"></div>
									 <div class="w3-container" style="padding:2px;"></div>'+
									--parte inferior--	
										isnull(@ODETALLE,'') +
 
									--inicio pop up--
									'<div id="nuevoProceso" class="w3-modal w3-round">
										<div class="w3-modal-content w3-round">
											<header class="w3-container w3-muhle-color w3-round-up">' +
												CASE 
													WHEN '' <> '' THEN '<h3>Editar Atributo</h3>'
													ELSE '<h3>Nuevo Atributo</h3>'
												END +
											'</header>
											<div class="w3-container w3-padding-large">
												<div class="w3-row w3-padding-large" style="width:100%">
													<label class="w3-muhle-text-14">&nbsp;Estado</label>
													<select class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" id="cmb1" name="SP.AGENDA_ESTADO"></select>
												</div>
												<div class="w3-row w3-padding-large" style="width:100%">
													<label class="w3-muhle-text-14">&nbsp;Observaciones</label>
													<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_OBSERVADOR">
												</div>
												<div class="w3-row w3-padding-large" style="width:100%">
													<label class="w3-muhle-text-14">&nbsp;Valor</label>
													<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_OBSERV_CALIF">
												</div>
													&nbsp;
													&nbsp;
											</div>
											<div class="w3-container w3-border-top w3-padding-16 w3-light-grey w3-round-down">
												<div class="w3-container w3-border-top w3-padding-16 w3-light-grey w3-round-down">
															<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''7B62AD63-D2A5-40B3-90C4-45A11E8DD67A'');">Guardar</btn>
															<btn type="btn" class="w3-button w3-muhle-color w3-medium w3-round" onclick="document.getElementById(''nuevoProceso'').style.display=''none''">Cancelar</btn>
												</div>
											</div>
										</div>
									</div>'
									--fin pop up--
	
	--cierre container @PS_TITULO--
	SET @PS_TABLE_1 = @PS_TABLE_1 +
								'</div>
							</div>
						</div>'
 
	SET @PS_TABLE_1 = @PS_TABLE_1 + '<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '260022DF-4FC1-4944-809E-BC3834834FD1' + ''', ''' + '' +''', '''');</script>'
 
END
