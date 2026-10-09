CREATE PROCEDURE [dbo].[HOME_GRD_HOJAS_RUTA]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VPROYECTO_SERV	VARCHAR(50),
		@VTIPO_SERV		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VPROYECTO		= ISNULL(PROYECTO_ID,''),
			@VPROYECTO_SERV = ISNULL(PROYECTO_SERV_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VTIPO_SERV  = ID_TIPO_SERVICIO
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	IF (@VTIPO_SERV = '1') BEGIN
 
		SELECT	'<img src="./../img/lupa.png" width="20" height="20" style="cursor:pointer" title="' +'Ver Detalle'+ '" 
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''A98FD1D3-4226-45C2-961D-A47DFA5E9E8F'');"/>'									AS '<font size="2">[+]</font>',
				--'<font size="1">'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+'</font>'											AS '<font size="2">Id</font>',
				--'<font size="1">'+DOC.CODE_DOCUMENTACION + ' - ' + DOC.DESC_DOCUMENTACION	+'</font>'					AS '<font size="2">Documento</font>',
				'<font size="1">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</font>'											AS '<font size="2">Fecha Doc.</font>',
				'<font size="1">'+NRO_DOCUM_INTERNO	+'</font>'															AS '<font size="2">Nro/Nombre Doc.</font>',
				'<font size="1">'+ISNULL(CONS1.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS1.NOMBRE_EMPLEADO,'') + '</br>'+ 
								  ISNULL(CONS2.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS2.NOMBRE_EMPLEADO,'') + '</font>'	AS '<font size="2">Consultores</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,VISITA_MES,103),'')	+'</font>'								AS '<font size="2">Visita Mes</font>',
				'<font size="1">'+ISNULL(OBSERVACIONES,'') +'</font>'													AS '<font size="2">Observacion</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,FECHA_CIERRE,103),'') +'</font>'								AS '<font size="2">Fecha Cierre</font>'
		FROM	LK_PROYECTO_DOCUM PD
				INNER JOIN LK_DOCUMENTACION DOC ON PD.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
				LEFT JOIN LK_EMPLEADOS CONS1 ON PD.CONSULTOR = CONS1.ID_EMPLEADO
				LEFT JOIN LK_EMPLEADOS CONS2 ON PD.CONSULTOR_ACOMP = CONS2.ID_EMPLEADO
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		ID_TIPO_SERVICIO = @VTIPO_SERV
		AND		PD.ID_DOCUMENTACION = '7'
 
	END
 
	IF (@VTIPO_SERV = '2') BEGIN
 
		SELECT	'<img src="./../img/lupa.png" width="20" height="20" style="cursor:pointer" title="' +'Ver Detalle'+ '" 
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''A98FD1D3-4226-45C2-961D-A47DFA5E9E8F'');"/>'									AS '<font size="2">[+]</font>',
				--'<font size="1">'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+'</font>'											AS '<font size="2">Id</font>',
				--'<font size="1">'+DOC.CODE_DOCUMENTACION + ' - ' + DOC.DESC_DOCUMENTACION	+'</font>'					AS '<font size="2">Documento</font>',
				'<font size="1">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</font>'											AS '<font size="2">Fecha Doc.</font>',
				'<font size="1">'+NRO_DOCUM_INTERNO	+'</font>'															AS '<font size="2">Fechas</font>',
				'<font size="1">'+ISNULL(CONS1.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS1.NOMBRE_EMPLEADO,'') + '</br>'+ 
								  ISNULL(CONS2.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS2.NOMBRE_EMPLEADO,'') + '</font>'	AS '<font size="2">Auditores</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,VISITA_MES,103),'')	+'</font>'								AS '<font size="2">F. Entrega Inf.</font>',
				'<font size="1">'+ISNULL(OBSERVACIONES,'') +'</font>'													AS '<font size="2">Observacion</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,FECHA_CIERRE,103),'') +'</font>'								AS '<font size="2">Fecha Cierre</font>'
		FROM	LK_PROYECTO_DOCUM PD
				INNER JOIN LK_DOCUMENTACION DOC ON PD.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
				LEFT JOIN LK_EMPLEADOS CONS1 ON PD.CONSULTOR = CONS1.ID_EMPLEADO
				LEFT JOIN LK_EMPLEADOS CONS2 ON PD.CONSULTOR_ACOMP = CONS2.ID_EMPLEADO
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		ID_TIPO_SERVICIO = @VTIPO_SERV
		AND		PD.ID_DOCUMENTACION = '5'
 
	END
 
	IF (@VTIPO_SERV = '3') BEGIN
 
		SELECT	'<img src="./../img/lupa.png" width="20" height="20" style="cursor:pointer" title="' +'Ver Detalle'+ '" 
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''A98FD1D3-4226-45C2-961D-A47DFA5E9E8F'');"/>'									AS '<font size="2">[+]</font>',
				--'<font size="1">'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+'</font>'											AS '<font size="2">Id</font>',
				--'<font size="1">'+DOC.CODE_DOCUMENTACION + ' - ' + DOC.DESC_DOCUMENTACION	+'</font>'					AS '<font size="2">Documento</font>',
				'<font size="1">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</font>'											AS '<font size="2">Fecha Doc.</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,VISITA_MES,103),'')	+'</font>'								AS '<font size="2">Fechas</font>',
				'<font size="1">'+NRO_DOCUM_INTERNO	+'</font>'															AS '<font size="2">Capacitacion (Tipo,Lugar)</font>',
				'<font size="1">'+ISNULL(CONS1.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS1.NOMBRE_EMPLEADO,'') + '</br>'+ 
								  ISNULL(CONS2.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS2.NOMBRE_EMPLEADO,'') + '</font>'	AS '<font size="2">Instructores</font>',
				'<font size="1">'+ISNULL(OBSERVACIONES,'') +'</font>'													AS '<font size="2">Observacion</font>',
				'<font size="1">'+ISNULL(CONVERT(VARCHAR,FECHA_CIERRE,103),'') +'</font>'								AS '<font size="2">Fecha Cierre</font>'
		FROM	LK_PROYECTO_DOCUM PD
				INNER JOIN LK_DOCUMENTACION DOC ON PD.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
				LEFT JOIN LK_EMPLEADOS CONS1 ON PD.CONSULTOR = CONS1.ID_EMPLEADO
				LEFT JOIN LK_EMPLEADOS CONS2 ON PD.CONSULTOR_ACOMP = CONS2.ID_EMPLEADO
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		ID_TIPO_SERVICIO = @VTIPO_SERV
		AND		PD.ID_DOCUMENTACION = '6'
 
	END
 
 
END
 
