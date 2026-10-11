# ============================================================
# PRAIS4 - SO3.3
# DIAGNOSTICO DA ESTIMACAO TRUSSELL EM NIVEL DE UF
# CENSO DEMOGRAFICO 2022
#
# Objetivo:
#
#   Verificar se a instabilidade observada no nivel municipal
#   decorre principalmente da rarefacao amostral dos eventos.
#
# Estrategia:
#
#   1. agregar os insumos municipais para UF;
#   2. executar exatamente o mesmo Brass-Trussell;
#   3. converter q2/q3/q5 para q5 equivalente;
#   4. calcular q5*;
#   5. avaliar cobertura e coerencia interna;
#   6. comparar cada componente com o q5 oficial do IBGE
#      no respectivo periodo retrospectivo.
#
# Este script e exclusivamente diagnostico.
# Nao altera o processamento municipal.
# ============================================================


# ============================================================
# 0. OBJETOS NECESSARIOS
# ============================================================

objetos_necessarios <- c(
  "insumos_ev0_2022",
  "coale_demeny_west",
  "estimar_mortalidade_trussell",
  "padronizar_q235_para_q5",
  "sintetizar_q5_estrela",
  "ler_tabuas_mortalidade_ibge"
)


faltantes <- objetos_necessarios[
  !vapply(
    objetos_necessarios,
    exists,
    logical(1),
    inherits = TRUE
  )
]


if (
  length(faltantes) > 0L
) {

  stop(
    "Objetos/funcoes ausentes: ",
    paste(
      faltantes,
      collapse = ", "
    ),
    ". Execute primeiro o main.R."
  )
}


# ============================================================
# 1. PREPARACAO DOS INSUMOS ESTADUAIS
# ============================================================

d <- data.table::copy(
  insumos_ev0_2022
)


# ------------------------------------------------------------
# Reconstrucao da soma dos pesos ao quadrado
#
# No processamento municipal:
#
#                   (sum w)^2
# n_efetivo = -----------------------
#                    sum(w^2)
#
# portanto:
#
#                (sum w)^2
# sum(w^2) = ----------------
#               n_efetivo
#
# Isso permite recompor corretamente o n_efetivo da UF.
# ------------------------------------------------------------

d[
  ,
  soma_pesos2_reconstruida :=
    data.table::fifelse(
      !is.na(n_efetivo) &
        is.finite(n_efetivo) &
        n_efetivo > 0 &
        !is.na(soma_pesos),
      soma_pesos^2 /
        n_efetivo,
      NA_real_
    )
]


if (
  anyNA(
    d$soma_pesos2_reconstruida
  )
) {

  stop(
    "Nao foi possivel reconstruir soma_pesos2 ",
    "para todos os insumos municipais."
  )
}


# ------------------------------------------------------------
# Agregacao municipal -> UF
#
# IMPORTANTE:
#
# proporcao_falecidos NAO e promediada.
#
# Primeiro agregamos:
#
#   filhos nascidos vivos
#   filhos sobreviventes
#
# depois recalculamos:
#
#                 B - S
# D(i) = -----------------------
#                   B
# ------------------------------------------------------------

insumos_ev0_uf_2022 <- d[
  ,
  .(
    n_mulheres =
      sum(
        n_mulheres,
        na.rm = TRUE
      ),

    soma_pesos =
      sum(
        soma_pesos,
        na.rm = TRUE
      ),

    soma_pesos2 =
      sum(
        soma_pesos2_reconstruida,
        na.rm = TRUE
      ),

    filhos_nv =
      sum(
        filhos_nv,
        na.rm = TRUE
      ),

    filhos_vivos =
      sum(
        filhos_vivos,
        na.rm = TRUE
      )
  ),
  by = .(
    ano,
    uf,
    grupo,
    idade_mae
  )
]


insumos_ev0_uf_2022[
  ,
  `:=`(
    cod_mun =
      paste0(
        "UF_",
        uf
      ),

    n_efetivo =
      data.table::fifelse(
        soma_pesos2 > 0,
        soma_pesos^2 /
          soma_pesos2,
        NA_real_
      ),

    filhos_falecidos =
      filhos_nv -
      filhos_vivos,

    proporcao_falecidos =
      data.table::fifelse(
        filhos_nv > 0,
        (
          filhos_nv -
            filhos_vivos
        ) /
          filhos_nv,
        NA_real_
      )
  )
]


data.table::setcolorder(
  insumos_ev0_uf_2022,
  c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "idade_mae",
    "n_mulheres",
    "n_efetivo",
    "soma_pesos",
    "filhos_nv",
    "filhos_vivos",
    "filhos_falecidos",
    "proporcao_falecidos",
    "soma_pesos2"
  )
)


data.table::setorder(
  insumos_ev0_uf_2022,
  uf,
  grupo,
  idade_mae
)


# ============================================================
# 2. QA DA AGREGACAO ESTADUAL
# ============================================================

# Esperado:
#
# 27 UFs
# x 3 grupos
# x 7 grupos etarios maternos
#
# = 567 registros

if (
  nrow(insumos_ev0_uf_2022) !=
    27L * 3L * 7L
) {

  stop(
    "Numero inesperado de registros em insumos_ev0_uf_2022: ",
    nrow(insumos_ev0_uf_2022)
  )
}


duplicidades_uf <- insumos_ev0_uf_2022[
  ,
  .N,
  by = .(
    ano,
    uf,
    grupo,
    idade_mae
  )
][
  N != 1L
]


if (
  nrow(duplicidades_uf) > 0L
) {

  stop(
    "Foram encontradas duplicidades nos insumos estaduais."
  )
}


# ------------------------------------------------------------
# Consistencia demografica basica
# ------------------------------------------------------------

problemas_demograficos_uf <- insumos_ev0_uf_2022[
  filhos_vivos >
    filhos_nv |
    filhos_falecidos < 0 |
    proporcao_falecidos < 0 |
    proporcao_falecidos > 1
]


if (
  nrow(problemas_demograficos_uf) > 0L
) {

  stop(
    "Foram encontradas inconsistencias demograficas ",
    "nos insumos agregados por UF."
  )
}


# ============================================================
# 3. BRASS-TRUSSELL EM NIVEL ESTADUAL
# ============================================================

mortalidade_trussell_uf_2022 <-
  estimar_mortalidade_trussell(
    insumos_ev0_uf_2022
  )


# ============================================================
# 4. q2/q3/q5 -> q5 EQUIVALENTE
# ============================================================

componentes_q5_uf_2022 <-
  padronizar_q235_para_q5(
    mortalidade_trussell =
      mortalidade_trussell_uf_2022,
    referencia_west =
      coale_demeny_west
  )


# ============================================================
# 5. SINTESE q5*
# ============================================================

q5_estrela_uf_2022 <-
  sintetizar_q5_estrela(
    componentes_q5_uf_2022
  )


# ============================================================
# 6. QA ESTRUTURAL DOS RESULTADOS
# ============================================================

# Esperado:
#
# 27 UFs x 3 grupos x 3 componentes = 243

if (
  nrow(componentes_q5_uf_2022) !=
    27L * 3L * 3L
) {

  stop(
    "Numero inesperado de componentes estaduais: ",
    nrow(componentes_q5_uf_2022)
  )
}


# Esperado:
#
# 27 UFs x 3 grupos = 81

if (
  nrow(q5_estrela_uf_2022) !=
    27L * 3L
) {

  stop(
    "Numero inesperado de sinteses estaduais: ",
    nrow(q5_estrela_uf_2022)
  )
}


# ============================================================
# 7. COBERTURA DOS COMPONENTES
# ============================================================

diagnostico_status_uf_2022 <-
  componentes_q5_uf_2022[
    ,
    .N,
    by = .(
      grupo,
      idade_qx,
      flag_q5_equiv
    )
  ][
    order(
      grupo,
      idade_qx,
      flag_q5_equiv
    )
  ]


# ============================================================
# 8. COBERTURA DO q5*
# ============================================================

diagnostico_cobertura_uf_2022 <-
  q5_estrela_uf_2022[
    ,
    .N,
    by = .(
      grupo,
      n_componentes_validos,
      flag_q5_estrela
    )
  ][
    ,
    percentual :=
      100 *
      N /
      sum(N),
    by = grupo
  ][
    order(
      grupo,
      -n_componentes_validos
    )
  ]


# ============================================================
# 9. IDENTIDADE q5 -> q5 EQUIVALENTE
# ============================================================

qa_q5_direto_uf_2022 <-
  componentes_q5_uf_2022[
    idade_qx == 5L &
      flag_q5_equiv == "ok",
    .(
      n = .N,

      erro_maximo =
        max(
          abs(
            qx -
              q5_equivalente
          ),
          na.rm = TRUE
        )
    ),
    by = grupo
  ]


# ============================================================
# 10. DISPERSAO ENTRE q2/q3/q5 HARMONIZADOS
# ============================================================

diagnostico_dispersao_uf_2022 <-
  q5_estrela_uf_2022[
    n_componentes_validos == 3L,
    .(
      n = .N,

      amplitude_mediana =
        median(
          amplitude_q5,
          na.rm = TRUE
        ),

      amplitude_p90 =
        as.numeric(
          quantile(
            amplitude_q5,
            probs = 0.90,
            na.rm = TRUE
          )
        ),

      amplitude_maxima =
        max(
          amplitude_q5,
          na.rm = TRUE
        )
    ),
    by = grupo
  ]


# ============================================================
# 11. TABUAS IBGE ANUAIS - 2000 A 2022
#
# Precisamos das series anuais porque cada q2/q3/q5 possui
# seu proprio ano retrospectivo.
# ============================================================

tabuas_ibge_anuais_2000_2022 <-
  ler_tabuas_mortalidade_ibge(
    anos = 2000:2022
  )


# ============================================================
# 12. q5 OFICIAL IBGE
#
# A tábua abreviada possui lx em:
#
#   idade 0
#   idade 1
#   idade 5
#   ...
#
# Portanto:
#
# q5 = 1 - l(5) / l(0)
# ============================================================

ibge_lx_05 <- data.table::dcast(
  tabuas_ibge_anuais_2000_2022[
    idade %in%
      c(
        0L,
        5L
      ),
    .(
      ano,
      codigo_local,
      grupo,
      idade,
      lx
    )
  ],
  ano + codigo_local + grupo ~ idade,
  value.var = "lx"
)


data.table::setnames(
  ibge_lx_05,
  old = c(
    "0",
    "5"
  ),
  new = c(
    "lx0",
    "lx5"
  )
)


ibge_q5_anual <- ibge_lx_05[
  ,
  .(
    ano,
    uf =
      sprintf(
        "%02d",
        codigo_local
      ),
    grupo,
    q5_ibge =
      1 -
      lx5 /
      lx0
  )
]


data.table::setorder(
  ibge_q5_anual,
  uf,
  grupo,
  ano
)


# ============================================================
# 13. INTERPOLACAO DO q5 IBGE NO ANO RETROSPECTIVO
#
# Cada estimativa indireta possui seu proprio:
#
#   ano_referencia_qx
#
# A comparacao e feita nesse momento, e nao em 2022.
# ============================================================

interpolar_q5_ibge <- function(
  ano_referencia,
  uf_referencia,
  grupo_referencia,
  tabela_ibge
) {

  if (
    is.na(ano_referencia) ||
    !is.finite(ano_referencia)
  ) {

    return(
      NA_real_
    )
  }


  referencia <- tabela_ibge[
    uf == uf_referencia &
      grupo == grupo_referencia
  ]


  if (
    nrow(referencia) < 2L
  ) {

    return(
      NA_real_
    )
  }


  if (
    ano_referencia <
      min(referencia$ano) ||
    ano_referencia >
      max(referencia$ano)
  ) {

    return(
      NA_real_
    )
  }


  stats::approx(
    x =
      referencia$ano,

    y =
      referencia$q5_ibge,

    xout =
      ano_referencia,

    method =
      "linear",

    rule =
      1
  )$y
}


componentes_q5_uf_2022[
  ,
  q5_ibge_referencia :=
    mapply(
      FUN = interpolar_q5_ibge,

      ano_referencia =
        ano_referencia_qx,

      uf_referencia =
        uf,

      grupo_referencia =
        grupo,

      MoreArgs = list(
        tabela_ibge =
          ibge_q5_anual
      )
    )
]


# ============================================================
# 14. DIFERENCA ENTRE TRUSSELL/WEST E IBGE
#
# Esta comparacao e diagnostica.
#
# O IBGE nao e utilizado aqui para corrigir ou calibrar
# o resultado indireto.
# ============================================================

componentes_q5_uf_2022[
  ,
  diferenca_ibge :=
    q5_equivalente -
    q5_ibge_referencia
]


componentes_q5_uf_2022[
  ,
  diferenca_relativa_ibge :=
    data.table::fifelse(
      !is.na(q5_ibge_referencia) &
        q5_ibge_referencia > 0,
      100 *
        (
          q5_equivalente -
            q5_ibge_referencia
        ) /
        q5_ibge_referencia,
      NA_real_
    )
]


# ============================================================
# 15. RESUMO DA VALIDACAO CONTRA IBGE
# ============================================================

diagnostico_ibge_uf_2022 <-
  componentes_q5_uf_2022[
    flag_q5_equiv == "ok" &
      !is.na(q5_ibge_referencia),
    .(
      n = .N,

      q5_trussell_mediana =
        median(
          q5_equivalente,
          na.rm = TRUE
        ),

      q5_ibge_mediana =
        median(
          q5_ibge_referencia,
          na.rm = TRUE
        ),

      vies_mediano =
        median(
          diferenca_ibge,
          na.rm = TRUE
        ),

      erro_absoluto_mediano =
        median(
          abs(
            diferenca_ibge
          ),
          na.rm = TRUE
        ),

      mae =
        mean(
          abs(
            diferenca_ibge
          ),
          na.rm = TRUE
        ),

      rmse =
        sqrt(
          mean(
            diferenca_ibge^2,
            na.rm = TRUE
          )
        ),

      erro_relativo_mediano =
        median(
          diferenca_relativa_ibge,
          na.rm = TRUE
        )
    ),
    by = .(
      grupo,
      idade_qx
    )
  ][
    order(
      grupo,
      idade_qx
    )
  ]


# ============================================================
# 16. RESULTADOS
# ============================================================

cat(
  "\n============================================\n"
)

cat(
  "STATUS DOS COMPONENTES - UF\n"
)

cat(
  "============================================\n"
)

print(
  diagnostico_status_uf_2022
)


cat(
  "\n============================================\n"
)

cat(
  "COBERTURA q5* - UF\n"
)

cat(
  "============================================\n"
)

print(
  diagnostico_cobertura_uf_2022
)


cat(
  "\n============================================\n"
)

cat(
  "IDENTIDADE q5 -> q5 EQUIVALENTE\n"
)

cat(
  "============================================\n"
)

print(
  qa_q5_direto_uf_2022
)


cat(
  "\n============================================\n"
)

cat(
  "DISPERSAO ENTRE COMPONENTES - UF\n"
)

cat(
  "============================================\n"
)

print(
  diagnostico_dispersao_uf_2022
)


cat(
  "\n============================================\n"
)

cat(
  "COMPARACAO COM TABUAS IBGE\n"
)

cat(
  "============================================\n"
)

print(
  diagnostico_ibge_uf_2022
)

# ============================================================
# 17. QUAL COMPONENTE DEFINE A MEDIANA?
# ============================================================


identificar_componente_mediana <- function(dt) {

  dt[
    flag_q5_equiv == "ok" &
      !is.na(q5_equivalente),
    {

      mediana_local <- stats::median(
        q5_equivalente
      )

      distancia <- abs(
        q5_equivalente -
          mediana_local
      )

      i <- which.min(
        distancia
      )

      list(
        componente_mediana =
          idade_qx[i],

        q5_mediana =
          mediana_local
      )
    },
    by = .(
      ano,
      uf,
      cod_mun,
      grupo
    )
  ]
}


# ------------------------------------------------------------
# UF
# ------------------------------------------------------------

componente_mediana_uf_2022 <-
  identificar_componente_mediana(
    componentes_q5_uf_2022
  )


diagnostico_componente_mediana_uf_2022 <-
  componente_mediana_uf_2022[
    ,
    .N,
    by = .(
      grupo,
      componente_mediana
    )
  ][
    ,
    percentual :=
      100 *
      N /
      sum(N),
    by = grupo
  ][
    order(
      grupo,
      componente_mediana
    )
  ]


# ------------------------------------------------------------
# Municipios
#
# Apenas casos com os tres componentes validos.
# ------------------------------------------------------------

componentes_municipais_completos <-
  q5_estrela_2022[
    n_componentes_validos == 3L,
    .(
      ano,
      uf,
      cod_mun,
      grupo
    )
  ]


componentes_q5_municipais_completos <-
  merge(
    componentes_q5_2022,
    componentes_municipais_completos,
    by = c(
      "ano",
      "uf",
      "cod_mun",
      "grupo"
    ),
    all = FALSE
  )


componente_mediana_municipal_2022 <-
  identificar_componente_mediana(
    componentes_q5_municipais_completos
  )


diagnostico_componente_mediana_municipal_2022 <-
  componente_mediana_municipal_2022[
    ,
    .N,
    by = .(
      grupo,
      componente_mediana
    )
  ][
    ,
    percentual :=
      100 *
      N /
      sum(N),
    by = grupo
  ][
    order(
      grupo,
      componente_mediana
    )
  ]


# ============================================================
# 18. COBERTURA DE ESTRATEGIAS ALTERNATIVAS
# ============================================================

validade_componentes_municipais_2022 <-
  componentes_q5_2022[
    ,
    .(
      q2_valido =
        any(
          idade_qx == 2L &
            flag_q5_equiv == "ok"
        ),

      q3_valido =
        any(
          idade_qx == 3L &
            flag_q5_equiv == "ok"
        ),

      q5_valido =
        any(
          idade_qx == 5L &
            flag_q5_equiv == "ok"
        )
    ),
    by = .(
      ano,
      uf,
      cod_mun,
      grupo
    )
  ]


diagnostico_cobertura_alternativas_2022 <-
  validade_componentes_municipais_2022[
    ,
    .(
      municipios =
        .N,

      q2 =
        sum(
          q2_valido
        ),

      q3 =
        sum(
          q3_valido
        ),

      q5 =
        sum(
          q5_valido
        ),

      q3_e_q5 =
        sum(
          q3_valido &
            q5_valido
        ),

      q3_ou_q5 =
        sum(
          q3_valido |
            q5_valido
        ),

      q2_q3_q5 =
        sum(
          q2_valido &
            q3_valido &
            q5_valido
        )
    ),
    by = grupo
  ]


diagnostico_cobertura_alternativas_2022[
  ,
  `:=`(
    perc_q2 =
      100 *
      q2 /
      municipios,

    perc_q3 =
      100 *
      q3 /
      municipios,

    perc_q5 =
      100 *
      q5 /
      municipios,

    perc_q3_e_q5 =
      100 *
      q3_e_q5 /
      municipios,

    perc_q3_ou_q5 =
      100 *
      q3_ou_q5 /
      municipios,

    perc_q2_q3_q5 =
      100 *
      q2_q3_q5 /
      municipios
  )
]


# ============================================================
# 19. ASSOCIACAO ESPACIAL COM O IBGE
#
# Mais importante do que apenas a diferenca absoluta:
#
# o metodo preserva a ordenacao espacial das UFs?
# ============================================================

diagnostico_correlacao_ibge_uf_2022 <-
  componentes_q5_uf_2022[
    flag_q5_equiv == "ok" &
      !is.na(q5_ibge_referencia) &
      is.finite(q5_ibge_referencia),
    {

      ajuste <- stats::lm(
        q5_equivalente ~
          q5_ibge_referencia
      )

      list(
        n =
          .N,

        correlacao_pearson =
          stats::cor(
            q5_equivalente,
            q5_ibge_referencia,
            method = "pearson"
          ),

        correlacao_spearman =
          stats::cor(
            q5_equivalente,
            q5_ibge_referencia,
            method = "spearman"
          ),

        intercepto =
          unname(
            stats::coef(
              ajuste
            )[1L]
          ),

        inclinacao =
          unname(
            stats::coef(
              ajuste
            )[2L]
          ),

        r2 =
          summary(
            ajuste
          )$r.squared
      )
    },
    by = .(
      grupo,
      idade_qx
    )
  ][
    order(
      grupo,
      idade_qx
    )
  ]


# ============================================================
# 20. BENCHMARK SINTETICO IBGE
#
# Reproduz no IBGE a MESMA operacao temporal feita no
# Trussell:
#
# para cada UF/grupo:
#
#   mediana[
#     q5_IBGE(t_q2),
#     q5_IBGE(t_q3),
#     q5_IBGE(t_q5)
#   ]
#
# Assim nao comparamos q5* com um unico ano arbitrario.
# ============================================================

benchmark_sintetico_ibge_uf_2022 <-
  componentes_q5_uf_2022[
    flag_q5_equiv == "ok" &
      !is.na(q5_ibge_referencia),
    .(
      q5_trussell_sintetico =
        stats::median(
          q5_equivalente
        ),

      q5_ibge_sintetico =
        stats::median(
          q5_ibge_referencia
        )
    ),
    by = .(
      ano,
      uf,
      grupo
    )
  ]


benchmark_sintetico_ibge_uf_2022[
  ,
  diferenca :=
    q5_trussell_sintetico -
    q5_ibge_sintetico
]


diagnostico_benchmark_sintetico_uf_2022 <-
  benchmark_sintetico_ibge_uf_2022[
    ,
    .(
      n =
        .N,

      trussell_mediana =
        stats::median(
          q5_trussell_sintetico
        ),

      ibge_mediana =
        stats::median(
          q5_ibge_sintetico
        ),

      diferenca_mediana =
        stats::median(
          diferenca
        ),

      erro_absoluto_mediano =
        stats::median(
          abs(
            diferenca
          )
        ),

      correlacao_pearson =
        stats::cor(
          q5_trussell_sintetico,
          q5_ibge_sintetico,
          method = "pearson"
        ),

      correlacao_spearman =
        stats::cor(
          q5_trussell_sintetico,
          q5_ibge_sintetico,
          method = "spearman"
        )
    ),
    by = grupo
  ]


# ============================================================
# 21. RESULTADOS
# ============================================================

cat(
  "\n============================================\n",
  "COMPONENTE QUE DEFINE A MEDIANA - UF\n",
  "============================================\n",
  sep = ""
)

print(
  diagnostico_componente_mediana_uf_2022
)


cat(
  "\n============================================\n",
  "COMPONENTE QUE DEFINE A MEDIANA - MUNICIPIOS\n",
  "============================================\n",
  sep = ""
)

print(
  diagnostico_componente_mediana_municipal_2022
)


cat(
  "\n============================================\n",
  "COBERTURA DE ESTRATEGIAS ALTERNATIVAS\n",
  "============================================\n",
  sep = ""
)

print(
  diagnostico_cobertura_alternativas_2022
)


cat(
  "\n============================================\n",
  "CORRELACAO COM IBGE - UF\n",
  "============================================\n",
  sep = ""
)

print(
  diagnostico_correlacao_ibge_uf_2022
)


cat(
  "\n============================================\n",
  "BENCHMARK SINTETICO IBGE - UF\n",
  "============================================\n",
  sep = ""
)

print(
  diagnostico_benchmark_sintetico_uf_2022
)
