/* ============================================================================
   CONSULTOR_V360_CAL_ESTILOS_V1
   ----------------------------------------------------------------------------
   El calendario de la Vista 360 de Consultor usa el mismo motor que los demas
   calendarios (data-vct-agc-root + vct-calendario.js/css), pero emitia un
   toolbar RECORTADO (solo prev / titulo / next). Por eso se veia distinto al de
   la pantalla "Agenda del consultor" y al resto.

   Este parche reemplaza, SOLO dentro de dbo.VCT_MAIN_CONSULTORES_V360, ese
   toolbar minimo por el toolbar COMPLETO (identico al del resto de calendarios):
     - toggle de vista Mes / Semana / Dia (data-vct-agc-view)
     - navegacion prev / titulo / next
     - salto rapido de mes y anio (data-vct-agc-month / data-vct-agc-year),
       reutilizando @V360_AGC_YEARS que ya declara el SP
     - fila de KPIs de disponibilidad (data-vct-agc-stats)
   Las clases ya existen en vct-calendario.css (CSS compartido): no se toca
   ningun css/js ni ningun otro SP. Sigue siendo SOLO LECTURA (can-edit=0) y el
   consultor queda fijo (no se agrega el selector de consultor).

   Robusto al drift: ubica el bloque por anclas (CHARINDEX) y lo reemplaza con
   STUFF, sin depender de la indentacion. Re-ejecutable: si ya tiene el toggle
   (data-vct-agc-view-toggle) avisa y no hace nada.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360')),
        @up NVARCHAR(MAX), @cp INT, @probe INT, @scan INT,
        @A INT, @B INT;

IF @D IS NULL BEGIN RAISERROR('No se encontro dbo.VCT_MAIN_CONSULTORES_V360.',16,1); RETURN; END;

IF CHARINDEX(N'data-vct-agc-view-toggle', @D) > 0
BEGIN PRINT 'CONSULTOR_V360_CAL_ESTILOS_V1 ya aplicado. No se hace nada.'; RETURN; END;

/* ---- localizar el toolbar recortado del calendario (ancla de inicio y fin) ---- */
SET @A = CHARINDEX(N'<div class="vct-agenda-toolbar vct-agc-toolbar">', @D);
SET @B = CHARINDEX(N'<div class="vct-agenda-legend vct-agc-legend">', @D);

IF @A = 0 OR @B = 0 OR @B <= @A
BEGIN RAISERROR('No se ubico el toolbar del calendario V360 (anclas toolbar/legend). Se cancela.',16,1); RETURN; END;

/* ---- toolbar COMPLETO (igual al resto de calendarios; consultor fijo, solo lectura) ----
   El fragmento queda dentro del literal de @OUTPARAM2, por eso se rompe la
   comilla solo para concatenar @V360_AGC_YEARS (opciones de anio ya armadas). */
DECLARE @NEW NVARCHAR(MAX) =
    N'<div class="vct-agenda-toolbar vct-agc-toolbar">'
  + N'<div class="vct-agenda-view-toggle" data-vct-agc-view-toggle>'
  + N'<button type="button" class="vct-agenda-view-btn is-active" data-vct-agc-view="month">Mes</button>'
  + N'<button type="button" class="vct-agenda-view-btn" data-vct-agc-view="week">Semana</button>'
  + N'<button type="button" class="vct-agenda-view-btn" data-vct-agc-view="day">D&iacute;a</button>'
  + N'</div>'
  + N'<div class="vct-agenda-nav">'
  + N'<button type="button" class="vct-agenda-nav-btn" data-vct-agc-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>'
  + N'<h2 class="vct-agenda-title" data-vct-agc-title></h2>'
  + N'<button type="button" class="vct-agenda-nav-btn" data-vct-agc-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button>'
  + N'</div>'
  + N'<div class="vct-agenda-toolbar-right"><div class="vct-agenda-jump vct-agc-jump">'
  + N'<select class="vct-select vct-agc-sel-month" data-vct-agc-month aria-label="Mes">'
  + N'<option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option>'
  + N'<option value="4">Abril</option><option value="5">Mayo</option><option value="6">Junio</option>'
  + N'<option value="7">Julio</option><option value="8">Agosto</option><option value="9">Septiembre</option>'
  + N'<option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option>'
  + N'</select>'
  + N'<select class="vct-select vct-agc-sel-year" data-vct-agc-year aria-label="A&ntilde;o">''+@V360_AGC_YEARS+''</select>'
  + N'</div></div>'
  + N'</div>'
  + N'<div class="vct-soft-kpi-grid vct-agc-stats" data-vct-agc-stats></div>';

/* ---- reemplazo del span [toolbar, legend) ---- */
SET @D = STUFF(@D, @A, @B - @A, @NEW);

/* ---- CREATE [OR ALTER] ... -> ALTER (ancla en el CREATE real) ---- */
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
    PRINT 'OK: CONSULTOR_V360_CAL_ESTILOS_V1 aplicado (toolbar completo: vista + navegacion + salto + KPIs, como el resto de calendarios).';
END TRY
BEGIN CATCH
    DECLARE @e NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Cancelado: %s',16,1,@e);
END CATCH;
GO
