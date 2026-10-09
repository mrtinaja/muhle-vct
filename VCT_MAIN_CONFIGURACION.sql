USE [MuhlePROD]
GO
/* ---- GUARDA: este script se preparo sobre una definicion puntual de VCT_MAIN_CONFIGURACION.
   Si el servidor tiene otra (cambio posterior), NO aplica nada y avisa. ---- */
DECLARE @DEF NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONFIGURACION'));
DECLARE @L INT=LEN(@DEF);
IF NOT (CHARINDEX('MIGRADO_DG',@DEF)>0 OR @L BETWEEN 229110 AND 229125 OR @L BETWEEN 229110 AND 229125)
BEGIN
    PRINT 'LARGO ACTUAL EN SERVIDOR: '+CONVERT(VARCHAR(20),@L);
    RAISERROR('La definicion de VCT_MAIN_CONFIGURACION en el servidor NO coincide con la version usada para preparar este script. No se aplico nada. Pasale a Claude la definicion vigente.',16,1);
    SET NOEXEC ON;
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ========================================================================
   V5 - CONFIGURACION + EMAIL TEMPLATE DESIGNER
   MIGRADO_DG: las 10 grillas usan el motor nuevo (vct-datagrid.js / vct-datagrid.css / vct-export.js).
   Logica, permisos, ABM, formularios y disenador de emails: sin cambios.
   ------------------------------------------------------------------------
   Estructura visual:
     - Selector principal por cards: Parametria / Emails
     - Parametria: subtabs Servicios / Normas
     - Emails: ABM Templates de emails

   Metodologia funcional conservada:
     - VCT_BUFFER
     - VCT_MAIN_GET_ACTIONS
     - VCT_MAIN_RENDER_FORM_ACTION
     - VCT_MAIN_RENDER_FORM
     - forms declarativos + DomForm del vct-main.js
     - VCT.Grid / paginado / filtros / export generico

   ABMs incluidos:
     - dbo.VCT_PRM_NORMAS
     - dbo.VCT_PRM_EMAIL_TEMPLATES

   NOTA TEMPLATES:
     Para Emails se utiliza EXCLUSIVAMENTE dbo.VCT_PRM_EMAIL_TEMPLATES.
     El alta/edicion se realiza a pantalla completa dentro de la solapa Emails.
     El diseñador visual se encuentra aislado en:
       ../css/vct-email-template-designer.css
       ../js/vct-email-template-designer.js
     No modifica vct-main.css ni vct-main.js.
   ======================================================================== */
ALTER PROCEDURE [dbo].[VCT_MAIN_CONFIGURACION]
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

    DECLARE @MODULE_CODE VARCHAR(50)='CONFIGURACION';

    DECLARE
        @HTML_SHELL              VARCHAR(MAX)='',
        @HTML                    VARCHAR(MAX)='',
        @HTML_FEEDBACK           VARCHAR(MAX)='',

        @HTML_TEMPLATE_ROWS      VARCHAR(MAX)='',
        @HTML_NORMAS_ROWS        VARCHAR(MAX)='',

        @HTML_NORMA_CREATE       VARCHAR(MAX)='',
        @HTML_NORMA_EDIT         VARCHAR(MAX)='',

        @HTML_MODAL_NORMA        VARCHAR(MAX)='',

        /* ---- Gestiones (catalogos simples: Tipos/Subtipos/Resultados/
           Estados/Prioridades) ---- */
        @HTML_GESTION_TIPO_ROWS       VARCHAR(MAX)='',
        @HTML_GESTION_SUBTIPO_ROWS    VARCHAR(MAX)='',
        @HTML_GESTION_RESULTADO_ROWS  VARCHAR(MAX)='',
        @HTML_GESTION_ESTADO_ROWS     VARCHAR(MAX)='',
        @HTML_GESTION_PRIORIDAD_ROWS  VARCHAR(MAX)='',

        @HTML_GESTION_TIPO_CREATE       VARCHAR(MAX)='',
        @HTML_GESTION_TIPO_EDIT         VARCHAR(MAX)='',
        @HTML_GESTION_SUBTIPO_CREATE    VARCHAR(MAX)='',
        @HTML_GESTION_SUBTIPO_EDIT      VARCHAR(MAX)='',
        @HTML_GESTION_RESULTADO_CREATE  VARCHAR(MAX)='',
        @HTML_GESTION_RESULTADO_EDIT    VARCHAR(MAX)='',
        @HTML_GESTION_ESTADO_CREATE     VARCHAR(MAX)='',
        @HTML_GESTION_ESTADO_EDIT       VARCHAR(MAX)='',
        @HTML_GESTION_PRIORIDAD_CREATE  VARCHAR(MAX)='',
        @HTML_GESTION_PRIORIDAD_EDIT    VARCHAR(MAX)='',

        @HTML_MODAL_GESTION_TIPO       VARCHAR(MAX)='',
        @HTML_MODAL_GESTION_SUBTIPO    VARCHAR(MAX)='',
        @HTML_MODAL_GESTION_RESULTADO  VARCHAR(MAX)='',
        @HTML_MODAL_GESTION_ESTADO     VARCHAR(MAX)='',
        @HTML_MODAL_GESTION_PRIORIDAD  VARCHAR(MAX)='',

        @HTML_OPTIONS_GESTION_TIPO     VARCHAR(MAX)='',

        @CNT_GESTION_TIPOS       INT=0,
        @CNT_GESTION_SUBTIPOS    INT=0,
        @CNT_GESTION_RESULTADOS  INT=0,
        @CNT_GESTION_ESTADOS     INT=0,
        @CNT_GESTION_PRIORIDADES INT=0,

        @FORM_ERR_GESTION_TIPO       VARCHAR(2000)='',
        @FORM_ERR_GESTION_SUBTIPO    VARCHAR(2000)='',
        @FORM_ERR_GESTION_RESULTADO  VARCHAR(2000)='',
        @FORM_ERR_GESTION_ESTADO     VARCHAR(2000)='',
        @FORM_ERR_GESTION_PRIORIDAD  VARCHAR(2000)='',

        @OPEN_GESTION_TIPO       BIT=0,
        @OPEN_GESTION_SUBTIPO    BIT=0,
        @OPEN_GESTION_RESULTADO  BIT=0,
        @OPEN_GESTION_ESTADO     BIT=0,
        @OPEN_GESTION_PRIORIDAD  BIT=0,

        /* ---- Proyectos (Estados/Roles) ---- */
        @HTML_PROYECTO_ESTADO_ROWS   VARCHAR(MAX)='',
        @HTML_PROYECTO_ROL_ROWS      VARCHAR(MAX)='',
        @HTML_PROYECTO_ESTADO_CREATE VARCHAR(MAX)='',
        @HTML_PROYECTO_ESTADO_EDIT   VARCHAR(MAX)='',
        @HTML_PROYECTO_ROL_CREATE    VARCHAR(MAX)='',
        @HTML_PROYECTO_ROL_EDIT      VARCHAR(MAX)='',
        @HTML_MODAL_PROYECTO_ESTADO  VARCHAR(MAX)='',
        @HTML_MODAL_PROYECTO_ROL     VARCHAR(MAX)='',
        @CNT_PROYECTO_ESTADOS        INT=0,
        @CNT_PROYECTO_ROLES          INT=0,
        @FORM_ERR_PROYECTO_ESTADO    VARCHAR(2000)='',
        @FORM_ERR_PROYECTO_ROL       VARCHAR(2000)='',
        @OPEN_PROYECTO_ESTADO        BIT=0,
        @OPEN_PROYECTO_ROL           BIT=0,

        /* ---- Viaticos (Tipos) ---- */
        @HTML_VIATICO_TIPO_ROWS   VARCHAR(MAX)='',
        @HTML_VIATICO_TIPO_CREATE VARCHAR(MAX)='',
        @HTML_VIATICO_TIPO_EDIT   VARCHAR(MAX)='',
        @HTML_MODAL_VIATICO_TIPO  VARCHAR(MAX)='',
        @CNT_VIATICO_TIPOS        INT=0,
        @FORM_ERR_VIATICO_TIPO    VARCHAR(2000)='',
        @OPEN_VIATICO_TIPO        BIT=0,

        /* ---- Parametria: KPIs y graficos (rediseño visual, header +
           dropdown igual a Reportes) ----
           Conteos auxiliares (activos/inactivos/finales/etc.) calculados
           con agregados baratos (COUNT/SUM con CASE) sobre las MISMAS
           tablas ya consultadas mas abajo para la grilla -- ningun dato
           nuevo, ninguna consulta cara. */
        @CNT_NORMAS_ACTIVAS               INT=0,
        @CNT_GESTION_TIPOS_ACTIVOS        INT=0,
        @CNT_GESTION_RESULTADOS_ACTIVOS   INT=0,
        @CNT_GESTION_ESTADOS_ACTIVOS      INT=0,
        @CNT_GESTION_ESTADOS_FINALES      INT=0,
        @CNT_GESTION_PRIORIDADES_ACTIVAS  INT=0,
        @CNT_GESTION_PRIORIDADES_NIVELMAX INT=0,
        @CNT_GESTION_SUBTIPOS_ACTIVOS     INT=0,
        @CNT_GESTION_SUBTIPOS_TIPOSCONSUB INT=0,
        @CNT_PROYECTO_ESTADOS_ACTIVOS     INT=0,
        @CNT_PROYECTO_ROLES_ACTIVOS       INT=0,
        @CNT_PROYECTO_ROLES_CONTIPO       INT=0,
        @CNT_VIATICO_TIPOS_ACTIVOS        INT=0,

        @VPCT_NORMAS_ACT              INT=0,
        @VPCT_GESTION_TIPOS_ACT       INT=0,
        @VPCT_GESTION_RESULTADOS_ACT  INT=0,
        @VPCT_GESTION_ESTADOS_ACT     INT=0,
        @VPCT_GESTION_ESTADOS_FIN     INT=0,
        @VPCT_GESTION_PRIORIDADES_ACT INT=0,
        @VPCT_GESTION_SUBTIPOS_ACT    INT=0,
        @VPCT_PROYECTO_ESTADOS_ACT    INT=0,
        @VPCT_PROYECTO_ROLES_ACT      INT=0,
        @VPCT_VIATICO_TIPOS_ACT       INT=0,

        @HTML_NORMAS_DONUT             VARCHAR(MAX)='',
        @HTML_GESTION_TIPO_DONUT       VARCHAR(MAX)='',
        @HTML_GESTION_RESULTADO_DONUT  VARCHAR(MAX)='',
        @HTML_GESTION_ESTADO_DONUT_ACT VARCHAR(MAX)='',
        @HTML_GESTION_ESTADO_DONUT_FIN VARCHAR(MAX)='',
        @HTML_GESTION_PRIORIDAD_DONUT  VARCHAR(MAX)='',
        @HTML_GESTION_PRIORIDAD_BARS   VARCHAR(MAX)='',
        @HTML_GESTION_SUBTIPO_DONUT    VARCHAR(MAX)='',
        @HTML_GESTION_SUBTIPO_BARS     VARCHAR(MAX)='',
        @HTML_PROYECTO_ESTADO_DONUT    VARCHAR(MAX)='',
        @HTML_PROYECTO_ROL_DONUT       VARCHAR(MAX)='',
        @HTML_PROYECTO_ROL_BARS        VARCHAR(MAX)='',
        @HTML_VIATICO_TIPO_DONUT       VARCHAR(MAX)='',

        @RESULTADO_SHELL         VARCHAR(20)='',
        @SIDEBAR_ID              INT=0,

        @CAN_CREATE              BIT=0,
        @CAN_EDIT                BIT=0,
        @CAN_DELETE              BIT=0,

        @CNT_TEMPLATES           INT=0,
        @CNT_NORMAS              INT=0,

        @VID_ROW                 VARCHAR(100)='',
        @VFORM_ENTITY             VARCHAR(50)='',
        @ACTIVE_TAB              VARCHAR(50)='gestiones-tipos',

        @VTEXTO01                VARCHAR(MAX)='',
        @VTEXTO02                VARCHAR(MAX)='',
        @VTEXTO03                VARCHAR(MAX)='',
        @VTEXTO04                VARCHAR(MAX)='',
        @VTEXTO05                VARCHAR(MAX)='',
        @VTEXTO06                VARCHAR(MAX)='',
        @VTEXTO07                VARCHAR(MAX)='',
        @VTEXTO08                VARCHAR(MAX)='',
        @VTEXTO09                VARCHAR(MAX)='',
        @VTEXTO10                VARCHAR(MAX)='',
        @VTEXTO11                VARCHAR(MAX)='',

        @VFLAG01                 VARCHAR(10)='',
        @VFLAG02                 VARCHAR(10)='0',
        @VFLAG03                 VARCHAR(10)='0',

        @VFORM_ERROR             VARCHAR(2000)='',
        @VFORM_REOPEN            BIT=0,
        @FORM_ERR_NORMA          VARCHAR(2000)='',
        @FORM_ERR_TEMPLATE       VARCHAR(2000)='',
        @OPEN_NORMA              BIT=0,
        @OPEN_TEMPLATE           BIT=0,
        @ID_ROW_INT              INT=NULL,
        @RC                      INT=0;

    /* ============================================================
       1. SHELL
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Configuración',
             @SUBTITLE           = 'Administración de parámetros y plantillas del sistema.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL='';
        SET @RESULTADO_SHELL='ERROR';
    END CATCH;

    /* ============================================================
       2. PERMISOS / ACCIONES
       ============================================================ */
    IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;

    SELECT *
    INTO #ACCIONES
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);

    SELECT TOP 1 @SIDEBAR_ID=ISNULL(SIDEBAR_ID,0)
    FROM #ACCIONES
    WHERE ISNULL(SIDEBAR_ID,0)<>0
    ORDER BY SORT_ORDER,ID_PRM;

    SET @CAN_CREATE=CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='CREATE') THEN 1 ELSE 0 END;
    SET @CAN_EDIT  =CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT')   THEN 1 ELSE 0 END;
    SET @CAN_DELETE=CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='DELETE') THEN 1 ELSE 0 END;

    IF NOT EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='VIEW')
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para visualizar Configuración.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* ============================================================
       3. VALIDACION DEL MODELO ACTUAL
       ============================================================ */
    IF OBJECT_ID('dbo.VCT_PRM_NORMAS','U') IS NULL
       OR OBJECT_ID('dbo.VCT_PRM_EMAIL_TEMPLATES','U') IS NULL
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Configuración incompleta</h2>
            <p class="vct-card-subtitle">Falta al menos una tabla requerida: VCT_PRM_NORMAS o VCT_PRM_EMAIL_TEMPLATES.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* ============================================================
       4. BUFFER / ESTADO DE OPERACION
       ------------------------------------------------------------
       Contrato comun para los tres ABM:
         IDSELEC01 = ID de fila
         TEXTO30   = NORMA | EMAIL_TEMPLATE
         ACTIVE_TAB= normas | email-templates
         FLAG01    = guardar
         FLAG03    = eliminar

       TEXTO01..11 se reutilizan por formulario. DomForm deja activo
       solamente el formulario que se está utilizando.
       ============================================================ */
    SELECT TOP 1
        @VID_ROW      =ISNULL(CONVERT(VARCHAR(100),IDSELEC01),''),
        @VFORM_ENTITY =UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),TEXTO30),'')))),
        @ACTIVE_TAB   =LOWER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),ACTIVE_TAB),'')))),

        @VTEXTO01     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO01),''),
        @VTEXTO02     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO02),''),
        @VTEXTO03     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO03),''),
        @VTEXTO04     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO04),''),
        @VTEXTO05     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO05),''),
        @VTEXTO06     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO06),''),
        @VTEXTO07     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO07),''),
        @VTEXTO08     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO08),''),
        @VTEXTO09     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO09),''),
        @VTEXTO10     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO10),''),
        @VTEXTO11     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO11),''),

        @VFLAG01      =ISNULL(CONVERT(VARCHAR(10),FLAG01),'0'),
        @VFLAG02      =ISNULL(CONVERT(VARCHAR(10),FLAG02),'0'),
        @VFLAG03      =ISNULL(CONVERT(VARCHAR(10),FLAG03),'0')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;

    /* Compatibilidad con el formulario de Templates anterior a esta versión. */
    IF @VFLAG01='1' AND NULLIF(@VFORM_ENTITY,'') IS NULL
        SET @VFORM_ENTITY='EMAIL_TEMPLATE';

    /* El SELECT de arriba trae el ACTIVE_TAB que haya quedado guardado en
       VCT_BUFFER de la ULTIMA vez que se guardo/edito/elimino algo (por
       ejemplo 'normas', de cuando el unico ABM era Normas) -- eso es
       correcto para volver a la pestaña correcta DESPUES de guardar un
       registro, pero pisa cualquier default cuando la pantalla se abre
       de cero desde el menu (sin guardar/editar/eliminar nada todavia).
       Por eso: si no hay accion real en curso (no se esta guardando,
       editando, ni eliminando nada), forzamos la pestana de entrada a
       Gestiones > Tipos, sin importar que haya quedado guardado antes. */
    IF @VFLAG01<>'1' AND @VFLAG03<>'1' AND NULLIF(@VFORM_ENTITY,'') IS NULL
        SET @ACTIVE_TAB='gestiones-tipos';

    IF @ACTIVE_TAB NOT IN (
        'normas','email-templates',
        'gestiones-tipos','gestiones-subtipos','gestiones-resultados',
        'gestiones-estados','gestiones-prioridades','gestiones-reglas',
        'proyectos-estados','proyectos-roles','viaticos-tipos'
    )
    BEGIN
        SET @ACTIVE_TAB=CASE @VFORM_ENTITY
            WHEN 'NORMA' THEN 'normas'
            WHEN 'EMAIL_TEMPLATE' THEN 'email-templates'
            WHEN 'GESTION_TIPO' THEN 'gestiones-tipos'
            WHEN 'GESTION_SUBTIPO' THEN 'gestiones-subtipos'
            WHEN 'GESTION_RESULTADO' THEN 'gestiones-resultados'
            WHEN 'GESTION_ESTADO' THEN 'gestiones-estados'
            WHEN 'GESTION_PRIORIDAD' THEN 'gestiones-prioridades'
            WHEN 'PROYECTO_ESTADO' THEN 'proyectos-estados'
            WHEN 'PROYECTO_ROL' THEN 'proyectos-roles'
            WHEN 'VIATICO_TIPO' THEN 'viaticos-tipos'
            ELSE 'gestiones-tipos'
        END;
    END;

    SET @VFLAG02=CASE WHEN @VFLAG02='1' THEN '1' ELSE '0' END;
    SET @VFLAG03=CASE WHEN @VFLAG03='1' THEN '1' ELSE '0' END;

    /* ============================================================
       EMAIL TEMPLATE - SENTINEL DE ALTA
       ------------------------------------------------------------
       El editor envía IDSELEC01=0 cuando todavía no existe ID.
       Se normaliza a vacío para que la lógica posterior lo trate
       como INSERT y no como UPDATE.
       ============================================================ */
    IF @VFORM_ENTITY='EMAIL_TEMPLATE'
       AND LTRIM(RTRIM(ISNULL(@VID_ROW,'')))='0'
    BEGIN
        SET @VID_ROW='';
    END;

    /* ============================================================
       5. ELIMINAR
       ============================================================ */
    IF @VFLAG03='1'
    BEGIN
        SET @VFORM_ERROR='';
        SET @VFORM_REOPEN=0;
        SET @ID_ROW_INT=NULL;

        IF @CAN_DELETE=0
            SET @VFORM_ERROR='No posee permisos para eliminar registros de Configuración.';
        ELSE IF NULLIF(LTRIM(RTRIM(@VID_ROW)),'') IS NULL
            SET @VFORM_ERROR='No se recibió el registro a eliminar.';
        ELSE IF @VID_ROW LIKE '%[^0-9]%'
            SET @VFORM_ERROR='El identificador del registro a eliminar no es válido.';
        ELSE
            SET @ID_ROW_INT=CONVERT(INT,@VID_ROW);

        IF @VFORM_ENTITY='NORMA' SET @ACTIVE_TAB='normas';
        IF @VFORM_ENTITY='EMAIL_TEMPLATE' SET @ACTIVE_TAB='email-templates';
        IF @VFORM_ENTITY='GESTION_TIPO' SET @ACTIVE_TAB='gestiones-tipos';
        IF @VFORM_ENTITY='GESTION_SUBTIPO' SET @ACTIVE_TAB='gestiones-subtipos';
        IF @VFORM_ENTITY='GESTION_RESULTADO' SET @ACTIVE_TAB='gestiones-resultados';
        IF @VFORM_ENTITY='GESTION_ESTADO' SET @ACTIVE_TAB='gestiones-estados';
        IF @VFORM_ENTITY='GESTION_PRIORIDAD' SET @ACTIVE_TAB='gestiones-prioridades';
        IF @VFORM_ENTITY='PROYECTO_ESTADO' SET @ACTIVE_TAB='proyectos-estados';
        IF @VFORM_ENTITY='PROYECTO_ROL' SET @ACTIVE_TAB='proyectos-roles';
        IF @VFORM_ENTITY='VIATICO_TIPO' SET @ACTIVE_TAB='viaticos-tipos';

        IF @VFORM_ERROR=''
        BEGIN TRY
            SET @RC=0;

            IF @VFORM_ENTITY='NORMA'
            BEGIN
                DELETE FROM dbo.VCT_PRM_NORMAS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='EMAIL_TEMPLATE'
            BEGIN
                DELETE FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='GESTION_TIPO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='GESTION_SUBTIPO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='GESTION_RESULTADO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='GESTION_ESTADO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='GESTION_PRIORIDAD'
            BEGIN
                DELETE FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='PROYECTO_ESTADO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='PROYECTO_ROL'
            BEGIN
                DELETE FROM dbo.VCT_PRM_PROYECTOS_ROLES WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE IF @VFORM_ENTITY='VIATICO_TIPO'
            BEGIN
                DELETE FROM dbo.VCT_PRM_VIATICOS_TIPOS WHERE ID=@ID_ROW_INT;
                SET @RC=@@ROWCOUNT;
            END
            ELSE
                SET @VFORM_ERROR='La entidad solicitada para eliminar no es válida.';

            IF @VFORM_ERROR='' AND @RC=0
                SET @VFORM_ERROR='El registro seleccionado ya no existe.';
        END TRY
        BEGIN CATCH
            IF ERROR_NUMBER()=547
                SET @VFORM_ERROR='No se puede eliminar el registro porque está siendo utilizado por otra información del sistema.';
            ELSE
                SET @VFORM_ERROR=ERROR_MESSAGE();
        END CATCH;

        SET @VFLAG01='0';
        SET @VFLAG03='0';

        UPDATE dbo.VCT_BUFFER
           SET FLAG01=0,
               FLAG03=0,
               IDSELEC01=NULL,
               ACTIVE_TAB=@ACTIVE_TAB
         WHERE PAR_KEY=@IPKEYJOB;
    END;

    /* ============================================================
       6. GUARDAR / EDITAR
       ============================================================ */
    IF @VFLAG01='1'
    BEGIN
        SET @VFORM_ERROR='';
        SET @VFORM_REOPEN=0;
        SET @ID_ROW_INT=NULL;

        IF NULLIF(LTRIM(RTRIM(@VID_ROW)),'') IS NOT NULL
        BEGIN
            IF @VID_ROW LIKE '%[^0-9]%'
                SET @VFORM_ERROR='El identificador del registro no es válido.';
            ELSE
                SET @ID_ROW_INT=CONVERT(INT,@VID_ROW);
        END;

        IF @VFORM_ERROR=''
        BEGIN
            IF @ID_ROW_INT IS NULL AND @CAN_CREATE=0
                SET @VFORM_ERROR='No posee permisos para crear registros de Configuración.';
            ELSE IF @ID_ROW_INT IS NOT NULL AND @CAN_EDIT=0
                SET @VFORM_ERROR='No posee permisos para editar registros de Configuración.';
        END;

        /* --------------------------------------------------------
           NORMAS
           TEXTO01 = DESCRIPCION
           TEXTO02 = ESTADO
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='NORMA'
        BEGIN
            SET @ACTIVE_TAB='normas';
            SET @VTEXTO01=LTRIM(RTRIM(ISNULL(@VTEXTO01,'')));
            SET @VTEXTO02=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO02,''))));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='La descripción de la norma es obligatoria.';
            ELSE IF LEN(@VTEXTO01)>400
                SET @VFORM_ERROR='La descripción de la norma no puede superar 400 caracteres.';
            ELSE IF @VTEXTO02 NOT IN ('ACTIVO','INACTIVO')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_NORMAS WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='La norma seleccionada no existe.';

            IF @VFORM_ERROR='' AND EXISTS
            (
                SELECT 1
                FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
                WHERE UPPER(LTRIM(RTRIM(N.DESCRIPCION))) COLLATE DATABASE_DEFAULT=
                      UPPER(@VTEXTO01) COLLATE DATABASE_DEFAULT
                  AND (@ID_ROW_INT IS NULL OR N.ID<>@ID_ROW_INT)
            )
                SET @VFORM_ERROR='Ya existe otra norma con la misma descripción.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PRM_NORMAS
                    (
                        DESCRIPCION,ESTADO,
                        FECHA_ALTA,USUARIO_ALTA,
                        FECHA_UPD,USUARIO_UPD
                    )
                    VALUES
                    (
                        @VTEXTO01,@VTEXTO02,
                        GETDATE(),@IAGENTE,
                        NULL,NULL
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_PRM_NORMAS
                       SET DESCRIPCION=@VTEXTO01,
                           ESTADO=@VTEXTO02,
                           FECHA_UPD=GETDATE(),
                           USUARIO_UPD=@IAGENTE
                     WHERE ID=@ID_ROW_INT;
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           GESTIONES - TIPOS / RESULTADOS (mismo shape: catalogo simple)
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ACTIVO('1'/'0')
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY IN ('GESTION_TIPO','GESTION_RESULTADO')
        BEGIN
            DECLARE @GT_TABLA VARCHAR(50)=CASE WHEN @VFORM_ENTITY='GESTION_TIPO' THEN 'dbo.VCT_PRM_GESTIONES_TIPOS' ELSE 'dbo.VCT_PRM_GESTIONES_RESULTADOS' END;
            DECLARE @GT_ORDEN INT, @GT_ACTIVO BIT;

            SET @ACTIVE_TAB=CASE WHEN @VFORM_ENTITY='GESTION_TIPO' THEN 'gestiones-tipos' ELSE 'gestiones-resultados' END;
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>50
                SET @VFORM_ERROR='El código no puede superar 50 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>150
                SET @VFORM_ERROR='La descripción no puede superar 150 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR=''
            BEGIN
                SET @GT_ORDEN=CONVERT(INT,@VTEXTO03);
                SET @GT_ACTIVO=CONVERT(BIT,@VTEXTO04);
            END;

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE @VFORM_ENTITY='GESTION_TIPO' AND ID=@ID_ROW_INT
                              UNION ALL SELECT 1 FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE @VFORM_ENTITY='GESTION_RESULTADO' AND ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El registro seleccionado no existe.';

            IF @VFORM_ERROR='' AND @VFORM_ENTITY='GESTION_TIPO' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_TIPOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro tipo con el mismo código.';
            IF @VFORM_ERROR='' AND @VFORM_ENTITY='GESTION_RESULTADO' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro resultado con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_ENTITY='GESTION_TIPO'
                BEGIN
                    IF @ID_ROW_INT IS NULL
                        INSERT INTO dbo.VCT_PRM_GESTIONES_TIPOS(CODIGO,DESCRIPCION,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                        VALUES(@VTEXTO01,@VTEXTO02,@GT_ORDEN,@GT_ACTIVO,GETDATE(),@IAGENTE);
                    ELSE
                        UPDATE dbo.VCT_PRM_GESTIONES_TIPOS SET DESCRIPCION=@VTEXTO02,ORDEN=@GT_ORDEN,ACTIVO=@GT_ACTIVO,FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
                END
                ELSE
                BEGIN
                    IF @ID_ROW_INT IS NULL
                        INSERT INTO dbo.VCT_PRM_GESTIONES_RESULTADOS(CODIGO,DESCRIPCION,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                        VALUES(@VTEXTO01,@VTEXTO02,@GT_ORDEN,@GT_ACTIVO,GETDATE(),@IAGENTE);
                    ELSE
                        UPDATE dbo.VCT_PRM_GESTIONES_RESULTADOS SET DESCRIPCION=@VTEXTO02,ORDEN=@GT_ORDEN,ACTIVO=@GT_ACTIVO,FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           GESTIONES - SUBTIPOS
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ACTIVO, TEXTO05=ID_TIPO
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='GESTION_SUBTIPO'
        BEGIN
            SET @ACTIVE_TAB='gestiones-subtipos';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));
            SET @VTEXTO05=LTRIM(RTRIM(ISNULL(@VTEXTO05,'')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>50
                SET @VFORM_ERROR='El código no puede superar 50 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>150
                SET @VFORM_ERROR='La descripción no puede superar 150 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';
            ELSE IF @VTEXTO05 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO05,'') IS NULL
                SET @VFORM_ERROR='Debe seleccionar el Tipo al que pertenece.';
            ELSE IF NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_TIPOS WITH(NOLOCK) WHERE ID=CONVERT(INT,@VTEXTO05))
                SET @VFORM_ERROR='El Tipo seleccionado no existe.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El subtipo seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro subtipo con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_GESTIONES_SUBTIPOS(ID_TIPO,CODIGO,DESCRIPCION,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(CONVERT(INT,@VTEXTO05),@VTEXTO01,@VTEXTO02,CONVERT(INT,@VTEXTO03),CONVERT(BIT,@VTEXTO04),GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_GESTIONES_SUBTIPOS SET ID_TIPO=CONVERT(INT,@VTEXTO05),DESCRIPCION=@VTEXTO02,ORDEN=CONVERT(INT,@VTEXTO03),ACTIVO=CONVERT(BIT,@VTEXTO04),FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           GESTIONES - ESTADOS
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ACTIVO, TEXTO05=ES_FINAL
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='GESTION_ESTADO'
        BEGIN
            SET @ACTIVE_TAB='gestiones-estados';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));
            SET @VTEXTO05=LTRIM(RTRIM(ISNULL(@VTEXTO05,'0')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>30
                SET @VFORM_ERROR='El código no puede superar 30 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>100
                SET @VFORM_ERROR='La descripción no puede superar 100 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0') OR @VTEXTO05 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El estado seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro estado con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_GESTIONES_ESTADOS(CODIGO,DESCRIPCION,ES_FINAL,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(@VTEXTO01,@VTEXTO02,CONVERT(BIT,@VTEXTO05),CONVERT(INT,@VTEXTO03),CONVERT(BIT,@VTEXTO04),GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_GESTIONES_ESTADOS SET DESCRIPCION=@VTEXTO02,ES_FINAL=CONVERT(BIT,@VTEXTO05),ORDEN=CONVERT(INT,@VTEXTO03),ACTIVO=CONVERT(BIT,@VTEXTO04),FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           GESTIONES - PRIORIDADES
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=NIVEL, TEXTO04=ACTIVO
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='GESTION_PRIORIDAD'
        BEGIN
            SET @ACTIVE_TAB='gestiones-prioridades';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>30
                SET @VFORM_ERROR='El código no puede superar 30 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>100
                SET @VFORM_ERROR='La descripción no puede superar 100 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El nivel debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='La prioridad seleccionada no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otra prioridad con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_GESTIONES_PRIORIDADES(CODIGO,DESCRIPCION,NIVEL,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(@VTEXTO01,@VTEXTO02,CONVERT(INT,@VTEXTO03),CONVERT(BIT,@VTEXTO04),GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_GESTIONES_PRIORIDADES SET DESCRIPCION=@VTEXTO02,NIVEL=CONVERT(INT,@VTEXTO03),ACTIVO=CONVERT(BIT,@VTEXTO04),FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           PROYECTOS - ESTADOS
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ACTIVO
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='PROYECTO_ESTADO'
        BEGIN
            SET @ACTIVE_TAB='proyectos-estados';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>30
                SET @VFORM_ERROR='El código no puede superar 30 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>100
                SET @VFORM_ERROR='La descripción no puede superar 100 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El estado seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro estado con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_PROYECTOS_ESTADOS(CODIGO,DESCRIPCION,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(@VTEXTO01,@VTEXTO02,CONVERT(INT,@VTEXTO03),CONVERT(BIT,@VTEXTO04),GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_PROYECTOS_ESTADOS SET DESCRIPCION=@VTEXTO02,ORDEN=CONVERT(INT,@VTEXTO03),ACTIVO=CONVERT(BIT,@VTEXTO04),FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           PROYECTOS - ROLES
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ACTIVO, TEXTO05=TIPO_MIEMBRO (opcional)
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='PROYECTO_ROL'
        BEGIN
            SET @ACTIVE_TAB='proyectos-roles';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=LTRIM(RTRIM(ISNULL(@VTEXTO04,'1')));
            SET @VTEXTO05=LTRIM(RTRIM(ISNULL(@VTEXTO05,'')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>50
                SET @VFORM_ERROR='El código no puede superar 50 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>100
                SET @VFORM_ERROR='La descripción no puede superar 100 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('1','0')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';
            ELSE IF LEN(@VTEXTO05)>20
                SET @VFORM_ERROR='El tipo de miembro no puede superar 20 caracteres.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El rol seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro rol con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_PROYECTOS_ROLES(CODIGO,DESCRIPCION,TIPO_MIEMBRO,ORDEN,ACTIVO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(@VTEXTO01,@VTEXTO02,NULLIF(@VTEXTO05,''),CONVERT(INT,@VTEXTO03),CONVERT(BIT,@VTEXTO04),GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_PROYECTOS_ROLES SET DESCRIPCION=@VTEXTO02,TIPO_MIEMBRO=NULLIF(@VTEXTO05,''),ORDEN=CONVERT(INT,@VTEXTO03),ACTIVO=CONVERT(BIT,@VTEXTO04),FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           VIATICOS - TIPOS
           TEXTO01=CODIGO, TEXTO02=DESCRIPCION, TEXTO03=ORDEN, TEXTO04=ESTADO('ACTIVO'/'INACTIVO')
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='VIATICO_TIPO'
        BEGIN
            SET @ACTIVE_TAB='viaticos-tipos';
            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));
            SET @VTEXTO04=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO04,''))));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>30
                SET @VFORM_ERROR='El código no puede superar 30 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>100
                SET @VFORM_ERROR='La descripción no puede superar 100 caracteres.';
            ELSE IF @VTEXTO03 LIKE '%[^0-9]%' OR NULLIF(@VTEXTO03,'') IS NULL
                SET @VFORM_ERROR='El orden debe ser un número entero.';
            ELSE IF @VTEXTO04 NOT IN ('ACTIVO','INACTIVO')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_VIATICOS_TIPOS WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El tipo de viático seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS(SELECT 1 FROM dbo.VCT_PRM_VIATICOS_TIPOS WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(CODIGO))) COLLATE DATABASE_DEFAULT=@VTEXTO01 COLLATE DATABASE_DEFAULT AND (@ID_ROW_INT IS NULL OR ID<>@ID_ROW_INT))
                SET @VFORM_ERROR='Ya existe otro tipo de viático con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                    INSERT INTO dbo.VCT_PRM_VIATICOS_TIPOS(CODIGO,DESCRIPCION,ORDEN,ESTADO,FECHA_ALTA,USUARIO_ALTA)
                    VALUES(@VTEXTO01,@VTEXTO02,CONVERT(INT,@VTEXTO03),@VTEXTO04,GETDATE(),@IAGENTE);
                ELSE
                    UPDATE dbo.VCT_PRM_VIATICOS_TIPOS SET DESCRIPCION=@VTEXTO02,ORDEN=CONVERT(INT,@VTEXTO03),ESTADO=@VTEXTO04,FECHA_UPD=GETDATE(),USUARIO_UPD=@IAGENTE WHERE ID=@ID_ROW_INT;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        /* --------------------------------------------------------
           EMAIL TEMPLATE - MODELO V5
           Unica tabla de negocio utilizada:
             dbo.VCT_PRM_EMAIL_TEMPLATES

           TEXTO01 = CODIGO
           TEXTO02 = DESCRIPCION
           TEXTO03 = TIPO_ENVIO          MANUAL | AUTOMATICO
           TEXTO04 = DESTINO_TIPO        ANALISTA | GERENCIA | CONSULTOR | CLIENTE | LIBRE
           TEXTO05 = DESTINO_LIBRE
           TEXTO06 = CC_TIPO             NINGUNO | ANALISTA | GERENCIA | CONSULTOR | CLIENTE | LIBRE
           TEXTO07 = CC_LIBRE
           TEXTO08 = ESTADO              ACTIVO | INACTIVO
           TEXTO09 = ASUNTO
           TEXTO10 = HTML_CONTENIDO
           TEXTO11 = DISENO_JSON
           -------------------------------------------------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL_TEMPLATE'
        BEGIN
            SET @ACTIVE_TAB='email-templates';

            SET @VTEXTO01=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO01,''))));
            SET @VTEXTO02=LTRIM(RTRIM(ISNULL(@VTEXTO02,'')));
            SET @VTEXTO03=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO03,''))));
            SET @VTEXTO04=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO04,''))));
            SET @VTEXTO05=LTRIM(RTRIM(ISNULL(@VTEXTO05,'')));
            SET @VTEXTO06=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO06,''))));
            SET @VTEXTO07=LTRIM(RTRIM(ISNULL(@VTEXTO07,'')));
            SET @VTEXTO08=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO08,''))));
            SET @VTEXTO09=LTRIM(RTRIM(ISNULL(@VTEXTO09,'')));
            SET @VTEXTO10=LTRIM(RTRIM(ISNULL(@VTEXTO10,'')));
            SET @VTEXTO11=LTRIM(RTRIM(ISNULL(@VTEXTO11,'')));

            IF NULLIF(@VTEXTO01,'') IS NULL
                SET @VFORM_ERROR='El código técnico del template es obligatorio.';
            ELSE IF LEN(@VTEXTO01)>50
                SET @VFORM_ERROR='El código técnico no puede superar 50 caracteres.';
            ELSE IF NULLIF(@VTEXTO02,'') IS NULL
                SET @VFORM_ERROR='La descripción del template es obligatoria.';
            ELSE IF LEN(@VTEXTO02)>200
                SET @VFORM_ERROR='La descripción no puede superar 200 caracteres.';
            ELSE IF @VTEXTO03 NOT IN ('MANUAL','AUTOMATICO')
                SET @VFORM_ERROR='El tipo de envío seleccionado no es válido.';
            ELSE IF @VTEXTO04 NOT IN ('ANALISTA','GERENCIA','CONSULTOR','CLIENTE','LIBRE')
                SET @VFORM_ERROR='El destino seleccionado no es válido.';
            ELSE IF @VTEXTO04='LIBRE' AND NULLIF(@VTEXTO05,'') IS NULL
                SET @VFORM_ERROR='Debe indicar el email de destino libre.';
            ELSE IF @VTEXTO06 NOT IN ('NINGUNO','ANALISTA','GERENCIA','CONSULTOR','CLIENTE','LIBRE')
                SET @VFORM_ERROR='La copia seleccionada no es válida.';
            ELSE IF @VTEXTO06='LIBRE' AND NULLIF(@VTEXTO07,'') IS NULL
                SET @VFORM_ERROR='Debe indicar el email de copia libre.';
            ELSE IF @VTEXTO08 NOT IN ('ACTIVO','INACTIVO')
                SET @VFORM_ERROR='El estado seleccionado no es válido.';
            ELSE IF NULLIF(@VTEXTO09,'') IS NULL
                SET @VFORM_ERROR='El asunto es obligatorio.';
            ELSE IF LEN(@VTEXTO09)>500
                SET @VFORM_ERROR='El asunto no puede superar 500 caracteres.';
            ELSE IF NULLIF(@VTEXTO10,'') IS NULL
                SET @VFORM_ERROR='El cuerpo HTML del email es obligatorio.';
            ELSE IF NULLIF(@VTEXTO11,'') IS NULL
                SET @VFORM_ERROR='No se recibió la definición del diseñador del email.';

            IF @VTEXTO04<>'LIBRE' SET @VTEXTO05='';
            IF @VTEXTO06<>'LIBRE' SET @VTEXTO07='';

            IF @VFORM_ERROR='' AND @ID_ROW_INT IS NOT NULL
               AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK) WHERE ID=@ID_ROW_INT)
                SET @VFORM_ERROR='El template seleccionado no existe.';

            IF @VFORM_ERROR='' AND EXISTS
            (
                SELECT 1
                FROM dbo.VCT_PRM_EMAIL_TEMPLATES T WITH(NOLOCK)
                WHERE UPPER(LTRIM(RTRIM(T.CODIGO))) COLLATE DATABASE_DEFAULT=
                      @VTEXTO01 COLLATE DATABASE_DEFAULT
                  AND (@ID_ROW_INT IS NULL OR T.ID<>@ID_ROW_INT)
            )
                SET @VFORM_ERROR='Ya existe otro template con el mismo código.';

            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @ID_ROW_INT IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PRM_EMAIL_TEMPLATES
                    (
                        CODIGO,DESCRIPCION,TIPO_ENVIO,
                        DESTINO_TIPO,DESTINO_LIBRE,
                        CC_TIPO,CC_LIBRE,
                        ESTADO,ASUNTO,HTML_CONTENIDO,DISENO_JSON,
                        FECHA_ALTA,USUARIO_ALTA,
                        FECHA_UPD,USUARIO_UPD
                    )
                    VALUES
                    (
                        @VTEXTO01,@VTEXTO02,@VTEXTO03,
                        @VTEXTO04,NULLIF(@VTEXTO05,''),
                        @VTEXTO06,NULLIF(@VTEXTO07,''),
                        @VTEXTO08,@VTEXTO09,@VTEXTO10,@VTEXTO11,
                        GETDATE(),@IAGENTE,
                        NULL,NULL
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
                       SET CODIGO=@VTEXTO01,
                           DESCRIPCION=@VTEXTO02,
                           TIPO_ENVIO=@VTEXTO03,
                           DESTINO_TIPO=@VTEXTO04,
                           DESTINO_LIBRE=NULLIF(@VTEXTO05,''),
                           CC_TIPO=@VTEXTO06,
                           CC_LIBRE=NULLIF(@VTEXTO07,''),
                           ESTADO=@VTEXTO08,
                           ASUNTO=@VTEXTO09,
                           HTML_CONTENIDO=@VTEXTO10,
                           DISENO_JSON=@VTEXTO11,
                           FECHA_UPD=GETDATE(),
                           USUARIO_UPD=@IAGENTE
                     WHERE ID=@ID_ROW_INT;
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;

        IF @VFORM_ENTITY NOT IN (
            'NORMA','EMAIL_TEMPLATE',
            'GESTION_TIPO','GESTION_SUBTIPO','GESTION_RESULTADO','GESTION_ESTADO','GESTION_PRIORIDAD',
            'PROYECTO_ESTADO','PROYECTO_ROL','VIATICO_TIPO'
        ) AND @VFORM_ERROR=''
            SET @VFORM_ERROR='La entidad del formulario no es válida.';

        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;

        IF @VFORM_ERROR=''
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET IDSELEC01=NULL,
                   TEXTO01=NULL,TEXTO02=NULL,TEXTO03=NULL,TEXTO04=NULL,
                   TEXTO05=NULL,TEXTO06=NULL,TEXTO07=NULL,TEXTO08=NULL,
                   TEXTO09=NULL,TEXTO10=NULL,TEXTO11=NULL,TEXTO30=NULL,
                   FLAG01=0,FLAG02=0,FLAG03=0,
                   ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END
        ELSE
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET FLAG01=0,
                   FLAG03=0,
                   ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END;
    END;

    /* Error de eliminación: se muestra en la página, no se abre un form. */
    IF @VFORM_ERROR<>'' AND @VFORM_REOPEN=0
    BEGIN
        SET @HTML_FEEDBACK=
            '<div class="vct-alert vct-alert-danger vct-config-feedback">'+
            REPLACE(REPLACE(REPLACE(ISNULL(@VFORM_ERROR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</div>';
    END;

    /* ============================================================
       7. ACCIONES GENERICAS: CREATE / EDIT
       ============================================================ */
    IF @CAN_CREATE=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctConfigNormaModal',
             @FORM_TITLE='Nueva norma',
             @FORM_SUBTITLE='Complete los datos de la norma.',
             @FORM_ICON='file-text',
             @BUTTON_TEXT='Nuevo',
             @BUTTON_ICON='user-plus',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Nueva norma',
             @OUTHTML=@HTML_NORMA_CREATE OUTPUT;

        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigGestionTipoModal',@FORM_TITLE='Nuevo tipo de gestión',@FORM_SUBTITLE='Complete los datos del tipo.',@FORM_ICON='settings',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo tipo',@OUTHTML=@HTML_GESTION_TIPO_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigGestionSubtipoModal',@FORM_TITLE='Nuevo subtipo de gestión',@FORM_SUBTITLE='Complete los datos del subtipo.',@FORM_ICON='settings',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo subtipo',@OUTHTML=@HTML_GESTION_SUBTIPO_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigGestionResultadoModal',@FORM_TITLE='Nuevo resultado de gestión',@FORM_SUBTITLE='Complete los datos del resultado.',@FORM_ICON='file-text',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo resultado',@OUTHTML=@HTML_GESTION_RESULTADO_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigGestionEstadoModal',@FORM_TITLE='Nuevo estado de gestión',@FORM_SUBTITLE='Complete los datos del estado.',@FORM_ICON='settings',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo estado',@OUTHTML=@HTML_GESTION_ESTADO_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigGestionPrioridadModal',@FORM_TITLE='Nueva prioridad de gestión',@FORM_SUBTITLE='Complete los datos de la prioridad.',@FORM_ICON='settings',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nueva prioridad',@OUTHTML=@HTML_GESTION_PRIORIDAD_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigProyectoEstadoModal',@FORM_TITLE='Nuevo estado de proyecto',@FORM_SUBTITLE='Complete los datos del estado.',@FORM_ICON='settings',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo estado',@OUTHTML=@HTML_PROYECTO_ESTADO_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigProyectoRolModal',@FORM_TITLE='Nuevo rol de proyecto',@FORM_SUBTITLE='Complete los datos del rol.',@FORM_ICON='briefcase',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo rol',@OUTHTML=@HTML_PROYECTO_ROL_CREATE OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='CREATE',@TARGET_FORM='vctConfigViaticoTipoModal',@FORM_TITLE='Nuevo tipo de viático',@FORM_SUBTITLE='Complete los datos del tipo.',@FORM_ICON='briefcase',@BUTTON_TEXT='Nuevo',@BUTTON_ICON='user-plus',@BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',@TOOLTIP='Nuevo tipo',@OUTHTML=@HTML_VIATICO_TIPO_CREATE OUTPUT;
    END;

    IF @CAN_EDIT=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',
             @TARGET_FORM='vctConfigNormaModal',
             @FORM_TITLE='Editar norma',
             @FORM_SUBTITLE='Modifique los datos de la norma seleccionada.',
             @FORM_ICON='file-text',
             @BUTTON_TEXT='',
             @BUTTON_ICON='edit',
             @BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',
             @TOOLTIP='Editar norma',
             @SOURCE_SELECTOR='[data-vct-row]',
             @OUTHTML=@HTML_NORMA_EDIT OUTPUT;

        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigGestionTipoModal',@FORM_TITLE='Editar tipo de gestión',@FORM_SUBTITLE='Modifique los datos del tipo seleccionado.',@FORM_ICON='settings',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar tipo',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_GESTION_TIPO_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigGestionSubtipoModal',@FORM_TITLE='Editar subtipo de gestión',@FORM_SUBTITLE='Modifique los datos del subtipo seleccionado.',@FORM_ICON='settings',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar subtipo',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_GESTION_SUBTIPO_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigGestionResultadoModal',@FORM_TITLE='Editar resultado de gestión',@FORM_SUBTITLE='Modifique los datos del resultado seleccionado.',@FORM_ICON='file-text',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar resultado',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_GESTION_RESULTADO_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigGestionEstadoModal',@FORM_TITLE='Editar estado de gestión',@FORM_SUBTITLE='Modifique los datos del estado seleccionado.',@FORM_ICON='settings',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar estado',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_GESTION_ESTADO_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigGestionPrioridadModal',@FORM_TITLE='Editar prioridad de gestión',@FORM_SUBTITLE='Modifique los datos de la prioridad seleccionada.',@FORM_ICON='settings',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar prioridad',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_GESTION_PRIORIDAD_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigProyectoEstadoModal',@FORM_TITLE='Editar estado de proyecto',@FORM_SUBTITLE='Modifique los datos del estado seleccionado.',@FORM_ICON='settings',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar estado',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_PROYECTO_ESTADO_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigProyectoRolModal',@FORM_TITLE='Editar rol de proyecto',@FORM_SUBTITLE='Modifique los datos del rol seleccionado.',@FORM_ICON='briefcase',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar rol',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_PROYECTO_ROL_EDIT OUTPUT;
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION @MODE='EDIT',@TARGET_FORM='vctConfigViaticoTipoModal',@FORM_TITLE='Editar tipo de viático',@FORM_SUBTITLE='Modifique los datos del tipo seleccionado.',@FORM_ICON='briefcase',@BUTTON_TEXT='',@BUTTON_ICON='edit',@BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',@TOOLTIP='Editar tipo',@SOURCE_SELECTOR='[data-vct-row]',@OUTHTML=@HTML_VIATICO_TIPO_EDIT OUTPUT;
    END;

    /* ============================================================
       9. DATASET NORMAS
       ============================================================ */
    SELECT @CNT_NORMAS=COUNT(*)
    FROM dbo.VCT_PRM_NORMAS WITH(NOLOCK);

    SELECT @HTML_NORMAS_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row '+
            'data-vct-id="'+CONVERT(VARCHAR(20),N.ID)+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-estado="'+ISNULL(N.ESTADO,'')+'" '+
            'data-vct-entity="NORMA" '+
            'data-vct-active-tab="normas" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-filter-estado="'+ISNULL(N.ESTADO,'')+'">'+

            '<td data-label="Norma"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+ISNULL(N.ESTADO,'')+'">'+CASE WHEN N.ESTADO='ACTIVO' THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                ISNULL(@HTML_NORMA_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN
                    '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" '+
                    'data-vct-config-delete="true" data-vct-target="vctConfigNormaModal" '+
                    'data-vct-entity="NORMA" data-vct-tab="normas" data-vct-tooltip="Eliminar norma">'+
                    '<span data-vct-icon="trash"></span></button>'
                ELSE '' END+
            '</td>'+
            '</tr>'
        FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
        ORDER BY N.DESCRIPCION,N.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');


    SELECT @CNT_NORMAS_ACTIVAS=COUNT(*) FROM dbo.VCT_PRM_NORMAS WITH(NOLOCK) WHERE ESTADO='ACTIVO';
    SET @VPCT_NORMAS_ACT=CASE WHEN @CNT_NORMAS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_NORMAS_ACTIVAS*100.0/@CNT_NORMAS,0)) END;
    SET @HTML_NORMAS_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_NORMAS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_NORMAS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_NORMAS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activas <b>'+CONVERT(VARCHAR(20),@CNT_NORMAS_ACTIVAS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivas <b>'+CONVERT(VARCHAR(20),@CNT_NORMAS-@CNT_NORMAS_ACTIVAS)+'</b></div>'+
            '</div>'+
        '</div>';

    /* ============================================================
       9b. DATASETS GESTIONES (Tipos/Resultados: catalogo simple)
       ============================================================ */
    SELECT @CNT_GESTION_TIPOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_TIPOS WITH(NOLOCK);
    SELECT @HTML_GESTION_TIPO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),G.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),G.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN G.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="GESTION_TIPO" data-vct-active-tab="gestiones-tipos" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,'')+' '+ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),G.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN G.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_GESTION_TIPO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigGestionTipoModal" data-vct-entity="GESTION_TIPO" data-vct-tab="gestiones-tipos" data-vct-tooltip="Eliminar tipo"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_GESTIONES_TIPOS G WITH(NOLOCK)
        ORDER BY G.ORDEN,G.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_GESTION_TIPOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_TIPOS WITH(NOLOCK) WHERE ACTIVO=1;
    SET @VPCT_GESTION_TIPOS_ACT=CASE WHEN @CNT_GESTION_TIPOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_TIPOS_ACTIVOS*100.0/@CNT_GESTION_TIPOS,0)) END;
    SET @HTML_GESTION_TIPO_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_TIPOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_TIPOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_TIPOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_TIPOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_TIPOS-@CNT_GESTION_TIPOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    SELECT @CNT_GESTION_RESULTADOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WITH(NOLOCK);
    SELECT @HTML_GESTION_RESULTADO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),G.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),G.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN G.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="GESTION_RESULTADO" data-vct-active-tab="gestiones-resultados" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,'')+' '+ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),G.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN G.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_GESTION_RESULTADO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigGestionResultadoModal" data-vct-entity="GESTION_RESULTADO" data-vct-tab="gestiones-resultados" data-vct-tooltip="Eliminar resultado"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_GESTIONES_RESULTADOS G WITH(NOLOCK)
        ORDER BY G.ORDEN,G.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_GESTION_RESULTADOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WITH(NOLOCK) WHERE ACTIVO=1;
    SET @VPCT_GESTION_RESULTADOS_ACT=CASE WHEN @CNT_GESTION_RESULTADOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_RESULTADOS_ACTIVOS*100.0/@CNT_GESTION_RESULTADOS,0)) END;
    SET @HTML_GESTION_RESULTADO_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_RESULTADOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_RESULTADOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_RESULTADOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_RESULTADOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_RESULTADOS-@CNT_GESTION_RESULTADOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    SELECT @CNT_GESTION_ESTADOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK);
    SELECT @HTML_GESTION_ESTADO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),G.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),G.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN G.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-esfinal="'+CASE WHEN G.ES_FINAL=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="GESTION_ESTADO" data-vct-active-tab="gestiones-estados" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,'')+' '+ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Final">'+CASE WHEN G.ES_FINAL=1 THEN 'Sí' ELSE 'No' END+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),G.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN G.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_GESTION_ESTADO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigGestionEstadoModal" data-vct-entity="GESTION_ESTADO" data-vct-tab="gestiones-estados" data-vct-tooltip="Eliminar estado"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_GESTIONES_ESTADOS G WITH(NOLOCK)
        ORDER BY G.ORDEN,G.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_GESTION_ESTADOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK) WHERE ACTIVO=1;
    SELECT @CNT_GESTION_ESTADOS_FINALES=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_ESTADOS WITH(NOLOCK) WHERE ES_FINAL=1;
    SET @VPCT_GESTION_ESTADOS_ACT=CASE WHEN @CNT_GESTION_ESTADOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_ESTADOS_ACTIVOS*100.0/@CNT_GESTION_ESTADOS,0)) END;
    SET @VPCT_GESTION_ESTADOS_FIN=CASE WHEN @CNT_GESTION_ESTADOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_ESTADOS_FINALES*100.0/@CNT_GESTION_ESTADOS,0)) END;
    SET @HTML_GESTION_ESTADO_DONUT_ACT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_ESTADOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_ESTADOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_ESTADOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS-@CNT_GESTION_ESTADOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';
    SET @HTML_GESTION_ESTADO_DONUT_FIN=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-blue" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_ESTADOS_FIN)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_ESTADOS_FIN)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_ESTADOS_FIN)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-blue"></span> Finales <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS_FINALES)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> No finales <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS-@CNT_GESTION_ESTADOS_FINALES)+'</b></div>'+
            '</div>'+
        '</div>';

    SELECT @CNT_GESTION_PRIORIDADES=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK);
    SELECT @HTML_GESTION_PRIORIDAD_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),G.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-nivel="'+CONVERT(VARCHAR(20),G.NIVEL)+'" '+
            'data-vct-activo="'+CASE WHEN G.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="GESTION_PRIORIDAD" data-vct-active-tab="gestiones-prioridades" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,'')+' '+ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Nivel">'+CONVERT(VARCHAR(20),G.NIVEL)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN G.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_GESTION_PRIORIDAD_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigGestionPrioridadModal" data-vct-entity="GESTION_PRIORIDAD" data-vct-tab="gestiones-prioridades" data-vct-tooltip="Eliminar prioridad"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES G WITH(NOLOCK)
        ORDER BY G.NIVEL,G.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_GESTION_PRIORIDADES_ACTIVAS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK) WHERE ACTIVO=1;
    SELECT @CNT_GESTION_PRIORIDADES_NIVELMAX=ISNULL(MAX(NIVEL),0) FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK);
    SET @VPCT_GESTION_PRIORIDADES_ACT=CASE WHEN @CNT_GESTION_PRIORIDADES=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_PRIORIDADES_ACTIVAS*100.0/@CNT_GESTION_PRIORIDADES,0)) END;
    SET @HTML_GESTION_PRIORIDAD_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_PRIORIDADES_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_PRIORIDADES_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_PRIORIDADES_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activas <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES_ACTIVAS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivas <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES-@CNT_GESTION_PRIORIDADES_ACTIVAS)+'</b></div>'+
            '</div>'+
        '</div>';

    DECLARE @VMAX_NIVEL_PRIORIDAD INT = ISNULL((SELECT MAX(NIVEL) FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WITH(NOLOCK)),0);
    IF @VMAX_NIVEL_PRIORIDAD=0 SET @VMAX_NIVEL_PRIORIDAD=1;
    SELECT @HTML_GESTION_PRIORIDAD_BARS=ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),G.NIVEL)+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,G.NIVEL*100.0/@VMAX_NIVEL_PRIORIDAD))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES G WITH(NOLOCK)
        ORDER BY G.NIVEL DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_GESTION_PRIORIDAD_BARS='' SET @HTML_GESTION_PRIORIDAD_BARS='<div class="vct-gantt-empty">Sin datos</div>';

    SELECT @CNT_GESTION_SUBTIPOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK);
    SELECT @HTML_GESTION_SUBTIPO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),G.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),G.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN G.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-idtipo="'+CONVERT(VARCHAR(20),G.ID_TIPO)+'" '+
            'data-vct-filter-estado="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="GESTION_SUBTIPO" data-vct-active-tab="gestiones-subtipos" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,'')+' '+ISNULL(G.DESCRIPCION,'')+' '+ISNULL(T.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(G.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(G.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td data-label="Tipo">'+REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),G.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN G.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN G.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_GESTION_SUBTIPO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigGestionSubtipoModal" data-vct-entity="GESTION_SUBTIPO" data-vct-tab="gestiones-subtipos" data-vct-tooltip="Eliminar subtipo"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS G WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK) ON T.ID=G.ID_TIPO
        ORDER BY T.DESCRIPCION,G.ORDEN,G.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_GESTION_SUBTIPOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK) WHERE ACTIVO=1;
    SELECT @CNT_GESTION_SUBTIPOS_TIPOSCONSUB=COUNT(DISTINCT ID_TIPO) FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK);
    SET @VPCT_GESTION_SUBTIPOS_ACT=CASE WHEN @CNT_GESTION_SUBTIPOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_GESTION_SUBTIPOS_ACTIVOS*100.0/@CNT_GESTION_SUBTIPOS,0)) END;
    SET @HTML_GESTION_SUBTIPO_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_GESTION_SUBTIPOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_GESTION_SUBTIPOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_GESTION_SUBTIPOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS-@CNT_GESTION_SUBTIPOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    DECLARE @VMAX_SUBTIPOS_POR_TIPO INT = ISNULL((SELECT MAX(CNT) FROM (SELECT COUNT(*) CNT FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WITH(NOLOCK) GROUP BY ID_TIPO) X),0);
    IF @VMAX_SUBTIPOS_POR_TIPO=0 SET @VMAX_SUBTIPOS_POR_TIPO=1;
    SELECT @HTML_GESTION_SUBTIPO_BARS=ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),COUNT(*))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,COUNT(*)*100.0/@VMAX_SUBTIPOS_POR_TIPO))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS G WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK) ON T.ID=G.ID_TIPO
        GROUP BY T.DESCRIPCION
        ORDER BY COUNT(*) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_GESTION_SUBTIPO_BARS='' SET @HTML_GESTION_SUBTIPO_BARS='<div class="vct-gantt-empty">Sin datos</div>';

    SELECT @HTML_OPTIONS_GESTION_TIPO=ISNULL((
        SELECT '<option value="'+CONVERT(VARCHAR(20),T.ID)+'">'+REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</option>'
        FROM dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK)
        ORDER BY T.ORDEN,T.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* ============================================================
       9c. DATASETS PROYECTOS (Estados/Roles) y VIATICOS (Tipos)
       ============================================================ */
    SELECT @CNT_PROYECTO_ESTADOS=COUNT(*) FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK);
    SELECT @HTML_PROYECTO_ESTADO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),P.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),P.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN P.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN P.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="PROYECTO_ESTADO" data-vct-active-tab="proyectos-estados" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,'')+' '+ISNULL(P.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(P.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),P.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN P.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN P.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_PROYECTO_ESTADO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigProyectoEstadoModal" data-vct-entity="PROYECTO_ESTADO" data-vct-tab="proyectos-estados" data-vct-tooltip="Eliminar estado"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_PROYECTOS_ESTADOS P WITH(NOLOCK)
        ORDER BY P.ORDEN,P.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_PROYECTO_ESTADOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE ACTIVO=1;
    SET @VPCT_PROYECTO_ESTADOS_ACT=CASE WHEN @CNT_PROYECTO_ESTADOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_PROYECTO_ESTADOS_ACTIVOS*100.0/@CNT_PROYECTO_ESTADOS,0)) END;
    SET @HTML_PROYECTO_ESTADO_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_PROYECTO_ESTADOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_PROYECTO_ESTADOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_PROYECTO_ESTADOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ESTADOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ESTADOS-@CNT_PROYECTO_ESTADOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    SELECT @CNT_PROYECTO_ROLES=COUNT(*) FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK);
    SELECT @HTML_PROYECTO_ROL_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),P.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-tipomiembro="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.TIPO_MIEMBRO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),P.ORDEN)+'" '+
            'data-vct-activo="'+CASE WHEN P.ACTIVO=1 THEN '1' ELSE '0' END+'" '+
            'data-vct-filter-estado="'+CASE WHEN P.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'" '+
            'data-vct-entity="PROYECTO_ROL" data-vct-active-tab="proyectos-roles" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,'')+' '+ISNULL(P.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(P.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td data-label="Tipo de miembro">'+REPLACE(REPLACE(REPLACE(ISNULL(P.TIPO_MIEMBRO,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),P.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+CASE WHEN P.ACTIVO=1 THEN 'ACTIVO' ELSE 'INACTIVO' END+'">'+CASE WHEN P.ACTIVO=1 THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_PROYECTO_ROL_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigProyectoRolModal" data-vct-entity="PROYECTO_ROL" data-vct-tab="proyectos-roles" data-vct-tooltip="Eliminar rol"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_PROYECTOS_ROLES P WITH(NOLOCK)
        ORDER BY P.ORDEN,P.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_PROYECTO_ROLES_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE ACTIVO=1;
    SELECT @CNT_PROYECTO_ROLES_CONTIPO=COUNT(*) FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE NULLIF(LTRIM(RTRIM(TIPO_MIEMBRO)),'') IS NOT NULL;
    SET @VPCT_PROYECTO_ROLES_ACT=CASE WHEN @CNT_PROYECTO_ROLES=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_PROYECTO_ROLES_ACTIVOS*100.0/@CNT_PROYECTO_ROLES,0)) END;
    SET @HTML_PROYECTO_ROL_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_PROYECTO_ROLES_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_PROYECTO_ROLES_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_PROYECTO_ROLES_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES-@CNT_PROYECTO_ROLES_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    DECLARE @VMAX_ROLES_POR_TIPO INT = ISNULL((SELECT MAX(CNT) FROM (SELECT COUNT(*) CNT FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE NULLIF(LTRIM(RTRIM(TIPO_MIEMBRO)),'') IS NOT NULL GROUP BY TIPO_MIEMBRO) X),0);
    IF @VMAX_ROLES_POR_TIPO=0 SET @VMAX_ROLES_POR_TIPO=1;
    SELECT @HTML_PROYECTO_ROL_BARS=ISNULL((
        SELECT TOP 5
            '<div class="vct-barchart-col"><span class="vct-barchart-value">'+CONVERT(VARCHAR(20),COUNT(*))+'</span><div class="vct-barchart-bar" style="height:'+CONVERT(VARCHAR(10),CONVERT(INT,COUNT(*)*100.0/@VMAX_ROLES_POR_TIPO))+'%"></div><span class="vct-barchart-label">'+REPLACE(REPLACE(REPLACE(TIPO_MIEMBRO,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span></div>'
        FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK)
        WHERE NULLIF(LTRIM(RTRIM(TIPO_MIEMBRO)),'') IS NOT NULL
        GROUP BY TIPO_MIEMBRO
        ORDER BY COUNT(*) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
    IF @HTML_PROYECTO_ROL_BARS='' SET @HTML_PROYECTO_ROL_BARS='<div class="vct-gantt-empty">Sin roles con Tipo de miembro asignado todavía</div>';

    SELECT @CNT_VIATICO_TIPOS=COUNT(*) FROM dbo.VCT_PRM_VIATICOS_TIPOS WITH(NOLOCK);
    SELECT @HTML_VIATICO_TIPO_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row data-vct-id="'+CONVERT(VARCHAR(20),V.ID)+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-orden="'+CONVERT(VARCHAR(20),V.ORDEN)+'" '+
            'data-vct-estado="'+ISNULL(V.ESTADO,'')+'" '+
            'data-vct-filter-estado="'+ISNULL(V.ESTADO,'')+'" '+
            'data-vct-entity="VIATICO_TIPO" data-vct-active-tab="viaticos-tipos" '+
            'data-vct-search="'+REPLACE(REPLACE(REPLACE(ISNULL(V.CODIGO,'')+' '+ISNULL(V.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'">'+
            '<td data-label="Código"><strong>'+REPLACE(REPLACE(REPLACE(ISNULL(V.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</strong></td>'+
            '<td data-label="Descripción">'+REPLACE(REPLACE(REPLACE(ISNULL(V.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Orden">'+CONVERT(VARCHAR(20),V.ORDEN)+'</td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+ISNULL(V.ESTADO,'')+'">'+CASE WHEN V.ESTADO='ACTIVO' THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+ISNULL(@HTML_VIATICO_TIPO_EDIT,'')+
                CASE WHEN @CAN_DELETE=1 THEN '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" data-vct-config-delete="true" data-vct-target="vctConfigViaticoTipoModal" data-vct-entity="VIATICO_TIPO" data-vct-tab="viaticos-tipos" data-vct-tooltip="Eliminar tipo"><span data-vct-icon="trash"></span></button>' ELSE '' END+
            '</td></tr>'
        FROM dbo.VCT_PRM_VIATICOS_TIPOS V WITH(NOLOCK)
        ORDER BY V.ORDEN,V.DESCRIPCION
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    SELECT @CNT_VIATICO_TIPOS_ACTIVOS=COUNT(*) FROM dbo.VCT_PRM_VIATICOS_TIPOS WITH(NOLOCK) WHERE ESTADO='ACTIVO';
    SET @VPCT_VIATICO_TIPOS_ACT=CASE WHEN @CNT_VIATICO_TIPOS=0 THEN 0 ELSE CONVERT(INT,ROUND(@CNT_VIATICO_TIPOS_ACTIVOS*100.0/@CNT_VIATICO_TIPOS,0)) END;
    SET @HTML_VIATICO_TIPO_DONUT=
        '<div class="vct-donut-row">'+
            '<svg viewBox="0 0 36 36" class="vct-donut">'+
                '<circle class="vct-donut-track" cx="18" cy="18" r="15.9155"></circle>'+
                '<circle class="vct-donut-seg is-mint" cx="18" cy="18" r="15.9155" stroke-dasharray="'+CONVERT(VARCHAR(10),@VPCT_VIATICO_TIPOS_ACT)+' '+CONVERT(VARCHAR(10),100-@VPCT_VIATICO_TIPOS_ACT)+'" stroke-dashoffset="25"></circle>'+
                '<text x="18" y="20.5" text-anchor="middle" class="vct-donut-label">'+CONVERT(VARCHAR(10),@VPCT_VIATICO_TIPOS_ACT)+'%</text>'+
            '</svg>'+
            '<div class="vct-donut-legend">'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-mint"></span> Activos <b>'+CONVERT(VARCHAR(20),@CNT_VIATICO_TIPOS_ACTIVOS)+'</b></div>'+
                '<div class="vct-donut-legend-item"><span class="vct-donut-dot is-track"></span> Inactivos <b>'+CONVERT(VARCHAR(20),@CNT_VIATICO_TIPOS-@CNT_VIATICO_TIPOS_ACTIVOS)+'</b></div>'+
            '</div>'+
        '</div>';

    /* ============================================================
       10. DATASET TEMPLATES - MODELO V5
       ============================================================ */
    IF OBJECT_ID('tempdb..#EMAIL_TEMPLATES') IS NOT NULL DROP TABLE #EMAIL_TEMPLATES;

    SELECT
        ID_TEMPLATE=CONVERT(VARCHAR(100),T.ID),
        T.CODIGO,
        T.DESCRIPCION,
        T.TIPO_ENVIO,
        T.DESTINO_TIPO,
        DESTINO_LIBRE=ISNULL(T.DESTINO_LIBRE,''),
        T.CC_TIPO,
        CC_LIBRE=ISNULL(T.CC_LIBRE,''),
        T.ESTADO,
        T.ASUNTO,
        HTML_CONTENIDO=ISNULL(T.HTML_CONTENIDO,''),
        DISENO_JSON=ISNULL(T.DISENO_JSON,''),
        ULTIMA_FECHA=ISNULL(T.FECHA_UPD,T.FECHA_ALTA),
        ULTIMO_USUARIO=ISNULL(NULLIF(T.USUARIO_UPD,''),ISNULL(T.USUARIO_ALTA,''))
    INTO #EMAIL_TEMPLATES
    FROM dbo.VCT_PRM_EMAIL_TEMPLATES T WITH(NOLOCK);

    SELECT @CNT_TEMPLATES=COUNT(*) FROM #EMAIL_TEMPLATES;

    SELECT @HTML_TEMPLATE_ROWS=ISNULL((
        SELECT
            '<tr data-vct-row '+
            'data-vct-id="'+T.ID_TEMPLATE+'" '+
            'data-vct-entity="EMAIL_TEMPLATE" '+
            'data-vct-active-tab="email-templates" '+
            'data-vct-search="'+
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(T.ID_TEMPLATE,'')+' '+ISNULL(T.CODIGO,'')+' '+ISNULL(T.DESCRIPCION,'')+' '+
                    ISNULL(T.TIPO_ENVIO,'')+' '+ISNULL(T.DESTINO_TIPO,'')+' '+ISNULL(T.CC_TIPO,'')+' '+
                    ISNULL(T.ASUNTO,'')+' '+ISNULL(T.ESTADO,''),
                    '&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-filter-tipo="'+ISNULL(T.TIPO_ENVIO,'')+'" '+
            'data-vct-filter-destino="'+ISNULL(T.DESTINO_TIPO,'')+'" '+
            'data-vct-filter-estado="'+ISNULL(T.ESTADO,'')+'" '+
            'data-vct-codigo="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.CODIGO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-descripcion="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-tipo-envio="'+ISNULL(T.TIPO_ENVIO,'')+'" '+
            'data-vct-destino-tipo="'+ISNULL(T.DESTINO_TIPO,'')+'" '+
            'data-vct-destino-libre="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.DESTINO_LIBRE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-cc-tipo="'+ISNULL(T.CC_TIPO,'')+'" '+
            'data-vct-cc-libre="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.CC_LIBRE,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-estado="'+ISNULL(T.ESTADO,'')+'" '+
            'data-vct-asunto="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.ASUNTO,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'" '+
            'data-vct-html-contenido="'+
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    CAST(ISNULL(T.HTML_CONTENIDO,'') AS VARCHAR(MAX)),
                    '&',CAST('&amp;' AS VARCHAR(MAX))),
                    '"',CAST('&quot;' AS VARCHAR(MAX))),
                    '<',CAST('&lt;' AS VARCHAR(MAX))),
                    '>',CAST('&gt;' AS VARCHAR(MAX))),
                    '''',CAST('&#39;' AS VARCHAR(MAX)))+
            '" '+
            'data-vct-diseno-json="'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.DISENO_JSON,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;')+'">'+

            '<td data-label="Descripción">'+
                '<span class="vct-table-cell-text">'+REPLACE(REPLACE(REPLACE(ISNULL(T.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>'+
            '</td>'+
            '<td data-label="Asunto">'+
                '<span class="vct-table-cell-text">'+REPLACE(REPLACE(REPLACE(ISNULL(T.ASUNTO,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</span>'+
            '</td>'+
            '<td data-label="Destino">'+
                '<span class="vct-table-cell-text">'+
                CASE T.DESTINO_TIPO
                    WHEN 'ANALISTA' THEN 'Analista'
                    WHEN 'GERENCIA' THEN 'Gerencia'
                    WHEN 'CONSULTOR' THEN 'Consultor'
                    WHEN 'CLIENTE' THEN 'Cliente'
                    WHEN 'LIBRE' THEN 'Libre'
                    ELSE ISNULL(T.DESTINO_TIPO,'-') END+
                CASE WHEN T.DESTINO_TIPO='LIBRE' AND NULLIF(T.DESTINO_LIBRE,'') IS NOT NULL
                     THEN '<div class="vct-table-subtext">'+REPLACE(REPLACE(REPLACE(T.DESTINO_LIBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</div>' ELSE '' END+
                '</span>'+
            '</td>'+
            '<td data-label="CC">'+
                '<span class="vct-table-cell-text">'+
                CASE T.CC_TIPO
                    WHEN 'NINGUNO' THEN '-'
                    WHEN 'ANALISTA' THEN 'Analista'
                    WHEN 'GERENCIA' THEN 'Gerencia'
                    WHEN 'CONSULTOR' THEN 'Consultor'
                    WHEN 'CLIENTE' THEN 'Cliente'
                    WHEN 'LIBRE' THEN 'Libre'
                    ELSE ISNULL(T.CC_TIPO,'-') END+
                CASE WHEN T.CC_TIPO='LIBRE' AND NULLIF(T.CC_LIBRE,'') IS NOT NULL
                     THEN '<div class="vct-table-subtext">'+REPLACE(REPLACE(REPLACE(T.CC_LIBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</div>' ELSE '' END+
                '</span>'+
            '</td>'+
            '<td class="vct-text-center" data-label="Tipo envío"><span class="vct-badge '+CASE WHEN T.TIPO_ENVIO='AUTOMATICO' THEN 'vct-email-badge-auto' ELSE 'vct-email-badge-manual' END+'">'+
                CASE WHEN T.TIPO_ENVIO='AUTOMATICO' THEN 'Automático' ELSE 'Manual' END+'</span></td>'+
            '<td class="vct-text-center" data-label="Estado"><span class="vct-badge" data-vct-badge="'+ISNULL(T.ESTADO,'')+'">'+CASE WHEN T.ESTADO='ACTIVO' THEN 'Activo' ELSE 'Inactivo' END+'</span></td>'+
            '<td class="vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 THEN
                    '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-edit" data-vct-email-edit data-vct-tooltip="Editar template">'+
                    '<span data-vct-icon="edit"></span></button>'
                ELSE '' END+
                CASE WHEN @CAN_DELETE=1 THEN
                    '<button type="button" class="vct-grid-icon-btn vct-grid-icon-btn-delete" '+
                    'data-vct-config-delete="true" data-vct-target="vctConfigEmailTemplateEditor" '+
                    'data-vct-entity="EMAIL_TEMPLATE" data-vct-tab="email-templates" data-vct-tooltip="Eliminar template">'+
                    '<span data-vct-icon="trash"></span></button>'
                ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #EMAIL_TEMPLATES T
        ORDER BY CONVERT(INT,T.ID_TEMPLATE) ASC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');


    SET @FORM_ERR_NORMA=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='NORMA' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_TEMPLATE=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL_TEMPLATE' THEN @VFORM_ERROR ELSE '' END;
    SET @OPEN_NORMA=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='NORMA' THEN 1 ELSE 0 END;
    SET @OPEN_TEMPLATE=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL_TEMPLATE' THEN 1 ELSE 0 END;

    SET @FORM_ERR_GESTION_TIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_TIPO' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_GESTION_SUBTIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_SUBTIPO' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_GESTION_RESULTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_RESULTADO' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_GESTION_ESTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_ESTADO' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_GESTION_PRIORIDAD=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_PRIORIDAD' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_PROYECTO_ESTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='PROYECTO_ESTADO' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_PROYECTO_ROL=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='PROYECTO_ROL' THEN @VFORM_ERROR ELSE '' END;
    SET @FORM_ERR_VIATICO_TIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='VIATICO_TIPO' THEN @VFORM_ERROR ELSE '' END;

    SET @OPEN_GESTION_TIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_TIPO' THEN 1 ELSE 0 END;
    SET @OPEN_GESTION_SUBTIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_SUBTIPO' THEN 1 ELSE 0 END;
    SET @OPEN_GESTION_RESULTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_RESULTADO' THEN 1 ELSE 0 END;
    SET @OPEN_GESTION_ESTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_ESTADO' THEN 1 ELSE 0 END;
    SET @OPEN_GESTION_PRIORIDAD=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='GESTION_PRIORIDAD' THEN 1 ELSE 0 END;
    SET @OPEN_PROYECTO_ESTADO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='PROYECTO_ESTADO' THEN 1 ELSE 0 END;
    SET @OPEN_PROYECTO_ROL=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='PROYECTO_ROL' THEN 1 ELSE 0 END;
    SET @OPEN_VIATICO_TIPO=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='VIATICO_TIPO' THEN 1 ELSE 0 END;

    /* ============================================================
       12. FORM NORMA
       ============================================================ */
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT,
        FIELD_NAME VARCHAR(50),
        LABEL VARCHAR(150),
        FIELD_TYPE VARCHAR(20),
        COL_SPAN INT,
        REQUIRED BIT,
        MAX_LENGTH INT,
        PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100),
        DEFAULT_VALUE VARCHAR(MAX),
        READONLY BIT,
        HIDDEN BIT,
        HELP_TEXT VARCHAR(500),
        SOURCE_FIELD VARCHAR(100)
    );

    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Norma','TEXT',8,1,400,'Descripción de la norma',NULL,CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='NORMA' THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'descripcion'),
    (2,'TEXTO02','Estado','TEXT',4,1,20,'Seleccione estado',NULL,CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='NORMA' THEN @VTEXTO02 ELSE 'ACTIVO' END,0,0,NULL,'estado'),
    (3,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='NORMA' THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (4,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'NORMA',0,1,NULL,'entity'),
    (5,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'normas',0,1,NULL,'active-tab'),
    (6,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (7,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctConfigNormaModal',
         @TITLE='Norma',
         @SUBTITLE='Administración de normas del sistema.',
         @ICON='file-text',
         @LAYOUT='MODAL',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@FORM_ERR_NORMA,
         @OPEN_ON_RENDER=@OPEN_NORMA,
         @OUTHTML=@HTML_MODAL_NORMA OUTPUT;

    SET @HTML_MODAL_NORMA=ISNULL(@HTML_MODAL_NORMA,'')+
        '<template data-vct-field-options data-vct-target="vctConfigNormaModal" data-vct-field="TEXTO02" data-vct-placeholder="Seleccione estado">'+
            '<option value="ACTIVO">Activo</option>'+
            '<option value="INACTIVO">Inactivo</option>'+
        '</template>';

    /* ============================================================
       12b. FORMS GESTIONES
       ============================================================ */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,50,'Código',NULL,CASE WHEN @OPEN_GESTION_TIPO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,150,'Descripción',NULL,CASE WHEN @OPEN_GESTION_TIPO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO03','Orden','NUMBER',6,1,NULL,'0',NULL,CASE WHEN @OPEN_GESTION_TIPO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (4,'TEXTO04','Estado','TEXT',6,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_GESTION_TIPO=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_GESTION_TIPO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'GESTION_TIPO',0,1,NULL,'entity'),
    (7,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'gestiones-tipos',0,1,NULL,'active-tab'),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigGestionTipoModal',@TITLE='Tipo de gestión',@SUBTITLE='Administración de tipos de gestión.',@ICON='settings',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_GESTION_TIPO,@OPEN_ON_RENDER=@OPEN_GESTION_TIPO,@OUTHTML=@HTML_MODAL_GESTION_TIPO OUTPUT;
    SET @HTML_MODAL_GESTION_TIPO=ISNULL(@HTML_MODAL_GESTION_TIPO,'')+'<template data-vct-field-options data-vct-target="vctConfigGestionTipoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,50,'Código',NULL,CASE WHEN @OPEN_GESTION_RESULTADO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,150,'Descripción',NULL,CASE WHEN @OPEN_GESTION_RESULTADO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO03','Orden','NUMBER',6,1,NULL,'0',NULL,CASE WHEN @OPEN_GESTION_RESULTADO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (4,'TEXTO04','Estado','TEXT',6,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_GESTION_RESULTADO=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_GESTION_RESULTADO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'GESTION_RESULTADO',0,1,NULL,'entity'),
    (7,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'gestiones-resultados',0,1,NULL,'active-tab'),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigGestionResultadoModal',@TITLE='Resultado de gestión',@SUBTITLE='Administración de resultados de gestión.',@ICON='file-text',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_GESTION_RESULTADO,@OPEN_ON_RENDER=@OPEN_GESTION_RESULTADO,@OUTHTML=@HTML_MODAL_GESTION_RESULTADO OUTPUT;
    SET @HTML_MODAL_GESTION_RESULTADO=ISNULL(@HTML_MODAL_GESTION_RESULTADO,'')+'<template data-vct-field-options data-vct-target="vctConfigGestionResultadoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,50,'Código',NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,150,'Descripción',NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO05','Tipo','TEXT',6,1,NULL,'Seleccione tipo',NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VTEXTO05 ELSE NULL END,0,0,NULL,'idtipo'),
    (4,'TEXTO03','Orden','NUMBER',3,1,NULL,'0',NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (5,'TEXTO04','Estado','TEXT',3,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (6,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_GESTION_SUBTIPO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (7,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'GESTION_SUBTIPO',0,1,NULL,'entity'),
    (8,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'gestiones-subtipos',0,1,NULL,'active-tab'),
    (9,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (10,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigGestionSubtipoModal',@TITLE='Subtipo de gestión',@SUBTITLE='Administración de subtipos de gestión.',@ICON='settings',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_GESTION_SUBTIPO,@OPEN_ON_RENDER=@OPEN_GESTION_SUBTIPO,@OUTHTML=@HTML_MODAL_GESTION_SUBTIPO OUTPUT;
    SET @HTML_MODAL_GESTION_SUBTIPO=ISNULL(@HTML_MODAL_GESTION_SUBTIPO,'')+
        '<template data-vct-field-options data-vct-target="vctConfigGestionSubtipoModal" data-vct-field="TEXTO05" data-vct-placeholder="Seleccione tipo">'+ISNULL(@HTML_OPTIONS_GESTION_TIPO,'')+'</template>'+
        '<template data-vct-field-options data-vct-target="vctConfigGestionSubtipoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,30,'Código',NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,100,'Descripción',NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO05','Es estado final','TEXT',4,1,NULL,'Seleccione',NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VTEXTO05 ELSE '0' END,0,0,'Marca si esta gestión se considera cerrada al llegar a este estado.','esfinal'),
    (4,'TEXTO03','Orden','NUMBER',4,1,NULL,'0',NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (5,'TEXTO04','Estado','TEXT',4,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (6,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_GESTION_ESTADO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (7,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'GESTION_ESTADO',0,1,NULL,'entity'),
    (8,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'gestiones-estados',0,1,NULL,'active-tab'),
    (9,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (10,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigGestionEstadoModal',@TITLE='Estado de gestión',@SUBTITLE='Administración de estados de gestión.',@ICON='settings',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_GESTION_ESTADO,@OPEN_ON_RENDER=@OPEN_GESTION_ESTADO,@OUTHTML=@HTML_MODAL_GESTION_ESTADO OUTPUT;
    SET @HTML_MODAL_GESTION_ESTADO=ISNULL(@HTML_MODAL_GESTION_ESTADO,'')+
        '<template data-vct-field-options data-vct-target="vctConfigGestionEstadoModal" data-vct-field="TEXTO05" data-vct-placeholder="Seleccione"><option value="1">Sí</option><option value="0">No</option></template>'+
        '<template data-vct-field-options data-vct-target="vctConfigGestionEstadoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,30,'Código',NULL,CASE WHEN @OPEN_GESTION_PRIORIDAD=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,100,'Descripción',NULL,CASE WHEN @OPEN_GESTION_PRIORIDAD=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO03','Nivel','NUMBER',6,1,NULL,'0',NULL,CASE WHEN @OPEN_GESTION_PRIORIDAD=1 THEN @VTEXTO03 ELSE '0' END,0,0,'Nivel numérico de la prioridad (mayor = más urgente).','nivel'),
    (4,'TEXTO04','Estado','TEXT',6,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_GESTION_PRIORIDAD=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_GESTION_PRIORIDAD=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'GESTION_PRIORIDAD',0,1,NULL,'entity'),
    (7,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'gestiones-prioridades',0,1,NULL,'active-tab'),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigGestionPrioridadModal',@TITLE='Prioridad de gestión',@SUBTITLE='Administración de prioridades de gestión.',@ICON='settings',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_GESTION_PRIORIDAD,@OPEN_ON_RENDER=@OPEN_GESTION_PRIORIDAD,@OUTHTML=@HTML_MODAL_GESTION_PRIORIDAD OUTPUT;
    SET @HTML_MODAL_GESTION_PRIORIDAD=ISNULL(@HTML_MODAL_GESTION_PRIORIDAD,'')+'<template data-vct-field-options data-vct-target="vctConfigGestionPrioridadModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    /* ============================================================
       12c. FORMS PROYECTOS y VIATICOS
       ============================================================ */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,30,'Código',NULL,CASE WHEN @OPEN_PROYECTO_ESTADO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,100,'Descripción',NULL,CASE WHEN @OPEN_PROYECTO_ESTADO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO03','Orden','NUMBER',6,1,NULL,'0',NULL,CASE WHEN @OPEN_PROYECTO_ESTADO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (4,'TEXTO04','Estado','TEXT',6,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_PROYECTO_ESTADO=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_PROYECTO_ESTADO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'PROYECTO_ESTADO',0,1,NULL,'entity'),
    (7,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'proyectos-estados',0,1,NULL,'active-tab'),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigProyectoEstadoModal',@TITLE='Estado de proyecto',@SUBTITLE='Administración de estados de proyecto.',@ICON='settings',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_PROYECTO_ESTADO,@OPEN_ON_RENDER=@OPEN_PROYECTO_ESTADO,@OUTHTML=@HTML_MODAL_PROYECTO_ESTADO OUTPUT;
    SET @HTML_MODAL_PROYECTO_ESTADO=ISNULL(@HTML_MODAL_PROYECTO_ESTADO,'')+'<template data-vct-field-options data-vct-target="vctConfigProyectoEstadoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,50,'Código',NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,100,'Descripción',NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO05','Tipo de miembro','TEXT',6,0,20,'Ej. CONSULTOR',NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VTEXTO05 ELSE NULL END,0,0,'Opcional: clasificación libre del rol.','tipomiembro'),
    (4,'TEXTO03','Orden','NUMBER',3,1,NULL,'0',NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (5,'TEXTO04','Estado','TEXT',3,1,NULL,'Seleccione estado',NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VTEXTO04 ELSE '1' END,0,0,NULL,'activo'),
    (6,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_PROYECTO_ROL=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (7,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'PROYECTO_ROL',0,1,NULL,'entity'),
    (8,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'proyectos-roles',0,1,NULL,'active-tab'),
    (9,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (10,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigProyectoRolModal',@TITLE='Rol de proyecto',@SUBTITLE='Administración de roles de proyecto.',@ICON='briefcase',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_PROYECTO_ROL,@OPEN_ON_RENDER=@OPEN_PROYECTO_ROL,@OUTHTML=@HTML_MODAL_PROYECTO_ROL OUTPUT;
    SET @HTML_MODAL_PROYECTO_ROL=ISNULL(@HTML_MODAL_PROYECTO_ROL,'')+'<template data-vct-field-options data-vct-target="vctConfigProyectoRolModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="1">Activo</option><option value="0">Inactivo</option></template>';

    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO01','Código','TEXT',4,1,30,'Código',NULL,CASE WHEN @OPEN_VIATICO_TIPO=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'codigo'),
    (2,'TEXTO02','Descripción','TEXT',8,1,100,'Descripción',NULL,CASE WHEN @OPEN_VIATICO_TIPO=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'descripcion'),
    (3,'TEXTO03','Orden','NUMBER',6,1,NULL,'0',NULL,CASE WHEN @OPEN_VIATICO_TIPO=1 THEN @VTEXTO03 ELSE '0' END,0,0,NULL,'orden'),
    (4,'TEXTO04','Estado','TEXT',6,1,20,'Seleccione estado',NULL,CASE WHEN @OPEN_VIATICO_TIPO=1 THEN @VTEXTO04 ELSE 'ACTIVO' END,0,0,NULL,'estado'),
    (5,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @OPEN_VIATICO_TIPO=1 THEN @VID_ROW ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'VIATICO_TIPO',0,1,NULL,'entity'),
    (7,'ACTIVE_TAB','Solapa','HIDDEN',12,0,NULL,NULL,NULL,'viaticos-tipos',0,1,NULL,'active-tab'),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);
    EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctConfigViaticoTipoModal',@TITLE='Tipo de viático',@SUBTITLE='Administración de tipos de viático.',@ICON='briefcase',@LAYOUT='MODAL',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',@ERROR_MESSAGE=@FORM_ERR_VIATICO_TIPO,@OPEN_ON_RENDER=@OPEN_VIATICO_TIPO,@OUTHTML=@HTML_MODAL_VIATICO_TIPO OUTPUT;
    SET @HTML_MODAL_VIATICO_TIPO=ISNULL(@HTML_MODAL_VIATICO_TIPO,'')+'<template data-vct-field-options data-vct-target="vctConfigViaticoTipoModal" data-vct-field="TEXTO04" data-vct-placeholder="Seleccione estado"><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></template>';

    /* ============================================================
       13-14. DOM PRINCIPAL
       ============================================================ */
    SET @HTML='
<div class="vct-page vct-page-main vct-config-page"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">

    '+ISNULL(@HTML_FEEDBACK,'')+'

    <section class="vct-card vct-config-workspace">
        <div data-vct-param-root data-vct-param-active="'+ISNULL(@ACTIVE_TAB,'gestiones-tipos')+'">

            <nav class="vct-param-topnav">
                <div class="vct-param-topnav-item">
                    <button type="button" data-vct-param-cat="gestiones" aria-expanded="false"><span data-vct-icon="settings"></span> Gestiones<span class="vct-param-chevron" data-vct-icon="chevrons-up-down"></span></button>
                    <div class="vct-param-dropdown" data-vct-param-cat-panel="gestiones">
                        <button type="button" data-vct-param-group="gestiones-tipos"><span data-vct-icon="list-checks"></span> Tipos</button>
                        <button type="button" data-vct-param-group="gestiones-subtipos"><span data-vct-icon="folder"></span> Subtipos</button>
                        <button type="button" data-vct-param-group="gestiones-resultados"><span data-vct-icon="clipboard-check"></span> Resultados</button>
                        <button type="button" data-vct-param-group="gestiones-estados"><span data-vct-icon="settings"></span> Estados</button>
                        <button type="button" data-vct-param-group="gestiones-prioridades"><span data-vct-icon="star"></span> Prioridades</button>
                    </div>
                </div>
                <button type="button" data-vct-param-cat="normas" data-vct-param-group="normas"><span data-vct-icon="file-text"></span> Normas</button>
                <div class="vct-param-topnav-item">
                    <button type="button" data-vct-param-cat="proyectos" aria-expanded="false"><span data-vct-icon="briefcase"></span> Proyectos<span class="vct-param-chevron" data-vct-icon="chevrons-up-down"></span></button>
                    <div class="vct-param-dropdown" data-vct-param-cat-panel="proyectos">
                        <button type="button" data-vct-param-group="proyectos-estados"><span data-vct-icon="settings"></span> Estados</button>
                        <button type="button" data-vct-param-group="proyectos-roles"><span data-vct-icon="users"></span> Roles</button>
                    </div>
                </div>
                <button type="button" data-vct-param-cat="viaticos" data-vct-param-group="viaticos-tipos"><span data-vct-icon="map-pin"></span> Viáticos</button>
                <button type="button" data-vct-param-cat="email-templates" data-vct-param-group="email-templates"><span data-vct-icon="mail"></span> Email</button>
            </nav>
            <div class="vct-param-breadcrumb" data-vct-param-breadcrumb></div>

                <div data-vct-param-group-panel="gestiones-tipos" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="settings"></span> Tipos de gestión</h2>
                            <p class="vct-card-subtitle">Administración de tipos de gestión.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="settings"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Tipos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_TIPOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_TIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_TIPOS-@CNT_GESTION_TIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-gestiones-tipos">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Tipos de gestión</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-gestiones-tipos"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart">
                                    <div class="vct-report-chart-title">Tipos por estado</div>
                                    '+@HTML_GESTION_TIPO_DONUT+'
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-gestion-tipos"
                         data-vct-dg-title="Tipos de gestión"
                         data-vct-dg-subtitle="Administración de tipos de gestión."
                         data-vct-dg-unit="tipo(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar tipo, código o descripción..."
                         data-vct-dg-charts="charts-gestiones-tipos"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_GESTION_TIPO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_GESTION_TIPO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="gestiones-subtipos" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="settings"></span> Subtipos de gestión</h2>
                            <p class="vct-card-subtitle">Administración de subtipos de gestión.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="settings"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Subtipos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS-@CNT_GESTION_SUBTIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-purple">
                            <span class="vct-soft-kpi-icon" data-vct-icon="list-checks"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Tipos con subtipos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_SUBTIPOS_TIPOSCONSUB)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-gestiones-subtipos">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Subtipos de gestión</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-gestiones-subtipos"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart-grid">
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Subtipos por estado</div>
                                        '+@HTML_GESTION_SUBTIPO_DONUT+'
                                    </div>
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Top 5 Tipos por cantidad de subtipos</div>
                                        <div class="vct-barchart">'+@HTML_GESTION_SUBTIPO_BARS+'</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-gestion-subtipos"
                         data-vct-dg-title="Subtipos de gestión"
                         data-vct-dg-subtitle="Administración de subtipos de gestión."
                         data-vct-dg-unit="subtipo(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar subtipo, código o descripción..."
                         data-vct-dg-charts="charts-gestiones-subtipos"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_GESTION_SUBTIPO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-width="22%"><span>Tipo</span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_GESTION_SUBTIPO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="gestiones-resultados" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="file-text"></span> Resultados de gestión</h2>
                            <p class="vct-card-subtitle">Administración de resultados de gestión.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="file-text"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Resultados</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_RESULTADOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_RESULTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_RESULTADOS-@CNT_GESTION_RESULTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-gestiones-resultados">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Resultados de gestión</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-gestiones-resultados"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart">
                                    <div class="vct-report-chart-title">Resultados por estado</div>
                                    '+@HTML_GESTION_RESULTADO_DONUT+'
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-gestion-resultados"
                         data-vct-dg-title="Resultados de gestión"
                         data-vct-dg-subtitle="Administración de resultados de gestión."
                         data-vct-dg-unit="resultado(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar resultado, código o descripción..."
                         data-vct-dg-charts="charts-gestiones-resultados"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_GESTION_RESULTADO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_GESTION_RESULTADO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="gestiones-estados" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="settings"></span> Estados de gestión</h2>
                            <p class="vct-card-subtitle">Administración de estados de gestión.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="settings"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Estados</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS-@CNT_GESTION_ESTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-purple">
                            <span class="vct-soft-kpi-icon" data-vct-icon="star"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Finales</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_ESTADOS_FINALES)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-gestiones-estados">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Estados de gestión</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-gestiones-estados"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart-grid">
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Estados por Activo/Inactivo</div>
                                        '+@HTML_GESTION_ESTADO_DONUT_ACT+'
                                    </div>
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Estados Finales/No finales</div>
                                        '+@HTML_GESTION_ESTADO_DONUT_FIN+'
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-gestion-estados"
                         data-vct-dg-title="Estados de gestión"
                         data-vct-dg-subtitle="Administración de estados de gestión."
                         data-vct-dg-unit="estado(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar estado, código o descripción..."
                         data-vct-dg-charts="charts-gestiones-estados"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_GESTION_ESTADO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-width="9%"><span>Final</span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_GESTION_ESTADO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="gestiones-prioridades" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="settings"></span> Prioridades de gestión</h2>
                            <p class="vct-card-subtitle">Administración de prioridades de gestión.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="settings"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Prioridades</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activas</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES_ACTIVAS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivas</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES-@CNT_GESTION_PRIORIDADES_ACTIVAS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-purple">
                            <span class="vct-soft-kpi-icon" data-vct-icon="chart-no-axes-column-increasing"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Nivel máx.</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_GESTION_PRIORIDADES_NIVELMAX)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-gestiones-prioridades">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Prioridades de gestión</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-gestiones-prioridades"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart-grid">
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Prioridades por estado</div>
                                        '+@HTML_GESTION_PRIORIDAD_DONUT+'
                                    </div>
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Top 5 por Nivel</div>
                                        <div class="vct-barchart">'+@HTML_GESTION_PRIORIDAD_BARS+'</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-gestion-prioridades"
                         data-vct-dg-title="Prioridades de gestión"
                         data-vct-dg-subtitle="Administración de prioridades de gestión."
                         data-vct-dg-unit="prioridad(es)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar prioridad, código o descripción..."
                         data-vct-dg-charts="charts-gestiones-prioridades"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_GESTION_PRIORIDAD_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="nivel" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Nivel</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_GESTION_PRIORIDAD_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="normas" class="vct-config-panel">

                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="file-text"></span> Normas</h2>
                            <p class="vct-card-subtitle">Administración de normas del sistema.</p>
                        </div>
                    </div>

                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="file-text"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Normas</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_NORMAS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activas</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_NORMAS_ACTIVAS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivas</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_NORMAS-@CNT_NORMAS_ACTIVAS)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-normas">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Normas</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-normas"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart">
                                    <div class="vct-report-chart-title">Normas por estado</div>
                                    '+@HTML_NORMAS_DONUT+'
                                </div>
                            </div>
                        </div>
                    </div>

                    <div data-vct-dg
                         data-vct-dg-id="config-normas"
                         data-vct-dg-title="Normas"
                         data-vct-dg-subtitle="Administración de normas del sistema."
                         data-vct-dg-unit="norma(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar norma..."
                         data-vct-dg-charts="charts-normas"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option>
                                <option value="ACTIVO">Activo</option>
                                <option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_NORMA_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="norma" data-vct-sortable="true"><span>Norma</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_NORMAS_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="proyectos-estados" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="settings"></span> Estados de proyecto</h2>
                            <p class="vct-card-subtitle">Administración de estados de proyecto.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="settings"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Estados</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ESTADOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ESTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ESTADOS-@CNT_PROYECTO_ESTADOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-proyectos-estados">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Estados de proyecto</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-proyectos-estados"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart">
                                    <div class="vct-report-chart-title">Estados por Activo/Inactivo</div>
                                    '+@HTML_PROYECTO_ESTADO_DONUT+'
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-proyecto-estados"
                         data-vct-dg-title="Estados de proyecto"
                         data-vct-dg-subtitle="Administración de estados de proyecto."
                         data-vct-dg-unit="estado(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar estado, código o descripción..."
                         data-vct-dg-charts="charts-proyectos-estados"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_PROYECTO_ESTADO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_PROYECTO_ESTADO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="proyectos-roles" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="briefcase"></span> Roles de proyecto</h2>
                            <p class="vct-card-subtitle">Administración de roles de proyecto.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="briefcase"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Roles</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES-@CNT_PROYECTO_ROLES_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-purple">
                            <span class="vct-soft-kpi-icon" data-vct-icon="users"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Con tipo de miembro</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_PROYECTO_ROLES_CONTIPO)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-proyectos-roles">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Roles de proyecto</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-proyectos-roles"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart-grid">
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Roles por estado</div>
                                        '+@HTML_PROYECTO_ROL_DONUT+'
                                    </div>
                                    <div class="vct-report-chart">
                                        <div class="vct-report-chart-title">Top 5 por Tipo de miembro</div>
                                        <div class="vct-barchart">'+@HTML_PROYECTO_ROL_BARS+'</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-proyecto-roles"
                         data-vct-dg-title="Roles de proyecto"
                         data-vct-dg-subtitle="Administración de roles de proyecto."
                         data-vct-dg-unit="rol(es)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar rol, código o descripción..."
                         data-vct-dg-charts="charts-proyectos-roles"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_PROYECTO_ROL_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-width="18%"><span>Tipo de miembro</span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_PROYECTO_ROL_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

                <div data-vct-param-group-panel="viaticos-tipos" class="vct-config-panel">
                    <div class="vct-card-header vct-config-abm-header">
                        <div>
                            <h2 class="vct-card-title"><span data-vct-icon="briefcase"></span> Tipos de viático</h2>
                            <p class="vct-card-subtitle">Administración de tipos de viático.</p>
                        </div>
                    </div>
                    <div class="vct-reports-kpis">
                        <div class="vct-soft-kpi is-blue">
                            <span class="vct-soft-kpi-icon" data-vct-icon="briefcase"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Total Tipos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_VIATICO_TIPOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-green">
                            <span class="vct-soft-kpi-icon" data-vct-icon="check"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Activos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_VIATICO_TIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                        <div class="vct-soft-kpi is-orange">
                            <span class="vct-soft-kpi-icon" data-vct-icon="x"></span>
                            <div class="vct-soft-kpi-copy">
                                <span class="vct-soft-kpi-label">Inactivos</span>
                                <span class="vct-soft-kpi-value">'+CONVERT(VARCHAR(20),@CNT_VIATICO_TIPOS-@CNT_VIATICO_TIPOS_ACTIVOS)+'</span>
                            </div>
                        </div>
                    </div>
                    <div class="vct-modal vct-modal-charts" data-vct-component="modal" data-vct-id="charts-viaticos-tipos">
                        <div class="vct-modal-dialog">
                            <div class="vct-modal-header">
                                <h3 class="vct-modal-title">Gráficos — Tipos de viático</h3>
                                <button type="button" class="vct-btn vct-btn-sm vct-btn-icon" data-vct-command="close-modal" data-vct-target="charts-viaticos-tipos"><span data-vct-icon="x"></span></button>
                            </div>
                            <div class="vct-modal-body">
                                <div class="vct-report-chart">
                                    <div class="vct-report-chart-title">Tipos por estado</div>
                                    '+@HTML_VIATICO_TIPO_DONUT+'
                                </div>
                            </div>
                        </div>
                    </div>
                    <div data-vct-dg
                         data-vct-dg-id="config-viatico-tipos"
                         data-vct-dg-title="Tipos de viático"
                         data-vct-dg-subtitle="Administración de tipos de viático."
                         data-vct-dg-unit="tipo(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar tipo, código o descripción..."
                         data-vct-dg-charts="charts-viaticos-tipos"
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+ISNULL(@HTML_VIATICO_TIPO_CREATE,'')+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="codigo" data-vct-sortable="true" data-vct-width="18%"><span>Código</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="descripcion" data-vct-sortable="true"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="orden" data-vct-sort-type="number" data-vct-sortable="true" data-vct-width="9%"><span>Orden</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="12%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_VIATICO_TIPO_ROWS,'')+'</tbody>
                        </table>
                    </div>
                </div>

        <div data-vct-param-group-panel="email-templates"
             class="vct-config-panel">

            <div data-vct-email-list-view class="vct-email-list-view '+CASE WHEN @OPEN_TEMPLATE=1 THEN '' ELSE 'is-active' END+'">

                <div class="vct-card-header vct-config-abm-header">
                    <div>
                        <h2 class="vct-card-title"><span data-vct-icon="mail"></span> Templates de emails</h2>
                        <p class="vct-card-subtitle">Parametrización de contenido, destinatarios y modalidad de envío.</p>
                    </div>
                </div>

                <div data-vct-dg
                         data-vct-dg-id="config-email-templates"
                         data-vct-dg-title="Templates de emails"
                         data-vct-dg-subtitle="Administración de plantillas de emails del sistema."
                         data-vct-dg-unit="template(s)"
                         data-vct-dg-page-size="10"
                         data-vct-dg-search-placeholder="Buscar template, código, asunto o destino..."
                         data-vct-dg-density="compact"
                         data-vct-dg-layout="fixed">

                        <div data-vct-dg-slot="filters">
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="tipo" aria-label="Todos los tipos"><option value="">Todos los tipos</option>
                            <option value="MANUAL">Manual</option>
                            <option value="AUTOMATICO">Automático</option></select>
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="destino" aria-label="Todos los destinos"><option value="">Todos los destinos</option>
                            <option value="ANALISTA">Analista</option>
                            <option value="GERENCIA">Gerencia</option>
                            <option value="CONSULTOR">Consultor</option>
                            <option value="CLIENTE">Cliente</option>
                            <option value="LIBRE">Libre</option></select>
                            <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Todos los estados"><option value="">Todos los estados</option>
                            <option value="ACTIVO">Activo</option>
                            <option value="INACTIVO">Inactivo</option></select>
                        </div>

                        <div data-vct-dg-slot="actions">'+CASE WHEN @CAN_CREATE=1 THEN
                                '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-email-new>'+
                                '<span data-vct-icon="user-plus"></span><span>Nuevo</span></button>'
                              ELSE '' END+'</div>

                        <table>
                            <thead><tr>
                                <th data-vct-sort="descripcion" data-vct-sortable="true" data-vct-truncate="2"><span>Descripción</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="asunto" data-vct-sortable="true" data-vct-width="26%" data-vct-truncate="2"><span>Asunto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="destino" data-vct-sortable="true" data-vct-width="14%" data-vct-truncate="2"><span>Destino</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th data-vct-sort="cc" data-vct-sortable="true" data-vct-width="10%" data-vct-truncate="2"><span>CC</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="tipo" data-vct-sortable="true" data-vct-width="11%"><span>Tipo envío</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-text-center" data-vct-sort="estado" data-vct-sortable="true" data-vct-width="9%"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th>
                                <th class="vct-col-action" data-vct-width="88" data-vct-export-ignore="true"></th>
                            </tr></thead>
                            <tbody>'+ISNULL(@HTML_TEMPLATE_ROWS,'')+'</tbody>
                        </table>
                    </div>
            </div>

            <div id="vctConfigEmailTemplateEditor"
                 class="vct-email-editor-view '+CASE WHEN @OPEN_TEMPLATE=1 THEN 'is-active' ELSE '' END+'"
                 data-vct-email-editor
                 data-vct-form-scope
                 data-vct-server-open="'+CASE WHEN @OPEN_TEMPLATE=1 THEN '1' ELSE '0' END+'">

                <div class="vct-email-editor-header">
                    <div class="vct-email-editor-heading">
                        <button type="button" class="vct-email-back-btn" data-vct-email-cancel data-vct-tooltip="Volver al listado">
                            <span data-vct-icon="arrow-left"></span>
                        </button>
                        <span class="vct-email-editor-icon"><span data-vct-icon="mail"></span></span>
                        <div class="vct-email-editor-titles">
                            <h2 data-vct-email-editor-title>'+CASE WHEN @OPEN_TEMPLATE=1 AND NULLIF(@VID_ROW,'') IS NOT NULL THEN 'Editar template de email' ELSE 'Nuevo template de email' END+'</h2>
                            <p>Defina destinatarios, asunto y diseño del mensaje.</p>
                        </div>
                    </div>
                    <div class="vct-email-editor-actions">
                        <button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-email-cancel>Cancelar</button>
                        <button type="button" class="vct-btn vct-btn-primary vct-btn-sm" data-vct-email-save>
                            <span data-vct-icon="save"></span><span>Guardar</span>
                        </button>
                    </div>
                </div>

                <div class="vct-validation-box" data-vct-validation-box style="'+CASE WHEN NULLIF(@FORM_ERR_TEMPLATE,'') IS NULL THEN 'display:none' ELSE 'display:block' END+'">'+
                    CASE WHEN NULLIF(@FORM_ERR_TEMPLATE,'') IS NULL THEN ''
                         ELSE '<div class="vct-validation-title">No se pudo guardar el template</div><ul><li>'+REPLACE(REPLACE(REPLACE(@FORM_ERR_TEMPLATE,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</li></ul>' END+
                '</div>

                <div class="vct-email-editor-body">
                    <div class="vct-email-editor-main">
                        <div class="vct-email-fields-row">
                            <section class="vct-email-editor-card vct-email-field-group vct-email-field-group-narrow">
                                <div class="vct-email-field-group-head">
                                    <svg viewBox="0 0 24 24" fill="none" width="14" height="14" aria-hidden="true"><rect x="4" y="4" width="16" height="16" rx="3" stroke="currentColor" stroke-width="1.8"/><path d="M8 9h8M8 13h5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                                    <span>Identificación</span>
                                </div>
                                <div class="vct-email-fields-grid">
                                    <div class="vct-field vct-email-col-12">
                                        <label class="vct-label">ID / Código técnico <span class="vct-required">*</span></label>
                                        <input type="text" class="vct-input" name="SP.TEXTO01" data-vct-field="TEXTO01" data-vct-label="Código técnico" data-vct-required="1" maxlength="50"
                                               value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO01,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') ELSE '' END+'"
                                               placeholder="Ej. TPL_001">
                                        <small class="vct-email-field-help">Identificador interno del template.</small>
                                    </div>
                                    <div class="vct-field vct-email-col-12">
                                        <label class="vct-label">Descripción <span class="vct-required">*</span></label>
                                        <input type="text" class="vct-input" name="SP.TEXTO02" data-vct-field="TEXTO02" data-vct-label="Descripción" data-vct-required="1" maxlength="200"
                                               value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO02,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') ELSE '' END+'"
                                               placeholder="Nombre descriptivo para identificar su uso">
                                        <small class="vct-email-field-help">Nombre descriptivo para identificar su uso.</small>
                                    </div>
                                </div>
                            </section>

                            <section class="vct-email-editor-card vct-email-field-group vct-email-field-group-wide">
                                <div class="vct-email-field-group-head">
                                    <svg viewBox="0 0 24 24" fill="none" width="14" height="14" aria-hidden="true"><path d="M4 4l16 8-16 8V4Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/></svg>
                                    <span>Envío y destino</span>
                                </div>
                                <div class="vct-email-fields-grid">
                                    <div class="vct-field vct-email-col-3">
                                        <label class="vct-label">Tipo de envío <span class="vct-required">*</span></label>
                                        <select class="vct-select" name="SP.TEXTO03" data-vct-field="TEXTO03" data-vct-label="Tipo de envío" data-vct-required="1">
                                            <option value="MANUAL" '+CASE WHEN @OPEN_TEMPLATE=0 OR @VTEXTO03='MANUAL' THEN 'selected' ELSE '' END+'>Manual</option>
                                            <option value="AUTOMATICO" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO03='AUTOMATICO' THEN 'selected' ELSE '' END+'>Automático</option>
                                        </select>
                                        <small class="vct-email-field-help">Define cuándo se envía este email.</small>
                                    </div>
                                    <div class="vct-field vct-email-col-3">
                                        <label class="vct-label">Destino <span class="vct-required">*</span></label>
                                        <select class="vct-select" name="SP.TEXTO04" data-vct-field="TEXTO04" data-vct-label="Destino" data-vct-required="1">
                                            <option value="ANALISTA" '+CASE WHEN @OPEN_TEMPLATE=0 OR @VTEXTO04='ANALISTA' THEN 'selected' ELSE '' END+'>Analista</option>
                                            <option value="GERENCIA" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO04='GERENCIA' THEN 'selected' ELSE '' END+'>Gerencia</option>
                                            <option value="CONSULTOR" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO04='CONSULTOR' THEN 'selected' ELSE '' END+'>Consultor</option>
                                            <option value="CLIENTE" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO04='CLIENTE' THEN 'selected' ELSE '' END+'>Cliente</option>
                                            <option value="LIBRE" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO04='LIBRE' THEN 'selected' ELSE '' END+'>Libre</option>
                                        </select>
                                        <small class="vct-email-field-help">Destinatario principal del email.</small>
                                    </div>
                                    <div class="vct-field vct-email-col-3">
                                        <label class="vct-label">CC</label>
                                        <select class="vct-select" name="SP.TEXTO06" data-vct-field="TEXTO06" data-vct-label="CC">
                                            <option value="NINGUNO" '+CASE WHEN @OPEN_TEMPLATE=0 OR @VTEXTO06='NINGUNO' THEN 'selected' ELSE '' END+'>Sin copia</option>
                                            <option value="ANALISTA" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO06='ANALISTA' THEN 'selected' ELSE '' END+'>Analista</option>
                                            <option value="GERENCIA" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO06='GERENCIA' THEN 'selected' ELSE '' END+'>Gerencia</option>
                                            <option value="CONSULTOR" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO06='CONSULTOR' THEN 'selected' ELSE '' END+'>Consultor</option>
                                            <option value="CLIENTE" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO06='CLIENTE' THEN 'selected' ELSE '' END+'>Cliente</option>
                                            <option value="LIBRE" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO06='LIBRE' THEN 'selected' ELSE '' END+'>Libre</option>
                                        </select>
                                        <small class="vct-email-field-help">Copias opcionales.</small>
                                    </div>
                                    <div class="vct-field vct-email-col-3">
                                        <label class="vct-label">Estado <span class="vct-required">*</span></label>
                                        <select class="vct-select" name="SP.TEXTO08" data-vct-field="TEXTO08" data-vct-label="Estado" data-vct-required="1">
                                            <option value="ACTIVO" '+CASE WHEN @OPEN_TEMPLATE=0 OR @VTEXTO08='ACTIVO' THEN 'selected' ELSE '' END+'>Activo</option>
                                            <option value="INACTIVO" '+CASE WHEN @OPEN_TEMPLATE=1 AND @VTEXTO08='INACTIVO' THEN 'selected' ELSE '' END+'>Inactivo</option>
                                        </select>
                                        <small class="vct-email-field-help">Indica si el template está habilitado.</small>
                                    </div>
                                    <div class="vct-field vct-email-col-12" data-vct-email-destino-libre-wrap>
                                        <label class="vct-label">Email destino libre</label>
                                        <input type="text" class="vct-input" name="SP.TEXTO05" data-vct-field="TEXTO05" data-vct-label="Email destino libre"
                                               value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO05,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') ELSE '' END+'"
                                               placeholder="nombre1@dominio.com; nombre2@dominio.com">
                                        <small class="vct-email-field-help">Si carga varios destinatarios, deben ir separados por punto y coma (;).</small>
                                    </div>
                                    <div class="vct-field vct-email-col-12" data-vct-email-cc-libre-wrap>
                                        <label class="vct-label">Email CC libre</label>
                                        <input type="text" class="vct-input" name="SP.TEXTO07" data-vct-field="TEXTO07" data-vct-label="Email CC libre"
                                               value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO07,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') ELSE '' END+'"
                                               placeholder="nombre1@dominio.com; nombre2@dominio.com">
                                        <small class="vct-email-field-help">Si carga varios destinatarios, deben ir separados por punto y coma (;).</small>
                                    </div>
                                    <div class="vct-field vct-email-col-12">
                                        <label class="vct-label">Asunto <span class="vct-required">*</span></label>
                                        <input type="text" class="vct-input" name="SP.TEXTO09" data-vct-field="TEXTO09" data-vct-label="Asunto" data-vct-required="1" maxlength="500"
                                               value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO09,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') ELSE '' END+'"
                                               placeholder="Asunto del correo">
                                        <small class="vct-email-field-help">Podés usar las variables.</small>
                                    </div>
                                </div>
                            </section>
                        </div>

                        <section class="vct-email-body-card">
                            <div class="vct-email-body-header">
                                <strong>Cuerpo del mail <span class="vct-required">*</span></strong>
                                <div class="vct-email-device-toggle">
                                    <button type="button" class="vct-email-device-btn is-active" data-vct-email-device="desktop">
                                        <svg viewBox="0 0 24 24" fill="none" width="12" height="12" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="1.6" stroke="currentColor" stroke-width="1.7"/><path d="M8 20h8M12 16v4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
                                        Escritorio
                                    </button>
                                    <button type="button" class="vct-email-device-btn" data-vct-email-device="mobile">
                                        <svg viewBox="0 0 24 24" fill="none" width="12" height="12" aria-hidden="true"><rect x="7" y="2" width="10" height="20" rx="2" stroke="currentColor" stroke-width="1.7"/><path d="M11 19h2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
                                        Móvil
                                    </button>
                                </div>
                            </div>

                            <div class="vct-email-rich-toolbar">
                                <select class="vct-email-rich-select" data-vct-email-rich-block title="Estilo de párrafo">
                                    <option value="<p>">Párrafo</option>
                                    <option value="<h1>">Título 1</option>
                                    <option value="<h2>">Título 2</option>
                                    <option value="<h3>">Título 3</option>
                                    <option value="<blockquote>">Cita</option>
                                </select>
                                <div class="vct-email-rich-group">
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="bold" title="Negrita"><strong>B</strong></button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="italic" title="Cursiva"><em>I</em></button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="underline" title="Subrayado"><u>U</u></button>
                                    <input type="color" class="vct-email-rich-color" data-vct-email-rich-color value="#263247" title="Color de texto">
                                </div>
                                <div class="vct-email-rich-group">
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="justifyLeft" title="Alinear izquierda (texto, o la imagen si está seleccionada)">Izq</button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="justifyCenter" title="Centrar (texto, o la imagen si está seleccionada)">Centro</button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="justifyRight" title="Alinear derecha (texto, o la imagen si está seleccionada)">Der</button>
                                </div>
                                <div class="vct-email-rich-group">
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="createLink" title="Insertar vínculo">Link</button>
                                    <select class="vct-email-rich-select" data-vct-email-banner-select title="Insertar banner del servidor">
                                        <option value="">Insertar banner&#8230;</option>
                                        <option value="../img/vct-mail-banner-Bordeaux.png">Banner bordo</option>
                                        <option value="../img/vct-mail-banner-Blanco.png">Banner blanco</option>
                                        <option value="../img/vct-mail-banner-Gris.png">Banner gris</option>
                                    </select>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-remove-image title="Quitar imagen seleccionada"><svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" aria-hidden="true"><path d="M4 7h16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="insertTable" title="Insertar tabla">Tabla</button>
                                </div>
                                <div class="vct-email-rich-group" style="margin-left:auto;">
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="undo" title="Deshacer"><svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" aria-hidden="true"><path d="M9 7L4 12l5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 12h11a5 5 0 0 1 0 10h-1" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
                                    <button type="button" class="vct-email-rich-btn" data-vct-email-rich="redo" title="Rehacer"><svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" aria-hidden="true"><path d="M15 7l5 5-5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M20 12H9a5 5 0 0 0 0 10h1" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
                                </div>
                            </div>

                            <div class="vct-email-body-split">
                                <div class="vct-email-rich-editor" contenteditable="true" data-vct-email-rich-editor></div>
                                <div class="vct-email-live-preview" data-vct-email-live-preview>
                                    <span class="vct-email-live-preview-label">Vista previa en vivo</span>
                                    <div class="vct-email-live-preview-frame-wrap">
                                        <iframe class="vct-email-preview-frame" data-vct-email-preview title="Vista previa del email"></iframe>
                                    </div>
                                </div>
                            </div>

                            <div class="vct-email-body-footer">
                                <span class="vct-email-word-count" data-vct-email-word-count>0 palabras</span>
                            </div>
                        </section>
                    </div>

                    <aside class="vct-email-variables-panel">
                        <div class="vct-email-variables-head">
                            <strong>Variables disponibles</strong>
                        </div>
                        <p class="vct-email-variables-hint">Insertá estas variables en el asunto o cuerpo del mail.</p>
                        <div class="vct-email-variables-search-wrap">
                            <svg class="vct-email-variables-search-icon" viewBox="0 0 24 24" fill="none" width="13" height="13" aria-hidden="true"><circle cx="11" cy="11" r="6.5" stroke="currentColor" stroke-width="1.8"/><path d="m20 20-3.8-3.8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                            <input type="text" class="vct-email-variables-search" data-vct-email-variables-search placeholder="Buscar variable…" autocomplete="off">
                        </div>
                        <div class="vct-email-variables-alert">Las variables se reemplazarán automáticamente con la información correspondiente al momento del envío.</div>
                        <div class="vct-email-variables-list" data-vct-email-variables-list></div>
                        <div class="vct-email-variables-empty" data-vct-email-variables-empty style="display:none;">Sin coincidencias.</div>
                        <div class="vct-email-tip">
                            <div>
                                <strong>Consejo</strong>
                                <span>Hacé clic en una variable para insertarla donde tengas el cursor (asunto o cuerpo del mail).</span>
                            </div>
                        </div>
                    </aside>
                </div>

                <textarea name="SP.TEXTO10" data-vct-field="TEXTO10" data-vct-label="HTML del email" data-vct-required="1" hidden>'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO10,''),'&','&amp;'),'<','&lt;'),'>','&gt;') ELSE '' END+'</textarea>
                <textarea name="SP.TEXTO11" data-vct-field="TEXTO11" data-vct-label="Diseño del email" data-vct-required="1" hidden>'+CASE WHEN @OPEN_TEMPLATE=1 THEN REPLACE(REPLACE(REPLACE(ISNULL(@VTEXTO11,''),'&','&amp;'),'<','&lt;'),'>','&gt;') ELSE '' END+'</textarea>
                <input type="hidden" name="SP.IDSELEC01" data-vct-field="IDSELEC01" value="'+CASE WHEN @OPEN_TEMPLATE=1 THEN ISNULL(@VID_ROW,'') ELSE '' END+'">
                <input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value="EMAIL_TEMPLATE">
                <input type="hidden" name="SP.ACTIVE_TAB" data-vct-field="ACTIVE_TAB" value="email-templates">
                <input type="hidden" name="SP.FLAG03" data-vct-field="FLAG03" value="0">
                <input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="1">
            </div>
        </div>
        </div>
    </section>
</div>';

    SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+
        '<link rel="stylesheet" href="../css/vct-datagrid.css?v=4">'+
        '<link rel="stylesheet" href="../css/vct-email-template-designer.css?v=31">'+
        '<link rel="stylesheet" href="../css/vct-config-parametria.css?v=6">'+
        ISNULL(@HTML,'')+
        '<script src="../js/vct-export.js?v=1"></script>'+
        '<script src="../js/vct-datagrid.js?v=3"></script>'+
        '<script src="../js/vct-email-template-designer.js?v=29"></script>'+
        '<script src="../js/vct-config-parametria.js?v=2"></script>';
    SET @OUTPARAM2=ISNULL(@HTML_MODAL_NORMA,'')+
        ISNULL(@HTML_MODAL_GESTION_TIPO,'')+ISNULL(@HTML_MODAL_GESTION_SUBTIPO,'')+ISNULL(@HTML_MODAL_GESTION_RESULTADO,'')+
        ISNULL(@HTML_MODAL_GESTION_ESTADO,'')+ISNULL(@HTML_MODAL_GESTION_PRIORIDAD,'')+
        ISNULL(@HTML_MODAL_PROYECTO_ESTADO,'')+ISNULL(@HTML_MODAL_PROYECTO_ROL,'')+ISNULL(@HTML_MODAL_VIATICO_TIPO,'');
    SET @OUTPARAM3='';
END
GO
SET NOEXEC OFF
GO
