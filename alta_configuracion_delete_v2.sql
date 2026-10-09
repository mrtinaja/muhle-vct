-- Primero confirmar nombres reales de columnas de Actions (para no adivinar
-- una tercera vez). Corre esto primero y fijate que coincida con el orden
-- posicional de abajo: Code, Description, Id, Fecha, Col5, Tipo.
SELECT COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Actions'
ORDER BY ORDINAL_POSITION;

-- Verificacion previa: confirmar que no exista ya
SELECT * FROM dbo.Actions WHERE Code = 'CONFIGURACION.DELETE';

-- Alta de la accion (mismo patron que DOCUMENTOS.DELETE: Tipo='ACTION')
INSERT INTO dbo.Actions
VALUES
(
    'CONFIGURACION.DELETE',      -- Code
    'Eliminar configuración',    -- Description (minuscula, como sus hermanas)
    NEWID(),                     -- Id
    GETDATE(),                   -- Fecha
    NULL,                        -- Col5 (NULL, como el resto de CONFIGURACION.*)
    'ACTION'                     -- Tipo (como DOCUMENTOS.DELETE)
);

-- Verificacion posterior
SELECT * FROM dbo.Actions WHERE Code = 'CONFIGURACION.DELETE';
