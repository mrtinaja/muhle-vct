/* =============================================================================
   PrmActions: CONFIGURACION.EDIT / CONFIGURACION.VIEW
   -----------------------------------------------------------------------------
   Patrón calcado de EMPLEADOS.CREATE/EDIT (única convención confirmada que
   existe hoy en la tabla). SideBarId='11' = fila de Configuración en Sidebar.

   Sin un ejemplo real de "VIEW sin Vista 360", CONFIGURACION.VIEW quedó
   armado igual que EDIT (TargetTab='form', sin TargetGuid) — ajustar si el
   comportamiento real de la pantalla necesita otra cosa.
   ============================================================================= */

USE MuhlePROD;
GO

INSERT INTO dbo.PrmActions (ActionID, ActionType, Title, Icon, KeyField, StorageKey, TargetTab, SortOrder, TargetGuid, SideBarId)
SELECT 'CONFIGURACION.EDIT', 'EDIT', 'Administrar Configuración', 'edit', 'Clave', 'IDSELEC01', 'form', 1, NULL, '11'
WHERE NOT EXISTS (SELECT 1 FROM dbo.PrmActions WHERE ActionID = 'CONFIGURACION.EDIT');

INSERT INTO dbo.PrmActions (ActionID, ActionType, Title, Icon, KeyField, StorageKey, TargetTab, SortOrder, TargetGuid, SideBarId)
SELECT 'CONFIGURACION.VIEW', 'VIEW', 'Ver Configuración', 'eye', 'Clave', 'IDSELEC01', 'form', 2, NULL, '11'
WHERE NOT EXISTS (SELECT 1 FROM dbo.PrmActions WHERE ActionID = 'CONFIGURACION.VIEW');

-- Verificación
SELECT * FROM dbo.PrmActions WHERE ActionID LIKE 'CONFIGURACION.%';
