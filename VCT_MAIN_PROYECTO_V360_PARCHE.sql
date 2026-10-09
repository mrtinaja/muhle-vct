/* ========================================================================
   VCT_MAIN_PROYECTO_V360 - grilla de gestiones al motor vct-datagrid
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE del servidor (no pisa nada mas):
     - La grilla "Ultimas gestiones" pasa a data-vct-dg (buscador, orden,
       paginado, Excel/PDF los arma el motor).
     - Se cargan vct-datagrid.css?v=4, vct-export.js?v=1, vct-datagrid.js?v=3.
     - Logica, estadisticas y Plan Estrategico: sin cambios.
   Si algun fragmento no se encuentra, NO aplica nada y avisa.
   Si ya fue aplicado (marca MIGRADO_DG), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D  NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s  INT, @e INT, @t INT, @f INT, @p1 INT, @p2 INT, @mk NVARCHAR(MAX), @mk2 NVARCHAR(MAX), @n NVARCHAR(MAX), @c INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'MIGRADO_DG',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360 ya estaba migrado. No se hizo nada.';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

/* ---- cada fragmento debe existir exactamente una vez ---- */
DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'<div class="vct-grid-card" data-vct-component="grid" data-vct-grid-id="proyecto-gestiones"'),
 (N'<tbody data-vct-grid-body>'),
 (N'<div class="vct-grid-footer">'),
 (N'</tbody>'),
 (N'<div class="vct-page vct-360-module vct-360-visual-final" data-vct-page'),
 (N'SET NOCOUNT ON;');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

/* ---- 1. cabecera: toolbar + tabla vieja -> host data-vct-dg + tabla ---- */
SET @mk  = N'<div class="vct-grid-card" data-vct-component="grid" data-vct-grid-id="proyecto-gestiones"';
SET @mk2 = N'<tbody data-vct-grid-body>';
SET @s = CHARINDEX(@mk, @D);
SET @e = CHARINDEX(@mk2, @D, @s);
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro la cabecera de la grilla. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'<div data-vct-dg data-vct-dg-id="proyecto-gestiones" data-vct-dg-title="Gestiones del proyecto" data-vct-dg-subtitle="Proyecto: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@PROYECTO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion..." data-vct-dg-density="compact" data-vct-dg-layout="fixed"><table><thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="gestion" data-vct-sortable="true"><span>Gestion</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="20%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead><tbody>';
SET @D = STUFF(@D, @s, (@e + LEN(@mk2)) - @s, @n);

/* ---- 2. cierre: </tbody> + </table> + table-wrap + footer viejo ---- */
SET @t  = CHARINDEX(N'</tbody>', @D, @s);
SET @f  = CASE WHEN @t > 0 THEN CHARINDEX(N'<div class="vct-grid-footer">', @D, @t) ELSE 0 END;
SET @p1 = CASE WHEN @f > 0 THEN CHARINDEX(N'</div>', @D, CHARINDEX(N'</select>', @D, @f)) ELSE 0 END;
SET @p2 = CASE WHEN @p1 > 0 THEN CHARINDEX(N'</div>', @D, @p1 + 1) ELSE 0 END;
IF @t = 0 OR @f = 0 OR @p1 = 0 OR @p2 = 0
BEGIN
    RAISERROR('No se encontro el pie de la grilla. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @t, (@p2 + 6) - @t, N'</tbody></table>');

/* ---- 3. assets del motor (CSS + export + datagrid) ---- */
SET @mk = N'<div class="vct-page vct-360-module vct-360-visual-final" data-vct-page';
SET @D = REPLACE(@D, @mk, N'<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script>' + @mk);

/* ---- 4. marca de migracion ---- */
SET @mk = N'SET NOCOUNT ON;';
SET @D = REPLACE(@D, @mk, N'SET NOCOUNT ON; /* MIGRADO_DG: grilla de gestiones con el motor vct-datagrid */');

/* ---- CREATE -> ALTER (tolera espacios extra) ---- */
SET @s = CHARINDEX(N'CREATE', @D);
IF @s > 0 AND @s < 4000 AND CHARINDEX(N'PROC', SUBSTRING(@D, @s, 40)) > 0
    SET @D = STUFF(@D, @s, 6, N'ALTER ');

IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTO_V360 migrado (grilla de gestiones).';
GO
