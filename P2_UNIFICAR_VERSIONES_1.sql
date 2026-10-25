/* ========================================================================
   P2_UNIFICAR_VERSIONES_1  —  auditoria Fase 9 / P2
   ------------------------------------------------------------------------
   Unifica el ?v de los assets compartidos que hoy tienen versiones
   distintas entre SPs (cache-miss + motor no-determinista segun el orden
   de navegacion). Deja cada uno en UNA sola version (50) en todos los SPs
   vivos. 50 esta por encima de todos los maximos actuales -> un refresh
   limpio y de ahi en mas una sola version.

   Alcance (del DIAG_ASSETS_VERSIONES, base viva):
     vct-datagrid.css  (hoy 19/20/28/30, 14 SPs)
     vct-datagrid.js   (hoy 7/11/12, 13 SPs)
     vct-datepicker.css(hoy 1/12, 4 SPs)
     vct-datepicker.js (hoy 2/12, 4 SPs)
   EXCLUYE los SP backup (*_BKP). NO toca vct-export.js (el ?v= malformado
   de PROYECTO_V360 se arregla aparte), ni v360/calendario/etc. (ya unificados).

   Mecanismo: reusa el patron de FIX_CALENDARIO_BUMP_V46 (cursor sobre
   sys.sql_modules, STUFF de los digitos tras ?v=, CREATE->ALTER robusto).
   Re-ejecutable: si ya estan en 50, no cambia nada. Compat 100 y 140.

   NOTA: ?v es solo cache-buster (query string); el server sirve el mismo
   archivo fisico. Este bump NO requiere subir assets, solo correr el script.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX), @ORIG NVARCHAR(MAX), @OID INT, @POS INT,
 @START INT, @FIN INT, @SCAN INT, @N INT=0, @ASSET INT, @TOKEN NVARCHAR(80),
 @HDR_P INT,@HDR_Q INT,@HDR_DEPTH INT,@HDR_PREFIX NVARCHAR(100);
DECLARE bumpP2 CURSOR LOCAL FAST_FORWARD FOR
 SELECT m.object_id FROM sys.sql_modules m
 JOIN sys.objects o ON o.object_id=m.object_id
 WHERE o.type='P'
   AND o.name NOT LIKE N'%[_]BKP'
   AND (m.definition LIKE N'%vct-datagrid.css?v=%'
     OR m.definition LIKE N'%vct-datagrid.js?v=%'
     OR m.definition LIKE N'%vct-datepicker.css?v=%'
     OR m.definition LIKE N'%vct-datepicker.js?v=%');
BEGIN TRY
 BEGIN TRANSACTION;
 OPEN bumpP2;
 FETCH NEXT FROM bumpP2 INTO @OID;
 WHILE @@FETCH_STATUS=0
 BEGIN
 SET @D=OBJECT_DEFINITION(@OID); SET @ORIG=@D; SET @ASSET=1;
 WHILE @ASSET<=4
 BEGIN
 SET @TOKEN=CASE @ASSET
    WHEN 1 THEN N'vct-datagrid.css?v='
    WHEN 2 THEN N'vct-datagrid.js?v='
    WHEN 3 THEN N'vct-datepicker.css?v='
    ELSE N'vct-datepicker.js?v=' END;
 SET @SCAN=1;
 WHILE 1=1
 BEGIN
   SET @POS=CHARINDEX(@TOKEN,@D,@SCAN);
   IF @POS=0 BREAK;
   SET @START=@POS+LEN(@TOKEN); SET @FIN=@START;
   WHILE SUBSTRING(@D,@FIN,1) COLLATE Latin1_General_BIN2 LIKE '[0-9]'
     SET @FIN=@FIN+1;
   IF @FIN=@START THROW 51055,'Version no numerica en un asset compartido. Sin cambios.',1;
   SET @D=STUFF(@D,@START,@FIN-@START,N'50'); SET @SCAN=@START+2;
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
     IF @HDR_Q=0 THROW 51055,'No hay cabecera despues del comentario. Sin cambios.',1;
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
     IF @HDR_DEPTH<>0 THROW 51055,'Comentario inicial sin cierre. Sin cambios.',1;
   END
   ELSE BREAK;
 END;
 SET @D=SUBSTRING(@D,@HDR_P,LEN(@D));
 SET @HDR_Q=CHARINDEX('PROCEDURE',UPPER(@D));
 IF @HDR_Q=0 SET @HDR_Q=CHARINDEX('PROC',UPPER(@D));
 IF @HDR_Q=0 OR @HDR_Q>100 THROW 51055,'No se reconoce PROCEDURE en la cabecera. Sin cambios.',1;
 SET @HDR_PREFIX=UPPER(LEFT(@D,@HDR_Q-1));
 SET @HDR_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(@HDR_PREFIX,' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
 IF @HDR_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER')
   THROW 51055,'Prefijo de procedimiento no reconocido. Sin cambios.',1;
 SET @D=N'ALTER '+SUBSTRING(@D,@HDR_Q,LEN(@D));

 EXEC sys.sp_executesql @D;
 SET @N=@N+1;
 PRINT OBJECT_SCHEMA_NAME(@OID)+'.'+OBJECT_NAME(@OID)+': datagrid/datepicker v50';
 END;
 FETCH NEXT FROM bumpP2 INTO @OID;
 END;
 CLOSE bumpP2; DEALLOCATE bumpP2;
 COMMIT TRANSACTION;
 PRINT 'OK. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@N);
END TRY
BEGIN CATCH
 IF CURSOR_STATUS('local','bumpP2')>=0 CLOSE bumpP2;
 IF CURSOR_STATUS('local','bumpP2')>-3 DEALLOCATE bumpP2;
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
