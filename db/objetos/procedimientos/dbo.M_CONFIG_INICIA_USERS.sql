CREATE PROCEDURE [dbo].[M_CONFIG_INICIA_USERS]
(
    @IPKEYJOB      VARCHAR(100) = NULL,
    @IUSERID      VARCHAR(100) = NULL,
    @FORM_ID      VARCHAR(100) = NULL,
    @PS_TITULO    VARCHAR(MAX) = NULL OUTPUT,
    @PS_FORMULARIO VARCHAR(MAX) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @RETCODE INT;
 
    ---------------------------------------------------------------------------
    -- 1. EJECUCIÓN DEL UPDATE/INSERT EN LA BD
    ---------------------------------------------------------------------------
    -- Cuando Mühle llega a esta actividad (disparado por el submit nativo SP.*),
    -- invocamos inmediatamente la persistencia con los datos capturados en M_CONFIG.
    EXEC dbo.M_CONFIG_UPD_USER 
        @IPKEYJOB = @IPKEYJOB, 
        @IUSERID  = @IUSERID, 
        @ORETCODE = @RETCODE OUTPUT;
 
    ---------------------------------------------------------------------------
    -- 2. CABECERA Y REDIRECCIÓN INMEDIATA A LA GRILLA (3-USUARIOS)
    ---------------------------------------------------------------------------
    -- Evita el salto a la pantalla blanca enviando un redireccionador automático
    -- que vuelve a la grilla principal (GUID: 9911B4B4-A00E-40D8-B148-A92469C268CC).
    
    SET @PS_TITULO = '
    <div style="padding: 10px; color: #6b0c36; font-weight: bold;">
        <span>Procesando solicitud...</span>
    </div>';
 
    SET @PS_FORMULARIO = '
    <div style="text-align: center; padding: 40px;">
        <p style="font-family: sans-serif; color: #555;">Guardando datos del usuario...</p>
    </div>
    <script type="text/javascript">
        setTimeout(function() {
            if (typeof goto === "function") {
                // Regresa automáticamente a la grilla principal de usuarios
                goto("' + ISNULL(@FORM_ID, '') + '", "9911B4B4-A00E-40D8-B148-A92469C268CC");
            } else {
                window.location.reload();
            }
        }, 100);
    </script>';
 
END
