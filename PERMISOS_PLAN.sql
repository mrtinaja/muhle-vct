/* ========================================================================
   PERMISOS_PLAN  (CAMBIA PERMISOS)  v2
   ------------------------------------------------------------------------
   Plan Estrategico:
     PLAN.EDIT -> GERENCIA, SQUAD, PROYECTOS, CONSULTORES  (generar plan,
                  items, gestiones, pendientes del cliente)
     PLAN.VIEW -> los anteriores + ADMINISTRACION          (solo ver)
   Si las acciones no existen en Actions, las crea (igual que el ABM de
   Configuracion: Id, Name, rowguid, ModifiedDate, Tipo).
   Se puede volver a correr: no duplica.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* 1. acciones */
INSERT INTO dbo.Actions (Id, Name, rowguid, ModifiedDate, Tipo)
SELECT a.id, a.nombre, NEWID(), GETDATE(), NULL
FROM (VALUES ('PLAN.EDIT', 'Plan Estrategico - editar'),
             ('PLAN.VIEW', 'Plan Estrategico - ver')) a(id, nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Actions AC WHERE UPPER(LTRIM(RTRIM(AC.Id))) = a.id);
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' acciones creadas en Actions.';

/* 2. asignacion por perfil */
INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
SELECT v.grupo, v.accion, NEWID(), GETDATE()
FROM (VALUES ('GERENCIA','PLAN.EDIT'),('SQUAD','PLAN.EDIT'),('PROYECTOS','PLAN.EDIT'),('CONSULTORES','PLAN.EDIT'),
             ('GERENCIA','PLAN.VIEW'),('SQUAD','PLAN.VIEW'),('PROYECTOS','PLAN.VIEW'),('CONSULTORES','PLAN.VIEW'),
             ('ADMINISTRACION','PLAN.VIEW')) v(grupo, accion)
WHERE EXISTS (SELECT 1 FROM dbo.Groups GR WHERE UPPER(LTRIM(RTRIM(GR.Id))) = v.grupo)
  AND NOT EXISTS (SELECT 1 FROM dbo.GroupsActions X
                  WHERE UPPER(LTRIM(RTRIM(X.GroupId))) = v.grupo
                    AND UPPER(LTRIM(RTRIM(X.ActionId))) = v.accion);
PRINT CONVERT(VARCHAR(10), @@ROWCOUNT) + ' permisos asignados.';

/* 3. resultado */
SELECT AC.Id, AC.Name FROM dbo.Actions AC WHERE AC.Id LIKE 'PLAN.%';
SELECT X.GroupId AS PERFIL, X.ActionId AS PERMISO
FROM dbo.GroupsActions X
WHERE UPPER(LTRIM(RTRIM(X.ActionId))) IN ('PLAN.EDIT','PLAN.VIEW')
ORDER BY X.GroupId, X.ActionId;
SELECT dbo.VCT_PERFIL_PUEDE('GERENCIA','PLAN.EDIT') AS GERENCIA_EDIT,
       dbo.VCT_PERFIL_PUEDE('ADMINISTRACION','PLAN.EDIT') AS ADMIN_EDIT,
       dbo.VCT_PERFIL_PUEDE('ADMINISTRACION','PLAN.VIEW') AS ADMIN_VIEW;
GO
