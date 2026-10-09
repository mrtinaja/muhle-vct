 
CREATE PROCEDURE [dbo].[M_CONFIG_SECTOR_USERS]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE
        @ID_SECTOR_SEL     VARCHAR(50) = '',
        @ID_SECTOR_SEL_INT INT = NULL;
 
    SELECT
        @ID_SECTOR_SEL = ISNULL(ID_SECTOR_SEL, '')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF ISNUMERIC(@ID_SECTOR_SEL) = 1
        SET @ID_SECTOR_SEL_INT = CONVERT(INT, @ID_SECTOR_SEL);
 
    IF OBJECT_ID('tempdb..#TmpSectorUsers') IS NOT NULL
        DROP TABLE #TmpSectorUsers;
 
    SELECT
        Usuario = ISNULL(U.Id_User, ''),
        Nombre  = ISNULL(US.Name, '')
    INTO #TmpSectorUsers
    FROM dbo.UsersSector U WITH (NOLOCK)
    INNER JOIN dbo.Users US WITH (NOLOCK)
        ON U.Id_User = US.Id
    WHERE U.Id_Sector = @ID_SECTOR_SEL_INT
    ORDER BY U.Id_User;
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpSectorUsers',
         @FormId        = @FORM_ID,
         @ActionsJson   = '[]',
         @PageSize      = 10,
         @HiddenColumns = '',
         @ScriptVersion = '9.9.9';
 
    IF OBJECT_ID('tempdb..#TmpSectorUsers') IS NOT NULL
        DROP TABLE #TmpSectorUsers;
END
