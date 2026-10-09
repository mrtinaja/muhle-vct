 
CREATE FUNCTION [dbo].[VCT_USER_GET_ACTIONS]
(
    @GROUPID   NVARCHAR(100),   -- GRUPO
    @SIDEBARID NVARCHAR(100)    -- IDSIDEBAR
)
RETURNS NVARCHAR(MAX)
-- PROPOSITO:
--   Reemplaza el patron viejo de llamar VCT_USER_HAS_ACTION(@USER, @RECURSO, 'VIEW'/'CREATE'/'EDIT'/...)
--   una vez POR CADA accion, con codigos de accion hardcodeados repartidos en cada SP llamador.
--   Esta funcion hace UNA sola consulta y devuelve TODAS las acciones que el usuario tiene
--   habilitadas para ese recurso (via su grupo). El SP llamador despues solo verifica membresia
--   en esa lista (CHARINDEX(',EDIT,', @acciones) > 0), sin repetir la consulta a la base
--   ni tener que ir a buscar la funcion 3 veces con 3 strings distintos.
AS
BEGIN
    DECLARE @RESULT NVARCHAR(MAX);
 
    SELECT @RESULT = ',' + STRING_AGG(CONVERT(NVARCHAR(MAX), SUBSTRING(X.Id, LEN(@SIDEBARID) + 1, 150)), ',') + ','
    FROM (
        
		SELECT DISTINCT GA.ActionID as id
        FROM dbo.GroupsActions GA WITH (NOLOCK)
            INNER JOIN dbo.PrmActions PA	WITH (NOLOCK) ON GA.ActionId = PA.ActionId
        WHERE	ga.GroupId = UPPER(LTRIM(RTRIM(@GROUPID)))
		AND		pa.SideBarId = @SIDEBARID
    ) X;
 
    -- PASO 5: si el usuario no tiene NINGUNA accion para ese recurso, STRING_AGG devuelve
    --         NULL (no hay filas para agregar) y por lo tanto @RESULT tambien queda NULL.
    --         Devolvemos ',' (lista "vacia" pero valida) para que cualquier CHARINDEX
    --         que haga el SP llamador simplemente no encuentre nada, sin errores.
    RETURN ISNULL(@RESULT, ',');
END
