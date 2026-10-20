/* ============================================================================
   CLEANUP_VCT_MAIN_AGENDA
   ----------------------------------------------------------------------------
   dbo.VCT_MAIN_AGENDA es la VIEJA SP de la pantalla de feriados, renombrada a
   dbo.VCT_MAIN_CALENDARIO. Si quedo en el server es un objeto muerto.
   Este script la dropea SOLO si:
     - existe dbo.VCT_MAIN_AGENDA, y
     - existe dbo.VCT_MAIN_CALENDARIO (la nueva, para no quedarnos sin feriados), y
     - VCT_MAIN_AGENDA NO esta referenciada en el ruteo (STORED_PROCEDURES).
   Si falta alguna condicion, NO dropea y avisa.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

IF OBJECT_ID('dbo.VCT_MAIN_AGENDA','P') IS NULL
BEGIN
    PRINT 'dbo.VCT_MAIN_AGENDA no existe. Nada que limpiar.';
    RETURN;
END;

IF OBJECT_ID('dbo.VCT_MAIN_CALENDARIO','P') IS NULL
BEGIN
    PRINT 'OJO: no existe dbo.VCT_MAIN_CALENDARIO (la nueva). NO se dropea VCT_MAIN_AGENDA para no quedarte sin feriados.';
    RETURN;
END;

/* chequear que no este ruteada (por las dudas). Ajustar el nombre de la tabla de
   ruteo si en este ambiente es otra; si no existe, se asume no ruteada. */
IF OBJECT_ID('dbo.STORED_PROCEDURES') IS NOT NULL
   AND EXISTS (SELECT 1 FROM dbo.STORED_PROCEDURES
               WHERE UPPER(CONVERT(VARCHAR(200), [STORED_PROCEDURE])) LIKE '%VCT_MAIN_AGENDA%'
                 AND UPPER(CONVERT(VARCHAR(200), [STORED_PROCEDURE])) NOT LIKE '%VCT_MAIN_AGENDA_CONSULTOR%')
BEGIN
    PRINT 'OJO: dbo.VCT_MAIN_AGENDA figura en STORED_PROCEDURES (ruteo). Revisar antes de dropear. NO se dropeo.';
    RETURN;
END;

DROP PROCEDURE dbo.VCT_MAIN_AGENDA;
PRINT 'OK: dbo.VCT_MAIN_AGENDA (vieja, renombrada a VCT_MAIN_CALENDARIO) eliminada.';
GO
