# FASE 9 · P1 — web.config: compresión HTTP + caché de estáticos

> El `web.config` **no va al repo** (regla .gitignore: machineKey). Este archivo es sólo la **referencia** de qué pegar en el server. Lo aplica la persona.

## Qué cambia
Reemplazar el bloque `<system.webServer>` actual (líneas ~89-97) por este, que agrega **compresión** y **caché de estáticos** (todo lo demás queda igual):

```xml
<system.webServer>
    <validation validateIntegratedModeConfiguration="false" />
    <security>
        <requestFiltering>
            <requestLimits maxAllowedContentLength="104857600" />
        </requestFiltering>
    </security>
    <directoryBrowse enabled="true" />

    <!-- AUDITORIA F9 P1: compresion HTTP (gzip) -->
    <urlCompression doStaticCompression="true" doDynamicCompression="true" />

    <!-- AUDITORIA F9 P1: cache de estaticos (css/js/img). El ?v versionado invalida al cambiar -->
    <staticContent>
        <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00" />
    </staticContent>
</system.webServer>
```

## Notas / precauciones
1. **Features de IIS necesarias:**
   - *Static Content Compression* (para css/js) — casi siempre ya instalada.
   - *Dynamic Content Compression* (para el HTML que generan los SP) — puede **no** estar instalada.
   - Si al guardar el web.config aparece **HTTP 500.19** (config error), es por `doDynamicCompression="true"` sin la feature. Solución: instalar la feature **o** dejar `doDynamicCompression="false"` (lo importante para el peso son los estáticos, que van por `doStaticCompression`).
2. **Tipos MIME comprimidos:** por defecto IIS comprime `text/css` y `application/javascript` en la lista `staticTypes` de `applicationHost.config`. Si algún `.js` no se comprime, verificar que su MIME esté en esa lista (eso es server-level, no web.config).
3. **La caché aplica a estáticos, no a `.aspx`:** `<clientCache>` dentro de `<staticContent>` sólo afecta archivos físicos (css/js/img). Las páginas `.aspx` (dinámicas) **no** se cachean → no hay riesgo de pantalla pegada vieja.
4. **Caché + `?v`:** con cache-max-age largo, cada cambio de asset debe subir el `?v` (ya se hace). Conviene aplicar **P2 (unificar `?v`)** junto o antes, para no mezclar versiones. Ver [FASE8_plan.md](FASE8_plan.md).
5. `directoryBrowse` se dejó **igual** (no se toca seguridad en esta auditoría). Queda anotado para que el equipo evalúe ponerlo en `false`.

## Validación (después de aplicar)
En la consola del navegador, logueado en desa:
```js
fetch('/css/vct-main.css?probe='+Date.now(),{cache:'no-store'})
  .then(r => ({encoding:r.headers.get('content-encoding'), cache:r.headers.get('cache-control')}))
```
Esperado: `encoding: "gzip"` (antes `(none)`) y `cache: "max-age=31536000"` (antes `(none)`).
`vct-main.css` debería transferirse en ~60-70 KB en vez de 513 KB.
