/* ============================================================================
   PASO6_4_ALTA_ALINEAR   (marca ALTA_LAYOUT_V1)
   ----------------------------------------------------------------------------
   dbo.VCT_PROYECTO_ALTA_RENDER (definicion viva):
     - Tipo de proyecto, Fecha inicio, Fecha fin y Horas proyectadas en UNA fila
       de 4 columnas iguales (3 + 3 + 3 + 3 de 12): sin huecos.
     - Boton del adjunto: solo "Adjuntar", sin icono.
   Requiere PASO6_3 (ALTA_DOCS_V1). Re-ejecutable: si ya tiene la marca, no hace nada.
   No hace falta subir js / css.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @NAME SYSNAME = N'dbo.VCT_PROYECTO_ALTA_RENDER', @D NVARCHAR(MAX), @O NVARCHAR(MAX), @ERR NVARCHAR(2000) = N'',
        @up NVARCHAR(MAX), @cp INT, @scan INT = 1, @probe INT, @k INT = 1, @A NVARCHAR(400), @B NVARCHAR(400);
SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));
IF @D IS NULL BEGIN RAISERROR('No existe %s.', 16, 1, @NAME); RETURN; END;
IF CHARINDEX(N'ALTA_LAYOUT_V1', @D) > 0 BEGIN PRINT N'ALTA_LAYOUT_V1 ya aplicado. No se hace nada.'; RETURN; END;
IF CHARINDEX(N'ALTA_DOCS_V1', @D) = 0 BEGIN RAISERROR('Falta PASO6_3 (ALTA_DOCS_V1) en %s.', 16, 1, @NAME); RETURN; END;

WHILE @k <= 5
BEGIN
    SELECT @A = CASE @k
                  WHEN 1 THEN N'(50,''TEXTO16'',''Tipo de proyecto'',''TEXT'',6,'
                  WHEN 2 THEN N'(70,''TEXTO13'',''Fecha inicio proyecto'',''DATE'',4,'
                  WHEN 3 THEN N'(80,''TEXTO14'',''Fecha fin proyecto'',''DATE'',4,'
                  WHEN 4 THEN N'(90,''TEXTO15'',''Horas proyectadas'',''NUMBER'',4,'
                  ELSE N'<span data-vct-icon="plus"></span><span>Adjuntar archivo</span>' END,
           @B = CASE @k
                  WHEN 1 THEN N'(50,''TEXTO16'',''Tipo de proyecto'',''TEXT'',3,'
                  WHEN 2 THEN N'(70,''TEXTO13'',''Fecha inicio proyecto'',''DATE'',3,'
                  WHEN 3 THEN N'(80,''TEXTO14'',''Fecha fin proyecto'',''DATE'',3,'
                  WHEN 4 THEN N'(90,''TEXTO15'',''Horas proyectadas'',''NUMBER'',3,'
                  ELSE N'<span>Adjuntar</span>' END;
    IF CHARINDEX(@A, @D) = 0 BEGIN SET @ERR = N'no se encontro: ' + @A; BREAK; END;
    SET @D = REPLACE(@D, @A, @B);
    SET @k = @k + 1;
END;
IF @ERR <> N'' BEGIN RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;

/* marca */
SET @D = REPLACE(@D, N'/* VCT_PROYECTO_ALTA_RENDER_V2 */', N'/* VCT_PROYECTO_ALTA_RENDER_V2 */ /* ALTA_LAYOUT_V1 */');
IF CHARINDEX(N'ALTA_LAYOUT_V1', @D) = 0 SET @D = REPLACE(@D, N'SET NOCOUNT ON;', N'SET NOCOUNT ON; /* ALTA_LAYOUT_V1 */');

/* CREATE [OR ALTER] -> ALTER */
SET @up = UPPER(@D); SET @cp = 0;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC.', 16, 1); RETURN; END;
IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER'); ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT N'OK: VCT_PROYECTO_ALTA_RENDER alineado (ALTA_LAYOUT_V1).';
END TRY
BEGIN CATCH
    SET @ERR = ERROR_MESSAGE();
    RAISERROR('Cancelado (no se modifico nada): %s', 16, 1, @ERR);
END CATCH;
GO
