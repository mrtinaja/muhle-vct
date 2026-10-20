/* ============================================================================
   ACCIONES_TOOLTIP_V1
   ----------------------------------------------------------------------------
   El tooltip del calendario de la pantalla Acciones debe mostrar la jerarquia
   Cliente -> Proyecto -> Servicio -> Descripcion. Hoy @CALDATA solo emite
   fecha/situacion/titulo, asi que el tooltip no tiene cliente/proyecto/servicio.

   Este parche hace el ajuste MINIMO sobre dbo.VCT_MAIN_ACCIONES:
     1) agrega la columna E_SRV (servicios del proyecto, escapados) al #A,
     2) la puebla desde VCT_PROYECTOS_SERVICIOS + VCT_PRM_SERVICIOS,
     3) emite data-cli / data-proy / data-srv en cada <i> de @CALDATA.
   NO cambia el contrato del SP (mismos parametros), ni consultas, filtros,
   permisos o navegacion. Es "servicio = servicios del proyecto".

   Por que parche sobre la definicion viva (y no el .sql completo): es la forma
   que ya usa el repo para tocar SPs grandes (ver FIX_*/bump), evita retipear
   ~400 lineas y el riesgo de transcripcion, y mantiene lo que ya funciona.

   Re-ejecutable: si ya esta aplicado (marca ACCIONES_TOOLTIP_V1) avisa y no hace
   nada. Trabaja sobre OBJECT_DEFINITION y pasa CREATE -> ALTER.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_ACCIONES')),
        @up NVARCHAR(MAX), @cp INT, @probe INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_ACCIONES.',16,1); RETURN;
END;

IF CHARINDEX(N'ACCIONES_TOOLTIP_V1', @D) > 0
BEGIN
    PRINT 'ACCIONES_TOOLTIP_V1 ya aplicado. No se hace nada.'; RETURN;
END;

/* ---- 1) columna E_SRV en el #A ---- */
IF CHARINDEX(N'E_SEARCH VARCHAR(4000), MENU VARCHAR(MAX)', @D) = 0
BEGIN
    RAISERROR('No se encontro la definicion esperada del #A (E_SEARCH ... MENU). Se cancela.',16,1); RETURN;
END;
SET @D = REPLACE(@D,
    N'E_SEARCH VARCHAR(4000), MENU VARCHAR(MAX)',
    N'E_SEARCH VARCHAR(4000), E_SRV VARCHAR(900), MENU VARCHAR(MAX)');

/* ---- 2) poblar E_SRV (servicios del proyecto) antes del menu de 3 puntos ---- */
IF CHARINDEX(N'/* menu de 3 puntos por fila (permisos del perfil) */', @D) = 0
BEGIN
    RAISERROR('No se encontro el ancla del menu de 3 puntos. Se cancela.',16,1); RETURN;
END;
SET @D = REPLACE(@D,
    N'/* menu de 3 puntos por fila (permisos del perfil) */',
    N'/* ACCIONES_TOOLTIP_V1: servicios del proyecto para el tooltip (crudo) */
    UPDATE A SET E_SRV = ISNULL(STUFF((
        SELECT '', '' + CONVERT(VARCHAR(200), S.DESCRIPCION)
        FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO
        WHERE PS.ID_PROYECTO = A.ID_PROYECTO
        ORDER BY S.DESCRIPCION
        FOR XML PATH(''''), TYPE).value(''.'',''VARCHAR(MAX)''), 1, 2, ''''), '''')
    FROM #A A WHERE A.ID_PROYECTO IS NOT NULL;
    UPDATE #A SET E_SRV = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(E_SRV,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'');

    /* menu de 3 puntos por fila (permisos del perfil) */');

/* ---- 3) emitir data-cli / data-proy / data-srv en @CALDATA ---- */
IF CHARINDEX(N'" data-t="'' + A.E_TIT + ''"></i>', @D) = 0
BEGIN
    RAISERROR('No se encontro el <i> de @CALDATA. Se cancela.',16,1); RETURN;
END;
SET @D = REPLACE(@D,
    N'" data-t="'' + A.E_TIT + ''"></i>',
    N'" data-t="'' + A.E_TIT + ''" data-cli="'' + ISNULL(A.E_CLI,'''') + ''" data-proy="'' + ISNULL(A.E_PROY,'''') + ''" data-srv="'' + ISNULL(A.E_SRV,'''') + ''"></i>');

/* ---- CREATE [OR ALTER] ... -> ALTER (ancla en el CREATE real del proc) ---- */
SET @up = UPPER(@D); SET @cp = 0;
DECLARE @scan INT = 1;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC. Se cancela.',16,1); RETURN; END;

IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER'
    SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE
    SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: ACCIONES_TOOLTIP_V1 aplicado (Cliente/Proyecto/Servicio en el tooltip de Acciones).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado: %s',16,1,@e);
END CATCH;
GO
