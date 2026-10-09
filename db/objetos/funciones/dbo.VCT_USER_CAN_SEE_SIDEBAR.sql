 
CREATE FUNCTION dbo.VCT_USER_CAN_SEE_SIDEBAR
(
    @USER_ID      NVARCHAR(100),
    @SIDEBAR_NAME NVARCHAR(100)
)
RETURNS BIT
AS
BEGIN
    DECLARE @RESULT BIT;
 
    SET @RESULT = 0;
 
    IF EXISTS (
        SELECT 1
        FROM dbo.SideBar SB WITH (NOLOCK)
            INNER JOIN dbo.SideBarGroups SBG WITH (NOLOCK)
                ON SBG.SideBarId = SB.Id
            INNER JOIN dbo.GroupsUserMembers GUM WITH (NOLOCK)
                ON GUM.GroupId = SBG.GroupId
        WHERE UPPER(LTRIM(RTRIM(GUM.UserMemberId))) = UPPER(LTRIM(RTRIM(@USER_ID)))
          AND UPPER(LTRIM(RTRIM(SB.Name))) = UPPER(LTRIM(RTRIM(@SIDEBAR_NAME)))
    )
    BEGIN
        SET @RESULT = 1;
    END;
 
    RETURN @RESULT;
END
