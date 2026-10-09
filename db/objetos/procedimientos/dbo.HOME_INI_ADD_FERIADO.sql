 
CREATE PROCEDURE [dbo].[HOME_INI_ADD_FERIADO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT)
AS
 
DECLARE @UNITDESC	AS VARCHAR(300),
		@USERDESC	AS VARCHAR(300),
		@VFECHA		AS VARCHAR(100),
		@VDESCRIPT	AS VARCHAR(300),
		@VT_FERIADO	AS VARCHAR(50),
		@VDESC_ERROR AS VARCHAR(4000)
 
BEGIN	
 
	SELECT	@VFECHA = ISNULL(FECHA_SELEC,''),
			@VDESCRIPT	= ISNULL(DESCRIP_FERIADO,''),
			@VT_FERIADO = ISNULL(TIPO_FERIADO,''),
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-calendar-alt w3-large"></i>&nbsp;&nbsp;Agenda General</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="almacenarSeleccion(''FECHA_SELEC'','''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round">
					<div class="w3-row-padding">
						<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Feriado</b></span>
						<div class="w3-row w3-bottombar"></div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Feriado</label>
							<input class="w3-input w3-round w3-border w3-muhle-text-12" type="date" name="SP.FECHA_FERIADO" value="' + @VFECHA + '" disabled>
						</div>
						<div class="w3-col m6 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripción&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<input class="w3-input w3-round w3-border w3-muhle-text-12" type="text" name="SP.DESCRIP_FERIADO" value="' + @VDESCRIPT + '">
						</div>
						<div class="w3-col m3 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Tipo Feriado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
							<select class="w3-input w3-round w3-border w3-muhle-text-12" name="SP.TIPO_FERIADO" value="' + @VT_FERIADO + '">
									<option value=""></option>
									<option value="1" '+CASE WHEN @VT_FERIADO = '1' THEN 'selected' ELSE '' END+'>Fijo</option>
									<option value="2" '+CASE WHEN @VT_FERIADO = '2' THEN 'selected' ELSE '' END+'>Movible</option>
							</select>
						</div>
						<div>&nbsp;</div>
						<div class="w3-row w3-topbar"></div>
						<div class="w3-row">
							<div class="w3-container w3-padding">'+
								CASE WHEN isnull(@VDESC_ERROR,'') <> '' THEN
									'<div class="w3-panel w3-pale-red" style="height: 20px;">
										<span class="w3-muhle-text-12"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
									</div>'
								ELSE 
									'<div>&nbsp;</div>'
								END + '
								<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Agregar</btn>
								<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="almacenarSeleccion(''FECHA_SELEC'','''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;">Cancelar</btn>
							</div>	
						</div>
					</div>
				</div>
			</div>
	</div>'
 
--	<div class="w3-col w3-padding-large">
--		<div class="w3-card-4 w3-round">
--			<div class="w3-container w3-padding-16 w3-round" style="background-color:light-gray;">
--				<div class="w3-row w3-bottombar"></div>
--					<form class="w3-container" style="background-color:light-gray;">
--						<div class="w3-row-padding"><h4><b>Agregar Feriado</b></h4>
--							<div class="w3-quarter">
--								<label>&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Feriado</label>
--								<input class="w3-input w3-border w3-round" type="date" name="SP.FECHA_FERIADO" value="' + @VFECHA + '" disabled>
--							</div>
--							<div class="w3-half">
--								<label>&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripción&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
--								<input class="w3-input w3-border w3-round" type="text" name="SP.DESCRIP_FERIADO" value="' + @VDESCRIPT + '">
--							</div>
--							<div class="w3-quarter">
--								<label>&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Tipo Feriado&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
--								<select class="w3-input w3-border w3-round" name="SP.TIPO_FERIADO" value="' + @VT_FERIADO + '">
--									<option value=""></option>
--									<option value="1" '+CASE WHEN @VT_FERIADO = '1' THEN 'selected' ELSE '' END+'>Fijo</option>
--									<option value="2" '+CASE WHEN @VT_FERIADO = '2' THEN 'selected' ELSE '' END+'>Movible</option>
--								</select>
--							</div>
--						</div>
--					</form>
--			<div>&nbsp;</div>
--		<div class="w3-row w3-topbar"></div>
--		<div class="w3-row">
--			<div class="w3-container">'+
--				CASE WHEN isnull(@VDESC_ERROR,'') <> '' THEN
--					'<div class="w3-panel w3-pale-red" style="height: 20px;">
--						<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#641E16"><b>'+isnull(@VDESC_ERROR,'')+'</b></font>
--					</div>'
--				ELSE 
--					'<div>&nbsp;</div>'
--				END + '	
--				<button onclick="almacenarSeleccion(''FECHA_SELEC'','''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');return false;" class="w3-button w3-round" style="background-color:#641E16;color:white;">Cancelar</button>
--				<button onclick="next('''+@FORM_ID+''');return false;" class="w3-button w3-round" style="background-color:#641E16;color:white;">Guardar</button>
--			</div>
--		</div>
--	</div>
--</div>'
 
END
 
