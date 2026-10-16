/* ========================================================================
   PASO2_4_FIX_ENTRADA_V360
   ------------------------------------------------------------------------
   "Ver proyecto" (Acciones y Proyectos) llegaba a la V360 sin proyecto:
   VCT.Buffer.store("IDSELEC02") escribe en el input SP.IDSELEC02 de la
   pantalla y esas pantallas no lo tenian, entonces el buffer no se
   grababa. Se agrega el input (mismo patron que SP.TEXTO30):
     1. dbo.VCT_MAIN_ACCIONES   -> SP.IDSELEC02
     2. dbo.VCT_MAIN_PROYECTOS  -> SP.IDSELEC02
     3. dbo.VCT_MAIN_PROYECTO_V360 -> SP.IDSELEC02 (con el proyecto, para
        no perderlo al volver) y los campos del comando PV_ASIGNAR
        (TEXTO30, IDSELEC03, TEXTO11, TEXTO12, TEXTO13, FLAG01).
   Parchea la definicion vigente. Re-ejecutable (marca SP_IDSELEC02_V1).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @OBJ TABLE (ORD INT, NOMBRE SYSNAME, ANCLA NVARCHAR(400), NUEVO NVARCHAR(MAX));
INSERT INTO @OBJ VALUES
(1, N'dbo.VCT_MAIN_ACCIONES',
    N'''<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">''',
    N'''<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value=""><input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">'' /* SP_IDSELEC02_V1 */'),
(2, N'dbo.VCT_MAIN_PROYECTOS',
    N'''<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">''',
    N'''<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value=""><input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="">'' /* SP_IDSELEC02_V1 */'),
(3, N'dbo.VCT_MAIN_PROYECTO_V360',
    N'+ @H + @MODAL',
    N'+ @H + @MODAL /* SP_IDSELEC02_V1 */
        + ''<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="'' + CONVERT(VARCHAR(20), @ID_PROYECTO) + ''">''
        + ''<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value=""><input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">''
        + ''<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value=""><input type="hidden" name="SP.TEXTO12" data-vct-field="TEXTO12" value="">''
        + ''<input type="hidden" name="SP.TEXTO13" data-vct-field="TEXTO13" value=""><input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">''');

DECLARE @I INT = 0, @N SYSNAME, @A NVARCHAR(400), @NV NVARCHAR(MAX), @D NVARCHAR(MAX), @P INT;
WHILE 1 = 1
BEGIN
    SELECT TOP 1 @I = ORD, @N = NOMBRE, @A = ANCLA, @NV = NUEVO FROM @OBJ WHERE ORD > @I ORDER BY ORD;
    IF @@ROWCOUNT = 0 BREAK;
    SET @D = OBJECT_DEFINITION(OBJECT_ID(@N));
    IF @D IS NULL BEGIN PRINT 'FALLO no existe ' + @N + '.'; CONTINUE; END;
    IF @D LIKE N'%SP_IDSELEC02_V1%' BEGIN PRINT 'OK   ' + @N + ' ya tenia el cambio.'; CONTINUE; END;
    IF @I < 3 AND @D LIKE N'%name="SP.IDSELEC02"%' BEGIN PRINT 'OK   ' + @N + ' ya tenia SP.IDSELEC02.'; CONTINUE; END;
    IF (LEN(@D) - LEN(REPLACE(@D, @A, N''))) / LEN(@A) <> 1 BEGIN PRINT 'FALLO ' + @N + ': no se encontro (una sola vez) el anclaje.'; CONTINUE; END;
    SET @D = REPLACE(@D, @A, @NV);

    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 SET @D = STUFF(@D, @P, 6, N'ALTER');
    ELSE IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0 BEGIN PRINT 'FALLO ' + @N + ': no se encontro CREATE/ALTER PROCEDURE.'; CONTINUE; END;

    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   ' + @N + ': input SP.IDSELEC02 agregado.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO ' + @N + ': ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
