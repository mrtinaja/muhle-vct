CREATE PROCEDURE [dbo].[HOME_INI_ADD_VIATICO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFORMULARIO AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
AS
 
/*DATOS FORMULARIO*/
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
		@VID_AGENDA_SELEC	VARCHAR(100),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
DECLARE	@VID_SELEC			VARCHAR(100),
		@VOPTIONS_TIPO		VARCHAR(MAX)
 
DECLARE @VTMT_PROVEEDOR_ID			VARCHAR(50),
		@VTMT_TIPO_PROV				VARCHAR(50),
		@VTMT_NRO_FACTURA_PROV		VARCHAR(50),
		@VTMT_DESCRIP_SERVICIO_PROV	VARCHAR(100),
		@VTMT_FECHA_FACTURA_PROV	DATETIME,
		@VTMT_PRECIO_FINAL_PROV		NUMERIC(12,2),
		@VTMT_FORMA_PAGO_PROV		VARCHAR(50),
		@VTMT_CANT_CUOTAS_PROV		VARCHAR(50),
		@VTMT_FECHA_DESDE_SERV_PROV	DATETIME,
		@VTMT_FECHA_HASTA_SERV_PROV	DATETIME,
		@VTMT_TIPO_CONSULTOR		VARCHAR(50),
		@VTMT_CONSULTOR				VARCHAR(50),
		@VTMT_DESC_PAGO				VARCHAR(300)
 
DECLARE @VPROVEEDOR_ID				VARCHAR(50),
		@VTIPO_PROV					VARCHAR(50),
		@VNRO_FACTURA_PROV			VARCHAR(50),
		@VDESCRIP_SERVICIO_PROV		VARCHAR(100),
		@VFECHA_FACTURA_PROV		DATETIME,
		@VPRECIO_FINAL_PROV			NUMERIC(12,2),
		@VFORMA_PAGO_PROV			VARCHAR(50),
		@VCANT_CUOTAS_PROV			VARCHAR(50),
		@VFECHA_DESDE_SERV_PROV		DATETIME,
		@VFECHA_HASTA_SERV_PROV		DATETIME,
		@VTIPO_CONSULTOR			VARCHAR(50),
		@VCONSULTOR					VARCHAR(50),
		@VDESC_PAGO					VARCHAR(300)
 
 
BEGIN	
 
	SELECT	@VCLIENTE				= ISNULL(CLIENTE,''),
			@VID_PROYECTO			= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO			= ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA_SELEC		= ISNULL(AGENDA_ID,''),
			@VERROR					= ISNULL(ERROR,''),
			@VDESC_ERROR			= ISNULL(DESC_ERROR,''),
			@VID_SELEC				= ISNULL(HOJA_RUTA_ID,''),
			@VTMT_PROVEEDOR_ID		= ISNULL(PROVEEDOR_ID,''),
			@VTMT_TIPO_PROV			= ISNULL(TIPO_PROV,''),
			@VTMT_NRO_FACTURA_PROV	= ISNULL(NRO_FACTURA_PROV,''),
			@VTMT_DESCRIP_SERVICIO_PROV = ISNULL(DESCRIP_SERVICIO_PROV,''),
			@VTMT_FECHA_FACTURA_PROV	= NULLIF(ISNULL(FECHA_FACTURA_PROV,''),''),
			@VTMT_PRECIO_FINAL_PROV		= ISNULL(PRECIO_FINAL_PROV,0),
			@VTMT_FORMA_PAGO_PROV		= ISNULL(FORMA_PAGO_PROV,''),
			@VTMT_CANT_CUOTAS_PROV		= ISNULL(CANT_CUOTAS_PROV,''),
			@VTMT_FECHA_DESDE_SERV_PROV = ISNULL(FECHA_DESDE_SERV_PROV,''),
			@VTMT_FECHA_HASTA_SERV_PROV	= ISNULL(FECHA_HASTA_SERV_PROV,''),
			@VTMT_TIPO_CONSULTOR		= ISNULL(TIPO_CONSULTOR_PROV,''),
			@VTMT_CONSULTOR				= ISNULL(CONSULTOR_PROV,''),
			@VTMT_DESC_PAGO				= ISNULL(DESC_FORMA_PAGO_PROV,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
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
	WHERE	ID_AGENDA = @VID_AGENDA_SELEC
 
	--Recupera infomacion desde la base para actualizacion.
	IF (@VID_SELEC <> '') BEGIN
		
		SELECT	@VPROVEEDOR_ID		= ISNULL(ID_PROVEEDOR,''),
				@VTIPO_PROV			= ISNULL(TIPO_PROVEEDOR,''),
				@VNRO_FACTURA_PROV	= ISNULL(NRO_FC,''),
				@VDESCRIP_SERVICIO_PROV = ISNULL(DESCRIP_SERVICIO,''),
				@VFECHA_FACTURA_PROV	= NULLIF(ISNULL(FECHA_FC,''),''),
				@VPRECIO_FINAL_PROV		= ISNULL(PRECIO_FINAL,0),
				@VFORMA_PAGO_PROV		= ISNULL(FORMA_PAGO,''),
				@VCANT_CUOTAS_PROV		= ISNULL(CANT_CUOTAS,''),
				@VFECHA_DESDE_SERV_PROV = ISNULL(FECHA_DESDE_SERV,''),
				@VFECHA_HASTA_SERV_PROV	= ISNULL(FECHA_HASTA_SERV,''),
				@VTIPO_CONSULTOR		= ISNULL(TIPO_CONSULTOR,''),
				@VCONSULTOR				= ISNULL(ID_CONSULTOR,''),
				@VDESC_PAGO				= ISNULL(DESC_FORMA_PAGO,'')
		FROM	LK_PROYECTO_VIATICOS
		WHERE	ID_PROYECTO_VIATICOS = @VID_SELEC
 
	END
 
	IF (@VID_SELEC <> '' AND @VDESC_ERROR = '') BEGIN
		
		SET @VTMT_PROVEEDOR_ID		= @VPROVEEDOR_ID
		SET @VTMT_TIPO_PROV			= @VTIPO_PROV
		SET @VTMT_NRO_FACTURA_PROV	= @VNRO_FACTURA_PROV
		SET @VTMT_DESCRIP_SERVICIO_PROV = @VDESCRIP_SERVICIO_PROV
		SET @VTMT_FECHA_FACTURA_PROV	= @VFECHA_FACTURA_PROV
		SET @VTMT_PRECIO_FINAL_PROV		= @VPRECIO_FINAL_PROV
		SET @VTMT_FORMA_PAGO_PROV		= @VFORMA_PAGO_PROV
		SET @VTMT_CANT_CUOTAS_PROV		= @VCANT_CUOTAS_PROV
		SET @VTMT_FECHA_DESDE_SERV_PROV = @VFECHA_DESDE_SERV_PROV
		SET @VTMT_FECHA_HASTA_SERV_PROV	= @VFECHA_HASTA_SERV_PROV
		SET @VTMT_TIPO_CONSULTOR		= @VTIPO_CONSULTOR
		SET @VTMT_CONSULTOR				= @VCONSULTOR
		SET @VTMT_DESC_PAGO				= @VDESC_PAGO
	END
 
	SET @VOPTIONS_TIPO = '<option value=""></option><option value="CONSULTOR"'+CASE WHEN isnull(@VTMT_TIPO_CONSULTOR,'') = 'CONSULTOR' THEN 'selected="selected"' ELSE '' END+'>Consultor</option><option value="OBSERVADOR" '+CASE WHEN isnull(@VTMT_TIPO_CONSULTOR,'') = 'OBSERVADOR' THEN 'selected="selected"' ELSE '' END+'>Observador</option>'
 
	----TOP CONTAINER----
	SET @OHEADER = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-money-check-alt w3-large"></i>&nbsp;&nbsp;Viáticos</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFORMULARIO = '		
				<div class="w3-row-padding">
					<span class="w3-muhle-text-20 w3-left w3-padding"><b>'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Modificar' END+' Viático</b></span>
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
					<div class="w3-quarter">
						<label class="w3-muhle-text-14"><i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Tipo Viático&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1_'+@FORM_ID+'" name="SP.TIPO_PROV" onchange="BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROVEEDORES'', '''',this.id);"></select>
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14"><i class="fa fa-address-card"></i>&nbsp;&nbsp;Proveedor&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2_'+@FORM_ID+'" name="SP.PROVEEDOR_ID"></select>
					</div>
					<div class="w3-quarter">
						<label class="w3-muhle-text-14"><i class="fas fa-user-tag"></i>&nbsp;&nbsp;Corresponde&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.TIPO_CONSULTOR_PROV">'
							+ISNULL(@VOPTIONS_TIPO,'')
						+'</select>
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14"><i class="fas fa-user"></i>&nbsp;&nbsp;Consultor&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.CONSULTOR_PROV"></select>
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripción&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESCRIP_SERVICIO_PROV" value="' + ISNULL(@VTMT_DESCRIP_SERVICIO_PROV,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Factura</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_FACTURA_PROV" value="'+CASE WHEN ISNULL(@VTMT_FECHA_FACTURA_PROV,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA_FACTURA_PROV,23),'') END +'">
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-file-invoice-dollar"></i>&nbsp;&nbsp;Nro Factura</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NRO_FACTURA_PROV" value="' + ISNULL(@VTMT_NRO_FACTURA_PROV,'') + '">
					</div>
					<div class="w3-third">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Precio Final</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number" name="SP.PRECIO_FINAL_PROV" value="' + ISNULL(CONVERT(VARCHAR,@VTMT_PRECIO_FINAL_PROV),'0') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-quarter">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-credit-card"></i>&nbsp;&nbsp;Forma de Pago</label>
						<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb5" name="SP.FORMA_PAGO_PROV"></select>
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripción Forma de Pago</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.DESC_FORMA_PAGO_PROV" value="' + ISNULL(@VTMT_DESC_PAGO,'') + '">
					</div>
					<div class="w3-quarter">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-list-ol"></i>&nbsp;&nbsp;Cuotas</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="number" name="SP.CANT_CUOTAS_PROV" value="' + ISNULL(@VTMT_CANT_CUOTAS_PROV,'') + '">
					</div>
					<div>
						&nbsp;
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde Servicio</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_DESDE_SERV_PROV" value="'+CASE WHEN ISNULL(@VTMT_FECHA_DESDE_SERV_PROV,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA_DESDE_SERV_PROV,23),'') END +'">
					</div>
					<div class="w3-half">
						<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta Servicio</label>
						<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_HASTA_SERV_PROV" value="'+CASE WHEN ISNULL(@VTMT_FECHA_HASTA_SERV_PROV,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VTMT_FECHA_HASTA_SERV_PROV,23),'') END +'">
					</div>
					<div class="w3-container" style="padding:2px;"></div><div class="w3-panel w3-bottombar"></div>'
 
	SET @OFOOTER =	CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN
						'<div class="w3-container" style="padding:8px;"></div>'
					ELSE 
						'<div class="w3-panel w3-pale-red" style="height: 20px;">
							<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
						 </div>' 
					END + '
					<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VID_SELEC = '' THEN 'Agregar' ELSE 'Grabar' END+'</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;">Cancelar</btn>
						</div>
					</div>
				</div>
			</div>
        </div>
    </div>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1_'+@FORM_ID+''', ''VW_TIPOS_VIATICOS'', '''+isnull(@VTMT_TIPO_PROV,'')+''', '''');</script>'+
	CASE WHEN ISNULL(@VTMT_TIPO_PROV,'') = '' THEN '' ELSE
		'<script>BuildAjaxSPComboWithCode('''+@FORM_ID+''',''cmb2_'+@FORM_ID+''', ''VW_PROVEEDORES'', '''+isnull(@VTMT_PROVEEDOR_ID,'')+''', '''+isnull(@VTMT_TIPO_PROV,'')+''');</script>' 
	END +'
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '8C9377AF-4074-42E0-B353-BCC33DB04051' + ''', ''' + ISNULL(@VTMT_CONSULTOR,'') +''', '''');</script>
	<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb5'', ''' + 'BDA5EFF2-F9AF-4F0A-8E11-E2CE6E5EB9BE' + ''', ''' + ISNULL(@VTMT_FORMA_PAGO_PROV,'') +''', '''');</script>'
 
END
