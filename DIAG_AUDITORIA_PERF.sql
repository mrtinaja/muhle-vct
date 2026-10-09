/* ============================================================
   DIAGNOSTICO DE PERFORMANCE - Reportes > Seguimiento de Auditoria
   Solo lectura. Correr en SSMS contra MuhlePROD y pasar TODAS las
   pestanas de resultados (o "Results to Text").
   Rango de prueba: Desde 2024-01-01 (el que da timeout en la web).
   ============================================================ */
USE [MuhlePROD]
GO
SET NOCOUNT ON;
DECLARE @D DATETIME = '2024-01-01', @H DATETIME = '2026-10-31';

/* 1) Cuantos servicios de auditoria caen en el rango */
SELECT COUNT(*) AS servicios_en_rango
FROM dbo.LK_PROYECTO_SERVICIO PS
WHERE PS.FECHA_INICIO_REAL >= @D AND PS.FECHA_INICIO_REAL <= @H AND PS.ID_TIPO_SERVICIO = '2';

/* 2) Tiempo REAL de cada funcion sobre una muestra de hasta 300 servicios (ms) */
IF OBJECT_ID('tempdb..#AUD_S') IS NOT NULL DROP TABLE #AUD_S;
SELECT TOP 300 P.ID_CLIENTE, PS.ID_PROYECTO, PS.ID_TIPO_SERVICIO, PS.ID_PROYECTO_SERVICIO, PS.FECHA_FIN_REAL
INTO #AUD_S
FROM dbo.LK_PROYECTO P WITH(NOLOCK)
    INNER JOIN dbo.LK_PROYECTO_SERVICIO PS ON P.ID_PROYECTO = PS.ID_PROYECTO
WHERE PS.FECHA_INICIO_REAL >= @D AND PS.FECHA_INICIO_REAL <= @H AND PS.ID_TIPO_SERVICIO = '2'
ORDER BY PS.FECHA_INICIO_REAL;

DECLARE @M TABLE (funcion VARCHAR(60), filas INT, ms INT);
DECLARE @t DATETIME2, @n INT, @x INT, @sql NVARCHAR(MAX);
SELECT @n = COUNT(*) FROM #AUD_S;

/* SQL dinamico: las columnas de #AUD_S se resuelven al EJECUTAR, no al compilar el lote */
DECLARE @f TABLE (nombre VARCHAR(60), predicado NVARCHAR(400));
INSERT @f VALUES
 ('FN_GET_SERVICIO_CONSULTORES', N'dbo.FN_GET_SERVICIO_CONSULTORES(ID_CLIENTE, ID_PROYECTO, ID_TIPO_SERVICIO, ID_PROYECTO_SERVICIO)'),
 ('FN_GET_SERVICIO_DIAS',        N'dbo.FN_GET_SERVICIO_DIAS(ID_CLIENTE, ID_PROYECTO, ID_TIPO_SERVICIO, ID_PROYECTO_SERVICIO)'),
 ('FN_GET_TOTAL_HS_EJECUTADAS',  N'dbo.FN_GET_TOTAL_HS_EJECUTADAS(''PS'', NULL, NULL, ID_PROYECTO_SERVICIO)'),
 ('FN_GET_DIAS_HABILES',         N'dbo.FN_GET_DIAS_HABILES(FECHA_FIN_REAL, GETDATE())');

DECLARE @nombre VARCHAR(60), @pred NVARCHAR(400);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT nombre, predicado FROM @f;
OPEN c; FETCH NEXT FROM c INTO @nombre, @pred;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @x = COUNT(*) FROM #AUD_S WHERE ' + @pred + N' IS NOT NULL;';
    SET @t = SYSDATETIME();
    EXEC sp_executesql @sql, N'@x INT OUTPUT', @x = @x OUTPUT;
    INSERT @M VALUES (@nombre, @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));
    FETCH NEXT FROM c INTO @nombre, @pred;
END
CLOSE c; DEALLOCATE c;

SELECT funcion, filas, ms, CAST(ms * 1.0 / NULLIF(filas, 0) AS DECIMAL(10,3)) AS ms_por_fila FROM @M ORDER BY ms DESC;

/* 3) Costo de las dos subconsultas agrupadas (Plan / Informe) */
SET @t = SYSDATETIME();
SELECT @x = COUNT(*) FROM (SELECT PS2.ID_PROYECTO_SERVICIO IDPS, MAX(PD.FECHA_DOCUM) FECHA
    FROM dbo.LK_PROYECTO_SERVICIO PS2 LEFT JOIN dbo.LK_PROYECTO_DOCUM PD ON PS2.ID_PROYECTO_SERVICIO = PD.PROYECTO_SERV_ID AND PD.TIPO = 'PA'
    GROUP BY PS2.ID_PROYECTO_SERVICIO) Z;
SELECT 'subconsulta Plan Auditoria (PA)' AS que, DATEDIFF(MILLISECOND, @t, SYSDATETIME()) AS ms, @x AS filas;

/* 4) Definiciones de las funciones */
SELECT o.name AS funcion, m.definition
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.name IN ('FN_GET_SERVICIO_CONSULTORES', 'FN_GET_SERVICIO_DIAS', 'FN_GET_TOTAL_HS_EJECUTADAS', 'FN_GET_DIAS_HABILES')
ORDER BY o.name;
GO
