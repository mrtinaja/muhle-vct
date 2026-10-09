/* ========================================================================
   COMPAT_SUBIR  (CAMBIA LA CONFIGURACION DE LA BASE)
   ------------------------------------------------------------------------
   Sube el nivel de compatibilidad de MuhlePROD para poder usar
   STRING_AGG ... WITHIN GROUP y OPENJSON (JSON en vez de buffers id=valor|).
     - Nivel: 140 si el servidor es SQL Server 2017 o mas nuevo, 130 si es 2016.
     - LEGACY_CARDINALITY_ESTIMATION = ON: el optimizador sigue estimando como
       antes, para que los SP viejos no cambien de rendimiento de golpe.
     - Query Store = ON: guarda los planes, para comparar si algo se pone lento.
   ANTES: correr DIAG_COMPAT.sql y pasar el resultado. Hacerlo primero en
   DESARROLLO, recorrer la aplicacion un dia y recien despues en produccion,
   en un horario sin uso (el cambio vacia la cache de planes de la base).
   VOLVER ATRAS (inmediato):
       ALTER DATABASE [MuhlePROD] SET COMPATIBILITY_LEVEL = <nivel anterior>;
   El nivel anterior queda impreso en Messages al correr este script.
   ======================================================================== */
USE [master];
SET NOCOUNT ON;

DECLARE @MAJOR INT = CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)), 4) AS INT);
DECLARE @NIVEL INT = CASE WHEN @MAJOR >= 14 THEN 140 WHEN @MAJOR = 13 THEN 130 ELSE 0 END;
DECLARE @ACTUAL INT = (SELECT compatibility_level FROM sys.databases WHERE name = 'MuhlePROD');

PRINT 'Nivel anterior de MuhlePROD: ' + CONVERT(VARCHAR(10), @ACTUAL) + '  (anotarlo para volver atras)';

IF @NIVEL = 0
    RAISERROR('El servidor es anterior a SQL Server 2016: no soporta OPENJSON. No se cambia nada.', 16, 1);
ELSE IF @ACTUAL >= @NIVEL
    PRINT 'MuhlePROD ya esta en ' + CONVERT(VARCHAR(10), @ACTUAL) + '. No se cambia el nivel.';
ELSE
BEGIN
    DECLARE @SQL NVARCHAR(200) = N'ALTER DATABASE [MuhlePROD] SET COMPATIBILITY_LEVEL = ' + CONVERT(NVARCHAR(10), @NIVEL) + N';';
    EXEC (@SQL);
    PRINT 'MuhlePROD pasa a nivel ' + CONVERT(VARCHAR(10), @NIVEL) + '.';
END
GO
USE [MuhlePROD];
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = ON;
PRINT 'LEGACY_CARDINALITY_ESTIMATION = ON';
GO
BEGIN TRY
    ALTER DATABASE CURRENT SET QUERY_STORE = ON;
    PRINT 'Query Store = ON';
END TRY
BEGIN CATCH
    PRINT 'Query Store no se pudo activar: ' + ERROR_MESSAGE();
END CATCH;
GO
/* Verificacion */
DECLARE @r NVARCHAR(200);
SELECT @r = STRING_AGG(v, N',') WITHIN GROUP (ORDER BY v) FROM (VALUES (N'b'), (N'a')) t(v);
PRINT 'STRING_AGG WITHIN GROUP: ' + @r;
SELECT @r = [value] FROM OPENJSON(N'{"campo":"ok"}') WHERE [key] = N'campo';
PRINT 'OPENJSON: ' + @r;
GO
