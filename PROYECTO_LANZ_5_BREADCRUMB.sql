/* ========================================================================
   PROYECTO_LANZ_5_BREADCRUMB
   ------------------------------------------------------------------------
   Breadcrumb de la Vista 360 de Proyecto navegable:
     - "Clientes"  -> listado de Clientes (igual que en la 360 de Cliente).
     - el cliente  -> Vista 360 de ese cliente (accion VIEW de CLIENTES).
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_PROYECTO_V360.
   Si ya fue aplicado (marca BREADCRUMB_V1), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'BREADCRUMB_V1',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360 ya tenia el breadcrumb navegable. No se hizo nada.';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'/* el inicio del proyecto cambia el estado del encabezado */'),
 (N'Clientes <span class="vct-breadcrumb-sep">/</span> ''+ISNULL(@CLIENTE,'''')+'' <span class="vct-breadcrumb-sep">/</span>');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

SET @s = CHARINDEX(N'/* el inicio del proyecto cambia el estado del encabezado */', @D);
SET @D = STUFF(@D, @s, 0, N'/* BREADCRUMB_V1: el cliente del breadcrumb abre su Vista 360 con la
   misma accion VIEW que usa la grilla de Clientes (respeta permisos). */
DECLARE @BC_CLI VARCHAR(MAX) = dbo.VCT_HTML_ESC(ISNULL(@CLIENTE,''''));
BEGIN TRY
    SELECT TOP 1 @BC_CLI =
        ''<button type="button" class="vct-breadcrumb-link" data-vct-command="grid-action"''
        + '' data-vct-action-id="'' + ISNULL(CONVERT(VARCHAR(50), A.ACTION_ID), '''') + ''"''
        + '' data-vct-store="'' + ISNULL(NULLIF(CONVERT(VARCHAR(50), A.STORAGE_KEY), ''''), ''IDSELEC01'') + ''"''
        + '' data-vct-value="'' + CONVERT(VARCHAR(20), @ID_CLIENTE) + ''"''
        + '' data-vct-guid="'' + CONVERT(VARCHAR(50), A.TARGET_GUID) + ''">''
        + dbo.VCT_HTML_ESC(ISNULL(@CLIENTE,'''')) + ''</button>''
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, ''CLIENTES'') A
    WHERE A.ACTION_TYPE = ''VIEW'' AND ISNULL(CONVERT(VARCHAR(50), A.TARGET_GUID), '''') <> ''''
    ORDER BY A.SORT_ORDER, A.ID_PRM;
END TRY
BEGIN CATCH
END CATCH;

');

SET @D = REPLACE(@D, N'Clientes <span class="vct-breadcrumb-sep">/</span> ''+ISNULL(@CLIENTE,'''')+'' <span class="vct-breadcrumb-sep">/</span>', N'<button type="button" class="vct-breadcrumb-link" data-vct-v360-back data-vct-guid="26899560-A8E8-4E54-A3C8-F9ED1E95DC45">Clientes</button> <span class="vct-breadcrumb-sep">/</span> ''+ISNULL(@BC_CLI,'''')+'' <span class="vct-breadcrumb-sep">/</span>');

DECLARE @p INT = CHARINDEX(N'PROCEDURE', @D), @pre NVARCHAR(60);
IF @p > 0
BEGIN
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
END;

IF PATINDEX(N'%ALTER%PROC%', @D) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTO_V360 con breadcrumb navegable.';
GO
