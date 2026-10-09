/* buscar_consultor_con_visitas_v2.sql
   La v1 (filtrada al mes en curso) vino vacia -- puede que en este
   ambiente (desa) no haya visitas cargadas para septiembre 2026. Esta
   version NO filtra por mes: lista TODOS los consultores con al menos
   una visita cargada, mas cercana a hoy primero, para ver que datos
   existen realmente y en que mes probar. */

SELECT
    VC.IDCONSULTOR,
    C.NOMBRES,
    C.APELLIDOS,
    COUNT(*) AS CANTIDAD_VISITAS_TOTAL,
    MIN(V.FECHA_DESDE) AS PRIMERA_VISITA,
    MAX(V.FECHA_DESDE) AS ULTIMA_VISITA
FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
INNER JOIN dbo.VCT_PROYECTOS_VISITAS V ON V.ID = VC.IDVISITA
INNER JOIN dbo.VCT_CONSULTORES C ON C.ID = VC.IDCONSULTOR
GROUP BY VC.IDCONSULTOR, C.NOMBRES, C.APELLIDOS
ORDER BY ABS(DATEDIFF(DAY, MAX(V.FECHA_DESDE), GETDATE()));

-- Por si la tabla de visitas esta directamente vacia en este ambiente:
SELECT COUNT(*) AS TOTAL_FILAS_VCT_PROYECTOS_VISITAS FROM dbo.VCT_PROYECTOS_VISITAS;
SELECT COUNT(*) AS TOTAL_FILAS_VCT_PROYECTOS_VISITAS_CONSULTORES FROM dbo.VCT_PROYECTOS_VISITAS_CONSULTORES;
