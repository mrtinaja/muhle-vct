/* ========================================================================
   NOTIF_RENDER_FIX2
   ------------------------------------------------------------------------
   dbo.VCT_NOTIF_RENDER: el titulo usaba dbo.VCT_HTML_ESC, que no existe en
   la base. Se reemplaza por el escape con REPLACE (sin crear funciones).
   Re-ejecutable (marca NOTIF_HEADER_V2).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_NOTIF_RENDER')),
        @P INT, @OK BIT = 1,
        @A NVARCHAR(200) = N'dbo.VCT_HTML_ESC(N.TITULO) + ''</button>''';

IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_NOTIF_RENDER.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%NOTIF_HEADER_V2%' BEGIN PRINT 'OK   dbo.VCT_NOTIF_RENDER ya tenia el cambio.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(@A, @D) = 0 BEGIN PRINT 'FALLO no se encontro dbo.VCT_HTML_ESC(N.TITULO) en el boton del titulo.'; SET @OK = 0; END;

IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A,
        N'REPLACE(REPLACE(REPLACE(ISNULL(N.TITULO, ''''), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') /* NOTIF_HEADER_V2 */ + ''</button>''');

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
        PRINT 'OK   dbo.VCT_NOTIF_RENDER: titulo sin dbo.VCT_HTML_ESC.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_NOTIF_RENDER: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO

/* prueba */
DECLARE @H VARCHAR(MAX) = '';
EXEC dbo.VCT_NOTIF_RENDER @IUNIDAD = 'PROYECTOS', @IAGENTE = 'aalfonso', @LINK = 1, @HTML = @H OUTPUT;
SELECT LEN(@H) AS LARGO, LEFT(@H, 300) AS HTML;
GO
