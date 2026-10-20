/* ========================================================================
   PASO5_3_ACCION_44_AL_PLAN  (datos: una sola accion)
   ------------------------------------------------------------------------
   La accion 44 (proyecto 1348) se cargo a mano con el subtipo CARGA_PLAN
   (que es del workflow) pero es trabajo sobre el item 4.1. PASO5_2 la dejo en
   Workflow; aca pasa al plan:
     ORIGEN = MANUAL, subtipo TRABAJO_PLAN_ITEM (mismo tipo TAREA),
     ID_PLAN_ITEM = 286 (4.1), ID_PLAN del item, titulo como el resto del plan.
   Repite las condiciones (si ya cambio, no hace nada) y deja historial.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRAN;
    DECLARE @SUB INT, @SUB_TIPO INT, @SUB_DES VARCHAR(150), @ITEM INT, @PLAN INT, @ITEM_TIT VARCHAR(400), @EST INT, @N INT = 0;
    SELECT @SUB = ID, @SUB_TIPO = ID_TIPO, @SUB_DES = DESCRIPCION FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'TRABAJO_PLAN_ITEM';
    SELECT @ITEM = I.ID, @PLAN = I.ID_PLAN, @ITEM_TIT = ISNULL(I.CODIGO_ITEM + ' ', '') + ISNULL(I.TITULO, ''), @EST = A.ID_ESTADO
    FROM dbo.VCT_ACCIONES A
    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO AND S.CODIGO = 'CARGA_PLAN'
    INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS I ON I.ID = 286 AND ISNULL(I.GRUPO,'') <> 'CAPITULO'
    INNER JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID = I.ID_PLAN AND PL.ID_PROYECTO = A.ID_PROYECTO
    WHERE A.ID = 44 AND A.ID_PLAN_ITEM IS NULL AND A.ID_TIPO = @SUB_TIPO;

    IF @SUB IS NULL RAISERROR('Falta el subtipo TRABAJO_PLAN_ITEM.', 16, 1);
    IF @ITEM IS NOT NULL
    BEGIN
        UPDATE dbo.VCT_ACCIONES
           SET ORIGEN = 'MANUAL', ID_SUBTIPO = @SUB, ID_PLAN = @PLAN, ID_PLAN_ITEM = @ITEM,
               TITULO = LEFT(@SUB_DES + ' - ' + @ITEM_TIT, 300), FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_3'
         WHERE ID = 44;
        SET @N = @@ROWCOUNT;
        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
        VALUES (44, @EST, @EST, 'MODIFICADA', 'Pasa al plan: subtipo CARGA_PLAN -> TRABAJO_PLAN_ITEM, item 286 (PASO5_3).', 'SISTEMA', GETDATE(), 'PASO5_3');
    END;
    PRINT 'OK   accion 44 pasada al plan: ' + CONVERT(VARCHAR(10), @N) + ' de 1.';
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT 'FALLO PASO5_3 (no se modifico nada): ' + ERROR_MESSAGE();
END CATCH;

SELECT A.ID, A.ORIGEN, S.CODIGO AS SUBTIPO, A.ID_PLAN, A.ID_PLAN_ITEM, E.CODIGO AS ESTADO, A.TITULO
FROM dbo.VCT_ACCIONES A
LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID = 44;
