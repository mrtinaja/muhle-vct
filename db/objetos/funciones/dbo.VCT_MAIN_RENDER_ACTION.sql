 
CREATE   FUNCTION [dbo].[VCT_MAIN_RENDER_ACTION]
(
    @ACTION_ID   VARCHAR(100),
    @TITLE       VARCHAR(200),
    @ICON        VARCHAR(100),
    @STORAGE_KEY VARCHAR(100),
    @TARGET_TAB  VARCHAR(100),
    @TARGET_GUID VARCHAR(100),
    @KEY_VALUE   VARCHAR(200),
    @CSS_CLASS   VARCHAR(200),
    @LABEL       VARCHAR(100)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE
        @HTML VARCHAR(MAX),
        @A VARCHAR(500),
        @T VARCHAR(500),
        @I VARCHAR(500),
        @S VARCHAR(500),
        @TAB VARCHAR(500),
        @G VARCHAR(500),
        @K VARCHAR(1000),
        @C VARCHAR(500),
        @L VARCHAR(500);
 
    SET @A   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@ACTION_ID,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @T   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@TITLE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @I   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@ICON,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @S   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@STORAGE_KEY,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @TAB = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@TARGET_TAB,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @G   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@TARGET_GUID,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @K   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@KEY_VALUE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @C   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@CSS_CLASS,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;');
    SET @L   = REPLACE(REPLACE(REPLACE(ISNULL(@LABEL,''),'&','&amp;'),'<','&lt;'),'>','&gt;');
 
    SET @HTML =
        '<button type="button" class="' + @C + '" ' +
        'data-vct-command="grid-action" ' +
        'data-vct-action-id="' + @A + '" ' +
        'data-vct-store="' + @S + '" ' +
        'data-vct-value="' + @K + '" ' +
        'data-vct-guid="' + @G + '" ' +
        'data-vct-target-tab="' + @TAB + '" ' +
        'data-vct-tooltip="' + @T + '">' +
            CASE WHEN @I <> '' THEN '<span data-vct-icon="' + @I + '"></span>' ELSE '' END +
            CASE WHEN @L <> '' THEN '<span>' + @L + '</span>' ELSE '' END +
        '</button>';
 
    RETURN @HTML;
END
