/* ============================================================================
   FIX_ACCIONES_CAL_UNIFICADO
   ----------------------------------------------------------------------------
   La pantalla Acciones ahora monta el calendario UNIFICADO (vct-calendario,
   solo lectura) desde vct-acciones.js, en vez de dibujar su propio mes.
   Como cambió el contenido de vct-acciones.js, hay que subir su ?v para que
   el navegador no sirva el cacheado.

   Este parche opera sobre la DEFINICION VIVA del SP (no necesita la fuente):
     1) bumpea  vct-acciones.js?v=1  ->  vct-acciones.js?v=2  (bust de cache), y
     2) AGREGA, justo despues, el par UNIFICADO vct-calendario.css/js?v=7
        (para que el SP cargue vct-calendario, como la Agenda).
   Re-ejecutable: tras aplicarlo ya no existe 'vct-acciones.js?v=1', asi que una
   segunda corrida no hace nada (no duplica los tags). Solo toca los <link>/<script>.

   RECORDAR antes de correr: subir al server (sobrescribiendo)
     - js/vct-acciones.js      (nuevo: monta vct-calendario)
     - js/vct-calendario.js    (activityBadges con color por estado)
     - css/vct-calendario.css  (colores ev-V/H/P/L)
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @oid INT, @Name SYSNAME, @D NVARCHAR(MAX), @orig NVARCHAR(MAX),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT, @N INT = 0;

DECLARE @ADD NVARCHAR(400) =
    N'vct-acciones.js?v=2"></script>'
  + N'<link rel="stylesheet" href="../css/vct-calendario.css?v=7">'
  + N'<script src="../js/vct-calendario.js?v=7"></script>';

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.object_id
    FROM sys.sql_modules m
    WHERE m.definition LIKE N'%vct-acciones.js?v=1%';

BEGIN TRY
    BEGIN TRANSACTION;
    OPEN cur;
    FETCH NEXT FROM cur INTO @oid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Name = OBJECT_SCHEMA_NAME(@oid) + '.' + OBJECT_NAME(@oid);
        SET @D = OBJECT_DEFINITION(@oid);
        SET @orig = @D;

        /* bumpea vct-acciones.js y, en el mismo <script ...></script>, agrega
           el par unificado vct-calendario.css/js. Ancla en el cierre del tag. */
        SET @D = REPLACE(@D, N'vct-acciones.js?v=1"></script>', @ADD);
        /* por si el cierre tuviera otro formato, al menos bumpea la version */
        SET @D = REPLACE(@D, N'vct-acciones.js?v=1', N'vct-acciones.js?v=2');

        IF @D <> @orig
        BEGIN
            /* CREATE [OR ALTER] ... -> ALTER (ancla en el CREATE real) */
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
            PRINT 'Repuntado (vct-acciones.js v2): ' + @Name;
        END;

        FETCH NEXT FROM cur INTO @oid;
    END;
    CLOSE cur; DEALLOCATE cur;
    COMMIT TRANSACTION;
    IF @N = 0
        PRINT 'Nada que cambiar (ya en v2, o el SP usa otra version). Sin cambios.';
    ELSE
        PRINT 'OK: SP repuntados a vct-acciones.js?v=2: ' + CONVERT(VARCHAR(10), @N) + '.';
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local','cur') >= 0 BEGIN CLOSE cur; DEALLOCATE cur; END;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado y revertido: %s',16,1,@e);
END CATCH;
GO
