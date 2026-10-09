CREATE PROCEDURE [dbo].[HOME_INI_RENDICION_VIATICOS]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
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
		@VHORAS		VARCHAR(50),
		@CONSULTOR_SEL VARCHAR(100),
		@OBS VARCHAR(400)
 
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
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-file-invoice-dollar w3-large"></i>&nbsp;&nbsp;Generar Rendición Viáticos</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
				<div class="w3-padding">
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
	      
						<div id="table1" class="w3-container w3-border"></div>
						<script>
							BuildAjaxSPTable(''table1'', ''HOME_GRD_RENDICIONES'', '''+@FORM_ID+''');
						</script>
						<div class="w3-panel w3-topbar"></div>
				</div>
	      </div>
        </div>
    </div>'
		
	SET @OFOOTER = '
				<div class="w3-padding">
					<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="saveValues(''ACUMULA_VIATICO'');next('''+@FORM_ID+''');return false;">Generar</btn>
					<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;">Cancelar</btn>		
				</div>'
 
	--SET @OFOOTER = '
	--		</div>
	--	</div>
	--</div>'
	--<div class="w3-container" style="padding:4px;"></div>
	--	<div class="w3-panel w3-topbar"></div>
	--	<div class="w3-panel">
	--		<span class="w3-bar-item w3-right w3-muhle-text-14">
	--			<i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VRAZON_SOCIAL,'')+'</b>&nbsp;'+'
	--			<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+'</b>&nbsp;'+'
	--			<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN 
	--						'fas fa-user-tie"'
	--					WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN 
	--						'fas fa-chalkboard-teacher"'
	--					WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN 
	--						'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE,'')+' - '+ISNULL(@VLUGAR,'')+'</b>
	--		</span>
	--	</div>
	--	<div class="w3-panel">
	--		<span class="w3-bar-item w3-right w3-muhle-text-14">
	--			<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
	--			<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
	--			<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
	--		</span>
	--	</div>
	--	<div class="w3-panel w3-topbar"></div>
	--	<div class="w3-container" style="padding:2px;"></div>
	      
	--	<div id="table1" class="w3-container w3-border"></div>
	--	<script>
	--		BuildAjaxSPTable(''table1'', ''HOME_GRD_RENDICIONES'', '''+@FORM_ID+''');
	--	</script>
END
