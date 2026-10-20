/* ============================================================================
   dbo.VCT_FN_AGENDA_ACTS_JSON
   ----------------------------------------------------------------------------
   Devuelve el JSON (crudo, sin escapar) de las actividades del consultor en un
   rango, con cliente / proyecto / servicio(s) para el tooltip-tarjeta del
   calendario (el mismo que usa Acciones). El que llama escapa el resultado para
   el atributo HTML (REPLACE & y ").

   Campos por actividad: id, f, hd, hh, t, ti, su, cli, proy, srv, r, ri, c.
     - r / ri = nombre e iniciales del consultor de esta agenda.
     - srv = "CO|Consultoria, AU|Auditoria" (codigo|descripcion por servicio).
   Fuente: VCT_FN_AGENDA_ACTIVIDADES_RANGO (trae ID_PROYECTO / ID_CLIENTE).
   Usa FOR XML PATH para concatenar (compatible compat 100 y 140).
   Re-ejecutable (CREATE OR ALTER). Solo lee.
   ============================================================================ */
USE [MuhlePROD];
GO
CREATE OR ALTER FUNCTION dbo.VCT_FN_AGENDA_ACTS_JSON
(
    @ID_CONSULTOR INT,
    @DESDE        DATE,
    @HASTA        DATE
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @J VARCHAR(MAX);

    SET @J = '[' + ISNULL(STUFF((
        SELECT ',{"id":' + CONVERT(VARCHAR(12), A.ID)
             + ',"f":"'  + CONVERT(VARCHAR(10), A.FECHA, 120)
             + '","hd":"'+ A.HD
             + '","hh":"'+ A.HH
             + '","t":"' + A.TIPO
             + '","ti":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(A.TITULO,''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","su":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(A.SUBTITULO,''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","cli":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C.RAZON_SOCIAL,''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","proy":"'+ REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN P.ID IS NOT NULL THEN ISNULL('('+NULLIF(LTRIM(RTRIM(P.CODIGO)),'')+') ','')+ISNULL(P.NOMBRE,'') ELSE '' END,'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","srv":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(STUFF((
                    SELECT ', '+UPPER(LEFT(ISNULL(S.CODIGO,''),2))+'|'+CONVERT(VARCHAR(200),S.DESCRIPCION)
                    FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
                    INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID=PS.ID_SERVICIO
                    WHERE PS.ID_PROYECTO=A.ID_PROYECTO
                    ORDER BY S.ID
                    FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,2,''),''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","r":"'+ REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(CO.APELLIDOS,'')+CASE WHEN NULLIF(LTRIM(RTRIM(CO.NOMBRES)),'') IS NOT NULL AND NULLIF(LTRIM(RTRIM(CO.APELLIDOS)),'') IS NOT NULL THEN ', ' ELSE '' END+ISNULL(CO.NOMBRES,''))),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","ri":"'+ REPLACE(REPLACE(REPLACE(REPLACE(UPPER(LEFT(LTRIM(ISNULL(CO.NOMBRES,'')),1)+LEFT(LTRIM(ISNULL(CO.APELLIDOS,'')),1)),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","c":"' + ISNULL(A.COLOR,'') + '"}'
        FROM dbo.VCT_FN_AGENDA_ACTIVIDADES_RANGO(@ID_CONSULTOR, @DESDE, @HASTA) A
        LEFT JOIN dbo.VCT_PROYECTOS P WITH(NOLOCK) ON P.ID = A.ID_PROYECTO
        LEFT JOIN dbo.VCT_CLIENTES  C WITH(NOLOCK) ON C.ID = ISNULL(P.IDCLIENTE, A.ID_CLIENTE)
        LEFT JOIN dbo.VCT_CONSULTORES CO WITH(NOLOCK) ON CO.ID = @ID_CONSULTOR
        ORDER BY A.FECHA, A.HD
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 1, ''), '') + ']';

    RETURN @J;
END
GO
