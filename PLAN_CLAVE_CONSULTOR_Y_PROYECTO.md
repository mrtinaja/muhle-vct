# Plan de los puntos "clave" (reunión 09/10 con Esteban)

Orden de ejecución una vez que vuelva la base. Todo nace de la charla del 09/10.
Lo marcado como **clave** por Esteban es la prioridad.

## 0. Requisito

Correr primero, con la base arriba:
- `CONSULTOR_SERVICIOS_1_MODELO.sql` — detecta el esquema real y agrega lo que falte (columna de servicio en `VCT_CONSULTORES_NORMAS` + índice único norma+servicio). Leer los PRINT.
- `DIAG_CONSULTOR_SERVICIOS.sql` — confirma tablas, Cavana (5), Romero, roles, sidebar.
- `db/DUMP_OBJETOS.sql` — baja los SP vigentes al repo.

Con eso se fijan los nombres reales de columnas (hoy desconocidos) y recién ahí se escriben los parches de SP contra la definición vigente del servidor.

## 1. Consultor: servicios y normas por servicio  **(CLAVE)**

En `VCT_MAIN_CONSULTORES_V360` (parche por REPLACE sobre la definición del server):

- **Sección/solapa Servicios nueva**: lista los servicios del consultor (`VCT_CONSULTORES_SERVICIOS`), con alta/baja. Botón "Agregar" → drawer con el select de servicios (`PRM_SERVICIOS` o `VCT_PRM_SERVICIOS`).
- **Modal de Norma**: sumar el campo **Servicio** (select, obligatorio) poblado del maestro de servicios. Hoy el drawer `vctDrawerConsultorNorma` tiene Norma (TEXTO11), Calificación (TEXTO12), Desde (TEXTO13), Observaciones (TEXTO14); agregar Servicio (TEXTO15) con su `<template data-vct-field-options>`.
- **Grilla de Normas**: columna **Servicio** + filtro por servicio. La misma norma puede aparecer hasta 3 veces (una por servicio).
- **Validación de duplicados**: cambiar la regla "una norma por consultor" por "una norma por **servicio** y consultor" (la del índice `UX_VCT_CONS_NORMAS_SERV`). El bloque a tocar es el `SELECT @ON=COUNT(*)` del alta de NORMA.

## 2. Lanzamiento: filtrar consultores asignables  **(CLAVE)**

En `VCT_PROYECTO_LANZ_RENDER` (arma el `<option>` de "Agregar consultor"):

- Hoy lista todos los consultores activos y marca con estrella a los que tienen alguna norma del proyecto.
- Nuevo: mostrar **solo** los consultores activos que tengan, en `VCT_CONSULTORES_SERVICIOS`, el/los servicio(s) del proyecto (`VCT_PROYECTOS_SERVICIOS`) **y**, para ese servicio, las normas del proyecto (`VCT_PROYECTOS_NORMAS`) en `VCT_CONSULTORES_NORMAS`.
- Validar lo mismo del lado servidor al grabar (`LANZ_EQUIPO_ADD`), no solo en el desplegable.
- Roles: líder / consultor / **observador** (mentor). Con 2+ consultores, exigir un único líder.

## 3. Vista 360 de Proyecto en solapas  **(CLAVE)**

Rediseño de `VCT_MAIN_PROYECTO_V360` (tiene parches LANZAMIENTO_V1, LANZ_5, PLAN_V1, VISITAS_V1, AVANCE_V1, AVANCE_SYNC_V1).

- **Encabezado**: nombre del proyecto + referencia (subtítulo) a la izquierda; cliente a la derecha. Sacar los KPI de arriba.
- **Franja de datos siempre visible**: nombre, cliente, estado (badge), servicio(s), normas, analista, consultor(es), inicio, fin.
- **Solapas con submenú** (como la 360 de Consultor):
  1. **Resumen** (default; contenido por perfil): lo que hay que hacer ahora (el stepper mientras no está lanzado) + horas proyectadas/usadas.
  2. **Servicios**.
  3. **Proyecto** ▸ Datos de entrada · Consideraciones · Equipo · Normas.
  4. **Plan estratégico** (solo cuando existe).
  5. **Acciones** (todas las del proyecto; reemplaza "Últimas gestiones").
  6. **Visitas**.
  7. **Seguimiento** (gráficos/KPI).
- El stepper deja de verse siempre: pasa a Resumen mientras se lanza, y lo cargado se ve en las solapas.

## 4. Alta de proyecto

- Campo **Referencia** (`VCT_PROYECTOS.REFERENCIA`) en el form, debajo del nombre, **no** obligatorio. Buffer: TEXTO16. Hoy el alta graba REFERENCIA = NULL.
- Mientras el proyecto está CONFIRMADO, ADMINISTRACION no edita el lanzamiento (solo el analista).
- Selector de normas: **ya corregido** en `vct-proyecto-alta.js` v2 (falta subir al server + `PROYECTO_ALTA_6_JS_V2.sql`).

## 5. Perfiles y pantallas

- Sidebar de ADMINISTRACION (= comercial) y CONSULTORES: Inicio, Acciones, Proyectos, Clientes.
- Pantalla **Proyectos** (hoy `ACTION=PROYECTOS` cae en el Inicio): listado + botón "Nuevo proyecto".
- Solo ADMINISTRACION/comercial da de alta proyectos (el consultor nunca). Botón en Inicio, Proyectos, 360 Cliente y 360 Consultor.
- Inicio del analista: bloque de **recién asignados / urgentes**, aparte de "para mirar". Vincular a Romero (empleado) con su usuario para que vea alerta y Acciones.

## 6. Gestiones → Acciones

- Renombrar el texto visible "Gestiones/Gestión" por "Acciones/Acción" en toda la app (coherencia con la solapa del sidebar). Es casi todo texto en los SP (server-rendered). No tocar claves internas ni `data-*` (p. ej. `data-vct-param-cat="gestiones"`).

## Datos de prueba

Analista Carlos Romero (empleado activo); consultor y líder María Laura Cavana (consultor 5, 3 servicios + normas).

## Primero consultoría

Auditoría funciona distinto y va después (decisión de Esteban).
