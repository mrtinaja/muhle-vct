/* ========================================================================
   PERMISOS_SQUAD_A_GERENCIA  (CAMBIA DATOS)
   ------------------------------------------------------------------------
   maja y EDEMARCO pasan del perfil SQUAD a GERENCIA en GroupsUserMembers,
   para poder entrar a MAIN (con SQUAD la plataforma responde "No posee
   permisos sobre la actividad"). GERENCIA incluye Rentabilidad.
   Para volver atras: correr el bloque ROLLBACK del final.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* antes */
SELECT 'ANTES' AS MOMENTO, M.*
FROM dbo.GroupsUserMembers M
WHERE UPPER(LTRIM(RTRIM(M.UserMemberId))) IN ('MAJA','EDEMARCO');

BEGIN TRANSACTION;
    UPDATE dbo.GroupsUserMembers
       SET GroupId = 'GERENCIA'
     WHERE UPPER(LTRIM(RTRIM(UserMemberId))) IN ('MAJA','EDEMARCO')
       AND UPPER(LTRIM(RTRIM(GroupId))) = 'SQUAD';

    IF COL_LENGTH('dbo.GroupsUserMembers', 'ModifiedDate') IS NOT NULL
        EXEC (N'UPDATE dbo.GroupsUserMembers SET ModifiedDate = GETDATE()
                WHERE UPPER(LTRIM(RTRIM(UserMemberId))) IN (''MAJA'',''EDEMARCO'')');
COMMIT TRANSACTION;

/* despues */
SELECT 'DESPUES' AS MOMENTO, M.*
FROM dbo.GroupsUserMembers M
WHERE UPPER(LTRIM(RTRIM(M.UserMemberId))) IN ('MAJA','EDEMARCO');

/* informativo (solo lectura): sectores por usuario, para investigar despues
   por que SQUAD no entra (avocaturo vs maja) */
IF OBJECT_ID('dbo.UsersSector') IS NOT NULL
    EXEC (N'SELECT TOP 200 * FROM dbo.UsersSector');
GO

/* ------------------------------------------------------------------------
   ROLLBACK (no se ejecuta solo: seleccionar y correr si hace falta volver)
   ------------------------------------------------------------------------
UPDATE dbo.GroupsUserMembers SET GroupId = 'SQUAD'
 WHERE UPPER(LTRIM(RTRIM(UserMemberId))) IN ('MAJA','EDEMARCO');
------------------------------------------------------------------------ */
