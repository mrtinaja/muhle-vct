CREATE PROCEDURE [dbo].[HOME_CMB_ANOS_HTML]
(@SELECTED	AS VARCHAR(100),
 @FIELD_NAME AS VARCHAR(50),
 @FORM_ID	AS VARCHAR(100),
 @STEP_GOTO	AS VARCHAR(100),
 @OHTML	AS VARCHAR(MAX) OUTPUT)
AS
BEGIN	
	
 
	set @OHTML = '<div class="w3-dropdown-hover w3-grey"><button class="w3-button"><b>'+@SELECTED+'</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i class="fa fa-caret-down"></i></button><div class="w3-dropdown-content w3-bar-block w3-card-4">';
	
	SELECT @OHTML = @OHTML + '<a href="javascript:saveSelection('''+@FIELD_NAME+''','''+cast(Ano as varchar)+''');goto('''+@FORM_ID+''','''+@STEP_GOTO+''');" class="w3-bar-item w3-button">' + cast(Ano as varchar) + '</a>' 
	FROM Calendar
	GROUP BY Ano
	ORDER BY Ano
 
	set @OHTML = @OHTML + '</div></div>';
 
END
