# FASE 4 — Auditoría de componentes reutilizables

> Diagnóstico sólo-lectura. Todo lo auditado **funciona**; no se cambió código. Se listan usos, duplicados y recomendaciones.

## DataGrid (`vct-datagrid.js`, `[data-vct-dg]`)
- **Adopción alta:** lo usan las grillas de Configuración (131 bloques), Reportes (40), Proyecto V360 (32+22), Consultores/Clientes/Empleados/Proveedores (14-15 c/u), Acciones, Consultor-servicios/normas, etc.
- Los `<table>` fuera de DataGrid son **mails/banners/templates/layout** (PROYECTO_ALTA/LANZ/PLAN/VISITAS instalación, VCT_MAIN_SEND_EMAIL, vocaturo_mail_FINAL, banners) → no son grillas de datos. **No hay grillas con implementación propia** compitiendo con el componente.
- **Funciones:** búsqueda, filtros (`select[data-vct-grid-filter]`), orden (`data-vct-sortable/-sort-type/-sort-value`), paginado (`data-vct-dg-page-size`, page-sizes), export Excel/PDF (`vct-export.js`), menú de fila (`data-vctdg-rowmenu`).
- **Export — alcance ✅ CORRECTO:** `exportSpec()` (vct-datagrid.js L722-724) arma las filas desde **`state.filtered`** (todas las filas que matchean búsqueda+filtros, ordenadas), **no** la página visible. Es decir, exporta el conjunto filtrado completo, no sólo lo visible. Cumple la directiva.
- Export de valores: respeta `data-vct-export-value` y `data-vct-export-ignore` (ej. columna Acciones no se exporta). `exportText()` usa texto limpio de celdas sólo-icono.

## Select — ⚠️ DOS componentes
Existen **dos** enhancers de select:
1. **`VCT.Select`** → `.vct-custom-select` (vct-main.js). **Modelo opt-out:** enhancea **todos** los `<select>` salvo los marcados `data-vct-native="true"` (L479). → Los selects quedan consistentes por defecto.
2. **`VCT.FormSelect`** → `.vct-form-select` (portal; menú en portal/overlay). Se usa en contextos de formulario/calendario (PV / Acciones usan `.vct-pv-cal-select` sobre FormSelect).
- **Nativos intencionales (`data-vct-native`):** mes/año de los calendarios (los maneja `vct-calendario.js`), ~5 archivos. Correcto (no deben volverse custom).
- **Recomendación (no urgente):** aclarar/consolidar el criterio **Select vs FormSelect** (¿cuándo cada uno?). Hoy conviven sin romper, pero son dos estilos/inits distintos de lo mismo → candidato a unificación controlada en fase posterior. No tocar ahora.

## DatePicker (`vct-datepicker.js`, `.vct-datepicker`)
- **Un solo componente.** Alcance: `<input type="date">` dentro de DataGrid (`[data-vct-dg]`) o Reportes (`[data-vct-report-root]`), más cualquiera con `data-vct-datepicker` (opt-in). 
- **Contrato preservado:** el `<input type="date">` nativo sigue siendo la fuente del valor enviado al server; el picker es sólo UI (misma técnica que el custom-select).
- No se encontraron `type="date"` crudos sin picker en los SPs (los forms usan field-type `DATE` vía `VCT_MAIN_RENDER_FORM` → picker). El modal de feriados tiene manejo especial (lo toca `vct-calendario.js`), ya contemplado.
- **Guard de doble carga** (L33): evita doble init cuando el picker viene del tag de pantalla **y** del motor. OK.

## Otros componentes (API `VCT.*` en vct-main.js)
Confirmados y reutilizados: Tabs, Modal, Drawer, Toast, Tooltip, Icon, Badge, Buffer, Navigation, RowMenu, Sidebar, Command, Action, DomForm, Dynamic, FieldOptions, FormState, Validation, Util. (Detalle de cada uno → si se quiere, en una pasada específica.)

## Hallazgos / riesgos
- 🟢 DataGrid y DatePicker: consistentes, sin implementaciones paralelas; export con alcance correcto.
- 🟡 **Dos componentes de select** (Select vs FormSelect): no es bug, pero es duplicación de propósito → documentar criterio o unificar (fase posterior, con OK).
- 🟡 Legacy en `js/`: `vct-Select.js`, `vct-Table.js`, `vct-Tabs.js` (anteriores a `vct-main.js`) — verificar en Fase 7 si todavía se cargan o son obsoletos.

## Estado / próximo paso
- Fase 4 completa (diagnóstico; sin cambios de código).
- Próximo: **Fase 5** (errores JS y navegación) o **Fase 7** (inventario de JS/CSS sin uso, que engancha con el punto de legacy). Vos elegís.
