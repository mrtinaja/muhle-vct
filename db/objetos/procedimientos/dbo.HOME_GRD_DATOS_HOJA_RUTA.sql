CREATE PROCEDURE [dbo].[HOME_GRD_DATOS_HOJA_RUTA]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO			VARCHAR(50),
		@VPROYECTO_DESC		VARCHAR(300),	
		@VSERVICIO			VARCHAR(50),
		@VID_HOJA			VARCHAR(50),
		@VCLIENTE			VARCHAR(300),
		@VFECHA				VARCHAR(50),
		@VNOMBRE			VARCHAR(100),
		@VCONSULTOR			VARCHAR(50),
		@VCONSULTOR_ACOMP	VARCHAR(50),
		@VVISITA			VARCHAR(50),
		@VOBSERVACIONES		VARCHAR(400),
		@VFECHA_CIERRE		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_HOJA  = ISNULL(HOJA_RUTA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO_DESC = P.NORMA_REF
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	SELECT	@VFECHA = CONVERT(VARCHAR,FECHA_DOCUM,103),
			@VNOMBRE = NRO_DOCUM_INTERNO,
			@VCONSULTOR = ISNULL(CONS1.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS1.NOMBRE_EMPLEADO,''),
			@VCONSULTOR_ACOMP = ISNULL(CONS2.APELLIDO_EMPLEADO,'')+', '+ISNULL(CONS2.NOMBRE_EMPLEADO,''),
			@VVISITA = CONVERT(VARCHAR,VISITA_MES,103),
			@VOBSERVACIONES = OBSERVACIONES,
			@VFECHA_CIERRE = CONVERT(VARCHAR,FECHA_CIERRE,103)
	FROM	LK_PROYECTO_DOCUM PD
			LEFT JOIN LK_EMPLEADOS CONS1 ON PD.CONSULTOR = CONS1.ID_EMPLEADO
			LEFT JOIN LK_EMPLEADOS CONS2 ON PD.CONSULTOR_ACOMP = CONS2.ID_EMPLEADO
	WHERE	ID_PROYECTO_DOCUM = @VID_HOJA
 
	SELECT
	'<font size="2" color  = "#003D7A"><B>Cliente:</B></font>' as '<div align="left"></div>' , 
	'<font size="2">'+ @VCLIENTE +'</font>' AS '<font color  = "#ebeadb">1</font>',
	'<font size="2" color  = "#003D7A"><B>Proyecto:</B></font>' as  '<font color  = "#ebeadb">A</font>', 
	'<font size="2">'+ @VPROYECTO_DESC +'</font>' AS '<font color  = "#ebeadb">2</font>',
	'<font size="2" color  = "#003D7A"><B>Nro/Nombre Doc.:</B></font>' as  '<font color  = "#ebeadb">B</font>',
	'<font size="2">'+ @VNOMBRE +'</font>' AS '<font color  = "#ebeadb">3</font>'
	UNION ALL
	SELECT
	'<font size="2" color  = "#003D7A"><B>Fecha:</B></font>', 
	'<font size="2">'+ @VFECHA +'</font>',
	'<font size="2" color  = "#003D7A"><B>Consultor:</B></font>',  
	'<font size="2">'+ @VCONSULTOR +'</font>',
	'<font size="2" color  = "#003D7A"><B>Consultor Acomp.:</B></font>',  
	'<font size="2">'+ @VCONSULTOR_ACOMP +'</font>'
	UNION ALL
	SELECT
	'<font size="2" color  = "#003D7A"><B>Visita Mes:</B></font>', 
	'<font size="2">'+ @VVISITA +'</font>',
	'<font size="2" color  = "#003D7A"><B>Observacion:</B></font>',  
	'<font size="2">'+ @VOBSERVACIONES +'</font>',
	'<font size="2" color  = "#003D7A"><B>Fecha Cierre:</B></font>',  
	'<font size="2">'+ @VFECHA_CIERRE +'</font>'
 
END
 
