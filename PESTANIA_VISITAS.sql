/* ============================================================================
   PESTANIA_VISITAS  (28/10/2026)  marca PV_TAB_VISITAS
   La pestania "Agenda" de la V360 del proyecto pasa a llamarse "Visitas"
   (tambien el titulo "Visitas del proyecto" y el nombre del Excel / PDF).
   Solo textos: no cambia la logica. Re-ejecutable.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),
        @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @N INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'<span>Visitas</span></button>', @D) > 0
    PRINT 'OK   la pestania ya se llama Visitas: no se hizo nada.';
ELSE
BEGIN
    /* tab */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'<span>Agenda</span></button>';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'<span>Visitas</span></button>';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' tab(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* titulo */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'</span></span>Agenda del proyecto (';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'</span></span>Visitas del proyecto (';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' titulo(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* export */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'data-vct-dg-title="Agenda del proyecto"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'data-vct-dg-title="Visitas del proyecto"';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' export(' + CONVERT(NVARCHAR(10), @N) + N')';
    IF @F <> N''
        PRINT 'FALLO: no se encontraron en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360: la pestania Agenda ahora se llama Visitas.';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
