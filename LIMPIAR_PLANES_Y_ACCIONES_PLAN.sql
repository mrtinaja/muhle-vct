/* ============================================================================
   LIMPIAR_PLANES_Y_ACCIONES_PLAN  (27/10/2026)
   ----------------------------------------------------------------------------
   Para probar el plan estrategico desde cero, en TODOS los proyectos:
   - Borra todos los planes (VCT_PROYECTOS_PLANES) y sus items / subitems.
   - Borra las acciones del plan: las que tienen plan o item asignado y las de
     subtipo TRABAJO_PLAN_ITEM (con sus acciones hijas, historial, comentarios,
     relaciones y demas tablas que cuelgan de ellas).
   - La accion "Carga del plan" (CARGA_PLAN) NO se borra: vuelve a Pendiente,
     sin plan ni cierre, para volver a cargar el plan con las tres opciones.
   - No toca visitas, asignacion, lanzamiento ni el resto de las acciones.
     Si alguna tabla de visitas apunta a lo que se borra, se le limpia la
     referencia (si admite nulo) o se cancela todo sin borrar nada.
   Todo en una transaccion: si algo falla no se borra nada.
   SSMS: F5. Al final muestra lo borrado por tabla.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @PEND INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_ACCIONES_ESTADOS WHERE CODIGO = 'PENDIENTE');
DECLARE @SUB_CP INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'CARGA_PLAN');
DECLARE @SUB_TI INT = (SELECT TOP 1 ID FROM dbo.VCT_PRM_ACCIONES_SUBTIPOS WHERE CODIGO = 'TRABAJO_PLAN_ITEM');

IF @PEND IS NULL OR @SUB_CP IS NULL
BEGIN
    PRINT 'FALLO: no se encontro el estado PENDIENTE o el subtipo CARGA_PLAN. No se borro nada.';
END
ELSE
BEGIN
    /* ---------- 1. acciones a borrar (sin CARGA_PLAN) + sus hijas ---------- */
    CREATE TABLE #ACC (ID INT PRIMARY KEY);
    INSERT INTO #ACC (ID)
    SELECT ID FROM dbo.VCT_ACCIONES
    WHERE ISNULL(ID_SUBTIPO, 0) <> @SUB_CP
      AND (ID_PLAN IS NOT NULL OR ID_PLAN_ITEM IS NOT NULL OR ISNULL(ID_SUBTIPO, 0) = ISNULL(@SUB_TI, -1));
    WHILE 1 = 1
    BEGIN
        INSERT INTO #ACC (ID)
        SELECT A.ID FROM dbo.VCT_ACCIONES A
        WHERE A.ID_ACCION_PADRE IN (SELECT ID FROM #ACC) AND A.ID NOT IN (SELECT ID FROM #ACC) AND ISNULL(A.ID_SUBTIPO, 0) <> @SUB_CP;
        IF @@ROWCOUNT = 0 BREAK;
    END;

    /* resumen previo */
    SELECT (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_PLANES) AS PLANES,
           (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_PLAN_ITEMS) AS ITEMS_DEL_PLAN,
           (SELECT COUNT(*) FROM #ACC) AS ACCIONES_DEL_PLAN,
           (SELECT COUNT(*) FROM dbo.VCT_ACCIONES WHERE ID_SUBTIPO = @SUB_CP) AS ACCIONES_CARGA_PLAN_A_PENDIENTE;

    /* ---------- 2. que se hace en cada tabla relacionada (por clave foranea) ----------
       MODO: D = borrar, N = poner en nulo la referencia, X = no se puede (cancela) */
    CREATE TABLE #Q (N INT IDENTITY(1,1), OBJ INT, TBL NVARCHAR(300), LVL INT, FILT NVARCHAR(MAX), MODO CHAR(1), SETS NVARCHAR(MAX), EXPANDIDO BIT DEFAULT 0);
    INSERT INTO #Q (OBJ, TBL, LVL, FILT, MODO) VALUES
        (OBJECT_ID('dbo.VCT_ACCIONES'),             N'[dbo].[VCT_ACCIONES]',             0, N'T0.[ID] IN (SELECT ID FROM #ACC)', 'D'),
        (OBJECT_ID('dbo.VCT_PROYECTOS_PLAN_ITEMS'), N'[dbo].[VCT_PROYECTOS_PLAN_ITEMS]', 0, N'1 = 1', 'D'),
        (OBJECT_ID('dbo.VCT_PROYECTOS_PLANES'),     N'[dbo].[VCT_PROYECTOS_PLANES]',     0, N'1 = 1', 'D');

    DECLARE @QN INT, @QOBJ INT, @QLVL INT, @QF NVARCHAR(MAX);
    WHILE 1 = 1
    BEGIN
        SELECT TOP 1 @QN = N, @QOBJ = OBJ, @QLVL = LVL, @QF = FILT FROM #Q WHERE EXPANDIDO = 0 AND MODO = 'D' ORDER BY N;
        IF @@ROWCOUNT = 0 BREAK;
        UPDATE #Q SET EXPANDIDO = 1 WHERE N = @QN;
        IF @QLVL >= 6 CONTINUE;
        INSERT INTO #Q (OBJ, TBL, LVL, FILT, MODO, SETS, EXPANDIDO)
        SELECT fk.parent_object_id,
               QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)),
               @QLVL + 1,
               N'EXISTS (SELECT 1 FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.referenced_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.referenced_object_id))
               + N' T' + CONVERT(NVARCHAR(5), @QLVL) + N' WHERE '
               + STUFF((SELECT N' AND T' + CONVERT(NVARCHAR(5), @QLVL) + N'.' + QUOTENAME(COL_NAME(k.referenced_object_id, k.referenced_column_id))
                              + N' = T' + CONVERT(NVARCHAR(5), @QLVL + 1) + N'.' + QUOTENAME(COL_NAME(k.parent_object_id, k.parent_column_id))
                        FROM sys.foreign_key_columns k WHERE k.constraint_object_id = fk.object_id ORDER BY k.constraint_column_id
                        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 5, N'')
               + N' AND (' + @QF + N'))',
               CASE WHEN OBJECT_NAME(fk.parent_object_id) LIKE 'VCT[_]ACCIONES[_]%' OR OBJECT_NAME(fk.parent_object_id) LIKE 'VCT[_]PROYECTOS[_]PLAN%' THEN 'D'
                    WHEN NOT EXISTS (SELECT 1 FROM sys.foreign_key_columns k JOIN sys.columns c ON c.object_id = k.parent_object_id AND c.column_id = k.parent_column_id
                                     WHERE k.constraint_object_id = fk.object_id AND c.is_nullable = 0) THEN 'N'
                    WHEN OBJECT_NAME(fk.parent_object_id) LIKE '%VISITA%' THEN 'X'
                    ELSE 'D' END,
               STUFF((SELECT N', ' + QUOTENAME(COL_NAME(k.parent_object_id, k.parent_column_id)) + N' = NULL'
                      FROM sys.foreign_key_columns k WHERE k.constraint_object_id = fk.object_id ORDER BY k.constraint_column_id
                      FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, N''),
               0
        FROM sys.foreign_keys fk
        WHERE fk.referenced_object_id = @QOBJ
          AND fk.parent_object_id <> @QOBJ                                        /* auto-referencias: se resuelven aparte */
          AND fk.parent_object_id NOT IN (SELECT OBJ FROM #Q WHERE LVL = 0)       /* acciones / items / planes ya son raiz */
          AND (SELECT COUNT(*) FROM #Q X WHERE X.OBJ = fk.parent_object_id) < 4;
    END;

    /* columnas ID_ACCION sin clave foranea (ej. notificaciones): mismas reglas */
    INSERT INTO #Q (OBJ, TBL, LVL, FILT, MODO, SETS, EXPANDIDO)
    SELECT t.object_id, QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name), 1,
           N'T1.' + QUOTENAME(c.name) + N' IN (SELECT ID FROM #ACC)',
           CASE WHEN c.is_nullable = 1 AND t.name LIKE '%VISITA%' THEN 'N' WHEN t.name LIKE '%VISITA%' THEN 'X' ELSE 'D' END,
           QUOTENAME(c.name) + N' = NULL', 1
    FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id
    WHERE c.name = 'ID_ACCION' AND t.name LIKE 'VCT[_]%' AND t.is_ms_shipped = 0
      AND TYPE_NAME(c.user_type_id) IN ('int','bigint')
      AND NOT EXISTS (SELECT 1 FROM sys.foreign_key_columns k WHERE k.parent_object_id = t.object_id AND k.parent_column_id = c.column_id)
      AND NOT EXISTS (SELECT 1 FROM #Q X WHERE X.OBJ = t.object_id);

    SELECT TBL AS TABLA, LVL AS NIVEL, CASE MODO WHEN 'D' THEN 'borrar' WHEN 'N' THEN 'quitar referencia' ELSE 'NO SE PUEDE' END AS QUE_SE_HACE
    FROM #Q ORDER BY LVL, N;

    /* ---------- 3. ejecucion ---------- */
    DECLARE @SQL NVARCHAR(MAX), @TBL NVARCHAR(300), @F NVARCHAR(MAX), @L INT, @M CHAR(1), @S NVARCHAR(MAX), @N INT, @ERRB NVARCHAR(2000) = N'';
    DECLARE @LOG TABLE (TBL NVARCHAR(300), QUE VARCHAR(30), FILAS INT);
    BEGIN TRY
        BEGIN TRAN;

        /* tablas que no se pueden tocar y tienen filas afectadas: cancela */
        DECLARE qx CURSOR LOCAL FAST_FORWARD FOR SELECT TBL, FILT, LVL FROM #Q WHERE MODO = 'X';
        OPEN qx;
        FETCH NEXT FROM qx INTO @TBL, @F, @L;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'SELECT @R = COUNT(*) FROM ' + @TBL + N' T' + CONVERT(NVARCHAR(5), @L) + N' WHERE ' + @F + N';';
            EXEC sys.sp_executesql @SQL, N'@R INT OUTPUT', @R = @N OUTPUT;
            IF @N > 0
            BEGIN
                SET @ERRB = N'La tabla ' + @TBL + N' tiene ' + CONVERT(NVARCHAR(10), @N) + N' fila(s) que dependen de lo que se borra y no admite nulo.';
                RAISERROR(@ERRB, 16, 1);
            END;
            FETCH NEXT FROM qx INTO @TBL, @F, @L;
        END;
        CLOSE qx; DEALLOCATE qx;

        /* carga del plan: vuelve a pendiente, sin plan ni cierre */
        UPDATE dbo.VCT_ACCIONES
           SET ID_ESTADO = @PEND, ID_RESULTADO = NULL, ID_PLAN = NULL, ID_PLAN_ITEM = NULL, FECHA_CIERRE = NULL,
               FECHA_UPD = GETDATE(), USUARIO_UPD = 'LIMPIAR_PLAN'
         WHERE ID_SUBTIPO = @SUB_CP;
        SET @N = @@ROWCOUNT;
        INSERT INTO @LOG VALUES (N'[dbo].[VCT_ACCIONES] (CARGA_PLAN)', 'a pendiente', @N);

        /* acciones que quedan y apuntan como padre a una que se borra */
        UPDATE dbo.VCT_ACCIONES SET ID_ACCION_PADRE = NULL
         WHERE ID_ACCION_PADRE IN (SELECT ID FROM #ACC) AND ID NOT IN (SELECT ID FROM #ACC);
        SET @N = @@ROWCOUNT;
        IF @N > 0 INSERT INTO @LOG VALUES (N'[dbo].[VCT_ACCIONES] (padre)', 'quitar referencia', @N);

        /* referencias que se ponen en nulo */
        DECLARE qn CURSOR LOCAL FAST_FORWARD FOR SELECT TBL, FILT, LVL, SETS FROM #Q WHERE MODO = 'N';
        OPEN qn;
        FETCH NEXT FROM qn INTO @TBL, @F, @L, @S;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'UPDATE T' + CONVERT(NVARCHAR(5), @L) + N' SET ' + @S + N' FROM ' + @TBL + N' T' + CONVERT(NVARCHAR(5), @L) + N' WHERE ' + @F + N'; SET @R = @@ROWCOUNT;';
            EXEC sys.sp_executesql @SQL, N'@R INT OUTPUT', @R = @N OUTPUT;
            IF @N > 0 INSERT INTO @LOG VALUES (@TBL, 'quitar referencia', @N);
            FETCH NEXT FROM qn INTO @TBL, @F, @L, @S;
        END;
        CLOSE qn; DEALLOCATE qn;

        /* borrado: primero las hijas (nivel mas profundo); las raices en orden acciones > items > planes */
        DECLARE qc CURSOR LOCAL FAST_FORWARD FOR
            SELECT TBL, FILT, LVL FROM #Q WHERE MODO = 'D' ORDER BY LVL DESC, CASE WHEN LVL = 0 THEN N ELSE -N END;
        OPEN qc;
        FETCH NEXT FROM qc INTO @TBL, @F, @L;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'DELETE T' + CONVERT(NVARCHAR(5), @L) + N' FROM ' + @TBL + N' T' + CONVERT(NVARCHAR(5), @L) + N' WHERE ' + @F + N'; SET @R = @@ROWCOUNT;';
            EXEC sys.sp_executesql @SQL, N'@R INT OUTPUT', @R = @N OUTPUT;
            IF @N > 0 INSERT INTO @LOG VALUES (@TBL, 'borradas', @N);
            FETCH NEXT FROM qc INTO @TBL, @F, @L;
        END;
        CLOSE qc; DEALLOCATE qc;

        IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_PLANES) RAISERROR('quedaron planes sin borrar.', 16, 1);
        COMMIT;

        /* avance de las listas (si existe el SP de sincronizacion) */
        IF OBJECT_ID('dbo.VCT_PROYECTO_AVANCE_SYNC') IS NOT NULL EXEC dbo.VCT_PROYECTO_AVANCE_SYNC;

        SELECT TBL AS TABLA, QUE, SUM(FILAS) AS FILAS FROM @LOG GROUP BY TBL, QUE ORDER BY TBL;
        PRINT 'OK   planes y acciones del plan borrados en todos los proyectos. Carga del plan en Pendiente. Visitas sin cambios.';
    END TRY
    BEGIN CATCH
        SET @ERRB = ERROR_MESSAGE();
        IF CURSOR_STATUS('local', 'qx') >= -1 BEGIN IF CURSOR_STATUS('local', 'qx') >= 0 CLOSE qx; DEALLOCATE qx; END;
        IF CURSOR_STATUS('local', 'qn') >= -1 BEGIN IF CURSOR_STATUS('local', 'qn') >= 0 CLOSE qn; DEALLOCATE qn; END;
        IF CURSOR_STATUS('local', 'qc') >= -1 BEGIN IF CURSOR_STATUS('local', 'qc') >= 0 CLOSE qc; DEALLOCATE qc; END;
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'FALLO: no se borro nada. ' + @ERRB;
        PRINT 'Ultimo paso: ' + ISNULL(@TBL, '');
    END CATCH;
    DROP TABLE #Q;
    DROP TABLE #ACC;
END;
GO
