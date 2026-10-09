CREATE FUNCTION [dbo].[FN_GET_SERVICIOS_PROY] (@IPROYECTO INT, @FORM_ID VARCHAR(100), @ITIPO VARCHAR(50))
RETURNS VARCHAR(MAX)
AS BEGIN
    DECLARE @VTIPO		VARCHAR(50),
			@VID		INT,
			@VCIERRE	VARCHAR(50),
			@VHORAS		INT,
			@VTOTAL		INT,
			@VICONS		VARCHAR(MAX),
			@VEXISTE_CONS	VARCHAR(50),
			@VEXISTE_AUDI	VARCHAR(50),
			@VEXISTE_CAPA	VARCHAR(50)
 
	DECLARE Servicios CURSOR FOR 
		SELECT	DISTINCT ID_TIPO_SERVICIO TIPO_SERVICIO--, CASE WHEN ID_TIPO_SERVICIO = '1' THEN CIERRE ELSE '' END, [dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('S', @IPROYECTO, ID_TIPO_SERVICIO, NULL) HORAS
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @IPROYECTO
				
			
	OPEN Servicios  
	FETCH NEXT FROM Servicios INTO @VTIPO--, @VCIERRE, @VHORAS
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		IF (@ITIPO = 'I') BEGIN
			SET @VICONS = isnull(@VICONS,'') +
				'<i class="'+ CASE WHEN @VTIPO = '1' THEN 
									'fas fa-user-tie w3-medium"'
								WHEN @VTIPO = '2' THEN 
									'fas fa-chalkboard-teacher w3-medium"'
								WHEN @VTIPO = '3' THEN 
									'fas fa-user-graduate w3-medium"' END+
				'style="cursor:pointer;" title="'+	CASE WHEN @VTIPO = '1' THEN 
															'Consultoria'-- - ('+CONVERT(VARCHAR,@VHORAS)+')"'
														WHEN @VTIPO = '2' THEN 
															'Auditoria'-- - ('+CONVERT(VARCHAR,@VHORAS)+')"'
														WHEN @VTIPO = '3' THEN 
															'Capacitacion'-- - ('+CONVERT(VARCHAR,@VHORAS)+')"' 
													END+ '"</i>&nbsp;'
		END
		
		IF (@ITIPO = 'D') BEGIN
			SET @VICONS = isnull(@VICONS,'') + CASE WHEN @VTIPO = '1' THEN 'Consultoria'
													WHEN @VTIPO = '2' THEN 'Auditoria'
													WHEN @VTIPO = '3' THEN 'Capacitacion' END+ '</i>&nbsp;'
		END
 
		FETCH NEXT FROM Servicios INTO @VTIPO--, @VCIERRE, @VHORAS
	END 
 
	CLOSE Servicios  
	DEALLOCATE Servicios
 
	RETURN ISNULL(@VICONS,'')
END
