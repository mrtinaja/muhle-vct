/* ============================================================
   DIAG_PROYECTOS_TIMEOUT  (v4)  —  UDF escalar vs REPLACE inline
   Sólo-lectura. SIN "SET STATISTICS IO" (con UDF escalar inunda Messages
   y traba SSMS). Compara el MISMO gather de datos:
     (C) como el SP, con VCT_HTML_ESC (UDF escalar)
     (E) idéntico pero con REPLACE inline (set-based, sin UDF)
   Si C >> E, la UDF es el cuello y el fix es pre-escapar inline.

   USO:  SSMS > Query > SQLCMD Mode  ->  F5.   Salida: _diag\PROYECTOS_TIMEOUT.txt
   ============================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\PROYECTOS_TIMEOUT.txt
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* ---------- C) gather CON UDF escalar (como el SP) ---------- */
PRINT '=== C) INSERT con VCT_HTML_ESC (UDF escalar) ===';
IF OBJECT_ID('tempdb..#C') IS NOT NULL DROP TABLE #C;
CREATE TABLE #C (ID INT, SERV_HTML VARCHAR(MAX), ANALISTA VARCHAR(320));
DECLARE @c0 DATETIME2 = SYSDATETIME();
INSERT INTO #C (ID, SERV_HTML, ANALISTA)
SELECT P.ID,
    ISNULL((SELECT ' ' + dbo.VCT_HTML_ESC(PS.DESCRIPCION)
     FROM dbo.VCT_PROYECTOS_SERVICIOS XS JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = XS.ID_SERVICIO
     WHERE XS.ID_PROYECTO = P.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),
    (SELECT TOP 1 dbo.VCT_HTML_ESC(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + CASE WHEN ISNULL(E.NOMBRES,'')<>'' THEN ', '+E.NOMBRES ELSE '' END)))
     FROM dbo.VCT_PROYECTOS_EQUIPO EQ
     JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
     JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
     WHERE EQ.ID_PROYECTO = P.ID AND R.CODIGO = 'ANALISTA' AND ISNULL(EQ.ESTADO,'ACTIVO')='ACTIVO')
FROM dbo.VCT_PROYECTOS P;
DECLARE @ms_c INT = DATEDIFF(MILLISECOND, @c0, SYSDATETIME());
PRINT 'C (con UDF) elapsed (ms): ' + CONVERT(VARCHAR(20), @ms_c);
GO

/* ---------- E) MISMO gather con REPLACE inline (sin UDF) ---------- */
PRINT '';
PRINT '=== E) INSERT con REPLACE inline (sin UDF) ===';
IF OBJECT_ID('tempdb..#E') IS NOT NULL DROP TABLE #E;
CREATE TABLE #E (ID INT, SERV_HTML VARCHAR(MAX), ANALISTA VARCHAR(320));
DECLARE @e0 DATETIME2 = SYSDATETIME();
INSERT INTO #E (ID, SERV_HTML, ANALISTA)
SELECT P.ID,
    ISNULL((SELECT ' ' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(PS.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')
     FROM dbo.VCT_PROYECTOS_SERVICIOS XS JOIN dbo.VCT_PRM_SERVICIOS PS ON PS.ID = XS.ID_SERVICIO
     WHERE XS.ID_PROYECTO = P.ID FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), ''),
    (SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'') + CASE WHEN ISNULL(E.NOMBRES,'')<>'' THEN ', '+E.NOMBRES ELSE '' END)),''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')
     FROM dbo.VCT_PROYECTOS_EQUIPO EQ
     JOIN dbo.VCT_EMPLEADOS E ON E.ID = EQ.ID_EMPLEADO
     JOIN dbo.VCT_PRM_PROYECTOS_ROLES R ON R.ID = EQ.ID_ROL
     WHERE EQ.ID_PROYECTO = P.ID AND R.CODIGO = 'ANALISTA' AND ISNULL(EQ.ESTADO,'ACTIVO')='ACTIVO')
FROM dbo.VCT_PROYECTOS P;
DECLARE @ms_e INT = DATEDIFF(MILLISECOND, @e0, SYSDATETIME());
PRINT 'E (inline REPLACE) elapsed (ms): ' + CONVERT(VARCHAR(20), @ms_e);
GO

IF OBJECT_ID('tempdb..#C') IS NOT NULL DROP TABLE #C;
IF OBJECT_ID('tempdb..#E') IS NOT NULL DROP TABLE #E;
:OUT stdout
PRINT 'DIAG completo.';
GO
