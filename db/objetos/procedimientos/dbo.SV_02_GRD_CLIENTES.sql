 
CREATE PROCEDURE [dbo].[SV_02_GRD_CLIENTES]
(
    @IPKEYJOB VARCHAR(100),
    @FORM_ID  VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @USER_ID VARCHAR(100) = '';
    DECLARE @CAN_EDIT BIT = 0;
 
    SELECT TOP 1
        @USER_ID = ISNULL(TS_USER_ID, '')
    FROM dbo.TMT_SV_02 WITH (NOLOCK)
    WHERE PAR_KEY = @IPKEYJOB;
 
    SET @CAN_EDIT = dbo.VCT_USER_HAS_ACTION(@USER_ID, 'Clientes', 'EDIT');
 
    IF OBJECT_ID('tempdb..#TmpClientes') IS NOT NULL
        DROP TABLE #TmpClientes;
 
    SELECT
        Clave = ISNULL(CONVERT(VARCHAR(100), C.ID_CLIENTE), ''),
        Cliente = ISNULL(C.RAZON_SOCIAL_CLIENTE, ''),
        Tipo = ISNULL(CONVERT(VARCHAR(100), C.TIPO_CLIENTE), ''),
        CUIT = ISNULL(C.CUIT_CLIENTE, ''),
 
        Domicilio = LTRIM(RTRIM(
            ISNULL(C.CALLE_CLIENTE, '') + ' ' +
            ISNULL(C.NRO_CALLE_CLIENTE, '') +
            CASE
                WHEN ISNULL(C.PISO_DEPTO_CLIENTE, '') = '' THEN ''
                ELSE ' - ' + C.PISO_DEPTO_CLIENTE
            END
        )),
 
        Localidad = ISNULL(C.LOCALIDAD_CLIENTE, ''),
        Provincia = ISNULL(CD.CAT_DATA_DESC, ISNULL(CONVERT(VARCHAR(100), C.PROVINCIA_CLIENTE), '')),
        Contacto = ISNULL(C.CONTACTO_CLIENTE, ''),
        Telefono = ISNULL(C.TEL1_CLIENTE, ''),
        Celular = ISNULL(C.TEL2_CLIENTE, ''),
        Email = ISNULL(C.EMAIL_CLIENTE, ''),
 
        Calle =
            CASE
                WHEN CHARINDEX(' ', REVERSE(LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, ''))))) > 0
                     AND ISNULL(C.NRO_CALLE_CLIENTE, '') = '' THEN
                    LEFT(
                        LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, ''))),
                        LEN(LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, '')))) -
                        CHARINDEX(' ', REVERSE(LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, '')))))
                    )
                ELSE LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, '')))
            END,
 
        Nro =
            CASE
                WHEN ISNULL(C.NRO_CALLE_CLIENTE, '') <> '' THEN
                    ISNULL(C.NRO_CALLE_CLIENTE, '')
                WHEN CHARINDEX(' ', REVERSE(LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, ''))))) > 0 THEN
                    RIGHT(
                        LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, ''))),
                        CHARINDEX(' ', REVERSE(LTRIM(RTRIM(ISNULL(C.CALLE_CLIENTE, ''))))) - 1
                    )
                ELSE ''
            END,
 
        Piso = ISNULL(C.PISO_DEPTO_CLIENTE, ''),
        ProvinciaCodigo = ISNULL(CONVERT(VARCHAR(100), C.PROVINCIA_CLIENTE), ''),
        IvaCodigo = ISNULL(CONVERT(VARCHAR(100), C.IVA_CLIENTE), ''),
        TipoCodigo = ISNULL(CONVERT(VARCHAR(100), C.TIPO_CLIENTE), '')
    INTO #TmpClientes
    FROM dbo.LK_CLIENTES C WITH (NOLOCK)
        LEFT JOIN dbo.CAT_DATA CD WITH (NOLOCK)
            ON CD.CAT_DATA_CODE = C.PROVINCIA_CLIENTE
           AND CD.PAR_KEY = (
                SELECT TOP 1 PKEY
                FROM dbo.CAT_TYPE WITH (NOLOCK)
                WHERE CAT_TYPE_CODE = 'PROVINCIA'
           )
    ORDER BY C.RAZON_SOCIAL_CLIENTE;
 
    DECLARE @ActionsJson VARCHAR(MAX);
 
    IF @CAN_EDIT = 1
    BEGIN
        SET @ActionsJson =
        '[
            {
                "type": "edit",
                "title": "Editar cliente",
                "icon": "pencil",
                "keyField": "Clave",
                "targetTab": "form"
            }
        ]';
    END
    ELSE
    BEGIN
        SET @ActionsJson = '[]';
    END;
 
    EXEC dbo.vct_RenderGrid
         @TempTableName = '#TmpClientes',
         @FormId        = @FORM_ID,
         @ActionsJson   = @ActionsJson,
         @PageSize      = 10,
         @HiddenColumns = 'Clave,ProvinciaCodigo,IvaCodigo,TipoCodigo',
         @ScriptVersion = '16.0.0';
 
    IF OBJECT_ID('tempdb..#TmpClientes') IS NOT NULL
        DROP TABLE #TmpClientes;
END
