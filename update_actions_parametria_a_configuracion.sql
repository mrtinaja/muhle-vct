/* =============================================================================
   Actions: PARAMETRIA.EDIT / PARAMETRIA.VIEW -> CONFIGURACION.EDIT / CONFIGURACION.VIEW
   -----------------------------------------------------------------------------
   Id es la PK natural referenciada por GroupsActions.ActionId (fuente real de
   autorización). Cambiar el Id de un permiso ya asignado a algún perfil rompe
   esa referencia si se hace con un UPDATE directo y no hay ON UPDATE CASCADE.

   Por eso el cambio se hace como INSERT (nuevo Id) -> UPDATE de los hijos en
   GroupsActions -> DELETE del Id viejo, todo en una transacción: en ningún
   momento queda un GroupsActions.ActionId apuntando a un Id que no existe.
   ============================================================================= */

USE MuhlePROD;
GO

/* -----------------------------------------------------------------------------
   PASO 1 - Ver el impacto real antes de tocar nada: qué perfiles tienen
   asignado hoy alguno de estos dos permisos.
   ----------------------------------------------------------------------------- */
SELECT ga.GroupId, ga.ActionId, g.Name AS Perfil
FROM dbo.GroupsActions ga
JOIN dbo.Groups g ON g.Id = ga.GroupId
WHERE ga.ActionId IN ('PARAMETRIA.EDIT', 'PARAMETRIA.VIEW');


/* -----------------------------------------------------------------------------
   PASO 2 - Migración segura dentro de una transacción.
   ----------------------------------------------------------------------------- */
BEGIN TRAN;

BEGIN TRY

    -- 2a. Crear los nuevos Actions con el Id/Name definitivos.
    INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, IdPadre, Tipo)
    SELECT 'CONFIGURACION.EDIT', N'Administrar configuración', NEWID(), GETDATE(), IdPadre, Tipo
    FROM dbo.Actions
    WHERE Id = 'PARAMETRIA.EDIT'
      AND NOT EXISTS (SELECT 1 FROM dbo.Actions WHERE Id = 'CONFIGURACION.EDIT');

    INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, IdPadre, Tipo)
    SELECT 'CONFIGURACION.VIEW', N'Ver configuración', NEWID(), GETDATE(), IdPadre, Tipo
    FROM dbo.Actions
    WHERE Id = 'PARAMETRIA.VIEW'
      AND NOT EXISTS (SELECT 1 FROM dbo.Actions WHERE Id = 'CONFIGURACION.VIEW');

    -- 2b. Reapuntar cualquier asignación existente en GroupsActions al nuevo Id.
    UPDATE dbo.GroupsActions
    SET ActionId = 'CONFIGURACION.EDIT'
    WHERE ActionId = 'PARAMETRIA.EDIT';

    UPDATE dbo.GroupsActions
    SET ActionId = 'CONFIGURACION.VIEW'
    WHERE ActionId = 'PARAMETRIA.VIEW';

    -- 2c. Recién ahora es seguro borrar los Actions viejos (sin hijos apuntándolos).
    DELETE FROM dbo.Actions WHERE Id = 'PARAMETRIA.EDIT';
    DELETE FROM dbo.Actions WHERE Id = 'PARAMETRIA.VIEW';

    COMMIT TRAN;
    PRINT 'OK: PARAMETRIA.EDIT/VIEW migrados a CONFIGURACION.EDIT/VIEW.';

END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'ERROR - no se aplicó ningún cambio:';
    PRINT ERROR_MESSAGE();
END CATCH;


/* -----------------------------------------------------------------------------
   PASO 3 - Verificación
   ----------------------------------------------------------------------------- */
SELECT Id, Name, IdPadre, Tipo, ModifiedDate
FROM dbo.Actions
WHERE Id IN ('CONFIGURACION.EDIT', 'CONFIGURACION.VIEW', 'PARAMETRIA.EDIT', 'PARAMETRIA.VIEW');

SELECT ga.GroupId, ga.ActionId, g.Name AS Perfil
FROM dbo.GroupsActions ga
JOIN dbo.Groups g ON g.Id = ga.GroupId
WHERE ga.ActionId IN ('CONFIGURACION.EDIT', 'CONFIGURACION.VIEW');
