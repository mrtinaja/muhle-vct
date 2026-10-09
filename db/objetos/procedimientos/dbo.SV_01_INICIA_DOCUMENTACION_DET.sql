CREATE   PROCEDURE [dbo].[SV_01_INICIA_DOCUMENTACION_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
DECLARE @UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VCLAVE_DOC VARCHAR(100),
		@VCODIGO	VARCHAR(50),
		@VDESC		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDETALLE	VARCHAR(50),
		@VERROR		VARCHAR(50)
 
BEGIN		
 
	SELECT	@VCLAVE_DOC = CLAVE_DOC,
			@VERROR = ISNULL(ERROR,'')
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCODIGO = CODE_DOCUMENTACION,
			@VDESC = DESC_DOCUMENTACION,
			@VFECHA = CONVERT(VARCHAR,FECHA_ALTA,103) ,
			@VDETALLE = DETALLE_DOCUMENTACION
	FROM	LK_DOCUMENTACION
	WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
 
	UPDATE	TMT_SV_01
	SET		DESCRIPCION_DET = NULL,
			ESTADO_DET = NULL,
			COMENTARIO_DET = NULL,
			GRUPO_DET = NULL,
			CLAVE_DETALLE = NULL,
			ORDEN = NULL,
			ERROR = 'NO',
			DESC_ERROR = NULL,
			OBLIGATORIO = NULL,
			DATO = NULL,
			CAMPO = NULL,
			EXPORTA = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-address-book fa-fw w3-large"></i>&nbsp;&nbsp;Detalle Documentación</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');return false;"></i></span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fa fa-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" onclick="goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-container" style="padding:2px;"></div>
	<div class="w3-container">
		<table class="w3-table-all">
			<thead>
				<tr class="w3-light-grey w3-muhle-text-12">
					<th><b>Codigo</b></th>
					<th><b>Documentacion</b></th>
					<th><b>Fecha Alta</b></th>
					<th><b>Detalle</b></th>
				</tr>
			</thead>
			<tr class="w3-grey w3-muhle-text-12">' +
				'<td>'+@VCODIGO+'</td>'+
				'<td>'+@VDESC+'</td>'+
				'<td>'+@VFECHA+'</td>'+
				'<td>'+@VDETALLE+'</td>
			</tr>
		</table>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
 
	--SET @OHEADER = '
	--<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--	<div class="w3-bar w3-round-up">
	--		<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-address-book fa-fw w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Detalle Documentación</span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');return false;""></i></span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fa fa-plus w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');return false;"></i></span>
	--	</div>
	--</div>
	--<div class="w3-container" style="padding:4px;"></div>
	--<div class="w3-container">
	--	<table class="w3-table-all">
	--		<thead>
	--			<tr class="w3-light-grey">
	--				<th><b>Codigo</b></th>
	--				<th><b>Documentacion</b></th>
	--				<th><b>Fecha Alta</b></th>
	--				<th><b>Detalle</b></th>
	--			</tr>
	--		</thead>
	--		<tr class="w3-grey">' +
	--			'<td>'+@VCODIGO+'</td>'+
	--			'<td>'+@VDESC+'</td>'+
	--			'<td>'+@VFECHA+'</td>'+
	--			'<td>'+@VDETALLE+'</td>
	--		</tr>
	--	</table>
	--</div>
	--<div class="w3-panel w3-topbar"></div>'
 
END
 
