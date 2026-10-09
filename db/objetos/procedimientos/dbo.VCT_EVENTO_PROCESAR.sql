 
CREATE PROCEDURE dbo.VCT_EVENTO_PROCESAR
(
    @ID_EVENTO INT,
    @USUARIO   VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE
        @CODIGO_EVENTO          VARCHAR(100),
        @TIPO_ENTIDAD           VARCHAR(50),
        @ID_ENTIDAD             INT,
        @ID_PROYECTO_EVENTO     INT,
 
        @ID_PROYECTO            INT,
        @ID_PROYECTO_SERVICIO   INT,
        @ID_VISITA              INT,
        @ID_PLAN                INT,
        @ID_PLAN_ITEM           INT,
        @ID_CLIENTE             INT,
 
        @CODIGO_PROYECTO        VARCHAR(100),
        @NOMBRE_PROYECTO        VARCHAR(300);
 
    SELECT
        @CODIGO_EVENTO=CODIGO_EVENTO,
        @TIPO_ENTIDAD=TIPO_ENTIDAD,
        @ID_ENTIDAD=ID_ENTIDAD,
        @ID_PROYECTO_EVENTO=ID_PROYECTO
    FROM dbo.VCT_EVENTOS_NEGOCIO
    WHERE ID=@ID_EVENTO
      AND PROCESADO=0;
 
    IF @CODIGO_EVENTO IS NULL
    BEGIN
        SELECT 'EVENTO_INEXISTENTE_O_PROCESADO' AS RESULTADO;
        RETURN;
    END;
 
    SET @ID_PROYECTO=@ID_PROYECTO_EVENTO;
 
    /* Resolver contexto desde la entidad que origino el evento. */
    IF @TIPO_ENTIDAD='PROYECTO' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SET @ID_PROYECTO=@ID_ENTIDAD;
    END;
 
    IF @TIPO_ENTIDAD='PROYECTO_SERVICIO' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SET @ID_PROYECTO_SERVICIO=@ID_ENTIDAD;
 
        SELECT @ID_PROYECTO=ID_PROYECTO
        FROM dbo.VCT_PROYECTOS_SERVICIOS
        WHERE ID=@ID_ENTIDAD;
    END;
 
    IF @TIPO_ENTIDAD='VISITA' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SET @ID_VISITA=@ID_ENTIDAD;
 
        SELECT
            @ID_PROYECTO=ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=ID_PROYECTO_SERVICIO
        FROM dbo.VCT_PROYECTOS_VISITAS
        WHERE ID=@ID_ENTIDAD;
    END;
 
    IF @TIPO_ENTIDAD='PLAN' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SET @ID_PLAN=@ID_ENTIDAD;
 
        SELECT
            @ID_PROYECTO=ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=ID_PROYECTO_SERVICIO
        FROM dbo.VCT_PROYECTOS_PLANES
        WHERE ID=@ID_ENTIDAD;
    END;
 
    IF @TIPO_ENTIDAD='PLAN_ITEM' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SET @ID_PLAN_ITEM=@ID_ENTIDAD;
 
        SELECT @ID_PLAN=ID_PLAN
        FROM dbo.VCT_PROYECTOS_PLAN_ITEMS
        WHERE ID=@ID_ENTIDAD;
 
        SELECT
            @ID_PROYECTO=ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=ID_PROYECTO_SERVICIO
        FROM dbo.VCT_PROYECTOS_PLANES
        WHERE ID=@ID_PLAN;
    END;
 
    IF @TIPO_ENTIDAD='VIATICO' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SELECT
            @ID_PROYECTO=ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=ID_PROYECTO_SERVICIO,
            @ID_VISITA=ID_VISITA
        FROM dbo.VCT_VIATICOS
        WHERE ID=@ID_ENTIDAD;
    END;
 
    IF @TIPO_ENTIDAD='HONORARIO' AND @ID_ENTIDAD IS NOT NULL
    BEGIN
        SELECT
            @ID_PROYECTO=ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=ID_PROYECTO_SERVICIO,
            @ID_VISITA=ID_VISITA
        FROM dbo.VCT_HONORARIOS
        WHERE ID=@ID_ENTIDAD;
    END;
 
    IF @ID_PROYECTO IS NOT NULL
    BEGIN
        SELECT
            @ID_CLIENTE=IDCLIENTE,
            @CODIGO_PROYECTO=CODIGO,
            @NOMBRE_PROYECTO=NOMBRE
        FROM dbo.VCT_PROYECTOS
        WHERE ID=@ID_PROYECTO;
    END;
 
    DECLARE
        @ID_REGLA               INT,
        @ID_TIPO                INT,
        @ID_SUBTIPO             INT,
        @ID_ESTADO_INICIAL      INT,
        @ID_PRIORIDAD           INT,
        @DESTINATARIO_ROL       VARCHAR(100),
        @TITULO_PLANTILLA       VARCHAR(300),
        @DETALLE_PLANTILLA      VARCHAR(MAX),
        @DIAS_VENCIMIENTO       INT,
        @GENERA_EMAIL           BIT,
        @ID_EMAIL_TEMPLATE      INT,
 
        @TITULO                 VARCHAR(300),
        @DETALLE                VARCHAR(MAX),
        @FECHA_VENCIMIENTO      DATETIME,
        @ID_GESTION             INT;
 
    DECLARE C_REGLAS CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        ID,
        ID_TIPO,
        ID_SUBTIPO,
        ID_ESTADO_INICIAL,
        ID_PRIORIDAD,
        DESTINATARIO_ROL,
        TITULO_PLANTILLA,
        DETALLE_PLANTILLA,
        DIAS_VENCIMIENTO,
        GENERA_EMAIL,
        ID_EMAIL_TEMPLATE
    FROM dbo.VCT_PRM_GESTIONES_REGLAS
    WHERE CODIGO_EVENTO=@CODIGO_EVENTO
      AND ACTIVO=1
    ORDER BY ID;
 
    OPEN C_REGLAS;
 
    FETCH NEXT FROM C_REGLAS
    INTO
        @ID_REGLA,
        @ID_TIPO,
        @ID_SUBTIPO,
        @ID_ESTADO_INICIAL,
        @ID_PRIORIDAD,
        @DESTINATARIO_ROL,
        @TITULO_PLANTILLA,
        @DETALLE_PLANTILLA,
        @DIAS_VENCIMIENTO,
        @GENERA_EMAIL,
        @ID_EMAIL_TEMPLATE;
 
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @TITULO=ISNULL(@TITULO_PLANTILLA,'Gestión automática');
        SET @DETALLE=@DETALLE_PLANTILLA;
 
        SET @TITULO=REPLACE(@TITULO,'{{ID_PROYECTO}}',ISNULL(CONVERT(VARCHAR(20),@ID_PROYECTO),''));
        SET @TITULO=REPLACE(@TITULO,'{{CODIGO_PROYECTO}}',ISNULL(@CODIGO_PROYECTO,''));
        SET @TITULO=REPLACE(@TITULO,'{{PROYECTO}}',ISNULL(@NOMBRE_PROYECTO,''));
 
        IF @DETALLE IS NOT NULL
        BEGIN
            SET @DETALLE=REPLACE(@DETALLE,'{{ID_PROYECTO}}',ISNULL(CONVERT(VARCHAR(20),@ID_PROYECTO),''));
            SET @DETALLE=REPLACE(@DETALLE,'{{CODIGO_PROYECTO}}',ISNULL(@CODIGO_PROYECTO,''));
            SET @DETALLE=REPLACE(@DETALLE,'{{PROYECTO}}',ISNULL(@NOMBRE_PROYECTO,''));
        END;
 
        SET @FECHA_VENCIMIENTO=NULL;
 
        IF @DIAS_VENCIMIENTO IS NOT NULL
            SET @FECHA_VENCIMIENTO=DATEADD(DAY,@DIAS_VENCIMIENTO,GETDATE());
 
        EXEC dbo.VCT_GESTION_CREAR
            @ORIGEN='AUTOMATICA',
            @ID_TIPO=@ID_TIPO,
            @ID_SUBTIPO=@ID_SUBTIPO,
            @ID_ESTADO=@ID_ESTADO_INICIAL,
            @ID_PRIORIDAD=@ID_PRIORIDAD,
            @ID_RESULTADO=NULL,
 
            @ID_GESTION_PADRE=NULL,
            @ID_EVENTO_ORIGEN=@ID_EVENTO,
            @ID_REGLA_ORIGEN=@ID_REGLA,
 
            @TITULO=@TITULO,
            @DESCRIPCION=@DETALLE,
 
            @ID_CLIENTE=@ID_CLIENTE,
            @ID_PROYECTO=@ID_PROYECTO,
            @ID_PROYECTO_SERVICIO=@ID_PROYECTO_SERVICIO,
            @ID_VISITA=@ID_VISITA,
            @ID_PLAN=@ID_PLAN,
            @ID_PLAN_ITEM=@ID_PLAN_ITEM,
 
            @REQUIERE_RESPUESTA=0,
            @REQUIERE_APROBACION=0,
 
            @FECHA_INICIO=NULL,
            @FECHA_VENCIMIENTO=@FECHA_VENCIMIENTO,
 
            @OBSERVACIONES=NULL,
            @USUARIO=@USUARIO,
            @ID_GESTION_OUT=@ID_GESTION OUTPUT;
 
        /* Toda gestion automatica tiene al SISTEMA como origen. */
        EXEC dbo.VCT_GESTION_PARTICIPANTE_AGREGAR
            @ID_GESTION=@ID_GESTION,
            @ROL_PARTICIPANTE='ORIGEN',
            @TIPO_ENTIDAD='SISTEMA',
            @ID_ENTIDAD=NULL,
            @PRINCIPAL=1,
            @USUARIO=@USUARIO;
 
 
        /* ------------------------------------------------------------
           Resolver destinatarios/responsables por rol de proyecto.
           ------------------------------------------------------------ */
 
        IF @DESTINATARIO_ROL='ANALISTA_PROYECTO'
        BEGIN
            DECLARE @ID_ANALISTA INT;
 
            SELECT TOP 1
                @ID_ANALISTA=E.ID_EMPLEADO
            FROM dbo.VCT_PROYECTOS_EQUIPO E
            INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R
                ON R.ID=E.ID_ROL
            WHERE E.ID_PROYECTO=@ID_PROYECTO
              AND E.TIPO_MIEMBRO='EMPLEADO'
              AND E.ID_EMPLEADO IS NOT NULL
              AND R.CODIGO='ANALISTA'
              AND E.ESTADO='ACTIVO'
            ORDER BY E.PRINCIPAL DESC,E.ID;
 
            IF @ID_ANALISTA IS NOT NULL
            BEGIN
                EXEC dbo.VCT_GESTION_PARTICIPANTE_AGREGAR
                    @ID_GESTION=@ID_GESTION,
                    @ROL_PARTICIPANTE='RESPONSABLE',
                    @TIPO_ENTIDAD='EMPLEADO',
                    @ID_ENTIDAD=@ID_ANALISTA,
                    @PRINCIPAL=1,
                    @USUARIO=@USUARIO;
            END;
        END;
 
 
        IF @DESTINATARIO_ROL='CONSULTOR_LIDER'
        BEGIN
            DECLARE @ID_CONSULTOR_LIDER INT;
 
            SELECT TOP 1
                @ID_CONSULTOR_LIDER=E.ID_CONSULTOR
            FROM dbo.VCT_PROYECTOS_EQUIPO E
            INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES R
                ON R.ID=E.ID_ROL
            WHERE E.ID_PROYECTO=@ID_PROYECTO
              AND E.TIPO_MIEMBRO='CONSULTOR'
              AND E.ID_CONSULTOR IS NOT NULL
              AND R.CODIGO='CONSULTOR_LIDER'
              AND E.ESTADO='ACTIVO'
              AND
              (
                  @ID_PROYECTO_SERVICIO IS NULL
                  OR E.ID_PROYECTO_SERVICIO IS NULL
                  OR E.ID_PROYECTO_SERVICIO=@ID_PROYECTO_SERVICIO
              )
            ORDER BY E.PRINCIPAL DESC,E.ID;
 
            /* Fallback: si no hay lider explicito, tomar consultor principal
               o el primero del equipo. */
            IF @ID_CONSULTOR_LIDER IS NULL
            BEGIN
                SELECT TOP 1
                    @ID_CONSULTOR_LIDER=E.ID_CONSULTOR
                FROM dbo.VCT_PROYECTOS_EQUIPO E
                WHERE E.ID_PROYECTO=@ID_PROYECTO
                  AND E.TIPO_MIEMBRO='CONSULTOR'
                  AND E.ID_CONSULTOR IS NOT NULL
                  AND E.ESTADO='ACTIVO'
                  AND
                  (
                      @ID_PROYECTO_SERVICIO IS NULL
                      OR E.ID_PROYECTO_SERVICIO IS NULL
                      OR E.ID_PROYECTO_SERVICIO=@ID_PROYECTO_SERVICIO
                  )
                ORDER BY E.PRINCIPAL DESC,E.ID;
            END;
 
            IF @ID_CONSULTOR_LIDER IS NOT NULL
            BEGIN
                EXEC dbo.VCT_GESTION_PARTICIPANTE_AGREGAR
                    @ID_GESTION=@ID_GESTION,
                    @ROL_PARTICIPANTE='RESPONSABLE',
                    @TIPO_ENTIDAD='CONSULTOR',
                    @ID_ENTIDAD=@ID_CONSULTOR_LIDER,
                    @PRINCIPAL=1,
                    @USUARIO=@USUARIO;
            END;
        END;
 
 
        IF @DESTINATARIO_ROL='CONSULTORES_PROYECTO'
        BEGIN
            DECLARE @ID_CONSULTOR INT;
 
            DECLARE C_CONS CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT E.ID_CONSULTOR
            FROM dbo.VCT_PROYECTOS_EQUIPO E
            WHERE E.ID_PROYECTO=@ID_PROYECTO
              AND E.TIPO_MIEMBRO='CONSULTOR'
              AND E.ID_CONSULTOR IS NOT NULL
              AND E.ESTADO='ACTIVO'
              AND
              (
                  @ID_PROYECTO_SERVICIO IS NULL
                  OR E.ID_PROYECTO_SERVICIO IS NULL
                  OR E.ID_PROYECTO_SERVICIO=@ID_PROYECTO_SERVICIO
              );
 
            OPEN C_CONS;
            FETCH NEXT FROM C_CONS INTO @ID_CONSULTOR;
 
            WHILE @@FETCH_STATUS=0
            BEGIN
                EXEC dbo.VCT_GESTION_PARTICIPANTE_AGREGAR
                    @ID_GESTION=@ID_GESTION,
                    @ROL_PARTICIPANTE='DESTINATARIO',
                    @TIPO_ENTIDAD='CONSULTOR',
                    @ID_ENTIDAD=@ID_CONSULTOR,
                    @PRINCIPAL=0,
                    @USUARIO=@USUARIO;
 
                FETCH NEXT FROM C_CONS INTO @ID_CONSULTOR;
            END;
 
            CLOSE C_CONS;
            DEALLOCATE C_CONS;
        END;
 
        /* GENERA_EMAIL e ID_EMAIL_TEMPLATE quedan registrados en la regla.
           El envio real se conecta en el siguiente paso al motor de emails. */
 
        FETCH NEXT FROM C_REGLAS
        INTO
            @ID_REGLA,
            @ID_TIPO,
            @ID_SUBTIPO,
            @ID_ESTADO_INICIAL,
            @ID_PRIORIDAD,
            @DESTINATARIO_ROL,
            @TITULO_PLANTILLA,
            @DETALLE_PLANTILLA,
            @DIAS_VENCIMIENTO,
            @GENERA_EMAIL,
            @ID_EMAIL_TEMPLATE;
    END;
 
    CLOSE C_REGLAS;
    DEALLOCATE C_REGLAS;
 
    UPDATE dbo.VCT_EVENTOS_NEGOCIO
       SET PROCESADO=1,
           FECHA_PROCESADO=GETDATE(),
           ERROR_PROCESO=NULL
     WHERE ID=@ID_EVENTO;
 
    SELECT
        @ID_EVENTO AS ID_EVENTO,
        @CODIGO_EVENTO AS CODIGO_EVENTO,
        'PROCESADO' AS RESULTADO;
END
