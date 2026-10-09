 
CREATE PROCEDURE [dbo].[EP_PLTS_USR_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID as varchar(100))
AS
 
BEGIN	
 
 
	DECLARE @ID_PLANTA_SEL VARCHAR(50);
	
	SELECT @ID_PLANTA_SEL = ID_PLANTA_SEL FROM TMT_CRON WHERE PAR_KEY= @IPKEYJOB;
 
	UPDATE TMT_CRON SET ID_USER_SEL=NULL, NEW_ID=NULL WHERE PKEY=@IPKEYJOB;
	 
	SELECT P.Planta, U.[Name] as Usuario, G.[Name] as Perfil,
		'<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');saveSelection(''ID_USER_SEL'', '''+cast(U.Id as varchar)+''');goto('''+@FORM_ID+''',''EAC43E31-EAE2-4513-BA01-57B60CE60B25'')">Eliminar</a>&nbsp;<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');saveSelection(''ID_USER_SEL'', '''+cast(U.Id as varchar)+''');goto('''+@FORM_ID+''',''C6D22A12-BE61-48ED-8BDD-47F56F9B5914'')">Editar</a>' AS Opciones 
	FROM EP_PLANTAS P INNER JOIN EP_PLANTAS_USUARIOS PU ON P.IDPLANTA = PU.IDPLANTA
	INNER JOIN Users U ON U.Id = PU.IDUSUARIO
	INNER JOIN GroupsUserMembers GU ON GU.UserMemberId = PU.IDUSUARIO
	INNER JOIN Groups G ON G.Id = GU.GroupId
	WHERE P.IDPLANTA = @ID_PLANTA_SEL  
 
 
END
