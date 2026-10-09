 
 
CREATE   PROCEDURE dbo.VCT_Sys_ABM_CAMPO_ENTIDAD
(
    @ACCION          VARCHAR(20),        -- AGREGAR / ELIMINAR
    @TABLA           VARCHAR(128),
    @CAMPO           VARCHAR(128),
 
    -- Se utilizan solamente para AGREGAR
    @TIPO_SQL        VARCHAR(30)  = NULL,
    @LARGO           INT          = NULL,
    @DECIMALES       INT          = 0,
    @ALIAS           VARCHAR(60)  = NULL,
 
    @USUARIO         VARCHAR(30)  = 'ADMINISTRADOR'
)
AS
BEGIN
 
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
 
    ---------------------------------------------------------------------------
    -- VARIABLES
    ---------------------------------------------------------------------------
 
    DECLARE @VPKEY_ENTITY        VARCHAR(36);
    DECLARE @VSQL                NVARCHAR(MAX);
 
    DECLARE @VFIELD_SEQ          INT;
 
    DECLARE @VSQL_TYPE           VARCHAR(30);
    DECLARE @VSQL_LENGTH         INT;
    DECLARE @VSQL_PRECISION      INT;
    DECLARE @VSQL_SCALE          INT;
 
    DECLARE @VFIELD_TYPE         VARCHAR(20);
    DECLARE @VFIELD_LENGTH       INT;
    DECLARE @VFIELD_DECIMALS     INT;
 
    DECLARE @VFIELD_ALIAS        VARCHAR(60);
 
 
    ---------------------------------------------------------------------------
    -- NORMALIZACIÓN
    ---------------------------------------------------------------------------
 
    SET @ACCION = UPPER(LTRIM(RTRIM(ISNULL(@ACCION, ''))));
    SET @TABLA  = LTRIM(RTRIM(ISNULL(@TABLA, '')));
    SET @CAMPO  = LTRIM(RTRIM(ISNULL(@CAMPO, '')));
 
    SET @TIPO_SQL =
        UPPER(LTRIM(RTRIM(ISNULL(@TIPO_SQL, ''))));
 
 
    ---------------------------------------------------------------------------
    -- VALIDACIONES GENERALES
    ---------------------------------------------------------------------------
 
    IF @ACCION NOT IN ('AGREGAR', 'ELIMINAR')
    BEGIN
        RAISERROR(
            'La accion debe ser AGREGAR o ELIMINAR.',
            16,
            1
        );
 
        RETURN;
    END;
 
 
    IF @TABLA = ''
    BEGIN
        RAISERROR(
            'Debe indicar el nombre de la tabla.',
            16,
            1
        );
 
        RETURN;
    END;
 
 
    IF @CAMPO = ''
    BEGIN
        RAISERROR(
            'Debe indicar el nombre del campo.',
            16,
            1
        );
 
        RETURN;
    END;
 
 
    ---------------------------------------------------------------------------
    -- VALIDAR EXISTENCIA DE TABLA
    ---------------------------------------------------------------------------
 
    IF OBJECT_ID('dbo.' + @TABLA, 'U') IS NULL
    BEGIN
        RAISERROR(
            'La tabla indicada no existe.',
            16,
            1
        );
 
        RETURN;
    END;
 
 
    ---------------------------------------------------------------------------
    -- RECUPERAR ENTITY_BROWSER.PKEY
    ---------------------------------------------------------------------------
 
    SELECT
        @VPKEY_ENTITY = PKEY
    FROM dbo.ENTITY_BROWSER
    WHERE ENTITY_TABLE_REL = @TABLA;
 
 
    IF ISNULL(@VPKEY_ENTITY, '') = ''
    BEGIN
        RAISERROR(
            'No existe configuración en ENTITY_BROWSER para la tabla indicada.',
            16,
            1
        );
 
        RETURN;
    END;
 
 
    ---------------------------------------------------------------------------
    -- TRANSACCIÓN
    ---------------------------------------------------------------------------
 
    BEGIN TRY
 
        BEGIN TRANSACTION;
 
 
        /***********************************************************************
         *
         *                            AGREGAR CAMPO
         *
         ***********************************************************************/
 
        IF @ACCION = 'AGREGAR'
        BEGIN
 
 
            -------------------------------------------------------------------
            -- VALIDAR QUE NO EXISTA EL CAMPO FÍSICAMENTE
            -------------------------------------------------------------------
 
            IF COL_LENGTH('dbo.' + @TABLA, @CAMPO) IS NOT NULL
            BEGIN
                RAISERROR(
                    'El campo ya existe físicamente en la tabla.',
                    16,
                    1
                );
            END;
 
 
            -------------------------------------------------------------------
            -- VALIDAR TIPO SQL
            -------------------------------------------------------------------
 
            IF @TIPO_SQL = ''
            BEGIN
                RAISERROR(
                    'Para agregar un campo debe indicar @TIPO_SQL.',
                    16,
                    1
                );
            END;
 
 
            -------------------------------------------------------------------
            -- ARMAR ALTER TABLE
            -------------------------------------------------------------------
 
            IF @TIPO_SQL IN ('VARCHAR', 'NVARCHAR', 'CHAR', 'NCHAR')
            BEGIN
 
                IF ISNULL(@LARGO, 0) <= 0
                BEGIN
                    RAISERROR(
                        'Para campos de texto debe indicar @LARGO.',
                        16,
                        1
                    );
                END;
 
 
                SET @VSQL =
                    N'ALTER TABLE dbo.' + QUOTENAME(@TABLA) +
                    N' ADD ' + QUOTENAME(@CAMPO) + N' ' +
                    @TIPO_SQL + N'(' +
                    CAST(@LARGO AS VARCHAR(10)) +
                    N') NULL;';
 
            END
            ELSE IF @TIPO_SQL IN ('DECIMAL', 'NUMERIC')
            BEGIN
 
                IF ISNULL(@LARGO, 0) <= 0
                BEGIN
                    RAISERROR(
                        'Para DECIMAL/NUMERIC debe indicar precision en @LARGO.',
                        16,
                        1
                    );
                END;
 
 
                SET @VSQL =
                    N'ALTER TABLE dbo.' + QUOTENAME(@TABLA) +
                    N' ADD ' + QUOTENAME(@CAMPO) + N' ' +
                    @TIPO_SQL + N'(' +
                    CAST(@LARGO AS VARCHAR(10)) + N',' +
                    CAST(ISNULL(@DECIMALES, 0) AS VARCHAR(10)) +
                    N') NULL;';
 
            END
            ELSE IF @TIPO_SQL IN
            (
                'INT',
                'BIGINT',
                'SMALLINT',
                'TINYINT',
                'BIT',
                'DATE',
                'DATETIME',
                'SMALLDATETIME',
                'DATETIME2',
                'FLOAT',
                'REAL',
                'MONEY',
                'SMALLMONEY',
                'UNIQUEIDENTIFIER'
            )
            BEGIN
 
                SET @VSQL =
                    N'ALTER TABLE dbo.' + QUOTENAME(@TABLA) +
                    N' ADD ' + QUOTENAME(@CAMPO) + N' ' +
                    @TIPO_SQL + N' NULL;';
 
            END
            ELSE
            BEGIN
 
                RAISERROR(
                    'El tipo SQL indicado todavía no está contemplado por el procedimiento.',
                    16,
                    1
                );
 
            END;
 
 
            -------------------------------------------------------------------
            -- CREAR CAMPO FÍSICO
            -------------------------------------------------------------------
 
            EXEC sp_executesql @VSQL;
 
 
            -------------------------------------------------------------------
            -- RECUPERAR INFORMACIÓN REAL DEL CAMPO DESDE SQL SERVER
            -------------------------------------------------------------------
 
            SELECT
                @VSQL_TYPE       = T.name,
                @VSQL_LENGTH     = C.max_length,
                @VSQL_PRECISION  = C.precision,
                @VSQL_SCALE      = C.scale
            FROM sys.columns C
            INNER JOIN sys.types T
                ON C.user_type_id = T.user_type_id
            WHERE
                C.object_id = OBJECT_ID('dbo.' + @TABLA)
                AND C.name = @CAMPO;
 
 
            IF @VSQL_TYPE IS NULL
            BEGIN
                RAISERROR(
                    'El campo fue creado pero no pudo recuperarse desde sys.columns.',
                    16,
                    1
                );
            END;
 
 
            -------------------------------------------------------------------
            -- CONVERSIÓN SQL SERVER -> FRAMEWORK MUHLE
            -------------------------------------------------------------------
 
            SET @VFIELD_TYPE =
                CASE
 
                    WHEN @VSQL_TYPE IN
                    (
                        'varchar',
                        'nvarchar',
                        'char',
                        'nchar',
                        'text',
                        'ntext'
                    )
                    THEN 'texto'
 
 
                    WHEN @VSQL_TYPE IN
                    (
                        'int',
                        'bigint',
                        'smallint',
                        'tinyint'
                    )
                    THEN 'numero'
 
 
                    WHEN @VSQL_TYPE IN
                    (
                        'decimal',
                        'numeric',
                        'float',
                        'real',
                        'money',
                        'smallmoney'
                    )
                    THEN 'numero'
 
 
                    WHEN @VSQL_TYPE = 'bit'
                    THEN 'logico'
 
 
                    WHEN @VSQL_TYPE IN
                    (
                        'date',
                        'datetime',
                        'smalldatetime',
                        'datetime2'
                    )
                    THEN 'fecha'
 
 
                    WHEN @VSQL_TYPE = 'uniqueidentifier'
                    THEN 'texto'
 
 
                    ELSE 'texto'
 
                END;
 
 
            -------------------------------------------------------------------
            -- FIELD_LENGTH
            -------------------------------------------------------------------
 
            SET @VFIELD_LENGTH =
                CASE
 
                    WHEN @VSQL_TYPE IN ('nvarchar', 'nchar')
                        THEN
                            CASE
                                WHEN @VSQL_LENGTH = -1 THEN 0
                                ELSE @VSQL_LENGTH / 2
                            END
 
                    WHEN @VSQL_TYPE IN
                    (
                        'varchar',
                        'char'
                    )
                        THEN
                            CASE
                                WHEN @VSQL_LENGTH = -1 THEN 0
                                ELSE @VSQL_LENGTH
                            END
 
                    WHEN @VSQL_TYPE IN
                    (
                        'decimal',
                        'numeric'
                    )
                        THEN @VSQL_PRECISION
 
                    WHEN @VSQL_TYPE IN
                    (
                        'int',
                        'bigint',
                        'smallint',
                        'tinyint'
                    )
                        THEN @VSQL_PRECISION
 
                    ELSE 0
 
                END;
 
 
            -------------------------------------------------------------------
            -- FIELD_DECIMALS
            -------------------------------------------------------------------
 
            SET @VFIELD_DECIMALS =
                CASE
 
                    WHEN @VSQL_TYPE IN
                    (
                        'decimal',
                        'numeric'
                    )
                        THEN @VSQL_SCALE
 
                    ELSE 0
 
                END;
 
 
            -------------------------------------------------------------------
            -- ALIAS
            -------------------------------------------------------------------
 
            SET @VFIELD_ALIAS =
                ISNULL(
                    NULLIF(LTRIM(RTRIM(@ALIAS)), ''),
                    @CAMPO
                );
 
 
            -------------------------------------------------------------------
            -- PRÓXIMO FIELD_SEQ
            -------------------------------------------------------------------
 
            SELECT
                @VFIELD_SEQ =
                    ISNULL(MAX(FIELD_SEQ), 0) + 1
            FROM dbo.ENTITY_BROWSER_DETAIL
            WHERE PAR_KEY = @VPKEY_ENTITY;
 
 
            -------------------------------------------------------------------
            -- INSERTAR METADATA
            -------------------------------------------------------------------
 
            INSERT INTO dbo.ENTITY_BROWSER_DETAIL
            (
                PKEY,
                PAR_KEY,
 
                TS_BEGIN,
                TS_END,
 
                FIELD_NAME,
                FIELD_ALIAS,
                FIELD_SEQ,
 
                ENABLED,
                FIELD_TYPE,
                FIELD_LENGTH,
                FIELD_DECIMALS,
                FIELD_KEY,
 
                VAL_TBL_NAME,
 
                SOURCE_TYPE,
                SOURCE_FIELD_NAME,
                SOURCE_TYPE_CODE,
 
                NORMALIZE_NAME,
 
                TS_USER_ID,
 
                VAL_TBL_FILTER,
                MANDATORY_IDR,
                SUGERENCIA_IDR,
                SUMARIZA_IDR,
                PRM_IDR,
 
                DEF_VAL,
 
                GROUP_TBL_NAME,
                GROUP_VAL,
 
                FIELD_DEFAULT,
 
                TS_CREATED_USER_ID,
                FIELD_MASK
            )
            VALUES
            (
                CONVERT(VARCHAR(36), NEWID()),
                @VPKEY_ENTITY,
 
                GETDATE(),
                GETDATE(),
 
                @CAMPO,
                @VFIELD_ALIAS,
                @VFIELD_SEQ,
 
                '0',
                @VFIELD_TYPE,
                @VFIELD_LENGTH,
                @VFIELD_DECIMALS,
                '0',
 
                NULL,
 
                'Entidad',
                NULL,
                'VCT Gestion',
 
                NULL,
 
                @USUARIO,
 
                'NO',
                '0',
                'NO',
                '0',
                '0',
 
                NULL,
 
                NULL,
                NULL,
 
                NULL,
 
                @USUARIO,
                ';;'
            );
 
 
        END;
 
 
 
        /***********************************************************************
         *
         *                           ELIMINAR CAMPO
         *
         ***********************************************************************/
 
        IF @ACCION = 'ELIMINAR'
        BEGIN
 
 
            -------------------------------------------------------------------
            -- FIELD_KEY NO SE PUEDE ELIMINAR DESDE ESTE SP
            -------------------------------------------------------------------
 
            IF EXISTS
            (
                SELECT 1
                FROM dbo.ENTITY_BROWSER_DETAIL
                WHERE
                    PAR_KEY = @VPKEY_ENTITY
                    AND FIELD_NAME = @CAMPO
                    AND FIELD_KEY = '1'
            )
            BEGIN
 
                RAISERROR(
                    'El campo está definido como FIELD_KEY y debe administrarse manualmente.',
                    16,
                    1
                );
 
            END;
 
 
            -------------------------------------------------------------------
            -- VALIDAR EXISTENCIA FÍSICA
            -------------------------------------------------------------------
 
            IF COL_LENGTH('dbo.' + @TABLA, @CAMPO) IS NULL
            BEGIN
 
                RAISERROR(
                    'El campo indicado no existe físicamente en la tabla.',
                    16,
                    1
                );
 
            END;
 
 
            -------------------------------------------------------------------
            -- ELIMINAR CAMPO SQL
            -------------------------------------------------------------------
 
            SET @VSQL =
                N'ALTER TABLE dbo.' + QUOTENAME(@TABLA) +
                N' DROP COLUMN ' + QUOTENAME(@CAMPO) + N';';
 
 
            EXEC sp_executesql @VSQL;
 
 
            -------------------------------------------------------------------
            -- ELIMINAR METADATA
            -------------------------------------------------------------------
 
            DELETE
            FROM dbo.ENTITY_BROWSER_DETAIL
            WHERE
                PAR_KEY = @VPKEY_ENTITY
                AND FIELD_NAME = @CAMPO;
 
 
        END;
 
 
        -----------------------------------------------------------------------
        -- COMMIT
        -----------------------------------------------------------------------
 
        COMMIT TRANSACTION;
 
 
        -----------------------------------------------------------------------
        -- RESULTADO
        -----------------------------------------------------------------------
 
        SELECT
            RESULTADO       = 'OK',
            ACCION          = @ACCION,
            TABLA           = @TABLA,
            CAMPO           = @CAMPO,
            PKEY_ENTITY     = @VPKEY_ENTITY,
            FIELD_TYPE      = @VFIELD_TYPE,
            FIELD_LENGTH    = @VFIELD_LENGTH,
            FIELD_DECIMALS  = @VFIELD_DECIMALS,
            FIELD_SEQ       = @VFIELD_SEQ;
 
 
    END TRY
    BEGIN CATCH
 
 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
 
 
        DECLARE @ERROR VARCHAR(MAX);
 
        SET @ERROR =
            'Error en VCT_ABM_CAMPO_ENTIDAD: ' +
            ERROR_MESSAGE();
 
 
        RAISERROR(
            @ERROR,
            16,
            1
        );
 
 
    END CATCH;
 
 
END
