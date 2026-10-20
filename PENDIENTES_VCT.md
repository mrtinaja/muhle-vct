# VCT · Proyecto V360 — pendientes de definición, relevamiento y construcción

Actualizado: 20/10/2026. Base: documento funcional (sección 15), minuta de la reunión y lo construido hasta PASO5_1.

## 1. Decisiones funcionales (las define la consultora / Esteban)

| # | Tema | Qué hay que decidir | Propuesta para arrancar |
|---|------|---------------------|-------------------------|
| 1 | Proyectos con varias normas | ¿Un plan integrado o un plan por norma? | Integrado (como el Excel de BORG): ítems comunes una vez, con la norma marcada |
| 2 | Planes base 14001, 45001 e integrado | Contenido (capítulos, ítems, subítems) | Cargar desde el Excel RE-PP-007 de BORG |
| 3 | Plan de mantenimiento (variante B) | Contenido y en qué se diferencia del de implementación | — |
| 4 | Auditoría y capacitación | ¿Tienen plan propio? Formato, ítems, quién lo carga | Plan corto por instancia: preparación, ejecución, informe, cierre |
| 5 | Hitos | ¿Solo fecha y estado, o generan una auditoría / servicio? | Solo fecha y estado (sin acciones obligatorias) |
| 6 | Próxima acción | Qué resultados obligan a cargar una próxima acción | Reprogramada y Observada → sí; Completada, Aprobada, Rechazada, No aplica, Cancelada → no |
| 7 | Mail al cargar una acción | ¿Marcado por defecto? ¿Se manda también si el responsable es el cliente? ¿Y si es "Otro"? | Marcado; equipo y cliente sí; "Otro" no (no tiene mail) |
| 8 | Acciones vencidas | ¿Aviso diario por mail o solo la campanita? ¿A quién? | Mail diario al responsable con copia al analista |
| 9 | Seguimiento quincenal | ¿Acción automática cada 15 días mientras está En curso? ¿Para quién? | Sí, al analista |
| 10 | Horas | La suma de horas de los servicios, ¿igual o ≤ al total contratado? | ≤ con aviso |
| 11 | Perfil Cliente | Qué ve en su inicio: pendientes, riesgos, avance, próximas visitas | Pendientes del cliente + avance + próxima visita |
| 12 | Permisos finos | Quién edita el plan, las acciones del proyecto y los riesgos; qué ve gerencia | Hoy: equipo del proyecto + analista + EDIT de PROYECTOS |
| 13 | Resumen y KPIs | Rediseño de la tarjeta Resumen y del KPI del plan | — |
| 14 | Historial | Migración de proyectos en curso desde enero: cuáles y con qué datos | — |

## 2. Relevamiento técnico (consultas de solo lectura o datos que tenés vos)

| # | Qué | Para qué |
|---|-----|----------|
| 1 | Plantillas actuales de VCT_PRM_EMAIL_TEMPLATES (código, destino, estado) | Confirmar códigos y cuáles faltan |
| 2 | ¿Hay SQL Server Agent disponible para jobs? | Vencidas diarias y seguimiento quincenal |
| 3 | Mail del cliente: ¿VCT_EMAILS del cliente o del contacto del proyecto? | Mails a cliente |
| 4 | Agenda del compañero (horas programadas y ejecutadas) | Avance de horas y pestaña Agenda |
| 5 | Ramas de Martín sin mergear (calendario-unificado-base, sync-datagrid-v30) | Datagrid v30 del servidor vs v1 del repo |
| 6 | Acentos en textos de SP (tema general) | Prolijidad |
| 7 | Las 4 acciones de tipo Aviso sin subtipo (salen en PASO5_1) | Asignarles el subtipo con un UPDATE puntual |

## 3. Plantillas de mail (VCT_PRM_EMAIL_TEMPLATES)

Variables que resuelve VCT_MAIN_SEND_EMAIL: {{PROYECTO}} {{CLIENTE}} {{CONSULTOR}} {{ANALISTA}} {{NOMBRE}} {{APELLIDO}} {{EMAIL}} {{AGENDA}} {{FECHA}} {{HORA}} {{MES}} {{ANIO}}.
El resto las reemplaza el SP que envía. DESTINO_TIPO admite CONSULTOR, ANALISTA, CLIENTE, LIBRE.

| Código | Cuándo se envía | Destino | Variables extra | Estado |
|--------|-----------------|---------|-----------------|--------|
| PROYECTO_ANALISTA_ASIGNADO | Alta del proyecto | ANALISTA | — | Existe (alta) |
| PROYECTO_CONSULTOR_ASIGNADO | Asignación del consultor líder | CONSULTOR | — | Existe |
| (asigna analista, ID 10 en la regla PROY_ANALISTA_ASIGNAR_CONSULTORES) | Pedido al analista de asignar consultores | ANALISTA | — | Existe; confirmar código |
| PROYECTO_INICIO_CONSULTOR | Iniciar proyecto (Lanzamiento → Iniciar, con "Enviar mail") | lo cargado en el modal | {{CODIGO_PROYECTO}} {{NORMAS}} {{EQUIPO}} {{FECHA_PLAN}} | **Falta crear** (el SP ya lo usa) |
| PLAN_CAMBIO_FECHA | El consultor cambia inicio / fin de un ítem del plan | ANALISTA | {{CODIGO_PROYECTO}} {{ITEM}} {{FECHA_ANTERIOR}} {{FECHA_NUEVA}} {{CONSULTOR}} | **Falta crear** + conectar en el SP |
| ACCION_ASIGNADA | Genérico: cualquier acción manual (proyecto o plan) con "Enviar mail" | el responsable de la acción (lo resuelve el SP) | {{CODIGO_PROYECTO}} {{TIPO}} {{SUBTIPO}} {{DETALLE}} {{VENCE}} {{PRIORIDAD}} {{RESPONSABLE}} {{CARGADO_POR}} {{ITEM}} | **Falta crear** + checkbox en el modal |
| ACCION_VENCIDA | Resumen diario de acciones vencidas | responsable, CC analista | {{CODIGO_PROYECTO}} {{LISTA_ACCIONES}} | Según decisión 8 (necesita job) |
| PLAN_CARGA_FINALIZADA | El consultor finaliza la carga del plan | ANALISTA | {{CODIGO_PROYECTO}} {{CONSULTOR}} | Opcional |
| SEGUIMIENTO_QUINCENAL | Recordatorio de seguimiento | ANALISTA | {{CODIGO_PROYECTO}} {{AVANCE}} | Según decisión 9 |

## 4. Construcción pendiente (ya definido o dependiente de lo anterior)

| # | Qué | Depende de |
|---|-----|------------|
| 1 | Mail genérico ACCION_ASIGNADA + checkbox "Enviar mail al responsable" en los modales de acción | Plantilla + decisión 7 |
| 2 | Mail PLAN_CAMBIO_FECHA (hoy solo se genera la acción de aviso) | Plantilla |
| 3 | Próxima acción encadenada | Decisión 6 |
| 4 | Plan de auditoría y de capacitación | Decisión 4 |
| 5 | Planes base de otras normas / integrado | Decisiones 1 y 2 |
| 6 | Pestaña Agenda (visitas y horas) | Relevamiento 4 |
| 7 | Administración: honorarios, viáticos, rentabilidad | — |
| 8 | Documentos (adjuntos, recrear VCT_PROYECTOS_DOCUMENTOS) | — |
| 9 | Gráficos de la sección 12 del documento | — |
| 10 | Resumen y KPIs | Decisión 13 |
| 11 | Validación con oficina y luego con 1-2 consultores | Etapas 1-6 |
| 12 | Migración de proyectos en curso | Decisión 14 |
