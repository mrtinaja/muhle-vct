CREATE PROCEDURE [dbo].[HOME_GRD_CHECKSLIST]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VTIPO_SERV		VARCHAR(50),
		@VAGENDA_ID		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VAGENDA_ID = ISNULL(AGENDA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
	
	SELECT	'<i class="fas fa-search" style="cursor:pointer;font-size:18px" title="Ver Detalle"				
				onclick="almacenarSeleccion(''HOJA_RUTA_ID'','''+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+''');
				goto('''+@FORM_ID+''',''6EA8B964-2C14-4B0F-AFB4-205C48498150'');"></i>'								AS '<font size="2">[+]</font>',
			--'<font size="1">'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM)+'</font>'											AS '<font size="2">Id</font>',
			--'<font size="1">'+DOC.CODE_DOCUMENTACION + ' - ' + DOC.DESC_DOCUMENTACION	+'</font>'					AS '<font size="2">Documento</font>',
			'<font size="1">'+CONVERT(VARCHAR,FECHA_DOCUM,103)	+'</font>'											AS '<font size="2">Fecha Doc.</font>',
			'<font size="1">'+ISNULL(TEMAS_DOCUM,'')+'</font>'																AS '<font size="2">Curso</font>',
			'<font size="1">'+NRO_DOCUM_INTERNO	+'</font>'															AS '<font size="2">Nro/Nombre Doc.</font>',
			'<font size="1">'+ISNULL(PARTICIPANTES_DOCUM,'')+'</font>'															AS '<font size="2">Asistentes</font>',
			'<font size="1">'+ISNULL(OBSERVACIONES,'') +'</font>'													AS '<font size="2">Observacion</font>'
	FROM	LK_PROYECTO_DOCUM PD
			INNER JOIN LK_DOCUMENTACION DOC ON PD.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
	WHERE	ID_AGENDA = @VAGENDA_ID
	AND		PD.ID_DOCUMENTACION = '4'
	
 
END
 
