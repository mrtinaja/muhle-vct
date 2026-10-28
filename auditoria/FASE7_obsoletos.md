# FASE 7 — Inventario de JS/CSS sin uso (obsoletos)

> Sólo-lectura. **No se eliminó nada** (regla 4: no borrar JS/CSS automáticamente). Barrido: cada `css/`-`js/` contra todas las referencias del repo (SPs del dump + parches de raíz + `.aspx`). El dump `db/objetos/` puede estar viejo → la verdad la da la base viva: ver `DIAG_ASSETS_USO.sql`.

## A. Candidatos a huérfano (0 referencias en el repo)
| Archivo | Tamaño | Señal |
|---|---|---|
| `css/vct-mainMobile.css` | **505 KB** | sin refs; no lo carga ningún SP/aspx/JS |
| `js/vct-main_SI.js` | **184 KB** | backup (`_SI`); sin refs |
| `css/font-awesome.css` | 37 KB | sin refs (ver §B: FA duplicado) |
| `css/portal-vocaturoBK.css` | 24 KB | backup (`BK`); sin refs |
| `js/Main-Copy.js` | 18 KB | backup (`-Copy`); sin refs |
| `js/portal-vocaturo.js` | 15 KB | sin refs |
| `js/vct-plan-gantt-pdf.js` | 6 KB | sin refs |
| `css/vct-proyecto-agenda.css` | 5,5 KB | sin refs (pantalla Agenda de Proyecto no implementada) |
| `js/vct-proyecto-agenda.js` | 5,4 KB | sin refs (idem) |
| `css/vct-proyectos.css` | 2,9 KB | sin refs (pantalla Proyectos sin SP, cae en Inicio) |
| `css/vct_main_proyecto_v360_bkp.css` | 2,9 KB | backup (`_bkp`); sin refs |
| `js/vct-Agenda.js` | 22 KB | 0 refs en SPs/aspx (sólo aparece dentro de otro asset) |

> **Corrección (24/10):** `js/vct-loading-overlay.js` **NO es huérfano** — el `main/Default.aspx` real del server lo carga (`<script src="../js/vct-loading-overlay.js">`). La copia del repo estaba vieja. Confirma el caveat: validar siempre contra el server antes de borrar.

**Total candidato ≈ 834 KB** (dominado por `vct-mainMobile.css` + `vct-main_SI.js`).

Clasificación:
- **Backups evidentes** (bajo riesgo de quitar, previa confirmación viva): `vct-main_SI.js`, `Main-Copy.js`, `portal-vocaturoBK.css`, `vct_main_proyecto_v360_bkp.css`.
- **Features no cableadas** (dejar si se van a implementar): `vct-proyecto-agenda.*`, `vct-proyectos.css`, `vct-plan-gantt-pdf.js`, `vct-loading-overlay.js`. Confirmar con Esteban si son trabajo futuro.
- **A verificar en vivo** antes de tocar: `vct-mainMobile.css`, `portal-vocaturo.js`, `font-awesome.css`, `vct-Agenda.js`.

## B. Font Awesome duplicado (en uso, pero redundante)
- `font-awesome-5-all.css` (71 KB) → **8 refs** y `font-awesome.min.css` (53 KB) → **6 refs**: **dos versiones distintas de FA se cargan** según la pantalla. `font-awesome.css` (37 KB) → 0 refs (huérfano, §A).
- **Además (24/10, del Default.aspx real):** el head del shell carga FA **por CDN** (`https://use.fontawesome.com/releases/v5.15.3/css/all.css`) **y** la copia **local** `font-awesome-5-all.css` a la vez → misma versión bajada dos veces (una externa, una local). Dejar sólo una (preferible la local, por CSP/offline).
- Riesgo: peso doble + posibles iconos inconsistentes entre pantallas.
- **Recomendación (F8/F9, con OK):** unificar a **una sola** versión de FA en todas las pantallas (o, mejor aún, cargarla desde el shell). No urgente; verificar que los iconos usados existan en la versión elegida antes de consolidar.

## C. Componentes legacy — EN USO, NO borrar
`vct-Select.js`, `vct-Table.js`, `vct-Tabs.js`, `vct-Core.js` los cargan los **SPs legacy con prefijo `M_*` / `M_CONFIG_*`** (la plataforma vieja, anterior a `VCT_MAIN_*`). Siguen vivos → **no se tocan** mientras esas pantallas existan.
- Observación: conviven con los nuevos (`vct-main.js`, `vct-datagrid.js`). La migración de las pantallas `M_*` → `VCT_MAIN_*` haría obsoletos estos legacy, pero eso es **trabajo de producto**, no de esta auditoría.

## D. Código muerto *dentro* de archivos vivos (no es archivo, es limpieza intra-archivo)
De fases previas, para limpieza controlada (F9, con OK):
- `css/vct-calendario.css`: ~9 capas en conflicto para el marcador de "hoy" (Fase 2 §A) + `.vct-cal-tip-service` wrapper viejo del tooltip (Fase 3). Inofensivo pero frágil → consolidar en un bloque.

## E. Cómo confirmar antes de eliminar (entregable para la persona)
`DIAG_ASSETS_USO.sql` (sólo-lectura): cuenta en cuántos objetos de la **base viva** se referencia cada candidato. `objetos_que_lo_usan = 0` + no estar en ningún `.aspx`/`.master` del server = seguro para quitar.
> Nota: estos archivos también están en el **server** (los bajó `pull_assets.ps1`). Borrarlos del repo no los saca del server; la limpieza del server la decide el equipo.

## Riesgos
- Bajo si se respeta el flujo: confirmar en vivo (DIAG) → quitar primero los backups evidentes → features no cableadas sólo si se descartan. Nunca borrado automático (regla 4).

## Estado / próximo paso
- Fase 7 completa (inventario; sin eliminar nada). Entregable: `DIAG_ASSETS_USO.sql`.
- Próximo: **Fase 8** — plan de corrección consolidado (prioriza compresión/caché de F6, unificación de `?v`, FA único, limpieza de huérfanos y de código muerto), con riesgos y orden de ejecución. La implementación (Fase 9) requiere tu OK explícito.
