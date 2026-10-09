 
CREATE PROCEDURE [dbo].[SV_05_GRD_RENTABILIDAD]
(
    @IPKEYJOB AS VARCHAR(100),
    @FORM_ID   AS VARCHAR(100)
)
AS
BEGIN
 
    SET NOCOUNT ON;
 
    DECLARE @VFECHA_DESDE DATETIME,
            @VFECHA_HASTA DATETIME,
            @VCLIENTE     VARCHAR(50),
            @VPERIODO     VARCHAR(50),
            @VESTADO      VARCHAR(50);
 
 
    -----------------------------------------------------------------------------------------
    -- RECUPERA FILTROS
    -----------------------------------------------------------------------------------------
    SELECT
        @VFECHA_DESDE = ISNULL(FECHA_DESDE, ''),
        @VFECHA_HASTA = ISNULL(FECHA_HASTA, ''),
        @VCLIENTE     = ISNULL(CLIENTE, ''),
        @VPERIODO     = ISNULL(PERIODO, ''),
        @VESTADO      = ISNULL(ESTADO, '')
    FROM TMT_SV_05
    WHERE PAR_KEY = @IPKEYJOB;
 
 
    -----------------------------------------------------------------------------------------
    -- GRILLA
    -----------------------------------------------------------------------------------------
    SELECT
 
        -------------------------------------------------------------------------------------
        -- CLIENTE
        -------------------------------------------------------------------------------------
        '<div class="w3-left w3-muhle-text-11">'
            + C.RAZON_SOCIAL_CLIENTE +
        '</div>'
        AS '<div class="w3-left w3-muhle-text-11">Cliente</div>',
 
 
        -------------------------------------------------------------------------------------
        -- PROYECTO
        -------------------------------------------------------------------------------------
        '<div class="w3-left w3-muhle-text-11">('
            + CONVERT(VARCHAR, P.CODIGO)
            + ') - '
            + P.NORMA_REF +
        '</div>'
        AS '<div class="w3-left w3-muhle-text-11">Proyecto</div>',
 
 
        -------------------------------------------------------------------------------------
        -- RENTABILIDAD ESTIMADA
        -------------------------------------------------------------------------------------
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(VARCHAR, FORMAT(ISNULL(P.MONTO_TOTAL, 0), 'C', 'es-AR'))
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Presupuesto Total</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(VARCHAR, FORMAT(ISNULL(P.COSTO_TOTAL, 0), 'C', 'es-AR'))
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Costo Estim. Total</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                FORMAT(
                    ISNULL(P.MONTO_TOTAL, 0) - ISNULL(P.COSTO_TOTAL, 0),
                    'C',
                    'es-AR'
                )
            )
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Utilidad Estim.</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                CASE
                    WHEN ISNULL(P.MONTO_TOTAL, 0) > 0
                    THEN CONVERT(
                        NUMERIC(15,2),
                        (
                            (ISNULL(P.MONTO_TOTAL, 0) - ISNULL(P.COSTO_TOTAL, 0))
                            * 100.0
                        ) / P.MONTO_TOTAL
                    )
                    ELSE 0
                END
            )
            + ' % </div>'
        AS '<div class="w3-center w3-muhle-text-11">Margen Estim.</div>',
 
 
        -------------------------------------------------------------------------------------
        -- RENTABILIDAD REAL ACUMULADA HASTA EL PERIODO SELECCIONADO
        -------------------------------------------------------------------------------------
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                FORMAT(ISNULL(R.TotalVentasReales, 0), 'C', 'es-AR')
            )
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Ventas Acum.</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                FORMAT(ISNULL(R.TotalComprasReales, 0), 'C', 'es-AR')
            )
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Compras Acum.</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                FORMAT(
                    ISNULL(R.TotalVentasReales, 0)
                    - ISNULL(R.TotalComprasReales, 0),
                    'C',
                    'es-AR'
                )
            )
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Utilidad Real Acum.</div>',
 
 
        '<div class="w3-center w3-muhle-text-11">'
            + CASE
                WHEN ISNULL(R.TotalVentasReales, 0) > 0
                THEN CONVERT(
                    VARCHAR,
                    CONVERT(
                        NUMERIC(15,2),
                        (
                            (ISNULL(R.TotalVentasReales, 0)
                             - ISNULL(R.TotalComprasReales, 0))
                            * 100.0
                        ) / R.TotalVentasReales
                    )
                )
                ELSE '0'
            END
            + ' % </div>'
        AS '<div class="w3-center w3-muhle-text-11">Margen Real Acum.</div>',
 
 
        -------------------------------------------------------------------------------------
        -- DESVIACION DE MARGEN
        -------------------------------------------------------------------------------------
        '<div class="w3-center w3-muhle-text-11">'
            + CONVERT(
                VARCHAR,
                CONVERT(
                    NUMERIC(15,2),
                    (
                        CASE
                            WHEN ISNULL(R.TotalVentasReales, 0) > 0
                            THEN
                                (
                                    (ISNULL(R.TotalVentasReales, 0)
                                     - ISNULL(R.TotalComprasReales, 0))
                                    * 100.0
                                ) / R.TotalVentasReales
                            ELSE 0
                        END
                    )
                    -
                    (
                        CASE
                            WHEN ISNULL(P.MONTO_TOTAL, 0) > 0
                            THEN
                                (
                                    (ISNULL(P.MONTO_TOTAL, 0)
                                     - ISNULL(P.COSTO_TOTAL, 0))
                                    * 100.0
                                ) / P.MONTO_TOTAL
                            ELSE 0
                        END
                    )
                )
            )
            + ' % </div>'
        AS '<div class="w3-center w3-muhle-text-11">Desviación Margen</div>',
 
 
        -------------------------------------------------------------------------------------
        -- PERIODO HASTA EL QUE SE ESTA ACUMULANDO
        -------------------------------------------------------------------------------------
        '<div class="w3-center w3-muhle-text-11">'
            + ISNULL(R.UltimoPeriodo, '')
            + '</div>'
        AS '<div class="w3-center w3-muhle-text-11">Período</div>'
 
 
    FROM LK_PROYECTO P WITH (NOLOCK)
 
    INNER JOIN LK_CLIENTES C WITH (NOLOCK)
        ON P.ID_CLIENTE = C.ID_CLIENTE
 
 
    -----------------------------------------------------------------------------------------
    -- ACUMULA RENTABILIDAD SOLO HASTA EL PERIODO SELECCIONADO
    -----------------------------------------------------------------------------------------
    LEFT JOIN
    (
        SELECT
            PR.ID_PROYECTO,
            SUM(ISNULL(PR.VENTAS, 0)) AS TotalVentasReales,
            SUM(ISNULL(PR.COMPRAS, 0)) AS TotalComprasReales,
            MAX(PR.PERIODO) AS UltimoPeriodo
        FROM LK_PROYECTO_RENTABILIDAD PR WITH (NOLOCK)
        WHERE
            (
                @VPERIODO = ''
                OR PR.PERIODO <= @VPERIODO
            )
        GROUP BY
            PR.ID_PROYECTO
    ) R ON P.ID_PROYECTO = R.ID_PROYECTO
 
 
    -----------------------------------------------------------------------------------------
    -- FILTROS
    -----------------------------------------------------------------------------------------
    WHERE   1 = 1
    AND     (@VCLIENTE = '' OR P.ID_CLIENTE = @VCLIENTE)
    AND     (@VESTADO = '' OR P.ESTADO_PROYECTO_TOTAL = @VESTADO)
 
    -----------------------------------------------------------------------------------------
    -- SI SE SELECCIONA PERIODO:
    -- SOLO PROYECTOS CON RENTABILIDAD CARGADA HASTA ESE PERIODO
    -----------------------------------------------------------------------------------------
    AND     (@VPERIODO = '' OR R.ID_PROYECTO IS NOT NULL)
    ORDER BY
        C.RAZON_SOCIAL_CLIENTE,
        P.CODIGO;
 
END
