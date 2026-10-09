 
CREATE PROCEDURE [dbo].[M_CONFIG_DEL_AREA]
(
    @IPKEYJOB AS VARCHAR(100),
    @IUSERID  AS VARCHAR(100),
    @ORETCODE AS INT OUTPUT,
    @ORETDESC AS VARCHAR(400) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ID_AREA_DEL VARCHAR(100),
            @VCANT       INT,
            @VDESC_AREA_DEL VARCHAR(200),
            @VDETALLE_LOG   VARCHAR(500);
 
    SELECT  @ID_AREA_DEL = ISNULL(ID_DELETE, '')
    FROM    M_CONFIG WITH (NOLOCK)
    WHERE   PAR_KEY = @IPKEYJOB;
 
    SET @ID_AREA_DEL = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(@ID_AREA_DEL, ''), ',', ''), '''', ''), '"', '')));
 
    SET @ORETCODE = 0;
    SET @ORETDESC = '';
    SET @VCANT    = 0;
 
    IF (@ID_AREA_DEL <> '')
    BEGIN
        SELECT  @VCANT = COUNT(1)
        FROM    Sectores WITH (NOLOCK)
        WHERE   CONVERT(VARCHAR, Id_area) = @ID_AREA_DEL;
 
        IF (@VCANT > 0)
        BEGIN
            SET @ORETCODE = 1;
            SET @ORETDESC = 'No puede eliminar el Área seleccionada porque tiene sectores asociados.';
 
            UPDATE M_CONFIG
            SET DESC_ERROR = @ORETDESC
            WHERE PAR_KEY = @IPKEYJOB;
 
            RETURN;
        END
        ELSE
        BEGIN
            SELECT TOP 1 @VDESC_AREA_DEL = Desc_Area
            FROM Areas WITH (NOLOCK)
            WHERE CONVERT(VARCHAR, Id_area) = @ID_AREA_DEL;
 
            DELETE FROM Areas
            WHERE CONVERT(VARCHAR, Id_area) = @ID_AREA_DEL;
 
            IF @@ROWCOUNT > 0
            BEGIN
                SET @VDETALLE_LOG = 'Baja de área: ' + ISNULL(@VDESC_AREA_DEL, '');
 
                EXEC dbo.VCT_LOG_AUDITORIA
                     @MODULO            = 'AREA',
                     @ACCION            = 'BAJA',
                     @USER_ID           = @IUSERID,
                     @REGISTRO_AFECTADO = @ID_AREA_DEL,
                     @DETALLE           = @VDETALLE_LOG;
            END
        END
    END
END
