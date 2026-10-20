/* ============================================================================
   DIAG_DUMP_CONSULTOR_TOOLTIP  (v3 - sin IF/ELSE, para evitar el ;WITH)
   ----------------------------------------------------------------------------
   Vuelca dos definiciones vivas. SOLO LECTURA.
     OBJ 1 = dbo.VCT_FN_AGENDA_ACTIVIDADES_RANGO
     OBJ 2 = dbo.VCT_MAIN_CONSULTORES_V360
   USO: SSMS -> Query -> "SQLCMD Mode" (si tu :OUT no escribe el .txt, copiá la
        grilla y pegala). F5.
        Archivo: C:\Users\Usuario\Desktop\muhle-vct\_diag\CONSULTOR_TOOLTIP.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\CONSULTOR_TOOLTIP.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @D1 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_FN_AGENDA_ACTIVIDADES_RANGO'));
WITH N AS (
    SELECT 1 AS SEQ, CONVERT(INT,1) AS POS
    UNION ALL SELECT SEQ+1, POS+4000 FROM N WHERE POS+4000 <= ISNULL(DATALENGTH(@D1)/2, 0)
)
SELECT 1 AS OBJ, SEQ,
       ISNULL(CONVERT(NVARCHAR(4000), SUBSTRING(@D1, POS, 4000)), '>>> NULL: no existe VCT_FN_AGENDA_ACTIVIDADES_RANGO <<<') AS TXT
FROM N ORDER BY SEQ OPTION (MAXRECURSION 0);

DECLARE @D2 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'));
WITH N AS (
    SELECT 1 AS SEQ, CONVERT(INT,1) AS POS
    UNION ALL SELECT SEQ+1, POS+4000 FROM N WHERE POS+4000 <= ISNULL(DATALENGTH(@D2)/2, 0)
)
SELECT 2 AS OBJ, SEQ,
       ISNULL(CONVERT(NVARCHAR(4000), SUBSTRING(@D2, POS, 4000)), '>>> NULL: no existe VCT_MAIN_CONSULTORES_V360 <<<') AS TXT
FROM N ORDER BY SEQ OPTION (MAXRECURSION 0);

:OUT stdout
