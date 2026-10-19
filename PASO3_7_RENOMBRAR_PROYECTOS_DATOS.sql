/* ========================================================================
   PASO3_7_RENOMBRAR_PROYECTOS_DATOS
   ------------------------------------------------------------------------
   dbo.VCT_PROYECTOS_DOCUMENTOS pasa a llamarse dbo.VCT_PROYECTOS_DATOS
   (datos de entrada, consideraciones, reuniones, inicio y, despues, riesgos).
   El nombre VCT_PROYECTOS_DOCUMENTOS queda libre para la futura tabla de
   adjuntos del proyecto.
     1. Lista los objetos que usan la tabla. Si alguna VISTA la usa, no hace
        nada (las vistas no se tocan).
     2. sp_rename de la tabla: conserva filas, columnas, IDs, indices,
        claves y triggers. No copia ni modifica datos.
     3. Renombra claves / CHECK / DEFAULT / indices cuyo nombre tenga
        VCT_PROYECTOS_DOCUMENTOS (incluidas las FK de otras tablas que la
        referencian).
     4. Actualiza la definicion vigente de cada SP / trigger / funcion que
        nombra la tabla: reemplaza solo el nombre exacto (no toca
        VCT_PROYECTOS_DOCUMENTOS_ITEMS ni VCT_PRM_DOCUMENTOS) y la vuelve a
        grabar con ALTER.
   Todo en una transaccion: si algo falla, no queda nada a medias.
   Re-ejecutable: si la tabla ya fue renombrada, solo revisa los objetos.
   No crea tablas, vistas ni SPs. No ejecuta INSERT / UPDATE / DELETE.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET XACT_ABORT ON;

DECLARE @VIEJA NVARCHAR(128) = N'VCT_PROYECTOS_DOCUMENTOS', @NUEVA NVARCHAR(128) = N'VCT_PROYECTOS_DATOS',
        @OK BIT = 1, @RENOMBRAR BIT = 0, @TRG BIT = 0;

IF OBJECT_ID(N'dbo.VCT_PROYECTOS_DOCUMENTOS', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.VCT_PROYECTOS_DATOS') IS NULL
    SET @RENOMBRAR = 1;
ELSE IF OBJECT_ID(N'dbo.VCT_PROYECTOS_DOCUMENTOS', N'U') IS NULL AND OBJECT_ID(N'dbo.VCT_PROYECTOS_DATOS', N'U') IS NOT NULL
    PRINT 'OK   la tabla ya se llama dbo.VCT_PROYECTOS_DATOS: solo se revisan los objetos que la usan.';
ELSE IF OBJECT_ID(N'dbo.VCT_PROYECTOS_DOCUMENTOS', N'U') IS NOT NULL
BEGIN
    PRINT 'FALLO existen dbo.VCT_PROYECTOS_DOCUMENTOS y un objeto dbo.VCT_PROYECTOS_DATOS: no se hace nada.';
    SET @OK = 0;
END
ELSE
BEGIN
    PRINT 'FALLO no existe dbo.VCT_PROYECTOS_DOCUMENTOS ni dbo.VCT_PROYECTOS_DATOS.';
    SET @OK = 0;
END;

/* ---------- 1. objetos que nombran la tabla (nombre exacto) ---------- */
DECLARE @M TABLE (ID INT, NOMBRE NVARCHAR(300), TIPO VARCHAR(2), DEF NVARCHAR(MAX), CAMBIOS INT);
INSERT INTO @M (ID, NOMBRE, TIPO, DEF, CAMBIOS)
SELECT O.object_id, SCHEMA_NAME(O.schema_id) + N'.' + O.name, O.type, M.[definition], 0
FROM sys.sql_modules M INNER JOIN sys.objects O ON O.object_id = M.object_id
WHERE M.[definition] LIKE N'%VCT[_]PROYECTOS[_]DOCUMENTOS%';

/* reemplazo del nombre exacto: el caracter anterior y el siguiente no pueden ser letra, numero o _ */
DECLARE @ID INT, @D NVARCHAR(MAX), @P INT, @L INT = LEN(@VIEJA), @N INT, @A NCHAR(1), @S NCHAR(1);
DECLARE CM CURSOR LOCAL STATIC READ_ONLY FOR SELECT ID, DEF FROM @M;
OPEN CM;
FETCH NEXT FROM CM INTO @ID, @D;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @N = 0;
    SET @P = CHARINDEX(@VIEJA, @D);
    WHILE @P > 0
    BEGIN
        SET @A = CASE WHEN @P > 1 THEN SUBSTRING(@D, @P - 1, 1) ELSE N' ' END;
        SET @S = SUBSTRING(@D, @P + @L, 1);
        IF @A LIKE N'[A-Za-z0-9_]' OR @S LIKE N'[A-Za-z0-9_]'
            SET @P = CHARINDEX(@VIEJA, @D, @P + @L);
        ELSE
        BEGIN
            SET @D = STUFF(@D, @P, @L, @NUEVA);
            SET @N = @N + 1;
            SET @P = CHARINDEX(@VIEJA, @D, @P + LEN(@NUEVA));
        END;
    END;
    UPDATE @M SET DEF = @D, CAMBIOS = @N WHERE ID = @ID;
    FETCH NEXT FROM CM INTO @ID, @D;
END;
CLOSE CM; DEALLOCATE CM;
DELETE FROM @M WHERE CAMBIOS = 0;   /* solo nombraban VCT_PROYECTOS_DOCUMENTOS_ITEMS u otro nombre parecido */

SELECT NOMBRE AS OBJETO, TIPO, CAMBIOS AS REEMPLAZOS FROM @M ORDER BY TIPO, NOMBRE;

IF @OK = 1 AND EXISTS (SELECT 1 FROM @M WHERE TIPO = 'V')
BEGIN
    PRINT 'FALLO hay vistas que usan la tabla (no se tocan vistas). No se hace nada. Vistas:';
    SELECT NOMBRE AS VISTA FROM @M WHERE TIPO = 'V';
    SET @OK = 0;
END;
IF @OK = 1 AND EXISTS (SELECT 1 FROM @M WHERE TIPO NOT IN ('P','TR','FN','IF','TF'))
BEGIN
    PRINT 'FALLO hay objetos de un tipo no previsto que usan la tabla. No se hace nada.';
    SET @OK = 0;
END;

/* CREATE -> ALTER en cada definicion (CREATE OR ALTER queda igual) */
IF @OK = 1
BEGIN
    DECLARE @T NVARCHAR(40), @NOM_X NVARCHAR(300);
    DECLARE CA CURSOR LOCAL STATIC READ_ONLY FOR SELECT ID, DEF FROM @M;
    OPEN CA;
    FETCH NEXT FROM CA INTO @ID, @D;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @P = CHARINDEX(N'CREATE', @D);
        WHILE @P > 0
        BEGIN
            SET @T = LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(@D, @P + 6, 40), NCHAR(13), N' '), NCHAR(10), N' '), NCHAR(9), N' '));
            IF @T LIKE N'PROC%' OR @T LIKE N'TRIGGER%' OR @T LIKE N'FUNCTION%' OR @T LIKE N'OR ALTER%' BREAK;
            SET @P = CHARINDEX(N'CREATE', @D, @P + 1);
        END;
        IF @P = 0 BEGIN SELECT @NOM_X = NOMBRE FROM @M WHERE ID = @ID; PRINT 'FALLO no se encontro el CREATE de ' + ISNULL(@NOM_X, ''); SET @OK = 0; END
        ELSE IF @T NOT LIKE N'OR ALTER%' SET @D = STUFF(@D, @P, 6, N'ALTER');
        UPDATE @M SET DEF = @D WHERE ID = @ID;
        FETCH NEXT FROM CA INTO @ID, @D;
    END;
    CLOSE CA; DEALLOCATE CA;
END;

/* ---------- 2..4: renombrar y actualizar objetos, todo junto ---------- */
IF @OK = 1
BEGIN
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_VCT_AUDITORIA_DDL' AND parent_class = 0 AND is_disabled = 0)
    BEGIN
        DISABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
        SET @TRG = 1;
    END;

    DECLARE @NOM NVARCHAR(300), @NOM_N NVARCHAR(300), @TABLA NVARCHAR(300), @CLASE VARCHAR(10);
    BEGIN TRY
        BEGIN TRAN;

        IF @RENOMBRAR = 1
        BEGIN
            EXEC sp_rename N'dbo.VCT_PROYECTOS_DOCUMENTOS', N'VCT_PROYECTOS_DATOS';
            PRINT 'OK   tabla renombrada: dbo.VCT_PROYECTOS_DOCUMENTOS -> dbo.VCT_PROYECTOS_DATOS';
        END;

        /* claves, CHECK y DEFAULT de la tabla, y FK de otras tablas que la referencian */
        DECLARE CO CURSOR LOCAL STATIC READ_ONLY FOR
            SELECT SCHEMA_NAME(O.schema_id) + N'.' + O.name, REPLACE(O.name, @VIEJA, @NUEVA)
            FROM sys.objects O
            WHERE O.name LIKE N'%VCT[_]PROYECTOS[_]DOCUMENTOS%' AND O.name NOT LIKE N'%VCT[_]PROYECTOS[_]DOCUMENTOS[_]ITEMS%'
              AND O.type IN ('PK','UQ','F','C','D')
              AND (O.parent_object_id = OBJECT_ID(N'dbo.VCT_PROYECTOS_DATOS')
                   OR O.object_id IN (SELECT FK.object_id FROM sys.foreign_keys FK WHERE FK.referenced_object_id = OBJECT_ID(N'dbo.VCT_PROYECTOS_DATOS')));
        OPEN CO;
        FETCH NEXT FROM CO INTO @NOM, @NOM_N;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_rename @NOM, @NOM_N, N'OBJECT';
            PRINT 'OK   ' + @NOM + ' -> ' + @NOM_N;
            FETCH NEXT FROM CO INTO @NOM, @NOM_N;
        END;
        CLOSE CO; DEALLOCATE CO;

        /* indices (los de PK / UQ ya cambiaron con su clave) */
        DECLARE CI CURSOR LOCAL STATIC READ_ONLY FOR
            SELECT N'dbo.VCT_PROYECTOS_DATOS.' + I.name, REPLACE(I.name, @VIEJA, @NUEVA)
            FROM sys.indexes I
            WHERE I.object_id = OBJECT_ID(N'dbo.VCT_PROYECTOS_DATOS') AND I.name LIKE N'%VCT[_]PROYECTOS[_]DOCUMENTOS%'
              AND I.is_primary_key = 0 AND I.is_unique_constraint = 0;
        OPEN CI;
        FETCH NEXT FROM CI INTO @NOM, @NOM_N;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_rename @NOM, @NOM_N, N'INDEX';
            PRINT 'OK   indice ' + @NOM + ' -> ' + @NOM_N;
            FETCH NEXT FROM CI INTO @NOM, @NOM_N;
        END;
        CLOSE CI; DEALLOCATE CI;

        /* SP / triggers / funciones */
        DECLARE CX CURSOR LOCAL STATIC READ_ONLY FOR SELECT NOMBRE, DEF FROM @M ORDER BY CASE TIPO WHEN 'TR' THEN 1 ELSE 2 END, NOMBRE;
        OPEN CX;
        FETCH NEXT FROM CX INTO @NOM, @D;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_executesql @D;
            PRINT 'OK   ' + @NOM + ' usa dbo.VCT_PROYECTOS_DATOS';
            FETCH NEXT FROM CX INTO @NOM, @D;
        END;
        CLOSE CX; DEALLOCATE CX;

        COMMIT;
        PRINT 'OK   listo.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'FALLO ' + ISNULL(@NOM, '') + ': ' + ERROR_MESSAGE();
        PRINT 'No se aplico ningun cambio (la tabla y los objetos quedaron como estaban).';
    END CATCH;

    IF @TRG = 1 ENABLE TRIGGER TR_VCT_AUDITORIA_DDL ON DATABASE;
END;

/* control final: nada debe seguir nombrando la tabla vieja */
SELECT SCHEMA_NAME(O.schema_id) + '.' + O.name AS PENDIENTE, O.type
FROM sys.sql_modules M INNER JOIN sys.objects O ON O.object_id = M.object_id
WHERE M.[definition] LIKE N'%VCT[_]PROYECTOS[_]DOCUMENTOS[^A-Za-z0-9_]%';
