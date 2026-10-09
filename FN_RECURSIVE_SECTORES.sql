USE [MuhlePROD]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_RECURSIVE_SECTORES]    Script Date: 13/9/2026 18:01:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Devuelve una secuencia de <li>...</li> (SIN el <ul> envolvente) para los hijos de @IPADRE_ID.
-- Si un hijo matchea la exclusión (sector "Externos"), no se dibuja su propia tarjeta,
-- pero sus propios hijos (Consultor/Cliente) se "aplanan" al mismo nivel del padre.
ALTER FUNCTION [dbo].[FN_RECURSIVE_SECTORES]
(
    @IPADRE_ID INT,
    @FORM_ID   VARCHAR(100),
    @NIVEL     INT = 1
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @HTML NVARCHAR(MAX) = N'';
    DECLARE @id INT, @nombre NVARCHAR(200), @mail NVARCHAR(300), @area NVARCHAR(200), @cant_users INT;
    DECLARE @VCHILDREN NVARCHAR(MAX);

    DECLARE
        @bg_badge NVARCHAR(20),
        @border_badge NVARCHAR(20),
        @text_badge NVARCHAR(20),
        @border_card NVARCHAR(20),
        @bg_card NVARCHAR(20);

    IF @NIVEL = 1
    BEGIN
        SET @bg_badge = N'#FDFBF7';
        SET @border_badge = N'#E8C2CA';
        SET @text_badge = N'#66062D';
        SET @border_card = N'#DDA8B3';
        SET @bg_card = N'#FFFFFF';
    END
    ELSE IF @NIVEL = 2
    BEGIN
        SET @bg_badge = N'#F8FAFC';
        SET @border_badge = N'#E2E8F0';
        SET @text_badge = N'#8C1D40';
        SET @border_card = N'#E2E8F0';
        SET @bg_card = N'#FAFAFA';
    END
    ELSE
    BEGIN
        SET @bg_badge = N'#F1F5F9';
        SET @border_badge = N'#CBD5E1';
        SET @text_badge = N'#A04A5D';
        SET @border_card = N'#CBD5E1';
        SET @bg_card = N'#F1F5F9';
    END;

    DECLARE curHijos CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            s.Id_Sector,
            s.Desc_Sector,
            s.Mail_Sector,
            a.Desc_Area,
            (
                SELECT COUNT(1)
                FROM dbo.UsersSector us WITH (NOLOCK)
                WHERE us.Id_Sector = s.Id_Sector
            ) AS CantUsers
        FROM dbo.Sectores s WITH (NOLOCK)
        LEFT JOIN dbo.Areas a WITH (NOLOCK)
            ON s.Id_Area = a.Id_Area
        WHERE s.Id_Sector_Padre = @IPADRE_ID
        ORDER BY ISNULL(s.Id_nivel, 1) ASC, s.Desc_Sector ASC;

    OPEN curHijos;
    FETCH NEXT FROM curHijos INTO @id, @nombre, @mail, @area, @cant_users;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (@id = 6 OR UPPER(ISNULL(@nombre, N'')) LIKE '%EXTERNO%' OR UPPER(ISNULL(@nombre, N'')) IN (N'CLIENTE', N'CONSULTOR'))
        BEGIN
            -- Nodo oculto: no se dibuja su tarjeta, pero sus hijos se aplanan al mismo nivel.
            SET @HTML = @HTML + ISNULL(dbo.FN_RECURSIVE_SECTORES(@id, @FORM_ID, @NIVEL), N'');
        END
        ELSE
        BEGIN
            SET @VCHILDREN = ISNULL(dbo.FN_RECURSIVE_SECTORES(@id, @FORM_ID, @NIVEL + 1), N'');

            SET @HTML = @HTML +
                N'<li>' +
                    N'<div class="vct-sector-card" style="border-left-color: ' + @text_badge + N' !important; background-color: ' + @bg_card + N' !important;">' +
                        N'<div class="vct-sector-header">' +
                            N'<div class="vct-sector-title-wrapper" onclick="var li=this.closest(''li'');if(li){var n=li.querySelector(''.vct-nested'');var c=this.querySelector(''.vct-caret'');if(n)n.classList.toggle(''active'');if(c)c.classList.toggle(''active'');}">' +
                                N'<span class="vct-caret" style="background-color: ' + @text_badge + N' !important; display:inline-flex; align-items:center; justify-content:center;">' +
                                    N'<i data-lucide="chevron-right" style="width:14px !important; height:14px !important; stroke:#ffffff !important; color:#ffffff !important;"></i>' +
                                N'</span>' +
                                N'<span class="vct-sector-icon" style="background-color:' + @bg_badge + N' !important; color:' + @text_badge + N' !important; border:1px solid ' + @border_badge + N' !important;">' +
                                    N'<i data-lucide="' + CASE WHEN @NIVEL = 2 THEN N'building-2' ELSE N'folder' END + N'" style="width:15px !important; height:15px !important; stroke:' + @text_badge + N' !important;"></i>' +
                                N'</span>' +
                                N'<span class="vct-sector-title" style="color: #1e293b !important; font-size: 14.5px !important; font-weight: 700 !important;">' + ISNULL(@nombre, N'') + N'</span>' +
                            N'</div>' +

                            N'<div class="vct-dropdown">' +
                                N'<button type="button" class="vct-dropdown-btn" onclick="event.stopPropagation();var m=this.parentElement.querySelector(''.vct-dropdown-menu'');var o=m?m.classList.contains(''is-open''):false;document.querySelectorAll(''.vct-dropdown-menu'').forEach(function(x){x.classList.remove(''is-open'');});if(!o&&m)m.classList.add(''is-open'');">' +
                                    N'<i data-lucide="more-vertical"></i>' +
                                N'</button>' +
                                N'<div class="vct-dropdown-menu">' +
                                    N'<a class="vct-dropdown-item" onclick="almacenarSeleccion(''ID_SECTOR_SEL'', ''' + CONVERT(VARCHAR, @id) + ''');almacenarSeleccion(''ACTION'', ''EDITAR'');goto(''' + @FORM_ID + ''',''BB9BCDF4-39AD-4118-8AE1-C25BCA95FBD1'');">' +
                                        N'<i data-lucide="edit-2"></i> <span>Editar Sector</span>' +
                                    N'</a>' +
                                    N'<a class="vct-dropdown-item" onclick="almacenarSeleccion(''ID_SECTOR_SEL'', ''' + CONVERT(VARCHAR, @id) + ''');goto(''' + @FORM_ID + ''',''4091398D-5D55-4C84-BF0A-4A67E4D0EE0A'');">' +
                                        N'<i data-lucide="users"></i> <span>Ver Usuarios (' + CONVERT(VARCHAR, @cant_users) + N')</span>' +
                                    N'</a>' +
                                N'</div>' +
                            N'</div>' +
                        N'</div>' +

                        N'<div class="vct-sector-meta">' +
                            CASE
                                WHEN ISNULL(@mail, N'') <> N'' THEN
                                    N'<span style="background-color:' + @bg_badge + N' !important; color:' + @text_badge + N' !important; border: 1px solid ' + @border_badge + N' !important; padding:3px 10px !important; border-radius:6px !important; font-size:11.5px !important; font-weight:500 !important; display:inline-flex !important; align-items:center !important; gap:5px !important; line-height:1.2 !important;">' +
                                        N'<i data-lucide="mail" style="width:12px !important; height:12px !important; stroke:' + @text_badge + N' !important;"></i> ' + @mail +
                                    N'</span>'
                                ELSE N''
                            END +
                            CASE
                                WHEN ISNULL(@cant_users, 0) > 0 THEN
                                    N'<span style="background-color:' + @bg_badge + N' !important; color:' + @text_badge + N' !important; border: 1px solid ' + @border_badge + N' !important; padding:3px 10px !important; border-radius:6px !important; font-size:11.5px !important; font-weight:500 !important; display:inline-flex !important; align-items:center !important; gap:5px !important; line-height:1.2 !important;">' +
                                        N'<i data-lucide="users" style="width:12px !important; height:12px !important; stroke:' + @text_badge + N' !important;"></i> ' + CONVERT(VARCHAR, @cant_users) + N' Integrantes' +
                                    N'</span>'
                                ELSE N''
                            END +
                        N'</div>' +
                    N'</div>' +
                    CASE WHEN @VCHILDREN <> N'' THEN N'<ul class="vct-nested">' + @VCHILDREN + N'</ul>' ELSE N'' END +
                N'</li>';
        END;

        FETCH NEXT FROM curHijos INTO @id, @nombre, @mail, @area, @cant_users;
    END;

    CLOSE curHijos;
    DEALLOCATE curHijos;

    RETURN @HTML;
END
