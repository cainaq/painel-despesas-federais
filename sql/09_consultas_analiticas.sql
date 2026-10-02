/* =========================================================
   09 - Consultas analíticas
   ---------------------------------------------------------
   Queries de exemplo para explorar os dados. Serve tanto
   como documentação quanto como ponto de partida para
   dashboards.
   ========================================================= */

USE Transparencia;
GO

-- Top 10 órgãos por empenho
SELECT TOP 10
    orgao_superior,
    SUM(valor_empenhado) AS empenhado,
    SUM(valor_liquidado) AS liquidado,
    SUM(valor_pago)      AS pago
FROM dbo.fato_despesa
GROUP BY orgao_superior
ORDER BY empenhado DESC;
GO

-- Execução por categoria
SELECT
    categoria,
    SUM(valor_empenhado) AS empenhado,
    SUM(valor_pago)      AS pago
FROM dbo.vw_despesa_categoria
GROUP BY categoria
ORDER BY empenhado DESC;
GO

-- ... demais queries