/* DIAG_OBJETOS_MODIFICADOS (solo lectura): lista SPs/funciones por fecha de
   modificacion (mas recientes arriba), para ver que cambio en la base (server)
   y re-sincronizar el repo. SSMS F5. Pegame los primeros ~25 renglones. */
USE [MuhlePROD];
SET NOCOUNT ON;
SELECT TOP 40
       o.type_desc                                   AS tipo,
       o.name                                        AS objeto,
       CONVERT(VARCHAR(19), o.modify_date, 120)      AS modificado,
       DATEDIFF(HOUR, o.modify_date, GETDATE())      AS hace_horas
FROM sys.objects o
WHERE o.type IN ('P','FN','IF','TF','V')          /* procs, funciones, vistas */
  AND o.is_ms_shipped = 0
  AND o.name LIKE 'VCT[_]%'                         /* solo objetos VCT */
ORDER BY o.modify_date DESC;
