CREATE PROCEDURE [dbo].[EP_ADD_USUARIO]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @RTA AS VARCHAR(1000) OUTPUT)
AS
 
BEGIN
 
	DECLARE @NEW_ID VARCHAR(50),
	@NEW_NAME VARCHAR(100),
	@NEW_EMAIL VARCHAR(100),
	@NEW_PASS VARCHAR(100),
	@NEW_PASS_ENC VARCHAR(100),
	@ID_PLANTA_SEL VARCHAR(50),
	@ID_USER_SEL VARCHAR(30),
	@BODY_HTML VARCHAR(4000),
	@ACTION VARCHAR(50),
	@CANT_USR AS INT;
 
	SELECT @NEW_ID= NEW_ID, @NEW_EMAIL=NEW_EMAIL, @NEW_NAME=NEW_NAME, @NEW_PASS=NEW_PASSWORD,
		@ID_PLANTA_SEL = ID_PLANTA_SEL, @ACTION=[ACTION] FROM TMT_CRON WHERE PAR_KEY = @IPKEYJOB;
 
	select @CANT_USR=count(*) from Users where Id = @NEW_ID;
 
	IF @NEW_ID IS NULL OR @ACTION IN ('EDIT_USER', 'DEL_USER')
		BEGIN 
			SET @RTA='';
			RETURN
		END
 
	IF @CANT_USR > 0 
		BEGIN
			--actualizo el user seleccionado para luego agregar usuario a planta
			UPDATE TMT_CRON
			SET ID_USER_SEL = null
			WHERE PAR_KEY = @IPKEYJOB;
 
			SET @RTA='<br><p><b><font color="red">Ya existe ese usuario.</font></b></p>'
			RETURN
		END
	ELSE
		BEGIN
			UPDATE TMT_CRON 
			SET [ACTION]='ADD_USER'
			WHERE PAR_KEY= @IPKEYJOB;
	
 
			SET @NEW_PASS_ENC = CONVERT(VARCHAR(40), HashBytes('SHA1', upper(@NEW_ID)+@NEW_PASS), 2)
 
			INSERT INTO USERS VALUES (@NEW_ID, @NEW_NAME, 1, 0, @NEW_EMAIL, NULL, NULL,@NEW_PASS_ENC, NEWID(), GETDATE(),GETDATE())
 
			--lo agrego al grupo de EP_CLIENTES 
			INSERT INTO GROUPSUSERMEMBERS VALUES ('EP_CLIENTES', @NEW_ID, NEWID(), GETDATE() );
 
 
			--actualizo el user seleccionado para luego agregar usuario a planta
			UPDATE TMT_CRON
			SET ID_USER_SEL = @NEW_ID
			WHERE PAR_KEY = @IPKEYJOB;
	
			INSERT INTO EP_PLANTAS_USUARIOS (IDPlanta, IdUsuario) VALUES (CAST(@ID_PLANTA_SEL AS INT), @NEW_ID);
		
			SET @RTA='<br><p><b><font color="red">Usuario creado con exito y asignado a planta. Se ha enviado un correo al cliente con éxito.</font></b></p>'
 
			set @body_html ='<p>Estimado '+@NEW_NAME+':</p><br><p>Para acceder al cronograma online haga click <a target"_blank" href="https://clientes.estrucplan.com.ar">aqui</a>.</p><p>Usuario: <b>'+@NEW_ID+'</b></p><p>Clave: <b>'+@NEW_PASS+'</b></p><p>Cualquier duda o problema comuniquese con su responsable de planta.</p><p>Muchas Gracias!</p><p>Equipo Estrucplan</p>';
			exec msdb.dbo.sp_send_dbmail @profile_name = 'MailCron', 
				@recipients = @NEW_EMAIL,
				@blind_copy_recipients = 'leo.de.marco@squad.com.ar; pgomez@estrucplan.com.ar',
				@subject = '[Estrucplan] Acceso al Cronograma Online!', 
				@body = @body_html, 
				@body_format = 'html'
 
		END
 
END
