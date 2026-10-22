/* CALENDARIOS_TOOLTIP_V42C = V42B de Martin SIN la V360 de proyecto.
   El calendario de la V360 de proyecto no esta definido ni se muestra, asi que su parte del
   V42B no aplica (y hacia fallar el script entero). Aplica TT42 solo en
   VCT_MAIN_CONSULTORES_V360 y VCT_MAIN_AGENDA_CONSULTOR. Re-ejecutable (marca TT42_CONTEXT).
   Correr SOLO si la consulta de control da TT42 = 0 en esos SP. */
/* TT42B: incorpora contexto a los tooltips sin reemplazar calculos de horas,
   repartos confirmado/pendiente/disponible, permisos ni operaciones de guardado.
   Instalar primero los SQL 01, 01B y 02. SQL Server 2017, compatibilidad >=130. */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<130
 THROW 51042,'Se requiere compatibilidad >=130 para las funciones JSON.',1;
IF OBJECT_ID('dbo.VCT_FN_CAL_TOOLTIP_JSON') IS NULL
 THROW 51042,'Falta instalar 02_CONTEXTO_CALENDARIO.sql.',1;
DECLARE @D NVARCHAR(MAX),@NAME SYSNAME,@I INT=1,@ANCHOR NVARCHAR(300),@INSERT NVARCHAR(MAX),@POS INT,
 @ATTR INT,@VARPOS INT,@VAREND INT,@VAR NVARCHAR(128),@PREFIX NVARCHAR(500),@ERR NVARCHAR(2048),
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100);
BEGIN TRY
 BEGIN TRANSACTION;
 WHILE @I<=2   /* V42C: sin VCT_MAIN_PROYECTO_V360 (su calendario no se usa) */
 BEGIN
 SET @NAME=CASE @I WHEN 1 THEN 'dbo.VCT_MAIN_CONSULTORES_V360' WHEN 2 THEN 'dbo.VCT_MAIN_AGENDA_CONSULTOR' ELSE 'dbo.VCT_MAIN_PROYECTO_V360' END;
 SET @D=OBJECT_DEFINITION(OBJECT_ID(@NAME));
 IF @D IS NULL THROW 51042,'No se puede leer uno de los SP requeridos. Sin cambios en SP.',1;
 IF CHARINDEX('/* TT42_CONTEXT */',@D)=0
 BEGIN
 IF @I=1
 BEGIN
 SET @ANCHOR=N'/* V360_AGENDA_FIN_DATOS */';
 SET @INSERT=N'/* TT42_CONTEXT */
 SET @V360_AGC_DIAS=REPLACE(REPLACE(REPLACE(dbo.VCT_FN_CAL_TOOLTIP_JSON(@V360_AGC_DIAS,@ID_CONSULTOR,NULL),''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;'');
 ';
 END
 ELSE IF @I=2
 BEGIN
 SET @ANCHOR=N'SET @DIAS_JSON = REPLACE';
 SET @INSERT=N'/* TT42_CONTEXT */
 SET @DIAS_JSON=dbo.VCT_FN_CAL_TOOLTIP_JSON(@DIAS_JSON,@CONS_ID,NULL);
 ';
 END
 ELSE
 BEGIN
 /* Proyecto: enriquecer la variable consumida por el atributo HTML.
    No depende de que exista un SET separado para escapar @AG_EV. */
 SET @ATTR=CHARINDEX(N'data-vct-calendar-events=',@D);
 IF @ATTR=0 OR CHARINDEX(N'data-vct-calendar-events=',@D,@ATTR+1)>0
 BEGIN
   SET @ERR=@NAME+N': atributo data-vct-calendar-events ausente o repetido. Sin cambios en SP.';
   THROW 51042,@ERR,1;
 END;
 SET @VARPOS=CHARINDEX(N'@',@D,@ATTR+LEN(N'data-vct-calendar-events='));
 IF @VARPOS=0 OR @VARPOS-@ATTR>400
 BEGIN
   SET @ERR=@NAME+N': no se reconoce la variable JSON del atributo. Sin cambios en SP.';
   THROW 51042,@ERR,1;
 END;
 SET @VAREND=@VARPOS+1;
 WHILE SUBSTRING(@D,@VAREND,1) COLLATE Latin1_General_BIN2 LIKE '[A-Za-z0-9_]'
   SET @VAREND=@VAREND+1;
 SET @VAR=SUBSTRING(@D,@VARPOS,@VAREND-@VARPOS);
 IF @VAR<>N'@AG_EV'
 BEGIN
   SET @ERR=@NAME+N': variable JSON no reconocida ('+@VAR+N'). Sin cambios en SP.';
   THROW 51042,@ERR,1;
 END;
 SET @PREFIX=UPPER(SUBSTRING(@D,@ATTR,@VARPOS-@ATTR));
 SET @INSERT=N'/* TT42_CONTEXT */ dbo.VCT_FN_CAL_TOOLTIP_JSON('+@VAR+N',NULL,@ID_PROYECTO)';
 /* Si la expresion original ya escapa HTML, se conserva ese escape.
    Si consume la variable directamente, el parche escapa el resultado crudo.
    La funcion de contexto acepta JSON crudo o previamente escapado. */
 IF CHARINDEX(N'REPLACE',@PREFIX)=0
   SET @INSERT=N'REPLACE(REPLACE(REPLACE('+@INSERT+N',''&'',''&amp;''),''"'',''&quot;''),''<'',''&lt;'')';
 SET @D=STUFF(@D,@VARPOS,@VAREND-@VARPOS,@INSERT);
 END;
 IF @I IN(1,2)
 BEGIN
 SET @POS=CHARINDEX(@ANCHOR,@D);
 IF @POS=0 OR CHARINDEX(@ANCHOR,@D,@POS+LEN(@ANCHOR))>0
 BEGIN
   SET @ERR=@NAME+N': ancla de contexto ausente o ambigua. Sin cambios en SP.';
   THROW 51042,@ERR,1;
 END;
 SET @D=STUFF(@D,@POS,0,@INSERT);
 END;
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
 PRINT @NAME+': preparado (pendiente de COMMIT)';
 END
 ELSE PRINT @NAME+': contexto TT42 ya aplicado';
 SET @I=@I+1;
 END;
 COMMIT TRANSACTION;
 PRINT 'OK: contexto TT42 confirmado en los tres SP.';
 SELECT OBJECT_SCHEMA_NAME(object_id)+'.'+OBJECT_NAME(object_id) AS Objeto,
 CASE WHEN CHARINDEX('/* TT42_CONTEXT */',definition)>0 THEN 'Aplicado' ELSE 'Revisar' END AS Contexto
 FROM sys.sql_modules WHERE object_id IN(OBJECT_ID('dbo.VCT_MAIN_CONSULTORES_V360'),OBJECT_ID('dbo.VCT_MAIN_AGENDA_CONSULTOR'),OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360'));
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
