CREATE PROCEDURE PA_SYS_MAX_END_DATE
@pnDias AS INTEGER,
@pnHoras AS INTEGER,
@pnMinutos AS INTEGER,
@psTipoAct AS VARCHAR(20), 
@psTipoTmT AS VARCHAR(20),
@psMotivo AS VARCHAR(50),
@psSubMotivo AS VARCHAR(50),
@psPrioridad AS VARCHAR(50),
@psKeyJob AS VARCHAR(100),
@psKeyAttCust AS VARCHAR(100),
@pnMinutosCalculados AS INTEGER OUTPUT --DEVUELVE EL VALOR EN MINUTOS
AS
 
        IF @pnDias=0 AND @pnHoras=0 AND @pnMinutos=0
        BEGIN
        	SET @pnMinutosCalculados = 1440000
        END
        ELSE
        BEGIN
		SET @pnMinutosCalculados= (@pnMinutos+(@pnHoras*60)+(@pnDias*1440))
        END 
 
SELECT @pnMinutosCalculados
