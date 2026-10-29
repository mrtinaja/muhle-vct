:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\VCT_MAIN_DASHBOARD.txt
/* ============================================================================
   DIAG_TABLERO_CONSULTOR (29/10/2026)  solo lectura
   Para armar el Tablero de control del consultor sobre la version VIVA del Inicio:
   1) vuelca dbo.VCT_MAIN_DASHBOARD a _diag\VCT_MAIN_DASHBOARD.txt
   2) columnas de las tablas que usa el tablero y parametria de estados, a _diag\DIAG_TABLERO_CONSULTOR.txt
   SSMS: Query > SQLCMD Mode, F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD'));
IF @D IS NULL PRINT 'No se encontro dbo.VCT_MAIN_DASHBOARD.'
ELSE
BEGIN
    DECLARE @TOTAL INT = DATALENGTH(@D) / 2, @P INT = 1, @E INT, @LINE NVARCHAR(MAX);
    WHILE @P <= @TOTAL
    BEGIN
        SET @E = CHARINDEX(NCHAR(10), @D, @P);
        IF @E = 0 SET @E = @TOTAL + 1;
        SET @LINE = SUBSTRING(@D, @P, @E - @P);
        IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13) SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
        WHILE (DATALENGTH(@LINE) / 2) > 4000
        BEGIN
            PRINT SUBSTRING(@LINE, 1, 4000);
            SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
        END;
        PRINT @LINE;
        SET @P = @E + 1;
    END;
END;
GO
:OUT C:\Users\EstebanDemarco\Desktop\Vocaturo\muhle-vct\_diag\DIAG_TABLERO_CONSULTOR.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '== 1. columnas ==';
SELECT T.NAME AS TABLA, C.NAME AS COLUMNA, TY.NAME AS TIPO, C.MAX_LENGTH, C.IS_NULLABLE
FROM sys.tables T JOIN sys.columns C ON C.object_id = T.object_id JOIN sys.types TY ON TY.user_type_id = C.user_type_id
WHERE T.NAME IN ('VCT_ACCIONES','VCT_ACCIONES_DESARROLLO','VCT_PROYECTOS_PLANES','VCT_PROYECTOS_PLAN_ITEMS','VCT_PROYECTOS_EQUIPO','VCT_PROYECTOS',
                 'VCT_PROYECTOS_SERVICIOS','VCT_PROYECTOS_VISITAS','VCT_PRM_ACCIONES_ESTADOS','VCT_PRM_PROYECTOS_ESTADOS','VCT_PRM_ACCIONES_TIPOS','VCT_PRM_ACCIONES_SUBTIPOS')
ORDER BY T.NAME, C.column_id;

PRINT '== 2. estados de acciones ==';
IF OBJECT_ID('dbo.VCT_PRM_ACCIONES_ESTADOS') IS NOT NULL EXEC('SELECT * FROM dbo.VCT_PRM_ACCIONES_ESTADOS WITH(NOLOCK)');
PRINT '== 3. estados de proyectos ==';
IF OBJECT_ID('dbo.VCT_PRM_PROYECTOS_ESTADOS') IS NOT NULL EXEC('SELECT * FROM dbo.VCT_PRM_PROYECTOS_ESTADOS WITH(NOLOCK)');

PRINT '== 4. volumen (para dimensionar) ==';
SELECT (SELECT COUNT(*) FROM dbo.VCT_ACCIONES WITH(NOLOCK)) AS ACCIONES,
       (SELECT COUNT(*) FROM dbo.VCT_ACCIONES WITH(NOLOCK) WHERE ID_PLAN_ITEM IS NOT NULL) AS ACCIONES_PLAN,
       (SELECT COUNT(*) FROM dbo.VCT_ACCIONES_DESARROLLO WITH(NOLOCK)) AS DESARROLLOS,
       (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_VISITAS WITH(NOLOCK)) AS VISITAS,
       (SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_EQUIPO WITH(NOLOCK) WHERE TIPO_MIEMBRO = 'CONSULTOR' AND ESTADO = 'ACTIVO') AS CONSULTORES_EN_EQUIPOS;

PRINT '== 5. indices de las tablas grandes ==';
SELECT T.NAME AS TABLA, I.NAME AS INDICE, I.TYPE_DESC,
       STUFF((SELECT ',' + C.NAME FROM sys.index_columns IC JOIN sys.columns C ON C.object_id = IC.object_id AND C.column_id = IC.column_id
              WHERE IC.object_id = I.object_id AND IC.index_id = I.index_id ORDER BY IC.key_ordinal FOR XML PATH('')), 1, 1, '') AS COLUMNAS
FROM sys.indexes I JOIN sys.tables T ON T.object_id = I.object_id
WHERE T.NAME IN ('VCT_ACCIONES','VCT_ACCIONES_DESARROLLO','VCT_PROYECTOS_VISITAS','VCT_PROYECTOS_VISITAS_CONSULTORES','VCT_PRM_AGENDA_CONSULTOR') AND I.index_id > 0
ORDER BY T.NAME, I.index_id;

PRINT '== 6. assets que carga hoy el Inicio ==';
DECLARE @D2 NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_DASHBOARD')), @i INT = 1, @j INT;
WHILE 1 = 1
BEGIN
    SET @i = CHARINDEX('?v=', @D2, @i);
    IF @i = 0 BREAK;
    SET @j = @i - 60; IF @j < 1 SET @j = 1;
    PRINT SUBSTRING(@D2, @j, 70);
    SET @i = @i + 3;
END;
PRINT '== fin ==';
GO
:OUT stdout
