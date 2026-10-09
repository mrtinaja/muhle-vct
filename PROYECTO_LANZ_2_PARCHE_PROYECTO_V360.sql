/* ========================================================================
   PROYECTO_LANZ_2_PARCHE_PROYECTO_V360
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_PROYECTO_V360
   (no pisa nada mas). Correr DESPUES de PROYECTO_LANZ_1_INSTALACION.sql y
   de subir vct-proyecto-lanz.js / vct-proyecto-lanz.css.
     - Procesa las acciones del analista (dbo.VCT_PROYECTO_LANZ_ACCION).
     - Agrega la seccion "Lanzamiento" arriba de "Ultimas gestiones".
     - Formularios de la seccion en OUTPARAM3.
     - Carga vct-datepicker y vct-proyecto-lanz.
   Si algun fragmento no se encuentra, NO aplica nada y avisa.
   Si ya fue aplicado (marca LANZAMIENTO_V1), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
DECLARE @s INT, @b INT, @mk NVARCHAR(MAX), @n NVARCHAR(MAX);

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_PROYECTO_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'LANZAMIENTO_V1',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_PROYECTO_V360 ya tenia la seccion de lanzamiento. No se hizo nada.';
    RETURN;
END;

IF OBJECT_ID('dbo.VCT_PROYECTO_LANZ_RENDER') IS NULL OR OBJECT_ID('dbo.VCT_PROYECTO_LANZ_ACCION') IS NULL
BEGIN
    RAISERROR('Faltan los SP del lanzamiento: correr antes PROYECTO_LANZ_1_INSTALACION.sql. No se aplico nada.',16,1);
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'SET NOCOUNT ON; /* MIGRADO_DG: grilla de gestiones con el motor vct-datagrid */'),
 (N'-- vct_main_proyecto_v360.css'),
 (N'<span data-vct-icon="clock-3"></span></span>'),
 (N'<script src="../js/vct-datagrid.js?v=3"></script>');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

/* ---- 1. marca + variables ---- */
SET @D = REPLACE(@D, N'SET NOCOUNT ON; /* MIGRADO_DG: grilla de gestiones con el motor vct-datagrid */', N'SET NOCOUNT ON; /* MIGRADO_DG: grilla de gestiones con el motor vct-datagrid */
DECLARE @LANZ_MSG VARCHAR(1000)='''', @LANZ_ERR VARCHAR(1000)='''', @HTML_LANZ VARCHAR(MAX)='''', @HTML_LANZ_FORMS VARCHAR(MAX)=''''; /* LANZAMIENTO_V1 */');

/* ---- 2. acciones + render, antes de armar el HTML ---- */
SET @mk = N'-- vct_main_proyecto_v360.css';
SET @s = CHARINDEX(@mk, @D) + LEN(@mk);
SET @n = N'

/* LANZAMIENTO_V1: acciones del analista (equipo, datos de entrada,
   consideraciones, reunion, inicio) y seccion "Lanzamiento". */
BEGIN TRY
    EXEC dbo.VCT_PROYECTO_LANZ_ACCION
         @IPKEYJOB=@IPKEYJOB, @IUNIDAD=@IUNIDAD, @IAGENTE=@IAGENTE, @ID_PROYECTO=@ID_PROYECTO,
         @MENSAJE=@LANZ_MSG OUTPUT, @ERROR=@LANZ_ERR OUTPUT;
END TRY
BEGIN CATCH
    SET @LANZ_ERR=LEFT(ERROR_MESSAGE(),1000);
END CATCH;

/* el inicio del proyecto cambia el estado del encabezado */
SELECT @ESTADO=ISNULL(E.DESCRIPCION,'''')
FROM dbo.VCT_PROYECTOS P
LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E ON E.ID=P.ID_ESTADO
WHERE P.ID=@ID_PROYECTO;

BEGIN TRY
    EXEC dbo.VCT_PROYECTO_LANZ_RENDER
         @ID_PROYECTO=@ID_PROYECTO, @IUNIDAD=@IUNIDAD, @MENSAJE=@LANZ_MSG, @ERROR=@LANZ_ERR,
         @HTML=@HTML_LANZ OUTPUT, @FORMS=@HTML_LANZ_FORMS OUTPUT;
END TRY
BEGIN CATCH
    SET @HTML_LANZ=''<div class="vct-lanz-alert is-error">No se pudo armar la seccion de lanzamiento: ''+dbo.VCT_HTML_ESC(ERROR_MESSAGE())+''</div>'';
    SET @HTML_LANZ_FORMS='''';
END CATCH;
';
SET @D = STUFF(@D, @s, 0, @n);

/* ---- 3. seccion: antes de la caja "Ultimas gestiones" ---- */
SET @s = CHARINDEX(N'<span data-vct-icon="clock-3"></span></span>', @D);
SET @b = @s - CHARINDEX(REVERSE(N'<div class="vct-360-box">'), REVERSE(LEFT(@D, @s - 1))) - LEN(N'<div class="vct-360-box">') + 1;
IF @b <= 0 OR SUBSTRING(@D, @b, LEN(N'<div class="vct-360-box">')) <> N'<div class="vct-360-box">'
BEGIN
    RAISERROR('No se encontro la caja de Ultimas gestiones. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @b, 0, N'''+ISNULL(@HTML_LANZ,'''')+''' + NCHAR(10));

/* ---- 4. assets ---- */
SET @D = REPLACE(@D, N'<script src="../js/vct-datagrid.js?v=3"></script>', N'<script src="../js/vct-datagrid.js?v=3"></script><link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-lanz.css?v=2"><script src="../js/vct-proyecto-lanz.js?v=2"></script>');

/* ---- 5. OUTPARAM3 (la ultima asignacion) ---- */
SET @mk = N'SET @OUTPARAM3='''';';
SET @s = DATALENGTH(@D)/2 - CHARINDEX(REVERSE(@mk), REVERSE(@D)) - LEN(@mk) + 2;
IF @s <= 0 OR SUBSTRING(@D, @s, LEN(@mk)) <> @mk
BEGIN
    RAISERROR('No se encontro la asignacion final de OUTPARAM3. No se aplico nada.',16,1);
    RETURN;
END;
SET @D = STUFF(@D, @s, LEN(@mk), N'SET @OUTPARAM3=ISNULL(@HTML_LANZ_FORMS,'''');');

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
PRINT 'OK: VCT_MAIN_PROYECTO_V360 con la seccion de lanzamiento.';
GO
