 
CREATE VIEW dbo.VCT_VW_PERSONAS_V360
AS
    SELECT
        'EMPLEADO' AS TIPO_ENTIDAD,
        E.ID AS ID_ENTIDAD,
        CONVERT
        (
            VARCHAR(320),
            ISNULL
            (
                NULLIF
                (
                    LTRIM
                    (
                        RTRIM
                        (
                            ISNULL(E.NOMBRES,'')+
                            CASE
                                WHEN NULLIF(LTRIM(RTRIM(ISNULL(E.NOMBRES,''))),'') IS NOT NULL
                                 AND NULLIF(LTRIM(RTRIM(ISNULL(E.APELLIDOS,''))),'') IS NOT NULL
                                    THEN ' '
                                ELSE ''
                            END+
                            ISNULL(E.APELLIDOS,'')
                        )
                    ),
                    ''
                ),
                'Empleado #'+CONVERT(VARCHAR(20),E.ID)
            )
        ) AS NOMBRE
    FROM dbo.VCT_EMPLEADOS E
 
    UNION ALL
 
    SELECT
        'CONSULTOR',
        C.ID,
        CONVERT(VARCHAR(320),CASE
            WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),'')+
                 CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),'') IS NOT NULL
                        AND NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),''))),'') IS NOT NULL
                      THEN ' ' ELSE '' END+
                 ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),''))),'') IS NOT NULL
              THEN LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),'')+
                   CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.NOMBRES),''))),'') IS NOT NULL
                          AND NULLIF(LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),''))),'') IS NOT NULL
                        THEN ' ' ELSE '' END+
                   ISNULL(CONVERT(VARCHAR(150),C.APELLIDOS),'')))
            ELSE 'Consultor #'+CONVERT(VARCHAR(20),C.ID)
          END)
    FROM dbo.VCT_CONSULTORES C;
