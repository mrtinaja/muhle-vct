CREATE   PROCEDURE [dbo].[SV_01_GRD_DOCUMENTACION]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
 
	SELECT	'<div class="w3-center w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
			onclick="almacenarSeleccion(''CLAVE_DOC'','''+CONVERT(VARCHAR,ID_DOCUMENTACION)+''');
					 almacenarSeleccion(''ESTADO_DOC'','''+STATUS_DOCUMENTACION+''');
					 almacenarSeleccion(''DETALLE_DOC'','''+DETALLE_DOCUMENTACION+''');
					 goto('''+@FORM_ID+''',''1B033F00-3AA8-43FB-9C54-6E1C81994DDF'');"></i></div>'		AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
			--ID_DOCUMENTACION		AS "<B>ID</B>",
			'<div class="w3-center w3-muhle-text-11">'+CODE_DOCUMENTACION+'</div>'						AS '<div class="w3-center w3-muhle-text-11">Codigo</div>',  
			'<div class="w3-left w3-muhle-text-11">'+DESC_DOCUMENTACION+'</div>'						AS '<div class="w3-left w3-muhle-text-11">Documentacion</div>',
			'<div class="w3-left w3-muhle-text-11">'+COMENT_DOCUMENTACION+'</div>'						AS '<div class="w3-left w3-muhle-text-11">Comentario</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_ALTA,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Alta</div>',
			'<div class="w3-center w3-muhle-text-11">'+USUARIO_ALTA+'</div>'							AS '<div class="w3-center w3-muhle-text-11">Usuario Alta</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_UPD,103)+'</div>'			AS '<div class="w3-center w3-muhle-text-11">Fecha Modif.</div>',
			'<div class="w3-center w3-muhle-text-11">'+USUARIO_UPD+'</div>'								AS '<div class="w3-center w3-muhle-text-11">Usuario Modif.</div>',
			CASE WHEN (STATUS_DOCUMENTACION = '0') THEN
					'<div class="w3-center w3-muhle-text-11 w3-red">Inactivo</div>'	
				 WHEN (STATUS_DOCUMENTACION = '1') THEN
					'<div class="w3-center w3-muhle-text-11 w3-green">Activo</div>'	
			END																							AS '<div class="w3-center w3-muhle-text-11">Estado</div>',
			CASE WHEN (DETALLE_DOCUMENTACION = 'SI') THEN
				'<div class="w3-center w3-muhle-text-12"><i class="fas fa-search" style="cursor:pointer;" title="Ver Detalle"				
				onclick="almacenarSeleccion(''CLAVE_DOC'','''+CONVERT(VARCHAR,ID_DOCUMENTACION)+''');
				goto('''+@FORM_ID+''',''4B0F1063-4306-45F1-8C86-E41A88987F90'');"></i></div>'
			ELSE
				'<div class="w3-center w3-muhle-text-11">'+DETALLE_DOCUMENTACION+'</div>'
			END																							AS '<div class="w3-center w3-muhle-text-11">Detalle</div>'
	FROM	LK_DOCUMENTACION WHERE CODE_DOCUMENTACION <> 'RE-PP-002' AND  CODE_DOCUMENTACION <> 'RE-PP-005' AND  CODE_DOCUMENTACION <> 'RE-PP-007'
	ORDER BY ID_DOCUMENTACION
 
END
 
