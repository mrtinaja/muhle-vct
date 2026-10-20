/* FASE 2: ejecutar en la base de DESARROLLO correspondiente.
   Subir antes los assets de la entrega. No modifica filas de negocio.
   Conserva los SP vigentes: agrega un bloque final de render de lectura.
   Transaccion unica. Reejecutable. Ante un preflight fallido no cambia nada. */
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360','P') IS NULL OR OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360','P') IS NULL
BEGIN RAISERROR('Faltan las pantallas 360 esperadas. Sin cambios.',16,1); RETURN; END;
IF OBJECT_ID('dbo.VCT_FN_AGENDA_CONSULTOR_RANGO') IS NULL
BEGIN RAISERROR('Falta dbo.VCT_FN_AGENDA_CONSULTOR_RANGO o no es visible. Sin cambios.',16,1); RETURN; END;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.VCT_FN_AGENDA_CONSULTOR_RANGO') AND name IN ('FECHA','ESTADO','HORAS','NOTA'))<>4
BEGIN RAISERROR('La funcion de agenda no tiene FECHA/ESTADO/HORAS/NOTA esperadas. Sin cambios.',16,1); RETURN; END;
/* Comprueba el esquema real antes de compilar consultas directas de lectura. */
DECLARE @MISSING NVARCHAR(2000)=N'';
SELECT @MISSING=@MISSING+CASE WHEN @MISSING=N'' THEN N'' ELSE N', ' END+E.Objeto+N'.'+E.Columna
FROM (VALUES
 ('dbo.VCT_PROYECTOS_VISITAS','ID'),('dbo.VCT_PROYECTOS_VISITAS','ID_PROYECTO'),
 ('dbo.VCT_PROYECTOS_VISITAS','FECHA_DESDE'),('dbo.VCT_PROYECTOS_VISITAS','FECHA_HASTA'),
 ('dbo.VCT_PROYECTOS_VISITAS','LUGAR'),('dbo.VCT_PROYECTOS_VISITAS','ESTADO'),
 ('dbo.VCT_PROYECTOS_VISITAS_REGISTRO','ID'),('dbo.VCT_PROYECTOS_VISITAS_REGISTRO','ID_VISITA'),
 ('dbo.VCT_PROYECTOS_VISITAS_REGISTRO','FECHA'),('dbo.VCT_PROYECTOS_VISITAS_REGISTRO','HORAS')
) E(Objeto,Columna)
WHERE NOT EXISTS(SELECT 1 FROM sys.columns C WHERE C.object_id=OBJECT_ID(E.Objeto) AND C.name=E.Columna);
IF @MISSING<>N''
BEGIN SELECT @MISSING AS ColumnasFaltantes; RAISERROR('El esquema de visitas difiere. Revise ColumnasFaltantes. Sin cambios.',16,1); RETURN; END;
IF OBJECT_ID('dbo.VCT_CALENDAR_V360_RENDER') IS NOT NULL AND CHARINDEX('VCT_CALENDAR_360_20261016_V2',ISNULL(OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_CALENDAR_V360_RENDER')),''))=0
BEGIN RAISERROR('Ya existe un helper con el mismo nombre y otra definicion. Sin cambios.',16,1); RETURN; END;
DECLARE @D NVARCHAR(MAX), @TAIL NVARCHAR(MAX), @PROC SYSNAME, @ENTITY VARCHAR(20), @KEY SYSNAME,
        @POS INT, @DONE INT=0;
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID('dbo.VCT_CALENDAR_V360_RENDER','P') IS NULL
 BEGIN
  EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.VCT_CALENDAR_V360_RENDER
    @ENTITY VARCHAR(20), @ENTITY_ID INT, @IUNIDAD VARCHAR(100), @HTML VARCHAR(MAX) OUTPUT
AS
/* VCT_CALENDAR_360_20261016_V2 */
BEGIN
    SET NOCOUNT ON;
    SET @HTML='''';
    IF ISNULL(@ENTITY_ID,0)<=0 RETURN;
    IF @ENTITY NOT IN (''PROYECTO'',''CONSULTOR'') RETURN;
    /* Se invoca solo desde la salida ya autorizada de la ficha 360.
       El instalador no concede permisos nuevos sobre este helper. */
    DECLARE @DESDE DATE=DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE())-1,0),
            @HASTA DATE=DATEADD(DAY,-1,DATEADD(YEAR,DATEDIFF(YEAR,0,GETDATE())+2,0)),
            @JSON VARCHAR(MAX), @YEARS VARCHAR(1000)='''', @Y INT=YEAR(GETDATE())-1,
            @PREFIX VARCHAR(10)=CASE WHEN @ENTITY=''CONSULTOR'' THEN ''agc'' ELSE ''agenda'' END;

    /* Una fila por registro; visitas sin registro se ubican en su fecha inicial.
       Se muestra el estado almacenado, sin reconstruir reglas de negocio. */
    CREATE TABLE #VCT_CALENDAR_EVENTS (F DATE, E VARCHAR(40), H DECIMAL(12,2), N VARCHAR(MAX));
    IF @ENTITY=''PROYECTO''
    BEGIN
        INSERT #VCT_CALENDAR_EVENTS(F,E,H,N)
        SELECT CONVERT(DATE,ISNULL(CONVERT(DATETIME,R.FECHA),V.FECHA_DESDE)),
               CASE WHEN R.ID IS NOT NULL THEN ''REGISTRADA'' ELSE ''VISITA'' END,
               ISNULL(R.HORAS,0),
               ''Visita ''+CONVERT(VARCHAR(20),V.ID)+'' - Estado: ''+ISNULL(NULLIF(V.ESTADO,''''),''Sin estado'')+
               CASE WHEN R.ID IS NOT NULL THEN '' - ''+CONVERT(VARCHAR(30),CONVERT(DECIMAL(12,2),ISNULL(R.HORAS,0)))+'' h registradas''
                    ELSE '' - Sin registro de horas'' END+
               CASE WHEN ISNULL(V.LUGAR,'''')='''' THEN '''' ELSE '' - ''+V.LUGAR END+
               CASE WHEN CONVERT(DATE,V.FECHA_DESDE)<>CONVERT(DATE,V.FECHA_HASTA)
                    THEN '' (periodo ''+CONVERT(VARCHAR(10),V.FECHA_DESDE,103)+'' al ''+CONVERT(VARCHAR(10),V.FECHA_HASTA,103)+'')'' ELSE '''' END
        FROM dbo.VCT_PROYECTOS_VISITAS V
        LEFT JOIN dbo.VCT_PROYECTOS_VISITAS_REGISTRO R ON R.ID_VISITA=V.ID
        WHERE V.ID_PROYECTO=@ENTITY_ID
          AND CONVERT(DATE,ISNULL(CONVERT(DATETIME,R.FECHA),V.FECHA_DESDE)) BETWEEN @DESDE AND @HASTA;
    END
    ELSE
    BEGIN
        INSERT #VCT_CALENDAR_EVENTS(F,E,H,N)
        SELECT R.FECHA,R.ESTADO,ISNULL(R.HORAS,0),ISNULL(R.NOTA,'''')
        FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@ENTITY_ID,@DESDE,@HASTA) R;
    END;

    /* Escape JSON completo de controles + escape HTML del atributo al final. */
    UPDATE #VCT_CALENDAR_EVENTS SET N=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N,''\'',''\\''),''"'',''\"''),CHAR(13),''\r''),CHAR(10),''\n''),CHAR(9),''\t'');
    DECLARE @CONTROL INT=0;
    WHILE @CONTROL<32
    BEGIN
        IF @CONTROL NOT IN (0,9,10,13)
            UPDATE #VCT_CALENDAR_EVENTS SET N=REPLACE(N,CHAR(@CONTROL),'' '');
        SET @CONTROL=@CONTROL+1;
    END;
    /* NUL no es un caracter valido en los datos XML usados por este sistema. */
    SET @JSON=''[''+ISNULL(STUFF((
        SELECT '',{"f":"''+CONVERT(VARCHAR(10),F,23)+''",''+
               CASE WHEN @ENTITY=''CONSULTOR''
                    THEN ''"e":"''+E+''","h":''+CONVERT(VARCHAR(30),H)+'',"n":"''+ISNULL(N,'''')+''","t":"","mo":"","de":""}''
                    ELSE ''"k":"''+E+''","x":"''+ISNULL(N,'''')+''"}'' END
        FROM #VCT_CALENDAR_EVENTS ORDER BY F,E,N
        FOR XML PATH(''''),TYPE).value(''.'',''VARCHAR(MAX)''),1,1,''''),'''')+'']'';
    SET @JSON=REPLACE(REPLACE(REPLACE(REPLACE(@JSON,''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;''),''>'',''&gt;'');
    WHILE @Y<=YEAR(GETDATE())+1
    BEGIN
        SET @YEARS=@YEARS+''<option value="''+CONVERT(VARCHAR(4),@Y)+''">''+CONVERT(VARCHAR(4),@Y)+''</option>'';
        SET @Y=@Y+1;
    END;

    SET @HTML=CONVERT(VARCHAR(MAX),'''')+
      ''<link rel="stylesheet" href="../css/vct-calendario.css?v=1">''+
      CASE WHEN @ENTITY=''CONSULTOR'' THEN ''<link rel="stylesheet" href="../css/vct-calendario.css?v=1">'' ELSE '''' END+
      ''<div class="vct-agenda-page vct-calendar-embedded''+CASE WHEN @ENTITY=''CONSULTOR'' THEN '' vct-agc-page'' ELSE '''' END+''" ''+
      CASE WHEN @ENTITY=''CONSULTOR'' THEN ''data-vct-agc-root data-vct-agc-can-edit="0" data-vct-agc-cons="''+CONVERT(VARCHAR(20),@ENTITY_ID)+''" data-vct-agc-dias="''+@JSON+''"''
           ELSE ''data-vct-agenda-root data-vct-agenda-can-edit="0" data-vct-feriados="[]" data-vct-calendar-events="''+@JSON+''"'' END+''>''+
      ''<section class="vct-card vct-agenda-card"><div class="vct-agenda-toolbar">''+
      ''<div class="vct-agenda-view-toggle">''+
      ''<button type="button" class="vct-agenda-view-btn is-active" data-vct-''+@PREFIX+''-view="month">Mes</button>''+
      ''<button type="button" class="vct-agenda-view-btn" data-vct-''+@PREFIX+''-view="week">Semana</button>''+
      ''<button type="button" class="vct-agenda-view-btn" data-vct-''+@PREFIX+''-view="day">D&iacute;a</button></div>''+
      ''<div class="vct-agenda-nav"><button type="button" class="vct-agenda-nav-btn" data-vct-''+@PREFIX+''-prev aria-label="Anterior">&#8249;</button>''+
      ''<h2 class="vct-agenda-title" data-vct-''+@PREFIX+''-title></h2>''+
      ''<button type="button" class="vct-agenda-nav-btn" data-vct-''+@PREFIX+''-next aria-label="Siguiente">&#8250;</button></div>''+
      ''<div class="vct-agenda-toolbar-right"><div class="vct-agenda-jump">''+
      ''<select class="vct-select" data-vct-native="true" data-vct-custom-init="true" aria-label="Mes" data-vct-''+@PREFIX+
      CASE WHEN @ENTITY=''CONSULTOR'' THEN ''-month'' ELSE ''-select-month'' END+''>''+ 
      ''<option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option><option value="4">Abril</option>''+
      ''<option value="5">Mayo</option><option value="6">Junio</option><option value="7">Julio</option><option value="8">Agosto</option>''+
      ''<option value="9">Septiembre</option><option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option></select>''+
      ''<select class="vct-select" data-vct-native="true" data-vct-custom-init="true" aria-label="A&ntilde;o" data-vct-''+@PREFIX+
      CASE WHEN @ENTITY=''CONSULTOR'' THEN ''-year'' ELSE ''-select-year'' END+''>''+@YEARS+''</select></div></div></div>''+
      ''<p class="vct-agenda-calendar-range">Consulta del ''+CONVERT(VARCHAR(10),@DESDE,103)+'' al ''+CONVERT(VARCHAR(10),@HASTA,103)+''. ''+
      CASE WHEN @ENTITY=''PROYECTO'' THEN ''Visitas y horas registradas del proyecto. Las visitas sin registro se muestran en su fecha inicial; el per&iacute;odo completo figura en la etiqueta.''
           ELSE ''Disponibilidad, asignaciones y feriados del consultor. La carga y edici&oacute;n se realiza desde Agenda Consultor.'' END+''</p>''+
      CASE WHEN @ENTITY=''PROYECTO'' AND NOT EXISTS(SELECT 1 FROM #VCT_CALENDAR_EVENTS) THEN ''<p class="vct-agenda-calendar-range">Sin visitas en este per&iacute;odo.</p>'' ELSE '''' END+
      ''<div class="vct-agenda-view-pane" ''+CASE WHEN @ENTITY=''CONSULTOR'' THEN ''data-vct-agc-pane'' ELSE ''data-vct-agenda-view-pane'' END+''></div>''+
      ''</section></div><script src="../js/''+CASE WHEN @ENTITY=''CONSULTOR'' THEN ''vct-calendario.js?v=1'' ELSE ''vct-calendario.js?v=1'' END+''"></script>'';
END;
';
 END;
 DECLARE C CURSOR LOCAL FAST_FORWARD FOR
 SELECT 'VCT_MAIN_PROYECTO_V360','PROYECTO','IDSELEC02' UNION ALL SELECT 'VCT_MAIN_CONSULTORES_V360','CONSULTOR','IDSELEC01';
 OPEN C; FETCH NEXT FROM C INTO @PROC,@ENTITY,@KEY;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @D=OBJECT_DEFINITION(OBJECT_ID('dbo.'+@PROC));
  IF @D IS NULL RAISERROR('No se puede leer la definicion del SP. Sin cambios.',16,1);
  IF CHARINDEX('VCT_CALENDAR_360_20261016_V2',@D)=0
  BEGIN
   IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID('dbo.'+@PROC) AND name IN ('@OUTPARAM1','@IPKEYJOB','@IUNIDAD'))<>3
       RAISERROR('Firma de SP 360 inesperada. Sin cambios.',16,1);
   IF CHARINDEX('data-vct-panel="agenda"',@D)=0
       RAISERROR('No se encontro la pestania Agenda en el SP vigente. Sin cambios.',16,1);
   SET @TAIL=NCHAR(13)+NCHAR(10)+N'/* VCT_CALENDAR_360_20261016_V2 */
IF CHARINDEX(''data-vct-panel="agenda">'',ISNULL(@OUTPARAM1,''''))>0
BEGIN
 DECLARE @VCT_CAL360_ID INT=0, @VCT_CAL360_HTML VARCHAR(MAX)='''';
 SELECT TOP (1) @VCT_CAL360_ID=ISNULL('+QUOTENAME(@KEY)+N',0) FROM dbo.VCT_BUFFER WHERE PAR_KEY=@IPKEYJOB;
 EXEC dbo.VCT_CALENDAR_V360_RENDER @ENTITY='''+@ENTITY+N''',@ENTITY_ID=@VCT_CAL360_ID,@IUNIDAD=@IUNIDAD,@HTML=@VCT_CAL360_HTML OUTPUT;
 IF ISNULL(@VCT_CAL360_HTML,'''')<>''''
 BEGIN
  DECLARE @VCT_CAL360_START INT=CHARINDEX(''data-vct-panel="agenda">'',@OUTPARAM1);
  DECLARE @VCT_CAL360_BODY INT=@VCT_CAL360_START+LEN(''data-vct-panel="agenda">'');
  DECLARE @VCT_CAL360_NEXT INT=CHARINDEX(''data-vct-panel="'',@OUTPARAM1,@VCT_CAL360_BODY);
  IF @VCT_CAL360_NEXT=0 SET @VCT_CAL360_NEXT=LEN(@OUTPARAM1)+1;
  DECLARE @VCT_CAL360_FRAGMENT VARCHAR(MAX)=SUBSTRING(@OUTPARAM1,@VCT_CAL360_BODY,@VCT_CAL360_NEXT-@VCT_CAL360_BODY);
  /* Solo se reemplazan los estados vacios exactos verificados de Agenda. */
  IF '+CASE WHEN @ENTITY='PROYECTO' THEN N'CHARINDEX(''La agenda del proyecto (visitas y horas) se habilita en el paso de agenda.'',@VCT_CAL360_FRAGMENT)>0'
                ELSE N'CHARINDEX(''Sin datos por el momento.'',@VCT_CAL360_FRAGMENT)>0' END+N'
  BEGIN
   DECLARE @VCT_CAL360_OLD VARCHAR(500)='+CASE WHEN @ENTITY='PROYECTO' THEN N'''<div class="vct-360-empty">La agenda del proyecto (visitas y horas) se habilita en el paso de agenda.</div>'''
                     ELSE N'''<div class="vct-360-empty vct-360-fixed-empty">Sin datos por el momento.</div>''' END+N';
   DECLARE @VCT_CAL360_EMPTY INT=CHARINDEX(@VCT_CAL360_OLD,@OUTPARAM1,@VCT_CAL360_BODY);
   IF @VCT_CAL360_EMPTY>0 AND @VCT_CAL360_EMPTY<@VCT_CAL360_NEXT
      SET @OUTPARAM1=STUFF(@OUTPARAM1,@VCT_CAL360_EMPTY,LEN(@VCT_CAL360_OLD),@VCT_CAL360_HTML);
  END;
 END;
END;
/* END_VCT_CALENDAR_360_20261016_V2 */
';
   /* CREATE / CREATE OR ALTER / ALTER sin reescribir el cuerpo vigente. */
   SET @POS=1;
   /* Saltar solo comentarios y espacios previos a la cabecera real. */
   WHILE @POS<=LEN(@D)
   BEGIN
    IF SUBSTRING(@D,@POS,1) IN (N' ',NCHAR(9),NCHAR(10),NCHAR(13)) SET @POS=@POS+1;
    ELSE IF SUBSTRING(@D,@POS,2)=N'--'
      SET @POS=CASE WHEN CHARINDEX(NCHAR(10),@D,@POS)>0 THEN CHARINDEX(NCHAR(10),@D,@POS)+1 ELSE LEN(@D)+1 END;
    ELSE IF SUBSTRING(@D,@POS,2)=N'/*'
    BEGIN
     IF CHARINDEX(N'*/',@D,@POS+2)=0 RAISERROR('Cabecera SQL inesperada.',16,1);
     SET @POS=CHARINDEX(N'*/',@D,@POS+2)+2;
    END
    ELSE BREAK;
   END;
   IF SUBSTRING(UPPER(@D),@POS,6)=N'CREATE'
   BEGIN
    DECLARE @VCT_HEADER_END INT=CHARINDEX(N'PROCEDURE',UPPER(@D),@POS);
    IF @VCT_HEADER_END=0 OR @VCT_HEADER_END-@POS>100 RAISERROR('Cabecera CREATE PROCEDURE inesperada.',16,1);
    SET @D=STUFF(@D,@POS,@VCT_HEADER_END-@POS,N'ALTER ');
   END
   ELSE IF SUBSTRING(UPPER(@D),@POS,5)<>N'ALTER' RAISERROR('Definicion de SP inesperada.',16,1);
   SET @D=@D+@TAIL;
   EXEC sys.sp_executesql @D;
   SET @DONE=@DONE+1;
  END;
  FETCH NEXT FROM C INTO @PROC,@ENTITY,@KEY;
 END;
 CLOSE C; DEALLOCATE C;
 COMMIT;
 PRINT 'FASE 2 instalada. SP integrados: '+CONVERT(VARCHAR(10),@DONE)+'. Recargar la aplicacion completa.';
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 DECLARE @ERR NVARCHAR(2048)=ERROR_MESSAGE(); RAISERROR('%s',16,1,@ERR);
END CATCH;
