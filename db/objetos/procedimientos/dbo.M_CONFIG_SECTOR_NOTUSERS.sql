CREATE   PROCEDURE [dbo].[M_CONFIG_SECTOR_NOTUSERS]
(@IPKEYJOB	AS VARCHAR(100),
 @IUSERID	AS VARCHAR(100),
 @FORM_ID   AS VARCHAR(100)
) AS
 
BEGIN	
 
	declare @ID_SECTOR_SEL VARCHAR(50)
 
	SELECT @ID_SECTOR_SEL = ID_SECTOR_SEL FROM M_CONFIG WHERE PAR_KEY = @IPKEYJOB;
	
	SELECT
	'<div align="left">' + u.Id +'</div>' AS '<div align="left">Usuario</div>',
	'<div align="left">' + u.Name  +'</div>'  AS '<div align="left">Nombre</div>',
	'<div align="left">' + u.Email +'</div>' AS '<div align="left">Email</div>',
	'<div align="left">' + case when u.State=1 then '<font color="green">' else '<font color="red">' end + cd.cat_data_desc + '</font></div>'  AS '<div align="left">Estado</div>',
	'<div align="left">' + u.Phone  +'</div>'  AS '<div align="left">Telefono</div>',
	'<i class="fas fa-user-plus w3-text-blue" style="cursor:pointer;font-size:14px;" title="Agregar ROL User" onclick="almacenarSeleccion( ''ID_USER_SEL'', ''U'+Id+''');next('''+@FORM_ID+''')"></i>&nbsp;&nbsp;&nbsp;&nbsp;
	 <i class="fas fa-user-secret w3-text-orange" style="cursor:pointer;font-size:14px;" title="Agregar ROL Supervisor" onclick="almacenarSeleccion( ''ID_USER_SEL'', ''S'+Id+''');next('''+@FORM_ID+''')"></i>' AS '<div align="left">Agregar</div>'
	FROM Users u
	left outer join cat_data cd on convert(varchar,u.State)=cd.ATTR1 and cd.PAR_KEY='3ECEABE3-13FD-4779-ADE7-CDECF2EC3992' 
	where Id not in (
				select Id_user from UsersSector 
				WHERE CAST(ID_Sector AS VARCHAR)=@ID_sector_SEL) order by id
 
END
