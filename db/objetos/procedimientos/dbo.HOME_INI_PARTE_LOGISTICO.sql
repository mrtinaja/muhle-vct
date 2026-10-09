CREATE PROCEDURE [dbo].[HOME_INI_PARTE_LOGISTICO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER2	AS VARCHAR(MAX) OUTPUT)
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
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(100),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VESTADO	VARCHAR(100),
		@VARNORMA	VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VTIPO			VARCHAR(50),
		@VCANT_HR		INT,
		@VSTATUS		VARCHAR(50),
		@VHORAS			VARCHAR(50),
		@CONSULTOR_SEL	VARCHAR(100),
		@OBS			VARCHAR(400),
		@LISTA			VARCHAR(400),
		@DESC_ENVIO		VARCHAR(400),
		@CORRESPONDE	VARCHAR(50),
		@POWER_POINT	VARCHAR(50)
 
BEGIN	
 
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@CONSULTOR_SEL	= ISNULL(CONSULTOR_PROV,''),
			@OBS			= ISNULL(OBSERVACIONES_PL,''),
			@LISTA			= ISNULL(LISTA_MATERIAL_PL,''),
			@DESC_ENVIO		= ISNULL(DESC_ENVIO_PL,''),
			@CORRESPONDE	= ISNULL(CORRESPONDE_MAT_PL,''),
			@POWER_POINT	= ISNULL(POWER_POINT_PL,'')
	FROM	XAGENDA
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
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		CORRESPONDE_MAT_PL = NULL,
				POWER_POINT_PL = NULL,
				LISTA_MATERIAL_PL = NULL,
				DESC_ENVIO_PL = NULL,
				OBSERVACIONES_PL = NULL,
				CONSULTOR_PROV = NULL,
				ERROR='SI'
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	IF ISNULL(@CONSULTOR_SEL,'')<>'' 
		BEGIN
			SET @OBS = dbo.FN_GET_OBSERVACIONES(@VAGENDA_ID, @CONSULTOR_SEL)
 
			--ACA SE ACTUALIZA LAS OBSERVACIONES SEGUN PROVEEDOR; POR AHORA SOLO HOTELES
			UPDATE	XAGENDA
			SET		OBSERVACIONES_PL = @OBS
			WHERE	PAR_KEY = @IPKEYJOB
 
		END
	
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-clipboard-list w3-large"></i>&nbsp;&nbsp;Generar Parte Logístico</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
 
	<div class="w3-panel w3-topbar"></div>
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
	</div>
	<div class="w3-panel">
		<span class="w3-bar-item w3-right w3-muhle-text-14">
			<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
			<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
			<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
		</span>
	</div>
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-container" style="padding:2px;"></div>
	<div class="w3-row-padding">
		<div class="w3-half">
			<label class="w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;Consultor&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
			<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.CONSULTOR_PROV"></select>
		</div>
	</div>
	<div class="w3-panel w3-topbar"></div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '8C9377AF-4074-42E0-B353-BCC33DB04051' + ''', ''' + ISNULL(@CONSULTOR_SEL,'') +''', '''');</script>'
 
	SET @OFOOTER = '	
	<div class="w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Siguiente</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;">Cancelar</btn>		
		</div>'
 
	
	SET @OFOOTER2 = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-clipboard-list w3-large"></i>&nbsp;&nbsp;Generar Parte Logístico</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
	<div class="w3-panel w3-topbar"></div>
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
	</div>
	<div class="w3-panel">
		<span class="w3-bar-item w3-right w3-muhle-text-14">
			<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
			<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
			<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
		</span>
	</div>
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-container" style="padding:2px;"></div>
	<div class="w3-row-padding">
		<div>
			<label class="w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;Consultor</label>
			<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.CONSULTOR_PROV" disabled></select>
		</div>
		<div>
			&nbsp;
		</div>
		<div>
			<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
			<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESC_ENVIO_PL" value="' + ISNULL(@DESC_ENVIO,'') + '">
		</div>
		<div>
			&nbsp;
		</div>
		<div>
			<label class="w3-muhle-text-14">&nbsp;<i class="fa fa-address-card"></i>&nbsp;&nbsp;Datos Proveedores</label>
			<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="textarea" name="SP.OBSERVACIONES_PL" value="' + ISNULL(@OBS,'') + '">
		</div>
	</div>
	<div class="w3-panel w3-topbar"></div>
			</div>
        </div>
    </div>
	<div class="w3-padding">
		<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Siguiente</btn>
		<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');return false;">Cancelar</btn>		
	</div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '8C9377AF-4074-42E0-B353-BCC33DB04051' + ''', ''' + ISNULL(@CONSULTOR_SEL,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb5'', ''' + '0000000004_98' + ''', ''' + ISNULL(@CORRESPONDE,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb6'', ''' + '0000000004_98' + ''', ''' + ISNULL(@POWER_POINT,'') +''', '''');</script>'
 
END
