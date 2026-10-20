/* ========================================================================
   DIAG_ACCIONES_ORIGEN  (solo lectura: no modifica nada)
   ------------------------------------------------------------------------
   Acciones viejas que hoy caen en el grupo "Proyecto" de la pestana Acciones
   y en realidad son del plan o del workflow:
     - ORIGEN = MANUAL, sin item del plan (ID_PLAN_ITEM NULL)
     - con un subtipo que no es de carga manual del proyecto
       (CARGA_MANUAL = SISTEMA o PLAN, ver PASO5_1)
   Para cada una propone a que grupo deberia ir y, si es del plan, el item
   candidato del plan del proyecto (se busca el titulo del item dentro del
   titulo de la accion). Pasar las dos grillas.
   ======================================================================== */
USE [MuhlePROD];
SET NOCOUNT ON;

/* 1. acciones a revisar con la propuesta */
SELECT P.CODIGO AS PROYECTO, A.ID AS ID_ACCION, A.ORIGEN, T.CODIGO AS TIPO, S.CODIGO AS SUBTIPO, S.CARGA_MANUAL,
       E.CODIGO AS ESTADO, A.ID_REGLA_ORIGEN, A.ID_PLAN, A.FECHA_CREACION, A.TITULO,
       CASE WHEN S.CARGA_MANUAL = 'SISTEMA' THEN 'Workflow: ORIGEN = ' + CASE WHEN A.ID_REGLA_ORIGEN IS NOT NULL THEN 'AUTOMATICA' ELSE 'SISTEMA' END
            WHEN S.CARGA_MANUAL = 'PLAN' AND C.N = 1 THEN 'Plan: ID_PLAN_ITEM = ' + CONVERT(VARCHAR(20), C.ID_ITEM)
            WHEN S.CARGA_MANUAL = 'PLAN' AND C.N > 1 THEN 'Plan: hay ' + CONVERT(VARCHAR(10), C.N) + ' items candidatos (elegir uno)'
            ELSE 'Plan: sin item candidato (definir a mano o cancelar)' END AS PROPUESTA,
       C.ITEM_CANDIDATO
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S WITH(NOLOCK) ON S.ID = A.ID_SUBTIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_TIPOS T WITH(NOLOCK) ON T.ID = A.ID_TIPO
LEFT JOIN dbo.VCT_PRM_ACCIONES_ESTADOS E WITH(NOLOCK) ON E.ID = A.ID_ESTADO
OUTER APPLY (
    SELECT COUNT(*) AS N, MIN(I.ID) AS ID_ITEM,
           MIN(ISNULL(I.CODIGO_ITEM + ' ', '') + I.TITULO) AS ITEM_CANDIDATO
    FROM dbo.VCT_PROYECTOS_PLAN_ITEMS I WITH(NOLOCK)
    INNER JOIN dbo.VCT_PROYECTOS_PLANES PL WITH(NOLOCK) ON PL.ID = I.ID_PLAN AND PL.ID_PROYECTO = A.ID_PROYECTO
    WHERE ISNULL(I.GRUPO,'') <> 'CAPITULO' AND LEN(ISNULL(I.TITULO,'')) > 5
      AND A.TITULO LIKE '%' + REPLACE(REPLACE(I.TITULO, '[', '[[]'), '%', '[%]') + '%'
) C
WHERE A.ORIGEN = 'MANUAL' AND A.ID_PLAN_ITEM IS NULL AND S.CARGA_MANUAL IN ('SISTEMA','PLAN')
ORDER BY P.CODIGO, A.ID;

/* 2. resumen por proyecto y propuesta */
SELECT P.CODIGO AS PROYECTO, S.CARGA_MANUAL, S.CODIGO AS SUBTIPO, COUNT(*) AS CANT
FROM dbo.VCT_ACCIONES A WITH(NOLOCK)
INNER JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
INNER JOIN dbo.VCT_PRM_ACCIONES_SUBTIPOS S WITH(NOLOCK) ON S.ID = A.ID_SUBTIPO
WHERE A.ORIGEN = 'MANUAL' AND A.ID_PLAN_ITEM IS NULL AND S.CARGA_MANUAL IN ('SISTEMA','PLAN')
GROUP BY P.CODIGO, S.CARGA_MANUAL, S.CODIGO
ORDER BY P.CODIGO, S.CARGA_MANUAL, S.CODIGO;
