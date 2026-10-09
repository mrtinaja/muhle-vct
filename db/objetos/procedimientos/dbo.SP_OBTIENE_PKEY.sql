 
-- ============================================================================================
-- Autor: Andres Volpi
-- Fecha de creacion: 07/04/2005
-- Ultima modificacion: 07/04/2005
-- Ultima modificacion por: Andres Volpi
-- Tablas afectadas de lectura: 
-- Tablas afectadas de modificacion: PHYSICAL_JOB, DSS_TBPHYSICAL_JOB, ATTENDED_CUSTOMER, DSS_TBATTENDED_CUSTOMER
-- Descripcion: Cambia la fecha default de vencimiento del tramite por la fecha calculada en base al motivo y submotivo.
-- Tambien utilazamos este store para el tramite de actividad de contacto, actualizando la fecha de vencimiento del tramite a partir de la fecha ingresada por el usuario.
-- ============================================================================================
 
 
-- ============================================================================================
-- Autor: Andres Volpi
-- Fecha de creacion: 22/04/2005
-- Ultima modificacion: 22/04/2005
-- Ultima modificacion por: Andres Volpi
-- Tablas afectadas de lectura: PHYSICAL_NOTES, PHYSICAL_ATTACHED_DOCUMENT
-- Tablas afectadas de modificacion: 
-- Descripcion: Dada una pkey , obtiene la cantida de archivos adjuntos y notas de la pkey relacionada. Para Clientes.
-- ============================================================================================ 
 
 
CREATE PROCEDURE [dbo].[SP_OBTIENE_PKEY] 
@pllave   varchar(50),
@Pkey  varchar (50) output
 
AS
  SET XACT_ABORT ON  --SENTENCIA AGREGADA ya que de lo contrario, si cancela la ejecución del 
--proceso almacenado, la conexión a la base de datos queda abierta y los 
--recursos bloqueados.
    begin tran 
     select @Pkey = PRM_VAL from prm (HOLDLOCK)  where PRM_COD = @pllave;
    UPDATE PRM SET PRM_VAL=  convert(varchar(50), convert(numeric,PRM_VAL) +1 )
    WHERE PRM_COD= @pllave ;
 
    IF @@error <> 0 BEGIN ROLLBACK TRANSACTION RETURN @@error END
 
	select @Pkey = PRM_VAL from prm where PRM_COD = @pllave;
    commit tran
return
 
