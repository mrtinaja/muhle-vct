/* ========================================================================
   NOTIF_RENDER_FIX
   ------------------------------------------------------------------------
   Completa NOTIF_EN_HEADER: solo dbo.VCT_NOTIF_RENDER (el link del titulo
   en la base no coincidia con el repo; ahora se reemplaza el contenido
   completo del titulo).
     - "N nueva(s) desde su ultimo ingreso".
     - Cada notificacion va a Acciones, a la pestania de la accion:
       vencidas / hoy / proximas; si no, todas.
     - Clases vct-notif-* (css/vct-notif.css).
   Re-ejecutable (marca NOTIF_HEADER_V1).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;

DECLARE @D NVARCHAR(MAX), @P INT, @Q INT, @OK BIT, @A NVARCHAR(400);

/* ======================================================================
   1. dbo.VCT_NOTIF_RENDER
   ====================================================================== */
SET @OK = 1;
SET @D = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_NOTIF_RENDER'));
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_NOTIF_RENDER.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%NOTIF_HEADER_V1%' BEGIN PRINT 'OK   dbo.VCT_NOTIF_RENDER ya tenia el cambio.'; SET @OK = 0; END;

IF @OK = 1
BEGIN
    /* texto */
    SET @A = N'desde tu &uacute;ltima visita';
    IF CHARINDEX(@A, @D) = 0 BEGIN PRINT 'FALLO RENDER: no se encontro el texto "desde tu ultima visita".'; SET @OK = 0; END
    ELSE SET @D = REPLACE(@D, @A, N'desde su &uacute;ltimo ingreso');
END;

IF @OK = 1
BEGIN
    /* titulo: boton que va a Acciones (antes: Vista 360 del proyecto).
       Se reemplaza todo lo que hay dentro de <span class="vct-ini-notif-title">. */
    SET @A = N'<span class="vct-ini-notif-title">''';
    SET @P = CHARINDEX(@A, @D);
    SET @Q = CASE WHEN @P > 0 THEN CHARINDEX(N'''</span>''', @D, @P + LEN(@A)) ELSE 0 END;
    IF @P = 0 OR @Q = 0 OR @Q - @P > 1500 BEGIN PRINT 'FALLO RENDER: no se encontro el titulo (vct-ini-notif-title).'; SET @OK = 0; END
    ELSE SET @D = STUFF(@D, @P + LEN(@A), @Q - (@P + LEN(@A)),
        N' + ''<button type="button" class="vct-notif-link" data-vct-notif-tab="'' + ISNULL(NT.TAB, ''todas'') + ''">'' + REPLACE(REPLACE(REPLACE(ISNULL(N.TITULO, ''''), ''&'', ''&amp;''), ''<'', ''&lt;''), ''>'', ''&gt;'') /* NOTIF_HEADER_V2 */ + ''</button>'' + ');
END;

IF @OK = 1
BEGIN
    /* pestania de Acciones segun la accion (misma regla que la pantalla Acciones) */
    SET @A = N'FROM dbo.VCT_NOTIFICACIONES N';
    IF (LEN(@D) - LEN(REPLACE(@D, @A, N''))) / LEN(@A) <> 1
    BEGIN PRINT 'FALLO RENDER: no se encontro (una sola vez) "FROM dbo.VCT_NOTIFICACIONES N".'; SET @OK = 0; END
    ELSE SET @D = REPLACE(@D, @A, @A + N'
        OUTER APPLY (SELECT TOP 1 /* NOTIF_HEADER_V1 */
                       CASE WHEN ISNULL(E.ES_FINAL, 0) = 1 OR A.FECHA_VENCIMIENTO IS NULL THEN ''todas''
                            WHEN CONVERT(DATE, A.FECHA_VENCIMIENTO) < CONVERT(DATE, GETDATE()) THEN ''vencidas''
                            WHEN CONVERT(DATE, A.FECHA_VENCIMIENTO) = CONVERT(DATE, GETDATE()) THEN ''hoy''
                            WHEN CONVERT(DATE, A.FECHA_VENCIMIENTO) <= DATEADD(DAY, 7, CONVERT(DATE, GETDATE())) THEN ''proximas''
                            ELSE ''todas'' END AS TAB
                     FROM dbo.VCT_ACCIONES A
                     LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
                     WHERE N.TIPO NOT IN (''VISITA'', ''HORAS'')
                       AND CONVERT(VARCHAR(20), A.ID) = LEFT(N.CLAVE, CHARINDEX(''-'', N.CLAVE + ''-'') - 1)) NT');
END;

IF @OK = 1
BEGIN
    /* clases propias del header (css/vct-notif.css) */
    SET @D = REPLACE(@D, N'data-vct-ini-bell-toggle', N'data-vct-notif-toggle');
    SET @D = REPLACE(@D, N'data-vct-ini-bell-panel', N'data-vct-notif-panel');
    SET @D = REPLACE(@D, N'data-vct-ini-bell', N'data-vct-notif-bell');
    SET @D = REPLACE(@D, N'vct-ini-bell', N'vct-notif-bell');
    SET @D = REPLACE(@D, N'vct-ini-notif', N'vct-notif-item');

    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 SET @D = STUFF(@D, @P, 6, N'ALTER');
    ELSE IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0 BEGIN PRINT 'FALLO RENDER: no se encontro CREATE/ALTER PROCEDURE.'; SET @OK = 0; END;
END;

IF @OK = 1
BEGIN
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_NOTIF_RENDER: texto "desde su ultimo ingreso" y links a Acciones por pestania.';
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
