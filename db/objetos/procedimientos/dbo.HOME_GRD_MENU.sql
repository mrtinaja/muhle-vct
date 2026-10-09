CREATE PROCEDURE [dbo].[HOME_GRD_MENU]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
 
	SELECT	'<img src="./../img/cotiza.png" width="91" height="91" style="cursor:pointer" title="' +'Agregar Cotizacion'+ '" 
			onclick="goto('''+@FORM_ID+''',''116FA485-BFEA-4883-AB54-CD2937DFD996'');"/>' +
			'   ' +
			'<img src="./../img/proyecto.png" width="91" height="91" style="cursor:pointer" title="' +'Agregar Proyecto'+ '" 
			onclick="goto('''+@FORM_ID+''',''4049307F-6C13-459D-AC01-54F97D942D1B'');"/>' AS "Menu"
			
 
END
 
