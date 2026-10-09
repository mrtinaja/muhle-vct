 
CREATE PROCEDURE dbo.VCT_GESTION_COMENTARIO_AGREGAR
(
    @ID_GESTION      INT,
    @COMENTARIO      VARCHAR(MAX),
    @TIPO_AUTOR      VARCHAR(20),
    @ID_AUTOR        INT = NULL,
    @INTERNO         BIT = 0,
    @USUARIO         VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT EXISTS (SELECT 1 FROM dbo.VCT_GESTIONES WHERE ID=@ID_GESTION)
    BEGIN
        RAISERROR('La gestion indicada no existe.',16,1);
        RETURN;
    END;
 
    IF NULLIF(LTRIM(RTRIM(ISNULL(@COMENTARIO,''))),'') IS NULL
    BEGIN
        RAISERROR('El comentario no puede estar vacio.',16,1);
        RETURN;
    END;
 
    INSERT INTO dbo.VCT_GESTIONES_COMENTARIOS
    (
        ID_GESTION,
        COMENTARIO,
        TIPO_AUTOR,
        ID_AUTOR,
        INTERNO,
        FECHA_ALTA,
        USUARIO_ALTA
    )
    VALUES
    (
        @ID_GESTION,
        @COMENTARIO,
        @TIPO_AUTOR,
        @ID_AUTOR,
        ISNULL(@INTERNO,0),
        GETDATE(),
        @USUARIO
    );
 
    SELECT SCOPE_IDENTITY() AS ID_COMENTARIO;
END
