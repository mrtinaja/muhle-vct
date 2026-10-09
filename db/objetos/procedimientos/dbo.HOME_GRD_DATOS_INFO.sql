CREATE PROCEDURE [dbo].[HOME_GRD_DATOS_INFO]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE	@VPROYECTO	VARCHAR(50),
		@VSERVICIO	VARCHAR(50),
		@VCLIENTE	VARCHAR(300),
		@VCUIT		VARCHAR(50),
		@VEMAIL		VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHA		VARCHAR(50),
		@VDIAS		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(PROYECTO_SERV_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VCUIT	  = CLI.CUIT_CLIENTE,
			@VEMAIL	  = CLI.EMAIL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VFECHA	  = CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103),
			@VDIAS	  = CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS/24)
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	SELECT
	'<font size="2" color  = "#003D7A"><B>Cliente:</B></font>' as '<div align="left"></div>' , 
	'<font size="2">'+ @VCLIENTE +'</font>' AS '<font color  = "#ebeadb">1</font>',
	'<font size="2" color  = "#003D7A"><B>CUIT:</B></font>' as  '<font color  = "#ebeadb">A</font>', 
	'<font size="2">'+ @VCUIT +'</font>' AS '<font color  = "#ebeadb">2</font>',
	'<font size="2" color  = "#003D7A"><B>Email:</B></font>' as  '<font color  = "#ebeadb">B</font>',
	'<font size="2">'+ @VEMAIL +'</font>' AS '<font color  = "#ebeadb">3</font>'
	UNION ALL
	SELECT
	'<font size="2" color  = "#003D7A"><B>Norma:</B></font>', 
	'<font size="2">'+ @VNORMA +'</font>',
	'<font size="2" color  = "#003D7A"><B>Fecha Inicio:</B></font>',  
	'<font size="2">'+ @VFECHA +'</font>',
	'<font size="2" color  = "#003D7A"><B>Dias:</B></font>',  
	'<font size="2">'+ @VDIAS +'</font>'
 
END
 
