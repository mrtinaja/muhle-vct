 
CREATE PROCEDURE [dbo].[M_CONFIG_AREAS]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100),
    @FORM_ID  AS VARCHAR(100)
)
AS
BEGIN	
    SET NOCOUNT ON;
 
    IF OBJECT_ID('tempdb..#TmpAreas') IS NOT NULL
        DROP TABLE #TmpAreas;
 
    SELECT	
        PKey                 = CONVERT(VARCHAR(100), A.Id_Area),
        ID                   = CONVERT(VARCHAR(100), A.Id_Area),
        [DESCRIPCION]        = ISNULL(A.Desc_Area, ''),
        [SECTORES ASOCIADOS] = ISNULL(SECTAREA.sectores, '')
    INTO #TmpAreas
    FROM Areas A WITH (NOLOCK)
    LEFT OUTER JOIN (
        SELECT sct.Id_Area,
               STRING_AGG(sct.Desc_Sector, ', ') AS sectores
        FROM Sectores sct WITH (NOLOCK)
        GROUP BY sct.Id_Area
    ) SECTAREA ON A.Id_Area = SECTAREA.Id_Area
    ORDER BY A.Id_Area;
 
    -- Configuración Nativa VCT: Edit (Lápiz) + Delete (Tacho Rojo)
    DECLARE @ActionsJson VARCHAR(MAX) = 
    '[
        {
            "type": "edit",
            "title": "Editar Área",
            "icon": "pen-line",
            "keyField": "PKey",
            "targetGuid": "62DE8169-4D9E-4A7F-98DD-412AE6DFC080",
            "storageKey": "ID_USER_SEL"
        },
        {
            "type": "delete",
            "title": "Eliminar Área",
            "icon": "trash-2",
            "variant": "danger",
            "keyField": "PKey",
            "targetGuid": "280E17F8-68A5-4DD9-B1CB-1B0670DE688B",
            "storageKey": "ID_DELETE"
        }
    ]';
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpAreas',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HiddenColumns = 'PKey',
         @ScriptVersion = '5.4.5';
 
    IF OBJECT_ID('tempdb..#TmpAreas') IS NOT NULL
        DROP TABLE #TmpAreas;
 
END
