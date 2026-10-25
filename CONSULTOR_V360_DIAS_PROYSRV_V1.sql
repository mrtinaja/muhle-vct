/* ============================================================================
   CONSULTOR_V360_DIAS_PROYSRV_V1
   ----------------------------------------------------------------------------
   El tooltip del calendario en la Vista 360 de Consultor NO muestra proyecto /
   servicios, cuando si andan en la Agenda del consultor. Causa: el JSON de dias
   del V360 (@V360_AGC_DIAS) se arma SIN las claves "proy"/"srv".

   Este parche calca en dbo.VCT_MAIN_CONSULTORES_V360 el mismo enriquecimiento
   que ya tiene dbo.VCT_MAIN_AGENDA_CONSULTOR (marca TOOLTIP_DIAS_PROYSRV_V1):
     1) agrega un OUTER APPLY PX (visita asignada a ese consultor ese dia ->
        proyecto + servicios, set-based, con los mismos joins y filtros);
     2) agrega "proy" y "srv" al objeto-dia del JSON.
   El render JS ya sabe mostrarlos (dayTip -> actTip -> data-tt-proy/srv).

   Tecnica: construye las anclas con CHAR(39) (sin doblar comillas) y hace STUFF/
   REPLACE sobre la definicion viva; CREATE->ALTER. Falla-seguro: si no encuentra
   una ancla, RAISERROR y NO cambia nada. Re-ejecutable: si ya esta (PX.PROY), avisa.
   Compat 100 y 140.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @Q CHAR(1) = CHAR(39), @NL NVARCHAR(2) = CHAR(13)+CHAR(10);
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'));
DECLARE @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT;

IF @D IS NULL BEGIN RAISERROR('No existe dbo.VCT_MAIN_CONSULTORES_V360.',16,1); RETURN; END;
IF CHARINDEX(N'PX.PROY', @D) > 0
BEGIN PRINT 'CONSULTOR_V360_DIAS_PROYSRV_V1 ya aplicado (PX.PROY presente). Sin cambios.'; RETURN; END;

/* cola comun de escape de los campos de texto del JSON: ),'\','/'),'"',''''),CHAR(10),' ') */
DECLARE @ESCTAIL NVARCHAR(200) =
    N')'+N','+@Q+N'\'+@Q+N','+@Q+N'/'+@Q+N')'+N','+@Q+N'"'+@Q+N','+@Q+@Q+@Q+@Q+N')'+N',CHAR(10),'+@Q+N' '+@Q+N')';

/* ---- 1) agregar "proy"/"srv" al objeto-dia (anclado en el campo "de" de R.DESCRIPCION) ---- */
DECLARE @S1 NVARCHAR(400) = N'ISNULL(R.DESCRIPCION,'+@Q+@Q+@ESCTAIL+N'+'+@Q+N'"}'+@Q;
DECLARE @R1 NVARCHAR(MAX) =
      N'ISNULL(R.DESCRIPCION,'+@Q+@Q+@ESCTAIL
    + N'+'+@Q+N'","proy":"'+@Q+N'+REPLACE(REPLACE(REPLACE(ISNULL(PX.PROY,'+@Q+@Q+@ESCTAIL
    + N'+'+@Q+N'","srv":"'+@Q+N'+REPLACE(REPLACE(REPLACE(ISNULL(PX.SRV,'+@Q+@Q+@ESCTAIL
    + N'+'+@Q+N'"}'+@Q;

IF CHARINDEX(@S1, @D) = 0
BEGIN RAISERROR('Ancla de campos (R.DESCRIPCION ... "}") no encontrada. Sin cambios.',16,1); RETURN; END;
SET @D = REPLACE(@D, @S1, @R1);

/* ---- 2) agregar el OUTER APPLY PX (anclado en el ON del LEFT JOIN AG, sin comillas) ---- */
DECLARE @S2 NVARCHAR(200) = N'ON AG.ID_CONSULTOR=@ID_CONSULTOR AND AG.FECHA=R.FECHA';
DECLARE @PX NVARCHAR(MAX) =
      @NL + N'            OUTER APPLY ('
    + @NL + N'                SELECT TOP 1'
    + @NL + N'                    ISNULL('+@Q+N'('+@Q+N'+NULLIF(LTRIM(RTRIM(P2.CODIGO)),'+@Q+@Q+N')+'+@Q+N') '+@Q+N','+@Q+@Q+N')+ISNULL(P2.NOMBRE,'+@Q+@Q+N') AS PROY,'
    + @NL + N'                    ISNULL(STUFF((SELECT '+@Q+N', '+@Q+N'+UPPER(LEFT(ISNULL(S2.CODIGO,'+@Q+@Q+N'),2))+'+@Q+N'|'+@Q+N'+CONVERT(VARCHAR(200),S2.DESCRIPCION)'
    + @NL + N'                        FROM dbo.VCT_PROYECTOS_SERVICIOS PS2 WITH(NOLOCK)'
    + @NL + N'                        INNER JOIN dbo.VCT_PRM_SERVICIOS S2 WITH(NOLOCK) ON S2.ID=PS2.ID_SERVICIO'
    + @NL + N'                        WHERE PS2.ID_PROYECTO=V2.ID_PROYECTO'
    + @NL + N'                        ORDER BY S2.ID'
    + @NL + N'                        FOR XML PATH('+@Q+@Q+N'),TYPE).value('+@Q+N'.'+@Q+N','+@Q+N'VARCHAR(MAX)'+@Q+N'),1,2,'+@Q+@Q+N'),'+@Q+@Q+N') AS SRV'
    + @NL + N'                FROM dbo.VCT_PROYECTOS_VISITAS V2 WITH(NOLOCK)'
    + @NL + N'                INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC2 WITH(NOLOCK) ON VC2.ID_VISITA=V2.ID AND VC2.ID_CONSULTOR=@ID_CONSULTOR'
    + @NL + N'                LEFT JOIN dbo.VCT_PROYECTOS P2 WITH(NOLOCK) ON P2.ID=V2.ID_PROYECTO'
    + @NL + N'                WHERE R.FECHA BETWEEN CONVERT(DATE,V2.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V2.FECHA_HASTA,V2.FECHA_DESDE))'
    + @NL + N'                  AND ISNULL(V2.ESTADO,'+@Q+@Q+N') NOT IN ('+@Q+N'CANCELADO'+@Q+N','+@Q+N'CANCELADA'+@Q+N','+@Q+N'ANULADO'+@Q+N','+@Q+N'ANULADA'+@Q+N')'
    + @NL + N'                ORDER BY V2.FECHA_DESDE DESC'
    + @NL + N'            ) PX';

IF CHARINDEX(@S2, @D) = 0
BEGIN RAISERROR('Ancla del LEFT JOIN AG (ON AG.ID_CONSULTOR=@ID_CONSULTOR AND AG.FECHA=R.FECHA) no encontrada. Sin cambios.',16,1); RETURN; END;
SET @D = REPLACE(@D, @S2, @S2 + @PX);

/* ---- verificacion minima: ambos cambios presentes ---- */
IF CHARINDEX(N'PX.PROY', @D) = 0 OR CHARINDEX(N'OUTER APPLY (', @D) = 0
BEGIN RAISERROR('Post-REPLACE no quedo coherente. Sin cambios.',16,1); RETURN; END;

/* ---- CREATE [OR ALTER] ... -> ALTER (mismo metodo que CONSULTOR_V360_TOOLTIP_V1) ---- */
SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
WHILE 1 = 1
BEGIN
    SET @cp = CHARINDEX(N'CREATE', @up, @scan);
    IF @cp = 0 BREAK;
    SET @probe = CHARINDEX(N'PROC', @up, @cp);
    IF @probe > 0 AND @probe <= @cp + 40 BREAK;
    SET @scan = @cp + 6;
END;
IF @cp = 0 BEGIN RAISERROR('No se identifico la cabecera CREATE PROC. Sin cambios.',16,1); RETURN; END;
IF SUBSTRING(@up, @cp, 15) = N'CREATE OR ALTER' SET @D = STUFF(@D, @cp, 15, N'ALTER');
ELSE SET @D = STUFF(@D, @cp, 6, N'ALTER');

BEGIN TRY
    EXEC sys.sp_executesql @D;
    PRINT 'OK: CONSULTOR_V360_DIAS_PROYSRV_V1 aplicado (proy/srv en los dias del calendario del V360 consultor).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado al recrear el SP: %s',16,1,@e);
END CATCH;
GO
