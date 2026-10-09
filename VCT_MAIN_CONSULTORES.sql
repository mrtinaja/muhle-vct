USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[VCT_MAIN_CONSULTORES]
        Migrado al motor de tablas nuevo (vct-datagrid.js / vct-datagrid.css / vct-export.js).
        Sin cambios de logica: permisos, guardado, historial de dias mensuales, validaciones,
        formulario y renderers de acciones (VIEW / EDIT / CREATE) quedan IGUAL.
        Solo cambia el markup de la grilla; se elimina el <style> local de filtros
        (el motor resuelve el layout de filtros en todas las pantallas). ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[VCT_MAIN_CONSULTORES]
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
    SET @OUTPARAM2 = '';
    SET @OUTPARAM3 = '';

    DECLARE @MODULE_CODE VARCHAR(50) = 'CONSULTORES';

    DECLARE
        @HTML_SHELL          VARCHAR(MAX) = '',
        @HTML                VARCHAR(MAX) = '',
        @HTML_ROWS           VARCHAR(MAX) = '',
        @HTML_USUARIOS       VARCHAR(MAX) = '',
        @HTML_TOOL_ACTIONS   VARCHAR(MAX) = '',
        @HTML_EDIT_ACTION    VARCHAR(MAX) = '',
        @HTML_MODAL          VARCHAR(MAX) = '',
        @RESULTADO_SHELL     VARCHAR(20)  = '',
        @SIDEBAR_ID          INT = 0,
        @TOTAL               INT = 0,
        @TOTAL_ACTIVOS       INT = 0,
        @TOTAL_EVENTUALES    INT = 0,
        @TOTAL_SISTEMA       INT = 0,
        @VID_CONSULTOR       VARCHAR(100) = '',
        @VTEXTO01            VARCHAR(500) = '',
        @VTEXTO02            VARCHAR(500) = '',
        @VTEXTO03            VARCHAR(100) = '',
        @VTEXTO04            VARCHAR(100) = '',
        @VTEXTO05            VARCHAR(100) = '',
        @VTEXTO06            VARCHAR(200) = '',
        @VTEXTO07            VARCHAR(100) = '',
        @VTEXTO08            VARCHAR(100) = '',
        @VTEXTO09            VARCHAR(50)  = '',
        @VTEXTO10            VARCHAR(50)  = '',
        @VTEXTO11            VARCHAR(200) = '',
        @VFLAG01             VARCHAR(10)  = '',
        @VFLAG02             VARCHAR(10)  = '0',
        @VFORM_ERROR         VARCHAR(1000) = '',
        @VFORM_REOPEN        BIT = 0,
        @VID_CONSULTOR_INT   INT = NULL,
        @VDIAS_ANTERIORES    INT = NULL,
        @VDIAS_NUEVOS        INT = NULL,
        @VPERIODO            INT = 0;

    /* ============================================================
       1. SHELL GENERAL: Sidebar + Header
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Consultores',
             @SUBTITLE           = 'Gestión y consulta de consultores del sistema.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
        SET @RESULTADO_SHELL = 'ERROR';
    END CATCH;

    /* ============================================================
       2. ACCIONES DEL MODULO
       ============================================================ */
    IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;

    SELECT *
    INTO #ACCIONES
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);

    SELECT TOP 1 @SIDEBAR_ID = ISNULL(SIDEBAR_ID,0)
    FROM #ACCIONES
    WHERE ISNULL(SIDEBAR_ID,0) <> 0
    ORDER BY SORT_ORDER,ID_PRM;

    IF NOT EXISTS (SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='VIEW')
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + '
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para visualizar Consultores.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* ============================================================
       3. POSTBACK ALTA / EDICION
       ------------------------------------------------------------
       TEXTO01 Nombres
       TEXTO02 Apellidos
       TEXTO03 Tipo documento
       TEXTO04 Numero documento
       TEXTO05 CUIT
       TEXTO06 Formacion
       TEXTO07 Movilidad
       TEXTO08 Dias mensuales
       TEXTO09 Eventual
       TEXTO10 Estado
       TEXTO11 Usuario seguridad
       FLAG02  Ingresa al sistema
       ============================================================ */
    SELECT TOP 1
        @VID_CONSULTOR = ISNULL(CONVERT(VARCHAR(100),IDSELEC01),''),
        @VTEXTO01      = ISNULL(CONVERT(VARCHAR(500),TEXTO01),''),
        @VTEXTO02      = ISNULL(CONVERT(VARCHAR(500),TEXTO02),''),
        @VTEXTO03      = ISNULL(CONVERT(VARCHAR(100),TEXTO03),''),
        @VTEXTO04      = ISNULL(CONVERT(VARCHAR(100),TEXTO04),''),
        @VTEXTO05      = ISNULL(CONVERT(VARCHAR(100),TEXTO05),''),
        @VTEXTO06      = ISNULL(CONVERT(VARCHAR(200),TEXTO06),''),
        @VTEXTO07      = ISNULL(CONVERT(VARCHAR(100),TEXTO07),''),
        @VTEXTO08      = ISNULL(CONVERT(VARCHAR(100),TEXTO08),''),
        @VTEXTO09      = ISNULL(CONVERT(VARCHAR(50),TEXTO09),''),
        @VTEXTO10      = ISNULL(CONVERT(VARCHAR(50),TEXTO10),''),
        @VTEXTO11      = ISNULL(CONVERT(VARCHAR(200),TEXTO11),''),
        @VFLAG01       = ISNULL(CONVERT(VARCHAR(10),FLAG01),''),
        @VFLAG02       = ISNULL(CONVERT(VARCHAR(10),FLAG02),'0')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;

    /*
       FLAG02 es el estado del toggle "Ingresa al sistema".
       El formulario se abre/cierra en cliente y VCT_BUFFER puede conservar
       el valor de una operacion anterior si el toggle quedo desmarcado.
       Normalizamos el valor y, cuando no estamos procesando un guardado,
       limpiamos los slots exclusivos del acceso al sistema para que una
       edicion nueva nunca herede FLAG02/TEXTO11 de otra fila.
    */
    SET @VFLAG02 = CASE WHEN @VFLAG02='1' THEN '1' ELSE '0' END;

    IF ISNULL(@VFLAG01,'')<>'1'
    BEGIN
        UPDATE dbo.VCT_BUFFER
           SET FLAG02=0,
               TEXTO11=''
         WHERE PAR_KEY=@IPKEYJOB;

        SET @VFLAG02='0';
        SET @VTEXTO11='';
    END;

    IF @VFLAG01='1'
    BEGIN
        SET @VFORM_ERROR='';

        IF NULLIF(LTRIM(RTRIM(@VTEXTO01)),'') IS NULL
            SET @VFORM_ERROR='Los nombres son obligatorios.';

        IF @VFORM_ERROR='' AND NULLIF(LTRIM(RTRIM(@VTEXTO02)),'') IS NULL
            SET @VFORM_ERROR='Los apellidos son obligatorios.';

        IF @VFORM_ERROR='' AND NULLIF(LTRIM(RTRIM(@VTEXTO03)),'') IS NULL
            SET @VFORM_ERROR='El tipo de documento es obligatorio.';

        IF @VFORM_ERROR='' AND NULLIF(LTRIM(RTRIM(@VTEXTO04)),'') IS NULL
            SET @VFORM_ERROR='El número de documento es obligatorio.';

        IF @VFORM_ERROR='' AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.CAT_DATA CD WITH(NOLOCK)
            WHERE CD.PAR_KEY=
            (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH(NOLOCK)
                WHERE CAT_TYPE_CODE='TIPO_DOCUMENTO'
            )
              AND CD.CAT_DATA_CODE COLLATE DATABASE_DEFAULT=
                  LTRIM(RTRIM(@VTEXTO03)) COLLATE DATABASE_DEFAULT
        )
            SET @VFORM_ERROR='El tipo de documento seleccionado no es válido.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO07)),'') IS NOT NULL
           AND UPPER(LTRIM(RTRIM(@VTEXTO07))) NOT IN ('SI','NO')
            SET @VFORM_ERROR='La movilidad seleccionada no es válida.';

        IF @VFORM_ERROR=''
           AND UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO09,'')))) NOT IN ('SI','NO')
            SET @VFORM_ERROR='Seleccione si el consultor es eventual.';

        IF @VFORM_ERROR=''
           AND UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO10,'')))) NOT IN ('ACTIVO','INACTIVO')
            SET @VFORM_ERROR='El estado seleccionado no es válido.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO08)),'') IS NOT NULL
           AND LTRIM(RTRIM(@VTEXTO08)) LIKE '%[^0-9]%'
            SET @VFORM_ERROR='Los días mensuales deben ser un número entero.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO08)),'') IS NOT NULL
           AND LEN(LTRIM(RTRIM(@VTEXTO08)))>2
            SET @VFORM_ERROR='Los días mensuales deben estar entre 0 y 31.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO08)),'') IS NOT NULL
           AND CONVERT(INT,LTRIM(RTRIM(@VTEXTO08)))>31
            SET @VFORM_ERROR='Los días mensuales deben estar entre 0 y 31.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VID_CONSULTOR)),'') IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
               WHERE CONVERT(VARCHAR(100),C.ID)=@VID_CONSULTOR
           )
            SET @VFORM_ERROR='El consultor seleccionado no existe.';

        IF @VFORM_ERROR='' AND EXISTS
        (
            SELECT 1
            FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(ISNULL(C.TIPO_DOCUMENTO,'')))) COLLATE DATABASE_DEFAULT=
                  UPPER(LTRIM(RTRIM(@VTEXTO03))) COLLATE DATABASE_DEFAULT
              AND LTRIM(RTRIM(ISNULL(C.NRO_DOCUMENTO,''))) COLLATE DATABASE_DEFAULT=
                  LTRIM(RTRIM(@VTEXTO04)) COLLATE DATABASE_DEFAULT
              AND CONVERT(VARCHAR(100),C.ID)<>@VID_CONSULTOR
        )
            SET @VFORM_ERROR='Ya existe otro consultor con el mismo tipo y número de documento.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO05)),'') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
               WHERE LTRIM(RTRIM(ISNULL(C.CUIT,''))) COLLATE DATABASE_DEFAULT=
                     LTRIM(RTRIM(@VTEXTO05)) COLLATE DATABASE_DEFAULT
                 AND CONVERT(VARCHAR(100),C.ID)<>@VID_CONSULTOR
           )
            SET @VFORM_ERROR='Ya existe otro consultor con el CUIT ingresado.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND NULLIF(LTRIM(RTRIM(@VTEXTO11)),'') IS NULL
            SET @VFORM_ERROR='Seleccione el usuario del sistema.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.GroupsUserMembers G WITH(NOLOCK)
               WHERE UPPER(LTRIM(RTRIM(ISNULL(G.GroupId,''))))<>'SQUAD'
                 AND LOWER(LTRIM(RTRIM(ISNULL(G.UserMemberID,'')))) COLLATE DATABASE_DEFAULT=
                     LOWER(LTRIM(RTRIM(@VTEXTO11))) COLLATE DATABASE_DEFAULT
           )
            SET @VFORM_ERROR='El usuario del sistema seleccionado no es válido.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND EXISTS
           (
               SELECT 1
               FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
               WHERE LOWER(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,'')))) COLLATE DATABASE_DEFAULT=
                     LOWER(LTRIM(RTRIM(@VTEXTO11))) COLLATE DATABASE_DEFAULT
                 AND CONVERT(VARCHAR(100),C.ID)<>@VID_CONSULTOR
           )
            SET @VFORM_ERROR='El usuario del sistema ya se encuentra asignado a otro consultor.';

        IF @VFORM_ERROR=''
        BEGIN
            SET @VDIAS_NUEVOS =
                CASE WHEN NULLIF(LTRIM(RTRIM(@VTEXTO08)),'') IS NULL
                     THEN NULL ELSE CONVERT(INT,LTRIM(RTRIM(@VTEXTO08))) END;

            SET @VPERIODO=(YEAR(GETDATE())*100)+MONTH(GETDATE());

            IF NULLIF(LTRIM(RTRIM(@VID_CONSULTOR)),'') IS NULL
            BEGIN
                IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_CONSULTORES'),'ID','IsIdentity')=1
                BEGIN
                    INSERT INTO dbo.VCT_CONSULTORES
                    (
                        NOMBRES,APELLIDOS,TIPO_DOCUMENTO,NRO_DOCUMENTO,CUIT,
                        FORMACION,MOVILIDAD,DIAS_MENSUALES,EVENTUAL,
                        INGRESA_SISTEMA,ID_USUARIO_SEGURIDAD,ESTADO,
                        FECHA_ALTA,USUARIO_ALTA
                    )
                    VALUES
                    (
                        LTRIM(RTRIM(@VTEXTO01)),
                        LTRIM(RTRIM(@VTEXTO02)),
                        LTRIM(RTRIM(@VTEXTO03)),
                        LTRIM(RTRIM(@VTEXTO04)),
                        NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                        NULLIF(LTRIM(RTRIM(@VTEXTO06)),''),
                        NULLIF(UPPER(LTRIM(RTRIM(@VTEXTO07))),''),
                        @VDIAS_NUEVOS,
                        UPPER(LTRIM(RTRIM(@VTEXTO09))),
                        CASE WHEN @VFLAG02='1' THEN 1 ELSE 0 END,
                        CASE WHEN @VFLAG02='1'
                             THEN LOWER(NULLIF(LTRIM(RTRIM(@VTEXTO11)),''))
                             ELSE NULL END,
                        UPPER(LTRIM(RTRIM(@VTEXTO10))),
                        GETDATE(),
                        @IAGENTE
                    );

                    SET @VID_CONSULTOR_INT=CONVERT(INT,SCOPE_IDENTITY());

                    /* Alta: crea la linea base del historial en el periodo actual. */
                    IF OBJECT_ID('dbo.VCT_CONSULTORES_HISTORICO_DIAS','U') IS NOT NULL
                    BEGIN
                        INSERT INTO dbo.VCT_CONSULTORES_HISTORICO_DIAS
                        (
                            ID_CONSULTOR,PERIODO,DIAS_MENSUALES,
                            FECHA_ALTA,USUARIO_ALTA
                        )
                        VALUES
                        (
                            @VID_CONSULTOR_INT,@VPERIODO,@VDIAS_NUEVOS,
                            GETDATE(),@IAGENTE
                        );
                    END;
                END
                ELSE
                    SET @VFORM_ERROR='No se pudo crear el consultor: la columna ID no es autonumérica.';
            END
            ELSE
            BEGIN
                SELECT TOP 1
                    @VID_CONSULTOR_INT=ID,
                    @VDIAS_ANTERIORES=DIAS_MENSUALES
                FROM dbo.VCT_CONSULTORES WITH(NOLOCK)
                WHERE CONVERT(VARCHAR(100),ID)=@VID_CONSULTOR;

                UPDATE dbo.VCT_CONSULTORES
                   SET NOMBRES=LTRIM(RTRIM(@VTEXTO01)),
                       APELLIDOS=LTRIM(RTRIM(@VTEXTO02)),
                       TIPO_DOCUMENTO=LTRIM(RTRIM(@VTEXTO03)),
                       NRO_DOCUMENTO=LTRIM(RTRIM(@VTEXTO04)),
                       CUIT=NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                       FORMACION=NULLIF(LTRIM(RTRIM(@VTEXTO06)),''),
                       MOVILIDAD=NULLIF(UPPER(LTRIM(RTRIM(@VTEXTO07))),''),
                       DIAS_MENSUALES=@VDIAS_NUEVOS,
                       EVENTUAL=UPPER(LTRIM(RTRIM(@VTEXTO09))),
                       INGRESA_SISTEMA=CASE WHEN @VFLAG02='1' THEN 1 ELSE 0 END,
                       ID_USUARIO_SEGURIDAD=
                           CASE WHEN @VFLAG02='1'
                                THEN LOWER(NULLIF(LTRIM(RTRIM(@VTEXTO11)),''))
                                ELSE NULL END,
                       ESTADO=UPPER(LTRIM(RTRIM(@VTEXTO10))),
                       FECHA_UPD=GETDATE(),
                       USUARIO_UPD=@IAGENTE
                 WHERE CONVERT(VARCHAR(100),ID)=@VID_CONSULTOR;

                /*
                   Si cambia DIAS_MENSUALES, el historial guarda el nuevo valor
                   efectivo para el mes actual. Si se modifica mas de una vez
                   dentro del mismo mes se actualiza la misma fila, porque el
                   objetivo es conservar disponibilidad efectiva por periodo.
                */
                IF OBJECT_ID('dbo.VCT_CONSULTORES_HISTORICO_DIAS','U') IS NOT NULL
                   AND ISNULL(@VDIAS_ANTERIORES,-2147483648)
                       <> ISNULL(@VDIAS_NUEVOS,-2147483648)
                BEGIN
                    IF EXISTS
                    (
                        SELECT 1
                        FROM dbo.VCT_CONSULTORES_HISTORICO_DIAS WITH(NOLOCK)
                        WHERE ID_CONSULTOR=@VID_CONSULTOR_INT
                          AND PERIODO=@VPERIODO
                    )
                    BEGIN
                        UPDATE dbo.VCT_CONSULTORES_HISTORICO_DIAS
                           SET DIAS_MENSUALES=@VDIAS_NUEVOS,
                               FECHA_UPD=GETDATE(),
                               USUARIO_UPD=@IAGENTE
                         WHERE ID_CONSULTOR=@VID_CONSULTOR_INT
                           AND PERIODO=@VPERIODO;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO dbo.VCT_CONSULTORES_HISTORICO_DIAS
                        (
                            ID_CONSULTOR,PERIODO,DIAS_MENSUALES,
                            FECHA_ALTA,USUARIO_ALTA
                        )
                        VALUES
                        (
                            @VID_CONSULTOR_INT,@VPERIODO,@VDIAS_NUEVOS,
                            GETDATE(),@IAGENTE
                        );
                    END;
                END;
            END;

            SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR='' THEN 0 ELSE 1 END;
        END
        ELSE
            SET @VFORM_REOPEN=1;

        /*
           FLAG01 es solamente el commit del formulario. FLAG02/TEXTO11 son
           estado transitorio del modal y no deben sobrevivir a la operacion.
           Los valores necesarios para un eventual reopen ya estan en las
           variables locales @VFLAG02/@VTEXTO11.
        */
        UPDATE dbo.VCT_BUFFER
           SET FLAG01=0,
               FLAG02=0,
               TEXTO11=''
         WHERE PAR_KEY=@IPKEYJOB;
    END;

    /* ============================================================
       4. USUARIOS DEL MODELO DE SEGURIDAD
       ============================================================ */
    SELECT @HTML_USUARIOS = ISNULL((
        SELECT
            '<option value="' +
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(U.USER_ID,''),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') +
            '">' +
            REPLACE(REPLACE(REPLACE(
                ISNULL(U.USER_ID,'') + ' (' + ISNULL(U.GROUP_ID,'') + ')',
                '&','&amp;'),'<','&lt;'),'>','&gt;') +
            '</option>'
        FROM
        (
            SELECT DISTINCT
                USER_ID=LOWER(LTRIM(RTRIM(ISNULL(UserMemberID,'')))),
                GROUP_ID=LTRIM(RTRIM(ISNULL(GroupId,'')))
            FROM dbo.GroupsUserMembers WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(ISNULL(GroupId,''))))<>'SQUAD'
              AND NULLIF(LTRIM(RTRIM(ISNULL(UserMemberID,''))),'') IS NOT NULL
        ) U
        ORDER BY U.USER_ID,U.GROUP_ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* ============================================================
       5. ACCIONES DE FORMULARIO
       ============================================================ */
    SET @HTML_TOOL_ACTIONS='';
    SET @HTML_EDIT_ACTION='';

    IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='CREATE')
    BEGIN
        DECLARE @CREATE_ICON VARCHAR(50)='user-plus';

        SELECT TOP 1 @CREATE_ICON=ISNULL(NULLIF(ICON,''),'user-plus')
        FROM #ACCIONES
        WHERE ACTION_TYPE='CREATE'
        ORDER BY SORT_ORDER,ID_PRM;

        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctConsultorEditModal',
             @FORM_TITLE='Nuevo consultor',
             @FORM_SUBTITLE='Complete los datos generales del consultor.',
             @FORM_ICON=@CREATE_ICON,
             @BUTTON_TEXT='Nuevo',
             @BUTTON_ICON=@CREATE_ICON,
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Nuevo consultor',
             @OUTHTML=@HTML_TOOL_ACTIONS OUTPUT;
    END;

    IF EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT')
    BEGIN
        DECLARE @EDIT_ICON VARCHAR(50)='edit';

        SELECT TOP 1 @EDIT_ICON=ISNULL(NULLIF(ICON,''),'edit')
        FROM #ACCIONES
        WHERE ACTION_TYPE='EDIT'
        ORDER BY SORT_ORDER,ID_PRM;

        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',
             @TARGET_FORM='vctConsultorEditModal',
             @FORM_TITLE='Editar consultor',
             @FORM_SUBTITLE='Modificación de datos generales del consultor.',
             @FORM_ICON=@EDIT_ICON,
             @BUTTON_TEXT='',
             @BUTTON_ICON=@EDIT_ICON,
             @BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',
             @TOOLTIP='Editar consultor',
             @SOURCE_SELECTOR='[data-vct-row]',
             @OUTHTML=@HTML_EDIT_ACTION OUTPUT;
    END;

    /* ============================================================
       6. DATASET
       ============================================================ */
    IF OBJECT_ID('tempdb..#CONSULTORES') IS NOT NULL DROP TABLE #CONSULTORES;

    SELECT
        ID_CONSULTOR          = CONVERT(VARCHAR(100),C.ID),
        NOMBRES               = ISNULL(CONVERT(VARCHAR(300),C.NOMBRES),''),
        APELLIDOS             = ISNULL(CONVERT(VARCHAR(300),C.APELLIDOS),''),
        TIPO_DOCUMENTO        = ISNULL(CONVERT(VARCHAR(50),C.TIPO_DOCUMENTO),''),
        NRO_DOCUMENTO         = ISNULL(CONVERT(VARCHAR(50),C.NRO_DOCUMENTO),''),
        CUIT                  = ISNULL(CONVERT(VARCHAR(50),C.CUIT),''),
        FORMACION             = ISNULL(CONVERT(VARCHAR(100),C.FORMACION),''),
        MOVILIDAD             = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(50),C.MOVILIDAD),'')))),
        DIAS_MENSUALES        = CASE WHEN C.DIAS_MENSUALES IS NULL THEN '' ELSE CONVERT(VARCHAR(20),C.DIAS_MENSUALES) END,
        EVENTUAL              = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(2),C.EVENTUAL),'')))),
        EVENTUAL_DESC         = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(2),C.EVENTUAL),''))))='SI'
                                      THEN 'Sí'
                                      WHEN UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(2),C.EVENTUAL),''))))='NO'
                                      THEN 'No'
                                      ELSE '-' END,
        INGRESA_SISTEMA       = CASE WHEN ISNULL(C.INGRESA_SISTEMA,0)=1 THEN '1' ELSE '0' END,
        SISTEMA_DESC          = CASE WHEN ISNULL(C.INGRESA_SISTEMA,0)=1 THEN 'Sí' ELSE 'No' END,
        ID_USUARIO_SEGURIDAD  = ISNULL(CONVERT(VARCHAR(100),C.ID_USUARIO_SEGURIDAD),''),
        ESTADO_CODE           = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),C.ESTADO),'INACTIVO')))),
        ESTADO_DESC           = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),C.ESTADO),''))))='ACTIVO'
                                      THEN 'Activo' ELSE 'Inactivo' END
    INTO #CONSULTORES
    FROM dbo.VCT_CONSULTORES C WITH(NOLOCK);

    SELECT @TOTAL=COUNT(*) FROM #CONSULTORES;
    SELECT @TOTAL_ACTIVOS=COUNT(*) FROM #CONSULTORES WHERE ESTADO_CODE='ACTIVO';
    SELECT @TOTAL_EVENTUALES=COUNT(*) FROM #CONSULTORES WHERE EVENTUAL='SI';
    SELECT @TOTAL_SISTEMA=COUNT(*) FROM #CONSULTORES WHERE INGRESA_SISTEMA='1';

    /* ============================================================
       7. FILAS
       ============================================================ */
    SELECT @HTML_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row ' +
            'data-vct-key="' + ISNULL(C.ID_CONSULTOR,'') + '" ' +
            'data-vct-search="' +
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(C.APELLIDOS,'') + ' ' +
                    ISNULL(C.NOMBRES,'') + ' ' +
                    ISNULL(C.TIPO_DOCUMENTO,'') + ' ' +
                    ISNULL(C.NRO_DOCUMENTO,'') + ' ' +
                    ISNULL(C.CUIT,'') + ' ' +
                    ISNULL(C.FORMACION,'') + ' ' +
                    ISNULL(C.MOVILIDAD,'') + ' ' +
                    ISNULL(C.ID_USUARIO_SEGURIDAD,''),
                    '&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-filter-estado="' + ISNULL(C.ESTADO_CODE,'') + '" ' +
            'data-vct-filter-eventual="' + ISNULL(C.EVENTUAL,'') + '" ' +
            'data-vct-filter-sistema="' + ISNULL(C.INGRESA_SISTEMA,'0') + '" ' +
            'data-vct-id="' + ISNULL(C.ID_CONSULTOR,'') + '" ' +
            'data-vct-nombres="' + REPLACE(REPLACE(ISNULL(C.NOMBRES,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-apellidos="' + REPLACE(REPLACE(ISNULL(C.APELLIDOS,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-tipo-documento="' + REPLACE(REPLACE(ISNULL(C.TIPO_DOCUMENTO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-nro-documento="' + REPLACE(REPLACE(ISNULL(C.NRO_DOCUMENTO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-cuit="' + REPLACE(REPLACE(ISNULL(C.CUIT,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-formacion="' + REPLACE(REPLACE(ISNULL(C.FORMACION,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-movilidad="' + REPLACE(REPLACE(ISNULL(C.MOVILIDAD,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-dias-mensuales="' + ISNULL(C.DIAS_MENSUALES,'') + '" ' +
            'data-vct-eventual="' + ISNULL(C.EVENTUAL,'') + '" ' +
            'data-vct-estado="' + ISNULL(C.ESTADO_CODE,'') + '" ' +
            'data-vct-ingresa-sistema="' + ISNULL(C.INGRESA_SISTEMA,'0') + '" ' +
            'data-vct-usuario-seguridad="' + REPLACE(REPLACE(ISNULL(C.ID_USUARIO_SEGURIDAD,''),'"','&quot;'),'''','&#39;') + '">' +

            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL((
                    SELECT TOP 1 dbo.VCT_MAIN_RENDER_ACTION
                    (
                        A.ACTION_ID,A.TITLE,A.ICON,A.STORAGE_KEY,
                        A.TARGET_TAB,A.TARGET_GUID,C.ID_CONSULTOR,
                        'vct-grid-icon-btn vct-grid-icon-btn-view',''
                    )
                    FROM #ACCIONES A
                    WHERE A.ACTION_TYPE='VIEW'
                    ORDER BY A.SORT_ORDER,A.ID_PRM
                ),'') +
            '</td>' +

            '<td data-label="Consultor" data-vct-sort-value="' +
                REPLACE(REPLACE(REPLACE(ISNULL(C.APELLIDOS,'') + ' ' + ISNULL(C.NOMBRES,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '">' +
                '<strong>' +
                REPLACE(REPLACE(REPLACE(ISNULL(C.APELLIDOS,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                CASE WHEN C.APELLIDOS<>'' AND C.NOMBRES<>'' THEN ', ' ELSE '' END +
                REPLACE(REPLACE(REPLACE(ISNULL(C.NOMBRES,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                '</strong>' +
            '</td>' +

            '<td class="vct-text-center" data-label="Documento">' +
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(C.TIPO_DOCUMENTO,'') + ' ' + ISNULL(C.NRO_DOCUMENTO,''))),'&','&amp;'),'<','&lt;'),'>','&gt;') +
            '</td>' +

            '<td class="vct-text-center" data-label="Días/mes">' +
                CASE WHEN C.DIAS_MENSUALES='' THEN '-' ELSE C.DIAS_MENSUALES END +
            '</td>' +

            '<td class="vct-text-center" data-label="Eventual">' +
                CASE WHEN C.EVENTUAL='SI'
                     THEN '<span class="vct-badge vct-badge-warning">Sí</span>'
                     WHEN C.EVENTUAL='NO'
                     THEN '<span class="vct-badge vct-badge-neutral">No</span>'
                     ELSE '<span class="vct-badge vct-badge-neutral">-</span>' END +
            '</td>' +

            '<td class="vct-text-center" data-label="Estado">' +
                '<span class="vct-badge" data-vct-badge="' + ISNULL(C.ESTADO_CODE,'') + '">' + ISNULL(C.ESTADO_DESC,'') + '</span>' +
            '</td>' +

            '<td class="vct-text-center" data-label="Sistema">' +
                CASE WHEN C.INGRESA_SISTEMA='1'
                     THEN '<span class="vct-badge vct-badge-info">Sí</span>'
                     ELSE '<span class="vct-badge vct-badge-neutral">No</span>' END +
            '</td>' +

            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL(@HTML_EDIT_ACTION,'') +
            '</td>' +
            '</tr>'
        FROM #CONSULTORES C
        ORDER BY C.APELLIDOS,C.NOMBRES,C.ID_CONSULTOR
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* ============================================================
       8. FORMULARIO MODAL
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
    (1,'TEXTO01','Nombres','TEXT',6,1,300,'Ingrese nombres',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'nombres'),
    (2,'TEXTO02','Apellidos','TEXT',6,1,300,'Ingrese apellidos',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'apellidos'),
    (3,'TEXTO03','Tipo documento','SELECT',4,1,NULL,NULL,'TIPO_DOCUMENTO',CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO03 ELSE NULL END,0,0,NULL,'tipo-documento'),
    (4,'TEXTO04','Número documento','TEXT',4,1,50,'Número',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO04 ELSE NULL END,0,0,NULL,'nro-documento'),
    (5,'TEXTO05','CUIT','TEXT',4,0,50,'CUIT',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO05 ELSE NULL END,0,0,NULL,'cuit'),
    (6,'TEXTO06','Formación','TEXT',6,0,100,'Formación',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO06 ELSE NULL END,0,0,NULL,'formacion'),
    (7,'TEXTO07','Movilidad','TEXT',6,0,50,'Seleccione movilidad',NULL,CASE WHEN @VFORM_REOPEN=1 THEN UPPER(LTRIM(RTRIM(@VTEXTO07))) ELSE NULL END,0,0,NULL,'movilidad'),
    (8,'TEXTO08','Días mensuales','NUMBER',4,0,NULL,'0',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO08 ELSE NULL END,0,0,'Cantidad estimada de días mensuales asignables al consultor.','dias-mensuales'),
    (9,'TEXTO09','Eventual','TEXT',4,1,2,'Seleccione eventual',NULL,CASE WHEN @VFORM_REOPEN=1 THEN UPPER(LTRIM(RTRIM(@VTEXTO09))) ELSE 'NO' END,0,0,NULL,'eventual'),
    (10,'TEXTO10','Estado','TEXT',4,1,20,'Seleccione estado',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO10 ELSE 'ACTIVO' END,0,0,NULL,'estado'),
    (11,'FLAG02','Ingresa al sistema','TOGGLE',6,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VFLAG02 ELSE '0' END,0,0,'Habilita la asociación con un usuario del modelo de seguridad.','ingresa-sistema'),
    (12,'TEXTO11','Usuario del sistema','TEXT',6,0,100,'Seleccione un usuario',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO11 ELSE NULL END,0,0,NULL,'usuario-seguridad'),
    (13,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VID_CONSULTOR ELSE NULL END,0,1,NULL,'id'),
    (14,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctConsultorEditModal',
         @TITLE='Editar consultor',
         @SUBTITLE='Modificación de datos generales del consultor.',
         @ICON='users',
         @LAYOUT='MODAL',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@VFORM_ERROR,
         @OPEN_ON_RENDER=@VFORM_REOPEN,
         @OUTHTML=@HTML_MODAL OUTPUT;

    SET @HTML_MODAL = ISNULL(@HTML_MODAL,'') +
        '<template data-vct-field-options data-vct-target="vctConsultorEditModal" data-vct-field="TEXTO07" data-vct-placeholder="Seleccione movilidad">' +
            '<option value="SI">Sí</option>' +
            '<option value="NO">No</option>' +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctConsultorEditModal" data-vct-field="TEXTO09" data-vct-placeholder="Seleccione eventual">' +
            '<option value="SI">Sí</option>' +
            '<option value="NO">No</option>' +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctConsultorEditModal" data-vct-field="TEXTO10" data-vct-placeholder="Seleccione estado">' +
            '<option value="ACTIVO">Activo</option>' +
            '<option value="INACTIVO">Inactivo</option>' +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctConsultorEditModal" data-vct-field="TEXTO11" data-vct-placeholder="Seleccione un usuario">' +
            ISNULL(@HTML_USUARIOS,'') +
        '</template>';

    /* ============================================================
       9. HTML PRINCIPAL
       ------------------------------------------------------------
       Grilla con el motor nuevo (data-vct-dg): el motor arma buscador,
       Excel/PDF, paginado, orden y "registros por pagina". El SP solo
       declara: filtros (slot filters), boton Nuevo (slot actions) y la tabla.
       ============================================================ */
    SET @HTML = '
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4">
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">

    <section class="vct-soft-kpi-grid" aria-label="Indicadores de consultores">
        <article class="vct-soft-kpi is-blue">
            <span class="vct-soft-kpi-icon" data-vct-icon="users"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Total Consultores</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL) + '</strong>
                <span class="vct-soft-kpi-help">consultores registrados</span>
            </div>
        </article>

        <article class="vct-soft-kpi is-green">
            <span class="vct-soft-kpi-icon" data-vct-icon="user-check"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Activos</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_ACTIVOS) + '</strong>
                <span class="vct-soft-kpi-help">estado activo</span>
            </div>
        </article>

        <article class="vct-soft-kpi is-orange">
            <span class="vct-soft-kpi-icon" data-vct-icon="calendar"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Eventuales</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_EVENTUALES) + '</strong>
                <span class="vct-soft-kpi-help">modalidad eventual</span>
            </div>
        </article>

        <article class="vct-soft-kpi is-purple">
            <span class="vct-soft-kpi-icon" data-vct-icon="lock"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Acceso al sistema</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_SISTEMA) + '</strong>
                <span class="vct-soft-kpi-help">usuarios habilitados</span>
            </div>
        </article>
    </section>

    <section class="vct-card vct-grid-card">
        <div class="vct-card-body">
            <div data-vct-dg
                 data-vct-dg-id="consultores"
                 data-vct-dg-title="Consultores"
                 data-vct-dg-subtitle="Gestión y consulta de consultores del sistema."
                 data-vct-dg-unit="consultor(es)"
                 data-vct-dg-page-size="10"
                 data-vct-dg-search-placeholder="Buscar consultor, documento, CUIT, formación..."
                 data-vct-dg-density="compact"
                 data-vct-dg-layout="fixed">

                <div data-vct-dg-slot="filters">
                    <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Estado">
                        <option value="">Todos los estados</option>
                        <option value="ACTIVO">Activo</option>
                        <option value="INACTIVO">Inactivo</option>
                    </select>

                    <select class="vct-select vct-select-sm" data-vct-dg-filter="eventual" aria-label="Eventual">
                        <option value="">Eventual</option>
                        <option value="SI">Sí</option>
                        <option value="NO">No</option>
                    </select>

                    <select class="vct-select vct-select-sm" data-vct-dg-filter="sistema" aria-label="Acceso al sistema">
                        <option value="">Acceso al sistema</option>
                        <option value="1">Con acceso</option>
                        <option value="0">Sin acceso</option>
                    </select>
                </div>

                <div data-vct-dg-slot="actions">' + ISNULL(@HTML_TOOL_ACTIONS,'') + '</div>

                <table>
                    <thead>
                        <tr>
                            <th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>

                            <th data-vct-sort="consultor" data-vct-sortable="true">
                                <span>Consultor</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="16%" data-vct-sort="documento" data-vct-sortable="true">
                                <span>Documento</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="10%" data-vct-sort="dias-mensuales" data-vct-sortable="true">
                                <span>Días/mes</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="10%" data-vct-sort="eventual" data-vct-sortable="true">
                                <span>Eventual</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="11%" data-vct-sort="estado" data-vct-sortable="true">
                                <span>Estado</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="10%" data-vct-sort="sistema" data-vct-sortable="true">
                                <span>Sistema</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>
                        </tr>
                    </thead>

                    <tbody>' + ISNULL(@HTML_ROWS,'') + '</tbody>
                </table>
            </div>
        </div>
    </section>

    <input type="hidden" name="SP.PAGE_NUMBER" id="PAGE_NUMBER"  value="1">
    <input type="hidden" name="SP.PAGE_SIZE"   id="PAGE_SIZE"    value="10">
    <input type="hidden" name="SP.SEARCH_TEXT" id="SEARCH_TEXT"  value="">
    <input type="hidden" name="SP.SORT_FIELD"  id="SORT_FIELD"   value="">
    <input type="hidden" name="SP.SORT_DIR"    id="SORT_DIR"     value="">
</div>
<script src="../js/vct-export.js?v=1"></script>
<script src="../js/vct-datagrid.js?v=3"></script>';

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + ISNULL(@HTML,'');
    SET @OUTPARAM2 = ISNULL(@HTML_MODAL,'');
    SET @OUTPARAM3 = '';
END
GO
