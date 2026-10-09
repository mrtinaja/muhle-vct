CREATE PROCEDURE [dbo].[HOME_INICIO_V360_BK_21/8]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OCLIENTE	AS VARCHAR(MAX) OUTPUT,
 @ODETALLE	AS VARCHAR(MAX) OUTPUT,
 @OBUTTON	AS VARCHAR(MAX) OUTPUT,
 @OPOPUP	AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE @VCUIT			VARCHAR(50),
		@VRAZON_SOCIAL	VARCHAR(300),
		@VCALLE			VARCHAR(100),
		@VNRO			VARCHAR(30),
		@VPISO			VARCHAR(30),
		@VLOCALIDAD		VARCHAR(100),
		@VPROVINCIA		VARCHAR(50),
		@VTELEFONO1		VARCHAR(100),
		@VTELEFONO2		VARCHAR(100),
		@VEMAIL			VARCHAR(100),
		@VIVA			VARCHAR(50),
		@VCONTACTO		VARCHAR(4000),
		@VTIPO_CLIENTE	VARCHAR(50),
		@VESTADO		VARCHAR(50),
		@VOBSERVACIONES	VARCHAR(400),
		@VDIRECCION		VARCHAR(MAX),
		@VOBSERV_HR		VARCHAR(MAX)
 
DECLARE	@VCLIENTE			VARCHAR(100), 
		@VID_PROYECTO		VARCHAR(100),
		@VID_SERVICIO		VARCHAR(100),
		@VID_AGENDA_SELEC	VARCHAR(100),
		@VCANT_PROY_ABI		INT,
		@VCANT_PROY_CER		INT,
		@VCANT_SERVICIOS	INT,
		@VNOMBRE_PROY		VARCHAR(MAX),
		@VNOMBRE_SERV_SELEC	VARCHAR(MAX),
		@VLUGAR_SERV_SELEC	VARCHAR(MAX),
		@VTIPO_SERV_SELEC	VARCHAR(MAX),
		@VFECHA_INI_SELEC	DATETIME,
		@VFECHA_FIN_SELEC	DATETIME,
		@VHORAS_SELEC		VARCHAR(MAX),
		@VMONTO_SELEC		VARCHAR(MAX),
		@VCIERRE_SELEC		VARCHAR(MAX),
		@VNOMBRE_SERV_TMT	VARCHAR(MAX),
		@VLUGAR_SERV_TMT	VARCHAR(MAX),
		@VTIPO_SERV_TMT		VARCHAR(MAX),
		@VFECHA_INI_TMT		DATETIME,
		@VFECHA_FIN_TMT		DATETIME,
		@VHORAS_TMT			VARCHAR(MAX),
		@VMONTO_TMT			VARCHAR(MAX),
		@VCIERRE_TMT		VARCHAR(MAX),
		@VTAB				VARCHAR(100),
		@VTAB_SERV			VARCHAR(100),
		@VTAB_AGENDA		VARCHAR(100),
		@VTABLA				VARCHAR(MAX),
		@VTABLA_DET			VARCHAR(MAX),
		@VDESC_ERROR		VARCHAR(MAX),
		@VCLAVE_DELETE		VARCHAR(100),
		@PageNumber			INT,
		@VSUBTOTAL			NUMERIC(36,2),
		@VTOTAL_PAGINA		INT,
		@VTOTAL				INT,
		@VIZQUIERDA			VARCHAR(MAX),
		@VPAGINADO			VARCHAR(MAX),
		@VDERECHA			VARCHAR(MAX),
		@VPAGINAS			VARCHAR(MAX),
		@VACTUAL			INT,
		@VPREVIUS			VARCHAR(50),
		@VAGENDA_CONSULTOR	VARCHAR(50),
		@VSTRUCTURE			VARCHAR(100),
		@VEXPORTA_DET		VARCHAR(50),
		@VID_DOCUM			VARCHAR(50),
		@VMINUTA_DESC		VARCHAR(400)
 
DECLARE @vproyecto			varchar(max),
		@vobs				varchar(max),
		@vestado_proy		varchar(max),
		@vnormas			varchar(max),
		@vfechaini			varchar(max),
		@vfechafin			varchar(max),
		@vhoras				varchar(max),
		@vopciones			varchar(max),
		@vinfo				varchar(max)
 
DECLARE @VER_SERVICIOS		VARCHAR(50),
		@VID_PROYECTO_SERV	VARCHAR(MAX),
		@VTIPO_SERVICIO		varchar(max), 
		@VHORAS_SERV_EJEC	varchar(max), 
		@VFECHA_INI_SERV	varchar(max), 
		@VFECHA_FIN_SERV	varchar(max), 
		@VCIERRE			varchar(max), 
		@VNOMBRE_SERV		varchar(max), 
		@VLUGAR_SERV		varchar(max),
		@VHORAS_SERV		varchar(max),
		@VID_SERV_DELETE	VARCHAR(100),
		@VCANT_AGENDAS		INT,
		@VMENSAJE			varchar(4000)
 
DECLARE @VARCLIENTE			varchar(max), 
		@VARPROYECTO		varchar(max), 
		@VARNORMA			varchar(max), 
		@VARFECHAD			varchar(max), 
		@VARFECHAH			varchar(max), 
		@VARPROFESIONAL		varchar(max), 
		@VAROBSERVACIONES	varchar(max), 
		@VID_AGENDA			varchar(max), 
		@VARSERVICIO		varchar(max), 
		@VARDIAS			varchar(max), 
		@VAROBS_HR			varchar(max), 
		@VAROBS_CALIF		varchar(max), 
		@VAROBS_LOGIS		varchar(max), 
		@VARHORAS			varchar(max),
		@VSTATUS			varchar(max),
		@VARESTADO			varchar(max),
		@VCANT_AGENDA		INT
 
DECLARE @VFRECUENCIA		VARCHAR(50),
		@VDOC_EMPRESA		VARCHAR(50),
		@VMANUAL_DOC		VARCHAR(50),
		@VREQ_INGRESO		VARCHAR(50),
		@VCV_CERTIF			VARCHAR(50),
		@VLOGISTICA			VARCHAR(50),
		@VCURSO				VARCHAR(300),
		@VMATERIAL			VARCHAR(50),
		@VESTADO_ENVIO		VARCHAR(50),
		@VRECIBIDO			VARCHAR(50),
		@VCANT_SEG			INT
 
DECLARE @VFECHA_MINUTA		VARCHAR(50),
		@VNOMBRE			VARCHAR(300),
		@VOBSERV_MINUTA		VARCHAR(400),
		@VACCION			VARCHAR(MAX),
		@VFECHA_PLAN		VARCHAR(50),
		@VOBSERV_PLAN		VARCHAR(400),
		@VESTADO_ANEXO		VARCHAR(400),
		@VCANT_MC			INT,
		@VCANT_PE			INT,
		@VCANT_PA			INT,
		@VCANT_IA			INT,
		@VCANT_IC			INT
 
--AGENDA--
DECLARE @VNORMA_AGENDA		VARCHAR(4000),
		@VFECHAD_AGENDA		VARCHAR(50),
		@VFECHAH_AGENDA		VARCHAR(50),
		@VDIAS_AGENDA		VARCHAR(50),
		@VHORAS_AGENDA		VARCHAR(50),
		@VESTADO_AGENDA		VARCHAR(100),
		@VESTADO_AGENDA_CODE VARCHAR(50),
		@VOBSERV_CALIF_AGENDA VARCHAR(400),
		@VOBSERV_AGENDA		VARCHAR(400),
		@VCONSULTORES_AGENDA VARCHAR(400),
		@VCONSULTORES_AGENDA_DESC VARCHAR(400),
		@lstDato			VARCHAR(100), 
		@lnuPosComa			INT,
		@VALOR				VARCHAR(400),
		@VDESCNORMAS		VARCHAR(4000)
 
DECLARE @DIF_HORAS_SERV		INT,
		@HORAS_SERV			INT,
		@HORAS_CARGADAS_SERV INT
 
DECLARE @VTIPO_SERV_ANEXO	VARCHAR(50),
		@VSERVICIO_ANEXO	VARCHAR(50),
		@VANEXO_SERV_ID		VARCHAR(50),
		@VDESC_SERV_ANEXO	VARCHAR(400)
 
DECLARE	@VUSUARIO			VARCHAR(100)
 
DECLARE @VMONTO_PRES_TMT	NUMERIC(15,2) = 0,
		@VMONTO_PRES_VIAT_TMT	NUMERIC(15,2) = 0,
		@VCOSTO_MO_TMT		NUMERIC(15,2) = 0,
		@VCOSTO_VIAT_TMT	NUMERIC(15,2) = 0,
		@VCOSTO_VARIOS_TMT	NUMERIC(15,2) = 0,
		@VMONTO_TOTAL_TMT	NUMERIC(15,2) = 0,
		@VCOSTO_TOTAL_TMT	NUMERIC(15,2) = 0,
		@VFECHA_PRESUP_TMT	DATE,
		@VCOMENTARIO_TMT	VARCHAR(4000),
		@VPERIODO_TMT		VARCHAR(50),
		@VVENTAS_TMT		NUMERIC(15,2) = 0,
		@VCOMPRAS_TMT		NUMERIC(15,2) = 0
 
-- VARIABLES PARA PRESUPUESTO Y RENTABILIDAD
DECLARE @VMONTO_PRES		NUMERIC(15,2) = 0,
		@VMONTO_PRES_VIAT	NUMERIC(15,2) = 0,
		@VCOSTO_MO			NUMERIC(15,2) = 0,
		@VCOSTO_VIAT		NUMERIC(15,2) = 0,
		@VCOSTO_VARIOS		NUMERIC(15,2) = 0,
		@VMONTO_TOTAL		NUMERIC(15,2) = 0,
		@VCOSTO_TOTAL		NUMERIC(15,2) = 0,
		@VFECHA_PRESUP		DATE,
		@VCOMENTARIO		VARCHAR(4000)
 
-- VARIABLES PARA GRÁFICO EVOLUTIVO (TAB_SERV = 11)
DECLARE @VMARGEN_ESTIMADO_PROY NUMERIC(15,2) = 0,
        @VLABELS_PERIODOS      VARCHAR(MAX) = '',
        @VDATA_RENT_PERIODOS   VARCHAR(MAX) = '',
        @VDATA_PROMEDIO        VARCHAR(MAX) = '',
        @VDATA_ESTIMADO        VARCHAR(MAX) = '',
        @VTOTAL_RENTA_ACUM     NUMERIC(15,2) = 0,
        @VCANT_PERIODOS_TOTAL  INT = 0,
        @VPROMEDIO_RENTA       NUMERIC(15,2) = 0
				
BEGIN	
 
	SELECT	@VCLIENTE = ISNULL(CLIENTE,''),
			@VID_PROYECTO =	ISNULL(PROYECTO_ID,''),
			@VID_SERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VID_AGENDA_SELEC = ISNULL(AGENDA_ID,''),
			@VTAB = ISNULL(TAB,''), 
			@VTAB_SERV = ISNULL(TAB_SERV,''), 
			@VTAB_AGENDA = ISNULL(TAB_AGENDA,''), 
			@VDESC_ERROR = ISNULL(DESC_ERROR,''),
			@VFECHA_INI_TMT = ISNULL(FECHA_INICIO_SERV,''),
			@VFECHA_FIN_TMT = ISNULL(FECHA_FIN_SERV,''),
			@VHORAS_TMT = ISNULL(HORAS_SERV,''),
			@VMONTO_TMT = REPLACE(ISNULL(MONTO_SERV,'0'),'.',''),
			@VNOMBRE_SERV_TMT = ISNULL(NOMBRE_SERV,''),
			@VLUGAR_SERV_TMT = ISNULL(LUGAR_SERV,''),
			@VCIERRE_TMT = ISNULL(CIERRE_SERVICIO,''),
			@VCLAVE_DELETE = ISNULL(CLAVE_DELETE,''),
			@PageNumber	= (CONVERT(INT,ISNULL(NRO_PAGINA,0))),
			@VPREVIUS = ISNULL(PREVIUS,''),
			@VAGENDA_CONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			@VID_SERV_DELETE = ISNULL(ID_SERV_DELETE,''),
			@VEXPORTA_DET = ISNULL(EXPORTA_MG,''),
			@VTIPO_SERV_ANEXO = ISNULL(AGENDA_ESTADO,''), 
			@VSERVICIO_ANEXO = ISNULL(AGENDA_DESC,''), 
			@VUSUARIO = ISNULL(TS_USER_ID,''),
			@VMONTO_PRES_TMT		= ISNULL(DECIMAL_01, 0),
			@VMONTO_PRES_VIAT_TMT	= ISNULL(DECIMAL_02, 0),
			@VCOSTO_MO_TMT			= ISNULL(DECIMAL_03, 0),
			@VCOSTO_VIAT_TMT		= ISNULL(DECIMAL_04, 0),
			@VCOSTO_VARIOS_TMT		= ISNULL(DECIMAL_05, 0),
			@VFECHA_PRESUP_TMT		= ISNULL(FECHA_FACTURA_PROV,''),
			@VCOMENTARIO_TMT		= ISNULL(ACUMULA_VIATICO,''),
			@VPERIODO_TMT			= ISNULL(PERIODO,''),
			@VVENTAS_TMT			= ISNULL(DECIMAL_06, 0),
            @VCOMPRAS_TMT			= ISNULL(DECIMAL_07, 0)
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VEXPORTA_DET = '') BEGIN
		SET @VEXPORTA_DET = '0|1'
	END
 
	IF (@VID_SERVICIO <> '') BEGIN
 
		SELECT	@HORAS_SERV = TOTAL_HORAS_PROYECTADAS,
				@HORAS_CARGADAS_SERV = ISNULL(CONVERT(VARCHAR,[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, ID_PROYECTO_SERVICIO)),'0')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
		SET @DIF_HORAS_SERV = @HORAS_SERV - @HORAS_CARGADAS_SERV
 
	END
 
	IF (@VAGENDA_CONSULTOR = '') BEGIN
		SET @VSTRUCTURE = '522967A7-DDC9-465B-969B-85997AE1B085'
	END ELSE BEGIN
		SET @VSTRUCTURE = '59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'
		UPDATE XAGENDA SET PREVIUS = NULL WHERE PAR_KEY = @IPKEYJOB
	END
 
	IF (@VTAB = '') BEGIN
		SET @VTAB = '0'
	END
 
	SET @VCANT_PROY_ABI = 0
	SET @VCANT_PROY_CER = 0
	SET @VCANT_SERVICIOS = 0
	SET @VTOTAL = 0 
 
	SELECT	@VCANT_PROY_ABI = COUNT(*)
	FROM	LK_PROYECTO P
	WHERE	P.ID_CLIENTE = @VCLIENTE
	AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'	
 
	SELECT	@VCANT_PROY_CER = COUNT(*)
	FROM	LK_PROYECTO P
	WHERE	P.ID_CLIENTE = @VCLIENTE
	AND		P.ESTADO_PROYECTO_TOTAL = 'TERMINADO'
 
	IF (@VID_PROYECTO <> '') BEGIN
 
		SELECT	@VCANT_SERVICIOS = COUNT(1)
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
		SELECT	@VNOMBRE_PROY = '('+CODIGO+') - '+NORMA_REF
		FROM	LK_PROYECTO P
		WHERE	P.ID_CLIENTE = @VCLIENTE
		AND		P.ID_PROYECTO = @VID_PROYECTO
	END
 
	IF (@VID_SERVICIO <> '') BEGIN
		
		SELECT	@VTIPO_SERV_SELEC = ID_TIPO_SERVICIO,
				@VNOMBRE_SERV_SELEC = ISNULL(NOMBRE,''),
				@VLUGAR_SERV_SELEC = ISNULL(LUGAR,''),
				@VFECHA_INI_SELEC = FECHA_INICIO_REAL,
				@VFECHA_FIN_SELEC = NULLIF(ISNULL(FECHA_FIN_REAL,''),''),
				@VHORAS_SELEC = TOTAL_HORAS_PROYECTADAS,
				@VMONTO_SELEC = MONTO_PRESUP,
				@VCIERRE_SELEC = ISNULL(CIERRE,'NO')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
		IF (@VDESC_ERROR = '') BEGIN
			SET @VFECHA_INI_TMT = @VFECHA_INI_SELEC
			SET @VFECHA_FIN_TMT = @VFECHA_FIN_SELEC
			SET @VHORAS_TMT = @VHORAS_SELEC
			SET @VMONTO_TMT = @VMONTO_SELEC
			SET @VNOMBRE_SERV_TMT = @VNOMBRE_SERV_SELEC
			SET @VLUGAR_SERV_TMT = @VLUGAR_SERV_SELEC
			SET @VCIERRE_TMT = @VCIERRE_SELEC
		END
	END
 
	SET @VMENSAJE = ''
 
	IF (@VID_SERV_DELETE = 'RENTA') BEGIN
		
		UPDATE	LK_PROYECTO
		SET		MONTO_PRES = @VMONTO_PRES_TMT,
				MONTO_PRES_VIAT = @VMONTO_PRES_VIAT_TMT,
				COSTO_MO = @VCOSTO_MO_TMT,
				COSTO_VIAT = @VCOSTO_VIAT_TMT,
				COSTO_VARIOS = @VCOSTO_VARIOS_TMT,
				MONTO_TOTAL = @VMONTO_PRES_TMT + @VMONTO_PRES_VIAT_TMT,
				COSTO_TOTAL = @VCOSTO_MO_TMT + @VCOSTO_VIAT_TMT + @VCOSTO_VARIOS_TMT,
				OBSERV_RENTA = @VCOMENTARIO_TMT,
				FECHA_PRESUPUESTO = @VFECHA_PRESUP_TMT
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
	END ELSE BEGIN
 
		IF (@VID_SERV_DELETE = 'PERIODO') BEGIN
 
			DELETE	LK_PROYECTO_RENTABILIDAD
			WHERE	ID_PROYECTO = @VID_PROYECTO
			AND		PERIODO		= @VPERIODO_TMT
 
			INSERT INTO LK_PROYECTO_RENTABILIDAD
			SELECT	@VID_PROYECTO, @VPERIODO_TMT, @VVENTAS_TMT, @VCOMPRAS_TMT,
					GETDATE(), @VUSUARIO
 
		END ELSE BEGIN
 
			IF (@VID_SERV_DELETE <> '') BEGIN
		
				SET @VCANT_AGENDAS = 0
 
				SELECT	@VCANT_AGENDAS = COUNT(1)
				FROM	LK_AGENDA
				WHERE	PROYECTO_SERV_ID = @VID_SERV_DELETE
		
				IF (@VCANT_AGENDAS = 0) BEGIN
					DELETE	LK_PROYECTO_SERVICIO
					WHERE	ID_PROYECTO_SERVICIO = @VID_SERV_DELETE
				END ELSE BEGIN
					SET @VMENSAJE = 
					'<script>
						alert("NO Puede Eliminar el Servicio si el mismo tiene Visitas Cargadas");
					</script>'
				END
			END
		END
	END
 
	SELECT	@VCUIT = ISNULL(CUIT_CLIENTE,''),
			@VRAZON_SOCIAL	= ISNULL(RAZON_SOCIAL_CLIENTE,''),
			@VCALLE = ISNULL(CALLE_CLIENTE,''),
			@VNRO = ISNULL(NRO_CALLE_CLIENTE,''),
			@VPISO = ISNULL(PISO_DEPTO_CLIENTE,''),
			@VLOCALIDAD = ISNULL(LOCALIDAD_CLIENTE,''),
			@VPROVINCIA = ISNULL(PROVINCIA_CLIENTE,''),
			@VTELEFONO1 = ISNULL(TEL1_CLIENTE,''),
			@VTELEFONO2 = ISNULL(TEL2_CLIENTE,''),
			@VEMAIL = ISNULL(EMAIL_CLIENTE,''),
			@VIVA = ISNULL(IVA_CLIENTE,''),
			@VTIPO_CLIENTE = ISNULL(TIPO_CLIENTE,''),
			@VESTADO = ISNULL(STATUS_CLIENTE,''),
			@VOBSERVACIONES = ISNULL(OBSERV_CLIENTE,''),
			@VCONTACTO = ISNULL(CONTACTO_CLIENTE,'')
	FROM	LK_CLIENTES
	WHERE	ID_CLIENTE = @VCLIENTE
	
	SET @VDIRECCION = ISNULL(@VCALLE,'') + ' ' + ISNULL(@VNRO,'') + ' / ' +
					  ISNULL(@VLOCALIDAD,'') + ' - ' + ISNULL(@VPROVINCIA,'')
	
	IF (@VTAB = '0') BEGIN
		
		SET @VTOTAL = @VCANT_PROY_ABI
		SELECT	@VSUBTOTAL = cast(round(@VCANT_PROY_ABI/5.0,2) as numeric(36,2))
 
		IF (SUBSTRING(CONVERT(VARCHAR,@VSUBTOTAL),
			CHARINDEX('.',CONVERT(VARCHAR,@VSUBTOTAL)) +1,
			LEN(CONVERT(VARCHAR,@VSUBTOTAL)))) = '00' BEGIN
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_PROY_ABI/5)
		END ELSE BEGIN
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_PROY_ABI/5)+1
		END
 
		SET @VTABLA = '
				<table id="Table1" class="w3-table w3-card-4 w3-muhle-text-11">
					<tr style="background-color:gray;color:white;">
						<th><div class="w3-left"></div></th>
						<th><div class="w3-left">Proyecto</div></th>
						<th><div class="w3-center">Estado</div></th>
						<th><div class="w3-center">Normas</div></th>
						<th><div class="w3-center">Inicio</div></th>
						<th><div class="w3-center">Fin</div></th>
						<th><div class="w3-center">Horas</div></th>
						<th><div class="w3-center">Opciones</div></th>
					</tr>'
 
		DECLARE Proyectos CURSOR FOR
		SELECT	'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-cogs" style="cursor:pointer;color:black;" title="Servicios" 
						onclick="'+CASE WHEN [dbo].[FN_GET_OBLIGA_MINUTA_GESTION] (CONVERT(VARCHAR,ID))  = 'NO' THEN 
								'almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''TAB_SERV'','''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,ID)+''');
								 almacenarSeleccion(''PROYECTO_SERV_ID'','''');
								 almacenarSeleccion(''AGENDA_ID'','''');
								 goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;' ELSE 'return false;' END+'"></i>' + '&nbsp;' +
					CASE WHEN (ISNULL(PROYECTOS.MINUTA_GESTION,'') <> '') THEN
						'<i class="fas fa-book" style="cursor:pointer;color:'+CASE WHEN [dbo].[FN_GET_OBLIGA_MINUTA_GESTION] (CONVERT(VARCHAR,ID))  = 'NO' THEN 'green' ELSE 'red' END +';" title="Minuta de Gestion" 
							onclick="almacenarSeleccion(''TAB'',''0'');
									 almacenarSeleccion(''TAB_SERV'',''8'');
									 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,ID)+''');
									 almacenarSeleccion(''PROYECTO_SERV_ID'','''');
									 almacenarSeleccion(''AGENDA_ID'','''');
									 goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"></i>'
					ELSE 
						'<i class="fas fa-book" style="cursor:pointer;color:gray;" title="Minuta de Gestion" onclick="return false;"></i>'
					END + '</div>'																		AS Info,
				'<div class="w3-left w3-muhle-text-11">'+PROYECTO+ '</div>'								AS Proyecto, 
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(ESTADO_DESC,'Sin Estado')+ '</div>'	AS Estado, 
				'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-info-circle" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',NORMAS,''),'</br>',char(10))+'"></i>' 
				+ '</div>'	AS Normas,
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_INICIO,103)+ '</div>'						AS "Fecha Inicio", 
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_FIN,103)+ '</div>'							AS "Fecha Fin", 
				'<div class="w3-center w3-muhle-text-11">'+HORASP+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', ID, NULL, NULL)+ '</div>' AS "Horas",
				'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-edit" style="cursor:pointer;color:black;" title="Modificar" onclick="almacenarSeleccion(''PROYECTO_ID'','''+cast(ID as varchar)+''');goto('''+@FORM_ID+''',''4049307F-6C13-459D-AC01-54F97D942D1B'');return false;"></i>&nbsp;'+
					CASE WHEN ISNULL(NRO_COTIZA,0) <> 0 THEN 
						'<i class="fas fa-file-word" style="cursor:pointer;color:blue;" title="Ver Propuesta" onclick="OpenAttach('''+ISNULL(ID_ADJUNTO,'')+''','''+ISNULL(ATACH_COTIZ.FILE_NAME,'')+''');return false;"></i>'  
					ELSE '' END + '&nbsp;' +
					CASE WHEN ISNULL(SUM(A.DIAS),0) = 0 THEN 
						'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar Proyecto'+ '" 
						onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Proyecto?'');
						if (confirmar){almacenarSeleccion(''ID_DELETE'','''+cast(ID as varchar)+ ''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');}"/>'
					ELSE ''
					END + '</div>' AS Opciones
		FROM	
			(
			SELECT DISTINCT CLI.RAZON_SOCIAL_CLIENTE						AS RAZON_SOCIAL,
					'('+CODIGO+') - '+NORMA_REF								AS PROYECTO,
					CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)				AS FECHA_INICIO,
					CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END	AS FECHA_FIN,
					CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)				AS HORASP,
					P.ID_PROYECTO							 AS ID,
					P.ID_CLIENTE							 AS CLIENTE,
					ESTADO_PROYECTO_TOTAL					 AS ESTADO,
					CD.CAT_DATA_DESC						 AS ESTADO_DESC,
					NORMAS									 AS NORMAS,
					P.OBSERVACIONES							 AS OBSERV,
					P.ID_COTIZACION							 AS NRO_COTIZA,
					C.ID_ADJUNTO							 AS ID_ADJUNTO,
					(SELECT 1 FROM LK_PROYECTO_DOCUM WHERE	ID_PROYECTO = P.ID_PROYECTO AND TIPO = 'MG') AS MINUTA_GESTION
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					LEFT JOIN LK_COTIZACIONES C ON C.ID_COTIZACION = P.ID_COTIZACION
			WHERE	P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
			AND		P.ID_CLIENTE = @VCLIENTE
			) PROYECTOS 
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT ATACH_COTIZ ON ATACH_COTIZ.PKEY = PROYECTOS.ID_ADJUNTO
			LEFT JOIN LK_AGENDA A ON A.ID_CLIENTE = PROYECTOS.CLIENTE AND A.ID_PROYECTO = PROYECTOS.ID
			GROUP BY RAZON_SOCIAL, PROYECTO, OBSERV, PROYECTOS.ESTADO, NORMAS, FECHA_INICIO, FECHA_FIN, HORASP, ID, PROYECTOS.CLIENTE, NRO_COTIZA, ID_ADJUNTO, ESTADO_DESC,ATACH_COTIZ.FILE_NAME, MINUTA_GESTION
		ORDER BY CONVERT(DATETIME,FECHA_INICIO,103) DESC
		OFFSET @PageNumber*5 ROWS FETCH NEXT 5 ROWS ONLY
 
		OPEN Proyectos
		FETCH NEXT FROM Proyectos INTO @vinfo, @vproyecto, @vestado_proy, @vnormas, @vfechaini, @vfechafin, @vhoras, @vopciones
	
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				
				SET	@VTABLA = isnull(@VTABLA,'') +
				'<tr>
					<td>'+ISNULL(@vinfo,'')+'</td>
					<td>'+ISNULL(@vproyecto,'')+'</td>
					<td>'+ISNULL(@vestado_proy,'')+'</td>
					<td>'+ISNULL(@vnormas,'')+'</td>
					<td>'+ISNULL(@vfechaini,'')+'</td>
					<td>'+ISNULL(@vfechafin,'')+'</td>
					<td>'+ISNULL(@vhoras,'')+'</td>
					<td>'+ISNULL(@vopciones,'')+'</td>
 
				</tr>'
 
				FETCH NEXT FROM Proyectos INTO @vinfo, @vproyecto, @vestado_proy, @vnormas, @vfechaini, @vfechafin, @vhoras, @vopciones
			END 
 
		CLOSE Proyectos  
		DEALLOCATE Proyectos	
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTAB = '1') BEGIN
		
		SET @VTOTAL = @VCANT_SERVICIOS
 
		SELECT	@VSUBTOTAL = cast(round(@VCANT_SERVICIOS/5.0,2) as numeric(36,2))
 
		IF (SUBSTRING(CONVERT(VARCHAR,@VSUBTOTAL),
			CHARINDEX('.',CONVERT(VARCHAR,@VSUBTOTAL)) +1,
			LEN(CONVERT(VARCHAR,@VSUBTOTAL)))) = '00' BEGIN
 
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_SERVICIOS/5)
		END ELSE BEGIN
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_SERVICIOS/5)+1
		END
 
		SET @VTABLA = '
				<table id="Table1" class="w3-table w3-card-4 w3-muhle-text-11">
					<tr style="background-color:gray;color:white;">
						<th><div class="w3-center"></div></th>
						<th><div class="w3-left">Nombre</div></th>
						<th><div class="w3-left">Lugar</div></th>
						<th><div class="w3-center">Inicio</div></th>
						<th><div class="w3-center">Fin</div></th>
						<th><div class="w3-center">Horas</div></th>
						<th><div class="w3-center">Cierre</div></th>
						<th><div class="w3-center">Opciones</div></th>
					</tr>'
 
		DECLARE Servicios CURSOR FOR 
			SELECT	CASE WHEN [dbo].[FN_GET_OBLIGA_MINUTA_GESTION] (CONVERT(VARCHAR,ID_PROYECTO))  = 'NO' THEN 'SI' ELSE 'NO' END,
					ID_PROYECTO_SERVICIO ID_SERVICIO,
					ID_TIPO_SERVICIO TIPO_SERVICIO, 
					ISNULL(CONVERT(VARCHAR,[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('PS', NULL, NULL, ID_PROYECTO_SERVICIO)),'0') HORAS,
					ISNULL(CONVERT(VARCHAR,FECHA_INICIO_REAL,103),''),
					NULLIF(ISNULL(CONVERT(VARCHAR,FECHA_FIN_REAL,103),''),''),
					ISNULL(CONVERT(VARCHAR,TOTAL_HORAS_PROYECTADAS),'0'),
					CASE WHEN CIERRE IS NULL THEN 'NO' ELSE CIERRE END,
					ISNULL(NOMBRE,''),
					ISNULL(LUGAR,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO = @VID_PROYECTO
			ORDER BY CONVERT(DATETIME,FECHA_INICIO_REAL,103) DESC
			OFFSET @PageNumber*5 ROWS FETCH NEXT 5 ROWS ONLY
			
		OPEN Servicios  
		FETCH NEXT FROM Servicios INTO @VER_SERVICIOS, @VID_PROYECTO_SERV, @VTIPO_SERVICIO, @VHORAS_SERV_EJEC, @VFECHA_INI_SERV, @VFECHA_FIN_SERV, @VHORAS_SERV, @VCIERRE, @VNOMBRE_SERV, @VLUGAR_SERV
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
				SET	@VTABLA = isnull(@VTABLA,'') +
					'<tr>
						<td>
							<div class="w3-center w3-muhle-text-12"><i class="'+ CASE WHEN @VTIPO_SERVICIO = '1' THEN 
									'fas fa-user-tie"'
								WHEN @VTIPO_SERVICIO = '2' THEN 
									'fas fa-chalkboard-teacher"'
								WHEN @VTIPO_SERVICIO = '3' THEN 
									'fas fa-user-graduate"' END+
								'style="cursor:pointer;" title="'+	CASE WHEN @VTIPO_SERVICIO = '1' THEN 
															'Consultoria"'
														WHEN @VTIPO_SERVICIO = '2' THEN 
															'Auditoria"'
														WHEN @VTIPO_SERVICIO = '3' THEN 
															'Capacitacion"' END+ ' onclick="'+CASE WHEN @VER_SERVICIOS = 'NO' THEN 'return false;' 
																								ELSE
																								'almacenarSeleccion(''TAB_SERV'',''0'');
																								almacenarSeleccion(''PROYECTO_SERV_ID'','''+CONVERT(VARCHAR,@VID_PROYECTO_SERV)+''');
																								almacenarSeleccion(''AGENDA_ID'','''');
																								goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;' END +'"></i>'+'</div></td>
						<td><div class="w3-left w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END + ISNULL(@VNOMBRE_SERV,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-left w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +ISNULL(@VLUGAR_SERV,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-center w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +ISNULL(@VFECHA_INI_SERV,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-center w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +ISNULL(@VFECHA_FIN_SERV,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-center w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +ISNULL(@VHORAS_SERV,'')+'/'+ISNULL(@VHORAS_SERV_EJEC,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-center w3-muhle-text-11 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +ISNULL(@VCIERRE,'')+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+'</div></td>
						<td><div class="w3-center w3-muhle-text-12 '+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN 'w3-muhle-vocaturo' ELSE 'black' END+';">'+CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '<b>' ELSE '' END +
							'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
							onclick="confirmar=confirm(''¿Esta seguro que quiere Eliminar el Servicio?'');
							if (confirmar){almacenarSeleccion(''ID_SERV_DELETE'','''+@VID_PROYECTO_SERV+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>'+
							CASE WHEN @VID_SERVICIO = CONVERT(VARCHAR,@VID_PROYECTO_SERV) THEN '</b>' ELSE '' END+
						'</div></td>
					</tr>'
					
			FETCH NEXT FROM Servicios INTO @VER_SERVICIOS, @VID_PROYECTO_SERV, @VTIPO_SERVICIO, @VHORAS_SERV_EJEC, @VFECHA_INI_SERV, @VFECHA_FIN_SERV, @VHORAS_SERV, @VCIERRE, @VNOMBRE_SERV, @VLUGAR_SERV
		END 
 
		CLOSE Servicios  
		DEALLOCATE Servicios
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
	IF (@VTAB = '2') BEGIN
		
		SET @VTOTAL = @VCANT_PROY_CER
 
		SELECT	@VSUBTOTAL = cast(round(@VCANT_PROY_CER/5.0,2) as numeric(36,2))
 
		IF (SUBSTRING(CONVERT(VARCHAR,@VSUBTOTAL),
			CHARINDEX('.',CONVERT(VARCHAR,@VSUBTOTAL)) +1,
			LEN(CONVERT(VARCHAR,@VSUBTOTAL)))) = '00' BEGIN
 
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_PROY_CER/5)
		END ELSE BEGIN
			SET @VTOTAL_PAGINA = FLOOR(@VCANT_PROY_CER/5)+1
		END
 
		SET @VTABLA = '
				<table id="Table1" class="w3-table w3-card-4 w3-muhle-text-11">
					<tr style="background-color:gray;color:white;">
						<th><div class="w3-left"></div></th>
						<th><div class="w3-left">Proyecto</div></th>
						<th><div class="w3-center">Estado</div></th>
						<th><div class="w3-center">Normas</div></th>
						<th><div class="w3-center">Inicio</div></th>
						<th><div class="w3-center">Fin</div></th>
						<th><div class="w3-center">Horas</div></th>
						<th><div class="w3-center">Opciones</div></th>
					</tr>'
 
		DECLARE Proyectos CURSOR FOR
		SELECT	'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-cogs" style="cursor:pointer;color:black;" title="Servicios" 
						onclick="'+CASE WHEN [dbo].[FN_GET_OBLIGA_MINUTA_GESTION] (CONVERT(VARCHAR,ID))  = 'NO' THEN 
								'almacenarSeleccion(''TAB'',''1'');
								 almacenarSeleccion(''TAB_SERV'','''');
								 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,ID)+''');
								 almacenarSeleccion(''PROYECTO_SERV_ID'','''');
								 almacenarSeleccion(''AGENDA_ID'','''');
								 goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;' ELSE 'return false;' END+'"></i>' + '&nbsp;' +
					CASE WHEN (ISNULL(PROYECTOS.MINUTA_GESTION,'') <> '') THEN
						'<i class="fas fa-book" style="cursor:pointer;color:'+CASE WHEN [dbo].[FN_GET_OBLIGA_MINUTA_GESTION] (CONVERT(VARCHAR,ID))  = 'NO' THEN 'green' ELSE 'red' END +';" title="Minuta de Gestion" 
							onclick="almacenarSeleccion(''TAB'',''0'');
									 almacenarSeleccion(''TAB_SERV'',''8'');
									 almacenarSeleccion(''PROYECTO_ID'','''+CONVERT(VARCHAR,ID)+''');
									 almacenarSeleccion(''PROYECTO_SERV_ID'','''');
									 almacenarSeleccion(''AGENDA_ID'','''');
									 goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"></i>'
					ELSE 
						'<i class="fas fa-book" style="cursor:pointer;color:gray;" title="Minuta de Gestion" onclick="return false;"></i>'
					END + '</div>'																		AS Info,
				'<div class="w3-left w3-muhle-text-11">'+PROYECTO+ '</div>'							AS Proyecto, 
				'<div class="w3-center w3-muhle-text-11">'+ISNULL(ESTADO_DESC,'Sin Estado')+ '</div>'	AS Estado, 
				'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-info-circle" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',NORMAS,''),'</br>',char(10))+'"></i>' 
				+ '</div>'	AS Normas,
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_INICIO,103)+ '</div>'						AS "Fecha Inicio", 
				'<div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FECHA_FIN,103)+ '</div>'							AS "Fecha Fin", 
				'<div class="w3-center w3-muhle-text-11">'+HORASP+'/'+[dbo].[FN_GET_TOTAL_HS_EJECUTADAS] ('P', ID, NULL, NULL)+ '</div>' AS "Horas",
				'<div class="w3-center w3-muhle-text-12">'+
					'<i class="fas fa-edit" style="cursor:pointer;color:black;" title="Modificar" onclick="almacenarSeleccion(''PROYECTO_ID'','''+cast(ID as varchar)+''');goto('''+@FORM_ID+''',''4049307F-6C13-459D-AC01-54F97D942D1B'');return false;"></i>&nbsp;'+
					CASE WHEN ISNULL(NRO_COTIZA,0) <> 0 THEN 
						'<i class="fas fa-file-word" style="cursor:pointer;color:blue;" title="Ver Propuesta" onclick="OpenAttach('''+ISNULL(ID_ADJUNTO,'')+''','''+ISNULL(ATACH_COTIZ.FILE_NAME,'')+''');return false;"></i>'  
					ELSE '' END + '&nbsp;' +
					CASE WHEN ISNULL(SUM(A.DIAS),0) = 0 THEN 
						'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar Proyecto'+ '" 
						onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Proyecto?'');
						if (confirmar){almacenarSeleccion(''ID_DELETE'','''+cast(ID as varchar)+ ''');goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');}"/>'
					ELSE ''
					END + '</div>' AS Opciones
		FROM	
			(
			SELECT DISTINCT CLI.RAZON_SOCIAL_CLIENTE						AS RAZON_SOCIAL,
					'('+CODIGO+') - '+NORMA_REF								AS PROYECTO,
					CONVERT(VARCHAR,P.FECHA_INICIO_REAL,103)				AS FECHA_INICIO,
					CASE WHEN ISNULL(P.FECHA_FIN_REAL,'') = '' THEN '' ELSE CONVERT(VARCHAR,P.FECHA_FIN_REAL,103) END	AS FECHA_FIN,
					CONVERT(VARCHAR,P.TOTAL_HORAS_PROYECTADAS)				AS HORASP,
					P.ID_PROYECTO							 AS ID,
					P.ID_CLIENTE							 AS CLIENTE,
					ESTADO_PROYECTO_TOTAL					 AS ESTADO,
					CD.CAT_DATA_DESC						 AS ESTADO_DESC,
					NORMAS									 AS NORMAS,
					P.OBSERVACIONES							 AS OBSERV,
					P.ID_COTIZACION							 AS NRO_COTIZA,
					C.ID_ADJUNTO							 AS ID_ADJUNTO,
					(SELECT 1 FROM LK_PROYECTO_DOCUM WHERE	ID_PROYECTO = P.ID_PROYECTO AND TIPO = 'MG') AS MINUTA_GESTION
			FROM	LK_PROYECTO P
					INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
					LEFT JOIN CAT_DATA CD ON CD.CAT_DATA_CODE = P.ESTADO_PROYECTO_TOTAL AND CD.PAR_KEY = (SELECT PKEY FROM CAT_TYPE WHERE CAT_TYPE_CODE = 'ESTADOS_PROYECTO')
					LEFT JOIN LK_COTIZACIONES C ON C.ID_COTIZACION = P.ID_COTIZACION
			WHERE	P.ESTADO_PROYECTO_TOTAL = 'TERMINADO'
			AND		P.ID_CLIENTE = @VCLIENTE
			) PROYECTOS 
			LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT ATACH_COTIZ ON ATACH_COTIZ.PKEY = PROYECTOS.ID_ADJUNTO
			LEFT JOIN LK_AGENDA A ON A.ID_CLIENTE = PROYECTOS.CLIENTE AND A.ID_PROYECTO = PROYECTOS.ID
			GROUP BY RAZON_SOCIAL, PROYECTO, OBSERV, PROYECTOS.ESTADO, NORMAS, FECHA_INICIO, FECHA_FIN, HORASP, ID, PROYECTOS.CLIENTE, NRO_COTIZA, ID_ADJUNTO, ESTADO_DESC,ATACH_COTIZ.FILE_NAME, MINUTA_GESTION
		ORDER BY CONVERT(DATETIME,FECHA_FIN,103) DESC
		OFFSET @PageNumber*5 ROWS FETCH NEXT 5 ROWS ONLY
 
		OPEN Proyectos
		FETCH NEXT FROM Proyectos INTO @vinfo, @vproyecto, @vestado_proy, @vnormas, @vfechaini, @vfechafin, @vhoras, @vopciones
	
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				
				SET	@VTABLA = isnull(@VTABLA,'') +
				'<tr>
					<td>'+ISNULL(@vinfo,'')+'</td>
					<td>'+ISNULL(@vproyecto,'')+'</td>
					<td>'+ISNULL(@vestado_proy,'')+'</td>
					<td>'+ISNULL(@vnormas,'')+'</td>
					<td>'+ISNULL(@vfechaini,'')+'</td>
					<td>'+ISNULL(@vfechafin,'')+'</td>
					<td>'+ISNULL(@vhoras,'')+'</td>
					<td>'+ISNULL(@vopciones,'')+'</td>
 
				</tr>'
 
				FETCH NEXT FROM Proyectos INTO @vinfo, @vproyecto, @vestado_proy, @vnormas, @vfechaini, @vfechafin, @vhoras, @vopciones
			END 
 
		CLOSE Proyectos  
		DEALLOCATE Proyectos	
 
		SET @VTABLA = @VTABLA + '</table>'
	END
 
 
	IF (@VTAB = '5' AND ISNULL(@VTAB_AGENDA,'') = '') BEGIN
 
		IF (@VTAB_SERV = '') BEGIN
			SET @VTABLA = ''
		END
 
		SELECT	@VMONTO_PRES		= ISNULL(MONTO_PRES,0),
				@VMONTO_PRES_VIAT	= ISNULL(MONTO_PRES_VIAT,0),
				@VCOSTO_MO			= ISNULL(COSTO_MO,0),
				@VCOSTO_VIAT		= ISNULL(COSTO_VIAT,0),
				@VCOSTO_VARIOS		= ISNULL(COSTO_VARIOS,0),
				@VMONTO_TOTAL		= ISNULL(MONTO_TOTAL,0),
				@VCOSTO_TOTAL		= ISNULL(COSTO_TOTAL,0),
				@VCOMENTARIO		= ISNULL(OBSERV_RENTA,''),
				@VFECHA_PRESUP		= ISNULL(CAST(Convert(CHAR(8),FECHA_PRESUPUESTO,112) as DATE),'')
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
		SET @VMONTO_PRES_TMT		= @VMONTO_PRES
		SET @VMONTO_PRES_VIAT_TMT	= @VMONTO_PRES_VIAT
		SET @VCOSTO_MO_TMT			= @VCOSTO_MO
		SET @VCOSTO_VIAT_TMT		= @VCOSTO_VIAT
		SET @VCOSTO_VARIOS_TMT		= @VCOSTO_VARIOS
		SET @VMONTO_TOTAL_TMT		= @VMONTO_TOTAL
		SET @VCOSTO_TOTAL_TMT		= @VCOSTO_TOTAL
		SET @VCOMENTARIO_TMT		= @VCOMENTARIO
		SET @VFECHA_PRESUP_TMT		= @VFECHA_PRESUP
 
		SET	@VTABLA = isnull(@VTABLA,'') + 
						'<div class="w3-container" style="border:2px solid #bdbdbd">
 
							<div class="w3-row">
								<!-- COLUMNA IZQUIERDA -->
								<div class="w3-half">
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-dollar-sign"></i>
											Monto Presupuestado Proyecto (S/IVA)
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12 monto"
											type="text"
											name="SP.DECIMAL_01"
											value="'+CONVERT(VARCHAR,@VMONTO_PRES_TMT)+'"
											oninput="calcularRentabilidad()">
									</div>
 
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-plane"></i>
											Monto Presupuestado Viáticos (S/IVA)
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12 monto"
											type="text"
											name="SP.DECIMAL_02"
											value="'+CONVERT(VARCHAR,@VMONTO_PRES_VIAT_TMT)+'"
											oninput="calcularRentabilidad()">
									</div>
 
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-calendar"></i>
											Fecha
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12"
											type="date"
											name="SP.FECHA_FACTURA_PROV"
											value="'+CASE WHEN ISNULL(@VFECHA_PRESUP_TMT,'') = '' THEN '' ELSE ISNULL(CONVERT(VARCHAR,@VFECHA_PRESUP_TMT,23),'') END +'">
									</div>
 
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<b>Monto Presupuesto Total</b>
										</label>
										<input
											id="TOTAL_PRESUPUESTO"
											value="'+CONVERT(VARCHAR,@VMONTO_TOTAL_TMT)+'"
											class="w3-input w3-border w3-light-grey w3-round w3-padding-small w3-muhle-text-12"
											readonly>
									</div>
								</div>
 
								<!-- COLUMNA DERECHA -->
								<div class="w3-half">
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-hard-hat"></i>
											Costo Estimado Mano de Obra
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12 costo"
											type="text"
											name="SP.DECIMAL_03"
											value="'+CONVERT(VARCHAR,@VCOSTO_MO_TMT)+'"
											oninput="calcularRentabilidad()">
									</div>
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-plane"></i>
											Costo Estimado Viáticos
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12 costo"
											type="text"
											name="SP.DECIMAL_04"
											value="'+CONVERT(VARCHAR,@VCOSTO_VIAT_TMT)+'"
											oninput="calcularRentabilidad()">
									</div>
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<i class="fas fa-tools"></i>
											Costo Estimado Varios
										</label>
										<input
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12 costo"
											type="text"
											name="SP.DECIMAL_05"
											value="'+CONVERT(VARCHAR,@VCOSTO_VARIOS_TMT)+'"
											oninput="calcularRentabilidad()">
									</div>
 
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<b>Costo Estimado Total</b>
										</label>
										<input
											id="TOTAL_COSTO"
											value="'+CONVERT(VARCHAR,@VCOSTO_TOTAL_TMT)+'"
											class="w3-input w3-border w3-light-grey w3-round w3-padding-small w3-muhle-text-12"
											readonly>
									</div>
								</div>
							</div>
							<div class="w3-row" style="margin-top:10px;">
								<div class="w3-half">
									<div class="w3-padding">
										<div style="margin-bottom:8px;">
											<label class="w3-large w3-muhle-text-12">
												<b>Rentabilidad Estimada (S/IVA):</b>
											</label>
											<span id="LBL_RENTABILIDAD"
												  class="w3-large w3-muhle-text-12 w3-text-green">
												$ 0,00
											</span>
										</div>
 
										<div>
											<label class="w3-large w3-muhle-text-12">
												<b>Margen Estimado:</b>
											</label>
											<span id="LBL_MARGEN"
												  class="w3-large w3-muhle-text-12 w3-text-blue">
												0,00 %
											</span>
										</div>
									</div>
								</div>
 
								<div class="w3-half">
									<div class="w3-padding">
										<label class="w3-muhle-text-12">
											<b>Comentario</b>
										</label>
										<textarea
											name="SP.ACUMULA_VIATICO"
											rows="4"
											class="w3-input w3-border w3-round w3-padding-small w3-muhle-text-12"
											style="resize:none;width:100%;">'+ISNULL(@VCOMENTARIO_TMT,'')+'</textarea>
									</div>
								</div>
							</div>
							<div class="w3-container w3-padding">					
								<btn
									class="w3-right w3-button w3-muhle-color w3-medium w3-round"
									onclick="almacenarSeleccion(''ID_SERV_DELETE'',''RENTA'');guardarRentabilidad();return false;">
									Guardar
								</btn>
							</div>
						</div>
					<script>
						function numero(valor){
							if(valor==null) return 0;
							var txt = valor.toString().trim();
							if(txt=="") return 0;
							txt = txt.replace(/\$/g,"").replace(/\s/g,"");
 
							if(txt.indexOf(",") >= 0){
								txt = txt.replace(/\./g,"");
								txt = txt.replace(",",".");
							}
 
							var n = parseFloat(txt);
							return isNaN(n) ? 0 : n;
						}
 
						function formatoPesos(valor){
							return valor.toLocaleString("es-AR",{
								style:"currency",
								currency:"ARS",
								minimumFractionDigits:2,
								maximumFractionDigits:2
							});
						}
 
						function formatearInput(input){
							if(input.value.trim()==""){
								input.value="";
								return;
							}
							var n = numero(input.value);
							input.value = formatoPesos(n);
						}
 
						function limpiarInput(input){
							if(input.value.trim()==""){
								input.value="";
								return;
							}
							input.value = numero(input.value).toFixed(2);
						}
 
						function prepararInputs(){
							var campos = document.querySelectorAll(".monto,.costo");
 
							campos.forEach(function(c){
								c.addEventListener("focus",function(){
									if(this.value.trim()=="" || numero(this.value)==0){
										this.value="";
										return;
									}
									this.value = numero(this.value);
								});
 
								c.addEventListener("blur",function(){
									if(this.value.trim()=="") return;
									formatearInput(this);
									calcularRentabilidad();
								});
							});
						}
 
						function calcularRentabilidad(){
							var p1 = numero(document.getElementsByName(''SP.DECIMAL_01'')[0].value);
							var p2 = numero(document.getElementsByName(''SP.DECIMAL_02'')[0].value);
							var c1 = numero(document.getElementsByName(''SP.DECIMAL_03'')[0].value);
							var c2 = numero(document.getElementsByName(''SP.DECIMAL_04'')[0].value);
							var c3 = numero(document.getElementsByName(''SP.DECIMAL_05'')[0].value);
							var totalPres = p1+p2;
							var totalCosto = c1+c2+c3;
 
							var rent = totalPres-totalCosto;
							var margen = 0;
 
							if(totalPres>0) margen = rent*100/totalPres;
 
							document.getElementById("TOTAL_PRESUPUESTO").value = formatoPesos(totalPres);
							document.getElementById("TOTAL_COSTO").value = formatoPesos(totalCosto);
							document.getElementById("LBL_RENTABILIDAD").innerHTML = formatoPesos(rent);
							document.getElementById("LBL_MARGEN").innerHTML = margen.toFixed(2).replace(".",",") + " %";
 
							if(typeof calcularRentabilidadReal === "function"){
								calcularRentabilidadReal();
							}
						}
 
						function guardarRentabilidad(){
							document.querySelectorAll(".monto,.costo").forEach(limpiarInput);
							goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');
						}
 
						setTimeout(function(){
							prepararInputs();
							document.querySelectorAll(".monto,.costo").forEach(function(i){
								formatearInput(i);
							});
							calcularRentabilidad();
						},150);
					</script>'
					+
					CASE WHEN ISNULL(@VDESC_ERROR,'') = '' THEN ''
					ELSE '<script>alert("'+isnull(@VDESC_ERROR,'')+'");</script>'
					END
	END
 
	IF (@VTAB_SERV = '1' AND ISNULL(@VTAB_AGENDA,'') = '') BEGIN
		
		SET @VCANT_AGENDA = 0
 
		SET @VTABLA_DET = '
		<table id="TableDet" class="w3-table-all w3-muhle-text-11">
			<tr style="background-color:gray;color:white;">
				<th><div class="w3-center"></div></th>
				<th><div class="w3-center">Desde</div></th>
				<th><div class="w3-center">Hasta</div></th>
				<th><div class="w3-center">Servicio</div></th>
				<th><div class="w3-center">Normas</div></th>
				<th><div class="w3-center">Días</div></th>
				<th><div class="w3-center">Horas</div></th>
				<th><div class="w3-center">Notas</div></th>
				<th><div class="w3-left">Consultores</div></th>
				<th><div class="w3-left">Observaciones</div></th>
				<th><div class="w3-center">[+]</div></th>
			</tr>'
 
		DECLARE Planificacion CURSOR FOR 
			SELECT	C.RAZON_SOCIAL_CLIENTE,
					P.NORMA_REF,
					A.NORMA,
					CONVERT(VARCHAR,A.FECHA,103),
					CONVERT(VARCHAR,A.FECHA_HASTA,103),
					CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor' 
					ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
					ISNULL(A.OBSERVADOR,''),
					CONVERT(VARCHAR,A.ID_AGENDA),
					A.ID_SERVICIO,
					A.DIAS,
					CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN '' ELSE A.OBSERV_CALIF END,
					CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN '' ELSE A.OBSERV_LOGISTICA END,
					CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN '' ELSE DOC.OBSERVACIONES END,
					DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) AS HORAS,
					INDICADOR_HR,
					A.ESTADO
			FROM	LK_AGENDA A
					INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
					INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
					INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
					LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
			WHERE	A.PROYECTO_SERV_ID = @VID_SERVICIO
			ORDER BY A.FECHA DESC
 
		OPEN Planificacion  
		FETCH NEXT FROM Planificacion INTO @VARCLIENTE, @VARPROYECTO, @VARNORMA, @VARFECHAD, @VARFECHAH, @VARPROFESIONAL, @VAROBSERVACIONES, @VID_AGENDA, @VARSERVICIO, @VARDIAS, @VAROBS_CALIF, @VAROBS_LOGIS, @VAROBS_HR, @VARHORAS, @VSTATUS, @VARESTADO
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_AGENDA = @VCANT_AGENDA + 1
			
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center">'+
										CASE WHEN ISNULL(@VSTATUS,'R') = 'R' THEN	
											'<i class="fas fa-circle" style="cursor:pointer;color:red;" title="Indicador"></i>'
											WHEN ISNULL(@VSTATUS,'R') = 'N' THEN
											'<i class="fas fa-circle" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
											WHEN ISNULL(@VSTATUS,'R') = 'A' THEN
											'<i class="fas fa-circle" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
											WHEN ISNULL(@VSTATUS,'R') = 'V' THEN
											'<i class="fas fa-circle" style="cursor:pointer;color:green;" title="Indicador"></i>'
											WHEN ISNULL(@VSTATUS,'R') = 'C' THEN	
											'<i class="fas fa-circle" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
										END +'</div></td>'+	
				  '<td><div class="w3-center">'+@VARFECHAD+'</div></td>'+
				  '<td><div class="w3-center">'+@VARFECHAH+'</div></td>'+
				  '<td><div class="w3-center">'+ CASE	WHEN @VARSERVICIO = '1' THEN 'Consultoria'
																		WHEN @VARSERVICIO = '2' THEN 'Auditoria'
																		WHEN @VARSERVICIO = '3' THEN 'Capacitacion'
																	END +'</div></td>'+
				  '<td><div class="w3-center">'+ 
					'<i class="fas fa-info-circle" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',@VARNORMA,''),'</br>',char(10))+'"></i>'
					+'</div></td>'+
				  '<td><div class="w3-center">'+@VARDIAS+'</div></td>'+
				  '<td><div class="w3-center">'+@VARHORAS+'</div></td>'+
				  '<td><div class="w3-center">'+
					CASE WHEN ISNULL(@VAROBS_CALIF,'') <> '' THEN 
					'<i class="fas fa-clipboard-list" style="cursor:pointer;color:red;" title="Obs. Calificación:&nbsp;'+@VAROBS_CALIF+'"></i>&nbsp;' ELSE '' END+
					CASE WHEN ISNULL(@VAROBS_HR,'') <> '' THEN 
					'<i class="fas fa-clipboard" style="cursor:pointer;color:green;" title="'+'Obs. Hoja Ruta:&nbsp;'+@VAROBS_HR+'"></i>' ELSE '' END
					+'</div></td>'+
				  '<td><div class="w3-left">'+@VARPROFESIONAL+'</div></td>'+
				  '<td><div class="w3-left">'+ISNULL(@VAROBSERVACIONES,'')+'</div></td>' +
				  '<td><div class="w3-center">' +
					  '<i class="fas fa-flag" style="cursor:pointer;color:'+CASE WHEN @VARESTADO = 'C' THEN 'green' ELSE 'yellow' END+'" title="'+CASE WHEN @VARESTADO = 'C' THEN 'Confirmado' ELSE 'Pendiente' END+'" onclick="return false;"></i>' + '&nbsp;' + 
					  '<i class="fas fa-calendar-alt" style="cursor:pointer;" title="Ver Visita" onclick="almacenarSeleccion(''AGENDA_ID'','''+@VID_AGENDA+''');almacenarSeleccion(''TAB_AGENDA'',''0'');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"></i>'+ '&nbsp;' + 
					  '<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
						onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Visita?'');
						if (confirmar){almacenarSeleccion(''ID_DELETE'','''+@VID_AGENDA+ ''');goto('''+@FORM_ID+''',''D4F4266D-2745-438E-9E46-D22F3B1D2D8A'');}"/>
					</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Planificacion INTO @VARCLIENTE, @VARPROYECTO, @VARNORMA, @VARFECHAD, @VARFECHAH, @VARPROFESIONAL, @VAROBSERVACIONES, @VID_AGENDA, @VARSERVICIO, @VARDIAS, @VAROBS_CALIF, @VAROBS_LOGIS, @VAROBS_HR, @VARHORAS, @VSTATUS, @VARESTADO
		END 
 
		CLOSE Planificacion  
		DEALLOCATE Planificacion
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	IF (@VTAB_SERV = '2') BEGIN
 
		IF (@VTIPO_SERV_SELEC = '1') BEGIN
			SELECT	@VFRECUENCIA = ISNULL(FRECUENCIA_ENVIO,''), @VDOC_EMPRESA = ISNULL(DOC_EMPRESA,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
			SET @VTABLA_DET = '
			<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Frecuencia Envio Plan Estrategico</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Documentacion Empresa</div></th>
				</tr>
				<tr>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VFRECUENCIA,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VDOC_EMPRESA,'')+'</div></td>
				</tr>
			</table>'
		END
 
		IF (@VTIPO_SERV_SELEC = '2') BEGIN
 
			SELECT	@VMANUAL_DOC = ISNULL(MANUALES,''), @VREQ_INGRESO = ISNULL(REQUISITO_INGRESO,''), @VCV_CERTIF = ISNULL(CV_CERTIFICADOS,''), @VLOGISTICA = ISNULL(LOGISTICA,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
			
			SET @VTABLA_DET = '
			<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Manual/Documentacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Requisitos Ingreso</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">CV y Certificados</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Logistica</div></th>
				</tr>
				<tr>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VMANUAL_DOC,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VREQ_INGRESO,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VCV_CERTIF,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VLOGISTICA,'')+'</div></td>
				</tr>
			</table>'
		END
 
		IF (@VTIPO_SERV_SELEC = '3') BEGIN
			
			SELECT	@VCURSO = ISNULL(NOMBRE_CURSO,''), @VMATERIAL = ISNULL(MATERIALES,''), @VESTADO_ENVIO = ISNULL(ESTADO_ENVIO,''), @VRECIBIDO = ISNULL(RECIBIDO,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VID_SERVICIO
 
			SET @VTABLA_DET = '
			<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Nombre Curso</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Materiales</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Estado de Envio</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Recibido</div></th>
				</tr>
				<tr>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VCURSO,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VMATERIAL,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VESTADO_ENVIO,'')+'</div></td>
					<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VRECIBIDO,'')+'</div></td>
				</tr>
			</table>'
		END
	END
 
	IF (@VTAB_SERV = '3') BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
 
		SET @VCANT_MC = 0
 
		SET @VTABLA_DET = '
			<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Observacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Minutas CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar la Minuta?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Minuta" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END 
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.ID_TIPO_SERVICIO = @VTIPO_SERV_SELEC
			AND		D.PROYECTO_SERV_ID = @VID_SERVICIO
			AND		D.TIPO = 'MC'
 
		OPEN Minutas  
		FETCH NEXT FROM Minutas INTO @VFECHA_MINUTA, @VNOMBRE, @VOBSERV_MINUTA,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_MC = @VCANT_MC + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_MINUTA+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_MINUTA+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Minutas INTO @VFECHA_MINUTA, @VNOMBRE, @VOBSERV_MINUTA,@VACCION
		END 
 
		CLOSE Minutas  
		DEALLOCATE Minutas
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	IF (@VTAB_SERV = '4')	BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
 
		SET @VCANT_PE = 0
 
		SET @VTABLA_DET = '
		<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Observacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Planes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''B0569958-40AB-49AD-8036-555088709D77'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Plan?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Plan" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.ID_TIPO_SERVICIO = @VTIPO_SERV_SELEC
			AND		D.PROYECTO_SERV_ID = @VID_SERVICIO
			AND		D.TIPO = 'PE'
 
		OPEN Planes  
		FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_PE = @VCANT_PE + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_PLAN+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Planes  
		DEALLOCATE Planes
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	IF (@VTAB_SERV = '5')	BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
 
		SET @VCANT_PA = 0
 
		SET @VTABLA_DET = '
		<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Observacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Planes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''DFE8677A-7CCF-4D8E-A91D-4EB3F526393C'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Plan?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Plan" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.ID_TIPO_SERVICIO = @VTIPO_SERV_SELEC
			AND		D.PROYECTO_SERV_ID = @VID_SERVICIO
			AND		D.TIPO = 'PA'
 
		OPEN Planes  
		FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_PA = @VCANT_PA + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_PLAN+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Planes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Planes  
		DEALLOCATE Planes
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	IF (@VTAB_SERV = '6')	BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
 
		SET @VCANT_IA = 0
 
		SET @VTABLA_DET = '
		<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Observacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Informes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''3F6EFE7E-110B-4A5E-953B-B0E5D49C0F16'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.ID_TIPO_SERVICIO = @VTIPO_SERV_SELEC
			AND		D.PROYECTO_SERV_ID = @VID_SERVICIO
			AND		D.TIPO = 'IA'
 
		OPEN Informes  
		FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_IA = @VCANT_IA + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_PLAN+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Informes  
		DEALLOCATE Informes
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	IF (@VTAB_SERV = '7')	BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
 
		SET @VCANT_IC = 0
 
		SET @VTABLA_DET = '
		<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Observacion</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Informes CURSOR FOR 
			SELECT	ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					OBSERVACIONES,
					'<i class="fas fa-edit" style="cursor:pointer;color:#002364;" title="Modificar"
					 onclick="almacenarSeleccion(''ID_MINUTA'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+''');
					 goto('''+@FORM_ID+''',''931875EA-23ED-4EEA-BF4F-8A53C7B1FB90'');"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Informe?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>' + '&nbsp;' +
					CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
						'<i class="fas fa-file-word" style="cursor:pointer;" title="Ver Informe" '+ CASE WHEN ISNULL(D.ID_ADJUNTO,'') <> '' THEN
															'onclick="OpenAttach('''+ISNULL(P.PKEY,'')+''','''+ISNULL(P.FILE_NAME,'')+''');return false;"' ELSE '' END +'></i>'
						ELSE '' END
			FROM	LK_PROYECTO_DOCUM D
					LEFT JOIN PHYSICAL_ATTACHED_DOCUMENT P ON P.PKEY = D.ID_ADJUNTO
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.ID_TIPO_SERVICIO = @VTIPO_SERV_SELEC
			AND		D.PROYECTO_SERV_ID = @VID_SERVICIO
			AND		D.TIPO = 'IC'
 
		OPEN Informes  
		FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_IC = @VCANT_IC + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_PLAN+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Informes INTO @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN,@VACCION
		END 
 
		CLOSE Informes  
		DEALLOCATE Informes
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	--TABLA DE ANEXOS--
	IF (@VTAB_SERV = '9')	BEGIN
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_DOCUM WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
			DELETE FROM LK_PROYECTO_DOCUM_DET WHERE ID_PROYECTO_DOCUM = @VCLAVE_DELETE
		END
		
		DECLARE @VCANT_ANEXO INT
		SET @VCANT_ANEXO = 0
 
		SET @VTABLA_DET = '
		<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;"></div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Nombre</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Tipo Servicio</div></th>
					<th><div class="w3-left w3-muhle-text-11" style="color:white;">Servicio</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">[+]</div></th>
				</tr>'
 
		DECLARE Anexos CURSOR FOR 
			SELECT	'<i class="fas fa-book" style="cursor:pointer;color:'+CASE WHEN [dbo].[FN_GET_OBLIGA_ANEXO_MINUTA] (ISNULL(CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM),''))  = 'NO' THEN 'green' ELSE 'red' END +';" title="Anexo Minuta de Gestion" 
							onclick="return false;"></i>' + '&nbsp;' + 
					'<i class="fas fa-edit" style="cursor:pointer;color:blue;" title="Modificar" 
							onclick="almacenarSeleccion(''TIPO_FERIADO'','''+ISNULL(CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM),'')+''');goto('''+@FORM_ID+''',''3049C791-DD77-42F0-B8E6-7E9A8AAEA86D'');"></i>',
					ISNULL(CONVERT(VARCHAR,FECHA_DOCUM, 103),''),
					NRO_DOCUM_INTERNO,
					CASE WHEN ID_TIPO_SERVICIO = '1' THEN 'Consultoria'
						 WHEN ID_TIPO_SERVICIO = '2' THEN 'Auditoria'
						 WHEN ID_TIPO_SERVICIO = '3' THEN 'Capacitacion' END,
					D.PROYECTO_SERV_ID,
					'<i class="fas fa-search" style="cursor:pointer;color:#002364;" title="Ver" onclick="almacenarSeleccion(''TAB_AGENDA'','''+ISNULL(CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM),'')+''');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"></i>' + '&nbsp;' + 
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:red;" title="' +'Eliminar'+ '" 
					onclick="confirmar=confirm(''¿Esta seguro que quiere eliminar el Anexo?'');
					if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,D.ID_PROYECTO_DOCUM)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>'
			FROM	LK_PROYECTO_DOCUM D
			WHERE	D.ID_PROYECTO = @VID_PROYECTO
			AND		D.TIPO IN ('Anex-A','Anex-CA','Anex-CO')
 
		OPEN Anexos  
		FETCH NEXT FROM Anexos INTO @VESTADO_ANEXO, @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN, @VANEXO_SERV_ID, @VACCION
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SELECT	@VDESC_SERV_ANEXO = ISNULL(NOMBRE,'')
			FROM	LK_PROYECTO_SERVICIO
			WHERE	ID_PROYECTO_SERVICIO = @VANEXO_SERV_ID
 
			SET @VCANT_ANEXO = @VCANT_ANEXO + 1
 
			SET @VTABLA_DET =  isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-12">'+@VESTADO_ANEXO+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+@VFECHA_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VNOMBRE+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+@VOBSERV_PLAN+'</div></td>'+
				  '<td><div class="w3-left w3-muhle-text-11">'+ISNULL(@VDESC_SERV_ANEXO,'')+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-12">'+@VACCION+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Anexos INTO @VESTADO_ANEXO, @VFECHA_PLAN, @VNOMBRE, @VOBSERV_PLAN, @VANEXO_SERV_ID, @VACCION
		END 
 
		CLOSE Anexos  
		DEALLOCATE Anexos
 
		SET @VTABLA_DET = @VTABLA_DET + '</table>'
	END
 
	--TABLA DE HISTORIAL DE PERIODO--
	--TABLA DE HISTORIAL DE PERIODO--
	IF (@VTAB_SERV = '10')	BEGIN
 
		IF (@VCLAVE_DELETE <> '') BEGIN
			DELETE FROM LK_PROYECTO_RENTABILIDAD WHERE ID_PROYECTO_RENTA = @VCLAVE_DELETE
		END
 
		-- 1. Calculamos el Margen Estimado del proyecto para comparar en el gráfico
		SELECT 
			@VMARGEN_ESTIMADO_PROY = 
				CASE WHEN ISNULL(MONTO_TOTAL,0) > 0 THEN 
					((MONTO_TOTAL - ISNULL(COSTO_TOTAL,0)) * 100.0) / MONTO_TOTAL 
				ELSE 0 
			END
		FROM	LK_PROYECTO
		WHERE	ID_PROYECTO = @VID_PROYECTO;
 
		DECLARE @VCANT_PERIODO	INT
		DECLARE @VFECHA_PERIODO	DATETIME, 
				@VPERIODO		VARCHAR(100), 
				@VCOMPRAS		NUMERIC(15,2), 
				@VVENTAS		NUMERIC(15,2),
				@UTIL_REAL		NUMERIC(15,2),
				@RENTA_REAL		NUMERIC(15,2),
				@VDELETE_RENTA	VARCHAR(MAX) -- Ampliado a MAX por los botones HTML
 
		SET @VCANT_PERIODO = 0
 
		SET @VTABLA_DET = '
			<table class="w3-table-all w3-muhle-text-11">
				<tr style="background-color:gray;">
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Fecha</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Periodo</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Ventas</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Compras</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Utilidad Real</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Rentabilidad Real</div></th>
					<th><div class="w3-center w3-muhle-text-11" style="color:white;">Opciones</div></th>
				</tr>'
 
		-- 2. Modificamos el cursor para agregar el icono de Gráfico y formatear los parámetros
		-- Modificamos el cursor para agregar el icono estilizado
		DECLARE Periodos CURSOR FOR 
			SELECT	FECHA_ALTA, PERIODO, VENTAS, COMPRAS, 
					(VENTAS - COMPRAS), 
					CASE WHEN (VENTAS > 0) THEN ((VENTAS - COMPRAS) * 100.0) / VENTAS ELSE 0 END,
					'<i class="fas fa-chart-bar w3-margin-right" style="cursor:pointer;color:#059669;font-size:15px;transition:transform 0.1s;" title="Ver Gráfico del Período" onmouseover="this.style.transform=''scale(1.25)''" onmouseout="this.style.transform=''scale(1)''" onclick="abrirModalGraficoPeriodo(''' + PERIODO + ''', ' + REPLACE(CONVERT(VARCHAR, @VMARGEN_ESTIMADO_PROY), ',', '.') + ', ' + REPLACE(CONVERT(VARCHAR, CASE WHEN (VENTAS > 0) THEN ((VENTAS - COMPRAS) * 100.0) / VENTAS ELSE 0 END), ',', '.') + ');"></i>' +
					'<i class="fas fa-trash-alt" style="cursor:pointer;color:#dc2626;font-size:14px;transition:transform 0.1s;" title="Eliminar Período" onmouseover="this.style.transform=''scale(1.25)''" onmouseout="this.style.transform=''scale(1)''" onclick="confirmar=confirm(''¿Está seguro que quiere eliminar el Período?'');if (confirmar){almacenarSeleccion(''CLAVE_DELETE'','''+CONVERT(VARCHAR,ID_PROYECTO_RENTA)+ ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');}"/>'
			FROM	LK_PROYECTO_RENTABILIDAD
			WHERE	ID_PROYECTO = @VID_PROYECTO
			ORDER BY PERIODO
 
		OPEN Periodos  
		FETCH NEXT FROM Periodos INTO @VFECHA_PERIODO, @VPERIODO, @VVENTAS, @VCOMPRAS, @UTIL_REAL, @RENTA_REAL, @VDELETE_RENTA
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			SET @VCANT_PERIODO = @VCANT_PERIODO + 1
 
			SET @VTABLA_DET = isnull(@VTABLA_DET,'') + 
				'<tr>' +
				  '<td><div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,@VFECHA_PERIODO,103)+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+@VPERIODO+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FORMAT(@VVENTAS, 'C', 'es-AR'))+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FORMAT(@VCOMPRAS, 'C', 'es-AR'))+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,FORMAT(@UTIL_REAL, 'C', 'es-AR'))+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+CONVERT(VARCHAR,CAST(@RENTA_REAL AS DECIMAL(18,2)))+' %'+'</div></td>'+
				  '<td><div class="w3-center w3-muhle-text-11">'+ISNULL(@VDELETE_RENTA,'')+'</div></td>'+
				'</tr>'
 
			FETCH NEXT FROM Periodos INTO @VFECHA_PERIODO, @VPERIODO, @VVENTAS, @VCOMPRAS, @UTIL_REAL, @RENTA_REAL, @VDELETE_RENTA
		END 
 
		CLOSE Periodos  
		DEALLOCATE Periodos
 
		-- 3. Cerramos la tabla e Inyectamos el Modal y el JS para el gráfico
		-- Cerramos la tabla e Inyectamos el Modal con cierre por clic exterior
		SET @VTABLA_DET = @VTABLA_DET + '</table>' + 
		'<div id="modalGraficoPeriodo" class="w3-modal w3-round" style="z-index:9999;" onclick="cerrarModalPeriodoExterior(event)">
			<div class="w3-modal-content w3-round w3-animate-zoom w3-card-4" style="max-width:650px; margin-top:50px;" onclick="event.stopPropagation();">
				<header class="w3-container w3-muhle-color w3-padding w3-round-up">
					<span onclick="cerrarModalPeriodo()" class="w3-button w3-display-topright w3-large w3-hover-none w3-hover-text-light-grey" style="color:white; cursor:pointer;">&times;</span>
					<h5 id="tituloModalGrafico" style="color:white; margin:0; font-weight:bold;"><i class="fas fa-chart-bar"></i> Rentabilidad Periodo</h5>
				</header>
				<div class="w3-container w3-padding w3-white w3-round-down" style="min-height: 280px; position: relative;">
					<canvas id="canvasModalPeriodo"></canvas>
				</div>
			</div>
		</div>
 
		<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
		<script>
			var chartModalPeriodo = null;
 
			function cerrarModalPeriodo() {
				document.getElementById("modalGraficoPeriodo").style.display = "none";
			}
 
			function cerrarModalPeriodoExterior(event) {
				if (event.target.id === "modalGraficoPeriodo") {
					cerrarModalPeriodo();
				}
			}
 
			function abrirModalGraficoPeriodo(periodo, estimada, real) {
				document.getElementById("tituloModalGrafico").innerHTML = "<i class=\"fas fa-chart-bar\"></i> Rentabilidad del Período: " + periodo;
				document.getElementById("modalGraficoPeriodo").style.display = "block";
 
				var canvas = document.getElementById("canvasModalPeriodo");
				var ctx = canvas.getContext("2d");
 
				if(chartModalPeriodo) {
					chartModalPeriodo.destroy();
				}
 
				var valEstimada = parseFloat(estimada) || 0;
				var valReal = parseFloat(real) || 0;
 
				var pluginEtiqBlancas = {
					id: "etiqBlancasModal",
					afterDatasetsDraw: function(chart) {
						var ctx = chart.ctx;
						chart.data.datasets.forEach(function(dataset, i) {
							var meta = chart.getDatasetMeta(i);
							meta.data.forEach(function(bar, index) {
								var val = dataset.data[index];
								if (val > 0) {
									var texto = val.toFixed(2).replace(".", ",") + " %";
									ctx.save();
									ctx.fillStyle = "#ffffff";
									ctx.font = "bold 12px sans-serif";
									ctx.textAlign = "right";
									ctx.textBaseline = "middle";
									ctx.fillText(texto, bar.x - 15, bar.y);
									ctx.restore();
								}
							});
						});
					}
				};
 
				chartModalPeriodo = new Chart(ctx, {
					type: "bar",
					plugins: [pluginEtiqBlancas],
					data: {
						labels: ["Rentabilidad Estimada", "Rentabilidad Real"],
						datasets: [{
							data: [valEstimada, valReal],
							backgroundColor: [
								"rgba(102, 6, 45, 0.95)",
								valReal >= valEstimada ? "rgba(5, 150, 105, 0.95)" : "rgba(220, 38, 38, 0.95)"
							],
							borderColor: [
								"#66062D",
								valReal >= valEstimada ? "#059669" : "#dc2626"
							],
							borderWidth: 1.5,
							borderRadius: 6,
							barThickness: 34
						}]
					},
					options: {
						indexAxis: "y",
						responsive: true,
						maintainAspectRatio: false,
						plugins: { legend: { display: false } },
						scales: {
							x: { min: 0, max: 100, grid: { color: "rgba(226, 232, 240, 0.6)" }, ticks: { color: "#64748b", stepSize: 10 } },
							y: { grid: { display: false }, ticks: { color: "#334155", font: { weight: "500" }, mirror: false } }
						}
					}
				});
			}
		</script>'
	END
 
	-- PRE-CÁLCULO PARA GRÁFICO EVOLUTIVO (TAB_SERV = 11) --
	IF (@VTAB = '5' AND ISNULL(@VTAB_SERV,'') = '11')
	BEGIN
		SELECT 
			@VMARGEN_ESTIMADO_PROY = CASE 
				WHEN ISNULL(MONTO_TOTAL,0) > 0 THEN ((MONTO_TOTAL - ISNULL(COSTO_TOTAL,0)) * 100.0) / MONTO_TOTAL 
				ELSE 0 
			END
		FROM LK_PROYECTO
		WHERE ID_PROYECTO = @VID_PROYECTO;
 
		DECLARE @VPER_NOM VARCHAR(100), @VVENT_PER NUMERIC(15,2), @VCOMP_PER NUMERIC(15,2), @VRENT_PER NUMERIC(15,2);
		
		-- VARIABLES PARA CÁLCULO PONDERADO REAL
		DECLARE @VVENTAS_ACUM_TOTAL NUMERIC(15,2) = 0;
		DECLARE @VCOMPRAS_ACUM_TOTAL NUMERIC(15,2) = 0;
 
		DECLARE CursorGrafico CURSOR FOR 
			SELECT PERIODO, ISNULL(VENTAS,0), ISNULL(COMPRAS,0)
			FROM LK_PROYECTO_RENTABILIDAD
			WHERE ID_PROYECTO = @VID_PROYECTO
			ORDER BY PERIODO;
 
		OPEN CursorGrafico;
		FETCH NEXT FROM CursorGrafico INTO @VPER_NOM, @VVENT_PER, @VCOMP_PER;
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Rentabilidad del período individual
			SET @VRENT_PER = CASE WHEN @VVENT_PER > 0 THEN ((@VVENT_PER - @VCOMP_PER) * 100.0) / @VVENT_PER ELSE 0 END;
			
			SET @VLABELS_PERIODOS    = ISNULL(@VLABELS_PERIODOS, '') + '''' + @VPER_NOM + ''',';
			SET @VDATA_RENT_PERIODOS = ISNULL(@VDATA_RENT_PERIODOS, '') + CONVERT(VARCHAR, CAST(@VRENT_PER AS DECIMAL(18,2))) + ',';
			
			-- Acumular montos monetarios reales para rentabilidad global ponderada
			SET @VVENTAS_ACUM_TOTAL  = @VVENTAS_ACUM_TOTAL + @VVENT_PER;
			SET @VCOMPRAS_ACUM_TOTAL = @VCOMPRAS_ACUM_TOTAL + @VCOMP_PER;
			SET @VCANT_PERIODOS_TOTAL = @VCANT_PERIODOS_TOTAL + 1;
 
			FETCH NEXT FROM CursorGrafico INTO @VPER_NOM, @VVENT_PER, @VCOMP_PER;
		END;
 
		CLOSE CursorGrafico;
		DEALLOCATE CursorGrafico;
 
		IF LEN(@VLABELS_PERIODOS) > 0 SET @VLABELS_PERIODOS = LEFT(@VLABELS_PERIODOS, LEN(@VLABELS_PERIODOS) - 1);
		IF LEN(@VDATA_RENT_PERIODOS) > 0 SET @VDATA_RENT_PERIODOS = LEFT(@VDATA_RENT_PERIODOS, LEN(@VDATA_RENT_PERIODOS) - 1);
 
		-- CÁLCULO DE PROMEDIO REAL PONDERADO EXACTO (Mismas Ventas Totales vs Compras Totales)
		IF @VVENTAS_ACUM_TOTAL > 0
			SET @VPROMEDIO_RENTA = ((@VVENTAS_ACUM_TOTAL - @VCOMPRAS_ACUM_TOTAL) * 100.0) / @VVENTAS_ACUM_TOTAL;
		ELSE
			SET @VPROMEDIO_RENTA = 0;
 
		DECLARE @i INT = 1;
		WHILE @i <= @VCANT_PERIODOS_TOTAL
		BEGIN
			SET @VDATA_ESTIMADO = ISNULL(@VDATA_ESTIMADO, '') + CONVERT(VARCHAR, CAST(@VMARGEN_ESTIMADO_PROY AS DECIMAL(18,2))) + ',';
			SET @VDATA_PROMEDIO = ISNULL(@VDATA_PROMEDIO, '') + CONVERT(VARCHAR, CAST(@VPROMEDIO_RENTA AS DECIMAL(18,2))) + ',';
			SET @i = @i + 1;
		END;
 
		IF LEN(@VDATA_ESTIMADO) > 0 SET @VDATA_ESTIMADO = LEFT(@VDATA_ESTIMADO, LEN(@VDATA_ESTIMADO) - 1);
		IF LEN(@VDATA_PROMEDIO) > 0 SET @VDATA_PROMEDIO = LEFT(@VDATA_PROMEDIO, LEN(@VDATA_PROMEDIO) - 1);
	END
 
	IF (@VTOTAL_PAGINA <> 0) BEGIN
		SET @VACTUAL = 1
		SET @VIZQUIERDA = '<a '+CASE WHEN @PageNumber = 0 THEN 'style="visibility: hidden;"' ELSE '' END+' href="javascript:almacenarSeleccion(''NRO_PAGINA'',''' + CONVERT(VARCHAR,(@PageNumber - 1)) + ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');">&laquo;</a>'
		SET @VDERECHA = '<a '+CASE WHEN ((@PageNumber + 1) = @VTOTAL_PAGINA) THEN 'style="visibility: hidden;"' ELSE '' END+' href="javascript:almacenarSeleccion(''NRO_PAGINA'',''' + CONVERT(VARCHAR,(@PageNumber + 1)) + ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');">&raquo;</a>'
 
		WHILE @VACTUAL <= @VTOTAL_PAGINA BEGIN
			SET @VPAGINAS = ISNULL(@VPAGINAS,'') +
					'<a '+CASE WHEN (@PageNumber+1 = @VACTUAL) THEN 'class="active"' ELSE '' END 
						+CASE WHEN (@PageNumber+1 = @VACTUAL) THEN '' ELSE ' href="javascript:almacenarSeleccion(''NRO_PAGINA'',''' + CONVERT(VARCHAR,(@VACTUAL - 1)) + ''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');' END + '"> ' +
						CONVERT(VARCHAR,@VACTUAL)+'</a>'
			SET @VACTUAL = @VACTUAL + 1
		END
		
		SET @VPAGINADO = '<div class="pagination w3-center w3-muhle-text-12">' + ISNULL(@VIZQUIERDA,'') + isnull(@VPAGINAS,'') + ISNULL(@VDERECHA,'') + '</div>'
	END
 
	SET @ODETALLE = 
			'<div class="w3-row w3-back w3-light-grey">
				<div class="w3-col w3-padding">
					<div class="w3-card-4 w3-round w3-padding">'
 
	IF (ISNULL(@VID_AGENDA_SELEC,'') = '') BEGIN
 
		IF (@VTAB_SERV = '8') BEGIN
			SELECT	@VID_DOCUM = ID_PROYECTO_DOCUM,
					@VMINUTA_DESC = LTRIM(RTRIM(SUBSTRING(NRO_DOCUM_INTERNO,1,CHARINDEX('-',NRO_DOCUM_INTERNO,0)-1)))
			FROM	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO = @VID_PROYECTO
			AND		TIPO = 'MG'
		END
 
		IF (@VTAB_SERV = '9') BEGIN
			SELECT	@VMINUTA_DESC = ISNULL(NRO_DOCUM_INTERNO,'')
			FROM	LK_PROYECTO_DOCUM
			WHERE	ID_PROYECTO = @VID_PROYECTO
			AND		ID_PROYECTO_DOCUM = @VTAB_AGENDA
		END
 
		DECLARE @VTITULO	NVARCHAR(MAX),
				@FILENAME	NVARCHAR(MAX)
 
		SET @VTITULO = @VMINUTA_DESC
		SET @FILENAME = @VMINUTA_DESC
 
		DECLARE @VOTRO_SERVICIO	INT
		SET @VOTRO_SERVICIO = 0
 
		SELECT	@VOTRO_SERVICIO = COUNT(1)
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VID_PROYECTO
 
		SET @ODETALLE = ISNULL(@ODETALLE,'') +
		'<div class="w3-bar w3-round w3-muhle-text-14">'+
			CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN
				'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '8' THEN 'w3-muhle-vocaturo' ELSE 'w3-muhle-color' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>'
			ELSE
				CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN
					CASE WHEN ISNULL(@VTAB,'') = '5' THEN
						'<button class="w3-bar-item w3-round '+CASE WHEN ISNULL(@VTAB_SERV,'') = '' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>
						 <button class="w3-bar-item w3-round '+CASE WHEN ISNULL(@VTAB_SERV,'') = '10' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB_SERV'',''10'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-history w3-margin-right"></i>Historial</button>
						 <button class="w3-bar-item w3-round '+CASE WHEN ISNULL(@VTAB_SERV,'') = '11' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white w3-right" onclick="almacenarSeleccion(''TAB_SERV'',''11'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-chart-line w3-margin-right"></i>Gráfico Evolutivo</button>'
					ELSE
						'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV IN ('8','9') THEN 'w3-muhle-vocaturo' ELSE 'w3-muhle-color' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>'+
							CASE WHEN (ISNULL(@VID_DOCUM,'') <> '' AND @VTAB_SERV = '8') THEN 
								'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '8' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''8'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-book w3-margin-right"></i>Minuta de Gestion</button>' +
								CASE WHEN (ISNULL(@VID_DOCUM,'') <> '' AND @VOTRO_SERVICIO > 1) THEN
									'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '9' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''9'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-comment w3-margin-right"></i>Anexos</button>'
								ELSE '' END 
							ELSE 
								CASE WHEN @VTAB IN ('0','2') THEN
								'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '8' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''8'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-book w3-margin-right"></i>Minuta de Gestion</button>
								 <button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '9' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''9'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-comment w3-margin-right"></i>Anexos</button>' +
								 CASE WHEN @VTAB_SERV = '9' THEN
									CASE WHEN ISNULL(@VTAB_AGENDA,'') = '' THEN
										'<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Nuevo Anexo" onclick="goto('''+@FORM_ID+''',''3049C791-DD77-42F0-B8E6-7E9A8AAEA86D'');return false;"><i class="fa fa-plus"></i></button>'
									ELSE 
										'<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Volver" onclick="almacenarSeleccion(''TAB_SERV'',''9'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-arrow-alt-circle-left"></i></button>'
									END
								 ELSE '' END
								ELSE '' END
							END +
							CASE WHEN ((@VTAB_SERV = '8') OR (@VTAB_SERV = '9' AND ISNULL(@VTAB_AGENDA,'') <> '')) THEN
								'<button class="w3-bar-item w3-round w3-button w3-border w3-muhle-color w3-text-white w3-right" onclick="exportarAPDF(''table_SP_HOME_GRD_DET_AGENDA_40'',''' + ISNULL(@FILENAME,'') + '.pdf'',''' + ISNULL(@VTITULO,'') + ''');return false;"><i class="fas fa-file-pdf"></i></button>
								 <div class="w3-bar-item w3-round w3-padding-small w3-right">
									<select class="w3-input w3-round w3-border w3-muhle-text-11 w3-right" name="SP.EXPORTA_MG" onchange="goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;">
										<option value="0" '+CASE WHEN isnull(@VEXPORTA_DET,'') = '0' THEN 'selected="selected"' ELSE '' END+'>Consultor</option>
										<option value="0|1" '+CASE WHEN isnull(@VEXPORTA_DET,'') = '0|1' THEN 'selected="selected"' ELSE '' END+'>Interno</option>
									</select>
								 </div>'
							ELSE '' END
						END
				ELSE
					'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '0' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''0'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>
					<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '1' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+'  onclick="almacenarSeleccion(''TAB_SERV'',''1'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-calendar-alt w3-margin-right"></i>Visitas</button>
					<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '2' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+'  onclick="almacenarSeleccion(''TAB_SERV'',''2'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-shoe-prints w3-margin-right"></i>Datos Seguimiento</button>'+
					CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN
							'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '3' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''3'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-archive w3-margin-right"></i>Minuta de Cierre</button>
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '4' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+'  onclick="almacenarSeleccion(''TAB_SERV'',''4'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-list-alt w3-margin-right"></i>Plan Estrategico</button>'
							WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN
							'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '5' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''5'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard w3-margin-right"></i>Plan Auditoría</button>
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '6' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+'  onclick="almacenarSeleccion(''TAB_SERV'',''6'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard-list w3-margin-right"></i>Informe Auditoría</button>'
							WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN
							'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB_SERV = '7' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB_SERV'',''7'');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-clipboard-list w3-margin-right"></i>Informe Capacitación</button>'
					ELSE '' END +
					CASE WHEN @VTAB_SERV = '1' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="myFunction();return false;"><i class="fas fa-calendar-plus"></i>&nbsp;&nbsp;Agregar Visita</button>'
							WHEN @VTAB_SERV = '2' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''6DDF0683-6FD9-4D57-8FF0-C2FA07AE1397'');return false;"><i class="fas fa-edit"></i>&nbsp;&nbsp;Editar Datos</button>'
							WHEN @VTAB_SERV = '3' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');return false;"><i class="fas fa-archive"></i>&nbsp;&nbsp;Agregar Minuta</button>'
							WHEN @VTAB_SERV = '4' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''B0569958-40AB-49AD-8036-555088709D77'');return false;"><i class="fas fa-list-alt"></i>&nbsp;&nbsp;Agregar Plan</button>'
							WHEN @VTAB_SERV = '5' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''DFE8677A-7CCF-4D8E-A91D-4EB3F526393C'');return false;"><i class="fas fa-clipboard"></i>&nbsp;&nbsp;Agregar Plan</button>'
							WHEN @VTAB_SERV = '6' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''3F6EFE7E-110B-4A5E-953B-B0E5D49C0F16'');return false;"><i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Agregar Informe</button>' 
							WHEN @VTAB_SERV = '7' THEN
							'<button class="w3-bar-item w3-round w3-button w3-muhle-color w3-text-white w3-right" onclick="goto('''+@FORM_ID+''',''931875EA-23ED-4EEA-BF4F-8A53C7B1FB90'');return false;"><i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Agregar Informe</button>'
					ELSE ''	END +
					CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN '' ELSE
						'<span class="w3-bar-item w3-muhle-text-12 w3-round w3-right">'+CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN '' ELSE 
						'<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN
												'fas fa-user-tie"'
											WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN
												'fas fa-chalkboard-teacher"'
											WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN
												'fas fa-user-graduate"'
										ELSE '' END +' style="color:black;"></i>&nbsp;&nbsp;<b>' END+SUBSTRING(ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,''),1,80)+'</b></span>'
					END 
				END
			END + '
		</div>'
 
	SET @ODETALLE = @ODETALLE +
		'<div class="w3-container" style="padding:1px;"></div>'+
		CASE WHEN ISNULL(@VID_PROYECTO,'') = '' THEN
			'<table id="TableDet" class="w3-table-all">
			<tr style="height:470px;">
				<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>Debe Seleccionar un Proyecto</b></td>
			</tr>
			</table>'
		ELSE
			CASE WHEN ISNULL(@VTAB,'') = '5'  THEN 
					CASE WHEN ISNULL(@VTAB_SERV,'') = '' THEN
						'<div class="w3-container w3-padding" style="border: 2px solid #bdbdbd; max-width: 100%;">
		<div class="w3-row-padding">
 
		<!-- PANEL IZQUIERDO: INPUTS (100% en móvil, 1/3 en PC) -->
		<div class="w3-col m4 s12 w3-margin-bottom">
			<div class="w3-card w3-border w3-round w3-padding" style="box-sizing: border-box; display: flex; flex-direction: column; justify-content: space-between; min-height: 420px;">
				<div>
					<h5 class="w3-muhle-text-14" style="font-weight:700; color:#1e293b; margin-top: 0; margin-bottom: 8px;">
						Rentabilidad Periodo
					</h5>
				
					<label class="w3-muhle-text-12" style="margin-top: 6px; display: inline-block;">Periodo (YYYY-MM)</label>
					<input class="w3-input w3-border w3-round" type="month" name="SP.PERIODO">
				
					<label class="w3-muhle-text-12" style="margin-top: 6px; display: inline-block;">Ventas</label>
					<input class="w3-input w3-border w3-round montoReal" type="text" name="SP.DECIMAL_06" onkeyup="calcularRentabilidadReal()" onblur="formatearInput(this);">
 
					<label class="w3-muhle-text-12" style="margin-top: 6px; display: inline-block;">Compras</label>
					<input class="w3-input w3-border w3-round montoReal" type="text" name="SP.DECIMAL_07" onkeyup="calcularRentabilidadReal()" onblur="formatearInput(this);">
 
					<label class="w3-muhle-text-12" style="margin-top: 6px; display: inline-block;"><b>Utilidad Real</b></label>
					<input id="UTILIDAD_REAL" class="w3-input w3-border w3-light-grey w3-round" style="padding: 4px 8px;" readonly>
 
					<label class="w3-muhle-text-12" style="margin-top: 6px; display: inline-block;"><b>Rentabilidad Real (%)</b></label>
					<input id="RENTABILIDAD_REAL" class="w3-input w3-border w3-light-grey w3-round" style="padding: 4px 8px;" readonly>
				</div>
 
				<div style="text-align: right; margin-top: 12px;">
					<button 
						class="w3-button w3-muhle-color w3-medium w3-round w3-mobile"
						type="button"
						onclick="return guardarRentabilidadReal();">
						Guardar
					</button>
				</div>
			</div>
		</div>
 
		<!-- PANEL DERECHO: GRÁFICO (100% en móvil, 2/3 en PC) -->
		<div class="w3-col m8 s12">
			<div class="w3-card w3-border w3-round w3-padding" style="box-sizing: border-box; display: flex; flex-direction: column; min-height: 420px; height: 100%;">
				<h5 class="w3-muhle-text-14" style="font-weight:700; color:#1e293b; margin-top: 0; margin-bottom: 10px;">
					Rentabilidad Estimada vs. Real
				</h5>
				<div style="position: relative; flex: 1; width: 100%; min-height: 300px;">
					<canvas id="graficoRentabilidad"></canvas>
				</div>
			</div>
		</div>
 
			</div>
		</div>
 
					<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
						<script>
							var grafico;
 
							function calcularRentabilidadReal(){
								var txtMargen = document.getElementById("LBL_MARGEN") ? document.getElementById("LBL_MARGEN").innerHTML : "0";
								var estimada = numero(txtMargen);
 
								var elVentas = document.getElementsByName("SP.DECIMAL_06")[0];
								var elCompras = document.getElementsByName("SP.DECIMAL_07")[0];
 
								var ventas = elVentas ? numero(elVentas.value) : 0;
								var compras = elCompras ? numero(elCompras.value) : 0;
								var utilidad = ventas - compras;
								var real = ventas > 0 ? (utilidad * 100) / ventas : 0;
 
								var elUtilidad = document.getElementById("UTILIDAD_REAL");
								var elRentabilidad = document.getElementById("RENTABILIDAD_REAL");
 
								if(elUtilidad) elUtilidad.value = formatoPesos(utilidad);
								if(elRentabilidad) elRentabilidad.value = real.toFixed(2).replace(".",",") + " %";
 
								actualizarGrafico(estimada, real);
							}
 
							function actualizarGrafico(estimada, real){
								var canvas = document.getElementById("graficoRentabilidad");
								if(!canvas) return;
 
								var ctx = canvas.getContext("2d");
								if(grafico) grafico.destroy();
 
								var valEstimada = parseFloat(estimada) || 0;
								var valReal = parseFloat(real) || 0;
 
								/* Plugin custom en Canvas nativo para asegurar las etiquetas adentro en blanco */
								var pluginEtiquetasBlancas = {
									id: ''etiquetasBlancasCustom'',
									afterDatasetsDraw: function(chart) {
										var ctx = chart.ctx;
										chart.data.datasets.forEach(function(dataset, i) {
											var meta = chart.getDatasetMeta(i);
											meta.data.forEach(function(bar, index) {
												var val = dataset.data[index];
												if (val > 0) {
													var texto = val.toFixed(2).replace(".", ",") + " %";
													ctx.save();
													ctx.fillStyle = "#ffffff";
													ctx.font = "bold 12px sans-serif";
													ctx.textAlign = "right";
													ctx.textBaseline = "middle";
													ctx.fillText(texto, bar.x - 15, bar.y);
													ctx.restore();
												}
											});
										});
									}
								};
 
								grafico = new Chart(ctx, {
									type: "bar",
									plugins: [pluginEtiquetasBlancas],
									data: {
										labels: ["Rentabilidad Estimada", "Rentabilidad Real"],
										datasets: [{
											data: [valEstimada, valReal],
											backgroundColor: [
												"rgba(102, 6, 45, 0.95)", 
												valReal >= valEstimada ? "rgba(5, 150, 105, 0.95)" : "rgba(220, 38, 38, 0.95)"
											],
											borderColor: [
												"#66062D", 
												valReal >= valEstimada ? "#059669" : "#dc2626"
											],
											borderWidth: 1.5,
											borderRadius: 6,
											barThickness: 34
										}]
									},
									options: {
										indexAxis: ''y'',
										responsive: true,
										maintainAspectRatio: false,
										plugins: { 
											legend: { display: false }
										},
										scales: {
											x: { 
												min: 0, 
												max: 100,
												grid: { color: "rgba(226, 232, 240, 0.6)" },
												ticks: { color: "#64748b", stepSize: 10 }
											},
											y: { 
												grid: { display: false },
												ticks: { color: "#334155", font: { size: 12, weight: "500" } }
											}
										}
									}
								});
							}
 
							setTimeout(function(){
								calcularRentabilidadReal();
							}, 200);
 
							function guardarRentabilidadReal(){
								var elPeriodo = document.getElementsByName("SP.PERIODO")[0]; 
								var elVentas  = document.getElementsByName("SP.DECIMAL_06")[0]; 
								var elCompras = document.getElementsByName("SP.DECIMAL_07")[0]; 
 
								var periodo = elPeriodo ? elPeriodo.value.trim() : ""; 
 
								/* ----------------------------------------------------
								   VALIDACION
								   ---------------------------------------------------- */
								if(periodo === ""){ 
									alert("Debe seleccionar el período."); 
 
									if(elPeriodo){
										elPeriodo.focus();
									}
									return false; 
								}
 
								/* ----------------------------------------------------
								   VENTAS Y COMPRAS NO SON OBLIGATORIOS
								   Si están vacíos se envía 0
								   ---------------------------------------------------- */
								if(elVentas){
									if(elVentas.value.trim() === ""){
										elVentas.value = "0";
									}
 
									var ventas = numero(elVentas.value);
 
									if(isNaN(ventas)){
										ventas = 0;
									}
 
									elVentas.value = ventas;
									limpiarInput(elVentas);
								}
 
 
								if(elCompras){
									if(elCompras.value.trim() === ""){
										elCompras.value = "0";
									}
 
									var compras = numero(elCompras.value);
 
									if(isNaN(compras)){
										compras = 0;
									}
 
									elCompras.value = compras;
									limpiarInput(elCompras);
								}
 
								/* ----------------------------------------------------
								   IMPORTANTE:
								   SOLO SI PASO TODAS LAS VALIDACIONES
								   ---------------------------------------------------- */
								almacenarSeleccion(''ID_SERV_DELETE'', ''PERIODO'');
								goto(
									'''+@FORM_ID+''',
									''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5''
								);
								return false;
							}
						</script>'
 
					WHEN ISNULL(@VTAB_SERV,'') = '10' THEN
						CASE WHEN (@VCANT_PERIODO > 0) THEN ISNULL(@VTABLA_DET,'')
						ELSE
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>El Proyecto no tiene Historial de Periodo</b></td>
								</tr>
							</table>'
						END
 
					WHEN ISNULL(@VTAB_SERV,'') = '11' THEN
						CASE WHEN (@VCANT_PERIODOS_TOTAL > 0) THEN
							'<div class="w3-container w3-padding" style="border: 2px solid #bdbdbd; max-width: 100%;">
								<!-- TARJETAS KPI RESUMEN ESTILO VOCATURO -->
								<div class="w3-row-padding w3-margin-bottom">
									<div class="w3-third">
										<div class="w3-card w3-round w3-white w3-padding" style="border-left: 4px solid blue !important; box-shadow: 0 2px 6px rgba(0,0,0,0.04);">
											<span class="w3-muhle-text-12 w3-text-gray" style="font-weight: normal; letter-spacing: 0.3px;">Rentabilidad Real</span>
											<h4 style="margin: 2px 0 0 0; font-weight: normal; color: blue;">' + REPLACE(CONVERT(VARCHAR, ROUND(@VPROMEDIO_RENTA,2)), ',', '.') + '%</h4>
										</div>
									</div>
									<div class="w3-third">
										<div class="w3-card w3-round w3-white w3-padding" style="border-left: 4px solid #66062D !important; box-shadow: 0 2px 6px rgba(0,0,0,0.04);">
											<span class="w3-muhle-text-12 w3-text-gray" style="font-weight: normal; letter-spacing: 0.3px;">Margen Estimado Objetivo</span>
											<h4 style="margin: 2px 0 0 0; font-weight: normal; color: #66062D;">' + REPLACE(CONVERT(VARCHAR, ROUND(@VMARGEN_ESTIMADO_PROY,2)), ',', '.') + '%</h4>
										</div>
									</div>
									<div class="w3-third">
										<div class="w3-card w3-round w3-white w3-padding" style="border-left: 4px solid orange !important; box-shadow: 0 2px 6px rgba(0,0,0,0.04);">
											<span class="w3-muhle-text-12 w3-text-gray" style="font-weight: normal; letter-spacing: 0.3px;">Total Períodos Medidos</span>
											<h4 style="margin: 2px 0 0 0; font-weight: normal; color: orange;">' + CONVERT(VARCHAR, @VCANT_PERIODOS_TOTAL) + CASE WHEN @VCANT_PERIODOS_TOTAL = 1 THEN ' Período' ELSE ' Períodos' END + '</h4>
										</div>
									</div>
								</div>
 
								<!-- PANEL DEL GRÁFICO EVOLUTIVO -->
								<div class="w3-card w3-border w3-round w3-padding w3-white" style="height: 390px; display: flex; flex-direction: column;">
									<h5 class="w3-muhle-text-14" style="font-weight: normal; color: #1e293b; margin-top: 0; margin-bottom: 12px;">
										<i class="fas fa-chart-line" style="color: #66062D;"></i> Evolución de Rentabilidad por Períodos vs. Margen Estimado
									</h5>
									<div style="position: relative; flex: 1; width: 100%; min-height: 0;">
										<canvas id="graficoEvolutivo"></canvas>
									</div>
								</div>
							</div>
 
							<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
							<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2"></script>
							<script>
								setTimeout(function(){
									var canvas = document.getElementById("graficoEvolutivo");
									if(!canvas) return;
 
									var ctx = canvas.getContext("2d");
 
									/* Degradado verde esmeralda suave */
									var gradient = ctx.createLinearGradient(0, 0, 0, 300);
									gradient.addColorStop(0, "rgba(5, 150, 105, 0.18)");
									gradient.addColorStop(1, "rgba(5, 150, 105, 0.0)");
 
									if(typeof ChartDataLabels !== ''undefined''){
										Chart.register(ChartDataLabels);
									}
 
									var cantPeriodos = ' + CONVERT(VARCHAR, @VCANT_PERIODOS_TOTAL) + ';
 
									/* Plugin custom para dibujar las líneas horizontales de referencia completas aunque haya 1 solo registro */
									var pluginLineasReferencia = {
										id: ''lineasReferenciaFull'',
										beforeDraw: function(chart) {
											if (cantPeriodos === 1) {
												var ctx = chart.ctx;
												var yScale = chart.scales.y;
												var xScale = chart.scales.x;
 
												var valEstimado = ' + REPLACE(CONVERT(VARCHAR, ROUND(@VMARGEN_ESTIMADO_PROY,2)), ',', '.') + ';
												var valPromedio = ' + REPLACE(CONVERT(VARCHAR, ROUND(@VPROMEDIO_RENTA,2)), ',', '.') + ';
 
												var yEst = yScale.getPixelForValue(valEstimado);
												var yProm = yScale.getPixelForValue(valPromedio);
 
												ctx.save();
 
												// Línea Margen Estimado (Bordó)
												ctx.beginPath();
												ctx.setLineDash([4, 4]);
												ctx.strokeStyle = "#66062D";
												ctx.lineWidth = 1.5;
												ctx.moveTo(xScale.left, yEst);
												ctx.lineTo(xScale.right, yEst);
												ctx.stroke();
 
												// Línea Promedio Real (Azul)
												ctx.beginPath();
												ctx.setLineDash([5, 5]);
												ctx.strokeStyle = "#2563eb";
												ctx.lineWidth = 1.5;
												ctx.moveTo(xScale.left, yProm);
												ctx.lineTo(xScale.right, yProm);
												ctx.stroke();
 
												ctx.restore();
											}
										}
									};
 
									new Chart(ctx, {
										type: "line",
										plugins: [pluginLineasReferencia],
										data: {
											labels: [' + ISNULL(@VLABELS_PERIODOS, '') + '],
											datasets: [
												{
													label: "Rentabilidad Real",
													data: [' + ISNULL(@VDATA_RENT_PERIODOS, '') + '],
													borderColor: "#059669",
													backgroundColor: gradient,
													borderWidth: 2,
													fill: true,
													tension: 0.1,
													pointRadius: cantPeriodos === 1 ? 6 : 4,
													pointBackgroundColor: "#ffffff",
													pointBorderColor: "#059669",
													pointBorderWidth: 2,
													pointHoverRadius: 7,
													datalabels: {
														display: true,
														align: "top",
														anchor: "end",
														offset: 4,
														backgroundColor: null,
														color: "#059669",
														font: { weight: "600", size: 11 },
														formatter: function(value) {
															return value.toFixed(1).replace(".", ",") + "%";
														}
													}
												},
												{
													label: "Promedio Real (' + REPLACE(CONVERT(VARCHAR, ROUND(@VPROMEDIO_RENTA,2)), ',', '.') + '%)",
													data: cantPeriodos > 1 ? [' + ISNULL(@VDATA_PROMEDIO, '') + '] : [],
													borderColor: "#2563eb",
													borderWidth: 1.5,
													borderDash: [5, 5],
													fill: false,
													pointRadius: 0,
													datalabels: { display: false }
												},
												{
													label: "Margen Estimado (' + REPLACE(CONVERT(VARCHAR, ROUND(@VMARGEN_ESTIMADO_PROY,2)), ',', '.') + '%)",
													data: cantPeriodos > 1 ? [' + ISNULL(@VDATA_ESTIMADO, '') + '] : [],
													borderColor: "#66062D",
													borderWidth: 1.5,
													borderDash: [4, 4],
													fill: false,
													pointRadius: 0,
													datalabels: { display: false }
												}
											]
										},
										options: {
											responsive: true,
											maintainAspectRatio: false,
											layout: {
												padding: { top: 25, right: cantPeriodos === 1 ? 40 : 15, left: cantPeriodos === 1 ? 40 : 10, bottom: 5 }
											},
											plugins: {
												legend: { display: false },
												tooltip: {
													backgroundColor: "#0f172a",
													titleFont: { size: 12, weight: "normal" },
													bodyFont: { size: 11 },
													padding: 10,
													cornerRadius: 6,
													callbacks: {
														label: function(context) {
															return " " + context.dataset.label + ": " + context.raw.toFixed(2).replace(".", ",") + "%";
														}
													}
												}
											},
											scales: {
												x: {
													grid: { display: false },
													offset: cantPeriodos === 1, /* Centra el punto único en el medio */
													ticks: { 
														color: "#64748b", 
														font: { weight: "normal", size: 10 },
														maxRotation: cantPeriodos > 8 ? 45 : 0,
														minRotation: cantPeriodos > 8 ? 45 : 0
													}
												},
												y: {
													min: 0,
													max: 100,
													grid: { color: "rgba(226, 232, 240, 0.6)" },
													ticks: {
														color: "#64748b",
														font: { weight: "normal" },
														stepSize: cantPeriodos <= 8 ? 20 : 10,
														callback: function(v) { return v + "%"; }
													}
												}
											}
										}
									});
								}, 200);
							</script>'
						ELSE
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No existen períodos suficientes cargados para graficar la tendencia.</b></td>
								</tr>
							</table>'
						END
				END
			ELSE 	
				CASE WHEN ISNULL(@VTAB_SERV,'') = '' THEN
					'<table id="TableDet" class="w3-table-all">
					<tr style="height:470px;">
						<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>Debe Seleccionar un Servicio</b></td>
					</tr>
					</table>'
					WHEN ISNULL(@VTAB_SERV,'') = '0' THEN 
						'<div class="w3-container" style="border: 2px solid gray;">
								<div class="w3-row">
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Nombre&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.NOMBRE_SERV" value="' + ISNULL(@VNOMBRE_SERV_TMT,'') + '">
									</div>
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-map-marker-alt"></i>&nbsp;&nbsp;Lugar&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.LUGAR_SERV" value="' + ISNULL(@VLUGAR_SERV_TMT,'') + '">
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Inicio&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="date" name="SP.FECHA_INICIO_SERV" value="'+ISNULL(CONVERT(VARCHAR,@VFECHA_INI_TMT,23),'') +'">
									</div>
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Fin&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="date" name="SP.FECHA_FIN_SERV" value="'+ISNULL(CONVERT(VARCHAR,@VFECHA_FIN_TMT,23),'') +'">
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-third w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Horas Proyectadas&nbsp;&nbsp;<i class="fas fa-exclamation-circle w3-text-red"></i></label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.HORAS_SERV" value="' + ISNULL(@VHORAS_TMT,'') + '">
									</div>
									<div class="w3-third w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-dollar-sign"></i>&nbsp;&nbsp;Monto</label>
										<input class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" type="text" name="SP.MONTO_SERV" value="' + ISNULL(@VMONTO_TMT,'') + '">
									</div>
									<div class="w3-third w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-window-close"></i>&nbsp;&nbsp;Cierre</label>
										<select class="w3-input w3-border w3-padding-large w3-round w3-muhle-text-14" name="SP.CIERRE_SERVICIO">
											<option value="SI" '+CASE WHEN isnull(@VCIERRE_TMT,'') = 'SI' THEN 'selected="selected"' ELSE '' END+'>Si</option>
											<option value="NO" '+CASE WHEN isnull(@VCIERRE_TMT,'') = 'NO' THEN 'selected="selected"' ELSE '' END+'>No</option>
										</select>									
									</div>
								</div>
								<div class="w3-container w3-padding">
									<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''A77CE927-9D2D-4C15-91CE-34388075B9F7'');return false;">Guardar</btn>
								</div>
						</div>'+
						CASE WHEN  ISNULL(@VDESC_ERROR,'') = '' THEN
							''
						ELSE
							'<script>alert("'+isnull(@VDESC_ERROR,'')+'");</script>'
						END
 
					WHEN ISNULL(@VTAB_SERV,'') = '1' THEN 
						CASE WHEN (@VCANT_AGENDA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Agendas Cargadas</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '2' THEN 
						ISNULL(@VTABLA_DET,'')
					WHEN ISNULL(@VTAB_SERV,'') = '3' THEN 
						CASE WHEN (@VCANT_MC > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Minutas de Cierre Cargadas</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '4' THEN 
						CASE WHEN (@VCANT_PE > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Plan Estrategico Cargados</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '5' THEN 
						CASE WHEN (@VCANT_PA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Plan Auditoria Cargados</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '6' THEN 
						CASE WHEN (@VCANT_IA > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Informe Auditoria Cargados</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '7' THEN 
						CASE WHEN (@VCANT_IC > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
							'<table id="TableDet" class="w3-table-all">
								<tr style="height:470px;">
									<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Informe Capacitacion Cargados</b></td>
								</tr>
							</table>' END
					WHEN ISNULL(@VTAB_SERV,'') = '8' THEN
						'<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>'
					WHEN ISNULL(@VTAB_SERV,'') = '9' THEN
						CASE WHEN ISNULL(@VTAB_AGENDA,'') = '' THEN 
							CASE WHEN (@VCANT_ANEXO > 0) THEN ISNULL(@VTABLA_DET,'') ELSE 
								'<table id="TableDet" class="w3-table-all">
									<tr style="height:470px;">
										<td class="w3-muhle-text-12" style="text-align:center;vertical-align:middle;"><b>No Existen Anexos Cargados</b></td>
									</tr>
								</table>' END
					ELSE '<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>' END
				ELSE '' END
			END
		END
	END
 
	IF (@VID_AGENDA_SELEC <> '') BEGIN 
		
		SELECT	@VDIAS_AGENDA = DIAS,
				@VHORAS_AGENDA = DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA),
				@VFECHAD_AGENDA = CONVERT(VARCHAR,A.FECHA,103),
				@VFECHAH_AGENDA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
				@VESTADO_AGENDA = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
				@VESTADO_AGENDA_CODE = A.ESTADO,
				@VNORMA_AGENDA = ISNULL(A.NORMA,''),
				@VCONSULTORES_AGENDA = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
				@VCONSULTORES_AGENDA_DESC = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'A') END,
				@VOBSERV_CALIF_AGENDA = ISNULL(A.OBSERV_CALIF,''),
				@VOBSERV_AGENDA = ISNULL(A.OBSERVADOR,'')
		FROM	LK_AGENDA A
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
		WHERE	ID_AGENDA = @VID_AGENDA_SELEC
 
		WHILE LEN(@VNORMA_AGENDA) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VNORMA_AGENDA)
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VARNORMA
					SET @VARNORMA = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VNORMA_AGENDA, 1, @lnuPosComa - 1)
 
					SELECT	@VALOR = '<font style="font-size:11px;color:black;text-align:left">'+DESC_APTITUD+'</font>'
					FROM	LK_APTITUDES
					WHERE	ID_APTITUD = @lstDato
 
					SET @VDESCNORMAS = ISNULL(@VDESCNORMAS,'') + @VALOR + '</br>'
 
					SET @VNORMA_AGENDA = SUBSTRING(@VARNORMA, @lnuPosComa + 1, LEN(@VNORMA_AGENDA))
				END
			END
 
		SET @ODETALLE = @ODETALLE + 
			
			'<div class="w3-bar w3-round w3-muhle-text-14">
				<span class="w3-bar-item w3-round w3-muhle-color w3-text-white w3-left"><i class="fas fa-calendar-alt w3-margin-right"></i>Detalle Visita</span>'+
				CASE WHEN ISNULL(@VTAB_AGENDA,'') <> '0' THEN
				'<span class="w3-bar-item w3-muhle-text-12 w3-left">
					<i class="fas fa-calendar" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VFECHAD_AGENDA,'')+' - '+ISNULL(@VFECHAH_AGENDA,'')+'</b>&nbsp;&nbsp;
					<i class="fas fa-clock" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'')+'</b>&nbsp;&nbsp;
					<i class="fas fa-users" style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VCONSULTORES_AGENDA_DESC,'') + '</b></span>'
				ELSE '' END +
				CASE WHEN ISNULL(@VID_SERVICIO,'') = '' THEN '' ELSE '
				<button class="w3-bar-item w3-round w3-muhle-color w3-button w3-text-white w3-right" onclick="almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-arrow-alt-circle-left w3-margin-center"></i>&nbsp;&nbsp;Volver</button>
				<span class="w3-bar-item w3-muhle-text-12 w3-right">
					<i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
										'fas fa-user-tie"'
									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
										'fas fa-chalkboard-teacher"'
									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
										'fas fa-user-graduate"' ELSE '' END+' style="color:black;"></i>&nbsp;&nbsp;<b>' +ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,'')+'</b></span>' END + '
			</div>
			<div class="w3-container" style="padding:1px;"></div>
			<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>
			<div class="w3-bar w3-round w3-muhle-text-14">
				<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '0' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''0'');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-info-circle w3-margin-right"></i>General</button>
				<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '1' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''1'');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-road w3-margin-right"></i>Hoja de Ruta</button>
				<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '2' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''2'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-money-check-alt w3-margin-right"></i>Viáticos</button>
				<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '3' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''3'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-hand-holding-usd w3-margin-right"></i>Honorarios</button>' +
				CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
					'<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '4' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''4'');goto('''+@FORM_ID+''',''D2E01C1F-FB41-42EC-8ED8-88D38E9D9CA5'');return false;"><i class="fas fa-paperclip w3-margin-right"></i>Minuta de Visita</button>'
					WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN
					''
					WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN
					'<button class="w3-bar-item w3-round w3-button '+CASE WHEN @VTAB_AGENDA = '5' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-text-white" onclick="almacenarSeleccion(''TAB_AGENDA'',''5'');goto('''+@FORM_ID+''',''380EF2BE-409D-4D09-8446-1605A4823D81'');return false;"><i class="fas fa-tasks w3-margin-right"></i>CheckList</button>'
				END + 
				CASE WHEN @VTAB_AGENDA = '0' THEN 
					'<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Modificar" onclick="goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');return false;"><i class="fas fa-edit"></i></button>
					<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Editar" onclick="document.getElementById(''nuevoProceso'').style.display=''block'';return false;"><i class="fas fa-pen"></i></button>'
					WHEN @VTAB_AGENDA = '2' THEN
					'<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Nuevo Viático" onclick="goto('''+@FORM_ID+''',''9699BAC1-EB3A-41AF-AB6C-8B97A339EFA2'');return false;"><i class="fa fa-plus"></i></button>
					<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Parte Logistico" onclick="goto('''+@FORM_ID+''',''DCF9CC7E-1B8D-452E-9AB5-85B179D58A7D'');return false;"><i class="fas fa-clipboard-list"></i></button>
					<button class="w3-bar-item w3-right w3-border w3-round w3-button w3-muhle-color w3-text-white" title="Rendicion Viaticos" onclick="goto('''+@FORM_ID+''',''816D74E9-0C1C-478A-A699-CF1903A61B23'');return false;"><i class="fas fa-file-invoice-dollar"></i></button>'
					WHEN @VTAB_AGENDA = '3' THEN 
					'<button class="w3-bar-item w3-right w3-round w3-button w3-muhle-color w3-text-white" title="Nuevo Honorario" onclick="goto('''+@FORM_ID+''',''0B438E7D-728C-4D27-B9C5-534984C18EF9'');return false;"><i class="fa fa-plus"></i></button>'
					WHEN @VTAB_AGENDA = '4' THEN 
					'<button class="w3-bar-item w3-right w3-round w3-button w3-muhle-color w3-text-white" title="Nueva Minuta" onclick="goto('''+@FORM_ID+''',''0403354A-FDBD-4443-BF8D-ABE9C10AB373'');return false;"><i class="fa fa-plus"></i></button>'
					WHEN @VTAB_AGENDA = '5' THEN 
					'<button class="w3-bar-item w3-right w3-round w3-button w3-muhle-color w3-text-white" title="Nuevo CheckList" onclick="goto('''+@FORM_ID+''',''3F11610E-DB37-427B-997D-1507E8982A92'');return false;"><i class="fa fa-plus"></i></button>'
				ELSE '' END +'
			</div>
			<div class="w3-container" style="padding:1px;"></div>' +
			CASE WHEN ISNULL(@VTAB_AGENDA,'') = '0' THEN
				'<div class="w3-container w3-padding" style="border: 2px solid gray;">
						<div class="w3-row">
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VFECHAD_AGENDA,'') + '" disabled>
							</div>
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VFECHAH_AGENDA,'') + '" disabled>
							</div>
							<div class="w3-half w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VOBSERV_AGENDA,'') + '" disabled>
							</div>
						</div>
						<div class="w3-row">
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VESTADO_AGENDA,'') + '" disabled>
							</div>
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Días / Horas</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'') + '" disabled>
							</div>
							<div class="w3-half w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Observaciones Calificación</label>
								<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VOBSERV_CALIF_AGENDA,'') + '" disabled>
							</div>
						</div>
						<div class="w3-row">
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-ruler"></i>&nbsp;&nbsp;Normas</label></br>'+
								ISNULL(@VDESCNORMAS,'')+'
							</div>
							<div class="w3-quarter w3-padding">
								<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Profesionales</label></br>' + 
								ISNULL(@VCONSULTORES_AGENDA,'') + '
							</div>
						</div>
					</div>'
			ELSE 
				'<div class="w3-container" style="padding:1px;border-top:1px solid;border-color:gray;"></div>' 
			END
	END
 
	SET @OHEADER = '
	<style>
		.pagination a {color:black;padding: 8px 16px;text-decoration: none;}
		.pagination a.active {background-color:#7f1d46;color:white;}
		.pagination a:hover:not(.active) {background-color:#ddd;}
	</style>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-street-view w3-large"></i>&nbsp;&nbsp;Vista 360 Cliente</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver a Proyectos" onclick="almacenarSeleccion(''TAB'','''');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''','''+ISNULL(@VSTRUCTURE,'')+''');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'+
				'<div class="w3-row-padding">'+
					'<div class="w3-col s3">'+
						'<div class="w3-card-4 w3-round">
							<header class="w3-container w3-muhle-color w3-center w3-padding w3-round">
								<span class="w3-muhle-text-14" style="font-size:20px;color:white">&nbsp;&nbsp;'+ISNULL(@VRAZON_SOCIAL,'')+'</span>
							</header>
							<div class="w3-container w3-padding">
								<span class="w3-muhle-text-11 w3-padding">
									<i class="fas fa-address-card w3-margin-right w3-text-blue-gray w3-small"></i>&nbsp;'
									+ ISNULL(@VCUIT,'') + '
								</span></br>
								<span class="w3-muhle-text-11 w3-padding">
									<i class="fas fa-user w3-margin-right w3-text-blue-gray w3-small"></i>&nbsp;<b>Contactos</b></br>'
									+ ISNULL(REPLACE(@VCONTACTO,'/','</br>'),'') + '
								</span>
								<hr style="height:1px;border-width:0;color:gray;background-color:gray;">
								<span class="w3-muhle-text-11 w3-padding">
									<i class="fas fa-home w3-margin-right w3-text-blue-gray w3-small"></i>&nbsp;' 
									+ ISNULL(@VDIRECCION,'')  + 
								'</span>
							</div>
						</div>
					</div>'+
					'<div class="w3-col s9">
						<div class="w3-bar w3-round w3-muhle-text-14">
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB = '0' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB'',''0'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-project-diagram w3-margin-right"></i>Proyectos</button>
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB = '2' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" onclick="almacenarSeleccion(''TAB'',''2'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');almacenarSeleccion(''PROYECTO_ID'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-project-diagram w3-margin-right"></i>Finalizados</button>
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB = '1' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN @VID_PROYECTO = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB'',''1'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-cogs w3-margin-right"></i>Servicios</button>'
							+ CASE WHEN @VUSUARIO IN ('avocaturo','svocaturo','jjvocaturo','cbielsa','mbolivieri') THEN
								'<button class="w3-bar-item w3-round '+CASE WHEN @VTAB = '5' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN @VID_PROYECTO = '' THEN 'disabled' ELSE '' END+' onclick="almacenarSeleccion(''TAB'',''5'');almacenarSeleccion(''NRO_PAGINA'',''0'');almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''TAB_AGENDA'','''');almacenarSeleccion(''PROYECTO_SERV_ID'','''');almacenarSeleccion(''AGENDA_ID'','''');goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;"><i class="fas fa-chart-line w3-margin-right"></i>Rentabilidad</button>'
							  ELSE '' END+ '
							<button class="w3-bar-item w3-round '+CASE WHEN @VTAB = '1' THEN 'w3-muhle-color' ELSE 'w3-muhle-vocaturo' END+' w3-button w3-text-white" '+CASE WHEN @VID_PROYECTO = '' THEN 'disabled' ELSE '' END+' title="Nuevo" onclick="almacenarSeleccion(''TAB_SERV'','''');almacenarSeleccion(''PROYECTO_SERV_ID'',''N'');almacenarSeleccion(''AGENDA_ID'','''');almacenarSeleccion(''TAB_AGENDA'','''');goto('''+@FORM_ID+''',''F8B6A5CD-5252-4CDF-ABEA-67260485E937'');return false;"><i class="fa fa-plus"></i></button>
							<span class="w3-bar-item w3-muhle-text-12 w3-round w3-right">'+CASE WHEN @VID_PROYECTO = '' THEN '' ELSE '<i class="fas fa-project-diagram" style="color:black;"></i>&nbsp;&nbsp;<b>' END+ISNULL(SUBSTRING(@VNOMBRE_PROY,1,80),'')+'</b></span>
						</div>
						<div class="w3-container" style="padding:1px;"></div>
						<div id="table1">'+ISNULL(@VTABLA,'')+'</div>
						<div class="w3-container w3-center" style="padding:8px;"></div>
						'+ISNULL(@VPAGINADO,'')+'
						<div class="w3-container w3-center" style="padding:8px;">
							<span class="w3-muhle-text-12">'+CASE WHEN @VTOTAL <> '0' THEN
							'Página '+ CONVERT(VARCHAR,@PageNumber+1)+' de '+CONVERT(VARCHAR,@VTOTAL_PAGINA)+', 
								mostrando filas ' + CASE WHEN (@PageNumber = 0) THEN '1' ELSE CONVERT(VARCHAR,(@PageNumber*5) + 1) END + ' a la '+
								CASE WHEN (@PageNumber + 1 < @VTOTAL_PAGINA) THEN
									CONVERT(VARCHAR,(@PageNumber*5) + 5) 
								ELSE 
									CONVERT(VARCHAR,@VTOTAL)
								END +' de '+CONVERT(VARCHAR,@VTOTAL)
								ELSE
									CASE WHEN @VTAB = '5' THEN '' ELSE 
										'No se han encontrado resultados para esta búsqueda.'
									END
								END + '</span>
						</div>
					</div>
				</div>'+
				CASE WHEN ISNULL(@VMENSAJE,'') <> '' THEN ISNULL(@VMENSAJE,'') ELSE '' END+
				'<script>
					function myFunction() {
						'+CASE WHEN @DIF_HORAS_SERV <= 0 THEN 
							'alert("Revise el total de Horas del Servicio");return false;'
						  ELSE 
							'goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');return false;'
						  END +'
					}
				</script>
				<!-- PDFMake -->
				<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.9/pdfmake.min.js"></script>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.9/vfs_fonts.js"></script>
				<script>
					(function () {
					  function getBase64Image(imgElement) {
						try {
						  var canvas = document.createElement("canvas");
						  canvas.width = imgElement.naturalWidth || imgElement.width || 0;
						  canvas.height = imgElement.naturalHeight || imgElement.height || 0;
						  if (!canvas.width || !canvas.height) return null;
						  var ctx = canvas.getContext("2d");
						  ctx.drawImage(imgElement, 0, 0);
						  return canvas.toDataURL("image/png");
						} catch (e) {
						  console.warn("No se pudo convertir la imagen a Base64:", e);
						  return null;
						}
					  }
 
					  function clean(cell) {
						var html = cell.innerHTML || "";
						html = html.replace(/<br\s*\/?>/gi, "\n");
						html = html.replace(/&nbsp;/gi, " ");
						html = html.replace(/<[^>]+>/g, "");
						return html.trim();
					  }
 
					  function isPdfOnlyCell(cell) {
						var html = (cell && cell.innerHTML) || "";
						if (/data-pdf-only\s*=\s*["'']?1/i.test(html)) return true;
						if (/style\s*=\s*["''][^"'']*display\s*:\s*none/i.test(html)) return true;
						return false;
					  }
 
					  function isIntroRow(tr) {
						if (!tr || !tr.cells || !tr.cells.length) return false;
						for (var i = 0; i < tr.cells.length; i++) {
						  if (!isPdfOnlyCell(tr.cells[i])) return false;
						}
						return true;
					  }
 
					  function rowText(tr) {
						var parts = [];
						for (var i = 0; i < tr.cells.length; i++) {
						  var t = clean(tr.cells[i]);
						  if (t) parts.push(t);
						}
						return parts.join("  ");
					  }
 
					  function isDatosGenerales(txt) { return /^Datos\s*Generales\s*$/i.test(txt); }
					  function isCierreProyecto(txt) { return /Cierre\s+de\s+proyecto/i.test(txt); }
 
					  function exportarAPDF(tableId, fileName, headerText) {
						var table = document.getElementById(tableId);
						if (!table) { console.error("No se encontró la tabla:", tableId); return; }
 
						var thead = table.tHead;
						var tbody = table.tBodies && table.tBodies[0] ? table.tBodies[0] : table;
 
						var headerRow = [];
						if (thead && thead.rows.length) {
						  var trh = thead.rows[0];
						  for (var hc = 0; hc < trh.cells.length; hc++) {
							headerRow.push({ text: clean(trh.cells[hc]), style: "tableHeader" });
						  }
						}
 
						var introBody = [];
						var body = [];
						var headerTaken = !!(thead && thead.rows.length);
 
						var rows = Array.from(tbody.rows);
						for (var r = 0; r < rows.length; r++) {
						  var tr = rows[r];
 
						  if (isIntroRow(tr)) {
							var txtIntro = rowText(tr);
							if (/^Cliente:\s*/i.test(txtIntro)) {
							  introBody.push([{ text: [{ text: "Cliente: ", bold: true }, { text: txtIntro.replace(/^Cliente:\s*/i, "") }], style: "introCell" }]);
							  continue;
							}
							if (/^Proyecto:\s*/i.test(txtIntro)) {
							  introBody.push([{ text: [{ text: "Proyecto: ", bold: true }, { text: txtIntro.replace(/^Proyecto:\s*/i, "") }], style: "introCell" }]);
							  continue;
							}
							introBody.push([{ text: txtIntro, style: "introCell" }]);
							continue;
						  }
 
						  var txtRow = rowText(tr);
 
						  if (isDatosGenerales(txtRow) || isCierreProyecto(txtRow)) {
							var colsCount = tr.cells.length || (body[0] ? body[0].length : (headerRow.length || 1));
							if (!headerTaken) headerTaken = true;
							var fwCell = { text: txtRow, style: "w3-muhle-vocaturo", colSpan: colsCount, alignment: "center" };
							var filler = new Array(Math.max(colsCount - 1, 0)).fill({});
							body.push([fwCell].concat(filler));
							continue;
						  }
 
						  var outRow = [];
						  for (var c = 0; c < tr.cells.length; c++) {
							var t = clean(tr.cells[c]);
							if (!headerTaken) {
							  outRow.push({ text: t, style: "tableHeader" });
							} else {
							  outRow.push({ text: t, style: (c === 0 ? "col1Cell" : "col2Cell") });
							}
						  }
						  if (!headerTaken) headerTaken = true;
						  if (outRow.length) body.push(outRow);
						}
 
						if (headerRow.length) body.unshift(headerRow);
						if (!body.length) body = [[{ text: "Sin datos", style: "tableBody" }]];
 
						var widths = (body[0] && body[0].length === 2) ? ["40%", "60%"] : Array((body[0] && body[0].length) || 1).fill("*");
 
						var logoElemIzq = document.getElementById(''LogoIzq'');
						var logoBase64Izq = logoElemIzq ? getBase64Image(logoElemIzq) : null;
						var logoElemDer = document.getElementById(''LogoDer'');
						var logoBase64Der = logoElemDer ? getBase64Image(logoElemDer) : null;
 
						var titulo =
						  (headerText && String(headerText).trim()) ||
						  (document.querySelector(".w3-muhle-text-20") && document.querySelector(".w3-muhle-text-20").innerText) ||
						  "Minuta de Gestión Auditoria";
 
						var docDefinition = {
						  pageSize: "A4",
						  pageMargins: [30, 40, 30, 40],
						  styles: {
							headerTitle: { fontSize: 12, bold: true },
							tableHeader: { bold: true, fontSize: 10, fillColor: "#800040", color: "white" },
							tableBody:   { fontSize: 11, color: "#222" },
							col1Cell:    { fontSize: 9,  bold: true, color: "#222", fillColor: "#E6E6E6" },
							col2Cell:    { fontSize: 8,  color: "#222" },
							introCell:   { fontSize: 10, color: "#222", margin: [6, 4, 6, 4] },
							"w3-muhle-vocaturo": {
							  fontSize: 8,
							  bold: true,
							  color: "#FFFFFF",
							  fillColor: "#9e5674",
							  margin: [0, 0, 0, 0],
							  alignment: "center",
							  lineHeight: 1.0
							}
						  },
						  content: [
							{
							  columns: [
								logoBase64Izq ? { image: logoBase64Izq, fit: [100, 60], alignment: "left" } : { text: "" },
								{ text: titulo, style: "headerTitle", alignment: "center", margin: [0, 22, 0, 0] },
								logoBase64Der ? { image: logoBase64Der, fit: [100, 60], alignment: "right" } : { text: "" }
							  ],
							  widths: [''auto'', ''*'', ''auto''],
							  columnGap: 10,
							  margin: [0, 0, 0, 10]
							},
							...(introBody.length ? [{
							  table: { widths: ["*"], body: introBody },
							  layout: {
								hLineWidth: function() { return 0.5; },
								vLineWidth: function() { return 0.5; },
								hLineColor: function() { return "#BDBDBD"; },
								vLineColor: function() { return "#BDBDBD"; },
								paddingLeft:   function(){ return 8; },
								paddingRight:  function(){ return 8; },
								paddingTop:    function(){ return 4; },
								paddingBottom: function(){ return 4; }
							  },
							  margin: [0, 0, 0, 8]
							}] : []),
							{
							  table: { headerRows: 1, widths: widths, body: body },
							  layout: {
								hLineWidth: function() { return 0.5; },
								vLineWidth: function() { return 0.5; },
								hLineColor: function() { return "#BDBDBD"; },
								vLineColor: function() { return "#BDBDBD"; },
								paddingLeft:  function() { return 8; },
								paddingRight: function() { return 8; },
								paddingTop:   function(rowIndex, node) { return isVocaturoRow(rowIndex, node) ? 2 : 6; },
								paddingBottom:function(rowIndex, node) { return isVocaturoRow(rowIndex, node) ? 2 : 6; }
							  }
							}
						  ],
						  defaultStyle: { font: "Roboto", fontSize: 9 }
						};
 
						function isVocaturoRow(rowIndex, node) {
						  var row = (node && node.table && node.table.body && node.table.body[rowIndex]) || [];
						  for (var i = 0; i < row.length; i++) {
							var cell = row[i];
							if (!cell) continue;
							var st = cell.style;
							if (typeof st === "string" && st === "w3-muhle-vocaturo") return true;
							if (Array.isArray(st) && st.indexOf("w3-muhle-vocaturo") >= 0) return true;
						  }
						  return false;
						}
 
						pdfMake.createPdf(docDefinition).download(fileName || "'+isnull(@FILENAME,'')+'");
					  }
 
					  window.exportarAPDF = exportarAPDF;
					})();
					</script>'
 
	SET @OCLIENTE = isnull(@ODETALLE,'') +
					CASE WHEN ISNULL(@VTAB_AGENDA,'') = '0' THEN
					'<div id="nuevoProceso" class="w3-modal w3-round">
						<div class="w3-modal-content w3-round">
							<header class="w3-container w3-muhle-color w3-round-up w3-padding">
								<p class="w3-muhle-text-14" style="font-size:20px;color:white">'+ISNULL(@VRAZON_SOCIAL,'')+'</p>
								<p class="w3-muhle-text-14" style="color:white"><i class="fas fa-project-diagram"></i>&nbsp;&nbsp;' +ISNULL(SUBSTRING(@VNOMBRE_PROY,1,80),'')+'</p>
								<p class="w3-muhle-text-14" style="color:white"><i class="'+ CASE WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '1' THEN 
																										'fas fa-user-tie"'
																									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '2' THEN 
																										'fas fa-chalkboard-teacher"'
																									WHEN ISNULL(@VTIPO_SERV_SELEC,'') = '3' THEN 
																										'fas fa-user-graduate"' ELSE '' END+'></i>&nbsp;&nbsp;' +ISNULL(@VNOMBRE_SERV_SELEC,'')+' - '+ISNULL(@VLUGAR_SERV_SELEC,'')+'</p>
							</header>
							<div class="w3-container w3-padding-large">
								<div class="w3-row">
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Desde</label>
										<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VFECHAD_AGENDA,'') + '" disabled>
									</div>
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Fecha Hasta</label>
										<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VFECHAH_AGENDA,'') + '" disabled>
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clock"></i>&nbsp;&nbsp;Días / Horas</label>
										<input class="w3-input w3-border w3-round w3-muhle-text-14" value="' + ISNULL(@VDIAS_AGENDA,'') + ' / ' + ISNULL(@VHORAS_AGENDA,'') + '" disabled>
									</div>
									<div class="w3-half w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-users"></i>&nbsp;&nbsp;Profesionales</label></br>' + 
										ISNULL(@VCONSULTORES_AGENDA,'') + '
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-row w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="far fa-play-circle"></i>&nbsp;&nbsp;Estado</label>
										<select class="w3-input w3-border w3-round w3-muhle-text-14" id="cmb1" name="SP.AGENDA_ESTADO"></select>
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-row w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones</label>
										<input class="w3-input w3-border w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_OBSERVADOR" value="' + ISNULL(@VOBSERV_AGENDA,'') + '">
									</div>
								</div>
								<div class="w3-row">
									<div class="w3-row w3-padding">
										<label class="w3-muhle-text-14">&nbsp;<i class="fas fa-clipboard-list"></i>&nbsp;&nbsp;Observaciones Calificación</label>
										<input class="w3-input w3-border w3-round w3-muhle-text-14" type="text" name="SP.AGENDA_OBSERV_CALIF" value="' + ISNULL(@VOBSERV_CALIF_AGENDA,'') + '" disabled>
									</div>
								</div>
							</div>
							<div class="w3-container w3-border-top w3-padding-16 w3-light-grey w3-round-down">
								<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="goto('''+@FORM_ID+''',''7B62AD63-D2A5-40B3-90C4-45A11E8DD67A'');">Guardar</btn>
								<btn type="btn" class="w3-button w3-muhle-color w3-medium w3-round" onclick="document.getElementById(''nuevoProceso'').style.display=''none''">Cancelar</btn>
							</div>
						</div>
					</div>
					<script>BuildAjaxSPCombo('''+@FORM_ID+''',''cmb1'', ''' + '260022DF-4FC1-4944-809E-BC3834834FD1' + ''', ''' + ISNULL(@VESTADO_AGENDA_CODE,'') +''', '''');</script>'
					ELSE 
						CASE WHEN @VTAB_SERV = '9' THEN ''
						ELSE '' END
					END
 
	IF (@VTAB_AGENDA IN ('1','2','3','4','5') OR (@VTAB_SERV IN ('8','9'))) BEGIN
		SET @OCLIENTE = @OCLIENTE +
								'<div class="w3-row w3-back w3-light-grey">
									<div class="w3-col w3-padding">
										<div class="w3-card-4 w3-round">'
	END
 
	SELECT	@VOBSERV_HR = ISNULL(OBSERVACIONES,'')
	FROM	LK_PROYECTO_DOCUM 
	WHERE	ID_AGENDA = @VID_AGENDA_SELEC
 
	SET @OBUTTON = 
		CASE WHEN @VTAB_AGENDA = '1' THEN
						'<div class="w3-container" style="padding:2px;border-top:1px solid;border-color:gray;"></div>
						<div>
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-font"></i>&nbsp;&nbsp;Observaciones Hoja de Ruta</label>
							<textarea class="w3-input w3-border w3-round w3-muhle-text-12" type="text" name="SP.OBSERVACION_HR" maxlength="4000" rows="3" cols="50" value="' + ISNULL(@VOBSERV_HR,'') + '">' + ISNULL(@VOBSERV_HR,'') + '</textarea>
						</div>
						<div class="w3-container" style="padding:1px;"></div>
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="saveValues(''BUFFER'');goto('''+@FORM_ID+''',''441D2446-B86C-4A60-AD37-1325060BFCCF'');return false;">Guardar</btn>
						</div>
					</div>
			</div>
			<script>var dic=[];function toggleCombo(i){dic[i.id]=i.value}function saveValues(i){var a="";for(var c in dic){a=a+c+"="+dic[c]+"|"}saveSelection(i,a)}</script>'
			WHEN (@VTAB_AGENDA IN ('2','3','4','5')) THEN
					'</div>
				</div>
			</div>
			<script>var dic=[];function toggleCombo(i){dic[i.id]=i.value}function saveValues(i){var a="";for(var c in dic){a=a+c+"="+dic[c]+"|"}saveSelection(i,a)}</script>'
		ELSE
			CASE WHEN ((@VTAB_SERV = '8') OR (@VTAB_SERV = '9') AND (ISNULL(@VTAB_AGENDA,'') <> '')) THEN
						'<div class="w3-container" style="padding:1px;"></div>
						<div class="w3-container w3-padding">
							<btn type="btn" class="w3-right w3-button w3-muhle-color w3-medium w3-round" onclick="saveValuesCombo(''BUFFER'');goto('''+@FORM_ID+''',''441D2446-B86C-4A60-AD37-1325060BFCCF'');return false;">Guardar</btn>
						</div>
					</div>
				</div>
			</div>
			<div><img class="w3-muhle-logo" id="LogoIzq" src="../img/logo_izq.jpg" style="display:none;"></div>
			<div><img class="w3-muhle-logo" id="LogoDer" src="../img/logo_der.jpg" style="display:none;"></div>
			<script>var dic2=[];function toggleCombo(i){dic2[i.id]=i.value;}function saveValuesCombo(i){var a="";for(var c in dic2){a=a+c+"="+dic2[c]+"|"}almacenarSeleccion(i,a);}</script>
			<script>function iniDic(){var str = document.getElementsByName("CALL.BUFFER:ctl_52")[0].value;var res = str.split("|");res.forEach(func);}</script>
			<script>function func(item, index){var val = item.split("=");if (val[0]!==""){dic2[val[0]]=val[1];}}iniDic();</script>'
			ELSE '' END
		END
 
	UPDATE	XAGENDA
	SET		AGENDA_DESDE = NULL,
			AGENDA_HASTA = NULL,
			AGENDA_FECHA = NULL,
			FECHA_SELEC = NULL,
			ERROR = NULL,
			DESC_ERROR = NULL,
			HOJA_RUTA_ID = NULL,
			PROVEEDOR_ID = NULL,
			TIPO_PROV = NULL,
			NRO_FACTURA_PROV = NULL,
			CANT_PERSONAS_PROV = NULL,
			DESCRIP_SERVICIO_PROV = NULL,
			FECHA_FACTURA_PROV = NULL,
			PRECIO_FINAL_PROV = NULL,
			FORMA_PAGO_PROV = NULL,
			CANT_CUOTAS_PROV = NULL,
			ESTADO_PAGO_PROV = NULL,
			FECHA_ULT_PAGO_PROV = NULL,
			PRECIO_CUOTA_PROV = NULL,
			FECHA_PROX_VTO_PROV = NULL,
			SALDO_PEND_PROV = NULL,
			DESTINO_PROV = NULL,
			FECHA_DESDE_SERV_PROV = NULL,
			FECHA_HASTA_SERV_PROV = NULL,
			TIPO_CONSULTOR_PROV = NULL,
			CONSULTOR_PROV = NULL,
			DESC_FORMA_PAGO_PROV = NULL,
			HONOR_FECHA = NULL,
			HONOR_LUGAR = NULL,
			HONOR_CONSULTOR = NULL,
			HONOR_IMPORTE = NULL,
			CONS_FECHA_MC = NULL,
			CONS_OBSERV_MC = NULL,
			AUDI_FECHA_PA = NULL,
			AUDI_OBSERV_PA = NULL,
			AUDI_FECHA_IA = NULL,
			AUDI_OBSERV_IA = NULL,
			CAPA_FECHA_IC = NULL,
			CAPA_OBSERV_IC = NULL,
			ID_MINUTA = NULL,
			FECHA_CLC = NULL,
			NOMBRE_CLC = NULL,
			CURSO_CLC = NULL,
			ASISTENTES_CLC = NULL,
			OBSERVACION_HR = NULL,
			ID_SERV_DELETE = NULL
	WHERE	PAR_KEY = @IPKEYJOB
 
END
