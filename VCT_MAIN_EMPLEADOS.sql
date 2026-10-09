USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[VCT_MAIN_EMPLEADOS]
        Migrado al motor de tablas nuevo (vct-datagrid.js / vct-datagrid.css / vct-export.js).
        Sin cambios de logica: permisos, guardado, validaciones, formulario y renderers de
        acciones (VIEW / EDIT / CREATE) quedan IGUAL. Solo cambia el markup de la grilla. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[VCT_MAIN_EMPLEADOS]
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

    DECLARE @MODULE_CODE VARCHAR(50) = 'EMPLEADOS';

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
        @TOTAL_INACTIVOS     INT = 0,
        @TOTAL_SISTEMA       INT = 0,
        @VID_EMPLEADO        VARCHAR(100) = '',
        @VTEXTO01            VARCHAR(500) = '',
        @VTEXTO02            VARCHAR(500) = '',
        @VTEXTO03            VARCHAR(100) = '',
        @VTEXTO04            VARCHAR(100) = '',
        @VTEXTO05            VARCHAR(100) = '',
        @VTEXTO06            VARCHAR(100) = '',
        @VTEXTO07            VARCHAR(200) = '',
        @VTEXTO08            VARCHAR(200) = '',
        @VTEXTO09            VARCHAR(200) = '',
        @VTEXTO10            VARCHAR(100) = '',
        @VTEXTO11            VARCHAR(200) = '',
        @VTEXTO12            VARCHAR(50)  = '',
        @VFECHA01            DATETIME = NULL,
        @VFECHA02            DATETIME = NULL,
        @VFLAG01             VARCHAR(10) = '',
        @VFLAG02             VARCHAR(10) = '0',
        @VFORM_ERROR         VARCHAR(1000) = '',
        @VFORM_REOPEN        BIT = 0;

    /* 1. SHELL GENERAL: Sidebar + Header */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Empleados',
             @SUBTITLE           = 'Gestión y consulta de empleados del sistema.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
        SET @RESULTADO_SHELL = 'ERROR';
    END CATCH;

    /* 2. ACCIONES: modulo EMPLEADOS, sin ActionID ni SidebarID hardcodeados */
    IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;

    SELECT *
    INTO #ACCIONES
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);

    SELECT TOP 1 @SIDEBAR_ID = ISNULL(SIDEBAR_ID,0)
    FROM #ACCIONES
    WHERE ISNULL(SIDEBAR_ID,0) <> 0
    ORDER BY SORT_ORDER,ID_PRM;

    IF NOT EXISTS (SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE = 'VIEW')
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + '
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="' + CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0)) + '"
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para visualizar Empleados.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;

    /* 3. POSTBACK ALTA / EDICION */
    SELECT TOP 1
        @VID_EMPLEADO = ISNULL(CONVERT(VARCHAR(100),IDSELEC01),''),
        @VTEXTO01     = ISNULL(CONVERT(VARCHAR(500),TEXTO01),''),
        @VTEXTO02     = ISNULL(CONVERT(VARCHAR(500),TEXTO02),''),
        @VTEXTO03     = ISNULL(CONVERT(VARCHAR(100),TEXTO03),''),
        @VTEXTO04     = ISNULL(CONVERT(VARCHAR(100),TEXTO04),''),
        @VTEXTO05     = ISNULL(CONVERT(VARCHAR(100),TEXTO05),''),
        @VTEXTO06     = ISNULL(CONVERT(VARCHAR(100),TEXTO06),''),
        @VTEXTO07     = ISNULL(CONVERT(VARCHAR(200),TEXTO07),''),
        @VTEXTO08     = ISNULL(CONVERT(VARCHAR(200),TEXTO08),''),
        @VTEXTO09     = ISNULL(CONVERT(VARCHAR(200),TEXTO09),''),
        @VTEXTO10     = ISNULL(CONVERT(VARCHAR(100),TEXTO10),''),
        @VTEXTO11     = ISNULL(CONVERT(VARCHAR(200),TEXTO11),''),
        @VTEXTO12     = ISNULL(CONVERT(VARCHAR(50),TEXTO12),''),
        @VFECHA01     = FECHA01,
        @VFECHA02     = FECHA02,
        @VFLAG01      = ISNULL(CONVERT(VARCHAR(10),FLAG01),''),
        @VFLAG02      = ISNULL(CONVERT(VARCHAR(10),FLAG02),'0')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;

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

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VID_EMPLEADO)),'') IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
               WHERE CONVERT(VARCHAR(100),E.ID)=@VID_EMPLEADO
           )
            SET @VFORM_ERROR='El empleado seleccionado no existe.';

        IF @VFORM_ERROR=''
           AND UPPER(LTRIM(RTRIM(ISNULL(@VTEXTO12,'')))) NOT IN ('ACTIVO','INACTIVO')
            SET @VFORM_ERROR='El estado seleccionado no es válido.';

        IF @VFORM_ERROR=''
           AND @VFECHA01 IS NOT NULL
           AND @VFECHA02 IS NOT NULL
           AND @VFECHA02 < @VFECHA01
            SET @VFORM_ERROR='La fecha de egreso no puede ser anterior a la fecha de ingreso.';

        IF @VFORM_ERROR='' AND EXISTS
        (
            SELECT 1
            FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(ISNULL(E.TIPO_DOCUMENTO,''))))
                    COLLATE DATABASE_DEFAULT =
                  UPPER(LTRIM(RTRIM(@VTEXTO03))) COLLATE DATABASE_DEFAULT
              AND LTRIM(RTRIM(ISNULL(E.NRO_DOCUMENTO,'')))
                    COLLATE DATABASE_DEFAULT =
                  LTRIM(RTRIM(@VTEXTO04)) COLLATE DATABASE_DEFAULT
              AND CONVERT(VARCHAR(100),E.ID)<>@VID_EMPLEADO
        )
            SET @VFORM_ERROR='Ya existe otro empleado con el mismo tipo y número de documento.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO05)),'') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
               WHERE LTRIM(RTRIM(ISNULL(E.CUIT,'')))
                       COLLATE DATABASE_DEFAULT =
                     LTRIM(RTRIM(@VTEXTO05)) COLLATE DATABASE_DEFAULT
                 AND CONVERT(VARCHAR(100),E.ID)<>@VID_EMPLEADO
           )
            SET @VFORM_ERROR='Ya existe otro empleado con el CUIT ingresado.';

        IF @VFORM_ERROR=''
           AND NULLIF(LTRIM(RTRIM(@VTEXTO06)),'') IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
               WHERE UPPER(LTRIM(RTRIM(ISNULL(E.LEGAJO,''))))
                       COLLATE DATABASE_DEFAULT =
                     UPPER(LTRIM(RTRIM(@VTEXTO06))) COLLATE DATABASE_DEFAULT
                 AND CONVERT(VARCHAR(100),E.ID)<>@VID_EMPLEADO
           )
            SET @VFORM_ERROR='Ya existe otro empleado con el legajo ingresado.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND NULLIF(LTRIM(RTRIM(@VTEXTO11)),'') IS NULL
            SET @VFORM_ERROR='Seleccione el usuario del sistema.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.GroupsUserMembers G WITH(NOLOCK)
               WHERE UPPER(LTRIM(RTRIM(ISNULL(G.GroupId,'')))) <> 'SQUAD'
                 AND LOWER(LTRIM(RTRIM(ISNULL(G.UserMemberID,''))))
                        COLLATE DATABASE_DEFAULT =
                     LOWER(LTRIM(RTRIM(@VTEXTO11))) COLLATE DATABASE_DEFAULT
           )
            SET @VFORM_ERROR='El usuario del sistema seleccionado no es válido.';

        IF @VFORM_ERROR='' AND @VFLAG02='1'
           AND EXISTS
           (
               SELECT 1
               FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
               WHERE LOWER(LTRIM(RTRIM(ISNULL(E.ID_USUARIO_SEGURIDAD,''))))
                       COLLATE DATABASE_DEFAULT =
                     LOWER(LTRIM(RTRIM(@VTEXTO11))) COLLATE DATABASE_DEFAULT
                 AND CONVERT(VARCHAR(100),E.ID)<>@VID_EMPLEADO
           )
            SET @VFORM_ERROR='El usuario del sistema ya se encuentra asignado a otro empleado.';

        IF @VFORM_ERROR=''
        BEGIN
            IF NULLIF(LTRIM(RTRIM(@VID_EMPLEADO)),'') IS NULL
            BEGIN
                IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_EMPLEADOS'),'ID','IsIdentity')=1
                BEGIN
                    INSERT INTO dbo.VCT_EMPLEADOS
                    (
                        LEGAJO,NOMBRES,APELLIDOS,TIPO_DOCUMENTO,NRO_DOCUMENTO,
                        CUIT,CARGO,AREA,FORMACION,MOVILIDAD,
                        FECHA_INGRESO,FECHA_EGRESO,
                        INGRESA_SISTEMA,ID_USUARIO_SEGURIDAD,ESTADO,
                        FECHA_ALTA,USUARIO_ALTA
                    )
                    VALUES
                    (
                        NULLIF(LTRIM(RTRIM(@VTEXTO06)),''),
                        LTRIM(RTRIM(@VTEXTO01)),
                        LTRIM(RTRIM(@VTEXTO02)),
                        LTRIM(RTRIM(@VTEXTO03)),
                        LTRIM(RTRIM(@VTEXTO04)),
                        NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                        NULLIF(LTRIM(RTRIM(@VTEXTO07)),''),
                        NULLIF(LTRIM(RTRIM(@VTEXTO08)),''),
                        NULLIF(LTRIM(RTRIM(@VTEXTO09)),''),
                        NULLIF(LTRIM(RTRIM(@VTEXTO10)),''),
                        @VFECHA01,
                        @VFECHA02,
                        CASE WHEN @VFLAG02='1' THEN 1 ELSE 0 END,
                        CASE WHEN @VFLAG02='1'
                             THEN LOWER(NULLIF(LTRIM(RTRIM(@VTEXTO11)),''))
                             ELSE NULL END,
                        UPPER(LTRIM(RTRIM(@VTEXTO12))),
                        GETDATE(),
                        @IAGENTE
                    );
                END
                ELSE
                    SET @VFORM_ERROR='No se pudo crear el empleado: la columna ID no es autonumérica.';
            END
            ELSE
            BEGIN
                UPDATE dbo.VCT_EMPLEADOS
                   SET LEGAJO=NULLIF(LTRIM(RTRIM(@VTEXTO06)),''),
                       NOMBRES=LTRIM(RTRIM(@VTEXTO01)),
                       APELLIDOS=LTRIM(RTRIM(@VTEXTO02)),
                       TIPO_DOCUMENTO=LTRIM(RTRIM(@VTEXTO03)),
                       NRO_DOCUMENTO=LTRIM(RTRIM(@VTEXTO04)),
                       CUIT=NULLIF(LTRIM(RTRIM(@VTEXTO05)),''),
                       CARGO=NULLIF(LTRIM(RTRIM(@VTEXTO07)),''),
                       AREA=NULLIF(LTRIM(RTRIM(@VTEXTO08)),''),
                       FORMACION=NULLIF(LTRIM(RTRIM(@VTEXTO09)),''),
                       MOVILIDAD=NULLIF(LTRIM(RTRIM(@VTEXTO10)),''),
                       FECHA_INGRESO=@VFECHA01,
                       FECHA_EGRESO=@VFECHA02,
                       INGRESA_SISTEMA=CASE WHEN @VFLAG02='1' THEN 1 ELSE 0 END,
                       ID_USUARIO_SEGURIDAD=
                           CASE WHEN @VFLAG02='1'
                                THEN LOWER(NULLIF(LTRIM(RTRIM(@VTEXTO11)),''))
                                ELSE NULL END,
                       ESTADO=UPPER(LTRIM(RTRIM(@VTEXTO12))),
                       FECHA_UPD=GETDATE(),
                       USUARIO_UPD=@IAGENTE
                 WHERE CONVERT(VARCHAR(100),ID)=@VID_EMPLEADO;
            END;

            SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR='' THEN 0 ELSE 1 END;
        END
        ELSE
            SET @VFORM_REOPEN=1;

        UPDATE dbo.VCT_BUFFER
           SET FLAG01=0
         WHERE PAR_KEY=@IPKEYJOB;
    END;

    /* 4. USUARIOS DEL MODELO DE SEGURIDAD */
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
                USER_ID  = LOWER(LTRIM(RTRIM(ISNULL(UserMemberID,'')))),
                GROUP_ID = LTRIM(RTRIM(ISNULL(GroupId,'')))
            FROM dbo.GroupsUserMembers WITH(NOLOCK)
            WHERE UPPER(LTRIM(RTRIM(ISNULL(GroupId,'')))) <> 'SQUAD'
              AND NULLIF(LTRIM(RTRIM(ISNULL(UserMemberID,''))),'') IS NOT NULL
        ) U
        ORDER BY U.USER_ID,U.GROUP_ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* 5. ACCIONES DE FORMULARIO */
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
             @TARGET_FORM='vctEmpleadoEditModal',
             @FORM_TITLE='Nuevo empleado',
             @FORM_SUBTITLE='Complete los datos generales del empleado.',
             @FORM_ICON=@CREATE_ICON,
             @BUTTON_TEXT='Nuevo',
             @BUTTON_ICON=@CREATE_ICON,
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Nuevo empleado',
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
             @TARGET_FORM='vctEmpleadoEditModal',
             @FORM_TITLE='Editar empleado',
             @FORM_SUBTITLE='Modificación de datos generales del empleado.',
             @FORM_ICON=@EDIT_ICON,
             @BUTTON_TEXT='',
             @BUTTON_ICON=@EDIT_ICON,
             @BUTTON_CLASS='vct-grid-icon-btn vct-grid-icon-btn-edit',
             @TOOLTIP='Editar empleado',
             @SOURCE_SELECTOR='[data-vct-row]',
             @OUTHTML=@HTML_EDIT_ACTION OUTPUT;
    END;

    /* 6. DATASET */
    IF OBJECT_ID('tempdb..#EMPLEADOS') IS NOT NULL DROP TABLE #EMPLEADOS;

    SELECT
        ID_EMPLEADO           = CONVERT(VARCHAR(100),E.ID),
        LEGAJO                = ISNULL(CONVERT(VARCHAR(50),E.LEGAJO),''),
        NOMBRES               = ISNULL(CONVERT(VARCHAR(150),E.NOMBRES),''),
        APELLIDOS             = ISNULL(CONVERT(VARCHAR(150),E.APELLIDOS),''),
        TIPO_DOCUMENTO        = ISNULL(CONVERT(VARCHAR(50),E.TIPO_DOCUMENTO),''),
        NRO_DOCUMENTO         = ISNULL(CONVERT(VARCHAR(50),E.NRO_DOCUMENTO),''),
        CUIT                  = ISNULL(CONVERT(VARCHAR(20),E.CUIT),''),
        CARGO                 = ISNULL(CONVERT(VARCHAR(100),E.CARGO),''),
        AREA                  = ISNULL(CONVERT(VARCHAR(100),E.AREA),''),
        FORMACION             = ISNULL(CONVERT(VARCHAR(100),E.FORMACION),''),
        MOVILIDAD             = ISNULL(CONVERT(VARCHAR(50),E.MOVILIDAD),''),
        FECHA_INGRESO_FORM    = CASE WHEN E.FECHA_INGRESO IS NULL THEN '' ELSE CONVERT(VARCHAR(10),E.FECHA_INGRESO,23) END,
        FECHA_EGRESO_FORM     = CASE WHEN E.FECHA_EGRESO IS NULL THEN '' ELSE CONVERT(VARCHAR(10),E.FECHA_EGRESO,23) END,
        INGRESA_SISTEMA       = CASE WHEN ISNULL(E.INGRESA_SISTEMA,0)=1 THEN '1' ELSE '0' END,
        SISTEMA_DESC          = CASE WHEN ISNULL(E.INGRESA_SISTEMA,0)=1 THEN 'Sí' ELSE 'No' END,
        ID_USUARIO_SEGURIDAD  = ISNULL(CONVERT(VARCHAR(100),E.ID_USUARIO_SEGURIDAD),''),
        ESTADO_CODE           = UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),E.ESTADO),'INACTIVO')))),
        ESTADO_DESC           = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),E.ESTADO),''))))='ACTIVO'
                                     THEN 'Activo' ELSE 'Inactivo' END
    INTO #EMPLEADOS
    FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK);

    SELECT @TOTAL=COUNT(*) FROM #EMPLEADOS;
    SELECT @TOTAL_ACTIVOS=COUNT(*) FROM #EMPLEADOS WHERE ESTADO_CODE='ACTIVO';
    SELECT @TOTAL_INACTIVOS=COUNT(*) FROM #EMPLEADOS WHERE ESTADO_CODE='INACTIVO';
    SELECT @TOTAL_SISTEMA=COUNT(*) FROM #EMPLEADOS WHERE INGRESA_SISTEMA='1';

    /* 7. FILAS */
    SELECT @HTML_ROWS = ISNULL((
        SELECT
            '<tr data-vct-row ' +
            'data-vct-key="' + ISNULL(E.ID_EMPLEADO,'') + '" ' +
            'data-vct-search="' +
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(E.LEGAJO,'') + ' ' +
                    ISNULL(E.APELLIDOS,'') + ' ' +
                    ISNULL(E.NOMBRES,'') + ' ' +
                    ISNULL(E.TIPO_DOCUMENTO,'') + ' ' +
                    ISNULL(E.NRO_DOCUMENTO,'') + ' ' +
                    ISNULL(E.CUIT,'') + ' ' +
                    ISNULL(E.CARGO,'') + ' ' +
                    ISNULL(E.AREA,'') + ' ' +
                    ISNULL(E.ID_USUARIO_SEGURIDAD,''),
                    '&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;'),'''','&#39;') + '" ' +
            'data-vct-filter-estado="' + ISNULL(E.ESTADO_CODE,'') + '" ' +
            'data-vct-filter-sistema="' + ISNULL(E.INGRESA_SISTEMA,'0') + '" ' +
            'data-vct-id="' + ISNULL(E.ID_EMPLEADO,'') + '" ' +
            'data-vct-legajo="' + REPLACE(REPLACE(ISNULL(E.LEGAJO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-nombres="' + REPLACE(REPLACE(ISNULL(E.NOMBRES,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-apellidos="' + REPLACE(REPLACE(ISNULL(E.APELLIDOS,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-tipo-documento="' + REPLACE(REPLACE(ISNULL(E.TIPO_DOCUMENTO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-nro-documento="' + REPLACE(REPLACE(ISNULL(E.NRO_DOCUMENTO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-cuit="' + REPLACE(REPLACE(ISNULL(E.CUIT,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-cargo="' + REPLACE(REPLACE(ISNULL(E.CARGO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-area="' + REPLACE(REPLACE(ISNULL(E.AREA,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-formacion="' + REPLACE(REPLACE(ISNULL(E.FORMACION,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-movilidad="' + REPLACE(REPLACE(ISNULL(E.MOVILIDAD,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-fecha-ingreso="' + ISNULL(E.FECHA_INGRESO_FORM,'') + '" ' +
            'data-vct-fecha-egreso="' + ISNULL(E.FECHA_EGRESO_FORM,'') + '" ' +
            'data-vct-ingresa-sistema="' + ISNULL(E.INGRESA_SISTEMA,'0') + '" ' +
            'data-vct-usuario-seguridad="' + REPLACE(REPLACE(ISNULL(E.ID_USUARIO_SEGURIDAD,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-estado="' + ISNULL(E.ESTADO_CODE,'') + '">' +

            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL((
                    SELECT TOP 1 dbo.VCT_MAIN_RENDER_ACTION
                    (
                        A.ACTION_ID,A.TITLE,A.ICON,A.STORAGE_KEY,
                        A.TARGET_TAB,A.TARGET_GUID,E.ID_EMPLEADO,
                        'vct-grid-icon-btn vct-grid-icon-btn-view',''
                    )
                    FROM #ACCIONES A
                    WHERE A.ACTION_TYPE='VIEW'
                    ORDER BY A.SORT_ORDER,A.ID_PRM
                ),'') +
            '</td>' +

            '<td data-label="Legajo">' +
                CASE WHEN E.LEGAJO='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(E.LEGAJO,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +

            '<td data-label="Empleado" data-vct-sort-value="' +
                REPLACE(REPLACE(REPLACE(ISNULL(E.APELLIDOS,'') + ' ' + ISNULL(E.NOMBRES,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '">' +
                '<strong>' +
                REPLACE(REPLACE(REPLACE(ISNULL(E.APELLIDOS,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                CASE WHEN E.APELLIDOS<>'' AND E.NOMBRES<>'' THEN ', ' ELSE '' END +
                REPLACE(REPLACE(REPLACE(ISNULL(E.NOMBRES,''),'&','&amp;'),'<','&lt;'),'>','&gt;') +
                '</strong>' +
            '</td>' +

            '<td class="vct-text-center" data-label="Documento">' +
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.TIPO_DOCUMENTO,'') + ' ' + ISNULL(E.NRO_DOCUMENTO,''))),'&','&amp;'),'<','&lt;'),'>','&gt;') +
            '</td>' +

            '<td data-label="Cargo">' +
                CASE WHEN E.CARGO='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(E.CARGO,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +

            '<td data-label="Área">' +
                CASE WHEN E.AREA='' THEN '-' ELSE REPLACE(REPLACE(REPLACE(E.AREA,'&','&amp;'),'<','&lt;'),'>','&gt;') END +
            '</td>' +

            '<td class="vct-text-center" data-label="Estado">' +
                '<span class="vct-badge" data-vct-badge="' + ISNULL(E.ESTADO_CODE,'') + '">' + ISNULL(E.ESTADO_DESC,'') + '</span>' +
            '</td>' +

            '<td class="vct-text-center" data-label="Sistema">' +
                CASE WHEN E.INGRESA_SISTEMA='1'
                     THEN '<span class="vct-badge vct-badge-info">Sí</span>'
                     ELSE '<span class="vct-badge vct-badge-neutral">No</span>' END +
            '</td>' +

            '<td class="vct-table-action-cell vct-table-action-left" data-label="">' +
                ISNULL(@HTML_EDIT_ACTION,'') +
            '</td>' +
            '</tr>'
        FROM #EMPLEADOS E
        ORDER BY E.APELLIDOS,E.NOMBRES,E.ID_EMPLEADO
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');

    /* 8. FORMULARIO */
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
    (1,'TEXTO01','Nombres','TEXT',6,1,150,'Ingrese nombres',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO01 ELSE NULL END,0,0,NULL,'nombres'),
    (2,'TEXTO02','Apellidos','TEXT',6,1,150,'Ingrese apellidos',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO02 ELSE NULL END,0,0,NULL,'apellidos'),
    (3,'TEXTO03','Tipo documento','TEXT',4,1,50,'Tipo',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO03 ELSE NULL END,0,0,NULL,'tipo-documento'),
    (4,'TEXTO04','Número documento','TEXT',4,1,50,'Número',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO04 ELSE NULL END,0,0,NULL,'nro-documento'),
    (5,'TEXTO05','CUIT','TEXT',4,0,20,'CUIT',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO05 ELSE NULL END,0,0,NULL,'cuit'),
    (6,'TEXTO06','Legajo','TEXT',4,0,50,'Legajo',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO06 ELSE NULL END,0,0,NULL,'legajo'),
    (7,'TEXTO07','Cargo','TEXT',4,0,100,'Cargo',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO07 ELSE NULL END,0,0,NULL,'cargo'),
    (8,'TEXTO08','Área','TEXT',4,0,100,'Área',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO08 ELSE NULL END,0,0,NULL,'area'),
    (9,'TEXTO09','Formación','TEXT',6,0,100,'Formación',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO09 ELSE NULL END,0,0,NULL,'formacion'),
    (10,'TEXTO10','Movilidad','TEXT',6,0,50,'Movilidad',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO10 ELSE NULL END,0,0,NULL,'movilidad'),
    (11,'FECHA01','Fecha ingreso','DATE',6,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 AND @VFECHA01 IS NOT NULL THEN CONVERT(VARCHAR(10),@VFECHA01,23) ELSE NULL END,0,0,NULL,'fecha-ingreso'),
    (12,'FECHA02','Fecha egreso','DATE',6,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 AND @VFECHA02 IS NOT NULL THEN CONVERT(VARCHAR(10),@VFECHA02,23) ELSE NULL END,0,0,NULL,'fecha-egreso'),
    (13,'TEXTO12','Estado','TEXT',6,1,30,'Seleccione estado',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO12 ELSE 'ACTIVO' END,0,0,NULL,'estado'),
    (14,'FLAG02','Ingresa al sistema','TOGGLE',6,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VFLAG02 ELSE '0' END,0,0,'Habilita la asociación con un usuario del modelo de seguridad.','ingresa-sistema'),
    (15,'TEXTO11','Usuario del sistema','TEXT',12,0,100,'Seleccione un usuario',NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VTEXTO11 ELSE NULL END,0,0,NULL,'usuario-seguridad'),
    (16,'IDSELEC01','ID','HIDDEN',12,0,NULL,NULL,NULL,CASE WHEN @VFORM_REOPEN=1 THEN @VID_EMPLEADO ELSE NULL END,0,1,NULL,'id'),
    (17,'FLAG01','Operación','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctEmpleadoEditModal',
         @TITLE='Editar empleado',
         @SUBTITLE='Modificación de datos generales del empleado.',
         @ICON='id-card',
         @LAYOUT='MODAL',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@VFORM_ERROR,
         @OPEN_ON_RENDER=@VFORM_REOPEN,
         @OUTHTML=@HTML_MODAL OUTPUT;

    SET @HTML_MODAL = ISNULL(@HTML_MODAL,'') +
        '<template data-vct-field-options data-vct-target="vctEmpleadoEditModal" data-vct-field="TEXTO12" data-vct-placeholder="Seleccione estado">' +
            '<option value="ACTIVO">Activo</option>' +
            '<option value="INACTIVO">Inactivo</option>' +
        '</template>' +
        '<template data-vct-field-options data-vct-target="vctEmpleadoEditModal" data-vct-field="TEXTO11" data-vct-placeholder="Seleccione un usuario">' +
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

    <section class="vct-soft-kpi-grid" aria-label="Indicadores de empleados">
        <article class="vct-soft-kpi is-blue">
            <span class="vct-soft-kpi-icon" data-vct-icon="users"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Total Empleados</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL) + '</strong>
                <span class="vct-soft-kpi-help">empleados registrados</span>
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
            <span class="vct-soft-kpi-icon" data-vct-icon="user-minus"></span>
            <div class="vct-soft-kpi-copy">
                <span class="vct-soft-kpi-label">Inactivos</span>
                <strong class="vct-soft-kpi-value">' + CONVERT(VARCHAR(30),@TOTAL_INACTIVOS) + '</strong>
                <span class="vct-soft-kpi-help">estado inactivo</span>
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
                 data-vct-dg-id="empleados"
                 data-vct-dg-title="Empleados"
                 data-vct-dg-subtitle="Gestión y consulta de empleados del sistema."
                 data-vct-dg-unit="empleado(s)"
                 data-vct-dg-page-size="10"
                 data-vct-dg-search-placeholder="Buscar empleado, documento, CUIT, cargo..."
                 data-vct-dg-density="compact"
                 data-vct-dg-layout="fixed">

                <div data-vct-dg-slot="filters">
                    <select class="vct-select vct-select-sm" data-vct-dg-filter="estado" aria-label="Estado">
                        <option value="">Todos los estados</option>
                        <option value="ACTIVO">Activo</option>
                        <option value="INACTIVO">Inactivo</option>
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

                            <th data-vct-width="9%" data-vct-sort="legajo" data-vct-sortable="true">
                                <span>Legajo</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th data-vct-sort="empleado" data-vct-sortable="true">
                                <span>Empleado</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="14%" data-vct-sort="documento" data-vct-sortable="true">
                                <span>Documento</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th data-vct-width="16%" data-vct-sort="cargo" data-vct-sortable="true">
                                <span>Cargo</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th data-vct-width="14%" data-vct-sort="area" data-vct-sortable="true">
                                <span>Área</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="9%" data-vct-sort="estado" data-vct-sortable="true">
                                <span>Estado</span>
                                <span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span>
                            </th>

                            <th class="vct-text-center" data-vct-width="8%" data-vct-sort="sistema" data-vct-sortable="true">
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
