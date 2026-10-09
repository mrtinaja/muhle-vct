CREATE PROCEDURE [dbo].[HOME_VER_RENDICION]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(8000) OUTPUT)
AS
 
DECLARE @VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VRAZON_SOCIAL		VARCHAR(400),
		@VNOMBRE_PROY		VARCHAR(400),
		@VTIPO_SERV			VARCHAR(50),
		@VNOMBRE			VARCHAR(400),
		@VLUGAR				VARCHAR(400),
		@VERROR				VARCHAR(50),
		@VDESC_ERROR		VARCHAR(4000)
 
DECLARE	@VID		VARCHAR(50),
		@VSERVICIO	VARCHAR(100),
		@UNITDESC	VARCHAR(300),
		@USERDESC	VARCHAR(300),
		@VPROYECTO	VARCHAR(300),
		@VIDCLIENTE	VARCHAR(100),
		@VNORMA		VARCHAR(300),
		@VFECHAD	VARCHAR(50),
		@VFECHAH	VARCHAR(50),
		@VDIAS		VARCHAR(50),
		@VAGENDA_ID	VARCHAR(50),
		@VESTADO	VARCHAR(100),
		@VARNORMA	VARCHAR(400),
		@lstDato		varchar(100), 
		@lnuPosComa		int ,
		@VALOR			VARCHAR(400),
		@VDESCNORMAS	VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@VTIPO			VARCHAR(50),
		@VCANT_HR		INT,
		@VSTATUS		VARCHAR(50),
		@VCONSULTOR		VARCHAR(50),
		@VOBSERV_PL		VARCHAR(400),
		@VPOWER_POINT	VARCHAR(50),	
		@VCORRESP_MAT	VARCHAR(50),
		@VLISTA_MAT		VARCHAR(400),
		@VDESC_ENVIO	VARCHAR(400),
		@VTORF			VARCHAR(100),
		@VACUMULA_VIAT	VARCHAR(MAX),
		@VEXCEL_CONSULTOR	VARCHAR(300),
		@VEXCEL_TIPO	VARCHAR(300),
		@VEXCEL_PROV	VARCHAR(300),
		@VEXCEL_PRECIO	NUMERIC(10,2),
		@VEXCEL_FECHA	VARCHAR(100),
		@VEXCEL_DETALLE	VARCHAR(400),
		@VQUERY			VARCHAR(MAX),
		@VCOMPROBANTE	INT,
		@VEXCEL_TOTAL	NUMERIC(10,2),
		@VEXCEL_GASTOS	NUMERIC(10,2),
		@VEXCEL_SUMA	NUMERIC(10,2),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
BEGIN	
 
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VAGENDA_ID		= ISNULL(AGENDA_ID,''),
			@VERROR			= ISNULL(ERROR,''),
			@VDESC_ERROR	= ISNULL(DESC_ERROR,''),
			@VACUMULA_VIAT = ISNULL(ACUMULA_VIATICO,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	@VPROYECTO  = ID_PROYECTO,
			@VSERVICIO  = ID_SERVICIO
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SELECT	@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
 
	IF (@VID_PROYECTO <> '') BEGIN
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	SELECT	@VTIPO_SERV = ID_TIPO_SERVICIO,
			@VNOMBRE = ISNULL(NOMBRE,''),
			@VLUGAR = ISNULL(LUGAR,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
	SELECT	@VDIAS_AGENDA = DIAS,
			@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
			@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END
	FROM	LK_AGENDA A
	WHERE	ID_AGENDA = @VAGENDA_ID
 
	SET @VQUERY = '
		SELECT	''<td colspan="6" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick" data-fill-color="D8E4BC"><b>Descripcion General</b></td>'' as ''title=Reembolsables;data-cols-width="20,20,15,20,15,15";data-f-name="Calibri";data-f-sz="26"'', '''' as "2", '''' as "3",'''' as "4",'''' as "5", '''' as "6"
		UNION ALL
		SELECT	''<td data-fill-color="EBF1DE" data-f-bold="true"><b>Cliente</b></td>'', ''<td data-fill-color="EBF1DE" colspan="3">''+C.RAZON_SOCIAL_CLIENTE+''</td>'', '''','''',''<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fecha Desde</b></td>'', ''<td data-fill-color="EBF1DE">''+CONVERT(VARCHAR,A.FECHA,103)+''</td>''
		FROM	LK_AGENDA A
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
		WHERE	ID_AGENDA = '''+@VAGENDA_ID+'''
		UNION ALL
		SELECT	''<td data-fill-color="EBF1DE" data-f-bold="true"><b>Proyecto</b></td>'', ''<td data-fill-color="EBF1DE" colspan="3">''+P.NORMA_REF+''</td>'', '''','''',''<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fecha Hasta</b></td>'', ''<td data-fill-color="EBF1DE">''+CONVERT(VARCHAR,A.FECHA_HASTA,103)+''</td>''
		FROM	LK_AGENDA A
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
		WHERE	ID_AGENDA = '''+@VAGENDA_ID+'''
		UNION ALL
		SELECT	''<td data-fill-color="EBF1DE" data-f-bold="true"><b>Actividad</b></td>'', CASE WHEN A.ID_SERVICIO = ''1'' THEN ''<td data-fill-color="EBF1DE" colspan="3">Consultoria</td>''
								  WHEN A.ID_SERVICIO = ''2'' THEN ''<td data-fill-color="EBF1DE" colspan="3">Auditoria</td>''
								  WHEN A.ID_SERVICIO = ''3'' THEN ''<td data-fill-color="EBF1DE" colspan="3">Capacitacion</td>'' END, '''','''',''<td data-fill-color="EBF1DE" data-f-bold="true"></td>'', ''<td data-fill-color="EBF1DE"></td>''
		FROM	LK_AGENDA A
		WHERE	ID_AGENDA = '''+@VAGENDA_ID+'''
		UNION ALL
		SELECT	''<td data-fill-color="FCD5B4" colspan="6" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Viaticos Actividad</b></td>'', '''', '''','''','''', ''''
		UNION ALL
		SELECT	''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha</font></td>'', ''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Consultor</font></td>'', ''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Tipo</font></td>'', ''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Detalle</font></td>'' ,''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Nro Comprobante</font></td>'', ''<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Importe</font></td>''
		'
 
	SET @VALOR = ''
	SET @VCOMPROBANTE = 1
 
	IF (LEN(@VACUMULA_VIAT) = 0) BEGIN
		SET @VQUERY = @VQUERY +
		'
		UNION ALL
		SELECT	'''', '''', '''','''','''', ''''
		'
	END
 
	--recorro los viaticos seleccionados--
	WHILE LEN(@VACUMULA_VIAT) > 0
	BEGIN 
		SET @lnuPosComa = CHARINDEX('|', @VACUMULA_VIAT) -- Busca el caracter a separador
		IF (@lnuPosComa = 0) BEGIN 
			SET @lstDato = @VACUMULA_VIAT
			SET @VACUMULA_VIAT = '' 
		END ELSE BEGIN
			SET @lstDato = SUBSTRING(@VACUMULA_VIAT, 1, @lnuPosComa - 1)
			SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
			IF (@VTORF = 'FALSE') BEGIN
				
				SET @VACUMULA_VIAT = SUBSTRING(@VACUMULA_VIAT, @lnuPosComa + 1, LEN(@VACUMULA_VIAT))
 
			END ELSE BEGIN
						
				SET @VALOR = SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1)
 
				--ACA RECUPERO EL DETALLE DEL VIATICO POR ID PARA MOSTRAR EN EL EXCEL--
				SELECT	@VEXCEL_CONSULTOR = ISNULL(APELLIDO_EMPLEADO,'') + ', '+ ISNULL(NOMBRE_EMPLEADO,'') ,
						--@VEXCEL_PROV = CASE WHEN ID_PROVEEDOR = '9999' THEN 'Otros' ELSE ID_PROVEEDOR END,
						@VEXCEL_TIPO = TIPO_PROVEEDOR,
						@VEXCEL_PRECIO = PRECIO_FINAL,
						@VEXCEL_FECHA = CASE WHEN ISNULL(FECHA_FC,'') = '' THEN '' ELSE CONVERT(VARCHAR,FECHA_FC,103) END,
						@VEXCEL_DETALLE = ISNULL(DESCRIP_SERVICIO,'')
				FROM	LK_PROYECTO_VIATICOS V
						LEFT JOIN LK_EMPLEADOS EMP ON V.ID_CONSULTOR = EMP.ID_EMPLEADO
				WHERE	ID_PROYECTO_VIATICOS = @VALOR
				
				IF (@VEXCEL_TIPO IN ('AVION','MICRO')) BEGIN
					SELECT	TOP 1 @VEXCEL_FECHA = CASE WHEN ISNULL(DET_PROV_FECHA,'') = '' THEN '' ELSE CONVERT(VARCHAR,DET_PROV_FECHA,103) END,
							@VEXCEL_DETALLE = ISNULL(DET_PROV_ORIGEN,'') + ' - ' + ISNULL(DET_PROV_DESTINO,'')
					FROM	LK_PROYECTO_VIATICOS_DET
					WHERE	ID_PROYECTO_VIATICOS = @VALOR
				END
 
				IF (@VEXCEL_TIPO IN ('REMIS','TAXI')) BEGIN
					SELECT	TOP 1 @VEXCEL_FECHA = CASE WHEN ISNULL(DET_PROV_FPARTIDA,'') = '' THEN '' ELSE CONVERT(VARCHAR,DET_PROV_FPARTIDA,103) END,
							@VEXCEL_DETALLE = ISNULL(DET_PROV_ORIGEN,'') + ' - ' + ISNULL(DET_PROV_DESTINO,'')
					FROM	LK_PROYECTO_VIATICOS_DET
					WHERE	ID_PROYECTO_VIATICOS = @VALOR
				END
 
				IF (@VEXCEL_TIPO = 'HOTEL') BEGIN
					SELECT	TOP 1 @VEXCEL_FECHA = CASE WHEN ISNULL(DET_PROV_FINGRESO,'') = '' THEN '' ELSE CONVERT(VARCHAR,DET_PROV_FINGRESO,103) + ' - ' + ISNULL(CONVERT(VARCHAR,DET_PROV_FEGRESO,103),'') END,
							@VEXCEL_DETALLE = ISNULL(DET_PROV_LOCAL,'')
					FROM	LK_PROYECTO_VIATICOS_DET
					WHERE	ID_PROYECTO_VIATICOS = @VALOR
				END
 
				SET @VQUERY = @VQUERY +
				'UNION ALL
				 SELECT	'''+@VEXCEL_FECHA+''',
						'''+@VEXCEL_CONSULTOR+''',
						'''+@VEXCEL_TIPO+''',
						'''+@VEXCEL_DETALLE+''',
						'''+'<td style="text-align:center;" data-a-h="center">'+CONVERT(VARCHAR,@VCOMPROBANTE)+'</td>'',
						'''+CONVERT(VARCHAR,@VEXCEL_PRECIO)+'''
				'
				
				SET @VCOMPROBANTE = @VCOMPROBANTE + 1
				SET @VEXCEL_TOTAL = ISNULL(@VEXCEL_TOTAL,0) + @VEXCEL_PRECIO
				SET @VACUMULA_VIAT = SUBSTRING(@VACUMULA_VIAT, @lnuPosComa + 1, LEN(@VACUMULA_VIAT))
			END									
		END
	END
 
	IF (ISNULL(CONVERT(VARCHAR,@VEXCEL_TOTAL),'') = '') BEGIN
		SET @VEXCEL_GASTOS = NULL
		SET @VEXCEL_SUMA = NULL
	END ELSE BEGIN
		SET @VEXCEL_GASTOS = @VEXCEL_TOTAL * 6 / 100
		SET @VEXCEL_SUMA = @VEXCEL_TOTAL + @VEXCEL_GASTOS
	END
	
	SET @VQUERY = @VQUERY +
	'
	UNION ALL
	SELECT	''<td data-fill-color="FFFF99" colspan="5" style="text-align:center;" data-a-h="center" data-f-bold="true"><b>Total de Viaticos</b></td>'', '''', '''','''','''', ''<td data-fill-color="FFFF99" data-f-bold="true"><b>'+ISNULL(CONVERT(VARCHAR,@VEXCEL_TOTAL),'')+'</b></td>''
	UNION ALL
	SELECT	''<td data-fill-color="FFFF99" colspan="5" style="text-align:center;" data-a-h="center" data-f-bold="true"><b>Gastos Administrativos e Impositivos 6%</b></td>'', '''', '''','''','''', ''<td data-fill-color="FFFF99" data-f-bold="true"><b>'+ISNULL(CONVERT(VARCHAR,@VEXCEL_GASTOS),'')+'</b></td>''
	UNION ALL
	SELECT	''<td data-fill-color="FFFF00" colspan="5" style="text-align:center;" data-a-h="center" data-f-bold="true"><b>TOTAL</b></td>'', '''', '''','''','''', ''<td data-fill-color="FFFF00" data-f-bold="true"><b>'+ISNULL(CONVERT(VARCHAR,@VEXCEL_SUMA),'')+'</b></td>''
	'
 
	EXEC(@VQUERY)
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-file-invoice-dollar w3-large"></i>&nbsp;&nbsp;Ver Rendición Viáticos</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''816D74E9-0C1C-478A-A699-CF1903A61B23'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
		<div class="w3-panel w3-topbar"></div>
		<div class="w3-panel">
			<span class="w3-bar-item w3-right w3-muhle-text-14">
				<i class="fas fa-user"></i>&nbsp;&nbsp;<b>'+ISNULL(@VRAZON_SOCIAL,'')+'</b>&nbsp;'+'
				<i class="fas fa-project-diagram"></i>&nbsp;&nbsp;<b>'+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,100),'')+'</b>&nbsp;'+'
				<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV,'') = '1' THEN 
							'fas fa-user-tie"'
						WHEN ISNULL(@VTIPO_SERV,'') = '2' THEN 
							'fas fa-chalkboard-teacher"'
						WHEN ISNULL(@VTIPO_SERV,'') = '3' THEN 
							'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE,'')+' - '+ISNULL(@VLUGAR,'')+'</b>
			</span>
		</div>
		<div class="w3-panel">
			<span class="w3-bar-item w3-right w3-muhle-text-14">
				<i class="fas fa-calendar"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
				<i class="fas fa-clock"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
				<i class="fas fa-users"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b>
			</span>
		</div>
		<div class="w3-panel w3-topbar"></div>
		 '
 
	SET @OFOOTER = '</div>
        </div>
    </div>
		<div class="w3-padding">
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="ExportaExcel(); return false;">Exportar</btn>
			<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''816D74E9-0C1C-478A-A699-CF1903A61B23'');return false;">Cancelar</btn>		
		</div>	     
	<script>
		function ExportaExcel(){
		debugger;
			TableToExcel.convert(document.getElementById("table_SP_HOME_VER_RENDICION_4"));
		}
	</script>'
 
END
