/* =========================================================
   07 - Popular a fato
   ---------------------------------------------------------
   Converte os dados do staging para os tipos finais:
   - data: TRY_CONVERT(DATE, 'AAAA-MM-01')
   - valor: TRY_CAST com REPLACE de ',' para '.'
   - sentinela 'Sem informaçăo' vira NULL
   - linhas com data inválida são ignoradas
   ========================================================= */

USE Transparencia;
GO

TRUNCATE TABLE dbo.fato_despesa;
GO

INSERT INTO dbo.fato_despesa
    (mes_referencia, orgao_superior, funcao, grupo_despesa,
     valor_empenhado, valor_liquidado, valor_pago)
SELECT
    TRY_CONVERT(DATE,
        CONCAT(LEFT([Ano e mês do lançamento],4), '-',
               RIGHT([Ano e mês do lançamento],2), '-01')),
    NULLIF(LTRIM(RTRIM([Nome Órgão Superior])), 'Sem informaçăo'),
    NULLIF(LTRIM(RTRIM([Nome Função])),        'Sem informaçăo'),
    NULLIF(LTRIM(RTRIM([Nome Grupo de Despesa])), 'Sem informaçăo'),
    TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM([Valor Empenhado (R$)])),'.',''),',','.') AS DECIMAL(18,2)),
    TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM([Valor Liquidado (R$)])),'.',''),',','.') AS DECIMAL(18,2)),
    TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM([Valor Pago (R$)])),'.',''),',','.') AS DECIMAL(18,2))
FROM dbo.stg_execucao
WHERE TRY_CONVERT(DATE,
        CONCAT(LEFT([Ano e mês do lançamento],4), '-',
               RIGHT([Ano e mês do lançamento],2), '-01')) IS NOT NULL;
GO

SELECT COUNT(*) AS linhas_na_fato FROM dbo.fato_despesa;
GO