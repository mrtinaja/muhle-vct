/* PARCHE V13 - REVISION DE CABECERAS Y FORMATO SSMS. Ejecutar UNA vez en desarrollo despues del paquete v12.
 Lee la definicion vigente, modifica solo los bloques reconocidos y conserva el resto.
 No deshabilita triggers, no elimina actividades y no ejecuta guardados de prueba.
 SQL Server 2017 (entorno de desarrollo). Instalacion atomica de los dos SP.
*/
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX),@OLD NVARCHAR(MAX),@NEW NVARCHAR(MAX),
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100);
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360','P') IS NULL
 OR OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR','P') IS NULL
 OR OBJECT_ID('dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD','U') IS NULL
 OR OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS','U') IS NULL
 OR OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_REGISTRO','U') IS NULL
 OR OBJECT_ID('dbo.VCT_PROYECTOS_VISITAS_CONSULTORES','U') IS NULL
   THROW 51013,'Faltan objetos requeridos por v12. Sin cambios.',1;
 SET @D=REPLACE(OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),CHAR(13),'');
 IF @D IS NULL THROW 51013,'Definicion de Proyecto no visible. Sin cambios.',1;
 IF CHARINDEX('CAL13_PROYECTO',@D)=0
 BEGIN

 SET @OLD=N'    DECLARE @AG_EV VARCHAR(MAX) = ''['' + ISNULL(STUFF((
        SELECT '',{"f":"'' + CONVERT(VARCHAR(10), VENCE, 120)
             + ''","x":"'' + REPLACE(REPLACE(REPLACE(ISNULL(TITULO,''''),'''',''/''),''"'',''''''''),CHAR(10),'' '')
             + ''","c":"'' + CASE WHEN CONVERT(DATE,VENCE) < CONVERT(DATE,@HOY) THEN ''V''
                                WHEN CONVERT(DATE,VENCE) = CONVERT(DATE,@HOY) THEN ''H''
                                WHEN CONVERT(DATE,VENCE) <= DATEADD(DAY,7,CONVERT(DATE,@HOY)) THEN ''P''
                                ELSE ''L'' END
             + ''"}''
        FROM #A WHERE VENCE IS NOT NULL AND SIT <> ''C''
        ORDER BY VENCE
        FOR XML PATH(''''), TYPE).value(''.'',''VARCHAR(MAX)''), 1, 1, ''''), '''') + '']'';
';
 SET @NEW=N'    /* CAL13_PROYECTO: acciones, visitas y horas; sin funciones auxiliares. */
    DECLARE @CAL13_EVT TABLE (F DATE, X VARCHAR(1000), K VARCHAR(20), C VARCHAR(5));
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,VENCE), LEFT(ISNULL(TITULO,''''),1000), '''',
      CASE WHEN CONVERT(DATE,VENCE)<CONVERT(DATE,@HOY) THEN ''V''
           WHEN CONVERT(DATE,VENCE)=CONVERT(DATE,@HOY) THEN ''H''
           WHEN CONVERT(DATE,VENCE)<=DATEADD(DAY,7,CONVERT(DATE,@HOY)) THEN ''P'' ELSE ''L'' END
    FROM #A WHERE VENCE IS NOT NULL AND SIT<>''C'';
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,V.FECHA_DESDE), LEFT(''Visita: ''+ISNULL(NULLIF(V.LUGAR,''''),''Proyecto'')
      +CASE WHEN V.FECHA_HASTA IS NOT NULL AND CONVERT(DATE,V.FECHA_HASTA)<>CONVERT(DATE,V.FECHA_DESDE)
        THEN '' (hasta ''+CONVERT(VARCHAR(10),V.FECHA_HASTA,103)+'')'' ELSE '''' END,1000),
      CASE WHEN CONVERT(DATE,V.FECHA_DESDE)>=CONVERT(DATE,@HOY) THEN ''AGENDADA'' ELSE ''PENDIENTE'' END,''''
    FROM dbo.VCT_PROYECTOS_VISITAS V
    WHERE V.ID_PROYECTO=@ID_PROYECTO AND V.FECHA_DESDE IS NOT NULL
      AND ISNULL(V.ESTADO,'''') NOT IN (''CANCELADO'',''CANCELADA'',''ANULADO'',''ANULADA'')
      AND NOT EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R WHERE R.ID_VISITA=V.ID);
    INSERT INTO @CAL13_EVT (F,X,K,C)
    SELECT CONVERT(DATE,R.FECHA), LEFT(''Horas registradas: ''+CONVERT(VARCHAR(30),R.HORAS)+'' h''
      +CASE WHEN NULLIF(V.LUGAR,'''') IS NOT NULL THEN '' - ''+V.LUGAR ELSE '''' END,1000),''REGISTRADA'',''''
    FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO R JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID=R.ID_VISITA
    WHERE V.ID_PROYECTO=@ID_PROYECTO AND R.FECHA IS NOT NULL
      AND ISNULL(V.ESTADO,'''') NOT IN (''CANCELADO'',''CANCELADA'',''ANULADO'',''ANULADA'');
    DECLARE @AG_EV VARCHAR(MAX) = ''['' + ISNULL(STUFF((
      SELECT '',{"f":"''+CONVERT(VARCHAR(10),F,120)+''","x":"''
        +CONVERT(VARCHAR(MAX),STRING_ESCAPE(CONVERT(NVARCHAR(MAX),X),''json''))
        +''","k":"''+K+''","c":"''+C+''"}''
      FROM @CAL13_EVT ORDER BY F,X
      FOR XML PATH(''''),TYPE).value(''.'',''VARCHAR(MAX)''),1,1,''''),'''')+'']'';
';
 SET @OLD=REPLACE(@OLD,CHAR(13),'');
 SET @NEW=REPLACE(@NEW,CHAR(13),'');
 IF CHARINDEX(@OLD,@D)=0 OR CHARINDEX(@OLD,@D,CHARINDEX(@OLD,@D)+LEN(@OLD))>0
   THROW 51013, 'Proyecto datos: la definicion cambio. No se aplico el parche.',1;
 SET @D=REPLACE(@D,@OLD,@NEW);


 SET @OLD=N'    DECLARE @AG_PANEL VARCHAR(MAX) =
        CASE WHEN @AG_EV = ''[]'' THEN ''<div class="vct-360-empty">Sin acciones con fecha para mostrar en el calendario.</div>'' ELSE
        ''<div class="vct-agenda vct-acc-cal-embed" data-vct-agenda-root data-vct-calendar-events="'' + @AG_EV + ''">''
      + ''<div class="vct-agenda-toolbar">''
      +   ''<div class="vct-agenda-nav"><button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>''
      +   ''<h2 class="vct-agenda-title" data-vct-agenda-title></h2>''
      +   ''<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button></div>''
      +   ''<div class="vct-agenda-view-toggle"><button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>''
      +     ''<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button>''
      +     ''<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">D'' + CHAR(237) + ''a</button></div>''
      +   ''<div class="vct-agenda-jump"><select class="vct-select vct-agenda-select-month" data-vct-agenda-select-month data-vct-native="true" data-vct-custom-init="true">'' + @AG_MONTHS + ''</select>''
      +     ''<select class="vct-select vct-agenda-select-year" data-vct-agenda-select-year data-vct-native="true" data-vct-custom-init="true"></select></div>''
      + ''</div>''
      + ''<div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div>''
      + ''</div>'' END;

';
 SET @NEW=N'    DECLARE @AG_PANEL VARCHAR(MAX) =
        ''<div class="vct-agenda vct-acc-cal-embed" data-vct-agenda-root data-vct-calendar-events="'' + @AG_EV + ''">''
      + ''<div class="vct-agenda-toolbar">''
      +   ''<div class="vct-agenda-nav"><button type="button" class="vct-agenda-nav-btn" data-vct-agenda-prev aria-label="Anterior"><span data-vct-icon="chevron-left"></span></button>''
      +   ''<h2 class="vct-agenda-title" data-vct-agenda-title></h2>''
      +   ''<button type="button" class="vct-agenda-nav-btn" data-vct-agenda-next aria-label="Siguiente"><span data-vct-icon="chevron-right"></span></button></div>''
      +   ''<div class="vct-agenda-view-toggle"><button type="button" class="vct-agenda-view-btn is-active" data-vct-agenda-view="month">Mes</button>''
      +     ''<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="week">Semana</button>''
      +     ''<button type="button" class="vct-agenda-view-btn" data-vct-agenda-view="day">D'' + CHAR(237) + ''a</button></div>''
      +   ''<div class="vct-agenda-jump"><select class="vct-select vct-agenda-select-month" data-vct-agenda-select-month data-vct-native="true" data-vct-custom-init="true">'' + @AG_MONTHS + ''</select>''
      +     ''<select class="vct-select vct-agenda-select-year" data-vct-agenda-select-year data-vct-native="true" data-vct-custom-init="true"></select></div>''
      + ''</div>''
      + ''<div class="vct-agenda-view-pane" data-vct-agenda-view-pane></div>''
      + ''</div>''; /* CAL13_CALENDARIO_SIEMPRE */

';
 SET @OLD=REPLACE(@OLD,CHAR(13),'');
 SET @NEW=REPLACE(@NEW,CHAR(13),'');
 IF CHARINDEX(@OLD,@D)=0 OR CHARINDEX(@OLD,@D,CHARINDEX(@OLD,@D)+LEN(@OLD))>0
   THROW 51013, 'Proyecto panel: la definicion cambio. No se aplico el parche.',1;
 SET @D=REPLACE(@D,@OLD,@NEW);


 /* Reconocer cabecera ignorando BOM, espacios y comentarios iniciales. */
 SET @HDR13_P=1;
 WHILE @HDR13_P<=LEN(@D)
 BEGIN
   IF UNICODE(SUBSTRING(@D,@HDR13_P,1)) IN(9,10,13,32,65279)
     SET @HDR13_P=@HDR13_P+1;
   ELSE IF SUBSTRING(@D,@HDR13_P,2)='--'
   BEGIN
     SET @HDR13_Q=CHARINDEX(CHAR(10),@D,@HDR13_P+2);
     IF @HDR13_Q=0 THROW 51013,'No hay cabecera despues del comentario. Sin cambios.',1;
     SET @HDR13_P=@HDR13_Q+1;
   END
   ELSE IF SUBSTRING(@D,@HDR13_P,2)='/*'
   BEGIN
     SET @HDR13_DEPTH=1; SET @HDR13_P=@HDR13_P+2;
     WHILE @HDR13_DEPTH>0 AND @HDR13_P<=LEN(@D)
     BEGIN
       IF SUBSTRING(@D,@HDR13_P,2)='/*'
       BEGIN SET @HDR13_DEPTH=@HDR13_DEPTH+1; SET @HDR13_P=@HDR13_P+2; END
       ELSE IF SUBSTRING(@D,@HDR13_P,2)='*/'
       BEGIN SET @HDR13_DEPTH=@HDR13_DEPTH-1; SET @HDR13_P=@HDR13_P+2; END
       ELSE SET @HDR13_P=@HDR13_P+1;
     END;
     IF @HDR13_DEPTH<>0 THROW 51013,'Comentario inicial sin cierre. Sin cambios.',1;
   END
   ELSE BREAK;
 END;
 SET @D=SUBSTRING(@D,@HDR13_P,LEN(@D));
 SET @HDR13_Q=CHARINDEX('PROCEDURE',UPPER(@D));
 IF @HDR13_Q=0 SET @HDR13_Q=CHARINDEX('PROC',UPPER(@D));
 IF @HDR13_Q=0 OR @HDR13_Q>100 THROW 51013,'No se reconoce PROCEDURE en la cabecera. Sin cambios.',1;
 SET @HDR13_PREFIX=UPPER(LEFT(@D,@HDR13_Q-1));
 SET @HDR13_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(@HDR13_PREFIX,' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
 IF @HDR13_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER')
   THROW 51013,'Prefijo de procedimiento no reconocido. Sin cambios.',1;
 SET @D=N'ALTER '+SUBSTRING(@D,@HDR13_Q,LEN(@D));
 EXEC sys.sp_executesql @D;

 END;
 SET @D=REPLACE(OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR')),CHAR(13),'');
 IF @D IS NULL THROW 51013,'Definicion de Agenda no visible. Sin cambios.',1;
 IF CHARINDEX('CAL13_VALIDACION',@D)=0
 BEGIN

 SET @OLD=N'                IF @MSG = ''''
                BEGIN
                    SET @B_DISP = CASE WHEN @B_TIPO=''DISPONIBLE'' THEN 1 ELSE 0 END;
                    IF @B_TIPO <> ''LICENCIA'' SET @B_MOT = '''';
                    IF @B_TIPO IN (''DISPONIBLE'',''LICENCIA'') SET @B_DESC = '''';
                    /* Horas cero para LICENCIA, OCUPADO y OBSERVACION. */
                    IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D)
                        UPDATE dbo.VCT_PRM_AGENDA_CONSULTOR
                           SET TIPO=@B_TIPO, DISPONIBLE=@B_DISP, HORAS_CAPACIDAD=@B_HORN,
                               MOTIVO=NULLIF(@B_MOT,''''), DESCRIPCION=NULLIF(@B_DESC,''''),
                               FECHA_UPD=GETDATE(), USUARIO_UPD=@U
                         WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D;
                    ELSE
                        INSERT INTO dbo.VCT_PRM_AGENDA_CONSULTOR (ID_CONSULTOR,FECHA,TIPO,HORAS_CAPACIDAD,DISPONIBLE,MOTIVO,DESCRIPCION,FECHA_ALTA,USUARIO_ALTA)
                        VALUES (@CONS_ID,@B_D,@B_TIPO,@B_HORN,@B_DISP,NULLIF(@B_MOT,''''),NULLIF(@B_DESC,''''),GETDATE(),@U);
                END;
';
 SET @NEW=N'                /* CAL13_VALIDACION: rechazos esperados se muestran dentro de Agenda. */
                IF @MSG='''' AND @B_TIPO=''LICENCIA''
                BEGIN
                    IF EXISTS(SELECT 1 FROM dbo.VCT_AGENDA_CONSULTOR_ACTIVIDAD
                      WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D AND ACTIVO=1)
                        SET @MSG=''El dia tiene actividades. Reprograme las actividades antes de cargar la licencia.'';
                    ELSE IF EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES C
                      JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID=C.ID_VISITA
                      WHERE C.ID_CONSULTOR=@CONS_ID
                        AND @B_D BETWEEN CONVERT(DATE,V.FECHA_DESDE) AND CONVERT(DATE,ISNULL(V.FECHA_HASTA,V.FECHA_DESDE))
                        AND ISNULL(V.ESTADO,'''') NOT IN (''CANCELADO'',''CANCELADA'',''ANULADO'',''ANULADA''))
                        SET @MSG=''El dia tiene una visita asignada. Reprograme la visita antes de cargar la licencia.'';
                    ELSE IF EXISTS(SELECT 1 FROM dbo.VCT_PROYECTOS_VISITAS_REGISTRO
                      WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D)
                        SET @MSG=''El dia tiene horas registradas. Revise el registro antes de cargar la licencia.'';
                END;
                DECLARE @CAL13_OWNTRAN BIT=0;
                BEGIN TRY
                    IF @MSG='''' AND @@TRANCOUNT=0
                    BEGIN
                        BEGIN TRANSACTION;
                        SET @CAL13_OWNTRAN=1;
                    END;
                IF @MSG = ''''
                BEGIN
                    SET @B_DISP = CASE WHEN @B_TIPO=''DISPONIBLE'' THEN 1 ELSE 0 END;
                    IF @B_TIPO <> ''LICENCIA'' SET @B_MOT = '''';
                    IF @B_TIPO IN (''DISPONIBLE'',''LICENCIA'') SET @B_DESC = '''';
                    /* Horas cero para LICENCIA, OCUPADO y OBSERVACION. */
                    IF EXISTS (SELECT 1 FROM dbo.VCT_PRM_AGENDA_CONSULTOR WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D)
                        UPDATE dbo.VCT_PRM_AGENDA_CONSULTOR
                           SET TIPO=@B_TIPO, DISPONIBLE=@B_DISP, HORAS_CAPACIDAD=@B_HORN,
                               MOTIVO=NULLIF(@B_MOT,''''), DESCRIPCION=NULLIF(@B_DESC,''''),
                               FECHA_UPD=GETDATE(), USUARIO_UPD=@U
                         WHERE ID_CONSULTOR=@CONS_ID AND FECHA=@B_D;
                    ELSE
                        INSERT INTO dbo.VCT_PRM_AGENDA_CONSULTOR (ID_CONSULTOR,FECHA,TIPO,HORAS_CAPACIDAD,DISPONIBLE,MOTIVO,DESCRIPCION,FECHA_ALTA,USUARIO_ALTA)
                        VALUES (@CONS_ID,@B_D,@B_TIPO,@B_HORN,@B_DISP,NULLIF(@B_MOT,''''),NULLIF(@B_DESC,''''),GETDATE(),@U);
                END;
                    IF @CAL13_OWNTRAN=1 COMMIT TRANSACTION;
                END TRY
                BEGIN CATCH
                    IF @CAL13_OWNTRAN=1 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION;
                    IF ERROR_NUMBER()<>51012 OR XACT_STATE()=-1 THROW;
                    SET @MSG=LEFT(ERROR_MESSAGE(),1000);
                END CATCH;
';
 SET @OLD=REPLACE(@OLD,CHAR(13),'');
 SET @NEW=REPLACE(@NEW,CHAR(13),'');
 IF CHARINDEX(@OLD,@D)=0 OR CHARINDEX(@OLD,@D,CHARINDEX(@OLD,@D)+LEN(@OLD))>0
   THROW 51013, 'Agenda guardado: la definicion cambio. No se aplico el parche.',1;
 SET @D=REPLACE(@D,@OLD,@NEW);


 /* Reconocer cabecera ignorando BOM, espacios y comentarios iniciales. */
 SET @HDR13_P=1;
 WHILE @HDR13_P<=LEN(@D)
 BEGIN
   IF UNICODE(SUBSTRING(@D,@HDR13_P,1)) IN(9,10,13,32,65279)
     SET @HDR13_P=@HDR13_P+1;
   ELSE IF SUBSTRING(@D,@HDR13_P,2)='--'
   BEGIN
     SET @HDR13_Q=CHARINDEX(CHAR(10),@D,@HDR13_P+2);
     IF @HDR13_Q=0 THROW 51013,'No hay cabecera despues del comentario. Sin cambios.',1;
     SET @HDR13_P=@HDR13_Q+1;
   END
   ELSE IF SUBSTRING(@D,@HDR13_P,2)='/*'
   BEGIN
     SET @HDR13_DEPTH=1; SET @HDR13_P=@HDR13_P+2;
     WHILE @HDR13_DEPTH>0 AND @HDR13_P<=LEN(@D)
     BEGIN
       IF SUBSTRING(@D,@HDR13_P,2)='/*'
       BEGIN SET @HDR13_DEPTH=@HDR13_DEPTH+1; SET @HDR13_P=@HDR13_P+2; END
       ELSE IF SUBSTRING(@D,@HDR13_P,2)='*/'
       BEGIN SET @HDR13_DEPTH=@HDR13_DEPTH-1; SET @HDR13_P=@HDR13_P+2; END
       ELSE SET @HDR13_P=@HDR13_P+1;
     END;
     IF @HDR13_DEPTH<>0 THROW 51013,'Comentario inicial sin cierre. Sin cambios.',1;
   END
   ELSE BREAK;
 END;
 SET @D=SUBSTRING(@D,@HDR13_P,LEN(@D));
 SET @HDR13_Q=CHARINDEX('PROCEDURE',UPPER(@D));
 IF @HDR13_Q=0 SET @HDR13_Q=CHARINDEX('PROC',UPPER(@D));
 IF @HDR13_Q=0 OR @HDR13_Q>100 THROW 51013,'No se reconoce PROCEDURE en la cabecera. Sin cambios.',1;
 SET @HDR13_PREFIX=UPPER(LEFT(@D,@HDR13_Q-1));
 SET @HDR13_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(@HDR13_PREFIX,' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
 IF @HDR13_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER')
   THROW 51013,'Prefijo de procedimiento no reconocido. Sin cambios.',1;
 SET @D=N'ALTER '+SUBSTRING(@D,@HDR13_Q,LEN(@D));
 EXEC sys.sp_executesql @D;

 END;
 COMMIT TRANSACTION;
 PRINT 'V13 instalado: calendario de Proyecto 360 siempre visible; acciones, visitas y horas; validacion de licencia dentro de Agenda.';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 -- Diagnostico de solo lectura si la version del servidor difiere de verdad.
 SELECT OBJECT_NAME(object_id) AS Objeto,
   CASE WHEN OBJECT_NAME(object_id)='VCT_MAIN_PROYECTO_V360'
   THEN SUBSTRING(definition,
       CASE WHEN CHARINDEX('DECLARE @AG_EV',definition)>0 THEN CHARINDEX('DECLARE @AG_EV',definition) ELSE 1 END,6000)
   ELSE SUBSTRING(definition,
       CASE WHEN CHARINDEX('IF @CAN_EDIT = 1 AND @CONS_ID IS NOT NULL',definition)>0
       THEN CHARINDEX('IF @CAN_EDIT = 1 AND @CONS_ID IS NOT NULL',definition) ELSE 1 END,8000)
   END AS BloqueActual
 FROM sys.sql_modules WHERE object_id IN(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'),OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR'));
 THROW;
END CATCH;
GO
SELECT @@SERVERNAME AS Servidor,DB_NAME() AS BaseActual;
SELECT OBJECT_NAME(object_id) AS Objeto,
 CASE WHEN definition LIKE '%CAL13_PROYECTO%' OR definition LIKE '%CAL13_VALIDACION%' THEN 'v13' ELSE 'Revisar' END AS Parche
FROM sys.sql_modules WHERE object_id IN(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'),OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR'));
GO
