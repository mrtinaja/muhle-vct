/* ============================================================================
   PASO6_5_ALTA_ADJ_QUITAR   (marca ALTA_ADJ_V2)
   ----------------------------------------------------------------------------
   La "x" de la lista de adjuntos del framework solo OCULTABA la fila: el archivo se
   vinculaba igual al grabar. Ahora "Quitar" (tarjeta nueva del alta, vct-proyecto-alta.js)
   anota la clave del archivo en el campo oculto TEXTO28 y el guardado no la vincula.
     dbo.VCT_PROYECTO_ALTA_RENDER : agrega el campo oculto TEXTO28 (adjuntos quitados).
     dbo.VCT_PROYECTO_ALTA_GUARDAR: vincula solo los adjuntos que no estan en TEXTO28
                                    y limpia TEXTO28 del buffer al terminar.
   Sobre la definicion viva. Requiere PASO6_3 (ALTA_DOCS_V1). Re-ejecutable (marca ALTA_ADJ_V2).
   Despues: subir js/css de vct-proyecto-alta y correr FIX_PROYECTO_ALTA_BUMP.sql.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @NAME SYSNAME, @D NVARCHAR(MAX), @ERR NVARCHAR(2000), @I INT = 1, @k INT, @A NVARCHAR(1000), @B NVARCHAR(1000),
        @up NVARCHAR(MAX), @cp INT, @scan INT, @probe INT;

WHILE @I <= 2
BEGIN
    SET @NAME = CASE @I WHEN 1 THEN N'dbo.VCT_PROYECTO_ALTA_RENDER' ELSE N'dbo.VCT_PROYECTO_ALTA_GUARDAR' END;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME)); SET @ERR = N'';
    IF @D IS NULL BEGIN RAISERROR('No existe %s.', 16, 1, @NAME); RETURN; END;
    IF CHARINDEX(N'ALTA_ADJ_V2', @D) > 0 BEGIN PRINT @NAME + N': ALTA_ADJ_V2 ya aplicado.'; SET @I = @I + 1; CONTINUE; END;
    IF CHARINDEX(N'ALTA_DOCS_V1', @D) = 0 BEGIN RAISERROR('Falta PASO6_3 (ALTA_DOCS_V1) en %s.', 16, 1, @NAME); RETURN; END;

    SET @k = 1;
    WHILE @k <= 3
    BEGIN
        SELECT @A = NULL, @B = NULL;
        IF @I = 1 AND @k = 1
            SELECT @A = N'(160,''TEXTO26'',''Comentario rentabilidad'',''HIDDEN'',12,0,NULL,NULL,NULL,NULLIF(@B26,''''),0,1,NULL,NULL);',
                   @B = N'(160,''TEXTO26'',''Comentario rentabilidad'',''HIDDEN'',12,0,NULL,NULL,NULL,NULLIF(@B26,''''),0,1,NULL,NULL),'
                      + NCHAR(10) + N'        (170,''TEXTO28'',''Adjuntos quitados'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL); /* ALTA_ADJ_V2 */';
        IF @I = 2 AND @k = 1
            SELECT @A = N'FROM dbo.PHYSICAL_ATTACHED_DOCUMENT A WHERE A.PAR_KEY = @IPKEYJOB;',
                   @B = N'FROM dbo.PHYSICAL_ATTACHED_DOCUMENT A WHERE A.PAR_KEY = @IPKEYJOB'
                      + N' AND CHARINDEX('','' + A.PKEY + '','', '','' + ISNULL((SELECT TOP 1 BQ.TEXTO28 FROM dbo.VCT_BUFFER BQ WITH(NOLOCK) WHERE BQ.PAR_KEY = @IPKEYJOB), '''') + '','') = 0; /* ALTA_ADJ_V2 */';
        IF @I = 2 AND @k = 2
            SELECT @A = N'UPDATE dbo.PHYSICAL_ATTACHED_DOCUMENT SET PAR_KEY = CONVERT(VARCHAR(20), @ID_PROYECTO) WHERE PAR_KEY = @IPKEYJOB;',
                   @B = N'UPDATE dbo.PHYSICAL_ATTACHED_DOCUMENT SET PAR_KEY = CONVERT(VARCHAR(20), @ID_PROYECTO) WHERE PAR_KEY = @IPKEYJOB'
                      + N' AND PKEY IN (SELECT ID_ADJUNTO FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE ID_PROYECTO = @ID_PROYECTO);';
        IF @I = 2 AND @k = 3
            SELECT @A = N'TEXTO24 = NULL, TEXTO25 = NULL, TEXTO26 = NULL',
                   @B = N'TEXTO24 = NULL, TEXTO25 = NULL, TEXTO26 = NULL, TEXTO28 = NULL';
        IF @A IS NOT NULL
        BEGIN
            IF CHARINDEX(@A, @D) = 0 OR CHARINDEX(@A, @D, CHARINDEX(@A, @D) + 1) > 0
            BEGIN SET @ERR = N'ancla ausente o repetida: ' + LEFT(@A, 120); BREAK; END;
            SET @D = REPLACE(@D, @A, @B);
        END;
        SET @k = @k + 1;
    END;
    IF @ERR <> N'' BEGIN RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;

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
        PRINT N'OK: ' + @NAME + N' (ALTA_ADJ_V2).';
    END TRY
    BEGIN CATCH
        SET @ERR = ERROR_MESSAGE();
        RAISERROR('Cancelado (no se modifico %s): %s', 16, 1, @NAME, @ERR);
        RETURN;
    END CATCH;
    SET @I = @I + 1;
END;
GO
