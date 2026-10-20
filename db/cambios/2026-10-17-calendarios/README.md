# Calendarios VCT — cierre del 17/10/2026

Los assets de js/ y css/ contienen la entrega final validada por el usuario en desarrollo.
Se mantienen el borde institucional, los colores de estados y los valores ISO originales.

- Proyecto 360: calendario siempre visible, acciones, visitas, horas y feriados.
- Consultor 360: botones Mes/Semana/Dia y retorno desde la vista diaria.
- Acciones: toolbar compacta, dropdowns VCT y feriados independientes del filtro.
- Feriados: picker VCT con estilos y fecha sincronizada al abrir el drawer.
- Licencia/vacaciones: columnas completas y protecciones de disponibilidad, actividades,
  asignaciones, fechas de visita y registro de horas. No borra conflictos previos.

## Fuentes e instalacion

Las fuentes completas de AGENDA_CONSULTOR_3_PANTALLA.sql y
VCT_MAIN_PROYECTO_V360_AGENDA.sql ya incorporan los parches 10/11.
AGENDA_CONSULTOR_8_ACTIVIDADES.sql crea el modelo sin datos de demostracion.

Para actualizar una instalacion anterior, respaldar primero los assets y los SP vigentes:

1. Subir los seis assets: vct-calendario, vct-datepicker y vct-acciones (CSS y JS).
2. Si falta el modelo, ejecutar AGENDA_CONSULTOR_8_ACTIVIDADES.sql.
3. Aplicar las fuentes completas actualizadas de Agenda/Proyecto, o los parches 10/11
   sobre la entrega v12. No hace falta hacer ambas cosas.
4. Ejecutar 04_BLOQUEOS_LICENCIA.sql y 12_ACCIONES_FERIADOS.sql.
5. Ejecutar 13_ASSETS_V21.sql para renovar las referencias de cache.
6. Cerrar todas las pestanas de Vocaturo y volver a abrir con Ctrl+F5.

No volver a aplicar versiones antiguas de los SP despues de los parches.
07_REVERTIR_SOLO_BLOQUEOS.sql es exclusivamente una reversa de los cinco triggers.
No borra actividades ni restaura SP/assets: para eso se usa el respaldo previo.

## Validacion

- Sintaxis de los tres JS comprobada con Node vm.Script.
- Arnes local: Proyecto sin selector de anio sigue renderizando; Mes/Semana/Dia.
- Cambiar anio actualiza titulo y seleccion de los dropdowns VCT.
- Consultor 360: Mes -> Dia -> Mes y Dia -> Semana.
- Feriados y actividad simultaneos en Mes/Semana/Dia de Proyecto y Acciones.
- Toolbars en una fila y celdas base de 56px; crecen para alojar contenido.
- Picker: input nativo oculto; fecha asignada sin change se refleja; eleccion actualiza ISO.
- El usuario ejecuto los SQL en desarrollo y confirmo el resultado final.
- No se ejecuto SQL Server desde el agente; la conexion no estuvo disponible.

El entorno revisado es SQL Server 2017, compatibilidad 140. Los parches 11/12 usan
FOR JSON PATH de ese entorno; no se declara compatibilidad con motores anteriores.
El bump 13 es una normalizacion de assets para futuros despliegues; no fue aplicado
contra la base por esta sesion.
