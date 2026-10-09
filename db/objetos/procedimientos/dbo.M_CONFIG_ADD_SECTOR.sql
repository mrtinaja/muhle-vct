CREATE   PROCEDURE [dbo].[M_CONFIG_ADD_SECTOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100))
AS
 
BEGIN	
 
	declare 
	@NEW_NAME VARCHAR(100),
	@NEW_AREA VARCHAR(100),
	@NEW_MAIL VARCHAR(100)
	
	SELECT  @NEW_MAIL =ltrim(rtrim( NEW_EMAIL)), 
			@NEW_NAME=ltrim(rtrim( NEW_NAME)), 
			@NEW_AREA=NEW_AREA 
	FROM M_CONFIG WHERE PAR_KEY = @IPKEYJOB;
 
	IF @NEW_AREA=''
		SET @NEW_AREA='1'
 
	insert into Sectores (Desc_Sector,Mail_Sector, Id_Area, ModifiedDate, Userid) 
	values (@NEW_NAME ,@NEW_MAIL, convert(numeric,@NEW_AREA) , GETDATE(),@IUSERID)
		
END
