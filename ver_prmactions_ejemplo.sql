-- Filas ya existentes/funcionando de una entidad que sí anda en el sidebar,
-- para copiar el patrón exacto de columnas al armar CONFIGURACION.EDIT/VIEW.
SELECT * FROM dbo.PrmActions WHERE ActionID LIKE 'CLIENTES.%';

-- Y confirmar de una vez que CONFIGURACION no tiene nada todavía:
SELECT * FROM dbo.PrmActions WHERE ActionID LIKE 'CONFIGURACION.%';

-- Estructura completa de la tabla (tipos, nulabilidad, defaults)
EXEC sp_help 'dbo.PrmActions';
