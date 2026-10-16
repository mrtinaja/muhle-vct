/* ========================================================================
   PASO2_1_PARAMETRIA
   ------------------------------------------------------------------------
   Parametria del paso 2 (asignacion de consultor), segun el documento
   "Sistema de Gestion de Proyectos VCT - Diseno funcional y tecnico",
   seccion 4 (paso 2) y seccion 7.
     1. Subtipos (tipo TAREA):  CARGA_DATOS_ENTRADA, LANZAMIENTO
     2. Resultado:              CONSULTOR_ASIGNADO
     3. Reglas del evento CONSULTORES_ASIGNADOS (al asignar el lider):
          PROY_ANALISTA_DATOS_ENTRADA -> ANALISTA, vence a los 5 dias
          PROY_ANALISTA_LANZAMIENTO   -> ANALISTA, vence a los 10 dias
        Regla 3 PROY_CONSULTORES_CARGAR_PLAN pasa al evento
        PROYECTO_INICIADO (el plan va despues del lanzamiento).
   Solo datos. No toca permisos, vistas ni SPs. Re-ejecutable.
   Los dias se cambian en VCT_PRM_ACCIONES_REGLAS.DIAS_VENCIMIENTO.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRAN;

    DECLARE @ID_TAREA INT, @SUB_DE INT, @SUB_LA INT, @PRIO INT, @EST_PEND INT;
    SELECT @ID_TAREA = ID FROM dbo.VCT_PRM_ACCIONES_TIPOS WHERE CODIGO = 'TAREA';
    SELECT @EST_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'PENDIENTE';
    SELECT @PRIO = ID_PRIORIDAD FROM dbo.VCT_PRM_ACCIONES_REGLAS WHERE CODIGO = 'PROY_ANALISTA_ASIGNAR_CONSULTORES';
    IF @ID_TAREA IS NULL OR @EST_PEND IS NULL OR @PRIO IS NULL
        RAISERROR('Falta el tipo TAREA, el estado PENDIENTE o la regla PROY_ANALISTA_ASIGNAR_CONSULTORES.', 16, 1);

    /* ---------- 1. subtipos ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'CARGA_DATOS_ENTRADA')
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PRM_ACCIONES_SUBTIPOS'), 'ID', 'IsIdentity') = 1
            INSERT INTO dbo.VCT_PRM_ACCIONES_SUBTIPOS (ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            VALUES (@ID_TAREA, 'CARGA_DATOS_ENTRADA', 'Carga de datos de entrada', 31, 1, GETDATE(), 'PASO2');
        ELSE
            INSERT INTO dbo.VCT_PRM_ACCIONES_SUBTIPOS (ID, ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            SELECT ISNULL(MAX(ID), 0) + 1, @ID_TAREA, 'CARGA_DATOS_ENTRADA', 'Carga de datos de entrada', 31, 1, GETDATE(), 'PASO2'
            FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS;
        PRINT 'OK   subtipo CARGA_DATOS_ENTRADA creado.';
    END
    ELSE PRINT 'OK   subtipo CARGA_DATOS_ENTRADA ya existia.';

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'LANZAMIENTO')
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PRM_ACCIONES_SUBTIPOS'), 'ID', 'IsIdentity') = 1
            INSERT INTO dbo.VCT_PRM_ACCIONES_SUBTIPOS (ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            VALUES (@ID_TAREA, 'LANZAMIENTO', 'Reuni' + CHAR(243) + 'n de lanzamiento', 32, 1, GETDATE(), 'PASO2');
        ELSE
            INSERT INTO dbo.VCT_PRM_ACCIONES_SUBTIPOS (ID, ID_TIPO, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            SELECT ISNULL(MAX(ID), 0) + 1, @ID_TAREA, 'LANZAMIENTO', 'Reuni' + CHAR(243) + 'n de lanzamiento', 32, 1, GETDATE(), 'PASO2'
            FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS;
        PRINT 'OK   subtipo LANZAMIENTO creado.';
    END
    ELSE PRINT 'OK   subtipo LANZAMIENTO ya existia.';

    SELECT @SUB_DE = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'CARGA_DATOS_ENTRADA';
    SELECT @SUB_LA = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'LANZAMIENTO';

    /* ---------- 2. resultado ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WHERE CODIGO = 'CONSULTOR_ASIGNADO')
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PRM_ACCIONES_RESULTADOS'), 'ID', 'IsIdentity') = 1
            INSERT INTO dbo.VCT_PRM_ACCIONES_RESULTADOS (CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            VALUES ('CONSULTOR_ASIGNADO', 'Consultor asignado', 10, 1, GETDATE(), 'PASO2');
        ELSE
            INSERT INTO dbo.VCT_PRM_ACCIONES_RESULTADOS (ID, CODIGO, DESCRIPCION, ORDEN, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            SELECT ISNULL(MAX(ID), 0) + 1, 'CONSULTOR_ASIGNADO', 'Consultor asignado', 10, 1, GETDATE(), 'PASO2'
            FROM dbo.VCT_PRM_ACCIONES_RESULTADOS;
        PRINT 'OK   resultado CONSULTOR_ASIGNADO creado.';
    END
    ELSE PRINT 'OK   resultado CONSULTOR_ASIGNADO ya existia.';

    /* ---------- 3. reglas ---------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_REGLAS WHERE CODIGO = 'PROY_ANALISTA_DATOS_ENTRADA')
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PRM_ACCIONES_REGLAS'), 'ID', 'IsIdentity') = 1
            INSERT INTO dbo.VCT_PRM_ACCIONES_REGLAS
                (CODIGO, DESCRIPCION, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, ID_ESTADO_INICIAL, ID_PRIORIDAD, DESTINATARIO_ROL,
                 TITULO_PLANTILLA, DETALLE_PLANTILLA, DIAS_VENCIMIENTO, GENERA_EMAIL, ID_EMAIL_TEMPLATE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            VALUES ('PROY_ANALISTA_DATOS_ENTRADA', 'Solicita al analista cargar los datos de entrada y las consideraciones del proyecto.',
                    'CONSULTORES_ASIGNADOS', @ID_TAREA, @SUB_DE, @EST_PEND, @PRIO, 'ANALISTA',
                    'Cargar datos de entrada - {{CODIGO_PROYECTO}}',
                    'Cargar datos de entrada, consideraciones y riesgos del proyecto {{CODIGO_PROYECTO}} - {{PROYECTO}}.',
                    5, 0, NULL, 1, GETDATE(), 'PASO2');
        ELSE
            INSERT INTO dbo.VCT_PRM_ACCIONES_REGLAS
                (ID, CODIGO, DESCRIPCION, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, ID_ESTADO_INICIAL, ID_PRIORIDAD, DESTINATARIO_ROL,
                 TITULO_PLANTILLA, DETALLE_PLANTILLA, DIAS_VENCIMIENTO, GENERA_EMAIL, ID_EMAIL_TEMPLATE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            SELECT ISNULL(MAX(ID), 0) + 1, 'PROY_ANALISTA_DATOS_ENTRADA', 'Solicita al analista cargar los datos de entrada y las consideraciones del proyecto.',
                   'CONSULTORES_ASIGNADOS', @ID_TAREA, @SUB_DE, @EST_PEND, @PRIO, 'ANALISTA',
                   'Cargar datos de entrada - {{CODIGO_PROYECTO}}',
                   'Cargar datos de entrada, consideraciones y riesgos del proyecto {{CODIGO_PROYECTO}} - {{PROYECTO}}.',
                   5, 0, NULL, 1, GETDATE(), 'PASO2'
            FROM dbo.VCT_PRM_ACCIONES_REGLAS;
        PRINT 'OK   regla PROY_ANALISTA_DATOS_ENTRADA creada.';
    END
    ELSE PRINT 'OK   regla PROY_ANALISTA_DATOS_ENTRADA ya existia.';

    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PRM_ACCIONES_REGLAS WHERE CODIGO = 'PROY_ANALISTA_LANZAMIENTO')
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PRM_ACCIONES_REGLAS'), 'ID', 'IsIdentity') = 1
            INSERT INTO dbo.VCT_PRM_ACCIONES_REGLAS
                (CODIGO, DESCRIPCION, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, ID_ESTADO_INICIAL, ID_PRIORIDAD, DESTINATARIO_ROL,
                 TITULO_PLANTILLA, DETALLE_PLANTILLA, DIAS_VENCIMIENTO, GENERA_EMAIL, ID_EMAIL_TEMPLATE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            VALUES ('PROY_ANALISTA_LANZAMIENTO', 'Solicita al analista coordinar la reuni' + CHAR(243) + 'n de lanzamiento con el consultor y el cliente.',
                    'CONSULTORES_ASIGNADOS', @ID_TAREA, @SUB_LA, @EST_PEND, @PRIO, 'ANALISTA',
                    'Reuni' + CHAR(243) + 'n de lanzamiento - {{CODIGO_PROYECTO}}',
                    'Coordinar y registrar la reuni' + CHAR(243) + 'n de lanzamiento del proyecto {{CODIGO_PROYECTO}} - {{PROYECTO}}.',
                    10, 0, NULL, 1, GETDATE(), 'PASO2');
        ELSE
            INSERT INTO dbo.VCT_PRM_ACCIONES_REGLAS
                (ID, CODIGO, DESCRIPCION, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, ID_ESTADO_INICIAL, ID_PRIORIDAD, DESTINATARIO_ROL,
                 TITULO_PLANTILLA, DETALLE_PLANTILLA, DIAS_VENCIMIENTO, GENERA_EMAIL, ID_EMAIL_TEMPLATE, ACTIVO, FECHA_ALTA, USUARIO_ALTA)
            SELECT ISNULL(MAX(ID), 0) + 1, 'PROY_ANALISTA_LANZAMIENTO', 'Solicita al analista coordinar la reuni' + CHAR(243) + 'n de lanzamiento con el consultor y el cliente.',
                   'CONSULTORES_ASIGNADOS', @ID_TAREA, @SUB_LA, @EST_PEND, @PRIO, 'ANALISTA',
                   'Reuni' + CHAR(243) + 'n de lanzamiento - {{CODIGO_PROYECTO}}',
                   'Coordinar y registrar la reuni' + CHAR(243) + 'n de lanzamiento del proyecto {{CODIGO_PROYECTO}} - {{PROYECTO}}.',
                   10, 0, NULL, 1, GETDATE(), 'PASO2'
            FROM dbo.VCT_PRM_ACCIONES_REGLAS;
        PRINT 'OK   regla PROY_ANALISTA_LANZAMIENTO creada.';
    END
    ELSE PRINT 'OK   regla PROY_ANALISTA_LANZAMIENTO ya existia.';

    UPDATE dbo.VCT_PRM_ACCIONES_REGLAS
       SET CODIGO_EVENTO = 'PROYECTO_INICIADO', FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO2'
     WHERE CODIGO = 'PROY_CONSULTORES_CARGAR_PLAN' AND CODIGO_EVENTO <> 'PROYECTO_INICIADO';
    PRINT 'OK   regla PROY_CONSULTORES_CARGAR_PLAN en el evento PROYECTO_INICIADO.';

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT 'FALLO parametria del paso 2: ' + ERROR_MESSAGE();
END CATCH;

SELECT ID, CODIGO, CODIGO_EVENTO, ID_TIPO, ID_SUBTIPO, DESTINATARIO_ROL, DIAS_VENCIMIENTO, GENERA_EMAIL, ACTIVO
FROM dbo.VCT_PRM_ACCIONES_REGLAS ORDER BY ID;
GO
