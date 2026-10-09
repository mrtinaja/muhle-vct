CREATE PROCEDURE [dbo].[HOME_GRD_AGENDA_SERVICIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OAGENDA	AS VARCHAR(MAX) OUTPUT,
 @OHEADER	AS VARCHAR(8000) OUTPUT)
AS
 
declare	@VMES			VARCHAR(50),
		@VMES_ANT		VARCHAR(50),
		@VMES_SIG		VARCHAR(50),
		@VANO			VARCHAR(50),
		@VANO_ANT		VARCHAR(50),
		@VANO_SIG		VARCHAR(50),
		@vprimer_semana	tinyint,
		@vultima_semana	tinyint,
		@vsemana		tinyint,
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
		@VDISP			VARCHAR(100),
		@VNDISP			VARCHAR(100),
		@VLIC			VARCHAR(100),
		@VQUERY			varchar(max),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_SELEC	VARCHAR(100),
		@VCONSULTOR		VARCHAR(50),
		@VPROYECTO		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VID_CLIENTE	VARCHAR(50),
		@VCLIENTE		VARCHAR(300),
		@VCUIT			VARCHAR(50),
		@VEMAIL			VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VFECHA			VARCHAR(50),
		@VDIAS			VARCHAR(50),
		@VTIPOSERVICIO	varchar(50),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max),
		@VNOMBRE		VARCHAR(300),
		@VID			VARCHAR(100)
 
BEGIN	
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE		
 
	SET @VCLASE = 'w3-btn w3-ripple w3-circle w3-border w3-border-black'
	SET @VCLASED = 'w3-btn w3-disabled w3-ripple w3-circle w3-border w3-border-black'
	SET @VSTYLE = 'background-color: #FDFEFE;'--LIBRE
	SET @VROJO  = 'background-color: #E74C3C;'--FERIADO
	SET @VAZUL  = 'background-color: #8E44AD;'--#3498DB;'--FERIADO MANUAL
	SET @VDISP  = 'background-color: #85C1E9;'--#D4EFDF;'--CARGADO DISPONIBLE
	SET @VNDISP = 'background-color: #ABB2B9;'--#D5DBDB;'--CARGADO NO DISPONIBLE 
	SET @VLIC	= 'background-color: #FADBD8;'--LICENCIAS
	SET @VVERDE = 'background-color: #27AE60;'--ASIGNADO CONFIRMADO
	SET @VAMAR  = 'background-color: #F1C40F;'--ASIGNADO PENDIENTE
 
	SELECT	@VPROYECTO = ISNULL(PROYECTO_ID,''),
			@VSERVICIO = ISNULL(TIPO_SERVICIO,''),
			@VID = ISNULL(PROYECTO_SERV_ID,''),
			@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,'')
			--@VFECHA_SELEC = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA_SELEC, 105), 23),''),
			--@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF @VSERVICIO = '1' BEGIN 
		SELECT	@VID = ID_PROYECTO_SERVICIO,
				@VTIPOSERVICIO = ID_TIPO_SERVICIO,
				@VNOMBRE = ISNULL(NOMBRE,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO = @VPROYECTO 
		AND		ID_TIPO_SERVICIO = @VSERVICIO
	
	END ELSE BEGIN
 
		SELECT	@VTIPOSERVICIO = ID_TIPO_SERVICIO,
				@VNOMBRE = ISNULL(NOMBRE,'')
		FROM	LK_PROYECTO_SERVICIO
		WHERE	ID_PROYECTO_SERVICIO = @VID
 
	END
 
	SELECT	@VCLIENTE = CLI.RAZON_SOCIAL_CLIENTE,
			@VNORMA	  = P.NORMA_REF,
			@VID_CLIENTE = CLI.ID_CLIENTE
	FROM	LK_PROYECTO P
			INNER JOIN LK_CLIENTES CLI ON P.ID_CLIENTE = CLI.ID_CLIENTE
	WHERE	P.ID_PROYECTO = @VPROYECTO
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())	
	/*
	IF (@VFECHA_SELEC <> '') BEGIN
		
		DELETE FROM LK_AGENDA_EMPLEADO
		WHERE	CONVERT(VARCHAR,Fecha) = @VFECHA_SELEC
		AND		ID_EMPLEADO = @VCONSULTOR
 
	END
	*/
 
	SELECT DISTINCT @VMES_DESC=MesNombre FROM	Calendar WHERE Mes=@VMES;
 
	EXEC HOME_CMB_MESES_HTML @VMES_DESC, 'AGENDA_MES', @FORM_ID, '02CDA1FC-0F56-486F-BB6C-3B1299CC39A1', @VMES_HTML OUTPUT;
 
	select	@vprimer_semana = min(semanames),
			@vultima_semana = max(semanames)
	from	Calendar
	where	CONVERT(VARCHAR,Mes) = @VMES
	and		CONVERT(VARCHAR,Ano) = @VANO
 
	set @vsemana = @vprimer_semana
 
	--DELETE FROM dbo.Agenda WHERE PAR_KEY = @IPKEYJOB
	/*
	IF (@VCONSULTOR = '') BEGIN
 
		SET @VTABLA = '<table class="w3-table w3-bordered">
				<thead>
				<tr class="w3-grey">
					<th id="th01"><b>Debe Seleccionar un Consultor</b></th>
				</tr>
				</thead>'
 
	END ELSE BEGIN
	*/
	SET @VTABLA = '<table class="w3-table w3-bordered">
			<thead>
			<tr class="w3-grey">
				<th id="th01"><b>Domingo</b></th>
				<th id="th01"><b>Lunes</b></th>
				<th id="th01"><b>Martes</b></th>
				<th id="th01"><b>Miercoles</b></th>
				<th id="th01"><b>Jueves</b></th>
				<th id="th01"><b>Viernes</b></th>
				<th id="th01"><b>Sabado</b></th>
			</tr>
			</thead>'
 
	while @vsemana <= @vultima_semana 
	begin			
		
		SET @VTABLA = @VTABLA +
			'<tr>'
 
		--INSERT INTO dbo.Agenda (PAR_KEY, Domingo, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado)
		SELECT  --@IPKEYJOB, 
				@vdomingo = '<td id="td01">'+
											case when TOTAL.DOMINGO = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.DOMINGO,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.DOMINGO)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.DOMINGO,1) > 0) then
															'<span style='''+case when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'P' then 'Pendiente'	
																																		 end + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) 
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						end
																				  /*when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'P' then
																					@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'C' then
																					@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.DOMINGO)+'</span>'
														end
												else
 
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.DOMINGO,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																			  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																			  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'P' then 'Pendiente'	
																																		 end + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) 
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						end
																			  /*when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end
																			  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'P' then
																					@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end
																			  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'C' then
																					@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))) end*/
																			else 
																				@VSTYLE 
																			end +''' class='''+@VCLASE+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>' +
														case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.DOMINGO)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" 
														class='''+@VCLASE+'''>'+convert(varchar,TOTAL.DOMINGO)+'</span>'
													end
												end
											 end+'</td>', 
				@vlunes = '<td id="td01">'+case when TOTAL.LUNES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.LUNES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.LUNES)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.LUNES,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'A' then
																						--analizo el estado de la agenda--
																						case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) IN ('S','P')  THEN
																								@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'S' then 'Sin Estado'
																																			  when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'P' then 'Pendiente'	
																																		 end + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) 
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							 when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'C'  THEN
																								@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		 case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A') = '1' then
																																			'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A')
																																		 end
																														  --+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																														  --+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						end
																				  /*when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'P' then
																					@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end
																				   when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'C' then
																					@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.LUNES)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.LUNES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																			  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																			  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'A' then
																				--analizo el estado de la agenda--
																				case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) IN ('S','P')  THEN
																						@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'S' then 'Sin Estado'
																																		when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'P' then 'Pendiente'	
																																	end + ' / ' +
																																	case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A') = '1' then
																																	'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A')
																																	end
																													--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) 
																													--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))) = 'C'  THEN
																						@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																	case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A') = '1' then
																																	'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))),'A')
																																	end
																													--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																				end
																			  /*when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end
																				when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'P' then
																					@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end
																				when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'C' then
																					@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.LUNES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.LUNES)+'</span>'
													end
												end
											 end+'</td>', 
				@vmartes = '<td id="td01">'+case when TOTAL.MARTES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.MARTES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.MARTES)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.MARTES,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																				  /*when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end
																					when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end
																					when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.MARTES)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.MARTES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																			  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																			  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'A' then
																				--analizo el estado de la agenda--
																				case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) IN ('S','P')  THEN
																						@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'S' then 'Sin Estado'
																																		when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'P' then 'Pendiente'	
																																	end + ' / ' +
																																	case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A') = '1' then
																																	'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A')
																																	end
																													--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) 
																													--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																						when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))) = 'C'  THEN
																						@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																	case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A') = '1' then
																																	'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))),'A')
																																	end
																													--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))))
																													--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																				end
																			  /*when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end
																					when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end
																					when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.MARTES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MARTES)+'</span>'
													end
												end
											 end+'</td>', 
				@vmiercoles = '<td id="td01">'+case when TOTAL.MIERCOLES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.MIERCOLES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.MIERCOLES)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.MIERCOLES,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																				  /*when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end
																					when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end
																					when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.MIERCOLES)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.MIERCOLES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																			  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																			  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																			   /*when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end
																					when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end
																					when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.MIERCOLES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MIERCOLES)+'</span>'
													end
												end
											 end+'</td>', 
				@vjueves = '<td id="td01">'+case when TOTAL.JUEVES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.JUEVES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.JUEVES)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.JUEVES,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																				   /*when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end
																					when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end
																					when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.JUEVES)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.JUEVES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																			  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																			  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																			  /*when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end
																					when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end
																					when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.JUEVES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.JUEVES)+'</span>'
													end
												end
											 end+'</td>',
				@vviernes = '<td id="td01">'+case when TOTAL.VIERNES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.VIERNES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.VIERNES)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.VIERNES,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																				  /*when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end
																					when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end
																					when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.VIERNES)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.VIERNES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																			  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																			  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																			  /*when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end
																					when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end
																					when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.VIERNES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.VIERNES)+'</span>'
													end
												end
											 end+'</td>',
				@vsabado = '<td id="td01">'+case when TOTAL.SABADO = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.SABADO,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1))))+'-'+@VMES+'-'+@VANO, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.SABADO)+'-'+@VMES+'-'+@VANO, 105), 23)
													end < CONVERT(VARCHAR(10), CONVERT(date, getdate(), 105), 23) then
														case when (CHARINDEX('-',TOTAL.SABADO,1) > 0) then
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '1' then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '2' then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																				 /*when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end
																					when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end
																					when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end*/
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.SABADO)+'</span>'
														end
												else
													--'<div class="w3-dropdown-hover" style="background-color: #EAF2F8;">'+
													case when(CHARINDEX('-',TOTAL.SABADO,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '1' then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																			  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = '2' then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																			  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'A' then
																					--analizo el estado de la agenda--
																					case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) IN ('S','P')  THEN
																							@VAMAR +''' title = ''' + 'Agendado - '+ case when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'S' then 'Sin Estado'
																																			when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'P' then 'Pendiente'	
																																		end + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A')
																																		end
																														--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) 
																														--+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																							when dbo.FN_GET_AGENDA_ESTADO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))) = 'C'  THEN
																							@VVERDE +''' title = ''' + 'Agendado - '+ 'Confirmado' + ' / ' +
																																		case when dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A') = '1' then
																																		'Sin Consultor' else dbo.FN_GET_AGENDA_CONSULTOR(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))),'A')
																																		end
																														+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))))
																														--+ ' / ' + dbo.FN_GET_AGENDA_SERVICIO(ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO)))))
																					end
																			  /*when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'S' then
																					@VAMAR +''' title = ''' + 'Sin Estado - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																																	'Sin Consultor' 
																																 else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end
																					when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'P' then
																						@VAMAR +''' title = ''' + 'Pendiente - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end
																					when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'C' then
																						@VVERDE +''' title = ''' + 'Confirmado - ' + case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,2))) = '1' THEN 
																															'Sin Consultor' 
																															else ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO)))) end*/
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'+
														case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) in ('1','2'/*,'S','P','C'*/) THEN
															''
														else
															''
														end
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.SABADO)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''766BD3F2-F310-43E7-9CAF-15168C0E01FB'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.SABADO)+'</span>'
													end
												end
											 end+'</td>'
		FROM	(
				SELECT	MAX(MES.DOMINGO) AS DOMINGO, MAX(MES.LUNES) AS LUNES, MAX(MES.MARTES) AS MARTES, MAX(MES.MIERCOLES) AS MIERCOLES, MAX(MES.JUEVES) AS JUEVES, MAX(MES.VIERNES) AS VIERNES, MAX(MES.SABADO) AS SABADO
				FROM	(
						select	CASE WHEN (DIASEMANA = '1') THEN 
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS DOMINGO,
								CASE WHEN (DIASEMANA = '2') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
								'' 
								END AS LUNES,
								CASE WHEN (DIASEMANA = '3') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS MARTES,
								CASE WHEN (DIASEMANA = '4') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS MIERCOLES,
								CASE WHEN (DIASEMANA = '5') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS JUEVES,
								CASE WHEN (DIASEMANA = '6') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS VIERNES,
								CASE WHEN (DIASEMANA = '7') THEN
									CASE WHEN (ISNULL(A.FECHA,'') <> '') THEN
										CONVERT(VARCHAR,A.DIA) + ' - '+ 'A' + ' - ' + CONVERT(VARCHAR,A.HOLIDAYTEXT)
									ELSE
										CASE WHEN (C.Feriado <> 0) THEN
											CONVERT(VARCHAR,C.DIA) + ' - '+CONVERT(VARCHAR,C.Feriado)+ ' - ' + C.HolidayText
										ELSE
											CONVERT(VARCHAR,C.DIA)
										END  
									END
								ELSE 
									'' 
								END AS SABADO
						from	Calendar C
								--LEFT JOIN LK_AGENDA AG ON AG.FECHA = C.Fecha and ID_CLIENTE = 60 and ID_PROYECTO = 15 and ID_SERVICIO = 2 AND PROYECTO_SERV_ID = 29
								LEFT JOIN LK_AGENDA_EMPLEADO A ON C.FECHA = A.FECHA AND	A.HOLIDAYTEXT in (SELECT CONVERT(VARCHAR,ID_AGENDA) FROM LK_AGENDA WHERE ID_CLIENTE = @VID_CLIENTE and ID_PROYECTO = @VPROYECTO and ID_SERVICIO = @VTIPOSERVICIO AND PROYECTO_SERV_ID = @VID)
						where	CONVERT(VARCHAR,C.Mes) = @VMES
						and		CONVERT(VARCHAR,C.Ano) = @VANO
						and		SemanaMes = @vsemana) MES
				) TOTAL
		
 
		SET @VTABLA = @VTABLA + @vdomingo +	@vlunes + @vmartes + @vmiercoles + @vjueves + @vviernes + @vsabado + 
						'</tr>'
 
		set @vsemana = @vsemana + 1
 
	end
	--END
 
	SET @VTABLA = @VTABLA + '</table>'
 
	SET @OAGENDA = '
<html>
<head>
<style>
 
th#th01 {
  text-align: center;
}
 
td#td01 {
  text-align: center;
  height: 50px;
  width: 80px;
  border-style: ridge;
  background-color:#EAF2F8;
}
 
</style>
<div class="w3-container">
 
' + @VTABLA + '
  
</div><br><br>'
 
SET @VMES_ANT = @VMES - 1
SET @VANO_ANT = @VANO - 1
SET @VMES_SIG = @VMES + 1
SET @VANO_SIG = @VANO + 1
 
SET @OHEADER = '
	<html>
 
	<body>
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''74BBD80D-05CB-41DB-A981-5B6E3EE63A74'');return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#2980B9;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Agregar Visita</b></font>
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
 
		<ul class="progress-indicator">
            <li class="completed">
                <span class="bubble"></span>
                <i class="fas fa-calendar-day w3-large"></i><br>
                1. SELECCIONAR FECHA DESDE
            </li>
            <li class="">
                <span class="bubble"></span>
                <i class="fas fa-users w3-large"></i><br>
                2. SELECCIONAR CONSULTORES
            </li>
            <li>
                <span class="bubble"></span>
                <i class="fas fa-check-circle w3-large"></i><br>
                3. FINALIZAR
            </li>
        </ul>
 
	<div class="w3-container">
		<table class="w3-table-all">
		<thead>
			<tr class="w3-light-grey">
			<th><b>Cliente</b></th>
			<th><b>Proyecto</b></th>
			<th><b>Servicio</b></th>
			<th><b>Nombre</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VNORMA+'</td>'+
			  '<td>'+ CASE WHEN @VTIPOSERVICIO = '1' THEN	'Consultoria&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '2' THEN	'Auditoria&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '3' THEN	'Capacitacion' END+'</td>'+
			'<td>'+ISNULL(@VNOMBRE,'')+'</td>
			</tr>
	</table>
	</div>
 
	<div class="w3-panel w3-topbar"></div>
 
	<h4><b>Seleccionar Fecha Desde:</b></h4>
 
	<div class="w3-cell-row w3-grey">
			<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '1' THEN '12'
																	ELSE @VMES_ANT END+');
								almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '1' THEN @VANO_ANT 
																	ELSE @VANO END+');
							goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');""><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
							'<div class="w3-cell w3-cell-middle w3-center">'+@VMES_HTML+'</div>'+
							'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '12' THEN '1'
																	ELSE @VMES_SIG END+');
								almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '12' THEN @VANO_SIG 
																	ELSE @VANO END+');
							goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>'+
			'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT+''');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');"">'+
				'<i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
			'<div class="w3-cell w3-cell-middle w3-center"><b>'+@VANO+'</b></div>'+
			+ '<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG+''');goto('''+@FORM_ID+''',''02CDA1FC-0F56-486F-BB6C-3B1299CC39A1'');">'+
			'<i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>'+
	'</div><br>'
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			FECHA_SELEC = NULL,
			AGENDA_FECHA = NULL,
			AGENDA_DESDE = NULL,
			AGENDA_HASTA = NULL,
			AGENDA_CONSULTOR = NULL,
			AGENDA_ESTADO = NULL,
			AGENDA_NORMA = NULL,
			VALIDA_AGENDA = NULL,
			AGENDA_OBSERVADOR = NULL,
			AGENDA_MES = @VMES,
			AGENDA_ANO = @VANO,
			BUFFER = NULL,
			AGENDA_CONSULTORES = NULL
	WHERE	PAR_KEY = @IPKEYJOB
	
END
