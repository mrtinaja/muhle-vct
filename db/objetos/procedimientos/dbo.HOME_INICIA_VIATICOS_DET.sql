CREATE PROCEDURE [dbo].[HOME_INICIA_VIATICOS_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT
 )
AS
 
DECLARE	@VID			VARCHAR(50),
		@VSERVICIO		VARCHAR(100),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VPROYECTO		VARCHAR(300),
		@VCLIENTE		VARCHAR(300),
		@VIDCLIENTE		VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VFECHA			VARCHAR(50),
		@VDIASP			VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VERROR			VARCHAR(50),
		@VID_VIATICO	VARCHAR(50),
		@VARNORMA		VARCHAR(400),
		@lstDato		VARCHAR(100), 
		@lnuPosComa		INT,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VID_SERVICIO	INT,
		@VID_PROYECTO	INT,
		@VESTADO		VARCHAR(100),
		@VFECHAD		VARCHAR(50),
		@VFECHAH		VARCHAR(50),
		@VDIAS			VARCHAR(50),
		@VTIPO_PROV		VARCHAR(50),
		@VHOTEL			VARCHAR(300),
		@VPROYECTO_SERV	VARCHAR(50),
		@VNOMBRE		VARCHAR(300),
		@VHORAS			VARCHAR(50),
		@VRAZON_SOCIAL	VARCHAR(400),
		@VNOMBRE_PROY	VARCHAR(400),
		@VTIPO_SERV		VARCHAR(50),
		@VLUGAR			VARCHAR(400),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
BEGIN
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VID_VIATICO = ISNULL(HOJA_RUTA_ID,''),
			@VCLIENTE = ISNULL(CLIENTE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VTIPO_PROV = TIPO_PROVEEDOR,
			@VHOTEL = ISNULL(P.RAZON_SOCIAL_PROV,V.DESCRIP_SERVICIO)
	FROM	LK_PROYECTO_VIATICOS V
			LEFT JOIN LK_PROVEEDORES P ON P.ID_PROVEEDOR = V.ID_PROVEEDOR	
	WHERE	ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	SELECT	@VID_PROYECTO  = ID_PROYECTO,
			@VID_SERVICIO  = ID_SERVICIO,
			@VPROYECTO_SERV = PROYECTO_SERV_ID
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
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	SELECT	@VDIAS_AGENDA = DIAS,
			@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END
	FROM	LK_AGENDA A
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-money-check-alt w3-large"></i>&nbsp;&nbsp;Ver Detalle Viático</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>Detalle Viático - '+ISNULL(@VTIPO_PROV,'')+'</b></span>
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
					<div class="w3-panel">
						<span class="w3-bar-item w3-right w3-muhle-text-14">
							<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
							<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
						</span>
					</div>
					<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
					<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Agregar Detalle Viático" onclick="goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');return false;"><i class="fa fa-plus"></i></button>
				<div>
			</div>
        </div>
    </div>
	<hr style="padding:2px;height:1px;border-width:0;color:gray;background-color:gray;">'
 
	SET @OFOOTER = ''
 
	UPDATE	XAGENDA
	SET		ID_DETALLE = NULL,
			DET_PROV_RESERVA = NULL,
			DET_PROV_FECHA = NULL,
			DET_PROV_VUELO = NULL,
			DET_PROV_ORIGEN = NULL,
			DET_PROV_DESTINO = NULL,
			DET_PROV_SALIDA = NULL,
			DET_PROV_LLEGADA = NULL,
			DET_PROV_LOCAL = NULL,
			DET_PROV_FINGRESO = NULL,
			DET_PROV_FEGRESO = NULL,
			DET_PROV_FPARTIDA = NULL,
			DET_PROV_FLLEGADA = NULL,
			PAGA_CONSULTOR = NULL,
			PAGA_CONSULTORA = NULL,
			RENDICION_CLIENTE = NULL,
			DET_PROV_KMS = NULL,
			DET_PROV_PEAJES = NULL,
			TIPO_PROV = @VTIPO_PROV,
			DESCRIP_SERVICIO_PROV = ISNULL(@VHOTEL,DESCRIP_SERVICIO_PROV),
			ERROR = NULL,
			DESC_ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
	
END
