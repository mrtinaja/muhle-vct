/* ============================================================================
   PASO6_3_ALTA_ADJUNTO_SIN_RIESGO   (marca ALTA_DOCS_V1)
   ----------------------------------------------------------------------------
   Alta de proyecto, sobre la definicion VIVA de los SP (no pisa cambios del server):
     dbo.VCT_PROYECTO_ALTA_RENDER
       - saca el campo Nivel de riesgo (pasa al lanzamiento);
       - agrega el bloque "Propuesta comercial" con el upload del framework
         (task/UploadFile.ashx: el archivo queda en PHYSICAL_ATTACHED_DOCUMENT con PAR_KEY = tramite).
     dbo.VCT_PROYECTO_ALTA_GUARDAR
       - no exige el riesgo y graba NIVEL_RIESGO en NULL (lo define el lanzamiento);
       - dentro de la transaccion: vincula los archivos adjuntados en el alta a
         VCT_PROYECTOS_DOCUMENTOS (TIPO PROPUESTA_COMERCIAL) y pasa su PAR_KEY al id
         del proyecto (como hacia el sistema anterior). Aparecen en la pestania Documentos.
   Los dias (horas / 8) en la seleccion de servicios son solo del JS (vct-proyecto-alta.js).
   Requiere PASO6_1. Re-ejecutable: si ya tiene la marca, avisa y no hace nada.
   Despues: subir js/css de vct-proyecto-alta y correr FIX_PROYECTO_ALTA_BUMP.sql.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID('dbo.VCT_PROYECTOS_DOCUMENTOS', 'U') IS NULL
BEGIN RAISERROR('Falta VCT_PROYECTOS_DOCUMENTOS: correr antes PASO6_1.', 16, 1); RETURN; END;

DECLARE @NAME SYSNAME, @D NVARCHAR(MAX), @NL NCHAR(1) = NCHAR(10), @p INT, @q INT, @up NVARCHAR(MAX),
        @cp INT, @scan INT, @probe INT, @I INT = 1, @ERR NVARCHAR(2000);

WHILE @I <= 2
BEGIN
    SET @NAME = CASE @I WHEN 1 THEN N'dbo.VCT_PROYECTO_ALTA_RENDER' ELSE N'dbo.VCT_PROYECTO_ALTA_GUARDAR' END;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));
    IF @D IS NULL BEGIN RAISERROR('No existe %s.', 16, 1, @NAME); RETURN; END;
    IF CHARINDEX(N'ALTA_DOCS_V1', @D) > 0 BEGIN PRINT @NAME + N': ALTA_DOCS_V1 ya aplicado.'; SET @I = @I + 1; CONTINUE; END;
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), @NL);
    SET @ERR = N'';

    IF @I = 1
    BEGIN
        /* 1) sacar la fila del campo Nivel de riesgo (linea completa) */
        SET @p = CHARINDEX(N'(60,''TEXTO18'',''Nivel de riesgo''', @D);
        IF @p = 0 SET @ERR = N'RENDER: no se encontro la fila del Nivel de riesgo.';
        ELSE
        BEGIN
            WHILE @p > 1 AND SUBSTRING(@D, @p - 1, 1) <> @NL SET @p = @p - 1;
            SET @q = CHARINDEX(@NL, @D, @p);
            SET @D = STUFF(@D, @p, @q - @p + 1, N'        /* ALTA_DOCS_V1: sin Nivel de riesgo (se define en el lanzamiento) */' + @NL);
        END;
        /* 2) bloque Propuesta comercial antes del pie del formulario */
        SET @p = CHARINDEX(N'/* ---------- opciones ---------- */', @D);
        IF @ERR = N'' AND @p = 0 SET @ERR = N'RENDER: no se encontro el bloque de opciones.';
        IF @ERR = N''
        BEGIN
            WHILE @p > 1 AND SUBSTRING(@D, @p - 1, 1) <> @NL SET @p = @p - 1;
            SET @D = STUFF(@D, @p, 0,
                  N'    /* ALTA_DOCS_V1: propuesta comercial (upload del framework; la vincula el guardado) */' + @NL
                + N'    SET @HF = REPLACE(@HF, ''<div class="vct-card-footer vct-form-footer">'','
                + N' ''<div class="vct-proy-adj" data-vct-proy-adj data-key="'' + REPLACE(ISNULL(@IPKEYJOB,''''),''"'','''') + ''">'''
                + N' + ''<div class="vct-proy-adj-h"><span data-vct-icon="file-text"></span><div><b>Propuesta comercial</b><small>PDF de la propuesta. Queda en Documentos del proyecto.</small></div></div>'''
                + N' + ''<label class="vct-btn vct-btn-secondary vct-btn-sm vct-proy-adj-btn"><span data-vct-icon="plus"></span><span>Adjuntar archivo</span>'''
                + N' + ''<input id="'' + @FORM + ''_fileupload" type="file" name="files[]" accept=".pdf,application/pdf"></label>'''
                + N' + ''<div id="'' + @FORM + ''_attached_files" class="vct-proy-adj-list"></div></div>'''
                + N' + ''<div class="vct-card-footer vct-form-footer">'');' + @NL + @NL);
        END;
    END
    ELSE
    BEGIN
        /* 1) el riesgo ya no es obligatorio */
        SET @p = CHARINDEX(N'IF @T18 NOT IN (''Bajo'',''Medio'',''Alto'')', @D);
        IF @p = 0 SET @ERR = N'GUARDAR: no se encontro la validacion del riesgo.';
        ELSE SET @D = STUFF(@D, @p, LEN(N'IF @T18 NOT IN (''Bajo'',''Medio'',''Alto'')'), N'IF 1 = 0 /* ALTA_DOCS_V1: el riesgo pasa al lanzamiento */');
        /* 2) NIVEL_RIESGO en NULL */
        SET @p = CHARINDEX(N'@HORAS, 0, @T18, @CONTACTO, @T16)', @D);
        IF @ERR = N'' AND @p = 0 SET @ERR = N'GUARDAR: no se encontro el INSERT de VCT_PROYECTOS (riesgo).';
        IF @ERR = N'' SET @D = STUFF(@D, @p, LEN(N'@HORAS, 0, @T18, @CONTACTO, @T16)'), N'@HORAS, 0, NULL, @CONTACTO, @T16)');
        /* 3) vincular los adjuntos antes del COMMIT (unico) */
        SET @p = CHARINDEX(N'COMMIT TRAN;', @D);
        IF @ERR = N'' AND (@p = 0 OR CHARINDEX(N'COMMIT TRAN;', @D, @p + 1) > 0) SET @ERR = N'GUARDAR: COMMIT TRAN ausente o repetido.';
        IF @ERR = N''
        BEGIN
            WHILE @p > 1 AND SUBSTRING(@D, @p - 1, 1) <> @NL SET @p = @p - 1;
            SET @D = STUFF(@D, @p, 0,
                  N'        /* ALTA_DOCS_V1: propuesta comercial adjuntada en el alta -> documentos del proyecto */' + @NL
                + N'        INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, TIPO, ID_ADJUNTO, NOMBRE, VISIBLE_CLIENTE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)' + @NL
                + N'        SELECT @ID_PROYECTO, ''PROPUESTA_COMERCIAL'', A.PKEY, LEFT(COALESCE(NULLIF(LTRIM(RTRIM(A.ATTACHED_MESSAGE)), ''''), A.FILE_NAME, ''Propuesta comercial''), 255), 0, 1, GETDATE(), @IAGENTE' + @NL
                + N'        FROM dbo.PHYSICAL_ATTACHED_DOCUMENT A WHERE A.PAR_KEY = @IPKEYJOB;' + @NL
                + N'        UPDATE dbo.PHYSICAL_ATTACHED_DOCUMENT SET PAR_KEY = CONVERT(VARCHAR(20), @ID_PROYECTO) WHERE PAR_KEY = @IPKEYJOB;' + @NL + @NL);
        END;
    END;

    IF @ERR <> N'' BEGIN RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;

    /* CREATE [OR ALTER] -> ALTER */
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
    IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER');
    ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

    BEGIN TRY
        EXEC sys.sp_executesql @D;
        PRINT N'OK: ' + @NAME + N' (ALTA_DOCS_V1).';
    END TRY
    BEGIN CATCH
        SET @ERR = ERROR_MESSAGE();
        RAISERROR('Cancelado (no se modifico %s): %s', 16, 1, @NAME, @ERR);
        RETURN;
    END CATCH;
    SET @I = @I + 1;
END;
GO
