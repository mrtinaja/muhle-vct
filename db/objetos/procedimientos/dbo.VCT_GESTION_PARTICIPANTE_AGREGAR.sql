 
CREATE PROCEDURE dbo.VCT_GESTION_PARTICIPANTE_AGREGAR
(
    @ID_GESTION          INT,
    @ROL_PARTICIPANTE    VARCHAR(30),
    @TIPO_ENTIDAD        VARCHAR(20),
    @ID_ENTIDAD          INT = NULL,
    @PRINCIPAL           BIT = 0,
    @USUARIO             VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES WHERE ID=@ID_GESTION)
    BEGIN
        RAISERROR('La gestion indicada no existe.',16,1);
        RETURN;
    END;
 
    IF @ROL_PARTICIPANTE NOT IN
       ('ORIGEN','RESPONSABLE','DESTINATARIO','APROBADOR','OBSERVADOR')
    BEGIN
        RAISERROR('Rol de participante invalido.',16,1);
        RETURN;
    END;
 
    IF @TIPO_ENTIDAD NOT IN
       ('EMPLEADO','CONSULTOR','CLIENTE','PROVEEDOR','SISTEMA')
    BEGIN
        RAISERROR('Tipo de participante invalido.',16,1);
        RETURN;
    END;
 
    IF @TIPO_ENTIDAD='SISTEMA' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        RAISERROR('SISTEMA no debe tener ID_ENTIDAD.',16,1);
        RETURN;
    END;
 
    IF @TIPO_ENTIDAD<>'SISTEMA' AND @ID_ENTIDAD IS NULL
    BEGIN
        RAISERROR('El participante requiere ID_ENTIDAD.',16,1);
        RETURN;
    END;
 
    /* Evitar duplicar el mismo participante activo. */
    IF EXISTS
    (
        SELECT 1
        FROM dbo.VCT_GESTIONES_PARTICIPANTES
        WHERE ID_GESTION=@ID_GESTION
          AND ROL_PARTICIPANTE=@ROL_PARTICIPANTE
          AND TIPO_ENTIDAD=@TIPO_ENTIDAD
          AND ISNULL(ID_ENTIDAD,-1)=ISNULL(@ID_ENTIDAD,-1)
          AND ESTADO='ACTIVO'
    )
    BEGIN
        SELECT 'YA_EXISTE' AS RESULTADO;
        RETURN;
    END;
 
    INSERT INTO dbo.VCT_GESTIONES_PARTICIPANTES
    (
        ID_GESTION,
        ROL_PARTICIPANTE,
        TIPO_ENTIDAD,
        ID_ENTIDAD,
        PRINCIPAL,
        ESTADO,
        FECHA_ASIGNACION,
        FECHA_ALTA,
        USUARIO_ALTA
    )
    VALUES
    (
        @ID_GESTION,
        @ROL_PARTICIPANTE,
        @TIPO_ENTIDAD,
        @ID_ENTIDAD,
        ISNULL(@PRINCIPAL,0),
        'ACTIVO',
        GETDATE(),
        GETDATE(),
        @USUARIO
    );
 
    SELECT SCOPE_IDENTITY() AS ID_PARTICIPANTE;
END
