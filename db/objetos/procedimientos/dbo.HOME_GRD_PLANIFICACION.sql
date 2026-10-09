CREATE PROCEDURE [dbo].[HOME_GRD_PLANIFICACION]
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
		SELECT	'<td colspan="13" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick" data-fill-color="D8E4BC"><b>Desde: '+CONVERT(VARCHAR,@VFECHA_DESDE,103)+' - Hasta: '+CONVERT(VARCHAR,@VFECHA_HASTA,103)+'</b></td>' as 'title=Planificación;data-cols-width="50,80,50,20,15,15,10,10,15,50,100,80,80";data-f-name="Calibri";data-f-sz="26"', '' as "2", '' as "3",'' as "4",'' as "5", '' as "6",'' as "7", '' as "8", '' as "9", '' as "10", '' as "11", '' as "12", '' as "13"
		UNION ALL
		SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Cliente</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Proyecto</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Normas</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Servicio</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Desde</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Hasta</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Días</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Horas</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Estado</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Consultores</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Observaciones</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Obs Calificacion</b></td>',
				'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Obs Hoja Ruta</b></td>'
		UNION ALL
		SELECT	*
		FROM	(
				SELECT	TOP 10000 
						'<div class="w3-left" style="font-size:13px">'+[dbo].[FN_GET_AGENDA_CLIENTE] (A.ID_AGENDA) + '</div>'	AS CLIENTE, --CLIENTE
						'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF + ' - ' + '<b>'+ISNULL(ps.NOMBRE,'')+'<b></div>' AS PROYECTO, --PROYECTO
						'<div class="w3-center" style="font-size:13px">'+ REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMA,''),'</br>',char(10))+'</div>'	AS NORMAS, --NORMAS
						'<div class="w3-center" style="font-size:13px">'+CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END + '</div>'	AS SERVICIO,
						'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA,103) +'</div>'	AS DESDE, --FECHA DESDE
						'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA_HASTA,103) +'</div>'	AS HASTA, --FECHA HASTA
						'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,ISNULL(A.DIAS,'')) +'</div>'	AS DIAS,
						'<div class="w3-center" style="font-size:13px">'+ DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) +'</div>'	AS HORAS,
						'<div class="w3-center" style="font-size:13px">'+ CASE WHEN A.ESTADO = 'P' THEN 'Pendiente' WHEN A.ESTADO = 'C' THEN 'Confirmado' ELSE 'Sin Estado' END +'</div>'	AS ESTADO,
						'<div class="w3-left" style="font-size:13px">'+ CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 
							'Sin Consultor' ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END AS CONSULTORES, --consultores
						'<div class="w3-left" style="font-size:13px">'+CASE WHEN ISNULL(A.OBSERVADOR,'') = '' THEN '' ELSE A.OBSERVADOR END+'</div>'	AS OBS,
						'<div class="w3-left" style="font-size:13px">'+CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN '' ELSE A.OBSERV_CALIF END+'</div>'	AS OBS_CALIF,
						--'<div class="w3-left" style="font-size:13px">'+CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN '' ELSE A.OBSERV_LOGISTICA END+'</div>'	AS OBS_LOG,
						'<div class="w3-left" style="font-size:13px">'+CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN '' ELSE DOC.OBSERVACIONES END+'</div>'		AS OBS_HR
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
					AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
					ORDER BY A.FECHA) A
	END
 
	IF (@VSOLAPA = 'PROYECTO') BEGIN
		
		IF (@VF_ESTADO = '') BEGIN --todos los proyectos en curso o confirmados--
			
			SELECT	'<td colspan="10" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick" data-fill-color="D8E4BC"><b>Estado: En Curso / Confirmado</b></td>' as 'title=Proyectos;data-cols-width="50,80,15,15,30,15,15,15,15,25";data-f-name="Calibri";data-f-sz="26"', '' as "2", '' as "3",'' as "4",'' as "5", '' as "6",'' as "7", '' as "8", '' as "9", '' as "10"
			UNION ALL
			SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Cliente</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Proyecto</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Riesgo</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Estado</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Normas</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Analista a Cargo</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Inicio</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fin</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Horas</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Servicios</b></td>'
			UNION ALL
			SELECT	*
			FROM	(
					SELECT	TOP 10000	'<div class="w3-left" style="font-size:13px">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'	AS RAZON_SOCIAL, 
							'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'	AS PROYECTO,
							'<div class="w3-center" style="font-size:13px">'+ISNULL(P.NIVEL_RIESGO,'N/A')+ '</div>'	AS RIESGO,
							'<div class="w3-center" style="font-size:13px">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'	AS ESTADO, 
							'<div class="w3-center" style="font-size:13px">'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'</div>'	AS NORMAS,
							'<div class="w3-center">'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN '' ELSE P.OBSERVACIONES END +'</div>'	AS OBS,--OBS
							'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'	AS INICIO, 
							'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS FIN, 
							'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>' AS HORAS,
							'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'D')+ '</div>'	AS SERVICIOS
					FROM	LK_PROYECTO P
							INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
							LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
					AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
					AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
					ORDER BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(DATETIME,P.FECHA_INICIO_REAL,103)  DESC) A
 
		END ELSE BEGIN
			
			SELECT	'<td colspan="10" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick" data-fill-color="D8E4BC"><b>Estado: '+ISNULL(@VF_ESTADO,'')+'</b></td>' as 'title=Proyectos;data-cols-width="50,80,15,15,30,15,15,15,15,25";data-f-name="Calibri";data-f-sz="26"', '' as "2", '' as "3",'' as "4",'' as "5", '' as "6",'' as "7", '' as "8", '' as "9", '' as "10"
			UNION ALL
			SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Cliente</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Proyecto</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Riesgo</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Estado</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Normas</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Observaciones</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Inicio</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fin</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Horas</b></td>',
					'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Servicios</b></td>'
			UNION ALL
			SELECT	*
			FROM	(
					SELECT	TOP 10000	'<div class="w3-left" style="font-size:13px">'+CLI.RAZON_SOCIAL_CLIENTE+ '</div>'	AS CLIENTE, 
							'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF+ '</div>'	AS PROYECTO,
							'<div class="w3-center" style="font-size:13px">'+ISNULL(P.NIVEL_RIESGO,'N/A')+ '</div>'	AS RIESGO,
							'<div class="w3-center" style="font-size:13px">'+ISNULL(CD.CAT_DATA_DESC,'Sin Estado')+ '</div>'	AS ESTADO, 
							'<div class="w3-center" style="font-size:13px">'+REPLACE(dbo.FN_GET_NORMA_HTML('',P.NORMAS,''),'</br>',char(10))+'</div>'	AS NORMAS,
							'<div class="w3-center">'+CASE WHEN ISNULL(P.OBSERVACIONES,'') = '' THEN '' ELSE P.OBSERVACIONES END +'</div>'	AS OBS,--OBS
							'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)+ '</div>'	AS INICIO, 
							'<div class="w3-center" style="font-size:13px">'+CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END+ '</div>'	AS FIN, 
							'<div class="w3-center" style="font-size:13px">'+CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', P.ID_PROYECTO, NULL, NULL)+ '</div>' AS HORAS,
							'<div class="w3-center" style="font-size:13px">'+[dbo].[FN_GET_SERVICIOS_PROY] (P.ID_PROYECTO, @FORM_ID, 'D')+ '</div>'	AS SERVICIOS
					FROM	LK_PROYECTO P
							INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
							LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					WHERE	P.ESTADO_PROYECTO_TOTAL = @VF_ESTADO
					AND		P.ID_CLIENTE = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE P.ID_CLIENTE END
					AND		P.ID_PROYECTO = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE P.ID_PROYECTO END
					AND		P.FECHA_FIN_REAL >= @VFECHA_DESDE
					AND		P.FECHA_FIN_REAL <= @VFECHA_HASTA
					ORDER BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(DATETIME,P.FECHA_FIN_REAL,103) DESC) A
		END
	END
END
 
