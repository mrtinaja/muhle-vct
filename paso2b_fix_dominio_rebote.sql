/* =============================================================================
   VOCATURO - FIX: revertir a un remitente dentro de muhle.io
   -----------------------------------------------------------------------------
   El intento anterior (martin.aja@squad.com.ar saliendo por mail.muhle.io)
   rebotó: cwp0.squad.com.ar rechazó el mensaje porque ese servidor SMTP no
   está autorizado a enviar "como" una dirección de squad.com.ar (falla de
   SPF/alineación de dominio).

   Fix: la dirección técnica (@email_address) vuelve a ser noreply@muhle.io
   -EXACTAMENTE la misma que ya usa MailCron y que se sabe que entrega bien-,
   porque mail.muhle.io SÍ está autorizado para ese dominio. Lo único que
   cambia es @display_name, que es lo que ve el destinatario en la bandeja
   de entrada: en vez de "[Notificacion Muhle]" va a decir "Vocaturo".
   ============================================================================= */

USE msdb;
GO

EXEC msdb.dbo.sysmail_update_account_sp
     @account_id      = 11,
     @email_address   = 'noreply@muhle.io',
     @display_name    = 'Vocaturo',
     @mailserver_name = 'mail.muhle.io',
     @port            = 25,
     @enable_ssl      = 0,
     @username        = NULL;
GO

-- Verificación
EXEC msdb.dbo.sysmail_help_account_sp @account_id = 11;
GO


/* =============================================================================
   PRUEBA
   ============================================================================= */

-- EXEC msdb.dbo.sp_send_dbmail
--      @profile_name = 'VocaturoProfile',
--      @recipients   = 'martin.aja@squad.com.ar',
--      @subject      = 'Prueba remitente Vocaturo',
--      @body         = 'Si ves este mail como "Vocaturo" y no rebota, funcionó.',
--      @body_format  = 'HTML';
