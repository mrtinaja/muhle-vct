 
CREATE PROCEDURE [dbo].[SV_05_GRD_SEG_CAPACITACION]
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
 
		SELECT	'<div class="w3-left w3-muhle-text-11">'+CLIENTE+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
				'<div class="w3-left w3-muhle-text-11">'+'('+CODIGO+') - '+PROYECTO+'<b> - '+  ISNULL(NOMBRE,'') + '</b>'+'</div>' AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
				'<div class="w3-left w3-muhle-text-11">'+ISNULL(CURSO,'')+'</div>'			AS '<div class="w3-left w3-muhle-text-11">Curso</div>',
				'<div class="w3-center w3-muhle-text-11">'+FECHA_INI+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Fecha Inicio</div>',
				'<div class="w3-center w3-muhle-text-11">'+FECHA_FIN+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Fecha Fin</div>',
				'<div class="w3-left w3-muhle-text-11">'+ISNULL(INSTRUCTORES,'')+'</div>' AS '<div class="w3-left w3-muhle-text-11">Instructores</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,HS_PROYEC)+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Hs Proyectadas</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,HS_EJEC)+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Hs Ejecutadas</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,PORC_AVANCE)+'</div>'	AS '<div class="w3-center w3-muhle-text-11">% Avance</div>',
				'<div class="w3-left w3-muhle-text-11">'+ISNULL(MATERIAL,'')+'</div>'		AS '<div class="w3-left w3-muhle-text-11">Material</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(ESTADO_ENVIO,'')+'</div>' AS '<div class="w3-center w3-muhle-text-11">Estado Envio</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(RECIBIDO,'')+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Recibido</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(INFORME,'')+'</div>'		AS '<div class="w3-center w3-muhle-text-11">Informe</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(FECHA_INF,'')+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Fecha Inf.</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(CONVERT(VARCHAR,TIEMPO_INF),'')+'</div>'	AS '<div class="w3-center w3-muhle-text-11">Tiempo Inf.</div>'
		FROM	(
				SELECT	CLI.RAZON_SOCIAL_CLIENTE					AS CLIENTE,
						P.NORMA_REF									AS PROYECTO,
						P.CODIGO									AS CODIGO,
						PS.NOMBRE									AS NOMBRE,
						PS.NOMBRE_CURSO								AS CURSO,
						CONVERT(VARCHAR,PS.FECHA_INICIO_REAL,103)	AS FECHA_INI,
						CONVERT(VARCHAR,PS.FECHA_FIN_REAL,103)		AS FECHA_FIN,
						SUBSTRING(CONVERT(VARCHAR,PS.FECHA_FIN_REAL,120),1,10)	AS FECHA_ORDEN,
						--CONVERT(VARCHAR,[dbo].[FN_GET_SERVICIO_VISITAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO,PS.ID_PROYECTO_SERVICIO),103)	AS '<font size="2">Fecha</font>',
						--instructores
						CASE WHEN [dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) = '1' THEN 
							'<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Sin Instructores</font>'
						ELSE
							[dbo].[FN_GET_SERVICIO_CONSULTORES] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO) 
						END											AS INSTRUCTORES,
						ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)													AS HS_PROYEC,
						--ISNULL(PS.TOTAL_HORAS_EJECUTADAS,0)														AS '<font size="2">Hs Ejecutadas</font>',
						[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO)			AS HS_EJEC,
						CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) = 0 THEN 
							0
						ELSE
							[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, PS.ID_PROYECTO_SERVICIO) * 100 / ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)															
						END																						AS PORC_AVANCE,
						--Cantidad de Asistentes --COUNT TABLA ASISTENTES	
						--Material	--AGREGAR A NIVEL AGENDA
						UPPER(SUBSTRING(PS.MATERIALES,1,1))+LOWER(SUBSTRING(PS.MATERIALES,2,LEN(PS.MATERIALES)))		AS MATERIAL,
						UPPER(SUBSTRING(PS.ESTADO_ENVIO,1,1))+LOWER(SUBSTRING(PS.ESTADO_ENVIO,2,LEN(PS.ESTADO_ENVIO)))	AS ESTADO_ENVIO,
						UPPER(SUBSTRING(PS.RECIBIDO,1,1))+LOWER(SUBSTRING(PS.RECIBIDO,2,LEN(PS.RECIBIDO)))				AS RECIBIDO,
						--Informe --(ver adjunto) si existe cargado --> enviado	
						CASE WHEN (INF.FECHA IS NOT NULL) THEN 'Enviado' ELSE 'Pendiente' END							AS INFORME,
						--Fecha envío informe (fecha de carga del adjunto)	
						CASE WHEN (INF.FECHA IS NOT NULL) THEN CONVERT(VARCHAR,INF.FECHA,103) ELSE '' END				AS FECHA_INF,
						--Tiempo de informe --diferencia de dias habiles entre la fecha auditoria y fecha envio informe
						ISNULL([dbo].[FN_GET_DIAS_HABILES]([dbo].[FN_GET_SERVICIO_VISITAS] (P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO),INF.FECHA),'') AS TIEMPO_INF
						--Intereses	--AGREGAR A NIVEL AGENDA
						--Lista asistentes	--AGREGAR A NIVEL AGENDA
						--Firmante	--AGREGAR A NIVEL AGENDA
						--Direcc envío	--AGREGAR A NIVEL AGENDA
						--Certificado	--AGREGAR A NIVEL AGENDA
						--Fecha envío certificados	--AGREGAR A NIVEL AGENDA
						--Cantidad de dias
				FROM	LK_PROYECTO P
						INNER JOIN LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
						INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
						LEFT JOIN (SELECT	PS.ID_PROYECTO_SERVICIO SERVICIO, FECHA_DOCUM FECHA, PD.OBSERVACIONES
									FROM	LK_PROYECTO_SERVICIO PS
											LEFT JOIN LK_PROYECTO_DOCUM PD ON PS.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID
									WHERE	PD.TIPO = 'IC'
									and		FECHA_DOCUM = (select max(FECHA_DOCUM)
															from  LK_PROYECTO_DOCUM doc
															where doc.PROYECTO_SERV_ID = PS.ID_PROYECTO_SERVICIO)) INF ON PS.ID_PROYECTO_SERVICIO = INF.SERVICIO
				WHERE	PS.FECHA_INICIO_REAL >= @VFECHA_DESDE
				AND		PS.FECHA_INICIO_REAL <= @VFECHA_HASTA
				--WHERE	PS.FECHA_INICIO_REAL <= @VFECHA_HASTA  
				--AND		PS.FECHA_FIN_REAL	 >= @VFECHA_DESDE
				AND		PS.ID_TIPO_SERVICIO = '3' --CAPACITACIONES
				) CAPA
		ORDER BY CAPA.FECHA_ORDEN
 
	END
END
