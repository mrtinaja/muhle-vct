/* =============================================================================
   VOCATURO - CONFIGURACIÓN FINAL DE MAIL (remitente + banner)
   -----------------------------------------------------------------------------
   Estado: RESUELTO y probado en vocaturo.desa.interdev.online (Gmail, sin
   rebote, banner renderizando a tamaño real).

   Si hay que replicar esto en otro servidor (ej. producción), correr este
   script COMPLETO de punta a punta ahí. En desa esto YA está aplicado —
   no hace falta volver a correr los pasos 1 y 2, sólo sirve como referencia
   de lo que quedó configurado y como base para producción.
   ============================================================================= */

USE msdb;
GO

/* =============================================================================
   PASO 1 - Cuenta y perfil de Database Mail propios de Vocaturo
   -----------------------------------------------------------------------------
   No se tocó MailCron (perfil compartido con otros clientes). Se creó un
   perfil aparte, con una cuenta que reusa el MISMO servidor SMTP que ya
   funciona para MailCron (mail.muhle.io:25, sin SSL, sin autenticación),
   pero con remitente propio de Vocaturo.

   Importante: la dirección técnica es noreply@muhle.io (NO una de
   squad.com.ar) porque ese servidor sólo tiene autorizado el dominio
   muhle.io (SPF) — usar un dominio distinto ahí hace rebotar el mail.
   Lo único que cambia de cara al destinatario es el @display_name.
   ============================================================================= */

EXEC msdb.dbo.sysmail_add_account_sp
     @account_name    = 'VocaturoAccount',
     @description     = 'Cuenta de email institucional de Vocaturo (remitente propio)',
     @email_address   = 'noreply@muhle.io',
     @display_name    = 'Vocaturo',
     @mailserver_name = 'mail.muhle.io',
     @port            = 25,
     @enable_ssl      = 0;
GO

EXEC msdb.dbo.sysmail_add_profile_sp
     @profile_name = 'VocaturoProfile',
     @description  = 'Perfil de envío de notificaciones de Vocaturo';
GO

EXEC msdb.dbo.sysmail_add_profileaccount_sp
     @profile_name    = 'VocaturoProfile',
     @account_name    = 'VocaturoAccount',
     @sequence_number = 1;
GO

EXEC msdb.dbo.sysmail_add_principalprofile_sp
     @profile_name   = 'VocaturoProfile',
     @principal_name = 'public',
     @is_default     = 0;
GO


/* =============================================================================
   PASO 2 - Verificación
   ============================================================================= */

EXEC msdb.dbo.sysmail_help_account_sp;
GO
-- Debe verse: VocaturoAccount | noreply@muhle.io | Vocaturo | mail.muhle.io | 25

EXEC msdb.dbo.sysmail_help_profileaccount_sp @profile_name = 'VocaturoProfile';
GO


/* =============================================================================
   PASO 3 - Banner de encabezado
   -----------------------------------------------------------------------------
   Imagen ya subida (1200x130px, formato angosto tipo banner) en:
       https://vocaturo.desa.interdev.online/img/vct-mail.png

   Sin max-width a propósito: ocupa el 100% del ancho real del cuerpo del
   mail en vez de taparse en un ancho fijo. La imagen está en alta
   resolución (1200px) justamente para no pixelarse al estirarse en
   pantallas anchas.

   Mientras el SP que arma @VBODY no incorpore esto de forma nativa, se
   antepone con este bloque justo antes del EXEC msdb.dbo.sp_send_dbmail,
   en el punto real donde arman el envío:
   ============================================================================= */

-- SET @VBODY =
--     '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 18px 0;">' +
--         '<tr><td>' +
--             '<img src="https://vocaturo.desa.interdev.online/img/vct-mail.png" alt="Vocaturo" width="100%" style="width:100%;height:auto;display:block;border:0;" />' +
--         '</td></tr>' +
--     '</table>' +
--     @VBODY;


/* =============================================================================
   PASO 4 - Uso real (reemplaza el MailCron del EXEC de siempre)
   ============================================================================= */

-- EXEC msdb.dbo.sp_send_dbmail
--      @profile_name     = 'VocaturoProfile',
--      @recipients       = @VEMAIL,
--      @subject          = @Asunto,
--      @body             = @VBODY,   -- ya con el banner antepuesto (PASO 3)
--      @body_format      = 'HTML',
--      @file_attachments = @Archivo;


/* =============================================================================
   PASO 5 - Notificar a Esteban (De Marco) que el tema quedó resuelto
   -----------------------------------------------------------------------------
   Manda un mail real, con el banner arriba (así lo ve funcionando en el
   propio mail) y el resumen de qué se hizo + qué falta integrar de su lado.
   Descomentar el EXEC del final para enviarlo.
   ============================================================================= */

DECLARE @VBODY NVARCHAR(MAX);
DECLARE @CacheBuster VARCHAR(30) = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120),'-',''),':',''),' ','');

SET @VBODY = N'
<p>Esteban, les cuento que qued&oacute; resuelto el tema de los mails saliendo como &quot;Muhle&quot;/otro cliente. Probado en desa, en Gmail: no rebota y sale con remitente &quot;Vocaturo&quot;.</p>

<p><b>QU&Eacute; SE HIZO:</b></p>
<ol>
<li>Perfil y cuenta de Database Mail propios de Vocaturo, aparte de MailCron (no se toc&oacute; MailCron, que usan otros clientes en el mismo server): cuenta <b>VocaturoAccount</b>, perfil <b>VocaturoProfile</b>.</li>
<li>Remitente: la direcci&oacute;n t&eacute;cnica qued&oacute; en <b>noreply@muhle.io</b> (mismo server mail.muhle.io:25 que ya usa MailCron, sin auth), pero con display_name &quot;Vocaturo&quot; &rarr; es lo que ve el destinatario en la bandeja. Probamos primero con un remitente de squad.com.ar directo y rebot&oacute; por SPF (ese server no tiene autorizado ese dominio); por eso la direcci&oacute;n t&eacute;cnica queda en muhle.io y solo cambia el nombre visible.</li>
<li>Banner de encabezado: imagen subida en <a href="https://vocaturo.desa.interdev.online/img/vct-mail.png">vct-mail.png</a> (1200x130px) &mdash; es el que se ve arriba de este mail.</li>
</ol>

<p><b>C&Oacute;MO SE IMPLEMENTA (falta este paso final de tu lado):</b></p>
<ul>
<li>En cualquier <code>EXEC msdb.dbo.sp_send_dbmail</code> que arme el sistema, cambiar <code>@profile_name</code> de <code>&#39;MailCron&#39;</code> a <code>&#39;VocaturoProfile&#39;</code>. No hay que tocar nada m&aacute;s de ese EXEC (@recipients, @subject, @body, @body_format, @file_attachments quedan igual).</li>
<li>El banner por ahora lo estamos anteponiendo &quot;a mano&quot; al @VBODY justo antes de ese EXEC:</li>
</ul>

<pre style="background:#f3f6f9;border:1px solid #dbe3ec;border-radius:6px;padding:10px 12px;font-size:12px;overflow:auto;">SET @VBODY =
    &#39;&lt;table role=&quot;presentation&quot; width=&quot;100%&quot; cellpadding=&quot;0&quot; cellspacing=&quot;0&quot; border=&quot;0&quot; style=&quot;margin:0 0 18px 0;&quot;&gt;&#39; +
        &#39;&lt;tr&gt;&lt;td&gt;&#39; +
            &#39;&lt;img src=&quot;https://vocaturo.desa.interdev.online/img/vct-mail.png&quot; alt=&quot;Vocaturo&quot; width=&quot;100%&quot; style=&quot;width:100%;height:auto;display:block;border:0;&quot; /&gt;&#39; +
        &#39;&lt;/td&gt;&lt;/tr&gt;&#39; +
    &#39;&lt;/table&gt;&#39; +
    @VBODY;</pre>

<p>Lo ideal es que esto pase a integrarse en el/los SP que arman @VBODY de forma nativa (as&iacute; no depende de acordarse de pegarlo en cada punto de env&iacute;o). Te paso el script completo (vocaturo_mail_FINAL.sql) con todo documentado por si lo quer&eacute;s revisar o replicar en otro ambiente.</p>

<p>Cualquier duda me avis&aacute;s.</p>
';

SET @VBODY =
    N'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 18px 0;">' +
        N'<tr><td>' +
            N'<img src="https://vocaturo.desa.interdev.online/img/vct-mail.png?v=' + @CacheBuster + N'" ' +
                 N'alt="Vocaturo" width="100%" ' +
                 N'style="width:100%;height:auto;display:block;border:0;" />' +
        N'</td></tr>' +
    N'</table>' +
    @VBODY;

-- EXEC msdb.dbo.sp_send_dbmail
--      @profile_name = 'VocaturoProfile',
--      @recipients   = 'esteban.de.marco@squad.com.ar',
--      @subject      = 'Resuelto: remitente Vocaturo en los mails del sistema + banner',
--      @body         = @VBODY,
--      @body_format  = 'HTML';
