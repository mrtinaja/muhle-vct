/* ========================================================================
   VCT MONEY  —  máscara/format de moneda (usado en Inicio y donde se pida).
   ------------------------------------------------------------------------
   IMPORTANTE: guarda de re-declaración. La plataforma re-inyecta los
   <script> en cada navegación SPA; con `const VctMoney = {...}` el segundo
   eval tira "Identifier 'VctMoney' has already been declared" (SyntaxError),
   que ademas aborta el eval de jQuery y puede romper el init de la pantalla.
   Por eso se asigna a window SOLO si no existe.
   ======================================================================== */
window.VctMoney = window.VctMoney || {
  format: function (value, currency) {
    currency = currency || 'ARS';
    if (value === null || value === undefined || value === '') {
      return '—';
    }
    var amount = Number(value);
    if (!isFinite(amount)) {
      return '—';
    }
    return new Intl.NumberFormat('es-AR', {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount);
  }
};
