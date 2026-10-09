 
CREATE PROCEDURE OBTIENE_PKEY 
@pllave  varchar(50)
AS
  SET XACT_ABORT ON  --SENTENCIA AGREGADA ya que de lo contrario, si cancela la ejecución del 
--proceso almacenado, la conexión a la base de datos queda abierta y los 
--recursos bloqueados.
    begin tran 
    select PRM_VAL from prm (HOLDLOCK)  where PRM_COD = @pllave;
    UPDATE PRM SET PRM_VAL=  convert(varchar(50), convert(numeric,PRM_VAL) +1 )
    WHERE PRM_COD= @pllave ;
 
    IF @@error <> 0 BEGIN ROLLBACK TRANSACTION RETURN @@error END
 
    select PRM_VAL from prm where PRM_COD = @pllave;
    commit tran
return
