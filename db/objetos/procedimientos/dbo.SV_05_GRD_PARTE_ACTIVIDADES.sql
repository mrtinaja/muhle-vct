CREATE PROCEDURE [dbo].[SV_05_GRD_PARTE_ACTIVIDADES]
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
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Desde</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
	END
 
	IF (@VFECHA_HASTA = '') BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">Debe Seleccionar Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
	END
 
	IF (@VFECHA_DESDE > @VFECHA_HASTA) BEGIN
		SELECT	'<div class="w3-center w3-muhle-text-11">La Fecha Desde debe ser Igual o Mayor a la Fecha Hasta</div>'  AS '<div class="w3-center w3-muhle-text-11">Mensaje</div>'
 
	END ELSE BEGIN
 
		SELECT	'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,AE.FECHA,103)	+ '</div>'											AS '<div class="w3-center w3-muhle-text-11">Fecha</div>',
				'<div class="w3-left w3-muhle-text-11">'+dbo.FN_GET_AGENDA_CLIENTE(HOLIDAYTEXT)	+ '</div>'										AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
				'<div class="w3-left w3-muhle-text-11">'+dbo.FN_GET_AGENDA_PROYECTO(HOLIDAYTEXT)	+'<b> - '+  ISNULL(PS.NOMBRE,'') + '</b>' + '</div>'	AS '<div class="w3-left w3-muhle-text-11">Descripción</div>',
				'<div class="w3-center w3-muhle-text-11">'+dbo.FN_GET_AGENDA_SERVICIO(HOLIDAYTEXT)	+ '</div>'									AS '<div class="w3-center w3-muhle-text-11">Servicio</div>',
				'<div class="w3-left w3-muhle-text-11">'+EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO	+ '</div>'							AS '<div class="w3-left w3-muhle-text-11">Consultor</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,AE.HORAS)	+ '</div>'												AS '<div class="w3-center w3-muhle-text-11">Horas</div>',
				'<div class="w3-center w3-muhle-text-11">'+
					case when [dbo].[FN_GET_AGENDA_SERVICIO] (HOLIDAYTEXT) = 'Consultoria' then
						--MV CONSULTORIA
						CASE WHEN isnull([dbo].[FN_GET_DOC_VISITA] (HOLIDAYTEXT, 'MV'),'') = '' THEN 'No' ELSE [dbo].[FN_GET_DOC_VISITA] (HOLIDAYTEXT, 'MV') END
					when [dbo].[FN_GET_AGENDA_SERVICIO] (HOLIDAYTEXT) = 'Auditoria' then
						--IA AUDITORIA
						CASE WHEN isnull([dbo].[FN_GET_DOC_VISITA] (A.PROYECTO_SERV_ID, 'IA'),'') = '' THEN 'Pendiente' ELSE [dbo].[FN_GET_DOC_VISITA] (A.PROYECTO_SERV_ID, 'IA') END
					when [dbo].[FN_GET_AGENDA_SERVICIO] (HOLIDAYTEXT) = 'Capacitacion' then
						--IC CAPACITACION
						CASE WHEN isnull([dbo].[FN_GET_DOC_VISITA] (A.PROYECTO_SERV_ID, 'IC'),'') = '' THEN 'Pendiente' ELSE [dbo].[FN_GET_DOC_VISITA] (A.PROYECTO_SERV_ID, 'IC') END
				end + '</div>'															AS '<div class="w3-center w3-muhle-text-11">Minuta/Informe</div>',
				'<div class="w3-left w3-muhle-text-11">'+A.OBSERVADOR + '</div>'		AS '<div class="w3-left w3-muhle-text-11">Observaciones</div>',
				'<div class="w3-left w3-muhle-text-11">'+A.OBSERV_CALIF	+ '</div>'		AS '<div class="w3-left w3-muhle-text-11">Obs. Calificación</div>',
				--A.OBSERV_LOGISTICA AS '<font size="2">Obs. Logística</font>',
				'<div class="w3-left w3-muhle-text-11">'+DOC.OBSERVACIONES + '</div>'	AS '<div class="w3-left w3-muhle-text-11">Obs. Hoja Ruta</div>'
		FROM	LK_AGENDA_EMPLEADO AE
				LEFT JOIN LK_EMPLEADOS EMP ON AE.ID_EMPLEADO = EMP.ID_EMPLEADO
				INNER JOIN LK_AGENDA A ON AE.HOLIDAYTEXT = A.ID_AGENDA
				INNER JOIN LK_PROYECTO PROY ON  PROY.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
				LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
		WHERE	AE.FECHA >= @VFECHA_DESDE
		AND		AE.FECHA <= @VFECHA_HASTA
		AND		AE.TIPO = 'A'
		AND		dbo.FN_GET_AGENDA_ESTADO(AE.HOLIDAYTEXT) = 'C'
		ORDER BY AE.FECHA, 2, 4, 3, 5
	END
 
	
 
END
