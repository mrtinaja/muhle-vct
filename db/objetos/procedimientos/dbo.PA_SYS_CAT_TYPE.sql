CREATE PROCEDURE [dbo].[PA_SYS_CAT_TYPE]
 
@PKEY_JOB VARCHAR(100)
 
 
 
AS
 
DECLARE @GRUPO     VARCHAR(20)
 
     SELECT  '<INPUT TYPE="Radio" onclick="almacenarSeleccion(''PKEY_CATEG'',''' + CT.PKEY + ''')" NAME="seleccion"/>' AS'<B>*</B>',
 
              '<B>Sel</B>' = CASE 
 
                            WHEN TMT.PKEY_CATEG = CT.PKEY THEN '*'
 
                            ELSE ''
 
                            END,
 
         CT.CAT_TYPE_CODE AS '<B>CODIGO</B>',
 
         CT.CAT_TYPE_DESC AS '<B>DESCRIPCION</B>',
 
         (SELECT COUNT(CD.PKEY) FROM CAT_DATA CD WHERE CT.PKEY = CD.PAR_KEY) AS '<B>CANT. ELEMENTOS</B>'
 
     FROM CAT_TYPE CT,
 
         TMT_CATEGORIAS TMT
 
     WHERE    TMT.PAR_KEY = @PKEY_JOB
 
         AND CT.CAT_TYPE_GROUP = '1AC7D389-E48E-40BE-AA3E-F7E4BCD3B932'
         AND CT.CAT_TYPE_CODE IN ('PRESTADOR_DESTINO', 'PRESTACIONES')
 
         AND CAT_LEVEL = 1
         
 
 
 
 
 
