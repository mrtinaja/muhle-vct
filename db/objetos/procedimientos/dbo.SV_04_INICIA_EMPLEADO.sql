CREATE PROCEDURE [dbo].[SV_04_INICIA_EMPLEADO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(4000) OUTPUT)
AS
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300),
		@VID_DELETE AS VARCHAR(100)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE	
 
	SELECT	@VID_DELETE = ISNULL(ID_DELETE,'')
	FROM	TMT_SV_04
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VID_DELETE <> '') BEGIN
		DELETE FROM LK_EMPLEADOS WHERE ID_EMPLEADO = @VID_DELETE
	END
 
	UPDATE	TMT_SV_04
	SET		CUIT  = NULL,
			CALLE = NULL,
			NRO = NULL,
			PISO = NULL,
			LOCALIDAD = NULL,
			PROVINCIA = NULL,
			TELEFONO1 = NULL,
			TELEFONO2 = NULL,
			EMAIL = NULL,
			ESTADO = NULL,
			NOMBRE = NULL,
			APELLIDO = NULL,
			TIPO_DOC = NULL,
			NRO_DOC = NULL,
			INGRESO = NULL,
			USUARIO = NULL,
			FORMACION = NULL,
			MOVILIDAD = NULL,
			PERFIL = NULL,
			CONS_TIPO_CONS = NULL,
			CONS_TIPO_AUDI = NULL,
			CONS_TIPO_CAPA = NULL,
			DIAS_MENSUALES = NULL,
			ERROR = NULL,
			DESC_ERROR = NULL,
			CLAVE = NULL,
			EVENTUAL = NULL,
			COD_ACCION_MENU = NULL,
			ID_DELETE = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
	DELETE	PHYSICAL_ATTACHED_DOCUMENT 
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fa fa-users fa-fw w3-large"></i>&nbsp;&nbsp;Empleados/Consultores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-user-plus w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Nuevo" style="cursor:pointer;" onclick="almacenarSeleccion(''COD_ACCION_MENU'',''ALTA'');goto('''+@FORM_ID+''',''EB1BF60D-7182-4AF8-A6F4-4904EA719F98'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
END
