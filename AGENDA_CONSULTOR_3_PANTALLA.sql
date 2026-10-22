/* ============================================================================
   AGENDA_CONSULTOR_3_PANTALLA
   ----------------------------------------------------------------------------
   Pantalla "Agenda del consultor" (SideBar Id=9, Code=AGENDA_CONSULTOR).
   Molde visual: shell + stats-row estilo Acciones + grilla de calendario
   (reusa las clases de vct-agenda.css) -> calendario y agenda unificados.

   Dos modos segun el perfil:
     - VE_TODO (GERENCIA/SQUAD/ADMINISTRACION/PROYECTOS): un <select> arriba
       para elegir CUALQUIER consultor y ver su disponibilidad (para decidir
       si le pueden asignar un proyecto). Al cambiar, guarda IDSELEC01 y
       recarga la misma pantalla (grid-action al guid de la pantalla).
     - CONSULTOR (perfil CONSULTORES): su propia agenda (resuelta por
       ID_USUARIO_SEGURIDAD), sin select.

   Datos: calcula una ventana amplia (hoy-3 meses .. hoy+12 meses) con
   dbo.VCT_FN_AGENDA_CONSULTOR_RANGO y la manda como JSON (armado con FOR XML
   PATH, compat 100-safe). El JS navega los meses offline.

   v1 = SOLO LECTURA (ver disponibilidad). El alta/edicion de bloqueos
   (DISPONIBLE=0) es el paso 2.

   Permisos: dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,'AGENDA_CONSULTOR') -> .VIEW.
   Ruteo: ACTION='AGENDA_CONSULTOR' (lo asocia el designer; ademas se agrega
   fallback en VCT_MAIN_DASHBOARD al final de este script).
   Re-ejecutable. Compat 100/140 (sin OPENJSON / FOR JSON / STRING_AGG).
   ============================================================================ */
USE [MuhlePROD];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.VCT_MAIN_AGENDA_CONSULTOR
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
    SET @OUTPARAM1 = '';
    SET @OUTPARAM2 = NULL;
    SET @OUTPARAM3 = NULL;

    DECLARE @MODULE_CODE VARCHAR(50) = 'AGENDA_CONSULTOR';
    DECLARE @GUID_SELF   VARCHAR(50) = 'EE2B3F6F-4900-4C8C-A287-D4630D65B344'; /* estructura CALL_CONV_STRUCTURES "16 - Agenda" (reentrada p/ recarga) */

    DECLARE @HTML_SHELL VARCHAR(MAX) = '', @RES VARCHAR(20) = '',
            @PERFIL VARCHAR(100) = UPPER(LTRIM(RTRIM(ISNULL(@IUNIDAD,'')))),
            @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @VE_TODO BIT = 0, @CAN_EDIT BIT = 0, @SIDEBAR_ID INT = 0,
            @CONS_ID INT = NULL, @CONS_NOMBRE VARCHAR(320) = '',
            @SEL_RAW VARCHAR(100) = '',
            @HTML VARCHAR(MAX) = '', @MSG VARCHAR(MAX) = '',
            @SUBT VARCHAR(200) = '';

    /* ¿el usuario logueado es un consultor? Su ficha MANDA sobre el perfil:
       un consultor ve SOLO su propia agenda (sin select); solo un admin/comercial
       que NO es consultor ve el select para elegir cualquiera. */
    DECLARE @SELF_CONS INT = NULL;
    SELECT TOP 1 @SELF_CONS = ID FROM dbo.VCT_CONSULTORES
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U
      AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO'
    ORDER BY ID DESC;

    SET @VE_TODO = CASE WHEN @SELF_CONS IS NULL AND @PERFIL IN ('GERENCIA','SQUAD','ADMINISTRACION','PROYECTOS') THEN 1 ELSE 0 END;
    SET @SUBT = 'Disponibilidad por d' + CHAR(237) + 'a: disponible, asignado, licencia, ocupado y feriados.';

    /* ---------- shell ---------- */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @FORM_ID=@FORM_ID,
             @TITLE='Agenda del consultor',
             @SUBTITLE=@SUBT,
             @SEARCH_PLACEHOLDER='', @SHOW_SEARCH=0,
             @OSHELL=@HTML_SHELL OUTPUT, @ORESULTADO=@RES OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
    END CATCH;

    /* ---------- permisos ---------- */
    IF OBJECT_ID('tempdb..#ACC') IS NOT NULL DROP TABLE #ACC;
    SELECT * INTO #ACC FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, @MODULE_CODE);

    SELECT TOP 1 @SIDEBAR_ID = ISNULL(SIDEBAR_ID,0) FROM #ACC WHERE ISNULL(SIDEBAR_ID,0)<>0 ORDER BY SORT_ORDER, ID_PRM;
    SET @CAN_EDIT = CASE WHEN EXISTS(SELECT 1 FROM #ACC WHERE ACTION_TYPE='EDIT') THEN 1 ELSE 0 END;

    IF NOT EXISTS(SELECT 1 FROM #ACC WHERE ACTION_TYPE='VIEW')
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') +
        '<div class="vct-page vct-page-main" data-vct-page data-vct-sidebar-id="'+CONVERT(VARCHAR(20),@SIDEBAR_ID)+'" data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">'
        +'<section class="vct-card"><div class="vct-card-body"><h2 class="vct-card-title">Acceso restringido</h2>'
        +'<p class="vct-card-subtitle">No posee permisos para ver la Agenda del consultor.</p></div></section></div>';
        RETURN;
    END;

    /* ---------- resolver consultor ---------- */
    IF @VE_TODO = 1
    BEGIN
        SELECT TOP 1 @SEL_RAW = ISNULL(CONVERT(VARCHAR(100), IDSELEC01),'')
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

        IF @SEL_RAW LIKE '%[0-9]%' AND @SEL_RAW NOT LIKE '%[^0-9]%'
            SET @CONS_ID = CONVERT(INT, @SEL_RAW);
    END
    ELSE
    BEGIN
        SET @CONS_ID = @SELF_CONS;   /* consultor: su propia agenda */
    END;

    IF @CONS_ID IS NOT NULL
        SELECT @CONS_NOMBRE = LTRIM(RTRIM(ISNULL(APELLIDOS,'') + CASE WHEN ISNULL(NOMBRES,'')<>'' THEN ', '+NOMBRES ELSE '' END))
        FROM dbo.VCT_CONSULTORES WHERE ID = @CONS_ID;

    /* ---------- alta/edicion/baja de fecha del consultor ----------
       Comando por buffer:
         TEXTO01 = fecha (AAAA-MM-DD)
         TEXTO02 = motivo       (licencia: Vacaciones / Medica)
         TEXTO03 = tipo         (DISPONIBLE/LICENCIA/OCUPADO/POTENCIAL/ORGANISMO/OBSERVACION)
         TEXTO04 = descripcion  (obligatoria salvo DISPONIBLE/LICENCIA)
         TEXTO05 = horas         (DISPONIBLE/POTENCIAL/ORGANISMO; resto = 0)
         FLAG01 = 1 guardar, FLAG02 = 1 eliminar la fecha. Solo con EDIT.
       Validaciones en el modal y en servidor; no persiste entradas invalidas. */
    IF @CAN_EDIT = 1 AND @CONS_ID IS NOT NULL
    BEGIN
        DECLARE @B_FECHA VARCHAR(20)='', @B_MOT VARCHAR(200)='', @B_TIPO VARCHAR(20)='',
                @B_DESC VARCHAR(400)='', @B_HOR VARCHAR(20)='',
                @B_SET VARCHAR(10)='0', @B_DEL VARCHAR(10)='0',
                @B_D DATE, @B_DISP BIT, @B_HORN DECIMAL(5,2);
        SELECT TOP 1
            @B_FECHA = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(20),  TEXTO01),''))),
            @B_MOT   = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(200), TEXTO02),''))),
            @B_TIPO  = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(20),  TEXTO03),'')))),
            @B_DESC  = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(400), TEXTO04),''))),
            @B_HOR   = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(20),  TEXTO05),''))),
            @B_SET   = ISNULL(CONVERT(VARCHAR(10), FLAG01),'0'),
            @B_DEL   = ISNULL(CONVERT(VARCHAR(10), FLAG02),'0')
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;

        IF ISDATE(@B_FECHA)=1 AND (@B_SET='1' OR @B_DEL='1')
        BEGIN
            SET @B_D = CONVERT(DATE, @B_FECHA, 120);
            IF @B_DEL='1'
                DELETE FROM dbo.VCT_PRM_AGENDA_CONSULTOR WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D;
            ELSE
            BEGIN
                SET @B_HORN = 0;
                IF @B_TIPO <> 'LICENCIA' AND EXISTS (
                    SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR
                    WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D AND TIPO='LICENCIA')
                    SET @MSG = 'Elimin&aacute; primero la licencia o vacaciones.';
                ELSE IF @B_TIPO NOT IN ('DISPONIBLE','LICENCIA','OCUPADO','NO_DISPONIBLE','POTENCIAL','ORGANISMO','OBSERVACION')
                    SET @MSG = 'Eleg&iacute; un tipo v&aacute;lido.';
                ELSE IF @B_TIPO IN ('POTENCIAL','ORGANISMO','OBSERVACION') AND @B_DESC = ''
                    SET @MSG = 'Complet&aacute; la descripci&oacute;n de la fecha.';
                ELSE IF @B_TIPO = 'LICENCIA' AND @B_MOT = ''
                    SET @MSG = 'Eleg&iacute; el motivo de la licencia.';
                ELSE IF @B_TIPO IN ('DISPONIBLE','POTENCIAL','ORGANISMO')
                BEGIN
                    DECLARE @B_HVALID DECIMAL(18,4);
                    BEGIN TRY
                        IF @B_HOR = '' OR @B_HOR LIKE '%[^0-9.]%'
                            SET @MSG = 'Ingres&aacute; horas entre 0,5 y 24, en intervalos de media hora.';
                        ELSE
                        BEGIN
                            SET @B_HVALID = CONVERT(DECIMAL(18,4), @B_HOR);
                            IF @B_HVALID <= 0 OR @B_HVALID > 24 OR @B_HVALID * 2 <> FLOOR(@B_HVALID * 2)
                                SET @MSG = 'Ingres&aacute; horas entre 0,5 y 24, en intervalos de media hora.';
                            ELSE
                                SET @B_HORN = CONVERT(DECIMAL(5,2), @B_HVALID);
                        END;
                    END TRY
                    BEGIN CATCH
                        SET @MSG = 'Ingres&aacute; horas entre 0,5 y 24, en intervalos de media hora.';
                    END CATCH;
                END;

                /* CAL13_VALIDACION: rechazos esperados se muestran dentro de Agenda. */
                IF @MSG='' AND @B_TIPO='LICENCIA'
                BEGIN
                    IF EXISTS(SELECT 1 FROM dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD
                      WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D AND ACTIVO=1)
                        SET @MSG='El dia tiene actividades. Reprograme las actividades antes de cargar la licencia.';
                    ELSE IF EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES C
                      JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID=C.ID_VISITA
                      WHERE C.ID_CONSULTOR=@CONS_ID
                        AND @B_D BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))
                        AND ISNULL(V.ESTADO,'') NOT IN ('CANCELADO','CANCELADA','ANULADO','ANULADA'))
                        SET @MSG='El dia tiene una visita asignada. Reprograme la visita antes de cargar la licencia.';
                    ELSE IF EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO
                      WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D)
                        SET @MSG='El dia tiene horas registradas. Revise el registro antes de cargar la licencia.';
                END;
                DECLARE @CAL13_OWNTRAN BIT=0;
                BEGIN TRY
                    IF @MSG='' AND @@TRANCOUNT=0
                    BEGIN
                        BEGIN TRANSACTION;
                        SET @CAL13_OWNTRAN=1;
                    END;
                IF @MSG = ''
                BEGIN
                    SET @B_DISP = CASE WHEN @B_TIPO='DISPONIBLE' THEN 1 ELSE 0 END;
                    IF @B_TIPO <> 'LICENCIA' SET @B_MOT = '';
                    IF @B_TIPO NOT IN ('POTENCIAL','ORGANISMO','OBSERVACION') SET @B_DESC = '';
                    /* Horas cero para LICENCIA, OCUPADO y OBSERVACION. */
                    IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D)
                        UPDATE dbo.VCT_PRM_AGENDA_CONSULTOR
                           SET TIPO=@B_TIPO, DISPONIBLE=@B_DISP, HORAS_CAPACIDAD=@B_HORN,
                               MOTIVO=NULLIF(@B_MOT,''), DESCRIPCION=NULLIF(@B_DESC,''),
                               FECHA_UPD=GETDATE(), USUARIO_UPD=@U
                         WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D;
                    ELSE
                        INSERT INTO dbo.VCT_PRM_AGENDA_CONSULTOR (ID_CONSULTOR,FECHA,TIPO,HORAS_CAPACIDAD,DISPONIBLE,MOTIVO,DESCRIPCION,FECHA_ALTA,USUARIO_ALTA)
                        VALUES (@CONS_ID,@B_D,@B_TIPO,@B_HORN,@B_DISP,NULLIF(@B_MOT,''),NULLIF(@B_DESC,''),GETDATE(),@U);
                END;
                    IF @CAL13_OWNTRAN=1 COMMIT TRANSACTION;
                END TRY
                BEGIN CATCH
                    IF @CAL13_OWNTRAN=1 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION;
                    IF ERROR_NUMBER()<>51012 OR XACT_STATE()=-1 THROW;
                    SET @MSG=LEFT(ERROR_MESSAGE(),1000);
                END CATCH;
            END;

            UPDATE dbo.VCT_BUFFER SET TEXTO01=NULL, TEXTO02=NULL, TEXTO03=NULL, TEXTO04=NULL, TEXTO05=NULL, FLAG01='0', FLAG02='0' WHERE PAR_KEY=@IPKEYJOB;
        END;
    END;

    /* ---------- select de consultor (solo VE_TODO) ---------- */
    DECLARE @SELECT_CONS VARCHAR(MAX) = '';
    IF @VE_TODO = 1
    BEGIN
        DECLARE @OPTS VARCHAR(MAX) = ISNULL((
            SELECT '<option value="'+CONVERT(VARCHAR(10),C.ID)+'"'+CASE WHEN C.ID=@CONS_ID THEN ' selected' ELSE '' END+'>'
                 + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(C.APELLIDOS,'')+CASE WHEN ISNULL(C.NOMBRES,'')<>'' THEN ', '+C.NOMBRES ELSE '' END)),'&','&amp;'),'<','&lt;'),'>','&gt;')
                 + '</option>'
            FROM dbo.VCT_CONSULTORES C
            WHERE UPPER(ISNULL(C.ESTADO,''))='ACTIVO'
            ORDER BY C.APELLIDOS, C.NOMBRES
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        SET @SELECT_CONS =
            '<div class="vct-agc-pick">'
          + '<label class="vct-agc-pick-label">Consultor</label>'
          + '<select class="vct-select vct-agc-select-cons" data-vct-agc-select-cons aria-label="Consultor">'
          + '<option value="">Eleg' + CHAR(237) + ' un consultor...</option>'
          + @OPTS + '</select></div>';
    END;

    /* ---------- datos (JSON de dias) ---------- */
    DECLARE @HOY DATE = CONVERT(DATE, GETDATE());
    DECLARE @DESDE DATE = DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(@HOY), MONTH(@HOY), 1));
    DECLARE @HASTA DATE = EOMONTH(@HOY, 12);
    DECLARE @DIAS_JSON VARCHAR(MAX) = '[]';

    /* opciones de AÑO generadas en el server (año-1 .. año+2) para que el
       widget custom de la plataforma las tenga al inicializarse (si las pone el
       JS despues, el widget queda vacio). */
    DECLARE @YA INT = YEAR(@HOY), @YEAR_OPTS VARCHAR(400) =
        '<option value="'+CONVERT(VARCHAR(4),YEAR(@HOY)-1)+'">'+CONVERT(VARCHAR(4),YEAR(@HOY)-1)+'</option>'
      + '<option value="'+CONVERT(VARCHAR(4),YEAR(@HOY)  )+'">'+CONVERT(VARCHAR(4),YEAR(@HOY)  )+'</option>'
      + '<option value="'+CONVERT(VARCHAR(4),YEAR(@HOY)+1)+'">'+CONVERT(VARCHAR(4),YEAR(@HOY)+1)+'</option>'
      + '<option value="'+CONVERT(VARCHAR(4),YEAR(@HOY)+2)+'">'+CONVERT(VARCHAR(4),YEAR(@HOY)+2)+'</option>';

    IF @CONS_ID IS NOT NULL
    BEGIN
        SET @DIAS_JSON = '[' + ISNULL(STUFF((
            SELECT ',{"f":"' + CONVERT(VARCHAR(10), R.FECHA, 120)
                 + '","e":"' + R.ESTADO
                 + '","h":' + CONVERT(VARCHAR(10), CONVERT(DECIMAL(6,1), CASE WHEN R.ESTADO IN ('DISPONIBLE','POTENCIAL','ORGANISMO') THEN ISNULL(AG.HORAS_CAPACIDAD,R.HORAS) ELSE R.HORAS END))
                 + ',"hc":' + CONVERT(VARCHAR(10),CONVERT(DECIMAL(5,2),ISNULL(AG.HORAS_CAPACIDAD,0)))
                 + ',"t":"'  + ISNULL(R.TIPO,'')
                 + '","n":"' + REPLACE(REPLACE(REPLACE(ISNULL(R.NOTA,''),'\','/'),'"',''''),CHAR(10),' ')
                 + '","mo":"'+ REPLACE(REPLACE(REPLACE(ISNULL(R.MOTIVO,''),'\','/'),'"',''''),CHAR(10),' ')
                 + '","de":"'+ REPLACE(REPLACE(REPLACE(ISNULL(R.DESCRIPCION,''),'\','/'),'"',''''),CHAR(10),' ')
                 /* TOOLTIP_V1: asignado por visita -> cliente / proyecto / servicio(s) */
                 + '","cli":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C2.RAZON_SOCIAL,''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
                 + '","proy":"'+ REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN P2.ID IS NOT NULL THEN ISNULL('('+NULLIF(LTRIM(RTRIM(P2.CODIGO)),'')+') ','')+ISNULL(P2.NOMBRE,'') ELSE '' END,'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
                 + '","srv":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(STUFF((SELECT ', '+UPPER(LEFT(ISNULL(S.CODIGO,''),2))+'|'+CONVERT(VARCHAR(200),S.DESCRIPCION) FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID=PS.ID_SERVICIO WHERE PS.ID_PROYECTO=VX.ID_PROYECTO ORDER BY S.ID FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,2,''),''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
                 + '"}'
            FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@CONS_ID, @DESDE, @HASTA) R
            LEFT JOIN dbo.VCT_PRM_AGENDA_CONSULTOR AG ON AG.ID_CONSULTOR=@CONS_ID AND AG.FECHA=R.FECHA
            OUTER APPLY (
                SELECT TOP 1 PV.ID_PROYECTO
                FROM dbo.VCT_PROYECTOS_VISITAS PV WITH(NOLOCK)
                INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES PVC WITH(NOLOCK) ON PVC.ID_VISITA=PV.ID
                WHERE PVC.ID_CONSULTOR=@CONS_ID
                  AND R.FECHA BETWEEN CONVERT(DATE,PV.FECHA_DESDE) AND CONVERT(DATE,ISNULL(PV.FECHA_HASTA,PV.FECHA_DESDE))
                ORDER BY PV.ID DESC
            ) VX
            LEFT JOIN dbo.VCT_PROYECTOS P2 WITH(NOLOCK) ON P2.ID = VX.ID_PROYECTO
            LEFT JOIN dbo.VCT_CLIENTES  C2 WITH(NOLOCK) ON C2.ID = P2.IDCLIENTE
            ORDER BY R.FECHA
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 1, ''), '') + ']';
    END
    ELSE
    BEGIN
        /* sin consultor elegido: igual mostramos los FERIADOS (fijo/movible)
           de dbo.Calendar, para que el calendario no quede totalmente vacio. */
        SET @DIAS_JSON = '[' + ISNULL(STUFF((
            SELECT ',{"f":"' + CONVERT(VARCHAR(10), cal.Fecha, 120)
                 + '","e":"' + CASE WHEN CONVERT(INT, ISNULL(cal.Feriado,0)) = 2 THEN 'FERIADO_MOV' ELSE 'FERIADO_FIJO' END
                 + '","h":0,"hc":0,"t":"'
                 + '","n":"' + REPLACE(REPLACE(REPLACE(ISNULL(cal.HolidayText,''),'\','/'),'"',''''),CHAR(10),' ')
                 + '","mo":"","de":""}'
            FROM dbo.Calendar cal
            WHERE cal.Fecha BETWEEN @DESDE AND @HASTA AND cal.IsHoliday = 1
            ORDER BY cal.Fecha
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 1, ''), '') + ']';
    END;

    /* ---------- datos (JSON de ACTIVIDADES con horario, estilo Google Calendar) ---------- */
    /* TOOLTIP_V1: actividades con cliente/proyecto/servicio (mismo tooltip que Acciones).
       La armadura del JSON vive en dbo.VCT_FN_AGENDA_ACTS_JSON (una sola fuente,
       compartida con la V360 del consultor). */
    DECLARE @ACTS_JSON VARCHAR(MAX) = '[]';
    IF @CONS_ID IS NOT NULL
        SET @ACTS_JSON = dbo.VCT_FN_AGENDA_ACTS_JSON(@CONS_ID, @DESDE, @HASTA);

    /* escape para atributo HTML (igual que el calendario de feriados) */
    SET @DIAS_JSON = REPLACE(REPLACE(@DIAS_JSON, '&', '&amp;'), '"', '&quot;');
    SET @ACTS_JSON = REPLACE(REPLACE(@ACTS_JSON, '&', '&amp;'), '"', '&quot;');

    /* ---------- cuerpo ---------- */
    DECLARE @NEED_PICK BIT = CASE WHEN @CONS_ID IS NULL THEN 1 ELSE 0 END;

    SET @HTML =
        '<link rel="stylesheet" href="../css/vct-inicio.css?v=5">'
      + '<link rel="stylesheet" href="../css/vct-calendario.css?v=39">'
      + '<script src="../js/vct-calendario.js?v=39"></script>'
      + '<div class="vct-page vct-page-main vct-agc-page" data-vct-page'
      + ' data-vct-sidebar-id="' + CONVERT(VARCHAR(20),@SIDEBAR_ID) + '"'
      + ' data-vct-form-id="' + ISNULL(@FORM_ID,'') + '"'
      + ' data-vct-agc-root'
      + ' data-vct-agc-guid="' + @GUID_SELF + '"'
      + ' data-vct-agc-ve-todo="' + CASE WHEN @VE_TODO=1 THEN '1' ELSE '0' END + '"'
      + ' data-vct-agc-can-edit="' + CASE WHEN @CAN_EDIT=1 THEN '1' ELSE '0' END + '"'
      + ' data-vct-agc-cons="' + ISNULL(CONVERT(VARCHAR(10),@CONS_ID),'') + '"'
      + ' data-vct-agc-dias="' + @DIAS_JSON + '"'
      + ' data-vct-agc-acts="' + @ACTS_JSON + '">'

      + '<section class="vct-card vct-agc-card">'
      + CASE WHEN @MSG <> '' THEN '<p class="vct-agc-modal-err" role="alert">' + @MSG + '</p>' ELSE '' END
      /* ===== layout SIEMPRE visible: toolbar + KPIs + leyenda + calendario.
         Sin consultor elegido el calendario se dibuja en blanco (todo "no
         cargado") y al elegir uno recarga y se puebla todo. ===== */
      + '<div class="vct-agenda-toolbar vct-agc-toolbar">'
      +   ISNULL(@SELECT_CONS,'')
      +   '<div class="vct-agenda-view-toggle" data-vct-agc-view-toggle>'
      +     '<button type="button" class="vct-agenda-view-btn is-active" data-vct-agc-view="month">Mes</button>'
      +     '<button type="button" class="vct-agenda-view-btn" data-vct-agc-view="week">Semana</button>'
      +     '<button type="button" class="vct-agenda-view-btn" data-vct-agc-view="day">D' + CHAR(237) + 'a</button>'
      +   '</div>'
      +   '<div class="vct-agenda-nav">'
      +     '<button type="button" class="vct-agenda-nav-btn" data-vct-agc-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>'
      +     '<h2 class="vct-agenda-title" data-vct-agc-title></h2>'
      +     '<button type="button" class="vct-agenda-nav-btn" data-vct-agc-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button>'
      +   '</div>'
      +   '<div class="vct-agenda-toolbar-right"><div class="vct-agenda-jump vct-agc-jump">'
      +     '<select class="vct-select vct-agc-sel-month" data-vct-agc-month aria-label="Mes">'
      +       '<option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option>'
      +       '<option value="4">Abril</option><option value="5">Mayo</option><option value="6">Junio</option>'
      +       '<option value="7">Julio</option><option value="8">Agosto</option><option value="9">Septiembre</option>'
      +       '<option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option>'
      +     '</select>'
      +     '<select class="vct-select vct-agc-sel-year" data-vct-agc-year aria-label="Año">' + @YEAR_OPTS + '</select>'
      +   '</div></div>'
      + '</div>'
      + '<div class="vct-soft-kpi-grid vct-agc-stats" data-vct-agc-stats></div>'
      + '<div class="vct-agenda-legend vct-agc-legend">'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-nocargado"></i>No cargado</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-disponible"></i>Disponible</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-asignado"></i>Asignado</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-licencia"></i>Licencia</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-ocupado"></i>Ocupado</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-potencial"></i>Potencial</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-organismo"></i>Organismo</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-observacion"></i>Observaci' + CHAR(243) + 'n</span>'
      +   '<span class="vct-agenda-legend-item"><i class="vct-agc-dot vct-agc-dot-feriado"></i>Feriado</span>'
      + '</div>'
      + '<div class="vct-agenda-view-pane vct-agc-pane" data-vct-agc-pane></div>'
      + '</section>'
      + '</div>';

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @HTML;
END

GO

PRINT 'OK: VCT_MAIN_AGENDA_CONSULTOR creado/actualizado.';
GO

/* ===== Ruteo fallback: ACTION=AGENDA_CONSULTOR -> VCT_MAIN_AGENDA_CONSULTOR =====
   (ademas de la asociacion en el designer). Mismo patron que PROYECTOS. */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD'));
IF @D IS NULL
    PRINT 'No existe dbo.VCT_MAIN_DASHBOARD (se omite el ruteo fallback).';
ELSE IF CHARINDEX(N'AGENDACONS_RUTEO_V1', @D) > 0
    PRINT 'VCT_MAIN_DASHBOARD ya ruteaba Agenda del consultor. Sin cambios.';
ELSE IF CHARINDEX(N'ACCIONES_RUTEO_V1', @D) = 0
    PRINT 'AVISO: no se encontro ACCIONES_RUTEO_V1; no se toco el ruteo (el designer alcanza).';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));
    DECLARE @NL NCHAR(1) = NCHAR(10);
    DECLARE @ANCLA NVARCHAR(MAX) =
        N'    /* ACCIONES_RUTEO_V1: el menu Acciones (ACTION=PLANIFICACION) no tiene paso propio en la plataforma */';
    DECLARE @NUEVO NVARCHAR(MAX) =
        N'    /* AGENDACONS_RUTEO_V1: el menu Agenda del consultor (ACTION=AGENDA_CONSULTOR) no tiene paso propio en la plataforma */' + @NL +
        N'    IF OBJECT_ID(''dbo.VCT_MAIN_AGENDA_CONSULTOR'') IS NOT NULL' + @NL +
        N'       AND EXISTS (SELECT 1 FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB AND UPPER(LTRIM(RTRIM(ISNULL(ACTION,'''')))) = ''AGENDA_CONSULTOR'')' + @NL +
        N'    BEGIN' + @NL +
        N'        EXEC dbo.VCT_MAIN_AGENDA_CONSULTOR @IPKEYJOB = @IPKEYJOB, @FORM_ID = @FORM_ID, @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE,' + @NL +
        N'             @OUTPARAM1 = @OUTPARAM1 OUTPUT, @OUTPARAM2 = @OUTPARAM2 OUTPUT, @OUTPARAM3 = @OUTPARAM3 OUTPUT;' + @NL +
        N'        RETURN;' + @NL +
        N'    END;' + @NL + @NL +
        @ANCLA;

    IF CHARINDEX(@ANCLA, @D) = 0
        PRINT 'AVISO: no se encontro el ancla exacta; no se toco el ruteo (el designer alcanza).';
    ELSE
    BEGIN
        SET @D = REPLACE(@D, @ANCLA, @NUEVO);
        DECLARE @kp INT = CHARINDEX(N'PROCEDURE', @D), @kpre NVARCHAR(60);
        SET @kpre = SUBSTRING(@D, CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END, CASE WHEN @kp > 40 THEN 40 ELSE @kp - 1 END);
        IF CHARINDEX(N'OR ALTER', @kpre) = 0 AND CHARINDEX(N'CREATE', @kpre) > 0
            SET @D = STUFF(@D, (CASE WHEN @kp > 40 THEN @kp - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @kpre) - 1, 6, N'ALTER');
        BEGIN TRY
            EXEC sp_executesql @D;
            PRINT 'OK: VCT_MAIN_DASHBOARD rutea ACTION=AGENDA_CONSULTOR a VCT_MAIN_AGENDA_CONSULTOR.';
        END TRY
        BEGIN CATCH
            PRINT 'ERROR al rutear: ' + ERROR_MESSAGE() + ' (el SP quedo creado igual; el designer alcanza).';
        END CATCH;
    END;
END;
GO
