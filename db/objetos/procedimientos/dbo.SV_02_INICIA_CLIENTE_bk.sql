CREATE PROCEDURE [dbo].[SV_02_INICIA_CLIENTE_bk]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(8000) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-user-tie w3-large"></i>&nbsp;&nbsp;Clientes</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-user-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''FDEDA3EB-D348-4CCB-883F-BB54E878F975'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
	SET @OFOOTER = '</div>
				</div>
			</div>'
 
	UPDATE	TMT_SV_02
	SET		CUIT  = NULL,
			RAZON_SOCIAL = NULL,
			CALLE = NULL,
			NRO = NULL,
			PISO = NULL,
			LOCALIDAD = NULL,
			PROVINCIA = NULL,
			TELEFONO1 = NULL,
			TELEFONO2 = NULL,
			EMAIL = NULL,
			IVA = NULL,
			CONTACTO = NULL,
			TIPO_CLIENTE = NULL,
			ESTADO = NULL,
			OBSERVACIONES = NULL,
			ERROR = NULL,
			CLAVE = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	--SET @OHEADER = '
	--<div class="w3-container" style="background-color:light-gray">
	--	<span class="w3-right" style="font-size:14px;">'+
	--		'Usuario: <b>'+@USERDESC+'</b> - Fecha: <b>' +CONVERT(VARCHAR, GETDATE(), 103)+' '+CONVERT(VARCHAR,GETDATE(),108)+'</b>
	--	</span>
	--</div>
	--<div class="w3-card-4 w3-round" style="background-color:#641E16;">
	--	<div class="w3-bar w3-round-up">
	--		<span class="w3-bar-item w3-left" style="color:white;font-size:16px;"><i class="fa fa-address-book w3-xlarge" style="color:white;"></i>&nbsp;&nbsp;Clientes</span>
	--		<span class="w3-bar-item w3-right" style="color:white;font-size:16px;"><i class="fas fa-user-plus w3-margin-center w3-xlarge" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''FDEDA3EB-D348-4CCB-883F-BB54E878F975'');return false;"></i></span>
	--	</div>
	--</div>
	--<div class="w3-panel w3-topbar">
	--</div>'
	--<button onclick="goto('''+@FORM_ID+''',''FDEDA3EB-D348-4CCB-883F-BB54E878F975'');return false;" class="w3-button w3-circle w3-teal w3-right w3-border w3-border-white" title="Nuevo">+</button>
 
END
 
