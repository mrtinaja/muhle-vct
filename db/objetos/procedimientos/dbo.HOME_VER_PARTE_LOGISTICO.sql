CREATE PROCEDURE [dbo].[HOME_VER_PARTE_LOGISTICO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(MAX) OUTPUT)
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
		@VDESC_ERROR		VARCHAR(4000),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VCONSULTORES_AGENDA_DESC VARCHAR(4000)
 
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
		@VDESC_ENVIO	VARCHAR(400)
 
BEGIN	
 
	SELECT	@VCLIENTE		= ISNULL(CLIENTE,''),
			@VID_PROYECTO	= ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO	= ISNULL(PROYECTO_SERV_ID,''),
			@VAGENDA_ID = ISNULL(AGENDA_ID,''),
			@VERROR = ISNULL(ERROR,''),
			@VCONSULTOR = ISNULL(CONSULTOR_PROV,''),
			@VOBSERV_PL = ISNULL(OBSERVACIONES_PL,''),
			@VPOWER_POINT = ISNULL(POWER_POINT_PL,''),
			@VCORRESP_MAT = ISNULL(CORRESPONDE_MAT_PL,''),
			@VLISTA_MAT = ISNULL(LISTA_MATERIAL_PL,''),
			@VDESC_ENVIO = ISNULL(DESC_ENVIO_PL,'')
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
 
	IF (@VCONSULTOR = '') BEGIN
		
		SELECT	'Debe Seleccionar un Consultor Previamente para Ver el Parte Logisitco' as "<b>Mensaje</b>"
 
	END ELSE BEGIN
 
		SELECT	'<td colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick" data-fill-color="D8E4BC"><b>Descripcion General</b></td>' as 'title=Parte Logístico;data-cols-width="20,20,15,20,15,15,15";data-f-name="Calibri";data-f-sz="26"', '' as "2", '' as "3",'' as "4",'' as "5", '' as "6",'' as "7"
		UNION ALL
		SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Cliente</b></td>', '<td data-fill-color="EBF1DE" colspan="3">'+C.RAZON_SOCIAL_CLIENTE+'</td>', '','','<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fecha Desde</b></td>', '<td data-fill-color="EBF1DE" colspan="2">'+CONVERT(VARCHAR,A.FECHA,103)+'</td>',''
		FROM	LK_AGENDA A
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
		WHERE	ID_AGENDA = @VAGENDA_ID
		UNION ALL
		SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Proyecto</b></td>', '<td data-fill-color="EBF1DE" colspan="3">'+P.NORMA_REF+'</td>', '','','<td data-fill-color="EBF1DE" data-f-bold="true"><b>Fecha Hasta</b></td>', '<td data-fill-color="EBF1DE" colspan="2">'+CONVERT(VARCHAR,A.FECHA_HASTA,103)+'</td>',''
		FROM	LK_AGENDA A
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
		WHERE	ID_AGENDA = @VAGENDA_ID
		UNION ALL
		SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Actividad</b></td>', CASE WHEN A.ID_SERVICIO = '1' THEN '<td data-fill-color="EBF1DE" colspan="3">Consultoria</td>'
								  WHEN A.ID_SERVICIO = '2' THEN '<td data-fill-color="EBF1DE" colspan="3">Auditoria</td>'
								  WHEN A.ID_SERVICIO = '3' THEN '<td data-fill-color="EBF1DE" colspan="3">Capacitacion</td>' END, '','','<td data-fill-color="EBF1DE" data-f-bold="true"><b>Consultor</b></td>', '<td data-fill-color="EBF1DE" colspan="2">'+E.APELLIDO_EMPLEADO + ', ' + E.NOMBRE_EMPLEADO+'</td>',''
		FROM	LK_AGENDA A
				INNER JOIN LK_EMPLEADOS E ON CONVERT(VARCHAR,E.ID_EMPLEADO) = @VCONSULTOR
		WHERE	ID_AGENDA = @VAGENDA_ID
		UNION ALL
		/*SELECT	'<td colspan="7" data-fill-color="CCC0DA" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Materiales de Referencia</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td data-fill-color="E4DFEC" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Corresponde Material?</b></font></td>', '<td colspan="3" data-fill-color="E4DFEC"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+isnull(@VCORRESP_MAT,'')+'</font></td>', '','','<td data-fill-color="E4DFEC" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Power Point</b></font></td>', '<td colspan="2" data-fill-color="E4DFEC"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+isnull(@VPOWER_POINT,'')+'</font></td>',''
		UNION ALL
		SELECT	'<td data-fill-color="E4DFEC" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Lista de Materiales</b></font></td>', '<td colspan="6" data-fill-color="E4DFEC"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+isnull(@VLISTA_MAT,'')+'</font></td>', '','','', '',''
		UNION ALL*/
		SELECT	'<td data-fill-color="EBF1DE" data-f-bold="true"><b>Observaciones</b></td>', '<td colspan="6" data-fill-color="EBF1DE"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+isnull(@VDESC_ENVIO,'')+'</font></td>', '','','', '',''
		UNION ALL
		SELECT	'<td colspan="7" data-fill-color="FCD5B4" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Logistica</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<tr data-height="36.8"><td data-fill-color="FDE9D9" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Concepto</font></td>', '<td data-fill-color="FDE9D9" data-f-bold="true" colspan="3"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Descripcion</font></td>', '','','<td data-fill-color="FDE9D9" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Paga Consultor</font></td>', '<td data-fill-color="FDE9D9" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Paga Consultora</font></td>','<td data-fill-color="FDE9D9" data-f-bold="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Rendicion Cliente</font></td>'
		UNION ALL
		SELECT	'<td data-fill-color="FCD5B4" colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Aereos/Micro</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Cod. Reserva/Nro Vuelo</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Origen/Destino</font></td>', '<td data-fill-color="FDE9D9" colspan="4"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Hora Salida/Llegada</font></td>' ,'', '',''
		UNION ALL
		SELECT	DISTINCT '<td data-fill-color="FDE9D9">'+CONVERT(VARCHAR,D.DET_PROV_FECHA,103)+'</td>', '<td data-fill-color="FDE9D9">'+D.DET_PROV_RESERVA+'('+D.DET_PROV_VUELO+')</td>', '<td data-fill-color="FDE9D9">'+D.DET_PROV_ORIGEN+'-'+D.DET_PROV_DESTINO+'</td>', '<td data-fill-color="FDE9D9">'+D.DET_PROV_SALIDA+'/'+D.DET_PROV_LLEGADA+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTOR+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTORA+'</td>', '<td data-fill-color="FDE9D9">'+D.RENDICION_CLIENTE+'</td>'
		FROM	LK_PROYECTO_VIATICOS V
				LEFT JOIN LK_PROYECTO_VIATICOS_DET D ON V.ID_PROYECTO_VIATICOS = D.ID_PROYECTO_VIATICOS
		WHERE	V.ID_AGENDA = @VAGENDA_ID
		AND		V.ID_CONSULTOR = @VCONSULTOR
		AND		V.TIPO_PROVEEDOR IN ('AVION','MICRO')
		UNION ALL
		SELECT	'<td data-fill-color="FCD5B4" colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Hospedaje</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Nombre Hotel</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Ciudad</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha Ingreso</font></td>', '<td colspan="4" data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha Egreso</font></td>' ,'', '',''
		UNION ALL
		SELECT	DISTINCT CASE WHEN V.ID_PROVEEDOR <> 9999 THEN '<td data-fill-color="FDE9D9">'+ISNULL(P.RAZON_SOCIAL_PROV,'')+'</td>' ELSE '<td data-fill-color="FDE9D9">'+ISNULL(V.DESCRIP_SERVICIO,'')+'</td>' END, '<td data-fill-color="FDE9D9">'+ISNULL(D.DET_PROV_LOCAL,'')+'</td>', '<td data-fill-color="FDE9D9">'+CASE WHEN ISNULL(D.DET_PROV_FINGRESO,'') = '' THEN '' ELSE CONVERT(VARCHAR,D.DET_PROV_FINGRESO,103) END+'</td>', '<td data-fill-color="FDE9D9">'+CASE WHEN ISNULL(D.DET_PROV_FEGRESO,'') = '' THEN '' ELSE CONVERT(VARCHAR,D.DET_PROV_FEGRESO,103) END+'</td>', '<td data-fill-color="FDE9D9">'+ISNULL(D.PAGA_CONSULTOR,'')+'</td>', '<td data-fill-color="FDE9D9">'+ISNULL(D.PAGA_CONSULTORA,'')+'</td>', '<td data-fill-color="FDE9D9">'+ISNULL(D.RENDICION_CLIENTE,'')+'</td>'
		FROM	LK_PROYECTO_VIATICOS V
				LEFT JOIN LK_PROYECTO_VIATICOS_DET D ON V.ID_PROYECTO_VIATICOS = D.ID_PROYECTO_VIATICOS
				LEFT JOIN LK_PROVEEDORES P ON P.ID_PROVEEDOR = V.ID_PROVEEDOR
		WHERE	V.ID_AGENDA = @VAGENDA_ID
		AND		V.ID_CONSULTOR = @VCONSULTOR
		AND		V.TIPO_PROVEEDOR IN ('HOTEL')
		UNION ALL
		SELECT	'<td data-fill-color="FCD5B4" colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Remis</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Origen</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha/Hora Partida</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Destino</font></td>', '<td colspan="4" data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fecha/Hora Llegada</font></td>' ,'', '',''
		UNION ALL
		SELECT	DISTINCT '<td data-fill-color="FDE9D9">'+D.DET_PROV_ORIGEN+'</td>', '<td data-fill-color="FDE9D9">'+CONVERT(VARCHAR,D.DET_PROV_FPARTIDA,103)+' '+isnull(D.DET_PROV_SALIDA,'')+'</td>', '<td data-fill-color="FDE9D9">'+D.DET_PROV_DESTINO+'</td>', '<td data-fill-color="FDE9D9">'+CONVERT(VARCHAR,D.DET_PROV_FLLEGADA,103)+' '+isnull(D.DET_PROV_LLEGADA,'')+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTOR+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTORA+'</td>', '<td data-fill-color="FDE9D9">'+D.RENDICION_CLIENTE+'</td>'
		FROM	LK_PROYECTO_VIATICOS V
				LEFT JOIN LK_PROYECTO_VIATICOS_DET D ON V.ID_PROYECTO_VIATICOS = D.ID_PROYECTO_VIATICOS
		WHERE	V.ID_AGENDA = @VAGENDA_ID
		AND		V.ID_CONSULTOR = @VCONSULTOR
		AND		V.TIPO_PROVEEDOR IN ('REMIS')
		UNION ALL
		SELECT	'<td data-fill-color="FCD5B4" colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-a-s="thick"><b>Alquiler Auto</b></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Inicio del Viaje</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Fin del Viaje</font></td>', '<td data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Desde</font></td>', '<td colspan="4" data-fill-color="FDE9D9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">Hasta</font></td>' ,'', '',''
		UNION ALL
		SELECT	DISTINCT '<td data-fill-color="FDE9D9">'+D.DET_PROV_ORIGEN+'</td>', '<td data-fill-color="FDE9D9">'+D.DET_PROV_DESTINO+'</td>' , '<td data-fill-color="FDE9D9">'+CONVERT(VARCHAR,D.DET_PROV_FPARTIDA,103)+'</td>', '<td data-fill-color="FDE9D9">'+CONVERT(VARCHAR,D.DET_PROV_FLLEGADA,103)+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTOR+'</td>', '<td data-fill-color="FDE9D9">'+D.PAGA_CONSULTORA+'</td>', '<td data-fill-color="FDE9D9">'+D.RENDICION_CLIENTE+'</td>'
		FROM	LK_PROYECTO_VIATICOS V
				LEFT JOIN LK_PROYECTO_VIATICOS_DET D ON V.ID_PROYECTO_VIATICOS = D.ID_PROYECTO_VIATICOS
		WHERE	V.ID_AGENDA = @VAGENDA_ID
		AND		V.ID_CONSULTOR = @VCONSULTOR
		AND		V.TIPO_PROVEEDOR IN ('ALQUILER')
		UNION ALL
		SELECT	'<td data-f-bold="true" data-fill-color="EBF1DE"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Datos Proveedores</b></font></td>', '<td colspan="6" data-fill-color="EBF1DE"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+isnull(@VOBSERV_PL,'')+'</font></td>', '','','', '',''
		UNION ALL
		SELECT	'<td data-b-a-s="thick" colspan="7" data-f-bold="true" data-fill-color="8DB4E2"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Coordinador del Proyecto</b></font></td>', '','','', '','',''
		UNION ALL
		/*SELECT	'<td colspan="2" data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Reviso</b></font></td>', '', '<td colspan="2" data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Comp. Escaneados</b></font></td>','','<td data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Verifico y Facturo</b></td>', '<td colspan="2" data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Comp. Originales</b></font></td>',''
		UNION ALL
		SELECT	'<td colspan="5" data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Detalle</b></font></td>', '', '','','', '<td colspan="2" data-fill-color="C5D9F1"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Observacion</b></font></td>',''
		UNION ALL*/
		SELECT	'<td colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-t-s="thick" data-b-l-s="thick" data-b-r-s="thick" data-f-sz="8" data-f-italic="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Recordar facturar los viaticos a nombre de la consultora con los siguiente datos:</b></font></td>', '', '','','', '',''
		UNION ALL
		SELECT	'<td colspan="7" style="text-align:center;" data-a-h="center" data-f-bold="true" data-b-b-s="thick" data-b-l-s="thick" data-b-r-s="thick" data-f-sz="8" data-f-italic="true"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left"><b>Grupo Vocaturo SRL - CUIT: 30-71132434-4</b></font></td>', '', '','','', '',''
	
	END
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-clipboard-list w3-large"></i>&nbsp;&nbsp;Ver Parte Logístico</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"></i></span>
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
			</div>
        </div>
    </div>'
 
	SET @OFOOTER = '
	<div class="w3-padding">
		<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="ExportaExcel();return false;">Exportar</btn>
		<btn type="btn" class="w3-right w3-border w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');return false;">Cancelar</btn>		
	</div>
	<script>
		function ExportaExcel(){
			TableToExcel.convert(document.getElementById("table_SP_HOME_VER_PARTE_LOGIS_227"));
		}
	</script>'
 
END
