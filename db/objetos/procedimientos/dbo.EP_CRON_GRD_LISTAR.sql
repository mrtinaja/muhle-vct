 
CREATE PROCEDURE [dbo].[EP_CRON_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID	AS VARCHAR(100))
 
AS
 
BEGIN	
 
	DECLARE @IEMPRESA VARCHAR(50)
 
	SELECT @IEMPRESA = ID_EMPRESA_SEL FROM TMT_CRON
	WHERE PAR_KEY = @IPKEYJOB
 
	IF (@IAGENTE='admin') or (@IAGENTE='estrucplan')
		begin
			IF ISNULL(@IEMPRESA,'') = ''
				BEGIN
					SELECT EMP.Empresa, P.Planta, count(*) as Tareas, '<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');saveSelection(''ID_EMPRESA_SEL'', '''+cast(EMP.IdEmpresa as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')">Ver</a>' AS Opciones
					FROM EP_CRONOGRAMA CRON
					INNER JOIN EP_EMPRESAS EMP ON EMP.IdEmpresa=CRON.IdEmpresa
					INNER JOIN EP_PLANTAS  P ON P.IdPlanta=CRON.IdPlanta
					INNER JOIN [EP_TIPO_TAREA_CRON] TIPO ON TIPO.ID=CRON.IdTipoTareaCronograma
					INNER JOIN [EP_SUBTIPO_TAREA_CRON] SUB ON SUB.IDSubtipoTareaCronograma=CRON.IDSubtipoTareaCronograma
					INNER JOIN [EP_MESES] M on M.IDMes=CRON.IdMes
					INNER JOIN [EP_ESTADOS] E on E.IdEstado=CRON.IdEstado
					group by EMP.Empresa, P.Planta, P.IdPlanta, EMP.IdEmpresa
 
				END
			ELSE
				BEGIN
					SELECT EMP.Empresa, P.Planta, count(*) as Tareas, '<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')">Ver</a>' AS Opciones
					FROM EP_CRONOGRAMA CRON
					INNER JOIN EP_EMPRESAS EMP ON EMP.IdEmpresa=CRON.IdEmpresa
					INNER JOIN EP_PLANTAS  P ON P.IdPlanta=CRON.IdPlanta
					INNER JOIN [EP_TIPO_TAREA_CRON] TIPO ON TIPO.ID=CRON.IdTipoTareaCronograma
					INNER JOIN [EP_SUBTIPO_TAREA_CRON] SUB ON SUB.IDSubtipoTareaCronograma=CRON.IDSubtipoTareaCronograma
					INNER JOIN [EP_MESES] M on M.IDMes=CRON.IdMes
					INNER JOIN [EP_ESTADOS] E on E.IdEstado=CRON.IdEstado
					where emp.idempresa=@IEMPRESA
					group by EMP.Empresa, P.Planta, P.IdPlanta
 
				END
		end
	else
		begin
			SELECT EMP.Empresa, P.Planta, count(*) as Tareas, '<a title="Ver Cronograma" href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');saveSelection(''ID_EMPRESA_SEL'', '''+cast(EMP.IdEmpresa as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')"><i class="fa fa-calendar-alt fa-fw"></i></a>' AS Opciones
			FROM EP_CRONOGRAMA CRON
			INNER JOIN EP_EMPRESAS EMP ON EMP.IdEmpresa=CRON.IdEmpresa
			INNER JOIN EP_PLANTAS  P ON P.IdPlanta=CRON.IdPlanta
			INNER JOIN [EP_TIPO_TAREA_CRON] TIPO ON TIPO.ID=CRON.IdTipoTareaCronograma
			INNER JOIN [EP_SUBTIPO_TAREA_CRON] SUB ON SUB.IDSubtipoTareaCronograma=CRON.IDSubtipoTareaCronograma
			INNER JOIN [EP_MESES] M on M.IDMes=CRON.IdMes
			INNER JOIN [EP_ESTADOS] E on E.IdEstado=CRON.IdEstado
			INNER JOIN [EP_PLANTAS_USUARIOS] PU ON PU.IdPlanta=CRON.IdPlanta
			where PU.IdUsuario=@IAGENTE
			group by EMP.Empresa, P.Planta, P.IdPlanta, EMP.IdEmpresa
		end
 
 
 
 
END
