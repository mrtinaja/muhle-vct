 
CREATE PROCEDURE [dbo].[EP_USR_DISP_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID as varchar(100))
AS
 
BEGIN	
 
 
	DECLARE @ID_PLANTA_SEL VARCHAR(50);
	
	SELECT @ID_PLANTA_SEL = ID_PLANTA_SEL FROM TMT_CRON WHERE PAR_KEY= @IPKEYJOB;
 
	UPDATE TMT_CRON 
	SET [ACTION]='ASIGN_USER'
	WHERE PAR_KEY= @IPKEYJOB;
 
	select U.Id, U.Name, U.EMAIL, GM.GroupId as Grupo,  '<a href="javascript:saveSelection(''ID_USER_SEL'', '''+cast(U.Id as varchar)+''');next('''+@FORM_ID+''')">Agregar</a>' AS Opciones
	from GroupsUserMembers GM
	INNER JOIN Users U ON U.Id=GM.UserMemberId
	where (GroupId='EP_CLIENTES' OR GroupId='EP_EJECUTIVOS')
	and UserMemberId not in (
		select IdUsuario from
		EP_PLANTAS_USUARIOS 
		WHERE IDPLANTA = cast(@ID_PLANTA_SEL  as int) )
 
 
END
