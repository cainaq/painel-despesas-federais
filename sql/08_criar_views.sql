/* =========================================================
   08 - Camada semântica (views)
   ---------------------------------------------------------
   Views que serão consumidas por ferramentas de BI ou por
   consultas analíticas diretas.
   ========================================================= */

USE Transparencia;
GO

CREATE OR ALTER VIEW dbo.vw_despesa_mensal AS
SELECT
    mes_referencia, orgao_superior, funcao, grupo_despesa,
    SUM(valor_empenhado) AS valor_empenhado,
    SUM(valor_liquidado) AS valor_liquidado,
    SUM(valor_pago)      AS valor_pago
FROM dbo.fato_despesa
GROUP BY mes_referencia, orgao_superior, funcao, grupo_despesa;
GO

CREATE OR ALTER VIEW dbo.vw_despesa_categoria AS
SELECT
    mes_referencia, orgao_superior, funcao, grupo_despesa,
    valor_empenhado, valor_liquidado, valor_pago,
    CASE
        WHEN orgao_superior = 'Ministério da Fazenda'
             AND funcao = 'Encargos especiais' THEN 'Dívida pública'
        WHEN funcao = 'Previdência social'     THEN 'Previdência'
        ELSE 'Discricionária'
    END AS categoria
FROM dbo.fato_despesa;
GO