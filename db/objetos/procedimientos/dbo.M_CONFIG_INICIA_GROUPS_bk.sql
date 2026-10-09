CREATE   PROCEDURE [dbo].[M_CONFIG_INICIA_GROUPS_bk]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100),
 @PS_TITULO AS VARCHAR(MAX) OUTPUT,
 @PS_FORMULARIO AS VARCHAR(MAX) OUTPUT)
AS
 
	DECLARE @VPERFIL_TMT	VARCHAR(50),
			@VNOMBRE_TMT	VARCHAR(100),
			@VDESC_ERROR	VARCHAR(4000),
			@ID_GROUP_SEL	VARCHAR(50)
 
BEGIN	
	
	SELECT	@VNOMBRE_TMT	= ISNULL(NEW_NAME,''),
			@VPERFIL_TMT	= ISNULL(NEW_ID,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@ID_GROUP_SEL	= ISNULL(ID_GROUP_SEL,'')
	FROM	M_CONFIG
	WHERE	PAR_KEY = @IPKEYJOB
 
 
	IF (@ID_GROUP_SEL <> '' AND @VDESC_ERROR = '') BEGIN
 
		SELECT	@VPERFIL_TMT	= ID, 
				@VNOMBRE_TMT	= NAME
		FROM	Groups 
		WHERE	Id = @ID_GROUP_SEL;
		
	END	
----TOP CONTAINER----
	SET @PS_TITULO = '<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-color w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-users w3-large"></i>&nbsp;&nbsp;Perfiles</span>
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
			CASE WHEN @ID_GROUP_SEL = '' THEN 
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Perfil</b></span>'
			ELSE
				'<span class="w3-muhle-text-20 w3-left w3-padding"><b>Modificar Perfil</b></span>'
			END + '			<div class="w3-row w3-bottombar"></div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Id&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NEW_ID" value="' + CASE WHEN @ID_GROUP_SEL <> '' THEN @ID_GROUP_SEL ELSE isnull(@VPERFIL_TMT,'') END +'" ' + CASE WHEN @ID_GROUP_SEL <> '' THEN 'disabled' ELSE '' END + '>
				</div>
			</div>
			<div class="w3-row">
				<div class="w3-half w3-padding">
					<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Perfil&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
					<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.NEW_NAME" value="' + @VNOMBRE_TMT + '">
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
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">'+CASE WHEN @ID_GROUP_SEL = '' THEN 'Agregar' ELSE 'Grabar' END +'</btn>
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''21B6894B-27A5-4A5F-9CA9-BFD807276E9C'');return false;">Cancelar</btn>
			</div>
	</div>
		</div>
	</div>
</div>'
 
END
