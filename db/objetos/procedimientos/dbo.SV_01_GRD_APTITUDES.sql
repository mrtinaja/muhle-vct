CREATE   PROCEDURE [dbo].[SV_01_GRD_APTITUDES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
 
	SELECT	'<div class="w3-center w3-muhle-text-12"><i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
			onclick="almacenarSeleccion(''CLAVE'','''+CONVERT(VARCHAR,ID_APTITUD)+''');
					 almacenarSeleccion(''ESTADO_APT'','''+STATUS_APTITUD+''');
					 goto('''+@FORM_ID+''',''A3E17ACE-383D-4C91-8280-B617C5AF13EA'');"></i></div>'				AS '<div class="w3-center w3-muhle-text-11">[+]</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,ID_APTITUD)+'</div>'						AS '<div class="w3-center w3-muhle-text-11">ID</div>',
			'<div class="w3-left w3-muhle-text-11">'+DESC_APTITUD+'</div>'									AS '<div class="w3-left w3-muhle-text-11">APTITUD</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_ALTA,103)+'</div>'					AS '<div class="w3-center w3-muhle-text-11">FECHA ALTA</div>',
			'<div class="w3-center w3-muhle-text-11">'+USUARIO_ALTA+'</div>'									AS '<div class="w3-center w3-muhle-text-11">USUARIO ALTA</div>',
			'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_UPD,103)+'</div>'					AS '<div class="w3-center w3-muhle-text-11">FECHA MODIF.</div>',
			'<div class="w3-center w3-muhle-text-11">'+USUARIO_UPD+'</div>'										AS '<div class="w3-center w3-muhle-text-11">USUARIO MODIF.</div>',
			CASE WHEN (STATUS_APTITUD = '0') THEN
					'<div class="w3-center w3-muhle-text-11 w3-red">Inactivo</div>'
				 WHEN (STATUS_APTITUD = '1') THEN
					'<div class="w3-center w3-muhle-text-11 w3-green">Activo</div>'
			END																									AS '<div class="w3-center w3-muhle-text-11">ESTADO</div>'
	FROM	LK_APTITUDES
	ORDER BY ID_APTITUD
	
END
 
