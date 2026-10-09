 
CREATE PROCEDURE [dbo].[M_CONFIG_GROUP_USERS_BK]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID AS VARCHAR(100))
AS
 
BEGIN	
 
	declare @ID_GROUP_SEL VARCHAR(50),
	@ACTION VARCHAR(50)
 
	SELECT @ID_GROUP_SEL = ID_GROUP_SEL, @ACTION=[ACTION] FROM M_CONFIG WHERE PAR_KEY = @IPKEYJOB;
 
	IF (@ACTION='VER_USUARIOS') 
		BEGIN
			UPDATE M_CONFIG SET ACTION='AGREGAR_USUARIO' WHERE PAR_KEY = @IPKEYJOB;
 
			SELECT [Name], Email, [State], LoginFailure, Phone, '<a href="javascript:saveSelection(''ID_USER_SEL'', '''+Id+''');goto('''+@FORM_ID+''',''97D60A26-8606-4D28-8BBE-6E290E407C9E'')">Eliminar</a>' AS Opciones
			FROM Users U 
			INNER JOIN GroupsUserMembers GU ON GU.UserMemberId=U.Id
			WHERE GU.GroupId=@ID_GROUP_SEL;
		END
	ELSE IF (@ACTION='AGREGAR_USUARIO') 
		BEGIN
			SELECT [Name], Email, [State], LoginFailure, Phone, '<a href="javascript:saveSelection(''ID_USER_SEL'', '''+Id+''');next('''+@FORM_ID+''');">Agregar</a>' AS Opciones
			FROM Users U 
			where Id not in (
				select UserMemberId from GroupsUserMembers 
				WHERE isnull(GroupId,'')=@ID_GROUP_SEL)
 
		END
 
		--OPCION NO IMPLEMENTADA AUN, VER GRUPOS X USUARIO
	--ELSE IF (@ACTION='VER_GRUPOS') 
	--	BEGIN
	--		SELECT [Name], Email, --,'<a href="javascript:saveSelection(''ID_USER_SEL'', '''+Id+''');next('''+@FORM_ID+'''):return false;">Agregar</a>' AS Opciones
	--		FROM Groups
	--		INNER JOIN GroupsUserMembers GU ON GU.UserMemberId=U.Id
	--		WHERE GU.GroupId<>@ID_GROUP_SEL
	--	END
 
END
