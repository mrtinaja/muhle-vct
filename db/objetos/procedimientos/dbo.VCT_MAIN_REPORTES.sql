 
CREATE    PROCEDURE dbo.VCT_MAIN_REPORTES
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
    SET @OUTPARAM2='';
    SET @OUTPARAM3='';
 
    DECLARE
        @HTML_SHELL      VARCHAR(MAX)='',
        @RESULTADO_SHELL VARCHAR(20)='';
 
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Reportes',
             @SUBTITLE           = 'Reportes y seguimientos del sistema.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL='';
    END CATCH;
 
    /* ============================================================
       1. ESTADO (grupo activo + filtros) - VCT_BUFFER
       ------------------------------------------------------------
       Slots de VCT_BUFFER reservados por reporte (misma fila, cada
       grupo usa los suyos para no pisarse):
         TEXTO01/02 = Indice Ocupacion (Mes/Ano)
         TEXTO03/04 = Fecha Desde/Hasta compartida (Parte de Actividades,
                      Seg. Consultoria, Seg. Auditoria, Seg. Capacitacion,
                      Seg. Hoteles -- igual que TMT_SV_05 en el hub legacy)
         TEXTO05    = Calificacion Consultores - Aptitud (ID_APTITUD)
         TEXTO06    = Calificacion Consultores - Tipo Servicio (ID_TIPO_SERVICIO)
         TEXTO07    = Calificacion Consultores - Calificacion
         TEXTO08    = Rentabilidad - Cliente (ID_CLIENTE)
         TEXTO09    = Rentabilidad - Periodo
         TEXTO10    = Rentabilidad - Estado (ESTADO_PROYECTO_TOTAL)
       ============================================================ */
    DECLARE
        @ACTIVE_GROUP VARCHAR(50)='',
        @VMES         VARCHAR(10)='',
        @VANO         VARCHAR(10)='',
        @VPA_FDESDE   VARCHAR(10)='',
        @VPA_FHASTA   VARCHAR(10)='',
        @VCC_APTITUD  VARCHAR(20)='',
        @VCC_TIPOSERV VARCHAR(20)='',
        @VCC_CALIF    VARCHAR(50)='',
        @VRENTA_CLIENTE VARCHAR(20)='',
        @VRENTA_PERIODO VARCHAR(20)='',
        @VRENTA_ESTADO  VARCHAR(50)='',
        @VFLAG_PANEL_ONLY VARCHAR(10)='';
 
    SELECT
        @ACTIVE_GROUP = ISNULL(NULLIF(LTRIM(RTRIM(ACTIVE_TAB)),''),''),
        @VMES         = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO01)),''),''),
        @VANO         = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO02)),''),''),
        @VPA_FDESDE   = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO03)),''),''),
        @VPA_FHASTA   = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO04)),''),''),
        @VCC_APTITUD  = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO05)),''),''),
        @VCC_TIPOSERV = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO06)),''),''),
        @VCC_CALIF    = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO07)),''),''),
        @VRENTA_CLIENTE = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO08)),''),''),
        @VRENTA_PERIODO = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO09)),''),''),
        @VRENTA_ESTADO  = ISNULL(NULLIF(LTRIM(RTRIM(TEXTO10)),''),''),
        @VFLAG_PANEL_ONLY = ISNULL(CONVERT(VARCHAR(10),FLAG01),'0')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    /* PERF: FLAG01 (libre, no usado por ningun otro campo de este SP) se
       reutiliza como señal de un solo uso: "este pedido puntual es un
       refresco liviano de UN panel (via fetch propio de vct-reportes.js),
       no una entrada de cero a Reportes". Solo lo puede mandar en 1 ese
       fetch propio -- cualquier otro camino (incluida una entrada nueva
       al modulo) nunca lo manda, asi que llega NULL/'0'. Mas abajo, el
       UPDATE de buffer lo vuelve a dejar en '0' SIEMPRE (sin importar con
       que valor entro), asi que no puede quedar pegado en 1 para la
       proxima vez -- un uso, se consume y se resetea en la misma
       ejecucion. Si vale 1, se calcula UNICAMENTE el panel de
       @ACTIVE_GROUP: los otros 9 quedan con HTML vacio en la respuesta,
       que el cliente ignora (ver vct-reportes.js, patchActivePanelOnly) y
       no toca el DOM que ya tiene de la carga de pagina completa. */
    DECLARE @CALC_TODOS_LOS_PANELES BIT = CASE WHEN @VFLAG_PANEL_ONLY='1' THEN 0 ELSE 1 END;
 
    /* PERF - ARRANQUE LIVIANO: cada ENTRADA de cero a Reportes (menu, F5, volver desde otra
       pantalla; FLAG01<>'1') arranca con TODOS los filtros en el dia actual:
         - Fecha Desde = Fecha Hasta = hoy (Parte de Actividades, Seguimientos, Hoteles,
           Pasajes, Remis);
         - Indice de Ocupacion = mes y año actuales (antes: "Todos" = el año completo);
         - Calificacion y Rentabilidad sin filtros especificos.
       Se ignoran los valores que hubieran quedado en VCT_BUFFER de una busqueda ancha
       anterior (ej. Desde 2024), que hacian lenta o directamente colgaban la entrada.
       Ampliar el rango es una decision del usuario: lo hace con la busqueda liviana
       (FLAG01='1', un solo panel), que SI respeta lo que mando el formulario. El ultimo
       panel activo (ACTIVE_TAB) se conserva. */
    IF @CALC_TODOS_LOS_PANELES=1
    BEGIN
        SET @VMES         = CONVERT(VARCHAR(2),DATEPART(MM,GETDATE()));
        SET @VANO         = CONVERT(VARCHAR(4),DATEPART(YYYY,GETDATE()));
        SET @VPA_FDESDE   = CONVERT(VARCHAR(10),GETDATE(),120);
        SET @VPA_FHASTA   = CONVERT(VARCHAR(10),GETDATE(),120);
        SET @VCC_APTITUD  = '';
        SET @VCC_TIPOSERV = '';
        SET @VCC_CALIF    = '';
        SET @VRENTA_CLIENTE = '';
        SET @VRENTA_PERIODO = '';
        SET @VRENTA_ESTADO  = '';
    END;
 
    IF @ACTIVE_GROUP='' SET @ACTIVE_GROUP='parte-actividades';
    IF @VMES=''         SET @VMES='TODOS';
    IF @VANO=''          SET @VANO=CONVERT(VARCHAR(10),DATEPART(YYYY,GETDATE()));
 
    /* Fecha Desde/Hasta de respaldo (solo si llegaran vacias en una busqueda liviana): hoy. */
    DECLARE @VMES_ACTUAL_DESDE DATETIME, @VMES_ACTUAL_HASTA DATETIME;
    SELECT @VMES_ACTUAL_DESDE=PrimerDiaMes, @VMES_ACTUAL_HASTA=UltimoDiaMes
    FROM dbo.Calendar WITH(NOLOCK)
    WHERE Fecha=CONVERT(VARCHAR,GETDATE(),113);
 
    IF @VPA_FDESDE='' SET @VPA_FDESDE=CONVERT(VARCHAR(10),GETDATE(),120);
    IF @VPA_FHASTA='' SET @VPA_FHASTA=CONVERT(VARCHAR(10),GETDATE(),120);
 
    /* PERF: hoisteado afuera de "3. PARTE DE ACTIVIDADES" (donde vivia
       originalmente) porque Consultoria/Auditoria/Capacitacion/Hoteles/
       Pasajes/Remis tambien lo usan y, con el nuevo gate por panel activo
       (@CALC_TODOS_LOS_PANELES), esas secciones pueden ejecutar sin que
       la de Parte de Actividades lo haga -- tiene que calcularse siempre,
       sin importar que panel este activo. */
    DECLARE
        @VPA_FDESDE_DATE DATETIME = CASE WHEN ISDATE(@VPA_FDESDE)=1 THEN CONVERT(DATETIME,@VPA_FDESDE,120) ELSE NULL END,
        @VPA_FHASTA_DATE DATETIME = CASE WHEN ISDATE(@VPA_FHASTA)=1 THEN CONVERT(DATETIME,@VPA_FHASTA,120) ELSE NULL END;
 
    /* Persistimos defaults la primera vez que se entra (sin filtro elegido aun). */
    UPDATE dbo.VCT_BUFFER
       SET ACTIVE_TAB = @ACTIVE_GROUP,
           TEXTO01    = @VMES,
           TEXTO02    = @VANO,
           TEXTO03    = @VPA_FDESDE,
           TEXTO04    = @VPA_FHASTA,
           TEXTO05    = @VCC_APTITUD,
           TEXTO06    = @VCC_TIPOSERV,
           TEXTO07    = @VCC_CALIF,
           TEXTO08    = @VRENTA_CLIENTE,
           TEXTO09    = @VRENTA_PERIODO,
           TEXTO10    = @VRENTA_ESTADO,
           FLAG01     = '0' /* PERF: se consume y se resetea siempre, ver nota arriba */
     WHERE PAR_KEY=@IPKEYJOB;
 
    DECLARE @PUEDE_VER_RENTABILIDAD BIT =
        dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'RENTABILIDAD.VIEW');
 
    /* ============================================================
       2. INDICE OCUPACION CONSULTORES - CALCULO BASE
       ------------------------------------------------------------
       Misma logica que SV_05_GRD_INDICE_OCUPACION / SV_05_INDICE_OCUPACION,
       reescrita en un solo CTE para no repetir 6 veces cada CASE WHEN.
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='indice-ocupacion'
    BEGIN
    DECLARE
        @VFECHA_DESDE   DATETIME = @VMES_ACTUAL_DESDE,
        @VFECHA_HASTA   DATETIME = @VMES_ACTUAL_HASTA,
        @VFDESDE_ANUAL  DATETIME,
        @VFHASTA_ANUAL  DATETIME,
        @VMES_NUM       INT;
 
    /* @VMES puede valer 'TODOS' (no numerico). Nunca pasar @VMES directo a una
       funcion/CONVERT que espere INT: aunque esa rama del CASE/AND no "deberia"
       evaluarse cuando @VMES='TODOS', SQL Server no garantiza cortocircuito en
       CASE/AND, y el intento de convertir 'TODOS' a INT tira el error de
       conversion igual. Se resuelve calculando una vez un INT seguro (NULL
       cuando es 'TODOS', ya que en ese caso se usan las funciones _ANUAL que
       no reciben mes). */
    SET @VMES_NUM = CASE WHEN ISNUMERIC(@VMES)=1 THEN CONVERT(INT,@VMES) ELSE NULL END;
 
    SELECT @VFDESDE_ANUAL=MIN(Fecha), @VFHASTA_ANUAL=MAX(Fecha)
    FROM dbo.Calendar WITH(NOLOCK)
    WHERE Ano=@VANO;
 
    IF OBJECT_ID('tempdb..#OCUP_BASE') IS NOT NULL DROP TABLE #OCUP_BASE;
    CREATE TABLE #OCUP_BASE
    (
        ID_EMPLEADO INT,
        NOMBRE      VARCHAR(640),
        ACTIVO      BIT,
        DIAS_DISP   DECIMAL(18,2),
        DIAS_COMP   DECIMAL(18,2),
        DIAS_OCUP   DECIMAL(18,2)
    );
 
    INSERT INTO #OCUP_BASE (ID_EMPLEADO,NOMBRE,ACTIVO,DIAS_DISP,DIAS_COMP,DIAS_OCUP)
    SELECT
        EMP.ID_EMPLEADO,
        EMP.APELLIDO_EMPLEADO+', '+EMP.NOMBRE_EMPLEADO,
        CASE WHEN EMP.STATUS_EMP='1' THEN 1 ELSE 0 END,
        CASE WHEN @VMES='TODOS' THEN CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_DISP_ANUAL(EMP.ID_EMPLEADO,@VANO))
             ELSE CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_DISPONIBLES(EMP.ID_EMPLEADO,@VMES_NUM,@VANO)) END,
        CASE WHEN @VMES='TODOS' THEN CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_COMP_ANUAL(EMP.ID_EMPLEADO,@VANO))
             ELSE CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_COMPROMISO(EMP.ID_EMPLEADO,@VMES_NUM,@VANO)) END,
        CASE WHEN @VMES='TODOS' THEN CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_OCUP_ANUAL(EMP.ID_EMPLEADO,@VANO))
             ELSE CONVERT(DECIMAL(18,2),dbo.FN_GET_DIAS_OCUPADOS(EMP.ID_EMPLEADO,@VMES_NUM,@VANO)) END
    FROM dbo.LK_EMPLEADOS EMP WITH(NOLOCK)
    WHERE EMP.PERFIL_EMP='CONSULTOR'
      AND ISNULL(EMP.EVENTUAL,'NO')='NO'
      AND
      (
          EMP.STATUS_EMP='1'
          OR
          (
              CASE WHEN @VMES='TODOS' THEN dbo.FN_GET_DIAS_COMP_ANUAL(EMP.ID_EMPLEADO,@VANO)
                   ELSE dbo.FN_GET_DIAS_COMPROMISO(EMP.ID_EMPLEADO,@VMES_NUM,@VANO) END > 0
          )
      )
      AND
      (
          (@VMES='TODOS' AND CONVERT(VARCHAR,DATEPART(YYYY,EMP.FECHA_ALTA)) <= CONVERT(VARCHAR,CONVERT(INT,@VANO)))
          OR
          (@VMES<>'TODOS' AND
           CONVERT(VARCHAR,DATEPART(YYYY,EMP.FECHA_ALTA))+FORMAT(DATEPART(MM,EMP.FECHA_ALTA),'00')
             <= CONVERT(VARCHAR,CONVERT(INT,@VANO))+FORMAT(@VMES_NUM,'00'))
      );
 
    DECLARE @CNT_OCUP INT = (SELECT COUNT(*) FROM #OCUP_BASE);
 
    /* KPIs resumen (misma formula que el shell legacy SV_05_INDICE_OCUPACION,
       preservada tal cual -- notar que "Prom. Indice Disp." toma como base
       DIAS_COMP, no DIAS_DISP, igual que el original). */
    DECLARE
        @VTOTAL_DIAS_OCUP INT,
        @VPROM_IND_DISP   DECIMAL(10,2),
        @VPROM_IND_COMP   DECIMAL(10,2),
        @VPROM_OCUP       DECIMAL(10,2);
 
    SELECT
        @VTOTAL_DIAS_OCUP = SUM(DIAS_OCUP),
        @VPROM_IND_DISP =
            CASE WHEN @VMES='TODOS'
                 THEN AVG(CAST(DIAS_COMP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFDESDE_ANUAL,@VFHASTA_ANUAL),0) AS DECIMAL(10,2)))
                 ELSE AVG(CAST(DIAS_COMP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFECHA_DESDE,@VFECHA_HASTA),0) AS DECIMAL(10,2)))
            END,
        @VPROM_IND_COMP = AVG(CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_COMP*100.0/DIAS_DISP AS DECIMAL(10,2)) END),
        @VPROM_OCUP     = AVG(CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_OCUP*100.0/DIAS_DISP AS DECIMAL(10,2)) END)
    FROM #OCUP_BASE;
 
    SET @VTOTAL_DIAS_OCUP = ISNULL(@VTOTAL_DIAS_OCUP,0);
    SET @VPROM_IND_DISP   = ISNULL(@VPROM_IND_DISP,0);
    SET @VPROM_IND_COMP   = ISNULL(@VPROM_IND_COMP,0);
    SET @VPROM_OCUP       = ISNULL(@VPROM_OCUP,0);
 
    DECLARE @VPCT_OCUP     INT = CASE WHEN @VPROM_OCUP>100 THEN 100 WHEN @VPROM_OCUP<0 THEN 0 ELSE CONVERT(INT,@VPROM_OCUP) END;
    DECLARE @VPCT_IND_DISP INT = CASE WHEN @VPROM_IND_DISP>100 THEN 100 WHEN @VPROM_IND_DISP<0 THEN 0 ELSE CONVERT(INT,@VPROM_IND_DISP) END;
    DECLARE @VPCT_IND_COMP INT = CASE WHEN @VPROM_IND_COMP>100 THEN 100 WHEN @VPROM_IND_COMP<0 THEN 0 ELSE CONVERT(INT,@VPROM_IND_COMP) END;
 
    /* Barras: Top 5 consultores por dias ocupados en el periodo. */
    DECLARE @VMAX_OCUP_DIAS DECIMAL(18,2) = (SELECT MAX(DIAS_OCUP) FROM #OCUP_BASE);
    IF @VMAX_OCUP_DIAS IS NULL OR @VMAX_OCUP_DIAS=0 SET @VMAX_OCUP_DIAS=1;
    DECLARE @HTML_OCUP_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),DIAS_OCUP)+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,DIAS_OCUP*100.0/@VMAX_OCUP_DIAS))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #OCUP_BASE
        ORDER BY DIAS_OCUP DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_OCUP_BARS=''
        SET @HTML_OCUP_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* Gantt: dias ocupados vs. dias disponibles por consultor (no hay
       fecha inicio/fin por fila en este reporte, asi que la barra
       representa la proporcion ocupada dentro de los dias disponibles
       del periodo, no un rango de calendario). */
    DECLARE @HTML_OCUP_GANTT VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(20),DIAS_OCUP)+' / '+CONVERT(VARCHAR(20),DIAS_DISP)+' días</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-violet" style="left:0%;width:'+CONVERT(VARCHAR(10),CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 WHEN CONVERT(INT,DIAS_OCUP*100.0/DIAS_DISP)>100 THEN 100 ELSE CONVERT(INT,DIAS_OCUP*100.0/DIAS_DISP) END)+'%;"></div></div></div>'
        FROM #OCUP_BASE
        ORDER BY DIAS_OCUP DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_OCUP_GANTT=''
        SET @HTML_OCUP_GANTT='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* HTML de las filas de la grilla (Consultor / Dias Disp. / Dias Comp. /
       Dias Ocup. / Indice Disp. / Indice Comp. / % Ocupacion). */
    DECLARE @HTML_OCUP_ROWS VARCHAR(MAX)='';
 
    SELECT @HTML_OCUP_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Consultor">'+
                    CASE WHEN ACTIVO=1
                         THEN '<strong>'+REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong>'
                         ELSE '<strong style="color:#B91C1C;">'+REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong>'
                    END+
                '</td>'+
                '<td class="vct-text-center" data-label="Días Disp." data-vct-sort-value="'+CONVERT(VARCHAR(20),DIAS_DISP)+'">'+CONVERT(VARCHAR(20),DIAS_DISP)+'</td>'+
                '<td class="vct-text-center" data-label="Días Comp." data-vct-sort-value="'+CONVERT(VARCHAR(20),DIAS_COMP)+'">'+CONVERT(VARCHAR(20),DIAS_COMP)+'</td>'+
                '<td class="vct-text-center" data-label="Días Ocup." data-vct-sort-value="'+CONVERT(VARCHAR(20),DIAS_OCUP)+'">'+CONVERT(VARCHAR(20),DIAS_OCUP)+'</td>'+
                '<td class="vct-text-center" data-label="Índice Disp." data-vct-sort-value="'+
                    CONVERT(VARCHAR(20),
                        CASE WHEN @VMES='TODOS'
                             THEN CAST(DIAS_DISP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFDESDE_ANUAL,@VFHASTA_ANUAL),0) AS DECIMAL(10,2))
                             ELSE CAST(DIAS_DISP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFECHA_DESDE,@VFECHA_HASTA),0) AS DECIMAL(10,2))
                        END)+'">'+
                    CONVERT(VARCHAR(20),
                        CASE WHEN @VMES='TODOS'
                             THEN CAST(DIAS_DISP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFDESDE_ANUAL,@VFHASTA_ANUAL),0) AS DECIMAL(10,2))
                             ELSE CAST(DIAS_DISP*100.0/NULLIF(dbo.FN_GET_DIAS_HABILES(@VFECHA_DESDE,@VFECHA_HASTA),0) AS DECIMAL(10,2))
                        END)+'%</td>'+
                '<td class="vct-text-center" data-label="Índice Comp." data-vct-sort-value="'+
                    CONVERT(VARCHAR(20),CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_COMP*100.0/DIAS_DISP AS DECIMAL(10,2)) END)+'">'+
                    CONVERT(VARCHAR(20),CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_COMP*100.0/DIAS_DISP AS DECIMAL(10,2)) END)+'%</td>'+
                '<td class="vct-text-center" data-label="% Ocupación" data-vct-sort-value="'+
                    CONVERT(VARCHAR(20),CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_OCUP*100.0/DIAS_DISP AS DECIMAL(10,2)) END)+'">'+
                    CONVERT(VARCHAR(20),CASE WHEN ISNULL(DIAS_DISP,0)=0 THEN 0 ELSE CAST(DIAS_OCUP*100.0/DIAS_DISP AS DECIMAL(10,2)) END)+'%</td>'+
            '</tr>'
        FROM #OCUP_BASE
        ORDER BY NOMBRE
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_OCUP_ROWS=''
        SET @HTML_OCUP_ROWS='<tr><td colspan="7" class="vct-text-center">Sin consultores para el período seleccionado.</td></tr>';
    END
 
    /* Opciones Mes (fijas, 1-12) y Año (dinamico, desde Calendar). */
    DECLARE @HTML_MESES VARCHAR(MAX)=
        '<option value="TODOS"'+CASE WHEN @VMES='TODOS' THEN ' selected' ELSE '' END+'>Todos</option>'+
        '<option value="1"'+ CASE WHEN @VMES='1'  THEN ' selected' ELSE '' END+'>Enero</option>'+
        '<option value="2"'+ CASE WHEN @VMES='2'  THEN ' selected' ELSE '' END+'>Febrero</option>'+
        '<option value="3"'+ CASE WHEN @VMES='3'  THEN ' selected' ELSE '' END+'>Marzo</option>'+
        '<option value="4"'+ CASE WHEN @VMES='4'  THEN ' selected' ELSE '' END+'>Abril</option>'+
        '<option value="5"'+ CASE WHEN @VMES='5'  THEN ' selected' ELSE '' END+'>Mayo</option>'+
        '<option value="6"'+ CASE WHEN @VMES='6'  THEN ' selected' ELSE '' END+'>Junio</option>'+
        '<option value="7"'+ CASE WHEN @VMES='7'  THEN ' selected' ELSE '' END+'>Julio</option>'+
        '<option value="8"'+ CASE WHEN @VMES='8'  THEN ' selected' ELSE '' END+'>Agosto</option>'+
        '<option value="9"'+ CASE WHEN @VMES='9'  THEN ' selected' ELSE '' END+'>Septiembre</option>'+
        '<option value="10"'+CASE WHEN @VMES='10' THEN ' selected' ELSE '' END+'>Octubre</option>'+
        '<option value="11"'+CASE WHEN @VMES='11' THEN ' selected' ELSE '' END+'>Noviembre</option>'+
        '<option value="12"'+CASE WHEN @VMES='12' THEN ' selected' ELSE '' END+'>Diciembre</option>';
 
    DECLARE @HTML_ANOS VARCHAR(MAX)='';
    SELECT @HTML_ANOS = ISNULL((
        SELECT '<option value="'+CONVERT(VARCHAR(10),Ano)+'"'+
               CASE WHEN CONVERT(VARCHAR(10),Ano)=@VANO THEN ' selected' ELSE '' END+
               '>'+CONVERT(VARCHAR(10),Ano)+'</option>'
        FROM (SELECT DISTINCT Ano FROM dbo.Calendar WITH(NOLOCK)) X
        ORDER BY Ano
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* ============================================================
       3. PARTE DE ACTIVIDADES - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_PARTE_ACTIVIDADES, migrando el
       filtro de TMT_SV_05 a VCT_BUFFER (TEXTO03/04) y armando la grilla
       como tabla HTML moderna (antes: recordset con alias-HTML crudo).
       ============================================================ */
    /* @VPA_FDESDE_DATE/@VPA_FHASTA_DATE ya se calcularon mas arriba
       (hoisteados, los usan tambien otras 6 secciones). */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='parte-actividades'
    BEGIN
    IF OBJECT_ID('tempdb..#PARTE_BASE') IS NOT NULL DROP TABLE #PARTE_BASE;
    CREATE TABLE #PARTE_BASE
    (
        FECHA         DATETIME,
        CLIENTE       VARCHAR(600),
        DESCRIPCION   VARCHAR(MAX),
        SERVICIO      VARCHAR(400),
        CONSULTOR     VARCHAR(640),
        HORAS         DECIMAL(10,2),
        MINUTA        VARCHAR(50),
        OBSERVACIONES VARCHAR(MAX),
        OBS_CALIF     VARCHAR(MAX),
        OBS_HOJA_RUTA VARCHAR(MAX)
    );
 
    /* PERF: dbo.FN_GET_DOC_VISITA(@clave,@tipo) hace
         SELECT ... FROM LK_PROYECTO_DOCUM
          WHERE CASE WHEN @tipo='MV' THEN ID_AGENDA ELSE PROYECTO_SERV_ID END=@clave AND TIPO=@tipo
       -- el CASE dentro del WHERE no es sargable: RECORRE TODA LK_PROYECTO_DOCUM EN CADA
       llamada (~4 ms), y la columna Minuta la llamaba hasta 2 veces por fila (una para
       ver si estaba vacia y otra para el valor): con ~9000 filas (rango de ~3 años) eran
       ~18000 recorridos completos y el SP superaba los 30 s (Execution Timeout).
       Se lee la tabla UNA sola vez, agrupada por (tipo, clave), y se une por clave.
       Si habia varios documentos para la misma clave, la funcion devolvia el de la ultima
       fila leida (orden no garantizado); aca se toma el mas reciente (MAX de la fecha). */
    IF OBJECT_ID('tempdb..#DOCV') IS NOT NULL DROP TABLE #DOCV;
    CREATE TABLE #DOCV (TIPO VARCHAR(10) NOT NULL, CLAVE INT NOT NULL, FECHA VARCHAR(50) NOT NULL, PRIMARY KEY (TIPO,CLAVE));
    INSERT INTO #DOCV (TIPO,CLAVE,FECHA)
    SELECT D.TIPO, D.CLAVE, ISNULL(CONVERT(VARCHAR(50),MAX(D.FECHA_DOCUM),103),'')
    FROM (
        SELECT 'MV' AS TIPO, CONVERT(INT,ID_AGENDA) AS CLAVE, FECHA_DOCUM
        FROM dbo.LK_PROYECTO_DOCUM WITH(NOLOCK) WHERE TIPO='MV'
        UNION ALL
        SELECT TIPO, CONVERT(INT,PROYECTO_SERV_ID), FECHA_DOCUM
        FROM dbo.LK_PROYECTO_DOCUM WITH(NOLOCK) WHERE TIPO IN ('IA','IC')
    ) D
    WHERE D.CLAVE IS NOT NULL
    GROUP BY D.TIPO, D.CLAVE;
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #PARTE_BASE (FECHA,CLIENTE,DESCRIPCION,SERVICIO,CONSULTOR,HORAS,MINUTA,OBSERVACIONES,OBS_CALIF,OBS_HOJA_RUTA)
    SELECT
        AE.FECHA,
        dbo.FN_GET_AGENDA_CLIENTE(AE.HOLIDAYTEXT),
        dbo.FN_GET_AGENDA_PROYECTO(AE.HOLIDAYTEXT)+' - '+ISNULL(PS.NOMBRE,''),
        X.SERVICIO,
        EMP.APELLIDO_EMPLEADO+', '+EMP.NOMBRE_EMPLEADO,
        AE.HORAS,
        CASE
            WHEN X.SERVICIO='Consultoria' THEN
                CASE WHEN ISNULL(DV.FECHA,'')='' THEN 'No' ELSE DV.FECHA END
            WHEN X.SERVICIO='Auditoria' THEN
                CASE WHEN ISNULL(DV.FECHA,'')='' THEN 'Pendiente' ELSE DV.FECHA END
            WHEN X.SERVICIO='Capacitacion' THEN
                CASE WHEN ISNULL(DV.FECHA,'')='' THEN 'Pendiente' ELSE DV.FECHA END
        END,
        A.OBSERVADOR,
        A.OBSERV_CALIF,
        DOC.OBSERVACIONES
    FROM dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK)
        LEFT JOIN dbo.LK_EMPLEADOS EMP ON AE.ID_EMPLEADO=EMP.ID_EMPLEADO
        INNER JOIN dbo.LK_AGENDA A ON AE.HOLIDAYTEXT=A.ID_AGENDA
        INNER JOIN dbo.LK_PROYECTO PROY ON PROY.ID_PROYECTO=A.ID_PROYECTO
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO=A.PROYECTO_SERV_ID
        LEFT JOIN dbo.LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA=A.ID_AGENDA AND DOC.ID_DOCUMENTACION IN (5,6,7)
        CROSS APPLY (SELECT dbo.FN_GET_AGENDA_SERVICIO(AE.HOLIDAYTEXT) AS SERVICIO) X
        LEFT JOIN #DOCV DV
               ON DV.TIPO  = CASE X.SERVICIO WHEN 'Consultoria' THEN 'MV' WHEN 'Auditoria' THEN 'IA' WHEN 'Capacitacion' THEN 'IC' END
              AND DV.CLAVE = CASE X.SERVICIO WHEN 'Consultoria' THEN CONVERT(INT,AE.HOLIDAYTEXT) ELSE A.PROYECTO_SERV_ID END
    WHERE AE.FECHA>=@VPA_FDESDE_DATE
      AND AE.FECHA<=@VPA_FHASTA_DATE
      AND AE.TIPO='A'
      AND dbo.FN_GET_AGENDA_ESTADO(AE.HOLIDAYTEXT)='C';
 
    DECLARE @CNT_PARTE INT = (SELECT COUNT(*) FROM #PARTE_BASE);
 
    DECLARE @VPARTE_CONS INT, @VPARTE_AUDI INT, @VPARTE_CAPA INT;
    SELECT
        @VPARTE_CONS = SUM(CASE WHEN SERVICIO='Consultoria' THEN 1 ELSE 0 END),
        @VPARTE_AUDI = SUM(CASE WHEN SERVICIO='Auditoria' THEN 1 ELSE 0 END),
        @VPARTE_CAPA = SUM(CASE WHEN SERVICIO='Capacitacion' THEN 1 ELSE 0 END)
    FROM #PARTE_BASE;
    SET @VPARTE_CONS = ISNULL(@VPARTE_CONS,0);
    SET @VPARTE_AUDI = ISNULL(@VPARTE_AUDI,0);
    SET @VPARTE_CAPA = ISNULL(@VPARTE_CAPA,0);
    DECLARE @VPARTE_TOTAL INT = @VPARTE_CONS+@VPARTE_AUDI+@VPARTE_CAPA;
    IF @VPARTE_TOTAL=0 SET @VPARTE_TOTAL=1;
    DECLARE @VPARTE_PCT_CONS INT = CONVERT(INT,@VPARTE_CONS*100.0/@VPARTE_TOTAL);
    DECLARE @VPARTE_PCT_AUDI INT = CONVERT(INT,@VPARTE_AUDI*100.0/@VPARTE_TOTAL);
    DECLARE @VPARTE_PCT_CAPA INT = CONVERT(INT,@VPARTE_CAPA*100.0/@VPARTE_TOTAL);
 
    /* Barras: Top 5 consultores por horas cargadas en el periodo. */
    DECLARE @VMAX_PARTE_CONS_HS DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(HORAS) S FROM #PARTE_BASE GROUP BY CONSULTOR) X);
    IF @VMAX_PARTE_CONS_HS IS NULL OR @VMAX_PARTE_CONS_HS=0 SET @VMAX_PARTE_CONS_HS=1;
    DECLARE @HTML_PARTE_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),SUM(HORAS))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(HORAS)*100.0/@VMAX_PARTE_CONS_HS))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(CONSULTOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #PARTE_BASE
        GROUP BY CONSULTOR
        ORDER BY SUM(HORAS) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PARTE_BARS=''
        SET @HTML_PARTE_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* Gantt: rango (primera - ultima actividad cargada en el periodo) por
       consultor, Top 5 por cantidad de horas -- no hay fecha inicio/fin
       por actividad (es un dato puntual), asi que el rango es el propio
       periodo de actividad de cada consultor dentro del filtro. */
    IF OBJECT_ID('tempdb..#PARTE_GANTT') IS NOT NULL DROP TABLE #PARTE_GANTT;
    SELECT TOP 5 CONSULTOR, MIN(FECHA) AS FECHA_INI, MAX(FECHA) AS FECHA_FIN, SUM(HORAS) AS HORAS,
        ROW_NUMBER() OVER (ORDER BY SUM(HORAS) DESC) AS RN
    INTO #PARTE_GANTT
    FROM #PARTE_BASE
    GROUP BY CONSULTOR
    ORDER BY SUM(HORAS) DESC;
 
    DECLARE @VPARTE_GANTT_MIN DATETIME = (SELECT MIN(FECHA_INI) FROM #PARTE_GANTT);
    DECLARE @VPARTE_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_INI),MAX(FECHA_FIN)) FROM #PARTE_GANTT);
    IF @VPARTE_GANTT_SPAN IS NULL OR @VPARTE_GANTT_SPAN=0 SET @VPARTE_GANTT_SPAN=1;
 
    DECLARE @HTML_PARTE_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(CONSULTOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_INI,103)+' - '+CONVERT(VARCHAR(10),FECHA_FIN,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-coral" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VPARTE_GANTT_MIN,FECHA_INI)*100.0/@VPARTE_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VPARTE_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VPARTE_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #PARTE_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PARTE_GANTT=''
        SET @HTML_PARTE_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @HTML_PARTE_ROWS VARCHAR(MAX)='';
    SELECT @HTML_PARTE_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CLIENTE+' '+CONSULTOR+' '+DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Fecha" data-vct-sort-value="'+CONVERT(VARCHAR(8),FECHA,112)+'">'+CONVERT(VARCHAR(10),FECHA,103)+'</td>'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Servicio">'+CASE WHEN SERVICIO IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td data-label="Consultor">'+REPLACE(REPLACE(REPLACE(ISNULL(CONSULTOR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Horas" data-vct-sort-value="'+CONVERT(VARCHAR(20),HORAS)+'">'+CONVERT(VARCHAR(20),HORAS)+'</td>'+
                '<td class="vct-text-center" data-label="Minuta/Informe">'+CASE WHEN ISNULL(MINUTA,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(MINUTA,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(MINUTA,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td data-label="Observaciones">'+REPLACE(REPLACE(REPLACE(ISNULL(OBSERVACIONES,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Obs. Calificación">'+REPLACE(REPLACE(REPLACE(ISNULL(OBS_CALIF,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Obs. Hoja Ruta">'+REPLACE(REPLACE(REPLACE(ISNULL(OBS_HOJA_RUTA,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '</tr>'
        FROM #PARTE_BASE
        ORDER BY FECHA
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_PARTE_ROWS='<tr><td colspan="10" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_PARTE_ROWS=''
        SET @HTML_PARTE_ROWS='<tr><td colspan="10" class="vct-text-center">Sin actividades para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       4. SEGUIMIENTO DE CONSULTORIA - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_CONSULTORIA (el SELECT activo;
       el bloque comentado al final del SP original es codigo muerto de una
       version anterior, no se porta). Reusa el MISMO filtro Fecha Desde/
       Hasta que Parte de Actividades (TEXTO03/04): en el hub legacy,
       TMT_SV_05 tambien era una unica fila compartida por TODOS los
       reportes de fecha, asi que esto replica ese comportamiento, no lo
       cambia.
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-consultoria'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGCONS_BASE') IS NOT NULL DROP TABLE #SEGCONS_BASE;
    CREATE TABLE #SEGCONS_BASE
    (
        CLIENTE       VARCHAR(600),
        FECHA_INICIO  DATETIME,
        FECHA_FIN     DATETIME,
        PROYECTO      VARCHAR(MAX),
        PERSONAL      VARCHAR(MAX),
        HORAS_PROY    DECIMAL(18,2),
        HORAS_EJEC    DECIMAL(18,2),
        PORC_AVANCE   DECIMAL(10,2),
        FRECUENCIA    VARCHAR(100),
        FECHA_PLAN    DATETIME,
        OBSERVACIONES VARCHAR(MAX),
        MINUTA_CIERRE VARCHAR(100)
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #SEGCONS_BASE (CLIENTE,FECHA_INICIO,FECHA_FIN,PROYECTO,PERSONAL,HORAS_PROY,HORAS_EJEC,PORC_AVANCE,FRECUENCIA,FECHA_PLAN,OBSERVACIONES,MINUTA_CIERRE)
    SELECT
        CLI.RAZON_SOCIAL,
        PS.FECHA_INICIO_REAL,
        PS.FECHA_FIN_REAL,
        '('+P.CODIGO+') - '+P.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        CASE WHEN X.CONSULTORES='1' THEN 'Sin Consultores' ELSE X.CONSULTORES END,
        ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0),
        X.HS_EJEC,
        CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)=0 THEN 0
             ELSE X.HS_EJEC*100.0/ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) END,
        UPPER(SUBSTRING(PS.FRECUENCIA_ENVIO,1,1))+LOWER(SUBSTRING(PS.FRECUENCIA_ENVIO,2,LEN(PS.FRECUENCIA_ENVIO))),
        PE.FECHA,
        DOC.OBSERVACIONES,
        CASE WHEN ISNULL(PS.CIERRE,'NO')='NO' THEN 'En Curso' ELSE CONVERT(VARCHAR,MC.FECHA,103) END
    FROM dbo.LK_PROYECTO P WITH(NOLOCK)
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO=PS.ID_PROYECTO
        INNER JOIN dbo.VCT_CLIENTES CLI ON P.ID_CLIENTE=CLI.ID
        CROSS APPLY (SELECT
            dbo.FN_GET_SERVICIO_CONSULTORES(P.ID_CLIENTE,PS.ID_PROYECTO,PS.ID_TIPO_SERVICIO,PS.ID_PROYECTO_SERVICIO) AS CONSULTORES,
            dbo.FN_GET_TOTAL_HS_EJEC_PERIODO(PS.ID_PROYECTO_SERVICIO,@VPA_FDESDE_DATE,@VPA_FHASTA_DATE) AS HS_EJEC) X
        LEFT JOIN (SELECT PS2.ID_PROYECTO_SERVICIO IDPS, MAX(PD.FECHA_DOCUM) FECHA
                   FROM dbo.LK_PROYECTO_SERVICIO PS2
                       LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO=PD.PROYECTO_SERV_ID AND PD.TIPO='PE'
                   GROUP BY PS2.ID_PROYECTO_SERVICIO) PE ON PS.ID_PROYECTO_SERVICIO=PE.IDPS
        LEFT JOIN (SELECT PS2.ID_PROYECTO_SERVICIO IDPS, MAX(PD.FECHA_DOCUM) FECHA
                   FROM dbo.LK_PROYECTO_SERVICIO PS2
                       LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO=PD.PROYECTO_SERV_ID AND PD.TIPO='MC'
                   GROUP BY PS2.ID_PROYECTO_SERVICIO) MC ON PS.ID_PROYECTO_SERVICIO=MC.IDPS
        LEFT JOIN dbo.LK_PROYECTO_DOCUM DOC ON PE.IDPS=DOC.PROYECTO_SERV_ID AND DOC.TIPO='PE' AND DOC.FECHA_DOCUM=PE.FECHA
    WHERE PS.FECHA_INICIO_REAL<=@VPA_FHASTA_DATE
      AND PS.FECHA_FIN_REAL>=@VPA_FDESDE_DATE
      AND PS.ID_TIPO_SERVICIO='1';
 
    DECLARE @CNT_SEGCONS INT = (SELECT COUNT(*) FROM #SEGCONS_BASE);
 
    DECLARE
        @VTOTAL_CONS      INT,
        @VTOTAL_HS_PROY_CONS DECIMAL(18,2),
        @VTOTAL_HS_EJEC_CONS DECIMAL(18,2);
 
    /* Totales derivados de #SEGCONS_BASE (mismo filtro que el INSERT de
       arriba) en vez de repetir el JOIN completo + FN_GET_TOTAL_HS_EJEC_PERIODO
       una tercera vez por fila -- esa funcion escalar hace RBAR (fila por
       fila) y esta SP evalua TODOS los reportes de fecha en cada ejecucion
       (no solo la pestaña activa), asi que triplicar su costo aca (y en
       Auditoria/Capacitacion mas abajo) era la causa del timeout al
       filtrar por fecha. */
    SELECT
        @VTOTAL_CONS         = COUNT(*),
        @VTOTAL_HS_PROY_CONS = SUM(HORAS_PROY),
        @VTOTAL_HS_EJEC_CONS = SUM(HORAS_EJEC)
    FROM #SEGCONS_BASE;
 
    SET @VTOTAL_CONS         = ISNULL(@VTOTAL_CONS,0);
    SET @VTOTAL_HS_PROY_CONS = ISNULL(@VTOTAL_HS_PROY_CONS,0);
    SET @VTOTAL_HS_EJEC_CONS = ISNULL(@VTOTAL_HS_EJEC_CONS,0);
 
    DECLARE @VPCT_CONS INT = CASE WHEN @VTOTAL_HS_PROY_CONS=0 THEN 0
                                   WHEN @VTOTAL_HS_EJEC_CONS*100.0/@VTOTAL_HS_PROY_CONS>100 THEN 100
                                   ELSE CONVERT(INT,@VTOTAL_HS_EJEC_CONS*100.0/@VTOTAL_HS_PROY_CONS) END;
 
    /* Cronograma (Top 5 por Fecha Inicio) para el grafico estilo Gantt:
       cada barra se ubica en % dentro del rango total (min inicio - max
       fin) de esos 5 servicios. */
    IF OBJECT_ID('tempdb..#CONS_GANTT') IS NOT NULL DROP TABLE #CONS_GANTT;
    SELECT TOP 5 PROYECTO, FECHA_INICIO, FECHA_FIN, ROW_NUMBER() OVER (ORDER BY FECHA_INICIO) AS RN
    INTO #CONS_GANTT
    FROM #SEGCONS_BASE
    WHERE FECHA_INICIO IS NOT NULL AND FECHA_FIN IS NOT NULL
    ORDER BY FECHA_INICIO;
 
    DECLARE @VCONS_GANTT_MIN DATETIME = (SELECT MIN(FECHA_INICIO) FROM #CONS_GANTT);
    DECLARE @VCONS_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_INICIO),MAX(FECHA_FIN)) FROM #CONS_GANTT);
    IF @VCONS_GANTT_SPAN IS NULL OR @VCONS_GANTT_SPAN=0 SET @VCONS_GANTT_SPAN=1;
 
    DECLARE @HTML_CONS_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_INICIO,103)+' - '+CONVERT(VARCHAR(10),FECHA_FIN,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-mint" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VCONS_GANTT_MIN,FECHA_INICIO)*100.0/@VCONS_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_INICIO,FECHA_FIN)*100.0/@VCONS_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_INICIO,FECHA_FIN)*100.0/@VCONS_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #CONS_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CONS_GANTT=''
        SET @HTML_CONS_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    /* Barras: Top 5 clientes por horas ejecutadas en el periodo. */
    DECLARE @VMAX_CONS_CLI DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(HORAS_EJEC) S FROM #SEGCONS_BASE GROUP BY CLIENTE) X);
    IF @VMAX_CONS_CLI IS NULL OR @VMAX_CONS_CLI=0 SET @VMAX_CONS_CLI=1;
    DECLARE @HTML_CONS_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),SUM(HORAS_EJEC))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(HORAS_EJEC)*100.0/@VMAX_CONS_CLI))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(CLIENTE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGCONS_BASE
        GROUP BY CLIENTE
        ORDER BY SUM(HORAS_EJEC) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CONS_BARS=''
        SET @HTML_CONS_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    DECLARE @HTML_SEGCONS_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGCONS_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CLIENTE+' '+PROYECTO+' '+PERSONAL,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Inicio" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_INICIO,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_INICIO,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Fin" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_FIN,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FIN,103),'')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Personal Afectado">'+REPLACE(REPLACE(REPLACE(ISNULL(PERSONAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Hs Proy. Servicio" data-vct-sort-value="'+CONVERT(VARCHAR(20),HORAS_PROY)+'">'+CONVERT(VARCHAR(20),HORAS_PROY)+'</td>'+
                '<td class="vct-text-center" data-label="Hs Ejec. Servicio Periodo" data-vct-sort-value="'+CONVERT(VARCHAR(20),HORAS_EJEC)+'">'+CONVERT(VARCHAR(20),HORAS_EJEC)+'</td>'+
                '<td class="vct-text-center" data-label="% Avance Periodo" data-vct-sort-value="'+CONVERT(VARCHAR(20),PORC_AVANCE)+'">'+CONVERT(VARCHAR(20),PORC_AVANCE)+'%</td>'+
                '<td data-label="Frecuencia Envío Plan">'+REPLACE(REPLACE(REPLACE(ISNULL(FRECUENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Plan Estratégico">'+ISNULL(CONVERT(VARCHAR(10),FECHA_PLAN,103),'')+'</td>'+
                '<td data-label="Observaciones">'+REPLACE(REPLACE(REPLACE(ISNULL(OBSERVACIONES,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Minuta Cierre Servicio">'+CASE WHEN ISNULL(MINUTA_CIERRE,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+MINUTA_CIERRE+'">'+MINUTA_CIERRE+'</span>' END+'</td>'+
            '</tr>'
        FROM #SEGCONS_BASE
        ORDER BY CLIENTE, PROYECTO, FECHA_FIN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGCONS_ROWS='<tr><td colspan="12" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGCONS_ROWS=''
        SET @HTML_SEGCONS_ROWS='<tr><td colspan="12" class="vct-text-center">Sin consultorías para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       5. SEGUIMIENTO DE AUDITORIA - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_AUDITORIA (el SELECT activo;
       ignora igual el bloque comentado). Filtro de fecha propio del
       original: solo FECHA_INICIO_REAL entre Desde/Hasta (no rango
       superpuesto como Consultoria), pero reusa el mismo par de campos
       compartidos TEXTO03/04.
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-auditoria'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGAUDI_BASE') IS NOT NULL DROP TABLE #SEGAUDI_BASE;
    CREATE TABLE #SEGAUDI_BASE
    (
        NOMBRE       VARCHAR(600),
        LUGAR        VARCHAR(600),
        CLIENTE      VARCHAR(600),
        FECHA_INI    DATETIME,
        FECHA_FIN    DATETIME,
        AUDITORES    VARCHAR(MAX),
        DIAS_AUDITOR DECIMAL(10,2),
        PROYECTO     VARCHAR(MAX),
        HS_PROYEC    DECIMAL(18,2),
        HS_EJEC      DECIMAL(18,2),
        PORC_AVANCE  DECIMAL(10,2),
        PLAN_AUDI    VARCHAR(20),
        FECHA_PLAN   VARCHAR(20),
        INFORME      VARCHAR(20),
        FECHA_INF    VARCHAR(20),
        TIEMPO_INF   VARCHAR(20)
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    BEGIN
    /* Pre-calculo por conjuntos de DIAS_AUDITOR y HS_EJEC (equivalente a
       FN_GET_SERVICIO_DIAS y FN_GET_TOTAL_HS_EJECUTADAS('PS'), que corrian
       por fila: ~15 ms/servicio -> timeout con rangos largos).
       - HS_EJEC  = SUM(HORAS) de LK_AGENDA_EMPLEADO (TIPO='A') de las agendas del servicio.
       - DIAS     = SUM(DIAS * empleados distintos) de las agendas que coinciden en
                    cliente/proyecto/tipo/servicio; NULL si alguna agenda tiene DIAS NULL
                    (igual que la funcion), 0 si no hay agendas. */
    IF OBJECT_ID('tempdb..#AUDI_S')   IS NOT NULL DROP TABLE #AUDI_S;
    IF OBJECT_ID('tempdb..#AUDI_AG')  IS NOT NULL DROP TABLE #AUDI_AG;
    IF OBJECT_ID('tempdb..#AUDI_CNT') IS NOT NULL DROP TABLE #AUDI_CNT;
    IF OBJECT_ID('tempdb..#AUDI_X')   IS NOT NULL DROP TABLE #AUDI_X;
 
    CREATE TABLE #AUDI_S (IDPS INT NOT NULL PRIMARY KEY, ID_CLIENTE INT, ID_PROYECTO INT, ID_TIPO INT);
    INSERT INTO #AUDI_S (IDPS,ID_CLIENTE,ID_PROYECTO,ID_TIPO)
    SELECT DISTINCT PS.ID_PROYECTO_SERVICIO,P.ID_CLIENTE,PS.ID_PROYECTO,PS.ID_TIPO_SERVICIO
    FROM dbo.LK_PROYECTO P WITH(NOLOCK)
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO=PS.ID_PROYECTO
    WHERE PS.FECHA_INICIO_REAL>=@VPA_FDESDE_DATE
      AND PS.FECHA_INICIO_REAL<=@VPA_FHASTA_DATE
      AND PS.ID_TIPO_SERVICIO='2';
 
    CREATE TABLE #AUDI_AG (ID_AGENDA INT NOT NULL PRIMARY KEY, IDPS INT NOT NULL, DIAS INT NULL, ES_SERV BIT NOT NULL);
    INSERT INTO #AUDI_AG (ID_AGENDA,IDPS,DIAS,ES_SERV)
    SELECT A.ID_AGENDA,S.IDPS,CONVERT(INT,A.DIAS),
           CASE WHEN A.ID_CLIENTE=S.ID_CLIENTE AND A.ID_PROYECTO=S.ID_PROYECTO AND A.ID_SERVICIO=S.ID_TIPO THEN 1 ELSE 0 END
    FROM #AUDI_S S
        INNER JOIN dbo.LK_AGENDA A ON A.PROYECTO_SERV_ID=S.IDPS;
 
    CREATE TABLE #AUDI_CNT (ID_AGENDA INT NOT NULL PRIMARY KEY, CNT INT NOT NULL);
    INSERT INTO #AUDI_CNT (ID_AGENDA,CNT)
    SELECT G.ID_AGENDA,COUNT(DISTINCT AE.ID_EMPLEADO)
    FROM #AUDI_AG G
        INNER JOIN dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK) ON AE.HOLIDAYTEXT=CONVERT(VARCHAR,G.ID_AGENDA)
    WHERE G.ES_SERV=1
    GROUP BY G.ID_AGENDA;
 
    CREATE TABLE #AUDI_X (IDPS INT NOT NULL PRIMARY KEY, DIAS DECIMAL(10,2) NULL, HS DECIMAL(18,2) NOT NULL);
    INSERT INTO #AUDI_X (IDPS,DIAS,HS)
    SELECT S.IDPS,
           CASE WHEN D.IDPS IS NULL THEN 0 ELSE D.DIAS END,
           CONVERT(DECIMAL(18,2),ISNULL(H.HS,0))
    FROM #AUDI_S S
        LEFT JOIN (SELECT G.IDPS,
                          CASE WHEN COUNT(*)>COUNT(G.DIAS) THEN NULL ELSE SUM(G.DIAS*ISNULL(C.CNT,0)) END AS DIAS
                   FROM #AUDI_AG G
                       LEFT JOIN #AUDI_CNT C ON C.ID_AGENDA=G.ID_AGENDA
                   WHERE G.ES_SERV=1
                   GROUP BY G.IDPS) D ON D.IDPS=S.IDPS
        LEFT JOIN (SELECT G.IDPS,SUM(AE.HORAS) AS HS
                   FROM #AUDI_AG G
                       INNER JOIN dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK) ON AE.HOLIDAYTEXT=CONVERT(VARCHAR,G.ID_AGENDA) AND AE.TIPO='A'
                   GROUP BY G.IDPS) H ON H.IDPS=S.IDPS;
 
    INSERT INTO #SEGAUDI_BASE (NOMBRE,LUGAR,CLIENTE,FECHA_INI,FECHA_FIN,AUDITORES,DIAS_AUDITOR,PROYECTO,HS_PROYEC,HS_EJEC,PORC_AVANCE,PLAN_AUDI,FECHA_PLAN,INFORME,FECHA_INF,TIEMPO_INF)
    SELECT DISTINCT
        PS.NOMBRE,
        PS.LUGAR,
        CLI.RAZON_SOCIAL,
        PS.FECHA_INICIO_REAL,
        PS.FECHA_FIN_REAL,
        CASE WHEN X.AUDITORES='1' THEN 'Sin Auditores' ELSE X.AUDITORES END,
        X.DIAS_AUDITOR,
        '('+P.CODIGO+') - '+P.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0),
        X.HS_EJEC,
        CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)=0 THEN 0
             ELSE X.HS_EJEC*100.0/ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) END,
        CASE WHEN PLA.FECHA IS NOT NULL THEN 'Enviado' ELSE 'Pendiente' END,
        CASE WHEN PLA.FECHA IS NOT NULL THEN CONVERT(VARCHAR,PLA.FECHA,103) ELSE '' END,
        CASE WHEN INF.FECHA IS NOT NULL THEN 'Enviado' ELSE 'Pendiente' END,
        CASE WHEN INF.FECHA IS NOT NULL THEN CONVERT(VARCHAR,INF.FECHA,103) ELSE '' END,
        ISNULL(CONVERT(VARCHAR(20),dbo.FN_GET_DIAS_HABILES(PS.FECHA_FIN_REAL,INF.FECHA)-1),'')
    FROM dbo.LK_PROYECTO P WITH(NOLOCK)
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO=PS.ID_PROYECTO
        INNER JOIN dbo.VCT_CLIENTES CLI ON P.ID_CLIENTE=CLI.ID
        INNER JOIN #AUDI_X XX ON XX.IDPS=PS.ID_PROYECTO_SERVICIO
        CROSS APPLY (SELECT
            dbo.FN_GET_SERVICIO_CONSULTORES(P.ID_CLIENTE,PS.ID_PROYECTO,PS.ID_TIPO_SERVICIO,PS.ID_PROYECTO_SERVICIO) AS AUDITORES,
            XX.DIAS AS DIAS_AUDITOR,
            XX.HS AS HS_EJEC) X
        LEFT JOIN (SELECT PS2.ID_PROYECTO_SERVICIO IDPS, MAX(PD.FECHA_DOCUM) FECHA
                   FROM dbo.LK_PROYECTO_SERVICIO PS2
                       LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO=PD.PROYECTO_SERV_ID AND PD.TIPO='PA'
                   GROUP BY PS2.ID_PROYECTO_SERVICIO) PLA ON PS.ID_PROYECTO_SERVICIO=PLA.IDPS
        LEFT JOIN (SELECT PS2.ID_PROYECTO_SERVICIO IDPS, MAX(PD.FECHA_DOCUM) FECHA
                   FROM dbo.LK_PROYECTO_SERVICIO PS2
                       LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO=PD.PROYECTO_SERV_ID AND PD.TIPO='IA'
                   GROUP BY PS2.ID_PROYECTO_SERVICIO) INF ON PS.ID_PROYECTO_SERVICIO=INF.IDPS
    WHERE PS.FECHA_INICIO_REAL>=@VPA_FDESDE_DATE
      AND PS.FECHA_INICIO_REAL<=@VPA_FHASTA_DATE
      AND PS.ID_TIPO_SERVICIO='2';
    END
 
    DECLARE @CNT_SEGAUDI INT = (SELECT COUNT(*) FROM #SEGAUDI_BASE);
 
    DECLARE
        @VTOTAL_AUDI      INT,
        @VTOTAL_HS_PROY_AUDI DECIMAL(18,2),
        @VTOTAL_HS_EJEC_AUDI DECIMAL(18,2);
 
    SELECT
        @VTOTAL_AUDI         = COUNT(*),
        @VTOTAL_HS_PROY_AUDI = SUM(HS_PROYEC),
        @VTOTAL_HS_EJEC_AUDI = SUM(HS_EJEC)
    FROM #SEGAUDI_BASE;
 
    SET @VTOTAL_AUDI         = ISNULL(@VTOTAL_AUDI,0);
    SET @VTOTAL_HS_PROY_AUDI = ISNULL(@VTOTAL_HS_PROY_AUDI,0);
    SET @VTOTAL_HS_EJEC_AUDI = ISNULL(@VTOTAL_HS_EJEC_AUDI,0);
 
    DECLARE @VPCT_AUDI INT = CASE WHEN @VTOTAL_HS_PROY_AUDI=0 THEN 0
                                   WHEN @VTOTAL_HS_EJEC_AUDI*100.0/@VTOTAL_HS_PROY_AUDI>100 THEN 100
                                   ELSE CONVERT(INT,@VTOTAL_HS_EJEC_AUDI*100.0/@VTOTAL_HS_PROY_AUDI) END;
 
    IF OBJECT_ID('tempdb..#AUDI_GANTT') IS NOT NULL DROP TABLE #AUDI_GANTT;
    SELECT TOP 5 PROYECTO, FECHA_INI, FECHA_FIN, ROW_NUMBER() OVER (ORDER BY FECHA_INI) AS RN
    INTO #AUDI_GANTT
    FROM #SEGAUDI_BASE
    WHERE FECHA_INI IS NOT NULL AND FECHA_FIN IS NOT NULL
    ORDER BY FECHA_INI;
 
    DECLARE @VAUDI_GANTT_MIN DATETIME = (SELECT MIN(FECHA_INI) FROM #AUDI_GANTT);
    DECLARE @VAUDI_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_INI),MAX(FECHA_FIN)) FROM #AUDI_GANTT);
    IF @VAUDI_GANTT_SPAN IS NULL OR @VAUDI_GANTT_SPAN=0 SET @VAUDI_GANTT_SPAN=1;
 
    DECLARE @HTML_AUDI_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_INI,103)+' - '+CONVERT(VARCHAR(10),FECHA_FIN,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-amber" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VAUDI_GANTT_MIN,FECHA_INI)*100.0/@VAUDI_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VAUDI_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VAUDI_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #AUDI_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_AUDI_GANTT=''
        SET @HTML_AUDI_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @VMAX_AUDI_CLI DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(HS_EJEC) S FROM #SEGAUDI_BASE GROUP BY CLIENTE) X);
    IF @VMAX_AUDI_CLI IS NULL OR @VMAX_AUDI_CLI=0 SET @VMAX_AUDI_CLI=1;
    DECLARE @HTML_AUDI_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),SUM(HS_EJEC))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(HS_EJEC)*100.0/@VMAX_AUDI_CLI))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(CLIENTE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGAUDI_BASE
        GROUP BY CLIENTE
        ORDER BY SUM(HS_EJEC) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_AUDI_BARS=''
        SET @HTML_AUDI_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    DECLARE @HTML_SEGAUDI_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGAUDI_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CLIENTE+' '+NOMBRE+' '+PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Nombre">'+REPLACE(REPLACE(REPLACE(ISNULL(NOMBRE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Lugar">'+REPLACE(REPLACE(REPLACE(ISNULL(LUGAR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Inicio" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_INI,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_INI,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Fin" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_FIN,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FIN,103),'')+'</td>'+
                '<td data-label="Auditores">'+REPLACE(REPLACE(REPLACE(ISNULL(AUDITORES,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Días Auditor" data-vct-sort-value="'+CONVERT(VARCHAR(20),DIAS_AUDITOR)+'">'+CONVERT(VARCHAR(20),DIAS_AUDITOR)+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Hs Proyectadas" data-vct-sort-value="'+CONVERT(VARCHAR(20),HS_PROYEC)+'">'+CONVERT(VARCHAR(20),HS_PROYEC)+'</td>'+
                '<td class="vct-text-center" data-label="Hs Ejecutadas" data-vct-sort-value="'+CONVERT(VARCHAR(20),HS_EJEC)+'">'+CONVERT(VARCHAR(20),HS_EJEC)+'</td>'+
                '<td class="vct-text-center" data-label="% Avance" data-vct-sort-value="'+CONVERT(VARCHAR(20),PORC_AVANCE)+'">'+CONVERT(VARCHAR(20),PORC_AVANCE)+'%</td>'+
                '<td class="vct-text-center" data-label="Plan Auditoría">'+CASE WHEN ISNULL(PLAN_AUDI,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+PLAN_AUDI+'">'+PLAN_AUDI+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Fecha PA">'+ISNULL(FECHA_PLAN,'')+'</td>'+
                '<td class="vct-text-center" data-label="Informe">'+CASE WHEN ISNULL(INFORME,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+INFORME+'">'+INFORME+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Inf.">'+ISNULL(FECHA_INF,'')+'</td>'+
                '<td class="vct-text-center" data-label="Tiempo Inf.">'+ISNULL(TIEMPO_INF,'')+'</td>'+
            '</tr>'
        FROM #SEGAUDI_BASE
        ORDER BY FECHA_FIN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGAUDI_ROWS='<tr><td colspan="16" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGAUDI_ROWS=''
        SET @HTML_SEGAUDI_ROWS='<tr><td colspan="16" class="vct-text-center">Sin auditorías para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       6. SEGUIMIENTO DE CAPACITACION - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_CAPACITACION. Reusa el mismo
       filtro compartido Fecha Desde/Hasta (TEXTO03/04).
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-capacitacion'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGCAPA_BASE') IS NOT NULL DROP TABLE #SEGCAPA_BASE;
    CREATE TABLE #SEGCAPA_BASE
    (
        CLIENTE      VARCHAR(600),
        PROYECTO     VARCHAR(MAX),
        CURSO        VARCHAR(600),
        FECHA_INI    DATETIME,
        FECHA_FIN    DATETIME,
        INSTRUCTORES VARCHAR(MAX),
        HS_PROYEC    DECIMAL(18,2),
        HS_EJEC      DECIMAL(18,2),
        PORC_AVANCE  DECIMAL(10,2),
        MATERIAL     VARCHAR(50),
        ESTADO_ENVIO VARCHAR(50),
        RECIBIDO     VARCHAR(50),
        INFORME      VARCHAR(20),
        FECHA_INF    VARCHAR(20),
        TIEMPO_INF   VARCHAR(20)
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #SEGCAPA_BASE (CLIENTE,PROYECTO,CURSO,FECHA_INI,FECHA_FIN,INSTRUCTORES,HS_PROYEC,HS_EJEC,PORC_AVANCE,MATERIAL,ESTADO_ENVIO,RECIBIDO,INFORME,FECHA_INF,TIEMPO_INF)
    SELECT
        CLI.RAZON_SOCIAL,
        '('+P.CODIGO+') - '+P.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        PS.NOMBRE_CURSO,
        PS.FECHA_INICIO_REAL,
        PS.FECHA_FIN_REAL,
        CASE WHEN X.INSTRUCTORES='1' THEN 'Sin Instructores' ELSE X.INSTRUCTORES END,
        ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0),
        X.HS_EJEC,
        CASE WHEN ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0)=0 THEN 0
             ELSE X.HS_EJEC*100.0/ISNULL(PS.TOTAL_HORAS_PROYECTADAS,0) END,
        UPPER(SUBSTRING(PS.MATERIALES,1,1))+LOWER(SUBSTRING(PS.MATERIALES,2,LEN(PS.MATERIALES))),
        UPPER(SUBSTRING(PS.ESTADO_ENVIO,1,1))+LOWER(SUBSTRING(PS.ESTADO_ENVIO,2,LEN(PS.ESTADO_ENVIO))),
        UPPER(SUBSTRING(PS.RECIBIDO,1,1))+LOWER(SUBSTRING(PS.RECIBIDO,2,LEN(PS.RECIBIDO))),
        CASE WHEN INF.FECHA IS NOT NULL THEN 'Enviado' ELSE 'Pendiente' END,
        CASE WHEN INF.FECHA IS NOT NULL THEN CONVERT(VARCHAR,INF.FECHA,103) ELSE '' END,
        ISNULL(CONVERT(VARCHAR(20),dbo.FN_GET_DIAS_HABILES(dbo.FN_GET_SERVICIO_VISITAS(P.ID_CLIENTE,PS.ID_PROYECTO,PS.ID_TIPO_SERVICIO,PS.ID_PROYECTO_SERVICIO),INF.FECHA)),'')
    FROM dbo.LK_PROYECTO P WITH(NOLOCK)
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO=PS.ID_PROYECTO
        INNER JOIN dbo.VCT_CLIENTES CLI ON P.ID_CLIENTE=CLI.ID
        LEFT JOIN (SELECT A.PROYECTO_SERV_ID AS IDPS,SUM(AE.HORAS) AS HS   /* = FN_GET_TOTAL_HS_EJECUTADAS('PS'), por conjuntos */
                   FROM dbo.LK_AGENDA A
                       INNER JOIN dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK) ON AE.HOLIDAYTEXT=CONVERT(VARCHAR,A.ID_AGENDA) AND AE.TIPO='A'
                   GROUP BY A.PROYECTO_SERV_ID) HE ON HE.IDPS=PS.ID_PROYECTO_SERVICIO
        CROSS APPLY (SELECT
            dbo.FN_GET_SERVICIO_CONSULTORES(P.ID_CLIENTE,PS.ID_PROYECTO,PS.ID_TIPO_SERVICIO,PS.ID_PROYECTO_SERVICIO) AS INSTRUCTORES,
            CONVERT(DECIMAL(18,2),ISNULL(HE.HS,0)) AS HS_EJEC) X
        LEFT JOIN (SELECT PS2.ID_PROYECTO_SERVICIO SERVICIO, PD.FECHA_DOCUM FECHA
                   FROM dbo.LK_PROYECTO_SERVICIO PS2
                       LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO=PD.PROYECTO_SERV_ID
                   WHERE PD.TIPO='IC'
                     AND PD.FECHA_DOCUM=(SELECT MAX(doc.FECHA_DOCUM) FROM dbo.LK_PROYECTO_DOCUM doc WHERE doc.PROYECTO_SERV_ID=PS2.ID_PROYECTO_SERVICIO)) INF
               ON PS.ID_PROYECTO_SERVICIO=INF.SERVICIO
    WHERE PS.FECHA_INICIO_REAL>=@VPA_FDESDE_DATE
      AND PS.FECHA_INICIO_REAL<=@VPA_FHASTA_DATE
      AND PS.ID_TIPO_SERVICIO='3';
 
    DECLARE @CNT_SEGCAPA INT = (SELECT COUNT(*) FROM #SEGCAPA_BASE);
 
    DECLARE
        @VTOTAL_CAPA         INT,
        @VTOTAL_HS_PROY_CAPA DECIMAL(18,2),
        @VTOTAL_HS_EJEC_CAPA DECIMAL(18,2);
 
    SELECT
        @VTOTAL_CAPA         = COUNT(*),
        @VTOTAL_HS_PROY_CAPA = SUM(HS_PROYEC),
        @VTOTAL_HS_EJEC_CAPA = SUM(HS_EJEC)
    FROM #SEGCAPA_BASE;
 
    SET @VTOTAL_CAPA         = ISNULL(@VTOTAL_CAPA,0);
    SET @VTOTAL_HS_PROY_CAPA = ISNULL(@VTOTAL_HS_PROY_CAPA,0);
    SET @VTOTAL_HS_EJEC_CAPA = ISNULL(@VTOTAL_HS_EJEC_CAPA,0);
 
    DECLARE @VPCT_CAPA INT = CASE WHEN @VTOTAL_HS_PROY_CAPA=0 THEN 0
                                   WHEN @VTOTAL_HS_EJEC_CAPA*100.0/@VTOTAL_HS_PROY_CAPA>100 THEN 100
                                   ELSE CONVERT(INT,@VTOTAL_HS_EJEC_CAPA*100.0/@VTOTAL_HS_PROY_CAPA) END;
 
    IF OBJECT_ID('tempdb..#CAPA_GANTT') IS NOT NULL DROP TABLE #CAPA_GANTT;
    SELECT TOP 5 PROYECTO, FECHA_INI, FECHA_FIN, ROW_NUMBER() OVER (ORDER BY FECHA_INI) AS RN
    INTO #CAPA_GANTT
    FROM #SEGCAPA_BASE
    WHERE FECHA_INI IS NOT NULL AND FECHA_FIN IS NOT NULL
    ORDER BY FECHA_INI;
 
    DECLARE @VCAPA_GANTT_MIN DATETIME = (SELECT MIN(FECHA_INI) FROM #CAPA_GANTT);
    DECLARE @VCAPA_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_INI),MAX(FECHA_FIN)) FROM #CAPA_GANTT);
    IF @VCAPA_GANTT_SPAN IS NULL OR @VCAPA_GANTT_SPAN=0 SET @VCAPA_GANTT_SPAN=1;
 
    DECLARE @HTML_CAPA_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_INI,103)+' - '+CONVERT(VARCHAR(10),FECHA_FIN,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-blue" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VCAPA_GANTT_MIN,FECHA_INI)*100.0/@VCAPA_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VCAPA_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_INI,FECHA_FIN)*100.0/@VCAPA_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #CAPA_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CAPA_GANTT=''
        SET @HTML_CAPA_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @VMAX_CAPA_CLI DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(HS_EJEC) S FROM #SEGCAPA_BASE GROUP BY CLIENTE) X);
    IF @VMAX_CAPA_CLI IS NULL OR @VMAX_CAPA_CLI=0 SET @VMAX_CAPA_CLI=1;
    DECLARE @HTML_CAPA_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),SUM(HS_EJEC))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(HS_EJEC)*100.0/@VMAX_CAPA_CLI))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(CLIENTE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGCAPA_BASE
        GROUP BY CLIENTE
        ORDER BY SUM(HS_EJEC) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CAPA_BARS=''
        SET @HTML_CAPA_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    DECLARE @HTML_SEGCAPA_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGCAPA_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CLIENTE+' '+PROYECTO+' '+ISNULL(CURSO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Curso">'+REPLACE(REPLACE(REPLACE(ISNULL(CURSO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Inicio" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_INI,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_INI,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Fin" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_FIN,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FIN,103),'')+'</td>'+
                '<td data-label="Instructores">'+REPLACE(REPLACE(REPLACE(ISNULL(INSTRUCTORES,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Hs Proyectadas" data-vct-sort-value="'+CONVERT(VARCHAR(20),HS_PROYEC)+'">'+CONVERT(VARCHAR(20),HS_PROYEC)+'</td>'+
                '<td class="vct-text-center" data-label="Hs Ejecutadas" data-vct-sort-value="'+CONVERT(VARCHAR(20),HS_EJEC)+'">'+CONVERT(VARCHAR(20),HS_EJEC)+'</td>'+
                '<td class="vct-text-center" data-label="% Avance" data-vct-sort-value="'+CONVERT(VARCHAR(20),PORC_AVANCE)+'">'+CONVERT(VARCHAR(20),PORC_AVANCE)+'%</td>'+
                '<td class="vct-text-center" data-label="Material">'+CASE WHEN ISNULL(MATERIAL,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+MATERIAL+'">'+MATERIAL+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Estado Envío">'+CASE WHEN ISNULL(ESTADO_ENVIO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+ESTADO_ENVIO+'">'+ESTADO_ENVIO+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Recibido">'+CASE WHEN ISNULL(RECIBIDO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+RECIBIDO+'">'+RECIBIDO+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Informe">'+CASE WHEN ISNULL(INFORME,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+INFORME+'">'+INFORME+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Inf.">'+ISNULL(FECHA_INF,'')+'</td>'+
                '<td class="vct-text-center" data-label="Tiempo Inf.">'+ISNULL(TIEMPO_INF,'')+'</td>'+
            '</tr>'
        FROM #SEGCAPA_BASE
        ORDER BY FECHA_FIN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGCAPA_ROWS='<tr><td colspan="15" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGCAPA_ROWS=''
        SET @HTML_SEGCAPA_ROWS='<tr><td colspan="15" class="vct-text-center">Sin capacitaciones para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       7. CALIFICACION CONSULTORES - CALCULO BASE
       ------------------------------------------------------------
       Misma logica que SV_05_GRD_CALIF_CONSULTORES, pero sin el EXEC()
       de SQL dinamico (armaba el WHERE por concatenacion): se reemplaza
       por condiciones parametrizadas equivalentes. Filtros propios
       (TEXTO05/06/07), sin fecha.
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='calif-consultores'
    BEGIN
    DECLARE @VCC_APTITUD_INT INT = CASE WHEN ISNUMERIC(@VCC_APTITUD)=1 THEN CONVERT(INT,@VCC_APTITUD) ELSE NULL END;
    DECLARE @VCC_TIPOSERV_INT INT = CASE WHEN ISNUMERIC(@VCC_TIPOSERV)=1 THEN CONVERT(INT,@VCC_TIPOSERV) ELSE NULL END;
 
    DECLARE @CNT_CALIFCONS INT;
 
    IF OBJECT_ID('tempdb..#CALIFCONS_BASE') IS NOT NULL DROP TABLE #CALIFCONS_BASE;
    CREATE TABLE #CALIFCONS_BASE
    (
        CONSULTOR      VARCHAR(640),
        ES_EVENTUAL    BIT,
        APTITUD        VARCHAR(600),
        APTITUD_ACTIVA BIT,
        TIPO_SERVICIO  VARCHAR(600),
        CALIFICACION   VARCHAR(50)
    );
 
    INSERT INTO #CALIFCONS_BASE (CONSULTOR,ES_EVENTUAL,APTITUD,APTITUD_ACTIVA,TIPO_SERVICIO,CALIFICACION)
    SELECT
        EMP.APELLIDO_EMPLEADO+' '+EMP.NOMBRE_EMPLEADO,
        CASE WHEN EMP.EVENTUAL='SI' THEN 1 ELSE 0 END,
        APT.DESC_APTITUD,
        CASE WHEN APT.STATUS_APTITUD='0' THEN 0 ELSE 1 END,
        TS.DESCRIPCION,
        EA.CALIFICACION
    FROM dbo.LK_EMPLEADOS EMP WITH(NOLOCK)
        LEFT JOIN dbo.LK_EMPLEADOS_APTITUD EA ON EMP.ID_EMPLEADO=EA.ID_EMPLEADO
        LEFT JOIN dbo.LK_APTITUDES APT ON EA.ID_APTITUD=APT.ID_APTITUD
        LEFT JOIN dbo.VCT_PRM_SERVICIOS TS ON TS.ID=EA.ID_TIPO
    WHERE EMP.STATUS_EMP='1'
      AND EMP.PERFIL_EMP='CONSULTOR'
      AND (@VCC_CALIF=''    OR EA.CALIFICACION=@VCC_CALIF)
      AND (@VCC_APTITUD_INT  IS NULL OR EA.ID_APTITUD=@VCC_APTITUD_INT)
      AND (@VCC_TIPOSERV_INT IS NULL OR EA.ID_TIPO=@VCC_TIPOSERV_INT);
 
    SET @CNT_CALIFCONS = (SELECT COUNT(*) FROM #CALIFCONS_BASE);
 
    DECLARE @VCALIF_EVENTUALES INT, @VCALIF_APTITUD_ACTIVA INT;
    SELECT
        @VCALIF_EVENTUALES     = SUM(CASE WHEN ES_EVENTUAL=1 THEN 1 ELSE 0 END),
        @VCALIF_APTITUD_ACTIVA = SUM(CASE WHEN APTITUD IS NOT NULL AND APTITUD_ACTIVA=1 THEN 1 ELSE 0 END)
    FROM #CALIFCONS_BASE;
    SET @VCALIF_EVENTUALES     = ISNULL(@VCALIF_EVENTUALES,0);
    SET @VCALIF_APTITUD_ACTIVA = ISNULL(@VCALIF_APTITUD_ACTIVA,0);
 
    DECLARE @HTML_CALIFCONS_ROWS VARCHAR(MAX)='';
    SELECT @HTML_CALIFCONS_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CONSULTOR+' '+ISNULL(APTITUD,'')+' '+ISNULL(TIPO_SERVICIO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Consultor">'+
                    CASE WHEN ES_EVENTUAL=1
                         THEN '<span style="color:#1D4ED8;">'+REPLACE(REPLACE(REPLACE(CONSULTOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>'
                         ELSE REPLACE(REPLACE(REPLACE(CONSULTOR,'&','&amp;'),'<','&lt;'),'>','&gt;') END+
                '</td>'+
                '<td data-label="Aptitud">'+
                    CASE WHEN APTITUD IS NULL THEN ''
                         WHEN APTITUD_ACTIVA=0 THEN '<span style="color:#B91C1C;">'+REPLACE(REPLACE(REPLACE(APTITUD,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>'
                         ELSE REPLACE(REPLACE(REPLACE(APTITUD,'&','&amp;'),'<','&lt;'),'>','&gt;') END+
                '</td>'+
                '<td class="vct-text-center" data-label="Tipo Servicio">'+CASE WHEN TIPO_SERVICIO IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(TIPO_SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(TIPO_SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Calificación">'+CASE WHEN CALIFICACION IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(CALIFICACION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(CALIFICACION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
            '</tr>'
        FROM #CALIFCONS_BASE
        ORDER BY CONSULTOR
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_CALIFCONS_ROWS=''
        SET @HTML_CALIFCONS_ROWS='<tr><td colspan="4" class="vct-text-center">Sin registros para los filtros seleccionados.</td></tr>';
 
    /* Grafico "afin a lo seleccionado": donut de composicion (top 5) de
       consultores por calificacion (CALIFICACION es texto libre de
       EA.CALIFICACION sin catalogo fijo, asi que se agrupa lo que haya en
       vez de asumir valores predefinidos). Se arma en una tabla temporal
       con el offset acumulado de cada segmento (donut de N porciones
       encadenadas), en vez de una cantidad fija de variables. */
    IF OBJECT_ID('tempdb..#CALIF_CHART_AGG') IS NOT NULL DROP TABLE #CALIF_CHART_AGG;
    SELECT TOP 5
        CALIFICACION,
        COUNT(*) AS CNT,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS RN
    INTO #CALIF_CHART_AGG
    FROM #CALIFCONS_BASE
    WHERE ISNULL(CALIFICACION,'')<>''
    GROUP BY CALIFICACION
    ORDER BY COUNT(*) DESC;
 
    DECLARE @VCALIF_TOTAL INT = (SELECT ISNULL(SUM(CNT),0) FROM #CALIF_CHART_AGG);
    IF @VCALIF_TOTAL=0 SET @VCALIF_TOTAL=1;
 
    ALTER TABLE #CALIF_CHART_AGG ADD PCT INT, CUM_BEFORE INT, COLORCLASS VARCHAR(20);
    UPDATE #CALIF_CHART_AGG SET PCT=CONVERT(INT,CNT*100.0/@VCALIF_TOTAL);
    UPDATE A SET CUM_BEFORE = ISNULL((SELECT SUM(PCT) FROM #CALIF_CHART_AGG B WHERE B.RN<A.RN),0)
    FROM #CALIF_CHART_AGG A;
    UPDATE #CALIF_CHART_AGG SET COLORCLASS =
        CASE RN WHEN 1 THEN 'is-mint' WHEN 2 THEN 'is-amber' WHEN 3 THEN 'is-blue' WHEN 4 THEN 'is-violet' ELSE 'is-coral' END;
 
    DECLARE @HTML_CALIF_SEGS VARCHAR(MAX) = ISNULL((
        SELECT '<circle class="vct-donut-seg '+COLORCLASS+'" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),PCT)+' '+CONVERT(VARCHAR(10),100-PCT)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-CUM_BEFORE)+'"></circle>'
        FROM #CALIF_CHART_AGG
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    DECLARE @HTML_CALIF_LEGEND VARCHAR(MAX) = ISNULL((
        SELECT '<div class="vct-donut-legend-item"><span class="vct-donut-dot '+COLORCLASS+'"></span> '+REPLACE(REPLACE(REPLACE(CALIFICACION,'&','&amp;'),'<','&lt;'),'>','&gt;')+' <b>'+CONVERT(VARCHAR(20),CNT)+'</b></div>'
        FROM #CALIF_CHART_AGG
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CALIF_LEGEND=''
        SET @HTML_CALIF_LEGEND='<div class="vct-donut-legend-item">Sin datos</div>';
 
    /* Barras: Top 5 aptitudes por cantidad de consultores. */
    DECLARE @VMAX_CALIF_APT INT = (SELECT MAX(CNT) FROM (SELECT COUNT(*) CNT FROM #CALIFCONS_BASE WHERE APTITUD IS NOT NULL GROUP BY APTITUD) X);
    IF @VMAX_CALIF_APT IS NULL OR @VMAX_CALIF_APT=0 SET @VMAX_CALIF_APT=1;
    DECLARE @HTML_CALIF_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),COUNT(*))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,COUNT(*)*100.0/@VMAX_CALIF_APT))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(APTITUD,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #CALIFCONS_BASE
        WHERE APTITUD IS NOT NULL
        GROUP BY APTITUD
        ORDER BY COUNT(*) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_CALIF_BARS=''
        SET @HTML_CALIF_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* Opciones de los 3 combos (catalogo real, mismo criterio que las
       plantillas dinamicas de VCT_MAIN_CONFIGURACION). */
    DECLARE @HTML_CC_APTITUDES VARCHAR(MAX)='';
    SELECT @HTML_CC_APTITUDES = ISNULL((
        SELECT '<option value="'+CONVERT(VARCHAR(20),ID_APTITUD)+'"'+
               CASE WHEN CONVERT(VARCHAR(20),ID_APTITUD)=@VCC_APTITUD THEN ' selected' ELSE '' END+
               '>'+REPLACE(REPLACE(REPLACE(DESC_APTITUD,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM dbo.LK_APTITUDES WITH(NOLOCK)
        ORDER BY DESC_APTITUD
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    DECLARE @HTML_CC_TIPOSERV VARCHAR(MAX)='';
    SELECT @HTML_CC_TIPOSERV = ISNULL((
        SELECT '<option value="'+CONVERT(VARCHAR(20),ID)+'"'+
               CASE WHEN CONVERT(VARCHAR(20),ID)=@VCC_TIPOSERV THEN ' selected' ELSE '' END+
               '>'+REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM dbo.VCT_PRM_SERVICIOS WITH(NOLOCK)
        ORDER BY DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    DECLARE @HTML_CC_CALIF VARCHAR(MAX)='';
    SELECT @HTML_CC_CALIF = ISNULL((
        SELECT '<option value="'+REPLACE(REPLACE(REPLACE(CALIFICACION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'"'+
               CASE WHEN CALIFICACION=@VCC_CALIF THEN ' selected' ELSE '' END+
               '>'+REPLACE(REPLACE(REPLACE(CALIFICACION,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM (SELECT DISTINCT CALIFICACION FROM dbo.LK_EMPLEADOS_APTITUD WITH(NOLOCK) WHERE CALIFICACION IS NOT NULL AND LTRIM(RTRIM(CALIFICACION))<>'') X  /* sin la opcion en blanco (quedaba seleccionada y ocultaba "Calificación (todas)") */
        ORDER BY CALIFICACION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    END
 
    /* ============================================================
       8. SEGUIMIENTO DE HOTELES - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_HOTELES. Reusa el filtro
       compartido Fecha Desde/Hasta (TEXTO03/04), pero contra
       V.FECHA_DESDE_SERV/FECHA_HASTA_SERV (estadia), no contra las
       fechas de proyecto como los reportes anteriores -- igual que el
       original. Sin KPIs (el shell legacy tampoco tenia).
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-hoteles'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGHOT_BASE') IS NOT NULL DROP TABLE #SEGHOT_BASE;
    CREATE TABLE #SEGHOT_BASE
    (
        ESTADIA_DESDE   DATETIME,
        ESTADIA_HASTA   DATETIME,
        NRO_FC          VARCHAR(50),
        FECHA_FC        DATETIME,
        PROVEEDOR       VARCHAR(600),
        TIPO_HUESPED    VARCHAR(100),
        HUESPED         VARCHAR(640),
        CLIENTE         VARCHAR(600),
        PROYECTO        VARCHAR(MAX),
        SERVICIO        VARCHAR(400),
        FORMA_PAGO      VARCHAR(100),
        DESC_FORMA_PAGO VARCHAR(600),
        PRECIO_FINAL    DECIMAL(18,2),
        CANT_CUOTAS     INT
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #SEGHOT_BASE (ESTADIA_DESDE,ESTADIA_HASTA,NRO_FC,FECHA_FC,PROVEEDOR,TIPO_HUESPED,HUESPED,CLIENTE,PROYECTO,SERVICIO,FORMA_PAGO,DESC_FORMA_PAGO,PRECIO_FINAL,CANT_CUOTAS)
    SELECT
        V.FECHA_DESDE_SERV,
        V.FECHA_HASTA_SERV,
        V.NRO_FC,
        V.FECHA_FC,
        CASE WHEN V.ID_PROVEEDOR=9999 THEN V.DESCRIP_SERVICIO ELSE P.RAZON_SOCIAL END,
        UPPER(SUBSTRING(V.TIPO_CONSULTOR,1,1))+LOWER(SUBSTRING(V.TIPO_CONSULTOR,2,LEN(V.TIPO_CONSULTOR))),
        CASE WHEN V.TIPO_CONSULTOR='CONSULTOR' THEN E.APELLIDO_EMPLEADO+', '+E.NOMBRE_EMPLEADO ELSE V.ID_CONSULTOR END,
        C.RAZON_SOCIAL,
        PROY.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        S.DESCRIPCION,
        UPPER(SUBSTRING(V.FORMA_PAGO,1,1))+LOWER(SUBSTRING(V.FORMA_PAGO,2,LEN(V.FORMA_PAGO))),
        V.DESC_FORMA_PAGO,
        V.PRECIO_FINAL,
        V.CANT_CUOTAS
    FROM dbo.LK_PROYECTO_VIATICOS V WITH(NOLOCK)
        INNER JOIN dbo.LK_AGENDA A ON V.ID_AGENDA=A.ID_AGENDA
        INNER JOIN dbo.LK_PROYECTO PROY ON PROY.ID_PROYECTO=A.ID_PROYECTO
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO=A.PROYECTO_SERV_ID
        INNER JOIN dbo.VCT_CLIENTES C ON C.ID=A.ID_CLIENTE
        INNER JOIN dbo.VCT_PRM_SERVICIOS S ON S.ID=V.ID_TIPO_SERVICIO
        LEFT JOIN dbo.VCT_PROVEEDORES P ON V.ID_PROVEEDOR=P.ID_PROVEEDOR
        LEFT JOIN dbo.LK_EMPLEADOS E ON V.ID_CONSULTOR=CONVERT(VARCHAR,E.ID_EMPLEADO)
    WHERE V.TIPO_PROVEEDOR='HOTEL'
      AND V.FECHA_DESDE_SERV>=@VPA_FDESDE_DATE
      AND V.FECHA_HASTA_SERV<=@VPA_FHASTA_DATE;
 
    DECLARE @CNT_SEGHOT INT = (SELECT COUNT(*) FROM #SEGHOT_BASE);
 
    IF OBJECT_ID('tempdb..#HOT_CHART_AGG') IS NOT NULL DROP TABLE #HOT_CHART_AGG;
    SELECT TOP 5
        FORMA_PAGO,
        SUM(PRECIO_FINAL) AS MONTO,
        ROW_NUMBER() OVER (ORDER BY SUM(PRECIO_FINAL) DESC) AS RN
    INTO #HOT_CHART_AGG
    FROM #SEGHOT_BASE
    WHERE ISNULL(FORMA_PAGO,'')<>''
    GROUP BY FORMA_PAGO
    ORDER BY SUM(PRECIO_FINAL) DESC;
 
    DECLARE @VHOT_TOTAL DECIMAL(18,2) = (SELECT ISNULL(SUM(MONTO),0) FROM #HOT_CHART_AGG);
    IF @VHOT_TOTAL=0 SET @VHOT_TOTAL=1;
 
    ALTER TABLE #HOT_CHART_AGG ADD PCT INT, CUM_BEFORE INT, COLORCLASS VARCHAR(20);
    UPDATE #HOT_CHART_AGG SET PCT=CONVERT(INT,MONTO*100.0/@VHOT_TOTAL);
    UPDATE A SET CUM_BEFORE = ISNULL((SELECT SUM(PCT) FROM #HOT_CHART_AGG B WHERE B.RN<A.RN),0)
    FROM #HOT_CHART_AGG A;
    UPDATE #HOT_CHART_AGG SET COLORCLASS =
        CASE RN WHEN 1 THEN 'is-mint' WHEN 2 THEN 'is-amber' WHEN 3 THEN 'is-blue' WHEN 4 THEN 'is-violet' ELSE 'is-coral' END;
 
    DECLARE @HTML_HOT_SEGS VARCHAR(MAX) = ISNULL((
        SELECT '<circle class="vct-donut-seg '+COLORCLASS+'" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),PCT)+' '+CONVERT(VARCHAR(10),100-PCT)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-CUM_BEFORE)+'"></circle>'
        FROM #HOT_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    DECLARE @HTML_HOT_LEGEND VARCHAR(MAX) = ISNULL((
        SELECT '<div class="vct-donut-legend-item"><span class="vct-donut-dot '+COLORCLASS+'"></span> '+REPLACE(REPLACE(REPLACE(FORMA_PAGO,'&','&amp;'),'<','&lt;'),'>','&gt;')+' <b>'+FORMAT(MONTO,'C','es-AR')+'</b></div>'
        FROM #HOT_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_HOT_LEGEND=''
        SET @HTML_HOT_LEGEND='<div class="vct-donut-legend-item">Sin datos</div>';
 
    DECLARE @VMAX_HOT_PROV DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(PRECIO_FINAL) S FROM #SEGHOT_BASE GROUP BY PROVEEDOR) X);
    IF @VMAX_HOT_PROV IS NULL OR @VMAX_HOT_PROV=0 SET @VMAX_HOT_PROV=1;
    DECLARE @HTML_HOT_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+FORMAT(SUM(PRECIO_FINAL),'C0','es-AR')+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(PRECIO_FINAL)*100.0/@VMAX_HOT_PROV))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGHOT_BASE
        GROUP BY PROVEEDOR
        ORDER BY SUM(PRECIO_FINAL) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_HOT_BARS=''
        SET @HTML_HOT_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    IF OBJECT_ID('tempdb..#HOT_GANTT') IS NOT NULL DROP TABLE #HOT_GANTT;
    SELECT TOP 5 PROVEEDOR, ESTADIA_DESDE, ESTADIA_HASTA, ROW_NUMBER() OVER (ORDER BY ESTADIA_DESDE) AS RN
    INTO #HOT_GANTT
    FROM #SEGHOT_BASE
    WHERE ESTADIA_DESDE IS NOT NULL AND ESTADIA_HASTA IS NOT NULL
    ORDER BY ESTADIA_DESDE;
 
    DECLARE @VHOT_GANTT_MIN DATETIME = (SELECT MIN(ESTADIA_DESDE) FROM #HOT_GANTT);
    DECLARE @VHOT_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(ESTADIA_DESDE),MAX(ESTADIA_HASTA)) FROM #HOT_GANTT);
    IF @VHOT_GANTT_SPAN IS NULL OR @VHOT_GANTT_SPAN=0 SET @VHOT_GANTT_SPAN=1;
 
    DECLARE @HTML_HOT_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),ESTADIA_DESDE,103)+' - '+CONVERT(VARCHAR(10),ESTADIA_HASTA,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-mint" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VHOT_GANTT_MIN,ESTADIA_DESDE)*100.0/@VHOT_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,ESTADIA_DESDE,ESTADIA_HASTA)*100.0/@VHOT_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,ESTADIA_DESDE,ESTADIA_HASTA)*100.0/@VHOT_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #HOT_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_HOT_GANTT=''
        SET @HTML_HOT_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @HTML_SEGHOT_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGHOT_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,'')+' '+ISNULL(HUESPED,'')+' '+ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td class="vct-text-center" data-label="Estadia Desde" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),ESTADIA_DESDE,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),ESTADIA_DESDE,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Estadia Hasta" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),ESTADIA_HASTA,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),ESTADIA_HASTA,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Nro Factura">'+ISNULL(NRO_FC,'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Factura">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FC,103),'')+'</td>'+
                '<td data-label="Proveedor">'+REPLACE(REPLACE(REPLACE(ISNULL(PROVEEDOR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Tipo Huésped">'+CASE WHEN ISNULL(TIPO_HUESPED,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+TIPO_HUESPED+'">'+TIPO_HUESPED+'</span>' END+'</td>'+
                '<td data-label="Huésped">'+REPLACE(REPLACE(REPLACE(ISNULL(HUESPED,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Servicio">'+CASE WHEN SERVICIO IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Forma Pago">'+CASE WHEN ISNULL(FORMA_PAGO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+FORMA_PAGO+'">'+FORMA_PAGO+'</span>' END+'</td>'+
                '<td data-label="Desc. Forma Pago">'+REPLACE(REPLACE(REPLACE(ISNULL(DESC_FORMA_PAGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Precio Final" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'">'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'</td>'+
                '<td class="vct-text-center" data-label="Cuotas" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'">'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'</td>'+
            '</tr>'
        FROM #SEGHOT_BASE
        ORDER BY ESTADIA_DESDE
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGHOT_ROWS='<tr><td colspan="14" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGHOT_ROWS=''
        SET @HTML_SEGHOT_ROWS='<tr><td colspan="14" class="vct-text-center">Sin hoteles para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       9. SEGUIMIENTO DE PASAJES - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_PASAJES (identica a Hoteles
       salvo TIPO_PROVEEDOR IN ('AVION','MICRO') y una columna "Tipo"
       extra en vez de Estadia Desde/Hasta -- aca solo hay Fecha Pasaje).
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-pasajes'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGPAS_BASE') IS NOT NULL DROP TABLE #SEGPAS_BASE;
    CREATE TABLE #SEGPAS_BASE
    (
        FECHA_PASAJE    DATETIME,
        NRO_FC          VARCHAR(50),
        FECHA_FC        DATETIME,
        TIPO            VARCHAR(100),
        PROVEEDOR       VARCHAR(600),
        TIPO_PASAJERO   VARCHAR(100),
        PASAJERO        VARCHAR(640),
        CLIENTE         VARCHAR(600),
        PROYECTO        VARCHAR(MAX),
        SERVICIO        VARCHAR(400),
        FORMA_PAGO      VARCHAR(100),
        DESC_FORMA_PAGO VARCHAR(600),
        PRECIO_FINAL    DECIMAL(18,2),
        CANT_CUOTAS     INT
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #SEGPAS_BASE (FECHA_PASAJE,NRO_FC,FECHA_FC,TIPO,PROVEEDOR,TIPO_PASAJERO,PASAJERO,CLIENTE,PROYECTO,SERVICIO,FORMA_PAGO,DESC_FORMA_PAGO,PRECIO_FINAL,CANT_CUOTAS)
    SELECT
        V.FECHA_DESDE_SERV,
        V.NRO_FC,
        V.FECHA_FC,
        UPPER(SUBSTRING(V.TIPO_PROVEEDOR,1,1))+LOWER(SUBSTRING(V.TIPO_PROVEEDOR,2,LEN(V.TIPO_PROVEEDOR))),
        CASE WHEN V.ID_PROVEEDOR=9999 THEN V.DESCRIP_SERVICIO ELSE P.RAZON_SOCIAL END,
        UPPER(SUBSTRING(V.TIPO_CONSULTOR,1,1))+LOWER(SUBSTRING(V.TIPO_CONSULTOR,2,LEN(V.TIPO_CONSULTOR))),
        CASE WHEN V.TIPO_CONSULTOR='CONSULTOR' THEN E.APELLIDO_EMPLEADO+', '+E.NOMBRE_EMPLEADO ELSE V.ID_CONSULTOR END,
        C.RAZON_SOCIAL,
        PROY.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        S.DESCRIPCION,
        UPPER(SUBSTRING(V.FORMA_PAGO,1,1))+LOWER(SUBSTRING(V.FORMA_PAGO,2,LEN(V.FORMA_PAGO))),
        V.DESC_FORMA_PAGO,
        V.PRECIO_FINAL,
        V.CANT_CUOTAS
    FROM dbo.LK_PROYECTO_VIATICOS V WITH(NOLOCK)
        INNER JOIN dbo.LK_AGENDA A ON V.ID_AGENDA=A.ID_AGENDA
        INNER JOIN dbo.LK_PROYECTO PROY ON PROY.ID_PROYECTO=A.ID_PROYECTO
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO=A.PROYECTO_SERV_ID
        INNER JOIN dbo.VCT_CLIENTES C ON C.ID=A.ID_CLIENTE
        INNER JOIN dbo.VCT_PRM_SERVICIOS S ON V.ID_TIPO_SERVICIO=S.ID
        LEFT JOIN dbo.VCT_PROVEEDORES P ON V.ID_PROVEEDOR=P.ID_PROVEEDOR
        LEFT JOIN dbo.LK_EMPLEADOS E ON V.ID_CONSULTOR=CONVERT(VARCHAR,E.ID_EMPLEADO)
    WHERE V.TIPO_PROVEEDOR IN ('AVION','MICRO')
      AND V.FECHA_DESDE_SERV>=@VPA_FDESDE_DATE
      AND V.FECHA_HASTA_SERV<=@VPA_FHASTA_DATE;
 
    DECLARE @CNT_SEGPAS INT = (SELECT COUNT(*) FROM #SEGPAS_BASE);
 
    IF OBJECT_ID('tempdb..#PAS_CHART_AGG') IS NOT NULL DROP TABLE #PAS_CHART_AGG;
    SELECT TOP 5
        FORMA_PAGO,
        SUM(PRECIO_FINAL) AS MONTO,
        ROW_NUMBER() OVER (ORDER BY SUM(PRECIO_FINAL) DESC) AS RN
    INTO #PAS_CHART_AGG
    FROM #SEGPAS_BASE
    WHERE ISNULL(FORMA_PAGO,'')<>''
    GROUP BY FORMA_PAGO
    ORDER BY SUM(PRECIO_FINAL) DESC;
 
    DECLARE @VPAS_TOTAL DECIMAL(18,2) = (SELECT ISNULL(SUM(MONTO),0) FROM #PAS_CHART_AGG);
    IF @VPAS_TOTAL=0 SET @VPAS_TOTAL=1;
 
    ALTER TABLE #PAS_CHART_AGG ADD PCT INT, CUM_BEFORE INT, COLORCLASS VARCHAR(20);
    UPDATE #PAS_CHART_AGG SET PCT=CONVERT(INT,MONTO*100.0/@VPAS_TOTAL);
    UPDATE A SET CUM_BEFORE = ISNULL((SELECT SUM(PCT) FROM #PAS_CHART_AGG B WHERE B.RN<A.RN),0)
    FROM #PAS_CHART_AGG A;
    UPDATE #PAS_CHART_AGG SET COLORCLASS =
        CASE RN WHEN 1 THEN 'is-mint' WHEN 2 THEN 'is-amber' WHEN 3 THEN 'is-blue' WHEN 4 THEN 'is-violet' ELSE 'is-coral' END;
 
    DECLARE @HTML_PAS_SEGS VARCHAR(MAX) = ISNULL((
        SELECT '<circle class="vct-donut-seg '+COLORCLASS+'" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),PCT)+' '+CONVERT(VARCHAR(10),100-PCT)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-CUM_BEFORE)+'"></circle>'
        FROM #PAS_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    DECLARE @HTML_PAS_LEGEND VARCHAR(MAX) = ISNULL((
        SELECT '<div class="vct-donut-legend-item"><span class="vct-donut-dot '+COLORCLASS+'"></span> '+REPLACE(REPLACE(REPLACE(FORMA_PAGO,'&','&amp;'),'<','&lt;'),'>','&gt;')+' <b>'+FORMAT(MONTO,'C','es-AR')+'</b></div>'
        FROM #PAS_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PAS_LEGEND=''
        SET @HTML_PAS_LEGEND='<div class="vct-donut-legend-item">Sin datos</div>';
 
    DECLARE @VMAX_PAS_PROV DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(PRECIO_FINAL) S FROM #SEGPAS_BASE GROUP BY PROVEEDOR) X);
    IF @VMAX_PAS_PROV IS NULL OR @VMAX_PAS_PROV=0 SET @VMAX_PAS_PROV=1;
    DECLARE @HTML_PAS_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+FORMAT(SUM(PRECIO_FINAL),'C0','es-AR')+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(PRECIO_FINAL)*100.0/@VMAX_PAS_PROV))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGPAS_BASE
        GROUP BY PROVEEDOR
        ORDER BY SUM(PRECIO_FINAL) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PAS_BARS=''
        SET @HTML_PAS_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* Gantt: Fecha de Pasaje -> Fecha de Factura por pasaje (no hay
       "estadia" en Pasajes como en Hoteles, se usa el par de fechas real
       que si tiene la tabla). */
    IF OBJECT_ID('tempdb..#PAS_GANTT') IS NOT NULL DROP TABLE #PAS_GANTT;
    SELECT TOP 5 PROVEEDOR, FECHA_PASAJE, FECHA_FC, ROW_NUMBER() OVER (ORDER BY FECHA_PASAJE) AS RN
    INTO #PAS_GANTT
    FROM #SEGPAS_BASE
    WHERE FECHA_PASAJE IS NOT NULL AND FECHA_FC IS NOT NULL AND FECHA_FC>=FECHA_PASAJE
    ORDER BY FECHA_PASAJE;
 
    DECLARE @VPAS_GANTT_MIN DATETIME = (SELECT MIN(FECHA_PASAJE) FROM #PAS_GANTT);
    DECLARE @VPAS_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_PASAJE),MAX(FECHA_FC)) FROM #PAS_GANTT);
    IF @VPAS_GANTT_SPAN IS NULL OR @VPAS_GANTT_SPAN=0 SET @VPAS_GANTT_SPAN=1;
 
    DECLARE @HTML_PAS_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_PASAJE,103)+' - '+CONVERT(VARCHAR(10),FECHA_FC,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-violet" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VPAS_GANTT_MIN,FECHA_PASAJE)*100.0/@VPAS_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_PASAJE,FECHA_FC)*100.0/@VPAS_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_PASAJE,FECHA_FC)*100.0/@VPAS_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #PAS_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PAS_GANTT=''
        SET @HTML_PAS_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @HTML_SEGPAS_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGPAS_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,'')+' '+ISNULL(PASAJERO,'')+' '+ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td class="vct-text-center" data-label="Fecha Pasaje" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_PASAJE,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_PASAJE,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Nro Factura">'+ISNULL(NRO_FC,'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Factura">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FC,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Tipo">'+CASE WHEN ISNULL(TIPO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+TIPO+'">'+TIPO+'</span>' END+'</td>'+
                '<td data-label="Proveedor">'+REPLACE(REPLACE(REPLACE(ISNULL(PROVEEDOR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Tipo Pasajero">'+CASE WHEN ISNULL(TIPO_PASAJERO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+TIPO_PASAJERO+'">'+TIPO_PASAJERO+'</span>' END+'</td>'+
                '<td data-label="Pasajero">'+REPLACE(REPLACE(REPLACE(ISNULL(PASAJERO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Servicio">'+CASE WHEN SERVICIO IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Forma Pago">'+CASE WHEN ISNULL(FORMA_PAGO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+FORMA_PAGO+'">'+FORMA_PAGO+'</span>' END+'</td>'+
                '<td data-label="Desc. Forma Pago">'+REPLACE(REPLACE(REPLACE(ISNULL(DESC_FORMA_PAGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Precio Final" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'">'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'</td>'+
                '<td class="vct-text-center" data-label="Cuotas" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'">'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'</td>'+
            '</tr>'
        FROM #SEGPAS_BASE
        ORDER BY FECHA_PASAJE
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGPAS_ROWS='<tr><td colspan="14" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGPAS_ROWS=''
        SET @HTML_SEGPAS_ROWS='<tr><td colspan="14" class="vct-text-center">Sin pasajes para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       10. SEGUIMIENTO DE REMIS/TAXI - CALCULO BASE
       ------------------------------------------------------------
       Misma logica/joins que SV_05_GRD_SEG_REMIS (identica a Hoteles/
       Pasajes salvo TIPO_PROVEEDOR IN ('REMIS','TAXI') y las columnas
       de fecha, que aca son Partida/Llegada).
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-remis'
    BEGIN
    IF OBJECT_ID('tempdb..#SEGREMIS_BASE') IS NOT NULL DROP TABLE #SEGREMIS_BASE;
    CREATE TABLE #SEGREMIS_BASE
    (
        FECHA_PARTIDA   DATETIME,
        FECHA_LLEGADA   DATETIME,
        NRO_FC          VARCHAR(50),
        FECHA_FC        DATETIME,
        TIPO            VARCHAR(100),
        PROVEEDOR       VARCHAR(600),
        TIPO_PASAJERO   VARCHAR(100),
        PASAJERO        VARCHAR(640),
        CLIENTE         VARCHAR(600),
        PROYECTO        VARCHAR(MAX),
        SERVICIO        VARCHAR(400),
        FORMA_PAGO      VARCHAR(100),
        DESC_FORMA_PAGO VARCHAR(600),
        PRECIO_FINAL    DECIMAL(18,2),
        CANT_CUOTAS     INT
    );
 
    IF @VPA_FDESDE_DATE IS NOT NULL AND @VPA_FHASTA_DATE IS NOT NULL AND @VPA_FDESDE_DATE<=@VPA_FHASTA_DATE
    INSERT INTO #SEGREMIS_BASE (FECHA_PARTIDA,FECHA_LLEGADA,NRO_FC,FECHA_FC,TIPO,PROVEEDOR,TIPO_PASAJERO,PASAJERO,CLIENTE,PROYECTO,SERVICIO,FORMA_PAGO,DESC_FORMA_PAGO,PRECIO_FINAL,CANT_CUOTAS)
    SELECT
        V.FECHA_DESDE_SERV,
        V.FECHA_HASTA_SERV,
        V.NRO_FC,
        V.FECHA_FC,
        UPPER(SUBSTRING(V.TIPO_PROVEEDOR,1,1))+LOWER(SUBSTRING(V.TIPO_PROVEEDOR,2,LEN(V.TIPO_PROVEEDOR))),
        CASE WHEN V.ID_PROVEEDOR=9999 THEN V.DESCRIP_SERVICIO ELSE P.RAZON_SOCIAL END,
        UPPER(SUBSTRING(V.TIPO_CONSULTOR,1,1))+LOWER(SUBSTRING(V.TIPO_CONSULTOR,2,LEN(V.TIPO_CONSULTOR))),
        CASE WHEN V.TIPO_CONSULTOR='CONSULTOR' THEN E.APELLIDO_EMPLEADO+', '+E.NOMBRE_EMPLEADO ELSE V.ID_CONSULTOR END,
        C.RAZON_SOCIAL,
        PROY.NORMA_REF+' - '+ISNULL(PS.NOMBRE,''),
        S.DESCRIPCION,
        UPPER(SUBSTRING(V.FORMA_PAGO,1,1))+LOWER(SUBSTRING(V.FORMA_PAGO,2,LEN(V.FORMA_PAGO))),
        V.DESC_FORMA_PAGO,
        V.PRECIO_FINAL,
        V.CANT_CUOTAS
    FROM dbo.LK_PROYECTO_VIATICOS V WITH(NOLOCK)
        INNER JOIN dbo.LK_AGENDA A ON V.ID_AGENDA=A.ID_AGENDA
        INNER JOIN dbo.LK_PROYECTO PROY ON PROY.ID_PROYECTO=A.ID_PROYECTO
        INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO=A.PROYECTO_SERV_ID
        INNER JOIN dbo.VCT_CLIENTES C ON C.ID=A.ID_CLIENTE
        INNER JOIN dbo.VCT_PRM_SERVICIOS S ON V.ID_TIPO_SERVICIO=S.ID
        LEFT JOIN dbo.VCT_PROVEEDORES P ON V.ID_PROVEEDOR=P.ID_PROVEEDOR
        LEFT JOIN dbo.LK_EMPLEADOS E ON V.ID_CONSULTOR=CONVERT(VARCHAR,E.ID_EMPLEADO)
    WHERE V.TIPO_PROVEEDOR IN ('REMIS','TAXI')
      AND V.FECHA_DESDE_SERV>=@VPA_FDESDE_DATE
      AND V.FECHA_HASTA_SERV<=@VPA_FHASTA_DATE;
 
    DECLARE @CNT_SEGREMIS INT = (SELECT COUNT(*) FROM #SEGREMIS_BASE);
 
    IF OBJECT_ID('tempdb..#REMIS_CHART_AGG') IS NOT NULL DROP TABLE #REMIS_CHART_AGG;
    SELECT TOP 5
        FORMA_PAGO,
        SUM(PRECIO_FINAL) AS MONTO,
        ROW_NUMBER() OVER (ORDER BY SUM(PRECIO_FINAL) DESC) AS RN
    INTO #REMIS_CHART_AGG
    FROM #SEGREMIS_BASE
    WHERE ISNULL(FORMA_PAGO,'')<>''
    GROUP BY FORMA_PAGO
    ORDER BY SUM(PRECIO_FINAL) DESC;
 
    DECLARE @VREMIS_TOTAL DECIMAL(18,2) = (SELECT ISNULL(SUM(MONTO),0) FROM #REMIS_CHART_AGG);
    IF @VREMIS_TOTAL=0 SET @VREMIS_TOTAL=1;
 
    ALTER TABLE #REMIS_CHART_AGG ADD PCT INT, CUM_BEFORE INT, COLORCLASS VARCHAR(20);
    UPDATE #REMIS_CHART_AGG SET PCT=CONVERT(INT,MONTO*100.0/@VREMIS_TOTAL);
    UPDATE A SET CUM_BEFORE = ISNULL((SELECT SUM(PCT) FROM #REMIS_CHART_AGG B WHERE B.RN<A.RN),0)
    FROM #REMIS_CHART_AGG A;
    UPDATE #REMIS_CHART_AGG SET COLORCLASS =
        CASE RN WHEN 1 THEN 'is-mint' WHEN 2 THEN 'is-amber' WHEN 3 THEN 'is-blue' WHEN 4 THEN 'is-violet' ELSE 'is-coral' END;
 
    DECLARE @HTML_REMIS_SEGS VARCHAR(MAX) = ISNULL((
        SELECT '<circle class="vct-donut-seg '+COLORCLASS+'" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),PCT)+' '+CONVERT(VARCHAR(10),100-PCT)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-CUM_BEFORE)+'"></circle>'
        FROM #REMIS_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    DECLARE @HTML_REMIS_LEGEND VARCHAR(MAX) = ISNULL((
        SELECT '<div class="vct-donut-legend-item"><span class="vct-donut-dot '+COLORCLASS+'"></span> '+REPLACE(REPLACE(REPLACE(FORMA_PAGO,'&','&amp;'),'<','&lt;'),'>','&gt;')+' <b>'+FORMAT(MONTO,'C','es-AR')+'</b></div>'
        FROM #REMIS_CHART_AGG ORDER BY RN FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_REMIS_LEGEND=''
        SET @HTML_REMIS_LEGEND='<div class="vct-donut-legend-item">Sin datos</div>';
 
    DECLARE @VMAX_REMIS_PROV DECIMAL(18,2) = (SELECT MAX(S) FROM (SELECT SUM(PRECIO_FINAL) S FROM #SEGREMIS_BASE GROUP BY PROVEEDOR) X);
    IF @VMAX_REMIS_PROV IS NULL OR @VMAX_REMIS_PROV=0 SET @VMAX_REMIS_PROV=1;
    DECLARE @HTML_REMIS_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+FORMAT(SUM(PRECIO_FINAL),'C0','es-AR')+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,SUM(PRECIO_FINAL)*100.0/@VMAX_REMIS_PROV))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #SEGREMIS_BASE
        GROUP BY PROVEEDOR
        ORDER BY SUM(PRECIO_FINAL) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_REMIS_BARS=''
        SET @HTML_REMIS_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    IF OBJECT_ID('tempdb..#REMIS_GANTT') IS NOT NULL DROP TABLE #REMIS_GANTT;
    SELECT TOP 5 PROVEEDOR, FECHA_PARTIDA, FECHA_LLEGADA, ROW_NUMBER() OVER (ORDER BY FECHA_PARTIDA) AS RN
    INTO #REMIS_GANTT
    FROM #SEGREMIS_BASE
    WHERE FECHA_PARTIDA IS NOT NULL AND FECHA_LLEGADA IS NOT NULL AND FECHA_LLEGADA>=FECHA_PARTIDA
    ORDER BY FECHA_PARTIDA;
 
    DECLARE @VREMIS_GANTT_MIN DATETIME = (SELECT MIN(FECHA_PARTIDA) FROM #REMIS_GANTT);
    DECLARE @VREMIS_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(FECHA_PARTIDA),MAX(FECHA_LLEGADA)) FROM #REMIS_GANTT);
    IF @VREMIS_GANTT_SPAN IS NULL OR @VREMIS_GANTT_SPAN=0 SET @VREMIS_GANTT_SPAN=1;
 
    DECLARE @HTML_REMIS_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROVEEDOR,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),FECHA_PARTIDA,103)+' - '+CONVERT(VARCHAR(10),FECHA_LLEGADA,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-amber" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VREMIS_GANTT_MIN,FECHA_PARTIDA)*100.0/@VREMIS_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,FECHA_PARTIDA,FECHA_LLEGADA)*100.0/@VREMIS_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,FECHA_PARTIDA,FECHA_LLEGADA)*100.0/@VREMIS_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #REMIS_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_REMIS_GANTT=''
        SET @HTML_REMIS_GANTT='<div class="vct-gantt-empty">Sin datos en el período</div>';
 
    DECLARE @HTML_SEGREMIS_ROWS VARCHAR(MAX)='';
    SELECT @HTML_SEGREMIS_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,'')+' '+ISNULL(PASAJERO,'')+' '+ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td class="vct-text-center" data-label="Fecha Partida" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_PARTIDA,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_PARTIDA,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Llegada" data-vct-sort-value="'+ISNULL(CONVERT(VARCHAR(8),FECHA_LLEGADA,112),'')+'">'+ISNULL(CONVERT(VARCHAR(10),FECHA_LLEGADA,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Nro Factura">'+ISNULL(NRO_FC,'')+'</td>'+
                '<td class="vct-text-center" data-label="Fecha Factura">'+ISNULL(CONVERT(VARCHAR(10),FECHA_FC,103),'')+'</td>'+
                '<td class="vct-text-center" data-label="Tipo">'+CASE WHEN ISNULL(TIPO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+TIPO+'">'+TIPO+'</span>' END+'</td>'+
                '<td data-label="Proveedor">'+REPLACE(REPLACE(REPLACE(ISNULL(PROVEEDOR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Tipo Pasajero">'+CASE WHEN ISNULL(TIPO_PASAJERO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+TIPO_PASAJERO+'">'+TIPO_PASAJERO+'</span>' END+'</td>'+
                '<td data-label="Pasajero">'+REPLACE(REPLACE(REPLACE(ISNULL(PASAJERO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Servicio">'+CASE WHEN SERVICIO IS NULL THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+REPLACE(REPLACE(REPLACE(SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>' END+'</td>'+
                '<td class="vct-text-center" data-label="Forma Pago">'+CASE WHEN ISNULL(FORMA_PAGO,'')='' THEN '' ELSE '<span class="vct-badge" data-vct-badge="'+FORMA_PAGO+'">'+FORMA_PAGO+'</span>' END+'</td>'+
                '<td data-label="Desc. Forma Pago">'+REPLACE(REPLACE(REPLACE(ISNULL(DESC_FORMA_PAGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Precio Final" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'">'+CONVERT(VARCHAR(20),ISNULL(PRECIO_FINAL,0))+'</td>'+
                '<td class="vct-text-center" data-label="Cuotas" data-vct-sort-value="'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'">'+CONVERT(VARCHAR(20),ISNULL(CANT_CUOTAS,0))+'</td>'+
            '</tr>'
        FROM #SEGREMIS_BASE
        ORDER BY FECHA_PARTIDA
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @VPA_FDESDE_DATE IS NULL OR @VPA_FHASTA_DATE IS NULL OR @VPA_FDESDE_DATE>@VPA_FHASTA_DATE
        SET @HTML_SEGREMIS_ROWS='<tr><td colspan="15" class="vct-text-center">La fecha desde debe ser igual o anterior a la fecha hasta.</td></tr>';
    ELSE IF @HTML_SEGREMIS_ROWS=''
        SET @HTML_SEGREMIS_ROWS='<tr><td colspan="15" class="vct-text-center">Sin viajes de remis/taxi para el período seleccionado.</td></tr>';
    END
 
    /* ============================================================
       11. RENTABILIDAD PROYECTOS - CALCULO BASE
       ------------------------------------------------------------
       Se porta SV_05_GRD_RENTABILIDAD (grilla) al patron moderno.
       El dashboard de graficos con Chart.js de SV_05_INI_GRAF_RENTA
       (tarjetas por proyecto con canvas + export a PDF individual/
       global) NO se porta en esta v1: es un componente muy distinto
       (cursor + Chart.js + ventanas de impresion propias) al resto de
       Reportes, que en esta modernizacion son todas grillas. La grilla
       ya trae los mismos datos (estimado/real/margen/desviacion por
       proyecto), asi que no se pierde informacion, solo la
       visualizacion en tarjetas+grafico de barras. Si se quiere ese
       dashboard especifico despues, conviene tratarlo aparte.
       Filtros propios (Cliente/Periodo/Estado -- TEXTO08/09/10), sin
       relacion con el Fecha Desde/Hasta compartido de los demas
       reportes (el original tampoco lo usaba en el WHERE real).
       ============================================================ */
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='rentabilidad'
    BEGIN
    IF OBJECT_ID('tempdb..#RENTA_BASE') IS NOT NULL DROP TABLE #RENTA_BASE;
    CREATE TABLE #RENTA_BASE
    (
        CLIENTE           VARCHAR(600),
        PROYECTO          VARCHAR(MAX),
        PRESUPUESTO       DECIMAL(18,2),
        COSTO_ESTIM       DECIMAL(18,2),
        UTILIDAD_ESTIM    DECIMAL(18,2),
        MARGEN_ESTIM      DECIMAL(10,2),
        VENTAS_ACUM       DECIMAL(18,2),
        COMPRAS_ACUM      DECIMAL(18,2),
        UTILIDAD_REAL     DECIMAL(18,2),
        MARGEN_REAL       DECIMAL(10,2),
        DESVIACION_MARGEN DECIMAL(10,2),
        PERIODO           VARCHAR(50)
    );
 
    IF @PUEDE_VER_RENTABILIDAD=1
    INSERT INTO #RENTA_BASE (CLIENTE,PROYECTO,PRESUPUESTO,COSTO_ESTIM,UTILIDAD_ESTIM,MARGEN_ESTIM,VENTAS_ACUM,COMPRAS_ACUM,UTILIDAD_REAL,MARGEN_REAL,DESVIACION_MARGEN,PERIODO)
    SELECT
        C.RAZON_SOCIAL,
        '('+CONVERT(VARCHAR,P.CODIGO)+') - '+P.NORMA_REF,
        ISNULL(P.MONTO_TOTAL,0),
        ISNULL(P.COSTO_TOTAL,0),
        ISNULL(P.MONTO_TOTAL,0)-ISNULL(P.COSTO_TOTAL,0),
        CASE WHEN ISNULL(P.MONTO_TOTAL,0)>0 THEN CAST((ISNULL(P.MONTO_TOTAL,0)-ISNULL(P.COSTO_TOTAL,0))*100.0/P.MONTO_TOTAL AS DECIMAL(10,2)) ELSE 0 END,
        ISNULL(R.TotalVentasReales,0),
        ISNULL(R.TotalComprasReales,0),
        ISNULL(R.TotalVentasReales,0)-ISNULL(R.TotalComprasReales,0),
        CASE WHEN ISNULL(R.TotalVentasReales,0)>0 THEN CAST((ISNULL(R.TotalVentasReales,0)-ISNULL(R.TotalComprasReales,0))*100.0/R.TotalVentasReales AS DECIMAL(10,2)) ELSE 0 END,
        CASE WHEN ISNULL(R.TotalVentasReales,0)>0 AND ISNULL(P.MONTO_TOTAL,0)>0
             THEN CAST(((ISNULL(R.TotalVentasReales,0)-ISNULL(R.TotalComprasReales,0))*100.0/R.TotalVentasReales)
                       -((ISNULL(P.MONTO_TOTAL,0)-ISNULL(P.COSTO_TOTAL,0))*100.0/P.MONTO_TOTAL) AS DECIMAL(10,2))
             ELSE 0 END,
        ISNULL(R.UltimoPeriodo,'')
    FROM dbo.LK_PROYECTO P WITH(NOLOCK)
        INNER JOIN dbo.VCT_CLIENTES C ON P.ID_CLIENTE=C.ID
        LEFT JOIN (
            SELECT PR.ID_PROYECTO, SUM(ISNULL(PR.VENTAS,0)) TotalVentasReales, SUM(ISNULL(PR.COMPRAS,0)) TotalComprasReales, MAX(PR.PERIODO) UltimoPeriodo
            FROM dbo.VCT_PROYECTOS_RENTABILIDAD PR WITH(NOLOCK)
            WHERE @VRENTA_PERIODO='' OR PR.PERIODO<=@VRENTA_PERIODO
            GROUP BY PR.ID_PROYECTO
        ) R ON P.ID_PROYECTO=R.ID_PROYECTO
    WHERE (@VRENTA_CLIENTE='' OR CONVERT(VARCHAR,P.ID_CLIENTE)=@VRENTA_CLIENTE)
      AND (@VRENTA_ESTADO=''  OR P.ESTADO_PROYECTO_TOTAL=@VRENTA_ESTADO)
      AND (@VRENTA_PERIODO='' OR R.ID_PROYECTO IS NOT NULL);
 
    DECLARE @CNT_RENTA INT = (SELECT COUNT(*) FROM #RENTA_BASE);
 
    DECLARE @VTOTAL_VENTAS_RENTA DECIMAL(18,2), @VTOTAL_COMPRAS_RENTA DECIMAL(18,2);
    SELECT @VTOTAL_VENTAS_RENTA = SUM(VENTAS_ACUM), @VTOTAL_COMPRAS_RENTA = SUM(COMPRAS_ACUM) FROM #RENTA_BASE;
    SET @VTOTAL_VENTAS_RENTA = ISNULL(@VTOTAL_VENTAS_RENTA,0);
    SET @VTOTAL_COMPRAS_RENTA = ISNULL(@VTOTAL_COMPRAS_RENTA,0);
    DECLARE @VTOTAL_UTILIDAD_RENTA DECIMAL(18,2) = @VTOTAL_VENTAS_RENTA-@VTOTAL_COMPRAS_RENTA;
    DECLARE @VPCT_MARGEN_RENTA INT = CASE WHEN @VTOTAL_VENTAS_RENTA=0 THEN 0
                                           WHEN @VTOTAL_UTILIDAD_RENTA*100.0/@VTOTAL_VENTAS_RENTA>100 THEN 100
                                           WHEN @VTOTAL_UTILIDAD_RENTA*100.0/@VTOTAL_VENTAS_RENTA<0 THEN 0
                                           ELSE CONVERT(INT,@VTOTAL_UTILIDAD_RENTA*100.0/@VTOTAL_VENTAS_RENTA) END;
 
    /* Barras: Top 5 proyectos por utilidad real acumulada. */
    DECLARE @VMAX_RENTA_UTIL DECIMAL(18,2) = (SELECT MAX(UTILIDAD_REAL) FROM #RENTA_BASE);
    IF @VMAX_RENTA_UTIL IS NULL OR @VMAX_RENTA_UTIL<=0 SET @VMAX_RENTA_UTIL=1;
    DECLARE @HTML_RENTA_BARS VARCHAR(MAX) = ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+FORMAT(UTILIDAD_REAL,'C0','es-AR')+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CASE WHEN UTILIDAD_REAL<0 THEN 0 ELSE CONVERT(INT,UTILIDAD_REAL*100.0/@VMAX_RENTA_UTIL) END)+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM #RENTA_BASE
        ORDER BY UTILIDAD_REAL DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_RENTA_BARS=''
        SET @HTML_RENTA_BARS='<div class="vct-gantt-empty">Sin datos</div>';
 
    /* Gantt: el reporte no tiene fecha inicio/fin, solo PERIODO (AAAAMM)
       -- se usa ese mes calendario como rango (1ro al ultimo dia) para
       los 5 proyectos con periodo mas reciente. */
    IF OBJECT_ID('tempdb..#RENTA_GANTT') IS NOT NULL DROP TABLE #RENTA_GANTT;
    SELECT TOP 5
        PROYECTO,
        CONVERT(DATETIME,LEFT(PERIODO,4)+'-'+SUBSTRING(PERIODO,5,2)+'-01') AS MES_INI,
        DATEADD(DAY,-1,DATEADD(MONTH,1,CONVERT(DATETIME,LEFT(PERIODO,4)+'-'+SUBSTRING(PERIODO,5,2)+'-01'))) AS MES_FIN,
        ROW_NUMBER() OVER (ORDER BY PERIODO DESC) AS RN
    INTO #RENTA_GANTT
    FROM #RENTA_BASE
    WHERE ISNULL(PERIODO,'')<>'' AND LEN(PERIODO)=6 AND ISNUMERIC(PERIODO)=1
    ORDER BY PERIODO DESC;
 
    DECLARE @VRENTA_GANTT_MIN DATETIME = (SELECT MIN(MES_INI) FROM #RENTA_GANTT);
    DECLARE @VRENTA_GANTT_SPAN INT = (SELECT DATEDIFF(DAY,MIN(MES_INI),MAX(MES_FIN)) FROM #RENTA_GANTT);
    IF @VRENTA_GANTT_SPAN IS NULL OR @VRENTA_GANTT_SPAN=0 SET @VRENTA_GANTT_SPAN=1;
 
    DECLARE @HTML_RENTA_GANTT VARCHAR(MAX) = ISNULL((
        SELECT
            '<div><div class="vct-gantt-row-head"><span>'+REPLACE(REPLACE(REPLACE(PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span><span>'+CONVERT(VARCHAR(10),MES_INI,103)+' - '+CONVERT(VARCHAR(10),MES_FIN,103)+'</span></div><div class="vct-gantt-track"><div class="vct-gantt-bar is-mint" style="left:'+CONVERT(VARCHAR(10),CONVERT(INT,DATEDIFF(DAY,@VRENTA_GANTT_MIN,MES_INI)*100.0/@VRENTA_GANTT_SPAN))+'%;width:'+CONVERT(VARCHAR(10),CASE WHEN CONVERT(INT,DATEDIFF(DAY,MES_INI,MES_FIN)*100.0/@VRENTA_GANTT_SPAN)<2 THEN 2 ELSE CONVERT(INT,DATEDIFF(DAY,MES_INI,MES_FIN)*100.0/@VRENTA_GANTT_SPAN) END)+'%;"></div></div></div>'
        FROM #RENTA_GANTT
        ORDER BY RN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_RENTA_GANTT=''
        SET @HTML_RENTA_GANTT='<div class="vct-gantt-empty">Sin período cargado</div>';
 
    DECLARE @HTML_RENTA_ROWS VARCHAR(MAX)='';
    SELECT @HTML_RENTA_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row data-vct-search="'+
                REPLACE(REPLACE(REPLACE(CLIENTE+' '+PROYECTO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
                '<td data-label="Cliente">'+REPLACE(REPLACE(REPLACE(ISNULL(CLIENTE,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td data-label="Proyecto">'+REPLACE(REPLACE(REPLACE(ISNULL(PROYECTO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
                '<td class="vct-text-center" data-label="Presupuesto" data-vct-sort-value="'+CONVERT(VARCHAR(20),PRESUPUESTO)+'">'+FORMAT(PRESUPUESTO,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Costo Estim." data-vct-sort-value="'+CONVERT(VARCHAR(20),COSTO_ESTIM)+'">'+FORMAT(COSTO_ESTIM,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Utilidad Estim." data-vct-sort-value="'+CONVERT(VARCHAR(20),UTILIDAD_ESTIM)+'">'+FORMAT(UTILIDAD_ESTIM,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Margen Estim." data-vct-sort-value="'+CONVERT(VARCHAR(20),MARGEN_ESTIM)+'">'+CONVERT(VARCHAR(20),MARGEN_ESTIM)+'%</td>'+
                '<td class="vct-text-center" data-label="Ventas Acum." data-vct-sort-value="'+CONVERT(VARCHAR(20),VENTAS_ACUM)+'">'+FORMAT(VENTAS_ACUM,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Compras Acum." data-vct-sort-value="'+CONVERT(VARCHAR(20),COMPRAS_ACUM)+'">'+FORMAT(COMPRAS_ACUM,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Utilidad Real Acum." data-vct-sort-value="'+CONVERT(VARCHAR(20),UTILIDAD_REAL)+'">'+FORMAT(UTILIDAD_REAL,'C','es-AR')+'</td>'+
                '<td class="vct-text-center" data-label="Margen Real Acum." data-vct-sort-value="'+CONVERT(VARCHAR(20),MARGEN_REAL)+'">'+CONVERT(VARCHAR(20),MARGEN_REAL)+'%</td>'+
                '<td class="vct-text-center" data-label="Desviación Margen" data-vct-sort-value="'+CONVERT(VARCHAR(20),DESVIACION_MARGEN)+'">'+
                    CASE WHEN DESVIACION_MARGEN>=0 THEN '<span style="color:#059669;">+'+CONVERT(VARCHAR(20),DESVIACION_MARGEN)+'%</span>'
                         ELSE '<span style="color:#DC2626;">'+CONVERT(VARCHAR(20),DESVIACION_MARGEN)+'%</span>' END+
                '</td>'+
                '<td class="vct-text-center" data-label="Período">'+ISNULL(PERIODO,'')+'</td>'+
            '</tr>'
        FROM #RENTA_BASE
        ORDER BY CLIENTE, PROYECTO
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @PUEDE_VER_RENTABILIDAD=0
        SET @HTML_RENTA_ROWS='<tr><td colspan="12" class="vct-text-center">No tiene permisos para ver este reporte.</td></tr>';
    ELSE IF @HTML_RENTA_ROWS=''
        SET @HTML_RENTA_ROWS='<tr><td colspan="12" class="vct-text-center">Sin proyectos para los filtros seleccionados.</td></tr>';
    END
 
    DECLARE @HTML_RENTA_CLIENTES VARCHAR(MAX)='';
    IF @PUEDE_VER_RENTABILIDAD=1
    SELECT @HTML_RENTA_CLIENTES = ISNULL((
        SELECT '<option value="'+CONVERT(VARCHAR(20),ID)+'"'+
               CASE WHEN CONVERT(VARCHAR(20),ID)=@VRENTA_CLIENTE THEN ' selected' ELSE '' END+
               '>'+REPLACE(REPLACE(REPLACE(RAZON_SOCIAL,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM dbo.VCT_CLIENTES WITH(NOLOCK)
        ORDER BY RAZON_SOCIAL
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    DECLARE @HTML_RENTA_ESTADOS VARCHAR(MAX)='';
    IF @PUEDE_VER_RENTABILIDAD=1
    SELECT @HTML_RENTA_ESTADOS = ISNULL((
        SELECT '<option value="'+REPLACE(REPLACE(REPLACE(ESTADO_PROYECTO_TOTAL,'&','&amp;'),'<','&lt;'),'>','&gt;')+'"'+
               CASE WHEN ESTADO_PROYECTO_TOTAL=@VRENTA_ESTADO THEN ' selected' ELSE '' END+
               '>'+REPLACE(REPLACE(REPLACE(ESTADO_PROYECTO_TOTAL,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM (SELECT DISTINCT ESTADO_PROYECTO_TOTAL FROM dbo.LK_PROYECTO WITH(NOLOCK) WHERE ESTADO_PROYECTO_TOTAL IS NOT NULL) X
        ORDER BY ESTADO_PROYECTO_TOTAL
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* ============================================================
       12. HTML - GRUPOS + PANELES
       ============================================================ */
    DECLARE @HTML_FECHA_FILTRO_COMPARTIDO VARCHAR(MAX)=
        '<div class="vct-reports-filters">'+
            '<input type="date" class="vct-input" name="SP.TEXTO03" data-vct-field="TEXTO03" value="'+@VPA_FDESDE+'" aria-label="Fecha Desde" title="Fecha Desde" autocomplete="off">'+
            '<input type="date" class="vct-input" name="SP.TEXTO04" data-vct-field="TEXTO04" value="'+@VPA_FHASTA+'" aria-label="Fecha Hasta" title="Fecha Hasta" autocomplete="off">'+
            '<button type="button" class="vct-hidden" data-vct-command="validate-next" aria-hidden="true" tabindex="-1"></button>'+
        '</div>';
 
    DECLARE @HTML_PANEL_SEG_CONSULTORIA VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-consultoria'
    SET @HTML_PANEL_SEG_CONSULTORIA=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="briefcase"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Consultorías</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_CONS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clock-3"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Proyectadas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_CONS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="calendar-days"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Ejecutadas Período</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_CONS)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-consultoria">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Consultoría</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-consultoria"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">% de Avance</div>'+
                                    '<div class="vct-donut-row">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_CONS)+' '+CONVERT(VARCHAR(10),100-@VPCT_CONS)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_CONS)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-legend">'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Hs Ejecutadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_CONS)+'</b></div>'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Hs Proyectadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_CONS)+'</b></div>'+
                                        '</div>'+
                                    '</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Cronograma (Top 5 por Fecha Inicio)</div>'+
                                    '<div class="vct-gantt">'+@HTML_CONS_GANTT+'</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Top 5 clientes por Hs Ejecutadas</div>'+
                                    '<div class="vct-barchart">'+@HTML_CONS_BARS+'</div>'+
                                '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-consultoria" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Consultoría" '+
                     'data-vct-dg-subtitle="Estado y avance de los proyectos de consultoría." data-vct-dg-unit="consultoría(s)" data-vct-dg-search-placeholder="Buscar cliente, proyecto o consultor..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-consultoria">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="briefcase"></span> Seguimiento de Consultoría</h2>'+
                            '<p class="vct-card-subtitle">Estado y avance de los proyectos de consultoría.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-consultoria">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-truncate="1" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_inicio" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_fin" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1">Personal Afectado</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="hs_proy" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Proy.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="hs_ejec" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Ejec. Período</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="pct_avance" data-vct-sort-type="number" data-vct-sortable="true"><span>% Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-col-sm">Frec. Envío Plan</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Plan Estratégico</th>'+
                                '<th data-vct-truncate="1">Observaciones</th>'+
                                '<th data-vct-width="11%" class="vct-text-center vct-col-md">Cierre</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGCONS_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_SEG_AUDITORIA VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-auditoria'
    SET @HTML_PANEL_SEG_AUDITORIA=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clipboard-check"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Auditorías</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_AUDI)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clock-3"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Proyectadas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_AUDI)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="calendar-days"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Ejecutadas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_AUDI)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-auditoria">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Auditoría</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-auditoria"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">% de Avance</div>'+
                                    '<div class="vct-donut-row">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-amber" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_AUDI)+' '+CONVERT(VARCHAR(10),100-@VPCT_AUDI)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_AUDI)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-legend">'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-amber"></span> Hs Ejecutadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_AUDI)+'</b></div>'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Hs Proyectadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_AUDI)+'</b></div>'+
                                        '</div>'+
                                    '</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Cronograma (Top 5 por Fecha Inicio)</div>'+
                                    '<div class="vct-gantt">'+@HTML_AUDI_GANTT+'</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Top 5 clientes por Hs Ejecutadas</div>'+
                                    '<div class="vct-barchart">'+@HTML_AUDI_BARS+'</div>'+
                                '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-auditoria" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Auditoría" '+
                     'data-vct-dg-subtitle="Estado y avance de las auditorías en curso." data-vct-dg-unit="auditoría(s)" data-vct-dg-search-placeholder="Buscar cliente, proyecto o auditor..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-auditoria">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="clipboard-check"></span> Seguimiento de Auditoría</h2>'+
                            '<p class="vct-card-subtitle">Estado y avance de las auditorías en curso.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-auditoria">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-truncate="1" data-vct-sort="nombre" data-vct-sortable="true"><span>Nombre</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-col-sm">Lugar</th>'+
                                '<th data-vct-truncate="1" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_inicio" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_fin" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1">Auditores</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="dias_auditor" data-vct-sort-type="number" data-vct-sortable="true"><span>Días Auditor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="hs_proy" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Proyectadas</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="hs_ejec" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Ejecutadas</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="pct_avance" data-vct-sort-type="number" data-vct-sortable="true"><span>% Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Plan Auditoría</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha PA</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Informe</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha Inf.</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Tiempo Inf.</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGAUDI_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_SEG_CAPACITACION VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-capacitacion'
    SET @HTML_PANEL_SEG_CAPACITACION=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="file-text"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Capacitaciones</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_CAPA)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clock-3"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Proyectadas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_CAPA)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="calendar-days"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Hs Ejecutadas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_CAPA)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-capacitacion">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Capacitación</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-capacitacion"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">% de Avance</div>'+
                                    '<div class="vct-donut-row">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-blue" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_CAPA)+' '+CONVERT(VARCHAR(10),100-@VPCT_CAPA)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_CAPA)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-legend">'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-blue"></span> Hs Ejecutadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_EJEC_CAPA)+'</b></div>'+
                                            '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Hs Proyectadas <b>'+CONVERT(VARCHAR(20),@VTOTAL_HS_PROY_CAPA)+'</b></div>'+
                                        '</div>'+
                                    '</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Cronograma (Top 5 por Fecha Inicio)</div>'+
                                    '<div class="vct-gantt">'+@HTML_CAPA_GANTT+'</div>'+
                                '</div>'+
                                '<div class="vct-report-chart">'+
                                    '<div class="vct-report-chart-title">Top 5 clientes por Hs Ejecutadas</div>'+
                                    '<div class="vct-barchart">'+@HTML_CAPA_BARS+'</div>'+
                                '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-capacitacion" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Capacitación" '+
                     'data-vct-dg-subtitle="Estado y avance de las capacitaciones dictadas." data-vct-dg-unit="capacitación(es)" data-vct-dg-search-placeholder="Buscar cliente, proyecto o curso..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-capacitacion">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="file-text"></span> Seguimiento de Capacitación</h2>'+
                            '<p class="vct-card-subtitle">Estado y avance de las capacitaciones dictadas.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-capacitacion">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-truncate="1" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="11%" data-vct-truncate="1" class="vct-col-md">Curso</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_inicio" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_fin" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1">Instructores</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="hs_proy" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Proyectadas</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="hs_ejec" data-vct-sort-type="number" data-vct-sortable="true"><span>Hs Ejecutadas</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="pct_avance" data-vct-sort-type="number" data-vct-sortable="true"><span>% Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Material</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Estado Envío</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Recibido</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Informe</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha Inf.</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Tiempo Inf.</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGCAPA_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_CALIF_CONSULTORES VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='calif-consultores'
    SET @HTML_PANEL_CALIF_CONSULTORES=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="star"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Registros</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_CALIFCONS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="user-minus"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Eventuales</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VCALIF_EVENTUALES)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="check"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Con Aptitud Activa</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VCALIF_APTITUD_ACTIVA)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-calif-consultores">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Calificación Consultores</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-calif-consultores"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Consultores por calificación</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        @HTML_CALIF_SEGS+
                                        '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(20),@VCALIF_TOTAL)+'</text>'+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+@HTML_CALIF_LEGEND+'</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 aptitudes por cantidad</div>'+
                                '<div class="vct-barchart">'+@HTML_CALIF_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Cronograma</div>'+
                                '<div class="vct-gantt"><div class="vct-gantt-empty">Este reporte no tiene fecha de referencia por consultor</div></div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-calif-consultores" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Calificación Consultores" '+
                     'data-vct-dg-subtitle="Evaluaciones y puntajes de los consultores." data-vct-dg-unit="registro(s)" data-vct-dg-search-placeholder="Buscar consultor, aptitud o servicio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-calif-consultores">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="star"></span> Calificación Consultores</h2>'+
                            '<p class="vct-card-subtitle">Evaluaciones y puntajes de los consultores.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="calif-consultores">'+
                                '<div class="vct-reports-filters">'+
                                    '<select class="vct-select" name="SP.TEXTO05" data-vct-field="TEXTO05" aria-label="Aptitud" title="Aptitud"><option value="">Aptitud (todas)</option>'+@HTML_CC_APTITUDES+'</select>'+
                                    '<select class="vct-select" name="SP.TEXTO06" data-vct-field="TEXTO06" aria-label="Servicio" title="Servicio"><option value="">Servicio (todos)</option>'+@HTML_CC_TIPOSERV+'</select>'+
                                    '<select class="vct-select" name="SP.TEXTO07" data-vct-field="TEXTO07" aria-label="Calificación" title="Calificación"><option value="">Calificación (todas)</option>'+@HTML_CC_CALIF+'</select>'+
                                    '<button type="button" class="vct-hidden" data-vct-command="validate-next" aria-hidden="true" tabindex="-1"></button>'+
                                '</div>'+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-sort="consultor" data-vct-sortable="true"><span>Consultor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-sort="aptitud" data-vct-sortable="true"><span>Aptitud</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="tipo_servicio" data-vct-sortable="true"><span>Tipo Servicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="calificacion" data-vct-sortable="true"><span>Calificación</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_CALIFCONS_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_SEG_HOTELES VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-hoteles'
    SET @HTML_PANEL_SEG_HOTELES=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="home"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Reservas</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_SEGHOT)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-red">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="circle-dollar-sign"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Gasto Total</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VHOT_TOTAL,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-bar"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Promedio por Reserva</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(CASE WHEN @CNT_SEGHOT=0 THEN 0 ELSE @VHOT_TOTAL/@CNT_SEGHOT END,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-hoteles">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Hoteles</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-hoteles"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Gasto por forma de pago</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        @HTML_HOT_SEGS+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+@HTML_HOT_LEGEND+'</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 proveedores por gasto</div>'+
                                '<div class="vct-barchart">'+@HTML_HOT_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Estadías (Top 5)</div>'+
                                '<div class="vct-gantt">'+@HTML_HOT_GANTT+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-hoteles" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Hoteles" '+
                     'data-vct-dg-subtitle="Gastos y reservas de alojamiento." data-vct-dg-unit="registro(s)" data-vct-dg-search-placeholder="Buscar cliente, huésped o proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-hoteles">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="home"></span> Seguimiento de Hoteles</h2>'+
                            '<p class="vct-card-subtitle">Gastos y reservas de alojamiento.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-hoteles">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="estadia_desde" data-vct-sort-type="date" data-vct-sortable="true"><span>Estadía Desde</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="estadia_hasta" data-vct-sort-type="date" data-vct-sortable="true"><span>Estadía Hasta</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Nro Factura</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha Factura</th>'+
                                '<th data-vct-truncate="1">Proveedor</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Tipo Huésped</th>'+
                                '<th data-vct-truncate="1">Huésped</th>'+
                                '<th data-vct-truncate="1">Cliente</th>'+
                                '<th data-vct-truncate="1">Proyecto</th>'+
                                '<th data-vct-width="11%" class="vct-text-center vct-col-md">Servicio</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Forma Pago</th>'+
                                '<th data-vct-width="11%" data-vct-truncate="1" class="vct-col-md">Desc. Forma Pago</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="precio_final" data-vct-sort-type="number" data-vct-sortable="true"><span>Precio Final</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Cuotas</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGHOT_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_SEG_PASAJES VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-pasajes'
    SET @HTML_PANEL_SEG_PASAJES=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="calendar-days"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Pasajes</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_SEGPAS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-red">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="circle-dollar-sign"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Gasto Total</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VPAS_TOTAL,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-bar"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Promedio por Pasaje</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(CASE WHEN @CNT_SEGPAS=0 THEN 0 ELSE @VPAS_TOTAL/@CNT_SEGPAS END,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-pasajes">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Pasajes</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-pasajes"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Gasto por forma de pago</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        @HTML_PAS_SEGS+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+@HTML_PAS_LEGEND+'</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 proveedores por gasto</div>'+
                                '<div class="vct-barchart">'+@HTML_PAS_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Fecha Pasaje → Fecha Factura (Top 5)</div>'+
                                '<div class="vct-gantt">'+@HTML_PAS_GANTT+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-pasajes" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Pasajes" '+
                     'data-vct-dg-subtitle="Gastos y reservas de pasajes aéreos." data-vct-dg-unit="registro(s)" data-vct-dg-search-placeholder="Buscar cliente, pasajero o proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-pasajes">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="map-pin"></span> Seguimiento de Pasajes</h2>'+
                            '<p class="vct-card-subtitle">Gastos y reservas de pasajes aéreos.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-pasajes">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_pasaje" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Pasaje</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Nro Factura</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha Factura</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Tipo</th>'+
                                '<th data-vct-truncate="1">Proveedor</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Tipo Pasajero</th>'+
                                '<th data-vct-truncate="1">Pasajero</th>'+
                                '<th data-vct-truncate="1">Cliente</th>'+
                                '<th data-vct-truncate="1">Proyecto</th>'+
                                '<th data-vct-width="11%" class="vct-text-center vct-col-md">Servicio</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Forma Pago</th>'+
                                '<th data-vct-width="11%" data-vct-truncate="1" class="vct-col-md">Desc. Forma Pago</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="precio_final" data-vct-sort-type="number" data-vct-sortable="true"><span>Precio Final</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Cuotas</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGPAS_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_SEG_REMIS VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='seg-remis'
    SET @HTML_PANEL_SEG_REMIS=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="truck"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Viajes</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_SEGREMIS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-red">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="circle-dollar-sign"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Gasto Total</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VREMIS_TOTAL,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-bar"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Promedio por Viaje</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(CASE WHEN @CNT_SEGREMIS=0 THEN 0 ELSE @VREMIS_TOTAL/@CNT_SEGREMIS END,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-seg-remis">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Seguimiento de Remis/Taxi</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-seg-remis"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Gasto por forma de pago</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        @HTML_REMIS_SEGS+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+@HTML_REMIS_LEGEND+'</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 proveedores por gasto</div>'+
                                '<div class="vct-barchart">'+@HTML_REMIS_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Partida → Llegada (Top 5)</div>'+
                                '<div class="vct-gantt">'+@HTML_REMIS_GANTT+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-seg-remis" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Seguimiento de Remis/Taxi" '+
                     'data-vct-dg-subtitle="Gastos de traslados en remis y taxi." data-vct-dg-unit="registro(s)" data-vct-dg-search-placeholder="Buscar cliente, pasajero o proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-seg-remis">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="truck"></span> Seguimiento de Remis/Taxi</h2>'+
                            '<p class="vct-card-subtitle">Gastos de traslados en remis y taxi.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="seg-remis">'+
                                @HTML_FECHA_FILTRO_COMPARTIDO+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_partida" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Partida</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="fecha_llegada" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha Llegada</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Nro Factura</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Fecha Factura</th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Tipo</th>'+
                                '<th data-vct-truncate="1">Proveedor</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Tipo Pasajero</th>'+
                                '<th data-vct-truncate="1">Pasajero</th>'+
                                '<th data-vct-truncate="1">Cliente</th>'+
                                '<th data-vct-truncate="1">Proyecto</th>'+
                                '<th data-vct-width="11%" class="vct-text-center vct-col-md">Servicio</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm">Forma Pago</th>'+
                                '<th data-vct-width="11%" data-vct-truncate="1" class="vct-col-md">Desc. Forma Pago</th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="precio_final" data-vct-sort-type="number" data-vct-sortable="true"><span>Precio Final</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Cuotas</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_SEGREMIS_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_RENTABILIDAD VARCHAR(MAX)='';
    IF @PUEDE_VER_RENTABILIDAD=1 AND (@CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='rentabilidad')
    SET @HTML_PANEL_RENTABILIDAD =
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="briefcase"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Proyectos</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_RENTA)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="circle-dollar-sign"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Ventas Acum.</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VTOTAL_VENTAS_RENTA,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="circle-dollar-sign"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Compras Acum.</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VTOTAL_COMPRAS_RENTA,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-no-axes-column-increasing"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Utilidad Acum.</span>'+
                            '<span class="vct-soft-kpi-value">'+FORMAT(@VTOTAL_UTILIDAD_RENTA,'C','es-AR')+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-rentabilidad">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Rentabilidad Proyectos</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-rentabilidad"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Margen (Utilidad / Ventas acumuladas)</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_MARGEN_RENTA)+' '+CONVERT(VARCHAR(10),100-@VPCT_MARGEN_RENTA)+'" stroke-dashoffset="25"></circle>'+
                                        '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_MARGEN_RENTA)+'%</text>'+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Ventas <b>'+FORMAT(@VTOTAL_VENTAS_RENTA,'C','es-AR')+'</b></div>'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-coral"></span> Compras <b>'+FORMAT(@VTOTAL_COMPRAS_RENTA,'C','es-AR')+'</b></div>'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Utilidad <b>'+FORMAT(@VTOTAL_UTILIDAD_RENTA,'C','es-AR')+'</b></div>'+
                                    '</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 proyectos por utilidad</div>'+
                                '<div class="vct-barchart">'+@HTML_RENTA_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Período (Top 5 más reciente)</div>'+
                                '<div class="vct-gantt">'+@HTML_RENTA_GANTT+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-rentabilidad" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Rentabilidad Proyectos" '+
                     'data-vct-dg-subtitle="Monto, costos y margen de los proyectos." data-vct-dg-unit="proyecto(s)" data-vct-dg-search-placeholder="Buscar cliente o proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-rentabilidad">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="circle-dollar-sign"></span> Rentabilidad Proyectos</h2>'+
                            '<p class="vct-card-subtitle">Monto, costos y margen de los proyectos.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="rentabilidad">'+
                                '<div class="vct-reports-filters">'+
                                    '<select class="vct-select" name="SP.TEXTO08" data-vct-field="TEXTO08" aria-label="Cliente" title="Cliente"><option value="">Cliente (todos)</option>'+@HTML_RENTA_CLIENTES+'</select>'+
                                    '<input type="text" class="vct-input" placeholder="Período (AAAAMM)" name="SP.TEXTO09" data-vct-field="TEXTO09" value="'+ISNULL(@VRENTA_PERIODO,'')+'" aria-label="Período (hasta)" title="Período (hasta)" autocomplete="off">'+
                                    '<select class="vct-select" name="SP.TEXTO10" data-vct-field="TEXTO10" aria-label="Estado" title="Estado"><option value="">Estado (todos)</option>'+@HTML_RENTA_ESTADOS+'</select>'+
                                    '<button type="button" class="vct-hidden" data-vct-command="validate-next" aria-hidden="true" tabindex="-1"></button>'+
                                '</div>'+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-truncate="1" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="presupuesto" data-vct-sort-type="number" data-vct-sortable="true"><span>Presupuesto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="costo_estim" data-vct-sort-type="number" data-vct-sortable="true"><span>Costo Estim.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="utilidad_estim" data-vct-sort-type="number" data-vct-sortable="true"><span>Utilidad Estim.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="margen_estim" data-vct-sort-type="number" data-vct-sortable="true"><span>Margen Estim.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="ventas_acum" data-vct-sort-type="number" data-vct-sortable="true"><span>Ventas Acum.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="compras_acum" data-vct-sort-type="number" data-vct-sortable="true"><span>Compras Acum.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="utilidad_real" data-vct-sort-type="number" data-vct-sortable="true"><span>Utilidad Real</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="margen_real" data-vct-sort-type="number" data-vct-sortable="true"><span>Margen Real</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="desviacion" data-vct-sort-type="number" data-vct-sortable="true"><span>Desviación</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs">Período</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_RENTA_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_PARTE_ACTIVIDADES VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='parte-actividades'
    SET @HTML_PANEL_PARTE_ACTIVIDADES=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="list-checks"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Actividades</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PARTE)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="briefcase"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Consultoría</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPARTE_CONS)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clipboard-check"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Auditoría</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPARTE_AUDI)+'</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="file-text"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Capacitación</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPARTE_CAPA)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-parte-actividades">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Parte de Actividades</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-parte-actividades"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Actividades por tipo de servicio</div>'+
                                '<div class="vct-donut-row">'+
                                    '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                        '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                        '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPARTE_PCT_CONS)+' '+CONVERT(VARCHAR(10),100-@VPARTE_PCT_CONS)+'" stroke-dashoffset="25"></circle>'+
                                        '<circle class="vct-donut-seg is-amber" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPARTE_PCT_AUDI)+' '+CONVERT(VARCHAR(10),100-@VPARTE_PCT_AUDI)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-@VPARTE_PCT_CONS)+'"></circle>'+
                                        '<circle class="vct-donut-seg is-blue" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPARTE_PCT_CAPA)+' '+CONVERT(VARCHAR(10),100-@VPARTE_PCT_CAPA)+'" stroke-dashoffset="'+CONVERT(VARCHAR(10),25-@VPARTE_PCT_CONS-@VPARTE_PCT_AUDI)+'"></circle>'+
                                        '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(20),@VPARTE_TOTAL)+'</text>'+
                                    '</svg>'+
                                    '<div class="vct-donut-legend">'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Consultoría <b>'+CONVERT(VARCHAR(20),@VPARTE_CONS)+'</b></div>'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-amber"></span> Auditoría <b>'+CONVERT(VARCHAR(20),@VPARTE_AUDI)+'</b></div>'+
                                        '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-blue"></span> Capacitación <b>'+CONVERT(VARCHAR(20),@VPARTE_CAPA)+'</b></div>'+
                                    '</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 consultores por horas</div>'+
                                '<div class="vct-barchart">'+@HTML_PARTE_BARS+'</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Período activo por consultor (Top 5)</div>'+
                                '<div class="vct-gantt">'+@HTML_PARTE_GANTT+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-parte-actividades" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Parte de Actividades" '+
                     'data-vct-dg-subtitle="Registro diario de actividades del equipo." data-vct-dg-unit="actividad(es)" data-vct-dg-search-placeholder="Buscar cliente, consultor o descripción..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-parte-actividades">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="list-checks"></span> Parte de Actividades</h2>'+
                            '<p class="vct-card-subtitle">Registro diario de actividades del equipo.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="parte-actividades">'+
                                '<div class="vct-reports-filters">'+
                                    '<input type="date" class="vct-input" name="SP.TEXTO03" data-vct-field="TEXTO03" value="'+@VPA_FDESDE+'" aria-label="Fecha Desde" title="Fecha Desde" autocomplete="off">'+
                                    '<input type="date" class="vct-input" name="SP.TEXTO04" data-vct-field="TEXTO04" value="'+@VPA_FHASTA+'" aria-label="Fecha Hasta" title="Fecha Hasta" autocomplete="off">'+
                                    '<button type="button" class="vct-hidden" data-vct-command="validate-next" aria-hidden="true" tabindex="-1"></button>'+
                                '</div>'+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-width="6%" class="vct-col-xs" data-vct-sort="fecha" data-vct-sort-type="date" data-vct-sortable="true"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1" data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="servicio" data-vct-sortable="true"><span>Servicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-sort="consultor" data-vct-sortable="true"><span>Consultor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="6%" class="vct-text-center vct-col-xs" data-vct-sort="horas" data-vct-sort-type="number" data-vct-sortable="true"><span>Horas</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-width="8%" class="vct-text-center vct-col-sm" data-vct-sort="minuta" data-vct-sortable="true"><span>Minuta/Informe</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th data-vct-truncate="1">Observaciones</th>'+
                                '<th data-vct-truncate="1">Obs. Calificación</th>'+
                                '<th data-vct-truncate="1">Obs. Hoja Ruta</th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_PARTE_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PANEL_INDICE_OCUPACION VARCHAR(MAX)='';
    IF @CALC_TODOS_LOS_PANELES=1 OR @ACTIVE_GROUP='indice-ocupacion'
    SET @HTML_PANEL_INDICE_OCUPACION=
        '<div class="vct-card-body">'+
                '<div class="vct-reports-kpis">'+
                    '<div class="vct-soft-kpi is-blue">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-no-axes-column-increasing"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Prom. % Ocupación</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPROM_OCUP)+'%</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-purple">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="calendar-days"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Prom. Índice Disp.</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPROM_IND_DISP)+'%</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-green">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="chart-bar"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Prom. Índice Comp.</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VPROM_IND_COMP)+'%</span>'+
                        '</div>'+
                    '</div>'+
                    '<div class="vct-soft-kpi is-orange">'+
                        '<span class="vct-soft-kpi-icon" data-vct-icon="clock-3"></span>'+
                        '<div class="vct-soft-kpi-copy">'+
                            '<span class="vct-soft-kpi-label">Total Días Ocup.</span>'+
                            '<span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@VTOTAL_DIAS_OCUP)+'</span>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
                '<div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-indice-ocupacion">'+
                    '<div class="vct-modal-dialog">'+
                        '<div class="vct-modal-header">'+
                            '<h3 class="vct-modal-title">Gráficos — Índice Ocupación Consultores</h3>'+
                            '<button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-indice-ocupacion"><span data-vct-icon="x"></span></button>'+
                        '</div>'+
                        '<div class="vct-modal-body">'+
                            '<div class="vct-report-chart-grid" data-vct-chart-cols="3">'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Promedios del período</div>'+
                                '<div class="vct-donut-gauges">'+
                                    '<div class="vct-donut-gauge">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-blue" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_OCUP)+' '+CONVERT(VARCHAR(10),100-@VPCT_OCUP)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_OCUP)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-sublabel">% Ocupación</div>'+
                                    '</div>'+
                                    '<div class="vct-donut-gauge">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-violet" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_IND_DISP)+' '+CONVERT(VARCHAR(10),100-@VPCT_IND_DISP)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_IND_DISP)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-sublabel">Índice Disp.</div>'+
                                    '</div>'+
                                    '<div class="vct-donut-gauge">'+
                                        '<svg viewBox="0 0 36 36" class="vct-donut">'+
                                            '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                                            '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_IND_COMP)+' '+CONVERT(VARCHAR(10),100-@VPCT_IND_COMP)+'" stroke-dashoffset="25"></circle>'+
                                            '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_IND_COMP)+'%</text>'+
                                        '</svg>'+
                                        '<div class="vct-donut-sublabel">Índice Comp.</div>'+
                                    '</div>'+
                                '</div>'+
                            '</div>'+
                            '<div class="vct-report-chart">'+
                                '<div class="vct-report-chart-title">Top 5 consultores por días ocupados</div>'+
                                '<div class="vct-barchart">'+@HTML_OCUP_BARS+'</div>'+
                            '</div>'+
                            '</div>'+
                        '</div>'+
                    '</div>'+
                '</div>'+
 
                '<div data-vct-dg data-vct-dg-id="reportes-indice-ocupacion" data-vct-dg-page-size="10" '+
                     'data-vct-dg-title="Índice Ocupación Consultores" '+
                     'data-vct-dg-subtitle="Nivel de ocupación del equipo de consultores." data-vct-dg-unit="consultor(es)" data-vct-dg-search-placeholder="Buscar consultor..." data-vct-dg-density="compact" data-vct-dg-layout="fixed" data-vct-dg-charts="charts-indice-ocupacion">'+
                    '<div class="vct-card-header vct-config-abm-header">'+
                        '<div>'+
                            '<h2 class="vct-card-title"><span data-vct-icon="users"></span> Índice Ocupación Consultores</h2>'+
                            '<p class="vct-card-subtitle">Detalle por consultor del período seleccionado.</p>'+
                        '</div>'+
                    '</div>'+
                    '<div data-vct-dg-slot="filters">'+
                            '<div data-vct-form-scope>'+
                                '<input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="indice-ocupacion">'+
                                '<div class="vct-reports-filters">'+
                                    '<select class="vct-select" name="SP.TEXTO01" data-vct-field="TEXTO01" aria-label="Mes" title="Mes">'+@HTML_MESES+'</select>'+
                                    '<select class="vct-select" name="SP.TEXTO02" data-vct-field="TEXTO02" aria-label="Año" title="Año">'+@HTML_ANOS+'</select>'+
                                    '<button type="button" class="vct-hidden" data-vct-command="validate-next" aria-hidden="true" tabindex="-1"></button>'+
                                '</div>'+
                            '</div>'+
                    '</div>'+
                        '<table>'+
                            '<thead><tr>'+
                                '<th data-vct-sort="consultor" data-vct-sortable="true"><span>Consultor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="dias_disp" data-vct-sort-type="number" data-vct-sortable="true"><span>Días Disp.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="dias_comp" data-vct-sort-type="number" data-vct-sortable="true"><span>Días Comp.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="dias_ocup" data-vct-sort-type="number" data-vct-sortable="true"><span>Días Ocup.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="indice_disp" data-vct-sort-type="number" data-vct-sortable="true"><span>Ind. Disp.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="indice_comp" data-vct-sort-type="number" data-vct-sortable="true"><span>Ind. Comp.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                                '<th class="vct-text-center" data-vct-sort="pct_ocup" data-vct-sort-type="number" data-vct-sortable="true"><span>% Ocup.</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>'+
                            '</tr></thead>'+
                            '<tbody>'+@HTML_OCUP_ROWS+'</tbody>'+
                        '</table>'+
                '</div>'+
            '</div>';
 
    DECLARE @HTML_PLACEHOLDER VARCHAR(MAX)=
        '<div class="vct-card-body"><div class="vct-reports-empty">Próximamente.</div></div>';
 
    /* Nombres de icono verificados contra VCT.Icon.icons en vct-main.js:
       shield-check/graduation-cap/building-2/plane/car NO existen ahi
       (VCT.Icon.render hace "if(!body) return;" y deja el <span> vacio,
       sin fallback visible) -- se reemplazan por los mas cercanos que si
       estan en la libreria.
 
       Navegacion en 2 niveles (opcion B elegida por el usuario sobre 4
       bocetos): categoria arriba, reporte especifico abajo dentro de la
       categoria activa. Contrato consumido por vct-reportes.js V2:
       data-vct-report-cat (boton de categoria) / data-vct-report-cat-panel
       (fila de sub-tabs de esa categoria, envuelve a sus
       data-vct-report-group). Rentabilidad tiene un solo reporte: la fila
       de sub-tabs se oculta sola via JS (.is-single) al no tener mas de
       un data-vct-report-group adentro. */
    /* ============================================================
       MENU SUPERIOR CON DROPDOWN ("Opcion 2" de los bocetos elegidos)
       ------------------------------------------------------------
       Una categoria de un solo reporte (Rentabilidad) es item DIRECTO:
       data-vct-report-cat Y data-vct-report-group en el MISMO boton,
       sin dropdown (ver catOf() en vct-reportes.js). Una categoria con
       mas de un reporte abre su dropdown (.vct-report-dropdown) al
       hacer click.
       ============================================================ */
    DECLARE @HTML_CATS VARCHAR(MAX)=
        '<div class="vct-report-topnav-item">'+
            '<button type="button" data-vct-report-cat="actividad" aria-expanded="false"><span data-vct-icon="list-checks"></span> Actividad y proyectos<span class="vct-report-chevron" data-vct-icon="chevrons-up-down"></span></button>'+
            '<div class="vct-report-dropdown" data-vct-report-cat-panel="actividad">'+
                '<button type="button" data-vct-report-group="parte-actividades"><span data-vct-icon="list-checks"></span> Parte de Actividades</button>'+
                '<button type="button" data-vct-report-group="seg-consultoria"><span data-vct-icon="briefcase"></span> Seguimiento de Consultoría</button>'+
                '<button type="button" data-vct-report-group="seg-auditoria"><span data-vct-icon="clipboard-check"></span> Seguimiento de Auditoría</button>'+
                '<button type="button" data-vct-report-group="seg-capacitacion"><span data-vct-icon="file-text"></span> Seguimiento de Capacitación</button>'+
            '</div>'+
        '</div>'+
        '<div class="vct-report-topnav-item">'+
            '<button type="button" data-vct-report-cat="personas" aria-expanded="false"><span data-vct-icon="users"></span> Personas<span class="vct-report-chevron" data-vct-icon="chevrons-up-down"></span></button>'+
            '<div class="vct-report-dropdown" data-vct-report-cat-panel="personas">'+
                '<button type="button" data-vct-report-group="indice-ocupacion"><span data-vct-icon="users"></span> Índice Ocupación Consultores</button>'+
                '<button type="button" data-vct-report-group="calif-consultores"><span data-vct-icon="star"></span> Calificación Consultores</button>'+
            '</div>'+
        '</div>'+
        '<div class="vct-report-topnav-item">'+
            '<button type="button" data-vct-report-cat="viaticos" aria-expanded="false"><span data-vct-icon="map-pin"></span> Viáticos<span class="vct-report-chevron" data-vct-icon="chevrons-up-down"></span></button>'+
            '<div class="vct-report-dropdown" data-vct-report-cat-panel="viaticos">'+
                '<button type="button" data-vct-report-group="seg-hoteles"><span data-vct-icon="home"></span> Seguimiento de Hoteles</button>'+
                '<button type="button" data-vct-report-group="seg-pasajes"><span data-vct-icon="map-pin"></span> Seguimiento de Pasajes</button>'+
                '<button type="button" data-vct-report-group="seg-remis"><span data-vct-icon="truck"></span> Seguimiento de Remis/Taxi</button>'+
            '</div>'+
        '</div>'+
        CASE WHEN @PUEDE_VER_RENTABILIDAD=1
             THEN '<button type="button" data-vct-report-cat="rentabilidad" data-vct-report-group="rentabilidad"><span data-vct-icon="circle-dollar-sign"></span> Rentabilidad</button>'
             ELSE '' END;
 
    DECLARE @HTML_PANELES VARCHAR(MAX)=
        '<div data-vct-report-group-panel="parte-actividades">'+@HTML_PANEL_PARTE_ACTIVIDADES+'</div>'+
        '<div data-vct-report-group-panel="seg-consultoria">'+@HTML_PANEL_SEG_CONSULTORIA+'</div>'+
        '<div data-vct-report-group-panel="seg-auditoria">'+@HTML_PANEL_SEG_AUDITORIA+'</div>'+
        '<div data-vct-report-group-panel="seg-capacitacion">'+@HTML_PANEL_SEG_CAPACITACION+'</div>'+
        '<div data-vct-report-group-panel="indice-ocupacion">'+@HTML_PANEL_INDICE_OCUPACION+'</div>'+
        '<div data-vct-report-group-panel="calif-consultores">'+@HTML_PANEL_CALIF_CONSULTORES+'</div>'+
        '<div data-vct-report-group-panel="seg-hoteles">'+@HTML_PANEL_SEG_HOTELES+'</div>'+
        '<div data-vct-report-group-panel="seg-pasajes">'+@HTML_PANEL_SEG_PASAJES+'</div>'+
        '<div data-vct-report-group-panel="seg-remis">'+@HTML_PANEL_SEG_REMIS+'</div>'+
        CASE WHEN @PUEDE_VER_RENTABILIDAD=1
             THEN '<div data-vct-report-group-panel="rentabilidad">'+@HTML_PANEL_RENTABILIDAD+'</div>'
             ELSE '' END;
 
    SET @OUTPARAM1=
        ISNULL(@HTML_SHELL,'')+
        '<link rel="stylesheet" href="../css/vct-datagrid.css?v=4">'+
        '<link rel="stylesheet" href="../css/vct-datepicker.css?v=1">'+
        '<link rel="stylesheet" href="../css/vct-reportes.css?v=27">'+
        '<div class="vct-page vct-page-main" data-vct-page data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">'+
            '<section class="vct-card vct-reports-workspace">'+
                '<div data-vct-report-root data-vct-report-active="'+@ACTIVE_GROUP+'">'+
                    '<nav class="vct-report-topnav">'+@HTML_CATS+'</nav>'+
                    '<div class="vct-report-breadcrumb" data-vct-report-breadcrumb></div>'+
                    @HTML_PANELES+
                '</div>'+
            '</section>'+
        '</div>'+
        '<script src="../js/vct-export.js?v=1"></script>'+
        '<script src="../js/vct-datagrid.js?v=3"></script>'+
        '<script src="../js/vct-reportes.js?v=14"></script>'+
        '<script src="../js/vct-datepicker.js?v=2"></script>';
 
END
