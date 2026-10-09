/* ========================================================================
   DIAG_SIDEBAR  (solo lectura, no modifica nada)
   La sidebar de MAIN muestra solo "Configuracion" para todos los usuarios.
   Pegar TODAS las grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. Menus que existen */
SELECT * FROM dbo.SideBar ORDER BY Id;
GO
/* 2. Menus asignados por perfil */
SELECT * FROM dbo.SideBarGroups ORDER BY GroupId, SideBarId;
GO
/* 3. SP / funciones que pintan la sidebar (y cuando se modificaron) */
SELECT O.type_desc, O.name, O.create_date, O.modify_date
FROM sys.objects O
JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE M.definition LIKE '%vct-sidebar-action%' OR M.definition LIKE '%muhleSideBar%' OR M.definition LIKE '%vct_mod_%'
ORDER BY O.modify_date DESC;
GO
/* 4. Todo lo modificado en la base desde el 05/10 (para ver que cambio) */
SELECT TOP 60 O.type_desc, O.name, O.create_date, O.modify_date
FROM sys.objects O
WHERE O.modify_date >= '20261005' AND O.is_ms_shipped = 0
ORDER BY O.modify_date DESC;
GO
/* 5. Perfil de los usuarios de prueba */
IF OBJECT_ID('dbo.GroupsUsers') IS NOT NULL
    EXEC (N'SELECT * FROM dbo.GroupsUsers WHERE UPPER(UserId) IN (''MAJA'',''EDEMARCO'',''AVOCATURO'',''JJVOCATURO'')');
GO
