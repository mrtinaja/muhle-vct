/* buscar_mensaje_inactividad.sql
   Barre TODAS las columnas de texto de TODAS las tablas de la base buscando
   fragmentos relacionados al mensaje de cierre de sesion por inactividad.
   Util cuando no sabemos si el texto esta hardcodeado en el front (JS/aspx)
   o parametrizado en alguna tabla tipo CAT_DATA / M_CONFIG / plantilla.

   Ajusta la lista de @Palabras si el primer resultado no aparece, o agregale
   una palabra poco comun tomada del texto real una vez que lo tengas
   (ej. "inactividad", "expiro", "expirada", "cerro por", "tiempo de espera"). */

SET NOCOUNT ON;

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
  AND t.is_ms_shipped = 0;

SET @sql = LEFT(@sql, LEN(@sql) - LEN('UNION ALL'));

EXEC sp_executesql @sql;
