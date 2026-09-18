/*
  Exemplo independente do ERP, executável em Oracle.
  Utiliza dados fictícios para demonstrar a composição do custo.
*/

WITH compras AS (
    SELECT 1001 nunota, DATE '2026-01-10' dtneg, 501 codprod,
           'EMBALAGEM 500G' produto, 'FORNECEDOR ALFA' fornecedor,
           1000 qtdneg, 1.20 vlrunit, 0.00 desconto_unitario,
           2.00 icms_unitario, 0.06 ipi_unitario,
           0.03 simples_unitario, 0.04 st_unitario,
           0.08 frete_unitario, 0.02 adicional_unitario
    FROM dual
    UNION ALL
    SELECT 1002, DATE '2026-02-15', 501,
           'EMBALAGEM 500G', 'FORNECEDOR BETA',
           1500, 1.25, 0.02,
           0.00, 0.063,
           0.025, 0.05,
           0.07, 0.02
    FROM dual
    UNION ALL
    SELECT 1003, DATE '2026-02-20', 502,
           'CAIXA DE PAPELAO', 'FORNECEDOR GAMA',
           500, 2.80, 0.10,
           0.08, 0.14,
           0.00, 0.09,
           0.12, 0.00
    FROM dual
),
custos AS (
    SELECT
        c.*,
        ROUND(
            vlrunit - desconto_unitario
            + icms_unitario + ipi_unitario + simples_unitario
            + st_unitario + frete_unitario + adicional_unitario,
            3
        ) AS custo_unitario_final
    FROM compras c
),
historico AS (
    SELECT
        c.*,
        LAG(custo_unitario_final) OVER (
            PARTITION BY codprod ORDER BY dtneg, nunota
        ) AS custo_anterior
    FROM custos c
)
SELECT
    h.*,
    ROUND(custo_unitario_final - custo_anterior, 3) AS variacao_valor,
    ROUND(
        (custo_unitario_final - custo_anterior)
        / NULLIF(custo_anterior, 0) * 100,
        2
    ) AS variacao_percentual
FROM historico h
ORDER BY codprod, dtneg;

