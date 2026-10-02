
## Classificação incorreta da dívida pública

*Problema:* a primeira versão da vw_despesa_categoria classificava como "Dívida pública" toda a função Encargos Especiais. Essa função também inclui transferências constitucionais a estados e municípios (FPE, FPM), que não são dívida.

*Como identifiquei:* ao revisar as conclusões, a participação da dívida (58,70% do pago) parecia alta. Listei os valores distintos de grupo_despesa e confirmei que existem grupos específicos para a dívida.

*Solução:* classificar pelo grupo de despesa.

sql
CASE
    WHEN grupo_despesa IN ('Juros e Encargos da Dívida',
                           'Amortização/Refinanciamento da Dívida') THEN 'Dívida pública'
    WHEN funcao = 'Previdência social' THEN 'Previdência'
    ELSE 'Discricionárias'
END


*Resultado:*

| Categoria | Antes | Depois |
|-----------|------:|-------:|
| Dívida pública | 58,70% | 47,88% |
| Discricionárias | 22,69% | 33,51% |
| Previdência | 18,62% | 18,62% |

O total pago se manteve em R$ 4,36 tri, confirmando que a mudança só redistribuiu valores entre categorias.
