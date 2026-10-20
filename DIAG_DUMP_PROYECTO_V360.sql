/* ============================================================================
   DIAG_DUMP_PROYECTO_V360
   ----------------------------------------------------------------------------
   Vuelca la definicion VIVA de dbo.VCT_MAIN_PROYECTO_V360 a un .txt del repo
   para poder agregarle el calendario de acciones (vct-calendario).
   Solo lee. No modifica nada.

   USO: SSMS -> Query menu -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_PROYECTO_V360.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\VCT_MAIN_PROYECTO_V360.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @NAME SYSNAME = 'dbo.VCT_MAIN_PROYECTO_V360';
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(@NAME));

IF @D IS NULL
BEGIN
    PRINT 'No se encontro la definicion de ' + @NAME + ' (nombre / permiso VIEW DEFINITION).';
END
ELSE
BEGIN
    DECLARE @TOTAL INT = DATALENGTH(@D) / 2;
    DECLARE @P INT = 1, @E INT, @LINE NVARCHAR(MAX);
    WHILE @P <= @TOTAL
    BEGIN
        SET @E = CHARINDEX(NCHAR(10), @D, @P);
        IF @E = 0 SET @E = @TOTAL + 1;
        SET @LINE = SUBSTRING(@D, @P, @E - @P);
        IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
            SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
        WHILE (DATALENGTH(@LINE) / 2) > 4000
        BEGIN
            PRINT SUBSTRING(@LINE, 1, 4000);
            SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
        END;
        PRINT @LINE;
        SET @P = @E + 1;
    END;
END;
GO
:OUT stdout
