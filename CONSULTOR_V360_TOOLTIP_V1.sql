/* ============================================================================
   CONSULTOR_V360_TOOLTIP_V1
   ----------------------------------------------------------------------------
   El calendario de la Vista 360 de Consultor (solo lectura) ahora muestra las
   ACTIVIDADES del consultor con el mismo tooltip-tarjeta que Acciones/Agenda
   (cliente -> proyecto -> iconos de servicio -> horario -> actividad). Hasta
   ahora solo pasaba la disponibilidad (data-vct-agc-dias), sin actividades.

   Cambio minimo sobre dbo.VCT_MAIN_CONSULTORES_V360:
     1) declara @V360_AGC_ACTS con dbo.VCT_FN_AGENDA_ACTS_JSON (misma fuente que
        la Agenda del consultor), escapado para atributo HTML;
     2) agrega data-vct-agc-acts al <div data-vct-agc-root> del calendario.
   NO cambia contrato, permisos (sigue can-edit=0), ni la disponibilidad.

   REQUIERE: dbo.VCT_FN_AGENDA_ACTS_JSON ya creada (VCT_FN_AGENDA_ACTS_JSON.sql).
   Re-ejecutable: si ya esta (marca data-vct-agc-acts) avisa y no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

IF OBJECT_ID('dbo.VCT_FN_AGENDA_ACTS_JSON') IS NULL
BEGIN RAISERROR('Falta dbo.VCT_FN_AGENDA_ACTS_JSON. Corre primero VCT_FN_AGENDA_ACTS_JSON.sql.',16,1); RETURN; END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360')),
        @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT = 1;

IF @D IS NULL BEGIN RAISERROR('No se encontro dbo.VCT_MAIN_CONSULTORES_V360.',16,1); RETURN; END;

IF CHARINDEX(N'data-vct-agc-acts', @D) > 0
BEGIN PRINT 'CONSULTOR_V360_TOOLTIP_V1 ya aplicado. No se hace nada.'; RETURN; END;

/* ---- 1) declarar @V360_AGC_ACTS justo despues del bloque de datos del calendario ---- */
IF CHARINDEX(N'/* V360_AGENDA_FIN_DATOS */', @D) = 0
BEGIN RAISERROR('No se encontro el ancla /* V360_AGENDA_FIN_DATOS */. Se cancela.',16,1); RETURN; END;
SET @D = REPLACE(@D,
    N'/* V360_AGENDA_FIN_DATOS */',
    N'/* TOOLTIP_V1: actividades del consultor para el tooltip del calendario */
    DECLARE @V360_AGC_ACTS VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(dbo.VCT_FN_AGENDA_ACTS_JSON(@ID_CONSULTOR,@V360_AGC_DESDE,@V360_AGC_HASTA),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;'');
    /* V360_AGENDA_FIN_DATOS */');

/* ---- 2) agregar data-vct-agc-acts al <div data-vct-agc-root> del calendario ---- */
IF CHARINDEX(N'data-vct-agc-dias="''+@V360_AGC_DIAS+''">', @D) = 0
BEGIN RAISERROR('No se encontro el tag data-vct-agc-dias del calendario V360. Se cancela.',16,1); RETURN; END;
SET @D = REPLACE(@D,
    N'data-vct-agc-dias="''+@V360_AGC_DIAS+''">',
    N'data-vct-agc-dias="''+@V360_AGC_DIAS+''" data-vct-agc-acts="''+@V360_AGC_ACTS+''">');

/* ---- CREATE [OR ALTER] ... -> ALTER ---- */
SET @up = UPPER(@D); SET @cp = 0; SET @scan = 1;
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
    PRINT 'OK: CONSULTOR_V360_TOOLTIP_V1 aplicado (actividades + tooltip en el calendario de V360 Consultor).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado: %s',16,1,@e);
END CATCH;
GO
