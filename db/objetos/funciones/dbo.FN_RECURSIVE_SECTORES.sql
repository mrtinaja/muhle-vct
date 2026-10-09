 
-- Devuelve una secuencia de <li>...</li> (SIN el <ul> envolvente) para el arbol de dbo.[Groups].
CREATE FUNCTION [dbo].[FN_RECURSIVE_SECTORES]
(
    @IPADRE_ID VARCHAR(100),
    @FORM_ID   VARCHAR(100),
    @NIVEL     INT = 1
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @HTML NVARCHAR(MAX) = N'';
    DECLARE @id VARCHAR(100), @nombre NVARCHAR(200), @mail NVARCHAR(300), @area NVARCHAR(200), @cant_users INT;
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
            X.ID,
            X.NAME,
            X.EMAIL,
            NULL AS Desc_Area,
            0 AS CantUsers
        FROM (
            SELECT
                0 AS NIVEL,
                CAST('VOCATURO' AS VARCHAR(100)) AS ID,
                CAST(N'Vocaturo' AS NVARCHAR(200)) AS NAME,
                CAST(N'/muhle-vct/img/VfondoBordo.png' AS NVARCHAR(300)) AS EMAIL
            UNION ALL
            SELECT
                CASE WHEN ID = 'GERENCIA' THEN 1 ELSE 2 END AS NIVEL,
                CAST(ID AS VARCHAR(100)) AS ID,
                CAST(NAME AS NVARCHAR(200)) AS NAME,
                CAST(EMAIL AS NVARCHAR(300)) AS EMAIL
            FROM dbo.[Groups] WITH (NOLOCK)
            WHERE Id <> 'SQUAD'
        ) X
        WHERE
            (@IPADRE_ID = 'VOCATURO' AND X.NIVEL = 1)
            OR (@IPADRE_ID = 'GERENCIA' AND X.NIVEL = 2)
        ORDER BY X.NIVEL ASC, X.NAME ASC;
 
    OPEN curHijos;
    FETCH NEXT FROM curHijos INTO @id, @nombre, @mail, @area, @cant_users;
 
    WHILE @@FETCH_STATUS = 0
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
 
        FETCH NEXT FROM curHijos INTO @id, @nombre, @mail, @area, @cant_users;
    END;
 
    CLOSE curHijos;
    DEALLOCATE curHijos;
 
    RETURN @HTML;
END
