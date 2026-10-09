/* buscar_mensaje_inactividad_v2.sql
   Version acotada: solo barre tablas CHICAS (candidatas a ser catalogo/
   parametrizacion, no logs/auditoria/historico), asi evita quedarse
   escaneando tablas grandes fila por fila como paso en la v1.

   Ajusta @MaxFilas si hace falta (por defecto 20000 filas por tabla). */

SET NOCOUNT ON;

DECLARE @MaxFilas INT = 20000;

DECLARE @Palabras TABLE (Palabra NVARCHAR(100));
INSERT INTO @Palabras (Palabra) VALUES
    (N'inactividad'),
    (N'sesión'),
    (N'sesion'),
    (N'expir'),
    (N'tiempo de espera'),
    (N'cerró por'),
    (N'cerro por'),
    (N'timeout');

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'
SELECT ' + QUOTENAME(t.name,'''') + N' AS Tabla, ' + QUOTENAME(c.name,'''') + N' AS Columna,
       ' + QUOTENAME(c.name) + N' AS Valor
FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N'
WHERE ' + QUOTENAME(c.name) + N' LIKE ''%' + p.Palabra + N'%''
UNION ALL'
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
CROSS JOIN @Palabras p
WHERE ty.name IN ('varchar','nvarchar','text','ntext','char','nchar')
  AND t.is_ms_shipped = 0
  -- solo tablas chicas: descarta logs/auditoria/historico grandes
  AND t.object_id IN (
        SELECT p.object_id
        FROM sys.partitions p
        WHERE p.index_id IN (0,1)
        GROUP BY p.object_id
        HAVING SUM(p.rows) <= @MaxFilas
  )
  -- descarta por nombre las que sabemos que son logs/auditoria/historicas
  AND t.name NOT LIKE '%AUDITORIA%'
  AND t.name NOT LIKE '%LOG%'
  AND t.name NOT LIKE '%HISTORICO%';

SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL'));

EXEC sp_executesql @sql;
