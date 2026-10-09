 
CREATE PROCEDURE [dbo].[HOME_BUILD_TITLE_HEADER]
    @I_TITULO          VARCHAR(100) = 'Gestión',
    @I_ICONO_TITULO    VARCHAR(50)  = 'fa fa-folder-open',
    @I_FORM_ID         VARCHAR(50)  = NULL,
    @I_ACTION_GUID     VARCHAR(50)  = 'USUARIOS',
    @I_ID_SELECCIONADO VARCHAR(50)  = NULL,
    
    @I_TEXTO_NUEVO     VARCHAR(50)  = 'Agregar Nuevo',
    @I_ICONO_NUEVO     VARCHAR(50)  = 'plus-circle',
    @I_TITLE_NUEVO     VARCHAR(50)  = 'Nuevo Registro',
    
    @I_TEXTO_EDITAR    VARCHAR(50)  = 'Editar Registro',
    @I_ICONO_EDITAR    VARCHAR(50)  = 'edit',
    @I_TITLE_EDITAR    VARCHAR(50)  = 'Modificar Registro Seleccionado',
    
    @I_ONCLICK_CUSTOM  VARCHAR(250) = NULL,
    @I_SELECT_HTML     VARCHAR(MAX) = NULL,
    @O_HTML_TITULO     VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ICONO_NATIVE VARCHAR(50);
    DECLARE @ACTION_FORM  VARCHAR(100);
    DECLARE @TITULO_CLEAN VARCHAR(100);
    DECLARE @NUEVO_CLEAN  VARCHAR(50);
 
    SET @ICONO_NATIVE = ISNULL(@I_ICONO_TITULO, 'fa fa-folder-open');
    IF @ICONO_NATIVE NOT LIKE 'fa %' AND @ICONO_NATIVE NOT LIKE 'fas %' AND @ICONO_NATIVE NOT LIKE 'far %'
    BEGIN
        SET @ICONO_NATIVE = 'fa fa-' + @ICONO_NATIVE;
    END
 
    SET @ACTION_FORM = LTRIM(RTRIM(ISNULL(@I_ACTION_GUID, '')));
    IF @ACTION_FORM = '' SET @ACTION_FORM = 'USUARIOS';
 
    -- Declaración e inicialización correcta para evitar error de sintaxis T-SQL
    SET @TITULO_CLEAN = REPLACE(ISNULL(@I_TITULO, 'Gestión'), '''', '');
    SET @NUEVO_CLEAN  = REPLACE(ISNULL(@I_TEXTO_NUEVO, 'Agregar Nuevo'), '''', '');
 
    SET @O_HTML_TITULO = '
    <style>
        .vct-header-card {
            width: 100% !important;
            margin: 0 0 16px 0 !important;
            padding: 0 !important;
            border-radius: 12px !important;
            overflow: hidden !important;
            box-shadow: 0 4px 20px rgba(15, 23, 42, 0.08) !important;
            border: 1px solid #e2e8f0 !important;
            background: #ffffff !important;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
        }
 
        .vct-header-bar {
            background: linear-gradient(135deg, #66062C 0%, #4a031f 100%) !important;
            color: #ffffff !important;
            padding: 16px 24px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            margin: 0 !important;
        }
 
        .vct-header-title {
            font-size: 15px !important;
            font-weight: 800 !important;
            display: flex !important;
            align-items: center !important;
            gap: 12px !important;
            color: #ffffff !important;
            letter-spacing: .04em !important;
            text-transform: uppercase !important;
            margin: 0 !important;
        }
 
        .vct-tabs-bar-native {
            display: flex !important;
            align-items: center !important;
            gap: 8px !important;
            background: #f1f5f9 !important;
            padding: 8px 16px 0 16px !important;
            border-bottom: 1px solid #e2e8f0 !important;
            width: 100% !important;
            box-sizing: border-box !important;
        }
 
        .vct-tab-item {
            display: inline-flex !important;
            align-items: center !important;
            gap: 8px !important;
            padding: 9px 18px !important;
            background: #e2e8f0 !important;
            color: #64748b !important;
            font-size: 12px !important;
            font-weight: 600 !important;
            border-radius: 8px 8px 0 0 !important;
            cursor: pointer !important;
            user-select: none !important;
            border: 1px solid #cbd5e1 !important;
            border-bottom: none !important;
            transition: all 0.15s ease !important;
        }
 
        .vct-tab-item.active {
            background: #ffffff !important;
            color: #66062C !important;
            font-weight: 700 !important;
            border-color: #e2e8f0 !important;
            margin-bottom: -1px !important;
            padding-bottom: 10px !important;
        }
 
        .vct-tab-btn-add {
            display: inline-flex !important;
            align-items: center !important;
            justify-content: center !important;
            min-width: 28px !important;
            height: 28px !important;
            border-radius: 6px !important;
            background: #ffffff !important;
            color: #66062C !important;
            border: 1px solid #cbd5e1 !important;
            cursor: pointer !important;
            font-size: 13px !important;
            font-weight: bold !important;
            margin-bottom: 2px !important;
            transition: all 0.2s ease !important;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1) !important;
            outline: none !important;
        }
 
        .vct-tab-btn-add:hover {
            background: #66062C !important;
            color: #ffffff !important;
            border-color: #66062C !important;
            transform: scale(1.08);
        }
    </style>
 
    <div class="vct-header-card">
        <div class="vct-header-bar">
            <div class="vct-header-title">
                <i class="' + @ICONO_NATIVE + '"></i>
                <span>' + @TITULO_CLEAN + '</span>
            </div>
        </div>
 
        <div id="vctTabsBar" class="vct-tabs-bar-native">
            <div class="vct-tab-item active" data-tab-id="tab-grid" onclick="if(window.VctTabEngine){ window.VctTabEngine.switchTab(''tab-grid''); } return false;">
                <i class="fa fa-table"></i>
                <span>' + @TITULO_CLEAN + '</span>
            </div>
 
            <button type="button" id="vctBtnNewTabPlus" class="vct-tab-btn-add" title="Agregar Nueva Pestaña" onclick="if(window.VctTabEngine){ window.VctTabEngine.openTab({ action: ''' + @ACTION_FORM + ''', title: ''' + @NUEVO_CLEAN + ''' }, event); } return false;">
                <i class="fa fa-plus"></i>
            </button>
        </div>
    </div>';
 
END
