/* ============================================================================
   dbo.VCT_FN_AGENDA_DIAS_JSON
   ----------------------------------------------------------------------------
   Devuelve el JSON (crudo, sin escapar) de la DISPONIBILIDAD por dia del
   consultor en un rango, con cliente / proyecto / servicio(s) para el dia
   ASIGNADO (resueltos desde la visita). Es el mismo contenido que arma la
   pantalla "Agenda del consultor", para poder reusarlo en el calendario de la
   Vista 360 del consultor y que el tooltip muestre los iconos de servicio.

   Campos por dia: f, e, h, hc, t, n, mo, de, cli, proy, srv.
     - cli  = razon social del cliente del proyecto de la visita.
     - proy = (codigo) nombre del proyecto de la visita.
     - srv  = "CO|Consultoria, AU|Auditoria" (codigo|descripcion por servicio
              del proyecto) -> el JS lo dibuja como iconos.
   El que llama escapa el resultado para el atributo HTML (REPLACE & " <).
   Fuente de dias: VCT_FN_AGENDA_CONSULTOR_RANGO. Proyecto del dia asignado:
   VCT_PROYECTOS_VISITAS + VCT_PROYECTOS_VISITAS_CONSULTORES (NO inventa
   asociaciones: el proyecto sale de la visita del consultor en esa fecha).
   Usa FOR XML PATH (compatible compat 100 y 140). Re-ejecutable. Solo lee.
   ============================================================================ */
USE [MuhlePROD];
GO
CREATE OR ALTER FUNCTION dbo.VCT_FN_AGENDA_DIAS_JSON
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
        SELECT ',{"f":"' + CONVERT(VARCHAR(10), R.FECHA, 120)
             + '","e":"' + ISNULL(R.ESTADO,'NO_CARGADO')
             + '","h":'  + CONVERT(VARCHAR(10), CONVERT(DECIMAL(6,1), CASE WHEN R.ESTADO IN ('DISPONIBLE','POTENCIAL','ORGANISMO') THEN ISNULL(AG.HORAS_CAPACIDAD,R.HORAS) ELSE R.HORAS END))
             + ',"hc":'  + CONVERT(VARCHAR(10), CONVERT(DECIMAL(5,2), ISNULL(AG.HORAS_CAPACIDAD,0)))
             + ',"t":"'  + ISNULL(R.TIPO,'')
             + '","n":"' + REPLACE(REPLACE(REPLACE(ISNULL(R.NOTA,''),'\','/'),'"',''''),CHAR(10),' ')
             + '","mo":"'+ REPLACE(REPLACE(REPLACE(ISNULL(R.MOTIVO,''),'\','/'),'"',''''),CHAR(10),' ')
             + '","de":"'+ REPLACE(REPLACE(REPLACE(ISNULL(R.DESCRIPCION,''),'\','/'),'"',''''),CHAR(10),' ')
             + '","cli":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(C2.RAZON_SOCIAL,''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","proy":"'+ REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN P2.ID IS NOT NULL THEN ISNULL('('+NULLIF(LTRIM(RTRIM(P2.CODIGO)),'')+') ','')+ISNULL(P2.NOMBRE,'') ELSE '' END,'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '","srv":"'+ REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(STUFF((
                    SELECT ', '+UPPER(LEFT(ISNULL(S.CODIGO,''),2))+'|'+CONVERT(VARCHAR(200),S.DESCRIPCION)
                    FROM dbo.VCT_PROYECTOS_SERVICIOS PS WITH(NOLOCK)
                    INNER JOIN dbo.VCT_PRM_SERVICIOS S WITH(NOLOCK) ON S.ID=PS.ID_SERVICIO
                    WHERE PS.ID_PROYECTO=VX.ID_PROYECTO
                    ORDER BY S.ID
                    FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,2,''),''),'\','/'),'"',''''),CHAR(10),' '),CHAR(13),' ')
             + '"}'
        FROM dbo.VCT_FN_AGENDA_CONSULTOR_RANGO(@ID_CONSULTOR, @DESDE, @HASTA) R
        LEFT JOIN dbo.VCT_PRM_AGENDA_CONSULTOR AG ON AG.ID_CONSULTOR=@ID_CONSULTOR AND AG.FECHA=R.FECHA
        OUTER APPLY (
            SELECT TOP 1 PV.ID_PROYECTO
            FROM dbo.VCT_PROYECTOS_VISITAS PV WITH(NOLOCK)
            INNER JOIN dbo.VCT_PROYECTOS_VISITAS_CONSULTORES PVC WITH(NOLOCK) ON PVC.ID_VISITA=PV.ID
            WHERE PVC.ID_CONSULTOR=@ID_CONSULTOR
              AND R.FECHA BETWEEN CONVERT(DATE,PV.FECHA_DESDE) AND CONVERT(DATE,ISNULL(PV.FECHA_HASTA,PV.FECHA_DESDE))
            ORDER BY PV.ID DESC
        ) VX
        LEFT JOIN dbo.VCT_PROYECTOS P2 WITH(NOLOCK) ON P2.ID = VX.ID_PROYECTO
        LEFT JOIN dbo.VCT_CLIENTES  C2 WITH(NOLOCK) ON C2.ID = P2.IDCLIENTE
        ORDER BY R.FECHA
        FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 1, ''), '') + ']';

    RETURN @J;
END
GO
