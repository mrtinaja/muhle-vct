 
CREATE PROCEDURE [dbo].[HOME_GRD_DET_AGENDA]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO			VARCHAR(50),
		@VCLIENTE			VARCHAR(50),	
		@VSERVICIO			VARCHAR(50),
		@VID_SERVICIO		VARCHAR(50),
		@VID_AGENDA			VARCHAR(50),
		@VID_HOJA			VARCHAR(50),
		@VID_DOCUM			VARCHAR(50),
		@VTIPO				VARCHAR(50),
		@VTAB_SERV			VARCHAR(50),
		@VID_DELETE			VARCHAR(50),
		@VOBSERVACIONES		VARCHAR(400),
		@VBUFFER			VARCHAR(MAX),
		@VEXPORTA_DET		VARCHAR(50),
		@VRAZON_SOCIAL		VARCHAR(400),
		@VNOMBRE_PROY		VARCHAR(400)
 
BEGIN	
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VCLIENTE = ISNULL(CLIENTE,''),
			--@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,''),
			@VTIPO = ISNULL(TAB_AGENDA,''),
			@VID_DELETE = ISNULL(ID_DELETE,''),
			@VTAB_SERV = ISNULL(TAB_SERV,''), --detalle de servicio
			@VBUFFER = ISNULL(BUFFER,''),
			@VEXPORTA_DET = ISNULL(EXPORTA_MG,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VID_AGENDA <> '') BEGIN
		SELECT	--@VPROYECTO  = ID_PROYECTO,
				@VSERVICIO  = ID_SERVICIO
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VID_AGENDA
	END
 
	IF (@VTAB_SERV = '9') BEGIN --detalle anexo minuta de gestion
		
		--@VTIPO CAMPO TAB_AGENDA, ID_PROYECTO_DOCUM DEL ANEXO SELECCIONADO--
		SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
		FROM	LK_CLIENTES
		WHERE	ID_CLIENTE = @VCLIENTE
 
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VPROYECTO
 
		SELECT	'<div align="left" class="w3-muhle-text-12" style="width:80%;display:none;"><b>Cliente:</b>'+ISNULL(@VRAZON_SOCIAL,'')+'</div>' AS '<div align="center" class="w3-muhle-text-12">Items</div>',
				'<div align="left" class="w3-muhle-text-12" style="width:100%;display:none;"></div>'	AS '<div align="center" class="w3-muhle-text-12">Descripción</div>'
		UNION ALL
		SELECT	'<div align="left"data-pdf-only="1" class="w3-muhle-text-12" style="width:80%;display:none;"><b>Proyecto:</b>'+ISNULL(@VNOMBRE_PROY,'')+'</div>',
				'<div align="left" data-pdf-only="1" class="w3-muhle-text-12" style="width:100%;display:none;"></div>'
		UNION ALL
		SELECT	'<div align="center" class="w3-muhle-text-12" style="width:80%;"><b>Datos Generales</b></div>',
				'<div align="center" class="w3-muhle-text-12" style="width:100%;"></div>'					
		UNION ALL
		SELECT	'<td style="width:40%;vertical-align:middle;">' +
					'<div align="left" class="w3-muhle-text-12 w3-padding '+CASE WHEN ISNULL(OBLIGATORIO_DOC_DET,'') = 'SI' THEN 'w3-text-red' ELSE '' END+'">' +
					  DESC_DOC_DET + 
					'</div>' +
				'</td>',
				'<td style="width:60%;">' +
					'<textarea class="w3-input w3-border w3-round w3-muhle-text-11" ' +
						'id="' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET) + '" maxlength="4000" rows="4" ' +
						'onChange="toggleCombo(this);">' +
					  REPLACE(ISNULL(VALOR_DOC_DET,''), '''', '''''') +
					'</textarea>' +
				'</td>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VTIPO
		AND		GRUPO_DOC_DET = 'GENERAL'
		AND		ISNULL(EXPORTA_DOC_DET,'') = CASE WHEN @VEXPORTA_DET = '0|1' THEN
													ISNULL(EXPORTA_DOC_DET,'')
												  WHEN @VEXPORTA_DET = '0' THEN
													'0|1'
											 ELSE ISNULL(EXPORTA_DOC_DET,'') END
 
 
	END
 
	IF (@VTAB_SERV = '8') BEGIN --minuta de gestion
 
		--RECUPERO EL ID DE DOCUMENTACION DE LA MINUTA DE GESTION--
		SELECT	@VID_DOCUM = ID_PROYECTO_DOCUM
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		TIPO = 'MG'
 
		SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
		FROM	LK_CLIENTES
		WHERE	ID_CLIENTE = @VCLIENTE
 
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VPROYECTO
		
		--AS '<div align="center" class="w3-muhle-text-12">Items</div>'
		--AS '<div align="center" class="w3-muhle-text-12">Descripción</div>'
		SELECT	'<div align="left" class="w3-muhle-text-12" style="width:80%;display:none;"><b>Cliente:</b>'+ISNULL(@VRAZON_SOCIAL,'')+'</div>' AS '<div align="center" class="w3-muhle-text-12">Items</div>',
				'<div align="left" class="w3-muhle-text-12" style="width:100%;display:none;"></div>'	AS '<div align="center" class="w3-muhle-text-12">Descripción</div>'
		UNION ALL
		SELECT	'<div align="left"data-pdf-only="1" class="w3-muhle-text-12" style="width:80%;display:none;"><b>Proyecto:</b>'+ISNULL(@VNOMBRE_PROY,'')+'</div>',
				'<div align="left" data-pdf-only="1" class="w3-muhle-text-12" style="width:100%;display:none;"></div>'
		UNION ALL
		SELECT	'<div align="center" class="w3-muhle-text-12" style="width:80%;"><b>Datos Generales</b></div>',
				'<div align="center" class="w3-muhle-text-12" style="width:100%;"></div>'					
		UNION ALL
		SELECT	'<td style="width:40%;vertical-align:middle;">' +
					'<div align="left" class="w3-muhle-text-12 w3-padding '+CASE WHEN ISNULL(OBLIGATORIO_DOC_DET,'') = 'SI' THEN 'w3-text-red' ELSE '' END+'">' +
					  DESC_DOC_DET + 
					'</div>' +
				'</td>',
				'<td style="width:60%;">' +
					'<textarea class="w3-input w3-border w3-round w3-muhle-text-11" ' +
						'id="' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET) + '" maxlength="4000" rows="4" ' +
						'onChange="toggleCombo(this);">' +
					  REPLACE(ISNULL(VALOR_DOC_DET,''), '''', '''''') +
					'</textarea>' +
				'</td>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VID_DOCUM
		AND		GRUPO_DOC_DET = 'GENERAL'
		AND		ISNULL(EXPORTA_DOC_DET,'') = CASE WHEN @VEXPORTA_DET = '0|1' THEN
													ISNULL(EXPORTA_DOC_DET,'')
												  WHEN @VEXPORTA_DET = '0' THEN
													'0|1'
											 ELSE ISNULL(EXPORTA_DOC_DET,'') END
		UNION ALL
		SELECT	'<div align="center" class="w3-muhle-text-12" style="width:80%;"><b>Cierre de Proyecto</b></div>',
				'<div align="center" class="w3-muhle-text-12" style="width:100%;"></div>'
		UNION ALL
		SELECT	'<td style="width:40%;vertical-align:middle;">' +
					'<div align="left" class="w3-muhle-text-12 w3-padding '+CASE WHEN ISNULL(OBLIGATORIO_DOC_DET,'') = 'SI' THEN 'w3-text-red' ELSE '' END+'">' +
					  DESC_DOC_DET + 
					'</div>' +
				'</td>',
				'<td style="width:60%;">' +
					'<textarea class="w3-input w3-border w3-round w3-muhle-text-11" ' +
						'id="' + CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET) + '" maxlength="4000" rows="4" ' +
						'onChange="toggleCombo(this);">' +
					  REPLACE(ISNULL(VALOR_DOC_DET,''), '''', '''''') +
					'</textarea>' +
				'</td>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VID_DOCUM
		AND		GRUPO_DOC_DET <> 'GENERAL'
		AND		ISNULL(EXPORTA_DOC_DET,'') = CASE WHEN @VEXPORTA_DET = '0|1' THEN
													ISNULL(EXPORTA_DOC_DET,'')
												  WHEN @VEXPORTA_DET = '0' THEN
													'0|1'
											 ELSE ISNULL(EXPORTA_DOC_DET,'') END
 
	END
 
 
	IF (@VTIPO = '1') BEGIN --hoja de ruta--
 
		SELECT	@VID_HOJA = ID_PROYECTO_DOCUM
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_AGENDA = @VID_AGENDA
		AND		ID_DOCUMENTACION = CASE WHEN @VSERVICIO = '1' THEN '7'
										WHEN @VSERVICIO = '2' THEN '5'
										WHEN @VSERVICIO = '3' THEN '6'
								   END
 
		SELECT	@VOBSERVACIONES = ISNULL(OBSERVACIONES,'')
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
 
		UPDATE	XAGENDA
		SET		OBSERVACION_HR = @VOBSERVACIONES
		WHERE	PAR_KEY = @IPKEYJOB
 
		SELECT	'<div align="left" class="w3-muhle-text-11"><b>Logistica</b></div>'	AS '<div align="center" class="w3-muhle-text-11">Datos</div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="L" style="background-color:gray" onchange="toggleCombo(this);">
						<option value=""></option>
						<option value="NA">No Aplica</option>'+
						--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
					'</select>
				</div>'											AS '<div align="center" class="w3-muhle-text-11">Valores</div>'
		UNION ALL
		SELECT	'<div align="left" class="w3-muhle-text-11">'+ DESC_DOC_DET +'</div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
					<option value=""'  +CASE WHEN ISNULL(VALOR_DOC_DET,'') = '' THEN 'selected' ELSE '' END+'></option>
					<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
					<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>'+
					--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
				 '</select>
				</div>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
		AND		GRUPO_DOC_DET = 'LOGISTICO'
		UNION ALL
		SELECT	'<div align="left" class="w3-muhle-text-11"><b>Temas Tecnicos</b></div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="T" style="background-color:gray" onchange="toggleCombo(this);">
						<option value=""></option>
						<option value="NA">No Aplica</option>'+
						--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
					'</select>
				</div>'
		UNION ALL
		SELECT	'<div align="left" class="w3-muhle-text-11">'+ DESC_DOC_DET +'</div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
						<option value=""'  +CASE WHEN ISNULL(VALOR_DOC_DET,'') = '' THEN 'selected' ELSE '' END+'></option>
						<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
						<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>'+
						--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
					'</select>
				</div>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
		AND		GRUPO_DOC_DET = 'TECNICO'
		UNION ALL
		SELECT	'<div align="left" class="w3-muhle-text-11"><b>Administracion</b></div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="A" style="background-color:gray" onchange="toggleCombo(this);">
						<option value=""></option>
						<option value="NA">No Aplica</option>'+
						--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
					'</select>
				</div>'
		UNION ALL
		SELECT	'<div align="left" class="w3-muhle-text-11">'+ DESC_DOC_DET +'</div>',
				'<div align="center" class="w3-muhle-text-11">
					<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
						<option value=""'  +CASE WHEN ISNULL(VALOR_DOC_DET,'') = '' THEN 'selected' ELSE '' END+'></option>
						<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
						<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>'+
						--<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
					'</select>
				</div>'
		FROM	LK_PROYECTO_DOCUM_DET
		WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
		AND		GRUPO_DOC_DET = 'ADMINISTRACION'
	END
 
	IF (@VTIPO = '2') BEGIN --viaticos--
		
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE FROM LK_PROYECTO_VIATICOS WHERE ID_PROYECTO_VIATICOS = @VID_DELETE
			DELETE FROM LK_PROYECTO_VIATICOS_DET WHERE ID_PROYECTO_VIATICOS = @VID_DELETE
 
			UPDATE XAGENDA SET ID_DELETE = NULL WHERE PAR_KEY = @IPKEYJOB
		END
 
		SELECT	'<div align="left" class="w3-muhle-text-11">'+ISNULL(PROV.RAZON_SOCIAL_PROV,'Otros')+'</div>'							AS '<div align="left" class="w3-muhle-text-11">Proveedor</div>',
				'<div align="center" class="w3-muhle-text-11">'+CD1.CAT_DATA_DESC+'</div>'												AS '<div align="center" class="w3-muhle-text-11">Tipo</div>',
				'<div align="center" class="w3-muhle-text-11">'+PV.TIPO_CONSULTOR+'</div>'												AS '<div align="center" class="w3-muhle-text-11">Corresponde</div>',
				'<div align="left" class="w3-muhle-text-11">'+CASE WHEN ISNULL(EMP.ID_EMPLEADO,'') = '' THEN 
									PV.ID_CONSULTOR 
								  ELSE EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO END +'</div>'									AS '<div align="left" class="w3-muhle-text-11">Consultor/Observador</div>',
				'<div align="left" class="w3-muhle-text-11">'+DESCRIP_SERVICIO+'</div>'													AS '<div align="left" class="w3-muhle-text-11">Desc. Servicio</div>',
				'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_FC,103)+'</div>'									AS '<div align="center" class="w3-muhle-text-11">Fecha Factura</div>',
				'<div align="center" class="w3-muhle-text-11">'+NRO_FC+'</div>'															AS '<div align="center" class="w3-muhle-text-11">Nro Factura</div>',
				'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,PRECIO_FINAL)+'</div>'									AS '<div align="center" class="w3-muhle-text-11">Precio</div>',
				'<div align="center" class="w3-muhle-text-11">'+CD2.CAT_DATA_DESC+'</div>'												AS '<div align="center" class="w3-muhle-text-11">Forma Pago</div>',
				'<div align="left" class="w3-muhle-text-11">'+PV.DESC_FORMA_PAGO+'</div>'												AS '<div align="left" class="w3-muhle-text-11">Desc. Forma Pago</div>',
				'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS)+''');goto('''+@FORM_ID+''',''9699BAC1-EB3A-41AF-AB6C-8B97A339EFA2'');"></i>'	 + '&nbsp;' +
				CASE WHEN PV.TIPO_PROVEEDOR IN ('AVION','MICRO','HOTEL','REMIS','TAXI','AUTO','ALQUILER') THEN
				'<i class="fas fa-search" style="cursor:pointer;" title="Ver Detalle" onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS)+''');goto('''+@FORM_ID+''',''EC456415-B3E5-42F7-B9E1-AA5964EDE560'');"></i>'
				ELSE '' END	+ '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Viatico?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_VIATICOS)+ ''');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');}"/></div>' AS '<div align="center" class="w3-muhle-text-11">[+]</div>'
		FROM	LK_PROYECTO_VIATICOS PV
				LEFT JOIN LK_PROVEEDORES PROV ON PROV.ID_PROVEEDOR = PV.ID_PROVEEDOR
				LEFT JOIN LK_EMPLEADOS EMP ON PV.ID_CONSULTOR = CONVERT(VARCHAR,EMP.ID_EMPLEADO)
				LEFT JOIN CAT_DATA CD1 ON PV.TIPO_PROVEEDOR = CD1.CAT_DATA_CODE AND CD1.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'TIPO_PROVEEDOR')
				LEFT JOIN CAT_DATA CD2 ON PV.FORMA_PAGO = CD2.CAT_DATA_CODE AND CD2.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'FORMA_PAGO')
				--LEFT JOIN CAT_DATA CD3 ON PV.ESTADO_PAGO = CD3.CAT_DATA_CODE AND CD3.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADO_PAGO')
		WHERE	ID_AGENDA = @VID_AGENDA
 
	END
 
	IF (@VTIPO = '5') BEGIN --CHECKLIST ??
		
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE FROM LK_PROYECTO_DOCUM WHERE	ID_PROYECTO_DOCUM = @VID_DELETE
			DELETE FROM LK_PROYECTO_DOCUM_DET WHERE ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE XAGENDA SET ID_DELETE = NULL WHERE PAR_KEY = @IPKEYJOB
		END
 
		SELECT	'<div align="center" class="w3-muhle-text-12"><i class="fas fa-search" style="cursor:pointer;" title="Ver Detalle"				
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''6EA8B964-2C14-4B0F-AFB4-205C48498150'');"></i></div>'								AS '<div align="center" class="w3-muhle-text-11">[+]</div>',
			--'<font size="1">'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+'</font>'											AS '<font size="2">Id</font>',
			--'<font size="1">'+DOC.CODE_DOCUMENTACION + ' - ' + DOC.DESC_DOCUMENTACION	+'</font>'					AS '<font size="2">Documento</font>',
			'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_DOCUM,103)+'</div>'											AS '<div align="center" class="w3-muhle-text-11">Fecha Doc.</div>',
			'<div align="left" class="w3-muhle-text-11">'+TEMAS_DOCUM	+'</div>'																AS '<div align="left" class="w3-muhle-text-11">Curso</div>',
			'<div align="left" class="w3-muhle-text-11">'+NRO_DOCUM_INTERNO	+'</div>'															AS '<div align="left" class="w3-muhle-text-11">Nro/Nombre Doc.</div>',
			'<div align="left" class="w3-muhle-text-11">'+PARTICIPANTES_DOCUM+'</div>'															AS '<div align="left" class="w3-muhle-text-11">Asistentes</div>',
			'<div align="left" class="w3-muhle-text-11">'+ISNULL(OBSERVACIONES,'') +'</div>'													AS '<div align="left" class="w3-muhle-text-11">Observacion</div>',
			'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');goto('''+@FORM_ID+''',''3F11610E-DB37-427B-997D-1507E8982A92'');"></i>'	 + '&nbsp;' +
			'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el CheckList?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');}"/></div>' AS '<div align="center" class="w3-muhle-text-11">[-]</div>'
		FROM	LK_PROYECTO_DOCUM PD
				INNER JOIN LK_DOCUMENTACION DOC ON PD.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
		WHERE	ID_AGENDA = @VID_AGENDA
		AND		PD.ID_DOCUMENTACION = '4'
 
	END
 
	IF (@VTIPO = '3') BEGIN --honorarios--
		
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE FROM LK_PROYECTO_HONORARIOS WHERE ID_PROYECTO_HONORARIOS = @VID_DELETE
 
			UPDATE XAGENDA SET ID_DELETE = NULL WHERE PAR_KEY = @IPKEYJOB
		END
 
		SELECT	'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA,103)	+'</div>'											AS '<div align="center" class="w3-muhle-text-11">Fecha</div>',
				'<div align="left" class="w3-muhle-text-11">'+CASE WHEN ISNULL(H.ID_CONSULTOR,'') <> '' THEN EMP.APELLIDO_EMPLEADO +', '+EMP.NOMBRE_EMPLEADO ELSE '' END +'</div>'	AS '<div align="left" class="w3-muhle-text-11">Consultor</div>',
				'<div align="left" class="w3-muhle-text-11">'+LUGAR	+'</div>'																	AS '<div align="left" class="w3-muhle-text-11">Lugar</div>',
				'<div align="center" class="w3-muhle-text-11">'+IMPORTE	+'</div>'																AS '<div align="center" class="w3-muhle-text-11">Importe</div>',
				'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_HONORARIOS)+''');goto('''+@FORM_ID+''',''0B438E7D-728C-4D27-B9C5-534984C18EF9'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Honorario?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_HONORARIOS)+ ''');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');}"/>' AS '<div align="center" class="w3-muhle-text-11">[-]</div>'
		FROM	LK_PROYECTO_HONORARIOS H
				LEFT JOIN LK_EMPLEADOS EMP ON EMP.ID_EMPLEADO = H.ID_CONSULTOR
		WHERE	ID_AGENDA = @VID_AGENDA
 
	END
	
	IF (@VTIPO = '4') BEGIN --minuta de visita--
		
		IF (@VID_DELETE <> '') BEGIN
			
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VID_DELETE
 
			UPDATE XAGENDA SET ID_DELETE = NULL WHERE PAR_KEY = @IPKEYJOB
		END
 
		SELECT	'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</div>'			AS '<div align="center" class="w3-muhle-text-11">Fecha Doc.</div>',
				'<div align="center" class="w3-muhle-text-11">'+NRO_DOCUM_INTERNO	+'</div>'							AS '<div align="center" class="w3-muhle-text-11">Nro/Nombre Doc.</div>',
				'<div align="left" class="w3-muhle-text-11">'+ISNULL(OBSERVACIONES,'') +'</div>'						AS '<div align="left" class="w3-muhle-text-11">Observacion</div>',
				'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Minuta?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');}"/>'+ '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Minuta" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i></div>'
						ELSE '' END  AS '<div align="center" class="w3-muhle-text-11">[-]</div>'
		FROM	LK_PROYECTO_DOCUM D
				LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
		WHERE	ID_AGENDA = @VID_AGENDA
		AND		TIPO = 'MV'
 
	END
 
	IF (@VTIPO = 'IA') BEGIN
 
		SELECT	'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</div>'			AS '<div align="center" class="w3-muhle-text-11">Fecha Doc.</div>',
				'<div align="center" class="w3-muhle-text-11">'+NRO_DOCUM_INTERNO	+'</div>'							AS '<div align="center" class="w3-muhle-text-11">Nro/Nombre Doc.</div>',
				'<div align="left" class="w3-muhle-text-11">'+ISNULL(OBSERVACIONES,'') +'</div>'						AS '<div align="left" class="w3-muhle-text-11">Observacion</div>',
				'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''E54664C3-342F-45DC-8CCA-F8DC8DF96E67'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''ABEB226A-83F2-486D-A6B2-C9B8B16458B8'');}"/>'+ '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i></div>'
						ELSE '' END  AS '<div align="center" class="w3-muhle-text-11">[-]</div>'
		FROM	LK_PROYECTO_DOCUM D
				LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
		WHERE	ID_AGENDA = @VID_AGENDA
		AND		TIPO = 'IA'
 
	END
 
	IF (@VTIPO = 'IC') BEGIN
 
		SELECT	'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</div>'				AS '<div align="center" class="w3-muhle-text-11">Fecha Doc.</div>',
				'<div align="center" class="w3-muhle-text-11">'+NRO_DOCUM_INTERNO	+'</div>'								AS '<div align="center" class="w3-muhle-text-11">Nro/Nombre Doc.</div>',
				'<div align="left" class="w3-muhle-text-11">'+ISNULL(OBSERVACIONES,'') +'</div>'							AS '<div align="left" class="w3-muhle-text-11">Observacion</div>',
				'<div align="center" class="w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"			
				onclick="
				almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''C8DDD3B5-F138-487B-A452-2CA1A10DEBF7'');"></i>'	 + '&nbsp;' +
				'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
				onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
				if (confirmar){almacenarSeleccion(''ID_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''ABEB226A-83F2-486D-A6B2-C9B8B16458B8'');}"/>'+ '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i></div>'
						ELSE '' END  AS '<div align="center" class="w3-muhle-text-11">[-]</div>'
		FROM	LK_PROYECTO_DOCUM D
				LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
		WHERE	ID_AGENDA = @VID_AGENDA
		AND		TIPO = 'IC'
 
	END
 
END
