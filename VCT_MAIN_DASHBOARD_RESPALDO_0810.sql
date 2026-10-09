/* RESPALDO de VCT_MAIN_DASHBOARD (Inicio) tal como estaba el 08/10/2026,
   antes del Inicio por perfil. Correr para volver atras. */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE [dbo].[VCT_MAIN_DASHBOARD]
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
    SET NOCOUNT ON;

    SET @OUTPARAM1='';
    SET @OUTPARAM2=NULL;
    SET @OUTPARAM3=NULL;

    DECLARE
        @HTML_SHELL            VARCHAR(MAX)='',
        @RESULTADO_SHELL       VARCHAR(20)='',
        @HTML                  VARCHAR(MAX)='',
        @HTML_ACTIVIDAD        VARCHAR(MAX)='',
        @HTML_PROXIMAS         VARCHAR(MAX)='',
        @HTML_BARRAS           VARCHAR(MAX)='',
        @CLIENTES_ACTIVOS      INT=0,
        @PROYECTOS_VIGENTES    INT=0,
        @GESTIONES_ACTIVAS     INT=0,
        @GESTIONES_MES         INT=0,
        @PROY_TOTAL            INT=0,
        @PROY_ACTIVOS          INT=0,
        @PROY_CONFIRMADOS      INT=0,
        @PROY_TERMINADOS       INT=0,
        @PROY_OTROS            INT=0,
        @PCT_ACTIVOS           INT=0,
        @PCT_CONFIRMADOS       INT=0,
        @PCT_TERMINADOS        INT=0,
        @PCT_OTROS             INT=0,
        @STOP_1                INT=0,
        @STOP_2                INT=0,
        @STOP_3                INT=0,
        @DONUT_STYLE           VARCHAR(1000)='',
        @MAX_GEST_MES          INT=0,
        @SIDEBAR_ID            INT=0;

    /* ============================================================
       1. SHELL GENERAL
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Inicio',
             @SUBTITLE           = 'Resumen general de clientes, proyectos y gestiones.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL='';
        SET @RESULTADO_SHELL='ERROR';
    END CATCH;

    BEGIN TRY
        SELECT TOP 1 @SIDEBAR_ID=CONVERT(INT,SB.Id)
        FROM dbo.SideBar SB WITH(NOLOCK)
        INNER JOIN dbo.SideBarGroups SBG WITH(NOLOCK)
            ON CONVERT(VARCHAR(50),SBG.SideBarId)=CONVERT(VARCHAR(50),SB.Id)
        WHERE UPPER(LTRIM(RTRIM(SBG.GroupId)))=UPPER(LTRIM(RTRIM(@IUNIDAD)))
          AND UPPER(LTRIM(RTRIM(ISNULL(SB.Code,''))))='INICIO'
        ORDER BY CONVERT(INT,SB.Id);
    END TRY
    BEGIN CATCH
        SET @SIDEBAR_ID=0;
    END CATCH;

    /* ============================================================
       2. KPIs
       ============================================================ */
    BEGIN TRY
        SELECT @CLIENTES_ACTIVOS=COUNT(*)
        FROM dbo.VCT_CLIENTES WITH(NOLOCK)
        WHERE UPPER(LTRIM(RTRIM(ISNULL(TIPO,''))))='ACTIVO';
    END TRY
    BEGIN CATCH
        SET @CLIENTES_ACTIVOS=0;
    END CATCH;

    BEGIN TRY
        SELECT @PROYECTOS_VIGENTES=COUNT(*)
        FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E WITH(NOLOCK)
            ON E.ID=P.ID_ESTADO
        WHERE E.CODIGO IN ('ENCURSO','CONFIRMADO');
    END TRY
    BEGIN CATCH
        SET @PROYECTOS_VIGENTES=0;
    END CATCH;

    BEGIN TRY
        SELECT @GESTIONES_ACTIVAS=COUNT(*)
        FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS E WITH(NOLOCK)
            ON E.ID=G.ID_ESTADO
        WHERE E.ES_FINAL=0;

        SELECT @GESTIONES_MES=COUNT(*)
        FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
        WHERE G.FECHA_CREACION >= DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0)
          AND G.FECHA_CREACION <  DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())+1,0);
    END TRY
    BEGIN CATCH
        SET @GESTIONES_ACTIVAS=0;
        SET @GESTIONES_MES=0;
    END CATCH;

    /* ============================================================
       3. ACTIVIDAD RECIENTE
       ============================================================ */
    BEGIN TRY
        SELECT @HTML_ACTIVIDAD=ISNULL((
            SELECT
                '<div class="vct-dashboard-activity-row">'+
                    '<span class="vct-dashboard-row-icon is-blue" data-vct-icon="list-checks"></span>'+
                    '<div class="vct-dashboard-row-main">'+
                        '<span class="vct-dashboard-row-title">'+ActividadTitulo+'</span>'+
                        '<span class="vct-dashboard-row-meta">'+ActividadMeta+'</span>'+
                    '</div>'+
                    '<span class="vct-dashboard-row-date">'+FechaTxt+'</span>'+
                '</div>'
            FROM
            (
                SELECT TOP 5
                    G.ID AS SortID,
                    ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) AS SortFecha,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(NULLIF(LTRIM(RTRIM(G.TITULO)),''),'Gestion registrada'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ActividadTitulo,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN P.NOMBRE IS NOT NULL AND LTRIM(RTRIM(P.NOMBRE))<>''
                                THEN P.NOMBRE
                            WHEN GE.DESCRIPCION IS NOT NULL AND LTRIM(RTRIM(GE.DESCRIPCION))<>''
                                THEN GE.DESCRIPCION
                            ELSE 'Actividad del sistema'
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ActividadMeta,
                    ISNULL(CONVERT(VARCHAR(10),
                        ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)),103),'-') AS FechaTxt
                FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
                LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
                    ON P.ID=G.ID_PROYECTO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE WITH(NOLOCK)
                    ON GE.ID=G.ID_ESTADO
                ORDER BY
                    ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) DESC,
                    G.ID DESC
            ) X
            ORDER BY SortFecha DESC,SortID DESC
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
    END TRY
    BEGIN CATCH
        SET @HTML_ACTIVIDAD='';
    END CATCH;

    IF ISNULL(@HTML_ACTIVIDAD,'')=''
        SET @HTML_ACTIVIDAD=
            '<div class="vct-dashboard-empty">No hay actividad reciente para mostrar.</div>';

    /* ============================================================
       4. PROXIMAS GESTIONES
       Gestiones abiertas con vencimiento desde hoy.
       ============================================================ */
    BEGIN TRY
        SELECT @HTML_PROXIMAS=ISNULL((
            SELECT
                '<div class="vct-dashboard-next-row">'+
                    '<div class="vct-dashboard-date-chip">'+
                        '<span class="vct-dashboard-date-day">'+DIA+'</span>'+
                        '<span class="vct-dashboard-date-month">'+MES+'</span>'+
                    '</div>'+
                    '<div class="vct-dashboard-row-main">'+
                        '<span class="vct-dashboard-row-title">'+Titulo+'</span>'+
                        '<span class="vct-dashboard-row-meta">'+Meta+'</span>'+
                    '</div>'+
                    '<span class="vct-dashboard-status '+ClaseEstado+'">'+EstadoTxt+'</span>'+
                '</div>'
            FROM
            (
                SELECT TOP 4
                    G.ID AS SortID,
                    G.FECHA_VENCIMIENTO AS SortFecha,
                    RIGHT('0'+CONVERT(VARCHAR(2),DAY(G.FECHA_VENCIMIENTO)),2) AS DIA,
                    CASE MONTH(G.FECHA_VENCIMIENTO)
                        WHEN 1 THEN 'ENE' WHEN 2 THEN 'FEB' WHEN 3 THEN 'MAR'
                        WHEN 4 THEN 'ABR' WHEN 5 THEN 'MAY' WHEN 6 THEN 'JUN'
                        WHEN 7 THEN 'JUL' WHEN 8 THEN 'AGO' WHEN 9 THEN 'SEP'
                        WHEN 10 THEN 'OCT' WHEN 11 THEN 'NOV' ELSE 'DIC'
                    END AS MES,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(NULLIF(LTRIM(RTRIM(G.TITULO)),''),'Gestion'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS Titulo,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN P.NOMBRE IS NOT NULL AND LTRIM(RTRIM(P.NOMBRE))<>''
                                THEN CASE
                                    WHEN NULLIF(LTRIM(RTRIM(ISNULL(P.CODIGO,''))),'') IS NOT NULL
                                        THEN 'Proyecto '+P.CODIGO+' - '+P.NOMBRE
                                    ELSE P.NOMBRE
                                END
                            ELSE ISNULL(T.DESCRIPCION,'Gestion')
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS Meta,
                    CASE
                        WHEN E.CODIGO='PENDIENTE' THEN 'is-pending'
                        ELSE 'is-progress'
                    END AS ClaseEstado,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(E.DESCRIPCION,'Pendiente'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EstadoTxt
                FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
                INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS E WITH(NOLOCK)
                    ON E.ID=G.ID_ESTADO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK)
                    ON T.ID=G.ID_TIPO
                LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
                    ON P.ID=G.ID_PROYECTO
                WHERE E.ES_FINAL=0
                  AND G.FECHA_VENCIMIENTO IS NOT NULL
                  AND G.FECHA_VENCIMIENTO>=DATEADD(DAY,DATEDIFF(DAY,0,GETDATE()),0)
                ORDER BY G.FECHA_VENCIMIENTO,G.ID
            ) X
            ORDER BY SortFecha,SortID
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
    END TRY
    BEGIN CATCH
        SET @HTML_PROXIMAS='';
    END CATCH;

    IF ISNULL(@HTML_PROXIMAS,'')=''
        SET @HTML_PROXIMAS=
            '<div class="vct-dashboard-empty">No hay proximas gestiones con vencimiento.</div>';

    /* ============================================================
       5. PROYECTOS POR ESTADO
       Estados estabilizados para un grafico consistente entre pantallas.
       ============================================================ */
    BEGIN TRY
        SELECT
            @PROY_TOTAL=COUNT(*),
            @PROY_ACTIVOS=SUM(CASE WHEN E.CODIGO='ENCURSO' THEN 1 ELSE 0 END),
            @PROY_CONFIRMADOS=SUM(CASE WHEN E.CODIGO='CONFIRMADO' THEN 1 ELSE 0 END),
            @PROY_TERMINADOS=SUM(CASE WHEN E.CODIGO='TERMINADO' THEN 1 ELSE 0 END),
            @PROY_OTROS=SUM(CASE
                WHEN ISNULL(E.CODIGO,'') NOT IN ('ENCURSO','CONFIRMADO','TERMINADO')
                    THEN 1 ELSE 0 END)
        FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E WITH(NOLOCK)
            ON E.ID=P.ID_ESTADO;
    END TRY
    BEGIN CATCH
        SET @PROY_TOTAL=0;
        SET @PROY_ACTIVOS=0;
        SET @PROY_CONFIRMADOS=0;
        SET @PROY_TERMINADOS=0;
        SET @PROY_OTROS=0;
    END CATCH;

    SET @PROY_TOTAL=ISNULL(@PROY_TOTAL,0);
    SET @PROY_ACTIVOS=ISNULL(@PROY_ACTIVOS,0);
    SET @PROY_CONFIRMADOS=ISNULL(@PROY_CONFIRMADOS,0);
    SET @PROY_TERMINADOS=ISNULL(@PROY_TERMINADOS,0);
    SET @PROY_OTROS=ISNULL(@PROY_OTROS,0);

    IF @PROY_TOTAL>0
    BEGIN
        SET @PCT_ACTIVOS=CONVERT(INT,ROUND((@PROY_ACTIVOS*100.0)/@PROY_TOTAL,0));
        SET @PCT_CONFIRMADOS=CONVERT(INT,ROUND((@PROY_CONFIRMADOS*100.0)/@PROY_TOTAL,0));
        SET @PCT_TERMINADOS=CONVERT(INT,ROUND((@PROY_TERMINADOS*100.0)/@PROY_TOTAL,0));

        SET @STOP_1=@PCT_ACTIVOS;
        SET @STOP_2=@STOP_1+@PCT_CONFIRMADOS;
        SET @STOP_3=@STOP_2+@PCT_TERMINADOS;
        IF @STOP_3>100 SET @STOP_3=100;
        SET @PCT_OTROS=100-@STOP_3;

        SET @DONUT_STYLE=
            'background:conic-gradient('+
            '#69A8FF 0% '+CONVERT(VARCHAR(10),@STOP_1)+'%,'+
            '#C59AF4 '+CONVERT(VARCHAR(10),@STOP_1)+'% '+CONVERT(VARCHAR(10),@STOP_2)+'%,'+
            '#82D8A2 '+CONVERT(VARCHAR(10),@STOP_2)+'% '+CONVERT(VARCHAR(10),@STOP_3)+'%,'+
            '#F4BC78 '+CONVERT(VARCHAR(10),@STOP_3)+'% 100%);';
    END
    ELSE
    BEGIN
        SET @DONUT_STYLE='background:#EEF2F7;';
    END;

    /* ============================================================
       6. GESTIONES POR MES - ULTIMOS 6 MESES
       ============================================================ */
    IF OBJECT_ID('tempdb..#GEST_MES') IS NOT NULL DROP TABLE #GEST_MES;

    CREATE TABLE #GEST_MES
    (
        ORDEN       INT,
        MES_INICIO  DATETIME,
        MES_LABEL   VARCHAR(10),
        TOTAL       INT,
        PCT_ALTURA  INT
    );

    ;WITH N AS
    (
        SELECT -5 AS N UNION ALL SELECT -4 UNION ALL SELECT -3
        UNION ALL SELECT -2 UNION ALL SELECT -1 UNION ALL SELECT 0
    )
    INSERT INTO #GEST_MES(ORDEN,MES_INICIO,MES_LABEL,TOTAL,PCT_ALTURA)
    SELECT
        N.N+6,
        DATEADD(MONTH,N.N,DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0)),
        CASE MONTH(DATEADD(MONTH,N.N,GETDATE()))
            WHEN 1 THEN 'Ene' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar'
            WHEN 4 THEN 'Abr' WHEN 5 THEN 'May' WHEN 6 THEN 'Jun'
            WHEN 7 THEN 'Jul' WHEN 8 THEN 'Ago' WHEN 9 THEN 'Sep'
            WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' ELSE 'Dic'
        END,
        0,
        0
    FROM N;

    BEGIN TRY
        UPDATE M
           SET TOTAL=
           (
               SELECT COUNT(*)
               FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
               WHERE G.FECHA_CREACION>=M.MES_INICIO
                 AND G.FECHA_CREACION<DATEADD(MONTH,1,M.MES_INICIO)
           )
        FROM #GEST_MES M;
    END TRY
    BEGIN CATCH
        UPDATE #GEST_MES SET TOTAL=0;
    END CATCH;

    SELECT @MAX_GEST_MES=ISNULL(MAX(TOTAL),0) FROM #GEST_MES;

    UPDATE #GEST_MES
       SET PCT_ALTURA=
           CASE
               WHEN @MAX_GEST_MES<=0 THEN 6
               WHEN TOTAL<=0 THEN 6
               ELSE CONVERT(INT,ROUND((TOTAL*100.0)/@MAX_GEST_MES,0))
           END;

    SELECT @HTML_BARRAS=ISNULL((
        SELECT
            '<div class="vct-dashboard-bar-item">'+
                '<span class="vct-dashboard-bar-value">'+CONVERT(VARCHAR(20),TOTAL)+'</span>'+
                '<div class="vct-dashboard-bar-track">'+
                    '<span class="vct-dashboard-bar" style="--vct-dashboard-bar-height:'+CONVERT(VARCHAR(10),PCT_ALTURA)+'%;"></span>'+
                '</div>'+
                '<span class="vct-dashboard-bar-label">'+MES_LABEL+'</span>'+
            '</div>'
        FROM #GEST_MES
        ORDER BY ORDEN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* ============================================================
       7. HTML FINAL
       ============================================================ */
    SET @HTML=
    '<div class="vct-page vct-page-main vct-dashboard vct-dashboard-option-b" data-vct-page data-vct-dashboard="option-b" data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'" data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">'+

        '<section class="vct-dashboard-kpi-grid">'+

            '<article class="vct-dashboard-kpi is-blue">'+
                '<span class="vct-dashboard-kpi-icon" data-vct-icon="users"></span>'+
                '<div class="vct-dashboard-kpi-copy">'+
                    '<span class="vct-dashboard-kpi-label">Clientes activos</span>'+
                    '<strong class="vct-dashboard-kpi-value">'+CONVERT(VARCHAR(30),@CLIENTES_ACTIVOS)+'</strong>'+
                    '<span class="vct-dashboard-kpi-help">cartera vigente</span>'+
                '</div>'+
            '</article>'+

            '<article class="vct-dashboard-kpi is-purple">'+
                '<span class="vct-dashboard-kpi-icon" data-vct-icon="folder"></span>'+
                '<div class="vct-dashboard-kpi-copy">'+
                    '<span class="vct-dashboard-kpi-label">Proyectos vigentes</span>'+
                    '<strong class="vct-dashboard-kpi-value">'+CONVERT(VARCHAR(30),@PROYECTOS_VIGENTES)+'</strong>'+
                    '<span class="vct-dashboard-kpi-help">en curso o confirmados</span>'+
                '</div>'+
            '</article>'+

            '<article class="vct-dashboard-kpi is-green">'+
                '<span class="vct-dashboard-kpi-icon" data-vct-icon="list-checks"></span>'+
                '<div class="vct-dashboard-kpi-copy">'+
                    '<span class="vct-dashboard-kpi-label">Gestiones activas</span>'+
                    '<strong class="vct-dashboard-kpi-value">'+CONVERT(VARCHAR(30),@GESTIONES_ACTIVAS)+'</strong>'+
                    '<span class="vct-dashboard-kpi-help">gestiones abiertas</span>'+
                '</div>'+
            '</article>'+

            '<article class="vct-dashboard-kpi is-orange">'+
                '<span class="vct-dashboard-kpi-icon" data-vct-icon="calendar-days"></span>'+
                '<div class="vct-dashboard-kpi-copy">'+
                    '<span class="vct-dashboard-kpi-label">Gestiones este mes</span>'+
                    '<strong class="vct-dashboard-kpi-value">'+CONVERT(VARCHAR(30),@GESTIONES_MES)+'</strong>'+
                    '<span class="vct-dashboard-kpi-help">registradas durante el mes actual</span>'+
                '</div>'+
            '</article>'+

        '</section>'+

        '<section class="vct-dashboard-grid vct-dashboard-grid-main">'+

            '<article class="vct-dashboard-card">'+
                '<header class="vct-dashboard-card-header">'+
                    '<div class="vct-dashboard-card-heading">'+
                        '<span class="vct-dashboard-card-icon" data-vct-icon="list-checks"></span>'+
                        '<h2 class="vct-dashboard-card-title">Actividad reciente</h2>'+
                    '</div>'+
                    '<span class="vct-dashboard-card-action">Ver todo &rarr;</span>'+
                '</header>'+
                '<div class="vct-dashboard-card-body vct-dashboard-list">'+
                    @HTML_ACTIVIDAD+
                '</div>'+
            '</article>'+

            '<article class="vct-dashboard-card">'+
                '<header class="vct-dashboard-card-header">'+
                    '<div class="vct-dashboard-card-heading">'+
                        '<span class="vct-dashboard-card-icon" data-vct-icon="calendar-days"></span>'+
                        '<h2 class="vct-dashboard-card-title">Pr&oacute;ximas gestiones</h2>'+
                    '</div>'+
                    '<span class="vct-dashboard-card-action">Ver todo &rarr;</span>'+
                '</header>'+
                '<div class="vct-dashboard-card-body vct-dashboard-list">'+
                    @HTML_PROXIMAS+
                '</div>'+
            '</article>'+

        '</section>'+

        '<section class="vct-dashboard-grid vct-dashboard-grid-charts">'+

            '<article class="vct-dashboard-card">'+
                '<header class="vct-dashboard-card-header">'+
                    '<div class="vct-dashboard-card-heading">'+
                        '<span class="vct-dashboard-card-icon" data-vct-icon="folder"></span>'+
                        '<h2 class="vct-dashboard-card-title">Proyectos por estado</h2>'+
                    '</div>'+
                    '<span class="vct-dashboard-card-action">Ver detalle &rarr;</span>'+
                '</header>'+
                '<div class="vct-dashboard-card-body">'+
                    '<div class="vct-dashboard-donut-layout">'+
                        '<div class="vct-dashboard-donut" style="'+@DONUT_STYLE+'">'+
                            '<div class="vct-dashboard-donut-hole">'+
                                '<strong>'+CONVERT(VARCHAR(30),@PROY_TOTAL)+'</strong>'+
                                '<span>Proyectos</span>'+
                            '</div>'+
                        '</div>'+
                        '<div class="vct-dashboard-legend">'+
                            '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-blue"></span><span>En curso</span><strong>'+CONVERT(VARCHAR(30),@PROY_ACTIVOS)+'</strong></div>'+
                            '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-purple"></span><span>Confirmados</span><strong>'+CONVERT(VARCHAR(30),@PROY_CONFIRMADOS)+'</strong></div>'+
                            '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-green"></span><span>Terminados</span><strong>'+CONVERT(VARCHAR(30),@PROY_TERMINADOS)+'</strong></div>'+
                            '<div class="vct-dashboard-legend-row"><span class="vct-dashboard-legend-dot is-orange"></span><span>Otros</span><strong>'+CONVERT(VARCHAR(30),@PROY_OTROS)+'</strong></div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
            '</article>'+

            '<article class="vct-dashboard-card">'+
                '<header class="vct-dashboard-card-header">'+
                    '<div class="vct-dashboard-card-heading">'+
                        '<span class="vct-dashboard-card-icon" data-vct-icon="calendar-days"></span>'+
                        '<h2 class="vct-dashboard-card-title">Gestiones por mes</h2>'+
                    '</div>'+
                    '<span class="vct-dashboard-card-note">&Uacute;ltimos 6 meses</span>'+
                '</header>'+
                '<div class="vct-dashboard-card-body">'+
                    '<div class="vct-dashboard-bars">'+@HTML_BARRAS+'</div>'+
                '</div>'+
            '</article>'+

        '</section>'+

    '</div>';

    SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+ISNULL(@HTML,'');
END
GO
