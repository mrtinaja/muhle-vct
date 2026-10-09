 
CREATE VIEW dbo.VCT_VW_PROYECTOS_ACTORES
AS
 
    /* Relacion explicita de equipo: fuente principal. */
    SELECT
        EQ.ID_PROYECTO,
        EQ.TIPO_MIEMBRO AS TIPO_ENTIDAD,
        CASE
            WHEN EQ.TIPO_MIEMBRO='EMPLEADO' THEN EQ.ID_EMPLEADO
            WHEN EQ.TIPO_MIEMBRO='CONSULTOR' THEN EQ.ID_CONSULTOR
            ELSE NULL
        END AS ID_ENTIDAD,
        ISNULL(NULLIF(LTRIM(RTRIM(R.DESCRIPCION)),''),R.CODIGO) AS RELACION,
        'EQUIPO' AS FUENTE,
        1 AS PRIORIDAD_FUENTE
    FROM dbo.VCT_PROYECTOS_EQUIPO EQ
    LEFT JOIN dbo.VCT_PRM_PROYECTOS_ROLES R
        ON R.ID=EQ.ID_ROL
    WHERE EQ.TIPO_MIEMBRO IN ('EMPLEADO','CONSULTOR')
      AND CASE
              WHEN EQ.TIPO_MIEMBRO='EMPLEADO' THEN EQ.ID_EMPLEADO
              WHEN EQ.TIPO_MIEMBRO='CONSULTOR' THEN EQ.ID_CONSULTOR
              ELSE NULL
          END IS NOT NULL
      AND ISNULL(NULLIF(UPPER(LTRIM(RTRIM(EQ.ESTADO))),''),'ACTIVO')<>'INACTIVO'
 
    UNION ALL
 
    /* Una visita es evidencia historica directa de participacion. */
    SELECT
        V.ID_PROYECTO,
        'CONSULTOR',
        VC.ID_CONSULTOR,
        CASE WHEN ISNULL(VC.LIDER,0)=1 THEN 'Consultor líder de visita'
             ELSE 'Consultor en visita' END,
        'VISITA',
        2
    FROM dbo.VCT_PROYECTOS_VISITAS V
    INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES VC
        ON VC.ID_VISITA=V.ID
 
    UNION ALL
 
    /* Una gestion vinculada al proyecto tambien constituye evidencia. */
    SELECT
        G.ID_PROYECTO,
        GP.TIPO_ENTIDAD,
        GP.ID_ENTIDAD,
        CASE GP.ROL_PARTICIPANTE
            WHEN 'RESPONSABLE' THEN 'Responsable de gestión'
            WHEN 'DESTINATARIO' THEN 'Destinatario de gestión'
            WHEN 'APROBADOR' THEN 'Aprobador de gestión'
            WHEN 'OBSERVADOR' THEN 'Observador de gestión'
            ELSE 'Participante de gestión'
        END,
        'GESTION',
        3
    FROM dbo.VCT_GESTIONES G
    INNER JOIN dbo.VCT_GESTIONES_PARTICIPANTES GP
        ON GP.ID_GESTION=G.ID
    WHERE G.ID_PROYECTO IS NOT NULL
      AND GP.TIPO_ENTIDAD IN ('EMPLEADO','CONSULTOR')
      AND GP.ID_ENTIDAD IS NOT NULL
      AND GP.ESTADO='ACTIVO';
