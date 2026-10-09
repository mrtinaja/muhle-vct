 
CREATE   PROCEDURE dbo.VCT_MIGRAR_PROVEEDORES_DESDE_LK
 @Aplicar bit=0,@PermitirOrigenVacio bit=0,@Principal varchar(50)='1'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF;
 SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
 SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME()<>N'MuhlePROD' OR ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')),N'')<>N'WIN-83AM68966R4'
 THROW 54000,'Ejecutar solamente en MuhlePROD / WIN-83AM68966R4 (desarrollo).',1;
 
 IF @@TRANCOUNT<>0 THROW 54003,'Ejecutar sin transacciones anteriores.',1;
 IF @Principal IS NULL OR LTRIM(RTRIM(@Principal)) IN ('','0') THROW 54004,'Principal debe ser informado y distinto de 0.',1;
 DECLARE @run uniqueidentifier=NEWID(),@ahora datetime=GETDATE(),@lock int,@sql nvarchar(max),@tabla nvarchar(517),
  @nombre sysname,@parent int,@fk int,@identity sysname=NULL,@cond nvarchar(max),@hay bit,@trust bit,
  @ultimo int,@valor int,@n bigint,@esperado bigint,@columna sysname;
 BEGIN TRY
  IF @Aplicar=1
  BEGIN
   BEGIN TRANSACTION;
   EXEC @lock=sys.sp_getapplock @Resource=N'VCT_MIG_MODELO_NUEVO',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0;
   IF @lock<0 THROW 54005,'Hay otra migracion en curso.',1;
  END;
  CREATE TABLE #Excepciones(ID_PROVEEDOR int,Campo varchar(100) COLLATE DATABASE_DEFAULT,Detalle nvarchar(max) COLLATE DATABASE_DEFAULT);
  SELECT ID_PROVEEDOR ID,CAST('PROVEEDOR' AS varchar(30)) COLLATE DATABASE_DEFAULT Entidad,
   RAZON_SOCIAL_PROV COLLATE DATABASE_DEFAULT Razon,CUIT_PROV COLLATE DATABASE_DEFAULT CuitOriginal,
   REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CUIT_PROV)),'-',''),' ',''),'.',''),CHAR(9),'') COLLATE DATABASE_DEFAULT CuitLimpio,
   CAST(NULL AS numeric(11,0)) Cuit,TIPO_PROV COLLATE DATABASE_DEFAULT Tipo,IVA_PROV COLLATE DATABASE_DEFAULT Iva,
   CONVERT(varchar(20),CASE WHEN UPPER(LTRIM(RTRIM(STATUS_PROV))) COLLATE Latin1_General_CI_AS IN ('1','ACTIVO','SI','SÍ') THEN 'ACTIVO' ELSE 'INACTIVO' END) Estado,
   CALLE_PROV COLLATE DATABASE_DEFAULT Calle,NRO_CALLE_PROV COLLATE DATABASE_DEFAULT Numero,
   PISO_DEPTO_PROV COLLATE DATABASE_DEFAULT PisoDepto,LOCALIDAD_PROV COLLATE DATABASE_DEFAULT Localidad,PROVINCIA_PROV COLLATE DATABASE_DEFAULT Provincia,
   TEL1_PROV COLLATE DATABASE_DEFAULT Tel1,TEL2_PROV COLLATE DATABASE_DEFAULT Tel2,EMAIL_PROV COLLATE DATABASE_DEFAULT Email,
   FECHA_ALTA FechaAlta,USUARIO_ALTA COLLATE DATABASE_DEFAULT UsuarioAlta,FECHA_UPD FechaUpd,USUARIO_UPD COLLATE DATABASE_DEFAULT UsuarioUpd,
   CONVERT(nvarchar(max),CONCAT(CAST(N'LK_PROVEEDORES - valores originales: ' AS nvarchar(max)),
    N'ID_PROVEEDOR=',ID_PROVEEDOR,N'; RAZON_SOCIAL=',RAZON_SOCIAL_PROV,N'; CUIT=',CUIT_PROV,
    N'; CALLE=',CALLE_PROV,N'; NRO=',NRO_CALLE_PROV,N'; PISO_DEPTO=',PISO_DEPTO_PROV,N'; LOCALIDAD=',LOCALIDAD_PROV,N'; PROVINCIA=',PROVINCIA_PROV,
    N'; TEL1=',TEL1_PROV,N'; TEL2=',TEL2_PROV,N'; EMAIL=',EMAIL_PROV,N'; IVA=',IVA_PROV,N'; TIPO=',TIPO_PROV,N'; STATUS=',STATUS_PROV,
    N'; OBSERVACION=',OBSERV_PROV,N'; FECHA_ALTA=',CONVERT(nvarchar(30),FECHA_ALTA,121),N'; USUARIO_ALTA=',USUARIO_ALTA,
    N'; FECHA_UPD=',CONVERT(nvarchar(30),FECHA_UPD,121),N'; USUARIO_UPD=',USUARIO_UPD)) COLLATE DATABASE_DEFAULT Raw
  INTO #P FROM dbo.LK_PROVEEDORES WITH(HOLDLOCK);
  IF NOT EXISTS(SELECT 1 FROM #P) AND @PermitirOrigenVacio=0 THROW 54006,'LK_PROVEEDORES vacia; no se borra el destino.',1;
  IF EXISTS(SELECT 1 FROM #P WHERE ID IS NULL OR ID<=0) OR EXISTS(SELECT ID FROM #P GROUP BY ID HAVING COUNT(*)>1)
   THROW 54007,'IDs de proveedor invalidos o duplicados.',1;
  CREATE UNIQUE CLUSTERED INDEX IX_P ON #P(ID);
  UPDATE #P SET Cuit=TRY_CAST(CuitLimpio AS numeric(11,0))
   WHERE LEN(CuitLimpio)=11 AND CuitLimpio COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%'
    AND TRY_CAST(CuitLimpio AS numeric(11,0))>0;
  INSERT #Excepciones SELECT ID,'CUIT',CONCAT(N'CUIT ausente, ambiguo o distinto de 11 digitos; se carga NULL. Original: ',CuitOriginal) FROM #P WHERE Cuit IS NULL;
  SELECT ID,Cuit,ROW_NUMBER() OVER(PARTITION BY Cuit ORDER BY ID) rn,MIN(ID) OVER(PARTITION BY Cuit) ID_CONSERVADO INTO #CuitRepetidos FROM #P WHERE Cuit IS NOT NULL;
  INSERT #Excepciones SELECT ID,'CUIT',CONCAT(N'CUIT duplicado: ',Cuit,N'; se conserva en proveedor ID=',ID_CONSERVADO,N'. En esta persona se carga NULL; original conservado.') FROM #CuitRepetidos WHERE rn>1;
  UPDATE p SET Cuit=NULL FROM #P p JOIN #CuitRepetidos d ON d.ID=p.ID WHERE d.rn>1;
  INSERT #Excepciones SELECT p.ID,'ESTADO',CONCAT(N'Estado no reconocido; INACTIVO. Original: ',l.STATUS_PROV)
   FROM #P p JOIN dbo.LK_PROVEEDORES l ON l.ID_PROVEEDOR=p.ID WHERE ISNULL(UPPER(LTRIM(RTRIM(l.STATUS_PROV))) COLLATE Latin1_General_CI_AS,'') NOT IN ('0','1','ACTIVO','INACTIVO','SI','SÍ','NO');
  INSERT #Excepciones SELECT ID,'RAZON_SOCIAL',N'Razon social vacia; se conserva el texto de origen.' FROM #P WHERE NULLIF(LTRIM(RTRIM(Razon)),'') IS NULL;
  SELECT p.ID,p.Entidad,ISNULL(p.Calle,'') CALLE,p.Numero NRO,
   CONVERT(varchar(50),CASE WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') AS int) IS NOT NULL
    OR UPPER(LTRIM(RTRIM(p.PisoDepto)))='PB' THEN LTRIM(RTRIM(p.PisoDepto)) END) PISO,
   CAST(NULL AS varchar(50)) DEPTO,p.Localidad LOCALIDAD,p.Provincia PROVINCIA,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_PROVEEDORES domicilio: ' AS nvarchar(max)),N'CALLE=',p.Calle,N'; NRO=',p.Numero,N'; PISO_DEPTO=',p.PisoDepto,
    N'; LOCALIDAD=',p.Localidad,N'; PROVINCIA=',p.Provincia,
    CASE WHEN NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') IS NOT NULL AND TRY_CAST(p.PisoDepto AS int) IS NULL AND UPPER(LTRIM(RTRIM(p.PisoDepto)))<>'PB'
     THEN N'; EXCEPCION: piso/departamento ambiguo; consultar original.' ELSE N'' END)) OBSERVACIONES
  INTO #Domicilios FROM #P p WHERE NULLIF(LTRIM(RTRIM(CONCAT(p.Calle,p.Numero,p.PisoDepto,p.Localidad,p.Provincia))),'') IS NOT NULL;
  INSERT #Excepciones SELECT p.ID,'DOMICILIO',CONCAT(N'Domicilio incompleto o piso/departamento ambiguo. Original: ',d.OBSERVACIONES)
   FROM #Domicilios d JOIN #P p ON p.ID=d.ID WHERE NULLIF(LTRIM(RTRIM(p.Calle)),'') IS NULL
    OR (NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') IS NOT NULL AND d.PISO IS NULL);
  CREATE TABLE #TelefonosRaw(ID int,Entidad varchar(30) COLLATE DATABASE_DEFAULT,Orden int,Campo sysname COLLATE DATABASE_DEFAULT,Original nvarchar(max) COLLATE DATABASE_DEFAULT);
  DECLARE @id int,@ent varchar(30),@raw nvarchar(max),@campo sysname,@orden int,@pos int,@parte nvarchar(max),@contador int;
  DECLARE telefonos CURSOR LOCAL FAST_FORWARD FOR SELECT p.ID,p.Entidad,v.Campo,v.Texto,v.Orden FROM #P p
   CROSS APPLY(VALUES(N'TEL1_PROV',p.Tel1,1),(N'TEL2_PROV',p.Tel2,2)) v(Campo,Texto,Orden) WHERE NULLIF(LTRIM(RTRIM(v.Texto)),N'') IS NOT NULL ORDER BY p.ID,v.Orden;
  OPEN telefonos; FETCH NEXT FROM telefonos INTO @id,@ent,@campo,@raw,@orden;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @parte=REPLACE(REPLACE(REPLACE(@raw,N';',N'/'),CHAR(13),N'/'),CHAR(10),N'/'); SET @contador=0;
   WHILE LEN(@parte)>0
   BEGIN
    SET @pos=CHARINDEX(N'/',@parte); IF @pos=0 SET @pos=LEN(@parte)+1;
    IF NULLIF(LTRIM(RTRIM(LEFT(@parte,@pos-1))),N'') IS NOT NULL
    BEGIN
     SET @contador+=1;
     INSERT #TelefonosRaw VALUES(@id,@ent,@orden*10000+@contador,@campo,LTRIM(RTRIM(LEFT(@parte,@pos-1))));
    END;
    SET @parte=SUBSTRING(@parte,@pos+1,LEN(@parte));
   END;
   IF @contador=0 INSERT #TelefonosRaw VALUES(@id,@ent,@orden*10000,@campo,@raw);
   FETCH NEXT FROM telefonos INTO @id,@ent,@campo,@raw,@orden;
  END;
  CLOSE telefonos; DEALLOCATE telefonos;
  SELECT r.ID,r.Entidad,t.CODAREA,t.NRO,t.Excepcion,
   CONVERT(varchar(50),CASE WHEN ROW_NUMBER() OVER(PARTITION BY r.ID ORDER BY CASE WHEN t.Excepcion IS NULL THEN 0 ELSE 1 END,r.Orden)=1 THEN @Principal ELSE '0' END) PRINCIPAL,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_PROVEEDORES telefono: ' AS nvarchar(max)),r.Campo,N' original completo=',CASE WHEN r.Campo=N'TEL1_PROV' THEN p.Tel1 ELSE p.Tel2 END,
    N'; segmento=',r.Original,N'; ',t.Excepcion)) OBSERVACIONES
  INTO #Telefonos FROM #TelefonosRaw r JOIN #P p ON p.ID=r.ID CROSS APPLY dbo.VCT_MIG_INTERPRETAR_TELEFONO(r.Original) t;
  INSERT #Excepciones SELECT ID,'TELEFONO',CONCAT(N'Telefono: ',OBSERVACIONES) FROM #Telefonos WHERE Excepcion IS NOT NULL;
  SELECT p.ID,p.Entidad,CONVERT(varchar(100),e.EMAIL) EMAIL,e.Excepcion,
   CONVERT(varchar(50),CASE WHEN ROW_NUMBER() OVER(PARTITION BY p.ID ORDER BY CASE WHEN e.EMAIL<>N'' THEN 0 ELSE 1 END,e.Orden)=1 THEN @Principal ELSE '0' END) PRINCIPAL,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_PROVEEDORES EMAIL_PROV original: ' AS nvarchar(max)),p.Email,N'; ',e.Excepcion)) OBSERVACIONES
  INTO #Emails FROM #P p CROSS APPLY dbo.VCT_MIG_EXTRAER_EMAILS(p.Email) e;
  INSERT #Excepciones SELECT ID,'EMAIL',CONCAT(N'Email: ',OBSERVACIONES) FROM #Emails WHERE Excepcion IS NOT NULL;
 
 
  UPDATE p SET Raw=CONCAT(p.Raw,NCHAR(13),NCHAR(10),x.Notas) FROM #P p
   CROSS APPLY(SELECT (SELECT NCHAR(13)+NCHAR(10)+N'EXCEPCION: '+e.Detalle FROM #Excepciones e WHERE e.ID_PROVEEDOR=p.ID ORDER BY e.Campo FOR XML PATH(''),TYPE).value('.','nvarchar(max)') Notas) x;
  CREATE TABLE #Resumen(Tabla sysname COLLATE DATABASE_DEFAULT PRIMARY KEY,Esperadas bigint,ColumnaId sysname COLLATE DATABASE_DEFAULT);
  INSERT #Resumen VALUES(N'VCT_PROVEEDORES',(SELECT COUNT_BIG(*) FROM #P),N'ID_PROVEEDOR'),
   (N'VCT_DOMICILIOS',(SELECT COUNT_BIG(*) FROM #Domicilios),N'ID'),
   (N'VCT_TELEFONOS',(SELECT COUNT_BIG(*) FROM #Telefonos),N'ID'),(N'VCT_EMAILS',(SELECT COUNT_BIG(*) FROM #Emails),N'ID');
  IF @Aplicar=0
  BEGIN
   SELECT N'VISTA PREVIA: NO SE MODIFICARON DATOS' Resultado;
   SELECT Tabla,Esperadas FROM #Resumen ORDER BY Tabla;
   SELECT ID ID_PROVEEDOR,Razon,Cuit,CuitOriginal,Tipo,Iva,Estado,Raw OBSERVACIONES FROM #P ORDER BY ID;
   SELECT * FROM #Domicilios ORDER BY ID; SELECT * FROM #Telefonos ORDER BY ID; SELECT * FROM #Emails ORDER BY ID;
   SELECT * FROM #Excepciones ORDER BY ID_PROVEEDOR,Campo;
   RETURN;
  END;
  DECLARE @Tablas TABLE(ObjectId int PRIMARY KEY,Nombre sysname);
  INSERT @Tablas SELECT OBJECT_ID(N'dbo.'+Tabla),Tabla FROM #Resumen;
  IF EXISTS(SELECT 1 FROM #Resumen r LEFT JOIN sys.identity_columns c ON c.object_id=OBJECT_ID(N'dbo.'+r.Tabla)
    WHERE c.column_id IS NULL OR c.name COLLATE DATABASE_DEFAULT<>r.ColumnaId COLLATE DATABASE_DEFAULT OR CONVERT(bigint,c.seed_value)<>1 OR CONVERT(bigint,c.increment_value)<>1)
   THROW 54008,'Identidades destino diferentes del modelo suministrado.',1;
  DECLARE bloquear CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM @Tablas ORDER BY ObjectId;
  OPEN bloquear; FETCH NEXT FROM bloquear INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+N' WITH(TABLOCKX,HOLDLOCK);';
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   FETCH NEXT FROM bloquear INTO @nombre;
  END;
  CLOSE bloquear; DEALLOCATE bloquear;
  DECLARE dependencias CURSOR LOCAL FAST_FORWARD FOR SELECT f.parent_object_id,f.name,f.object_id,t.Nombre
   FROM sys.foreign_keys f JOIN @Tablas t ON t.ObjectId=f.referenced_object_id
   WHERE t.Nombre IN (N'VCT_DOMICILIOS',N'VCT_TELEFONOS',N'VCT_EMAILS');
  OPEN dependencias; FETCH NEXT FROM dependencias INTO @parent,@nombre,@fk,@tabla;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SELECT @cond=STUFF((SELECT N' AND p.'+QUOTENAME(COL_NAME(c.parent_object_id,c.parent_column_id))+N'=a.'+QUOTENAME(COL_NAME(c.referenced_object_id,c.referenced_column_id))
    FROM sys.foreign_key_columns c WHERE c.constraint_object_id=@fk ORDER BY c.constraint_column_id FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,5,N'');
   SET @sql=N'SELECT @Hay=CASE WHEN EXISTS(SELECT 1 FROM '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N' p JOIN dbo.'+QUOTENAME(@tabla)+N' a ON '+@cond+N' WHERE a.TIPO_ENTIDAD IN (''PROVEEDOR'')) THEN 1 ELSE 0 END;';
   EXEC sys.sp_executesql @sql,N'@Hay bit OUTPUT',@Hay=@hay OUTPUT;
   IF @hay=1
   BEGIN
    SELECT OBJECT_SCHEMA_NAME(@parent) Esquema,OBJECT_NAME(@parent) TablaDependiente,@nombre FK;
    THROW 54012,'Hay referencias a IDs auxiliares que se regeneran. Resolver la dependencia antes de migrar.',1;
   END;
   FETCH NEXT FROM dependencias INTO @parent,@nombre,@fk,@tabla;
  END;
  CLOSE dependencias; DEALLOCATE dependencias;
 
  CREATE TABLE #IndicesCuit(Nombre sysname COLLATE DATABASE_DEFAULT,Descendente bit,Incluidas nvarchar(max) COLLATE DATABASE_DEFAULT,Filtro nvarchar(max) COLLATE DATABASE_DEFAULT,Grupo sysname COLLATE DATABASE_DEFAULT,IndexId int);
  INSERT #IndicesCuit SELECT i.name,k.is_descending_key,
   STUFF((SELECT N','+QUOTENAME(COL_NAME(c.object_id,c.column_id)) FROM sys.index_columns c WHERE c.object_id=i.object_id AND c.index_id=i.index_id AND c.is_included_column=1 ORDER BY c.index_column_id FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,N''),
   i.filter_definition,ds.name,i.index_id FROM sys.indexes i JOIN sys.index_columns k ON k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal=1 JOIN sys.data_spaces ds ON ds.data_space_id=i.data_space_id
   WHERE i.object_id=OBJECT_ID(N'dbo.VCT_PROVEEDORES') AND i.is_unique=1 AND i.is_unique_constraint=0 AND i.is_primary_key=0 AND i.type=2 AND i.is_disabled=0 AND ds.type='FG'
    AND COL_NAME(k.object_id,k.column_id)=N'CUIT' AND NOT EXISTS(SELECT 1 FROM sys.index_columns c WHERE c.object_id=i.object_id AND c.index_id=i.index_id AND c.key_ordinal>1)
    AND (i.has_filter=0 OR REPLACE(REPLACE(REPLACE(UPPER(i.filter_definition),N'[',N''),N']',N''),N' ',N'') NOT LIKE N'%CUITISNOTNULL%');
  IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #IndicesCuit i ON i.IndexId=f.key_index_id WHERE f.referenced_object_id=OBJECT_ID(N'dbo.VCT_PROVEEDORES'))
   THROW 54009,'Una FK referencia el indice CUIT; adaptar esa relacion antes de permitir CUIT ausentes.',1;
  CREATE TABLE #FKs(ParentId int,Nombre sysname COLLATE DATABASE_DEFAULT,Deshabilitada bit,NoConfiable bit);
  INSERT #FKs SELECT f.parent_object_id,f.name,f.is_disabled,f.is_not_trusted FROM sys.foreign_keys f
   WHERE EXISTS(SELECT 1 FROM @Tablas t WHERE t.ObjectId=f.parent_object_id OR t.ObjectId=f.referenced_object_id);
  CREATE TABLE #Triggers(ParentId int,Nombre sysname COLLATE DATABASE_DEFAULT);
  INSERT #Triggers SELECT tr.parent_id,tr.name FROM sys.triggers tr JOIN @Tablas t ON t.ObjectId=tr.parent_id WHERE tr.is_disabled=0;
  DECLARE desactivar CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #FKs WHERE Deshabilitada=0;
  OPEN desactivar; FETCH NEXT FROM desactivar INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N' NOCHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM desactivar INTO @parent,@nombre;
  END;
  CLOSE desactivar; DEALLOCATE desactivar;
  DECLARE desactivartrg CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #Triggers;
  OPEN desactivartrg; FETCH NEXT FROM desactivartrg INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DISABLE TRIGGER '+QUOTENAME(@nombre)+N' ON '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N';'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM desactivartrg INTO @parent,@nombre;
  END;
  CLOSE desactivartrg; DEALLOCATE desactivartrg;
 
  DELETE dbo.VCT_PROVEEDORES;
  DELETE dbo.VCT_DOMICILIOS WHERE TIPO_ENTIDAD='PROVEEDOR';
  DELETE dbo.VCT_TELEFONOS WHERE TIPO_ENTIDAD='PROVEEDOR';
  DELETE dbo.VCT_EMAILS WHERE TIPO_ENTIDAD='PROVEEDOR';
  DECLARE @idxNombre sysname,@idxDesc bit,@idxInclude nvarchar(max),@idxFiltro nvarchar(max),@idxGrupo sysname;
  DECLARE indicescuit CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre,Descendente,Incluidas,Filtro,Grupo FROM #IndicesCuit;
  OPEN indicescuit; FETCH NEXT FROM indicescuit INTO @idxNombre,@idxDesc,@idxInclude,@idxFiltro,@idxGrupo;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DROP INDEX '+QUOTENAME(@idxNombre)+N' ON dbo.VCT_PROVEEDORES; CREATE UNIQUE NONCLUSTERED INDEX '+QUOTENAME(@idxNombre)
    +N' ON dbo.VCT_PROVEEDORES([CUIT]'+CASE WHEN @idxDesc=1 THEN N' DESC' ELSE N' ASC' END+N')'
    +CASE WHEN NULLIF(@idxInclude,N'') IS NOT NULL THEN N' INCLUDE ('+@idxInclude+N')' ELSE N'' END+N' WHERE [CUIT] IS NOT NULL'
    +CASE WHEN NULLIF(@idxFiltro,N'') IS NOT NULL THEN N' AND ('+@idxFiltro+N')' ELSE N'' END+N' ON '+QUOTENAME(@idxGrupo)+N';';
   EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM indicescuit INTO @idxNombre,@idxDesc,@idxInclude,@idxFiltro,@idxGrupo;
  END;
  CLOSE indicescuit; DEALLOCATE indicescuit;
  SET IDENTITY_INSERT dbo.VCT_PROVEEDORES ON; SET @identity=N'VCT_PROVEEDORES';
  INSERT dbo.VCT_PROVEEDORES(ID_PROVEEDOR,RAZON_SOCIAL,DESCRIPCION,CUIT,TIPO_PROVEEDOR,CONDICION_IVA,ESTADO,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT ID,ISNULL(Razon,''),NULL,Cuit,Tipo,Iva,Estado,CONVERT(varchar(max),Raw),FechaAlta,UsuarioAlta,FechaUpd,UsuarioUpd FROM #P;
  SET IDENTITY_INSERT dbo.VCT_PROVEEDORES OFF; SET @identity=NULL;
  INSERT dbo.VCT_DOMICILIOS(TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT d.Entidad,d.ID,d.CALLE,d.NRO,d.PISO,d.DEPTO,d.LOCALIDAD,d.PROVINCIA,@Principal,d.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Domicilios d JOIN #P p ON p.ID=d.ID;
  INSERT dbo.VCT_TELEFONOS(TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT t.Entidad,t.ID,t.CODAREA,t.NRO,t.PRINCIPAL,t.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Telefonos t JOIN #P p ON p.ID=t.ID;
  INSERT dbo.VCT_EMAILS(TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT e.Entidad,e.ID,e.EMAIL,e.PRINCIPAL,e.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Emails e JOIN #P p ON p.ID=e.ID;
 
  IF EXISTS(SELECT ID FROM #P EXCEPT SELECT ID_PROVEEDOR FROM dbo.VCT_PROVEEDORES)
   OR EXISTS(SELECT ID_PROVEEDOR FROM dbo.VCT_PROVEEDORES EXCEPT SELECT ID FROM #P)
   THROW 54010,'IDs de proveedores no coinciden con origen.',1;
  DECLARE validar CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla,Esperadas,ColumnaId FROM #Resumen;
  OPEN validar; FETCH NEXT FROM validar INTO @nombre,@esperado,@columna;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+CASE WHEN @nombre<>N'VCT_PROVEEDORES' THEN N' WHERE TIPO_ENTIDAD=''PROVEEDOR''' ELSE N'' END;
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   IF @n<>@esperado THROW 54011,'Conteos incorrectos; se revierte la carga.',1;
   SET @tabla=N'dbo.'+QUOTENAME(@nombre);
   SET @sql=N'SELECT @M=MAX('+QUOTENAME(@columna)+N') FROM '+@tabla; EXEC sys.sp_executesql @sql,N'@M int OUTPUT',@M=@ultimo OUTPUT;
   SET @valor=CASE WHEN @ultimo IS NOT NULL THEN @ultimo WHEN EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(@tabla) AND last_value IS NULL) THEN 1 ELSE 0 END;
   SET @sql=N'DBCC CHECKIDENT(N'''+REPLACE(@tabla,'''','''''')+N''',RESEED,'+CONVERT(nvarchar(20),@valor)+N') WITH NO_INFOMSGS;'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM validar INTO @nombre,@esperado,@columna;
  END;
  CLOSE validar; DEALLOCATE validar;
  DECLARE restaurar CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre,NoConfiable FROM #FKs WHERE Deshabilitada=0;
  OPEN restaurar; FETCH NEXT FROM restaurar INTO @parent,@nombre,@trust;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @tabla=QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent));
   SET @sql=N'ALTER TABLE '+@tabla+N' WITH CHECK CHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   IF @trust=1
   BEGIN
    SET @sql=N'ALTER TABLE '+@tabla+N' NOCHECK CONSTRAINT '+QUOTENAME(@nombre)+N'; ALTER TABLE '+@tabla+N' CHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   END;
   FETCH NEXT FROM restaurar INTO @parent,@nombre,@trust;
  END;
  CLOSE restaurar; DEALLOCATE restaurar;
  DECLARE restaurartrg CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #Triggers;
  OPEN restaurartrg; FETCH NEXT FROM restaurartrg INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'ENABLE TRIGGER '+QUOTENAME(@nombre)+N' ON '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent)); EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM restaurartrg INTO @parent,@nombre;
  END;
  CLOSE restaurartrg; DEALLOCATE restaurartrg;
 
  INSERT dbo.VCT_MIGRACION_PROVEEDORES_EJECUCIONES(ID,FECHA,PROVEEDORES,EXCEPCIONES,USUARIO)
   SELECT @run,@ahora,(SELECT COUNT(*) FROM #P),(SELECT COUNT(*) FROM #Excepciones),LEFT(SUSER_SNAME(),100);
  INSERT dbo.VCT_MIGRACION_PROVEEDORES_EXCEPCIONES(ID_EJECUCION,ID_PROVEEDOR,CAMPO,OBSERVACIONES)
   SELECT @run,ID_PROVEEDOR,Campo,Detalle FROM #Excepciones;
  COMMIT TRANSACTION;
  SELECT N'MIGRACION PROVEEDORES CONFIRMADA' Resultado,@run ID_EJECUCION;
  SELECT Tabla,Esperadas FilasCargadas FROM #Resumen ORDER BY Tabla;
  SELECT * FROM #Excepciones ORDER BY ID_PROVEEDOR,Campo;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @identity IS NOT NULL
  BEGIN TRY
   SET @sql=N'SET IDENTITY_INSERT dbo.'+QUOTENAME(@identity)+N' OFF;'; EXEC sys.sp_executesql @sql;
  END TRY
  BEGIN CATCH
   PRINT N'Cerrar esta conexion antes de reintentar: no pudo limpiarse IDENTITY_INSERT.';
  END CATCH;
  THROW;
 END CATCH;
END;
