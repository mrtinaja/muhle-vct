 
CREATE   PROCEDURE [dbo].[VCT_RENDER_BACK_BUTTON]
(
    @FORM_ID     VARCHAR(100),
    @TARGET_GUID VARCHAR(100),
    @TITLE       VARCHAR(100) = 'Volver',
    @HTML        VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @Q CHAR(1) = CHAR(39); -- Comilla simple "'"
    DECLARE @V_FORM_CLEAN VARCHAR(100) = REPLACE(ISNULL(@FORM_ID, ''), '''', '');
    DECLARE @V_GUID_CLEAN VARCHAR(100) = REPLACE(ISNULL(@TARGET_GUID, ''), '', '');
 
    -- Construcción segura del evento OnClick en JS
    DECLARE @JS_ONCLICK VARCHAR(MAX) = 
        'try{' +
            'if(typeof window.almacenarSeleccion===' + @Q + 'function' + @Q + '){' +
                'window.almacenarSeleccion(' + @Q + 'ID_ACTION_SEL' + @Q + ',' + @Q + @Q + ');' +
                'window.almacenarSeleccion(' + @Q + 'NEW_ID' + @Q + ',' + @Q + @Q + ');' +
                'window.almacenarSeleccion(' + @Q + 'ACTION' + @Q + ',' + @Q + @Q + ');' +
            '}' +
            'if(typeof window.goto===' + @Q + 'function' + @Q + '){' +
                'window.goto(' + @Q + @V_FORM_CLEAN + @Q + ',' + @Q + @V_GUID_CLEAN + @Q + ');' +
            '}else if(typeof window.next===' + @Q + 'function' + @Q + '){' +
                'window.next();' +
            '}' +
        '}catch(e){console.error(' + @Q + 'Error VCT-BACK:' + @Q + ',e);} return false;';
 
    SET @HTML = CAST(
        '<button type="button" class="vct-circular-back-btn" title="' + REPLACE(@TITLE, '"', '&quot;') + '" onclick="' + @JS_ONCLICK + '">' +
            '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">' +
                '<line x1="19" y1="12" x2="5" y2="12"></line>' +
                '<polyline points="12 19 5 12 12 5"></polyline>' +
            '</svg>' +
        '</button>'
    AS VARCHAR(MAX));
END
