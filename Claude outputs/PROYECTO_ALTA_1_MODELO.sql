/* ========================================================================
   PROYECTO_ALTA_1_MODELO                                   (paso 1 de 3)
   ------------------------------------------------------------------------
   Alta de proyecto desde cero. Este script deja listo el MODELO y la
   PARAMETRIA DEL WORKFLOW que usan los SP del paso 2. No crea SP, vistas,
   funciones ni permisos. Re-ejecutable (no duplica nada).

   1. VCT_PROYECTOS.TIPO_PROYECTO  varchar(20) NULL
        valores: IMPLEMENTACION | MANTENIMIENTO  (CHECK; no hay tabla)
   2. Tipificacion de acciones (una sola vez, generica):
        VCT_PRM_ACCIONES_TIPOS     PROYECTO        "Proyecto"
        VCT_PRM_ACCIONES_SUBTIPOS  ALTA_PROYECTO   "Alta de proyecto" (tipo PROYECTO)
      (los demas tipos/subtipos/resultados que usa el alta ya existen)
   3. Workflow = dbo.VCT_PRM_ACCIONES_REGLAS (tabla existente, la mantiene
      el equipo de desarrollo por script; el usuario no la edita).
      Cada evento que dispara un SP genera una accion por regla activa:
        evento PROYECTO_ALTA
          PROY_ALTA_REGISTRO               Proyecto / Alta de proyecto
                                           estado CUMPLIDA, sin responsable, sin mail
        evento ANALISTA_ASIGNADO  (reglas 1 y 2 ya existentes)
          PROY_ANALISTA_ASIGNADO_REGISTRO  Asignacion / Asignacion analista, CUMPLIDA
          PROY_ANALISTA_ASIGNAR_CONSULTORES Asignacion / Asignacion consultor, PENDIENTE
                                           -> mail con template PROYECTO_ANALISTA_ASIGNADO
      DESTINATARIO_ROL = VCT_PRM_PROYECTOS_ROLES.CODIGO. Las reglas 1 y 2
      tenian 'ANALISTA_PROYECTO', que no existe como rol: pasan a 'ANALISTA'.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @TRG_ON BIT = 0;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    SET @TRG_ON = 1;
END;

/* ---------------- 1. columna TIPO_PROYECTO ---------------- */
BEGIN TRY
    IF COL_LENGTH('dbo.VCT_PROYECTOS', 'TIPO_PROYECTO') IS NULL
    BEGIN
        EXEC ('ALTER TABLE dbo.VCT_PROYECTOS ADD TIPO_PROYECTO VARCHAR(20) NULL;');
        PRINT 'OK   VCT_PROYECTOS.TIPO_PROYECTO agregado.';
    END
    ELSE PRINT 'OK   VCT_PROYECTOS.TIPO_PROYECTO ya existia.';

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_VCT_PROYECTOS_TIPO_PROYECTO')
    BEGIN
        EXEC ('ALTER TABLE dbo.VCT_PROYECTOS ADD CONSTRAINT CK_VCT_PROYECTOS_TIPO_PROYECTO
               CHECK (TIPO_PROYECTO IS NULL OR TIPO_PROYECTO IN (''IMPLEMENTACION'',''MANTENIMIENTO''));');
        PRINT 'OK   CHECK CK_VCT_PROYECTOS_TIPO_PROYECTO creado.';
    END;
END TRY
BEGIN CATCH
    PRINT 'FALLO columna TIPO_PROYECTO: ' + ERROR_MESSAGE();
END CATCH;

/* ---------------- 2. tipo PROYECTO / subtipo ALTA_PROYECTO ---------------- */
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_TIPOS WHERE CODIGO = 'PROYECTO')
    BEGIN
        INSERT INTO dbo.VCT_PRM_ACCIONES_TIPOS (CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
        SELECT 'PROYECTO', 'Proyecto', ISNULL(MAX(ORDEN), 0) + 10, 1, GETDATE(), 'PROYECTO_ALTA'
        FROM dbo.VCT_PRM_ACCIONES_TIPOS;
        PRINT 'OK   tipo de accion PROYECTO creado.';
    END
    ELSE PRINT 'OK   tipo de accion PROYECTO ya existia.';

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'ALTA_PROYECTO')
    BEGIN
        INSERT INTO dbo.VCT_PRM_ACCIONES_SUBTIPOS (ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
        SELECT T.ID, 'ALTA_PROYECTO', 'Alta de proyecto',
               ISNULL((SELECT MAX(ORDEN) FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS), 0) + 10, 1, GETDATE(), 'PROYECTO_ALTA'
        FROM dbo.VCT_PRM_ACCIONES_TIPOS T WHERE T.CODIGO = 'PROYECTO';
        PRINT 'OK   subtipo de accion ALTA_PROYECTO creado.';
    END
    ELSE PRINT 'OK   subtipo de accion ALTA_PROYECTO ya existia.';
END TRY
BEGIN CATCH
    PRINT 'FALLO tipificacion: ' + ERROR_MESSAGE();
END CATCH;

/* ---------------- 3. reglas del workflow ---------------- */
BEGIN TRY
    DECLARE @T_PROY INT     = (SELECT ID FROM dbo.VCT_PRM_ACCIONES_TIPOS     WHERE CODIGO = 'PROYECTO'),
            @S_ALTA INT     = (SELECT ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS  WHERE CODIGO = 'ALTA_PROYECTO'),
            @E_CUMP INT     = (SELECT ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS   WHERE CODIGO = 'CUMPLIDA'),
            @P_NORM INT     = (SELECT ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WHERE CODIGO = 'NORMAL'),
            @TPL_AN INT     = (SELECT ID FROM dbo.VCT_PRM_EMAIL_TEMPLATES    WHERE CODIGO = 'PROYECTO_ANALISTA_ASIGNADO');

    /* 3a. nueva regla: registro del alta */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_REGLAS WHERE CODIGO = 'PROY_ALTA_REGISTRO')
    BEGIN
        INSERT INTO dbo.VCT_PRM_ACCIONES_REGLAS
            (CODIGO, DESCRIPCION, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, ID_ESTADO_INICIAL, ID_PRIORIDAD,
             DESTINATARIO_ROL, TITULO_PLANTILLA, DETALLE_PLANTILLA, DIAS_VENCIMIENTO, GENERA_EMAIL, ID_EMAIL_TEMPLATE,
             ACTIVO, FECHA_ALTA, USUARIO_ALTA)
        VALUES
            ('PROY_ALTA_REGISTRO', 'Registro del alta del proyecto (queda en el historial)', 'PROYECTO_ALTA',
             @T_PROY, @S_ALTA, @E_CUMP, @P_NORM,
             NULL, 'Alta de proyecto ({{CODIGO_PROYECTO}}) {{PROYECTO}}',
             'Proyecto dado de alta para {{CLIENTE}}. Servicios: {{SERVICIOS}}. Normas: {{NORMAS}}.',
             0, 0, NULL, 1, GETDATE(), 'PROYECTO_ALTA');
        PRINT 'OK   regla PROY_ALTA_REGISTRO creada.';
    END
    ELSE PRINT 'OK   regla PROY_ALTA_REGISTRO ya existia.';

    /* 3b. reglas existentes del evento ANALISTA_ASIGNADO: rol real del equipo */
    UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
       SET DESTINATARIO_ROL = 'ANALISTA', FECHA_UPD = GETDATE(), USUARIO_UPD = 'PROYECTO_ALTA'
     WHERE CODIGO IN ('PROY_ANALISTA_ASIGNADO_REGISTRO','PROY_ANALISTA_ASIGNAR_CONSULTORES')
       AND ISNULL(DESTINATARIO_ROL,'') <> 'ANALISTA';
    PRINT 'OK   reglas ANALISTA_ASIGNADO con DESTINATARIO_ROL = ANALISTA (' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' actualizadas).';

    /* 3c. la accion pendiente para el analista manda el mail del template */
    IF @TPL_AN IS NULL
        PRINT 'AVISO no existe el template PROYECTO_ANALISTA_ASIGNADO: la regla queda sin mail.';
    ELSE
    BEGIN
        UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
           SET GENERA_EMAIL = 1, ID_EMAIL_TEMPLATE = @TPL_AN, FECHA_UPD = GETDATE(), USUARIO_UPD = 'PROYECTO_ALTA'
         WHERE CODIGO = 'PROY_ANALISTA_ASIGNAR_CONSULTORES'
           AND (GENERA_EMAIL = 0 OR ISNULL(ID_EMAIL_TEMPLATE,0) <> @TPL_AN);
        PRINT 'OK   regla PROY_ANALISTA_ASIGNAR_CONSULTORES envia PROYECTO_ANALISTA_ASIGNADO.';
    END;
END TRY
BEGIN CATCH
    PRINT 'FALLO reglas: ' + ERROR_MESSAGE();
END CATCH;

IF @TRG_ON = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;

/* ---------------- control (solo lectura) ---------------- */
SELECT R.ID, R.CODIGO, R.CODIGO_EVENTO, T.CODIGO AS TIPO, S.CODIGO AS SUBTIPO, E.CODIGO AS ESTADO_INICIAL,
       R.DESTINATARIO_ROL, R.DIAS_VENCIMIENTO, R.GENERA_EMAIL, TP.CODIGO AS TEMPLATE, TP.DESTINO_TIPO, R.ACTIVO
FROM dbo.VCT_PRM_ACCIONES_REGLAS R
LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T     ON T.ID = R.ID_TIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S  ON S.ID = R.ID_SUBTIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E   ON E.ID = R.ID_ESTADO_INICIAL
LEFT JOIN dbo.VCT_PRM_EMAIL_TEMPLATES TP   ON TP.ID = R.ID_EMAIL_TEMPLATE
ORDER BY R.CODIGO_EVENTO, R.ID;
