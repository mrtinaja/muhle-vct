/* ============================================================================
   VISITAS_HORAS_DIA_1  (28/10/2026)  marca VIS_HD_V1
   ----------------------------------------------------------------------------
   Visitas: horas manuales por consultor y por dia (opcion B del boceto).
   1. Tabla nueva dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS (visita, consultor, fecha, horas).
      VCT_PROYECTOS_VISITAS_CONSULTORES.HORAS_PLANIFICADAS sigue siendo el total (= suma de los dias).
      Las visitas ya cargadas NO se tocan: sin detalle por dia siguen repartidas parejo hasta que se editen.
   2. dbo.VCT_MAIN_PROYECTO_V360 (modal Nueva / Editar visita y pestania Visitas):
      - Graba las horas de cada dia; la disponibilidad se valida dia por dia.
      - Al editar, trae las horas de cada dia.
      - Horas ejecutadas de una visita en curso: las de los dias anteriores a hoy.
      - Leyenda de la agenda compacta (badges).
      - Assets: vct-proyecto-v360.css ?v=55 y vct-proyecto-v360.js ?v=46 (subir los dos).
   3. dbo.VCT_FN_AGENDA_CONSULTOR_RANGO (agenda del consultor en la V360 del proyecto, la del consultor y la
      pantalla Agenda): las horas planificadas de cada dia salen del detalle por dia; sin detalle, reparto parejo.
   4. dbo.VCT_MAIN_AGENDA_CONSULTOR (calendario de la Agenda): idem para las horas confirmadas / pendientes.
   SSMS: F5. Re-ejecutable. Si algun punto no se encuentra, ese SP no cambia.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
/* ---------- 1. tabla de horas por dia (si no existe) ---------- */
IF OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS (
        ID            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VCT_PVC_DIAS PRIMARY KEY,
        ID_VISITA     INT NOT NULL CONSTRAINT FK_VCT_PVC_DIAS_VISITA REFERENCES dbo.VCT_PROYECTOS_VISITAS (ID) ON DELETE CASCADE,
        ID_CONSULTOR  INT NOT NULL CONSTRAINT FK_VCT_PVC_DIAS_CONS REFERENCES dbo.VCT_CONSULTORES (ID),
        FECHA         DATE NOT NULL,
        HORAS         NUMERIC(9,2) NOT NULL,
        FECHA_ALTA    DATETIME NOT NULL CONSTRAINT DF_VCT_PVC_DIAS_FA DEFAULT (GETDATE()),
        USUARIO_ALTA  VARCHAR(100) NULL,
        CONSTRAINT UQ_VCT_PVC_DIAS UNIQUE (ID_VISITA, ID_CONSULTOR, FECHA)
    );
    PRINT 'OK   tabla dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS creada.';
END
ELSE PRINT 'OK   la tabla dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS ya existia.';
GO

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'VIS_HD_V1', @D) > 0
    PRINT 'OK   el parche VIS_HD_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'DES_GRID_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes DESARROLLO_GRILLA_1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* t23_decl */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T21 VARCHAR(4000) = '''', @AG_T22 VARCHAR(4000) = '''';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T21 VARCHAR(4000) = '''', @AG_T22 VARCHAR(4000) = '''', @AG_T23 VARCHAR(MAX) = '''';   /* VIS_HD_V1: TEXTO23 horas por dia */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t23_decl'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t23_read */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T22 = LTRIM(RTRIM(ISNULL(TEXTO22,'''')))' + NCHAR(10) + N'        FROM dbo.VCT_BUFFER';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'@AG_T22 = LTRIM(RTRIM(ISNULL(TEXTO22,''''))), @AG_T23 = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(MAX), TEXTO23),'''')))' + NCHAR(10) + N'        FROM dbo.VCT_BUFFER';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t23_read'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* t23_clean */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'TEXTO21 = NULL, TEXTO22 = NULL' + NCHAR(10) + N'        WHERE PAR_KEY = @IPKEYJOB;' + NCHAR(10) + N'        SET @VOLVER = ''agenda'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'TEXTO21 = NULL, TEXTO22 = NULL, TEXTO23 = NULL' + NCHAR(10) + N'        WHERE PAR_KEY = @IPKEYJOB;' + NCHAR(10) + N'        SET @VOLVER = ''agenda'';';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' t23_clean'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* agd_decl */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'        DECLARE @AGN TABLE (ID_NORMA INT);' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'        DECLARE @AGN TABLE (ID_NORMA INT);' + NCHAR(10) + N'        DECLARE @AGD TABLE (CONS INT, FECHA DATE, HORAS NUMERIC(9,2));   /* VIS_HD_V1: horas por consultor y por dia */' + NCHAR(10) + N'        DECLARE @AG_L2 VARCHAR(MAX), @AG_P2 INT, @AG_PAR2 VARCHAR(100), @AG_Q2 INT, @AG_FD VARCHAR(20), @AG_HD VARCHAR(20);' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' agd_decl'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* agd_parse */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'            IF @AG_DES IS NULL SET @ERR = ''Fecha desde es obligatoria.''' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'            /* VIS_HD_V1: horas por dia "id:aaaa-mm-dd=h|aaaa-mm-dd=h;id:..." (manuales); el total del consultor pasa a ser la suma */' + NCHAR(10) + N'            SET @AG_L = @AG_T23 + '';'';' + NCHAR(10) + N'            SET @AG_P = CHARINDEX('';'', @AG_L);' + NCHAR(10) + N'            WHILE @AG_P > 0' + NCHAR(10) + N'            BEGIN' + NCHAR(10) + N'                SET @AG_PAR = LTRIM(RTRIM(LEFT(@AG_L, @AG_P - 1)));' + NCHAR(10) + N'                SET @AG_L = SUBSTRING(@AG_L, @AG_P + 1, 2000000);' + NCHAR(10) + N'                SET @AG_Q = CHARINDEX('':'', @AG_PAR);' + NCHAR(10) + N'                SET @AG_A = CASE WHEN @AG_Q > 1 THEN LTRIM(RTRIM(LEFT(@AG_PAR, @AG_Q - 1))) ELSE '''' END;' + NCHAR(10) + N'                IF @AG_A <> '''' AND PATINDEX(''%[^0-9]%'', @AG_A) = 0 AND LEN(@AG_A) <= 9 AND EXISTS (SELECT 1 FROM @AGC WHERE CONS = CONVERT(INT, @AG_A))' + NCHAR(10) + N'                BEGIN' + NCHAR(10) + N'                    SET @AG_L2 = SUBSTRING(@AG_PAR, @AG_Q + 1, 4000) + ''|'';' + NCHAR(10) + N'                    SET @AG_P2 = CHARINDEX(''|'', @AG_L2);' + NCHAR(10) + N'                    WHILE @AG_P2 > 0' + NCHAR(10) + N'                    BEGIN' + NCHAR(10) + N'                        SET @AG_PAR2 = LTRIM(RTRIM(LEFT(@AG_L2, @AG_P2 - 1)));' + NCHAR(10) + N'                        SET @AG_L2 = SUBSTRING(@AG_L2, @AG_P2 + 1, 4000);' + NCHAR(10) + N'                        SET @AG_Q2 = CHARINDEX(''='', @AG_PAR2);' + NCHAR(10) + N'                        IF @AG_Q2 = 11' + NCHAR(10) + N'                        BEGIN' + NCHAR(10) + N'                            SET @AG_FD = LEFT(@AG_PAR2, 10);' + NCHAR(10) + N'                            SET @AG_HD = REPLACE(LTRIM(RTRIM(SUBSTRING(@AG_PAR2, 12, 20))), '','', ''.'');' + NCHAR(10) + N'                            IF @AG_FD LIKE ''[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]'' AND ISDATE(REPLACE(@AG_FD,''-'','''')) = 1' + NCHAR(10) + N'                               AND @AG_HD <> '''' AND @AG_HD <> ''.'' AND PATINDEX(''%[^0-9.]%'', @AG_HD) = 0 AND @AG_HD NOT LIKE ''%.%.%'' AND LEN(@AG_HD) <= 6' + NCHAR(10) + N'                               AND CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112) BETWEEN CONVERT(DATE, @AG_DES) AND CONVERT(DATE, @AG_HAS)' + NCHAR(10) + N'                               AND CONVERT(NUMERIC(9,2), @AG_HD) > 0' + NCHAR(10) + N'                               AND NOT EXISTS (SELECT 1 FROM @AGD WHERE CONS = CONVERT(INT, @AG_A) AND FECHA = CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112))' + NCHAR(10) + N'                                INSERT INTO @AGD (CONS, FECHA, HORAS) VALUES (CONVERT(INT, @AG_A), CONVERT(DATE, REPLACE(@AG_FD,''-'',''''), 112), CONVERT(NUMERIC(9,2), @AG_HD));' + NCHAR(10) + N'                        END;' + NCHAR(10) + N'                        SET @AG_P2 = CHARINDEX(''|'', @AG_L2);' + NCHAR(10) + N'                    END;' + NCHAR(10) + N'                END;' + NCHAR(10) + N'                SET @AG_P = CHARINDEX('';'', @AG_L);' + NCHAR(10) + N'            END;' + NCHAR(10) + N'            UPDATE C SET HORAS = X.S FROM @AGC C CROSS APPLY (SELECT SUM(D.HORAS) AS S FROM @AGD D WHERE D.CONS = C.CONS) X WHERE X.S IS NOT NULL;' + NCHAR(10) + NCHAR(10) + N'            IF @AG_DES IS NULL SET @ERR = ''Fecha desde es obligatoria.''' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' agd_parse'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* agd_val8 */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                FROM @AGC WHERE HORAS <= 0 OR HORAS > @AG_DIAS * 8 ORDER BY ORD;' + NCHAR(10) + N'            END;' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                FROM @AGC WHERE HORAS <= 0 OR HORAS > @AG_DIAS * 8 ORDER BY ORD;' + NCHAR(10) + N'            END' + NCHAR(10) + N'            ELSE IF EXISTS (SELECT 1 FROM @AGD WHERE HORAS > 8)   /* VIS_HD_V1 */' + NCHAR(10) + N'                SELECT TOP 1 @ERR = ''Horas de '' + C.NOM + '' el '' + CONVERT(VARCHAR(10), D.FECHA, 103) + '': hasta 8 por d'' + CHAR(237) + ''a.''' + NCHAR(10) + N'                FROM @AGD D INNER JOIN @AGC C ON C.CONS = D.CONS WHERE D.HORAS > 8 ORDER BY C.ORD, D.FECHA;' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' agd_val8'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_msg */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''; la visita pide '' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,1), C.HORAS / @AG_DIAS)) + '' h por d'' + CHAR(237) + ''a).''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'+ ''; la visita pide '' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,1), NE.H)) + '' h ese d'' + CHAR(237) + ''a).''   /* VIS_HD_V1 */';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_msg'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_own */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                OUTER APPLY (SELECT SUM(ISNULL(VC.HORAS_PLANIFICADAS, 0) / NULLIF(COALESCE(NULLIF(V.DIAS, 0), DATEDIFF(DAY, V.FECHA_DESDE, ISNULL(V.FECHA_HASTA, V.FECHA_DESDE)) + 1), 0)) AS H' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                OUTER APPLY (SELECT SUM(CASE WHEN OD.N > 0 THEN ISNULL(OH.H, 0) ELSE ISNULL(VC.HORAS_PLANIFICADAS, 0) / NULLIF(COALESCE(NULLIF(V.DIAS, 0), DATEDIFF(DAY, V.FECHA_DESDE, ISNULL(V.FECHA_HASTA, V.FECHA_DESDE)) + 1), 0) END) AS H' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_own'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_own_ap */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                             WHERE V.ID = @AG_ID AND R.FECHA BETWEEN CONVERT(DATE, V.FECHA_DESDE) AND CONVERT(DATE, ISNULL(V.FECHA_HASTA, V.FECHA_DESDE))) OWN';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                             OUTER APPLY (SELECT COUNT(*) AS N FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS DZ WITH(NOLOCK) WHERE DZ.ID_VISITA = V.ID AND DZ.ID_CONSULTOR = VC.ID_CONSULTOR) OD' + NCHAR(10) + N'                             OUTER APPLY (SELECT SUM(DZ.HORAS) AS H FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS DZ WITH(NOLOCK) WHERE DZ.ID_VISITA = V.ID AND DZ.ID_CONSULTOR = VC.ID_CONSULTOR AND DZ.FECHA = R.FECHA) OH' + NCHAR(10) + N'                             WHERE V.ID = @AG_ID AND R.FECHA BETWEEN CONVERT(DATE, V.FECHA_DESDE) AND CONVERT(DATE, ISNULL(V.FECHA_HASTA, V.FECHA_DESDE))) OWN';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_own_ap'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* disp_need */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                WHERE X.LIBRE + 0.05 < C.HORAS / @AG_DIAS' + NCHAR(10) + N'                ORDER BY C.ORD, R.FECHA;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                OUTER APPLY (SELECT TOP 1 D1.HORAS FROM @AGD D1 WHERE D1.CONS = C.CONS AND D1.FECHA = R.FECHA) DD' + NCHAR(10) + N'                CROSS APPLY (SELECT CASE WHEN EXISTS (SELECT 1 FROM @AGD D0 WHERE D0.CONS = C.CONS) THEN ISNULL(DD.HORAS, 0) ELSE C.HORAS / @AG_DIAS END AS H) NE' + NCHAR(10) + N'                WHERE NE.H > 0 AND X.LIBRE + 0.05 < NE.H' + NCHAR(10) + N'                ORDER BY C.ORD, R.FECHA;';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' disp_need'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* save_dias */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                    /* normas de la visita (en la edicion se cargan una sola vez, con el primer consultor) */' + NCHAR(10);
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                    /* VIS_HD_V1: horas por dia del consultor (sin detalle: se reparte el total parejo, como antes) */' + NCHAR(10) + N'                    DELETE FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS WHERE ID_VISITA = @AG_VID AND ID_CONSULTOR = @AG_C;' + NCHAR(10) + N'                    INSERT INTO dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS (ID_VISITA, ID_CONSULTOR, FECHA, HORAS, FECHA_ALTA, USUARIO_ALTA)' + NCHAR(10) + N'                    SELECT @AG_VID, @AG_C, D.FECHA, D.HORAS, GETDATE(), @IAGENTE FROM @AGD D WHERE D.CONS = @AG_C;' + NCHAR(10) + N'                    /* normas de la visita (en la edicion se cargan una sola vez, con el primer consultor) */' + NCHAR(10);
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' save_dias'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* save_quitados */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                    DELETE VC FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC' + NCHAR(10) + N'                    WHERE VC.ID_VISITA = @AG_ID AND NOT EXISTS (SELECT 1 FROM @AGC C WHERE C.CONS = VC.ID_CONSULTOR);';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                    DELETE D FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WHERE D.ID_VISITA = @AG_ID AND NOT EXISTS (SELECT 1 FROM @AGC C WHERE C.CONS = D.ID_CONSULTOR);   /* VIS_HD_V1 */' + NCHAR(10) + N'                    DELETE VC FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC' + NCHAR(10) + N'                    WHERE VC.ID_VISITA = @AG_ID AND NOT EXISTS (SELECT 1 FROM @AGC C WHERE C.CONS = VC.ID_CONSULTOR);';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' save_quitados'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* borrar_dias */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'                DELETE FROM dbo.VCT_PROYECTOS_VISITAS_NORMAS WHERE ID_VISITA = @AG_ID;' + NCHAR(10) + N'                DELETE FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE ID_VISITA = @AG_ID;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'                DELETE FROM dbo.VCT_PROYECTOS_VISITAS_NORMAS WHERE ID_VISITA = @AG_ID;' + NCHAR(10) + N'                DELETE FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS WHERE ID_VISITA = @AG_ID;   /* VIS_HD_V1 */' + NCHAR(10) + N'                DELETE FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES WHERE ID_VISITA = @AG_ID;';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' borrar_dias'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* edit_dh */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'data-cons="'' + A.CONS + ''"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'data-cons="'' + A.CONS + ''" data-dh="'' + ISNULL(STUFF((SELECT '';'' + CONVERT(VARCHAR(20), VC.ID_CONSULTOR) + '':'' + ISNULL(STUFF((SELECT ''|'' + CONVERT(VARCHAR(10), D.FECHA, 120) + ''='' + REPLACE(CONVERT(VARCHAR(20), CONVERT(DECIMAL(9,2), D.HORAS)), ''.00'', '''') FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WITH(NOLOCK) WHERE D.ID_VISITA = A.ID AND D.ID_CONSULTOR = VC.ID_CONSULTOR ORDER BY D.FECHA FOR XML PATH('''')), 1, 1, ''''), '''') FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) WHERE VC.ID_VISITA = A.ID AND EXISTS (SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WITH(NOLOCK) WHERE D.ID_VISITA = A.ID AND D.ID_CONSULTOR = VC.ID_CONSULTOR) FOR XML PATH('''')), 1, 1, ''''), '''') + ''"';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' edit_dh'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* he_x */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'    OUTER APPLY (SELECT SUM(ISNULL(VC.HORAS_PLANIFICADAS, 0)) AS P, SUM(ISNULL(VC.HORAS_EJECUTADAS, ISNULL(VC.HORAS_PLANIFICADAS, 0))) AS E' + NCHAR(10) + N'                 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) WHERE VC.ID_VISITA = A.ID) X;';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'    OUTER APPLY (SELECT SUM(ISNULL(VC.HORAS_PLANIFICADAS, 0)) AS P, SUM(ISNULL(VC.HORAS_EJECUTADAS, ISNULL(VC.HORAS_PLANIFICADAS, 0))) AS E' + NCHAR(10) + N'                 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK) WHERE VC.ID_VISITA = A.ID) X' + NCHAR(10) + N'    /* VIS_HD_V1: visita en curso: lo ejecutado son los dias anteriores a hoy (con detalle por dia, sus horas) */' + NCHAR(10) + N'    OUTER APPLY (SELECT SUM(CASE WHEN DX.N > 0 THEN ISNULL(DX.HP, 0) ELSE 0 END) AS PD, SUM(CASE WHEN ISNULL(DX.N, 0) = 0 THEN ISNULL(VC.HORAS_PLANIFICADAS, 0) ELSE 0 END) AS PS, SUM(DX.N) AS NR' + NCHAR(10) + N'                 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)' + NCHAR(10) + N'                 OUTER APPLY (SELECT COUNT(*) AS N, SUM(CASE WHEN D.FECHA < CONVERT(DATE, @HOY) THEN D.HORAS ELSE 0 END) AS HP FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WITH(NOLOCK)' + NCHAR(10) + N'                              WHERE D.ID_VISITA = VC.ID_VISITA AND D.ID_CONSULTOR = VC.ID_CONSULTOR) DX' + NCHAR(10) + N'                 WHERE VC.ID_VISITA = A.ID) XD;';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' he_x'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* he_case */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'WHEN A.NP = 0 THEN 0 ELSE ROUND(ISNULL(X.P, 0) * A.NP / A.ND, 1) END,';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'WHEN A.NP = 0 THEN 0 WHEN ISNULL(XD.NR, 0) > 0 THEN ROUND(ISNULL(XD.PD, 0) + ISNULL(XD.PS, 0) * A.NP / A.ND, 1) ELSE ROUND(ISNULL(X.P, 0) * A.NP / A.ND, 1) END,';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' he_case'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* leyenda */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'''<div class="vct-help">Agenda desde la fecha desde, 7 d&iacute;as seguidos; con borde bord&oacute;, los d&iacute;as de la visita. D = disponible y horas libres &middot; Asig = asignado &middot; ND = no disponible &middot; Oc = ocupado &middot; Pot = potencial &middot; Org = organismo &middot; Lic = licencia &middot; Fer = feriado &middot; &mdash; = no cargado. Horas: por defecto d&iacute;as &times; 8, m&aacute;ximo d&iacute;as &times; 8.</div>''';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'''<div class="vct-pv-ag-leg"><span class="vct-pv-ag-leg-t">Agenda 7 d&iacute;as desde la fecha desde &middot; borde bord&oacute; = d&iacute;as de la visita &middot; horas por d&iacute;a, a mano</span><span class="vct-pv-ag-lg is-d">D disponible</span><span class="vct-pv-ag-lg is-a">Asig asignado</span><span class="vct-pv-ag-lg is-o">ND / Oc</span><span class="vct-pv-ag-lg is-p">Pot</span><span class="vct-pv-ag-lg is-g">Org</span><span class="vct-pv-ag-lg is-l">Lic</span><span class="vct-pv-ag-lg is-f">Fer</span><span class="vct-pv-ag-lg is-n">&mdash; sin cargar</span></div>''';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' leyenda'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* assets */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=54"><script src="../js/vct-proyecto-v360.js?v=45"';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'vct-proyecto-v360.css?v=55"><script src="../js/vct-proyecto-v360.js?v=46"';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' assets'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    IF @F <> N''
        PRINT 'FALLO: no se encontraron (o estan repetidos) en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (VIS_HD_V1). Subir vct-proyecto-v360.css (v55) y vct-proyecto-v360.js (v46).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO

/* ---------- 3. dbo.VCT_FN_AGENDA_CONSULTOR_RANGO: horas planificadas por dia desde el detalle (si existe) ---------- */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_FN_AGENDA_CONSULTOR_RANGO')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_FN_AGENDA_CONSULTOR_RANGO.';
ELSE IF CHARINDEX(N'VIS_HD_V1', @D) > 0
    PRINT 'OK   el parche VIS_HD_V1 ya estaba aplicado: no se hizo nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* rg_case_a */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'CONVERT(DECIMAL(9,2), ISNULL(VC.HORAS_PLANIFICADAS,0))';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'/* VIS_HD_V1: con detalle por dia, las horas de ese dia */ CASE WHEN DD.N > 0 THEN CONVERT(DECIMAL(9,2), ISNULL(DH.H,0)) ELSE CONVERT(DECIMAL(9,2), ISNULL(VC.HORAS_PLANIFICADAS,0))';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' rg_case_a'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* rg_case_z */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'/ NULLIF(COALESCE(NULLIF(V.DIAS,0), DC.N), 0)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'/ NULLIF(COALESCE(NULLIF(V.DIAS,0), DC.N), 0) END';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' rg_case_z'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* rg_apply */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'c2.Fecha BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))) DC';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'c2.Fecha BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))) DC' + NCHAR(10) + N'        CROSS APPLY (SELECT COUNT(*) AS N FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WHERE D.ID_VISITA = V.ID AND D.ID_CONSULTOR = @ID_CONSULTOR) DD' + NCHAR(10) + N'        OUTER APPLY (SELECT SUM(D.HORAS) AS H FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS D WHERE D.ID_VISITA = V.ID AND D.ID_CONSULTOR = @ID_CONSULTOR AND D.FECHA = cal.Fecha) DH';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' rg_apply'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    IF @F <> N''
        PRINT 'FALLO: no se encontraron (o estan repetidos) en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'FUNCTION', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_FN_AGENDA_CONSULTOR_RANGO actualizada (VIS_HD_V1).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_FN_AGENDA_CONSULTOR_RANGO (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO

/* ---------- 4. dbo.VCT_MAIN_AGENDA_CONSULTOR: calendario con las horas por dia desde el detalle (si existe) ---------- */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR')), @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @i INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_AGENDA_CONSULTOR.';
ELSE IF CHARINDEX(N'VIS_HD_V1', @D) > 0
    PRINT 'OK   el parche VIS_HD_V1 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'AGENDA_CAL_C_V1', @D) = 0
    PRINT 'FALLO: falta aplicar antes AGENDA_CAL_C_V1.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* ag_case_a */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(RG.H, ISNULL(HVC.HORAS_PLANIFICADAS,0)';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'ISNULL(RG.H, CASE WHEN HDD.N > 0 THEN ISNULL(HDH.H,0) ELSE ISNULL(HVC.HORAS_PLANIFICADAS,0)';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_case_a'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ag_case_z */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'CONVERT(DATE,ISNULL(HVV.FECHA_HASTA,HVV.FECHA_DESDE))) + 1), 0))) AS H';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'CONVERT(DATE,ISNULL(HVV.FECHA_HASTA,HVV.FECHA_DESDE))) + 1), 0) END)) AS H';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_case_z'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    /* ag_apply */
    SET @NE = CONVERT(NVARCHAR(MAX), N'') + N'RR.FECHA = R.FECHA) RG';
    SET @RE = CONVERT(NVARCHAR(MAX), N'') + N'RR.FECHA = R.FECHA) RG' + NCHAR(10) + N'                    /* VIS_HD_V1: con detalle por dia, las horas de ese dia */' + NCHAR(10) + N'                    OUTER APPLY (SELECT COUNT(*) AS N FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS DD WITH(NOLOCK) WHERE DD.ID_VISITA = HVV.ID AND DD.ID_CONSULTOR = @CONS_ID) HDD' + NCHAR(10) + N'                    OUTER APPLY (SELECT SUM(DD.HORAS) AS H FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES_DIAS DD WITH(NOLOCK) WHERE DD.ID_VISITA = HVV.ID AND DD.ID_CONSULTOR = @CONS_ID AND DD.FECHA = R.FECHA) HDH';
    SET @i = CHARINDEX(@NE, @D);
    IF @i = 0 OR CHARINDEX(@NE, @D, @i + 1) > 0 SET @F = @F + N' ag_apply'; ELSE SET @D = STUFF(@D, @i, LEN(@NE + N'x') - 1, @RE);
    IF @F <> N''
        PRINT 'FALLO: no se encontraron (o estan repetidos) en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_AGENDA_CONSULTOR actualizado (VIS_HD_V1).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar dbo.VCT_MAIN_AGENDA_CONSULTOR (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
