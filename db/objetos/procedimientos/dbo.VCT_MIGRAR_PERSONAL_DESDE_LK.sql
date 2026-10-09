 
CREATE   PROCEDURE dbo.VCT_MIGRAR_PERSONAL_DESDE_LK
 @Aplicar bit=0,
 @PermitirOrigenVacio bit=0,
 @Principal varchar(50)='1',
 @UsarUsuarioOrigenComoIdSeguridad bit=0,
 @VaciarProyectosYGestiones bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF;
 SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
 SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME()<>N'MuhlePROD' OR ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')),N'')<>N'WIN-83AM68966R4'
 THROW 53000,'Ejecutar solamente en MuhlePROD / WIN-83AM68966R4 (desarrollo).',1;
 
 IF @@TRANCOUNT<>0 THROW 53003,'Ejecutar sin transacciones previas.',1;
 IF @Principal IS NULL OR LTRIM(RTRIM(@Principal)) IN ('','0') THROW 53004,'Principal debe ser un valor informado distinto de 0.',1;
 DECLARE @run uniqueidentifier=NEWID(),@ahora datetime=GETDATE(),@lock int,
  @sql nvarchar(max),@tabla nvarchar(517),@nombre sysname,@parent int,@fk int,@identity sysname=NULL,
  @cond nvarchar(max),@hay bit,@trust bit,@ultimo int,@valor int,@n bigint,@esperado bigint;
 BEGIN TRY
  IF @Aplicar=1
  BEGIN
   BEGIN TRANSACTION;
   EXEC @lock=sys.sp_getapplock @Resource=N'VCT_MIG_MODELO_NUEVO',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0;
   IF @lock<0 THROW 53005,'Hay otra migracion en curso.',1;
  END;
  CREATE TABLE #Excepciones(Fuente sysname COLLATE DATABASE_DEFAULT,ID_ORIGEN int,Entidad varchar(30) COLLATE DATABASE_DEFAULT,ID_ENTIDAD int,Detalle nvarchar(max) COLLATE DATABASE_DEFAULT);
  SELECT ID_EMPLEADO AS ID,
   CONVERT(varchar(30),UPPER(LTRIM(RTRIM(PERFIL_EMP))) COLLATE Latin1_General_CI_AS) COLLATE DATABASE_DEFAULT Entidad,
   NOMBRE_EMPLEADO COLLATE DATABASE_DEFAULT Nombres,APELLIDO_EMPLEADO COLLATE DATABASE_DEFAULT Apellidos,TIPO_DOC_EMP COLLATE DATABASE_DEFAULT TipoDocumento,NRO_DOC_EMP COLLATE DATABASE_DEFAULT Documento,
   CUIT_EMP COLLATE DATABASE_DEFAULT Cuit,FORMACION_EMP COLLATE DATABASE_DEFAULT Formacion,MOVILIDAD_EMP COLLATE DATABASE_DEFAULT Movilidad,
   TRY_CAST(NULLIF(LTRIM(RTRIM(DIAS_MENSUALES)),'') AS int) Dias,
   CONVERT(varchar(2),CASE WHEN UPPER(LTRIM(RTRIM(EVENTUAL))) COLLATE Latin1_General_CI_AS IN ('SI','SÍ','1','TRUE') THEN 'SI'
    WHEN UPPER(LTRIM(RTRIM(EVENTUAL))) COLLATE Latin1_General_CI_AS IN ('NO','0','FALSE') THEN 'NO' END) Eventual,
   CONVERT(varchar(20),CASE WHEN UPPER(LTRIM(RTRIM(STATUS_EMP))) COLLATE Latin1_General_CI_AS IN ('1','ACTIVO','SI','SÍ') THEN 'ACTIVO' ELSE 'INACTIVO' END) Estado,
   CONVERT(bit,CASE WHEN UPPER(LTRIM(RTRIM(INGRESA_SISTEMA))) COLLATE Latin1_General_CI_AS IN ('1','SI','SÍ','TRUE') THEN 1 ELSE 0 END) SolicitaAcceso,
   USUARIO_EMP COLLATE DATABASE_DEFAULT UsuarioOrigen,INGRESA_SISTEMA COLLATE DATABASE_DEFAULT IngresaOrigen,
   CONVERT(bit,CASE WHEN @UsarUsuarioOrigenComoIdSeguridad=1 AND NULLIF(LTRIM(RTRIM(USUARIO_EMP)),'') IS NOT NULL
     AND UPPER(LTRIM(RTRIM(INGRESA_SISTEMA))) COLLATE Latin1_General_CI_AS IN ('1','SI','SÍ','TRUE') THEN 1 ELSE 0 END) Acceso,
   CONVERT(varchar(100),CASE WHEN @UsarUsuarioOrigenComoIdSeguridad=1 AND NULLIF(LTRIM(RTRIM(USUARIO_EMP)),'') IS NOT NULL
     AND UPPER(LTRIM(RTRIM(INGRESA_SISTEMA))) COLLATE Latin1_General_CI_AS IN ('1','SI','SÍ','TRUE') THEN LTRIM(RTRIM(USUARIO_EMP)) END) COLLATE DATABASE_DEFAULT UsuarioSeguridad,
   CALLE_EMP COLLATE DATABASE_DEFAULT Calle,NRO_CALLE_EMP COLLATE DATABASE_DEFAULT Numero,PISO_DEPTO_EMP COLLATE DATABASE_DEFAULT PisoDepto,LOCALIDAD_EMP COLLATE DATABASE_DEFAULT Localidad,PROVINCIA_EMP COLLATE DATABASE_DEFAULT Provincia,
   TEL1_EMP COLLATE DATABASE_DEFAULT Tel1,TEL2_EMP COLLATE DATABASE_DEFAULT Tel2,EMAIL_EMP COLLATE DATABASE_DEFAULT Email,
   FECHA_ALTA FechaAlta,USUARIO_ALTA COLLATE DATABASE_DEFAULT UsuarioAlta,FECHA_UPD FechaUpd,USUARIO_UPD COLLATE DATABASE_DEFAULT UsuarioUpd,
   CONVERT(varbinary(max),CV_EMP) CV,FECHA_CV_EMP FechaCV,CV_EMP_PKEY COLLATE DATABASE_DEFAULT CVPkey,
   CAST(N'' AS nvarchar(max)) Raw
  INTO #P FROM dbo.LK_EMPLEADOS WITH(HOLDLOCK)
  WHERE UPPER(LTRIM(RTRIM(PERFIL_EMP))) COLLATE Latin1_General_CI_AS IN ('EMPLEADO','CONSULTOR');
  IF NOT EXISTS(SELECT 1 FROM #P) AND @PermitirOrigenVacio=0 THROW 53006,'Origen sin empleados ni consultores. No se borra el destino.',1;
  IF EXISTS(SELECT 1 FROM #P WHERE ID IS NULL OR ID<=0) OR EXISTS(SELECT ID FROM #P GROUP BY ID HAVING COUNT(*)>1)
   THROW 53007,'IDs de persona invalidos o duplicados.',1;
  CREATE UNIQUE CLUSTERED INDEX IX_P ON #P(ID);
  UPDATE p SET Raw=CONCAT(CAST(N'LK_EMPLEADOS - valores originales: ' AS nvarchar(max)),
   N'ID=',p.ID,N'; PERFIL=',l.PERFIL_EMP,N'; NOMBRES=',l.NOMBRE_EMPLEADO,N'; APELLIDOS=',l.APELLIDO_EMPLEADO,
   N'; TIPO_DOC=',l.TIPO_DOC_EMP,N'; NRO_DOC=',l.NRO_DOC_EMP,N'; CUIT=',l.CUIT_EMP,
   N'; FORMACION=',l.FORMACION_EMP,N'; MOVILIDAD=',l.MOVILIDAD_EMP,N'; DIAS_MENSUALES=',l.DIAS_MENSUALES,
   N'; EVENTUAL=',l.EVENTUAL,N'; STATUS=',l.STATUS_EMP,N'; INGRESA_SISTEMA=',l.INGRESA_SISTEMA,N'; USUARIO=',l.USUARIO_EMP,
   N'; CALLE=',l.CALLE_EMP,N'; NUMERO=',l.NRO_CALLE_EMP,N'; PISO_DEPTO=',l.PISO_DEPTO_EMP,
   N'; LOCALIDAD=',l.LOCALIDAD_EMP,N'; PROVINCIA=',l.PROVINCIA_EMP,N'; TEL1=',l.TEL1_EMP,N'; TEL2=',l.TEL2_EMP,N'; EMAIL=',l.EMAIL_EMP)
  FROM #P p JOIN dbo.LK_EMPLEADOS l ON l.ID_EMPLEADO=p.ID;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,N'Acceso al sistema no habilitado: falta validar el identificador de seguridad. Usuario y solicitud originales conservados.'
   FROM #P WHERE SolicitaAcceso=1 AND Acceso=0;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',p.ID,p.Entidad,p.ID,CONCAT(N'Estado de origen no reconocido; INACTIVO. Original: ',l.STATUS_EMP)
   FROM #P p JOIN dbo.LK_EMPLEADOS l ON l.ID_EMPLEADO=p.ID
   WHERE ISNULL(UPPER(LTRIM(RTRIM(l.STATUS_EMP))) COLLATE Latin1_General_CI_AS,'') NOT IN ('0','1','ACTIVO','INACTIVO','SI','SÍ','NO');
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',p.ID,p.Entidad,p.ID,CONCAT(N'INGRESA_SISTEMA no reconocido; sin acceso. Original: ',l.INGRESA_SISTEMA)
   FROM #P p JOIN dbo.LK_EMPLEADOS l ON l.ID_EMPLEADO=p.ID
   WHERE ISNULL(UPPER(LTRIM(RTRIM(l.INGRESA_SISTEMA))) COLLATE Latin1_General_CI_AS,'') NOT IN ('0','1','SI','SÍ','NO','TRUE','FALSE');
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',p.ID,p.Entidad,p.ID,CONCAT(N'Dias mensuales invalidos; NULL. Original: ',l.DIAS_MENSUALES)
   FROM #P p JOIN dbo.LK_EMPLEADOS l ON l.ID_EMPLEADO=p.ID WHERE p.Entidad='CONSULTOR'
    AND NULLIF(LTRIM(RTRIM(l.DIAS_MENSUALES)),'') IS NOT NULL AND (p.Dias IS NULL OR p.Dias<0);
  UPDATE #P SET Dias=NULL WHERE Dias<0;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',p.ID,p.Entidad,p.ID,CONCAT(N'Eventual no reconocido; NULL. Original: ',l.EVENTUAL)
   FROM #P p JOIN dbo.LK_EMPLEADOS l ON l.ID_EMPLEADO=p.ID WHERE p.Entidad='CONSULTOR' AND p.Eventual IS NULL AND NULLIF(LTRIM(RTRIM(l.EVENTUAL)),'') IS NOT NULL;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,N'Valor excede longitud de destino; se recorta y se conserva completo en OBSERVACIONES.'
   FROM #P WHERE (Entidad='EMPLEADO' AND (DATALENGTH(Nombres)>150 OR DATALENGTH(Apellidos)>150 OR DATALENGTH(Cuit)>20))
    OR (Entidad='CONSULTOR' AND DATALENGTH(Cuit)>50);
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,N'FECHA_ALTA de empleado ausente; se usa fecha de esta ejecucion.' FROM #P WHERE Entidad='EMPLEADO' AND FechaAlta IS NULL;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,N'Campos obligatorios de nombre o documento vacios; se conserva el valor original.' FROM #P
   WHERE NULLIF(LTRIM(RTRIM(Nombres)),'') IS NULL OR NULLIF(LTRIM(RTRIM(Apellidos)),'') IS NULL OR NULLIF(LTRIM(RTRIM(TipoDocumento)),'') IS NULL OR NULLIF(LTRIM(RTRIM(Documento)),'') IS NULL;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID_EMPLEADO,LEFT(PERFIL_EMP,30),ID_EMPLEADO,CONCAT(N'Perfil no incluido en la migracion: ',PERFIL_EMP)
   FROM dbo.LK_EMPLEADOS WHERE ISNULL(UPPER(LTRIM(RTRIM(PERFIL_EMP))) COLLATE Latin1_General_CI_AS,'') NOT IN ('EMPLEADO','CONSULTOR');
  -- Missing CUIT is NULL; duplicates retain the lowest original ID.
  -- Raw was captured before normalization, so no original text is lost.
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,N'CUIT ausente o en blanco; se carga NULL.'
   FROM #P WHERE NULLIF(LTRIM(RTRIM(Cuit)),'') IS NULL;
  UPDATE #P SET Cuit=NULLIF(LEFT(LTRIM(RTRIM(Cuit)),CASE WHEN Entidad='EMPLEADO' THEN 20 ELSE 50 END),'');
  SELECT ID,Entidad,Cuit,ROW_NUMBER() OVER(PARTITION BY Entidad,Cuit ORDER BY ID) rn,
   MIN(ID) OVER(PARTITION BY Entidad,Cuit) ID_CONSERVADO INTO #CuitRepetidos FROM #P WHERE Cuit IS NOT NULL;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,
   CONCAT(N'CUIT duplicado: ',Cuit,N'. Se conserva en ID=',ID_CONSERVADO,N'; en esta persona se carga NULL. Valor original conservado en OBSERVACIONES.')
   FROM #CuitRepetidos WHERE rn>1;
  UPDATE p SET Cuit=NULL FROM #P p JOIN #CuitRepetidos d ON d.ID=p.ID WHERE d.rn>1;
 
  SELECT ID_APTITUD ID,CONVERT(varchar(400),ISNULL(NULLIF(LTRIM(RTRIM(DESC_APTITUD)),''),'[SIN DESCRIPCION LK '+CONVERT(varchar(20),ID_APTITUD)+']')) COLLATE DATABASE_DEFAULT Descripcion,
   CONVERT(varchar(20),CASE WHEN UPPER(LTRIM(RTRIM(STATUS_APTITUD))) COLLATE Latin1_General_CI_AS IN ('1','ACTIVO','SI','SÍ') THEN 'ACTIVO' ELSE 'INACTIVO' END) Estado,
   FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_APTITUDES: ' AS nvarchar(max)),N'ID=',ID_APTITUD,N'; DESC=',DESC_APTITUD,N'; STATUS=',STATUS_APTITUD)) OBSERVACIONES
  INTO #Normas FROM dbo.LK_APTITUDES WITH(HOLDLOCK);
  IF NOT EXISTS(SELECT 1 FROM #Normas) AND @PermitirOrigenVacio=0 THROW 53008,'LK_APTITUDES vacia: verificar recarga de origen.',1;
  IF EXISTS(SELECT 1 FROM #Normas WHERE ID IS NULL OR ID<=0) OR EXISTS(SELECT ID FROM #Normas GROUP BY ID HAVING COUNT(*)>1) THROW 53009,'IDs de normas invalidos.',1;
  INSERT #Excepciones SELECT N'LK_APTITUDES',l.ID_APTITUD,NULL,NULL,CONCAT(N'Descripcion vacia o estado no reconocido. DESC=',l.DESC_APTITUD,N'; STATUS=',l.STATUS_APTITUD)
   FROM dbo.LK_APTITUDES l WHERE NULLIF(LTRIM(RTRIM(l.DESC_APTITUD)),'') IS NULL
    OR ISNULL(UPPER(LTRIM(RTRIM(l.STATUS_APTITUD))) COLLATE Latin1_General_CI_AS,'') NOT IN ('0','1','ACTIVO','INACTIVO','SI','SÍ','NO');
  SELECT ID INTO #NormasDuplicadas FROM #Normas WHERE Descripcion IN (SELECT Descripcion FROM #Normas GROUP BY Descripcion HAVING COUNT(*)>1);
  INSERT #Excepciones SELECT N'LK_APTITUDES',n.ID,NULL,NULL,CONCAT(N'Descripcion duplicada; se agrega prefijo [LK ID]. Original: ',n.Descripcion) FROM #Normas n JOIN #NormasDuplicadas d ON d.ID=n.ID;
  UPDATE n SET Descripcion=LEFT(CONCAT('[LK ',n.ID,'] ',n.Descripcion),400) FROM #Normas n JOIN #NormasDuplicadas d ON d.ID=n.ID;
  IF EXISTS(SELECT Descripcion FROM #Normas GROUP BY Descripcion HAVING COUNT(*)>1) THROW 53010,'Colision de nombres de normas. Revisar vista previa.',1;
  IF EXISTS(SELECT 1 FROM #Normas s JOIN dbo.VCT_PRM_NORMAS d ON d.DESCRIPCION COLLATE DATABASE_DEFAULT=s.Descripcion COLLATE DATABASE_DEFAULT WHERE NOT EXISTS(SELECT 1 FROM #Normas n WHERE n.ID=d.ID))
   THROW 53011,'Una norma ajena al origen ocupa una descripcion requerida. Resolver sin cambiar los IDs.',1;
  CREATE TABLE #Servicios(ID int PRIMARY KEY,Codigo varchar(30) COLLATE DATABASE_DEFAULT,Descripcion varchar(100) COLLATE DATABASE_DEFAULT);
  INSERT #Servicios VALUES(1,'CONSULTORIA','Consultoria'),(2,'AUDITORIA','Auditoria'),(3,'CAPACITACION','Capacitacion');
  IF EXISTS(SELECT 1 FROM #Servicios s JOIN dbo.VCT_PRM_SERVICIOS d ON d.CODIGO COLLATE DATABASE_DEFAULT=s.Codigo COLLATE DATABASE_DEFAULT OR d.DESCRIPCION COLLATE DATABASE_DEFAULT=s.Descripcion COLLATE DATABASE_DEFAULT WHERE d.ID NOT IN (1,2,3))
   THROW 53012,'Un servicio fuera de los IDs 1,2,3 ocupa el codigo o descripcion requeridos.',1;
 
  SELECT p.ID,p.Entidad,ISNULL(p.Calle,'') CALLE,p.Numero NRO,
   CONVERT(varchar(50),CASE WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') AS int) IS NOT NULL
    OR UPPER(LTRIM(RTRIM(p.PisoDepto)))='PB' THEN LTRIM(RTRIM(p.PisoDepto)) END) PISO,
   CAST(NULL AS varchar(50)) DEPTO,p.Localidad LOCALIDAD,p.Provincia PROVINCIA,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_EMPLEADOS domicilio: ' AS nvarchar(max)),N'CALLE=',p.Calle,N'; NRO=',p.Numero,N'; PISO_DEPTO=',p.PisoDepto,
    N'; LOCALIDAD=',p.Localidad,N'; PROVINCIA=',p.Provincia,
    CASE WHEN NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') IS NOT NULL AND TRY_CAST(p.PisoDepto AS int) IS NULL AND UPPER(LTRIM(RTRIM(p.PisoDepto)))<>'PB'
     THEN N'; EXCEPCION: piso/departamento ambiguo; consultar original.' ELSE N'' END)) OBSERVACIONES
  INTO #Domicilios FROM #P p WHERE NULLIF(LTRIM(RTRIM(CONCAT(p.Calle,p.Numero,p.PisoDepto,p.Localidad,p.Provincia))),'') IS NOT NULL;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',p.ID,p.Entidad,p.ID,CONCAT(N'Domicilio incompleto o piso/departamento ambiguo. Original: ',d.OBSERVACIONES)
   FROM #Domicilios d JOIN #P p ON p.ID=d.ID WHERE NULLIF(LTRIM(RTRIM(p.Calle)),'') IS NULL
    OR (NULLIF(LTRIM(RTRIM(p.PisoDepto)),'') IS NOT NULL AND d.PISO IS NULL);
  CREATE TABLE #TelefonosRaw(ID int,Entidad varchar(30) COLLATE DATABASE_DEFAULT,Orden int,Campo sysname COLLATE DATABASE_DEFAULT,Original nvarchar(max) COLLATE DATABASE_DEFAULT);
  DECLARE @id int,@ent varchar(30),@raw nvarchar(max),@campo sysname,@orden int,@pos int,@parte nvarchar(max),@contador int;
  DECLARE telefonos CURSOR LOCAL FAST_FORWARD FOR SELECT p.ID,p.Entidad,v.Campo,v.Texto,v.Orden FROM #P p
   CROSS APPLY(VALUES(N'TEL1_EMP',p.Tel1,1),(N'TEL2_EMP',p.Tel2,2)) v(Campo,Texto,Orden) WHERE NULLIF(LTRIM(RTRIM(v.Texto)),N'') IS NOT NULL ORDER BY p.ID,v.Orden;
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
   CONVERT(varchar(max),CONCAT(CAST(N'LK_EMPLEADOS telefono: ' AS nvarchar(max)),r.Campo,N' original completo=',CASE WHEN r.Campo=N'TEL1_EMP' THEN p.Tel1 ELSE p.Tel2 END,
    N'; segmento=',r.Original,N'; ',t.Excepcion)) OBSERVACIONES
  INTO #Telefonos FROM #TelefonosRaw r JOIN #P p ON p.ID=r.ID CROSS APPLY dbo.VCT_MIG_INTERPRETAR_TELEFONO(r.Original) t;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,CONCAT(N'Telefono: ',OBSERVACIONES) FROM #Telefonos WHERE Excepcion IS NOT NULL;
  SELECT p.ID,p.Entidad,CONVERT(varchar(100),e.EMAIL) EMAIL,e.Excepcion,
   CONVERT(varchar(50),CASE WHEN ROW_NUMBER() OVER(PARTITION BY p.ID ORDER BY CASE WHEN e.EMAIL<>N'' THEN 0 ELSE 1 END,e.Orden)=1 THEN @Principal ELSE '0' END) PRINCIPAL,
   CONVERT(varchar(max),CONCAT(CAST(N'LK_EMPLEADOS EMAIL_EMP original: ' AS nvarchar(max)),p.Email,N'; ',e.Excepcion)) OBSERVACIONES
  INTO #Emails FROM #P p CROSS APPLY dbo.VCT_MIG_EXTRAER_EMAILS(p.Email) e;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS',ID,Entidad,ID,CONCAT(N'Email: ',OBSERVACIONES) FROM #Emails WHERE Excepcion IS NOT NULL;
 
  SELECT d.ID_EMPLE_DIAS ID,d.ID_EMPLEADO ID_CONSULTOR,d.MES,d.ANO,d.DIAS,TRY_CAST(CONVERT(bigint,d.ANO)*100+d.MES AS int) PERIODO,
   d.FECHA_ALTA,d.USUARIO_ALTA,d.FECHA_UPD,d.USUARIO_UPD,
   CONCAT(CAST(N'LK_EMPLEADOS_DIAS: ' AS nvarchar(max)),N'ID=',d.ID_EMPLE_DIAS,N'; ID_EMPLEADO=',d.ID_EMPLEADO,N'; MES=',d.MES,N'; ANO=',d.ANO,N'; DIAS=',d.DIAS,
    N'; FECHA_ALTA=',CONVERT(nvarchar(30),d.FECHA_ALTA,121),N'; USUARIO_ALTA=',d.USUARIO_ALTA,
    N'; FECHA_UPD=',CONVERT(nvarchar(30),d.FECHA_UPD,121),N'; USUARIO_UPD=',d.USUARIO_UPD) COLLATE DATABASE_DEFAULT Raw,
   p.Entidad
  INTO #D0 FROM dbo.LK_EMPLEADOS_DIAS d WITH(HOLDLOCK) LEFT JOIN #P p ON p.ID=d.ID_EMPLEADO;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_DIAS',ID,Entidad,ID_CONSULTOR,CONCAT(N'No corresponde a un consultor del origen; no se inserta en tablas de consultores. ',Raw)
   FROM #D0 WHERE ISNULL(Entidad,'')<>'CONSULTOR';
 
  SELECT d.ID_EMPLE_APTITUD ID,d.ID_EMPLEADO ID_CONSULTOR,d.ID_APTITUD,d.ID_TIPO,d.CALIFICACION COLLATE DATABASE_DEFAULT AS CALIFICACION,d.OBSERVACION COLLATE DATABASE_DEFAULT AS OBSERVACION,
   d.FECHA_ALTA,d.USUARIO_ALTA,d.FECHA_UPD,d.USUARIO_UPD,
   CONCAT(CAST(N'LK_EMPLEADOS_APTITUD: ' AS nvarchar(max)),N'ID=',d.ID_EMPLE_APTITUD,N'; ID_EMPLEADO=',d.ID_EMPLEADO,N'; ID_APTITUD=',d.ID_APTITUD,N'; ID_TIPO=',d.ID_TIPO,N'; CALIFICACION=',d.CALIFICACION,N'; OBSERVACION=',d.OBSERVACION,
    N'; FECHA_ALTA=',CONVERT(nvarchar(30),d.FECHA_ALTA,121),N'; USUARIO_ALTA=',d.USUARIO_ALTA,
    N'; FECHA_UPD=',CONVERT(nvarchar(30),d.FECHA_UPD,121),N'; USUARIO_UPD=',d.USUARIO_UPD) COLLATE DATABASE_DEFAULT Raw,
   p.Entidad
  INTO #A0 FROM dbo.LK_EMPLEADOS_APTITUD d WITH(HOLDLOCK) LEFT JOIN #P p ON p.ID=d.ID_EMPLEADO;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_APTITUD',ID,Entidad,ID_CONSULTOR,CONCAT(N'No corresponde a un consultor del origen; no se inserta en tablas de consultores. ',Raw)
   FROM #A0 WHERE ISNULL(Entidad,'')<>'CONSULTOR';
 
  SELECT d.ID_EMPLE_TIPO ID,d.ID_EMPLEADO ID_CONSULTOR,d.ID_TIPO,
   d.FECHA_ALTA,d.USUARIO_ALTA,d.FECHA_UPD,d.USUARIO_UPD,
   CONCAT(CAST(N'LK_EMPLEADOS_TIPO: ' AS nvarchar(max)),N'ID=',d.ID_EMPLE_TIPO,N'; ID_EMPLEADO=',d.ID_EMPLEADO,N'; ID_TIPO=',d.ID_TIPO,
    N'; FECHA_ALTA=',CONVERT(nvarchar(30),d.FECHA_ALTA,121),N'; USUARIO_ALTA=',d.USUARIO_ALTA,
    N'; FECHA_UPD=',CONVERT(nvarchar(30),d.FECHA_UPD,121),N'; USUARIO_UPD=',d.USUARIO_UPD) COLLATE DATABASE_DEFAULT Raw,
   p.Entidad
  INTO #T0 FROM dbo.LK_EMPLEADOS_TIPO d WITH(HOLDLOCK) LEFT JOIN #P p ON p.ID=d.ID_EMPLEADO;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_TIPO',ID,Entidad,ID_CONSULTOR,CONCAT(N'No corresponde a un consultor del origen; no se inserta en tablas de consultores. ',Raw)
   FROM #T0 WHERE ISNULL(Entidad,'')<>'CONSULTOR';
 
  SELECT d.ID_EMPLE_OBSERV ID,d.ID_EMPLEADO ID_CONSULTOR,d.MES,d.ANO,TRY_CAST(CONVERT(bigint,d.ANO)*100+d.MES AS int) PERIODO,d.OBSERVACION COLLATE DATABASE_DEFAULT AS OBSERVACION,
   d.FECHA_ALTA,d.USUARIO_ALTA,d.FECHA_UPD,d.USUARIO_UPD,
   CONCAT(CAST(N'LK_EMPLEADOS_OBSERV: ' AS nvarchar(max)),N'ID=',d.ID_EMPLE_OBSERV,N'; ID_EMPLEADO=',d.ID_EMPLEADO,N'; MES=',d.MES,N'; ANO=',d.ANO,N'; OBSERVACION=',d.OBSERVACION,
    N'; FECHA_ALTA=',CONVERT(nvarchar(30),d.FECHA_ALTA,121),N'; USUARIO_ALTA=',d.USUARIO_ALTA,
    N'; FECHA_UPD=',CONVERT(nvarchar(30),d.FECHA_UPD,121),N'; USUARIO_UPD=',d.USUARIO_UPD) COLLATE DATABASE_DEFAULT Raw,
   p.Entidad
  INTO #O0 FROM dbo.LK_EMPLEADOS_OBSERV d WITH(HOLDLOCK) LEFT JOIN #P p ON p.ID=d.ID_EMPLEADO;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_OBSERV',ID,Entidad,ID_CONSULTOR,CONCAT(N'No corresponde a un consultor del origen; no se inserta en tablas de consultores. ',Raw)
   FROM #O0 WHERE ISNULL(Entidad,'')<>'CONSULTOR';
 
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_DIAS',ID,Entidad,ID_CONSULTOR,CONCAT(N'Periodo invalido; registro conservado en excepciones. ',Raw)
   FROM #D0 WHERE Entidad='CONSULTOR' AND (MES IS NULL OR MES NOT BETWEEN 1 AND 12 OR ANO IS NULL OR ANO NOT BETWEEN 1900 AND 2200);
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_DIAS',ID,Entidad,ID_CONSULTOR,CONCAT(N'Dias fuera de 0..31; se carga NULL. ',Raw)
   FROM #D0 WHERE Entidad='CONSULTOR' AND (DIAS<0 OR DIAS>31);
  SELECT *,ROW_NUMBER() OVER(PARTITION BY ID_CONSULTOR,PERIODO ORDER BY ID) rn INTO #D1 FROM #D0
   WHERE Entidad='CONSULTOR' AND MES BETWEEN 1 AND 12 AND ANO BETWEEN 1900 AND 2200;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_DIAS',ID,Entidad,ID_CONSULTOR,CONCAT(N'Periodo duplicado; se conserva en destino el menor ID de origen. ',Raw) FROM #D1 WHERE rn>1;
  SELECT ID,ID_CONSULTOR,PERIODO,CASE WHEN DIAS BETWEEN 0 AND 31 THEN DIAS END DIAS_MENSUALES,
   FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,CONVERT(varchar(max),Raw) OBSERVACIONES INTO #Dias FROM #D1 WHERE rn=1;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_APTITUD',a.ID,a.Entidad,a.ID_CONSULTOR,CONCAT(N'Norma inexistente en LK_APTITUDES o servicio fuera de 1,2,3; registro conservado en excepciones. ',a.Raw)
   FROM #A0 a WHERE a.Entidad='CONSULTOR' AND (NOT EXISTS(SELECT 1 FROM #Normas n WHERE n.ID=a.ID_APTITUD) OR a.ID_TIPO IS NULL OR a.ID_TIPO NOT IN (1,2,3));
  SELECT a.*,ROW_NUMBER() OVER(PARTITION BY ID_CONSULTOR,ID_APTITUD,ID_TIPO ORDER BY a.ID) rn INTO #A1
   FROM #A0 a JOIN #Normas n ON n.ID=a.ID_APTITUD WHERE a.Entidad='CONSULTOR' AND a.ID_TIPO IN (1,2,3);
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_APTITUD',ID,Entidad,ID_CONSULTOR,CONCAT(N'Asignacion de norma/servicio duplicada; se conserva en destino el menor ID de origen. ',Raw) FROM #A1 WHERE rn>1;
  SELECT ID,ID_CONSULTOR,ID_APTITUD ID_NORMA,ID_TIPO ID_SERVICIO,CALIFICACION,
   FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,CONVERT(varchar(max),CONCAT(CAST(OBSERVACION AS nvarchar(max)),NCHAR(13),NCHAR(10),Raw)) OBSERVACIONES INTO #Aptitudes FROM #A1 WHERE rn=1;
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_TIPO',ID,Entidad,ID_CONSULTOR,CONCAT(N'Servicio fuera de 1,2,3; registro conservado en excepciones. ',Raw)
   FROM #T0 WHERE Entidad='CONSULTOR' AND (ID_TIPO IS NULL OR ID_TIPO NOT IN (1,2,3));
  SELECT ID,ID_CONSULTOR,ID_TIPO ID_SERVICIO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,CONVERT(varchar(max),Raw) OBSERVACIONES
   INTO #Tipos FROM #T0 WHERE Entidad='CONSULTOR' AND ID_TIPO IN (1,2,3);
  INSERT #Excepciones SELECT N'LK_EMPLEADOS_OBSERV',ID,Entidad,ID_CONSULTOR,CONCAT(N'Periodo de observacion invalido; PERIODO=NULL, se conservan MES y ANO originales. ',Raw)
   FROM #O0 WHERE Entidad='CONSULTOR' AND (MES IS NULL OR MES NOT BETWEEN 1 AND 12 OR ANO IS NULL OR ANO NOT BETWEEN 1900 AND 2200);
  SELECT ID,ID_CONSULTOR,MES,ANO,CASE WHEN MES BETWEEN 1 AND 12 AND ANO BETWEEN 1900 AND 2200 THEN PERIODO END PERIODO,
   FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,CONVERT(varchar(max),CONCAT(CAST(OBSERVACION AS nvarchar(max)),NCHAR(13),NCHAR(10),Raw)) OBSERVACIONES
  INTO #Observaciones FROM #O0 WHERE Entidad='CONSULTOR';
  -- Include issues in their surviving destination rows as well as in the run log.
  UPDATE p SET Raw=CONCAT(p.Raw,NCHAR(13),NCHAR(10),x.Notas)
   FROM #P p CROSS APPLY(SELECT (SELECT NCHAR(13)+NCHAR(10)+N'EXCEPCION: '+e.Detalle FROM #Excepciones e
    WHERE e.ID_ENTIDAD=p.ID ORDER BY e.Fuente,e.ID_ORIGEN FOR XML PATH(''),TYPE).value('.','nvarchar(max)') Notas) x;
  UPDATE n SET OBSERVACIONES=CONVERT(varchar(max),CONCAT(n.OBSERVACIONES,NCHAR(13),NCHAR(10),x.Notas))
   FROM #Normas n CROSS APPLY(SELECT (SELECT NCHAR(13)+NCHAR(10)+N'EXCEPCION: '+e.Detalle FROM #Excepciones e
    WHERE e.Fuente=N'LK_APTITUDES' AND e.ID_ORIGEN=n.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)') Notas) x;
  UPDATE d SET OBSERVACIONES=CONVERT(varchar(max),CONCAT(d.OBSERVACIONES,NCHAR(13),NCHAR(10),x.Notas))
   FROM #Dias d CROSS APPLY(SELECT (SELECT NCHAR(13)+NCHAR(10)+N'EXCEPCION: '+e.Detalle FROM #Excepciones e JOIN #D0 s ON s.ID=e.ID_ORIGEN
    WHERE e.Fuente=N'LK_EMPLEADOS_DIAS' AND s.ID_CONSULTOR=d.ID_CONSULTOR AND s.PERIODO=d.PERIODO FOR XML PATH(''),TYPE).value('.','nvarchar(max)') Notas) x;
  UPDATE a SET OBSERVACIONES=CONVERT(varchar(max),CONCAT(a.OBSERVACIONES,NCHAR(13),NCHAR(10),x.Notas))
   FROM #Aptitudes a CROSS APPLY(SELECT (SELECT NCHAR(13)+NCHAR(10)+N'EXCEPCION: '+e.Detalle FROM #Excepciones e JOIN #A0 s ON s.ID=e.ID_ORIGEN
    WHERE e.Fuente=N'LK_EMPLEADOS_APTITUD' AND s.ID_CONSULTOR=a.ID_CONSULTOR AND s.ID_APTITUD=a.ID_NORMA AND s.ID_TIPO=a.ID_SERVICIO FOR XML PATH(''),TYPE).value('.','nvarchar(max)') Notas) x;
 
  -- Explicitly authorized reset of project/management data for their next migration.
  CREATE TABLE #Limpiar(ObjectId int PRIMARY KEY,Nombre sysname COLLATE DATABASE_DEFAULT,FilasAntes bigint);
  IF @VaciarProyectosYGestiones=1
   INSERT #Limpiar(ObjectId,Nombre)
    SELECT t.object_id,t.name FROM sys.tables t WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.is_ms_shipped=0
     AND (t.name=N'VCT_PROYECTOS' OR t.name LIKE N'VCT[_]PROYECTOS[_]%'
      OR t.name=N'VCT_GESTIONES' OR t.name LIKE N'VCT[_]GESTIONES[_]%');
  DECLARE contarlimpieza CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM #Limpiar ORDER BY ObjectId;
  OPEN contarlimpieza; FETCH NEXT FROM contarlimpieza INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+N';';
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   UPDATE #Limpiar SET FilasAntes=@n WHERE Nombre=@nombre;
   FETCH NEXT FROM contarlimpieza INTO @nombre;
  END;
  CLOSE contarlimpieza; DEALLOCATE contarlimpieza;
  CREATE TABLE #Resumen(Tabla sysname COLLATE DATABASE_DEFAULT PRIMARY KEY,Esperadas bigint);
  INSERT #Resumen VALUES
   (N'VCT_EMPLEADOS',(SELECT COUNT_BIG(*) FROM #P WHERE Entidad='EMPLEADO')),
   (N'VCT_CONSULTORES',(SELECT COUNT_BIG(*) FROM #P WHERE Entidad='CONSULTOR')),
   (N'VCT_CONSULTORES_HISTORICO_DIAS',(SELECT COUNT_BIG(*) FROM #Dias)),
   (N'VCT_CONSULTORES_NORMAS',(SELECT COUNT_BIG(*) FROM #Aptitudes)),
   (N'VCT_CONSULTORES_OBSERVACIONES',(SELECT COUNT_BIG(*) FROM #Observaciones)),
   (N'VCT_CONSULTORES_SERVICIOS',(SELECT COUNT_BIG(*) FROM #Tipos)),
   (N'VCT_DOMICILIOS',(SELECT COUNT_BIG(*) FROM #Domicilios)),
   (N'VCT_TELEFONOS',(SELECT COUNT_BIG(*) FROM #Telefonos)),
   (N'VCT_EMAILS',(SELECT COUNT_BIG(*) FROM #Emails));
  IF @Aplicar=0
  BEGIN
   SELECT N'VISTA PREVIA: NO SE MODIFICARON DATOS' Resultado;
   SELECT * FROM #Resumen ORDER BY Tabla;
   SELECT Nombre TablaQueSeVaciara,FilasAntes FilasABorrar FROM #Limpiar ORDER BY Nombre;
   SELECT * FROM #Normas ORDER BY ID;
   SELECT ID,Entidad,Nombres,Apellidos,Estado,Dias,Eventual,Acceso,UsuarioSeguridad,Raw OBSERVACIONES FROM #P ORDER BY Entidad,ID;
   SELECT * FROM #Dias ORDER BY ID_CONSULTOR,PERIODO;
   SELECT * FROM #Excepciones ORDER BY Fuente,ID_ORIGEN;
   RETURN;
  END;
  DECLARE @Tablas TABLE(ObjectId int PRIMARY KEY,Nombre sysname);
  INSERT @Tablas SELECT OBJECT_ID(N'dbo.'+Tabla),Tabla FROM #Resumen;
  INSERT @Tablas VALUES(OBJECT_ID(N'dbo.VCT_PRM_NORMAS'),N'VCT_PRM_NORMAS'),(OBJECT_ID(N'dbo.VCT_PRM_SERVICIOS'),N'VCT_PRM_SERVICIOS'),
   (OBJECT_ID(N'dbo.VCT_PERSONAS_CV'),N'VCT_PERSONAS_CV');
  INSERT @Tablas SELECT ObjectId,Nombre FROM #Limpiar;
  IF EXISTS(SELECT 1 FROM @Tablas t LEFT JOIN sys.identity_columns c ON c.object_id=t.ObjectId WHERE t.Nombre<>N'VCT_PERSONAS_CV'
    AND NOT EXISTS(SELECT 1 FROM #Limpiar l WHERE l.ObjectId=t.ObjectId)
    AND (c.column_id IS NULL OR c.name<>N'ID' OR CONVERT(bigint,c.seed_value)<>1 OR CONVERT(bigint,c.increment_value)<>1))
   THROW 53013,'El modelo destino debe mantener ID identity(1,1).',1;
  -- Serialize table writers while checking dependencies and replacing data.
  DECLARE bloquear CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM @Tablas ORDER BY ObjectId;
  OPEN bloquear; FETCH NEXT FROM bloquear INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+N' WITH(TABLOCKX,HOLDLOCK);';
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   FETCH NEXT FROM bloquear INTO @nombre;
  END;
  CLOSE bloquear; DEALLOCATE bloquear;
  -- Only block references to auxiliary rows of EMPLEADO/CONSULTOR, not CLIENTE.
  DECLARE dependencias CURSOR LOCAL FAST_FORWARD FOR SELECT f.parent_object_id,f.name,f.object_id,t.Nombre
   FROM sys.foreign_keys f JOIN @Tablas t ON t.ObjectId=f.referenced_object_id
   WHERE t.Nombre IN (N'VCT_DOMICILIOS',N'VCT_TELEFONOS',N'VCT_EMAILS')
    AND NOT EXISTS(SELECT 1 FROM #Limpiar l WHERE l.ObjectId=f.parent_object_id);
  OPEN dependencias; FETCH NEXT FROM dependencias INTO @parent,@nombre,@fk,@tabla;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SELECT @cond=STUFF((SELECT N' AND p.'+QUOTENAME(COL_NAME(c.parent_object_id,c.parent_column_id))+N'=a.'+QUOTENAME(COL_NAME(c.referenced_object_id,c.referenced_column_id))
    FROM sys.foreign_key_columns c WHERE c.constraint_object_id=@fk ORDER BY c.constraint_column_id FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,5,N'');
   SET @sql=N'SELECT @Hay=CASE WHEN EXISTS(SELECT 1 FROM '+QUOTENAME(OBJECT_SCHEMA_NAME(@parent))+N'.'+QUOTENAME(OBJECT_NAME(@parent))+N' p JOIN dbo.'+QUOTENAME(@tabla)+N' a ON '+@cond+N' WHERE a.TIPO_ENTIDAD IN (''EMPLEADO'',''CONSULTOR'')) THEN 1 ELSE 0 END;';
   EXEC sys.sp_executesql @sql,N'@Hay bit OUTPUT',@Hay=@hay OUTPUT;
   IF @hay=1
   BEGIN
    SELECT OBJECT_SCHEMA_NAME(@parent) Esquema,OBJECT_NAME(@parent) TablaDependiente,@nombre FK;
    THROW 53014,'Hay referencias a IDs auxiliares que se regeneran. Resolver la dependencia antes de migrar.',1;
   END;
   FETCH NEXT FROM dependencias INTO @parent,@nombre,@fk,@tabla;
  END;
  CLOSE dependencias; DEALLOCATE dependencias;
  -- Actual CUIT indexes were not included in the supplied table scripts.
  CREATE TABLE #IndicesCuit(ObjectId int,IndexId int,Tabla sysname COLLATE DATABASE_DEFAULT,Nombre sysname COLLATE DATABASE_DEFAULT,Descendente bit,Incluidas nvarchar(max) COLLATE DATABASE_DEFAULT,Filtro nvarchar(max) COLLATE DATABASE_DEFAULT,Grupo sysname COLLATE DATABASE_DEFAULT);
  INSERT #IndicesCuit
   SELECT i.object_id,i.index_id,OBJECT_NAME(i.object_id),i.name,k.is_descending_key,
    STUFF((SELECT N','+QUOTENAME(COL_NAME(c.object_id,c.column_id)) FROM sys.index_columns c
     WHERE c.object_id=i.object_id AND c.index_id=i.index_id AND c.is_included_column=1 ORDER BY c.index_column_id FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,N''),
    i.filter_definition,ds.name
   FROM sys.indexes i JOIN sys.index_columns k ON k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal=1
   JOIN sys.data_spaces ds ON ds.data_space_id=i.data_space_id
   WHERE i.object_id IN (OBJECT_ID(N'dbo.VCT_EMPLEADOS'),OBJECT_ID(N'dbo.VCT_CONSULTORES'))
    AND i.is_unique=1 AND i.is_unique_constraint=0 AND i.is_primary_key=0 AND i.type=2 AND i.is_disabled=0
    AND COL_NAME(k.object_id,k.column_id)=N'CUIT' AND ds.type='FG'
    AND (i.has_filter=0 OR REPLACE(REPLACE(REPLACE(UPPER(i.filter_definition),N'[',N''),N']',N''),N' ',N'') NOT LIKE N'%CUITISNOTNULL%')
    AND NOT EXISTS(SELECT 1 FROM sys.index_columns c WHERE c.object_id=i.object_id AND c.index_id=i.index_id AND c.key_ordinal>1);
  IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #IndicesCuit i ON i.ObjectId=f.referenced_object_id AND i.IndexId=f.key_index_id)
   THROW 53019,'Una FK referencia el CUIT unico: requiere adaptar esa relacion antes de permitir CUIT ausentes.',1;
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
  -- Clear every authorized project/management table with FK temporarily disabled.
  DECLARE limpiardependencias CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM #Limpiar ORDER BY ObjectId;
  OPEN limpiardependencias; FETCH NEXT FROM limpiardependencias INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DELETE FROM dbo.'+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM limpiardependencias INTO @nombre;
  END;
  CLOSE limpiardependencias; DEALLOCATE limpiardependencias;
  DELETE dbo.VCT_CONSULTORES_NORMAS;
  DELETE dbo.VCT_CONSULTORES_HISTORICO_DIAS;
  DELETE dbo.VCT_CONSULTORES_OBSERVACIONES;
  DELETE dbo.VCT_CONSULTORES_SERVICIOS;
  DELETE dbo.VCT_EMPLEADOS;
  DELETE dbo.VCT_CONSULTORES;
  DELETE dbo.VCT_DOMICILIOS WHERE TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR');
  DELETE dbo.VCT_TELEFONOS WHERE TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR');
  DELETE dbo.VCT_EMAILS WHERE TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR');
  DELETE dbo.VCT_PERSONAS_CV WHERE TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR');
 
  -- Filter unique CUIT indexes so NULL/blank do not identify a person.
  -- Tables are empty here and both schema and data changes share the transaction.
  DECLARE @idxTabla sysname,@idxNombre sysname,@idxDesc bit,@idxInclude nvarchar(max),@idxFiltro nvarchar(max),@idxGrupo sysname;
  DECLARE indicescuit CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla,Nombre,Descendente,Incluidas,Filtro,Grupo FROM #IndicesCuit;
  OPEN indicescuit; FETCH NEXT FROM indicescuit INTO @idxTabla,@idxNombre,@idxDesc,@idxInclude,@idxFiltro,@idxGrupo;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DROP INDEX '+QUOTENAME(@idxNombre)+N' ON dbo.'+QUOTENAME(@idxTabla)+N'; CREATE UNIQUE NONCLUSTERED INDEX '+QUOTENAME(@idxNombre)
    +N' ON dbo.'+QUOTENAME(@idxTabla)+N'([CUIT]'+CASE WHEN @idxDesc=1 THEN N' DESC' ELSE N' ASC' END+N')'
    +CASE WHEN NULLIF(@idxInclude,N'') IS NOT NULL THEN N' INCLUDE ('+@idxInclude+N')' ELSE N'' END
    +N' WHERE [CUIT] IS NOT NULL AND [CUIT] <> '+NCHAR(39)+NCHAR(39)
    +CASE WHEN NULLIF(@idxFiltro,N'') IS NOT NULL THEN N' AND ('+@idxFiltro+N')' ELSE N'' END+N' ON '+QUOTENAME(@idxGrupo)+N';';
   EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM indicescuit INTO @idxTabla,@idxNombre,@idxDesc,@idxInclude,@idxFiltro,@idxGrupo;
  END;
  CLOSE indicescuit; DEALLOCATE indicescuit;
  -- Upsert catalogs: preserve records outside this source and their references.
  DECLARE @marca varchar(36)=CONVERT(varchar(36),@run);
  UPDATE d SET DESCRIPCION='__MIG_'+@marca+'_'+CONVERT(varchar(20),d.ID) FROM dbo.VCT_PRM_NORMAS d JOIN #Normas s ON s.ID=d.ID;
  UPDATE d SET DESCRIPCION=s.Descripcion,ESTADO=s.Estado,FECHA_ALTA=s.FECHA_ALTA,USUARIO_ALTA=s.USUARIO_ALTA,
   FECHA_UPD=s.FECHA_UPD,USUARIO_UPD=s.USUARIO_UPD,OBSERVACIONES=s.OBSERVACIONES FROM dbo.VCT_PRM_NORMAS d JOIN #Normas s ON s.ID=d.ID;
  SET IDENTITY_INSERT dbo.VCT_PRM_NORMAS ON; SET @identity=N'VCT_PRM_NORMAS';
  INSERT dbo.VCT_PRM_NORMAS(ID,DESCRIPCION,ESTADO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES)
   SELECT s.ID,s.Descripcion,s.Estado,s.FECHA_ALTA,s.USUARIO_ALTA,s.FECHA_UPD,s.USUARIO_UPD,s.OBSERVACIONES FROM #Normas s WHERE NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_NORMAS d WHERE d.ID=s.ID);
  SET IDENTITY_INSERT dbo.VCT_PRM_NORMAS OFF; SET @identity=NULL;
  UPDATE dbo.VCT_PRM_SERVICIOS SET CODIGO='__MIG_'+LEFT(@marca,18)+'_'+CONVERT(varchar(1),ID),DESCRIPCION='__MIG_'+@marca+'_'+CONVERT(varchar(1),ID) WHERE ID IN (1,2,3);
  UPDATE d SET CODIGO=s.Codigo,DESCRIPCION=s.Descripcion,ESTADO='ACTIVO',FECHA_UPD=@ahora,
   OBSERVACIONES=CAST(N'Servicios de migracion: 1 Consultoria, 2 Auditoria, 3 Capacitacion.' AS varchar(max)) FROM dbo.VCT_PRM_SERVICIOS d JOIN #Servicios s ON s.ID=d.ID;
  SET IDENTITY_INSERT dbo.VCT_PRM_SERVICIOS ON; SET @identity=N'VCT_PRM_SERVICIOS';
  INSERT dbo.VCT_PRM_SERVICIOS(ID,CODIGO,DESCRIPCION,ESTADO,FECHA_ALTA,USUARIO_ALTA,OBSERVACIONES)
   SELECT s.ID,s.Codigo,s.Descripcion,'ACTIVO',@ahora,SUSER_SNAME(),'Servicios fijos de migracion.' FROM #Servicios s WHERE NOT EXISTS(SELECT 1 FROM dbo.VCT_PRM_SERVICIOS d WHERE d.ID=s.ID);
  SET IDENTITY_INSERT dbo.VCT_PRM_SERVICIOS OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_EMPLEADOS ON; SET @identity=N'VCT_EMPLEADOS';
  INSERT dbo.VCT_EMPLEADOS(ID,NOMBRES,APELLIDOS,TIPO_DOCUMENTO,NRO_DOCUMENTO,CUIT,FORMACION,MOVILIDAD,INGRESA_SISTEMA,ID_USUARIO_SEGURIDAD,ESTADO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES,USUARIO_ORIGEN,INGRESA_SISTEMA_ORIGEN)
   SELECT ID,LEFT(ISNULL(Nombres,''),150),LEFT(ISNULL(Apellidos,''),150),ISNULL(TipoDocumento,''),ISNULL(Documento,''),LEFT(Cuit,20),Formacion,Movilidad,Acceso,UsuarioSeguridad,Estado,ISNULL(FechaAlta,@ahora),UsuarioAlta,FechaUpd,UsuarioUpd,CONVERT(varchar(max),Raw),UsuarioOrigen,IngresaOrigen FROM #P WHERE Entidad='EMPLEADO';
  SET IDENTITY_INSERT dbo.VCT_EMPLEADOS OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES ON; SET @identity=N'VCT_CONSULTORES';
  INSERT dbo.VCT_CONSULTORES(ID,NOMBRES,APELLIDOS,TIPO_DOCUMENTO,NRO_DOCUMENTO,CUIT,FORMACION,MOVILIDAD,DIAS_MENSUALES,EVENTUAL,INGRESA_SISTEMA,ID_USUARIO_SEGURIDAD,ESTADO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES,USUARIO_ORIGEN,INGRESA_SISTEMA_ORIGEN)
   SELECT ID,ISNULL(Nombres,''),ISNULL(Apellidos,''),ISNULL(TipoDocumento,''),ISNULL(Documento,''),LEFT(Cuit,50),Formacion,Movilidad,Dias,Eventual,Acceso,UsuarioSeguridad,Estado,FechaAlta,UsuarioAlta,FechaUpd,UsuarioUpd,CONVERT(varchar(max),Raw),UsuarioOrigen,IngresaOrigen FROM #P WHERE Entidad='CONSULTOR';
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_HISTORICO_DIAS ON; SET @identity=N'VCT_CONSULTORES_HISTORICO_DIAS';
  INSERT dbo.VCT_CONSULTORES_HISTORICO_DIAS(ID,ID_CONSULTOR,PERIODO,DIAS_MENSUALES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES)
   SELECT ID,ID_CONSULTOR,PERIODO,DIAS_MENSUALES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES FROM #Dias;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_HISTORICO_DIAS OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_NORMAS ON; SET @identity=N'VCT_CONSULTORES_NORMAS';
  INSERT dbo.VCT_CONSULTORES_NORMAS(ID,ID_CONSULTOR,ID_NORMA,ID_SERVICIO,CALIFICACION,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES)
   SELECT ID,ID_CONSULTOR,ID_NORMA,ID_SERVICIO,CALIFICACION,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES FROM #Aptitudes;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_NORMAS OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_SERVICIOS ON; SET @identity=N'VCT_CONSULTORES_SERVICIOS';
  INSERT dbo.VCT_CONSULTORES_SERVICIOS(ID,ID_CONSULTOR,ID_SERVICIO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES)
   SELECT ID,ID_CONSULTOR,ID_SERVICIO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES FROM #Tipos;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_SERVICIOS OFF; SET @identity=NULL;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_OBSERVACIONES ON; SET @identity=N'VCT_CONSULTORES_OBSERVACIONES';
  INSERT dbo.VCT_CONSULTORES_OBSERVACIONES(ID,ID_CONSULTOR,MES,ANO,PERIODO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES)
   SELECT ID,ID_CONSULTOR,MES,ANO,PERIODO,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD,OBSERVACIONES FROM #Observaciones;
  SET IDENTITY_INSERT dbo.VCT_CONSULTORES_OBSERVACIONES OFF; SET @identity=NULL;
 
  INSERT dbo.VCT_DOMICILIOS(TIPO_ENTIDAD,ID_ENTIDAD,CALLE,NRO,PISO,DEPTO,LOCALIDAD,PROVINCIA,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT d.Entidad,d.ID,d.CALLE,d.NRO,d.PISO,d.DEPTO,d.LOCALIDAD,d.PROVINCIA,@Principal,d.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Domicilios d JOIN #P p ON p.ID=d.ID;
  INSERT dbo.VCT_TELEFONOS(TIPO_ENTIDAD,ID_ENTIDAD,CODAREA,NRO,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT t.Entidad,t.ID,t.CODAREA,t.NRO,t.PRINCIPAL,t.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Telefonos t JOIN #P p ON p.ID=t.ID;
  INSERT dbo.VCT_EMAILS(TIPO_ENTIDAD,ID_ENTIDAD,EMAIL,PRINCIPAL,OBSERVACIONES,FECHA_ALTA,USUARIO_ALTA,FECHA_UPD,USUARIO_UPD)
   SELECT e.Entidad,e.ID,e.EMAIL,e.PRINCIPAL,e.OBSERVACIONES,p.FechaAlta,p.UsuarioAlta,p.FechaUpd,p.UsuarioUpd FROM #Emails e JOIN #P p ON p.ID=e.ID;
  INSERT dbo.VCT_PERSONAS_CV(TIPO_ENTIDAD,ID_ENTIDAD,CV,FECHA_CV,CV_PKEY,OBSERVACIONES)
   SELECT Entidad,ID,CV,FechaCV,CVPkey,'CV original de LK_EMPLEADOS; contenido binario conservado.' FROM #P WHERE CV IS NOT NULL OR FechaCV IS NOT NULL OR CVPkey IS NOT NULL;
  IF EXISTS(SELECT ID FROM #P WHERE Entidad='EMPLEADO' EXCEPT SELECT ID FROM dbo.VCT_EMPLEADOS)
   OR EXISTS(SELECT ID FROM dbo.VCT_EMPLEADOS EXCEPT SELECT ID FROM #P WHERE Entidad='EMPLEADO')
   OR EXISTS(SELECT ID FROM #P WHERE Entidad='CONSULTOR' EXCEPT SELECT ID FROM dbo.VCT_CONSULTORES)
   OR EXISTS(SELECT ID FROM dbo.VCT_CONSULTORES EXCEPT SELECT ID FROM #P WHERE Entidad='CONSULTOR')
   THROW 53015,'IDs de empleados o consultores no coinciden con origen.',1;
  IF EXISTS(SELECT 1 FROM #Normas s LEFT JOIN dbo.VCT_PRM_NORMAS d ON d.ID=s.ID WHERE d.ID IS NULL OR d.DESCRIPCION COLLATE DATABASE_DEFAULT<>s.Descripcion COLLATE DATABASE_DEFAULT)
   OR EXISTS(SELECT 1 FROM #Servicios s LEFT JOIN dbo.VCT_PRM_SERVICIOS d ON d.ID=s.ID WHERE d.ID IS NULL OR d.CODIGO COLLATE DATABASE_DEFAULT<>s.Codigo COLLATE DATABASE_DEFAULT OR d.DESCRIPCION COLLATE DATABASE_DEFAULT<>s.Descripcion COLLATE DATABASE_DEFAULT)
   THROW 53016,'Catalogos no coinciden con el origen.',1;
  IF EXISTS(SELECT 1 FROM #P p LEFT JOIN dbo.VCT_PERSONAS_CV c ON c.TIPO_ENTIDAD COLLATE DATABASE_DEFAULT=p.Entidad COLLATE DATABASE_DEFAULT AND c.ID_ENTIDAD=p.ID
    WHERE p.CV IS NOT NULL AND (c.ID_ENTIDAD IS NULL OR c.CV IS NULL OR DATALENGTH(c.CV)<>DATALENGTH(p.CV) OR c.CV<>p.CV))
   THROW 53017,'El CV no se copio correctamente.',1;
  DECLARE validar CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla,Esperadas FROM #Resumen;
  OPEN validar; FETCH NEXT FROM validar INTO @nombre,@esperado;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+CASE WHEN @nombre IN (N'VCT_DOMICILIOS',N'VCT_TELEFONOS',N'VCT_EMAILS') THEN N' WHERE TIPO_ENTIDAD IN (''EMPLEADO'',''CONSULTOR'')' ELSE N'' END;
   EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   IF @n<>@esperado THROW 53018,'Conteos incorrectos; se revierte la migracion.',1;
   FETCH NEXT FROM validar INTO @nombre,@esperado;
  END;
  CLOSE validar; DEALLOCATE validar;
  -- Reseed each table to its actual maximum. Shared auxiliaries include CLIENTE.
  DECLARE identidades CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM @Tablas t WHERE Nombre<>N'VCT_PERSONAS_CV'
   AND NOT EXISTS(SELECT 1 FROM #Limpiar l WHERE l.ObjectId=t.ObjectId);
  OPEN identidades; FETCH NEXT FROM identidades INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @tabla=N'dbo.'+QUOTENAME(@nombre);
   SET @sql=N'SELECT @M=MAX(ID) FROM '+@tabla; EXEC sys.sp_executesql @sql,N'@M int OUTPUT',@M=@ultimo OUTPUT;
   SET @valor=CASE WHEN @ultimo IS NOT NULL THEN @ultimo WHEN EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(@tabla) AND last_value IS NULL) THEN 1 ELSE 0 END;
   SET @sql=N'DBCC CHECKIDENT(N'''+REPLACE(@tabla,'''','''''')+N''',RESEED,'+CONVERT(nvarchar(20),@valor)+N') WITH NO_INFOMSGS;'; EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM identidades INTO @nombre;
  END;
  CLOSE identidades; DEALLOCATE identidades;
  -- Reset cleared tables only when they have an identity; handle their actual seed.
  DECLARE @semilla bigint,@incremento bigint,@nunca bit;
  DECLARE resetlimpieza CURSOR LOCAL FAST_FORWARD FOR
   SELECT l.Nombre,CONVERT(bigint,c.seed_value),CONVERT(bigint,c.increment_value),CONVERT(bit,CASE WHEN c.last_value IS NULL THEN 1 ELSE 0 END)
   FROM #Limpiar l JOIN sys.identity_columns c ON c.object_id=l.ObjectId;
  OPEN resetlimpieza; FETCH NEXT FROM resetlimpieza INTO @nombre,@semilla,@incremento,@nunca;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'DBCC CHECKIDENT(N''dbo.'+REPLACE(QUOTENAME(@nombre),NCHAR(39),NCHAR(39)+NCHAR(39))+N''',RESEED,'
    +CONVERT(nvarchar(30),CASE WHEN @nunca=1 THEN @semilla ELSE @semilla-@incremento END)+N') WITH NO_INFOMSGS;';
   EXEC sys.sp_executesql @sql;
   FETCH NEXT FROM resetlimpieza INTO @nombre,@semilla,@incremento,@nunca;
  END;
  CLOSE resetlimpieza; DEALLOCATE resetlimpieza;
  DECLARE validarlimpieza CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM #Limpiar;
  OPEN validarlimpieza; FETCH NEXT FROM validarlimpieza INTO @nombre;
  WHILE @@FETCH_STATUS=0
  BEGIN
   SET @sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@nombre)+N';'; EXEC sys.sp_executesql @sql,N'@N bigint OUTPUT',@N=@n OUTPUT;
   IF @n<>0 THROW 53020,'Una tabla de proyectos o gestiones no quedo vacia; se revierte la carga.',1;
   FETCH NEXT FROM validarlimpieza INTO @nombre;
  END;
  CLOSE validarlimpieza; DEALLOCATE validarlimpieza;
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
  INSERT dbo.VCT_MIGRACION_PERSONAL_EJECUCIONES(ID,FECHA,EMPLEADOS,CONSULTORES,NORMAS,EXCEPCIONES,USUARIO)
   SELECT @run,@ahora,(SELECT COUNT(*) FROM #P WHERE Entidad='EMPLEADO'),(SELECT COUNT(*) FROM #P WHERE Entidad='CONSULTOR'),(SELECT COUNT(*) FROM #Normas),(SELECT COUNT(*) FROM #Excepciones),LEFT(SUSER_SNAME(),100);
  INSERT dbo.VCT_MIGRACION_PERSONAL_EXCEPCIONES(ID_EJECUCION,TABLA_ORIGEN,ID_ORIGEN,TIPO_ENTIDAD,ID_ENTIDAD,OBSERVACIONES)
   SELECT @run,Fuente,ID_ORIGEN,LEFT(Entidad,30),ID_ENTIDAD,Detalle FROM #Excepciones;
  COMMIT TRANSACTION;
  SELECT N'MIGRACION PERSONAL CONFIRMADA' Resultado,@run ID_EJECUCION;
  SELECT Tabla,Esperadas FilasCargadas FROM #Resumen ORDER BY Tabla;
  SELECT Nombre TablaVaciada,FilasAntes FilasEliminadas FROM #Limpiar ORDER BY Nombre;
  SELECT * FROM #Excepciones ORDER BY Fuente,ID_ORIGEN;
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
