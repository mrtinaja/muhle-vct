 
CREATE FUNCTION [dbo].[VCT_USER_HAS_ACTION]
(
    @USER_ID      NVARCHAR(100),
    @SIDEBAR_NAME NVARCHAR(100),
    @ACTION_CODE  NVARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    
    --aca tiene que ser por perfil-- (gerencia: devuelva todas las acciiones habilitas) la funcion debe devolver todas las acciones habilitadas 
    --por grupo (o si entra por usuario, recuperar el grupo) y opcional ?? si le agregas un param por opcion de menu... (agregar idSidebar en Actions)
    
    DECLARE @RESULT BIT;
    DECLARE @ACTION_ID NVARCHAR(150);
 
    SET @RESULT = 0;
    SET @ACTION_ID = UPPER(LTRIM(RTRIM(@SIDEBAR_NAME))) + '.' + UPPER(LTRIM(RTRIM(@ACTION_CODE)));
 
    IF EXISTS (
        SELECT 1
        FROM dbo.GroupsUserMembers GUM WITH (NOLOCK)
            INNER JOIN dbo.GroupsActions GA WITH (NOLOCK)
                ON GA.GroupId = GUM.GroupId
            INNER JOIN dbo.Actions A WITH (NOLOCK)
                ON A.Id = GA.ActionId
        WHERE UPPER(LTRIM(RTRIM(GUM.UserMemberId))) = UPPER(LTRIM(RTRIM(@USER_ID)))
          AND UPPER(LTRIM(RTRIM(A.Id))) = @ACTION_ID
    )
    BEGIN
        SET @RESULT = 1;
    END;
 
    RETURN @RESULT;
END
