 
-- =========================================================================
-- SP generico de logging: se invoca desde cualquier ABM con un EXEC simple
-- EXEC dbo.VCT_LOG_AUDITORIA @MODULO='PERFILES', @ACCION='ALTA', @USER_ID=@IUSERID,
--      @REGISTRO_AFECTADO=@V_PERFIL_SEL, @DETALLE='Alta de perfil ' + @V_PERFIL_DESC
-- =========================================================================
CREATE   PROCEDURE dbo.VCT_LOG_AUDITORIA
(
    @MODULO             VARCHAR(50),
    @ACCION             VARCHAR(50),
    @USER_ID            VARCHAR(30),
    @REGISTRO_AFECTADO  VARCHAR(200) = NULL,
    @DETALLE            VARCHAR(500) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
 
    INSERT INTO dbo.M_AUDITORIA_ADMIN (Modulo, Accion, UsuarioId, RegistroAfectado, Detalle, Fecha)
    VALUES (ISNULL(@MODULO,''), ISNULL(@ACCION,''), ISNULL(@USER_ID,''), @REGISTRO_AFECTADO, @DETALLE, GETDATE());
END
