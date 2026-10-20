/* ============================================================================
   FIX_CALENDARIO_ALL_ASSETS
   ----------------------------------------------------------------------------
   Repunta TODOS los SP que carguen los assets VIEJOS de calendario al par
   UNIFICADO, reemplazando el NOMBRE DE ARCHIVO y conservando el ?v (funciona
   sea cual sea la version viva: v3/v11/v31/20261016-2/etc.):
       vct-agenda-consultor.css -> vct-calendario.css
       vct-agenda-consultor.js  -> vct-calendario.js
       vct-agenda.css           -> vct-calendario.css
       vct-agenda.js            -> vct-calendario.js
   Cubre: VCT_MAIN_CALENDARIO (feriados), los *_V360 que embeben el calendario,
   el helper VCT_CALENDAR_V360_RENDER (si existe) y cualquier otro.
   ("vct-agenda.css" NO es substring de "vct-agenda-consultor.css", no se pisan.)

   Transaccional, re-ejecutable. Si un SP ya apunta a vct-calendario, se saltea.
   No toca consultas/permisos/calculos, solo los <link>/<script> de assets.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @oid INT, @Name SYSNAME, @D NVARCHAR(MAX), @orig NVARCHAR(MAX),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT, @N INT = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.object_id
    FROM sys.sql_modules m
    WHERE (m.definition LIKE N'%vct-agenda.css%' OR m.definition LIKE N'%vct-agenda.js%'
        OR m.definition LIKE N'%vct-agenda-consultor.css%' OR m.definition LIKE N'%vct-agenda-consultor.js%');

BEGIN TRY
    BEGIN TRANSACTION;
    OPEN cur;
    FETCH NEXT FROM cur INTO @oid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Name = OBJECT_SCHEMA_NAME(@oid) + '.' + OBJECT_NAME(@oid);
        SET @D = OBJECT_DEFINITION(@oid);
        SET @orig = @D;

        SET @D = REPLACE(@D, N'vct-agenda-consultor.css', N'vct-calendario.css');
        SET @D = REPLACE(@D, N'vct-agenda-consultor.js',  N'vct-calendario.js');
        SET @D = REPLACE(@D, N'vct-agenda.css',           N'vct-calendario.css');
        SET @D = REPLACE(@D, N'vct-agenda.js',            N'vct-calendario.js');

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
            PRINT 'Repuntado: ' + @Name;
        END;

        FETCH NEXT FROM cur INTO @oid;
    END;
    CLOSE cur; DEALLOCATE cur;
    COMMIT TRANSACTION;
    PRINT 'OK: SP repuntados a vct-calendario: ' + CONVERT(VARCHAR(10), @N) + '.';
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local','cur') >= 0 BEGIN CLOSE cur; DEALLOCATE cur; END;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado y revertido: %s',16,1,@e);
END CATCH;
GO
