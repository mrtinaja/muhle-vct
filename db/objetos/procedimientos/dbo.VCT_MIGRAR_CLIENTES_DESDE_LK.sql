 
CREATE   PROCEDURE dbo.VCT_MIGRAR_CLIENTES_DESDE_LK
 @Aplicar bit=0,
 @Principal varchar(50)='1',
 @PermitirOrigenVacio bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF;
 SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;
 IF DB_NAME()<>N'MuhlePROD' OR ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')),N'')<>N'WIN-83AM68966R4'
  THROW 52000, 'Destino permitido: MuhlePROD en WIN-83AM68966R4 (desarrollo).',1;
 IF @@TRANCOUNT<>0 THROW 52001,'Ejecutar sin transacciones anteriores.',1;
 IF @Principal IS NULL OR @Principal IN ('','0') THROW 52002,'Informar el valor que identifica un registro principal.',1;
 IF OBJECT_ID(N'dbo.LK_CLIENTES',N'U') IS NULL THROW 52003,'No existe LK_CLIENTES.',1;
 DECLARE @IdentityActivo sysname=NULL,@sql nvarchar(max),@parent int,@nombre sysname,@tabla nvarchar(517),@flags bit,@afectados bit,@recurso int;
 BEGIN TRY
  IF @Aplicar=1
  BEGIN
   BEGIN TRANSACTION;
   EXEC @recurso=sys.sp_getapplock @Resource=N'VCT_MIG_MODELO_NUEVO',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0;
   IF @recurso<0 THROW 52004,'Hay otra migracion en curso.',1;
  END;
  -- Raw data remains available for every exception; no changes are made to LK_CLIENTES.
  SELECT TRY_CAST(l.ID_CLIENTE AS int) AS ID,
   CONVERT(nvarchar(max),l.RAZON_SOCIAL_CLIENTE) Razon,
   CONVERT(nvarchar(max),l.CUIT_CLIENTE) Cuit,
   CONVERT(nvarchar(max),l.CALLE_CLIENTE) Calle,
   CONVERT(nvarchar(max),l.NRO_CALLE_CLIENTE) Numero,
   CONVERT(nvarchar(max),l.PISO_DEPTO_CLIENTE) PisoDepto,
   CONVERT(nvarchar(max),l.LOCALIDAD_CLIENTE) Localidad,
   CONVERT(nvarchar(max),l.PROVINCIA_CLIENTE) Provincia,
   CONVERT(nvarchar(max),l.TEL1_CLIENTE) Tel1,
   CONVERT(nvarchar(max),l.TEL2_CLIENTE) Tel2,
   CONVERT(nvarchar(max),l.EMAIL_CLIENTE) EmailOrigen,
   CONVERT(nvarchar(max),l.CONTACTO_CLIENTE) ContactoOrigen,
   CONVERT(nvarchar(max),l.IVA_CLIENTE) Iva,
   CONVERT(nvarchar(max),l.TIPO_CLIENTE) Tipo,
   CONVERT(nvarchar(max),l.STATUS_CLIENTE) Estado,
   CONVERT(nvarchar(max),l.OBSERV_CLIENTE) ObservOrigen,
   TRY_CAST(l.FECHA_ALTA AS datetime) FechaAlta,
   CONVERT(nvarchar(max),l.USUARIO_ALTA) UsuarioAlta,
   TRY_CAST(l.FECHA_UPD AS datetime) FechaUpd,
   CONVERT(nvarchar(max),l.USUARIO_UPD) UsuarioUpd,
   CONCAT(CAST(N'LK_CLIENTES - valores originales:' AS nvarchar(max)),
    NCHAR(13),
    NCHAR(10),
    N'ID_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.ID_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'RAZON_SOCIAL_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.RAZON_SOCIAL_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'CUIT_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.CUIT_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'CALLE_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.CALLE_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'NRO_CALLE_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.NRO_CALLE_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'PISO_DEPTO_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.PISO_DEPTO_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'LOCALIDAD_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.LOCALIDAD_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'PROVINCIA_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.PROVINCIA_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'TEL1_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.TEL1_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'TEL2_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.TEL2_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'EMAIL_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.EMAIL_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'IVA_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.IVA_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'CONTACTO_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.CONTACTO_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'TIPO_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.TIPO_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'STATUS_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.STATUS_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'OBSERV_CLIENTE=',
    ISNULL(CONVERT(nvarchar(max),l.OBSERV_CLIENTE),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'FECHA_ALTA=',
    ISNULL(CONVERT(nvarchar(max),l.FECHA_ALTA),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'USUARIO_ALTA=',
    ISNULL(CONVERT(nvarchar(max),l.USUARIO_ALTA),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'FECHA_UPD=',
    ISNULL(CONVERT(nvarchar(max),l.FECHA_UPD),N'<NULL>'),
    NCHAR(13),
    NCHAR(10),
    N'USUARIO_UPD=',
    ISNULL(CONVERT(nvarchar(max),l.USUARIO_UPD),N'<NULL>')) AS RespaldoOrigen
  INTO #Origen FROM dbo.LK_CLIENTES l WITH(HOLDLOCK);
  IF EXISTS(SELECT 1 FROM #Origen WHERE ID IS NULL) OR EXISTS(SELECT ID FROM #Origen GROUP BY ID HAVING COUNT(*)>1)
   THROW 52005,'ID_CLIENTE nulo, fuera de int o duplicado: no se puede conservar el ID.',1;
  IF NOT EXISTS(SELECT 1 FROM #Origen) AND @PermitirOrigenVacio=0
   THROW 52006,'LK_CLIENTES esta vacia; se cancela para evitar un borrado accidental.',1;
  CREATE UNIQUE CLUSTERED INDEX IX_Origen ON #Origen(ID);
  CREATE TABLE #Excepciones(Tabla sysname,ID_CLIENTE int,Campo sysname,Detalle nvarchar(max));
  INSERT #Excepciones
  SELECT N'VCT_CLIENTES',ID,N'Campos',N'Campos obligatorios vacios o campos excedidos: se conserva origen completo en OBSERVACIONES.'
  FROM #Origen WHERE ISNULL(Razon,N'')=N'' OR ISNULL(Cuit,N'')=N'' OR DATALENGTH(CONVERT(varchar(max),Razon))>300 OR DATALENGTH(CONVERT(varchar(max),Cuit))>50 OR DATALENGTH(CONVERT(varchar(max),Iva))>50 OR DATALENGTH(CONVERT(varchar(max),Tipo))>50 OR DATALENGTH(CONVERT(varchar(max),Estado))>50 OR DATALENGTH(CONVERT(varchar(max),UsuarioAlta))>100 OR DATALENGTH(CONVERT(varchar(max),UsuarioUpd))>100;
  CREATE TABLE #Domicilios(ID int,ID_CLIENTE int,CALLE varchar(300),NRO varchar(50),PISO varchar(50),DEPTO varchar(50),LOCALIDAD varchar(100),PROVINCIA varchar(50),OBSERVACIONES varchar(max));
  INSERT #Domicilios
  SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY ID)),ID,LEFT(ISNULL(CONVERT(varchar(max),Calle),''),300),LEFT(CONVERT(varchar(max),Numero),50),
   CASE WHEN TRY_CAST(LEFT(LTRIM(RTRIM(PisoDepto)),50) AS int) IS NOT NULL OR UPPER(LTRIM(RTRIM(PisoDepto)))=N'PB' THEN LEFT(CONVERT(varchar(max),LTRIM(RTRIM(PisoDepto))),50) ELSE NULL END,
   NULL,LEFT(CONVERT(varchar(max),Localidad),100),LEFT(CONVERT(varchar(max),Provincia),50),
   CONVERT(varchar(max),CONCAT(CAST(N'[MIGRACION LK_CLIENTES] CALLE_CLIENTE=' AS nvarchar(max)),Calle,N'; NRO_CALLE_CLIENTE=',Numero,N'; PISO_DEPTO_CLIENTE=',PisoDepto,N'; LOCALIDAD_CLIENTE=',Localidad,N'; PROVINCIA_CLIENTE=',Provincia))
  FROM #Origen WHERE NULLIF(LTRIM(RTRIM(CONCAT(Calle,Numero,PisoDepto,Localidad,Provincia))),N'') IS NOT NULL;
  INSERT #Excepciones SELECT N'VCT_DOMICILIOS',o.ID,N'PISO_DEPTO_CLIENTE',N'Piso/departamento no separables con seguridad; conservados en OBSERVACIONES.'
  FROM #Origen o JOIN #Domicilios d ON d.ID_CLIENTE=o.ID WHERE NULLIF(LTRIM(RTRIM(o.PisoDepto)),N'') IS NOT NULL AND d.PISO IS NULL;
  INSERT #Excepciones SELECT N'VCT_DOMICILIOS',ID,N'Domicilio',N'Calle vacia o campos excedidos; original conservado en OBSERVACIONES.' FROM #Origen
  WHERE (ISNULL(Calle,N'')=N'' AND NULLIF(CONCAT(Numero,PisoDepto,Localidad,Provincia),N'') IS NOT NULL) OR DATALENGTH(CONVERT(varchar(max),Calle))>300 OR DATALENGTH(CONVERT(varchar(max),Numero))>50 OR DATALENGTH(CONVERT(varchar(max),Localidad))>100 OR DATALENGTH(CONVERT(varchar(max),Provincia))>50;
  CREATE TABLE #TelefonosRaw(ID_CLIENTE int,Orden int,Campo sysname,Original nvarchar(max));
  DECLARE @id int,@raw nvarchar(max),@campo sysname,@orden int,@p int,@parte nvarchar(max),@contador int;
  DECLARE telraw CURSOR LOCAL FAST_FORWARD FOR
   SELECT ID,v.Campo,v.Texto,v.Orden FROM #Origen CROSS APPLY(VALUES(N'TEL1_CLIENTE',Tel1,1),(N'TEL2_CLIENTE',Tel2,2)) v(Campo,Texto,Orden) WHERE NULLIF(LTRIM(RTRIM(v.Texto)),N'') IS NOT NULL ORDER BY ID,v.Orden;
  OPEN telraw; FETCH NEXT FROM telraw INTO @id,@campo,@raw,@orden;
  WHILE @@FETCH_STATUS=0
  BEGIN
   -- Explicit list separators create individual candidates; ambiguous digits remain original.
   SET @parte=REPLACE(REPLACE(REPLACE(@raw,N';',N'/'),CHAR(13),N'/'),CHAR(10),N'/'); SET @contador=0;
   WHILE LEN(@parte)>0
   BEGIN
    SET @p=CHARINDEX(N'/',@parte); IF @p=0 SET @p=LEN(@parte)+1;
    IF NULLIF(LTRIM(RTRIM(LEFT(@parte,@p-1))),N'') IS NOT NULL
    BEGIN
     SET @contador+=1;
     INSERT #TelefonosRaw VALUES(@id,@orden*10000+@contador,@campo,LTRIM(RTRIM(LEFT(@parte,@p-1))));
    END;
    SET @parte=SUBSTRING(@parte,@p+1,LEN(@parte));
   END;
   IF @contador=0 INSERT #TelefonosRaw VALUES(@id,@orden*10000,@campo,@raw);
   FETCH NEXT FROM telraw INTO @id,@campo,@raw,@orden;
  END;
  CLOSE telraw; DEALLOCATE telraw;
  SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY r.ID_CLIENTE,r.Orden)) AS ID,r.ID_CLIENTE,r.Orden,r.Campo,r.Original,p.CODAREA,p.NRO,p.Excepcion,
   CONVERT(varchar(50),CASE WHEN ROW_NUMBER() OVER(PARTITION BY r.ID_CLIENTE ORDER BY CASE WHEN p.Excepcion IS NULL THEN 0 ELSE 1 END,r.Orden)=1 THEN @Principal ELSE '0' END) PRINCIPAL,
   CONVERT(varchar(max),CONCAT(CAST(N'[MIGRACION LK_CLIENTES] ' AS nvarchar(max)),r.Campo,N' original completo: ',CASE WHEN r.Campo=N'TEL1_CLIENTE' THEN o.Tel1 ELSE o.Tel2 END,N'; segmento: ',r.Original,CASE WHEN p.Excepcion IS NULL THEN N'' ELSE N'; EXCEPCION: '+p.Excepcion END)) OBSERVACIONES
  INTO #Telefonos FROM #TelefonosRaw r JOIN #Origen o ON o.ID=r.ID_CLIENTE CROSS APPLY dbo.VCT_MIG_INTERPRETAR_TELEFONO(r.Original) p;
  INSERT #Excepciones SELECT N'VCT_TELEFONOS',ID_CLIENTE,Campo,Excepcion FROM #Telefonos WHERE Excepcion IS NOT NULL;
  SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY o.ID,e.Orden)) AS ID,o.ID AS ID_CLIENTE,e.Orden,CONVERT(varchar(100),e.EMAIL) EMAIL,e.Excepcion,
   CONVERT(varchar(50),CASE WHEN ROW_NUMBER() OVER(PARTITION BY o.ID ORDER BY CASE WHEN e.EMAIL<>N'' THEN 0 ELSE 1 END,e.Orden)=1 THEN @Principal ELSE '0' END) PRINCIPAL,
   CONVERT(varchar(max),CONCAT(CAST(N'[MIGRACION LK_CLIENTES] EMAIL_CLIENTE original: ' AS nvarchar(max)),o.EmailOrigen,CASE WHEN e.Excepcion IS NULL THEN N'' ELSE N'; EXCEPCION: '+e.Excepcion END)) OBSERVACIONES
  INTO #Emails FROM #Origen o CROSS APPLY dbo.VCT_MIG_EXTRAER_EMAILS(o.EmailOrigen) e;
  INSERT #Excepciones SELECT N'VCT_EMAILS',ID_CLIENTE,N'EMAIL_CLIENTE',Excepcion FROM #Emails WHERE Excepcion IS NOT NULL;
  CREATE TABLE #Contactos(ID int,ID_CLIENTE int,APELLIDO varchar(100),NOMBRES varchar(100),CARGO varchar(100),OBSERVACIONES varchar(max));
  DECLARE @nombreContacto nvarchar(max),@apellido nvarchar(max),@nombres nvarchar(max),@nota nvarchar(max),@limite int,@coma int;
  DECLARE contactosraw CURSOR LOCAL FAST_FORWARD FOR SELECT ID,ContactoOrigen FROM #Origen WHERE NULLIF(LTRIM(RTRIM(ContactoOrigen)),N'') IS NOT NULL ORDER BY ID;
  OPEN contactosraw; FETCH NEXT FROM contactosraw INTO @id,@raw;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @nombreContacto=LTRIM(RTRIM(@raw)); SET @apellido=N''; SET @nombres=N''; SET @nota=N'';
   SELECT @limite=MIN(n)
   FROM (
    SELECT NULLIF(CHARINDEX(N' - ',@nombreContacto),0) AS n
    UNION ALL SELECT NULLIF(CHARINDEX(N' / ',@nombreContacto),0)
    UNION ALL SELECT NULLIF(CHARINDEX(N';',@nombreContacto),0)
    UNION ALL SELECT NULLIF(CHARINDEX(CHAR(10),@nombreContacto),0)
   ) AS LimitesContacto;
   IF @limite IS NOT NULL SET @nombreContacto=RTRIM(LEFT(@nombreContacto,@limite-1));
   IF LEN(@nombreContacto)<=100 AND @nombreContacto<>N'' AND @nombreContacto NOT LIKE N'%[0-9@:/<>]%' COLLATE Latin1_General_100_BIN2
   BEGIN
    SET @coma=CHARINDEX(N',',@nombreContacto);
    IF @coma>1 AND CHARINDEX(N',',@nombreContacto,@coma+1)=0 AND @coma<LEN(@nombreContacto)
    BEGIN SET @apellido=LTRIM(RTRIM(LEFT(@nombreContacto,@coma-1))); SET @nombres=LTRIM(RTRIM(SUBSTRING(@nombreContacto,@coma+1,LEN(@nombreContacto)))); END
    ELSE BEGIN SET @nombres=@nombreContacto; SET @nota=N'Nombre completo sin separacion verificable de apellido. APELLIDO vacio.'; END;
   END
   ELSE SET @nota=N'Contacto no separable con seguridad: APELLIDO y NOMBRES vacios; consultar texto original.';
   IF @nombreContacto<>LTRIM(RTRIM(@raw)) SET @nota=CONCAT(@nota,N' Texto adicional y cargos conservados en OBSERVACIONES.');
   INSERT #Contactos VALUES((SELECT COUNT(*)+1 FROM #Contactos),@id,CONVERT(varchar(100),@apellido),CONVERT(varchar(100),@nombres),NULL,CONVERT(varchar(max),CONCAT(CAST(N'[MIGRACION LK_CLIENTES] CONTACTO_CLIENTE original: ' AS nvarchar(max)),@raw,CASE WHEN @nota=N'' THEN N'' ELSE N'; EXCEPCION: '+@nota END)));
   IF @nota<>N'' INSERT #Excepciones VALUES(N'VCT_CONTACTOS',@id,N'CONTACTO_CLIENTE',@nota);
   FETCH NEXT FROM contactosraw INTO @id,@raw;
  END;
  CLOSE contactosraw; DEALLOCATE contactosraw;
  -- These reports are prepared before deleting any destination rows.
  CREATE TABLE #Resumen(Tabla sysname,FilasEsperadas bigint);
  INSERT #Resumen VALUES(N'VCT_CLIENTES',(SELECT COUNT_BIG(*) FROM #Origen)),(N'VCT_DOMICILIOS',(SELECT COUNT_BIG(*) FROM #Domicilios)),(N'VCT_TELEFONOS',(SELECT COUNT_BIG(*) FROM #Telefonos)),(N'VCT_EMAILS',(SELECT COUNT_BIG(*) FROM #Emails)),(N'VCT_CONTACTOS',(SELECT COUNT_BIG(*) FROM #Contactos));
  IF @Aplicar=0
  BEGIN
   SELECT N'VISTA PREVIA: NO SE BORRARON NI INSERTARON DATOS' AS Resultado;
   SELECT * FROM #Resumen; SELECT * FROM #Excepciones ORDER BY ID_CLIENTE,Tabla,Campo;
   SELECT ID_CLIENTE,CODAREA,NRO,PRINCIPAL,OBSERVACIONES FROM #Telefonos ORDER BY ID_CLIENTE,Orden;
   SELECT ID_CLIENTE,EMAIL,PRINCIPAL,OBSERVACIONES FROM #Emails ORDER BY ID_CLIENTE,Orden;
   SELECT * FROM #Contactos ORDER BY ID_CLIENTE;
   RETURN;
  END;
  DECLARE @Tablas TABLE(ObjectId int PRIMARY KEY,Nombre sysname);
  IF EXISTS(SELECT 1 FROM #Resumen WHERE OBJECT_ID(N'dbo.'+Tabla,N'U') IS NULL) THROW 52007,'Falta una tabla de destino.',1;
  INSERT @Tablas SELECT OBJECT_ID(N'dbo.'+Tabla,N'U'),Tabla FROM #Resumen;
  IF EXISTS(SELECT 1 FROM @Tablas t LEFT JOIN sys.identity_columns c ON c.object_id=t.ObjectId WHERE c.column_id IS NULL OR c.name<>N'ID' OR CONVERT(bigint,c.seed_value)<>1 OR CONVERT(bigint,c.increment_value)<>1)
   THROW 52008,'Destino debe mantener ID identity(1,1), segun el modelo suministrado.',1;
  -- Protect unrelated tables from being rebound to regenerated auxiliary IDs.
  DECLARE fkexterna CURSOR LOCAL FAST_FORWARD FOR
   SELECT f.parent_object_id,f.name,f.object_id FROM sys.foreign_keys f JOIN @Tablas t ON t.ObjectId=f.referenced_object_id
   WHERE t.Nombre<>N'VCT_CLIENTES' AND NOT EXISTS(SELECT 1 FROM @Tablas x WHERE x.ObjectId=f.parent_object_id);
  DECLARE @fk int,@condicion nvarchar(max);
  OPEN fkexterna; FETCH NEXT FROM fkexterna INTO @parent,@nombre,@fk;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SELECT @condicion=STUFF((SELECT N' AND '+QUOTENAME(COL_NAME(fkc.parent_object_id,fkc.parent_column_id))+N' IS NOT NULL' FROM sys.foreign_key_columns fkc WHERE fkc.constraint_object_id=@fk ORDER BY fkc.constraint_column_id FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,5,N'');
   SET @sql=N'SELECT @Hay=CASE WHEN EXISTS(SELECT 1 FROM '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N' WHERE '+@condicion+N') THEN 1 ELSE 0 END;';
   EXEC sys.sp_executesql @sql,N'@Hay bit OUTPUT',@Hay=@afectados OUTPUT;
   IF @afectados=1
   BEGIN
    SELECT OBJECT_SCHEMA_NAME(@parent) AS Esquema,OBJECT_NAME(@parent) AS TablaExterna,@nombre AS FK;
    THROW 52009,'Una tabla externa referencia IDs auxiliares que se regeneraran. Resolver su migracion conjunta antes de borrar.',1;
   END;
   FETCH NEXT FROM fkexterna INTO @parent,@nombre,@fk;
  END;
  CLOSE fkexterna; DEALLOCATE fkexterna;
  CREATE TABLE #Restricciones(ParentId int,Nombre sysname,Deshabilitada bit,NoConfiable bit);
  INSERT #Restricciones SELECT f.parent_object_id,f.name,f.is_disabled,f.is_not_trusted FROM sys.foreign_keys f WHERE EXISTS(SELECT 1 FROM @Tablas t WHERE t.ObjectId=f.parent_object_id OR t.ObjectId=f.referenced_object_id)
   UNION ALL SELECT c.parent_object_id,c.name,c.is_disabled,c.is_not_trusted FROM sys.check_constraints c JOIN @Tablas t ON t.ObjectId=c.parent_object_id;
  CREATE TABLE #Triggers(ParentId int,Nombre sysname);
  INSERT #Triggers SELECT tr.parent_id,tr.name FROM sys.triggers tr JOIN @Tablas t ON t.ObjectId=tr.parent_id WHERE tr.is_disabled=0;
  DECLARE restricciones CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #Restricciones WHERE Deshabilitada=0;
  OPEN restricciones; FETCH NEXT FROM restricciones INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N' NOCHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM restricciones INTO @parent,@nombre;
  END;
  CLOSE restricciones; DEALLOCATE restricciones;
  DECLARE triggers CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #Triggers;
  OPEN triggers; FETCH NEXT FROM triggers INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DISABLE TRIGGER '+QUOTENAME(@nombre)+N' ON '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N';'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM triggers INTO @parent,@nombre;
  END;
  CLOSE triggers; DEALLOCATE triggers;
  DELETE dbo.VCT_CONTACTOS WITH(TABLOCKX);
  DELETE dbo.VCT_CLIENTES WITH(TABLOCKX);
  DELETE dbo.VCT_DOMICILIOS WITH(TABLOCKX);
  DELETE dbo.VCT_TELEFONOS WITH(TABLOCKX);
  DELETE dbo.VCT_EMAILS WITH(TABLOCKX);
  -- Only customer IDs are inherited. Auxiliary IDs are newly assigned 1..N, deterministically.
  SET IDENTITY_INSERT dbo.VCT_CLIENTES ON; SET @IdentityActivo=N'VCT_CLIENTES';
  INSERT dbo.VCT_CLIENTES(ID,RAZON_SOCIAL,CUIT,ID_DOMICILIO,ID_TELEFONO,ID_EMAIL,ID_CONTACTO,CONDICION_IVA,TIPO,ESTADO,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
  SELECT o.ID,LEFT(ISNULL(CONVERT(varchar(max),o.Razon),''),300),LEFT(ISNULL(CONVERT(varchar(max),o.Cuit),''),50),d.ID,t.ID,e.ID,c.ID,LEFT(CONVERT(varchar(max),o.Iva),50),LEFT(CONVERT(varchar(max),o.Tipo),50),LEFT(CONVERT(varchar(max),o.Estado),50),
   CONVERT(varchar(max),CONCAT(CAST(ISNULL(o.ObservOrigen,N'') AS nvarchar(max)),NCHAR(13),NCHAR(10),N'[MIGRACION LK_CLIENTES] Respaldo completo de origen: ',o.RespaldoOrigen)),o.FechaAlta,LEFT(CONVERT(varchar(max),o.UsuarioAlta),100),o.FechaUpd,LEFT(CONVERT(varchar(max),o.UsuarioUpd),100)
  FROM #Origen o LEFT JOIN #Domicilios d ON d.ID_CLIENTE=o.ID LEFT JOIN #Telefonos t ON t.ID_CLIENTE=o.ID AND t.PRINCIPAL=@Principal LEFT JOIN #Emails e ON e.ID_CLIENTE=o.ID AND e.PRINCIPAL=@Principal LEFT JOIN #Contactos c ON c.ID_CLIENTE=o.ID;
  SET IDENTITY_INSERT dbo.VCT_CLIENTES OFF; SET @IdentityActivo=NULL;
  SET IDENTITY_INSERT dbo.VCT_DOMICILIOS ON; SET @IdentityActivo=N'VCT_DOMICILIOS';
  INSERT dbo.VCT_DOMICILIOS(ID,TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
  SELECT d.ID,'CLIENTE',d.ID_CLIENTE,d.CALLE,d.NRO,d.PISO,d.DEPTO,d.LOCALIDAD,d.PROVINCIA,@Principal,d.OBSERVACIONES,o.FechaAlta,LEFT(CONVERT(varchar(max),o.UsuarioAlta),100),o.FechaUpd,LEFT(CONVERT(varchar(max),o.UsuarioUpd),100) FROM #Domicilios d JOIN #Origen o ON o.ID=d.ID_CLIENTE;
  SET IDENTITY_INSERT dbo.VCT_DOMICILIOS OFF; SET @IdentityActivo=NULL;
  SET IDENTITY_INSERT dbo.VCT_TELEFONOS ON; SET @IdentityActivo=N'VCT_TELEFONOS';
  INSERT dbo.VCT_TELEFONOS(ID,TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
  SELECT t.ID,'CLIENTE',t.ID_CLIENTE,t.CODAREA,t.NRO,t.PRINCIPAL,t.OBSERVACIONES,o.FechaAlta,LEFT(CONVERT(varchar(max),o.UsuarioAlta),100),o.FechaUpd,LEFT(CONVERT(varchar(max),o.UsuarioUpd),100) FROM #Telefonos t JOIN #Origen o ON o.ID=t.ID_CLIENTE;
  SET IDENTITY_INSERT dbo.VCT_TELEFONOS OFF; SET @IdentityActivo=NULL;
  SET IDENTITY_INSERT dbo.VCT_EMAILS ON; SET @IdentityActivo=N'VCT_EMAILS';
  INSERT dbo.VCT_EMAILS(ID,TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
  SELECT e.ID,'CLIENTE',e.ID_CLIENTE,e.EMAIL,e.PRINCIPAL,e.OBSERVACIONES,o.FechaAlta,LEFT(CONVERT(varchar(max),o.UsuarioAlta),100),o.FechaUpd,LEFT(CONVERT(varchar(max),o.UsuarioUpd),100) FROM #Emails e JOIN #Origen o ON o.ID=e.ID_CLIENTE;
  SET IDENTITY_INSERT dbo.VCT_EMAILS OFF; SET @IdentityActivo=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONTACTOS ON; SET @IdentityActivo=N'VCT_CONTACTOS';
  INSERT dbo.VCT_CONTACTOS(ID,IDCLIENTE,APELLIDO,NOMBRES,CARGO,ID_DOMICILIO,ID_TELEFONO,ID_EMAIL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
  SELECT c.ID,c.ID_CLIENTE,c.APELLIDO,c.NOMBRES,c.CARGO,d.ID,t.ID,e.ID,c.OBSERVACIONES,o.FechaAlta,LEFT(CONVERT(varchar(max),o.UsuarioAlta),100),o.FechaUpd,LEFT(CONVERT(varchar(max),o.UsuarioUpd),100) FROM #Contactos c JOIN #Origen o ON o.ID=c.ID_CLIENTE LEFT JOIN #Domicilios d ON d.ID_CLIENTE=c.ID_CLIENTE LEFT JOIN #Telefonos t ON t.ID_CLIENTE=c.ID_CLIENTE AND t.PRINCIPAL=@Principal LEFT JOIN #Emails e ON e.ID_CLIENTE=c.ID_CLIENTE AND e.PRINCIPAL=@Principal;
  SET IDENTITY_INSERT dbo.VCT_CONTACTOS OFF; SET @IdentityActivo=NULL;
  IF EXISTS(SELECT ID FROM #Origen EXCEPT SELECT ID FROM dbo.VCT_CLIENTES) OR EXISTS(SELECT ID FROM dbo.VCT_CLIENTES EXCEPT SELECT ID FROM #Origen)
   THROW 52010,'Los IDs de cliente cargados no coinciden con los IDs originales.',1;
  DECLARE @conteo bigint,@esperado bigint,@ultimo int,@valor int;
  DECLARE validar CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla,FilasEsperadas FROM #Resumen;
  OPEN validar; FETCH NEXT FROM validar INTO @nombre,@esperado;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @tabla=N'dbo.'+QUOTENAME(@nombre);
   SET @sql=N'SELECT @N=COUNT_BIG(*),@M=MAX(ID) FROM '+@tabla;
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT,@M int OUTPUT',@N=@conteo OUTPUT,@M=@ultimo OUTPUT;
   IF @conteo<>@esperado THROW 52011,'Conteos de carga incorrectos: se revierte el bloque completo.',1;
   -- Empty never-used identity tables need seed=1; previously used empty tables need current=0.
   SET @valor=CASE WHEN @ultimo IS NOT NULL THEN @ultimo WHEN EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(@tabla) AND last_value IS NULL) THEN 1 ELSE 0 END;
   SET @sql=N'DBCC CHECKIDENT(N'''+REPLACE(@tabla,'''','''''')+N''',RESEED,'+CONVERT(nvarchar(20),@valor)+N') WITH NO_INFOMSGS;'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM validar INTO @nombre,@esperado;
  END;
  CLOSE validar; DEALLOCATE validar;
  -- Validate active constraints, then restore their previous trust state.
  DECLARE restaurar CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre,NoConfiable FROM #Restricciones WHERE Deshabilitada=0;
  OPEN restaurar; FETCH NEXT FROM restaurar INTO @parent,@nombre,@flags;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @tabla=QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent));
   SET @sql=N'ALTER TABLE '+@tabla+N' WITH CHECK CHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   IF @flags=1 BEGIN SET @sql=N'ALTER TABLE '+@tabla+N' NOCHECK CONSTRAINT '+QUOTENAME(@nombre)+N'; ALTER TABLE '+@tabla+N' CHECK CONSTRAINT '+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql; END;
   FETCH NEXT FROM restaurar INTO @parent,@nombre,@flags;
  END;
  CLOSE restaurar; DEALLOCATE restaurar;
  DECLARE resttrg CURSOR LOCAL FAST_FORWARD FOR SELECT ParentId,Nombre FROM #Triggers;
  OPEN resttrg; FETCH NEXT FROM resttrg INTO @parent,@nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'ENABLE TRIGGER '+QUOTENAME(@nombre)+N' ON '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent)); EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM resttrg INTO @parent,@nombre;
  END;
  CLOSE resttrg; DEALLOCATE resttrg;
  COMMIT TRANSACTION;
  SELECT N'MIGRACION CLIENTES CONFIRMADA' AS Resultado;
  SELECT r.Tabla,r.FilasEsperadas AS FilasCargadas,(SELECT COUNT_BIG(*) FROM #Excepciones e WHERE e.Tabla=r.Tabla) AS Excepciones FROM #Resumen r;
  SELECT * FROM #Excepciones ORDER BY ID_CLIENTE,Tabla,Campo;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  IF @IdentityActivo IS NOT NULL
  BEGIN TRY
   SET @sql=N'SET IDENTITY_INSERT dbo.'+QUOTENAME(@IdentityActivo)+N' OFF;'; EXEC sys.sp_executesql @sql;
  END TRY
  BEGIN CATCH
   PRINT N'No pudo limpiarse IDENTITY_INSERT. Cerrar esta conexion antes de reintentar.';
  END CATCH;
  THROW;
 END CATCH;
END;
