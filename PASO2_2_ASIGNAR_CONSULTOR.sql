/* ========================================================================
   PASO2_2_ASIGNAR_CONSULTOR
   ------------------------------------------------------------------------
   Crea dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR: graba la asignacion que hace el
   analista desde la V360 de Proyecto (modal "Asignar consultor", boceto
   paso3). Documento funcional, seccion 7 "Que pasa al confirmar":
     1. VCT_PROYECTOS_EQUIPO: alta del consultor en el proyecto (sin
        servicio, sin horas: las horas salen de la agenda).
     2. Si el rol es CONSULTOR_LIDER: la accion abierta de subtipo
        ASIGNACION_CONSULTOR del proyecto pasa a CUMPLIDA y se generan las
        acciones de las reglas del evento CONSULTORES_ASIGNADOS (una sola
        vez por proyecto). El responsable de cada accion es el integrante
        del equipo con el rol DESTINATARIO_ROL de la regla.
     3. Despues del COMMIT, mail al consultor con la plantilla
        PROYECTO_CONSULTOR_ASIGNADO de VCT_PRM_EMAIL_TEMPLATES (destino y CC
        los resuelve dbo.VCT_MAIN_SEND_EMAIL con @ID_CONSULTOR). Si la
        plantilla no existe o falla, la asignacion queda y se registra en
        VCT_ACCIONES_HISTORIAL. Las reglas con GENERA_EMAIL = 1 mandan su
        plantilla (ID_EMAIL_TEMPLATE).
   Permiso: responsable de la accion abierta ASIGNACION_CONSULTOR del
   proyecto, o accion EDIT del modulo PROYECTOS (VCT_MAIN_GET_ACTIONS).
   Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
DECLARE @TRG BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG = 1;
END;
IF OBJECT_ID('tempdb..#P2A') IS NOT NULL DROP TABLE #P2A;
CREATE TABLE #P2A (TRG BIT);
INSERT INTO #P2A VALUES (@TRG);
IF OBJECT_ID('dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR') IS NULL
    EXEC ('CREATE PROCEDURE dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR AS RETURN 0;');
GO

ALTER PROCEDURE dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR
(
    @IUNIDAD      VARCHAR(100),
    @IAGENTE      VARCHAR(100),
    @ID_PROYECTO  INT,
    @ID_CONSULTOR INT,
    @ID_ROL       INT,
    @VENCE        DATETIME = NULL,
    @OBS          VARCHAR(MAX) = NULL,
    @EMAIL_EXTRA  VARCHAR(500) = NULL,   /* CC del mail al consultor; destino si el consultor no tiene email */
    @ERROR        VARCHAR(1000) OUTPUT,
    @MENSAJE      VARCHAR(1000) OUTPUT
)
AS
BEGIN
    /* VCT_PROYECTO_ASIGNAR_CONSULTOR_V1 - V2: email adicional - V3: email obligatorio si el consultor no tiene */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ERROR = '';
    SET @MENSAJE = '';

    DECLARE @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))),
            @HOY DATETIME = CONVERT(DATETIME, CONVERT(DATE, GETDATE())),
            @EMP_U INT, @CONS_U INT,
            @COD VARCHAR(100), @NOM VARCHAR(300), @CLI INT,
            @ROL_COD VARCHAR(50), @ROL_DES VARCHAR(150), @ES_LIDER BIT = 0,
            @CONS_NOM VARCHAR(300), @ANALISTA INT,
            @ID_ACC_ASIG INT, @EST_CUMP INT, @EST_ANT INT, @ID_RES INT,
            @PUEDE BIT = 0, @YA_DISPARADO BIT = 0, @GEN_TXT VARCHAR(1000) = '';

    SELECT TOP 1 @EMP_U = ID FROM dbo.VCT_EMPLEADOS WITH(NOLOCK)
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U ORDER BY ID DESC;
    SELECT TOP 1 @CONS_U = ID FROM dbo.VCT_CONSULTORES WITH(NOLOCK)
    WHERE LOWER(LTRIM(RTRIM(ISNULL(ID_USUARIO_SEGURIDAD,'')))) = @U ORDER BY ID DESC;

    /* ---------- validaciones (en orden, la primera que falla) ---------- */
    SELECT @COD = P.CODIGO, @NOM = P.NOMBRE, @CLI = P.IDCLIENTE
    FROM dbo.VCT_PROYECTOS P WITH(NOLOCK) WHERE P.ID = @ID_PROYECTO;
    IF @COD IS NULL AND @NOM IS NULL BEGIN SET @ERROR = 'El proyecto no existe.'; RETURN; END;

    IF @ID_CONSULTOR IS NULL BEGIN SET @ERROR = 'Seleccione un consultor.'; RETURN; END;
    SELECT @CONS_NOM = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150), C.APELLIDOS),'') + ', ' + ISNULL(CONVERT(VARCHAR(150), C.NOMBRES),'')))
    FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
    WHERE C.ID = @ID_CONSULTOR AND UPPER(ISNULL(C.ESTADO,'ACTIVO')) = 'ACTIVO';
    IF @CONS_NOM IS NULL BEGIN SET @ERROR = 'El consultor no existe o no est' + CHAR(225) + ' activo.'; RETURN; END;

    IF @ID_ROL IS NULL BEGIN SET @ERROR = 'Rol es obligatorio.'; RETURN; END;
    SELECT @ROL_COD = R.CODIGO, @ROL_DES = R.DESCRIPCION
    FROM dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK)
    WHERE R.ID = @ID_ROL AND R.TIPO_MIEMBRO = 'CONSULTOR';
    IF @ROL_COD IS NULL BEGIN SET @ERROR = 'El rol no corresponde a un consultor (VCT_PRM_PROYECTOS_ROLES).'; RETURN; END;
    SET @ES_LIDER = CASE WHEN @ROL_COD = 'CONSULTOR_LIDER' THEN 1 ELSE 0 END;

    IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK)
               WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR' AND ID_CONSULTOR = @ID_CONSULTOR AND ESTADO = 'ACTIVO')
    BEGIN SET @ERROR = @CONS_NOM + ' ya est' + CHAR(225) + ' asignado al proyecto.'; RETURN; END;

    IF @ES_LIDER = 1 AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK)
                                 WHERE ID_PROYECTO = @ID_PROYECTO AND ID_ROL = @ID_ROL AND ESTADO = 'ACTIVO')
    BEGIN SET @ERROR = 'El proyecto ya tiene ' + @ROL_DES + '.'; RETURN; END;

    /* email adicional: direcciones separadas por ; con formato x@y.z */
    SET @EMAIL_EXTRA = LTRIM(RTRIM(REPLACE(ISNULL(@EMAIL_EXTRA,''), ',', ';')));
    IF @EMAIL_EXTRA <> ''
    BEGIN
        DECLARE @EX VARCHAR(600) = @EMAIL_EXTRA + ';', @EXP INT, @EXI VARCHAR(300);
        SET @EXP = CHARINDEX(';', @EX);
        WHILE @EXP > 0
        BEGIN
            SET @EXI = LTRIM(RTRIM(LEFT(@EX, @EXP - 1)));
            SET @EX = SUBSTRING(@EX, @EXP + 1, 600);
            IF @EXI <> '' AND (@EXI NOT LIKE '%_@_%._%' OR CHARINDEX(' ', @EXI) > 0 OR @EXI LIKE '%@%@%')
            BEGIN SET @ERROR = 'Email adicional: "' + @EXI + '" no es una direcci' + CHAR(243) + 'n v' + CHAR(225) + 'lida.'; RETURN; END;
            SET @EXP = CHARINDEX(';', @EX);
        END;
    END;

    /* sin mail principal del consultor, el email adicional es obligatorio */
    IF @EMAIL_EXTRA = '' AND NOT EXISTS (SELECT 1 FROM dbo.VCT_EMAILS M WITH(NOLOCK)
                                         WHERE M.TIPO_ENTIDAD = 'CONSULTOR' AND M.ID_ENTIDAD = @ID_CONSULTOR AND M.PRINCIPAL = 'SI'
                                           AND LTRIM(RTRIM(ISNULL(M.EMAIL,''))) <> '')
    BEGIN SET @ERROR = @CONS_NOM + ' no tiene email cargado: ingrese un email para enviarle el aviso.'; RETURN; END;

    IF @VENCE IS NOT NULL AND @VENCE < @HOY
    BEGIN SET @ERROR = 'Vence pr' + CHAR(243) + 'xima acci' + CHAR(243) + 'n no puede ser anterior a hoy.'; RETURN; END;

    /* accion abierta "Asignar consultor" del proyecto (subtipo ASIGNACION_CONSULTOR) */
    SELECT TOP 1 @ID_ACC_ASIG = A.ID, @EST_ANT = A.ID_ESTADO
    FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = A.ID_SUBTIPO AND ST.CODIGO = 'ASIGNACION_CONSULTOR'
    INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO AND E.ES_FINAL = 0
    WHERE A.ID_PROYECTO = @ID_PROYECTO
    ORDER BY A.ID;

    /* permiso: responsable de esa accion, o EDIT de PROYECTOS */
    IF @ID_ACC_ASIG IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK)
        WHERE AP.ID_ACCION = @ID_ACC_ASIG AND AP.ROL_PARTICIPANTE = 'RESPONSABLE' AND AP.ESTADO = 'ACTIVO'
          AND ((AP.TIPO_ENTIDAD = 'EMPLEADO' AND AP.ID_ENTIDAD = @EMP_U) OR (AP.TIPO_ENTIDAD = 'CONSULTOR' AND AP.ID_ENTIDAD = @CONS_U)))
        SET @PUEDE = 1;
    IF @PUEDE = 0 AND EXISTS (SELECT 1 FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD, 'PROYECTOS') A WHERE UPPER(ISNULL(A.ACTION_TYPE,'')) = 'EDIT')
        SET @PUEDE = 1;
    IF @PUEDE = 0 BEGIN SET @ERROR = 'No tiene permiso para asignar consultores en este proyecto.'; RETURN; END;

    SELECT @EST_CUMP = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK) WHERE CODIGO = 'CUMPLIDA';
    SELECT @ID_RES = ID FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WITH(NOLOCK) WHERE CODIGO = 'CONSULTOR_ASIGNADO';
    IF @ES_LIDER = 1 AND @EST_CUMP IS NULL BEGIN SET @ERROR = 'Falta el estado CUMPLIDA en VCT_PRM_ACCIONES_ESTADOS.'; RETURN; END;

    SELECT TOP 1 @ANALISTA = EQ.ID_EMPLEADO
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ESTADO = 'ACTIVO'
    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

    /* reglas del evento CONSULTORES_ASIGNADOS (solo al asignar el lider, una vez por proyecto) */
    DECLARE @RG TABLE (ID INT, CODIGO VARCHAR(100), ID_TIPO INT, ID_SUBTIPO INT, ID_ESTADO INT, ID_PRIORIDAD INT,
                       ROL VARCHAR(100), TITULO VARCHAR(300), DETALLE VARCHAR(MAX), DIAS INT, MAIL BIT, ID_TPL INT,
                       ES_FINAL BIT, TIPO_ENT VARCHAR(20), ID_ENT INT, ID_ACCION INT, SUB_DES VARCHAR(150));
    IF @ES_LIDER = 1
    BEGIN
        INSERT INTO @RG (ID, CODIGO, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ROL, TITULO, DETALLE, DIAS, MAIL, ID_TPL, ES_FINAL, SUB_DES)
        SELECT R.ID, R.CODIGO, R.ID_TIPO, R.ID_SUBTIPO, R.ID_ESTADO_INICIAL, R.ID_PRIORIDAD, LTRIM(RTRIM(ISNULL(R.DESTINATARIO_ROL,''))),
               R.TITULO_PLANTILLA, R.DETALLE_PLANTILLA, R.DIAS_VENCIMIENTO, R.GENERA_EMAIL, R.ID_EMAIL_TEMPLATE, ISNULL(E.ES_FINAL, 0), ST.DESCRIPCION
        FROM dbo.VCT_PRM_ACCIONES_REGLAS R WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = R.ID_ESTADO_INICIAL
        LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST WITH(NOLOCK) ON ST.ID = R.ID_SUBTIPO
        WHERE R.CODIGO_EVENTO = 'CONSULTORES_ASIGNADOS' AND R.ACTIVO = 1;

        IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WITH(NOLOCK) INNER JOIN @RG G ON G.ID = A.ID_REGLA_ORIGEN WHERE A.ID_PROYECTO = @ID_PROYECTO)
            SET @YA_DISPARADO = 1;
        IF @YA_DISPARADO = 1 DELETE FROM @RG;

        /* responsable = integrante del equipo con el rol de la regla (el lider nuevo cuenta) */
        UPDATE G SET
            TIPO_ENT = CASE WHEN R.CODIGO = @ROL_COD THEN 'CONSULTOR' ELSE X.TIPO_MIEMBRO END,
            ID_ENT   = CASE WHEN R.CODIGO = @ROL_COD THEN @ID_CONSULTOR ELSE X.ID_ENT END
        FROM @RG G
        LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.CODIGO = G.ROL
        OUTER APPLY (SELECT TOP 1 EQ.TIPO_MIEMBRO, CASE WHEN EQ.TIPO_MIEMBRO = 'EMPLEADO' THEN EQ.ID_EMPLEADO ELSE EQ.ID_CONSULTOR END AS ID_ENT
                     FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                     WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.ID_ROL = R.ID AND EQ.ESTADO = 'ACTIVO'
                     ORDER BY EQ.PRINCIPAL DESC, EQ.ID) X;

        DECLARE @SIN VARCHAR(300) = NULL;
        SELECT TOP 1 @SIN = G.CODIGO + ' (DESTINATARIO_ROL = ' + CASE WHEN G.ROL = '' THEN 'vacio' ELSE G.ROL END + ')' FROM @RG G WHERE G.ID_ENT IS NULL ORDER BY G.ID;
        IF @SIN IS NOT NULL BEGIN SET @ERROR = 'La regla ' + @SIN + ' no tiene a qui' + CHAR(233) + 'n asignarse en el equipo del proyecto.'; RETURN; END;
    END;

    DECLARE @MIN_DIAS INT;
    SELECT @MIN_DIAS = MIN(DIAS) FROM @RG WHERE DIAS IS NOT NULL AND ES_FINAL = 0;

    /* ---------- grabar ---------- */
    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
            (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL,
             FECHA_DESDE, ESTADO, OBSERVACIONES, FECHA_ALTA, USUARIO_ALTA)
        VALUES
            (@ID_PROYECTO, NULL, 'CONSULTOR', NULL, @ID_CONSULTOR, @ID_ROL, @ES_LIDER,
             GETDATE(), 'ACTIVO', NULLIF(LTRIM(RTRIM(ISNULL(@OBS,''))),''), GETDATE(), @IAGENTE);

        IF @ID_ACC_ASIG IS NOT NULL
        BEGIN
            IF @ES_LIDER = 1
            BEGIN
                UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @EST_CUMP, FECHA_CIERRE = GETDATE() WHERE ID = @ID_ACC_ASIG;
                IF @ID_RES IS NOT NULL AND COL_LENGTH('dbo.VCT_ACCIONES', 'ID_RESULTADO') IS NOT NULL
                    EXEC sp_executesql N'UPDATE dbo.VCT_ACCIONES SET ID_RESULTADO = @R WHERE ID = @A', N'@R INT, @A INT', @R = @ID_RES, @A = @ID_ACC_ASIG;
            END;
            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL
                (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
            VALUES (@ID_ACC_ASIG, @EST_ANT, CASE WHEN @ES_LIDER = 1 THEN @EST_CUMP ELSE @EST_ANT END,
                    CASE WHEN @ES_LIDER = 1 THEN 'CUMPLIDA' ELSE 'CONSULTOR_ASIGNADO' END,
                    LEFT('Consultor asignado: ' + @CONS_NOM + ' (' + @ROL_DES + ').'
                         + CASE WHEN ISNULL(@OBS,'') <> '' THEN ' ' + @OBS ELSE '' END, 2000),
                    'USUARIO', GETDATE(), @IAGENTE);
        END;

        /* acciones de las reglas: accion + responsable + historial */
        DECLARE @RID INT = 0, @NEWA INT;
        WHILE 1 = 1
        BEGIN
            SELECT TOP 1 @RID = ID FROM @RG WHERE ID > @RID ORDER BY ID;
            IF @@ROWCOUNT = 0 BREAK;

            INSERT INTO dbo.VCT_ACCIONES
                (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_REGLA_ORIGEN, TITULO, DESCRIPCION,
                 ID_CLIENTE, ID_PROYECTO, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
            SELECT 'AUTOMATICA', G.ID_TIPO, G.ID_SUBTIPO, G.ID_ESTADO, G.ID_PRIORIDAD, G.ID,
                   LEFT(REPLACE(REPLACE(G.TITULO, '{{CODIGO_PROYECTO}}', ISNULL(@COD,'')), '{{PROYECTO}}', ISNULL(@NOM,'')), 300),
                   REPLACE(REPLACE(ISNULL(G.DETALLE, ''), '{{CODIGO_PROYECTO}}', ISNULL(@COD,'')), '{{PROYECTO}}', ISNULL(@NOM,'')),
                   @CLI, @ID_PROYECTO, GETDATE(), GETDATE(),
                   CASE WHEN G.ES_FINAL = 1 OR G.DIAS IS NULL THEN NULL
                        WHEN @VENCE IS NOT NULL THEN DATEADD(DAY, G.DIAS - @MIN_DIAS, @VENCE)
                        ELSE DATEADD(DAY, G.DIAS, @HOY) END,
                   CASE WHEN G.ES_FINAL = 1 THEN GETDATE() END,
                   GETDATE(), @IAGENTE
            FROM @RG G WHERE G.ID = @RID;
            SET @NEWA = SCOPE_IDENTITY();
            UPDATE @RG SET ID_ACCION = @NEWA WHERE ID = @RID;

            INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES
                (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
            SELECT @NEWA, 'RESPONSABLE', G.TIPO_ENT, G.ID_ENT, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE
            FROM @RG G WHERE G.ID = @RID;

            INSERT INTO dbo.VCT_ACCIONES_HISTORIAL
                (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
            SELECT @NEWA, NULL, G.ID_ESTADO, 'ALTA',
                   LEFT('Generada por la regla ' + G.CODIGO + ' al asignar el consultor l' + CHAR(237) + 'der del proyecto ' + ISNULL(@COD,'') + '.', 2000),
                   'SISTEMA', GETDATE(), @IAGENTE
            FROM @RG G WHERE G.ID = @RID;
        END;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @ERROR = LEFT('No se pudo asignar el consultor: ' + ERROR_MESSAGE(), 1000);
        RETURN;
    END CATCH;

    SELECT @GEN_TXT = @GEN_TXT + CASE WHEN @GEN_TXT = '' THEN '' ELSE ', ' END + ISNULL(G.SUB_DES, G.CODIGO) FROM @RG G ORDER BY G.ID;
    SET @MENSAJE = LEFT(@CONS_NOM + ' asignado como ' + @ROL_DES + '.'
                 + CASE WHEN @ES_LIDER = 1 AND @ID_ACC_ASIG IS NOT NULL THEN ' Acci' + CHAR(243) + 'n "Asignar consultores" cumplida.' ELSE '' END
                 + CASE WHEN @GEN_TXT <> '' THEN ' Nuevas acciones: ' + @GEN_TXT + '.' ELSE '' END, 1000);

    /* ---------- mails (despues de grabar: si falla, la asignacion queda) ----------
       Al consultor: plantilla PROYECTO_CONSULTOR_ASIGNADO (VCT_PRM_EMAIL_TEMPLATES).
       Reglas con GENERA_EMAIL = 1: plantilla VCT_PRM_EMAIL_TEMPLATES.ID = regla.ID_EMAIL_TEMPLATE.
       Destino y CC: los resuelve dbo.VCT_MAIN_SEND_EMAIL segun DESTINO_TIPO / CC_TIPO de la plantilla.
       Perfil: el predeterminado de Database Mail en msdb. Resultado en VCT_ACCIONES_HISTORIAL. */
    DECLARE @PERFIL SYSNAME, @TPL VARCHAR(50), @HIST INT, @MAIL_OK VARCHAR(1000) = '', @MAIL_ERR VARCHAR(1000) = '',
            @M_TO VARCHAR(1000), @M_CC VARCHAR(1000), @M_ASU VARCHAR(500), @M_BODY VARCHAR(MAX),
            @V_NOR VARCHAR(MAX) = '', @V_ROL VARCHAR(150) = @ROL_DES;
    DECLARE @PV TABLE (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));
    DECLARE @MQ TABLE (ORD INT IDENTITY(1,1), TPL VARCHAR(50), ID_ACCION INT);

    SELECT TOP 1 @PERFIL = P.name
    FROM msdb.dbo.sysmail_profile P
    JOIN msdb.dbo.sysmail_principalprofile PP ON PP.profile_id = P.profile_id
    WHERE PP.is_default = 1
    ORDER BY P.profile_id;

    SELECT @V_NOR = @V_NOR + CASE WHEN @V_NOR = '' THEN '' ELSE ', ' END + ISNULL(N.DESCRIPCION,'')
    FROM dbo.VCT_PROYECTOS_NORMAS PN WITH(NOLOCK)
    JOIN dbo.VCT_PRM_NORMAS N WITH(NOLOCK) ON N.ID = PN.ID_NORMA
    WHERE PN.ID_PROYECTO = @ID_PROYECTO
    ORDER BY PN.PRINCIPAL DESC, N.DESCRIPCION;

    INSERT INTO @MQ (TPL, ID_ACCION) VALUES ('PROYECTO_CONSULTOR_ASIGNADO', @ID_ACC_ASIG);
    INSERT INTO @MQ (TPL, ID_ACCION)
    SELECT ISNULL(T.CODIGO, ''), G.ID_ACCION
    FROM @RG G LEFT JOIN dbo.VCT_PRM_EMAIL_TEMPLATES T WITH(NOLOCK) ON T.ID = G.ID_TPL AND T.ESTADO = 'ACTIVO'
    WHERE G.MAIL = 1
    ORDER BY G.ID;

    DECLARE @MO INT = 0;
    WHILE 1 = 1
    BEGIN
        SELECT TOP 1 @MO = ORD, @TPL = TPL, @HIST = ID_ACCION FROM @MQ WHERE ORD > @MO ORDER BY ORD;
        IF @@ROWCOUNT = 0 BREAK;
        DELETE FROM @PV;
        BEGIN TRY
            IF ISNULL(@TPL,'') = '' OR NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WITH(NOLOCK) WHERE CODIGO = @TPL AND ESTADO = 'ACTIVO')
                RAISERROR('no existe la plantilla activa %s en VCT_PRM_EMAIL_TEMPLATES.', 16, 1, @TPL);
            IF @PERFIL IS NULL RAISERROR('no hay un perfil de Database Mail predeterminado en msdb.', 16, 1);

            INSERT INTO @PV EXEC dbo.VCT_MAIN_SEND_EMAIL @CODIGO = @TPL, @ID_CONSULTOR = @ID_CONSULTOR, @ID_PROYECTO = @ID_PROYECTO,
                                 @ID_ANALISTA = @ANALISTA, @ID_CLIENTE = @CLI, @PROFILE_NAME = NULL;

            UPDATE @PV SET
                ASUNTO = REPLACE(REPLACE(REPLACE(ASUNTO, '{{CODIGO_PROYECTO}}', ISNULL(@COD,'')), '{{NORMAS}}', @V_NOR), '{{ROL}}', @V_ROL),
                HTML_CONTENIDO = REPLACE(REPLACE(REPLACE(HTML_CONTENIDO, '{{CODIGO_PROYECTO}}', ISNULL(@COD,'')),
                                 '{{NORMAS}}', REPLACE(REPLACE(REPLACE(@V_NOR, '&', '&amp;'), '<', '&lt;'), '>', '&gt;')), '{{ROL}}', @V_ROL);

            SELECT TOP 1 @M_TO = NULLIF(LTRIM(RTRIM(ISNULL(DESTINATARIO,''))),''), @M_CC = NULLIF(LTRIM(RTRIM(ISNULL(CC,''))),''), @M_ASU = ASUNTO, @M_BODY = HTML_CONTENIDO FROM @PV;
            /* email adicional (solo el mail al consultor): CC, o destino si el consultor no tiene email */
            IF @MO = 1 AND @EMAIL_EXTRA <> ''
            BEGIN
                IF @M_TO IS NULL SET @M_TO = @EMAIL_EXTRA;
                ELSE SET @M_CC = CASE WHEN @M_CC IS NULL THEN @EMAIL_EXTRA ELSE @M_CC + ';' + @EMAIL_EXTRA END;
            END;
            IF @M_TO IS NULL RAISERROR('la plantilla no resolvio el destinatario (el consultor no tiene email y no se cargo email adicional).', 16, 1);

            EXEC msdb.dbo.sp_send_dbmail @profile_name = @PERFIL, @recipients = @M_TO, @copy_recipients = @M_CC,
                                         @subject = @M_ASU, @body = @M_BODY, @body_format = 'HTML';
            IF @HIST IS NOT NULL
                INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@HIST, 'EMAIL_ENVIADO', LEFT('Plantilla ' + @TPL + ' a ' + @M_TO + ' (perfil ' + @PERFIL + ').', 2000), 'SISTEMA', GETDATE(), @IAGENTE);
            SET @MAIL_OK = LEFT(@MAIL_OK + CASE WHEN @MAIL_OK = '' THEN '' ELSE '; ' END + @M_TO, 1000);
        END TRY
        BEGIN CATCH
            SET @MAIL_ERR = LEFT(ERROR_MESSAGE(), 500);
            IF @HIST IS NOT NULL
                INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                VALUES (@HIST, 'EMAIL_NO_ENVIADO', LEFT('Plantilla ' + ISNULL(NULLIF(@TPL,''),'-') + ': ' + @MAIL_ERR, 2000), 'SISTEMA', GETDATE(), @IAGENTE);
        END CATCH;
    END;

    IF @MAIL_OK <> '' SET @MENSAJE = LEFT(@MENSAJE + ' Mail enviado a ' + @MAIL_OK + '.', 1000);
    IF @MAIL_ERR <> '' SET @MENSAJE = LEFT(@MENSAJE + ' El mail no se pudo enviar: ' + @MAIL_ERR, 1000);
END
GO

DECLARE @TRG BIT;
SELECT @TRG = TRG FROM #P2A;
IF OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR')) LIKE '%V3: email obligatorio%'
    PRINT 'OK   dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR creado.';
ELSE
    PRINT 'FALLO dbo.VCT_PROYECTO_ASIGNAR_CONSULTOR no se creo: revisar el error de arriba.';
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
