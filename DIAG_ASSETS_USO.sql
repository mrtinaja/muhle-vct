/* ============================================================
   DIAG_ASSETS_USO  —  Fase 7 (inventario de obsoletos)
   Sólo-lectura. Cuenta en cuántos objetos (SP/funciones/vistas/triggers)
   de la base viva se referencia cada asset candidato a huérfano.
   Si COUNT = 0 en la base viva -> el asset NO lo carga ningún objeto
   de la base -> candidato real a eliminar (confirmar también en
   .aspx/.master del server, que no están en sys.sql_modules).

   USO en SSMS:  Query > SQLCMD Mode,  luego F5.
   La salida queda en el repo, en _diag\ASSETS_USO.txt
   ============================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\ASSETS_USO.txt
SET NOCOUNT ON;

DECLARE @cand TABLE (asset VARCHAR(200));
INSERT INTO @cand (asset) VALUES
  ('vct-mainMobile.css'),
  ('vct-main_SI.js'),
  ('font-awesome.css'),           -- ojo: NO confundir con font-awesome.min.css / font-awesome-5-all.css
  ('portal-vocaturoBK.css'),
  ('portal-vocaturo.js'),
  ('Main-Copy.js'),
  ('vct-plan-gantt-pdf.js'),
  ('vct-proyecto-agenda.css'),
  ('vct-proyecto-agenda.js'),
  ('vct-proyectos.css'),
  ('vct_main_proyecto_v360_bkp.css'),
  ('vct-loading-overlay.js'),
  ('vct-Agenda.js');

/* Conteo de objetos de la base que mencionan cada asset */
SELECT
    c.asset,
    COUNT(m.object_id) AS objetos_que_lo_usan
FROM @cand c
LEFT JOIN sys.sql_modules m
       ON m.definition LIKE '%' + c.asset + '%'
GROUP BY c.asset
ORDER BY objetos_que_lo_usan ASC, c.asset;

PRINT '';
PRINT '--- Detalle: qué objeto usa cada asset que SÍ aparece (si objetos_que_lo_usan > 0) ---';

SELECT
    c.asset,
    OBJECT_SCHEMA_NAME(m.object_id) + '.' + OBJECT_NAME(m.object_id) AS objeto,
    o.type_desc
FROM @cand c
JOIN sys.sql_modules m ON m.definition LIKE '%' + c.asset + '%'
JOIN sys.objects o     ON o.object_id = m.object_id
ORDER BY c.asset, objeto;

:OUT stdout
SET NOCOUNT OFF;
