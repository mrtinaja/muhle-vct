USE [MuhlePROD]
GO

-- =========================================================================
-- Tabla de auditoria para el modulo de Administracion / Seguridad
-- (Usuarios, Perfiles, Estructura, Area, Psessions, Perfil_Admin)
-- =========================================================================
IF OBJECT_ID('dbo.M_AUDITORIA_ADMIN', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.M_AUDITORIA_ADMIN
    (
        Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_M_AUDITORIA_ADMIN_Id DEFAULT NEWID(),
        Modulo              VARCHAR(50)      NOT NULL,   -- USUARIOS, PERFILES, ESTRUCTURA, AREA, PSESSIONS, PERFIL_ADMIN
        Accion              VARCHAR(50)      NOT NULL,   -- ALTA, MODIFICACION, ASOCIAR, DESASOCIAR, LOG IN, LOG OFF
        UsuarioId           VARCHAR(30)      NOT NULL,   -- quien ejecuto la accion (@IUSERID)
        RegistroAfectado    VARCHAR(200)     NULL,        -- clave del registro afectado (Id de Grupo/Usuario/Sector/Accion, etc.)
        Detalle             VARCHAR(500)     NULL,        -- descripcion legible de que cambio
        Fecha               DATETIME         NOT NULL CONSTRAINT DF_M_AUDITORIA_ADMIN_Fecha DEFAULT GETDATE(),

        CONSTRAINT PK_M_AUDITORIA_ADMIN PRIMARY KEY (Id)
    );

    CREATE NONCLUSTERED INDEX IX_M_AUDITORIA_ADMIN_Modulo_Accion_Fecha
        ON dbo.M_AUDITORIA_ADMIN (Modulo, Accion, Fecha DESC);

    CREATE NONCLUSTERED INDEX IX_M_AUDITORIA_ADMIN_UsuarioId
        ON dbo.M_AUDITORIA_ADMIN (UsuarioId);
END
GO

-- =========================================================================
-- SP generico de logging: se invoca desde cualquier ABM con un EXEC simple
-- EXEC dbo.VCT_LOG_AUDITORIA @MODULO='PERFILES', @ACCION='ALTA', @USER_ID=@IUSERID,
--      @REGISTRO_AFECTADO=@V_PERFIL_SEL, @DETALLE='Alta de perfil ' + @V_PERFIL_DESC
-- =========================================================================
CREATE OR ALTER PROCEDURE dbo.VCT_LOG_AUDITORIA
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
GO
