/* Ejecuta VCT_MAIN_REPORTES directo con los mismos parametros del error.
   SSMS va a mostrar en la pestaña Messages algo como:
     Msg 8152, Level 16, State 30, Procedure VCT_MAIN_REPORTES, Line NNN
   Pasame ese numero de Line (y el Msg completo). */
USE [MuhlePROD]
GO

DECLARE @O1 VARCHAR(MAX), @O2 VARCHAR(MAX), @O3 VARCHAR(MAX);

EXEC [dbo].[VCT_MAIN_REPORTES]
    @IPKEYJOB  = '254aef80-0868-418e-aa91-58b421944253',
    @FORM_ID   = 'step_7dffc30d_9ac9_43dc_a1f7_f2ff702888d0',
    @IUNIDAD   = 'GERENCIA',
    @IAGENTE   = 'avocaturo',
    @OUTPARAM1 = @O1 OUTPUT,
    @OUTPARAM2 = @O2 OUTPUT,
    @OUTPARAM3 = @O3 OUTPUT;
GO
