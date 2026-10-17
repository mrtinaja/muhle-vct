USE [MuhlePROD];
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
                + '<link rel="stylesheet" href="../css/vct-proyecto-v360.css?v=22"><script src="../js/vct-proyecto-v360.js?v=18"></script><link rel="stylesheet" href="../css/vct-calendario.css?v=21"><script src="../js/vct-calendario.js?v=21"></script>';

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

    /* comando PV_PROY_GUARDAR (PV_PROY_EDIT_V1): edita los datos del paso 1 (alta) sin servicios, normas, horas ni rentabilidad.
       TEXTO11 nombre, TEXTO12 referencia, TEXTO13 tipo, TEXTO14 riesgo, TEXTO15 inicio, TEXTO16 fin (aaaa-mm-dd),
       TEXTO17 contacto del cliente, TEXTO18 analista (VCT_EMPLEADOS.ID), TEXTO19 fecha limite de lanzamiento.
       Permiso: EDIT de PROYECTOS (VCT_MAIN_GET_ACTIONS). Si cambia el analista, pasa al nuevo su fila del equipo y
       las acciones abiertas del proyecto que estaban a cargo del anterior. La fecha limite es el vencimiento de la
       accion abierta "Asignacion de consultor". Vuelve a la pestania Resumen. */
    DECLARE @PE_VOLVER BIT = 0;
    IF @B_FLAG = '1' AND @B_CMD = 'PV_PROY_GUARDAR'
    BEGIN
        DECLARE @PE_T14 VARCHAR(4000) = '', @PE_T15 VARCHAR(4000) = '', @PE_T16 VARCHAR(4000) = '', @PE_T17 VARCHAR(4000) = '',
                @PE_T18 VARCHAR(4000) = '', @PE_T19 VARCHAR(4000) = '';
        SELECT TOP 1 @PE_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @PE_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @PE_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))),
                     @PE_T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))), @PE_T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))), @PE_T19 = LTRIM(RTRIM(ISNULL(TEXTO19,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL,
               TEXTO15 = NULL, TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL
        WHERE PAR_KEY = @IPKEYJOB;
        SET @PE_VOLVER = 1;

        DECLARE @PE_CLI INT, @PE_INI DATETIME, @PE_FIN DATETIME, @PE_CON INT, @PE_ANA INT, @PE_LIM DATETIME, @PE_ANA_OLD INT,
                @PE_ACC_ASIG INT, @PE_ACC_INI DATETIME, @PE_SRV VARCHAR(400), @PE_N INT = 0;
        SELECT @PE_CLI = IDCLIENTE FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;
        SELECT TOP 1 @PE_ANA_OLD = EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'EMPLEADO' ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
        SELECT TOP 1 @PE_ACC_ASIG = A.ID, @PE_ACC_INI = A.FECHA_INICIO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'ASIGNACION_CONSULTOR'
        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
        WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID;

        IF @B_T13 IN ('IMPLEMENTACION','MANTENIMIENTO') SET @B_T13 = @B_T13; ELSE SET @B_T13 = '';
        IF @PE_T15 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@PE_T15,'-','')) = 1 SET @PE_INI = CONVERT(DATETIME, REPLACE(@PE_T15,'-',''), 112);
        IF @PE_T16 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@PE_T16,'-','')) = 1 SET @PE_FIN = CONVERT(DATETIME, REPLACE(@PE_T16,'-',''), 112);
        IF @PE_T17 <> '' AND PATINDEX('%[^0-9]%', @PE_T17) = 0 AND LEN(@PE_T17) <= 9 SET @PE_CON = CONVERT(INT, @PE_T17);
        IF @PE_T18 <> '' AND PATINDEX('%[^0-9]%', @PE_T18) = 0 AND LEN(@PE_T18) <= 9 SET @PE_ANA = CONVERT(INT, @PE_T18);
        IF @PE_T19 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@PE_T19,'-','')) = 1 SET @PE_LIM = CONVERT(DATETIME, REPLACE(@PE_T19,'-',''), 112);
        IF @PE_INI IS NOT NULL AND @PE_FIN IS NOT NULL
            SELECT TOP 1 @PE_SRV = ISNULL(PS.DESCRIPCION, 'Un servicio') + ' (' + ISNULL(CONVERT(VARCHAR(10), S.FECHA_INICIO, 103), '-') + ' - ' + ISNULL(CONVERT(VARCHAR(10), S.FECHA_FIN, 103), '-') + ')'
            FROM dbo.VCT_PROYECTOS_SERVICIOS S WITH(NOLOCK) LEFT JOIN dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK) ON PS.ID = S.ID_SERVICIO
            WHERE S.ID_PROYECTO = @ID_PROYECTO AND (S.FECHA_INICIO < @PE_INI OR S.FECHA_FIN > @PE_FIN) ORDER BY S.ORDEN, S.ID;

        IF @ID_PROYECTO IS NULL OR @PE_CLI IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'EDIT')
            SET @ERR = 'No tiene permiso para editar los datos del proyecto.';
        ELSE IF @B_T11 = '' SET @ERR = 'Nombre del proyecto es obligatorio.';
        ELSE IF LEN(@B_T11) > 300 SET @ERR = 'Nombre del proyecto no puede superar 300 caracteres.';
        ELSE IF LEN(@B_T12) > 300 SET @ERR = 'Referencia no puede superar 300 caracteres.';
        ELSE IF @B_T13 = '' SET @ERR = 'Tipo de proyecto es obligatorio.';
        ELSE IF @PE_T14 NOT IN ('Bajo','Medio','Alto') SET @ERR = 'Nivel de riesgo es obligatorio.';
        ELSE IF @PE_INI IS NULL SET @ERR = 'Fecha inicio es obligatoria.';
        ELSE IF @PE_FIN IS NULL SET @ERR = 'Fecha fin es obligatoria.';
        ELSE IF @PE_FIN < @PE_INI SET @ERR = 'La fecha fin del proyecto es anterior a la fecha inicio.';
        ELSE IF @PE_SRV IS NOT NULL SET @ERR = @PE_SRV + ' queda fuera del nuevo plazo del proyecto. Ajust' + CHAR(225) + ' primero las fechas del servicio.';
        ELSE IF @PE_T17 <> '' AND (@PE_CON IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CONTACTOS WITH(NOLOCK) WHERE ID = @PE_CON AND IDCLIENTE = @PE_CLI))
            SET @ERR = 'El contacto elegido no pertenece al cliente.';
        ELSE IF @PE_ANA IS NULL SET @ERR = 'Analista a cargo es obligatorio.';
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE ID = @PE_ANA AND ISNULL(ESTADO,'ACTIVO') = 'ACTIVO')
            SET @ERR = 'El analista elegido no existe o no est' + CHAR(225) + ' activo.';
        ELSE IF @PE_ACC_ASIG IS NOT NULL AND @PE_LIM IS NULL SET @ERR = 'Fecha l' + CHAR(237) + 'mite de lanzamiento es obligatoria.';
        ELSE IF @PE_ACC_ASIG IS NOT NULL AND @PE_ACC_INI IS NOT NULL AND @PE_LIM < CONVERT(DATE, @PE_ACC_INI)
            SET @ERR = 'La fecha l' + CHAR(237) + 'mite no puede ser anterior al ' + CONVERT(VARCHAR(10), @PE_ACC_INI, 103) + '.';

        IF @ERR = ''
        BEGIN
            BEGIN TRY
                BEGIN TRAN;
                UPDATE dbo.VCT_PROYECTOS
                   SET NOMBRE = @B_T11, REFERENCIA = NULLIF(@B_T12, ''), TIPO_PROYECTO = @B_T13, NIVEL_RIESGO = @PE_T14,
                       FECHA_INICIO = @PE_INI, FECHA_FIN = @PE_FIN, IDCONTACTO = @PE_CON, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_PROYECTO;
                IF ISNULL(@PE_ANA_OLD, -1) <> @PE_ANA
                BEGIN
                    UPDATE EQ SET EQ.ID_EMPLEADO = @PE_ANA
                    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
                    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ID_EMPLEADO = @PE_ANA_OLD;
                    IF @PE_ANA_OLD IS NOT NULL
                    BEGIN
                        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                        SELECT A.ID, A.ID_ESTADO, A.ID_ESTADO, 'REASIGNADA', 'Cambio de analista del proyecto.', 'USUARIO', GETDATE(), @IAGENTE
                        FROM dbo.VCT_ACCIONES A
                        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
                        WHERE A.ID_PROYECTO = @ID_PROYECTO
                          AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WHERE AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE'
                                      AND AP.ESTADO = 'ACTIVO' AND AP.TIPO_ENTIDAD = 'EMPLEADO' AND AP.ID_ENTIDAD = @PE_ANA_OLD);
                        UPDATE AP SET AP.ID_ENTIDAD = @PE_ANA
                        FROM dbo.VCT_ACCIONES_PARTICIPANTES AP
                        INNER JOIN dbo.VCT_ACCIONES A ON A.ID = AP.ID_ACCION AND A.ID_PROYECTO = @ID_PROYECTO
                        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
                        WHERE AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO' AND AP.TIPO_ENTIDAD = 'EMPLEADO' AND AP.ID_ENTIDAD = @PE_ANA_OLD;
                        SET @PE_N = @@ROWCOUNT;
                    END;
                END;
                IF @PE_ACC_ASIG IS NOT NULL
                    UPDATE dbo.VCT_ACCIONES SET FECHA_VENCIMIENTO = @PE_LIM, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @PE_ACC_ASIG AND ISNULL(FECHA_VENCIMIENTO, '19000101') <> @PE_LIM;
                COMMIT;
                SET @MSG = 'Datos del proyecto actualizados.'
                         + CASE WHEN @PE_N > 0 THEN ' ' + CONVERT(VARCHAR(10), @PE_N) + ' acci' + CHAR(243) + 'n(es) abierta(s) pasaron al nuevo analista.' ELSE '' END;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @ERR = 'No se pudo guardar: ' + LEFT(ERROR_MESSAGE(), 800);
            END CATCH;
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
            @F_ALTA DATETIME, @U_ALTA VARCHAR(100), @CONTACTO VARCHAR(400) = '', @F_INI_REAL DATETIME;
    IF @ID_PROYECTO IS NOT NULL
        SELECT @COD = P.CODIGO, @NOM = P.NOMBRE, @REF = P.REFERENCIA, @CLI = P.IDCLIENTE, @CLI_NOM = C.RAZON_SOCIAL,
               @EST_COD = E.CODIGO, @EST_DES = E.DESCRIPCION, @F_INI = P.FECHA_INICIO, @F_FIN = P.FECHA_FIN,
               @H_PROY = ISNULL(P.TOTAL_HORAS_PROYECTADAS, 0), @RIESGO = P.NIVEL_RIESGO, @TIPO_P = P.TIPO_PROYECTO,
               @ID_CONTACTO = P.IDCONTACTO, @F_ALTA = P.FECHA_ALTA, @U_ALTA = P.USUARIO_ALTA, @F_INI_REAL = P.FECHA_INICIO_REAL
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

    /* ---------- fila 3 del encabezado (PV_HEADER_V2): contacto principal y domicilio del cliente ----------
       Contacto: el elegido en el alta (VCT_PROYECTOS.IDCONTACTO); si no hay, el primer contacto del cliente
       con telefono o email (misma regla que la Vista 360 del cliente). Telefono / email: los del contacto;
       si no tiene, los principales del cliente. Domicilio: el principal del cliente (VCT_DOMICILIOS). */
    DECLARE @HC_ID INT = @ID_CONTACTO, @HC_NOM VARCHAR(300) = '', @HC_CARGO VARCHAR(150) = '', @HC_TEL VARCHAR(100) = '', @HC_MAIL VARCHAR(200) = '',
            @HC_DOM VARCHAR(600) = '', @HC_MAPS VARCHAR(1500) = '';
    IF @HC_ID IS NULL
        SELECT TOP 1 @HC_ID = C.ID FROM dbo.VCT_CONTACTOS C WITH(NOLOCK)
        WHERE C.IDCLIENTE = @CLI AND LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ISNULL(C.APELLIDO,''))) <> ''
        ORDER BY CASE WHEN C.ID_TELEFONO IS NOT NULL OR C.ID_EMAIL IS NOT NULL THEN 0 ELSE 1 END, C.ID;
    SELECT TOP 1 @HC_NOM = LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ' ' + ISNULL(C.APELLIDO,''))), @HC_CARGO = ISNULL(C.CARGO,''),
           @HC_TEL = ISNULL(CASE WHEN T.ID IS NULL THEN NULL
                                 WHEN T.CODAREA IS NULL THEN CONVERT(VARCHAR(50), T.NRO)
                                 ELSE '(' + CONVERT(VARCHAR(20), T.CODAREA) + ') ' + CONVERT(VARCHAR(50), T.NRO) END, ''),
           @HC_MAIL = ISNULL(M.EMAIL, '')
    FROM dbo.VCT_CONTACTOS C WITH(NOLOCK)
    LEFT JOIN dbo.VCT_TELEFONOS T WITH(NOLOCK) ON T.ID = C.ID_TELEFONO
    LEFT JOIN dbo.VCT_EMAILS M WITH(NOLOCK) ON M.ID = C.ID_EMAIL
    WHERE C.ID = @HC_ID;
    IF @HC_TEL = ''
        SELECT TOP 1 @HC_TEL = CASE WHEN T.CODAREA IS NULL THEN CONVERT(VARCHAR(50), T.NRO) ELSE '(' + CONVERT(VARCHAR(20), T.CODAREA) + ') ' + CONVERT(VARCHAR(50), T.NRO) END
        FROM dbo.VCT_TELEFONOS T WITH(NOLOCK) WHERE T.TIPO_ENTIDAD = 'CLIENTE' AND T.ID_ENTIDAD = @CLI
        ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, T.ID;
    IF @HC_MAIL = ''
        SELECT TOP 1 @HC_MAIL = ISNULL(E.EMAIL,'') FROM dbo.VCT_EMAILS E WITH(NOLOCK) WHERE E.TIPO_ENTIDAD = 'CLIENTE' AND E.ID_ENTIDAD = @CLI
        ORDER BY CASE WHEN UPPER(ISNULL(E.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, E.ID;
    SELECT TOP 1 @HC_DOM = LTRIM(RTRIM(
               ISNULL(D.CALLE,'') + CASE WHEN D.NRO IS NULL THEN '' ELSE ' ' + CONVERT(VARCHAR(20), D.NRO) END
             + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.PISO,''))), '') IS NULL THEN '' ELSE ' - Piso ' + D.PISO END
             + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.DEPTO,''))), '') IS NULL THEN '' ELSE ' ' + D.DEPTO END
             + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.LOCALIDAD,''))), '') IS NULL THEN '' ELSE ', ' + D.LOCALIDAD END
             + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.PROVINCIA,''))), '') IS NULL THEN '' ELSE ', ' + D.PROVINCIA END))
    FROM dbo.VCT_DOMICILIOS D WITH(NOLOCK) WHERE D.TIPO_ENTIDAD = 'CLIENTE' AND D.ID_ENTIDAD = @CLI
    ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, D.ID;
    SET @HC_DOM = LTRIM(RTRIM(ISNULL(@HC_DOM,'')));
    IF LEFT(@HC_DOM, 1) = ',' SET @HC_DOM = LTRIM(SUBSTRING(@HC_DOM, 2, 600));
    IF @HC_DOM <> ''
        SET @HC_MAPS = 'https://www.google.com/maps/search/?api=1&amp;query='
                     + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@HC_DOM,'%','%25'),' ','+'),'#','%23'),'&','%26'),'/','%2F'),'"','%22');

    /* ---------- usuario y permisos ---------- */
    DECLARE @EMP_U INT, @CONS_U INT, @PUEDE_EDIT BIT = 0, @GUID_V360 VARCHAR(100) = '';
    SELECT TOP 1 @EMP_U = ID FROM dbo.VCT_EMPLEADOS WITH(NOLOCK) WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U ORDER BY ID DESC;
    SELECT TOP 1 @CONS_U = ID FROM dbo.VCT_CONSULTORES WITH(NOLOCK) WHERE (LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U OR (LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,''))) = '' AND LOWER(REPLACE(LEFT(LTRIM(CONVERT(VARCHAR(150), NOMBRES)), 1) + LTRIM(RTRIM(CONVERT(VARCHAR(150), APELLIDOS))), ' ', '')) = @U)) /* CONS_LOGIN_V1 */ ORDER BY ID DESC;
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
    DECLARE @VOLVER VARCHAR(50) = CASE WHEN @PE_VOLVER = 1 THEN 'resumen' ELSE 'equipo' END, @PUEDE_LANZ BIT = @PUEDE_EDIT;
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
        /* el inicio y una reunion realizada no se editan ni se eliminan */
        IF @ERR = '' AND @B_CMD = 'PV_IN_BORRAR' SET @ERR = 'El inicio del proyecto no se puede eliminar.';
        IF @ERR = '' AND @B_CMD = 'PV_IN_GUARDAR' AND @LZ_ID IS NOT NULL SET @ERR = 'El inicio del proyecto no se puede editar.';
        IF @ERR = '' AND @B_CMD IN ('PV_RE_GUARDAR','PV_RE_BORRAR') AND @LZ_ID IS NOT NULL
           AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS WITH(NOLOCK) WHERE ID = @LZ_ID AND FECHA_CIERRE IS NOT NULL)
            SET @ERR = 'Una reuni' + CHAR(243) + 'n de lanzamiento realizada no se puede editar ni eliminar.';
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
    /* ======================= PARTE LOGISTICO: comandos (PV_PLAN_V1) =======================
       Tablas existentes: VCT_PROYECTOS_PLANES (cabecera), VCT_PROYECTOS_PLAN_ITEMS (items y sub-items con ID_PADRE),
       VCT_ACCIONES (ID_PLAN / ID_PLAN_ITEM: acciones de cada item).
       Comandos (TEXTO30): PV_PL_GENERAR, PV_PL_ITEM_GUARDAR, PV_PL_ITEM_BORRAR, PV_PL_ACC_GUARDAR, PV_PL_ACC_ESTADO, PV_PL_CERRAR.
       Permiso: consultores del equipo, analista del proyecto o EDIT de PROYECTOS. */
    DECLARE @PUEDE_PLAN BIT = @PUEDE_LANZ;
    IF @PUEDE_PLAN = 0 AND @CONS_U IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = @CONS_U)
        SET @PUEDE_PLAN = 1;

    IF @B_FLAG = '1' AND @B_CMD IN ('PV_PL_GENERAR','PV_PL_ITEM_GUARDAR','PV_PL_ITEM_BORRAR','PV_PL_ACC_GUARDAR','PV_PL_ACC_ESTADO','PV_PL_CERRAR')
    BEGIN
        DECLARE @PL_T14 VARCHAR(4000) = '', @PL_T15 VARCHAR(4000) = '', @PL_T16 VARCHAR(4000) = '', @PL_T17 VARCHAR(4000) = '', @PL_T18 VARCHAR(4000) = '',
                @PL_T19 VARCHAR(4000) = '', @PL_T20 VARCHAR(4000) = '', @PL_T21 VARCHAR(4000) = '';
        SELECT TOP 1 @PL_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @PL_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @PL_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))),
                     @PL_T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))), @PL_T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))),
                     @PL_T19 = LTRIM(RTRIM(ISNULL(TEXTO19,''))), @PL_T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))), @PL_T21 = LTRIM(RTRIM(ISNULL(TEXTO21,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL,
               TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL, TEXTO21 = NULL
        WHERE PAR_KEY = @IPKEYJOB;
        SET @VOLVER = 'plan';
        /* accion del plan (PL_ACC_TIPIF_V1): TEXTO21 tipo, TEXTO16 subtipo, TEXTO17 prioridad, TEXTO19 estado, TEXTO20 resultado,
           TEXTO13 fecha inicio, TEXTO12 vence, TEXTO15 responsable (fila de equipo), TEXTO18 detalle */
        DECLARE @PA_TIPO INT, @PA_SUB INT, @PA_SUB_TIPO INT, @PA_SUB_DES VARCHAR(150), @PA_PRIO INT, @PA_EST INT, @PA_EST_FIN BIT, @PA_RES INT, @PA_ITEM_TIT VARCHAR(400);

        DECLARE @PL_ID INT, @PL_PLAN INT, @PL_DOC INT, @PL_PS INT, @PL_LIDER INT, @PL_ANA INT, @PL_FI DATETIME, @PL_FF DATETIME, @PL_FR DATETIME,
                @PL_P_INI DATETIME, @PL_P_FIN DATETIME, @PL_PADRE INT, @PL_RESP INT, @PL_TIT VARCHAR(400), @PL_N INT = 0,
                @PL_OLD_FI DATETIME, @PL_OLD_FF DATETIME, @PL_OLD_TIT VARCHAR(400), @PL_ES_SUB BIT = 0,
                @PL_PEND INT, @PL_PROC INT, @PL_CUMP INT, @PL_CANC INT, @PL_PRIO INT, @PL_ST_ITEM INT, @PL_TP_ITEM INT, @PL_ST_AV INT, @PL_TP_AV INT,
                @PL_ACC INT, @PL_ACC_EST INT, @PL_COD VARCHAR(100), @PL_NOM VARCHAR(300), @PL_CLI INT;
        IF @B_SEL3 <> '' AND PATINDEX('%[^0-9]%', @B_SEL3) = 0 AND LEN(@B_SEL3) <= 9 SET @PL_ID = NULLIF(CONVERT(INT, @B_SEL3), 0);
        SELECT TOP 1 @PL_PLAN = ID FROM dbo.VCT_PROYECTOS_PLANES WITH(NOLOCK) WHERE ID_PROYECTO = @ID_PROYECTO ORDER BY VERSION DESC, ID DESC;
        SELECT @PL_P_INI = ISNULL(FECHA_INICIO_REAL, FECHA_INICIO), @PL_P_FIN = FECHA_FIN, @PL_COD = CODIGO, @PL_NOM = NOMBRE, @PL_CLI = IDCLIENTE
        FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;
        SELECT @PL_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE';
        SELECT @PL_PROC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'EN_PROCESO';
        SELECT @PL_CUMP = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';
        SELECT @PL_CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';
        SELECT @PL_ST_ITEM = ID, @PL_TP_ITEM = ID_TIPO FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'TRABAJO_PLAN_ITEM';
        SELECT @PL_ST_AV = ID, @PL_TP_AV = ID_TIPO FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'AVISO_VENCIMIENTO';
        SELECT TOP 1 @PL_PRIO = A.ID_PRIORIDAD FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_PLAN'
        WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID DESC;
        IF @PL_PRIO IS NULL SELECT TOP 1 @PL_PRIO = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) ORDER BY ID;
        SELECT TOP 1 @PL_LIDER = EQ.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'CONSULTOR_LIDER'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.ID;
        SELECT TOP 1 @PL_ANA = EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

        IF @ID_PROYECTO IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        IF @ERR = '' AND @PUEDE_PLAN = 0 SET @ERR = 'No tiene permiso para editar el parte log' + CHAR(237) + 'stico de este proyecto.';
        IF @ERR = '' AND @B_CMD <> 'PV_PL_GENERAR' AND @PL_PLAN IS NULL SET @ERR = 'El proyecto todav' + CHAR(237) + 'a no tiene plan.';

        /* fechas aaaa-mm-dd: TEXTO12 inicio / vence, TEXTO13 fin, TEXTO14 fin real */
        IF @ERR = '' AND @B_CMD IN ('PV_PL_ITEM_GUARDAR','PV_PL_ACC_GUARDAR')
        BEGIN
            IF @B_T12 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T12,'-','')) = 1 SET @PL_FI = CONVERT(DATETIME, REPLACE(@B_T12,'-',''), 112);
            IF @B_T13 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T13,'-','')) = 1 SET @PL_FF = CONVERT(DATETIME, REPLACE(@B_T13,'-',''), 112);
            IF @PL_T14 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@PL_T14,'-','')) = 1 SET @PL_FR = CONVERT(DATETIME, REPLACE(@PL_T14,'-',''), 112);
            IF (@B_T12 <> '' AND @PL_FI IS NULL) OR (@B_T13 <> '' AND @PL_FF IS NULL) OR (@PL_T14 <> '' AND @PL_FR IS NULL) SET @ERR = 'Alguna de las fechas no es v' + CHAR(225) + 'lida.';
            IF @PL_T15 <> '' AND PATINDEX('%[^0-9]%', @PL_T15) = 0 AND LEN(@PL_T15) <= 9 SET @PL_RESP = CONVERT(INT, @PL_T15);
            IF @ERR = '' AND @PL_RESP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK) WHERE ID = @PL_RESP AND ID_PROYECTO = @ID_PROYECTO AND ESTADO = 'ACTIVO')
                SET @ERR = 'El responsable elegido no es del equipo del proyecto.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_GENERAR'
        BEGIN
            SELECT TOP 1 @PL_DOC = ID FROM dbo.VCT_PRM_DOCUMENTOS WITH(NOLOCK) WHERE CODIGO = 'RE-PP-007' AND ACTIVO = 1 AND ISNULL(TIPO_DETALLE,'') = 'PLAN' ORDER BY ID DESC;
            IF @PL_DOC IS NULL SELECT TOP 1 @PL_DOC = ID FROM dbo.VCT_PRM_DOCUMENTOS WITH(NOLOCK) WHERE CODIGO = 'RE-PP-007' AND ACTIVO = 1 ORDER BY ID DESC;
            SELECT TOP 1 @PL_PS = PS.ID FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO AND UPPER(LEFT(ISNULL(S.CODIGO,''),2)) = 'CO'
            WHERE PS.ID_PROYECTO = @ID_PROYECTO ORDER BY PS.ID;
            IF @PL_PLAN IS NOT NULL SET @ERR = 'El proyecto ya tiene plan.';
            ELSE IF @PL_PS IS NULL SET @ERR = 'El parte log' + CHAR(237) + 'stico solo existe si el proyecto tiene consultor' + CHAR(237) + 'a.';
            ELSE IF @PL_DOC IS NULL SET @ERR = 'No existe el plan base RE-PP-007 activo en parametr' + CHAR(237) + 'a.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ITEM_GUARDAR'
        BEGIN
            SET @PL_TIT = LEFT(@B_T11, 400);
            IF @PL_T16 <> '' AND PATINDEX('%[^0-9]%', @PL_T16) = 0 AND LEN(@PL_T16) <= 9 SET @PL_PADRE = NULLIF(CONVERT(INT, @PL_T16), 0);
            IF @PL_ID IS NOT NULL
            BEGIN
                SELECT @PL_OLD_FI = FECHA_INICIO, @PL_OLD_FF = FECHA_VENCIMIENTO, @PL_OLD_TIT = TITULO, @PL_PADRE = ID_PADRE
                FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_ID AND ID_PLAN = @PL_PLAN;
                IF @PL_OLD_TIT IS NULL SET @ERR = 'El ' + CHAR(237) + 'tem no pertenece al plan de este proyecto.';
            END;
            IF @ERR = '' AND @PL_PADRE IS NOT NULL
            BEGIN
                SET @PL_ES_SUB = 1;
                IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_PADRE AND ID_PLAN = @PL_PLAN AND ID_PADRE IS NULL)
                    SET @ERR = 'El ' + CHAR(237) + 'tem padre no es v' + CHAR(225) + 'lido.';
            END;
            IF @ERR = '' AND @PL_TIT = '' SET @ERR = CHAR(205) + 'tem es obligatorio.';
            IF @ERR = '' AND @PL_ES_SUB = 0
            BEGIN
                IF @PL_FI IS NOT NULL AND @PL_FF IS NOT NULL AND @PL_FF < @PL_FI SET @ERR = 'La fecha fin no puede ser anterior a la de inicio.';
                ELSE IF @PL_FI IS NOT NULL AND @PL_P_INI IS NOT NULL AND @PL_FI < CONVERT(DATE, @PL_P_INI)
                    SET @ERR = 'La fecha de inicio no puede ser anterior al inicio del proyecto (' + CONVERT(VARCHAR(10), @PL_P_INI, 103) + ').';
                ELSE IF @PL_FF IS NOT NULL AND @PL_P_FIN IS NOT NULL AND @PL_FF > @PL_P_FIN
                    SET @ERR = 'La fecha fin no puede superar el fin del proyecto (' + CONVERT(VARCHAR(10), @PL_P_FIN, 103) + ').';
            END;
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ITEM_BORRAR'
        BEGIN
            IF @PL_ID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_ID AND ID_PLAN = @PL_PLAN)
                SET @ERR = 'El ' + CHAR(237) + 'tem no pertenece al plan de este proyecto.';
            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID_PADRE = @PL_ID)
                SET @ERR = 'El ' + CHAR(237) + 'tem tiene sub-' + CHAR(237) + 'tems: elim' + CHAR(237) + 'nelos primero.';
            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES WITH(NOLOCK) WHERE ID_PLAN_ITEM = @PL_ID)
                SET @ERR = 'El ' + CHAR(237) + 'tem tiene acciones: no se puede eliminar.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ACC_GUARDAR'
        BEGIN
            /* IDSELEC03 = item (o sub-item); el rango lo da el item superior */
            DECLARE @PL_TOP INT, @PL_TOP_FI DATETIME, @PL_TOP_FF DATETIME;
            SELECT @PL_TOP = ISNULL(I.ID_PADRE, I.ID) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) WHERE I.ID = @PL_ID AND I.ID_PLAN = @PL_PLAN;
            SELECT @PL_TOP_FI = FECHA_INICIO, @PL_TOP_FF = FECHA_VENCIMIENTO FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_TOP;
            IF @PL_TOP IS NULL SET @ERR = 'El ' + CHAR(237) + 'tem no pertenece al plan de este proyecto.';
            ELSE
            BEGIN
                SELECT @PA_ITEM_TIT = TITULO FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_ID;
                IF @PL_T21 <> '' AND PATINDEX('%[^0-9]%', @PL_T21) = 0 AND LEN(@PL_T21) <= 9
                    SELECT @PA_TIPO = ID FROM dbo.VCT_PRM_ACCIONES_TIPOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T21) AND ACTIVO = 1;
                IF @PL_T16 <> '' AND PATINDEX('%[^0-9]%', @PL_T16) = 0 AND LEN(@PL_T16) <= 9
                    SELECT @PA_SUB = ID, @PA_SUB_TIPO = ID_TIPO, @PA_SUB_DES = DESCRIPCION FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T16) AND ACTIVO = 1;
                IF @PL_T17 <> '' AND PATINDEX('%[^0-9]%', @PL_T17) = 0 AND LEN(@PL_T17) <= 9
                    SELECT @PA_PRIO = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T17) AND ACTIVO = 1;
                IF @PL_T19 <> '' AND PATINDEX('%[^0-9]%', @PL_T19) = 0 AND LEN(@PL_T19) <= 9
                    SELECT @PA_EST = ID, @PA_EST_FIN = ES_FINAL FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T19) AND ACTIVO = 1;
                IF @PL_T20 <> '' AND PATINDEX('%[^0-9]%', @PL_T20) = 0 AND LEN(@PL_T20) <= 9
                    SELECT @PA_RES = ID FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T20) AND ACTIVO = 1;

                IF @PA_TIPO IS NULL SET @ERR = 'Tipo es obligatorio.';
                ELSE IF @PA_SUB IS NULL SET @ERR = 'Subtipo es obligatorio.';
                ELSE IF @PA_SUB_TIPO <> @PA_TIPO SET @ERR = 'El subtipo no corresponde al tipo elegido.';
                ELSE IF @PA_PRIO IS NULL SET @ERR = 'Prioridad es obligatoria.';
                ELSE IF @PA_EST IS NULL SET @ERR = 'Estado es obligatorio.';
                ELSE IF @PA_EST_FIN = 1 AND @PA_RES IS NULL SET @ERR = 'Resultado es obligatorio para un estado final.';
                ELSE IF @B_T13 <> '' AND @PL_FF IS NULL SET @ERR = 'La fecha de inicio no es v' + CHAR(225) + 'lida.';
                ELSE IF @PL_FI IS NULL SET @ERR = 'Vence es obligatorio.';
                ELSE IF @PL_FF IS NOT NULL AND @PL_FI < @PL_FF SET @ERR = 'Vence no puede ser anterior a la fecha de inicio.';
                ELSE IF @PL_RESP IS NULL SET @ERR = 'Responsable es obligatorio.';
                ELSE IF @PL_TOP_FI IS NOT NULL AND ISNULL(@PL_FF, @PL_FI) < CONVERT(DATE, @PL_TOP_FI)
                    SET @ERR = 'La acci' + CHAR(243) + 'n no puede empezar antes del inicio del ' + CHAR(237) + 'tem (' + CONVERT(VARCHAR(10), @PL_TOP_FI, 103) + ').';
                ELSE IF @PL_TOP_FF IS NOT NULL AND @PL_FI > @PL_TOP_FF
                    SET @ERR = 'La acci' + CHAR(243) + 'n no puede vencer despu' + CHAR(233) + 's del fin del ' + CHAR(237) + 'tem (' + CONVERT(VARCHAR(10), @PL_TOP_FF, 103) + ').';
                IF @ERR = '' AND ISNULL(@PA_EST_FIN, 0) = 0 SET @PA_RES = NULL;
            END;
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ACC_ESTADO'
        BEGIN
            SELECT @PL_ACC = A.ID, @PL_ACC_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            WHERE A.ID = @PL_ID AND A.ID_PROYECTO = @ID_PROYECTO AND A.ID_PLAN_ITEM IS NOT NULL;
            IF @PL_ACC IS NULL SET @ERR = 'La acci' + CHAR(243) + 'n no es del plan de este proyecto.';
            ELSE IF UPPER(@B_T11) NOT IN ('CUMPLIDA','PENDIENTE') SET @ERR = 'Estado no v' + CHAR(225) + 'lido.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_CERRAR'
        BEGIN
            SELECT TOP 1 @PL_ACC = A.ID, @PL_ACC_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_PLAN'
            INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
            WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID;
            SELECT @PL_N = COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK)
            WHERE ID_PLAN = @PL_PLAN AND ID_PADRE IS NULL AND (FECHA_INICIO IS NULL OR FECHA_VENCIMIENTO IS NULL);
            IF @PL_ACC IS NULL SET @ERR = 'No hay una acci' + CHAR(243) + 'n "Carga del plan" abierta.';
            ELSE IF @PL_N > 0 SET @ERR = 'Faltan fechas de inicio y fin en ' + CONVERT(VARCHAR(10), @PL_N) + CHAR(237) + 'tem(s) del plan.';
        END;

        /* ---------- grabar ---------- */
        IF @ERR = ''
        BEGIN
            BEGIN TRY
                BEGIN TRAN;

                IF @B_CMD = 'PV_PL_GENERAR'
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_PLANES (ID_PROYECTO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, VERSION, ESTADO, ID_CONSULTOR_RESPONSABLE, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @PL_PS, @PL_DOC, 1, 'VIGENTE', @PL_LIDER, ISNULL(@PL_P_INI, @HOY), GETDATE(), @IAGENTE);
                    SET @PL_PLAN = SCOPE_IDENTITY();
                    IF UPPER(@B_T11) <> 'BLANCO'
                    BEGIN
                        INSERT INTO dbo.VCT_PROYECTOS_PLAN_ITEMS (ID_PLAN, ID_DOCUMENTO_ITEM, CODIGO_ITEM, TITULO, GRUPO, ORDEN, OBLIGATORIO, ESTADO, PORCENTAJE_AVANCE, FECHA_ALTA, USUARIO_ALTA)
                        SELECT @PL_PLAN, I.ID, I.CODIGO_ITEM, LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(I.DESCRIPCION,''))), CHAR(13), ' '), CHAR(10), ' '), 400),
                               /* hitos (auditorias): items "Realizacion de ..." del plan base */
                               CASE WHEN I.DESCRIPCION LIKE 'Realizaci%n de%' THEN 'HITO' ELSE I.GRUPO END,
                               ISNULL(I.ORDEN, 999), ISNULL(I.OBLIGATORIO, 0), 'PENDIENTE', 0, GETDATE(), @IAGENTE
                        FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
                        WHERE I.ID_DOCUMENTO = @PL_DOC AND I.ACTIVO = 1 AND I.ID_PADRE IS NULL
                        ORDER BY I.ORDEN, I.ID;
                        SET @PL_N = @@ROWCOUNT;
                    END;
                    /* la accion "Carga del plan" pasa a En proceso y queda ligada al plan */
                    SELECT TOP 1 @PL_ACC = A.ID, @PL_ACC_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A
                    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_PLAN'
                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_ESTADO = @PL_PEND ORDER BY A.ID;
                    IF @PL_ACC IS NOT NULL AND @PL_PROC IS NOT NULL
                    BEGIN
                        UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @PL_PROC, ID_PLAN = @PL_PLAN, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @PL_ACC;
                        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                        VALUES (@PL_ACC, @PL_ACC_EST, @PL_PROC, 'PLAN_GENERADO', 'Se gener' + CHAR(243) + ' el plan del proyecto.', 'USUARIO', GETDATE(), @IAGENTE);
                    END;
                    SET @MSG = CASE WHEN UPPER(@B_T11) = 'BLANCO' THEN 'Plan creado en blanco: agregue los ' + CHAR(237) + 'tems.'
                                    ELSE 'Plan generado con ' + CONVERT(VARCHAR(10), @PL_N) + ' ' + CHAR(237) + 'tems del plan base. Defina fechas y responsables de cada ' + CHAR(237) + 'tem.' END;
                END;

                IF @B_CMD = 'PV_PL_ITEM_GUARDAR'
                BEGIN
                    IF @PL_ID IS NULL
                    BEGIN
                        INSERT INTO dbo.VCT_PROYECTOS_PLAN_ITEMS (ID_PLAN, ID_PADRE, TITULO, GRUPO, ORDEN, OBLIGATORIO, ESTADO, ID_RESPONSABLE_EQUIPO,
                                                                FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, PORCENTAJE_AVANCE, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                        SELECT @PL_PLAN, @PL_PADRE, @PL_TIT, CASE WHEN @PL_T17 = '1' THEN 'HITO' ELSE 'PLAN ESTRATEGICO' END,
                               ISNULL((SELECT MAX(ORDEN) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN = @PL_PLAN), 0) + 1,
                               0, 'PENDIENTE', @PL_RESP,
                               CASE WHEN @PL_ES_SUB = 1 THEN NULL ELSE @PL_FI END, CASE WHEN @PL_ES_SUB = 1 THEN NULL ELSE @PL_FF END, @PL_FR,
                               CASE WHEN @PL_FR IS NOT NULL THEN 100 ELSE 0 END, NULLIF(LEFT(@PL_T18, 2000), ''), GETDATE(), @IAGENTE;
                        SET @PL_ID = SCOPE_IDENTITY();
                        SET @MSG = CASE WHEN @PL_ES_SUB = 1 THEN 'Sub-' + CHAR(237) + 'tem agregado.' ELSE CHAR(205) + 'tem agregado.' END;
                    END
                    ELSE
                    BEGIN
                        UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS
                           SET TITULO = @PL_TIT, ID_RESPONSABLE_EQUIPO = @PL_RESP,
                               GRUPO = CASE WHEN @PL_T17 = '1' THEN 'HITO' WHEN GRUPO = 'HITO' THEN 'PLAN ESTRATEGICO' ELSE GRUPO END,
                               FECHA_INICIO = CASE WHEN @PL_ES_SUB = 1 THEN NULL ELSE @PL_FI END,
                               FECHA_VENCIMIENTO = CASE WHEN @PL_ES_SUB = 1 THEN NULL ELSE @PL_FF END,
                               FECHA_CIERRE = @PL_FR, OBSERVACIONES = NULLIF(LEFT(@PL_T18, 2000), ''), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                         WHERE ID = @PL_ID;
                        SET @MSG = CHAR(205) + 'tem actualizado.';

                        /* cambio de fechas de un item ya fechado: accion de aviso al analista */
                        IF @PL_ES_SUB = 0 AND @PL_ANA IS NOT NULL AND @PL_ST_AV IS NOT NULL
                           AND ((@PL_OLD_FI IS NOT NULL AND ISNULL(CONVERT(DATE, @PL_OLD_FI), '19000101') <> ISNULL(CONVERT(DATE, @PL_FI), '19000101'))
                             OR (@PL_OLD_FF IS NOT NULL AND ISNULL(CONVERT(DATE, @PL_OLD_FF), '19000101') <> ISNULL(CONVERT(DATE, @PL_FF), '19000101')))
                        BEGIN
                            DECLARE @PL_NEWA INT;
                            INSERT INTO dbo.VCT_ACCIONES (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN, ID_PLAN_ITEM,
                                                          REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_ALTA, USUARIO_ALTA)
                            VALUES ('AUTOMATICA', @PL_TP_AV, @PL_ST_AV, @PL_PEND, @PL_PRIO,
                                    LEFT('Cambio de fecha en el plan: ' + @PL_TIT + ' - ' + ISNULL(@PL_COD,''), 300),
                                    'Fechas anteriores: ' + ISNULL(CONVERT(VARCHAR(10), @PL_OLD_FI, 103), '-') + ' a ' + ISNULL(CONVERT(VARCHAR(10), @PL_OLD_FF, 103), '-')
                                  + '. Nuevas: ' + ISNULL(CONVERT(VARCHAR(10), @PL_FI, 103), '-') + ' a ' + ISNULL(CONVERT(VARCHAR(10), @PL_FF, 103), '-') + '.',
                                    @PL_CLI, @ID_PROYECTO, @PL_PLAN, @PL_ID, 0, 0, GETDATE(), GETDATE(), DATEADD(DAY, 2, @HOY), GETDATE(), @IAGENTE);
                            SET @PL_NEWA = SCOPE_IDENTITY();
                            INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                            VALUES (@PL_NEWA, 'RESPONSABLE', 'EMPLEADO', @PL_ANA, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                            VALUES (@PL_NEWA, NULL, @PL_PEND, 'ALTA', 'Generada al cambiar las fechas de un ' + CHAR(237) + 'tem del plan.', 'SISTEMA', GETDATE(), @IAGENTE);
                            SET @MSG = @MSG + ' Se avis' + CHAR(243) + ' al analista del cambio de fechas.';
                        END;
                    END;
                END;

                IF @B_CMD = 'PV_PL_ITEM_BORRAR'
                BEGIN
                    DELETE FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID = @PL_ID AND ID_PLAN = @PL_PLAN;
                    SET @MSG = CHAR(205) + 'tem eliminado.';
                END;

                IF @B_CMD = 'PV_PL_ACC_GUARDAR'
                BEGIN
                    DECLARE @PL_NEWB INT;
                    INSERT INTO dbo.VCT_ACCIONES (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN, ID_PLAN_ITEM,
                                                  REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
                    VALUES ('MANUAL', @PA_TIPO, @PA_SUB, @PA_EST, @PA_PRIO, @PA_RES, LEFT(@PA_SUB_DES + ' - ' + ISNULL(@PA_ITEM_TIT, ''), 300), NULLIF(@PL_T18, ''), @PL_CLI, @ID_PROYECTO, @PL_PLAN, @PL_ID,
                            0, 0, GETDATE(), @PL_FF, @PL_FI, CASE WHEN @PA_EST_FIN = 1 THEN GETDATE() END, GETDATE(), @IAGENTE);
                    SET @PL_NEWB = SCOPE_IDENTITY();
                    INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    SELECT @PL_NEWB, 'RESPONSABLE', EQ.TIPO_MIEMBRO, CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE
                    FROM dbo.VCT_PROYECTOS_EQUIPO EQ WHERE EQ.ID = @PL_RESP;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@PL_NEWB, NULL, @PA_EST, 'ALTA', 'Acci' + CHAR(243) + 'n del plan.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n agregada al ' + CHAR(237) + 'tem.';
                END;

                IF @B_CMD = 'PV_PL_ACC_ESTADO'
                BEGIN
                    UPDATE dbo.VCT_ACCIONES
                       SET ID_ESTADO = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN @PL_CUMP ELSE @PL_PEND END,
                           FECHA_CIERRE = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN GETDATE() END, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @PL_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@PL_ACC, @PL_ACC_EST, CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN @PL_CUMP ELSE @PL_PEND END,
                            CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'CUMPLIDA' ELSE 'REABIERTA' END, 'Desde el parte log' + CHAR(237) + 'stico.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'Acci' + CHAR(243) + 'n cumplida.' ELSE 'Acci' + CHAR(243) + 'n reabierta.' END;
                END;

                IF @B_CMD = 'PV_PL_CERRAR'
                BEGIN
                    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @PL_CUMP, FECHA_CIERRE = GETDATE(), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @PL_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@PL_ACC, @PL_ACC_EST, @PL_CUMP, 'CUMPLIDA', 'Plan cargado con fechas en todos los ' + CHAR(237) + 'tems.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Carga del plan finalizada: la acci' + CHAR(243) + 'n qued' + CHAR(243) + ' cumplida.';
                END;

                /* avance y estado de los items (avance = acciones cumplidas / acciones no canceladas) */
                UPDATE I SET
                    PORCENTAJE_AVANCE = CASE WHEN X.TOT > 0 THEN CONVERT(INT, ROUND(100.0 * X.CUMP / X.TOT, 0)) WHEN I.FECHA_CIERRE IS NOT NULL THEN 100 ELSE 0 END,
                    ESTADO = CASE WHEN I.FECHA_CIERRE IS NOT NULL THEN 'CUMPLIDO'
                                  WHEN T.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, T.FECHA_VENCIMIENTO) < @HOY THEN 'VENCIDO'
                                  WHEN T.FECHA_INICIO IS NOT NULL AND CONVERT(DATE, T.FECHA_INICIO) <= @HOY THEN 'EN_CURSO'
                                  ELSE 'PENDIENTE' END
                FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
                INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS T ON T.ID = ISNULL(I.ID_PADRE, I.ID)
                OUTER APPLY (SELECT COUNT(*) AS TOT, SUM(CASE WHEN A.ID_ESTADO = @PL_CUMP THEN 1 ELSE 0 END) AS CUMP
                             FROM dbo.VCT_ACCIONES A
                             WHERE A.ID_ESTADO <> ISNULL(@PL_CANC, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@PL_ST_AV, -1)
                               AND (A.ID_PLAN_ITEM = I.ID OR A.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))) X
                WHERE I.ID_PLAN = @PL_PLAN;

                COMMIT;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @MSG = '';
                SET @ERR = LEFT('No se pudo grabar el plan: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
        END;
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


    /* ---------- parte logistico: datos (PV_PLAN_V1) ---------- */
    DECLARE @PLN INT, @PLN_DOC VARCHAR(400) = '', @PLN_TIENE_CO BIT = 0, @PL_AV_ST INT, @PL_CANC_ST INT, @PL_CUMP_ST INT;
    SELECT TOP 1 @PLN = P.ID, @PLN_DOC = ISNULL(D.CODIGO, '') + ISNULL(' &middot; ' + REPLACE(REPLACE(D.COMENTARIO,'<',''),'>',''), '')
    FROM dbo.VCT_PROYECTOS_PLANES P WITH(NOLOCK) LEFT JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) ON D.ID = P.ID_DOCUMENTO
    WHERE P.ID_PROYECTO = @ID_PROYECTO ORDER BY P.VERSION DESC, P.ID DESC;
    IF EXISTS (SELECT 1 FROM #SV WHERE UPPER(LEFT(ISNULL(COD,''),2)) = 'CO') SET @PLN_TIENE_CO = 1;
    SELECT @PL_AV_ST = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'AVISO_VENCIMIENTO';
    SELECT @PL_CANC_ST = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';
    SELECT @PL_CUMP_ST = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';

    CREATE TABLE #PI (ID INT, PADRE INT, ORD INT, TIT VARCHAR(400), HITO BIT, FI DATETIME, FF DATETIME, FR DATETIME, EST VARCHAR(20),
                      RESP INT, RESP_INI VARCHAR(4), RESP_NOM VARCHAR(300), OBS VARCHAR(2000), TOT INT, CUMP INT, AV INT,
                      CODE VARCHAR(20), NAME VARCHAR(400), CAP VARCHAR(10), CAP_ORD INT, VEN INT, HTML VARCHAR(MAX));
    CREATE TABLE #PA (ID INT, ITEM INT, TOP_ITEM INT, TIT VARCHAR(300), SUB VARCHAR(150), VENCE DATETIME, CUMPLIDA BIT, FINAL BIT, SIT CHAR(1), RESP_INI VARCHAR(4), RESP_NOM VARCHAR(300),
                      DET VARCHAR(300), HTML VARCHAR(MAX));
    IF @PLN IS NOT NULL
    BEGIN
        INSERT INTO #PI (ID, PADRE, ORD, TIT, HITO, FI, FF, FR, RESP, OBS)
        SELECT I.ID, I.ID_PADRE, ISNULL(I.ORDEN, 999), REPLACE(REPLACE(ISNULL(I.TITULO,''), CHAR(13), ' '), CHAR(10), ' '),
               CASE WHEN I.GRUPO = 'HITO' THEN 1 ELSE 0 END, I.FECHA_INICIO, I.FECHA_VENCIMIENTO, I.FECHA_CIERRE, I.ID_RESPONSABLE_EQUIPO, ISNULL(I.OBSERVACIONES,'')
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) WHERE I.ID_PLAN = @PLN;
        UPDATE P SET RESP_INI = Q.INI, RESP_NOM = Q.NOMBRE FROM #PI P
        INNER JOIN dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK) ON EQ.ID = P.RESP
        INNER JOIN #EQ Q ON Q.TIPO = EQ.TIPO_MIEMBRO AND Q.ID_ENT = CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END;

        INSERT INTO #PA (ID, ITEM, TIT, SUB, VENCE, CUMPLIDA, FINAL, RESP_INI, RESP_NOM, DET)
        SELECT A.ID, A.ID_PLAN_ITEM, ISNULL(A.TITULO,''), ISNULL(ST.DESCRIPCION,''), A.FECHA_VENCIMIENTO,
               CASE WHEN A.ID_ESTADO = @PL_CUMP_ST THEN 1 ELSE 0 END, ISNULL(E.ES_FINAL, 0), ISNULL(RP.INI,''), ISNULL(RP.NOMBRE,''),
               LEFT(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(400), A.DESCRIPCION),''), CHAR(13), ' '), CHAR(10), ' '), 300)
        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
        LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO
        OUTER APPLY (SELECT TOP 1 Q.INI, Q.NOMBRE FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
                     INNER JOIN #EQ Q ON Q.TIPO = AP.TIPO_ENTIDAD AND Q.ID_ENT = AP.ID_ENTIDAD
                     WHERE AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO' ORDER BY AP.PRINCIPAL DESC, AP.ID) RP
        WHERE A.ID_PLAN_ITEM IN (SELECT ID FROM #PI) AND A.ID_ESTADO <> ISNULL(@PL_CANC_ST, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@PL_AV_ST, -1);
        UPDATE A SET TOP_ITEM = ISNULL(P.PADRE, P.ID),
                     SIT = CASE WHEN A.FINAL = 1 THEN 'C' WHEN A.VENCE IS NOT NULL AND CONVERT(DATE, A.VENCE) < @HOY THEN 'V' ELSE 'A' END
        FROM #PA A INNER JOIN #PI P ON P.ID = A.ITEM;

        UPDATE P SET TOT = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID OR A.ITEM IN (SELECT S.ID FROM #PI S WHERE S.PADRE = P.ID)), 0),
                     CUMP = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.CUMPLIDA = 1 AND (A.ITEM = P.ID OR A.ITEM IN (SELECT S.ID FROM #PI S WHERE S.PADRE = P.ID))), 0)
        FROM #PI P;
        UPDATE P SET AV = CASE WHEN TOT > 0 THEN CONVERT(INT, ROUND(100.0 * CUMP / TOT, 0)) WHEN FR IS NOT NULL THEN 100 ELSE 0 END FROM #PI P;
        /* estado del item: fechas del item superior (los sub-items heredan) */
        UPDATE P SET EST = CASE WHEN P.FR IS NOT NULL THEN 'CUMPLIDO'
                                WHEN T.FF IS NOT NULL AND CONVERT(DATE, T.FF) < @HOY THEN 'VENCIDO'
                                WHEN T.FI IS NOT NULL AND CONVERT(DATE, T.FI) <= @HOY THEN 'EN_CURSO'
                                ELSE 'PENDIENTE' END
        FROM #PI P INNER JOIN #PI T ON T.ID = ISNULL(P.PADRE, P.ID);
    END;
    DECLARE @PL_TOT INT = (SELECT COUNT(*) FROM #PA), @PL_OK INT = (SELECT COUNT(*) FROM #PA WHERE CUMPLIDA = 1),
            @PL_NI INT = (SELECT COUNT(*) FROM #PI WHERE PADRE IS NULL), @PL_PCT INT = 0,
            @PL_C INT = (SELECT COUNT(*) FROM #PI WHERE PADRE IS NULL AND EST = 'CUMPLIDO'),
            @PL_E INT = (SELECT COUNT(*) FROM #PI WHERE PADRE IS NULL AND EST = 'EN_CURSO'),
            @PL_P INT = (SELECT COUNT(*) FROM #PI WHERE PADRE IS NULL AND EST = 'PENDIENTE'),
            @PL_V INT = (SELECT COUNT(*) FROM #PI WHERE PADRE IS NULL AND EST = 'VENCIDO');
    IF @PL_TOT > 0 SET @PL_PCT = CONVERT(INT, ROUND(100.0 * @PL_OK / @PL_TOT, 0));

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
                 WHEN SUB_COD IN ('CARGA_PLAN','TRABAJO_PLAN_ITEM') THEN 'data-vct-pv-goto="plan"'
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
    /* encabezado: servicios del proyecto, hasta 3 normas (+N), escapes de la fila 3 (PV_HEADER_V2) */
    DECLARE @HD_SRV VARCHAR(MAX) = '', @HD_NOR VARCHAR(MAX) = '', @HD_NOR_MAS VARCHAR(2000) = '', @HD_N_NOR INT = 0;
    SELECT @HD_SRV = ISNULL((
        SELECT '<span class="vctdg-svc is-' + LOWER(LEFT(CASE WHEN COD = '' THEN 'xx' ELSE COD END, 2)) + ' is-on" title="'
             + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'"',''),'<','') + ' &middot; ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h">'
             + '<span data-vct-icon="' + CASE LEFT(COD, 2) WHEN 'AU' THEN 'clipboard-check' WHEN 'CA' THEN 'users' ELSE 'briefcase' END + '"></span></span>'
        FROM #SV ORDER BY IDX FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @HD_N_NOR = COUNT(*) FROM #NO;
    SELECT @HD_NOR = ISNULL((
        SELECT TOP 3 '<span class="vct-pv-hd-nor" title="' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'"',''),'<','') + '">' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
        FROM #NO ORDER BY PRINCIPAL DESC, DES FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    IF @HD_N_NOR > 3
    BEGIN
        SELECT @HD_NOR_MAS = @HD_NOR_MAS + CASE WHEN @HD_NOR_MAS = '' THEN '' ELSE ', ' END + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'"',''),'<','')
        FROM (SELECT DES, ROW_NUMBER() OVER (ORDER BY PRINCIPAL DESC, DES) AS RN FROM #NO) X WHERE X.RN > 3 ORDER BY X.RN;
        SET @HD_NOR = @HD_NOR + '<span class="vct-pv-hd-nor is-more" title="' + @HD_NOR_MAS + '">+' + CONVERT(VARCHAR(10), @HD_N_NOR - 3) + '</span>';
    END;
    DECLARE @E_HC_NOM VARCHAR(400) = REPLACE(REPLACE(REPLACE(REPLACE(@HC_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
            @E_HC_CARGO VARCHAR(300) = REPLACE(REPLACE(REPLACE(REPLACE(@HC_CARGO,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
            @E_HC_TEL VARCHAR(200) = REPLACE(REPLACE(REPLACE(REPLACE(@HC_TEL,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
            @E_HC_MAIL VARCHAR(300) = REPLACE(REPLACE(REPLACE(REPLACE(@HC_MAIL,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;'),
            @E_HC_DOM VARCHAR(800) = REPLACE(REPLACE(REPLACE(REPLACE(@HC_DOM,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H = CONVERT(VARCHAR(MAX), '') + '<div class="vct-360-breadcrumb-row"><nav class="vct-breadcrumb-simple" aria-label="Breadcrumb">'
        + '<button type="button" class="vct-breadcrumb-link" data-vct-v360-back data-vct-sidebar-mod="3">Proyectos</button>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-item">' + @E_CLI + '</span>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-item">Vista 360</span>'
        + '<span class="vct-breadcrumb-sep">&rsaquo;</span><span class="vct-breadcrumb-current">(' + @E_COD + ') ' + LEFT(@E_NOM, 60) + '</span></nav></div>'
        /* encabezado en 3 filas fijas (PV_HEADER_V2): 1 nombre | 2 servicios, normas (max 3), estado, riesgo | 3 cliente y contacto */
        + '<div class="vct-360-client-strip vct-pv-hd"><div class="vct-360-card-left">'
        + '<div class="vct-360-avatar vct-pv-hd-ic"><span data-vct-icon="folder"></span></div>'
        + '<div class="vct-pv-hd-rows">'
        + '<div class="vct-pv-hd-r1"><h1 title="(' + @E_COD + ') ' + REPLACE(@E_NOM,'"','&quot;') + '">(' + @E_COD + ') ' + @E_NOM + '</h1></div>'
        + '<div class="vct-pv-hd-r2">'
        +   CASE WHEN @HD_SRV = '' THEN '' ELSE '<span class="vctdg-svc-set">' + @HD_SRV + '</span><span class="vct-pv-hd-sep"></span>' END
        +   CASE WHEN @HD_NOR = '' THEN '' ELSE @HD_NOR + '<span class="vct-pv-hd-sep"></span>' END
        +   '<span class="vct-360-badge vct-pv-hd-bd ' + CASE @EST_COD WHEN 'ENCURSO' THEN 'is-active' WHEN 'CONFIRMADO' THEN 'is-planned' WHEN 'CANCELADO' THEN 'is-cancel' ELSE 'is-neutral' END + '">' + @E_EST + '</span>'
        +   CASE WHEN ISNULL(@RIESGO,'') = '' THEN ''
                 ELSE '<span class="vct-360-badge vct-pv-hd-bd vct-pv-riesgo ' + CASE UPPER(LTRIM(RTRIM(@RIESGO))) WHEN 'ALTO' THEN 'is-alto' WHEN 'MEDIO' THEN 'is-medio' WHEN 'BAJO' THEN 'is-bajo' ELSE 'is-neutral' END + '">Riesgo ' + LOWER(@E_RIESGO) + '</span>' END
        + '</div>'
        + '<div class="vct-pv-hd-r3" data-vct-pv-fit>'
        +   '<span class="vct-pv-hd-cli" title="' + REPLACE(@E_CLI,'"','&quot;') + '"><span data-vct-icon="id-card"></span><span class="vct-pv-hd-t">' + @E_CLI + '</span></span>'
        +   CASE WHEN @HC_NOM = '' THEN ''
                 ELSE '<span class="vct-pv-hd-con" data-vct-pv-fit-item title="Contacto principal: ' + @E_HC_NOM + CASE WHEN @E_HC_CARGO <> '' THEN ' &middot; ' + @E_HC_CARGO ELSE '' END + '">'
                    + '<span data-vct-icon="contact"></span><span class="vct-pv-hd-t">' + @E_HC_NOM + '</span>'
                    + CASE WHEN @E_HC_CARGO <> '' THEN '<span class="vct-pv-hd-cg">&middot; ' + @E_HC_CARGO + '</span>' ELSE '' END + '</span>' END
        +   CASE WHEN @HC_TEL = '' THEN ''
                 ELSE '<a class="vct-pv-hd-tel" data-vct-pv-fit-item href="tel:' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@HC_TEL,' ',''),'(',''),')',''),'-',''),'"','') + '" title="Llamar: ' + @E_HC_TEL + '">'
                    + '<span data-vct-icon="phone"></span><span class="vct-pv-hd-t">' + @E_HC_TEL + '</span></a>' END
        +   CASE WHEN @HC_MAIL = '' THEN ''
                 ELSE '<a class="vct-pv-hd-mail" data-vct-pv-fit-item href="mailto:' + REPLACE(@E_HC_MAIL,'"','') + '" title="Enviar mail: ' + @E_HC_MAIL + '">'
                    + '<span data-vct-icon="mail"></span><span class="vct-pv-hd-t">' + @E_HC_MAIL + '</span></a>' END
        +   CASE WHEN @HC_DOM = '' THEN ''
                 ELSE '<a class="vct-pv-hd-dom" data-vct-pv-fit-item href="' + @HC_MAPS + '" target="_blank" rel="noopener noreferrer" title="Ver ubicaci&oacute;n en Google Maps: ' + @E_HC_DOM + '">'
                    + '<span class="vct-pv-hd-pin"><span data-vct-icon="map-pin"></span></span><span class="vct-pv-hd-t">' + @E_HC_DOM + '</span></a>' END
        + '</div>'
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
        + '<div class="vct-360-stat" data-vct-tone="violet"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Avance plan</span>'
        + CASE WHEN @PLN IS NULL THEN '<b>&ndash;</b><small>' + CASE WHEN @EST_COD = 'ENCURSO' THEN 'plan sin generar' ELSE 'se genera al iniciar' END + '</small>'
               ELSE '<b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b><small>' + CONVERT(VARCHAR(10), @PL_OK) + ' de ' + CONVERT(VARCHAR(10), @PL_TOT) + ' acciones cumplidas</small>' END
        + '</span><span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span></div>'
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
        + '<button type="button" data-vct-tab="plan"><span data-vct-icon="list-checks"></span><span>Parte log&iacute;stico</span>' + CASE WHEN @PL_NI > 0 THEN '<span class="vct-tab-count' + CASE WHEN @PL_V > 0 THEN ' is-alert' ELSE '' END + '">' + CONVERT(VARCHAR(10), @PL_NI) + '</span>' ELSE '' END + '</button>'
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

    /* ======== RESUMEN v2 (PV_RESUMEN_V2): etapas sobre la linea de tiempo + 3 cards del mismo alto ======== */
    DECLARE @F_LIM DATETIME;
    SELECT TOP 1 @F_LIM = VENCE FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' ORDER BY ID;

    /* etapas del flujo: estado D (cumplida) / A (actual) / V (actual atrasada) / P (proxima) */
    DECLARE @ET TABLE (ORD INT, NOM VARCHAR(100), EST CHAR(1), TXT VARCHAR(300));
    DECLARE @ET_ANA_OK BIT = 0, @ET_CONS_OK BIT = 0, @ET_LANZ_OK BIT = 0, @ET_PLAN_OK BIT = 0, @ET_FIN_OK BIT = 0,
            @ET_ANA_F DATETIME, @ET_CONS_F DATETIME, @ET_PLAN_F DATETIME, @ET_V_CONS BIT = 0, @ET_V_LANZ BIT = 0, @ET_V_PLAN BIT = 0,
            @ET_LANZ_LIM DATETIME, @ET_ACT VARCHAR(100) = '', @ET_ACT_V BIT = 0;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_ANALISTA' AND SIT = 'C') OR (NOT EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_ANALISTA') AND @ANALISTA_NOM <> '')
        SET @ET_ANA_OK = 1;
    SELECT TOP 1 @ET_ANA_F = ISNULL(CIERRE, CREA) FROM #A WHERE SUB_COD = 'ASIGNACION_ANALISTA' AND SIT = 'C' ORDER BY ID;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT = 'C') OR (NOT EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT <> 'C') AND @N_CONS > 0)
        SET @ET_CONS_OK = 1;
    SELECT TOP 1 @ET_CONS_F = CIERRE FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT = 'C' ORDER BY ID;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT = 'V') SET @ET_V_CONS = 1;
    IF @F_INI_REAL IS NOT NULL OR @EST_COD IN ('ENCURSO','TERMINADO') SET @ET_LANZ_OK = 1;
    SELECT @ET_LANZ_LIM = MIN(VENCE) FROM #A WHERE SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') AND SIT <> 'C';
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') AND SIT = 'V') SET @ET_V_LANZ = 1;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_PLAN' AND SIT = 'C') SET @ET_PLAN_OK = 1;
    SELECT TOP 1 @ET_PLAN_F = CIERRE FROM #A WHERE SUB_COD = 'CARGA_PLAN' AND SIT = 'C' ORDER BY ID DESC;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_PLAN' AND SIT = 'V') SET @ET_V_PLAN = 1;
    IF @EST_COD = 'TERMINADO' SET @ET_FIN_OK = 1;

    INSERT INTO @ET VALUES
     (1, 'Alta', 'D', ISNULL(CONVERT(VARCHAR(5), @F_ALTA, 103), '-') + ISNULL(' &middot; ' + REPLACE(REPLACE(@U_ALTA,'<',''),'>',''), '')),
     (2, 'Analista asignado', CASE WHEN @ET_ANA_OK = 1 THEN 'D' ELSE 'P' END,
         CASE WHEN @ANALISTA_NOM = '' THEN 'sin analista' ELSE ISNULL(CONVERT(VARCHAR(5), @ET_ANA_F, 103) + ' &middot; ', '') + REPLACE(REPLACE(REPLACE(LEFT(@ANALISTA_NOM, CHARINDEX(',', @ANALISTA_NOM + ',') - 1),'&','&amp;'),'<',''),'>','') END),
     (3, 'Consultores', CASE WHEN @ET_CONS_OK = 1 THEN 'D' WHEN @ET_V_CONS = 1 THEN 'V' ELSE 'P' END,
         CASE WHEN @ET_CONS_OK = 1 THEN ISNULL(CONVERT(VARCHAR(5), @ET_CONS_F, 103) + ' &middot; ', '') + CONVERT(VARCHAR(10), @N_CONS) + ' asignado(s)'
              WHEN @F_LIM IS NOT NULL THEN 'l&iacute;mite ' + CONVERT(VARCHAR(5), @F_LIM, 103) ELSE 'pendiente' END),
     (4, 'Lanzamiento', CASE WHEN @ET_LANZ_OK = 1 THEN 'D' WHEN @ET_V_LANZ = 1 THEN 'V' ELSE 'P' END,
         CASE WHEN @ET_LANZ_OK = 1 THEN 'inicio ' + ISNULL(CONVERT(VARCHAR(5), @F_INI_REAL, 103), '-')
              WHEN @ET_LANZ_LIM IS NOT NULL THEN 'l&iacute;mite ' + CONVERT(VARCHAR(5), @ET_LANZ_LIM, 103) ELSE 'pendiente' END),
     (5, 'Plan estrat&eacute;gico', CASE WHEN @ET_PLAN_OK = 1 THEN 'D' WHEN @ET_V_PLAN = 1 THEN 'V' ELSE 'P' END,
         CASE WHEN @PLN IS NULL THEN 'sin generar'
              ELSE CONVERT(VARCHAR(10), @PL_NI) + ' &iacute;tems &middot; ' + CONVERT(VARCHAR(10), @PL_PCT) + '%' + CASE WHEN @PL_V > 0 THEN ' &middot; ' + CONVERT(VARCHAR(10), @PL_V) + ' vencido(s)' ELSE '' END END),
     (6, 'Cierre', CASE WHEN @ET_FIN_OK = 1 THEN 'D' ELSE 'P' END, ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-'));
    /* la primera no cumplida es la actual (en rojo si su accion esta vencida) */
    UPDATE @ET SET EST = CASE WHEN EST = 'V' THEN 'V' ELSE 'A' END
    WHERE ORD = (SELECT MIN(ORD) FROM @ET WHERE EST <> 'D') AND @EST_COD <> 'CANCELADO';
    UPDATE @ET SET EST = 'P' WHERE EST = 'V' AND ORD > (SELECT MIN(ORD) FROM @ET WHERE EST <> 'D');
    SELECT TOP 1 @ET_ACT = NOM, @ET_ACT_V = CASE WHEN EST = 'V' THEN 1 ELSE 0 END FROM @ET WHERE EST IN ('A','V') ORDER BY ORD;
    DECLARE @ET_POS INT = ISNULL((SELECT MAX(ORD) FROM @ET WHERE EST = 'D'), 1);
    IF EXISTS (SELECT 1 FROM @ET WHERE EST IN ('A','V')) SET @ET_POS = (SELECT MIN(ORD) FROM @ET WHERE EST IN ('A','V'));
    /* linea: relleno y marca "Hoy" entre la ultima etapa cumplida y la actual (PV_RESUMEN_V3) */
    DECLARE @ET_HOY_X DECIMAL(6,2) = CASE WHEN NOT EXISTS (SELECT 1 FROM @ET WHERE EST IN ('A','V')) THEN 100
                                          WHEN @ET_POS <= 1 THEN 0 ELSE (@ET_POS - 1.5) * 20 END;
    DECLARE @R_ET VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-360-box vct-pv-et"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span class="vct-pv-ic-pulse"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h4l3 8 4-16 3 8h4"/></svg></span></span>Etapas del proyecto</h3>'
        + CASE WHEN @EST_COD = 'CANCELADO' THEN '<span class="vct-360-badge is-cancel">Proyecto cancelado</span>'
               WHEN @ET_ACT = '' THEN '<span class="vct-360-badge is-active">Proyecto terminado</span>'
               ELSE '<span class="vct-360-badge ' + CASE WHEN @ET_ACT_V = 1 THEN 'is-cancel' ELSE 'is-progress' END + '">Etapa actual: ' + @ET_ACT + '</span>' END
        + '</div><div class="vct-pv-et-tl">'
        + '<span class="vct-pv-et-ini">' + ISNULL(CONVERT(VARCHAR(5), @F_INI, 103), '') + '</span><span class="vct-pv-et-fin">' + ISNULL(CONVERT(VARCHAR(5), @F_FIN, 103), '') + '</span>'
        + '<span class="vct-pv-et-rail"></span><span class="vct-pv-et-done" style="width:' + CONVERT(VARCHAR(20), @ET_HOY_X) + '%"></span>'
        + CASE WHEN @EST_COD <> 'CANCELADO' THEN '<span class="vct-pv-et-hoy" style="left:' + CONVERT(VARCHAR(20), @ET_HOY_X) + '%"><em>Hoy ' + CONVERT(VARCHAR(5), @HOY, 103) + '</em></span>' ELSE '' END
        + ISNULL((SELECT '<div class="vct-pv-et-st is-' + LOWER(EST) + '" style="left:' + CONVERT(VARCHAR(10), (ORD - 1) * 20) + '%">'
                       + '<i class="vct-pv-et-dia"></i><b>' + NOM + '</b><small>' + TXT + '</small>'
                       + CASE EST WHEN 'A' THEN '<em>Actual</em>' WHEN 'V' THEN '<em>Atrasada</em>' ELSE '' END + '</div>'
                  FROM @ET ORDER BY ORD FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
        + '</div><div class="vct-pv-et-foot"><span><i class="is-d"></i>Cumplida</span><span><i class="is-a"></i>Actual</span><span><i class="is-v"></i>Atrasada</span><span><i class="is-p"></i>Pr&oacute;xima</span>'
        + '<span class="vct-pv-et-sp"></span><span class="vct-pv-et-plazo">' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-')
        + ' &middot; hoy ' + CONVERT(VARCHAR(5), @HOY, 103) + '<span class="vct-pv-et-bar"><i style="width:' + CONVERT(VARCHAR(5), @PCT_T) + '%"></i></span>' + CONVERT(VARCHAR(5), @PCT_T) + '% del plazo</span></div></div>';

    /* card 1: datos del proyecto + equipo (hasta 4; el resto en la pestania Equipo) */
    DECLARE @R_EQ VARCHAR(MAX) = '', @R_N_EQ INT = (SELECT COUNT(*) FROM #EQ);
    SELECT @R_EQ = ISNULL((
        SELECT TOP 4 '<div class="vct-pv-rs-person"><span class="vctdg-avatar ' + CASE WHEN TIPO = 'EMPLEADO' THEN 'is-a' ELSE 'is-c' END + '">' + INI + '</span>'
             + '<span><b>' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b><small>' + REPLACE(REPLACE(REPLACE(ISNULL(ROL_DES,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</small></span></div>'
        FROM #EQ ORDER BY ROL_ORD, ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    DECLARE @R_C1 VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-360-box vct-pv-rs-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="folder"></span></span>Datos del proyecto</h3>'
        +   CASE WHEN @PUEDE_EDIT = 1 THEN '<div class="vct-360-box-actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-edit="pe" data-id="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '"'
                 + ' data-f-nom="' + REPLACE(@E_NOM,'"','&quot;') + '" data-f-ref="' + REPLACE(@E_REF,'"','&quot;') + '" data-f-tipo="' + UPPER(ISNULL(@TIPO_P,'')) + '"'
                 + ' data-f-riesgo="' + REPLACE(ISNULL(@RIESGO,''),'"','') + '" data-f-ini="' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 120),'') + '" data-f-fin="' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 120),'') + '"'
                 + ' data-f-con="' + ISNULL(CONVERT(VARCHAR(20), @ID_CONTACTO),'') + '" data-f-ana="' + ISNULL((SELECT TOP 1 CONVERT(VARCHAR(20), ID_ENT) FROM #EQ WHERE ROL_COD = 'ANALISTA' ORDER BY ID),'') + '"'
                 + ' data-f-lim="' + ISNULL(CONVERT(VARCHAR(10), (SELECT TOP 1 VENCE FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT <> 'C' ORDER BY ID), 120),'') + '">'
                 + '<span data-vct-icon="edit"></span><span>Editar</span></button></div>' ELSE '' END
        + '</div>'
        + '<div class="vct-pv-rs-kv">'
        + '<div><small>Referencia</small><b title="' + REPLACE(@E_REF,'"','&quot;') + '">' + CASE WHEN @E_REF = '' THEN '-' ELSE @E_REF END + '</b></div>'
        + '<div><small>Tipo</small><b>' + @E_TIPO + '</b></div>'
        + '<div><small>Inicio</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103),'-') + '</b></div>'
        + '<div><small>Fin</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103),'-') + '</b></div>'
        + '<div><small>Inicio real</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_INI_REAL, 103),'-') + '</b></div>'
        + '<div><small>L&iacute;mite de lanzamiento</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_LIM, 103),'-') + '</b></div>'
        + '<div><small>Contacto</small><b title="' + REPLACE(@CONTACTO,'"','&quot;') + '">' + @CONTACTO + '</b></div>'
        + '<div><small>Alta</small><b>' + ISNULL(CONVERT(VARCHAR(10), @F_ALTA, 103),'-') + ISNULL(' <span class="vct-pv-rs-mut">&middot; ' + REPLACE(REPLACE(@U_ALTA,'<',''),'>','') + '</span>', '') + '</b></div>'
        + '</div>'
        + '<div class="vct-pv-rs-sec">Equipo (' + CONVERT(VARCHAR(10), @R_N_EQ) + ')</div>'
        + '<div class="vct-pv-rs-team">' + CASE WHEN @R_EQ = '' THEN '<span class="vct-pv-rs-mut">Sin integrantes.</span>' ELSE @R_EQ END + '</div>'
        + CASE WHEN @R_N_EQ > 4 THEN '<button type="button" class="vct-pv-rs-link" data-vct-pv-goto="equipo">+' + CONVERT(VARCHAR(10), @R_N_EQ - 4) + ' m&aacute;s &middot; Ver equipo completo</button>' ELSE '' END
        + '</div>';

    /* card 2: horas por servicio (mensaje de horas) + como vamos (mensaje de conclusion) */
    DECLARE @R_HS VARCHAR(MAX) = '';
    SELECT @R_HS = ISNULL((
        SELECT '<div class="vct-pv-rs-hs"><span class="vctdg-svc is-' + LOWER(LEFT(CASE WHEN COD = '' THEN 'xx' ELSE COD END, 2)) + ' is-on"><span data-vct-icon="' + CASE LEFT(COD, 2) WHEN 'AU' THEN 'clipboard-check' WHEN 'CA' THEN 'users' ELSE 'briefcase' END + '"></span></span>'
             + '<b>' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
             + '<span>' + CONVERT(VARCHAR(20), CONVERT(INT, EJEC)) + ' + ' + CONVERT(VARCHAR(20), CONVERT(INT, PROG)) + ' / ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h</span>'
             + '<span class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN EJEC * 100.0 / PROY > 100 THEN 100 ELSE EJEC * 100.0 / PROY END) ELSE 0 END) + '%"></span>'
             + '<span class="is-prog" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN PROG * 100.0 / PROY > 100 THEN 100 ELSE PROG * 100.0 / PROY END) ELSE 0 END) + '%"></span></span></div>'
        FROM #SV ORDER BY IDX FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    DECLARE @R_MSG_A VARCHAR(500), @R_MSG_A_CLS VARCHAR(20);
    IF @PLN IS NULL
        SELECT @R_MSG_A = 'El plan todav&iacute;a no est&aacute; generado: el avance se mide por tiempo y horas.', @R_MSG_A_CLS = 'is-info';
    ELSE IF @PL_PCT >= @PCT_T AND @PCT_H = 0
        SELECT @R_MSG_A = 'El plan va al d&iacute;a (' + CONVERT(VARCHAR(5), @PL_PCT) + '%), pero todav&iacute;a no hay horas ejecutadas.', @R_MSG_A_CLS = 'is-warn';
    ELSE IF @PL_PCT >= @PCT_T
        SELECT @R_MSG_A = 'Vamos al d&iacute;a: el plan (' + CONVERT(VARCHAR(5), @PL_PCT) + '%) acompa&ntilde;a el tiempo transcurrido (' + CONVERT(VARCHAR(5), @PCT_T) + '%).', @R_MSG_A_CLS = 'is-ok';
    ELSE
        SELECT @R_MSG_A = 'Vamos atrasados: el plan (' + CONVERT(VARCHAR(5), @PL_PCT) + '%) va detr&aacute;s del tiempo transcurrido (' + CONVERT(VARCHAR(5), @PCT_T) + '%).', @R_MSG_A_CLS = 'is-late';
    DECLARE @R_C2 VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-360-box vct-pv-rs-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="briefcase"></span></span>Horas por servicio</h3></div>'
        + '<div class="vct-pv-rs-hslist">' + CASE WHEN @R_HS = '' THEN '<span class="vct-pv-rs-mut">Sin servicios.</span>' ELSE @R_HS END + '</div>'
        + '<div class="vct-pv-legend"><span><i class="is-ejec"></i>Ejecutadas</span><span><i class="is-prog"></i>Programadas</span><span><i></i>Disponibles ' + CONVERT(VARCHAR(20), CONVERT(INT, @H_DISP)) + ' h</span></div>'
        + '<div class="vct-pv-rs-msg is-info"><span data-vct-icon="clock-3"></span><span>' + CONVERT(VARCHAR(5), @PCT_T) + '% del tiempo usado y ' + CONVERT(VARCHAR(5), @PCT_H) + '% de horas ejecutadas.</span></div>'
        + '<div class="vct-pv-rs-sec">&iquest;C&oacute;mo vamos?</div>'
        + '<div class="vct-pv-rs-gauge">'
        +   '<div><span>Tiempo transcurrido</span><b>' + CONVERT(VARCHAR(5), @PCT_T) + '%</b><span class="vct-pv-bar"><span class="is-time" style="width:' + CONVERT(VARCHAR(5), @PCT_T) + '%"></span></span></div>'
        +   '<div><span>Plan cumplido (acciones)</span><b>' + CASE WHEN @PLN IS NULL THEN '&ndash;' ELSE CONVERT(VARCHAR(5), @PL_PCT) + '%' END + '</b><span class="vct-pv-bar"><span class="is-plan" style="width:' + CASE WHEN @PLN IS NULL THEN '0' ELSE CONVERT(VARCHAR(5), @PL_PCT) END + '%"></span></span></div>'
        +   '<div><span>Horas ejecutadas</span><b>' + CONVERT(VARCHAR(5), @PCT_H) + '%</b><span class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(5), @PCT_H) + '%"></span></span></div>'
        + '</div>'
        + '<div class="vct-pv-rs-msg ' + @R_MSG_A_CLS + '"><span data-vct-icon="alert-triangle"></span><span>' + @R_MSG_A + '</span></div>'
        + '</div>';

    /* card 3: pendientes del proyecto (acciones abiertas, la mas proxima arriba) */
    DECLARE @R_PEND VARCHAR(MAX) = '', @R_N_PEND INT = (SELECT COUNT(*) FROM #A WHERE SIT <> 'C');
    SELECT @R_PEND = ISNULL((
        SELECT '<div class="vct-pv-rs-pend">'
             + CASE WHEN SIT = 'V' THEN '<span class="vct-360-badge is-cancel">Vencida</span>'
                    WHEN VENCE IS NULL THEN '<span class="vct-360-badge is-neutral">Sin fecha</span>'
                    WHEN CONVERT(DATE, VENCE) = CONVERT(DATE, @HOY) THEN '<span class="vct-360-badge is-planned">Hoy</span>'
                    ELSE '<span class="vct-360-badge is-planned">En ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @HOY, VENCE)) + ' d</span>' END
             + '<span><b>' + REPLACE(REPLACE(REPLACE(CASE WHEN SUB_DES <> '' THEN SUB_DES ELSE TITULO END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
             + '<small>' + REPLACE(REPLACE(REPLACE(CASE WHEN RESP <> '' THEN RESP ELSE '-' END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</small></span>'
             + '<span class="vct-pv-rs-pd' + CASE WHEN SIT = 'V' THEN ' is-late' ELSE '' END + '">' + ISNULL(CONVERT(VARCHAR(5), VENCE, 103), '-') + '</span></div>'
        FROM #A WHERE SIT <> 'C'
        ORDER BY CASE WHEN VENCE IS NULL THEN 1 ELSE 0 END, VENCE, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    DECLARE @R_C3 VARCHAR(MAX) = CONVERT(VARCHAR(MAX), '')
        + '<div class="vct-360-box vct-pv-rs-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="bell"></span></span>Pendientes del proyecto (' + CONVERT(VARCHAR(10), @R_N_PEND) + ')</h3>'
        + '<div class="vct-360-box-actions"><button type="button" class="vct-pv-rs-link" data-vct-pv-goto="acciones">Acciones &rsaquo;</button></div></div>'
        + '<div class="vct-pv-rs-pendlist">' + CASE WHEN @R_PEND = '' THEN '<div class="vct-360-empty">No hay acciones pendientes en el proyecto.</div>' ELSE @R_PEND END + '</div>'
        + '</div>';

    SET @H = @H + '<div class="vct-360-panel is-active" data-vct-panel="resumen">' + @R_ET
        + '<div class="vct-pv-rs-cards">' + @R_C1 + @R_C2 + @R_C3 + '</div></div>';

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
             + CASE WHEN @PUEDE_LANZ = 1 AND CIERRE IS NOT NULL THEN '<td></td>'
                    WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
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
             + '</tr>'
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
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="130"><span>Inicio real</span></th><th><span>Observaciones</span></th><th class="vct-text-center" data-vct-width="130"><span>Registr&oacute;</span></th></tr></thead><tbody>'
        +   @LZ_IN + '</tbody></table></div>'
        +   CASE WHEN @N_IN = 0 THEN '<div class="vct-360-empty">' + CASE WHEN @EST_COD <> 'CONFIRMADO' THEN 'El proyecto no est&aacute; Confirmado.' WHEN @IN_OK = 1 THEN 'Al iniciar, el proyecto pasa a En curso y el consultor l&iacute;der recibe la acci&oacute;n de cargar el plan.' ELSE @IN_FALTA + '.' END + '</div>' ELSE '' END
        + '</div></div>'
        + '</div>';


    /* ======================= PARTE LOGISTICO (PV_PLAN_V1) ======================= */
    DECLARE @PL_H VARCHAR(MAX) = '', @PL_ROWS VARCHAR(MAX) = '', @PL_ATN VARCHAR(MAX) = '', @PL_ROPT VARCHAR(MAX) = '',
            @PL_RANGO INT = CASE WHEN @F_INI IS NOT NULL AND @F_FIN IS NOT NULL AND @F_FIN > @F_INI THEN DATEDIFF(DAY, @F_INI, @F_FIN) ELSE 0 END,
            @PL_HOYP INT = 0, @PL_TRIG VARCHAR(300) = '<button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>',
            @PL_CARGA_ABIERTA BIT = 0, @PL_IOPT VARCHAR(MAX) = '', @PL_GANTT VARCHAR(MAX) = '';
    IF @PL_RANGO > 0 SET @PL_HOYP = CASE WHEN @HOY <= @F_INI THEN 0 WHEN @HOY >= @F_FIN THEN 100 ELSE DATEDIFF(DAY, @F_INI, @HOY) * 100 / @PL_RANGO END;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_PLAN' AND SIT <> 'C') SET @PL_CARGA_ABIERTA = 1;

    SELECT @PL_ROPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')
             + ' (' + REPLACE(REPLACE(ISNULL(ROL_DES,''),'<',''),'>','') + ')</option>'
        FROM #EQ ORDER BY ROL_ORD, NOMBRE
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    /* items superiores (desplegable no editable del sub-item) */
    SELECT @PL_IOPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(TIT,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM #PI WHERE PADRE IS NULL ORDER BY ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    IF @PLN IS NOT NULL
    BEGIN
        /* ===== PL_CARDS_V1: tarjetas por capitulo (editable) + cronograma (solo lectura) ===== */
        /* capitulo = numero antes del primer punto del titulo (4.1 -> 4); hitos aparte; sin numero -> Otros */
        UPDATE #PI SET CODE = CASE WHEN TIT LIKE '[0-9]%' THEN LEFT(TIT, PATINDEX('%[^0-9.]%', TIT + ' ') - 1) ELSE '' END WHERE PADRE IS NULL;
        UPDATE #PI SET CODE = LEFT(CODE, LEN(CODE) - 1) WHERE PADRE IS NULL AND RIGHT(CODE, 1) = '.';
        UPDATE #PI SET NAME = CASE WHEN CODE = '' THEN TIT ELSE LTRIM(SUBSTRING(TIT, LEN(CODE) + 1, 400)) END,
                       CAP = CASE WHEN HITO = 1 THEN 'H' WHEN CODE = '' THEN 'Z' ELSE LEFT(CODE, CHARINDEX('.', CODE + '.') - 1) END
        WHERE PADRE IS NULL;
        UPDATE #PI SET NAME = CASE WHEN LEFT(NAME, 1) IN ('.','-') THEN LTRIM(SUBSTRING(NAME, 2, 400)) ELSE NAME END WHERE PADRE IS NULL;
        UPDATE #PI SET CAP_ORD = CASE WHEN CAP = 'H' THEN 9998 WHEN CAP = 'Z' OR LEN(CAP) > 4 OR PATINDEX('%[^0-9]%', CAP) > 0 THEN 9999 ELSE CONVERT(INT, CAP) END WHERE PADRE IS NULL;
        UPDATE P SET VEN = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.SIT = 'V' AND (A.ITEM = P.ID OR A.ITEM IN (SELECT S.ID FROM #PI S WHERE S.PADRE = P.ID))), 0) FROM #PI P;

        /* fila de accion (checklist): la casilla marca / reabre */
        UPDATE A SET HTML =
              '<div class="vct-pl-acc' + CASE WHEN A.CUMPLIDA = 1 THEN ' is-done' WHEN A.SIT = 'V' THEN ' is-late' ELSE '' END + '">'
            + CASE WHEN @PUEDE_PLAN = 1 AND A.CUMPLIDA = 1
                   THEN '<button type="button" class="vct-pl-ck is-on" data-vct-pv-confirm="PV_PL_ACC_ESTADO" data-t11="PENDIENTE" data-id="' + CONVERT(VARCHAR(20), A.ID) + '" data-msg="&iquest;Reabrir la acci&oacute;n?" title="Reabrir"><span data-vct-icon="check"></span></button>'
                   WHEN @PUEDE_PLAN = 1 AND A.FINAL = 0
                   THEN '<button type="button" class="vct-pl-ck" data-vct-pv-confirm="PV_PL_ACC_ESTADO" data-t11="CUMPLIDA" data-id="' + CONVERT(VARCHAR(20), A.ID) + '" data-msg="&iquest;Marcar la acci&oacute;n como cumplida?" title="Marcar cumplida"></button>'
                   ELSE '<span class="vct-pl-ck' + CASE WHEN A.CUMPLIDA = 1 THEN ' is-on' ELSE '' END + '">' + CASE WHEN A.CUMPLIDA = 1 THEN '<span data-vct-icon="check"></span>' ELSE '' END + '</span>' END
            + '<span class="vct-pl-acc-t"><b>' + REPLACE(REPLACE(REPLACE(CASE WHEN A.DET <> '' THEN A.DET ELSE A.SUB END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
            + '<small>' + CASE WHEN A.DET <> '' THEN REPLACE(REPLACE(REPLACE(A.SUB,'&','&amp;'),'<','&lt;'),'>','&gt;') + CASE WHEN A.RESP_NOM <> '' THEN ' &middot; ' ELSE '' END ELSE '' END
            + REPLACE(REPLACE(REPLACE(A.RESP_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</small></span>'
            + '<span class="vct-pl-acc-d">' + CASE WHEN A.CUMPLIDA = 1 THEN 'cumplida' WHEN A.VENCE IS NULL THEN '-' ELSE CONVERT(VARCHAR(5), A.VENCE, 103) END + '</span>'
            + '</div>'
        FROM #PA A;

        /* bloque de sub-item (con sus acciones) */
        UPDATE S SET HTML =
              '<div class="vct-pl-sub">'
            + '<div class="vct-pl-sub-h"><span class="vct-pl-tag">Sub&iacute;tem</span><b>' + REPLACE(REPLACE(REPLACE(S.TIT,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
            + CASE WHEN S.TOT > 0 THEN '<span class="vct-pl-sub-c">' + CONVERT(VARCHAR(10), S.CUMP) + '/' + CONVERT(VARCHAR(10), S.TOT) + '</span>' ELSE '' END
            + CASE WHEN ISNULL(S.RESP_INI,'') <> '' THEN '<span class="vctdg-avatar is-c" title="' + REPLACE(REPLACE(S.RESP_NOM,'"',''),'<','') + '">' + S.RESP_INI + '</span>' ELSE '' END
            + CASE WHEN @PUEDE_PLAN = 1 THEN '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-new="pa" data-id="' + CONVERT(VARCHAR(20), S.ID) + '"><span data-vct-icon="plus"></span><span>Nueva acci&oacute;n</span></button>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-edit="pi" data-id="' + CONVERT(VARCHAR(20), S.ID) + '" data-f-padre="' + CONVERT(VARCHAR(20), S.PADRE) + '"'
                + ' data-f-tit="' + REPLACE(REPLACE(REPLACE(REPLACE(S.TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '" data-f-fr="' + ISNULL(CONVERT(VARCHAR(10), S.FR, 120),'') + '"'
                + ' data-f-resp="' + ISNULL(CONVERT(VARCHAR(20), S.RESP),'') + '" data-f-hito="0"'
                + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(S.OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar sub&iacute;tem</span></button>'
                + CASE WHEN S.TOT = 0 THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ITEM_BORRAR" data-id="' + CONVERT(VARCHAR(20), S.ID) + '" data-nombre="' + REPLACE(REPLACE(REPLACE(REPLACE(S.TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button>' ELSE '' END
                + '</div></span>' ELSE '' END
            + '</div>'
            + ISNULL((SELECT A.HTML AS [text()] FROM #PA A WHERE A.ITEM = S.ID ORDER BY A.CUMPLIDA, ISNULL(A.VENCE, '29991231'), A.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
            + '</div>'
        FROM #PI S WHERE S.PADRE IS NOT NULL;

        /* tarjeta del item */
        UPDATE T SET HTML =
              '<div class="vct-pl-icard is-' + LOWER(T.EST) + '" data-pl-card data-pl-est="' + T.EST + '" data-pl-search="'
            + LOWER(REPLACE(REPLACE(REPLACE(T.TIT + ' ' + ISNULL((SELECT ' ' + S.TIT FROM #PI S WHERE S.PADRE = T.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                                     + ISNULL((SELECT ' ' + A.DET + ' ' + A.SUB FROM #PA A WHERE A.TOP_ITEM = T.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),'"',''),'<',''),'>','')) + '">'
            /* cabecera */
            + '<div class="vct-pl-ic-h">'
            + CASE WHEN T.HITO = 1 THEN '<span class="vct-pl-code is-hito">Hito</span>' WHEN T.CODE <> '' THEN '<span class="vct-pl-code">' + T.CODE + '</span>' ELSE '' END
            + '<b class="vct-pl-ic-t">' + REPLACE(REPLACE(REPLACE(T.NAME,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
            + '<span class="vct-360-badge ' + CASE T.EST WHEN 'CUMPLIDO' THEN 'is-active' WHEN 'VENCIDO' THEN 'is-cancel' WHEN 'EN_CURSO' THEN 'is-progress' ELSE 'is-planned' END + '">'
            + CASE T.EST WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso' ELSE 'Pendiente' END + '</span>'
            + CASE WHEN @PUEDE_PLAN = 1 THEN '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-new="pa" data-id="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Nueva acci&oacute;n</span></button>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-edit="pi" data-id="' + CONVERT(VARCHAR(20), T.ID) + '" data-f-padre=""'
                + ' data-f-tit="' + REPLACE(REPLACE(REPLACE(REPLACE(T.TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                + ' data-f-fi="' + ISNULL(CONVERT(VARCHAR(10), T.FI, 120),'') + '" data-f-ff="' + ISNULL(CONVERT(VARCHAR(10), T.FF, 120),'') + '" data-f-fr="' + ISNULL(CONVERT(VARCHAR(10), T.FR, 120),'') + '"'
                + ' data-f-resp="' + ISNULL(CONVERT(VARCHAR(20), T.RESP),'') + '" data-f-hito="' + CASE WHEN T.HITO = 1 THEN '1' ELSE '0' END + '"'
                + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar &iacute;tem</span></button>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-new="pi" data-f-padre="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Agregar sub&iacute;tem</span></button>'
                + CASE WHEN T.TOT = 0 AND NOT EXISTS (SELECT 1 FROM #PI S WHERE S.PADRE = T.ID)
                       THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ITEM_BORRAR" data-id="' + CONVERT(VARCHAR(20), T.ID) + '" data-nombre="' + REPLACE(REPLACE(REPLACE(REPLACE(T.TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button>' ELSE '' END
                + '</div></span>' ELSE '' END
            + '</div>'
            /* fechas, plazo y responsable */
            + '<div class="vct-pl-ic-m">'
            + CASE WHEN T.FI IS NULL AND T.FF IS NULL THEN '<span class="vct-pl-warn"><span data-vct-icon="calendar"></span>Sin fechas</span>'
                   ELSE '<span><span data-vct-icon="calendar"></span>' + ISNULL(CONVERT(VARCHAR(5), T.FI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(5), T.FF, 103), '-') + '</span>' END
            + CASE WHEN T.FR IS NOT NULL THEN '<span>fin real ' + CONVERT(VARCHAR(5), T.FR, 103) + '</span>'
                   WHEN T.EST = 'VENCIDO' THEN '<span class="vct-pl-late">venci&oacute; hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, T.FF, @HOY)) + ' d</span>'
                   WHEN T.EST = 'EN_CURSO' AND T.FF IS NOT NULL THEN '<span>' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @HOY, T.FF)) + ' d restantes</span>'
                   WHEN T.FI IS NOT NULL AND CONVERT(DATE, T.FI) > @HOY THEN '<span>empieza en ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @HOY, T.FI)) + ' d</span>'
                   ELSE '' END
            + '<span class="vct-pl-ic-sp"></span>'
            + CASE WHEN ISNULL(T.RESP_INI,'') <> '' THEN '<span class="vctdg-avatar is-c" title="' + REPLACE(REPLACE(T.RESP_NOM,'"',''),'<','') + '">' + T.RESP_INI + '</span>' ELSE '' END
            + '</div>'
            /* avance: cumplidas / abiertas / vencidas */
            + CASE WHEN T.HITO = 1 AND T.TOT = 0 THEN ''
                   ELSE '<div class="vct-pl-seg"><span class="vct-pl-seg-bar">'
                      + CASE WHEN T.TOT > 0 THEN '<i class="is-ok" style="width:' + CONVERT(VARCHAR(10), T.CUMP * 100 / T.TOT) + '%"></i>'
                                               + '<i class="is-run" style="width:' + CONVERT(VARCHAR(10), (T.TOT - T.CUMP - T.VEN) * 100 / T.TOT) + '%"></i>'
                                               + '<i class="is-late" style="width:' + CONVERT(VARCHAR(10), T.VEN * 100 / T.TOT) + '%"></i>' ELSE '' END
                      + '</span><b>' + CONVERT(VARCHAR(10), T.AV) + '%</b></div>'
                      + '<div class="vct-pl-ic-c">' + CASE WHEN T.TOT = 0 THEN 'Sin acciones cargadas' ELSE CONVERT(VARCHAR(10), T.CUMP) + ' de ' + CONVERT(VARCHAR(10), T.TOT) + ' acciones cumplidas' + CASE WHEN T.VEN > 0 THEN ' &middot; <span class="vct-pl-late">' + CONVERT(VARCHAR(10), T.VEN) + ' vencida(s)</span>' ELSE '' END END + '</div>' END
            /* acciones del item y sub-items */
            + CASE WHEN EXISTS (SELECT 1 FROM #PA A WHERE A.ITEM = T.ID) OR EXISTS (SELECT 1 FROM #PI S WHERE S.PADRE = T.ID)
                   THEN '<div class="vct-pl-ic-l">'
                      + ISNULL((SELECT A.HTML AS [text()] FROM #PA A WHERE A.ITEM = T.ID ORDER BY A.CUMPLIDA, ISNULL(A.VENCE, '29991231'), A.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                      + ISNULL((SELECT S.HTML AS [text()] FROM #PI S WHERE S.PADRE = T.ID ORDER BY S.ORD, S.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                      + '</div>' ELSE '' END
            + CASE WHEN @PUEDE_PLAN = 1 THEN '<div class="vct-pl-ic-k">'
                      + '<button type="button" class="vct-pl-link" data-vct-pv-new="pa" data-id="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Nueva acci&oacute;n</span></button>'
                      + '<button type="button" class="vct-pl-link" data-vct-pv-new="pi" data-f-padre="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Sub&iacute;tem</span></button></div>' ELSE '' END
            + '</div>'
        FROM #PI T WHERE T.PADRE IS NULL;

        /* capitulos: cabecera con anillo de avance + grilla de tarjetas (se acomodan solas) */
        SELECT @PL_ROWS = ISNULL((
            SELECT C.H AS [text()] FROM (
                SELECT G.CAP_ORD,
                       '<div class="vct-pl-chap' + CASE WHEN G.ABRE = 1 THEN ' is-open' ELSE '' END + '" data-pl-chap="' + G.CAP + '">'
                     + '<div class="vct-pl-chap-h" data-pl-chap-toggle role="button" tabindex="0">'
                     + '<span class="vct-pl-ring" style="background:' + CASE WHEN G.TOT = 0 THEN '#eef2f6' ELSE 'conic-gradient(#66062D 0 ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), G.CUMP * 100.0 / G.TOT)) + '%, #CF6F92 0 '
                            + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), (G.TOT - G.VEN) * 100.0 / G.TOT)) + '%, #dc2626 0 100%)' END + '"><span>' + CASE WHEN G.TOT = 0 THEN '-' ELSE CONVERT(VARCHAR(10), G.CUMP * 100 / G.TOT) + '%' END + '</span></span>'
                     + '<span class="vct-pl-chap-t"><b>' + CASE WHEN G.CAP = 'H' THEN 'Hitos' WHEN G.CAP = 'Z' THEN 'Otros &iacute;tems' ELSE 'Cap&iacute;tulo ' + G.CAP END + '</b>'
                     + '<small>' + CONVERT(VARCHAR(10), G.NI) + ' &iacute;tem(s)' + CASE WHEN G.FI IS NOT NULL THEN ' &middot; ' + CONVERT(VARCHAR(5), G.FI, 103) + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(5), G.FF, 103), '-') ELSE '' END
                     + CASE WHEN G.SINF > 0 THEN ' &middot; ' + CONVERT(VARCHAR(10), G.SINF) + ' sin fechas' ELSE '' END
                     + ' &middot; ' + CONVERT(VARCHAR(10), G.CUMP) + ' de ' + CONVERT(VARCHAR(10), G.TOT) + ' acciones cumplidas</small></span>'
                     + '<span class="vct-pl-chap-b">'
                     + CASE WHEN G.N_C > 0 THEN '<span class="vct-360-badge is-active">' + CONVERT(VARCHAR(10), G.N_C) + ' cumplido(s)</span>' ELSE '' END
                     + CASE WHEN G.N_E > 0 THEN '<span class="vct-360-badge is-progress">' + CONVERT(VARCHAR(10), G.N_E) + ' en curso</span>' ELSE '' END
                     + CASE WHEN G.N_V > 0 THEN '<span class="vct-360-badge is-cancel">' + CONVERT(VARCHAR(10), G.N_V) + ' vencido(s)</span>' ELSE '' END
                     + CASE WHEN G.N_P > 0 THEN '<span class="vct-360-badge is-planned">' + CONVERT(VARCHAR(10), G.N_P) + ' pendiente(s)</span>' ELSE '' END
                     + '</span>'
                     + '<span class="vct-pl-chap-r">' + ISNULL((SELECT DISTINCT '<span class="vctdg-avatar is-c">' + X.RESP_INI + '</span>' AS [text()] FROM #PI X WHERE X.PADRE IS NULL AND X.CAP = G.CAP AND ISNULL(X.RESP_INI,'') <> '' FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '') + '</span>'
                     + '<span class="vct-pl-chap-tg"><span data-vct-icon="arrow-right"></span></span>'
                     + '</div>'
                     + '<div class="vct-pl-grid">'
                     + ISNULL((SELECT T.HTML AS [text()] FROM #PI T WHERE T.PADRE IS NULL AND T.CAP = G.CAP ORDER BY T.ORD, T.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                     + '</div></div>' AS H
                FROM (
                    SELECT CAP, MIN(CAP_ORD) AS CAP_ORD, COUNT(*) AS NI, MIN(FI) AS FI, MAX(FF) AS FF, SUM(TOT) AS TOT, SUM(CUMP) AS CUMP, SUM(VEN) AS VEN,
                           SUM(CASE WHEN FI IS NULL AND FF IS NULL THEN 1 ELSE 0 END) AS SINF,
                           SUM(CASE WHEN EST = 'CUMPLIDO' THEN 1 ELSE 0 END) AS N_C, SUM(CASE WHEN EST = 'EN_CURSO' THEN 1 ELSE 0 END) AS N_E,
                           SUM(CASE WHEN EST = 'VENCIDO' THEN 1 ELSE 0 END) AS N_V, SUM(CASE WHEN EST = 'PENDIENTE' THEN 1 ELSE 0 END) AS N_P,
                           CASE WHEN SUM(CASE WHEN EST IN ('EN_CURSO','VENCIDO') THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END AS ABRE
                    FROM #PI WHERE PADRE IS NULL GROUP BY CAP
                ) G
            ) C ORDER BY C.CAP_ORD
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        /* si ningun capitulo queda abierto, se abre el primero */
        IF @PL_ROWS <> '' AND CHARINDEX('vct-pl-chap is-open', @PL_ROWS) = 0
            SET @PL_ROWS = STUFF(@PL_ROWS, CHARINDEX('class="vct-pl-chap"', @PL_ROWS), LEN('class="vct-pl-chap"'), 'class="vct-pl-chap is-open"');

        /* ----- cronograma (solo lectura): semanas si el rango es corto, meses si es largo ----- */
        DECLARE @G_INI DATETIME, @G_FIN DATETIME, @G_END DATETIME, @G_DAYS INT, @G_N INT, @G_I INT = 0, @G_MES BIT = 0, @G_COLS VARCHAR(MAX) = '', @G_HOY VARCHAR(20) = '';
        SELECT @G_INI = ISNULL(@F_INI, MIN(FI)), @G_FIN = ISNULL(@F_FIN, MAX(FF)) FROM #PI WHERE PADRE IS NULL;
        IF @G_INI IS NOT NULL AND @G_FIN IS NOT NULL AND @G_FIN >= @G_INI
        BEGIN
            IF DATEDIFF(DAY, @G_INI, @G_FIN) > 120 SET @G_MES = 1;
            IF @G_MES = 1
            BEGIN
                SET @G_INI = DATEADD(MONTH, DATEDIFF(MONTH, 0, @G_INI), 0);
                SET @G_N = DATEDIFF(MONTH, @G_INI, @G_FIN) + 1;
                SET @G_END = DATEADD(MONTH, @G_N, @G_INI);
            END
            ELSE
            BEGIN
                SET @G_INI = DATEADD(DAY, -((DATEPART(WEEKDAY, @G_INI) + @@DATEFIRST - 2) % 7), CONVERT(DATE, @G_INI));
                SET @G_N = (DATEDIFF(DAY, @G_INI, @G_FIN) / 7) + 1;
                SET @G_END = DATEADD(DAY, 7 * @G_N, @G_INI);
            END;
            SET @G_DAYS = DATEDIFF(DAY, @G_INI, @G_END);
            WHILE @G_I < @G_N
            BEGIN
                SET @G_COLS = @G_COLS + '<span' + CASE WHEN @HOY >= CASE WHEN @G_MES = 1 THEN DATEADD(MONTH, @G_I, @G_INI) ELSE DATEADD(DAY, 7 * @G_I, @G_INI) END
                                                       AND @HOY < CASE WHEN @G_MES = 1 THEN DATEADD(MONTH, @G_I + 1, @G_INI) ELSE DATEADD(DAY, 7 * (@G_I + 1), @G_INI) END THEN ' class="is-now"' ELSE '' END + '>'
                            + CASE WHEN @G_MES = 1 THEN SUBSTRING('EneFebMarAbrMayJunJulAgoSepOctNovDic', (MONTH(DATEADD(MONTH, @G_I, @G_INI)) - 1) * 3 + 1, 3) + ' ' + RIGHT(CONVERT(VARCHAR(4), YEAR(DATEADD(MONTH, @G_I, @G_INI))), 2)
                                   ELSE CONVERT(VARCHAR(5), DATEADD(DAY, 7 * @G_I, @G_INI), 103) END + '</span>';
                SET @G_I = @G_I + 1;
            END;
            IF @HOY >= @G_INI AND @HOY < @G_END SET @G_HOY = CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), DATEDIFF(DAY, @G_INI, @HOY) * 100.0 / @G_DAYS));

            SELECT @PL_GANTT = ISNULL((
                SELECT R.H AS [text()] FROM (
                    /* fila de capitulo */
                    SELECT T.CAP_ORD AS O1, MIN(T.ORD) AS O2, 0 AS O3, 0 AS O4,
                           '<div class="vct-pl-g-row is-chap" data-pl-gchap="' + T.CAP + '"><div class="vct-pl-g-l"><b>' + CASE WHEN T.CAP = 'H' THEN 'Hitos' WHEN T.CAP = 'Z' THEN 'Otros &iacute;tems' ELSE 'Cap&iacute;tulo ' + T.CAP END + '</b></div><div class="vct-pl-g-lane"></div></div>' AS H
                    FROM #PI T WHERE T.PADRE IS NULL GROUP BY T.CAP, T.CAP_ORD
                    UNION ALL
                    /* item */
                    SELECT T.CAP_ORD, T.ORD, T.ID, 0,
                           '<div class="vct-pl-g-row" data-pl-grow="' + CONVERT(VARCHAR(20), T.ID) + '" data-pl-cap="' + T.CAP + '" data-pl-est="' + T.EST + '" data-pl-search="' + LOWER(REPLACE(REPLACE(REPLACE(T.TIT,'"',''),'<',''),'>','')) + '">'
                         + '<div class="vct-pl-g-l">' + CASE WHEN T.HITO = 1 THEN '<span class="vct-pl-code is-hito">Hito</span>' WHEN T.CODE <> '' THEN '<span class="vct-pl-code">' + T.CODE + '</span>' ELSE '' END
                         + '<span class="vct-pl-g-t" title="' + REPLACE(REPLACE(T.TIT,'"',''),'<','') + '">' + REPLACE(REPLACE(REPLACE(T.NAME,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
                         + CASE WHEN T.FI IS NULL AND T.FF IS NULL THEN '<span class="vct-pl-warn">Sin fechas</span>'
                                WHEN ISNULL(T.RESP_INI,'') <> '' THEN '<span class="vctdg-avatar is-c" title="' + REPLACE(REPLACE(T.RESP_NOM,'"',''),'<','') + '">' + T.RESP_INI + '</span>' ELSE '' END + '</div>'
                         + '<div class="vct-pl-g-lane">'
                         + CASE WHEN T.HITO = 1 AND ISNULL(T.FI, T.FF) IS NOT NULL
                                THEN '<i class="vct-pl-g-mil" title="' + CONVERT(VARCHAR(10), ISNULL(T.FI, T.FF), 103) + '" style="left:' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN ISNULL(T.FI, T.FF) <= @G_INI THEN 0 WHEN ISNULL(T.FI, T.FF) >= @G_END THEN 100 ELSE DATEDIFF(DAY, @G_INI, ISNULL(T.FI, T.FF)) * 100.0 / @G_DAYS END)) + '%"></i>'
                                WHEN T.FI IS NOT NULL AND T.FF IS NOT NULL
                                THEN '<span class="vct-pl-g-bar is-' + LOWER(T.EST) + '" title="' + CONVERT(VARCHAR(10), T.FI, 103) + ' &rarr; ' + CONVERT(VARCHAR(10), T.FF, 103) + ' &middot; ' + CONVERT(VARCHAR(10), T.AV) + '%" style="left:'
                                   + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN T.FI <= @G_INI THEN 0 WHEN T.FI >= @G_END THEN 99 ELSE DATEDIFF(DAY, @G_INI, T.FI) * 100.0 / @G_DAYS END))
                                   + '%;width:' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN (DATEDIFF(DAY, CASE WHEN T.FI < @G_INI THEN @G_INI ELSE T.FI END, CASE WHEN T.FF > @G_END THEN @G_END ELSE T.FF END) + 1) * 100.0 / @G_DAYS < 1 THEN 1
                                                                                                ELSE (DATEDIFF(DAY, CASE WHEN T.FI < @G_INI THEN @G_INI ELSE T.FI END, CASE WHEN T.FF > @G_END THEN @G_END ELSE T.FF END) + 1) * 100.0 / @G_DAYS END)) + '%">'
                                   + '<i style="width:' + CONVERT(VARCHAR(10), T.AV) + '%"></i><em>' + CONVERT(VARCHAR(10), T.AV) + '%</em></span>'
                                ELSE '' END
                         + ISNULL((SELECT '<i class="vct-pl-g-dot' + CASE WHEN A.CUMPLIDA = 1 THEN ' is-ok' WHEN A.SIT = 'V' THEN ' is-late' ELSE '' END + '" title="'
                                         + REPLACE(REPLACE(CASE WHEN A.DET <> '' THEN A.DET ELSE A.SUB END,'"',''),'<','') + ' &middot; ' + CONVERT(VARCHAR(10), A.VENCE, 103) + '" style="left:'
                                         + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN A.VENCE <= @G_INI THEN 0 WHEN A.VENCE >= @G_END THEN 100 ELSE DATEDIFF(DAY, @G_INI, A.VENCE) * 100.0 / @G_DAYS END)) + '%"></i>' AS [text()]
                                   FROM #PA A WHERE A.TOP_ITEM = T.ID AND A.VENCE IS NOT NULL FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                         + '</div></div>'
                    FROM #PI T WHERE T.PADRE IS NULL
                    UNION ALL
                    /* sub-items: heredan el rango del item */
                    SELECT T.CAP_ORD, T.ORD, T.ID, S.ORD + 1,
                           '<div class="vct-pl-g-row is-sub" data-pl-gparent="' + CONVERT(VARCHAR(20), T.ID) + '"><div class="vct-pl-g-l"><span class="vct-pl-g-t">' + REPLACE(REPLACE(REPLACE(S.TIT,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
                         + '<span class="vct-360-badge ' + CASE S.EST WHEN 'CUMPLIDO' THEN 'is-active' WHEN 'VENCIDO' THEN 'is-cancel' WHEN 'EN_CURSO' THEN 'is-progress' ELSE 'is-planned' END + '">'
                         + CASE S.EST WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso' ELSE 'Pendiente' END + '</span></div>'
                         + '<div class="vct-pl-g-lane">'
                         + CASE WHEN T.FI IS NOT NULL AND T.FF IS NOT NULL
                                THEN '<span class="vct-pl-g-bar is-sub is-' + LOWER(T.EST) + '" style="left:'
                                   + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN T.FI <= @G_INI THEN 0 WHEN T.FI >= @G_END THEN 99 ELSE DATEDIFF(DAY, @G_INI, T.FI) * 100.0 / @G_DAYS END))
                                   + '%;width:' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), CASE WHEN (DATEDIFF(DAY, CASE WHEN T.FI < @G_INI THEN @G_INI ELSE T.FI END, CASE WHEN T.FF > @G_END THEN @G_END ELSE T.FF END) + 1) * 100.0 / @G_DAYS < 1 THEN 1
                                                                                                ELSE (DATEDIFF(DAY, CASE WHEN T.FI < @G_INI THEN @G_INI ELSE T.FI END, CASE WHEN T.FF > @G_END THEN @G_END ELSE T.FF END) + 1) * 100.0 / @G_DAYS END)) + '%"></span>'
                                ELSE '' END
                         + '</div></div>'
                    FROM #PI S INNER JOIN #PI T ON T.ID = S.PADRE
                ) R ORDER BY R.O1, R.O2, R.O3, R.O4
                FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
            SET @PL_GANTT = '<div class="vct-pl-g" style="--pl-cols:' + CONVERT(VARCHAR(10), @G_N) + '">'
                + '<div class="vct-pl-g-row is-head"><div class="vct-pl-g-l">&Iacute;tem</div><div class="vct-pl-g-lane"><div class="vct-pl-g-cols">' + @G_COLS + '</div>'
                + CASE WHEN @G_HOY <> '' THEN '<i class="vct-pl-g-today is-head" style="left:' + @G_HOY + '%"><em>Hoy</em></i>' ELSE '' END + '</div></div>'
                + '<div class="vct-pl-g-body"' + CASE WHEN @G_HOY <> '' THEN ' style="--pl-hoy:' + @G_HOY + '%"' ELSE '' END + '>' + @PL_GANTT + '</div>'
                + '<div class="vct-pl-g-legend"><span><i class="is-en_curso"></i>En curso</span><span><i class="is-pendiente"></i>Pendiente</span><span><i class="is-vencido"></i>Vencido</span><span><i class="is-cumplido"></i>Cumplido</span>'
                + '<span><i class="is-mil"></i>Hito</span><span><i class="is-dot"></i>Vencimiento de acci&oacute;n</span><span><i class="is-today"></i>Hoy</span></div></div>';
        END
        ELSE SET @PL_GANTT = '<div class="vct-360-empty">Para ver el cronograma, el proyecto o los &iacute;tems tienen que tener fechas.</div>';

        /* requiere atencion */
        SELECT @PL_ATN = ISNULL((
            SELECT TOP 6 '<li><span class="vct-360-badge ' + X.C + '">' + X.B + '</span><span>' + X.T + '</span></li>'
            FROM (
                SELECT 1 AS O, 'is-cancel' AS C, 'Vencido' AS B,
                       REPLACE(REPLACE(REPLACE(LEFT(TIT, 70),'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, FF, @HOY)) + ' d' AS T, FF AS F
                FROM #PI WHERE PADRE IS NULL AND EST = 'VENCIDO'
                UNION ALL
                SELECT 2, 'is-planned', 'Fecha', REPLACE(REPLACE(REPLACE(LEFT(TITULO, 90),'&','&amp;'),'<','&lt;'),'>','&gt;'), CREA
                FROM #A WHERE SUB_COD = 'AVISO_VENCIMIENTO' AND SIT <> 'C' AND TITULO LIKE 'Cambio de fecha en el plan%'
                UNION ALL
                SELECT 3, 'is-cancel', 'Acci&oacute;n', REPLACE(REPLACE(REPLACE(LEFT(TIT, 70),'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; venci&oacute; ' + CONVERT(VARCHAR(5), VENCE, 103), VENCE
                FROM #PA WHERE SIT = 'V'
            ) X ORDER BY X.O, X.F
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    END;

    SET @PL_H = '<div class="vct-360-panel" data-vct-panel="plan">';
    IF @PLN IS NULL
        SET @PL_H = @PL_H + '<div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Parte log&iacute;stico</h3></div>'
            + CASE WHEN @PLN_TIENE_CO = 0 THEN '<div class="vct-360-empty">El parte log&iacute;stico solo existe si el proyecto tiene consultor&iacute;a. Sin plan: las acciones se cargan con fecha en la pesta&ntilde;a Acciones.</div>'
                   WHEN @EST_COD <> 'ENCURSO' THEN '<div class="vct-360-empty">El plan se arma cuando el proyecto est&aacute; En curso (despu&eacute;s del lanzamiento).</div>'
                   WHEN @PUEDE_PLAN = 0 THEN '<div class="vct-360-empty">El consultor todav&iacute;a no arm&oacute; el plan del proyecto.</div>'
                   ELSE '<div class="vct-pl-start">'
                      + '<p>Eleg&iacute; c&oacute;mo arrancar el plan. Despu&eacute;s defin&iacute;s fechas de inicio y fin y el responsable de cada &iacute;tem, y cargas las acciones.</p>'
                      + '<div class="vct-pl-start-opts">'
                      + '<button type="button" class="vct-pl-opt" data-vct-pv-confirm="PV_PL_GENERAR" data-t11="BASE" data-id="0" data-msg="&iquest;Generar el plan con los &iacute;tems del plan base RE-PP-007?">'
                      +   '<b>A &middot; Desde el plan base</b><span>RE-PP-007 &middot; ' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) ON D.ID = I.ID_DOCUMENTO AND D.CODIGO = 'RE-PP-007' AND D.ACTIVO = 1 AND ISNULL(D.TIPO_DETALLE,'') = 'PLAN' WHERE I.ACTIVO = 1)) + ' &iacute;tems de los requisitos de las normas</span></button>'
                      + '<button type="button" class="vct-pl-opt" data-vct-pv-confirm="PV_PL_GENERAR" data-t11="BLANCO" data-id="0" data-msg="&iquest;Crear el plan en blanco?">'
                      +   '<b>C &middot; Plan en blanco</b><span>Sin &iacute;tems: cargas los tuyos</span></button>'
                      + '</div></div>' END
            + '</div>';
    ELSE
        SET @PL_H = @PL_H
            /* encabezado: avance, tiempo vs avance, requiere atencion */
            + '<div class="vct-pl-cards">'
            + '<div class="vct-360-box vct-pl-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Avance del plan</h3></div>'
            +   '<div class="vct-pl-donut-wrap"><div class="vct-pl-donut" style="background:' + CASE WHEN @PL_NI = 0 THEN '#e2e8f0' ELSE 'conic-gradient(#16a34a 0 ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), @PL_C * 100.0 / @PL_NI)) + '%, #2563eb 0 ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), (@PL_C + @PL_E) * 100.0 / @PL_NI)) + '%, #94a3b8 0 ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(6,2), (@PL_C + @PL_E + @PL_P) * 100.0 / @PL_NI)) + '%, #dc2626 0 100%)' END + '">'
            +   '<div><b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b><small>' + CONVERT(VARCHAR(10), @PL_OK) + ' de ' + CONVERT(VARCHAR(10), @PL_TOT) + ' acciones</small></div></div>'
            +   '<ul class="vct-pl-legend"><li><i style="background:#16a34a"></i>Cumplidos <b>' + CONVERT(VARCHAR(10), @PL_C) + '</b></li><li><i style="background:#2563eb"></i>En curso <b>' + CONVERT(VARCHAR(10), @PL_E) + '</b></li>'
            +   '<li><i style="background:#94a3b8"></i>Pendientes <b>' + CONVERT(VARCHAR(10), @PL_P) + '</b></li><li><i style="background:#dc2626"></i>Vencidos <b>' + CONVERT(VARCHAR(10), @PL_V) + '</b></li></ul></div></div>'
            + '<div class="vct-360-box vct-pl-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>Tiempo y avance</h3></div>'
            +   '<div class="vct-pl-tv"><div><span>Tiempo transcurrido del proyecto</span><div class="vct-pl-tv-bar"><span class="is-time" style="width:' + CONVERT(VARCHAR(10), @PL_HOYP) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PL_HOYP) + '%</b></div>'
            +   '<div><span>Avance real del plan (acciones cumplidas)</span><div class="vct-pl-tv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(10), @PL_PCT) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b></div>'
            +   '<div><span>Avance de horas (ejecutadas / proyectadas)</span><div class="vct-pl-tv-bar"><span class="is-hours" style="width:' + CONVERT(VARCHAR(10), @PCT_H) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PCT_H) + '%</b></div>'
            +   '<p class="vct-pl-tv-note">' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-') + '</p></div></div>'
            + '<div class="vct-360-box vct-pl-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="bell"></span></span>Requiere atenci&oacute;n</h3></div>'
            +   CASE WHEN @PL_ATN = '' THEN '<div class="vct-360-empty">Nada vencido ni cambios de fecha pendientes.</div>' ELSE '<ul class="vct-pl-atn">' + @PL_ATN + '</ul>' END + '</div>'
            + '</div>'
            /* tarjetas por capitulo (editable) / cronograma (solo lectura) PL_CARDS_V1 */
            + '<div class="vct-360-box vct-pl-box" data-pl-box><div class="vct-360-box-head vct-pl-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Parte log&iacute;stico</h3>'
            +   '<div class="vct-pl-view" role="group" aria-label="Vista"><button type="button" class="is-on" data-pl-view="cards"><span data-vct-icon="list-checks"></span><span>Tarjetas</span></button>'
            +   '<button type="button" data-pl-view="gantt"><span data-vct-icon="calendar"></span><span>Cronograma</span></button></div></div>'
            +   '<div class="vctdg vct-pl-tools"><div class="vctdg-toolbar"><div class="vctdg-filters"><div class="vctdg-search"><span data-vct-icon="search"></span><input type="search" placeholder="Buscar &iacute;tem, sub&iacute;tem o acci&oacute;n..." data-pl-buscar autocomplete="off"></div>'
            +   '<select class="vct-select vct-select-sm" data-vct-dg-filter="estado" data-pl-estado><option value="">Todos los estados</option><option value="PENDIENTE">Pendiente</option><option value="EN_CURSO">En curso</option><option value="VENCIDO">Vencido</option><option value="CUMPLIDO">Cumplido</option></select></div>'
            +   '<div class="vctdg-tools vct-pl-edit-tools">'
            +   '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-pl-chap-all><span data-vct-icon="list-checks"></span><span>Expandir todo</span></button>'
            +   CASE WHEN @PUEDE_PLAN = 1 AND @PL_CARGA_ABIERTA = 1 THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-confirm="PV_PL_CERRAR" data-id="0" data-msg="&iquest;Finalizar la carga del plan? La acci&oacute;n de carga del plan queda cumplida (todos los &iacute;tems tienen que tener fecha de inicio y fin)."><span data-vct-icon="check"></span><span>Finalizar carga</span></button>' ELSE '' END
            +   CASE WHEN @PUEDE_PLAN = 1 THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="pi" data-f-padre=""><span data-vct-icon="plus"></span><span>&Iacute;tem</span></button>' ELSE '' END
            +   '</div></div></div>'
            +   '<div class="vct-pl-cardsview" data-pl-pane="cards">' + CASE WHEN @PL_ROWS = '' THEN '<div class="vct-360-empty">El plan no tiene &iacute;tems. Us&aacute; &laquo;&Iacute;tem&raquo; para agregarlos.</div>' ELSE @PL_ROWS END
            +   '<div class="vct-360-empty" data-pl-nores hidden>No hay &iacute;tems que coincidan con el filtro.</div></div>'
            +   '<div class="vct-pl-ganttview" data-pl-pane="gantt" hidden>' + @PL_GANTT + '</div>'
            + '</div>';
    SET @PL_H = @PL_H + '</div>';

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
                 WHEN SUB_COD IN ('CARGA_PLAN','TRABAJO_PLAN_ITEM') THEN 'data-vct-pv-goto="plan"'
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

        /* ---- calendario de ACCIONES del proyecto para la pestania Agenda (solo lectura) ---- */
    /* CAL13_PROYECTO: acciones, visitas y horas; sin funciones auxiliares. */
    DECLARE @CAL13_EVT TABLE (F DATE, X VARCHAR(1000), K VARCHAR(20), C VARCHAR(5));
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,VENCE), LEFT(ISNULL(TITULO,''),1000), '',
      CASE WHEN CONVERT(DATE,VENCE)<CONVERT(DATE,@HOY) THEN 'V'
           WHEN CONVERT(DATE,VENCE)=CONVERT(DATE,@HOY) THEN 'H'
           WHEN CONVERT(DATE,VENCE)<=DATEADD(DAY,7,CONVERT(DATE,@HOY)) THEN 'P' ELSE 'L' END
    FROM #A WHERE VENCE IS NOT NULL AND SIT<>'C';
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,V.FECHA_DESDE), LEFT('Visita: '+ISNULL(NULLIF(V.LUGAR,''),'Proyecto')
      +CASE WHEN V.FECHA_HASTA IS NOT NULL AND CONVERT(DATE,V.FECHA_HASTA)<>CONVERT(DATE,V.FECHA_DESDE)
        THEN ' (hasta '+CONVERT(VARCHAR(10),V.FECHA_HASTA,103)+')' ELSE '' END,1000),
      CASE WHEN CONVERT(DATE,V.FECHA_DESDE)>=CONVERT(DATE,@HOY) THEN 'AGENDADA' ELSE 'PENDIENTE' END,''
    FROM dbo.VCT_PROYECTOS_VISITAS V
    WHERE V.ID_PROYECTO=@ID_PROYECTO AND V.FECHA_DESDE IS NOT NULL
      AND ISNULL(V.ESTADO,'') NOT IN ('CANCELADO','CANCELADA','ANULADO','ANULADA')
      AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R WHERE R.ID_VISITA=V.ID);
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,R.FECHA), LEFT('Horas registradas: '+CONVERT(VARCHAR(30),R.HORAS)+' h'
      +CASE WHEN NULLIF(V.LUGAR,'') IS NOT NULL THEN ' - '+V.LUGAR ELSE '' END,1000),'REGISTRADA',''
    FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID=R.ID_VISITA
    WHERE V.ID_PROYECTO=@ID_PROYECTO AND R.FECHA IS NOT NULL
      AND ISNULL(V.ESTADO,'') NOT IN ('CANCELADO','CANCELADA','ANULADO','ANULADA');
    DECLARE @AG_EV VARCHAR(MAX) = '[' + ISNULL(STUFF((
      SELECT ',{"f":"'+CONVERT(VARCHAR(10),F,120)+'","x":"'
        +CONVERT(VARCHAR(MAX),STRING_ESCAPE(CONVERT(NVARCHAR(MAX),X),'json'))
        +'","k":"'+K+'","c":"'+C+'"}'
      FROM @CAL13_EVT ORDER BY F,X
      FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,1,''),'')+']';
    SET @AG_EV = REPLACE(REPLACE(@AG_EV, '&', '&amp;'), '"', '&quot;');
    DECLARE @AG_MONTHS VARCHAR(600) =
        '<option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option>'
      + '<option value="4">Abril</option><option value="5">Mayo</option><option value="6">Junio</option>'
      + '<option value="7">Julio</option><option value="8">Agosto</option><option value="9">Septiembre</option>'
      + '<option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option>';
    /* PV_FERIADOS_V17: misma fuente que el calendario general. */
    DECLARE @PV17_HOLIDAYS NVARCHAR(MAX);
    SELECT @PV17_HOLIDAYS=ISNULL((
      SELECT CONVERT(VARCHAR(10),Fecha,120) AS f, Feriado AS t,
        ISNULL(NULLIF(HolidayText,''),'Feriado') AS x
      FROM dbo.Calendar WHERE IsHoliday=1 ORDER BY Fecha FOR JSON PATH
    ),N'[]');
    SET @PV17_HOLIDAYS=REPLACE(REPLACE(@PV17_HOLIDAYS,'&','&amp;'),'"','&quot;');
    DECLARE @AG_PANEL VARCHAR(MAX) =
        '<div class="vct-agenda vct-acc-cal-embed" data-vct-agenda-root data-vct-feriados="' + CONVERT(VARCHAR(MAX),@PV17_HOLIDAYS) + '" data-vct-calendar-events="' + @AG_EV + '">'
      + '<div class="vct-agenda-toolbar">'
      +   '<div class="vct-agenda-nav"><button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>'
      +   '<h2 class="vct-agenda-title" data-vct-agenda-title></h2>'
      +   '<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button></div>'
      +   '<div class="vct-agenda-view-toggle"><button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>'
      +     '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button>'
      +     '<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">D' + CHAR(237) + 'a</button></div>'
      +   '<div class="vct-agenda-jump"><select class="vct-select vct-agenda-select-month" data-vct-agenda-select-month data-vct-native="true" data-vct-custom-init="true">' + @AG_MONTHS + '</select>'
      +     '<select class="vct-select vct-agenda-select-year" data-vct-agenda-select-year data-vct-native="true" data-vct-custom-init="true"></select></div>'
      + '</div>'
      + '<div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div>'
      + '</div>'; /* CAL13_CALENDARIO_SIEMPRE */

/* ======================= PESTANIAS DE PASOS SIGUIENTES ======================= */
    SET @H = @H
        + @PL_H
        + '<div class="vct-360-panel" data-vct-panel="agenda"><div class="vct-360-box">' + @AG_PANEL + '</div></div>'
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

    /* ======================= MODALES DEL PARTE LOGISTICO ======================= */
    /* modal "Editar datos del proyecto" (PV_PROY_EDIT_V1): datos del paso 1 sin servicios, normas, horas ni rentabilidad */
    DECLARE @PE_MODAL VARCHAR(MAX) = '', @PE_OCON VARCHAR(MAX) = '', @PE_OANA VARCHAR(MAX) = '', @PE_HAY_LIM BIT = 0;
    IF @PUEDE_EDIT = 1
    BEGIN
        IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'ASIGNACION_CONSULTOR' AND SIT <> 'C') SET @PE_HAY_LIM = 1;
        SELECT @PE_OCON = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), C.ID) + '">'
                 + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ' ' + ISNULL(C.APELLIDO,''))) + CASE WHEN ISNULL(C.CARGO,'') <> '' THEN ' - ' + C.CARGO ELSE '' END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_CONTACTOS C WITH(NOLOCK)
            WHERE C.IDCLIENTE = @CLI AND LTRIM(RTRIM(ISNULL(C.NOMBRES,'') + ISNULL(C.APELLIDO,''))) <> ''
            ORDER BY C.APELLIDO, C.NOMBRES, C.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PE_OANA = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), E.ID) + '">' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK) WHERE ISNULL(E.ESTADO,'ACTIVO') = 'ACTIVO'
            ORDER BY E.APELLIDOS, E.NOMBRES FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SET @PE_MODAL = CONVERT(VARCHAR(MAX), '')
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-md" data-vct-component="modal" data-vct-pv-modal="pe" data-vct-pv-cmd="PV_PROY_GUARDAR" data-vct-pv-tnew="Editar datos del proyecto" data-vct-pv-tedit="Editar datos del proyecto">'
            + '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
            + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="folder"></span></div>'
            + '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-pv-mtitle>Editar datos del proyecto</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
            + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
            + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Cliente</label><input type="text" class="vct-input" value="' + REPLACE(@E_CLI,'"','&quot;') + '" readonly></div>'
            + '<div class="vct-field vct-col-8"><label class="vct-label">Nombre del proyecto <span class="vct-req">*</span></label>'
            +   '<input type="text" class="vct-input" maxlength="300" data-vct-pv-f="nom" data-vct-pv-buf="TEXTO11" data-req="Nombre del proyecto"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Referencia</label>'
            +   '<input type="text" class="vct-input" maxlength="300" placeholder="Ej.: propuesta 2026-118" data-vct-pv-f="ref" data-vct-pv-buf="TEXTO12"></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Tipo de proyecto <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="tipo" data-vct-pv-buf="TEXTO13" data-req="Tipo de proyecto"><option value="">Seleccione</option><option value="IMPLEMENTACION">Implementaci&oacute;n</option><option value="MANTENIMIENTO">Mantenimiento</option></select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Nivel de riesgo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="riesgo" data-vct-pv-buf="TEXTO14" data-req="Nivel de riesgo"><option value="">Seleccione</option><option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Fecha inicio proyecto <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="ini" data-vct-pv-buf="TEXTO15" data-req="Fecha inicio proyecto"></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Fecha fin proyecto <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fin" data-vct-pv-buf="TEXTO16" data-req="Fecha fin proyecto"></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Contacto del cliente</label>'
            +   '<select data-vct-pv-f="con" data-vct-pv-buf="TEXTO17" data-vct-pv-def=""><option value="">' + CASE WHEN @PE_OCON = '' THEN 'El cliente no tiene contactos cargados' ELSE 'Sin contacto' END + '</option>' + @PE_OCON + '</select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Analista a cargo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="ana" data-vct-pv-buf="TEXTO18" data-req="Analista a cargo"><option value="">Seleccione</option>' + @PE_OANA + '</select></div>'
            + CASE WHEN @PE_HAY_LIM = 1
                   THEN '<div class="vct-field vct-col-6"><label class="vct-label">Fecha l&iacute;mite de lanzamiento <span class="vct-req">*</span></label>'
                      + '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="lim" data-vct-pv-buf="TEXTO19" data-req="Fecha l&iacute;mite de lanzamiento"></div>'
                   ELSE '<div class="vct-field vct-col-6"><label class="vct-label">Fecha l&iacute;mite de lanzamiento</label>'
                      + '<input type="text" class="vct-input" value="' + ISNULL(CONVERT(VARCHAR(10), @F_LIM, 103), '-') + ' (consultores ya asignados)" readonly></div>' END
            + '<div class="vct-field vct-col-12"><div class="vct-help">Los servicios, las normas y las horas se editan en sus pesta&ntilde;as. Si cambi&aacute;s el analista, sus acciones abiertas en este proyecto pasan al nuevo.</div></div>'
            + '</div></div>'
            + '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
            + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>';
    END;

    DECLARE @PL_MODALS VARCHAR(MAX) = '', @PMH VARCHAR(MAX), @PMF VARCHAR(MAX);
    /* tipificacion de la accion del plan (parametria de acciones, solo activos) PL_ACC_TIPIF_V1 */
    DECLARE @PA_OTIPO VARCHAR(MAX) = '', @PA_OSUB VARCHAR(MAX) = '', @PA_OPRIO VARCHAR(MAX) = '', @PA_OEST VARCHAR(MAX) = '', @PA_ORES VARCHAR(MAX) = '',
            @PA_DTIPO VARCHAR(20) = '', @PA_DSUB VARCHAR(20) = '', @PA_DPRIO VARCHAR(20) = '', @PA_DEST VARCHAR(20) = '';
    IF @PUEDE_PLAN = 1 AND @PLN IS NOT NULL
    BEGIN
        SELECT @PA_OTIPO = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_TIPOS WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OSUB = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '" data-tipo="' + CONVERT(VARCHAR(20), ID_TIPO) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OPRIO = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY NIVEL, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OEST = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '" data-final="' + CASE WHEN ES_FINAL = 1 THEN '1' ELSE '0' END + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_ORES = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        /* valores sugeridos: trabajo sobre item del plan, prioridad normal, estado pendiente (se pueden cambiar) */
        SELECT @PA_DSUB = CONVERT(VARCHAR(20), ID), @PA_DTIPO = CONVERT(VARCHAR(20), ID_TIPO) FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'TRABAJO_PLAN_ITEM' AND ACTIVO = 1;
        SELECT @PA_DPRIO = CONVERT(VARCHAR(20), ID) FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE CODIGO = 'NORMAL' AND ACTIVO = 1;
        SELECT @PA_DEST = CONVERT(VARCHAR(20), ID) FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE' AND ACTIVO = 1;
    END;
    IF @PUEDE_PLAN = 1 AND @PLN IS NOT NULL
    BEGIN
        SET @PMF = '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
                 + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>';
        SET @PMH = '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
                 + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="{ICON}"></span></div>'
                 + '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-pv-mtitle>{TIT}</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
                 + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
                 + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">';
        SET @PL_MODALS = CONVERT(VARCHAR(MAX), '')
            /* item / sub-item */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-sm" data-vct-component="modal" data-vct-pv-modal="pi" data-vct-pv-cmd="PV_PL_ITEM_GUARDAR" data-vct-pv-tnew="Agregar &iacute;tem" data-vct-pv-tedit="Editar &iacute;tem">'
            + REPLACE(REPLACE(@PMH, '{ICON}', 'list-checks'), '{TIT}', '&Iacute;tem del plan')
            + '<div class="vct-field vct-col-12 vct-pv-fixed" data-vct-pv-only-sub><label class="vct-label">&Iacute;tem</label>'
            +   '<select data-vct-pv-f="padre" data-vct-pv-buf="TEXTO16" data-vct-pv-def="" disabled><option value="">-</option>' + @PL_IOPT + '</select></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label"><span data-vct-pv-only-top>&Iacute;tem</span><span data-vct-pv-only-sub>Sub&iacute;tem</span> <span class="vct-req">*</span></label>'
            +   '<input type="text" class="vct-input" maxlength="400" placeholder="Ej.: 4.1 Comprensi&oacute;n de la organizaci&oacute;n y su contexto" data-vct-pv-f="tit" data-vct-pv-buf="TEXTO11" data-req="&Iacute;tem"></div>'
            + '<div class="vct-field vct-col-4" data-vct-pv-only-top><label class="vct-label">Fecha inicio</label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fi" data-vct-pv-buf="TEXTO12" min="' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 120), '') + '" max="' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 120), '') + '"></div>'
            + '<div class="vct-field vct-col-4" data-vct-pv-only-top><label class="vct-label">Fecha fin</label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="ff" data-vct-pv-buf="TEXTO13" min="' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 120), '') + '" max="' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 120), '') + '"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fin real</label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fr" data-vct-pv-buf="TEXTO14"></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-sub><div class="vct-help">El sub&iacute;tem hereda las fechas del &iacute;tem superior.</div></div>'
            + '<div class="vct-field vct-col-8"><label class="vct-label">Responsable</label>'
            +   '<select data-vct-pv-f="resp" data-vct-pv-buf="TEXTO15" data-vct-pv-def=""><option value="">-</option>' + @PL_ROPT + '</select></div>'
            + '<div class="vct-field vct-col-4" data-vct-pv-only-top><label class="vct-label">&nbsp;</label><label class="vct-pv-switch"><input type="checkbox" data-vct-pv-f="hito" data-vct-pv-buf="TEXTO17"><span>Hito (auditor&iacute;a, certificaci&oacute;n)</span></label></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Observaciones</label>'
            +   '<textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO18"></textarea></div>'
            + '<div class="vct-field vct-col-12" data-vct-pv-only-top><div class="vct-help">Las fechas tienen que estar dentro del proyecto (' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-') + '). Si cambi&aacute;s las fechas de un &iacute;tem ya fechado, se avisa al analista.</div></div>'
            + '</div></div>' + @PMF
            /* accion del item */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-md" data-vct-component="modal" data-vct-pv-modal="pa" data-vct-pv-cmd="PV_PL_ACC_GUARDAR" data-vct-pv-tnew="Nueva acci&oacute;n del plan" data-vct-pv-tedit="Acci&oacute;n del plan">'
            + REPLACE(REPLACE(@PMH, '{ICON}', 'clipboard-check'), '{TIT}', 'Nueva acci&oacute;n del plan')
            + '<div class="vct-field vct-col-6"><label class="vct-label">Tipo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="tipo" data-vct-pv-buf="TEXTO21" data-req="Tipo" data-vct-pv-def="' + @PA_DTIPO + '" data-vct-pv-tipo><option value="">-</option>' + @PA_OTIPO + '</select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Subtipo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="sub" data-vct-pv-buf="TEXTO16" data-req="Subtipo" data-vct-pv-def="' + @PA_DSUB + '" data-vct-pv-sub-tipo><option value="">-</option>' + @PA_OSUB + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Prioridad <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="prio" data-vct-pv-buf="TEXTO17" data-req="Prioridad" data-vct-pv-def="' + @PA_DPRIO + '"><option value="">-</option>' + @PA_OPRIO + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Estado <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="est" data-vct-pv-buf="TEXTO19" data-req="Estado" data-vct-pv-def="' + @PA_DEST + '" data-vct-pv-estado><option value="">-</option>' + @PA_OEST + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Resultado <span class="vct-req" data-vct-pv-res-req hidden>*</span></label>'
            +   '<select data-vct-pv-f="res" data-vct-pv-buf="TEXTO20" data-vct-pv-def="" data-vct-pv-resultado><option value="">-</option>' + @PA_ORES + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fecha inicio</label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="ini" data-vct-pv-buf="TEXTO13"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Vence <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="vence" data-vct-pv-buf="TEXTO12" data-req="Vence"></div>'
            + '<div class="vct-field vct-col-4"></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Responsable <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="resp" data-vct-pv-buf="TEXTO15" data-req="Responsable"><option value="">-</option>' + @PL_ROPT + '</select></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Detalle</label>'
            +   '<textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO18"></textarea></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-help">El t&iacute;tulo de la acci&oacute;n se arma con el subtipo y el &iacute;tem. Las fechas tienen que estar dentro del rango del &iacute;tem. El resultado se pide solo si el estado es final.</div></div>'
            + '</div></div>' + @PMF;
    END;

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @ASSETS
        + '<div class="vct-page vct-page-main" data-vct-page data-vct-sidebar-id="3" data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID,''),'"','') + '">'
        + '<section class="vct-module vct-360-module vct-cliente360-module vct-360-visual-final vct-pv" data-vct-module data-vct-pv data-vct-entity-theme="cliente"'
        + ' data-vct-tabs data-vct-tabs-active="resumen" data-vct-tabs-reset="0" data-vct-pv-proyecto="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '"'
        + ' data-vct-pv-guid="' + REPLACE(@GUID_V360,'"','') + '"' + CASE WHEN @MSG <> '' OR @ERR <> '' THEN ' data-vct-pv-volver="' + @VOLVER + '"' ELSE '' END + '>'
        + @H + @MODAL
        + @LZ_MODALS + @PL_MODALS + @PE_MODAL /* SP_IDSELEC02_V1 */
        + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '">'
        + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value=""><input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">'
        + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value=""><input type="hidden" name="SP.TEXTO12" data-vct-field="TEXTO12" value="">'
        + '<input type="hidden" name="SP.TEXTO13" data-vct-field="TEXTO13" value=""><input type="hidden" name="SP.TEXTO14" data-vct-field="TEXTO14" value=""><input type="hidden" name="SP.TEXTO15" data-vct-field="TEXTO15" value=""><input type="hidden" name="SP.TEXTO16" data-vct-field="TEXTO16" value=""><input type="hidden" name="SP.TEXTO17" data-vct-field="TEXTO17" value=""><input type="hidden" name="SP.TEXTO18" data-vct-field="TEXTO18" value=""><input type="hidden" name="SP.TEXTO19" data-vct-field="TEXTO19" value=""><input type="hidden" name="SP.TEXTO20" data-vct-field="TEXTO20" value=""><input type="hidden" name="SP.TEXTO21" data-vct-field="TEXTO21" value=""><input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">'
        + '</section></div>';
END
GO
