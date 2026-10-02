/* =========================================================
   04 - Renomear colunas do staging
   ---------------------------------------------------------
   O processo de criação da tabela (seja por cópia manual do
   cabeçalho ou por ferramenta) gerou colunas com underscore
   no lugar de espaço, e alguns acentos corrompidos.

   Este script normaliza TODOS os 47 nomes para ficarem
   idênticos ao cabeçalho original do CSV.

   ⚠️ Só precisa rodar UMA VEZ. Se rodar de novo, dará erro
   de coluna inexistente (porque o nome antigo já não existe).
   ========================================================= */

USE Transparencia;
GO

EXEC sp_rename 'dbo.stg_execucao.[Ano_e_mês_do_lançamento]',            'Ano e mês do lançamento',                       'COLUMN';
EXEC sp_rename 'dbo.stg_execucao.[Código_Órgão_Superior]',              'Código Órgão Superior',                         'COLUMN';
-- ... (47 no total)
GO