# FASE 6 — Auditoría de performance

> Diagnóstico sólo-lectura. Evidencia medida en vivo (desa) + tamaños de repo + web.config local. Responsive fuera de alcance. Las correcciones (web.config / server) las aplica la persona, con OK, en Fase 9.

## 🔴 Hallazgo 1 — Sin compresión HTTP (el mayor costo)
Medido en vivo (`fetch` a assets estáticos en `vocaturo.desa.interdev.online`):
| Asset | content-encoding | bytes servidos |
|---|---|---|
| `css/vct-main.css` | **(none)** | **513.265** |
| `css/vct-calendario.css` | (none) | 119.698 |
| `js/vct-datagrid.js` | (none) | 85.372 |

- El `web.config` **no tiene** `<httpCompression>` ni `<urlCompression>`, e IIS **no comprime** a nivel server (header confirma `(none)`).
- CSS/JS son texto → gzip/brotli los reduce **~80-90%**. `vct-main.css` pasaría de ~513 KB a ~60-70 KB.
- En una carga fría se transfieren **>1,5 MB** de CSS/JS sin comprimir (main 513 + mainMobile si cargara + calendario 120 + datagrid 85 + v360 css 99 + v360 js 119 + main.js 155 + …).
- **Recomendación (F9, bajo riesgo, altísimo impacto):** activar **compresión estática y dinámica** de IIS (gzip/brotli) para `text/css`, `application/javascript`, `text/html`. Server-level o `<httpCompression>`+`<urlCompression doStaticCompression="true" doDynamicCompression="true">`.

## 🔴 Hallazgo 2 — Sin headers de caché
- `cache-control: (none)` en los assets → el navegador **revalida/re-descarga** en cada navegación en vez de servir de caché.
- Combinado con el `?v` versionado (ya existe para cache-busting), lo ideal es **cachear fuerte + bustear por `?v`**.
- **Recomendación (F9):** `<staticContent><clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00"/></staticContent>` para css/js/img. Con el `?v` cada cambio sigue invalidando. Resultado: casi cero re-descargas entre pantallas.

## 🟡 Hallazgo 3 — Versiones `?v` inconsistentes (de Fase 5, impacto perf)
- Mismo asset pedido con `?v` distintos entre pantallas (`vct-datagrid.css` v19/20/28/29; `vct-datagrid.js` v7/11; `vct-calendario.css` v42/44) → **cache miss**: el navegador guarda y vuelve a bajar la "otra" versión del mismo archivo.
- **11 SPs** referencian `vct-datagrid` (grep sobre `db/objetos/`), cada uno con su `?v` hardcodeado.
- **Recomendación (F8/F9):** unificar el `?v` por asset (un bump que recorra TODOS los SP) o, mejor, **cargar los shared una sola vez desde el shell** (`VCT_GET_SIDEBAR` ya carga `vct-main.css`) en vez de re-emitirlos por pantalla.

## 🟡 Hallazgo 4 — Shared re-pedidos por pantalla
- `vct-notif.js`, `vct-export.js`, `vct-datepicker.*` y los grandes (`vct-datagrid`, `vct-calendario`) los emite **cada SP de pantalla**, no el shell → se re-piden al navegar (agravado por la falta de caché, H2).
- Los guards de JS evitan la doble ejecución (ver Fase 5), pero la **descarga** igual ocurre.
- **Recomendación:** mover los verdaderamente globales al shell; dejar en el SP sólo los específicos de esa pantalla.

## 🟡 Hallazgo 5 — Google Maps sin `loading=async`
- Warning en consola: `Google Maps JavaScript API loaded directly without loading=async`. Bloquea el parse mientras baja la lib.
- **Recomendación (F9):** cargar el script de Maps con `loading=async` + callback. Cambio acotado al punto donde se inserta el `<script>` de Maps.

## 🟡 Hallazgo 6 — Archivos pesados huérfanos (no se cargan, pero pesan en repo/server → Fase 7)
No referenciados en ningún SP/aspx/js:
- `css/vct-mainMobile.css` — **505 KB**
- `js/vct-main_SI.js` — **184 KB**
- `js/Main.js`, `js/Main-Copy.js`, (candidatos) `js/vct-main_SI.js`
No afectan la carga (no se linkean), pero son bulto y confunden. Confirmar y quitar en **Fase 7**.

## 🟢 Observación de seguridad (NO se toca — fuera de alcance de esta auditoría)
- `web.config`: `<directoryBrowse enabled="true" />` → listado de directorios del sitio habilitado (info-disclosure). Lo dejo anotado para que el equipo lo evalúe; **no lo modifico** (regla: no tocar seguridad).

## Nota de deploy pendiente
- `vct-calendario.css` en vivo = 119.698 bytes; en repo = 120.892 (con FASE2_C/FASE3). Confirma que los cambios de calendario **aún no están subidos** (se suben al final, con el bump V45).

## Riesgos de las correcciones propuestas
- Compresión + caché: **bajo**. Son settings de IIS/web.config, no tocan lógica, SPs ni datos. Riesgo de caché: si se cachea fuerte sin bustear, un asset viejo queda pegado → mitigado porque ya existe `?v` (y conviene unificarlo, H3).
- Mover shared al shell: **medio** — hay que verificar que ninguna pantalla dependa del orden de carga actual. Hacer con pruebas por pantalla (F9).

## Estado / próximo paso
- Fase 6 completa (diagnóstico; sin cambios de código). Evidencia viva de compresión/caché OFF.
- Próximo: **Fase 7** (inventario de JS/CSS sin uso — hereda los huérfanos de H6 y las libs legacy de F4/F5) o **Fase 8** (plan de corrección consolidado). Vos elegís.
