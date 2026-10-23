/* ============================================================================
   PASO6_8_ALTA_MAIL_ANALISTA   (marca ALTA_MAIL_V1)
   ----------------------------------------------------------------------------
   Alta de proyecto: si el analista no tiene email en VCT_EMAILS, debajo del formulario
   se escribe a quien enviar el mail de asignacion (viaja en TEXTO29).
     dbo.VCT_PROYECTO_ALTA_RENDER : agrega el campo oculto TEXTO29.
     dbo.VCT_PROYECTO_ALTA_GUARDAR: si el template no resolvio destinatario, usa TEXTO29
       (formato valido) antes de caer al mail del usuario; limpia TEXTO29 al terminar.
   La confirmacion (codigo + nombre, analista, email) es del JS.
   Sobre la definicion viva. Requiere PASO6_7 (ALTA_CONTACTO_V1). Re-ejecutable (marca ALTA_MAIL_V1).
   Despues: subir js/css de vct-proyecto-alta y correr FIX_PROYECTO_ALTA_BUMP.sql.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @NAME SYSNAME, @D NVARCHAR(MAX), @ERR NVARCHAR(2000), @I INT = 1, @A NVARCHAR(1000), @B NVARCHAR(MAX), @NL NCHAR(1) = NCHAR(10),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT;

WHILE @I <= 2
BEGIN
    SET @NAME = CASE @I WHEN 1 THEN N'dbo.VCT_PROYECTO_ALTA_RENDER' ELSE N'dbo.VCT_PROYECTO_ALTA_GUARDAR' END;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME)); SET @ERR = N'';
    IF @D IS NULL BEGIN RAISERROR('No existe %s.', 16, 1, @NAME); RETURN; END;
    IF CHARINDEX(N'ALTA_MAIL_V1', @D) > 0 BEGIN PRINT @NAME + N': ALTA_MAIL_V1 ya aplicado.'; SET @I = @I + 1; CONTINUE; END;
    IF CHARINDEX(N'ALTA_CONTACTO_V1', @D) = 0 BEGIN RAISERROR('Falta PASO6_7 (ALTA_CONTACTO_V1) en %s.', 16, 1, @NAME); RETURN; END;

    IF @I = 1
        SELECT @A = N'(175,''TEXTO27'',''Contacto nuevo'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL); /* ALTA_CONTACTO_V1 */',
               @B = N'(175,''TEXTO27'',''Contacto nuevo'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL), /* ALTA_CONTACTO_V1 */' + @NL
                  + N'        (180,''TEXTO29'',''Mail de asignacion'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL); /* ALTA_MAIL_V1 */';
    ELSE
    BEGIN
        /* limpieza del buffer */
        SELECT @A = N'TEXTO26 = NULL, TEXTO28 = NULL', @B = N'TEXTO26 = NULL, TEXTO28 = NULL, TEXTO29 = NULL /* ALTA_MAIL_V1 */';
        IF CHARINDEX(@A, @D) = 0 OR CHARINDEX(@A, @D, CHARINDEX(@A, @D) + 1) > 0
        BEGIN SET @ERR = N'ancla ausente o repetida: ' + LEFT(@A, 120); RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;
        SET @D = REPLACE(@D, @A, @B);
        /* destinatario: justo despues de leer el resultado del template (#MAIL) */
        SET @A = NULL;
        IF @A IS NULL AND CHARINDEX(N'FROM #MAIL;', @D) > 0 AND CHARINDEX(N'FROM #MAIL;', @D, CHARINDEX(N'FROM #MAIL;', @D) + 1) = 0 SET @A = N'FROM #MAIL;';
        IF @A IS NULL AND CHARINDEX(N'FROM #MAIL', @D) > 0 AND CHARINDEX(N'FROM #MAIL', @D, CHARINDEX(N'FROM #MAIL', @D) + 1) = 0 SET @A = N'FROM #MAIL';
        IF @A IS NULL
        BEGIN
            SET @ERR = SUBSTRING(@D, CHARINDEX(N'sp_send_dbmail', @D) - 1500, 1600);
            PRINT N'--- tramo del mail en la definicion vigente ---'; PRINT @ERR;
            RAISERROR('Cancelado, no se modifico %s: no se encontro la lectura del template (#MAIL). Pasar el texto de arriba.', 16, 1, @NAME); RETURN;
        END;
        SET @B = @A + @NL
               + N'            /* ALTA_MAIL_V1: el analista no tiene mail en VCT_EMAILS: se usa el que se escribio en el alta (TEXTO29) */' + @NL
               + N'            DECLARE @MAIL_ALTA VARCHAR(200) = ISNULL((SELECT TOP 1 LTRIM(RTRIM(ISNULL(TEXTO29,''''))) FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB), '''');' + @NL
               + N'            IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''''))),'''') IS NULL AND @MAIL_ALTA LIKE ''%_@_%._%''' + @NL
               + N'               AND CHARINDEX('' '', @MAIL_ALTA) = 0 AND CHARINDEX('';'', @MAIL_ALTA) = 0 AND CHARINDEX('','', @MAIL_ALTA) = 0' + @NL
               + N'                SET @M_DEST = @MAIL_ALTA;' + @NL;
    END;

    IF CHARINDEX(@A, @D) = 0 OR CHARINDEX(@A, @D, CHARINDEX(@A, @D) + 1) > 0
    BEGIN SET @ERR = N'ancla ausente o repetida: ' + LEFT(@A, 120); RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;
    SET @D = REPLACE(@D, @A, @B);

    SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
    WHILE 1 = 1
    BEGIN
        SET @cp = CHARINDEX(N'CREATE', @up, @scan);
        IF @cp = 0 BREAK;
        SET @probe = CHARINDEX(N'PROC', @up, @cp);
        IF @probe > 0 AND @probe <= @cp + 40 BREAK;
        SET @scan = @cp + 6;
    END;
    IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC de %s.', 16, 1, @NAME); RETURN; END;
    IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER'); ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

    BEGIN TRY
        EXEC sys.sp_executesql @D;
        PRINT N'OK: ' + @NAME + N' (ALTA_MAIL_V1).';
    END TRY
    BEGIN CATCH
        SET @ERR = ERROR_MESSAGE();
        RAISERROR('Cancelado (no se modifico %s): %s', 16, 1, @NAME, @ERR);
        RETURN;
    END CATCH;
    SET @I = @I + 1;
END;
GO
