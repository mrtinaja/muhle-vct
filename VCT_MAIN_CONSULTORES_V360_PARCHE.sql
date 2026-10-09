/* ========================================================================
   VCT_MAIN_CONSULTORES_V360 - grillas internas al motor vct-datagrid
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

DECLARE @D  NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'));
DECLARE @s  INT, @e INT, @mk NVARCHAR(MAX), @ed NVARCHAR(MAX), @n NVARCHAR(MAX), @c INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_CONSULTORES_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'MIGRADO_DG',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_CONSULTORES_V360 ya estaba migrado. No se hizo nada.';
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
SET @ed = N'''</section>'';';

/* ---- grilla v360_con_proyectos ---- */
SET @mk = N'''<section class="vct-360-grid vct-360-grid-projects-full" data-vct-component="grid" data-vct-grid-id="v360_con_proyectos"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_proyectos. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_proyectos" data-vct-dg-title="Proyectos del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="proyecto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar proyecto, cliente..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-width="20%" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="40%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="inicio" data-vct-sortable="true" data-vct-sort-type="date"><span>Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="fin" data-vct-sortable="true" data-vct-sort-type="date"><span>Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="avance" data-vct-sortable="true" data-vct-sort-type="number"><span>Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_PROYECTOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_gestiones ---- */
SET @mk = N'''<section class="vct-360-grid vct-360-gestiones-grid" data-vct-component="grid" data-vct-grid-id="v360_con_gestiones"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_gestiones. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_gestiones" data-vct-dg-title="Gestiones del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion, cliente, proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-width="4%" data-vct-export-ignore="true" aria-label="Tipo"></th><th data-vct-width="17%" data-vct-sort="gestion" data-vct-sortable="true"><span>Gestión</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="27%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="responsable" data-vct-sortable="true"><span>Responsable</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="vencimiento" data-vct-sortable="true" data-vct-sort-type="date"><span>Vencimiento</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_GESTIONES+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_dom ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_dom"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_dom. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_dom" data-vct-dg-title="Domicilios del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Dirección</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_DOMICILIOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_tel ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_tel"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_tel. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_tel" data-vct-dg-title="Telefonos del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Código área</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Número</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_TELEFONOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_mail ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_mail"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_mail. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_mail" data-vct-dg-title="Emails del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>''+
            ''<tbody>''+@HTML_EMAILS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_normas ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_normas"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_normas. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_normas" data-vct-dg-title="Normas del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="norma(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar norma..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr>''+''<th data-vct-sort="norma" data-vct-sortable="true"><span>Norma</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>''+CASE WHEN @NormHasEstado=1 THEN ''<th class="vct-text-center" data-vct-width="14%" data-vct-sort="estado" data-vct-sortable="true"><span>''+@NORMA_ESTADO_LABEL+''</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'' ELSE '''' END+CASE WHEN @NormHasDesde=1 THEN ''<th class="vct-text-center" data-vct-width="11%" data-vct-sort="desde" data-vct-sortable="true" data-vct-sort-type="date"><span>''+''Desde''+''</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'' ELSE '''' END+CASE WHEN @NormHasHasta=1 THEN ''<th class="vct-text-center" data-vct-width="11%" data-vct-sort="hasta" data-vct-sortable="true" data-vct-sort-type="date"><span>''+''Hasta''+''</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'' ELSE '''' END+''<th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>''+''<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>''+''</tr></thead>''+
            ''<tbody>''+@HTML_NORMAS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_hist ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_hist"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_hist. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_hist" data-vct-dg-title="Dias mensuales del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="periodo(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar periodo, proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr>''+''<th class="vct-text-center" data-vct-width="14%" data-vct-sort="periodo" data-vct-sortable="true" data-vct-sort-type="number"><span>Período</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>''+CASE WHEN @HistHasProject=1 THEN ''<th data-vct-sort="proyecto" data-vct-sortable="true"><span>''+''Proyecto''+''</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'' ELSE '''' END+''<th class="vct-text-center" data-vct-width="12%" data-vct-sort="dias" data-vct-sortable="true" data-vct-sort-type="number"><span>Días</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>''+CASE WHEN @HistHasObs=1 THEN ''<th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>''+''Observaciones''+''</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'' ELSE '''' END+''</tr></thead>''+
            ''<tbody>''+@HTML_HISTORICO+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_docs ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_docs"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_docs. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_docs" data-vct-dg-title="Documentos del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="documento(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar documento..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="documento" data-vct-sortable="true"><span>Documento</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="emision" data-vct-sortable="true" data-vct-sort-type="date"><span>Emisión</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="cierre" data-vct-sortable="true" data-vct-sort-type="date"><span>Cierre</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="26%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_DOCUMENTOS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

/* ---- grilla v360_con_notas ---- */
SET @mk = N'''<section class="vct-360-grid" data-vct-component="grid" data-vct-grid-id="v360_con_notas"';
SET @s  = CHARINDEX(@mk, @D);
SET @e  = CASE WHEN @s > 0 THEN CHARINDEX(@ed, @D, @s + 1) ELSE 0 END;
IF @s = 0 OR @e = 0
BEGIN
    RAISERROR('No se encontro el bloque de la grilla v360_con_notas. No se aplico nada.',16,1);
    RETURN;
END;
SET @n = N'''<div data-vct-dg data-vct-dg-id="v360_con_notas" data-vct-dg-title="Notas del consultor" data-vct-dg-subtitle="Consultor: ''+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;''),''"'',''&quot;'')+''" data-vct-dg-unit="nota(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar nota..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">''+
            ''<table>''+
            ''<thead><tr><th class="vct-text-center" data-vct-width="10%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="22%" data-vct-sort="titulo" data-vct-sortable="true"><span>Título</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="nota" data-vct-sortable="true" data-vct-truncate="2"><span>Nota</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="16%" data-vct-sort="usuario" data-vct-sortable="true"><span>Usuario</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>''+
            ''<tbody>''+@HTML_NOTAS+''</tbody>''+
            ''</table>''+
            ''</div>'';';
SET @D = STUFF(@D, @s, (@e + DATALENGTH(@ed)/2) - @s, @n);

SET @mk = N'''<td class="vct-text-center" data-label="Avance" style="width:10% !important;">''+';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Avance de Proyectos. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-text-center" data-label="Avance" data-vct-sort-value="''+CONVERT(VARCHAR(5),ISNULL(P.PORCENTAJE_AVANCE,0))+''" style="width:10% !important;">''+');

SET @mk = N'''<td data-label="Responsable" class="vct-360-cell-person"';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Responsable de Gestiones. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td data-label="Responsable" data-vct-sort-value="''+ResponsableNombre+''" class="vct-360-cell-person"');

SET @mk = N'''<td class="vct-text-center" data-label="Período">''+';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Periodo del historico. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-text-center" data-label="Período" data-vct-sort-value="''+CASE WHEN H.FECHA IS NOT NULL THEN CONVERT(VARCHAR(6),H.FECHA,112) ELSE ''0'' END+''">''+');

SET @mk = N'''<td class="vct-text-center" data-label="Días">''+';
SET @c = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @mk, N''))) / NULLIF(DATALENGTH(@mk),0);
IF @c <> 1
BEGIN
    RAISERROR('No se encontro la celda Dias del historico. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = REPLACE(@D, @mk, N'''<td class="vct-text-center" data-label="Días" data-vct-sort-value="''+CONVERT(VARCHAR(30),CAST(ROUND(ISNULL(H.DIAS,0)*100,0) AS BIGINT))+''">''+');

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
PRINT 'OK: VCT_MAIN_CONSULTORES_V360 migrado (Proyectos, Gestiones, Normas, Dias, Domicilios, Telefonos, Emails, Documentos y Notas).';
GO
