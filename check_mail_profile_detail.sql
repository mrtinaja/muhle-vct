-- Cuenta(s) y datos SMTP asociados al perfil VocaturoProfile
SELECT
    p.profile_id,
    p.name            AS profile_name,
    p.description     AS profile_description,
    a.account_id,
    a.name            AS account_name,
    a.email_address    AS casilla,
    a.display_name,
    a.replyto_address,
    s.servername      AS smtp_server,
    s.port,
    s.username         AS smtp_usuario,
    s.use_default_credentials,
    s.enable_ssl
FROM msdb.dbo.sysmail_profile p
JOIN msdb.dbo.sysmail_profileaccount pa ON pa.profile_id = p.profile_id
JOIN msdb.dbo.sysmail_account a          ON a.account_id  = pa.account_id
JOIN msdb.dbo.sysmail_server s           ON s.account_id   = a.account_id
WHERE p.name = 'VocaturoProfile';
