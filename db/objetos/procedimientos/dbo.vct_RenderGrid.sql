 
CREATE PROCEDURE [dbo].[vct_RenderGrid]
(
    @TempTableName VARCHAR(100),
    @FormId        VARCHAR(100) = '',
    @ActionsJson   VARCHAR(MAX) = '',
    @PageSize      INT = 10,
    @HiddenColumns VARCHAR(MAX) = '',
    @HtmlColumns   VARCHAR(MAX) = '',
    @ScriptVersion VARCHAR(10) = '18.0.0',
    @RenderMode    VARCHAR(20) = 'RESULTSET',
    @HTML          VARCHAR(MAX) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @TempTableName = LTRIM(RTRIM(ISNULL(@TempTableName, '')));
    SET @FormId = ISNULL(@FormId, '');
    SET @ActionsJson = LTRIM(RTRIM(ISNULL(@ActionsJson, '')));
    SET @HiddenColumns = LTRIM(RTRIM(ISNULL(@HiddenColumns, '')));
    SET @HtmlColumns = LTRIM(RTRIM(ISNULL(@HtmlColumns, '')));
    SET @RenderMode = UPPER(LTRIM(RTRIM(ISNULL(@RenderMode, 'RESULTSET'))));
 
    IF ISNULL(@ScriptVersion, '') = ''
        SET @ScriptVersion = '18.0.0';
 
    IF ISNULL(@PageSize, 0) <= 0
        SET @PageSize = 10;
 
    IF @RenderMode NOT IN ('RESULTSET', 'OUTPUT', 'NONE')
        SET @RenderMode = 'RESULTSET';
 
    DECLARE @TempObjectId INT;
    SET @TempObjectId = OBJECT_ID('tempdb..' + @TempTableName);
 
    IF @TempObjectId IS NULL
    BEGIN
        SET @HTML = '';
        RETURN;
    END;
 
    -------------------------------------------------------------------------
    -- COLUMNAS OCULTAS
    -------------------------------------------------------------------------
    DECLARE @CleanHidden VARCHAR(MAX) = '';
 
    IF @HiddenColumns <> ''
    BEGIN
        SET @CleanHidden =
            ',' + LOWER(REPLACE(REPLACE(@HiddenColumns, ' ', ''), ';', ',')) + ',';
 
        WHILE CHARINDEX(',,', @CleanHidden) > 0
            SET @CleanHidden = REPLACE(@CleanHidden, ',,', ',');
    END;
 
    -------------------------------------------------------------------------
    -- COLUMNAS HTML
    -------------------------------------------------------------------------
    DECLARE @CleanHtml VARCHAR(MAX) = '';
 
    IF @HtmlColumns <> ''
    BEGIN
        SET @CleanHtml =
            ',' + LOWER(REPLACE(REPLACE(@HtmlColumns, ' ', ''), ';', ',')) + ',';
 
        WHILE CHARINDEX(',,', @CleanHtml) > 0
            SET @CleanHtml = REPLACE(@CleanHtml, ',,', ',');
    END;
 
    -------------------------------------------------------------------------
    -- METADATA DE COLUMNAS
    -------------------------------------------------------------------------
    DECLARE @ColumnsJson VARCHAR(MAX) = '[]';
 
    SELECT @ColumnsJson =
        '[' +
        ISNULL(
            STUFF(
                (
                    SELECT
                        ',' +
                        '{' +
                            '"title":"' + STRING_ESCAPE(REPLACE(c.name, '_', ' '), 'json') + '",' +
                            '"data":"' + STRING_ESCAPE(c.name, 'json') + '",' +
                            '"visible":true,' +
                            '"vctHidden":' +
                                CASE
                                    WHEN @CleanHidden <> ''
                                     AND CHARINDEX(',' + LOWER(c.name) + ',', @CleanHidden) > 0
                                    THEN 'true'
                                    ELSE 'false'
                                END + ',' +
                            '"searchable":' +
                                CASE
                                    WHEN @CleanHidden <> ''
                                     AND CHARINDEX(',' + LOWER(c.name) + ',', @CleanHidden) > 0
                                    THEN 'false'
                                    ELSE 'true'
                                END + ',' +
                            '"orderable":' +
                                CASE
                                    WHEN @CleanHidden <> ''
                                     AND CHARINDEX(',' + LOWER(c.name) + ',', @CleanHidden) > 0
                                    THEN 'false'
                                    ELSE 'true'
                                END + ',' +
                            '"exportable":' +
                                CASE
                                    WHEN @CleanHidden <> ''
                                     AND CHARINDEX(',' + LOWER(c.name) + ',', @CleanHidden) > 0
                                    THEN 'false'
                                    ELSE 'true'
                                END + ',' +
                            '"html":' +
                                CASE
                                    WHEN @CleanHtml <> ''
                                     AND CHARINDEX(',' + LOWER(c.name) + ',', @CleanHtml) > 0
                                    THEN 'true'
                                    ELSE 'false'
                                END +
                        '}'
                    FROM tempdb.sys.columns c
                    WHERE c.object_id = @TempObjectId
                    ORDER BY c.column_id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'),
                1,
                1,
                ''
            ),
            ''
        ) +
        ']';
 
    -------------------------------------------------------------------------
    -- DATOS JSON
    -------------------------------------------------------------------------
    DECLARE @JsonData VARCHAR(MAX) = '[]';
    DECLARE @SqlDynamic NVARCHAR(MAX);
 
    SET @SqlDynamic = N'
        SELECT @JsonOut =
            ISNULL(
                (
                    SELECT *
                    FROM ' + QUOTENAME(@TempTableName) + N'
                    FOR JSON PATH
                ),
                ''[]''
            );
    ';
 
    EXEC sys.sp_executesql
         @stmt = @SqlDynamic,
         @params = N'@JsonOut VARCHAR(MAX) OUTPUT',
         @JsonOut = @JsonData OUTPUT;
 
    -------------------------------------------------------------------------
    -- ACCIONES
    -------------------------------------------------------------------------
    DECLARE @ActionsConfig VARCHAR(MAX);
 
    SET @ActionsConfig =
        CASE
            WHEN ISJSON(@ActionsJson) = 1 THEN @ActionsJson
            ELSE '[]'
        END;
 
    -------------------------------------------------------------------------
    -- ESCAPE PARA ATRIBUTOS HTML
    -------------------------------------------------------------------------
    DECLARE @AttrJsonData VARCHAR(MAX);
    DECLARE @AttrColumnsJson VARCHAR(MAX);
    DECLARE @AttrActionsConfig VARCHAR(MAX);
    DECLARE @AttrFormId VARCHAR(MAX);
    DECLARE @AttrHiddenColumns VARCHAR(MAX);
 
    SET @AttrJsonData =
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @JsonData,
            '&', '&amp;'),
            '"', '&quot;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '''', '&#39;');
 
    SET @AttrColumnsJson =
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @ColumnsJson,
            '&', '&amp;'),
            '"', '&quot;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '''', '&#39;');
 
    SET @AttrActionsConfig =
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @ActionsConfig,
            '&', '&amp;'),
            '"', '&quot;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '''', '&#39;');
 
    SET @AttrFormId =
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @FormId,
            '&', '&amp;'),
            '"', '&quot;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '''', '&#39;');
 
    SET @AttrHiddenColumns =
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            ISNULL(@HiddenColumns, ''),
            '&', '&amp;'),
            '"', '&quot;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '''', '&#39;');
 
    -------------------------------------------------------------------------
    -- IDS UNICOS
    -------------------------------------------------------------------------
    DECLARE @TableId VARCHAR(100);
    DECLARE @SourceId VARCHAR(100);
 
    SET @TableId =
        'vctSource_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
 
    SET @SourceId =
        'vctGridSource_' +
        REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
 
    -------------------------------------------------------------------------
    -- COLUMNAS HTML PARA JAVASCRIPT
    -------------------------------------------------------------------------
    DECLARE @SafeHtmlColumns VARCHAR(MAX);
 
    SET @SafeHtmlColumns =
        STRING_ESCAPE(REPLACE(ISNULL(@HtmlColumns, ''), ';', ','), 'json');
 
    -------------------------------------------------------------------------
    -- HTML FINAL
    -------------------------------------------------------------------------
    SET @HTML =
        '<link rel="stylesheet" type="text/css" href="../css/vct-Table.css?v=' + @ScriptVersion + '" />' +
 
        '<div id="' + @SourceId + '" class="vct-grid-source" ' +
             'data-vct-grid-source ' +
             'data-vct-actions="' + @AttrActionsConfig + '" ' +
             'data-vct-form-id="' + @AttrFormId + '" ' +
             'data-vct-hidden-columns="' + @AttrHiddenColumns + '">' +
 
            '<table id="' + @TableId + '" ' +
                   'data-vct-table ' +
                   'data-vct-form-id="' + @AttrFormId + '" ' +
                   'data-vct-page-size="' + CONVERT(VARCHAR(10), @PageSize) + '" ' +
                   'data-vct-columns="' + @AttrColumnsJson + '" ' +
                   'data-vct-data="' + @AttrJsonData + '" ' +
                   'data-vct-actions="' + @AttrActionsConfig + '" ' +
                   'data-vct-hidden-columns="' + @AttrHiddenColumns + '">' +
            '</table>' +
 
        '</div>' +
 
        ---------------------------------------------------------------------
        -- POSTPROCESO EXCLUSIVO PARA COLUMNAS @HtmlColumns
        ---------------------------------------------------------------------
        CASE
            WHEN @HtmlColumns = '' THEN ''
            ELSE
            '<script type="text/javascript">
            (function(){
                "use strict";
 
                var sourceId = "' + @SourceId + '";
                var tableId = "' + @TableId + '";
                var htmlColumns = "' + @SafeHtmlColumns + '"
                    .split(",")
                    .map(function(v){ return String(v || "").trim(); })
                    .filter(function(v){ return v !== ""; });
 
                if (!htmlColumns.length) return;
 
                function normalize(value) {
                    return String(value || "")
                        .replace(/_/g, " ")
                        .replace(/\s+/g, " ")
                        .trim()
                        .toLowerCase();
                }
 
                function getTable() {
                    var table = document.getElementById(tableId);
                    if (table) return table;
 
                    var source = document.getElementById(sourceId);
                    if (!source) return null;
 
                    return source.querySelector("table");
                }
 
                function applyHtmlColumns() {
                    var table = getTable();
                    if (!table) return;
 
                    var headerCells = table.querySelectorAll("thead th");
                    if (!headerCells.length) return;
 
                    htmlColumns.forEach(function(columnName) {
                        var wanted = normalize(columnName);
                        var columnIndex = -1;
 
                        for (var i = 0; i < headerCells.length; i++) {
                            var headerText = normalize(headerCells[i].textContent);
 
                            if (headerText === wanted) {
                                columnIndex = i;
                                break;
                            }
                        }
 
                        if (columnIndex < 0) return;
 
                        var rows = table.querySelectorAll("tbody > tr");
 
                        for (var r = 0; r < rows.length; r++) {
                            var cells = rows[r].children;
 
                            if (!cells || !cells[columnIndex]) continue;
 
                            var td = cells[columnIndex];
 
                            if (td.getAttribute("colspan")) continue;
 
                            var text = td.textContent || "";
                            text = text.trim();
 
                            if (
                                text.indexOf("<") !== -1 &&
                                text.indexOf(">") !== -1
                            ) {
                                td.innerHTML = text;
                            }
                        }
                    });
                }
 
                function start() {
                    applyHtmlColumns();
 
                    var source = document.getElementById(sourceId);
 
                    if (
                        source &&
                        typeof MutationObserver === "function"
                    ) {
                        var pending = false;
 
                        var observer = new MutationObserver(function() {
                            if (pending) return;
 
                            pending = true;
 
                            setTimeout(function() {
                                pending = false;
                                applyHtmlColumns();
                            }, 0);
                        });
 
                        observer.observe(source, {
                            childList: true,
                            subtree: true
                        });
                    }
 
                    var tries = 0;
 
                    function retry() {
                        applyHtmlColumns();
 
                        tries++;
 
                        if (tries < 20) {
                            setTimeout(retry, 100);
                        }
                    }
 
                    retry();
                }
 
                if (document.readyState === "loading") {
                    document.addEventListener("DOMContentLoaded", start);
                } else {
                    start();
                }
            })();
            </script>'
        END;
 
    -------------------------------------------------------------------------
    -- SALIDA
    -------------------------------------------------------------------------
    IF @RenderMode = 'NONE'
        RETURN;
 
    IF @RenderMode = 'OUTPUT'
        RETURN;
 
    SELECT @HTML AS GRID;
END
