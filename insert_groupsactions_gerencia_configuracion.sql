/* =============================================================================
   Asigna CONFIGURACION.EDIT y CONFIGURACION.VIEW al perfil GERENCIA.
   ============================================================================= */

USE MuhlePROD;
GO

INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
SELECT 'GERENCIA', 'CONFIGURACION.EDIT', NEWID(), GETDATE()
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.GroupsActions
    WHERE GroupId = 'GERENCIA' AND ActionId = 'CONFIGURACION.EDIT'
);

INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
SELECT 'GERENCIA', 'CONFIGURACION.VIEW', NEWID(), GETDATE()
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.GroupsActions
    WHERE GroupId = 'GERENCIA' AND ActionId = 'CONFIGURACION.VIEW'
);

-- Verificación
SELECT GroupId, ActionId, rowguid, ModifiedDate
FROM dbo.GroupsActions
WHERE GroupId = 'GERENCIA' AND ActionId LIKE 'CONFIGURACION.%';
