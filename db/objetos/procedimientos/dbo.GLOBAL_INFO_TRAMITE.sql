 
-- =============================================
-- Author:		<Esteban De Marco>
-- Create date: <11/02/2011>
-- Description:	<SP para mostrar datos generales de un Proceso>
-- =============================================
CREATE PROCEDURE [dbo].[GLOBAL_INFO_TRAMITE] 
	(
		@IPKEYJOB	AS VARCHAR(100), 
		@IJOBSEQ	AS INT,
		@IAGENTE	AS VARCHAR(100),
		@IUNIDAD	AS VARCHAR(100)
	)
AS
 
DECLARE @UNITDESC AS VARCHAR(300),
		@USERDESC AS VARCHAR(300)
 
BEGIN
 
	SELECT	TOP 1 @UNITDESC = UNIT_DESCRIPTION
	FROM	ORGANIZATION
	WHERE	UNIT_CODE = @IUNIDAD;
 
	SELECT	TOP 1 @USERDESC = A.NOMBRE
	FROM	(
			SELECT	TOP 1 USER_NAME AS NOMBRE
			FROM	AGENTE
			WHERE	USER_ID = @IAGENTE
			UNION
			SELECT	TOP 1 SUPERVISOR_NAME AS NOMBRE
			FROM	SUPERVISOR
			WHERE	SUPERVISOR_CODE = @IAGENTE) A
 
	SELECT  '<font style="font-family:Tahoma, Arial, Helvetica, sans-serif;font-size:8;color:#000000;text-align: center">'
		+'<b>Nro Proceso: </b>'+'<font style="font-size:8;color:#003D7A">'+'<b>'+ CONVERT(VARCHAR,@IJOBSEQ)		 +'</b></font> - '
        +'<b>Usuario: </b>'+@USERDESC								 +' - '
		+'<b>Perfil: </b>'+@UNITDESC								 +' - '
        +'<b>Fecha: </b>' +CONVERT(VARCHAR, GETDATE(), 103)			 +' '
							+CONVERT(VARCHAR,GETDATE(),108)			 +
        +'<img src="./../img/blank.gif" width="1" height="1" '
        +'onload="var a=this.parentNode.parentNode.parentNode.parentNode.parentNode;a.removeChild(a.firstChild);'
        --+'a.parentNode.style.border=1;a.firstChild.firstChild.firstChild.className='''';'
        +'a.firstChild.firstChild.firstChild.style.textAlign=''right'';"'
        +'/>'
        +'</font>' --"<B>INFO</B>";
	
END
 
 
