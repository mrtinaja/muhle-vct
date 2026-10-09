CREATE PROCEDURE [dbo].[HOME_GRD_INICIO_PLANIF]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE		
	@VFECHA_DESDE		DATETIME,
	@VFECHA_HASTA		DATETIME,
	@VF_CLIENTE			VARCHAR(50),
	@VF_PROYECTO		VARCHAR(50),
	@VF_SERVICIO		VARCHAR(50),
	@VFILTRO			VARCHAR(50),
	@VSOLAPA			VARCHAR(50),
	@VF_ESTADO			VARCHAR(50)
 
BEGIN	
 
	SELECT	@VFILTRO = ISNULL(FILTRO,''),
			@VSOLAPA = ISNULL(SOLAPA,''),
			@VF_ESTADO = ISNULL(ESTADO,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VSOLAPA = '') BEGIN
		SET @VSOLAPA = 'PLAN'
	END
	
	IF (@VFILTRO = '') BEGIN
		SELECT	@VFECHA_DESDE = CAST(Convert(CHAR(8),GETDATE() - 5,112) as DATETIME),--PrimerDiaMes, 
				@VFECHA_HASTA = CAST(Convert(CHAR(8),GETDATE() + 3,112) as DATETIME)--UltimoDiaMes 
		FROM	Calendar 
		WHERE	Fecha = convert(varchar,GETDATE(),113)	
 
		SELECT	@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,''),
				@VF_ESTADO = ISNULL(ESTADO,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
		UPDATE	XAGENDA 
		SET		FECHA_DESDE = @VFECHA_DESDE, 
				FECHA_HASTA = @VFECHA_HASTA
		WHERE	PAR_KEY = @IPKEYJOB	
 
	END ELSE BEGIN
 
		SELECT	@VFECHA_DESDE = FECHA_DESDE,
				@VFECHA_HASTA = FECHA_HASTA,
				@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,''),
				@VF_ESTADO = ISNULL(ESTADO,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
	END
 
	IF (@VSOLAPA = 'PLAN') BEGIN
		SELECT	'<div align="center" class="w3-muhle-text-11">' +
					CASE WHEN ISNULL(A.INDICADOR_HR,'R') = 'R' THEN	
						'<i class="fas fa-circle w3-medium" style="cursor:pointer;color:red;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'N' THEN
						'<i class="fas fa-circle w3-medium" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'A' THEN
						'<i class="fas fa-circle w3-medium" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'V' THEN
						'<i class="fas fa-circle w3-medium" style="cursor:pointer;color:green;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'C' THEN	
						'<i class="fas fa-circle w3-medium" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
					END	+ '</div>'																												AS '<div align="center" class="w3-muhle-text-11"></div>',
				'<div align="left" class="w3-muhle-text-11">'+[dbo].[FN_GET_AGENDA_CLIENTE] (A.ID_AGENDA)+ '</div>'								AS '<div align="left" class="w3-muhle-text-11">Cliente</div>', --CLIENTE
				'<div align="left" class="w3-muhle-text-11">'+'('+P.CODIGO+') - '+P.NORMA_REF + ' - ' + '<b>'+ISNULL(ps.NOMBRE,'')+'<b></div>'	AS '<div align="left" class="w3-muhle-text-11">Proyecto</div>',--PROYECTO
				'<div align="center" class="w3-muhle-text-11">'+ 
					'<i class="fas fa-info-circle w3-medium" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMA,''),'</br>',char(10))+'"></i>
				</div>'																															AS '<div align="center" class="w3-muhle-text-11">Normas</div>', --NORMA
				'<div align="center" class="w3-muhle-text-11">'+
				--'<i class="' + 
					CASE	WHEN A.ID_SERVICIO = '1' THEN 'Consultoria'--'fas fa-user-tie w3-large"'
							WHEN A.ID_SERVICIO = '2' THEN 'Auditoria'--'fas fa-chalkboard-teacher w3-large"'
							WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion'--'fas fa-user-graduate w3-large"' END +
								/*'style="cursor:pointer;" title="'+	CASE WHEN A.ID_SERVICIO = '1' THEN 
																			'Consultoria"'
																		WHEN A.ID_SERVICIO = '2' THEN 
																			'Auditoria"'
																		WHEN A.ID_SERVICIO = '3' THEN 
																			'Capacitacion"' END --+ '></i>'*/
					END +'</div>'																												AS '<div align="center" class="w3-muhle-text-11">Servicio</div>', --SERVICIO
				'<div align="center" class="w3-muhle-text-11">'+ CONVERT(VARCHAR,FECHA,103) +'</div>'											AS '<div align="center" class="w3-muhle-text-11">Desde</div>', --FECHA DESDE
				'<div align="center" class="w3-muhle-text-11">'+ CONVERT(VARCHAR,FECHA_HASTA,103) +'</div>'										AS '<div align="center" class="w3-muhle-text-11">Hasta</div>', --FECHA HASTA
				'<div align="center" class="w3-muhle-text-11">'+ CONVERT(VARCHAR,ISNULL(A.DIAS,'')) +'</div>'									AS '<div align="center" class="w3-muhle-text-11">Días</div>',--DIAS
				'<div align="center" class="w3-muhle-text-11">'+ DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) +'</div>'								AS '<div align="center" class="w3-muhle-text-11">Horas</div>',--HORAS
				'<div align="center" class="w3-muhle-text-11">'+
					CASE WHEN ISNULL(A.OBSERV_CALIF,'') <> '' THEN 
					'<i class="fas fa-clipboard-list w3-medium" style="cursor:pointer;color:red;" title="Obs. Calificación:&nbsp;'+ ISNULL(A.OBSERV_CALIF,'') +'"></i>&nbsp;' ELSE '' END+
					--CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') <> '' THEN
					--'<i class="fas fa-clipboard-check w3-medium" style="cursor:pointer;color:blue;" title="Obs. Logística:&nbsp;'+ ISNULL(A.OBSERV_LOGISTICA,'') +'"></i>&nbsp;' ELSE '' END+
					CASE WHEN ISNULL(DOC.OBSERVACIONES,'') <> '' THEN
					'<i class="fas fa-clipboard w3-medium" style="cursor:pointer;color:green;" title="Obs. Hoja Ruta:&nbsp;'+ ISNULL(DOC.OBSERVACIONES,'') +'"></i>&nbsp;' ELSE '' END + '
				</div>'																															AS '<div align="center" class="w3-muhle-text-11">Notas</div>',
				'<div align="left" class="w3-muhle-text-11">'+ CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 
					'Sin Consultor' ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END /*+
					'<span style="font-size:11px;color:blue;text-align: left" title="Observador">'+ISNULL(A.OBSERVADOR,'')+'</span>'*/+'</div>'	AS '<div align="left" class="w3-muhle-text-11">Consultores</div>',
				'<div align="left" class="w3-muhle-text-11">'+ISNULL(A.OBSERVADOR,'')+'</div>'													AS '<div align="left" class="w3-muhle-text-11">Observaciones</div>',--OBS
				'<div align="center" class="w3-muhle-text-11">'+ 
					'<i class="fas fa-flag w3-medium" style="cursor:pointer;color:'+CASE WHEN A.ESTADO = 'C' THEN 'green' ELSE 'yellow' END+'" title="'+CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' ELSE 'Pendiente' END+'" onclick="return false;"></i>' + '&nbsp;' +
					'<i class="fas fa-calendar-alt w3-medium" style="cursor:pointer;" title="Ver Agenda" onclick="almacenarSeleccion(''TAB'',''1'');
																												 almacenarSeleccion(''TAB_SERV'',''1'');
																												 almacenarSeleccion(''TAB_AGENDA'',''0'');
																												 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,A.ID_CLIENTE)+ ''');
																												 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');
																												 almacenarSeleccion(''PROYECTO_SERV_ID'','''+CONVERT(VARCHAR,PS.ID_PROYECTO_SERVICIO)+''');
																												 almacenarSeleccion(''AGENDA_ID'','''+cast(A.ID_AGENDA as varchar)+''');
																												 goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>'
				+'</div>'																														AS '<div align="center" class="w3-muhle-text-11">Ver</div>'
			FROM	LK_AGENDA A
					--INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
					INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
					INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
					LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
			WHERE	((A.FECHA >= @VFECHA_DESDE) or (@VFECHA_DESDE BETWEEN A.FECHA AND A.FECHA_HASTA))
			AND		A.FECHA <= @VFECHA_HASTA
			--AND		CONVERT(VARCHAR,A.ID_CLIENTE) = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE CONVERT(VARCHAR,A.ID_CLIENTE) END
			AND		A.ID_CLIENTE = CASE WHEN NULLIF(ISNULL(@VF_CLIENTE,''),'') <> '' THEN ISNULL(@VF_CLIENTE,'') ELSE A.ID_CLIENTE END
			--AND		CONVERT(VARCHAR,A.ID_PROYECTO) = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE CONVERT(VARCHAR,A.ID_PROYECTO) END
			AND		A.ID_PROYECTO = CASE WHEN NULLIF(ISNULL(@VF_PROYECTO,''),'') <> '' THEN ISNULL(@VF_PROYECTO,'') ELSE A.ID_PROYECTO END
			--AND		CONVERT(VARCHAR,A.ID_SERVICIO) = CASE WHEN @VF_SERVICIO <> '' THEN @VF_SERVICIO ELSE CONVERT(VARCHAR,A.ID_SERVICIO) END 
			AND		A.ID_SERVICIO = CASE WHEN NULLIF(ISNULL(@VF_SERVICIO,''),'') <> '' THEN ISNULL(@VF_SERVICIO,'') ELSE A.ID_SERVICIO END 
			--AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			ORDER BY A.FECHA
	END
 
	IF (@VSOLAPA = 'PROYECTO') BEGIN
		
		IF (@VF_ESTADO = '') BEGIN --todos los proyectos en curso o confirmados--
 
			SELECT	'<div align="center" class="w3-muhle-text-11">' +
					'<i class="fas fa-street-view w3-medium" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,P.ID_CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 	
					+ '</div>'																										AS '<div align="center" class="w3-muhle-text-11"></div>',
					'<div align="left" class="w3-muhle-text-11">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'								AS '<div align="left" class="w3-muhle-text-11">Cliente</div>', 
					'<div align="left" class="w3-muhle-text-11">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'							AS '<div align="left" class="w3-muhle-text-11">Proyecto</div>',
					'<div align="center" class="w3-muhle-text-11">'+
						CASE WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Alto' THEN
								'<div class="w3-center w3-muhle-text-11 w3-red">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
							 WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Medio' THEN
								'<div class="w3-center w3-muhle-text-11 w3-yellow">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
							 WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Bajo' THEN
								'<div class="w3-center w3-muhle-text-11 w3-green">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11 w3-gray">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
						END + '</div>'																								AS '<div align="center" class="w3-muhle-text-11">Riesgo</div>',
					'<div align="center" class="w3-muhle-text-11">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'					AS '<div align="center" class="w3-muhle-text-11">Estado</div>',  
					'<div align="center" class="w3-muhle-text-11">'+
						'<i class="fas fa-info-circle w3-medium" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div align="center" class="w3-muhle-text-11">Normas</div>',
					--'<div class="w3-center">'+
					--	'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE P.OBSERVACIONES END +'"></i>'
					--+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					'<div align="center" class="w3-muhle-text-11">'+
						'<i class="fas fa-user-tie w3-medium" style="cursor:pointer;color:blue;" title="'+ISNULL(P.OBSERVACIONES,'')+'"></i>'
					+'</div>'																										AS '<div align="center" class="w3-muhle-text-11">AC</div>',
					'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'				AS '<div align="center" class="w3-muhle-text-11">Inicio</div>', 
					'<div align="center" class="w3-muhle-text-11">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Fin</div>',
					'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Horas</div>',
					'<div align="center" class="w3-muhle-text-11">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Servicios</div>'
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
			WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
			AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
			ORDER BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(DATETIME,P.FECHA_INICIO_REAL,103)  DESC
 
		END ELSE BEGIN
		
			SELECT	'<div align="center" class="w3-muhle-text-11">' +
					'<i class="fas fa-street-view w3-medium" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,P.ID_CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 	
					+ '</div>'																										AS '<div align="center" class="w3-muhle-text-11"></div>',
					'<div align="left" class="w3-muhle-text-11">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'								AS '<div align="left" class="w3-muhle-text-11">Cliente</div>', 
					'<div align="left" class="w3-muhle-text-11">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'							AS '<div align="left" class="w3-muhle-text-11">Proyecto</div>',
					'<div align="center" class="w3-muhle-text-11">'+
						CASE WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Alto' THEN
								'<div class="w3-center w3-muhle-text-11 w3-red">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
							 WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Medio' THEN
								'<div class="w3-center w3-muhle-text-11 w3-yellow">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
							 WHEN ISNULL(P.NIVEL_RIESGO,'N/A') = 'Bajo' THEN
								'<div class="w3-center w3-muhle-text-11 w3-green">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11 w3-gray">'+ISNULL(P.NIVEL_RIESGO,'N/A')+'</div>'
						END + '</div>'																								AS '<div align="center" class="w3-muhle-text-11">Riesgo</div>',
					'<div align="center" class="w3-muhle-text-11">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'					AS '<div align="center" class="w3-muhle-text-11">Estado</div>',  
					'<div align="center" class="w3-muhle-text-11">'+
						'<i class="fas fa-info-circle w3-medium" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div align="center" class="w3-muhle-text-11">Normas</div>',
					--'<div class="w3-center">'+
					--	'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE P.OBSERVACIONES END +'"></i>'
					--+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					'<div align="center" class="w3-muhle-text-11">'+
						'<i class="fas fa-user-tie w3-medium" style="cursor:pointer;color:blue;" title="'+ISNULL(P.OBSERVACIONES,'')+'"></i>'
					+'</div>'																										AS '<div align="center" class="w3-muhle-text-11">AC</div>',
					'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'				AS '<div align="center" class="w3-muhle-text-11">Inicio</div>', 
					'<div align="center" class="w3-muhle-text-11">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Fin</div>',
					'<div align="center" class="w3-muhle-text-11">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Horas</div>',
					'<div align="center" class="w3-muhle-text-11">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div align="center" class="w3-muhle-text-11">Servicios</div>'
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
			WHERE	P.ESTADO_PROYECTO_TOTAL = @VF_ESTADO
			AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
			AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
			AND		P.FECHA_FIN_REAL >= @VFECHA_DESDE
			AND		P.FECHA_FIN_REAL <= @VFECHA_HASTA
			ORDER BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(DATETIME,P.FECHA_INICIO_REAL,103)  DESC
 
		END
	END
 
END
