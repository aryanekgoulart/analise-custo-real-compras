/*
  Projeto: Automação da apuração do custo real de compras
  Autora: Aryane K. Goulart

  Versão anonimizada da consulta utilizada como base para a tabela analítica
  disponibilizada dentro do ERP Sankhya.
  Os nomes das tabelas seguem o padrão do ERP Sankhya, mas dados, parâmetros
  e regras devem ser adaptados ao ambiente em que a consulta for executada.
*/

WITH base AS (
    SELECT
        cab.nunota,
        cab.dtneg,
        cab.dtentsai,
        cab.codemp,
        cab.codparc,
        par.razaosocial,
        pro.codprod,
        pro.descrprod,
        ite.qtdneg,
        ite.vlrunit,
        ite.vlrtot,
        ite.vlrdesc,
        ite.vlrtot - NVL(ite.vlrdesc, 0) AS vlrtot_liq,
        ite.ad_vlrcliche,
        cab.vlrnota,
        ite.aliqicms,
        ite.aliqipi,
        ite.vlrsubst,
        cab.vlrfrete,
        ite.ad_aliqsimples,
        cab.ad_nrcte,
        cab.codtipoper
    FROM tgfcab cab
    INNER JOIN tgfite ite ON ite.nunota = cab.nunota
    INNER JOIN tgfpar par ON par.codparc = cab.codparc
    INNER JOIN tgfpro pro ON pro.codprod = ite.codprod
    WHERE cab.codtipoper IN (1401, 1406, 1408, 1416, 1451, 1460, 1441, 1402, 1405)
      AND pro.usoprod IN :USOPROD
      AND cab.dtentsai BETWEEN :PERIODO.INI AND :PERIODO.FIN
      AND pro.codprod = NVL(:CODPROD, pro.codprod)
      AND cab.codemp = NVL(:CODEMP, cab.codemp)
      AND cab.codparc = NVL(:CODPARC, cab.codparc)
),

/* Soma dos itens das notas vinculadas ao mesmo CT-e. */
frete_base AS (
    SELECT
        cab.ad_nrcte,
        SUM(ite.vlrtot - NVL(ite.vlrdesc, 0)) AS total_notas_nrcte
    FROM tgfcab cab
    INNER JOIN tgfite ite ON ite.nunota = cab.nunota
    WHERE cab.ad_nrcte IS NOT NULL
    GROUP BY cab.ad_nrcte
),

base_calculada AS (
    SELECT
        b.*,
        fb.total_notas_nrcte,

        CASE
            WHEN fb.total_notas_nrcte > 0
             AND fb.total_notas_nrcte <> b.vlrtot_liq
                THEN fb.total_notas_nrcte
            ELSE SUM(b.vlrtot_liq) OVER (PARTITION BY b.nunota)
        END AS vlr_prod,

        CASE
            WHEN b.ad_vlrcliche IS NULL OR b.qtdneg = 0 THEN 0
            ELSE ROUND(b.ad_vlrcliche / b.qtdneg, 3)
        END AS vlr_cliche_un,

        CASE
            WHEN b.codtipoper = 1401 OR NVL(b.aliqicms, 0) = 0 THEN 0
            WHEN b.codemp = 1 THEN ROUND(((18 - NVL(b.aliqicms, 0)) / 100) * b.vlrunit, 3)
            WHEN b.codemp = 3 THEN ROUND((NVL(b.aliqicms, 0) / 100) * b.vlrunit, 3)
            ELSE 0
        END AS vlr_icms,

        CASE
            WHEN b.codtipoper = 1401 THEN 0
            ELSE ROUND(b.vlrunit * (NVL(b.aliqipi, 0) / 100), 3)
        END AS vlr_ipi,

        CASE
            WHEN b.ad_aliqsimples IS NULL THEN 0
            WHEN b.codemp = 1 THEN ROUND(((18 - NVL(b.ad_aliqsimples, 0)) / 100) * b.vlrunit, 3)
            WHEN b.codemp = 3 THEN ROUND((NVL(b.ad_aliqsimples, 0) / 100) * b.vlrunit, 3)
            ELSE 0
        END AS vlr_simples,

        CASE
            WHEN b.codtipoper = 1401 OR b.vlrtot_liq <= 0 THEN 0
            ELSE ROUND((NVL(b.vlrsubst, 0) / b.vlrtot_liq) * b.vlrunit, 3)
        END AS vlr_st,

        CASE
            WHEN b.vlrtot_liq <= 0 THEN 0
            WHEN NVL(b.ad_nrcte, 0) <> 0 AND fb.total_notas_nrcte > 0
                THEN ROUND((NVL(b.vlrfrete, 0) / fb.total_notas_nrcte) * b.vlrunit, 3)
            ELSE ROUND(
                (NVL(b.vlrfrete, 0) /
                    NULLIF(SUM(b.vlrtot_liq) OVER (PARTITION BY b.nunota), 0)
                ) * b.vlrunit,
                3
            )
        END AS vlr_frete_final
    FROM base b
    LEFT JOIN frete_base fb ON fb.ad_nrcte = b.ad_nrcte
),

custo_final AS (
    SELECT
        bc.*,
        ROUND(
            bc.vlrunit
            + bc.vlr_icms
            + bc.vlr_ipi
            + bc.vlr_simples
            + bc.vlr_st
            + bc.vlr_frete_final
            + bc.vlr_cliche_un,
            3
        ) AS custo_unitario_final
    FROM base_calculada bc
),

comparacao AS (
    SELECT
        cf.*,
        LAG(cf.custo_unitario_final) OVER (
            PARTITION BY cf.codprod
            ORDER BY cf.dtneg, cf.nunota
        ) AS custo_unitario_anterior
    FROM custo_final cf
)

SELECT
    nunota,
    codemp,
    dtneg,
    dtentsai,
    codparc,
    razaosocial,
    codprod,
    descrprod,
    qtdneg,
    vlrunit,
    vlr_prod,
    vlr_cliche_un,
    vlr_icms AS icms,
    vlr_ipi AS ipi,
    vlr_simples AS simples,
    vlr_st AS st,
    vlr_frete_final AS frete_final,
    custo_unitario_final,
    custo_unitario_anterior,
    ROUND(
        custo_unitario_final - custo_unitario_anterior,
        3
    ) AS variacao_valor,
    ROUND(
        (custo_unitario_final - custo_unitario_anterior)
        / NULLIF(custo_unitario_anterior, 0) * 100,
        2
    ) AS variacao_percentual
FROM comparacao
ORDER BY nunota DESC, codprod;
