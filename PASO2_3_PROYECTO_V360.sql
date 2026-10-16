/* ========================================================================
   PASO2_3_PROYECTO_V360
   ------------------------------------------------------------------------
   Reemplaza el cuerpo de dbo.VCT_MAIN_PROYECTO_V360 (Vista 360 de
   Proyecto) segun los bocetos de design-bocetos (v360_1 resumen,
   v360_2 proyecto/servicios, v360_3 lanzamiento, v360_5 acciones,
   paso3 asignar consultor) y el documento funcional, seccion 11.
     - Encabezado, KPIs y las 8 pestanias del workflow: Resumen,
       Proyecto (Datos y servicios / Normas / Equipo), Lanzamiento,
       Parte logistico, Acciones, Agenda, Administracion, Documentos.
       Funcionan: Resumen, Proyecto, Lanzamiento (control) y Acciones;
       el resto muestra en que paso se habilita.
     - "Pendiente a su cargo": las acciones abiertas del usuario en el
       proyecto con su boton Gestionar (Asignar consultor abre el modal).
       Si el usuario no tiene pendientes, solo navega.
     - Modal "Asignar consultor" -> dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR
       (comando PV_ASIGNAR por VCT_BUFFER).
   El proyecto llega en VCT_BUFFER.IDSELEC02 (grilla Proyectos, Acciones,
   V360 Cliente). Permisos solo con dbo.VCT_MAIN_GET_ACTIONS.
   Assets: css/vct-proyecto-v360.css?v=14  js/vct-proyecto-v360.js?v=12
   No crea vistas, funciones ni tablas. ASCII. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;
IF OBJECT_ID('tempdb..#P2V') IS NOT NULL DROP TABLE #P2V;
CREATE TABLE #P2V (TRG BIT);
INSERT INTO #P2V VALUES (@TRG);
GO

ALTER PROCEDURE dbo.VCT_MAIN_PROYECTO_V360
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
    /* PROYECTO_V360_V2 */
    SET NOCOUNT ON;
    SET @OUTPARAM1 = '';
    SET @OUTPARAM2 = '';
    SET @OUTPARAM3 = '';

    DECLARE @HTML_SHELL VARCHAR(MAX) = '', @RES VARCHAR(20) = '',
            @HOY DATETIME = CONVERT(DATETIME, CONVERT(DATE, GETDATE())),
            @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @ID_PROYECTO INT, @MSG VARCHAR(1000) = '', @ERR VARCHAR(1000) = '',
            @ASSETS VARCHAR(MAX);

    SET @ASSETS = '<link rel="stylesheet" href="../css/vct-datagrid.css?v=30"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=12"></script>'
                + '<link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script>'
                + '<link rel="stylesheet" href="../css/vct-proyecto-v360.css?v=14"><script src="../js/vct-proyecto-v360.js?v=12"></script>';

    /* ---------- buffer: proyecto + comando ---------- */
    DECLARE @B_PROY VARCHAR(100), @B_FLAG VARCHAR(10), @B_CMD VARCHAR(100), @B_SEL3 VARCHAR(100),
            @B_T11 VARCHAR(4000), @B_T12 VARCHAR(4000), @B_T13 VARCHAR(4000);
    SELECT TOP 1 @B_PROY = REPLACE(ISNULL(IDSELEC02,''), ',', ''), @B_FLAG = ISNULL(FLAG01,''),
                 @B_CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))), @B_SEL3 = REPLACE(ISNULL(IDSELEC03,''), ',', ''),
                 @B_T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))), @B_T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))), @B_T13 = LTRIM(RTRIM(ISNULL(TEXTO13,'')))
    FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
    SET @B_PROY = LTRIM(RTRIM(ISNULL(@B_PROY,'')));
    IF @B_PROY <> '' AND PATINDEX('%[^0-9]%', @B_PROY) = 0 AND LEN(@B_PROY) <= 9 SET @ID_PROYECTO = CONVERT(INT, @B_PROY);

    /* comando PV_ASIGNAR: TEXTO11 = "consultor:rol;consultor:rol", TEXTO12 = vence (aaaa-mm-dd),
       TEXTO13 = observaciones, TEXTO14 = email adicional (CC, o destino si el consultor no tiene email).
       Se asigna primero el lider (cumple la accion y dispara las reglas) y despues el resto. */
    IF @B_FLAG = '1' AND @B_CMD = 'PV_ASIGNAR'
    BEGIN
        DECLARE @B_T14 VARCHAR(4000) = '';
        SELECT TOP 1 @B_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))) FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL
        WHERE PAR_KEY = @IPKEYJOB;
        DECLARE @A_VENCE DATETIME, @A_LIST VARCHAR(4000) = @B_T11 + ';', @A_PAR VARCHAR(100), @A_P INT, @A_Q INT,
                @A_ERR VARCHAR(1000), @A_MSG VARCHAR(1000), @A_I INT = 0, @A_CONS INT, @A_ROL INT;
        DECLARE @AL TABLE (ORD INT IDENTITY(1,1), CONS INT, ROL INT, LIDER BIT);
        IF @B_T12 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T12,'-','')) = 1
            SET @A_VENCE = CONVERT(DATETIME, REPLACE(@B_T12,'-',''), 112);
        SET @A_P = CHARINDEX(';', @A_LIST);
        WHILE @A_P > 0
        BEGIN
            SET @A_PAR = LTRIM(RTRIM(LEFT(@A_LIST, @A_P - 1)));
            SET @A_LIST = SUBSTRING(@A_LIST, @A_P + 1, 4000);
            SET @A_Q = CHARINDEX(':', @A_PAR);
            IF @A_Q > 1 AND PATINDEX('%[^0-9]%', LEFT(@A_PAR, @A_Q - 1)) = 0 AND PATINDEX('%[^0-9]%', SUBSTRING(@A_PAR, @A_Q + 1, 20)) = 0
               AND LEN(LEFT(@A_PAR, @A_Q - 1)) BETWEEN 1 AND 9 AND LEN(SUBSTRING(@A_PAR, @A_Q + 1, 20)) BETWEEN 1 AND 9
                INSERT INTO @AL (CONS, ROL, LIDER)
                SELECT CONVERT(INT, LEFT(@A_PAR, @A_Q - 1)), CONVERT(INT, SUBSTRING(@A_PAR, @A_Q + 1, 20)),
                       CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) WHERE R.ID = CONVERT(INT, SUBSTRING(@A_PAR, @A_Q + 1, 20)) AND R.CODIGO = 'CONSULTOR_LIDER') THEN 1 ELSE 0 END;
            SET @A_P = CHARINDEX(';', @A_LIST);
        END;
        IF @ID_PROYECTO IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        ELSE IF NOT EXISTS (SELECT 1 FROM @AL) SET @ERR = 'Seleccione al menos un consultor.';
        ELSE IF (SELECT COUNT(*) FROM @AL WHERE LIDER = 1) > 1 SET @ERR = 'Solo puede haber un consultor l' + CHAR(237) + 'der.';
        ELSE
        BEGIN
            DECLARE @AO TABLE (ORD INT IDENTITY(1,1), CONS INT, ROL INT);
            INSERT INTO @AO (CONS, ROL) SELECT CONS, ROL FROM @AL ORDER BY LIDER DESC, ORD;
            WHILE 1 = 1
            BEGIN
                SELECT TOP 1 @A_I = ORD, @A_CONS = CONS, @A_ROL = ROL FROM @AO WHERE ORD > @A_I ORDER BY ORD;
                IF @@ROWCOUNT = 0 BREAK;
                SELECT @A_ERR = '', @A_MSG = '';
                BEGIN TRY
                    EXEC dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @ID_PROYECTO = @ID_PROYECTO,
                         @ID_CONSULTOR = @A_CONS, @ID_ROL = @A_ROL, @VENCE = @A_VENCE, @OBS = @B_T13, @EMAIL_EXTRA = @B_T14,
                         @ERROR = @A_ERR OUTPUT, @MENSAJE = @A_MSG OUTPUT;
                END TRY
                BEGIN CATCH
                    SET @A_ERR = LEFT('No se pudo asignar el consultor: ' + ERROR_MESSAGE(), 1000);
                END CATCH;
                IF ISNULL(@A_ERR,'') <> '' SET @ERR = LEFT(@ERR + CASE WHEN @ERR = '' THEN '' ELSE ' ' END + @A_ERR, 1000);
                IF ISNULL(@A_MSG,'') <> '' SET @MSG = LEFT(@MSG + CASE WHEN @MSG = '' THEN '' ELSE ' ' END + @A_MSG, 1000);
            END;
        END;
    END;

    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL @IUNIDAD = @IUNIDAD, @IAGENTE = @IAGENTE, @FORM_ID = @FORM_ID,
             @TITLE = 'Vista 360 de Proyecto', @SUBTITLE = 'Ficha del proyecto: datos, equipo, lanzamiento y acciones.',
             @SEARCH_PLACEHOLDER = '', @SHOW_SEARCH = 0, @OSHELL = @HTML_SHELL OUTPUT, @ORESULTADO = @RES OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
    END CATCH;

    /* ---------- proyecto ---------- */
    DECLARE @COD VARCHAR(100), @NOM VARCHAR(300), @REF VARCHAR(300), @CLI INT, @CLI_NOM VARCHAR(300),
            @EST_COD VARCHAR(30), @EST_DES VARCHAR(100), @F_INI DATETIME, @F_FIN DATETIME,
            @H_PROY NUMERIC(18,2), @RIESGO VARCHAR(50), @TIPO_P VARCHAR(20), @ID_CONTACTO INT,
            @F_ALTA DATETIME, @U_ALTA VARCHAR(100), @CONTACTO VARCHAR(400) = '';
    IF @ID_PROYECTO IS NOT NULL
        SELECT @COD = P.CODIGO, @NOM = P.NOMBRE, @REF = P.REFERENCIA, @CLI = P.IDCLIENTE, @CLI_NOM = C.RAZON_SOCIAL,
               @EST_COD = E.CODIGO, @EST_DES = E.DESCRIPCION, @F_INI = P.FECHA_INICIO, @F_FIN = P.FECHA_FIN,
               @H_PROY = ISNULL(P.TOTAL_HORAS_PROYECTADAS, 0), @RIESGO = P.NIVEL_RIESGO, @TIPO_P = P.TIPO_PROYECTO,
               @ID_CONTACTO = P.IDCONTACTO, @F_ALTA = P.FECHA_ALTA, @U_ALTA = P.USUARIO_ALTA
        FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
        LEFT JOIN dbo.VCT_CLIENTES C WITH(NOLOCK) ON C.ID = P.IDCLIENTE
        LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E WITH(NOLOCK) ON E.ID = P.ID_ESTADO
        WHERE P.ID = @ID_PROYECTO;

    IF @COD IS NULL AND @NOM IS NULL
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @ASSETS
            + '<div class="vct-page vct-page-main" data-vct-page data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID,''),'"','') + '">'
            + '<section class="vct-module vct-360-module vct-360-visual-final">'
            + '<div class="vct-360-breadcrumb-row"><nav class="vct-breadcrumb-simple"><button type="button" class="vct-breadcrumb-link" data-vct-v360-back data-vct-sidebar-mod="3">Proyectos</button></nav></div>'
            + '<div class="vct-360-box"><div class="vct-360-empty">Sin proyecto seleccionado. Abra un proyecto desde Proyectos, Acciones o la Vista 360 del cliente.</div></div>'
            + '</section></div>';
        RETURN;
    END;

    /* escapes para HTML */
    DECLARE @E_COD VARCHAR(400) = REPLACE(REPLACE(REPLACE(ISNULL(@COD,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),
            @E_NOM VARCHAR(1200) = REPLACE(REPLACE(REPLACE(ISNULL(@NOM,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),
            @E_REF VARCHAR(1200) = REPLACE(REPLACE(REPLACE(ISNULL(@REF,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),
            @E_CLI VARCHAR(1200) = REPLACE(REPLACE(REPLACE(ISNULL(@CLI_NOM,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),
            @E_TIPO VARCHAR(100) = CASE UPPER(ISNULL(@TIPO_P,'')) WHEN 'IMPLEMENTACION' THEN 'Implementaci&oacute;n' WHEN 'MANTENIMIENTO' THEN 'Mantenimiento' ELSE '-' END,
            @E_RIESGO VARCHAR(100) = REPLACE(REPLACE(ISNULL(NULLIF(@RIESGO,''),'-'),'<','&lt;'),'>','&gt;'),
            @E_EST VARCHAR(200) = REPLACE(REPLACE(ISNULL(@EST_DES, ISNULL(@EST_COD,'')),'<','&lt;'),'>','&gt;');

    SELECT TOP 1 @CONTACTO = LTRIM(RTRIM(ISNULL(CT.NOMBRES,'') + ' ' + ISNULL(CT.APELLIDO,'')))
                           + CASE WHEN ISNULL(CT.CARGO,'') <> '' THEN ' - ' + CT.CARGO ELSE '' END
    FROM dbo.VCT_CONTACTOS CT WITH(NOLOCK) WHERE CT.ID = @ID_CONTACTO;
    SET @CONTACTO = REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(@CONTACTO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;');

    /* ---------- usuario y permisos ---------- */
    DECLARE @EMP_U INT, @CONS_U INT, @PUEDE_EDIT BIT = 0, @GUID_V360 VARCHAR(100) = '';
    SELECT TOP 1 @EMP_U = ID FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U ORDER BY ID DESC;
    SELECT TOP 1 @CONS_U = ID FROM dbo.VCT_CONSULTORES WITH(NOLOCK) WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U ORDER BY ID DESC;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'EDIT') SET @PUEDE_EDIT = 1;
        SELECT TOP 1 @GUID_V360 = ISNULL(A.TARGET_GUID,'') FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A
        WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'VIEW' AND ISNULL(A.TARGET_GUID,'') <> '' ORDER BY A.SORT_ORDER;
    END TRY
    BEGIN CATCH
        SET @PUEDE_EDIT = 0;
    END CATCH;

    /* comando PV_EQ_BAJA (PV_EQ_BAJA_V1): IDSELEC03 = ID de VCT_PROYECTOS_EQUIPO de un consultor.
       Quita al consultor del equipo (todas sus filas con ese rol en el proyecto).
       No se puede si tiene visitas en la agenda del proyecto o acciones abiertas a su cargo.
       Permiso: responsable de la accion abierta "Asignar consultores" o EDIT de PROYECTOS. */
    IF @B_FLAG = '1' AND @B_CMD = 'PV_EQ_BAJA'
    BEGIN
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL WHERE PAR_KEY = @IPKEYJOB;
        DECLARE @BJ_ID INT, @BJ_CONS INT, @BJ_ROL INT, @BJ_NOM VARCHAR(300) = '', @BJ_PUEDE BIT = @PUEDE_EDIT, @BJ_ACC INT, @BJ_EST INT, @BJ_N INT = 0;
        IF @B_SEL3 <> '' AND PATINDEX('%[^0-9]%', @B_SEL3) = 0 AND LEN(@B_SEL3) <= 9 SET @BJ_ID = CONVERT(INT, @B_SEL3);
        SELECT @BJ_CONS = EQ.ID_CONSULTOR, @BJ_ROL = EQ.ID_ROL,
               @BJ_NOM = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),'')))
        FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        LEFT JOIN dbo.VCT_CONSULTORES C WITH(NOLOCK) ON C.ID = EQ.ID_CONSULTOR
        WHERE EQ.ID = @BJ_ID AND EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR';
        SELECT TOP 1 @BJ_ACC = A.ID, @BJ_EST = A.ID_ESTADO
        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'ASIGNACION_CONSULTOR'
        WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID DESC;
        IF @BJ_PUEDE = 0 AND EXISTS (
            SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'ASIGNACION_CONSULTOR'
            INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
            INNER JOIN dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK) ON AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO'
            WHERE A.ID_PROYECTO = @ID_PROYECTO
              AND ((AP.TIPO_ENTIDAD = 'EMPLEADO' AND AP.ID_ENTIDAD = @EMP_U) OR (AP.TIPO_ENTIDAD = 'CONSULTOR' AND AP.ID_ENTIDAD = @CONS_U)))
            SET @BJ_PUEDE = 1;
        SELECT @BJ_N = COUNT(*)
        FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)
        INNER JOIN dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK) ON V.ID = VC.ID_VISITA
        INNER JOIN dbo.VCT_PROYECTOS_SERVICIOS S WITH(NOLOCK) ON S.ID = V.ID_PROYECTO_SERVICIO
        WHERE S.ID_PROYECTO = @ID_PROYECTO AND VC.ID_CONSULTOR = @BJ_CONS;

        IF @ID_PROYECTO IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        ELSE IF @BJ_CONS IS NULL SET @ERR = 'El integrante indicado no es un consultor de este proyecto.';
        ELSE IF @BJ_PUEDE = 0 SET @ERR = 'No tiene permiso para quitar consultores de este proyecto.';
        ELSE IF @BJ_N > 0 SET @ERR = @BJ_NOM + ' tiene ' + CONVERT(VARCHAR(10), @BJ_N) + ' visita(s) en la agenda del proyecto: no se puede quitar.';
        ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
                        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
                        INNER JOIN dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK) ON AP.ID_ACCION = A.ID AND AP.ESTADO = 'ACTIVO'
                        WHERE A.ID_PROYECTO = @ID_PROYECTO AND AP.TIPO_ENTIDAD = 'CONSULTOR' AND AP.ID_ENTIDAD = @BJ_CONS)
            SET @ERR = @BJ_NOM + ' tiene acciones abiertas en el proyecto: no se puede quitar.';
        ELSE
        BEGIN
            BEGIN TRY
                BEGIN TRAN;
                DELETE FROM dbo.VCT_PROYECTOS_EQUIPO
                WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR' AND ID_CONSULTOR = @BJ_CONS AND ID_ROL = @BJ_ROL;
                IF @BJ_ACC IS NOT NULL
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@BJ_ACC, @BJ_EST, @BJ_EST, 'CONSULTOR_QUITADO', LEFT('Consultor quitado del equipo: ' + @BJ_NOM + '.', 2000), 'USUARIO', GETDATE(), @IAGENTE);
                COMMIT;
                SET @MSG = @BJ_NOM + ' fue quitado del equipo.';
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @ERR = LEFT('No se pudo quitar el consultor: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
        END;
    END;

    /* ======================= LANZAMIENTO: comandos (PV_LANZ_V1) =======================
       Sin tablas nuevas: todo en VCT_PROYECTOS_DOCUMENTOS, una fila por registro.
         TIPO 'MG'     dato de entrada: NRO_INTERNO = 'ITEM:<id VCT_PRM_DOCUMENTOS_ITEMS>' o 'LIBRE',
                       TEMAS = pregunta, OBSERVACIONES = respuesta, ID_DOCUMENTO = minuta RE-PP-022 del servicio.
         TIPO 'CONS'   consideracion: NRO_INTERNO = INTERNA / CONSULTOR / CLIENTE, OBSERVACIONES = texto.
         TIPO 'LANZ'   reunion de lanzamiento: FECHA_DOCUMENTO = fecha, PARTICIPANTES, TEMAS, ID_CONSULTOR,
                       OBSERVACIONES = conclusiones, FECHA_CIERRE = realizada.
         TIPO 'INICIO' inicio del proyecto: FECHA_DOCUMENTO = fecha de inicio real, OBSERVACIONES.
       Buffer: TEXTO30 = comando, IDSELEC03 = ID de la fila (editar / borrar), TEXTO11..16 = campos.
       Permiso: analista del proyecto (equipo, rol ANALISTA) o EDIT de PROYECTOS. */
    DECLARE @VOLVER VARCHAR(50) = 'equipo', @PUEDE_LANZ BIT = @PUEDE_EDIT;
    IF @PUEDE_LANZ = 0 AND EXISTS (
        SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ID_EMPLEADO = @EMP_U)
        SET @PUEDE_LANZ = 1;

    /* minutas (datos de entrada) de los servicios del proyecto: RE-PP-022-CO / -A / -CA */
    CREATE TABLE #MIN (ID_DOCUMENTO INT, ID_SERVICIO INT, ID_PS INT, SRV VARCHAR(300));
    INSERT INTO #MIN
    SELECT D.ID, X.ID_SERVICIO, X.ID_PS, X.SRV
    FROM (SELECT PS.ID_SERVICIO, MIN(PS.ID) AS ID_PS, MAX(ISNULL(S.DESCRIPCION,'')) AS SRV, MAX(UPPER(LEFT(ISNULL(S.CODIGO,''),2))) AS C2
          FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
          INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO
          WHERE PS.ID_PROYECTO = @ID_PROYECTO
          GROUP BY PS.ID_SERVICIO) X
    INNER JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK)
            ON D.ACTIVO = 1 AND D.CODIGO = 'RE-PP-022-' + CASE X.C2 WHEN 'AU' THEN 'A' WHEN 'CA' THEN 'CA' ELSE 'CO' END;

    IF @B_FLAG = '1' AND @B_CMD IN ('PV_DE_GUARDAR','PV_DE_BORRAR','PV_DE_CERRAR','PV_CO_GUARDAR','PV_CO_BORRAR',
                                    'PV_RE_GUARDAR','PV_RE_BORRAR','PV_IN_GUARDAR','PV_IN_BORRAR')
    BEGIN
        DECLARE @L_T14 VARCHAR(4000) = '', @L_T15 VARCHAR(4000) = '', @L_T16 VARCHAR(4000) = '';
        SELECT TOP 1 @L_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @L_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @L_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL,
               TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL
        WHERE PAR_KEY = @IPKEYJOB;

        DECLARE @LZ_TIPO VARCHAR(20) = CASE LEFT(@B_CMD, 5) WHEN 'PV_DE' THEN 'MG' WHEN 'PV_CO' THEN 'CONS' WHEN 'PV_RE' THEN 'LANZ' ELSE 'INICIO' END;
        SET @VOLVER = 'lanzamiento:' + CASE @LZ_TIPO WHEN 'MG' THEN 'datos' WHEN 'CONS' THEN 'cons' WHEN 'LANZ' THEN 'reunion' ELSE 'inicio' END;

        DECLARE @LZ_ID INT, @LZ_CUMP INT, @LZ_PEND INT, @LZ_CANC INT, @LZ_P_CONF INT, @LZ_P_CURSO INT, @LZ_P_EST INT,
                @LZ_CLI INT, @LZ_COD VARCHAR(100), @LZ_NOM VARCHAR(300), @LZ_FECHA DATETIME, @LZ_ITEM INT, @LZ_DOC INT,
                @LZ_SRV INT, @LZ_PS INT, @LZ_PREG VARCHAR(1000) = '', @LZ_ACC INT, @LZ_ACC_EST INT, @LZ_CONS INT, @LZ_N INT = 0;
        IF @B_SEL3 <> '' AND PATINDEX('%[^0-9]%', @B_SEL3) = 0 AND LEN(@B_SEL3) <= 9 SET @LZ_ID = NULLIF(CONVERT(INT, @B_SEL3), 0);
        SELECT @LZ_CUMP = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';
        SELECT @LZ_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE';
        SELECT @LZ_CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';
        SELECT @LZ_P_CONF = ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CONFIRMADO';
        SELECT @LZ_P_CURSO = ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'ENCURSO';
        SELECT @LZ_P_EST = ID_ESTADO, @LZ_CLI = IDCLIENTE, @LZ_COD = CODIGO, @LZ_NOM = NOMBRE FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;

        IF @ID_PROYECTO IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        IF @ERR = '' AND @PUEDE_LANZ = 0 SET @ERR = 'No tiene permiso para editar el lanzamiento de este proyecto.';
        IF @ERR = '' AND @LZ_ID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS WITH(NOLOCK) WHERE ID = @LZ_ID AND ID_PROYECTO = @ID_PROYECTO AND TIPO = @LZ_TIPO)
            SET @ERR = 'El registro indicado no corresponde a este proyecto.';
        IF @ERR = '' AND @B_CMD LIKE '%[_]BORRAR' AND @LZ_ID IS NULL SET @ERR = 'Indique el registro a eliminar.';

        /* fecha aaaa-mm-dd (reunion e inicio) */
        IF @ERR = '' AND @LZ_TIPO IN ('LANZ','INICIO') AND @B_CMD LIKE '%[_]GUARDAR'
        BEGIN
            IF @B_T11 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T11,'-','')) = 1
                SET @LZ_FECHA = CONVERT(DATETIME, REPLACE(@B_T11,'-',''), 112);
            IF @LZ_FECHA IS NULL SET @ERR = 'Fecha es obligatoria.';
        END;

        /* ---------- validaciones por comando ---------- */
        IF @ERR = '' AND @B_CMD = 'PV_DE_GUARDAR'
        BEGIN
            IF @B_T13 = '' SET @ERR = 'Respuesta es obligatoria.';
            ELSE IF @LZ_ID IS NULL
            BEGIN
                IF @B_T11 <> '' AND PATINDEX('%[^0-9]%', @B_T11) = 0 AND LEN(@B_T11) <= 9 SET @LZ_ITEM = CONVERT(INT, @B_T11);
                IF @LZ_ITEM IS NOT NULL
                BEGIN
                    SELECT TOP 1 @LZ_DOC = I.ID_DOCUMENTO, @LZ_PREG = LEFT(ISNULL(I.DESCRIPCION,''), 1000), @LZ_SRV = M.ID_SERVICIO, @LZ_PS = M.ID_PS
                    FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
                    INNER JOIN #MIN M ON M.ID_DOCUMENTO = I.ID_DOCUMENTO
                    WHERE I.ID = @LZ_ITEM AND I.ACTIVO = 1 AND UPPER(ISNULL(I.GRUPO,'')) <> 'CIERRE';
                    IF @LZ_DOC IS NULL SET @ERR = 'El dato elegido no corresponde a los servicios del proyecto.';
                    ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS WITH(NOLOCK)
                                    WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'MG' AND NRO_INTERNO = 'ITEM:' + CONVERT(VARCHAR(20), @LZ_ITEM))
                        SET @ERR = 'Ese dato ya est' + CHAR(225) + ' cargado: ed' + CHAR(237) + 'telo desde la grilla.';
                END
                ELSE
                BEGIN
                    SET @LZ_PREG = LEFT(@B_T12, 1000);
                    IF @LZ_PREG = '' SET @ERR = 'Dato es obligatorio: elija uno de la minuta o escriba el dato.';
                    SELECT TOP 1 @LZ_DOC = ID_DOCUMENTO, @LZ_SRV = ID_SERVICIO, @LZ_PS = ID_PS FROM #MIN ORDER BY ID_SERVICIO;
                END;
            END;
        END;
        IF @ERR = '' AND @B_CMD = 'PV_DE_CERRAR'
        BEGIN
            SELECT TOP 1 @LZ_ACC = A.ID, @LZ_ACC_EST = A.ID_ESTADO
            FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_DATOS_ENTRADA'
            INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
            WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID;
            SELECT @LZ_N = COUNT(*) FROM dbo.VCT_PROYECTOS_DOCUMENTOS WITH(NOLOCK)
            WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'MG' AND (NRO_INTERNO LIKE 'ITEM:%' OR NRO_INTERNO = 'LIBRE');
            IF @LZ_ACC IS NULL SET @ERR = 'No hay una acci' + CHAR(243) + 'n "Carga de datos de entrada" abierta en el proyecto.';
            ELSE IF @LZ_N = 0 SET @ERR = 'Cargue al menos un dato de entrada antes de finalizar la carga.';
        END;
        IF @ERR = '' AND @B_CMD = 'PV_CO_GUARDAR'
        BEGIN
            IF UPPER(@B_T11) NOT IN ('INTERNA','CONSULTOR','CLIENTE') SET @ERR = 'Tipo es obligatorio.';
            ELSE IF @B_T12 = '' SET @ERR = 'Consideraci' + CHAR(243) + 'n es obligatoria.';
        END;
        IF @ERR = '' AND @B_CMD = 'PV_RE_GUARDAR'
        BEGIN
            IF @L_T16 <> '' AND PATINDEX('%[^0-9]%', @L_T16) = 0 AND LEN(@L_T16) <= 9 SET @LZ_CONS = CONVERT(INT, @L_T16);
            IF @LZ_CONS IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK)
                                                    WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR' AND ID_CONSULTOR = @LZ_CONS AND ESTADO = 'ACTIVO')
                SET @ERR = 'El consultor elegido no es del equipo del proyecto.';
            ELSE IF @L_T15 = '1' AND @LZ_FECHA > @HOY SET @ERR = 'Una reuni' + CHAR(243) + 'n realizada no puede tener fecha futura.';
        END;
        IF @ERR = '' AND @B_CMD = 'PV_IN_GUARDAR'
        BEGIN
            IF @LZ_FECHA > @HOY SET @ERR = 'Fecha de inicio real no puede ser futura.';
            ELSE IF @LZ_ID IS NULL
            BEGIN
                IF @LZ_P_EST <> @LZ_P_CONF SET @ERR = 'Solo se puede iniciar un proyecto en estado Confirmado.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'CONSULTOR_LIDER'
                                    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO')
                    SET @ERR = 'Falta asignar el consultor l' + CHAR(237) + 'der.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_DATOS_ENTRADA'
                                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_ESTADO = @LZ_CUMP)
                    SET @ERR = 'Falta finalizar la carga de datos de entrada.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS WITH(NOLOCK) WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'CONS' AND ISNULL(OBSERVACIONES,'') <> '')
                    SET @ERR = 'Falta cargar al menos una consideraci' + CHAR(243) + 'n.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'LANZAMIENTO'
                                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_ESTADO = @LZ_CUMP)
                    SET @ERR = 'Falta registrar la reuni' + CHAR(243) + 'n de lanzamiento realizada.';
            END;
        END;
        IF @ERR = '' AND @B_CMD = 'PV_IN_GUARDAR' AND @LZ_ID IS NULL AND @B_T13 = '1'
        BEGIN
            SET @L_T14 = REPLACE(REPLACE(@L_T14, ',', ';'), ' ', '');
            SET @L_T15 = REPLACE(REPLACE(@L_T15, ',', ';'), ' ', '');
            IF @L_T14 = '' SET @ERR = 'Para es obligatorio para enviar el mail al consultor.';
            ELSE
            BEGIN
                DECLARE @IM_L VARCHAR(1100) = @L_T14 + ';' + @L_T15 + ';', @IM_P INT, @IM_X VARCHAR(500);
                SET @IM_P = CHARINDEX(';', @IM_L);
                WHILE @IM_P > 0 AND @ERR = ''
                BEGIN
                    SET @IM_X = LEFT(@IM_L, @IM_P - 1);
                    SET @IM_L = SUBSTRING(@IM_L, @IM_P + 1, 1100);
                    IF @IM_X <> '' AND @IM_X NOT LIKE '%_@_%._%' SET @ERR = 'Email no v' + CHAR(225) + 'lido: ' + @IM_X;
                    SET @IM_P = CHARINDEX(';', @IM_L);
                END;
            END;
        END;
        IF @ERR = '' AND @B_CMD = 'PV_IN_BORRAR'
        BEGIN
            IF @LZ_P_EST <> @LZ_P_CURSO SET @ERR = 'El proyecto no est' + CHAR(225) + ' En curso: no hay inicio para deshacer.';
            ELSE IF COL_LENGTH('dbo.VCT_PROYECTOS_PLANES', 'ID_PROYECTO') IS NOT NULL
            BEGIN
                EXEC sp_executesql N'SELECT @N = COUNT(*) FROM dbo.VCT_PROYECTOS_PLANES WITH(NOLOCK) WHERE ID_PROYECTO = @P',
                     N'@N INT OUTPUT, @P INT', @N = @LZ_N OUTPUT, @P = @ID_PROYECTO;
                IF @LZ_N > 0 SET @ERR = 'El proyecto ya tiene parte log' + CHAR(237) + 'stico cargado: no se puede deshacer el inicio.';
            END;
        END;

        /* reglas del evento PROYECTO_INICIADO (al iniciar; una vez, salvo que se hayan cancelado) */
        DECLARE @LZ_RG TABLE (ID INT, CODIGO VARCHAR(100), ID_TIPO INT, ID_SUBTIPO INT, ID_ESTADO INT, ID_PRIORIDAD INT, ROL VARCHAR(100),
                              TITULO VARCHAR(300), DETALLE VARCHAR(MAX), DIAS INT, ES_FINAL BIT, TIPO_ENT VARCHAR(20), ID_ENT INT, ID_ACCION INT);
        IF @ERR = '' AND @B_CMD = 'PV_IN_GUARDAR' AND @LZ_ID IS NULL
        BEGIN
            INSERT INTO @LZ_RG (ID, CODIGO, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ROL, TITULO, DETALLE, DIAS, ES_FINAL)
            SELECT R.ID, R.CODIGO, R.ID_TIPO, R.ID_SUBTIPO, R.ID_ESTADO_INICIAL, R.ID_PRIORIDAD, LTRIM(RTRIM(ISNULL(R.DESTINATARIO_ROL,''))),
                   R.TITULO_PLANTILLA, R.DETALLE_PLANTILLA, R.DIAS_VENCIMIENTO, ISNULL(E.ES_FINAL, 0)
            FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
            LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = R.ID_ESTADO_INICIAL
            WHERE R.CODIGO_EVENTO = 'PROYECTO_INICIADO' AND R.ACTIVO = 1
              AND NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
                              WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_REGLA_ORIGEN = R.ID AND ISNULL(A.ID_ESTADO, 0) <> ISNULL(@LZ_CANC, -1));
            UPDATE G SET TIPO_ENT = X.TIPO_MIEMBRO, ID_ENT = X.ID_ENT
            FROM @LZ_RG G
            LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.CODIGO = G.ROL
            OUTER APPLY (SELECT TOP 1 EQ.TIPO_MIEMBRO, CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END AS ID_ENT
                         FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                         WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ID_ROL = R.ID AND EQ.ESTADO = 'ACTIVO'
                         ORDER BY EQ.PRINCIPAL DESC, EQ.ID) X;
            SELECT TOP 1 @ERR = 'La regla ' + G.CODIGO + ' no tiene a qui' + CHAR(233) + 'n asignarse en el equipo (DESTINATARIO_ROL = '
                              + CASE WHEN G.ROL = '' THEN 'vacio' ELSE G.ROL END + ').'
            FROM @LZ_RG G WHERE G.ID_ENT IS NULL ORDER BY G.ID;
        END;

        /* ---------- grabar ---------- */
        IF @ERR = ''
        BEGIN
            BEGIN TRY
                BEGIN TRAN;

                IF @B_CMD = 'PV_DE_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS
                        (ID_PROYECTO, ID_SERVICIO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, FECHA_DOCUMENTO, NRO_INTERNO, TEMAS, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @LZ_SRV, @LZ_PS, @LZ_DOC, GETDATE(),
                            CASE WHEN @LZ_ITEM IS NULL THEN 'LIBRE' ELSE 'ITEM:' + CONVERT(VARCHAR(20), @LZ_ITEM) END,
                            @LZ_PREG, 'MG', 'REGISTRADO', LEFT(@B_T13, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_DE_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS
                       SET OBSERVACIONES = LEFT(@B_T13, 2000),
                           TEMAS = CASE WHEN NRO_INTERNO = 'LIBRE' AND @B_T12 <> '' THEN LEFT(@B_T12, 1000) ELSE TEMAS END,
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @LZ_ID;

                IF @B_CMD = 'PV_CO_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, GETDATE(), UPPER(@B_T11), 'CONS', 'REGISTRADO', LEFT(@B_T12, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_CO_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS SET NRO_INTERNO = UPPER(@B_T11), OBSERVACIONES = LEFT(@B_T12, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @LZ_ID;

                IF @B_CMD = 'PV_RE_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS
                        (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, PARTICIPANTES, TEMAS, ID_CONSULTOR, FECHA_CIERRE, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @LZ_FECHA, 'Reuni' + CHAR(243) + 'n de lanzamiento', LEFT(@B_T12, 500), LEFT(@B_T13, 1000), @LZ_CONS,
                            CASE WHEN @L_T15 = '1' THEN GETDATE() END, 'LANZ', CASE WHEN @L_T15 = '1' THEN 'REALIZADA' ELSE 'PROGRAMADA' END,
                            LEFT(@L_T14, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_RE_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS
                       SET FECHA_DOCUMENTO = @LZ_FECHA, PARTICIPANTES = LEFT(@B_T12, 500), TEMAS = LEFT(@B_T13, 1000), ID_CONSULTOR = @LZ_CONS,
                           FECHA_CIERRE = CASE WHEN @L_T15 = '1' THEN ISNULL(FECHA_CIERRE, GETDATE()) END,
                           ESTADO = CASE WHEN @L_T15 = '1' THEN 'REALIZADA' ELSE 'PROGRAMADA' END,
                           OBSERVACIONES = LEFT(@L_T14, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @LZ_ID;

                IF @B_CMD IN ('PV_DE_BORRAR','PV_CO_BORRAR','PV_RE_BORRAR','PV_IN_BORRAR')
                    DELETE FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE ID = @LZ_ID AND ID_PROYECTO = @ID_PROYECTO AND TIPO = @LZ_TIPO;

                /* cerrar "Carga de datos de entrada" */
                IF @B_CMD = 'PV_DE_CERRAR'
                BEGIN
                    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @LZ_CUMP, FECHA_CIERRE = GETDATE() WHERE ID = @LZ_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@LZ_ACC, @LZ_ACC_EST, @LZ_CUMP, 'CUMPLIDA', 'Datos de entrada cargados (' + CONVERT(VARCHAR(10), @LZ_N) + ').', 'USUARIO', GETDATE(), @IAGENTE);
                END;

                /* reunion realizada: cumple "Reunion de lanzamiento"; sin reuniones realizadas: la reabre */
                IF @B_CMD IN ('PV_RE_GUARDAR','PV_RE_BORRAR')
                BEGIN
                    SELECT TOP 1 @LZ_ACC = A.ID, @LZ_ACC_EST = A.ID_ESTADO
                    FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
                    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'LANZAMIENTO'
                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND ISNULL(A.ID_ESTADO, 0) <> ISNULL(@LZ_CANC, -1)
                    ORDER BY A.ID DESC;
                    IF @LZ_ACC IS NOT NULL
                    BEGIN
                        IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'LANZ' AND FECHA_CIERRE IS NOT NULL)
                        BEGIN
                            IF @LZ_ACC_EST <> @LZ_CUMP
                            BEGIN
                                UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @LZ_CUMP, FECHA_CIERRE = GETDATE() WHERE ID = @LZ_ACC;
                                INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                                VALUES (@LZ_ACC, @LZ_ACC_EST, @LZ_CUMP, 'CUMPLIDA', 'Reuni' + CHAR(243) + 'n de lanzamiento realizada.', 'USUARIO', GETDATE(), @IAGENTE);
                            END;
                        END
                        ELSE IF @LZ_ACC_EST = @LZ_CUMP AND @LZ_P_EST = @LZ_P_CONF AND @LZ_PEND IS NOT NULL
                        BEGIN
                            UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @LZ_PEND, FECHA_CIERRE = NULL WHERE ID = @LZ_ACC;
                            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                            VALUES (@LZ_ACC, @LZ_CUMP, @LZ_PEND, 'REABIERTA', 'Se elimin' + CHAR(243) + ' la reuni' + CHAR(243) + 'n de lanzamiento realizada.', 'USUARIO', GETDATE(), @IAGENTE);
                        END;
                    END;
                END;

                /* iniciar proyecto */
                IF @B_CMD = 'PV_IN_GUARDAR' AND @LZ_ID IS NULL
                BEGIN
                    UPDATE dbo.VCT_PROYECTOS SET ID_ESTADO = @LZ_P_CURSO, FECHA_INICIO_REAL = @LZ_FECHA, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @ID_PROYECTO;
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @LZ_FECHA, 'Inicio del proyecto', 'INICIO', 'REGISTRADO', LEFT(@B_T12, 2000), GETDATE(), @IAGENTE);

                    DECLARE @LZ_RID INT = 0, @LZ_NEWA INT;
                    WHILE 1 = 1
                    BEGIN
                        SELECT TOP 1 @LZ_RID = ID FROM @LZ_RG WHERE ID > @LZ_RID ORDER BY ID;
                        IF @@ROWCOUNT = 0 BREAK;
                        INSERT INTO dbo.VCT_ACCIONES
                            (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_REGLA_ORIGEN, TITULO, DESCRIPCION,
                             ID_CLIENTE, ID_PROYECTO, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
                        SELECT 'AUTOMATICA', G.ID_TIPO, G.ID_SUBTIPO, G.ID_ESTADO, G.ID_PRIORIDAD, G.ID,
                               LEFT(REPLACE(REPLACE(ISNULL(G.TITULO,''), '{{CODIGO_PROYECTO}}', ISNULL(@LZ_COD,'')), '{{PROYECTO}}', ISNULL(@LZ_NOM,'')), 300),
                               REPLACE(REPLACE(ISNULL(G.DETALLE, ''), '{{CODIGO_PROYECTO}}', ISNULL(@LZ_COD,'')), '{{PROYECTO}}', ISNULL(@LZ_NOM,'')),
                               @LZ_CLI, @ID_PROYECTO, GETDATE(), GETDATE(),
                               CASE WHEN G.ES_FINAL = 1 OR G.DIAS IS NULL THEN NULL ELSE DATEADD(DAY, G.DIAS, @HOY) END,
                               CASE WHEN G.ES_FINAL = 1 THEN GETDATE() END, GETDATE(), @IAGENTE
                        FROM @LZ_RG G WHERE G.ID = @LZ_RID;
                        SET @LZ_NEWA = SCOPE_IDENTITY();
                        INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES
                            (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                        SELECT @LZ_NEWA, 'RESPONSABLE', G.TIPO_ENT, G.ID_ENT, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE
                        FROM @LZ_RG G WHERE G.ID = @LZ_RID;
                        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                        SELECT @LZ_NEWA, NULL, G.ID_ESTADO, 'ALTA',
                               LEFT('Generada por la regla ' + G.CODIGO + ' al iniciar el proyecto ' + ISNULL(@LZ_COD,'') + '.', 2000), 'SISTEMA', GETDATE(), @IAGENTE
                        FROM @LZ_RG G WHERE G.ID = @LZ_RID;
                    END;
                END;
                IF @B_CMD = 'PV_IN_GUARDAR' AND @LZ_ID IS NOT NULL
                BEGIN
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS SET FECHA_DOCUMENTO = @LZ_FECHA, OBSERVACIONES = LEFT(@B_T12, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @LZ_ID;
                    UPDATE dbo.VCT_PROYECTOS SET FECHA_INICIO_REAL = @LZ_FECHA, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @ID_PROYECTO;
                END;

                /* deshacer el inicio: vuelve a Confirmado y cancela las acciones abiertas que genero el inicio */
                IF @B_CMD = 'PV_IN_BORRAR'
                BEGIN
                    UPDATE dbo.VCT_PROYECTOS SET ID_ESTADO = @LZ_P_CONF, FECHA_INICIO_REAL = NULL, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @ID_PROYECTO;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    SELECT A.ID, A.ID_ESTADO, @LZ_CANC, 'CANCELADA', 'Se deshizo el inicio del proyecto.', 'USUARIO', GETDATE(), @IAGENTE
                    FROM dbo.VCT_ACCIONES A
                    INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
                    INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND @LZ_CANC IS NOT NULL;
                    UPDATE A SET ID_ESTADO = @LZ_CANC, FECHA_CIERRE = GETDATE()
                    FROM dbo.VCT_ACCIONES A
                    INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
                    INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND @LZ_CANC IS NOT NULL;
                END;

                COMMIT;
                SET @MSG = CASE @B_CMD
                    WHEN 'PV_DE_GUARDAR' THEN 'Dato de entrada guardado.'
                    WHEN 'PV_DE_BORRAR'  THEN 'Dato de entrada eliminado.'
                    WHEN 'PV_DE_CERRAR'  THEN 'Carga de datos de entrada finalizada: la acci' + CHAR(243) + 'n qued' + CHAR(243) + ' cumplida.'
                    WHEN 'PV_CO_GUARDAR' THEN 'Consideraci' + CHAR(243) + 'n guardada.'
                    WHEN 'PV_CO_BORRAR'  THEN 'Consideraci' + CHAR(243) + 'n eliminada.'
                    WHEN 'PV_RE_GUARDAR' THEN 'Reuni' + CHAR(243) + 'n de lanzamiento guardada' + CASE WHEN @L_T15 = '1' THEN ': la acci' + CHAR(243) + 'n qued' + CHAR(243) + ' cumplida.' ELSE '.' END
                    WHEN 'PV_RE_BORRAR'  THEN 'Reuni' + CHAR(243) + 'n de lanzamiento eliminada.'
                    WHEN 'PV_IN_GUARDAR' THEN CASE WHEN @LZ_ID IS NULL THEN 'Proyecto iniciado: pas' + CHAR(243) + ' a En curso' + CASE WHEN EXISTS (SELECT 1 FROM @LZ_RG) THEN ' y se gener' + CHAR(243) + ' la carga del plan para el consultor l' + CHAR(237) + 'der.' ELSE '.' END ELSE 'Inicio del proyecto actualizado.' END
                    WHEN 'PV_IN_BORRAR'  THEN 'Se deshizo el inicio: el proyecto volvi' + CHAR(243) + ' a Confirmado.'
                    ELSE '' END;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @ERR = LEFT('No se pudo grabar: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
        END;
    END;
    /* mail al consultor lider al iniciar el proyecto (despues de grabar: si falla, el inicio queda).
       Plantilla PROYECTO_INICIO_CONSULTOR (VCT_PRM_EMAIL_TEMPLATES); destino y CC = lo cargado en el modal. */
    IF @B_FLAG = '1' AND @B_CMD = 'PV_IN_GUARDAR' AND @ERR = '' AND @MSG <> '' AND ISNULL(@LZ_ID, 0) = 0 AND @B_T13 = '1'
    BEGIN
        DECLARE @IM_PERFIL SYSNAME, @IM_LIDER INT, @IM_ANA INT, @IM_ACC INT, @IM_ASU VARCHAR(500), @IM_BODY VARCHAR(MAX),
                @IM_NOR VARCHAR(MAX) = '', @IM_EQ VARCHAR(MAX) = '', @IM_PLAN VARCHAR(10) = '', @IM_ERR VARCHAR(500) = '';
        DECLARE @IM_PV TABLE (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));
        SELECT TOP 1 @IM_PERFIL = P.name FROM msdb.dbo.sysmail_profile P
        JOIN msdb.dbo.sysmail_principalprofile PP ON PP.profile_id = P.profile_id WHERE PP.is_default = 1 ORDER BY P.profile_id;
        SELECT TOP 1 @IM_LIDER = EQ.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'CONSULTOR_LIDER'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.ID;
        SELECT TOP 1 @IM_ANA = EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
        SELECT TOP 1 @IM_ACC = A.ID, @IM_PLAN = CONVERT(VARCHAR(10), A.FECHA_VENCIMIENTO, 103)
        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK) ON R.ID = A.ID_REGLA_ORIGEN AND R.CODIGO_EVENTO = 'PROYECTO_INICIADO'
        WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID DESC;
        SELECT @IM_NOR = @IM_NOR + CASE WHEN @IM_NOR = '' THEN '' ELSE ', ' END + ISNULL(N.DESCRIPCION,'')
        FROM (SELECT DISTINCT ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS WITH(NOLOCK) WHERE ID_PROYECTO = @ID_PROYECTO) PN
        JOIN dbo.VCT_PRM_NORMAS N WITH(NOLOCK) ON N.ID = PN.ID_NORMA ORDER BY N.DESCRIPCION;
        SELECT @IM_EQ = @IM_EQ + CASE WHEN @IM_EQ = '' THEN '' ELSE ', ' END + X.NOM + ' (' + X.ROL + ')'
        FROM (SELECT DISTINCT LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))) AS NOM, ISNULL(R.DESCRIPCION,'') AS ROL
              FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
              JOIN dbo.VCT_CONSULTORES C WITH(NOLOCK) ON C.ID = EQ.ID_CONSULTOR
              LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL
              WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'CONSULTOR') X
        ORDER BY X.NOM;
        BEGIN TRY
            IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK) WHERE CODIGO = 'PROYECTO_INICIO_CONSULTOR' AND ESTADO = 'ACTIVO')
                RAISERROR('no existe la plantilla activa PROYECTO_INICIO_CONSULTOR en VCT_PRM_EMAIL_TEMPLATES.', 16, 1);
            IF @IM_PERFIL IS NULL RAISERROR('no hay un perfil de Database Mail predeterminado en msdb.', 16, 1);
            INSERT INTO @IM_PV EXEC dbo.VCT_MAIN_SEND_EMAIL @CODIGO = 'PROYECTO_INICIO_CONSULTOR', @ID_CONSULTOR = @IM_LIDER, @ID_PROYECTO = @ID_PROYECTO,
                                    @ID_ANALISTA = @IM_ANA, @ID_CLIENTE = @LZ_CLI, @PROFILE_NAME = NULL;
            SELECT TOP 1 @IM_ASU = ASUNTO, @IM_BODY = HTML_CONTENIDO FROM @IM_PV;
            SET @IM_ASU = REPLACE(REPLACE(REPLACE(ISNULL(@IM_ASU,''), '{{CODIGO_PROYECTO}}', ISNULL(@LZ_COD,'')), '{{PROYECTO}}', ISNULL(@LZ_NOM,'')), '{{FECHA_PLAN}}', @IM_PLAN);
            SET @IM_BODY = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@IM_BODY,''),
                               '{{CODIGO_PROYECTO}}', ISNULL(@LZ_COD,'')), '{{PROYECTO}}', REPLACE(REPLACE(REPLACE(ISNULL(@LZ_NOM,''),'&','&amp;'),'<','&lt;'),'>','&gt;')),
                               '{{NORMAS}}', REPLACE(REPLACE(REPLACE(@IM_NOR,'&','&amp;'),'<','&lt;'),'>','&gt;')),
                               '{{EQUIPO}}', REPLACE(REPLACE(REPLACE(@IM_EQ,'&','&amp;'),'<','&lt;'),'>','&gt;')),
                               '{{FECHA_PLAN}}', @IM_PLAN);
            EXEC msdb.dbo.sp_send_dbmail @profile_name = @IM_PERFIL, @recipients = @L_T14, @copy_recipients = @L_T15,
                                         @subject = @IM_ASU, @body = @IM_BODY, @body_format = 'HTML';
            IF @IM_ACC IS NOT NULL
                INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@IM_ACC, 'EMAIL_ENVIADO', LEFT('Plantilla PROYECTO_INICIO_CONSULTOR a ' + @L_T14 + CASE WHEN @L_T15 <> '' THEN ' (CC ' + @L_T15 + ')' ELSE '' END + '.', 2000), 'SISTEMA', GETDATE(), @IAGENTE);
            SET @MSG = LEFT(@MSG + ' Mail enviado a ' + @L_T14 + '.', 1000);
        END TRY
        BEGIN CATCH
            SET @IM_ERR = LEFT(ERROR_MESSAGE(), 500);
            IF @IM_ACC IS NOT NULL
                INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@IM_ACC, 'EMAIL_NO_ENVIADO', LEFT('Plantilla PROYECTO_INICIO_CONSULTOR: ' + @IM_ERR, 2000), 'SISTEMA', GETDATE(), @IAGENTE);
            SET @MSG = LEFT(@MSG + ' El mail no se pudo enviar: ' + @IM_ERR, 1000);
        END CATCH;
    END;
    SET @VOLVER = CASE WHEN @B_FLAG = '1' AND @B_CMD = 'PV_ASIGNAR' THEN 'equipo' ELSE @VOLVER END;

    /* ---------- equipo ---------- */
    CREATE TABLE #EQ (ID INT, TIPO VARCHAR(20), ID_ENT INT, NOMBRE VARCHAR(300), INI VARCHAR(4), ROL_COD VARCHAR(50),
                      ROL_DES VARCHAR(150), ROL_ORD INT, DESDE DATETIME, OBS VARCHAR(MAX));
    INSERT INTO #EQ
    SELECT EQ.ID, EQ.TIPO_MIEMBRO, CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END,
           X.NOMBRE, UPPER(LEFT(ISNULL(X.N1,''),1) + LEFT(ISNULL(X.A1,''),1)), R.CODIGO, R.DESCRIPCION, ISNULL(R.ORDEN, 99),
           EQ.FECHA_DESDE, EQ.OBSERVACIONES
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL
    OUTER APPLY (
        SELECT TOP 1 LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))) AS NOMBRE, E.NOMBRES AS N1, E.APELLIDOS AS A1
        FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK) WHERE EQ.TIPO_MIEMBRO = 'EMPLEADO' AND E.ID = EQ.ID_EMPLEADO
        UNION ALL
        SELECT TOP 1 LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),
               CONVERT(VARCHAR(150),C.NOMBRES), CONVERT(VARCHAR(150),C.APELLIDOS)
        FROM dbo.VCT_CONSULTORES C WITH(NOLOCK) WHERE EQ.TIPO_MIEMBRO = 'CONSULTOR' AND C.ID = EQ.ID_CONSULTOR
    ) X
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO';
    /* una fila por integrante y rol aunque este cargado por servicio */
    DELETE E FROM #EQ E
    WHERE EXISTS (SELECT 1 FROM #EQ E2 WHERE E2.TIPO = E.TIPO AND E2.ID_ENT = E.ID_ENT AND ISNULL(E2.ROL_COD,'') = ISNULL(E.ROL_COD,'') AND E2.ID < E.ID);

    DECLARE @ANALISTA_NOM VARCHAR(300) = '', @EQ_META VARCHAR(1000) = '', @HAY_LIDER BIT = 0, @N_CONS INT = 0;
    SELECT TOP 1 @ANALISTA_NOM = NOMBRE FROM #EQ WHERE ROL_COD = 'ANALISTA' ORDER BY ID;
    IF EXISTS (SELECT 1 FROM #EQ WHERE ROL_COD = 'CONSULTOR_LIDER') SET @HAY_LIDER = 1;
    SELECT @N_CONS = COUNT(*) FROM #EQ WHERE TIPO = 'CONSULTOR';
    SELECT @EQ_META = @EQ_META + CASE WHEN @EQ_META = '' THEN '' ELSE ' &middot; ' END + INI + ' ' + LOWER(ISNULL(ROL_DES,''))
    FROM #EQ ORDER BY ROL_ORD, ID;
    SET @EQ_META = REPLACE(REPLACE(@EQ_META, '<', '&lt;'), '>', '&gt;');

    /* ---------- servicios y normas ---------- */
    CREATE TABLE #SV (ID INT, ID_SERVICIO INT, COD VARCHAR(50), DES VARCHAR(300), NOMBRE VARCHAR(300), LUGAR VARCHAR(300),
                      INI DATETIME, FIN DATETIME, PROY NUMERIC(18,2), PROG NUMERIC(18,2), EJEC NUMERIC(18,2), ORDEN INT,
                      EST_COD VARCHAR(30), EST_DES VARCHAR(100), IDX INT NULL);
    INSERT INTO #SV (ID, ID_SERVICIO, COD, DES, NOMBRE, LUGAR, INI, FIN, PROY, PROG, EJEC, ORDEN, EST_COD, EST_DES)
    SELECT S.ID, S.ID_SERVICIO, UPPER(ISNULL(PS.CODIGO,'')), ISNULL(PS.DESCRIPCION,''), ISNULL(S.NOMBRE,''), ISNULL(S.LUGAR,''),
           S.FECHA_INICIO, S.FECHA_FIN, ISNULL(S.TOTAL_HORAS_PROYECTADAS, 0), 0, 0, S.ORDEN, E.CODIGO, E.DESCRIPCION
    FROM dbo.VCT_PROYECTOS_SERVICIOS S WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK) ON PS.ID = S.ID_SERVICIO
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E WITH(NOLOCK) ON E.ID = S.ID_ESTADO
    WHERE S.ID_PROYECTO = @ID_PROYECTO;

    /* horas de la agenda: ejecutadas = visitas pasadas, programadas = visitas desde hoy */
    UPDATE S SET
        EJEC = ISNULL((SELECT SUM(ISNULL(VC.HORAS_EJECUTADAS, ISNULL(VC.HORAS_PLANIFICADAS,0)))
                       FROM dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK)
                       JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) ON VC.ID_VISITA = V.ID
                       WHERE V.ID_PROYECTO_SERVICIO = S.ID AND V.FECHA_DESDE < @HOY), 0),
        PROG = ISNULL((SELECT SUM(ISNULL(VC.HORAS_PLANIFICADAS,0))
                       FROM dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK)
                       JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) ON VC.ID_VISITA = V.ID
                       WHERE V.ID_PROYECTO_SERVICIO = S.ID AND V.FECHA_DESDE >= @HOY), 0)
    FROM #SV S;

    UPDATE S SET IDX = (SELECT COUNT(*) FROM #SV S2 WHERE S2.ORDEN < S.ORDEN OR (S2.ORDEN = S.ORDEN AND S2.ID <= S.ID)) FROM #SV S;

    DECLARE @H_EJEC NUMERIC(18,2) = 0, @H_PROG NUMERIC(18,2) = 0, @H_SRV NUMERIC(18,2) = 0;
    SELECT @H_EJEC = ISNULL(SUM(EJEC),0), @H_PROG = ISNULL(SUM(PROG),0), @H_SRV = ISNULL(SUM(PROY),0) FROM #SV;

    CREATE TABLE #NO (ID_NORMA INT, DES VARCHAR(300), PRINCIPAL BIT);
    INSERT INTO #NO
    SELECT PN.ID_NORMA, MAX(ISNULL(N.DESCRIPCION,'')), MAX(CONVERT(INT, ISNULL(PN.PRINCIPAL,0)))
    FROM dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_NORMAS N WITH(NOLOCK) ON N.ID = PN.ID_NORMA
    WHERE PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA'
    GROUP BY PN.ID_NORMA;   /* una fila por norma aunque este cargada por servicio */
    DECLARE @N_NOR INT = 0, @NOR_META VARCHAR(2000) = '';
    SELECT @N_NOR = COUNT(*) FROM #NO;
    SELECT @NOR_META = @NOR_META + CASE WHEN @NOR_META = '' THEN '' ELSE ' &middot; ' END
                     + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;')
    FROM #NO ORDER BY PRINCIPAL DESC, DES;

    /* ---------- acciones del proyecto ---------- */
    CREATE TABLE #A (ID INT, TITULO VARCHAR(300), TIPO VARCHAR(150), SUB_COD VARCHAR(50), SUB_DES VARCHAR(150),
                     EST_COD VARCHAR(30), EST_DES VARCHAR(100), ES_FINAL BIT, VENCE DATETIME, CIERRE DATETIME, CREA DATETIME,
                     RESP VARCHAR(300), RESP_INI VARCHAR(4), AREA VARCHAR(150), MIA BIT, SIT CHAR(1));
    INSERT INTO #A
    SELECT A.ID, ISNULL(A.TITULO,''), ISNULL(T.DESCRIPCION,''), ISNULL(ST.CODIGO,''), ISNULL(ST.DESCRIPCION,''),
           ISNULL(E.CODIGO,''), ISNULL(E.DESCRIPCION,''), ISNULL(E.ES_FINAL,0), A.FECHA_VENCIMIENTO, A.FECHA_CIERRE, A.FECHA_CREACION,
           ISNULL(RP.NOMBRE,''), ISNULL(RP.INI,''),
           ISNULL(RP.AREA, ''),
           CASE WHEN RP.TIPO_ENTIDAD = 'EMPLEADO' AND RP.ID_ENTIDAD = @EMP_U THEN 1
                WHEN RP.TIPO_ENTIDAD = 'CONSULTOR' AND RP.ID_ENTIDAD = @CONS_U THEN 1 ELSE 0 END,
           CASE WHEN ISNULL(E.ES_FINAL,0) = 1 THEN 'C'
                WHEN A.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, A.FECHA_VENCIMIENTO) < CONVERT(DATE, @HOY) THEN 'V'
                ELSE 'A' END
    FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) ON T.ID = A.ID_TIPO
    LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
    OUTER APPLY (
        SELECT TOP 1 AP.TIPO_ENTIDAD, AP.ID_ENTIDAD, Q.NOMBRE, Q.INI,
               ISNULL((SELECT TOP 1 X.ROL_DES FROM #EQ X WHERE X.TIPO = AP.TIPO_ENTIDAD AND X.ID_ENT = AP.ID_ENTIDAD ORDER BY X.ROL_ORD),
                      CASE AP.TIPO_ENTIDAD
                           WHEN 'EMPLEADO' THEN ISNULL((SELECT TOP 1 ISNULL(NULLIF(LTRIM(RTRIM(G9.Name)),''), GM9.GroupId)
                                                        FROM dbo.VCT_EMPLEADOS E9 WITH(NOLOCK)
                                                        INNER JOIN dbo.GroupsUserMembers GM9 WITH(NOLOCK) ON UPPER(LTRIM(RTRIM(GM9.UserMemberId))) = UPPER(LTRIM(RTRIM(E9.ID_USUARIO_SEGURIDAD)))
                                                        LEFT JOIN dbo.Groups G9 WITH(NOLOCK) ON UPPER(LTRIM(RTRIM(G9.Id))) = UPPER(LTRIM(RTRIM(GM9.GroupId)))
                                                        WHERE E9.ID = AP.ID_ENTIDAD ORDER BY GM9.GroupId), 'Empleado')
                           WHEN 'CONSULTOR' THEN 'Consultor' ELSE ISNULL(AP.TIPO_ENTIDAD,'') END) AS AREA
        FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
        OUTER APPLY (
            SELECT TOP 1 LTRIM(RTRIM(ISNULL(E2.APELLIDOS,'') + ', ' + ISNULL(E2.NOMBRES,''))) AS NOMBRE,
                   UPPER(LEFT(ISNULL(E2.NOMBRES,''),1) + LEFT(ISNULL(E2.APELLIDOS,''),1)) AS INI
            FROM dbo.VCT_EMPLEADOS E2 WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'EMPLEADO' AND E2.ID = AP.ID_ENTIDAD
            UNION ALL
            SELECT TOP 1 LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C2.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C2.NOMBRES),''))),
                   UPPER(LEFT(ISNULL(CONVERT(VARCHAR(150),C2.NOMBRES),''),1) + LEFT(ISNULL(CONVERT(VARCHAR(150),C2.APELLIDOS),''),1))
            FROM dbo.VCT_CONSULTORES C2 WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'CONSULTOR' AND C2.ID = AP.ID_ENTIDAD
        ) Q
        WHERE AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO'
        ORDER BY AP.PRINCIPAL DESC, AP.ID
    ) RP
    WHERE A.ID_PROYECTO = @ID_PROYECTO;

    DECLARE @N_ABIERTAS INT = 0, @N_VENCIDAS INT = 0, @N_TOT_ACC INT = 0, @PROX DATETIME, @N_MIAS INT = 0;
    SELECT @N_TOT_ACC = COUNT(*), @N_ABIERTAS = SUM(CASE WHEN SIT <> 'C' THEN 1 ELSE 0 END),
           @N_VENCIDAS = SUM(CASE WHEN SIT = 'V' THEN 1 ELSE 0 END),
           @N_MIAS = SUM(CASE WHEN SIT <> 'C' AND MIA = 1 THEN 1 ELSE 0 END),
           @PROX = MIN(CASE WHEN SIT <> 'C' THEN VENCE END)
    FROM #A;
    SET @N_ABIERTAS = ISNULL(@N_ABIERTAS,0); SET @N_VENCIDAS = ISNULL(@N_VENCIDAS,0); SET @N_MIAS = ISNULL(@N_MIAS,0);

    /* puede asignar: responsable de la accion abierta ASIGNACION_CONSULTOR, o EDIT de PROYECTOS */
    DECLARE @PUEDE_ASIG BIT = @PUEDE_EDIT;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT <> 'C' AND MIA = 1) SET @PUEDE_ASIG = 1;

    /* boton Gestionar segun el subtipo de la accion */
    DECLARE @GEST_ASIG VARCHAR(300) = 'data-vct-pv-open="asignar"';

    /* ---------- lanzamiento (control) ---------- */
    DECLARE @L_CONS BIT = @HAY_LIDER, @L_DATOS BIT = 0, @L_REU BIT = 0, @L_DATOS_TXT VARCHAR(200) = 'pendiente', @L_REU_TXT VARCHAR(200) = 'pendiente', @L_OK INT = 0;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_DATOS_ENTRADA' AND EST_COD = 'CUMPLIDA') SET @L_DATOS = 1;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'LANZAMIENTO' AND EST_COD = 'CUMPLIDA') SET @L_REU = 1;
    SELECT TOP 1 @L_DATOS_TXT = CASE WHEN SIT = 'C' THEN 'completo' ELSE 'pendiente' + ISNULL(' &middot; vence ' + CONVERT(VARCHAR(5), VENCE, 103), '') END
    FROM #A WHERE SUB_COD = 'CARGA_DATOS_ENTRADA' ORDER BY ID DESC;
    SELECT TOP 1 @L_REU_TXT = CASE WHEN SIT = 'C' THEN 'realizada' ELSE 'pendiente' + ISNULL(' &middot; vence ' + CONVERT(VARCHAR(5), VENCE, 103), '') END
    FROM #A WHERE SUB_COD = 'LANZAMIENTO' ORDER BY ID DESC;
    DECLARE @LIDER_TXT VARCHAR(400) = '';
    SELECT TOP 1 @LIDER_TXT = CONVERT(VARCHAR(5), DESDE, 103) + ' &middot; ' + INI + ' l&iacute;der' FROM #EQ WHERE ROL_COD = 'CONSULTOR_LIDER' ORDER BY ID;
    /* ---------- lanzamiento: registros y control (PV_LANZ_V1) ---------- */
    CREATE TABLE #LZ (ID INT, TIPO VARCHAR(20), NRO VARCHAR(300), TEMAS VARCHAR(1000), PART VARCHAR(500), OBS VARCHAR(2000),
                      FECHA DATETIME, CIERRE DATETIME, ID_CONS INT, CONS_NOM VARCHAR(300), SRV VARCHAR(300), OBL INT, ORD INT,
                      ITEM INT, USR VARCHAR(100), FUPD DATETIME);
    INSERT INTO #LZ
    SELECT D.ID, D.TIPO, ISNULL(D.NRO_INTERNO,''), ISNULL(D.TEMAS,''), ISNULL(D.PARTICIPANTES,''), ISNULL(D.OBSERVACIONES,''),
           D.FECHA_DOCUMENTO, D.FECHA_CIERRE, D.ID_CONSULTOR,
           LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + CASE WHEN C.ID IS NULL THEN '' ELSE ', ' END + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),
           ISNULL(M.SRV,''), CONVERT(INT, ISNULL(I.OBLIGATORIO,0)), ISNULL(I.ORDEN, 999), I.ID,
           ISNULL(D.USUARIO_UPD, ISNULL(D.USUARIO_ALTA,'')), ISNULL(D.FECHA_UPD, D.FECHA_ALTA)
    FROM dbo.VCT_PROYECTOS_DOCUMENTOS D WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
           ON D.TIPO = 'MG' AND D.NRO_INTERNO LIKE 'ITEM:%' AND LEN(D.NRO_INTERNO) BETWEEN 6 AND 14
          AND SUBSTRING(D.NRO_INTERNO, 6, 20) NOT LIKE '%[^0-9]%'
          AND I.ID = CASE WHEN SUBSTRING(D.NRO_INTERNO, 6, 20) NOT LIKE '%[^0-9]%' AND LEN(D.NRO_INTERNO) BETWEEN 6 AND 14 THEN CONVERT(INT, SUBSTRING(D.NRO_INTERNO, 6, 20)) END
    LEFT JOIN #MIN M ON M.ID_DOCUMENTO = D.ID_DOCUMENTO
    LEFT JOIN dbo.VCT_CONSULTORES C WITH(NOLOCK) ON C.ID = D.ID_CONSULTOR
    WHERE D.ID_PROYECTO = @ID_PROYECTO
      AND (   (D.TIPO = 'MG' AND (D.NRO_INTERNO LIKE 'ITEM:%' OR D.NRO_INTERNO = 'LIBRE'))
           OR (D.TIPO = 'CONS' AND ISNULL(D.OBSERVACIONES,'') <> '' AND D.NRO_INTERNO IN ('INTERNA','CONSULTOR','CLIENTE'))
           OR D.TIPO IN ('LANZ','INICIO'));

    /* preguntas de las minutas del proyecto (sin el grupo CIERRE) */
    CREATE TABLE #IT (ID INT, DES VARCHAR(400), OBL INT, ORD INT, SRV VARCHAR(300), CARGADO BIT);
    INSERT INTO #IT
    SELECT I.ID, ISNULL(I.DESCRIPCION,''), CONVERT(INT, ISNULL(I.OBLIGATORIO,0)), ISNULL(I.ORDEN, 999), M.SRV,
           CASE WHEN EXISTS (SELECT 1 FROM #LZ L WHERE L.TIPO = 'MG' AND L.ITEM = I.ID) THEN 1 ELSE 0 END
    FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
    INNER JOIN #MIN M ON M.ID_DOCUMENTO = I.ID_DOCUMENTO
    WHERE I.ACTIVO = 1 AND UPPER(ISNULL(I.GRUPO,'')) <> 'CIERRE';

    DECLARE @N_SRV_MIN INT = (SELECT COUNT(DISTINCT SRV) FROM #MIN),
            @DE_OBL INT = (SELECT COUNT(*) FROM #IT WHERE OBL = 1),
            @DE_OBL_OK INT = (SELECT COUNT(*) FROM #IT WHERE OBL = 1 AND CARGADO = 1),
            @N_DE INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'MG'),
            @N_CO INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'CONS'),
            @N_RE INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'LANZ'),
            @N_IN INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'INICIO'),
            @DE_ABIERTA BIT = 0, @L_CO BIT = 0, @IN_OK BIT = 0, @IN_FALTA VARCHAR(500) = '', @RE_FECHA DATETIME;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_DATOS_ENTRADA' AND SIT <> 'C') SET @DE_ABIERTA = 1;
    IF @N_CO > 0 SET @L_CO = 1;
    SELECT TOP 1 @RE_FECHA = FECHA FROM #LZ WHERE TIPO = 'LANZ' AND CIERRE IS NOT NULL ORDER BY FECHA DESC;
    SET @IN_FALTA = CASE WHEN @L_CONS = 0 THEN ', consultor l&iacute;der' ELSE '' END
                  + CASE WHEN @L_DATOS = 0 THEN ', datos de entrada' ELSE '' END
                  + CASE WHEN @L_CO = 0 THEN ', consideraciones' ELSE '' END
                  + CASE WHEN @L_REU = 0 THEN ', reuni&oacute;n de lanzamiento' ELSE '' END;
    IF @IN_FALTA = '' SET @IN_OK = 1
    ELSE SET @IN_FALTA = 'Falta: ' + SUBSTRING(@IN_FALTA, 3, 500);
    SET @L_OK = CONVERT(INT, @L_CONS) + CONVERT(INT, @L_DATOS) + CONVERT(INT, @L_CO) + CONVERT(INT, @L_REU);


    /* ---------- numeros ---------- */
    DECLARE @PCT_H INT = CASE WHEN @H_PROY > 0 THEN CONVERT(INT, ROUND(@H_EJEC * 100.0 / @H_PROY, 0)) ELSE 0 END,
            @PCT_T INT = 0, @DIAS_FIN INT = NULL;
    IF @F_INI IS NOT NULL AND @F_FIN IS NOT NULL AND @F_FIN > @F_INI
        SET @PCT_T = CASE WHEN @HOY <= @F_INI THEN 0 WHEN @HOY >= @F_FIN THEN 100
                          ELSE CONVERT(INT, ROUND(DATEDIFF(DAY, @F_INI, @HOY) * 100.0 / DATEDIFF(DAY, @F_INI, @F_FIN), 0)) END;
    IF @F_FIN IS NOT NULL SET @DIAS_FIN = DATEDIFF(DAY, @HOY, @F_FIN);
    IF @PCT_H > 100 SET @PCT_H = 100;
    DECLARE @H_DISP NUMERIC(18,2) = @H_PROY - @H_EJEC - @H_PROG;

    /* ==================================================================
       HTML
       ================================================================== */
    DECLARE @H VARCHAR(MAX) = '', @X VARCHAR(MAX) = '';

    /* alertas del comando */
    DECLARE @ALERTA VARCHAR(MAX) = CASE
        WHEN @ERR <> '' THEN '<div class="vct-pv-alert is-error" data-vct-pv-alert><span data-vct-icon="alert-triangle"></span><span>' + REPLACE(REPLACE(@ERR,'<','&lt;'),'>','&gt;') + '</span></div>'
        WHEN @MSG <> '' THEN '<div class="vct-pv-alert is-ok" data-vct-pv-alert><span data-vct-icon="check"></span><span>' + REPLACE(REPLACE(@MSG,'<','&lt;'),'>','&gt;') + '</span></div>'
        ELSE '' END;

    /* pendientes del usuario en este proyecto: van en la campanita del encabezado (PV_BELL_V1) */
    DECLARE @PEND VARCHAR(MAX) = '';
    SELECT @PEND = ISNULL((
        SELECT
            '<li class="vct-pv-bell-item' + CASE WHEN SIT = 'V' THEN ' is-late' ELSE '' END + '">'
          + '<span class="vct-pv-bell-item-icon"><span data-vct-icon="' + CASE WHEN SIT = 'V' THEN 'alert-triangle' ELSE 'user-check' END + '"></span></span>'
          + '<span class="vct-pv-bell-item-main"><span class="vct-pv-bell-item-title">' + REPLACE(REPLACE(REPLACE(TITULO,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
          + '<span class="vct-pv-bell-item-meta">' + REPLACE(REPLACE(REPLACE(SUB_DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
          + CASE WHEN VENCE IS NULL THEN '' WHEN SIT = 'V' THEN '<span class="vct-pv-bell-item-date">Venci&oacute; el ' + CONVERT(VARCHAR(10), VENCE, 103) + '</span>'
                 ELSE '<span class="vct-pv-bell-item-date">Vence el ' + CONVERT(VARCHAR(10), VENCE, 103) + '</span>' END + '</span>'
          + '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-bell-go '
          + CASE WHEN SUB_COD = 'ASIGNACION_CONSULTOR' AND @PUEDE_ASIG = 1 THEN @GEST_ASIG
                 WHEN SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') THEN 'data-vct-pv-goto="lanzamiento"'
                 ELSE 'data-vct-pv-goto="acciones"' END
          + '><span>Gestionar</span></button>'
          + '</li>'
        FROM #A WHERE SIT <> 'C' AND MIA = 1
        ORDER BY CASE WHEN VENCE IS NULL THEN 1 ELSE 0 END, VENCE, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    DECLARE @N_MIAS_V INT = (SELECT COUNT(*) FROM #A WHERE SIT = 'V' AND MIA = 1);
    DECLARE @BELL VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-pv-bell" data-vct-pv-bell>'
        + '<button type="button" class="vct-360-alerts vct-pv-bell-btn' + CASE WHEN @N_MIAS_V > 0 THEN ' is-late' ELSE '' END + '" data-vct-pv-bell-toggle aria-expanded="false" title="Acciones pendientes a su cargo en este proyecto">'
        + '<span class="vct-360-alert-icon"><span data-vct-icon="bell"></span></span>'
        + CASE WHEN @N_MIAS > 0 THEN '<span class="vct-360-alert-count">' + CONVERT(VARCHAR(10), @N_MIAS) + '</span>' ELSE '' END + '</button>'
        + '<div class="vct-pv-bell-panel" data-vct-pv-bell-panel hidden>'
        + '<div class="vct-pv-bell-head"><b>Pendientes a su cargo</b><span>' + CASE WHEN @N_MIAS = 0 THEN 'al d&iacute;a' ELSE CONVERT(VARCHAR(10), @N_MIAS) + ' en este proyecto' END + '</span></div>'
        + CASE WHEN @PEND = '' THEN '<p class="vct-pv-bell-empty">No tiene acciones pendientes en este proyecto.</p>'
               ELSE '<ul class="vct-pv-bell-list">' + @PEND + '</ul>' END
        + '</div></div>';

    /* ---------- encabezado: titulo + estado + riesgo; subtitulo = cliente + servicios ---------- */
    DECLARE @INI_P VARCHAR(4) = UPPER(LEFT(LTRIM(ISNULL(@NOM,'')),1) + ISNULL(SUBSTRING(LTRIM(ISNULL(@NOM,'')), CHARINDEX(' ', LTRIM(ISNULL(@NOM,''))) + 1, 1), ''));
    DECLARE @SRV_ICONS VARCHAR(MAX) = '';
    SELECT @SRV_ICONS = ISNULL((
        SELECT '<span class="vctdg-svc is-' + LOWER(LEFT(ISNULL(PS.CODIGO,'xx'),2))
             + CASE WHEN EXISTS (SELECT 1 FROM #SV S WHERE S.ID_SERVICIO = PS.ID) THEN ' is-on' ELSE '' END + '" title="'
             + REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'"',''),'<','')
             + CASE WHEN EXISTS (SELECT 1 FROM #SV S WHERE S.ID_SERVICIO = PS.ID) THEN '' ELSE ' (no incluido)' END + '">'
             + '<span data-vct-icon="' + CASE UPPER(LEFT(ISNULL(PS.CODIGO,''),2)) WHEN 'AU' THEN 'clipboard-check' WHEN 'CA' THEN 'users' ELSE 'briefcase' END + '"></span></span>'
        FROM dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK)
        WHERE ISNULL(PS.ESTADO,'ACTIVO') = 'ACTIVO' OR EXISTS (SELECT 1 FROM #SV S WHERE S.ID_SERVICIO = PS.ID)
        ORDER BY PS.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SET @H = CONVERT(VARCHAR(MAX), '') + '<div class="vct-360-breadcrumb-row"><nav class="vct-breadcrumb-simple" aria-label="Breadcrumb">'
        + '<button type="button" class="vct-breadcrumb-link" data-vct-v360-back data-vct-sidebar-mod="3">Proyectos</button>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-item">' + @E_CLI + '</span>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-item">Vista 360</span>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-current">(' + @E_COD + ') ' + LEFT(@E_NOM, 60) + '</span></nav></div>'
        + '<div class="vct-360-client-strip"><div class="vct-360-card-left">'
        + '<div class="vct-360-avatar">' + REPLACE(REPLACE(@INI_P,'<',''),'>','') + '</div>'
        + '<div class="vct-360-identity"><div class="vct-360-identity-title"><h1>(' + @E_COD + ') ' + @E_NOM + '</h1>'
        + '<span class="vct-360-badge ' + CASE @EST_COD WHEN 'ENCURSO' THEN 'is-active' WHEN 'CONFIRMADO' THEN 'is-planned' WHEN 'CANCELADO' THEN 'is-cancel' ELSE 'is-neutral' END + '">' + @E_EST + '</span>'
        + CASE WHEN ISNULL(@RIESGO,'') = '' THEN ''
               ELSE '<span class="vct-360-badge vct-pv-riesgo ' + CASE UPPER(LTRIM(RTRIM(@RIESGO))) WHEN 'ALTO' THEN 'is-alto' WHEN 'MEDIO' THEN 'is-medio' WHEN 'BAJO' THEN 'is-bajo' ELSE 'is-neutral' END + '">Riesgo ' + LOWER(@E_RIESGO) + '</span>' END
        + '</div>'
        + '<div class="vct-pv-subtitle"><span class="vct-pv-cli">' + @E_CLI + '</span>'
        + CASE WHEN @SRV_ICONS = '' THEN '' ELSE '<span class="vctdg-svc-set">' + @SRV_ICONS + '</span>' END + '</div>'
        + '</div></div>'
        + '<div class="vct-360-card-right">'
        + @BELL
        + '<span class="vct-360-card-divider" aria-hidden="true"></span>'
        + '<div class="vct-360-last-management"><span class="vct-360-inline-stat-icon"><span data-vct-icon="calendar"></span></span><span><span class="vct-360-inline-stat-label">Pr&oacute;xima acci&oacute;n</span><span class="vct-360-inline-stat-value">' + ISNULL(CONVERT(VARCHAR(10), @PROX, 103), '-') + '</span></span></div>'
        + '</div></div>';

    /* ---------- KPIs ---------- */
    SET @H = @H + '<div class="vct-360-content-shell">' + @ALERTA + '<div class="vct-360-stats-row">'
        + '<div class="vct-360-stat" data-vct-tone="blue"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Horas proyectadas</span><b>' + CONVERT(VARCHAR(20), CONVERT(INT, @H_PROY)) + '</b><small>' + CONVERT(VARCHAR(20), CONVERT(INT, @H_EJEC)) + ' ejecutadas &middot; ' + CONVERT(VARCHAR(20), CONVERT(INT, @H_PROG)) + ' programadas</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span></div>'
        + CASE WHEN @EST_COD = 'CONFIRMADO'
               THEN '<div class="vct-360-stat" data-vct-tone="mint"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Lanzamiento</span><b>' + CONVERT(VARCHAR(5), @L_OK) + ' / 4</b><small>pasos completos</small></span><span class="vct-360-stat-icon"><span data-vct-icon="check"></span></span></div>'
               ELSE '<div class="vct-360-stat" data-vct-tone="mint"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Avance horas</span><b>' + CONVERT(VARCHAR(5), @PCT_H) + '%</b><small>' + CONVERT(VARCHAR(20), CONVERT(INT, @H_DISP)) + ' h disponibles</small></span><span class="vct-360-stat-icon"><span data-vct-icon="chart-bar"></span></span></div>' END
        + '<div class="vct-360-stat" data-vct-tone="violet"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Avance plan</span><b>&ndash;</b><small>se genera al iniciar</small></span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
        + CASE WHEN @EST_COD = 'CONFIRMADO'
               THEN '<div class="vct-360-stat" data-vct-tone="amber"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Acciones pendientes</span><b>' + CONVERT(VARCHAR(10), @N_ABIERTAS) + '</b><small>' + CASE WHEN @PROX IS NULL THEN 'sin vencimientos' ELSE 'pr&oacute;xima vence ' + CONVERT(VARCHAR(5), @PROX, 103) END + '</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clipboard-check"></span></span></div>'
               ELSE '<div class="vct-360-stat" data-vct-tone="amber"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Acciones vencidas</span><b>' + CONVERT(VARCHAR(10), @N_VENCIDAS) + '</b><small>' + CASE WHEN @DIAS_FIN IS NULL THEN '-' WHEN @DIAS_FIN < 0 THEN 'fin hace ' + CONVERT(VARCHAR(10), -@DIAS_FIN) + ' d&iacute;as' ELSE CONVERT(VARCHAR(10), @DIAS_FIN) + ' d&iacute;as para el fin' END + '</small></span><span class="vct-360-stat-icon"><span data-vct-icon="clipboard-check"></span></span></div>' END
        + '</div>';

    /* ---------- pestanias (orden del workflow; sin submenus) ---------- */
    SET @H = @H + '<div class="vct-360-tabsbar" data-vct-tablist>'
        + '<button type="button" data-vct-tab="resumen" class="is-active"><span data-vct-icon="scan-eye"></span><span>Resumen</span></button>'
        + '<button type="button" data-vct-tab="servicios"><span data-vct-icon="briefcase"></span><span>Servicios</span></button>'
        + '<button type="button" data-vct-tab="normas"><span data-vct-icon="clipboard-check"></span><span>Normas</span></button>'
        + '<button type="button" data-vct-tab="equipo"><span data-vct-icon="users"></span><span>Equipo</span></button>'
        + '<button type="button" data-vct-tab="lanzamiento"><span data-vct-icon="check"></span><span>Lanzamiento</span></button>'
        + '<button type="button" data-vct-tab="plan"><span data-vct-icon="list-checks"></span><span>Parte log&iacute;stico</span></button>'
        + '<button type="button" data-vct-tab="acciones"><span data-vct-icon="clipboard-check"></span><span>Acciones</span>'
        +   CASE WHEN @N_ABIERTAS > 0 THEN '<span class="vct-tab-count' + CASE WHEN @N_VENCIDAS > 0 THEN ' is-alert' ELSE '' END + '">' + CONVERT(VARCHAR(10), @N_ABIERTAS) + '</span>' ELSE '' END + '</button>'
        + '<button type="button" data-vct-tab="agenda"><span data-vct-icon="calendar"></span><span>Agenda</span></button>'
        + '<button type="button" data-vct-tab="admin"><span data-vct-icon="circle-dollar-sign"></span><span>Administraci&oacute;n</span></button>'
        + '<button type="button" data-vct-tab="documentos"><span data-vct-icon="file-text"></span><span>Documentos</span></button>'
        + '</div>';

    /* ======================= RESUMEN ======================= */
    DECLARE @R_SRV VARCHAR(MAX) = '', @R_ULT VARCHAR(MAX) = '';
    SELECT @R_SRV = ISNULL((
        SELECT '<div class="vct-pv-hsrv"><div class="vct-pv-hsrv-top"><b>' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b><span>'
             + CONVERT(VARCHAR(20), CONVERT(INT, EJEC)) + ' + ' + CONVERT(VARCHAR(20), CONVERT(INT, PROG)) + ' / ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h</span></div>'
             + '<div class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN EJEC * 100.0 / PROY > 100 THEN 100 ELSE EJEC * 100.0 / PROY END) ELSE 0 END) + '%"></span>'
             + '<span class="is-prog" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN PROG * 100.0 / PROY > 100 THEN 100 ELSE PROG * 100.0 / PROY END) ELSE 0 END) + '%"></span></div></div>'
        FROM #SV ORDER BY ORDEN, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @R_ULT = ISNULL((
        SELECT TOP 5
            '<tr><td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TITULO,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
          + '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(TIPO,'&','&amp;'),'<','&lt;'),'>','&gt;') + CASE WHEN SUB_DES <> '' THEN ' &middot; ' ELSE '' END + REPLACE(REPLACE(REPLACE(SUB_DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
          + '<td class="vct-text-center"><span class="vctdg-person"><span class="vctdg-avatar is-a" title="' + REPLACE(RESP,'"','') + '">' + RESP_INI + '</span></span></td>'
          + '<td class="vct-text-center">' + CASE WHEN SIT = 'C' AND EST_COD = 'CANCELADA' THEN '<span class="vct-360-badge is-cancel">Cancelada</span>'
                                                  WHEN SIT = 'C' THEN '<span class="vct-360-badge is-active">' + EST_DES + '</span>'
                                                  WHEN SIT = 'V' THEN '<span class="vct-360-badge is-cancel">Vencida</span>'
                                                  ELSE '<span class="vct-360-badge is-planned">' + EST_DES + '</span>' END + '</td>'
          + '<td class="vct-text-center">' + ISNULL(CONVERT(VARCHAR(10), CASE WHEN SIT = 'C' THEN ISNULL(CIERRE, CREA) ELSE ISNULL(VENCE, CREA) END, 103), '-') + '</td></tr>'
        FROM #A ORDER BY ISNULL(CIERRE, CREA) DESC, ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* datos del proyecto (lo que no esta en la card de arriba), en 2 columnas */
    DECLARE @R_SRV_TXT VARCHAR(MAX) = '', @R_NOR_CHIPS VARCHAR(MAX) = '', @F_LIM DATETIME;
    SELECT @R_SRV_TXT = ISNULL((
        SELECT '<span class="vct-pv-srv-line"><span class="vctdg-svc is-' + LOWER(LEFT(CASE WHEN COD = '' THEN 'xx' ELSE COD END, 2)) + ' is-on">'
             + '<span data-vct-icon="' + CASE LEFT(COD, 2) WHEN 'AU' THEN 'clipboard-check' WHEN 'CA' THEN 'users' ELSE 'briefcase' END + '"></span></span>'
             + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h</span>'
        FROM #SV ORDER BY IDX FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @R_NOR_CHIPS = ISNULL((SELECT '<span class="vct-pv-chip is-b">' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
                                  FROM #NO ORDER BY PRINCIPAL DESC, DES FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT TOP 1 @F_LIM = VENCE FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' ORDER BY ID;
    DECLARE @R_DATOS VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="folder"></span></span>Datos del proyecto</h3>'
        +   CASE WHEN @PUEDE_EDIT = 1 THEN '<div class="vct-360-box-actions"><button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-pv-pronto="Editar proyecto"><span data-vct-icon="edit"></span><span>Editar</span></button></div>' ELSE '' END
        + '</div>'
        + '<div class="vct-pv-kv is-2">'
        + '<div class="is-full vct-pv-kv-sec">General</div>'
        + '<div class="is-full"><small>Referencia</small><b class="vct-pv-oneline" title="' + REPLACE(@E_REF,'"','') + '">' + CASE WHEN @E_REF = '' THEN '-' ELSE @E_REF END + '</b></div>'
        + '<div class="is-full vct-pv-kv-sec">Plazo</div>'
        + '<div><small>Fecha de inicio</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103),'-') + '</b></div>'
        + '<div><small>Fecha de fin</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103),'-') + '</b></div>'
        + '<div class="is-full vct-pv-kv-sec">Gesti&oacute;n</div>'
        + '<div><small>Tipo de proyecto</small><b>' + @E_TIPO + '</b></div>'
        + '<div><small>Analista</small>' + CASE WHEN @ANALISTA_NOM = '' THEN '<b>-</b>'
               ELSE '<span class="vct-pv-person"><span class="vctdg-avatar is-a">' + ISNULL((SELECT TOP 1 INI FROM #EQ WHERE ROL_COD = 'ANALISTA' ORDER BY ID), '') + '</span><b>'
                  + REPLACE(REPLACE(REPLACE(@ANALISTA_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b></span>' END + '</div>'
        + '<div class="is-full vct-pv-kv-sec">Situaci&oacute;n</div>'
        + '<div><small>Estado</small><span class="vct-360-badge ' + CASE @EST_COD WHEN 'ENCURSO' THEN 'is-active' WHEN 'CONFIRMADO' THEN 'is-planned' WHEN 'CANCELADO' THEN 'is-cancel' ELSE 'is-neutral' END + '">' + @E_EST + '</span></div>'
        + '<div><small>Nivel de riesgo</small>' + CASE WHEN ISNULL(@RIESGO,'') = '' THEN '<b>-</b>'
               ELSE '<span class="vct-360-badge vct-pv-riesgo ' + CASE UPPER(LTRIM(RTRIM(@RIESGO))) WHEN 'ALTO' THEN 'is-alto' WHEN 'MEDIO' THEN 'is-medio' WHEN 'BAJO' THEN 'is-bajo' ELSE 'is-neutral' END + '">' + @E_RIESGO + '</span>' END + '</div>'
        + '<div class="is-full vct-pv-kv-sec">Lanzamiento y alta</div>'
        + '<div><small>Fecha l&iacute;mite de lanzamiento</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_LIM, 103),'-') + '</b></div>'
        + '<div><small>Fecha de alta</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_ALTA, 103),'-') + ISNULL(' &middot; ' + REPLACE(REPLACE(@U_ALTA,'<',''),'>',''), '') + '</b></div>'
        + '</div></div>';

    /* Resumen en dos mitades: izquierda datos; derecha servicios y normas, horas por servicio y atraso
       (las 3 cards de la derecha suman el alto de la de datos) */
    SET @H = @H + '<div class="vct-360-panel is-active" data-vct-panel="resumen"><div class="vct-pv-half">'
        + '<div class="vct-pv-col is-left">' + @R_DATOS + '</div>'
        + '<div class="vct-pv-col is-right">'
        + '<div class="vct-360-box vct-pv-mini"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>Servicios y normas</h3></div>'
        +   '<div class="vct-pv-kv is-2">'
        +   '<div><small>Servicios</small><span class="vct-pv-srv-list">' + CASE WHEN @R_SRV_TXT = '' THEN '<b>-</b>' ELSE @R_SRV_TXT END + '</span></div>'
        +   '<div><small>Normas</small><span class="vct-pv-chips">' + CASE WHEN @R_NOR_CHIPS = '' THEN '<b>-</b>' ELSE @R_NOR_CHIPS END + '</span></div>'
        +   '</div></div>'
        + '<div class="vct-360-box vct-pv-mini"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="briefcase"></span></span>Horas por servicio</h3></div>'
        +   CASE WHEN @R_SRV = '' THEN '<div class="vct-360-empty">Sin servicios.</div>' ELSE @R_SRV
             + '<div class="vct-pv-legend"><span><i class="is-ejec"></i>Ejecutadas</span><span><i class="is-prog"></i>Programadas</span><span><i></i>Disponibles ' + CONVERT(VARCHAR(20), CONVERT(INT, @H_DISP)) + ' h</span></div>' END
        + '</div>'
        + '<div class="vct-360-box vct-pv-mini"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>&iquest;Vamos atrasados?</h3></div>'
        +   '<div class="vct-pv-meter"><div class="vct-pv-meter-top"><span>Tiempo transcurrido</span><b>' + CONVERT(VARCHAR(5), @PCT_T) + '%</b></div><div class="vct-pv-bar"><span class="is-time" style="width:' + CONVERT(VARCHAR(5), @PCT_T) + '%"></span></div></div>'
        +   '<div class="vct-pv-meter"><div class="vct-pv-meter-top"><span>Horas ejecutadas</span><b>' + CONVERT(VARCHAR(5), @PCT_H) + '%</b></div><div class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(5), @PCT_H) + '%"></span></div></div>'
        +   '<div class="vct-pv-meter"><div class="vct-pv-meter-top"><span>Plan cumplido</span><b>&ndash;</b></div><div class="vct-pv-bar"><span class="is-plan" style="width:0%"></span></div></div>'
        + '</div>'
        + '</div></div></div>';

    /* ======================= PROYECTO ======================= */
    DECLARE @P_SRV VARCHAR(MAX) = '', @P_REP VARCHAR(MAX) = '', @P_REP_LEG VARCHAR(MAX) = '', @P_NOR VARCHAR(MAX) = '', @P_EQ VARCHAR(MAX) = '';
    SELECT @P_REP = ISNULL((
        SELECT '<span style="width:' + CONVERT(VARCHAR(10), CASE WHEN @H_PROY > 0 THEN CONVERT(INT, ROUND(PROY * 100.0 / @H_PROY, 0)) ELSE 0 END) + '%" class="is-s' + CONVERT(VARCHAR(5), ((IDX - 1) % 4) + 1) + '"></span>'
        FROM #SV ORDER BY IDX FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @P_REP_LEG = ISNULL((
        SELECT '<span><i class="is-s' + CONVERT(VARCHAR(5), ((IDX - 1) % 4) + 1) + '"></i>'
             + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + ' ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + '</span>'
        FROM #SV ORDER BY IDX FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @P_SRV = ISNULL((
        SELECT '<tr data-vct-row data-vct-filter-s="' + COD + '">'
             + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + CASE WHEN NOMBRE <> '' THEN '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '' END + '</td>'
             + '<td>' + CASE WHEN LUGAR = '' THEN '-' ELSE REPLACE(REPLACE(REPLACE(LUGAR,'&','&amp;'),'<','&lt;'),'>','&gt;') END + '</td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), INI, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), INI, 103),'-') + '</td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FIN, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FIN, 103),'-') + '</td>'
             + '<td class="vct-text-right">' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + '</td>'
             + '<td class="vct-text-right">' + CONVERT(VARCHAR(20), CONVERT(INT, PROG)) + '</td>'
             + '<td class="vct-text-right">' + CONVERT(VARCHAR(20), CONVERT(INT, EJEC)) + '</td>'
             + '<td class="vct-text-right">' + CONVERT(VARCHAR(20), CONVERT(INT, PROY - PROG - EJEC)) + '</td>'
             + '<td data-vct-sort-value="' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, EJEC * 100.0 / PROY) ELSE 0 END) + '"><span class="vctdg-progress"><span class="vctdg-progress-bar"><i style="width:'
             + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN EJEC * 100.0 / PROY > 100 THEN 100 ELSE EJEC * 100.0 / PROY END) ELSE 0 END) + '%"></i></span><b>'
             + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, EJEC * 100.0 / PROY) ELSE 0 END) + '%</b></span></td>'
             + '<td class="vct-text-center"><span class="vct-360-badge ' + CASE EST_COD WHEN 'ENCURSO' THEN 'is-active' WHEN 'CONFIRMADO' THEN 'is-planned' WHEN 'CANCELADO' THEN 'is-cancel' ELSE 'is-neutral' END + '">'
             + REPLACE(REPLACE(ISNULL(EST_DES, ISNULL(EST_COD,'-')),'<','&lt;'),'>','&gt;') + '</span></td></tr>'
        FROM #SV ORDER BY ORDEN, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @P_NOR = ISNULL((
        SELECT '<tr data-vct-row>'
             + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(N.DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
             + '<td class="vct-text-center">' + CASE WHEN N.PRINCIPAL = 1 THEN '<span class="vct-360-badge is-active">Principal</span>' ELSE '<span class="vct-360-badge is-neutral">Secundaria</span>' END + '</td>'
             + '<td>' + ISNULL(NULLIF(REPLACE(REPLACE(ISNULL((
                    SELECT ' &middot; ' + REPLACE(REPLACE(REPLACE(Q.NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')
                    FROM #EQ Q
                    WHERE Q.TIPO = 'CONSULTOR' AND EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS CN WITH(NOLOCK) WHERE CN.ID_CONSULTOR = Q.ID_ENT AND CN.ID_NORMA = N.ID_NORMA)
                    ORDER BY Q.ROL_ORD, Q.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''), '&amp;middot;', '&middot;'), '&amp;amp;', '&amp;'), ''), '<span class="vctdg-none">Ning&uacute;n consultor del equipo</span>') + '</td></tr>'
        FROM #NO N ORDER BY N.PRINCIPAL DESC, N.DES
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SET @P_NOR = REPLACE(@P_NOR, '<td> &middot; ', '<td>');

    SELECT @P_EQ = ISNULL((
        SELECT '<tr data-vct-row data-vct-filter-t="' + TIPO + '">'
             + '<td><span class="vctdg-person"><span class="vctdg-avatar ' + CASE WHEN TIPO = 'CONSULTOR' THEN 'is-c' ELSE 'is-a' END + '">' + INI + '</span></span> '
             + '<span class="vct-pv-member"><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + CASE WHEN ISNULL(OBS,'') <> '' THEN '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(LEFT(OBS,200),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '' END + '</span></td>'
             + '<td>' + CASE WHEN TIPO = 'CONSULTOR' THEN 'Consultor' ELSE 'Empleado' END + '</td>'
             + '<td class="vct-text-center"><span class="vct-360-badge ' + CASE ROL_COD WHEN 'CONSULTOR_LIDER' THEN 'is-active' WHEN 'ANALISTA' THEN 'is-planned' ELSE 'is-neutral' END + '">'
             + REPLACE(REPLACE(ISNULL(ROL_DES,'-'),'<','&lt;'),'>','&gt;') + '</span></td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), DESDE, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), DESDE, 103),'-') + '</td>'
             + CASE WHEN @PUEDE_ASIG = 1 THEN '<td class="vct-col-action">'
                    + CASE WHEN TIPO = 'CONSULTOR' THEN '<button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                         + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-baja="' + CONVERT(VARCHAR(20), ID) + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button></div>' ELSE '' END + '</td>'
                    ELSE '' END + '</tr>'
        FROM #EQ ORDER BY ROL_ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @H = @H
        /* servicios */
        + '<div class="vct-360-panel" data-vct-panel="servicios">'
        + '<div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="briefcase"></span></span>Servicios (' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #SV)) + ')</h3></div>'
        +   CASE WHEN @P_SRV = '' THEN '<div class="vct-360-empty">Sin servicios.</div>' ELSE
            '<div data-vct-dg data-vct-dg-id="pv_servicios" data-vct-dg-title="Servicios del proyecto" data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-unit="servicio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar servicio, lugar..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
          + CASE WHEN @PUEDE_EDIT = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-pronto="Agregar servicio"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
          + '<table><thead><tr>'
          + '<th data-vct-sort="s" data-vct-sortable="true"><span>Servicio</span></th><th data-vct-width="13%"><span>Lugar</span></th>'
          + '<th class="vct-text-center" data-vct-width="92" data-vct-sort="ini" data-vct-sortable="true"><span>Inicio</span></th><th class="vct-text-center" data-vct-width="92" data-vct-sort="fin" data-vct-sortable="true"><span>Fin</span></th>'
          + '<th class="vct-text-right" data-vct-width="76"><span>Proyect.</span></th><th class="vct-text-right" data-vct-width="76"><span>Program.</span></th>'
          + '<th class="vct-text-right" data-vct-width="70"><span>Ejecut.</span></th><th class="vct-text-right" data-vct-width="70"><span>Dispon.</span></th>'
          + '<th data-vct-width="12%"><span>Avance horas</span></th><th class="vct-text-center" data-vct-width="110"><span>Estado</span></th>'
          + '</tr></thead><tbody>' + @P_SRV + '</tbody></table></div>' END
        + '</div></div>'
        /* normas */
        + '<div class="vct-360-panel" data-vct-panel="normas"><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>Normas (' + CONVERT(VARCHAR(10), @N_NOR) + ')</h3></div>'
        +   CASE WHEN @P_NOR = '' THEN '<div class="vct-360-empty">Sin normas.</div>' ELSE
            '<div data-vct-dg data-vct-dg-id="pv_normas" data-vct-dg-title="Normas del proyecto" data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-unit="norma(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar norma..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
          + CASE WHEN @PUEDE_EDIT = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-pronto="Agregar norma"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
          + '<table><thead><tr><th data-vct-sort="n" data-vct-sortable="true"><span>Norma</span></th><th class="vct-text-center" data-vct-width="130"><span>Tipo</span></th><th data-vct-width="45%"><span>Consultores del equipo que la cubren</span></th></tr></thead><tbody>'
          + @P_NOR + '</tbody></table></div>' END
        + '</div></div>'
        /* equipo */
        + '<div class="vct-360-panel" data-vct-panel="equipo"><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="users"></span></span>Equipo (' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #EQ)) + ')</h3></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_equipo" data-vct-dg-title="Equipo del proyecto" data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-unit="integrante(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar integrante..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
        +   CASE WHEN @PUEDE_ASIG = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" ' + @GEST_ASIG + '><span data-vct-icon="user-plus"></span><span>Asignar consultor</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th data-vct-sort="i" data-vct-sortable="true"><span>Integrante</span></th><th data-vct-width="120"><span>Tipo</span></th>'
        +   '<th class="vct-text-center" data-vct-width="170"><span>Rol</span></th><th class="vct-text-center" data-vct-width="110" data-vct-sort="d" data-vct-sortable="true"><span>Desde</span></th>'
        +   CASE WHEN @PUEDE_ASIG = 1 THEN '<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>' ELSE '' END + '</tr></thead><tbody>'
        +   @P_EQ + '</tbody></table></div>'
        + '</div></div>';


    /* ======================= LANZAMIENTO (PV_LANZ_V1) ======================= */
    DECLARE @LZ_DE VARCHAR(MAX) = '', @LZ_CO VARCHAR(MAX) = '', @LZ_RE VARCHAR(MAX) = '', @LZ_IN VARCHAR(MAX) = '', @LZ_OPT VARCHAR(MAX) = '', @LZ_COPT VARCHAR(MAX) = '';
    DECLARE @I_EDIT VARCHAR(100) = '<span data-vct-icon="edit"></span><span>Editar</span>', @I_DEL VARCHAR(100) = '<span data-vct-icon="trash"></span><span>Eliminar</span>';

    SELECT @LZ_DE = ISNULL((
        SELECT '<tr data-vct-row data-vct-filter-o="' + CASE WHEN OBL = 1 THEN 'SI' ELSE 'NO' END + '">'
             + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + CASE WHEN @N_SRV_MIN > 1 AND SRV <> '' THEN '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(SRV,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
                    WHEN NRO = 'LIBRE' THEN '<span class="vct-360-project-ref">Dato libre</span>' ELSE '' END + '</td>'
             + '<td class="vct-pv-pre">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + CASE WHEN OBL = 1 THEN '<span class="vct-360-badge is-planned">S&iacute;</span>' ELSE '<span class="vctdg-none">-</span>' END + '</td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FUPD, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FUPD, 103),'-')
             + '<span class="vct-360-project-ref">' + REPLACE(REPLACE(USR,'<',''),'>','') + '</span></td>'
             + CASE WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="de" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-f-item="' + ISNULL(CONVERT(VARCHAR(20), ITEM),'') + '" data-f-preg="' + REPLACE(REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-valor="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Eliminar" data-vct-pv-confirm="PV_DE_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Eliminar dato de entrada" data-msg="Se elimina el dato: ' + REPLACE(REPLACE(REPLACE(REPLACE(LEFT(TEMAS,150),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_DEL + '</button></div></td>'
               ELSE '' END + '</tr>'
        FROM #LZ WHERE TIPO = 'MG' ORDER BY CASE WHEN ITEM IS NULL THEN 1 ELSE 0 END, SRV, ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_OPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + CASE WHEN OBL = 1 THEN '* ' ELSE '' END
             + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;')
             + CASE WHEN @N_SRV_MIN > 1 THEN ' &middot; ' + REPLACE(REPLACE(REPLACE(SRV,'&','&amp;'),'<','&lt;'),'>','&gt;') ELSE '' END + '</option>'
        FROM #IT WHERE CARGADO = 0 ORDER BY OBL DESC, SRV, ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_CO = ISNULL((
        SELECT '<tr data-vct-row data-vct-filter-g="' + NRO + '">'
             + '<td class="vct-text-center"><span class="vct-360-badge ' + CASE NRO WHEN 'CLIENTE' THEN 'is-active' WHEN 'CONSULTOR' THEN 'is-progress' ELSE 'is-neutral' END + '">'
             + CASE NRO WHEN 'CLIENTE' THEN 'Cliente' WHEN 'CONSULTOR' THEN 'Consultor' ELSE 'Interna' END + '</span></td>'
             + '<td class="vct-pv-pre">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + REPLACE(REPLACE(USR,'<',''),'>','') + '</td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FUPD, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FUPD, 103),'-') + '</td>'
             + CASE WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="co" data-id="' + CONVERT(VARCHAR(20), ID) + '" data-f-grupo="' + NRO + '"'
                  + ' data-f-texto="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Eliminar" data-vct-pv-confirm="PV_CO_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Eliminar consideraci&oacute;n" data-msg="Se elimina la consideraci&oacute;n: ' + REPLACE(REPLACE(REPLACE(REPLACE(LEFT(OBS,150),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_DEL + '</button></div></td>'
               ELSE '' END + '</tr>'
        FROM #LZ WHERE TIPO = 'CONS' ORDER BY FUPD DESC, ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_RE = ISNULL((
        SELECT '<tr data-vct-row>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FECHA, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FECHA, 103),'-') + '</td>'
             + '<td>' + REPLACE(REPLACE(REPLACE(PART,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-pv-pre"><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + CASE WHEN OBS <> '' THEN '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '' END + '</td>'
             + '<td>' + REPLACE(REPLACE(REPLACE(CONS_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + CASE WHEN CIERRE IS NOT NULL THEN '<span class="vct-360-badge is-active">Realizada</span>' ELSE '<span class="vct-360-badge is-planned">Programada</span>' END + '</td>'
             + CASE WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="re" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-f-fecha="' + ISNULL(CONVERT(VARCHAR(10), FECHA, 120),'') + '" data-f-cons="' + ISNULL(CONVERT(VARCHAR(20), ID_CONS),'') + '"'
                  + ' data-f-realizada="' + CASE WHEN CIERRE IS NOT NULL THEN '1' ELSE '0' END + '"'
                  + ' data-f-part="' + REPLACE(REPLACE(REPLACE(REPLACE(PART,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-temas="' + REPLACE(REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Eliminar" data-vct-pv-confirm="PV_RE_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Eliminar reuni&oacute;n" data-msg="Se elimina la reuni&oacute;n del ' + ISNULL(CONVERT(VARCHAR(10), FECHA, 103),'') + '.'
                  + CASE WHEN CIERRE IS NOT NULL THEN ' Si no queda otra reuni&oacute;n realizada, la acci&oacute;n Reuni&oacute;n de lanzamiento vuelve a pendiente.' ELSE '' END + '">' + @I_DEL + '</button></div></td>'
               ELSE '' END + '</tr>'
        FROM #LZ WHERE TIPO = 'LANZ' ORDER BY FECHA DESC, ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_COPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID_ENT) + '">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')
             + CASE WHEN ROL_COD = 'CONSULTOR_LIDER' THEN ' (l&iacute;der)' ELSE '' END + '</option>'
        FROM #EQ WHERE TIPO = 'CONSULTOR' ORDER BY ROL_ORD, NOMBRE
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_IN = ISNULL((
        SELECT '<tr data-vct-row>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FECHA, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FECHA, 103),'-') + '</td>'
             + '<td class="vct-pv-pre">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + REPLACE(REPLACE(USR,'<',''),'>','') + '</td>'
             + CASE WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="in" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-f-fecha="' + ISNULL(CONVERT(VARCHAR(10), FECHA, 120),'') + '"'
                  + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Deshacer inicio" data-vct-pv-confirm="PV_IN_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Deshacer el inicio" data-msg="El proyecto vuelve a Confirmado y se cancelan las acciones abiertas que gener&oacute; el inicio (carga del plan). No se puede si ya tiene parte log&iacute;stico.">' + @I_DEL + '</button></div></td>'
               ELSE '' END + '</tr>'
        FROM #LZ WHERE TIPO = 'INICIO' ORDER BY FECHA DESC, ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    DECLARE @TH_ACC VARCHAR(200) = CASE WHEN @PUEDE_LANZ = 1 THEN '<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>' ELSE '' END;
    DECLARE @DG_ATTR VARCHAR(300) = ' data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-page-size="10" data-vct-dg-density="compact" data-vct-dg-layout="fixed"';

    SET @H = @H + '<div class="vct-360-panel" data-vct-panel="lanzamiento">'
        + '<div class="vct-pv-steps is-nav">'
        +   '<div class="' + CASE WHEN @L_CONS = 1 THEN 'ok' ELSE 'now' END + '" data-vct-pv-goto="equipo" role="button" tabindex="0"><i>' + CASE WHEN @L_CONS = 1 THEN '&#10003;' ELSE '1' END + '</i><span><b>Consultor asignado</b>' + CASE WHEN @L_CONS = 1 THEN @LIDER_TXT ELSE 'falta el l&iacute;der' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_DATOS = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="datos" role="button" tabindex="0"><i>' + CASE WHEN @L_DATOS = 1 THEN '&#10003;' ELSE '2' END + '</i><span><b>Datos de entrada</b>'
        +     CASE WHEN @L_DATOS = 1 THEN 'completo &middot; ' + CONVERT(VARCHAR(10), @N_DE) + ' datos'
               WHEN @DE_OBL > 0 THEN CONVERT(VARCHAR(10), @DE_OBL_OK) + ' de ' + CONVERT(VARCHAR(10), @DE_OBL) + ' obligatorios' ELSE CONVERT(VARCHAR(10), @N_DE) + ' cargados' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_CO = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="cons" role="button" tabindex="0"><i>' + CASE WHEN @L_CO = 1 THEN '&#10003;' ELSE '3' END + '</i><span><b>Consideraciones</b>'
        +     CASE WHEN @N_CO = 0 THEN 'sin cargar' ELSE CONVERT(VARCHAR(10), @N_CO) + ' cargada(s)' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_REU = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="reunion" role="button" tabindex="0"><i>' + CASE WHEN @L_REU = 1 THEN '&#10003;' ELSE '4' END + '</i><span><b>Reuni&oacute;n de lanzamiento</b>'
        +     CASE WHEN @L_REU = 1 THEN 'realizada' + ISNULL(' ' + CONVERT(VARCHAR(5), @RE_FECHA, 103), '') ELSE @L_REU_TXT END + '</span></div>'
        +   '<div class="' + CASE WHEN @EST_COD = 'ENCURSO' THEN 'ok' WHEN @IN_OK = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="inicio" role="button" tabindex="0"><i>' + CASE WHEN @EST_COD = 'ENCURSO' THEN '&#10003;' ELSE '5' END + '</i><span><b>Iniciar proyecto</b>'
        +     CASE WHEN @EST_COD = 'ENCURSO' THEN 'en curso' WHEN @IN_OK = 1 THEN 'listo para iniciar' ELSE 'genera la carga del plan' END + '</span></div>'
        + '</div>'

        /* datos de entrada */
        + '<div data-vct-pv-subpanel="datos"><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="file-text"></span></span>Datos de entrada (' + CONVERT(VARCHAR(10), @N_DE) + ')</h3>'
        +   '<span class="vct-pv-box-note">' + CASE WHEN @DE_OBL > 0 THEN CONVERT(VARCHAR(10), @DE_OBL_OK) + ' de ' + CONVERT(VARCHAR(10), @DE_OBL) + ' obligatorios de la minuta' ELSE 'Minuta de gesti&oacute;n del servicio' END
        +   CASE WHEN @L_DATOS = 1 THEN ' &middot; <b class="vct-pv-ok-txt">carga finalizada</b>' ELSE '' END + '</span></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_datos" data-vct-dg-title="Datos de entrada" data-vct-dg-unit="dato(s)" data-vct-dg-search-placeholder="Buscar dato o respuesta..."' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_LANZ = 1 THEN '<div data-vct-dg-slot="actions">'
              + CASE WHEN @DE_ABIERTA = 1 THEN '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm" data-vct-pv-confirm="PV_DE_CERRAR" data-id="0" data-titulo="Finalizar carga de datos de entrada"'
                   + ' data-msg="La acci&oacute;n Carga de datos de entrada queda cumplida.' + CASE WHEN @DE_OBL > @DE_OBL_OK THEN ' Quedan ' + CONVERT(VARCHAR(10), @DE_OBL - @DE_OBL_OK) + ' dato(s) obligatorio(s) sin cargar.' ELSE '' END + '"><span data-vct-icon="check"></span><span>Finalizar carga</span></button>' ELSE '' END
              + '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="de"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th data-vct-sort="d" data-vct-sortable="true"><span>Dato</span></th><th data-vct-width="38%"><span>Respuesta</span></th>'
        +   '<th class="vct-text-center" data-vct-width="80"><span>Oblig.</span></th><th class="vct-text-center" data-vct-width="110" data-vct-sort="f" data-vct-sortable="true"><span>Actualizado</span></th>' + @TH_ACC + '</tr></thead><tbody>'
        +   @LZ_DE + '</tbody></table></div>'
        +   CASE WHEN @N_DE = 0 THEN '<div class="vct-360-empty">Sin datos de entrada. ' + CASE WHEN @PUEDE_LANZ = 1 THEN 'Us&aacute; Agregar para cargar los datos de la minuta del servicio.' ELSE '' END + '</div>' ELSE '' END
        + '</div></div>'

        /* consideraciones */
        + '<div data-vct-pv-subpanel="cons" hidden><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="scan-eye"></span></span>Consideraciones (' + CONVERT(VARCHAR(10), @N_CO) + ')</h3></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_cons" data-vct-dg-title="Consideraciones" data-vct-dg-unit="consideraci&oacute;n(es)" data-vct-dg-search-placeholder="Buscar consideraci&oacute;n..."' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_LANZ = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="co"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="110"><span>Tipo</span></th><th><span>Consideraci&oacute;n</span></th>'
        +   '<th class="vct-text-center" data-vct-width="120"><span>Autor</span></th><th class="vct-text-center" data-vct-width="100" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th>' + @TH_ACC + '</tr></thead><tbody>'
        +   @LZ_CO + '</tbody></table></div>'
        +   CASE WHEN @N_CO = 0 THEN '<div class="vct-360-empty">Sin consideraciones. Ej.: log&iacute;stica, d&iacute;as de acompa&ntilde;amiento en la auditor&iacute;a interna.</div>' ELSE '' END
        + '</div></div>'

        /* reunion de lanzamiento */
        + '<div data-vct-pv-subpanel="reunion" hidden><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="calendar"></span></span>Reuni&oacute;n de lanzamiento (' + CONVERT(VARCHAR(10), @N_RE) + ')</h3></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_reunion" data-vct-dg-title="Reuni&oacute;n de lanzamiento" data-vct-dg-unit="reuni&oacute;n(es)" data-vct-dg-search-placeholder="Buscar reuni&oacute;n..."' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_LANZ = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="re"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="100" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th><th data-vct-width="22%"><span>Participantes</span></th>'
        +   '<th><span>Temas y conclusiones</span></th><th data-vct-width="16%"><span>Consultor</span></th><th class="vct-text-center" data-vct-width="110"><span>Estado</span></th>' + @TH_ACC + '</tr></thead><tbody>'
        +   @LZ_RE + '</tbody></table></div>'
        +   CASE WHEN @N_RE = 0 THEN '<div class="vct-360-empty">Sin reuniones. Se explica el proyecto al consultor: d&iacute;as por mes, auditor&iacute;a interna, acompa&ntilde;amientos y puntos de atenci&oacute;n.</div>' ELSE '' END
        + '</div></div>'

        /* inicio del proyecto */
        + '<div data-vct-pv-subpanel="inicio" hidden><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="check"></span></span>Inicio del proyecto</h3>'
        +   '<span class="vct-pv-box-note">' + CASE WHEN @EST_COD = 'ENCURSO' THEN '<b class="vct-pv-ok-txt">En curso</b>' WHEN @IN_OK = 1 THEN '<b class="vct-pv-ok-txt">Control de lanzamiento OK</b>' ELSE @IN_FALTA END + '</span></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_inicio" data-vct-dg-title="Inicio del proyecto" data-vct-dg-unit="registro(s)"' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_LANZ = 1 AND @N_IN = 0 AND @EST_COD = 'CONFIRMADO' THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="in"'
                   + CASE WHEN @IN_OK = 0 THEN ' disabled title="' + @IN_FALTA + '"' ELSE '' END + '><span data-vct-icon="check"></span><span>Iniciar proyecto</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="130"><span>Inicio real</span></th><th><span>Observaciones</span></th><th class="vct-text-center" data-vct-width="130"><span>Registr&oacute;</span></th>' + @TH_ACC + '</tr></thead><tbody>'
        +   @LZ_IN + '</tbody></table></div>'
        +   CASE WHEN @N_IN = 0 THEN '<div class="vct-360-empty">' + CASE WHEN @EST_COD <> 'CONFIRMADO' THEN 'El proyecto no est&aacute; Confirmado.' WHEN @IN_OK = 1 THEN 'Al iniciar, el proyecto pasa a En curso y el consultor l&iacute;der recibe la acci&oacute;n de cargar el plan.' ELSE @IN_FALTA + '.' END + '</div>' ELSE '' END
        + '</div></div>'
        + '</div>';


    /* ======================= ACCIONES ======================= */
    DECLARE @AC VARCHAR(MAX) = '', @AC_F_EST VARCHAR(MAX) = '', @AC_F_AREA VARCHAR(MAX) = '', @AC_F_TIPO VARCHAR(MAX) = '';
    SELECT @AC = ISNULL((
        SELECT '<tr data-vct-row data-vct-filter-estado="' + CASE WHEN SIT = 'V' THEN 'VENCIDA' ELSE EST_COD END + '" data-vct-filter-area="' + REPLACE(AREA,'"','') + '" data-vct-filter-tipo="' + REPLACE(TIPO,'"','') + '">'
             + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TIPO + CASE WHEN SUB_DES <> '' THEN ' - ' + SUB_DES ELSE '' END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(TITULO,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
             + '<td>' + REPLACE(REPLACE(REPLACE(AREA,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center"><span class="vctdg-person"><span class="vctdg-avatar ' + CASE WHEN MIA = 1 THEN 'is-c' ELSE 'is-a' END + '" title="' + REPLACE(REPLACE(REPLACE(RESP,'&','&amp;'),'"',''),'<','') + '">' + RESP_INI + '</span></span></td>'
             + '<td class="vct-text-center">' + CASE WHEN SIT = 'C' AND EST_COD = 'CANCELADA' THEN '<span class="vct-360-badge is-cancel">Cancelada</span>'
                                                     WHEN SIT = 'C' THEN '<span class="vct-360-badge is-active">' + EST_DES + '</span>'
                                                     WHEN SIT = 'V' THEN '<span class="vct-360-badge is-cancel">Vencida</span>'
                                                     WHEN EST_COD IN ('EN_PROCESO','EN_ESPERA') THEN '<span class="vct-360-badge is-progress">' + EST_DES + '</span>'
                                                     ELSE '<span class="vct-360-badge is-planned">' + EST_DES + '</span>' END + '</td>'
             /* fecha y hora de la accion (alta); debajo, vence o cierre */
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), CREA, 112) + REPLACE(CONVERT(VARCHAR(8), CREA, 108), ':', ''), '') + '">'
             + ISNULL(CONVERT(VARCHAR(10), CREA, 103) + ' ' + LEFT(CONVERT(VARCHAR(8), CREA, 108), 5), '-')
             + CASE WHEN SIT = 'C' AND CIERRE IS NOT NULL THEN '<span class="vct-360-project-ref">cerrada ' + CONVERT(VARCHAR(5), CIERRE, 103) + '</span>'
                    WHEN SIT <> 'C' AND VENCE IS NOT NULL THEN '<span class="vct-360-project-ref">vence ' + CONVERT(VARCHAR(5), VENCE, 103) + '</span>' ELSE '' END + '</td>'
             + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true">'
             + CASE WHEN MIA = 1 AND SIT <> 'C'
                    THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" '
                       + CASE WHEN SUB_COD = 'ASIGNACION_CONSULTOR' AND @PUEDE_ASIG = 1 THEN @GEST_ASIG
                              WHEN SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') THEN 'data-vct-pv-goto="lanzamiento"'
                              ELSE 'data-vct-pv-goto="acciones"' END
                       + ' title="Gestionar"><span>Gestionar</span></button>'
                    ELSE '' END
             + '</td></tr>'
        FROM #A
        ORDER BY CREA DESC, ID DESC   /* la mas nueva arriba */
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @AC_F_EST = ISNULL((SELECT '<option value="' + K + '">' + D + '</option>' FROM (
        SELECT DISTINCT CASE WHEN SIT = 'V' THEN 'VENCIDA' ELSE EST_COD END AS K, CASE WHEN SIT = 'V' THEN 'Vencida' ELSE EST_DES END AS D FROM #A) Z
        ORDER BY D FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @AC_F_AREA = ISNULL((SELECT '<option value="' + REPLACE(AREA,'"','') + '">' + REPLACE(REPLACE(AREA,'<','&lt;'),'>','&gt;') + '</option>' FROM (SELECT DISTINCT AREA FROM #A WHERE AREA <> '') Z
        ORDER BY AREA FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @AC_F_TIPO = ISNULL((SELECT '<option value="' + REPLACE(TIPO,'"','') + '">' + REPLACE(REPLACE(TIPO,'<','&lt;'),'>','&gt;') + '</option>' FROM (SELECT DISTINCT TIPO FROM #A WHERE TIPO <> '') Z
        ORDER BY TIPO FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @H = @H + '<div class="vct-360-panel" data-vct-panel="acciones"><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box">'
        + '<div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>Acciones (' + CONVERT(VARCHAR(10), @N_TOT_ACC) + ')</h3></div>'
        + CASE WHEN @AC = '' THEN '<div class="vct-360-empty">Sin acciones.</div>' ELSE
          '<div data-vct-dg data-vct-dg-id="pv_acciones" data-vct-dg-title="Acciones del proyecto" data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-unit="acci&oacute;n(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar acci&oacute;n, responsable..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
        + '<div data-vct-dg-slot="filters">'
        +   '<select data-vct-dg-filter="estado" aria-label="Estado"><option value="">Estado</option>' + @AC_F_EST + '</select>'
        +   '<select data-vct-dg-filter="area" aria-label="&Aacute;rea"><option value="">&Aacute;rea</option>' + @AC_F_AREA + '</select>'
        +   '<select data-vct-dg-filter="tipo" aria-label="Tipo"><option value="">Tipo</option>' + @AC_F_TIPO + '</select></div>'
        + '<table><thead><tr><th data-vct-sort="a" data-vct-sortable="true"><span>Acci&oacute;n</span></th><th data-vct-width="14%"><span>&Aacute;rea</span></th>'
        + '<th class="vct-text-center" data-vct-width="70"><span>Resp.</span></th><th class="vct-text-center" data-vct-width="130" data-vct-sort="e" data-vct-sortable="true"><span>Estado</span></th>'
        + '<th class="vct-text-center" data-vct-width="130" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th><th class="vct-col-action" data-vct-width="110" data-vct-export-ignore="true"></th></tr></thead><tbody>'
        + @AC + '</tbody></table></div>' END
        + '</div></div>';

    /* ======================= PESTANIAS DE PASOS SIGUIENTES ======================= */
    SET @H = @H
        + '<div class="vct-360-panel" data-vct-panel="plan"><div class="vct-360-box"><div class="vct-360-empty">El parte log&iacute;stico (plan estrat&eacute;gico) se genera al iniciar el proyecto.</div></div></div>'
        + '<div class="vct-360-panel" data-vct-panel="agenda"><div class="vct-360-box"><div class="vct-360-empty">La agenda del proyecto (visitas y horas) se habilita en el paso de agenda.</div></div></div>'
        + '<div class="vct-360-panel" data-vct-panel="admin"><div class="vct-360-box"><div class="vct-360-empty">Honorarios, vi&aacute;ticos y rentabilidad se habilitan en el paso de administraci&oacute;n.</div></div></div>'
        + '<div class="vct-360-panel" data-vct-panel="documentos"><div class="vct-360-box"><div class="vct-360-empty">Los documentos del proyecto se habilitan en el paso de documentaci&oacute;n.</div></div></div>'
        + '</div>';

    /* ======================= MODAL ASIGNAR CONSULTOR ======================= */
    DECLARE @MODAL VARCHAR(MAX) = '';
    IF @PUEDE_ASIG = 1
    BEGIN
        CREATE TABLE #C (ID INT, NOMBRE VARCHAR(300), SRV VARCHAR(1000), NOR_TXT VARCHAR(2000), CUBRE INT, PROYS INT, HORAS NUMERIC(18,2), EMAIL VARCHAR(300));
        INSERT INTO #C (ID, NOMBRE, SRV, NOR_TXT, CUBRE, PROYS, HORAS, EMAIL)
        SELECT C.ID,
               LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),
               ISNULL(STUFF((SELECT ', ' + S.DES FROM #SV S
                             WHERE EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_SERVICIOS CS WITH(NOLOCK) WHERE CS.ID_CONSULTOR = C.ID AND CS.ID_SERVICIO = S.ID_SERVICIO)
                             ORDER BY S.ORDEN FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 2, ''), ''),
               ISNULL(STUFF((SELECT ' &middot; ' + N.DES FROM #NO N
                             WHERE EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS CN WITH(NOLOCK) WHERE CN.ID_CONSULTOR = C.ID AND CN.ID_NORMA = N.ID_NORMA)
                             ORDER BY N.PRINCIPAL DESC, N.DES FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 10, ''), ''),
               (SELECT COUNT(*) FROM #NO N WHERE EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS CN WITH(NOLOCK) WHERE CN.ID_CONSULTOR = C.ID AND CN.ID_NORMA = N.ID_NORMA)),
               (SELECT COUNT(DISTINCT EQ.ID_PROYECTO) FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                JOIN dbo.VCT_PROYECTOS P2 WITH(NOLOCK) ON P2.ID = EQ.ID_PROYECTO
                JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E2 WITH(NOLOCK) ON E2.ID = P2.ID_ESTADO AND E2.CODIGO IN ('CONFIRMADO','ENCURSO')
                WHERE EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = C.ID AND EQ.ESTADO = 'ACTIVO'),
               ISNULL((SELECT SUM(ISNULL(VC.HORAS_PLANIFICADAS,0)) FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)
                       JOIN dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK) ON V.ID = VC.ID_VISITA
                       WHERE VC.ID_CONSULTOR = C.ID AND V.FECHA_DESDE >= ISNULL(@F_INI, @HOY) AND V.FECHA_DESDE <= ISNULL(@F_FIN, DATEADD(YEAR, 1, @HOY))), 0),
               /* mail principal del consultor (VCT_EMAILS) */
               (SELECT TOP 1 LTRIM(RTRIM(M.EMAIL)) FROM dbo.VCT_EMAILS M WITH(NOLOCK)
                WHERE M.TIPO_ENTIDAD = 'CONSULTOR' AND M.ID_ENTIDAD = C.ID AND M.PRINCIPAL = 'SI' AND LTRIM(RTRIM(ISNULL(M.EMAIL,''))) <> '' ORDER BY M.ID)
        FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
        WHERE UPPER(ISNULL(C.ESTADO,'ACTIVO')) = 'ACTIVO'
          AND EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_SERVICIOS CS WITH(NOLOCK) JOIN #SV S ON S.ID_SERVICIO = CS.ID_SERVICIO WHERE CS.ID_CONSULTOR = C.ID)
          AND NOT EXISTS (SELECT 1 FROM #EQ Q WHERE Q.TIPO = 'CONSULTOR' AND Q.ID_ENT = C.ID);

        DECLARE @C_ROWS VARCHAR(MAX) = '', @CHIPS VARCHAR(MAX) = '', @ROLES VARCHAR(MAX) = '', @GEN VARCHAR(MAX) = '',
                @MIN_D INT, @VENCE_DEF VARCHAR(10) = '', @TPL_OK BIT = 0, @ID_LIDER_ROL INT;
        SELECT @ID_LIDER_ROL = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WITH(NOLOCK) WHERE CODIGO = 'CONSULTOR_LIDER';
        SELECT @ROLES = ISNULL((
            SELECT '<button type="button" class="vct-pv-role' + CASE WHEN R.CODIGO = 'CONSULTOR' THEN ' is-on is-default' ELSE '' END + '" data-vct-pv-role="' + CONVERT(VARCHAR(20), R.ID) + '"'
                 + ' data-lider="' + CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN '1' ELSE '0' END + '">'
                 + REPLACE(REPLACE(REPLACE(R.DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</button>'
            FROM dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK)
            WHERE R.TIPO_MIEMBRO = 'CONSULTOR' AND NOT (@HAY_LIDER = 1 AND R.CODIGO = 'CONSULTOR_LIDER')
            ORDER BY R.ORDEN
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        SELECT @C_ROWS = ISNULL((
            SELECT '<tr data-vct-pv-cons="' + CONVERT(VARCHAR(20), ID) + '" data-email="' + REPLACE(REPLACE(ISNULL(EMAIL,''),'"',''),'<','') + '" data-vct-search="' + LOWER(REPLACE(REPLACE(REPLACE(NOMBRE + ' ' + SRV + ' ' + REPLACE(NOR_TXT,'&middot;',' '),'"',''),'<',''),'>','')) + '">'
                 + '<td><span class="vct-pv-check" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 5 5 9-10"/></svg></span></td>'
                 + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span><span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(SRV,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
                 + '<td>' + CASE WHEN NOR_TXT = '' THEN '<span class="vctdg-none">-</span>' ELSE REPLACE(REPLACE(REPLACE(REPLACE(NOR_TXT,'&','&amp;'),'&amp;middot;','&middot;'),'<','&lt;'),'>','&gt;') END + '</td>'
                 + '<td><span class="vct-360-badge ' + CASE WHEN @N_NOR > 0 AND CUBRE = @N_NOR THEN 'is-active' WHEN CUBRE > 0 THEN 'is-planned' ELSE 'is-neutral' END + '">cubre '
                 + CONVERT(VARCHAR(5), CUBRE) + '/' + CONVERT(VARCHAR(5), @N_NOR) + '</span></td>'
                 + '<td>' + CONVERT(VARCHAR(10), PROYS) + ' en curso</td>'
                 + '<td>' + CONVERT(VARCHAR(20), CONVERT(INT, HORAS)) + ' h</td>'
                 + '<td><div class="vct-pv-roles" data-vct-pv-roles>' + @ROLES + '</div></td></tr>'
            FROM #C ORDER BY NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        SELECT @CHIPS = '<span class="vct-pv-chips-lbl">Servicios</span>'
                     + CASE WHEN @SRV_ICONS = '' THEN '' ELSE '<span class="vctdg-svc-set vct-pv-svc-md">' + @SRV_ICONS + '</span>' END
                     + '<span class="vct-pv-chips-lbl">Normas</span>'
                     + ISNULL((SELECT '<span class="vct-pv-chip is-b">' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' FROM #NO ORDER BY PRINCIPAL DESC, DES
                                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        /* lo que se genera al guardar: reglas de CONSULTORES_ASIGNADOS (solo con el lider) */
        IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK) WHERE CODIGO = 'PROYECTO_CONSULTOR_ASIGNADO' AND ESTADO = 'ACTIVO') SET @TPL_OK = 1;
        SELECT @MIN_D = MIN(R.DIAS_VENCIMIENTO) FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
        WHERE R.CODIGO_EVENTO = 'CONSULTORES_ASIGNADOS' AND R.ACTIVO = 1 AND R.DIAS_VENCIMIENTO IS NOT NULL;
        SET @VENCE_DEF = CASE WHEN @MIN_D IS NULL THEN '' ELSE CONVERT(VARCHAR(10), DATEADD(DAY, @MIN_D, @HOY), 120) END;
        SELECT @GEN = ISNULL((
            SELECT '<div data-vct-pv-gen-lider data-vct-pv-dias="' + ISNULL(CONVERT(VARCHAR(10), R.DIAS_VENCIMIENTO - @MIN_D), '') + '"><span class="vct-360-badge is-planned">Pendiente</span> '
                 + REPLACE(REPLACE(REPLACE(ISNULL(ST.DESCRIPCION, R.CODIGO),'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; '
                 + LOWER(REPLACE(REPLACE(ISNULL(PR.DESCRIPCION, R.DESTINATARIO_ROL),'<','&lt;'),'>','&gt;'))
                 + CASE WHEN R.DIAS_VENCIMIENTO IS NULL THEN '' ELSE ' &middot; vence <b data-vct-pv-gen-fecha>' + CONVERT(VARCHAR(5), DATEADD(DAY, R.DIAS_VENCIMIENTO, @HOY), 103) + '</b>' END + '</div>'
            FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
            LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = R.ID_SUBTIPO
            LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES PR WITH(NOLOCK) ON PR.CODIGO = R.DESTINATARIO_ROL
            WHERE R.CODIGO_EVENTO = 'CONSULTORES_ASIGNADOS' AND R.ACTIVO = 1
              AND NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_REGLA_ORIGEN = R.ID)
            ORDER BY R.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SET @GEN = CONVERT(VARCHAR(MAX), '') + CASE WHEN EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT <> 'C')
                        THEN '<div data-vct-pv-gen-lider><span class="vct-360-badge is-active">Cumplida</span> Asignar consultores (al asignar el l&iacute;der)</div>' ELSE '' END
                 + @GEN;

        SET @MODAL = CONVERT(VARCHAR(MAX), '') + '<div class="vct-modal vct-form-shell vct-form-lg vct-pv-modal" id="vctPvAsignar" data-vct-component="modal" data-vct-pv-modal="asignar"'
            + ' data-vct-pv-guid="' + REPLACE(@GUID_V360,'"','') + '" data-vct-pv-hoy="' + CONVERT(VARCHAR(10), @HOY, 120) + '">'
            + '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
            + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="user-plus"></span></div>'
            + '<div class="vct-form-header-copy"><h3 class="vct-modal-title">Asignar consultores</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
            + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
            + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Tipo</label><input type="text" class="vct-input" value="Asignaci&oacute;n" readonly></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Subtipo</label><input type="text" class="vct-input" value="Asignaci&oacute;n de consultor" readonly></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Resultado</label><input type="text" class="vct-input" value="Consultor asignado" readonly></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-pv-sec">Consultores con el servicio y las normas del proyecto</div></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-pv-chips">' + @CHIPS + '</div>'
            + CASE WHEN @C_ROWS = '' THEN '<div class="vct-360-empty">No hay consultores activos con los servicios del proyecto (VCT_CONSULTORES_SERVICIOS) sin asignar.</div>'
                   ELSE '<div class="vct-pv-cons-search"><span data-vct-icon="search"></span><input type="text" class="vct-input" style="padding-left:38px !important" placeholder="Buscar consultor, servicio o norma..." data-vct-pv-buscar autocomplete="off"></div>'
                      + '<div class="vct-pv-cons-wrap" data-vct-dg-id="pv_asignar_cons"><table class="vct-pv-cons"><colgroup><col style="width:40px"><col style="width:22%"><col style="width:17%"><col style="width:9%"><col style="width:9%"><col style="width:9%"><col style="width:34%"></colgroup><thead><tr><th></th><th>Consultor</th><th>Normas que cubre</th><th>Cobertura</th><th>Proyectos</th><th>Horas per&iacute;odo</th><th>Rol</th></tr></thead><tbody>'
                      + @C_ROWS + '</tbody></table></div><div class="vct-pv-cons-sel" data-vct-pv-sel></div>' END
            + '</div>'
            + '<div class="vct-field vct-col-4" data-vct-pv-vence-wrap><label class="vct-label">Vence pr&oacute;xima acci&oacute;n</label><input type="date" class="vct-input" data-vct-datepicker data-vct-pv-vence value="' + @VENCE_DEF + '" min="' + CONVERT(VARCHAR(10), @HOY, 120) + '"></div>'
            + '<div class="vct-field vct-col-8"><label class="vct-label" data-vct-pv-email-lbl>Email adicional (CC)</label><input type="text" class="vct-input" maxlength="500" placeholder="nombre@dominio.com; otro@dominio.com" data-vct-pv-email>'
            +   '<div class="vct-help" data-vct-pv-email-help>Opcional: va en copia del mail a los consultores.</div></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Observaciones</label><textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-obs></textarea></div>'
            + CASE WHEN @GEN = '' THEN '' ELSE '<div class="vct-field vct-col-12" data-vct-pv-gen-lider><div class="vct-pv-sec">Al asignar el l&iacute;der se genera</div></div>'
                   + '<div class="vct-field vct-col-12" data-vct-pv-gen-lider><div class="vct-pv-gen">' + @GEN + '</div></div>' END
            + '</div></div>'
            + '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
            + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-asignar><span data-vct-icon="save"></span><span>Asignar y notificar</span></button></div>'
            + '</div></div>';
    END;

    /* ======================= MODALES DEL LANZAMIENTO (alta / edicion) ======================= */
    DECLARE @LZ_MODALS VARCHAR(MAX) = '', @MH VARCHAR(MAX), @MF VARCHAR(MAX);
    DECLARE @LIDER_MAIL VARCHAR(300) = '';
    SELECT TOP 1 @LIDER_MAIL = LTRIM(RTRIM(ISNULL(M.EMAIL,'')))
    FROM #EQ Q INNER JOIN dbo.VCT_EMAILS M WITH(NOLOCK) ON M.TIPO_ENTIDAD = 'CONSULTOR' AND M.ID_ENTIDAD = Q.ID_ENT AND M.PRINCIPAL = 'SI'
    WHERE Q.TIPO = 'CONSULTOR' AND Q.ROL_COD = 'CONSULTOR_LIDER' AND LTRIM(RTRIM(ISNULL(M.EMAIL,''))) <> '' ORDER BY Q.ID, M.ID;
    SET @LIDER_MAIL = ISNULL(@LIDER_MAIL, '');
    IF @PUEDE_LANZ = 1
    BEGIN
        SET @MF = '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
                + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>';
        SET @MH = '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
                + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="{ICON}"></span></div>'
                + '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-pv-mtitle>{TIT}</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
                + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
                + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">';

        SET @LZ_MODALS = CONVERT(VARCHAR(MAX), '')
            /* dato de entrada */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-md" data-vct-component="modal" data-vct-pv-modal="de" data-vct-pv-cmd="PV_DE_GUARDAR" data-vct-pv-tnew="Agregar dato de entrada" data-vct-pv-tedit="Editar dato de entrada">'
            + REPLACE(REPLACE(@MH, '{ICON}', 'file-text'), '{TIT}', 'Dato de entrada')
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new><label class="vct-label">Dato de la minuta <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="item" data-vct-pv-buf="TEXTO11">' + @LZ_OPT + '<option value="">Otro dato (escribirlo)</option></select>'
            +   '<div class="vct-help">Los marcados con * son obligatorios de la minuta del servicio.</div></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-preg-wrap><label class="vct-label">Dato <span class="vct-req">*</span></label>'
            +   '<input type="text" class="vct-input" maxlength="1000" data-vct-pv-f="preg" data-vct-pv-buf="TEXTO12"></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Respuesta <span class="vct-req">*</span></label>'
            +   '<textarea class="vct-textarea" rows="4" maxlength="2000" data-vct-pv-f="valor" data-vct-pv-buf="TEXTO13" data-req="Respuesta"></textarea></div>'
            + '</div></div>' + @MF

            /* consideracion */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-sm" data-vct-component="modal" data-vct-pv-modal="co" data-vct-pv-cmd="PV_CO_GUARDAR" data-vct-pv-tnew="Agregar consideraci&oacute;n" data-vct-pv-tedit="Editar consideraci&oacute;n">'
            + REPLACE(REPLACE(@MH, '{ICON}', 'scan-eye'), '{TIT}', 'Consideraci&oacute;n')
            + '<div class="vct-field vct-col-6"><label class="vct-label">Tipo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="grupo" data-vct-pv-buf="TEXTO11" data-vct-pv-def="INTERNA"><option value="INTERNA">Interna</option><option value="CONSULTOR">Consultor</option><option value="CLIENTE">Cliente</option></select></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Consideraci&oacute;n <span class="vct-req">*</span></label>'
            +   '<textarea class="vct-textarea" rows="4" maxlength="2000" data-vct-pv-f="texto" data-vct-pv-buf="TEXTO12" data-req="Consideraci&oacute;n"></textarea></div>'
            + '</div></div>' + @MF

            /* reunion de lanzamiento */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-lg" data-vct-component="modal" data-vct-pv-modal="re" data-vct-pv-cmd="PV_RE_GUARDAR" data-vct-pv-tnew="Agregar reuni&oacute;n de lanzamiento" data-vct-pv-tedit="Editar reuni&oacute;n de lanzamiento">'
            + REPLACE(REPLACE(@MH, '{ICON}', 'calendar'), '{TIT}', 'Reuni&oacute;n de lanzamiento')
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fecha <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fecha" data-vct-pv-buf="TEXTO11" data-req="Fecha" data-vct-pv-def="' + CONVERT(VARCHAR(10), @HOY, 120) + '"></div>'
            + '<div class="vct-field vct-col-8"><label class="vct-label">Consultor</label>'
            +   '<select data-vct-pv-f="cons" data-vct-pv-buf="TEXTO16"><option value="">-</option>' + @LZ_COPT + '</select></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Participantes</label>'
            +   '<input type="text" class="vct-input" maxlength="500" data-vct-pv-f="part" data-vct-pv-buf="TEXTO12"></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Temas tratados</label>'
            +   '<textarea class="vct-textarea" rows="3" maxlength="1000" data-vct-pv-f="temas" data-vct-pv-buf="TEXTO13"></textarea></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Conclusiones / observaciones</label>'
            +   '<textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO14"></textarea></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-pv-switch"><input type="checkbox" data-vct-pv-f="realizada" data-vct-pv-buf="TEXTO15"><span>Reuni&oacute;n realizada (cumple la acci&oacute;n Reuni&oacute;n de lanzamiento)</span></label></div>'
            + '</div></div>' + @MF

            /* inicio del proyecto */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-sm" data-vct-component="modal" data-vct-pv-modal="in" data-vct-pv-cmd="PV_IN_GUARDAR" data-vct-pv-tnew="Iniciar proyecto" data-vct-pv-tedit="Editar inicio del proyecto">'
            + REPLACE(REPLACE(@MH, '{ICON}', 'check'), '{TIT}', 'Iniciar proyecto')
            + '<div class="vct-field vct-col-6"><label class="vct-label">Fecha de inicio real <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fecha" data-vct-pv-buf="TEXTO11" data-req="Fecha de inicio real" data-vct-pv-def="' + CONVERT(VARCHAR(10), @HOY, 120) + '" max="' + CONVERT(VARCHAR(10), @HOY, 120) + '"></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Observaciones</label>'
            +   '<textarea class="vct-textarea" rows="3" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO12"></textarea></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new><div class="vct-pv-sec">Aviso al consultor l&iacute;der</div></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new><label class="vct-pv-switch"><input type="checkbox" data-vct-pv-f="enviar" data-vct-pv-buf="TEXTO13" data-vct-pv-def="1"><span>Enviar mail al consultor (plantilla Proyecto en curso)</span></label></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new data-vct-pv-mail><label class="vct-label">Para <span class="vct-req">*</span></label>'
            +   '<input type="text" class="vct-input" maxlength="500" placeholder="nombre@dominio.com" data-vct-pv-f="para" data-vct-pv-buf="TEXTO14" data-vct-pv-def="' + REPLACE(REPLACE(@LIDER_MAIL,'"',''),'<','') + '">'
            +   '<div class="vct-help">' + CASE WHEN @LIDER_MAIL = '' THEN 'El consultor l&iacute;der no tiene email cargado: ingrese uno.' ELSE 'Email del consultor l&iacute;der; se puede cambiar.' END + '</div></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new data-vct-pv-mail><label class="vct-label">CC</label>'
            +   '<input type="text" class="vct-input" maxlength="500" placeholder="nombre@dominio.com; otro@dominio.com" data-vct-pv-f="cc" data-vct-pv-buf="TEXTO15"></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-new><div class="vct-help">El proyecto pasa a En curso y se genera la acci&oacute;n de carga del plan para el consultor l&iacute;der.</div></div>'
            + '</div></div>' + @MF;
    END;

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @ASSETS
        + '<div class="vct-page vct-page-main" data-vct-page data-vct-sidebar-id="3" data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID,''),'"','') + '">'
        + '<section class="vct-module vct-360-module vct-cliente360-module vct-360-visual-final vct-pv" data-vct-module data-vct-pv data-vct-entity-theme="cliente"'
        + ' data-vct-tabs data-vct-tabs-active="resumen" data-vct-tabs-reset="0" data-vct-pv-proyecto="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '"'
        + ' data-vct-pv-guid="' + REPLACE(@GUID_V360,'"','') + '"' + CASE WHEN @MSG <> '' OR @ERR <> '' THEN ' data-vct-pv-volver="' + @VOLVER + '"' ELSE '' END + '>'
        + @H + @MODAL
        + @LZ_MODALS /* SP_IDSELEC02_V1 */
        + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '">'
        + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value=""><input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">'
        + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value=""><input type="hidden" name="SP.TEXTO12" data-vct-field="TEXTO12" value="">'
        + '<input type="hidden" name="SP.TEXTO13" data-vct-field="TEXTO13" value=""><input type="hidden" name="SP.TEXTO14" data-vct-field="TEXTO14" value=""><input type="hidden" name="SP.TEXTO15" data-vct-field="TEXTO15" value=""><input type="hidden" name="SP.TEXTO16" data-vct-field="TEXTO16" value=""><input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">'
        + '</section></div>';
END
GO

DECLARE @TRG BIT;
SELECT @TRG = TRG FROM #P2V;
IF OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')) LIKE '%PV_LANZ_V1%'
    PRINT 'OK   dbo.VCT_MAIN_PROYECTO_V360 reemplazado (campanita, quitar consultor y lanzamiento).';
ELSE
    PRINT 'FALLO dbo.VCT_MAIN_PROYECTO_V360 no se actualizo: revisar el error de arriba.';
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
