CREATE PROCEDURE [dbo].[EP_CRON_GRD_POR_PLANTA]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100))
AS
	DECLARE 
	@IPLANTA VARCHAR(50),
	@IESTADO_SEL VARCHAR(50),
	@IMES_SEL VARCHAR(50),
	@IANIO_SEL VARCHAR(50),
	@ITIPO_SERV VARCHAR(50),
	@QUERY VARCHAR(MAX)
	--@ITIPO_TAREA VARCHAR(50),
	
 
BEGIN	
 
	SELECT 
		@IPLANTA = ID_PLANTA_SEL,
		@IESTADO_SEL = ID_ESTADO_SEL,
		@IMES_SEL = ID_MES_SEL,
		@IANIO_SEL = ID_ANIO_SEL,
		@ITIPO_SERV = ID_TIPO_SERV_SEL --,@ITIPO_TAREA = ID_TAREA_SEL 
	FROM TMT_CRON
	WHERE PAR_KEY = @IPKEYJOB
	
 
	 SET @QUERY = '';
 
	IF (ISNULL(@IANIO_SEL,'')='') 
		BEGIN
			SET @IANIO_SEL = '2024'
		END
 
 
	IF (ISNULL(@IPLANTA,'') <> '')
		BEGIN
		 SET @QUERY = @QUERY + ' AND CRON.IDPlanta= ' + @IPLANTA
		END
	IF (ISNULL(@IESTADO_SEL,'') <> '')
		BEGIN
		 SET @QUERY = @QUERY + ' AND CRON.IdEstado= '+ @IESTADO_SEL 
		END
	IF (ISNULL(@IMES_SEL,'') <> '')
		BEGIN
		 SET @QUERY = @QUERY + ' AND CRON.IdMes='+@IMES_SEL 
		END
	IF (ISNULL(@IANIO_SEL,'') <> '')
		BEGIN
		 SET @QUERY = @QUERY + ' AND CRON.Año='+@IANIO_SEL
		END
	IF (ISNULL(@ITIPO_SERV,'') <> '')
		BEGIN
		  SET @QUERY = @QUERY + ' AND TIPO.Fila= '+@ITIPO_SERV 
		END
	--IF (ISNULL(@ITIPO_TAREA,'') <> '')
	--	BEGIN
	--	  SET @QUERY = @QUERY + ' AND CRON.IdTipoTareaCronograma= '+@ITIPO_TAREA 
	--	END
 
	--TIPO.Descripcion as "Tipo Tarea",
	SET @QUERY = 'SELECT CRON.Año, M.Mes, 
	CASE 
		WHEN TIPO.FILA = 1 THEN ''Seguridad e Higiene''
		WHEN TIPO.FILA = 2 THEN ''Asesoramiento y Gestión Ambiental''
		WHEN TIPO.FILA = 3 THEN ''Monitoreos Contratados''
		WHEN TIPO.FILA = 4 THEN ''Avisos y Comunicaciones''
	END as "Tipo Servicio",
	ISNULL(CRON.Descripcion, SUB.Impresion) as Tarea,
	CASE 
		WHEN CRON.IDESTADO = 1 THEN ''<i class="fas fa-circle w3-text-red w3-large"></i>&nbsp;No Realizado''
		WHEN CRON.IDESTADO = 2 THEN ''<i class="fas fa-circle w3-large" style="color: #ffeb3b"></i>&nbsp;En Proceso'' 
		WHEN CRON.IDESTADO = 3 THEN ''<i class="fa fa-circle w3-text-orange w3-large"></i>&nbsp;Realizado'' 
		WHEN CRON.IDESTADO = 4 THEN ''<i class="fas fa-circle w3-text-green w3-large"></i>&nbsp;Finalizado''
	END as Estado
	FROM EP_CRONOGRAMA CRON
	INNER JOIN EP_EMPRESAS EMP ON EMP.IdEmpresa=CRON.IdEmpresa
	INNER JOIN EP_PLANTAS  P ON P.IdPlanta=CRON.IdPlanta
	INNER JOIN [EP_TIPO_TAREA_CRON] TIPO ON TIPO.ID=CRON.IdTipoTareaCronograma
	INNER JOIN [EP_SUBTIPO_TAREA_CRON] SUB ON SUB.IDSubtipoTareaCronograma=CRON.IDSubtipoTareaCronograma
	INNER JOIN [EP_MESES] M on M.IDMes=CRON.IdMes
	INNER JOIN [EP_ESTADOS] E on E.IdEstado=CRON.IdEstado
	WHERE 1=1' + @QUERY + ' order by m.idmes';
 
	exec(@QUERY);
 
	--1	No Realizado
	--2	En Proceso
	--3	Realizado
	--4	Finalizado
	--
	-- SE SOLICITO POR EL CLIENTE SACAR EL ESTADO SUSPENDIDA
	--	CASE WHEN ISNULL(CRON.Suspendida,'''') = ''True'' THEN ''<i class="w3-tooltip  fas fa-pause-circle w3-text-red w3-large"><span class="w3-text">(Suspendido por el cliente)</span></i>'' ELSE
 
END
