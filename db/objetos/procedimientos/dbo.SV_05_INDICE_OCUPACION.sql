CREATE PROCEDURE [dbo].[SV_05_INDICE_OCUPACION]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100),
 @IUNIDAD	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @IJOBSEQ	AS INT,
 @OHEADER	AS VARCHAR(4000) OUTPUT,
 @OPANEL	AS VARCHAR(MAX) OUTPUT
 )
AS
 
DECLARE @UNITDESC		VARCHAR(300),
		@USERDESC		VARCHAR(300),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME,
		@VFDESDE_ANUAL	DATETIME,
		@VFHASTA_ANUAL	DATETIME,
		@VMES			VARCHAR(50),
		@VANO			VARCHAR(50),
		@VMES_DESC      VARCHAR(100),
		@VMES_HTML      VARCHAR(max),
		@VANO_DESC      VARCHAR(100),
		@VANO_HTML      VARCHAR(max),
		@VPROM_IND_DISP decimal(10, 2),
		@VPROM_IND_COMP decimal(10, 2),
		@VPROM_OCUP		decimal(10, 2),
		@VTOTAL_DIAS_OCUP INT,
		@VOPTIONS_MESES VARCHAR(MAX),
		@VCODE_MES		VARCHAR(50),
		@VOPTIONS_ANO	VARCHAR(MAX),
		@VCODE_ANO		VARCHAR(50)
 
BEGIN	
 
	SELECT	@VFECHA_DESDE = FECHA_DESDE,
			@VFECHA_HASTA = FECHA_HASTA,
			@VMES = ISNULL(MES,''),
			@VANO = ISNULL(ANO,'')
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	IF (@VMES = '')
		SELECT @VMES = DATEPART(MM,GETDATE())	
 
	IF (@VANO = '')
		SELECT @VANO = DATEPART(YYYY,GETDATE())
 
	SET @VOPTIONS_MESES = '<option onclick="saveSelection(''MES'',''TODOS'');" value="TODOS"'+ CASE WHEN ISNULL(CONVERT(VARCHAR,@VMES),'') = 'TODOS' THEN 'selected="selected"' ELSE '' END+'>Todos</option>'
 
	DECLARE Meses CURSOR FOR 
		SELECT	DISTINCT Mes, MesNombre
		FROM	Calendar 
		WHERE	Ano = @VANO
		order by Mes
 
		OPEN Meses  
		FETCH NEXT FROM Meses INTO @VCODE_MES, @VMES_DESC
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
 
			SET @VOPTIONS_MESES =  isnull(@VOPTIONS_MESES,'') + 
	
				'<option onclick="saveSelection(''MES'','''+@VCODE_MES+''');" value="'+@VCODE_MES+'"'+ CASE WHEN ISNULL(CONVERT(VARCHAR,@VMES),'') = @VCODE_MES THEN 'selected="selected"' ELSE '' END+'>'+@VMES_DESC+'</option>'
			
			FETCH NEXT FROM Meses INTO @VCODE_MES, @VMES_DESC
		END 
 
	CLOSE Meses  
	DEALLOCATE Meses	
 
	DECLARE Anos CURSOR FOR 
		SELECT	Ano
		FROM	Calendar
		GROUP BY Ano
		ORDER BY Ano
 
		OPEN Anos  
		FETCH NEXT FROM Anos INTO @VCODE_ANO--, @VANO_DESC
 
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
 
			SET @VOPTIONS_ANO =  isnull(@VOPTIONS_ANO,'') + 
	
				'<option onclick="saveSelection(''ANO'','''+@VCODE_ANO+''');" value="'+@VCODE_ANO+'"'+ CASE WHEN ISNULL(CONVERT(VARCHAR,@VANO),'') = @VCODE_ANO THEN 'selected="selected"' ELSE '' END+'>'+@VCODE_ANO+'</option>'
			
			FETCH NEXT FROM Anos INTO @VCODE_ANO--, @VANO_DESC
		END 
 
	CLOSE Anos  
	DEALLOCATE Anos
 
	--SELECT DISTINCT @VMES_DESC=MesNombre FROM Calendar WHERE CONVERT(VARCHAR,Mes)=@VMES;
 
	--IF (@VMES_DESC IS NULL)
	--	SET @VMES_DESC = 'Todos'
 
	--SELECT DISTINCT @VANO_DESC=Ano FROM	Calendar WHERE Ano=@VANO;
 
	--EXEC HOME_CMB_MESES_HTML_TODOS @VMES_DESC, 'MES', @FORM_ID, 'EAD5B2BE-755B-40F8-8C17-173A0DACAA4C', @VMES_HTML OUTPUT;
 
	--EXEC HOME_CMB_ANOS_HTML @VANO_DESC, 'ANO', @FORM_ID, 'EAD5B2BE-755B-40F8-8C17-173A0DACAA4C', @VANO_HTML OUTPUT;
 
	/*
	se calculan los indicadores
	*/
	SELECT	@VFDESDE_ANUAL = MIN(fecha), @VFHASTA_ANUAL = max(fecha)
	FROM	Calendar
	WHERE	Ano = @VANO
 
	SELECT	@VFECHA_DESDE = PrimerDiaMes, 
			@VFECHA_HASTA = UltimoDiaMes 
	FROM	Calendar 
	WHERE	Fecha = convert(varchar,GETDATE(),113)
 
	SELECT	@VTOTAL_DIAS_OCUP=SUM(CASE WHEN (@VMES = 'TODOS') THEN
				[dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO)
			ELSE
				[dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO) 
			END),
			@VPROM_IND_DISP=AVG(CASE WHEN (@VMES = 'TODOS') THEN
				cast([dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFDESDE_ANUAL,@VFHASTA_ANUAL) as decimal(10, 2))
			ELSE
				cast([dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFECHA_DESDE,@VFECHA_HASTA) as decimal(10, 2)) 
			END),
			@VPROM_IND_COMP=AVG(CASE WHEN (@VMES = 'TODOS') THEN
				CASE WHEN ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) = 0 THEN
					0
				ELSE
					cast([dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2)) 
				END
			ELSE
				case when ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) = 0 then 
					0 
				else
					cast([dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2)) 
				end 
			END),
			@VPROM_OCUP=AVG(CASE WHEN (@VMES = 'TODOS') THEN
				case when [dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO) = 0 then 
					0 
				else 
					cast([dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2))--[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO) as decimal(10, 2)) 
				end
			ELSE
				case when [dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO) = 0 then 
					0 
				else 
					cast([dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2))--[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) as decimal(10, 2)) 
				end 
			END)
	FROM	LK_EMPLEADOS EMP
	WHERE	EMP.PERFIL_EMP = 'CONSULTOR'
	AND		ISNULL(EMP.EVENTUAL,'NO') = 'NO'
	AND		((EMP.STATUS_EMP = '1') OR (CASE WHEN (@VMES = 'TODOS') THEN
											[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO)
										ELSE
											[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) 
										END > 0))
 
	SET @OHEADER = '
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round">
				<div class="w3-bar w3-muhle-vocaturo w3-round w3-padding">
					<span class="w3-bar-item w3-muhle-text-14 w3-left" style="color:white"><i class="fas fa-chart-pie fa-fw w3-large"></i>&nbsp;&nbsp;Índice Ocupación Consultores</span>
					<span class="w3-bar-item w3-muhle-text-14 w3-right" style="color:white;"><i class="fas fa-arrow-alt-circle-left w3-margin-center w3-large" style="cursor:pointer;color:white;" title="Volver" style="cursor:pointer;" onclick="goto('''+@FORM_ID+''',''3156A499-EF81-4F52-818A-AE94DAF5583B'');return false;"></i></span>
				</div>
			</div>
		</div>
	</div>'
 
	--<input class="w3-input w3-round w3-border w3-muhle-text-12" type="date" name="SP.FECHA_HASTA" value="'+ISNULL(CONVERT(VARCHAR(10), CONVERT(date, @VFECHA_HASTA, 105), 23),'')+'">
	SET @OPANEL = 
	'<div class="w3-row w3-back w3-light-grey">
			<div class="w3-col w3-padding">
				<div class="w3-card-4 w3-round">
					<div class="w3-container w3-white w3-padding w3-round-up">
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Mes</label>
							<select class="w3-input w3-round w3-border w3-center w3-muhle-text-11" id="comboA" onchange="getComboA(this);">
								'+ISNULL(@VOPTIONS_MESES,'')+'
							</select>
						</div>
						<div class="w3-col m2 w3-padding-small">
							<label class="w3-muhle-text-12">&nbsp;<i class="fas fa-calendar"></i>&nbsp;&nbsp;Año</label>
							<select class="w3-input w3-round w3-border w3-center w3-muhle-text-11" id="comboB" onchange="getComboB(this);">
								'+ISNULL(@VOPTIONS_ANO,'')+'
							</select>
						</div>
						<div class="w3-col m1 w3-padding-small">
							<br>
							<button class="w3-button w3-muhle-text-14 w3-round w3-muhle-color w3-text-white" title="Buscar" onclick="goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');return false;"><i class="fas fa-search"></i></button>
						</div>
					</div>
				</div>
			</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">
	<div class="w3-panel w3-topbar"></div>
	<div class="w3-container">
		<div class="w3-row-padding">
			<div class="w3-col m3" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-red"  style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+isnull(CAST(@VPROM_OCUP AS VARCHAR),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-user-tie w3-large"></i> Prom. % Ocup.</span>
					</div>
				</div>
			</div>
			<div class="w3-col m3" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-blue" style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+ISNULL(CAST(@VPROM_IND_DISP AS varchar),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-business-time w3-large"></i> Prom. Indice Disp.</span>
					</div>
				</div>
			</div>
			<div class="w3-col m3" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-green" style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+isnull(cast(@VPROM_IND_COMP AS varchar),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-user-clock w3-large"></i> Prom. Indice Comp.</span>
					</div>
				</div>
			</div>	
			<div class="w3-col m3" style="cursor:pointer;display: flex;justify-content: center;flex-wrap: wrap;">
				<div class="w3-container w3-round-large w3-orange w3-text-white" style="width:350px;height:100px;">
					<div class="w3-center w3-padding">
					  <span class="w3-muhle-text-20 w3-text-white">'+isnull(cast(@VTOTAL_DIAS_OCUP AS varchar),'0')+'</span>
					</div>
					<div class="w3-clear"></div>
					<div class="w3-center w3-padding">
						<span class="w3-muhle-text-14 w3-text-white"><i class="fas fa-user-clock w3-large"></i> Total Dias Ocup.</span>
					</div>
				</div>
			</div>			
		</div>
	</div>
	<script>
	function getComboA(selectObject) {
    var value = selectObject.value;
	saveSelection(''MES'',value);goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');
	}
	function getComboB(selectObject) {
    var value = selectObject.value;
	saveSelection(''ANO'',value);goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');
	}
	</script>
	<div class="w3-panel w3-topbar"></div>
			</div>
		</div>
	</div>
	<div class="w3-row w3-back w3-light-grey">
		<div class="w3-col w3-padding">
			<div class="w3-card-4 w3-round w3-padding">'
 
 
	--SET @OPANEL = '
	--<div class="w3-panel w3-topbar"></div>
	--<div class="w3-cell-row w3-grey">
	--	<a class="w3-button w3-cell w3-cell-middle">'+@VMES_HTML+'</a>'+
	--	'<a class="w3-button w3-cell w3-cell-middle">'+@VANO_HTML+'</a>'+
	--	'<a class="w3-button w3-cell w3-cell-right" href="javascript:goto('''+@FORM_ID+''',''EAD5B2BE-755B-40F8-8C17-173A0DACAA4C'');"><i class="fa fa-search"></i>&nbsp;Buscar</a>
	--</div>
	--<div class="w3-panel w3-topbar"></div>
	--<div class="w3-container">
	--	<div class="w3-row-padding">
	--		<div class="w3-quarter" style="cursor:pointer;">
	--			<div class="w3-container w3-round-large w3-red w3-padding-large">
	--				<div class="w3-center">
	--				  <h3>'+isnull(CAST(@VPROM_OCUP AS VARCHAR),'0')+'</h3>
	--				</div>
	--				<div class="w3-clear"></div>
	--				<div class="w3-center">
	--					<h5><i class="fas fa-user-lock w3-xlarge"></i> Prom. % Ocup.</h5>
	--				</div>
	--			</div>
	--		</div>
	--		<div class="w3-quarter" style="cursor:pointer;">
	--			<div class="w3-container w3-round-large w3-blue w3-padding-large">
	--				<div class="w3-center">
	--				  <h3>'+ISNULL(CAST(@VPROM_IND_DISP AS varchar),'0')+'</h3>
	--				</div>
	--				<div class="w3-clear"></div>
	--				<div class="w3-center">
	--					<h5><i class="fas fa-user-check w3-xlarge"></i> Prom. Indice Disp.</h5>
	--				</div>
	--			</div>
	--		</div>
	--		<div class="w3-quarter" style="cursor:pointer;">
	--			<div class="w3-container w3-round-large w3-green w3-padding-large">
	--				<div class="w3-center">
	--				  <h3>'+isnull(cast(@VPROM_IND_COMP AS varchar),'0')+'</h3>
	--				</div>
	--				<div class="w3-clear"></div>
	--				<div class="w3-center">
	--					<h5><i class="fas fa-user-shield w3-xlarge"></i> Prom. Indice Comp.</h5>
	--				</div>
	--			</div>
	--		</div>
	--		<div class="w3-quarter" style="cursor:pointer;">
	--			<div class="w3-container w3-round-large w3-orange w3-text-white w3-padding-large">
	--				<div class="w3-center">
	--				  <h3>'+isnull(cast(@VTOTAL_DIAS_OCUP AS varchar),'0')+'</h3>
	--				</div>
	--				<div class="w3-clear"></div>
	--				<div class="w3-center">
	--					<h5><i class="fas fa-user-clock w3-xlarge"></i> Total Dias Ocup.</h5>
	--				</div>
	--			</div>
	--		</div>
	--	</div>
	--</div>
	--<div class="w3-panel w3-topbar"></div>'
 
	UPDATE	TMT_SV_05
	SET		MES = CASE WHEN ISNULL(MES,'') = '' THEN @VMES ELSE MES END,
			ANO = CASE WHEN ISNULL(ANO,'') = '' THEN @VANO ELSE ANO END
	WHERE	PAR_KEY = @IPKEYJOB
 
END
