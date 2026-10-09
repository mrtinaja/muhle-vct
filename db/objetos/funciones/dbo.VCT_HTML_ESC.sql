 
/* ---------------- 3. funciones ---------------- */
CREATE   FUNCTION dbo.VCT_HTML_ESC (@S VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@S,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
END
