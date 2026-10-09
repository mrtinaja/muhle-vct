CREATE PROCEDURE [dbo].[HOME_GRD_CONSULTORES]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE @VID_PROYECTO	INT,
		@VID			INT,
		@VDESC			VARCHAR(400),
		@VCONSULTORES	VARCHAR(400),
		@VCANT			INT,
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VTORF			VARCHAR(50),
		@VQUERY			VARCHAR(MAX),
		@VFECHAD		VARCHAR(50),
		@vsemana		int,
		@vmes			int,
		@vano			int,
		@vbuffer		varchar(4000)
 
BEGIN	
 
	SELECT	@VCONSULTORES = ISNULL(AGENDA_CONSULTORES,''),
			@VFECHAD = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_DESDE, 105), 23),CONVERT(VARCHAR(10), CONVERT(date, FECHA_SELEC, 105), 23)),
			@vbuffer = ISNULL(LIDER,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@vsemana = SemanaMes, @vmes = Mes, @vano = Ano--CONVERT(varchar, DATEPART(YYYY, @VFECHA_SELEC))
	FROM	Calendar
	WHERE	Fecha = @VFECHAD
 
	IF (@VCONSULTORES = '') BEGIN
		
		SELECT	'<font size="1">Sin Consultor Seleccionado</font>' AS '<font size="1">Consultores</font>'
		
	END ELSE BEGIN
 
		SELECT '<font size="1">'+APELLIDO_EMPLEADO+', '+NOMBRE_EMPLEADO+'</font>'	AS '<font size="1">Consultores</font>',
				[dbo].[FN_GET_SEMANA] (ID_EMPLEADO, @vmes, @vano, @vsemana) AS '<font size="1">Semana</font>',
				'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_EMPLEADO)+'"'+CASE WHEN ([dbo].[FN_GET_NORMA](@vbuffer,ID_EMPLEADO) = 'SI') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">' AS '<font size="1">Lider</font>'
		FROM	LK_EMPLEADOS
		WHERE	[dbo].[FN_GET_NORMA](@VCONSULTORES,ID_EMPLEADO) = 'SI'
 
	END	
	
END
