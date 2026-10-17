/* ========================================================================
   PASO3_2_ACCIONES_Y_DASHBOARD_ANALISTA
   ------------------------------------------------------------------------
   1. dbo.VCT_MAIN_ACCIONES (Vencidas / Hoy / Proximas / Todas): el menu de
      3 puntos de cada accion queda con UNA sola opcion, "Gestionar", que
      abre la Vista 360 del proyecto (la opcion PROYECTOS VIEW que ya
      existia). Salen "Ver / Editar accion" y "Marcar cumplida". Se muestra
      tambien en las acciones cerradas. Marca ACC_GESTIONAR_V1.
   2. dbo.VCT_MAIN_DASHBOARD (Inicio), vista ANALISTA (perfil PROYECTOS):
      se reemplazan tarjetas y graficos (horas y visitas no aplican al
      analista) por seguimiento de proyectos y acciones. Marca DASH_ANALISTA_V1.
      Gerencia, Administracion y Consultor no cambian.
   Se parchea la definicion vigente de cada SP (no se reescriben). No crea
   objetos ni toca permisos. Re-ejecutable.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#P32') IS NOT NULL DROP TABLE #P32;
CREATE TABLE #P32 (TRG BIT);
INSERT INTO #P32 VALUES (0);
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
BEGIN
    DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    UPDATE #P32 SET TRG = 1;
END;
GO

/* ---------------- 1. Acciones: solo "Gestionar" ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_ACCIONES')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(400) = N'WHERE P.MODULO = ''ACCIONES'' AND P.ACTION_TYPE IN (''VIEW'',''EDIT'')',
        @A2 NVARCHAR(400) = N'ISNULL(NULLIF(A.TITLE,''''), ''Ver proyecto''), ISNULL(NULLIF(A.ICON,''''), ''scan-eye'')',
        @A3 NVARCHAR(400) = N'WHERE @PUEDE_ESTADO = 1 AND A.ES_FINAL = 0 AND (@VE_TODO = 1 OR A.MIA = 1)',
        @A4 NVARCHAR(400) = N'WHERE A.ES_FINAL = 0;';
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_ACCIONES.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%ACC_GESTIONAR_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_ACCIONES ya tenia el cambio.'; SET @OK = 0; END;
IF @OK = 1 AND (CHARINDEX(@A1, @D) = 0 OR CHARINDEX(@A2, @D) = 0 OR CHARINDEX(@A3, @D) = 0 OR CHARINDEX(@A4, @D) = 0)
BEGIN
    PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: no se encontraron los textos del menu de 3 puntos ('
        + CASE WHEN CHARINDEX(@A1, @D) = 0 THEN 'ver/editar ' ELSE '' END + CASE WHEN CHARINDEX(@A2, @D) = 0 THEN 'ver proyecto ' ELSE '' END
        + CASE WHEN CHARINDEX(@A3, @D) = 0 THEN 'marcar cumplida ' ELSE '' END + CASE WHEN CHARINDEX(@A4, @D) = 0 THEN 'filtro abiertas' ELSE '' END + ').';
    SET @OK = 0;
END;
IF @OK = 1
BEGIN
    SET @D = REPLACE(@D, @A1, @A1 + N' AND 1 = 0 /* ACC_GESTIONAR_V1 */');
    SET @D = REPLACE(@D, @A2, N'''Gestionar'', ''arrow-right''');
    SET @D = REPLACE(@D, @A3, N'WHERE 1 = 0 AND @PUEDE_ESTADO = 1 AND A.ES_FINAL = 0 AND (@VE_TODO = 1 OR A.MIA = 1)');
    SET @D = REPLACE(@D, @A4, N'WHERE A.ID_PROYECTO IS NOT NULL;');
    SET @P = CHARINDEX(N'CREATE', @D);
    WHILE @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'PROC%'
          AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
    IF @P > 0 AND LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 30), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' ')) NOT LIKE N'OR ALTER PROC%'
        SET @D = STUFF(@D, @P, 6, N'ALTER');
    BEGIN TRY
        EXEC sp_executesql @D;
        PRINT 'OK   dbo.VCT_MAIN_ACCIONES: menu de 3 puntos solo con Gestionar (Vista 360 del proyecto).';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_ACCIONES: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

/* ---------------- 2. Inicio: tablero del analista ---------------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.VCT_MAIN_DASHBOARD')), @OK BIT = 1, @P INT,
        @A1 NVARCHAR(200) = N'IF @VISTA IN (''GERENCIA'',''ANALISTA'')',
        @BLK NVARCHAR(MAX) = N'/* ===================================================================
       MIS PROYECTOS (ANALISTA) - DASH_ANALISTA_V1
       El analista no ejecuta horas ni visitas: coordina, hace seguimiento y cumple acciones.
       Alcance: proyectos del equipo donde es analista (#SC / #DP); acciones a su cargo.
       =================================================================== */
    IF @VISTA = ''ANALISTA''
    BEGIN
        CREATE TABLE #AA (ID INT PRIMARY KEY, ID_PROYECTO INT, MIA BIT, FINAL BIT, CUMPLIDA BIT, VENCE DATE, CIERRE DATETIME, CREA DATETIME);
        INSERT INTO #AA (ID, ID_PROYECTO, MIA, FINAL, CUMPLIDA, VENCE, CIERRE, CREA)
        SELECT A.ID, A.ID_PROYECTO,
               CASE WHEN @EMP_ID IS NULL THEN 1
                    WHEN EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WHERE AP.ID_ACCION = A.ID AND AP.ESTADO = ''ACTIVO''
                                 AND AP.ROL_PARTICIPANTE = ''RESPONSABLE'' AND AP.TIPO_ENTIDAD = ''EMPLEADO'' AND AP.ID_ENTIDAD = @EMP_ID) THEN 1 ELSE 0 END,
               ISNULL(E.ES_FINAL, 0), CASE WHEN E.CODIGO = ''CUMPLIDA'' THEN 1 ELSE 0 END,
               CONVERT(DATE, A.FECHA_VENCIMIENTO), A.FECHA_CIERRE, A.FECHA_CREACION
        FROM dbo.VCT_ACCIONES A
        INNER JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E ON E.ID = A.ID_ESTADO
        WHERE A.ID_PROYECTO IN (SELECT ID FROM #SC)
           OR (@EMP_ID IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.VCT_ACCIONES_PARTICIPANTES AP WHERE AP.ID_ACCION = A.ID AND AP.ESTADO = ''ACTIVO''
                                               AND AP.ROL_PARTICIPANTE = ''RESPONSABLE'' AND AP.TIPO_ENTIDAD = ''EMPLEADO'' AND AP.ID_ENTIDAD = @EMP_ID));

        DECLARE @AN_SEM DATE = DATEADD(DAY, 7, @HOY),
                @AN_CUMP_MES INT, @AN_A_TERM INT;
        SELECT @AN_CUMP_MES = COUNT(*), @AN_A_TERM = SUM(CASE WHEN VENCE IS NULL OR CONVERT(DATE, CIERRE) <= VENCE THEN 1 ELSE 0 END)
        FROM #AA WHERE MIA = 1 AND CUMPLIDA = 1 AND CIERRE >= @MES_INI AND CIERRE < DATEADD(MONTH, 1, @MES_INI);

        /* tarjetas */
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''proyectos'', 1, ''Proyectos a cargo'', (SELECT COUNT(*) FROM #DP), ''N'',
               CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #DP WHERE EST = ''ENCURSO'')) + '' en curso &middot; ''
             + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #DP WHERE EST = ''CONFIRMADO'')) + '' por iniciar'', ''blue'', ''folder'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''proyectos'', 2, ''En lanzamiento'', (SELECT COUNT(*) FROM #DP WHERE EST = ''CONFIRMADO''), ''N'',
               CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #DP D WHERE D.EST = ''CONFIRMADO''
                                     AND NOT EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL AND R.CODIGO = ''CONSULTOR_LIDER''
                                                     WHERE EQ.ID_PROYECTO = D.ID AND EQ.ESTADO = ''ACTIVO''))) + '' sin consultor l&iacute;der'', ''violet'', ''check'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''proyectos'', 3, ''Mis acciones abiertas'', (SELECT COUNT(*) FROM #AA WHERE MIA = 1 AND FINAL = 0), ''N'',
               CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #AA WHERE MIA = 1 AND FINAL = 0 AND VENCE < @HOY)) + '' vencida(s) &middot; ''
             + CONVERT(VARCHAR(10), (SELECT COUNT(*) FROM #AA WHERE MIA = 1 AND FINAL = 0 AND VENCE >= @HOY AND VENCE <= @AN_SEM)) + '' en 7 d&iacute;as'', ''amber'', ''list-checks'';
        INSERT INTO #K (PANEL, ORD, LBL, VAL, FMT, SUB, TONE, ICON)
        SELECT ''proyectos'', 4, ''Cumplidas del mes'', ISNULL(@AN_CUMP_MES, 0), ''N'',
               CASE WHEN ISNULL(@AN_CUMP_MES, 0) = 0 THEN ''sin acciones cumplidas''
                    ELSE CONVERT(VARCHAR(10), CONVERT(INT, ROUND(100.0 * ISNULL(@AN_A_TERM, 0) / @AN_CUMP_MES, 0))) + ''% a t&eacute;rmino'' END, ''mint'', ''clipboard-check'';

        /* proyectos por etapa del workflow */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (21, ''proyectos'', 1, ''D'', ''Mis proyectos por etapa'', ''activos (confirmados y en curso)'', ''folder'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 21, X.O, X.L, COUNT(*)
        FROM (SELECT CASE WHEN D.EST = ''ENCURSO'' THEN 3
                          WHEN EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL AND R.CODIGO = ''CONSULTOR_LIDER''
                                       WHERE EQ.ID_PROYECTO = D.ID AND EQ.ESTADO = ''ACTIVO'') THEN 2 ELSE 1 END AS O,
                     CASE WHEN D.EST = ''ENCURSO'' THEN ''En curso''
                          WHEN EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_EQUIPO EQ INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL AND R.CODIGO = ''CONSULTOR_LIDER''
                                       WHERE EQ.ID_PROYECTO = D.ID AND EQ.ESTADO = ''ACTIVO'') THEN ''Lanzamiento'' ELSE ''Sin consultor asignado'' END AS L
              FROM #DP D) X
        GROUP BY X.O, X.L;

        /* mis acciones abiertas por vencimiento */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (22, ''proyectos'', 2, ''V'', ''Mis acciones abiertas por vencimiento'', ''a mi cargo'', ''calendar'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 22, B.O, B.L, (SELECT COUNT(*) FROM #AA A WHERE A.MIA = 1 AND A.FINAL = 0 AND
                                CASE WHEN A.VENCE IS NULL THEN 5 WHEN A.VENCE < @HOY THEN 1 WHEN A.VENCE = @HOY THEN 2 WHEN A.VENCE <= @AN_SEM THEN 3 ELSE 4 END = B.O)
        FROM (VALUES (1, ''Vencidas''), (2, ''Hoy''), (3, ''7 d&iacute;as''), (4, ''M&aacute;s adelante''), (5, ''Sin fecha'')) B(O, L);

        /* proyectos con mas acciones abiertas (de todo el equipo) */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (23, ''proyectos'', 3, ''H'', ''Acciones abiertas por proyecto'', ''de todo el equipo; los que m&aacute;s seguimiento piden'', ''clipboard-check'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT TOP 8 23, 0, ISNULL(''('' + D.CODIGO + '') '', '''') + D.NOMBRE, COUNT(*)
        FROM #AA A INNER JOIN #DP D ON D.ID = A.ID_PROYECTO
        WHERE A.FINAL = 0
        GROUP BY D.CODIGO, D.NOMBRE
        ORDER BY COUNT(*) DESC;

        /* acciones cumplidas por mes */
        INSERT INTO #C (CH, PANEL, ORD, TIPO, TITULO, SUB, ICON, FMT, ANCHO) VALUES (24, ''proyectos'', 4, ''V'', ''Acciones cumplidas por mes'', ''a mi cargo &middot; &uacute;ltimos 6 meses'', ''list-checks'', ''N'', ''N'');
        INSERT INTO #S (CH, ORD, LBL, VAL)
        SELECT 24, M.ORD, M.LBL, (SELECT COUNT(*) FROM #AA A WHERE A.MIA = 1 AND A.CUMPLIDA = 1 AND A.CIERRE >= M.MES AND A.CIERRE < DATEADD(MONTH, 1, M.MES))
        FROM #DM M WHERE M.MES >= @DESDE6;

    END;

    IF @VISTA = ''GERENCIA''
';
IF @D IS NULL BEGIN PRINT 'FALLO no existe dbo.VCT_MAIN_DASHBOARD.'; SET @OK = 0; END;
IF @OK = 1 AND @D LIKE N'%DASH_ANALISTA_V1%' BEGIN PRINT 'OK   dbo.VCT_MAIN_DASHBOARD ya tenia el cambio.'; SET @OK = 0; END;
IF @OK = 1 AND CHARINDEX(@A1, @D) = 0 BEGIN PRINT 'FALLO dbo.VCT_MAIN_DASHBOARD: no se encontro el bloque de Operacion / Mis proyectos.'; SET @OK = 0; END;
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
        PRINT 'OK   dbo.VCT_MAIN_DASHBOARD: Inicio del analista con seguimiento de proyectos y acciones.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLO dbo.VCT_MAIN_DASHBOARD: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

DECLARE @TRG BIT;
SELECT @TRG = TRG FROM #P32;
IF @TRG = 1
BEGIN
    ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
    PRINT 'OK   trigger TR_VCT_AUDITORIA_DDL reactivado.';
END;
GO
