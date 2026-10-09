/* ========================================================================
   DIAG_SCRIPTS_APLICADOS  (solo lectura)  -  correr con Query > SQLCMD Mode
   Verifica si quedaron aplicados FIX_VCT_GET_SIDEBAR_V82 y
   PROYECTO_VISITAS_3_ASSETS_V2, y contra que servidor / base se corre.
   ======================================================================== */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\DIAG_SCRIPTS_APLICADOS.txt
USE [MuhlePROD];
SET NOCOUNT ON;

SELECT @@SERVERNAME AS SERVIDOR, DB_NAME() AS BASE, SUSER_SNAME() AS USUARIO, GETDATE() AS AHORA;

SELECT O.name, O.modify_date,
       CASE WHEN M.definition LIKE '%V8.2%' THEN 'SI' ELSE 'NO' END AS TIENE_V82,
       CASE WHEN M.definition LIKE '%body:not(.vct-x)%' THEN 'SI' ELSE 'NO' END AS CSS_MOVIL,
       CASE WHEN M.definition LIKE '%vct-proyecto-visitas.js?v=2%' THEN 'SI' ELSE 'NO' END AS VISITAS_V2,
       CASE WHEN M.definition LIKE '%vct-proyecto-visitas.js?v=1%' THEN 'SI' ELSE 'NO' END AS VISITAS_V1
FROM sys.objects O JOIN sys.sql_modules M ON M.object_id = O.object_id
WHERE O.name IN ('VCT_GET_SIDEBAR','VCT_MAIN_PROYECTO_V360');

/* otras bases del servidor que tengan VCT_GET_SIDEBAR (por si se corrio en otra) */
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'SELECT ''' + name + N''' AS BASE, modify_date FROM ' + QUOTENAME(name) + N'.sys.objects WHERE name = ''VCT_GET_SIDEBAR'' UNION ALL '
FROM sys.databases WHERE state = 0 AND HAS_DBACCESS(name) = 1;
IF @sql <> N'' BEGIN SET @sql = LEFT(@sql, LEN(@sql) - 10) + N' ORDER BY 2 DESC;'; EXEC sp_executesql @sql; END;
GO
