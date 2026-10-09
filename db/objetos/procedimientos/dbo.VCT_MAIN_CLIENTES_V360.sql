 
CREATE     PROCEDURE [dbo].[VCT_MAIN_CLIENTES_V360]
(
    @IPKEYJOB    VARCHAR(100),
    @FORM_ID     VARCHAR(100),
    @IUNIDAD     VARCHAR(100),
    @IAGENTE     VARCHAR(100),
    @OUTPARAM1   VARCHAR(MAX) OUTPUT,
    @OUTPARAM2   VARCHAR(MAX) OUTPUT,
    @OUTPARAM3   VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */
    DECLARE @PROY_ALTA_ERR VARCHAR(1000)='', @PROY_ALTA_MSG VARCHAR(1000)=''; /* ALTA_PROYECTO_V1 */
 
    /* ============================================================
       VISTA 360 - MODELO VCT
 
       Fuentes principales:
         VCT_CLIENTES
         VCT_DOMICILIOS
         VCT_TELEFONOS
         VCT_EMAILS
         VCT_CONTACTOS
         VCT_PROYECTOS
 
       MODELO ACTUAL:
       VCT_PROYECTOS utiliza ID_ESTADO contra
       VCT_PRM_PROYECTOS_ESTADOS y ya posee FECHA_INICIO / FECHA_FIN.
 
       VCT_GESTIONES utiliza ID_CLIENTE, ID_PROYECTO, ID_ESTADO,
       ID_TIPO, ID_SUBTIPO e ID_RESULTADO contra las nuevas tablas
       de parametria VCT_PRM_GESTIONES_*.
 
       VCT_CONTACTOS usa la estructura real:
       APELLIDO, NOMBRES, CARGO, ID_DOMICILIO, ID_TELEFONO, ID_EMAIL,
       OBSERVACIONES y campos de auditoría.
 
       MODELO MULTIENTIDAD:
       VCT_DOMICILIOS / VCT_TELEFONOS / VCT_EMAILS ya no usan IDCLIENTE.
       Para Clientes se filtran y graban mediante:
         TIPO_ENTIDAD = 'CLIENTE'
         ID_ENTIDAD   = @ID_CLIENTE
       ============================================================ */
 
    DECLARE @HTML_SHELL    VARCHAR(MAX) = '';
    DECLARE @BTN_BACK      VARCHAR(MAX) = '';
    DECLARE @CAN_VIEW      BIT = 0;
    DECLARE @CAN_EDIT      BIT = 0;
 
    /* ============================================================
       1. PERMISOS - LOGICA NUEVA
       ------------------------------------------------------------
       NO usa funciones inventadas.
       Permisos reales:
         Actions
         GroupsActions
       Perfil actual:
         @IUNIDAD
 
       CLIENTES.VIEW -> permite ver Vista 360
       CLIENTES.EDIT -> permite alta/edición de datos relacionados
                        (domicilios, teléfonos, emails y contactos)
 
       Si más adelante se crean acciones específicas por subentidad,
       sólo se cambia este bloque; el renderer y JS no se modifican.
       ============================================================ */
    SELECT
        @CAN_VIEW = MAX(CASE WHEN A.Id='CLIENTES.VIEW' THEN 1 ELSE 0 END),
        @CAN_EDIT = MAX(CASE WHEN A.Id='CLIENTES.EDIT' THEN 1 ELSE 0 END)
    FROM dbo.Actions A WITH(NOLOCK)
    INNER JOIN dbo.GroupsActions GA WITH(NOLOCK)
        ON GA.ActionId COLLATE DATABASE_DEFAULT =
           A.Id COLLATE DATABASE_DEFAULT
    WHERE UPPER(LTRIM(RTRIM(GA.GroupId))) =
          UPPER(LTRIM(RTRIM(@IUNIDAD)))
      AND A.Id IN ('CLIENTES.VIEW','CLIENTES.EDIT');
 
    SET @CAN_VIEW=ISNULL(@CAN_VIEW,0);
    SET @CAN_EDIT=ISNULL(@CAN_EDIT,0);
 
    /* ============================================================
       2. SHELL GENERAL DEL FRAMEWORK
       ------------------------------------------------------------
       Devuelve Sidebar + Header común.
       El título y subtítulo de la Vista 360 se pasan dinámicamente
       al shell para evitar una cabecera propia dentro del módulo.
       ============================================================ */
    DECLARE @RESULTADO_SHELL VARCHAR(20) = '';
 
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Vista 360 de Cliente',
             @SUBTITLE           = 'Información completa del cliente, sus proyectos y relaciones.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL = '';
        SET @RESULTADO_SHELL = 'ERROR';
    END CATCH;
 
    IF ISNULL(@CAN_VIEW,0) = 0
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + '
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para ver la Vista 360 de Clientes.</p>
        </div>
    </section>
</div>';
        SET @OUTPARAM2 = '';
        SET @OUTPARAM3 = '';
        RETURN;
    END;
 
    /* ============================================================
       3. CLIENTE SELECCIONADO
       ============================================================ */
    DECLARE @IDCLIENTE_SELEC INT;
 
    SELECT TOP 1
        @IDCLIENTE_SELEC = ISNULL(IDSELEC01,0)
    FROM dbo.VCT_BUFFER WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    IF OBJECT_ID('tempdb..#CLIENTE360') IS NOT NULL DROP TABLE #CLIENTE360;
 
    CREATE TABLE #CLIENTE360
    (
        ID            INT,
        RAZON_SOCIAL  VARCHAR(300),
        CUIT          VARCHAR(50),
        TIPO          VARCHAR(100),
        ESTADO        VARCHAR(50),
        FECHA_ALTA    DATETIME,
        USUARIO_ALTA  VARCHAR(100),
        FECHA_UPD     DATETIME,
        USUARIO_UPD   VARCHAR(100)
    );
 
    DECLARE @COL_CLI_ID      SYSNAME;
    DECLARE @COL_CLI_RAZON   SYSNAME;
    DECLARE @COL_CLI_CUIT    SYSNAME;
    DECLARE @COL_CLI_TIPO    SYSNAME;
    DECLARE @COL_CLI_ESTADO  SYSNAME;
    DECLARE @COL_CLI_FALTA   SYSNAME;
    DECLARE @COL_CLI_UALTA   SYSNAME;
    DECLARE @COL_CLI_FUPD    SYSNAME;
    DECLARE @COL_CLI_UUPD    SYSNAME;
 
    SET @COL_CLI_ID     = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','ID') IS NOT NULL THEN 'ID' ELSE 'ID_CLIENTE' END;
    SET @COL_CLI_RAZON  = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','RAZON_SOCIAL') IS NOT NULL THEN 'RAZON_SOCIAL' ELSE 'RAZON_SOCIAL_CLIENTE' END;
    SET @COL_CLI_CUIT   = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','CUIT') IS NOT NULL THEN 'CUIT' ELSE 'CUIT_CLIENTE' END;
    SET @COL_CLI_TIPO   = CASE
                            WHEN COL_LENGTH('dbo.VCT_CLIENTES','TIPO') IS NOT NULL THEN 'TIPO'
                            WHEN COL_LENGTH('dbo.VCT_CLIENTES','TIPO_CLIENTE') IS NOT NULL THEN 'TIPO_CLIENTE'
                            ELSE NULL
                          END;
    SET @COL_CLI_ESTADO = CASE
                            WHEN COL_LENGTH('dbo.VCT_CLIENTES','ESTADO') IS NOT NULL THEN 'ESTADO'
                            WHEN COL_LENGTH('dbo.VCT_CLIENTES','STATUS_CLIENTE') IS NOT NULL THEN 'STATUS_CLIENTE'
                            ELSE NULL
                          END;
    SET @COL_CLI_FALTA  = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','FECHA_ALTA') IS NOT NULL THEN 'FECHA_ALTA' ELSE NULL END;
    SET @COL_CLI_UALTA  = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','USUARIO_ALTA') IS NOT NULL THEN 'USUARIO_ALTA' ELSE NULL END;
    SET @COL_CLI_FUPD   = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','FECHA_UPD') IS NOT NULL THEN 'FECHA_UPD' ELSE NULL END;
    SET @COL_CLI_UUPD   = CASE WHEN COL_LENGTH('dbo.VCT_CLIENTES','USUARIO_UPD') IS NOT NULL THEN 'USUARIO_UPD' ELSE NULL END;
 
    DECLARE @SQL_CLIENTE NVARCHAR(MAX);
 
    SET @SQL_CLIENTE =
        N'INSERT INTO #CLIENTE360
         (ID, RAZON_SOCIAL, CUIT, TIPO, ESTADO, FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD)
         SELECT TOP 1
             CONVERT(INT,' + QUOTENAME(@COL_CLI_ID) + '),
             CONVERT(VARCHAR(300),' + QUOTENAME(@COL_CLI_RAZON) + '),
             CONVERT(VARCHAR(50),' + QUOTENAME(@COL_CLI_CUIT) + '),' +
             CASE WHEN @COL_CLI_TIPO IS NULL THEN 'NULL' ELSE 'CONVERT(VARCHAR(100),' + QUOTENAME(@COL_CLI_TIPO) + ')' END + ',' +
             CASE WHEN @COL_CLI_ESTADO IS NULL THEN 'NULL' ELSE 'CONVERT(VARCHAR(50),' + QUOTENAME(@COL_CLI_ESTADO) + ')' END + ',' +
             CASE WHEN @COL_CLI_FALTA IS NULL THEN 'NULL' ELSE QUOTENAME(@COL_CLI_FALTA) END + ',' +
             CASE WHEN @COL_CLI_UALTA IS NULL THEN 'NULL' ELSE 'CONVERT(VARCHAR(100),' + QUOTENAME(@COL_CLI_UALTA) + ')' END + ',' +
             CASE WHEN @COL_CLI_FUPD IS NULL THEN 'NULL' ELSE QUOTENAME(@COL_CLI_FUPD) END + ',' +
             CASE WHEN @COL_CLI_UUPD IS NULL THEN 'NULL' ELSE 'CONVERT(VARCHAR(100),' + QUOTENAME(@COL_CLI_UUPD) + ')' END + '
         FROM dbo.VCT_CLIENTES WITH (NOLOCK)
         WHERE CONVERT(VARCHAR(100),' + QUOTENAME(@COL_CLI_ID) + ') = @PIDCLIENTE;';
 
    EXEC sp_executesql
         @SQL_CLIENTE,
         N'@PIDCLIENTE INT',
         @PIDCLIENTE = @IDCLIENTE_SELEC;
 
    DECLARE
        @ID_CLIENTE   INT,
        @Cliente      VARCHAR(300) = '',
        @CUIT         VARCHAR(50)  = '',
        @Tipo         VARCHAR(100) = '',
        @Estado       VARCHAR(50)  = '',
        @FechaAlta    DATETIME     = NULL,
        @UsuarioAlta  VARCHAR(100) = '',
        @FechaUpd     DATETIME     = NULL,
        @UsuarioUpd   VARCHAR(100) = '';
 
    SELECT TOP 1
        @ID_CLIENTE  = ID,
        @Cliente     = ISNULL(RAZON_SOCIAL,''),
        @CUIT        = ISNULL(CUIT,''),
        @Tipo        = ISNULL(TIPO,''),
        @Estado      = ISNULL(ESTADO,''),
        @FechaAlta   = FECHA_ALTA,
        @UsuarioAlta = ISNULL(USUARIO_ALTA,''),
        @FechaUpd    = FECHA_UPD,
        @UsuarioUpd  = ISNULL(USUARIO_UPD,'')
    FROM #CLIENTE360;
 
    IF @ID_CLIENTE IS NULL
    BEGIN
        SET @OUTPARAM1 = ISNULL(@HTML_SHELL,'') + '
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-form-id="' + ISNULL(@FORM_ID,'') + '">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Sin cliente seleccionado</h2>
            <p class="vct-card-subtitle">Volvé al listado de Clientes y elegí uno para ver su Vista 360.</p>
        </div>
    </section>
</div>';
        SET @OUTPARAM2 = '';
        SET @OUTPARAM3 = '';
        RETURN;
    END;
 
    DECLARE @AntiguedadAnios INT =
        CASE WHEN @FechaAlta IS NULL THEN NULL ELSE DATEDIFF(YEAR,@FechaAlta,GETDATE()) END;
 
 
    /* ============================================================
       3B. CRUD DATOS RELACIONADOS - MISMO SP
       ------------------------------------------------------------
       FLAG01    = 1 indica Guardar.
       TEXTO30   identifica la entidad:
                    DOMICILIO / TELEFONO / EMAIL / CONTACTO
       IDSELEC02 vacío -> ALTA
       IDSELEC02 valor -> EDICION
       IDSELEC01       -> cliente padre (se conserva)
 
       ACTION NO se modifica.
       ============================================================ */
    DECLARE
        @VFORM_SAVE      VARCHAR(10)='',
        @VFORM_DELETE    VARCHAR(10)='',
        @VFORM_PRINCIPAL VARCHAR(10)='',
        @VFORM_ENTITY    VARCHAR(30)='',
        @VFORM_ROW_ID    VARCHAR(100)='',
        @VFORM_T11       VARCHAR(1000)='',
        @VFORM_T12       VARCHAR(1000)='',
        @VFORM_T13       VARCHAR(1000)='',
        @VFORM_T14       VARCHAR(1000)='',
        @VFORM_T15       VARCHAR(1000)='',
        @VFORM_T16       VARCHAR(1000)='',
        @VFORM_T17       VARCHAR(2000)='',
        @VFORM_FLAG02    VARCHAR(10)='0',
        @VFORM_ERROR     VARCHAR(1000)='',
        @VFORM_REOPEN    BIT=0,
        @ACTIVE_TAB      VARCHAR(50)='resumen';
 
    SELECT TOP 1
        @VFORM_SAVE      = ISNULL(CONVERT(VARCHAR(10),FLAG01),''),
        @VFORM_DELETE    = ISNULL(CONVERT(VARCHAR(10),FLAG03),''),
        @VFORM_PRINCIPAL = ISNULL(CONVERT(VARCHAR(10),FLAG04),''),
        @VFORM_FLAG02    = ISNULL(CONVERT(VARCHAR(10),FLAG02),'0'),
        @VFORM_ENTITY = UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @VFORM_ROW_ID = LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(100),IDSELEC02),''))),
        @VFORM_T11    = ISNULL(TEXTO11,''),
        @VFORM_T12    = ISNULL(TEXTO12,''),
        @VFORM_T13    = ISNULL(TEXTO13,''),
        @VFORM_T14    = ISNULL(TEXTO14,''),
        @VFORM_T15    = ISNULL(TEXTO15,''),
        @VFORM_T16    = ISNULL(TEXTO16,''),
        @VFORM_T17    = ISNULL(TEXTO17,''),
        @ACTIVE_TAB   = ISNULL(NULLIF(ACTIVE_TAB,''),'resumen')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    /* Compatibilidad defensiva con buffers contaminados por versiones
       anteriores del JS: varios drawers podían compartir el mismo name
       SP.xxx y el framework concatenaba los controles con comas.
       Sólo normalizamos campos de CONTROL. */
    IF CHARINDEX(',',ISNULL(@VFORM_ENTITY,''))>0
        SET @VFORM_ENTITY=LEFT(@VFORM_ENTITY,CHARINDEX(',',@VFORM_ENTITY)-1);
 
    IF CHARINDEX(',',ISNULL(@VFORM_ROW_ID,''))>0
        SET @VFORM_ROW_ID=LEFT(@VFORM_ROW_ID,CHARINDEX(',',@VFORM_ROW_ID)-1);
 
    IF CHARINDEX(',',ISNULL(@ACTIVE_TAB,''))>0
        SET @ACTIVE_TAB=LEFT(@ACTIVE_TAB,CHARINDEX(',',@ACTIVE_TAB)-1);
 
    SET @VFORM_ENTITY=UPPER(LTRIM(RTRIM(ISNULL(@VFORM_ENTITY,''))));
    SET @VFORM_ROW_ID=LTRIM(RTRIM(ISNULL(@VFORM_ROW_ID,'')));
    SET @ACTIVE_TAB=ISNULL(NULLIF(LTRIM(RTRIM(@ACTIVE_TAB)),''),'resumen');
 
    /* Gestiones deja de ser una pestaña independiente en Cliente 360. */
    IF @ACTIVE_TAB='gestiones' SET @ACTIVE_TAB='resumen';
 
    /* Si no estamos volviendo de una acción interna de la 360,
       la navegación es una entrada nueva y debe iniciar en Resumen. */
    DECLARE @V360_RESET_TAB BIT;
    SET @V360_RESET_TAB =
        CASE
            WHEN @VFORM_SAVE='1'
              OR @VFORM_DELETE='1'
              OR @VFORM_PRINCIPAL='1'
                THEN 0
            ELSE 1
        END;
 
    /* Entrada nueva a una Vista 360: los slots de los drawers son
       transitorios y no deben heredarse de otro cliente ni de una
       validación anterior. IDSELEC01 se conserva porque identifica
       al cliente seleccionado. */
    IF @V360_RESET_TAB=1
    BEGIN
        UPDATE dbo.VCT_BUFFER
           SET IDSELEC02=NULL,
               TEXTO11=NULL,
               TEXTO12=NULL,
               TEXTO13=NULL,
               TEXTO14=NULL,
               TEXTO15=NULL,
               TEXTO16=NULL,
               TEXTO17=NULL,
               TEXTO30=NULL,
               FLAG01=0,
               FLAG02=0,
               FLAG03=0,
               FLAG04=0,
               ACTIVE_TAB='resumen'
         WHERE PAR_KEY=@IPKEYJOB;
 
        SET @VFORM_SAVE='';
        SET @VFORM_DELETE='';
        SET @VFORM_PRINCIPAL='';
        SET @VFORM_FLAG02='0';
        SET @VFORM_ENTITY='';
        SET @VFORM_ROW_ID='';
        SET @VFORM_T11='';
        SET @VFORM_T12='';
        SET @VFORM_T13='';
        SET @VFORM_T14='';
        SET @VFORM_T15='';
        SET @VFORM_T16='';
        SET @VFORM_T17='';
        SET @VFORM_ERROR='';
        SET @VFORM_REOPEN=0;
        SET @ACTIVE_TAB='resumen';
    END;
 
 
    /* ============================================================
       3A. ELIMINAR REGISTRO RELACIONADO
       ------------------------------------------------------------
       FLAG03=1, TEXTO30=entidad, IDSELEC02=id del registro.
       ACTION no se modifica.
       ============================================================ */
    IF @VFORM_DELETE='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para eliminar datos del cliente.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibió el registro a eliminar.';
 
        IF @VFORM_ERROR=''
        BEGIN TRY
            IF @VFORM_ENTITY='DOMICILIO'
            BEGIN
                DELETE FROM dbo.VCT_DOMICILIOS
                WHERE TIPO_ENTIDAD='CLIENTE'
                  AND ID_ENTIDAD=@ID_CLIENTE
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al cliente.';
 
                SET @ACTIVE_TAB='domicilio';
            END
            ELSE IF @VFORM_ENTITY='TELEFONO'
            BEGIN
                DELETE FROM dbo.VCT_TELEFONOS
                WHERE TIPO_ENTIDAD='CLIENTE'
                  AND ID_ENTIDAD=@ID_CLIENTE
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El teléfono seleccionado ya no existe o no pertenece al cliente.';
 
                SET @ACTIVE_TAB='telefonos';
            END
            ELSE IF @VFORM_ENTITY='EMAIL'
            BEGIN
                DELETE FROM dbo.VCT_EMAILS
                WHERE TIPO_ENTIDAD='CLIENTE'
                  AND ID_ENTIDAD=@ID_CLIENTE
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al cliente.';
 
                SET @ACTIVE_TAB='email';
            END
            ELSE IF @VFORM_ENTITY='CONTACTO'
            BEGIN
                IF COL_LENGTH('dbo.VCT_CONTACTOS','ID') IS NULL
                    SET @VFORM_ERROR='No se puede eliminar el contacto porque VCT_CONTACTOS no posee columna ID.';
                ELSE
                BEGIN
                    DECLARE @SQL_DEL_CONT NVARCHAR(MAX);
                    SET @SQL_DEL_CONT =
                        N'DELETE FROM dbo.VCT_CONTACTOS
                          WHERE IDCLIENTE=@PC
                            AND CONVERT(VARCHAR(100),ID)=@PID;';
 
                    EXEC sp_executesql
                         @SQL_DEL_CONT,
                         N'@PC INT,@PID VARCHAR(100)',
                         @PC=@ID_CLIENTE,
                         @PID=@VFORM_ROW_ID;
                END;
                SET @ACTIVE_TAB='contacto';
            END
            ELSE
                SET @VFORM_ERROR='Entidad no válida para eliminar.';
        END TRY
        BEGIN CATCH
            SET @VFORM_ERROR=ERROR_MESSAGE();
        END CATCH;
 
        UPDATE dbo.VCT_BUFFER
           SET IDSELEC02=NULL,
               TEXTO11=NULL,
               TEXTO12=NULL,
               TEXTO13=NULL,
               TEXTO14=NULL,
               TEXTO15=NULL,
               TEXTO16=NULL,
               TEXTO17=NULL,
               TEXTO30=NULL,
               FLAG01=0,
               FLAG02=0,
               FLAG03=0,
               FLAG04=0,
               ACTIVE_TAB=@ACTIVE_TAB
         WHERE PAR_KEY=@IPKEYJOB;
    END;
 
 
    /* ============================================================
       3B. MARCAR REGISTRO COMO PRINCIPAL
       ------------------------------------------------------------
       FLAG04=1, TEXTO30=entidad, IDSELEC02=id del registro.
       Se soporta:
         DOMICILIO / TELEFONO / EMAIL / CONTACTO
       ACTION no se modifica.
       ============================================================ */
    IF @VFORM_PRINCIPAL='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para modificar datos del cliente.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibió el registro a marcar como principal.';
 
        IF @VFORM_ERROR=''
        BEGIN TRY
            IF @VFORM_ENTITY='DOMICILIO'
            BEGIN
                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
                    WHERE TIPO_ENTIDAD='CLIENTE'
                      AND ID_ENTIDAD=@ID_CLIENTE
                      AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID
                )
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al cliente.';
                ELSE
                BEGIN
                    UPDATE dbo.VCT_DOMICILIOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE;
 
                    UPDATE dbo.VCT_DOMICILIOS
                       SET PRINCIPAL='SI'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
                END;
 
                SET @ACTIVE_TAB='domicilio';
            END
            ELSE IF @VFORM_ENTITY='TELEFONO'
            BEGIN
                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
                    WHERE TIPO_ENTIDAD='CLIENTE'
                      AND ID_ENTIDAD=@ID_CLIENTE
                      AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID
                )
                    SET @VFORM_ERROR='El teléfono seleccionado ya no existe o no pertenece al cliente.';
                ELSE
                BEGIN
                    UPDATE dbo.VCT_TELEFONOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE;
 
                    UPDATE dbo.VCT_TELEFONOS
                       SET PRINCIPAL='SI'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
                END;
 
                SET @ACTIVE_TAB='telefonos';
            END
            ELSE IF @VFORM_ENTITY='EMAIL'
            BEGIN
                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.VCT_EMAILS WITH(NOLOCK)
                    WHERE TIPO_ENTIDAD='CLIENTE'
                      AND ID_ENTIDAD=@ID_CLIENTE
                      AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID
                )
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al cliente.';
                ELSE
                BEGIN
                    UPDATE dbo.VCT_EMAILS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE;
 
                    UPDATE dbo.VCT_EMAILS
                       SET PRINCIPAL='SI'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
                END;
 
                SET @ACTIVE_TAB='email';
            END
            ELSE IF @VFORM_ENTITY='CONTACTO'
            BEGIN
                SET @VFORM_ERROR='Los contactos no manejan un registro principal.';
                SET @ACTIVE_TAB='contacto';
            END
            ELSE
                SET @VFORM_ERROR='Entidad no válida para marcar como principal.';
        END TRY
        BEGIN CATCH
            SET @VFORM_ERROR=ERROR_MESSAGE();
        END CATCH;
 
        UPDATE dbo.VCT_BUFFER
           SET IDSELEC02=NULL,
               TEXTO11=NULL,
               TEXTO12=NULL,
               TEXTO13=NULL,
               TEXTO14=NULL,
               TEXTO15=NULL,
               TEXTO16=NULL,
               TEXTO17=NULL,
               TEXTO30=NULL,
               FLAG01=0,
               FLAG02=0,
               FLAG03=0,
               FLAG04=0,
               ACTIVE_TAB=@ACTIVE_TAB
         WHERE PAR_KEY=@IPKEYJOB;
    END;
 
    IF @VFORM_SAVE='1'
    BEGIN
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para modificar datos del cliente.';
 
        /* ---------------- DOMICILIO ---------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='La calle / avenida es obligatoria.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El número es obligatorio.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T15)),'') IS NULL
                SET @VFORM_ERROR='La localidad es obligatoria.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T16)),'') IS NULL
                SET @VFORM_ERROR='La provincia es obligatoria.';
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.CAT_DATA CD WITH(NOLOCK)
                WHERE CD.PAR_KEY =
                (
                    SELECT TOP 1 CT.PKEY
                    FROM dbo.CAT_TYPE CT WITH(NOLOCK)
                    WHERE CT.CAT_TYPE_CODE='Provincia'
                )
                  AND LTRIM(RTRIM(CONVERT(VARCHAR(100),CD.CAT_DATA_CODE))) =
                      LTRIM(RTRIM(@VFORM_T16))
            )
                SET @VFORM_ERROR='Seleccione una provincia válida.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                    UPDATE dbo.VCT_DOMICILIOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND (@VFORM_ROW_ID='' OR CONVERT(VARCHAR(100),ID)<>@VFORM_ROW_ID);
 
                IF @VFORM_ROW_ID=''
                    INSERT INTO dbo.VCT_DOMICILIOS
                    (TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES)
                    VALUES
                    (
                        'CLIENTE',
                        @ID_CLIENTE,
                        LTRIM(RTRIM(@VFORM_T11)),
                        NULLIF(LTRIM(RTRIM(@VFORM_T12)),''),
                        NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                        NULLIF(LTRIM(RTRIM(@VFORM_T14)),''),
                        NULLIF(LTRIM(RTRIM(@VFORM_T15)),''),
                        NULLIF(LTRIM(RTRIM(@VFORM_T16)),''),
                        CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                        NULLIF(LTRIM(RTRIM(@VFORM_T17)),'')
                    );
                ELSE
                BEGIN
                    UPDATE dbo.VCT_DOMICILIOS
                       SET CALLE=Ltrim(RTRIM(@VFORM_T11)),
                           NRO=NULLIF(LTRIM(RTRIM(@VFORM_T12)),''),
                           PISO=NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                           DEPTO=NULLIF(LTRIM(RTRIM(@VFORM_T14)),''),
                           LOCALIDAD=NULLIF(LTRIM(RTRIM(@VFORM_T15)),''),
                           PROVINCIA=NULLIF(LTRIM(RTRIM(@VFORM_T16)),''),
                           PRINCIPAL=CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T17)),'')
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El domicilio a editar ya no existe o no pertenece al cliente.';
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;
 
        /* ---------------- TELEFONO ---------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='TELEFONO'
        BEGIN
            SET @ACTIVE_TAB='telefonos';
 
            IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El código de área es obligatorio.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El número es obligatorio.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                    UPDATE dbo.VCT_TELEFONOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND (@VFORM_ROW_ID='' OR CONVERT(VARCHAR(100),ID)<>@VFORM_ROW_ID);
 
                IF @VFORM_ROW_ID=''
                    INSERT INTO dbo.VCT_TELEFONOS
                    (TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES)
                    VALUES
                    (
                        'CLIENTE',
                        @ID_CLIENTE,
                        @VFORM_T11,
                        @VFORM_T12,
                        CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                        NULLIF(LTRIM(RTRIM(@VFORM_T13)),'')
                    );
                ELSE
                BEGIN
                    UPDATE dbo.VCT_TELEFONOS
                       SET CODAREA=@VFORM_T11,
                           NRO=@VFORM_T12,
                           PRINCIPAL=CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T13)),'')
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El teléfono a editar ya no existe o no pertenece al cliente.';
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;
 
        /* ---------------- EMAIL ---------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL'
        BEGIN
            SET @ACTIVE_TAB='email';
 
            IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El email es obligatorio.';
            ELSE IF LTRIM(RTRIM(@VFORM_T11)) NOT LIKE '%_@_%._%'
                SET @VFORM_ERROR='El email no tiene un formato válido.';
            ELSE IF EXISTS
            (
                SELECT 1
                FROM dbo.VCT_EMAILS E WITH(NOLOCK)
                WHERE E.TIPO_ENTIDAD='CLIENTE'
                  AND E.ID_ENTIDAD=@ID_CLIENTE
                  AND LOWER(LTRIM(RTRIM(ISNULL(E.EMAIL,''))))=
                      LOWER(LTRIM(RTRIM(@VFORM_T11)))
                  AND (@VFORM_ROW_ID='' OR CONVERT(VARCHAR(100),E.ID)<>@VFORM_ROW_ID)
            )
                SET @VFORM_ERROR='El cliente ya posee ese email registrado.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                    UPDATE dbo.VCT_EMAILS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND (@VFORM_ROW_ID='' OR CONVERT(VARCHAR(100),ID)<>@VFORM_ROW_ID);
 
                IF @VFORM_ROW_ID=''
                    INSERT INTO dbo.VCT_EMAILS
                    (TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES)
                    VALUES
                    (
                        'CLIENTE',
                        @ID_CLIENTE,
                        LTRIM(RTRIM(@VFORM_T11)),
                        CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                        NULLIF(LTRIM(RTRIM(@VFORM_T12)),'')
                    );
                ELSE
                BEGIN
                    UPDATE dbo.VCT_EMAILS
                       SET EMAIL=LTRIM(RTRIM(@VFORM_T11)),
                           PRINCIPAL=CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T12)),'')
                     WHERE TIPO_ENTIDAD='CLIENTE'
                       AND ID_ENTIDAD=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El email a editar ya no existe o no pertenece al cliente.';
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;
 
        /* ---------------- CONTACTO ----------------
           Estructura real de dbo.VCT_CONTACTOS:
             ID, IDCLIENTE, APELLIDO, NOMBRES, CARGO, ID_DOMICILIO,
             ID_TELEFONO, ID_EMAIL, OBSERVACIONES,
             FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD.
 
           TEXTO11 = NOMBRES
           TEXTO12 = APELLIDO
           TEXTO13 = CARGO
           TEXTO14 = ID_TELEFONO
           TEXTO15 = ID_EMAIL
           TEXTO16 = OBSERVACIONES
        */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='CONTACTO'
        BEGIN
            SET @ACTIVE_TAB='contacto';
 
            IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='Los nombres del contacto son obligatorios.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El apellido del contacto es obligatorio.';
            ELSE IF LEN(LTRIM(RTRIM(ISNULL(@VFORM_T13,'')))) > 100
                SET @VFORM_ERROR='El cargo no puede superar los 100 caracteres.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T14)),'') IS NOT NULL
                 AND NOT EXISTS
                 (
                    SELECT 1
                    FROM dbo.VCT_TELEFONOS T WITH(NOLOCK)
                    WHERE T.TIPO_ENTIDAD='CLIENTE'
                      AND T.ID_ENTIDAD=@ID_CLIENTE
                      AND CONVERT(VARCHAR(50),T.ID)=LTRIM(RTRIM(@VFORM_T14))
                 )
                SET @VFORM_ERROR='Seleccione un teléfono registrado para el cliente.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T15)),'') IS NOT NULL
                 AND NOT EXISTS
                 (
                    SELECT 1
                    FROM dbo.VCT_EMAILS E WITH(NOLOCK)
                    WHERE E.TIPO_ENTIDAD='CLIENTE'
                      AND E.ID_ENTIDAD=@ID_CLIENTE
                      AND CONVERT(VARCHAR(50),E.ID)=LTRIM(RTRIM(@VFORM_T15))
                 )
                SET @VFORM_ERROR='Seleccione un email registrado para el cliente.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_ROW_ID=''
                BEGIN
                    INSERT INTO dbo.VCT_CONTACTOS
                    (
                        IDCLIENTE, APELLIDO, NOMBRES, CARGO, ID_DOMICILIO,
                        ID_TELEFONO, ID_EMAIL, OBSERVACIONES,
                        FECHA_ALTA, USUARIO_ALTA, FECHA_UPD, USUARIO_UPD
                    )
                    VALUES
                    (
                        @ID_CLIENTE,
                        LTRIM(RTRIM(@VFORM_T12)),
                        LTRIM(RTRIM(@VFORM_T11)),
                        NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                        NULL,
                        CONVERT(INT,NULLIF(LTRIM(RTRIM(@VFORM_T14)),'')),
                        CONVERT(INT,NULLIF(LTRIM(RTRIM(@VFORM_T15)),'')),
                        NULLIF(LTRIM(RTRIM(@VFORM_T16)),''),
                        GETDATE(),
                        @IAGENTE,
                        NULL,
                        NULL
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_CONTACTOS
                       SET APELLIDO=LTRIM(RTRIM(@VFORM_T12)),
                           NOMBRES=LTRIM(RTRIM(@VFORM_T11)),
                           CARGO=NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                           ID_TELEFONO=CONVERT(INT,NULLIF(LTRIM(RTRIM(@VFORM_T14)),'')),
                           ID_EMAIL=CONVERT(INT,NULLIF(LTRIM(RTRIM(@VFORM_T15)),'')),
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T16)),''),
                           FECHA_UPD=GETDATE(),
                           USUARIO_UPD=@IAGENTE
                     WHERE IDCLIENTE=@ID_CLIENTE
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El contacto a editar ya no existe o no pertenece al cliente.';
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;
 
                /* ---------------- PROYECTO (alta desde el menu del encabezado) ----------------
           Valida y graba dbo.VCT_PROYECTO_ALTA_GUARDAR (permiso PROYECTOS.CREATE). */
        IF @VFORM_ENTITY='PROYECTO'
        BEGIN
            SET @ACTIVE_TAB='proyectos';
            SET @VFORM_ERROR='';
            SET @PROY_ALTA_ERR='';
            SET @PROY_ALTA_MSG='';
 
            BEGIN TRY
                EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR
                     @IPKEYJOB=@IPKEYJOB,
                     @IUNIDAD=@IUNIDAD,
                     @IAGENTE=@IAGENTE,
                     @ID_CLIENTE=@ID_CLIENTE,
                     @ERROR=@PROY_ALTA_ERR OUTPUT,
                     @MENSAJE=@PROY_ALTA_MSG OUTPUT;
 
                SET @VFORM_ERROR=LEFT(ISNULL(@PROY_ALTA_ERR,''),1000);
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=LEFT('No se pudo grabar el proyecto: '+ERROR_MESSAGE(),1000);
            END CATCH;
 
            IF @VFORM_ERROR<>'' SET @PROY_ALTA_MSG='';
        END;
 
        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;
 
        /* Si hubo error conservamos los valores para reabrir el drawer.
           Si grabó correctamente, limpiamos todo el payload transitorio para
           que no pueda reaparecer al entrar a otra Vista 360. */
        IF @VFORM_ERROR<>''
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET FLAG01=0,
                   FLAG03=0,
                   FLAG04=0,
                   ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END
        ELSE
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET IDSELEC02=NULL,
                   TEXTO11=NULL,
                   TEXTO12=NULL,
                   TEXTO13=NULL,
                   TEXTO14=NULL,
                   TEXTO15=NULL,
                   TEXTO16=NULL,
                   TEXTO17=NULL,
                   TEXTO30=NULL,
                   FLAG01=0,
                   FLAG02=0,
                   FLAG03=0,
                   FLAG04=0,
                   ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END;
    END;
 
    /* ============================================================
       4. DATOS PRINCIPALES DE DOMICILIO / TELEFONO / EMAIL
       ============================================================ */
    DECLARE
        @Domicilio    VARCHAR(500) = '',
        @Localidad    VARCHAR(100) = '',
        @Provincia    VARCHAR(100) = '',
        @Telefono     VARCHAR(100) = '',
        @Email        VARCHAR(100) = '';
 
    SELECT TOP 1
        @Domicilio =
            LTRIM(RTRIM(
                ISNULL(D.CALLE,'') +
                CASE WHEN D.NRO IS NULL THEN '' ELSE ' ' + CONVERT(VARCHAR(20),D.NRO) END +
                CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.PISO,''))), '') IS NULL THEN '' ELSE ' - Piso ' + D.PISO END +
                CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.DEPTO,''))), '') IS NULL THEN '' ELSE ' ' + D.DEPTO END
            )),
        @Localidad = ISNULL(D.LOCALIDAD,''),
        @Provincia = ISNULL(D.PROVINCIA,'')
    FROM dbo.VCT_DOMICILIOS D WITH (NOLOCK)
    WHERE D.TIPO_ENTIDAD='CLIENTE'
      AND D.ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, D.ID;
 
    SELECT TOP 1
        @Telefono =
            CASE
                WHEN T.CODAREA IS NULL THEN CONVERT(VARCHAR(30),T.NRO)
                ELSE '(' + CONVERT(VARCHAR(10),T.CODAREA) + ') ' + CONVERT(VARCHAR(30),T.NRO)
            END
    FROM dbo.VCT_TELEFONOS T WITH (NOLOCK)
    WHERE T.TIPO_ENTIDAD='CLIENTE'
      AND T.ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, T.ID;
 
    SELECT TOP 1
        @Email = ISNULL(E.EMAIL,'')
    FROM dbo.VCT_EMAILS E WITH (NOLOCK)
    WHERE E.TIPO_ENTIDAD='CLIENTE'
      AND E.ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(E.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, E.ID;
 
    /* ============================================================
       5. CONTACTOS NORMALIZADOS
       Estructura real: NOMBRES/APELLIDO + FK a teléfono/email.
       ============================================================ */
    IF OBJECT_ID('tempdb..#CONTACTOS360') IS NOT NULL DROP TABLE #CONTACTOS360;
 
    CREATE TABLE #CONTACTOS360
    (
        ID            INT,
        NOMBRES       VARCHAR(100),
        APELLIDO      VARCHAR(100),
        CARGO         VARCHAR(100),
        NOMBRE        VARCHAR(300),
        ID_TELEFONO   INT,
        ID_EMAIL      INT,
        TELEFONO      VARCHAR(100),
        EMAIL         VARCHAR(200),
        OBSERVACIONES VARCHAR(1000)
    );
 
    INSERT INTO #CONTACTOS360
    (ID,NOMBRES,APELLIDO,CARGO,NOMBRE,ID_TELEFONO,ID_EMAIL,TELEFONO,EMAIL,OBSERVACIONES)
    SELECT
        C.ID,
        ISNULL(C.NOMBRES,''),
        ISNULL(C.APELLIDO,''),
        ISNULL(C.CARGO,''),
        LTRIM(RTRIM(ISNULL(C.NOMBRES,'') +
            CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(C.APELLIDO,''))), '') IS NULL
                 THEN '' ELSE ' ' + C.APELLIDO END)),
        C.ID_TELEFONO,
        C.ID_EMAIL,
        CASE
            WHEN T.ID IS NULL THEN NULL
            WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(20),T.CODAREA),''))), '') IS NULL
                THEN ISNULL(CONVERT(VARCHAR(50),T.NRO),'')
            ELSE '('+CONVERT(VARCHAR(20),T.CODAREA)+') '+ISNULL(CONVERT(VARCHAR(50),T.NRO),'')
        END,
        E.EMAIL,
        C.OBSERVACIONES
    FROM dbo.VCT_CONTACTOS C WITH(NOLOCK)
    LEFT JOIN dbo.VCT_TELEFONOS T WITH(NOLOCK)
        ON T.ID=C.ID_TELEFONO
       AND T.TIPO_ENTIDAD='CLIENTE'
       AND T.ID_ENTIDAD=C.IDCLIENTE
    LEFT JOIN dbo.VCT_EMAILS E WITH(NOLOCK)
        ON E.ID=C.ID_EMAIL
       AND E.TIPO_ENTIDAD='CLIENTE'
       AND E.ID_ENTIDAD=C.IDCLIENTE
    WHERE C.IDCLIENTE=@ID_CLIENTE;
 
    DECLARE
        @DomiciliosCount INT = 0,
        @TelefonosCount  INT = 0,
        @EmailsCount     INT = 0,
        @ContactosCount  INT = 0;
 
    SELECT @DomiciliosCount = COUNT(*)
    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE;
 
    SELECT @TelefonosCount = COUNT(*)
    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE;
 
    SELECT @EmailsCount = COUNT(*)
    FROM dbo.VCT_EMAILS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE;
 
    SELECT @ContactosCount = COUNT(*)
    FROM #CONTACTOS360;
 
    /* ============================================================
       6. PROYECTOS NORMALIZADOS - MODELO NUEVO
       ------------------------------------------------------------
       Resumen ejecutivo:
         - Analista explicito del equipo.
         - Un consultor principal visible por proyecto.
         - Montos/costos para KPI y rentabilidad.
       ============================================================ */
    IF OBJECT_ID('tempdb..#PROYECTOS360') IS NOT NULL DROP TABLE #PROYECTOS360;
 
    CREATE TABLE #PROYECTOS360
    (
        ID                  INT,
        CODIGO              VARCHAR(100),
        NOMBRE              VARCHAR(300),
        REFERENCIA          VARCHAR(300),
        ESTADO_CODIGO       VARCHAR(50),
        ESTADO              VARCHAR(100),
        FECHA_INICIO        DATETIME,
        FECHA_FIN           DATETIME,
        PORCENTAJE_AVANCE   INT,
        MONTO_PRES          NUMERIC(18,2),
        MONTO_TOTAL         NUMERIC(18,2),
        COSTO_TOTAL         NUMERIC(18,2),
        MONTO_COBRADO       NUMERIC(18,2),
        ANALISTA            VARCHAR(320),
        CONSULTOR_ID        INT,
        CONSULTOR_NOMBRE    VARCHAR(320)
    );
 
    INSERT INTO #PROYECTOS360
    (
        ID,CODIGO,NOMBRE,REFERENCIA,ESTADO_CODIGO,ESTADO,
        FECHA_INICIO,FECHA_FIN,PORCENTAJE_AVANCE,
        MONTO_PRES,MONTO_TOTAL,COSTO_TOTAL,MONTO_COBRADO,
        ANALISTA,CONSULTOR_ID,CONSULTOR_NOMBRE
    )
    SELECT
        P.ID,
        CONVERT(VARCHAR(100),P.CODIGO),
        P.NOMBRE,
        P.REFERENCIA,
        E.CODIGO,
        E.DESCRIPCION,
        P.FECHA_INICIO,
        P.FECHA_FIN,
        ISNULL(P.PORCENTAJE_AVANCE,0),
        ISNULL(P.MONTO_PRES,0),
        CASE
            WHEN P.MONTO_TOTAL IS NULL THEN ISNULL(P.MONTO_PRES,0)+ISNULL(P.MONTO_PRES_VIAT,0)
            ELSE P.MONTO_TOTAL
        END,
        ISNULL(P.COSTO_TOTAL,0),
        ISNULL(P.MONTO_COBRADO,0),
 
        ISNULL
        (
            (
                SELECT TOP 1
                    ISNULL
                    (
                        NULLIF(LTRIM(RTRIM(PV.NOMBRE)),''),
                        '#'+CONVERT(VARCHAR(20),EQ.ID_EMPLEADO)
                    )
                FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
                INNER JOIN dbo.VCT_PRM_PROYECTOS_ROLES ROL WITH(NOLOCK)
                    ON ROL.ID=EQ.ID_ROL
                LEFT JOIN dbo.VCT_VW_PERSONAS_V360 PV WITH(NOLOCK)
                    ON PV.TIPO_ENTIDAD='EMPLEADO'
                   AND PV.ID_ENTIDAD=EQ.ID_EMPLEADO
                WHERE EQ.ID_PROYECTO=P.ID
                  AND EQ.TIPO_MIEMBRO='EMPLEADO'
                  AND EQ.ID_EMPLEADO IS NOT NULL
                  AND ROL.CODIGO='ANALISTA'
                  AND ISNULL(NULLIF(UPPER(LTRIM(RTRIM(EQ.ESTADO))),''),'ACTIVO')<>'INACTIVO'
                ORDER BY EQ.PRINCIPAL DESC,EQ.ID
            ),
            '-'
        ),
 
        CP.ID_CONSULTOR,
 
        CASE
            WHEN CP.ID_CONSULTOR IS NULL THEN NULL
            WHEN NULLIF(LTRIM(RTRIM(CPV.NOMBRE)),'') IS NOT NULL
                THEN LTRIM(RTRIM(CPV.NOMBRE))
            ELSE '#'+CONVERT(VARCHAR(20),CP.ID_CONSULTOR)
        END
 
    FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
 
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS E WITH(NOLOCK)
        ON E.ID=P.ID_ESTADO
 
    OUTER APPLY
    (
        SELECT TOP 1 Q.ID_CONSULTOR
        FROM
        (
            SELECT
                EQ.ID_CONSULTOR,
                1 AS FUENTE,
                CASE WHEN ISNULL(EQ.PRINCIPAL,0)=1 THEN 0 ELSE 1 END AS ORDEN_INTERNO,
                EQ.ID AS ID_ORDEN
            FROM dbo.VCT_PROYECTOS_EQUIPO EQ WITH(NOLOCK)
            WHERE EQ.ID_PROYECTO=P.ID
              AND EQ.TIPO_MIEMBRO='CONSULTOR'
              AND EQ.ID_CONSULTOR IS NOT NULL
              AND ISNULL(NULLIF(UPPER(LTRIM(RTRIM(EQ.ESTADO))),''),'ACTIVO')<>'INACTIVO'
 
            UNION ALL
 
            SELECT
                VC.ID_CONSULTOR,
                2,
                CASE WHEN ISNULL(VC.LIDER,0)=1 THEN 0 ELSE 1 END,
                VC.ID
            FROM dbo.VCT_PROYECTOS_VISITAS V WITH(NOLOCK)
            INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC WITH(NOLOCK)
                ON VC.ID_VISITA=V.ID
            WHERE V.ID_PROYECTO=P.ID
              AND VC.ID_CONSULTOR IS NOT NULL
 
            UNION ALL
 
            SELECT
                GP.ID_ENTIDAD,
                3,
                CASE WHEN ISNULL(GP.PRINCIPAL,0)=1 THEN 0 ELSE 1 END,
                GP.ID
            FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
            INNER JOIN dbo.VCT_GESTIONES_PARTICIPANTES GP WITH(NOLOCK)
                ON GP.ID_GESTION=G.ID
            WHERE G.ID_PROYECTO=P.ID
              AND GP.TIPO_ENTIDAD='CONSULTOR'
              AND GP.ID_ENTIDAD IS NOT NULL
              AND GP.ROL_PARTICIPANTE='RESPONSABLE'
              AND GP.ESTADO='ACTIVO'
        ) Q
        ORDER BY Q.FUENTE,Q.ORDEN_INTERNO,Q.ID_ORDEN,Q.ID_CONSULTOR
    ) CP
 
    LEFT JOIN dbo.VCT_VW_PERSONAS_V360 CPV WITH(NOLOCK)
        ON CPV.TIPO_ENTIDAD='CONSULTOR'
       AND CPV.ID_ENTIDAD=CP.ID_CONSULTOR
 
    WHERE P.IDCLIENTE=@ID_CLIENTE;
 
    DECLARE
        @ProyectosCount       INT = 0,
        @ProyectosEnCurso     INT = 0,
        @ProyectosActivos     INT = 0,
        @MontoPresEnCurso     NUMERIC(18,2) = 0,
        @MontoCobradoEnCurso  NUMERIC(18,2) = 0,
        @MontoActivo          NUMERIC(18,2) = 0,
        @CostoActivo          NUMERIC(18,2) = 0,
        @AvanceEnCurso        NUMERIC(18,2) = 0,
        @AvanceActivo         NUMERIC(18,2) = 0,
        @GestionesCount       INT = 0,
        @GestionesTotalCount  INT = 0,
        @DocumentosCount      INT = 0,
        @NotasCount           INT = 0;
 
    SELECT
        @ProyectosCount = COUNT(*),
        @ProyectosEnCurso = SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN 1 ELSE 0 END),
        @ProyectosActivos = SUM(CASE WHEN ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN 1 ELSE 0 END),
        @MontoPresEnCurso = SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN ISNULL(MONTO_PRES,0) ELSE 0 END),
        @MontoCobradoEnCurso = SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN ISNULL(MONTO_COBRADO,0) ELSE 0 END),
        @MontoActivo = SUM(CASE WHEN ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN ISNULL(MONTO_TOTAL,0) ELSE 0 END),
        @CostoActivo = SUM(CASE WHEN ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN ISNULL(COSTO_TOTAL,0) ELSE 0 END)
    FROM #PROYECTOS360;
 
    SELECT
        @AvanceEnCurso = ISNULL(AVG(CONVERT(NUMERIC(18,2),PORCENTAJE_AVANCE)),0)
    FROM #PROYECTOS360
    WHERE ESTADO_CODIGO='ENCURSO';
 
    SELECT
        @AvanceActivo = ISNULL(AVG(CONVERT(NUMERIC(18,2),PORCENTAJE_AVANCE)),0)
    FROM #PROYECTOS360
    WHERE ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO');
 
    SET @ProyectosCount = ISNULL(@ProyectosCount,0);
    SET @ProyectosEnCurso = ISNULL(@ProyectosEnCurso,0);
    SET @ProyectosActivos = ISNULL(@ProyectosActivos,0);
    SET @MontoPresEnCurso = ISNULL(@MontoPresEnCurso,0);
    SET @MontoCobradoEnCurso = ISNULL(@MontoCobradoEnCurso,0);
    SET @MontoActivo = ISNULL(@MontoActivo,0);
    SET @CostoActivo = ISNULL(@CostoActivo,0);
    SET @AvanceActivo = ISNULL(@AvanceActivo,0);
 
    IF OBJECT_ID('dbo.VCT_PROYECTOS_DOCUMENTOS','U') IS NOT NULL
    BEGIN
        SELECT @DocumentosCount=COUNT(*)
        FROM dbo.VCT_PROYECTOS_DOCUMENTOS D WITH(NOLOCK)
        INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
            ON P.ID=D.ID_PROYECTO
        WHERE P.IDCLIENTE=@ID_CLIENTE;
    END;
 
    /* ============================================================
       GESTIONES ACTIVAS - MODELO NUEVO
       Activa = estado no final.
       ============================================================ */
    SET @GestionesCount=0;
    SET @GestionesTotalCount=0;
 
    BEGIN TRY
        SELECT @GestionesCount=COUNT(*)
        FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
            ON P.ID=G.ID_PROYECTO
        INNER JOIN dbo.VCT_PRM_GESTIONES_ESTADOS E WITH(NOLOCK)
            ON E.ID=G.ID_ESTADO
        WHERE ISNULL(G.ID_CLIENTE,P.IDCLIENTE)=@ID_CLIENTE
          AND E.ES_FINAL=0;
 
        SELECT @GestionesTotalCount=COUNT(*)
        FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
            ON P.ID=G.ID_PROYECTO
        WHERE ISNULL(G.ID_CLIENTE,P.IDCLIENTE)=@ID_CLIENTE;
    END TRY
    BEGIN CATCH
        SET @GestionesCount=0;
        SET @GestionesTotalCount=0;
    END CATCH;
 
    /* Footer genérico de grilla: mismo paginado que Clientes. */
    DECLARE @HTML_GRID_FOOTER VARCHAR(MAX) =
        '<div class="vct-grid-footer">' +
            '<div class="vct-grid-footer-info" data-vct-grid-info></div>' +
            '<div class="vct-pagination" data-vct-grid-pagination></div>' +
            '<div class="vct-grid-page-size">' +
                '<span>Registros por página:</span>' +
                '<select class="vct-select vct-select-sm" data-vct-grid-page-size>' +
                    '<option value="10">10</option>' +
                    '<option value="20">20</option>' +
                    '<option value="50">50</option>' +
                    '<option value="100">100</option>' +
                '</select>' +
            '</div>' +
        '</div>';
 
    /* ============================================================
       7. HTML PROYECTOS - COMPLETO Y TOP 5
       ============================================================ */
    DECLARE @HTML_PROYECTOS      VARCHAR(MAX) = '';
    DECLARE @HTML_PROYECTOS_TOP  VARCHAR(MAX) = '';
 
    SELECT @HTML_PROYECTOS = ISNULL((
        SELECT
            '<tr data-vct-row>' +
                '<td data-label="Proyecto"><span class="vct-360-project-name">(' + EscCodigo + ') ' + EscNombre + '</span>' +
                    CASE WHEN EscReferencia <> '' THEN '<span class="vct-360-project-ref">' + EscReferencia + '</span>' ELSE '' END +
                '</td>' +
                '<td class="vct-text-center" data-label="Estado"><span class="vct-360-badge ' + EstadoClase + '">' + EscEstado + '</span></td>' +
                '<td class="vct-text-center" data-label="Inicio">' + FInicioTxt + '</td>' +
                '<td class="vct-text-center" data-label="Fin">' + FFinTxt + '</td>' +
                '<td class="vct-text-center" data-label="Avance" data-vct-sort-value="' + AvanceTxt + '"><div class="vct-360-progress"><div class="vct-360-progress-bar" style="background:#66062D !important;width:' + AvanceBarTxt + '%;"></div></div>' +
                    '<span class="vct-360-progress-label">' + AvanceTxt + '%</span></td>' +
                '<td class="vct-360-action-cell vct-table-action-cell" data-label="360" data-vct-export-ignore="true">' +
                    '<button type="button" class="vct-row-menu-trigger" ' +
                    'data-vct-command="grid-action" ' +
                    'data-vct-store="IDSELEC02" ' +
                    'data-vct-value="' + CONVERT(VARCHAR(20),SortID) + '" ' +
                    'data-vct-guid="330B876D-4E57-4E2E-BFC3-D7B998D09725" ' +
                    'title="Vista 360 Proyecto">' +
                    '<span data-vct-icon="scan-eye"></span>' +
                    '</button>' +
                '</td>' +
            '</tr>'
        FROM
        (
            SELECT
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscCodigo,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscReferencia,
                REPLACE(REPLACE(REPLACE(REPLACE(
                    CASE
                        WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'ACTIVO'
                        ELSE ISNULL(NULLIF(P.ESTADO,''),'Sin estado')
                    END,
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscEstado,
                CASE
                    WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'is-progress'
                    WHEN P.ESTADO_CODIGO='CONFIRMADO' THEN 'is-planned'
                    WHEN P.ESTADO_CODIGO='TERMINADO' THEN 'is-done'
                    WHEN P.ESTADO_CODIGO='CANCELADO' THEN 'is-cancel'
                    ELSE 'is-neutral'
                END AS EstadoClase,
                ISNULL(CONVERT(VARCHAR(10),P.FECHA_INICIO,103),'-') AS FInicioTxt,
                ISNULL(CONVERT(VARCHAR(10),P.FECHA_FIN,103),'-') AS FFinTxt,
                CONVERT(VARCHAR(10),ISNULL(P.PORCENTAJE_AVANCE,0)) AS AvanceTxt,
                CONVERT(VARCHAR(10),
                    CASE
                        WHEN ISNULL(P.PORCENTAJE_AVANCE,0) < 0 THEN 0
                        WHEN ISNULL(P.PORCENTAJE_AVANCE,0) > 100 THEN 100
                        ELSE ISNULL(P.PORCENTAJE_AVANCE,0)
                    END
                ) AS AvanceBarTxt,
                P.FECHA_INICIO AS SortFecha,
                P.ID AS SortID
            FROM #PROYECTOS360 P
        ) X
        ORDER BY
            CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,
            SortFecha DESC,
            SortID DESC
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_PROYECTOS = ''
        SET @HTML_PROYECTOS = '<div class="vct-360-empty vct-360-fixed-empty">Este cliente no tiene proyectos asociados.</div>';
    ELSE
        SET @HTML_PROYECTOS =
            '<div data-vct-dg data-vct-dg-id="v360_proy" data-vct-dg-title="Proyectos del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="proyecto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="12%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="inicio" data-vct-sortable="true" data-vct-sort-type="date"><span>Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="fin" data-vct-sortable="true" data-vct-sort-type="date"><span>Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="12%" data-vct-sort="avance" data-vct-sortable="true" data-vct-sort-type="number"><span>Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_PROYECTOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_PROYECTOS_TOP = ISNULL((
        SELECT
            '<tr>' +
                '<td data-label="Proyecto" class="vct-360-cell-project">' +
                    '<span class="vct-360-project-name">(' + EscCodigo + ') ' + EscNombre + '</span>' +
                    CASE WHEN EscReferencia <> ''
                         THEN '<span class="vct-360-project-ref">' + EscReferencia + '</span>'
                         ELSE '' END +
                '</td>' +
 
                '<td data-label="Estado" class="vct-360-cell-status">' +
                    '<span class="vct-badge" data-vct-badge="' + EstadoBadge + '">' + EscEstado + '</span>' +
                '</td>' +
 
                '<td data-label="Analista" class="vct-360-cell-person">' +
                    CASE
                        WHEN EscAnalista='-' THEN '-'
                        ELSE
                            '<span class="vct-360-person-inline">' +
                                '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" ' +
                                      'style="--vct-avatar-bg:'+AnalistaBg+';--vct-avatar-color:'+AnalistaTx+';">' +
                                    AnalistaIniciales +
                                '</span>' +
                                '<span class="vct-360-person-name">'+EscAnalista+'</span>' +
                            '</span>'
                    END +
                '</td>' +
 
                '<td data-label="Consultor" class="vct-360-cell-person">' +
                    CASE
                        WHEN ConsultorID IS NULL THEN '-'
                        ELSE
                            '<span class="vct-360-person-inline">' +
                                '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" ' +
                                      'style="--vct-avatar-bg:'+ConsultorBg+';--vct-avatar-color:'+ConsultorTx+';">' +
                                    ConsultorIniciales +
                                '</span>' +
                                '<span class="vct-360-person-name">'+EscConsultorNombre+'</span>' +
                            '</span>'
                    END +
                '</td>' +
 
                '<td data-label="Inicio" class="vct-360-cell-date">'+FInicioTxt+'</td>' +
                '<td data-label="Fin" class="vct-360-cell-date">'+FFinTxt+'</td>' +
 
                '<td data-label="Avance" class="vct-360-cell-progress vct-text-center">' +
                    '<div class="vct-360-progress"><div class="vct-360-progress-bar" style="background:#66062D !important;width:' + AvanceBarTxt + '%;"></div></div>' +
                    '<span class="vct-360-progress-label">' + AvanceTxt + '%</span>' +
                '</td>' +
            '</tr>'
        FROM
        (
            SELECT TOP 5
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscCodigo,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscReferencia,
 
                REPLACE(REPLACE(REPLACE(REPLACE(
                    CASE
                        WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'ACTIVO'
                        ELSE ISNULL(NULLIF(P.ESTADO,''),'Sin estado')
                    END,
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscEstado,
 
                CASE
                    WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'ACTIVO'
                    WHEN P.ESTADO_CODIGO='CONFIRMADO' THEN 'CONFIRMADO'
                    WHEN P.ESTADO_CODIGO='PAUSADO' THEN 'PAUSADO'
                    WHEN P.ESTADO_CODIGO='TERMINADO' THEN 'TERMINADO'
                    WHEN P.ESTADO_CODIGO='CANCELADO' THEN 'CANCELADO'
                    ELSE ISNULL(NULLIF(P.ESTADO_CODIGO,''),'SIN ESTADO')
                END AS EstadoBadge,
 
                REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(NULLIF(P.ANALISTA,''),'-'),
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscAnalista,
 
                CASE
                    WHEN NULLIF(LTRIM(RTRIM(ISNULL(P.ANALISTA,''))),'') IS NULL THEN ''
                    WHEN CHARINDEX(' ',LTRIM(RTRIM(ISNULL(P.ANALISTA,''))))>0
                        THEN UPPER(
                            LEFT(LTRIM(RTRIM(P.ANALISTA)),1)+
                            LEFT(REVERSE(LEFT(REVERSE(RTRIM(P.ANALISTA)),CHARINDEX(' ',REVERSE(RTRIM(P.ANALISTA))+' ')-1)),1)
                        )
                    ELSE UPPER(LEFT(LTRIM(RTRIM(ISNULL(P.ANALISTA,'A'))),2))
                END AS AnalistaIniciales,
 
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(P.ANALISTA,'')))) % 8
                    WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
                    WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8'
                END AS AnalistaBg,
 
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(P.ANALISTA,'')))) % 8
                    WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
                    WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94'
                END AS AnalistaTx,
 
                P.CONSULTOR_ID AS ConsultorID,
 
                REPLACE(REPLACE(REPLACE(REPLACE(
                    ISNULL(NULLIF(P.CONSULTOR_NOMBRE,''),'#'+CONVERT(VARCHAR(20),P.CONSULTOR_ID)),
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EscConsultorNombre,
 
                CASE
                    WHEN P.CONSULTOR_ID IS NULL THEN ''
                    WHEN LEFT(ISNULL(P.CONSULTOR_NOMBRE,''),1)='#' THEN 'C'
                    WHEN CHARINDEX(' ',LTRIM(RTRIM(ISNULL(P.CONSULTOR_NOMBRE,''))))>0
                        THEN UPPER(
                            LEFT(LTRIM(RTRIM(P.CONSULTOR_NOMBRE)),1)+
                            LEFT(REVERSE(LEFT(REVERSE(RTRIM(P.CONSULTOR_NOMBRE)),CHARINDEX(' ',REVERSE(RTRIM(P.CONSULTOR_NOMBRE))+' ')-1)),1)
                        )
                    ELSE UPPER(LEFT(LTRIM(RTRIM(ISNULL(P.CONSULTOR_NOMBRE,'C'))),2))
                END AS ConsultorIniciales,
 
                CASE ABS(CONVERT(BIGINT,ISNULL(P.CONSULTOR_ID,0))) % 8
                    WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
                    WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8'
                END AS ConsultorBg,
 
                CASE ABS(CONVERT(BIGINT,ISNULL(P.CONSULTOR_ID,0))) % 8
                    WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
                    WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94'
                END AS ConsultorTx,
 
                ISNULL(CONVERT(VARCHAR(10),P.FECHA_INICIO,103),'-') AS FInicioTxt,
                ISNULL(CONVERT(VARCHAR(10),P.FECHA_FIN,103),'-') AS FFinTxt,
                CONVERT(VARCHAR(10),ISNULL(P.PORCENTAJE_AVANCE,0)) AS AvanceTxt,
                CONVERT(VARCHAR(10),CASE WHEN ISNULL(P.PORCENTAJE_AVANCE,0)<0 THEN 0 WHEN ISNULL(P.PORCENTAJE_AVANCE,0)>100 THEN 100 ELSE ISNULL(P.PORCENTAJE_AVANCE,0) END) AS AvanceBarTxt,
                P.FECHA_INICIO AS SortFecha,
                P.ID AS SortID
            FROM #PROYECTOS360 P
            ORDER BY
                CASE WHEN P.FECHA_INICIO IS NULL THEN 1 ELSE 0 END,
                P.FECHA_INICIO DESC,
                P.ID DESC
        ) X
        ORDER BY
            CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,
            SortFecha DESC,
            SortID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'), '');
 
    IF @HTML_PROYECTOS_TOP=''
        SET @HTML_PROYECTOS_TOP=
            '<div class="vct-360-empty vct-360-fixed-empty">Este cliente no tiene proyectos asociados.</div>';
    ELSE
        SET @HTML_PROYECTOS_TOP=
            '<div class="vct-360-projects-recent vct-360-projects-recent-full">' +
                '<table class="vct-360-table vct-360-project-table vct-360-project-table-recent">' +
                    '<colgroup>' +
                        '<col style="width:31%">' +
                        '<col style="width:10%">' +
                        '<col style="width:12%">' +
                        '<col style="width:16%">' +
                        '<col style="width:9%">' +
                        '<col style="width:9%">' +
                        '<col style="width:13%">' +
                    '</colgroup>' +
                    '<thead><tr>' +
                        '<th>Proyecto</th>' +
                        '<th>Estado</th>' +
                        '<th>Analista</th>' +
                        '<th>Consultor</th>' +
                        '<th>Inicio</th>' +
                        '<th>Fin</th>' +
                        '<th>Avance</th>' +
                    '</tr></thead>' +
                    '<tbody>'+@HTML_PROYECTOS_TOP+'</tbody>' +
                '</table>' +
            '</div>';
 
    /* ============================================================
       8. HTML DOMICILIOS
       ============================================================ */
    DECLARE @HTML_DOMICILIOS VARCHAR(MAX) = '';
 
    SELECT @HTML_DOMICILIOS = ISNULL((
        SELECT --TOP 5
            '<tr data-vct-row ' +
            'data-vct-id="' + CONVERT(VARCHAR(100),D.ID) + '" ' +
            'data-vct-calle="' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(D.CALLE,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '" ' +
            'data-vct-nro="' + REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(50),D.NRO),''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-piso="' + REPLACE(REPLACE(ISNULL(D.PISO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-depto="' + REPLACE(REPLACE(ISNULL(D.DEPTO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-localidad="' + REPLACE(REPLACE(ISNULL(D.LOCALIDAD,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-provincia="' + REPLACE(REPLACE(ISNULL(D.PROVINCIA,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-principal="' + CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END + '" ' +
            'data-vct-observaciones="' + REPLACE(REPLACE(ISNULL(D.OBSERVACIONES,''),'"','&quot;'),'''','&#39;') + '">' +
            '<td data-label="Dirección">' +
                REPLACE(REPLACE(REPLACE(REPLACE(
                    LTRIM(RTRIM(
                        ISNULL(D.CALLE,'') +
                        CASE WHEN D.NRO IS NULL THEN '' ELSE ' ' + CONVERT(VARCHAR(20),D.NRO) END
                    )),
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
            '</td>' +
            '<td class="vct-text-center" data-label="Piso / Depto">' + REPLACE(REPLACE(REPLACE(REPLACE(
                LTRIM(RTRIM(
                    ISNULL(D.PISO,'') +
                    CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.DEPTO,''))), '') IS NULL THEN '' ELSE ' ' + D.DEPTO END
                )),
                '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Localidad">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(D.LOCALIDAD,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Provincia">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(D.PROVINCIA,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-text-center" data-label="Tipo">' + CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI'
                    THEN '<span class="vct-360-badge is-active">Principal</span>'
                    ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END + '</td>' +
            '<td data-label="Observaciones">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(D.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">' +
            CASE WHEN @CAN_EDIT=1 THEN
                '<button type="button" class="vct-row-menu-trigger" ' +
                'data-vct-command="row-context-menu" ' +
                'data-vct-target="vctDrawerDomicilio" ' +
                'data-vct-entity="DOMICILIO" ' +
                'data-vct-tab="domicilio" ' +
                'data-vct-form-title="Editar domicilio" ' +
                'data-vct-form-subtitle="Modifique los datos de la dirección." ' +
                'data-vct-form-icon="map-pin" ' +
                'aria-label="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
            ELSE '' END +
            '</td>' +
            '</tr>'
        FROM dbo.VCT_DOMICILIOS D WITH (NOLOCK)
        WHERE D.TIPO_ENTIDAD='CLIENTE'
      AND D.ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, D.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_DOMICILIOS = ''
        SET @HTML_DOMICILIOS = '<div class="vct-360-empty vct-360-fixed-empty">Sin domicilios registrados.</div>';
    ELSE
        SET @HTML_DOMICILIOS =
            '<div data-vct-dg data-vct-dg-id="v360_dom" data-vct-dg-title="Domicilios del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Dirección</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_DOMICILIOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       9. HTML TELEFONOS
       ============================================================ */
    DECLARE @HTML_TELEFONOS VARCHAR(MAX) = '';
 
    SELECT @HTML_TELEFONOS = ISNULL((
        SELECT --TOP 5
            '<tr data-vct-row ' +
            'data-vct-id="' + CONVERT(VARCHAR(100),T.ID) + '" ' +
            'data-vct-codarea="' + REPLACE(ISNULL(CONVERT(VARCHAR(50),T.CODAREA),''),'"','&quot;') + '" ' +
            'data-vct-nro="' + REPLACE(ISNULL(CONVERT(VARCHAR(50),T.NRO),''),'"','&quot;') + '" ' +
            'data-vct-principal="' + CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END + '" ' +
            'data-vct-observaciones="' + REPLACE(REPLACE(ISNULL(T.OBSERVACIONES,''),'"','&quot;'),'''','&#39;') + '">' +
            '<td class="vct-text-center" data-label="Código área">' + ISNULL(CONVERT(VARCHAR(10),T.CODAREA),'-') + '</td>' +
            '<td data-label="Número">' + ISNULL(CONVERT(VARCHAR(30),T.NRO),'-') + '</td>' +
            '<td class="vct-text-center" data-label="Tipo">' + CASE WHEN UPPER(ISNULL(T.PRINCIPAL,'')) = 'SI'
                    THEN '<span class="vct-360-badge is-active">Principal</span>'
                    ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END + '</td>' +
            '<td data-label="Observaciones">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(T.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">' +
            CASE WHEN @CAN_EDIT=1 THEN
                '<button type="button" class="vct-row-menu-trigger" ' +
                'data-vct-command="row-context-menu" ' +
                'data-vct-target="vctDrawerTelefono" ' +
                'data-vct-entity="TELEFONO" ' +
                'data-vct-tab="telefonos" ' +
                'data-vct-form-title="Editar teléfono" ' +
                'data-vct-form-subtitle="Modifique el teléfono seleccionado." ' +
                'data-vct-form-icon="phone" ' +
                'aria-label="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
            ELSE '' END +
            '</td>' +
            '</tr>'
        FROM dbo.VCT_TELEFONOS T WITH (NOLOCK)
        WHERE T.TIPO_ENTIDAD='CLIENTE'
      AND T.ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, T.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_TELEFONOS = ''
        SET @HTML_TELEFONOS = '<div class="vct-360-empty vct-360-fixed-empty">Sin teléfonos registrados.</div>';
    ELSE
        SET @HTML_TELEFONOS =
            '<div data-vct-dg data-vct-dg-id="v360_tel" data-vct-dg-title="Telefonos del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Código área</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Número</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_TELEFONOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       10. HTML EMAILS
       ============================================================ */
    DECLARE @HTML_EMAILS VARCHAR(MAX) = '';
 
    SELECT @HTML_EMAILS = ISNULL((
        SELECT --TOP 5
            '<tr data-vct-row ' +
            'data-vct-id="' + CONVERT(VARCHAR(100),E.ID) + '" ' +
            'data-vct-email="' + REPLACE(REPLACE(ISNULL(E.EMAIL,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-principal="' + CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END + '" ' +
            'data-vct-observaciones="' + REPLACE(REPLACE(ISNULL(E.OBSERVACIONES,''),'"','&quot;'),'''','&#39;') + '">' +
            '<td data-label="Email">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(E.EMAIL,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-text-center" data-label="Tipo">' + CASE WHEN UPPER(ISNULL(E.PRINCIPAL,'')) = 'SI'
                    THEN '<span class="vct-360-badge is-active">Principal</span>'
                    ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END + '</td>' +
            '<td data-label="Observaciones">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(E.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">' +
            CASE WHEN @CAN_EDIT=1 THEN
                '<button type="button" class="vct-row-menu-trigger" ' +
                'data-vct-command="row-context-menu" ' +
                'data-vct-target="vctDrawerEmail" ' +
                'data-vct-entity="EMAIL" ' +
                'data-vct-tab="email" ' +
                'data-vct-form-title="Editar email" ' +
                'data-vct-form-subtitle="Modifique el email seleccionado." ' +
                'data-vct-form-icon="mail" ' +
                'aria-label="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
            ELSE '' END +
            '</td>' +
            '</tr>'
        FROM dbo.VCT_EMAILS E WITH (NOLOCK)
        WHERE E.TIPO_ENTIDAD='CLIENTE'
      AND E.ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN UPPER(ISNULL(E.PRINCIPAL,'')) = 'SI' THEN 0 ELSE 1 END, E.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_EMAILS = ''
        SET @HTML_EMAILS = '<div class="vct-360-empty vct-360-fixed-empty">Sin emails registrados.</div>';
    ELSE
        SET @HTML_EMAILS =
            '<div data-vct-dg data-vct-dg-id="v360_mail" data-vct-dg-title="Emails del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_EMAILS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       11. HTML CONTACTOS
       ============================================================ */
    DECLARE @HTML_CONTACTOS_TABLE   VARCHAR(MAX) = '';
    DECLARE @HTML_CONTACTOS_COMPACT VARCHAR(MAX) = '';
 
    SELECT @HTML_CONTACTOS_TABLE = ISNULL((
        SELECT
            '<tr data-vct-row ' +
            'data-vct-id="' + CONVERT(VARCHAR(100),C.ID) + '" ' +
            'data-vct-nombres="' + REPLACE(REPLACE(ISNULL(C.NOMBRES,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-apellido="' + REPLACE(REPLACE(ISNULL(C.APELLIDO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-cargo="' + REPLACE(REPLACE(ISNULL(C.CARGO,''),'"','&quot;'),'''','&#39;') + '" ' +
            'data-vct-telefono="' + ISNULL(CONVERT(VARCHAR(30),C.ID_TELEFONO),'') + '" ' +
            'data-vct-email="' + ISNULL(CONVERT(VARCHAR(30),C.ID_EMAIL),'') + '" ' +
            'data-vct-observaciones="' + REPLACE(REPLACE(ISNULL(C.OBSERVACIONES,''),'"','&quot;'),'''','&#39;') + '">' +
            '<td class="vct-360-contact-avatar-cell" data-label="">' +
                '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" style="width:24px;height:24px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:8px;font-weight:800;background:' +
                    CASE ABS(CONVERT(BIGINT,ISNULL(C.ID,0))) % 8
                        WHEN 0 THEN '#F3DFE5'
                        WHEN 1 THEN '#E3E4FA'
                        WHEN 2 THEN '#DCEBF0'
                        WHEN 3 THEN '#F3E1D9'
                        WHEN 4 THEN '#E4F2EA'
                        WHEN 5 THEN '#F8E7D4'
                        WHEN 6 THEN '#E7E1F5'
                        ELSE '#E4EEF8'
                    END +
                    ';color:' +
                    CASE ABS(CONVERT(BIGINT,ISNULL(C.ID,0))) % 8
                        WHEN 0 THEN '#8B2E4A'
                        WHEN 1 THEN '#5257A2'
                        WHEN 2 THEN '#356D84'
                        WHEN 3 THEN '#A05A3C'
                        WHEN 4 THEN '#3C7A57'
                        WHEN 5 THEN '#A66324'
                        WHEN 6 THEN '#6E55A5'
                        ELSE '#3D6B94'
                    END +
                    ';">' +
                    UPPER(
                        ISNULL(LEFT(NULLIF(LTRIM(RTRIM(C.NOMBRES)),''),1),'') +
                        ISNULL(LEFT(NULLIF(LTRIM(RTRIM(C.APELLIDO)),''),1),'')
                    ) +
                '</span>' +
            '</td>' +
            '<td data-label="Apellido">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.APELLIDO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Nombres">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.NOMBRES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Cargo">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.CARGO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Teléfono">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.TELEFONO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Email">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.EMAIL,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td data-label="Observaciones">' + REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') + '</td>' +
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">' +
            CASE WHEN @CAN_EDIT=1 THEN
                '<button type="button" class="vct-row-menu-trigger" ' +
                'data-vct-command="row-context-menu" ' +
                'data-vct-target="vctDrawerContacto" ' +
                'data-vct-entity="CONTACTO" ' +
                'data-vct-tab="contacto" ' +
                'data-vct-actions="edit,delete" ' +
                'data-vct-form-title="Editar contacto" ' +
                'data-vct-form-subtitle="Modifique los datos del contacto." ' +
                'data-vct-form-icon="contact" ' +
                'aria-label="Acciones"><span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
            ELSE '' END +
            '</td>' +
            '</tr>'
        FROM #CONTACTOS360 C
        ORDER BY C.APELLIDO,C.NOMBRES,C.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_CONTACTOS_TABLE = ''
        SET @HTML_CONTACTOS_TABLE = '<div class="vct-360-empty vct-360-fixed-empty">Sin contactos registrados.</div>';
    ELSE
        SET @HTML_CONTACTOS_TABLE =
            '<div data-vct-dg data-vct-dg-id="v360_cont" data-vct-dg-title="Contactos del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="contacto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar contacto, cargo, email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-width="46" data-vct-export-ignore="true" aria-label="Avatar"></th><th data-vct-width="14%" data-vct-sort="apellido" data-vct-sortable="true"><span>Apellido</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="nombres" data-vct-sortable="true"><span>Nombres</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="cargo" data-vct-sortable="true"><span>Cargo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="telefono" data-vct-sortable="true"><span>Teléfono</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="17%" data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_CONTACTOS_TABLE+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_CONTACTOS_COMPACT = ISNULL((
        SELECT TOP 5
            '<div class="vct-360-contact-row">' +
                '<span class="vct-360-contact-avatar" style="width:28px;height:28px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:8px;font-weight:800;background:' +
                    CASE ABS(CONVERT(BIGINT,ISNULL(C.ID,0))) % 8
                        WHEN 0 THEN '#F3DFE5'
                        WHEN 1 THEN '#E3E4FA'
                        WHEN 2 THEN '#DCEBF0'
                        WHEN 3 THEN '#F3E1D9'
                        WHEN 4 THEN '#E4F2EA'
                        WHEN 5 THEN '#F8E7D4'
                        WHEN 6 THEN '#E7E1F5'
                        ELSE '#E4EEF8'
                    END +
                    ';color:' +
                    CASE ABS(CONVERT(BIGINT,ISNULL(C.ID,0))) % 8
                        WHEN 0 THEN '#8B2E4A'
                        WHEN 1 THEN '#5257A2'
                        WHEN 2 THEN '#356D84'
                        WHEN 3 THEN '#A05A3C'
                        WHEN 4 THEN '#3C7A57'
                        WHEN 5 THEN '#A66324'
                        WHEN 6 THEN '#6E55A5'
                        ELSE '#3D6B94'
                    END +
                    ';">' +
                    UPPER(
                        ISNULL(LEFT(NULLIF(LTRIM(RTRIM(C.NOMBRES)),''),1),'') +
                        ISNULL(LEFT(NULLIF(LTRIM(RTRIM(C.APELLIDO)),''),1),'')
                    ) +
                '</span>' +
                '<span class="vct-360-contact-info">' +
                    '<span class="vct-360-contact-name">' +
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(C.NOMBRE,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
                    '</span>' +
                '</span>' +
            '</div>'
        FROM #CONTACTOS360 C
        ORDER BY C.APELLIDO,C.NOMBRES,C.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_CONTACTOS_COMPACT = ''
        SET @HTML_CONTACTOS_COMPACT = '<div class="vct-360-empty vct-360-fixed-empty">Sin contactos registrados.</div>';
 
    /* ============================================================
       12. GESTIONES - TODAS Y TOP 5 - MODELO NUEVO
       ============================================================ */
    DECLARE @HTML_GESTIONES      VARCHAR(MAX) = '';
    DECLARE @HTML_GESTIONES_TOP  VARCHAR(MAX) = '';
    DECLARE @UltimaGestionFecha  DATETIME = NULL;
    DECLARE @UltimaGestionFechaTxt VARCHAR(20) = '-';
 
    BEGIN TRY
 
        SELECT TOP 1
            @UltimaGestionFecha=
                ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION))
        FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
        LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
            ON P.ID=G.ID_PROYECTO
        WHERE ISNULL(G.ID_CLIENTE,P.IDCLIENTE)=@ID_CLIENTE
        ORDER BY
            ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) DESC,
            G.ID DESC;
 
        IF @UltimaGestionFecha IS NOT NULL
            SET @UltimaGestionFechaTxt=CONVERT(VARCHAR(10),@UltimaGestionFecha,103);
 
        SELECT @HTML_GESTIONES=ISNULL((
            SELECT
                '<tr data-vct-row>' +
                    '<td class="vct-text-center" data-label="Fecha">' + FechaTxt + '</td>' +
                    '<td data-label="Proyecto"><span class="vct-360-project-name">(' + ProyectoCodigo + ') ' + ProyectoNombre + '</span>' +
                        CASE WHEN ProyectoReferencia<>'' THEN '<span class="vct-360-project-ref">' + ProyectoReferencia + '</span>' ELSE '' END +
                    '</td>' +
                    '<td data-label="Gestión"><span class="vct-360-project-name">' + GestionTitulo + '</span>' +
                        CASE WHEN ResultadoTxt<>'' THEN '<span class="vct-360-project-ref">' + ResultadoTxt + '</span>' ELSE '' END +
                    '</td>' +
                    '<td data-label="Tipo / Subtipo"><span class="vct-360-project-name">' + TipoTxt + '</span>' +
                        CASE WHEN SubtipoTxt<>'' THEN '<span class="vct-360-project-ref">' + SubtipoTxt + '</span>' ELSE '' END +
                    '</td>' +
                    '<td data-label="Responsable">' + ResponsableTxt + '</td>' +
                    '<td class="vct-text-center" data-label="Vencimiento">' + VencimientoTxt + '</td>' +
                    '<td class="vct-text-center" data-label="Estado"><span class="vct-360-badge ' + EstadoClase + '">' + EstadoVisual + '</span></td>' +
                '</tr>'
            FROM
            (
                SELECT
                    G.ID AS SortID,
                    ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) AS SortFecha,
                    ISNULL(CONVERT(VARCHAR(10),
                        ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)),103),'-') AS FechaTxt,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(CONVERT(VARCHAR(100),P.CODIGO),'-'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoCodigo,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(P.NOMBRE,'-'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoNombre,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(P.REFERENCIA,''),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoReferencia,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(NULLIF(G.TITULO,''),'Gestión'),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS GestionTitulo,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(T.DESCRIPCION,ISNULL(T.CODIGO,'-')),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS TipoTxt,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(ST.DESCRIPCION,ISNULL(ST.CODIGO,'')),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS SubtipoTxt,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(R.DESCRIPCION,ISNULL(R.CODIGO,'')),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ResultadoTxt,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL
                        (
                            (
                                SELECT TOP 1 GR.NOMBRE
                                FROM dbo.VCT_VW_GESTIONES_RESPONSABLES GR WITH(NOLOCK)
                                WHERE GR.ID_GESTION=G.ID
                            ),
                            '-'
                        ),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ResponsableTxt,
 
                    ISNULL(CONVERT(VARCHAR(10),G.FECHA_VENCIMIENTO,103),'-') AS VencimientoTxt,
 
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN GE.ES_FINAL=1
                                THEN UPPER(ISNULL(GE.DESCRIPCION,GE.CODIGO))
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL
                             AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0
                                THEN 'VENCIDA'
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL
                             AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)=0
                                THEN 'HOY'
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL
                             AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)>0
                                THEN 'PRÓXIMA'
                            ELSE UPPER(ISNULL(GE.DESCRIPCION,ISNULL(GE.CODIGO,'SIN ESTADO')))
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EstadoVisual,
 
                    CASE
                        WHEN GE.CODIGO='CUMPLIDA' THEN 'is-done'
                        WHEN GE.CODIGO='CANCELADA' THEN 'is-cancel'
                        WHEN GE.ES_FINAL=0
                         AND G.FECHA_VENCIMIENTO IS NOT NULL
                         AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0
                            THEN 'is-cancel'
                        WHEN GE.CODIGO IN ('EN_PROCESO','EN_ESPERA') THEN 'is-progress'
                        WHEN GE.CODIGO='PENDIENTE' THEN 'is-planned'
                        ELSE 'is-neutral'
                    END AS EstadoClase
 
                FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
                LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
                    ON P.ID=G.ID_PROYECTO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK)
                    ON T.ID=G.ID_TIPO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST WITH(NOLOCK)
                    ON ST.ID=G.ID_SUBTIPO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_RESULTADOS R WITH(NOLOCK)
                    ON R.ID=G.ID_RESULTADO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE WITH(NOLOCK)
                    ON GE.ID=G.ID_ESTADO
                WHERE ISNULL(G.ID_CLIENTE,P.IDCLIENTE)=@ID_CLIENTE
            ) X
            ORDER BY
                CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,
                SortFecha DESC,
                SortID DESC
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
 
        SELECT @HTML_GESTIONES_TOP=ISNULL((
            SELECT
                '<tr style="border-bottom:1px solid #edf1f5;">' +
                    '<td data-label="" class="vct-360-cell-management-icon" aria-hidden="true" style="border-bottom:1px solid #edf1f5 !important;">' +
                        '<span class="vct-360-management-type-icon"><span data-vct-icon="'+GestionIcono+'"></span></span>' +
                    '</td>' +
                    '<td data-label="Gestión" class="vct-360-cell-management" style="border-bottom:1px solid #edf1f5 !important;">' +
                        '<span class="vct-360-project-name">'+GestionTitulo+'</span>' +
                        CASE WHEN SubtipoTxt<>'' THEN '<span class="vct-360-project-ref">'+SubtipoTxt+'</span>' ELSE '' END +
                    '</td>' +
                    '<td data-label="Proyecto" class="vct-360-cell-management-project vct-360-cell-project" style="border-bottom:1px solid #edf1f5 !important;">' +
                        '<span class="vct-360-project-name">(' + ProyectoCodigo + ') ' + ProyectoNombre + '</span>' +
                        CASE WHEN ProyectoReferencia<>'' THEN '<span class="vct-360-project-ref">'+ProyectoReferencia+'</span>' ELSE '' END +
                    '</td>' +
                    '<td data-label="Asignado" class="vct-360-cell-person" style="border-bottom:1px solid #edf1f5 !important;">' +
                        CASE
                            WHEN ResponsableTipo='' THEN '-'
                            ELSE
                                '<span class="vct-360-person-inline">' +
                                    '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" style="--vct-avatar-bg:'+ResponsableBg+';--vct-avatar-color:'+ResponsableTx+';">'+ResponsableIniciales+'</span>' +
                                    '<span class="vct-360-person-name">'+ResponsableNombre+'</span>' +
                                '</span>'
                        END +
                    '</td>' +
                    '<td data-label="Estado" class="vct-360-cell-status" style="border-bottom:1px solid #edf1f5 !important;"><span class="vct-badge" data-vct-badge="'+EstadoBadge+'">'+EstadoVisual+'</span></td>' +
                    '<td data-label="Fecha" class="vct-360-cell-date" style="border-bottom:1px solid #edf1f5 !important;">'+FechaTxt+'</td>' +
                '</tr>'
            FROM
            (
                SELECT TOP 5
                    G.ID AS SortID,
                    ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) AS SortFecha,
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.TITULO,''),'Gestión'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS GestionTitulo,
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ST.DESCRIPCION,ISNULL(ST.CODIGO,'')),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS SubtipoTxt,
                    REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN P.CODIGO IS NULL THEN '-' ELSE CONVERT(VARCHAR(100),P.CODIGO) END,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoCodigo,
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(P.NOMBRE,''),'Sin proyecto'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoNombre,
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoReferencia,
                    CASE
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%VISITA%' THEN 'calendar'
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%DOCUMENT%' THEN 'file-text'
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%LLAM%' THEN 'phone'
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%MAIL%' OR UPPER(ISNULL(ST.CODIGO,'')) LIKE '%EMAIL%' THEN 'mail'
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%REUN%' THEN 'users'
                        WHEN UPPER(ISNULL(ST.CODIGO,'')) LIKE '%PROYECTO%' THEN 'folder'
                        WHEN UPPER(ISNULL(T.CODIGO,''))='TAREA' THEN 'list-checks'
                        ELSE 'clipboard-check'
                    END AS GestionIcono,
                    ISNULL(GR.TIPO_ENTIDAD,'') AS ResponsableTipo,
                    GR.ID_ENTIDAD AS ResponsableID,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN GR.TIPO_ENTIDAD IS NULL THEN ''
                            WHEN GR.TIPO_ENTIDAD='SISTEMA' THEN 'Sistema'
                            WHEN GR.ID_ENTIDAD IS NOT NULL AND (UPPER(ISNULL(GR.NOMBRE,'')) LIKE 'CONSULTOR #%' OR UPPER(ISNULL(GR.NOMBRE,'')) LIKE 'EMPLEADO #%')
                                THEN '#'+CONVERT(VARCHAR(20),GR.ID_ENTIDAD)
                            ELSE ISNULL(NULLIF(LTRIM(RTRIM(GR.NOMBRE)),''),'#'+CONVERT(VARCHAR(20),GR.ID_ENTIDAD))
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ResponsableNombre,
                    CASE
                        WHEN GR.TIPO_ENTIDAD IS NULL THEN ''
                        WHEN GR.TIPO_ENTIDAD='SISTEMA' THEN 'SI'
                        WHEN GR.ID_ENTIDAD IS NOT NULL AND (UPPER(ISNULL(GR.NOMBRE,'')) LIKE 'CONSULTOR #%' OR UPPER(ISNULL(GR.NOMBRE,'')) LIKE 'EMPLEADO #%') THEN LEFT(GR.TIPO_ENTIDAD,1)
                        WHEN CHARINDEX(' ',LTRIM(RTRIM(ISNULL(GR.NOMBRE,''))))>0
                            THEN UPPER(LEFT(LTRIM(RTRIM(GR.NOMBRE)),1)+LEFT(REVERSE(LEFT(REVERSE(RTRIM(GR.NOMBRE)),CHARINDEX(' ',REVERSE(RTRIM(GR.NOMBRE))+' ')-1)),1))
                        ELSE UPPER(LEFT(LTRIM(RTRIM(ISNULL(GR.NOMBRE,GR.TIPO_ENTIDAD))),2))
                    END AS ResponsableIniciales,
                    CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(GR.TIPO_ENTIDAD,'')+'|'+CONVERT(VARCHAR(20),ISNULL(GR.ID_ENTIDAD,G.ID))))) % 8
                        WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
                        WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8'
                    END AS ResponsableBg,
                    CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(GR.TIPO_ENTIDAD,'')+'|'+CONVERT(VARCHAR(20),ISNULL(GR.ID_ENTIDAD,G.ID))))) % 8
                        WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
                        WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94'
                    END AS ResponsableTx,
                    ISNULL(CONVERT(VARCHAR(10),ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)),103),'-') AS FechaTxt,
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN GE.ES_FINAL=1 THEN UPPER(ISNULL(GE.DESCRIPCION,GE.CODIGO))
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0 THEN 'VENCIDA'
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)=0 THEN 'HOY'
                            WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)>0 THEN 'PRÓXIMA'
                            ELSE UPPER(ISNULL(GE.DESCRIPCION,ISNULL(GE.CODIGO,'SIN ESTADO')))
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EstadoVisual,
                    CASE
                        WHEN GE.ES_FINAL=1 THEN ISNULL(GE.CODIGO,'SIN ESTADO')
                        WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0 THEN 'VENCIDA'
                        WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)=0 THEN 'HOY'
                        WHEN G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)>0 THEN 'PRÓXIMA'
                        ELSE ISNULL(GE.CODIGO,'SIN ESTADO')
                    END AS EstadoBadge
                FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
                INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
                    ON P.ID=G.ID_PROYECTO
                LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS PE WITH(NOLOCK)
                    ON PE.ID=P.ID_ESTADO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST WITH(NOLOCK)
                    ON ST.ID=G.ID_SUBTIPO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK)
                    ON T.ID=G.ID_TIPO
                LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE WITH(NOLOCK)
                    ON GE.ID=G.ID_ESTADO
                LEFT JOIN dbo.VCT_VW_GESTIONES_RESPONSABLES GR WITH(NOLOCK)
                    ON GR.ID_GESTION=G.ID
                WHERE ISNULL(G.ID_CLIENTE,P.IDCLIENTE)=@ID_CLIENTE
                  AND PE.CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO')
                ORDER BY
                    CASE WHEN ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) IS NULL THEN 1 ELSE 0 END,
                    ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)) DESC,
                    G.ID DESC
            ) X
            ORDER BY CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,SortFecha DESC,SortID DESC
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'' );
 
    END TRY
    BEGIN CATCH
        SET @HTML_GESTIONES='';
        SET @HTML_GESTIONES_TOP='';
        SET @UltimaGestionFecha=NULL;
        SET @UltimaGestionFechaTxt='-';
    END CATCH;
 
    IF @HTML_GESTIONES=''
        SET @HTML_GESTIONES=
            '<div class="vct-360-empty vct-360-fixed-empty">Sin gestiones registradas para este cliente.</div>';
    ELSE
        SET @HTML_GESTIONES=
            '<div data-vct-dg data-vct-dg-id="v360_gest" data-vct-dg-title="Gestiones del cliente" data-vct-dg-subtitle="Cliente: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion, proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th class="vct-text-center" data-vct-width="8%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="28%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="22%" data-vct-sort="gestion" data-vct-sortable="true"><span>Gestión</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo / Subtipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="10%" data-vct-sort="responsable" data-vct-sortable="true"><span>Responsable</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="vencimiento" data-vct-sortable="true" data-vct-sort-type="date"><span>Vencimiento</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="9%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>'+
            '<tbody>'+@HTML_GESTIONES+'</tbody>'+
            '</table>'+
            '</div>';
 
    IF @HTML_GESTIONES_TOP=''
        SET @HTML_GESTIONES_TOP=
            '<div class="vct-360-empty vct-360-fixed-empty">Sin gestiones recientes en proyectos activos.</div>';
    ELSE
        SET @HTML_GESTIONES_TOP=
            '<div class="vct-360-gestiones-recent vct-360-gestiones-recent-full">' +
                '<table class="vct-360-table vct-360-management-table-recent">' +
                    '<colgroup>' +
                        '<col style="width:4%">' +
                        '<col style="width:22%">' +
                        '<col style="width:27%">' +
                        '<col style="width:23%">' +
                        '<col style="width:14%">' +
                        '<col style="width:10%">' +
                    '</colgroup>' +
                    '<thead><tr>' +
                        '<th aria-label="Tipo"></th>' +
                        '<th>Gestión</th>' +
                        '<th>Proyecto</th>' +
                        '<th>Asignado</th>' +
                        '<th>Estado</th>' +
                        '<th>Fecha</th>' +
                    '</tr></thead>' +
                    '<tbody>'+@HTML_GESTIONES_TOP+'</tbody>' +
                '</table>' +
            '</div>';
 
    /* ============================================================
       13. GRAFICOS / RESUMENES
       ============================================================ */
    DECLARE
        @CantEnCurso      INT = 0,
        @CantConfirmado   INT = 0,
        @CantTerminado    INT = 0,
        @CantOtros        INT = 0;
 
    SELECT
        @CantEnCurso = SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN 1 ELSE 0 END),
        @CantConfirmado = SUM(CASE WHEN ESTADO_CODIGO='CONFIRMADO' THEN 1 ELSE 0 END),
        @CantTerminado = SUM(CASE WHEN ESTADO_CODIGO='TERMINADO' THEN 1 ELSE 0 END),
        @CantOtros = SUM(CASE WHEN ISNULL(ESTADO_CODIGO,'') NOT IN ('ENCURSO','CONFIRMADO','TERMINADO') THEN 1 ELSE 0 END)
    FROM #PROYECTOS360;
 
    SET @CantEnCurso = ISNULL(@CantEnCurso,0);
    SET @CantConfirmado = ISNULL(@CantConfirmado,0);
    SET @CantTerminado = ISNULL(@CantTerminado,0);
    SET @CantOtros = ISNULL(@CantOtros,0);
 
    DECLARE @PctEnCurso INT = CASE WHEN @ProyectosCount > 0 THEN (@CantEnCurso * 100) / @ProyectosCount ELSE 0 END;
    DECLARE @PctConfirmado INT = CASE WHEN @ProyectosCount > 0 THEN (@CantConfirmado * 100) / @ProyectosCount ELSE 0 END;
    DECLARE @PctTerminado INT = CASE WHEN @ProyectosCount > 0 THEN (@CantTerminado * 100) / @ProyectosCount ELSE 0 END;
    DECLARE @PctProyectosActivos INT = CASE WHEN @ProyectosCount > 0 THEN (@ProyectosActivos * 100) / @ProyectosCount ELSE 0 END;
 
    DECLARE @MontoActivoTxt VARCHAR(40) = CONVERT(VARCHAR(40),CAST(ROUND(@MontoActivo,0) AS MONEY),1);
    DECLARE @CostoActivoTxt VARCHAR(40) = CONVERT(VARCHAR(40),CAST(ROUND(@CostoActivo,0) AS MONEY),1);
    DECLARE @MargenActivo NUMERIC(18,2) = ISNULL(@MontoActivo,0)-ISNULL(@CostoActivo,0);
    DECLARE @MargenActivoTxt VARCHAR(40) = CONVERT(VARCHAR(40),CAST(ROUND(@MargenActivo,0) AS MONEY),1);
 
    IF RIGHT(@MontoActivoTxt,3)='.00' SET @MontoActivoTxt=LEFT(@MontoActivoTxt,LEN(@MontoActivoTxt)-3);
    IF RIGHT(@CostoActivoTxt,3)='.00' SET @CostoActivoTxt=LEFT(@CostoActivoTxt,LEN(@CostoActivoTxt)-3);
    IF RIGHT(@MargenActivoTxt,3)='.00' SET @MargenActivoTxt=LEFT(@MargenActivoTxt,LEN(@MargenActivoTxt)-3);
 
    DECLARE @AvanceActivoEntero INT=CONVERT(INT,ROUND(ISNULL(@AvanceActivo,0),0));
    IF @AvanceActivoEntero<0 SET @AvanceActivoEntero=0;
    IF @AvanceActivoEntero>100 SET @AvanceActivoEntero=100;
 
    DECLARE @MargenPct INT=
        CASE WHEN @MontoActivo>0 THEN CONVERT(INT,ROUND((@MargenActivo*100.0)/@MontoActivo,0)) ELSE 0 END;
 
    DECLARE @CostoPctBar INT=
        CASE
            WHEN @MontoActivo<=0 THEN 0
            WHEN @CostoActivo<=0 THEN 0
            WHEN @CostoActivo>=@MontoActivo THEN 100
            ELSE CONVERT(INT,ROUND((@CostoActivo*100.0)/@MontoActivo,0))
        END;
 
    DECLARE @MargenPctBar INT=
        CASE
            WHEN @MontoActivo<=0 OR @MargenActivo<=0 THEN 0
            WHEN @MargenActivo>=@MontoActivo THEN 100
            ELSE 100-@CostoPctBar
        END;
 
    DECLARE @HTML_ESTADOS VARCHAR(MAX) =
        '<div class="vct-360-chart-simple vct-360-chart-state">' +
            '<div class="vct-360-donut-ring vct-360-donut-lg" style="background:conic-gradient(' +
                '#10b981 0% ' + CONVERT(VARCHAR(5),@PctEnCurso) + '%,' +
                '#f59e0b ' + CONVERT(VARCHAR(5),@PctEnCurso) + '% ' + CONVERT(VARCHAR(5),@PctEnCurso + @PctConfirmado) + '%,' +
                '#94a3b8 ' + CONVERT(VARCHAR(5),@PctEnCurso + @PctConfirmado) + '% ' + CONVERT(VARCHAR(5),@PctEnCurso + @PctConfirmado + @PctTerminado) + '%,' +
                '#e2e8f0 ' + CONVERT(VARCHAR(5),@PctEnCurso + @PctConfirmado + @PctTerminado) + '% 100%);">' +
                '<span class="vct-360-donut-center vct-360-donut-center-lg"><b>' + CONVERT(VARCHAR(10),@ProyectosCount) + '</b><span>Proyectos</span></span>' +
            '</div>' +
            '<div class="vct-360-donut-legend vct-360-donut-legend-lg">' +
                '<div class="vct-360-donut-legend-item"><span class="vct-360-dot" style="background:#10b981;"></span><span>En curso</span><b>' + CONVERT(VARCHAR(10),@CantEnCurso) + ' (' + CONVERT(VARCHAR(5),@PctEnCurso) + '%)</b></div>' +
                '<div class="vct-360-donut-legend-item"><span class="vct-360-dot" style="background:#f59e0b;"></span><span>Confirmados</span><b>' + CONVERT(VARCHAR(10),@CantConfirmado) + ' (' + CONVERT(VARCHAR(5),@PctConfirmado) + '%)</b></div>' +
                '<div class="vct-360-donut-legend-item"><span class="vct-360-dot" style="background:#94a3b8;"></span><span>Terminados</span><b>' + CONVERT(VARCHAR(10),@CantTerminado) + ' (' + CONVERT(VARCHAR(5),@PctTerminado) + '%)</b></div>' +
            '</div>' +
        '</div>';
 
    /* Gestiones de proyectos activos: barra apilada a 100% del ancho. */
    DECLARE
        @GA_Total       INT=0,
        @GA_Cumplidas   INT=0,
        @GA_EnCurso     INT=0,
        @GA_Pendientes  INT=0,
        @GA_Vencidas    INT=0,
        @GA_Canceladas  INT=0,
        @GA_Otras       INT=0;
 
    SELECT
        @GA_Total=COUNT(*),
        @GA_Cumplidas=SUM(CASE WHEN GE.CODIGO='CUMPLIDA' THEN 1 ELSE 0 END),
        @GA_Canceladas=SUM(CASE WHEN GE.CODIGO='CANCELADA' THEN 1 ELSE 0 END),
        @GA_Vencidas=SUM(CASE WHEN ISNULL(GE.ES_FINAL,0)=0 AND G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0 THEN 1 ELSE 0 END),
        @GA_EnCurso=SUM(CASE WHEN ISNULL(GE.ES_FINAL,0)=0
                                  AND NOT (G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0)
                                  AND GE.CODIGO IN ('EN_PROCESO','EN_ESPERA') THEN 1 ELSE 0 END),
        @GA_Pendientes=SUM(CASE WHEN ISNULL(GE.ES_FINAL,0)=0
                                     AND NOT (G.FECHA_VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.FECHA_VENCIMIENTO)<0)
                                     AND ISNULL(GE.CODIGO,'') NOT IN ('EN_PROCESO','EN_ESPERA') THEN 1 ELSE 0 END)
    FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
    INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
        ON P.ID=G.ID_PROYECTO
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS PE WITH(NOLOCK)
        ON PE.ID=P.ID_ESTADO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE WITH(NOLOCK)
        ON GE.ID=G.ID_ESTADO
    WHERE P.IDCLIENTE=@ID_CLIENTE
      AND PE.CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO');
 
    SET @GA_Total=ISNULL(@GA_Total,0);
    SET @GA_Cumplidas=ISNULL(@GA_Cumplidas,0);
    SET @GA_EnCurso=ISNULL(@GA_EnCurso,0);
    SET @GA_Pendientes=ISNULL(@GA_Pendientes,0);
    SET @GA_Vencidas=ISNULL(@GA_Vencidas,0);
    SET @GA_Canceladas=ISNULL(@GA_Canceladas,0);
    SET @GA_Otras=@GA_Total-(@GA_Cumplidas+@GA_EnCurso+@GA_Pendientes+@GA_Vencidas+@GA_Canceladas);
    IF @GA_Otras<0 SET @GA_Otras=0;
 
    DECLARE @GA_PctCumplidas INT=CASE WHEN @GA_Total>0 THEN (@GA_Cumplidas*100)/@GA_Total ELSE 0 END;
    DECLARE @GA_PctEnCurso INT=CASE WHEN @GA_Total>0 THEN (@GA_EnCurso*100)/@GA_Total ELSE 0 END;
    DECLARE @GA_PctPendientes INT=CASE WHEN @GA_Total>0 THEN (@GA_Pendientes*100)/@GA_Total ELSE 0 END;
    DECLARE @GA_PctVencidas INT=CASE WHEN @GA_Total>0 THEN (@GA_Vencidas*100)/@GA_Total ELSE 0 END;
    DECLARE @GA_PctCanceladas INT=CASE WHEN @GA_Total>0 THEN (@GA_Canceladas*100)/@GA_Total ELSE 0 END;
    DECLARE @GA_PctOtras INT=CASE WHEN @GA_Total>0 THEN (@GA_Otras*100)/@GA_Total ELSE 0 END;
 
    DECLARE @HTML_GESTIONES_ACTIVOS VARCHAR(MAX)='';
 
    IF @GA_Total=0
    BEGIN
        SET @HTML_GESTIONES_ACTIVOS=
            '<div class="vct-360-empty vct-360-fixed-empty">No hay gestiones asociadas a proyectos activos.</div>';
    END
    ELSE
    BEGIN
        SET @HTML_GESTIONES_ACTIVOS=
            '<div class="vct-360-active-management-chart">' +
                '<div class="vct-360-active-management-main">' +
                    '<div class="vct-360-active-management-bar">' +
                        CASE WHEN @GA_Cumplidas>0 THEN '<span class="is-complete" style="flex:'+CONVERT(VARCHAR(12),@GA_Cumplidas)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_Cumplidas)+'</span>' ELSE '' END +
                        CASE WHEN @GA_EnCurso>0 THEN '<span class="is-progress" style="flex:'+CONVERT(VARCHAR(12),@GA_EnCurso)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_EnCurso)+'</span>' ELSE '' END +
                        CASE WHEN @GA_Pendientes>0 THEN '<span class="is-pending" style="flex:'+CONVERT(VARCHAR(12),@GA_Pendientes)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_Pendientes)+'</span>' ELSE '' END +
                        CASE WHEN @GA_Vencidas>0 THEN '<span class="is-overdue" style="flex:'+CONVERT(VARCHAR(12),@GA_Vencidas)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_Vencidas)+'</span>' ELSE '' END +
                        CASE WHEN @GA_Canceladas>0 THEN '<span class="is-cancelled" style="flex:'+CONVERT(VARCHAR(12),@GA_Canceladas)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_Canceladas)+'</span>' ELSE '' END +
                        CASE WHEN @GA_Otras>0 THEN '<span class="is-other" style="flex:'+CONVERT(VARCHAR(12),@GA_Otras)+' 1 0;">'+CONVERT(VARCHAR(10),@GA_Otras)+'</span>' ELSE '' END +
                    '</div>' +
                    '<div class="vct-360-active-management-legend">' +
                        '<span><i class="is-complete"></i><b>Cumplidas</b><small>'+CONVERT(VARCHAR(10),@GA_Cumplidas)+' ('+CONVERT(VARCHAR(5),@GA_PctCumplidas)+'%)</small></span>' +
                        '<span><i class="is-progress"></i><b>En curso</b><small>'+CONVERT(VARCHAR(10),@GA_EnCurso)+' ('+CONVERT(VARCHAR(5),@GA_PctEnCurso)+'%)</small></span>' +
                        '<span><i class="is-pending"></i><b>Pendientes</b><small>'+CONVERT(VARCHAR(10),@GA_Pendientes)+' ('+CONVERT(VARCHAR(5),@GA_PctPendientes)+'%)</small></span>' +
                        '<span><i class="is-overdue"></i><b>Vencidas</b><small>'+CONVERT(VARCHAR(10),@GA_Vencidas)+' ('+CONVERT(VARCHAR(5),@GA_PctVencidas)+'%)</small></span>' +
                        CASE WHEN @GA_Canceladas>0 THEN '<span><i class="is-cancelled"></i><b>Canceladas</b><small>'+CONVERT(VARCHAR(10),@GA_Canceladas)+' ('+CONVERT(VARCHAR(5),@GA_PctCanceladas)+'%)</small></span>' ELSE '' END +
                        CASE WHEN @GA_Otras>0 THEN '<span><i class="is-other"></i><b>Otras</b><small>'+CONVERT(VARCHAR(10),@GA_Otras)+' ('+CONVERT(VARCHAR(5),@GA_PctOtras)+'%)</small></span>' ELSE '' END +
                    '</div>' +
                '</div>' +
                '<div class="vct-360-active-management-total">' +
                    '<span>Total de gestiones</span>' +
                    '<b>'+CONVERT(VARCHAR(10),@GA_Total)+'</b>' +
                    '<small>'+CONVERT(VARCHAR(10),@ProyectosActivos)+' proyecto(s) activo(s)</small>' +
                '</div>' +
            '</div>';
    END;
 
    DECLARE @HTML_RENTABILIDAD VARCHAR(MAX)=
        '<div class="vct-360-profitability">' +
            '<div class="vct-360-profitability-metrics">' +
                '<div><span>Monto proyectos activos</span><b>$'+@MontoActivoTxt+'</b></div>' +
                '<div><span>Costos</span><b>$'+@CostoActivoTxt+'</b></div>' +
                '<div><span>Margen</span><b class="'+CASE WHEN @MargenActivo<0 THEN 'is-negative' ELSE 'is-positive' END+'">$'+@MargenActivoTxt+'</b></div>' +
                '<div class="vct-360-profitability-rate '+CASE WHEN @MargenActivo<0 THEN 'is-negative' ELSE 'is-positive' END+'"><b>'+CONVERT(VARCHAR(12),@MargenPct)+'%</b><span>Margen</span></div>' +
            '</div>' +
            '<div class="vct-360-profitability-track">' +
                CASE WHEN @CostoPctBar>0 THEN '<span class="is-cost" style="width:'+CONVERT(VARCHAR(5),@CostoPctBar)+'%;"></span>' ELSE '' END +
                CASE WHEN @MargenPctBar>0 THEN '<span class="is-margin" style="width:'+CONVERT(VARCHAR(5),@MargenPctBar)+'%;"></span>' ELSE '' END +
            '</div>' +
            '<div class="vct-360-profitability-legend">' +
                '<span><i class="is-cost"></i>Costos</span>' +
                '<span><i class="is-margin"></i>Margen</span>' +
            '</div>' +
        '</div>';
 
    /* Texto compacto para KPI de monto activo. */
    DECLARE @MontoActivoKpiTxt VARCHAR(40);
    IF ABS(@MontoActivo)>=1000000
        SET @MontoActivoKpiTxt=REPLACE(CONVERT(VARCHAR(30),CONVERT(NUMERIC(18,1),@MontoActivo/1000000.0)),'.',',')+' M';
    ELSE IF ABS(@MontoActivo)>=1000
        SET @MontoActivoKpiTxt=REPLACE(CONVERT(VARCHAR(30),CONVERT(NUMERIC(18,1),@MontoActivo/1000.0)),'.',',')+' K';
    ELSE
        SET @MontoActivoKpiTxt=@MontoActivoTxt;
 
    /* ------------------------------------------------------------
       KPI - COMPARACION REAL POR COHORTES DE INICIO
       ------------------------------------------------------------
       El modelo no posee snapshots historicos de estado/avance. Para no
       inventar tendencias, la comparacion usa proyectos iniciados en los
       ultimos 12 meses disponibles del cliente vs. los 12 meses anteriores.
       ------------------------------------------------------------ */
    DECLARE
        @TrendFechaRef DATETIME=NULL,
        @TrendPeriodoFin DATETIME=NULL,
        @TrendActualDesde DATETIME=NULL,
        @TrendPrevDesde DATETIME=NULL,
        @TP_ProyActual INT=0,
        @TP_ProyPrev INT=0,
        @TP_ActivosActual INT=0,
        @TP_ActivosPrev INT=0,
        @TP_MontoActual NUMERIC(18,2)=0,
        @TP_MontoPrev NUMERIC(18,2)=0,
        @TP_AvanceActual NUMERIC(18,2)=0,
        @TP_AvancePrev NUMERIC(18,2)=0;
 
    SELECT @TrendFechaRef=MAX(FECHA_INICIO)
    FROM #PROYECTOS360;
 
    IF @TrendFechaRef IS NULL SET @TrendFechaRef=GETDATE();
 
    SET @TrendPeriodoFin=DATEADD(DAY,1,@TrendFechaRef);
    SET @TrendActualDesde=DATEADD(MONTH,-12,@TrendPeriodoFin);
    SET @TrendPrevDesde=DATEADD(MONTH,-24,@TrendPeriodoFin);
 
    SELECT
        @TP_ProyActual=SUM(CASE WHEN FECHA_INICIO>=@TrendActualDesde AND FECHA_INICIO<@TrendPeriodoFin THEN 1 ELSE 0 END),
        @TP_ProyPrev=SUM(CASE WHEN FECHA_INICIO>=@TrendPrevDesde AND FECHA_INICIO<@TrendActualDesde THEN 1 ELSE 0 END),
        @TP_ActivosActual=SUM(CASE WHEN FECHA_INICIO>=@TrendActualDesde AND FECHA_INICIO<@TrendPeriodoFin AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN 1 ELSE 0 END),
        @TP_ActivosPrev=SUM(CASE WHEN FECHA_INICIO>=@TrendPrevDesde AND FECHA_INICIO<@TrendActualDesde AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN 1 ELSE 0 END),
        @TP_MontoActual=SUM(CASE WHEN FECHA_INICIO>=@TrendActualDesde AND FECHA_INICIO<@TrendPeriodoFin AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN ISNULL(MONTO_TOTAL,0) ELSE 0 END),
        @TP_MontoPrev=SUM(CASE WHEN FECHA_INICIO>=@TrendPrevDesde AND FECHA_INICIO<@TrendActualDesde AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN ISNULL(MONTO_TOTAL,0) ELSE 0 END)
    FROM #PROYECTOS360;
 
    SELECT @TP_AvanceActual=ISNULL(AVG(CONVERT(NUMERIC(18,2),PORCENTAJE_AVANCE)),0)
    FROM #PROYECTOS360
    WHERE FECHA_INICIO>=@TrendActualDesde
      AND FECHA_INICIO<@TrendPeriodoFin
      AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO');
 
    SELECT @TP_AvancePrev=ISNULL(AVG(CONVERT(NUMERIC(18,2),PORCENTAJE_AVANCE)),0)
    FROM #PROYECTOS360
    WHERE FECHA_INICIO>=@TrendPrevDesde
      AND FECHA_INICIO<@TrendActualDesde
      AND ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO');
 
    SET @TP_ProyActual=ISNULL(@TP_ProyActual,0);
    SET @TP_ProyPrev=ISNULL(@TP_ProyPrev,0);
    SET @TP_ActivosActual=ISNULL(@TP_ActivosActual,0);
    SET @TP_ActivosPrev=ISNULL(@TP_ActivosPrev,0);
    SET @TP_MontoActual=ISNULL(@TP_MontoActual,0);
    SET @TP_MontoPrev=ISNULL(@TP_MontoPrev,0);
 
    DECLARE
        @TrendProyPct INT=NULL,
        @TrendActivosPct INT=NULL,
        @TrendMontoPct INT=NULL,
        @TrendAvancePct INT=NULL,
        @TrendProyTxt VARCHAR(30)='',
        @TrendActivosTxt VARCHAR(30)='',
        @TrendMontoTxt VARCHAR(30)='',
        @TrendAvanceTxt VARCHAR(30)='',
        @TrendProyClass VARCHAR(20)='is-neutral',
        @TrendActivosClass VARCHAR(20)='is-neutral',
        @TrendMontoClass VARCHAR(20)='is-neutral',
        @TrendAvanceClass VARCHAR(20)='is-neutral';
 
    IF @TP_ProyPrev>0
        SET @TrendProyPct=CONVERT(INT,ROUND(((@TP_ProyActual-@TP_ProyPrev)*100.0)/@TP_ProyPrev,0));
    IF @TP_ActivosPrev>0
        SET @TrendActivosPct=CONVERT(INT,ROUND(((@TP_ActivosActual-@TP_ActivosPrev)*100.0)/@TP_ActivosPrev,0));
    IF @TP_MontoPrev>0
        SET @TrendMontoPct=CONVERT(INT,ROUND(((@TP_MontoActual-@TP_MontoPrev)*100.0)/@TP_MontoPrev,0));
    IF @TP_AvancePrev>0
        SET @TrendAvancePct=CONVERT(INT,ROUND(((@TP_AvanceActual-@TP_AvancePrev)*100.0)/@TP_AvancePrev,0));
 
    SET @TrendProyTxt=CASE WHEN @TP_ProyPrev=0 THEN CASE WHEN @TP_ProyActual>0 THEN 'NUEVO' ELSE '0%' END ELSE CASE WHEN @TrendProyPct>0 THEN '+' ELSE '' END+CONVERT(VARCHAR(12),@TrendProyPct)+'%' END;
    SET @TrendActivosTxt=CASE WHEN @TP_ActivosPrev=0 THEN CASE WHEN @TP_ActivosActual>0 THEN 'NUEVO' ELSE '0%' END ELSE CASE WHEN @TrendActivosPct>0 THEN '+' ELSE '' END+CONVERT(VARCHAR(12),@TrendActivosPct)+'%' END;
    SET @TrendMontoTxt=CASE WHEN @TP_MontoPrev=0 THEN CASE WHEN @TP_MontoActual>0 THEN 'NUEVO' ELSE '0%' END ELSE CASE WHEN @TrendMontoPct>0 THEN '+' ELSE '' END+CONVERT(VARCHAR(12),@TrendMontoPct)+'%' END;
    SET @TrendAvanceTxt=CASE WHEN @TP_AvancePrev=0 THEN CASE WHEN @TP_AvanceActual>0 THEN 'NUEVO' ELSE '0%' END ELSE CASE WHEN @TrendAvancePct>0 THEN '+' ELSE '' END+CONVERT(VARCHAR(12),@TrendAvancePct)+'%' END;
 
    IF @TrendProyPct>0 OR (@TP_ProyPrev=0 AND @TP_ProyActual>0) SET @TrendProyClass='is-up';
    ELSE IF @TrendProyPct<0 SET @TrendProyClass='is-down';
 
    IF @TrendActivosPct>0 OR (@TP_ActivosPrev=0 AND @TP_ActivosActual>0) SET @TrendActivosClass='is-up';
    ELSE IF @TrendActivosPct<0 SET @TrendActivosClass='is-down';
 
    IF @TrendMontoPct>0 OR (@TP_MontoPrev=0 AND @TP_MontoActual>0) SET @TrendMontoClass='is-up';
    ELSE IF @TrendMontoPct<0 SET @TrendMontoClass='is-down';
 
    IF @TrendAvancePct>0 OR (@TP_AvancePrev=0 AND @TP_AvanceActual>0) SET @TrendAvanceClass='is-up';
    ELSE IF @TrendAvancePct<0 SET @TrendAvanceClass='is-down';
 
    /* ============================================================
       13. HEADER / BREADCRUMB
       ============================================================ */
    DECLARE @NombreLimpio VARCHAR(300) = LTRIM(RTRIM(@Cliente));
    DECLARE @PosEspacio INT = CHARINDEX(' ',@NombreLimpio);
    DECLARE @Iniciales VARCHAR(4) = '';
 
    IF @NombreLimpio <> ''
    BEGIN
        IF @PosEspacio > 0
            SET @Iniciales = UPPER(LEFT(@NombreLimpio,1) + LEFT(LTRIM(SUBSTRING(@NombreLimpio,@PosEspacio+1,300)),1));
        ELSE
            SET @Iniciales = UPPER(LEFT(@NombreLimpio,1));
    END;
 
    IF ISNULL(@Iniciales,'') = '' SET @Iniciales = '--';
 
    DECLARE @E_Cliente VARCHAR(300) = REPLACE(REPLACE(REPLACE(REPLACE(@Cliente,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_CUIT VARCHAR(50) = REPLACE(REPLACE(REPLACE(REPLACE(@CUIT,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_Localidad VARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Localidad,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_Provincia VARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Provincia,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
 
    DECLARE
        @HeaderContactoID       INT=NULL,
        @HeaderContactoNombres  VARCHAR(100)='',
        @HeaderContactoApellido VARCHAR(100)='',
        @HeaderContactoNombre   VARCHAR(300)='',
        @HeaderContactoCargo    VARCHAR(100)='',
        @HeaderContactoTelefono VARCHAR(100)='',
        @HeaderContactoEmail    VARCHAR(200)='';
 
    SELECT TOP 1
        @HeaderContactoID=C.ID,
        @HeaderContactoNombres=ISNULL(C.NOMBRES,''),
        @HeaderContactoApellido=ISNULL(C.APELLIDO,''),
        @HeaderContactoNombre=ISNULL(NULLIF(LTRIM(RTRIM(C.NOMBRE)),''),'-'),
        @HeaderContactoCargo=ISNULL(C.CARGO,''),
        @HeaderContactoTelefono=ISNULL(C.TELEFONO,''),
        @HeaderContactoEmail=ISNULL(C.EMAIL,'')
    FROM #CONTACTOS360 C
    ORDER BY
        CASE WHEN C.ID_TELEFONO IS NOT NULL OR C.ID_EMAIL IS NOT NULL THEN 0 ELSE 1 END,
        C.ID;
 
    IF NULLIF(LTRIM(RTRIM(@HeaderContactoTelefono)),'') IS NULL
        SET @HeaderContactoTelefono=ISNULL(@Telefono,'');
 
    IF NULLIF(LTRIM(RTRIM(@HeaderContactoEmail)),'') IS NULL
        SET @HeaderContactoEmail=ISNULL(@Email,'');
 
    DECLARE @HeaderContactoIniciales VARCHAR(4)=
        UPPER
        (
            ISNULL(LEFT(NULLIF(LTRIM(RTRIM(@HeaderContactoNombres)),''),1),'')+
            ISNULL(LEFT(NULLIF(LTRIM(RTRIM(@HeaderContactoApellido)),''),1),'')
        );
 
    IF NULLIF(@HeaderContactoIniciales,'') IS NULL SET @HeaderContactoIniciales='--';
 
    DECLARE @E_HeaderContactoNombre VARCHAR(300)=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@HeaderContactoNombre,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_HeaderContactoCargo VARCHAR(100)=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@HeaderContactoCargo,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_HeaderContactoTelefono VARCHAR(100)=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@HeaderContactoTelefono,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    DECLARE @E_HeaderContactoEmail VARCHAR(200)=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@HeaderContactoEmail,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
    DECLARE @HeaderContactoBg VARCHAR(20)=
        CASE ABS(CONVERT(BIGINT,ISNULL(@HeaderContactoID,0))) % 8
            WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
            WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8' END;
 
    DECLARE @HeaderContactoTx VARCHAR(20)=
        CASE ABS(CONVERT(BIGINT,ISNULL(@HeaderContactoID,0))) % 8
            WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
            WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94' END;
 
    DECLARE @MapsRaw VARCHAR(1000)=LTRIM(RTRIM(
        ISNULL(@Domicilio,'')+
        CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(@Localidad,''))),'') IS NOT NULL THEN ', '+@Localidad ELSE '' END+
        CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(@Provincia,''))),'') IS NOT NULL THEN ', '+@Provincia ELSE '' END
    ));
 
    DECLARE @MapsQuery VARCHAR(1200)=@MapsRaw;
    SET @MapsQuery=REPLACE(@MapsQuery,'%','%25');
    SET @MapsQuery=REPLACE(@MapsQuery,' ','+');
    SET @MapsQuery=REPLACE(@MapsQuery,'#','%23');
    SET @MapsQuery=REPLACE(@MapsQuery,'&','%26');
    SET @MapsQuery=REPLACE(@MapsQuery,'/','%2F');
 
    DECLARE @MapsUrl VARCHAR(1500)=
        CASE WHEN NULLIF(@MapsRaw,'') IS NULL THEN ''
             ELSE 'https://www.google.com/maps/search/?api=1&amp;query='+@MapsQuery END;
 
    DECLARE @EstadoBadgeClase VARCHAR(20) = 'is-neutral';
    DECLARE @EstadoBadgeTexto VARCHAR(50) = UPPER(ISNULL(NULLIF(@Estado,''),'SIN ESTADO'));
 
    IF UPPER(@Estado) IN ('1','ACTIVO','ACTIVA')
    BEGIN
        SET @EstadoBadgeClase = 'is-active';
        SET @EstadoBadgeTexto = 'ACTIVO';
    END
    ELSE IF UPPER(@Estado) IN ('0','INACTIVO','INACTIVA','DESAFECTADO','DESAFECTADA','BAJA')
    BEGIN
        SET @EstadoBadgeClase = 'is-inactive';
        SET @EstadoBadgeTexto = 'INACTIVO';
    END;
 
    DECLARE @HTML_ESTADO_BADGE VARCHAR(200) =
        '<span class="vct-360-badge ' + @EstadoBadgeClase + '">' + @EstadoBadgeTexto + '</span>';
 
    /* Breadcrumb simple - opción 1
       Sin botones ni cards. Clientes > Vista 360 > Nombre del cliente.
       El primer paso vuelve al listado de Clientes mediante goto(). */
    SET @BTN_BACK =
        '<nav class="vct-breadcrumb-simple" aria-label="Breadcrumb">' +
            '<button type="button" class="vct-breadcrumb-link" ' +
                    'data-vct-v360-back ' +
                    'data-vct-guid="26899560-A8E8-4E54-A3C8-F9ED1E95DC45">Clientes</button>' +
            '<span class="vct-breadcrumb-sep">›</span>' +
            '<span class="vct-breadcrumb-item">Vista 360</span>' +
            '<span class="vct-breadcrumb-sep">›</span>' +
            '<span class="vct-breadcrumb-current">' + @E_Cliente + '</span>' +
        '</nav>';
 
DECLARE @CssVersion VARCHAR(20) =
        CONVERT(VARCHAR(20),DATEDIFF(SECOND,'2020-01-01',GETDATE()));
 
    /* ============================================================
       13B. CATALOGO DE PROVINCIAS PARA FORMULARIOS
       Valor almacenado: CAT_DATA_CODE
       Texto visible:    CAT_DATA_DESC
       ============================================================ */
    DECLARE @HTML_PROVINCIAS VARCHAR(MAX)='';
 
    SELECT @HTML_PROVINCIAS = ISNULL((
        SELECT
            '<option value="' +
            REPLACE(REPLACE(REPLACE(REPLACE(
                ISNULL(CONVERT(VARCHAR(100),CD.CAT_DATA_CODE),''),
                '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
            '">' +
            REPLACE(REPLACE(REPLACE(REPLACE(
                ISNULL(CONVERT(VARCHAR(300),CD.CAT_DATA_DESC),''),
                '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
            '</option>'
        FROM dbo.CAT_DATA CD WITH(NOLOCK)
        WHERE CD.PAR_KEY =
        (
            SELECT TOP 1 CT.PKEY
            FROM dbo.CAT_TYPE CT WITH(NOLOCK)
            WHERE CT.CAT_TYPE_CODE='Provincia'
        )
        ORDER BY CD.CAT_DATA_CODE
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* Opciones del formulario de Contactos.
       El value enviado es la FK real (ID_TELEFONO / ID_EMAIL). */
    DECLARE
        @HTML_CONTACT_TELEFONOS VARCHAR(MAX)='',
        @HTML_CONTACT_EMAILS    VARCHAR(MAX)='';
 
    SELECT @HTML_CONTACT_TELEFONOS = ISNULL((
        SELECT
            '<option value="' + CONVERT(VARCHAR(30),T.ID) + '">' +
            REPLACE(REPLACE(REPLACE(REPLACE(
                LTRIM(RTRIM(
                    CASE
                        WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(20),T.CODAREA),''))), '') IS NULL
                            THEN ISNULL(CONVERT(VARCHAR(50),T.NRO),'')
                        ELSE '('+CONVERT(VARCHAR(20),T.CODAREA)+') '+ISNULL(CONVERT(VARCHAR(50),T.NRO),'')
                    END
                )),
                '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
            CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN ' (Principal)' ELSE '' END +
            '</option>'
        FROM dbo.VCT_TELEFONOS T WITH(NOLOCK)
        WHERE T.TIPO_ENTIDAD='CLIENTE'
          AND T.ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,T.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    SELECT @HTML_CONTACT_EMAILS = ISNULL((
        SELECT
            '<option value="' + CONVERT(VARCHAR(30),E.ID) + '">' +
            REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.EMAIL,''))),
                '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') +
            CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI' THEN ' (Principal)' ELSE '' END +
            '</option>'
        FROM dbo.VCT_EMAILS E WITH(NOLOCK)
        WHERE E.TIPO_ENTIDAD='CLIENTE'
          AND E.ID_ENTIDAD=@ID_CLIENTE
        ORDER BY CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,E.ID
        FOR XML PATH(''), TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    /* ============================================================
       14. FORMS DINAMICOS - DRAWERS
       ------------------------------------------------------------
       Se reutilizan:
         VCT_MAIN_RENDER_FORM
         VCT_MAIN_RENDER_FORM_ACTION
 
       Unicamente se declaran campos. No hay HTML/JS particular
       por domicilio / teléfono / email / contacto.
       ============================================================ */
    DECLARE
        @HTML_DRAWER_DOM VARCHAR(MAX)='',
        @HTML_DRAWER_TEL VARCHAR(MAX)='',
        @HTML_DRAWER_MAIL VARCHAR(MAX)='',
        @HTML_DRAWER_CONT VARCHAR(MAX)='',
        @BTN_ADD_DOM VARCHAR(MAX)='',
        @BTN_EDIT_DOM VARCHAR(MAX)='',
        @BTN_ADD_TEL VARCHAR(MAX)='',
        @BTN_EDIT_TEL VARCHAR(MAX)='',
        @BTN_ADD_MAIL VARCHAR(MAX)='',
        @BTN_EDIT_MAIL VARCHAR(MAX)='',
        @BTN_ADD_CONT VARCHAR(MAX)='',
        @BTN_EDIT_CONT VARCHAR(MAX)='';
 
    /* Acciones: modificar datos relacionados requiere CLIENTES.EDIT */
    IF @CAN_EDIT=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',@TARGET_FORM='vctDrawerDomicilio',
             @FORM_TITLE='Nuevo domicilio',
             @FORM_SUBTITLE='Agregue una dirección para el cliente.',
             @FORM_ICON='map-pin',@BUTTON_TEXT='Agregar',@BUTTON_ICON='map-pin',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar domicilio',@OUTHTML=@BTN_ADD_DOM OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',@TARGET_FORM='vctDrawerDomicilio',
             @FORM_TITLE='Editar domicilio',
             @FORM_SUBTITLE='Modifique los datos de la dirección.',
             @FORM_ICON='map-pin',@BUTTON_TEXT='Editar',@BUTTON_ICON='edit',
             @BUTTON_CLASS='vct-btn vct-btn-outline vct-btn-sm',
             @TOOLTIP='Editar domicilio',@OUTHTML=@BTN_EDIT_DOM OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',@TARGET_FORM='vctDrawerTelefono',
             @FORM_TITLE='Nuevo teléfono',
             @FORM_SUBTITLE='Agregue un teléfono para el cliente.',
             @FORM_ICON='phone',@BUTTON_TEXT='Agregar',@BUTTON_ICON='phone',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar teléfono',@OUTHTML=@BTN_ADD_TEL OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',@TARGET_FORM='vctDrawerTelefono',
             @FORM_TITLE='Editar teléfono',
             @FORM_SUBTITLE='Modifique el teléfono seleccionado.',
             @FORM_ICON='phone',@BUTTON_TEXT='Editar',@BUTTON_ICON='edit',
             @BUTTON_CLASS='vct-btn vct-btn-outline vct-btn-sm',
             @TOOLTIP='Editar teléfono',@OUTHTML=@BTN_EDIT_TEL OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',@TARGET_FORM='vctDrawerEmail',
             @FORM_TITLE='Nuevo email',
             @FORM_SUBTITLE='Agregue un email para el cliente.',
             @FORM_ICON='mail',@BUTTON_TEXT='Agregar',@BUTTON_ICON='mail',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar email',@OUTHTML=@BTN_ADD_MAIL OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',@TARGET_FORM='vctDrawerEmail',
             @FORM_TITLE='Editar email',
             @FORM_SUBTITLE='Modifique el email seleccionado.',
             @FORM_ICON='mail',@BUTTON_TEXT='Editar',@BUTTON_ICON='edit',
             @BUTTON_CLASS='vct-btn vct-btn-outline vct-btn-sm',
             @TOOLTIP='Editar email',@OUTHTML=@BTN_EDIT_MAIL OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',@TARGET_FORM='vctDrawerContacto',
             @FORM_TITLE='Nuevo contacto',
             @FORM_SUBTITLE='Agregue una persona de contacto.',
             @FORM_ICON='contact',@BUTTON_TEXT='Agregar',@BUTTON_ICON='contact',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar contacto',@OUTHTML=@BTN_ADD_CONT OUTPUT;
 
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='EDIT',@TARGET_FORM='vctDrawerContacto',
             @FORM_TITLE='Editar contacto',
             @FORM_SUBTITLE='Modifique los datos del contacto.',
             @FORM_ICON='contact',@BUTTON_TEXT='Editar',@BUTTON_ICON='edit',
             @BUTTON_CLASS='vct-btn vct-btn-outline vct-btn-sm',
             @TOOLTIP='Editar contacto',@OUTHTML=@BTN_EDIT_CONT OUTPUT;
    END;
 
    /* Registro principal actual usado por el botón EDITAR del encabezado
       de cada tab. Si hay varios registros, la grilla sigue mostrando todos;
       este botón edita el PRINCIPAL o el primero según el orden actual. */
    DECLARE
        @DomID VARCHAR(100)='',
        @DomCalle VARCHAR(300)='',
        @DomNro VARCHAR(30)='',
        @DomPiso VARCHAR(50)='',
        @DomDepto VARCHAR(50)='',
        @DomLoc VARCHAR(100)='',
        @DomProv VARCHAR(100)='',
        @DomPrincipal VARCHAR(10)='0',
        @DomObs VARCHAR(1000)='',
        @TelID VARCHAR(100)='',
        @TelCodArea VARCHAR(20)='',
        @TelNro VARCHAR(30)='',
        @TelPrincipal VARCHAR(10)='0',
        @TelObs VARCHAR(1000)='',
        @MailID VARCHAR(100)='',
        @MailValor VARCHAR(200)='',
        @MailPrincipal VARCHAR(10)='0',
        @MailObs VARCHAR(1000)='',
        @ContID VARCHAR(100)='',
        @ContNombres VARCHAR(100)='',
        @ContApellido VARCHAR(100)='',
        @ContTelID VARCHAR(30)='',
        @ContMailID VARCHAR(30)='',
        @ContObs VARCHAR(1000)='';
 
    SELECT TOP 1
        @DomID=CONVERT(VARCHAR(100),ID),
        @DomCalle=ISNULL(CALLE,''),@DomNro=ISNULL(CONVERT(VARCHAR(30),NRO),''),
        @DomPiso=ISNULL(PISO,''),@DomDepto=ISNULL(DEPTO,''),
        @DomLoc=ISNULL(LOCALIDAD,''),@DomProv=ISNULL(PROVINCIA,''),
        @DomPrincipal=CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN '1' ELSE '0' END,
        @DomObs=ISNULL(OBSERVACIONES,'')
    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    SELECT TOP 1
        @TelID=CONVERT(VARCHAR(100),ID),
        @TelCodArea=ISNULL(CONVERT(VARCHAR(20),CODAREA),''),
        @TelNro=ISNULL(CONVERT(VARCHAR(30),NRO),''),
        @TelPrincipal=CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN '1' ELSE '0' END,
        @TelObs=ISNULL(OBSERVACIONES,'')
    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    SELECT TOP 1
        @MailID=CONVERT(VARCHAR(100),ID),
        @MailValor=ISNULL(EMAIL,''),
        @MailPrincipal=CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN '1' ELSE '0' END,
        @MailObs=ISNULL(OBSERVACIONES,'')
    FROM dbo.VCT_EMAILS WITH(NOLOCK)
    WHERE TIPO_ENTIDAD='CLIENTE'
      AND ID_ENTIDAD=@ID_CLIENTE
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    SELECT TOP 1
        @ContID=CONVERT(VARCHAR(100),ID),
        @ContNombres=ISNULL(NOMBRES,''),
        @ContApellido=ISNULL(APELLIDO,''),
        @ContTelID=ISNULL(CONVERT(VARCHAR(30),ID_TELEFONO),''),
        @ContMailID=ISNULL(CONVERT(VARCHAR(30),ID_EMAIL),''),
        @ContObs=ISNULL(OBSERVACIONES,'')
    FROM #CONTACTOS360
    ORDER BY APELLIDO,NOMBRES,ID;
 
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT,FIELD_NAME VARCHAR(50),LABEL VARCHAR(150),FIELD_TYPE VARCHAR(20),
        COL_SPAN INT,REQUIRED BIT,MAX_LENGTH INT,PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100),DEFAULT_VALUE VARCHAR(MAX),READONLY BIT,
        HIDDEN BIT,HELP_TEXT VARCHAR(500),SOURCE_FIELD VARCHAR(100)
    );
 
    /* Valores calculados previamente porque SQL Server no admite
       expresiones CASE directamente en los parámetros de EXEC. */
    DECLARE
        @ERR_DOM   VARCHAR(MAX)='',
        @ERR_TEL   VARCHAR(MAX)='',
        @ERR_MAIL  VARCHAR(MAX)='',
        @ERR_CONT  VARCHAR(MAX)='',
        @OPEN_DOM  BIT=0,
        @OPEN_TEL  BIT=0,
        @OPEN_MAIL BIT=0,
        @OPEN_CONT BIT=0;
 
    SET @ERR_DOM  = CASE WHEN @VFORM_ENTITY='DOMICILIO' THEN @VFORM_ERROR ELSE '' END;
    SET @ERR_TEL  = CASE WHEN @VFORM_ENTITY='TELEFONO'  THEN @VFORM_ERROR ELSE '' END;
    SET @ERR_MAIL = CASE WHEN @VFORM_ENTITY='EMAIL'     THEN @VFORM_ERROR ELSE '' END;
    SET @ERR_CONT = CASE WHEN @VFORM_ENTITY='CONTACTO'  THEN @VFORM_ERROR ELSE '' END;
 
    SET @OPEN_DOM  = CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN 1 ELSE 0 END;
    SET @OPEN_TEL  = CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO'  THEN 1 ELSE 0 END;
    SET @OPEN_MAIL = CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL'     THEN 1 ELSE 0 END;
    SET @OPEN_CONT = CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO'  THEN 1 ELSE 0 END;
 
    /* ---------------- Drawer Domicilio ---------------- */
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Calle / Avenida','TEXT',12,1,300,'Ingrese calle o avenida',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'calle'),
    (2,'TEXTO12','Número','TEXT',4,1,30,'Número',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'nro'),
    (3,'TEXTO13','Piso','TEXT',4,0,50,'Piso',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T13 ELSE NULL END,0,0,NULL,'piso'),
    (4,'TEXTO14','Depto','TEXT',4,0,50,'Depto',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T14 ELSE NULL END,0,0,NULL,'depto'),
    (5,'TEXTO15','Localidad','TEXT',6,1,100,'Localidad',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T15 ELSE NULL END,0,0,NULL,'localidad'),
    (6,'TEXTO16','Provincia','TEXT',6,1,100,'Provincia',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T16 ELSE NULL END,0,0,NULL,'provincia'),
    (7,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (8,'TEXTO17','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_T17 ELSE NULL END,0,0,NULL,'observaciones'),
    (9,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (10,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'DOMICILIO',0,1,NULL,NULL),
    (11,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (12,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (13,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (14,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'domicilio',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerDomicilio',@TITLE='Domicilio',
         @SUBTITLE='Datos de dirección del cliente.',@ICON='map-pin',
         @LAYOUT='DRAWER',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_DOM,
         @OPEN_ON_RENDER=@OPEN_DOM,
         @OUTHTML=@HTML_DRAWER_DOM OUTPUT;
 
    /* Configuración declarativa: el JS genérico convierte TEXTO16
       en select y reutiliza el mismo componente FormSelect. */
    SET @HTML_DRAWER_DOM = ISNULL(@HTML_DRAWER_DOM,'') +
        '<template data-vct-field-options ' +
        'data-vct-target="vctDrawerDomicilio" ' +
        'data-vct-field="TEXTO16" ' +
        'data-vct-placeholder="Seleccione una provincia">' +
        ISNULL(@HTML_PROVINCIAS,'') +
        '</template>';
 
    /* ---------------- Drawer Teléfono ---------------- */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Código de área','TEXT',6,1,20,'Código de área',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'codarea'),
    (2,'TEXTO12','Número','TEXT',6,1,30,'Número',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'nro'),
    (3,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (4,'TEXTO13','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN @VFORM_T13 ELSE NULL END,0,0,NULL,'observaciones'),
    (5,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'TELEFONO',0,1,NULL,NULL),
    (7,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (10,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'telefonos',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerTelefono',@TITLE='Teléfono',
         @SUBTITLE='Número de contacto del cliente.',@ICON='phone',
         @LAYOUT='DRAWER',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_TEL,
         @OPEN_ON_RENDER=@OPEN_TEL,
         @OUTHTML=@HTML_DRAWER_TEL OUTPUT;
 
    /* ---------------- Drawer Email ---------------- */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Email','EMAIL',12,1,200,'usuario@dominio.com',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL' THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'email'),
    (2,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL' THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (3,'TEXTO12','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL' THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'observaciones'),
    (4,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL' THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (5,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'EMAIL',0,1,NULL,NULL),
    (6,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (7,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (8,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'email',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerEmail',@TITLE='Email',
         @SUBTITLE='Dirección de correo del cliente.',@ICON='mail',
         @LAYOUT='DRAWER',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_MAIL,
         @OPEN_ON_RENDER=@OPEN_MAIL,
         @OUTHTML=@HTML_DRAWER_MAIL OUTPUT;
 
    /* ---------------- Drawer Contacto ---------------- */
    DELETE FROM #VCT_FORM_FIELDS;
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Nombres','TEXT',6,1,100,'Nombres',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'nombres'),
    (2,'TEXTO12','Apellido','TEXT',6,1,100,'Apellido',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'apellido'),
    (3,'TEXTO13','Cargo','TEXT',12,0,100,'Cargo',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T13 ELSE NULL END,0,0,NULL,'cargo'),
    (4,'TEXTO14','Teléfono','TEXT',6,0,30,'Seleccione un teléfono',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T14 ELSE NULL END,0,0,NULL,'telefono'),
    (5,'TEXTO15','Email','TEXT',6,0,30,'Seleccione un email',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T15 ELSE NULL END,0,0,NULL,'email'),
    (6,'TEXTO16','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_T16 ELSE NULL END,0,0,NULL,'observaciones'),
    (7,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='CONTACTO' THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (8,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'CONTACTO',0,1,NULL,NULL),
    (9,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (10,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (11,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (12,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'contacto',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerContacto',@TITLE='Contacto',
         @SUBTITLE='Persona de contacto del cliente.',@ICON='contact',
         @LAYOUT='DRAWER',@SAVE_LABEL='Guardar',@CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_CONT,
         @OPEN_ON_RENDER=@OPEN_CONT,
         @OUTHTML=@HTML_DRAWER_CONT OUTPUT;
 
    /* Teléfono y email del contacto se eligen exclusivamente entre los datos
       ya registrados en los ABM del cliente. FieldOptions mantiene el motor
       JS genérico y evita lógica específica de negocio en vct-main.js. */
    SET @HTML_DRAWER_CONT = ISNULL(@HTML_DRAWER_CONT,'') +
        '<template data-vct-field-options ' +
        'data-vct-target="vctDrawerContacto" ' +
        'data-vct-field="TEXTO14" ' +
        'data-vct-placeholder="Seleccione un teléfono">' +
        ISNULL(@HTML_CONTACT_TELEFONOS,'') +
        '</template>' +
        '<template data-vct-field-options ' +
        'data-vct-target="vctDrawerContacto" ' +
        'data-vct-field="TEXTO15" ' +
        'data-vct-placeholder="Seleccione un email">' +
        ISNULL(@HTML_CONTACT_EMAILS,'') +
        '</template>';
 
    /* ============================================================
       15. HTML VISTA 360
       ------------------------------------------------------------
       Sin JavaScript inline.
       Tabs -> vct-main.js
       Drawers/forms -> vct-main.js + renderers
       Charts -> CSS (el SP original no cargaba Chart.js; los gráficos
                 se construían con conic-gradient y barras CSS).
       ============================================================ */
    SET @OUTPARAM1 =
        ISNULL(@HTML_SHELL,'') + '
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
 
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-alta.css?v=1"><script src="../js/vct-proyecto-alta.js?v=2"></script><section class="vct-module vct-360-module vct-consultor360-module vct-cliente360-module vct-360-visual-final"
         data-vct-module
         data-vct-entity-theme="cliente"
         data-vct-tabs
         data-vct-tabs-active="'+ISNULL(@ACTIVE_TAB,'resumen')+'"
         data-vct-tabs-reset="'+CONVERT(VARCHAR(1),@V360_RESET_TAB)+'"
         data-vct-client-key="'+CONVERT(VARCHAR(100),@ID_CLIENTE)+'">
 
    <div class="vct-360-breadcrumb-row">
        '+ISNULL(@BTN_BACK,'')+'
    </div>
 
    <div class="vct-360-client-strip vct-360-consultor-strip">
        <div class="vct-360-card-left">
            <div class="vct-360-avatar">'+@Iniciales+'</div>
            <div class="vct-360-identity">
                <div class="vct-360-identity-title">
                    <h1>'+@E_Cliente+'</h1>
                    '+@HTML_ESTADO_BADGE+'
                </div>
                <div class="vct-360-client-meta">
                    <span><span data-vct-icon="file-text"></span>CUIT '+CASE WHEN @E_CUIT='' THEN '-' ELSE @E_CUIT END+'</span>
                    <span><span data-vct-icon="calendar"></span>Cliente desde '+ISNULL(CONVERT(VARCHAR(10),@FechaAlta,103),'-')+'</span>
                    <span><span data-vct-icon="clock-3"></span>Antigüedad '+CASE WHEN @AntiguedadAnios IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),@AntiguedadAnios)+' años' END+'</span>
                </div>
            </div>
        </div>
 
        <div class="vct-360-card-right"
             data-vct-row
             data-vct-id="'+CONVERT(VARCHAR(20),@ID_CLIENTE)+'">
 
            '+CASE
                WHEN @MapsUrl<>'' THEN '
            <a class="vct-360-header-map-btn"
               href="'+@MapsUrl+'"
               target="_blank"
               rel="noopener noreferrer"
               title="Ver ubicación"
               aria-label="Ver ubicación">
                <span data-vct-icon="map-pin"></span>
            </a>'
                ELSE ''
              END+'
 
            <div class="vct-360-alerts"
                 data-vct-alerts
                 data-vct-alert-count="0"
                 aria-label="Alertas: 0">
                <span class="vct-360-alert-icon"><span data-vct-icon="bell"></span></span>
                <span class="vct-360-alert-count">0</span>
            </div>
 
            <span class="vct-360-card-divider" aria-hidden="true"></span>
 
            <div class="vct-360-last-management">
                <span class="vct-360-inline-stat-icon"><span data-vct-icon="calendar"></span></span>
                <span>
                    <span class="vct-360-inline-stat-label">Última Gestión</span>
                    <span class="vct-360-inline-stat-value">'+@UltimaGestionFechaTxt+'</span>
                </span>
            </div>
 
            <button type="button"
                    class="vct-row-menu-trigger vct-360-header-menu-trigger"
                    data-vct-command="row-context-menu"
                    data-vct-entity="CLIENTE"
                    data-vct-tab="resumen"
                    data-vct-actions="project-create"
                    aria-label="Acciones">
                <span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span>
            </button>
        </div>
    </div>
 
    <div class="vct-360-content-shell">
        <div class="vct-360-stats-row">
            <div class="vct-360-stat" data-vct-tone="blue">
                <span class="vct-360-stat-main">
                    <span class="vct-360-stat-label">Proyectos totales</span>
                    <b>'+CONVERT(VARCHAR(10),@ProyectosCount)+'</b>
                    <small>'+CONVERT(VARCHAR(10),@ProyectosActivos)+' activos</small>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="violet">
                <span class="vct-360-stat-main">
                    <span class="vct-360-stat-label">Proyectos activos</span>
                    <b>'+CONVERT(VARCHAR(10),@ProyectosActivos)+'</b>
                    <small>'+CONVERT(VARCHAR(10),@PctProyectosActivos)+'% del total</small>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="mint">
                <span class="vct-360-stat-main">
                    <span class="vct-360-stat-label">Monto en curso</span>
                    <b>$'+@MontoActivoKpiTxt+'</b>
                    <small>proyectos activos</small>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="circle-dollar-sign"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="amber">
                <span class="vct-360-stat-main">
                    <span class="vct-360-stat-label">Avance promedio</span>
                    <b>'+CONVERT(VARCHAR(10),@AvanceActivoEntero)+'%</b>
                    <small>'+CONVERT(VARCHAR(10),@ProyectosActivos)+' proyecto(s)</small>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="chart-no-axes-column-increasing"></span></span>
            </div>
        </div>
 
        <div class="vct-360-tabsbar" data-vct-tablist>
            <button type="button" data-vct-tab="resumen"><span data-vct-icon="scan-eye"></span><span>Resumen</span></button>
            <button type="button" data-vct-tab="proyectos"><span data-vct-icon="folder"></span><span>Proyectos</span></button>
            <button type="button" data-vct-tab="domicilio"><span data-vct-icon="map-pin"></span><span>Domicilios</span></button>
            <button type="button" data-vct-tab="telefonos"><span data-vct-icon="phone"></span><span>Teléfonos</span></button>
            <button type="button" data-vct-tab="email"><span data-vct-icon="mail"></span><span>Emails</span></button>
            <button type="button" data-vct-tab="contacto"><span data-vct-icon="contact"></span><span>Contactos</span></button>
            <button type="button" data-vct-tab="documentos"><span data-vct-icon="file-text"></span><span>Documentos</span></button>
            <button type="button" data-vct-tab="notas"><span data-vct-icon="clipboard-check"></span><span>Notas</span></button>
        </div>
';
 
    SET @OUTPARAM2 = '
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="resumen">
            <div class="vct-360-box vct-360-box-compact vct-360-recent-projects-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Últimos Proyectos</h3><button type="button" data-vct-tab-link="proyectos">Ver todos</button></div>
                    '+@HTML_PROYECTOS_TOP+'
                </div>
 
            <div class="vct-360-box vct-360-active-management-box">
                <div class="vct-360-box-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="chart-bar"></span>Gestiones de proyectos activos</h3>
                        <p class="vct-360-box-subtitle">Distribución por estado de las gestiones vinculadas a proyectos activos.</p>
                    </div>
                </div>
                '+@HTML_GESTIONES_ACTIVOS+'
            </div>
 
            <div class="vct-360-box vct-360-box-compact vct-360-recent-management-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="list-checks"></span>Últimas Gestiones</h3></div>
                    '+@HTML_GESTIONES_TOP+'
                </div>
 
            <div class="vct-360-summary-charts">
                <div class="vct-360-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Proyectos por estado</h3></div>
                    '+@HTML_ESTADOS+'
                </div>
                <div class="vct-360-box">
                    <div class="vct-360-box-head">
                        <div>
                            <h3><span class="vct-360-title-icon" data-vct-icon="chart-bar"></span>Rentabilidad - Proyectos activos</h3>
                            <p class="vct-360-box-subtitle">Monto, costos y margen acumulado de proyectos activos.</p>
                        </div>
                    </div>
                    '+@HTML_RENTABILIDAD+'
                </div>
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="domicilio">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="map-pin"></span>Domicilios ('+CONVERT(VARCHAR(10),@DomiciliosCount)+')</h3>
                    </div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_DOM,'')+
                    '</div>
                </div>'+@HTML_DOMICILIOS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="telefonos">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="phone"></span>Teléfonos ('+CONVERT(VARCHAR(10),@TelefonosCount)+')</h3>
                    </div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_TEL,'')+
                    '</div>
                </div>'+@HTML_TELEFONOS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="email">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="mail"></span>Emails ('+CONVERT(VARCHAR(10),@EmailsCount)+')</h3>
                    </div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_MAIL,'')+
                    '</div>
                </div>'+@HTML_EMAILS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="contacto">
            <div class="vct-360-box">
                <div class="vct-360-box-head vct-360-section-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="contact"></span>Contactos ('+CONVERT(VARCHAR(10),@ContactosCount)+')</h3>
                    </div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_CONT,'')+
                    '</div>
                </div>'+@HTML_CONTACTOS_TABLE+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="proyectos"><div class="vct-360-box vct-360-box-grid-auto"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Proyectos ('+CONVERT(VARCHAR(10),@ProyectosCount)+')</h3></div>'+@HTML_PROYECTOS+'</div></div>
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="documentos"><div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="file-text"></span>Documentos ('+CONVERT(VARCHAR(10),@DocumentosCount)+')</h3></div><div class="vct-360-empty">Sin información todavía.</div></div></div>
        <div class="vct-360-panel vct-consultor360-panel" data-vct-entity-theme="cliente" data-vct-panel="notas"><div class="vct-360-box"><div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="clipboard-check"></span>Notas ('+CONVERT(VARCHAR(10),@NotasCount)+')</h3></div><div class="vct-360-empty">Sin información todavía.</div></div></div>
    </div>
</section>
</div>';
 
        /* ============================================================
       14B. ALTA DE PROYECTO - MODAL (ALTA_PROYECTO_V1)
       ------------------------------------------------------------
       Se abre desde el menu del encabezado ("Nuevo Proyecto").
       Campos con el renderer generico; servicios, normas y
       rentabilidad los arma vct-proyecto-alta.js sobre esos mismos
       campos (el valor viaja en el input original):
         TEXTO22 servicios (ids,coma)  TEXTO24 normas (ids,coma)
         TEXTO25 rentabilidad (6 valores con |)  TEXTO26 comentario
       Guardado: bloque PROYECTO de 3B -> VCT_PROYECTO_ALTA_GUARDAR.
       ============================================================ */
    DECLARE @HTML_MODAL_PROY VARCHAR(MAX)='';
    DECLARE @CAN_CREATE_PROY BIT=0;
 
    SET @CAN_CREATE_PROY=ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,'PROYECTOS.CREATE'),0);
 
    IF @CAN_CREATE_PROY=1
    BEGIN
        DECLARE
            @PROY_REOPEN BIT=0,
            @P11 VARCHAR(4000)='',@P13 VARCHAR(4000)='',@P14 VARCHAR(4000)='',@P15 VARCHAR(4000)='',
            @P17 VARCHAR(4000)='',@P18 VARCHAR(4000)='',
            @P20 VARCHAR(4000)='',@P21 VARCHAR(4000)='',@P22 VARCHAR(4000)='',
            @P24 VARCHAR(4000)='',@P25 VARCHAR(4000)='',@P26 VARCHAR(4000)='',
            @PROY_NEXT_COD VARCHAR(20)='',
            @ERR_PROY VARCHAR(MAX)='',
            @PROY_SUBT VARCHAR(500)='',
            @OPT_PROY_CONT VARCHAR(MAX)='',
            @OPT_PROY_ANAL VARCHAR(MAX)='',
            @OPT_PROY_SERV VARCHAR(MAX)='',
            @OPT_PROY_NORM VARCHAR(MAX)='';
 
        SET @PROY_REOPEN=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='PROYECTO' THEN 1 ELSE 0 END;
        SET @ERR_PROY=CASE WHEN @VFORM_ENTITY='PROYECTO' THEN ISNULL(@VFORM_ERROR,'') ELSE '' END;
 
        IF @PROY_REOPEN=1
            SELECT TOP 1
                @P11=ISNULL(TEXTO11,''),@P13=ISNULL(TEXTO13,''),@P14=ISNULL(TEXTO14,''),@P15=ISNULL(TEXTO15,''),
                @P17=ISNULL(TEXTO17,''),@P18=ISNULL(TEXTO18,''),
                @P20=ISNULL(TEXTO20,''),@P21=ISNULL(TEXTO21,''),@P22=ISNULL(TEXTO22,''),
                @P24=ISNULL(TEXTO24,''),@P25=ISNULL(TEXTO25,''),@P26=ISNULL(TEXTO26,'')
            FROM dbo.VCT_BUFFER WITH(NOLOCK)
            WHERE PAR_KEY=@IPKEYJOB;
 
        /* Codigo estimado (el definitivo se asigna al grabar). */
        SELECT @PROY_NEXT_COD=CONVERT(VARCHAR(20),ISNULL(MAX(N),0)+1)
        FROM
        (
            SELECT CASE WHEN CODIGO NOT LIKE '%[^0-9]%' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT,CODIGO) END AS N
            FROM dbo.VCT_PROYECTOS WITH(NOLOCK)
        ) X;
 
        SET @PROY_SUBT='Cliente: '+REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''),'&','&amp;'),'<','&lt;'),'>','&gt;');
 
        /* ---- opciones ---- */
        SELECT @OPT_PROY_CONT=ISNULL((
            SELECT
                '<option value="'+CONVERT(VARCHAR(20),C.ID)+'">'+
                REPLACE(REPLACE(REPLACE(
                    ISNULL(NULLIF(C.NOMBRE,''),'-')+CASE WHEN ISNULL(C.CARGO,'')<>'' THEN ' - '+C.CARGO ELSE '' END,
                    '&','&amp;'),'<','&lt;'),'>','&gt;')+
                '</option>'
            FROM #CONTACTOS360 C
            ORDER BY C.APELLIDO,C.NOMBRES,C.ID
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
 
        SELECT @OPT_PROY_ANAL=ISNULL((
            SELECT
                '<option value="'+CONVERT(VARCHAR(20),E.ID)+'">'+
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'')+', '+ISNULL(E.NOMBRES,''))),'&','&amp;'),'<','&lt;'),'>','&gt;')+
                '</option>'
            FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
            WHERE ISNULL(E.ESTADO,'ACTIVO')='ACTIVO'
            ORDER BY E.APELLIDOS,E.NOMBRES
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
 
        SELECT @OPT_PROY_SERV=ISNULL((
            SELECT
                '<option value="'+CONVERT(VARCHAR(20),S.ID)+'" data-codigo="'+UPPER(ISNULL(S.CODIGO,''))+'">'+
                REPLACE(REPLACE(REPLACE(ISNULL(S.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+
                '</option>'
            FROM dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
            WHERE ISNULL(S.ESTADO,'ACTIVO')='ACTIVO'
            ORDER BY S.ID
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
 
        SELECT @OPT_PROY_NORM=ISNULL((
            SELECT
                '<option value="'+CONVERT(VARCHAR(20),N.ID)+'">'+
                REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;')+
                '</option>'
            FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
            WHERE ISNULL(N.ESTADO,'ACTIVO')='ACTIVO'
            ORDER BY N.DESCRIPCION
            FOR XML PATH(''),TYPE
        ).value('.','VARCHAR(MAX)'),'');
 
        /* ---- campos ---- */
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,'TEXTO11','Nombre del proyecto','TEXT',9,1,300,'Ej.: Implementaci&oacute;n ISO 9001:2015',NULL,NULLIF(@P11,''),0,0,NULL,NULL),
        (2,'TEXTO12','C&oacute;digo','TEXT',3,0,20,NULL,NULL,@PROY_NEXT_COD,1,0,'Se confirma al guardar.',NULL),
        (3,'TEXTO22','Servicios','TEXT',12,1,4000,NULL,NULL,NULLIF(@P22,''),0,0,NULL,NULL),
        (4,'TEXTO24','Normas','TEXT',12,1,4000,NULL,NULL,NULLIF(@P24,''),0,0,NULL,NULL),
        (5,'TEXTO13','Fecha de inicio','DATE',4,0,NULL,'Fecha de inicio',NULL,NULLIF(@P13,''),0,0,NULL,NULL),
        (6,'TEXTO14','Fecha de fin','DATE',4,0,NULL,'Fecha de fin',NULL,NULLIF(@P14,''),0,0,NULL,NULL),
        (7,'TEXTO15','Horas contratadas','NUMBER',4,0,6,'0',NULL,NULLIF(@P15,''),0,0,NULL,NULL),
        (8,'TEXTO17','Contacto del cliente','TEXT',8,0,20,NULL,NULL,NULLIF(@P17,''),0,0,NULL,NULL),
        (9,'TEXTO18','Nivel de riesgo','TEXT',4,0,20,NULL,NULL,NULLIF(@P18,''),0,0,NULL,NULL),
        (10,'TEXTO20','Analista a cargo','TEXT',6,0,20,NULL,NULL,NULLIF(@P20,''),0,0,'Recibe un mail y una gesti&oacute;n para organizar el lanzamiento.',NULL),
        (11,'TEXTO21','Fecha l&iacute;mite de lanzamiento','DATE',6,0,NULL,'Fecha l&iacute;mite',NULL,NULLIF(@P21,''),0,0,'Vencimiento de la gesti&oacute;n del analista.',NULL),
        (12,'TEXTO25','Rentabilidad estimada','TEXT',12,0,4000,NULL,NULL,NULLIF(@P25,''),0,0,NULL,NULL),
        (13,'TEXTO26','Comentario rentabilidad','HIDDEN',12,0,NULL,NULL,NULL,NULLIF(@P26,''),0,1,NULL,NULL),
        (14,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL),
        (15,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'PROYECTO',0,1,NULL,NULL),
        (16,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
        (17,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
        (18,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
        (19,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'proyectos',0,1,NULL,NULL);
 
        EXEC dbo.VCT_MAIN_RENDER_FORM
             @FORM_ID='vctModalProyecto',@TITLE='Nuevo proyecto',
             @SUBTITLE=@PROY_SUBT,@ICON='folder',
             @LAYOUT='MODAL',@SAVE_LABEL='Crear proyecto',@CANCEL_LABEL='Cancelar',
             @ERROR_MESSAGE=@ERR_PROY,
             @OPEN_ON_RENDER=@PROY_REOPEN,
             @OUTHTML=@HTML_MODAL_PROY OUTPUT;
 
        /* Fechas con el date picker propio y marca para el CSS del alta. */
        SET @HTML_MODAL_PROY=REPLACE(ISNULL(@HTML_MODAL_PROY,''),'type="date" ','type="date" data-vct-datepicker ');
        SET @HTML_MODAL_PROY=REPLACE(@HTML_MODAL_PROY,'class="vct-modal vct-form-shell ','class="vct-modal vct-form-shell vct-proy-alta ');
 
        SET @HTML_MODAL_PROY=@HTML_MODAL_PROY+
            '<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO17" data-vct-placeholder="'+CASE WHEN @OPT_PROY_CONT='' THEN 'El cliente no tiene contactos cargados' ELSE 'Seleccione un contacto' END+'">'+@OPT_PROY_CONT+'</template>'+
            '<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO18" data-vct-placeholder="Seleccione"><option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></template>'+
            '<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO20" data-vct-placeholder="Sin asignar">'+@OPT_PROY_ANAL+'</template>'+
            '<template data-vct-proy-catalog="servicios">'+@OPT_PROY_SERV+'</template>'+
            '<template data-vct-proy-catalog="normas">'+@OPT_PROY_NORM+'</template>';
    END;
 
    /* Aviso de alta OK: lo muestra vct-proyecto-alta.js como toast. */
    IF ISNULL(@PROY_ALTA_MSG,'')<>''
        SET @HTML_MODAL_PROY=ISNULL(@HTML_MODAL_PROY,'')+
            '<div hidden data-vct-proy-alta-ok="'+REPLACE(REPLACE(REPLACE(REPLACE(@PROY_ALTA_MSG,'&','&amp;'),'"','&quot;'),'<','&lt;'),'>','&gt;')+'"></div>';
 
    /* Drawers separados para que el framework pueda concatenarlos sin
       meterlos dentro del flujo visual de la página. */
    SET @OUTPARAM3 =
        ISNULL(@HTML_DRAWER_DOM,'')+
        ISNULL(@HTML_DRAWER_TEL,'')+
        ISNULL(@HTML_DRAWER_MAIL,'')+
        ISNULL(@HTML_DRAWER_CONT,'')+ISNULL(@HTML_MODAL_PROY,'');
 
 
END
