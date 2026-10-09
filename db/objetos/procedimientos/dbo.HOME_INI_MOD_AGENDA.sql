 
CREATE PROCEDURE [dbo].[HOME_INI_MOD_AGENDA]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(MAX) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @ODISPONIBLE AS VARCHAR(MAX) OUTPUT)
AS
 
DECLARE		@VNORMAS_PROY	VARCHAR(400),
			@VNORMAS		VARCHAR(400),
			@VNORMASIN		VARCHAR(400),
			@VCONSULTORES	VARCHAR(MAX),
			@lstDato		varchar(100), 
			@lnuPosComa		int ,
			@VALOR			VARCHAR(400),
			@VCANT			INT,
			@VID_CONSULTOR	VARCHAR(50),
			@VAPENOM		VARCHAR(400),
			@VCALIF			VARCHAR(100),
			@vdomingo		varchar(4000),
			@vlunes			varchar(4000),
			@vmartes		varchar(4000),
			@vmiercoles		varchar(4000),
			@vjueves		varchar(4000),
			@vviernes		varchar(4000),
			@vsabado		varchar(4000),
			@VTABLA			VARCHAR(max),
			@VCLASE			VARCHAR(1000),
			@VCLASED		VARCHAR(1000),
			@VSTYLE			VARCHAR(1000),
			@VROJO			VARCHAR(100),
			@VAZUL			VARCHAR(100),
			@VVERDE			VARCHAR(100),
			@VAMAR			VARCHAR(100),
			@VNARANJA		VARCHAR(100),
			@VDISP			VARCHAR(100),
			@VNDISP			VARCHAR(100),
			@VNDISP2		VARCHAR(100),
			@VLIC			VARCHAR(100),
			@UNITDESC		VARCHAR(300),
			@USERDESC		VARCHAR(300),
			@VPROYECTO		VARCHAR(50),
			@VSERVICIO		VARCHAR(50),
			@VID_CLIENTE	VARCHAR(50),
			@VCLIENTE		VARCHAR(300),
			@VCUIT			VARCHAR(50),
			@VEMAIL			VARCHAR(100),
			@VNORMA			VARCHAR(300),
			@VFECHA_AGENDA	VARCHAR(50),
			@VTIPOSERVICIO	VARCHAR(50),
			@VFECHA_SELEC	VARCHAR(100),
			@VQUERY			NVARCHAR(MAX),
			@SQLString		NVARCHAR(MAX),
			@objcursorConsultores as cursor,
			@VFECHAD		VARCHAR(50),
			@VFECHAH		VARCHAR(50),
			@vsemana		int,
			@vmes			int,
			@vano			int,
			@VCHECK			VARCHAR(400),
			@vbuffer		varchar(400),
			@VID_AGENDA		VARCHAR(50),
			@VDIAS			VARCHAR(50),
			@VFECHADESDE	VARCHAR(50),
			@VFECHAHASTA	VARCHAR(50),
			@VESTADO		VARCHAR(100),
			@VARNORMA		VARCHAR(400),
			@VCONSULTOR		VARCHAR(max),
			@VDESCNORMAS	VARCHAR(4000),
			@VPREVIOS		VARCHAR(400),
			@VEST_AGENDA	VARCHAR(50),
			@VOBSERVADOR	VARCHAR(300),
			@VOBS_LOGISTICA VARCHAR(400),
			@VOBS_CALIF		VARCHAR(400),
			@VHORAS			INT,
			@VLIDER			VARCHAR(400),
			@VHORA_AGENDA	VARCHAR(50),
			@VNOMBRE		VARCHAR(300),
			@VNORMA_SERV	VARCHAR(400),
			@VEVENTUAL		VARCHAR(50),
			@var_mes		VARCHAR(50),
			@var_ano		VARCHAR(50)
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
 
	SET @VCLASE = 'w3-btn w3-tiny w3-circle w3-border w3-border-black'
	SET @VCLASED = 'w3-btn w3-disabled w3-tiny w3-circle w3-border w3-border-black'
	SET @VSTYLE = 'background-color: #FDFEFE;'--LIBRE
	SET @VROJO  = 'background-color: #E74C3C;'--FERIADO
	SET @VAZUL  = 'background-color: #8E44AD;'--#3498DB;'--FERIADO MANUAL
	SET @VDISP  = 'background-color: #85C1E9;'--#D4EFDF;'--CARGADO DISPONIBLE
	SET @VNDISP = 'background-color: #ABB2B9;'--#D5DBDB;'--CARGADO NO DISPONIBLE, OTRO PROYECTO 
	SET @VNDISP2= 'background-color: #FDFEFE;'--#D5DBDB;'--NO CARGADO
	SET @VLIC	= 'background-color: #FADBD8;'--LICENCIAS
	SET @VVERDE = 'background-color: #27AE60;'--ASIGNADO CONFIRMADO
	SET @VAMAR  = 'background-color: #F1C40F;'--ASIGNADO PENDIENTE
	SET @VNARANJA = 'background-color: orange;'
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			--@VSERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			--@VMES = ISNULL(AGENDA_MES,''),
			--@VANO = ISNULL(AGENDA_ANO,''),
			--@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			--@VFECHA_SELEC = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_DESDE, 105), 23),''),
			--@VFECHAD = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_DESDE, 105), 23),CONVERT(VARCHAR(10), CONVERT(date, FECHA_SELEC, 105), 23)),
			--@VFECHAH = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_HASTA, 105), 23),''),
			@vbuffer = isnull(AGENDA_CONSULTORES,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
	
	SELECT	--@VFECHA_SELEC = CASE WHEN @VFECHA_SELEC = '' THEN ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA, 105), 23),'') ELSE @VFECHA_SELEC END,
			@VFECHAD = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA, 105), 23),''),
			@VFECHAH = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA_HASTA, 105), 23),''),
			@VPREVIOS = isnull(ID_CONSULTOR,''),
			@VTIPOSERVICIO = ISNULL(ID_SERVICIO,''),
			@VEST_AGENDA = ISNULL(ESTADO,''),
			@VOBSERVADOR = ISNULL(OBSERVADOR,''),
			@VOBS_LOGISTICA = ISNULL(OBSERV_LOGISTICA,''),
			@VOBS_CALIF = ISNULL(OBSERV_CALIF,''),
			@VLIDER = ISNULL(LIDER,''),
			@VNORMA_SERV = ISNULL(NORMA,''),
			@VSERVICIO = ISNULL(PROYECTO_SERV_ID,'')
	FROM	LK_AGENDA
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VSERVICIO
 
	SELECT	TOP 1 @VHORAS = HORAS
	FROM	LK_AGENDA_EMPLEADO
	WHERE	HOLIDAYTEXT = @VID_AGENDA
 
	IF (@vbuffer = '') BEGIN
		SET @vbuffer = @VPREVIOS
	END
 
	IF (@VFECHAH = '') BEGIN
		SET @VFECHAH = CONVERT(VARCHAR(10), CONVERT(date, DATEADD(DD,7,@VFECHAD), 105), 23)
	END
 
	/*IF (@VFECHA_SELEC = '') BEGIN
		UPDATE	XAGENDA
		SET		AGENDA_DESDE = @VFECHAD
		WHERE	PAR_KEY = @IPKEYJOB
	END*/
 
	SELECT	@vsemana = SemanaMes, @vmes = Mes, @vano = Ano--CONVERT(varchar, DATEPART(YYYY, @VFECHA_SELEC))
	FROM	Calendar
	WHERE	Fecha = @VFECHAD--CASE WHEN @VFECHA_SELEC = '' THEN @VFECHAD ELSE @VFECHA_SELEC END
	
	SET @var_mes = CONVERT(VARCHAR(50),@vmes)
	SET @var_ano = CONVERT(VARCHAR(50),@vano)
 
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VNORMA  = '('+P.CODIGO+') - '+P.NORMA_REF,
			--@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VFECHADESDE = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAHASTA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(P.NORMAS,''),
			@VCONSULTOR = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END
			--@VID_SERVICIO = ID_SERVICIO
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VNORMASIN = substring(''''+REPLACE(@VARNORMA,'|',''','''),1,len(''''+REPLACE(@VARNORMA,'|',''','''))-2)
 
	SET @VNORMAS = @VARNORMA
 
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
 
	SET @VARNORMA = @VNORMAS
 
	SET @VCONSULTORES = '
	<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
				<th id = "th04"><b>Opc.</b></th>
				<th id = "th03"><b>Consultor</b></th>'
	  
	  WHILE LEN(@VNORMAS) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VNORMAS
				SET @VNORMAS = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
 
				SELECT	@VALOR = DESC_APTITUD
				FROM	LK_APTITUDES
				WHERE	ID_APTITUD = @lstDato
 
				--SET @VDESCNORMAS = ISNULL(@VDESCNORMAS,'') + @VALOR 
 
				SET @VCONSULTORES = @VCONSULTORES + 
				'<th id = "th04"><b>'+@VALOR+'</b></th>'
 
				SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
			END
		END
	  
	SET @VCONSULTORES = @VCONSULTORES +
	  '<th id = "th03"><b>Disponibilidad</b></th>
	   <th id = "th03"><b>Detalles</b></th>
    </tr>
	</thead>'
 
	--'+CONVERT(VARCHAR,ID_APTITUD)+'"'+CASE WHEN ([dbo].[FN_GET_NORMA2](@VNORMAS,ID_APTITUD) = 'true') THEN 'checked="true"' ELSE '' END +
	--''<input type="checkbox" id="''+CONVERT(VARCHAR,APT.ID_APTITUD)+''" onchange="toggleCheckbox(this);">'',
	SELECT @VQUERY = 
		'SELECT	DISTINCT ''<input type="checkbox" id="''+CONVERT(VARCHAR,EMP.ID_EMPLEADO)+''"''+CASE WHEN ([dbo].[FN_GET_NORMA]('''+@vbuffer+''',EMP.ID_EMPLEADO) = ''SI'') THEN '' checked="true"'' ELSE '''' END +'' onchange="toggleCheckbox(this);">'',  EMP.ID_EMPLEADO, EMP.APELLIDO_EMPLEADO + '', '' + EMP.NOMBRE_EMPLEADO, isnull(EVENTUAL,''NO'')
		   FROM	LK_EMPLEADOS EMP    
				INNER JOIN LK_EMPLEADOS_APTITUD APT ON EMP.ID_EMPLEADO = APT.ID_EMPLEADO AND APT.ID_TIPO = '+@VTIPOSERVICIO+' AND APT.ID_APTITUD IN ('+@VNORMASIN+')  
		  WHERE	PERFIL_EMP = ''CONSULTOR'' 
		  ORDER BY 3'
 
		/*'SELECT	DISTINCT ''<input type="checkbox" id="''+CONVERT(VARCHAR,EMP.ID_EMPLEADO)+''" onchange="toggleCheckbox(this);">'',  EMP.ID_EMPLEADO, EMP.APELLIDO_EMPLEADO + '', '' + EMP.NOMBRE_EMPLEADO
		   FROM	LK_EMPLEADOS EMP    
				INNER JOIN LK_EMPLEADOS_APTITUD APT ON EMP.ID_EMPLEADO = APT.ID_EMPLEADO AND APT.ID_TIPO = '+@VTIPOSERVICIO+' AND APT.ID_APTITUD IN ('+@VNORMASIN+')  
		  WHERE	PERFIL_EMP = ''CONSULTOR'' '*/
 
	SELECT @SQLString = 'set @cursor = cursor forward_only static for ' + @vquery + ' open @cursor;'
 
	exec sys.sp_executesql
    @SQLString
    ,N'@cursor cursor output'
    ,@objcursorConsultores output
 
	/*DECLARE Consultores CURSOR FOR
		SELECT	DISTINCT EMP.ID_EMPLEADO, EMP.APELLIDO_EMPLEADO +', '+ EMP.NOMBRE_EMPLEADO
		FROM	LK_EMPLEADOS EMP    
				INNER JOIN LK_EMPLEADOS_APTITUD APT ON EMP.ID_EMPLEADO = APT.ID_EMPLEADO AND APT.ID_TIPO = @VTIPOSERVICIO AND APT.ID_APTITUD IN ([dbo].[FN_GET_NORMAS](@VNORMAS_PROY))  
		WHERE	PERFIL_EMP = 'CONSULTOR'*/
			
			--OPEN @objcursorConsultores  
			FETCH NEXT FROM @objcursorConsultores INTO @VCHECK, @VID_CONSULTOR, @VAPENOM, @VEVENTUAL
 
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				--BUSCO LA CALIFICACION POR CADA NORMA DEL PROYECTO
				SET @VCONSULTORES = @VCONSULTORES +
						'<td id = "td06">'+isnull(@VCHECK,'')+'</td>'+ 
						'<td id = "td05">'+'<div><font color="'  + case when @VEVENTUAL = 'SI' then 'blue' else 'black' end + '">' + @VAPENOM + '</font></div>' +'</td>'
 
				SET @VNORMAS = @VARNORMA
					
				WHILE LEN(@VNORMAS) > 0
				BEGIN 
					SET @lnuPosComa = CHARINDEX('|', @VNORMAS) -- Busca el caracter a separador
					IF (@lnuPosComa = 0) BEGIN 
						SET @lstDato = @VNORMAS
						SET @VNORMAS = '' 
					END ELSE BEGIN
						SET @lstDato = SUBSTRING(@VNORMAS, 1, @lnuPosComa - 1)
 
						SELECT	@VCALIF = [dbo].[FN_GET_CALIFICACION] (@VID_CONSULTOR,@lstDato,@VTIPOSERVICIO)
						
						SET @VCONSULTORES = @VCONSULTORES + 
						'<td id = "td06">'+@VCALIF+'</td>'
 
						SET @VNORMAS = SUBSTRING(@VNORMAS, @lnuPosComa + 1, LEN(@VNORMAS))
					END
				END	
				
				SELECT  @vdomingo	= '<span style='''+case when TOTAL.DOMINGO = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				   when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
															end
														end,
						@vlunes		= '<span style='''+case when TOTAL.LUNES = '' then 
														'''>' + '</span>' 
													   else
															case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				   when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
															end
														end,
						@vmartes	= '<span style='''+case when TOTAL.MARTES = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				   when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
															end
														end,
						@vmiercoles = '<span style='''+case when TOTAL.MIERCOLES = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				   when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
															end
														end,
						@vjueves	= '<span style='''+case when TOTAL.JUEVES = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				   when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
															end
														end,
						@vviernes	= '<span style='''+case when TOTAL.VIERNES = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				   when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
															end
														end,
						@vsabado	= '<span style='''+case when TOTAL.SABADO = '' then 
														'''>' + '</span>' 
													   else
														case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'OP' then
																					@VNDISP +''' title = ''' + 'Otro Proyecto' 
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'ND' then
																					@VNDISP +''' title = ''' + 'No Disponible'
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'D' then
																					@VDISP +''' title = ''' + 'Disponible'
																				  when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,4))) = 'LIC' then
																					@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																				  when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,4))) = 'POT' then
																					@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @VID_CONSULTOR) + ''
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'NA' then
																					@VNDISP2 +''' title = ''' + 'No Cargado'
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				   when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'P' then 'Pendiente'	
																																		 end +
																														  /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																																	 end */	
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) 
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' +
																														 /*+ ' / ' +  case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																																	 end*/
																														  + ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														  + ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																						end
																				else 
																					@VSTYLE +''' '
																				end +''' class='''+@VCLASE+ ''' '+
															case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) in ('1','2','A'/*,'S','P','C'*/) THEN
																	'>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
																 when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) in ('ND','NA','OP') THEN
																	'>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
																 when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,4))) = 'LIC' then
																	'>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
															else
																'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
															end
														end
				FROM	(
				--ARMO CURSOR PARA RECORRER DE FECHA DESDE A FECHA HASTA Y MOSTRAR DISPONIBILIDAD POR CONSULTOR--
				SELECT	MAX(MES.DOMINGO) AS DOMINGO, MAX(MES.LUNES) AS LUNES, MAX(MES.MARTES) AS MARTES, MAX(MES.MIERCOLES) AS MIERCOLES, MAX(MES.JUEVES) AS JUEVES, MAX(MES.VIERNES) AS VIERNES, MAX(MES.SABADO) AS SABADO
					FROM	(
							select	CASE WHEN (DIASEMANA = '1') THEN 
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS DOMINGO,
									CASE WHEN (DIASEMANA = '2') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
									'' 
									END AS LUNES,
									CASE WHEN (DIASEMANA = '3') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS MARTES,
									CASE WHEN (DIASEMANA = '4') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS MIERCOLES,
									CASE WHEN (DIASEMANA = '5') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS JUEVES,
									CASE WHEN (DIASEMANA = '6') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS VIERNES,
									CASE WHEN (DIASEMANA = '7') THEN
										--TENGO FECHA CONSULTOR
										CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
												CONVERT(VARCHAR,A.DIA) + ' - '+CONVERT(VARCHAR,A.TIPO)+ ' - ' + A.HOLIDAYTEXT
										ELSE
											CASE WHEN (C.Feriado <> 0) THEN
												CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
											ELSE
												CONVERT(VARCHAR,C.DIA) + ' - NA'
											END  
										END
									ELSE 
										'' 
									END AS SABADO				
							from	Calendar C
									LEFT JOIN LK_AGENDA_EMPLEADO A ON A.FECHA = C.Fecha and a.ID_EMPLEADO = @VID_CONSULTOR
									--LEFT JOIN LK_AGENDA AG ON AG.FECHA = C.Fecha and AG.ID_CLIENTE = @VID_CLIENTE and AG.ID_PROYECTO = @VPROYECTO and AG.ID_SERVICIO = @VTIPOSERVICIO
									--LEFT JOIN LK_EMPLEADOS EMP ON AG.ID_CONSULTOR = EMP.ID_EMPLEADO
							where	CONVERT(VARCHAR,C.Mes) = @vmes
							and		CONVERT(VARCHAR,C.Ano) = @vano
							and		SemanaMes = @vsemana) MES
							--and		c.Fecha >= @VFECHAD
							--and		c.Fecha <= @VFECHAH) MES
							) TOTAL
		
				SET @VCONSULTORES = @VCONSULTORES + '<td id = "td05">'+@vdomingo+'&nbsp;&nbsp;' +@vlunes+'&nbsp;&nbsp;'+@vmartes+'&nbsp;&nbsp;'+@vmiercoles+'&nbsp;&nbsp;'+@vjueves+'&nbsp;&nbsp;'+@vviernes+'&nbsp;&nbsp;'+@vsabado+'</td>'
					--+ '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
				SET @VCONSULTORES = @VCONSULTORES +
				'<td id = "td05">' +
					  '<i class="far fa-calendar-alt w3-large" style="cursor:pointer;" title="Ver Agenda" onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''+@VID_CONSULTOR+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5'');"></i>' + '&nbsp;' +
					  '<i class="far fa-calendar-plus w3-large" style="cursor:pointer;" title="Ir Agenda" onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''+@VID_CONSULTOR+''');almacenarSeleccion(''PREVIUS'','''+'MOD'+''');goto('''+@FORM_ID+''',''59AA3C13-A4EB-4DD9-AC84-50A1C3F2745B'');"></i>
				</td>'+
				'</tr>'+
				'<tr><td colspan="7"><div id="content'+@VID_CONSULTOR+'" class="w3-hide w3-container"></div></td></tr>'
	
 
				FETCH NEXT FROM @objcursorConsultores INTO @VCHECK, @VID_CONSULTOR, @VAPENOM, @VEVENTUAL
			END 
 
			CLOSE @objcursorConsultores  
			DEALLOCATE @objcursorConsultores
 
			
 
	SET @VCONSULTORES = isnull(@VCONSULTORES,'') + '</table>'
 
	SET @ODISPONIBLE = '
<html>
<head>
<style>
 
table {
  border-collapse: collapse;
  width: 100%;
}
 
th, td {
  padding: 8px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}
 
tr:hover {background-color:#f5f5f5;}
 
th#th03 {
  text-align: left;
}
 
th#th04 {
  text-align: center;
}
 
td#td05 {
  text-align: left;
}
 
td#td06 {
  text-align: center;
}
 
</style>
</head>
<body>
 
<div class="w3-container">
 
' + @VCONSULTORES + '
  
</div>
 
<div>
	<p>
		<button onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
		<button onclick="saveValues(''BUFFER'');next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Siguiente</b></font></button>
	</p>
</div>
 
</body>
</html>
'
 
SET @OHEADER = '
	<div>
	<p>
		<button onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''');goto('''+@FORM_ID+''',''413A3F03-AD67-44E3-8907-C81085611C20''); return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
		<button onclick="saveValues(''BUFFER'');next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Siguiente</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#2980B9;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:20px;color:#FFFFFF;text-align: left"><b>Modifica Visita</b></font>
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
			<th><b>Dias</b></th>
			<th><b>Fecha Desde</b></th>
			<th><b>Fecha Hasta</b></th>
			<th><b>Estado</b></th>
			<th><b>Profesional</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VNORMA+'</td>' +
			  '<td>'+ CASE WHEN @VTIPOSERVICIO = '1' THEN	'Consultoria&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '2' THEN	'Auditoria&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '3' THEN	'Capacitacion' END	 +'</td>' +
			  '<td>'+ISNULL(@VNOMBRE,'')+'</td>' +
			  '<td>'+@VDIAS+'</td>' +
			  '<td>'+@VFECHADESDE+'</td>' +
			  '<td>'+@VFECHAHASTA+'</td>' +
			  '<td>'+@VESTADO+'</td>' +
			  '<td>'+@VCONSULTOR+'</td> 
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-bar w3-grey w3-center">'+
		+'<div class="w3-bar-item w3-grey"><b>Desde:</b></div><input type="date" class="w3-bar-item w3-grey" name="SP.AGENDA_DESDE" value="'+@VFECHAD+'">'+
		+'<a class="w3-bar-item w3-button w3-grey w3-right" href="javascript:almacenarSeleccion(''AGENDA_CONSULTOR'','''+''+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5'');">Buscar&nbsp;<i class="fa fa-search"></i></a>
	</div><br>'
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div>
	<p>
		<button onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
		<button onclick="saveValues(''BUFFER'');next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Siguiente</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	UPDATE	XAGENDA
	SET		AGENDA_CONSULTORES = @vbuffer,
			AGENDA_ESTADO = @VEST_AGENDA,
			AGENDA_OBSERVADOR = @VOBSERVADOR,
			AGENDA_OBSERV_LOGIS = @VOBS_LOGISTICA,
			AGENDA_OBSERV_CALIF = @VOBS_CALIF,
			AGENDA_HORAS = @VHORAS,
			AGENDA_HASTA = @VFECHAH,
			AGENDA_DESDE = @VFECHAD,
			LIDER = @VLIDER,
			ACUMULA = NULL,
			AGENDA_NORMA = @VNORMA_SERV,
			AGENDA_NORMAS = NULL
	WHERE	PAR_KEY = @IPKEYJOB	
 
END
