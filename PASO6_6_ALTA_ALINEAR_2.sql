/* ============================================================================
   PASO6_6_ALTA_ALINEAR_2   (marca ALTA_LAYOUT_V2)
   ----------------------------------------------------------------------------
   dbo.VCT_PROYECTO_ALTA_RENDER (definicion viva):
     - sin los textos de ayuda debajo de los inputs (Codigo, Horas proyectadas,
       Analista, Fecha limite y el cliente fijo de la V360);
     - Contacto del cliente, Analista a cargo y Fecha limite de lanzamiento en UNA
       fila de 3 columnas iguales (4 + 4 + 4 de 12).
   Requiere PASO6_4 (ALTA_LAYOUT_V1). Re-ejecutable: si ya tiene la marca, no hace nada.
   No hace falta subir js / css.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @NAME SYSNAME = N'dbo.VCT_PROYECTO_ALTA_RENDER', @D NVARCHAR(MAX), @O NVARCHAR(MAX), @ERR NVARCHAR(2000) = N'',
        @up NVARCHAR(MAX), @cp INT, @scan INT = 1, @probe INT, @k INT = 1, @A NVARCHAR(400), @B NVARCHAR(400);
SET @D = OBJECT_DEFINITION(OBJECT_ID(@NAME));
IF @D IS NULL BEGIN RAISERROR('No existe %s.', 16, 1, @NAME); RETURN; END;
IF CHARINDEX(N'ALTA_LAYOUT_V2', @D) > 0 BEGIN PRINT N'ALTA_LAYOUT_V2 ya aplicado. No se hace nada.'; RETURN; END;
IF CHARINDEX(N'ALTA_LAYOUT_V1', @D) = 0 BEGIN RAISERROR('Falta PASO6_4 (ALTA_LAYOUT_V1) en %s.', 16, 1, @NAME); RETURN; END;

WHILE @k <= 8
BEGIN
    SELECT @A = CASE @k
                  WHEN 1 THEN N'''Se confirma al guardar.'''
                  WHEN 2 THEN N'''Tope para la suma de los servicios.'''
                  WHEN 3 THEN N'''Recibe la gesti&oacute;n y el mail para organizar el lanzamiento.'''
                  WHEN 4 THEN N'''Vencimiento de la gesti&oacute;n del analista.'''
                  WHEN 5 THEN N'''Viene de la Vista 360 del cliente.'''
                  WHEN 6 THEN N'(120,''TEXTO17'',''Contacto del cliente'',''TEXT'',12,'
                  WHEN 7 THEN N'(130,''TEXTO20'',''Analista a cargo'',''TEXT'',6,'
                  ELSE N'(140,''TEXTO21'',''Fecha l&iacute;mite de lanzamiento'',''DATE'',6,' END,
           @B = CASE @k
                  WHEN 6 THEN N'(120,''TEXTO17'',''Contacto del cliente'',''TEXT'',4,'
                  WHEN 7 THEN N'(130,''TEXTO20'',''Analista a cargo'',''TEXT'',4,'
                  WHEN 8 THEN N'(140,''TEXTO21'',''Fecha l&iacute;mite de lanzamiento'',''DATE'',4,'
                  ELSE N'NULL' END;
    IF CHARINDEX(@A, @D) = 0 BEGIN SET @ERR = N'no se encontro: ' + @A; BREAK; END;
    SET @D = REPLACE(@D, @A, @B);
    SET @k = @k + 1;
END;
IF @ERR <> N'' BEGIN RAISERROR('Cancelado, no se modifico %s: %s', 16, 1, @NAME, @ERR); RETURN; END;

/* marca */
SET @D = REPLACE(@D, N'/* ALTA_LAYOUT_V1 */', N'/* ALTA_LAYOUT_V1 */ /* ALTA_LAYOUT_V2 */');

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
    PRINT N'OK: VCT_PROYECTO_ALTA_RENDER (ALTA_LAYOUT_V2).';
END TRY
BEGIN CATCH
    SET @ERR = ERROR_MESSAGE();
    RAISERROR('Cancelado (no se modifico nada): %s', 16, 1, @ERR);
END CATCH;
GO
