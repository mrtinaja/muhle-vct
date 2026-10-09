CREATE PROCEDURE [dbo].[HOME_INICIO_PROYECTOS]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OTABLA	AS VARCHAR(MAX) OUTPUT,
 @OTOTAL	AS INT OUTPUT)
AS
 
DECLARE		
	@VF_CLIENTE			VARCHAR(50),
	@VF_PROYECTO		VARCHAR(50),
	@VF_SERVICIO		VARCHAR(50),
	@Pagina				INT,
	@vcliente			varchar(max),
	@vproyecto			varchar(max),
	@vobs				varchar(max),
	@vestado			varchar(max),
	@vnormas			varchar(max),
	@vfechaini			varchar(max),
	@vfechafin			varchar(max),
	@vhoras				varchar(max),
	@vservicios			varchar(max),
	@vopciones			varchar(max),
	@VINFO				VARCHAR(MAX)
 
BEGIN	
 
		SELECT	@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,''),
				@Pagina = (CONVERT(INT,ISNULL(NRO_PAGINA,0)))*10
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
		SET @OTABLA = '
			<table id="Table1" class="w3-table-all w3-card-4">
				<tr style="background-color:gray;">
					<th><div class="w3-left" style="font-size:13px"></div></th>
					<th><div class="w3-left" style="font-size:13px">Cliente</div></th>
					<th><div class="w3-left" style="font-size:13px">Proyecto</div></th>'+
					--<th><div class="w3-center" style="font-size:13px">Obs</div></th>
					'<th><div class="w3-center" style="font-size:13px">Estado</div></th>
					<th><div class="w3-center" style="font-size:13px">Normas</div></th>
					<th><div class="w3-center" style="font-size:13px">Inicio</div></th>
					<th><div class="w3-center" style="font-size:13px">Fin</div></th>
					<th><div class="w3-center" style="font-size:13px">Horas</div></th>
					<th><div class="w3-center" style="font-size:13px">Servicios</div></th>
					<th><div class="w3-center" style="font-size:13px">Opciones</div></th>
				</tr>'
		
		DECLARE Proyectos CURSOR FOR
		SELECT	'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-street-view w3-large" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''CLIENTE'','''+cast(PROYECTOS.CLIENTE as varchar)+ ''');almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,ID)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 
				+ '</div>' as Info,
				'<div class="w3-left" style="font-size:13px">'+RAZON_SOCIAL+ '</div>'							AS Cliente, 
				'<div class="w3-left" style="font-size:13px">'+PROYECTO+ '</div>'							AS Proyecto, 
				--'<div class="w3-left" style="font-size:13px">'+
				--	'<font style="font-size:10px;color:black;text-align: left">'+ISNULL(OBSERV,'Sin Observaciones')+'</font>'+ '</div>' AS Obs, 
				'<div class="w3-center" style="font-size:13px">'+ISNULL(ESTADO_DESC,'Sin Estado')+ '</div>'	AS Estado, 
				'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',NORMAS,''),'</br>',char(10))+'"></i>' 
				+ '</div>'	AS Normas,
				'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,FECHA_INICIO,103)+ '</div>'						AS "Fecha Inicio", 
				'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,FECHA_FIN,103)+ '</div>'							AS "Fecha Fin", 
				'<div class="w3-center" style="font-size:13px">'+HORASP+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', ID, NULL, NULL)+ '</div>' AS "Horas",
				'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (ID, @FORM_ID, 'I')+ '</div>' AS "Servicios",
				'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-edit w3-large" style="cursor:pointer;" title="Modificar" onclick="almacenarSeleccion(''NRO_COTIZA'','''+cast(NRO_COTIZA as varchar)+''');almacenarSeleccion(''CLIENTE'','''+cast(PROYECTOS.CLIENTE as varchar)+''');almacenarSeleccion(''ESTADO_PROY'','''+ISNULL(PROYECTOS.ESTADO,'')+''');almacenarSeleccion(''PROYECTO_ID'','''+cast(ID as varchar)+''');goto('''+@FORM_ID+''',''2F0833BA-8A65-4039-8443-95158FCDB8CF'');"></i>&nbsp;'+
					CASE WHEN ISNULL(NRO_COTIZA,0) <> 0 THEN 
						'<i class="fas fa-file-word w3-large" style="cursor:pointer;" title="Ver Propuesta" onclick="OpenAttach('''+ISNULL(ID_ADJUNTO,'')+''','''+ISNULL(ATACH_COTIZ.FILE_NAME,'')+''');return false;"></i>'  
					ELSE '' END + '&nbsp;' +
					CASE WHEN ISNULL(SUM(A.DIAS),0) = 0 THEN 
						'<i class="fas fa-trash-alt w3-large" style="cursor:pointer;" title="' +'Eliminar Proyecto'+ '" 
						onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Proyecto?'');
						if (confirmar){almacenarSeleccion(''ID_DELETE'','''+cast(ID as varchar)+ ''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');}"/>'
					ELSE ''
					END + '</div>' AS Opciones		
		FROM	
			(
			SELECT DISTINCT CLI.RAZON_SOCIAL_CLIENTE						AS RAZON_SOCIAL,
					'('+CODIGO+') - '+NORMA_REF								AS PROYECTO,
					CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)				AS FECHA_INICIO,
					CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END	AS FECHA_FIN,
					CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)				AS HORASP,
					--CONVERT(VARCHAR,ISNULL(P.TOTAL_HORAS_EJECUTADAS,'0'))	AS HORASE,
					P.ID_PROYECTO							 AS ID,
					P.ID_CLIENTE							 AS CLIENTE,
					ESTADO_PROYECTO_TOTAL					 AS ESTADO,
					CD.CAT_DATA_DESC						 AS ESTADO_DESC,
					NORMAS									 AS NORMAS,
					P.OBSERVACIONES							 AS OBSERV,
					P.ID_COTIZACION							 AS NRO_COTIZA,
					C.ID_ADJUNTO
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					--LEFT JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					--LEFT JOIN LK_AGENDA A ON A.ID_CLIENTE = CLI.ID_CLIENTE AND A.ID_PROYECTO = P.ID_PROYECTO
					LEFT JOIN LK_COTIZACIONES C ON C.ID_COTIZACION = P.ID_COTIZACION
			WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			) PROYECTOS 
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT ATACH_COTIZ ON ATACH_COTIZ.PKEY = PROYECTOS.ID_ADJUNTO
			LEFT JOIN LK_AGENDA A ON A.ID_CLIENTE = PROYECTOS.CLIENTE AND A.ID_PROYECTO = PROYECTOS.ID
		WHERE	CONVERT(VARCHAR,PROYECTOS.CLIENTE) = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE CONVERT(VARCHAR,PROYECTOS.CLIENTE) END
		AND		CONVERT(VARCHAR,PROYECTOS.ID) = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE CONVERT(VARCHAR,PROYECTOS.ID) END
		--AND		CONVERT(VARCHAR,ISNULL(PS.ID_TIPO_SERVICIO,'')) = CASE WHEN @VF_SERVICIO <> '' THEN @VF_SERVICIO ELSE CONVERT(VARCHAR,ISNULL(PS.ID_TIPO_SERVICIO,'')) END
		GROUP BY RAZON_SOCIAL, PROYECTO, OBSERV, PROYECTOS.ESTADO, NORMAS, FECHA_INICIO, FECHA_FIN, HORASP, ID, PROYECTOS.CLIENTE, NRO_COTIZA, ID_ADJUNTO, ESTADO_DESC,ATACH_COTIZ.FILE_NAME
		ORDER BY RAZON_SOCIAL, FECHA_INICIO
		OFFSET @Pagina ROWS
		FETCH NEXT 10 ROWS ONLY
 
		OPEN Proyectos
		FETCH NEXT FROM Proyectos INTO @VINFO,@vcliente, @vproyecto, /*@vobs,*/ @vestado, @vnormas, @vfechaini, @vfechafin, @vhoras, @vservicios, @vopciones
	
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				
				SET	@OTABLA = isnull(@OTABLA,'') +
				'<tr>
					<td>'+ISNULL(@VINFO,'')+'</td>
					<td>'+ISNULL(@vcliente,'')+'</td>
					<td>'+ISNULL(@vproyecto,'')+'</td>'+
					--<td>'+ISNULL(@vobs,'')+'</td>
					'<td>'+ISNULL(@vestado,'')+'</td>
					<td>'+ISNULL(@vnormas,'')+'</td>
					<td>'+ISNULL(@vfechaini,'')+'</td>
					<td>'+ISNULL(@vfechafin,'')+'</td>
					<td>'+ISNULL(@vhoras,'')+'</td>
					<td>'+ISNULL(@vservicios,'')+'</td>
					<td>'+ISNULL(@vopciones,'')+'</td>
				</tr>'
 
			FETCH NEXT FROM Proyectos INTO @VINFO,@vcliente, @vproyecto, /*@vobs,*/ @vestado, @vnormas, @vfechaini, @vfechafin, @vhoras, @vservicios, @vopciones
		END 
 
		CLOSE Proyectos  
		DEALLOCATE Proyectos	
 
		SET @OTABLA = @OTABLA + '</table>'
 
		SET @OTOTAL = 0
 
		SELECT	DISTINCT @OTOTAL = COUNT(*)
		FROM	
			(
			SELECT DISTINCT CLI.RAZON_SOCIAL_CLIENTE						AS CLIENTE,
					'('+CODIGO+') - '+NORMA_REF								AS PROYECTO,
					CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)				AS FECHA_INICIO,
					CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END	AS FECHA_FIN,
					CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)				AS HORASP,
					--CONVERT(VARCHAR,ISNULL(P.TOTAL_HORAS_EJECUTADAS,'0'))	AS HORASE,
					P.ID_PROYECTO							 AS ID,
					CLI.ID_CLIENTE							 AS ID_CLIENTE,
					ESTADO_PROYECTO_TOTAL					 AS ESTADO,
					CD.CAT_DATA_DESC						 AS ESTADO_DESC,
					NORMAS									 AS NORMAS,
					P.OBSERVACIONES							 AS OBSERV,
					P.ID_COTIZACION							 AS NRO_COTIZA,
					C.ID_ADJUNTO
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					--LEFT JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					--LEFT JOIN LK_AGENDA A ON A.ID_CLIENTE = CLI.ID_CLIENTE AND A.ID_PROYECTO = P.ID_PROYECTO
					LEFT JOIN LK_COTIZACIONES C ON C.ID_COTIZACION = P.ID_COTIZACION
			WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			) PROYECTOS 
		WHERE	CONVERT(VARCHAR,PROYECTOS.ID_CLIENTE) = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE CONVERT(VARCHAR,PROYECTOS.ID_CLIENTE) END
		AND		CONVERT(VARCHAR,PROYECTOS.ID) = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE CONVERT(VARCHAR,PROYECTOS.ID) END
		--AND		CONVERT(VARCHAR,ISNULL(PS.ID_TIPO_SERVICIO,'')) = CASE WHEN @VF_SERVICIO <> '' THEN @VF_SERVICIO ELSE CONVERT(VARCHAR,ISNULL(PS.ID_TIPO_SERVICIO,'')) END
		--GROUP BY CLIENTE, PROYECTO, OBSERV, PROYECTOS.ESTADO, NORMAS, FECHA_INICIO, FECHA_FIN, HORASP, ID, PROYECTOS.ID_CLIENTE, NRO_COTIZA, ID_ADJUNTO, ESTADO_DESC,ATACH_COTIZ.FILE_NAME
 
		IF (ISNULL(@OTOTAL,'') = '') BEGIN
			SET @OTOTAL = 0
		END
END
