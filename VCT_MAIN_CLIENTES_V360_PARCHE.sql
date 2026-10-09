/* ========================================================================
   VCT_MAIN_CLIENTES_V360 - grillas internas al motor vct-datagrid
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE del servidor (no pisa nada mas):
     - Las grillas internas pasan a data-vct-dg (buscador, orden, paginado,
       Excel/PDF los arma el motor).
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

DECLARE @D  NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CLIENTES_V360'));
DECLARE @s  INT, @e INT, @mk NVARCHAR(MAX), @ed NVARCHAR(MAX), @n NVARCHAR(MAX), @c INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_CLIENTES_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'MIGRADO_DG',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_CLIENTES_V360 ya estaba migrado. No se hizo nada.';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
SET @ed = N'''</section>'';';

/* ---- grilla v360_proy ---- */
SET @mk = N'''<section class="vct-360-grid vct-360-grid-projects-full" data-vct-component="grid" data-vct-grid-id="v360_proy"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_proy. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_proy" data-vct-dg-title="Proyectos del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="proyecto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="12%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="inicio" data-vct-sortable="true" data-vct-sort-type="date"><span>Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="fin" data-vct-sortable="true" data-vct-sort-type="date"><span>Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="12%" data-vct-sort="avance" data-vct-sortable="true" data-vct-sort-type="number"><span>Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_PROYECTOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_dom ---- */
SET @mk = N'''<section class="vct-360-grid " data-vct-component="grid" data-vct-grid-id="v360_dom"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_dom. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_dom" data-vct-dg-title="Domicilios del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Dirección</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_DOMICILIOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_tel ---- */
SET @mk = N'''<section class="vct-360-grid " data-vct-component="grid" data-vct-grid-id="v360_tel"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_tel. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_tel" data-vct-dg-title="Telefonos del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Código área</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Número</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_TELEFONOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_mail ---- */
SET @mk = N'''<section class="vct-360-grid " data-vct-component="grid" data-vct-grid-id="v360_mail"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_mail. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_mail" data-vct-dg-title="Emails del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_EMAILS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_cont ---- */
SET @mk = N'''<section class="vct-360-grid " data-vct-component="grid" data-vct-grid-id="v360_cont"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_cont. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_cont" data-vct-dg-title="Contactos del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="contacto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar contacto, cargo, email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-width="46" data-vct-export-ignore="true" aria-label="Avatar"></th><th data-vct-width="14%" data-vct-sort="apellido" data-vct-sortable="true"><span>Apellido</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="nombres" data-vct-sortable="true"><span>Nombres</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="cargo" data-vct-sortable="true"><span>Cargo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="telefono" data-vct-sortable="true"><span>Teléfono</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="17%" data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_CONTACTOS_TABLE+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_gest ---- */
SET @mk = N'''<section class="vct-360-grid vct-360-gestiones-grid" data-vct-component="grid" data-vct-grid-id="v360_gest"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_gest. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_gest" data-vct-dg-title="Gestiones del cliente" data-vct-dg-subtitle="Cliente: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion, proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="8%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="28%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="22%" data-vct-sort="gestion" data-vct-sortable="true"><span>Gestión</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo / Subtipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="10%" data-vct-sort="responsable" data-vct-sortable="true"><span>Responsable</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="vencimiento" data-vct-sortable="true" data-vct-sort-type="date"><span>Vencimiento</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="9%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_GESTIONES+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

SET @mk = N'''<td class="vct-text-center" data-label="Avance"><div class="vct-360-progress">';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Avance de Proyectos. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-text-center" data-label="Avance" data-vct-sort-value="'' + AvanceTxt + ''"><div class="vct-360-progress">');

SET @mk = N'''<td class="vct-360-action-cell" data-label="360">';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda 360 de Proyectos. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-360-action-cell vct-table-action-cell" data-label="360" data-vct-export-ignore="true">');

SET @mk = N'<section class="vct-module vct-360-module vct-consultor360-module vct-cliente360-module';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro (o esta repetido) el contenedor principal de la ficha. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><section class="vct-module vct-360-module vct-consultor360-module vct-cliente360-module');

SET @mk = N'class="vct-360-action-cell" data-label="Acciones"';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 4
BEGIN
    RAISERROR('Las celdas de acciones no son 4 como se esperaba. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true"');

SET @mk = N'SET NOCOUNT ON;';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro el ancla de la marca de migracion. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'SET NOCOUNT ON; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */');

/* ---- CREATE -> ALTER (si la definicion guardada empieza con CREATE; tolera espacios extra) ---- */
SET @s = CHARINDEX(N'CREATE', @D);
IF @s > 0 AND @s < 4000 AND CHARINDEX(N'PROC', SUBSTRING(@D, @s, 40)) > 0
    SET @D = STUFF(@D, @s, 6, N'ALTER ');

IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_CLIENTES_V360 migrado (Proyectos, Domicilios, Telefonos, Emails, Contactos y Gestiones).';
GO
