 
CREATE PROCEDURE [dbo].[HOME_INI_ADD_MINUTA_CONS]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VRAZON_SOCIAL		VARCHAR(400),
		@VNOMBRE_PROY		VARCHAR(400),
		@VTIPO_SERV			VARCHAR(50),
		@VNOMBRE			VARCHAR(400),
		@VLUGAR				VARCHAR(400),
		@VERROR				VARCHAR(50),
		@VDESC_ERROR		VARCHAR(4000),
		@VID_SELEC			VARCHAR(100)
 
DECLARE	@VSERVICIO		VARCHAR(50),
		@VID			VARCHAR(50),
		@VFECHA_INI		DATETIME,
		@VFECHA_FIN		DATETIME,
		@VDIAS			VARCHAR(50),
		@VMONTO			VARCHAR(50),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VPROYECTO		VARCHAR(50),
		@VIDCLIENTE		VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VDIASP			VARCHAR(50),
		@VTABLA			VARCHAR(MAX),
		@VARCLIENTE		VARCHAR(300), 
		@VARPROYECTO	VARCHAR(300), 
		@VARSERVICIO	VARCHAR(100), 
		@VARNORMA		VARCHAR(300), 
		@VARFECHA		VARCHAR(50), 
		@VARPROFESIONAL VARCHAR(300), 
		@VAROBSERVADOR	VARCHAR(300), 
		@VID_AGENDA		VARCHAR(50),
		@lstDato		VARCHAR(100), 
		@lnuPosComa		INT,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VSTATUS		VARCHAR(50),
		@VID_DELETE		VARCHAR(50),
		@VTIPO			VARCHAR(50),
		@VTIPO_SERVICIO	VARCHAR(50),
		@VAGENDA_ID		VARCHAR(100),
		@VMINUTA		VARCHAR(50),
		@VHOJA_RUTA_ID	VARCHAR(50),
		@VFECHA			DATETIME,
		@VOBSERVACION	VARCHAR(400),
		@VADJUNTO		VARCHAR(100),
		@VADJUNTO_ANT	VARCHAR(100),
		@VTAB_AGENDA	VARCHAR(50),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
DECLARE @VTMT_OBSERVACION	VARCHAR(400),
		@VTMT_FECHA			DATETIME,
		@VSTRUCTURE			VARCHAR(100)
 
BEGIN	
 
	SELECT	@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VTAB_AGENDA	= ISNULL(TAB_AGENDA,''),
			@VMINUTA		= ISNULL(ID_MINUTA,''),
			@VHOJA_RUTA_ID	= ISNULL(HOJA_RUTA_ID,''),
			@VTMT_FECHA		= ISNULL(CONS_FECHA_MC,''),
			@VTMT_OBSERVACION = ISNULL(CONS_OBSERV_MC,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VTAB_AGENDA <> '4') BEGIN
		SET @VSTRUCTURE = '40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5' --MINUTA DE CIERRE
	END ELSE BEGIN
		SET @VSTRUCTURE = 'D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5' --MINUTA DE VISITA
		SET @VMINUTA = @VHOJA_RUTA_ID
	END
 
	IF (@VMINUTA <> '') BEGIN
 
		SELECT	@VFECHA = ISNULL(FECHA_DOCUM,''),
				@VOBSERVACION = ISNULL(OBSERVACIONES,'')
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_PROYECTO_DOCUM = @VMINUTA
 
		SELECT	@VADJUNTO_ANT = ISNULL(ID_ADJUNTO,'')
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_PROYECTO_DOCUM = @VMINUTA
	END
 
	SELECT	@VADJUNTO = ISNULL(PKEY,'')
	FROM	PHYSICAL_ATTACHED_DOCUMENT
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	SELECT	@VTIPO_SERV = ID_TIPO_SERVICIO,
			@VNOMBRE = ISNULL(NOMBRE,''),
			@VLUGAR = ISNULL(LUGAR,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
	SELECT	@VDIAS_AGENDA = DIAS,
			@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END
	FROM	LK_AGENDA A
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	IF (@VMINUTA <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_FECHA		  = @VFECHA
		SET @VTMT_OBSERVACION = @VOBSERVACION
	END
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="'+CASE WHEN @VTAB_AGENDA = '4' THEN 'fas fa-paperclip' ELSE 'fas fa-archive' END +' w3-large"></i>&nbsp;&nbsp;'+CASE WHEN @VTAB_AGENDA = '4' THEN 'Minuta de Visita' ELSE 'Minuta de Cierre' END+'</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '		
				<div class="w3-row-padding">'+
					CASE WHEN @VMINUTA = '' THEN
						'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Minuta</b></span>'
					ELSE
						'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Minuta</b></span>'
					END + '
					<div class="w3-row w3-bottombar"></div>
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VRAZON_SOCIAL,'')+'</b>&nbsp;'+'
							<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+'</b>&nbsp;'+'
							<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN 
										'fas fa-user-tie"'
									WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN 
										'fas fa-chalkboard-teacher"'
									WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN 
										'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE,'')+' - '+ISNULL(@VLUGAR,'')+'</b>
						</span>
					</div>' +
					CASE WHEN (@VTAB_AGENDA <> '4') THEN '' ELSE
					'<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
						</span>
					</div>' END + '
					<div class="w3-panel w3-bottombar"></div>
					<div>
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-alt"></i>&nbsp;&nbsp;Fecha&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
                        <input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.CONS_FECHA_MC" value="'+CASE WHEN ISNULL(@VTMT_FECHA,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA,23),'') END +'">
					</div>
					<div>
						&nbsp;
					</div>
					<div>
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CONS_OBSERV_MC" value="'+ISNULL(@VTMT_OBSERVACION,'')+'">
					</div>
					<div class="w3-container" style="padding:2px;"></div>
					<div class="w3-panel w3-bottombar"></div>'
 
--<textarea class="w3-input w3-border w3-round" maxlength="4000" name="SP.CONS_OBSERV_MC" value="'+ISNULL(@VTMT_OBSERVACION,'')+'"></textarea>
	SET @OFOOTER = '
	<div class="w3-card">
		   <div class="w3-col w3-container w3-muhle-text-14 w3-muhle-color"><p><b>Adjuntar Minuta</b></p></div>
		   <input class=""w3-input w3-border"" id="'+@FORM_ID+'_fileupload" type="file" name="files[]">
	
			<div id="progressdiv" class="w3-light-grey" style="display:none;">
				<div id="progressbar" class="w3-container w3-green w3-center" style="width:0%"></div>
			</div>
			<div id="'+@FORM_ID+'_attached_files"></div><script>initAttachFiles(''' + @FORM_ID + ''',''' + isnull(@IPKEYJOB,'') + ''')</script>
	</div>	
	<div class="w3-panel w3-topbar"></div>'+
	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
		'<div class="w3-container" style="padding:8px;"></div>'
	ELSE 
		'<div class="w3-panel w3-pale-red" style="height: 20px;">
			<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
			</div>' 
	END + '
		<div class="w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VMINUTA = '' THEN 'Agregar' ELSE 'Grabar' END +'</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''','''+@VSTRUCTURE+''');return false;">Cancelar</btn>		
		</div>
	      </div>
        </div>
    </div>'
 
	UPDATE	XAGENDA
	SET		ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
	
END
