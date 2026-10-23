/* ========================================================================
   DEMO_AGENDA_1348_Y_LIMPIAR_1349  (CAMBIA DATOS - pedido para la demo)
   ------------------------------------------------------------------------
   PARTE 1 - Proyecto 1348: visitas de demo en octubre y noviembre 2026.
     - Consultoria, auditoria y capacitacion (las instancias del proyecto).
     - Consultor lider y los otros consultores del equipo (una visita por consultor).
     - Normas: las del proyecto. 8 h por dia de visita.
     - Hasta hoy: CONFIRMADO con horas ejecutadas; desde hoy: PENDIENTE / CONFIRMADO (programadas).
     - No mira la disponibilidad cargada (VCT_PRM_AGENDA_CONSULTOR). Si un dia choca con una
       licencia (bloqueo 51012 de los triggers VCT_CIERRE12_*), esa visita se saltea y se avisa.
     - Re-ejecutable: borra y vuelve a crear solo las visitas con USUARIO_ALTA = 'DEMO_AGENDA'.
   PARTE 2 - Proyecto 1349: se elimina el proyecto con todo lo que cuelga de el
     (acciones, equipo, servicios, normas, lanzamiento, plan, visitas, documentos...),
     para liberar las acciones y asignaciones del consultor y del analista.
     Se recorre cada tabla con ID_PROYECTO y las claves foraneas hacia abajo; las filas
     hijas se borran primero. Todo en una transaccion: si algo falla, no se borra nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* ======================= PARTE 1: visitas de demo en 1348 ======================= */
DECLARE @COD VARCHAR(50) = '1348', @MARCA VARCHAR(100) = 'DEMO_AGENDA';
DECLARE @PROY INT, @HOY DATE = CONVERT(DATE, GETDATE()), @CO INT, @AU1 INT, @AU2 INT, @CA1 INT, @CA2 INT,
        @V_IDENT BIT = ISNULL(COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS'), 'ID', 'IsIdentity'), 0),
        @VC_IDENT BIT = ISNULL(COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES'), 'ID', 'IsIdentity'), 0),
        @VN_IDENT BIT = ISNULL(COLUMNPROPERTY(OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_NORMAS'), 'ID', 'IsIdentity'), 0),
        @NCONS INT = 0, @OK INT = 0, @SALT INT = 0;

SELECT @PROY = ID FROM dbo.VCT_PROYECTOS WHERE CODIGO = @COD;
IF @PROY IS NULL
    PRINT 'FALLO: no existe el proyecto ' + @COD + '.'
ELSE
BEGIN
    /* instancias de servicio del proyecto por tipo (CO / AU / CA) */
    SELECT TOP 1 @CO = S.ID FROM dbo.VCT_PROYECTOS_SERVICIOS S JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
    WHERE S.ID_PROYECTO = @PROY AND UPPER(LEFT(PS.CODIGO, 2)) = 'CO' ORDER BY S.ORDEN, S.ID;
    SELECT TOP 1 @AU1 = S.ID FROM dbo.VCT_PROYECTOS_SERVICIOS S JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
    WHERE S.ID_PROYECTO = @PROY AND UPPER(LEFT(PS.CODIGO, 2)) = 'AU' ORDER BY S.FECHA_INICIO, S.ORDEN, S.ID;
    SELECT TOP 1 @AU2 = S.ID FROM dbo.VCT_PROYECTOS_SERVICIOS S JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
    WHERE S.ID_PROYECTO = @PROY AND UPPER(LEFT(PS.CODIGO, 2)) = 'AU' AND S.ID <> ISNULL(@AU1, 0) ORDER BY S.FECHA_INICIO, S.ORDEN, S.ID;
    SELECT TOP 1 @CA1 = S.ID FROM dbo.VCT_PROYECTOS_SERVICIOS S JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
    WHERE S.ID_PROYECTO = @PROY AND UPPER(LEFT(PS.CODIGO, 2)) = 'CA' ORDER BY S.FECHA_INICIO, S.ORDEN, S.ID;
    SELECT TOP 1 @CA2 = S.ID FROM dbo.VCT_PROYECTOS_SERVICIOS S JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
    WHERE S.ID_PROYECTO = @PROY AND UPPER(LEFT(PS.CODIGO, 2)) = 'CA' AND S.ID <> ISNULL(@CA1, 0) ORDER BY S.FECHA_INICIO, S.ORDEN, S.ID;
    IF @AU2 IS NULL SET @AU2 = @AU1;
    IF @CA2 IS NULL SET @CA2 = @CA1;

    /* consultores del equipo: el lider primero */
    DECLARE @C TABLE (N INT IDENTITY(1,1), ID INT, LIDER BIT);
    INSERT INTO @C (ID, LIDER)
    SELECT X.ID_CONSULTOR, X.LIDER FROM (
        SELECT EQ.ID_CONSULTOR, MAX(CASE WHEN R.CODIGO = 'CONSULTOR_LIDER' THEN 1 ELSE 0 END) AS LIDER, MIN(EQ.ID) AS PRIMERO
        FROM dbo.VCT_PROYECTOS_EQUIPO EQ LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
        WHERE EQ.ID_PROYECTO = @PROY AND EQ.ESTADO = 'ACTIVO' AND EQ.TIPO_MIEMBRO = 'CONSULTOR' AND EQ.ID_CONSULTOR IS NOT NULL
        GROUP BY EQ.ID_CONSULTOR) X
    ORDER BY X.LIDER DESC, X.PRIMERO;
    SELECT @NCONS = COUNT(*) FROM @C;

    /* el plan de visitas: servicio, desde, hasta, consultor (1 = lider, 2.. = el resto del equipo), estado futuro */
    DECLARE @PL TABLE (N INT IDENTITY(1,1), PS INT, D DATE, H DATE, K INT, EST VARCHAR(20), LUGAR VARCHAR(300), DET VARCHAR(300), LOGI VARCHAR(300));
    INSERT INTO @PL (PS, D, H, K, EST, LUGAR, DET, LOGI) VALUES
        (@CO,  '2026-10-06', '2026-10-06', 1, 'CONFIRMADO', NULL, 'Relevamiento inicial de procesos', 'Ingreso 9 h, contacto en recepcion'),
        (@CO,  '2026-10-07', '2026-10-07', 2, 'CONFIRMADO', NULL, 'Relevamiento de documentacion existente', NULL),
        (@CA1, '2026-10-09', '2026-10-09', 3, 'CONFIRMADO', NULL, 'Capacitacion de sensibilizacion', 'Sala con proyector'),
        (@CO,  '2026-10-14', '2026-10-14', 1, 'CONFIRMADO', NULL, 'Contexto de la organizacion y partes interesadas', NULL),
        (@AU2, '2026-10-15', '2026-10-15', 2, 'CONFIRMADO', NULL, 'Diagnostico previo (gap analysis)', NULL),
        (@CO,  '2026-10-20', '2026-10-21', 1, 'CONFIRMADO', NULL, 'Mapa de procesos y riesgos', 'Traslado en remis'),
        (@CO,  '2026-10-20', '2026-10-21', 2, 'CONFIRMADO', NULL, 'Mapa de procesos y riesgos', 'Traslado en remis'),
        (@CO,  '2026-10-28', '2026-10-28', 1, 'CONFIRMADO', NULL, 'Revision de procedimientos', NULL),
        (@CO,  '2026-10-29', '2026-10-29', 3, 'PENDIENTE',  NULL, 'Indicadores y objetivos', NULL),
        (@CO,  '2026-11-04', '2026-11-04', 1, 'CONFIRMADO', NULL, 'Control de documentos y registros', NULL),
        (@AU1, '2026-11-10', '2026-11-11', 1, 'PENDIENTE',  NULL, 'Auditoria interna', 'Viaticos: 1 noche'),
        (@AU1, '2026-11-10', '2026-11-11', 2, 'PENDIENTE',  NULL, 'Auditoria interna', 'Viaticos: 1 noche'),
        (@CO,  '2026-11-18', '2026-11-18', 2, 'PENDIENTE',  NULL, 'Tratamiento de hallazgos', NULL),
        (@CA2, '2026-11-19', '2026-11-19', 3, 'CONFIRMADO', NULL, 'Capacitacion de auditores internos', 'Sala con proyector'),
        (@CO,  '2026-11-25', '2026-11-25', 1, 'PENDIENTE',  NULL, 'Revision por la direccion', NULL);
    DELETE FROM @PL WHERE PS IS NULL;   /* el proyecto no tiene ese servicio */

    IF @NCONS = 0
        PRINT 'FALLO: el proyecto ' + @COD + ' no tiene consultores activos en el equipo.'
    ELSE IF NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_NORMAS WHERE ID_PROYECTO = @PROY)
        PRINT 'FALLO: el proyecto ' + @COD + ' no tiene normas.'
    ELSE
    BEGIN
        /* re-ejecutable: borra las visitas de demo anteriores */
        DELETE VN FROM dbo.VCT_PROYECTOS_VISITAS_NORMAS VN JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VN.ID_VISITA WHERE V.ID_PROYECTO = @PROY AND V.USUARIO_ALTA = @MARCA;
        DELETE VC FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VC.ID_VISITA WHERE V.ID_PROYECTO = @PROY AND V.USUARIO_ALTA = @MARCA;
        DELETE FROM dbo.VCT_PROYECTOS_VISITAS WHERE ID_PROYECTO = @PROY AND USUARIO_ALTA = @MARCA;

        DECLARE @I INT = 0, @PS INT, @D DATE, @H DATE, @K INT, @EST VARCHAR(20), @DET VARCHAR(300), @LOGI VARCHAR(300),
                @CONS INT, @LID BIT, @DIAS INT, @HRS NUMERIC(9,2), @EJ NUMERIC(9,2), @VID INT, @NEW INT, @LUG VARCHAR(300);
        WHILE 1 = 1
        BEGIN
            SELECT TOP 1 @I = N, @PS = PS, @D = D, @H = H, @K = K, @EST = EST, @DET = DET, @LOGI = LOGI FROM @PL WHERE N > @I ORDER BY N;
            IF @@ROWCOUNT = 0 BREAK;
            /* consultor: K-esimo del equipo (si el equipo es mas chico, vuelve a empezar) */
            SELECT @CONS = ID, @LID = LIDER FROM @C WHERE N = ((@K - 1) % @NCONS) + 1;
            SET @DIAS = DATEDIFF(DAY, @D, @H) + 1;
            SET @HRS = @DIAS * 8;
            /* lo que ya paso: confirmado y ejecutado; lo que viene: el estado del plan, programado */
            IF @H < @HOY SELECT @EST = 'CONFIRMADO', @EJ = @HRS ELSE SET @EJ = NULL;
            SELECT @LUG = NULLIF(LTRIM(RTRIM(ISNULL(LUGAR,''))), '') FROM dbo.VCT_PROYECTOS_SERVICIOS WHERE ID = @PS;
            /* la misma visita para el mismo consultor y fecha no se duplica */
            IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS V JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID
                       WHERE V.ID_PROYECTO = @PROY AND VC.ID_CONSULTOR = @CONS AND CONVERT(DATE, V.FECHA_DESDE) <= @H AND CONVERT(DATE, ISNULL(V.FECHA_HASTA, V.FECHA_DESDE)) >= @D)
            BEGIN
                SET @SALT = @SALT + 1;
                PRINT 'AVISO visita ' + CONVERT(VARCHAR(10), @D, 103) + ': el consultor ya tiene una visita del proyecto en esas fechas (salteada).';
                CONTINUE;
            END;
            BEGIN TRY
                BEGIN TRAN;
                IF @V_IDENT = 1
                BEGIN
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS (ID_PROYECTO, ID_PROYECTO_SERVICIO, FECHA_DESDE, FECHA_HASTA, DIAS, LUGAR, DESCRIPCION,
                           OBSERV_LOGISTICA, ESTADO, FECHA_ALTA, USUARIO_ALTA, TOTAL_HORAS_EJECUTADAS)
                    VALUES (@PROY, @PS, @D, @H, @DIAS, @LUG, @DET, @LOGI, @EST, GETDATE(), @MARCA, @EJ);
                    SET @VID = SCOPE_IDENTITY();
                END
                ELSE
                BEGIN
                    SELECT @NEW = ISNULL(MAX(ID), 0) + 1 FROM dbo.VCT_PROYECTOS_VISITAS WITH (UPDLOCK, HOLDLOCK);
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS (ID, ID_PROYECTO, ID_PROYECTO_SERVICIO, FECHA_DESDE, FECHA_HASTA, DIAS, LUGAR, DESCRIPCION,
                           OBSERV_LOGISTICA, ESTADO, FECHA_ALTA, USUARIO_ALTA, TOTAL_HORAS_EJECUTADAS)
                    VALUES (@NEW, @PROY, @PS, @D, @H, @DIAS, @LUG, @DET, @LOGI, @EST, GETDATE(), @MARCA, @EJ);
                    SET @VID = @NEW;
                END;
                IF @VC_IDENT = 1
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES (ID_VISITA, ID_CONSULTOR, LIDER, HORAS_PLANIFICADAS, HORAS_EJECUTADAS, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@VID, @CONS, @LID, @HRS, @EJ, GETDATE(), @MARCA)
                ELSE
                BEGIN
                    SELECT @NEW = ISNULL(MAX(ID), 0) + 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WITH (UPDLOCK, HOLDLOCK);
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES (ID, ID_VISITA, ID_CONSULTOR, LIDER, HORAS_PLANIFICADAS, HORAS_EJECUTADAS, FECHA_ALTA, USUARIO_ALTA)
                    VALUES (@NEW, @VID, @CONS, @LID, @HRS, @EJ, GETDATE(), @MARCA);
                END;
                IF @VN_IDENT = 1
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS_NORMAS (ID_VISITA, ID_NORMA, FECHA_ALTA, USUARIO_ALTA)
                    SELECT DISTINCT @VID, PN.ID_NORMA, GETDATE(), @MARCA FROM dbo.VCT_PROYECTOS_NORMAS PN
                    WHERE PN.ID_PROYECTO = @PROY AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA'
                ELSE
                BEGIN
                    SELECT @NEW = ISNULL(MAX(ID), 0) FROM dbo.VCT_PROYECTOS_VISITAS_NORMAS WITH (UPDLOCK, HOLDLOCK);
                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS_NORMAS (ID, ID_VISITA, ID_NORMA, FECHA_ALTA, USUARIO_ALTA)
                    SELECT @NEW + ROW_NUMBER() OVER (ORDER BY X.ID_NORMA), @VID, X.ID_NORMA, GETDATE(), @MARCA
                    FROM (SELECT DISTINCT PN.ID_NORMA FROM dbo.VCT_PROYECTOS_NORMAS PN WHERE PN.ID_PROYECTO = @PROY AND ISNULL(PN.ESTADO,'ACTIVA') = 'ACTIVA') X;
                END;
                COMMIT;
                SET @OK = @OK + 1;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK;
                SET @SALT = @SALT + 1;
                PRINT 'AVISO visita ' + CONVERT(VARCHAR(10), @D, 103) + ' salteada: ' + ERROR_MESSAGE();
            END CATCH;
        END;
        PRINT 'OK   1348: ' + CONVERT(VARCHAR(10), @OK) + ' visita(s) de demo creadas' + CASE WHEN @SALT > 0 THEN ', ' + CONVERT(VARCHAR(10), @SALT) + ' salteada(s)' ELSE '' END + '.';
        /* resumen de horas por servicio (lo que muestra "Horas por servicio": ejecutadas + programadas / proyectadas) */
        SELECT PS.DESCRIPCION AS SERVICIO, ISNULL(NULLIF(S.NOMBRE,''), PS.DESCRIPCION) AS INSTANCIA, S.TOTAL_HORAS_PROYECTADAS AS PROYECTADAS,
               SUM(CASE WHEN V.FECHA_DESDE < @HOY THEN ISNULL(VC.HORAS_EJECUTADAS, VC.HORAS_PLANIFICADAS) ELSE 0 END) AS EJECUTADAS,
               SUM(CASE WHEN V.FECHA_DESDE >= @HOY THEN VC.HORAS_PLANIFICADAS ELSE 0 END) AS PROGRAMADAS, COUNT(DISTINCT V.ID) AS VISITAS
        FROM dbo.VCT_PROYECTOS_SERVICIOS S
        JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = S.ID_SERVICIO
        LEFT JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID_PROYECTO_SERVICIO = S.ID
        LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID
        WHERE S.ID_PROYECTO = @PROY
        GROUP BY PS.DESCRIPCION, S.NOMBRE, S.TOTAL_HORAS_PROYECTADAS, S.ORDEN, S.ID
        ORDER BY S.ORDEN, S.ID;
    END;
END;
GO

/* ======================= PARTE 2: eliminar el proyecto 1349 ======================= */
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @COD2 VARCHAR(50) = '1349', @P INT;
SELECT @P = ID FROM dbo.VCT_PROYECTOS WHERE CODIGO = @COD2;
IF @P IS NULL
    PRINT 'OK   1349: el proyecto no existe (ya estaba eliminado).'
ELSE
BEGIN
    SELECT P.ID, P.CODIGO, P.NOMBRE, C.RAZON_SOCIAL AS CLIENTE, P.FECHA_ALTA, P.USUARIO_ALTA
    FROM dbo.VCT_PROYECTOS P LEFT JOIN dbo.VCT_CLIENTES C ON C.ID = P.IDCLIENTE WHERE P.ID = @P;

    /* lo que se borra: cada tabla con ID_PROYECTO / IDPROYECTO y, hacia abajo, todas las tablas hijas por clave foranea */
    CREATE TABLE #Q (N INT IDENTITY(1,1), OBJ INT, TBL NVARCHAR(300), LVL INT, FILT NVARCHAR(MAX), EXPANDIDO BIT DEFAULT 0);
    INSERT INTO #Q (OBJ, TBL, LVL, FILT)
    VALUES (OBJECT_ID('dbo.VCT_PROYECTOS'), N'[dbo].[VCT_PROYECTOS]', 0, N'T0.[ID] = ' + CONVERT(NVARCHAR(20), @P));
    INSERT INTO #Q (OBJ, TBL, LVL, FILT)
    SELECT t.object_id, QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name), 1, N'T1.' + QUOTENAME(c.name) + N' = ' + CONVERT(NVARCHAR(20), @P)
    FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id
    WHERE c.name IN ('ID_PROYECTO','IDPROYECTO') AND t.name LIKE 'VCT[_]%' AND t.name NOT LIKE 'VCT[_]PRM[_]%' AND t.name <> 'VCT_PROYECTOS'
      AND t.is_ms_shipped = 0 AND TYPE_NAME(c.user_type_id) IN ('int','bigint','smallint','numeric','decimal');

    DECLARE @QN INT, @QOBJ INT, @QLVL INT, @QF NVARCHAR(MAX);
    WHILE 1 = 1
    BEGIN
        SELECT TOP 1 @QN = N, @QOBJ = OBJ, @QLVL = LVL, @QF = FILT FROM #Q WHERE EXPANDIDO = 0 ORDER BY N;
        IF @@ROWCOUNT = 0 BREAK;
        UPDATE #Q SET EXPANDIDO = 1 WHERE N = @QN;
        IF @QLVL >= 8 CONTINUE;
        /* hijas por clave foranea (sin la auto-referencia: esas filas ya estan en el mismo borrado) */
        INSERT INTO #Q (OBJ, TBL, LVL, FILT)
        SELECT fk.parent_object_id,
               QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)),
               @QLVL + 1,
               N'EXISTS (SELECT 1 FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.referenced_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.referenced_object_id))
               + N' T' + CONVERT(NVARCHAR(5), @QLVL) + N' WHERE '
               + STUFF((SELECT N' AND T' + CONVERT(NVARCHAR(5), @QLVL) + N'.' + QUOTENAME(COL_NAME(k.referenced_object_id, k.referenced_column_id))
                              + N' = T' + CONVERT(NVARCHAR(5), @QLVL + 1) + N'.' + QUOTENAME(COL_NAME(k.parent_object_id, k.parent_column_id))
                        FROM sys.foreign_key_columns k WHERE k.constraint_object_id = fk.object_id ORDER BY k.constraint_column_id
                        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 5, N'')
               + N' AND (' + @QF + N'))'
        FROM sys.foreign_keys fk
        WHERE fk.referenced_object_id = @QOBJ AND fk.parent_object_id <> @QOBJ
          AND (SELECT COUNT(*) FROM #Q X WHERE X.OBJ = fk.parent_object_id) < 4;
    END;

    /* cuantas filas toca cada paso (informativo) y borrado: primero las hijas (nivel mas profundo) */
    DECLARE @SQL NVARCHAR(MAX), @TBL NVARCHAR(300), @F NVARCHAR(MAX), @L INT, @N INT, @TOT INT = 0, @ERRB NVARCHAR(2000) = N'';
    DECLARE @LOG TABLE (TBL NVARCHAR(300), FILAS INT);
    BEGIN TRY
        BEGIN TRAN;
        DECLARE qc CURSOR LOCAL FAST_FORWARD FOR SELECT TBL, FILT, LVL FROM #Q ORDER BY LVL DESC, N DESC;
        OPEN qc;
        FETCH NEXT FROM qc INTO @TBL, @F, @L;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'DELETE T' + CONVERT(NVARCHAR(5), @L) + N' FROM ' + @TBL + N' T' + CONVERT(NVARCHAR(5), @L) + N' WHERE ' + @F + N'; SET @R = @@ROWCOUNT;';
            EXEC sys.sp_executesql @SQL, N'@R INT OUTPUT', @R = @N OUTPUT;
            IF @N > 0 INSERT INTO @LOG (TBL, FILAS) VALUES (@TBL, @N);
            SET @TOT = @TOT + @N;
            FETCH NEXT FROM qc INTO @TBL, @F, @L;
        END;
        CLOSE qc; DEALLOCATE qc;
        IF EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS WHERE ID = @P) RAISERROR('el proyecto sigue existiendo.', 16, 1);
        COMMIT;
        SELECT TBL AS TABLA, SUM(FILAS) AS FILAS_BORRADAS FROM @LOG GROUP BY TBL ORDER BY TBL;
        PRINT 'OK   1349: proyecto eliminado con todo lo asociado (' + CONVERT(VARCHAR(10), @TOT) + ' fila(s)).';
    END TRY
    BEGIN CATCH
        SET @ERRB = ERROR_MESSAGE();
        IF CURSOR_STATUS('local', 'qc') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'qc') >= 0 CLOSE qc;
            DEALLOCATE qc;
        END;
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'FALLO 1349: no se borro nada. ' + @ERRB;
        PRINT 'Ultimo paso: ' + ISNULL(@TBL, '');
    END CATCH;
    DROP TABLE #Q;
END;
GO
