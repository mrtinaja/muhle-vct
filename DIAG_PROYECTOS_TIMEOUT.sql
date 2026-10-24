/* ============================================================
   DIAG_PROYECTOS_TIMEOUT  —  por qué VCT_MAIN_PROYECTOS da timeout
   Sólo-lectura. SSMS no tiene el límite de 30s de la app, así que
   el SP completa y STATISTICS TIME muestra QUÉ statement tarda.

   USO:  SSMS > Query > SQLCMD Mode  ->  F5.
   Salida: _diag\PROYECTOS_TIMEOUT.txt
   ============================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\PROYECTOS_TIMEOUT.txt
USE [MuhlePROD];
SET NOCOUNT ON;

/* ---------- 1) Volumen de datos involucrado ---------- */
PRINT '=== CONTEOS ===';
SELECT 'VCT_PROYECTOS'            AS tabla, COUNT(*) AS filas FROM dbo.VCT_PROYECTOS
UNION ALL SELECT 'VCT_PROYECTOS_EQUIPO',    COUNT(*) FROM dbo.VCT_PROYECTOS_EQUIPO
UNION ALL SELECT 'VCT_PROYECTOS_SERVICIOS', COUNT(*) FROM dbo.VCT_PROYECTOS_SERVICIOS
UNION ALL SELECT 'VCT_PRM_SERVICIOS',       COUNT(*) FROM dbo.VCT_PRM_SERVICIOS
UNION ALL SELECT 'VCT_EMPLEADOS',           COUNT(*) FROM dbo.VCT_EMPLEADOS
UNION ALL SELECT 'VCT_CLIENTES',            COUNT(*) FROM dbo.VCT_CLIENTES;

/* ---------- 2) Índices existentes en las tablas de las subconsultas ---------- */
PRINT '';
PRINT '=== INDICES en EQUIPO / SERVICIOS (para ver si falta soporte) ===';
SELECT OBJECT_NAME(i.object_id) AS tabla, i.name AS indice, i.type_desc,
       STUFF((SELECT ', ' + c.name FROM sys.index_columns ic
              JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
              WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id AND ic.is_included_column=0
              ORDER BY ic.key_ordinal FOR XML PATH('')),1,2,'') AS columnas
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.VCT_PROYECTOS_EQUIPO'), OBJECT_ID('dbo.VCT_PROYECTOS_SERVICIOS'))
  AND i.type_desc <> 'HEAP'
ORDER BY tabla, indice;

/* ---------- 3) Ejecutar el SP con timing por statement ---------- */
PRINT '';
PRINT '=== EJECUCION DEL SP (mirar el statement con mayor elapsed time) ===';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @o1 VARCHAR(MAX), @o2 VARCHAR(MAX), @o3 VARCHAR(MAX);
DECLARE @t0 DATETIME2 = SYSDATETIME();

EXEC dbo.VCT_MAIN_PROYECTOS
     @IPKEYJOB = '00000000-0000-0000-0000-000000000000',
     @FORM_ID  = 'diag',
     @IUNIDAD  = 'GERENCIA',
     @IAGENTE  = 'avocaturo',
     @OUTPARAM1 = @o1 OUTPUT, @OUTPARAM2 = @o2 OUTPUT, @OUTPARAM3 = @o3 OUTPUT;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

PRINT '';
PRINT '=== TOTAL ===';
PRINT 'Elapsed total (ms): ' + CONVERT(VARCHAR(20), DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
PRINT 'Largo del HTML devuelto: ' + CONVERT(VARCHAR(20), LEN(@o1));

:OUT stdout
SET NOCOUNT OFF;
