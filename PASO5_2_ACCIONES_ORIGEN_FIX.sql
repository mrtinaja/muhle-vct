/* ========================================================================
   PASO5_2_ACCIONES_ORIGEN_FIX  (datos: corre solo sobre 4 acciones puntuales)
   ------------------------------------------------------------------------
   Segun DIAG_ACCIONES_ORIGEN (20/10/2026):
     - 37 (1347, VISITA_HISTORICA) y 44 (1348, CARGA_PLAN): son del sistema
       -> ORIGEN = 'SISTEMA' (pasan al grupo Workflow).
     - 45 (1348) -> item 286 "4.1 Comprension de la organizacion..."
       46 (1348) -> item 287 "4.2 Comprension de las necesidades..."
       -> ID_PLAN_ITEM / ID_PLAN (pasan al grupo Plan estrategico).
   Las otras 9 (proyectos 1341, 1342, 1343 y las 36 / 38 del 1347) no tienen
   item candidato: NO se tocan.
   Cada UPDATE repite las condiciones del diagnostico (si la accion ya cambio,
   no se modifica) y deja un registro en VCT_ACCIONES_HISTORIAL.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRAN;
    /* acciones que cumplen todavia las condiciones del diagnostico */
    DECLARE @W TABLE (ID_ACCION INT, ID_ITEM INT, ID_PLAN INT, ID_ESTADO INT);
    INSERT INTO @W (ID_ACCION, ID_ITEM, ID_PLAN, ID_ESTADO)
    SELECT A.ID, NULL, NULL, A.ID_ESTADO
    FROM dbo.VCT_ACCIONES A
    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO
    WHERE A.ID IN (37, 44) AND A.ORIGEN = 'MANUAL' AND A.ID_PLAN_ITEM IS NULL
      AND S.CODIGO IN ('VISITA_HISTORICA', 'CARGA_PLAN');
    INSERT INTO @W (ID_ACCION, ID_ITEM, ID_PLAN, ID_ESTADO)
    SELECT A.ID, I.ID, I.ID_PLAN, A.ID_ESTADO
    FROM dbo.VCT_ACCIONES A
    INNER JOIN (SELECT 45 AS ID_ACCION, 286 AS ID_ITEM UNION ALL SELECT 46, 287) M ON M.ID_ACCION = A.ID
    INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS I ON I.ID = M.ID_ITEM AND ISNULL(I.GRUPO,'') <> 'CAPITULO'
    INNER JOIN dbo.VCT_PROYECTOS_PLANES PL ON PL.ID = I.ID_PLAN AND PL.ID_PROYECTO = A.ID_PROYECTO
    INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO AND S.CODIGO = 'TRABAJO_PLAN_ITEM'
    WHERE A.ORIGEN = 'MANUAL' AND A.ID_PLAN_ITEM IS NULL;

    /* 1. workflow: ORIGEN = SISTEMA */
    UPDATE A SET ORIGEN = 'SISTEMA', FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_2'
    FROM dbo.VCT_ACCIONES A INNER JOIN @W W ON W.ID_ACCION = A.ID AND W.ID_ITEM IS NULL;
    PRINT 'OK   origen corregido: ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' de 2.';

    /* 2. plan: item del plan del mismo proyecto */
    UPDATE A SET ID_PLAN_ITEM = W.ID_ITEM, ID_PLAN = W.ID_PLAN, FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_2'
    FROM dbo.VCT_ACCIONES A INNER JOIN @W W ON W.ID_ACCION = A.ID AND W.ID_ITEM IS NOT NULL;
    PRINT 'OK   acciones vinculadas al plan: ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' de 2.';

    /* historial de cada cambio */
    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
    SELECT W.ID_ACCION, W.ID_ESTADO, W.ID_ESTADO, 'MODIFICADA',
           CASE WHEN W.ID_ITEM IS NULL THEN 'Correccion de origen: MANUAL -> SISTEMA (PASO5_2).'
                ELSE 'Vinculada al item del plan ' + CONVERT(VARCHAR(20), W.ID_ITEM) + ' (PASO5_2).' END,
           'SISTEMA', GETDATE(), 'PASO5_2'
    FROM @W W;

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT 'FALLO PASO5_2 (no se modifico nada): ' + ERROR_MESSAGE();
END CATCH;

/* control */
SELECT A.ID, P.CODIGO AS PROYECTO, A.ORIGEN, S.CODIGO AS SUBTIPO, A.ID_PLAN, A.ID_PLAN_ITEM, E.CODIGO AS ESTADO, A.TITULO
FROM dbo.VCT_ACCIONES A
INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = A.ID_PROYECTO
LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.ID_SUBTIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
WHERE A.ID IN (37, 44, 45, 46)
ORDER BY A.ID;
