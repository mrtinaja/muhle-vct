CREATE PROCEDURE [dbo].[SV_05_GRD_CALIF_CONSULTORES]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VID_APT	VARCHAR(50),
		@VID		VARCHAR(50),
		@VDESC_APT	VARCHAR(400),
		@VDESC		VARCHAR(400),
		@VQUERY		VARCHAR(MAX),
		@VIDS		VARCHAR(MAX),
		@VTODOS_IDS	VARCHAR(MAX),
		@VTODAS		VARCHAR(MAX),
		@lstDato		varchar(400), 
		--@lstNorma		int,
		@lnuPosComa		int,
		@VID_CONSULTOR	VARCHAR(50),
		@VCONSULTOR		VARCHAR(1000),
		@VCALIF_CONS	VARCHAR(100),
		@VCALIF_AUDI	VARCHAR(100),
		@VCALIF_CAPA	VARCHAR(100),
		@CALIF_SEL		VARCHAR(50),
		@APTITUD_SEL	INT,
		@TIPO_SERVICIO_SEL INT
BEGIN	
 
 
	SELECT	@CALIF_SEL=CALIF_SEL,
			@APTITUD_SEL=APTITUD_SEL,
			@TIPO_SERVICIO_SEL=TIPO_SERVICIO_SEL
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @VQUERY = '';
 
	IF (ISNULL(@CALIF_SEL,'') <> '')
		BEGIN
		 SET @VQUERY = @VQUERY + ' AND EA.CALIFICACION= ''' + @CALIF_SEL +''''
		END
	IF (ISNULL(cast(@APTITUD_SEL as varchar),'') <> '')
		BEGIN
		 SET @VQUERY = @VQUERY + ' AND EA.ID_APTITUD= '+ CAST(@APTITUD_SEL  AS VARCHAR)
		END
	IF (ISNULL(cast(@TIPO_SERVICIO_SEL as varchar),'') <> '')
		BEGIN
		 SET @VQUERY = @VQUERY + ' AND EA.ID_TIPO='+ CAST(@TIPO_SERVICIO_SEL  AS varchar)
		END
 
	SET @VQUERY = 
	'SELECT	CASE WHEN EMP.EVENTUAL = ''SI'' THEN 
				''<div class="w3-left w3-muhle-text-11" style="color:blue">'' + EMP.APELLIDO_EMPLEADO + '' '' + EMP.NOMBRE_EMPLEADO + ''</div>''
			ELSE 
				''<div class="w3-left w3-muhle-text-11" style="color:black">'' + EMP.APELLIDO_EMPLEADO + '' '' + EMP.NOMBRE_EMPLEADO + ''</div>''
			END		AS ''<div class="w3-left w3-muhle-text-11">Consultor</div>'', 
			CASE WHEN APT.STATUS_APTITUD = ''0'' THEN 
				''<div class="w3-left w3-muhle-text-11" style="color:red">'' + APT.DESC_APTITUD	+ ''</div>'' 
			ELSE 
				''<div class="w3-left w3-muhle-text-11" style="color:black">'' + APT.DESC_APTITUD	+ ''</div>'' 
			END		AS ''<div class="w3-left w3-muhle-text-11">Aptitud</div>'',
			''<div class="w3-center w3-muhle-text-11">'' + TS.DESC_TIPO_SERVICIO + ''</div>''	AS ''<div class="w3-center w3-muhle-text-11">Tipo Servicio</div>'', 
			''<div class="w3-center w3-muhle-text-11">'' + EA.CALIFICACION	+ ''</div>''	AS ''<div class="w3-center w3-muhle-text-11">Calificación</div>''
	FROM	LK_EMPLEADOS EMP
			LEFT JOIN LK_EMPLEADOS_APTITUD EA ON EMP.ID_EMPLEADO = EA.ID_EMPLEADO
			LEFT JOIN LK_APTITUDES APT ON EA.ID_APTITUD = APT.ID_APTITUD 
			LEFT JOIN LK_TIPO_SERVICIOS TS ON TS.ID_TIPO_SERVICIO = EA.ID_TIPO
	WHERE	1= 1 
	AND		EMP.STATUS_EMP=''1'' 
	AND		EMP.PERFIL_EMP = ''CONSULTOR'' '  + @VQUERY + 
	'ORDER BY EMP.APELLIDO_EMPLEADO + '' '' + EMP.NOMBRE_EMPLEADO'
	
	EXEC(@VQUERY)
 
END
