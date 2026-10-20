/* ============================================================================
   FIX_CALENDARIO_BUMP_V33
   ----------------------------------------------------------------------------
   Sube el ?v de vct-calendario.css/js a v=33 en TODOS los SP que lo carguen
   (Agenda del consultor, Feriados/Calendario, fichas 360, Acciones, etc.), sea
   cual sea la version viva. Asi el navegador toma el archivo nuevo (badge de
   responsable en el 360, dias pasados solo lectura y "No disponible" editable).

   Version-agnostico: busca 'vct-calendario.css?v=' / 'vct-calendario.js?v=' y
   reemplaza el token de version (hasta la comilla) por 24. Re-ejecutable (si ya
   esta en 24 lo deja igual). Solo toca los <link>/<script>, no la logica.

   RECORDAR: subir al server (sobrescribiendo) ANTES o DESPUES de correr esto:
       js/vct-calendario.js   y   css/vct-calendario.css
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @oid INT, @Name SYSNAME, @D NVARCHAR(MAX), @orig NVARCHAR(MAX),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT, @N INT = 0,
        @start INT, @q INT, @NEW NVARCHAR(4) = N'33';

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.object_id
    FROM sys.sql_modules m
    WHERE m.definition LIKE N'%vct-calendario.css?v=%'
       OR m.definition LIKE N'%vct-calendario.js?v=%';

BEGIN TRY
    BEGIN TRANSACTION;
    OPEN cur;
    FETCH NEXT FROM cur INTO @oid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Name = OBJECT_SCHEMA_NAME(@oid) + '.' + OBJECT_NAME(@oid);
        SET @D = OBJECT_DEFINITION(@oid);
        SET @orig = @D;

        /* ---- CSS: 'vct-calendario.css?v=' = 21 chars ---- */
        SET @scan = 1;
        WHILE 1 = 1
        BEGIN
            SET @cp = CHARINDEX(N'vct-calendario.css?v=', @D, @scan);
            IF @cp = 0 BREAK;
            SET @start = @cp + 21;
            SET @q = CHARINDEX(N'"', @D, @start);
            IF @q = 0 BREAK;
            SET @D = STUFF(@D, @start, @q - @start, @NEW);
            SET @scan = @start + 1;
        END;

        /* ---- JS: 'vct-calendario.js?v=' = 20 chars ---- */
        SET @scan = 1;
        WHILE 1 = 1
        BEGIN
            SET @cp = CHARINDEX(N'vct-calendario.js?v=', @D, @scan);
            IF @cp = 0 BREAK;
            SET @start = @cp + 20;
            SET @q = CHARINDEX(N'"', @D, @start);
            IF @q = 0 BREAK;
            SET @D = STUFF(@D, @start, @q - @start, @NEW);
            SET @scan = @start + 1;
        END;

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
            PRINT 'Bump vct-calendario v=33: ' + @Name;
        END;

        FETCH NEXT FROM cur INTO @oid;
    END;
    CLOSE cur; DEALLOCATE cur;
    COMMIT TRANSACTION;
    PRINT 'OK: SP actualizados a vct-calendario v=33: ' + CONVERT(VARCHAR(10), @N) + '.';
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local','cur') >= 0 BEGIN CLOSE cur; DEALLOCATE cur; END;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado y revertido: %s',16,1,@e);
END CATCH;
GO
