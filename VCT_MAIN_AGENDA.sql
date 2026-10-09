USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[VCT_MAIN_AGENDA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ========================================================================
   VCT_MAIN_AGENDA - V3 (CALENDARIO FULL-WIDTH + CARGA DESDE EL DIA)
   ------------------------------------------------------------------------
   V3 saca el panel lateral fijo de V2: el calendario ocupa todo el ancho
   (opcion "A" del mockup) y el alta/baja de feriados se dispara haciendo
   clic directo sobre un dia del calendario (opcion "D"), no desde una
   lista permanente al costado.

   Mecanismo de clic -> modal:
     - Se renderiza UNA sola fila-proxy oculta (data-vct-row, display:none)
       con el boton EDIT real generado por VCT_MAIN_RENDER_FORM_ACTION.
       Cuando el usuario hace clic en un dia CON feriado, vct-agenda.js
       actualiza los atributos data-vct-fecha/tipo/holidaytext de esa
       fila-proxy y dispara un click programatico sobre el boton --
       reutiliza el mismo mecanismo probado de Servicio/Norma (boton
       dentro de [data-vct-row], @SOURCE_SELECTOR='[data-vct-row]'),
       solo que la fila es unica y reciclada en vez de una por registro.
     - Para un dia SIN feriado, el JS dispara el boton "Nuevo feriado"
       (modo CREATE, sin prellenado por el framework) y completa a mano
       el input de fecha ya presente en el modal.

   Solo se leen/escriben las columnas IsHoliday, Feriado y HolidayText de
   dbo.Calendar -- nunca las columnas calculadas (DiaSemana, SemanaMes,
   etc.). A futuro la misma pantalla va a sumar la agenda de cada
   consultor (sidebar Id=9, Code='AGENDA_CONSULTOR', no se toca aca).

   Permisos requeridos (ver alta_agenda_view.sql / alta_agenda_edit.sql):
     dbo.PrmActions/Actions: AGENDA.VIEW (ya dado de alta)
     dbo.PrmActions/Actions: AGENDA.EDIT (ya dado de alta)
   ======================================================================== */
CREATE OR ALTER PROCEDURE [dbo].[VCT_MAIN_AGENDA]
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

    DECLARE @MODULE_CODE VARCHAR(50)='AGENDA';

    DECLARE
        @HTML_SHELL           VARCHAR(MAX)='',
        @HTML                 VARCHAR(MAX)='',
        @HTML_FEEDBACK        VARCHAR(MAX)='',
        @HTML_FERIADO_CREATE  VARCHAR(MAX)='',
        @HTML_FERIADO_DELETE  VARCHAR(MAX)='',
        @HTML_MODAL_CREATE    VARCHAR(MAX)='',
        @HTML_MODAL_DELETE    VARCHAR(MAX)='',

        @RESULTADO_SHELL      VARCHAR(20)='',
        @SIDEBAR_ID           INT=0,
        @CAN_EDIT             BIT=0,

        @HOLIDAYS_JSON        VARCHAR(MAX)='[]',

        @VFECHA_ROW           VARCHAR(100)='',
        @VFORM_ENTITY         VARCHAR(50)='',
        @VTEXTO01             VARCHAR(MAX)='',
        @VTEXTO02             VARCHAR(MAX)='',
        @VTEXTO03             VARCHAR(MAX)='',
        @VFLAG01              VARCHAR(10)='0',
        @VFLAG03              VARCHAR(10)='0',

        @VFORM_ERROR          VARCHAR(2000)='',
        @VFORM_REOPEN         BIT=0,
        @FORM_ERR_CREATE      VARCHAR(2000)='',
        @OPEN_CREATE          BIT=0,
        @FECHA_DATE           DATE=NULL,
        @RC                   INT=0;

    /* ============================================================
       1. SHELL
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Agenda General',
             @SUBTITLE           = 'Calendario de feriados y días no laborables.',
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
       2. PERMISOS
       ============================================================ */
    IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;

    SELECT *
    INTO #ACCIONES
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);

    SELECT TOP 1 @SIDEBAR_ID=ISNULL(SIDEBAR_ID,0)
    FROM #ACCIONES
    WHERE ISNULL(SIDEBAR_ID,0)<>0
    ORDER BY SORT_ORDER,ID_PRM;

    SET @CAN_EDIT=CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT') THEN 1 ELSE 0 END;

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
            <p class="vct-card-subtitle">No posee permisos para visualizar la Agenda.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* ============================================================
       3. VALIDACION DE TABLA
       ============================================================ */
    IF OBJECT_ID('dbo.Calendar','U') IS NULL
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Agenda incompleta</h2>
            <p class="vct-card-subtitle">No se encontró la tabla dbo.Calendar.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* ============================================================
       4. BUFFER / ESTADO DE OPERACION
       ------------------------------------------------------------
         TEXTO01 = FECHA (AAAA-MM-DD)
         TEXTO02 = TIPO (1=Fijo, 2=Movible)
         TEXTO03 = HOLIDAYTEXT (motivo)
         TEXTO30 = 'FERIADO'
         FLAG01  = guardar
         FLAG03  = eliminar (desmarcar la fecha, no borra la fila)
       ============================================================ */
    SELECT TOP 1
        @VTEXTO01     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO01),''),
        @VTEXTO02     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO02),''),
        @VTEXTO03     =ISNULL(CONVERT(VARCHAR(MAX),TEXTO03),''),
        @VFORM_ENTITY =UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),TEXTO30),'')))),
        @VFLAG01      =ISNULL(CONVERT(VARCHAR(10),FLAG01),'0'),
        @VFLAG03      =ISNULL(CONVERT(VARCHAR(10),FLAG03),'0')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;

    SET @VFLAG01=CASE WHEN @VFLAG01='1' THEN '1' ELSE '0' END;
    SET @VFLAG03=CASE WHEN @VFLAG03='1' THEN '1' ELSE '0' END;
    SET @VFECHA_ROW=LTRIM(RTRIM(ISNULL(@VTEXTO01,'')));

    /* ============================================================
       5. ELIMINAR (desmarcar fecha)
       ============================================================ */
    IF @VFLAG03='1' AND @VFORM_ENTITY='FERIADO'
    BEGIN
        SET @VFORM_ERROR='';
        SET @FECHA_DATE=NULL;

        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para editar la Agenda.';
        ELSE IF NULLIF(@VFECHA_ROW,'') IS NULL
            SET @VFORM_ERROR='No se recibió la fecha a eliminar.';
        ELSE IF ISDATE(@VFECHA_ROW)=0
            SET @VFORM_ERROR='La fecha a eliminar no es válida.';
        ELSE
            SET @FECHA_DATE=CONVERT(DATE,@VFECHA_ROW,120);

        IF @VFORM_ERROR=''
        BEGIN TRY
            UPDATE dbo.Calendar
               SET IsHoliday=0,
                   Feriado=0,
                   HolidayText=NULL
             WHERE Fecha=@FECHA_DATE;
            SET @RC=@@ROWCOUNT;

            IF @RC=0
                SET @VFORM_ERROR='La fecha indicada no existe en el calendario.';
        END TRY
        BEGIN CATCH
            SET @VFORM_ERROR=ERROR_MESSAGE();
        END CATCH;

        UPDATE dbo.VCT_BUFFER
           SET FLAG01=0,FLAG03=0,
               TEXTO01=NULL,TEXTO02=NULL,TEXTO03=NULL,TEXTO30=NULL
         WHERE PAR_KEY=@IPKEYJOB;
    END;

    /* ============================================================
       6. GUARDAR (alta o edicion de un feriado -- upsert por fecha)
       ============================================================ */
    IF @VFLAG01='1' AND @VFORM_ENTITY='FERIADO'
    BEGIN
        SET @VFORM_ERROR='';
        SET @VFORM_REOPEN=0;
        SET @FECHA_DATE=NULL;

        SET @VTEXTO02=UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO02,''))));
        SET @VTEXTO03=LTRIM(RTRIM(ISNULL(@VTEXTO03,'')));

        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para editar la Agenda.';
        ELSE IF NULLIF(@VFECHA_ROW,'') IS NULL
            SET @VFORM_ERROR='La fecha del feriado es obligatoria.';
        ELSE IF ISDATE(@VFECHA_ROW)=0
            SET @VFORM_ERROR='La fecha ingresada no es válida (usar formato AAAA-MM-DD).';
        ELSE
            SET @FECHA_DATE=CONVERT(DATE,@VFECHA_ROW,120);

        IF @VFORM_ERROR='' AND @VTEXTO02 NOT IN ('1','2')
            SET @VFORM_ERROR='El tipo de feriado seleccionado no es válido.';
        ELSE IF @VFORM_ERROR='' AND NULLIF(@VTEXTO03,'') IS NULL
            SET @VFORM_ERROR='El motivo del feriado es obligatorio.';
        ELSE IF @VFORM_ERROR='' AND LEN(@VTEXTO03)>200
            SET @VFORM_ERROR='El motivo no puede superar 200 caracteres.';

        IF @VFORM_ERROR='' AND NOT EXISTS(SELECT 1 FROM dbo.Calendar WITH(NOLOCK) WHERE Fecha=@FECHA_DATE)
            SET @VFORM_ERROR='La fecha indicada está fuera del calendario cargado.';

        IF @VFORM_ERROR=''
        BEGIN TRY
            UPDATE dbo.Calendar
               SET IsHoliday=1,
                   Feriado=CONVERT(INT,@VTEXTO02),
                   HolidayText=@VTEXTO03
             WHERE Fecha=@FECHA_DATE;
            SET @RC=@@ROWCOUNT;

            IF @RC=0
                SET @VFORM_ERROR='La fecha indicada no existe en el calendario.';
        END TRY
        BEGIN CATCH
            SET @VFORM_ERROR=ERROR_MESSAGE();
        END CATCH;

        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;

        IF @VFORM_ERROR=''
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET FLAG01=0,FLAG03=0,
                   TEXTO01=NULL,TEXTO02=NULL,TEXTO03=NULL,TEXTO30=NULL
             WHERE PAR_KEY=@IPKEYJOB;
        END
        ELSE
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET FLAG01=0,FLAG03=0
             WHERE PAR_KEY=@IPKEYJOB;
        END;
    END;

    IF @VFORM_ERROR<>'' AND @VFORM_REOPEN=0
    BEGIN
        SET @HTML_FEEDBACK=
            '<div class="vct-alert vct-alert-danger vct-config-feedback">'+
            REPLACE(REPLACE(REPLACE(ISNULL(@VFORM_ERROR,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</div>';
    END;

    SET @FORM_ERR_CREATE=CASE WHEN @VFORM_REOPEN=1 THEN @VFORM_ERROR ELSE '' END;
    SET @OPEN_CREATE=CASE WHEN @VFORM_REOPEN=1 THEN 1 ELSE 0 END;

    /* ============================================================
       7. JSON DE FERIADOS PARA EL CALENDARIO (cliente)
       ============================================================ */
    SELECT @HOLIDAYS_JSON=ISNULL((
        SELECT
            CONVERT(VARCHAR(10),Fecha,120) AS [f],
            Feriado                        AS [t],
            ISNULL(HolidayText,'')         AS [x]
        FROM dbo.Calendar WITH(NOLOCK)
        WHERE IsHoliday=1
        ORDER BY Fecha
        FOR JSON PATH
    ),'[]');
    SET @HOLIDAYS_JSON=REPLACE(REPLACE(@HOLIDAYS_JSON,'&','&amp;'),'"','&quot;');

    /* ============================================================
       8. ACCIONES: CREATE "Nuevo feriado" / EDIT "Eliminar feriado"
       ------------------------------------------------------------
       @HTML_FERIADO_DELETE se inserta dentro de UNA sola fila-proxy
       oculta (ver DOM PRINCIPAL) -- vct-agenda.js le cambia los
       data-vct-fecha/tipo/holidaytext segun el dia clickeado y despues
       dispara el click del boton real generado aca.
       ============================================================ */
    IF @CAN_EDIT=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',
             @TARGET_FORM='vctAgendaFeriadoDeleteModal',
             @FORM_TITLE='Eliminar feriado',
             @FORM_SUBTITLE='Esta fecha vuelve a ser un día laborable normal.',
             @FORM_ICON='calendar-x',
             @BUTTON_TEXT='',
             @BUTTON_ICON='trash',
             @BUTTON_CLASS='vct-agenda-proxy-btn',
             @TOOLTIP='Eliminar feriado',
             @SOURCE_SELECTOR='[data-vct-row]',
             @OUTHTML=@HTML_FERIADO_DELETE OUTPUT;

        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctAgendaFeriadoModal',
             @FORM_TITLE='Nuevo feriado',
             @FORM_SUBTITLE='Marcar una fecha del calendario como feriado.',
             @FORM_ICON='calendar-plus',
             @BUTTON_TEXT='Nuevo feriado',
             @BUTTON_ICON='plus',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-agenda-btn-new',
             @TOOLTIP='Nuevo feriado',
             @OUTHTML=@HTML_FERIADO_CREATE OUTPUT;
    END;

    /* ============================================================
       9. FORM "Nuevo feriado"
       ============================================================ */
    IF @CAN_EDIT=1
    BEGIN
        IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
        CREATE TABLE #VCT_FORM_FIELDS
        (
            ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
            COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
            OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT, HIDDEN BIT,
            HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
        );

        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO01','Fecha','TEXT',6,1,10,'AAAA-MM-DD',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO01 ELSE NULL END,0,0,'Formato AAAA-MM-DD.','fecha'),
        (2,'TEXTO02','Tipo','TEXT',6,1,1,'Seleccione tipo',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO02 ELSE '1' END,0,0,NULL,'tipo'),
        (3,'TEXTO03','Motivo','TEXT',12,1,200,'Motivo del feriado',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO03 ELSE NULL END,0,0,NULL,'holidaytext'),
        (4,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'FERIADO',0,1,NULL,NULL),
        (5,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
        (6,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

        EXEC dbo.VCT_MAIN_RENDER_FORM
             @FORM_ID='vctAgendaFeriadoModal',
             @TITLE='Nuevo feriado',
             @SUBTITLE='Marcar una fecha del calendario como feriado.',
             @ICON='calendar-plus',
             @LAYOUT='MODAL',
             @SAVE_LABEL='Guardar',
             @CANCEL_LABEL='Cancelar',
             @ERROR_MESSAGE=@FORM_ERR_CREATE,
             @OPEN_ON_RENDER=@OPEN_CREATE,
             @OUTHTML=@HTML_MODAL_CREATE OUTPUT;

        SET @HTML_MODAL_CREATE=ISNULL(@HTML_MODAL_CREATE,'')+
            '<template data-vct-field-options data-vct-target="vctAgendaFeriadoModal" data-vct-field="TEXTO02" data-vct-placeholder="Seleccione tipo">'+
                '<option value="1">Fijo (inamovible)</option>'+
                '<option value="2">Movible (puente)</option>'+
            '</template>';

        /* ============================================================
           10. FORM "Eliminar feriado" (confirmacion, campos readonly)
           ============================================================ */
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO01','Fecha','TEXT',12,0,10,NULL,NULL,NULL,1,0,NULL,'fecha'),
        (2,'TEXTO03','Motivo','TEXT',12,0,200,NULL,NULL,NULL,1,0,NULL,'holidaytext'),
        (3,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'FERIADO',0,1,NULL,NULL),
        (4,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
        (5,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

        EXEC dbo.VCT_MAIN_RENDER_FORM
             @FORM_ID='vctAgendaFeriadoDeleteModal',
             @TITLE='Eliminar feriado',
             @SUBTITLE='Esta fecha vuelve a ser un día laborable normal.',
             @ICON='calendar-x',
             @LAYOUT='MODAL',
             @SAVE_LABEL='Eliminar',
             @CANCEL_LABEL='Cancelar',
             @ERROR_MESSAGE='',
             @OPEN_ON_RENDER=0,
             @OUTHTML=@HTML_MODAL_DELETE OUTPUT;
    END;

    /* ============================================================
       11. DOM PRINCIPAL -- calendario full-width, sin panel fijo
       ============================================================ */
    SET @HTML='
<div class="vct-page vct-page-main vct-agenda-page"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'"
     data-vct-agenda-root
     data-vct-agenda-can-edit="'+CASE WHEN @CAN_EDIT=1 THEN '1' ELSE '0' END+'"
     data-vct-feriados="'+@HOLIDAYS_JSON+'">

    '+ISNULL(@HTML_FEEDBACK,'')+'

    <section class="vct-card vct-agenda-card">
        <div class="vct-agenda-toolbar">
            <div class="vct-agenda-view-toggle" data-vct-agenda-view-toggle>
                <button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>
                <button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button>
                <button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">Día</button>
            </div>

            <div class="vct-agenda-nav">
                <button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>
                <h2 class="vct-agenda-title" data-vct-agenda-title></h2>
                <button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button>
            </div>

            <div class="vct-agenda-toolbar-right">
                <div class="vct-agenda-jump">
                    <select class="vct-select vct-agenda-select-month" data-vct-agenda-select-month>
                        <option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option>
                        <option value="4">Abril</option><option value="5">Mayo</option><option value="6">Junio</option>
                        <option value="7">Julio</option><option value="8">Agosto</option><option value="9">Septiembre</option>
                        <option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option>
                    </select>
                    <select class="vct-select vct-agenda-select-year" data-vct-agenda-select-year></select>
                </div>
                '+ISNULL(@HTML_FERIADO_CREATE,'')+'
            </div>
        </div>

        <div class="vct-agenda-legend">
            <span class="vct-agenda-legend-item"><i class="vct-agenda-dot vct-agenda-dot-fijo"></i>Feriado fijo</span>
            <span class="vct-agenda-legend-item"><i class="vct-agenda-dot vct-agenda-dot-movible"></i>Feriado movible</span>
        </div>

        <div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div>
    </section>

    <div class="vct-agenda-proxy" data-vct-row data-vct-fecha="" data-vct-tipo="" data-vct-holidaytext="" data-vct-agenda-proxy-delete>
        '+ISNULL(@HTML_FERIADO_DELETE,'')+'
    </div>

    '+ISNULL(@HTML_MODAL_CREATE,'')+'
    '+ISNULL(@HTML_MODAL_DELETE,'')+'
</div>
<link rel="stylesheet" href="../css/vct-agenda.css?v=3">
<script src="../js/vct-agenda.js?v=3"></script>';

    SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+ISNULL(@HTML,'');
END
