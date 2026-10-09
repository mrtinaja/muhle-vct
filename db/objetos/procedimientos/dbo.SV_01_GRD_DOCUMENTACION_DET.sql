CREATE   PROCEDURE [dbo].[SV_01_GRD_DOCUMENTACION_DET]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE @VCLAVE_DOC	VARCHAR(100),
		@VCODIGO_DOC VARCHAR(100)
 
BEGIN	
	--menu editar original 1CDC7834-BC42-41E3-AF73-E2AE6C2CEF5C
	SELECT	@VCLAVE_DOC = CLAVE_DOC
	FROM	TMT_SV_01
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCODIGO_DOC = CODE_DOCUMENTACION
	FROM	LK_DOCUMENTACION
	WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
 
	IF (@VCODIGO_DOC IN ('RE-PP-022-A','RE-PP-022-CA','RE-PP-022-CO','RE-PP-022-A-Anex','RE-PP-022-CA-Anex','RE-PP-022-CO-Anex')) BEGIN
 
		SELECT	'<div class="w3-center w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" 
				onclick="almacenarSeleccion(''CLAVE_DETALLE'','''+CONVERT(VARCHAR,ID_DOCUMENTACION_DET)+''');
						 almacenarSeleccion(''ESTADO_DET'','''+STATUS_DOC_DET+''');
						 almacenarSeleccion(''GRUPO_DET'','''+GRUPO_DOC_DET+''');
						 goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');"></i></div>'			AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
				--ID_DOCUMENTACION_DET		AS "<B>ID</B>",
				'<div class="w3-left w3-muhle-text-11">'+DESC_DOC_DET+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Detalle</div>',
				'<div class="w3-center w3-muhle-text-11">'+CD.CAT_DATA_DESC+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Grupo</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,ORDEN)+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Orden</div>',
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(OBLIGATORIO_DET,'')+'</div>'					AS '<div class="w3-center w3-muhle-text-11">Obligatorio</div>',
				'<div class="w3-center w3-muhle-text-11">'+CASE WHEN ISNULL(EXPORTA_DET,'') = '0|1' THEN 
																	'Interno'
																WHEN ISNULL(EXPORTA_DET,'') = '1' THEN 
																	'Consultor' ELSE '' END +'</div>'			AS '<div class="w3-center w3-muhle-text-11">Exporta</div>',
				'<div class="w3-center w3-muhle-text-11">'+CASE WHEN ISNULL(DATO_DET,'') = 'LK_PROYECTO' THEN
																	'Proyecto'
																WHEN ISNULL(DATO_DET,'') = 'LK_CLIENTES' THEN
																	'Cliente'
															ELSE ISNULL(DATO_DET,'') END+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Dato Asociado</div>',
				'<div class="w3-center w3-muhle-text-11">'+ CASE WHEN CAMPO_DET = 'FECHA_INICIO_REAL' THEN
																	'FECHA INICIO'
																 WHEN CAMPO_DET = 'FECHA_FIN_REAL' THEN
																	'FECHA FIN'
																WHEN CAMPO_DET = 'OBSERVACIONES' THEN
																	'ANALISTA A CARGO'
															ELSE
																ISNULL(REPLACE(CAMPO_DET,'_',' '),'')
															END	+'</div>'										AS '<div class="w3-center w3-muhle-text-11">Campo Asociado</div>',
				--'<div class="w3-left w3-muhle-text-11">'+COMENT_DOC_DET+'</div>'								AS '<div class="w3-left w3-muhle-text-11">Comentario</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_ALTA,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha Alta</div>',
				'<div class="w3-center w3-muhle-text-11">'+USUARIO_ALTA+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Usuario Alta</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_UPD,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha Modif.</div>',
				'<div class="w3-center w3-muhle-text-11">'+USUARIO_UPD+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Usuario Modif.</div>',
				CASE WHEN (STATUS_DOC_DET = '0') THEN
						'<div class="w3-center w3-muhle-text-11 w3-red">Inactivo</div>'
					 WHEN (STATUS_DOC_DET = '1') THEN
						'<div class="w3-center w3-muhle-text-11 w3-green">Activo</div>'
				END																								AS '<div class="w3-center w3-muhle-text-11">Estado</div>'
		FROM	LK_DOCUMENTACION_DET LKD
				LEFT JOIN CAT_DATA CD ON (LKD.GRUPO_DOC_DET = CD.CAT_DATA_CODE) AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'GRUPO_DOC_DET') 
		WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
		ORDER BY CASE WHEN CD.CAT_DATA_DESC IN ('General') THEN 1 
					  WHEN CD.CAT_DATA_DESC IN ('Cierre de Proyecto') THEN 2 END, ISNULL(ORDEN,99), CASE WHEN STATUS_DOC_DET = '1' THEN 1 ELSE 2 END
	
	END ELSE BEGIN
	
		SELECT	'<div class="w3-center w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar" 
				onclick="almacenarSeleccion(''CLAVE_DETALLE'','''+CONVERT(VARCHAR,ID_DOCUMENTACION_DET)+''');
						 almacenarSeleccion(''ESTADO_DET'','''+STATUS_DOC_DET+''');
						 almacenarSeleccion(''GRUPO_DET'','''+GRUPO_DOC_DET+''');
						 goto('''+@FORM_ID+''',''9C07EDBD-165C-495C-9FC3-6419CDC9526A'');"></i></div>'			AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
				--ID_DOCUMENTACION_DET		AS "<B>ID</B>",
				'<div class="w3-left w3-muhle-text-11">'+DESC_DOC_DET+'</div>'									AS '<div class="w3-left w3-muhle-text-11">Detalle</div>',
				'<div class="w3-center w3-muhle-text-11">'+CD.CAT_DATA_DESC+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Grupo</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,ORDEN)+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Orden</div>',
				'<div class="w3-left w3-muhle-text-11">'+COMENT_DOC_DET+'</div>'								AS '<div class="w3-left w3-muhle-text-11">Comentario</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_ALTA,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha Alta</div>',
				'<div class="w3-center w3-muhle-text-11">'+USUARIO_ALTA+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Usuario Alta</div>',
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_UPD,103)+'</div>'				AS '<div class="w3-center w3-muhle-text-11">Fecha Modif.</div>',
				'<div class="w3-center w3-muhle-text-11">'+USUARIO_UPD+'</div>'									AS '<div class="w3-center w3-muhle-text-11">Usuario Modif.</div>',
				CASE WHEN (STATUS_DOC_DET = '0') THEN
						'<div class="w3-center w3-muhle-text-11 w3-red">Inactivo</div>'
					 WHEN (STATUS_DOC_DET = '1') THEN
						'<div class="w3-center w3-muhle-text-11 w3-green">Activo</div>'
				END																								AS '<div class="w3-center w3-muhle-text-11">Estado</div>'
		FROM	LK_DOCUMENTACION_DET LKD
				LEFT JOIN CAT_DATA CD ON (LKD.GRUPO_DOC_DET = CD.CAT_DATA_CODE) AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'GRUPO_DOC_DET') 
		WHERE	ID_DOCUMENTACION = @VCLAVE_DOC
		ORDER BY CASE WHEN CD.CAT_DATA_DESC IN ('Logistico','General') THEN 1 
					  WHEN CD.CAT_DATA_DESC IN ('Tecnico','Cierre de Proyecto') THEN 2
					  WHEN CD.CAT_DATA_DESC = 'Administracion' THEN 3 END, ISNULL(ORDEN,99), CASE WHEN STATUS_DOC_DET = '1' THEN 1 ELSE 2 END
	END
 
END
