/* ========================================================================
   PASO5_4_PLAN_PRUEBA_1348  (datos de prueba del plan estrategico)
   ------------------------------------------------------------------------
   Completa el plan del proyecto @CODIGO para probar el arbol, el cronograma,
   los avances y la pestana Acciones. NO toca lo ya cargado:
     - solo pone fechas en items sin inicio ni fin (los subitems usan las de su item)
     - solo crea acciones en items / subitems que no tienen acciones (sin contar canceladas)
   Logica de fechas (todo dentro del rango del proyecto):
     - la ventana de trabajo es el 80% del proyecto; los items se reparten en orden
       (capitulo, item) con ventanas que se solapan; minimo 4 dias por item
     - hitos (capitulo H): auditoria interna fin-12, legal fin-6, certificacion fin-1
     - fin real: items vencidos con todas sus acciones cumplidas
   Logica de acciones (en el rango del item superior):
     - item sin subitems: 3 acciones (relevar / documentar / validar con el cliente)
     - item con subitems: 1 accion propia (reunion de revision) + 2 por subitem
       (relevar / revisar-aprobar)
     - responsables: consultor lider, analista y cliente del proyecto
     - estado segun hoy: vencida en fecha -> cumplida (1 de cada 4 queda vencida);
       en curso -> en proceso / pendiente; futura -> pendiente
   Todo lo que genera queda con USUARIO_ALTA / USUARIO_UPD = 'PASO5_4'.
   Para deshacerlo: @DESHACER = 1 (borra solo lo generado por este script).
   Correr DESPUES de PASO5_1 (usa los subtipos nuevos; si no estan, usa
   "Trabajo sobre item").
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @CODIGO VARCHAR(50) = '1348',
        @DESHACER BIT = 0;

DECLARE @PROY INT, @CLI INT, @PLAN INT, @INI DATE, @FIN DATE, @HOY DATE = CONVERT(DATE, GETDATE()),
        @EQ_LIDER INT, @ID_LIDER INT, @EQ_ANA INT, @ID_ANA INT,
        @EST_PEND INT, @EST_PROC INT, @EST_CUMP INT, @EST_CANC INT, @PRIO_N INT, @PRIO_A INT, @RES_OK INT, @TIPO_TAREA INT,
        @ST_TRAB INT, @ST_DOC INT, @ST_CLI INT, @ST_REU INT, @ST_REV INT, @ST_AV INT, @N INT;

SELECT @PROY = P.ID, @CLI = P.IDCLIENTE, @INI = CONVERT(DATE, ISNULL(P.FECHA_INICIO_REAL, P.FECHA_INICIO)), @FIN = CONVERT(DATE, P.FECHA_FIN)
FROM dbo.VCT_PROYECTOS P WHERE P.CODIGO = @CODIGO;
SELECT TOP 1 @PLAN = ID FROM dbo.VCT_PROYECTOS_PLANES WHERE ID_PROYECTO = @PROY ORDER BY VERSION DESC, ID DESC;
SELECT TOP 1 @EQ_LIDER = EQ.ID, @ID_LIDER = EQ.ID_CONSULTOR FROM dbo.VCT_PROYECTOS_EQUIPO EQ
INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL AND R.CODIGO = 'CONSULTOR_LIDER'
WHERE EQ.ID_PROYECTO = @PROY AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.ID;
SELECT TOP 1 @EQ_ANA = EQ.ID, @ID_ANA = EQ.ID_EMPLEADO FROM dbo.VCT_PROYECTOS_EQUIPO EQ
INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL AND R.CODIGO = 'ANALISTA'
WHERE EQ.ID_PROYECTO = @PROY AND EQ.ESTADO = 'ACTIVO' ORDER BY EQ.PRINCIPAL DESC, EQ.ID;
SELECT @EST_PEND = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'PENDIENTE';
SELECT @EST_PROC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'EN_PROCESO';
SELECT @EST_CUMP = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'CUMPLIDA';
SELECT @EST_CANC = ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'CANCELADA';
SELECT @PRIO_N = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WHERE CODIGO = 'NORMAL';
SELECT @PRIO_A = ID FROM dbo.VCT_PRM_ACCIONES_PRIORIDADES WHERE CODIGO = 'ALTA';
SELECT @RES_OK = ID FROM dbo.VCT_PRM_ACCIONES_RESULTADOS WHERE CODIGO = 'COMPLETADA';
SELECT @ST_TRAB = ID, @TIPO_TAREA = ID_TIPO FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'TRABAJO_PLAN_ITEM';
SELECT @ST_DOC = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'DOCUMENTO_PENDIENTE' AND ACTIVO = 1;
SELECT @ST_CLI = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'PENDIENTE_CLIENTE' AND ACTIVO = 1;
SELECT @ST_REU = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'REUNION_CLIENTE' AND ACTIVO = 1;
SELECT @ST_REV = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'DOCUMENTO_REVISION' AND ACTIVO = 1;
SELECT @ST_AV = ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'AVISO_VENCIMIENTO';

IF @PROY IS NULL OR @PLAN IS NULL BEGIN PRINT 'FALLO: el proyecto ' + @CODIGO + ' no existe o no tiene plan.'; RETURN; END;
IF @INI IS NULL OR @FIN IS NULL OR @FIN <= @INI BEGIN PRINT 'FALLO: el proyecto no tiene fecha de inicio y fin validas.'; RETURN; END;
IF @EQ_LIDER IS NULL BEGIN PRINT 'FALLO: el proyecto no tiene consultor lider activo.'; RETURN; END;
IF @EST_PEND IS NULL OR @EST_CUMP IS NULL OR @PRIO_N IS NULL OR @ST_TRAB IS NULL BEGIN PRINT 'FALLO: falta parametria de acciones (PENDIENTE, CUMPLIDA, NORMAL, TRABAJO_PLAN_ITEM).'; RETURN; END;

BEGIN TRY
    BEGIN TRAN;

    IF @DESHACER = 1
    BEGIN
        /* ---------- deshacer: solo lo generado por este script ---------- */
        DECLARE @X TABLE (ID INT PRIMARY KEY);
        INSERT INTO @X SELECT ID FROM dbo.VCT_ACCIONES WHERE ID_PROYECTO = @PROY AND USUARIO_ALTA = 'PASO5_4';
        DELETE H FROM dbo.VCT_ACCIONES_HISTORIAL H INNER JOIN @X X ON X.ID = H.ID_ACCION;
        DELETE AP FROM dbo.VCT_ACCIONES_PARTICIPANTES AP INNER JOIN @X X ON X.ID = AP.ID_ACCION;
        DELETE A FROM dbo.VCT_ACCIONES A INNER JOIN @X X ON X.ID = A.ID;
        SET @N = @@ROWCOUNT;
        UPDATE dbo.VCT_PROYECTOS_PLAN_ITEMS
           SET FECHA_INICIO = NULL, FECHA_VENCIMIENTO = NULL, FECHA_CIERRE = NULL, ID_RESPONSABLE_EQUIPO = NULL, OBSERVACIONES = NULL,
               FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_4_DESHACER'
         WHERE ID_PLAN = @PLAN AND USUARIO_UPD = 'PASO5_4';
        PRINT 'OK   deshecho: ' + CONVERT(VARCHAR(10), @N) + ' acciones borradas, ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + ' items sin fechas.';
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES WHERE ID_PROYECTO = @PROY AND USUARIO_ALTA = 'PASO5_4')
            RAISERROR('Ya se corrio PASO5_4 en este proyecto: corralo con @DESHACER = 1 antes de volver a generarlo.', 16, 1);

        /* ---------- nodos del plan ---------- */
        IF OBJECT_ID('tempdb..#ND') IS NOT NULL DROP TABLE #ND;
        CREATE TABLE #ND (ID INT PRIMARY KEY, PADRE INT, NIV INT, CHAP INT, TOPI INT, GRP VARCHAR(100), CODE VARCHAR(50), TIT VARCHAR(400),
                          CH_ORD INT, ORD INT, HITO BIT, HIJOS INT, FI DATE, FF DATE, TIENE_ACC BIT, SEQ INT, NA INT);
        INSERT INTO #ND (ID, PADRE, NIV, CHAP, TOPI, GRP, CODE, TIT, CH_ORD, ORD, HITO, HIJOS, FI, FF, TIENE_ACC)
        SELECT I.ID, I.ID_PADRE,
               CASE WHEN I.GRUPO = 'CAPITULO' THEN 1 WHEN P.ID IS NULL OR P.GRUPO = 'CAPITULO' THEN 2 ELSE 3 END,
               CASE WHEN I.GRUPO = 'CAPITULO' THEN I.ID WHEN P.GRUPO = 'CAPITULO' THEN P.ID WHEN PP.GRUPO = 'CAPITULO' THEN PP.ID END,
               CASE WHEN I.GRUPO = 'CAPITULO' THEN NULL WHEN P.ID IS NULL OR P.GRUPO = 'CAPITULO' THEN I.ID ELSE P.ID END,
               ISNULL(I.GRUPO,''), ISNULL(I.CODIGO_ITEM,''), ISNULL(I.TITULO,''),
               ISNULL(CASE WHEN I.GRUPO = 'CAPITULO' THEN I.ORDEN WHEN P.GRUPO = 'CAPITULO' THEN P.ORDEN WHEN PP.GRUPO = 'CAPITULO' THEN PP.ORDEN END, 9999),
               ISNULL(I.ORDEN, 0), CASE WHEN I.GRUPO = 'HITO' THEN 1 ELSE 0 END,
               (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID),
               CONVERT(DATE, I.FECHA_INICIO), CONVERT(DATE, I.FECHA_VENCIMIENTO),
               CASE WHEN EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES A WHERE A.ID_PLAN_ITEM = I.ID AND A.ID_ESTADO <> ISNULL(@EST_CANC, -1)) THEN 1 ELSE 0 END
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
        LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P ON P.ID = I.ID_PADRE
        LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS PP ON PP.ID = P.ID_PADRE
        WHERE I.ID_PLAN = @PLAN;

        /* ---------- 1. fechas de los items (nivel 2, no hitos) ---------- */
        DECLARE @D INT = DATEDIFF(DAY, @INI, @FIN), @W INT, @NI INT, @DUR INT;
        SET @W = CASE WHEN @D * 8 / 10 < 10 THEN @D ELSE @D * 8 / 10 END;
        UPDATE N SET SEQ = X.RN FROM #ND N
        INNER JOIN (SELECT ID, ROW_NUMBER() OVER (ORDER BY CH_ORD, ORD, ID) AS RN FROM #ND WHERE NIV = 2 AND HITO = 0) X ON X.ID = N.ID;
        SELECT @NI = COUNT(*) FROM #ND WHERE NIV = 2 AND HITO = 0;
        SET @DUR = CASE WHEN @NI = 0 THEN 4 WHEN 2 * @W / @NI < 4 THEN 4 ELSE 2 * @W / @NI END;
        UPDATE N SET FI = DATEADD(DAY, (N.SEQ - 1) * @W / CASE WHEN @NI = 0 THEN 1 ELSE @NI END, @INI)
        FROM #ND N WHERE N.NIV = 2 AND N.HITO = 0 AND N.FI IS NULL AND N.FF IS NULL;
        UPDATE N SET FF = CASE WHEN DATEADD(DAY, @DUR, N.FI) > @FIN THEN @FIN ELSE DATEADD(DAY, @DUR, N.FI) END
        FROM #ND N WHERE N.NIV = 2 AND N.HITO = 0 AND N.FF IS NULL AND N.FI IS NOT NULL;
        /* hitos: fin-12, fin-6, fin-1 en el orden del capitulo */
        UPDATE N SET FI = DATEADD(DAY, CASE X.RN WHEN 1 THEN -12 WHEN 2 THEN -6 ELSE -1 END, @FIN),
                     FF = DATEADD(DAY, CASE X.RN WHEN 1 THEN -12 WHEN 2 THEN -6 ELSE -1 END, @FIN)
        FROM #ND N INNER JOIN (SELECT ID, ROW_NUMBER() OVER (ORDER BY ORD, ID) AS RN FROM #ND WHERE HITO = 1) X ON X.ID = N.ID
        WHERE N.FI IS NULL AND N.FF IS NULL;
        UPDATE N SET FI = CASE WHEN N.FI < @INI THEN @INI ELSE N.FI END FROM #ND N WHERE N.HITO = 1;

        UPDATE I SET FECHA_INICIO = N.FI, FECHA_VENCIMIENTO = N.FF, ID_RESPONSABLE_EQUIPO = ISNULL(I.ID_RESPONSABLE_EQUIPO, @EQ_LIDER),
                     OBSERVACIONES = CASE WHEN I.OBSERVACIONES IS NOT NULL THEN I.OBSERVACIONES
                                          WHEN N.HITO = 1 THEN 'Fecha a confirmar con el organismo / el cliente.'
                                          WHEN N.SEQ % 3 = 1 THEN 'Ventana de trabajo acordada en la reuni' + CHAR(243) + 'n de lanzamiento.' END,
                     FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_4'
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I INNER JOIN #ND N ON N.ID = I.ID
        WHERE N.NIV = 2 AND I.FECHA_INICIO IS NULL AND I.FECHA_VENCIMIENTO IS NULL;
        PRINT 'OK   items con fechas nuevas: ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + '.';

        /* rango final de cada item superior (los que ya tenian fechas quedan como estaban) */
        UPDATE N SET FI = CONVERT(DATE, I.FECHA_INICIO), FF = CONVERT(DATE, I.FECHA_VENCIMIENTO)
        FROM #ND N INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS I ON I.ID = N.TOPI;

        /* ---------- 2. acciones ---------- */
        /* cuantas por nodo: subitem 2, item sin subitems 3, item con subitems 1 (propia); hitos y nodos con acciones: 0 */
        UPDATE #ND SET NA = CASE WHEN NIV = 1 OR HITO = 1 OR TIENE_ACC = 1 OR FI IS NULL OR FF IS NULL THEN 0
                                 WHEN NIV = 3 THEN 2 WHEN HIJOS > 0 THEN 1 ELSE 3 END;
        IF OBJECT_ID('tempdb..#NA') IS NOT NULL DROP TABLE #NA;
        CREATE TABLE #NA (K INT IDENTITY(1,1) PRIMARY KEY, ITEM INT, J INT, NA INT, TIPO INT, SUB INT, SUB_DES VARCHAR(150), RT VARCHAR(20), RID INT,
                          FI DATE, FV DATE, EST INT, CIERRE DATETIME, RES INT, PRIO INT, TIT VARCHAR(300), DET VARCHAR(2000), ID_ACC INT);
        ;WITH J AS (SELECT 1 AS J UNION ALL SELECT 2 UNION ALL SELECT 3)
        INSERT INTO #NA (ITEM, J, NA, SUB, RT, RID, FI, FV, PRIO, DET)
        SELECT N.ID, J.J, N.NA,
               /* subtipo y responsable segun la posicion de la accion */
               CASE WHEN N.HIJOS > 0 THEN ISNULL(@ST_REU, @ST_TRAB)
                    WHEN N.NIV = 3 AND J.J = 2 THEN ISNULL(@ST_REV, @ST_TRAB)
                    WHEN J.J = 2 THEN ISNULL(@ST_DOC, @ST_TRAB)
                    WHEN J.J = 3 THEN ISNULL(@ST_CLI, @ST_TRAB)
                    ELSE @ST_TRAB END,
               CASE WHEN J.J = 3 AND @CLI IS NOT NULL THEN 'CLIENTE'
                    WHEN N.NIV = 3 AND J.J = 2 AND @ID_ANA IS NOT NULL THEN 'EMPLEADO'
                    ELSE 'CONSULTOR' END,
               CASE WHEN J.J = 3 AND @CLI IS NOT NULL THEN @CLI
                    WHEN N.NIV = 3 AND J.J = 2 AND @ID_ANA IS NOT NULL THEN @ID_ANA
                    ELSE @ID_LIDER END,
               /* fechas: la ventana del item superior partida en NA tramos */
               DATEADD(DAY, (J.J - 1) * DATEDIFF(DAY, N.FI, N.FF) / N.NA, N.FI),
               DATEADD(DAY, J.J * DATEDIFF(DAY, N.FI, N.FF) / N.NA, N.FI),
               CASE WHEN J.J = 3 THEN ISNULL(@PRIO_A, @PRIO_N) ELSE @PRIO_N END,
               CASE WHEN N.HIJOS > 0 THEN 'Reuni' + CHAR(243) + 'n de revisi' + CHAR(243) + 'n con el responsable del ' + CHAR(225) + 'rea: '
                    WHEN N.NIV = 3 AND J.J = 2 THEN 'Revisar y aprobar lo elaborado: '
                    WHEN J.J = 1 THEN 'Relevar la situaci' + CHAR(243) + 'n actual: '
                    WHEN J.J = 2 THEN 'Elaborar el documento / registro: '
                    ELSE 'Validar con el cliente y enviar evidencias: ' END + LOWER(LEFT(N.TIT, 1)) + SUBSTRING(N.TIT, 2, 400)
        FROM #ND N INNER JOIN J ON J.J <= N.NA
        WHERE N.NA > 0;

        UPDATE A SET SUB_DES = S.DESCRIPCION, TIPO = S.ID_TIPO,
                     TIT = LEFT(S.DESCRIPCION + ' - ' + CASE WHEN N.CODE <> '' THEN N.CODE + ' ' ELSE '' END + N.TIT, 300),
                     /* estado segun hoy: vencida en fecha -> cumplida salvo 1 de cada 4; en curso -> en proceso / pendiente */
                     EST = CASE WHEN A.FV < @HOY AND (A.ITEM + A.J) % 4 <> 0 THEN @EST_CUMP
                                WHEN A.FI <= @HOY AND A.FV >= @HOY AND A.J = 1 THEN ISNULL(@EST_PROC, @EST_PEND)
                                ELSE @EST_PEND END
        FROM #NA A INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S ON S.ID = A.SUB INNER JOIN #ND N ON N.ID = A.ITEM;
        UPDATE #NA SET CIERRE = CONVERT(DATETIME, CASE WHEN DATEADD(DAY, -1, FV) < FI THEN FV ELSE DATEADD(DAY, -1, FV) END),
                       RES = @RES_OK
        WHERE EST = @EST_CUMP;

        DECLARE @MAP TABLE (K INT, ID_ACC INT);
        MERGE dbo.VCT_ACCIONES AS T
        USING #NA AS S ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (ORIGEN, ID_TIPO, ID_SUBTIPO, ID_ESTADO, ID_PRIORIDAD, ID_RESULTADO, TITULO, DESCRIPCION, ID_CLIENTE, ID_PROYECTO, ID_PLAN, ID_PLAN_ITEM,
                    REQUIERE_RESPUESTA, REQUIERE_APROBACION, FECHA_CREACION, FECHA_INICIO, FECHA_VENCIMIENTO, FECHA_CIERRE, FECHA_ALTA, USUARIO_ALTA)
            VALUES ('MANUAL', S.TIPO, S.SUB, S.EST, S.PRIO, S.RES, S.TIT, S.DET, @CLI, @PROY, @PLAN, S.ITEM,
                    0, 0, CONVERT(DATETIME, S.FI), CONVERT(DATETIME, S.FI), CONVERT(DATETIME, S.FV), S.CIERRE, GETDATE(), 'PASO5_4')
        OUTPUT S.K, INSERTED.ID INTO @MAP (K, ID_ACC);
        UPDATE A SET ID_ACC = M.ID_ACC FROM #NA A INNER JOIN @MAP M ON M.K = A.K;
        SELECT @N = COUNT(*) FROM @MAP;
        PRINT 'OK   acciones creadas: ' + CONVERT(VARCHAR(10), @N) + '.';

        INSERT INTO dbo.VCT_ACCIONES_PARTICIPANTES (ID_ACCION, ROL_PARTICIPANTE, TIPO_ENTIDAD, ID_ENTIDAD, NOMBRE_LIBRE, PRINCIPAL, ESTADO, FECHA_ASIGNACION, FECHA_ALTA, USUARIO_ALTA)
        SELECT ID_ACC, 'RESPONSABLE', RT, RID, NULL, 1, 'ACTIVO', GETDATE(), GETDATE(), 'PASO5_4' FROM #NA WHERE ID_ACC IS NOT NULL;
        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
        SELECT ID_ACC, NULL, @EST_PEND, 'ALTA', 'Acci' + CHAR(243) + 'n del plan (datos de prueba PASO5_4).', 'SISTEMA', GETDATE(), 'PASO5_4' FROM #NA WHERE ID_ACC IS NOT NULL;
        INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)
        SELECT ID_ACC, @EST_PEND, EST, CASE WHEN EST = @EST_CUMP THEN 'CUMPLIDA' ELSE 'MODIFICADA' END, 'Estado de prueba (PASO5_4).', 'SISTEMA', GETDATE(), 'PASO5_4'
        FROM #NA WHERE ID_ACC IS NOT NULL AND EST <> @EST_PEND;

        /* ---------- 3. fin real: items vencidos con todas sus acciones cumplidas ---------- */
        UPDATE I SET FECHA_CIERRE = X.ULT, FECHA_UPD = GETDATE(), USUARIO_UPD = 'PASO5_4'
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
        INNER JOIN #ND N ON N.ID = I.ID AND N.NIV = 2 AND N.HITO = 0
        CROSS APPLY (SELECT COUNT(*) AS TOT, SUM(CASE WHEN A.ID_ESTADO = @EST_CUMP THEN 1 ELSE 0 END) AS CUMP, MAX(A.FECHA_CIERRE) AS ULT
                     FROM dbo.VCT_ACCIONES A
                     WHERE A.ID_ESTADO <> ISNULL(@EST_CANC, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@ST_AV, -1)
                       AND (A.ID_PLAN_ITEM = I.ID OR A.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))) X
        WHERE I.FECHA_CIERRE IS NULL AND I.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, I.FECHA_VENCIMIENTO) < @HOY
          AND X.TOT > 0 AND X.TOT = X.CUMP AND I.USUARIO_UPD = 'PASO5_4';
        PRINT 'OK   items con fin real: ' + CONVERT(VARCHAR(10), @@ROWCOUNT) + '.';
    END;

    /* ---------- avance y estado de los items (misma regla que el SP) ---------- */
    UPDATE I SET
        PORCENTAJE_AVANCE = CASE WHEN X.TOT > 0 THEN CONVERT(INT, ROUND(100.0 * X.CUMP / X.TOT, 0)) WHEN I.FECHA_CIERRE IS NOT NULL THEN 100 ELSE 0 END,
        ESTADO = CASE WHEN I.FECHA_CIERRE IS NOT NULL THEN 'CUMPLIDO'
                      WHEN T.FECHA_VENCIMIENTO IS NOT NULL AND CONVERT(DATE, T.FECHA_VENCIMIENTO) < @HOY THEN 'VENCIDO'
                      WHEN T.FECHA_INICIO IS NOT NULL AND CONVERT(DATE, T.FECHA_INICIO) <= @HOY THEN 'EN_CURSO'
                      ELSE 'PENDIENTE' END
    FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
    LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS PP ON PP.ID = I.ID_PADRE
    INNER JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS T ON T.ID = CASE WHEN I.GRUPO = 'CAPITULO' OR PP.ID IS NULL OR PP.GRUPO = 'CAPITULO' THEN I.ID ELSE PP.ID END
    OUTER APPLY (SELECT COUNT(*) AS TOT, SUM(CASE WHEN A.ID_ESTADO = @EST_CUMP THEN 1 ELSE 0 END) AS CUMP
                 FROM dbo.VCT_ACCIONES A
                 WHERE A.ID_ESTADO <> ISNULL(@EST_CANC, -1) AND ISNULL(A.ID_SUBTIPO, 0) <> ISNULL(@ST_AV, -1)
                   AND (A.ID_PLAN_ITEM = I.ID OR A.ID_PLAN_ITEM IN (SELECT S.ID FROM dbo.VCT_PROYECTOS_PLAN_ITEMS S WHERE S.ID_PADRE = I.ID))) X
    WHERE I.ID_PLAN = @PLAN;

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT 'FALLO PASO5_4 (no se modifico nada): ' + ERROR_MESSAGE();
END CATCH;

/* control: plan por nivel */
SELECT CASE WHEN I.GRUPO = 'CAPITULO' THEN 'Capitulo' WHEN P.ID IS NULL OR P.GRUPO = 'CAPITULO' THEN 'Item' ELSE 'Subitem' END AS NIVEL,
       I.CODIGO_ITEM, I.TITULO, I.FECHA_INICIO, I.FECHA_VENCIMIENTO, I.FECHA_CIERRE, I.ESTADO, I.PORCENTAJE_AVANCE,
       (SELECT COUNT(*) FROM dbo.VCT_ACCIONES A WHERE A.ID_PLAN_ITEM = I.ID AND A.ID_ESTADO <> ISNULL(@EST_CANC, -1)) AS ACCIONES,
       I.USUARIO_UPD
FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I
LEFT JOIN dbo.VCT_PROYECTOS_PLAN_ITEMS P ON P.ID = I.ID_PADRE
WHERE I.ID_PLAN = @PLAN
ORDER BY I.ORDEN, I.ID;
