/* =========================================================
   06 - Tabela fato
   ---------------------------------------------------------
   Modelo enxuto, com tipos já convertidos:
   - mes_referencia: DATE (primeiro dia do mês)
   - valores: DECIMAL(18,2)
   - texto: NVARCHAR

   A granularidade é: um lançamento de despesa do CSV.
   ========================================================= */

USE Transparencia;
GO

IF OBJECT_ID('dbo.fato_despesa','U') IS NOT NULL
    DROP TABLE dbo.fato_despesa;
GO

CREATE TABLE dbo.fato_despesa (
    mes_referencia   DATE          NOT NULL,
    orgao_superior   NVARCHAR(200) NULL,
    funcao           NVARCHAR(200) NULL,
    grupo_despesa    NVARCHAR(100) NULL,
    valor_empenhado  DECIMAL(18,2) NULL,
    valor_liquidado  DECIMAL(18,2) NULL,
    valor_pago       DECIMAL(18,2) NULL
);
GO