CREATE PROCEDURE [dbo].[HOME_GRD_DET_HOJA_RUTA]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO			VARCHAR(50),	
		@VSERVICIO			VARCHAR(50),
		@VID_SERVICIO		VARCHAR(50),
		@VID_AGENDA			VARCHAR(50),
		@VID_HOJA			VARCHAR(50)
 
BEGIN	
 
	SELECT	--@VPROYECTO = ISNULL(PROYECTO_ID,''),
			--@VSERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			--@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VID_HOJA = ID_PROYECTO_DOCUM
	FROM	LK_PROYECTO_DOCUM
	WHERE	ID_AGENDA = @VID_AGENDA
	AND		ID_DOCUMENTACION = CASE WHEN @VSERVICIO = '1' THEN '7'
									WHEN @VSERVICIO = '2' THEN '5'
									WHEN @VSERVICIO = '3' THEN '6'
							   END
 
	SELECT	'<font size="1"><b>Logistica</b></font>'	AS '<font color  = "#ebeadb"></font>',
			''											AS '<font color  = "#ebeadb"></font>'
	UNION ALL
	SELECT	'<font size="1">'+ DESC_DOC_DET +'</font>',
			'<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
				<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
				<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>
				<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
			 </select>' 
	FROM	LK_PROYECTO_DOCUM_DET
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
	AND		GRUPO_DOC_DET = 'LOGISTICO'
	UNION ALL
	SELECT	'<font size="1"><b>Temas Tecnicos</b></font>',
			''
	UNION ALL
	SELECT	'<font size="1">'+ DESC_DOC_DET +'</font>',
			'<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
				<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
				<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>
				<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
			 </select>'   
	FROM	LK_PROYECTO_DOCUM_DET
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
	AND		GRUPO_DOC_DET = 'TECNICO'
	UNION ALL
	SELECT	'<font size="1"><b>Administracion</b></font>',
			''
	UNION ALL
	SELECT	'<font size="1">'+ DESC_DOC_DET +'</font>',
			'<select id="'+CONVERT(VARCHAR,ID_PROYECTO_DOCUM_DET)+'" onchange="toggleCombo(this);">
				<option value="NA"'+CASE WHEN VALOR_DOC_DET = 'NA' THEN 'selected' ELSE '' END+'>No Aplica</option>
				<option value="SI"'+CASE WHEN VALOR_DOC_DET = 'SI' THEN 'selected' ELSE '' END+'>Si</option>
				<option value="NO"'+CASE WHEN VALOR_DOC_DET = 'NO' THEN 'selected' ELSE '' END+'>No</option>
			 </select>'   
	FROM	LK_PROYECTO_DOCUM_DET
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
	AND		GRUPO_DOC_DET = 'ADMINISTRACION'
 
END
 
