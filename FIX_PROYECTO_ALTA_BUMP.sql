/* ============================================================================
   FIX_PROYECTO_ALTA_BUMP
   ----------------------------------------------------------------------------
   Sube en +1 el ?v= de vct-proyecto-alta.js y vct-proyecto-alta.css en TODOS los SP
   que los cargan (Proyectos, V360 de cliente, ...), sobre la definicion viva.
   Solo toca esos <link>/<script>. Correr UNA vez despues de subir los archivos
   (cada corrida vuelve a sumar 1, no rompe nada).
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @oid INT, @Name SYSNAME, @D NVARCHAR(MAX), @orig NVARCHAR(MAX), @up NVARCHAR(MAX),
        @cp INT, @scan INT, @probe INT, @pos INT, @s INT, @f INT, @A INT, @TOK NVARCHAR(60), @V INT, @N INT = 0, @e NVARCHAR(4000);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT m.object_id FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
    WHERE o.type = 'P' AND (m.definition LIKE N'%vct-proyecto-alta.js?v=%' OR m.definition LIKE N'%vct-proyecto-alta.css?v=%');
OPEN cur; FETCH NEXT FROM cur INTO @oid;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Name = OBJECT_SCHEMA_NAME(@oid) + N'.' + OBJECT_NAME(@oid);
    SET @D = OBJECT_DEFINITION(@oid); SET @orig = @D; SET @A = 1;
    WHILE @A <= 2
    BEGIN
        SET @TOK = CASE @A WHEN 1 THEN N'vct-proyecto-alta.js?v=' ELSE N'vct-proyecto-alta.css?v=' END;
        SET @scan = 1;
        WHILE 1 = 1
        BEGIN
            SET @pos = CHARINDEX(@TOK, @D, @scan);
            IF @pos = 0 BREAK;
            SET @s = @pos + LEN(@TOK); SET @f = @s;
            WHILE SUBSTRING(@D, @f, 1) LIKE N'[0-9]' SET @f = @f + 1;
            SET @V = CASE WHEN @f > @s THEN CONVERT(INT, SUBSTRING(@D, @s, @f - @s)) ELSE 0 END + 1;
            SET @D = STUFF(@D, @s, @f - @s, CONVERT(NVARCHAR(10), @V));
            SET @scan = @s + 1;
        END;
        SET @A = @A + 1;
    END;
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
        IF @cp > 0
        BEGIN
            IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER'); ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');
            BEGIN TRY
                EXEC sys.sp_executesql @D;
                SET @N = @N + 1;
                PRINT N'Bump vct-proyecto-alta: ' + @Name + N' (v=' + CONVERT(NVARCHAR(10), @V) + N')';
            END TRY
            BEGIN CATCH
                SET @e = ERROR_MESSAGE();
                PRINT N'NO se pudo actualizar ' + @Name + N': ' + @e;
            END CATCH;
        END
        ELSE PRINT N'Sin cabecera CREATE PROC: ' + @Name;
    END;
    FETCH NEXT FROM cur INTO @oid;
END;
CLOSE cur; DEALLOCATE cur;
PRINT N'OK: SP con vct-proyecto-alta actualizados: ' + CONVERT(NVARCHAR(10), @N) + N'.';
GO
