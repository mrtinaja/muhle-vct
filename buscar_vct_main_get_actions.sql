/* =============================================================================
   1. ¿Existe algún objeto con nombre PARECIDO a VCT_MAIN_GET_ACTIONS?
   (por si el nombre real es levemente distinto: GET_ACTIONS, ACTIONS, PERMISOS...)
   ============================================================================= */
SELECT name, type_desc, create_date, modify_date
FROM sys.objects
WHERE name LIKE '%ACTION%'
   OR name LIKE '%PERMISO%'
ORDER BY name;


/* =============================================================================
   2. ¿Algún SP existente lo REFERENCIA en su texto (llamado desde dentro de
   otro SP, no desde JS/cliente)?
   ============================================================================= */
SELECT
    Llamado_desde = OBJECT_SCHEMA_NAME(o.object_id) + '.' + o.name,
    o.type_desc
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%VCT_MAIN_GET_ACTIONS%';


/* =============================================================================
   3. Confirmar explícitamente que el objeto no existe (por nombre exacto,
   sin importar el tipo de objeto: SP, función, vista...)
   ============================================================================= */
SELECT name, type_desc
FROM sys.objects
WHERE name = 'VCT_MAIN_GET_ACTIONS';
