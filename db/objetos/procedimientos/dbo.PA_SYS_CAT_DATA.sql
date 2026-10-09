CREATE PROCEDURE [dbo].[PA_SYS_CAT_DATA]
 
@PKEY_JOB VARCHAR(100)
 
AS
 
BEGIN
 
 
 
SELECT   '<INPUT TYPE="Radio" onclick="almacenarSeleccion(''PKEY_ELEM'',''' + CD.PKEY + ''')" NAME="seleccion"/>' AS'<B>*</B>',
 
         '<B>Sel</B>' = CASE 
 
                            WHEN TMT.PKEY_ELEM = CD.PKEY THEN '*'
 
                            ELSE ''
 
                            END,
		CD.CAT_DATA_CODE AS '<B>CODIGO</B>',
 
         CD.CAT_DATA_DESC AS '<B>DESCRIPCION</B>',
 
         CD.ATTR1 AS '<B>AT.01</B>',
 
         CD.ATTR2 AS '<B>AT.02</B>',
 
         CD.ATTR3 AS '<B>AT.03</B>',
 
         CD.ATTR4 AS '<B>AT.04</B>',
 
         CD.ATTR5 AS '<B>AT.05</B>',
 
         CD.ATTR6 AS '<B>AT.06</B>',
 
         --CD.ATTR7 AS '<B>AT.07</B>',
 
         --CD.ATTR8 AS '<B>AT.08</B>',
 
         --CD.ATTR9 AS '<B>AT.09</B>',
 
         --CD.ATTR10 AS '<B>AT.10</B>',
 
         CASE CD.CAT_INACTIVE
 
              WHEN '0' THEN 'SI'
 
              WHEN '1' THEN 'NO'
 
              ELSE '-'
 
         END
 
              AS '<B>VIGENCIA</B>'
 
     FROM     CAT_DATA CD,  TMT_CATEGORIAS TMT
 
     WHERE    TMT.PAR_KEY = @PKEY_JOB
 
         AND CD.PAR_KEY = TMT.PKEY_CATEG
         --AND CD.CAT_INACTIVE = '0'
 
     ORDER BY cd.CAT_INACTIVE ASC, cd.CAT_DATA_DESC asc
 
 
END
 
 
 
