 
CREATE PROCEDURE [dbo].[M_CONFIG_SECTORES]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- La estructura y la grilla de usuarios se renderizan en
    -- M_CONFIG_PREV_SECTORES mediante vct_RenderGrid en modo OUTPUT.
    -- Este procedimiento no debe devolver otro resultset porque
    -- vct-Core intentaría montar una segunda grilla.
    UPDATE dbo.M_CONFIG
    SET ID_GROUP_SEL  = NULL,
        ID_SECTOR_SEL = NULL,
        NEW_NAME      = NULL,
        NEW_EMAIL     = NULL,
        NEW_AREA      = NULL
    WHERE PAR_KEY = @IPKEYJOB;
END;
