# ============================================================
# PRAIS4 - SO3.3
# EXPECTATIVA DE VIDA AO NASCER
# ESTIMACAO INDIRETA DA MORTALIDADE INFANTO-JUVENIL
#
# Variante de Trussell do metodo de Brass
# Dados classificados segundo idade da mae
#
# Referencias metodologicas:
#
#   United Nations (1983) - Manual X
#   United Nations (1990) - Step-by-Step Guide to the
#                            Estimation of Child Mortality
#
# Modelo operacional:
#
#   Coale-Demeny West
#
# Este arquivo contem SOMENTE funcoes e objetos metodologicos.
# Nao deve executar processamento censitario diretamente.
# ============================================================


# ============================================================
# 0. DEPENDENCIAS
# ============================================================

if (!requireNamespace("data.table", quietly = TRUE)) {

  stop(
    "O pacote 'data.table' e necessario para o processamento."
  )
}


# ============================================================
# 1. FUNCOES TEMPORAIS
# ============================================================


# ------------------------------------------------------------
# Ano decimal de uma data
#
# Exemplos:
#
# 01/08/2000 -> aproximadamente 2000.5820
# 01/08/2010 -> aproximadamente 2010.5808
# 01/08/2022 -> aproximadamente 2022.5808
# ------------------------------------------------------------

calcular_ano_decimal <- function(data) {

  data <- as.Date(
    data
  )


  ano <- as.integer(
    format(
      data,
      "%Y"
    )
  )


  inicio_ano <- as.Date(
    paste0(
      ano,
      "-01-01"
    )
  )


  inicio_ano_seguinte <- as.Date(
    paste0(
      ano + 1L,
      "-01-01"
    )
  )


  ano +
    as.numeric(
      data -
        inicio_ano
    ) /
    as.numeric(
      inicio_ano_seguinte -
        inicio_ano
    )
}


# ------------------------------------------------------------
# Data de referencia dos Censos utilizados no DVI
# ------------------------------------------------------------

obter_data_censo <- function(ano) {

  datas <- c(
    "2000" = "2000-08-01",
    "2010" = "2010-08-01",
    "2022" = "2022-08-01"
  )


  chave <- as.character(
    ano
  )


  if (
    any(
      !chave %in%
        names(datas)
    )
  ) {

    stop(
      "Ano censitario nao reconhecido. ",
      "Anos permitidos: 2000, 2010 e 2022."
    )
  }


  as.Date(
    unname(
      datas[
        chave
      ]
    )
  )
}


# ============================================================
# 2. COEFICIENTES TRUSSELL / WEST
# ============================================================

coeficientes_trussell_west <- data.table::data.table(

  idade_mae = c(
    "15-19",
    "20-24",
    "25-29",
    "30-34",
    "35-39",
    "40-44",
    "45-49"
  ),

  indice = 1:7,

  idade_qx = c(
    1L,
    2L,
    3L,
    5L,
    10L,
    15L,
    20L
  ),


  # ----------------------------------------------------------
  # Coeficientes do multiplicador k(i)
  #
  # k(i) =
  #   a_k +
  #   b_k * P(1)/P(2) +
  #   c_k * P(2)/P(3)
  # ----------------------------------------------------------

  a_k = c(
    1.1415,
    1.2563,
    1.1851,
    1.1720,
    1.1865,
    1.1746,
    1.1639
  ),

  b_k = c(
    -2.7070,
    -0.5381,
     0.0633,
     0.2341,
     0.3080,
     0.3314,
     0.3190
  ),

  c_k = c(
     0.7663,
    -0.2637,
    -0.4177,
    -0.4272,
    -0.4452,
    -0.4537,
    -0.4435
  ),


  # ----------------------------------------------------------
  # Coeficientes do periodo de referencia t(x)
  #
  # t(x) =
  #   a_t +
  #   b_t * P(1)/P(2) +
  #   c_t * P(2)/P(3)
  #
  # t(x) = numero de anos anteriores a data do Censo
  # ----------------------------------------------------------

  a_t = c(
    1.0970,
    1.3062,
    1.5305,
    1.9991,
    2.7632,
    4.3468,
    7.5242
  ),

  b_t = c(
     5.5628,
     5.5677,
     2.5528,
    -2.4261,
    -8.4065,
   -13.2436,
   -14.2013
  ),

  c_t = c(
    -1.9956,
     0.2962,
     4.8962,
    10.4282,
    16.1787,
    20.1990,
    20.0162
  )
)


# ============================================================
# 3. ESTIMACAO TRUSSELL
# ============================================================

estimar_mortalidade_trussell <- function(
  insumos_ev0
) {

  # ----------------------------------------------------------
  # Estrutura minima
  # ----------------------------------------------------------

  colunas_necessarias <- c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "idade_mae",
    "soma_pesos",
    "filhos_nv",
    "proporcao_falecidos"
  )


  faltantes <- setdiff(
    colunas_necessarias,
    names(
      insumos_ev0
    )
  )


  if (
    length(
      faltantes
    ) > 0L
  ) {

    stop(
      "Colunas ausentes em insumos_ev0: ",
      paste(
        faltantes,
        collapse = ", "
      )
    )
  }


  d <- data.table::as.data.table(
    data.table::copy(
      insumos_ev0
    )
  )


  # ----------------------------------------------------------
  # Duplicidades estruturais
  #
  # Deve existir no maximo uma observacao para cada:
  #
  # ano + UF + municipio + grupo + idade materna
  # ----------------------------------------------------------

  duplicidades <- d[
    ,
    .N,
    by = .(
      ano,
      uf,
      cod_mun,
      grupo,
      idade_mae
    )
  ][
    N > 1L
  ]


  if (
    nrow(
      duplicidades
    ) > 0L
  ) {

    stop(
      "Foram encontradas duplicidades nos insumos ",
      "da estimacao Trussell."
    )
  }


  # ----------------------------------------------------------
  # Paridade media
  #
  #              filhos nascidos vivos
  # P(i) = --------------------------------
  #             mulheres ponderadas
  #
  # Como os filhos_nv ja estao ponderados:
  #
  # P(i) = filhos_nv / soma_pesos
  # ----------------------------------------------------------

  d[
    ,
    paridade :=
      data.table::fifelse(
        !is.na(soma_pesos) &
          soma_pesos > 0,
        filhos_nv /
          soma_pesos,
        NA_real_
      )
  ]


  # ----------------------------------------------------------
  # P(1), P(2), P(3)
  #
  # 15-19 -> P1
  # 20-24 -> P2
  # 25-29 -> P3
  # ----------------------------------------------------------

  paridades_ref <- data.table::dcast(
    d[
      idade_mae %in%
        c(
          "15-19",
          "20-24",
          "25-29"
        ),
      .(
        ano,
        uf,
        cod_mun,
        grupo,
        idade_mae,
        paridade
      )
    ],
    ano + uf + cod_mun + grupo ~ idade_mae,
    value.var = "paridade"
  )


  if (
    nrow(
      paridades_ref
    ) == 0L
  ) {

    stop(
      "Nao foi possivel construir P1, P2 e P3."
    )
  }


  # ----------------------------------------------------------
  # Garante as tres colunas mesmo quando alguma faixa
  # nao aparece em um subconjunto censitario.
  # ----------------------------------------------------------

  faixas_paridade <- c(
    "15-19",
    "20-24",
    "25-29"
  )


  for (
    faixa in faixas_paridade
  ) {

    if (
      !faixa %in%
        names(
          paridades_ref
        )
    ) {

      paridades_ref[
        ,
        (faixa) :=
          NA_real_
      ]
    }
  }


  data.table::setnames(
    paridades_ref,
    old = c(
      "15-19",
      "20-24",
      "25-29"
    ),
    new = c(
      "P1",
      "P2",
      "P3"
    )
  )


  # ----------------------------------------------------------
  # Razoes de paridade
  # ----------------------------------------------------------

  paridades_ref[
    ,
    `:=`(
      razao_P1_P2 =
        data.table::fifelse(
          !is.na(P1) &
            !is.na(P2) &
            P2 > 0,
          P1 / P2,
          NA_real_
        ),

      razao_P2_P3 =
        data.table::fifelse(
          !is.na(P2) &
            !is.na(P3) &
            P3 > 0,
          P2 / P3,
          NA_real_
        )
    )
  ]


  # ----------------------------------------------------------
  # Anexa razoes de paridade
  # ----------------------------------------------------------

  d <- merge(
    d,
    paridades_ref,
    by = c(
      "ano",
      "uf",
      "cod_mun",
      "grupo"
    ),
    all.x = TRUE,
    sort = FALSE
  )


  # ----------------------------------------------------------
  # Anexa coeficientes Trussell / West
  # ----------------------------------------------------------

  d <- merge(
    d,
    coeficientes_trussell_west,
    by = "idade_mae",
    all.x = TRUE,
    sort = FALSE
  )


  # ----------------------------------------------------------
  # Multiplicador k(i)
  # ----------------------------------------------------------

  d[
    ,
    k_trussell :=
      a_k +
      b_k *
        razao_P1_P2 +
      c_k *
        razao_P2_P3
  ]


  # ----------------------------------------------------------
  # Probabilidade de morrer antes da idade x
  #
  # q(x) = k(i) * D(i)
  # ----------------------------------------------------------

  d[
    ,
    qx_bruto :=
      k_trussell *
      proporcao_falecidos
  ]


  # ----------------------------------------------------------
  # Periodo retrospectivo de referencia
  # ----------------------------------------------------------

  d[
    ,
    tempo_referencia :=
      a_t +
      b_t *
        razao_P1_P2 +
      c_t *
        razao_P2_P3
  ]


  # ----------------------------------------------------------
  # Data censitaria exata
  #
  # Nao utilizar:
  #
  #   ano - tempo_referencia
  #
  # pois o Censo nao esta ancorado em 1 de janeiro.
  # ----------------------------------------------------------

  d[
    ,
    data_censo :=
      obter_data_censo(
        ano
      )
  ]


  d[
    ,
    ano_decimal_censo :=
      calcular_ano_decimal(
        data_censo
      )
  ]


  d[
    ,
    ano_referencia_qx :=
      ano_decimal_censo -
      tempo_referencia
  ]


  # ----------------------------------------------------------
  # Flags diagnosticas
  #
  # Nenhum valor e corrigido ou truncado.
  # ----------------------------------------------------------

  d[
    ,
    `:=`(
      flag_paridade =
        is.na(
          razao_P1_P2
        ) |
        is.na(
          razao_P2_P3
        ),

      flag_qx =
        !is.na(
          qx_bruto
        ) &
        (
          qx_bruto < 0 |
          qx_bruto > 1
        ),

      flag_tempo_referencia =
        is.na(
          tempo_referencia
        ) |
        !is.finite(
          tempo_referencia
        ) |
        tempo_referencia < 0
    )
  ]


  # ----------------------------------------------------------
  # q(x) operacional
  #
  # Valores matematicamente impossiveis permanecem em
  # qx_bruto para auditoria, mas qx recebe NA.
  # ----------------------------------------------------------

  d[
    ,
    qx :=
      data.table::fifelse(
        !is.na(
          qx_bruto
        ) &
          is.finite(
            qx_bruto
          ) &
          qx_bruto >= 0 &
          qx_bruto <= 1,
        qx_bruto,
        NA_real_
      )
  ]


  data.table::setorder(
    d,
    ano,
    uf,
    cod_mun,
    grupo,
    indice
  )


  return(
    d[]
  )
}


# ============================================================
# BLOCO LEGADO / DIAGNOSTICO - ROTA CLASSICA
# ============================================================
#
# As secoes 4, 5 e 6 sao preservadas deliberadamente para
# auditoria metodologica e revisao por especialistas.
#
# Elas registram a rota classica anteriormente avaliada:
# q(2)/q(3)/q(5) -> equivalencia West -> sintese q5*.
#
# Essa rota NAO integra o caminho operacional primario do
# SO3.3. A especificacao operacional utiliza q(5) de maes
# 30-34 anos, estabilizacao Empirical Bayes e posterior
# conversao q(5)_EB -> e0 pela familia Coale-Demeny West.
#
# O codigo legado permanece util para diagnostico,
# sensibilidade e revisao demografica/atuarial.
# ============================================================


# ============================================================
# 4. [LEGADO] CONVERSAO q(x) -> q(5) EQUIVALENTE
#    COALE-DEMENY WEST
# ============================================================
#
# Componentes primarios:
#
#   q2 -> mulheres 20-24
#   q3 -> mulheres 25-29
#   q5 -> mulheres 30-34
#
# q1 permanece diagnostico.
# q10/q15/q20 permanecem historicos/sensibilidade.
#
# A conversao utiliza interpolacao linear entre niveis
# adjacentes da familia Coale-Demeny West.
#
# Nao e realizada extrapolacao.
# ============================================================

converter_qx_para_q5_west <- function(
  qx,
  idade_qx,
  grupo_dvi,
  referencia_west,
  tolerancia = 1e-12
) {

  # ----------------------------------------------------------
  # Funcao interna para padronizar todos os retornos
  # ----------------------------------------------------------

  retornar <- function(
    flag_q5_equiv,
    q5_equivalente = NA_real_,
    nivel_west_equivalente = NA_real_,
    nivel_j = NA_integer_,
    nivel_j1 = NA_integer_,
    h_west = NA_real_,
    flag_anomalia_west_n22 = FALSE
  ) {

    list(
      q5_equivalente =
        q5_equivalente,

      nivel_west_equivalente =
        nivel_west_equivalente,

      nivel_j =
        nivel_j,

      nivel_j1 =
        nivel_j1,

      h_west =
        h_west,

      flag_anomalia_west_n22 =
        flag_anomalia_west_n22,

      flag_q5_equiv =
        flag_q5_equiv
    )
  }


  # ----------------------------------------------------------
  # Ausencia
  # ----------------------------------------------------------

  if (
    length(qx) != 1L ||
    is.na(qx) ||
    !is.finite(qx)
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "qx_ausente"
      )
    )
  }


  # ----------------------------------------------------------
  # Validade matematica
  # ----------------------------------------------------------

  if (
    qx < 0 ||
    qx > 1
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "qx_fora_0_1"
      )
    )
  }


  # ----------------------------------------------------------
  # Idades utilizadas na sintese
  # ----------------------------------------------------------

  if (
    !idade_qx %in%
      c(
        2L,
        3L,
        5L
      )
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "idade_qx_nao_utilizada"
      )
    )
  }


  # ----------------------------------------------------------
  # Grupo DVI
  #
  # O ARGUMENTO chama-se grupo_dvi.
  #
  # A COLUNA da tabela de referencia continua chamando-se
  # grupo.
  # ----------------------------------------------------------

  if (
    !grupo_dvi %in%
      c(
        "Total",
        "Masculino",
        "Feminino"
      )
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "grupo_invalido"
      )
    )
  }


  # ----------------------------------------------------------
  # Tabela West correspondente ao grupo
  # ----------------------------------------------------------

  tabela <- data.table::copy(
    referencia_west[
      grupo == grupo_dvi
    ]
  )


  if (
    nrow(
      tabela
    ) == 0L
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "grupo_sem_tabela_west"
      )
    )
  }


  data.table::setorder(
    tabela,
    nivel
  )


  coluna_qx <- paste0(
    "q",
    idade_qx
  )


  if (
    !coluna_qx %in%
      names(
        tabela
      )
  ) {

    stop(
      "Coluna ",
      coluna_qx,
      " ausente na referencia Coale-Demeny West."
    )
  }


  q_modelo <- tabela[[coluna_qx]]


  # ----------------------------------------------------------
  # Dominio das tabuas-modelo
  # ----------------------------------------------------------

  q_min <- min(
    q_modelo,
    na.rm = TRUE
  )


  q_max <- max(
    q_modelo,
    na.rm = TRUE
  )


  if (
    qx < q_min -
      tolerancia ||
    qx > q_max +
      tolerancia
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "fora_dominio_west"
      )
    )
  }


  # ----------------------------------------------------------
  # Correspondencia exata com um nivel West
  # ----------------------------------------------------------

  indice_exato <- which(
    abs(
      q_modelo -
        qx
    ) <=
      tolerancia
  )


  if (
    length(
      indice_exato
    ) > 0L
  ) {

    i <- indice_exato[
      1L
    ]


    usa_anomalia_n22 <-
      grupo_dvi == "Feminino" &&
      tabela$nivel[
        i
      ] == 22L


    return(
      retornar(
        flag_q5_equiv =
          "ok",

        q5_equivalente =
          as.numeric(
            tabela$q5[
              i
            ]
          ),

        nivel_west_equivalente =
          as.numeric(
            tabela$nivel[
              i
            ]
          ),

        nivel_j =
          as.integer(
            tabela$nivel[
              i
            ]
          ),

        nivel_j1 =
          as.integer(
            tabela$nivel[
              i
            ]
          ),

        h_west =
          0,

        flag_anomalia_west_n22 =
          usa_anomalia_n22
      )
    )
  }


  # ----------------------------------------------------------
  # Niveis adjacentes
  #
  # A serie q(x) diminui com o aumento do nivel West.
  #
  # Procuramos:
  #
  # q_j(x) > q_estimado(x) > q_j+1(x)
  # ----------------------------------------------------------

  candidatos_j <- which(
    q_modelo >
      qx
  )


  candidatos_j1 <- which(
    q_modelo <
      qx
  )


  if (
    length(
      candidatos_j
    ) == 0L ||
    length(
      candidatos_j1
    ) == 0L
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "sem_intervalo_west"
      )
    )
  }


  # ----------------------------------------------------------
  # Nivel imediatamente acima de q(x)
  # ----------------------------------------------------------

  i_j <- max(
    candidatos_j
  )


  # ----------------------------------------------------------
  # Nivel imediatamente abaixo de q(x)
  # ----------------------------------------------------------

  i_j1 <- min(
    candidatos_j1
  )


  # ----------------------------------------------------------
  # Os dois niveis devem ser adjacentes
  # ----------------------------------------------------------

  if (
    i_j1 !=
      i_j + 1L
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "intervalo_west_nao_adjacente",

        nivel_j =
          as.integer(
            tabela$nivel[
              i_j
            ]
          ),

        nivel_j1 =
          as.integer(
            tabela$nivel[
              i_j1
            ]
          )
      )
    )
  }


  q_j <- q_modelo[
    i_j
  ]


  q_j1 <- q_modelo[
    i_j1
  ]


  # ----------------------------------------------------------
  # Fator de interpolacao
  #
  #            q_est - q_j
  # h = -----------------------------
  #          q_j+1 - q_j
  # ----------------------------------------------------------

  h <- (
    qx -
      q_j
  ) / (
    q_j1 -
      q_j
  )


  # ----------------------------------------------------------
  # QA da interpolacao
  # ----------------------------------------------------------

  if (
    !is.finite(h) ||
    h < -
      tolerancia ||
    h > 1 +
      tolerancia
  ) {

    return(
      retornar(
        flag_q5_equiv =
          "interpolacao_invalida",

        nivel_j =
          as.integer(
            tabela$nivel[
              i_j
            ]
          ),

        nivel_j1 =
          as.integer(
            tabela$nivel[
              i_j1
            ]
          ),

        h_west =
          as.numeric(
            h
          )
      )
    )
  }


  # ----------------------------------------------------------
  # q(5) equivalente
  # ----------------------------------------------------------

  q5_equivalente <-
    (
      1 -
        h
    ) *
    tabela$q5[
      i_j
    ] +
    h *
    tabela$q5[
      i_j1
    ]


  # ----------------------------------------------------------
  # Nivel West equivalente
  #
  # Mantido para diagnostico e auditoria.
  #
  # A sintese final e realizada em q(5), e nao diretamente
  # no numero do nivel.
  # ----------------------------------------------------------

  nivel_west_equivalente <-
    (
      1 -
        h
    ) *
    tabela$nivel[
      i_j
    ] +
    h *
    tabela$nivel[
      i_j1
    ]


  # ----------------------------------------------------------
  # Anomalia conhecida da fonte:
  #
  # West / Feminino / nivel 22.
  #
  # O resultado NAO e alterado.
  # Apenas registramos se o intervalo de interpolacao utiliza
  # esse nivel como um dos extremos.
  # ----------------------------------------------------------

  usa_anomalia_n22 <-
    grupo_dvi == "Feminino" &&
    any(
      tabela$nivel[
        c(
          i_j,
          i_j1
        )
      ] == 22L
    )


  return(
    retornar(
      flag_q5_equiv =
        "ok",

      q5_equivalente =
        as.numeric(
          q5_equivalente
        ),

      nivel_west_equivalente =
        as.numeric(
          nivel_west_equivalente
        ),

      nivel_j =
        as.integer(
          tabela$nivel[
            i_j
          ]
        ),

      nivel_j1 =
        as.integer(
          tabela$nivel[
            i_j1
          ]
        ),

      h_west =
        as.numeric(
          h
        ),

      flag_anomalia_west_n22 =
        usa_anomalia_n22
    )
  )
}


# ============================================================
# 5. [LEGADO] PADRONIZACAO q2/q3/q5 -> q5 EQUIVALENTE
# ============================================================

padronizar_q235_para_q5 <- function(
  mortalidade_trussell,
  referencia_west
) {

  # ----------------------------------------------------------
  # Estrutura da base Trussell
  # ----------------------------------------------------------

  colunas_necessarias <- c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "idade_mae",
    "idade_qx",
    "qx_bruto",
    "qx",
    "tempo_referencia",
    "data_censo",
    "ano_decimal_censo",
    "ano_referencia_qx"
  )


  faltantes <- setdiff(
    colunas_necessarias,
    names(
      mortalidade_trussell
    )
  )


  if (
    length(
      faltantes
    ) > 0L
  ) {

    stop(
      "Colunas ausentes em mortalidade_trussell: ",
      paste(
        faltantes,
        collapse = ", "
      )
    )
  }


  # ----------------------------------------------------------
  # Estrutura da referencia West
  # ----------------------------------------------------------

  colunas_west <- c(
    "grupo",
    "nivel",
    "q2",
    "q3",
    "q5"
  )


  faltantes_west <- setdiff(
    colunas_west,
    names(
      referencia_west
    )
  )


  if (
    length(
      faltantes_west
    ) > 0L
  ) {

    stop(
      "Colunas ausentes na referencia Coale-Demeny West: ",
      paste(
        faltantes_west,
        collapse = ", "
      )
    )
  }


  grupos_west <- c(
    "Total",
    "Masculino",
    "Feminino"
  )


  if (
    !setequal(
      unique(
        referencia_west$grupo
      ),
      grupos_west
    )
  ) {

    stop(
      "A referencia Coale-Demeny West nao contem ",
      "exatamente os grupos Total, Masculino e Feminino."
    )
  }


  duplicidades_west <- referencia_west[
    ,
    .N,
    by = .(
      grupo,
      nivel
    )
  ][
    N > 1L
  ]


  if (
    nrow(
      duplicidades_west
    ) > 0L
  ) {

    stop(
      "Foram encontradas duplicidades na referencia ",
      "Coale-Demeny West."
    )
  }


  dados_completos <- data.table::as.data.table(
    data.table::copy(
      mortalidade_trussell
    )
  )


  # ----------------------------------------------------------
  # Universo de municipios e grupos existentes na estimativa
  # Trussell.
  #
  # Esse universo sera utilizado para explicitar componentes
  # q2/q3/q5 ausentes, em vez de simplesmente perder a linha.
  # ----------------------------------------------------------

  universo <- unique(
    dados_completos[
      ,
      .(
        ano,
        uf,
        cod_mun,
        grupo
      )
    ]
  )


  # ----------------------------------------------------------
  # Mantem somente q2, q3 e q5 efetivamente observados
  # ----------------------------------------------------------

  dados <- dados_completos[
    idade_qx %in%
      c(
        2L,
        3L,
        5L
      )
  ]


  # ----------------------------------------------------------
  # Nenhum componente pode aparecer mais de uma vez
  # ----------------------------------------------------------

  duplicidades <- dados[
    ,
    .N,
    by = .(
      ano,
      uf,
      cod_mun,
      grupo,
      idade_qx
    )
  ][
    N > 1L
  ]


  if (
    nrow(
      duplicidades
    ) > 0L
  ) {

    stop(
      "Foram encontradas duplicidades em q2/q3/q5 ",
      "na base Trussell."
    )
  }


  # ----------------------------------------------------------
  # Grade esperada:
  #
  # para cada municipio/grupo devem ser representados:
  #
  # q2
  # q3
  # q5
  #
  # Ausencia de um componente e registrada como NA.
  # Nenhum valor e imputado.
  # ----------------------------------------------------------

  grade <- universo[
    ,
    .(
      idade_qx =
        c(
          2L,
          3L,
          5L
        )
    ),
    by = .(
      ano,
      uf,
      cod_mun,
      grupo
    )
  ]


  dados <- merge(
    grade,
    dados,
    by = c(
      "ano",
      "uf",
      "cod_mun",
      "grupo",
      "idade_qx"
    ),
    all.x = TRUE,
    sort = FALSE
  )


  # ----------------------------------------------------------
  # Reconstrucao apenas do rotulo etario quando a linha
  # original esta ausente.
  #
  # Isso NAO constitui imputacao demografica.
  # ----------------------------------------------------------

  dados[
    is.na(
      idade_mae
    ),
    idade_mae :=
      data.table::fcase(
        idade_qx == 2L,
        "20-24",

        idade_qx == 3L,
        "25-29",

        idade_qx == 5L,
        "30-34",

        default =
          NA_character_
      )
  ]


  # ----------------------------------------------------------
  # Data censitaria e ano decimal sao propriedades do recorte,
  # portanto podem ser preenchidos mesmo quando um componente
  # demografico esta ausente.
  # ----------------------------------------------------------

  dados[
    is.na(
      data_censo
    ),
    data_censo :=
      obter_data_censo(
        ano
      )
  ]


  dados[
    is.na(
      ano_decimal_censo
    ),
    ano_decimal_censo :=
      calcular_ano_decimal(
        data_censo
      )
  ]


  # ----------------------------------------------------------
  # Conversao linha a linha para q5 equivalente
  # ----------------------------------------------------------

  conversoes <- Map(
    f = function(
      q,
      idade,
      g
    ) {

      converter_qx_para_q5_west(
        qx = q,
        idade_qx = idade,
        grupo_dvi = g,
        referencia_west =
          referencia_west
      )
    },

    q =
      dados$qx,

    idade =
      dados$idade_qx,

    g =
      dados$grupo
  )


  # ----------------------------------------------------------
  # Expansao dos resultados
  # ----------------------------------------------------------

  dados[
    ,
    q5_equivalente :=
      vapply(
        conversoes,
        function(x) {
          x$q5_equivalente
        },
        numeric(1)
      )
  ]


  dados[
    ,
    nivel_west_equivalente :=
      vapply(
        conversoes,
        function(x) {
          x$nivel_west_equivalente
        },
        numeric(1)
      )
  ]


  dados[
    ,
    nivel_j :=
      vapply(
        conversoes,
        function(x) {
          x$nivel_j
        },
        integer(1)
      )
  ]


  dados[
    ,
    nivel_j1 :=
      vapply(
        conversoes,
        function(x) {
          x$nivel_j1
        },
        integer(1)
      )
  ]


  dados[
    ,
    h_west :=
      vapply(
        conversoes,
        function(x) {
          x$h_west
        },
        numeric(1)
      )
  ]


  dados[
    ,
    flag_anomalia_west_n22 :=
      vapply(
        conversoes,
        function(x) {
          x$flag_anomalia_west_n22
        },
        logical(1)
      )
  ]


  dados[
    ,
    flag_q5_equiv :=
      vapply(
        conversoes,
        function(x) {
          x$flag_q5_equiv
        },
        character(1)
      )
  ]


  data.table::setorder(
    dados,
    ano,
    uf,
    cod_mun,
    grupo,
    idade_qx
  )


  return(
    dados[]
  )
}


# ============================================================
# 6. [LEGADO] SINTESE MUNICIPAL q5*
# ============================================================
#
# Decisao metodologica do SO3.3:
#
# q5* =
#
#   mediana(
#     q5 equivalente derivado de q2,
#     q5 equivalente derivado de q3,
#     q5 equivalente derivado de q5
#   )
#
# Regras desta primeira implementacao:
#
#   1. devem existir estruturalmente q2, q3 e q5;
#   2. os tres devem ser validos na familia West;
#   3. somente nesse caso q5* e produzido;
#   4. nao existe fallback nesta etapa;
#   5. componentes ausentes permanecem explicitamente
#      registrados.
# ============================================================

sintetizar_q5_estrela <- function(
  componentes_q5
) {

  # ----------------------------------------------------------
  # Estrutura minima
  # ----------------------------------------------------------

  colunas_necessarias <- c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "idade_qx",
    "q5_equivalente",
    "ano_referencia_qx",
    "flag_anomalia_west_n22",
    "flag_q5_equiv"
  )


  faltantes <- setdiff(
    colunas_necessarias,
    names(
      componentes_q5
    )
  )


  if (
    length(
      faltantes
    ) > 0L
  ) {

    stop(
      "Colunas ausentes em componentes_q5: ",
      paste(
        faltantes,
        collapse = ", "
      )
    )
  }


  dados <- data.table::as.data.table(
    data.table::copy(
      componentes_q5
    )
  )


  if (
    nrow(
      dados
    ) == 0L
  ) {

    stop(
      "componentes_q5 possui zero registros."
    )
  }


  # ----------------------------------------------------------
  # Duplicidades
  # ----------------------------------------------------------

  duplicidades <- dados[
    ,
    .N,
    by = .(
      ano,
      uf,
      cod_mun,
      grupo,
      idade_qx
    )
  ][
    N > 1L
  ]


  if (
    nrow(
      duplicidades
    ) > 0L
  ) {

    stop(
      "Foram encontradas duplicidades nos componentes ",
      "utilizados para q5*."
    )
  }


  # ----------------------------------------------------------
  # Sintese
  # ----------------------------------------------------------

  resultado <- dados[
    ,
    {

      # ------------------------------------------------------
      # Estrutura esperada:
      #
      # exatamente q2, q3 e q5.
      # ------------------------------------------------------

      idades_observadas <- sort(
        unique(
          as.integer(
            idade_qx
          )
        )
      )


      estrutura_componentes_ok <-
        .N == 3L &&
        identical(
          idades_observadas,
          c(
            2L,
            3L,
            5L
          )
        )


      # ------------------------------------------------------
      # Componentes efetivamente validos
      # ------------------------------------------------------

      valido <-
        flag_q5_equiv ==
          "ok" &
        !is.na(
          q5_equivalente
        ) &
        is.finite(
          q5_equivalente
        )


      valores <- q5_equivalente[
        valido
      ]


      n_validos <- length(
        valores
      )


      # ------------------------------------------------------
      # q5*
      #
      # Exige estrutura 2/3/5 e tres componentes validos.
      # ------------------------------------------------------

      q5_star <-
        if (
          estrutura_componentes_ok &&
          n_validos == 3L
        ) {

          stats::median(
            valores
          )

        } else {

          NA_real_
        }


      # ------------------------------------------------------
      # Dispersao entre os q5 equivalentes
      # ------------------------------------------------------

      amplitude_q5 <-
        if (
          n_validos >= 2L
        ) {

          diff(
            range(
              valores
            )
          )

        } else {

          NA_real_
        }


      # ------------------------------------------------------
      # Datas retrospectivas dos componentes validos
      # ------------------------------------------------------

      anos_validos <- ano_referencia_qx[
        valido &
          !is.na(
            ano_referencia_qx
          ) &
          is.finite(
            ano_referencia_qx
          )
      ]


      ano_referencia_min <-
        if (
          length(
            anos_validos
          ) > 0L
        ) {

          min(
            anos_validos
          )

        } else {

          NA_real_
        }


      ano_referencia_max <-
        if (
          length(
            anos_validos
          ) > 0L
        ) {

          max(
            anos_validos
          )

        } else {

          NA_real_
        }


      amplitude_temporal <-
        if (
          length(
            anos_validos
          ) >= 2L
        ) {

          ano_referencia_max -
            ano_referencia_min

        } else {

          NA_real_
        }


      # ------------------------------------------------------
      # Uso da anomalia conhecida West/Feminino/nivel 22
      # ------------------------------------------------------

      usa_anomalia_west_n22 <-
        any(
          flag_anomalia_west_n22 &
            valido,
          na.rm = TRUE
        )


      # ------------------------------------------------------
      # Status da sintese
      # ------------------------------------------------------

      flag_sintese <-
        if (
          !estrutura_componentes_ok
        ) {

          "estrutura_componentes_invalida"

        } else if (
          n_validos == 3L
        ) {

          "ok_3_componentes"

        } else if (
          n_validos == 2L
        ) {

          "incompleto_2_componentes"

        } else if (
          n_validos == 1L
        ) {

          "insuficiente_1_componente"

        } else {

          "sem_componente_valido"
        }


      # ------------------------------------------------------
      # Retorno municipal
      # ------------------------------------------------------

      list(
        estrutura_componentes_ok =
          estrutura_componentes_ok,

        n_componentes_validos =
          n_validos,

        q5_estrela =
          q5_star,

        amplitude_q5 =
          amplitude_q5,

        ano_referencia_min =
          ano_referencia_min,

        ano_referencia_max =
          ano_referencia_max,

        amplitude_temporal =
          amplitude_temporal,

        usa_anomalia_west_n22 =
          usa_anomalia_west_n22,

        flag_q5_estrela =
          flag_sintese
      )
    },

    by = .(
      ano,
      uf,
      cod_mun,
      grupo
    )
  ]


  data.table::setorder(
    resultado,
    ano,
    uf,
    cod_mun,
    grupo
  )


  return(
    resultado[]
  )
}

# ============================================================
# 7. CAMINHO OPERACIONAL - q(5)_EB -> e0
#    COALE-DEMENY WEST
# ============================================================
#
# Converte q(5) estabilizado por Empirical Bayes em
# expectativa de vida ao nascer (e0) pela familia West.
#
# Para q5 entre niveis adjacentes j e j+1:
#
#              q5 - q5_j
#   h = -------------------------
#         q5_(j+1) - q5_j
#
#   e0 = (1 - h) * e0_j + h * e0_(j+1)
#
# Nao ha extrapolacao para fora do dominio West.
# Como q5 e e0 possuem relacao inversa:
#
#   q5_ic_inf -> e0_ic_sup
#   q5_ic_sup -> e0_ic_inf
#
# A referencia temporal permanece ano_referencia_q5.
# ============================================================

.converter_um_q5_para_e0_west <- function(
  q5,
  grupo_dvi,
  referencia_west,
  tolerancia = 1e-12
) {

  retorno <- list(
    e0 = NA_real_,
    nivel_west_equivalente = NA_real_,
    nivel_j = NA_integer_,
    nivel_j1 = NA_integer_,
    h_west = NA_real_,
    flag_e0 = NA_character_
  )

  if (
    length(q5) != 1L ||
    is.na(q5) ||
    !is.finite(q5)
  ) {
    retorno$flag_e0 <- "q5_ausente"
    return(retorno)
  }

  if (q5 < 0 || q5 > 1) {
    retorno$flag_e0 <- "q5_fora_0_1"
    return(retorno)
  }

  if (
    !grupo_dvi %in%
      c("Total", "Masculino", "Feminino")
  ) {
    retorno$flag_e0 <- "grupo_invalido"
    return(retorno)
  }

  tabela <- data.table::copy(
    referencia_west[
      grupo == grupo_dvi
    ]
  )

  if (nrow(tabela) == 0L) {
    retorno$flag_e0 <- "grupo_sem_tabela_west"
    return(retorno)
  }

  data.table::setorder(
    tabela,
    nivel
  )

  q_modelo <- tabela$q5

  q_min <- min(q_modelo, na.rm = TRUE)
  q_max <- max(q_modelo, na.rm = TRUE)

  if (
    q5 < q_min - tolerancia ||
    q5 > q_max + tolerancia
  ) {
    retorno$flag_e0 <- "fora_dominio_west"
    return(retorno)
  }

  indice_exato <- which(
    abs(q_modelo - q5) <= tolerancia
  )

  if (length(indice_exato) > 0L) {

    i <- indice_exato[1L]

    retorno$e0 <- as.numeric(tabela$e0[i])
    retorno$nivel_west_equivalente <-
      as.numeric(tabela$nivel[i])
    retorno$nivel_j <-
      as.integer(tabela$nivel[i])
    retorno$nivel_j1 <-
      as.integer(tabela$nivel[i])
    retorno$h_west <- 0
    retorno$flag_e0 <- "ok"

    return(retorno)
  }

  candidatos_j <- which(
    q_modelo > q5
  )

  candidatos_j1 <- which(
    q_modelo < q5
  )

  if (
    length(candidatos_j) == 0L ||
    length(candidatos_j1) == 0L
  ) {
    retorno$flag_e0 <- "sem_intervalo_west"
    return(retorno)
  }

  i_j <- max(candidatos_j)
  i_j1 <- min(candidatos_j1)

  retorno$nivel_j <-
    as.integer(tabela$nivel[i_j])
  retorno$nivel_j1 <-
    as.integer(tabela$nivel[i_j1])

  if (i_j1 != i_j + 1L) {
    retorno$flag_e0 <- "intervalo_west_nao_adjacente"
    return(retorno)
  }

  q_j <- q_modelo[i_j]
  q_j1 <- q_modelo[i_j1]

  h <- (
    q5 - q_j
  ) / (
    q_j1 - q_j
  )

  retorno$h_west <- as.numeric(h)

  if (
    !is.finite(h) ||
    h < -tolerancia ||
    h > 1 + tolerancia
  ) {
    retorno$flag_e0 <- "interpolacao_invalida"
    return(retorno)
  }

  retorno$e0 <- as.numeric(
    (1 - h) * tabela$e0[i_j] +
      h * tabela$e0[i_j1]
  )

  retorno$nivel_west_equivalente <- as.numeric(
    (1 - h) * tabela$nivel[i_j] +
      h * tabela$nivel[i_j1]
  )

  retorno$flag_e0 <- "ok"

  retorno
}


converter_q5_eb_para_e0_west <- function(
  q5_eb,
  referencia_west,
  tolerancia = 1e-12
) {

  colunas_necessarias <- c(
    "ano",
    "uf",
    "cod_mun",
    "grupo",
    "q5_estabilizado",
    "q5_ic_inf",
    "q5_ic_sup",
    "t_usado",
    "ano_referencia_q5"
  )

  faltantes <- setdiff(
    colunas_necessarias,
    names(q5_eb)
  )

  if (length(faltantes) > 0L) {
    stop(
      "Colunas ausentes em q5_eb: ",
      paste(faltantes, collapse = ", ")
    )
  }

  referencia <- data.table::as.data.table(
    data.table::copy(
      referencia_west
    )
  )

  colunas_west <- c(
    "grupo",
    "nivel",
    "e0",
    "q5"
  )

  faltantes_west <- setdiff(
    colunas_west,
    names(referencia)
  )

  if (length(faltantes_west) > 0L) {
    stop(
      "Colunas ausentes na referencia West: ",
      paste(faltantes_west, collapse = ", ")
    )
  }

  grupos_esperados <- c(
    "Total",
    "Masculino",
    "Feminino"
  )

  if (
    !setequal(
      unique(referencia$grupo),
      grupos_esperados
    )
  ) {
    stop(
      "A referencia West deve conter exatamente ",
      "Total, Masculino e Feminino."
    )
  }

  duplicidades_west <- referencia[
    ,
    .N,
    by = .(grupo, nivel)
  ][
    N > 1L
  ]

  if (nrow(duplicidades_west) > 0L) {
    stop(
      "Foram encontradas duplicidades na referencia West."
    )
  }

  qa_west <- referencia[
    order(nivel),
    .(
      n_niveis = data.table::uniqueN(nivel),
      q5_decrescente = all(diff(q5) < 0),
      e0_crescente = all(diff(e0) > 0)
    ),
    by = grupo
  ]

  if (
    any(
      qa_west$n_niveis != 25L |
      !qa_west$q5_decrescente |
      !qa_west$e0_crescente
    )
  ) {
    stop(
      "A referencia West nao apresenta a estrutura ",
      "monotonica esperada para q5 e e0."
    )
  }

  dados <- data.table::as.data.table(
    data.table::copy(
      q5_eb
    )
  )

  duplicidades <- dados[
    ,
    .N,
    by = .(ano, uf, cod_mun, grupo)
  ][
    N > 1L
  ]

  if (nrow(duplicidades) > 0L) {
    stop(
      "Foram encontradas duplicidades em q5_eb."
    )
  }

  converter_vetor <- function(q) {
    Map(
      function(valor, grupo_atual) {
        .converter_um_q5_para_e0_west(
          q5 = valor,
          grupo_dvi = grupo_atual,
          referencia_west = referencia,
          tolerancia = tolerancia
        )
      },
      q,
      dados$grupo
    )
  }

  ponto <- converter_vetor(
    dados$q5_estabilizado
  )

  lim_q5_inf <- converter_vetor(
    dados$q5_ic_inf
  )

  lim_q5_sup <- converter_vetor(
    dados$q5_ic_sup
  )

  data.table::set(
    dados,
    j = "e0",
    value = vapply(
      ponto,
      function(x) x$e0,
      numeric(1)
    )
  )

  data.table::set(
    dados,
    j = "nivel_west_equivalente",
    value = vapply(
      ponto,
      function(x) x$nivel_west_equivalente,
      numeric(1)
    )
  )

  data.table::set(
    dados,
    j = "nivel_west_j",
    value = vapply(
      ponto,
      function(x) x$nivel_j,
      integer(1)
    )
  )

  data.table::set(
    dados,
    j = "nivel_west_j1",
    value = vapply(
      ponto,
      function(x) x$nivel_j1,
      integer(1)
    )
  )

  data.table::set(
    dados,
    j = "h_west",
    value = vapply(
      ponto,
      function(x) x$h_west,
      numeric(1)
    )
  )

  data.table::set(
    dados,
    j = "flag_e0",
    value = vapply(
      ponto,
      function(x) x$flag_e0,
      character(1)
    )
  )

  data.table::set(
    dados,
    j = "e0_ic_inf",
    value = vapply(
      lim_q5_sup,
      function(x) x$e0,
      numeric(1)
    )
  )

  data.table::set(
    dados,
    j = "e0_ic_sup",
    value = vapply(
      lim_q5_inf,
      function(x) x$e0,
      numeric(1)
    )
  )

  data.table::set(
    dados,
    j = "flag_e0_ic_inf",
    value = vapply(
      lim_q5_sup,
      function(x) x$flag_e0,
      character(1)
    )
  )

  data.table::set(
    dados,
    j = "flag_e0_ic_sup",
    value = vapply(
      lim_q5_inf,
      function(x) x$flag_e0,
      character(1)
    )
  )

  flag_ordem_ic_q5 <- data.table::fcase(
    is.na(dados$q5_ic_inf) |
      !is.finite(dados$q5_ic_inf) |
      is.na(dados$q5_ic_sup) |
      !is.finite(dados$q5_ic_sup),
    "ic_q5_ausente",

    dados$q5_ic_inf >
      dados$q5_estabilizado + tolerancia |
      dados$q5_estabilizado >
        dados$q5_ic_sup + tolerancia,
    "ic_q5_ordem_invalida",

    default = "ok"
  )

  data.table::set(
    dados,
    j = "flag_ordem_ic_q5",
    value = flag_ordem_ic_q5
  )

  flag_e0_intervalo <- data.table::fcase(
    dados$flag_ordem_ic_q5 != "ok",
    dados$flag_ordem_ic_q5,

    dados$flag_e0_ic_inf != "ok",
    paste0(
      "limite_inferior_",
      dados$flag_e0_ic_inf
    ),

    dados$flag_e0_ic_sup != "ok",
    paste0(
      "limite_superior_",
      dados$flag_e0_ic_sup
    ),

    default = "ok"
  )

  data.table::set(
    dados,
    j = "flag_e0_intervalo",
    value = flag_e0_intervalo
  )

  idx_intervalo_invalido <-
    dados$flag_e0_intervalo != "ok"

  dados$e0_ic_inf[
    idx_intervalo_invalido
  ] <- NA_real_

  dados$e0_ic_sup[
    idx_intervalo_invalido
  ] <- NA_real_

  data.table::set(
    dados,
    j = "amplitude_e0_ic",
    value = data.table::fifelse(
      is.finite(dados$e0_ic_inf) &
        is.finite(dados$e0_ic_sup),
      dados$e0_ic_sup - dados$e0_ic_inf,
      NA_real_
    )
  )

  linhas_ic_validas <-
    dados$flag_e0 == "ok" &
    dados$flag_e0_intervalo == "ok" &
    is.finite(dados$e0) &
    is.finite(dados$e0_ic_inf) &
    is.finite(dados$e0_ic_sup)

  if (
    any(
      dados$e0_ic_inf[linhas_ic_validas] >
        dados$e0[linhas_ic_validas] +
          tolerancia |
      dados$e0[linhas_ic_validas] >
        dados$e0_ic_sup[linhas_ic_validas] +
          tolerancia
    )
  ) {
    stop(
      "Inconsistencia na ordem do intervalo de e0 ",
      "apos a conversao West."
    )
  }

  data.table::setorder(
    dados,
    ano,
    grupo,
    uf,
    cod_mun
  )

  dados[]
}
