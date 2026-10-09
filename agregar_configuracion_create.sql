/* =============================================================================
   Falta CONFIGURACION.CREATE — la spec de VCT_MAIN_CONFIGURACION V1 lo pide
   explícitamente ("Permisos esperados") pero solo migramos EDIT/VIEW desde
   PARAMETRIA.EDIT/VIEW (nunca existió un PARAMETRIA.CREATE). Sin esta acción,
   el botón "Nuevo template" no se renderiza para ningún perfil.
   ============================================================================= */

USE MuhlePROD;
GO

-- 1) Actions
INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, IdPadre, Tipo)
SELECT 'CONFIGURACION.CREATE', N'Crear configuración', NEWID(), GETDATE(), NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM dbo.Actions WHERE Id = 'CONFIGURACION.CREATE');

-- 2) PrmActions — mismo patrón que EMPLEADOS.CREATE (icon 'plus', coincide
--    con @BUTTON_ICON='plus' que ya usa el SP para este botón).
--    De paso reordeno EDIT/VIEW a 2/3 para que quede CREATE=1, EDIT=2, VIEW=3
--    (mismo orden que CLIENTES/EMPLEADOS).
INSERT INTO dbo.PrmActions (ActionID, ActionType, Title, Icon, KeyField, StorageKey, TargetTab, SortOrder, TargetGuid, SideBarId)
SELECT 'CONFIGURACION.CREATE', 'CREATE', 'Alta Configuración', 'plus', 'Clave', 'IDSELEC01', 'form', 1, NULL, '11'
WHERE NOT EXISTS (SELECT 1 FROM dbo.PrmActions WHERE ActionID = 'CONFIGURACION.CREATE');

UPDATE dbo.PrmActions SET SortOrder = 2 WHERE ActionID = 'CONFIGURACION.EDIT';
UPDATE dbo.PrmActions SET SortOrder = 3 WHERE ActionID = 'CONFIGURACION.VIEW';

-- 3) GroupsActions — otorgar a GERENCIA, igual que EDIT/VIEW
INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
SELECT 'GERENCIA', 'CONFIGURACION.CREATE', NEWID(), GETDATE()
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.GroupsActions
    WHERE GroupId = 'GERENCIA' AND ActionId = 'CONFIGURACION.CREATE'
);

-- Verificación
SELECT * FROM dbo.Actions WHERE Id LIKE 'CONFIGURACION.%';
SELECT * FROM dbo.PrmActions WHERE ActionID LIKE 'CONFIGURACION.%' ORDER BY SortOrder;
SELECT * FROM dbo.GroupsActions WHERE GroupId = 'GERENCIA' AND ActionId LIKE 'CONFIGURACION.%';
