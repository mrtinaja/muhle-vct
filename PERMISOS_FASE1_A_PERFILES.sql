/* ========================================================================
   PERMISOS FASE 1 - A) PERFILES Y USUARIOS  (CAMBIA DATOS: leer antes de correr)
   ------------------------------------------------------------------------
   Decisiones del 2026-10-06:
     1. Rentabilidad: la ven solo GERENCIA y svocaturo (perfil ADMINISTRACION).
        -> se asigna RENTABILIDAD.VIEW a los perfiles GERENCIA y ADMINISTRACION.
        -> se crea dbo.VCT_PERFIL_PUEDE(@IUNIDAD, accion) para que los SP
           consulten el permiso en vez de listas de usuarios (ver script B).
     2. Desarrolladores = EDEMARCO y maja -> perfil SQUAD, con los mismos
        menues y acciones que GERENCIA (sin Rentabilidad) para que sigan
        entrando. majaja se elimina. yolvirri queda en PROYECTOS (empleados).
     3. Empleados activos sin usuario: se crean EDEOLIVEIRA, JOCHOA y LRAMIREZ
        (perfil PROYECTOS) y se vinculan a su empleado; se vinculan tambien
        LBERRA (#120) y SVOCATURO (#58) (campo "Ingresa al sistema").
   Es transaccional: si algo no coincide, NO cambia nada y avisa.
   @PASS_INICIAL (contrasena inicial de los 3 usuarios nuevos, mismo hash que
   el admin): opcional. Si se deja vacia, los usuarios nuevos se crean
   DESACTIVADOS y sin clave; el administrador define la clave y los activa
   desde el admin (Gestion de Usuarios).
   ======================================================================== */
USE [MuhlePROD];
GO
CREATE OR ALTER FUNCTION dbo.VCT_PERFIL_PUEDE
(
    @IUNIDAD   VARCHAR(100),   -- perfil (Groups.Id), el mismo @IUNIDAD de los SP de MAIN
    @ACTION_ID VARCHAR(150)    -- ej. 'RENTABILIDAD.VIEW'
)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS
    (
        SELECT 1
        FROM dbo.GroupsActions GA WITH (NOLOCK)
        WHERE UPPER(LTRIM(RTRIM(GA.GroupId))) = UPPER(LTRIM(RTRIM(@IUNIDAD)))
          AND UPPER(LTRIM(RTRIM(GA.ActionId))) = UPPER(LTRIM(RTRIM(@ACTION_ID)))
    ) THEN 1 ELSE 0 END;
END
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @PASS_INICIAL VARCHAR(100) = '';      /* opcional: vacia = usuarios nuevos desactivados y sin clave */
DECLARE @EJECUTOR     VARCHAR(30)  = 'PERMISOS_FASE1';

/* Si @PASS_INICIAL queda vacia, los usuarios nuevos se crean DESACTIVADOS y sin clave:
   la define y los activa el administrador desde el admin (Gestion de Usuarios). */
DECLARE @SIN_CLAVE BIT = CASE WHEN @PASS_INICIAL = '' THEN 1 ELSE 0 END;
IF @SIN_CLAVE = 1
    PRINT 'Sin contrasena inicial: los usuarios nuevos se crean DESACTIVADOS y sin clave; defina la clave y activelos desde el admin.';

/* ---------- pre-chequeos: si algo falta, no se toca nada ---------- */
DECLARE @falta NVARCHAR(300) = NULL;
IF NOT EXISTS (SELECT 1 FROM dbo.Groups WHERE UPPER(LTRIM(RTRIM(Id)))='GERENCIA')       SET @falta=N'perfil GERENCIA';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Groups WHERE UPPER(LTRIM(RTRIM(Id)))='ADMINISTRACION') SET @falta=N'perfil ADMINISTRACION';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Groups WHERE UPPER(LTRIM(RTRIM(Id)))='SQUAD')           SET @falta=N'perfil SQUAD';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Groups WHERE UPPER(LTRIM(RTRIM(Id)))='PROYECTOS')       SET @falta=N'perfil PROYECTOS';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Actions WHERE UPPER(LTRIM(RTRIM(Id)))='RENTABILIDAD.VIEW') SET @falta=N'accion RENTABILIDAD.VIEW en Actions';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='EDEMARCO')  SET @falta=N'usuario EDEMARCO';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='MAJA')      SET @falta=N'usuario maja';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='LBERRA')    SET @falta=N'usuario LBERRA';
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='SVOCATURO') SET @falta=N'usuario SVOCATURO';
IF @falta IS NOT NULL
BEGIN
    RAISERROR('No existe: %s. No se hizo ningun cambio de datos.',16,1,@falta);
    RETURN;
END;

DECLARE @map TABLE (emp INT, usr VARCHAR(30), ape VARCHAR(60));
INSERT @map VALUES (27,'EDEOLIVEIRA','DE OLIVEIRA%'),(134,'JOCHOA','OCHOA%'),(135,'LRAMIREZ','RAMIREZ%'),(120,'LBERRA','BERRA%'),(58,'SVOCATURO','VOCATURO%');

DECLARE @nuevos TABLE (id VARCHAR(30), nombre VARCHAR(150), email VARCHAR(150));
INSERT @nuevos VALUES ('EDEOLIVEIRA','De Oliveira Estela Maris','vocaturoyasoc@yahoo.com.ar'),
                      ('JOCHOA','Ochoa Juan Pablo',''),
                      ('LRAMIREZ','Ramirez Lara Yanella Ailen','');

IF (SELECT COUNT(*) FROM dbo.VCT_EMPLEADOS E INNER JOIN @map m ON m.emp=E.ID WHERE UPPER(E.APELLIDOS) LIKE m.ape) <> (SELECT COUNT(*) FROM @map)
BEGIN
    RAISERROR('Los empleados #27, #134, #135, #120 y #58 no coinciden con los apellidos esperados. No se hizo ningun cambio de datos.',16,1);
    RETURN;
END;

IF EXISTS (SELECT 1 FROM dbo.Users U INNER JOIN @nuevos n ON UPPER(LTRIM(RTRIM(U.Name)))=UPPER(n.nombre) AND UPPER(LTRIM(RTRIM(U.Id)))<>n.id)
BEGIN
    RAISERROR('Ya existe otro usuario con el mismo Nombre y Apellido que uno de los nuevos. No se hizo ningun cambio de datos.',16,1);
    RETURN;
END;

/* ---------- cambios (una sola transaccion) ---------- */
BEGIN TRY
    BEGIN TRANSACTION;

    /* 1. Rentabilidad: GERENCIA y ADMINISTRACION */
    INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
    SELECT g.id, 'RENTABILIDAD.VIEW', NEWID(), GETDATE()
    FROM (VALUES ('GERENCIA'),('ADMINISTRACION')) g(id)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.GroupsActions X WHERE UPPER(LTRIM(RTRIM(X.GroupId)))=g.id AND UPPER(LTRIM(RTRIM(X.ActionId)))='RENTABILIDAD.VIEW');

    /* 2. SQUAD: mismas acciones que GERENCIA (sin Rentabilidad) y mismos menues */
    INSERT INTO dbo.GroupsActions (GroupId, ActionId, rowguid, ModifiedDate)
    SELECT 'SQUAD', A.ActionId, NEWID(), GETDATE()
    FROM dbo.GroupsActions A
    WHERE UPPER(LTRIM(RTRIM(A.GroupId)))='GERENCIA'
      AND UPPER(A.ActionId) NOT LIKE 'RENTABILIDAD.%'
      AND NOT EXISTS (SELECT 1 FROM dbo.GroupsActions X WHERE UPPER(LTRIM(RTRIM(X.GroupId)))='SQUAD' AND X.ActionId=A.ActionId);

    DECLARE @cols NVARCHAR(MAX), @sel NVARCHAR(MAX), @sqlM NVARCHAR(MAX);
    SELECT @cols = STUFF((SELECT ',' + QUOTENAME(c.name)
                          FROM sys.columns c
                          WHERE c.object_id=OBJECT_ID('dbo.SideBarGroups') AND c.is_identity=0 AND c.is_computed=0
                          ORDER BY c.column_id
                          FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'');
    SELECT @sel  = STUFF((SELECT ',' + CASE WHEN LOWER(c.name)='groupid'      THEN '''SQUAD'''
                                            WHEN LOWER(c.name)='rowguid'      THEN 'NEWID()'
                                            WHEN LOWER(c.name)='modifieddate' THEN 'GETDATE()'
                                            ELSE 'S.' + QUOTENAME(c.name) END
                          FROM sys.columns c
                          WHERE c.object_id=OBJECT_ID('dbo.SideBarGroups') AND c.is_identity=0 AND c.is_computed=0
                          ORDER BY c.column_id
                          FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'');
    SET @sqlM = N'INSERT INTO dbo.SideBarGroups (' + @cols + N') SELECT ' + @sel +
                N' FROM dbo.SideBarGroups S WHERE UPPER(LTRIM(RTRIM(S.GroupId)))=''GERENCIA''' +
                N' AND NOT EXISTS (SELECT 1 FROM dbo.SideBarGroups X WHERE UPPER(LTRIM(RTRIM(X.GroupId)))=''SQUAD'' AND X.SideBarId=S.SideBarId)';
    EXEC (@sqlM);

    /* 3. Desarrolladores a SQUAD (un solo perfil por usuario) */
    DELETE FROM dbo.GroupsUserMembers WHERE UPPER(LTRIM(RTRIM(UserMemberId))) IN ('EDEMARCO','MAJA');
    INSERT INTO dbo.GroupsUserMembers (GroupId, UserMemberId, rowguid, ModifiedDate)
    SELECT 'SQUAD', UPPER(LTRIM(RTRIM(U.Id))), NEWID(), GETDATE()
    FROM dbo.Users U WHERE UPPER(LTRIM(RTRIM(U.Id))) IN ('EDEMARCO','MAJA');

    /* 5. Empleados activos: usuarios nuevos (perfil PROYECTOS) ... */
    INSERT INTO dbo.Users (Id, [Name], Email, [Password], [State], LoginFailure, ModifiedDate)
    SELECT n.id, n.nombre, n.email,
           CASE WHEN @SIN_CLAVE = 1 THEN '' ELSE CONVERT(VARCHAR(40), HASHBYTES('SHA1', UPPER(n.id) + @PASS_INICIAL), 2) END,
           CASE WHEN @SIN_CLAVE = 1 THEN 0 ELSE 1 END,
           0, GETDATE()
    FROM @nuevos n
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Users U WHERE UPPER(LTRIM(RTRIM(U.Id)))=n.id);

    INSERT INTO dbo.GroupsUserMembers (GroupId, UserMemberId, rowguid, ModifiedDate)
    SELECT 'PROYECTOS', n.id, NEWID(), GETDATE()
    FROM @nuevos n
    WHERE NOT EXISTS (SELECT 1 FROM dbo.GroupsUserMembers M WHERE UPPER(LTRIM(RTRIM(M.UserMemberId)))=n.id);

    /* ... y vinculo usuario <-> empleado (mismo efecto que "Ingresa al sistema" + usuario en MAIN > Empleados) */
    DECLARE @rc INT;
    UPDATE E
       SET E.INGRESA_SISTEMA = 1,
           E.ID_USUARIO_SEGURIDAD = LOWER(m.usr),
           E.FECHA_UPD = GETDATE(),
           E.USUARIO_UPD = @EJECUTOR
    FROM dbo.VCT_EMPLEADOS E
    INNER JOIN @map m ON m.emp = E.ID
    WHERE UPPER(E.APELLIDOS) LIKE m.ape;
    SET @rc = @@ROWCOUNT;
    IF @rc <> (SELECT COUNT(*) FROM @map)
        RAISERROR('No se pudieron vincular todos los empleados. Se deshace todo.',16,1);

    /* auditoria (misma tabla que usa el admin) */
    IF OBJECT_ID('dbo.M_AUDITORIA_ADMIN','U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.M_AUDITORIA_ADMIN (Modulo, Accion, UsuarioId, RegistroAfectado, Detalle, Fecha)
        VALUES ('PERFIL_ADMIN','ASOCIAR',@EJECUTOR,'GERENCIA,ADMINISTRACION','RENTABILIDAD.VIEW asignada a GERENCIA y ADMINISTRACION',GETDATE()),
               ('PERFIL_ADMIN','ASOCIAR',@EJECUTOR,'SQUAD','SQUAD recibe las acciones y menues de GERENCIA (sin Rentabilidad)',GETDATE()),
               ('USUARIOS','MODIFICACION',@EJECUTOR,'EDEMARCO,MAJA','Desarrolladores pasan al perfil SQUAD',GETDATE());
        INSERT INTO dbo.M_AUDITORIA_ADMIN (Modulo, Accion, UsuarioId, RegistroAfectado, Detalle, Fecha)
        SELECT 'USUARIOS','ALTA',@EJECUTOR,n.id,'Alta de usuario '+n.id+' (perfil PROYECTOS) para empleado activo',GETDATE() FROM @nuevos n;
    END;

    COMMIT TRANSACTION;
    PRINT 'OK: perfiles, permisos y usuarios actualizados.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR - se deshizo todo: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

/* 4. Eliminar el usuario majaja (fuera de la transaccion principal).
      Si tiene registros asociados que impiden borrarlo, queda DESACTIVADO (State=0) y sin perfil. */
IF EXISTS (SELECT 1 FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='MAJAJA')
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM dbo.GroupsUserMembers WHERE UPPER(LTRIM(RTRIM(UserMemberId)))='MAJAJA';
        DELETE FROM dbo.UsersSector WHERE UPPER(LTRIM(RTRIM(Id_User)))='MAJAJA';
        DELETE FROM dbo.Users WHERE UPPER(LTRIM(RTRIM(Id)))='MAJAJA';
        COMMIT TRANSACTION;
        PRINT 'OK: usuario majaja eliminado.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DELETE FROM dbo.GroupsUserMembers WHERE UPPER(LTRIM(RTRIM(UserMemberId)))='MAJAJA';
        UPDATE dbo.Users SET [State]=0, ModifiedDate=GETDATE() WHERE UPPER(LTRIM(RTRIM(Id)))='MAJAJA';
        PRINT 'majaja no se pudo borrar (tiene registros asociados): quedo DESACTIVADO y sin perfil. Detalle: ' + ERROR_MESSAGE();
    END CATCH;
END
ELSE
    PRINT 'majaja ya no existia.';

/* ---------- verificacion ---------- */
SELECT 'Rentabilidad por perfil' AS control, GA.GroupId AS dato FROM dbo.GroupsActions GA WHERE UPPER(GA.ActionId)='RENTABILIDAD.VIEW';
SELECT 'Perfil de usuarios tocados' AS control, M.UserMemberId AS usuario, M.GroupId AS perfil
FROM dbo.GroupsUserMembers M
WHERE UPPER(M.UserMemberId) IN ('EDEMARCO','MAJA','MAJAJA','YOLVIRRI','EDEOLIVEIRA','JOCHOA','LRAMIREZ','LBERRA','SVOCATURO');
SELECT 'SQUAD: acciones / menues' AS control,
       (SELECT COUNT(*) FROM dbo.GroupsActions WHERE UPPER(GroupId)='SQUAD') AS acciones,
       (SELECT COUNT(*) FROM dbo.SideBarGroups WHERE UPPER(GroupId)='SQUAD') AS menues;
SELECT 'Empleados vinculados' AS control, E.ID, E.APELLIDOS, E.NOMBRES, E.ESTADO, E.INGRESA_SISTEMA, E.ID_USUARIO_SEGURIDAD
FROM dbo.VCT_EMPLEADOS E WHERE E.ID IN (27,134,135,120,58);
GO
