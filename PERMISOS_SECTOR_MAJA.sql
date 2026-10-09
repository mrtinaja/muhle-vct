/* ========================================================================
   PERMISOS_SECTOR_MAJA  (CAMBIA DATOS)
   ------------------------------------------------------------------------
   maja no tiene fila en UsersSector (avocaturo y edemarco si). La
   plataforma responde "No posee permisos sobre la actividad" a maja.
   Se le copia a maja la(s) fila(s) de sector de avocaturo, con todas las
   columnas iguales salvo el usuario (y rowguid / fecha si existen).
   Si maja ya tiene sector, no hace nada.
   Para volver atras: bloque comentado al final.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;

/* antes: sectores de los tres usuarios */
SELECT 'ANTES' AS MOMENTO, * FROM dbo.UsersSector
WHERE UPPER(LTRIM(RTRIM(Id_User))) IN ('AVOCATURO','EDEMARCO','MAJA');

IF EXISTS (SELECT 1 FROM dbo.UsersSector WHERE UPPER(LTRIM(RTRIM(Id_User))) = 'MAJA')
BEGIN
    PRINT 'maja ya tiene sector. No se hizo nada.';
    RETURN;
END;

/* columnas a copiar (sin identidad ni calculadas) */
DECLARE @cols NVARCHAR(MAX) = N'', @sel NVARCHAR(MAX) = N'';
SELECT @cols = @cols + CASE WHEN @cols = N'' THEN N'' ELSE N', ' END + QUOTENAME(c.name),
       @sel  = @sel  + CASE WHEN @sel  = N'' THEN N'' ELSE N', ' END +
               CASE WHEN c.name = 'Id_User' THEN N'''maja'''
                    WHEN TYPE_NAME(c.user_type_id) = 'uniqueidentifier' THEN N'NEWID()'
                    WHEN c.name LIKE '%Modified%' OR c.name LIKE '%FECHA%' THEN N'GETDATE()'
                    ELSE QUOTENAME(c.name) END
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.UsersSector') AND c.is_identity = 0 AND c.is_computed = 0
ORDER BY c.column_id;

DECLARE @sql NVARCHAR(MAX) =
    N'INSERT INTO dbo.UsersSector (' + @cols + N') SELECT ' + @sel +
    N' FROM dbo.UsersSector WHERE UPPER(LTRIM(RTRIM(Id_User))) = ''AVOCATURO'';';
PRINT @sql;
EXEC sp_executesql @sql;

/* despues */
SELECT 'DESPUES' AS MOMENTO, * FROM dbo.UsersSector
WHERE UPPER(LTRIM(RTRIM(Id_User))) IN ('AVOCATURO','EDEMARCO','MAJA');
GO

/* ------------------------------------------------------------------------
   VOLVER ATRAS (no se ejecuta solo):
DELETE FROM dbo.UsersSector WHERE UPPER(LTRIM(RTRIM(Id_User))) = 'MAJA';
------------------------------------------------------------------------ */
