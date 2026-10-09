CREATE PROCEDURE [dbo].[HOME_INICIO_PLANIF]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @OTABLA	AS VARCHAR(MAX) OUTPUT,
 @OTOTAL	AS INT OUTPUT)
AS
 
DECLARE		
	@VFECHA_DESDE		DATETIME,
	@VFECHA_HASTA		DATETIME,
	@VF_CLIENTE			VARCHAR(50),
	@VF_PROYECTO		VARCHAR(50),
	@VF_SERVICIO		VARCHAR(50),
	@VFILTRO			VARCHAR(50),
	@Pagina				INT,
	@vindicador			varchar(max),
	@vcliente			varchar(max),
	@vproyecto			varchar(max),
	@vobs				varchar(max),
	@vservicio			varchar(max),
	@vnormas			varchar(max),
	@vfechad			varchar(max),
	@vfechah			varchar(max),
	@vdias				varchar(max),
	@vhoras				varchar(max),
	@vconsultores		varchar(max),
	@vdetalle			varchar(max)
 
BEGIN	
 
	SELECT	@VFILTRO = ISNULL(FILTRO,''),
			@Pagina = (CONVERT(INT,ISNULL(NRO_PAGINA,0)))*10
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	IF (@VFILTRO = '') BEGIN
		SELECT	@VFECHA_DESDE = GETDATE() - 5,--PrimerDiaMes, 
				@VFECHA_HASTA = GETDATE() + 10--UltimoDiaMes 
		FROM	Calendar 
		WHERE	Fecha = convert(varchar,GETDATE(),113)	
 
		UPDATE	XAGENDA 
		SET		FECHA_DESDE = @VFECHA_DESDE, 
				FECHA_HASTA = @VFECHA_HASTA
		WHERE	PAR_KEY = @IPKEYJOB	
 
	END ELSE BEGIN
 
		SELECT	@VFECHA_DESDE = FECHA_DESDE,
				@VFECHA_HASTA = FECHA_HASTA,
				@VF_CLIENTE = ISNULL(INICIO_CLIENTE,''),
				@VF_PROYECTO = ISNULL(PROYECTO,''),
				@VF_SERVICIO = ISNULL(SERVICIO,'')
		FROM	XAGENDA
		WHERE	PAR_KEY = @IPKEYJOB
 
	END
 
	--IF (@TIPO = 'D') BEGIN
 
		SET @OTABLA = '
		<table id="Table1" class="w3-table-all w3-card-4">
			<tr style="background-color:gray;">
				<th><div class="w3-center" style="font-size:13px"></div></th>
				<th><div class="w3-left" style="font-size:13px">Cliente</div></th>
				<th><div class="w3-left" style="font-size:13px">Proyecto</div></th>
				<th><div class="w3-center" style="font-size:13px">Obs</div></th>
				<th><div class="w3-center" style="font-size:13px">Servicio</div></th>
				<th><div class="w3-center" style="font-size:13px">Normas</div></th>
				<th><div class="w3-center" style="font-size:13px">Desde</div></th>
				<th><div class="w3-center" style="font-size:13px">Hasta</div></th>
				<th><div class="w3-center" style="font-size:13px">Días</div></th>
				<th><div class="w3-center" style="font-size:13px">Horas</div></th>
				<th><div class="w3-left" style="font-size:13px">Profesionales</div></th>
				<th><div class="w3-center" style="font-size:13px">Ver</div></th>
			</tr>'
 
		DECLARE Planifica CURSOR FOR
		SELECT	'<div class="w3-center" style="font-size:15px">'+
				case [dbo].[FN_GET_STATUS_AGENDA] (A.ID_AGENDA) 
				WHEN 'R' THEN	
					'<i class="fas fa-circle w3-large" style="cursor:pointer;color:red;" title="Indicador"></i>'
				WHEN 'N' THEN
					'<i class="fas fa-circle w3-large" style="cursor:pointer;color:orange;" title="Indicador"></i>'	 
				WHEN 'A' THEN
					'<i class="fas fa-circle w3-large" style="cursor:pointer;color:yellow;" title="Indicador"></i>'
				WHEN 'V' THEN
					'<i class="fas fa-circle w3-large" style="cursor:pointer;color:green;" title="Indicador"></i>'
				WHEN 'C' THEN	
					'<i class="fas fa-circle w3-large" style="cursor:pointer;color:#5DADE2;" title="Indicador"></i>'	
				END	+ '</div>'																												AS Indicador, --ESTADO
			'<div class="w3-left" style="font-size:13px">'+C.RAZON_SOCIAL_CLIENTE + '</div>'												AS Cliente, --CLIENTE
			'<div class="w3-left" style="font-size:13px">'+'('+P.CODIGO+') - '+P.NORMA_REF + ' - ' + '<b>'+ISNULL(ps.NOMBRE,'')+'<b></div>'	AS Proyecto, --PROYECTO
			/*'<div class="tooltip w3-center">' +
			CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN
				''
			ELSE
				'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:red;" title="Obs. Calificacion">'
			END + '
				<span class="tooltiptext">'+'<font style="font-size:10px;color:black;text-align:left">'+CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_CALIF END+
				'</font></span>
			</i>
			</div>'	
			+ '<br>' + 
			'<div class="tooltip w3-center">' +
			CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN 
				''
			ELSE 
				'<i class="fas fa-clipboard-check w3-large" style="cursor:pointer;color:blue;" title="Obs. Logistica">' 
			END + '
				<span class="tooltiptext">'+'<font style="font-size:10px;color:black;text-align: left">'+CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_LOGISTICA END +
				'</font></span>
			</i>
			</div>'
			+ '<br>' + 
			'<div class="tooltip w3-center">' +
			CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN
				''
			ELSE
				'<i class="fas fa-address-book w3-large" style="cursor:pointer;color:green;" title="Obs. Hoja Ruta">'
			END + '
				<span class="tooltiptext">'+'<font style="font-size:10px;color:black;text-align: left">'+CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE DOC.OBSERVACIONES END +
				'</font></span>
			</i>
			</div>'															AS Obs,*/
			'Obs. Calificacion:&nbsp;'+CASE WHEN ISNULL(A.OBSERV_CALIF,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_CALIF END+ char(10)+
			'Obs. Logistica:&nbsp;'+CASE WHEN ISNULL(A.OBSERV_LOGISTICA,'') = '' THEN 'Sin Observaciones' ELSE A.OBSERV_LOGISTICA END+ char(10)+
			'Obs. Hoja Ruta:&nbsp;'+CASE WHEN ISNULL(DOC.OBSERVACIONES,'') = '' THEN 'Sin Observaciones' ELSE DOC.OBSERVACIONES END	AS Obs,
			'<div class="w3-center">'+
			'<i class="' + 
				CASE	WHEN A.ID_SERVICIO = '1' THEN 'fas fa-user-tie w3-large"'
						WHEN A.ID_SERVICIO = '2' THEN 'fas fa-chalkboard-teacher w3-large"'
						WHEN A.ID_SERVICIO = '3' THEN 'fas fa-user-graduate w3-large"' END +
							'style="cursor:pointer;" title="'+	CASE WHEN A.ID_SERVICIO = '1' THEN 
																		'Consultoria"'
																	WHEN A.ID_SERVICIO = '2' THEN 
																		'Auditoria"'
																	WHEN A.ID_SERVICIO = '3' THEN 
																		'Capacitacion"' 
																END + '></i>'+'</div>'																							AS Servicio, --SERVICIO
			'<div class="w3-center" style="font-size:13px">'+ 
				'<i class="fas fa-info-circle w3-large" style="cursor:pointer;color:teal;" title="'+REPLACE(dbo.FN_GET_NORMA_HTML('',A.NORMA,''),'</br>',char(10))+'"></i>'
			+'</div>'	AS Normas, --NORMA
			'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA,103) +'</div>'																				AS Fdesde, --FECHA DESDE
			'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,FECHA_HASTA,103) +'</div>'																		AS Fhasta, --FECHA HASTA
			'<div class="w3-center" style="font-size:13px">'+ CONVERT(VARCHAR,ISNULL(A.DIAS,'')) +'</div>'																		AS Dias,
			'<div class="w3-center" style="font-size:13px">'+ DBO.[FN_GET_AGENDA_HORAS] (A.ID_AGENDA) +'</div>'																	AS Horas,
			'<div class="w3-left" style="font-size:13px">'+ CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 
				'Sin Consultor' ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END +
				'<span style="font-size:10px;color:blue;text-align: left" title="Observador">'+ISNULL(A.OBSERVADOR,'')+'</span>'+'</div>'										AS Prof,
			'<div class="w3-center">'+ 
				'<i class="fas fa-calendar-alt w3-large" style="cursor:pointer;" title="Ver Visita" onclick="almacenarSeleccion(''AGENDA_ID'','''+cast(A.ID_AGENDA as varchar)+''');goto('''+''+''',''413A3F03-AD67-44E3-8907-C81085611C20''); return false;"></i>'
			+'</div>'																																							AS Ver
		FROM	LK_AGENDA A
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
				LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
		WHERE	A.FECHA >= @VFECHA_DESDE
		AND		A.FECHA <= @VFECHA_HASTA
		AND		CONVERT(VARCHAR,A.ID_CLIENTE) = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE CONVERT(VARCHAR,A.ID_CLIENTE) END
		AND		CONVERT(VARCHAR,A.ID_PROYECTO) = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE CONVERT(VARCHAR,A.ID_PROYECTO) END
		AND		CONVERT(VARCHAR,A.ID_SERVICIO) = CASE WHEN @VF_SERVICIO <> '' THEN @VF_SERVICIO ELSE CONVERT(VARCHAR,A.ID_SERVICIO) END 
		AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
		ORDER BY A.FECHA
		OFFSET @Pagina ROWS
		FETCH NEXT 10 ROWS ONLY
 
		OPEN Planifica
		FETCH NEXT FROM Planifica INTO @vindicador,	@vcliente, @vproyecto, @vobs, @vservicio, @vnormas, @vfechad, @vfechah,	@vdias,	@vhoras, @vconsultores, @vdetalle
	
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				
				SET @vobs = 
				'<div class="w3-center">'+
				'<i class="fas fa-clipboard-list w3-large" style="cursor:pointer;color:blue;" 
					title="'+ISNULL(@vobs,'')+'"></i>'
				+'</div>'
 
				SET	@OTABLA = isnull(@OTABLA,'') +
				'<tr>
					<td>'+ISNULL(@vindicador,'')+'</td>
					<td>'+ISNULL(@vcliente,'')+'</td>
					<td>'+ISNULL(@vproyecto,'')+'</td>
					<td>'+ISNULL(@vobs,'')+'</td>
					<td>'+ISNULL(@vservicio,'')+'</td>
					<td>'+ISNULL(@vnormas,'')+'</td>
					<td>'+ISNULL(@vfechad,'')+'</td>
					<td>'+ISNULL(@vfechah,'')+'</td>
					<td>'+ISNULL(@vdias,'')+'</td>
					<td>'+ISNULL(@vhoras,'')+'</td>
					<td>'+ISNULL(@vconsultores,'')+'</td>
					<td>'+ISNULL(@vdetalle,'')+'</td>
				</tr>'
 
			FETCH NEXT FROM Planifica INTO @vindicador,	@vcliente, @vproyecto, @vobs, @vservicio, @vnormas, @vfechad, @vfechah,	@vdias,	@vhoras, @vconsultores, @vdetalle
		END 
 
		CLOSE Planifica  
		DEALLOCATE Planifica	
 
		SET @OTABLA = @OTABLA + '</table>'
	--END
 
	--IF (@TIPO = 'T') BEGIN
		
		SET @OTOTAL = 0
 
		SELECT	@OTOTAL = COUNT(*)
		FROM	LK_AGENDA A
				INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
				INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
				INNER JOIN LK_PROYECTO_SERVICIO PS ON PS.ID_PROYECTO_SERVICIO = A.PROYECTO_SERV_ID
				LEFT JOIN LK_PROYECTO_DOCUM DOC ON DOC.ID_AGENDA = A.ID_AGENDA AND DOC.ID_DOCUMENTACION in (5,6,7)
		WHERE	A.FECHA >= @VFECHA_DESDE
		AND		A.FECHA <= @VFECHA_HASTA
		AND		CONVERT(VARCHAR,A.ID_CLIENTE) = CASE WHEN @VF_CLIENTE <> '' THEN @VF_CLIENTE ELSE CONVERT(VARCHAR,A.ID_CLIENTE) END
		AND		CONVERT(VARCHAR,A.ID_PROYECTO) = CASE WHEN @VF_PROYECTO <> '' THEN @VF_PROYECTO ELSE CONVERT(VARCHAR,A.ID_PROYECTO) END
		AND		CONVERT(VARCHAR,A.ID_SERVICIO) = CASE WHEN @VF_SERVICIO <> '' THEN @VF_SERVICIO ELSE CONVERT(VARCHAR,A.ID_SERVICIO) END 
		AND		P.ESTADO_PROYECTO_TOTAL <> 'TERMINADO'
 
		IF (ISNULL(@OTOTAL,'') = '') BEGIN
			SET @OTOTAL = 0
		END
 
	--END
END
