 
CREATE   PROCEDURE dbo.VCT_NOTIF_RENDER
(
    @IUNIDAD VARCHAR(100),
    @IAGENTE VARCHAR(100),
    @LINK    BIT,
    @HTML    VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @U VARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@IAGENTE,'')))), @NL INT = 0, @ITEMS VARCHAR(MAX) = '';
    SET @HTML = '';
    SELECT @NL = COUNT(*) FROM dbo.VCT_NOTIFICACIONES WHERE USUARIO = @U AND LEIDA = 0;
 
    SELECT @ITEMS = ISNULL((
        SELECT TOP 20
            '<li class="vct-ini-notif' + CASE WHEN N.LEIDA = 0 THEN ' is-unread' ELSE '' END + '">'
          + '<span class="vct-ini-notif-icon is-' + LOWER(N.TIPO) + '" data-vct-icon="'
          +   CASE N.TIPO WHEN 'AVISO' THEN 'clock-3' WHEN 'VENCIDA' THEN 'list-checks' WHEN 'VISITA' THEN 'calendar'
                          WHEN 'PENDIENTE' THEN 'user-check' WHEN 'HORAS' THEN 'chart-bar' ELSE 'clipboard-check' END + '"></span>'
          + '<span class="vct-ini-notif-main">'
          +   '<span class="vct-ini-notif-title">'
          +     CASE WHEN @LINK = 1 AND N.ID_PROYECTO IS NOT NULL
                     THEN '<button type="button" class="vct-ini-link" data-vct-ini-proy="' + CONVERT(VARCHAR(20), N.ID_PROYECTO) + '" data-vct-ini-cli="' + CONVERT(VARCHAR(20), ISNULL(N.ID_CLIENTE,0)) + '">' + dbo.VCT_HTML_ESC(N.TITULO) + '</button>'
                     ELSE dbo.VCT_HTML_ESC(N.TITULO) END
          +   '</span>'
          +   CASE WHEN ISNULL(N.DETALLE,'') <> '' THEN '<span class="vct-ini-notif-meta">' + dbo.VCT_HTML_ESC(N.DETALLE) + '</span>' ELSE '' END
          +   '<span class="vct-ini-notif-date">'
          +     CASE WHEN DATEDIFF(MINUTE, N.FECHA, GETDATE()) < 60 THEN 'hace ' + CONVERT(VARCHAR(10), CASE WHEN DATEDIFF(MINUTE, N.FECHA, GETDATE()) < 1 THEN 1 ELSE DATEDIFF(MINUTE, N.FECHA, GETDATE()) END) + ' min'
                     WHEN DATEDIFF(HOUR, N.FECHA, GETDATE()) < 24 THEN 'hace ' + CONVERT(VARCHAR(10), DATEDIFF(HOUR, N.FECHA, GETDATE())) + ' h'
                     WHEN DATEDIFF(DAY, N.FECHA, GETDATE()) < 7 THEN 'hace ' + CONVERT(VARCHAR(10), DATEDIFF(DAY, N.FECHA, GETDATE())) + ' d'
                     ELSE CONVERT(VARCHAR(10), N.FECHA, 103) END
          +   '</span>'
          + '</span>'
          + '</li>'
        FROM dbo.VCT_NOTIFICACIONES N
        WHERE N.USUARIO = @U
        ORDER BY N.LEIDA, N.FECHA DESC, N.ID DESC
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), '');
 
    SET @HTML =
        '<div class="vct-ini-bell" data-vct-ini-bell>'
      + '<button type="button" class="vct-ini-bell-btn' + CASE WHEN @NL > 0 THEN ' has-unread' ELSE '' END + '" data-vct-ini-bell-toggle aria-expanded="false"'
      +   ' title="Notificaciones" aria-label="Notificaciones' + CASE WHEN @NL > 0 THEN ': ' + CONVERT(VARCHAR(10), @NL) + ' sin leer' ELSE '' END + '">'
      +   '<span data-vct-icon="bell"></span>'
      +   CASE WHEN @NL > 0 THEN '<span class="vct-ini-bell-badge">' + CASE WHEN @NL > 99 THEN '99+' ELSE CONVERT(VARCHAR(10), @NL) END + '</span>' ELSE '' END
      + '</button>'
      + '<div class="vct-ini-bell-panel" data-vct-ini-bell-panel hidden>'
      +   '<div class="vct-ini-bell-head"><b>Notificaciones</b>'
      +     CASE WHEN @NL > 0 THEN '<span class="vct-ini-bell-new" style="color:#b91c1c;font-size:12px;">' + CONVERT(VARCHAR(10), @NL) + ' nueva' + CASE WHEN @NL = 1 THEN '' ELSE 's' END + ' desde tu &uacute;ltima visita</span>'
            ELSE '<span class="vct-ini-bell-ok">Est&aacute;s al d&iacute;a</span>' END
      +   '</div>'
      +   CASE WHEN @ITEMS = '' THEN '<p class="vct-ini-bell-empty">Todav&iacute;a no ten&eacute;s notificaciones.</p>'
               ELSE '<ul class="vct-ini-bell-list">' + @ITEMS + '</ul>' END
      + '</div>'
      + '</div>';
    /* lo mostrado queda visto: en la proxima visita ya no aparece en rojo */
    UPDATE dbo.VCT_NOTIFICACIONES SET LEIDA = 1, FECHA_LEIDA = GETDATE() WHERE USUARIO = @U AND LEIDA = 0;
END
