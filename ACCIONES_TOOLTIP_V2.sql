/* ============================================================================
   ACCIONES_TOOLTIP_V2   (sobre ACCIONES_TOOLTIP_V1)
   ----------------------------------------------------------------------------
   Ajuste "mas operativo": en el tooltip del calendario de Acciones, el Servicio
   se muestra como circulos con su codigo (CO/AU/CA) y el Consultor asignado como
   avatar con iniciales (el nombre completo va en el hover). Dos cambios minimos
   sobre dbo.VCT_MAIN_ACCIONES:
     1) E_SRV ahora lleva 'CODIGO|Descripcion' por servicio (el JS arma el circulo
        con el codigo y el nombre en el title).
     2) @CALDATA emite data-r (responsable) y data-ri (iniciales) por accion.
   No cambia contrato, consultas, permisos ni navegacion. Requiere V1 aplicado.
   Re-ejecutable: si ya esta (marca data-ri) avisa y no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_ACCIONES')),
        @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT = 1;

IF @D IS NULL BEGIN RAISERROR('No se encontro dbo.VCT_MAIN_ACCIONES.',16,1); RETURN; END;

IF CHARINDEX(N'data-ri="', @D) > 0
BEGIN PRINT 'ACCIONES_TOOLTIP_V2 ya aplicado. No se hace nada.'; RETURN; END;

IF CHARINDEX(N'E_SRV', @D) = 0
BEGIN RAISERROR('Falta ACCIONES_TOOLTIP_V1 (columna E_SRV). Corre primero ACCIONES_TOOLTIP_V1.sql.',16,1); RETURN; END;

/* ---- 1) E_SRV: agregar el codigo del servicio -> 'CODIGO|Descripcion' ---- */
IF CHARINDEX(N'SELECT '', '' + CONVERT(VARCHAR(200), S.DESCRIPCION)', @D) = 0
BEGIN RAISERROR('No se encontro el SELECT de E_SRV (V1). Se cancela.',16,1); RETURN; END;
SET @D = REPLACE(@D,
    N'SELECT '', '' + CONVERT(VARCHAR(200), S.DESCRIPCION)',
    N'SELECT '', '' + UPPER(LEFT(ISNULL(S.CODIGO,''''),2)) + ''|'' + CONVERT(VARCHAR(200), S.DESCRIPCION)');

/* ---- 2) @CALDATA: emitir data-r (responsable) + data-ri (iniciales) ---- */
IF CHARINDEX(N'data-srv="'' + ISNULL(A.E_SRV,'''') + ''"></i>', @D) = 0
BEGIN RAISERROR('No se encontro el <i> de @CALDATA (V1). Se cancela.',16,1); RETURN; END;
SET @D = REPLACE(@D,
    N'data-srv="'' + ISNULL(A.E_SRV,'''') + ''"></i>',
    N'data-srv="'' + ISNULL(A.E_SRV,'''') + ''" data-r="'' + ISNULL(A.E_RESP,'''') + ''" data-ri="'' + CASE WHEN ISNULL(A.RESP_INI,'''') IN ('''',''-'') THEN '''' ELSE A.RESP_INI END + ''"></i>');

/* ---- CREATE [OR ALTER] ... -> ALTER ---- */
SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC. Se cancela.',16,1); RETURN; END;
IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: ACCIONES_TOOLTIP_V2 aplicado (servicio como codigo + consultor con iniciales).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado: %s',16,1,@e);
END CATCH;
GO
