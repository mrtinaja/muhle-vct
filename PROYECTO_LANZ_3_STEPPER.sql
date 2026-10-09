/* ========================================================================
   PROYECTO_LANZ_3_STEPPER
   ------------------------------------------------------------------------
   1. Vista 360 de Proyecto: carga vct-proyecto-lanz.js / .css v2 (stepper:
      barra 1-2-3-4 y un paso visible a la vez).
   2. Datos de entrada: "Codigo de propuesta" ya no se precarga con el
      codigo del proyecto; "Normas vigentes" se precarga con las normas.
   Correr DESPUES de subir vct-proyecto-lanz.js y vct-proyecto-lanz.css v2.
   Se puede volver a correr.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX), @p INT, @pre NVARCHAR(60), @s INT;

/* ---- 1. version de los assets en la Vista 360 de Proyecto ---- */
SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
IF CHARINDEX(N'vct-proyecto-lanz.js?v=1', @D) = 0
    PRINT 'VCT_MAIN_PROYECTO_V360: ya estaba en v2 (o no tiene la seccion). Sin cambios.';
ELSE
BEGIN
    SET @D = REPLACE(REPLACE(@D, N'vct-proyecto-lanz.js?v=1', N'vct-proyecto-lanz.js?v=2'),
                                 N'vct-proyecto-lanz.css?v=1', N'vct-proyecto-lanz.css?v=2');
    SET @p = CHARINDEX(N'PROCEDURE', @D);
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
    EXEC sp_executesql @D;
    PRINT 'OK: VCT_MAIN_PROYECTO_V360 carga vct-proyecto-lanz v2.';
END;

/* ---- 2. precarga de datos de entrada ---- */
SET @D = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_PROYECTO_LANZ_RENDER'));
IF CHARINDEX(N'NOT LIKE ''%propuesta%''', @D) > 0
    PRINT 'VCT_PROYECTO_LANZ_RENDER: la precarga ya estaba corregida. Sin cambios.';
ELSE IF (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, N'WHEN I.CAMPO = ''CODIGO'' THEN @CODIGO', N''))) / DATALENGTH(N'WHEN I.CAMPO = ''CODIGO'' THEN @CODIGO') <> 1
    RAISERROR('VCT_PROYECTO_LANZ_RENDER: no se encontro la linea de precarga del codigo. No se aplico.',16,1);
ELSE
BEGIN
    SET @D = REPLACE(@D, N'WHEN I.CAMPO = ''CODIGO'' THEN @CODIGO',
                         N'WHEN I.CAMPO = ''CODIGO'' AND I.DESCRIPCION NOT LIKE ''%propuesta%'' THEN @CODIGO'
                       + NCHAR(10) + N'                        WHEN I.DESCRIPCION LIKE ''Normas%'' THEN NULLIF(@NORMAS,'''')');
    SET @p = CHARINDEX(N'PROCEDURE', @D);
    SET @pre = SUBSTRING(@D, CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END, CASE WHEN @p > 40 THEN 40 ELSE @p - 1 END);
    IF CHARINDEX(N'CREATE', @pre) > 0 AND CHARINDEX(N'OR ALTER', @pre) = 0
    BEGIN
        SET @s = (CASE WHEN @p > 40 THEN @p - 40 ELSE 1 END) + CHARINDEX(N'CREATE', @pre) - 1;
        SET @D = STUFF(@D, @s, 6, N'ALTER ');
    END;
    EXEC sp_executesql @D;
    PRINT 'OK: VCT_PROYECTO_LANZ_RENDER con la precarga corregida.';
END;
GO
