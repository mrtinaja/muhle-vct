-- ============================================================
-- Alta de permiso AGENDA.VIEW -- mismo patron dual que se uso para
-- CONFIGURACION.DELETE (PrmActions la lee VCT_MAIN_GET_ACTIONS en la SP,
-- Actions la lee la Matriz de Permisos del panel admin).
-- ============================================================

-- Actions.AGENDA.VIEW ya quedo insertado en el intento anterior (el error
-- de "duplicate key" lo confirma) -- no hace falta volver a correr esa
-- parte, solo falta PrmActions.

-- 0) SideBarId confirmado: tabla de menu lateral (Id=8, Name='Calendario',
--    Code='AGENDA_GENERAL') -- coincide con "Agenda General" del
--    screenshot. El Id=9 (Code='AGENDA_CONSULTOR', Name='Agenda') queda
--    reservado para la futura pantalla de visitas de consultores, no se
--    usa aca.

-- 1) PrmActions -- la usa VCT_MAIN_GET_ACTIONS(@IUNIDAD,'AGENDA') dentro
--    de VCT_MAIN_AGENDA para habilitar/bloquear la pantalla.
--    Mismo patron que CONFIGURACION.VIEW (Icon='eye', KeyField='Clave',
--    StorageKey='IDSELEC01', SortOrder=3, TargetGuid=NULL). TargetTab
--    va en NULL (a diferencia de CONFIGURACION.VIEW que usa 'form')
--    porque Agenda no tiene formulario, es un calendario puro.
INSERT INTO dbo.PrmActions
    (ActionID,ActionType,Title,Icon,KeyField,StorageKey,TargetTab,SortOrder,TargetGuid,SideBarId)
VALUES
    ('AGENDA.VIEW','VIEW','Ver Agenda','eye','Clave','IDSELEC01',NULL,3,NULL,8);

-- 2) Verificacion
SELECT * FROM dbo.PrmActions WHERE ActionID='AGENDA.VIEW';
SELECT * FROM dbo.Actions WHERE Id='AGENDA.VIEW';
