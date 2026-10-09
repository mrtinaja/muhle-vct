/* ========================================================================
   VCT_MAIN_PROVEEDORES_V360 - grillas internas al motor vct-datagrid
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE del servidor (no pisa nada mas):
     - Domicilios / Telefonos / Emails / Viaticos pasan a data-vct-dg
       (buscador, orden, paginado, Excel/PDF los arma el motor).
     - Se cargan vct-datagrid.css?v=4, vct-export.js?v=1, vct-datagrid.js?v=3.
     - Logica, permisos, formularios (drawers), KPIs y graficos: sin cambios.
   Si algun fragmento no se encuentra, NO aplica nada y avisa.
   Si ya fue aplicado (marca MIGRADO_DG), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D  NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROVEEDORES_V360'));
DECLARE @s  INT, @e INT, @mk NVARCHAR(MAX), @ed NVARCHAR(MAX), @n NVARCHAR(MAX), @c INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROVEEDORES_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'MIGRADO_DG',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROVEEDORES_V360 ya estaba migrado. No se hizo nada.';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
SET @ed = N'''</section>'';';

/* ---- grilla v360_prov_dom ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_prov_dom"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_prov_dom. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_prov_dom" data-vct-dg-title="Domicilios del proveedor" data-vct-dg-subtitle="Proveedor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Direccion</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_DOMICILIOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_prov_tel ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_prov_tel"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_prov_tel. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_prov_tel" data-vct-dg-title="Telefonos del proveedor" data-vct-dg-subtitle="Proveedor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Codigo area</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Numero</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_TELEFONOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_prov_mail ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_prov_mail"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_prov_mail. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_prov_mail" data-vct-dg-title="Emails del proveedor" data-vct-dg-subtitle="Proveedor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_EMAILS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_prov_viaticos ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_prov_viaticos"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_prov_viaticos. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_prov_viaticos" data-vct-dg-title="Viaticos del proveedor" data-vct-dg-subtitle="Proveedor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="viatico(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar viatico, proyecto, consultor..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="9%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="23%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="consultor" data-vct-sortable="true"><span>Consultor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="destino" data-vct-sortable="true" data-vct-truncate="2"><span>Destino / Detalle</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-right" data-vct-width="11%" data-vct-sort="importe" data-vct-sortable="true" data-vct-sort-type="number"><span>Importe</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="pago" data-vct-sortable="true"><span>Pago</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_VIATICOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- assets: css + scripts del motor ---- */
SET @mk = N'<section class="vct-module vct-360-module vct-proveedor360-module vct-360-visual-final"';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro (o esta repetido) el contenedor principal de la ficha. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script>' + @mk);

/* ---- celdas de acciones de las 3 grillas de contacto ---- */
SET @mk = N'class="vct-360-action-cell" data-label="Acciones"';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 3
BEGIN
    RAISERROR('Las celdas de acciones no son 3 como se esperaba. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true"');

/* ---- importe numerico para ordenar ---- */
SET @mk = N'''<td class="vct-text-right" data-label="Importe">''+';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Importe de Viaticos. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-text-right" data-label="Importe" data-vct-sort-value="''+CONVERT(VARCHAR(30),CAST(ROUND(ISNULL(V.IMPORTE,0)*100,0) AS BIGINT))+''">''+');

/* ---- marca de migracion ---- */
SET @mk = N'DECLARE @MODULE_CODE VARCHAR(50)=''PROVEEDORES'';';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la declaracion del modulo. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'DECLARE @MODULE_CODE VARCHAR(50)=''PROVEEDORES''; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */');

/* ---- CREATE -> ALTER (si la definicion guardada empieza con CREATE) ---- */
SET @s = CHARINDEX(N'CREATE PROCEDURE', @D);
IF @s > 0 AND @s < 4000
    SET @D = STUFF(@D, @s, 16, N'ALTER PROCEDURE');

IF CHARINDEX(N'ALTER PROCEDURE', @D) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROVEEDORES_V360 migrado (Domicilios, Telefonos, Emails y Viaticos).';
GO
