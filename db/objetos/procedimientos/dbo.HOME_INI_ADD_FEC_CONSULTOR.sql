CREATE PROCEDURE [dbo].[HOME_INI_ADD_FEC_CONSULTOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @UNITDESC	AS VARCHAR(300),
		@USERDESC	AS VARCHAR(300),
		@VFECHA		AS VARCHAR(100),
		@VFECHA_HASTA AS VARCHAR(100),
		@VTIPO		AS VARCHAR(50),
		@VMOTIVO	AS VARCHAR(50),
		@VDESC_MOTIVO AS VARCHAR(400),
		@VHORAS		AS NUMERIC(5,0),
		@VDESC_ERROR AS VARCHAR(4000),
		@VCONSULTOR	 AS VARCHAR(50),
		@VDESC_CONSULTOR	 AS VARCHAR(400)
 
BEGIN	
 
	SELECT	@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			@VFECHA = ISNULL(FECHA_SELEC,''),
			@VFECHA_HASTA = ISNULL(AGENDA_FECHA,''),
			@VTIPO	= ISNULL(AGENDA_TIPO,''),
			@VMOTIVO = ISNULL(AGENDA_MOTIVO,''),
			@VDESC_MOTIVO = ISNULL(AGENDA_DESC,''),
			@VHORAS = ISNULL(AGENDA_HORAS,8),
			@VDESC_ERROR = ISNULL(DESC_ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VDESC_CONSULTOR = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO
	FROM	LK_EMPLEADOS
	WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @VCONSULTOR
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-user-clock w3-large"></i>&nbsp;&nbsp;Agenda Consultor</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="almacenarSeleccion(''FECHA_SELEC'','''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
						<div class="w3-row-padding">
							<span class="w3-muhle-text-20 w3-left w3-padding"><b>Agregar Fecha Consultor - '+ISNULL(@VDESC_CONSULTOR,'')+'</b></span>
							<div class="w3-row w3-bottombar"></div>
							<div class="w3-col m2 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde</label>
								<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.FECHA_SELEC" value="' + @VFECHA + '" disabled>
							</div>
							<div class="w3-col m2 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
								<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="date" name="SP.AGENDA_FECHA" value="' + CASE WHEN ISNULL(@VFECHA_HASTA,'') = '' THEN '' ELSE CONVERT(VARCHAR,@VFECHA_HASTA,23) END + '">
							</div>
							<div class="w3-col m8 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar-week"></i>&nbsp;&nbsp;Tipo&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
								<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb1" name="SP.AGENDA_TIPO"></select>
							</div>
						</div>
						<div class="w3-row-padding">
							<div class="w3-col m3 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-grip-vertical"></i>&nbsp;&nbsp;Motivo</label>
								<select class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" id="cmb2" name="SP.AGENDA_MOTIVO"></select>
							</div>
							<div class="w3-col m6 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Descripcion</label>
								<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_DESC" value="' + @VDESC_MOTIVO + '">
							</div>
							<div class="w3-col m3 w3-padding-small">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Horas&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
								<input class="w3-input w3-border w3-padding w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_HORAS" value="' + ISNULL(CONVERT(VARCHAR(5),@VHORAS),'') + '">
							</div>
							<div>&nbsp;</div>
						</div>
		<div class="w3-row w3-topbar"></div>'
 
	SET @OFOOTER = '
		<div class="w3-row">
			<div class="w3-container w3-padding">'+
				CASE WHEN isnull(@VDESC_ERROR,'') <> '' THEN
					'<div class="w3-panel w3-pale-red" style="height: 20px;">
						<span class="w3-muhle-text-14"><b>'+isnull(@VDESC_ERROR,'')+'</b></span>
					</div>'
				ELSE 
					'<div>&nbsp;</div>'
				END + '	
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="next('''+@FORM_ID+''');return false;">Agregar</btn>
				<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="almacenarSeleccion(''FECHA_SELEC'','''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');return false;">Cancelar</btn>
			</div>
		</div>
	</div>
</div>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + 'D14748F8-7C50-4364-9E0C-413B847E3954' + ''', ''' + ISNULL(@VTIPO,'') +''', '''');</script>
<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb2'', ''' + 'E5D2BD3F-8B01-40D5-9417-B3D28E583589' + ''', ''' + ISNULL(@VMOTIVO,'') +''', '''');</script>'
 
END
 
