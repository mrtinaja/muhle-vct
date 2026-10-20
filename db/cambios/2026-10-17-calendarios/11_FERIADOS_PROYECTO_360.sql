/* FERIADOS EN VCT_MAIN_PROYECTO_V360. Requiere el parche v13 instalado.
 Solo agrega lectura de dbo.Calendar y actualiza version de assets de este SP.
 No modifica feriados ni datos de proyectos. Reejecutable y transaccional.
*/
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX),@A NVARCHAR(MAX),@B NVARCHAR(MAX),@AT INT,@END INT,
 @HDR13_P INT,@HDR13_Q INT,@HDR13_DEPTH INT,@HDR13_PREFIX NVARCHAR(100);
BEGIN TRY
 BEGIN TRANSACTION;
 IF COL_LENGTH('dbo.Calendar','Fecha') IS NULL OR COL_LENGTH('dbo.Calendar','IsHoliday') IS NULL
 OR COL_LENGTH('dbo.Calendar','Feriado') IS NULL OR COL_LENGTH('dbo.Calendar','HolidayText') IS NULL
   THROW 51017,'Faltan columnas de dbo.Calendar. Sin cambios.',1;
 SET @D=REPLACE(OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360')),CHAR(13),'');
 IF @D IS NULL THROW 51017,'El SP de Proyecto no es visible. Sin cambios.',1;
 IF CHARINDEX('CAL13_PROYECTO',@D)=0 THROW 51017,'Primero debe estar instalado v13 de Proyecto 360.',1;
 IF CHARINDEX('PV_FERIADOS_V17',@D)=0
 BEGIN
   SET @A=N'DECLARE @AG_PANEL VARCHAR(MAX)';
   SET @B=N'/* PV_FERIADOS_V17: misma fuente que el calendario general. */
    DECLARE @PV17_HOLIDAYS NVARCHAR(MAX);
    SELECT @PV17_HOLIDAYS=ISNULL((
      SELECT CONVERT(VARCHAR(10),Fecha,120) AS f, Feriado AS t,
        ISNULL(NULLIF(HolidayText,''''),''Feriado'') AS x
      FROM dbo.Calendar WHERE IsHoliday=1 ORDER BY Fecha FOR JSON PATH
    ),N''[]'');
    SET @PV17_HOLIDAYS=REPLACE(REPLACE(@PV17_HOLIDAYS,''&'',''&amp;''),''"'',''&quot;'');
    DECLARE @AG_PANEL VARCHAR(MAX)';
   SET @A=REPLACE(@A,CHAR(13),''); SET @B=REPLACE(@B,CHAR(13),'');
   IF CHARINDEX(@A,@D)=0 OR CHARINDEX(@A,@D,CHARINDEX(@A,@D)+LEN(@A))>0
     THROW 51017,'No se encontro un unico panel de Agenda. Sin cambios.',1;
   SET @D=REPLACE(@D,@A,@B);
   SET @A=N'data-vct-agenda-root data-vct-calendar-events="';
   SET @B=N'data-vct-agenda-root data-vct-feriados="'' + CONVERT(VARCHAR(MAX),@PV17_HOLIDAYS) + ''" data-vct-calendar-events="';
   IF CHARINDEX(@A,@D)=0 OR CHARINDEX(@A,@D,CHARINDEX(@A,@D)+LEN(@A))>0
     THROW 51017,'No se encontro un unico calendario de Proyecto. Sin cambios.',1;
   SET @D=REPLACE(@D,@A,@B);
 END;
 -- Version de JS/CSS solo de la ficha Proyecto. Los archivos se suben primero.
 SET @A=N'vct-calendario.js?v='; SET @AT=CHARINDEX(@A,@D);
 IF @AT=0 THROW 51017,'No se encontro la referencia JS. Sin cambios.',1;
 SET @AT=@AT+LEN(@A); SET @END=CHARINDEX('"',@D,@AT);
 IF @END=0 OR @END-@AT>10 THROW 51017,'Referencia JS no reconocida. Sin cambios.',1;
 SET @D=STUFF(@D,@AT,@END-@AT,N'17');
 SET @A=N'vct-calendario.css?v='; SET @AT=CHARINDEX(@A,@D);
 IF @AT=0 THROW 51017,'No se encontro la referencia CSS. Sin cambios.',1;
 SET @AT=@AT+LEN(@A); SET @END=CHARINDEX('"',@D,@AT);
 IF @END=0 OR @END-@AT>10 THROW 51017,'Referencia CSS no reconocida. Sin cambios.',1;
 SET @D=STUFF(@D,@AT,@END-@AT,N'17');
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
 PRINT 'V17 instalado en VCT_MAIN_PROYECTO_V360: feriados junto con actividades.';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
SELECT OBJECT_NAME(object_id) AS Objeto,
 CASE WHEN definition LIKE '%PV_FERIADOS_V17%' THEN 'Feriados v17' ELSE 'Revisar' END AS Estado
FROM sys.sql_modules WHERE object_id=OBJECT_ID('dbo.VCT_MAIN_PROYECTO_V360');
GO
