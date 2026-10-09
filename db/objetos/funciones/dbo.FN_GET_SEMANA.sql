 
 
CREATE FUNCTION [dbo].[FN_GET_SEMANA] (@ICONSULTOR INT, @vmes INT, @vano INT, @vsemana INT)
RETURNS VARCHAR(MAX)
AS BEGIN
    DECLARE @vdomingo		varchar(4000),
			@vlunes			varchar(4000),
			@vmartes		varchar(4000),
			@vmiercoles		varchar(4000),
			@vjueves		varchar(4000),
			@vviernes		varchar(4000),
			@vsabado		varchar(4000),
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
			@var_mes		VARCHAR(50),
			@var_ano		VARCHAR(50)
	
	SET @var_mes = CONVERT(VARCHAR(50),@vmes)
	SET @var_ano = CONVERT(VARCHAR(50),@vano)
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
 
	SELECT  @vdomingo	= '<span style='''+case when TOTAL.DOMINGO = '' then 
											'''>' + '</span>'
											else
											case when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.DOMINGO,1,CHARINDEX('-',TOTAL.DOMINGO,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.DOMINGO,CHARINDEX('-',TOTAL.DOMINGO,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
												case when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.LUNES,1,CHARINDEX('-',TOTAL.LUNES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.LUNES,CHARINDEX('-',TOTAL.LUNES,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
											case when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MARTES,1,CHARINDEX('-',TOTAL.MARTES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.MARTES,CHARINDEX('-',TOTAL.MARTES,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
											case when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.MIERCOLES,1,CHARINDEX('-',TOTAL.MIERCOLES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.MIERCOLES,CHARINDEX('-',TOTAL.MIERCOLES,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
											case when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal' 
																		when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.JUEVES,1,CHARINDEX('-',TOTAL.JUEVES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.JUEVES,CHARINDEX('-',TOTAL.JUEVES,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
											case when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.VIERNES,1,CHARINDEX('-',TOTAL.VIERNES,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.VIERNES,CHARINDEX('-',TOTAL.VIERNES,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
											case when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'OC' then
																			@VNDISP +''' title = ''' + 'Organismo Certificacion'
																		when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'OP' then
																			@VNDISP +''' title = ''' + 'Ocupado Personal'
																		when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) = 'ND' then
																		@VNDISP +''' title = ''' + 'No Disponible'
																		when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,2))) = 'D' then
																		@VDISP +''' title = ''' + 'Disponible'
																		when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,4))) = 'LIC' then
																		@VLIC +''' title = ''' + 'Licencia ' + case when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+7,2))) = 'M' then 'Medica' else 'Vacaciones' end
																		when ltrim(rtrim(SUBSTRING(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,4))) = 'POT' then
																		@VNARANJA +''' title = ''' + 'Potencial - '+ [dbo].[FN_GET_AGENDA_CONSULTOR_DESC] (CONVERT(date, CONVERT(VARCHAR,ltrim(rtrim(substring(TOTAL.SABADO,1,CHARINDEX('-',TOTAL.SABADO,1)-1))))+'-'+@var_mes+'-'+@var_ano, 105), @ICONSULTOR) + ''
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
														when ltrim(rtrim(substring(TOTAL.SABADO,CHARINDEX('-',TOTAL.SABADO,1)+1,3))) in ('ND','NA','OP','OC') THEN
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
						LEFT JOIN LK_AGENDA_EMPLEADO A ON A.FECHA = C.Fecha and A.ID_EMPLEADO = @ICONSULTOR
						--LEFT JOIN LK_AGENDA AG ON AG.FECHA = C.Fecha and AG.ID_CLIENTE = @VID_CLIENTE and AG.ID_PROYECTO = @VPROYECTO and AG.ID_SERVICIO = @VTIPOSERVICIO
						--LEFT JOIN LK_EMPLEADOS EMP ON AG.ID_CONSULTOR = EMP.ID_EMPLEADO
				where	CONVERT(VARCHAR,C.Mes) = @vmes
				and		CONVERT(VARCHAR,C.Ano) = @vano
				and		SemanaMes = @vsemana) MES
				--and		c.Fecha >= @VFECHAD
				--and		c.Fecha <= @VFECHAH) MES
				) TOTAL
 
    RETURN @vdomingo+'&nbsp;&nbsp;' +@vlunes+'&nbsp;&nbsp;'+@vmartes+'&nbsp;&nbsp;'+@vmiercoles+'&nbsp;&nbsp;'+@vjueves+'&nbsp;&nbsp;'+@vviernes+'&nbsp;&nbsp;'+@vsabado 
END
