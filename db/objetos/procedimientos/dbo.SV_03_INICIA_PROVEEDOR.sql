CREATE PROCEDURE [dbo].[SV_03_INICIA_PROVEEDOR]
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
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	UPDATE	TMT_SV_03
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
			TIPO_PROVEEDOR = NULL,
			ESTADO = NULL,
			OBSERVACIONES = NULL,
			ERROR = NULL,
			CLAVE = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-address-card w3-large"></i>&nbsp;&nbsp;Proveedores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-user-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''AD56248B-C21A-479B-9F51-4AC8EC3DA905'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
END
 
