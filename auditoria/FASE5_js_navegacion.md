# FASE 5 — Auditoría de JavaScript y navegación

> Recorrido en vivo (sesión logueada) por el host SPA `main/`. Lectura de consola + network por pantalla. Sin cambios de código (no se hallaron errores que corregir).

## Pantallas recorridas (AJAX / cambio de solapa)
Inicio, Acciones, Agenda del consultor, Proyectos, Configuración, Clientes, Consultores, Empleados. (Reportes/Proveedores/Agenda están bajo "Mas" — no se abrieron por link directo; pendiente pasada.)

## Resultado JS
- ✅ **Cero errores de consola** en todas las pantallas recorridas.
- ✅ **Cero promesas rechazadas**, cero "función no definida", cero referencias inexistentes.
- ✅ **Cero requests fallidos**: los ~92 requests de la sesión son **HTTP 200** (sin 404/500; sin 200-con-error visible).
- ⚠️ Único warning: `Google Maps JavaScript API loaded directly without loading=async` (performance, no error). → Fase 6.
- ✅ **Guards anti-doble-init OK** en los shared: `vct-datagrid.js` (`window.VCTDataGrid.version`, L47), `vct-notif.js` (`__vctNotifLoaded`), `vct-datepicker.js` (`__vctDatePickerLoaded` + version), `vct-export.js` (chequea `VCT.Toast`). → No hay doble ejecución ni listeners duplicados por recarga de script.

## 🟡 Hallazgo principal — versiones `?v` inconsistentes del mismo asset entre SPs
Cada SP de pantalla emite los assets compartidos con **su propia versión hardcodeada**, y la SPA no las unifica:
- `vct-datagrid.css` observado en **v=19, v=20, v=28, v=29** (según pantalla).
- `vct-datagrid.js` en **v=7 y v=11**.
- `vct-calendario.css` en **v=42 y v=44** (ya mitigado por el dedupe FASE2_C, pero el origen persiste).
- `vct-notif.js?v=2`, `vct-export.js?v=1` se **re-descargan en cada pantalla** (misma versión, pero re-pedido).

**Consecuencias:**
1. **CSS:** varias versiones del mismo archivo se apilan en el DOM → contaminación de cascada + descargas extra (cache miss por `?v` distinto).
2. **JS:** por el guard de carga, **gana la PRIMERA versión que se ejecuta** → el motor de grilla activo depende del **orden de navegación** (si el usuario entra primero a Clientes carga datagrid v=7; si entra a Configuración, v=11). Nondeterminístico. Hoy no rompe (no hubo errores), pero es frágil: si v=7 y v=11 divergen en lógica, algunas grillas corren con el motor viejo.

**Causa raíz:** los `?v` los pone cada SP a mano y los bumps no cubren todos los SP por igual. Es la versión generalizada del "doble `<link>`" (hallazgo C de Fase 2).

**Recomendación (Fase 6/8, no urgente, con OK):**
- Unificar el `?v` de cada asset compartido a **una sola versión global** (un bump que recorra TODOS los SP), o mejor
- Cargar los shared (`vct-datagrid`, `vct-datepicker`, `vct-export`, `vct-notif`, `vct-calendario`) **una sola vez desde el shell** (`VCT_GET_SHELL`) en vez de por pantalla. Esto elimina duplicados, cache misses y el no-determinismo.

## 🟡 Libs legacy cargadas globalmente (posible obsoleto → Fase 7)
En el shell se cargan todavía: `lib/DataTables/datatables.min.js` + `.css` y `lib/tableToExcel/tableToExcel.js`, pese a que **DataGrid (`vct-datagrid.js`) + `vct-export.js` ya los reemplazan**. Verificar si algún screen legacy aún los usa antes de quitarlos.

## Riesgos
- Bajo a nivel funcional hoy (sin errores). El riesgo real es de **consistencia/performance** por las versiones múltiples (arriba) → tratar en Fase 6/7/8.

## Estado / próximo paso
- Fase 5 completa (sin cambios de código; app sin errores JS).
- Pendiente menor: abrir Reportes/Proveedores/Agenda (bajo "Mas") y un form de alta a fondo en una pasada corta, si se quiere cobertura 100%.
- Próximo: **Fase 6 (performance)** — engancha directo con el hallazgo de versiones múltiples, el warning de Google Maps y la compresión HTTP del `web.config`.
