# Transparência — Despesas Públicas Federais

Pipeline de ingestão e tratamento das **despesas públicas federais brasileiras**, construído do zero com **SQL Server** e preparado para expansão analítica em **Python**, **DAX** e **Power BI**.

Este projeto faz parte do meu portfólio de transição para a área de **Análise de Dados**, com foco em modelagem, ETL, SQL analítico e visualização.

**Período coberto:** [mês/ano] a [mês/ano] · **558.998 linhas** na tabela fato.

---

## Objetivo

Transformar os arquivos CSV mensais de execução orçamentária federal (Portal da Transparência) em uma base consultável e confiável, capaz de responder:

- Quanto cada ministério **empenhou**, **liquidou** e **pagou** no mês?
- Qual a diferença entre empenho e pagamento (execução orçamentária)?
- Quanto da despesa total vem da **dívida pública** e da **previdência**?
- Qual o gasto **discricionário** do governo, excluindo dívida e previdência?

O projeto também documenta **os problemas reais encontrados durante a construção** e as soluções aplicadas (veja `docs/problemas_e_solucoes.md`).

---

## Habilidades demonstradas

| Área | O que foi aplicado |
|------|--------------------|
| **SQL** | Staging, ETL, `BULK INSERT` dinâmico com cursor e `xp_dirtree`, `TRY_CONVERT`, `TRY_CAST`, `sp_rename`, views |
| **Modelagem de dados** | Separação em camadas (staging → fato → views), preparação para star schema |
| **Qualidade de dados** | Tratamento de encoding, aspas literais, valores sentinela (`Sem informação`), linhas vazias |
| **Boas práticas** | Scripts numerados e comentados, documentação de erros e soluções |

---

## Estrutura do repositório

```
transparencia-despesas/
├── README.md
├── LICENSE
├── .gitignore
├── data/
│   └── raw/                         # CSVs originais (não versionados)
│       └── .gitkeep
├── sql/
│   ├── 01_criar_banco.sql
│   ├── 02_criar_staging.sql
│   ├── 03_carga_csv_staging.sql
│   ├── 04_renomear_colunas.sql
│   ├── 05_limpeza_staging.sql
│   ├── 06_criar_fato.sql
│   ├── 07_popular_fato.sql
│   ├── 08_criar_views.sql
│   └── 09_consultas_analiticas.sql
├
├── powerbi/                         
└── docs/
    ├── problemas_e_solucoes.md
    └── dicionario_dados.md
```

---

## Tecnologias

| Camada | Ferramenta |
|--------|------------|
| Banco de dados | **SQL Server 2025** |
| Transformação | **T-SQL** |
| Ingestão | **`BULK INSERT`** com loop dinâmico |
| Visualização (em construção) | **Power BI + DAX** |

---

## Pipeline passo a passo

### Etapa 1 — Criar o banco

`sql/01_criar_banco.sql`

```sql
IF DB_ID('Transparencia') IS NULL
    CREATE DATABASE Transparencia;
GO
```

### Etapa 2 — Tabela de staging

`sql/02_criar_staging.sql`

Tabela com **47 colunas `NVARCHAR`**, espelhando o cabeçalho do CSV original (incluindo acentos e parênteses). Tudo entra como texto; a conversão de tipos acontece na Etapa 7.

> O Portal da Transparência entrega os arquivos em Windows-1252 (Latin1). Se um dia eles mudarem para UTF-8, ajuste o CODEPAGE para '65001'.
> 
### Etapa 3 — Carga dos CSVs

`sql/03_carga_csv_staging.sql`

Lista todos os `.csv` da pasta configurada com `xp_dirtree` e carrega cada um com `BULK INSERT` dinâmico, dentro de um cursor.

```sql
BULK INSERT dbo.stg_execucao
FROM 'C:\caminho\arquivo.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);
```

> **Aprendizado:** sem `FORMAT = 'CSV'`, o `BULK INSERT` não reconhece as aspas que envolvem os campos, e elas entram como texto (`"2026/01"`). Optei por essa carga e removi as aspas na Etapa 5.

### Etapa 4 — Renomear colunas

`sql/04_renomear_colunas.sql`

A criação da tabela gerou colunas com underscore (`Ano_e_mês_do_lançamento`) em vez de espaço. Este script usa `sp_rename` para normalizar os **47 nomes**. Deve ser executado uma única vez, logo após a Etapa 2.

### Etapa 5 — Limpeza do staging

`sql/05_limpeza_staging.sql`

Remove as **aspas literais** (`"2026/01"` → `2026/01`) e as **linhas vazias** do fim dos CSVs.


### Etapa 6 — Tabela fato

`sql/06_criar_fato.sql`

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

`sql/07_popular_fato.sql`

Converte datas e valores com `TRY_CONVERT` e `TRY_CAST`, transforma sentinelas (`Sem informação`) em `NULL` e descarta linhas inválidas.

Resultado: **558.998 linhas** na `fato_despesa`.

### Etapa 8 — Camada semântica (views)

`sql/08_criar_views.sql`

- **`vw_despesa_mensal`** — agregação por mês, órgão, função e grupo de despesa.
- **`vw_despesa_categoria`** — classifica a despesa em **Dívida pública**, **Previdência** e **Discricionárias**.

### Etapa 9 — Análises

`sql/09_consultas_analiticas.sql`

Ranking de órgãos, execução por função e comparação entre empenho e pagamento.

---

## Como rodar

1. Clone o repositório:

   ```bash
   git clone https://github.com/cainaq/transparencia-despesas.git
   ```

2. Baixe os CSVs de **Execução da Despesa** no [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao) e coloque-os numa pasta local (ex.: `C:\dados\`).
   O `BULK INSERT` exige um **caminho absoluto** acessível pelo serviço do SQL Server. Ajuste a variável `@pasta` no script `03`.

3. No SQL Server Management Studio (SSMS), execute os scripts **na ordem**:

   ```
   sql/01_criar_banco.sql
   sql/02_criar_staging.sql
   sql/04_renomear_colunas.sql      ← uma única vez, logo após a criação da staging
   sql/03_carga_csv_staging.sql
   sql/05_limpeza_staging.sql
   sql/06_criar_fato.sql
   sql/07_popular_fato.sql
   sql/08_criar_views.sql
   sql/09_consultas_analiticas.sql
   ```

---

### Validação dos números

- A classificação inicial usava a função Encargos Especiais como "dívida" e somava junto cerca de *R$ 472 bi* em transferências a estados e municípios. A versão final classifica pelo *grupo de despesa*, separando juros e amortização das transferências.
- O total pago (*R$ 4,36 tri*) é o mesmo antes e depois da reclassificação: nenhum valor foi perdido ou duplicado.
- *99,9%* da dívida está lançada no Ministério da Fazenda (o restante, R$ 1,2 bi, no Ministério da Defesa).

Detalhes em docs/problemas_e_solucoes.md.

## Resultados

### Top 5 órgãos por valor pago

| Órgão | Empenhado (R$ bi) | Pago (R$ bi) | % pago |
|-------|------------------:|-------------:|-------:|
| Ministério da Fazenda | 2.790,44 | 2.580,52 | 92,48 |
| Ministério da Previdência Social | 960,02 | 854,19 | 88,98 |
| Ministério da Saúde | 207,84 | 179,48 | 86,36 |
| Ministério da Educação | 251,60 | 163,76 | 65,09 |
| Ministério do Desenvolvimento e Assistência | 138,96 | 124,58 | 89,65 |

### Execução por categoria

| Categoria | Empenhado (R$ bi) | Pago (R$ bi) | Participação no pago |
|-----------|------------------:|-------------:|---------------------:|
| Dívida pública | 2.755,58 | 2.559,12 | 58,70% |
| Discricionárias | 1.254,97 | 989,04 | 22,69% |
| Previdência | 930,11 | 811,65 | 18,62% |

### Execução por função

| Indicador | Função | % pago |
|-----------|--------|-------:|
| **Menor execução** | Desporto e lazer | 25,72 |
| **Maior execução** | Trabalho | 99,24 |

### Principais conclusões

1. A **Dívida pública** concentrou **58,70%** de todos os pagamentos do período. Esse valor inclui juros e a amortização e refinamento de títulos; o refinanciamento troca dívida antiga por nova e não é gasto novo.
2. **Dívida + Previdência** somaram **77,32%** do valor pago. O gasto **discricionário** (políticas públicas) ficou em apenas **22,69%**.
3. A taxa de pagamento (pago ÷ empenhado) variou de **25,72%** em **Desporto e lazer** a **99,24%** em **Trabalho**. Uma hipótese é que funções dominadas por benefícios e transferências pagam quase tudo o que empenham, enquanto com mais investimento executam mais devagar.
4. O **Ministério da Fazenda** liderou o ranking por órgão (R$ 2,58 tri pagos), mas cerca de *81%* desse valor é dívida. Sem ela, a Fazenda pagou cerca de R$ 494 bi, abaixo do **Ministério da Previdência Social** (R$ 854 bi), que passa a liderar.

As consultas que geram esses resultados estão em `sql/09_consultas_analiticas.sql`.


---

## Próximos passos

- [ ] **Power BI + DAX** — dashboard com série mensal, ranking de órgãos e medidas de execução (% pago, acumulado no ano, variação mensal).
- [ ] **Python** — validação com `pandas` (nulos, somas por grupo, comparação com totais oficiais).
- [ ] **Star schema** — `dim_tempo`, `dim_orgao`, `dim_funcao`, `dim_grupo_despesa`.
- [ ] **Automação** — ingestão mensal recorrente.
- [ ] **Testes de qualidade** — checagens automáticas de contagem e soma.

---

## Referências

- [Portal da Transparência — Execução da Despesa](https://portaldatransparencia.gov.br/download-de-dados/despesas-execucao)
- [Documentação `BULK INSERT` — Microsoft](https://learn.microsoft.com/sql/t-sql/statements/bulk-insert-transact-sql)
- [Documentação `sp_rename` — Microsoft](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql)
- [Documentação `TRY_CAST` / `TRY_CONVERT` — Microsoft](https://learn.microsoft.com/sql/t-sql/functions/try-cast-transact-sql)

---

## Autor

**Cainã Queiroz Silva** — em transição para Análise de Dados.

- GitHub: [@cainaq](https://github.com/cainaq)
- LinkedIn: [linkedin.com/in/seu-usuario](https://linkedin.com/in/seu-usuario)
- Foco atual: SQL, Python, Power BI e DAX.

---

## Licença

Este projeto está sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.
