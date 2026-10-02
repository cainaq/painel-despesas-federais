/* =========================================================
   02 - Tabela de staging
   ---------------------------------------------------------
   Espelha as 47 colunas do CSV original, todas como NVARCHAR
   (a conversão de tipo acontece depois, na fato).

   ATENÇÃO: os nomes das colunas devem ser IDÊNTICOS ao
   cabeçalho do CSV, respeitando acentos e maiúsculas.
   Salve este arquivo em UTF-8 para não corromper acentos.
   ========================================================= */

USE Transparencia;
GO

IF OBJECT_ID('dbo.stg_execucao','U') IS NOT NULL
    DROP TABLE dbo.stg_execucao;
GO

CREATE TABLE dbo.stg_execucao (
    [Ano e mês do lançamento]                NVARCHAR(20),
    [Código Órgão Superior]                  NVARCHAR(20),
    [Nome Órgão Superior]                    NVARCHAR(200),
    -- ... (as 47 colunas completas)
    [Valor Pago (R$)]                        NVARCHAR(50),
    [Valor Restos a Pagar Inscritos (R$)]    NVARCHAR(50),
    [Valor Restos a Pagar Cancelado (R$)]    NVARCHAR(50),
    [Valor Restos a Pagar Pagos (R$)]        NVARCHAR(50)
);
GO