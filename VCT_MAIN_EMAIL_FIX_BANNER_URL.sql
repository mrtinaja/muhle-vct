USE [MuhlePROD]
GO

/* Corrige de una sola vez TODOS los templates que todavia tengan guardada la
   ruta relativa del banner (../img/...), que un cliente de correo no puede
   resolver. Esto es un fix de datos historicos, unico: de aca en mas, el
   editor (vct-email-template-designer.js, insertServerBanner) ya guarda
   siempre la URL absoluta al insertar un banner nuevo, asi que esto no
   deberia volver a hacer falta. */

-- Preview: que templates se van a tocar y como queda el HTML
SELECT
    ID, CODIGO, DESCRIPCION,
    REPLACE(HTML_CONTENIDO, 'src="../img/', 'src="https://vocaturo.desa.interdev.online/img/') AS HTML_DESPUES
FROM dbo.VCT_PRM_EMAIL_TEMPLATES
WHERE HTML_CONTENIDO LIKE '%src="../img/%';

-- Aplica la correccion a todos los templates afectados
UPDATE dbo.VCT_PRM_EMAIL_TEMPLATES
SET HTML_CONTENIDO = REPLACE(HTML_CONTENIDO, 'src="../img/', 'src="https://vocaturo.desa.interdev.online/img/'),
    FECHA_UPD = GETDATE(),
    USUARIO_UPD = SUSER_SNAME()
WHERE HTML_CONTENIDO LIKE '%src="../img/%';
