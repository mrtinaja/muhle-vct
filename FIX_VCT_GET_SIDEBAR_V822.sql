/* FIX_VCT_GET_SIDEBAR_V822: en escritorio, reglas viejas de vct-main.css
   (body.vct-sidebar-expanded / :not(...)) volvian a mostrar el nombre en el riel
   y corrian los iconos. Se agrega un selector mas fuerte a "SIN TEXTOS". */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_GET_SIDEBAR'));
DECLARE @MK NVARCHAR(200) = N'''html body #muhleSideBar .vct-sidebar-text,''+';

IF CHARINDEX(N'vct-sidebar-v8 .vct-sidebar-text,html body #muhleSideBar', @D) > 0
BEGIN
    PRINT 'VCT_GET_SIDEBAR ya tenia el arreglo de escritorio. No se hizo nada.';
    RETURN;
END;

IF (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @MK, N''))) / DATALENGTH(@MK) <> 1
BEGIN
    RAISERROR('No se encontro la regla SIN TEXTOS en VCT_GET_SIDEBAR. No se aplico nada.',16,1);
    RETURN;
END;

SET @D = REPLACE(@D, @MK, N'''html body:not(.vct-x) #muhleSideBar.vct-sidebar.vct-sidebar-option-b.vct-sidebar-v8 .vct-sidebar-text,html body #muhleSideBar .vct-sidebar-text,''+');
IF CHARINDEX(N'ALTER PROCEDURE', @D) = 0 AND CHARINDEX(N'CREATE PROCEDURE', @D) > 0
    SET @D = STUFF(@D, CHARINDEX(N'CREATE PROCEDURE', @D), 6, N'ALTER');
EXEC sp_executesql @D;
PRINT 'OK: VCT_GET_SIDEBAR V8.2 - escritorio sin nombres en el riel.';
GO
