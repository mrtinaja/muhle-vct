/* ACCIONES: calendario compacto y feriados. No cambia los datos de negocio.
 Modifica solamente dbo.VCT_MAIN_ACCIONES sobre su definicion vigente.
 Los archivos JS/CSS de esta entrega se suben antes de ejecutar este script.
*/
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX),@TAIL INT,@INSERT NVARCHAR(MAX),
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100),
 @TOKEN NVARCHAR(80),@AT INT,@FIN INT,@POS INT;
BEGIN TRY
 BEGIN TRANSACTION;
 IF COL_LENGTH('dbo.Calendar','Fecha') IS NULL OR COL_LENGTH('dbo.Calendar','Feriado') IS NULL
 OR COL_LENGTH('dbo.Calendar','IsHoliday') IS NULL OR COL_LENGTH('dbo.Calendar','HolidayText') IS NULL
   THROW 51021,'Faltan columnas de dbo.Calendar. Sin cambios.',1;
 SET @D=REPLACE(OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_ACCIONES')),CHAR(13),'');
 IF @D IS NULL THROW 51021,'El SP de Acciones no es visible. Sin cambios.',1;
 IF CHARINDEX('@OUTPARAM1',@D)=0 THROW 51021,'Salida de Acciones no reconocida. Sin cambios.',1;
 IF CHARINDEX('ACC_FERIADOS_V21',@D)=0
 BEGIN
   SET @TAIL=LEN(@D);
   WHILE @TAIL>0 AND UNICODE(SUBSTRING(@D,@TAIL,1)) IN(9,10,13,32,59) SET @TAIL=@TAIL-1;
   IF UPPER(SUBSTRING(@D,@TAIL-2,3))<>'END'
     THROW 51021,'No se reconoce el END final de Acciones. Sin cambios.',1;
   SET @INSERT=N'
    /* ACC_FERIADOS_V21: solo lectura de la fuente oficial de feriados. */
    DECLARE @ACC21_HOLIDAYS NVARCHAR(MAX);
    SELECT @ACC21_HOLIDAYS=ISNULL((
      SELECT CONVERT(VARCHAR(10),Fecha,120) AS f,Feriado AS t,
             ISNULL(NULLIF(HolidayText,''''),''Feriado'') AS x
      FROM dbo.Calendar WHERE IsHoliday=1 ORDER BY Fecha FOR JSON PATH
    ),N''[]'');
    SET @ACC21_HOLIDAYS=REPLACE(REPLACE(@ACC21_HOLIDAYS,''&'',''&amp;''),''"'',''&quot;'');
    SET @OUTPARAM1=''<span hidden data-vct-acc-holidays="''+CONVERT(VARCHAR(MAX),@ACC21_HOLIDAYS)+''"></span>''
      +''<link rel="stylesheet" href="../css/vct-acciones.css?v=21">''
      +''<link rel="stylesheet" href="../css/vct-calendario.css?v=21">''
      +''<script src="../js/vct-calendario.js?v=21"></script>''
      +''<script src="../js/vct-acciones.js?v=21"></script>''
      +ISNULL(@OUTPARAM1,'''');
';
   SET @D=STUFF(@D,@TAIL-2,0,@INSERT+CHAR(10));
 END;
 -- Evitar referencias antiguas a los mismos assets en el HTML vigente.
 DECLARE @TOKENS TABLE(T NVARCHAR(80));
 INSERT INTO @TOKENS VALUES(N'vct-calendario.js?v='),(N'vct-calendario.css?v='),(N'vct-acciones.js?v='),(N'vct-acciones.css?v=');
 DECLARE tokens CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM @TOKENS;
 OPEN tokens; FETCH NEXT FROM tokens INTO @TOKEN;
 WHILE @@FETCH_STATUS=0
 BEGIN
   SET @POS=1;
   WHILE 1=1
   BEGIN
     SET @AT=CHARINDEX(@TOKEN,@D,@POS); IF @AT=0 BREAK;
     SET @AT=@AT+LEN(@TOKEN); SET @FIN=CHARINDEX('"',@D,@AT);
     IF @FIN=0 OR @FIN-@AT>10 THROW 51021,'Referencia de asset no reconocida. Sin cambios.',1;
     SET @D=STUFF(@D,@AT,@FIN-@AT,N'21'); SET @POS=@AT+2;
   END;
   FETCH NEXT FROM tokens INTO @TOKEN;
 END;
 CLOSE tokens; DEALLOCATE tokens;
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
 COMMIT TRANSACTION;
 PRINT 'Acciones v21 instalado: lectura de feriados y assets actualizados.';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
SELECT OBJECT_NAME(object_id) AS Objeto,
 CASE WHEN definition LIKE '%ACC_FERIADOS_V21%' THEN 'Feriados v21' ELSE 'Revisar' END AS Estado
FROM sys.sql_modules WHERE object_id=OBJECT_ID('dbo.VCT_MAIN_ACCIONES');
GO
