/* ============================================================================
   DIAG_ACCIONES_NUEVA  (salida por SELECT -> :OUT la captura)
   ----------------------------------------------------------------------------
   Muestra las acciones que VCT_MAIN_GET_ACTIONS devuelve para el modulo
   ACCIONES segun el perfil, con foco en la accion de ALTA (CREATE/NEW/ADD).
   Si TARGET_GUID viene vacio, el boton "Nueva" cae en VCT.Navigation.next()
   y rebota a la misma pantalla. Solo lee. No modifica nada.

   >>> AJUSTA @PERFIL al perfil del usuario con el que probas (ej. el de
       "Vocaturo Agustin"). Si no sabes, deja GERENCIA y SQUAD: corre las dos.

   USO: SSMS -> menu Query -> "SQLCMD Mode" (activar) -> F5.
        Queda en: C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_NUEVA.txt
   ============================================================================ */
:OUT C:\Users\Usuario\Desktop\muhle-vct\_diag\ACCIONES_NUEVA.txt
USE [MuhlePROD];
SET NOCOUNT ON;

DECLARE @PERFIL VARCHAR(100) = 'GERENCIA';   /* <-- cambia si hace falta */

SELECT
    @PERFIL AS PERFIL,
    A.ACTION_ID,
    A.ACTION_TYPE,
    A.TITLE,
    A.STORAGE_KEY,
    A.TARGET_TAB,
    A.TARGET_GUID,
    CASE WHEN LTRIM(RTRIM(ISNULL(A.TARGET_GUID,''))) = '' THEN '>>> GUID VACIO <<<' ELSE 'ok' END AS DIAG_GUID,
    A.SORT_ORDER
FROM dbo.VCT_MAIN_GET_ACTIONS(@PERFIL, 'ACCIONES') A
ORDER BY A.SORT_ORDER, A.ACTION_ID;

/* por si el perfil real es otro, repetimos para SQUAD */
SELECT
    'SQUAD' AS PERFIL,
    A.ACTION_ID, A.ACTION_TYPE, A.TITLE, A.STORAGE_KEY, A.TARGET_TAB, A.TARGET_GUID,
    CASE WHEN LTRIM(RTRIM(ISNULL(A.TARGET_GUID,''))) = '' THEN '>>> GUID VACIO <<<' ELSE 'ok' END AS DIAG_GUID,
    A.SORT_ORDER
FROM dbo.VCT_MAIN_GET_ACTIONS('SQUAD', 'ACCIONES') A
ORDER BY A.SORT_ORDER, A.ACTION_ID;

:OUT stdout
