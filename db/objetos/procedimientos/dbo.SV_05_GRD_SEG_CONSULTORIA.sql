 
CREATE PROCEDURE [dbo].[SV_05_GRD_SEG_CONSULTORIA]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME
 
BEGIN	
 
	SELECT	@VFECHA_DESDE = ISNULL(FECHA_DESDE,''),
			@VFECHA_HASTA = ISNULL(FECHA_HASTA,'')
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VFECHA_DESDE = '') BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Desde</div>'  AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
	END
 
	IF (@VFECHA_HASTA = '') BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
	END
 
	IF (@VFECHA_DESDE > @VFECHA_HASTA) BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">La Fecha Desde debe ser Igual o Mayor a la Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-12">Mensaje</div>'
 
	END ELSE BEGIN
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+T.CLIENTE+'</div>'				AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.FECHA_INICIO+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Fecha Inicio</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.FECHA_FIN+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Fin</div>',
				'<div class="w3-left w3-muhle-text-11">'+T.PROYECTO +'</div>'			AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
				'<div class="w3-left w3-muhle-text-11">'+T.PERSONAL	+'</div>'			AS '<div class="w3-left w3-muhle-text-11">Personal Afectado</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.HORAS_PROY_SERVICIO+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Hs Proy. Servicio</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.HORAS_EJEC_SERVICIO +'</div>'	AS '<div class="w3-center w3-muhle-text-11">Hs Ejec. Servicio Periodo</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.PORC_AVANCE+'</div>'			AS '<div class="w3-center w3-muhle-text-11">% Avance Periodo</div>',
				'<div class="w3-left w3-muhle-text-11">'+T.FRECUENCIA_ENV_PLAN	+'</div>'	AS '<div class="w3-left w3-muhle-text-11">Frecuencia Envio Plan</div>',
				'<div class="w3-center w3-muhle-text-11">'+T.FECHA_PLAN +'</div>'			AS '<div class="w3-center w3-muhle-text-11">Plan Estrategico</div>',
				'<div class="w3-left w3-muhle-text-11">'+T.OBSERVACIONES+'</div>'			AS '<div class="w3-left w3-muhle-text-11">Observaciones</div>',
				--minuta cierre servicio
				'<div class="w3-center w3-muhle-text-11">'+T.MINUTA_CIERRE_SERV+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Minuta Cierre Servicio</div>'
		FROM	(		
		SELECT	CLI.RAZON_SOCIAL_CLIENTE													AS CLIENTE,
				CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103)									AS FECHA_INICIO,
				CONVERT(VARCHAR,PS.FECHA_FIN_REAL,103)										AS FECHA_FIN,
				'('+P.CODIGO+') - '+P.NORMA_REF+'<b> - '+  ISNULL(PS.NOMBRE,'') + '</b>'	AS PROYECTO,
				CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN 
					'Sin Consultores'
				ELSE 
					[dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) 
				END																			AS PERSONAL,
				CONVERT(VARCHAR,ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0))						AS HORAS_PROY_SERVICIO,
				CONVERT(VARCHAR,[dbo].[FN_GET_TOTAL_HS_EJEC_PERIODO] (PS.ID_PROYECTO_SERVICIO, @VFECHA_DESDE , @VFECHA_HASTA))	AS HORAS_EJEC_SERVICIO,
				CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) = 0 THEN 
					'0' 
				ELSE
					CONVERT(VARCHAR,[dbo].[FN_GET_TOTAL_HS_EJEC_PERIODO] (PS.ID_PROYECTO_SERVICIO, @VFECHA_DESDE , @VFECHA_HASTA) * 100 / ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0))
				END																												AS PORC_AVANCE,
				UPPER(SUBSTRING(PS.FRECUENCIA_ENVIO,1,1))+LOWER(SUBSTRING(PS.FRECUENCIA_ENVIO,2,LEN(PS.FRECUENCIA_ENVIO)))		AS FRECUENCIA_ENV_PLAN,
				CONVERT(VARCHAR,MAX(PE.FECHA),103)																				AS FECHA_PLAN,
				ISNULL(DOC.OBSERVACIONES,'')																					AS OBSERVACIONES,
				--minuta cierre servicio
				CASE WHEN ISNULL(PS.CIERRE,'NO') = 'NO' THEN 'En Curso' ELSE CONVERT(VARCHAR,MC.FECHA,103) END					AS MINUTA_CIERRE_SERV
		FROM	LK_PROYECTO P
				INNER JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
				INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
				LEFT JOIN (SELECT	PS.ID_PROYECTO_SERVICIO IDPS, MAX(FECHA_DOCUM) FECHA
							FROM	LK_PROYECTO_SERVICIO PS
									LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID AND PD.TIPO = 'PE'
							GROUP BY PS.ID_PROYECTO_SERVICIO) PE ON PS.ID_PROYECTO_SERVICIO = PE.IDPS
				LEFT JOIN (SELECT	PS.ID_PROYECTO_SERVICIO IDPS, MAX(FECHA_DOCUM) FECHA
									FROM	LK_PROYECTO_SERVICIO PS
									LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID AND PD.TIPO = 'MC'
									GROUP BY ID_PROYECTO_SERVICIO ) MC ON PS.ID_PROYECTO_SERVICIO = MC.IDPS
				LEFT JOIN LK_PROYECTO_DOCUM DOC ON (PE.IDPS = DOC.PROYECTO_SERV_ID) AND DOC.TIPO = 'PE' AND FECHA_DOCUM = PE.FECHA
		WHERE	PS.FECHA_INICIO_REAL <= @VFECHA_HASTA 
		AND		PS.FECHA_FIN_REAL	 >= @VFECHA_DESDE
		AND		PS.ID_TIPO_SERVICIO = '1' --CONSULTORIAS
		GROUP BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103),'('+P.CODIGO+') - '+P.NORMA_REF+'<b> - '+  ISNULL(PS.NOMBRE,'') + '</b>',
				 CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN 
					'Sin Consultores'
				 ELSE [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) END,
				 PS.TOTAL_HORAS_PROYECTADAS, [dbo].[FN_GET_TOTAL_HS_EJEC_PERIODO] (PS.ID_PROYECTO_SERVICIO, @VFECHA_DESDE , @VFECHA_HASTA), PS.FRECUENCIA_ENVIO,PS.FECHA_FIN_REAL,
				 CASE WHEN ISNULL(PS.CIERRE,'NO') = 'NO' THEN 'En Curso' ELSE CONVERT(VARCHAR,MC.FECHA,103) END, DOC.OBSERVACIONES) T
		ORDER BY T.CLIENTE, T.PROYECTO, T.FECHA_FIN
 
		/*
		SELECT --ps.ID_PROYECTO_SERVICIO,	
				CLI.RAZON_SOCIAL_CLIENTE					AS '<font size="2">Cliente</font>',
				CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103)	AS '<font size="2">Fecha Inicio</font>',
				CONVERT(VARCHAR,PS.FECHA_FIN_REAL,103)		AS '<font size="2">Fecha Fin</font>',
				P.NORMA_REF									AS '<font size="2">Descripcion Actividad</font>',
				CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Sin Consultores</font>'
				ELSE [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) END AS '<font size="2">Personal Afectado</font>',
				--[dbo].[FN_GET_SERVICIO_VISITAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO) AS '<font size="2">Total Visitas</font>',
				ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)		AS '<font size="2">Hs Proyectadas</font>',
				ISNULL(PS.TOTAL_HORAS_EJECUTADAS,0)			AS '<font size="2">Hs Ejecutadas Proyecto</font>',
				AGD.HS_EJEC_V						AS '<font size="2">Hs Ejecutadas Periodo</font>',
				ISNULL(PS.PORCENTAJE_AVANCE,0)				AS '<font size="2">% Avance</font>',
				UPPER(SUBSTRING(PS.FRECUENCIA_ENVIO,1,1))+LOWER(SUBSTRING(PS.FRECUENCIA_ENVIO,2,LEN(PS.FRECUENCIA_ENVIO)))	AS '<font size="2">Frecuencia Envio Plan</font>',
				CONVERT(VARCHAR,MAX(DOC.FECHA),103)			AS '<font size="2">Plan Estrategico</font>',
				'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+ISNULL(DOC.OBSERVACIONES,'')+'</font>'	AS '<font size="2">Observaciones</font>',
				--minuta cierre servicio
				CASE WHEN ISNULL(PS.CIERRE,'NO') = 'NO' THEN 'En Curso' ELSE CONVERT(VARCHAR,MI.FECHA,103) END AS '<font size="2">Minuta Cierre Servicio</font>'
		FROM	LK_PROYECTO P
				INNER JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
				INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
				LEFT JOIN (SELECT	PS.ID_PROYECTO PROYECTO, FECHA_DOCUM FECHA, PD.OBSERVACIONES
							FROM	LK_PROYECTO_SERVICIO PS
									LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID
							WHERE	PD.TIPO = 'PE') DOC ON P.ID_PROYECTO = DOC.PROYECTO
				LEFT JOIN (SELECT	PS.ID_PROYECTO PROYECTO, FECHA_DOCUM FECHA, PD.OBSERVACIONES
							FROM	LK_PROYECTO_SERVICIO PS
									LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID
							WHERE	PD.NRO_DOCUM_INTERNO = 'MC') MI ON P.ID_PROYECTO = DOC.PROYECTO
				LEFT JOIN ( SELECT PS.ID_PROYECTO, SUM(ISNULL(A.DIAS,0)*8) as HS_EJEC_V
							FROM LK_PROYECTO_SERVICIO PS
							LEFT JOIN LK_AGENDA A ON A.PROYECTO_SERV_ID= PS.ID_PROYECTO_SERVICIO
							WHERE A.FECHA >= @VFECHA_DESDE AND A.FECHA_HASTA  <= @VFECHA_HASTA
							AND		PS.ID_TIPO_SERVICIO = '1'
							GROUP BY PS.ID_PROYECTO) AGD ON  P.ID_PROYECTO = AGD.ID_PROYECTO
		WHERE	(PS.FECHA_INICIO_REAL <= @VFECHA_HASTA AND PS.FECHA_FIN_REAL >= @VFECHA_DESDE)
		--(PS.FECHA_INICIO_REAL <= @VFECHA_DESDE OR PS.FECHA_FIN_REAL >= @VFECHA_HASTA)  
		AND		PS.ID_TIPO_SERVICIO = '1' --CONSULTORIAS
		AND		AGD.HS_EJEC_V>0
		GROUP BY CLI.RAZON_SOCIAL_CLIENTE,CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103),P.NORMA_REF,
				 CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Sin Consultores</font>'
				ELSE [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) END,
				 --[dbo].[FN_GET_SERVICIO_VISITAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO),
				 PS.TOTAL_HORAS_PROYECTADAS,PS.TOTAL_HORAS_EJECUTADAS,AGD.HS_EJEC_V, PS.PORCENTAJE_AVANCE,
				 PS.FRECUENCIA_ENVIO,PS.FECHA_FIN_REAL,CASE WHEN ISNULL(PS.CIERRE,'NO') = 'NO' THEN 'En Curso' ELSE CONVERT(VARCHAR,MI.FECHA,103) END,DOC.OBSERVACIONES
		ORDER BY [<font size="2">Fecha Fin</font>]
		*/
	END
END
