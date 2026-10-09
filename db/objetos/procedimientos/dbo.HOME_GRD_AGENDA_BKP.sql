 
CREATE PROCEDURE [dbo].[HOME_GRD_AGENDA_BKP]
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
		@VQUERY			varchar(max),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_SELEC	VARCHAR(100),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max)
 
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
 
	SET @VCLASE = 'w3-btn w3-ripple w3-circle w3-border w3-border-black'
	SET @VCLASED = 'w3-btn w3-disabled w3-ripple w3-circle w3-border w3-border-black'
	SET @VSTYLE = 'background-color: #FDFEFE;'
	SET @VROJO  = 'background-color: #E74C3C;'
	SET @VAZUL  = 'background-color: #8E44AD;'--#3498DB;'
	SET @VVERDE = 'background-color: #27AE60;'
 
	SELECT	@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,''),
			@VFECHA_SELEC = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, FECHA_SELEC, 105), 23),'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())	
 
	IF (@VFECHA_SELEC <> '') BEGIN
		
		UPDATE	Calendar
		SET		IsHoliday = 0,
				HolidayText = NULL,
				Feriado = '0'
		WHERE	CONVERT(VARCHAR,Fecha) = @VFECHA_SELEC
	END
 
	select	@vprimer_semana = min(semanames),
			@vultima_semana = max(semanames)
	from	Calendar
	where	CONVERT(VARCHAR,Mes) = @VMES
	and		CONVERT(VARCHAR,Ano) = @VANO
 
	SELECT DISTINCT @VMES_DESC=MesNombre FROM	Calendar WHERE Mes=@VMES;
 
	EXEC HOME_CMB_MESES_HTML @VMES_DESC, 'AGENDA_MES', @FORM_ID, '8C0685B0-27AD-4DD2-A881-EDDD553BA13C', @VMES_HTML OUTPUT;
 
	set @vsemana = @vprimer_semana
	
	--DELETE FROM dbo.Agenda WHERE PAR_KEY = @IPKEYJOB
	SET	@VTABLA = '<table>
	  <thead>
		<tr>
		  <th>Domingo</th>
		  <th>Lunes</th>
		  <th>Martes</th>
		  <th>Miércoles</th>
		  <th>Jueves</th>
		  <th>Viernes</th>
		  <th>Sábado</th>
		</tr>
	  </thead>'
 
	WHILE @vsemana <= @vultima_semana 
	BEGIN
 
		SET @VTABLA = @VTABLA +
			'<tr>'
 
		--INSERT INTO dbo.Agenda (PAR_KEY, Domingo, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado)
		/*SELECT  --@IPKEYJOB, 
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
															'<span style='''+case when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.DOMINGO)+'</span>'
														end
												else
 
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.DOMINGO,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																			  when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+5,len(TOTAL.DOMINGO))))
																			else 
																				@VSTYLE 
																			end +''' class='''+@VCLASE+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>' +
														--case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.DOMINGO)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" 
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.LUNES)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.LUNES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																			  when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+5,len(TOTAL.LUNES))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.LUNES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.LUNES)+'</span>'
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.MARTES)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.MARTES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																			  when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+5,len(TOTAL.MARTES))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.MARTES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MARTES)+'</span>'
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.MIERCOLES)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.MIERCOLES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																			  when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+5,len(TOTAL.MIERCOLES))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.MIERCOLES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MIERCOLES)+'</span>'
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.JUEVES)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.JUEVES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																			  when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+5,len(TOTAL.JUEVES))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.JUEVES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.JUEVES)+'</span>'
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.VIERNES)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.VIERNES,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																			  when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+5,len(TOTAL.VIERNES))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.VIERNES)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.VIERNES)+'</span>'
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
															'<span style='''+case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 1 then
																					@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 2 then
																					@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																				else 
																					@VSTYLE 
																				end +''' class='''+@VCLASED+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
														else
															'<span style='''+@VSTYLE+''' class='''+@VCLASED+'''>'+convert(varchar,TOTAL.SABADO)+'</span>'
														end
												else
													'<div class="w3-dropdown-hover" style="background-color: #FBEEE6;">'+
													case when(CHARINDEX('-',TOTAL.SABADO,1) > 0) then --'1 - FF - ANO NUEVO'
														'<span style='''+case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 1 then
																				@VROJO +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																			  when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 2 then
																				@VAZUL +''' title = ''' + ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+5,len(TOTAL.SABADO))))
																		 else 
																				@VSTYLE 
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'+
														--case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 1 THEN
															--''
														--else
															'<div class="w3-dropdown-content w3-bar-block">
																<a href="javascript:onclick=almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1))))+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');" class="w3-bar-item w3-button fas fa-trash-alt" style="color:#E74C3C; cursor:pointer;"> Eliminar</a>
															</div>'
														--end
													+'</div>'
													else
														'<span style='''+@VSTYLE+''' onclick="almacenarSeleccion(''FECHA_SELEC'','''+CONVERT(VARCHAR,TOTAL.SABADO)+'-'+@VMES+'-'+@VANO+''');goto('''+@FORM_ID+''',''2A9EC27F-DB1E-4399-B295-CC2D6009C193'');" class='''+@VCLASE+'''>'+convert(varchar,TOTAL.SABADO)+'</span>'
													end
												end
											 end+'</td>'
		FROM	(
				SELECT	MAX(MES.DOMINGO) AS DOMINGO, MAX(MES.LUNES) AS LUNES, MAX(MES.MARTES) AS MARTES, MAX(MES.MIERCOLES) AS MIERCOLES, MAX(MES.JUEVES) AS JUEVES, MAX(MES.VIERNES) AS VIERNES, MAX(MES.SABADO) AS SABADO
				FROM	(
						select	CASE WHEN (DIASEMANA = '1') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END  
								ELSE 
									'' 
								END AS DOMINGO,
								CASE WHEN (DIASEMANA = '2') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END 
								ELSE 
								'' 
								END AS LUNES,
								CASE WHEN (DIASEMANA = '3') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END  
								ELSE 
									'' 
								END AS MARTES,
								CASE WHEN (DIASEMANA = '4') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END   
								ELSE 
									'' 
								END AS MIERCOLES,
								CASE WHEN (DIASEMANA = '5') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END  
								ELSE 
									'' 
								END AS JUEVES,
								CASE WHEN (DIASEMANA = '6') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END 
								ELSE 
									'' 
								END AS VIERNES,
								CASE WHEN (DIASEMANA = '7') THEN 
									CASE WHEN (Feriado <> 0) THEN
										CONVERT(VARCHAR,DIA) + ' - '+CONVERT(VARCHAR,Feriado)+ ' - ' + HolidayText
									ELSE
										CONVERT(VARCHAR,DIA)
									END  
								ELSE 
									'' 
								END AS SABADO				
						from	Calendar
						where	CONVERT(VARCHAR,Mes) = @VMES
						and		CONVERT(VARCHAR,Ano) = @VANO
						and		SemanaMes = @vsemana) MES
				) TOTAL*/
 
			SELECT  @vlunes = TOTAL.LUNES,
					@vmartes = TOTAL.MARTES,
					@vmiercoles = TOTAL.MIERCOLES,
					@vjueves = TOTAL.JUEVES,
					@vviernes = TOTAL.VIERNES,
					@vsabado = TOTAL.SABADO,
					@vdomingo = TOTAL.DOMINGO
			FROM	(
					SELECT	MAX(MES.DOMINGO) AS DOMINGO, MAX(MES.LUNES) AS LUNES, MAX(MES.MARTES) AS MARTES, MAX(MES.MIERCOLES) AS MIERCOLES, MAX(MES.JUEVES) AS JUEVES, MAX(MES.VIERNES) AS VIERNES, MAX(MES.SABADO) AS SABADO
					FROM	(
							SELECT	CASE WHEN (DIASEMANA = '2') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END 
									ELSE 
										'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
									END AS LUNES,
									CASE WHEN (DIASEMANA = '3') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END  
									ELSE 
										'<td><span class="date"></span></td>' 
									END AS MARTES,
									CASE WHEN (DIASEMANA = '4') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END   
									ELSE 
										'<td><span class="date"></span></td>'
									END AS MIERCOLES,
									CASE WHEN (DIASEMANA = '5') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END  
									ELSE 
										'<td><span class="date"></span></td>'
									END AS JUEVES,
									CASE WHEN (DIASEMANA = '6') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END 
									ELSE 
										'<td><span class="date"></span></td>'
									END AS VIERNES,
									CASE WHEN (DIASEMANA = '7') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END  
									ELSE 
										'<td><span class="date"></span></td>' 
									END AS SABADO,
									CASE WHEN (DIASEMANA = '1') THEN 
										CASE WHEN (Feriado = 2) THEN
											'<td class="weekend"><span class="date">'+CONVERT(VARCHAR,DIA)+'<ul><li><span class="event">'+ISNULL(HolidayText,'')+'</span><span class="time">4 pm</span></li></ul></span></td>'
										ELSE
											'<td><span class="date">'+CONVERT(VARCHAR,DIA)+'</span></td>'
										END  
									ELSE 
										'<td><span class="date"></span></td>' 
									END AS DOMINGO			
							FROM	Calendar
							WHERE	CONVERT(VARCHAR,Mes) = @VMES
							AND		CONVERT(VARCHAR,Ano) = @VANO
							AND		SemanaMes = @vsemana) MES
				) TOTAL
 
		SET @VTABLA = @VTABLA + @vdomingo +	@vlunes + @vmartes + @vmiercoles + @vjueves + @vviernes + @vsabado + 
					'</tr>'
 
		set @vsemana = @vsemana + 1
	END
 
	SET @VTABLA = @VTABLA + '</table>'
	
SET @VMES_ANT = @VMES - 1
SET @VANO_ANT = @VANO - 1
SET @VMES_SIG = @VMES + 1
SET @VANO_SIG = @VANO + 1
 
SET @OHEADER = '
	<div>
	<p>
		<button onclick="goto('''+@FORM_ID+''',''522967A7-DDC9-465B-969B-85997AE1B085'');" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#D35400"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#D35400;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Agenda General</b></font>
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
	<div class="w3-cell-row w3-grey">
 
	<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '1' THEN '12'
																ELSE @VMES_ANT END+');
						 almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '1' THEN @VANO_ANT 
																ELSE @VANO END+');
						goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');""><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
 
						'<div class="w3-cell w3-cell-middle w3-center">'+@VMES_HTML+'</div>'+
 
 
 
	'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES = '12' THEN '1'
																ELSE @VMES_SIG END+');
						 almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES = '12' THEN @VANO_SIG 
																ELSE @VANO END+');
						goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>'+
	'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');">'+
			'<i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
	'<div class="w3-cell w3-cell-middle w3-center"><b>'+@VANO+'</b></div>'+
	+ '<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG+''');goto('''+@FORM_ID+''',''8C0685B0-27AD-4DD2-A881-EDDD553BA13C'');">'+
	'<i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>
	</div>
	
	<div class="w3-panel w3-topbar"></div>'
 
	set @OAGENDA = '
	<style>
	{
	  font-size: 100%;
	}
	*:before,
	*:after {
	  box-sizing: border-box;
	}
	body {
	  margin: 0.5em;
	}
	table {
	  border-collapse: collapse;
	  border-spacing: 0;
	  width: 100%;
	  height: 100%;
	  min-width: 800px;
	}
	@media (max-width: 800px) {
	  table .time {
		display: none;
	  }
	}
	tr {
	  position: relative;
	}
	th {
	  text-align: center;
	  color: black;
	  font-weight: bold;
	  font-weight: normal;
	  font-size: 1.00em;
	}
	td {
	  width: 14.285714286%;
	}
	.date {
	  text-align: right;
	  display: block;
	  height: 0;
	  font-weight: bold;
	  font-size: 1.00em;
	  padding: 0.25em;
	  padding-bottom: 73%;
	  position: relative;
	  border: 1px solid #dedbdb;
	}
	.date ul,
	.date li {
	  margin: 0;
	  padding: 0;
	  list-style: none;
	  color: #333;
	}
	.date ul {
	  text-align: left;
	  font-size: 0.8em;
	  width: 100%;
	  overflow: hidden;
	  position: absolute;
	  font-weight: normal;
	}
	.date li {
	  color: black;
	  width: 100%;
	  height: 1.6em;
	  overflow: hidden;
	  white-space: nowrap;
	  text-overflow: ellipsis;
	  position: relative;
	}
	.date li:before {
	  content: ''\2022'';
	  color: inherit;
	  display: inline-block;
	  padding-right: 0.25em;
	}
	.time {
	  float: right;
	  padding-right: 0.60em;
	  text-align: right;
	  color: #999;
	}
	.event {
	  color: #333;
	}
	.weekend {
	  background-clop: padding-box;
	  background: #fed6d7;
	}
	</style>'
	
	SET @OAGENDA = @OAGENDA + ISNULL(@VTABLA,'')
 
	UPDATE	XAGENDA
	SET		ERROR = NULL,
			FECHA_FERIADO = NULL,
			DESCRIP_FERIADO = NULL,
			FECHA_SELEC = NULL,
			AGENDA_MES = @VMES,
			AGENDA_ANO = @VANO
	WHERE	PAR_KEY = @IPKEYJOB
	
END
 
