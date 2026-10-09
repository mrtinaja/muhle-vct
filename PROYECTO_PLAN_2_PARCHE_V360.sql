/* ========================================================================
   PROYECTO_PLAN_2_PARCHE_V360  (v2: anclas tolerantes a espacios)
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_PROYECTO_V360.
   Correr DESPUES de PROYECTO_PLAN_1_INSTALACION.sql y de subir
   vct-proyecto-plan.js / vct-proyecto-plan.css. Requiere los parches
   LANZ_2 (lanzamiento), LANZ_3 (stepper) y LANZ_4 (avance).
     - Procesa las acciones del plan (antes de calcular el avance).
     - Agrega la seccion "Plan Estrategico" arriba del lanzamiento.
     - Oculta la caja vieja "Plan Estrategico" (solo listaba items).
     - Carga vct-proyecto-plan.
   Si algun fragmento no se encuentra, NO aplica nada y avisa cuales.
   Si ya fue aplicado (marca PLAN_V1), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT, @b INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'PLAN_V1',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360 ya tenia el Plan Estrategico. No se hizo nada.';
    RETURN;
END;

IF OBJECT_ID('dbo.VCT_PROYECTO_PLAN_RENDER') IS NULL OR OBJECT_ID('dbo.VCT_PROYECTO_PLAN_ACCION') IS NULL
BEGIN
    RAISERROR('Faltan los SP del plan: correr antes PROYECTO_PLAN_1_INSTALACION.sql. No se aplico nada.',16,1);
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'LANZAMIENTO_V1 */'),
 (N'/* AVANCE_V1: avance calculado'),
 (N'@FORMS=@HTML_LANZ_FORMS OUTPUT;'),
 (N'<span data-vct-icon="list-checks"></span></span>Plan Estrat'),
 (N'<script src="../js/vct-proyecto-lanz.js?v=2"></script>');

DECLARE @bad NVARCHAR(2000) = N'';
SELECT @bad = @bad + N' [' + mk + N'] x' + CONVERT(NVARCHAR(10), (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0))
FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad <> N''
BEGIN
    DECLARE @msg NVARCHAR(2100) = N'Fragmentos no encontrados o repetidos (veces):' + @bad + N'. No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

/* ---- 1. variables, despues de la marca del lanzamiento ---- */
SET @s = CHARINDEX(N'LANZAMIENTO_V1 */', @D) + LEN(N'LANZAMIENTO_V1 */');
SET @D = STUFF(@D, @s, 0, N'
DECLARE @PLAN_MSG VARCHAR(1000)='''', @PLAN_ERR VARCHAR(1000)='''', @HTML_PLAN VARCHAR(MAX)='''', @HTML_PLAN_FORMS VARCHAR(MAX)=''''; /* PLAN_V1 */');

/* ---- 2. acciones del plan, antes del avance ---- */
SET @s = CHARINDEX(N'/* AVANCE_V1: avance calculado', @D);
SET @D = STUFF(@D, @s, 0, N'/* PLAN_V1: acciones del Plan Estrategico (antes del avance) */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_PLAN_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@PLAN_MSG OUTPUT, @ERROR=@PLAN_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @PLAN_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;

');

/* ---- 3. render del plan: despues del END CATCH del render del lanzamiento ---- */
SET @s = CHARINDEX(N'@FORMS=@HTML_LANZ_FORMS OUTPUT;', @D);
SET @b = CHARINDEX(N'END CATCH;', @D, @s);
IF @b = 0
BEGIN
    RAISERROR('No se encontro el cierre del render del lanzamiento. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @b + LEN(N'END CATCH;'), 0, N'

/* PLAN_V1: seccion Plan Estrategico, arriba del lanzamiento */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_PLAN_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@PLAN_MSG, @ERROR=@PLAN_ERR,
         @HTML=@HTML_PLAN OUTPUT, @FORMS=@HTML_PLAN_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_PLAN=''<div class="vct-lanz-alert is-error">No se pudo armar el Plan Estrategico: ''+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+''</div>'';
    SET @HTML_PLAN_FORMS='''';
END CATCH;
SET @HTML_LANZ=ISNULL(@HTML_PLAN,'''')+ISNULL(@HTML_LANZ,'''');
SET @HTML_LANZ_FORMS=ISNULL(@HTML_LANZ_FORMS,'''')+ISNULL(@HTML_PLAN_FORMS,'''');');

/* ---- 4. ocultar la caja vieja del plan ---- */
SET @s = CHARINDEX(N'<span data-vct-icon="list-checks"></span></span>Plan Estrat', @D);
SET @b = @s - CHARINDEX(REVERSE(N'<div class="vct-360-box">'), REVERSE(LEFT(@D, @s - 1))) - LEN(N'<div class="vct-360-box">') + 1;
IF @b <= 0 OR SUBSTRING(@D, @b, LEN(N'<div class="vct-360-box">')) <> N'<div class="vct-360-box">'
BEGIN
    RAISERROR('No se encontro la caja vieja del Plan Estrategico. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @b, LEN(N'<div class="vct-360-box">'), N'<div class="vct-360-box" style="display:none!important" data-vct-plan-old>');

/* ---- 5. assets ---- */
SET @D = REPLACE(@D, N'<script src="../js/vct-proyecto-lanz.js?v=2"></script>', N'<script src="../js/vct-proyecto-lanz.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-plan.css?v=1"><script src="../js/vct-proyecto-plan.js?v=1"></script>');

/* ---- CREATE -> ALTER en el encabezado ---- */
DECLARE @p INT = CHARINDEX(N'PROCEDURE', @D), @pre NVARCHAR(60);
IF @p > 0
BEGIN
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
END;

IF PATINDEX(N'%ALTER%PROC%', @D) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTO_V360 con el Plan Estrategico.';
GO
