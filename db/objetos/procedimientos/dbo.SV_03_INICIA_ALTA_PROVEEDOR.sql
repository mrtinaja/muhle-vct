CREATE PROCEDURE [dbo].[SV_03_INICIA_ALTA_PROVEEDOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @PS_TITULO		AS VARCHAR(MAX) OUTPUT,
 @PS_FORMULARIO  AS VARCHAR(MAX) OUTPUT,
 @PS_FORMU_FOOT  AS VARCHAR(MAX) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
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
		@VTIPO_PROVEEDOR	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VOBSERVACIONES	VARCHAR(400),
		@VERROR			VARCHAR(50),
		@VCLAVE			VARCHAR(100),
		@VCUIT_TMT			VARCHAR(50),
		@VRAZON_SOCIAL_TMT	VARCHAR(300),
		@VCALLE_TMT			VARCHAR(100),
		@VNRO_TMT			VARCHAR(30),
		@VPISO_TMT			VARCHAR(30),
		@VLOCALIDAD_TMT		VARCHAR(100),
		@VPROVINCIA_TMT		VARCHAR(50),
		@VTELEFONO1_TMT		VARCHAR(100),
		@VTELEFONO2_TMT		VARCHAR(100),
		@VEMAIL_TMT			VARCHAR(100),
		@VIVA_TMT			VARCHAR(50),
		@VTIPO_PROVEEDOR_TMT	VARCHAR(50),
		@VESTADO_TMT		VARCHAR(50),
		@VOBSERVACIONES_TMT	VARCHAR(400)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	SELECT	@VCLAVE = ISNULL(CLAVE,''),
			@VCUIT_TMT = ISNULL(CUIT,''),
			@VRAZON_SOCIAL_TMT	= ISNULL(RAZON_SOCIAL,''),
			@VCALLE_TMT = ISNULL(CALLE,''),
			@VNRO_TMT = ISNULL(NRO,''),
			@VPISO_TMT = ISNULL(PISO,''),
			@VLOCALIDAD_TMT = ISNULL(LOCALIDAD,''),
			@VPROVINCIA_TMT = ISNULL(PROVINCIA,''),
			@VTELEFONO1_TMT = ISNULL(TELEFONO1,''),
			@VTELEFONO2_TMT = ISNULL(TELEFONO2,''),
			@VEMAIL_TMT = ISNULL(EMAIL,''),
			@VIVA_TMT = ISNULL(IVA,''),
			@VTIPO_PROVEEDOR_TMT = ISNULL(TIPO_PROVEEDOR,''),
			@VESTADO_TMT = ISNULL(ESTADO,''),
			@VOBSERVACIONES_TMT = ISNULL(OBSERVACIONES,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_03
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF @VERROR = '' BEGIN 
		UPDATE	TMT_SV_03
		SET		ERROR = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
	
	IF @VCLAVE <> '' BEGIN
		IF @VERROR = '' BEGIN
				SELECT	@VCUIT = ISNULL(CUIT_PROV,''),
						@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_PROV,''),
						@VCALLE = ISNULL(CALLE_PROV,''),
						@VNRO = ISNULL(NRO_CALLE_PROV,''),
						@VPISO = ISNULL(PISO_DEPTO_PROV,''),
						@VLOCALIDAD = ISNULL(LOCALIDAD_PROV,''),
						@VPROVINCIA = ISNULL(PROVINCIA_PROV,''),
						@VTELEFONO1 = ISNULL(TEL1_PROV,''),
						@VTELEFONO2 = ISNULL(TEL2_PROV,''),
						@VEMAIL = ISNULL(EMAIL_PROV,''),
						@VIVA = ISNULL(IVA_PROV,''),
						@VTIPO_PROVEEDOR = ISNULL(TIPO_PROV,''),
						@VESTADO = ISNULL(STATUS_PROV,''),
						@VOBSERVACIONES = ISNULL(OBSERV_PROV,'')
				FROM	LK_PROVEEDORES
				WHERE	ID_PROVEEDOR = @VCLAVE
 
				SET @VCUIT_TMT = @VCUIT
				SET @VRAZON_SOCIAL_TMT	= @VRAZON_SOCIAL
				SET @VCALLE_TMT = @VCALLE
				SET @VNRO_TMT = @VNRO
				SET @VPISO_TMT = @VPISO
				SET @VLOCALIDAD_TMT = @VLOCALIDAD
				SET @VPROVINCIA_TMT = @VPROVINCIA
				SET @VTELEFONO1_TMT = @VTELEFONO1
				SET @VTELEFONO2_TMT = @VTELEFONO2
				SET @VEMAIL_TMT = @VEMAIL
				SET @VIVA_TMT = @VIVA
				SET @VTIPO_PROVEEDOR_TMT = @VTIPO_PROVEEDOR
				SET @VESTADO_TMT = @VESTADO
				SET @VOBSERVACIONES_TMT = @VOBSERVACIONES
		END 
	END
 
	----TOP CONTAINER----
	SET @PS_TITULO = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-address-card w3-large"></i>&nbsp;&nbsp;Proveedores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''F7CB8283-07A6-479F-8FD1-334AE1670B1D'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
 ----FOOT CONTAINER----
	SET @PS_FORMULARIO = '
		<div class="w3-row-padding">'+
			CASE WHEN @VCLAVE = '' THEN 
				--'<h4><b>Nuevo Cliente</b></h4>'
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Proveedor</b></span>'
			ELSE
				--'<h4><b>Modificar Cliente</b></h4>'
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Proveedor</b></span>'
			END + '
			<div class="w3-row w3-bottombar"></div>
			<div class="w3-threequarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-trademark"></i>&nbsp;&nbsp;Razón Social&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.RAZON_SOCIAL" value="' + @VRAZON_SOCIAL_TMT + '">
			</div>
			<div class="w3-quarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-id-card"></i>&nbsp;&nbsp;Cuit&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CUIT" value="' + @VCUIT_TMT + '">
			</div>
			<div class="w3-half w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-home"></i>&nbsp;&nbsp;Calle</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.CALLE" value="' + @VCALLE_TMT + '">
			</div>
			<div class="w3-quarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map-pin"></i>&nbsp;&nbsp;Nro</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NRO" value="' + @VNRO_TMT + '">
			</div>
			<div class="w3-quarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-building"></i>&nbsp;&nbsp;Piso</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.PISO" value="' + @VPISO_TMT + '">
			</div>
			<div class="w3-half w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map"></i>&nbsp;&nbsp;Localidad&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.LOCALIDAD" value="' + @VLOCALIDAD_TMT + '">
			</div>
			<div class="w3-half w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Provincia</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.PROVINCIA"></select>
			</div>
			<div class="w3-quarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-phone"></i>&nbsp;&nbsp;Teléfono 1</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.TELEFONO1" value="' + @VTELEFONO1_TMT + '">
			</div>
			<div class="w3-quarter w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-mobile-alt"></i>&nbsp;&nbsp;Teléfono 2</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.TELEFONO2" value="' + @VTELEFONO2_TMT + '">
			</div>
			<div class="w3-half w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-envelope"></i>&nbsp;&nbsp;Email</label>
				<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.EMAIL" value="' + @VEMAIL_TMT + '">
			</div>							
			<div class="w3-third w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-file-invoice-dollar"></i>&nbsp;&nbsp;Situación Iva</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.IVA"></select>
			</div>
			<div class="w3-third w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Tipo Proveedor</label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb3" name="SP.TIPO_PROVEEDOR"></select>
			</div>	
			<div class="w3-third w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
				<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb4" name="SP.ESTADO"></select>
			</div>
			<div class="w3-padding">
				<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
				<textarea class="w3-input w3-border w3-round w3-muhle-text-14" maxlength="4000" rows="5" cols="50" name="SP.OBSERVACIONES">' + @VOBSERVACIONES_TMT + '</textarea>
			</div>
			<div>&nbsp;</div>
		</div>
	<div class="w3-row w3-topbar">
		&nbsp;
	</div>'
 
SET @PS_FORMU_FOOT = '<div class="w3-row">
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @VCLAVE = '' THEN 'Agregar' ELSE 'Grabar' END +'</btn>
							<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''7F1FE7CB-3A2E-4F6B-B54B-B074C41E8603'');return false;">Cancelar</btn>
						</div>
					 </div>
		</div>
	</div>
</div>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '0000000124_98' + ''', ''' + ISNULL(@VPROVINCIA_TMT,'') +''', '''');</script>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + '0000000003_98' + ''', ''' + ISNULL(@VIVA_TMT,'') +''', '''');</script>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb3'', ''' + 'CBE764F0-948C-4604-84CB-7CA9A48D4E07' + ''', ''' + ISNULL(@VTIPO_PROVEEDOR_TMT,'') +''', '''');</script>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb4'', ''' + '78FF2D5A-0B70-4854-A931-6D7F026748EA' + ''', ''' + ISNULL(@VESTADO_TMT,'') +''', '''');</script>'
 
END
