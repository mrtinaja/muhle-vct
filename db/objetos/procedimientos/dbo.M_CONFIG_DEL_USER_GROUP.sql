 
CREATE PROCEDURE [dbo].[M_CONFIG_DEL_USER_GROUP]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100)
)
AS
BEGIN   
    SET NOCOUNT ON;
 
    DECLARE @ID_USER_DEL  VARCHAR(100) = '',
            @ID_GROUP_SEL VARCHAR(100) = '';
 
    -- 1. Leer variables desde M_CONFIG sin bloqueos
    SELECT TOP 1
        @ID_USER_DEL  = ISNULL(ID_DELETE, ''), 
        @ID_GROUP_SEL = ISNULL(ID_GROUP_SEL, '')  
    FROM dbo.M_CONFIG WITH (READUNCOMMITTED) 
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- 2. Limpieza de comas duplicadas (ej: "rabosaleh,rabosaleh")
    IF CHARINDEX(',', @ID_USER_DEL) > 0
    BEGIN
        SET @ID_USER_DEL = LEFT(@ID_USER_DEL, CHARINDEX(',', @ID_USER_DEL) - 1);
    END
 
    IF CHARINDEX(',', @ID_GROUP_SEL) > 0
    BEGIN
        SET @ID_GROUP_SEL = LEFT(@ID_GROUP_SEL, CHARINDEX(',', @ID_GROUP_SEL) - 1);
    END
 
    -- 3. Saneo de comillas y espacios
    SET @ID_USER_DEL  = LTRIM(RTRIM(REPLACE(REPLACE(ISNULL(@ID_USER_DEL, ''), '''', ''), '"', '')));
    SET @ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(ISNULL(@ID_GROUP_SEL, ''), '''', ''), '"', '')));
 
    -- Validación preventiva
    IF @ID_USER_DEL = '' OR @ID_GROUP_SEL = '' RETURN;
 
    -- 4. Transacción de Desvinculación
    BEGIN TRANSACTION;
        BEGIN TRY
 
            -- Eliminar relación Grupo-Usuario sin importar Mayúsculas/Minúsculas
            DELETE FROM dbo.GroupsUserMembers 
            WHERE UPPER(LTRIM(RTRIM(GroupId))) = UPPER(@ID_GROUP_SEL) 
              AND UPPER(LTRIM(RTRIM(UserMemberId))) = UPPER(@ID_USER_DEL);
            
            -- Si el perfil desvinculado es Administrador de Sistema, remover roles
            IF UPPER(@ID_GROUP_SEL) = 'SYS_ADM'
            BEGIN
                DELETE FROM dbo.RolesUserMembers
                WHERE UPPER(LTRIM(RTRIM(UserMemberId))) = UPPER(@ID_USER_DEL);
            END
 
            -- Limpiar la variable buffer de borrado
            UPDATE dbo.M_CONFIG 
            SET ID_DELETE = '' 
            WHERE PAR_KEY = @IPKEYJOB;
 
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        END CATCH;
 
END
