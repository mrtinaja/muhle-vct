CREATE   PROCEDURE [dbo].[SV_01_MENU]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
BEGIN	
 
	SELECT	1	as '<div>Opción</div>', 
			'<a style="cursor: pointer;color:blue" title="ABM Tipos Servicio" 
			 onclick="goto('''+@FORM_ID+''',''C6AD6921-F54B-4D59-94BE-1951BADC0AA3'');"><u>ABM Tipos Servicio</u></a>'	as '<div>Proceso</div>'
	UNION ALL
	SELECT	2,
			'<a style="cursor: pointer;color:blue" title="ABM Documentacion" 
			 onclick="goto('''+@FORM_ID+''',''DC567CD9-C30C-43D0-8723-68DFEFC31B91'');"><u>ABM Documentacion</u></a>'
	UNION ALL
	SELECT	3,
			'<a style="cursor: pointer;color:blue" title="ABM Documentacion Relacionada" 
			 onclick="goto('''+@FORM_ID+''',''8374CCC7-378F-488E-950F-4AFFA6B56BD0'');"><u>ABM Documentacion Relacionada</u></a>'
	UNION ALL
	SELECT	4,
			'<a style="cursor: pointer;color:blue" title="ABM Aptitudes" 
			 onclick="goto('''+@FORM_ID+''',''F6941E7F-13B6-483D-8513-CE40C0C35C6C'');"><u>ABM Aptitudes</u></a>'
	UNION ALL
	SELECT	5,
			'<a style="cursor: pointer;color:blue" title="ABM Empleado Aptitudes" 
			 onclick="goto('''+@FORM_ID+''',''1EC14FB3-DC80-40ED-9421-DDC95F09B55A'');"><u>ABM Empleado Aptitudes</u></a>'
END
 
