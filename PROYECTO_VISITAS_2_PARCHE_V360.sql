/* ========================================================================
   PROYECTO_VISITAS_2_PARCHE_V360
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_PROYECTO_V360.
   Correr DESPUES de PROYECTO_VISITAS_1_INSTALACION.sql y de subir
   vct-proyecto-visitas.js / vct-proyecto-visitas.css. Requiere el parche
   del Plan Estrategico (PLAN_V1).
     - Procesa el registro de visitas (comando VISITA_GUARDAR).
     - Agrega la seccion "Visitas y horas" debajo del Plan Estrategico.
     - KPI de la cabecera: "Visitas" (cantidad) pasa a "Horas usadas".
       Si ese KPI no se encuentra, sigue sin cambiarlo y avisa.
     - Carga vct-proyecto-visitas.
   Si algun fragmento obligatorio no se encuentra, NO aplica nada y avisa
   cuales. Si ya fue aplicado (marca VISITAS_V1), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT;

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'VISITAS_V1',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360 ya tenia las visitas. No se hizo nada.';
    RETURN;
END;

IF OBJECT_ID('dbo.VCT_PROYECTO_VISITA_RENDER') IS NULL OR OBJECT_ID('dbo.VCT_PROYECTO_VISITA_ACCION') IS NULL
BEGIN
    RAISERROR('Faltan los SP de visitas: correr antes PROYECTO_VISITAS_1_INSTALACION.sql. No se aplico nada.',16,1);
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'PLAN_V1 */'),
 (N'/* PLAN_V1: acciones del Plan Estrategico (antes del avance) */'),
 (N'SET @HTML_LANZ=ISNULL(@HTML_PLAN,'''')+ISNULL(@HTML_LANZ,'''');'),
 (N'SET @HTML_LANZ_FORMS=ISNULL(@HTML_LANZ_FORMS,'''')+ISNULL(@HTML_PLAN_FORMS,'''');'),
 (N'<script src="../js/vct-proyecto-plan.js?v=2"></script>');

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

/* ---- 1. variables, despues de las del plan ---- */
SET @s = CHARINDEX(N'PLAN_V1 */', @D) + LEN(N'PLAN_V1 */');
SET @D = STUFF(@D, @s, 0, N'
DECLARE @VIS_MSG VARCHAR(1000)='''', @VIS_ERR VARCHAR(1000)='''', @HTML_VIS VARCHAR(MAX)='''', @HTML_VIS_FORMS VARCHAR(MAX)=''''; /* VISITAS_V1 */');

/* ---- 2. registro de visitas, antes de las acciones del plan ---- */
SET @s = CHARINDEX(N'/* PLAN_V1: acciones del Plan Estrategico (antes del avance) */', @D);
SET @D = STUFF(@D, @s, 0, N'/* VISITAS_V1: registro de visitas */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_VISITA_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@VIS_MSG OUTPUT, @ERROR=@VIS_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @VIS_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;

');

/* ---- 3. render: plan + visitas + lanzamiento ---- */
SET @D = REPLACE(@D, N'SET @HTML_LANZ=ISNULL(@HTML_PLAN,'''')+ISNULL(@HTML_LANZ,'''');', N'/* VISITAS_V1: seccion Visitas y horas, debajo del plan */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_VISITA_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@VIS_MSG, @ERROR=@VIS_ERR,
         @HTML=@HTML_VIS OUTPUT, @FORMS=@HTML_VIS_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_VIS=''<div class="vct-lanz-alert is-error">No se pudo armar la seccion de visitas: ''+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+''</div>'';
    SET @HTML_VIS_FORMS='''';
END CATCH;
SET @HTML_LANZ=ISNULL(@HTML_PLAN,'''')+ISNULL(@HTML_VIS,'''')+ISNULL(@HTML_LANZ,'''');');

SET @D = REPLACE(@D, N'SET @HTML_LANZ_FORMS=ISNULL(@HTML_LANZ_FORMS,'''')+ISNULL(@HTML_PLAN_FORMS,'''');',
                     N'SET @HTML_LANZ_FORMS=ISNULL(@HTML_LANZ_FORMS,'''')+ISNULL(@HTML_PLAN_FORMS,'''')+ISNULL(@HTML_VIS_FORMS,'''');');

/* ---- 4. assets ---- */
SET @D = REPLACE(@D, N'<script src="../js/vct-proyecto-plan.js?v=2"></script>',
                     N'<script src="../js/vct-proyecto-plan.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-visitas.css?v=1"><script src="../js/vct-proyecto-visitas.js?v=1"></script>');

/* ---- 5. KPI de la cabecera (opcional) ---- */
DECLARE @K1 NVARCHAR(200) = N'<span class="vct-360-stat-label">Visitas</span>',
        @K2 NVARCHAR(200) = N'(SELECT COUNT(*) FROM dbo.VCT_PROYECTOS_VISITAS WHERE ID_PROYECTO=@ID_PROYECTO)';
IF (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @K1, N''))) / DATALENGTH(@K1) = 1
   AND (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @K2, N''))) / DATALENGTH(@K2) = 1
BEGIN
    SET @D = REPLACE(@D, @K1, N'<span class="vct-360-stat-label">Horas usadas</span>');
    SET @D = REPLACE(@D, @K2, N'dbo.VCT_PROYECTO_HORAS_USADAS_TXT(@ID_PROYECTO)');
    PRINT 'KPI de la cabecera: Visitas -> Horas usadas.';
END
ELSE
    PRINT 'AVISO: no se encontro el KPI "Visitas" de la cabecera; queda como estaba (el resto se aplica igual).';

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
PRINT 'OK: VCT_MAIN_PROYECTO_V360 con Visitas y horas.';
GO
