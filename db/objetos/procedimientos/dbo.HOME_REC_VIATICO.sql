CREATE PROCEDURE [dbo].[HOME_REC_VIATICO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(8000) OUTPUT)
AS
 
DECLARE	@VID					VARCHAR(50),
		@VSERVICIO				VARCHAR(50),
		@VID_HOJA				VARCHAR(50),
		@VPROVEEDOR_ID			VARCHAR(50),
		@VTIPO_PROV				VARCHAR(50),
		@VNRO_FACTURA_PROV		VARCHAR(50),
		@VCANT_PERSONAS_PROV	VARCHAR(50),
		@VDESCRIP_SERVICIO_PROV	VARCHAR(100),
		@VFECHA_FACTURA_PROV	DATETIME,
		@VPRECIO_FINAL_PROV		VARCHAR(50),
		@VFORMA_PAGO_PROV		VARCHAR(50),
		@VCANT_CUOTAS_PROV		VARCHAR(50),
		@VESTADO_PAGO_PROV		VARCHAR(50),
		@VFECHA_ULT_PAGO_PROV	DATETIME,
		@VPRECIO_CUOTA_PROV		VARCHAR(50),
		@VFECHA_PROX_VTO_PROV	DATETIME,
		@VSALDO_PEND_PROV		VARCHAR(50),
		@VDESTINO_PROV			VARCHAR(100),
		@VFECHA_DESDE_SERV_PROV	DATETIME,
		@VFECHA_HASTA_SERV_PROV	DATETIME,
		@UNITDESC			VARCHAR(300),
		@USERDESC			VARCHAR(300),
		@VERROR				VARCHAR(50),
		@VID_AGENDA			VARCHAR(50),
		@VPROYECTO			VARCHAR(50),
		@VCLIENTE			VARCHAR(300),
		@VNORMA				VARCHAR(300),
		@VFECHAP			VARCHAR(50),
		@VDIASP				VARCHAR(50),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VESTADO	VARCHAR(100),
		@VARNORMA	VARCHAR(400),
		@VID_SERVICIO INT,
		@VCONSULTORES	VARCHAR(4000),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VTIPO_CONSULTOR	VARCHAR(50),
		@VCONSULTOR			VARCHAR(50),
		@VPROYECTO_SERV	VARCHAR(50),
		@VNOMBRE		VARCHAR(300),
		@VHORAS		VARCHAR(50),
		@VDESC_PAGO			VARCHAR(300)
 
BEGIN
 
	--SELECT	TOP 1 @UNITDESC = UNIT_DESCRIPTION
	--FROM	ORGANIZATION
	--WHERE	UNIT_CODE = @IUNIDAD;
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	--SELECT	TOP 1 @USERDESC = A.NOMBRE
	--FROM	(
	--		SELECT	TOP 1 USER_NAME AS NOMBRE
	--		FROM	AGENTE
	--		WHERE	USER_ID = @IAGENTE
	--		UNION
	--		SELECT	TOP 1 SUPERVISOR_NAME AS NOMBRE
	--		FROM	SUPERVISOR
	--		WHERE	SUPERVISOR_CODE = @IAGENTE) A
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE		
	
	SELECT	--@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VID_HOJA  = ISNULL(HOJA_RUTA_ID,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO,
			@VPROYECTO_SERV = PROYECTO_SERV_ID
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VID_AGENDA
	
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VPROYECTO  = '('+P.CODIGO+') - '+P.NORMA_REF,
			@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VFECHAD = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(a.NORMA,''),
			@VCONSULTORES = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
			@VID_SERVICIO = ID_SERVICIO,
			@VHORAS = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA)
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VPROYECTO_SERV
 
	--SET @VSTATUS = [dbo].[FN_GET_STATUS_AGENDA] (@VAGENDA_ID)
	
	WHILE LEN(@VARNORMA) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VARNORMA) -- Busca el caracter a separador
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VARNORMA
					SET @VARNORMA = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VARNORMA, 1, @lnuPosComa - 1)
 
					SELECT	@VALOR = '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+DESC_APTITUD+'</font>'
					FROM	LK_APTITUDES
					WHERE	ID_APTITUD = @lstDato
 
					SET @VDESCNORMAS = ISNULL(@VDESCNORMAS,'') + @VALOR + '</br>'
 
					SET @VARNORMA = SUBSTRING(@VARNORMA, @lnuPosComa + 1, LEN(@VARNORMA))
				END
			END
	
	SELECT	@VPROVEEDOR_ID = ISNULL(ID_PROVEEDOR,''),
			@VTIPO_PROV	= ISNULL(TIPO_PROVEEDOR,''),	
			@VNRO_FACTURA_PROV = ISNULL(NRO_FC,''),
			@VCANT_PERSONAS_PROV = ISNULL(CANT_PERSONAS,''),	 
			@VDESCRIP_SERVICIO_PROV	= ISNULL(DESCRIP_SERVICIO,''),
			@VFECHA_FACTURA_PROV = NULLIF(ISNULL(FECHA_FC,''),''),
			@VPRECIO_FINAL_PROV	= ISNULL(PRECIO_FINAL,''),	
			@VFORMA_PAGO_PROV = ISNULL(FORMA_PAGO,''),		
			@VCANT_CUOTAS_PROV = ISNULL(CANT_CUOTAS,''),		
			@VESTADO_PAGO_PROV	= ISNULL(ESTADO_PAGO,''),	
			@VFECHA_ULT_PAGO_PROV = NULLIF(ISNULL(FECHA_ULT_PAGO,''),''),	
			@VPRECIO_CUOTA_PROV = ISNULL(PRECIO_CUOTA,''),		
			@VFECHA_PROX_VTO_PROV = NULLIF(ISNULL(PROX_VENCIMIENTO,''),''),	
			@VSALDO_PEND_PROV = ISNULL(SALDO_PEND,''),		
			@VDESTINO_PROV = ISNULL(DESTINO,''),			
			@VFECHA_DESDE_SERV_PROV	= NULLIF(ISNULL(FECHA_DESDE_SERV,''),''),
			@VFECHA_HASTA_SERV_PROV = NULLIF(ISNULL(FECHA_HASTA_SERV,''),''),
			@VTIPO_CONSULTOR = ISNULL(TIPO_CONSULTOR,''),
			@VCONSULTOR = ISNULL(ID_CONSULTOR,''),
			@VDESC_PAGO	= ISNULL(DESC_FORMA_PAGO,'')
	FROM	LK_PROYECTO_VIATICOS
	WHERE	ID_PROYECTO_VIATICOS = @VID_HOJA--ID_AGENDA = @VID_AGENDA--
 
	IF (@VERROR <> 'SI') BEGIN
		UPDATE	XAGENDA
		SET		PROVEEDOR_ID = @VPROVEEDOR_ID,
				TIPO_PROV = @VTIPO_PROV,
				NRO_FACTURA_PROV = @VNRO_FACTURA_PROV,
				CANT_PERSONAS_PROV = @VCANT_PERSONAS_PROV,
				DESCRIP_SERVICIO_PROV = @VDESCRIP_SERVICIO_PROV,
				FECHA_FACTURA_PROV = @VFECHA_FACTURA_PROV,
				PRECIO_FINAL_PROV = @VPRECIO_FINAL_PROV,
				FORMA_PAGO_PROV = @VFORMA_PAGO_PROV,
				CANT_CUOTAS_PROV = @VCANT_CUOTAS_PROV,
				ESTADO_PAGO_PROV = @VESTADO_PAGO_PROV,
				FECHA_ULT_PAGO_PROV = @VFECHA_ULT_PAGO_PROV,
				PRECIO_CUOTA_PROV = @VPRECIO_CUOTA_PROV,
				FECHA_PROX_VTO_PROV = @VFECHA_PROX_VTO_PROV,
				SALDO_PEND_PROV = @VSALDO_PEND_PROV,
				DESTINO_PROV = @VDESTINO_PROV,
				FECHA_DESDE_SERV_PROV = @VFECHA_DESDE_SERV_PROV,
				FECHA_HASTA_SERV_PROV = @VFECHA_HASTA_SERV_PROV,
				TIPO_CONSULTOR_PROV = @VTIPO_CONSULTOR,
				CONSULTOR_PROV = @VCONSULTOR,
				DESC_FORMA_PAGO_PROV = @VDESC_PAGO
		WHERE	PAR_KEY = @IPKEYJOB
	END
 
	SET @OHEADER = '
	<html>
	
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C''); return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#52BE80;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Modificar Viatico</b></font>
			</p>
		</div>
		
		<div class="w3-col w3-container" style="width:70%;background-color:#D6DBDF;text-align:right">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: center">'
			+'<b>Nro Proceso: </b>'+'<font style="font-size:8;color:#003D7A">'+'<b>'+ CONVERT(VARCHAR,@IJOBSEQ)		 +'</b></font> - '
			+'<b>Usuario: </b>'+@USERDESC								 +' - '
			+'<b>Perfil: </b>'+@UNITDESC								 +' - '
			+'<b>Fecha: </b>' +CONVERT(VARCHAR, GETDATE(), 103)			 +' '
								+CONVERT(VARCHAR,GETDATE(),108)			 +
			--+'/>'
			+'</font>
			</p>
		</div>
	</div>
	
	<div class="w3-panel w3-topbar"></div>
 
	<div class="w3-container">
		<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
			<th><b>Cliente</b></th>
			<th><b>Proyecto</b></th>
			<th><b>Servicio</b></th>
			<th><b>Nombre</b></th>
			<th><b>Normas</b></th>
			<th><b>Dias</b></th>
			<th><b>Horas</b></th>
			<th><b>Fecha Desde</b></th>
			<th><b>Fecha Hasta</b></th>
			<th><b>Estado</b></th>
			<th><b>Profesional</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			 '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VPROYECTO+'</td>' +
			  '<td>'+@VSERVICIO+'</td>' +
			  '<td>'+ISNULL(@VNOMBRE,'')+'</td>' +
			  '<td>'+@VDESCNORMAS+'</td>' +
			  '<td>'+@VDIAS+'</td>' +
			  '<td>'+@VHORAS+'</td>' +
			  '<td>'+@VFECHAD+'</td>' +
			  '<td>'+@VFECHAH+'</td>' +
			  '<td>'+@VESTADO+'</td>' +
			  '<td>'+@VCONSULTORES+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	'
 
	
 
	SET @OFOOTER = '
	<html>
	<body>
	
	<div>
	<p>
		<button onclick="next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Grabar</b></font></button>
		<button onclick="goto('''+@FORM_ID+''',''87AAC6F3-E50E-496A-9394-806E19335B6C''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#52BE80"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Cancelar</b></font></button>
	</p>
	</div>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	</body>
	</html>'
 
END
