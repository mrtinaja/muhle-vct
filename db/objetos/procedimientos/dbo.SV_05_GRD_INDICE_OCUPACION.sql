CREATE PROCEDURE [dbo].[SV_05_GRD_INDICE_OCUPACION]
(@IPKEYJOB	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
AS
 
DECLARE	@VMES	VARCHAR(50),
		@VANO	VARCHAR(50),
		@VFECHA_DESDE	DATETIME,
		@VFECHA_HASTA	DATETIME,
		@VFDESDE_ANUAL	DATETIME,
		@VFHASTA_ANUAL	DATETIME
 
BEGIN	
 
	SELECT	@VMES = ISNULL(MES,''),--CASE WHEN ISNULL(MES,'') = 'TODOS' THEN '' ELSE ISNULL(MES,'') END,
			@VANO = ISNULL(ANO,'')
	FROM	TMT_SV_05
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	@VFDESDE_ANUAL = MIN(fecha), @VFHASTA_ANUAL = max(fecha)
	FROM	Calendar
	WHERE	Ano = @VANO
 
	SELECT	@VFECHA_DESDE = PrimerDiaMes, 
			@VFECHA_HASTA = UltimoDiaMes 
	FROM	Calendar 
	WHERE	Fecha = convert(varchar,GETDATE(),113)
 
	IF (@VMES = 'TODOS') BEGIN
 
			SELECT	CASE WHEN (EMP.STATUS_EMP = '1') THEN 
						'<div class="w3-left w3-muhle-text-11">'+EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO + '</div>' 
					ELSE 
						'<div class="w3-left w3-muhle-text-11" style="color:red">'+ EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO + '</div>' 
					END													AS '<div class="w3-left w3-muhle-text-11">Consultor</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
					END													AS '<div class="w3-center w3-muhle-text-11">Dias Disponibles</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
					END													AS '<div class="w3-center w3-muhle-text-11">Dias Comprometidos</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
					END													AS '<div class="w3-center w3-muhle-text-11">Dias Ocupados</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFDESDE_ANUAL,@VFHASTA_ANUAL) as decimal(10, 2)))+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFECHA_DESDE,@VFECHA_HASTA) as decimal(10, 2)))+ '</div>'
					END													AS '<div class="w3-center w3-muhle-text-11">Indice Disp.</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						CASE WHEN ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) = 0 THEN
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2)))+ '</div>'
						END
					ELSE
						CASE WHEN ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) = 0 THEN 
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2)))+ '</div>'
						END 
					END													AS '<div class="w3-center w3-muhle-text-11">Indice Comp.</div>',
					CASE WHEN (@VMES = 'TODOS') THEN
						CASE WHEN [dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO) = 0 THEN
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2)))+ '</div>'
						END
					ELSE
						CASE WHEN [dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO) = 0 THEN
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0) + '</div>'
						ELSE
							'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2)))+ '</div>'
						END
					END													AS '<div class="w3-center w3-muhle-text-11">% Ocupacion</div>'
			FROM	LK_EMPLEADOS EMP
			WHERE	EMP.PERFIL_EMP = 'CONSULTOR'
			AND		ISNULL(EMP.EVENTUAL,'NO') = 'NO'
			AND		((EMP.STATUS_EMP = '1') OR (CASE WHEN (@VMES = 'TODOS') THEN
													[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO)
												ELSE
													[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) 
												END > 0))
			AND		CONVERT(VARCHAR,CONVERT(INT,DATEPART(YYYY, EMP.FECHA_ALTA))) <= CONVERT(VARCHAR,CONVERT(INT,@VANO))
			ORDER BY EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO 
 
	END ELSE BEGIN
 
		SELECT	CASE WHEN (EMP.STATUS_EMP = '1') THEN 
					'<div class="w3-left w3-muhle-text-11">'+ EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO + '</div>'
				ELSE 
					'<div class="w3-left w3-muhle-text-11" style="color:red">'+ EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO + '</div>' 
				END													AS '<div class="w3-left w3-muhle-text-11">Consultor</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
				ELSE
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
				END													AS '<div class="w3-center w3-muhle-text-11">Dias Disponibles</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
				ELSE
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
				END													AS '<div class="w3-center w3-muhle-text-11">Dias Comprometidos</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO))+ '</div>'
				ELSE
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,[dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO))+ '</div>'
				END													AS '<div class="w3-center w3-muhle-text-11">Dias Ocupados</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFDESDE_ANUAL,@VFHASTA_ANUAL) as decimal(10, 2)))+ '</div>'
				ELSE
					'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / [dbo].[FN_GET_DIAS_HABILES](@VFECHA_DESDE,@VFECHA_HASTA) as decimal(10, 2)))+ '</div>'
				END													AS '<div class="w3-center w3-muhle-text-11">Indice Disp.</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					CASE WHEN ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) = 0 THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2)))+ '</div>'
					END
				ELSE
					CASE WHEN ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) = 0 THEN 
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2)))+ '</div>'
					END 
				END													AS '<div class="w3-center w3-muhle-text-11">Indice Comp.</div>',
				CASE WHEN (@VMES = 'TODOS') THEN
					CASE WHEN [dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO) = 0 THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_OCUP_ANUAL] (EMP.ID_EMPLEADO, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISP_ANUAL] (EMP.ID_EMPLEADO, @VANO),0) as decimal(10, 2)))+ '</div>'
					END
				ELSE
					CASE WHEN [dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO) = 0 THEN
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,0)+ '</div>'
					ELSE
						'<div class="w3-center w3-muhle-text-11">'+ CONVERT(VARCHAR,cast([dbo].[FN_GET_DIAS_OCUPADOS] (EMP.ID_EMPLEADO, @VMES, @VANO) * 100 / ISNULL([dbo].[FN_GET_DIAS_DISPONIBLES] (EMP.ID_EMPLEADO, @VMES, @VANO),0) as decimal(10, 2)))+ '</div>'
					END
				END													AS '<div class="w3-center w3-muhle-text-11">% Ocupacion</div>'
		FROM	LK_EMPLEADOS EMP
		WHERE	EMP.PERFIL_EMP = 'CONSULTOR'
		AND		ISNULL(EMP.EVENTUAL,'NO') = 'NO'
		AND		((EMP.STATUS_EMP = '1') OR (CASE WHEN (@VMES = 'TODOS') THEN
												[dbo].[FN_GET_DIAS_COMP_ANUAL] (EMP.ID_EMPLEADO, @VANO)
											ELSE
												[dbo].[FN_GET_DIAS_COMPROMISO] (EMP.ID_EMPLEADO, @VMES, @VANO) 
											END > 0))
		AND		CONVERT(VARCHAR,CONVERT(INT,DATEPART(YYYY, EMP.FECHA_ALTA))) + CONVERT(VARCHAR,FORMAT(CONVERT(INT,DATEPART(MM, EMP.FECHA_ALTA)),'00')) <= CONVERT(VARCHAR,CONVERT(INT,@VANO)) + CONVERT(VARCHAR,FORMAT(CONVERT(INT,@VMES),'00')) 
		ORDER BY EMP.APELLIDO_EMPLEADO + ', ' + EMP.NOMBRE_EMPLEADO 
	END
END
