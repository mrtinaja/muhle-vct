 
 
-- EXECUTE [dbo].[SAT_BATCH_DEPURA]  1
-- =============================================
-- Author:		EDM
-- Create date: 2020-05-10
-- Description:	CORRIDA BATCH DEPURACION DIARIA
-- =============================================
CREATE PROCEDURE [dbo].[SAT_BATCH_DEPURA] (@NROJOB NUMERIC(18)) AS
 
DECLARE @FechaDesde DATETIME
DECLARE @NROJOBPASO NUMERIC(18)
 
BEGIN
 
	SET @FechaDesde = GETDATE()-1
 
	BEGIN TRANSACTION
 
		DELETE FROM PHYSICAL_CALL_CONV_STEPS
		DELETE FROM PHYSICAL_CALL_TRANSACTIONS
		DELETE FROM EDA_REGISTRO_SUCESOS
		DELETE FROM DSS_TBPHYSICAL_CALL_CONV_STEPS
 
		DELETE FROM DSS_TBPHYSICAL_CALL where PKEY_PHYSICAL_JOB in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM PHYSICAL_CALL where par_key in 
			( select pkey from ATTENDED_CUSTOMER where PKEY_JOB in
				 ( select pkey from PHYSICAL_JOB where job_state_date<@FechaDesde))
 
		DELETE FROM ATTENDED_CUSTOMER where PKEY_JOB in 
			( select pkey from PHYSICAL_JOB where job_state_date<@FechaDesde)
 
		DELETE FROM DSS_TBATTENDED_CUSTOMER where PKEY_PHYSICAL_JOB in
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM TMT_SV_01 where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
		
		DELETE FROM TMT_SV_02 where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM TMT_SV_03 where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM TMT_SV_04 where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM TMT_SV_05 where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM XAGENDA where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM XAGENDA_VISITAS where par_key in 
			(select pkey_PHYSICAL_JOB from DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde)
 
		DELETE FROM DSS_TBPHYSICAL_JOB where job_state_date_time<@FechaDesde
	
		DELETE FROM PHYSICAL_JOB where job_state_date<@FechaDesde
 
	COMMIT TRANSACTION
 
END
