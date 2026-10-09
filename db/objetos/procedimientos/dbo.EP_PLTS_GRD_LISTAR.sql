 
CREATE PROCEDURE [dbo].[EP_PLTS_GRD_LISTAR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100),
 @FORM_ID as varchar(100))
AS
 
--se fixeo error reportado x paula: Las empresas que desaparecieron desde "PLANTA" en el cronograma online: -- se saco el filtro x state by LDM
BEGIN	
 
	IF (@IAGENTE='admin') or (@IAGENTE='estrucplan')
		begin
			SELECT distinct '<i class="fas fa-circle w3-text-red w3-large"></i>&nbsp;Sin Asignar' as Estado, E.Empresa + ' - ' + P.Planta AS 'Empresa - Planta', 
				'<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')"><i class="fa fa-calendar-alt fa-fw"></i></a>&nbsp;&nbsp;<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''6E071597-4AA9-4387-9CBE-2DC9D5142625'')"><i class="fa fa-users"></i></a>' AS Opciones
			FROM EP_PLANTAS P
			INNER JOIN EP_CRONOGRAMA CRON ON CRON.IdPlanta= P.IdPlanta
			INNER JOIN EP_EMPRESAS E ON E.IdEmpresa = CRON.IdEmpresa
			WHERE P.IDPlanta NOT IN (
				SELECT pu.IDPlanta FROM EP_PLANTAS_USUARIOS PU)
			UNION
			SELECT distinct '<i class="fas fa-circle w3-text-green w3-large"></i>&nbsp;Asignados Clientes' as Estado, E.Empresa + ' - ' + P.Planta AS 'Empresa - Planta', 
				'<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')"><i class="fa fa-calendar-alt fa-fw"></i></a>&nbsp;&nbsp;<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''6E071597-4AA9-4387-9CBE-2DC9D5142625'')"><i class="fa fa-users"></i></a>' AS Opciones
			FROM EP_PLANTAS P
			INNER JOIN EP_CRONOGRAMA CRON ON CRON.IdPlanta= P.IdPlanta
			INNER JOIN EP_EMPRESAS E ON E.IdEmpresa = CRON.IdEmpresa
			WHERE P.IDPlanta IN (
				SELECT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU 
				INNER JOIN GroupsUserMembers GU ON GU.UserMemberId = PU.IdUsuario
				INNER JOIN Users U ON U.Id = GU.UserMemberId
				AND GroupId='EP_CLIENTES')
				--AND U.[State]>0)
			UNION
			SELECT distinct '<i class="fas fa-circle w3-text-yellow w3-large"></i>&nbsp;Asignados Responsables' as Estado, E.Empresa + ' - ' + P.Planta AS 'Empresa - Planta', 
				'<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')"><i class="fa fa-calendar-alt fa-fw"></i></a>&nbsp;&nbsp;<a href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''6E071597-4AA9-4387-9CBE-2DC9D5142625'')"><i class="fa fa-users"></i></a>' AS Opciones
			FROM EP_PLANTAS P
			INNER JOIN EP_CRONOGRAMA CRON ON CRON.IdPlanta= P.IdPlanta
			INNER JOIN EP_EMPRESAS E ON E.IdEmpresa = CRON.IdEmpresa
			WHERE P.IDPlanta IN (
				SELECT PU.IDPlanta FROM EP_PLANTAS_USUARIOS PU 
				INNER JOIN GroupsUserMembers GU ON GU.UserMemberId = PU.IdUsuario
				INNER JOIN Users U ON U.Id = GU.UserMemberId
				AND GroupId='EP_EJECUTIVOS')
				--AND U.[State]>0)
 
		end
	else
		begin
			SELECT distinct E.Empresa + ' - ' + P.Planta as 'Empresa - Planta', '<a title="Ver Cronograma" href="javascript:saveSelection(''ID_PLANTA_SEL'', '''+cast(P.IdPlanta as varchar)+''');goto('''+@FORM_ID+''',''BFF38257-9AFA-4450-B782-DA6CFEA23B5D'')"><i class="fa fa-calendar-alt fa-fw"></i></a>' AS Opciones
			FROM EP_PLANTAS P
			INNER JOIN EP_CRONOGRAMA CRON ON CRON.IdPlanta= P.IdPlanta
			INNER JOIN EP_EMPRESAS E ON E.IdEmpresa = CRON.IdEmpresa
			left JOIN EP_PLANTAS_USUARIOS PU ON PU.IdPlanta=P.IdPlanta
			where PU.IdUsuario = @IAGENTE
		end
 
END
