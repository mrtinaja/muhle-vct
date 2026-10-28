/* ========================================================================
   DATAGRID_BUMP_V51  —  cache-bust de vct-datagrid.css + vct-datagrid.js
   ------------------------------------------------------------------------
   Cambiaron los DOS archivos y hay que subir el ?v para que el browser baje
   las versiones nuevas:
     - vct-datagrid.js : fixes de timing (init + VCTColStd en microtask).
     - vct-datagrid.css: ANTI-FLASH -> oculta la grilla cruda y muestra un
       spinner hasta que el motor la arma (data-vct-dg-ready="1"). Asi no se
       ve la tabla basica ni el reshape posterior.

   Deja ambos en v51 en todos los SP vivos (no *_BKP). Idempotente.

   IMPORTANTE: ANTES de correr esto, SUBIR al server:
     - css/vct-datagrid.css
     - js/vct-datagrid.js
     - main/Default.aspx  (el head ya quedo en vct-datagrid.css?v=51)
   El head (Default.aspx) y los SP deben coincidir en v51 para no cargar dos
   URLs distintas de la misma hoja.

   Mecanismo: patron de P2_UNIFICAR_VERSIONES_1 (cursor + STUFF + CREATE->ALTER
   robusto). Compat 100 y 140.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX), @ORIG NVARCHAR(MAX), @OID INT, @POS INT,
 @START INT, @FIN INT, @SCAN INT, @N INT=0, @ASSET INT, @TOKEN NVARCHAR(80),
 @HDR_P INT,@HDR_Q INT,@HDR_DEPTH INT,@HDR_PREFIX NVARCHAR(100);
DECLARE bumpDG CURSOR LOCAL FAST_FORWARD FOR
 SELECT m.object_id FROM sys.sql_modules m
 JOIN sys.objects o ON o.object_id=m.object_id
 WHERE o.type='P'
   AND o.name NOT LIKE N'%[_]BKP'
   AND (m.definition LIKE N'%vct-datagrid.css?v=%'
     OR m.definition LIKE N'%vct-datagrid.js?v=%');
BEGIN TRY
 BEGIN TRANSACTION;
 OPEN bumpDG;
 FETCH NEXT FROM bumpDG INTO @OID;
 WHILE @@FETCH_STATUS=0
 BEGIN
 SET @D=OBJECT_DEFINITION(@OID); SET @ORIG=@D; SET @ASSET=1;
 WHILE @ASSET<=2
 BEGIN
 SET @TOKEN=CASE @ASSET WHEN 1 THEN N'vct-datagrid.css?v=' ELSE N'vct-datagrid.js?v=' END;
 SET @SCAN=1;
 WHILE 1=1
 BEGIN
   SET @POS=CHARINDEX(@TOKEN,@D,@SCAN);
   IF @POS=0 BREAK;
   SET @START=@POS+LEN(@TOKEN); SET @FIN=@START;
   WHILE SUBSTRING(@D,@FIN,1) COLLATE Latin1_General_BIN2 LIKE '[0-9]'
     SET @FIN=@FIN+1;
   IF @FIN=@START THROW 51057,'Version no numerica en un asset datagrid. Sin cambios.',1;
   SET @D=STUFF(@D,@START,@FIN-@START,N'51'); SET @SCAN=@START+2;
 END;
 SET @ASSET=@ASSET+1;
 END;
 IF @D<>@ORIG
 BEGIN
 /* Reconocer cabecera ignorando BOM, espacios y comentarios iniciales. */
 SET @HDR_P=1;
 WHILE @HDR_P<=LEN(@D)
 BEGIN
   IF UNICODE(SUBSTRING(@D,@HDR_P,1)) IN(9,10,13,32,65279)
     SET @HDR_P=@HDR_P+1;
   ELSE IF SUBSTRING(@D,@HDR_P,2)='--'
   BEGIN
     SET @HDR_Q=CHARINDEX(CHAR(10),@D,@HDR_P+2);
     IF @HDR_Q=0 THROW 51057,'No hay cabecera despues del comentario. Sin cambios.',1;
     SET @HDR_P=@HDR_Q+1;
   END
   ELSE IF SUBSTRING(@D,@HDR_P,2)='/*'
   BEGIN
     SET @HDR_DEPTH=1; SET @HDR_P=@HDR_P+2;
     WHILE @HDR_DEPTH>0 AND @HDR_P<=LEN(@D)
     BEGIN
       IF SUBSTRING(@D,@HDR_P,2)='/*'
       BEGIN SET @HDR_DEPTH=@HDR_DEPTH+1; SET @HDR_P=@HDR_P+2; END
       ELSE IF SUBSTRING(@D,@HDR_P,2)='*/'
       BEGIN SET @HDR_DEPTH=@HDR_DEPTH-1; SET @HDR_P=@HDR_P+2; END
       ELSE SET @HDR_P=@HDR_P+1;
     END;
     IF @HDR_DEPTH<>0 THROW 51057,'Comentario inicial sin cierre. Sin cambios.',1;
   END
   ELSE BREAK;
 END;
 SET @D=SUBSTRING(@D,@HDR_P,LEN(@D));
 SET @HDR_Q=CHARINDEX('PROCEDURE',UPPER(@D));
 IF @HDR_Q=0 SET @HDR_Q=CHARINDEX('PROC',UPPER(@D));
 IF @HDR_Q=0 OR @HDR_Q>100 THROW 51057,'No se reconoce PROCEDURE en la cabecera. Sin cambios.',1;
 SET @HDR_PREFIX=UPPER(LEFT(@D,@HDR_Q-1));
 SET @HDR_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(@HDR_PREFIX,' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
 IF @HDR_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER')
   THROW 51057,'Prefijo de procedimiento no reconocido. Sin cambios.',1;
 SET @D=N'ALTER '+SUBSTRING(@D,@HDR_Q,LEN(@D));

 EXEC sys.sp_executesql @D;
 SET @N=@N+1;
 PRINT OBJECT_SCHEMA_NAME(@OID)+'.'+OBJECT_NAME(@OID)+': vct-datagrid css/js v51';
 END;
 FETCH NEXT FROM bumpDG INTO @OID;
 END;
 CLOSE bumpDG; DEALLOCATE bumpDG;
 COMMIT TRANSACTION;
 PRINT 'OK. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@N);
END TRY
BEGIN CATCH
 IF CURSOR_STATUS('local','bumpDG')>=0 CLOSE bumpDG;
 IF CURSOR_STATUS('local','bumpDG')>-3 DEALLOCATE bumpDG;
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
