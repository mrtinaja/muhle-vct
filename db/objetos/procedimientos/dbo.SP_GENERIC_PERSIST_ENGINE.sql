 
/* ==========================================================================
   🎯 MOTOR DE PERSISTENCIA Y CRUD GENÉRICO DINÁMICO - MÜHLE PLATFORM (v2.2)
   Procedimiento: SP_GENERIC_PERSIST_ENGINE
   ========================================================================== */
CREATE PROCEDURE [dbo].[SP_GENERIC_PERSIST_ENGINE]
(
    @IPKEYJOB        VARCHAR(100)  = NULL,              -- Clave única de trabajo / sesión (PAR_KEY)
    @IUSERID         VARCHAR(100)  = NULL,              -- Usuario operador
    @BUFFER_TABLE    VARCHAR(128)  = 'M_CONFIG',        -- Tabla Buffer / Staging (Default: M_CONFIG)
    @TARGET_TABLE    VARCHAR(128)  = 'M_USERS',         -- Tabla Destino real en la BD (Default: M_USERS)
    @PK_FIELD_SEL    VARCHAR(128)  = 'ID_USER_SEL',     -- Columna en Buffer con PK (Default: ID_USER_SEL)
    @TARGET_PK_FIELD VARCHAR(128)  = 'USER_ID',         -- Columna PK real en Tabla Destino
    @ACTION_MODE     VARCHAR(20)   = 'UPSERT',          -- Modo: 'UPSERT' | 'DELETE' | 'LOGICAL_DELETE'
    @SOFT_DEL_FIELD  VARCHAR(128)  = 'IsDeleted',       -- Campo de baja lógica
    @O_RETCODE       INT           = 0 OUTPUT,          -- Código de retorno
    @O_DESC_ERROR    NVARCHAR(4000) = '' OUTPUT        -- Mensaje descriptivo
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @O_RETCODE = 0;
    SET @O_DESC_ERROR = 'OK';
 
    -----------------------------------------------------------------------------------------
    -- 0. SANEAMIENTO Y ASIGNACIÓN DE VALORES POR DEFECTO
    -----------------------------------------------------------------------------------------
    SET @BUFFER_TABLE    = ISNULL(NULLIF(RTRIM(LTRIM(@BUFFER_TABLE)), ''), 'M_CONFIG');
    SET @TARGET_TABLE    = ISNULL(NULLIF(RTRIM(LTRIM(@TARGET_TABLE)), ''), 'M_USERS');
    SET @PK_FIELD_SEL    = ISNULL(NULLIF(RTRIM(LTRIM(@PK_FIELD_SEL)), ''), 'ID_USER_SEL');
    SET @TARGET_PK_FIELD = ISNULL(NULLIF(RTRIM(LTRIM(@TARGET_PK_FIELD)), ''), 'USER_ID');
    SET @ACTION_MODE     = ISNULL(NULLIF(RTRIM(LTRIM(@ACTION_MODE)), ''), 'UPSERT');
 
    -- Sanitización de Identificadores SQL
    DECLARE @Q_BUFFER    NVARCHAR(258) = QUOTENAME(@BUFFER_TABLE);
    DECLARE @Q_TARGET    NVARCHAR(258) = QUOTENAME(@TARGET_TABLE);
    DECLARE @Q_PK_SEL    NVARCHAR(258) = QUOTENAME(@PK_FIELD_SEL);
    DECLARE @Q_TARGET_PK NVARCHAR(258) = QUOTENAME(@TARGET_PK_FIELD);
    
    DECLARE @PK_VALUE NVARCHAR(255) = NULL;
 
    -----------------------------------------------------------------------------------------
    -- 1. LECTURA DINÁMICA DE LA PK EN LA TABLA BUFFER
    -----------------------------------------------------------------------------------------
    DECLARE @SQL_READ_PK NVARCHAR(MAX) = 
        N'SELECT TOP 1 @PK_OUT = CONVERT(NVARCHAR(255), ' + @Q_PK_SEL + N') ' +
        N'FROM dbo.' + @Q_BUFFER + N' WITH (NOLOCK) WHERE PAR_KEY = @KEY;';
 
    BEGIN TRY
        EXEC sp_executesql 
            @SQL_READ_PK, 
            N'@KEY VARCHAR(100), @PK_OUT NVARCHAR(255) OUTPUT', 
            @KEY = @IPKEYJOB, 
            @PK_OUT = @PK_VALUE OUTPUT;
    END TRY
    BEGIN CATCH
        SET @O_RETCODE = -1;
        SET @O_DESC_ERROR = N'Error al leer [' + @PK_FIELD_SEL + N'] desde la tabla buffer [' + @BUFFER_TABLE + N']: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
 
    -- Si la PK viene nula o vacía (caso Alta Nueva), intentamos leer 'NEW_ID' como fallback de la PK
    IF ISNULL(@PK_VALUE, '') = ''
    BEGIN
        DECLARE @SQL_READ_NEW_ID NVARCHAR(MAX) = 
            N'SELECT TOP 1 @PK_OUT = CONVERT(NVARCHAR(255), [NEW_ID]) ' +
            N'FROM dbo.' + @Q_BUFFER + N' WITH (NOLOCK) WHERE PAR_KEY = @KEY;';
 
        BEGIN TRY
            EXEC sp_executesql 
                @SQL_READ_NEW_ID, 
                N'@KEY VARCHAR(100), @PK_OUT NVARCHAR(255) OUTPUT', 
                @KEY = @IPKEYJOB, 
                @PK_OUT = @PK_VALUE OUTPUT;
        END TRY
        BEGIN CATCH
            -- Si no existe la columna NEW_ID, se ignora la excepción
            SET @PK_VALUE = NULL;
        END CATCH
    END
 
    -----------------------------------------------------------------------------------------
    -- 2. OPERACIONES DE ELIMINACIÓN (DELETE / LOGICAL_DELETE)
    -----------------------------------------------------------------------------------------
    IF UPPER(@ACTION_MODE) = 'DELETE'
    BEGIN
        IF ISNULL(@PK_VALUE, '') = ''
        BEGIN
            SET @O_RETCODE = -1;
            SET @O_DESC_ERROR = N'Borrado cancelado: No se especificó PK en el buffer.';
            RETURN;
        END
 
        BEGIN TRANSACTION;
        BEGIN TRY
            DECLARE @SQL_DEL NVARCHAR(MAX) = 
                N'DELETE FROM dbo.' + @Q_TARGET + N' WHERE ' + @Q_TARGET_PK + N' = @PK_VAL;';
            
            EXEC sp_executesql @SQL_DEL, N'@PK_VAL NVARCHAR(255)', @PK_VAL = @PK_VALUE;
 
            -- Limpieza del buffer
            DECLARE @SQL_CLEAN_DEL NVARCHAR(MAX) = N'DELETE FROM dbo.' + @Q_BUFFER + N' WHERE PAR_KEY = @KEY;';
            EXEC sp_executesql @SQL_CLEAN_DEL, N'@KEY VARCHAR(100)', @KEY = @IPKEYJOB;
 
            COMMIT TRANSACTION;
            SET @O_RETCODE = 0;
            SET @O_DESC_ERROR = 'OK';
            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @O_RETCODE = ERROR_NUMBER();
            SET @O_DESC_ERROR = N'Error en borrado físico en [' + @TARGET_TABLE + N']: ' + ERROR_MESSAGE();
            RETURN;
        END CATCH
    END
 
    IF UPPER(@ACTION_MODE) = 'LOGICAL_DELETE'
    BEGIN
        IF ISNULL(@PK_VALUE, '') = ''
        BEGIN
            SET @O_RETCODE = -1;
            SET @O_DESC_ERROR = N'Borrado lógico cancelado: No se especificó PK en el buffer.';
            RETURN;
        END
 
        BEGIN TRANSACTION;
        BEGIN TRY
            DECLARE @Q_SOFT_DEL NVARCHAR(258) = QUOTENAME(@SOFT_DEL_FIELD);
            DECLARE @SQL_SOFT_DEL NVARCHAR(MAX) = 
                N'UPDATE dbo.' + @Q_TARGET + N' SET ' + @Q_SOFT_DEL + N' = 1 ' +
                CASE WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.' + @TARGET_TABLE) AND name = 'ModifiedDate') 
                     THEN N', [ModifiedDate] = GETDATE() ' ELSE N'' END +
                N'WHERE ' + @Q_TARGET_PK + N' = @PK_VAL;';
 
            EXEC sp_executesql @SQL_SOFT_DEL, N'@PK_VAL NVARCHAR(255)', @PK_VAL = @PK_VALUE;
 
            -- Limpieza del buffer
            DECLARE @SQL_CLEAN_SOFT NVARCHAR(MAX) = N'DELETE FROM dbo.' + @Q_BUFFER + N' WHERE PAR_KEY = @KEY;';
            EXEC sp_executesql @SQL_CLEAN_SOFT, N'@KEY VARCHAR(100)', @KEY = @IPKEYJOB;
 
            COMMIT TRANSACTION;
            SET @O_RETCODE = 0;
            SET @O_DESC_ERROR = 'OK';
            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SET @O_RETCODE = ERROR_NUMBER();
            SET @O_DESC_ERROR = N'Error en borrado lógico en [' + @TARGET_TABLE + N']: ' + ERROR_MESSAGE();
            RETURN;
        END CATCH
    END
 
    -----------------------------------------------------------------------------------------
    -- 3. MAPEO AUTOMÁTICO DE COLUMNAS (BUFFER <-> TARGET)
    -----------------------------------------------------------------------------------------
    DECLARE @SET_CLAUSE NVARCHAR(MAX) = N'';
    DECLARE @INSERT_COLS NVARCHAR(MAX) = N'';
    DECLARE @SELECT_COLS NVARCHAR(MAX) = N'';
 
    SELECT 
        -- Cláusula SET para UPDATE
        @SET_CLAUSE = @SET_CLAUSE + 
            CASE WHEN @SET_CLAUSE = '' THEN '' ELSE ', ' END +
            N'T.' + QUOTENAME(cTarget.name) + N' = B.' + QUOTENAME(cBuffer.name),
        
        -- Columnas destino para INSERT
        @INSERT_COLS = @INSERT_COLS + 
            CASE WHEN @INSERT_COLS = '' THEN '' ELSE ', ' END +
            QUOTENAME(cTarget.name),
 
        -- Columnas origen desde Buffer para INSERT
        @SELECT_COLS = @SELECT_COLS + 
            CASE WHEN @SELECT_COLS = '' THEN '' ELSE ', ' END +
            N'B.' + QUOTENAME(cBuffer.name)
 
    FROM sys.columns cTarget
    INNER JOIN sys.columns cBuffer 
        ON (
            cBuffer.name = cTarget.name 
            OR cBuffer.name = 'NEW_' + cTarget.name
        )
    WHERE cTarget.object_id = OBJECT_ID('dbo.' + @TARGET_TABLE)
      AND cBuffer.object_id = OBJECT_ID('dbo.' + @BUFFER_TABLE)
      -- Excluimos PKs, auditorías fijas e identidades
      AND cTarget.name NOT IN (@TARGET_PK_FIELD, 'CreationDate', 'rowguid')
      AND cTarget.is_identity = 0;
 
    IF ISNULL(@SET_CLAUSE, '') = ''
    BEGIN
        SET @O_RETCODE = -2;
        SET @O_DESC_ERROR = N'Error de esquema: No se encontraron columnas coincidentes entre [' + @BUFFER_TABLE + N'] y [' + @TARGET_TABLE + N']';
        RETURN;
    END
 
    -- Auditoría de modificación
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.' + @TARGET_TABLE) AND name = 'ModifiedDate')
    BEGIN
        SET @SET_CLAUSE = @SET_CLAUSE + N', T.[ModifiedDate] = GETDATE()';
    END
 
    -----------------------------------------------------------------------------------------
    -- 4. DECISIÓN AUTOMÁTICA UPSERT (UPDATE VS INSERT)
    -----------------------------------------------------------------------------------------
    DECLARE @EXISTS_IN_TARGET BIT = 0;
 
    IF ISNULL(@PK_VALUE, '') <> ''
    BEGIN
        DECLARE @SQL_CHECK NVARCHAR(MAX) = 
            N'IF EXISTS (SELECT 1 FROM dbo.' + @Q_TARGET + N' WHERE ' + @Q_TARGET_PK + N' = @PK_VAL) ' +
            N'  SET @EXISTS_OUT = 1; ELSE SET @EXISTS_OUT = 0;';
 
        EXEC sp_executesql 
            @SQL_CHECK, 
            N'@PK_VAL NVARCHAR(255), @EXISTS_OUT BIT OUTPUT', 
            @PK_VAL = @PK_VALUE, 
            @EXISTS_OUT = @EXISTS_IN_TARGET OUTPUT;
    END
 
    DECLARE @SQL_PERSIST NVARCHAR(MAX) = N'';
 
    IF @EXISTS_IN_TARGET = 1
    BEGIN
        -- MODO UPDATE
        SET @SQL_PERSIST = 
            N'UPDATE T ' +
            N'SET ' + @SET_CLAUSE + N' ' +
            N'FROM dbo.' + @Q_TARGET + N' T ' +
            N'INNER JOIN dbo.' + @Q_BUFFER + N' B ON B.PAR_KEY = @KEY ' +
            N'WHERE T.' + @Q_TARGET_PK + N' = @PK_VAL;';
    END
    ELSE
    BEGIN
        -- MODO INSERT (ALTA)
        IF EXISTS (
            SELECT 1 FROM sys.columns 
            WHERE object_id = OBJECT_ID('dbo.' + @TARGET_TABLE) 
              AND name = @TARGET_PK_FIELD 
              AND is_identity = 0
        )
        BEGIN
            SET @INSERT_COLS = @Q_TARGET_PK + N', ' + @INSERT_COLS;
            SET @SELECT_COLS = N'@PK_VAL, ' + @SELECT_COLS;
        END
 
        SET @SQL_PERSIST = 
            N'INSERT INTO dbo.' + @Q_TARGET + N' (' + @INSERT_COLS + N') ' +
            N'SELECT ' + @SELECT_COLS + N' ' +
            N'FROM dbo.' + @Q_BUFFER + N' B ' +
            N'WHERE B.PAR_KEY = @KEY;';
    END
 
    -----------------------------------------------------------------------------------------
    -- 5. TRANSACCIONALIDAD Y LIMPIEZA
    -----------------------------------------------------------------------------------------
    BEGIN TRANSACTION;
    BEGIN TRY
 
        EXEC sp_executesql 
            @SQL_PERSIST, 
            N'@KEY VARCHAR(100), @PK_VAL NVARCHAR(255)', 
            @KEY = @IPKEYJOB, 
            @PK_VAL = @PK_VALUE;
 
        -- Limpieza del buffer utilizado
        DECLARE @SQL_CLEAN NVARCHAR(MAX) = N'DELETE FROM dbo.' + @Q_BUFFER + N' WHERE PAR_KEY = @KEY;';
        EXEC sp_executesql @SQL_CLEAN, N'@KEY VARCHAR(100)', @KEY = @IPKEYJOB;
 
        COMMIT TRANSACTION;
        SET @O_RETCODE = 0;
        SET @O_DESC_ERROR = 'OK';
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @O_RETCODE = ERROR_NUMBER();
        SET @O_DESC_ERROR = N'Error en SP_GENERIC_PERSIST_ENGINE [' + ERROR_PROCEDURE() + N' Line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + N']: ' + ERROR_MESSAGE();
    END CATCH
END
