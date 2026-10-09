/* =============================================================================
   VERIFICACION - ¿VCT_RENDER_MODULE_HEADER y vct_RenderGrid son compartidos
   entre el admin (M_CONFIG_*) y el portal principal (VCT_MAIN_*)?
   -----------------------------------------------------------------------------
   Busca en el texto de TODOS los SPs de la base quién llama a cada uno, y
   clasifica el resultado según el prefijo del SP que lo llama.
   ============================================================================= */

SELECT
    Llamado_por        = OBJECT_SCHEMA_NAME(o.object_id) + '.' + o.name,
    Tipo_de_caller      = CASE
                              WHEN o.name LIKE 'M_CONFIG%'  THEN 'ADMIN'
                              WHEN o.name LIKE 'VCT_MAIN%'  THEN 'MAIN'
                              WHEN o.name = 'VCT_RENDER_MODULE_HEADER' THEN '(es el propio SP)'
                              ELSE 'OTRO/INFRA'
                          END,
    SP_referenciado     = 'VCT_RENDER_MODULE_HEADER'
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%VCT_RENDER_MODULE_HEADER%'
  AND o.name <> 'VCT_RENDER_MODULE_HEADER'   -- excluye la definición del propio SP

UNION ALL

SELECT
    OBJECT_SCHEMA_NAME(o.object_id) + '.' + o.name,
    CASE
        WHEN o.name LIKE 'M_CONFIG%'  THEN 'ADMIN'
        WHEN o.name LIKE 'VCT_MAIN%'  THEN 'MAIN'
        WHEN o.name = 'vct_RenderGrid' THEN '(es el propio SP)'
        ELSE 'OTRO/INFRA'
    END,
    'vct_RenderGrid'
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%vct_RenderGrid%'
  AND o.name <> 'vct_RenderGrid'

ORDER BY SP_referenciado, Tipo_de_caller, Llamado_por;
