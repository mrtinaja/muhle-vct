-- 1) En que base y servidor estas parado ahora mismo
SELECT DB_NAME() AS base_actual, @@SERVERNAME AS server_actual;

-- 2) Buscar la tabla PrmActions en TODAS las bases del servidor
--    (por si el INSERT se corrio en una base distinta a la que usa el panel)
EXEC sp_MSforeachdb '
IF EXISTS (SELECT 1 FROM [?].sys.tables WHERE name = ''PrmActions'')
BEGIN
    SELECT ''?'' AS base_donde_esta_la_tabla;
    EXEC(''SELECT COUNT(*) AS total_filas, MAX(Id) AS ultimo_id FROM [?].dbo.PrmActions'');
    EXEC(''SELECT * FROM [?].dbo.PrmActions WHERE ActionID LIKE ''''CONFIGURACION%'''' ORDER BY Id'');
END
';
