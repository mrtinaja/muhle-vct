CREATE PROCEDURE [dbo].[HOME_GRD_INICIO_PLANIF_BKP]
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
		SELECT	'<div class="w3-center" style="font-size:15px">'+
					CASE WHEN ISNULL(A.INDICADOR_HR,'R') = 'R' THEN	
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:red;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'N' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'A' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'V' THEN
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:green;" title="Indicador"></i>'
						WHEN ISNULL(A.INDICADOR_HR,'R') = 'C' THEN	
						'<i class="fas fa-circle w3-large" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
					END	+ '</div>'																												AS '<div class="w3-center" style="font-size:13px"></div>',
				'<div class="w3-left" style="font-size:13px">'+[dbo].[FN_GET_AGENDA_CLIENTE] (A.ID_AGENDA)+ '</div>'							AS '<div class="w3-left" style="font-size:13px">Cliente</div>', --CLIENTE
				'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF + ' - ' + '<b>'+ISNULL(ps.NOMBRE,'')+'<b></div>'	AS '<div class="w3-left" style="font-size:13px">Proyecto</div>', --PROYECTO
				'<div class="w3-center">'+
					CASE WHEN ISNULL(A.OBSERV_CALIF,'') <> '' THEN 
					'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:red;" title="Obs. Calificación:&nbsp;'+ ISNULL(A.OBSERV_CALIF,'') +'"></i>&nbsp;' ELSE '' END+
					CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') <> '' THEN
					'<i class="fas fa-clipboard-check w3-large" style="cursor:pointer;color:blue;" title="Obs. Logística:&nbsp;'+ ISNULL(A.OBSERV_LOGISTICA,'') +'"></i>&nbsp;' ELSE '' END+
					CASE WHEN ISNULL(DOC.OBSERVACIONES,'') <> '' THEN
					'<i class="fas fa-clipboard w3-large" style="cursor:pointer;color:green;" title="Obs. Hoja Ruta:&nbsp;'+ ISNULL(DOC.OBSERVACIONES,'') +'"></i>&nbsp;' ELSE '' END + '
				</div>'																													AS '<div class="w3-center" style="font-size:13px">Observ.</div>',--OBS
				'<div class="w3-center">'+
				'<i class="' + 
					CASE	WHEN A.ID_SERVICIO = '1' THEN 'fas fa-user-tie w3-large"'
							WHEN A.ID_SERVICIO = '2' THEN 'fas fa-chalkboard-teacher w3-large"'
							WHEN A.ID_SERVICIO = '3' THEN 'fas fa-user-graduate w3-large"' END +
								'style="cursor:pointer;" title="'+	CASE WHEN A.ID_SERVICIO = '1' THEN 
																			'Consultoria"'
																		WHEN A.ID_SERVICIO = '2' THEN 
																			'Auditoria"'
																		WHEN A.ID_SERVICIO = '3' THEN 
																			'Capacitacion"' 
																	END + '></i>'+'</div>'																							AS '<div class="w3-center" style="font-size:13px">Servicio</div>', --SERVICIO
				'<div class="w3-center" style="font-size:13px">'+ 
					'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMA,''),'</br>',char(10))+'"></i>'
				+'</div>'	AS '<div class="w3-center" style="font-size:13px">Normas</div>', --NORMA
				'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA,103) +'</div>'																				AS '<div class="w3-center" style="font-size:13px">Desde</div>', --FECHA DESDE
				'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA_HASTA,103) +'</div>'																		AS '<div class="w3-center" style="font-size:13px">Hasta</div>', --FECHA HASTA
				'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,ISNULL(A.DIAS,'')) +'</div>'																		AS '<div class="w3-center" style="font-size:13px">Días</div>',
				'<div class="w3-center" style="font-size:13px">'+ DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) +'</div>'																	AS '<div class="w3-center" style="font-size:13px">Horas</div>',
				'<div class="w3-left" style="font-size:13px">'+ CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 
					'Sin Consultor' ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END +
					'<span style="font-size:13px;color:blue;text-align: left" title="Observador">'+ISNULL(A.OBSERVADOR,'')+'</span>'+'</div>'										AS '<div class="w3-left" style="font-size:13px">Profesionales</div>',
				'<div class="w3-center">'+ 
					'<i class="fas fa-calendar-alt w3-large" style="cursor:pointer;" title="Ver Agenda" onclick="almacenarSeleccion(''TAB'',''1'');
																												 almacenarSeleccion(''TAB_SERV'',''1'');
																												 almacenarSeleccion(''TAB_AGENDA'',''0'');
																												 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,A.ID_CLIENTE)+ ''');
																												 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');
																												 almacenarSeleccion(''PROYECTO_SERV_ID'','''+CONVERT(VARCHAR,PS.ID_PROYECTO_SERVICIO)+''');
																												 almacenarSeleccion(''AGENDA_ID'','''+cast(A.ID_AGENDA as varchar)+''');
																												 goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>'
				+'</div>'																																							AS '<div class="w3-center" style="font-size:13px">Ver</div>'
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
 
			/*SELECT	'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-street-view w3-large" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,A.CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,A.PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 
					+ '</div>'																										AS '<div class="w3-left" style="font-size:13px"></div>',
					'<div class="w3-left" style="font-size:13px">'+A.RAZON_SOCIAL+ '</div>'											AS '<div class="w3-left" style="font-size:13px">Cliente</div>', 
					'<div class="w3-left" style="font-size:13px">'+'('+A.CODIGO+') - '+A.NORMA_REF+ '</div>'						AS '<div class="w3-left" style="font-size:13px">Proyecto</div>',
					'<div class="w3-center" style="font-size:13px">'+ISNULL(A.ESTADO,'Sin Estado')+ '</div>'						AS '<div class="w3-center" style="font-size:13px">Estado</div>', 
					'<div class="w3-center" style="font-size:13px">'+
						'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div class="w3-center" style="font-size:13px">Normas</div>',
					'<div class="w3-center">'+
						'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(A.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERVACIONES END +'"></i>'
					+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					+'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,A.FECHA_INICIO,103)+ '</div>'					AS '<div class="w3-center" style="font-size:13px">Inicio</div>', 
					'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(A.FECHA_FIN,'') = '' THEN '' ELSE CONVERT(VARCHAR,A.FECHA_FIN,103) END+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Fin</div>',
					'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,A.HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', A.PROYECTO, NULL, NULL)+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Horas</div>',
					'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (A.PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Servicios</div>'
			FROM	(
					SELECT	DISTINCT P.ID_CLIENTE		AS CLIENTE,
							P.ID_PROYECTO				AS PROYECTO,
							CLI.RAZON_SOCIAL_CLIENTE	AS RAZON_SOCIAL,
							P.CODIGO					AS CODIGO,
							P.NORMA_REF					AS NORMA_REF,
							P.NORMAS					AS NORMAS,
							CD.CAT_DATA_DESC			AS ESTADO,
							P.OBSERVACIONES				AS OBSERVACIONES,
							P.FECHA_INICIO_REAL			AS FECHA_INICIO,
							P.FECHA_FIN_REAL			AS FECHA_FIN,
							P.TOTAL_HORAS_PROYECTADAS	AS HORAS_PROYECTADAS
					FROM	LK_PROYECTO P
							INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
							LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
					AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
					AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
					) A
			ORDER BY A.RAZON_SOCIAL,CONVERT(DATETIME,FECHA_INICIO,103)  DESC*/
 
			SELECT	'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-street-view w3-large" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,P.ID_CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 
					+ '</div>'																										AS '<div class="w3-left" style="font-size:13px"></div>',
					'<div class="w3-left" style="font-size:13px">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'								AS '<div class="w3-left" style="font-size:13px">Cliente</div>', 
					'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'						AS '<div class="w3-left" style="font-size:13px">Proyecto</div>',
					'<div class="w3-center" style="font-size:13px">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'				AS '<div class="w3-center" style="font-size:13px">Estado</div>', 
					'<div class="w3-center" style="font-size:13px">'+
						'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div class="w3-center" style="font-size:13px">Normas</div>',
					--'<div class="w3-center">'+
					--	'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE P.OBSERVACIONES END +'"></i>'
					--+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					'<div class="w3-center">'+
						'<i class="fas fa-user-tie w3-large" style="cursor:pointer;color:blue;" title="'+ISNULL(P.OBSERVACIONES,'')+'"></i>'
					+'</div>'																										AS '<div class="w3-center" style="font-size:13px">AC</div>',
					+'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'			AS '<div class="w3-center" style="font-size:13px">Inicio</div>', 
					'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Fin</div>',
					'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Horas</div>',
					'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Servicios</div>'
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
			WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
			AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
			ORDER BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(DATETIME,P.FECHA_INICIO_REAL,103)  DESC
 
		END ELSE BEGIN
		
			/*SELECT	'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-street-view w3-large" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,A.CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,A.PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 
					+ '</div>'																										AS '<div class="w3-left" style="font-size:13px"></div>',
					'<div class="w3-left" style="font-size:13px">'+A.RAZON_SOCIAL+ '</div>'											AS '<div class="w3-left" style="font-size:13px">Cliente</div>', 
					'<div class="w3-left" style="font-size:13px">'+'('+A.CODIGO+') - '+A.NORMA_REF+ '</div>'						AS '<div class="w3-left" style="font-size:13px">Proyecto</div>',
					'<div class="w3-center" style="font-size:13px">'+ISNULL(A.ESTADO,'Sin Estado')+ '</div>'						AS '<div class="w3-center" style="font-size:13px">Estado</div>', 
					'<div class="w3-center" style="font-size:13px">'+
						'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div class="w3-center" style="font-size:13px">Normas</div>',
					'<div class="w3-center">'+
						'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(A.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERVACIONES END +'"></i>'
					+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,A.FECHA_INICIO,103)+ '</div>'					AS '<div class="w3-center" style="font-size:13px">Inicio</div>', 
					'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(A.FECHA_FIN,'') = '' THEN '' ELSE CONVERT(VARCHAR,A.FECHA_FIN,103) END+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Fin</div>', 
					'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,A.HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', A.PROYECTO, NULL, NULL)+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Horas</div>',
					'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (A.PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Servicios</div>'
			FROM	(
					SELECT	DISTINCT P.ID_CLIENTE		AS CLIENTE,
							P.ID_PROYECTO				AS PROYECTO,
							CLI.RAZON_SOCIAL_CLIENTE	AS RAZON_SOCIAL,
							P.CODIGO					AS CODIGO,
							P.NORMA_REF					AS NORMA_REF,
							P.NORMAS					AS NORMAS,
							CD.CAT_DATA_DESC			AS ESTADO,
							P.OBSERVACIONES				AS OBSERVACIONES,
							P.FECHA_INICIO_REAL			AS FECHA_INICIO,
							P.FECHA_FIN_REAL			AS FECHA_FIN,
							P.TOTAL_HORAS_PROYECTADAS	AS HORAS_PROYECTADAS
					FROM	LK_PROYECTO P
							INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
							LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					WHERE	P.ESTADO_PROYECTO_TOTAL = @VF_ESTADO
					AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
					AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
					AND		P.FECHA_FIN_REAL >= @VFECHA_DESDE
					AND		P.FECHA_FIN_REAL <= @VFECHA_HASTA) A
			ORDER BY A.RAZON_SOCIAL,CONVERT(DATETIME,FECHA_FIN,103) DESC*/
 
			SELECT	'<div class="w3-center" style="font-size:13px">'+
					'<i class="fas fa-street-view w3-large" style="cursor:pointer;color:#FFBF00;" title="Vista 360" 
						onclick="almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''CLIENTE'','''+CONVERT(VARCHAR,P.ID_CLIENTE)+ ''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,P.ID_PROYECTO)+''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>' 
					+ '</div>'																										AS '<div class="w3-left" style="font-size:13px"></div>',
					'<div class="w3-left" style="font-size:13px">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'								AS '<div class="w3-left" style="font-size:13px">Cliente</div>', 
					'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'						AS '<div class="w3-left" style="font-size:13px">Proyecto</div>',
					'<div class="w3-center" style="font-size:13px">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'				AS '<div class="w3-center" style="font-size:13px">Estado</div>', 
					'<div class="w3-center" style="font-size:13px">'+
						'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'"></i>' 
					+ '</div>'																										AS '<div class="w3-center" style="font-size:13px">Normas</div>',
					--'<div class="w3-center">'+
					--	'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" title="'+'Observaciones:&nbsp;'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE P.OBSERVACIONES END +'"></i>'
					--+'</div>'																										AS '<div class="w3-center" style="font-size:13px">Obs</div>',--OBS
					'<div class="w3-center">'+
						'<i class="fas fa-user-tie w3-large" style="cursor:pointer;color:blue;" title="'+ISNULL(P.OBSERVACIONES,'')+'"></i>'
					+'</div>'																										AS '<div class="w3-center" style="font-size:13px">AC</div>',
					+'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'			AS '<div class="w3-center" style="font-size:13px">Inicio</div>', 
					'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Fin</div>',
					--'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Horas</div>'
					'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'I')+ '</div>'	AS '<div class="w3-center" style="font-size:13px">Servicios</div>'
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
