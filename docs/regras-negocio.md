# Regras de negócio

Este documento apresenta as regras de forma simplificada e anonimizada. Elas não devem ser interpretadas como orientação contábil ou fiscal.

## 1. Seleção das compras

- Considerar somente tipos de operação definidos pelo processo de entrada de compras.
- Permitir filtros por período de entrada, empresa, fornecedor, produto e tipo de uso do produto.

## 2. Valor líquido do item

```text
Valor líquido = valor total do item - desconto do item
```

O valor líquido serve de base para os rateios proporcionais.

## 3. ICMS

- Determinados tipos de operação não recebem ajuste de ICMS.
- Se a alíquota estiver ausente ou zerada, o ajuste é zero.
- A regra varia conforme a empresa compradora.

## 4. IPI

- O IPI unitário é calculado aplicando a alíquota ao valor unitário.
- Determinados tipos de operação são desconsiderados conforme a regra interna.

## 5. Simples Nacional

- O cálculo é aplicado somente quando a alíquota específica estiver informada.
- A forma de cálculo varia conforme a empresa compradora.

## 6. Substituição tributária

O valor total de ST é transformado em valor unitário proporcional:

```text
ST unitária = (ST total do item / valor líquido do item) × valor unitário
```

## 7. Frete

Existem dois cenários:

### Frete da própria nota

```text
Frete unitário =
    (frete da nota / soma líquida dos itens da nota) × valor unitário
```

### Frete compartilhado por CT-e

Quando um mesmo CT-e está relacionado a várias notas, o rateio utiliza a soma líquida de todas as notas relacionadas:

```text
Frete unitário =
    (frete / soma líquida das notas do CT-e) × valor unitário
```

## 8. Custo adicional

Quando existe custo adicional vinculado ao item, ele é dividido pela quantidade comprada:

```text
Custo adicional unitário = custo adicional / quantidade
```

No processo original, esse campo representa o custo de clichê associado a determinados materiais.

## 9. Custo unitário final

```text
Custo final = valor unitário
            + ICMS
            + IPI
            + Simples
            + ST
            + frete proporcional
            + custo adicional unitário
```

## 10. Comparação histórica

Para cada produto, o custo atual é comparado ao custo da compra anterior por meio da função analítica `LAG()`.

São calculadas:

- variação em valor;
- variação percentual;
- fornecedor atual e anterior;
- data da última aquisição.

