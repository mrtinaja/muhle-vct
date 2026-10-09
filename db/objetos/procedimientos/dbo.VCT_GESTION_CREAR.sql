 
CREATE PROCEDURE dbo.VCT_GESTION_CREAR
(
    @ORIGEN                 VARCHAR(20),
 
    @ID_TIPO                INT,
    @ID_SUBTIPO             INT = NULL,
    @ID_ESTADO              INT,
    @ID_PRIORIDAD           INT,
    @ID_RESULTADO           INT = NULL,
 
    @ID_GESTION_PADRE       INT = NULL,
    @ID_EVENTO_ORIGEN       INT = NULL,
    @ID_REGLA_ORIGEN        INT = NULL,
 
    @TITULO                 VARCHAR(300),
    @DESCRIPCION            VARCHAR(MAX) = NULL,
 
    @ID_CLIENTE             INT = NULL,
    @ID_PROYECTO            INT = NULL,
    @ID_PROYECTO_SERVICIO   INT = NULL,
    @ID_VISITA              INT = NULL,
    @ID_PLAN                INT = NULL,
    @ID_PLAN_ITEM           INT = NULL,
 
    @REQUIERE_RESPUESTA     BIT = 0,
    @REQUIERE_APROBACION    BIT = 0,
 
    @FECHA_INICIO           DATETIME = NULL,
    @FECHA_VENCIMIENTO      DATETIME = NULL,
 
    @OBSERVACIONES          VARCHAR(2000) = NULL,
 
    @USUARIO                VARCHAR(100) = NULL,
 
    @ID_GESTION_OUT         INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    SET @ID_GESTION_OUT = NULL;
 
    IF @ORIGEN NOT IN ('MANUAL','AUTOMATICA','SISTEMA')
    BEGIN
        RAISERROR('ORIGEN de gestion invalido.',16,1);
        RETURN;
    END;
 
    IF @ID_TIPO IS NULL OR @ID_ESTADO IS NULL OR @ID_PRIORIDAD IS NULL
    BEGIN
        RAISERROR('Tipo, estado y prioridad son obligatorios.',16,1);
        RETURN;
    END;
 
    IF NULLIF(LTRIM(RTRIM(ISNULL(@TITULO,''))),'') IS NULL
    BEGIN
        RAISERROR('El titulo de la gestion es obligatorio.',16,1);
        RETURN;
    END;
 
    /* Si viene proyecto y no cliente, resolverlo desde el proyecto. */
    IF @ID_PROYECTO IS NOT NULL AND @ID_CLIENTE IS NULL
    BEGIN
        SELECT @ID_CLIENTE=P.IDCLIENTE
        FROM dbo.VCT_PROYECTOS P
        WHERE P.ID=@ID_PROYECTO;
    END;
 
    IF @FECHA_INICIO IS NULL
        SET @FECHA_INICIO=GETDATE();
 
    BEGIN TRANSACTION;
 
    INSERT INTO dbo.VCT_GESTIONES
    (
        CODIGO,
        ORIGEN,
 
        ID_TIPO,
        ID_SUBTIPO,
        ID_ESTADO,
        ID_PRIORIDAD,
        ID_RESULTADO,
 
        ID_GESTION_PADRE,
        ID_EVENTO_ORIGEN,
        ID_REGLA_ORIGEN,
 
        TITULO,
        DESCRIPCION,
 
        ID_CLIENTE,
        ID_PROYECTO,
        ID_PROYECTO_SERVICIO,
        ID_VISITA,
        ID_PLAN,
        ID_PLAN_ITEM,
 
        REQUIERE_RESPUESTA,
        REQUIERE_APROBACION,
 
        FECHA_CREACION,
        FECHA_INICIO,
        FECHA_VENCIMIENTO,
        FECHA_CIERRE,
 
        OBSERVACIONES,
 
        FECHA_ALTA,
        USUARIO_ALTA,
        FECHA_UPD,
        USUARIO_UPD
    )
    VALUES
    (
        NULL,
        @ORIGEN,
 
        @ID_TIPO,
        @ID_SUBTIPO,
        @ID_ESTADO,
        @ID_PRIORIDAD,
        @ID_RESULTADO,
 
        @ID_GESTION_PADRE,
        @ID_EVENTO_ORIGEN,
        @ID_REGLA_ORIGEN,
 
        @TITULO,
        @DESCRIPCION,
 
        @ID_CLIENTE,
        @ID_PROYECTO,
        @ID_PROYECTO_SERVICIO,
        @ID_VISITA,
        @ID_PLAN,
        @ID_PLAN_ITEM,
 
        ISNULL(@REQUIERE_RESPUESTA,0),
        ISNULL(@REQUIERE_APROBACION,0),
 
        GETDATE(),
        @FECHA_INICIO,
        @FECHA_VENCIMIENTO,
        NULL,
 
        @OBSERVACIONES,
 
        GETDATE(),
        @USUARIO,
        NULL,
        NULL
    );
 
    SET @ID_GESTION_OUT=SCOPE_IDENTITY();
 
    UPDATE dbo.VCT_GESTIONES
       SET CODIGO='GES-'+RIGHT(REPLICATE('0',9)+CONVERT(VARCHAR(20),@ID_GESTION_OUT),9)
     WHERE ID=@ID_GESTION_OUT;
 
    INSERT INTO dbo.VCT_GESTIONES_HISTORIAL
    (
        ID_GESTION,
        ID_ESTADO_ANTERIOR,
        ID_ESTADO_NUEVO,
        ID_RESULTADO,
        ACCION,
        DESCRIPCION,
        TIPO_ACTOR,
        ID_ACTOR,
        FECHA,
        USUARIO
    )
    VALUES
    (
        @ID_GESTION_OUT,
        NULL,
        @ID_ESTADO,
        @ID_RESULTADO,
        'CREACION',
        'Creación de gestión.',
        CASE WHEN @ORIGEN='MANUAL' THEN 'EMPLEADO' ELSE 'SISTEMA' END,
        NULL,
        GETDATE(),
        @USUARIO
    );
 
    COMMIT TRANSACTION;
 
    SELECT
        G.ID,
        G.CODIGO,
        G.TITULO,
        G.ID_ESTADO,
        G.FECHA_VENCIMIENTO
    FROM dbo.VCT_GESTIONES G
    WHERE G.ID=@ID_GESTION_OUT;
END
