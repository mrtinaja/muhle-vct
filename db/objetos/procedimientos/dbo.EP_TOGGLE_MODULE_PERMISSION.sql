 
CREATE PROCEDURE [dbo].[EP_TOGGLE_MODULE_PERMISSION]
(
    @GroupId VARCHAR(50),
    @ModuleId VARCHAR(50),
    @IsVisible BIT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF EXISTS (SELECT 1 FROM GroupModulePermissions WHERE GroupId = @GroupId AND ModuleId = @ModuleId)
    BEGIN
        UPDATE GroupModulePermissions
        SET IsVisible = @IsVisible
        WHERE GroupId = @GroupId AND ModuleId = @ModuleId;
    END
    ELSE
    BEGIN
        INSERT INTO GroupModulePermissions (GroupId, ModuleId, IsVisible)
        VALUES (@GroupId, @ModuleId, @IsVisible);
    END
END
