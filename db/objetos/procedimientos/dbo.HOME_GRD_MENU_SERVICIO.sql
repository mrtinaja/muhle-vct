CREATE PROCEDURE [dbo].[HOME_GRD_MENU_SERVICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO		VARCHAR(50),
		@VSERVICIO_ID	VARCHAR(50),
		@VTIPO_SERV		VARCHAR(50),
		@VID			VARCHAR(100),
		@VDOC			VARCHAR(MAX),
		@VDOCUMENTOS	VARCHAR(MAX),
		@VTOTALES		VARCHAR(MAX),
		@VID_DOC		VARCHAR(50),
		@VCANT			INT,
		@VVIATICOS		INT
 
BEGIN	
 
	SELECT	@VPROYECTO = PROYECTO_ID,
			@VSERVICIO_ID = PROYECTO_SERV_ID
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VTIPO_SERV = ID_TIPO_SERVICIO
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VSERVICIO_ID
 
	/*
	1	Consultoria --> Hoja de Ruta Consultoria, Agenda, Viaticos
	2	Auditoria	--> Hoja de Ruta Auditoria, Agenda, Plan Auditoria, Viaticos
	3	Capacitacion -->  Hoja de Ruta Capacitacion, Agenda, Check List Capacitacion, Viaticos
 
	1	Check List Capacitacion 
	2	Hoja de Ruta Capacitacion
	3	Hoja de Ruta Consultoria
	4	Plan Auditoria
	5	Hoja de Ruta Auditoria
	*/
	DECLARE Documentos CURSOR FOR 
		SELECT	REL.ID_DOCUMENTACION_REL,
				CASE WHEN REL.ID_DOCUMENTACION_REL = '1' THEN
						'<img src="./../img/check.png" width="73" height="73" style="cursor:pointer" title="' +DOC.DESC_DOCUMENTACION+ '" 
						onclick="goto('''+@FORM_ID+''',''3D54E704-280F-4A6C-9876-D28E83C3F187'');"/>'
					 WHEN REL.ID_DOCUMENTACION_REL = '2' THEN
						'<img src="./../img/ruta.png" width="73" height="73" style="cursor:pointer" title="' +DOC.DESC_DOCUMENTACION+ '" 
						onclick="goto('''+@FORM_ID+''',''8B282B8A-3016-4529-BB76-2DD52D0C7450'');"/>'
					 WHEN REL.ID_DOCUMENTACION_REL = '3' THEN
						'<img src="./../img/ruta.png" width="73" height="73" style="cursor:pointer" title="' +DOC.DESC_DOCUMENTACION+ '" 
						onclick="goto('''+@FORM_ID+''',''8B282B8A-3016-4529-BB76-2DD52D0C7450'');"/>'
					 WHEN REL.ID_DOCUMENTACION_REL = '4' THEN
						'<img src="./../img/auditor.png" width="73" height="73" style="cursor:pointer" title="' +DOC.DESC_DOCUMENTACION+ '" />'
						--onclick="goto('''+@FORM_ID+''',''4049307F-6C13-459D-AC01-54F97D942D1B'');"/>'
					 WHEN REL.ID_DOCUMENTACION_REL = '5' THEN 
						'<img src="./../img/ruta.png" width="73" height="73" style="cursor:pointer" title="' +DOC.DESC_DOCUMENTACION+ '" 
						onclick="goto('''+@FORM_ID+''',''8B282B8A-3016-4529-BB76-2DD52D0C7450'');"/>'
				END
		FROM	LK_DOCUMENTACION_REL REL
				INNER JOIN LK_DOCUMENTACION DOC ON REL.ID_DOCUMENTACION = DOC.ID_DOCUMENTACION
		WHERE	ID_TIPO_SERVICIO = @VTIPO_SERV 
 
	OPEN Documentos  
	FETCH NEXT FROM Documentos INTO @VID, @VDOC  
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		
		SELECT	@VID_DOC = ID_DOCUMENTACION
		FROM	LK_DOCUMENTACION_REL
		WHERE	ID_DOCUMENTACION_REL = @VID
		 
		SELECT	@VCANT = COUNT(1)
		FROM	LK_PROYECTO_DOCUM
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		ID_DOCUMENTACION = @VID_DOC
 
		SELECT	@VVIATICOS = COUNT(1)
		FROM	LK_PROYECTO_VIATICOS
		WHERE	ID_PROYECTO = @VPROYECTO
		AND		ID_TIPO_SERVICIO = @VTIPO_SERV		
 
		SET @VDOCUMENTOS = ISNULL(@VDOCUMENTOS,'') + @VDOC + '   '
		SET @VTOTALES    = ISNULL(@VTOTALES,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;') + '('+CONVERT(VARCHAR,@VCANT)+')' + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
 
		  FETCH NEXT FROM Documentos INTO @VID, @VDOC
	END 
 
	CLOSE Documentos  
	DEALLOCATE Documentos 
 
	SET @VDOCUMENTOS = ISNULL(@VDOCUMENTOS,'') + 
						'<img src="./../img/viatic.png" width="73" height="73" style="cursor:pointer" title="' +'Viaticos '+CASE WHEN @VTIPO_SERV = '1' THEN 'Consultoria' 
																															  WHEN @VTIPO_SERV = '2' THEN 'Auditoria' 
																															  WHEN @VTIPO_SERV = '3' THEN 'Capacitacion'
																														 END+ '" 
						onclick="goto('''+@FORM_ID+''',''D5C00A34-A249-424B-9152-033D6F2652FB'');"/>'
						+ '   ' +
						'<img src="./../img/agenda.png" width="73" height="73" style="cursor:pointer" title="' +'Agenda '+CASE WHEN @VTIPO_SERV = '1' THEN 'Consultoria' 
																															  WHEN @VTIPO_SERV = '2' THEN 'Auditoria' 
																															  WHEN @VTIPO_SERV = '3' THEN 'Capacitacion'
																														 END+ '" 
						onclick="goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');"/>'
 
	SET  @VTOTALES    =  ISNULL(@VTOTALES,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;') + '('+CONVERT(VARCHAR,@VVIATICOS)+')' + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
	
	SELECT	@VDOCUMENTOS + '</BR>' + ISNULL(@VTOTALES,'') AS '<font color  = "#ebeadb">A</font>'
END
 
