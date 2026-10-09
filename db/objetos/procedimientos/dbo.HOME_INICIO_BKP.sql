CREATE PROCEDURE [dbo].[HOME_INICIO_BKP]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @OMENU		AS VARCHAR(MAX) OUTPUT,
 @OTABS		AS VARCHAR(MAX) OUTPUT,
 @OPAGINA	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE		@UNITDESC			VARCHAR(300),
			@USERDESC			VARCHAR(300),
			@VSOLAPA			VARCHAR(50),
			@VID_DELETE			VARCHAR(50),
			@VID_MC_DELETE		VARCHAR(100),
			@VPROY_MC			VARCHAR(50),
			@VFECHA_DESDE		DATETIME,
			@VFECHA_HASTA		DATETIME,
			@VF_CLIENTE			VARCHAR(50),
			@VF_PROYECTO		VARCHAR(50),
			@VF_SERVICIO		VARCHAR(50),
			@VF_ESTADO			VARCHAR(50),
			@VFILTRO			VARCHAR(50),
			@VTABLA				VARCHAR(MAX),
			@Pagina				INT,
			@VTOTAL				INT,
			@VTOTAL_PAGINA		INT,
			@VOPTIONS_CLI		VARCHAR(MAX),
			@VCODE				VARCHAR(100),
			@VDESC				VARCHAR(4000),
			@VTIPO_CLI			VARCHAR(100)
 
BEGIN	
 
	--SET @Pagina = 0
	--SET	@VTOTAL = 0
	--SET @VTOTAL_PAGINA = 0
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	SELECT	@VFILTRO = ISNULL(FILTRO,''),
			@VSOLAPA = ISNULL(SOLAPA,''),
			@VID_DELETE = ISNULL(ID_DELETE,''),
			@VID_MC_DELETE = ISNULL(MC_DELETE,''),
			@Pagina = CONVERT(INT,ISNULL(NRO_PAGINA,0))	
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF (@VSOLAPA = '') BEGIN
		SET @VSOLAPA = 'PLAN'
	END
 
	IF (@VFILTRO = '') BEGIN
		SELECT	@VFECHA_DESDE = CAST(Convert(CHAR(8),GETDATE() - 5,112) as DATETIME),--PrimerDiaMes, 
				@VFECHA_HASTA = CAST(Convert(CHAR(8),GETDATE() + 3,112) as DATETIME)--UltimoDiaMes 
		FROM	Calendar 
		WHERE	Fecha = convert(varchar,GETDATE(),113)	
 
		UPDATE	XAGENDA 
		SET		FECHA_DESDE = @VFECHA_DESDE, 
				FECHA_HASTA = @VFECHA_HASTA,
				INICIO_CLIENTE = NULL,
				PROYECTO = NULL,
				SERVICIO = NULL,
				ESTADO = NULL
		WHERE	PAR_KEY = @IPKEYJOB	
 
		SELECT	@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,''),
				@VF_ESTADO = ISNULL(ESTADO,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
	END ELSE BEGIN
 
		SELECT	@VFECHA_DESDE = FECHA_DESDE,
				@VFECHA_HASTA = FECHA_HASTA,
				@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,''),
				@VF_ESTADO = ISNULL(ESTADO,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
	END
	
	IF (@VID_MC_DELETE <> '') BEGIN
 
		SELECT	@VPROY_MC = ID_PROYECTO
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_ADJUNTO = @VID_MC_DELETE
 
		UPDATE	LK_PROYECTO
		SET		FECHA_FIN_TOTAL = FECHA_FIN_REAL,
				ESTADO_PROYECTO_TOTAL = 'ENCURSO'
		WHERE	ID_PROYECTO = @VPROY_MC
 
		DELETE	LK_PROYECTO_DOCUM
		WHERE	ID_ADJUNTO = @VID_MC_DELETE
 
		DELETE	PHYSICAL_ATTACHED_DOCUMENT
		WHERE	PKEY = @VID_MC_DELETE
 
	END
 
	IF (@VID_DELETE <> '') BEGIN
		
		DELETE	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_DELETE
 
		DELETE	LK_PROYECTO 
		WHERE	ID_PROYECTO = @VID_DELETE
 
	END
 
	--ELIMINO ADJUNTOS DEL TRAMITE POR SI SE CARGARON ALGUNOS PREVIAMENTE--
	DELETE	PHYSICAL_ATTACHED_DOCUMENT
	WHERE	PAR_KEY = @IPKEYJOB	
	
	--COMBO DE CLIENTES--
	DECLARE Clientes CURSOR FOR 
		SELECT	ID_CLIENTE, RAZON_SOCIAL_CLIENTE + ' - ('+CUIT_CLIENTE+')', TIPO_CLIENTE
		FROM	LK_CLIENTES
		ORDER BY 2
 
	SET @VOPTIONS_CLI = '<option value=""></option>'
 
	OPEN Clientes  
	FETCH NEXT FROM Clientes INTO @VCODE, @VDESC, @VTIPO_CLI
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @VOPTIONS_CLI = @VOPTIONS_CLI +
		'<option value="'+@VCODE+'" style="color:'+case when @VTIPO_CLI = 'ACTIVO' then 'black' when @VTIPO_CLI = 'PASIVO' then 'blue' else 'red' end +'"'+ CASE WHEN @VF_CLIENTE = @VCODE THEN 'selected="selected"' ELSE '' END+'>'+@VDESC+'</option>'
			
		FETCH NEXT FROM Clientes INTO @VCODE, @VDESC, @VTIPO_CLI
	END 
 
	CLOSE Clientes  
	DEALLOCATE Clientes
 
	SET @OMENU = '
	<div class="w3-container" style="background-color:light-gray">
		<span class="w3-right" style="font-size:14px;">'+
			'Usuario: <b>'+@USERDESC+'</b> - Fecha: <b>' +CONVERT(VARCHAR, GETDATE(), 103)+' '+CONVERT(VARCHAR,GETDATE(),108)+'</b>
		</span>
	</div>
	<div class="w3-card-4 w3-round" style="background-color:#641E16;">
		<div class="w3-bar w3-round-up">
			<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-home w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Inicio</span>
		</div>
	</div>
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-container" style="background-color:#DCDCDC;text-align:left">
		<div class="w3-container" style="padding:4px;"></div>
		<div class="w3-row-padding">
			<div class="w3-quarter">
				<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-round" type="date" name="SP.FECHA_DESDE" value="'+CASE WHEN ISNULL(@VFECHA_DESDE,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_DESDE,23),'') END +'">
			</div>
			<div class="w3-quarter">
				<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-round" type="date" name="SP.FECHA_HASTA" value="'+CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_HASTA,23),'') END +'">
			</div>
			<div class="w3-quarter">
				<label><i class="fas fa-cogs"></i>&nbsp;&nbsp;Servicio</label>
				<select class="w3-input w3-border w3-round" name="SP.SERVICIO">
					<option value=""></option>
					<option value="2" '+CASE WHEN isnull(@VF_SERVICIO,'') = '2' THEN 'selected="selected"' ELSE '' END+'>Auditoria</option>
					<option value="3" '+CASE WHEN isnull(@VF_SERVICIO,'') = '3' THEN 'selected="selected"' ELSE '' END+'>Capacitacion</option>
					<option value="1" '+CASE WHEN isnull(@VF_SERVICIO,'') = '1' THEN 'selected="selected"' ELSE '' END+'>Consultoria</option>
				</select>
			</div>
			<div class="w3-quarter">
				<label><i class="fa fa-adjust"></i>&nbsp;&nbsp;Estado Proyecto</label>
				<select class="w3-input w3-border w3-round" id="cmb3" name="SP.ESTADO" '+CASE WHEN @VSOLAPA = 'PLAN' THEN 'disabled' ELSE '' END+'></select>
			</div>
			<div class="w3-container" style="padding:4px;"></div>
			<div class="w3-third">
				<label><i class="fas fa-user"></i>&nbsp;&nbsp;Cliente</label>
				<select class="w3-input w3-border w3-round" id="cmb1_'+@FORM_ID+'" name="SP.INICIO_CLIENTE" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROYECTOS'', '''',this.id);">
				'+ISNULL(@VOPTIONS_CLI,'')+'
				</select>
			</div>
			<div class="w3-twothird">
				<label><i class="fas fa-project-diagram"></i>&nbsp;&nbsp;Proyecto</label>
				<select class="w3-input w3-border w3-round" id="cmb2_'+@FORM_ID+'" name="SP.PROYECTO"></select>
			</div>
			<div class="w3-container" style="padding:4px;"></div>
			<div>
				<button onclick="almacenarSeleccion(''FILTRO'','''+'SI'+''');almacenarSeleccion(''NRO_PAGINA'',''0'');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;" class="w3-button w3-round w3-right" style="font-size:14px;background-color:#641E16;color:white;padding:8px 16px;"><i class="fas fa-search"></i>&nbsp;Buscar</button>
			</div>
			<div class="w3-container" style="padding:2px;"></div>
		</div>
		<div class="w3-container" style="padding:4px;"></div>
	</div>
	<div class="w3-panel w3-topbar"></div>'+
	--<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_CLIENTES'', '''+isnull(@VF_CLIENTE,'')+''', '''');</script>'+
	CASE WHEN ISNULL(@VF_CLIENTE,'') = '' THEN '' ELSE
		'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROYECTOS'', '''+isnull(@VF_PROYECTO,'')+''', '''+isnull(@VF_CLIENTE,'')+''');</script>' 
	END +
	'<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '3C2B554E-4339-4492-90D3-AE93773FB5D1' + ''', ''' + ISNULL(@VF_ESTADO,'') +''', '''');</script>'
	
	SET @OTABS = '
		<div class="w3-bar" style="background-color:gray;font-size:16px">
			<button style="width:44%;background-color:'+CASE WHEN @VSOLAPA = 'PLAN' THEN '#641E16' ELSE 'gray' END+';" class="w3-bar-item w3-button w3-text-white" onclick="almacenarSeleccion(''SOLAPA'','''+'PLAN'+''');almacenarSeleccion(''NRO_PAGINA'',''0'');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;"><i class="fas fa-calendar-check w3-large w3-margin-right"></i>Planificación</button>
			<button style="width:4%;background-color:'+CASE WHEN @VSOLAPA = 'PLAN' THEN '#641E16' ELSE 'gray' END+';" class="w3-bar-item w3-button w3-text-white" onclick="'+CASE WHEN @VSOLAPA = 'PLAN' THEN 'ExportaExcel();return false;' ELSE 'return false;' END+'"><i class="fas fa-file-excel w3-large w3-margin-right" title="Exportar Planificacion"></i></button>
			<button style="width:44%;background-color:'+CASE WHEN @VSOLAPA = 'PROYECTO' THEN '#641E16' ELSE 'gray' END+';" class="w3-bar-item w3-button w3-text-white" onclick="almacenarSeleccion(''SOLAPA'','''+'PROYECTO'+''');almacenarSeleccion(''NRO_PAGINA'',''0'');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');return false;"><i class="fas fa-project-diagram w3-large w3-margin-right"></i>Proyectos</button>
			<button style="width:4%;background-color:'+CASE WHEN @VSOLAPA = 'PROYECTO' THEN '#641E16' ELSE 'gray' END+';" class="w3-bar-item w3-button w3-text-white" onclick="'+CASE WHEN @VSOLAPA = 'PROYECTO' THEN 'ExportaExcel();return false;' ELSE 'return false;' END+'"><i class="fas fa-file-excel w3-large w3-margin-right" title="Exportar Proyectos"></i></button>
			<button style="width:4%;background-color:'+CASE WHEN @VSOLAPA = 'PROYECTO' THEN '#641E16' ELSE 'gray' END+';" class="w3-bar-item w3-button w3-text-white" title="Nuevo" onclick="'+CASE WHEN @VSOLAPA = 'PROYECTO' THEN 'almacenarSeleccion(''SOLAPA'','''+'PROYECTO'+''');almacenarSeleccion(''NRO_PAGINA'',''0'');goto('''+@FORM_ID+''',''4049307F-6C13-459D-AC01-54F97D942D1B'');return false;' ELSE 'return false;' END+'"><i class="fa fa-plus" style="font-size:16px"></i></button>
		</div>
		<div class="w3-container" style="padding:2px;"></div>
		<script>
			document.getElementById("table_SP_HOME_GRD_PLANIFICA_54").style.display = "none";
			function ExportaExcel(){
				debugger;
				TableToExcel.convert(document.getElementById("table_SP_HOME_GRD_PLANIFICA_54"));
			}
		</script>'
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			PROYECTO_ID = NULL,
			PROYECTO_SERV_ID = NULL,
			AGENDA_ID = NULL,
			TAB = NULL,
			TAB_SERV = NULL,
			TAB_AGENDA = NULL,
			FECHA_SELEC= NULL,
			AGENDA_DESDE = NULL,
			AGENDA_HASTA = NULL,
			PREVIUS = NULL,
			BUFFER = NULL,
			ACUMULA = NULL,
			AGENDA_ANO = DATEPART(YYYY,GETDATE()),
			AGENDA_MES = DATEPART(MM,GETDATE()),
			--FECHA_DESDE = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),103),
			--FECHA_HASTA = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),103),
			CLAVE_COTIZA = NULL,
			ID_DELETE = NULL,
			MC_DELETE = NULL	,
			TIPO_SELEC = NULL,
			ID_DETALLE = NULL,
			AGREGA_SERV = NULL,
			GRABA_SERV = NULL,
			CLIENTE = NULL,
			NRO_COTIZA = NULL,
			NOMBRE_PROY = NULL,
			FECHA_INICIO_PROY = NULL,
			FECHA_FIN_PROY = NULL,
			HORAS_PROY = '0',
			MONTO_PROY = '0',
			SERV_AUDI_PROY = NULL,
			SERV_CAPA_PROY = NULL,
			SERV_CONS_PROY = NULL,				
			CODIGO_PROY = NULL,
			OBSERV_PROY = NULL,
			--ESTADO_PROY = NULL,	
			CONTACTO_PROY=null		
	WHERE	PAR_KEY = @IPKEYJOB
 
END
