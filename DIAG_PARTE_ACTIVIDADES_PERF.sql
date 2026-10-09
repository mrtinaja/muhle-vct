/* ============================================================
   DIAGNOSTICO DE PERFORMANCE - Reportes > Parte de Actividades
   Solo lectura (no modifica nada). Correr en SSMS contra MuhlePROD.
   Rango de prueba: el que rompe hoy (Desde 2024-01-01).
   Pasame TODAS las pestanas de resultados (o usa "Results to Text"
   / "Results to File" y guardalo en la carpeta muhle-vct).
   ============================================================ */
USE [MuhlePROD]
GO
SET NOCOUNT ON;

DECLARE @D DATETIME = '2024-01-01', @H DATETIME = '2026-10-31';

/* 1) Cuantas filas candidatas hay en el rango (antes de filtrar por estado) */
SELECT
    COUNT(*)                                             AS filas_candidatas,
    COUNT(DISTINCT AE.HOLIDAYTEXT)                       AS agendas_distintas
FROM dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK)
WHERE AE.FECHA >= @D AND AE.FECHA <= @H AND AE.TIPO = 'A';

/* 2) Costo REAL de cada funcion escalar sobre 2000 filas (ms) */
IF OBJECT_ID('tempdb..#M') IS NOT NULL DROP TABLE #M;
CREATE TABLE #M (funcion VARCHAR(60), filas INT, ms INT);

SELECT TOP 2000 AE.HOLIDAYTEXT, A.PROYECTO_SERV_ID
INTO #S
FROM dbo.LK_AGENDA_EMPLEADO AE WITH(NOLOCK)
    INNER JOIN dbo.LK_AGENDA A ON AE.HOLIDAYTEXT = A.ID_AGENDA
WHERE AE.FECHA >= @D AND AE.FECHA <= @H AND AE.TIPO = 'A'
ORDER BY AE.FECHA;

DECLARE @t DATETIME2, @n INT, @x INT;
SELECT @n = COUNT(*) FROM #S;

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_AGENDA_ESTADO(HOLIDAYTEXT) = 'C';
INSERT #M VALUES ('FN_GET_AGENDA_ESTADO',   @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_AGENDA_SERVICIO(HOLIDAYTEXT) IS NOT NULL;
INSERT #M VALUES ('FN_GET_AGENDA_SERVICIO', @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_AGENDA_CLIENTE(HOLIDAYTEXT) IS NOT NULL;
INSERT #M VALUES ('FN_GET_AGENDA_CLIENTE',  @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_AGENDA_PROYECTO(HOLIDAYTEXT) IS NOT NULL;
INSERT #M VALUES ('FN_GET_AGENDA_PROYECTO', @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_DOC_VISITA(HOLIDAYTEXT, 'MV') IS NOT NULL;
INSERT #M VALUES ('FN_GET_DOC_VISITA (MV)', @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SET @t = SYSDATETIME(); SELECT @x = COUNT(*) FROM #S WHERE dbo.FN_GET_DOC_VISITA(PROYECTO_SERV_ID, 'IA') IS NOT NULL;
INSERT #M VALUES ('FN_GET_DOC_VISITA (IA)', @n, DATEDIFF(MILLISECOND, @t, SYSDATETIME()));

SELECT funcion, filas, ms, CAST(ms * 1.0 / NULLIF(filas, 0) AS DECIMAL(10,3)) AS ms_por_fila FROM #M ORDER BY ms DESC;

/* 3) Indices existentes en las tablas del filtro */
SELECT o.name AS tabla, i.name AS indice, i.type_desc,
       STUFF((SELECT ', ' + c.name FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0 ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 2, '') AS columnas_clave
FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
WHERE o.name IN ('LK_AGENDA_EMPLEADO', 'LK_AGENDA', 'LK_PROYECTO_DOCUM') AND i.index_id > 0
ORDER BY o.name, i.name;

/* 4) Definiciones de las funciones (para reescribirlas como joins por conjuntos) */
SELECT o.name AS funcion, m.definition
FROM sys.sql_modules m JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.name IN ('FN_GET_AGENDA_ESTADO', 'FN_GET_AGENDA_SERVICIO', 'FN_GET_AGENDA_CLIENTE', 'FN_GET_AGENDA_PROYECTO', 'FN_GET_DOC_VISITA')
ORDER BY o.name;
GO
