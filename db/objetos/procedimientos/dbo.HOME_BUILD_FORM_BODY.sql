CREATE PROCEDURE [dbo].[HOME_BUILD_FORM_BODY]
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ACTION VARCHAR(50);
    DECLARE @HTML NVARCHAR(MAX) = '';
 
    -- Leer la acción persistida
    SELECT TOP 1 @ACTION = LTRIM(RTRIM(ACTION)) 
    FROM dbo.M_CONFIG 
    WHERE ACTION = 'ACTION';
 
    -- Evaluar acción para construir el formulario
    IF (@ACTION = 'USUARIOS' OR @ACTION = 'UPD')
    BEGIN
        SET @HTML = '
        <div class="vct-tab-form-container w3-card-4 w3-white w3-padding w3-round-large" style="margin-top: 10px;">
            <h3 style="color:#66062C; font-weight:bold;"><i class="fa fa-user-plus"></i> Datos del Usuario</h3>
            <hr/>
            <div class="w3-row-padding">
                <div class="w3-half">
                    <label><b>Nombre Completo</b></label>
                    <input class="w3-input w3-border w3-round" type="text" name="txtNombre" placeholder="Ingrese nombre...">
                </div>
                <div class="w3-half">
                    <label><b>Correo Electrónico</b></label>
                    <input class="w3-input w3-border w3-round" type="text" name="txtEmail" placeholder="correo@ejemplo.com">
                </div>
            </div>
            <div class="w3-margin-top text-right">
                <button type="button" class="w3-btn w3-round" style="background:#66062C; color:#fff;">Guardar Usuario</button>
            </div>
        </div>';
    END
 
    -- Devolver el resultado HTML directo
    SELECT ISNULL(@HTML, '') AS PS_FORMULARIO;
END
