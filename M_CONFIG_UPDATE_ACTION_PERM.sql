USE [MuhlePROD]
GO
/****** Object:  StoredProcedure [dbo].[M_CONFIG_UPDATE_ACTION_PERM]    Script Date: 13/9/2026 19:25:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[M_CONFIG_UPDATE_ACTION_PERM]
(
    @IPKEYJOB VARCHAR(100),
    @IUSERID  VARCHAR(100),
    @FORM_ID  VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @V_GROUP_ID   VARCHAR(100) = '',
        @V_ACTION_ID  VARCHAR(100) = '',
        @V_NEW_STATE  VARCHAR(10)  = '',
        @V_GROUP_DESC VARCHAR(250) = '',
        @V_ACTION_DESC VARCHAR(250) = '',
        @V_DETALLE_LOG VARCHAR(500) = '';

    -- 1. Leer los parámetros guardados por almacenarSeleccion desde M_CONFIG
    SELECT TOP 1
        @V_GROUP_ID  = ISNULL(ID_GROUP_SEL, ''),
        @V_ACTION_ID = ISNULL(ID_ACTION_SEL, ''),
        @V_NEW_STATE = ISNULL(NEW_ID, '0')
    FROM dbo.M_CONFIG WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;

    -- Limpieza de caracteres y formato
    SET @V_GROUP_ID  = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@V_GROUP_ID, '''', ''), '"', ''), ',', '')));
    SET @V_ACTION_ID = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@V_ACTION_ID, '''', ''), '"', ''), ',', '')));
    SET @V_NEW_STATE = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@V_NEW_STATE, '''', ''), '"', ''), ',', '')));

    -- 2. Ejecutar inserción o borrado en dbo.GroupsActions según el estado del Switch
    IF @V_GROUP_ID <> '' AND @V_ACTION_ID <> ''
    BEGIN
        SELECT TOP 1 @V_GROUP_DESC = ISNULL(Name, '') FROM dbo.Groups WITH (NOLOCK) WHERE Id = @V_GROUP_ID;
        SELECT TOP 1 @V_ACTION_DESC = ISNULL(Name, '') FROM dbo.Actions WITH (NOLOCK) WHERE Id = @V_ACTION_ID;

        IF @V_NEW_STATE = '1'
        BEGIN
            -- ACTIVAR PERMISO: Insertar en GroupsActions si no existe
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.GroupsActions WITH (NOLOCK)
                WHERE LTRIM(RTRIM(GroupId)) = @V_GROUP_ID
                  AND LTRIM(RTRIM(ActionId)) = @V_ACTION_ID
            )
            BEGIN
                INSERT INTO dbo.GroupsActions (GroupId, ActionId)
                VALUES (@V_GROUP_ID, @V_ACTION_ID);

                SET @V_DETALLE_LOG = 'Permiso "' + ISNULL(NULLIF(@V_ACTION_DESC, ''), @V_ACTION_ID) + '" habilitado para el perfil ' + ISNULL(NULLIF(@V_GROUP_DESC, ''), @V_GROUP_ID);

                EXEC dbo.VCT_LOG_AUDITORIA
                     @MODULO            = 'PERFIL_ADMIN',
                     @ACCION            = 'ASOCIAR',
                     @USER_ID           = @IUSERID,
                     @REGISTRO_AFECTADO = @V_GROUP_ID,
                     @DETALLE           = @V_DETALLE_LOG;
            END
        END
        ELSE
        BEGIN
            -- DESACTIVAR PERMISO: Eliminar de GroupsActions si existe
            DELETE FROM dbo.GroupsActions
            WHERE LTRIM(RTRIM(GroupId)) = @V_GROUP_ID
              AND LTRIM(RTRIM(ActionId)) = @V_ACTION_ID;

            IF @@ROWCOUNT > 0
            BEGIN
                SET @V_DETALLE_LOG = 'Permiso "' + ISNULL(NULLIF(@V_ACTION_DESC, ''), @V_ACTION_ID) + '" deshabilitado para el perfil ' + ISNULL(NULLIF(@V_GROUP_DESC, ''), @V_GROUP_ID);

                EXEC dbo.VCT_LOG_AUDITORIA
                     @MODULO            = 'PERFIL_ADMIN',
                     @ACCION            = 'DESASOCIAR',
                     @USER_ID           = @IUSERID,
                     @REGISTRO_AFECTADO = @V_GROUP_ID,
                     @DETALLE           = @V_DETALLE_LOG;
            END
        END
    END

    -- 3. Limpiar variables temporales de la acción en M_CONFIG pero PRESERVAR ID_GROUP_SEL
    UPDATE dbo.M_CONFIG
    SET ID_ACTION_SEL = NULL,
        NEW_ID        = NULL
    WHERE PAR_KEY = @IPKEYJOB;

END
