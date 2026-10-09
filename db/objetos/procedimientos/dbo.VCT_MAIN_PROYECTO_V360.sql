 
CREATE           PROCEDURE [dbo].[VCT_MAIN_PROYECTO_V360]
(
    @IPKEYJOB    VARCHAR(100),
    @FORM_ID     VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @OUTPARAM1   VARCHAR(MAX) OUTPUT,
    @OUTPARAM2   VARCHAR(MAX) OUTPUT,
    @OUTPARAM3   VARCHAR(MAX) OUTPUT
)
AS
BEGIN
 
SET NOCOUNT ON; /* MIGRADO_DG: grilla de gestiones con el motor vct-datagrid */
DECLARE @LANZ_MSG VARCHAR(1000)='', @LANZ_ERR VARCHAR(1000)='', @HTML_LANZ VARCHAR(MAX)='', @HTML_LANZ_FORMS VARCHAR(MAX)=''; /* LANZAMIENTO_V1 */
DECLARE @PLAN_MSG VARCHAR(1000)='', @PLAN_ERR VARCHAR(1000)='', @HTML_PLAN VARCHAR(MAX)='', @HTML_PLAN_FORMS VARCHAR(MAX)=''; /* PLAN_V1 */
DECLARE @VIS_MSG VARCHAR(1000)='', @VIS_ERR VARCHAR(1000)='', @HTML_VIS VARCHAR(MAX)='', @HTML_VIS_FORMS VARCHAR(MAX)=''; /* VISITAS_V1 */
 
DECLARE @HTML_SHELL VARCHAR(MAX)='';
DECLARE @HTML VARCHAR(MAX)='';
DECLARE @ID_PROYECTO INT;
DECLARE @ID_CLIENTE INT;
 
DECLARE @BUFFER_CLIENTE VARCHAR(100);
DECLARE @BUFFER_PROYECTO VARCHAR(100);
 
SELECT TOP 1
    @BUFFER_CLIENTE = REPLACE(ISNULL(IDSELEC01,''),',',''),
    @BUFFER_PROYECTO = REPLACE(ISNULL(IDSELEC02,''),',','')
FROM dbo.VCT_BUFFER WITH(NOLOCK)
WHERE PAR_KEY=@IPKEYJOB;
 
SET @ID_CLIENTE =
    CASE
        WHEN ISNUMERIC(@BUFFER_CLIENTE)=1
        THEN CONVERT(INT,@BUFFER_CLIENTE)
        ELSE NULL
    END;
SET @ID_PROYECTO =
    CASE
        WHEN ISNUMERIC(@BUFFER_PROYECTO)=1
        THEN CONVERT(INT,@BUFFER_PROYECTO)
        ELSE NULL
    END;
 
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.VCT_PROYECTOS
    WHERE ID=@ID_PROYECTO
      AND IDCLIENTE=@ID_CLIENTE
)
BEGIN
    SET @ID_PROYECTO=NULL;
END;
 
 
BEGIN TRY
    EXEC dbo.VCT_GET_SHELL
         @IUNIDAD=@IUNIDAD,
         @IAGENTE=@IAGENTE,
         @FORM_ID=@FORM_ID,
         @TITLE='Vista 360 de Proyecto',
         @SUBTITLE='Información completa del proyecto, plan estratégico y ejecución.',
         @SEARCH_PLACEHOLDER='',
         @SHOW_SEARCH=0,
         @OSHELL=@HTML_SHELL OUTPUT,
         @ORESULTADO=NULL;
END TRY
BEGIN CATCH
    SET @HTML_SHELL='';
END CATCH;
 
 
IF @ID_PROYECTO IS NULL
BEGIN
    SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+
    '<div class="vct-page vct-page-main">
        <section class="vct-card">
            <div class="vct-card-body">
                <h2 class="vct-card-title">Sin proyecto seleccionado</h2>
                <p class="vct-card-subtitle">Seleccione un proyecto desde la Vista 360 de Cliente.</p>
            </div>
        </section>
    </div>';
 
    SET @OUTPARAM2='';
    SET @OUTPARAM3='';
    RETURN;
END;
 
 
DECLARE
    @PROYECTO VARCHAR(300),
    @CLIENTE VARCHAR(300),
    @ESTADO VARCHAR(100),
    @SERVICIO VARCHAR(100),
    @AVANCE INT;
 
 
SELECT
    @PROYECTO=P.NOMBRE,
    @CLIENTE=C.RAZON_SOCIAL,
    @ESTADO=ISNULL(E.DESCRIPCION,''),
    @AVANCE=ISNULL(P.PORCENTAJE_AVANCE,0)
FROM dbo.VCT_PROYECTOS P
INNER JOIN dbo.VCT_CLIENTES C
    ON C.ID=P.IDCLIENTE
LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E
    ON E.ID=P.ID_ESTADO
WHERE P.ID=@ID_PROYECTO;
 
 
SELECT TOP 1
    @SERVICIO=S.DESCRIPCION
FROM dbo.VCT_PROYECTOS_SERVICIOS PS
INNER JOIN dbo.VCT_PRM_SERVICIOS S
    ON S.ID=PS.ID_SERVICIO
WHERE PS.ID_PROYECTO=@ID_PROYECTO;
 
 
-- CSS Vista 360 Proyecto:
-- El archivo vct_main_proyecto_v360.css debe registrarse en el layout/framework
-- de Muhle para evitar modificar estilos globales desde el SP.
-- Referencia:
-- vct_main_proyecto_v360.css
 
/* LANZAMIENTO_V1: acciones del analista (equipo, datos de entrada,
   consideraciones, reunion, inicio) y seccion "Lanzamiento". */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_LANZ_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@LANZ_MSG OUTPUT, @ERROR=@LANZ_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @LANZ_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;
 
/* VISITAS_V1: registro de visitas */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_VISITA_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@VIS_MSG OUTPUT, @ERROR=@VIS_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @VIS_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;
 
/* PLAN_V1: acciones del Plan Estrategico (antes del avance) */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_PLAN_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@PLAN_MSG OUTPUT, @ERROR=@PLAN_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @PLAN_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;
 
/* AVANCE_SYNC_V1: la columna PORCENTAJE_AVANCE queda igual al avance calculado (listas de las otras 360) */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_AVANCE_SYNC @ID_PROYECTO=@ID_PROYECTO;
END TRY
BEGIN CATCH
END CATCH;
 
/* AVANCE_V1: avance calculado (lanzamiento 10% + plan 90%) */
DECLARE @AVANCE_DET VARCHAR(200) = '';
BEGIN TRY
    SELECT @AVANCE = AVANCE, @AVANCE_DET = DETALLE FROM dbo.VCT_PROYECTO_AVANCE(@ID_PROYECTO);
END TRY
BEGIN CATCH
    SET @AVANCE_DET = '';
END CATCH;
 
/* BREADCRUMB_V1: el cliente del breadcrumb abre su Vista 360 con la
   misma accion VIEW que usa la grilla de Clientes (respeta permisos). */
DECLARE @BC_CLI VARCHAR(MAX) = dbo.VCT_HTML_ESC(ISNULL(@CLIENTE,''));
BEGIN TRY
    SELECT TOP 1 @BC_CLI =
        '<button type="button" class="vct-breadcrumb-link" data-vct-command="grid-action"'
        + ' data-vct-action-id="' + ISNULL(CONVERT(VARCHAR(50), A.ACTION_ID), '') + '"'
        + ' data-vct-store="' + ISNULL(NULLIF(CONVERT(VARCHAR(50), A.STORAGE_KEY), ''), 'IDSELEC01') + '"'
        + ' data-vct-value="' + CONVERT(VARCHAR(20), @ID_CLIENTE) + '"'
        + ' data-vct-guid="' + CONVERT(VARCHAR(50), A.TARGET_GUID) + '">'
        + dbo.VCT_HTML_ESC(ISNULL(@CLIENTE,'')) + '</button>'
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'CLIENTES') A
    WHERE A.ACTION_TYPE = 'VIEW' AND ISNULL(CONVERT(VARCHAR(50), A.TARGET_GUID), '') <> ''
    ORDER BY A.SORT_ORDER, A.ID_PRM;
END TRY
BEGIN CATCH
END CATCH;
 
/* el inicio del proyecto cambia el estado del encabezado */
SELECT @ESTADO=ISNULL(E.DESCRIPCION,'')
FROM dbo.VCT_PROYECTOS P
LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID=P.ID_ESTADO
WHERE P.ID=@ID_PROYECTO;
 
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_LANZ_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@LANZ_MSG, @ERROR=@LANZ_ERR,
         @HTML=@HTML_LANZ OUTPUT, @FORMS=@HTML_LANZ_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_LANZ='<div class="vct-lanz-alert is-error">No se pudo armar la seccion de lanzamiento: '+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+'</div>';
    SET @HTML_LANZ_FORMS='';
END CATCH;
 
/* PLAN_V1: seccion Plan Estrategico, arriba del lanzamiento */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_PLAN_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@PLAN_MSG, @ERROR=@PLAN_ERR,
         @HTML=@HTML_PLAN OUTPUT, @FORMS=@HTML_PLAN_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_PLAN='<div class="vct-lanz-alert is-error">No se pudo armar el Plan Estrategico: '+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+'</div>';
    SET @HTML_PLAN_FORMS='';
END CATCH;
/* VISITAS_V1: seccion Visitas y horas, debajo del plan */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_VISITA_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@VIS_MSG, @ERROR=@VIS_ERR,
         @HTML=@HTML_VIS OUTPUT, @FORMS=@HTML_VIS_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_VIS='<div class="vct-lanz-alert is-error">No se pudo armar la seccion de visitas: '+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+'</div>';
    SET @HTML_VIS_FORMS='';
END CATCH;
SET @HTML_LANZ=ISNULL(@HTML_PLAN,'')+ISNULL(@HTML_VIS,'')+ISNULL(@HTML_LANZ,'');
SET @HTML_LANZ_FORMS=ISNULL(@HTML_LANZ_FORMS,'')+ISNULL(@HTML_PLAN_FORMS,'')+ISNULL(@HTML_VIS_FORMS,'');
 
 
SET @HTML='
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-lanz.css?v=2"><script src="../js/vct-proyecto-lanz.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-plan.css?v=2"><script src="../js/vct-proyecto-plan.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-visitas.css?v=3"><script src="../js/vct-proyecto-visitas.js?v=2"></script><div class="vct-page vct-360-module vct-360-visual-final" data-vct-page data-vct-form-id="'+ISNULL(@FORM_ID,'')+'" data-vct-entity-theme="cliente">
 
<div class="vct-360-breadcrumb-row">
<div class="vct-breadcrumb-simple">
<button type="button" class="vct-breadcrumb-link" data-vct-v360-back data-vct-guid="26899560-A8E8-4E54-A3C8-F9ED1E95DC45">Clientes</button> <span class="vct-breadcrumb-sep">/</span> '+ISNULL(@BC_CLI,'')+' <span class="vct-breadcrumb-sep">/</span> <span class="vct-breadcrumb-current">'+ISNULL(@PROYECTO,'')+'</span>
</div>
</div>
 
<div class="vct-360-client-strip">
<div class="vct-360-card-left">
<div class="vct-360-avatar">'+LEFT(UPPER(ISNULL(@PROYECTO,'')),2)+'</div>
<div class="vct-360-identity">
<div class="vct-360-identity-title"><h1>'+ISNULL(@PROYECTO,'')+'</h1></div>
<div class="vct-360-client-meta">
<span><span data-vct-icon="contact"></span> '+ISNULL(@CLIENTE,'')+'</span>
<span><span data-vct-icon="briefcase"></span> '+ISNULL(@SERVICIO,'')+'</span>
<span><span data-vct-icon="check"></span> '+ISNULL(@ESTADO,'')+'</span>
</div>
</div>
</div>
</div>
 
<div class="vct-360-content-shell">
 
<div class="vct-360-stats-row">
 
<div class="vct-360-stat" data-vct-tone="blue">
<span>
<span class="vct-360-stat-label">Avance proyecto</span>
<b>'+CONVERT(VARCHAR(10),@AVANCE)+'%</b>'+CASE WHEN @AVANCE_DET<>'' THEN '<small style="display:block;font-size:11px;font-weight:400;opacity:.75;margin-top:2px">'+@AVANCE_DET+'</small>' ELSE '' END+'
</span>
<span class="vct-360-stat-icon"><span data-vct-icon="chart-bar"></span></span>
</div>
 
<div class="vct-360-stat" data-vct-tone="violet">
<span>
<span class="vct-360-stat-label">Items plan</span>
<b>'+CONVERT(VARCHAR(10),
(SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
 INNER JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID=I.ID_PLAN
 WHERE PL.ID_PROYECTO=@ID_PROYECTO))+'</b>
</span>
<span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span>
</div>
 
<div class="vct-360-stat" data-vct-tone="mint">
<span>
<span class="vct-360-stat-label">Gestiones</span>
<b>'+CONVERT(VARCHAR(10),
(SELECT COUNT(*) FROM dbo.VCT_GESTIONES WHERE ID_PROYECTO=@ID_PROYECTO))+'</b>
</span>
<span class="vct-360-stat-icon"><span data-vct-icon="clipboard-check"></span></span>
</div>
 
<div class="vct-360-stat" data-vct-tone="amber">
<span>
<span class="vct-360-stat-label">Horas usadas</span>
<b>'+CONVERT(VARCHAR(10),
dbo.VCT_PROYECTO_HORAS_USADAS_TXT(@ID_PROYECTO))+'</b>
</span>
<span class="vct-360-stat-icon"><span data-vct-icon="map-pin"></span></span>
</div>
 
</div>
 
 
'+ISNULL(@HTML_LANZ,'')+'
<div class="vct-360-box">
<div class="vct-360-box-head">
<h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>Últimas gestiones</h3>
</div>
 
<div class="vct-360-grid">
<div data-vct-dg data-vct-dg-id="proyecto-gestiones" data-vct-dg-title="Gestiones del proyecto" data-vct-dg-subtitle="Proyecto: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion..." data-vct-dg-density="compact" data-vct-dg-layout="fixed"><table><thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="gestion" data-vct-sortable="true"><span>Gestion</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="20%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead><tbody>';
 
SELECT @HTML=@HTML+
'<tr data-vct-row>
<td data-label="Fecha">'+ISNULL(CONVERT(VARCHAR(10),G.FECHA_CREACION,103),'-')+'</td>
<td data-label="Gestion">'+ISNULL(G.TITULO,'')+'</td>
<td data-label="Estado"><span class="vct-badge" data-vct-badge="'+ISNULL(E.DESCRIPCION,'')+'">'+ISNULL(E.DESCRIPCION,'')+'</span></td>
</tr>'
FROM dbo.VCT_GESTIONES G
LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS E
ON E.ID=G.ID_ESTADO
WHERE G.ID_PROYECTO=@ID_PROYECTO
ORDER BY G.ID DESC;
 
 
SET @HTML=@HTML+
'</tbody></table>
 
</div>
</div>
 
</div>
 
 
<div class="vct-360-box" style="display:none!important" data-vct-plan-old>
<div class="vct-360-box-head">
<h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Plan Estratégico</h3>
</div>
<div class="vct-plan-tree">';
 
SELECT @HTML=@HTML+
'<div class="vct-plan-item">
<b>'+ISNULL(I.CODIGO_ITEM,'')+'</b> - '+ISNULL(I.TITULO,'')+
'<div class="vct-plan-item-meta">
<span class="vct-plan-status" data-status="'+ISNULL(I.ESTADO,'')+'">'+ISNULL(I.ESTADO,'')+'</span>
<span class="vct-plan-progress">Avance: '+CONVERT(VARCHAR(10),ISNULL(I.PORCENTAJE_AVANCE,0))+'%</span>
</div>
</div>'
FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
INNER JOIN dbo.VCT_PROYECTOS_PLANES PL
ON PL.ID=I.ID_PLAN
WHERE PL.ID_PROYECTO=@ID_PROYECTO
ORDER BY I.ORDEN;
 
 
SET @HTML=@HTML+
'</div>
</div>
 
</div>
 
</div>';
 
 
SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+@HTML;
SET @OUTPARAM2='';
SET @OUTPARAM3=ISNULL(@HTML_LANZ_FORMS,'');
 
END
