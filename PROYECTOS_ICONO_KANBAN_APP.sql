/* ============================================================================
   PROYECTOS_ICONO_KANBAN_APP  v2
   Cambia el icono de Proyectos de 'folder' a 'folder-kanban' en TODA la app,
   SOLO donde representa Proyectos (cajas 360, charts, solapas, KPI). No toca
   los 'folder' genericos. Recorre los SP vivos (no *_BKP). Re-ejecutable.
   REQUIERE: subir js/vct-main.js (ya tiene 'folder-kanban' en el catalogo). Compat 100 y 140.
   ============================================================================ */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

DECLARE @U NCHAR(1);
DECLARE @OID INT;
DECLARE @D NVARCHAR(MAX);
DECLARE @ORIG NVARCHAR(MAX);
DECLARE @BODY NVARCHAR(MAX);
DECLARE @s NVARCHAR(400);
DECLARE @r NVARCHAR(400);
DECLARE @HDR_P INT;
DECLARE @HDR_Q INT;
DECLARE @HDR_DEPTH INT;
DECLARE @HDR_PREFIX NVARCHAR(100);
DECLARE @N INT;
SET @U = NCHAR(0x00DA);   /* 'U' con tilde, para "Ultimos" sin depender del encoding */
SET @N = 0;

DECLARE @MAP TABLE (ord INT IDENTITY(1,1), s NVARCHAR(400), r NVARCHAR(400));
INSERT INTO @MAP (s, r) VALUES
 (N'data-vct-icon="folder"></span>Proyectos',                  N'data-vct-icon="folder-kanban"></span>Proyectos'),
 (N'data-vct-icon="folder"></span></span>Proyectos',           N'data-vct-icon="folder-kanban"></span></span>Proyectos'),
 (N'data-vct-icon="folder"></span>'+@U+N'ltimos Proyectos',    N'data-vct-icon="folder-kanban"></span>'+@U+N'ltimos Proyectos'),
 (N'data-vct-icon="folder"></span><span>Proyectos',            N'data-vct-icon="folder-kanban"></span><span>Proyectos'),
 (N'data-vct-icon="folder"></span><span>Mis proyectos',        N'data-vct-icon="folder-kanban"></span><span>Mis proyectos'),
 (N'data-vct-tab="proyectos"><span data-vct-icon="folder">',   N'data-vct-tab="proyectos"><span data-vct-icon="folder-kanban">'),
 (N'en total</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder"', N'en total</small></span><span class="vct-360-stat-icon"><span data-vct-icon="folder-kanban"'),
 (N'<span class="vct-soft-kpi-icon" data-vct-icon="folder"', N'<span class="vct-soft-kpi-icon" data-vct-icon="folder-kanban"');

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
 SELECT m.object_id FROM sys.sql_modules m
 JOIN sys.objects o ON o.object_id=m.object_id
 WHERE o.type='P' AND o.name NOT LIKE N'%[_]BKP'
   AND m.definition LIKE N'%data-vct-icon="folder"%';

BEGIN TRY
 BEGIN TRANSACTION;
 OPEN cur; FETCH NEXT FROM cur INTO @OID;
 WHILE @@FETCH_STATUS=0
 BEGIN
   SET @D=OBJECT_DEFINITION(@OID); SET @ORIG=@D;
   DECLARE c2 CURSOR LOCAL FAST_FORWARD FOR SELECT s,r FROM @MAP ORDER BY ord;
   OPEN c2; FETCH NEXT FROM c2 INTO @s,@r;
   WHILE @@FETCH_STATUS=0 BEGIN SET @D=REPLACE(@D,@s,@r); FETCH NEXT FROM c2 INTO @s,@r; END;
   CLOSE c2; DEALLOCATE c2;

   IF @D <> @ORIG
   BEGIN
     SET @HDR_P=1;
     WHILE @HDR_P<=LEN(@D)
     BEGIN
       IF UNICODE(SUBSTRING(@D,@HDR_P,1)) IN(9,10,13,32,65279) SET @HDR_P=@HDR_P+1;
       ELSE IF SUBSTRING(@D,@HDR_P,2)='--'
       BEGIN SET @HDR_Q=CHARINDEX(CHAR(10),@D,@HDR_P+2); IF @HDR_Q=0 THROW 51090,'Comentario sin cierre.',1; SET @HDR_P=@HDR_Q+1; END
       ELSE IF SUBSTRING(@D,@HDR_P,2)='/*'
       BEGIN
         SET @HDR_DEPTH=1; SET @HDR_P=@HDR_P+2;
         WHILE @HDR_DEPTH>0 AND @HDR_P<=LEN(@D)
         BEGIN
           IF SUBSTRING(@D,@HDR_P,2)='/*' BEGIN SET @HDR_DEPTH=@HDR_DEPTH+1; SET @HDR_P=@HDR_P+2; END
           ELSE IF SUBSTRING(@D,@HDR_P,2)='*/' BEGIN SET @HDR_DEPTH=@HDR_DEPTH-1; SET @HDR_P=@HDR_P+2; END
           ELSE SET @HDR_P=@HDR_P+1;
         END;
         IF @HDR_DEPTH<>0 THROW 51090,'Comentario /* */ sin cierre.',1;
       END
       ELSE BREAK;
     END;
     SET @BODY=SUBSTRING(@D,@HDR_P,LEN(@D));
     SET @HDR_Q=CHARINDEX('PROCEDURE',UPPER(@BODY)); IF @HDR_Q=0 SET @HDR_Q=CHARINDEX('PROC',UPPER(@BODY));
     IF @HDR_Q=0 OR @HDR_Q>100 THROW 51090,'No se reconoce PROCEDURE.',1;
     SET @HDR_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(UPPER(LEFT(@BODY,@HDR_Q-1)),' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
     IF @HDR_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER') THROW 51090,'Prefijo no reconocido.',1;
     SET @D=N'ALTER '+SUBSTRING(@BODY,@HDR_Q,LEN(@BODY));
     EXEC sys.sp_executesql @D;
     SET @N=@N+1;
     PRINT OBJECT_SCHEMA_NAME(@OID)+'.'+OBJECT_NAME(@OID)+': folder -> folder-kanban (Proyectos)';
   END;
   FETCH NEXT FROM cur INTO @OID;
 END;
 CLOSE cur; DEALLOCATE cur;
 COMMIT TRANSACTION;
 PRINT 'OK. Procedimientos actualizados: '+CONVERT(VARCHAR(10),@N);
END TRY
BEGIN CATCH
 IF CURSOR_STATUS('local','c2')>=0 BEGIN CLOSE c2; DEALLOCATE c2; END;
 IF CURSOR_STATUS('local','cur')>=0 BEGIN CLOSE cur; DEALLOCATE cur; END;
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
