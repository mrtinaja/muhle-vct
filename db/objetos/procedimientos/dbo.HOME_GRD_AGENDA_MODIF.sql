 
CREATE PROCEDURE [dbo].[HOME_GRD_AGENDA_MODIF]
(@IPKEYJOB	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @FORM_ID	AS VARCHAR(100),
 @OHEADER	AS VARCHAR(8000) OUTPUT,
 @OFOOTER	AS VARCHAR(4000) OUTPUT,
 @OAGENDA_PROY AS VARCHAR(MAX) OUTPUT,
 @OALERTA	AS VARCHAR(400) OUTPUT)
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
		@VTABLA2		VARCHAR(MAX),
		@VCLASE			VARCHAR(1000),
		@VCLASED		VARCHAR(1000),
		@VSTYLE			VARCHAR(1000),
		@VROJO			VARCHAR(100),
		@VAZUL			VARCHAR(100),
		@VVERDE			VARCHAR(100),
		@VAMAR			VARCHAR(100),
		@VDISP			VARCHAR(100),
		@VNDISP			VARCHAR(100),
		@VNDISP2		VARCHAR(100),
		@VSELEC			VARCHAR(100),
		@VLIC			VARCHAR(100),
		@VQUERY			varchar(max),
		@UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_SELEC	VARCHAR(100),
		--@VCONSULTOR		VARCHAR(50),
		@VDESCCONSULTOR	VARCHAR(400),
		@VPROYECTO		VARCHAR(50),
		@VSERVICIO		VARCHAR(50),
		@VID_CLIENTE	VARCHAR(50),
		@VCLIENTE		VARCHAR(300),
		@VCUIT			VARCHAR(50),
		@VEMAIL			VARCHAR(100),
		@VNORMA			VARCHAR(300),
		@VFECHA_AGENDA	VARCHAR(50),
		@VTIPOSERVICIO	VARCHAR(50),
		@VFECHAD		VARCHAR(50),
		@VFECHAH		VARCHAR(50),
		@VSELECCION		VARCHAR(4000),
		@VCONSULTORES	VARCHAR(4000),
		@lstDato		varchar(100),
		@lstNorma		varchar(100),
		@lnuPosComa		int ,
		@lnuPosComa2	int,
		@VALOR			VARCHAR(400),
		@VTORF			VARCHAR(50),
		@VDESCCONS		VARCHAR(4000),
		--NUEVA AGENDA--
		@VMES_PROY			VARCHAR(50),
		@VMES_ANT_PROY		VARCHAR(50),
		@VMES_SIG_PROY		VARCHAR(50),
		@VANO_PROY			VARCHAR(50),
		@VANO_ANT_PROY		VARCHAR(50),
		@VANO_SIG_PROY		VARCHAR(50),
		@vprimer_semana_PROY	tinyint,
		@vultima_semana_PROY	tinyint,
		@vsemana_PROY		tinyint,
		@vdomingo_PROY		varchar(4000),
		@vlunes_PROY		varchar(4000),
		@vmartes_PROY		varchar(4000),
		@vmiercoles_PROY	varchar(4000),
		@vjueves_PROY		varchar(4000),
		@vviernes_PROY		varchar(4000),
		@vsabado_PROY		varchar(4000),
		@VEXISTE			VARCHAR(50),
		@VPREVIAS			VARCHAR(400),
		@VNUEVAS			VARCHAR(400),
		@RESULTADO			INT,
		@VALOR2				VARCHAR(400),
		@VAGREGO			VARCHAR(50),
		@VSELECCION2		VARCHAR(4000),
		@VID_AGENDA			VARCHAR(50),
		@VDIAS			VARCHAR(50),
		@VFECHADESDE	VARCHAR(50),
		@VFECHAHASTA	VARCHAR(50),
		@VESTADO		VARCHAR(100),
		@VARNORMA		VARCHAR(400),
		@VCONSULTOR		VARCHAR(4000),
		@VDESCNORMAS	VARCHAR(4000),
		@VNORMAS_PROY		VARCHAR(400),
		@VCALIF				VARCHAR(100),
		@VALERT_CALIF		VARCHAR(50),
		@VALIDA_AGENDA		VARCHAR(50),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max),
		@VNOMBRE		VARCHAR(300)
 
BEGIN
 
	SELECT	@UNITDESC = [Name]
	FROM	Groups
	WHERE	[Id] = @IUNIDAD;
 
	SELECT	@USERDESC = [Name]
	from Users
	where Id=@IAGENTE
 
	SET @VCLASE = 'w3-btn w3-ripple w3-circle w3-border w3-border-black'
	SET @VCLASED = 'w3-btn w3-disabled w3-ripple w3-circle w3-border w3-border-black'
	SET @VSTYLE = 'cursor: not-allowed;background-color: #FDFEFE;'--LIBRE
	SET @VROJO  = 'cursor: not-allowed;background-color: #E74C3C;'--FERIADO
	SET @VAZUL  = 'cursor: not-allowed;background-color: #8E44AD;'--#3498DB;'--FERIADO MANUAL
	SET @VDISP  = 'cursor: not-allowed;background-color: #85C1E9;'--#D4EFDF;'--CARGADO DISPONIBLE
	SET @VNDISP = 'cursor: not-allowed;background-color: #ABB2B9;'--#D5DBDB;'--CARGADO NO DISPONIBLE, OTRO PROYECTO 
	SET @VNDISP2= 'cursor: not-allowed;background-color: #FDFEFE;'--#D5DBDB;'--NO CARGADO
	SET @VLIC	= 'cursor: not-allowed;background-color: #FADBD8;'--LICENCIAS
	SET @VSELEC	= 'cursor: not-allowed;background-color: #DC7633;'--FECHA DESDE SELECCIONADA
	SET @VVERDE = 'cursor: not-allowed;background-color: #27AE60;'--ASIGNADO CONFIRMADO
	SET @VAMAR  = 'cursor: not-allowed;background-color: #F1C40F;'--ASIGNADO PENDIENTE
 
	SELECT	--@VPROYECTO = ISNULL(PROYECTO_ID,''),
			--@VSERVICIO = ISNULL(PROYECTO_SERV_ID,''),
			@VMES = ISNULL(CONVERT(varchar, DATEPART(MM, AGENDA_DESDE)),''),
			@VANO = ISNULL(CONVERT(varchar, DATEPART(YYYY, AGENDA_DESDE)),''),
			@VMES_PROY = ISNULL(AGENDA_MES,''),
			@VANO_PROY = ISNULL(AGENDA_ANO,''),
			--@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,''),
			@VFECHAD = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_DESDE, 105), 23),''),
			@VFECHAH = ISNULL(CONVERT(VARCHAR(10), CONVERT(date, AGENDA_HASTA, 105), 23),''),
			@VSELECCION = ISNULL(BUFFER,''),
			@VPREVIAS = ISNULL(AGENDA_CONSULTORES,''),
			@VID_AGENDA = ISNULL(AGENDA_ID,''),
			@VALIDA_AGENDA = ISNULL(VALIDA_AGENDA,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VCLIENTE	= C.RAZON_SOCIAL_CLIENTE,
			@VNORMA  = '('+P.CODIGO+') - '+P.NORMA_REF,
			--@VSERVICIO  = CASE WHEN A.ID_SERVICIO = '1' THEN 'Consultoria' WHEN A.ID_SERVICIO = '2' THEN 'Auditoria' WHEN A.ID_SERVICIO = '3' THEN 'Capacitacion' END,
			@VDIAS = DIAS,
			@VFECHADESDE = CONVERT(VARCHAR,A.FECHA,103),
			@VFECHAHASTA = CONVERT(VARCHAR,A.FECHA_HASTA,103),
			@VESTADO = CASE WHEN A.ESTADO = 'C' THEN 'Confirmado' WHEN A.ESTADO = 'P' THEN 'Pendiente' ELSE 'Sin Estado' END,
			@VARNORMA = ISNULL(P.NORMAS,''),
			@VNORMAS_PROY = ISNULL(P.NORMAS,''),
			@VCONSULTOR = CASE WHEN ISNULL(A.ID_CONSULTOR,'') = '' THEN 'Sin Consultor'  ELSE dbo.FN_GET_AGENDA_CONSULTOR(A.ID_AGENDA,'M') END,
			@VID_CLIENTE = ISNULL(A.ID_CLIENTE,''),
			@VPROYECTO = ISNULL(A.ID_PROYECTO,''),
			@VTIPOSERVICIO = A.ID_SERVICIO,
			@VSERVICIO = ISNULL(PROYECTO_SERV_ID,'')
	FROM	LK_AGENDA A
			INNER JOIN LK_PROYECTO P ON P.ID_PROYECTO = A.ID_PROYECTO
			INNER JOIN LK_CLIENTES C ON C.ID_CLIENTE = A.ID_CLIENTE
	WHERE	ID_AGENDA = @VID_AGENDA
 
	SELECT	@VNOMBRE = ISNULL(NOMBRE,'')
	FROM	LK_PROYECTO_SERVICIO
	WHERE	ID_PROYECTO_SERVICIO = @VSERVICIO
 
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
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())	
 
	IF (@VMES_PROY = '')
		SELECT @VMES_PROY = DATEPART(MM,GETDATE())	
 
	IF (@VANO_PROY = '')
		SELECT @VANO_PROY = DATEPART(YYYY,GETDATE())
 
	SELECT DISTINCT @VMES_DESC=MesNombre FROM	Calendar WHERE Mes=@VMES_PROY;
 
	EXEC HOME_CMB_MESES_HTML @VMES_DESC, 'AGENDA_MES', @FORM_ID, '05CBFF2A-25B9-48B6-AC2D-8499061B8236', @VMES_HTML OUTPUT;
	
 
	SET @VNUEVAS = @VPREVIAS
	SET @VSELECCION2 = [dbo].[FN_GET_SELECCION] (@VSELECCION)
	
	WHILE PATINDEX('%|%',@VNUEVAS)>0
	BEGIN
		SET @RESULTADO = PATINDEX('%|%',@VNUEVAS) --+ @N
		SET  @VALOR = SUBSTRING(@VNUEVAS,1, @RESULTADO-1)
		
		SET @VEXISTE = DBO.FN_GET_NORMA(@VSELECCION2,@VALOR)
 
		--aca agrego o elimino el dato en el string--
		IF (@VEXISTE = 'SI') BEGIN
			SET @VAGREGO = 'NO'
		END ELSE BEGIN
			SET @VAGREGO = 'SI'
		END
 
		IF (@VAGREGO = 'SI') BEGIN
			SET @VSELECCION = ISNULL(@VSELECCION,'') + @VALOR + '=true|'
		END
		
		SELECT @VNUEVAS = RIGHT(@VNUEVAS,LEN(@VNUEVAS)-PATINDEX('%|%',@VNUEVAS))
	END
	
	SET @VALOR = NULL
	SET @VCONSULTORES = @VSELECCION
	SET @VALERT_CALIF = 'NO'
	SET @VCALIF = NULL
 
	IF (@VCONSULTORES <> '') BEGIN
		WHILE LEN(@VCONSULTORES) > 0
		BEGIN 
			SET @lnuPosComa = CHARINDEX('|', @VCONSULTORES) -- Busca el caracter a separador
			IF (@lnuPosComa = 0) BEGIN 
				SET @lstDato = @VCONSULTORES
				SET @VCONSULTORES = '' 
			END ELSE BEGIN
				SET @lstDato = SUBSTRING(@VCONSULTORES, 1, @lnuPosComa - 1)
				SET @VTORF = SUBSTRING(@lstDato,CHARINDEX('=', @lstDato)+1,LEN(@lstDato))
						
				IF (@VTORF = 'FALSE') BEGIN
					SET @VALOR = REPLACE('|'+ @VALOR,'|'+@VALOR+'|','|')
						IF (SUBSTRING(@VALOR,1,1) = '|') BEGIN
							SET @VALOR = SUBSTRING(@VALOR,2,LEN(@VALOR))
 
						END
				END ELSE BEGIN
 
					SET @VALOR = ISNULL(@VALOR,'') + SUBSTRING(@lstDato,1,CHARINDEX('=', @lstDato)-1) + '|'
 
				END						
 
				SET @VCONSULTORES = SUBSTRING(@VCONSULTORES, @lnuPosComa + 1, LEN(@VCONSULTORES))
			END
		END
	END
 
	UPDATE	XAGENDA
	SET		AGENDA_CONSULTORES = @VALOR
	WHERE	PAR_KEY = @IPKEYJOB
 
	SET @VALOR2 = @VALOR
 
	WHILE LEN(@VNORMAS_PROY) > 0
		
		BEGIN 
			SET @lnuPosComa2 = CHARINDEX('|', @VNORMAS_PROY) -- Busca el caracter a separador
			IF (@lnuPosComa2 = 0) BEGIN 
				SET @lstNorma = @VNORMAS_PROY
				SET @VNORMAS_PROY = '' 
			END ELSE BEGIN
				SET @lstNorma = SUBSTRING(@VNORMAS_PROY, 1, @lnuPosComa2 - 1)
 
				WHILE LEN(@VALOR) > 0
				BEGIN 
					SET @lnuPosComa = CHARINDEX('|', @VALOR) -- Busca el caracter a separador
					IF (@lnuPosComa = 0) BEGIN 
						SET @lstDato = @VALOR
						SET @VALOR = '' 
					END ELSE BEGIN
						SET @lstDato = SUBSTRING(@VALOR, 1, @lnuPosComa - 1)
 
						SELECT @VCALIF = dbo.FN_GET_CALIFICACION(@lstDato,@lstNorma,@VTIPOSERVICIO)
 
						IF (@VCALIF = 'NA' AND @VALERT_CALIF = 'NO') BEGIN
							SET @VALERT_CALIF = 'SI'
						END
 
					END
				
					SET @VALOR = SUBSTRING(@VALOR, @lnuPosComa + 1, LEN(@VALOR))
				END
			END
				
			SET @VNORMAS_PROY = SUBSTRING(@VNORMAS_PROY, @lnuPosComa2 + 1, LEN(@VNORMAS_PROY))
			SET @VALOR = @VALOR2
 
		END
	
	UPDATE	XAGENDA
	SET		ALERTA_CALIF = @VALERT_CALIF
	WHERE	PAR_KEY = @IPKEYJOB
 
	--SET @VALOR = ''
	--SET @VDESCCONS = ''
	--SET @VCONSULTORES = @VSELECCION
 
	/*IF (@VALOR <> '') BEGIN
 
		WHILE LEN(@VALOR) > 0
			BEGIN 
				SET @lnuPosComa = CHARINDEX('|', @VALOR) -- Busca el caracter a separador
				IF (@lnuPosComa = 0) BEGIN 
					SET @lstDato = @VALOR
					SET @VCONSULTORES = '' 
				END ELSE BEGIN
					SET @lstDato = SUBSTRING(@VALOR, 1, @lnuPosComa - 1)
 
					SELECT	@VDESCCONS = '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:10px;color:black;text-align: left">'+APELLIDO_EMPLEADO+', '+NOMBRE_EMPLEADO+'</font>'
					FROM	LK_EMPLEADOS
					WHERE	CONVERT(VARCHAR,ID_EMPLEADO) = @lstDato
 
					SET @OCONSULTORES = ISNULL(@OCONSULTORES,'') + @VDESCCONS + ' </br> '
 
					SET @VALOR = LTRIM(RTRIM(SUBSTRING(@VALOR, @lnuPosComa + 1, LEN(@VALOR))))
				END
			END
		
		SET @OCONSULTORES = SUBSTRING(@OCONSULTORES,1,len(@OCONSULTORES)-1)
		
	END*/
 
	UPDATE	XAGENDA
	SET		FECHA_SELEC = CONVERT(VARCHAR,DATEPART(DD,@VFECHAD)) + '-' + CONVERT(VARCHAR,DATEPART(MM,@VFECHAD)) + '-' + CONVERT(VARCHAR,DATEPART(YYYY,@VFECHAD))
	WHERE	PAR_KEY = @IPKEYJOB
 
	select	@vprimer_semana = min(semanames),
			@vultima_semana = max(semanames)
	from	Calendar
	where	CONVERT(VARCHAR,Mes) = @VMES
	and		CONVERT(VARCHAR,Ano) = @VANO
 
	set @vsemana = @vprimer_semana
 
	select	@vprimer_semana_PROY = min(semanames),
			@vultima_semana_PROY = max(semanames)
	from	Calendar
	where	CONVERT(VARCHAR,Mes) = @VMES_PROY
	and		CONVERT(VARCHAR,Ano) = @VANO_PROY
 
	set @vsemana_PROY = @vprimer_semana_PROY
 
SET @VTABLA2 = '<table class="w3-table w3-bordered">
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
 
	while @vsemana_PROY <= @vultima_semana_PROY 
	begin			
		
		SET @VTABLA2 = @VTABLA2 +
			'<tr>'
 
		--INSERT INTO dbo.Agenda (PAR_KEY, Domingo, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado)
		SELECT  --@IPKEYJOB, 
				@vdomingo_PROY = '<td id="td01">'+
											case when TOTAL.DOMINGO = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.DOMINGO,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.DOMINGO)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																			end +''' class='''+@VCLASE+'''>'+substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1)+'</span>' 
													--+'</div>'
													else
														'<span style='''+@VSTYLE+'''class='''+@VCLASE+'''>'+convert(varchar,TOTAL.DOMINGO)+'</span>'
													end
												end
											 end+'</td>', 
				@vlunes_PROY = '<td id="td01">'+case when TOTAL.LUNES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.LUNES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.LUNES)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.LUNES)+'</span>'
													end
												end
											 end+'</td>', 
				@vmartes_PROY = '<td id="td01">'+case when TOTAL.MARTES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.MARTES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.MARTES)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MARTES)+'</span>'
													end
												end
											 end+'</td>', 
				@vmiercoles_PROY = '<td id="td01">'+case when TOTAL.MIERCOLES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.MIERCOLES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.MIERCOLES)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.MIERCOLES)+'</span>'
													end
												end
											 end+'</td>', 
				@vjueves_PROY = '<td id="td01">'+case when TOTAL.JUEVES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.JUEVES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.JUEVES)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.JUEVES)+'</span>'
													end
												end
											 end+'</td>',
				@vviernes_PROY = '<td id="td01">'+case when TOTAL.VIERNES = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.VIERNES,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.VIERNES)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.VIERNES)+'</span>'
													end
												end
											 end+'</td>',
				@vsabado_PROY = '<td id="td01">'+case when TOTAL.SABADO = '' then 
													'' 
											 else
												case when
													case when (CHARINDEX('-',TOTAL.SABADO,1) > 0) then 
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1))))+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
													else
														CONVERT(VARCHAR(10), CONVERT(date, CONVERT(VARCHAR,TOTAL.SABADO)+'-'+@VMES_PROY+'-'+@VANO_PROY, 105), 23)
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
																		 end +''' class='''+@VCLASE+'''>'+substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1)+'</span>'
													--+'</div>'
													else
														'<span style='''+@VSTYLE+''' class='''+@VCLASE+'''>'+convert(varchar,TOTAL.SABADO)+'</span>'
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
								LEFT JOIN LK_AGENDA_EMPLEADO A ON C.FECHA = A.FECHA AND	A.HOLIDAYTEXT in (SELECT CONVERT(VARCHAR,ID_AGENDA) FROM LK_AGENDA WHERE ID_CLIENTE = @VID_CLIENTE and ID_PROYECTO = @VPROYECTO and ID_SERVICIO = @VTIPOSERVICIO AND PROYECTO_SERV_ID = @VSERVICIO)
						where	CONVERT(VARCHAR,C.Mes) = @VMES_PROY
						and		CONVERT(VARCHAR,C.Ano) = @VANO_PROY
						and		SemanaMes = @vsemana_PROY) MES
				) TOTAL
		
 
		SET @VTABLA2 = @VTABLA2 + @vdomingo_PROY +	@vlunes_PROY + @vmartes_PROY + @vmiercoles_PROY + @vjueves_PROY + @vviernes_PROY + @vsabado_PROY + 
						'</tr>'
 
		set @vsemana_PROY = @vsemana_PROY + 1
 
	end
	--END
 
	SET @VTABLA2 = @VTABLA2 + '</table>'
 
 
SET @VMES_ANT_PROY = @VMES_PROY - 1
SET @VANO_ANT_PROY = @VANO_PROY - 1
SET @VMES_SIG_PROY = @VMES_PROY + 1
SET @VANO_SIG_PROY = @VANO_PROY + 1
 
SET @OHEADER = '
	<div>
	<p>
		<button onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''+''+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5''); return false;" class="w3-button w3-round w3-left w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
		<button onclick="almacenarSeleccion(''VALIDA_AGENDA'','''+'SI'+''');saveValues2(''AGENDA_NORMAS'');saveValues(''ACUMULA'');next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Confirmar</b></font></button>
	</p>
	</div>
 
	<div class="w3-row">
		<div class="w3-col w3-container" style="width:30%;background-color:#2980B9;text-align:left">
			<p>
			<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:16px;color:#FFFFFF;text-align: left"><b>Confirma Modificar Visita</b></font>
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
			<th><b>Opc.</b></th>
			</tr>
		</thead>
		<tr class="w3-grey">' +
			  '<td>'+@VCLIENTE+'</td>'+
			  '<td>'+@VNORMA+'</td>' +
			  '<td>'+CASE WHEN @VTIPOSERVICIO = '1' THEN	'Consultoria&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '2' THEN	'Auditoria&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
					WHEN @VTIPOSERVICIO = '3' THEN	'Capacitacion' END	 +'</td>'+
			  '<td>'+ISNULL(@VNOMBRE,'')+'</td>' +
			  '<td>'+@VDIAS+'</td>' +
			  '<td>'+@VFECHADESDE+'</td>' +
			  '<td>'+@VFECHAHASTA+'</td>' +
			  '<td>'+@VESTADO+'</td>' +
			  '<td>'+@VCONSULTOR+'</td>
			  <td><a class="w3-button" href="javascript:void(0);" onclick="w3_open_div(''div_calendar'')" title="Ver Agenda"><i class="fa fa-caret-down" style="display: inline;"></i></a></td>
			</tr>
	</table>
	</div>'
 
SET @OAGENDA_PROY = '
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
		<div id="div_calendar" class="w3-container" style="display: none">
			<div class="w3-cell-row w3-grey">
			<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES_PROY = '1' THEN '12'
																		ELSE @VMES_ANT_PROY END+');
								 almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES_PROY = '1' THEN @VANO_ANT_PROY 
																		ELSE @VANO_PROY END+');
								almacenarSeleccion(''VALIDA_AGENDA'','''+'NO'+''');goto('''+@FORM_ID+''',''05CBFF2A-25B9-48B6-AC2D-8499061B8236'');""><i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
								'<div class="w3-cell w3-cell-middle w3-center">'+@VMES_HTML+'</div>'+
								'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','+CASE WHEN @VMES_PROY = '12' THEN '1'
																		ELSE @VMES_SIG_PROY END+');
								 almacenarSeleccion(''AGENDA_ANO'','+CASE WHEN @VMES_PROY = '12' THEN @VANO_SIG_PROY 
																		ELSE @VANO_PROY END+');
								almacenarSeleccion(''VALIDA_AGENDA'','''+'NO'+''');goto('''+@FORM_ID+''',''05CBFF2A-25B9-48B6-AC2D-8499061B8236'');"><i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>'+
			'<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES_PROY+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_ANT_PROY+''');almacenarSeleccion(''VALIDA_AGENDA'','''+'NO'+''');goto('''+@FORM_ID+''',''05CBFF2A-25B9-48B6-AC2D-8499061B8236'');"">'+
					'<i class="fas fa-arrow-alt-circle-left w3-center" title="Anterior"></i></a>'+
			'<div class="w3-cell w3-cell-middle w3-center"><b>'+@VANO_PROY+'</b></div>'+
			+ '<a class="w3-button w3-cell w3-cell-middle" href="javascript:almacenarSeleccion(''AGENDA_MES'','''+@VMES_PROY+''');almacenarSeleccion(''AGENDA_ANO'','''+@VANO_SIG_PROY+''');almacenarSeleccion(''VALIDA_AGENDA'','''+'NO'+''');goto('''+@FORM_ID+''',''05CBFF2A-25B9-48B6-AC2D-8499061B8236'');">'+
			'<i class="fas fa-arrow-alt-circle-right w3-center" title="Siguiente"></i></a>'+
			'<span onclick="w3_close_div(''div_calendar'')" class="w3-cell w3-button w3-xlarge w3-right" style="font-weight:bold;">×</span>
			</div><br>
 
		' + @VTABLA2 + '
  
		</div>
		<div class="w3-panel w3-topbar"></div>
	<script>
	function w3_close_div(id) {
		var div = document.getElementById(id);
		div.style.display = "none";
	}
	function w3_open_div(id) {
		var div = document.getElementById(id);
		div.style.display = "block";
	}
	</script>'
 
	SET @OFOOTER = '
	<html>
	<body>
 
	<div class="w3-panel w3-topbar">
	</div>
 
	<div>
	<p>
		<button onclick="almacenarSeleccion(''AGENDA_CONSULTOR'','''+''+''');goto('''+@FORM_ID+''',''8F8DE75E-0B4E-4E4E-B70E-33D78E5F20F5''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Volver</b></font></button>
		<button onclick="almacenarSeleccion(''VALIDA_AGENDA'','''+'SI'+''');saveValues2(''AGENDA_NORMAS'');saveValues(''ACUMULA'');next('''+@FORM_ID+'''); return false;" class="w3-button w3-round w3-center w3-border w3-border-white w3-opacity-min" style="background-color:#2980B9"><font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:12px;color:#FFFFFF"><b>Confirmar</b></font></button>
	</p>
	</div>
 
	</body>
	</html>'
 
	IF (@VALERT_CALIF = 'SI' AND @VALIDA_AGENDA NOT IN('SI','NO')) BEGIN
		SET @OALERTA = '<script type="text/javascript">alert("Ha Seleccionado Algun Consultor que NO tiene Calificacion para Alguna de las Normas del Proyecto");</script>'
	END
	
	UPDATE	XAGENDA
	SET		ERROR = 'NO',
			VALIDA_AGENDA = '1'
	WHERE	PAR_KEY = @IPKEYJOB
 
END
