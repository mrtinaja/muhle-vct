 
CREATE PROCEDURE [dbo].[PA_SYS_CAT_TYPE_GROUPS]
 
@PKEY_JOB     VARCHAR(100),
 
@FILTRO_GRUPO VARCHAR(100)
 
AS
 
 
 
     --SELECT        '<INPUT TYPE="Radio" onclick="almacenarSeleccion(''PKEY_GROUP'',''' + CTG.PKEY + '''),
 
     --              almacenarSeleccion(''PKEY_CATEG'',''' + '' + '''),
 
     --              almacenarSeleccion(''PKEY_ELEM'',''' + '' + '''),
 
     --              almacenarSeleccion(''HABILITACION_ITEM'','''+''+''+'''),
 
     --              almacenarSeleccion(''CODE_ITEM'','''+''+''+'''),
 
     --              almacenarSeleccion(''DESC_ITEM'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_01'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_02'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_03'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_04'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_05'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_06'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_07'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_08'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_09'','''+''+''+'''),
 
     --              almacenarSeleccion(''AT_10'','''+''+''+''')
 
     --              " NAME="seleccion"/>' AS'<B>*</B>',
 
     --              '<B>Sel</B>' = CASE 
 
     --                       WHEN PKEY_GROUP = CTG.PKEY THEN 'X'
 
     --                       ELSE ''
 
     --                       END,
 
     --         CTG.CAT_TYPE_GROUP_CODE AS '<B>CODIGO</B>',
 
     --         CTG.CAT_TYPE_GROUP_DESC AS '<B>DESCRIPCION</B>',
 
     --         (SELECT COUNT(T.CAT_TYPE_GROUP) FROM CAT_TYPE T WHERE CTG.Pkey = T.CAT_TYPE_GROUP AND T.CAT_LEVEL = 1) AS '<B>CANT. CATEGORIAS</B>'
 
     --FROM     CAT_TYPE_GROUP CTG, TMT_CATEGORIAS TMT
 
     --WHERE TMT.PAR_KEY = @PKEY_JOB
 
     --AND ((@FILTRO_GRUPO = 'A' AND CTG.CAT_TYPE_GROUP_CODE IN ('Agrupamientos'))
 
     --OR (@FILTRO_GRUPO = 'B' AND CTG.CAT_TYPE_GROUP_CODE IN ('Automotriz'))
 
     --OR (@FILTRO_GRUPO = 'TODOS' AND CTG.CAT_TYPE_GROUP_CODE NOT IN ('NOAPLICA')))
 
     --ORDER BY CTG.CAT_TYPE_GROUP_DESC
 
  SELECT        '<INPUT TYPE="Radio" onclick="almacenarSeleccion(''PKEY_GROUP'',''' + CTG.PKEY + ''')" NAME="seleccion"/>' AS'<B>*</B>',
 
                   '<B>Sel</B>' = CASE 
 
                            WHEN PKEY_GROUP = CTG.PKEY THEN 'X'
 
                            ELSE ''
 
                            END,
 
              CTG.CAT_TYPE_GROUP_CODE AS '<B>CODIGO</B>',
 
              CTG.CAT_TYPE_GROUP_DESC AS '<B>DESCRIPCION</B>',
 
              (SELECT COUNT(T.CAT_TYPE_GROUP) FROM CAT_TYPE T WHERE CTG.Pkey = T.CAT_TYPE_GROUP AND T.CAT_LEVEL = 1) AS '<B>CANT. CATEGORIAS</B>'
 
     FROM     CAT_TYPE_GROUP CTG, TMT_CATEGORIAS TMT
 
     WHERE TMT.PAR_KEY = @PKEY_JOB
 
     AND ((@FILTRO_GRUPO = 'A' AND CTG.CAT_TYPE_GROUP_CODE IN ('Agrupamientos'))
 
     OR (@FILTRO_GRUPO = 'B' AND CTG.CAT_TYPE_GROUP_CODE IN ('Automotriz'))
 
     OR (@FILTRO_GRUPO = 'TODOS' AND CTG.CAT_TYPE_GROUP_CODE NOT IN ('NOAPLICA')))
 
     ORDER BY CTG.CAT_TYPE_GROUP_DESC
 
