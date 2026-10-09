-- Ajustar el USE a la base donde vive PrmActions (la del panel admin /
-- "Sistema de Seguridad" -- probablemente NO es MuhlePROD, que es la base
-- del portal principal). Corre esto en esa base.
-- USE [NombreDeLaBaseDelPanelAdmin]
-- GO

-- Verificacion previa: confirmar que no exista ya (por las dudas)
SELECT * FROM dbo.PrmActions WHERE ActionID='CONFIGURACION.DELETE';

-- Alta de la accion, mismo patron que las otras 3 de Configuracion
-- (Id 10/11/12: EDIT/VIEW/CREATE), SideBarId=11 igual que esas.
INSERT INTO dbo.PrmActions
(
    ActionID, ActionType, Title, Icon, KeyField, StorageKey,
    TargetTab, SortOrder, TargetGuid, SideBarId
)
VALUES
(
    'CONFIGURACION.DELETE',   -- ActionID
    'DELETE',                 -- ActionType
    'Eliminar Configuración', -- Title
    'trash-2',                -- Icon
    'Clave',                  -- KeyField
    'IDSELEC01',               -- StorageKey
    NULL,                      -- TargetTab (no abre form, es una accion inline)
    4,                         -- SortOrder (despues de CREATE=1, EDIT=2, VIEW=3)
    NULL,                      -- TargetGuid
    11                         -- SideBarId (Configuracion)
);

-- Verificacion posterior
SELECT * FROM dbo.PrmActions WHERE ActionID='CONFIGURACION.DELETE';
