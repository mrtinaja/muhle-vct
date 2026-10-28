# FASE 1 — Inventario y diagnóstico (Vocaturo / Muhle)

> Auditoría sólo-lectura. No se modificó código. Responsive fuera de alcance.
> Fecha: 2026-10-24. Rama: `main`. El **servidor es la fuente**; el repo puede diferir del desplegado (ver §8).

## 1. Páginas (ASPX / HTML)

### ASPX productivas (una por “módulo host”)
- `Default.aspx` (entrada) · `login/Default.aspx` · `logout/Default.aspx`
- `main/Default.aspx` (**host SPA principal** — casi toda la app vive acá vía AJAX)
- `Dashboard.aspx` · `Configuration.aspx` · `admin/Default.aspx` · `admin/dashboard.aspx`
- `profile/Default.aspx` · `task/Default.aspx` · `GetServerData.aspx` (endpoint datos)
- `ErrorPage.aspx` · `WarningPage.aspx`

### ASPX duplicadas / backup (candidatas a revisar, NO borrar aún)
- `main/Default - Copy.aspx`, `… Copy (2)`, `… Copy (3)`, `… Copy(3)`, `… Copy (4)`
- `Default8.aspx`, `DefaultoriginalMuhle.aspx`, `profile/Default - Copy.aspx`
- `admin/dashboardBK2.aspx`, `admin/dashboardBK3.aspx`

### HTML sueltos (plantillas/mails/informes, no parte del SPA)
- `banner_*.html` (6: aviso, bienvenida, confirmacion, masthead blanco/bordo/gris, recordatorio)
- `informe_auditoria_reportes.html`, `informe_testeo_admin.html`, `estado_panel_admin.html`, `modelo_permisos_vocaturo.html`
- `_diag/*.html` y `design-bocetos/*.html` → artefactos de trabajo, NO productivos.

## 2. JavaScript (34 archivos en `js/`)

### Núcleo / framework (API común `window.VCT.*`)
- `vct-main.js` (+ `vct-Core.js`) → define la API: **Select, FormSelect, Datepicker, Tabs, Modal, Drawer, Toast, Tooltip, Icon, Badge, Buffer, Navigation, RowMenu, Sidebar, Command, Action, DomForm, Dynamic, FieldOptions, FormState, Config, Util, Validation, init**.
- `vct-datagrid.js` → motor de grillas (`data-vct-dg`). `vct-export.js` → exportación.
- `vct-loading-overlay.js`, `vct-notif.js`, `vct-modal.js`.

### Por pantalla (se bootean sobre su root y re-escanean por AJAX)
- `vct-calendario.js` → **UNIFICADO**: 2 motores (feriados `[data-vct-agenda-root]` + agenda consultor `[data-vct-agc-root]`) + capa común `CAL_C` (`.vct-cal-c`).
- `vct-acciones.js`, `vct-inicio.js`, `vct-reportes.js`, `vct-config-parametria.js`, `vct-resumen-proyectos.js`
- `vct-proyecto-alta.js`, `vct-proyecto-lanz.js`, `vct-proyecto-plan.js`, `vct-proyecto-visitas.js`, `vct-proyecto-v360.js`, `vct-proyecto-agenda.js`, `vct-proyectos.js`
- `vct-email-template-designer.js`, `vct-money.js`

### Legacy / duplicados / backup (candidatos — verificar referencias antes de nada)
- `vct-Agenda.js` + `vct-agenda-consultor.js` → **supuestamente reemplazados por `vct-calendario.js`**. Verificar que ningún SP los siga cargando.
- `Main.js`, `Main-Copy.js`, `vct-main_SI.js` → posibles duplicados del main.
- `vct-proyecto-nuevo.js` → ¿reemplazado por `vct-proyecto-alta.js`?
- `vct-Select.js`, `vct-Table.js`, `vct-Tabs.js`, `vct-Core.js` → ¿viven o están absorbidos en `vct-main.js`? (verificar carga real).
- `portal-vocaturo.js`, `profile.js`.

## 3. CSS (37 archivos en `css/`)
- Comunes: `vct-main.css`, `vct-shell.css`, `vct-datagrid.css`, `vct-datepicker.css`, `vct-modal.css`, `vct-notif.css`, `vct-calendario.css`.
- Por pantalla: `vct-acciones/inicio/reportes/config-parametria/resumen-proyectos/email-template-designer.css`, `vct-proyecto-*.css`.
- Legacy/duplicados: `vct-Agenda.css`, `vct-agenda-consultor.css` (vs `vct-calendario.css`); `vct-proyecto-nuevo.css`; `vct_main_proyecto_v360.css` vs `vct-proyecto-v360.css`; `portal-vocaturoBK.css`; `main.css`/`admin.css`/`w3.css`.
- Fuentes: `font-awesome.css`, `font-awesome.min.css`, `font-awesome-5-all.css` (**3 variantes de FA** — revisar cuál se usa).
- Backups de carpeta: `css_bkp/`, `fonts_bkp/`, `Base_BK/`.

## 4. Componentes reutilizables (confirmados por API `VCT.*`)
| Componente | Marcador DOM | Archivo |
|---|---|---|
| Select custom | `.vct-custom-select` / `VCT.Select` | vct-main.js (+ vct-Select.js legacy) |
| FormSelect (portal) | `.vct-form-select` | vct-main.js |
| DatePicker | `[data-vct-datepicker]` / `<input type=date>` en grilla | vct-datepicker.js |
| DataGrid | `[data-vct-dg]` | vct-datagrid.js (+ vct-export.js) |
| Tabs | `[data-vct-tabs]` | vct-main.js |
| Modal / Drawer | `.vct-modal` / `@LAYOUT=DRAWER` | vct-main.js + vct-modal.js |
| RowMenu | `[data-vctdg-rowmenu]` / `data-vct-command="row-context-menu"` | vct-main.js / vct-datagrid.js |
| Tooltip-tarjeta calendario | `[data-tt]` → `.vct-cal-tip` | vct-calendario.js |
| Icon (Lucide) | `[data-vct-icon]` | vct-main.js |
| Buffer / Navigation | `VCT.Buffer` / `window.goto` | vct-main.js |

## 5. Stored procedures que generan interfaz (`VCT_MAIN_*` + infra)
- **Shell/infra:** `VCT_GET_SHELL`, `VCT_GET_SIDEBAR`, `VCT_MAIN_RENDER_FORM`, `VCT_MAIN_RENDER_FORM_ACTION`, `VCT_MAIN_RENDER_ACTION`, `VCT_MAIN_GET_ACTIONS`, `VCT_PERFIL_PUEDE`.
- **Pantallas:** `VCT_MAIN_DASHBOARD`, `VCT_MAIN_CALENDARIO`, `VCT_MAIN_AGENDA_CONSULTOR`, `VCT_MAIN_ACCIONES`, `VCT_MAIN_CONSULTORES(_V360)`, `VCT_MAIN_EMPLEADOS`, `VCT_MAIN_PROVEEDORES`, `VCT_MAIN_PROYECTOS`, `VCT_MAIN_PROYECTO_V360`, `VCT_MAIN_REPORTES`, `VCT_MAIN_CONFIGURACION`, `VCT_MAIN_EMAIL_TEMPLATE_*`.
- **Proyecto (render/acción):** `VCT_PROYECTO_ALTA_*`, `VCT_PROYECTO_LANZ_*`, `VCT_PROYECTO_PLAN_*`, `VCT_PROYECTO_VISITA_*`, `VCT_PROYECTO_ASIGNAR_CONSULTOR`, `VCT_PROYECTO_AVANCE_SYNC`.
- **Datos calendario:** `VCT_FN_AGENDA_CONSULTOR_RANGO`, `VCT_FN_AGENDA_ACTIVIDADES_RANGO`, `VCT_FN_AGENDA_ACTS_JSON`, `VCT_FN_AGENDA_DIAS_JSON`, `VCT_CALENDAR_V360_RENDER`.
- **Notificaciones:** `VCT_NOTIF_GENERAR/RENDER/ACCION`. **Auditoría:** `VCT_LOG_AUDITORIA`.
- > El volcado local `db/objetos/` tiene sólo 3 archivos → **el inventario completo de SPs hay que sacarlo del servidor** (Fase 7 con consultas sólo-lectura).

## 6. Calendarios (mapa — detalle visual en Fase 2)
| Calendario | SP | Root / motor | Notas |
|---|---|---|---|
| Agenda general (feriados) | `VCT_MAIN_CALENDARIO` | `[data-vct-agenda-root]` (motor 1) | feriados fijo/movible |
| Acciones | `VCT_MAIN_ACCIONES` | `[data-vct-agenda-root]` + `.vct-acc-cal-unified` + eventos | tooltip de acciones |
| Agenda del consultor | `VCT_MAIN_AGENDA_CONSULTOR` | `[data-vct-agc-root]` (motor 2) | estados + actividades; semana con mini-mes |
| Agenda consultor en V360 | `VCT_MAIN_CONSULTORES_V360` | `[data-vct-agc-root].vct-agc-v360` | sólo lectura |
| Agenda de Proyecto 360 | `VCT_MAIN_PROYECTO_V360` | `[data-vct-pv]` / `vct-proyecto-agenda.js` | motor aparte (no CAL_C) |

## 7. Inicialización / destrucción / navegación SPA
- **Patrón de init:** cada `vct-*.js` tiene `boot()/scan()` + guard (`window.__vctXLoaded`) y re-escanea en `DOMContentLoaded`, en el evento **`vct:content-loaded`** y vía **`MutationObserver`** (para contenido inyectado por AJAX).
- **Navegación:** `window.goto(formId, guid)` (conserva `VCT_BUFFER`), `newTaskForContactWithParams(...)` (round-trip al server), `VCT.Navigation`, sidebar por `VCT_GET_SIDEBAR`.
- **Estado entre pantallas:** tabla `VCT_BUFFER` (TEXTO/IDSELEC/FLAG/ACTION) + `VCT.Buffer` en cliente.
- **Riesgo transversal:** re-inicializaciones y listeners duplicados al re-escanear tras AJAX (a verificar en Fase 5).

## 8. Divergencia repo ↔ servidor (hallazgo crítico temprano)
- El `css/vct-calendario.css` **desplegado (v=44)** contiene un diseño MÁS nuevo que el repo: reglas `.vct-cal-c .vct-agenda-table td.vct-agenda-cell…` con variables `--cal-rose-line` / `--cal-bord`, agregadas **directo en el servidor** (no commiteadas).
- Se cargan **dos `<link>` de `vct-calendario.css`** a la vez (`?v=42` y `?v=44`) en el main → doble hoja + posible pisado de reglas.
- **Consecuencia ya observada (Acciones):** el borde del día de hoy queda rosa 1px en vez de bordó 2px porque `td.vct-agenda-cell:not(empty){border:1px solid var(--cal-rose-line)!important}` le gana por especificidad al marcador de “hoy”. (Detalle en Fase 2.)
- **Acción recomendada antes de tocar CSS:** reconciliar repo ↔ servidor (`tools/pull_assets.ps1`) y resolver el doble `<link>`.

## Duplicaciones / candidatos tempranos (resumen, NO borrar)
- JS: `vct-Agenda.js`, `vct-agenda-consultor.js` (vs `vct-calendario.js`); `Main.js`/`Main-Copy.js`/`vct-main_SI.js`; `vct-proyecto-nuevo.js`.
- CSS: `vct-Agenda.css`, `vct-agenda-consultor.css`; `vct_main_proyecto_v360.css`; `portal-vocaturoBK.css`; 3× font-awesome.
- ASPX: varios `Default - Copy*`, `Default8`, `DefaultoriginalMuhle`, `dashboardBK2/3`.
- Carpetas backup: `css_bkp/`, `fonts_bkp/`, `Base_BK/`.

## Estado y próximo paso
- **Estado:** Fase 1 completa (inventario de archivos, componentes, SPs y navegación). No se modificó nada.
- **Pendiente de servidor:** inventario completo de SPs y referencias a assets (Fase 7, consultas sólo-lectura).
- **Próximo paso (requiere tu OK):** Fase 2 — auditoría visual de calendarios (empezando por el hallazgo §8 de Acciones) **o** la fase que priorices.
