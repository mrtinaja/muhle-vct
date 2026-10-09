/* ========================================================================
   PROYECTO_LANZ_1_INSTALACION  (CREA OBJETOS Y CAMBIA PARAMETRIA: leer antes)
   ------------------------------------------------------------------------
   Pantalla del analista: seccion "Lanzamiento" en la Vista 360 de Proyecto.
   Solo modelo nuevo (VCT_*), sin tablas ni columnas nuevas.
     1. Permiso PROYECTOS.EDIT (ya existe en Actions) para GERENCIA,
        ADMINISTRACION, SQUAD y PROYECTOS.
     2. Template de mail PROYECTO_INICIO_CONSULTOR (formato del editor,
        banner bordo). MODO PRUEBA: destino martin.aja + esteban.de.marco.
     3. Funciones: dbo.VCT_HTML_ESC, dbo.VCT_PROYECTO_MINUTAS,
        dbo.VCT_PROYECTO_LANZ_ESTADO.
     4. dbo.VCT_PROYECTO_LANZ_ACCION: graba equipo, datos de entrada,
        consideraciones, reunion de lanzamiento e inicio del proyecto.
     5. dbo.VCT_PROYECTO_LANZ_RENDER: arma la seccion y sus formularios.
   Criterio (reunion con los duenos, Resumen_reunion_sistema_gestion.pdf):
   la minuta de gestion deja de existir como formato. Sus items pasan a ser
   los "Datos de entrada" del proyecto: campos LIBRES, sin obligatorios ni
   validaciones. El inicio del proyecto no se bloquea (los pasos se muestran
   como guia).
   Donde se guarda (sin tablas nuevas):
     - Datos de entrada: VCT_PROYECTOS_DOCUMENTOS TIPO 'MG' + _ITEMS
       (preguntas de VCT_PRM_DOCUMENTOS_ITEMS de la minuta del servicio).
     - Consideraciones:  VCT_PROYECTOS_DOCUMENTOS TIPO 'CONS' + _ITEMS
       (GRUPO = INTERNA / CONSULTOR / CLIENTE, autor y fecha de alta).
   Todo se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* ---------------- 1. permiso PROYECTOS.EDIT ---------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.Actions WHERE UPPER(LTRIM(RTRIM(Id)))='PROYECTOS.EDIT')
    RAISERROR('No existe la accion PROYECTOS.EDIT en Actions: el permiso no se asigno (el resto sigue).',10,1);
ELSE
    INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
    SELECT g.id, 'PROYECTOS.EDIT', NEWID(), GETDATE()
    FROM (VALUES ('GERENCIA'),('ADMINISTRACION'),('SQUAD'),('PROYECTOS')) g(id)
    WHERE EXISTS (SELECT 1 FROM dbo.Groups G WHERE UPPER(LTRIM(RTRIM(G.Id)))=g.id)
      AND NOT EXISTS (SELECT 1 FROM dbo.GroupsActions X
                      WHERE UPPER(LTRIM(RTRIM(X.GroupId)))=g.id
                        AND UPPER(LTRIM(RTRIM(X.ActionId)))='PROYECTOS.EDIT');
GO

/* ---------------- 2. template de mail ---------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE UPPER(LTRIM(RTRIM(CODIGO)))='PROYECTO_INICIO_CONSULTOR')
INSERT INTO dbo.VCT_PRM_EMAIL_TEMPLATES
    (CODIGO, DESCRIPCION, TIPO_ENVIO, DESTINO_TIPO, DESTINO_LIBRE, CC_TIPO, CC_LIBRE, ESTADO, ASUNTO, HTML_CONTENIDO, DISENO_JSON, FECHA_ALTA, USUARIO_ALTA)
VALUES
    ('PROYECTO_INICIO_CONSULTOR',
     'Aviso automatico al consultor lider cuando el analista inicia el proyecto (armar el Plan Estrategico).',
     'AUTOMATICO', 'LIBRE', 'martin.aja@squad.com.ar; esteban.de.marco@squad.com.ar', 'NINGUNO', NULL, 'ACTIVO',
     'Proyecto en curso: ({{CODIGO_PROYECTO}}) {{PROYECTO}}',
       '<!doctype html><html><head><meta charset="utf-8"><style>html,body{overflow-x:hidden;}</style></head>'
     + '<body style="margin:0;padding:0;background:#f3f5f7;">'
     + '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;background:#f3f5f7;padding:24px 0;"><tr><td align="center">'
     + '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:600px;max-width:94%;background:#ffffff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;"><tr>'
     + '<td data-vct-email-content style="padding:20px 24px;color:#263247;font-family:Arial,sans-serif;font-size:14px;line-height:1.6;">'
     + '<img src="https://vocaturo.desa.interdev.online/img/vct-mail-banner-Bordeaux.png" alt="" width="600" height="90" style="max-width:100%;width:100%;height:auto;display:block;margin:0;">'
     + '<div><br></div>'
     + '<div style="font-size:17px;font-weight:bold;color:#66062D;">Proyecto en curso</div>'
     + '<div><br></div>'
     + '<div>Hola {{CONSULTOR}},</div>'
     + '<div>El proyecto <b>({{CODIGO_PROYECTO}}) {{PROYECTO}}</b> del cliente <b>{{CLIENTE}}</b> ya est&aacute; en curso y fuiste asignado como <b>consultor l&iacute;der</b>.</div>'
     + '<div><br></div>'
     + '<div><b>Analista:</b> {{ANALISTA}}</div>'
     + '<div><b>Normas:</b> {{NORMAS}}</div>'
     + '<div><b>Equipo:</b> {{EQUIPO}}</div>'
     + '<div><br></div>'
     + '<div>Pr&oacute;ximo paso: armar el Plan Estrat&eacute;gico del proyecto antes del <b>{{FECHA_PLAN}}</b>.</div>'
     + '<div><br></div>'
     + '<div>Pod&eacute;s verlo en <a href="https://vocaturo.desa.interdev.online/main/">https://vocaturo.desa.interdev.online/main/</a></div>'
     + '<div><br></div>'
     + '<div style="color:#6b7280;font-size:12px;">Mail generado autom&aacute;ticamente el {{FECHA}} a las {{HORA}}.</div>'
     + '</td></tr></table>'
     + '</td></tr></table></body></html>',
     NULL, GETDATE(), 'PROYECTO_LANZ');
GO

/* ---------------- 3. funciones ---------------- */
CREATE OR ALTER FUNCTION dbo.VCT_HTML_ESC (@S VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@S,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
END
GO

/* Minutas de gestion (datos de entrada) que corresponden al proyecto:
   una por tipo de servicio, segun el codigo del documento parametrizado. */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_MINUTAS (@ID_PROYECTO INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        X.ID_PROYECTO_SERVICIO,
        X.ID_SERVICIO,
        X.SERVICIO,
        D.ID AS ID_DOCUMENTO,
        D.DESCRIPCION AS DOCUMENTO,
        PD.ID AS ID_PROYECTO_DOCUMENTO,
        (SELECT COUNT(*) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
          WHERE I.ID_DOCUMENTO = D.ID AND I.ACTIVO = 1
            AND UPPER(ISNULL(I.GRUPO,'')) <> 'CIERRE') AS ITEMS_TOTAL,
        (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
          WHERE PI.ID_PROYECTO_DOCUMENTO = PD.ID
            AND LTRIM(RTRIM(ISNULL(PI.VALOR,''))) <> '') AS ITEMS_OK
    FROM
    (
        SELECT PS.ID AS ID_PROYECTO_SERVICIO, PS.ID_SERVICIO, S.DESCRIPCION AS SERVICIO, UPPER(S.CODIGO) AS CODIGO_SERVICIO,
               ROW_NUMBER() OVER (PARTITION BY PS.ID_SERVICIO ORDER BY PS.PRINCIPAL DESC, PS.ID) AS RN
        FROM dbo.VCT_PROYECTOS_SERVICIOS PS
        INNER JOIN dbo.VCT_PRM_SERVICIOS S ON S.ID = PS.ID_SERVICIO
        WHERE PS.ID_PROYECTO = @ID_PROYECTO
    ) X
    INNER JOIN dbo.VCT_PRM_DOCUMENTOS D
            ON D.CODIGO = CASE X.CODIGO_SERVICIO
                              WHEN 'CONSULTORIA'  THEN 'RE-PP-022-CO'
                              WHEN 'AUDITORIA'    THEN 'RE-PP-022-A'
                              WHEN 'CAPACITACION' THEN 'RE-PP-022-CA'
                          END
           AND D.ACTIVO = 1
    OUTER APPLY
    (
        SELECT TOP 1 PDX.ID
        FROM dbo.VCT_PROYECTOS_DOCUMENTOS PDX
        WHERE PDX.ID_PROYECTO = @ID_PROYECTO
          AND PDX.ID_DOCUMENTO = D.ID
          AND PDX.TIPO = 'MG'
        ORDER BY PDX.ID DESC
    ) PD
    WHERE X.RN = 1
)
GO

/* Estado de los 3 pasos del lanzamiento. */
CREATE OR ALTER FUNCTION dbo.VCT_PROYECTO_LANZ_ESTADO (@ID_PROYECTO INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        E.CODIGO AS ESTADO_CODIGO,
        E.DESCRIPCION AS ESTADO,
        (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_EQUIPO EQ
          INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
          WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
            AND R.CODIGO = 'CONSULTOR_LIDER') AS LIDERES,
        (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_EQUIPO EQ
          WHERE EQ.ID_PROYECTO = P.ID AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO') AS CONSULTORES,
        (SELECT COUNT(*) FROM dbo.VCT_PROYECTO_MINUTAS(P.ID) M WHERE M.ITEMS_OK > 0) AS DATOS_CARGADOS,
        (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_DOCUMENTOS D
          INNER JOIN dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS I ON I.ID_PROYECTO_DOCUMENTO = D.ID
          WHERE D.ID_PROYECTO = P.ID AND D.TIPO = 'CONS' AND I.CAMPO = 'CONSIDERACION') AS CONSIDERACIONES,
        CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES G
                           INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
                           INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
                           WHERE G.ID_PROYECTO = P.ID AND ST.CODIGO = 'ASIGNACION_ANALISTA' AND GE.CODIGO = 'CUMPLIDA')
             THEN 1 ELSE 0 END AS REUNION_OK
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    WHERE P.ID = @ID_PROYECTO
)
GO

/* ---------------- 4. acciones ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_LANZ_ACCION
(
    @IPKEYJOB    VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @ID_PROYECTO INT,
    @MENSAJE     VARCHAR(1000) OUTPUT,
    @ERROR       VARCHAR(1000) OUTPUT
)
AS
BEGIN
    /* ============================================================
       Comandos (VCT_BUFFER.TEXTO30, con FLAG01 = 1):
         LANZ_EQUIPO_ADD  TEXTO11 consultor, TEXTO12 rol (CONSULTOR_LIDER / CONSULTOR)
         LANZ_EQUIPO_DEL  IDSELEC03 = VCT_PROYECTOS_EQUIPO.ID (baja logica)
         LANZ_DATOS       IDSELEC03 = ID_DOCUMENTO de la minuta;
                          TEXTO11..TEXTO29 = respuestas "[[idItem]]valor..." en tramos
         LANZ_CONS        TEXTO11 consideracion, TEXTO12 visibilidad
         LANZ_REUNION     TEXTO11 fecha (yyyy-mm-dd), TEXTO12 participantes, TEXTO13 notas
         LANZ_INICIAR     pasa el proyecto a EN CURSO
       No devuelve result sets.
       ============================================================ */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @MENSAJE = '';
    SET @ERROR = '';

    DECLARE @FLAG VARCHAR(10), @CMD VARCHAR(100), @SEL3 VARCHAR(100), @PAYLOAD VARCHAR(MAX),
            @T11 VARCHAR(4000), @T12 VARCHAR(4000), @T13 VARCHAR(4000);

    SELECT TOP 1
        @FLAG = ISNULL(FLAG01,''),
        @CMD = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @SEL3 = LTRIM(RTRIM(ISNULL(IDSELEC03,''))),
        @T11 = LTRIM(RTRIM(ISNULL(TEXTO11,''))),
        @T12 = LTRIM(RTRIM(ISNULL(TEXTO12,''))),
        @T13 = LTRIM(RTRIM(ISNULL(TEXTO13,''))),
        @PAYLOAD = ISNULL(TEXTO11,'') + ISNULL(TEXTO12,'') + ISNULL(TEXTO13,'') + ISNULL(TEXTO14,'') + ISNULL(TEXTO15,'')
                 + ISNULL(TEXTO16,'') + ISNULL(TEXTO17,'') + ISNULL(TEXTO18,'') + ISNULL(TEXTO19,'') + ISNULL(TEXTO20,'')
                 + ISNULL(TEXTO21,'') + ISNULL(TEXTO22,'') + ISNULL(TEXTO23,'') + ISNULL(TEXTO24,'') + ISNULL(TEXTO25,'')
                 + ISNULL(TEXTO26,'') + ISNULL(TEXTO27,'') + ISNULL(TEXTO28,'') + ISNULL(TEXTO29,'')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    IF CHARINDEX(',', @CMD) > 0 SET @CMD = LEFT(@CMD, CHARINDEX(',', @CMD) - 1);
    IF ISNULL(@FLAG,'') <> '1' OR @CMD NOT LIKE 'LANZ[_]%' RETURN;

    /* siempre se consume el comando, haya error o no */
    UPDATE dbo.VCT_BUFFER
       SET FLAG01 = '0', TEXTO30 = NULL, IDSELEC03 = NULL,
           TEXTO11 = NULL, TEXTO12 = NULL, TEXTO13 = NULL, TEXTO14 = NULL, TEXTO15 = NULL,
           TEXTO16 = NULL, TEXTO17 = NULL, TEXTO18 = NULL, TEXTO19 = NULL, TEXTO20 = NULL,
           TEXTO21 = NULL, TEXTO22 = NULL, TEXTO23 = NULL, TEXTO24 = NULL, TEXTO25 = NULL,
           TEXTO26 = NULL, TEXTO27 = NULL, TEXTO28 = NULL, TEXTO29 = NULL
     WHERE PAR_KEY = @IPKEYJOB;

    IF dbo.VCT_PERFIL_PUEDE(@IUNIDAD, 'PROYECTOS.EDIT') = 0
    BEGIN
        SET @ERROR = 'No posee permisos para modificar el proyecto.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS WHERE ID = @ID_PROYECTO)
    BEGIN
        SET @ERROR = 'No se encontro el proyecto.';
        RETURN;
    END;

    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT, @EST_COD VARCHAR(30);
    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE, @EST_COD = E.CODIGO
    FROM dbo.VCT_PROYECTOS P LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = P.ID_ESTADO
    WHERE P.ID = @ID_PROYECTO;

    BEGIN TRY
        /* ---------------- equipo: agregar consultor ---------------- */
        IF @CMD = 'LANZ_EQUIPO_ADD'
        BEGIN
            DECLARE @ID_CONS INT, @ID_ROL INT, @ROL_COD VARCHAR(50) = UPPER(@T12);

            IF @T11 = '' OR PATINDEX('%[^0-9]%', @T11) > 0 OR LEN(@T11) > 9
               OR NOT EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES WHERE CONVERT(VARCHAR(20),ID) = @T11 AND UPPER(ISNULL(ESTADO,'')) = 'ACTIVO')
            BEGIN
                SET @ERROR = 'Seleccione un consultor activo.';
                RETURN;
            END;
            SET @ID_CONS = CONVERT(INT, @T11);

            SELECT TOP 1 @ID_ROL = ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WHERE CODIGO = @ROL_COD AND @ROL_COD IN ('CONSULTOR_LIDER','CONSULTOR');
            IF @ID_ROL IS NULL
            BEGIN
                SET @ERROR = 'Seleccione el rol del consultor.';
                RETURN;
            END;

            IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO_MIEMBRO = 'CONSULTOR'
                       AND ID_CONSULTOR = @ID_CONS AND ESTADO = 'ACTIVO')
            BEGIN
                SET @ERROR = 'Ese consultor ya forma parte del equipo.';
                RETURN;
            END;

            BEGIN TRANSACTION;
                /* un solo lider: el anterior pasa a consultor */
                IF @ROL_COD = 'CONSULTOR_LIDER'
                    UPDATE EQ
                       SET ID_ROL = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ROLES WHERE CODIGO = 'CONSULTOR'),
                           PRINCIPAL = 0, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                      FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                      INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                     WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                       AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER';

                INSERT INTO dbo.VCT_PROYECTOS_EQUIPO
                    (ID_PROYECTO, ID_PROYECTO_SERVICIO, TIPO_MIEMBRO, ID_EMPLEADO, ID_CONSULTOR, ID_ROL, PRINCIPAL, FECHA_DESDE, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_PROYECTO, NULL, 'CONSULTOR', NULL, @ID_CONS, @ID_ROL,
                     CASE WHEN @ROL_COD = 'CONSULTOR_LIDER' THEN 1 ELSE 0 END, GETDATE(), 'ACTIVO', GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;

            SET @MENSAJE = 'Consultor agregado al equipo.';
            RETURN;
        END;

        /* ---------------- equipo: quitar ---------------- */
        IF @CMD = 'LANZ_EQUIPO_DEL'
        BEGIN
            UPDATE dbo.VCT_PROYECTOS_EQUIPO
               SET ESTADO = 'INACTIVO', FECHA_HASTA = GETDATE(), PRINCIPAL = 0, FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
             WHERE CONVERT(VARCHAR(20), ID) = @SEL3 AND ID_PROYECTO = @ID_PROYECTO
               AND TIPO_MIEMBRO = 'CONSULTOR' AND ESTADO = 'ACTIVO';

            IF @@ROWCOUNT = 0 SET @ERROR = 'El consultor ya no forma parte del equipo.';
            ELSE SET @MENSAJE = 'Consultor quitado del equipo.';
            RETURN;
        END;

        /* ---------------- datos de entrada (minuta) ---------------- */
        IF @CMD = 'LANZ_DATOS'
        BEGIN
            DECLARE @ID_DOC INT, @ID_PS INT, @ID_SERV INT, @ID_PD INT;

            SELECT TOP 1 @ID_DOC = M.ID_DOCUMENTO, @ID_PS = M.ID_PROYECTO_SERVICIO, @ID_SERV = M.ID_SERVICIO, @ID_PD = M.ID_PROYECTO_DOCUMENTO
            FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) M
            WHERE CONVERT(VARCHAR(20), M.ID_DOCUMENTO) = @SEL3;

            IF @ID_DOC IS NULL
            BEGIN
                SET @ERROR = 'La minuta indicada no corresponde a este proyecto.';
                RETURN;
            END;

            /* respuestas: [[idItem]]valor[[idItem]]valor... */
            DECLARE @R TABLE (ID_ITEM INT PRIMARY KEY, VALOR VARCHAR(MAX));
            DECLARE @P INT = CHARINDEX('[[', @PAYLOAD), @Q INT, @N INT, @IDTXT VARCHAR(20);
            WHILE @P > 0
            BEGIN
                SET @Q = CHARINDEX(']]', @PAYLOAD, @P + 2);
                IF @Q = 0 BREAK;
                SET @IDTXT = SUBSTRING(@PAYLOAD, @P + 2, @Q - @P - 2);
                SET @N = CHARINDEX('[[', @PAYLOAD, @Q + 2);
                IF @IDTXT <> '' AND PATINDEX('%[^0-9]%', @IDTXT) = 0 AND LEN(@IDTXT) <= 9
                   AND NOT EXISTS (SELECT 1 FROM @R WHERE ID_ITEM = CONVERT(INT, @IDTXT))
                    INSERT INTO @R VALUES (CONVERT(INT, @IDTXT),
                        LTRIM(RTRIM(SUBSTRING(@PAYLOAD, @Q + 2, CASE WHEN @N = 0 THEN LEN(@PAYLOAD) + 1 ELSE @N END - @Q - 2))));
                SET @P = @N;
            END;

            BEGIN TRANSACTION;
                IF @ID_PD IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS
                        (ID_PROYECTO, ID_SERVICIO, ID_PROYECTO_SERVICIO, ID_DOCUMENTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                    SELECT @ID_PROYECTO, @ID_SERV, @ID_PS, @ID_DOC, GETDATE(), LEFT(D.DESCRIPCION, 300), 'MG', 'REGISTRADO', GETDATE(), @IAGENTE
                    FROM dbo.VCT_PRM_DOCUMENTOS D WHERE D.ID = @ID_DOC;
                    SET @ID_PD = SCOPE_IDENTITY();
                END
                ELSE
                    UPDATE dbo.VCT_PROYECTOS_DOCUMENTOS SET FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @ID_PD;

                UPDATE PI
                   SET VALOR = NULLIF(R.VALOR,''), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                  FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                  INNER JOIN @R R ON R.ID_ITEM = PI.ID_DOCUMENTO_ITEM
                 WHERE PI.ID_PROYECTO_DOCUMENTO = @ID_PD
                   AND ISNULL(PI.VALOR,'') <> ISNULL(NULLIF(R.VALOR,''),'');

                INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS
                    (ID_PROYECTO_DOCUMENTO, ID_DOCUMENTO_ITEM, DESCRIPCION, VALOR, GRUPO, ORDEN, OBLIGATORIO, DATO, CAMPO, EXPORTA, FECHA_ALTA, USUARIO_ALTA)
                SELECT @ID_PD, I.ID, I.DESCRIPCION, R.VALOR, I.GRUPO, I.ORDEN, ISNULL(I.OBLIGATORIO,0), I.DATO, I.CAMPO, ISNULL(I.EXPORTA,0), GETDATE(), @IAGENTE
                FROM @R R
                INNER JOIN dbo.VCT_PRM_DOCUMENTOS_ITEMS I ON I.ID = R.ID_ITEM AND I.ID_DOCUMENTO = @ID_DOC
                WHERE R.VALOR <> ''
                  AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                                  WHERE PI.ID_PROYECTO_DOCUMENTO = @ID_PD AND PI.ID_DOCUMENTO_ITEM = I.ID);
            COMMIT TRANSACTION;

            SET @MENSAJE = 'Datos de entrada guardados.';
            RETURN;
        END;

        /* ---------------- consideraciones ---------------- */
        IF @CMD = 'LANZ_CONS'
        BEGIN
            DECLARE @VIS VARCHAR(20) = UPPER(@T12);
            IF @T11 = ''
            BEGIN
                SET @ERROR = 'Escriba la consideracion.';
                RETURN;
            END;
            IF @VIS NOT IN ('INTERNA','CONSULTOR','CLIENTE') SET @VIS = 'INTERNA';

            DECLARE @ID_CONS_DOC INT = (SELECT TOP 1 ID FROM dbo.VCT_PROYECTOS_DOCUMENTOS WHERE ID_PROYECTO = @ID_PROYECTO AND TIPO = 'CONS' ORDER BY ID);

            BEGIN TRANSACTION;
                IF @ID_CONS_DOC IS NULL
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS (ID_PROYECTO, FECHA_DOCUMENTO, NRO_INTERNO, TIPO, ESTADO, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@ID_PROYECTO, GETDATE(), 'Consideraciones', 'CONS', 'REGISTRADO', GETDATE(), @IAGENTE);
                    SET @ID_CONS_DOC = SCOPE_IDENTITY();
                END;

                INSERT INTO dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS
                    (ID_PROYECTO_DOCUMENTO, DESCRIPCION, VALOR, GRUPO, ORDEN, OBLIGATORIO, CAMPO, EXPORTA, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_CONS_DOC, 'Consideracion', LEFT(@T11, 4000), @VIS,
                     (SELECT ISNULL(MAX(ORDEN),0) + 1 FROM dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS WHERE ID_PROYECTO_DOCUMENTO = @ID_CONS_DOC),
                     0, 'CONSIDERACION', CASE WHEN @VIS = 'CLIENTE' THEN 1 ELSE 0 END, GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;

            SET @MENSAJE = 'Consideracion agregada.';
            RETURN;
        END;

        /* ---------------- reunion de lanzamiento ---------------- */
        IF @CMD = 'LANZ_REUNION'
        BEGIN
            DECLARE @F_REU DATETIME;
            IF @T11 NOT LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]' OR ISDATE(REPLACE(@T11,'-','')) = 0
            BEGIN
                SET @ERROR = 'Indique la fecha de la reunion de lanzamiento.';
                RETURN;
            END;
            SET @F_REU = CONVERT(DATETIME, REPLACE(@T11,'-',''), 112);

            DECLARE @ID_G INT, @EST_ANT INT,
                    @G_CUMP INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'CUMPLIDA'),
                    @G_RES  INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_RESULTADOS WHERE CODIGO = 'COMPLETADA');

            SELECT TOP 1 @ID_G = G.ID, @EST_ANT = G.ID_ESTADO
            FROM dbo.VCT_GESTIONES G
            INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
            WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'ASIGNACION_ANALISTA'
            ORDER BY G.ID DESC;

            BEGIN TRANSACTION;
                IF @ID_G IS NULL
                BEGIN
                    /* proyectos sin gestion de lanzamiento (dados de alta antes): se crea */
                    INSERT INTO dbo.VCT_GESTIONES
                        (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                         REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_ALTA, USUARIO_ALTA)
                    SELECT 'SISTEMA',
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'ASIGNACION'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'ASIGNACION_ANALISTA'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
                           (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
                           LEFT('Organizar lanzamiento - (' + ISNULL(@CODIGO,'') + ') ' + ISNULL(@NOMBRE,''), 300),
                           'Reunion de lanzamiento del proyecto.', @ID_CLIENTE, @ID_PROYECTO, 0, 0, GETDATE(), GETDATE(), GETDATE(), @IAGENTE;
                    SET @ID_G = SCOPE_IDENTITY();
                    UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_G), 9) WHERE ID = @ID_G;
                    SELECT @EST_ANT = ID_ESTADO FROM dbo.VCT_GESTIONES WHERE ID = @ID_G;
                END;

                UPDATE dbo.VCT_GESTIONES
                   SET ID_ESTADO = @G_CUMP, ID_RESULTADO = @G_RES, FECHA_CIERRE = @F_REU,
                       OBSERVACIONES = LEFT('Reunion de lanzamiento ' + CONVERT(VARCHAR(10), @F_REU, 103)
                                     + CASE WHEN @T12 <> '' THEN '. Participantes: ' + @T12 ELSE '' END
                                     + '. Notas: ' + @T13, 2000),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_G;

                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ID_RESULTADO, ACCION, DESCRIPCION, TIPO_ACTOR, ID_ACTOR, FECHA, USUARIO)
                VALUES
                    (@ID_G, @EST_ANT, @G_CUMP, @G_RES, 'REUNION_LANZAMIENTO',
                     LEFT('Reunion ' + CONVERT(VARCHAR(10), @F_REU, 103)
                          + CASE WHEN @T12 <> '' THEN ' | Participantes: ' + @T12 ELSE '' END
                          + ' | Notas: ' + @T13, 2000),
                     'EMPLEADO', NULL, GETDATE(), @IAGENTE);
            COMMIT TRANSACTION;

            SET @MENSAJE = 'Reunion de lanzamiento registrada.';
            RETURN;
        END;

        /* ---------------- iniciar proyecto ---------------- */
        IF @CMD = 'LANZ_INICIAR'
        BEGIN
            IF ISNULL(@EST_COD,'') NOT IN ('BORRADOR','CONFIRMADO')
            BEGIN
                SET @ERROR = 'El proyecto ya fue iniciado o no esta en estado Confirmado.';
                RETURN;
            END;

            DECLARE @ID_ENC INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WHERE CODIGO = 'ENCURSO'),
                    @ID_LIDER INT, @ID_REGLA INT, @DIAS INT, @TIT VARCHAR(300), @DET VARCHAR(MAX), @ID_GP INT, @F_PLAN DATETIME;

            SELECT TOP 1 @ID_LIDER = EQ.ID_CONSULTOR
            FROM dbo.VCT_PROYECTOS_EQUIPO EQ INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
            WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'CONSULTOR_LIDER'
            ORDER BY EQ.ID DESC;

            SELECT TOP 1 @ID_REGLA = ID, @DIAS = DIAS_VENCIMIENTO, @TIT = TITULO_PLANTILLA, @DET = DETALLE_PLANTILLA
            FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE CODIGO = 'PROY_CONSULTORES_CARGAR_PLAN';

            SET @F_PLAN = DATEADD(DAY, ISNULL(@DIAS, 3), CONVERT(DATE, GETDATE()));
            SET @TIT = REPLACE(REPLACE(ISNULL(@TIT, 'Iniciar Plan Estrategico - {{CODIGO_PROYECTO}}'), '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,'')), '{{PROYECTO}}', ISNULL(@NOMBRE,''));
            SET @DET = REPLACE(REPLACE(ISNULL(@DET, 'Iniciar o completar el Plan Estrategico del proyecto.'), '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,'')), '{{PROYECTO}}', ISNULL(@NOMBRE,''));

            BEGIN TRANSACTION;
                UPDATE dbo.VCT_PROYECTOS
                   SET ID_ESTADO = @ID_ENC, FECHA_INICIO_REAL = ISNULL(FECHA_INICIO_REAL, CONVERT(DATE, GETDATE())),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                 WHERE ID = @ID_PROYECTO;

                UPDATE PS
                   SET ID_ESTADO = @ID_ENC, FECHA_INICIO_REAL = ISNULL(PS.FECHA_INICIO_REAL, CONVERT(DATE, GETDATE())),
                       FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE
                  FROM dbo.VCT_PROYECTOS_SERVICIOS PS
                  INNER JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID = PS.ID_ESTADO
                 WHERE PS.ID_PROYECTO = @ID_PROYECTO AND E.CODIGO IN ('BORRADOR','CONFIRMADO');

                IF @ID_LIDER IS NOT NULL
                BEGIN
                INSERT INTO dbo.VCT_GESTIONES
                    (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_REGLA_ORIGEN, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO,
                     REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_ALTA, USUARIO_ALTA)
                SELECT 'AUTOMATICA',
                       ISNULL((SELECT TOP 1 ID_TIPO FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE ID = @ID_REGLA), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_TIPOS WHERE CODIGO = 'TAREA')),
                       ISNULL((SELECT TOP 1 ID_SUBTIPO FROM dbo.VCT_PRM_GESTIONES_REGLAS WHERE ID = @ID_REGLA), (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_SUBTIPOS WHERE CODIGO = 'CARGA_PLAN')),
                       (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_ESTADOS WHERE CODIGO = 'PENDIENTE'),
                       (SELECT TOP 1 ID FROM dbo.VCT_PRM_GESTIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
                       @ID_REGLA, LEFT(@TIT, 300), @DET, @ID_CLIENTE, @ID_PROYECTO, 0, 0, GETDATE(), GETDATE(), @F_PLAN, GETDATE(), @IAGENTE;
                SET @ID_GP = SCOPE_IDENTITY();
                UPDATE dbo.VCT_GESTIONES SET CODIGO = 'GES-' + RIGHT(REPLICATE('0',9) + CONVERT(VARCHAR(20), @ID_GP), 9) WHERE ID = @ID_GP;

                INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
                    (ID_GESTION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
                SELECT @ID_GP, NULL, ID_ESTADO, 'CREACION', 'Creacion de gestion (inicio de proyecto).', 'SISTEMA', GETDATE(), @IAGENTE
                FROM dbo.VCT_GESTIONES WHERE ID = @ID_GP;

                INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
                    (ID_GESTION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
                VALUES
                    (@ID_GP, 'ORIGEN', 'SISTEMA', NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE),
                    (@ID_GP, 'RESPONSABLE', 'CONSULTOR', @ID_LIDER, 1, 'ACTIVO', GETDATE(), GETDATE(), @IAGENTE);
                END;
            COMMIT TRANSACTION;

            IF @ID_LIDER IS NULL
            BEGIN
                SET @MENSAJE = 'Proyecto iniciado: quedo En curso. No hay consultor lider asignado, asi que no se creo la gestion del Plan Estrategico.';
                RETURN;
            END;

            SET @MENSAJE = 'Proyecto iniciado: quedo En curso y se creo la gestion del Plan Estrategico para el consultor lider.';

            /* mail al consultor lider (fuera de la transaccion) */
            BEGIN TRY
                DECLARE @M_ASUNTO VARCHAR(500), @M_BODY VARCHAR(MAX), @M_DEST VARCHAR(1000), @M_CC VARCHAR(1000);
                IF OBJECT_ID('tempdb..#MAIL') IS NOT NULL DROP TABLE #MAIL;
                CREATE TABLE #MAIL (ASUNTO VARCHAR(500), HTML_CONTENIDO VARCHAR(MAX), DESTINATARIO VARCHAR(1000), CC VARCHAR(1000), ENVIADO BIT, ADVERTENCIA VARCHAR(500));

                IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_EMAIL_TEMPLATES WHERE UPPER(LTRIM(RTRIM(CODIGO))) = 'PROYECTO_INICIO_CONSULTOR' AND ESTADO = 'ACTIVO')
                BEGIN
                    DECLARE @ID_ANA INT = (SELECT TOP 1 EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                                           INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                                           WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'ANALISTA'
                                           ORDER BY EQ.PRINCIPAL DESC, EQ.ID);

                    INSERT INTO #MAIL
                    EXEC dbo.VCT_MAIN_SEND_EMAIL
                         @CODIGO = 'PROYECTO_INICIO_CONSULTOR',
                         @ID_CONSULTOR = @ID_LIDER,
                         @ID_PROYECTO = @ID_PROYECTO,
                         @ID_ANALISTA = @ID_ANA,
                         @ID_CLIENTE = @ID_CLIENTE;

                    SELECT TOP 1 @M_ASUNTO = ASUNTO, @M_BODY = HTML_CONTENIDO, @M_DEST = DESTINATARIO, @M_CC = NULLIF(LTRIM(RTRIM(CC)),'') FROM #MAIL;

                    DECLARE @L_NORM VARCHAR(2000) = '', @L_EQ VARCHAR(2000) = '';
                    SELECT @L_NORM = @L_NORM + CASE WHEN @L_NORM = '' THEN '' ELSE ', ' END + N.DESCRIPCION
                    FROM (SELECT DISTINCT PN.ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS PN WHERE PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA') X
                    INNER JOIN dbo.VCT_PRM_NORMAS N ON N.ID = X.ID_NORMA;
                    SELECT @L_EQ = @L_EQ + CASE WHEN @L_EQ = '' THEN '' ELSE ', ' END
                                 + LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ' ' + ISNULL(C.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')'
                    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                    INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
                    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
                    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
                    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

                    SET @M_ASUNTO = REPLACE(@M_ASUNTO, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{CODIGO_PROYECTO}}', ISNULL(@CODIGO,''));
                    SET @M_BODY = REPLACE(@M_BODY, '{{NORMAS}}', dbo.VCT_HTML_ESC(@L_NORM));
                    SET @M_BODY = REPLACE(@M_BODY, '{{EQUIPO}}', dbo.VCT_HTML_ESC(@L_EQ));
                    SET @M_BODY = REPLACE(@M_BODY, '{{FECHA_PLAN}}', CONVERT(VARCHAR(10), @F_PLAN, 103));

                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL AND @M_CC IS NOT NULL
                    BEGIN
                        SET @M_DEST = @M_CC;
                        SET @M_CC = NULL;
                    END;

                    IF NULLIF(LTRIM(RTRIM(ISNULL(@M_DEST,''))),'') IS NULL
                        SET @MENSAJE = LEFT(@MENSAJE + ' No se envio el mail: el consultor lider no tiene email cargado.', 1000);
                    ELSE
                    BEGIN
                        EXEC msdb.dbo.sp_send_dbmail
                             @profile_name = 'VocaturoProfile', @recipients = @M_DEST, @copy_recipients = @M_CC,
                             @subject = @M_ASUNTO, @body = @M_BODY, @body_format = 'HTML';
                        SET @MENSAJE = LEFT(@MENSAJE + ' Mail enviado a ' + @M_DEST + '.', 1000);
                    END;
                END;
            END TRY
            BEGIN CATCH
                SET @MENSAJE = LEFT(@MENSAJE + ' El mail fallo: ' + ERROR_MESSAGE(), 1000);
            END CATCH;
            RETURN;
        END;

        SET @ERROR = 'Comando no reconocido.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ERROR = LEFT('No se pudo grabar: ' + ERROR_MESSAGE(), 1000);
    END CATCH;
END
GO

/* ---------------- 5. render de la seccion ---------------- */
CREATE OR ALTER PROCEDURE dbo.VCT_PROYECTO_LANZ_RENDER
(
    @ID_PROYECTO INT,
    @IUNIDAD     VARCHAR(100),
    @MENSAJE     VARCHAR(1000) = '',
    @ERROR       VARCHAR(1000) = '',
    @HTML        VARCHAR(MAX) OUTPUT,
    @FORMS       VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    /* Seccion "Lanzamiento" de la Vista 360 de Proyecto (pantalla del analista):
       1. Equipo  2. Datos de entrada  3. Consideraciones  4. Reunion de lanzamiento
       + boton "Iniciar proyecto". Los pasos son guia: no bloquean el inicio.
       Formularios en @FORMS (van a OUTPARAM3). No devuelve result sets. */
    SET NOCOUNT ON;
    SET @HTML = '';
    SET @FORMS = '';

    DECLARE @CAN_EDIT BIT = ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PROYECTOS.EDIT'),0);

    DECLARE @CODIGO VARCHAR(100), @NOMBRE VARCHAR(300), @ID_CLIENTE INT, @CLIENTE VARCHAR(300),
            @F_INI DATETIME, @F_FIN DATETIME, @F_INI_REAL DATETIME, @RIESGO VARCHAR(50), @ID_CONTACTO INT;

    SELECT @CODIGO = P.CODIGO, @NOMBRE = P.NOMBRE, @ID_CLIENTE = P.IDCLIENTE, @CLIENTE = C.RAZON_SOCIAL,
           @F_INI = P.FECHA_INICIO, @F_FIN = P.FECHA_FIN, @F_INI_REAL = P.FECHA_INICIO_REAL,
           @RIESGO = P.NIVEL_RIESGO, @ID_CONTACTO = P.IDCONTACTO
    FROM dbo.VCT_PROYECTOS P
    LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE
    WHERE P.ID = @ID_PROYECTO;

    IF @CODIGO IS NULL AND @NOMBRE IS NULL RETURN;

    DECLARE @EST_COD VARCHAR(30), @EST VARCHAR(100), @NLID INT, @NCONS_EQ INT, @NDATOS INT, @NCONSID INT, @REU BIT;
    SELECT @EST_COD = ESTADO_CODIGO, @EST = ESTADO, @NLID = LIDERES, @NCONS_EQ = CONSULTORES,
           @NDATOS = DATOS_CARGADOS, @NCONSID = CONSIDERACIONES, @REU = REUNION_OK
    FROM dbo.VCT_PROYECTO_LANZ_ESTADO(@ID_PROYECTO);

    DECLARE @EN_LANZ BIT = CASE WHEN ISNULL(@EST_COD,'') IN ('BORRADOR','CONFIRMADO') THEN 1 ELSE 0 END;

    /* ---------- datos de apoyo ---------- */
    DECLARE @ANALISTA VARCHAR(400) = '', @CONSULTORES_TXT VARCHAR(2000) = '', @NORMAS VARCHAR(2000) = '',
            @DOMICILIO VARCHAR(600) = '', @CONTACTO VARCHAR(600) = '';

    SELECT TOP 1 @ANALISTA = LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + ', ' + ISNULL(E.NOMBRES,'')))
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    INNER JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'EMPLEADO' AND EQ.ESTADO = 'ACTIVO' AND R.CODIGO = 'ANALISTA'
    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

    SELECT @CONSULTORES_TXT = @CONSULTORES_TXT + CASE WHEN @CONSULTORES_TXT = '' THEN '' ELSE '; ' END
                            + LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,''))) + ' (' + R.DESCRIPCION + ')'
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
    INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
    WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
    ORDER BY EQ.PRINCIPAL DESC, EQ.ID;

    SELECT @NORMAS = @NORMAS + CASE WHEN @NORMAS = '' THEN '' ELSE ', ' END + N.DESCRIPCION
    FROM (SELECT DISTINCT PN.ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS PN
          WHERE PN.ID_PROYECTO = @ID_PROYECTO AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA') X
    INNER JOIN dbo.VCT_PRM_NORMAS N ON N.ID = X.ID_NORMA;

    SELECT TOP 1 @DOMICILIO = LTRIM(RTRIM(ISNULL(D.CALLE,'') + ' ' + ISNULL(CONVERT(VARCHAR(20),D.NRO),'')
                 + CASE WHEN ISNULL(D.LOCALIDAD,'') <> '' THEN ', ' + D.LOCALIDAD ELSE '' END
                 + CASE WHEN ISNULL(D.PROVINCIA,'') <> '' THEN ', ' + D.PROVINCIA ELSE '' END))
    FROM dbo.VCT_DOMICILIOS D
    WHERE D.TIPO_ENTIDAD = 'CLIENTE' AND D.ID_ENTIDAD = @ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, D.ID;

    SELECT TOP 1 @CONTACTO = LTRIM(RTRIM(ISNULL(CT.NOMBRES,'') + ' ' + ISNULL(CT.APELLIDO,'')))
                 + CASE WHEN ISNULL(CT.CARGO,'') <> '' THEN ' - ' + CT.CARGO ELSE '' END
                 + CASE WHEN ISNULL(EM.EMAIL,'') <> '' THEN ' - ' + EM.EMAIL ELSE '' END
    FROM dbo.VCT_CONTACTOS CT
    LEFT JOIN dbo.VCT_EMAILS EM ON EM.ID = CT.ID_EMAIL
    WHERE CT.IDCLIENTE = @ID_CLIENTE
    ORDER BY CASE WHEN CT.ID = @ID_CONTACTO THEN 0 ELSE 1 END, CT.ID;

    /* ---------- gestion de lanzamiento ---------- */
    DECLARE @G_VENC DATETIME, @G_CIERRE DATETIME, @G_OBS VARCHAR(2000), @G_EST VARCHAR(100);
    SELECT TOP 1 @G_VENC = G.FECHA_VENCIMIENTO, @G_CIERRE = G.FECHA_CIERRE, @G_OBS = G.OBSERVACIONES, @G_EST = GE.DESCRIPCION
    FROM dbo.VCT_GESTIONES G
    INNER JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST ON ST.ID = G.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE ON GE.ID = G.ID_ESTADO
    WHERE G.ID_PROYECTO = @ID_PROYECTO AND ST.CODIGO = 'ASIGNACION_ANALISTA'
    ORDER BY G.ID DESC;

    /* ---------- 1. equipo ---------- */
    DECLARE @H_EQUIPO VARCHAR(MAX) = '';
    SELECT @H_EQUIPO = ISNULL((
        SELECT
            '<li class="vct-lanz-person">'
          + '<span class="vct-lanz-person-name">' + dbo.VCT_HTML_ESC(LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,'')))) + '</span>'
          + '<span class="vct-lanz-role' + CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN ' is-lead' ELSE '' END + '">' + dbo.VCT_HTML_ESC(R.DESCRIPCION) + '</span>'
          + CASE WHEN @CAN_EDIT = 1 THEN
                '<span class="vct-lanz-inline" data-vct-form-scope data-vct-lanz-quitar>'
              + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_EQUIPO_DEL" value="LANZ_EQUIPO_DEL">'
              + '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), EQ.ID) + '" value="' + CONVERT(VARCHAR(20), EQ.ID) + '">'
              + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
              + '<button type="button" class="vct-lanz-icon-btn" data-vct-command="validate-next" title="Quitar del equipo" aria-label="Quitar del equipo">&times;</button>'
              + '</span>'
            ELSE '' END
          + '</li>'
        FROM dbo.VCT_PROYECTOS_EQUIPO EQ
        INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = EQ.ID_CONSULTOR
        INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
        WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ESTADO = 'ACTIVO'
        ORDER BY EQ.PRINCIPAL DESC, EQ.ID
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @H_EQUIPO =
        '<div class="vct-lanz-row"><span class="vct-lanz-k">Analista</span><span class="vct-lanz-v">' + CASE WHEN @ANALISTA = '' THEN 'Sin asignar' ELSE dbo.VCT_HTML_ESC(@ANALISTA) END + '</span></div>'
      + CASE WHEN @H_EQUIPO = '' THEN '<div class="vct-lanz-empty">Todav&iacute;a no hay consultores asignados.</div>'
             ELSE '<ul class="vct-lanz-people">' + @H_EQUIPO + '</ul>' END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzConsultor" data-vct-form-title="Agregar consultor" data-vct-form-subtitle="Consultores activos; primero los calificados en las normas del proyecto."><span data-vct-icon="user-plus"></span><span>Agregar consultor</span></button>'
        ELSE '' END;

    /* ---------- 2. datos de entrada ---------- */
    DECLARE @H_DATOS VARCHAR(MAX) = '';
    SELECT @H_DATOS = ISNULL((
        SELECT
            '<div class="vct-lanz-doc">'
          + '<div class="vct-lanz-doc-head"><b>' + dbo.VCT_HTML_ESC(M.SERVICIO) + '</b><span>'
          + CONVERT(VARCHAR(10), M.ITEMS_OK) + ' de ' + CONVERT(VARCHAR(10), M.ITEMS_TOTAL) + ' datos cargados</span></div>'
          + '<div class="vct-lanz-bar"><span style="width:' + CONVERT(VARCHAR(10), CASE WHEN M.ITEMS_TOTAL = 0 THEN 0 ELSE (M.ITEMS_OK * 100) / M.ITEMS_TOTAL END) + '%"></span></div>'
          + '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-lanz-open="vctLanzDatos' + CONVERT(VARCHAR(20), M.ID_DOCUMENTO) + '">'
          + '<span data-vct-icon="' + CASE WHEN @CAN_EDIT = 1 THEN 'edit' ELSE 'eye' END + '"></span><span>'
          + CASE WHEN @CAN_EDIT = 0 THEN 'Ver' WHEN M.ITEMS_OK = 0 THEN 'Completar' ELSE 'Ver / editar' END + '</span></button>'
          + '</div>'
        FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) M
        ORDER BY M.ID_SERVICIO
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
    IF @H_DATOS = ''
        SET @H_DATOS = '<div class="vct-lanz-empty">El servicio del proyecto no tiene datos de entrada parametrizados.</div>';

    /* ---------- 3. consideraciones ---------- */
    DECLARE @H_CONS VARCHAR(MAX) = '';
    SELECT @H_CONS = ISNULL((
        SELECT TOP 5
            '<li class="vct-lanz-note">'
          + '<div class="vct-lanz-note-meta"><span class="vct-lanz-vis vct-lanz-vis-' + LOWER(ISNULL(I.GRUPO,'INTERNA')) + '">'
          + CASE ISNULL(I.GRUPO,'INTERNA') WHEN 'CONSULTOR' THEN 'Consultor' WHEN 'CLIENTE' THEN 'Cliente' ELSE 'Interna' END + '</span>'
          + '<span>' + CONVERT(VARCHAR(10), I.FECHA_ALTA, 103) + ' &middot; ' + dbo.VCT_HTML_ESC(ISNULL(I.USUARIO_ALTA,'')) + '</span></div>'
          + '<div class="vct-lanz-note-text">' + REPLACE(dbo.VCT_HTML_ESC(I.VALOR), CHAR(10), '<br>') + '</div>'
          + '</li>'
        FROM dbo.VCT_PROYECTOS_DOCUMENTOS D
        INNER JOIN dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS I ON I.ID_PROYECTO_DOCUMENTO = D.ID
        WHERE D.ID_PROYECTO = @ID_PROYECTO AND D.TIPO = 'CONS' AND I.CAMPO = 'CONSIDERACION'
        ORDER BY I.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

    SET @H_CONS =
        CASE WHEN @H_CONS = '' THEN '<div class="vct-lanz-empty">Sin consideraciones. Ej.: &laquo;ojo con la log&iacute;stica&raquo;, d&iacute;as de acompa&ntilde;amiento en la auditor&iacute;a interna.</div>'
             ELSE '<ul class="vct-lanz-notes">' + @H_CONS + '</ul>'
                + CASE WHEN ISNULL(@NCONSID,0) > 5 THEN '<div class="vct-lanz-more">y ' + CONVERT(VARCHAR(10), @NCONSID - 5) + ' m&aacute;s</div>' ELSE '' END END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzCons"><span data-vct-icon="plus"></span><span>Agregar consideraci&oacute;n</span></button>'
        ELSE '' END;

    /* ---------- 4. reunion de lanzamiento ---------- */
    DECLARE @H_REU VARCHAR(MAX) =
        CASE WHEN @REU = 1 THEN
            '<div class="vct-lanz-row"><span class="vct-lanz-k">Realizada</span><span class="vct-lanz-v">' + ISNULL(CONVERT(VARCHAR(10), @G_CIERRE, 103), '-') + '</span></div>'
          + CASE WHEN ISNULL(@G_OBS,'') <> '' THEN '<div class="vct-lanz-note-text vct-lanz-muted">' + dbo.VCT_HTML_ESC(@G_OBS) + '</div>' ELSE '' END
        ELSE
            '<div class="vct-lanz-row"><span class="vct-lanz-k">Fecha l&iacute;mite</span><span class="vct-lanz-v">' + ISNULL(CONVERT(VARCHAR(10), @G_VENC, 103), 'Sin definir') + '</span></div>'
          + '<div class="vct-lanz-empty">Se explica el proyecto al consultor: d&iacute;as por mes, auditor&iacute;a interna, acompa&ntilde;amientos y puntos de atenci&oacute;n.</div>'
        END
      + CASE WHEN @CAN_EDIT = 1 THEN
            '<button type="button" class="vct-btn vct-btn-secondary vct-btn-sm vct-lanz-action" data-vct-command="open-modal-empty" data-vct-target="vctLanzReunion"><span data-vct-icon="calendar"></span><span>'
          + CASE WHEN @REU = 1 THEN 'Actualizar reuni&oacute;n' ELSE 'Registrar reuni&oacute;n' END + '</span></button>'
        ELSE '' END;

    /* ---------- armado de la seccion ---------- */
    DECLARE @PASOS INT = CASE WHEN ISNULL(@NCONS_EQ,0) > 0 THEN 1 ELSE 0 END + CASE WHEN ISNULL(@NDATOS,0) > 0 THEN 1 ELSE 0 END
                       + CASE WHEN ISNULL(@NCONSID,0) > 0 THEN 1 ELSE 0 END + CASE WHEN @REU = 1 THEN 1 ELSE 0 END;

    SET @HTML =
        '<div class="vct-360-box vct-lanz" data-vct-lanz>'
      + '<div class="vct-360-box-head vct-lanz-head">'
      +   '<div><h3><span class="vct-360-title-icon"><span data-vct-icon="clipboard-check"></span></span>'
      +   CASE WHEN @EN_LANZ = 1 THEN 'Lanzamiento del proyecto' ELSE 'Equipo y datos de entrada' END + '</h3>'
      +   '<p class="vct-360-box-subtitle">'
      +   CASE WHEN @EN_LANZ = 1 THEN 'Asignar el equipo, cargar los datos de entrada y las consideraciones, hacer la reuni&oacute;n de lanzamiento e iniciar el proyecto.'
               ELSE 'Proyecto ' + dbo.VCT_HTML_ESC(LOWER(ISNULL(@EST,''))) + CASE WHEN @F_INI_REAL IS NOT NULL THEN ' desde el ' + CONVERT(VARCHAR(10), @F_INI_REAL, 103) ELSE '' END + '.' END
      +   '</p></div>'
      +   CASE WHEN @EN_LANZ = 1 THEN '<span class="vct-lanz-progress"><b>' + CONVERT(VARCHAR(2), @PASOS) + '</b> de 4 pasos</span>' ELSE '' END
      + '</div>'
      + CASE WHEN ISNULL(@ERROR,'') <> '' THEN '<div class="vct-lanz-alert is-error">' + dbo.VCT_HTML_ESC(@ERROR) + '</div>'
             WHEN ISNULL(@MENSAJE,'') <> '' THEN '<div class="vct-lanz-alert is-ok">' + dbo.VCT_HTML_ESC(@MENSAJE) + '</div>'
             ELSE '' END
      + '<div class="vct-lanz-steps">'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NCONS_EQ,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">1</span><h4>Equipo</h4></header>' + @H_EQUIPO + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NDATOS,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">2</span><h4>Datos de entrada</h4></header>' + @H_DATOS + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN ISNULL(@NCONSID,0) > 0 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">3</span><h4>Consideraciones</h4></header>' + @H_CONS + '</section>'
      +   '<section class="vct-lanz-step' + CASE WHEN @REU = 1 THEN ' is-done' ELSE '' END + '"><header><span class="vct-lanz-num">4</span><h4>Reuni&oacute;n de lanzamiento</h4></header>' + @H_REU + '</section>'
      + '</div>'
      + CASE WHEN @EN_LANZ = 1 AND @CAN_EDIT = 1 THEN
            '<div class="vct-lanz-foot" data-vct-form-scope data-vct-lanz-iniciar data-pasos="' + CONVERT(VARCHAR(2), @PASOS) + '">'
          + '<span class="vct-lanz-foot-text">Al iniciar, el proyecto pasa a <b>En curso</b> y el consultor l&iacute;der recibe la tarea de armar el Plan Estrat&eacute;gico.</span>'
          + '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_INICIAR" value="LANZ_INICIAR">'
          + '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
          + '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next"><span data-vct-icon="check"></span><span>Iniciar proyecto</span></button>'
          + '</div>'
        ELSE '' END
      + '</div>';

    /* ============================================================
       FORMULARIOS
       ============================================================ */
    IF @CAN_EDIT = 0 AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO)) RETURN;

    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT, FIELD_NAME VARCHAR(50), LABEL VARCHAR(150), FIELD_TYPE VARCHAR(20),
        COL_SPAN INT, REQUIRED BIT, MAX_LENGTH INT, PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100), DEFAULT_VALUE VARCHAR(MAX), READONLY BIT,
        HIDDEN BIT, HELP_TEXT VARCHAR(500), SOURCE_FIELD VARCHAR(100)
    );
    DECLARE @F VARCHAR(MAX), @OPT VARCHAR(MAX);

    IF @CAN_EDIT = 1
    BEGIN
        /* ---- agregar consultor ---- */
        SELECT @OPT = ISNULL((
            SELECT '<option value="' + CONVERT(VARCHAR(20), X.ID) + '">' + dbo.VCT_HTML_ESC(X.NOMBRE)
                 + CASE WHEN X.CAL = 1 THEN ' &#9733; calificado' ELSE '' END + '</option>'
            FROM
            (
                SELECT C.ID, LTRIM(RTRIM(ISNULL(C.APELLIDOS,'') + ', ' + ISNULL(C.NOMBRES,''))) AS NOMBRE,
                       CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_CONSULTORES_NORMAS CN
                                         INNER JOIN dbo.VCT_PROYECTOS_NORMAS PN ON PN.ID_NORMA = CN.ID_NORMA AND PN.ID_PROYECTO = @ID_PROYECTO
                                         WHERE CN.ID_CONSULTOR = C.ID) THEN 1 ELSE 0 END AS CAL
                FROM dbo.VCT_CONSULTORES C
                WHERE UPPER(ISNULL(C.ESTADO,'')) = 'ACTIVO'
                  AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ
                                  WHERE EQ.ID_PROYECTO = @ID_PROYECTO AND EQ.TIPO_MIEMBRO = 'CONSULTOR'
                                    AND EQ.ID_CONSULTOR = C.ID AND EQ.ESTADO = 'ACTIVO')
            ) X
            ORDER BY X.CAL DESC, X.NOMBRE
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Consultor','TEXT',8,1,20,NULL,NULL,NULL,0,0,'&#9733; = calificado en alguna norma del proyecto.',NULL),
        (2,'TEXTO12','Rol','TEXT',4,1,30,NULL,NULL,CASE WHEN ISNULL(@NLID,0) = 0 THEN 'CONSULTOR_LIDER' ELSE 'CONSULTOR' END,0,0,NULL,NULL),
        (3,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_EQUIPO_ADD',0,1,NULL,NULL),
        (4,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzConsultor', @TITLE='Agregar consultor',
             @SUBTITLE='Consultores activos; primero los calificados en las normas del proyecto.', @ICON='user-plus',
             @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + ISNULL(@F,'')
            + '<template data-vct-field-options data-vct-target="vctLanzConsultor" data-vct-field="TEXTO11" data-vct-placeholder="Seleccione un consultor">' + @OPT + '</template>'
            + '<template data-vct-field-options data-vct-target="vctLanzConsultor" data-vct-field="TEXTO12" data-vct-placeholder="Seleccione"><option value="CONSULTOR_LIDER">Consultor l&iacute;der</option><option value="CONSULTOR">Consultor</option></template>';

        /* ---- consideracion ---- */
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Consideraci&oacute;n','TEXTAREA',12,1,4000,'Ej.: ojo con la log&iacute;stica de la planta; a los 10 meses hay auditor&iacute;a interna con 2 d&iacute;as de acompa&ntilde;amiento.',NULL,NULL,0,0,NULL,NULL),
        (2,'TEXTO12','Visible para','TEXT',6,1,20,NULL,NULL,'INTERNA',0,0,'Interna: solo la consultora.',NULL),
        (3,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_CONS',0,1,NULL,NULL),
        (4,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzCons', @TITLE='Nueva consideraci&oacute;n',
             @SUBTITLE='Queda registrada con autor y fecha.', @ICON='clipboard-check',
             @LAYOUT='MODAL', @SAVE_LABEL='Agregar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + ISNULL(@F,'')
            + '<template data-vct-field-options data-vct-target="vctLanzCons" data-vct-field="TEXTO12" data-vct-placeholder="Seleccione"><option value="INTERNA">Interna</option><option value="CONSULTOR">Consultor</option><option value="CLIENTE">Cliente</option></template>';

        /* ---- reunion de lanzamiento ---- */
        DECLARE @PARTIC VARCHAR(2000) = LTRIM(RTRIM(CASE WHEN @ANALISTA <> '' THEN @ANALISTA + ' (Analista)' ELSE '' END
                                       + CASE WHEN @ANALISTA <> '' AND @CONSULTORES_TXT <> '' THEN '; ' ELSE '' END + @CONSULTORES_TXT));
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Fecha de la reuni&oacute;n','DATE',6,1,NULL,'Seleccionar fecha',NULL,CONVERT(VARCHAR(10), ISNULL(@G_CIERRE, GETDATE()), 23),0,0,NULL,NULL),
        (2,'TEXTO12','Participantes','TEXT',12,0,1000,NULL,NULL,LEFT(@PARTIC,1000),0,0,NULL,NULL),
        (3,'TEXTO13','Notas','TEXTAREA',12,0,1500,'Qu&eacute; se le explic&oacute; al consultor: d&iacute;as por mes, auditor&iacute;a interna, acompa&ntilde;amientos, puntos de atenci&oacute;n.',NULL,NULL,0,0,NULL,NULL),
        (4,'TEXTO30','Comando','HIDDEN',12,0,NULL,NULL,NULL,'LANZ_REUNION',0,1,NULL,NULL),
        (5,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL);

        SET @F = '';
        EXEC dbo.VCT_MAIN_RENDER_FORM @FORM_ID='vctLanzReunion', @TITLE='Reuni&oacute;n de lanzamiento',
             @SUBTITLE='Cierra la gesti&oacute;n de lanzamiento del analista.', @ICON='calendar',
             @LAYOUT='MODAL', @SAVE_LABEL='Guardar', @CANCEL_LABEL='Cancelar', @ERROR_MESSAGE='', @OPEN_ON_RENDER=0, @OUTHTML=@F OUTPUT;
        SET @FORMS = @FORMS + REPLACE(ISNULL(@F,''), 'type="date" ', 'type="date" data-vct-datepicker ');
    END;

    /* ---- datos de entrada: un modal por minuta (campos libres) ---- */
    DECLARE @ID_DOC INT, @DOC_TIT VARCHAR(400), @ID_PD INT, @Q VARCHAR(MAX), @SLOTS VARCHAR(MAX) = '', @I INT = 11;
    WHILE @I <= 29
    BEGIN
        SET @SLOTS = @SLOTS + '<input type="hidden" name="SP.TEXTO' + CONVERT(VARCHAR(2), @I) + '" data-vct-field="TEXTO' + CONVERT(VARCHAR(2), @I) + '" data-vct-default="" value="" data-vct-lanz-slot>';
        SET @I = @I + 1;
    END;

    DECLARE C_DOC CURSOR LOCAL FAST_FORWARD FOR
        SELECT ID_DOCUMENTO, SERVICIO, ID_PROYECTO_DOCUMENTO FROM dbo.VCT_PROYECTO_MINUTAS(@ID_PROYECTO) ORDER BY ID_SERVICIO;
    OPEN C_DOC;
    FETCH NEXT FROM C_DOC INTO @ID_DOC, @DOC_TIT, @ID_PD;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Q = ISNULL((
            SELECT
                '<div class="vct-field ' + CASE WHEN LEN(I.DESCRIPCION) > 55 THEN 'vct-col-12' ELSE 'vct-col-6' END + '">'
              + '<label class="vct-label">' + dbo.VCT_HTML_ESC(LTRIM(RTRIM(I.DESCRIPCION))) + '</label>'
              + '<textarea class="vct-textarea vct-lanz-q" rows="1" data-lanz-item="' + CONVERT(VARCHAR(20), I.ID) + '"'
              + CASE WHEN @CAN_EDIT = 0 THEN ' readonly' ELSE '' END + '>'
              + dbo.VCT_HTML_ESC(COALESCE(PI.VALOR,
                    CASE
                        WHEN I.CAMPO = 'CODIGO' AND I.DESCRIPCION NOT LIKE '%propuesta%' THEN @CODIGO
                        WHEN I.DESCRIPCION LIKE 'Normas%' THEN NULLIF(@NORMAS,'')
                        WHEN I.CAMPO = 'RAZON_SOCIAL_CLIENTE' THEN @CLIENTE
                        WHEN I.CAMPO = 'DOMICILIO' THEN NULLIF(@DOMICILIO,'')
                        WHEN I.CAMPO = 'CONTACTO_CLIENTE' THEN NULLIF(@CONTACTO,'')
                        WHEN I.CAMPO = 'OBSERVACIONES' THEN NULLIF(@ANALISTA,'')
                        WHEN I.CAMPO = 'NORMAS' THEN NULLIF(@NORMAS,'')
                        WHEN I.CAMPO = 'FECHA_INICIO_REAL' THEN CONVERT(VARCHAR(10), @F_INI, 103)
                        WHEN I.CAMPO = 'FECHA_FIN_REAL' THEN CONVERT(VARCHAR(10), @F_FIN, 103)
                        WHEN I.DESCRIPCION LIKE 'Profesional%' THEN NULLIF(@CONSULTORES_TXT,'')
                        WHEN I.DESCRIPCION LIKE 'Nivel de Riesgo%' THEN @RIESGO
                    END, ''))
              + '</textarea></div>'
            FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS I
            LEFT JOIN dbo.VCT_PROYECTOS_DOCUMENTOS_ITEMS PI
                   ON PI.ID_PROYECTO_DOCUMENTO = @ID_PD AND PI.ID_DOCUMENTO_ITEM = I.ID
            WHERE I.ID_DOCUMENTO = @ID_DOC AND I.ACTIVO = 1 AND UPPER(ISNULL(I.GRUPO,'')) <> 'CIERRE'
            ORDER BY ISNULL(I.ORDEN, 999), I.ID
            FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');

        SET @FORMS = @FORMS
          + '<div id="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" class="vct-modal vct-form-shell vct-form-large vct-lanz-datos" data-vct-component="modal" data-vct-id="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" data-vct-form-scope data-vct-form-size="large" data-vct-lanz-datos>'
          + '<div class="vct-modal-backdrop" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '"></div>'
          + '<div class="vct-modal-dialog">'
          +   '<div class="vct-modal-header vct-form-header"><div class="vct-form-header-accent"></div>'
          +     '<div class="vct-form-header-icon" data-vct-form-icon-wrap><span data-vct-icon="file-text" data-vct-form-icon></span></div>'
          +     '<div class="vct-form-header-copy"><h3 class="vct-modal-title" data-vct-form-title>Datos de entrada &middot; ' + dbo.VCT_HTML_ESC(@DOC_TIT) + '</h3>'
          +     '<p class="vct-modal-subtitle" data-vct-form-subtitle>Todo lo que antes iba en la minuta de gesti&oacute;n. Campos libres: complet&aacute; lo que aplique.</p></div>'
          +     '<button type="button" class="vct-form-close" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '" aria-label="Cerrar">&times;</button>'
          +   '</div>'
          +   '<div class="vct-modal-body vct-form-body">'
          +     '<div class="vct-validation-box" data-vct-validation-box style="display:none;"></div>'
          +     '<div class="vct-lanz-search"><span data-vct-icon="search"></span><input type="text" class="vct-input" placeholder="Buscar un dato..." data-vct-lanz-filter autocomplete="off"></div>'
          +     '<div class="vct-form-grid">' + @Q + '</div>'
          +     '<input type="hidden" name="SP.IDSELEC03" data-vct-field="IDSELEC03" data-vct-default="' + CONVERT(VARCHAR(20), @ID_DOC) + '" value="' + CONVERT(VARCHAR(20), @ID_DOC) + '">'
          +     '<input type="hidden" name="SP.TEXTO30" data-vct-field="TEXTO30" data-vct-default="LANZ_DATOS" value="LANZ_DATOS">'
          +     @SLOTS
          +     '<input type="hidden" name="SP.FLAG01" data-vct-field="FLAG01" data-vct-default="1" value="1">'
          +   '</div>'
          +   '<div class="vct-modal-footer vct-form-footer">'
          +     '<span class="vct-lanz-count" data-vct-lanz-count></span>'
          +     '<button type="button" class="vct-btn vct-btn-secondary" data-vct-command="close-modal" data-vct-target="vctLanzDatos' + CONVERT(VARCHAR(20), @ID_DOC) + '">' + CASE WHEN @CAN_EDIT = 1 THEN 'Cancelar' ELSE 'Cerrar' END + '</button>'
          +     CASE WHEN @CAN_EDIT = 1 THEN '<button type="button" class="vct-btn vct-btn-primary" data-vct-command="validate-next"><span data-vct-icon="save"></span><span>Guardar</span></button>' ELSE '' END
          +   '</div>'
          + '</div></div>';

        FETCH NEXT FROM C_DOC INTO @ID_DOC, @DOC_TIT, @ID_PD;
    END;
    CLOSE C_DOC;
    DEALLOCATE C_DOC;
END
GO

PRINT 'OK: pantalla del analista instalada (permiso, template, funciones y SP de accion/render).';
GO
