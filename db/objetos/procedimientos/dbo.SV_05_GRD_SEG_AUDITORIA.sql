 
CREATE PROCEDURE [dbo].[SV_05_GRD_SEG_AUDITORIA]
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
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+NOMBRE+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Nombre</div>',
				'<div class="w3-left w3-muhle-text-11">'+LUGAR	+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Lugar</div>',
				'<div class="w3-left w3-muhle-text-11">'+CLIENTE +'</div>'		AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
				'<div class="w3-center w3-muhle-text-11">'+FECHA_INI+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Fecha Inicio</div>',
				'<div class="w3-center w3-muhle-text-11">'+FECHA_FIN+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Fecha Fin</div>',
				'<div class="w3-left w3-muhle-text-11">'+AUDITORES+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Auditores</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,DIAS_AUDITOR)+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Dias Auditor</div>',
				'<div class="w3-left w3-muhle-text-11">'+PROYECTO+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,HS_PROYEC)+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Hs Proyectadas</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,HS_EJEC)+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Hs Ejecutadas</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,PORC_AVANCE)	+'</div>'	AS '<div class="w3-center w3-muhle-text-11">% Avance</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(PLAN_AUDI,'')+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Plan Auditoria</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(FECHA_PLAN,'')+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Fecha PA</div>',
				--MANUALES		AS '<font size="1">Manuales</font>',
				--REQUISITOS		AS '<font size="1">Requisitos</font>',
				--CV_CERTIF		AS '<font size="1">CV/Cert.</font>',
				--LOGISTICA		AS '<font size="1">Logistica</font>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(INFORME,'')+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Informe</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(FECHA_INF,'')+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Fecha Inf.</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(CONVERT(VARCHAR,TIEMPO_INF),'')+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Tiempo Inf.</div>'
		FROM	(
				SELECT	distinct	PS.NOMBRE AS NOMBRE,
						PS.LUGAR	AS LUGAR,
						CLI.RAZON_SOCIAL_CLIENTE	AS CLIENTE,
						CONVERT(VARCHAR,CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,120),1,10)),103)	AS FECHA_INI,
						CONVERT(VARCHAR,CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR,PS.FECHA_FIN_REAL,120),1,10)),103)		AS FECHA_FIN,
						SUBSTRING(CONVERT(VARCHAR,PS.FECHA_FIN_REAL,120),1,10)												AS FECHA_ORDEN,
						--CONVERT(VARCHAR,[dbo].[FN_GET_SERVICIO_VISITAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO),103)	AS '<font size="2">Fecha</font>',
						--auditores
						CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN 
							'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Sin Auditores</font>'
						ELSE 
							[dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) 
						END											AS AUDITORES,
						--DIAS AUDITOR
						[dbo].[FN_GET_SERVICIO_DIAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO)	AS DIAS_AUDITOR,
						'('+P.CODIGO+') - '+P.NORMA_REF+'<b> - '+  ISNULL(PS.NOMBRE,'') + '</b>'									AS PROYECTO,
						ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)																		AS HS_PROYEC,
						[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO)								AS HS_EJEC,
						--ISNULL(PS.TOTAL_HORAS_EJECUTADAS,0)														AS '<font size="2">Hs Ejecutadas</font>',
						CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) = 0 THEN 
							0
						ELSE
							[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO) * 100 / ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)															
						END																											AS PORC_AVANCE,
						--plan auditoria (ver adjunto) si existe cargado --> enviado
						CASE WHEN (PLA.FECHA IS NOT NULL) THEN 'Enviado' ELSE 'Pendiente' END										AS PLAN_AUDI,
						CASE WHEN (PLA.FECHA IS NOT NULL) THEN CONVERT(VARCHAR,PLA.FECHA,103) ELSE '' END							AS FECHA_PLAN,
						--Manual/documentos	--check a nivel servicio
						UPPER(SUBSTRING(PS.MANUALES,1,1))+LOWER(SUBSTRING(PS.MANUALES,2,LEN(PS.MANUALES)))							AS MANUALES,
						--Reqs Ingreso	--check a nivel servicio
						UPPER(SUBSTRING(PS.REQUISITO_INGRESO,1,1))+LOWER(SUBSTRING(PS.REQUISITO_INGRESO,2,LEN(PS.REQUISITO_INGRESO))) AS REQUISITOS,
						--Cv y Certificados	--check a nivel servicio
						UPPER(SUBSTRING(PS.CV_CERTIFICADOS,1,1))+LOWER(SUBSTRING(PS.CV_CERTIFICADOS,2,LEN(PS.CV_CERTIFICADOS)))		AS CV_CERTIF,
						--Logística	--check a nivel servicio
						UPPER(SUBSTRING(PS.LOGISTICA,1,1))+LOWER(SUBSTRING(PS.LOGISTICA,2,LEN(PS.LOGISTICA)))						AS LOGISTICA,
						--Informe --(ver adjunto) si existe cargado --> enviado	
						CASE WHEN (INF.FECHA IS NOT NULL) THEN 'Enviado' ELSE 'Pendiente' END										AS INFORME,
						--Fecha envío informe (fecha de carga del adjunto)	
						CASE WHEN (INF.FECHA IS NOT NULL) THEN CONVERT(VARCHAR,INF.FECHA,103) ELSE '' END							AS FECHA_INF,
						--Tiempo de informe --diferencia de dias habiles entre la fecha auditoria y fecha envio informe
						ISNULL([dbo].[FN_GET_DIAS_HABILES](PS.FECHA_FIN_REAL, INF.FECHA) - 1,'')									AS TIEMPO_INF
				FROM	LK_PROYECTO P
						INNER JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
						INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
						LEFT JOIN (SELECT	PS.ID_PROYECTO_SERVICIO IDPS, MAX(FECHA_DOCUM) FECHA
									FROM	LK_PROYECTO_SERVICIO PS
									LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID AND PD.TIPO = 'PA'
									GROUP BY ID_PROYECTO_SERVICIO ) PLA ON PS.ID_PROYECTO_SERVICIO = PLA.IDPS
						LEFT JOIN (SELECT	PS.ID_PROYECTO_SERVICIO IDPS, MAX(FECHA_DOCUM) FECHA
									FROM	LK_PROYECTO_SERVICIO PS
											LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID AND PD.TIPO = 'IA'
									GROUP BY ID_PROYECTO_SERVICIO ) INF ON PS.ID_PROYECTO_SERVICIO = INF.IDPS
				WHERE	PS.FECHA_INICIO_REAL >= @VFECHA_DESDE
				AND		PS.FECHA_INICIO_REAL <= @VFECHA_HASTA
				--WHERE	PS.FECHA_INICIO_REAL <= @VFECHA_HASTA  
				--AND		PS.FECHA_FIN_REAL	 >= @VFECHA_DESDE
				AND		PS.ID_TIPO_SERVICIO = '2' --AUDITORIAS
				) AUDI
		ORDER BY AUDI.FECHA_ORDEN
 
	END
END
