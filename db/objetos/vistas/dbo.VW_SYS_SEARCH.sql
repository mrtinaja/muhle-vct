 
CREATE view [dbo].[VW_SYS_SEARCH] as
 
SELECT '<a href="javascript:newTaskForContactWithParams(''' + A.PAR_KEY + ''', ''PKEY_CONTACTO=' + A.PKEY + ''', ''ABM_ADHERENTES'',''' + NOMBRE+', '+APELLIDO + ''')">Editar</a>' as Accion, 
TIPO_DOC+NRO_DOC AS Identificador,  NOMBRE+', '+APELLIDO AS Nombre, ESTADO AS Tipo, 
TELEFONO AS 'Telefono', EMAIL AS 'Email', DOMICILIO AS 'Domicilio', LOCALIDAD AS 'Localidad', 
PROVINCIA AS 'Provincia', C.CUST_TYPE_CODE as TipoCliente FROM ADHERENTES a inner join CUSTOMER c on c.PKEY = a.PAR_KEY
 
 
 
 
