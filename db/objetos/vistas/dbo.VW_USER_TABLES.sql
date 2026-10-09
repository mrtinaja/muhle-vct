CREATE VIEW [dbo].[VW_USER_TABLES]
AS
SELECT name AS table_name
FROM sysobjects
WHERE xtype = 'u' 
 
 
