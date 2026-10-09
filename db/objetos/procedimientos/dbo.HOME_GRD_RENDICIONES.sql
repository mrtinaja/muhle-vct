CREATE PROCEDURE [dbo].[HOME_GRD_RENDICIONES]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VSERVICIO		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	'<div class="w3-center w3-muhle-text-12">'+
				'<input type="checkbox" id="'+CONVERT(VARCHAR,PV.ID_PROYECTO_VIATICOS)+'"'+' onchange="toggleCheckbox(this);">
			</div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
			'<div class="w3-left w3-muhle-text-11">'+ISNULL(PROV.RAZON_SOCIAL_PROV,'Otros')+'</div>'							AS '<div class="w3-left w3-muhle-text-11">Proveedor</div>',
			'<div class="w3-center w3-muhle-text-11">'+CD1.CAT_DATA_DESC+'</div>'												AS '<div class="w3-center w3-muhle-text-11">Tipo</div>',
			'<div class="w3-center w3-muhle-text-11">'+PV.TIPO_CONSULTOR+'</div>'												AS '<div class="w3-center w3-muhle-text-11">Corresponde</div>',
			'<div class="w3-left w3-muhle-text-11">'+CASE WHEN ISNULL(EMP.ID_EMPLEADO,'') = '' THEN 
								PV.ID_CONSULTOR 
							  ELSE EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO END +'</div>'								AS '<div class="w3-left w3-muhle-text-11">Consultor/Observador</div>',
			'<div class="w3-left w3-muhle-text-11">'+DESCRIP_SERVICIO+'</div>'													AS '<div class="w3-center w3-muhle-text-11">Desc. Servicio</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_FC,103)+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Fecha Factura</div>',
			'<div class="w3-center w3-muhle-text-11">'+NRO_FC+'</div>'															AS '<div class="w3-center w3-muhle-text-11">Nro Factura</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,PRECIO_FINAL)+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Precio</div>',
			'<div class="w3-center w3-muhle-text-11">'+CD2.CAT_DATA_DESC+'</div>'												AS '<div class="w3-center w3-muhle-text-11">Forma Pago</div>',
			'<div class="w3-left w3-muhle-text-11">'+PV.DESC_FORMA_PAGO+'</div>'												AS '<div class="w3-left w3-muhle-text-11">Desc. Forma Pago</div>'
		FROM	LK_PROYECTO_VIATICOS PV
				LEFT JOIN LK_PROVEEDORES PROV ON PROV.ID_PROVEEDOR = PV.ID_PROVEEDOR
				LEFT JOIN LK_EMPLEADOS EMP ON PV.ID_CONSULTOR = CONVERT(VARCHAR,EMP.ID_EMPLEADO)
				LEFT JOIN CAT_DATA CD1 ON PV.TIPO_PROVEEDOR = CD1.CAT_DATA_CODE AND CD1.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'TIPO_PROVEEDOR')
				LEFT JOIN CAT_DATA CD2 ON PV.FORMA_PAGO = CD2.CAT_DATA_CODE AND CD2.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'FORMA_PAGO')
				--LEFT JOIN CAT_DATA CD3 ON PV.ESTADO_PAGO = CD3.CAT_DATA_CODE AND CD3.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADO_PAGO')
		WHERE	ID_AGENDA = @VAGENDA_ID
 
END
