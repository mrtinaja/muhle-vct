/* ============================================================================
   DIAG_DUMP_CONSULTORES_V360   (SOLO LECTURA - salida por SELECT -> :OUT)
   ----------------------------------------------------------------------------
   Vuelca la definicion VIVA de dbo.VCT_MAIN_CONSULTORES_V360 para verificar que
   su calendario sea mensual y de SOLO LECTURA (sin KPI/selects/edicion) y poder
   aplicarle la estetica comun sin agregarle controles. El volcado del repo esta
   viejo (no muestra calendario). No modifica nada.

   USO: SSMS -> menu Query -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_CONSULTORES_V360.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_CONSULTORES_V360.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'));

IF @D IS NULL
    SELECT 0 AS SEQ, CONVERT(NVARCHAR(4000),'NULL: no se encontro dbo.VCT_MAIN_CONSULTORES_V360.') AS TXT;
ELSE
    ;WITH N AS (
        SELECT 1 AS SEQ, CONVERT(INT,1) AS POS
        UNION ALL
        SELECT SEQ + 1, POS + 4000 FROM N WHERE POS + 4000 <= DATALENGTH(@D) / 2
    )
    SELECT SEQ, CONVERT(NVARCHAR(4000), SUBSTRING(@D, POS, 4000)) AS TXT
    FROM N ORDER BY SEQ OPTION (MAXRECURSION 0);
:OUT stdout
