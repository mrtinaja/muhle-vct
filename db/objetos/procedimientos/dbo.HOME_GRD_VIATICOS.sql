CREATE PROCEDURE [dbo].[HOME_GRD_VIATICOS]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VID_VIATICO	VARCHAR(50),
		@VTIPO_PROV		VARCHAR(50),
		@VID_DELETE		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VID_VIATICO = ISNULL(HOJA_RUTA_ID,''),
			@VID_DELETE = ISNULL(ID_DELETE,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VTIPO_PROV = TIPO_PROVEEDOR
	FROM	LK_PROYECTO_VIATICOS
	WHERE	ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	IF (@VID_DELETE <> '') BEGIN
		DELETE	LK_PROYECTO_VIATICOS_DET
		WHERE	ID_PROYECTO_VIATICOS_DET = @VID_DELETE
 
		UPDATE	XAGENDA
		SET		ID_DELETE = NULL
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	IF (@VTIPO_PROV IN ('AVION','MICRO')) BEGIN
 
		SELECT	'<div class="w3-center w3-muhle-text-11">'+DET_PROV_RESERVA+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Cod. Reserva</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FECHA,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha</div>',
				'<div class="w3-center w3-muhle-text-11">'+DET_PROV_VUELO+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Vuelo</div>',
				'<div class="w3-left w3-muhle-text-11">'+DET_PROV_ORIGEN+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Origen</div>',
				'<div class="w3-left w3-muhle-text-11">'+DET_PROV_DESTINO+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Destino</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(DET_PROV_SALIDA,'')+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Hora Salida</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(DET_PROV_LLEGADA,'')+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Hora Llegada</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTOR+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTORA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultora</div>',
				'<div class="w3-center w3-muhle-text-11">'+RENDICION_CLIENTE+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Rendicion Cliente</div>',
				'<div class="w3-center w3-muhle-text-12">'+
				'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" onclick="almacenarSeleccion(''ID_DETALLE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+''');goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Detalle Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+ ''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS_DET			
		WHERE	ID_AGENDA			 = @VAGENDA_ID
		AND		ID_PROYECTO_VIATICOS = @VID_VIATICO
		
	END
 
	IF (@VTIPO_PROV = 'HOTEL') BEGIN
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+DET_PROV_LOCAL+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Ciudad</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FINGRESO,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Ingreso</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FEGRESO,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Egreso</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTOR+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTORA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultora</div>',
				'<div class="w3-center w3-muhle-text-11">'+RENDICION_CLIENTE+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Rendicion Cliente</div>',
				'<div class="w3-center w3-muhle-text-12">'+
				'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" onclick="almacenarSeleccion(''ID_DETALLE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+''');goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Detalle Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+ ''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS_DET			
		WHERE	ID_AGENDA			 = @VAGENDA_ID
		AND		ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	END
 
	IF (@VTIPO_PROV = 'TAXI' OR @VTIPO_PROV = 'REMIS') BEGIN
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+DET_PROV_ORIGEN+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Origen</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FPARTIDA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Partida</div>',
				'<div class="w3-center w3-muhle-text-11">'+DET_PROV_SALIDA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Hora Partida</div>',
				'<div class="w3-left w3-muhle-text-11">'+DET_PROV_DESTINO+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Destino</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FLLEGADA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Llegada</div>',
				'<div class="w3-center w3-muhle-text-11">'+DET_PROV_LLEGADA+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Hora Llegada</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTOR+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTORA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultora</div>',
				'<div class="w3-center w3-muhle-text-11">'+RENDICION_CLIENTE+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Rendicion Cliente</div>',
				'<div class="w3-center w3-muhle-text-12">'+
				'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" onclick="almacenarSeleccion(''ID_DETALLE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+''');goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Detalle Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+ ''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS_DET			
		WHERE	ID_AGENDA			 = @VAGENDA_ID
		AND		ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	END
 
	IF (@VTIPO_PROV = 'AUTO') BEGIN
 
		SELECT	'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FECHA,103)+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Fecha</div>',
				'<div class="w3-center w3-muhle-text-11">'+DET_PROV_KMS+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Kilometros</div>',
				'<div class="w3-center w3-muhle-text-11">'+DET_PROV_PEAJES+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Peajes</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTOR+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Paga Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTORA+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Paga Consultora</div>',
				'<div class="w3-center w3-muhle-text-11">'+RENDICION_CLIENTE+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Rendicion Cliente</div>',
				'<div class="w3-center w3-muhle-text-12">'+
				'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" onclick="almacenarSeleccion(''ID_DETALLE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+''');goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Detalle Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+ ''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS_DET			
		WHERE	ID_AGENDA			 = @VAGENDA_ID
		AND		ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	END
 
	IF (@VTIPO_PROV = 'ALQUILER') BEGIN
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+DET_PROV_ORIGEN+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Origen</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FPARTIDA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Desde</div>',
				'<div class="w3-left w3-muhle-text-11">'+DET_PROV_DESTINO+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Destino</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DET_PROV_FLLEGADA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Hasta</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTOR+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+PAGA_CONSULTORA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Paga Consultora</div>',
				'<div class="w3-center w3-muhle-text-11">'+RENDICION_CLIENTE+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Rendicion Cliente</div>',
				'<div class="w3-center w3-muhle-text-12">'+
				'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" onclick="almacenarSeleccion(''ID_DETALLE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+''');goto('''+@FORM_ID+''',''0351017D-A702-4B52-A220-1CE89E31A6C8'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Detalle Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS_DET)+ ''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');}"/></div>' AS '<div class="w3-center w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS_DET			
		WHERE	ID_AGENDA			 = @VAGENDA_ID
		AND		ID_PROYECTO_VIATICOS = @VID_VIATICO
 
	END
 
END
