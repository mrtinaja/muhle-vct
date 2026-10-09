/* =============================================================================
   VOCATURO - CONFIGURAR LA CUENTA YA EXISTENTE (account_id = 11)
   -----------------------------------------------------------------------------
   VocaturoAccount (id 11) y VocaturoProfile (id 4) ya existen y están
   vinculados/habilitados (public). Solo faltaba configurar bien la cuenta:
   mismo servidor que usa MailCron (mail.muhle.io:25, sin SSL, sin auth),
   pero con remitente propio de Vocaturo.

   @username se deja en NULL a propósito: según confirmaste, ese relay no
   pide autenticación (igual que en la práctica funciona para MailCron).
   Si al probar el envío tira un error de autenticación SMTP, entonces sí
   hace falta la contraseña real de martin.aja@squad.com.ar (o de una
   casilla noreply propia) y volvemos a este mismo UPDATE agregándola.
   ============================================================================= */

USE msdb;
GO

EXEC msdb.dbo.sysmail_update_account_sp
     @account_id      = 11,
     @email_address   = 'martin.aja@squad.com.ar',
     @display_name    = 'Vocaturo',
     @mailserver_name = 'mail.muhle.io',
     @port            = 25,
     @enable_ssl      = 0,
     @username        = NULL;
GO

-- Verificación: confirmar que quedó como se espera
EXEC msdb.dbo.sysmail_help_account_sp @account_id = 11;
GO


/* =============================================================================
   PRUEBA - enviar un mail de test usando VocaturoProfile
   ============================================================================= */

-- EXEC msdb.dbo.sp_send_dbmail
--      @profile_name = 'VocaturoProfile',
--      @recipients   = 'martin.aja@squad.com.ar',
--      @subject      = 'Prueba remitente Vocaturo',
--      @body         = 'Si ves este mail como Vocaturo, funcionó.',
--      @body_format  = 'HTML';
