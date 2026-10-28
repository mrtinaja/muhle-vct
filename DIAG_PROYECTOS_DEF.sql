/* ============================================================
   DIAG_PROYECTOS_DEF  —  confirmar fuente antes de aplicar el fix
   Sólo-lectura. Vuelca: (1) si existe VCT_HTML_ESC, (2) la definicion
   VIVA de VCT_MAIN_PROYECTOS tal cual esta en el server.
   USO: SSMS > Query > SQLCMD Mode -> F5.  Salida: _diag\PROYECTOS_DEF.txt
   ============================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\PROYECTOS_DEF.txt
USE [MuhlePROD];
SET NOCOUNT ON;

PRINT '=== EXISTENCIA DE OBJETOS ===';
SELECT
    CASE WHEN OBJECT_ID('dbo.VCT_HTML_ESC')      IS NULL THEN 'NO existe' ELSE 'existe (' + ISNULL((SELECT type_desc FROM sys.objects WHERE object_id=OBJECT_ID('dbo.VCT_HTML_ESC')),'?') + ')' END AS VCT_HTML_ESC,
    CASE WHEN OBJECT_ID('dbo.VCT_MAIN_PROYECTOS') IS NULL THEN 'NO existe' ELSE 'existe' END AS VCT_MAIN_PROYECTOS;

PRINT '';
PRINT '=== DEFINICION VIVA DE VCT_MAIN_PROYECTOS ===';
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS')) AS definicion;

:OUT stdout
PRINT 'DIAG DEF completo.';
