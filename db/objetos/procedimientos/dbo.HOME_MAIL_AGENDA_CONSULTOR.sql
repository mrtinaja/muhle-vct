 
CREATE PROCEDURE [dbo].[HOME_MAIL_AGENDA_CONSULTOR]
(@IPKEYJOB	AS VARCHAR(100),
 @IAGENTE	AS VARCHAR(100))
AS
 
BEGIN
 
DECLARE @VMES			VARCHAR(50),
		@VANO			VARCHAR(50),
		@VCONSULTOR		VARCHAR(50),
		@VMes_Nombre	VARCHAR(100),
		@VCONSULTOR_DESC VARCHAR(300),
		@VEMAIL			VARCHAR(400),
		@VBODY			NVARCHAR(MAX),
		@Archivo		NVARCHAR(MAX),
        @Asunto			NVARCHAR(4000),
        @fileexists		INT,
        @cmd			NVARCHAR(1000);
 
	SELECT	@VMES = ISNULL(AGENDA_MES,''),
			@VANO = ISNULL(AGENDA_ANO,''),
			@VCONSULTOR = ISNULL(AGENDA_CONSULTOR,'')
	FROM	XAGENDA
	WHERE	PAR_KEY = @IPKEYJOB
 
	SELECT	DISTINCT TOP 1 @VMes_Nombre = MesNombre
	FROM	Calendar
	WHERE	CONVERT(VARCHAR,Mes) = @VMES
	AND		CONVERT(VARCHAR,Ano) = @VANO
	
	SELECT	@VCONSULTOR_DESC = APELLIDO_EMPLEADO + ', ' + NOMBRE_EMPLEADO,
			@VEMAIL = EMAIL_EMP
	FROM	LK_EMPLEADOS
	WHERE	ID_EMPLEADO = @VCONSULTOR
 
-- 1. Ruta del archivo generado
	SET @Archivo = 'C:\inetpub\wwwroot\muhle-vct\img\Agendas\' +
	'AgCons_' +  @VCONSULTOR + '_' + @VMES + @VANO + '_' + CONVERT(VARCHAR,GETDATE(),112) + '_' + @IAGENTE + '.png'
 
-- 2. Asunto dinámico
	SET @Asunto = 'Actualización de agenda - ' + @VMes_Nombre + ' ' + @VANO
 
-- 3. Cuerpo 
	SET @VBODY = N'<p>Estimado/a <b>'+@VCONSULTOR_DESC+'</b>,</p>
				   <p>Le informamos que su <b>agenda de trabajo ha sido actualizada</b>. Esta actualización corresponde al <b>'+CONVERT(VARCHAR,GETDATE(),103)+'</b>' + ' ' + '
					  e incluye las últimas modificaciones de actividades, asignaciones y días disponibles.</p>
				   <p>Le solicitamos revisar la información cargada para prever la organización de sus actividades.</p>
				   <p><b>Este mensaje es emitido automáticamente</b></p>
				   <p>Ante cualquier duda o inconsistencia detectada en la agenda, <b>por favor comuníquese con el área administrativa correspondiente</b>.</p>
				   <p>Saludos.</p>
				   <p><b>Área de Proyectos – Grupo Vocaturo</b></p>'
 
-- 4. Enviar correo
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name     = 'MailCron',
        @recipients       = @VEMAIL, -- o el mail del consultor
        @subject          = @Asunto,
        @body             = @VBODY,
        @body_format      = 'HTML',
        @file_attachments = @Archivo;
 
-- 5. Elimino el adjunto
	SET @cmd = 'DEL "' + @Archivo + '"';
    EXEC xp_cmdshell @cmd;
 
	UPDATE	XAGENDA
	SET		DESC_ERROR = 'Email Agenda Consultor, enviado correctamente.'
	WHERE	PAR_KEY = @IPKEYJOB
 
END
