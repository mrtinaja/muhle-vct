USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[VCT_MAIN_PROYECTO_V360]    Script Date: 7/10/2026 17:33:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROCEDURE [dbo].[VCT_MAIN_PROYECTO_V360]
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

SET @HTML='
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><div class="vct-page vct-360-module vct-360-visual-final" data-vct-page data-vct-form-id="'+ISNULL(@FORM_ID,'')+'" data-vct-entity-theme="cliente">

<div class="vct-360-breadcrumb-row">
<div class="vct-breadcrumb-simple">
Clientes <span class="vct-breadcrumb-sep">/</span> '+ISNULL(@CLIENTE,'')+' <span class="vct-breadcrumb-sep">/</span> <span class="vct-breadcrumb-current">'+ISNULL(@PROYECTO,'')+'</span>
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
<b>'+CONVERT(VARCHAR(10),@AVANCE)+'%</b>
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
<span class="vct-360-stat-label">Visitas</span>
<b>'+CONVERT(VARCHAR(10),
(SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_VISITAS WHERE ID_PROYECTO=@ID_PROYECTO))+'</b>
</span>
<span class="vct-360-stat-icon"><span data-vct-icon="map-pin"></span></span>
</div>

</div>


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


<div class="vct-360-box">
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
SET @OUTPARAM3='';

END
