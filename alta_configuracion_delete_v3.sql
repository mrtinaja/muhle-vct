-- Verificacion previa
SELECT * FROM dbo.Actions WHERE Id = 'CONFIGURACION.DELETE';

-- Alta de la accion en la tabla real que lee el panel admin.
-- Tipo='ACTION' igual que DOCUMENTOS.DELETE (el unico precedente de un
-- permiso de borrado en la tabla); IdPadre=NULL igual que sus hermanas
-- CONFIGURACION.CREATE/EDIT/VIEW.
INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, IdPadre, Tipo)
VALUES
(
    'CONFIGURACION.DELETE',
    'Eliminar configuración',
    NEWID(),
    GETDATE(),
    NULL,
    'ACTION'
);

-- Verificacion posterior
SELECT * FROM dbo.Actions WHERE Id = 'CONFIGURACION.DELETE';
