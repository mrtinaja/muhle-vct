/* ============================================================
   DIAG_PROYECTOS_TIEMPO  —  verificar que el fix anda
   Ejecuta el VCT_MAIN_PROYECTOS ya reescrito y mide el tiempo.
   Si da < 1000 ms -> el fix funciono (antes: timeout > 30000 ms).
   NO necesita login. Sólo-lectura (el SP no escribe datos).
   USO: SSMS > Query > SQLCMD Mode -> F5.  Salida: _diag\PROYECTOS_TIEMPO.txt
   ============================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\PROYECTOS_TIEMPO.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @o1 VARCHAR(MAX), @o2 VARCHAR(MAX), @o3 VARCHAR(MAX);
DECLARE @t0 DATETIME2 = SYSDATETIME();

EXEC dbo.VCT_MAIN_PROYECTOS
     @IPKEYJOB  = '00000000-0000-0000-0000-000000000000',
     @FORM_ID   = 'diag',
     @IUNIDAD   = 'GERENCIA',
     @IAGENTE   = 'avocaturo',
     @OUTPARAM1 = @o1 OUTPUT, @OUTPARAM2 = @o2 OUTPUT, @OUTPARAM3 = @o3 OUTPUT;

DECLARE @ms INT = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
PRINT 'Elapsed (ms): ' + CONVERT(VARCHAR(20), @ms);
PRINT 'Largo HTML: ' + CONVERT(VARCHAR(20), LEN(@o1));
PRINT CASE WHEN @ms < 2000 THEN 'OK: el fix funciono.' ELSE 'ATENCION: sigue lento, revisar.' END;
PRINT '--- primeros 400 chars del HTML (sanity) ---';
PRINT LEFT(@o1, 400);

:OUT stdout
PRINT 'DIAG TIEMPO completo.';
