CREATE PROCEDURE [dbo].[SV_03_GRD_PROVEEDORES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VCLAVE_DEL		VARCHAR(50),
		@VID_ADJUNTO	VARCHAR(100)
 
BEGIN	
 
	SELECT	'<div class="w3-center w3-muhle-text-12">'+
			'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
			onclick="almacenarSeleccion(''CLAVE'','''+CONVERT(VARCHAR,ID_PROVEEDOR)+''');
					 almacenarSeleccion(''PROVINCIA'','''+ISNULL(CONVERT(VARCHAR,PROVINCIA_PROV),'')+''');
					 almacenarSeleccion(''IVA'','''+ISNULL(CONVERT(VARCHAR,IVA_PROV),'')+''');
					 almacenarSeleccion(''TIPO_PROVEEDOR'','''+ISNULL(CONVERT(VARCHAR,TIPO_PROV),'')+''');
					 almacenarSeleccion(''ESTADO'','''+ISNULL(CONVERT(VARCHAR,STATUS_PROV),'')+''');
					 goto('''+@FORM_ID+''',''AD56248B-C21A-479B-9F51-4AC8EC3DA905'');"></i></div>'	AS '<div class="w3-center w3-muhle-text-11"></div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(RAZON_SOCIAL_PROV,'')+'</div>'							AS '<div class="w3-left w3-muhle-text-11">Proveedor</div>',
			'<div class="w3-center w3-muhle-text-11">'+ISNULL(CD1.CAT_DATA_DESC,TIPO_PROV)+'</div>'					AS '<div class="w3-center w3-muhle-text-11">Tipo</div>',
			'<div class="w3-center w3-muhle-text-11">'+ISNULL(CUIT_PROV,'')+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Cuit Proveedor</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(CALLE_PROV,'')+ ' ' +ISNULL(NRO_CALLE_PROV,'') + case when ISNULL(PISO_DEPTO_PROV,'') = '' THEN '' ELSE ' - ' + PISO_DEPTO_PROV END+'</div>'	AS '<div class="w3-left w3-muhle-text-11">Domicilio</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(LOCALIDAD_PROV,'')+'</div>'								AS '<div class="w3-left w3-muhle-text-11">Localidad</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(CD.CAT_DATA_DESC,PROVINCIA_PROV)+'</div>'				AS '<div class="w3-left w3-muhle-text-11">Provincia</div>',
			'<div class="w3-center w3-muhle-text-11">'+ISNULL(TEL1_PROV,'')+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Telefono</div>',
			'<div class="w3-center w3-muhle-text-11">'+ISNULL(TEL2_PROV,'')+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Celular</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(EMAIL_PROV,'')+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Email</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(OBSERV_PROV,'')+'</div>'								AS '<div class="w3-left w3-muhle-text-11">Observaciones</div>'			
	FROM	LK_PROVEEDORES P
			LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.PROVINCIA_PROV AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'PROVINCIA')
			LEFT JOIN CAT_DATA CD1 ON CD1.CAT_DATA_CODE = P.TIPO_PROV AND CD1.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'TIPO_PROVEEDOR')
	ORDER BY RAZON_SOCIAL_PROV
 
END
