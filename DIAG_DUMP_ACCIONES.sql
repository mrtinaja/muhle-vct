/* ============================================================================
   DIAG_DUMP_ACCIONES  (v2 - salida por SELECT, no PRINT)
   ----------------------------------------------------------------------------
   Vuelca la definicion VIVA de dbo.VCT_MAIN_ACCIONES a un .txt del repo para
   diagnosticar por que "Nueva" salta a la misma pantalla.
   La v1 usaba PRINT (que en SSMS va a la pestania Messages, no a :OUT); esta
   version sale como RESULT SET en filas de 4000 chars -> :OUT la captura OK.
   Solo lee, no modifica.

   USO: SSMS -> menu Query -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_ACCIONES.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_ACCIONES.txt
:XML OFF
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @NAME SYSNAME = 'dbo.VCT_MAIN_ACCIONES';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@NAME));

IF @D IS NULL
BEGIN
    SELECT 0 AS SEQ, CONVERT(NVARCHAR(4000),
        'NULL: no se encontro dbo.VCT_MAIN_ACCIONES (nombre o permiso VIEW DEFINITION).') AS TXT;
END
ELSE
BEGIN
    ;WITH N AS (
        SELECT 1 AS SEQ, CONVERT(INT,1) AS POS
        UNION ALL
        SELECT SEQ + 1, POS + 4000 FROM N WHERE POS + 4000 <= DATALENGTH(@D) / 2
    )
    SELECT SEQ, CONVERT(NVARCHAR(4000), SUBSTRING(@D, POS, 4000)) AS TXT
    FROM N
    ORDER BY SEQ
    OPTION (MAXRECURSION 0);
END;
:OUT stdout
