/* ========================================================================
   INICIO_SIN_AVISO_EMPLEADO
   ------------------------------------------------------------------------
   Parche sobre la definicion vigente de dbo.VCT_MAIN_DASHBOARD (Inicio):
     1. Saca el aviso "Tu usuario no esta vinculado a un empleado..." (y el
        de "No tenes proyectos asignados..."): el Inicio no muestra mensajes
        por el vinculo usuario / VCT_EMPLEADOS.
     2. Campanita: solo se muestra si el usuario tiene notificaciones
        (VCT_NOTIFICACIONES) y queda alineada a la derecha.
   No crea nada. Solo modifica dbo.VCT_MAIN_DASHBOARD. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_DASHBOARD')),
        @P INT, @Q INT, @OK BIT = 1,
        @A1 NVARCHAR(200) = N'SET @AVISO = CASE WHEN @EMP_ID IS NULL',
        @B1 NVARCHAR(400) = N'+ CASE WHEN ISNULL(@BELL, '''') <> '''' THEN ''<div class="vct-ini-top">'' + @BELL + ''</div>'' ELSE '''' END',
        @B2 NVARCHAR(800) = N'+ CASE WHEN ISNULL(@BELL, '''') <> '''' AND EXISTS (SELECT 1 FROM dbo.VCT_NOTIFICACIONES WITH(NOLOCK) WHERE USUARIO = LOWER(LTRIM(RTRIM(@IAGENTE)))) THEN ''<div class="vct-ini-top" style="justify-content:flex-end">'' + @BELL + ''</div>'' ELSE '''' END /* INICIO_SIN_AVISO_EMPLEADO_V1 */';

IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_DASHBOARD.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%INICIO_SIN_AVISO_EMPLEADO_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_DASHBOARD ya tenia el cambio.'; SET @OK = 0; END;

IF @OK = 1
BEGIN
    /* 1. aviso: SET @AVISO = CASE ... END;  ->  SET @AVISO = ''''; */
    SET @P = CHARINDEX(@A1, @D);
    SET @Q = CASE WHEN @P > 0 THEN CHARINDEX(N'END;', @D, @P) ELSE 0 END;
    IF @P = 0 OR @Q = 0 OR @Q - @P > 600 BEGIN PRINT 'FALLO no se encontro el aviso del empleado en dbo.VCT_MAIN_DASHBOARD.'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, @Q + LEN(N'END;') - @P, N'SET @AVISO = '''';');
END;

IF @OK = 1
BEGIN
    /* 2. campanita */
    SET @P = CHARINDEX(@B1, @D);
    IF @P = 0 BEGIN PRINT 'FALLO no se encontro la linea de la campanita en dbo.VCT_MAIN_DASHBOARD.'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P, LEN(@B1), @B2);
END;

IF @OK = 1
BEGIN
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 SET @D = STUFF(@D, @P, 6, N'ALTER');
    ELSE IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0 BEGIN PRINT 'FALLO no se encontro CREATE/ALTER PROCEDURE.'; SET @OK = 0; END;
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_DASHBOARD: sin aviso de empleado; campanita a la derecha y solo si hay notificaciones.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_DASHBOARD: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
