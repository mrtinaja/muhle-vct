/* ========================================================================
   DIAG_ANALISTA - SOLO LECTURA. No modifica nada.
   Para disenar la pantalla del analista (lanzamiento del proyecto):
     1. columnas de las tablas de documentos, planes y consultores
     2. catalogo de documentos (VCT_PRM_DOCUMENTOS) y sus items
     3. preguntas de la minuta de gestion del sistema anterior
        (distintas DESC/GRUPO por tipo de documento en LK_PROYECTO_DOCUM_DET)
   Uso: ejecutar y copiar TODA la columna "linea" de Results.
   Ademas: en la pestana Messages imprime la definicion de
   VCT_MAIN_PROYECTO_V360 (copiar Messages entero tambien).
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#O') IS NOT NULL DROP TABLE #O;
CREATE TABLE #O (id INT IDENTITY(1,1) PRIMARY KEY, linea NVARCHAR(MAX));

/* ---------- 1. columnas ---------- */
INSERT #O(linea) VALUES (N'=== 1. COLUMNAS ===');
INSERT #O(linea)
SELECT t.name + N' (' + CONVERT(NVARCHAR(20),(SELECT SUM(p.rows) FROM sys.partitions p WHERE p.object_id=t.object_id AND p.index_id IN (0,1))) + N') | '
     + ISNULL(STUFF((
         SELECT N', ' + c.name + N' ' + ty.name
              + CASE WHEN ty.name IN (N'varchar',N'char') THEN N'(' + CASE WHEN c.max_length=-1 THEN N'MAX' ELSE CONVERT(NVARCHAR(10),c.max_length) END + N')' ELSE N'' END
              + CASE WHEN c.is_nullable=1 THEN N' NULL' ELSE N'' END
         FROM sys.columns c INNER JOIN sys.types ty ON ty.user_type_id=c.user_type_id
         WHERE c.object_id=t.object_id ORDER BY c.column_id
         FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,N''),N'')
FROM sys.tables t
WHERE t.name LIKE N'VCT[_]PRM[_]DOCUMENTO%'
   OR t.name LIKE N'VCT[_]PROYECTOS[_]DOCUMENTO%'
   OR t.name LIKE N'VCT[_]PROYECTOS[_]PLAN%'
   OR t.name LIKE N'VCT[_]CONSULTORES[_]%'
   OR t.name LIKE N'VCT[_]EVENTOS%'
   OR t.name LIKE N'LK[_]DOCUMENT%'
   OR t.name LIKE N'%MINUTA%'
ORDER BY t.name;

/* ---------- 2. catalogo de documentos ---------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 2. VCT_PRM_DOCUMENTOS (JSON) ===');
IF OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS') IS NOT NULL
    EXEC (N'INSERT #O(linea) SELECT ISNULL((SELECT * FROM dbo.VCT_PRM_DOCUMENTOS FOR JSON PATH),N''(vacia)'')');
IF OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_SERVICIOS') IS NOT NULL
    EXEC (N'INSERT #O(linea) SELECT N''VCT_PRM_DOCUMENTOS_SERVICIOS | '' + ISNULL((SELECT * FROM dbo.VCT_PRM_DOCUMENTOS_SERVICIOS FOR JSON PATH),N''(vacia)'')');

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 2b. VCT_PRM_DOCUMENTOS_ITEMS: cantidad por documento y primeros 80 de cada uno ===');
IF OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_ITEMS') IS NOT NULL
BEGIN
    DECLARE @col NVARCHAR(200) = (SELECT TOP 1 c.name FROM sys.columns c WHERE c.object_id=OBJECT_ID('dbo.VCT_PRM_DOCUMENTOS_ITEMS') AND c.name LIKE N'ID[_]DOCUMENTO%');
    IF @col IS NOT NULL
        EXEC (N'INSERT #O(linea) SELECT N''DOC '' + CONVERT(NVARCHAR(20),' + @col + N') + N'' | items='' + CONVERT(NVARCHAR(20),COUNT(*)) FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS GROUP BY ' + @col + N' ORDER BY ' + @col + N';'
            + N'INSERT #O(linea) SELECT N''ITEMS | '' + ISNULL((SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY ' + @col + N' ORDER BY ID) RN FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS) X WHERE RN<=80 FOR JSON PATH),N''(vacia)'')');
    ELSE
        EXEC (N'INSERT #O(linea) SELECT N''ITEMS | '' + ISNULL((SELECT TOP 300 * FROM dbo.VCT_PRM_DOCUMENTOS_ITEMS FOR JSON PATH),N''(vacia)'')');
END;

/* ---------- 3. preguntas de la minuta del sistema anterior ---------- */
INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 3. LK_PROYECTO_DOCUM_DET: preguntas distintas por ID_DOCUMENTACION / TIPO (doc | tipo | grupo | orden | pregunta | veces) ===');
IF OBJECT_ID('dbo.LK_PROYECTO_DOCUM_DET') IS NOT NULL
    INSERT #O(linea)
    SELECT CONVERT(NVARCHAR(20),ISNULL(D.ID_DOCUMENTACION,-1)) + N' | ' + ISNULL(D.TIPO,N'-') + N' | '
         + ISNULL(T.GRUPO_DOC_DET,N'-') + N' | ' + CONVERT(NVARCHAR(20),ISNULL(MIN(T.ORDEN),0)) + N' | '
         + LEFT(ISNULL(T.DESC_DOC_DET,N''),300) + N' | ' + CONVERT(NVARCHAR(20),COUNT(*))
    FROM dbo.LK_PROYECTO_DOCUM_DET T WITH(NOLOCK)
    INNER JOIN dbo.LK_PROYECTO_DOCUM D WITH(NOLOCK) ON D.ID_PROYECTO_DOCUM = T.ID_PROYECTO_DOCUM
    GROUP BY D.ID_DOCUMENTACION, D.TIPO, T.GRUPO_DOC_DET, T.DESC_DOC_DET
    ORDER BY D.ID_DOCUMENTACION, D.TIPO, MIN(T.ORDEN), T.GRUPO_DOC_DET;

INSERT #O(linea) VALUES (N'');
INSERT #O(linea) VALUES (N'=== 3b. Documentos del sistema anterior por ID_DOCUMENTACION / TIPO (cantidad, ultimo) ===');
IF OBJECT_ID('dbo.LK_PROYECTO_DOCUM') IS NOT NULL
    INSERT #O(linea)
    SELECT CONVERT(NVARCHAR(20),ISNULL(ID_DOCUMENTACION,-1)) + N' | ' + ISNULL(TIPO,N'-') + N' | ' + CONVERT(NVARCHAR(20),COUNT(*))
         + N' | ' + ISNULL(MAX(NRO_DOCUM_INTERNO),N'')
    FROM dbo.LK_PROYECTO_DOCUM WITH(NOLOCK)
    GROUP BY ID_DOCUMENTACION, TIPO
    ORDER BY ID_DOCUMENTACION, TIPO;

SELECT linea FROM #O ORDER BY id;
GO

/* ---------- definicion de VCT_MAIN_PROYECTO_V360 (pestana Messages) ---------- */
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @TOTAL INT = DATALENGTH(@D) / 2, @P INT = 1, @E INT, @LINE NVARCHAR(MAX);
PRINT N'===== dbo.VCT_MAIN_PROYECTO_V360 =====';
WHILE @P <= @TOTAL
BEGIN
    SET @E = CHARINDEX(NCHAR(10), @D, @P);
    IF @E = 0 SET @E = @TOTAL + 1;
    SET @LINE = SUBSTRING(@D, @P, @E - @P);
    IF DATALENGTH(@LINE) > 0 AND RIGHT(@LINE, 1) = NCHAR(13)
        SET @LINE = SUBSTRING(@LINE, 1, (DATALENGTH(@LINE) / 2) - 1);
    WHILE (DATALENGTH(@LINE) / 2) > 4000
    BEGIN
        PRINT SUBSTRING(@LINE, 1, 4000);
        SET @LINE = SUBSTRING(@LINE, 4001, 1000000);
    END;
    PRINT @LINE;
    SET @P = @E + 1;
END;
GO
