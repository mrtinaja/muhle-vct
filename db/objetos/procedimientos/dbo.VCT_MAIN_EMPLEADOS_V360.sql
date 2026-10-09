 
CREATE PROCEDURE [dbo].[VCT_MAIN_EMPLEADOS_V360]
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
 
    SET @OUTPARAM1=''; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */
    SET @OUTPARAM2='';
    SET @OUTPARAM3='';
 
    DECLARE
        @HTML_SHELL         VARCHAR(MAX)='',
        @RESULTADO_SHELL    VARCHAR(20)='',
        @CAN_VIEW           BIT=0,
        @CAN_EDIT           BIT=0,
        @BTN_BACK           VARCHAR(MAX)='';
 
    /* ============================================================
       1. PERMISOS
       ============================================================ */
    SELECT
        @CAN_VIEW = MAX(CASE WHEN A.Id='EMPLEADOS.VIEW' THEN 1 ELSE 0 END),
        @CAN_EDIT = MAX(CASE WHEN A.Id='EMPLEADOS.EDIT' THEN 1 ELSE 0 END)
    FROM dbo.Actions A WITH(NOLOCK)
    INNER JOIN dbo.GroupsActions GA WITH(NOLOCK)
        ON GA.ActionId COLLATE DATABASE_DEFAULT =
           A.Id COLLATE DATABASE_DEFAULT
    WHERE UPPER(LTRIM(RTRIM(GA.GroupId))) =
          UPPER(LTRIM(RTRIM(@IUNIDAD)))
      AND A.Id IN ('EMPLEADOS.VIEW','EMPLEADOS.EDIT');
 
    SET @CAN_VIEW=ISNULL(@CAN_VIEW,0);
    SET @CAN_EDIT=ISNULL(@CAN_EDIT,0);
 
    /* ============================================================
       2. SHELL GENERAL DEL FRAMEWORK
       ------------------------------------------------------------
       Reutiliza Sidebar + Header global ya cerrados.
       La Vista 360 no renderiza una cabecera interna propia.
       ============================================================ */
    BEGIN TRY
        EXEC dbo.VCT_GET_SHELL
             @IUNIDAD            = @IUNIDAD,
             @IAGENTE            = @IAGENTE,
             @FORM_ID            = @FORM_ID,
             @TITLE              = 'Vista 360 de Empleado',
             @SUBTITLE           = 'Información completa del empleado, sus proyectos y relaciones.',
             @SEARCH_PLACEHOLDER = '',
             @SHOW_SEARCH        = 0,
             @OSHELL             = @HTML_SHELL OUTPUT,
             @ORESULTADO         = @RESULTADO_SHELL OUTPUT;
    END TRY
    BEGIN CATCH
        SET @HTML_SHELL='';
        SET @RESULTADO_SHELL='ERROR';
    END CATCH;
 
    IF @CAN_VIEW=0
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="6"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Acceso restringido</h2>
            <p class="vct-card-subtitle">No posee permisos para visualizar la Vista 360 de Empleados.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;
 
    /* ============================================================
       3. EMPLEADO SELECCIONADO
       ============================================================ */
    DECLARE @ID_EMPLEADO INT=0;
 
    SELECT TOP 1
        @ID_EMPLEADO=ISNULL(IDSELEC01,0)
    FROM dbo.VCT_BUFFER WITH(NOLOCK)
    WHERE PAR_KEY=@IPKEYJOB;
 
    DECLARE
        @NOMBRES              VARCHAR(150)='',
        @APELLIDOS            VARCHAR(150)='',
        @TIPO_DOCUMENTO       VARCHAR(50)='',
        @NRO_DOCUMENTO        VARCHAR(50)='',
        @CUIT                 VARCHAR(30)='',
        @LEGAJO               VARCHAR(50)='',
        @CARGO                VARCHAR(100)='',
        @AREA                 VARCHAR(100)='',
        @FORMACION            VARCHAR(100)='',
        @MOVILIDAD            VARCHAR(50)='',
        @FECHA_INGRESO        DATETIME=NULL,
        @FECHA_EGRESO         DATETIME=NULL,
        @INGRESA_SISTEMA      BIT=0,
        @USUARIO_SEGURIDAD    VARCHAR(100)='',
        @ESTADO               VARCHAR(30)='',
        @FECHA_ALTA           DATETIME=NULL;
 
    SELECT TOP 1
        @NOMBRES=ISNULL(E.NOMBRES,''),
        @APELLIDOS=ISNULL(E.APELLIDOS,''),
        @TIPO_DOCUMENTO=ISNULL(E.TIPO_DOCUMENTO,''),
        @NRO_DOCUMENTO=ISNULL(E.NRO_DOCUMENTO,''),
        @CUIT=ISNULL(E.CUIT,''),
        @LEGAJO=ISNULL(E.LEGAJO,''),
        @CARGO=ISNULL(E.CARGO,''),
        @AREA=ISNULL(E.AREA,''),
        @FORMACION=ISNULL(E.FORMACION,''),
        @MOVILIDAD=ISNULL(E.MOVILIDAD,''),
        @FECHA_INGRESO=E.FECHA_INGRESO,
        @FECHA_EGRESO=E.FECHA_EGRESO,
        @INGRESA_SISTEMA=ISNULL(E.INGRESA_SISTEMA,0),
        @USUARIO_SEGURIDAD=LOWER(LTRIM(RTRIM(ISNULL(E.ID_USUARIO_SEGURIDAD,'')))),
        @ESTADO=UPPER(LTRIM(RTRIM(ISNULL(E.ESTADO,'')))),
        @FECHA_ALTA=E.FECHA_ALTA
    FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
    WHERE E.ID=@ID_EMPLEADO;
 
    IF NULLIF(LTRIM(RTRIM(@NOMBRES+@APELLIDOS)),'') IS NULL
    BEGIN
        SET @OUTPARAM1=ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="6"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
    <section class="vct-card">
        <div class="vct-card-body">
            <h2 class="vct-card-title">Sin empleado seleccionado</h2>
            <p class="vct-card-subtitle">Volvé al listado de Empleados y elegí uno para abrir su Vista 360.</p>
        </div>
    </section>
</div>';
        RETURN;
    END;
 
    DECLARE @NOMBRE_COMPLETO VARCHAR(320)=
        LTRIM(RTRIM(
            ISNULL(@NOMBRES,'')+
            CASE WHEN @NOMBRES<>'' AND @APELLIDOS<>'' THEN ' ' ELSE '' END+
            ISNULL(@APELLIDOS,'')
        ));
 
    DECLARE @USUARIO_DISPLAY VARCHAR(200)='';
 
    IF NULLIF(@USUARIO_SEGURIDAD,'') IS NOT NULL
    BEGIN
        SELECT TOP 1
            @USUARIO_DISPLAY=
                LOWER(LTRIM(RTRIM(ISNULL(G.UserMemberID,''))))+
                ' ('+LTRIM(RTRIM(ISNULL(G.GroupId,'')))+')'
        FROM dbo.GroupsUserMembers G WITH(NOLOCK)
        WHERE UPPER(LTRIM(RTRIM(ISNULL(G.GroupId,''))))<>'SQUAD'
          AND LOWER(LTRIM(RTRIM(ISNULL(G.UserMemberID,''))))=
              @USUARIO_SEGURIDAD
        ORDER BY G.GroupId;
    END;
 
    IF NULLIF(@USUARIO_DISPLAY,'') IS NULL
        SET @USUARIO_DISPLAY=
            CASE WHEN @INGRESA_SISTEMA=1
                 THEN ISNULL(NULLIF(@USUARIO_SEGURIDAD,''),'-')
                 ELSE '-' END;
 
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
 
    /* Defensa contra buffers historicos con valores concatenados. */
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
       5. MODELO DE RELACION DE DOMICILIOS / TELEFONOS / EMAILS
       ============================================================ */
    DECLARE
        @DOM_MODE  VARCHAR(20)='NONE',
        @TEL_MODE  VARCHAR(20)='NONE',
        @MAIL_MODE VARCHAR(20)='NONE';
 
    IF OBJECT_ID('dbo.VCT_DOMICILIOS','U') IS NOT NULL
    BEGIN
        IF COL_LENGTH('dbo.VCT_DOMICILIOS','TIPO_ENTIDAD') IS NOT NULL
           AND COL_LENGTH('dbo.VCT_DOMICILIOS','ID_ENTIDAD') IS NOT NULL
            SET @DOM_MODE='GENERIC';
        ELSE IF COL_LENGTH('dbo.VCT_DOMICILIOS','IDEMPLEADO') IS NOT NULL
            SET @DOM_MODE='IDEMPLEADO';
        ELSE IF COL_LENGTH('dbo.VCT_DOMICILIOS','ID_EMPLEADO') IS NOT NULL
            SET @DOM_MODE='ID_EMPLEADO';
    END;
 
    IF OBJECT_ID('dbo.VCT_TELEFONOS','U') IS NOT NULL
    BEGIN
        IF COL_LENGTH('dbo.VCT_TELEFONOS','TIPO_ENTIDAD') IS NOT NULL
           AND COL_LENGTH('dbo.VCT_TELEFONOS','ID_ENTIDAD') IS NOT NULL
            SET @TEL_MODE='GENERIC';
        ELSE IF COL_LENGTH('dbo.VCT_TELEFONOS','IDEMPLEADO') IS NOT NULL
            SET @TEL_MODE='IDEMPLEADO';
        ELSE IF COL_LENGTH('dbo.VCT_TELEFONOS','ID_EMPLEADO') IS NOT NULL
            SET @TEL_MODE='ID_EMPLEADO';
    END;
 
    IF OBJECT_ID('dbo.VCT_EMAILS','U') IS NOT NULL
    BEGIN
        IF COL_LENGTH('dbo.VCT_EMAILS','TIPO_ENTIDAD') IS NOT NULL
           AND COL_LENGTH('dbo.VCT_EMAILS','ID_ENTIDAD') IS NOT NULL
            SET @MAIL_MODE='GENERIC';
        ELSE IF COL_LENGTH('dbo.VCT_EMAILS','IDEMPLEADO') IS NOT NULL
            SET @MAIL_MODE='IDEMPLEADO';
        ELSE IF COL_LENGTH('dbo.VCT_EMAILS','ID_EMPLEADO') IS NOT NULL
            SET @MAIL_MODE='ID_EMPLEADO';
    END;
 
    DECLARE
        @SQL_CRUD NVARCHAR(MAX)='',
        @RC INT=0,
        @NEXISTS INT=0,
        @EXEC_PRINCIPAL VARCHAR(2)='NO',
        @EXEC_T17 VARCHAR(2000)=NULL,
        @EXEC_T13 VARCHAR(1000)=NULL,
        @EXEC_EMAIL VARCHAR(1000)=NULL,
        @EXEC_EMAIL_OBS VARCHAR(1000)=NULL,
        @EXEC_NOMBRE_COMPLETO VARCHAR(320)='';
 
    SET @EXEC_NOMBRE_COMPLETO=LOWER(ISNULL(@NOMBRE_COMPLETO,''));
 
    /* ============================================================
       6. ELIMINAR
       ============================================================ */
    IF @VFORM_DELETE='1'
    BEGIN
        SET @VFORM_ERROR='';
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para eliminar datos del empleado.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibió el registro a eliminar.';
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_MODE='NONE'
                SET @VFORM_ERROR='La tabla de domicilios todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @DOM_MODE
                    WHEN 'GENERIC' THEN
                        N'DELETE FROM dbo.VCT_DOMICILIOS
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'DELETE FROM dbo.VCT_DOMICILIOS
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'DELETE FROM dbo.VCT_DOMICILIOS
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al empleado.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='TELEFONO'
        BEGIN
            SET @ACTIVE_TAB='telefonos';
 
            IF @TEL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de teléfonos todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @TEL_MODE
                    WHEN 'GENERIC' THEN
                        N'DELETE FROM dbo.VCT_TELEFONOS
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'DELETE FROM dbo.VCT_TELEFONOS
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'DELETE FROM dbo.VCT_TELEFONOS
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El teléfono seleccionado ya no existe o no pertenece al empleado.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL'
        BEGIN
            SET @ACTIVE_TAB='email';
 
            IF @MAIL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de emails todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @MAIL_MODE
                    WHEN 'GENERIC' THEN
                        N'DELETE FROM dbo.VCT_EMAILS
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'DELETE FROM dbo.VCT_EMAILS
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'DELETE FROM dbo.VCT_EMAILS
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al empleado.';
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
            SET @VFORM_ERROR='No posee permisos para modificar datos del empleado.';
        ELSE IF NULLIF(@VFORM_ROW_ID,'') IS NULL
            SET @VFORM_ERROR='No se recibió el registro a marcar como principal.';
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_MODE='NONE'
                SET @VFORM_ERROR='La tabla de domicilios todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @DOM_MODE
                    WHEN 'GENERIC' THEN
                        N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;
                          UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''SI''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                          WHERE IDEMPLEADO=@PID;
                          UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''SI''
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                          WHERE ID_EMPLEADO=@PID;
                          UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''SI''
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El domicilio seleccionado ya no existe o no pertenece al empleado.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='TELEFONO'
        BEGIN
            SET @ACTIVE_TAB='telefonos';
 
            IF @TEL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de teléfonos todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @TEL_MODE
                    WHEN 'GENERIC' THEN
                        N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;
                          UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''SI''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                          WHERE IDEMPLEADO=@PID;
                          UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''SI''
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                          WHERE ID_EMPLEADO=@PID;
                          UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''SI''
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El teléfono seleccionado ya no existe o no pertenece al empleado.';
            END;
        END;
 
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='EMAIL'
        BEGIN
            SET @ACTIVE_TAB='email';
 
            IF @MAIL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de emails todavía no posee una relación con Empleados.';
            ELSE
            BEGIN
                SET @SQL_CRUD=
                    CASE @MAIL_MODE
                    WHEN 'GENERIC' THEN
                        N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;
                          UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''SI''
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    WHEN 'IDEMPLEADO' THEN
                        N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                          WHERE IDEMPLEADO=@PID;
                          UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''SI''
                          WHERE IDEMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    ELSE
                        N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                          WHERE ID_EMPLEADO=@PID;
                          UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''SI''
                          WHERE ID_EMPLEADO=@PID
                            AND CONVERT(VARCHAR(100),ID)=@RID;
                          SET @ORC=@@ROWCOUNT;'
                    END;
 
                SET @RC=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@ORC INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@ORC=@RC OUTPUT;
 
                IF @RC=0
                    SET @VFORM_ERROR='El email seleccionado ya no existe o no pertenece al empleado.';
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
        SET @EXEC_T17=NULLIF(LTRIM(RTRIM(@VFORM_T17)),'');
        SET @EXEC_T13=NULLIF(LTRIM(RTRIM(@VFORM_T13)),'');
        SET @EXEC_EMAIL=LTRIM(RTRIM(ISNULL(@VFORM_T11,'')));
        SET @EXEC_EMAIL_OBS=NULLIF(LTRIM(RTRIM(@VFORM_T12)),'');
 
        IF @CAN_EDIT=0
            SET @VFORM_ERROR='No posee permisos para modificar datos del empleado.';
 
        /* ---------------- DOMICILIO ---------------- */
        IF @VFORM_ERROR='' AND @VFORM_ENTITY='DOMICILIO'
        BEGIN
            SET @ACTIVE_TAB='domicilio';
 
            IF @DOM_MODE='NONE'
                SET @VFORM_ERROR='La tabla de domicilios todavía no posee una relación con Empleados.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='La calle es obligatoria.';
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
                WHERE CD.PAR_KEY=
                (
                    SELECT TOP 1 PKEY
                    FROM dbo.CAT_TYPE WITH(NOLOCK)
                    WHERE CAT_TYPE_CODE='Provincia'
                )
                  AND CD.CAT_DATA_CODE COLLATE DATABASE_DEFAULT=
                      LTRIM(RTRIM(@VFORM_T16)) COLLATE DATABASE_DEFAULT
            )
                SET @VFORM_ERROR='La provincia seleccionada no es válida.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    SET @SQL_CRUD=
                        CASE @DOM_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                              WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                              WHERE IDEMPLEADO=@PID;'
                        ELSE
                            N'UPDATE dbo.VCT_DOMICILIOS SET PRINCIPAL=''NO''
                              WHERE ID_EMPLEADO=@PID;'
                        END;
 
                    EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    SET @SQL_CRUD=
                        CASE @DOM_MODE
                        WHEN 'GENERIC' THEN
                            N'INSERT INTO dbo.VCT_DOMICILIOS
                              (TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (''EMPLEADO'',@PID,@P11,@P12,@P13,@P14,@P15,@P16,@PPR,@P17);'
                        WHEN 'IDEMPLEADO' THEN
                            N'INSERT INTO dbo.VCT_DOMICILIOS
                              (IDEMPLEADO,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@P12,@P13,@P14,@P15,@P16,@PPR,@P17);'
                        ELSE
                            N'INSERT INTO dbo.VCT_DOMICILIOS
                              (ID_EMPLEADO,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@P12,@P13,@P14,@P15,@P16,@PPR,@P17);'
                        END;
 
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@P11 VARCHAR(1000),@P12 VARCHAR(1000),@P13 VARCHAR(1000),
                           @P14 VARCHAR(1000),@P15 VARCHAR(1000),@P16 VARCHAR(1000),
                           @PPR VARCHAR(2),@P17 VARCHAR(2000)',
                         @PID=@ID_EMPLEADO,@P11=@VFORM_T11,@P12=@VFORM_T12,
                         @P13=@VFORM_T13,@P14=@VFORM_T14,@P15=@VFORM_T15,
                         @P16=@VFORM_T16,
                         @PPR=@EXEC_PRINCIPAL,
                         @P17=@EXEC_T17;
                END
                ELSE
                BEGIN
                    SET @SQL_CRUD=
                        CASE @DOM_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_DOMICILIOS
                                 SET CALLE=@P11,NRO=@P12,PISO=@P13,DEPTO=@P14,
                                     LOCALIDAD=@P15,PROVINCIA=@P16,PRINCIPAL=@PPR,
                                     OBSERVACIONES=@P17
                               WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_DOMICILIOS
                                 SET CALLE=@P11,NRO=@P12,PISO=@P13,DEPTO=@P14,
                                     LOCALIDAD=@P15,PROVINCIA=@P16,PRINCIPAL=@PPR,
                                     OBSERVACIONES=@P17
                               WHERE IDEMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        ELSE
                            N'UPDATE dbo.VCT_DOMICILIOS
                                 SET CALLE=@P11,NRO=@P12,PISO=@P13,DEPTO=@P14,
                                     LOCALIDAD=@P15,PROVINCIA=@P16,PRINCIPAL=@PPR,
                                     OBSERVACIONES=@P17
                               WHERE ID_EMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        END;
 
                    SET @RC=0;
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@RID VARCHAR(100),@P11 VARCHAR(1000),@P12 VARCHAR(1000),
                           @P13 VARCHAR(1000),@P14 VARCHAR(1000),@P15 VARCHAR(1000),
                           @P16 VARCHAR(1000),@PPR VARCHAR(2),@P17 VARCHAR(2000),
                           @ORC INT OUTPUT',
                         @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,
                         @P11=@VFORM_T11,@P12=@VFORM_T12,@P13=@VFORM_T13,
                         @P14=@VFORM_T14,@P15=@VFORM_T15,@P16=@VFORM_T16,
                         @PPR=@EXEC_PRINCIPAL,
                         @P17=@EXEC_T17,
                         @ORC=@RC OUTPUT;
 
                    IF @RC=0
                        SET @VFORM_ERROR='El domicilio a editar ya no existe o no pertenece al empleado.';
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
 
            IF @TEL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de teléfonos todavía no posee una relación con Empleados.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El código de área es obligatorio.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T12)),'') IS NULL
                SET @VFORM_ERROR='El número es obligatorio.';
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    SET @SQL_CRUD=
                        CASE @TEL_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                              WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                              WHERE IDEMPLEADO=@PID;'
                        ELSE
                            N'UPDATE dbo.VCT_TELEFONOS SET PRINCIPAL=''NO''
                              WHERE ID_EMPLEADO=@PID;'
                        END;
 
                    EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    SET @SQL_CRUD=
                        CASE @TEL_MODE
                        WHEN 'GENERIC' THEN
                            N'INSERT INTO dbo.VCT_TELEFONOS
                              (TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (''EMPLEADO'',@PID,@P11,@P12,@PPR,@P13);'
                        WHEN 'IDEMPLEADO' THEN
                            N'INSERT INTO dbo.VCT_TELEFONOS
                              (IDEMPLEADO,CODAREA,NRO,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@P12,@PPR,@P13);'
                        ELSE
                            N'INSERT INTO dbo.VCT_TELEFONOS
                              (ID_EMPLEADO,CODAREA,NRO,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@P12,@PPR,@P13);'
                        END;
 
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@P11 VARCHAR(1000),@P12 VARCHAR(1000),
                           @PPR VARCHAR(2),@P13 VARCHAR(1000)',
                         @PID=@ID_EMPLEADO,@P11=@VFORM_T11,@P12=@VFORM_T12,
                         @PPR=@EXEC_PRINCIPAL,
                         @P13=@EXEC_T13;
                END
                ELSE
                BEGIN
                    SET @SQL_CRUD=
                        CASE @TEL_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_TELEFONOS
                                 SET CODAREA=@P11,NRO=@P12,PRINCIPAL=@PPR,OBSERVACIONES=@P13
                               WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_TELEFONOS
                                 SET CODAREA=@P11,NRO=@P12,PRINCIPAL=@PPR,OBSERVACIONES=@P13
                               WHERE IDEMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        ELSE
                            N'UPDATE dbo.VCT_TELEFONOS
                                 SET CODAREA=@P11,NRO=@P12,PRINCIPAL=@PPR,OBSERVACIONES=@P13
                               WHERE ID_EMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        END;
 
                    SET @RC=0;
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@RID VARCHAR(100),@P11 VARCHAR(1000),@P12 VARCHAR(1000),
                           @PPR VARCHAR(2),@P13 VARCHAR(1000),@ORC INT OUTPUT',
                         @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,
                         @P11=@VFORM_T11,@P12=@VFORM_T12,
                         @PPR=@EXEC_PRINCIPAL,
                         @P13=@EXEC_T13,
                         @ORC=@RC OUTPUT;
 
                    IF @RC=0
                        SET @VFORM_ERROR='El teléfono a editar ya no existe o no pertenece al empleado.';
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
 
            IF @MAIL_MODE='NONE'
                SET @VFORM_ERROR='La tabla de emails todavía no posee una relación con Empleados.';
            ELSE IF NULLIF(LTRIM(RTRIM(@VFORM_T11)),'') IS NULL
                SET @VFORM_ERROR='El email es obligatorio.';
            ELSE IF LTRIM(RTRIM(@VFORM_T11)) NOT LIKE '%_@_%._%'
                SET @VFORM_ERROR='El email no tiene un formato válido.';
 
            IF @VFORM_ERROR=''
            BEGIN
                SET @SQL_CRUD=
                    CASE @MAIL_MODE
                    WHEN 'GENERIC' THEN
                        N'SELECT @ON=COUNT(*) FROM dbo.VCT_EMAILS
                          WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                            AND LOWER(LTRIM(RTRIM(ISNULL(EMAIL,''''))))=LOWER(LTRIM(RTRIM(@PEMAIL)))
                            AND (@RID='''' OR CONVERT(VARCHAR(100),ID)<>@RID);'
                    WHEN 'IDEMPLEADO' THEN
                        N'SELECT @ON=COUNT(*) FROM dbo.VCT_EMAILS
                          WHERE IDEMPLEADO=@PID
                            AND LOWER(LTRIM(RTRIM(ISNULL(EMAIL,''''))))=LOWER(LTRIM(RTRIM(@PEMAIL)))
                            AND (@RID='''' OR CONVERT(VARCHAR(100),ID)<>@RID);'
                    ELSE
                        N'SELECT @ON=COUNT(*) FROM dbo.VCT_EMAILS
                          WHERE ID_EMPLEADO=@PID
                            AND LOWER(LTRIM(RTRIM(ISNULL(EMAIL,''''))))=LOWER(LTRIM(RTRIM(@PEMAIL)))
                            AND (@RID='''' OR CONVERT(VARCHAR(100),ID)<>@RID);'
                    END;
 
                SET @NEXISTS=0;
                EXEC sp_executesql
                     @SQL_CRUD,
                     N'@PID INT,@RID VARCHAR(100),@PEMAIL VARCHAR(1000),@ON INT OUTPUT',
                     @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,@PEMAIL=@VFORM_T11,
                     @ON=@NEXISTS OUTPUT;
 
                IF @NEXISTS>0
                    SET @VFORM_ERROR='El empleado ya posee ese email registrado.';
            END;
 
            IF @VFORM_ERROR=''
            BEGIN TRY
                IF @VFORM_FLAG02='1'
                BEGIN
                    SET @SQL_CRUD=
                        CASE @MAIL_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                              WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                              WHERE IDEMPLEADO=@PID;'
                        ELSE
                            N'UPDATE dbo.VCT_EMAILS SET PRINCIPAL=''NO''
                              WHERE ID_EMPLEADO=@PID;'
                        END;
 
                    EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
                END;
 
                IF @VFORM_ROW_ID=''
                BEGIN
                    SET @SQL_CRUD=
                        CASE @MAIL_MODE
                        WHEN 'GENERIC' THEN
                            N'INSERT INTO dbo.VCT_EMAILS
                              (TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (''EMPLEADO'',@PID,@P11,@PPR,@P12);'
                        WHEN 'IDEMPLEADO' THEN
                            N'INSERT INTO dbo.VCT_EMAILS
                              (IDEMPLEADO,EMAIL,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@PPR,@P12);'
                        ELSE
                            N'INSERT INTO dbo.VCT_EMAILS
                              (ID_EMPLEADO,EMAIL,PRINCIPAL,OBSERVACIONES)
                              VALUES
                              (@PID,@P11,@PPR,@P12);'
                        END;
 
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@P11 VARCHAR(1000),@PPR VARCHAR(2),@P12 VARCHAR(1000)',
                         @PID=@ID_EMPLEADO,@P11=@EXEC_EMAIL,
                         @PPR=@EXEC_PRINCIPAL,
                         @P12=@EXEC_EMAIL_OBS;
                END
                ELSE
                BEGIN
                    SET @SQL_CRUD=
                        CASE @MAIL_MODE
                        WHEN 'GENERIC' THEN
                            N'UPDATE dbo.VCT_EMAILS
                                 SET EMAIL=@P11,PRINCIPAL=@PPR,OBSERVACIONES=@P12
                               WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        WHEN 'IDEMPLEADO' THEN
                            N'UPDATE dbo.VCT_EMAILS
                                 SET EMAIL=@P11,PRINCIPAL=@PPR,OBSERVACIONES=@P12
                               WHERE IDEMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        ELSE
                            N'UPDATE dbo.VCT_EMAILS
                                 SET EMAIL=@P11,PRINCIPAL=@PPR,OBSERVACIONES=@P12
                               WHERE ID_EMPLEADO=@PID
                                 AND CONVERT(VARCHAR(100),ID)=@RID;
                              SET @ORC=@@ROWCOUNT;'
                        END;
 
                    SET @RC=0;
                    EXEC sp_executesql
                         @SQL_CRUD,
                         N'@PID INT,@RID VARCHAR(100),@P11 VARCHAR(1000),
                           @PPR VARCHAR(2),@P12 VARCHAR(1000),@ORC INT OUTPUT',
                         @PID=@ID_EMPLEADO,@RID=@VFORM_ROW_ID,
                         @P11=@EXEC_EMAIL,
                         @PPR=@EXEC_PRINCIPAL,
                         @P12=@EXEC_EMAIL_OBS,
                         @ORC=@RC OUTPUT;
 
                    IF @RC=0
                        SET @VFORM_ERROR='El email a editar ya no existe o no pertenece al empleado.';
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
        LOCALIDAD VARCHAR(100),
        PROVINCIA VARCHAR(100),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1000)
    );
 
    IF OBJECT_ID('tempdb..#TELEFONOS360') IS NOT NULL DROP TABLE #TELEFONOS360;
    CREATE TABLE #TELEFONOS360
    (
        ID INT,
        CODAREA VARCHAR(50),
        NRO VARCHAR(50),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1000)
    );
 
    IF OBJECT_ID('tempdb..#EMAILS360') IS NOT NULL DROP TABLE #EMAILS360;
    CREATE TABLE #EMAILS360
    (
        ID INT,
        EMAIL VARCHAR(300),
        PRINCIPAL VARCHAR(10),
        OBSERVACIONES VARCHAR(1000)
    );
 
    IF @DOM_MODE<>'NONE'
    BEGIN
        SET @SQL_CRUD=
            CASE @DOM_MODE
            WHEN 'GENERIC' THEN
                N'INSERT INTO #DOMICILIOS360
                  SELECT ID,CONVERT(VARCHAR(300),CALLE),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(50),PISO),CONVERT(VARCHAR(50),DEPTO),
                         CONVERT(VARCHAR(100),LOCALIDAD),CONVERT(VARCHAR(100),PROVINCIA),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
                   WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
            WHEN 'IDEMPLEADO' THEN
                N'INSERT INTO #DOMICILIOS360
                  SELECT ID,CONVERT(VARCHAR(300),CALLE),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(50),PISO),CONVERT(VARCHAR(50),DEPTO),
                         CONVERT(VARCHAR(100),LOCALIDAD),CONVERT(VARCHAR(100),PROVINCIA),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
                   WHERE IDEMPLEADO=@PID;'
            ELSE
                N'INSERT INTO #DOMICILIOS360
                  SELECT ID,CONVERT(VARCHAR(300),CALLE),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(50),PISO),CONVERT(VARCHAR(50),DEPTO),
                         CONVERT(VARCHAR(100),LOCALIDAD),CONVERT(VARCHAR(100),PROVINCIA),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_DOMICILIOS WITH(NOLOCK)
                   WHERE ID_EMPLEADO=@PID;'
            END;
 
        EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
    END;
 
    IF @TEL_MODE<>'NONE'
    BEGIN
        SET @SQL_CRUD=
            CASE @TEL_MODE
            WHEN 'GENERIC' THEN
                N'INSERT INTO #TELEFONOS360
                  SELECT ID,CONVERT(VARCHAR(50),CODAREA),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
                   WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
            WHEN 'IDEMPLEADO' THEN
                N'INSERT INTO #TELEFONOS360
                  SELECT ID,CONVERT(VARCHAR(50),CODAREA),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
                   WHERE IDEMPLEADO=@PID;'
            ELSE
                N'INSERT INTO #TELEFONOS360
                  SELECT ID,CONVERT(VARCHAR(50),CODAREA),CONVERT(VARCHAR(50),NRO),
                         CONVERT(VARCHAR(10),PRINCIPAL),CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_TELEFONOS WITH(NOLOCK)
                   WHERE ID_EMPLEADO=@PID;'
            END;
 
        EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
    END;
 
    IF @MAIL_MODE<>'NONE'
    BEGIN
        SET @SQL_CRUD=
            CASE @MAIL_MODE
            WHEN 'GENERIC' THEN
                N'INSERT INTO #EMAILS360
                  SELECT ID,CONVERT(VARCHAR(300),EMAIL),CONVERT(VARCHAR(10),PRINCIPAL),
                         CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_EMAILS WITH(NOLOCK)
                   WHERE TIPO_ENTIDAD=''EMPLEADO'' AND ID_ENTIDAD=@PID;'
            WHEN 'IDEMPLEADO' THEN
                N'INSERT INTO #EMAILS360
                  SELECT ID,CONVERT(VARCHAR(300),EMAIL),CONVERT(VARCHAR(10),PRINCIPAL),
                         CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_EMAILS WITH(NOLOCK)
                   WHERE IDEMPLEADO=@PID;'
            ELSE
                N'INSERT INTO #EMAILS360
                  SELECT ID,CONVERT(VARCHAR(300),EMAIL),CONVERT(VARCHAR(10),PRINCIPAL),
                         CONVERT(VARCHAR(1000),OBSERVACIONES)
                    FROM dbo.VCT_EMAILS WITH(NOLOCK)
                   WHERE ID_EMPLEADO=@PID;'
            END;
 
        EXEC sp_executesql @SQL_CRUD,N'@PID INT',@PID=@ID_EMPLEADO;
    END;
 
    DECLARE
        @DomiciliosCount INT=0,
        @TelefonosCount INT=0,
        @EmailsCount INT=0;
 
    SELECT @DomiciliosCount=COUNT(*) FROM #DOMICILIOS360;
    SELECT @TelefonosCount=COUNT(*) FROM #TELEFONOS360;
    SELECT @EmailsCount=COUNT(*) FROM #EMAILS360;
 
    /* ============================================================
       10. PROYECTOS RELACIONADOS AL EMPLEADO - RELACION CANONICA
       ------------------------------------------------------------
       La Vista 360 muestra exclusivamente proyectos relacionados
       al empleado seleccionado mediante la vista canonica de actores.
       Se incorpora el cliente del proyecto para mantener el mismo
       criterio visual y funcional que Consultor 360.
       ============================================================ */
    IF OBJECT_ID('tempdb..#PROYECTOS360') IS NOT NULL DROP TABLE #PROYECTOS360;
 
    CREATE TABLE #PROYECTOS360
    (
        ID INT,
        ID_CLIENTE INT,
        CODIGO VARCHAR(100),
        NOMBRE VARCHAR(300),
        REFERENCIA VARCHAR(300),
        CLIENTE_NOMBRE VARCHAR(300),
        ESTADO_CODIGO VARCHAR(50),
        ESTADO VARCHAR(100),
        FECHA_INICIO DATETIME,
        FECHA_FIN DATETIME,
        PORCENTAJE_AVANCE INT,
        RELACION VARCHAR(150)
    );
 
    INSERT INTO #PROYECTOS360
    (
        ID,ID_CLIENTE,CODIGO,NOMBRE,REFERENCIA,CLIENTE_NOMBRE,
        ESTADO_CODIGO,ESTADO,FECHA_INICIO,FECHA_FIN,
        PORCENTAJE_AVANCE,RELACION
    )
    SELECT
        P.ID,
        P.IDCLIENTE,
        CONVERT(VARCHAR(100),P.CODIGO),
        CONVERT(VARCHAR(300),P.NOMBRE),
        CONVERT(VARCHAR(300),P.REFERENCIA),
        CONVERT(VARCHAR(300),ISNULL(NULLIF(C.RAZON_SOCIAL,''),'Sin cliente')),
        PE.CODIGO,
        PE.DESCRIPCION,
        P.FECHA_INICIO,
        P.FECHA_FIN,
        ISNULL(P.PORCENTAJE_AVANCE,0),
        ISNULL
        (
            (
                SELECT TOP 1 A.RELACION
                FROM dbo.VCT_VW_PROYECTOS_ACTORES A WITH(NOLOCK)
                WHERE A.ID_PROYECTO=P.ID
                  AND A.TIPO_ENTIDAD='EMPLEADO'
                  AND A.ID_ENTIDAD=@ID_EMPLEADO
                ORDER BY A.PRIORIDAD_FUENTE,A.RELACION
            ),
            'Empleado'
        )
    FROM dbo.VCT_PROYECTOS P WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ESTADOS PE WITH(NOLOCK)
        ON PE.ID=P.ID_ESTADO
    LEFT JOIN dbo.VCT_CLIENTES C WITH(NOLOCK)
        ON C.ID=P.IDCLIENTE
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.VCT_VW_PROYECTOS_ACTORES A WITH(NOLOCK)
        WHERE A.ID_PROYECTO=P.ID
          AND A.TIPO_ENTIDAD='EMPLEADO'
          AND A.ID_ENTIDAD=@ID_EMPLEADO
    );
 
    DECLARE
        @ProyectosCount INT=0,
        @ProyectosEnCurso INT=0,
        @ProyectosActivos INT=0,
        @ProyectosActivosPct INT=0,
        @ClientesAsignados INT=0;
 
    SELECT
        @ProyectosCount=COUNT(*),
        @ProyectosEnCurso=ISNULL(SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN 1 ELSE 0 END),0),
        @ProyectosActivos=ISNULL(SUM(CASE WHEN ESTADO_CODIGO IN ('ENCURSO','CONFIRMADO','PAUSADO') THEN 1 ELSE 0 END),0)
    FROM #PROYECTOS360;
 
    SELECT @ClientesAsignados=COUNT(DISTINCT ID_CLIENTE)
    FROM #PROYECTOS360
    WHERE ID_CLIENTE IS NOT NULL;
 
    IF @ProyectosCount>0
        SET @ProyectosActivosPct=(@ProyectosActivos*100)/@ProyectosCount;
 
    /* ============================================================
       11. GESTIONES DEL EMPLEADO - RELACION CANONICA
       ------------------------------------------------------------
       La gestion pertenece al empleado cuando figura como
       participante activo. Todo queda filtrado por @ID_EMPLEADO.
       ============================================================ */
    IF OBJECT_ID('tempdb..#GESTIONES360') IS NOT NULL DROP TABLE #GESTIONES360;
 
    CREATE TABLE #GESTIONES360
    (
        ID INT,
        FECHA DATETIME,
        PROYECTO_CODIGO VARCHAR(100),
        PROYECTO_NOMBRE VARCHAR(300),
        PROYECTO_REFERENCIA VARCHAR(300),
        CLIENTE_NOMBRE VARCHAR(300),
        TITULO VARCHAR(300),
        TIPO VARCHAR(200),
        SUBTIPO VARCHAR(200),
        RESULTADO VARCHAR(300),
        RESPONSABLE VARCHAR(320),
        VENCIMIENTO DATETIME,
        ESTADO_CODIGO VARCHAR(50),
        ESTADO VARCHAR(100),
        ES_FINAL BIT
    );
 
    INSERT INTO #GESTIONES360
    (
        ID,FECHA,PROYECTO_CODIGO,PROYECTO_NOMBRE,PROYECTO_REFERENCIA,
        CLIENTE_NOMBRE,TITULO,TIPO,SUBTIPO,RESULTADO,RESPONSABLE,
        VENCIMIENTO,ESTADO_CODIGO,ESTADO,ES_FINAL
    )
    SELECT
        G.ID,
        ISNULL(G.FECHA_CIERRE,ISNULL(G.FECHA_INICIO,G.FECHA_CREACION)),
        CONVERT(VARCHAR(100),P.CODIGO),
        CONVERT(VARCHAR(300),P.NOMBRE),
        CONVERT(VARCHAR(300),P.REFERENCIA),
        CONVERT(VARCHAR(300),ISNULL(NULLIF(C.RAZON_SOCIAL,''),'Sin cliente')),
        CONVERT(VARCHAR(300),ISNULL(NULLIF(G.TITULO,''),'Gestión')),
        CONVERT(VARCHAR(200),ISNULL(T.DESCRIPCION,ISNULL(T.CODIGO,''))),
        CONVERT(VARCHAR(200),ISNULL(ST.DESCRIPCION,ISNULL(ST.CODIGO,''))),
        CONVERT(VARCHAR(300),ISNULL(RS.DESCRIPCION,ISNULL(RS.CODIGO,''))),
        CONVERT(VARCHAR(320),ISNULL(GR.NOMBRE,'-')),
        G.FECHA_VENCIMIENTO,
        GE.CODIGO,
        GE.DESCRIPCION,
        ISNULL(GE.ES_FINAL,0)
    FROM dbo.VCT_GESTIONES G WITH(NOLOCK)
    LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK)
        ON P.ID=G.ID_PROYECTO
    LEFT JOIN dbo.VCT_CLIENTES C WITH(NOLOCK)
        ON C.ID=P.IDCLIENTE
    LEFT JOIN dbo.VCT_PRM_GESTIONES_TIPOS T WITH(NOLOCK)
        ON T.ID=G.ID_TIPO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_SUBTIPOS ST WITH(NOLOCK)
        ON ST.ID=G.ID_SUBTIPO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_RESULTADOS RS WITH(NOLOCK)
        ON RS.ID=G.ID_RESULTADO
    LEFT JOIN dbo.VCT_PRM_GESTIONES_ESTADOS GE WITH(NOLOCK)
        ON GE.ID=G.ID_ESTADO
    LEFT JOIN dbo.VCT_VW_GESTIONES_RESPONSABLES GR WITH(NOLOCK)
        ON GR.ID_GESTION=G.ID
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.VCT_GESTIONES_PARTICIPANTES GP WITH(NOLOCK)
        WHERE GP.ID_GESTION=G.ID
          AND GP.TIPO_ENTIDAD='EMPLEADO'
          AND GP.ID_ENTIDAD=@ID_EMPLEADO
          AND GP.ESTADO='ACTIVO'
    );
 
    DECLARE
        @GestionesCount INT=0,
        @GestionesAnio INT=0,
        @UltimaGestionFecha DATETIME=NULL,
        @UltimaGestionFechaTxt VARCHAR(20)='-',
        @DocumentosCount INT=0;
 
    SELECT
        @GestionesCount=COUNT(*),
        @GestionesAnio=ISNULL
        (
            SUM(CASE WHEN FECHA IS NOT NULL AND YEAR(FECHA)=YEAR(GETDATE()) THEN 1 ELSE 0 END),
            0
        ),
        @UltimaGestionFecha=MAX(FECHA)
    FROM #GESTIONES360;
 
    IF @UltimaGestionFecha IS NOT NULL
        SET @UltimaGestionFechaTxt=CONVERT(VARCHAR(10),@UltimaGestionFecha,103);
 
    /* ============================================================
       12. FOOTER GENERICO
       ============================================================ */
    DECLARE @HTML_GRID_FOOTER VARCHAR(MAX)=
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
       13. HTML PROYECTOS
       ============================================================ */
    DECLARE
        @HTML_PROYECTOS VARCHAR(MAX)='',
        @HTML_PROYECTOS_TOP VARCHAR(MAX)='';
 
    SELECT @HTML_PROYECTOS=ISNULL((
        SELECT
            '<tr data-vct-row>' +
                '<td data-label="Cliente" class="vct-360-cell-client" style="width:20% !important;">'+
                    '<span class="vct-360-project-name">'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(P.CLIENTE_NOMBRE,''),'Sin cliente'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                    '</span>'+
                '</td>'+
                '<td data-label="Proyecto" style="width:42% !important;text-align:left !important;">' +
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
                CASE WHEN ISNULL(P.RELACION,'')<>''
                     THEN '<span class="vct-360-project-ref">Rol: '+
                          REPLACE(REPLACE(REPLACE(REPLACE(P.RELACION,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                          '</span>'
                     ELSE '' END+
                '</td>'+
                '<td class="vct-text-center" data-label="Estado" style="width:10% !important;">'+
                    '<span class="vct-360-badge '+
                    CASE
                        WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'is-progress'
                        WHEN P.ESTADO_CODIGO='TERMINADO' THEN 'is-done'
                        WHEN P.ESTADO_CODIGO='CANCELADO' THEN 'is-cancel'
                        ELSE 'is-neutral'
                    END+'">'+
                    REPLACE(REPLACE(REPLACE(
                        CASE WHEN P.ESTADO_CODIGO='ENCURSO'
                             THEN 'EN CURSO'
                             ELSE ISNULL(NULLIF(P.ESTADO,''),'Sin estado') END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;')+
                    '</span>'+
                '</td>'+
                '<td class="vct-text-center" data-label="Inicio" style="width:9% !important;">'+
                    CASE WHEN P.FECHA_INICIO IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_INICIO,103) END+
                '</td>'+
                '<td class="vct-text-center" data-label="Fin" style="width:9% !important;">'+
                    CASE WHEN P.FECHA_FIN IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_FIN,103) END+
                '</td>'+
                '<td class="vct-text-center" data-label="Avance" data-vct-sort-value="'+CONVERT(VARCHAR(5),ISNULL(P.PORCENTAJE_AVANCE,0))+'" style="width:10% !important;">'+
                    '<div class="vct-360-progress"><div class="vct-360-progress-bar" style="background:#66062D !important;width:'+
                    CONVERT(VARCHAR(5),
                        CASE
                            WHEN ISNULL(P.PORCENTAJE_AVANCE,0)<0 THEN 0
                            WHEN ISNULL(P.PORCENTAJE_AVANCE,0)>100 THEN 100
                            ELSE ISNULL(P.PORCENTAJE_AVANCE,0)
                        END
                    )+'%;"></div></div>'+
                    '<span class="vct-360-progress-label">'+
                    CONVERT(VARCHAR(5),ISNULL(P.PORCENTAJE_AVANCE,0))+'%</span>'+
                '</td>'+
            '</tr>'
        FROM #PROYECTOS360 P
        ORDER BY
            CASE WHEN P.FECHA_INICIO IS NULL THEN 1 ELSE 0 END,
            P.FECHA_INICIO DESC,
            P.ID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_PROYECTOS=''
        SET @HTML_PROYECTOS=
            '<div class="vct-360-empty vct-360-fixed-empty">El empleado no posee proyectos relacionados.</div>';
    ELSE
        SET @HTML_PROYECTOS=
            '<div data-vct-dg data-vct-dg-id="v360_emp_proyectos" data-vct-dg-title="Proyectos del empleado" data-vct-dg-subtitle="Empleado: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="proyecto(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar proyecto, cliente..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-width="20%" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="9%" data-vct-sort="inicio" data-vct-sortable="true" data-vct-sort-type="date"><span>Inicio</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="9%" data-vct-sort="fin" data-vct-sortable="true" data-vct-sort-type="date"><span>Fin</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="10%" data-vct-sort="avance" data-vct-sortable="true" data-vct-sort-type="number"><span>Avance</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>'+
            '<tbody>'+@HTML_PROYECTOS+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_PROYECTOS_TOP=ISNULL((
        SELECT TOP 5
            '<tr>'+
                '<td class="vct-360-cell-client" style="width:20% !important;"><span class="vct-360-project-name">'+
                    REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(P.CLIENTE_NOMBRE,''),'Sin cliente'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                '</span></td>'+
                '<td style="width:42% !important;text-align:left !important;"><span class="vct-360-project-name">('+
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.CODIGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                ') '+
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(P.NOMBRE,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                '</span>'+
                CASE WHEN ISNULL(P.REFERENCIA,'')<>''
                     THEN '<span class="vct-360-project-ref">'+
                          REPLACE(REPLACE(REPLACE(REPLACE(P.REFERENCIA,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                          '</span>'
                     ELSE '' END+
                CASE WHEN ISNULL(P.RELACION,'')<>''
                     THEN '<span class="vct-360-project-ref">Rol: '+
                          REPLACE(REPLACE(REPLACE(REPLACE(P.RELACION,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+
                          '</span>'
                     ELSE '' END+
                '</td>'+
                '<td class="vct-text-center" style="width:10% !important;"><span class="vct-360-badge '+
                    CASE
                        WHEN P.ESTADO_CODIGO='ENCURSO' THEN 'is-progress'
                        WHEN P.ESTADO_CODIGO='TERMINADO' THEN 'is-done'
                        ELSE 'is-neutral'
                    END+'">'+
                    REPLACE(REPLACE(REPLACE(
                        CASE WHEN P.ESTADO_CODIGO='ENCURSO'
                             THEN 'EN CURSO'
                             ELSE ISNULL(NULLIF(P.ESTADO,''),'Sin estado') END,
                        '&','&amp;'),'<','&lt;'),'>','&gt;')+
                '</span></td>'+
                '<td class="vct-text-center" style="width:9% !important;">'+
                    CASE WHEN P.FECHA_INICIO IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_INICIO,103) END+
                '</td>'+
                '<td class="vct-text-center" style="width:9% !important;">'+
                    CASE WHEN P.FECHA_FIN IS NULL THEN '-' ELSE CONVERT(VARCHAR(10),P.FECHA_FIN,103) END+
                '</td>'+
                '<td class="vct-text-center" style="width:10% !important;">'+
                    '<div class="vct-360-progress"><div class="vct-360-progress-bar" style="background:#66062D !important;width:'+
                    CONVERT(VARCHAR(5),
                        CASE
                            WHEN ISNULL(P.PORCENTAJE_AVANCE,0)<0 THEN 0
                            WHEN ISNULL(P.PORCENTAJE_AVANCE,0)>100 THEN 100
                            ELSE ISNULL(P.PORCENTAJE_AVANCE,0)
                        END
                    )+'%;"></div></div>'+
                    '<span class="vct-360-progress-label">'+
                    CONVERT(VARCHAR(5),ISNULL(P.PORCENTAJE_AVANCE,0))+'%</span>'+
                '</td>'+
            '</tr>'
        FROM #PROYECTOS360 P
        ORDER BY
            CASE WHEN P.FECHA_INICIO IS NULL THEN 1 ELSE 0 END,
            P.FECHA_INICIO DESC,
            P.ID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_PROYECTOS_TOP=''
        SET @HTML_PROYECTOS_TOP=
            '<div class="vct-360-empty vct-360-fixed-empty">El empleado no posee proyectos relacionados.</div>';
    ELSE
        SET @HTML_PROYECTOS_TOP=
            '<div class="vct-360-grid-fixed vct-360-grid-five vct-360-projects-recent">'+
                '<table class="vct-360-table vct-360-project-table vct-360-project-table-recent vct-360-project-table-recent-consultor" style="width:100% !important;min-width:0 !important;table-layout:fixed !important;">'+
                    '<colgroup><col style="width:20%"><col style="width:42%"><col style="width:10%"><col style="width:9%"><col style="width:9%"><col style="width:10%"></colgroup>'+ 
                    '<thead><tr>'+
                        '<th style="width:20% !important;">Cliente</th>'+
                        '<th style="width:42% !important;text-align:left !important;">Proyecto</th>'+
                        '<th class="vct-text-center" style="width:10% !important;">Estado</th>'+
                        '<th class="vct-text-center" style="width:9% !important;">Inicio</th>'+
                        '<th class="vct-text-center" style="width:9% !important;">Fin</th>'+
                        '<th class="vct-text-center" style="width:10% !important;">Avance</th>'+
                    '</tr></thead>'+
                    '<tbody>'+@HTML_PROYECTOS_TOP+'</tbody>'+
                '</table>'+
            '</div>';
 
    /* ============================================================
       14. HTML GESTIONES
       "Vencida" se calcula por fecha; no se almacena como estado visual.
       ============================================================ */
    DECLARE
        @HTML_GESTIONES VARCHAR(MAX)='',
        @HTML_GESTIONES_TOP VARCHAR(MAX)='';
 
    SELECT @HTML_GESTIONES=ISNULL((
        SELECT
            '<tr data-vct-row style="border-bottom:1px solid #edf1f5;">'+
                '<td data-label="" class="vct-360-cell-management-icon" aria-hidden="true" style="width:4% !important;border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-management-type-icon"><span data-vct-icon="'+GestionIcono+'"></span></span>'+ 
                '</td>'+ 
                '<td data-label="Gestión" class="vct-360-cell-management" style="width:17% !important;text-align:left !important;border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">'+GestionTitulo+'</span>'+ 
                    CASE WHEN GestionDetalle<>'' THEN '<span class="vct-360-project-ref">'+GestionDetalle+'</span>' ELSE '' END+
                '</td>'+ 
                '<td data-label="Cliente" class="vct-360-cell-client" style="width:13% !important;text-align:left !important;border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">'+ClienteNombre+'</span>'+ 
                '</td>'+ 
                '<td data-label="Proyecto" class="vct-360-cell-management-project vct-360-cell-project" style="width:27% !important;text-align:left !important;border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">('+ProyectoCodigo+') '+ProyectoNombre+'</span>'+ 
                    CASE WHEN ProyectoReferencia<>'' THEN '<span class="vct-360-project-ref">'+ProyectoReferencia+'</span>' ELSE '' END+
                '</td>'+ 
                '<td data-label="Responsable" data-vct-sort-value="'+ResponsableNombre+'" class="vct-360-cell-person" style="width:15% !important;text-align:left !important;border-bottom:1px solid #edf1f5 !important;">'+
                    CASE WHEN ResponsableNombre='-' THEN '-'
                         ELSE '<span class="vct-360-person-inline">'+
                              '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" style="--vct-avatar-bg:'+ResponsableBg+';--vct-avatar-color:'+ResponsableTx+';">'+ResponsableIniciales+'</span>'+ 
                              '<span class="vct-360-person-name">'+ResponsableNombre+'</span>'+ 
                              '</span>' END+
                '</td>'+ 
                '<td data-label="Vencimiento" class="vct-360-cell-date" style="width:8% !important;text-align:center !important;border-bottom:1px solid #edf1f5 !important;">'+VencimientoTxt+'</td>'+ 
                '<td data-label="Estado" class="vct-360-cell-status" style="width:8% !important;text-align:center !important;border-bottom:1px solid #edf1f5 !important;"><span class="vct-badge" data-vct-badge="'+EstadoBadge+'">'+EstadoVisual+'</span></td>'+ 
                '<td data-label="Fecha" class="vct-360-cell-date" style="width:8% !important;text-align:center !important;border-bottom:1px solid #edf1f5 !important;">'+FechaTxt+'</td>'+ 
            '</tr>'
        FROM
        (
            SELECT
                G.ID AS SortID,
                G.FECHA AS SortFecha,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.TITULO,''),'Gestión'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS GestionTitulo,
                REPLACE(REPLACE(REPLACE(REPLACE(
                    LTRIM(RTRIM(
                        ISNULL(NULLIF(G.TIPO,''),'')+
                        CASE WHEN NULLIF(G.TIPO,'') IS NOT NULL AND NULLIF(G.SUBTIPO,'') IS NOT NULL THEN ' · ' ELSE '' END+
                        ISNULL(NULLIF(G.SUBTIPO,''),'')+
                        CASE WHEN (NULLIF(G.TIPO,'') IS NOT NULL OR NULLIF(G.SUBTIPO,'') IS NOT NULL) AND NULLIF(G.RESULTADO,'') IS NOT NULL THEN ' · ' ELSE '' END+
                        ISNULL(NULLIF(G.RESULTADO,''),'')
                    )),
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS GestionDetalle,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.CLIENTE_NOMBRE,''),'Sin cliente'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ClienteNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.PROYECTO_CODIGO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoCodigo,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.PROYECTO_NOMBRE,''),'Sin proyecto'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.PROYECTO_REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoReferencia,
                CASE
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%VISITA%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%VISITA%' THEN 'calendar'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%DOCUMENT%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%DOCUMENT%' THEN 'file-text'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%LLAM%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%LLAM%' THEN 'phone'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%MAIL%' OR UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%EMAIL%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%MAIL%' THEN 'mail'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%REUN%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%REUN%' THEN 'users'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%CIERRE%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%CIERRE%PROYECTO%' THEN 'folder'
                    WHEN UPPER(ISNULL(G.TIPO,'')) LIKE '%TAREA%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%TAREA%' THEN 'list-checks'
                    ELSE 'clipboard-check'
                END AS GestionIcono,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(LTRIM(RTRIM(G.RESPONSABLE)),''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ResponsableNombre,
                CASE
                    WHEN NULLIF(LTRIM(RTRIM(ISNULL(G.RESPONSABLE,''))),'') IS NULL THEN '--'
                    WHEN CHARINDEX(' ',LTRIM(RTRIM(G.RESPONSABLE)))>0
                        THEN UPPER(LEFT(LTRIM(RTRIM(G.RESPONSABLE)),1)+LEFT(REVERSE(LEFT(REVERSE(RTRIM(G.RESPONSABLE)),CHARINDEX(' ',REVERSE(RTRIM(G.RESPONSABLE))+' ')-1)),1))
                    ELSE UPPER(LEFT(LTRIM(RTRIM(G.RESPONSABLE)),2))
                END AS ResponsableIniciales,
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(G.RESPONSABLE,'')+'|'+CONVERT(VARCHAR(20),G.ID)))) % 8
                    WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
                    WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8'
                END AS ResponsableBg,
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(G.RESPONSABLE,'')+'|'+CONVERT(VARCHAR(20),G.ID)))) % 8
                    WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
                    WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94'
                END AS ResponsableTx,
                ISNULL(CONVERT(VARCHAR(10),G.VENCIMIENTO,103),'-') AS VencimientoTxt,
                ISNULL(CONVERT(VARCHAR(10),G.FECHA,103),'-') AS FechaTxt,
                REPLACE(REPLACE(REPLACE(REPLACE(
                    CASE
                        WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)<0 THEN 'VENCIDA'
                        WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)=0 THEN 'HOY'
                        ELSE UPPER(ISNULL(NULLIF(G.ESTADO,''),'SIN ESTADO'))
                    END,
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EstadoVisual,
                CASE
                    WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)<0 THEN 'VENCIDA'
                    WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)=0 THEN 'HOY'
                    ELSE ISNULL(G.ESTADO_CODIGO,'SIN ESTADO')
                END AS EstadoBadge
            FROM #GESTIONES360 G
        ) X
        ORDER BY CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,SortFecha DESC,SortID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_GESTIONES=''
        SET @HTML_GESTIONES='<div class="vct-360-empty vct-360-fixed-empty">Sin gestiones registradas para el empleado.</div>';
    ELSE
        SET @HTML_GESTIONES=
            '<div data-vct-dg data-vct-dg-id="v360_emp_gestiones" data-vct-dg-title="Gestiones del empleado" data-vct-dg-subtitle="Empleado: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="gestion(es)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar gestion, cliente, proyecto..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-width="4%" data-vct-export-ignore="true" aria-label="Tipo"></th><th data-vct-width="17%" data-vct-sort="gestion" data-vct-sortable="true"><span>Gestión</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="13%" data-vct-sort="cliente" data-vct-sortable="true"><span>Cliente</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="27%" data-vct-sort="proyecto" data-vct-sortable="true"><span>Proyecto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="responsable" data-vct-sortable="true"><span>Responsable</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="vencimiento" data-vct-sortable="true" data-vct-sort-type="date"><span>Vencimiento</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="estado" data-vct-sortable="true"><span>Estado</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="8%" data-vct-sort="fecha" data-vct-sortable="true" data-vct-sort-type="date"><span>Fecha</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th></tr></thead>'+
            '<tbody>'+@HTML_GESTIONES+'</tbody>'+
            '</table>'+
            '</div>';
 
    SELECT @HTML_GESTIONES_TOP=ISNULL((
        SELECT
            '<tr style="border-bottom:1px solid #edf1f5;">'+
                '<td data-label="" class="vct-360-cell-management-icon" aria-hidden="true" style="border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-management-type-icon"><span data-vct-icon="'+GestionIcono+'"></span></span>'+
                '</td>'+
                '<td data-label="Gestión" class="vct-360-cell-management" style="border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">'+GestionTitulo+'</span>'+
                    CASE WHEN SubtipoTxt<>'' THEN '<span class="vct-360-project-ref">'+SubtipoTxt+'</span>' ELSE '' END+
                '</td>'+
                '<td data-label="Cliente" class="vct-360-cell-client" style="border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">'+ClienteNombre+'</span>'+
                '</td>'+
                '<td data-label="Proyecto" class="vct-360-cell-management-project vct-360-cell-project" style="border-bottom:1px solid #edf1f5 !important;">'+
                    '<span class="vct-360-project-name">('+ProyectoCodigo+') '+ProyectoNombre+'</span>'+
                    CASE WHEN ProyectoReferencia<>'' THEN '<span class="vct-360-project-ref">'+ProyectoReferencia+'</span>' ELSE '' END+
                '</td>'+
                '<td data-label="Asignado" class="vct-360-cell-person" style="border-bottom:1px solid #edf1f5 !important;">'+
                    CASE WHEN ResponsableNombre='-' THEN '-'
                         ELSE '<span class="vct-360-person-inline">'+
                              '<span class="vct-360-contact-avatar vct-360-contact-avatar-sm" style="--vct-avatar-bg:'+ResponsableBg+';--vct-avatar-color:'+ResponsableTx+';">'+ResponsableIniciales+'</span>'+
                              '<span class="vct-360-person-name">'+ResponsableNombre+'</span>'+
                              '</span>' END+
                '</td>'+
                '<td data-label="Estado" class="vct-360-cell-status" style="border-bottom:1px solid #edf1f5 !important;"><span class="vct-badge" data-vct-badge="'+EstadoBadge+'">'+EstadoVisual+'</span></td>'+
                '<td data-label="Fecha" class="vct-360-cell-date" style="border-bottom:1px solid #edf1f5 !important;">'+FechaTxt+'</td>'+
            '</tr>'
        FROM
        (
            SELECT TOP 5
                G.ID AS SortID,
                G.FECHA AS SortFecha,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.TITULO,''),'Gestión'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS GestionTitulo,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.SUBTIPO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS SubtipoTxt,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.CLIENTE_NOMBRE,''),'Sin cliente'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ClienteNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.PROYECTO_CODIGO,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoCodigo,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(G.PROYECTO_NOMBRE,''),'Sin proyecto'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoNombre,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(G.PROYECTO_REFERENCIA,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ProyectoReferencia,
                CASE
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%VISITA%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%VISITA%' THEN 'calendar'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%DOCUMENT%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%DOCUMENT%' THEN 'file-text'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%LLAM%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%LLAM%' THEN 'phone'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%MAIL%' OR UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%EMAIL%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%MAIL%' THEN 'mail'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%REUN%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%REUN%' THEN 'users'
                    WHEN UPPER(ISNULL(G.SUBTIPO,'')) LIKE '%CIERRE%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%CIERRE%PROYECTO%' THEN 'folder'
                    WHEN UPPER(ISNULL(G.TIPO,'')) LIKE '%TAREA%' OR UPPER(ISNULL(G.TITULO,'')) LIKE '%TAREA%' THEN 'list-checks'
                    ELSE 'clipboard-check'
                END AS GestionIcono,
                REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(LTRIM(RTRIM(G.RESPONSABLE)),''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS ResponsableNombre,
                CASE
                    WHEN NULLIF(LTRIM(RTRIM(ISNULL(G.RESPONSABLE,''))),'') IS NULL THEN '--'
                    WHEN CHARINDEX(' ',LTRIM(RTRIM(G.RESPONSABLE)))>0
                        THEN UPPER(LEFT(LTRIM(RTRIM(G.RESPONSABLE)),1)+LEFT(REVERSE(LEFT(REVERSE(RTRIM(G.RESPONSABLE)),CHARINDEX(' ',REVERSE(RTRIM(G.RESPONSABLE))+' ')-1)),1))
                    ELSE UPPER(LEFT(LTRIM(RTRIM(G.RESPONSABLE)),2))
                END AS ResponsableIniciales,
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(G.RESPONSABLE,'')+'|'+CONVERT(VARCHAR(20),G.ID)))) % 8
                    WHEN 0 THEN '#F3DFE5' WHEN 1 THEN '#E3E4FA' WHEN 2 THEN '#DCEBF0' WHEN 3 THEN '#F3E1D9'
                    WHEN 4 THEN '#E4F2EA' WHEN 5 THEN '#F8E7D4' WHEN 6 THEN '#E7E1F5' ELSE '#E4EEF8'
                END AS ResponsableBg,
                CASE ABS(CONVERT(BIGINT,CHECKSUM(ISNULL(G.RESPONSABLE,'')+'|'+CONVERT(VARCHAR(20),G.ID)))) % 8
                    WHEN 0 THEN '#8B2E4A' WHEN 1 THEN '#5257A2' WHEN 2 THEN '#356D84' WHEN 3 THEN '#A05A3C'
                    WHEN 4 THEN '#3C7A57' WHEN 5 THEN '#A66324' WHEN 6 THEN '#6E55A5' ELSE '#3D6B94'
                END AS ResponsableTx,
                ISNULL(CONVERT(VARCHAR(10),G.FECHA,103),'-') AS FechaTxt,
                REPLACE(REPLACE(REPLACE(REPLACE(
                    CASE
                        WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)<0 THEN 'VENCIDA'
                        WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)=0 THEN 'HOY'
                        ELSE UPPER(ISNULL(NULLIF(G.ESTADO,''),'SIN ESTADO'))
                    END,
                    '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;') AS EstadoVisual,
                CASE
                    WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)<0 THEN 'VENCIDA'
                    WHEN ISNULL(G.ES_FINAL,0)=0 AND G.VENCIMIENTO IS NOT NULL AND DATEDIFF(DAY,GETDATE(),G.VENCIMIENTO)=0 THEN 'HOY'
                    ELSE ISNULL(G.ESTADO_CODIGO,'SIN ESTADO')
                END AS EstadoBadge
            FROM #GESTIONES360 G
            ORDER BY CASE WHEN G.FECHA IS NULL THEN 1 ELSE 0 END,G.FECHA DESC,G.ID DESC
        ) X
        ORDER BY CASE WHEN SortFecha IS NULL THEN 1 ELSE 0 END,SortFecha DESC,SortID DESC
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @HTML_GESTIONES_TOP=''
        SET @HTML_GESTIONES_TOP='<div class="vct-360-empty vct-360-fixed-empty">Sin gestiones registradas todavía.</div>';
    ELSE
        SET @HTML_GESTIONES_TOP=
            '<div class="vct-360-gestiones-recent vct-360-gestiones-recent-full">'+
                '<table class="vct-360-table vct-360-management-table-recent">'+
                    '<colgroup>'+
                        '<col style="width:4%">'+
                        '<col style="width:20%">'+
                        '<col style="width:16%">'+
                        '<col style="width:27%">'+
                        '<col style="width:15%">'+
                        '<col style="width:10%">'+
                        '<col style="width:8%">'+
                    '</colgroup>'+
                    '<thead><tr>'+
                        '<th aria-label="Tipo"></th>'+
                        '<th>Gestión</th>'+
                        '<th>Cliente</th>'+
                        '<th>Proyecto</th>'+
                        '<th>Asignado</th>'+
                        '<th>Estado</th>'+
                        '<th>Fecha</th>'+
                    '</tr></thead>'+
                    '<tbody>'+@HTML_GESTIONES_TOP+'</tbody>'+
                '</table>'+
            '</div>';
 
    /* ============================================================
       15. HTML DOMICILIOS / TELEFONOS / EMAILS
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
            '<td data-label="Dirección">'+
                REPLACE(REPLACE(REPLACE(
                    LTRIM(RTRIM(ISNULL(D.CALLE,'')+
                    CASE WHEN ISNULL(D.NRO,'')<>'' THEN ' '+D.NRO ELSE '' END)),
                    '&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-text-center" data-label="Piso / Depto">'+
                REPLACE(REPLACE(REPLACE(
                    LTRIM(RTRIM(ISNULL(D.PISO,'')+
                    CASE WHEN ISNULL(D.DEPTO,'')<>'' THEN ' '+D.DEPTO ELSE '' END)),
                    '&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td data-label="Localidad">'+REPLACE(REPLACE(REPLACE(ISNULL(D.LOCALIDAD,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td data-label="Provincia">'+REPLACE(REPLACE(REPLACE(ISNULL(D.PROVINCIA,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+'</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+
                REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(D.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @DOM_MODE<>'NONE'
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerEmpleadoDomicilio" '+
                          'data-vct-entity="DOMICILIO" data-vct-tab="domicilio" '+
                          'data-vct-form-title="Editar domicilio" '+
                          'data-vct-form-subtitle="Modifique los datos de la dirección." '+
                          'data-vct-form-icon="map-pin" aria-label="Acciones">'+
                          '<span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                     ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #DOMICILIOS360 D
        ORDER BY CASE WHEN UPPER(ISNULL(D.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,D.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @DOM_MODE='NONE'
        SET @HTML_DOMICILIOS=
            '<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_DOMICILIOS todavía no posee relación con Empleados.</div>';
    ELSE IF @HTML_DOMICILIOS=''
        SET @HTML_DOMICILIOS=
            '<div class="vct-360-empty vct-360-fixed-empty">Sin domicilios registrados.</div>';
    ELSE
        SET @HTML_DOMICILIOS=
            '<div data-vct-dg data-vct-dg-id="v360_emp_dom" data-vct-dg-title="Domicilios del empleado" data-vct-dg-subtitle="Empleado: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="domicilio(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar domicilio..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="direccion" data-vct-sortable="true"><span>Dirección</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="piso" data-vct-sortable="true"><span>Piso / Depto</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="15%" data-vct-sort="localidad" data-vct-sortable="true"><span>Localidad</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="14%" data-vct-sort="provincia" data-vct-sortable="true"><span>Provincia</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="11%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="18%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
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
            '<td class="vct-text-center" data-label="Código área">'+ISNULL(NULLIF(T.CODAREA,''),'-')+'</td>'+
            '<td data-label="Número">'+ISNULL(NULLIF(T.NRO,''),'-')+'</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+
                REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(T.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @TEL_MODE<>'NONE'
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerEmpleadoTelefono" '+
                          'data-vct-entity="TELEFONO" data-vct-tab="telefonos" '+
                          'data-vct-form-title="Editar teléfono" '+
                          'data-vct-form-subtitle="Modifique el teléfono seleccionado." '+
                          'data-vct-form-icon="phone" aria-label="Acciones">'+
                          '<span class="vct-row-menu-dots" aria-hidden="true">&#8942;</span></button>'
                     ELSE '' END+
            '</td>'+
            '</tr>'
        FROM #TELEFONOS360 T
        ORDER BY CASE WHEN UPPER(ISNULL(T.PRINCIPAL,''))='SI' THEN 0 ELSE 1 END,T.ID
        FOR XML PATH(''),TYPE
    ).value('.','VARCHAR(MAX)'),'');
 
    IF @TEL_MODE='NONE'
        SET @HTML_TELEFONOS=
            '<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_TELEFONOS todavía no posee relación con Empleados.</div>';
    ELSE IF @HTML_TELEFONOS=''
        SET @HTML_TELEFONOS=
            '<div class="vct-360-empty vct-360-fixed-empty">Sin teléfonos registrados.</div>';
    ELSE
        SET @HTML_TELEFONOS=
            '<div data-vct-dg data-vct-dg-id="v360_emp_tel" data-vct-dg-title="Telefonos del empleado" data-vct-dg-subtitle="Empleado: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="telefono(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar telefono..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th class="vct-text-center" data-vct-width="14%" data-vct-sort="codarea" data-vct-sortable="true"><span>Código área</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="20%" data-vct-sort="numero" data-vct-sortable="true"><span>Número</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
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
            '<td data-label="Email">'+
                REPLACE(REPLACE(REPLACE(ISNULL(E.EMAIL,'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-text-center" data-label="Tipo">'+
                CASE WHEN UPPER(ISNULL(E.PRINCIPAL,''))='SI'
                     THEN '<span class="vct-360-badge is-active">Principal</span>'
                     ELSE '<span class="vct-360-badge is-neutral">Secundario</span>' END+
            '</td>'+
            '<td data-label="Observaciones">'+
                REPLACE(REPLACE(REPLACE(ISNULL(NULLIF(E.OBSERVACIONES,''),'-'),'&','&amp;'),'<','&lt;'),'>','&gt;')+
            '</td>'+
            '<td class="vct-360-action-cell vct-table-action-cell" data-label="Acciones" data-vct-export-ignore="true">'+
                CASE WHEN @CAN_EDIT=1 AND @MAIL_MODE<>'NONE'
                     THEN '<button type="button" class="vct-row-menu-trigger" '+
                          'data-vct-command="row-context-menu" '+
                          'data-vct-target="vctDrawerEmpleadoEmail" '+
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
 
    IF @MAIL_MODE='NONE'
        SET @HTML_EMAILS=
            '<div class="vct-360-empty vct-360-fixed-empty">La tabla VCT_EMAILS todavía no posee relación con Empleados.</div>';
    ELSE IF @HTML_EMAILS=''
        SET @HTML_EMAILS=
            '<div class="vct-360-empty vct-360-fixed-empty">Sin emails registrados.</div>';
    ELSE
        SET @HTML_EMAILS=
            '<div data-vct-dg data-vct-dg-id="v360_emp_mail" data-vct-dg-title="Emails del empleado" data-vct-dg-subtitle="Empleado: '+REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@NOMBRE_COMPLETO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;')+'" data-vct-dg-unit="email(s)" data-vct-dg-page-size="10" data-vct-dg-search-placeholder="Buscar email..." data-vct-dg-density="compact" data-vct-dg-layout="fixed">'+
            '<table>'+
            '<thead><tr><th data-vct-sort="email" data-vct-sortable="true"><span>Email</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-text-center" data-vct-width="14%" data-vct-sort="tipo" data-vct-sortable="true"><span>Tipo</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th data-vct-width="34%" data-vct-sort="observaciones" data-vct-sortable="true" data-vct-truncate="2"><span>Observaciones</span><span class="vct-sort-icon" data-vct-icon="chevrons-up-down"></span></th><th class="vct-col-action" data-vct-width="44" data-vct-export-ignore="true"></th></tr></thead>'+
            '<tbody>'+@HTML_EMAILS+'</tbody>'+
            '</table>'+
            '</div>';
 
    /* ============================================================
       15.B GRAFICOS DEL RESUMEN - EMPLEADO SELECCIONADO
       ============================================================ */
    DECLARE
        @HTML_CHART_PROY_ESTADO VARCHAR(MAX)='',
        @HTML_CHART_GEST_ESTADO VARCHAR(MAX)='',
        @HTML_CHART_CLIENTES VARCHAR(MAX)='',
        @P_ACT INT=0,@P_PLAN INT=0,@P_FIN INT=0,@P_OTR INT=0,@P_TOT INT=0,
        @G_REAL INT=0,@G_PEND INT=0,@G_CURSO INT=0,@G_OTR INT=0,@G_TOT INT=0;
 
    SELECT
        @P_ACT=SUM(CASE WHEN ESTADO_CODIGO='ENCURSO' THEN 1 ELSE 0 END),
        @P_PLAN=SUM(CASE WHEN ESTADO_CODIGO IN ('BORRADOR','CONFIRMADO','PAUSADO') THEN 1 ELSE 0 END),
        @P_FIN=SUM(CASE WHEN ESTADO_CODIGO='TERMINADO' THEN 1 ELSE 0 END),
        @P_TOT=COUNT(*)
    FROM #PROYECTOS360;
 
    SET @P_ACT=ISNULL(@P_ACT,0);
    SET @P_PLAN=ISNULL(@P_PLAN,0);
    SET @P_FIN=ISNULL(@P_FIN,0);
    SET @P_TOT=ISNULL(@P_TOT,0);
    SET @P_OTR=@P_TOT-@P_ACT-@P_PLAN-@P_FIN;
    IF @P_OTR<0 SET @P_OTR=0;
 
    DECLARE @P_ACT_PCT DECIMAL(10,2)=0,@P_PLAN_PCT DECIMAL(10,2)=0,@P_FIN_PCT DECIMAL(10,2)=0,@P_OTR_PCT DECIMAL(10,2)=0;
    IF @P_TOT>0
    BEGIN
        SET @P_ACT_PCT=100.0*@P_ACT/@P_TOT;
        SET @P_PLAN_PCT=100.0*@P_PLAN/@P_TOT;
        SET @P_FIN_PCT=100.0*@P_FIN/@P_TOT;
        SET @P_OTR_PCT=100.0-@P_ACT_PCT-@P_PLAN_PCT-@P_FIN_PCT;
    END;
 
    DECLARE @P_BG VARCHAR(MAX)='';
    SET @P_BG=CASE WHEN @P_TOT=0 THEN '#E8EDF3' ELSE
        'conic-gradient('+
        '#12B76A 0 '+CONVERT(VARCHAR(20),@P_ACT_PCT)+'%,'+
        '#F79009 '+CONVERT(VARCHAR(20),@P_ACT_PCT)+'% '+CONVERT(VARCHAR(20),@P_ACT_PCT+@P_PLAN_PCT)+'%,'+
        '#98A2B3 '+CONVERT(VARCHAR(20),@P_ACT_PCT+@P_PLAN_PCT)+'% '+CONVERT(VARCHAR(20),@P_ACT_PCT+@P_PLAN_PCT+@P_FIN_PCT)+'%,'+
        '#7F56D9 '+CONVERT(VARCHAR(20),@P_ACT_PCT+@P_PLAN_PCT+@P_FIN_PCT)+'% 100%)' END;
 
    SET @HTML_CHART_PROY_ESTADO=
        '<div class="vct-360-chart-simple">'+
            '<div class="vct-360-donut-ring vct-360-donut-lg" style="background:'+@P_BG+';">'+
                '<div class="vct-360-donut-center vct-360-donut-center-lg"><b>'+CONVERT(VARCHAR(10),@P_TOT)+'</b><span>Proyectos</span></div>'+
            '</div>'+
            '<div class="vct-360-donut-legend-lg">'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#12B76A"></i><span>En curso</span><b>'+CONVERT(VARCHAR(10),@P_ACT)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#F79009"></i><span>Otros abiertos</span><b>'+CONVERT(VARCHAR(10),@P_PLAN)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#98A2B3"></i><span>Terminados</span><b>'+CONVERT(VARCHAR(10),@P_FIN)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#7F56D9"></i><span>Otros</span><b>'+CONVERT(VARCHAR(10),@P_OTR)+'</b></div>'+
            '</div>'+
        '</div>';
 
    SELECT
        @G_REAL=SUM(CASE WHEN ESTADO_CODIGO='CUMPLIDA' THEN 1 ELSE 0 END),
        @G_PEND=SUM(CASE WHEN ESTADO_CODIGO='PENDIENTE' THEN 1 ELSE 0 END),
        @G_CURSO=SUM(CASE WHEN ESTADO_CODIGO IN ('EN_PROCESO','EN_ESPERA') THEN 1 ELSE 0 END),
        @G_TOT=COUNT(*)
    FROM #GESTIONES360;
 
    SET @G_REAL=ISNULL(@G_REAL,0);
    SET @G_PEND=ISNULL(@G_PEND,0);
    SET @G_CURSO=ISNULL(@G_CURSO,0);
    SET @G_TOT=ISNULL(@G_TOT,0);
    SET @G_OTR=@G_TOT-@G_REAL-@G_PEND-@G_CURSO;
    IF @G_OTR<0 SET @G_OTR=0;
 
    DECLARE @G_REAL_PCT DECIMAL(10,2)=0,@G_PEND_PCT DECIMAL(10,2)=0,@G_CURSO_PCT DECIMAL(10,2)=0,@G_OTR_PCT DECIMAL(10,2)=0;
    IF @G_TOT>0
    BEGIN
        SET @G_REAL_PCT=100.0*@G_REAL/@G_TOT;
        SET @G_PEND_PCT=100.0*@G_PEND/@G_TOT;
        SET @G_CURSO_PCT=100.0*@G_CURSO/@G_TOT;
        SET @G_OTR_PCT=100.0-@G_REAL_PCT-@G_PEND_PCT-@G_CURSO_PCT;
    END;
 
    DECLARE @G_BG VARCHAR(MAX)='';
    SET @G_BG=CASE WHEN @G_TOT=0 THEN '#E8EDF3' ELSE
        'conic-gradient('+
        '#12B76A 0 '+CONVERT(VARCHAR(20),@G_REAL_PCT)+'%,'+
        '#F79009 '+CONVERT(VARCHAR(20),@G_REAL_PCT)+'% '+CONVERT(VARCHAR(20),@G_REAL_PCT+@G_PEND_PCT)+'%,'+
        '#2E90FA '+CONVERT(VARCHAR(20),@G_REAL_PCT+@G_PEND_PCT)+'% '+CONVERT(VARCHAR(20),@G_REAL_PCT+@G_PEND_PCT+@G_CURSO_PCT)+'%,'+
        '#F04438 '+CONVERT(VARCHAR(20),@G_REAL_PCT+@G_PEND_PCT+@G_CURSO_PCT)+'% 100%)' END;
 
    SET @HTML_CHART_GEST_ESTADO=
        '<div class="vct-360-chart-simple">'+
            '<div class="vct-360-donut-ring vct-360-donut-lg" style="background:'+@G_BG+';">'+
                '<div class="vct-360-donut-center vct-360-donut-center-lg"><b>'+CONVERT(VARCHAR(10),@G_TOT)+'</b><span>Gestiones</span></div>'+
            '</div>'+
            '<div class="vct-360-donut-legend-lg">'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#12B76A"></i><span>Cumplidas</span><b>'+CONVERT(VARCHAR(10),@G_REAL)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#F79009"></i><span>Pendientes</span><b>'+CONVERT(VARCHAR(10),@G_PEND)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#2E90FA"></i><span>En curso</span><b>'+CONVERT(VARCHAR(10),@G_CURSO)+'</b></div>'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#F04438"></i><span>Otros</span><b>'+CONVERT(VARCHAR(10),@G_OTR)+'</b></div>'+
            '</div>'+
        '</div>';
 
    SET @HTML_CHART_CLIENTES=
        '<div class="vct-360-chart-simple">'+
            '<div class="vct-360-donut-ring vct-360-donut-lg" style="background:'+
                CASE WHEN @ClientesAsignados=0 THEN '#E8EDF3' ELSE '#2E90FA' END+';">'+
                '<div class="vct-360-donut-center vct-360-donut-center-lg"><b>'+CONVERT(VARCHAR(10),@ClientesAsignados)+'</b><span>Clientes</span></div>'+
            '</div>'+
            '<div class="vct-360-donut-legend-lg">'+
                '<div class="vct-360-donut-legend-item"><i class="vct-360-dot" style="background:#2E90FA"></i><span>Clientes asignados</span><b>'+CONVERT(VARCHAR(10),@ClientesAsignados)+'</b></div>'+
            '</div>'+
        '</div>';
 
    /* ============================================================
       16. FORM ACTIONS / DRAWERS
       ============================================================ */
    DECLARE
        @BTN_ADD_DOM VARCHAR(MAX)='',
        @BTN_ADD_TEL VARCHAR(MAX)='',
        @BTN_ADD_MAIL VARCHAR(MAX)='',
        @HTML_DRAWER_DOM VARCHAR(MAX)='',
        @HTML_DRAWER_TEL VARCHAR(MAX)='',
        @HTML_DRAWER_MAIL VARCHAR(MAX)='';
 
    IF @CAN_EDIT=1 AND @DOM_MODE<>'NONE'
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerEmpleadoDomicilio',
             @FORM_TITLE='Nuevo domicilio',
             @FORM_SUBTITLE='Agregue una dirección para el empleado.',
             @FORM_ICON='map-pin',
             @BUTTON_TEXT='Agregar',
             @BUTTON_ICON='map-pin',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar domicilio',
             @OUTHTML=@BTN_ADD_DOM OUTPUT;
    END;
 
    IF @CAN_EDIT=1 AND @TEL_MODE<>'NONE'
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerEmpleadoTelefono',
             @FORM_TITLE='Nuevo teléfono',
             @FORM_SUBTITLE='Agregue un teléfono para el empleado.',
             @FORM_ICON='phone',
             @BUTTON_TEXT='Agregar',
             @BUTTON_ICON='phone',
             @BUTTON_CLASS='vct-btn vct-btn-new vct-btn-sm',
             @TOOLTIP='Agregar teléfono',
             @OUTHTML=@BTN_ADD_TEL OUTPUT;
    END;
 
    IF @CAN_EDIT=1 AND @MAIL_MODE<>'NONE'
    BEGIN
        EXEC dbo.VCT_MAIN_RENDER_FORM_ACTION
             @MODE='CREATE',
             @TARGET_FORM='vctDrawerEmpleadoEmail',
             @FORM_TITLE='Nuevo email',
             @FORM_SUBTITLE='Agregue un email para el empleado.',
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
    (2,'TEXTO12','Número','TEXT',4,1,30,'Número',NULL,
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
         @FORM_ID='vctDrawerEmpleadoDomicilio',
         @TITLE='Domicilio',
         @SUBTITLE='Datos de dirección del empleado.',
         @ICON='map-pin',
         @LAYOUT='DRAWER',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_DOM,
         @OPEN_ON_RENDER=@OPEN_DOM,
         @OUTHTML=@HTML_DRAWER_DOM OUTPUT;
 
    /* Provincia: opciones desde CAT_DATA. */
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
        'data-vct-target="vctDrawerEmpleadoDomicilio" '+
        'data-vct-field="TEXTO16" data-vct-placeholder="Seleccione una provincia">'+
        ISNULL(@HTML_PROVINCIAS,'')+
        '</template>';
 
    /* Telefono */
    DELETE FROM #VCT_FORM_FIELDS;
 
    INSERT INTO #VCT_FORM_FIELDS VALUES
    (1,'TEXTO11','Código de área','TEXT',6,1,30,'Código de área',NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_T11 ELSE NULL END,0,0,NULL,'codarea'),
    (2,'TEXTO12','Número','TEXT',6,1,50,'Número',NULL,
        CASE WHEN @OPEN_TEL=1 THEN @VFORM_T12 ELSE NULL END,0,0,NULL,'nro'),
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
         @FORM_ID='vctDrawerEmpleadoTelefono',
         @TITLE='Teléfono',
         @SUBTITLE='Número de contacto del empleado.',
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
         @FORM_ID='vctDrawerEmpleadoEmail',
         @TITLE='Email',
         @SUBTITLE='Correo electrónico del empleado.',
         @ICON='mail',
         @LAYOUT='DRAWER',
         @SAVE_LABEL='Guardar',
         @CANCEL_LABEL='Cancelar',
         @ERROR_MESSAGE=@ERR_MAIL,
         @OPEN_ON_RENDER=@OPEN_MAIL,
         @OUTHTML=@HTML_DRAWER_MAIL OUTPUT;
 
    /* ============================================================
       17. HEADER / BREADCRUMB / FICHA
       ============================================================ */
    DECLARE
        @INICIALES VARCHAR(4)='',
        @E_NOMBRE VARCHAR(400)='',
        @E_DOC VARCHAR(150)='',
        @E_LEGAJO VARCHAR(100)='',
        @E_CARGO VARCHAR(200)='',
        @E_USUARIO VARCHAR(250)='',
        @ESTADO_BADGE_CLASE VARCHAR(20)='is-neutral',
        @ESTADO_BADGE_TEXTO VARCHAR(50)='SIN ESTADO';
 
    SET @INICIALES=
        UPPER(
            LEFT(LTRIM(ISNULL(@NOMBRES,'')),1)+
            LEFT(LTRIM(ISNULL(@APELLIDOS,'')),1)
        );
 
    IF NULLIF(@INICIALES,'') IS NULL SET @INICIALES='--';
 
    SET @E_NOMBRE=REPLACE(REPLACE(REPLACE(REPLACE(@NOMBRE_COMPLETO,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @E_DOC=REPLACE(REPLACE(REPLACE(REPLACE(
        LTRIM(RTRIM(ISNULL(@TIPO_DOCUMENTO,'')+' '+ISNULL(@NRO_DOCUMENTO,''))),
        '&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @E_LEGAJO=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@LEGAJO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @E_CARGO=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@CARGO,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
    SET @E_USUARIO=REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@USUARIO_DISPLAY,''),'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
 
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
 
    /* Breadcrumb de Empleados.
       Reutiliza el handler genérico data-vct-v360-back.
       El retorno se resuelve contra la opción real del sidebar (módulo 6),
       por lo que no es necesario hardcodear el GUID del formulario principal. */
    SET @BTN_BACK=
        '<nav class="vct-breadcrumb-simple" aria-label="Breadcrumb">'+
            '<button type="button" class="vct-breadcrumb-link" '+
                    'data-vct-v360-back '+
                    'data-vct-sidebar-mod="6">Empleados</button>'+
            '<span class="vct-breadcrumb-sep">›</span>'+
            '<span class="vct-breadcrumb-item">Vista 360</span>'+
            '<span class="vct-breadcrumb-sep">›</span>'+
            '<span class="vct-breadcrumb-current">'+@E_NOMBRE+'</span>'+
        '</nav>';
 
 
    /* ============================================================
       18. OUTPUT 1 - HEADER / FICHA / KPI / TABS
       ============================================================ */
    SET @OUTPARAM1=
        ISNULL(@HTML_SHELL,'')+'
<div class="vct-page vct-page-main"
     data-vct-page
     data-vct-sidebar-id="6"
     data-vct-form-id="'+ISNULL(@FORM_ID,'')+'">
 
<link rel="stylesheet" href="../css/vct-datagrid.css?v=4"><script src="../js/vct-export.js?v=1"></script><script src="../js/vct-datagrid.js?v=3"></script><section class="vct-module vct-360-module vct-empleado360-module vct-consultor360-module vct-cliente360-module vct-360-visual-final"
         data-vct-module
         data-vct-entity-theme="empleado"
         data-vct-tabs
         data-vct-tabs-active="'+ISNULL(@ACTIVE_TAB,'resumen')+'"
         data-vct-tabs-reset="'+CONVERT(VARCHAR(1),@V360_RESET_TAB)+'"
         data-vct-employee-key="'+CONVERT(VARCHAR(100),@ID_EMPLEADO)+'">
 
    <div class="vct-360-breadcrumb-row">'+ISNULL(@BTN_BACK,'')+'</div>
 
    <div class="vct-360-client-strip vct-360-employee-strip">
        <div class="vct-360-card-left">
            <div class="vct-360-avatar">'+@INICIALES+'</div>
            <div class="vct-360-identity">
                <div class="vct-360-identity-title">
                    <h1>'+@E_NOMBRE+'</h1>'+@HTML_ESTADO_BADGE+'
                </div>
                <div class="vct-360-client-meta">
                    <span><span data-vct-icon="file-text"></span>'+CASE WHEN @E_DOC='' THEN '-' ELSE @E_DOC END+'</span>
                    <span><span data-vct-icon="id-card"></span>Legajo '+CASE WHEN @E_LEGAJO='' THEN '-' ELSE @E_LEGAJO END+'</span>
                    <span><span data-vct-icon="briefcase"></span>'+CASE WHEN @E_CARGO='' THEN '-' ELSE @E_CARGO END+'</span>
                    <span><span data-vct-icon="monitor"></span>Ingresa al sistema: '+CASE WHEN @INGRESA_SISTEMA=1 THEN 'Sí' ELSE 'No' END+'</span>
                    <span><span data-vct-icon="user"></span>Usuario: '+CASE WHEN @E_USUARIO='' THEN '-' ELSE @E_USUARIO END+'</span>
                </div>
            </div>
        </div>
 
        <div class="vct-360-card-right">
            <div class="vct-360-alerts" data-vct-alerts data-vct-alert-count="0" aria-label="Alertas: 0">
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
        </div>
    </div>
 
    <div class="vct-360-content-shell">
        <div class="vct-360-stats-row">
            <div class="vct-360-stat" data-vct-tone="blue">
                <span class="vct-360-stat-main"><span class="vct-360-stat-label">Proyectos totales</span><b>'+CONVERT(VARCHAR(10),@ProyectosCount)+'</b><small>'+CONVERT(VARCHAR(10),@ProyectosEnCurso)+' en curso</small></span>
                <span class="vct-360-stat-icon"><span data-vct-icon="folder"></span></span>
            </div>
            <div class="vct-360-stat" data-vct-tone="violet">
                <span class="vct-360-stat-main"><span class="vct-360-stat-label">Gestiones</span><b>'+CONVERT(VARCHAR(10),@GestionesCount)+'</b><small>'+CONVERT(VARCHAR(10),@GestionesAnio)+' este año</small></span>
                <span class="vct-360-stat-icon"><span data-vct-icon="list-checks"></span></span>
            </div>
            <div class="vct-360-stat" data-vct-tone="mint">
                <span class="vct-360-stat-main"><span class="vct-360-stat-label">Clientes asignados</span><b>'+CONVERT(VARCHAR(10),@ClientesAsignados)+'</b><small>vinculados a sus proyectos</small></span>
                <span class="vct-360-stat-icon"><span data-vct-icon="users"></span></span>
            </div>
            <div class="vct-360-stat" data-vct-tone="amber">
                <span class="vct-360-stat-main"><span class="vct-360-stat-label">Proyectos activos</span><b>'+CONVERT(VARCHAR(10),@ProyectosActivos)+'</b><small>'+CONVERT(VARCHAR(10),@ProyectosActivosPct)+'% del total</small></span>
                <span class="vct-360-stat-icon"><span data-vct-icon="clock-3"></span></span>
            </div>
        </div>
 
        <div class="vct-360-tabsbar" data-vct-tablist>
            <button type="button" data-vct-tab="resumen"><span data-vct-icon="scan-eye"></span><span>Resumen</span></button>
            <button type="button" data-vct-tab="proyectos"><span data-vct-icon="folder"></span><span>Proyectos</span></button>
            <button type="button" data-vct-tab="gestiones"><span data-vct-icon="list-checks"></span><span>Gestiones</span></button>
            <button type="button" data-vct-tab="domicilio"><span data-vct-icon="map-pin"></span><span>Domicilios</span></button>
            <button type="button" data-vct-tab="telefonos"><span data-vct-icon="phone"></span><span>Teléfonos</span></button>
            <button type="button" data-vct-tab="email"><span data-vct-icon="mail"></span><span>Emails</span></button>
            <button type="button" data-vct-tab="documentos"><span data-vct-icon="file-text"></span><span>Documentos</span></button>
            <button type="button" data-vct-tab="notas"><span data-vct-icon="clipboard-check"></span><span>Notas</span></button>
        </div>
';
 
    /* ============================================================
       19. OUTPUT 2 - PANELES
       ============================================================ */
    SET @OUTPARAM2='
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="resumen">
            <div class="vct-360-box vct-360-box-compact vct-360-recent-projects-box">
                <div class="vct-360-box-head">
                    <h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Últimos Proyectos</h3>
                    <button type="button" data-vct-tab-link="proyectos">Ver todos</button>
                </div>
                '+@HTML_PROYECTOS_TOP+'
            </div>
 
            <div class="vct-360-box vct-360-box-compact vct-360-recent-management-box">
                <div class="vct-360-box-head">
                    <h3><span class="vct-360-title-icon" data-vct-icon="list-checks"></span>Últimas Gestiones</h3>
                    <button type="button" data-vct-tab-link="gestiones">Ver todas</button>
                </div>
                '+@HTML_GESTIONES_TOP+'
            </div>
 
            <div class="vct-360-summary-charts">
                <div class="vct-360-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Proyectos por estado</h3></div>
                    '+@HTML_CHART_PROY_ESTADO+'
                </div>
                <div class="vct-360-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="list-checks"></span>Gestiones por estado</h3></div>
                    '+@HTML_CHART_GEST_ESTADO+'
                </div>
                <div class="vct-360-box">
                    <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="users"></span>Clientes asignados</h3></div>
                    '+@HTML_CHART_CLIENTES+'
                </div>
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="proyectos">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="folder"></span>Proyectos ('+CONVERT(VARCHAR(10),@ProyectosCount)+')</h3></div>
                '+@HTML_PROYECTOS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="gestiones">
            <div class="vct-360-box">
                <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="list-checks"></span>Gestiones ('+CONVERT(VARCHAR(10),@GestionesCount)+')</h3></div>
                '+@HTML_GESTIONES+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="domicilio">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="map-pin"></span>Domicilios ('+CONVERT(VARCHAR(10),@DomiciliosCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_DOM,'')+'</div>
                </div>
                '+@HTML_DOMICILIOS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="telefonos">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="phone"></span>Teléfonos ('+CONVERT(VARCHAR(10),@TelefonosCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_TEL,'')+'</div>
                </div>
                '+@HTML_TELEFONOS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="email">
            <div class="vct-360-box vct-360-box-grid-auto">
                <div class="vct-360-box-head vct-360-section-head">
                    <div><h3><span class="vct-360-title-icon" data-vct-icon="mail"></span>Emails ('+CONVERT(VARCHAR(10),@EmailsCount)+')</h3></div>
                    <div class="vct-360-box-actions">'+ISNULL(@BTN_ADD_MAIL,'')+'</div>
                </div>
                '+@HTML_EMAILS+'
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="documentos">
            <div class="vct-360-box">
                <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="file-text"></span>Documentos ('+CONVERT(VARCHAR(10),@DocumentosCount)+')</h3></div>
                <div class="vct-360-empty">Sin información todavía.</div>
            </div>
        </div>
 
        <div class="vct-360-panel vct-consultor360-panel" data-vct-panel="notas">
            <div class="vct-360-box">
                <div class="vct-360-box-head"><h3><span class="vct-360-title-icon" data-vct-icon="clipboard-check"></span>Notas (0)</h3></div>
                <div class="vct-360-empty">Sin información todavía.</div>
            </div>
        </div>
    </div>
</section>
</div>';
 
    /* ============================================================
       20. OUTPUT 3 - DRAWERS
       ============================================================ */
    SET @OUTPARAM3=
        ISNULL(@HTML_DRAWER_DOM,'')+
        ISNULL(@HTML_DRAWER_TEL,'')+
        ISNULL(@HTML_DRAWER_MAIL,'');
 
END
