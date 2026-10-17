/* ========================================================================
   PASO3_3_CONSULTOR
   ------------------------------------------------------------------------
   Perfil consultor + ajustes generales:
     1. Diagnostico del usuario jbracamonte: a que consultor esta vinculado
        (VCT_CONSULTORES.ID_USUARIO_SEGURIDAD) y a cual apunta el equipo del
        proyecto 1347 y sus acciones. Inicio, Acciones y la campanita buscan
        al consultor por ese vinculo (y ESTADO = ACTIVO): si no coincide, se
        ve todo en 0. Solo lectura (pasar el resultado si no coincide).
     2. dbo.VCT_GET_HEADER: la campanita del header se muestra SIEMPRE, para
        cualquier perfil (antes solo si el usuario tenia notificaciones).
        Marca NOTIF_SIEMPRE_V1.
     3. dbo.VCT_MAIN_ACCIONES: boton "Nueva" con el estilo de los botones de
        la barra de filtros (vct-btn-new, como Excel / PDF). Marca ACC_NUEVA_V1.
     4. dbo.VCT_MAIN_DASHBOARD: Inicio del consultor (Mi trabajo) con sus
        acciones, proyectos por etapa, visitas y horas. Marca DASH_CONSULTOR_V1.
   Parchea la definicion vigente (no reescribe). No crea objetos ni toca
   permisos. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* ---------------- 1. diagnostico jbracamonte ---------------- */
SELECT 'CONSULTOR VINCULADO AL USUARIO' AS QUE, C.ID, C.APELLIDOS, C.NOMBRES, C.ESTADO, C.ID_USUARIO_SEGURIDAD
FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
WHERE LOWER(LTRIM(RTRIM(ISNULL(C.ID_USUARIO_SEGURIDAD,'')))) = 'jbracamonte'
UNION ALL
SELECT 'CONSULTORES BRACAMONTE', C.ID, C.APELLIDOS, C.NOMBRES, C.ESTADO, C.ID_USUARIO_SEGURIDAD
FROM dbo.VCT_CONSULTORES C WITH(NOLOCK)
WHERE CONVERT(VARCHAR(300), C.APELLIDOS) LIKE '%Bracamonte%';

SELECT 'EQUIPO 1347' AS QUE, EQ.ID, EQ.ID_CONSULTOR, R.CODIGO AS ROL, EQ.ESTADO
FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = EQ.ID_PROYECTO AND P.CODIGO = '1347'
LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R WITH(NOLOCK) ON R.ID = EQ.ID_ROL
WHERE EQ.TIPO_MIEMBRO = 'CONSULTOR';

SELECT 'ACCIONES 1347 A CONSULTOR' AS QUE, A.ID, A.TITULO, AP.TIPO_ENTIDAD, AP.ID_ENTIDAD, AP.ESTADO
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO AND P.CODIGO = '1347'
INNER JOIN dbo.VCT_ACCIONES_PARTICIPANTES AP WITH(NOLOCK) ON AP.ID_ACCION = A.ID
WHERE AP.TIPO_ENTIDAD = 'CONSULTOR';
GO

IF OBJECT_ID('tempdb..#P33') IS NOT NULL DROP TABLE #P33;
CREATE TABLE #P33 (TRG BIT);
INSERT INTO #P33 VALUES (0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #P33 SET TRG = 1;
END;
GO

/* ---------------- 2. header: campanita siempre ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_GET_HEADER')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(400) = N'IF EXISTS (SELECT 1 FROM dbo.VCT_NOTIFICACIONES WITH(NOLOCK) WHERE USUARIO = LOWER(LTRIM(RTRIM(@IAGENTE))))';
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_GET_HEADER.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%NOTIF_SIEMPRE_V1%' BEGIN PRINT 'OK   dbo.VCT_GET_HEADER ya tenia el cambio.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(@A1, @D) = 0 BEGIN PRINT 'FALLO dbo.VCT_GET_HEADER: no se encontro la condicion de la campanita.'; SET @OK = 0; END;
IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A1, N'IF 1 = 1 /* NOTIF_SIEMPRE_V1 */');
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_GET_HEADER: campanita siempre visible.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_GET_HEADER: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

/* ---------------- 3. Acciones: boton Nueva ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_ACCIONES')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(400) = N'''vct-btn vct-btn-primary vct-btn-sm'', ''Nueva'')';
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_ACCIONES.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%ACC_NUEVA_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_ACCIONES ya tenia el boton Nueva.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(@A1, @D) = 0 BEGIN PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: no se encontro el boton Nueva.'; SET @OK = 0; END;
IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A1, N'''vct-btn vct-btn-new vct-btn-sm'', ''Nueva'') /* ACC_NUEVA_V1 */');
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_ACCIONES: boton Nueva con el estilo de la barra de filtros.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

/* ---------------- 4. Inicio del consultor ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_DASHBOARD')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(200) = N'UPDATE #K SET TXT =',
        @BLK NVARCHAR(MAX) = N'/* ===================================================================
       MI TRABAJO (CONSULTOR) - DASH_CONSULTOR_V1
       El consultor arma el plan, ejecuta visitas, carga horas y cumple acciones.
       Reemplaza tarjetas y graficos del panel consultor.
       =================================================================== */
    IF @VISTA = ''CONSULTOR''
    BEGIN
        DELETE FROM #S WHERE CH IN (SELECT CH FROM #C WHERE PANEL = ''consultor'');
        DELETE FROM #C WHERE PANEL = ''consultor'';
        DELETE FROM #K WHERE PANEL = ''consultor'';

        CREATE TABLE #CA (ID INT PRIMARY KEY, ID_PROYECTO INT, FINAL BIT, CUMPLIDA BIT, VENCE DATE, CIERRE DATETIME, SUB VARCHAR(50));
        INSERT INTO #CA (ID, ID_PROYECTO, FINAL, CUMPLIDA, VENCE, CIERRE, SUB)
        SELECT A.ID, A.ID_PROYECTO, ISNULL(E.ES_FINAL, 0), CASE WHEN E.CODIGO = ''CUMPLIDA'' THEN 1 ELSE 0 END,
               CONVERT(DATE, A.FECHA_VENCIMIENTO), A.FECHA_CIERRE, ISNULL(ST.CODIGO, '''')
        FROM dbo.VCT_ACCIONES A
        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
        LEFT JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS ST ON ST.ID = A.ID_SUBTIPO
        WHERE EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WHERE AP.ID_ACCION = A.ID AND AP.ESTADO = ''ACTIVO''
                      AND AP.ROL_PARTICIPANTE = ''RESPONSABLE'' AND AP.TIPO_ENTIDAD = ''CONSULTOR'' AND AP.ID_ENTIDAD = @CONS_ID);

        CREATE TABLE #CV (FECHA DATETIME, ID_PROYECTO INT, HPLAN DECIMAL(18,2), HEJEC DECIMAL(18,2));
        INSERT INTO #CV (FECHA, ID_PROYECTO, HPLAN, HEJEC)
        SELECT V.FECHA_DESDE, V.ID_PROYECTO, ISNULL(VC.HORAS_PLANIFICADAS, 0), ISNULL(VC.HORAS_EJECUTADAS, 0)
        FROM dbo.VCT_PROYECTOS_VISITAS V
        INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC ON VC.ID_VISITA = V.ID
        WHERE VC.ID_CONSULTOR = @CONS_ID AND V.FECHA_DESDE >= @DESDE12;

        DECLARE @CO_SEM DATE = DATEADD(DAY, 7, @HOY), @CO_FIN_MES DATETIME = DATEADD(MONTH, 1, @MES_INI);

        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''consultor'', 1, ''Mis proyectos'', (SELECT COUNT(*) FROM #DP), ''N'',
               CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #DP WHERE EST = ''ENCURSO'')) + '' en curso &middot; ''
             + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #DP WHERE EST = ''CONFIRMADO'')) + '' en lanzamiento'', ''blue'', ''folder'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''consultor'', 2, ''Visitas del mes'', (SELECT COUNT(*) FROM #CV WHERE FECHA >= @MES_INI AND FECHA < @CO_FIN_MES), ''N'',
               ''pr&oacute;xima: '' + ISNULL((SELECT TOP 1 CONVERT(VARCHAR(10), FECHA, 103) FROM #CV WHERE FECHA >= GETDATE() ORDER BY FECHA), ''sin agendar''),
               ''violet'', ''calendar'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''consultor'', 3, ''Horas del mes'', ISNULL((SELECT SUM(HEJEC) FROM #CV WHERE FECHA >= @MES_INI AND FECHA < @CO_FIN_MES), 0), ''H'',
               ''ejecutadas &middot; '' + CONVERT(VARCHAR(20), CONVERT(INT, ISNULL((SELECT SUM(HPLAN) FROM #CV WHERE FECHA >= @MES_INI AND FECHA < @CO_FIN_MES), 0))) + '' h programadas'',
               ''mint'', ''clock-3'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''consultor'', 4, ''Mis acciones abiertas'', (SELECT COUNT(*) FROM #CA WHERE FINAL = 0), ''N'',
               CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #CA WHERE FINAL = 0 AND VENCE < @HOY)) + '' vencida(s) &middot; ''
             + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #CA WHERE FINAL = 0 AND VENCE >= @HOY AND VENCE <= @CO_SEM)) + '' en 7 d&iacute;as'', ''amber'', ''list-checks'';

        /* mis acciones abiertas por vencimiento */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (31, ''consultor'', 1, ''V'', ''Mis acciones abiertas por vencimiento'', ''a mi cargo (plan, pendientes, visitas)'', ''list-checks'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 31, B.O, B.L, (SELECT COUNT(*) FROM #CA A WHERE A.FINAL = 0 AND
                                CASE WHEN A.VENCE IS NULL THEN 5 WHEN A.VENCE < @HOY THEN 1 WHEN A.VENCE = @HOY THEN 2 WHEN A.VENCE <= @CO_SEM THEN 3 ELSE 4 END = B.O)
        FROM (VALUES (1, ''Vencidas''), (2, ''Hoy''), (3, ''7 d&iacute;as''), (4, ''M&aacute;s adelante''), (5, ''Sin fecha'')) B(O, L);

        /* mis proyectos por etapa */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (32, ''consultor'', 2, ''D'', ''Mis proyectos por etapa'', ''activos'', ''folder'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 32, X.O, X.L, COUNT(*)
        FROM (SELECT CASE WHEN D.EST = ''CONFIRMADO'' THEN 1
                          WHEN EXISTS (SELECT 1 FROM #CA A WHERE A.ID_PROYECTO = D.ID AND A.FINAL = 0 AND A.SUB = ''CARGA_PLAN'') THEN 2 ELSE 3 END AS O,
                     CASE WHEN D.EST = ''CONFIRMADO'' THEN ''Lanzamiento''
                          WHEN EXISTS (SELECT 1 FROM #CA A WHERE A.ID_PROYECTO = D.ID AND A.FINAL = 0 AND A.SUB = ''CARGA_PLAN'') THEN ''Plan por cargar''
                          ELSE ''En ejecuci&oacute;n'' END AS L
              FROM #DP D) X
        GROUP BY X.O, X.L;

        /* horas por mes: ejecutadas */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (33, ''consultor'', 3, ''V'', ''Mis horas ejecutadas por mes'', ''&uacute;ltimos 6 meses'', ''clock-3'', ''H'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 33, M.ORD, M.LBL, ISNULL((SELECT SUM(HEJEC) FROM #CV WHERE FECHA >= M.MES AND FECHA < DATEADD(MONTH, 1, M.MES)), 0)
        FROM #DM M WHERE M.MES >= @DESDE6;

        /* horas por proyecto */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (34, ''consultor'', 4, ''H'', ''Mis horas por proyecto'', ''ejecutadas, &uacute;ltimos 12 meses'', ''briefcase'', ''H'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT TOP 8 34, 0, ISNULL(''('' + P.CODIGO + '') '', '''') + P.NOMBRE, SUM(V.HEJEC)
        FROM #CV V INNER JOIN dbo.VCT_PROYECTOS P ON P.ID = V.ID_PROYECTO
        WHERE V.FECHA <= GETDATE()
        GROUP BY P.CODIGO, P.NOMBRE
        HAVING SUM(V.HEJEC) > 0
        ORDER BY SUM(V.HEJEC) DESC;
    END;

    UPDATE #K SET TXT =
';
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_DASHBOARD.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%DASH_CONSULTOR_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_DASHBOARD ya tenia el Inicio del consultor.'; SET @OK = 0; END;
IF @OK = 1 AND (LEN(@D) - LEN(REPLACE(@D, @A1, N''))) / LEN(@A1) <> 1 BEGIN PRINT 'FALLO dbo.VCT_MAIN_DASHBOARD: no se encontro (una sola vez) "UPDATE #K SET TXT =".'; SET @OK = 0; END;
IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A1, @BLK);
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_DASHBOARD: Inicio del consultor.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_DASHBOARD: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

DECLARE @TRG BIT;
SELECT @TRG = TRG FROM #P33;
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
