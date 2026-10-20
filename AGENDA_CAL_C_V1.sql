/* ============================================================================
   AGENDA_CAL_C_V1
   ----------------------------------------------------------------------------
   Agenda del consultor: reparto de las horas ASIGNADAS del dia entre visitas
   CONFIRMADAS y PENDIENTES, para pintar la celda con la franja partida
   (verde confirmado / amarillo pendiente / azul lo que sigue disponible).

   Cambio minimo sobre dbo.VCT_MAIN_AGENDA_CONSULTOR (definicion viva):
     - el JSON de dias (data-vct-agc-dias) suma dos campos por dia:
         "hcf": horas asignadas confirmadas (visita ESTADO = CONFIRMADO o con horas registradas)
         "hpe": horas asignadas pendientes  (resto de las visitas del dia)
       mismo calculo que dbo.VCT_FN_AGENDA_CONSULTOR_RANGO (registradas, o planificadas
       prorrateadas por los dias de la visita). "hc" (capacidad cargada) ya venia.
   NO cambia la funcion, ni permisos, ni el resto del JSON. El JS (vct-calendario v35)
   hace: disponible restante = hc - (hcf + hpe) cuando el dia estaba cargado como DISPONIBLE.

   Re-ejecutable: si ya esta aplicado (marca AGENDA_CAL_C_V1) avisa y no hace nada.
   Correr ANTES de FIX_CALENDARIO_BUMP_V35.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR')),
        @NL NCHAR(1) = NCHAR(10), @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT = 1;

IF @D IS NULL BEGIN RAISERROR('No se encontro dbo.VCT_MAIN_AGENDA_CONSULTOR.',16,1); RETURN; END;
IF CHARINDEX(N'AGENDA_CAL_C_V1', @D) > 0 BEGIN PRINT 'AGENDA_CAL_C_V1 ya aplicado. No se hace nada.'; RETURN; END;

SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), @NL);

/* Las anclas se buscan sin depender de espacios ni saltos de linea (la definicion viva puede
   diferir del archivo del repo):
     1) FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@CONS_ID ...  -> el SELECT del JSON de dias
     2) el ultimo '"}' antes de ese FROM                      -> cierre de cada objeto del JSON
     3) el primer ORDER BY R.FECHA despues de ese FROM        -> ahi se agrega el OUTER APPLY */
DECLARE @pF INT, @pC INT, @pO INT, @CIERRE NVARCHAR(10) = N'''"}''', @AP NVARCHAR(MAX);
SET @pF = CHARINDEX(N'FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@CONS_ID', @D);
IF @pF = 0 BEGIN RAISERROR('No se encontro FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@CONS_ID ... en el SP. Se cancela.',16,1); RETURN; END;
SET @pC = CHARINDEX(REVERSE(@CIERRE), REVERSE(LEFT(@D, @pF - 1)));
IF @pC = 0 BEGIN RAISERROR('No se encontro el cierre ''"}'' del JSON de dias antes del FROM. Se cancela.',16,1); RETURN; END;
SET @pC = (@pF - 1) - (CHARINDEX(REVERSE(@CIERRE), REVERSE(LEFT(@D, @pF - 1))) - 1) - LEN(@CIERRE) + 1;
IF SUBSTRING(@D, @pC, LEN(@CIERRE)) <> @CIERRE BEGIN RAISERROR('No se pudo ubicar el cierre del JSON de dias. Se cancela.',16,1); RETURN; END;
SET @pO = CHARINDEX(N'ORDER BY R.FECHA', @D, @pF);
IF @pO = 0 BEGIN RAISERROR('No se encontro ORDER BY R.FECHA despues del FROM. Se cancela.',16,1); RETURN; END;

SET @AP = N'/* AGENDA_CAL_C_V1: confirmada = ESTADO CONFIRMADO o con horas registradas ese dia */' + @NL
    + N'            OUTER APPLY (' + @NL
    + N'                SELECT SUM(CASE WHEN X.CONF = 1 THEN X.H ELSE 0 END) AS HCF,' + @NL
    + N'                       SUM(CASE WHEN X.CONF = 0 THEN X.H ELSE 0 END) AS HPE' + @NL
    + N'                FROM (' + @NL
    + N'                    SELECT CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(HVV.ESTADO,'''')))) = ''CONFIRMADO'' OR RG.H IS NOT NULL THEN 1 ELSE 0 END AS CONF,' + @NL
    + N'                           CONVERT(DECIMAL(9,2), ISNULL(RG.H, ISNULL(HVC.HORAS_PLANIFICADAS,0)' + @NL
    + N'                               / NULLIF(COALESCE(NULLIF(HVV.DIAS,0), DATEDIFF(DAY, CONVERT(DATE,HVV.FECHA_DESDE), CONVERT(DATE,ISNULL(HVV.FECHA_HASTA,HVV.FECHA_DESDE))) + 1), 0))) AS H' + @NL
    + N'                    FROM dbo.VCT_PROYECTOS_VISITAS HVV WITH(NOLOCK)' + @NL
    + N'                    INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES HVC WITH(NOLOCK) ON HVC.ID_VISITA = HVV.ID AND HVC.ID_CONSULTOR = @CONS_ID' + @NL
    + N'                    OUTER APPLY (SELECT SUM(CONVERT(DECIMAL(9,2), ISNULL(RR.HORAS,0))) AS H FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO RR WITH(NOLOCK)' + @NL
    + N'                                 WHERE RR.ID_VISITA = HVV.ID AND RR.ID_CONSULTOR = @CONS_ID AND RR.FECHA = R.FECHA) RG' + @NL
    + N'                    WHERE R.FECHA BETWEEN CONVERT(DATE,HVV.FECHA_DESDE) AND CONVERT(DATE,ISNULL(HVV.FECHA_HASTA,HVV.FECHA_DESDE))' + @NL
    + N'                ) X' + @NL
    + N'            ) HV' + @NL + N'            ';

/* primero el OUTER APPLY (esta despues), despues el cierre (esta antes): no se corren las posiciones */
SET @D = STUFF(@D, @pO, 0, @AP);
SET @D = STUFF(@D, @pC, LEN(@CIERRE),
      N'''","hcf":'' + CONVERT(VARCHAR(12), CONVERT(DECIMAL(9,2), ISNULL(HV.HCF,0)))'
    + N' + '',"hpe":'' + CONVERT(VARCHAR(12), CONVERT(DECIMAL(9,2), ISNULL(HV.HPE,0)))'
    + N' + ''}''   /* AGENDA_CAL_C_V1 */');

/* ---- CREATE [OR ALTER] ... -> ALTER ---- */
SET @up = UPPER(@D); SET @cp = 0;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC. Se cancela.',16,1); RETURN; END;
IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: AGENDA_CAL_C_V1 aplicado (JSON de dias con hcf / hpe).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado (no se modifico nada): %s',16,1,@e);
END CATCH;
GO
