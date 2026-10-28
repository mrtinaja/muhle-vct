# FASE 8 — Plan de corrección consolidado

> Consolida los hallazgos de F1–F7 en acciones priorizadas. **Nada se implementa en esta fase.** La ejecución es **Fase 9** y requiere OK explícito, ítem por ítem. Respeta las 10 reglas (no tocar lógica/SPs funcionales/contratos/permisos/seguridad; no borrado automático; responsive fuera de alcance; priorizar lo reutilizable).

## Prioridades (resumen)

| # | Acción | Origen | Impacto | Riesgo | Esfuerzo | Quién ejecuta |
|---|---|---|---|---|---|---|
| **P0** | Deploy pendiente de calendario (F2/F3 ya hechos y validados) | F2, F3 | Medio (cierra fixes visuales) | Bajo | Chico | Persona (subir assets + SP bump) |
| **P1** | Activar **compresión HTTP** (gzip/brotli) | F6-H1 | **Muy alto** (−85% texto) | Bajo | Chico | Persona (web.config/IIS) |
| **P1** | Agregar **headers de caché** a css/js/img | F6-H2 | Alto (cero re-descargas) | Bajo* | Chico | Persona (web.config) |
| **P1** | Google Maps `loading=async` | F5, F6-H5 | Bajo-medio | Bajo | Chico | Claude edita + persona sube |
| **P2** | **Unificar `?v`** de los shared (o cargarlos desde el shell) | F5, F6-H3/H4 | Alto (quita no-determinismo + cache miss) | Medio | Medio | Claude (bump global) + persona |
| **P2** | **Font Awesome único** | F7-B | Medio | Medio | Medio | Claude + persona, con verificación de iconos |
| **P3** | Quitar **huérfanos** (tras `DIAG_ASSETS_USO`) | F7-A | Medio (≈834 KB repo/server) | Bajo** | Chico | Persona (confirma y borra) |
| **P3** | Limpiar **código muerto intra-archivo** (capas "hoy", `.vct-cal-tip-service`) | F2, F3, F7-D | Bajo (mantenibilidad) | Medio | Medio | Claude + persona |
| **P4** | Documentar/unificar **Select vs FormSelect** | F4 | Bajo | Medio | Medio | A decidir |
| — | **Observación seguridad** `directoryBrowse=true` | F6 | — | — | — | Equipo (fuera de alcance) |

\* Riesgo de caché mitigado por el `?v` ya existente (y por P2). \** Riesgo bajo **sólo** tras confirmar en la base viva con el DIAG.

---

## Detalle por ítem

### P0 — Deploy pendiente de calendario
- **Qué:** subir `css/vct-calendario.css` + `js/vct-calendario.js` al server y correr el bump `FIX_CALENDARIO_BUMP_V45.sql` (ya creado).
- **Por qué:** los fixes de F2 (marcador "hoy" por `outline`, dedupe del doble `<link>`) y F3 (tooltips: iconos sin label, `title`→`data-tt`) están en el repo pero **no en el server** (evidencia: calendario vivo 119.698 B vs repo 120.892 B).
- **Riesgo:** bajo — sólo CSS/JS de calendario, ya validados en vivo.
- **Validación:** recargar pantalla completa; "hoy" con anillo bordó en todos los `.vct-cal-c`; tooltip con iconos; un solo `<link vct-calendario.css>` en el DOM.

### P1 — Compresión HTTP  ⭐ (mayor ganancia)
- **Qué:** activar compresión estática y dinámica de IIS para `text/css`, `application/javascript`, `text/html`.
- **Por qué:** medido en vivo `content-encoding: (none)`; `vct-main.css` viaja 513 KB crudos (gzip ≈ 60-70 KB).
- **Cómo:** `<httpCompression>` + `<urlCompression doStaticCompression="true" doDynamicCompression="true">` en web.config, o habilitarlo a nivel server (requiere feature de compresión de IIS instalada).
- **Riesgo:** bajo — no toca lógica/SPs/datos. **Nota:** el web.config **no va al repo** (regla .gitignore) → lo edita la persona en el server.
- **Validación:** `fetch` a un .css → `content-encoding: gzip` y tamaño transferido mucho menor.

### P1 — Headers de caché
- **Qué:** `<staticContent><clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00"/></staticContent>`.
- **Por qué:** hoy `cache-control: (none)` → re-descarga al navegar.
- **Riesgo:** bajo, **condicionado a P2** (cache fuerte sin bustear = asset viejo pegado; el `?v` ya busca, conviene unificarlo primero/junto).
- **Validación:** segunda carga de pantalla sirve css/js desde caché (304/from cache).

### P1 — Google Maps `loading=async`
- **Qué:** cargar el `<script>` de Google Maps con `loading=async` + callback.
- **Dónde:** el punto donde se inserta el script de Maps (ubicar el SP/JS exacto en F9).
- **Riesgo:** bajo — cambio acotado; verificar que el mapa siga inicializando por callback.

### P2 — Unificar `?v` de los shared
- **Qué:** una sola versión por asset compartido en **todos** los SP (bump global), o —preferible— cargar `vct-datagrid`, `vct-datepicker`, `vct-export`, `vct-notif`, `vct-calendario` **una vez desde el shell** (`VCT_GET_SIDEBAR`) y sacarlos de los SP de pantalla.
- **Por qué:** hoy el mismo asset se pide con `?v` distintos (datagrid v19/20/28/29, v7/11) → cache miss + la versión activa depende del orden de navegación (F5).
- **Riesgo:** medio — hay que verificar que ninguna pantalla dependa del orden de carga actual. Hacer **con pruebas por pantalla**.
- **Enfoque sugerido:** opción "bump global" primero (menos invasiva); mover al shell como paso 2 si se quiere.

### P2 — Font Awesome único
- **Qué:** consolidar a **una** versión de FA (hoy conviven `font-awesome-5-all.css` y `font-awesome.min.css`).
- **Riesgo:** medio — **verificar antes** que todos los iconos usados existan en la versión elegida (clases FA4 vs FA5 difieren).
- **Validación:** barrido visual de iconos por pantalla tras unificar.

### P3 — Huérfanos
- **Qué:** quitar los candidatos de F7-A, **en este orden**: (1) backups evidentes (`*_SI.js`, `*-Copy.js`, `*BK.css`, `*_bkp.css`); (2) el resto **sólo** si `DIAG_ASSETS_USO` da 0 en la base viva y no aparecen en `.aspx`/`.master` del server; (3) features no cableadas (`vct-proyecto-agenda.*`, etc.) **sólo** si Esteban confirma que no son trabajo futuro.
- **Riesgo:** bajo tras el DIAG. **No borrado automático** (regla 4): lo hace la persona, confirmado.
- **Nota:** también están en el server; la limpieza del server la decide el equipo.

### P3 — Código muerto intra-archivo
- **Qué:** consolidar en `vct-calendario.css` las ~9 capas en conflicto del marcador "hoy" en un solo bloque y quitar `.vct-cal-tip-service` (wrapper viejo del tooltip).
- **Riesgo:** medio — el CSS de calendario es frágil; hacer con pruebas visuales de los 4 calendarios y bump de versión.

### P4 — Select vs FormSelect
- **Qué:** documentar el criterio (cuándo cada uno) o unificar en un solo componente.
- **Riesgo:** medio — tocar un enhancer usado en muchas pantallas. No urgente; decisión de producto.

---

## Orden de ejecución recomendado (Fase 9)
1. **P0** (deploy calendario pendiente) — cierra lo ya hecho.
2. **P1 compresión** — ganancia inmediata, sin riesgo.
3. **P1 Google Maps async** — acotado.
4. **P2 unificar `?v`** — y recién después **P1 caché** (juntos, para no cachear versiones mezcladas).
5. **P2 Font Awesome único**.
6. **P3 huérfanos** (tras DIAG) y **código muerto**.
7. **P4** Select/FormSelect — cuando el equipo lo priorice.

## Lo que NO se toca (por reglas)
- Lógica de negocio, SPs funcionales, contratos front/back/SQL, permisos/seguridad, responsive. La observación de `directoryBrowse` queda **sólo anotada** para el equipo.

## Estado / próximo paso
- Fase 8 completa (plan; sin cambios de código).
- **Fase 9** (implementación controlada) **requiere tu OK explícito**, ítem por ítem. Sugerencia: arrancar por P0 + P1 (compresión), que son los de mejor relación impacto/riesgo. Decime con cuáles avanzamos.
