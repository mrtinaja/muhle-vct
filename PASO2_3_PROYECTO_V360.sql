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
   v24/v20: Servicios en una grilla unica agrupada por tipo (sin normas:
     van por proyecto), un solo boton "Agregar servicio", menu Editar /
     Ver plan; la pestania del plan arranca deshabilitada y toma el nombre
     del plan elegido (PV_SV_GRILLA_V1 / PV_PLAN_TAB_V1).
   v25/v21: paginado de 10 en auditorias / capacitaciones (> 10); pestania
     "Plan de auditoria" / "Plan de capacitacion" y el titulo con nombre y lugar.
   Datos de entrada: solo la minuta de consultoria RE-PP-022-CO, sin el
     servicio en la descripcion (PV_DE_MINUTA_CO_V1).
   Lanzamiento: paso Riesgos (TIPO RIESGO, nivel del proyecto) y Reuniones
     (N reuniones; la tildada es la de lanzamiento) (PV_LZ_RIESGOS_V1 / PV_LZ_REUNIONES_V1).
   Lanzamiento: la tabla de datos pasa a dbo.VCT_PROYECTOS_DATOS (PASO3_7).
   v27/v22 PL_ARBOL_V1: plan estrategico por norma en arbol capitulo > item > subitem, detalle 50/50
     del nodo elegido, acciones con editar / eliminar y responsable equipo / cliente / otro;
     avance del plan sobre el total de items. Requiere PASO4_1 (columnas nuevas).
   Assets: css/vct-proyecto-v360.css?v=34  js/vct-proyecto-v360.js?v=25
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
                + '<link rel="stylesheet" href="../css/vct-proyecto-v360.css?v=34"><script src="../js/vct-proyecto-v360.js?v=25"></script>';

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
    DECLARE @PE_VOLVER BIT = 0, @PE_TAB VARCHAR(20) = '';
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

    /* comando PV_SV_GUARDAR (PV_SV_EDIT_V1 / PV_SV_GRUPOS_V1): agrega o edita un servicio del proyecto.
       Se agregan Auditorias y Capacitaciones (N instancias, cada una con su nombre, lugar, fechas y horas); la Consultoria
       solo se carga en el alta y aca solo se edita.
       IDSELEC03 = VCT_PROYECTOS_SERVICIOS.ID (0 = nuevo), TEXTO11 servicio (VCT_PRM_SERVICIOS.ID, solo al agregar),
       TEXTO12 nombre, TEXTO13 lugar, TEXTO14 inicio, TEXTO15 fin (aaaa-mm-dd), TEXTO16 horas proyectadas.
       Permiso: EDIT de PROYECTOS. Las horas proyectadas del proyecto pasan a ser la suma de las de sus servicios. */
    IF @B_FLAG = '1' AND @B_CMD = 'PV_SV_GUARDAR'
    BEGIN
        DECLARE @SVE_T14 VARCHAR(4000) = '', @SVE_T15 VARCHAR(4000) = '', @SVE_T16 VARCHAR(4000) = '';
        SELECT TOP 1 @SVE_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @SVE_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @SVE_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL,
               TEXTO15 = NULL, TEXTO16 = NULL
        WHERE PAR_KEY = @IPKEYJOB;
        SET @PE_TAB = 'servicios';

        DECLARE @SVE_ID INT, @SVE_SRV INT, @SVE_SRV_COD VARCHAR(50), @SVE_INI DATETIME, @SVE_FIN DATETIME, @SVE_HRS INT,
                @SVE_P_INI DATETIME, @SVE_P_FIN DATETIME, @SVE_P_EST INT, @SVE_USADAS NUMERIC(18,2) = 0, @SVE_DES VARCHAR(300) = '',
                @SVE_LN INT = ISNULL(COL_LENGTH('dbo.VCT_PROYECTOS_SERVICIOS', 'NOMBRE'), 100), @SVE_LL INT = ISNULL(COL_LENGTH('dbo.VCT_PROYECTOS_SERVICIOS', 'LUGAR'), 100);
        IF @SVE_LN < 1 SET @SVE_LN = 4000;
        IF @SVE_LL < 1 SET @SVE_LL = 4000;
        IF @B_SEL3 <> '' AND PATINDEX('%[^0-9]%', @B_SEL3) = 0 AND LEN(@B_SEL3) <= 9 SET @SVE_ID = NULLIF(CONVERT(INT, @B_SEL3), 0);
        SELECT @SVE_P_INI = FECHA_INICIO, @SVE_P_FIN = FECHA_FIN, @SVE_P_EST = ID_ESTADO FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;
        IF @SVE_ID IS NOT NULL
            SELECT @SVE_SRV = S.ID_SERVICIO, @SVE_SRV_COD = UPPER(ISNULL(PS.CODIGO,'')), @SVE_DES = ISNULL(PS.DESCRIPCION,'')
            FROM dbo.VCT_PROYECTOS_SERVICIOS S WITH(NOLOCK) LEFT JOIN dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK) ON PS.ID = S.ID_SERVICIO
            WHERE S.ID = @SVE_ID AND S.ID_PROYECTO = @ID_PROYECTO;
        ELSE IF @B_T11 <> '' AND PATINDEX('%[^0-9]%', @B_T11) = 0 AND LEN(@B_T11) <= 9
            SELECT @SVE_SRV = PS.ID, @SVE_SRV_COD = UPPER(ISNULL(PS.CODIGO,'')), @SVE_DES = ISNULL(PS.DESCRIPCION,'')
            FROM dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK) WHERE PS.ID = CONVERT(INT, @B_T11) AND ISNULL(PS.ESTADO,'ACTIVO') = 'ACTIVO';
        IF @SVE_T14 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@SVE_T14,'-','')) = 1 SET @SVE_INI = CONVERT(DATETIME, REPLACE(@SVE_T14,'-',''), 112);
        IF @SVE_T15 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@SVE_T15,'-','')) = 1 SET @SVE_FIN = CONVERT(DATETIME, REPLACE(@SVE_T15,'-',''), 112);
        IF @SVE_T16 <> '' AND PATINDEX('%[^0-9]%', @SVE_T16) = 0 AND LEN(@SVE_T16) <= 6 SET @SVE_HRS = CONVERT(INT, @SVE_T16);
        /* horas ya usadas en la agenda (no se puede proyectar menos) */
        IF @SVE_ID IS NOT NULL
            SELECT @SVE_USADAS = ISNULL(SUM(ISNULL(VC.HORAS_EJECUTADAS, ISNULL(VC.HORAS_PLANIFICADAS,0))), 0)
            FROM dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK)
            JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) ON VC.ID_VISITA = V.ID
            WHERE V.ID_PROYECTO_SERVICIO = @SVE_ID;

        IF @ID_PROYECTO IS NULL OR @SVE_P_EST IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'EDIT')
            SET @ERR = 'No tiene permiso para editar los servicios del proyecto.';
        ELSE IF @SVE_ID IS NOT NULL AND @SVE_SRV IS NULL SET @ERR = 'El servicio no pertenece a este proyecto.';
        ELSE IF @SVE_SRV IS NULL SET @ERR = 'Servicio es obligatorio.';
        ELSE IF @SVE_ID IS NULL AND LEFT(@SVE_SRV_COD, 2) = 'CO' SET @ERR = 'La consultor' + CHAR(237) + 'a solo se carga en el alta del proyecto.';
        ELSE IF @SVE_ID IS NULL AND LEFT(@SVE_SRV_COD, 2) NOT IN ('AU','CA') SET @ERR = 'Solo se puede agregar Auditor' + CHAR(237) + 'a o Capacitaci' + CHAR(243) + 'n.';
        ELSE IF LEN(@B_T12) > @SVE_LN SET @ERR = 'Nombre no puede superar ' + CONVERT(VARCHAR(10), @SVE_LN) + ' caracteres.';
        ELSE IF LEN(@B_T13) > @SVE_LL SET @ERR = 'Lugar no puede superar ' + CONVERT(VARCHAR(10), @SVE_LL) + ' caracteres.';
        ELSE IF @SVE_INI IS NULL SET @ERR = 'Fecha inicio es obligatoria.';
        ELSE IF @SVE_FIN IS NULL SET @ERR = 'Fecha fin es obligatoria.';
        ELSE IF @SVE_FIN < @SVE_INI SET @ERR = 'La fecha fin es anterior a la fecha inicio.';
        ELSE IF (@SVE_P_INI IS NOT NULL AND @SVE_INI < @SVE_P_INI) OR (@SVE_P_FIN IS NOT NULL AND @SVE_FIN > @SVE_P_FIN)
            SET @ERR = 'Las fechas tienen que estar dentro del plazo del proyecto (' + ISNULL(CONVERT(VARCHAR(10), @SVE_P_INI, 103), '-') + ' - ' + ISNULL(CONVERT(VARCHAR(10), @SVE_P_FIN, 103), '-') + ').';
        ELSE IF ISNULL(@SVE_HRS, 0) <= 0 SET @ERR = 'Horas proyectadas es obligatorio y debe ser mayor a cero.';
        ELSE IF @SVE_HRS < @SVE_USADAS SET @ERR = 'Las horas no pueden ser menos que las ya cargadas en la agenda (' + CONVERT(VARCHAR(20), CONVERT(INT, @SVE_USADAS)) + ' h).';

        IF @ERR = ''
        BEGIN
            BEGIN TRY
                BEGIN TRAN;
                IF @SVE_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_SERVICIOS
                        (ID_PROYECTO, ID_SERVICIO, ID_ESTADO, PRINCIPAL, ORDEN, FECHA_INICIO, FECHA_FIN, PORCENTAJE_AVANCE,
                         FECHA_ALTA, USUARIO_ALTA, SECUENCIA, TOTAL_HORAS_PROYECTADAS, TOTAL_HORAS_EJECUTADAS, NOMBRE, LUGAR)
                    SELECT @ID_PROYECTO, @SVE_SRV, @SVE_P_EST,
                           CASE WHEN NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_SERVICIOS X WHERE X.ID_PROYECTO = @ID_PROYECTO AND X.PRINCIPAL = 1) THEN 1 ELSE 0 END,
                           ISNULL((SELECT MAX(X.ORDEN) FROM dbo.VCT_PROYECTOS_SERVICIOS X WHERE X.ID_PROYECTO = @ID_PROYECTO), 0) + 1,
                           @SVE_INI, @SVE_FIN, 0, GETDATE(), @IAGENTE, 1, @SVE_HRS, 0, NULLIF(@B_T12, ''), NULLIF(@B_T13, '');
                ELSE
                    UPDATE dbo.VCT_PROYECTOS_SERVICIOS
                       SET NOMBRE = NULLIF(@B_T12, ''), LUGAR = NULLIF(@B_T13, ''), FECHA_INICIO = @SVE_INI, FECHA_FIN = @SVE_FIN,
                           TOTAL_HORAS_PROYECTADAS = @SVE_HRS
                     WHERE ID = @SVE_ID AND ID_PROYECTO = @ID_PROYECTO;
                UPDATE dbo.VCT_PROYECTOS
                   SET TOTAL_HORAS_PROYECTADAS = (SELECT ISNULL(SUM(ISNULL(X.TOTAL_HORAS_PROYECTADAS, 0)), 0) FROM dbo.VCT_PROYECTOS_SERVICIOS X WHERE X.ID_PROYECTO = @ID_PROYECTO),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_PROYECTO;
                COMMIT;
                SET @MSG = CASE WHEN @SVE_ID IS NULL THEN @SVE_DES + ' agregada al proyecto.' ELSE @SVE_DES + ' actualizada.' END + ' Horas proyectadas del proyecto actualizadas.';
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
       Sin tablas nuevas: todo en VCT_PROYECTOS_DATOS, una fila por registro.
         TIPO 'MG'     dato de entrada: NRO_INTERNO = 'ITEM:<id VCT_PRM_DOCUMENTOS_ITEMS>' o 'LIBRE',
                       TEMAS = pregunta, OBSERVACIONES = respuesta, ID_DOCUMENTO = minuta RE-PP-022 del servicio.
         TIPO 'CONS'   consideracion: NRO_INTERNO = INTERNA / CONSULTOR / CLIENTE, OBSERVACIONES = texto.
         TIPO 'LANZ'   reunion de lanzamiento: FECHA_DOCUMENTO = fecha, PARTICIPANTES, TEMAS, ID_CONSULTOR,
                       OBSERVACIONES = conclusiones, FECHA_CIERRE = realizada.
         TIPO 'INICIO' inicio del proyecto: FECHA_DOCUMENTO = fecha de inicio real, OBSERVACIONES.
         TIPO 'RIESGO' riesgo (PV_LZ_RIESGOS_V1): NRO_INTERNO = nivel (Bajo / Medio / Alto), OBSERVACIONES = texto.
                       Si el nivel elegido difiere del proyecto, se actualiza VCT_PROYECTOS.NIVEL_RIESGO.
       Buffer: TEXTO30 = comando, IDSELEC03 = ID de la fila (editar / borrar), TEXTO11..16 = campos.
       Permiso: analista del proyecto (equipo, rol ANALISTA) o EDIT de PROYECTOS. */
    DECLARE @VOLVER VARCHAR(50) = CASE WHEN @PE_TAB <> '' THEN @PE_TAB WHEN @PE_VOLVER = 1 THEN 'resumen' ELSE 'equipo' END, @PUEDE_LANZ BIT = @PUEDE_EDIT;
    IF @PUEDE_LANZ = 0 AND EXISTS (
        SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ID_EMPLEADO = @EMP_U)
        SET @PUEDE_LANZ = 1;
    DECLARE @PUEDE_RI BIT = @PUEDE_LANZ;   /* riesgos: ademas, cualquier consultor activo del equipo (PV_LZ_RIESGOS_V1) */
    IF @PUEDE_RI = 0 AND @CONS_U IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = @CONS_U)
        SET @PUEDE_RI = 1;

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
    /* PV_DE_MINUTA_CO_V1: por default solo la minuta de gestion de consultoria (RE-PP-022-CO);
       si el proyecto no tiene consultoria, quedan las minutas de sus servicios */
    IF EXISTS (SELECT 1 FROM #MIN M INNER JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) ON D.ID = M.ID_DOCUMENTO AND D.CODIGO = 'RE-PP-022-CO')
        DELETE M FROM #MIN M
        WHERE NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) WHERE D.ID = M.ID_DOCUMENTO AND D.CODIGO = 'RE-PP-022-CO');

    IF @B_FLAG = '1' AND @B_CMD IN ('PV_DE_GUARDAR','PV_DE_BORRAR','PV_DE_CERRAR','PV_CO_GUARDAR','PV_CO_BORRAR','PV_RI_GUARDAR','PV_RI_BORRAR',
                                    'PV_RE_GUARDAR','PV_RE_BORRAR','PV_IN_GUARDAR','PV_IN_BORRAR')
    BEGIN
        DECLARE @L_T14 VARCHAR(4000) = '', @L_T15 VARCHAR(4000) = '', @L_T16 VARCHAR(4000) = '';
        SELECT TOP 1 @L_T14 = LTRIM(RTRIM(ISNULL(TEXTO14,''))), @L_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @L_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL,
               TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL
        WHERE PAR_KEY = @IPKEYJOB;

        DECLARE @LZ_TIPO VARCHAR(20) = CASE LEFT(@B_CMD, 5) WHEN 'PV_DE' THEN 'MG' WHEN 'PV_CO' THEN 'CONS' WHEN 'PV_RI' THEN 'RIESGO' WHEN 'PV_RE' THEN 'LANZ' ELSE 'INICIO' END;
        SET @VOLVER = 'lanzamiento:' + CASE @LZ_TIPO WHEN 'MG' THEN 'datos' WHEN 'CONS' THEN 'cons' WHEN 'RIESGO' THEN 'riesgos' WHEN 'LANZ' THEN 'reunion' ELSE 'inicio' END;
        DECLARE @RI_NIVEL VARCHAR(50) = CASE UPPER(@B_T11) WHEN 'BAJO' THEN 'Bajo' WHEN 'MEDIO' THEN 'Medio' WHEN 'ALTO' THEN 'Alto' ELSE '' END,
                @RI_ANT VARCHAR(50) = '', @RI_CAMBIA BIT = 0;

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
        IF @ERR = '' AND @PUEDE_LANZ = 0 AND NOT (@LZ_TIPO = 'RIESGO' AND @PUEDE_RI = 1) SET @ERR = 'No tiene permiso para editar el lanzamiento de este proyecto.';
        IF @ERR = '' AND @LZ_ID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK) WHERE ID = @LZ_ID AND ID_PROYECTO = @ID_PROYECTO AND TIPO = @LZ_TIPO)
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
                    ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK)
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
            SELECT @LZ_N = COUNT(*) FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK)
            WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'MG' AND (NRO_INTERNO LIKE 'ITEM:%' OR NRO_INTERNO = 'LIBRE');
            IF @LZ_ACC IS NULL SET @ERR = 'No hay una acci' + CHAR(243) + 'n "Carga de datos de entrada" abierta en el proyecto.';
            ELSE IF @LZ_N = 0 SET @ERR = 'Cargue al menos un dato de entrada antes de finalizar la carga.';
        END;
        IF @ERR = '' AND @B_CMD = 'PV_CO_GUARDAR'
        BEGIN
            IF UPPER(@B_T11) NOT IN ('INTERNA','CONSULTOR','CLIENTE') SET @ERR = 'Tipo es obligatorio.';
            ELSE IF @B_T12 = '' SET @ERR = 'Consideraci' + CHAR(243) + 'n es obligatoria.';
        END;
        IF @ERR = '' AND @B_CMD = 'PV_RI_GUARDAR'
        BEGIN
            IF @RI_NIVEL = '' SET @ERR = 'Nivel de riesgo es obligatorio.';
            ELSE IF @B_T12 = '' SET @ERR = 'Riesgo es obligatorio.';
            ELSE
            BEGIN
                SELECT @RI_ANT = ISNULL(NIVEL_RIESGO, '') FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;
                IF @RI_ANT <> @RI_NIVEL SET @RI_CAMBIA = 1;
            END;
        END;
        IF @ERR = '' AND @B_CMD = 'PV_RE_GUARDAR'
        BEGIN
            IF @L_T16 <> '' AND PATINDEX('%[^0-9]%', @L_T16) = 0 AND LEN(@L_T16) <= 9 SET @LZ_CONS = CONVERT(INT, @L_T16);
            IF @LZ_CONS IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK)
                                                    WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR' AND ID_CONSULTOR = @LZ_CONS AND ESTADO = 'ACTIVO')
                SET @ERR = 'El consultor elegido no es del equipo del proyecto.';
            ELSE IF @L_T15 = '1' AND @LZ_FECHA > @HOY SET @ERR = 'Una reuni' + CHAR(243) + 'n realizada no puede tener fecha futura.';
            /* PV_LZ_REUNIONES_V1: una sola reunion de lanzamiento (la que se tilda como realizada) */
            ELSE IF @L_T15 = '1' AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK)
                                             WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'LANZ' AND FECHA_CIERRE IS NOT NULL AND ID <> ISNULL(@LZ_ID, -1))
                SET @ERR = 'La reuni' + CHAR(243) + 'n de lanzamiento ya est' + CHAR(225) + ' registrada: esta reuni' + CHAR(243) + 'n se guarda sin tildar.';
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
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK) WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'CONS' AND ISNULL(OBSERVACIONES,'') <> '')
                    SET @ERR = 'Falta cargar al menos una consideraci' + CHAR(243) + 'n.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WITH(NOLOCK) WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'RIESGO' AND ISNULL(OBSERVACIONES,'') <> '')
                    SET @ERR = 'Falta cargar al menos un riesgo.';
                ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'LANZAMIENTO'
                                    WHERE A.ID_PROYECTO = @ID_PROYECTO AND A.ID_ESTADO = @LZ_CUMP)
                    SET @ERR = 'Falta registrar la reuni' + CHAR(243) + 'n de lanzamiento (tildada como realizada).';
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
        /* PV_LZ_REUNIONES_V1: la reunion de lanzamiento tambien se edita y se elimina; si deja de serlo, la accion vuelve a pendiente */
        IF @ERR = '' AND @B_CMD = 'PV_IN_BORRAR'
        BEGIN
            IF @LZ_P_EST <> @LZ_P_CURSO SET @ERR = 'El proyecto no est' + CHAR(225) + ' En curso: no hay inicio para deshacer.';
            ELSE IF COL_LENGTH('dbo.VCT_PROYECTOS_PLANES', 'ID_PROYECTO') IS NOT NULL
            BEGIN
                EXEC sp_executesql N'SELECT @N = COUNT(*) FROM dbo.VCT_PROYECTOS_PLANES WITH(NOLOCK) WHERE ID_PROYECTO = @P',
                     N'@N INT OUTPUT, @P INT', @N = @LZ_N OUTPUT, @P = @ID_PROYECTO;
                IF @LZ_N > 0 SET @ERR = 'El proyecto ya tiene plan estrat' + CHAR(233) + 'gico cargado: no se puede deshacer el inicio.';
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
                    INSERT INTO dbo.VCT_PROYECTOS_DATOS
                        (ID_PROYECTO, ID_SERVICIO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, FECHA_DOCUMENTO, NRO_INTERNO, TEMAS, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @LZ_SRV, @LZ_PS, @LZ_DOC, GETDATE(),
                            CASE WHEN @LZ_ITEM IS NULL THEN 'LIBRE' ELSE 'ITEM:' + CONVERT(VARCHAR(20), @LZ_ITEM) END,
                            @LZ_PREG, 'MG', 'REGISTRADO', LEFT(@B_T13, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_DE_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DATOS
                       SET OBSERVACIONES = LEFT(@B_T13, 2000),
                           TEMAS = CASE WHEN NRO_INTERNO = 'LIBRE' AND @B_T12 <> '' THEN LEFT(@B_T12, 1000) ELSE TEMAS END,
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @LZ_ID;

                IF @B_CMD = 'PV_CO_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DATOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, GETDATE(), UPPER(@B_T11), 'CONS', 'REGISTRADO', LEFT(@B_T12, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_CO_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DATOS SET NRO_INTERNO = UPPER(@B_T11), OBSERVACIONES = LEFT(@B_T12, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @LZ_ID;

                IF @B_CMD = 'PV_RI_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DATOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, GETDATE(), @RI_NIVEL, 'RIESGO', 'REGISTRADO', LEFT(@B_T12, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_RI_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DATOS SET NRO_INTERNO = @RI_NIVEL, OBSERVACIONES = LEFT(@B_T12, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                    WHERE ID = @LZ_ID;
                IF @B_CMD = 'PV_RI_GUARDAR' AND @RI_CAMBIA = 1
                    UPDATE dbo.VCT_PROYECTOS SET NIVEL_RIESGO = @RI_NIVEL, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @ID_PROYECTO;

                IF @B_CMD = 'PV_RE_GUARDAR' AND @LZ_ID IS NULL
                    INSERT INTO dbo.VCT_PROYECTOS_DATOS
                        (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, PARTICIPANTES, TEMAS, ID_CONSULTOR, FECHA_CIERRE, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, @LZ_FECHA, CASE WHEN @L_T15 = '1' THEN 'Reuni' + CHAR(243) + 'n de lanzamiento' ELSE 'Reuni' + CHAR(243) + 'n' END, LEFT(@B_T12, 500), LEFT(@B_T13, 1000), @LZ_CONS,
                            CASE WHEN @L_T15 = '1' THEN GETDATE() END, 'LANZ', CASE WHEN @L_T15 = '1' THEN 'REALIZADA' ELSE 'PROGRAMADA' END,
                            LEFT(@L_T14, 2000), GETDATE(), @IAGENTE);
                IF @B_CMD = 'PV_RE_GUARDAR' AND @LZ_ID IS NOT NULL
                    UPDATE dbo.VCT_PROYECTOS_DATOS
                       SET FECHA_DOCUMENTO = @LZ_FECHA, NRO_INTERNO = CASE WHEN @L_T15 = '1' THEN 'Reuni' + CHAR(243) + 'n de lanzamiento' ELSE 'Reuni' + CHAR(243) + 'n' END, PARTICIPANTES = LEFT(@B_T12, 500), TEMAS = LEFT(@B_T13, 1000), ID_CONSULTOR = @LZ_CONS,
                           FECHA_CIERRE = CASE WHEN @L_T15 = '1' THEN ISNULL(FECHA_CIERRE, GETDATE()) END,
                           ESTADO = CASE WHEN @L_T15 = '1' THEN 'REALIZADA' ELSE 'PROGRAMADA' END,
                           OBSERVACIONES = LEFT(@L_T14, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @LZ_ID;

                IF @B_CMD IN ('PV_DE_BORRAR','PV_CO_BORRAR','PV_RI_BORRAR','PV_RE_BORRAR','PV_IN_BORRAR')
                    DELETE FROM dbo.VCT_PROYECTOS_DATOS WHERE ID = @LZ_ID AND ID_PROYECTO = @ID_PROYECTO AND TIPO = @LZ_TIPO;

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
                        IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DATOS WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'LANZ' AND FECHA_CIERRE IS NOT NULL)
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
                    INSERT INTO dbo.VCT_PROYECTOS_DATOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
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
                    UPDATE dbo.VCT_PROYECTOS_DATOS SET FECHA_DOCUMENTO = @LZ_FECHA, OBSERVACIONES = LEFT(@B_T12, 2000), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
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
                    WHEN 'PV_RI_GUARDAR' THEN 'Riesgo guardado.' + CASE WHEN @RI_CAMBIA = 1 THEN ' Nivel de riesgo del proyecto: ' + @RI_NIVEL + '.' ELSE '' END
                    WHEN 'PV_RI_BORRAR'  THEN 'Riesgo eliminado.'
                    WHEN 'PV_RE_GUARDAR' THEN CASE WHEN @L_T15 = '1' THEN 'Reuni' + CHAR(243) + 'n de lanzamiento guardada: la acci' + CHAR(243) + 'n qued' + CHAR(243) + ' cumplida.' ELSE 'Reuni' + CHAR(243) + 'n guardada.' END
                    WHEN 'PV_RE_BORRAR'  THEN 'Reuni' + CHAR(243) + 'n eliminada.'
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
       Comandos (TEXTO30): PV_PL_GENERAR, PV_PL_ITEM_GUARDAR, PV_PL_ITEM_BORRAR, PV_PL_ACC_GUARDAR, PV_PL_ACC_ESTADO, PV_PL_ACC_BORRAR, PV_PL_CERRAR.
       PL_ARBOL_V1: el plan base sale de la norma del proyecto (VCT_PRM_DOCUMENTOS.ID_NORMA, la principal primero) y se copia
       como arbol capitulo > item > subitem (ID_PADRE). Responsable de la accion: equipo, cliente u otro (texto libre).
       Permiso: consultores del equipo, analista del proyecto o EDIT de PROYECTOS. */
    DECLARE @PUEDE_PLAN BIT = @PUEDE_LANZ;
    IF @PUEDE_PLAN = 0 AND @CONS_U IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR = @CONS_U)
        SET @PUEDE_PLAN = 1;

    IF @B_FLAG = '1' AND @B_CMD IN ('PV_PL_GENERAR','PV_PL_ITEM_GUARDAR','PV_PL_ITEM_BORRAR','PV_PL_ACC_GUARDAR','PV_PL_ACC_ESTADO','PV_PL_ACC_BORRAR','PV_PL_CERRAR')
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
        /* PL_ARBOL_V1: TEXTO15 responsable = EQ:<fila de equipo> / CLI / OTRO; TEXTO11 nombre si es OTRO; TEXTO14 id de la accion al editar */
        DECLARE @PA_RT VARCHAR(20), @PA_RID INT, @PA_RNOM VARCHAR(150), @PA_RERR VARCHAR(200) = '', @PA_ACC INT, @PA_OLD_EST INT,
                @PL_CAPI INT, @PL_ITEM_GRP VARCHAR(100), @PL_DOC_DES VARCHAR(400) = '';

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
        IF @ERR = '' AND @PUEDE_PLAN = 0 SET @ERR = 'No tiene permiso para editar el plan estrat' + CHAR(233) + 'gico de este proyecto.';
        IF @ERR = '' AND @B_CMD <> 'PV_PL_GENERAR' AND @PL_PLAN IS NULL SET @ERR = 'El proyecto todav' + CHAR(237) + 'a no tiene plan.';

        /* fechas aaaa-mm-dd: TEXTO12 inicio / vence, TEXTO13 fin, TEXTO14 fin real */
        IF @ERR = '' AND @B_CMD IN ('PV_PL_ITEM_GUARDAR','PV_PL_ACC_GUARDAR')
        BEGIN
            IF @B_T12 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T12,'-','')) = 1 SET @PL_FI = CONVERT(DATETIME, REPLACE(@B_T12,'-',''), 112);
            IF @B_T13 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T13,'-','')) = 1 SET @PL_FF = CONVERT(DATETIME, REPLACE(@B_T13,'-',''), 112);
            IF @B_CMD = 'PV_PL_ITEM_GUARDAR' AND @PL_T14 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@PL_T14,'-','')) = 1 SET @PL_FR = CONVERT(DATETIME, REPLACE(@PL_T14,'-',''), 112);
            IF (@B_T12 <> '' AND @PL_FI IS NULL) OR (@B_T13 <> '' AND @PL_FF IS NULL) OR (@B_CMD = 'PV_PL_ITEM_GUARDAR' AND @PL_T14 <> '' AND @PL_FR IS NULL) SET @ERR = 'Alguna de las fechas no es v' + CHAR(225) + 'lida.';
            IF @B_CMD = 'PV_PL_ITEM_GUARDAR' AND @PL_T15 <> '' AND PATINDEX('%[^0-9]%', @PL_T15) = 0 AND LEN(@PL_T15) <= 9 SET @PL_RESP = CONVERT(INT, @PL_T15);
            IF @ERR = '' AND @PL_RESP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK) WHERE ID = @PL_RESP AND ID_PROYECTO = @ID_PROYECTO AND ESTADO = 'ACTIVO')
                SET @ERR = 'El responsable elegido no es del equipo del proyecto.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_GENERAR'
        BEGIN
            /* plan base de la norma del proyecto (la principal primero) */
            SELECT TOP 1 @PL_DOC = D.ID, @PL_DOC_DES = ISNULL(D.DESCRIPCION, D.CODIGO)
            FROM dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK)
            INNER JOIN dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK) ON PN.ID_NORMA = D.ID_NORMA AND PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA'
            WHERE D.ACTIVO = 1 AND ISNULL(D.TIPO_DETALLE,'') = 'PLAN'
            ORDER BY PN.PRINCIPAL DESC, PN.ID, D.ID DESC;
            /* plan en blanco: la cabecera igual necesita un documento de plan (FK) */
            IF @PL_DOC IS NULL AND UPPER(@B_T11) = 'BLANCO'
                SELECT TOP 1 @PL_DOC = ID, @PL_DOC_DES = ISNULL(DESCRIPCION, CODIGO) FROM dbo.VCT_PRM_DOCUMENTOS WITH(NOLOCK) WHERE ACTIVO = 1 AND ISNULL(TIPO_DETALLE,'') = 'PLAN' ORDER BY ID;
            SELECT TOP 1 @PL_PS = PS.ID FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID = PS.ID_SERVICIO AND UPPER(LEFT(ISNULL(S.CODIGO,''),2)) = 'CO'
            WHERE PS.ID_PROYECTO = @ID_PROYECTO ORDER BY PS.ID;
            IF @PL_PLAN IS NOT NULL SET @ERR = 'El proyecto ya tiene plan.';
            ELSE IF @PL_PS IS NULL SET @ERR = 'El plan estrat' + CHAR(233) + 'gico solo existe si el proyecto tiene consultor' + CHAR(237) + 'a.';
            ELSE IF @PL_DOC IS NULL AND UPPER(@B_T11) = 'BLANCO' SET @ERR = 'No hay ning' + CHAR(250) + 'n plan base activo en parametr' + CHAR(237) + 'a.';
            ELSE IF @PL_DOC IS NULL SET @ERR = 'No hay plan base cargado para las normas del proyecto.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ITEM_GUARDAR'
        BEGIN
            SET @PL_TIT = LEFT(@B_T11, 400);
            IF @PL_T16 <> '' AND PATINDEX('%[^0-9]%', @PL_T16) = 0 AND LEN(@PL_T16) <= 9 SET @PL_PADRE = NULLIF(CONVERT(INT, @PL_T16), 0);
            IF @PL_T19 <> '' AND PATINDEX('%[^0-9]%', @PL_T19) = 0 AND LEN(@PL_T19) <= 9 SET @PL_CAPI = NULLIF(CONVERT(INT, @PL_T19), 0);
            IF @PL_ID IS NOT NULL
            BEGIN
                SELECT @PL_OLD_FI = I.FECHA_INICIO, @PL_OLD_FF = I.FECHA_VENCIMIENTO, @PL_OLD_TIT = I.TITULO, @PL_ITEM_GRP = I.GRUPO,
                       @PL_PADRE = CASE WHEN P.GRUPO = 'CAPITULO' THEN NULL ELSE I.ID_PADRE END
                FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P WITH(NOLOCK) ON P.ID = I.ID_PADRE
                WHERE I.ID = @PL_ID AND I.ID_PLAN = @PL_PLAN;
                IF @PL_OLD_TIT IS NULL SET @ERR = 'El ' + CHAR(237) + 'tem no pertenece al plan de este proyecto.';
                ELSE IF @PL_ITEM_GRP = 'CAPITULO' SET @ERR = 'Los cap' + CHAR(237) + 'tulos no se editan desde el plan.';
            END;
            IF @ERR = '' AND @PL_PADRE IS NOT NULL
            BEGIN
                /* subitem: el padre es un item (sin padre o hijo de un capitulo) */
                SET @PL_ES_SUB = 1;
                SET @PL_CAPI = NULL;
                IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P WITH(NOLOCK) ON P.ID = I.ID_PADRE
                               WHERE I.ID = @PL_PADRE AND I.ID_PLAN = @PL_PLAN AND ISNULL(I.GRUPO,'') <> 'CAPITULO' AND (I.ID_PADRE IS NULL OR P.GRUPO = 'CAPITULO'))
                    SET @ERR = 'El ' + CHAR(237) + 'tem padre no es v' + CHAR(225) + 'lido.';
            END;
            IF @ERR = '' AND @PL_ES_SUB = 0 AND @PL_CAPI IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_CAPI AND ID_PLAN = @PL_PLAN AND GRUPO = 'CAPITULO')
                SET @ERR = 'El cap' + CHAR(237) + 'tulo elegido no es del plan.';
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
            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_ID AND GRUPO = 'CAPITULO')
                SET @ERR = 'Los cap' + CHAR(237) + 'tulos no se eliminan.';
            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID_PADRE = @PL_ID)
                SET @ERR = 'El ' + CHAR(237) + 'tem tiene sub-' + CHAR(237) + 'tems: elim' + CHAR(237) + 'nelos primero.';
            ELSE IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES WITH(NOLOCK) WHERE ID_PLAN_ITEM = @PL_ID)
                SET @ERR = 'El ' + CHAR(237) + 'tem tiene acciones: no se puede eliminar.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_ACC_GUARDAR'
        BEGIN
            /* IDSELEC03 = item (o sub-item); el rango lo da el item superior */
            DECLARE @PL_TOP INT, @PL_TOP_FI DATETIME, @PL_TOP_FF DATETIME;
            SELECT @PL_TOP = CASE WHEN P.ID IS NULL OR P.GRUPO = 'CAPITULO' THEN I.ID ELSE P.ID END, @PL_ITEM_GRP = I.GRUPO
            FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P WITH(NOLOCK) ON P.ID = I.ID_PADRE
            WHERE I.ID = @PL_ID AND I.ID_PLAN = @PL_PLAN;
            SELECT @PL_TOP_FI = FECHA_INICIO, @PL_TOP_FF = FECHA_VENCIMIENTO FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_TOP;
            IF @PL_T14 <> '' AND PATINDEX('%[^0-9]%', @PL_T14) = 0 AND LEN(@PL_T14) <= 9
                SELECT @PA_ACC = A.ID, @PA_OLD_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
                WHERE A.ID = CONVERT(INT, @PL_T14) AND A.ID_PROYECTO = @ID_PROYECTO AND A.ID_PLAN_ITEM = @PL_ID;
            /* responsable: EQ:<fila de equipo> / CLI (cliente del proyecto) / OTRO (nombre libre) */
            IF @PL_T15 LIKE 'EQ:[0-9]%' AND PATINDEX('%[^0-9]%', SUBSTRING(@PL_T15, 4, 20)) = 0 AND LEN(@PL_T15) <= 12
                SELECT @PA_RT = EQ.TIPO_MIEMBRO, @PA_RID = CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END
                FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                WHERE EQ.ID = CONVERT(INT, SUBSTRING(@PL_T15, 4, 20)) AND EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO';
            ELSE IF @PL_T15 = 'CLI' AND @PL_CLI IS NOT NULL
                SELECT @PA_RT = 'CLIENTE', @PA_RID = @PL_CLI;
            ELSE IF @PL_T15 = 'OTRO' AND LTRIM(RTRIM(ISNULL(@B_T11,''))) <> ''
                SELECT @PA_RT = 'OTRO', @PA_RID = NULL, @PA_RNOM = LEFT(LTRIM(RTRIM(@B_T11)), 150);
            SET @PA_RERR = CASE WHEN @PL_T15 = 'OTRO' THEN 'Nombre del responsable es obligatorio.'
                                WHEN @PL_T15 LIKE 'EQ:%' THEN 'El responsable elegido no es del equipo del proyecto.'
                                ELSE 'Responsable es obligatorio.' END;
            IF @PL_TOP IS NULL SET @ERR = 'El ' + CHAR(237) + 'tem no pertenece al plan de este proyecto.';
            ELSE IF @PL_ITEM_GRP = 'CAPITULO' SET @ERR = 'Las acciones se cargan en un ' + CHAR(237) + 'tem o sub' + CHAR(237) + 'tem, no en el cap' + CHAR(237) + 'tulo.';
            ELSE IF @PL_T14 <> '' AND @PA_ACC IS NULL SET @ERR = 'La acci' + CHAR(243) + 'n no es de este ' + CHAR(237) + 'tem.';
            ELSE
            BEGIN
                SELECT @PA_ITEM_TIT = TITULO FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WITH(NOLOCK) WHERE ID = @PL_ID;
                IF @PL_T21 <> '' AND PATINDEX('%[^0-9]%', @PL_T21) = 0 AND LEN(@PL_T21) <= 9
                    SELECT @PA_TIPO = ID FROM dbo.VCT_PRM_ACCIONES_TIPOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T21) AND ACTIVO = 1;
                IF @PL_T16 <> '' AND PATINDEX('%[^0-9]%', @PL_T16) = 0 AND LEN(@PL_T16) <= 9
                    SELECT @PA_SUB = ID, @PA_SUB_TIPO = ID_TIPO, @PA_SUB_DES = DESCRIPCION FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T16) AND ACTIVO = 1 AND CARGA_MANUAL IN ('PLAN','AMBOS');
                IF @PL_T17 <> '' AND PATINDEX('%[^0-9]%', @PL_T17) = 0 AND LEN(@PL_T17) <= 9
                    SELECT @PA_PRIO = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T17) AND ACTIVO = 1;
                IF @PL_T19 <> '' AND PATINDEX('%[^0-9]%', @PL_T19) = 0 AND LEN(@PL_T19) <= 9
                    SELECT @PA_EST = ID, @PA_EST_FIN = ES_FINAL FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T19) AND ACTIVO = 1;
                IF @PL_T20 <> '' AND PATINDEX('%[^0-9]%', @PL_T20) = 0 AND LEN(@PL_T20) <= 9
                    SELECT @PA_RES = ID FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @PL_T20) AND ACTIVO = 1 AND CARGA_MANUAL = 1;

                IF @PA_TIPO IS NULL SET @ERR = 'Tipo es obligatorio.';
                ELSE IF @PA_SUB IS NULL SET @ERR = 'Subtipo es obligatorio.';
                ELSE IF @PA_SUB_TIPO <> @PA_TIPO SET @ERR = 'El subtipo no corresponde al tipo elegido.';
                ELSE IF @PA_PRIO IS NULL SET @ERR = 'Prioridad es obligatoria.';
                ELSE IF @PA_EST IS NULL SET @ERR = 'Estado es obligatorio.';
                ELSE IF @PA_EST_FIN = 1 AND @PA_RES IS NULL SET @ERR = 'Resultado es obligatorio para un estado final.';
                ELSE IF @B_T13 <> '' AND @PL_FF IS NULL SET @ERR = 'La fecha de inicio no es v' + CHAR(225) + 'lida.';
                ELSE IF @PL_FI IS NULL SET @ERR = 'Vence es obligatorio.';
                ELSE IF @PL_FF IS NOT NULL AND @PL_FI < @PL_FF SET @ERR = 'Vence no puede ser anterior a la fecha de inicio.';
                ELSE IF @PA_RT IS NULL SET @ERR = @PA_RERR;
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

        IF @ERR = '' AND @B_CMD = 'PV_PL_ACC_BORRAR'
        BEGIN
            SELECT @PL_ACC = A.ID, @PL_ACC_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            WHERE A.ID = @PL_ID AND A.ID_PROYECTO = @ID_PROYECTO AND A.ID_PLAN_ITEM IS NOT NULL;
            IF @PL_ACC IS NULL SET @ERR = 'La acci' + CHAR(243) + 'n no es del plan de este proyecto.';
            ELSE IF @PL_CANC IS NULL SET @ERR = 'Falta el estado CANCELADA en la parametr' + CHAR(237) + 'a de acciones.';
        END;

        IF @ERR = '' AND @B_CMD = 'PV_PL_CERRAR'
        BEGIN
            SELECT TOP 1 @PL_ACC = A.ID, @PL_ACC_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'CARGA_PLAN'
            INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
            WHERE A.ID_PROYECTO = @ID_PROYECTO ORDER BY A.ID;
            SELECT @PL_N = COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P WITH(NOLOCK) ON P.ID = I.ID_PADRE
            WHERE I.ID_PLAN = @PL_PLAN AND ISNULL(I.GRUPO,'') <> 'CAPITULO' AND (I.ID_PADRE IS NULL OR P.GRUPO = 'CAPITULO')
              AND (I.FECHA_INICIO IS NULL OR I.FECHA_VENCIMIENTO IS NULL);
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
                        /* arbol del plan base: se copian todos los nodos y despues se enlaza cada uno con su padre */
                        INSERT INTO dbo.VCT_PROYECTOS_PLAN_ITEMS (ID_PLAN, ID_DOCUMENTO_ITEM, CODIGO_ITEM, TITULO, GRUPO, ORDEN, OBLIGATORIO, ESTADO, PORCENTAJE_AVANCE, FECHA_ALTA, USUARIO_ALTA)
                        SELECT @PL_PLAN, I.ID, I.CODIGO_ITEM, LEFT(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(I.DESCRIPCION,''))), CHAR(13), ' '), CHAR(10), ' '), 400),
                               I.GRUPO, ISNULL(I.ORDEN, 999), ISNULL(I.OBLIGATORIO, 0), 'PENDIENTE', 0, GETDATE(), @IAGENTE
                        FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
                        WHERE I.ID_DOCUMENTO = @PL_DOC AND I.ACTIVO = 1
                        ORDER BY I.ORDEN, I.ID;
                        UPDATE C SET ID_PADRE = P.ID
                        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS C
                        INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS D WITH(NOLOCK) ON D.ID = C.ID_DOCUMENTO_ITEM
                        INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P ON P.ID_PLAN = @PL_PLAN AND P.ID_DOCUMENTO_ITEM = D.ID_PADRE
                        WHERE C.ID_PLAN = @PL_PLAN;
                        SELECT @PL_N = COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS WHERE ID_PLAN = @PL_PLAN AND ISNULL(GRUPO,'') <> 'CAPITULO';
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
                                    ELSE 'Plan generado con ' + CONVERT(VARCHAR(10), @PL_N) + ' ' + CHAR(237) + 'tems y sub' + CHAR(237) + 'tems del plan base ' + @PL_DOC_DES + '. Defina fechas y responsables de cada ' + CHAR(237) + 'tem.' END;
                END;

                IF @B_CMD = 'PV_PL_ITEM_GUARDAR'
                BEGIN
                    IF @PL_ID IS NULL
                    BEGIN
                        INSERT INTO dbo.VCT_PROYECTOS_PLAN_ITEMS (ID_PLAN, ID_PADRE, TITULO, GRUPO, ORDEN, OBLIGATORIO, ESTADO, ID_RESPONSABLE_EQUIPO,
                                                                FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, PORCENTAJE_AVANCE, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
                        SELECT @PL_PLAN, ISNULL(@PL_PADRE, @PL_CAPI), @PL_TIT, CASE WHEN @PL_T17 = '1' THEN 'HITO' ELSE 'PLAN ESTRATEGICO' END,
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
                               ID_PADRE = CASE WHEN @PL_ES_SUB = 1 THEN ID_PADRE ELSE @PL_CAPI END,
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

                IF @B_CMD = 'PV_PL_ACC_GUARDAR' AND @PA_ACC IS NOT NULL
                BEGIN
                    UPDATE dbo.VCT_ACCIONES
                       SET ID_TIPO = @PA_TIPO, ID_SUBTIPO = @PA_SUB, ID_ESTADO = @PA_EST, ID_PRIORIDAD = @PA_PRIO, ID_RESULTADO = @PA_RES,
                           TITULO = LEFT(@PA_SUB_DES + ' - ' + ISNULL(@PA_ITEM_TIT, ''), 300), DESCRIPCION = NULLIF(@PL_T18, ''),
                           FECHA_INICIO = @PL_FF, FECHA_VENCIMIENTO = @PL_FI,
                           FECHA_CIERRE = CASE WHEN @PA_EST_FIN = 1 THEN ISNULL(FECHA_CIERRE, GETDATE()) END,
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @PA_ACC;
                    /* responsable: si cambio, el anterior queda inactivo */
                    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES WHERE ID_ACCION = @PA_ACC AND ROL_PARTICIPANTE = 'RESPONSABLE' AND ESTADO = 'ACTIVO'
                                   AND TIPO_ENTIDAD = @PA_RT AND ISNULL(ID_ENTIDAD, -1) = ISNULL(@PA_RID, -1) AND ISNULL(NOMBRE_LIBRE, '') = ISNULL(@PA_RNOM, ''))
                    BEGIN
                        UPDATE dbo.VCT_ACCIONES_PARTICIPANTES SET ESTADO = 'INACTIVO', FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                        WHERE ID_ACCION = @PA_ACC AND ROL_PARTICIPANTE = 'RESPONSABLE' AND ESTADO = 'ACTIVO';
                        INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, NOMBRE_LIBRE, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                        VALUES (@PA_ACC, 'RESPONSABLE', @PA_RT, @PA_RID, @PA_RNOM, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                    END;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@PA_ACC, @PA_OLD_EST, @PA_EST, 'MODIFICADA', 'Acci' + CHAR(243) + 'n del plan editada.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n actualizada.';
                END;
                IF @B_CMD = 'PV_PL_ACC_GUARDAR' AND @PA_ACC IS NULL
                BEGIN
                    DECLARE @PL_NEWB INT;
                    INSERT INTO dbo.VCT_ACCIONES (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN, ID_PLAN_ITEM,
                                                  REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
                    VALUES ('MANUAL', @PA_TIPO, @PA_SUB, @PA_EST, @PA_PRIO, @PA_RES, LEFT(@PA_SUB_DES + ' - ' + ISNULL(@PA_ITEM_TIT, ''), 300), NULLIF(@PL_T18, ''), @PL_CLI, @ID_PROYECTO, @PL_PLAN, @PL_ID,
                            0, 0, GETDATE(), @PL_FF, @PL_FI, CASE WHEN @PA_EST_FIN = 1 THEN GETDATE() END, GETDATE(), @IAGENTE);
                    SET @PL_NEWB = SCOPE_IDENTITY();
                    INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, NOMBRE_LIBRE, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@PL_NEWB, 'RESPONSABLE', @PA_RT, @PA_RID, @PA_RNOM, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
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
                            CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'CUMPLIDA' ELSE 'REABIERTA' END, 'Desde el plan estrat' + CHAR(233) + 'gico.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'Acci' + CHAR(243) + 'n cumplida.' ELSE 'Acci' + CHAR(243) + 'n reabierta.' END;
                END;

                IF @B_CMD = 'PV_PL_ACC_BORRAR'
                BEGIN
                    /* no se borra fisicamente (tiene historial y participantes): queda CANCELADA y sale del plan */
                    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @PL_CANC, FECHA_CIERRE = GETDATE(), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @PL_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@PL_ACC, @PL_ACC_EST, @PL_CANC, 'ELIMINADA', 'Acci' + CHAR(243) + 'n eliminada del plan estrat' + CHAR(233) + 'gico.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n eliminada.';
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
                LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS PP ON PP.ID = I.ID_PADRE
                INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS T ON T.ID = CASE WHEN I.GRUPO = 'CAPITULO' OR PP.ID IS NULL OR PP.GRUPO = 'CAPITULO' THEN I.ID ELSE PP.ID END
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

    /* ======================= ACCIONES DEL PROYECTO: comandos (AC_PESTANIA_V1) =======================
       Acciones manuales del proyecto fuera del plan (VCT_ACCIONES con ID_PLAN_ITEM NULL, ORIGEN MANUAL).
       Comandos (TEXTO30): PV_AC_GUARDAR (alta / edicion), PV_AC_ESTADO (cumplida / reabrir), PV_AC_BORRAR (queda CANCELADA).
       Buffer: IDSELEC03 = accion al editar (0 = nueva); TEXTO21 tipo, TEXTO16 subtipo, TEXTO17 prioridad, TEXTO19 estado,
       TEXTO20 resultado, TEXTO13 inicio, TEXTO12 vence, TEXTO15 responsable (EQ:<fila de equipo> / CLI / OTRO), TEXTO11 nombre si es OTRO,
       TEXTO18 detalle. Solo subtipos con CARGA_MANUAL PROYECTO / AMBOS. Mismo permiso que el plan. */
    IF @B_FLAG = '1' AND @B_CMD IN ('PV_AC_GUARDAR','PV_AC_ESTADO','PV_AC_BORRAR')
    BEGIN
        DECLARE @AC_T15 VARCHAR(4000) = '', @AC_T16 VARCHAR(4000) = '', @AC_T17 VARCHAR(4000) = '', @AC_T18 VARCHAR(4000) = '',
                @AC_T19 VARCHAR(4000) = '', @AC_T20 VARCHAR(4000) = '', @AC_T21 VARCHAR(4000) = '',
                @AC_ID INT, @AC_ACC INT, @AC_OLD_EST INT, @AC_TIPO INT, @AC_SUB INT, @AC_SUB_TIPO INT, @AC_SUB_DES VARCHAR(150),
                @AC_PRIO INT, @AC_EST INT, @AC_EST_FIN BIT, @AC_RES INT, @AC_INI DATETIME, @AC_VENCE DATETIME,
                @AC_RT VARCHAR(20), @AC_RID INT, @AC_RNOM VARCHAR(150), @AC_CLI INT, @AC_CUMP INT, @AC_PEND INT, @AC_CANC INT, @AC_NEW INT;
        SELECT TOP 1 @AC_T15 = LTRIM(RTRIM(ISNULL(TEXTO15,''))), @AC_T16 = LTRIM(RTRIM(ISNULL(TEXTO16,''))), @AC_T17 = LTRIM(RTRIM(ISNULL(TEXTO17,''))),
                     @AC_T18 = LTRIM(RTRIM(ISNULL(TEXTO18,''))), @AC_T19 = LTRIM(RTRIM(ISNULL(TEXTO19,''))), @AC_T20 = LTRIM(RTRIM(ISNULL(TEXTO20,''))),
                     @AC_T21 = LTRIM(RTRIM(ISNULL(TEXTO21,'')))
        FROM dbo.VCT_BUFFER WITH(NOLOCK) WHERE PAR_KEY = @IPKEYJOB;
        UPDATE dbo.VCT_BUFFER SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL, TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL,
               TEXTO14 = NULL, TEXTO15 = NULL, TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL, TEXTO21 = NULL
        WHERE PAR_KEY = @IPKEYJOB;
        SET @VOLVER = 'acciones';
        IF @B_SEL3 <> '' AND PATINDEX('%[^0-9]%', @B_SEL3) = 0 AND LEN(@B_SEL3) <= 9 SET @AC_ID = NULLIF(CONVERT(INT, @B_SEL3), 0);
        SELECT @AC_CLI = IDCLIENTE FROM dbo.VCT_PROYECTOS WITH(NOLOCK) WHERE ID = @ID_PROYECTO;
        SELECT @AC_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE';
        SELECT @AC_CUMP = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';
        SELECT @AC_CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';

        IF @ID_PROYECTO IS NULL SET @ERR = 'No hay proyecto seleccionado.';
        IF @ERR = '' AND @PUEDE_PLAN = 0 SET @ERR = 'No tiene permiso para cargar acciones en este proyecto.';
        /* solo acciones manuales del proyecto y fuera del plan */
        IF @ERR = '' AND @AC_ID IS NOT NULL
        BEGIN
            SELECT @AC_ACC = A.ID, @AC_OLD_EST = A.ID_ESTADO FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
            WHERE A.ID = @AC_ID AND A.ID_PROYECTO = @ID_PROYECTO AND A.ID_PLAN_ITEM IS NULL AND A.ORIGEN = 'MANUAL';
            IF @AC_ACC IS NULL SET @ERR = 'La acci' + CHAR(243) + 'n no es una acci' + CHAR(243) + 'n manual de este proyecto.';
        END;
        IF @ERR = '' AND @B_CMD IN ('PV_AC_ESTADO','PV_AC_BORRAR') AND @AC_ACC IS NULL SET @ERR = 'Falta la acci' + CHAR(243) + 'n.';
        IF @ERR = '' AND @B_CMD = 'PV_AC_ESTADO' AND UPPER(@B_T11) NOT IN ('CUMPLIDA','PENDIENTE') SET @ERR = 'Estado no v' + CHAR(225) + 'lido.';
        IF @ERR = '' AND @B_CMD = 'PV_AC_BORRAR' AND @AC_CANC IS NULL SET @ERR = 'Falta el estado CANCELADA en la parametr' + CHAR(237) + 'a de acciones.';

        IF @ERR = '' AND @B_CMD = 'PV_AC_GUARDAR'
        BEGIN
            IF @AC_T21 <> '' AND PATINDEX('%[^0-9]%', @AC_T21) = 0 AND LEN(@AC_T21) <= 9
                SELECT @AC_TIPO = ID FROM dbo.VCT_PRM_ACCIONES_TIPOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @AC_T21) AND ACTIVO = 1;
            IF @AC_T16 <> '' AND PATINDEX('%[^0-9]%', @AC_T16) = 0 AND LEN(@AC_T16) <= 9
                SELECT @AC_SUB = ID, @AC_SUB_TIPO = ID_TIPO, @AC_SUB_DES = DESCRIPCION FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK)
                WHERE ID = CONVERT(INT, @AC_T16) AND ACTIVO = 1 AND CARGA_MANUAL IN ('PROYECTO','AMBOS');
            IF @AC_T17 <> '' AND PATINDEX('%[^0-9]%', @AC_T17) = 0 AND LEN(@AC_T17) <= 9
                SELECT @AC_PRIO = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE ID = CONVERT(INT, @AC_T17) AND ACTIVO = 1;
            IF @AC_T19 <> '' AND PATINDEX('%[^0-9]%', @AC_T19) = 0 AND LEN(@AC_T19) <= 9
                SELECT @AC_EST = ID, @AC_EST_FIN = ES_FINAL FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @AC_T19) AND ACTIVO = 1;
            IF @AC_T20 <> '' AND PATINDEX('%[^0-9]%', @AC_T20) = 0 AND LEN(@AC_T20) <= 9
                SELECT @AC_RES = ID FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE ID = CONVERT(INT, @AC_T20) AND ACTIVO = 1 AND CARGA_MANUAL = 1;
            IF @B_T13 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T13,'-','')) = 1 SET @AC_INI = CONVERT(DATETIME, REPLACE(@B_T13,'-',''), 112);
            IF @B_T12 LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' AND ISDATE(REPLACE(@B_T12,'-','')) = 1 SET @AC_VENCE = CONVERT(DATETIME, REPLACE(@B_T12,'-',''), 112);
            /* responsable: EQ:<fila de equipo> / CLI (cliente del proyecto) / OTRO (nombre libre) */
            IF @AC_T15 LIKE 'EQ:[0-9]%' AND PATINDEX('%[^0-9]%', SUBSTRING(@AC_T15, 4, 20)) = 0 AND LEN(@AC_T15) <= 12
                SELECT @AC_RT = EQ.TIPO_MIEMBRO, @AC_RID = CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END
                FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                WHERE EQ.ID = CONVERT(INT, SUBSTRING(@AC_T15, 4, 20)) AND EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO';
            ELSE IF @AC_T15 = 'CLI' AND @AC_CLI IS NOT NULL
                SELECT @AC_RT = 'CLIENTE', @AC_RID = @AC_CLI;
            ELSE IF @AC_T15 = 'OTRO' AND LTRIM(RTRIM(ISNULL(@B_T11,''))) <> ''
                SELECT @AC_RT = 'OTRO', @AC_RID = NULL, @AC_RNOM = LEFT(LTRIM(RTRIM(@B_T11)), 150);

            /* mismo orden que el formulario */
            IF @AC_TIPO IS NULL SET @ERR = 'Tipo es obligatorio.';
            ELSE IF @AC_SUB IS NULL SET @ERR = 'Subtipo es obligatorio.';
            ELSE IF @AC_SUB_TIPO <> @AC_TIPO SET @ERR = 'El subtipo no corresponde al tipo elegido.';
            ELSE IF @AC_PRIO IS NULL SET @ERR = 'Prioridad es obligatoria.';
            ELSE IF @AC_EST IS NULL SET @ERR = 'Estado es obligatorio.';
            ELSE IF @AC_EST_FIN = 1 AND @AC_RES IS NULL SET @ERR = 'Resultado es obligatorio para un estado final.';
            ELSE IF @B_T13 <> '' AND @AC_INI IS NULL SET @ERR = 'La fecha de inicio no es v' + CHAR(225) + 'lida.';
            ELSE IF @AC_VENCE IS NULL SET @ERR = 'Vence es obligatorio.';
            ELSE IF @AC_INI IS NOT NULL AND @AC_VENCE < @AC_INI SET @ERR = 'Vence no puede ser anterior a la fecha de inicio.';
            ELSE IF @AC_RT IS NULL SET @ERR = CASE WHEN @AC_T15 = 'OTRO' THEN 'Nombre del responsable es obligatorio.'
                                                    WHEN @AC_T15 LIKE 'EQ:%' THEN 'El responsable elegido no es del equipo del proyecto.'
                                                    ELSE 'Responsable es obligatorio.' END;
            IF @ERR = '' AND ISNULL(@AC_EST_FIN, 0) = 0 SET @AC_RES = NULL;
        END;

        IF @ERR = ''
        BEGIN
            BEGIN TRY
                BEGIN TRAN;
                IF @B_CMD = 'PV_AC_GUARDAR' AND @AC_ACC IS NOT NULL
                BEGIN
                    UPDATE dbo.VCT_ACCIONES
                       SET ID_TIPO = @AC_TIPO, ID_SUBTIPO = @AC_SUB, ID_ESTADO = @AC_EST, ID_PRIORIDAD = @AC_PRIO, ID_RESULTADO = @AC_RES,
                           TITULO = LEFT(@AC_SUB_DES, 300), DESCRIPCION = NULLIF(@AC_T18, ''),
                           FECHA_INICIO = @AC_INI, FECHA_VENCIMIENTO = @AC_VENCE,
                           FECHA_CIERRE = CASE WHEN @AC_EST_FIN = 1 THEN ISNULL(FECHA_CIERRE, GETDATE()) END,
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @AC_ACC;
                    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES WHERE ID_ACCION = @AC_ACC AND ROL_PARTICIPANTE = 'RESPONSABLE' AND ESTADO = 'ACTIVO'
                                   AND TIPO_ENTIDAD = @AC_RT AND ISNULL(ID_ENTIDAD, -1) = ISNULL(@AC_RID, -1) AND ISNULL(NOMBRE_LIBRE, '') = ISNULL(@AC_RNOM, ''))
                    BEGIN
                        UPDATE dbo.VCT_ACCIONES_PARTICIPANTES SET ESTADO = 'INACTIVO', FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                        WHERE ID_ACCION = @AC_ACC AND ROL_PARTICIPANTE = 'RESPONSABLE' AND ESTADO = 'ACTIVO';
                        INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, NOMBRE_LIBRE, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                        VALUES (@AC_ACC, 'RESPONSABLE', @AC_RT, @AC_RID, @AC_RNOM, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                    END;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@AC_ACC, @AC_OLD_EST, @AC_EST, 'MODIFICADA', 'Acci' + CHAR(243) + 'n del proyecto editada.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n actualizada.';
                END;
                IF @B_CMD = 'PV_AC_GUARDAR' AND @AC_ACC IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_ACCIONES (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                                                  REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
                    VALUES ('MANUAL', @AC_TIPO, @AC_SUB, @AC_EST, @AC_PRIO, @AC_RES, LEFT(@AC_SUB_DES, 300), NULLIF(@AC_T18, ''), @AC_CLI, @ID_PROYECTO,
                            0, 0, GETDATE(), @AC_INI, @AC_VENCE, CASE WHEN @AC_EST_FIN = 1 THEN GETDATE() END, GETDATE(), @IAGENTE);
                    SET @AC_NEW = SCOPE_IDENTITY();
                    INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, NOMBRE_LIBRE, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@AC_NEW, 'RESPONSABLE', @AC_RT, @AC_RID, @AC_RNOM, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@AC_NEW, NULL, @AC_EST, 'ALTA', 'Acci' + CHAR(243) + 'n del proyecto.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n agregada al proyecto.';
                END;
                IF @B_CMD = 'PV_AC_ESTADO'
                BEGIN
                    UPDATE dbo.VCT_ACCIONES
                       SET ID_ESTADO = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN @AC_CUMP ELSE @AC_PEND END,
                           FECHA_CIERRE = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN GETDATE() END,
                           ID_RESULTADO = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN ID_RESULTADO END,
                           FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                     WHERE ID = @AC_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@AC_ACC, @AC_OLD_EST, CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN @AC_CUMP ELSE @AC_PEND END,
                            CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'CUMPLIDA' ELSE 'REABIERTA' END, 'Desde la pesta' + CHAR(241) + 'a Acciones del proyecto.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = CASE WHEN UPPER(@B_T11) = 'CUMPLIDA' THEN 'Acci' + CHAR(243) + 'n cumplida.' ELSE 'Acci' + CHAR(243) + 'n reabierta.' END;
                END;
                IF @B_CMD = 'PV_AC_BORRAR'
                BEGIN
                    /* no se borra fisicamente (tiene historial y participantes): queda CANCELADA */
                    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @AC_CANC, FECHA_CIERRE = GETDATE(), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @AC_ACC;
                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                    VALUES (@AC_ACC, @AC_OLD_EST, @AC_CANC, 'ELIMINADA', 'Acci' + CHAR(243) + 'n del proyecto eliminada.', 'USUARIO', GETDATE(), @IAGENTE);
                    SET @MSG = 'Acci' + CHAR(243) + 'n eliminada.';
                END;
                COMMIT;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @MSG = '';
                SET @ERR = LEFT('No se pudo grabar la acci' + CHAR(243) + 'n: ' + ERROR_MESSAGE(), 1000);
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
                      EST_COD VARCHAR(30), EST_DES VARCHAR(100), IDX INT NULL, INI_R DATETIME NULL, FIN_R DATETIME NULL);
    INSERT INTO #SV (ID, ID_SERVICIO, COD, DES, NOMBRE, LUGAR, INI, FIN, PROY, PROG, EJEC, ORDEN, EST_COD, EST_DES, INI_R, FIN_R)
    SELECT S.ID, S.ID_SERVICIO, UPPER(ISNULL(PS.CODIGO,'')), ISNULL(PS.DESCRIPCION,''), ISNULL(S.NOMBRE,''), ISNULL(S.LUGAR,''),
           S.FECHA_INICIO, S.FECHA_FIN, ISNULL(S.TOTAL_HORAS_PROYECTADAS, 0), 0, 0, S.ORDEN, E.CODIGO, E.DESCRIPCION, S.FECHA_INICIO_REAL, S.FECHA_FIN_REAL
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
    /* servicios agrupados por tipo (PV_SV_GRUPOS_V1): consultoria unica; auditorias y capacitaciones pueden ser N */
    CREATE TABLE #SVT (T VARCHAR(2), DES VARCHAR(300), N INT, PROY NUMERIC(18,2), PROG NUMERIC(18,2), EJEC NUMERIC(18,2), ORD INT, ICO VARCHAR(40));
    INSERT INTO #SVT (T, DES, N, PROY, PROG, EJEC, ORD, ICO)
    SELECT LEFT(COD, 2), MIN(DES), COUNT(*), SUM(PROY), SUM(PROG), SUM(EJEC),
           CASE LEFT(COD, 2) WHEN 'CO' THEN 1 WHEN 'AU' THEN 2 WHEN 'CA' THEN 3 ELSE 9 END,
           CASE LEFT(COD, 2) WHEN 'AU' THEN 'clipboard-check' WHEN 'CA' THEN 'users' ELSE 'briefcase' END
    FROM #SV GROUP BY LEFT(COD, 2);

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
                     RESP VARCHAR(300), RESP_INI VARCHAR(4), AREA VARCHAR(150), MIA BIT, SIT CHAR(1),
                     /* AC_PESTANIA_V1: origen (grupo de la pestania) y datos para editar la accion del proyecto */
                     ORIG VARCHAR(20), ITEM INT, IDT INT, IDS INT, IDP INT, IDE INT, IDR INT, INI DATETIME, RT VARCHAR(20), RID INT, DETF VARCHAR(2000),
                     OG INT, RCOD VARCHAR(30), ITEM_TIT VARCHAR(400), CAPI INT, CAP_ORD INT, CAP_LBL VARCHAR(400));
    INSERT INTO #A
    SELECT A.ID, ISNULL(A.TITULO,''), ISNULL(T.DESCRIPCION,''), ISNULL(ST.CODIGO,''), ISNULL(ST.DESCRIPCION,''),
           ISNULL(E.CODIGO,''), ISNULL(E.DESCRIPCION,''), ISNULL(E.ES_FINAL,0), A.FECHA_VENCIMIENTO, A.FECHA_CIERRE, A.FECHA_CREACION,
           ISNULL(RP.NOMBRE,''), ISNULL(RP.INI,''),
           ISNULL(RP.AREA, ''),
           CASE WHEN RP.TIPO_ENTIDAD = 'EMPLEADO' AND RP.ID_ENTIDAD = @EMP_U THEN 1
                WHEN RP.TIPO_ENTIDAD = 'CONSULTOR' AND RP.ID_ENTIDAD = @CONS_U THEN 1 ELSE 0 END,
           CASE WHEN ISNULL(E.ES_FINAL,0) = 1 THEN 'C'
                WHEN A.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, A.FECHA_VENCIMIENTO) < CONVERT(DATE, @HOY) THEN 'V'
                ELSE 'A' END,
           ISNULL(A.ORIGEN,''), A.ID_PLAN_ITEM, A.ID_TIPO, A.ID_SUBTIPO, A.ID_PRIORIDAD, A.ID_ESTADO, A.ID_RESULTADO, A.FECHA_INICIO,
           ISNULL(RP.TIPO_ENTIDAD,''), RP.ID_ENTIDAD, LEFT(ISNULL(CONVERT(VARCHAR(2000), A.DESCRIPCION),''), 2000), 1, '', '', NULL, NULL, NULL
    FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) ON T.ID = A.ID_TIPO
    LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
    OUTER APPLY (
        SELECT TOP 1 AP.TIPO_ENTIDAD, AP.ID_ENTIDAD, Q.NOMBRE, Q.INI,
               /* area en Acciones: el rol ANALISTA se muestra como "Analista" (columna y filtro) */
               ISNULL((SELECT TOP 1 CASE WHEN X.ROL_COD = 'ANALISTA' THEN 'Analista' ELSE X.ROL_DES END FROM #EQ X WHERE X.TIPO = AP.TIPO_ENTIDAD AND X.ID_ENT = AP.ID_ENTIDAD ORDER BY X.ROL_ORD),
                      CASE AP.TIPO_ENTIDAD
                           WHEN 'EMPLEADO' THEN ISNULL((SELECT TOP 1 ISNULL(NULLIF(LTRIM(RTRIM(G9.Name)),''), GM9.GroupId)
                                                        FROM dbo.VCT_EMPLEADOS E9 WITH(NOLOCK)
                                                        INNER JOIN dbo.GroupsUserMembers GM9 WITH(NOLOCK) ON UPPER(LTRIM(RTRIM(GM9.UserMemberId))) = UPPER(LTRIM(RTRIM(E9.ID_USUARIO_SEGURIDAD)))
                                                        LEFT JOIN dbo.Groups G9 WITH(NOLOCK) ON UPPER(LTRIM(RTRIM(G9.Id))) = UPPER(LTRIM(RTRIM(GM9.GroupId)))
                                                        WHERE E9.ID = AP.ID_ENTIDAD ORDER BY GM9.GroupId), 'Empleado')
                           WHEN 'CONSULTOR' THEN 'Consultor' WHEN 'CLIENTE' THEN 'Cliente' WHEN 'OTRO' THEN 'Otro' ELSE ISNULL(AP.TIPO_ENTIDAD,'') END) AS AREA
        FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
        OUTER APPLY (
            SELECT TOP 1 LTRIM(RTRIM(ISNULL(E2.APELLIDOS,'') + ', ' + ISNULL(E2.NOMBRES,''))) AS NOMBRE,
                   UPPER(LEFT(ISNULL(E2.NOMBRES,''),1) + LEFT(ISNULL(E2.APELLIDOS,''),1)) AS INI
            FROM dbo.VCT_EMPLEADOS E2 WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'EMPLEADO' AND E2.ID = AP.ID_ENTIDAD
            UNION ALL
            SELECT TOP 1 LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C2.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C2.NOMBRES),''))),
                   UPPER(LEFT(ISNULL(CONVERT(VARCHAR(150),C2.NOMBRES),''),1) + LEFT(ISNULL(CONVERT(VARCHAR(150),C2.APELLIDOS),''),1))
            FROM dbo.VCT_CONSULTORES C2 WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'CONSULTOR' AND C2.ID = AP.ID_ENTIDAD
            UNION ALL   /* PL_ARBOL_V1: responsable cliente u otro (texto libre) */
            SELECT TOP 1 ISNULL(C3.RAZON_SOCIAL,''), UPPER(LEFT(LTRIM(ISNULL(C3.RAZON_SOCIAL,'')), 2))
            FROM dbo.VCT_CLIENTES C3 WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'CLIENTE' AND C3.ID = AP.ID_ENTIDAD
            UNION ALL
            SELECT ISNULL(AP.NOMBRE_LIBRE,''), UPPER(LEFT(LTRIM(ISNULL(AP.NOMBRE_LIBRE,'')), 1)
                   + CASE WHEN CHARINDEX(' ', LTRIM(RTRIM(ISNULL(AP.NOMBRE_LIBRE,'')))) > 0 THEN SUBSTRING(LTRIM(RTRIM(AP.NOMBRE_LIBRE)), CHARINDEX(' ', LTRIM(RTRIM(AP.NOMBRE_LIBRE))) + 1, 1) ELSE '' END)
            WHERE AP.TIPO_ENTIDAD = 'OTRO'
        ) Q
        WHERE AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO'
        ORDER BY AP.PRINCIPAL DESC, AP.ID
    ) RP
    WHERE A.ID_PROYECTO = @ID_PROYECTO;

    /* origen: 4 workflow (la genero el sistema), 2 plan (tiene item), 3 pendiente del cliente, 1 proyecto (manual) */
    UPDATE #A SET OG = CASE WHEN ORIG <> 'MANUAL' THEN 4 WHEN ITEM IS NOT NULL THEN 2 WHEN RT = 'CLIENTE' THEN 3 ELSE 1 END,
                  RCOD = CASE WHEN RT IN ('EMPLEADO','CONSULTOR') THEN ISNULL((SELECT TOP 1 'EQ:' + CONVERT(VARCHAR(20), Q.ID) FROM #EQ Q WHERE Q.TIPO = #A.RT AND Q.ID_ENT = #A.RID), '')
                              WHEN RT = 'CLIENTE' THEN 'CLI' WHEN RT = 'OTRO' THEN 'OTRO' ELSE '' END;
    UPDATE A SET ITEM_TIT = LEFT(ISNULL(I.CODIGO_ITEM + ' ', '') + ISNULL(I.TITULO, ''), 400),
                 /* capitulo de la accion del plan (filtro Capitulo con el chip Plan) */
                 CAPI = CH.ID, CAP_ORD = CH.ORDEN,
                 CAP_LBL = LEFT(CASE WHEN ISNULL(CH.CODIGO_ITEM,'') LIKE '[0-9]%' THEN 'Cap' + CHAR(237) + 'tulo ' + CH.CODIGO_ITEM + ' - ' ELSE '' END + ISNULL(CH.TITULO,''), 400)
    FROM #A A INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) ON I.ID = A.ITEM
    LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P1 WITH(NOLOCK) ON P1.ID = I.ID_PADRE
    LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P2 WITH(NOLOCK) ON P2.ID = P1.ID_PADRE
    LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS CH WITH(NOLOCK) ON CH.ID = CASE WHEN P1.GRUPO = 'CAPITULO' THEN P1.ID WHEN P2.GRUPO = 'CAPITULO' THEN P2.ID END;
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
    FROM dbo.VCT_PROYECTOS_DATOS D WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I WITH(NOLOCK)
           ON D.TIPO = 'MG' AND D.NRO_INTERNO LIKE 'ITEM:%' AND LEN(D.NRO_INTERNO) BETWEEN 6 AND 14
          AND SUBSTRING(D.NRO_INTERNO, 6, 20) NOT LIKE '%[^0-9]%'
          AND I.ID = CASE WHEN SUBSTRING(D.NRO_INTERNO, 6, 20) NOT LIKE '%[^0-9]%' AND LEN(D.NRO_INTERNO) BETWEEN 6 AND 14 THEN CONVERT(INT, SUBSTRING(D.NRO_INTERNO, 6, 20)) END
    LEFT JOIN #MIN M ON M.ID_DOCUMENTO = D.ID_DOCUMENTO
    LEFT JOIN dbo.VCT_CONSULTORES C WITH(NOLOCK) ON C.ID = D.ID_CONSULTOR
    WHERE D.ID_PROYECTO = @ID_PROYECTO
      AND (   (D.TIPO = 'MG' AND (D.NRO_INTERNO LIKE 'ITEM:%' OR D.NRO_INTERNO = 'LIBRE'))
           OR (D.TIPO = 'CONS' AND ISNULL(D.OBSERVACIONES,'') <> '' AND D.NRO_INTERNO IN ('INTERNA','CONSULTOR','CLIENTE'))
           OR (D.TIPO = 'RIESGO' AND ISNULL(D.OBSERVACIONES,'') <> '')
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
            @N_RI INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'RIESGO'), @L_RI BIT = 0,
            @N_RE INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'LANZ'),
            @N_IN INT = (SELECT COUNT(*) FROM #LZ WHERE TIPO = 'INICIO'),
            @DE_ABIERTA BIT = 0, @L_CO BIT = 0, @IN_OK BIT = 0, @IN_FALTA VARCHAR(500) = '', @RE_FECHA DATETIME;
    IF EXISTS (SELECT 1 FROM #A WHERE SUB_COD = 'CARGA_DATOS_ENTRADA' AND SIT <> 'C') SET @DE_ABIERTA = 1;
    IF @N_CO > 0 SET @L_CO = 1;
    IF @N_RI > 0 SET @L_RI = 1;
    SELECT TOP 1 @RE_FECHA = FECHA FROM #LZ WHERE TIPO = 'LANZ' AND CIERRE IS NOT NULL ORDER BY FECHA DESC;
    SET @IN_FALTA = CASE WHEN @L_CONS = 0 THEN ', consultor l&iacute;der' ELSE '' END
                  + CASE WHEN @L_DATOS = 0 THEN ', datos de entrada' ELSE '' END
                  + CASE WHEN @L_CO = 0 THEN ', consideraciones' ELSE '' END
                  + CASE WHEN @L_RI = 0 THEN ', riesgos' ELSE '' END
                  + CASE WHEN @L_REU = 0 THEN ', reuni&oacute;n de lanzamiento' ELSE '' END;
    IF @IN_FALTA = '' SET @IN_OK = 1
    ELSE SET @IN_FALTA = 'Falta: ' + SUBSTRING(@IN_FALTA, 3, 500);
    SET @L_OK = CONVERT(INT, @L_CONS) + CONVERT(INT, @L_DATOS) + CONVERT(INT, @L_CO) + CONVERT(INT, @L_RI) + CONVERT(INT, @L_REU);


    /* ---------- plan estrategico: datos (PV_PLAN_V1 / PL_ARBOL_V1) ----------
       Arbol: capitulo (GRUPO CAPITULO) > item > subitem. Sin capitulo: "Otros items".
       Avance del plan = promedio de todas las unidades (cada subitem, cada item sin subitems y las acciones propias
       de un item con subitems), cada unidad = acciones cumplidas / acciones (0 si no tiene; 100 con fin real). */
    DECLARE @PLN INT, @PLN_DOC VARCHAR(400) = '', @PLN_TIENE_CO BIT = 0, @PL_AV_ST INT, @PL_CANC_ST INT, @PL_CUMP_ST INT;
    SELECT TOP 1 @PLN = P.ID, @PLN_DOC = REPLACE(REPLACE(REPLACE(ISNULL(D.DESCRIPCION, ISNULL(D.CODIGO, '')),'&','&amp;'),'<','&lt;'),'>','&gt;')
    FROM dbo.VCT_PROYECTOS_PLANES P WITH(NOLOCK) LEFT JOIN dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK) ON D.ID = P.ID_DOCUMENTO
    WHERE P.ID_PROYECTO = @ID_PROYECTO ORDER BY P.VERSION DESC, P.ID DESC;
    IF EXISTS (SELECT 1 FROM #SV WHERE UPPER(LEFT(ISNULL(COD,''),2)) = 'CO') SET @PLN_TIENE_CO = 1;
    SELECT @PL_AV_ST = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE CODIGO = 'AVISO_VENCIMIENTO';
    SELECT @PL_CANC_ST = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CANCELADA';
    SELECT @PL_CUMP_ST = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';

    CREATE TABLE #PI (ID INT, PADRE INT, ORD INT, TIT VARCHAR(400), CODE VARCHAR(50), GRP VARCHAR(100), HITO BIT, NIV INT, CHAP INT, TOPI INT, HIJOS INT,
                      FI DATETIME, FF DATETIME, FR DATETIME, EST VARCHAR(20), RESP INT, RESP_INI VARCHAR(4), RESP_NOM VARCHAR(300), OBS VARCHAR(2000),
                      TOT INT, CUMP INT, VEN INT, AV INT, UNI INT, CAP VARCHAR(20), CAP_ORD INT, NAME VARCHAR(400), TH VARCHAR(1200), TA VARCHAR(1200),
                      HTML VARCHAR(MAX), DHTML VARCHAR(MAX));
    CREATE TABLE #PA (ID INT, ITEM INT, TOP_ITEM INT, TIT VARCHAR(300), SUB VARCHAR(150), VENCE DATETIME, INI DATETIME, CUMPLIDA BIT, FINAL BIT, SIT CHAR(1),
                      RESP_INI VARCHAR(4), RESP_NOM VARCHAR(300), RCLS VARCHAR(10), RCOD VARCHAR(30), RLIB VARCHAR(150), DET VARCHAR(300), DETF VARCHAR(2000),
                      TIPO INT, SUBT INT, PRIO INT, ESTI INT, RES INT, EST_DES VARCHAR(100), EST_COD VARCHAR(30), CIERRE DATETIME, HTML VARCHAR(MAX));
    IF @PLN IS NOT NULL
    BEGIN
        INSERT INTO #PI (ID, PADRE, ORD, TIT, CODE, GRP, HITO, FI, FF, FR, RESP, OBS)
        SELECT I.ID, I.ID_PADRE, ISNULL(I.ORDEN, 999), LTRIM(RTRIM(REPLACE(REPLACE(ISNULL(I.TITULO,''), CHAR(13), ' '), CHAR(10), ' '))),
               LTRIM(RTRIM(ISNULL(I.CODIGO_ITEM,''))), ISNULL(I.GRUPO,''), CASE WHEN I.GRUPO = 'HITO' THEN 1 ELSE 0 END,
               I.FECHA_INICIO, I.FECHA_VENCIMIENTO, I.FECHA_CIERRE, I.ID_RESPONSABLE_EQUIPO, ISNULL(I.OBSERVACIONES,'')
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK) WHERE I.ID_PLAN = @PLN;
        /* niveles: 1 capitulo, 2 item (sin padre o hijo de capitulo), 3 subitem */
        UPDATE #PI SET NIV = 1 WHERE GRP = 'CAPITULO';
        UPDATE X SET NIV = 2, CHAP = CASE WHEN P.NIV = 1 THEN P.ID END, TOPI = X.ID
        FROM #PI X LEFT JOIN #PI P ON P.ID = X.PADRE WHERE X.NIV IS NULL AND (X.PADRE IS NULL OR P.NIV = 1 OR P.ID IS NULL);
        UPDATE #PI SET NIV = 3 WHERE NIV IS NULL;
        DECLARE @PL_K INT = 0;
        WHILE @PL_K < 6 AND EXISTS (SELECT 1 FROM #PI WHERE NIV = 3 AND TOPI IS NULL)
        BEGIN
            UPDATE X SET TOPI = P.TOPI, CHAP = P.CHAP FROM #PI X INNER JOIN #PI P ON P.ID = X.PADRE WHERE X.NIV = 3 AND X.TOPI IS NULL AND P.TOPI IS NOT NULL;
            SET @PL_K = @PL_K + 1;
        END;
        UPDATE #PI SET TOPI = ID, NIV = 2 WHERE NIV = 3 AND TOPI IS NULL;
        UPDATE P SET HIJOS = (SELECT COUNT(*) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV > P.NIV) FROM #PI P;
        /* codigo y titulo: planes viejos traen el codigo dentro del titulo ("4.1 Comprension ...") */
        UPDATE #PI SET CODE = LEFT(TIT, PATINDEX('%[^0-9.]%', TIT + ' ') - 1) WHERE NIV > 1 AND CODE NOT LIKE '[0-9]%' AND TIT LIKE '[0-9]%';
        UPDATE #PI SET CODE = LEFT(CODE, LEN(CODE) - 1) WHERE RIGHT(CODE, 1) = '.' AND LEN(CODE) > 1;
        UPDATE #PI SET NAME = CASE WHEN CODE <> '' AND LEFT(TIT, LEN(CODE)) = CODE AND NIV > 1 THEN LTRIM(SUBSTRING(TIT, LEN(CODE) + 1, 400)) ELSE TIT END;
        UPDATE #PI SET NAME = CASE WHEN LEFT(NAME, 1) IN ('.','-') THEN LTRIM(SUBSTRING(NAME, 2, 400)) ELSE NAME END;
        UPDATE #PI SET CODE = '' WHERE NIV > 1 AND CODE NOT LIKE '[0-9]%';
        UPDATE #PI SET TH = REPLACE(REPLACE(REPLACE(NAME,'&','&amp;'),'<','&lt;'),'>','&gt;'),
                       TA = REPLACE(REPLACE(REPLACE(REPLACE(TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;');
        /* capitulo de cada nodo: clave y orden */
        UPDATE X SET CAP = CASE WHEN X.NIV = 1 THEN CONVERT(VARCHAR(20), X.ID) WHEN X.CHAP IS NULL THEN 'Z' ELSE CONVERT(VARCHAR(20), X.CHAP) END,
                     CAP_ORD = CASE WHEN X.NIV = 1 THEN X.ORD WHEN X.CHAP IS NULL THEN 999999 ELSE C.ORD END
        FROM #PI X LEFT JOIN #PI C ON C.ID = X.CHAP;
        UPDATE P SET RESP_INI = Q.INI, RESP_NOM = Q.NOMBRE FROM #PI P
        INNER JOIN dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK) ON EQ.ID = P.RESP
        INNER JOIN #EQ Q ON Q.TIPO = EQ.TIPO_MIEMBRO AND Q.ID_ENT = CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END;

        /* acciones de los items (sin canceladas ni avisos de vencimiento); responsable: equipo, cliente u otro (texto) */
        INSERT INTO #PA (ID, ITEM, TIT, SUB, VENCE, INI, CUMPLIDA, FINAL, RESP_INI, RESP_NOM, RCLS, RCOD, RLIB, DET, DETF, TIPO, SUBT, PRIO, ESTI, RES, EST_DES, EST_COD, CIERRE)
        SELECT A.ID, A.ID_PLAN_ITEM, ISNULL(A.TITULO,''), ISNULL(ST.DESCRIPCION,''), A.FECHA_VENCIMIENTO, A.FECHA_INICIO,
               CASE WHEN A.ID_ESTADO = @PL_CUMP_ST THEN 1 ELSE 0 END, ISNULL(E.ES_FINAL, 0), ISNULL(RP.INI,''), ISNULL(RP.NOM,''), ISNULL(RP.CLS,''), ISNULL(RP.COD,''), ISNULL(RP.LIB,''),
               LEFT(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(400), A.DESCRIPCION),''), CHAR(13), ' '), CHAR(10), ' '), 300), LEFT(ISNULL(CONVERT(VARCHAR(2000), A.DESCRIPCION),''), 2000),
               A.ID_TIPO, A.ID_SUBTIPO, A.ID_PRIORIDAD, A.ID_ESTADO, A.ID_RESULTADO, ISNULL(E.DESCRIPCION,''), ISNULL(E.CODIGO,''), A.FECHA_CIERRE
        FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
        LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO
        OUTER APPLY (SELECT TOP 1 X.INI, X.NOM, X.CLS, X.COD, X.LIB FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
                     CROSS APPLY (
                         SELECT TOP 1 Q.INI, Q.NOMBRE AS NOM, CASE WHEN Q.TIPO = 'EMPLEADO' THEN 'is-a' ELSE 'is-c' END AS CLS, 'EQ:' + CONVERT(VARCHAR(20), Q.ID) AS COD, '' AS LIB
                         FROM #EQ Q WHERE AP.TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR') AND Q.TIPO = AP.TIPO_ENTIDAD AND Q.ID_ENT = AP.ID_ENTIDAD
                         UNION ALL
                         SELECT TOP 1 UPPER(LEFT(LTRIM(ISNULL(C.RAZON_SOCIAL,'')), 1) + CASE WHEN CHARINDEX(' ', LTRIM(RTRIM(ISNULL(C.RAZON_SOCIAL,'')))) > 0 THEN SUBSTRING(LTRIM(RTRIM(C.RAZON_SOCIAL)), CHARINDEX(' ', LTRIM(RTRIM(C.RAZON_SOCIAL))) + 1, 1) ELSE '' END),
                                ISNULL(C.RAZON_SOCIAL,'') + ' (cliente)', 'is-cl', 'CLI', ''
                         FROM dbo.VCT_CLIENTES C WITH(NOLOCK) WHERE AP.TIPO_ENTIDAD = 'CLIENTE' AND C.ID = AP.ID_ENTIDAD
                         UNION ALL
                         SELECT UPPER(LEFT(LTRIM(ISNULL(AP.NOMBRE_LIBRE,'')), 1) + CASE WHEN CHARINDEX(' ', LTRIM(RTRIM(ISNULL(AP.NOMBRE_LIBRE,'')))) > 0 THEN SUBSTRING(LTRIM(RTRIM(AP.NOMBRE_LIBRE)), CHARINDEX(' ', LTRIM(RTRIM(AP.NOMBRE_LIBRE))) + 1, 1) ELSE '' END),
                                ISNULL(AP.NOMBRE_LIBRE,''), 'is-x', 'OTRO', ISNULL(AP.NOMBRE_LIBRE,'')
                         WHERE AP.TIPO_ENTIDAD = 'OTRO') X
                     WHERE AP.ID_ACCION = A.ID AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO' ORDER BY AP.PRINCIPAL DESC, AP.ID DESC) RP
        WHERE A.ID_PLAN_ITEM IN (SELECT ID FROM #PI WHERE NIV > 1) AND A.ID_ESTADO <> ISNULL(@PL_CANC_ST, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@PL_AV_ST, -1);
        UPDATE A SET TOP_ITEM = P.TOPI,
                     SIT = CASE WHEN A.FINAL = 1 THEN 'C' WHEN A.VENCE IS NOT NULL AND CONVERT(DATE, A.VENCE) < @HOY THEN 'V' ELSE 'A' END
        FROM #PA A INNER JOIN #PI P ON P.ID = A.ITEM;

        /* acciones propias de cada nodo y avance */
        UPDATE P SET TOT = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID), 0),
                     CUMP = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.CUMPLIDA = 1), 0),
                     VEN = ISNULL((SELECT COUNT(*) FROM #PA A WHERE A.ITEM = P.ID AND A.SIT = 'V'), 0)
        FROM #PI P;
        /* unidad de avance de cada nodo (item / subitem): acciones propias; sin acciones 0; con fin real 100 */
        UPDATE #PI SET AV = CASE WHEN FR IS NOT NULL THEN 100 WHEN TOT > 0 THEN CONVERT(INT, ROUND(100.0 * CUMP / TOT, 0)) ELSE 0 END WHERE NIV > 1;
        /* item con subitems: promedio de sus subitems (+ sus acciones propias si tiene) */
        UPDATE P SET AV = CASE WHEN P.FR IS NOT NULL THEN 100 ELSE
                     CONVERT(INT, ROUND((ISNULL((SELECT SUM(S.AV) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0) + CASE WHEN P.TOT > 0 THEN 100.0 * P.CUMP / P.TOT ELSE 0 END) * 1.0
                                        / (P.HIJOS + CASE WHEN P.TOT > 0 THEN 1 ELSE 0 END), 0)) END,
                     UNI = P.HIJOS + CASE WHEN P.TOT > 0 THEN 1 ELSE 0 END
        FROM #PI P WHERE P.NIV = 2 AND P.HIJOS > 0;
        UPDATE #PI SET UNI = 1 WHERE NIV > 1 AND UNI IS NULL;
        /* totales del item (con sus subitems) y del capitulo */
        UPDATE P SET TOT = P.TOT + ISNULL((SELECT SUM(S.TOT) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0),
                     CUMP = P.CUMP + ISNULL((SELECT SUM(S.CUMP) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0),
                     VEN = P.VEN + ISNULL((SELECT SUM(S.VEN) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0)
        FROM #PI P WHERE P.NIV = 2 AND P.HIJOS > 0;
        /* estado: fechas del item (los subitems heredan) */
        UPDATE P SET EST = CASE WHEN P.FR IS NOT NULL THEN 'CUMPLIDO'
                                WHEN P.NIV > 1 AND P.AV = 100 AND P.TOT > 0 THEN 'CUMPLIDO'
                                WHEN T.FF IS NOT NULL AND CONVERT(DATE, T.FF) < @HOY THEN 'VENCIDO'
                                WHEN T.FI IS NOT NULL AND CONVERT(DATE, T.FI) <= @HOY THEN 'EN_CURSO'
                                ELSE 'PENDIENTE' END
        FROM #PI P INNER JOIN #PI T ON T.ID = ISNULL(P.TOPI, P.ID);
    END;
    /* unidades del avance: subitems + items sin subitems + acciones propias de items con subitems */
    DECLARE @PL_TOT INT = (SELECT COUNT(*) FROM #PA), @PL_OK INT = (SELECT COUNT(*) FROM #PA WHERE CUMPLIDA = 1),
            @PL_NI INT = (SELECT COUNT(*) FROM #PI WHERE NIV = 2), @PL_PCT INT = 0, @PL_NU INT = 0,
            @PL_C INT = (SELECT COUNT(*) FROM #PI WHERE NIV = 2 AND EST = 'CUMPLIDO'),
            @PL_E INT = (SELECT COUNT(*) FROM #PI WHERE NIV = 2 AND EST = 'EN_CURSO'),
            @PL_P INT = (SELECT COUNT(*) FROM #PI WHERE NIV = 2 AND EST = 'PENDIENTE'),
            @PL_V INT = (SELECT COUNT(*) FROM #PI WHERE NIV = 2 AND EST = 'VENCIDO');
    DECLARE @PL_SUMA NUMERIC(18,4) = 0;
    SELECT @PL_NU = COUNT(*), @PL_SUMA = ISNULL(SUM(CONVERT(NUMERIC(18,4), U.V)), 0) FROM (
        SELECT AV AS V FROM #PI WHERE NIV = 3
        UNION ALL SELECT AV FROM #PI WHERE NIV = 2 AND HIJOS = 0
        UNION ALL SELECT CASE WHEN FR IS NOT NULL THEN 100 ELSE 100.0 * CUMP / NULLIF(TOT, 0) END FROM (
            SELECT P.FR, P.TOT - ISNULL((SELECT SUM(S.TOT) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0) AS TOT,
                   P.CUMP - ISNULL((SELECT SUM(S.CUMP) FROM #PI S WHERE S.PADRE = P.ID AND S.NIV = 3), 0) AS CUMP
            FROM #PI P WHERE P.NIV = 2 AND P.HIJOS > 0) Y WHERE Y.TOT > 0
    ) U;
    IF @PL_NU > 0 SET @PL_PCT = CONVERT(INT, ROUND(@PL_SUMA / @PL_NU, 0));
    /* capitulo: promedio de sus unidades */
    UPDATE C SET AV = ISNULL((SELECT CONVERT(INT, ROUND(SUM(CONVERT(NUMERIC(18,4), X.AV * X.UNI)) / NULLIF(SUM(X.UNI), 0), 0)) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID), 0),
                 TOT = ISNULL((SELECT SUM(X.TOT) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID), 0),
                 CUMP = ISNULL((SELECT SUM(X.CUMP) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID), 0),
                 VEN = ISNULL((SELECT SUM(X.VEN) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID), 0),
                 FI = (SELECT MIN(X.FI) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID),
                 FF = (SELECT MAX(X.FF) FROM #PI X WHERE X.NIV = 2 AND X.CHAP = C.ID)
    FROM #PI C WHERE C.NIV = 1;

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
        WHEN @ERR <> '' THEN '<div class="vct-pv-alert is-error" data-vct-pv-alert><span class="vct-pv-ic-pulse"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg></span><span>' + REPLACE(REPLACE(@ERR,'<','&lt;'),'>','&gt;') + '</span></div>'
        WHEN @MSG <> '' THEN '<div class="vct-pv-alert is-ok" data-vct-pv-alert><span data-vct-icon="check"></span><span>' + REPLACE(REPLACE(@MSG,'<','&lt;'),'>','&gt;') + '</span></div>'
        ELSE '' END;

    /* pendientes del usuario en este proyecto: van en la campanita del encabezado (PV_BELL_V1) */
    DECLARE @PEND VARCHAR(MAX) = '';
    SELECT @PEND = ISNULL((
        SELECT
            '<li class="vct-pv-bell-item' + CASE WHEN SIT = 'V' THEN ' is-late' ELSE '' END + '">'
          + '<span class="vct-pv-bell-item-icon">' + CASE WHEN SIT = 'V' THEN '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>' ELSE '<span data-vct-icon="user-check"></span>' END + '</span>'   /* alert-triangle no existe en el set de iconos */
          + '<span class="vct-pv-bell-item-main"><span class="vct-pv-bell-item-title">' + REPLACE(REPLACE(REPLACE(TITULO,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
          + '<span class="vct-pv-bell-item-meta">' + REPLACE(REPLACE(REPLACE(SUB_DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
          + CASE WHEN VENCE IS NULL THEN '' WHEN SIT = 'V' THEN '<span class="vct-pv-bell-item-date">Venci&oacute; el ' + CONVERT(VARCHAR(10), VENCE, 103) + '</span>'
                 ELSE '<span class="vct-pv-bell-item-date">Vence el ' + CONVERT(VARCHAR(10), VENCE, 103) + '</span>' END + '</span>'
          + '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-bell-go '
          + CASE WHEN SUB_COD = 'ASIGNACION_CONSULTOR' AND @PUEDE_ASIG = 1 THEN @GEST_ASIG
                 WHEN SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') THEN 'data-vct-pv-goto="lanzamiento"'
                 WHEN SUB_COD IN ('CARGA_PLAN','TRABAJO_PLAN_ITEM') THEN 'data-vct-pv-goto="plan" data-vct-pv-plan="co"'
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
        SELECT '<span class="vct-pv-hd-svc" title="' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'"',''),'<','')
             + CASE WHEN N > 1 THEN ' &middot; ' + CONVERT(VARCHAR(10), N) ELSE '' END + ' &middot; ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h">'
             + '<span class="vctdg-svc is-' + LOWER(CASE WHEN T = '' THEN 'xx' ELSE T END) + ' is-on"><span data-vct-icon="' + ICO + '"></span></span>'
             + CASE WHEN N > 1 THEN '<b>' + CONVERT(VARCHAR(10), N) + '</b>' ELSE '' END + '</span>'
        FROM #SVT ORDER BY ORD FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
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
               THEN '<div class="vct-360-stat" data-vct-tone="mint"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Lanzamiento</span><b>' + CONVERT(VARCHAR(5), @L_OK) + ' / 5</b><small>pasos completos</small></span><span class="vct-360-stat-icon"><span data-vct-icon="check"></span></span></div>'
               ELSE '<div class="vct-360-stat" data-vct-tone="mint"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Avance horas</span><b>' + CONVERT(VARCHAR(5), @PCT_H) + '%</b><small>' + CONVERT(VARCHAR(20), CONVERT(INT, @H_DISP)) + ' h disponibles</small></span><span class="vct-360-stat-icon"><span data-vct-icon="chart-bar"></span></span></div>' END
        + '<div class="vct-360-stat" data-vct-tone="violet"><span class="vct-360-stat-main"><span class="vct-360-stat-label">Plan estrat&eacute;gico</span>'
        + CASE WHEN @PLN IS NULL THEN '<b>&ndash;</b><small>' + CASE WHEN @EST_COD = 'ENCURSO' THEN 'plan sin generar' ELSE 'se genera al iniciar' END + '</small>'
               ELSE '<b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b><small>sobre ' + CONVERT(VARCHAR(10), @PL_NU) + ' &iacute;tems y sub&iacute;tems</small>' END
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
        /* PV_PLAN_TAB_V1: la pestania del plan arranca deshabilitada; se habilita desde Servicios (Ver plan) o con Gestionar */
        + '<button type="button" data-vct-tab="plan" class="is-off" aria-disabled="true" data-vct-pv-plantab title="Se habilita desde Servicios (&#8942; &rarr; Ver plan) o con Gestionar en una acci&oacute;n del plan."><span data-vct-icon="list-checks"></span><span data-vct-pv-plantab-lbl>Plan</span>' + CASE WHEN @PL_NI > 0 THEN '<span data-vct-pv-plantab-cnt class="vct-tab-count' + CASE WHEN @PL_V > 0 THEN ' is-alert' ELSE '' END + '">' + CONVERT(VARCHAR(10), @PL_NI) + '</span>' ELSE '' END + '</button>'
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
        SELECT '<div class="vct-pv-rs-hs"><span class="vctdg-svc is-' + LOWER(CASE WHEN T = '' THEN 'xx' ELSE T END) + ' is-on"><span data-vct-icon="' + ICO + '"></span></span>'
             + '<b>' + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + CASE WHEN N > 1 THEN ' <span class="vct-pv-rs-mut">(' + CONVERT(VARCHAR(10), N) + ')</span>' ELSE '' END + '</b>'
             + '<span>' + CONVERT(VARCHAR(20), CONVERT(INT, EJEC)) + ' + ' + CONVERT(VARCHAR(20), CONVERT(INT, PROG)) + ' / ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h</span>'
             + '<span class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN EJEC * 100.0 / PROY > 100 THEN 100 ELSE EJEC * 100.0 / PROY END) ELSE 0 END) + '%"></span>'
             + '<span class="is-prog" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN PROG * 100.0 / PROY > 100 THEN 100 ELSE PROG * 100.0 / PROY END) ELSE 0 END) + '%"></span></span></div>'
        FROM #SVT ORDER BY ORD FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
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
        +   '<div><span>Plan estrat&eacute;gico (sobre el total de &iacute;tems)</span><b>' + CASE WHEN @PLN IS NULL THEN '&ndash;' ELSE CONVERT(VARCHAR(5), @PL_PCT) + '%' END + '</b><span class="vct-pv-bar"><span class="is-plan" style="width:' + CASE WHEN @PLN IS NULL THEN '0' ELSE CONVERT(VARCHAR(5), @PL_PCT) END + '%"></span></span></div>'
        +   '<div><span>Horas ejecutadas</span><b>' + CONVERT(VARCHAR(5), @PCT_H) + '%</b><span class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(5), @PCT_H) + '%"></span></span></div>'
        + '</div>'
        + '<div class="vct-pv-rs-msg ' + @R_MSG_A_CLS + '"><span class="vct-pv-ic-pulse"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg></span><span>' + @R_MSG_A + '</span></div>'
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

    /* servicios que se pueden agregar (PV_SV_GRUPOS_V1): Auditoria y Capacitacion siempre (pueden ser N);
       Consultoria solo en el alta. En el selector, las que no se pueden agregar quedan solo para mostrar al editar. */
    DECLARE @SV_OPT VARCHAR(MAX) = '', @SV_ID_AU INT, @SV_ID_CA INT;
    SELECT TOP 1 @SV_ID_AU = ID FROM dbo.VCT_PRM_SERVICIOS WITH(NOLOCK) WHERE ISNULL(ESTADO,'ACTIVO') = 'ACTIVO' AND LEFT(UPPER(ISNULL(CODIGO,'')), 2) = 'AU' ORDER BY ID;
    SELECT TOP 1 @SV_ID_CA = ID FROM dbo.VCT_PRM_SERVICIOS WITH(NOLOCK) WHERE ISNULL(ESTADO,'ACTIVO') = 'ACTIVO' AND LEFT(UPPER(ISNULL(CODIGO,'')), 2) = 'CA' ORDER BY ID;
    SELECT @SV_OPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), PS.ID) + '"'
             + CASE WHEN ISNULL(PS.ESTADO,'ACTIVO') = 'ACTIVO' AND LEFT(UPPER(ISNULL(PS.CODIGO,'')), 2) IN ('AU','CA') THEN '' ELSE ' data-used="1"' END + '>'
             + REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM dbo.VCT_PRM_SERVICIOS PS WITH(NOLOCK)
        WHERE (ISNULL(PS.ESTADO,'ACTIVO') = 'ACTIVO' AND LEFT(UPPER(ISNULL(PS.CODIGO,'')), 2) IN ('AU','CA'))
           OR EXISTS (SELECT 1 FROM #SV S WHERE S.ID_SERVICIO = PS.ID)
        ORDER BY PS.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* ---------- servicios: grilla unica agrupada por tipo (PV_SV_GRILLA_V1) ----------
       Una fila de grupo por tipo (Consultoria / Auditorias / Capacitaciones) con totales y una fila por instancia.
       Las normas se asignan al proyecto: no van en la grilla. Menu de cada fila: Editar (con permiso) y Ver plan. */
    DECLARE @SVG VARCHAR(MAX) = '', @SVG_T VARCHAR(2), @SVG_H VARCHAR(MAX), @SVG_N INT = (SELECT COUNT(*) FROM #SV);
    DECLARE @SVG_TT TABLE (T VARCHAR(2), ORD INT);
    INSERT INTO @SVG_TT (T, ORD) SELECT T, ORD FROM #SVT;
    WHILE EXISTS (SELECT 1 FROM @SVG_TT)
    BEGIN
        SELECT TOP 1 @SVG_T = T FROM @SVG_TT ORDER BY ORD, T;
        DELETE FROM @SVG_TT WHERE T = @SVG_T;
        /* fila de grupo */
        SELECT @SVG_H = '<tr class="vct-pv-svt-g is-open" data-vct-pv-svg="' + LOWER(@SVG_T) + '"><td colspan="8"><div class="vct-pv-svt-gh">'
             + '<span class="vct-pv-svt-chev"><span data-vct-icon="chevron-right"></span></span>'
             + '<span class="vctdg-svc is-' + LOWER(CASE WHEN T = '' THEN 'xx' ELSE T END) + ' is-on"><span data-vct-icon="' + ICO + '"></span></span>'
             + '<b>' + CASE T WHEN 'CO' THEN 'Consultor&iacute;a' WHEN 'AU' THEN 'Auditor&iacute;as' WHEN 'CA' THEN 'Capacitaciones'
                              ELSE REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') END + ' (' + CONVERT(VARCHAR(10), N) + ')</b>'
             + '<small>' + CONVERT(VARCHAR(20), CONVERT(INT, EJEC)) + ' / ' + CONVERT(VARCHAR(20), CONVERT(INT, PROY)) + ' h ejecutadas'
             + CASE WHEN PROG > 0 THEN ' &middot; ' + CONVERT(VARCHAR(20), CONVERT(INT, PROG)) + ' h programadas' ELSE '' END + '</small>'
             + '<span class="vct-pv-bar"><span class="is-ejec" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN EJEC * 100.0 / PROY > 100 THEN 100 ELSE EJEC * 100.0 / PROY END) ELSE 0 END) + '%"></span>'
             + '<span class="is-prog" style="width:' + CONVERT(VARCHAR(10), CASE WHEN PROY > 0 THEN CONVERT(INT, CASE WHEN PROG * 100.0 / PROY > 100 THEN 100 ELSE PROG * 100.0 / PROY END) ELSE 0 END) + '%"></span></span>'
             + '</div></td></tr>'
        FROM #SVT WHERE T = @SVG_T;
        /* filas de las instancias */
        SELECT @SVG_H = ISNULL(@SVG_H, '') + ISNULL((
            SELECT '<tr class="vct-pv-svt-row" data-vct-pv-svrow="' + LOWER(@SVG_T) + '" data-q="'
                 + LOWER(REPLACE(REPLACE(REPLACE(REPLACE(S.NOMBRE + ' ' + S.DES + ' ' + S.LUGAR,'&','&amp;'),'"',''),'<',''),'>','')) + '">'
                 /* servicio */
                 + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(CASE WHEN S.NOMBRE <> '' THEN S.NOMBRE WHEN @SVG_T = 'CO' THEN S.DES ELSE S.DES + ' ' + CONVERT(VARCHAR(10), S.ORDEN) END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
                 + CASE WHEN S.LUGAR <> '' THEN '<span class="vct-360-project-ref" title="' + REPLACE(REPLACE(REPLACE(S.LUGAR,'&','&amp;'),'"',''),'<','') + '">' + REPLACE(REPLACE(REPLACE(S.LUGAR,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '' END + '</td>'
                 /* fecha (o rango) */
                 + '<td class="vct-text-center">' + ISNULL(CONVERT(VARCHAR(10), S.INI, 103), '-')
                 + CASE WHEN S.FIN IS NOT NULL AND (S.INI IS NULL OR CONVERT(DATE, S.FIN) <> CONVERT(DATE, S.INI)) THEN '<span class="vct-360-project-ref">al ' + CONVERT(VARCHAR(10), S.FIN, 103) + '</span>' ELSE '' END + '</td>'
                 /* equipo de la instancia (la consultoria suma el equipo general del proyecto) */
                 + '<td class="vct-text-center"><span class="vct-pv-sv-eq">' + ISNULL(NULLIF((
                       SELECT TOP 4 '<span class="vctdg-avatar ' + CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN 'is-a' ELSE 'is-c' END + '" title="' + REPLACE(REPLACE(X.NOM,'"',''),'<','') + ISNULL(' &middot; ' + REPLACE(REPLACE(R.DESCRIPCION,'"',''),'<',''), '') + '">' + X.INI + '</span>'
                       FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                       LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL
                       CROSS APPLY (
                           SELECT TOP 1 LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,''))) AS NOM, UPPER(LEFT(ISNULL(E.NOMBRES,''),1) + LEFT(ISNULL(E.APELLIDOS,''),1)) AS INI
                           FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK) WHERE EQ.TIPO_MIEMBRO = 'EMPLEADO' AND E.ID = EQ.ID_EMPLEADO
                           UNION ALL
                           SELECT TOP 1 LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),
                                  UPPER(LEFT(ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''),1) + LEFT(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),''),1))
                           FROM dbo.VCT_CONSULTORES C WITH(NOLOCK) WHERE EQ.TIPO_MIEMBRO = 'CONSULTOR' AND C.ID = EQ.ID_CONSULTOR) X
                       WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO'
                         AND (EQ.ID_PROYECTO_SERVICIO = S.ID OR (@SVG_T = 'CO' AND EQ.ID_PROYECTO_SERVICIO IS NULL))
                       ORDER BY EQ.PRINCIPAL DESC, EQ.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''), '<span class="vctdg-none">-</span>')
                 + ISNULL((SELECT '<span class="vct-pv-sv-eqmas">+' + CONVERT(VARCHAR(10), COUNT(*) - 4) + '</span>'
                           FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                           WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO'
                             AND (EQ.ID_PROYECTO_SERVICIO = S.ID OR (@SVG_T = 'CO' AND EQ.ID_PROYECTO_SERVICIO IS NULL))
                           HAVING COUNT(*) > 4), '') + '</span></td>'
                 /* horas */
                 + '<td class="vct-text-right" title="Programadas ' + CONVERT(VARCHAR(20), CONVERT(INT, S.PROG)) + ' h &middot; Disponibles ' + CONVERT(VARCHAR(20), CONVERT(INT, S.PROY - S.PROG - S.EJEC)) + ' h">'
                 + CONVERT(VARCHAR(20), CONVERT(INT, S.EJEC)) + ' / ' + CONVERT(VARCHAR(20), CONVERT(INT, S.PROY)) + ' h</td>'
                 + '<td><span class="vctdg-progress"><span class="vctdg-progress-bar"><i style="width:'
                 + CONVERT(VARCHAR(10), CASE WHEN S.PROY > 0 THEN CONVERT(INT, CASE WHEN S.EJEC * 100.0 / S.PROY > 100 THEN 100 ELSE S.EJEC * 100.0 / S.PROY END) ELSE 0 END) + '%"></i></span><b>'
                 + CONVERT(VARCHAR(10), CASE WHEN S.PROY > 0 THEN CONVERT(INT, S.EJEC * 100.0 / S.PROY) ELSE 0 END) + '%</b></span></td>'
                 /* plan: hoy solo existe el plan estrategico de la consultoria */
                 + '<td>' + CASE WHEN @SVG_T = 'CO' AND @PLN IS NOT NULL
                                 THEN '<span class="vct-pv-svt-plan"><span class="vct-pv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(5), @PL_PCT) + '%"></span></span><b>' + CONVERT(VARCHAR(5), @PL_PCT) + '%</b></span>'
                                 ELSE '<span class="vctdg-none">Sin plan</span>' END + '</td>'
                 /* estado */
                 + '<td class="vct-text-center"><span class="vct-360-badge ' + CASE S.EST_COD WHEN 'ENCURSO' THEN 'is-active' WHEN 'CONFIRMADO' THEN 'is-planned' WHEN 'CANCELADO' THEN 'is-cancel' ELSE 'is-neutral' END + '">'
                 + REPLACE(REPLACE(ISNULL(S.EST_DES, ISNULL(S.EST_COD,'-')),'<','&lt;'),'>','&gt;') + '</span></td>'
                 /* menu: Editar + Ver plan */
                 + '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                 + '<div class="vctdg-rowmenu-items" hidden>'
                 + CASE WHEN @PUEDE_EDIT = 1 THEN
                        '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="sv" data-id="' + CONVERT(VARCHAR(20), S.ID) + '"'
                      + ' data-f-srv="' + CONVERT(VARCHAR(20), S.ID_SERVICIO) + '" data-f-nom="' + REPLACE(REPLACE(REPLACE(REPLACE(S.NOMBRE,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                      + ' data-f-lugar="' + REPLACE(REPLACE(REPLACE(REPLACE(S.LUGAR,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                      + ' data-f-ini="' + ISNULL(CONVERT(VARCHAR(10), S.INI, 120),'') + '" data-f-fin="' + ISNULL(CONVERT(VARCHAR(10), S.FIN, 120),'') + '" data-f-hrs="' + CONVERT(VARCHAR(20), CONVERT(INT, S.PROY)) + '">'
                      + '<span data-vct-icon="edit"></span><span>Editar</span></button>'
                   ELSE '' END
                 + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-verplan="' + LOWER(@SVG_T) + '" data-id="' + CONVERT(VARCHAR(20), S.ID) + '"'
                 + ' data-nombre="' + REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN S.NOMBRE <> '' THEN S.NOMBRE WHEN @SVG_T = 'CO' THEN S.DES ELSE S.DES + ' ' + CONVERT(VARCHAR(10), S.ORDEN) END,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                 + ' data-lugar="' + REPLACE(REPLACE(REPLACE(REPLACE(S.LUGAR,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">'
                 + '<span data-vct-icon="list-checks"></span><span>Ver ' + CASE @SVG_T WHEN 'CO' THEN 'plan estrat&eacute;gico' WHEN 'AU' THEN 'plan de auditor&iacute;a' WHEN 'CA' THEN 'plan de capacitaci&oacute;n' ELSE 'plan' END + '</span></button>'
                 + '</div></td></tr>'
            FROM #SV S WHERE LEFT(S.COD, 2) = @SVG_T
            ORDER BY S.INI, S.ORDEN, S.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        /* paginado de auditorias / capacitaciones con mas de 10 instancias (el JS arma la botonera) */
        IF @SVG_T <> 'CO' AND (SELECT COUNT(*) FROM #SV WHERE LEFT(COD, 2) = @SVG_T) > 10
            SET @SVG_H = ISNULL(@SVG_H, '') + '<tr class="vct-pv-svt-pg" data-vct-pv-svpg="' + LOWER(@SVG_T) + '" data-unit="'
                       + CASE @SVG_T WHEN 'AU' THEN 'auditor&iacute;a(s)' WHEN 'CA' THEN 'capacitaci&oacute;n(es)' ELSE 'servicio(s)' END + '"><td colspan="8">'
                       + '<div class="vctdg"><div class="vctdg-footer"><div class="vctdg-info" data-vct-pv-svinfo></div><nav class="vctdg-pager" aria-label="Paginaci&oacute;n"></nav><span></span></div></div></td></tr>';
        SET @SVG = @SVG + ISNULL(@SVG_H, '');
    END;

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
        /* servicios: grilla unica agrupada por tipo (PV_SV_GRILLA_V1) */
        + '<div class="vct-360-panel" data-vct-panel="servicios">'
        + '<div class="vct-360-box vct-pv-svt-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="briefcase"></span></span>Servicios del proyecto (' + CONVERT(VARCHAR(10), @SVG_N) + ')</h3></div>'
        + '<div class="vctdg vct-pv-svt-tools"><div class="vctdg-toolbar"><div class="vctdg-filters"><div class="vctdg-search"><span data-vct-icon="search"></span>'
        +   '<input type="search" placeholder="Buscar servicio o lugar..." data-vct-pv-svbuscar autocomplete="off"></div></div>'
        +   CASE WHEN @PUEDE_EDIT = 1 AND (@SV_ID_AU IS NOT NULL OR @SV_ID_CA IS NOT NULL)
                 THEN '<div class="vctdg-tools"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="sv"><span data-vct-icon="plus"></span><span>Agregar servicio</span></button></div>' ELSE '' END
        + '</div></div>'
        + CASE WHEN @SVG = '' THEN '<div class="vct-360-empty">Sin servicios.</div>' ELSE
            '<div class="vct-pv-svt-wrap"><table class="vct-pv-svt"><colgroup><col><col style="width:112px"><col style="width:120px"><col style="width:104px"><col style="width:13%"><col style="width:13%"><col style="width:118px"><col style="width:48px"></colgroup>'
          + '<thead><tr><th>Servicio</th><th class="vct-text-center">Fecha</th><th class="vct-text-center">Equipo</th><th class="vct-text-right">Horas</th><th>Avance horas</th><th>Plan</th><th class="vct-text-center">Estado</th><th></th></tr></thead>'
          + '<tbody>' + @SVG + '<tr data-vct-pv-svnores hidden><td colspan="8"><div class="vct-360-empty">No hay servicios que coincidan con la b&uacute;squeda.</div></td></tr></tbody></table></div>' END
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
    DECLARE @LZ_DE VARCHAR(MAX) = '', @LZ_CO VARCHAR(MAX) = '', @LZ_RI VARCHAR(MAX) = '', @LZ_RE VARCHAR(MAX) = '', @LZ_IN VARCHAR(MAX) = '', @LZ_OPT VARCHAR(MAX) = '', @LZ_COPT VARCHAR(MAX) = '';
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
             + REPLACE(REPLACE(REPLACE(DES,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'   /* solo la descripcion (PV_DE_MINUTA_CO_V1) */
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

    /* riesgos (PV_LZ_RIESGOS_V1) */
    SELECT @LZ_RI = ISNULL((
        SELECT '<tr data-vct-row>'
             + '<td class="vct-text-center"><span class="vct-360-badge vct-pv-riesgo ' + CASE UPPER(NRO) WHEN 'ALTO' THEN 'is-alto' WHEN 'MEDIO' THEN 'is-medio' WHEN 'BAJO' THEN 'is-bajo' ELSE 'is-neutral' END + '">'
             + REPLACE(REPLACE(REPLACE(NRO,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
             + '<td class="vct-pv-pre">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + REPLACE(REPLACE(USR,'<',''),'>','') + '</td>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FUPD, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FUPD, 103),'-') + '</td>'
             + CASE WHEN @PUEDE_RI = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="ri" data-id="' + CONVERT(VARCHAR(20), ID) + '" data-f-nivel="' + REPLACE(REPLACE(REPLACE(REPLACE(NRO,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-texto="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Eliminar" data-vct-pv-confirm="PV_RI_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Eliminar riesgo" data-msg="Se elimina el riesgo: ' + REPLACE(REPLACE(REPLACE(REPLACE(LEFT(OBS,150),'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '. El nivel de riesgo del proyecto no cambia.">' + @I_DEL + '</button></div></td>'
               ELSE '' END + '</tr>'
        FROM #LZ WHERE TIPO = 'RIESGO' ORDER BY FUPD DESC, ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SELECT @LZ_RE = ISNULL((
        SELECT '<tr data-vct-row>'
             + '<td class="vct-text-center" data-vct-sort-value="' + ISNULL(CONVERT(VARCHAR(8), FECHA, 112),'') + '">' + ISNULL(CONVERT(VARCHAR(10), FECHA, 103),'-') + '</td>'
             + '<td>' + REPLACE(REPLACE(REPLACE(PART,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-pv-pre"><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + CASE WHEN OBS <> '' THEN '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '' END + '</td>'
             + '<td>' + REPLACE(REPLACE(REPLACE(CONS_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</td>'
             + '<td class="vct-text-center">' + CASE WHEN CIERRE IS NOT NULL THEN '<span class="vct-360-badge is-active">Lanzamiento</span>' ELSE '<span class="vct-360-badge is-neutral">Reuni&oacute;n</span>' END + '</td>'
             + CASE WHEN @PUEDE_LANZ = 1 THEN '<td class="vct-col-action"><button type="button" class="vct-row-menu-trigger" data-vctdg-rowmenu aria-label="Acciones" title="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button><div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Editar" data-vct-pv-edit="re" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-f-fecha="' + ISNULL(CONVERT(VARCHAR(10), FECHA, 120),'') + '" data-f-cons="' + ISNULL(CONVERT(VARCHAR(20), ID_CONS),'') + '"'
                  + ' data-f-realizada="' + CASE WHEN CIERRE IS NOT NULL THEN '1' ELSE '0' END + '"'
                  + ' data-f-part="' + REPLACE(REPLACE(REPLACE(REPLACE(PART,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-temas="' + REPLACE(REPLACE(REPLACE(REPLACE(TEMAS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                  + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + @I_EDIT + '</button>'
                  + '<button type="button" class="vct-pv-menu-btn" title="Eliminar" data-vct-pv-confirm="PV_RE_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-titulo="Eliminar reuni&oacute;n" data-msg="Se elimina la reuni&oacute;n del ' + ISNULL(CONVERT(VARCHAR(10), FECHA, 103),'') + '.'
                  + CASE WHEN CIERRE IS NOT NULL THEN ' Es la reuni&oacute;n de lanzamiento: la acci&oacute;n Reuni&oacute;n de lanzamiento vuelve a pendiente.' ELSE '' END
                  + '">' + @I_DEL + '</button></div></td>'
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

    DECLARE @TH_ACC VARCHAR(200) = CASE WHEN @PUEDE_LANZ = 1 THEN '<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>' ELSE '' END,
            @TH_ACC_RI VARCHAR(200) = CASE WHEN @PUEDE_RI = 1 THEN '<th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th>' ELSE '' END,
            @E_RI_ACT VARCHAR(60) = CASE UPPER(ISNULL(@RIESGO,'')) WHEN 'BAJO' THEN 'Bajo' WHEN 'MEDIO' THEN 'Medio' WHEN 'ALTO' THEN 'Alto' ELSE '' END;
    DECLARE @DG_ATTR VARCHAR(300) = ' data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-page-size="10" data-vct-dg-density="compact" data-vct-dg-layout="fixed"';

    SET @H = @H + '<div class="vct-360-panel" data-vct-panel="lanzamiento">'
        + '<div class="vct-pv-steps is-nav">'
        +   '<div class="' + CASE WHEN @L_CONS = 1 THEN 'ok' ELSE 'now' END + '" data-vct-pv-goto="equipo" role="button" tabindex="0"><i>' + CASE WHEN @L_CONS = 1 THEN '&#10003;' ELSE '1' END + '</i><span><b>Consultor asignado</b>' + CASE WHEN @L_CONS = 1 THEN @LIDER_TXT ELSE 'falta el l&iacute;der' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_DATOS = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="datos" role="button" tabindex="0"><i>' + CASE WHEN @L_DATOS = 1 THEN '&#10003;' ELSE '2' END + '</i><span><b>Datos de entrada</b>'
        +     CASE WHEN @L_DATOS = 1 THEN 'completo &middot; ' + CONVERT(VARCHAR(10), @N_DE) + ' datos'
               WHEN @DE_OBL > 0 THEN CONVERT(VARCHAR(10), @DE_OBL_OK) + ' de ' + CONVERT(VARCHAR(10), @DE_OBL) + ' obligatorios' ELSE CONVERT(VARCHAR(10), @N_DE) + ' cargados' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_CO = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="cons" role="button" tabindex="0"><i>' + CASE WHEN @L_CO = 1 THEN '&#10003;' ELSE '3' END + '</i><span><b>Consideraciones</b>'
        +     CASE WHEN @N_CO = 0 THEN 'sin cargar' ELSE CONVERT(VARCHAR(10), @N_CO) + ' cargada(s)' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_RI = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="riesgos" role="button" tabindex="0"><i>' + CASE WHEN @L_RI = 1 THEN '&#10003;' ELSE '4' END + '</i><span><b>Riesgos</b>'
        +     CASE WHEN @N_RI = 0 THEN 'sin cargar' ELSE CONVERT(VARCHAR(10), @N_RI) + ' cargado(s)' END + CASE WHEN @E_RI_ACT <> '' THEN ' &middot; ' + @E_RI_ACT ELSE '' END + '</span></div>'
        +   '<div class="' + CASE WHEN @L_REU = 1 THEN 'ok' WHEN @L_CONS = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="reunion" role="button" tabindex="0"><i>' + CASE WHEN @L_REU = 1 THEN '&#10003;' ELSE '5' END + '</i><span><b>Reuniones</b>'
        +     CASE WHEN @L_REU = 1 THEN 'lanzamiento' + ISNULL(' ' + CONVERT(VARCHAR(5), @RE_FECHA, 103), '') ELSE @L_REU_TXT END + '</span></div>'
        +   '<div class="' + CASE WHEN @EST_COD = 'ENCURSO' THEN 'ok' WHEN @IN_OK = 1 THEN 'now' ELSE '' END + '" data-vct-pv-sub="inicio" role="button" tabindex="0"><i>' + CASE WHEN @EST_COD = 'ENCURSO' THEN '&#10003;' ELSE '6' END + '</i><span><b>Iniciar proyecto</b>'
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

        /* riesgos (PV_LZ_RIESGOS_V1) */
        + '<div data-vct-pv-subpanel="riesgos" hidden><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span class="vct-pv-ic-pulse"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg></span></span>Riesgos (' + CONVERT(VARCHAR(10), @N_RI) + ')</h3>'
        +   '<span class="vct-pv-box-note">Nivel de riesgo del proyecto: ' + CASE WHEN @E_RI_ACT = '' THEN 'sin definir' ELSE '<span class="vct-360-badge vct-pv-riesgo is-' + LOWER(@E_RI_ACT) + '">' + @E_RI_ACT + '</span>' END + '</span></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_riesgos" data-vct-dg-title="Riesgos" data-vct-dg-unit="riesgo(s)" data-vct-dg-search-placeholder="Buscar riesgo..."' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_RI = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="ri"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="110"><span>Nivel</span></th><th><span>Riesgo</span></th>'
        +   '<th class="vct-text-center" data-vct-width="120"><span>Autor</span></th><th class="vct-text-center" data-vct-width="100" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th>' + @TH_ACC_RI + '</tr></thead><tbody>'
        +   @LZ_RI + '</tbody></table></div>'
        +   CASE WHEN @N_RI = 0 THEN '<div class="vct-360-empty">Sin riesgos. Al cargar uno se elige el nivel de riesgo del proyecto (Bajo / Medio / Alto).</div>' ELSE '' END
        + '</div></div>'

        /* reuniones (PV_LZ_REUNIONES_V1): la tildada como realizada es la de lanzamiento */
        + '<div data-vct-pv-subpanel="reunion" hidden><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="calendar"></span></span>Reuniones (' + CONVERT(VARCHAR(10), @N_RE) + ')</h3>'
        +   '<span class="vct-pv-box-note">' + CASE WHEN @RE_FECHA IS NULL THEN 'Reuni&oacute;n de lanzamiento pendiente' ELSE 'Reuni&oacute;n de lanzamiento: <b class="vct-pv-ok-txt">' + CONVERT(VARCHAR(10), @RE_FECHA, 103) + '</b>' END + '</span></div>'
        +   '<div data-vct-dg data-vct-dg-id="pv_lz_reunion" data-vct-dg-title="Reuniones" data-vct-dg-unit="reuni&oacute;n(es)" data-vct-dg-search-placeholder="Buscar reuni&oacute;n..."' + @DG_ATTR + '>'
        +   CASE WHEN @PUEDE_LANZ = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="re"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        +   '<table><thead><tr><th class="vct-text-center" data-vct-width="100" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th><th data-vct-width="22%"><span>Participantes</span></th>'
        +   '<th><span>Temas y conclusiones</span></th><th data-vct-width="16%"><span>Consultor</span></th><th class="vct-text-center" data-vct-width="110"><span>Tipo</span></th>' + @TH_ACC + '</tr></thead><tbody>'
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
    /* items (desplegable no editable del sub-item) y capitulos (desplegable del item) */
    SELECT @PL_IOPT = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + CASE WHEN CODE <> '' THEN CODE + ' ' ELSE '' END + TH + '</option>'
        FROM #PI WHERE NIV = 2 ORDER BY CAP_ORD, ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    DECLARE @PL_COPT VARCHAR(MAX) = ISNULL((
        SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + CASE WHEN CODE LIKE '[0-9]%' THEN 'Cap&iacute;tulo ' + CODE + ' &middot; ' ELSE '' END + TH + '</option>'
        FROM #PI WHERE NIV = 1 ORDER BY ORD, ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    /* responsable de la accion: equipo (consultores, analista), cliente u otro (texto) */
    DECLARE @PA_ROPT VARCHAR(MAX) = ISNULL((
        SELECT '<option value="EQ:' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(NOMBRE,'&','&amp;'),'<','&lt;'),'>','&gt;')
             + ' (' + REPLACE(REPLACE(ISNULL(ROL_DES,''),'<',''),'>','') + ')</option>'
        FROM #EQ ORDER BY CASE WHEN TIPO = 'CONSULTOR' THEN 0 ELSE 1 END, ROL_ORD, NOMBRE
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
        + CASE WHEN @CLI IS NOT NULL THEN '<option value="CLI">' + @E_CLI + ' (cliente)</option>' ELSE '' END
        + '<option value="OTRO">Otro (escribir el nombre)</option>';
    /* plan base de las normas del proyecto (la principal primero) */
    DECLARE @PLB_DOC INT, @PLB_DES VARCHAR(500) = '', @PLB_N INT = 0;
    SELECT TOP 1 @PLB_DOC = D.ID, @PLB_DES = REPLACE(REPLACE(REPLACE(ISNULL(D.DESCRIPCION, D.CODIGO),'&','&amp;'),'<','&lt;'),'>','&gt;')
    FROM dbo.VCT_PRM_DOCUMENTOS D WITH(NOLOCK)
    INNER JOIN dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK) ON PN.ID_NORMA = D.ID_NORMA AND PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA'
    WHERE D.ACTIVO = 1 AND ISNULL(D.TIPO_DETALLE,'') = 'PLAN'
    ORDER BY PN.PRINCIPAL DESC, PN.ID, D.ID DESC;
    IF @PLB_DOC IS NOT NULL
        SELECT @PLB_N = COUNT(*) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS WITH(NOLOCK) WHERE ID_DOCUMENTO = @PLB_DOC AND ACTIVO = 1 AND ISNULL(GRUPO,'') <> 'CAPITULO';

    IF @PLN IS NOT NULL
    BEGIN
        /* ===== PL_ARBOL_V1: arbol capitulo > item > subitem (editable) + detalle del nodo elegido; cronograma (solo lectura) ===== */
        DECLARE @PL_SEP VARCHAR(20) = ' &middot; ';

        /* fila de accion (detalle): check de cumplida, responsable, vence, estado y menu Editar / Eliminar */
        UPDATE A SET HTML =
              '<div class="vct-plt-acc' + CASE WHEN A.CUMPLIDA = 1 THEN ' is-done' WHEN A.SIT = 'V' THEN ' is-late' ELSE '' END + '">'
            + CASE WHEN @PUEDE_PLAN = 1 AND A.CUMPLIDA = 1
                   THEN '<button type="button" class="vct-pl-ck is-on" data-vct-pv-confirm="PV_PL_ACC_ESTADO" data-t11="PENDIENTE" data-id="' + CONVERT(VARCHAR(20), A.ID) + '" data-msg="&iquest;Reabrir la acci&oacute;n?" title="Reabrir"><span data-vct-icon="check"></span></button>'
                   WHEN @PUEDE_PLAN = 1 AND A.FINAL = 0
                   THEN '<button type="button" class="vct-pl-ck" data-vct-pv-confirm="PV_PL_ACC_ESTADO" data-t11="CUMPLIDA" data-id="' + CONVERT(VARCHAR(20), A.ID) + '" data-msg="&iquest;Marcar la acci&oacute;n como cumplida?" title="Marcar cumplida"></button>'
                   ELSE '<span class="vct-pl-ck' + CASE WHEN A.CUMPLIDA = 1 THEN ' is-on' ELSE '' END + '">' + CASE WHEN A.CUMPLIDA = 1 THEN '<span data-vct-icon="check"></span>' ELSE '' END + '</span>' END
            + '<span class="vct-plt-acc-t"><b title="' + REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN A.DET <> '' THEN A.DET ELSE A.SUB END,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + REPLACE(REPLACE(REPLACE(CASE WHEN A.DET <> '' THEN A.DET ELSE A.SUB END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</b>'
            + '<small>' + REPLACE(REPLACE(REPLACE(A.SUB,'&','&amp;'),'<','&lt;'),'>','&gt;') + CASE WHEN A.INI IS NOT NULL THEN @PL_SEP + 'desde ' + CONVERT(VARCHAR(5), A.INI, 103) ELSE '' END + '</small></span>'
            + '<span class="vct-plt-resp is-ini">' + CASE WHEN A.RESP_INI <> '' THEN '<span class="vctdg-avatar ' + A.RCLS + '" title="' + REPLACE(REPLACE(REPLACE(REPLACE(A.RESP_NOM,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + A.RESP_INI + '</span>' ELSE '<span class="vctdg-avatar is-none" title="Sin responsable">-</span>' END + '</span>'
            + '<span class="vct-plt-d"' + CASE WHEN A.CUMPLIDA = 1 AND A.CIERRE IS NOT NULL THEN ' title="Cumplida el ' + CONVERT(VARCHAR(10), A.CIERRE, 103) + '"' ELSE '' END + '>' + CASE WHEN A.CUMPLIDA = 1 THEN ISNULL(CONVERT(VARCHAR(10), A.CIERRE, 103), '-') WHEN A.VENCE IS NULL THEN '-' ELSE CONVERT(VARCHAR(10), A.VENCE, 103) END + '</span>'
            + '<span class="vct-plt-b"><span class="vct-360-badge ' + CASE WHEN A.CUMPLIDA = 1 THEN 'is-active' WHEN A.SIT = 'V' THEN 'is-cancel' WHEN A.EST_COD IN ('EN_PROCESO','EN_ESPERA') THEN 'is-progress' ELSE 'is-planned' END + '">'
            + CASE WHEN A.CUMPLIDA = 1 THEN 'Cumplida' WHEN A.SIT = 'V' THEN 'Vencida' ELSE REPLACE(REPLACE(A.EST_DES,'<',''),'>','') END + '</span></span>'
            + CASE WHEN @PUEDE_PLAN = 1 THEN '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-edit="pa" data-id="' + CONVERT(VARCHAR(20), A.ITEM) + '" data-f-accid="' + CONVERT(VARCHAR(20), A.ID) + '"'
                + ' data-f-tipo="' + ISNULL(CONVERT(VARCHAR(20), A.TIPO),'') + '" data-f-sub="' + ISNULL(CONVERT(VARCHAR(20), A.SUBT),'') + '" data-f-prio="' + ISNULL(CONVERT(VARCHAR(20), A.PRIO),'') + '"'
                + ' data-f-est="' + ISNULL(CONVERT(VARCHAR(20), A.ESTI),'') + '" data-f-res="' + ISNULL(CONVERT(VARCHAR(20), A.RES),'') + '"'
                + ' data-f-ini="' + ISNULL(CONVERT(VARCHAR(10), A.INI, 120),'') + '" data-f-vence="' + ISNULL(CONVERT(VARCHAR(10), A.VENCE, 120),'') + '"'
                + ' data-f-resp="' + A.RCOD + '" data-f-nom="' + REPLACE(REPLACE(REPLACE(REPLACE(A.RLIB,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"'
                + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(A.DETF,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar</span></button>'
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ACC_BORRAR" data-id="' + CONVERT(VARCHAR(20), A.ID) + '" data-nombre="' + REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN A.DET <> '' THEN A.DET ELSE A.SUB END,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button>'
                + '</div></span>' ELSE '' END
            + '</div>'
        FROM #PA A;

        /* menu y fila del arbol de cada item / subitem */
        UPDATE T SET HTML =
              '<div class="vct-plt-r is-' + CASE WHEN T.NIV = 3 THEN 'sub' ELSE 'it' END + '" data-pl-row="' + CONVERT(VARCHAR(20), T.ID) + '">'
            + '<span class="vct-plt-n">'
            + CASE WHEN T.HIJOS > 0 THEN '<span class="vct-plt-tg" data-pl-tg role="button" tabindex="0"><span data-vct-icon="chevron-right"></span></span>' ELSE '<span class="vct-plt-ph"></span>' END
            + CASE WHEN T.HITO = 1 THEN '<span class="vct-pl-code is-hito">Hito</span>' WHEN T.CODE <> '' THEN '<span class="vct-pl-code">' + T.CODE + '</span>' ELSE '' END
            + '<span class="vct-plt-tw"><span class="vct-plt-t" data-pl-sel="' + CONVERT(VARCHAR(20), T.ID) + '" title="' + T.TA + '">' + T.TH + '</span>'
            + CASE WHEN (T.FI IS NOT NULL OR T.FF IS NOT NULL) AND ISNULL(T.OBS,'') <> ''
                   THEN '<small class="vct-plt-sub" title="' + REPLACE(REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '">' + REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</small>' ELSE '' END
            + '</span></span>'
            + '<span class="vct-plt-c vct-plt-resp">' + CASE WHEN ISNULL(T.RESP_INI,'') <> '' THEN '<span class="vctdg-avatar is-c">' + T.RESP_INI + '</span><span>' + REPLACE(REPLACE(REPLACE(T.RESP_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>' ELSE '<span class="vctdg-none">-</span>' END + '</span>'
            /* PL_FECHAS_V1: inicio / vence / fin real (el subitem toma las fechas de su item) */
            + '<span class="vct-plt-c vct-plt-f">' + ISNULL(CONVERT(VARCHAR(5), ISNULL(T.FI, (SELECT X.FI FROM #PI X WHERE X.ID = T.TOPI)), 103), '-') + '</span>'
            + '<span class="vct-plt-c vct-plt-f">' + ISNULL(CONVERT(VARCHAR(5), ISNULL(T.FF, (SELECT X.FF FROM #PI X WHERE X.ID = T.TOPI)), 103), '-') + '</span>'
            + '<span class="vct-plt-c vct-plt-f' + CASE WHEN T.FR IS NOT NULL AND ISNULL(T.FF, (SELECT X.FF FROM #PI X WHERE X.ID = T.TOPI)) IS NOT NULL
                                                         THEN CASE WHEN CONVERT(DATE, T.FR) > CONVERT(DATE, ISNULL(T.FF, (SELECT X.FF FROM #PI X WHERE X.ID = T.TOPI))) THEN ' is-late" title="Cerrado despu&eacute;s del vencimiento' ELSE ' is-ok" title="Cerrado en t&eacute;rmino' END ELSE '' END + '">'
            +   ISNULL(CONVERT(VARCHAR(5), T.FR, 103), '-') + '</span>'
            + '<span class="vct-plt-c vct-plt-pg"><span class="vct-pv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(10), ISNULL(T.AV, 0)) + '%"></span></span><b>' + CONVERT(VARCHAR(10), ISNULL(T.AV, 0)) + '%</b></span>'
            + '<span class="vct-plt-c vct-plt-cnt">' + CONVERT(VARCHAR(10), T.CUMP) + '/' + CONVERT(VARCHAR(10), T.TOT) + ' acc.' + CASE WHEN T.VEN > 0 THEN ' &middot; <b>' + CONVERT(VARCHAR(10), T.VEN) + ' venc.</b>' ELSE '' END + '</span>'
            + '<span class="vct-plt-b"><span class="vct-360-badge ' + CASE T.EST WHEN 'CUMPLIDO' THEN 'is-active' WHEN 'VENCIDO' THEN 'is-cancel' WHEN 'EN_CURSO' THEN 'is-progress' ELSE 'is-planned' END + '">'
            + CASE T.EST WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso' ELSE 'Pendiente' END + '</span></span>'
            + '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
            + '<button type="button" class="vct-pv-menu-btn" data-pl-sel="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="eye"></span><span>Ver detalle</span></button>'
            + CASE WHEN @PUEDE_PLAN = 1 THEN
                  '<button type="button" class="vct-pv-menu-btn" data-vct-pv-new="pa" data-id="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Nueva acci&oacute;n</span></button>'
                + CASE WHEN T.NIV = 2 THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-new="pi" data-f-padre="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Agregar sub&iacute;tem</span></button>' ELSE '' END
                + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-edit="pi" data-id="' + CONVERT(VARCHAR(20), T.ID) + '" data-f-padre="' + CASE WHEN T.NIV = 3 THEN CONVERT(VARCHAR(20), T.PADRE) ELSE '' END + '"'
                + ' data-f-cap="' + ISNULL(CONVERT(VARCHAR(20), T.CHAP),'') + '" data-f-tit="' + T.TA + '"'
                + ' data-f-fi="' + ISNULL(CONVERT(VARCHAR(10), T.FI, 120),'') + '" data-f-ff="' + ISNULL(CONVERT(VARCHAR(10), T.FF, 120),'') + '" data-f-fr="' + ISNULL(CONVERT(VARCHAR(10), T.FR, 120),'') + '"'
                + ' data-f-resp="' + ISNULL(CONVERT(VARCHAR(20), T.RESP),'') + '" data-f-hito="' + CASE WHEN T.HITO = 1 THEN '1' ELSE '0' END + '"'
                + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar ' + CASE WHEN T.NIV = 3 THEN 'sub&iacute;tem' ELSE '&iacute;tem' END + '</span></button>'
                + CASE WHEN T.TOT = 0 AND T.HIJOS = 0
                       THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_PL_ITEM_BORRAR" data-id="' + CONVERT(VARCHAR(20), T.ID) + '" data-nombre="' + T.TA + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button>' ELSE '' END
              ELSE '' END
            + '</div></span></div>'
        FROM #PI T WHERE T.NIV > 1;

        /* detalle del item / subitem (se muestra al elegirlo: 50 / 50) */
        UPDATE T SET DHTML =
              '<div class="vct-plt-det" data-pl-det="' + CONVERT(VARCHAR(20), T.ID) + '" hidden>'
            + '<div class="vct-plt-det-h"><div class="vct-plt-det-tt"><small>'
            + ISNULL((SELECT CASE WHEN C.CODE LIKE '[0-9]%' THEN 'Cap&iacute;tulo ' + C.CODE + @PL_SEP ELSE '' END + C.TH FROM #PI C WHERE C.ID = T.CHAP), 'Otros &iacute;tems')
            + CASE WHEN T.NIV = 3 THEN ISNULL((SELECT @PL_SEP + CASE WHEN P.CODE <> '' THEN P.CODE + ' ' ELSE '' END + P.TH FROM #PI P WHERE P.ID = T.PADRE), '') ELSE '' END + '</small>'
            + '<h4>' + CASE WHEN T.HITO = 1 THEN '<span class="vct-pl-code is-hito">Hito</span> ' WHEN T.CODE <> '' THEN T.CODE + @PL_SEP ELSE '' END + T.TH + '</h4>'
            + '<span class="vct-360-badge ' + CASE T.EST WHEN 'CUMPLIDO' THEN 'is-active' WHEN 'VENCIDO' THEN 'is-cancel' WHEN 'EN_CURSO' THEN 'is-progress' ELSE 'is-planned' END + '">'
            + CASE T.EST WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso' ELSE 'Pendiente' END + '</span></div>'
            + '<button type="button" class="vct-plt-x" data-pl-x title="Cerrar detalle" aria-label="Cerrar detalle">&times;</button></div>'
            + '<div class="vct-plt-meta">'
            + '<div><small>Responsable</small><b>' + CASE WHEN ISNULL(T.RESP_NOM,'') <> '' THEN REPLACE(REPLACE(REPLACE(T.RESP_NOM,'&','&amp;'),'<','&lt;'),'>','&gt;') ELSE 'Sin asignar' END + '</b></div>'
            + '<div><small>Inicio</small><b>' + ISNULL(CONVERT(VARCHAR(10), ISNULL(T.FI, (SELECT X.FI FROM #PI X WHERE X.ID = T.TOPI)), 103), '-') + '</b></div>'
            + '<div><small>Vence</small><b>' + ISNULL(CONVERT(VARCHAR(10), ISNULL(T.FF, (SELECT X.FF FROM #PI X WHERE X.ID = T.TOPI)), 103), '-') + '</b></div>'
            + CASE WHEN T.FR IS NOT NULL THEN '<div><small>Fin real</small><b>' + CONVERT(VARCHAR(10), T.FR, 103) + '</b></div>' ELSE '' END
            + '<div class="vct-plt-meta-pg"><small>Avance</small><span class="vct-plt-pg"><span class="vct-pv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(10), ISNULL(T.AV, 0)) + '%"></span></span><b>' + CONVERT(VARCHAR(10), ISNULL(T.AV, 0)) + '%</b></span></div>'
            + '</div>'
            + CASE WHEN T.NIV = 3 THEN '<div class="vct-help">El sub&iacute;tem toma las fechas del &iacute;tem.</div>' ELSE '' END
            + CASE WHEN T.OBS <> '' THEN '<p class="vct-plt-obs">' + REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</p>' ELSE '' END
            + '<div class="vct-plt-sec">Acciones (' + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #PA A WHERE A.ITEM = T.ID)) + ')</div>'
            + '<div class="vct-plt-alist">' + ISNULL(NULLIF((SELECT A.HTML AS [text()] FROM #PA A WHERE A.ITEM = T.ID ORDER BY A.CUMPLIDA, ISNULL(A.VENCE, '29991231'), A.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),
                                                     '<div class="vct-plt-empty">Sin acciones cargadas.</div>') + '</div>'
            + CASE WHEN @PUEDE_PLAN = 1 THEN '<div class="vct-plt-btns">'
                   + '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="pa" data-id="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Nueva acci&oacute;n</span></button>'
                   + CASE WHEN T.NIV = 2 THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="pi" data-f-padre="' + CONVERT(VARCHAR(20), T.ID) + '"><span data-vct-icon="plus"></span><span>Sub&iacute;tem</span></button>' ELSE '' END
                   + '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-edit="pi" data-id="' + CONVERT(VARCHAR(20), T.ID) + '" data-f-padre="' + CASE WHEN T.NIV = 3 THEN CONVERT(VARCHAR(20), T.PADRE) ELSE '' END + '"'
                   + ' data-f-cap="' + ISNULL(CONVERT(VARCHAR(20), T.CHAP),'') + '" data-f-tit="' + T.TA + '"'
                   + ' data-f-fi="' + ISNULL(CONVERT(VARCHAR(10), T.FI, 120),'') + '" data-f-ff="' + ISNULL(CONVERT(VARCHAR(10), T.FF, 120),'') + '" data-f-fr="' + ISNULL(CONVERT(VARCHAR(10), T.FR, 120),'') + '"'
                   + ' data-f-resp="' + ISNULL(CONVERT(VARCHAR(20), T.RESP),'') + '" data-f-hito="' + CASE WHEN T.HITO = 1 THEN '1' ELSE '0' END + '"'
                   + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(T.OBS,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar ' + CASE WHEN T.NIV = 3 THEN 'sub&iacute;tem' ELSE '&iacute;tem' END + '</span></button>'
                   + '</div>' ELSE '' END
            /* subitems del item: se eligen desde aca tambien */
            + CASE WHEN T.NIV = 2 AND T.HIJOS > 0 THEN '<div class="vct-plt-sec">Sub&iacute;tems (' + CONVERT(VARCHAR(10), T.HIJOS) + ')</div><div class="vct-plt-alist">'
                   + ISNULL((SELECT '<div class="vct-plt-subl" data-pl-sel="' + CONVERT(VARCHAR(20), S.ID) + '" role="button" tabindex="0">'
                                  + CASE WHEN S.CODE <> '' THEN '<span class="vct-pl-code">' + S.CODE + '</span>' ELSE '' END + '<b>' + S.TH + '</b>'
                                  + '<small>' + CONVERT(VARCHAR(10), S.CUMP) + '/' + CONVERT(VARCHAR(10), S.TOT) + ' acc.</small>'
                                  + '<span class="vct-360-badge ' + CASE S.EST WHEN 'CUMPLIDO' THEN 'is-active' WHEN 'VENCIDO' THEN 'is-cancel' WHEN 'EN_CURSO' THEN 'is-progress' ELSE 'is-planned' END + '">'
                                  + CASE S.EST WHEN 'CUMPLIDO' THEN 'Cumplido' WHEN 'VENCIDO' THEN 'Vencido' WHEN 'EN_CURSO' THEN 'En curso' ELSE 'Pendiente' END + '</span></div>' AS [text()]
                             FROM #PI S WHERE S.PADRE = T.ID AND S.NIV = 3 ORDER BY S.ORD, S.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '') + '</div>' ELSE '' END
            + '</div>'
        FROM #PI T WHERE T.NIV > 1;

        /* arbol: capitulos (reales y "Otros items") con sus items y subitems */
        SELECT @PL_ROWS = ISNULL((
            SELECT G.H AS [text()] FROM (
                SELECT C.CO,
                       '<div class="vct-plt-ch" data-pl-ch="' + C.CAP + '"' + CASE WHEN C.ABRE = 1 THEN ' data-pl-def="1"' ELSE '' END + '>'
                     + '<div class="vct-plt-r is-ch" data-pl-tg role="button" tabindex="0"><span class="vct-plt-n">'
                     + '<span class="vct-plt-tg"><span data-vct-icon="chevron-right"></span></span>'
                     + '<span class="vct-pl-ring" style="background:conic-gradient(#66062D 0 ' + CONVERT(VARCHAR(10), C.AV) + '%, #f1e4ea 0)"><span>' + CONVERT(VARCHAR(10), C.AV) + '%</span></span>'
                     + '<span class="vct-plt-cht"><b>' + C.TIT + '</b><small>' + CONVERT(VARCHAR(10), C.NI) + ' &iacute;tem(s)'
                     + CASE WHEN C.FI IS NOT NULL THEN @PL_SEP + CONVERT(VARCHAR(5), C.FI, 103) + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(5), C.FF, 103), '-') ELSE @PL_SEP + 'sin fechas' END
                     + @PL_SEP + CONVERT(VARCHAR(10), C.CUMP) + ' de ' + CONVERT(VARCHAR(10), C.TOT) + ' acciones cumplidas'
                     + CASE WHEN C.VEN > 0 THEN @PL_SEP + '<span class="vct-pl-late">' + CONVERT(VARCHAR(10), C.VEN) + ' vencida(s)</span>' ELSE '' END + '</small></span></span>'
                     + '<span class="vct-plt-c"></span><span class="vct-plt-c vct-plt-f">' + ISNULL(CONVERT(VARCHAR(5), C.FI, 103), '-') + '</span><span class="vct-plt-c vct-plt-f">' + ISNULL(CONVERT(VARCHAR(5), C.FF, 103), '-') + '</span><span class="vct-plt-c vct-plt-f"></span>'
                     + '<span class="vct-plt-c vct-plt-pg"><span class="vct-pv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(10), C.AV) + '%"></span></span><b>' + CONVERT(VARCHAR(10), C.AV) + '%</b></span>'
                     + '<span class="vct-plt-c vct-plt-cnt">' + CONVERT(VARCHAR(10), C.CUMP) + '/' + CONVERT(VARCHAR(10), C.TOT) + ' acc.</span><span class="vct-plt-b"></span><span class="vct-plt-m"></span></div>'
                     + '<div class="vct-plt-kids">'
                     + ISNULL((SELECT '<div class="vct-plt-it" data-pl-node data-pl-est="' + I.EST + '" data-pl-search="'
                                    + LOWER(REPLACE(REPLACE(REPLACE(I.CODE + ' ' + I.TIT
                                          + ISNULL((SELECT ' ' + S.CODE + ' ' + S.TIT FROM #PI S WHERE S.TOPI = I.ID AND S.NIV = 3 FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                                          + ISNULL((SELECT ' ' + A.DET + ' ' + A.SUB + ' ' + A.RESP_NOM FROM #PA A WHERE A.TOP_ITEM = I.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),'"',''),'<',''),'>','')) + '">'
                                    + I.HTML
                                    + CASE WHEN I.HIJOS > 0 THEN '<div class="vct-plt-kids">'
                                         + ISNULL((SELECT '<div class="vct-plt-it is-sub" data-pl-node data-pl-est="' + S.EST + '" data-pl-search="'
                                                        + LOWER(REPLACE(REPLACE(REPLACE(S.CODE + ' ' + S.TIT + ISNULL((SELECT ' ' + A.DET + ' ' + A.SUB + ' ' + A.RESP_NOM FROM #PA A WHERE A.ITEM = S.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),'"',''),'<',''),'>','')) + '">'
                                                        + S.HTML + '</div>' AS [text()]
                                                   FROM #PI S WHERE S.TOPI = I.ID AND S.NIV = 3 ORDER BY S.ORD, S.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                                         + '</div>' ELSE '' END
                                    + '</div>' AS [text()]
                               FROM #PI I WHERE I.NIV = 2 AND I.CAP = C.CAP ORDER BY I.ORD, I.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '')
                     + '</div></div>' AS H
                FROM (
                    SELECT X.CAP, X.ORD AS CO, CASE WHEN X.CODE LIKE '[0-9]%' THEN 'Cap&iacute;tulo ' + X.CODE + @PL_SEP ELSE '' END + X.TH AS TIT,
                           X.AV, X.TOT, X.CUMP, X.VEN, X.FI, X.FF,
                           (SELECT COUNT(*) FROM #PI I WHERE I.NIV = 2 AND I.CHAP = X.ID) AS NI,
                           CASE WHEN EXISTS (SELECT 1 FROM #PI I WHERE I.NIV = 2 AND I.CHAP = X.ID AND I.EST IN ('EN_CURSO','VENCIDO')) THEN 1 ELSE 0 END AS ABRE
                    FROM #PI X WHERE X.NIV = 1
                    UNION ALL
                    SELECT 'Z', 999999, 'Otros &iacute;tems',
                           ISNULL(CONVERT(INT, ROUND(SUM(CONVERT(NUMERIC(18,4), AV * UNI)) / NULLIF(SUM(UNI), 0), 0)), 0), SUM(TOT), SUM(CUMP), SUM(VEN), MIN(FI), MAX(FF), COUNT(*),
                           MAX(CASE WHEN EST IN ('EN_CURSO','VENCIDO') THEN 1 ELSE 0 END)
                    FROM #PI WHERE NIV = 2 AND CHAP IS NULL HAVING COUNT(*) > 0
                ) C
            ) G ORDER BY G.CO
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        /* si ningun capitulo queda abierto por defecto, se abre el primero */
        IF @PL_ROWS <> '' AND CHARINDEX('data-pl-def="1"', @PL_ROWS) = 0
            SET @PL_ROWS = STUFF(@PL_ROWS, CHARINDEX('"vct-plt-ch" data-pl-ch="', @PL_ROWS) + LEN('"vct-plt-ch"'), 0, ' data-pl-def="1"');
        DECLARE @PL_DETS VARCHAR(MAX) = ISNULL((SELECT DHTML AS [text()] FROM #PI WHERE NIV > 1 ORDER BY ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        /* ----- cronograma (solo lectura, mismo diseno): semanas si el rango es corto, meses si es largo ----- */
        DECLARE @G_INI DATETIME, @G_FIN DATETIME, @G_END DATETIME, @G_DAYS INT, @G_N INT, @G_I INT = 0, @G_MES BIT = 0, @G_COLS VARCHAR(MAX) = '', @G_HOY VARCHAR(20) = '';
        SELECT @G_INI = ISNULL(@F_INI, MIN(FI)), @G_FIN = ISNULL(@F_FIN, MAX(FF)) FROM #PI WHERE NIV = 2;
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
                    SELECT T.CAP_ORD AS O1, 0 AS O2, 0 AS O3, 0 AS O4,
                           '<div class="vct-pl-g-row is-chap" data-pl-gchap="' + T.CAP + '"><div class="vct-pl-g-l"><b>'
                         + ISNULL((SELECT CASE WHEN C.CODE LIKE '[0-9]%' THEN 'Cap&iacute;tulo ' + C.CODE + @PL_SEP ELSE '' END + C.TH FROM #PI C WHERE C.ID = MIN(T.CHAP)), 'Otros &iacute;tems')
                         + '</b></div><div class="vct-pl-g-lane"></div></div>' AS H
                    FROM #PI T WHERE T.NIV = 2 GROUP BY T.CAP, T.CAP_ORD
                    UNION ALL
                    /* item */
                    SELECT T.CAP_ORD, T.ORD, T.ID, 0,
                           '<div class="vct-pl-g-row" data-pl-grow="' + CONVERT(VARCHAR(20), T.ID) + '" data-pl-cap="' + T.CAP + '" data-pl-est="' + T.EST + '" data-pl-search="' + LOWER(REPLACE(REPLACE(REPLACE(T.CODE + ' ' + T.TIT,'"',''),'<',''),'>','')) + '">'
                         + '<div class="vct-pl-g-l">' + CASE WHEN T.HITO = 1 THEN '<span class="vct-pl-code is-hito">Hito</span>' WHEN T.CODE <> '' THEN '<span class="vct-pl-code">' + T.CODE + '</span>' ELSE '' END
                         + '<span class="vct-pl-g-t" title="' + REPLACE(REPLACE(T.TIT,'"',''),'<','') + '">' + T.TH + '</span>'
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
                    FROM #PI T WHERE T.NIV = 2
                    UNION ALL
                    /* sub-items: heredan el rango del item */
                    SELECT T.CAP_ORD, T.ORD, T.ID, S.ORD + 1,
                           '<div class="vct-pl-g-row is-sub" data-pl-gparent="' + CONVERT(VARCHAR(20), T.ID) + '"><div class="vct-pl-g-l"><span class="vct-pl-g-t">' + CASE WHEN S.CODE <> '' THEN S.CODE + ' ' ELSE '' END + S.TH + '</span>'
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
                    FROM #PI S INNER JOIN #PI T ON T.ID = S.TOPI WHERE S.NIV = 3
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
                       CASE WHEN CODE <> '' THEN CODE + ' ' ELSE '' END + REPLACE(REPLACE(REPLACE(LEFT(NAME, 70),'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, FF, @HOY)) + ' d' AS T, FF AS F
                FROM #PI WHERE NIV = 2 AND EST = 'VENCIDO'
                UNION ALL
                SELECT 2, 'is-planned', 'Fecha', REPLACE(REPLACE(REPLACE(LEFT(TITULO, 90),'&','&amp;'),'<','&lt;'),'>','&gt;'), CREA
                FROM #A WHERE SUB_COD = 'AVISO_VENCIMIENTO' AND SIT <> 'C' AND TITULO LIKE 'Cambio de fecha en el plan%'
                UNION ALL
                SELECT 3, 'is-cancel', 'Acci&oacute;n', REPLACE(REPLACE(REPLACE(LEFT(CASE WHEN DET <> '' THEN DET ELSE TIT END, 70),'&','&amp;'),'<','&lt;'),'>','&gt;') + ' &middot; venci&oacute; ' + CONVERT(VARCHAR(5), VENCE, 103), VENCE
                FROM #PA WHERE SIT = 'V'
            ) X ORDER BY X.O, X.F
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    END;

    SET @PL_H = '<div class="vct-360-panel" data-vct-panel="plan"><div data-vct-pv-planpane="co">';
    IF @PLN IS NULL
        SET @PL_H = @PL_H + '<div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Plan estrat&eacute;gico</h3></div>'
            + CASE WHEN @PLN_TIENE_CO = 0 THEN '<div class="vct-360-empty">El plan estrat&eacute;gico solo existe si el proyecto tiene consultor&iacute;a. Sin plan: las acciones se cargan con fecha en la pesta&ntilde;a Acciones.</div>'
                   WHEN @EST_COD <> 'ENCURSO' THEN '<div class="vct-360-empty">El plan se arma cuando el proyecto est&aacute; En curso (despu&eacute;s del lanzamiento).</div>'
                   WHEN @PUEDE_PLAN = 0 THEN '<div class="vct-360-empty">El consultor todav&iacute;a no arm&oacute; el plan del proyecto.</div>'
                   ELSE '<div class="vct-pl-start">'
                      + '<p>Eleg&iacute; c&oacute;mo arrancar el plan. Despu&eacute;s defin&iacute;s fechas de inicio y fin y el responsable de cada &iacute;tem, y cargas las acciones.</p>'
                      + '<div class="vct-pl-start-opts">'
                      + CASE WHEN @PLB_DOC IS NOT NULL
                             THEN '<button type="button" class="vct-pl-opt" data-vct-pv-confirm="PV_PL_GENERAR" data-t11="BASE" data-id="0" data-msg="&iquest;Generar el plan con el plan base ' + @PLB_DES + '?">'
                                + '<b>A &middot; Desde el plan base</b><span>' + @PLB_DES + ' &middot; ' + CONVERT(VARCHAR(10), @PLB_N) + ' &iacute;tems y sub&iacute;tems por cap&iacute;tulo</span></button>'
                             ELSE '<div class="vct-pl-opt is-off"><b>A &middot; Desde el plan base</b><span>No hay plan base cargado para las normas del proyecto' + CASE WHEN @NOR_META <> '' THEN ' (' + @NOR_META + ')' ELSE '' END + '.</span></div>' END
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
            +   '<div><b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b><small>avance</small></div></div>'
            +   '<ul class="vct-pl-legend"><li><i style="background:#16a34a"></i>Cumplidos <b>' + CONVERT(VARCHAR(10), @PL_C) + '</b></li><li><i style="background:#2563eb"></i>En curso <b>' + CONVERT(VARCHAR(10), @PL_E) + '</b></li>'
            +   '<li><i style="background:#94a3b8"></i>Pendientes <b>' + CONVERT(VARCHAR(10), @PL_P) + '</b></li><li><i style="background:#dc2626"></i>Vencidos <b>' + CONVERT(VARCHAR(10), @PL_V) + '</b></li>'
            +   '<li class="vct-pl-legend-tot">Sobre ' + CONVERT(VARCHAR(10), @PL_NU) + ' &iacute;tems y sub&iacute;tems</li></ul></div></div>'
            + '<div class="vct-360-box vct-pl-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clock-3"></span></span>Tiempo y avance</h3></div>'
            +   '<div class="vct-pl-tv"><div><span>Tiempo transcurrido del proyecto</span><div class="vct-pl-tv-bar"><span class="is-time" style="width:' + CONVERT(VARCHAR(10), @PL_HOYP) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PL_HOYP) + '%</b></div>'
            +   '<div><span>Avance del plan (sobre el total de &iacute;tems)</span><div class="vct-pl-tv-bar"><span class="is-plan" style="width:' + CONVERT(VARCHAR(10), @PL_PCT) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PL_PCT) + '%</b></div>'
            +   '<div><span>Avance de horas (ejecutadas / proyectadas)</span><div class="vct-pl-tv-bar"><span class="is-hours" style="width:' + CONVERT(VARCHAR(10), @PCT_H) + '%"></span></div><b>' + CONVERT(VARCHAR(10), @PCT_H) + '%</b></div>'
            +   '<p class="vct-pl-tv-note">' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-') + ' &middot; ' + CONVERT(VARCHAR(10), @PL_OK) + ' de ' + CONVERT(VARCHAR(10), @PL_TOT) + ' acciones cumplidas</p></div></div>'
            + '<div class="vct-360-box vct-pl-card"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="bell"></span></span>Requiere atenci&oacute;n</h3></div>'
            +   CASE WHEN @PL_ATN = '' THEN '<div class="vct-360-empty">Nada vencido ni cambios de fecha pendientes.</div>' ELSE '<ul class="vct-pl-atn">' + @PL_ATN + '</ul>' END + '</div>'
            + '</div>'
            /* arbol (editable) / cronograma (solo lectura) PL_ARBOL_V1 */
            + '<div class="vct-360-box vct-pl-box" data-pl-box><div class="vct-360-box-head vct-pl-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span>Plan estrat&eacute;gico'
            +   CASE WHEN @PLN_DOC <> '' THEN '<span class="vct-pl-head-doc">' + @PLN_DOC + '</span>' ELSE '' END + '</h3>'
            +   '<div class="vct-pl-view" role="group" aria-label="Vista"><button type="button" class="is-on" data-pl-view="cards"><span data-vct-icon="list-checks"></span><span>&Aacute;rbol</span></button>'
            +   '<button type="button" data-pl-view="gantt"><span data-vct-icon="calendar"></span><span>Cronograma</span></button></div></div>'
            +   '<div class="vctdg vct-pl-tools"><div class="vctdg-toolbar"><div class="vctdg-filters"><div class="vctdg-search"><span data-vct-icon="search"></span><input type="search" placeholder="Buscar &iacute;tem, sub&iacute;tem o acci&oacute;n..." data-pl-buscar autocomplete="off"></div>'
            +   '<select class="vct-select vct-select-sm" data-vct-dg-filter="estado" data-pl-estado><option value="">Todos los estados</option><option value="PENDIENTE">Pendiente</option><option value="EN_CURSO">En curso</option><option value="VENCIDO">Vencido</option><option value="CUMPLIDO">Cumplido</option></select></div>'
            +   '<div class="vctdg-tools vct-pl-edit-tools">'
            +   '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-pl-chap-all><span data-vct-icon="list-checks"></span><span>Expandir todo</span></button>'
            +   CASE WHEN @PUEDE_PLAN = 1 AND @PL_CARGA_ABIERTA = 1 THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-confirm="PV_PL_CERRAR" data-id="0" data-msg="&iquest;Finalizar la carga del plan? La acci&oacute;n de carga del plan queda cumplida (todos los &iacute;tems tienen que tener fecha de inicio y fin)."><span data-vct-icon="check"></span><span>Finalizar carga</span></button>' ELSE '' END
            +   CASE WHEN @PUEDE_PLAN = 1 THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="pi" data-f-padre=""><span data-vct-icon="plus"></span><span>&Iacute;tem</span></button>' ELSE '' END
            +   '</div></div></div>'
            +   '<div class="vct-pl-cardsview" data-pl-pane="cards">'
            +   CASE WHEN @PL_ROWS = '' THEN '<div class="vct-360-empty">El plan no tiene &iacute;tems. Us&aacute; &laquo;&Iacute;tem&raquo; para agregarlos.</div>' ELSE
                  '<div class="vct-plt" data-pl-tree><div class="vct-plt-tree">'
                + '<div class="vct-plt-hd"><span>Cap&iacute;tulo / &iacute;tem / sub&iacute;tem</span><span class="vct-plt-c">Responsable</span><span class="vct-plt-c">Inicio</span><span class="vct-plt-c">Vence</span><span class="vct-plt-c">Fin real</span><span class="vct-plt-c">Avance</span><span class="vct-plt-c">Acciones</span><span>Estado</span><span></span></div>'
                + @PL_ROWS + '<div class="vct-360-empty" data-pl-nores hidden>No hay &iacute;tems que coincidan con el filtro.</div></div>'
                + '<div class="vct-plt-side">' + ISNULL(@PL_DETS, '') + '</div></div>' END
            +   '</div>'
            +   '<div class="vct-pl-ganttview" data-pl-pane="gantt" hidden>' + @PL_GANTT + '</div>'
            + '</div>';
    /* plan de auditoria / capacitacion de la instancia elegida: todavia sin definir (PV_PLAN_TAB_V1) */
    SET @PL_H = @PL_H + '</div>'
        + '<div data-vct-pv-planpane="otro" hidden><div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="list-checks"></span></span><span data-vct-pv-planpane-tit>Plan</span></h3></div>'
        + '<div class="vct-360-empty" data-vct-pv-planpane-msg>Plan pendiente de definici&oacute;n.</div></div></div>'
        + '</div>';

    /* ======================= ACCIONES (AC_PESTANIA_V1) =======================
       Grilla unica agrupada por origen (proyecto, plan, pendientes del cliente, workflow) con chips arriba para
       ver cada grupo por separado. Las del proyecto (manuales, sin item) se agregan / editan / eliminan aca;
       las del plan se gestionan en su item; las del workflow las genera el sistema. */
    DECLARE @AC VARCHAR(MAX) = '', @AC_F_EST VARCHAR(MAX) = '', @AC_F_AREA VARCHAR(MAX) = '', @AC_F_TIPO VARCHAR(MAX) = '',
            @AC_CHIPS VARCHAR(MAX) = '', @AC_NOPT VARCHAR(MAX) = '', @AC_F_CAP VARCHAR(MAX) = '';
    SELECT @AC = ISNULL((
        SELECT '<tr data-vct-row data-pv-acg="' + CASE OG WHEN 1 THEN 'proyecto' WHEN 2 THEN 'plan' WHEN 3 THEN 'cliente' ELSE 'workflow' END + '"'
             + ' data-vct-filter-origen="' + CASE OG WHEN 1 THEN 'proyecto' WHEN 2 THEN 'plan' WHEN 3 THEN 'cliente' ELSE 'workflow' END + '"'
             + ' data-vct-filter-cap="' + ISNULL(CONVERT(VARCHAR(20), CAPI), '') + '"'
             + ' data-vct-filter-estado="' + CASE WHEN SIT = 'V' THEN 'VENCIDA' ELSE EST_COD END + '" data-vct-filter-area="' + REPLACE(AREA,'"','') + '" data-vct-filter-tipo="' + REPLACE(TIPO,'"','') + '">'
             + '<td><span class="vct-360-project-name">' + REPLACE(REPLACE(REPLACE(TIPO + CASE WHEN SUB_DES <> '' THEN ' - ' + SUB_DES ELSE '' END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span>'
             + '<span class="vct-360-project-ref">' + REPLACE(REPLACE(REPLACE(CASE WHEN OG IN (1,3) AND DETF <> '' THEN LEFT(REPLACE(REPLACE(DETF, CHAR(13), ' '), CHAR(10), ' '), 200) ELSE TITULO END,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</span></td>'
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
             + '<td class="vct-table-action-cell" data-label="" data-vct-export-ignore="true"><div class="vct-pv-ac-acts">'
             + CASE WHEN MIA = 1 AND SIT <> 'C' AND OG IN (2,4)
                    THEN '<button type="button" class="vct-btn vct-btn-new vct-btn-sm" '
                       + CASE WHEN SUB_COD = 'ASIGNACION_CONSULTOR' AND @PUEDE_ASIG = 1 THEN @GEST_ASIG
                              WHEN SUB_COD IN ('CARGA_DATOS_ENTRADA','LANZAMIENTO') THEN 'data-vct-pv-goto="lanzamiento"'
                              WHEN SUB_COD IN ('CARGA_PLAN','TRABAJO_PLAN_ITEM') OR ITEM IS NOT NULL THEN 'data-vct-pv-goto="plan" data-vct-pv-plan="co"' + CASE WHEN ITEM IS NOT NULL THEN ' data-vct-pv-plitem="' + CONVERT(VARCHAR(20), ITEM) + '"' ELSE '' END
                              ELSE 'data-vct-pv-goto="acciones"' END
                       + ' title="Gestionar"><span>Gestionar</span></button>'
                    ELSE '' END
             /* menu: proyecto / cliente (manuales) Editar - Cumplida - Eliminar; plan: ver en el plan */
             + CASE WHEN OG IN (1,3) AND @PUEDE_PLAN = 1 THEN
                    '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-edit="ac" data-id="' + CONVERT(VARCHAR(20), ID) + '"'
                  + ' data-f-tipo="' + ISNULL(CONVERT(VARCHAR(20), IDT),'') + '" data-f-sub="' + ISNULL(CONVERT(VARCHAR(20), IDS),'') + '" data-f-prio="' + ISNULL(CONVERT(VARCHAR(20), IDP),'') + '"'
                  + ' data-f-est="' + ISNULL(CONVERT(VARCHAR(20), IDE),'') + '" data-f-res="' + ISNULL(CONVERT(VARCHAR(20), IDR),'') + '"'
                  + ' data-f-ini="' + ISNULL(CONVERT(VARCHAR(10), INI, 120),'') + '" data-f-vence="' + ISNULL(CONVERT(VARCHAR(10), VENCE, 120),'') + '"'
                  + ' data-f-resp="' + RCOD + '" data-f-nom="' + CASE WHEN RT = 'OTRO' THEN REPLACE(REPLACE(REPLACE(REPLACE(RESP,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') ELSE '' END + '"'
                  + ' data-f-obs="' + REPLACE(REPLACE(REPLACE(REPLACE(DETF,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="edit"></span><span>Editar</span></button>'
                  + CASE WHEN SIT = 'C' AND EST_COD = 'CUMPLIDA' THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_AC_ESTADO" data-t11="PENDIENTE" data-id="' + CONVERT(VARCHAR(20), ID) + '" data-msg="&iquest;Reabrir la acci&oacute;n?"><span data-vct-icon="rotate-ccw"></span><span>Reabrir</span></button>'
                         WHEN SIT <> 'C' THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_AC_ESTADO" data-t11="CUMPLIDA" data-id="' + CONVERT(VARCHAR(20), ID) + '" data-msg="&iquest;Marcar la acci&oacute;n como cumplida?"><span data-vct-icon="check"></span><span>Marcar cumplida</span></button>'
                         ELSE '' END
                  + CASE WHEN EST_COD <> 'CANCELADA' THEN '<button type="button" class="vct-pv-menu-btn" data-vct-pv-confirm="PV_AC_BORRAR" data-id="' + CONVERT(VARCHAR(20), ID) + '" data-nombre="' + REPLACE(REPLACE(REPLACE(REPLACE(TIPO + CASE WHEN SUB_DES <> '' THEN ' - ' + SUB_DES ELSE '' END,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="trash"></span><span>Eliminar</span></button>' ELSE '' END
                  + '</div></span>'
                    WHEN OG = 2 THEN
                    '<span class="vct-pl-menu">' + @PL_TRIG + '<div class="vctdg-rowmenu-items" hidden>'
                  + '<button type="button" class="vct-pv-menu-btn" data-vct-pv-goto="plan" data-vct-pv-plan="co" data-vct-pv-plitem="' + CONVERT(VARCHAR(20), ITEM) + '"'
                  + ' title="' + REPLACE(REPLACE(REPLACE(REPLACE(ITEM_TIT,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;') + '"><span data-vct-icon="list-checks"></span><span>Ver en el plan</span></button>'
                  + '</div></span>'
                    ELSE '' END
             + '</div></td></tr>'
        FROM #A
        ORDER BY OG, CREA DESC, ID DESC   /* por grupo; dentro del grupo la mas nueva arriba */
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    /* chips de origen (con cantidad) y el filtro oculto que los aplica en la grilla */
    SELECT @AC_CHIPS = ISNULL((SELECT '<button type="button" class="vct-pv-acchip' + CASE WHEN N = 0 THEN ' is-zero' ELSE '' END + '" data-pv-acchip="' + K + '" data-pv-acchip-lbl="' + L + '"'
                                    + ' data-pv-acchip-ab="' + CONVERT(VARCHAR(10), AB) + '" data-pv-acchip-ve="' + CONVERT(VARCHAR(10), VE) + '">'
                                    + L + '<i>' + CONVERT(VARCHAR(10), N) + '</i></button>'
        /* los 4 grupos siempre visibles (con 0 si no tienen acciones) */
        FROM (SELECT G.OG, G.K, G.L, COUNT(A.ID) AS N,
                     ISNULL(SUM(CASE WHEN A.SIT <> 'C' THEN 1 ELSE 0 END), 0) AS AB, ISNULL(SUM(CASE WHEN A.SIT = 'V' THEN 1 ELSE 0 END), 0) AS VE
              FROM (SELECT 1 AS OG, 'proyecto' AS K, 'Proyecto' AS L UNION ALL SELECT 2, 'plan', 'Plan estrat&eacute;gico'
                    UNION ALL SELECT 3, 'cliente', 'Pendientes del cliente' UNION ALL SELECT 4, 'workflow', 'Workflow') G
              LEFT JOIN #A A ON A.OG = G.OG
              GROUP BY G.OG, G.K, G.L) Z
        ORDER BY OG FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @AC_F_CAP = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), CAPI) + '">' + REPLACE(REPLACE(REPLACE(CAP_LBL,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
        FROM (SELECT DISTINCT CAPI, CAP_ORD, CAP_LBL FROM #A WHERE CAPI IS NOT NULL) Z
        ORDER BY CAP_ORD, CAPI FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SET @AC_NOPT = '<option value="proyecto">Proyecto</option><option value="plan">Plan</option><option value="cliente">Cliente</option><option value="workflow">Workflow</option>';

    SELECT @AC_F_EST = ISNULL((SELECT '<option value="' + K + '">' + D + '</option>' FROM (
        SELECT DISTINCT CASE WHEN SIT = 'V' THEN 'VENCIDA' ELSE EST_COD END AS K, CASE WHEN SIT = 'V' THEN 'Vencida' ELSE EST_DES END AS D FROM #A) Z
        ORDER BY D FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @AC_F_AREA = ISNULL((SELECT '<option value="' + REPLACE(AREA,'"','') + '">' + REPLACE(REPLACE(AREA,'<','&lt;'),'>','&gt;') + '</option>' FROM (SELECT DISTINCT AREA FROM #A WHERE AREA <> '') Z
        ORDER BY AREA FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    SELECT @AC_F_TIPO = ISNULL((SELECT '<option value="' + REPLACE(TIPO,'"','') + '">' + REPLACE(REPLACE(TIPO,'<','&lt;'),'>','&gt;') + '</option>' FROM (SELECT DISTINCT TIPO FROM #A WHERE TIPO <> '') Z
        ORDER BY TIPO FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @H = @H + '<div class="vct-360-panel" data-vct-panel="acciones"><div class="vct-360-box vct-360-box-grid-auto vctdg-in-box" data-pv-acbox>'
        + '<div class="vct-360-box-head"><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>Acciones (' + CONVERT(VARCHAR(10), @N_TOT_ACC) + ')</h3></div>'
        + CASE WHEN @AC <> '' THEN '<div class="vct-pv-acchips" data-pv-acchips><button type="button" class="vct-pv-acchip is-on" data-pv-acchip="">Todas<i>' + CONVERT(VARCHAR(10), @N_TOT_ACC) + '</i></button>' + @AC_CHIPS + '</div>' ELSE '' END
        + CASE WHEN @AC = '' THEN
              CASE WHEN @PUEDE_PLAN = 1 THEN '<div class="vct-pv-ac-empty"><div class="vct-360-empty">Sin acciones.</div><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="ac" data-id="0"><span data-vct-icon="plus"></span><span>Agregar acci&oacute;n</span></button></div>'
                   ELSE '<div class="vct-360-empty">Sin acciones.</div>' END
          ELSE
          '<div data-vct-dg data-vct-dg-id="pv_acciones" data-vct-dg-title="Acciones del proyecto" data-vct-dg-subtitle="Proyecto (' + @E_COD + ')" data-vct-dg-unit="acci&oacute;n(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar acci&oacute;n, responsable..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'
        + '<div class="vct-pv-acorig-wrap" hidden aria-hidden="true" style="display:none !important"><select data-vct-dg-filter="origen" data-pv-acorig tabindex="-1"><option value=""></option>' + @AC_NOPT + '</select></div>'
        + '<div data-vct-dg-slot="filters">'
        +   CASE WHEN @AC_F_CAP <> '' THEN '<select data-vct-dg-filter="cap" data-pv-accap aria-label="Cap&iacute;tulo"><option value="">Cap&iacute;tulo</option>' + @AC_F_CAP + '</select>' ELSE '' END
        +   '<select data-vct-dg-filter="estado" aria-label="Estado"><option value="">Estado</option>' + @AC_F_EST + '</select>'
        +   '<select data-vct-dg-filter="area" aria-label="&Aacute;rea"><option value="">&Aacute;rea</option>' + @AC_F_AREA + '</select>'
        +   '<select data-vct-dg-filter="tipo" aria-label="Tipo"><option value="">Tipo</option>' + @AC_F_TIPO + '</select></div>'
        + CASE WHEN @PUEDE_PLAN = 1 THEN '<div data-vct-dg-slot="actions"><button type="button" class="vct-btn vct-btn-new vct-btn-sm" data-vct-pv-new="ac" data-id="0" title="Agregar acci&oacute;n"><span data-vct-icon="plus"></span><span>Agregar</span></button></div>' ELSE '' END
        + '<table><thead><tr><th data-vct-sort="a" data-vct-sortable="true"><span>Acci&oacute;n</span></th><th data-vct-width="14%"><span>&Aacute;rea</span></th>'
        + '<th class="vct-text-center" data-vct-width="70"><span>Resp.</span></th><th class="vct-text-center" data-vct-width="130" data-vct-sort="e" data-vct-sortable="true"><span>Estado</span></th>'
        + '<th class="vct-text-center" data-vct-width="130" data-vct-sort="f" data-vct-sortable="true"><span>Fecha</span></th><th class="vct-col-action" data-vct-width="140" data-vct-export-ignore="true"></th></tr></thead><tbody>'
        + @AC + '</tbody></table></div>' END
        + '</div></div>';

    /* ======================= PESTANIAS DE PASOS SIGUIENTES ======================= */
    SET @H = @H
        + @PL_H
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

            /* riesgo (PV_LZ_RIESGOS_V1) */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-sm" data-vct-component="modal" data-vct-pv-modal="ri" data-vct-pv-cmd="PV_RI_GUARDAR" data-vct-pv-tnew="Agregar riesgo" data-vct-pv-tedit="Editar riesgo">'
            + REPLACE(REPLACE(@MH, '<span data-vct-icon="{ICON}"></span>', '<span class="vct-pv-ic-pulse"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg></span>'), '{TIT}', 'Riesgo')
            + '<div class="vct-field vct-col-6"><label class="vct-label">Nivel de riesgo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="nivel" data-vct-pv-buf="TEXTO11" data-req="Nivel de riesgo" data-vct-pv-def="' + @E_RI_ACT + '"><option value="">Seleccione</option><option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></select>'
            +   '<div class="vct-help">Viene el nivel actual del proyecto' + CASE WHEN @E_RI_ACT = '' THEN ' (sin definir)' ELSE ' (' + @E_RI_ACT + ')' END + '. Si lo cambi&aacute;s, se actualiza el del proyecto.</div></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Riesgo <span class="vct-req">*</span></label>'
            +   '<textarea class="vct-textarea" rows="4" maxlength="2000" data-vct-pv-f="texto" data-vct-pv-buf="TEXTO12" data-req="Riesgo"></textarea></div>'
            + '</div></div>' + @MF

            /* reunion (PV_LZ_REUNIONES_V1) */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-lg" data-vct-component="modal" data-vct-pv-modal="re" data-vct-pv-cmd="PV_RE_GUARDAR" data-vct-pv-tnew="Agregar reuni&oacute;n" data-vct-pv-tedit="Editar reuni&oacute;n">'
            + REPLACE(REPLACE(@MH, '{ICON}', 'calendar'), '{TIT}', 'Reuni&oacute;n')
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
            + '<div class="vct-field vct-col-12"><label class="vct-pv-switch"><input type="checkbox" data-vct-pv-f="realizada" data-vct-pv-buf="TEXTO15"><span>Es la reuni&oacute;n de lanzamiento realizada (cumple la acci&oacute;n Reuni&oacute;n de lanzamiento)</span></label>'
            + CASE WHEN @RE_FECHA IS NULL THEN '' ELSE '<div class="vct-help">Solo una reuni&oacute;n es la de lanzamiento (hoy: ' + CONVERT(VARCHAR(10), @RE_FECHA, 103) + '). Si la destild&aacute;s, la acci&oacute;n vuelve a pendiente.</div>' END + '</div>'
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
            + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>'
            /* agregar / editar servicio (PV_SV_EDIT_V1) */
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-sm" data-vct-component="modal" data-vct-pv-modal="sv" data-vct-pv-cmd="PV_SV_GUARDAR" data-vct-pv-tnew="Agregar servicio" data-vct-pv-tedit="Editar servicio">'
            + '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
            + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="briefcase"></span></div>'
            + '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-pv-mtitle>Servicio</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
            + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
            + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Servicio <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="srv" data-vct-pv-buf="TEXTO11" data-req="Servicio" data-vct-pv-svsel><option value="">Seleccione</option>' + @SV_OPT + '</select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Nombre</label>'
            +   '<input type="text" class="vct-input" maxlength="100" placeholder="Ej.: Auditor&iacute;a interna" data-vct-pv-f="nom" data-vct-pv-buf="TEXTO12"></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Lugar</label>'
            +   '<input type="text" class="vct-input" maxlength="100" placeholder="Ej.: planta Rosario" data-vct-pv-f="lugar" data-vct-pv-buf="TEXTO13"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fecha inicio <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="ini" data-vct-pv-buf="TEXTO14" data-req="Fecha inicio" min="' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 120), '') + '" max="' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 120), '') + '"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fecha fin <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="fin" data-vct-pv-buf="TEXTO15" data-req="Fecha fin" min="' + ISNULL(CONVERT(VARCHAR(10), @F_INI, 120), '') + '" max="' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 120), '') + '"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Horas proyectadas <span class="vct-req">*</span></label>'
            +   '<input type="number" class="vct-input" min="1" max="999999" step="1" data-vct-pv-f="hrs" data-vct-pv-buf="TEXTO16" data-req="Horas proyectadas"></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-help">Se agregan auditor&iacute;as y capacitaciones (cada una es una instancia propia); la consultor&iacute;a solo se carga en el alta. Las fechas van dentro del plazo del proyecto ('
            +   ISNULL(CONVERT(VARCHAR(10), @F_INI, 103), '-') + ' &rarr; ' + ISNULL(CONVERT(VARCHAR(10), @F_FIN, 103), '-') + ') y las horas proyectadas del proyecto pasan a ser la suma de sus servicios.</div></div>'
            + '</div></div>'
            + '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
            + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>';
    END;

    DECLARE @PL_MODALS VARCHAR(MAX) = '', @PMH VARCHAR(MAX), @PMF VARCHAR(MAX);
    /* tipificacion de la accion del plan (parametria de acciones, solo activos) PL_ACC_TIPIF_V1 */
    DECLARE @PA_OTIPO VARCHAR(MAX) = '', @PA_OSUB VARCHAR(MAX) = '', @PA_OPRIO VARCHAR(MAX) = '', @PA_OEST VARCHAR(MAX) = '', @PA_ORES VARCHAR(MAX) = '',
            @PA_DTIPO VARCHAR(20) = '', @PA_DSUB VARCHAR(20) = '', @PA_DPRIO VARCHAR(20) = '', @PA_DEST VARCHAR(20) = '',
            @AC_OTIPO VARCHAR(MAX) = '', @AC_OSUB VARCHAR(MAX) = '';
    IF @PUEDE_PLAN = 1
    BEGIN
        /* AC_TIPIF_V1: el modal muestra solo los subtipos de carga manual de su ambito (VCT_PRM_ACCIONES_SUBTIPOS.CARGA_MANUAL);
           los tipos salen de esos subtipos. Los de SISTEMA solo los genera el workflow. */
        SELECT @PA_OTIPO = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), T.ID) + '">' + REPLACE(REPLACE(REPLACE(T.DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) WHERE T.ACTIVO = 1
              AND EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS S WITH(NOLOCK) WHERE S.ID_TIPO = T.ID AND S.ACTIVO = 1 AND S.CARGA_MANUAL IN ('PLAN','AMBOS'))
            ORDER BY T.ORDEN, T.DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OSUB = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '" data-tipo="' + CONVERT(VARCHAR(20), ID_TIPO) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE ACTIVO = 1 AND CARGA_MANUAL IN ('PLAN','AMBOS') ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @AC_OTIPO = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), T.ID) + '">' + REPLACE(REPLACE(REPLACE(T.DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) WHERE T.ACTIVO = 1
              AND EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS S WITH(NOLOCK) WHERE S.ID_TIPO = T.ID AND S.ACTIVO = 1 AND S.CARGA_MANUAL IN ('PROYECTO','AMBOS'))
            ORDER BY T.ORDEN, T.DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @AC_OSUB = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '" data-tipo="' + CONVERT(VARCHAR(20), ID_TIPO) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WITH(NOLOCK) WHERE ACTIVO = 1 AND CARGA_MANUAL IN ('PROYECTO','AMBOS') ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OPRIO = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY NIVEL, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_OEST = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '" data-final="' + CASE WHEN ES_FINAL = 1 THEN '1' ELSE '0' END + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE ACTIVO = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
        SELECT @PA_ORES = ISNULL((SELECT '<option value="' + CONVERT(VARCHAR(20), ID) + '">' + REPLACE(REPLACE(REPLACE(DESCRIPCION,'&','&amp;'),'<','&lt;'),'>','&gt;') + '</option>'
            FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE ACTIVO = 1 AND CARGA_MANUAL = 1 ORDER BY ORDEN, DESCRIPCION FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
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
            + '<div class="vct-field vct-col-12" data-vct-pv-only-top><label class="vct-label">Cap&iacute;tulo</label>'
            +   '<select data-vct-pv-f="cap" data-vct-pv-buf="TEXTO19" data-vct-pv-def=""><option value="">Sin cap&iacute;tulo (Otros &iacute;tems)</option>' + @PL_COPT + '</select></div>'
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
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-md" data-vct-component="modal" data-vct-pv-modal="pa" data-vct-pv-cmd="PV_PL_ACC_GUARDAR" data-vct-pv-tnew="Nueva acci&oacute;n del plan" data-vct-pv-tedit="Editar acci&oacute;n del plan">'
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
            + '<div class="vct-field vct-col-6"><label class="vct-label">Responsable <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="resp" data-vct-pv-buf="TEXTO15" data-req="Responsable" data-vct-pv-resp><option value="">-</option>' + @PA_ROPT + '</select></div>'
            + '<div class="vct-field vct-col-6" data-vct-pv-otro hidden><label class="vct-label">Nombre del responsable <span class="vct-req">*</span></label>'
            +   '<div class="vct-pv-otro-in"><span class="vctdg-avatar is-x" data-vct-pv-otro-ini>?</span><input type="text" class="vct-input" maxlength="150" placeholder="Ej.: Juan P&eacute;rez" data-vct-pv-f="nom" data-vct-pv-buf="TEXTO11"></div>'
            +   '<div class="vct-help">El badge toma las iniciales del nombre.</div></div>'
            + '<input type="hidden" data-vct-pv-f="accid" data-vct-pv-buf="TEXTO14" data-vct-pv-def="">'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Detalle</label>'
            +   '<textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO18"></textarea></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-help">El t&iacute;tulo de la acci&oacute;n se arma con el subtipo y el &iacute;tem. Las fechas tienen que estar dentro del rango del &iacute;tem. El resultado se pide solo si el estado es final.</div></div>'
            + '</div></div>' + @PMF;
    END;
    /* accion del proyecto (pestania Acciones, AC_PESTANIA_V1): mismo modelo de la accion del plan, sin item */
    DECLARE @AC_MODAL VARCHAR(MAX) = '', @AC_DPRIO VARCHAR(20) = '', @AC_DEST VARCHAR(20) = '';
    IF @PUEDE_PLAN = 1
    BEGIN
        SELECT @AC_DPRIO = CONVERT(VARCHAR(20), ID) FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WITH(NOLOCK) WHERE CODIGO = 'NORMAL' AND ACTIVO = 1;
        SELECT @AC_DEST = CONVERT(VARCHAR(20), ID) FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'PENDIENTE' AND ACTIVO = 1;
        SET @AC_MODAL = CONVERT(VARCHAR(MAX), '')
            + '<div class="vct-modal vct-form-shell vct-pv-modal vct-pv-w-md" data-vct-component="modal" data-vct-pv-modal="ac" data-vct-pv-cmd="PV_AC_GUARDAR" data-vct-pv-tnew="Nueva acci&oacute;n del proyecto" data-vct-pv-tedit="Editar acci&oacute;n del proyecto">'
            + '<div class="vct-modal-backdrop" data-vct-pv-close></div><div class="vct-modal-dialog">'
            + '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div><div class="vct-form-header-icon"><span data-vct-icon="clipboard-check"></span></div>'
            + '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-pv-mtitle>Nueva acci&oacute;n del proyecto</h3><p class="vct-modal-subtitle">Proyecto (' + @E_COD + ') &middot; ' + @E_CLI + '</p></div>'
            + '<button type="button" class="vct-form-close" data-vct-pv-close aria-label="Cerrar">&times;</button></div>'
            + '<div class="vct-modal-body vct-form-body"><div class="vct-validation-box" data-vct-pv-error style="display:none;"></div><div class="vct-form-grid">'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Tipo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="tipo" data-vct-pv-buf="TEXTO21" data-req="Tipo" data-vct-pv-def="" data-vct-pv-tipo><option value="">-</option>' + @AC_OTIPO + '</select></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Subtipo <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="sub" data-vct-pv-buf="TEXTO16" data-req="Subtipo" data-vct-pv-def="" data-vct-pv-sub-tipo><option value="">-</option>' + @AC_OSUB + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Prioridad <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="prio" data-vct-pv-buf="TEXTO17" data-req="Prioridad" data-vct-pv-def="' + @AC_DPRIO + '"><option value="">-</option>' + @PA_OPRIO + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Estado <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="est" data-vct-pv-buf="TEXTO19" data-req="Estado" data-vct-pv-def="' + @AC_DEST + '" data-vct-pv-estado><option value="">-</option>' + @PA_OEST + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Resultado <span class="vct-req" data-vct-pv-res-req hidden>*</span></label>'
            +   '<select data-vct-pv-f="res" data-vct-pv-buf="TEXTO20" data-vct-pv-def="" data-vct-pv-resultado><option value="">-</option>' + @PA_ORES + '</select></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Fecha inicio</label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="ini" data-vct-pv-buf="TEXTO13"></div>'
            + '<div class="vct-field vct-col-4"><label class="vct-label">Vence <span class="vct-req">*</span></label>'
            +   '<input type="date" class="vct-input" data-vct-datepicker data-vct-pv-f="vence" data-vct-pv-buf="TEXTO12" data-req="Vence"></div>'
            + '<div class="vct-field vct-col-4"></div>'
            + '<div class="vct-field vct-col-6"><label class="vct-label">Responsable <span class="vct-req">*</span></label>'
            +   '<select data-vct-pv-f="resp" data-vct-pv-buf="TEXTO15" data-req="Responsable" data-vct-pv-resp><option value="">-</option>' + @PA_ROPT + '</select></div>'
            + '<div class="vct-field vct-col-6" data-vct-pv-otro hidden><label class="vct-label">Nombre del responsable <span class="vct-req">*</span></label>'
            +   '<div class="vct-pv-otro-in"><span class="vctdg-avatar is-x" data-vct-pv-otro-ini>?</span><input type="text" class="vct-input" maxlength="150" placeholder="Ej.: Juan P&eacute;rez" data-vct-pv-f="nom" data-vct-pv-buf="TEXTO11"></div>'
            +   '<div class="vct-help">El badge toma las iniciales del nombre.</div></div>'
            + '<div class="vct-field vct-col-12"><label class="vct-label">Detalle</label>'
            +   '<textarea class="vct-textarea" rows="2" maxlength="2000" data-vct-pv-f="obs" data-vct-pv-buf="TEXTO18"></textarea></div>'
            + '<div class="vct-field vct-col-12"><div class="vct-help">Acciones del proyecto fuera del plan. Las del plan se cargan desde su &iacute;tem; las del workflow (alta, asignaciones, datos de entrada, lanzamiento) las genera el sistema. El resultado se pide solo si el estado es final.</div></div>'
            + '</div></div>'
            + '<div class="vct-modal-footer vct-form-footer"><button type="button" class="vct-btn vct-btn-secondary" data-vct-pv-close><span>Cancelar</span></button>'
            + '<button type="button" class="vct-btn vct-btn-primary" data-vct-pv-save><span data-vct-icon="save"></span><span>Guardar</span></button></div></div></div>';
    END;

    SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + @ASSETS
        + '<div class="vct-page vct-page-main" data-vct-page data-vct-sidebar-id="3" data-vct-form-id="' + REPLACE(ISNULL(@FORM_ID,''),'"','') + '">'
        + '<section class="vct-module vct-360-module vct-cliente360-module vct-360-visual-final vct-pv" data-vct-module data-vct-pv data-vct-entity-theme="cliente"'
        + ' data-vct-tabs data-vct-tabs-active="resumen" data-vct-tabs-reset="0" data-vct-pv-proyecto="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '"'
        + ' data-vct-pv-guid="' + REPLACE(@GUID_V360,'"','') + '"' + CASE WHEN @MSG <> '' OR @ERR <> '' THEN ' data-vct-pv-volver="' + @VOLVER + '"' ELSE '' END + '>'
        + @H + @MODAL
        + @LZ_MODALS + @PL_MODALS + @AC_MODAL + @PE_MODAL /* SP_IDSELEC02_V1 */
        + '<input type="hidden" name="SP.IDSELEC02" data-vct-field="IDSELEC02" value="' + CONVERT(VARCHAR(20), @ID_PROYECTO) + '">'
        + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" value=""><input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" value="">'
        + '<input type="hidden" name="SP.TEXTO11" data-vct-field="TEXTO11" value=""><input type="hidden" name="SP.TEXTO12" data-vct-field="TEXTO12" value="">'
        + '<input type="hidden" name="SP.TEXTO13" data-vct-field="TEXTO13" value=""><input type="hidden" name="SP.TEXTO14" data-vct-field="TEXTO14" value=""><input type="hidden" name="SP.TEXTO15" data-vct-field="TEXTO15" value=""><input type="hidden" name="SP.TEXTO16" data-vct-field="TEXTO16" value=""><input type="hidden" name="SP.TEXTO17" data-vct-field="TEXTO17" value=""><input type="hidden" name="SP.TEXTO18" data-vct-field="TEXTO18" value=""><input type="hidden" name="SP.TEXTO19" data-vct-field="TEXTO19" value=""><input type="hidden" name="SP.TEXTO20" data-vct-field="TEXTO20" value=""><input type="hidden" name="SP.TEXTO21" data-vct-field="TEXTO21" value=""><input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" value="">'
        + '</section></div>';
END
GO

DECLARE @TRG BIT;
SELECT @TRG = TRG FROM #P2V;
IF OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')) LIKE '%PV_PLAN_V1%'
    PRINT 'OK   dbo.VCT_MAIN_PROYECTO_V360 reemplazado (lanzamiento y parte logistico).';
ELSE
    PRINT 'FALLO dbo.VCT_MAIN_PROYECTO_V360 no se actualizo: revisar el error de arriba.';
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
