 
CREATE PROCEDURE [dbo].[M_CONFIG_ADD_USER_GROUP]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100)
)
AS
BEGIN   
    SET NOCOUNT ON;
 
    DECLARE 
        @ID_USER_SEL  VARCHAR(100) = '',
        @ID_GROUP_SEL VARCHAR(100) = '';
 
    -- 1. Leer parámetros desde M_CONFIG
    SELECT TOP 1
        @ID_USER_SEL  = ISNULL(ID_USER_SEL, ''), 
        @ID_GROUP_SEL = ISNULL(ID_GROUP_SEL, '')  
    FROM dbo.M_CONFIG WITH (READUNCOMMITTED) 
    WHERE PAR_KEY = @IPKEYJOB;
 
    -- 2. SI VIENE CON COMAS (ej: "rabosaleh,rabosaleh"), TOMAR SOLO EL PRIMER ELEMENTO
    IF CHARINDEX(',', @ID_USER_SEL) > 0
    BEGIN
        SET @ID_USER_SEL = LEFT(@ID_USER_SEL, CHARINDEX(',', @ID_USER_SEL) - 1);
    END
 
    IF CHARINDEX(',', @ID_GROUP_SEL) > 0
    BEGIN
        SET @ID_GROUP_SEL = LEFT(@ID_GROUP_SEL, CHARINDEX(',', @ID_GROUP_SEL) - 1);
    END
 
    -- 3. Saneo de comillas y espacios
    SET @ID_USER_SEL  = LTRIM(RTRIM(REPLACE(REPLACE(ISNULL(@ID_USER_SEL, ''), '''', ''), '"', '')));
    SET @ID_GROUP_SEL = LTRIM(RTRIM(REPLACE(REPLACE(ISNULL(@ID_GROUP_SEL, ''), '''', ''), '"', '')));
 
    -- 4. Inserción estricta
    IF @ID_USER_SEL <> '' AND @ID_GROUP_SEL <> ''
    BEGIN
        BEGIN TRANSACTION
 
            -- Regla Mühle: borrar previa asignación
            DELETE FROM dbo.GroupsUserMembers
            WHERE UPPER(LTRIM(RTRIM(UserMemberId))) = UPPER(@ID_USER_SEL);
 
            -- Insertar el ID de usuario limpio
            INSERT INTO dbo.GroupsUserMembers (GroupId, UserMemberId)
            VALUES (@ID_GROUP_SEL, @ID_USER_SEL);
 
            -- Limpiar M_CONFIG
            UPDATE dbo.M_CONFIG
            SET ID_USER_SEL = ''
            WHERE PAR_KEY = @IPKEYJOB;
 
        COMMIT TRANSACTION
    END
END
