CREATE PROCEDURE [dbo].[PA_SYS_GROUPS]
	(@USER_ID AS VARCHAR(30))
AS
 
-- =========================================================================================================================
-- AUTOR: LDM
-- DESCRIPCIÓN: Devuelve los grupos de un usuario. Armado para estructuras de 7 niveles.
-- CONSIDERACIONES:
-- 1. Si en la prm esta definido mas o menos de 7 niveles se debera modificar ese SP
-- =========================================================================================================================
 
BEGIN
	SET NOCOUNT ON;
 
SELECT DISTINCT S.SUPERVISOR_CODE as USER_ID, S.SUPERVISOR_NAME as USER_NAME, OD.UNIT_CODE, OD.UNIT_DESCRIPTION
FROM ORGANIZATION O
INNER JOIN ORGANIZATION OD ON (
(O.UNIT_CODE=OD.NIVEL1)
OR
(O.UNIT_CODE=OD.NIVEL2)
OR
(O.UNIT_CODE=OD.NIVEL3)
OR
(O.UNIT_CODE=OD.NIVEL4)
OR
(O.UNIT_CODE=OD.NIVEL5)
OR
(O.UNIT_CODE=OD.NIVEL6)
OR
(O.UNIT_CODE=OD.NIVEL7)
) 
INNER JOIN SUPERVISOR S ON O.UNIT_CODE=S.UNIT_CODE
AND O.NIVEL=S.UNIT_LEVEL 
AND OD.NIVEL>=S.UNIT_LEVEL 
WHERE OD.BOTTOM=1 
AND S.SUPERVISOR_CODE=@USER_ID
UNION 
SELECT DISTINCT A.USER_ID, A.USER_NAME, O.UNIT_CODE, O.UNIT_DESCRIPTION
FROM AGENTE A 
INNER JOIN ORGANIZATION O ON A.UNIT_CODE=O.UNIT_CODE 
WHERE O.BOTTOM=1
AND A.USER_ID=@USER_ID
ORDER BY 2 ASC
 
END
 
