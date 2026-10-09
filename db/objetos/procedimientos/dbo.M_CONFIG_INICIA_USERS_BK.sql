CREATE  PROCEDURE [dbo].[M_CONFIG_INICIA_USERS_BK]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100),
 @PS_TITULO AS VARCHAR(MAX) OUTPUT,
 @PS_FORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
	DECLARE @ID_USER_SEL	VARCHAR(50),
			@VUSUARIO_TMT	VARCHAR(50),
			@VUSUARIO		VARCHAR(50),
			@VNOMBRE_TMT	VARCHAR(100),
			@VNOMBRE		VARCHAR(100),
			@VEMAIL_TMT		VARCHAR(100),
			@VEMAIL			VARCHAR(100),
			@VPASS_TMT		VARCHAR(100),
			@VPASS			VARCHAR(100),
			@VESTADO_TMT	VARCHAR(50),
			@VESTADO		INT,
			@VESTADO_CODE	VARCHAR(50),
			@VPERFIL		VARCHAR(50),
			@VPERFIL_TMT	VARCHAR(50),
			@VDESC_ERROR	VARCHAR(4000)
 
BEGIN	
	
	SELECT	@ID_USER_SEL	= ISNULL(ID_USER_SEL,''),
			@VUSUARIO_TMT	= ISNULL(NEW_ID,''),
			@VNOMBRE_TMT	= ISNULL(NEW_NAME,''),
			@VEMAIL_TMT		= ISNULL(NEW_EMAIL,''),
			@VPASS_TMT		= ISNULL(NEW_PASSWORD,''),
			@VESTADO_TMT	= ISNULL(NEW_ESTADO_CUENTA,''),
			@VPERFIL_TMT	= ISNULL(NEW_PERFIL,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,'')
	FROM	M_CONFIG
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF (@ID_USER_SEL <> '' AND @VDESC_ERROR = '') BEGIN
 
		SELECT	@VUSUARIO	= ID, 
				@VNOMBRE	= NAME,
				@VEMAIL		= Email, 
				@VPASS		= Password, 
				@VESTADO	= State
		FROM	Users 
		WHERE	Id = @ID_USER_SEL;
 
		SELECT @VESTADO_CODE=CAT_DATA_CODE FROM CAT_DATA WHERE ATTR1 = convert(varchar,@VESTADO) and PAR_KEY='3ECEABE3-13FD-4779-ADE7-CDECF2EC3992'
 
		--RECUPERO EL PERFIL DEL USUARIO
		SELECT	TOP 1 @VPERFIL = GroupId
		FROM	GroupsUserMembers
		WHERE	UserMemberId = @ID_USER_SEL
 
		SET @VUSUARIO_TMT	= @VUSUARIO
		SET @VNOMBRE_TMT	= @VNOMBRE
		SET @VEMAIL_TMT		= @VEMAIL
		SET @VPASS_TMT		= @VPASS
		SET @VESTADO_TMT	= @VESTADO_CODE
		SET @VPERFIL_TMT	= @VPERFIL
		
	END
 
	--UPDATE M_CONFIG
	--SET NEW_ID= @NEW_ID,
	--NEW_EMAIL=@NEW_EMAIL,
	--NEW_PASSWORD=@NEW_PASS,
	--NEW_NAME=@NEW_NAME,
	--NEW_ESTADO_CUENTA=@NEW_ESTADO_CUENTA
	--WHERE PAR_KEY = @IPKEYJOB;
 
 
----TOP CONTAINER----
	SET @PS_TITULO = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-color w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-user w3-large"></i>&nbsp;&nbsp;Usuarios</span>
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
			CASE WHEN @ID_USER_SEL = '' THEN 
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Usuario</b></span>'
			ELSE
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Usuario</b></span>'
			END + '
			<div class="w3-row w3-bottombar"></div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-user"></i>&nbsp;&nbsp;Usuario&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NEW_ID" value="' + CASE WHEN @ID_USER_SEL <> '' THEN @ID_USER_SEL ELSE @VUSUARIO_TMT END + '" '+CASE WHEN @ID_USER_SEL <> '' THEN 'disabled' ELSE '' END+'>
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Nombre y Apellido&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NEW_NAME" value="' + @VNOMBRE_TMT + '">
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-envelope"></i>&nbsp;&nbsp;Email</label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NEW_EMAIL" value="' + @VEMAIL_TMT + '">
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map-pin"></i>&nbsp;&nbsp;Password&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="password" name="SP.NEW_PASSWORD" value="' + @VPASS_TMT + '">
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Perfil&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.NEW_PERFIL"></select>
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.NEW_ESTADO_CUENTA"></select>
				</div>
			</div>
		</div>
	<div class="w3-row w3-topbar">'+
		CASE WHEN isnull(@VDESC_ERROR,'') = '' THEN '&nbsp;' ELSE
		'<div class="w3-panel w3-pale-red" style="height: 20px;">
			<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
		</div>' END + '
	</div>
	<div class="w3-row">
			<div class="w3-container w3-padding">
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @ID_USER_SEL = '' THEN 'Agregar' ELSE 'Grabar' END +'</btn>
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''9911B4B4-A00E-40D8-B148-A92469C268CC'');return false;">Cancelar</btn>
			</div>
	</div>
		</div>
	</div>
</div>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '3ECEABE3-13FD-4779-ADE7-CDECF2EC3992' + ''', ''' + ISNULL(@VESTADO_TMT,'') +''', '''');</script>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + 'C298D430-BFCF-4331-B088-AC5208C1575A' + ''', ''' + ISNULL(@VPERFIL_TMT,'') +''', '''');</script>'
 
END
