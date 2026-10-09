CREATE PROCEDURE [dbo].[M_CONFIG_INICIA_GROUPS]
(
    @IPKEYJOB      AS VARCHAR(100),
    @IUSERID        AS VARCHAR(100),
    @FORM_ID        AS VARCHAR(100),
    @PS_TITULO     AS VARCHAR(MAX) OUTPUT,
    @PS_FORMULARIO AS VARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @VPERFIL_TMT     NVARCHAR(100),
            @VNOMBRE_TMT     NVARCHAR(200),
            @VEMAIL_TMT      NVARCHAR(300),
            @VDESC_ERROR     NVARCHAR(4000),
            @ID_GROUP_SEL    VARCHAR(100),
            @FIELDS_HTML     VARCHAR(MAX),
            @FORM_MODAL_HTML VARCHAR(MAX) = '',
            @TITULO_FORM     NVARCHAR(100),
            @BOTON_GUARDAR   NVARCHAR(50);
 
    -- 1. Leer datos de sesión desde M_CONFIG
    SELECT  @VNOMBRE_TMT    = ISNULL(NEW_NAME, ''),
            @VPERFIL_TMT    = ISNULL(NEW_ID, ''),
            @VEMAIL_TMT     = ISNULL(NEW_EMAIL, ''),
            @VDESC_ERROR    = ISNULL(DESC_ERROR, ''),
            @ID_GROUP_SEL   = ISNULL(ID_GROUP_SEL, '')
    FROM    M_CONFIG WITH (NOLOCK)
    WHERE   PAR_KEY = @IPKEYJOB;
 
    -- 2. Obtener datos de la tabla Groups si es edición
    IF (@ID_GROUP_SEL <> '' AND @VDESC_ERROR = '') 
    BEGIN
        SELECT  @VPERFIL_TMT = ISNULL(Id, ''), 
                @VNOMBRE_TMT = ISNULL(Name, ''),
                @VEMAIL_TMT  = ISNULL(email, '')
        FROM    Groups WITH (NOLOCK)
        WHERE   Id = @ID_GROUP_SEL;
    END    
 
    -- 3. Maquetación del Formulario Modal (Diseño Vocaturo)
    SET @FIELDS_HTML = '
        <div class="vct-form-group">
            <label class="vct-label"><i class="fas fa-key"></i> ID Grupo / Perfil <span style="color:#ef4444;">*</span></label>
            <input class="vct-input-text" type="text" name="SP.NEW_ID" value="' + CASE WHEN @ID_GROUP_SEL <> '' THEN @ID_GROUP_SEL ELSE ISNULL(@VPERFIL_TMT, '') END + '" ' + CASE WHEN @ID_GROUP_SEL <> '' THEN 'disabled' ELSE '' END + ' placeholder="ej. SQUAD">
        </div>
 
        <div class="vct-form-group">
            <label class="vct-label"><i class="fas fa-users"></i> Nombre del Perfil <span style="color:#ef4444;">*</span></label>
            <input class="vct-input-text" type="text" name="SP.NEW_NAME" value="' + ISNULL(@VNOMBRE_TMT, '') + '" placeholder="ej. Desarrollo Squad">
        </div>
 
        <div class="vct-form-group">
            <label class="vct-label"><i class="fas fa-envelope"></i> Email Contacto</label>
            <input class="vct-input-text" type="text" name="SP.NEW_EMAIL" value="' + ISNULL(@VEMAIL_TMT, '') + '" placeholder="grupo@vocaturo.com.ar">
        </div>';
 
    SET @TITULO_FORM    = CASE WHEN @ID_GROUP_SEL = '' THEN 'Agregar Perfil / Grupo' ELSE 'Modificar Perfil / Grupo' END;
    SET @BOTON_GUARDAR  = CASE WHEN @ID_GROUP_SEL = '' THEN 'Agregar' ELSE 'Grabar' END;
 
    -- 4. Construcción del Formulario Modal
    EXEC [dbo].[HOME_BUILD_FORM_BODY]
        @I_TITLE        = @TITULO_FORM,
        @I_FIELDS_HTML  = @FIELDS_HTML,
        @I_FORM_ID      = @FORM_ID,
        @I_SAVE_LABEL   = @BOTON_GUARDAR,
        @I_LAYOUT_MODE  = 'SMALL',
        @O_HTML_FORM    = @FORM_MODAL_HTML OUTPUT;
 
    -- 5. Únicamente devolvemos el modal oculto (la grilla la maneja nativamente Mühle sin duplicarse)
    SET @PS_FORMULARIO = @FORM_MODAL_HTML;
 
END
