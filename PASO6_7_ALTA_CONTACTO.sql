/* ============================================================================
   PASO6_7_ALTA_CONTACTO   (marca ALTA_CONTACTO_V1)
   ----------------------------------------------------------------------------
   "+" al lado de Contacto del cliente (alta de proyecto): modal Nombres / Apellido /
   Cargo / Observaciones. Graba por el mismo boton del formulario con
   TEXTO27 = CONTACTO|nombres|apellido|cargo|observaciones.
     dbo.VCT_PROYECTO_ALTA_RENDER : agrega el campo oculto TEXTO27.
     dbo.VCT_PROYECTO_ALTA_GUARDAR: si TEXTO27 trae un contacto, valida el cliente y los
       datos (en orden), inserta en dbo.VCT_CONTACTOS (mismas columnas que la V360 de cliente),
       lo deja elegido en TEXTO17 y devuelve "Contacto agregado ..." en @ERROR para que la
       pantalla vuelva a abrir el alta con todo lo cargado. NO graba el proyecto.
   Sobre la definicion viva. Requiere PASO6_5 (ALTA_ADJ_V2). Re-ejecutable (marca ALTA_CONTACTO_V1).
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
    IF CHARINDEX(N'ALTA_CONTACTO_V1', @D) > 0 BEGIN PRINT @NAME + N': ALTA_CONTACTO_V1 ya aplicado.'; SET @I = @I + 1; CONTINUE; END;
    IF @I = 1 AND CHARINDEX(N'ALTA_ADJ_V2', @D) = 0 BEGIN RAISERROR('Falta PASO6_5 (ALTA_ADJ_V2) en %s.', 16, 1, @NAME); RETURN; END;

    IF @I = 1
        SELECT @A = N'(170,''TEXTO28'',''Adjuntos quitados'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL); /* ALTA_ADJ_V2 */',
               @B = N'(170,''TEXTO28'',''Adjuntos quitados'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL), /* ALTA_ADJ_V2 */' + @NL
                  + N'        (175,''TEXTO27'',''Contacto nuevo'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL); /* ALTA_CONTACTO_V1 */';
    ELSE
        SELECT @A = N'BEGIN SET @ERROR = ''El cliente elegido no existe.''; RETURN; END;',
               @B = N'BEGIN SET @ERROR = ''El cliente elegido no existe.''; RETURN; END;' + @NL + @NL
                  + N'    /* ALTA_CONTACTO_V1: alta de contacto desde el "+" del formulario (no graba el proyecto) */' + @NL
                  + N'    DECLARE @CT_RAW VARCHAR(4000) = ISNULL((SELECT TOP 1 LTRIM(RTRIM(ISNULL(TEXTO27,''''))) FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB), '''');' + @NL
                  + N'    IF @CT_RAW LIKE ''CONTACTO|%''' + @NL
                  + N'    BEGIN' + @NL
                  + N'        DECLARE @CT_R VARCHAR(4000) = SUBSTRING(@CT_RAW, 10, 4000) + ''||||'', @CT_N VARCHAR(4000), @CT_A VARCHAR(4000), @CT_C VARCHAR(4000), @CT_O VARCHAR(4000), @CT_ID INT;' + @NL
                  + N'        SET @CT_N = LTRIM(RTRIM(LEFT(@CT_R, CHARINDEX(''|'', @CT_R) - 1))); SET @CT_R = SUBSTRING(@CT_R, CHARINDEX(''|'', @CT_R) + 1, 4000);' + @NL
                  + N'        SET @CT_A = LTRIM(RTRIM(LEFT(@CT_R, CHARINDEX(''|'', @CT_R) - 1))); SET @CT_R = SUBSTRING(@CT_R, CHARINDEX(''|'', @CT_R) + 1, 4000);' + @NL
                  + N'        SET @CT_C = LTRIM(RTRIM(LEFT(@CT_R, CHARINDEX(''|'', @CT_R) - 1))); SET @CT_R = SUBSTRING(@CT_R, CHARINDEX(''|'', @CT_R) + 1, 4000);' + @NL
                  + N'        SET @CT_O = LTRIM(RTRIM(LEFT(@CT_R, CHARINDEX(''|'', @CT_R) - 1)));' + @NL
                  + N'        UPDATE dbo.VCT_BUFFER SET TEXTO27 = NULL WHERE PAR_KEY = @IPKEYJOB;' + @NL
                  + N'        IF @CT_N = '''' BEGIN SET @ERROR = ''Los nombres del contacto son obligatorios.''; RETURN; END;' + @NL
                  + N'        IF @CT_A = '''' BEGIN SET @ERROR = ''El apellido del contacto es obligatorio.''; RETURN; END;' + @NL
                  + N'        IF LEN(@CT_C) > 100 BEGIN SET @ERROR = ''El cargo no puede superar los 100 caracteres.''; RETURN; END;' + @NL
                  + N'        BEGIN TRY' + @NL
                  + N'            INSERT INTO dbo.VCT_CONTACTOS (IDCLIENTE, APELLIDO, NOMBRES, CARGO, ID_DOMICILIO, ID_TELEFONO, ID_EMAIL, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)' + @NL
                  + N'            VALUES (@CLI, @CT_A, @CT_N, NULLIF(@CT_C, ''''), NULL, NULL, NULL, NULLIF(@CT_O, ''''), GETDATE(), @IAGENTE, NULL, NULL);' + @NL
                  + N'            SET @CT_ID = SCOPE_IDENTITY();' + @NL
                  + N'            UPDATE dbo.VCT_BUFFER SET TEXTO17 = CONVERT(VARCHAR(20), @CT_ID) WHERE PAR_KEY = @IPKEYJOB;' + @NL
                  + N'            SET @ERROR = LEFT(''Contacto agregado: '' + @CT_N + '' '' + @CT_A + ''. Ya qued'' + CHAR(243) + '' elegido; complete el resto y cree el proyecto.'', 1000);' + @NL
                  + N'        END TRY' + @NL
                  + N'        BEGIN CATCH' + @NL
                  + N'            SET @ERROR = LEFT(''No se pudo agregar el contacto: '' + ERROR_MESSAGE(), 1000);' + @NL
                  + N'        END CATCH;' + @NL
                  + N'        RETURN;' + @NL
                  + N'    END;';

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
        PRINT N'OK: ' + @NAME + N' (ALTA_CONTACTO_V1).';
    END TRY
    BEGIN CATCH
        SET @ERR = ERROR_MESSAGE();
        RAISERROR('Cancelado (no se modifico %s): %s', 16, 1, @NAME, @ERR);
        RETURN;
    END CATCH;
    SET @I = @I + 1;
END;
GO
