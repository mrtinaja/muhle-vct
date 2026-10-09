 
CREATE PROCEDURE [dbo].[M_CONFIG_ADD_TASK_GROUP]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE
        @V_GROUP_ID    VARCHAR(100),
        @V_SIDEBAR_ID  VARCHAR(100),
        @V_NEXT_ID     BIGINT,
        @V_GEN_ID      VARCHAR(100),
        @V_EXISTS      INT,
        @V_PERFIL_DESC VARCHAR(250),
        @V_MENU_DESC   VARCHAR(250),
        @V_DETALLE_LOG VARCHAR(500),
        @V_ERROR       NVARCHAR(500),
        @V_RESTO_MENU VARCHAR(101),
        @V_MENU_ITEM  VARCHAR(100),
        @V_MENU_UNICO VARCHAR(100),
        @V_POS_COMA   INT;
 
    SET @V_GROUP_ID = '';
    SET @V_SIDEBAR_ID = '';
    SET @V_EXISTS = 0;
 
    BEGIN TRY
        -- 1. Leer los valores recibidos.
        SELECT TOP (1)
            @V_GROUP_ID =
                LTRIM(RTRIM(ISNULL(ID_GROUP_SEL, ''))),
            @V_SIDEBAR_ID =
                LTRIM(RTRIM(ISNULL(ID_TASK_SEL, '')))
        FROM dbo.M_CONFIG
        WHERE PAR_KEY = @IPKEYJOB;
 
        IF @V_GROUP_ID = ''
            RAISERROR('Debe seleccionar un perfil.', 16, 1);
 
        IF CHARINDEX(',', @V_GROUP_ID) > 0
            RAISERROR(
                'El perfil llegó duplicado o contiene varios valores.',
                16, 1
            );
 
        -- 2. Normalizar repeticiones del mismo menú.
        -- Ejemplo: "4,4" -> "4".
        -- Valores diferentes, como "4,6", generan un error.
        SET @V_RESTO_MENU = ISNULL(@V_SIDEBAR_ID, '') + ',';
        SET @V_MENU_UNICO = '';
 
        WHILE LEN(@V_RESTO_MENU) > 0
        BEGIN
            SET @V_POS_COMA = CHARINDEX(',', @V_RESTO_MENU);
 
            IF @V_POS_COMA = 0
                BREAK;
 
            SET @V_MENU_ITEM =
                LTRIM(RTRIM(
                    LEFT(@V_RESTO_MENU, @V_POS_COMA - 1)
                ));
 
            SET @V_RESTO_MENU =
                SUBSTRING(@V_RESTO_MENU, @V_POS_COMA + 1, 101);
 
            IF @V_MENU_ITEM <> ''
            BEGIN
                IF @V_MENU_UNICO = ''
                    SET @V_MENU_UNICO = @V_MENU_ITEM;
                ELSE IF @V_MENU_UNICO <> @V_MENU_ITEM
                    RAISERROR(
                        'Se recibieron menús diferentes. Seleccione un solo menú.',
                        16, 1
                    );
            END;
        END;
 
        IF @V_MENU_UNICO = ''
            RAISERROR(
                'Debe seleccionar un menú para asociar.',
                16, 1
            );
 
        SET @V_SIDEBAR_ID = @V_MENU_UNICO;
 
        BEGIN TRANSACTION;
 
        -- 3. Validar que el perfil exista.
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Groups WITH (HOLDLOCK)
            WHERE Id = @V_GROUP_ID
        )
            RAISERROR(
                'El perfil seleccionado no existe.',
                16, 1
            );
 
        -- 4. Validar el ID real del menú.
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.SideBar WITH (HOLDLOCK)
            WHERE CONVERT(VARCHAR(100), Id) = @V_SIDEBAR_ID
        )
            RAISERROR(
                'El ID de menú recibido no existe en SideBar.',
                16, 1
            );
 
        -- 5. Bloquear durante el alta para evitar IDs repetidos.
        SELECT
            @V_EXISTS = ISNULL(MAX(
                CASE
                    WHEN LTRIM(RTRIM(GroupId)) = @V_GROUP_ID
                     AND LTRIM(RTRIM(
                         CONVERT(VARCHAR(100), SideBarId)
                     )) = @V_SIDEBAR_ID
                    THEN 1
                    ELSE 0
                END
            ), 0)
        FROM dbo.SideBarGroups WITH (TABLOCKX, HOLDLOCK);
 
        IF @V_EXISTS = 0
        BEGIN
            -- 6. Obtener el próximo ID numérico.
            DECLARE @IdsNumericos TABLE
            (
                Valor VARCHAR(100)
            );
 
            INSERT INTO @IdsNumericos (Valor)
            SELECT LTRIM(RTRIM(CONVERT(VARCHAR(100), Id)))
            FROM dbo.SideBarGroups;
 
            DELETE FROM @IdsNumericos
            WHERE Valor IS NULL
               OR Valor = ''
               OR Valor COLLATE Latin1_General_BIN LIKE '%[^0-9]%';
 
            -- Quitar ceros iniciales.
            WHILE EXISTS
            (
                SELECT 1
                FROM @IdsNumericos
                WHERE LEN(Valor) > 1
                  AND LEFT(Valor, 1) = '0'
            )
            BEGIN
                UPDATE @IdsNumericos
                SET Valor = SUBSTRING(Valor, 2, 100)
                WHERE LEN(Valor) > 1
                  AND LEFT(Valor, 1) = '0';
            END;
 
            -- Validar el rango antes de convertir y sumar.
            IF EXISTS
            (
                SELECT 1
                FROM @IdsNumericos
                WHERE LEN(Valor) > 19
                   OR
                   (
                       LEN(Valor) = 19
                       AND Valor COLLATE Latin1_General_BIN
                           >= '9223372036854775807'
                   )
            )
                RAISERROR(
                    'No se puede generar el siguiente ID: se excede el rango de BIGINT.',
                    16, 1
                );
 
            SELECT
                @V_NEXT_ID =
                    ISNULL(MAX(CONVERT(BIGINT, Valor)), 0) + 1
            FROM @IdsNumericos;
 
            SET @V_GEN_ID = CONVERT(VARCHAR(100), @V_NEXT_ID);
 
            -- 7. Guardar la asociación.
            INSERT INTO dbo.SideBarGroups
            (
                Id,
                SideBarId,
                GroupId,
                rowguid,
                ModifiedDate
            )
            VALUES
            (
                @V_GEN_ID,
                @V_SIDEBAR_ID,
                @V_GROUP_ID,
                NEWID(),
                GETDATE()
            );
 
            -- 8. Auditoría.
            SELECT TOP (1)
                @V_PERFIL_DESC = Name
            FROM dbo.Groups
            WHERE Id = @V_GROUP_ID;
 
            SELECT TOP (1)
                @V_MENU_DESC = Name
            FROM dbo.SideBar
            WHERE CONVERT(VARCHAR(100), Id) = @V_SIDEBAR_ID;
 
            SET @V_DETALLE_LOG = LEFT(
                'Menú "'
                + COALESCE(
                    NULLIF(@V_MENU_DESC, ''),
                    @V_SIDEBAR_ID
                )
                + '" asociado al perfil '
                + COALESCE(
                    NULLIF(@V_PERFIL_DESC, ''),
                    @V_GROUP_ID
                ),
                500
            );
 
            EXEC dbo.VCT_LOG_AUDITORIA
                @MODULO            = 'PERFIL_ADMIN',
                @ACCION            = 'ASOCIAR',
                @USER_ID           = @IUSERID,
                @REGISTRO_AFECTADO = @V_GROUP_ID,
                @DETALLE           = @V_DETALLE_LOG;
        END;
 
        -- 9. Limpiar solo cuando se guardó o ya existía.
        UPDATE dbo.M_CONFIG
        SET ID_TASK_SEL = NULL,
            NEW_ID      = NULL,
            DESC_ERROR  = NULL
        WHERE PAR_KEY = @IPKEYJOB;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @V_ERROR = LEFT(ERROR_MESSAGE(), 500);
 
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
 
        UPDATE dbo.M_CONFIG
        SET DESC_ERROR = @V_ERROR
        WHERE PAR_KEY = @IPKEYJOB;
 
        RAISERROR(N'%s', 16, 1, @V_ERROR);
        RETURN;
    END CATCH;
END;
