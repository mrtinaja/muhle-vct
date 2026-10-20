/* ============================================================================
   FIX_VST_MONEY_TYPO
   ----------------------------------------------------------------------------
   Corrige el typo de asset: algun SP carga '../js/vst-money.js' (con 's':
   "vst") cuando el archivo real es 'vct-money.js' (mascara de moneda del
   Inicio). Ese 404 dispara un error de jQuery (globalEval "Unexpected token
   '<'") al inyectar la pantalla. Se reemplaza 'vst-money' -> 'vct-money' en
   la definicion viva de cualquier SP que lo tenga.

   Version-agnostico respecto del ?v (reemplaza el nombre, conserva ?v=N).
   Re-ejecutable. Solo toca el <script>, no la logica.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @oid INT, @Name SYSNAME, @D NVARCHAR(MAX), @orig NVARCHAR(MAX),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT, @N INT = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.object_id
    FROM sys.sql_modules m
    WHERE m.definition LIKE N'%vst-money%';

BEGIN TRY
    BEGIN TRANSACTION;
    OPEN cur;
    FETCH NEXT FROM cur INTO @oid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Name = OBJECT_SCHEMA_NAME(@oid) + '.' + OBJECT_NAME(@oid);
        SET @D = OBJECT_DEFINITION(@oid);
        SET @orig = @D;

        SET @D = REPLACE(@D, N'vst-money', N'vct-money');

        IF @D <> @orig
        BEGIN
            SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
            WHILE 1 = 1
            BEGIN
                SET @cp = CHARINDEX(N'CREATE', @up, @scan);
                IF @cp = 0 BREAK;
                SET @probe = CHARINDEX(N'PROC', @up, @cp);
                IF @probe > 0 AND @probe <= @cp + 40 BREAK;
                SET @scan = @cp + 6;
            END;
            IF @cp = 0
                RAISERROR('No se identifico la cabecera CREATE en %s. Se cancela.',16,1,@Name);

            IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER'
                SET @D = STUFF(@D, @cp, 15, N'ALTER');
            ELSE
                SET @D = STUFF(@D, @cp, 6, N'ALTER');

            EXEC sys.sp_executesql @D;
            SET @N = @N + 1;
            PRINT 'Typo corregido (vst-money -> vct-money): ' + @Name;
        END;

        FETCH NEXT FROM cur INTO @oid;
    END;
    CLOSE cur; DEALLOCATE cur;
    COMMIT TRANSACTION;
    IF @N = 0
        PRINT 'No se encontro ''vst-money'' en ningun SP (ya corregido o esta en un asset estatico).';
    ELSE
        PRINT 'OK: SP corregidos: ' + CONVERT(VARCHAR(10), @N) + '.';
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local','cur') >= 0 BEGIN CLOSE cur; DEALLOCATE cur; END;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado y revertido: %s',16,1,@e);
END CATCH;
GO
