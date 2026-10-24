# FASE 3 — Normalización de tooltips

> No se reconstruyó la arquitectura del tooltip custom (`.vct-cal-tip` en `vct-calendario.js`) — funciona. Cambios quirúrgicos de bajo riesgo. Pendiente de deploy final (el usuario sube todo junto).

## Hallazgos y cambios

### A. Iconos de servicio con label de texto redundante ✅ corregido
- **Antes:** cada servicio se mostraba como `icono + nombre` (`.vct-cal-tip-service` → `<svg>` + `<span>Consultoría</span>`).
- **Cambio (`js/vct-calendario.js` build):** sólo el **icono**, con el nombre en `aria-label` + `role="img"` (accesibilidad preservada, dato conservado).
- **Distribución (`css/vct-calendario.css`, FASE3_TOOLTIP):** fila horizontal a la **izquierda**, `gap:6px`, **sin superposición**. 1 → izquierda; 2 → horizontal; 3 → entran holgados (≈22px c/u en tooltip de ~270px) → horizontal. La superposición "cartas apiladas" no hace falta (máx 3 servicios). Si hubiera más, hacen `flex-wrap`.
- Evidencia: tarjeta de muestra con 3 servicios renderizada en vivo → 3 iconos (maletín/clipboard/personas), horizontales, sin texto.

### B. Tooltip nativo duplicando el custom ✅ corregido
Se detectaron `title` nativos en celdas que **además** tienen tooltip custom o un badge visible (aparecían las dos tooltips):
- **Agenda del consultor** (`vct-agenda-cell` con nota): la celda tenía `title="nota"` **y** la nota interna tiene `data-tt` (custom). → **se quitó el `title` nativo** de la celda (queda sólo el custom).
- **Feriados / Agenda general** (celda con feriado): tenía `title="texto feriado"` **y** el badge/label visible con el mismo texto. → se reemplazó el `title` nativo por **`data-tt` (custom)**: una sola tooltip, estilada, que además muestra el **nombre completo** del feriado aunque el badge se trunque (`line-clamp:2`, p. ej. "Día del Resp…"). Así se evita el nativo y no se pierde info.
- Se conservó el `title` de botones reales (ej. botón editar día `data-vct-agc-editday`) — ahí el nativo es el esperado (control).

### C. Accesibilidad
- Iconos de servicio: `role="img"` + `aria-label` con el nombre.
- Celdas: el contenido (nota/feriado) sigue visible en el DOM para lectores de pantalla; el tooltip custom es sólo visual (`pointer-events:none`).

## Archivos tocados
- `js/vct-calendario.js`: build() de la tarjeta (iconos sin label); celda feriado (`title`→`data-tt`); celda agenda consultor (quita `title`).
- `css/vct-calendario.css`: bloque `FASE3_TOOLTIP` (fila de iconos horizontal, sin overlap).

## Riesgos
- Bajo. Sólo afecta el contenido del tooltip y el `title` de celdas (no datos, no SPs, no navegación). El motor del tooltip no se tocó.
- Nota: quedó CSS muerto `.vct-cal-tip-service` (wrapper viejo del icono+label) — inofensivo; se puede limpiar en la fase de obsoletos (F7).

## Estado / próximo paso
- Fase 3 completa (A, B, C) — pendiente de deploy final.
- Próximo (pedido por el usuario): **hallazgo C de Fase 2 — doble `<link>` de vct-calendario.css** que ensucia la cascada.
