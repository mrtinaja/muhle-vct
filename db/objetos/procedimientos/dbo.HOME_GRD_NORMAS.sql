CREATE PROCEDURE [dbo].[HOME_GRD_NORMAS]
(@IPKEYJOB	AS VARCHAR(100))
AS
 
DECLARE @VID_PROYECTO	INT,
		@VID			INT,
		@VDESC			VARCHAR(400),
		@VNORMAS		VARCHAR(400),
		@VCANT			INT,
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VTORF			VARCHAR(50),
		@VQUERY			VARCHAR(MAX)
 
BEGIN	
 
	SELECT	@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VNORMAS = BUFFER
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VID_PROYECTO = '') BEGIN
		
		--SELECT	'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_APTITUD)+'"'+CASE WHEN ([dbo].[FN_GET_NORMA2](@VNORMAS,ID_APTITUD) = 'true') THEN 'checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">' AS '<font size="1">-</font>',
		--		'<font size="1">'+DESC_APTITUD+'</font>'											AS '<font size="1">Normas</font>'
		--FROM	LK_APTITUDES
		--WHERE	STATUS_APTITUD = '1'
 
		SELECT	'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_APTITUD)+'" '+CASE WHEN ([dbo].[FN_GET_NORMA2](@VNORMAS,ID_APTITUD) = 'true') THEN ' checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">&nbsp;&nbsp;'+DESC_APTITUD AS 'Normas'
		FROM	LK_APTITUDES
		WHERE	STATUS_APTITUD = '1'
	
	END ELSE BEGIN
 
		SELECT	@VNORMAS = ISNULL(NORMAS,'')
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VID_PROYECTO	
 
		--SELECT	'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_APTITUD)+'" '+CASE WHEN ([dbo].[FN_GET_NORMA](@VNORMAS,ID_APTITUD) = 'SI') THEN 'checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">' AS '<font size="1">-</font>',
		--		'<font size="1">'+DESC_APTITUD+'</font>'											AS '<font size="1">Normas</font>'
		--FROM	LK_APTITUDES
		--WHERE	STATUS_APTITUD = '1'
 
		SELECT	'<input type="checkbox" id="'+CONVERT(VARCHAR,ID_APTITUD)+'" '+CASE WHEN ([dbo].[FN_GET_NORMA](@VNORMAS,ID_APTITUD) = 'SI') THEN 'checked="true"' ELSE '' END +' onchange="toggleCheckbox(this);">&nbsp;&nbsp;'+DESC_APTITUD AS 'Normas'
		FROM	LK_APTITUDES
		WHERE	STATUS_APTITUD = '1'
 
	END	
	
END
 
