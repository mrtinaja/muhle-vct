/* ============================================================================
   PASO6_9_ALTA_ANALISTA_MAIL   (marca ALTA_ANALISTA_MAIL_V1)
   ----------------------------------------------------------------------------
   Alta de proyecto: "+" al lado del analista -> modal Email (un solo input).
   Graba por el mismo boton del formulario con TEXTO27 = EMAIL|id_analista|email.
     dbo.VCT_PROYECTO_ALTA_RENDER : el data-email del analista toma el principal y,
       si no hay, el primero cargado (mismo criterio que VCT_MAIN_SEND_EMAIL).
     dbo.VCT_PROYECTO_ALTA_GUARDAR: inserta el email en dbo.VCT_EMAILS (EMPLEADO,
       PRINCIPAL = 'NO'), devuelve "Email agregado ..." y vuelve a abrir el alta.
       NO graba el proyecto.
   Todo o nada: si algo no encaja no modifica ninguno de los dos SP.
   Requiere PASO6_7 (ALTA_CONTACTO_V1). Re-ejecutable.
   Despues: subir js/css de vct-proyecto-alta y correr FIX_PROYECTO_ALTA_BUMP.sql.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @NL NCHAR(1) = NCHAR(10), @A NVARCHAR(1000), @B NVARCHAR(MAX), @ERR NVARCHAR(2000),
        @D1 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_RENDER')),
        @D2 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_PROYECTO_ALTA_GUARDAR')),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT, @I INT;

IF @D1 IS NULL OR @D2 IS NULL BEGIN RAISERROR('No existe VCT_PROYECTO_ALTA_RENDER o VCT_PROYECTO_ALTA_GUARDAR.', 16, 1); RETURN; END;
IF CHARINDEX(N'ALTA_ANALISTA_MAIL_V1', @D1) > 0 AND CHARINDEX(N'ALTA_ANALISTA_MAIL_V1', @D2) > 0
BEGIN PRINT N'ALTA_ANALISTA_MAIL_V1 ya aplicado. No hay nada que hacer.'; RETURN; END;
IF CHARINDEX(N'ALTA_CONTACTO_V1', @D2) = 0 BEGIN RAISERROR('Falta PASO6_7 (ALTA_CONTACTO_V1).', 16, 1); RETURN; END;

/* ---------- RENDER: data-email = principal o, si no hay, el primero ---------- */
IF CHARINDEX(N'ALTA_ANALISTA_MAIL_V1', @D1) = 0
BEGIN
    SET @A = NULL;
    IF CHARINDEX(N'AND M.PRINCIPAL = ''SI''', @D1) > 0 AND CHARINDEX(N'AND M.PRINCIPAL = ''SI''', @D1, CHARINDEX(N'AND M.PRINCIPAL = ''SI''', @D1) + 1) = 0
        SET @A = N'AND M.PRINCIPAL = ''SI'''
    ELSE IF CHARINDEX(N'AND M.PRINCIPAL=''SI''', @D1) > 0 AND CHARINDEX(N'AND M.PRINCIPAL=''SI''', @D1, CHARINDEX(N'AND M.PRINCIPAL=''SI''', @D1) + 1) = 0
        SET @A = N'AND M.PRINCIPAL=''SI''';
    IF @A IS NULL
    BEGIN
        SET @ERR = SUBSTRING(@D1, CHARINDEX(N'data-email', @D1) - 200, 900);
        PRINT N'--- tramo del data-email en la definicion vigente ---'; PRINT @ERR;
        RAISERROR('Cancelado, no se modifico nada: no se encontro el filtro PRINCIPAL del analista. Pasar el texto de arriba.', 16, 1); RETURN;
    END;
    SET @D1 = REPLACE(@D1, @A, N'AND M.ID = (SELECT TOP 1 M2.ID FROM dbo.VCT_EMAILS M2 WITH(NOLOCK) WHERE M2.TIPO_ENTIDAD = ''EMPLEADO'' AND M2.ID_ENTIDAD = E.ID ORDER BY CASE WHEN M2.PRINCIPAL = ''SI'' THEN 0 ELSE 1 END, M2.ID) /* ALTA_ANALISTA_MAIL_V1 */');
END;

/* ---------- GUARDAR: alta del email antes del bloque de contacto ---------- */
IF CHARINDEX(N'ALTA_ANALISTA_MAIL_V1', @D2) = 0
BEGIN
    SET @A = N'    /* ALTA_CONTACTO_V1: alta de contacto desde el "+" del formulario (no graba el proyecto) */';
    IF CHARINDEX(@A, @D2) = 0 OR CHARINDEX(@A, @D2, CHARINDEX(@A, @D2) + 1) > 0
    BEGIN RAISERROR('Cancelado, no se modifico nada: no se encontro el bloque ALTA_CONTACTO_V1 en VCT_PROYECTO_ALTA_GUARDAR.', 16, 1); RETURN; END;
    SET @B = N'    /* ALTA_ANALISTA_MAIL_V1: alta de email del analista desde el "+" del formulario (no graba el proyecto) */' + @NL
        + N'    DECLARE @EM_RAW VARCHAR(4000) = ISNULL((SELECT TOP 1 LTRIM(RTRIM(ISNULL(TEXTO27,''''))) FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB), '''');' + @NL
        + N'    IF @EM_RAW LIKE ''EMAIL|%''' + @NL
        + N'    BEGIN' + @NL
        + N'        DECLARE @EM_R VARCHAR(4000) = SUBSTRING(@EM_RAW, 7, 4000) + ''|'', @EM_ID VARCHAR(20), @EM_MAIL VARCHAR(200), @EM_NOM VARCHAR(400);' + @NL
        + N'        SET @EM_ID = LTRIM(RTRIM(LEFT(@EM_R, CHARINDEX(''|'', @EM_R) - 1))); SET @EM_R = SUBSTRING(@EM_R, CHARINDEX(''|'', @EM_R) + 1, 4000);' + @NL
        + N'        SET @EM_MAIL = LTRIM(RTRIM(LEFT(@EM_R, CHARINDEX(''|'', @EM_R) - 1)));' + @NL
        + N'        UPDATE dbo.VCT_BUFFER SET TEXTO27 = NULL WHERE PAR_KEY = @IPKEYJOB;' + @NL
        + N'        IF @EM_ID = '''' OR PATINDEX(''%[^0-9]%'', @EM_ID) > 0 OR LEN(@EM_ID) > 9 BEGIN SET @ERROR = ''Seleccione el analista.''; RETURN; END;' + @NL
        + N'        SELECT @EM_NOM = LTRIM(RTRIM(ISNULL(APELLIDOS,'''') + '', '' + ISNULL(NOMBRES,''''))) FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @EM_ID);' + @NL
        + N'        IF @EM_NOM IS NULL BEGIN SET @ERROR = ''El analista elegido no existe.''; RETURN; END;' + @NL
        + N'        IF @EM_MAIL = '''' BEGIN SET @ERROR = ''El email es obligatorio.''; RETURN; END;' + @NL
        + N'        IF LEN(@EM_MAIL) > 100 OR @EM_MAIL NOT LIKE ''%_@_%._%'' OR CHARINDEX('' '', @EM_MAIL) > 0 OR CHARINDEX('';'', @EM_MAIL) > 0 OR CHARINDEX('','', @EM_MAIL) > 0' + @NL
        + N'        BEGIN SET @ERROR = ''El email no tiene un formato valido.''; RETURN; END;' + @NL
        + N'        IF EXISTS (SELECT 1 FROM dbo.VCT_EMAILS WITH(NOLOCK) WHERE TIPO_ENTIDAD = ''EMPLEADO'' AND ID_ENTIDAD = CONVERT(INT, @EM_ID)' + @NL
        + N'                   AND LOWER(LTRIM(RTRIM(ISNULL(EMAIL,'''')))) = LOWER(@EM_MAIL))' + @NL
        + N'        BEGIN SET @ERROR = ''El analista ya posee ese email registrado.''; RETURN; END;' + @NL
        + N'        BEGIN TRY' + @NL
        + N'            INSERT INTO dbo.VCT_EMAILS (TIPO_ENTIDAD, ID_ENTIDAD, EMAIL, PRINCIPAL, OBSERVACIONES)' + @NL
        + N'            VALUES (''EMPLEADO'', CONVERT(INT, @EM_ID), @EM_MAIL, ''NO'', NULL);' + @NL
        + N'            SET @ERROR = LEFT(''Email agregado: '' + @EM_MAIL + '' para '' + @EM_NOM + ''.'', 1000);' + @NL
        + N'        END TRY' + @NL
        + N'        BEGIN CATCH' + @NL
        + N'            SET @ERROR = LEFT(''No se pudo agregar el email: '' + ERROR_MESSAGE(), 1000);' + @NL
        + N'        END CATCH;' + @NL
        + N'        RETURN;' + @NL
        + N'    END;' + @NL + @NL
        + @A;
    SET @D2 = REPLACE(@D2, @A, @B);
END;

/* ---------- CREATE -> ALTER en los dos ---------- */
SET @I = 1;
WHILE @I <= 2
BEGIN
    SET @up = UPPER(CASE @I WHEN 1 THEN @D1 ELSE @D2 END); SET @cp = 0; SET @scan = 1;
    WHILE 1 = 1
    BEGIN
        SET @cp = CHARINDEX(N'CREATE', @up, @scan);
        IF @cp = 0 BREAK;
        SET @probe = CHARINDEX(N'PROC', @up, @cp);
        IF @probe > 0 AND @probe <= @cp + 40 BREAK;
        SET @scan = @cp + 6;
    END;
    IF @cp = 0 BEGIN RAISERROR('Cancelado, no se modifico nada: no se identifico la cabecera CREATE PROC.', 16, 1); RETURN; END;
    IF @I = 1
        SET @D1 = CASE WHEN SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' THEN STUFF(@D1, @cp, 15, N'ALTER') ELSE STUFF(@D1, @cp, 6, N'ALTER') END
    ELSE
        SET @D2 = CASE WHEN SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' THEN STUFF(@D2, @cp, 15, N'ALTER') ELSE STUFF(@D2, @cp, 6, N'ALTER') END;
    SET @I = @I + 1;
END;

BEGIN TRY
    BEGIN TRAN;
    EXEC sys.sp_executesql @D1;
    EXEC sys.sp_executesql @D2;
    COMMIT TRAN;
    PRINT N'OK: VCT_PROYECTO_ALTA_RENDER y VCT_PROYECTO_ALTA_GUARDAR (ALTA_ANALISTA_MAIL_V1).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    SET @ERR = ERROR_MESSAGE();
    RAISERROR('Cancelado, no se modifico nada: %s', 16, 1, @ERR);
END CATCH;
GO
