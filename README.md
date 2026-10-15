# Transparência — Despesas Públicas Federais

Pipeline de ingestão, tratamento e análise das despesas públicas federais brasileiras, construído do zero com SQL Server, validado com Python e apresentado em um dashboard em Power BI e DAX.

Este projeto faz parte do meu portfólio de transição para a área de Análise de Dados, com foco em modelagem, ETL, SQL analítico, qualidade de dados e visualização.

Período coberto: 01/2026 a 09/2026 · 558.998 linhas na tabela fato · R$ 4,36 trilhões pagos.

## Objetivo

Transformar os arquivos CSV mensais de execução orçamentária federal (Portal da Transparência) em uma base consultável e confiável, capaz de responder:

Quanto cada ministério empenhou, liquidou e pagou no mês?
Qual a diferença entre empenho e pagamento (execução orçamentária)?
Quanto da despesa total vem da dívida pública e da previdência?
Qual o gasto discricionário do governo, excluindo dívida e previdência?

O projeto também documenta os problemas reais encontrados durante a construção e as soluções aplicadas (veja docs/problemas_e_solucoes.md).

## Dashboard


painel-despesas-federais/imagens/visao_geral.png


Painel em Power BI com totais de empenho e pagamento, participação de cada categoria de despesa, série mensal de pagamentos e ranking dos 10 órgãos que mais pagaram.

# Habilidades demonstradas

| Área	| O que foi aplicado |
| --- | --- |
| SQL |	Staging, ETL, BULK INSERT dinâmico com cursor e xp_dirtree, TRY_CONVERT, TRY_CAST, sp_rename, views
| Modelagem de dados| 	Separação em camadas (staging → fato → views), dimensão de órgãos, preparação para star schema
| Qualidade de dados |	Encoding, aspas literais, valores sentinela, linhas vazias, nomes truncados na origem, reclassificação de categorias
| Validação	| Conferência independente em Python (pandas) dos CSVs originais contra a tabela fato
| Visualização	| Power BI, DAX, relacionamentos e tabela calendário
| Boas práticas	| Scripts numerados e comentados, documentação de erros e soluções| 

**Estrutura do repositório**
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
│   ├── 09_consultas_analiticas.sql
│   ├── 10_dim_orgao.sql
│   └── validacao_despesas.sql
├── python/
│   └── validacao_despesas.py
├── powerbi/
│   └── dashboard_despesas.pbix
└── docs/
    ├── problemas_e_solucoes.md
    ├── dicionario_dados.md
    └── img/
        └── dashboard.png

```
# Tecnologias

| Camada	| Ferramenta |
| --- | --- |
| Banco de dados |	SQL Server 2025 |
| Transformação | 	T-SQL |
|Ingestão	 | BULK INSERT com loop dinâmico |
|Validação |	Python (pandas, SQLAlchemy)
|Visualização |	Power BI + DAX


# Pipeline passo a passo

## Etapa 1 — Criar o banco

sql/01_criar_banco.sql

```sql
IF DB_ID('Transparencia') IS NULL
    CREATE DATABASE Transparencia;
GO
```
## Etapa 2 — Tabela de staging**

``` sql/02_criar_staging.sql```

Tabela com 47 colunas NVARCHAR, espelhando o cabeçalho do CSV original (incluindo acentos e parênteses). Tudo entra como texto; a conversão de tipos acontece na Etapa 7.

O Portal da Transparência entrega os arquivos em Windows-1252 (Latin1). Se um dia eles mudarem para UTF-8, ajuste o CODEPAGE para '65001'.

## Etapa 3 — Carga dos CSVs

sql/03_carga_csv_staging.sql

Lista todos os .csv da pasta configurada com xp_dirtree e carrega cada um com BULK INSERT dinâmico, dentro de um cursor.

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
Aprendizado: sem FORMAT = 'CSV', o BULK INSERT não reconhece as aspas que envolvem os campos, e elas entram como texto ("2026/01"). Optei por essa carga e removi as aspas na Etapa 5.

## Etapa 4 — Renomear colunas

sql/04_renomear_colunas.sql

A criação da tabela gerou colunas com underscore (Ano_e_mês_do_lançamento) em vez de espaço. Este script usa sp_rename para normalizar os 47 nomes. Deve ser executado uma única vez, logo após a Etapa 2.

## Etapa 5 — Limpeza do staging

sql/05_limpeza_staging.sql

Remove as aspas literais ("2026/01" → 2026/01) e as linhas vazias do fim dos CSVs.

## Etapa 6 — Tabela fato

sql/06_criar_fato.sql
```
sql
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
## Etapa 7 — Popular a tabela fato

sql/07_popular_fato.sql

Converte datas e valores com TRY_CONVERT e TRY_CAST e descarta linhas inválidas.

Resultado: 558.998 linhas na fato_despesa.

## Etapa 8 — Camada semântica (views)

sql/08_criar_views.sql

vw_despesa_mensal: agregação por mês, órgão, função e grupo de despesa.
vw_despesa_categoria: classifica a despesa em Dívida pública, Previdência e Discricionárias.
## Etapa 9 — Análises

sql/09_consultas_analiticas.sql

Ranking de órgãos, execução por função e comparação entre empenho e pagamento.

## Etapa 10 — Dimensão de órgãos

sql/10_dim_orgao.sql

Os nomes de órgão já vêm truncados em cerca de 45 bytes nos CSVs do Portal (por exemplo, "Ministério da Ciência, Tecnologia e Inovaç"). A tabela dim_orgao guarda o nome como vem na origem, o nome oficial completo e um nome curto para os gráficos. A tabela fato não é alterada e continua fiel à fonte.

# Como rodar
1. Clone o repositório:
  ``` git clone https://github.com/cainaq/transparencia-despesas.git```
2. Baixe os CSVs de Execução da Despesa no Portal da Transparência e coloque-os numa pasta local (ex.: D:\dados\). O BULK INSERT exige um caminho absoluto acessível pelo serviço do SQL Server. Ajuste a variável @pasta no script 03.
3. No SQL Server Management Studio (SSMS), execute os scripts na ordem:
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
   sql/10_dim_orgao.sql 
4. Para validar a carga, ajuste a pasta e a conexão no topo de python/validacao_despesas.py e rode:

 ```
 pip install pandas sqlalchemy pyodbc
   python python/validacao_despesas.py

```

## Validação dos números

A base foi conferida por dois caminhos independentes: os CSVs originais, lidos diretamente com pandas, e a tabela fato no SQL Server.

| Verificação	| Resultado| 
| --- | --- |
| Linhas (CSV × fato) |	558.998 × 558.998, sem perdas |
| Valores que não convertem para número |	0 |
| Meses carregados em mais de um arquivo	| 0 |
|Linhas duplicadas	| 0|
|Diferença no total pago, mês a mês	| R$ 0,00|
|Total pago |	R$ 4.359.806.643.910,17 nos dois caminhos|

**Reclassificação da dívida.** A classificação inicial usava a função Encargos Especiais como "dívida" e somava junto cerca de R$ 472 bi em transferências a estados e municípios. A versão final classifica pelo grupo de despesa, separando juros e amortização das transferências. O total pago é o mesmo antes e depois da reclassificação: nenhum valor foi perdido ou duplicado.

**Nomes truncados na origem.** Os CSVs trazem nomes de órgão cortados. A conferência pelo código do órgão mostrou que nenhum nome cortado corresponde a mais de um órgão, então rankings e totais não foram afetados. A dim_orgao restaura os nomes oficiais para exibição.

**Detalhes em docs/problemas_e_solucoes.md.**

## Escopo e decisões

- **"Pago"** significa pagamentos de despesas empenhadas em 2026. Restos a pagar (despesas de anos anteriores pagas em 2026, cerca de R$ 234 bi, ou 5,4% do valor analisado) ficaram fora da análise.
- **Estornos estão incluídos.** São 6.305 linhas com valor pago negativo, somando −R$ 1,37 bi (0,03% do total), que representam anulações e já estão descontadas dos totais.
**Linhas sem movimento foram mantidas.** 110.710 linhas têm empenhado, liquidado e pago iguais a zero. Elas não alteram nenhuma soma.
**Órgão "Sem informação" foi mantido**. São 6.033 linhas sem valor pago.
**Os valores do CSV são movimentos mensais.** Um pagamento em março pode vir de um empenho feito em janeiro. Por isso, a taxa de pagamento só é calculada no acumulado do período.

## Resultados


**Top 5 órgãos por valor pago**

| Órgão	| Empenhado (R$ bi) |	Pago (R$ bi) |	% pago |
|--- | --- | --- | --- |
|Ministério da Fazenda	| 2.790,44 |	2.580,52 |	92,48|
|Ministério da Previdência Social	| 960,02	| 854,19 | 	88,98|
|Ministério da Saúde	| 207,84	| 179,48	| 86,36|
|Ministério da Educação	| 251,60	| 163,76	| 65,09|
|Ministério do Desenvolvimento e Assistência Social, Família e Combate à Fome| 	138,96	| 124,58	| 89,65|

**Execução por categoria**

|Categoria	| Pago (R$ tri)	| Participação no pago| 
|--- |---| --- |
|Dívida pública |	2,09 |	47,88%|
|Discricionárias |	1,46 |	33,51%|
|Previdência |	0,81 |	18,62%|

**Execução por função**
|Indicador	| Função	| % pago|
| --- |---| --- |
|Menor execução	|Desporto e lazer	|25,72|
|Maior execução	|Trabalho|	99,24|

## Principais conclusões

1. **A dívida pública concentrou 47,88% de todos os pagamentos do período.** Esse valor inclui juros e a amortização e o refinanciamento de títulos; o refinanciamento troca dívida antiga por nova e não é gasto novo.
2. **Dívida e Previdência somaram 66,50% do valor pago.** O gasto discricionário (políticas públicas) ficou em 33,51%.
3. **A taxa de pagamento (pago ÷ empenhado) variou de 25,72% em Desporto e lazer a 99,24% em Trabalho.** Uma hipótese é que funções dominadas por benefícios e transferências pagam quase tudo o que empenham, enquanto as que têm mais investimento executam mais devagar.
4. **O Ministério da Fazenda liderou o ranking por órgão (R$ 2,58 tri pagos), mas cerca de 81% desse valor é dívida.** Sem ela, a Fazenda pagou cerca de R$ 494 bi, abaixo do Ministério da Previdência Social (R$ 854 bi), que passa a liderar.

As consultas que geram esses resultados estão em sql/09_consultas_analiticas.sql.

## Próximos passos

[ ] Star schema completo: dim_tempo, dim_funcao, dim_grupo_despesa.
 [ ] Automação da ingestão mensal recorrente.
[ ] Testes de qualidade automáticos a cada carga, a partir de python/validacao_despesas.py.
[ ] Análise de restos a pagar como complemento à execução do ano.

## Referências

- Portal da Transparência — Execução da Despesa
- Documentação BULK INSERT — Microsoft
- Documentação sp_rename — Microsoft
- Documentação TRY_CAST / TRY_CONVERT — Microsoft

## Autor

Cainã Queiroz Silva — em transição para Análise de Dados.

**GitHub:** @cainaq
**LinkedIn:**linkedin.com/in/cainaqueiroz

**Foco atual:** SQL, Python, Power BI e DAX.

## Licença

Este projeto está sob a licença MIT. Consulte o arquivo LICENSE para mais detalhes.
---

## Licença

Este projeto está sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.
