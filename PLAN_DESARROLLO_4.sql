/* ============================================================================
   PLAN_DESARROLLO_4  (27/10/2026)  marca PL_DES_V4  -- requiere PLAN_DESARROLLO_3 aplicado
   ----------------------------------------------------------------------------
   Eliminar una accion del plan (solo si NO tiene desarrollo realizado) la borra del arbol:
   la accion, su historial, participantes y desarrollo planificado. Tambien para las canceladas.
   Sin cambios de css / js.
   Si alguno de los puntos no se encuentra en la definicion vigente, NO se cambia nada.
   Re-ejecutable: si la marca PL_DES_V4 ya esta, avisa y no hace nada.  SSMS: F5.
   ============================================================================ */
USE [MuhlePROD];
SET NOCOUNT ON;
GO
DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),
        @NE NVARCHAR(MAX), @RE NVARCHAR(MAX), @N INT, @F NVARCHAR(MAX) = N'', @s INT, @p INT;
IF @D IS NULL
    PRINT 'FALLO: no se encontro dbo.VCT_MAIN_PROYECTO_V360.';
ELSE IF CHARINDEX(N'PL_DES_V4', @D) > 0
    PRINT 'OK   el parche PL_DES_V4 ya estaba aplicado: no se hizo nada.';
ELSE IF CHARINDEX(N'PL_DES_V3', @D) = 0
    PRINT 'FALLO: falta aplicar antes PLAN_DESARROLLO_3.sql. No se cambio nada.';
ELSE
BEGIN
    SET @D = REPLACE(@D, NCHAR(13) + NCHAR(10), NCHAR(10));
    /* borrar */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'                    /* no se borra fisicamente (tiene historial y participantes): queda CANCELADA y sale del plan */' + NCHAR(10) + N'                    UPDATE dbo.VCT_ACCIONES SET ID_ESTADO = @PL_CANC, FECHA_CIERRE = GETDATE(), FECHA_UPD = GETDATE(), USUARIO_UPD = @IAGENTE WHERE ID = @PL_ACC;' + NCHAR(10) + N'                    INSERT INTO dbo.VCT_ACCIONES_HISTORIAL (ID_ACCION, ID_ESTADO_ANTERIOR, ID_ESTADO_NUEVO, ACCION, DESCRIPCION, TIPO_ACTOR, FECHA, USUARIO)' + NCHAR(10) + N'                    VALUES (@PL_ACC, @PL_ACC_EST, @PL_CANC, ''ELIMINADA'', ''Acci'' + CHAR(243) + ''n eliminada del plan estrat'' + CHAR(233) + ''gico.'', ''USUARIO'', GETDATE(), @IAGENTE);' + NCHAR(10) + N'                    SET @MSG = ''Acci'' + CHAR(243) + ''n eliminada.'';';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'                    /* PL_DES_V4: sin desarrollo realizado (validado antes) se borra del todo: la accion, sus tablas VCT_ACCIONES_*' + NCHAR(10) + N'                       (historial, participantes, desarrollo planificado...) y, en otras tablas, la referencia si admite nulo */' + NCHAR(10) + N'                    UPDATE dbo.VCT_ACCIONES SET ID_ACCION_PADRE = NULL WHERE ID_ACCION_PADRE = @PL_ACC;' + NCHAR(10) + N'                    DECLARE @AX_SQL NVARCHAR(MAX), @AX_T NVARCHAR(300), @AX_N SYSNAME, @AX_C NVARCHAR(200), @AX_NUL BIT;' + NCHAR(10) + N'                    DECLARE ax CURSOR LOCAL FAST_FORWARD FOR' + NCHAR(10) + N'                        SELECT QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N''.'' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)), OBJECT_NAME(fk.parent_object_id), QUOTENAME(c.name), c.is_nullable' + NCHAR(10) + N'                        FROM sys.foreign_keys fk' + NCHAR(10) + N'                        INNER JOIN sys.foreign_key_columns k ON k.constraint_object_id = fk.object_id' + NCHAR(10) + N'                        INNER JOIN sys.columns c ON c.object_id = k.parent_object_id AND c.column_id = k.parent_column_id' + NCHAR(10) + N'                        WHERE fk.referenced_object_id = OBJECT_ID(''dbo.VCT_ACCIONES'') AND fk.parent_object_id <> fk.referenced_object_id' + NCHAR(10) + N'                          AND (SELECT COUNT(*) FROM sys.foreign_key_columns k2 WHERE k2.constraint_object_id = fk.object_id) = 1;' + NCHAR(10) + N'                    OPEN ax;' + NCHAR(10) + N'                    FETCH NEXT FROM ax INTO @AX_T, @AX_N, @AX_C, @AX_NUL;' + NCHAR(10) + N'                    WHILE @@FETCH_STATUS = 0' + NCHAR(10) + N'                    BEGIN' + NCHAR(10) + N'                        IF @AX_N LIKE ''VCT[_]ACCIONES[_]%''' + NCHAR(10) + N'                            SET @AX_SQL = N''DELETE FROM '' + @AX_T + N'' WHERE '' + @AX_C + N'' = @A;''' + NCHAR(10) + N'                        ELSE IF @AX_NUL = 1' + NCHAR(10) + N'                            SET @AX_SQL = N''UPDATE '' + @AX_T + N'' SET '' + @AX_C + N'' = NULL WHERE '' + @AX_C + N'' = @A;''' + NCHAR(10) + N'                        ELSE' + NCHAR(10) + N'                            SET @AX_SQL = N''IF EXISTS (SELECT 1 FROM '' + @AX_T + N'' WHERE '' + @AX_C + N'' = @A) RAISERROR(''''La tabla '' + REPLACE(@AX_N, '''''''', '''') + N'' depende de la acci'' + NCHAR(243) + N''n.'''', 16, 1);'';' + NCHAR(10) + N'                        EXEC sys.sp_executesql @AX_SQL, N''@A INT'', @A = @PL_ACC;' + NCHAR(10) + N'                        FETCH NEXT FROM ax INTO @AX_T, @AX_N, @AX_C, @AX_NUL;' + NCHAR(10) + N'                    END;' + NCHAR(10) + N'                    CLOSE ax;' + NCHAR(10) + N'                    DEALLOCATE ax;' + NCHAR(10) + N'                    IF OBJECT_ID(''dbo.VCT_ACCIONES_DESARROLLO'', ''U'') IS NOT NULL DELETE FROM dbo.VCT_ACCIONES_DESARROLLO WHERE ID_ACCION = @PL_ACC;' + NCHAR(10) + N'                    DELETE FROM dbo.VCT_ACCIONES_HISTORIAL WHERE ID_ACCION = @PL_ACC;' + NCHAR(10) + N'                    DELETE FROM dbo.VCT_ACCIONES_PARTICIPANTES WHERE ID_ACCION = @PL_ACC;' + NCHAR(10) + N'                    DELETE FROM dbo.VCT_ACCIONES WHERE ID = @PL_ACC;' + NCHAR(10) + N'                    SET @MSG = ''Acci'' + CHAR(243) + ''n eliminada del plan.'';';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' borrar(' + CONVERT(NVARCHAR(10), @N) + N')';
    /* menu_del */
    SET @NE = CONVERT(NVARCHAR(MAX), N'')+ N'CASE WHEN A.CANC = 0 AND ISNULL(A.ND, 0) = 0 THEN ''<button';
    SET @RE = CONVERT(NVARCHAR(MAX), N'')+ N'CASE WHEN ISNULL(A.ND, 0) = 0 THEN ''<button';
    SET @N = (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, @NE, N''))) / DATALENGTH(@NE);
    IF @N = 1 SET @D = REPLACE(@D, @NE, @RE); ELSE SET @F = @F + N' menu_del(' + CONVERT(NVARCHAR(10), @N) + N')';
    IF @F <> N''
        PRINT 'FALLO: no se encontraron en la definicion vigente los puntos:' + @F + '. No se cambio nada.';
    ELSE
    BEGIN
        SET @s = CHARINDEX(N'PROCEDURE', @D);
        SET @p = CASE WHEN @s > 40 THEN @s - 40 ELSE 1 END;
        IF CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) > 0 AND CHARINDEX(N'OR ALTER', SUBSTRING(@D, @p, 40)) = 0
            SET @D = STUFF(@D, @p + CHARINDEX(N'CREATE', SUBSTRING(@D, @p, 40)) - 1, 6, N'ALTER ');
        BEGIN TRY
            EXEC sys.sp_executesql @D;
            PRINT 'OK   VCT_MAIN_PROYECTO_V360 actualizado (PL_DES_V4).';
        END TRY
        BEGIN CATCH
            PRINT 'FALLO al actualizar VCT_MAIN_PROYECTO_V360 (no se cambio): ' + ERROR_MESSAGE() + ' (linea ' + CONVERT(VARCHAR(10), ERROR_LINE()) + ')';
        END CATCH;
    END;
END;
GO
