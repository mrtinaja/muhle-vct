CREATE PROCEDURE [dbo].[EP_CRON_ACTUALIZAR] AS
BEGIN
 
	DECLARE @RTA  VARCHAR(4000),
	@CANT_USR INT;
 
	BEGIN TRY  
		--SELECT * from [EPCONSULTORA.DYNDNS.ORG].[dbMariana].[dbo].[0000-View-Cronograma]
 
		TRUNCATE TABLE EP_TMP_CRONOGRAMA;  
		
		--SELECT * FROM EP_TMP_CRONOGRAMA
 
		--SELECT * INTO EP_TMP_CRONOGRAMA FROM [EPCONSULTORA.DYNDNS.ORG].[DBMARIANA].[DBO].[0000-VIEW-CRONOGRAMA]
	
		INSERT INTO EP_TMP_CRONOGRAMA SELECT * FROM [190.106.145.48].[dbMariana].[dbo].[0000-View-Cronograma]
 
		INSERT INTO EP_EMPRESAS
			SELECT DISTINCT IDEMPRESA, RAZONSOCIAL FROM EP_TMP_CRONOGRAMA
			WHERE IDEMPRESA NOT IN (SELECT IDEMPRESA FROM EP_EMPRESAS);
 
		INSERT INTO EP_PLANTAS
			SELECT DISTINCT CODIGOEMPRESA, EXPR1 FROM EP_TMP_CRONOGRAMA
			WHERE CODIGOEMPRESA NOT IN (SELECT IDPLANTA FROM EP_PLANTAS);
 
		--SELECT * INTO EP_CRONOGRAMA_BAK FROM EP_CRONOGRAMA;
 
		TRUNCATE TABLE EP_CRONOGRAMA;
 
		INSERT INTO EP_CRONOGRAMA
			SELECT IDEMPRESA, CODIGOEMPRESA AS IDPLANTA, ANIO AS [AÑO], IDMES, IDTIPOTAREACRONOGRAMA, IDSUBTIPOTAREACRONOGRAMA, ESTADO AS IDESTADO, SUSPENDIDA, DESCRIPCION FROM EP_TMP_CRONOGRAMA
 
		SELECT @RTA=cast(count(*) as varchar) FROM EP_CRONOGRAMA;
		
		SELECT @CANT_USR=count(*) FROM EP_CRONOGRAMA CRON
		WHERE IDPLANTA NOT IN 
				(SELECT IDPLANTA FROM EP_PLANTAS_USUARIOS PU
					INNER JOIN GroupsUserMembers GU ON GU.UserMemberId = PU.IdUsuario
					AND GroupId='EP_CLIENTES')
 
		set @RTA = 'La actualizacion del cronograma es correcta: ' + @RTA + ' registros total. Total plantas sin asignar: ' + cast(@CANT_USR AS VARCHAR);
	
		exec msdb.dbo.sp_send_dbmail @profile_name = 'MailCron', 
				@recipients = 'webmaster@squad.com.ar; rvalentinuzzi@estrucplan.com.ar; pgomez@estrucplan.com.ar', 
				@subject = '[CRM Estrucplan] Actualizacion Cronograma OK', 
				@body = @RTA, 
				@body_format = 'text'
		
	END TRY  
	BEGIN CATCH  
		-- Execute error retrieval routine.  
 
		set  @RTA =  'Ocurrio un error en la actualizacion del cronograma -> ErrorNumber: ' +  isnull(cast(ERROR_NUMBER() AS varchar),'') + 'ErrorSeverity: ' + isnull(cast(ERROR_SEVERITY() AS varchar),'') +
			'ErrorState: ' + isnull(cast(ERROR_STATE() AS varchar),'') + ' - ErrorMessage: ' + isnull(cast(ERROR_MESSAGE() AS varchar),'') ;  
 
 
 
			exec msdb.dbo.sp_send_dbmail @profile_name = 'notif_muhle_final', 
				@recipients = 'webmaster@squad.com.ar; rvalentinuzzi@estrucplan.com.ar; pgomez@estrucplan.com.ar', 
				@subject = '[CRM Estrucplan] Error actualizacion Cronograma', 
				@body = @RTA, 
				@body_format = 'text'
 
 
 
	END CATCH;  
 
END
 
