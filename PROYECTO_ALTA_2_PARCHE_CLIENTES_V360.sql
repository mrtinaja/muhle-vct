/* ========================================================================
   PROYECTO_ALTA_2_PARCHE_CLIENTES_V360
   ------------------------------------------------------------------------
   PARCHE sobre la definicion VIGENTE de dbo.VCT_MAIN_CLIENTES_V360
   (no pisa nada mas). Correr DESPUES de PROYECTO_ALTA_1_INSTALACION.sql
   y de subir vct-proyecto-alta.js / vct-proyecto-alta.css.
     - Modal "Nuevo proyecto" (se abre desde el menu del encabezado).
     - Guardado: entidad PROYECTO -> dbo.VCT_PROYECTO_ALTA_GUARDAR.
     - Carga vct-datepicker y vct-proyecto-alta (CSS + JS).
   Si algun fragmento no se encuentra, NO aplica nada y avisa.
   Si ya fue aplicado (marca ALTA_PROYECTO_V1), no hace nada.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @D NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_CLIENTES_V360'));
DECLARE @s INT, @mk NVARCHAR(MAX), @n NVARCHAR(MAX);

IF @D IS NULL
BEGIN
    RAISERROR('No se encontro dbo.VCT_MAIN_CLIENTES_V360.',16,1);
    RETURN;
END;

IF CHARINDEX(N'ALTA_PROYECTO_V1',@D) > 0
BEGIN
    PRINT 'VCT_MAIN_CLIENTES_V360 ya tenia el alta de proyecto. No se hizo nada.';
    RETURN;
END;

IF OBJECT_ID('dbo.VCT_PROYECTO_ALTA_GUARDAR') IS NULL
BEGIN
    RAISERROR('Falta dbo.VCT_PROYECTO_ALTA_GUARDAR: correr antes PROYECTO_ALTA_1_INSTALACION.sql. No se aplico nada.',16,1);
    RETURN;
END;

SET @D = REPLACE(@D, NCHAR(13)+NCHAR(10), NCHAR(10));

/* ---- cada fragmento debe existir exactamente una vez ---- */
DECLARE @chk TABLE (mk NVARCHAR(400));
INSERT INTO @chk VALUES
 (N'SET NOCOUNT ON; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */'),
 (N'SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'''' THEN 1 ELSE 0 END;'),
 (N'/* Drawers separados para que el framework pueda concatenarlos sin'),
 (N'ISNULL(@HTML_DRAWER_CONT,'''');'),
 (N'<script src="../js/vct-datagrid.js?v=3"></script>');

DECLARE @bad NVARCHAR(400) = NULL;
SELECT TOP 1 @bad = mk FROM @chk
WHERE (DATALENGTH(@D) - DATALENGTH(REPLACE(@D, mk, N''))) / NULLIF(DATALENGTH(mk),0) <> 1;
IF @bad IS NOT NULL
BEGIN
    DECLARE @msg NVARCHAR(600) = N'El fragmento "' + @bad + N'" no esta (o esta repetido). No se aplico nada.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

/* ---- 1. marca + variables del alta ---- */
SET @D = REPLACE(@D, N'SET NOCOUNT ON; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */', N'SET NOCOUNT ON; /* MIGRADO_DG: grillas internas con el motor vct-datagrid */
    DECLARE @PROY_ALTA_ERR VARCHAR(1000)='''', @PROY_ALTA_MSG VARCHAR(1000)=''''; /* ALTA_PROYECTO_V1 */');

/* ---- 2. guardado: bloque PROYECTO antes de calcular la reapertura ---- */
SET @mk = N'SET @VFORM_REOPEN=CASE WHEN @VFORM_ERROR<>'''' THEN 1 ELSE 0 END;';
SET @s = CHARINDEX(@mk, @D);
SET @n = N'        /* ---------------- PROYECTO (alta desde el menu del encabezado) ----------------
           Valida y graba dbo.VCT_PROYECTO_ALTA_GUARDAR (permiso PROYECTOS.CREATE). */
        IF @VFORM_ENTITY=''PROYECTO''
        BEGIN
            SET @ACTIVE_TAB=''proyectos'';
            SET @VFORM_ERROR='''';
            SET @PROY_ALTA_ERR='''';
            SET @PROY_ALTA_MSG='''';

            BEGIN TRY
                EXEC dbo.VCT_PROYECTO_ALTA_GUARDAR
                     @IPKEYJOB=@IPKEYJOB,
                     @IUNIDAD=@IUNIDAD,
                     @IAGENTE=@IAGENTE,
                     @ID_CLIENTE=@ID_CLIENTE,
                     @ERROR=@PROY_ALTA_ERR OUTPUT,
                     @MENSAJE=@PROY_ALTA_MSG OUTPUT;

                SET @VFORM_ERROR=LEFT(ISNULL(@PROY_ALTA_ERR,''''),1000);
            END TRY
            BEGIN CATCH
                SET @VFORM_ERROR=LEFT(''No se pudo grabar el proyecto: ''+ERROR_MESSAGE(),1000);
            END CATCH;

            IF @VFORM_ERROR<>'''' SET @PROY_ALTA_MSG='''';
        END;

';
SET @D = STUFF(@D, @s, 0, @n + N'        ');

/* ---- 3. modal: antes de armar OUTPARAM3 ---- */
SET @mk = N'/* Drawers separados para que el framework pueda concatenarlos sin';
SET @s = CHARINDEX(@mk, @D);
SET @n = N'    /* ============================================================
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
    DECLARE @HTML_MODAL_PROY VARCHAR(MAX)='''';
    DECLARE @CAN_CREATE_PROY BIT=0;

    SET @CAN_CREATE_PROY=ISNULL(dbo.VCT_PERFIL_PUEDE(@IUNIDAD,''PROYECTOS.CREATE''),0);

    IF @CAN_CREATE_PROY=1
    BEGIN
        DECLARE
            @PROY_REOPEN BIT=0,
            @P11 VARCHAR(4000)='''',@P13 VARCHAR(4000)='''',@P14 VARCHAR(4000)='''',@P15 VARCHAR(4000)='''',
            @P17 VARCHAR(4000)='''',@P18 VARCHAR(4000)='''',
            @P20 VARCHAR(4000)='''',@P21 VARCHAR(4000)='''',@P22 VARCHAR(4000)='''',
            @P24 VARCHAR(4000)='''',@P25 VARCHAR(4000)='''',@P26 VARCHAR(4000)='''',
            @PROY_NEXT_COD VARCHAR(20)='''',
            @ERR_PROY VARCHAR(MAX)='''',
            @PROY_SUBT VARCHAR(500)='''',
            @OPT_PROY_CONT VARCHAR(MAX)='''',
            @OPT_PROY_ANAL VARCHAR(MAX)='''',
            @OPT_PROY_SERV VARCHAR(MAX)='''',
            @OPT_PROY_NORM VARCHAR(MAX)='''';

        SET @PROY_REOPEN=CASE WHEN @VFORM_REOPEN=1 AND @VFORM_ENTITY=''PROYECTO'' THEN 1 ELSE 0 END;
        SET @ERR_PROY=CASE WHEN @VFORM_ENTITY=''PROYECTO'' THEN ISNULL(@VFORM_ERROR,'''') ELSE '''' END;

        IF @PROY_REOPEN=1
            SELECT TOP 1
                @P11=ISNULL(TEXTO11,''''),@P13=ISNULL(TEXTO13,''''),@P14=ISNULL(TEXTO14,''''),@P15=ISNULL(TEXTO15,''''),
                @P17=ISNULL(TEXTO17,''''),@P18=ISNULL(TEXTO18,''''),
                @P20=ISNULL(TEXTO20,''''),@P21=ISNULL(TEXTO21,''''),@P22=ISNULL(TEXTO22,''''),
                @P24=ISNULL(TEXTO24,''''),@P25=ISNULL(TEXTO25,''''),@P26=ISNULL(TEXTO26,'''')
            FROM dbo.VCT_BUFFER WITH(NOLOCK)
            WHERE PAR_KEY=@IPKEYJOB;

        /* Codigo estimado (el definitivo se asigna al grabar). */
        SELECT @PROY_NEXT_COD=CONVERT(VARCHAR(20),ISNULL(MAX(N),0)+1)
        FROM
        (
            SELECT CASE WHEN CODIGO NOT LIKE ''%[^0-9]%'' AND LEN(CODIGO) BETWEEN 1 AND 9 THEN CONVERT(INT,CODIGO) END AS N
            FROM dbo.VCT_PROYECTOS WITH(NOLOCK)
        ) X;

        SET @PROY_SUBT=''Cliente: ''+REPLACE(REPLACE(REPLACE(ISNULL(@Cliente,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'');

        /* ---- opciones ---- */
        SELECT @OPT_PROY_CONT=ISNULL((
            SELECT
                ''<option value="''+CONVERT(VARCHAR(20),C.ID)+''">''+
                REPLACE(REPLACE(REPLACE(
                    ISNULL(NULLIF(C.NOMBRE,''''),''-'')+CASE WHEN ISNULL(C.CARGO,'''')<>'''' THEN '' - ''+C.CARGO ELSE '''' END,
                    ''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'')+
                ''</option>''
            FROM #CONTACTOS360 C
            ORDER BY C.APELLIDO,C.NOMBRES,C.ID
            FOR XML PATH(''''),TYPE
        ).value(''.'',''VARCHAR(MAX)''),'''');

        SELECT @OPT_PROY_ANAL=ISNULL((
            SELECT
                ''<option value="''+CONVERT(VARCHAR(20),E.ID)+''">''+
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(E.APELLIDOS,'''')+'', ''+ISNULL(E.NOMBRES,''''))),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'')+
                ''</option>''
            FROM dbo.VCT_EMPLEADOS E WITH(NOLOCK)
            WHERE ISNULL(E.ESTADO,''ACTIVO'')=''ACTIVO''
            ORDER BY E.APELLIDOS,E.NOMBRES
            FOR XML PATH(''''),TYPE
        ).value(''.'',''VARCHAR(MAX)''),'''');

        SELECT @OPT_PROY_SERV=ISNULL((
            SELECT
                ''<option value="''+CONVERT(VARCHAR(20),S.ID)+''" data-codigo="''+UPPER(ISNULL(S.CODIGO,''''))+''">''+
                REPLACE(REPLACE(REPLACE(ISNULL(S.DESCRIPCION,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'')+
                ''</option>''
            FROM dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK)
            WHERE ISNULL(S.ESTADO,''ACTIVO'')=''ACTIVO''
            ORDER BY S.ID
            FOR XML PATH(''''),TYPE
        ).value(''.'',''VARCHAR(MAX)''),'''');

        SELECT @OPT_PROY_NORM=ISNULL((
            SELECT
                ''<option value="''+CONVERT(VARCHAR(20),N.ID)+''">''+
                REPLACE(REPLACE(REPLACE(ISNULL(N.DESCRIPCION,''''),''&'',''&amp;''),''<'',''&lt;''),''>'',''&gt;'')+
                ''</option>''
            FROM dbo.VCT_PRM_NORMAS N WITH(NOLOCK)
            WHERE ISNULL(N.ESTADO,''ACTIVO'')=''ACTIVO''
            ORDER BY N.DESCRIPCION
            FOR XML PATH(''''),TYPE
        ).value(''.'',''VARCHAR(MAX)''),'''');

        /* ---- campos ---- */
        DELETE FROM #VCT_FORM_FIELDS;
        INSERT INTO #VCT_FORM_FIELDS VALUES
        (1,''TEXTO11'',''Nombre del proyecto'',''TEXT'',9,1,300,''Ej.: Implementaci&oacute;n ISO 9001:2015'',NULL,NULLIF(@P11,''''),0,0,NULL,NULL),
        (2,''TEXTO12'',''C&oacute;digo'',''TEXT'',3,0,20,NULL,NULL,@PROY_NEXT_COD,1,0,''Se confirma al guardar.'',NULL),
        (3,''TEXTO22'',''Servicios'',''TEXT'',12,1,4000,NULL,NULL,NULLIF(@P22,''''),0,0,NULL,NULL),
        (4,''TEXTO24'',''Normas'',''TEXT'',12,1,4000,NULL,NULL,NULLIF(@P24,''''),0,0,NULL,NULL),
        (5,''TEXTO13'',''Fecha de inicio'',''DATE'',4,0,NULL,''Fecha de inicio'',NULL,NULLIF(@P13,''''),0,0,NULL,NULL),
        (6,''TEXTO14'',''Fecha de fin'',''DATE'',4,0,NULL,''Fecha de fin'',NULL,NULLIF(@P14,''''),0,0,NULL,NULL),
        (7,''TEXTO15'',''Horas contratadas'',''NUMBER'',4,0,6,''0'',NULL,NULLIF(@P15,''''),0,0,NULL,NULL),
        (8,''TEXTO17'',''Contacto del cliente'',''TEXT'',8,0,20,NULL,NULL,NULLIF(@P17,''''),0,0,NULL,NULL),
        (9,''TEXTO18'',''Nivel de riesgo'',''TEXT'',4,0,20,NULL,NULL,NULLIF(@P18,''''),0,0,NULL,NULL),
        (10,''TEXTO20'',''Analista a cargo'',''TEXT'',6,0,20,NULL,NULL,NULLIF(@P20,''''),0,0,''Recibe un mail y una gesti&oacute;n para organizar el lanzamiento.'',NULL),
        (11,''TEXTO21'',''Fecha l&iacute;mite de lanzamiento'',''DATE'',6,0,NULL,''Fecha l&iacute;mite'',NULL,NULLIF(@P21,''''),0,0,''Vencimiento de la gesti&oacute;n del analista.'',NULL),
        (12,''TEXTO25'',''Rentabilidad estimada'',''TEXT'',12,0,4000,NULL,NULL,NULLIF(@P25,''''),0,0,NULL,NULL),
        (13,''TEXTO26'',''Comentario rentabilidad'',''HIDDEN'',12,0,NULL,NULL,NULL,NULLIF(@P26,''''),0,1,NULL,NULL),
        (14,''IDSELEC02'',''ID'',''HIDDEN'',12,0,NULL,NULL,NULL,NULL,0,1,NULL,NULL),
        (15,''TEXTO30'',''Entidad'',''HIDDEN'',12,0,NULL,NULL,NULL,''PROYECTO'',0,1,NULL,NULL),
        (16,''FLAG01'',''Guardar'',''HIDDEN'',12,0,NULL,NULL,NULL,''1'',0,1,NULL,NULL),
        (17,''FLAG03'',''Eliminar'',''HIDDEN'',12,0,NULL,NULL,NULL,''0'',0,1,NULL,NULL),
        (18,''FLAG04'',''PrincipalCmd'',''HIDDEN'',12,0,NULL,NULL,NULL,''0'',0,1,NULL,NULL),
        (19,''ACTIVE_TAB'',''Tab'',''HIDDEN'',12,0,NULL,NULL,NULL,''proyectos'',0,1,NULL,NULL);

        EXEC dbo.VCT_MAIN_RENDER_FORM
             @FORM_ID=''vctModalProyecto'',@TITLE=''Nuevo proyecto'',
             @SUBTITLE=@PROY_SUBT,@ICON=''folder'',
             @LAYOUT=''MODAL'',@SAVE_LABEL=''Crear proyecto'',@CANCEL_LABEL=''Cancelar'',
             @ERROR_MESSAGE=@ERR_PROY,
             @OPEN_ON_RENDER=@PROY_REOPEN,
             @OUTHTML=@HTML_MODAL_PROY OUTPUT;

        /* Fechas con el date picker propio y marca para el CSS del alta. */
        SET @HTML_MODAL_PROY=REPLACE(ISNULL(@HTML_MODAL_PROY,''''),''type="date" '',''type="date" data-vct-datepicker '');
        SET @HTML_MODAL_PROY=REPLACE(@HTML_MODAL_PROY,''class="vct-modal vct-form-shell '',''class="vct-modal vct-form-shell vct-proy-alta '');

        SET @HTML_MODAL_PROY=@HTML_MODAL_PROY+
            ''<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO17" data-vct-placeholder="''+CASE WHEN @OPT_PROY_CONT='''' THEN ''El cliente no tiene contactos cargados'' ELSE ''Seleccione un contacto'' END+''">''+@OPT_PROY_CONT+''</template>''+
            ''<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO18" data-vct-placeholder="Seleccione"><option value="Bajo">Bajo</option><option value="Medio">Medio</option><option value="Alto">Alto</option></template>''+
            ''<template data-vct-field-options data-vct-target="vctModalProyecto" data-vct-field="TEXTO20" data-vct-placeholder="Sin asignar">''+@OPT_PROY_ANAL+''</template>''+
            ''<template data-vct-proy-catalog="servicios">''+@OPT_PROY_SERV+''</template>''+
            ''<template data-vct-proy-catalog="normas">''+@OPT_PROY_NORM+''</template>'';
    END;

    /* Aviso de alta OK: lo muestra vct-proyecto-alta.js como toast. */
    IF ISNULL(@PROY_ALTA_MSG,'''')<>''''
        SET @HTML_MODAL_PROY=ISNULL(@HTML_MODAL_PROY,'''')+
            ''<div hidden data-vct-proy-alta-ok="''+REPLACE(REPLACE(REPLACE(REPLACE(@PROY_ALTA_MSG,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'')+''"></div>'';

';
SET @D = STUFF(@D, @s, 0, @n + N'    ');

/* ---- 4. OUTPARAM3: agrega el modal ---- */
SET @D = REPLACE(@D, N'ISNULL(@HTML_DRAWER_CONT,'''');', N'ISNULL(@HTML_DRAWER_CONT,'''')+ISNULL(@HTML_MODAL_PROY,'''');');

/* ---- 5. assets: date picker + alta de proyecto ---- */
SET @D = REPLACE(@D, N'<script src="../js/vct-datagrid.js?v=3"></script>', N'<script src="../js/vct-datagrid.js?v=3"></script><link rel="stylesheet" href="../css/vct-datepicker.css?v=1"><script src="../js/vct-datepicker.js?v=2"></script><link rel="stylesheet" href="../css/vct-proyecto-alta.css?v=1"><script src="../js/vct-proyecto-alta.js?v=1"></script>');

/* ---- CREATE -> ALTER (tolera espacios extra) ---- */
SET @s = CHARINDEX(N'CREATE', @D);
IF @s > 0 AND @s < 4000 AND CHARINDEX(N'PROC', SUBSTRING(@D, @s, 40)) > 0
    SET @D = STUFF(@D, @s, 6, N'ALTER ');

IF PATINDEX(N'%ALTER%PROC%', LEFT(@D, 4000)) = 0
BEGIN
    RAISERROR('La definicion no contiene ALTER/CREATE PROCEDURE. No se aplico nada.',16,1);
    RETURN;
END;

EXEC sp_executesql @D;
PRINT 'OK: VCT_MAIN_CLIENTES_V360 con alta de proyecto.';
GO
