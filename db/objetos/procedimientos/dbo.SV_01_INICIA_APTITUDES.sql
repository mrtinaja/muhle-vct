CREATE   PROCEDURE [dbo].[SV_01_INICIA_APTITUDES]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
BEGIN	
 
	UPDATE	TMT_SV_01
	SET		DESCRIPCION_APT = NULL,
			ESTADO_APT = NULL,
			CLAVE = NULL,
			ERROR = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users fa-fw fa-fw w3-large"></i>&nbsp;&nbsp;Aptitudes</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" onclick="goto('''+@FORM_ID+''',''1085F118-8FDD-4D38-8AE4-BD8D52BF0928'');return false;"></i></span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fa fa-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" onclick="goto('''+@FORM_ID+''',''A3E17ACE-383D-4C91-8280-B617C5AF13EA'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	--SET @OHEADER = '
	--<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--	<div class="w3-bar w3-round-up">
	--		<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-users fa-fw w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Aptitudes</span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''1085F118-8FDD-4D38-8AE4-BD8D52BF0928'');return false;"></i></span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fa fa-plus w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''A3E17ACE-383D-4C91-8280-B617C5AF13EA'');return false;"></i></span>
	--	</div>
	--</div>
	--<div class="w3-panel w3-bottombar"></div>'
 
END
 
 
