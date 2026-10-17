/* Assets finales de calendarios, picker y Acciones. Solo referencias CSS/JS.
 Ejecutar despues de subir archivos. No ejecuta comandos funcionales de los SP.
*/
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX),@ORIGINAL NVARCHAR(MAX),@OID INT,@TOKEN NVARCHAR(80),
 @AT INT,@FIN INT,@POS INT,@N INT=0,
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100);
DECLARE @TOKENS TABLE(T NVARCHAR(80));
INSERT INTO @TOKENS VALUES(N'vct-calendario.js?v='),(N'vct-calendario.css?v='),
 (N'vct-datepicker.js?v='),(N'vct-datepicker.css?v='),(N'vct-acciones.js?v='),(N'vct-acciones.css?v=');
DECLARE mods CURSOR LOCAL FAST_FORWARD FOR
 SELECT M.object_id FROM sys.sql_modules M JOIN sys.objects O ON O.object_id=M.object_id
 WHERE O.type='P' AND EXISTS(SELECT 1 FROM @TOKENS T WHERE CHARINDEX(T.T,M.definition)>0);
BEGIN TRY
 BEGIN TRANSACTION;
 OPEN mods; FETCH NEXT FROM mods INTO @OID;
 WHILE @@FETCH_STATUS=0
 BEGIN
   SET @D=REPLACE(OBJECT_DEFINITION(@OID),CHAR(13),''); SET @ORIGINAL=@D;
   DECLARE assets CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM @TOKENS;
   OPEN assets; FETCH NEXT FROM assets INTO @TOKEN;
   WHILE @@FETCH_STATUS=0
   BEGIN
     SET @POS=1;
     WHILE 1=1
     BEGIN
       SET @AT=CHARINDEX(@TOKEN,@D,@POS); IF @AT=0 BREAK;
       SET @AT=@AT+LEN(@TOKEN); SET @FIN=CHARINDEX('"',@D,@AT);
       IF @FIN=0 OR @FIN-@AT>10 THROW 51021,'Referencia de asset no reconocida. Se revierte el bump.',1;
       SET @D=STUFF(@D,@AT,@FIN-@AT,N'21'); SET @POS=@AT+2;
     END;
     FETCH NEXT FROM assets INTO @TOKEN;
   END;
   CLOSE assets; DEALLOCATE assets;
   IF @D<>@ORIGINAL
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
     SET @N=@N+1;
   END;
   FETCH NEXT FROM mods INTO @OID;
 END;
 CLOSE mods; DEALLOCATE mods;
 COMMIT TRANSACTION;
 SELECT @N AS ProcedimientosActualizados;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
