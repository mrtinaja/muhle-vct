/* CAL_E_V1 v45: invalida la cache de calendario CSS/JS (y Acciones JS). Boceto B final: sin foto de fondo,
   degrade pastel, celdas blancas, circulo bordo, fin de semana / pasados / feriados, semana en 7 columnas, dia sin horas.
   Lee las definiciones actuales; conserva consultas y guardados. Reejecutable.
   Subir css/vct-calendario.css antes de ejecutar (los JS no cambian). */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX), @ORIG NVARCHAR(MAX), @OID INT, @POS INT,
 @START INT, @FIN INT, @SCAN INT, @N INT=0, @ASSET INT, @TOKEN NVARCHAR(80),
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100);
DECLARE bump45 CURSOR LOCAL FAST_FORWARD FOR
 SELECT m.object_id FROM sys.sql_modules m
 JOIN sys.objects o ON o.object_id=m.object_id
 WHERE o.type='P' AND (m.definition LIKE N'%vct-calendario.js?v=%'
 OR m.definition LIKE N'%vct-calendario.css?v=%'
 OR m.definition LIKE N'%vct-acciones.js?v=%');
BEGIN TRY
 BEGIN TRANSACTION;
 OPEN bump45;
 FETCH NEXT FROM bump45 INTO @OID;
 WHILE @@FETCH_STATUS=0
 BEGIN
 SET @D=OBJECT_DEFINITION(@OID); SET @ORIG=@D; SET @ASSET=1;
 WHILE @ASSET<=3
 BEGIN
 SET @TOKEN=CASE @ASSET WHEN 1 THEN N'vct-calendario.js?v=' WHEN 2 THEN N'vct-calendario.css?v=' ELSE N'vct-acciones.js?v=' END;
 SET @SCAN=1;
 WHILE 1=1
 BEGIN
   SET @POS=CHARINDEX(@TOKEN,@D,@SCAN);
   IF @POS=0 BREAK;
   SET @START=@POS+LEN(@TOKEN); SET @FIN=@START;
   WHILE SUBSTRING(@D,@FIN,1) COLLATE Latin1_General_BIN2 LIKE '[0-9]'
     SET @FIN=@FIN+1;
   IF @FIN=@START THROW 51042,'Version JS no numerica. Sin cambios.',1;
   SET @D=STUFF(@D,@START,@FIN-@START,N'45'); SET @SCAN=@START+2;
 END;
 SET @ASSET=@ASSET+1;
 END;
 IF @D<>@ORIG
 BEGIN
 /* Reconocer cabecera ignorando BOM, espacios y comentarios iniciales. */
 SET @HDR13_P=1;
 WHILE @HDR13_P<=LEN(@D)
 BEGIN
   IF UNICODE(SUBSTRING(@D,@HDR13_P,1)) IN(9,10,13,32,65279)
     SET @HDR13_P=@HDR13_P+1;
   ELSE IF SUBSTRING(@D,@HDR13_P,2)='--'
   BEGIN
     SET @HDR13_Q=CHARINDEX(CHAR(10),@D,@HDR13_P+2);
     IF @HDR13_Q=0 THROW 51042,'No hay cabecera despues del comentario. Sin cambios.',1;
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
     IF @HDR13_DEPTH<>0 THROW 51042,'Comentario inicial sin cierre. Sin cambios.',1;
   END
   ELSE BREAK;
 END;
 SET @D=SUBSTRING(@D,@HDR13_P,LEN(@D));
 SET @HDR13_Q=CHARINDEX('PROCEDURE',UPPER(@D));
 IF @HDR13_Q=0 SET @HDR13_Q=CHARINDEX('PROC',UPPER(@D));
 IF @HDR13_Q=0 OR @HDR13_Q>100 THROW 51042,'No se reconoce PROCEDURE en la cabecera. Sin cambios.',1;
 SET @HDR13_PREFIX=UPPER(LEFT(@D,@HDR13_Q-1));
 SET @HDR13_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(@HDR13_PREFIX,' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
 IF @HDR13_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER')
   THROW 51042,'Prefijo de procedimiento no reconocido. Sin cambios.',1;
 SET @D=N'ALTER '+SUBSTRING(@D,@HDR13_Q,LEN(@D));

 EXEC sys.sp_executesql @D;
 SET @N=@N+1;
 PRINT OBJECT_SCHEMA_NAME(@OID)+'.'+OBJECT_NAME(@OID)+': assets v45';
 END;
 FETCH NEXT FROM bump45 INTO @OID;
 END;
 CLOSE bump45; DEALLOCATE bump45;
 COMMIT TRANSACTION;
 PRINT 'OK. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@N);
END TRY
BEGIN CATCH
 IF CURSOR_STATUS('local','bump45')>=0 CLOSE bump45;
 IF CURSOR_STATUS('local','bump45')>-3 DEALLOCATE bump45;
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
