# Transparência — Despesas Públicas Federais

Pipeline completo de ingestão, tratamento e análise das **despesas públicas federais brasileiras**, construído do zero com **SQL Server**, e preparado para expansão analítica em **Python**, **DAX** e **Power BI**.

Este projeto faz parte do meu portfólio de transição para a área de **Análise de Dados**, com foco em domínio prático de modelagem, ETL, SQL analítico e visualização.

---

## Objetivo

Transformar os arquivos CSV mensais de execução orçamentária federal (padrão do Portal da Transparência) em uma base consultável e confiável, permitindo responder perguntas como:

- Quanto cada ministério **empenhou**, **liquidou** e **pagou** no mês?
- Qual a diferença entre empenho e pagamento (execução orçamentária)?
- Como a **dívida pública** e a **previdência** impactam o total?
- Qual o gasto **discricionário** real do governo, excluindo encargos da dívida?

O projeto também documenta, passo a passo, **os problemas reais encontrados durante a construção** e as soluções aplicadas — algo essencial em qualquer pipeline de dados do mundo real.

---

## Habilidades demonstradas

| Área | O que foi aplicado |
|------|--------------------|
| **SQL** | Modelagem de staging, ETL, `BULK INSERT` dinâmico, `TRY_CONVERT`, `TRY_CAST`, `sp_rename`, views, cursor, `xp_dirtree` |
| **Modelagem de dados** | Separação em camadas (staging → fato → views), preparação para star schema |
| **Qualidade de dados** | Tratamento de encoding, aspas literais, sentinelas (`Sem informação`), linhas vazias |
| **Boas práticas** | Scripts numerados, idempotência, comentários, documentação de erros |
| **Próximas etapas** | Python (pandas) para validação, DAX para métricas, Power BI para dashboards |

---

## Estrutura do repositório

```
transparencia-despesas/
├── README.md
├── .gitignore
├── data/
│   └── raw/                         # CSVs originais (não versionados)
│       └── .gitkeep
├── sql/
│   ├── 01_criar_banco.sql
│   ├── 02_criar_staging.sql
│   ├── 03_carga_cvs_staging.sql
│   ├── 04_renomear_coluna.sql
│   ├── 05_limpeza_staging.sql
│   ├── 06_tabela.sql
│   ├── 07_popular_tabela.sql
│   ├── 08_criar_views.sql
│   └── 09_consultas_analiticas.sql
├── python/                          # (em construção) validação com pandas
│   └── .gitkeep
├── powerbi/                         # (em construção) dashboards
│   └── .gitkeep
└── docs/
    ├── problemas_e_solucoes.md
    └── dicionario_dados.md
```

---

## Tecnologias

| Camada | Ferramenta |
|--------|------------|
| Banco de dados | **SQL Server 2022** |
| Linguagem de transformação | **T-SQL** |
| Ingestão | **`BULK INSERT`** com loop dinâmico |
| Análise (em construção) | **Python + pandas** |
| Visualização (em construção) | **Power BI + DAX** |

---

## Pipeline passo a passo

### Etapa 1 — Criar o banco

📄 `sql/01_create_database.sql`

Cria o banco `Transparencia`.

```sql
IF DB_ID('Transparencia') IS NULL
    CREATE DATABASE Transparencia;
GO
```

### Etapa 2 — Tabela de staging

📄 `sql/02_create_staging.sql`

Tabela com **47 colunas `NVARCHAR`**, espelhando exatamente o cabeçalho do CSV original (incluindo acentos e parênteses).

> O CSV vem em encoding **Windows-1252 (Latin1)**. Salve os scripts em **UTF-8** para não corromper acentos.

### Etapa 3 — Carga dos CSVs

 `sql/03_bulk_insert_loop.sql`

Loop em todos os `.csv` da pasta configurada, carregando cada um com `BULK INSERT` dinâmico.

```sql
BULK INSERT dbo.stg_execucao
FROM 'caminho\arquivo.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    FIELDQUOTE      = '"',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);
```

> **Aprendizado:** usar `FORMAT='CSV'` junto com `FIELDTERMINATOR=';'` **quebra o parsing** e deixa aspas literais nos valores. Removemos o `FORMAT='CSV'` para que o `FIELDQUOTE` funcione.

### Etapa 4 — Renomear colunas

`sql/04_rename_columns.sql`

O processo de criação gerou colunas com underscore (`Ano_e_mês_do_lançamento`) em vez de espaço. Este script usa `sp_rename` para normalizar os **47 nomes**.

### Etapa 5 — Limpeza do staging

 `sql/05_clean_staging.sql`

Remove **aspas literais residuais** (`"2026/01"` → `2026/01`) e **linhas vazias** do fim dos CSVs.

### Etapa 6 — Tabela fato

`sql/06_create_fato.sql`

```sql
CREATE TABLE dbo.fato_despesa (
    mes_referencia   DATE          NOT NULL,
    orgao_superior   NVARCHAR(200) NULL,
    funcao           NVARCHAR(200) NULL,
    grupo_despesa    NVARCHAR(100) NULL,
    valor_empenhado  DECIMAL(18,2) NULL,
    valor_liquidado  DECIMAL(18,2) NULL,
    valor_pago       DECIMAL(18,2) NULL
);
```

### Etapa 7 — Popular a tabela fato

`sql/07_insert_fato.sql`

Conversão robusta com `TRY_CONVERT` e `TRY_CAST`, tratamento de sentinelas (`Sem informação` → `NULL`) e filtro de linhas inválidas.

Resultado alcançado:

```
linhas_na_fato
--------------
558998
```

### Etapa 8 — Camada semântica (views)

 `sql/08_create_views.sql`

- **`vw_despesa_mensal`** — agregação por mês, órgão, função e grupo de despesa.
- **`vw_despesa_categoria`** — separa em **Dívida pública**, **Previdência** e **Discricionárias**.

### Etapa 9 — Análises

`sql/09_analysis_queries.sql`

Consultas analíticas de exemplo, incluindo ranking de órgãos, execução por função e comparação entre empenho e pagamento.

---

##  Como rodar

1. Clone o repositório:

   ```bash
   git clone https://github.com/cainaq/transparencia-despesas.git
   ```

2. Coloque os CSVs em `data/raw/` ou ajuste a pasta no script `03`.

3. Abra o SQL Server Management Studio (SSMS) ou Azure Data Studio e execute os scripts **na ordem**:

   ```
   sql/01_create_database.sql
   sql/02_create_staging.sql
   sql/03_bulk_insert_loop.sql
   sql/04_rename_columns.sql      ← rodar só uma vez
   sql/05_clean_staging.sql
   sql/06_create_fato.sql
   sql/07_insert_fato.sql
   sql/08_create_views.sql
   sql/09_analysis_queries.sql
   ```

4. O script `07` imprime o total de linhas carregadas. O `09` retorna os rankings.

---

##  Análises já disponíveis

### Top 10 órgãos por empenho

```sql
SELECT TOP 10
    orgao_superior,
    SUM(valor_empenhado) AS empenhado,
    SUM(valor_pago)      AS pago
FROM dbo.fato_despesa
GROUP BY orgao_superior
ORDER BY empenhado DESC;
```

### Execução por categoria (dívida / previdência / discricionárias)

```sql
SELECT
    categoria,
    SUM(valor_empenhado) AS empenhado,
    SUM(valor_pago)      AS pago
FROM dbo.vw_despesa_categoria
GROUP BY categoria
ORDER BY empenhado DESC;
```

### Empenhado vs. pago por função

```sql
SELECT
    funcao,
    SUM(valor_empenhado) AS empenhado,
    SUM(valor_pago)      AS pago,
    CAST(100.0 * SUM(valor_pago) / NULLIF(SUM(valor_empenhado),0)
        AS DECIMAL(5,2)) AS pct_pago
FROM dbo.fato_despesa
GROUP BY funcao
ORDER BY empenhado DESC;
```

---

##  Observações importantes sobre os dados

1. **Encargos especiais do Ministério da Fazenda** representam **rolagem da dívida pública** — não são gasto novo. Sempre trate à parte.
2. **Previdência Social** tem empenho maior que pagamento no início do mês e menor no fim (restos a pagar).
3. **Educação e Assistência Social** costumam empenhar o orçamento anual em **janeiro**, pagando ao longo do ano.
4. Os valores são armazenados em `DECIMAL(18,2)` — suficiente para qualquer valor da dívida pública.

---

##  Próximos passos

- [ ] **Python** — validação dos dados com `pandas` (checagens de nulos, somas por grupo, comparação com totais oficiais).
- [ ] **Modelagem star schema** — `dim_tempo`, `dim_orgao`, `dim_funcao`, `dim_grupo_despesa`.
- [ ] **Power BI** — dashboards interativos com séries temporais e ranking de ministérios.
- [ ] **DAX** — medidas de execução orçamentária (% pago, acumulado no ano, variação mês a mês).
- [ ] **Automação** — SQL Agent Job para ingestão mensal recorrente.
- [ ] **Testes de qualidade** — checagens automáticas de contagem e soma.

---

##  Referências

- [Portal da Transparência — Despesas Públicas](https://portaldatransparencia.gov.br/despesas)
- [Documentação `BULK INSERT` — Microsoft](https://learn.microsoft.com/sql/t-sql/statements/bulk-insert-transact-sql)
- [Documentação `sp_rename` — Microsoft](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql)
- [Documentação `TRY_CAST` / `TRY_CONVERT` — Microsoft](https://learn.microsoft.com/sql/t-sql/functions/try-cast-transact-sql)

---

##  Autor

**Cainã Queiroz Silva.** — em transição para Análise de Dados.

- GitHub: [@cainaq](https://github.com/cainaq)
- Foco atual: SQL, Python, Power BI e DAX.

---

##  Licença

Este projeto está sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.
