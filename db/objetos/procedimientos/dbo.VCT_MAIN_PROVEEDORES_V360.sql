 
CREATE PROCEDURE [dbo].[VCT_MAIN_PROVEEDORES_V360]
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
    SET NOCOUNT ON;
 
    SET @OUTPARAM1='';
    SET @OUTPARAM2='';
    SET @OUTPARAM3='';
 
    DECLARE @MODULE_CODE VARCHAR(50)='PROVEEDORES'; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */
 
    DECLARE
        @HTML_SHELL      VARCHAR(MAX)='',
        @RESULTADO_SHELL VARCHAR(20)='',
        @SIDEBAR_ID      INT=0,
        @CAN_VIEW        BIT=0,
        @CAN_EDIT        BIT=0,
        @BTN_BACK        VARCHAR(MAX)='';
 
    /* ============================================================
       1. SHELL GENERAL
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Vista 360 de Proveedor',
             @SUBTITLE           = 'Informacion general y datos de contacto del proveedor.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL='';
        SET @RESULTADO_SHELL='ERROR';
    END CATCH;
 
    /* ============================================================
       2. ACCIONES / PERMISOS / SIDEBAR
       ============================================================ */
    IF OBJECT_ID('tempdb..#ACCIONES') IS NOT NULL DROP TABLE #ACCIONES;
 
    SELECT *
    INTO #ACCIONES
    FROM dbo.VCT_MAIN_GET_ACTIONS(@IUNIDAD,@MODULE_CODE);
 
    SELECT TOP 1 @SIDEBAR_ID=ISNULL(SIDEBAR_ID,0)
    FROM #ACCIONES
    WHERE ISNULL(SIDEBAR_ID,0)<>0
    ORDER BY SORT_ORDER,ID_PRM;
 
    SET @CAN_VIEW=CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='VIEW') THEN 1 ELSE 0 END;
    SET @CAN_EDIT=CASE WHEN EXISTS(SELECT 1 FROM #ACCIONES WHERE ACTION_TYPE='EDIT') THEN 1 ELSE 0 END;
 
    IF @CAN_VIEW=0
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para visualizar la Vista 360 de Proveedores.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;
 
    /* ============================================================
       3. PROVEEDOR SELECCIONADO
       ============================================================ */
    DECLARE @ID_PROVEEDOR INT=0;
 
    SELECT TOP 1
        @ID_PROVEEDOR=ISNULL(IDSELEC01,0)
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    DECLARE
        @RAZON_SOCIAL        VARCHAR(300)='',
        @DESCRIPCION         VARCHAR(300)='',
        @CUIT                VARCHAR(30)='',
        @TIPO_PROVEEDOR      VARCHAR(50)='',
        @TIPO_PROVEEDOR_DESC VARCHAR(300)='',
        @CONDICION_IVA       VARCHAR(50)='',
        @CONDICION_IVA_DESC  VARCHAR(300)='',
        @ESTADO              VARCHAR(30)='',
        @OBSERVACIONES       VARCHAR(1200)='',
        @FECHA_ALTA          DATETIME=NULL,
        @USUARIO_ALTA        VARCHAR(100)='',
        @FECHA_UPD           DATETIME=NULL,
        @USUARIO_UPD         VARCHAR(100)='';
 
    SELECT TOP 1
        @RAZON_SOCIAL   =ISNULL(CONVERT(VARCHAR(300),P.RAZON_SOCIAL),''),
        @DESCRIPCION    =ISNULL(CONVERT(VARCHAR(300),P.DESCRIPCION),''),
        @CUIT           =ISNULL(CONVERT(VARCHAR(30),P.CUIT),''),
        @TIPO_PROVEEDOR =ISNULL(CONVERT(VARCHAR(50),P.TIPO_PROVEEDOR),''),
        @CONDICION_IVA  =ISNULL(CONVERT(VARCHAR(50),P.CONDICION_IVA),''),
        @ESTADO         =UPPER(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(30),P.ESTADO),'')))),
        @OBSERVACIONES  =ISNULL(CONVERT(VARCHAR(1200),P.OBSERVACIONES),''),
        @FECHA_ALTA     =P.FECHA_ALTA,
        @USUARIO_ALTA   =ISNULL(CONVERT(VARCHAR(100),P.USUARIO_ALTA),''),
        @FECHA_UPD      =P.FECHA_UPD,
        @USUARIO_UPD    =ISNULL(CONVERT(VARCHAR(100),P.USUARIO_UPD),'')
    FROM dbo.VCT_PROVEEDORES P WITH(NOLOCK)
    WHERE P.ID_PROVEEDOR=@ID_PROVEEDOR;
 
    IF NULLIF(LTRIM(RTRIM(@RAZON_SOCIAL)),'') IS NULL
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Proveedor no encontrado</h2>
            <p class="vct-card-subtitle">No se encontro el proveedor seleccionado.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;
 
    SELECT TOP 1
        @TIPO_PROVEEDOR_DESC=ISNULL(CONVERT(VARCHAR(300),CD.CAT_DATA_DESC),'')
    FROM dbo.CAT_DATA CD WITH(NOLOCK)
    WHERE CD.PAR_KEY=
    (
        SELECT TOP 1 PKEY
        FROM dbo.CAT_TYPE WITH(NOLOCK)
        WHERE CAT_TYPE_CODE='TIPO_PROVEEDOR'
    )
      AND CONVERT(VARCHAR(50),CD.CAT_DATA_CODE) COLLATE DATABASE_DEFAULT=
          @TIPO_PROVEEDOR COLLATE DATABASE_DEFAULT;
 
    SELECT TOP 1
        @CONDICION_IVA_DESC=ISNULL(CONVERT(VARCHAR(300),CD.CAT_DATA_DESC),'')
    FROM dbo.CAT_DATA CD WITH(NOLOCK)
    WHERE CD.PAR_KEY=
    (
        SELECT TOP 1 PKEY
        FROM dbo.CAT_TYPE WITH(NOLOCK)
        WHERE CAT_TYPE_CODE='CondicionIva'
    )
      AND CONVERT(VARCHAR(50),CD.CAT_DATA_CODE) COLLATE DATABASE_DEFAULT=
          @CONDICION_IVA COLLATE DATABASE_DEFAULT;
 
    IF NULLIF(LTRIM(RTRIM(@TIPO_PROVEEDOR_DESC)),'') IS NULL
        SET @TIPO_PROVEEDOR_DESC=@TIPO_PROVEEDOR;
 
    IF NULLIF(LTRIM(RTRIM(@CONDICION_IVA_DESC)),'') IS NULL
        SET @CONDICION_IVA_DESC=@CONDICION_IVA;
 
    /* ============================================================
       4. ESTADO DE FORMS / TABS
       ============================================================ */
    DECLARE
        @VFORM_SAVE       VARCHAR(10)='',
        @VFORM_DELETE     VARCHAR(10)='',
        @VFORM_PRINCIPAL  VARCHAR(10)='',
        @VFORM_FLAG02     VARCHAR(10)='0',
        @VFORM_ENTITY     VARCHAR(30)='',
        @VFORM_ROW_ID     VARCHAR(100)='',
        @VFORM_T11        VARCHAR(1000)='',
        @VFORM_T12        VARCHAR(1000)='',
        @VFORM_T13        VARCHAR(1000)='',
        @VFORM_T14        VARCHAR(1000)='',
        @VFORM_T15        VARCHAR(1000)='',
        @VFORM_T16        VARCHAR(1000)='',
        @VFORM_T17        VARCHAR(2000)='',
        @VFORM_ERROR      VARCHAR(1000)='',
        @VFORM_REOPEN     BIT=0,
        @ACTIVE_TAB       VARCHAR(50)='resumen';
 
    SELECT TOP 1
        @VFORM_SAVE=ISNULL(CONVERT(VARCHAR(10),FLAG01),''),
        @VFORM_DELETE=ISNULL(CONVERT(VARCHAR(10),FLAG03),''),
        @VFORM_PRINCIPAL=ISNULL(CONVERT(VARCHAR(10),FLAG04),''),
        @VFORM_FLAG02=ISNULL(CONVERT(VARCHAR(10),FLAG02),'0'),
        @VFORM_ENTITY=UPPER(LTRIM(RTRIM(ISNULL(TEXTO30,'')))),
        @VFORM_ROW_ID=LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(100),IDSELEC02),''))),
        @VFORM_T11=ISNULL(TEXTO11,''),
        @VFORM_T12=ISNULL(TEXTO12,''),
        @VFORM_T13=ISNULL(TEXTO13,''),
        @VFORM_T14=ISNULL(TEXTO14,''),
        @VFORM_T15=ISNULL(TEXTO15,''),
        @VFORM_T16=ISNULL(TEXTO16,''),
        @VFORM_T17=ISNULL(TEXTO17,''),
        @ACTIVE_TAB=ISNULL(NULLIF(ACTIVE_TAB,''),'resumen')
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    IF CHARINDEX(',',ISNULL(@VFORM_ENTITY,''))>0
        SET @VFORM_ENTITY=LEFT(@VFORM_ENTITY,CHARINDEX(',',@VFORM_ENTITY)-1);
 
    IF CHARINDEX(',',ISNULL(@VFORM_ROW_ID,''))>0
        SET @VFORM_ROW_ID=LEFT(@VFORM_ROW_ID,CHARINDEX(',',@VFORM_ROW_ID)-1);
 
    IF CHARINDEX(',',ISNULL(@ACTIVE_TAB,''))>0
        SET @ACTIVE_TAB=LEFT(@ACTIVE_TAB,CHARINDEX(',',@ACTIVE_TAB)-1);
 
    SET @VFORM_ENTITY=UPPER(LTRIM(RTRIM(ISNULL(@VFORM_ENTITY,''))));
    SET @VFORM_ROW_ID=LTRIM(RTRIM(ISNULL(@VFORM_ROW_ID,'')));
    SET @ACTIVE_TAB=ISNULL(NULLIF(LTRIM(RTRIM(@ACTIVE_TAB)),''),'resumen');
 
    DECLARE @V360_RESET_TAB BIT=
        CASE
            WHEN @VFORM_SAVE='1'
              OR @VFORM_DELETE='1'
              OR @VFORM_PRINCIPAL='1'
                THEN 0
            ELSE 1
        END;
 
    IF @V360_RESET_TAB=1
    BEGIN
        UPDATE dbo.VCT_BUFFER
           SET IDSELEC02=NULL,
               TEXTO11=NULL,TEXTO12=NULL,TEXTO13=NULL,TEXTO14=NULL,
               TEXTO15=NULL,TEXTO16=NULL,TEXTO17=NULL,TEXTO30=NULL,
               FLAG01=0,FLAG02=0,FLAG03=0,FLAG04=0,
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
        SET @ACTIVE_TAB='resumen';
    END;
 
    /* ============================================================
       5. TABLAS RELACIONADAS DISPONIBLES
       ============================================================ */
    DECLARE
        @DOM_OK  BIT=CASE WHEN OBJECT_ID('dbo.VCT_DOMICILIOS','U') IS NOT NULL THEN 1 ELSE 0 END,
        @TEL_OK  BIT=CASE WHEN OBJECT_ID('dbo.VCT_TELEFONOS','U') IS NOT NULL THEN 1 ELSE 0 END,
        @MAIL_OK BIT=CASE WHEN OBJECT_ID('dbo.VCT_EMAILS','U') IS NOT NULL THEN 1 ELSE 0 END,
        @RC      INT=0,
        @NEXISTS INT=0,
        @EXEC_PRINCIPAL VARCHAR(2)='NO';
 
    /* ============================================================
       6. ELIMINAR RELACIONADOS
       ============================================================ */
    IF @VFORM_DELETE='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para eliminar datos del proveedor.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibio el registro a eliminar.';
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_OK=0
                SET @VFORM_ERROR='La tabla VCT_DOMICILIOS no se encuentra disponible.';
            ELSE
            BEGIN
                DELETE FROM dbo.VCT_DOMICILIOS
                WHERE TIPO_ENTIDAD='PROVEEDOR'
                  AND ID_ENTIDAD=@ID_PROVEEDOR
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='TELEFONO'
        BEGIN
            SET @ACTIVE_TAB='telefonos';
 
            IF @TEL_OK=0
                SET @VFORM_ERROR='La tabla VCT_TELEFONOS no se encuentra disponible.';
            ELSE
            BEGIN
                DELETE FROM dbo.VCT_TELEFONOS
                WHERE TIPO_ENTIDAD='PROVEEDOR'
                  AND ID_ENTIDAD=@ID_PROVEEDOR
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El telefono seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL'
        BEGIN
            SET @ACTIVE_TAB='email';
 
            IF @MAIL_OK=0
                SET @VFORM_ERROR='La tabla VCT_EMAILS no se encuentra disponible.';
            ELSE
            BEGIN
                DELETE FROM dbo.VCT_EMAILS
                WHERE TIPO_ENTIDAD='PROVEEDOR'
                  AND ID_ENTIDAD=@ID_PROVEEDOR
                  AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;
 
        UPDATE dbo.VCT_BUFFER
           SET FLAG03=0,
               ACTIVE_TAB=@ACTIVE_TAB
         WHERE PAR_KEY=@IPKEYJOB;
    END;
 
    /* ============================================================
       7. MARCAR PRINCIPAL
       ============================================================ */
    IF @VFORM_PRINCIPAL='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para modificar datos del proveedor.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibio el registro a marcar como principal.';
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_OK=0
                SET @VFORM_ERROR='La tabla VCT_DOMICILIOS no se encuentra disponible.';
            ELSE
            BEGIN
                UPDATE dbo.VCT_DOMICILIOS
                   SET PRINCIPAL='NO'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR;
 
                UPDATE dbo.VCT_DOMICILIOS
                   SET PRINCIPAL='SI'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR
                   AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='TELEFONO'
        BEGIN
            SET @ACTIVE_TAB='telefonos';
 
            IF @TEL_OK=0
                SET @VFORM_ERROR='La tabla VCT_TELEFONOS no se encuentra disponible.';
            ELSE
            BEGIN
                UPDATE dbo.VCT_TELEFONOS
                   SET PRINCIPAL='NO'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR;
 
                UPDATE dbo.VCT_TELEFONOS
                   SET PRINCIPAL='SI'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR
                   AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El telefono seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL'
        BEGIN
            SET @ACTIVE_TAB='email';
 
            IF @MAIL_OK=0
                SET @VFORM_ERROR='La tabla VCT_EMAILS no se encuentra disponible.';
            ELSE
            BEGIN
                UPDATE dbo.VCT_EMAILS
                   SET PRINCIPAL='NO'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR;
 
                UPDATE dbo.VCT_EMAILS
                   SET PRINCIPAL='SI'
                 WHERE TIPO_ENTIDAD='PROVEEDOR'
                   AND ID_ENTIDAD=@ID_PROVEEDOR
                   AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                IF @@ROWCOUNT=0
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al proveedor.';
            END;
        END;
 
        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;
 
        UPDATE dbo.VCT_BUFFER
           SET FLAG04=0,
               ACTIVE_TAB=@ACTIVE_TAB
         WHERE PAR_KEY=@IPKEYJOB;
    END;
 
    /* ============================================================
       8. GUARDAR / EDITAR RELACIONADOS
       ============================================================ */
    IF @VFORM_SAVE='1'
    BEGIN
        SET @VFORM_ERROR='';
        SET @EXEC_PRINCIPAL=CASE WHEN @VFORM_FLAG02='1' THEN 'SI' ELSE 'NO' END;
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para modificar datos del proveedor.';
 
        /* ---------------- DOMICILIO ---------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_OK=0
                SET @VFORM_ERROR='La tabla VCT_DOMICILIOS no se encuentra disponible.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='La calle es obligatoria.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El numero es obligatorio.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T15)),'') IS NULL
                SET @VFORM_ERROR='La localidad es obligatoria.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T16)),'') IS NULL
                SET @VFORM_ERROR='La provincia es obligatoria.';
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.CAT_DATA CD WITH(NOLOCK)
                WHERE CD.PAR_KEY=
                (
                    SELECT TOP 1 PKEY
                    FROM dbo.CAT_TYPE WITH(NOLOCK)
                    WHERE CAT_TYPE_CODE='Provincia'
                )
                  AND CONVERT(VARCHAR(100),CD.CAT_DATA_CODE) COLLATE DATABASE_DEFAULT=
                      LTRIM(RTRIM(@VFORM_T16)) COLLATE DATABASE_DEFAULT
            )
                SET @VFORM_ERROR='La provincia seleccionada no es valida.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    UPDATE dbo.VCT_DOMICILIOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    INSERT INTO dbo.VCT_DOMICILIOS
                    (
                        TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,
                        LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES
                    )
                    VALUES
                    (
                        'PROVEEDOR',@ID_PROVEEDOR,
                        LTRIM(RTRIM(@VFORM_T11)),
                        LTRIM(RTRIM(@VFORM_T12)),
                        NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                        NULLIF(LTRIM(RTRIM(@VFORM_T14)),''),
                        LTRIM(RTRIM(@VFORM_T15)),
                        LTRIM(RTRIM(@VFORM_T16)),
                        @EXEC_PRINCIPAL,
                        NULLIF(LTRIM(RTRIM(@VFORM_T17)),'')
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_DOMICILIOS
                       SET CALLE=LTRIM(RTRIM(@VFORM_T11)),
                           NRO=LTRIM(RTRIM(@VFORM_T12)),
                           PISO=NULLIF(LTRIM(RTRIM(@VFORM_T13)),''),
                           DEPTO=NULLIF(LTRIM(RTRIM(@VFORM_T14)),''),
                           LOCALIDAD=LTRIM(RTRIM(@VFORM_T15)),
                           PROVINCIA=LTRIM(RTRIM(@VFORM_T16)),
                           PRINCIPAL=@EXEC_PRINCIPAL,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T17)),'')
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El domicilio a editar ya no existe o no pertenece al proveedor.';
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
 
            IF @TEL_OK=0
                SET @VFORM_ERROR='La tabla VCT_TELEFONOS no se encuentra disponible.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El codigo de area es obligatorio.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El numero es obligatorio.';
            ELSE IF LTRIM(RTRIM(@VFORM_T11)) LIKE '%[^0-9]%'
                 OR LEN(LTRIM(RTRIM(@VFORM_T11)))>4
                SET @VFORM_ERROR='El codigo de area debe ser numerico y no puede superar 4 digitos.';
            ELSE IF LTRIM(RTRIM(@VFORM_T12)) LIKE '%[^0-9]%'
                 OR LEN(LTRIM(RTRIM(@VFORM_T12)))>8
                SET @VFORM_ERROR='El numero debe ser numerico y no puede superar 8 digitos.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    UPDATE dbo.VCT_TELEFONOS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    INSERT INTO dbo.VCT_TELEFONOS
                    (
                        TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES
                    )
                    VALUES
                    (
                        'PROVEEDOR',@ID_PROVEEDOR,
                        CONVERT(NUMERIC(4,0),LTRIM(RTRIM(@VFORM_T11))),
                        CONVERT(NUMERIC(8,0),LTRIM(RTRIM(@VFORM_T12))),
                        @EXEC_PRINCIPAL,
                        NULLIF(LTRIM(RTRIM(@VFORM_T13)),'')
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_TELEFONOS
                       SET CODAREA=CONVERT(NUMERIC(4,0),LTRIM(RTRIM(@VFORM_T11))),
                           NRO=CONVERT(NUMERIC(8,0),LTRIM(RTRIM(@VFORM_T12))),
                           PRINCIPAL=@EXEC_PRINCIPAL,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T13)),'')
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El telefono a editar ya no existe o no pertenece al proveedor.';
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
 
            IF @MAIL_OK=0
                SET @VFORM_ERROR='La tabla VCT_EMAILS no se encuentra disponible.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El email es obligatorio.';
            ELSE IF LTRIM(RTRIM(@VFORM_T11)) NOT LIKE '%_@_%._%'
                SET @VFORM_ERROR='El email no tiene un formato valido.';
 
            IF @VFORM_ERROR=''
            BEGIN
                SELECT @NEXISTS=COUNT(*)
                FROM dbo.VCT_EMAILS WITH(NOLOCK)
                WHERE TIPO_ENTIDAD='PROVEEDOR'
                  AND ID_ENTIDAD=@ID_PROVEEDOR
                  AND LOWER(LTRIM(RTRIM(ISNULL(EMAIL,''))))=
                      LOWER(LTRIM(RTRIM(@VFORM_T11)))
                  AND (@VFORM_ROW_ID='' OR CONVERT(VARCHAR(100),ID)<>@VFORM_ROW_ID);
 
                IF @NEXISTS>0
                    SET @VFORM_ERROR='El proveedor ya posee ese email registrado.';
            END;
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    UPDATE dbo.VCT_EMAILS
                       SET PRINCIPAL='NO'
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    INSERT INTO dbo.VCT_EMAILS
                    (
                        TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES
                    )
                    VALUES
                    (
                        'PROVEEDOR',@ID_PROVEEDOR,
                        LOWER(LTRIM(RTRIM(@VFORM_T11))),
                        @EXEC_PRINCIPAL,
                        NULLIF(LTRIM(RTRIM(@VFORM_T12)),'')
                    );
                END
                ELSE
                BEGIN
                    UPDATE dbo.VCT_EMAILS
                       SET EMAIL=LOWER(LTRIM(RTRIM(@VFORM_T11))),
                           PRINCIPAL=@EXEC_PRINCIPAL,
                           OBSERVACIONES=NULLIF(LTRIM(RTRIM(@VFORM_T12)),'')
                     WHERE TIPO_ENTIDAD='PROVEEDOR'
                       AND ID_ENTIDAD=@ID_PROVEEDOR
                       AND CONVERT(VARCHAR(100),ID)=@VFORM_ROW_ID;
 
                    IF @@ROWCOUNT=0
                        SET @VFORM_ERROR='El email a editar ya no existe o no pertenece al proveedor.';
                END;
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=ERROR_MESSAGE();
            END CATCH;
        END;
 
        SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'' THEN 1 ELSE 0 END;
 
        IF @VFORM_ERROR<>''
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET FLAG01=0,FLAG03=0,FLAG04=0,ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END
        ELSE
        BEGIN
            UPDATE dbo.VCT_BUFFER
               SET IDSELEC02=NULL,
                   TEXTO11=NULL,TEXTO12=NULL,TEXTO13=NULL,TEXTO14=NULL,
                   TEXTO15=NULL,TEXTO16=NULL,TEXTO17=NULL,TEXTO30=NULL,
                   FLAG01=0,FLAG02=0,FLAG03=0,FLAG04=0,
                   ACTIVE_TAB=@ACTIVE_TAB
             WHERE PAR_KEY=@IPKEYJOB;
        END;
    END;
 
    /* ============================================================
       9. NORMALIZACION DE DOMICILIOS / TELEFONOS / EMAILS
       ============================================================ */
    IF OBJECT_ID('tempdb..#DOMICILIOS360') IS NOT NULL DROP TABLE #DOMICILIOS360;
    CREATE TABLE #DOMICILIOS360
    (
        ID INT,
        CALLE VARCHAR(300),
        NRO VARCHAR(50),
        PISO VARCHAR(50),
        DEPTO VARCHAR(50),
        LOCALIDAD VARCHAR(150),
        PROVINCIA VARCHAR(150),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1200)
    );
 
    IF @DOM_OK=1
    BEGIN
        INSERT INTO #DOMICILIOS360
        (ID,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES)
        SELECT
            ID,
            ISNULL(CONVERT(VARCHAR(300),CALLE),''),
            ISNULL(CONVERT(VARCHAR(50),NRO),''),
            ISNULL(CONVERT(VARCHAR(50),PISO),''),
            ISNULL(CONVERT(VARCHAR(50),DEPTO),''),
            ISNULL(CONVERT(VARCHAR(150),LOCALIDAD),''),
            ISNULL(CONVERT(VARCHAR(150),PROVINCIA),''),
            ISNULL(CONVERT(VARCHAR(10),PRINCIPAL),'NO'),
            ISNULL(CONVERT(VARCHAR(1200),OBSERVACIONES),'')
        FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='PROVEEDOR'
          AND ID_ENTIDAD=@ID_PROVEEDOR;
    END;
 
    IF OBJECT_ID('tempdb..#TELEFONOS360') IS NOT NULL DROP TABLE #TELEFONOS360;
    CREATE TABLE #TELEFONOS360
    (
        ID INT,
        CODAREA VARCHAR(30),
        NRO VARCHAR(50),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1200)
    );
 
    IF @TEL_OK=1
    BEGIN
        INSERT INTO #TELEFONOS360
        (ID,CODAREA,NRO,PRINCIPAL,OBSERVACIONES)
        SELECT
            ID,
            ISNULL(CONVERT(VARCHAR(30),CODAREA),''),
            ISNULL(CONVERT(VARCHAR(50),NRO),''),
            ISNULL(CONVERT(VARCHAR(10),PRINCIPAL),'NO'),
            ISNULL(CONVERT(VARCHAR(1200),OBSERVACIONES),'')
        FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='PROVEEDOR'
          AND ID_ENTIDAD=@ID_PROVEEDOR;
    END;
 
    IF OBJECT_ID('tempdb..#EMAILS360') IS NOT NULL DROP TABLE #EMAILS360;
    CREATE TABLE #EMAILS360
    (
        ID INT,
        EMAIL VARCHAR(300),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1200)
    );
 
    IF @MAIL_OK=1
    BEGIN
        INSERT INTO #EMAILS360
        (ID,EMAIL,PRINCIPAL,OBSERVACIONES)
        SELECT
            ID,
            ISNULL(CONVERT(VARCHAR(300),EMAIL),''),
            ISNULL(CONVERT(VARCHAR(10),PRINCIPAL),'NO'),
            ISNULL(CONVERT(VARCHAR(1200),OBSERVACIONES),'')
        FROM dbo.VCT_EMAILS WITH(NOLOCK)
        WHERE TIPO_ENTIDAD='PROVEEDOR'
          AND ID_ENTIDAD=@ID_PROVEEDOR;
    END;
 
    /* ============================================================
       10. KPIS Y CONTACTO PRINCIPAL
       ============================================================ */
    DECLARE
        @DomiciliosCount INT=0,
        @TelefonosCount INT=0,
        @EmailsCount INT=0,
        @TelefonosPendientes INT=0,
        @PrincipalCount INT=0,
        @PrincipalDomicilio VARCHAR(1000)='-',
        @PrincipalTelefono VARCHAR(300)='-',
        @PrincipalEmail VARCHAR(300)='-';
 
    SELECT @DomiciliosCount=COUNT(*) FROM #DOMICILIOS360;
    SELECT @TelefonosCount=COUNT(*) FROM #TELEFONOS360;
    SELECT @EmailsCount=COUNT(*) FROM #EMAILS360;
    SELECT @TelefonosPendientes=COUNT(*)
    FROM #TELEFONOS360
    WHERE ISNULL(CODAREA,'')='0'
      AND ISNULL(NRO,'')='0';
 
    SET @PrincipalCount=
        CASE WHEN EXISTS(SELECT 1 FROM #DOMICILIOS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI') THEN 1 ELSE 0 END+
        CASE WHEN EXISTS(SELECT 1 FROM #TELEFONOS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI' AND NOT (ISNULL(CODAREA,'')='0' AND ISNULL(NRO,'')='0')) THEN 1 ELSE 0 END+
        CASE WHEN EXISTS(SELECT 1 FROM #EMAILS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI') THEN 1 ELSE 0 END;
 
    SELECT TOP 1
        @PrincipalDomicilio=
            LTRIM(RTRIM(
                ISNULL(CALLE,'')+
                CASE WHEN ISNULL(NRO,'')<>'' THEN ' '+NRO ELSE '' END+
                CASE WHEN ISNULL(PISO,'')<>'' THEN ' - Piso '+PISO ELSE '' END+
                CASE WHEN ISNULL(DEPTO,'')<>'' THEN ' '+DEPTO ELSE '' END+
                CASE WHEN ISNULL(LOCALIDAD,'')<>'' THEN ', '+LOCALIDAD ELSE '' END+
                CASE WHEN ISNULL(PROVINCIA,'')<>'' THEN ', '+PROVINCIA ELSE '' END
            ))
    FROM #DOMICILIOS360
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    SELECT TOP 1
        @PrincipalTelefono=
            CASE
                WHEN ISNULL(CODAREA,'')='0' AND ISNULL(NRO,'')='0'
                    THEN 'Pendiente de normalizar'
                WHEN NULLIF(ISNULL(CODAREA,''),'') IS NULL OR CODAREA='0'
                    THEN ISNULL(NULLIF(NRO,''),'-')
                ELSE '('+CODAREA+') '+ISNULL(NULLIF(NRO,''),'-')
            END
    FROM #TELEFONOS360
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    SELECT TOP 1
        @PrincipalEmail=ISNULL(NULLIF(EMAIL,''),'-')
    FROM #EMAILS360
    ORDER BY CASE WHEN UPPER(ISNULL(PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,ID;
 
    IF NULLIF(LTRIM(RTRIM(@PrincipalDomicilio)),'') IS NULL SET @PrincipalDomicilio='-';
    IF NULLIF(LTRIM(RTRIM(@PrincipalTelefono)),'') IS NULL SET @PrincipalTelefono='-';
    IF NULLIF(LTRIM(RTRIM(@PrincipalEmail)),'') IS NULL SET @PrincipalEmail='-';
 
    /* ============================================================
       11. FOOTER GENERICO DE GRILLA
       ============================================================ */
    DECLARE @HTML_GRID_FOOTER VARCHAR(MAX)=
        '<div class="vct-grid-footer">'+
            '<div class="vct-grid-footer-info" data-vct-grid-info></div>'+
            '<div class="vct-pagination" data-vct-grid-pagination></div>'+
            '<div class="vct-grid-page-size">'+
                '<span>Registros por pagina:</span>'+
                '<select class="vct-select vct-select-sm" data-vct-grid-page-size>'+
                    '<option value="10" selected="selected">10</option>'+
                    '<option value="20">20</option>'+
                    '<option value="50">50</option>'+
                    '<option value="100">100</option>'+
                '</select>'+
            '</div>'+
        '</div>';
 
    /* ============================================================
       12. HTML DOMICILIOS / TELEFONOS / EMAILS
       ============================================================ */
    DECLARE
        @HTML_DOMICILIOS VARCHAR(MAX)='',
        @HTML_TELEFONOS VARCHAR(MAX)='',
        @HTML_EMAILS VARCHAR(MAX)='';
 
    SELECT @HTML_DOMICILIOS=ISNULL((
        SELECT
            '<tr data-vct-row '+
            'data-vct-id="'+CONVERT(VARCHAR(100),D.ID)+'" '+
            'data-vct-calle="'+REPLACE(REPLACE(ISNULL(D.CALLE,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-nro="'+REPLACE(REPLACE(ISNULL(D.NRO,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-piso="'+REPLACE(REPLACE(ISNULL(D.PISO,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-depto="'+REPLACE(REPLACE(ISNULL(D.DEPTO,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-localidad="'+REPLACE(REPLACE(ISNULL(D.LOCALIDAD,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-provincia="'+REPLACE(REPLACE(ISNULL(D.PROVINCIA,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-principal="'+CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END+'" '+
            'data-vct-observaciones="'+REPLACE(REPLACE(ISNULL(D.OBSERVACIONES,''),'"','&quot;'),'''','&#39;')+'">'+
            '<td data-label="Direccion">'+
                REPLACE(REPLACE(REPLACE(
                    LTRIM(RTRIM(ISNULL(D.CALLE,'')+
                    CASE WHEN ISNULL(D.NRO,'')<>'' THEN ' '+D.NRO ELSE '' END)),
                    '&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-text-center" data-label="Piso / Depto">'+
                CASE
                    WHEN NULLIF(LTRIM(RTRIM(ISNULL(D.PISO,'')+ISNULL(D.DEPTO,''))),'') IS NULL THEN '-'
                    ELSE REPLACE(REPLACE(REPLACE(
                        LTRIM(RTRIM(ISNULL(D.PISO,'')+
                        CASE WHEN ISNULL(D.DEPTO,'')<>'' THEN ' '+D.DEPTO ELSE '' END)),
                        '&','&amp;'),'<','&lt;'),'>','&gt;')
                END+
            '</td>'+
            '<td data-label="Localidad">'+REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(D.LOCALIDAD,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td data-label="Provincia">'+REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(D.PROVINCIA,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+
                REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(D.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @DOM_OK=1
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerProveedorDomicilio" '+
                          'data-vct-entity="DOMICILIO" data-vct-tab="domicilio" '+
                          'data-vct-form-title="Editar domicilio" '+
                          'data-vct-form-subtitle="Modifique los datos de la direccion." '+
                          'data-vct-form-icon="map-pin" aria-label="Acciones">'+
                          '<span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                     ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #DOMICILIOS360 D
        ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,D.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @DOM_OK=0
        SET @HTML_DOMICILIOS='<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_DOMICILIOS no se encuentra disponible.</div>';
    ELSE IF @HTML_DOMICILIOS=''
        SET @HTML_DOMICILIOS='<div class="vct-360-empty vct-360-fixed-empty">Sin domicilios registrados.</div>';
    ELSE
        SET @HTML_DOMICILIOS=
            '<div data-vct-dg data-vct-dg-id="v360_prov_dom" data-vct-dg-title="Domicilios del proveedor" data-vct-dg-subtitle="Proveedor: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Direccion</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_DOMICILIOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_TELEFONOS=ISNULL((
        SELECT
            '<tr data-vct-row '+
            'data-vct-id="'+CONVERT(VARCHAR(100),T.ID)+'" '+
            'data-vct-codarea="'+REPLACE(REPLACE(ISNULL(T.CODAREA,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-nro="'+REPLACE(REPLACE(ISNULL(T.NRO,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-principal="'+CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END+'" '+
            'data-vct-observaciones="'+REPLACE(REPLACE(ISNULL(T.OBSERVACIONES,''),'"','&quot;'),'''','&#39;')+'">'+
            '<td class="vct-text-center" data-label="Codigo area">'+ISNULL(NULLIF(T.CODAREA,''),'-')+'</td>'+
            '<td data-label="Numero">'+ISNULL(NULLIF(T.NRO,''),'-')+'</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+
                CASE WHEN ISNULL(T.CODAREA,'')='0' AND ISNULL(T.NRO,'')='0'
                     THEN '<span class="vct-360-badge is-planned">Pendiente</span> '+
                          REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(T.OBSERVACIONES,''),'Dato historico pendiente de normalizar'),'&','&amp;'),'<','&lt;'),'>','&gt;')
                     ELSE REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(T.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')
                END+
            '</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @TEL_OK=1
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerProveedorTelefono" '+
                          'data-vct-entity="TELEFONO" data-vct-tab="telefonos" '+
                          'data-vct-form-title="Editar telefono" '+
                          'data-vct-form-subtitle="Modifique el telefono seleccionado." '+
                          'data-vct-form-icon="phone" aria-label="Acciones">'+
                          '<span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                     ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #TELEFONOS360 T
        ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,T.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @TEL_OK=0
        SET @HTML_TELEFONOS='<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_TELEFONOS no se encuentra disponible.</div>';
    ELSE IF @HTML_TELEFONOS=''
        SET @HTML_TELEFONOS='<div class="vct-360-empty vct-360-fixed-empty">Sin telefonos registrados.</div>';
    ELSE
        SET @HTML_TELEFONOS=
            '<div data-vct-dg data-vct-dg-id="v360_prov_tel" data-vct-dg-title="Telefonos del proveedor" data-vct-dg-subtitle="Proveedor: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Codigo area</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Numero</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_TELEFONOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_EMAILS=ISNULL((
        SELECT
            '<tr data-vct-row '+
            'data-vct-id="'+CONVERT(VARCHAR(100),E.ID)+'" '+
            'data-vct-email="'+REPLACE(REPLACE(ISNULL(E.EMAIL,''),'"','&quot;'),'''','&#39;')+'" '+
            'data-vct-principal="'+CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI' THEN '1' ELSE '0' END+'" '+
            'data-vct-observaciones="'+REPLACE(REPLACE(ISNULL(E.OBSERVACIONES,''),'"','&quot;'),'''','&#39;')+'">'+
            '<td data-label="Email">'+REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(E.EMAIL,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(E.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @MAIL_OK=1
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerProveedorEmail" '+
                          'data-vct-entity="EMAIL" data-vct-tab="email" '+
                          'data-vct-form-title="Editar email" '+
                          'data-vct-form-subtitle="Modifique el email seleccionado." '+
                          'data-vct-form-icon="mail" aria-label="Acciones">'+
                          '<span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                     ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #EMAILS360 E
        ORDER BY CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,E.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @MAIL_OK=0
        SET @HTML_EMAILS='<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_EMAILS no se encuentra disponible.</div>';
    ELSE IF @HTML_EMAILS=''
        SET @HTML_EMAILS='<div class="vct-360-empty vct-360-fixed-empty">Sin emails registrados.</div>';
    ELSE
        SET @HTML_EMAILS=
            '<div data-vct-dg data-vct-dg-id="v360_prov_mail" data-vct-dg-title="Emails del proveedor" data-vct-dg-subtitle="Proveedor: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_EMAILS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       13. FORM ACTIONS / DRAWERS
       ============================================================ */
    DECLARE
        @BTN_ADD_DOM VARCHAR(MAX)='',
        @BTN_ADD_TEL VARCHAR(MAX)='',
        @BTN_ADD_MAIL VARCHAR(MAX)='',
        @HTML_DRAWER_DOM VARCHAR(MAX)='',
        @HTML_DRAWER_TEL VARCHAR(MAX)='',
        @HTML_DRAWER_MAIL VARCHAR(MAX)='';
 
    IF @CAN_EDIT=1 AND @DOM_OK=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerProveedorDomicilio',
             @FORM_TITLE='Nuevo domicilio',
             @FORM_SUBTITLE='Agregue una direccion para el proveedor.',
             @FORM_ICON='map-pin',
             @BUTTON_TEXT='Agregar',
             @BUTTON_ICON='map-pin',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar domicilio',
             @OUTHTML=@BTN_ADD_DOM OUTPUT;
    END;
 
    IF @CAN_EDIT=1 AND @TEL_OK=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerProveedorTelefono',
             @FORM_TITLE='Nuevo telefono',
             @FORM_SUBTITLE='Agregue un telefono para el proveedor.',
             @FORM_ICON='phone',
             @BUTTON_TEXT='Agregar',
             @BUTTON_ICON='phone',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar telefono',
             @OUTHTML=@BTN_ADD_TEL OUTPUT;
    END;
 
    IF @CAN_EDIT=1 AND @MAIL_OK=1
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerProveedorEmail',
             @FORM_TITLE='Nuevo email',
             @FORM_SUBTITLE='Agregue un email para el proveedor.',
             @FORM_ICON='mail',
             @BUTTON_TEXT='Agregar',
             @BUTTON_ICON='mail',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar email',
             @OUTHTML=@BTN_ADD_MAIL OUTPUT;
    END;
 
    IF OBJECT_ID('tempdb..#VCT_FORM_FIELDS') IS NOT NULL DROP TABLE #VCT_FORM_FIELDS;
    CREATE TABLE #VCT_FORM_FIELDS
    (
        ORDEN INT,
        FIELD_NAME VARCHAR(50),
        LABEL VARCHAR(150),
        FIELD_TYPE VARCHAR(20),
        COL_SPAN INT,
        REQUIRED BIT,
        MAX_LENGTH INT,
        PLACEHOLDER VARCHAR(250),
        OPTIONS_SOURCE VARCHAR(100),
        DEFAULT_VALUE VARCHAR(MAX),
        READONLY BIT,
        HIDDEN BIT,
        HELP_TEXT VARCHAR(500),
        SOURCE_FIELD VARCHAR(100)
    );
 
    DECLARE
        @ERR_DOM VARCHAR(MAX)='',
        @ERR_TEL VARCHAR(MAX)='',
        @ERR_MAIL VARCHAR(MAX)='',
        @OPEN_DOM BIT=0,
        @OPEN_TEL BIT=0,
        @OPEN_MAIL BIT=0;
 
    SET @ERR_DOM=CASE WHEN @VFORM_ENTITY='DOMICILIO' THEN @VFORM_ERROR ELSE '' END;
    SET @ERR_TEL=CASE WHEN @VFORM_ENTITY='TELEFONO' THEN @VFORM_ERROR ELSE '' END;
    SET @ERR_MAIL=CASE WHEN @VFORM_ENTITY='EMAIL' THEN @VFORM_ERROR ELSE '' END;
 
    SET @OPEN_DOM=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='DOMICILIO' THEN 1 ELSE 0 END;
    SET @OPEN_TEL=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='TELEFONO' THEN 1 ELSE 0 END;
    SET @OPEN_MAIL=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY='EMAIL' THEN 1 ELSE 0 END;
 
    /* Domicilio */
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Calle / Avenida','TEXT',12,1,300,'Ingrese calle o avenida',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'calle'),
    (2,'TEXTO12','Numero','TEXT',4,1,30,'Numero',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'nro'),
    (3,'TEXTO13','Piso','TEXT',4,0,50,'Piso',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T13 ELSE NULL END,0,0,NULL,'piso'),
    (4,'TEXTO14','Depto','TEXT',4,0,50,'Depto',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T14 ELSE NULL END,0,0,NULL,'depto'),
    (5,'TEXTO15','Localidad','TEXT',6,1,100,'Localidad',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T15 ELSE NULL END,0,0,NULL,'localidad'),
    (6,'TEXTO16','Provincia','TEXT',6,1,100,'Provincia',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T16 ELSE NULL END,0,0,NULL,'provincia'),
    (7,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (8,'TEXTO17','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_T17 ELSE NULL END,0,0,NULL,'observaciones'),
    (9,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_DOM=1 THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (10,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'DOMICILIO',0,1,NULL,NULL),
    (11,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (12,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (13,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (14,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'domicilio',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerProveedorDomicilio',
         @TITLE='Domicilio',
         @SUBTITLE='Datos de direccion del proveedor.',
         @ICON='map-pin',
         @LAYOUT='DRAWER',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_DOM,
         @OPEN_ON_RENDER=@OPEN_DOM,
         @OUTHTML=@HTML_DRAWER_DOM OUTPUT;
 
    DECLARE @HTML_PROVINCIAS VARCHAR(MAX)='';
 
    SELECT @HTML_PROVINCIAS=ISNULL((
        SELECT
            '<option value="'+
            REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(100),CD.CAT_DATA_CODE),''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
            '">'+
            REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(300),CD.CAT_DATA_DESC),''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
            '</option>'
        FROM dbo.CAT_DATA CD WITH(NOLOCK)
        WHERE CD.PAR_KEY=
        (
            SELECT TOP 1 PKEY
            FROM dbo.CAT_TYPE WITH(NOLOCK)
            WHERE CAT_TYPE_CODE='Provincia'
        )
        ORDER BY CD.CAT_DATA_CODE
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    SET @HTML_DRAWER_DOM=ISNULL(@HTML_DRAWER_DOM,'')+
        '<template data-vct-field-options '+
        'data-vct-target="vctDrawerProveedorDomicilio" '+
        'data-vct-field="TEXTO16" data-vct-placeholder="Seleccione una provincia">'+
        ISNULL(@HTML_PROVINCIAS,'')+
        '</template>';
 
    /* Telefono */
    DELETE FROM #VCT_FORM_FIELDS;
 
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Codigo de area','TEXT',6,1,4,'Codigo de area',NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_T11 ELSE NULL END,0,0,'Solo numeros. Maximo 4 digitos.','codarea'),
    (2,'TEXTO12','Numero','TEXT',6,1,8,'Numero',NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_T12 ELSE NULL END,0,0,'Solo numeros. Maximo 8 digitos.','nro'),
    (3,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (4,'TEXTO13','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_T13 ELSE NULL END,0,0,NULL,'observaciones'),
    (5,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (6,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'TELEFONO',0,1,NULL,NULL),
    (7,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (8,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (10,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'telefonos',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerProveedorTelefono',
         @TITLE='Telefono',
         @SUBTITLE='Numero de contacto del proveedor.',
         @ICON='phone',
         @LAYOUT='DRAWER',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_TEL,
         @OPEN_ON_RENDER=@OPEN_TEL,
         @OUTHTML=@HTML_DRAWER_TEL OUTPUT;
 
    /* Email */
    DELETE FROM #VCT_FORM_FIELDS;
 
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Email','EMAIL',12,1,300,'email@dominio.com',NULL,
        CASE WHEN @OPEN_MAIL=1 THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'email'),
    (2,'FLAG02','Principal','TOGGLE',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_MAIL=1 THEN @VFORM_FLAG02 ELSE '0' END,0,0,NULL,'principal'),
    (3,'TEXTO12','Observaciones','TEXTAREA',12,0,1000,'Observaciones',NULL,
        CASE WHEN @OPEN_MAIL=1 THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'observaciones'),
    (4,'IDSELEC02','ID','HIDDEN',12,0,NULL,NULL,NULL,
        CASE WHEN @OPEN_MAIL=1 THEN @VFORM_ROW_ID ELSE NULL END,0,1,NULL,'id'),
    (5,'TEXTO30','Entidad','HIDDEN',12,0,NULL,NULL,NULL,'EMAIL',0,1,NULL,NULL),
    (6,'FLAG01','Guardar','HIDDEN',12,0,NULL,NULL,NULL,'1',0,1,NULL,NULL),
    (7,'FLAG03','Eliminar','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (8,'FLAG04','PrincipalCmd','HIDDEN',12,0,NULL,NULL,NULL,'0',0,1,NULL,NULL),
    (9,'ACTIVE_TAB','Tab','HIDDEN',12,0,NULL,NULL,NULL,'email',0,1,NULL,NULL);
 
    EXEC dbo.VCT_MAIN_RENDER_FORM
         @FORM_ID='vctDrawerProveedorEmail',
         @TITLE='Email',
         @SUBTITLE='Correo electronico del proveedor.',
         @ICON='mail',
         @LAYOUT='DRAWER',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_MAIL,
         @OPEN_ON_RENDER=@OPEN_MAIL,
         @OUTHTML=@HTML_DRAWER_MAIL OUTPUT;
 
    /* ============================================================
       14. HEADER / BREADCRUMB / FICHA
       ============================================================ */
    DECLARE
        @INICIALES VARCHAR(4)='--',
        @H_RAZON VARCHAR(700)='',
        @H_DESC VARCHAR(700)='',
        @H_CUIT VARCHAR(100)='',
        @H_TIPO VARCHAR(700)='',
        @H_IVA VARCHAR(700)='',
        @H_OBS VARCHAR(2500)='',
        @ALTA_TXT VARCHAR(30)='-',
        @UPD_TXT VARCHAR(30)='-',
        @ESTADO_BADGE_CLASE VARCHAR(20)='is-neutral',
        @ESTADO_BADGE_TEXTO VARCHAR(50)='SIN ESTADO';
 
    SET @INICIALES=UPPER(LEFT(LTRIM(RTRIM(@RAZON_SOCIAL)),2));
    IF NULLIF(@INICIALES,'') IS NULL SET @INICIALES='--';
 
    SET @H_RAZON=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H_DESC=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@DESCRIPCION,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H_CUIT=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@CUIT,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H_TIPO=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@TIPO_PROVEEDOR_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H_IVA=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@CONDICION_IVA_DESC,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @H_OBS=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@OBSERVACIONES,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
    IF @FECHA_ALTA IS NOT NULL SET @ALTA_TXT=CONVERT(VARCHAR(10),@FECHA_ALTA,103);
    IF @FECHA_UPD IS NOT NULL SET @UPD_TXT=CONVERT(VARCHAR(10),@FECHA_UPD,103);
    ELSE IF @FECHA_ALTA IS NOT NULL SET @UPD_TXT=CONVERT(VARCHAR(10),@FECHA_ALTA,103);
 
    IF @ESTADO='ACTIVO'
    BEGIN
        SET @ESTADO_BADGE_CLASE='is-active';
        SET @ESTADO_BADGE_TEXTO='ACTIVO';
    END
    ELSE IF @ESTADO='INACTIVO'
    BEGIN
        SET @ESTADO_BADGE_CLASE='is-inactive';
        SET @ESTADO_BADGE_TEXTO='INACTIVO';
    END
    ELSE
        SET @ESTADO_BADGE_TEXTO=ISNULL(NULLIF(@ESTADO,''),'SIN ESTADO');
 
    DECLARE @HTML_ESTADO_BADGE VARCHAR(250)=
        '<span class="vct-360-badge '+@ESTADO_BADGE_CLASE+'">'+@ESTADO_BADGE_TEXTO+'</span>';
 
    SET @BTN_BACK=
        '<nav class="vct-breadcrumb-simple" aria-label="Breadcrumb">'+
            '<button type="button" class="vct-breadcrumb-link" '+
                    'data-vct-v360-back '+
                    'data-vct-sidebar-mod="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'">Proveedores</button>'+
            '<span class="vct-breadcrumb-sep">&#8250;</span>'+
            '<span class="vct-breadcrumb-item">Vista 360</span>'+
            '<span class="vct-breadcrumb-sep">&#8250;</span>'+
            '<span class="vct-breadcrumb-current">'+@H_RAZON+'</span>'+
        '</nav>';
 
 
    /* ============================================================
       14.b VIATICOS REALES POR PROVEEDOR
       ------------------------------------------------------------
       Fuente:
         VCT_VIATICOS
         VCT_PRM_VIATICOS_TIPOS
         VCT_PRM_SERVICIOS
         VCT_PROYECTOS
         VCT_PRM_PROYECTOS_ESTADOS
         VCT_CONSULTORES
 
       Se elimina por completo la asignacion simulada/provisoria.
       ============================================================ */
    DECLARE
        @ViaticosCount          INT=0,
        @ViaticosProjectCount   INT=0,
        @ViaticosConsultorCount INT=0,
        @TotalViaticos          NUMERIC(18,2)=0,
        @TotalViaticosAnio      NUMERIC(18,2)=0,
        @MaxViaticoMes          NUMERIC(18,2)=0,
        @ViatYear               INT=YEAR(GETDATE()),
 
        @HTML_VIAT_PROJECTS     VARCHAR(MAX)='',
        @HTML_VIAT_CONS         VARCHAR(MAX)='',
        @HTML_VIAT_BARS         VARCHAR(MAX)='',
        @HTML_VIAT_DONUT        VARCHAR(MAX)='',
        @HTML_VIAT_DONUT_BG     VARCHAR(2000)='',
        @HTML_VIATICOS          VARCHAR(MAX)='';
 
 
    /* ------------------------------------------------------------
       CONSULTOR - FUENTE NORMALIZADA
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_CONS_RAW') IS NOT NULL DROP TABLE #V360_CONS_RAW;
    CREATE TABLE #V360_CONS_RAW
    (
        ID            INT,
        NOMBRES       VARCHAR(150),
        APELLIDOS     VARCHAR(150),
        RAZON_SOCIAL  VARCHAR(250),
        ESTADO        VARCHAR(50)
    );
 
    IF OBJECT_ID('tempdb..#V360_CONS_SOURCE') IS NOT NULL DROP TABLE #V360_CONS_SOURCE;
    CREATE TABLE #V360_CONS_SOURCE
    (
        ID     INT,
        NOMBRE VARCHAR(320),
        ESTADO VARCHAR(50)
    );
 
    IF OBJECT_ID('dbo.VCT_CONSULTORES','U') IS NOT NULL
       AND COL_LENGTH('dbo.VCT_CONSULTORES','ID') IS NOT NULL
    BEGIN
        DECLARE
            @C_NOMBRES_PROV   NVARCHAR(500)=N'''''' ,
            @C_APELLIDOS_PROV NVARCHAR(500)=N'''''' ,
            @C_RAZON_PROV     NVARCHAR(500)=N'''''' ,
            @C_ESTADO_PROV    NVARCHAR(500)=N'''''' ,
            @SQL_CONS_PROV    NVARCHAR(MAX)=N'';
 
        IF COL_LENGTH('dbo.VCT_CONSULTORES','NOMBRES') IS NOT NULL
            SET @C_NOMBRES_PROV=N'CONVERT(VARCHAR(150),ISNULL(C.NOMBRES,''''))';
        ELSE IF COL_LENGTH('dbo.VCT_CONSULTORES','NOMBRE') IS NOT NULL
            SET @C_NOMBRES_PROV=N'CONVERT(VARCHAR(150),ISNULL(C.NOMBRE,''''))';
 
        IF COL_LENGTH('dbo.VCT_CONSULTORES','APELLIDOS') IS NOT NULL
            SET @C_APELLIDOS_PROV=N'CONVERT(VARCHAR(150),ISNULL(C.APELLIDOS,''''))';
        ELSE IF COL_LENGTH('dbo.VCT_CONSULTORES','APELLIDO') IS NOT NULL
            SET @C_APELLIDOS_PROV=N'CONVERT(VARCHAR(150),ISNULL(C.APELLIDO,''''))';
 
        IF COL_LENGTH('dbo.VCT_CONSULTORES','RAZON_SOCIAL') IS NOT NULL
            SET @C_RAZON_PROV=N'CONVERT(VARCHAR(250),ISNULL(C.RAZON_SOCIAL,''''))';
        ELSE IF COL_LENGTH('dbo.VCT_CONSULTORES','NOMBRE_FANTASIA') IS NOT NULL
            SET @C_RAZON_PROV=N'CONVERT(VARCHAR(250),ISNULL(C.NOMBRE_FANTASIA,''''))';
 
        IF COL_LENGTH('dbo.VCT_CONSULTORES','ESTADO') IS NOT NULL
            SET @C_ESTADO_PROV=N'CONVERT(VARCHAR(50),ISNULL(C.ESTADO,''''))';
 
        SET @SQL_CONS_PROV=N'
            INSERT INTO #V360_CONS_RAW(ID,NOMBRES,APELLIDOS,RAZON_SOCIAL,ESTADO)
            SELECT
                C.ID,
                '+@C_NOMBRES_PROV+N',
                '+@C_APELLIDOS_PROV+N',
                '+@C_RAZON_PROV+N',
                '+@C_ESTADO_PROV+N'
            FROM dbo.VCT_CONSULTORES C WITH(NOLOCK);';
 
        EXEC sp_executesql @SQL_CONS_PROV;
    END;
 
    INSERT INTO #V360_CONS_SOURCE(ID,NOMBRE,ESTADO)
    SELECT
        R.ID,
        CASE
            WHEN NULLIF(LTRIM(RTRIM(ISNULL(R.NOMBRES,'')+ISNULL(R.APELLIDOS,''))),'') IS NOT NULL
                THEN LTRIM(RTRIM(
                    ISNULL(R.NOMBRES,'')+
                    CASE
                        WHEN NULLIF(LTRIM(RTRIM(ISNULL(R.NOMBRES,''))),'') IS NOT NULL
                         AND NULLIF(LTRIM(RTRIM(ISNULL(R.APELLIDOS,''))),'') IS NOT NULL
                            THEN ' '
                        ELSE ''
                    END+
                    ISNULL(R.APELLIDOS,'')
                ))
            ELSE LTRIM(RTRIM(ISNULL(R.RAZON_SOCIAL,'')))
        END,
        ISNULL(R.ESTADO,'')
    FROM #V360_CONS_RAW R
    WHERE NULLIF(
        LTRIM(RTRIM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(ISNULL(R.NOMBRES,'')+ISNULL(R.APELLIDOS,''))),'') IS NOT NULL
                    THEN ISNULL(R.NOMBRES,'')+' '+ISNULL(R.APELLIDOS,'')
                ELSE ISNULL(R.RAZON_SOCIAL,'')
            END
        )),
        ''
    ) IS NOT NULL;
 
 
    /* ------------------------------------------------------------
       VIATICOS DEL PROVEEDOR - FUENTE NORMALIZADA
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_VIATICOS_SOURCE') IS NOT NULL DROP TABLE #V360_VIATICOS_SOURCE;
 
    CREATE TABLE #V360_VIATICOS_SOURCE
    (
        ID                    INT,
        ID_PROYECTO           INT,
        ID_PROYECTO_LEGACY    INT,
        PROYECTO_CODIGO       VARCHAR(100),
        PROYECTO_NOMBRE       VARCHAR(300),
        PROYECTO_REFERENCIA   VARCHAR(300),
        PROYECTO_ESTADO_COD   VARCHAR(50),
        PROYECTO_ESTADO       VARCHAR(100),
        PROYECTO_FECHA_INICIO DATETIME,
        PROYECTO_FECHA_FIN    DATETIME,
 
        ID_CONSULTOR          INT,
        CONSULTOR_NOMBRE      VARCHAR(320),
 
        ID_SERVICIO           INT,
        SERVICIO              VARCHAR(150),
 
        TIPO_VIATICO          VARCHAR(150),
        DESCRIPCION           VARCHAR(500),
        DESTINO               VARCHAR(200),
 
        FECHA_DESDE           DATETIME,
        FECHA_HASTA           DATETIME,
        FECHA_OPERACION       DATETIME,
 
        MONEDA                VARCHAR(3),
        IMPORTE               NUMERIC(18,2),
 
        NRO_COMPROBANTE       VARCHAR(100),
        ESTADO_PAGO           VARCHAR(50),
        PROX_VENCIMIENTO      DATETIME
    );
 
    IF OBJECT_ID('dbo.VCT_VIATICOS','U') IS NOT NULL
    BEGIN
        INSERT INTO #V360_VIATICOS_SOURCE
        (
            ID,
            ID_PROYECTO,
            ID_PROYECTO_LEGACY,
            PROYECTO_CODIGO,
            PROYECTO_NOMBRE,
            PROYECTO_REFERENCIA,
            PROYECTO_ESTADO_COD,
            PROYECTO_ESTADO,
            PROYECTO_FECHA_INICIO,
            PROYECTO_FECHA_FIN,
            ID_CONSULTOR,
            CONSULTOR_NOMBRE,
            ID_SERVICIO,
            SERVICIO,
            TIPO_VIATICO,
            DESCRIPCION,
            DESTINO,
            FECHA_DESDE,
            FECHA_HASTA,
            FECHA_OPERACION,
            MONEDA,
            IMPORTE,
            NRO_COMPROBANTE,
            ESTADO_PAGO,
            PROX_VENCIMIENTO
        )
        SELECT
            V.ID,
            V.ID_PROYECTO,
            V.ID_PROYECTO_LEGACY,
 
            CASE
                WHEN P.ID IS NOT NULL
                    THEN ISNULL(CONVERT(VARCHAR(100),P.CODIGO),'')
                WHEN V.ID_PROYECTO_LEGACY IS NOT NULL
                    THEN 'LEG-'+CONVERT(VARCHAR(20),V.ID_PROYECTO_LEGACY)
                ELSE '-'
            END,
 
            CASE
                WHEN P.ID IS NOT NULL
                    THEN ISNULL(CONVERT(VARCHAR(300),P.NOMBRE),'')
                WHEN V.ID_PROYECTO_LEGACY IS NOT NULL
                    THEN 'Proyecto historico #'+CONVERT(VARCHAR(20),V.ID_PROYECTO_LEGACY)
                ELSE 'Sin proyecto'
            END,
 
            ISNULL(CONVERT(VARCHAR(300),P.REFERENCIA),''),
            PE.CODIGO,
            PE.DESCRIPCION,
            P.FECHA_INICIO,
            P.FECHA_FIN,
 
            V.ID_CONSULTOR,
 
            CASE
                WHEN V.ID_CONSULTOR IS NULL
                    THEN 'Sin consultor'
                WHEN C.NOMBRE IS NOT NULL
                    THEN C.NOMBRE
                ELSE 'Consultor #'+CONVERT(VARCHAR(20),V.ID_CONSULTOR)
            END,
 
            V.ID_SERVICIO,
 
            CASE
                WHEN S.DESCRIPCION IS NOT NULL
                    THEN S.DESCRIPCION
                WHEN S.CODIGO IS NOT NULL
                    THEN S.CODIGO
                WHEN V.ID_SERVICIO IS NOT NULL
                    THEN 'Servicio #'+CONVERT(VARCHAR(20),V.ID_SERVICIO)
                ELSE 'Sin servicio'
            END,
 
            ISNULL(TV.DESCRIPCION,ISNULL(TV.CODIGO,'Otro')),
            ISNULL(V.DESCRIPCION,''),
            ISNULL(V.DESTINO,''),
 
            V.FECHA_DESDE,
            V.FECHA_HASTA,
            ISNULL(V.FECHA_DESDE,ISNULL(V.FECHA_COMPROBANTE,V.FECHA_ALTA)),
 
            ISNULL(NULLIF(LTRIM(RTRIM(V.MONEDA)),''),'ARS'),
            ISNULL(V.IMPORTE,0),
 
            ISNULL(V.NRO_COMPROBANTE,''),
            ISNULL(V.ESTADO_PAGO,''),
            V.PROX_VENCIMIENTO
 
        FROM dbo.VCT_VIATICOS V WITH(NOLOCK)
 
        LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
            ON P.ID=V.ID_PROYECTO
 
        LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS PE WITH(NOLOCK)
            ON PE.ID=P.ID_ESTADO
 
        LEFT JOIN #V360_CONS_SOURCE C
            ON C.ID=V.ID_CONSULTOR
 
        LEFT JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
            ON S.ID=V.ID_SERVICIO
 
        LEFT JOIN dbo.VCT_PRM_VIATICOS_TIPOS TV WITH(NOLOCK)
            ON TV.ID=V.ID_TIPO_VIATICO
 
        WHERE V.ID_PROVEEDOR=@ID_PROVEEDOR;
    END;
 
 
    SELECT
        @ViaticosCount=COUNT(*),
        @TotalViaticos=ISNULL(SUM(CASE WHEN MONEDA='ARS' THEN IMPORTE ELSE 0 END),0)
    FROM #V360_VIATICOS_SOURCE;
 
 
    /* ------------------------------------------------------------
       PROYECTOS REALES CON VIATICOS
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_VIAT_PROJECTS') IS NOT NULL DROP TABLE #V360_VIAT_PROJECTS;
 
    CREATE TABLE #V360_VIAT_PROJECTS
    (
        ID_PROYECTO         INT,
        ID_PROYECTO_LEGACY  INT,
        CODIGO              VARCHAR(100),
        NOMBRE              VARCHAR(300),
        REFERENCIA          VARCHAR(300),
        ESTADO_CODIGO       VARCHAR(50),
        ESTADO              VARCHAR(100),
        FECHA_INICIO        DATETIME,
        FECHA_FIN           DATETIME,
        ULTIMO_VIATICO      DATETIME,
        VIATICOS            INT,
        MONTO               NUMERIC(18,2)
    );
 
    INSERT INTO #V360_VIAT_PROJECTS
    (
        ID_PROYECTO,
        ID_PROYECTO_LEGACY,
        CODIGO,
        NOMBRE,
        REFERENCIA,
        ESTADO_CODIGO,
        ESTADO,
        FECHA_INICIO,
        FECHA_FIN,
        ULTIMO_VIATICO,
        VIATICOS,
        MONTO
    )
    SELECT
        V.ID_PROYECTO,
        V.ID_PROYECTO_LEGACY,
        V.PROYECTO_CODIGO,
        V.PROYECTO_NOMBRE,
        V.PROYECTO_REFERENCIA,
        V.PROYECTO_ESTADO_COD,
        V.PROYECTO_ESTADO,
        V.PROYECTO_FECHA_INICIO,
        V.PROYECTO_FECHA_FIN,
        MAX(V.FECHA_OPERACION),
        COUNT(*),
        SUM(CASE WHEN V.MONEDA='ARS' THEN V.IMPORTE ELSE 0 END)
    FROM #V360_VIATICOS_SOURCE V
    GROUP BY
        V.ID_PROYECTO,
        V.ID_PROYECTO_LEGACY,
        V.PROYECTO_CODIGO,
        V.PROYECTO_NOMBRE,
        V.PROYECTO_REFERENCIA,
        V.PROYECTO_ESTADO_COD,
        V.PROYECTO_ESTADO,
        V.PROYECTO_FECHA_INICIO,
        V.PROYECTO_FECHA_FIN;
 
    SELECT @ViaticosProjectCount=COUNT(*)
    FROM #V360_VIAT_PROJECTS;
 
 
    /* ------------------------------------------------------------
       CONSULTORES REALES CON VIATICOS
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_VIAT_CONS') IS NOT NULL DROP TABLE #V360_VIAT_CONS;
 
    CREATE TABLE #V360_VIAT_CONS
    (
        ID_CONSULTOR INT,
        NOMBRE       VARCHAR(320),
        PROYECTOS    INT,
        VIATICOS     INT,
        MONTO        NUMERIC(18,2)
    );
 
    INSERT INTO #V360_VIAT_CONS
    (
        ID_CONSULTOR,
        NOMBRE,
        PROYECTOS,
        VIATICOS,
        MONTO
    )
    SELECT
        V.ID_CONSULTOR,
        V.CONSULTOR_NOMBRE,
 
        COUNT
        (
            DISTINCT
            CASE
                WHEN V.ID_PROYECTO IS NOT NULL
                    THEN V.ID_PROYECTO
                WHEN V.ID_PROYECTO_LEGACY IS NOT NULL
                    THEN -V.ID_PROYECTO_LEGACY
                ELSE NULL
            END
        ),
 
        COUNT(*),
 
        SUM(CASE WHEN V.MONEDA='ARS' THEN V.IMPORTE ELSE 0 END)
 
    FROM #V360_VIATICOS_SOURCE V
 
    GROUP BY
        V.ID_CONSULTOR,
        V.CONSULTOR_NOMBRE;
 
    SELECT @ViaticosConsultorCount=COUNT(*)
    FROM #V360_VIAT_CONS;
 
 
    /* ------------------------------------------------------------
       VIATICOS POR MES - ANIO ACTUAL
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_VIAT_MONTHS') IS NOT NULL DROP TABLE #V360_VIAT_MONTHS;
 
    CREATE TABLE #V360_VIAT_MONTHS
    (
        ORDEN      INT,
        ETQ        VARCHAR(3),
        MES_INICIO DATETIME,
        MONTO      NUMERIC(18,2)
    );
 
    INSERT INTO #V360_VIAT_MONTHS(ORDEN,ETQ,MES_INICIO,MONTO)
    SELECT 1,'Ene',DATEADD(MONTH,0,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 2,'Feb',DATEADD(MONTH,1,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 3,'Mar',DATEADD(MONTH,2,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 4,'Abr',DATEADD(MONTH,3,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 5,'May',DATEADD(MONTH,4,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 6,'Jun',DATEADD(MONTH,5,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 7,'Jul',DATEADD(MONTH,6,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 8,'Ago',DATEADD(MONTH,7,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 9,'Sep',DATEADD(MONTH,8,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 10,'Oct',DATEADD(MONTH,9,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 11,'Nov',DATEADD(MONTH,10,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0
    UNION ALL SELECT 12,'Dic',DATEADD(MONTH,11,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE()),0)),0;
 
    UPDATE M
       SET MONTO=
           ISNULL
           (
               (
                   SELECT SUM(V.IMPORTE)
                   FROM #V360_VIATICOS_SOURCE V
                   WHERE V.MONEDA='ARS'
                     AND V.FECHA_OPERACION>=M.MES_INICIO
                     AND V.FECHA_OPERACION<DATEADD(MONTH,1,M.MES_INICIO)
               ),
               0
           )
    FROM #V360_VIAT_MONTHS M;
 
    SELECT
        @TotalViaticosAnio=ISNULL(SUM(MONTO),0),
        @MaxViaticoMes=ISNULL(MAX(MONTO),0)
    FROM #V360_VIAT_MONTHS;
 
    IF @MaxViaticoMes<=0
        SET @MaxViaticoMes=1;
 
 
    /* ------------------------------------------------------------
       DISTRIBUCION REAL POR TIPO GENERAL DE SERVICIO
       Top 3 + Otros.
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#V360_VIAT_SERVICE_AGG') IS NOT NULL DROP TABLE #V360_VIAT_SERVICE_AGG;
 
    CREATE TABLE #V360_VIAT_SERVICE_AGG
    (
        ID_SERVICIO INT,
        NOMBRE      VARCHAR(150),
        MONTO       NUMERIC(18,2)
    );
 
    INSERT INTO #V360_VIAT_SERVICE_AGG(ID_SERVICIO,NOMBRE,MONTO)
    SELECT
        V.ID_SERVICIO,
        V.SERVICIO,
        SUM(CASE WHEN V.MONEDA='ARS' THEN V.IMPORTE ELSE 0 END)
    FROM #V360_VIATICOS_SOURCE V
    GROUP BY
        V.ID_SERVICIO,
        V.SERVICIO;
 
    IF OBJECT_ID('tempdb..#V360_VIAT_TYPES') IS NOT NULL DROP TABLE #V360_VIAT_TYPES;
 
    CREATE TABLE #V360_VIAT_TYPES
    (
        ORDEN  INT,
        NOMBRE VARCHAR(150),
        PORC   NUMERIC(9,2),
        MONTO  NUMERIC(18,2),
        COLOR  VARCHAR(20)
    );
 
    ;WITH A AS
    (
        SELECT
            ID_SERVICIO,
            NOMBRE,
            MONTO,
            ROW_NUMBER() OVER(ORDER BY MONTO DESC,NOMBRE,ISNULL(ID_SERVICIO,0)) AS RN
        FROM #V360_VIAT_SERVICE_AGG
        WHERE MONTO>0
    )
    INSERT INTO #V360_VIAT_TYPES(ORDEN,NOMBRE,PORC,MONTO,COLOR)
    SELECT
        RN,
        NOMBRE,
        0,
        MONTO,
        CASE RN
            WHEN 1 THEN '#8A003B'
            WHEN 2 THEN '#C77B9D'
            ELSE '#D1A15D'
        END
    FROM A
    WHERE RN<=3;
 
    DECLARE @MontoTopServicios NUMERIC(18,2)=0;
    SELECT @MontoTopServicios=ISNULL(SUM(MONTO),0)
    FROM #V360_VIAT_TYPES;
 
    IF @TotalViaticos>@MontoTopServicios
    BEGIN
        INSERT INTO #V360_VIAT_TYPES(ORDEN,NOMBRE,PORC,MONTO,COLOR)
        VALUES
        (
            4,
            'Otros',
            0,
            @TotalViaticos-@MontoTopServicios,
            '#94A3B8'
        );
    END;
 
    IF @TotalViaticos>0
    BEGIN
        UPDATE #V360_VIAT_TYPES
           SET PORC=CONVERT(NUMERIC(9,2),(MONTO*100.0)/@TotalViaticos);
 
        DECLARE @UltimoTipoOrden INT;
        SELECT @UltimoTipoOrden=MAX(ORDEN)
        FROM #V360_VIAT_TYPES;
 
        IF @UltimoTipoOrden IS NOT NULL
        BEGIN
            UPDATE T
               SET PORC=
                   CONVERT
                   (
                       NUMERIC(9,2),
                       100.00-
                       ISNULL
                       (
                           (
                               SELECT SUM(X.PORC)
                               FROM #V360_VIAT_TYPES X
                               WHERE X.ORDEN<T.ORDEN
                           ),
                           0
                       )
                   )
            FROM #V360_VIAT_TYPES T
            WHERE T.ORDEN=@UltimoTipoOrden;
        END;
 
        SELECT @HTML_VIAT_DONUT_BG=
            'background:conic-gradient('+
            STUFF
            (
                (
                    SELECT
                        ','+
                        T.COLOR+' '+
                        CONVERT
                        (
                            VARCHAR(30),
                            CONVERT
                            (
                                NUMERIC(9,2),
                                ISNULL
                                (
                                    (
                                        SELECT SUM(X.PORC)
                                        FROM #V360_VIAT_TYPES X
                                        WHERE X.ORDEN<T.ORDEN
                                    ),
                                    0
                                )
                            )
                        )+'% '+
                        CONVERT
                        (
                            VARCHAR(30),
                            CONVERT
                            (
                                NUMERIC(9,2),
                                ISNULL
                                (
                                    (
                                        SELECT SUM(X.PORC)
                                        FROM #V360_VIAT_TYPES X
                                        WHERE X.ORDEN<=T.ORDEN
                                    ),
                                    0
                                )
                            )
                        )+'%'
                    FROM #V360_VIAT_TYPES T
                    ORDER BY T.ORDEN
                    FOR XML PATH(''),TYPE
                ).value('.','VARCHAR(MAX)'),
                1,
                1,
                ''
            )+
            ');';
    END
    ELSE
    BEGIN
        SET @HTML_VIAT_DONUT_BG='background:#E5E7EB;';
    END;
 
 
    /* ------------------------------------------------------------
       HTML - PROYECTOS CON VIATICOS
       ------------------------------------------------------------ */
    SELECT @HTML_VIAT_PROJECTS=ISNULL((
        SELECT TOP 5
            '<tr>'+
                '<td data-label="Proyecto">'+
                    '<span class="vct-360-project-name">('+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    ') '+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</span>'+
                    CASE WHEN ISNULL(P.REFERENCIA,'')<>''
                         THEN '<span class="vct-360-project-ref">'+
                              REPLACE(REPLACE(REPLACE(REPLACE(P.REFERENCIA,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                              '</span>'
                         ELSE '' END+
                '</td>'+
                '<td class="vct-text-center" data-label="Estado">'+
                    '<span class="vct-360-badge '+
                    CASE
                        WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'is-progress'
                        WHEN P.ESTADO_CODIGO='TERMINADO' THEN 'is-done'
                        WHEN P.ESTADO_CODIGO='CANCELADO' THEN 'is-cancel'
                        WHEN P.ESTADO_CODIGO IN ('BORRADOR','CONFIRMADO','PAUSADO') THEN 'is-planned'
                        ELSE 'is-neutral'
                    END+'">'+
                    REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'EN CURSO'
                            WHEN ISNULL(P.ESTADO,'')='' AND P.ID_PROYECTO IS NULL THEN 'HISTORICO'
                            ELSE ISNULL(NULLIF(P.ESTADO,''),'SIN ESTADO')
                        END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;')+
                    '</span>'+
                '</td>'+
                '<td class="vct-text-center" data-label="Inicio">'+
                    CASE WHEN P.FECHA_INICIO IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_INICIO,103) END+
                '</td>'+
                '<td class="vct-text-center" data-label="Fin">'+
                    CASE WHEN P.FECHA_FIN IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_FIN,103) END+
                '</td>'+
                '<td class="vct-text-right" data-label="Viáticos">ARS '+
                    REPLACE(CONVERT(VARCHAR(30),CAST(ISNULL(P.MONTO,0) AS MONEY),1),'.00','')+
                '</td>'+
            '</tr>'
        FROM #V360_VIAT_PROJECTS P
        ORDER BY
            CASE WHEN P.ULTIMO_VIATICO IS NULL THEN 1 ELSE 0 END,
            P.ULTIMO_VIATICO DESC,
            ISNULL(P.ID_PROYECTO,ISNULL(P.ID_PROYECTO_LEGACY,0)) DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_VIAT_PROJECTS=''
        SET @HTML_VIAT_PROJECTS=
            '<tr><td colspan="5"><div class="vct-360-empty vct-360-fixed-empty">No hay viáticos asociados a proyectos para este proveedor.</div></td></tr>';
 
 
    /* ------------------------------------------------------------
       HTML - CONSULTORES CON VIATICOS
       ------------------------------------------------------------ */
    SELECT @HTML_VIAT_CONS=ISNULL((
        SELECT TOP 5
            '<tr>'+
                '<td data-label="Consultor">'+
                    '<strong>'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</strong>'+
                    '<span class="vct-360-project-ref">'+CONVERT(VARCHAR(10),C.VIATICOS)+' viático(s)</span>'+
                '</td>'+
                '<td class="vct-text-center" data-label="Proyectos">'+CONVERT(VARCHAR(10),C.PROYECTOS)+'</td>'+
                '<td class="vct-text-right" data-label="Viáticos">ARS '+
                    REPLACE(CONVERT(VARCHAR(30),CAST(ISNULL(C.MONTO,0) AS MONEY),1),'.00','')+
                '</td>'+
            '</tr>'
        FROM #V360_VIAT_CONS C
        ORDER BY C.MONTO DESC,C.VIATICOS DESC,C.NOMBRE
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_VIAT_CONS=''
        SET @HTML_VIAT_CONS=
            '<tr><td colspan="3"><div class="vct-360-empty vct-360-fixed-empty">No hay consultores asociados a viáticos para este proveedor.</div></td></tr>';
 
 
    /* ------------------------------------------------------------
       HTML - BARRAS MENSUALES
       ------------------------------------------------------------ */
    SELECT @HTML_VIAT_BARS=ISNULL((
        SELECT
            '<div class="vct-360-column-item" style="width:7.8%;" title="'+
                M.ETQ+' · ARS '+
                REPLACE(CONVERT(VARCHAR(30),CAST(ISNULL(M.MONTO,0) AS MONEY),1),'.00','')+'">'+
                '<div class="vct-360-column-track" style="width:100%;height:130px;">'+
                    '<div class="vct-360-column-bar" style="height:'+
                        CONVERT
                        (
                            VARCHAR(10),
                            CASE
                                WHEN M.MONTO<=0 THEN 0
                                WHEN CAST((M.MONTO*100.0)/@MaxViaticoMes AS INT)<8 THEN 8
                                ELSE CAST((M.MONTO*100.0)/@MaxViaticoMes AS INT)
                            END
                        )+
                    '%;"></div>'+
                '</div>'+
                '<span class="vct-360-column-label">'+M.ETQ+'</span>'+
            '</div>'
        FROM #V360_VIAT_MONTHS M
        ORDER BY M.ORDEN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
 
    /* ------------------------------------------------------------
       HTML - DISTRIBUCION POR SERVICIO
       ------------------------------------------------------------ */
    SELECT @HTML_VIAT_DONUT=ISNULL((
        SELECT
            '<div class="vct-360-donut-legend-item">'+
                '<span class="vct-360-dot" style="background:'+T.COLOR+';"></span>'+
                '<span>'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(T.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                '</span>'+
                '<strong>'+
                    CONVERT(VARCHAR(20),T.PORC)+'% · ARS '+
                    REPLACE(CONVERT(VARCHAR(30),CAST(ISNULL(T.MONTO,0) AS MONEY),1),'.00','')+
                '</strong>'+
            '</div>'
        FROM #V360_VIAT_TYPES T
        ORDER BY T.ORDEN
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_VIAT_DONUT=''
        SET @HTML_VIAT_DONUT=
            '<div class="vct-360-empty">Sin importes de viáticos para distribuir.</div>';
 
 
    /* ------------------------------------------------------------
       HTML - DETALLE COMPLETO DE VIATICOS
       ------------------------------------------------------------ */
    SELECT @HTML_VIATICOS=ISNULL((
        SELECT
            '<tr data-vct-row>'+
                '<td class="vct-text-center" data-label="Fecha">'+
                    CASE WHEN V.FECHA_OPERACION IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),V.FECHA_OPERACION,103) END+
                '</td>'+
                '<td data-label="Proyecto">'+
                    '<span class="vct-360-project-name">('+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.PROYECTO_CODIGO,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    ') '+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.PROYECTO_NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</span>'+
                '</td>'+
                '<td data-label="Consultor">'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.CONSULTOR_NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                '</td>'+
                '<td data-label="Tipo">'+
                    '<span class="vct-360-project-name">'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(V.TIPO_VIATICO,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</span>'+
                    CASE WHEN ISNULL(V.SERVICIO,'')<>''
                         THEN '<span class="vct-360-project-ref">'+
                              REPLACE(REPLACE(REPLACE(REPLACE(V.SERVICIO,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                              '</span>'
                         ELSE '' END+
                '</td>'+
                '<td data-label="Destino / Detalle">'+
                    '<span class="vct-360-project-name">'+
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        ISNULL(NULLIF(V.DESTINO,''),ISNULL(NULLIF(V.DESCRIPCION,''),'-')),
                        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</span>'+
                    CASE WHEN ISNULL(V.NRO_COMPROBANTE,'')<>''
                         THEN '<span class="vct-360-project-ref">Comprobante: '+
                              REPLACE(REPLACE(REPLACE(REPLACE(V.NRO_COMPROBANTE,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                              '</span>'
                         ELSE '' END+
                '</td>'+
                '<td class="vct-text-right" data-label="Importe" data-vct-sort-value="'+CONVERT(VARCHAR(30),CAST(ROUND(ISNULL(V.IMPORTE,0)*100,0) AS BIGINT))+'">'+
                    ISNULL(NULLIF(V.MONEDA,''),'ARS')+' '+
                    REPLACE(CONVERT(VARCHAR(30),CAST(ISNULL(V.IMPORTE,0) AS MONEY),1),'.00','')+
                '</td>'+
                '<td class="vct-text-center" data-label="Pago">'+
                    '<span class="vct-360-badge '+
                    CASE
                        WHEN UPPER(REPLACE(ISNULL(V.ESTADO_PAGO,''),' ','')) IN ('PAGADO','PAGA','CANCELADO','CANCELADA') THEN 'is-done'
                        WHEN UPPER(REPLACE(ISNULL(V.ESTADO_PAGO,''),' ','')) IN ('VENCIDO','VENCIDA') THEN 'is-cancel'
                        WHEN UPPER(REPLACE(ISNULL(V.ESTADO_PAGO,''),' ','')) IN ('PENDIENTE','PARCIAL','PARCIALMENTE') THEN 'is-planned'
                        ELSE 'is-neutral'
                    END+'">'+
                    REPLACE(REPLACE(REPLACE(
                        UPPER(ISNULL(NULLIF(V.ESTADO_PAGO,''),'SIN ESTADO')),
                        '&','&amp;'),'<','&lt;'),'>','&gt;')+
                    '</span>'+
                '</td>'+
            '</tr>'
        FROM #V360_VIATICOS_SOURCE V
        ORDER BY
            CASE WHEN V.FECHA_OPERACION IS NULL THEN 1 ELSE 0 END,
            V.FECHA_OPERACION DESC,
            V.ID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_VIATICOS=''
        SET @HTML_VIATICOS=
            '<div class="vct-360-empty vct-360-fixed-empty">No hay viáticos registrados para este proveedor.</div>';
    ELSE
        SET @HTML_VIATICOS=
            '<div data-vct-dg data-vct-dg-id="v360_prov_viaticos" data-vct-dg-title="Viaticos del proveedor" data-vct-dg-subtitle="Proveedor: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@RAZON_SOCIAL,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="viatico(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar viatico, proyecto, consultor..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th class="vct-text-center" data-vct-width="9%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="23%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="consultor" data-vct-sortable="true"><span>Consultor</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="destino" data-vct-sortable="true" data-vct-truncate="2"><span>Destino / Detalle</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-right" data-vct-width="11%" data-vct-sort="importe" data-vct-sortable="true" data-vct-sort-type="number"><span>Importe</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="pago" data-vct-sortable="true"><span>Pago</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>'+
            '<tbody>'+@HTML_VIATICOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       15. OUTPUT 1 - HEADER / FICHA / KPI / TABS
       ============================================================ */
    SET @OUTPARAM1=
        ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="'+CONVERT(VARCHAR(20),ISNULL(@SIDEBAR_ID,0))+'"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
 
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><section class="vct-module vct-360-module vct-proveedor360-module vct-360-visual-final"
         data-vct-module
         data-vct-entity-theme="proveedor"
         data-vct-tabs
         data-vct-tabs-active="'+ISNULL(@ACTIVE_TAB,'resumen')+'"
         data-vct-tabs-reset="'+CONVERT(VARCHAR(1),@V360_RESET_TAB)+'"
         data-vct-proveedor-key="'+CONVERT(VARCHAR(100),@ID_PROVEEDOR)+'">
 
    <div class="vct-360-breadcrumb-row">
        '+ISNULL(@BTN_BACK,'')+'
    </div>
 
    <div class="vct-360-client-strip vct-360-proveedor-strip">
        <div class="vct-360-card-left">
            <div class="vct-360-avatar">'+@INICIALES+'</div>
            <div class="vct-360-identity">
                <div class="vct-360-identity-title">
                    <h1>'+@H_RAZON+'</h1>
                    '+@HTML_ESTADO_BADGE+'
                </div>
                <div class="vct-360-client-meta">
                    <span><span data-vct-icon="file-text"></span>CUIT '+CASE WHEN @H_CUIT='' THEN '-' ELSE @H_CUIT END+'</span>
                    <span><span data-vct-icon="truck"></span>'+CASE WHEN @H_TIPO='' THEN 'Tipo sin definir' ELSE @H_TIPO END+'</span>
                    <span><span data-vct-icon="circle-dollar-sign"></span>'+CASE WHEN @H_IVA='' THEN 'IVA sin definir' ELSE @H_IVA END+'</span>
                    '+CASE WHEN @H_DESC<>'' THEN '<span><span data-vct-icon="briefcase"></span>'+@H_DESC+'</span>' ELSE '' END+'
                    <span><span data-vct-icon="calendar"></span>Alta '+@ALTA_TXT+'</span>
                </div>
            </div>
        </div>
 
        <div class="vct-360-card-right">
            <div class="vct-360-alerts" data-vct-alerts data-vct-alert-count="'+CONVERT(VARCHAR(10),@TelefonosPendientes)+'" aria-label="Telefonos pendientes: '+CONVERT(VARCHAR(10),@TelefonosPendientes)+'" title="Telefonos pendientes de normalizar">
                <span class="vct-360-alert-icon"><span data-vct-icon="bell"></span></span>
                <span class="vct-360-alert-count">'+CONVERT(VARCHAR(10),@TelefonosPendientes)+'</span>
            </div>
            <span class="vct-360-card-divider" aria-hidden="true"></span>
            <div class="vct-360-last-management">
                <span class="vct-360-inline-stat-icon"><span data-vct-icon="calendar"></span></span>
                <span>
                    <span class="vct-360-inline-stat-label">Ultima actualizacion</span>
                    <span class="vct-360-inline-stat-value">'+@UPD_TXT+'</span>
                </span>
            </div>
        </div>
    </div>
 
    <div class="vct-360-content-shell">
        <div class="vct-360-stats-row" style="grid-template-columns:repeat(5,minmax(0,1fr));">
            <div class="vct-360-stat" style="--vct-kpi-accent:#A85E08;--vct-kpi-bg:#FFF9F1;--vct-kpi-icon-bg:#F8E8D1;--vct-kpi-icon:#8A4B05;">
                <span>
                    <span class="vct-360-stat-label">Proyectos</span>
                    <b>'+CONVERT(VARCHAR(10),@ViaticosProjectCount)+'</b>
                    <span style="display:block;margin-top:4px;color:#64748b;font-size:9px;font-weight:500;">Con este proveedor</span>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="briefcase"></span></span>
            </div>
 
            <div class="vct-360-stat" style="--vct-kpi-accent:#B56E18;--vct-kpi-bg:#FFFAF3;--vct-kpi-icon-bg:#F8EBD8;--vct-kpi-icon:#9B5D12;">
                <span>
                    <span class="vct-360-stat-label">Viáticos</span>
                    <b>'+CONVERT(VARCHAR(10),@ViaticosCount)+'</b>
                    <span style="display:block;margin-top:4px;color:#64748b;font-size:9px;font-weight:500;">ARS '+REPLACE(CONVERT(VARCHAR(30),CAST(@TotalViaticos AS MONEY),1),'.00','')+' total</span>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="circle-dollar-sign"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="blue">
                <span>
                    <span class="vct-360-stat-label">Domicilios</span>
                    <b>'+CONVERT(VARCHAR(10),@DomiciliosCount)+'</b>
                    <span style="display:block;margin-top:4px;color:#64748b;font-size:9px;font-weight:500;">'+CASE WHEN EXISTS(SELECT 1 FROM #DOMICILIOS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI') THEN '1 principal' ELSE 'Sin principal' END+'</span>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="map-pin"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="violet">
                <span>
                    <span class="vct-360-stat-label">Teléfonos</span>
                    <b>'+CONVERT(VARCHAR(10),@TelefonosCount)+'</b>
                    <span style="display:block;margin-top:4px;color:#64748b;font-size:9px;font-weight:500;">'+CASE WHEN @TelefonosPendientes>0 THEN CONVERT(VARCHAR(10),@TelefonosPendientes)+' pendiente(s)' ELSE CASE WHEN EXISTS(SELECT 1 FROM #TELEFONOS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI') THEN '1 principal' ELSE 'Sin principal' END END+'</span>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="phone"></span></span>
            </div>
 
            <div class="vct-360-stat" data-vct-tone="mint">
                <span>
                    <span class="vct-360-stat-label">Emails</span>
                    <b>'+CONVERT(VARCHAR(10),@EmailsCount)+'</b>
                    <span style="display:block;margin-top:4px;color:#64748b;font-size:9px;font-weight:500;">'+CASE WHEN EXISTS(SELECT 1 FROM #EMAILS360 WHERE UPPER(ISNULL(PRINCIPAL,''))='SI') THEN '1 principal' ELSE 'Sin principal' END+'</span>
                </span>
                <span class="vct-360-stat-icon"><span data-vct-icon="mail"></span></span>
            </div>
        </div>
 
        <div class="vct-360-tabsbar" data-vct-tablist>
            <button type="button" data-vct-tab="resumen"><span data-vct-icon="scan-eye"></span><span>Resumen</span></button>
            <button type="button" data-vct-tab="viaticos"><span data-vct-icon="circle-dollar-sign"></span><span>Viáticos</span></button>
            <button type="button" data-vct-tab="domicilio"><span data-vct-icon="map-pin"></span><span>Domicilios</span></button>
            <button type="button" data-vct-tab="telefonos"><span data-vct-icon="phone"></span><span>Telefonos</span></button>
            <button type="button" data-vct-tab="email"><span data-vct-icon="mail"></span><span>Emails</span></button>
        </div>
';
 
    /* ============================================================
       16. OUTPUT 2 - PANELES
       ============================================================ */
    SET @OUTPARAM2='
        <div class="vct-360-panel" data-vct-panel="resumen">
            <div class="vct-360-summary-main" style="grid-template-columns:minmax(0,1.55fr) minmax(320px,1fr);">
                <div class="vct-360-box">
                    <div class="vct-360-box-head">
                        <div>
                            <h3><span class="vct-360-title-icon" data-vct-icon="briefcase"></span>Proyectos recientes con viáticos</h3>
                            <div style="margin-top:3px;color:#8793a5;font-size:9px;">Proyectos vinculados a viáticos registrados para '+@H_RAZON+'.</div>
                        </div>
                    </div>
                    <div class="vct-360-grid-fixed vct-360-grid-five vct-360-projects-recent" style="overflow:hidden;">
                        <table class="vct-360-table vct-360-project-table vct-360-project-table-recent" style="width:100%;table-layout:fixed;">
                            <thead>
                                <tr>
                                    <th style="width:46%;">Proyecto</th>
                                    <th class="vct-text-center" style="width:14%;">Estado</th>
                                    <th class="vct-text-center" style="width:13%;">Inicio</th>
                                    <th class="vct-text-center" style="width:13%;">Fin</th>
                                    <th class="vct-text-right" style="width:14%;">Viáticos</th>
                                </tr>
                            </thead>
                            <tbody>'+ISNULL(@HTML_VIAT_PROJECTS,'')+'</tbody>
                        </table>
                    </div>
                </div>
 
                <div class="vct-360-box">
                    <div class="vct-360-box-head">
                        <div>
                            <h3><span class="vct-360-title-icon" data-vct-icon="users"></span>Consultores con viáticos</h3>
                            <div style="margin-top:3px;color:#8793a5;font-size:9px;">Consultores vinculados a viáticos reales del proveedor seleccionado.</div>
                        </div>
                    </div>
                    <div class="vct-table-wrap" style="overflow-x:hidden;">
                        <table class="vct-table vct-360-table" style="width:100%;table-layout:fixed;">
                            <thead>
                                <tr>
                                    <th style="width:56%;">Consultor</th>
                                    <th class="vct-text-center" style="width:14%;">Proyectos</th>
                                    <th class="vct-text-right" style="width:30%;">Viáticos</th>
                                </tr>
                            </thead>
                            <tbody>'+ISNULL(@HTML_VIAT_CONS,'')+'</tbody>
                        </table>
                    </div>
                </div>
            </div>
 
            <div class="vct-360-summary-charts" style="grid-template-columns:minmax(0,1.55fr) minmax(320px,1fr);">
                <div class="vct-360-box">
                    <div class="vct-360-box-head">
                        <div>
                            <h3><span class="vct-360-title-icon" data-vct-icon="chart-bar"></span>Viáticos por mes</h3>
                            <div style="margin-top:3px;color:#8793a5;font-size:9px;">Importes registrados en '+CONVERT(VARCHAR(4),@ViatYear)+' para '+@H_RAZON+'.</div>
                        </div>
                        <span class="vct-360-badge is-neutral">Año '+CONVERT(VARCHAR(4),@ViatYear)+'</span>
                    </div>
                    <div class="vct-360-column-chart" style="min-height:235px;padding:14px 8px 6px;">
                        <div class="vct-360-column-plot" style="height:165px;gap:8px;justify-content:space-between;padding:0 4px;">'+ISNULL(@HTML_VIAT_BARS,'')+'</div>
                        <div style="display:flex;justify-content:space-between;align-items:center;margin-top:10px;padding:0 4px;color:#64748b;font-size:9px;">
                            <span>Total anual</span>
                            <strong style="color:#172033;font-size:11px;">ARS '+REPLACE(CONVERT(VARCHAR(30),CAST(@TotalViaticosAnio AS MONEY),1),'.00','')+'</strong>
                        </div>
                    </div>
                </div>
 
                <div class="vct-360-box">
                    <div class="vct-360-box-head">
                        <div>
                            <h3><span class="vct-360-title-icon" data-vct-icon="chart-no-axes-column-increasing"></span>Viáticos por tipo de servicio</h3>
                            <div style="margin-top:3px;color:#8793a5;font-size:9px;">Distribución real de importes por tipo general de servicio.</div>
                        </div>
                    </div>
                    <div class="vct-360-chart-simple" style="min-height:235px;gap:22px;">
                        <div class="vct-360-donut-ring vct-360-donut-lg" style="'+@HTML_VIAT_DONUT_BG+'">
                            <div class="vct-360-donut-center vct-360-donut-center-lg">
                                <small>ARS</small>
                                <b style="font-size:18px;">'+REPLACE(CONVERT(VARCHAR(30),CAST(@TotalViaticos AS MONEY),1),'.00','')+'</b>
                                <span>Total</span>
                            </div>
                        </div>
                        <div class="vct-360-donut-legend-lg" style="min-width:200px;">'+ISNULL(@HTML_VIAT_DONUT,'')+'</div>
                    </div>
                </div>
            </div>
        </div>
 
        <div class="vct-360-panel" data-vct-panel="viaticos">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div>
                        <h3><span class="vct-360-title-icon" data-vct-icon="circle-dollar-sign"></span>Viáticos ('+CONVERT(VARCHAR(10),@ViaticosCount)+')</h3>
                        <div style="margin-top:3px;color:#8793a5;font-size:9px;">Total ARS '+REPLACE(CONVERT(VARCHAR(30),CAST(@TotalViaticos AS MONEY),1),'.00','')+'.</div>
                    </div>
                </div>
                '+@HTML_VIATICOS+'
            </div>
        </div>
 
        <div class="vct-360-panel" data-vct-panel="domicilio">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="map-pin"></span>Domicilios ('+CONVERT(VARCHAR(10),@DomiciliosCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_DOM,'')+'</div>
                </div>
                '+@HTML_DOMICILIOS+'
            </div>
        </div>
 
        <div class="vct-360-panel" data-vct-panel="telefonos">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="phone"></span>Telefonos ('+CONVERT(VARCHAR(10),@TelefonosCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_TEL,'')+'</div>
                </div>
                '+@HTML_TELEFONOS+'
            </div>
        </div>
 
        <div class="vct-360-panel" data-vct-panel="email">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="mail"></span>Emails ('+CONVERT(VARCHAR(10),@EmailsCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_MAIL,'')+'</div>
                </div>
                '+@HTML_EMAILS+'
            </div>
        </div>
    </div>
</section>
</div>';
 
    /* ============================================================
       17. OUTPUT 3 - DRAWERS
       ============================================================ */
    SET @OUTPARAM3=
        ISNULL(@HTML_DRAWER_DOM,'')+
        ISNULL(@HTML_DRAWER_TEL,'')+
        ISNULL(@HTML_DRAWER_MAIL,'');
END
