 
CREATE PROCEDURE [dbo].[HOME_INI_DATOS_SEGUIMIENTO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
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
 
DECLARE	@VSERVICIO	VARCHAR(50),
		@VID		VARCHAR(50),
		@VFECHA_INI	DATETIME,
		@VFECHA_FIN	DATETIME,
		@VDIAS		VARCHAR(50),
		@VMONTO		VARCHAR(50),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(50),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDIASP		VARCHAR(50),
		@VTABLA		VARCHAR(MAX),
		@VARCLIENTE	VARCHAR(300), 
		@VARPROYECTO VARCHAR(300), 
		@VARSERVICIO VARCHAR(100), 
		@VARNORMA	VARCHAR(300), 
		@VARFECHA	VARCHAR(50), 
		@VARPROFESIONAL VARCHAR(300), 
		@VAROBSERVADOR VARCHAR(300), 
		@VID_AGENDA	VARCHAR(50),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS		VARCHAR(4000),
		@VSTATUS			VARCHAR(50),
		@VID_DELETE			VARCHAR(50),
		@VTIPO				VARCHAR(50),
		@VFRECUENCIA		VARCHAR(50),
		@VDOC_EMPRESA		VARCHAR(50),
		@VMANUAL_DOC		VARCHAR(50),
		@VREQ_INGRESO		VARCHAR(50),
		@VCV_CERTIF			VARCHAR(50),
		@VLOGISTICA			VARCHAR(50),
		@VCURSO				VARCHAR(300),
		@VMATERIAL			VARCHAR(50),
		@VESTADO_ENVIO		VARCHAR(50),
		@VRECIBIDO			VARCHAR(50),
		@VTIPO_SERVICIO		VARCHAR(50),
		@VAGENDA_ID			VARCHAR(100)
 
BEGIN	
	
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	IF (@VID_SERVICIO <> '') BEGIN
		SELECT	@VFRECUENCIA = ISNULL(FRECUENCIA_ENVIO,''), 
				@VDOC_EMPRESA = ISNULL(DOC_EMPRESA,''), 
				@VMANUAL_DOC = ISNULL(MANUALES,''), 
				@VREQ_INGRESO = ISNULL(REQUISITO_INGRESO,''), 
				@VCV_CERTIF = ISNULL(CV_CERTIFICADOS,''), 
				@VLOGISTICA = ISNULL(LOGISTICA,''),
				@VCURSO = ISNULL(NOMBRE_CURSO,''), 
				@VMATERIAL = ISNULL(MATERIALES,''), 
				@VESTADO_ENVIO = ISNULL(ESTADO_ENVIO,''), 
				@VRECIBIDO = ISNULL(RECIBIDO,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
	END
 
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
		SET		AUDI_MANUAL = @VMANUAL_DOC,
				AUDI_REQ_INGRESO = @VREQ_INGRESO,
				AUDI_CV_CERTIF = @VCV_CERTIF,
				AUDI_LOGISTICA = @VLOGISTICA,
				CAPA_CURSO = @VCURSO,
				CAPA_MATERIAL = @VMATERIAL,
				CAPA_ESTADO_ENVIO = @VESTADO_ENVIO,
				CAPA_RECIBIDO = @VRECIBIDO,
				CONS_DOC_EMPRESA = @VDOC_EMPRESA,
				CONS_FRECUENCIA_PE = @VFRECUENCIA
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-shoe-prints w3-large"></i>&nbsp;&nbsp;Datos Seguimiento</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>Editar Datos</b></span>
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
					</div>
					<hr style="height:1px;border-width:0;color:gray;background-color:gray;">'+
					--<div>&nbsp;</div>
						CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN
						'<div class="w3-half">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-share-square"></i>&nbsp;&nbsp;Frecuencia de Envio Plan Estrategico</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.CONS_FRECUENCIA_PE"></select>
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-book"></i>&nbsp;&nbsp;Documentacion Empresa</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.CONS_DOC_EMPRESA"></select>
						</div>'
						WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN
						'<div class="w3-half">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-book"></i>&nbsp;&nbsp;Manual/Documentacion</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.AUDI_MANUAL"></select>
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-info"></i>&nbsp;&nbsp;Requisitos Ingreso</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.AUDI_REQ_INGRESO"></select>
						</div>
						<div>
							&nbsp;
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-certificate"></i>&nbsp;&nbsp;CV y Certificados</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb5" name="SP.AUDI_CV_CERTIF"></select>
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Logistica</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb6" name="SP.AUDI_LOGISTICA"></select>
						</div>'
					WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN
						'<div class="w3-half">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Nombre del Curso</label>
							<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CAPA_CURSO" value="' + ISNULL(@VCURSO,'') + '">
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-pen"></i>&nbsp;&nbsp;Materiales</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb7" name="SP.CAPA_MATERIAL"></select>
						</div>
						<div>
							&nbsp;
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-share-square"></i>&nbsp;&nbsp;Estado de Envio</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb8" name="SP.CAPA_ESTADO_ENVIO"></select>
						</div>
						<div class="w3-half">
							<label class="w3-muhle-text-14"><i class="fas fa-inbox"></i>&nbsp;&nbsp;Recibido</label>
							<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb9" name="SP.CAPA_RECIBIDO"></select>
						</div>'
					ELSE '' END + '
					<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>'
 
	SET @OFOOTER = CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Grabar</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + 'A840872C-537A-41DD-980B-43E48C92479B' + ''', ''' + ISNULL(@VFRECUENCIA,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VDOC_EMPRESA,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + '2C74F080-5DE7-4127-9E65-E97AB11E3A35' + ''', ''' + ISNULL(@VMANUAL_DOC,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VREQ_INGRESO,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb5'', ''' + '2C74F080-5DE7-4127-9E65-E97AB11E3A35' + ''', ''' + ISNULL(@VCV_CERTIF,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb6'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VLOGISTICA,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb7'', ''' + 'FC343E11-DEAF-4C8D-9D4A-332B856762BE' + ''', ''' + ISNULL(@VMATERIAL,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb8'', ''' + '2C74F080-5DE7-4127-9E65-E97AB11E3A35' + ''', ''' + ISNULL(@VESTADO_ENVIO,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb9'', ''' + '0000000004_98' + ''', ''' + ISNULL(@VRECIBIDO,'') +''', '''');</script>'
 
END
