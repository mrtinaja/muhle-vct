# FASE 2 — Auditoría visual de calendarios

> Sólo-lectura + 1 fix quirúrgico de bajo riesgo (ver §F). Responsive fuera de alcance.
> Previo: se resolvió la divergencia repo↔servidor (`tools/pull_assets.ps1`, commit e5cb405) → el repo ya refleja el CSS/JS desplegado (vct-calendario.css 119 KB, diseño `--cal-rose-line/--cal-bord`).

## Calendarios auditados
Acciones · Agenda general (feriados) · Agenda del consultor · Agenda consultor en V360 · (Agenda de Proyecto 360 = motor aparte `[data-vct-pv]`, se respeta).
Todos los primeros comparten `vct-calendario.js` + capa común `.vct-cal-c`.

## Hallazgos

### A. 🔴 CSS sobre-apilado para el marcador de "HOY" (causa raíz del bug)
En `css/vct-calendario.css` hay **~9 bloques distintos** que tocan el día actual, de distintas iteraciones:
- L343 `.vct-agenda-cell-today` (base) · L610 `…today{outline:2px …}` · L1777 `.vct-cal-c …today{box-shadow inset + border-color}`
- L1873-1892 (boceto C: `border:2px #66062D` + `outline:none` + número bordó plano)
- L1957-1964 (diseño nuevo: `td…today{border:2px var(--cal-bord)}`)
- L2068 (`td.vct-agenda-cell:not(empty){border:1px var(--cal-rose-line)!important}`)
- L2096-2097 (`td…today{border:2px #66062D}` + número **relleno** bordó)
- **~pos 113057** (al final): regla **rosa de finde** `td.vct-agenda-cell:is(weekend,wknd):not(empty){border:1px var(--cal-rose-line)!important}`

**Mecánica del bug (Acciones):** la regla rosa final tiene **misma especificidad** (0,0,5,1) que la del borde bordó de hoy y está **más abajo** en el archivo → gana la rosa. Además el boceto C había puesto `outline:none !important`, matando el anillo de respaldo. Resultado: hoy con **borde rosa 1px** en vez de bordó.
Evidencia (vivo, Acciones): `borderTopColor=#EFE3E9`; ni un `border` inline `!important` lo cambiaba (lo pisa la regla rosa); `outline:2px #66062D` sí se aplica.

### B. ✅ "Hoy" clasificado como finde — FALSO POSITIVO (resuelto 2026-10-24)
La nota original ("hoy jueves 22 marcado como finde") fue un error de medición: la inspección de clases se hizo el **2026-10-24 (sábado, getDay=6)**, no el 22. Por lo tanto `vct-agenda-cell-weekend` en la celda de hoy es **correcto** — ese día es realmente fin de semana. **No hay bug de cálculo de día.**
Implicancia real: cuando hoy cae en sábado/domingo, la celda toma el estilo de finde (rosa/punteado) y el marcador de hoy debe seguir visible → lo garantiza `FIX_AUDIT_HOY` (outline bordó, independiente del borde). Nada más que hacer acá.

### C. 🟡 Doble `<link>` del mismo CSS
El host principal carga `vct-calendario.css` **dos veces** (`?v=42` y `?v=44`) → es el mismo archivo físico (el `?v` es cache-buster), pero duplica reglas y ensucia la cascada. Origen: dos SP distintos (shell + pantalla) emiten el `<link>` y el bump de versión no los dejó iguales. → normalizar a un único `<link>` y una sola versión (Fase 6/SP).

### D. ✅ Tema visual distinto por calendario — INTENCIONAL (confirmado 2026-10-24)
El calendario de **Acciones** se ve con **fondo/bordes rosados** (`--cal-rose-line`), mientras la Agenda del consultor y la del V360 se ven **blancas**. **Confirmado por el usuario: es intencional — NO tocar.** Se conserva como diferencia de diseño deliberada.

### E. ✅ Consistencia que SÍ está bien
Toolbar compacto `‹ Mes › · Mes/Semana/Día · ‹ Año ›`, leyenda "No editable", número de días (círculo gris / hoy destacado), tooltip-tarjeta con iconos de servicio — homogéneos en los calendarios `.vct-cal-c`. El mini-calendario lateral de la vista Semana (consultor y V360) se conserva.

## F. Fix aplicado (bajo riesgo, repo)
Agregado al final de `css/vct-calendario.css` (`FIX_AUDIT_HOY`): marcador de hoy vía **`outline:2px solid #66062D`** (con `outline-offset:-2px`). El outline **no participa de la cascada de `border`**, así que el anillo bordó de hoy queda garantizado en todos los `.vct-cal-c` sin pelear con la regla rosa. Validado en vivo en Acciones (`outline` computado = `2px solid rgb(102,6,45)`).
- Riesgo: mínimo (sólo agrega outline a `…-today`). No toca datos, JS ni SPs.
- Pendiente de deploy: subir el css al server + bump `?v` (V45).

## Riesgos / recomendaciones
- El CSS de calendario (120 KB, muchas capas en conflicto) es **frágil**: cada cambio nuevo corre riesgo de ser pisado por una capa posterior. Recomendación (fase posterior, con OK): **consolidar** las reglas de "hoy"/bordes en un solo bloque y quitar las capas muertas.
- Resolver el doble `<link>` y el posible mal cálculo de finde (B, C) antes de tocar más estilos.

## Estado y próximo paso
- **Estado:** Fase 2 hecha (hallazgos A–E) + fix F aplicado en repo (falta deploy).
- **Próximo paso (con tu OK):** (1) deployar el fix de hoy (css + bump V45); (2) Fase 3 (tooltips) o seguir puliendo la consistencia visual D. Decidís vos el orden.
