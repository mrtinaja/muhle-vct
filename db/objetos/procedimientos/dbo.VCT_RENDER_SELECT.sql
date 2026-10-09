 
CREATE   PROCEDURE [dbo].[VCT_RENDER_SELECT]
(
    @I_SELECT_ID     VARCHAR(100),       -- ID/Name del elemento HTML
    @I_QUERY         NVARCHAR(MAX),      -- Consulta SQL a ejecutar
    @I_SELECTED_VAL  VARCHAR(100) = '',  -- Valor seleccionado por defecto
    @I_PLACEHOLDER   NVARCHAR(150) = '',
    @I_EXTRA_CLASSES VARCHAR(200) = '',  -- Clases CSS adicionales
    @O_HTML_SELECT   VARCHAR(MAX) OUTPUT -- HTML generado
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @V_OPTIONS NVARCHAR(MAX) = '';
    DECLARE @V_CODE NVARCHAR(200), @V_DESC NVARCHAR(500), @V_ACTIVE VARCHAR(10);
 
    -- Tabla temporal para ejecutar la consulta dinámica
    IF OBJECT_ID('tempdb..#TmpSelectData') IS NOT NULL
        DROP TABLE #TmpSelectData;
 
    CREATE TABLE #TmpSelectData (
        CAT_DATA_CODE NVARCHAR(200),
        CAT_DATA_DESC NVARCHAR(500),
        IS_ACTIVE     VARCHAR(10) DEFAULT 'TRUE'
    );
 
    INSERT INTO #TmpSelectData (CAT_DATA_CODE, CAT_DATA_DESC, IS_ACTIVE)
    EXEC sp_executesql @I_QUERY;
 
    -- Opción por defecto
    IF ISNULL(@I_PLACEHOLDER, '') <> ''
    BEGIN
        SET @V_OPTIONS = '<option value="">' + REPLACE(REPLACE(@I_PLACEHOLDER, '<', '&lt;'), '>', '&gt;') + '</option>';
    END
 
    -- Recorrido de Opciones
    DECLARE CUR_VCT_SELECT CURSOR LOCAL FAST_FORWARD FOR
        SELECT 
            ISNULL(CAT_DATA_CODE, ''),
            ISNULL(CAT_DATA_DESC, ''),
            ISNULL(IS_ACTIVE, 'TRUE')
        FROM #TmpSelectData;
 
    OPEN CUR_VCT_SELECT;
    FETCH NEXT FROM CUR_VCT_SELECT INTO @V_CODE, @V_DESC, @V_ACTIVE;
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @V_OPTIONS = @V_OPTIONS + 
            '<option value="' + 
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@V_CODE, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;') + '"' +
            CASE 
                WHEN UPPER(LTRIM(RTRIM(@V_CODE))) = UPPER(LTRIM(RTRIM(@I_SELECTED_VAL))) THEN ' selected="selected"'
                ELSE ''
            END +
            CASE 
                WHEN UPPER(LTRIM(RTRIM(@V_ACTIVE))) IN ('FALSE', '0', 'NO') THEN ' disabled="disabled"'
                ELSE ''
            END + '>' +
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@V_DESC, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;'), '''', '&#39;') +
            '</option>';
 
        -- CORRECCIÓN AQUÍ: CUR_VCT_SELECT
        FETCH NEXT FROM CUR_VCT_SELECT INTO @V_CODE, @V_DESC, @V_ACTIVE;
    END;
 
    CLOSE CUR_VCT_SELECT;
    DEALLOCATE CUR_VCT_SELECT;
 
    IF OBJECT_ID('tempdb..#TmpSelectData') IS NOT NULL
        DROP TABLE #TmpSelectData;
 
    -- Select Nativo VCT Limpio
    SET @O_HTML_SELECT = 
        '<select id="' + @I_SELECT_ID + '" name="SP.' + @I_SELECT_ID + '" class="vct-select ' + ISNULL(@I_EXTRA_CLASSES, '') + '">' +
            @V_OPTIONS +
        '</select>';
 
END
