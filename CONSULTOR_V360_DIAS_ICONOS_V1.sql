/* ============================================================================
   !!! NO USAR — DIO TIMEOUT. Supersedido por CONSULTOR_V360_DIAS_ICONOS_REVERT.
   Este patch AGREGABA la llamada a la funcion SIN sacar el bloque inline, con
   lo cual los ~450 dias se calculaban dos veces y la Vista 360 hacia timeout.
   Se deja como referencia historica. El enfoque bueno sera enriquecer el bloque
   inline del V360 en una sola pasada (pendiente).
   ============================================================================
   CONSULTOR_V360_DIAS_ICONOS_V1
   ----------------------------------------------------------------------------
   El calendario de la Vista 360 del consultor ahora manda, por dia asignado,
   cliente / proyecto / servicio(s) -> el tooltip muestra los iconos de servicio
   (igual que Acciones y la Agenda del consultor). Hasta ahora @V360_AGC_DIAS no
   traia esos campos, por eso el tooltip del dia no tenia iconos.

   Cambio minimo sobre dbo.VCT_MAIN_CONSULTORES_V360: justo antes de escapar
   @V360_AGC_DIAS para el atributo HTML, se reemplaza su contenido por el JSON
   enriquecido de dbo.VCT_FN_AGENDA_DIAS_JSON (misma fuente que la Agenda del
   consultor). No cambia contrato, permisos (sigue can-edit=0) ni la logica.

   REQUIERE: dbo.VCT_FN_AGENDA_DIAS_JSON ya creada (VCT_FN_AGENDA_DIAS_JSON.sql).
   Re-ejecutable: si ya esta aplicado (menciona VCT_FN_AGENDA_DIAS_JSON) avisa y
   no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

IF OBJECT_ID('dbo.VCT_FN_AGENDA_DIAS_JSON') IS NULL
BEGIN RAISERROR('Falta dbo.VCT_FN_AGENDA_DIAS_JSON. Corre primero VCT_FN_AGENDA_DIAS_JSON.sql.',16,1); RETURN; END;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360')),
        @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT = 1;

IF @D IS NULL BEGIN RAISERROR('No se encontro dbo.VCT_MAIN_CONSULTORES_V360.',16,1); RETURN; END;

IF CHARINDEX(N'VCT_FN_AGENDA_DIAS_JSON', @D) > 0
BEGIN PRINT 'CONSULTOR_V360_DIAS_ICONOS_V1 ya aplicado. No se hace nada.'; RETURN; END;

/* ---- inyectar la reasignacion justo ANTES de escapar @V360_AGC_DIAS ----
   Ancla: la linea que escapa el JSON para el atributo HTML (es unica). */
IF CHARINDEX(N'SET @V360_AGC_DIAS = REPLACE(REPLACE(REPLACE(@V360_AGC_DIAS,''&'',''&amp;'')', @D) = 0
BEGIN RAISERROR('No se encontro la linea de escape de @V360_AGC_DIAS. Se cancela.',16,1); RETURN; END;

SET @D = REPLACE(@D,
    N'SET @V360_AGC_DIAS = REPLACE(REPLACE(REPLACE(@V360_AGC_DIAS,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;'');',
    N'/* DIAS_ICONOS_V1: dias con cliente/proyecto/servicio (iconos en el tooltip) */
    IF @ID_CONSULTOR > 0 SET @V360_AGC_DIAS = dbo.VCT_FN_AGENDA_DIAS_JSON(@ID_CONSULTOR,@V360_AGC_DESDE,@V360_AGC_HASTA);
    SET @V360_AGC_DIAS = REPLACE(REPLACE(REPLACE(@V360_AGC_DIAS,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;'');');

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
    PRINT 'OK: CONSULTOR_V360_DIAS_ICONOS_V1 aplicado (dias con servicio/proyecto -> iconos en el tooltip del calendario del V360).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado: %s',16,1,@e);
END CATCH;
GO
