:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\VCT_MAIN_ACCIONES.txt
/* ============================================================================
   DIAG_ACCIONES_PANTALLA (29/10/2026)  solo lectura
   Para llevar la pantalla Acciones (pestanias, Lista | Calendario, filtros, columnas, Gestionar y Graficos)
   a la card "Para hacer" del Tablero del consultor, sobre la version VIVA:
   vuelca dbo.VCT_MAIN_ACCIONES a _diag\VCT_MAIN_ACCIONES.txt.
   SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_ACCIONES'));
IF @D IS NULL PRINT 'No se encontro dbo.VCT_MAIN_ACCIONES.'
ELSE
BEGIN
    DECLARE @TOTAL INT = DATALENGTH(@D) / 2, @P INT = 1, @E INT, @LINE NVARCHAR(MAX);
    WHILE @P <= @TOTAL
    BEGIN
        SET @E = CHARINDEX(NCHAR(10), @D, @P);
        IF @E = 0 SET @E = @TOTAL + 1;
        SET @LINE = SUBSTRING(@D, @P, @E - @P);
        IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13) SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
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
