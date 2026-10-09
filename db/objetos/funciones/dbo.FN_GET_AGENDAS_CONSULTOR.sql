 
CREATE FUNCTION [dbo].[FN_GET_AGENDAS_CONSULTOR] (@IPKEY_JOB VARCHAR(100), @ICONSULTOR INT, @IFECHA VARCHAR(50), @FORM_ID VARCHAR(100))
RETURNS VARCHAR(4000)
AS BEGIN
    DECLARE @VAGENDA			INT,
			@VHORAS				INT,
			@VHORAS_AGENDAS		INT,
			@VHORAS_DISP		INT,
			@VCLIENTE			VARCHAR(50),
			@VPROYECTO			VARCHAR(50),
			@VSERVICIO			VARCHAR(50),
			@VDATO				VARCHAR(4000),
			@VPREVIUS			VARCHAR(50)
 
	SELECT	@VPREVIUS = ISNULL(PREVIUS,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEY_JOB
	
	SET @VHORAS_AGENDAS = [dbo].[FN_GET_CONSULTOR_HORAS] (@ICONSULTOR, @IFECHA)
	SET @VHORAS_DISP = [dbo].[FN_GET_CONSULTOR_HORAS_DISP] (@ICONSULTOR, @IFECHA)
	
	DECLARE Agendas CURSOR FOR 
	SELECT	HOLIDAYTEXT, HORAS
	FROM	LK_AGENDA_EMPLEADO
	WHERE	ID_EMPLEADO	= @ICONSULTOR
	AND		FECHA = @IFECHA
	ORDER BY FECHA, HOLIDAYTEXT
			
	OPEN Agendas  
	FETCH NEXT FROM Agendas INTO @VAGENDA, @VHORAS
 
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
 
		SELECT	@VCLIENTE = ISNULL(ID_CLIENTE,''),
				@VPROYECTO = ISNULL(ID_PROYECTO,''),
				@VSERVICIO = ISNULL(PROYECTO_SERV_ID,'')
		FROM	LK_AGENDA
		WHERE	ID_AGENDA = @VAGENDA
		
		SET @VDATO = isnull(@VDATO,'') + 
		'<li><span class="event">'+ 
			'<i class="'+ CASE WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Consultoria' THEN 
									'fas fa-user-tie w3-large"'
								WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Auditoria' THEN 
									'fas fa-chalkboard-teacher w3-large"'
								WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Capacitacion' THEN 
									'fas fa-user-graduate w3-large"' END+
				'style="cursor:pointer;" title="'+CASE WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Consultoria' THEN 
									'Consultoria'
								WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Auditoria' THEN 
									'Auditoria'
								WHEN ISNULL([dbo].[FN_GET_AGENDA_SERVICIO] (@VAGENDA),'') = 'Capacitacion' THEN 
									'Capacitacion' END
				--+ ' / ' + dbo.FN_GET_AGENDA_CLIENTE(A.HOLIDAYTEXT)
				+ ' / ' + dbo.FN_GET_AGENDA_PROYECTO(@VAGENDA)+'"
				onclick="'+ CASE WHEN @VPREVIUS <> '' THEN 'confirmar=confirm(''¿Esta seguro que Desea Ver el Detalle? Si Confirma Deberá Cargar Nuevamente la Visita en Curso'');
						if (confirmar){' ELSE '' END + 'almacenarSeleccion(''TAB'',''1'');almacenarSeleccion(''TAB_SERV'',''1'');almacenarSeleccion(''TAB_AGENDA'',''0'');
						 almacenarSeleccion(''CLIENTE'','''+@VCLIENTE+''');almacenarSeleccion(''PROYECTO_ID'','''+@VPROYECTO+''');almacenarSeleccion(''PROYECTO_SERV_ID'','''+@VSERVICIO+''');almacenarSeleccion(''AGENDA_ID'','''+CONVERT(VARCHAR,@VAGENDA)+''');
						 goto('''+@FORM_ID+''',''40D2D9E1-74E8-4135-A54E-EBA6D61AC8E5'');return false;'+ CASE WHEN @VPREVIUS <> '' THEN '}' ELSE '' END +'"></i>' + '&nbsp;' +
				ISNULL(SUBSTRING([dbo].[FN_GET_AGENDA_CLIENTE] (@VAGENDA),1,20),'')+'</span>
			<span class="time"><b>('+ISNULL(CONVERT(VARCHAR,@VHORAS),'0')+')</b></span>
		</li>'
					
		FETCH NEXT FROM Agendas INTO @VAGENDA, @VHORAS
	END 
 
	CLOSE Agendas  
	DEALLOCATE Agendas
 
	IF ((@VHORAS_DISP - @VHORAS_AGENDAS > 0)) BEGIN
		SET @VDATO = isnull(@VDATO,'') + 
		'<li><span class="event">Disponible</span>
			<span class="time"><b>('+ISNULL(CONVERT(VARCHAR,@VHORAS_DISP - @VHORAS_AGENDAS),'0')+')</b></span>
		</li>'
	END
 
	RETURN ISNULL(@VDATO,'')
 
END
