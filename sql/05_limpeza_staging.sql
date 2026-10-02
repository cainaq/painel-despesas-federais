/* =========================================================
   05 - Limpeza do staging
   ---------------------------------------------------------
   Remove aspas literais e caracteres CR/LF que ficaram
   grudados nos valores (resíduo do processo de importação
   antes de corrigirmos o BULK INSERT).

   Também remove linhas vazias no fim do CSV.
   ========================================================= */

USE Transparencia;
GO

-- 1. Limpar aspas em todas as colunas de texto e valor
UPDATE dbo.stg_execucao
SET
    [Ano e mês do lançamento] = REPLACE(REPLACE([Ano e mês do lançamento], '"', ''), CHAR(13), ''),
    [Nome Órgão Superior]     = REPLACE([Nome Órgão Superior], '"', ''),
    -- ... (todas as 47 colunas)
    [Valor Pago (R$)]         = REPLACE([Valor Pago (R$)], '"', '');
GO

-- 2. Remover linhas vazias
DELETE FROM dbo.stg_execucao
WHERE [Ano e mês do lançamento] IS NULL
   OR LTRIM(RTRIM([Ano e mês do lançamento])) = ''
   OR LTRIM(RTRIM([Ano e mês do lançamento])) NOT LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]';
GO

-- 3. Conferência
SELECT COUNT(*) AS datas_invalidas
FROM dbo.stg_execucao
WHERE TRY_CONVERT(DATE, CONCAT(LEFT([Ano e mês do lançamento],4),'-',RIGHT([Ano e mês do lançamento],2),'-01')) IS NULL;
GO