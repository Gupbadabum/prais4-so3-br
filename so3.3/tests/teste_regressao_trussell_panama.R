# ============================================================
# PRAIS4 - SO3.3
# TESTE DE REGRESSAO - TRUSSELL / PANAMA 1976
#
# Referencia operacional:
# exemplo Panama / modelo West reproduzido em u5mr,
# originalmente baseado no Manual X das Nacoes Unidas.
#
# O ano 2022 abaixo e apenas um marcador tecnico para permitir
# executar a funcao atual, cuja referencia censitaria aceita
# 2000/2010/2022.
#
# k(i), q(x) e t(i) independem dessa escolha de ano.
# ============================================================


idades_mae <- c(
  "15-19",
  "20-24",
  "25-29",
  "30-34",
  "35-39",
  "40-44",
  "45-49"
)


mulheres <- c(
  2695,
  2095,
  1828,
  1605,
  1362,
  1128,
  930
)


panama <- data.table::rbindlist(
  list(

    data.table::data.table(
      grupo = "Total",
      filhos_nv = c(
        557,
        2633,
        4757,
        6085,
        6722,
        6367,
        5276
      ),
      filhos_falecidos = c(
        40,
        130,
        312,
        435,
        636,
        686,
        689
      )
    ),

    data.table::data.table(
      grupo = "Masculino",
      filhos_nv = c(
        278,
        1380,
        2395,
        3097,
        3444,
        3274,
        2682
      ),
      filhos_falecidos = c(
        24,
        77,
        172,
        236,
        348,
        394,
        354
      )
    ),

    data.table::data.table(
      grupo = "Feminino",
      filhos_nv = c(
        279,
        1253,
        2362,
        2988,
        3278,
        3093,
        2594
      ),
      filhos_falecidos = c(
        16,
        53,
        140,
        199,
        288,
        292,
        335
      )
    )
  )
)


panama[
  ,
  `:=`(
    ano = 2022L,
    uf = "PA",
    cod_mun = "PANAMA",
    idade_mae = rep(
      idades_mae,
      times = 3L
    ),
    n_mulheres = rep(
      mulheres,
      times = 3L
    ),
    n_efetivo = rep(
      mulheres,
      times = 3L
    ),
    soma_pesos = rep(
      mulheres,
      times = 3L
    )
  )
]


panama[
  ,
  `:=`(
    filhos_vivos =
      filhos_nv -
      filhos_falecidos,

    proporcao_falecidos =
      filhos_falecidos /
      filhos_nv
  )
]


# ============================================================
# 1. EXECUCAO DA NOSSA IMPLEMENTACAO
# ============================================================

resultado_panama <-
  estimar_mortalidade_trussell(
    panama
  )


componentes_panama <-
  padronizar_q235_para_q5(
    mortalidade_trussell =
      resultado_panama,
    referencia_west =
      coale_demeny_west
  )


# ============================================================
# 2. VALORES DE REFERENCIA
#
# Valores publicados no exemplo operacional do Panama.
# ============================================================

esperado <- data.table::data.table(

  grupo = c(
    "Total",
    "Total",
    "Total",
    "Masculino",
    "Masculino",
    "Masculino",
    "Feminino",
    "Feminino",
    "Feminino"
  ),

  idade_qx = rep(
    c(
      2L,
      3L,
      5L
    ),
    times = 3L
  ),

  qx_esperado = c(
    0.05137070,
    0.06517946,
    0.07178590,

    0.05799854,
    0.07073958,
    0.07573630,

    0.04403690,
    0.05943267,
    0.06758414
  ),

  t_esperado = c(
    2.364852,
    4.314966,
    6.636520,

    2.3270195,
    4.3919097,
    6.8621158,

    2.407031,
    4.238697,
    6.406109
  ),

  q5_esperado = c(
    0.05824125,
    0.07022363,
    0.07178590,

    0.06559956,
    0.07600789,
    0.07573630,

    0.05003973,
    0.06427108,
    0.06758414
  )
)


# ============================================================
# 3. COMPARACAO
# ============================================================

teste_panama <- merge(
  componentes_panama[
    ,
    .(
      grupo,
      idade_qx,
      qx_obtido = qx,
      t_obtido = tempo_referencia,
      q5_obtido = q5_equivalente
    )
  ],
  esperado,
  by = c(
    "grupo",
    "idade_qx"
  ),
  all = FALSE
)


teste_panama[
  ,
  `:=`(
    erro_qx =
      abs(
        qx_obtido -
          qx_esperado
      ),

    erro_t =
      abs(
        t_obtido -
          t_esperado
      ),

    erro_q5 =
      abs(
        q5_obtido -
          q5_esperado
      )
  )
]


print(
  teste_panama
)


# ============================================================
# 4. CRITERIOS
#
# Os valores de referencia estao arredondados na publicacao,
# portanto usamos tolerancias compativeis com esse arredondamento.
# ============================================================

tolerancia_qx <- 1e-7
tolerancia_t <- 1e-5
tolerancia_q5 <- 1e-7


if (
  any(
    teste_panama$erro_qx >
      tolerancia_qx
  )
) {

  stop(
    "Falha no teste de regressao Panama: q(x)."
  )
}


if (
  any(
    teste_panama$erro_t >
      tolerancia_t
  )
) {

  stop(
    "Falha no teste de regressao Panama: t(x)."
  )
}


if (
  any(
    teste_panama$erro_q5 >
      tolerancia_q5
  )
) {

  stop(
    "Falha no teste de regressao Panama: q5 equivalente."
  )
}


cat(
  "\nTeste de regressao Panama concluido com sucesso.\n"
)
