/* ========================================================================
   DIAG_COMPAT - SOLO LECTURA. No modifica nada.
   Version de SQL Server, nivel de compatibilidad de MuhlePROD y prueba real
   de STRING_AGG, STRING_AGG ... WITHIN GROUP y OPENJSON. Tambien revisa
   Database Mail (para la auditoria) y si existe el Agente SQL.
   USO: F5 y copiar la pestana Messages (no hace falta SQLCMD Mode).
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @r NVARCHAR(200), @v NVARCHAR(4000);

PRINT '=== SERVIDOR ===';
PRINT 'Servidor: ' + @@SERVERNAME;
PRINT 'Version:  ' + CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)) + ' ' + CAST(SERVERPROPERTY('ProductLevel') AS VARCHAR(50));
PRINT 'Edicion:  ' + CAST(SERVERPROPERTY('Edition') AS VARCHAR(100));
SELECT @v = CONVERT(NVARCHAR(10), compatibility_level) FROM sys.databases WHERE name = 'MuhlePROD';
PRINT 'Compatibilidad MuhlePROD: ' + ISNULL(@v, '?');

PRINT '';
PRINT '=== PRUEBAS ===';
BEGIN TRY
    EXEC sp_executesql N'SELECT @x = STRING_AGG(v, N'','') FROM (VALUES (N''b''), (N''a'')) t(v);', N'@x NVARCHAR(200) OUTPUT', @r OUTPUT;
    PRINT 'STRING_AGG: OK (' + @r + ')';
END TRY BEGIN CATCH PRINT 'STRING_AGG: NO - ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY
    EXEC sp_executesql N'SELECT @x = STRING_AGG(v, N'','') WITHIN GROUP (ORDER BY v) FROM (VALUES (N''b''), (N''a'')) t(v);', N'@x NVARCHAR(200) OUTPUT', @r OUTPUT;
    PRINT 'STRING_AGG WITHIN GROUP: OK (' + @r + ')';
END TRY BEGIN CATCH PRINT 'STRING_AGG WITHIN GROUP: NO - ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY
    EXEC sp_executesql N'SELECT @x = [value] FROM OPENJSON(N''{"campo":"ok"}'') WHERE [key] = N''campo'';', N'@x NVARCHAR(200) OUTPUT', @r OUTPUT;
    PRINT 'OPENJSON: OK (' + @r + ')';
END TRY BEGIN CATCH PRINT 'OPENJSON: NO - ' + ERROR_MESSAGE(); END CATCH;

PRINT '';
PRINT '=== CONFIGURACION ===';
BEGIN TRY
    SET @r = NULL;
    EXEC sp_executesql N'SELECT @x = CONVERT(NVARCHAR(10), value) FROM sys.database_scoped_configurations WHERE name = ''LEGACY_CARDINALITY_ESTIMATION'';', N'@x NVARCHAR(200) OUTPUT', @r OUTPUT;
    PRINT 'LEGACY_CARDINALITY_ESTIMATION: ' + ISNULL(@r, '?');
END TRY BEGIN CATCH PRINT 'database_scoped_configurations: no disponible'; END CATCH;
BEGIN TRY
    SET @r = NULL;
    EXEC sp_executesql N'SELECT @x = actual_state_desc FROM sys.database_query_store_options;', N'@x NVARCHAR(200) OUTPUT', @r OUTPUT;
    PRINT 'Query Store: ' + ISNULL(@r, 'no disponible');
END TRY BEGIN CATCH PRINT 'Query Store: no disponible'; END CATCH;
BEGIN TRY
    SET @r = NULL;
    SELECT TOP 1 @r = status_desc FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server Agent%';
    PRINT 'Agente SQL: ' + ISNULL(@r, 'no instalado');
END TRY BEGIN CATCH PRINT 'Agente SQL: sin permiso para consultar'; END CATCH;
BEGIN TRY
    SET @v = NULL;
    SELECT @v = STUFF((SELECT ', ' + name FROM msdb.dbo.sysmail_profile FOR XML PATH('')), 1, 2, '');
    PRINT 'Perfiles de Database Mail: ' + ISNULL(@v, '(ninguno)');
END TRY BEGIN CATCH PRINT 'Database Mail: sin permiso para consultar'; END CATCH;
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0)
    PRINT 'Trigger de auditoria instalado: SI';
ELSE
    PRINT 'Trigger de auditoria instalado: no';
PRINT '';
PRINT 'DIAG_COMPAT OK';
