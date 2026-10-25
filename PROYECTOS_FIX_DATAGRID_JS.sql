/* ========================================================================
   PROYECTOS_FIX_DATAGRID_JS  —  Proyectos no inicializa el datagrid.
   ------------------------------------------------------------------------
   CAUSA (diagnosticada con Playwright): VCT_MAIN_PROYECTOS carga vct-inicio.js
   pero NUNCA vct-datagrid.js -> el motor del datagrid no corre -> la tabla
   queda sin data-vct-dg-ready, sin buscador, sin paginado (862 filas crudas).
   Las otras listas (Clientes, etc.) SI emiten vct-datagrid.js, por eso andan.

   FIX: inserta <script vct-datagrid.js> + <script vct-export.js> justo ANTES
   del <script vct-inicio.js> en la definicion viva. Version-agnostico
   (ancla por el tag de inicio.js, sin depender del ?v). Re-ejecutable:
   si ya esta vct-datagrid.js, no hace nada. Compat 100 y 140.
   ======================================================================== */
USE [MuhlePROD];
GO
SET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
DECLARE @D NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID('dbo.VCT_MAIN_PROYECTOS'));
IF @D IS NULL THROW 51080,'No existe VCT_MAIN_PROYECTOS.',1;
IF CHARINDEX(N'vct-datagrid.js', @D) > 0
BEGIN PRINT 'Ya carga vct-datagrid.js. Sin cambios.'; RETURN; END;

/* ancla: el <script> de vct-inicio.js (sin fijar version) */
DECLARE @pos INT = CHARINDEX(N'<script src="../js/vct-inicio.js', @D);
IF @pos = 0 THROW 51080,'No se encontro el <script> de vct-inicio.js. Revisar manualmente.',1;

DECLARE @ins NVARCHAR(200) = N'<script src="../js/vct-datagrid.js?v=50"></script><script src="../js/vct-export.js?v=1"></script>';
SET @D = STUFF(@D, @pos, 0, @ins);

/* CREATE -> ALTER (ignora BOM/espacios/comentarios iniciales) */
DECLARE @HDR_P INT=1,@HDR_Q INT,@HDR_DEPTH INT,@HDR_PREFIX NVARCHAR(100);
WHILE @HDR_P<=LEN(@D)
BEGIN
  IF UNICODE(SUBSTRING(@D,@HDR_P,1)) IN(9,10,13,32,65279) SET @HDR_P=@HDR_P+1;
  ELSE IF SUBSTRING(@D,@HDR_P,2)='--'
  BEGIN
    SET @HDR_Q=CHARINDEX(CHAR(10),@D,@HDR_P+2);
    IF @HDR_Q=0 THROW 51080,'Comentario de linea sin cierre.',1;
    SET @HDR_P=@HDR_Q+1;
  END
  ELSE IF SUBSTRING(@D,@HDR_P,2)='/*'
  BEGIN
    SET @HDR_DEPTH=1; SET @HDR_P=@HDR_P+2;
    WHILE @HDR_DEPTH>0 AND @HDR_P<=LEN(@D)
    BEGIN
      IF SUBSTRING(@D,@HDR_P,2)='/*' BEGIN SET @HDR_DEPTH=@HDR_DEPTH+1; SET @HDR_P=@HDR_P+2; END
      ELSE IF SUBSTRING(@D,@HDR_P,2)='*/' BEGIN SET @HDR_DEPTH=@HDR_DEPTH-1; SET @HDR_P=@HDR_P+2; END
      ELSE SET @HDR_P=@HDR_P+1;
    END;
    IF @HDR_DEPTH<>0 THROW 51080,'Comentario /* */ inicial sin cierre.',1;
  END
  ELSE BREAK;
END;
SET @D=SUBSTRING(@D,@HDR_P,LEN(@D));
SET @HDR_Q=CHARINDEX('PROCEDURE',UPPER(@D));
IF @HDR_Q=0 OR @HDR_Q>100 THROW 51080,'No se reconoce PROCEDURE.',1;
SET @HDR_PREFIX=REPLACE(REPLACE(REPLACE(REPLACE(UPPER(LEFT(@D,@HDR_Q-1)),' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'');
IF @HDR_PREFIX NOT IN('CREATE','ALTER','CREATEORALTER') THROW 51080,'Prefijo no reconocido.',1;
SET @D=N'ALTER '+SUBSTRING(@D,@HDR_Q,LEN(@D));

EXEC sys.sp_executesql @D;
PRINT 'OK: VCT_MAIN_PROYECTOS ahora carga vct-datagrid.js + vct-export.js (datagrid inicializa).';
GO
